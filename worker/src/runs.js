// HTTP side of runs (contract 6.2): create, find the open one, abandon, WebSocket upgrade.
// Auth today is the session cookie. TODO(LIAM-1): Bearer tokens for desktop once the loopback+PKCE
// login lands. TODO: guests (ADR C3) need a server-issued guest account before this accepts them.
import { shared } from './accounts.js';
import { signRunToken } from './run_token.js';
import { rulesSupported } from './run_do.js';

const RULES_PER_DAY_DEFAULT = 20;
const NEWCOMER_RUNS = 5;
// A run still 'pending' after this long never got its DO confirmed: it is our failure, not the player's.
export const PENDING_TTL_S = 5 * 60;
// Modes that need the wallet / newcomer gate. Refused (fail closed) until those exist; staging can set
// ALLOW_GATED_MODES=1 to test them.
const GATED_MODES = new Set(['ranked', 'mission']);
const MODES = new Set(['normal', 'mission', 'ranked']);
const { json } = shared;

const hex = (bytes) => Array.from(bytes, (b) => b.toString(16).padStart(2, '0')).join('');
const stub = (env, runId) => env.RUN_DO.get(env.RUN_DO.idFromName(runId));
const wsUrl = (url, runId) => `wss://${url.host}/api/run/${runId}/ws`;

export const isRunsPath = (p) => p === '/api/run' || p === '/api/run/open' || /^\/api\/run\/[a-f0-9]{32}\/(ws|abandon)$/.test(p);

async function newcomer(env, playerId) {
  const r = await env.DB.prepare('SELECT COUNT(*) AS n FROM runs WHERE player_id = ? AND battles_done >= 1').bind(playerId).first();
  return r.n < NEWCOMER_RUNS;
}

async function createRun(request, env, url, player) {
  if (request.headers.get('Origin') && !shared.isAllowedOrigin(request.headers.get('Origin'), url)) return json({ error: 'forbidden' }, 403);
  let body;
  try { body = await request.json(); } catch { return json({ error: 'bad_request' }, 400); }
  if (!body || typeof body !== 'object' || Array.isArray(body)) return json({ error: 'bad_request' }, 400);
  const mode = body.mode ?? 'normal';
  const ascension = Number.isInteger(body.ascension) ? body.ascension : 0;
  const rules = body.rules_version;
  const nonce = body.client_nonce ?? null;
  if (!MODES.has(mode) || ascension < 0 || ascension > 10 || typeof rules !== 'string' || !/^[a-z0-9_.-]{1,40}$/.test(rules)) return json({ error: 'bad_request' }, 400);
  if (nonce !== null && !/^[a-f0-9]{32}$/.test(nonce)) return json({ error: 'bad_request' }, 400);
  if (!rulesSupported(env, rules)) return json({ error: 'version' }, 409);
  if (GATED_MODES.has(mode) && env.ALLOW_GATED_MODES !== '1') return json({ error: 'not_available' }, 403);
  // TODO(wallet/LIAM-2): mission stake, Boon source, newcomer gating for ranked/mission go in this batch.

  const runId = hex(crypto.getRandomValues(new Uint8Array(16)));
  const nowS = Math.floor(Date.now() / 1000);
  const dayStart = nowS - (nowS % 86400);
  const cap = Number(env.RUNS_PER_DAY) || RULES_PER_DAY_DEFAULT;
  // A pending run of this player that never got confirmed would block them forever (unique index).
  await env.DB.prepare(`UPDATE runs SET state = 'infra_error', closed_at = ? WHERE player_id = ? AND state = 'pending' AND created_at < ?`)
    .bind(nowS, player.id, nowS - PENDING_TTL_S).run();
  let res;
  try {
    // Cap check and insert are one statement, so concurrent requests cannot both slip under the cap.
    res = await env.DB.batch([
      env.DB.prepare(
        `INSERT INTO runs (run_id, player_id, mode, ascension, rules_version, state, created_at)
         SELECT ?, ?, ?, ?, ?, 'pending', ?
          WHERE ? = 'mission'
             OR (SELECT COUNT(*) FROM runs WHERE player_id = ? AND created_at >= ? AND mode != 'mission' AND state != 'infra_error') < ?`,
      ).bind(runId, player.id, mode, ascension, rules, nowS, mode, player.id, dayStart, cap),
    ]);
  } catch (err) {
    if (/UNIQUE/i.test(String(err && err.message || err))) return json({ error: 'run_open' }, 409);
    throw err;
  }
  if (res[0].meta.changes !== 1) return json({ error: 'daily_cap' }, 429);

  let init;
  try {
    const r = await stub(env, runId).fetch('https://do/init', {
      method: 'POST',
      body: JSON.stringify({ run_id: runId, player_id: player.id, mode, rules_version: rules, client_nonce: nonce }),
    });
    init = await r.json();
  } catch (err) {
    init = { ok: false, code: 'infra' };
  }
  if (!init.ok) {
    // Our fault, not the player's: free the slot (a stake, once it exists, is refunded here).
    await env.DB.prepare(`UPDATE runs SET state = 'infra_error', closed_at = ? WHERE run_id = ?`).bind(nowS, runId).run();
    return json({ error: init.code === 'version' ? 'version' : 'server' }, init.code === 'version' ? 409 : 502);
  }
  await env.DB.prepare(`UPDATE runs SET state = 'open', commit_hash = ? WHERE run_id = ? AND state = 'pending'`).bind(init.commit, runId).run();
  const run_token = await signRunToken(env, { player_id: player.id, run_id: runId, rules_version: rules });
  return json({ run_id: runId, run_token, commit: init.commit, ws_url: wsUrl(url, runId), header: { newcomer: await newcomer(env, player.id) } });
}

