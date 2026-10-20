// HTTP side of runs (contract 6.2): create, find the open one, abandon, WebSocket upgrade.
// Auth today is the session cookie. TODO(LIAM-1): Bearer tokens for desktop once the loopback+PKCE
// login lands. TODO: guests (ADR C3) need a server-issued guest account before this accepts them.
import { shared } from './accounts.js';
import { signRunToken, newJti } from './run_token.js';
import { rulesSupported } from './run_do.js';
import { validateMission, escrowStatements, settleEscrow, reconcileEscrows } from './missions.js';

const RULES_PER_DAY_DEFAULT = 20;
const NEWCOMER_RUNS = 5;
// A run still 'pending' after this long never got its DO confirmed: it is our failure, not the player's.
export const PENDING_TTL_S = 5 * 60;
// Modes refused (fail closed) unless ALLOW_GATED_MODES=1. Empty now: ranked opened in L1 C2 and mission in
// L1 S (stake escrow, src/missions.js); both keep the newcomer gate below. ALLOW_GATED_MODES=1 (staging) still
// lifts that gate, so it must NOT be set on production.
const GATED_MODES = new Set([]);
const DAILY_TRIES_DEFAULT = 3;               // Daily tries per UTC day, abandoned runs count (Liam 14/10)
const VAULT_PREFIX = 'vault_';               // MetaState.VAULT_KEY_PREFIX: an imported Axie, never allowed in Ranked
// RunParams.kind (contract 3.6). RunParams.mode (short|full) is game length and goes in run_start args.
const KINDS = new Set(['normal', 'daily', 'ranked', 'mission']);
const { json } = shared;

const hex = (bytes) => Array.from(bytes, (b) => b.toString(16).padStart(2, '0')).join('');
const stub = (env, runId) => env.RUN_DO.get(env.RUN_DO.idFromName(runId));
const wsUrl = (url, runId) => `wss://${url.host}/api/run/${runId}/ws`;

export const isRunsPath = (p) => p === '/api/run' || p === '/api/run/open' || /^\/api\/run\/[a-f0-9]{32}\/(ws|abandon)$/.test(p) || p === '/api/run/daily';

async function newcomer(env, playerId) {
  const r = await env.DB.prepare('SELECT COUNT(*) AS n FROM runs WHERE player_id = ? AND battles_done >= 1').bind(playerId).first();
  return r.n < NEWCOMER_RUNS;
}

// Depth v4 3.8 (N7): stage 2 from STAGE2_RUNS completed runs, stage 3 from STAGE3_RUNS; an account already past the newcomer gate starts at 3.
// "Completed" = a run the Durable Object wrote back as closed (won or lost); a run that only has run_start, or was abandoned, never counts.
const STAGE2_RUNS = 1;
const STAGE3_RUNS = 3;
export async function depthStage(env, playerId) {
  const r = await env.DB.prepare(`SELECT COUNT(*) AS n FROM runs WHERE player_id = ? AND state = 'closed' AND outcome IN ('won', 'lost')`).bind(playerId).first();
  const n = r ? r.n : 0;
  if (n >= STAGE3_RUNS) return 3;
  if (n >= STAGE2_RUNS) return 2;
  return (await newcomer(env, playerId)) ? 1 : 3;
}

