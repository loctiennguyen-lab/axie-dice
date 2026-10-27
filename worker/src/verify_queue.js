// SR-V: shadow verifier queue. NEVER affects rewards, outcome or leaderboard: it only records what an
// out-of-process verifier (verifier/, Godot headless, no network) says about a closed run.
//   enqueueVerify(env, row)      called by RunDO after the close is written back; inert unless env.VERIFY_SHADOW === '1'.
//   handleVerify(request, env)   POST /api/verify/next (claim a job), POST /api/verify/result (submit), GET /api/verify/stats (read-only), HMAC-signed.
// Signature: hex HMAC-SHA256(env.VERIFY_HMAC_KEY, `${ts}\n${METHOD}\n${path}\n${body}`) in X-Verify-Sig, unix seconds in
// X-Verify-Ts (|now - ts| <= 120 s). No key configured = endpoints answer 404 (feature absent).

export const isVerifyPath = (p) => p === '/api/verify/next' || p === '/api/verify/result' || p === '/api/verify/stats';

/** Bytes (not chars), with a margin under D1's 2 MB row limit. */
export const MAX_PAYLOAD_BYTES = 900_000;
export const DONE_RETAIN_S = 7 * 86400;      // payload of an ok/error row is dropped after this
export const PENDING_EXPIRE_S = 14 * 86400;  // a pending job older than this is given up (runner off)
export const SWEEP_LIMIT = 50;
export const MAX_ATTEMPTS = 3;
export const LEASE_S = 300;
export const SKEW_S = 120;
export const MAX_BODY = 4096;
const OUTCOMES = new Set(['won', 'lost', 'rejected', 'invalid']);
const RESULT_KEYS = ['ok', 'reason', 'rules_version', 'outcome', 'score', 'nodes', 'log_len', 'ms'];
/** Rejections that say "the verifier could not judge this record" rather than "the record is wrong". */
const NOT_A_VERDICT = new Set(['rules_version_mismatch', 'content_version_mismatch', 'bad_header', 'log_incomplete',
  'bad_json', 'bad_tape', 'input_too_large', 'log_too_long', 'no_input', 'unreadable_input']);

const enc = new TextEncoder();
const json = (obj, status = 200) => new Response(JSON.stringify(obj), { status, headers: { 'content-type': 'application/json' } });
const hex = (buf) => [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, '0')).join('');