async function openRun(env, url, player) {
  const row = await env.DB.prepare(`SELECT run_id, rules_version, mode, commit_hash FROM runs WHERE player_id = ? AND state = 'open'`).bind(player.id).first();
  if (!row) return json({});
  const run_token = await signRunToken(env, { player_id: player.id, run_id: row.run_id, rules_version: row.rules_version });
  return json({ run_id: row.run_id, run_token, commit: row.commit_hash, ws_url: wsUrl(url, row.run_id), header: { mode: row.mode, newcomer: await newcomer(env, player.id) } });
}

async function abandon(request, env, url, player, runId) {
  if (request.headers.get('Origin') && !shared.isAllowedOrigin(request.headers.get('Origin'), url)) return json({ error: 'forbidden' }, 403);
  const row = await env.DB.prepare('SELECT state FROM runs WHERE run_id = ? AND player_id = ?').bind(runId, player.id).first();
  if (!row) return json({ error: 'not_found' }, 404);
  if (row.state === 'pending') {
    // Creation never confirmed: free the slot. The DO may or may not exist, so its answer is ignored.
    await stub(env, runId).fetch('https://do/abandon', { method: 'POST' }).catch(() => {});
    await env.DB.prepare(`UPDATE runs SET state = 'abandoned', outcome = 'lost', closed_at = ? WHERE run_id = ? AND state = 'pending'`)
      .bind(Math.floor(Date.now() / 1000), runId).run();
  } else if (row.state === 'open') {
    const r = await stub(env, runId).fetch('https://do/abandon', { method: 'POST' });
    if (!r.ok) return json({ error: 'server' }, 502);
    await env.DB.prepare(`UPDATE runs SET state = 'abandoned', outcome = 'lost', closed_at = ? WHERE run_id = ? AND state = 'open'`)
      .bind(Math.floor(Date.now() / 1000), runId).run();
  }
  return json({ ok: true });
}

async function upgrade(request, env, url, runId) {
  if (request.headers.get('Upgrade') !== 'websocket') return json({ error: 'bad_request' }, 426);
  const origin = request.headers.get('Origin');
  if (origin && !shared.isAllowedOrigin(origin, url)) return json({ error: 'forbidden' }, 403);
  if (env.RUN_LIMITER) {
    const { success } = await env.RUN_LIMITER.limit({ key: `ws:${request.headers.get('CF-Connecting-IP') || 'unknown'}` });
    if (!success) return json({ error: 'rate_limited' }, 429);
  }
  // A bogus or finished run id must not wake a Durable Object (ADR 4.6): D1 answers first.
  const row = await env.DB.prepare(`SELECT 1 AS ok FROM runs WHERE run_id = ? AND state = 'open'`).bind(runId).first();
  if (!row) return json({ error: 'not_found' }, 404);
  return stub(env, runId).fetch(request);
}

export async function handleRuns(request, env, url) {
  try {
    const m = /^\/api\/run\/([a-f0-9]{32})\/(ws|abandon)$/.exec(url.pathname);
    if (m && m[2] === 'ws' && request.method === 'GET') return await upgrade(request, env, url, m[1]);
    const player = await shared.currentPlayer(request, env);
    if (!player) return json({ error: 'unauthenticated' }, 401);
    if (env.RUN_LIMITER) {
      const { success } = await env.RUN_LIMITER.limit({ key: `p:${player.id}` });
      if (!success) return json({ error: 'rate_limited' }, 429);
    }
    if (url.pathname === '/api/run' && request.method === 'POST') return await createRun(request, env, url, player);
    if (url.pathname === '/api/run/open' && request.method === 'GET') return await openRun(env, url, player);
    if (m && m[2] === 'abandon' && request.method === 'POST') return await abandon(request, env, url, player, m[1]);
    return json({ error: 'not_found' }, 404);
  } catch (err) {
    console.error('runs error', url.pathname, String(err && err.stack || err));
    return json({ error: 'server' }, 500);
  }
}


/** Cron: runs stuck in 'pending' (DO init never confirmed) become infra_error so nobody stays locked out. */
export async function sweepPending(env, nowS = Math.floor(Date.now() / 1000)) {
  const r = await env.DB.prepare(`UPDATE runs SET state = 'infra_error', closed_at = ? WHERE state = 'pending' AND created_at < ?`)
    .bind(nowS, nowS - PENDING_TTL_S).run();
  return r.meta.changes;
}
