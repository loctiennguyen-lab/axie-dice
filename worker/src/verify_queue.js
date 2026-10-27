// SR-V: shadow verifier queue. NEVER affects rewards, outcome or leaderboard: it only records what an
// out-of-process verifier (verifier/, Godot headless, no network) says about a closed run.
//   enqueueVerify(env, row)      called by RunDO after the close is written back; inert unless env.VERIFY_SHADOW === '1'.
//   handleVerify(request, env)   POST /api/verify/next (claim a job) and POST /api/verify/result (submit), HMAC-signed.
// Signature: hex HMAC-SHA256(env.VERIFY_HMAC_KEY, `${ts}\n${METHOD}\n${path}\n${body}`) in X-Verify-Sig, unix seconds in
// X-Verify-Ts (|now - ts| <= 120 s). No key configured = endpoints answer 404 (feature absent).

export const isVerifyPath = (p) => p === '/api/verify/next' || p === '/api/verify/result';

export const MAX_PAYLOAD_BYTES = 1_000_000;
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
export async function enqueueVerify(env, { run_id, rules_version, outcome, platform = 'unknown', payload }) {
  try {
    if (!env || env.VERIFY_SHADOW !== '1' || !env.DB) return false;
    const body = JSON.stringify(payload ?? null);
    const tooBig = body.length > MAX_PAYLOAD_BYTES;
    const plat = typeof platform === 'string' && /^[a-z0-9_-]{1,16}$/.test(platform) ? platform : 'unknown';
    await env.DB.prepare(
      `INSERT OR IGNORE INTO verify_queue (run_id, rules_version, platform, state, srv_outcome, payload_json, reason, created_at, finished_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    ).bind(run_id, rules_version, plat, tooBig ? 'error' : 'pending', outcome, tooBig ? null : body, tooBig ? 'payload_too_large' : null,
      Math.floor(Date.now() / 1000), tooBig ? Math.floor(Date.now() / 1000) : null).run();
    return true;
  } catch (err) {
    console.error('verify enqueue failed', String(err));
    return false;
  }
}

export async function handleVerify(request, env, url, nowS = Math.floor(Date.now() / 1000)) {
  if (!env.VERIFY_HMAC_KEY || !env.DB) return json({ error: 'not_found' }, 404);
  if (request.method !== 'POST') return json({ error: 'method' }, 405);
  const body = await request.text();
  if (body.length > MAX_BODY) return json({ error: 'too_large' }, 413);
  const ts = Number(request.headers.get('x-verify-ts'));
  const sig = request.headers.get('x-verify-sig') || '';
  if (!Number.isInteger(ts) || Math.abs(nowS - ts) > SKEW_S) return json({ error: 'unauthorized' }, 401);
  if (!sameHex(sig, await signVerify(env.VERIFY_HMAC_KEY, ts, 'POST', url.pathname, body))) return json({ error: 'unauthorized' }, 401);
  let m;
  try { m = body ? JSON.parse(body) : {}; } catch { return json({ error: 'bad_request' }, 400); }

  if (url.pathname === '/api/verify/next') {
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
  const job = await env.DB.prepare('SELECT state, srv_outcome, rules_version, claimed_at FROM verify_queue WHERE run_id = ?').bind(m.run_id).first();
  if (!job) return json({ error: 'not_found' }, 404);
  if (job.state !== 'pending' || job.claimed_at == null) return json({ error: 'not_claimed' }, 409);
  let state;
  if (m.result.ok) state = m.result.outcome === job.srv_outcome ? 'ok' : 'mismatch';
  else state = NOT_A_VERDICT.has(m.result.reason) || m.result.rules_version !== job.rules_version ? 'error' : 'mismatch';
  await env.DB.prepare(
    `UPDATE verify_queue SET state = ?, result_json = ?, reason = ?, finished_at = ?, payload_json = NULL WHERE run_id = ? AND state = 'pending'`,
  ).bind(state, JSON.stringify(m.result), m.result.reason || null, nowS, m.run_id).run();
  return json({ ok: true, state });
}