async function createRun(request, env, url, player) {
  if (request.headers.get('Origin') && !shared.isAllowedOrigin(request.headers.get('Origin'), url)) return json({ error: 'forbidden' }, 403);
  let body;
  try { body = await request.json(); } catch { return json({ error: 'bad_request' }, 400); }
  if (!body || typeof body !== 'object' || Array.isArray(body)) return json({ error: 'bad_request' }, 400);
  const mode = body.kind ?? 'normal'; // stored in runs.mode / DO meta.mode
  const ascension = Number.isInteger(body.ascension) ? body.ascension : 0;
  const rules = body.rules_version;
  const nonce = body.client_nonce ?? null;
  if (!KINDS.has(mode) || ascension < 0 || ascension > 10 || typeof rules !== 'string' || !/^[a-z0-9_.-]{1,40}$/.test(rules)) return json({ error: 'bad_request' }, 400);
  if (nonce !== null && !/^[a-f0-9]{32}$/.test(nonce)) return json({ error: 'bad_request' }, 400);
  if (!rulesSupported(env, rules)) return json({ error: 'version' }, 409);
  if (GATED_MODES.has(mode) && env.ALLOW_GATED_MODES !== '1') return json({ error: 'not_available' }, 403);
  // Ranked: newcomers (< 5 runs with a fight) wait; imported (vault) Axies are refused. The server cannot see
  // the team, so team_keys is the client's word - an honest-client check until the verifier (P3) lands.
  if (mode === 'ranked') {
    if (body.team_keys !== undefined && (!Array.isArray(body.team_keys) || body.team_keys.length > 5 || body.team_keys.some((k) => typeof k !== 'string' || k.length > 80))) return json({ error: 'bad_request' }, 400);
    if (Array.isArray(body.team_keys) && body.team_keys.some((k) => k.startsWith(VAULT_PREFIX))) return json({ error: 'vault_banned' }, 403);
    if (env.ALLOW_GATED_MODES !== '1' && await newcomer(env, player.id)) return json({ error: 'newcomer_locked' }, 403);
  }
  // Mission: stake and tier are checked against the server's table; N4..N6 are locked in this build. Same
  // newcomer gate as ranked. The escrow rows go in the run's own batch below.
  let mission = null;
  if (mode === 'mission') {
    mission = validateMission(body.mission, ascension);
    if (!mission.ok) return json({ error: mission.error }, mission.status);
    if (env.ALLOW_GATED_MODES !== '1' && await newcomer(env, player.id)) return json({ error: 'newcomer_locked' }, 403);
  } else if (body.mission !== undefined) return json({ error: 'bad_request' }, 400);
  // TODO(wallet/LIAM-2): Boon source goes in this batch.
  const dailyMax = Number(env.DAILY_TRIES) || DAILY_TRIES_DEFAULT;

  const stage = await depthStage(env, player.id);
  // Depth v4: ranked only opens at stage 3.
  if (mode === 'ranked' && stage < 3 && env.ALLOW_GATED_MODES !== '1') return json({ error: 'ranked_stage' }, 403);
  const runId = hex(crypto.getRandomValues(new Uint8Array(16)));
  const nowS = Math.floor(Date.now() / 1000);
  const dayStart = nowS - (nowS % 86400);
  const cap = Number(env.RUNS_PER_DAY) || RULES_PER_DAY_DEFAULT;
  // A pending run of this player that never got confirmed would block them forever (unique index).
  await env.DB.prepare(`UPDATE runs SET state = 'infra_error', closed_at = ? WHERE player_id = ? AND state = 'pending' AND created_at < ?`)
    .bind(nowS, player.id, nowS - PENDING_TTL_S).run();
  if (mission) await reconcileEscrows(env, player.id); // a swept pending mission run gets its stake back
  let res;
  try {
    // Cap check and insert are one statement, so concurrent requests cannot both slip under the cap.
    res = await env.DB.batch([
      env.DB.prepare(
        `INSERT INTO runs (run_id, player_id, mode, ascension, rules_version, state, created_at, depth_stage)
         SELECT ?, ?, ?, ?, ?, 'pending', ?, ?
          WHERE (? = 'mission'
             OR (SELECT COUNT(*) FROM runs WHERE player_id = ? AND created_at >= ? AND mode != 'mission' AND state != 'infra_error') < ?)
           AND (? != 'daily'
             OR (SELECT COUNT(*) FROM runs WHERE player_id = ? AND mode = 'daily' AND created_at >= ? AND state != 'infra_error') < ?)`,
      ).bind(runId, player.id, mode, ascension, rules, nowS, stage, mode, player.id, dayStart, cap, mode, player.id, dayStart, dailyMax),
      ...(mission ? escrowStatements(env, { runId, playerId: player.id, tier: mission.tier, stake: mission.stake, mult: mission.mult, at: nowS }) : []),
    ]);
  } catch (err) {
    if (/UNIQUE/i.test(String(err && err.message || err))) return json({ error: 'run_open' }, 409);
    throw err;
  }
  if (res[0].meta.changes !== 1) {
    if (mode === 'daily' && (await dailyUsed(env, player.id, dayStart)) >= dailyMax) return json({ error: 'daily_tries' }, 429);
    return json({ error: 'daily_cap' }, 429);
  }

  let init;
  try {
    const r = await stub(env, runId).fetch('https://do/init', {
      method: 'POST',
      body: JSON.stringify({ run_id: runId, player_id: player.id, mode, ascension, rules_version: rules, client_nonce: nonce, depth_stage: stage }),
    });
    init = await r.json();
  } catch (err) {
    init = { ok: false, code: 'infra' };
  }
  if (!init.ok) {
    // Our fault, not the player's: free the slot (a stake, once it exists, is refunded here).
    await env.DB.prepare(`UPDATE runs SET state = 'infra_error', closed_at = ? WHERE run_id = ?`).bind(nowS, runId).run();
    if (mission) await settleEscrow(env, runId, 'refunded');
    return json({ error: init.code === 'version' ? 'version' : 'server' }, init.code === 'version' ? 409 : 502);
  }
  const jti = newJti();
  await env.DB.prepare(`UPDATE runs SET state = 'open', commit_hash = ?, token_jti = ? WHERE run_id = ? AND state = 'pending'`).bind(init.commit, jti, runId).run();
  const run_token = await signRunToken(env, { player_id: player.id, run_id: runId, rules_version: rules, jti });
  return json({ run_id: runId, run_token, commit: init.commit, ws_url: wsUrl(url, runId), header: { newcomer: await newcomer(env, player.id), depth_stage: stage } });
}

