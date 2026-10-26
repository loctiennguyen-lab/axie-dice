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
import { SUPPORTED_RULE_VERSIONS } from './run_do.js';

const { json } = shared;
const nowS = () => Math.floor(Date.now() / 1000);

// The table in force. Tests swap it for a 6-tier fixture; production never calls the setter.
let T = table;
/** Stone a won Mission tier pays (table `stone`) and the per-UTC-day Stone cap (table `stone_day_cap`). */
export const tierStone = (tier) => (Object.hasOwn(T.tiers, tier) ? Number(T.tiers[tier].stone) || 0 : 0);
export const stoneDayCap = () => Number(T.stone_day_cap) || 0;

/** Test hook: replace (or with no argument restore) the mission table. */
export const _setTableForTest = (t) => { T = t || table; };

export const PAYOUT_CAP = Number(table.payout_cap) > 0 ? Number(table.payout_cap) : 20000;
const SETTLED_TAIL = 10;

export const isMissionsPath = (p) => p === '/api/missions/escrow' || p === '/api/missions/unlocks';

/** Same rounding as MissionBoard.payout in the client: round5(stake x m), then the cap. */
export const payoutFor = (stake, mult) => Math.min(PAYOUT_CAP, Math.round((stake * mult) / 5) * 5);

/** The rules version a mission run must be created under: the newest the Worker serves (last of the list). */
export const currentRules = (env) => {
  const list = env && env.SUPPORTED_RULES ? env.SUPPORTED_RULES.split(',') : SUPPORTED_RULE_VERSIONS;
  return list[list.length - 1];
};

const offTiers = (env) => String((env && env.MISSION_TIERS_OFF) || '').split(',').map((x) => x.trim());
// A run on older rules is only refunded by the sweep once it is this old (D1 has no last-activity column, so
// created_at bounds it): a Short run lasts well under an hour, 3 h leaves a still-playing tab alone and the
// client's own abandon() refunds the rest straight away.
export const BUMP_STALE_S = 12 * 3600;   // Full mode (N6) runs were never measured; 12h only delays refunds of truly abandoned runs (abandon() refunds at once). Tune after measuring Full.

const tierNo = (id) => Number(id.slice(1));

/** Wins per tier for a player: {N1: 2, ...}. */
export async function winsByTier(env, playerId) {
  const { results } = await env.DB.prepare('SELECT tier, COUNT(*) AS n FROM mission_wins WHERE player_id = ? GROUP BY tier').bind(playerId).all();
  const out = {};
  for (const r of results) out[r.tier] = r.n;
  return out;
}

/** Wins of the previous tier a player needs to open `tier` (table `unlock_wins`, default 1). N1 is always open. */
const winsNeeded = (tier) => (tierNo(tier) <= 1 ? 0 : Math.max(1, Number(T.tiers[tier].unlock_wins) || 1));
const isUnlocked = (wins, tier) => tierNo(tier) <= 1 || (wins[`N${tierNo(tier) - 1}`] || 0) >= winsNeeded(tier);

/** Same set of rule ids, order and duplicates aside (duplicates are refused). */
const sameRules = (got, want) => {
  if (!Array.isArray(got) || got.length !== want.length || got.some((r) => typeof r !== 'string')) return false;
  const a = [...got].sort(); const b = [...want].sort();
  return a.every((r, i) => r === b[i]) && new Set(a).size === a.length;
};

/**
 * Check the `mission` block of POST /api/run against the table and the player's unlocks.
 * -> {ok:true, tier, stake, mult} | {ok:false, status, error}.
 * Errors: 400 bad_request (shape) / mission_rules_mismatch (`rules` differ from the tier's fixed set; N2+ with
 * `rules: []` or no rules lands here), 403 tier_not_unlocked (previous tier not won yet), 409 stake_mismatch /
 * tier_mismatch. The rules check is strict: a tier with `rules: []` (or no `rules` field) accepts only a missing
 * or empty `rules`. This checks the client's CLAIM only; the Durable Object does not know which rules a run
 * plays, so it is not enforcement. Kill switch per tier: table `enabled: false` (missing = on) or env
 * MISSION_TIERS_OFF="N5,N6" (read at runtime) -> 403 tier_locked. Otherwise the win chain is the only gate.
 * Async because the unlock check reads D1.
 */
