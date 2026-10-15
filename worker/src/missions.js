// Mission stake escrow (L1 option A). The server keeps the stake from the moment the run is created and
// settles it exactly once when the run ends: won -> stake x multiplier (clamped to the cap), lost/abandoned ->
// nothing, infra_error -> the stake back. Win/loss is the client's claim (same trust as the leaderboard until
// the verifier lands); what the server DOES enforce is that the stake matches its table, the payout can never
// exceed the table's cap, and a run settles at most once.
//
// The table is godot/assets/data/economy/missions.json itself (one source, bundled by wrangler). Shard has no
// server balance: its movements are recorded in wallet_ledger with currency 'shard' and never touch `wallets`.
import table from '../../godot/assets/data/economy/missions.json' with { type: 'json' };
import { shared } from './accounts.js';

const { json } = shared;
const nowS = () => Math.floor(Date.now() / 1000);

export const PAYOUT_CAP = Number(table.payout_cap) > 0 ? Number(table.payout_cap) : 20000;
const SETTLED_TAIL = 10;

export const isMissionsPath = (p) => p === '/api/missions/escrow';

/** Same rounding as MissionBoard.payout in the client: round5(stake x m), then the cap. */
export const payoutFor = (stake, mult) => Math.min(PAYOUT_CAP, Math.round((stake * mult) / 5) * 5);

/**
 * Check the `mission` block of POST /api/run against the table.
 * -> {ok:true, tier, stake, mult} | {ok:false, status, error}.
 * N4..N6 exist in the table but are disabled in this build: 403 tier_locked. Unknown/garbled tier: 400.
 */
export function validateMission(m, ascension) {
  const bad = { ok: false, status: 400, error: 'bad_request' };
  if (!m || typeof m !== 'object' || Array.isArray(m)) return bad;
  if (typeof m.tier !== 'string' || !/^N[1-6]$/.test(m.tier) || !Number.isSafeInteger(m.stake)) return bad;
  const t = table.tiers[m.tier];
  if (!t) return bad;
  if (t.enabled !== true) return { ok: false, status: 403, error: 'tier_locked' };
  if (m.stake !== t.stake) return { ok: false, status: 409, error: 'stake_mismatch' };
  if (ascension !== t.ascension) return { ok: false, status: 409, error: 'tier_mismatch' };
  return { ok: true, tier: m.tier, stake: t.stake, mult: Number(t.m_base) * Number(t.m_scale ?? 1) };
}

/** Statements that open the escrow. They only insert when the run row of the same batch exists, so a refused
 *  run (cap, unique-open) leaves no escrow and no ledger row behind. */
export function escrowStatements(env, { runId, playerId, tier, stake, mult, at }) {
  return [
    env.DB.prepare(
      `INSERT INTO mission_escrow (run_id, player_id, tier, stake, payout_mult, state, payout, created_at)
       SELECT ?, ?, ?, ?, ?, 'open', 0, ? WHERE EXISTS (SELECT 1 FROM runs WHERE run_id = ?)`,
    ).bind(runId, playerId, tier, stake, mult, at, runId),
    env.DB.prepare(
      `INSERT OR IGNORE INTO wallet_ledger (player_id, currency, delta, reason, idem_key, at)
       SELECT ?, 'shard', ?, ?, ?, ? WHERE EXISTS (SELECT 1 FROM mission_escrow WHERE run_id = ?)`,
    ).bind(playerId, -stake, `mission_stake:${tier}`, `mission_stake:${runId}`, at, runId),
  ];
}

/**
 * Close the escrow of `runId` as 'won' | 'lost' | 'refunded'. Idempotent and race-safe: the state flips only
 * from 'open', the ledger row is keyed per run, whoever settles first wins. Returns the escrow row after the
 * call ({run_id, tier, stake, state, payout, settled_at}), or null when the run has no escrow.
 */