async function dailyUsed(env, playerId, dayStart) {
  const r = await env.DB.prepare(`SELECT COUNT(*) AS n FROM runs WHERE player_id = ? AND mode = 'daily' AND created_at >= ? AND state != 'infra_error'`).bind(playerId, dayStart).first();
  return r.n;
}

/** GET /api/run/daily: tries used today (UTC), the limit, and when the day turns over. */
async function dailyInfo(env, player) {
  const nowS = Math.floor(Date.now() / 1000);
  const dayStart = nowS - (nowS % 86400);
  const max = Number(env.DAILY_TRIES) || DAILY_TRIES_DEFAULT;
  return json({ used: await dailyUsed(env, player.id, dayStart), max, resets_at: dayStart + 86400 });
}

async function openRun(env, url, player) {
  const row = await env.DB.prepare(`SELECT run_id, rules_version, mode, commit_hash, depth_stage FROM runs WHERE player_id = ? AND state = 'open'`).bind(player.id).first();
  if (!row) return json({});
  // A new token revokes the previous one (other device, or a stolen copy): only the newest jti passes hello.
  const jti = newJti();
  await env.DB.prepare(`UPDATE runs SET token_jti = ? WHERE run_id = ? AND state = 'open'`).bind(jti, row.run_id).run();
  const run_token = await signRunToken(env, { player_id: player.id, run_id: row.run_id, rules_version: row.rules_version, jti });
  return json({ run_id: row.run_id, run_token, commit: row.commit_hash, ws_url: wsUrl(url, row.run_id), header: { mode: row.mode, newcomer: await newcomer(env, player.id), depth_stage: row.depth_stage ?? 3 } });
}

const changed = (r) => ((r && r.meta && r.meta.changes) || 0) > 0;

async function abandon(request, env, url, player, runId) {
  if (request.headers.get('Origin') && !shared.isAllowedOrigin(request.headers.get('Origin'), url)) return json({ error: 'forbidden' }, 403);
  const row = await env.DB.prepare('SELECT state FROM runs WHERE run_id = ? AND player_id = ?').bind(runId, player.id).first();
  if (!row) return json({ error: 'not_found' }, 404);
  const at = Math.floor(Date.now() / 1000);
  // Every settle below is gated on THIS request's UPDATE having changed the row: if a close, a cron sweep or
  // createRun's confirm got there first, the escrow belongs to that path (a lost here would contradict it).
  if (row.state === 'pending') {
    // Creation never confirmed: free the slot. The DO may or may not exist, so its answer is ignored.
    await stub(env, runId).fetch('https://do/abandon', { method: 'POST' }).catch(() => {});
    const u = await env.DB.prepare(`UPDATE runs SET state = 'abandoned', outcome = 'lost', closed_at = ? WHERE run_id = ? AND state = 'pending'`)
      .bind(at, runId).run();
    if (changed(u)) await settleEscrow(env, runId, 'refunded'); // never started: the stake comes back
  } else if (row.state === 'open') {
    const r = await stub(env, runId).fetch('https://do/abandon', { method: 'POST' });
    if (!r.ok) return json({ error: 'server' }, 502);
    let out = {};
    try { out = await r.json(); } catch { out = {}; }
    // The run had already closed (its own write-back and settlement decide the escrow): never mark it lost.
    if (out && out.state === 'closed') return json({ ok: true });
    const u = await env.DB.prepare(`UPDATE runs SET state = 'abandoned', outcome = 'lost', closed_at = ? WHERE run_id = ? AND state = 'open'`)
      .bind(at, runId).run();
    // Abandon = the stake is lost. Only a run that never really started (no epoch answered, i.e. run_start
    // failed) gets the stake back: once run_start is answered the player has seen the map, and a free refund
    // would let them reroll maps (Liam 16/10). Unknown count = lost.
    if (changed(u)) await settleEscrow(env, runId, out && out.epochs === 0 ? 'refunded' : 'lost'); // no-op for a run without escrow
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
    if (url.pathname === '/api/run/daily' && request.method === 'GET') return await dailyInfo(env, player);
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
  try { await reconcileEscrows(env); } catch (err) { console.error('escrow reconcile failed', String(err)); } // e.g. migration 0007 not applied yet
  return r.meta.changes;
}