export async function validateMission(env, playerId, m, ascension) {
  const bad = { ok: false, status: 400, error: 'bad_request' };
  if (!m || typeof m !== 'object' || Array.isArray(m)) return bad;
  if (typeof m.tier !== 'string' || !/^N[1-6]$/.test(m.tier) || !Number.isSafeInteger(m.stake)) return bad;
  const t = Object.hasOwn(T.tiers, m.tier) ? T.tiers[m.tier] : null;
  if (!t) return bad;
  if (m.stake !== t.stake) return { ok: false, status: 409, error: 'stake_mismatch' };
  if (ascension !== t.ascension) return { ok: false, status: 409, error: 'tier_mismatch' };
  if (t.enabled === false || offTiers(env).includes(m.tier)) return { ok: false, status: 403, error: 'tier_locked' };
  // Strict: a tier without a `rules` array counts as `rules: []`, so a table that forgot the field never
  // switches the check off silently (any rule the client sends is refused).
  const want = Array.isArray(t.rules) ? t.rules : [];
  const got = m.rules === undefined && want.length === 0 ? [] : m.rules;
  if (!sameRules(got, want)) return { ok: false, status: 400, error: 'mission_rules_mismatch' };
  if (!isUnlocked(await winsByTier(env, playerId), m.tier)) return { ok: false, status: 403, error: 'tier_not_unlocked' };
  return { ok: true, tier: m.tier, stake: t.stake, mult: Number(t.m_base) * Number(t.m_scale ?? 1) };
}

/** Statements that open the escrow. They only insert when the run row of the same batch exists, so a refused
 *  run (cap, unique-open) leaves no escrow and no ledger row behind. */
// N5: with env.ECON_SHARD_WALLET = '1' the stake is really taken from (and the payout added to) the server Shard
// balance, in the same batch as the ledger row. Default OFF so the L1 behaviour and its tests stay as they were.
const walletOn = (env) => !!env && env.ECON_SHARD_WALLET === '1';
const ensureShard = (env, pid) => env.DB.prepare(`INSERT OR IGNORE INTO wallets (player_id, currency, balance) VALUES (?, 'shard', 0)`).bind(pid);
// Must directly follow the ledger INSERT: changes() = 1 only when that row was really inserted (not a replay/ignore).
// Short funds trip CHECK (balance >= 0) and roll the whole batch back (the run is not created).
const applyShard = (env, pid, delta) => env.DB.prepare(`UPDATE wallets SET balance = balance + ? WHERE player_id = ? AND currency = 'shard' AND changes() = 1`).bind(delta, pid);
export function escrowStatements(env, { runId, playerId, tier, stake, mult, at }) {
  return [
    env.DB.prepare(
      `INSERT INTO mission_escrow (run_id, player_id, tier, stake, payout_mult, state, payout, created_at)
       SELECT ?, ?, ?, ?, ?, 'open', 0, ? WHERE EXISTS (SELECT 1 FROM runs WHERE run_id = ?)`,
    ).bind(runId, playerId, tier, stake, mult, at, runId),
    ...(walletOn(env) ? [ensureShard(env, playerId)] : []),
    env.DB.prepare(
      `INSERT OR IGNORE INTO wallet_ledger (player_id, currency, delta, reason, idem_key, at)
       SELECT ?, 'shard', ?, ?, ?, ? WHERE EXISTS (SELECT 1 FROM mission_escrow WHERE run_id = ?)`,
    ).bind(playerId, -stake, `mission_stake:${tier}`, `mission_stake:${runId}`, at, runId),
    ...(walletOn(env) ? [applyShard(env, playerId, -stake)] : []),
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
    if (walletOn(env)) stmts.push(ensureShard(env, row.player_id));
    stmts.push(env.DB.prepare(
      `INSERT OR IGNORE INTO wallet_ledger (player_id, currency, delta, reason, idem_key, at)
       SELECT ?, 'shard', ?, ?, ?, ? WHERE EXISTS (SELECT 1 FROM mission_escrow WHERE run_id = ? AND state = ? AND settled_at = ?)`,
    ).bind(row.player_id, payout, state === 'won' ? `mission_win:${row.tier}` : 'mission_refund', `mission_settle:${runId}`, at, runId, state, at));
    if (walletOn(env)) stmts.push(applyShard(env, row.player_id, payout));
  }
  if (state === 'won') {
    stmts.push(env.DB.prepare(
      `INSERT OR IGNORE INTO mission_wins (run_id, player_id, tier, at)
       SELECT ?, ?, ?, ? WHERE EXISTS (SELECT 1 FROM mission_escrow WHERE run_id = ? AND state = 'won' AND settled_at = ?)`,
    ).bind(runId, row.player_id, row.tier, at, runId, at));
  }
  await env.DB.batch(stmts);
  return pub(await env.DB.prepare('SELECT * FROM mission_escrow WHERE run_id = ?').bind(runId).first());
}