export async function settleEscrow(env, runId, outcome, at = nowS()) {
  const row = await env.DB.prepare('SELECT * FROM mission_escrow WHERE run_id = ?').bind(runId).first();
  if (!row) return null;
  if (row.state !== 'open') return pub(row);
  const state = outcome === 'won' || outcome === 'refunded' ? outcome : 'lost';
  const payout = state === 'won' ? payoutFor(row.stake, row.payout_mult) : state === 'refunded' ? row.stake : 0;
  const stmts = [
    env.DB.prepare(`UPDATE mission_escrow SET state = ?, payout = ?, settled_at = ? WHERE run_id = ? AND state = 'open'`)
      .bind(state, payout, at, runId),
  ];
  if (payout > 0) {
    stmts.push(env.DB.prepare(
      `INSERT OR IGNORE INTO wallet_ledger (player_id, currency, delta, reason, idem_key, at)
       SELECT ?, 'shard', ?, ?, ?, ? WHERE EXISTS (SELECT 1 FROM mission_escrow WHERE run_id = ? AND state = ? AND settled_at = ?)`,
    ).bind(row.player_id, payout, state === 'won' ? `mission_win:${row.tier}` : 'mission_refund', `mission_settle:${runId}`, at, runId, state, at));
  }
  await env.DB.batch(stmts);
  return pub(await env.DB.prepare('SELECT * FROM mission_escrow WHERE run_id = ?').bind(runId).first());
}

const pub = (r) => ({ run_id: r.run_id, tier: r.tier, stake: r.stake, state: r.state, payout: r.payout, settled_at: r.settled_at });

/** Settle every open escrow whose run is over but was never settled (a failed write-back, a stale pending
 *  swept to infra_error). Per player when playerId is given, else everyone (cron). */
export async function reconcileEscrows(env, playerId = null) {
  const q = `SELECT e.run_id, r.state AS rs, r.outcome AS ro FROM mission_escrow e JOIN runs r ON r.run_id = e.run_id
              WHERE e.state = 'open' AND r.state NOT IN ('pending', 'open')${playerId ? ' AND e.player_id = ?' : ''} LIMIT 100`;
  const st = env.DB.prepare(q);
  const { results } = await (playerId ? st.bind(playerId) : st).all();
  for (const r of results) {
    await settleEscrow(env, r.run_id, r.rs === 'infra_error' ? 'refunded' : r.rs === 'closed' && r.ro === 'won' ? 'won' : 'lost');
  }
  return results.length;
}

/** GET /api/missions/escrow: the open escrow (if any) and the last settlements, so the client can reconcile. */
async function escrowInfo(env, player) {
  await reconcileEscrows(env, player.id);
  const open = await env.DB.prepare(`SELECT * FROM mission_escrow WHERE player_id = ? AND state = 'open' ORDER BY created_at DESC LIMIT 1`).bind(player.id).first();
  const tail = await env.DB.prepare(`SELECT * FROM mission_escrow WHERE player_id = ? AND state != 'open' ORDER BY settled_at DESC, created_at DESC LIMIT ${SETTLED_TAIL}`).bind(player.id).all();
  return json({
    open: open ? { run_id: open.run_id, tier: open.tier, stake: open.stake, payout_mult: open.payout_mult, created_at: open.created_at } : null,
    settled: tail.results.map(pub),
  });
}

export async function handleMissions(request, env, url) {
  try {
    const player = await shared.currentPlayer(request, env);
    if (!player) return json({ error: 'unauthenticated' }, 401);
    if (env.RUN_LIMITER) {
      const { success } = await env.RUN_LIMITER.limit({ key: `p:${player.id}` });
      if (!success) return json({ error: 'rate_limited' }, 429);
    }
    if (url.pathname === '/api/missions/escrow' && request.method === 'GET') return await escrowInfo(env, player);
    return json({ error: 'not_found' }, 404);
  } catch (err) {
    console.error('missions error', url.pathname, String(err && err.stack || err));
    return json({ error: 'server' }, 500);
  }
}