export async function signVerify(key, ts, method, path, body) {
  const k = await crypto.subtle.importKey('raw', enc.encode(key), { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
  return hex(await crypto.subtle.sign('HMAC', k, enc.encode(`${ts}\n${method}\n${path}\n${body}`)));
}

function sameHex(a, b) {
  if (typeof a !== 'string' || a.length !== b.length) return false;
  let d = 0;
  for (let i = 0; i < a.length; i++) d |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return d === 0;
}

/** Fixed 8-key schema with ceilings. Returns '' when valid, else the first problem. */
export function checkResult(r) {
  if (!r || typeof r !== 'object' || Array.isArray(r)) return 'not_object';
  const keys = Object.keys(r);
  if (keys.length !== RESULT_KEYS.length || !RESULT_KEYS.every((k) => keys.includes(k))) return 'keys';
  if (typeof r.ok !== 'boolean') return 'ok';
  if (typeof r.reason !== 'string' || r.reason.length > 64 || !/^[a-z_]*$/.test(r.reason)) return 'reason';
  if (typeof r.rules_version !== 'string' || r.rules_version.length > 40) return 'rules_version';
  if (!OUTCOMES.has(r.outcome)) return 'outcome';
  const caps = { score: 1_000_000, nodes: 1000, log_len: 20_000, ms: 600_000 };
  for (const [k, max] of Object.entries(caps)) if (!Number.isInteger(r[k]) || r[k] < 0 || r[k] > max) return k;
  if (r.ok && (r.reason !== '' || (r.outcome !== 'won' && r.outcome !== 'lost'))) return 'ok_inconsistent';
  return '';
}

/** Queue a closed run. Inert unless VERIFY_SHADOW === '1'. Never throws: a queue problem must not touch the close. */
export async function enqueueVerify(env, { run_id, rules_version, outcome, platform = 'unknown', kind = 'normal', client_score = null, header_mismatch = false, payload }) {
  try {
    if (!env || env.VERIFY_SHADOW !== '1' || !env.DB) return false;
    const body = JSON.stringify(payload ?? null);
    const tooBig = new TextEncoder().encode(body).length > MAX_PAYLOAD_BYTES;
    const plat = typeof platform === 'string' && /^[a-z0-9_-]{1,16}$/.test(platform) ? platform : 'unknown';
    const k = ['normal', 'daily', 'ranked', 'mission'].includes(kind) ? kind : 'normal';
    const cs = Number.isSafeInteger(client_score) && client_score >= 0 ? client_score : null;
    const now = Math.floor(Date.now() / 1000);
    await env.DB.prepare(
      `INSERT OR IGNORE INTO verify_queue (run_id, rules_version, platform, kind, state, srv_outcome, client_score, header_mismatch, payload_json, reason, created_at, finished_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    ).bind(run_id, rules_version, plat, k, tooBig ? 'error' : 'pending', outcome, cs, header_mismatch ? 1 : 0, tooBig ? null : body,
      tooBig ? 'payload_too_large' : null, now, tooBig ? now : null).run();
    return true;
  } catch (err) {
    console.error('verify enqueue failed', String(err));
    return false;
  }
}

/** verdict of a result against what the server/client recorded. state: ok (match) | mismatch | error (could not judge). */
export function judge(result, job) {
  if (result.ok) {
    if (result.outcome !== job.srv_outcome) return { state: 'mismatch', verdict: 'outcome_mismatch' };
    if (job.client_score != null && result.score !== job.client_score) return { state: 'mismatch', verdict: 'score_mismatch' };
    return { state: 'ok', verdict: 'match' };
  }
  if (NOT_A_VERDICT.has(result.reason) || result.rules_version !== job.rules_version) return { state: 'error', verdict: 'error' };
  return { state: 'mismatch', verdict: 'rejected' };
}

async function stats(env, url) {
  const n = Math.min(100, Math.max(1, Number(url.searchParams.get('n')) || 20));
  const all = async (q, ...b) => ((await env.DB.prepare(q).bind(...b).all()).results) || [];
  const queue = await all('SELECT state, COUNT(*) AS n FROM verify_queue GROUP BY state');
  const verdicts = await all('SELECT verdict, kind, COUNT(*) AS n FROM verify_results GROUP BY verdict, kind');
  const platforms = await all('SELECT platform, verdict, COUNT(*) AS n FROM verify_results GROUP BY platform, verdict');
  const hm = await env.DB.prepare('SELECT COUNT(*) AS n FROM verify_queue WHERE header_mismatch = 1').bind().first();
  const last = await all(
    `SELECT run_id, verdict, kind, platform, reason, srv_outcome, v_outcome, client_score, v_score, rules_version, ms, at
       FROM verify_results WHERE verdict NOT IN ('match', 'error') ORDER BY at DESC LIMIT ?`, n);
  return json({ queue, verdicts, platforms, header_mismatch_jobs: hm ? hm.n : 0, last_mismatches: last });
}

/**
 * Housekeeping, run opportunistically from /next, bounded by SWEEP_LIMIT per statement. Never throws.
 *  - pending, attempts used up and lease over -> error 'attempts_exhausted' (payload dropped)
 *  - pending older than PENDING_EXPIRE_S -> error 'expired' (payload dropped), so an idle runner cannot fill D1
 *  - ok/mismatch/error rows older than DONE_RETAIN_S lose their payload (results stay in verify_results)
 */
export async function sweep(env, nowS) {
  const stmts = [
    [`UPDATE verify_queue SET state = 'error', reason = 'attempts_exhausted', payload_json = NULL, finished_at = ?
       WHERE run_id IN (SELECT run_id FROM verify_queue WHERE state = 'pending' AND attempts >= ? AND claimed_at < ? LIMIT ?)`, [nowS, MAX_ATTEMPTS, nowS - LEASE_S, SWEEP_LIMIT]],
    [`UPDATE verify_queue SET state = 'error', reason = 'expired', payload_json = NULL, finished_at = ?
       WHERE run_id IN (SELECT run_id FROM verify_queue WHERE state = 'pending' AND created_at < ? LIMIT ?)`, [nowS, nowS - PENDING_EXPIRE_S, SWEEP_LIMIT]],
    [`UPDATE verify_queue SET payload_json = NULL
       WHERE run_id IN (SELECT run_id FROM verify_queue WHERE state != 'pending' AND payload_json IS NOT NULL AND finished_at < ? LIMIT ?)`, [nowS - DONE_RETAIN_S, SWEEP_LIMIT]],
  ];
  for (const [q, b] of stmts) {
    try { await env.DB.prepare(q).bind(...b).run(); } catch (err) { console.error('verify sweep failed', String(err)); }
  }
}

export async function handleVerify(request, env, url, nowS = Math.floor(Date.now() / 1000)) {
  if (!env.VERIFY_HMAC_KEY || !env.DB) return json({ error: 'not_found' }, 404);
  const isStats = url.pathname === '/api/verify/stats';
  if (request.method !== (isStats ? 'GET' : 'POST')) return json({ error: 'method' }, 405);
  // Cheap checks first: timestamp window and declared length, before the body is read or any HMAC is computed.
  const ts = Number(request.headers.get('x-verify-ts'));
  const sig = request.headers.get('x-verify-sig') || '';
  if (!Number.isInteger(ts) || Math.abs(nowS - ts) > SKEW_S || !/^[a-f0-9]{64}$/.test(sig)) return json({ error: 'unauthorized' }, 401);
  const declared = Number(request.headers.get('content-length') || 0);
  if (declared > MAX_BODY) return json({ error: 'too_large' }, 413);
  const body = isStats ? '' : await request.text();
  if (new TextEncoder().encode(body).length > MAX_BODY) return json({ error: 'too_large' }, 413);
  if (!sameHex(sig, await signVerify(env.VERIFY_HMAC_KEY, ts, request.method, url.pathname, body))) return json({ error: 'unauthorized' }, 401);
  if (isStats) return stats(env, url);
  let m;
  try { m = body ? JSON.parse(body) : {}; } catch { return json({ error: 'bad_request' }, 400); }

  if (url.pathname === '/api/verify/next') {
    await sweep(env, nowS);
    // Claim one job: pending, under the attempt cap, not leased. Lease expires after LEASE_S so a dead runner does not strand it.
    const row = await env.DB.prepare(
      `SELECT run_id, rules_version, payload_json FROM verify_queue
        WHERE state = 'pending' AND attempts < ? AND (claimed_at IS NULL OR claimed_at < ?) ORDER BY created_at LIMIT 1`,
    ).bind(MAX_ATTEMPTS, nowS - LEASE_S).first();
    if (!row) return json({ job: null });
    const upd = await env.DB.prepare(
      `UPDATE verify_queue SET attempts = attempts + 1, claimed_at = ? WHERE run_id = ? AND state = 'pending' AND (claimed_at IS NULL OR claimed_at < ?)`,
    ).bind(nowS, row.run_id, nowS - LEASE_S).run();
    if (!upd.meta || upd.meta.changes !== 1) return json({ job: null }); // someone else won the claim
    return json({ job: { run_id: row.run_id, rules_version: row.rules_version, payload: JSON.parse(row.payload_json) } });
  }

  // /api/verify/result
  if (typeof m.run_id !== 'string' || !/^[a-f0-9]{32}$/.test(m.run_id)) return json({ error: 'bad_request' }, 400);
  const bad = checkResult(m.result);
  if (bad) return json({ error: 'bad_result', field: bad }, 400);
  const job = await env.DB.prepare('SELECT state, srv_outcome, rules_version, claimed_at, client_score, kind, platform FROM verify_queue WHERE run_id = ?').bind(m.run_id).first();
  if (!job) return json({ error: 'not_found' }, 404);
  if (job.state !== 'pending' || job.claimed_at == null || job.claimed_at < nowS - LEASE_S) return json({ error: 'not_claimed' }, 409);
  const { state, verdict } = judge(m.result, job);
  const r = m.result;
  // Only verify_queue and verify_results are written. Never runs, wallet or leaderboard.
  await env.DB.batch([
    env.DB.prepare(
      `UPDATE verify_queue SET state = ?, result_json = ?, reason = ?, finished_at = ?, payload_json = NULL WHERE run_id = ? AND state = 'pending'`,
    ).bind(state, JSON.stringify(r), r.reason || null, nowS, m.run_id),
    env.DB.prepare(
      `INSERT OR REPLACE INTO verify_results (run_id, verdict, kind, platform, rules_version, srv_outcome, client_score, ok, reason, v_outcome, v_score, nodes, log_len, ms, at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    ).bind(m.run_id, verdict, job.kind, job.platform, r.rules_version, job.srv_outcome, job.client_score, r.ok ? 1 : 0, r.reason, r.outcome, r.score, r.nodes, r.log_len, r.ms, nowS),
  ]);
  return json({ ok: true, state, verdict });
}