const pub = (r) => ({ run_id: r.run_id, tier: r.tier, stake: r.stake, state: r.state, payout: r.payout, settled_at: r.settled_at });

/** Settle every open escrow whose run is over but was never settled (a failed write-back, a stale pending
 *  swept to infra_error). Also refund the stake of a run created under an older rules version than the
 *  current one: the client never resumes a run on other rules (RunState.gd), so it can only be abandoned or
 *  left open, and the player must not pay for our bump. A run that really closed 'won' still pays as won.
 *  Per player when playerId is given, else everyone (cron). */
export async function reconcileEscrows(env, playerId = null) {
  const q = `SELECT e.run_id, r.state AS rs, r.outcome AS ro, r.rules_version AS rv FROM mission_escrow e JOIN runs r ON r.run_id = e.run_id
              WHERE e.state = 'open' AND r.state != 'pending' AND (r.state != 'open' OR (r.rules_version != ? AND r.created_at < ?))${playerId ? ' AND e.player_id = ?' : ''} LIMIT 100`;
  const cur = currentRules(env);
  const st = env.DB.prepare(q);
  const stale = nowS() - BUMP_STALE_S;
  const { results } = await (playerId ? st.bind(cur, stale, playerId) : st.bind(cur, stale)).all();
  for (const r of results) {
    // A run that played to its end (closed) keeps its result even on old rules; open/abandoned on old rules = refund.
    const closed = r.rs === 'closed';
    const refund = r.rs === 'infra_error' || (r.rv !== cur && !closed);
    await settleEscrow(env, r.run_id, refund ? 'refunded' : closed && r.ro === 'won' ? 'won' : 'lost');
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

/** GET /api/missions/unlocks: per tier whether it can be bought now, with the win counts behind it. */
async function unlocksInfo(env, player) {
  const wins = await winsByTier(env, player.id);
  const tiers = {};
  const off = offTiers(env);
  for (const id of Object.keys(T.tiers)) {
    const locked = T.tiers[id].enabled === false || off.includes(id);   // kill switch, same rule as validateMission
    tiers[id] = { unlocked: !locked && isUnlocked(wins, id), wins: wins[id] || 0, needs: winsNeeded(id), ...(locked ? { locked_reason: 'tier_locked' } : {}) };
  }
  return json({ tiers });
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
    if (url.pathname === '/api/missions/unlocks' && request.method === 'GET') return await unlocksInfo(env, player);
    return json({ error: 'not_found' }, 404);
  } catch (err) {
    console.error('missions error', url.pathname, String(err && err.stack || err));
    return json({ error: 'server' }, 500);
  }
}
