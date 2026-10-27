// SR-V: builds the job the shadow verifier replays. Everything the server knows comes from D1 / the DO's own epoch log;
// what only the client knows (team, content version, loadout flags) is carried apart in `client_header` and never wins
// over the server fields. See verifier/JOB_SCHEMA.md. Shadow only: nothing here touches runs, wallet or leaderboard.
import { missionHeader } from './missions.js';
import { sanitizeLogHeader } from './verify_header.js';
export { sanitizeLogHeader };

/** Unlock ids that change a run (godot MetaState.run_bonuses). */
const U = { reroll: 'u_reroll', reroll2: 'u_reroll2', hp: 'u_hp', hp2: 'u_hp2', start: 'u_start' };

/**
 * Bonuses a run starts with, from the account's unlock ids.
 * MIRRORS godot/autoload/MetaState.gd run_bonuses(is_ranked) WITHOUT perks (perks are not applied when the economy is
 * server-owned, Liam 27/10): u_reroll +1 and u_reroll2 +1 reroll; u_hp +3 and u_hp2 +2 hp; u_start -> start_relic_max_rarity 0
 * else -1; reward_reroll_max 1. Ranked and unranked are the same once perks are gone. Change one side, change the other.
 */
export function runBonuses(unlockIds) {
  const have = new Set(unlockIds || []);
  return {
    bonus_reroll: (have.has(U.reroll) ? 1 : 0) + (have.has(U.reroll2) ? 1 : 0),
    hp_bonus: (have.has(U.hp) ? 3 : 0) + (have.has(U.hp2) ? 2 : 0),
    start_relic_max_rarity: have.has(U.start) ? 0 : -1,
    reward_reroll_max: 1,
  };
}

const KINDS = new Set(['normal', 'daily', 'ranked', 'mission']);

/**
 * The header from server state only. `missionRow` = the mission_escrow row ({tier}) or null.
 * kind=='mission' <=> mission present; any disagreement sets header_mismatch (the job is still queued so the verifier
 * answers `header_mismatch`; nothing is dropped silently).
 */
export function buildServerHeader({ meta, runMode, missionRow, newcomer }) {
  const kind = KINDS.has(meta.mode) ? meta.mode : 'normal';
  const mission = missionRow ? missionHeader(missionRow.tier) : null;
  const header_mismatch = (kind === 'mission') !== (mission !== null) || !KINDS.has(meta.mode);
  return {
    rules_version: meta.rules_version,
    kind,
    mode: runMode === 'full' ? 'full' : 'short',  // run_start args.mode: enum-checked by the Worker and part of the seed
    ascension: meta.ascension | 0,
    ranked: kind === 'ranked',
    depth_stage: Number.isInteger(meta.depth_stage) ? meta.depth_stage : 3, // NULL on record = pre-v4 behaviour = 3 (runs.js openRun)
    newcomer: !!newcomer,
    mission,
    header_mismatch,
  };
}

/** Server-known loadout. Flags the server never sees are listed in server_unknown; ranked pins what the rules pin. */
export function buildServerLoadout({ unlockIds, ranked }) {
  return {
    bonuses: runBonuses(unlockIds),
    forced: ranked ? { rules_on: true, core_off: false, anchor: false } : {},
    server_unknown: ['anchor', 'rules_on', 'core_off', 'boon_id'].filter((k) => !(ranked && k !== 'boon_id')),
  };
}

const num = (v) => (typeof v === 'bigint' ? Number(v) : v);

/**
 * Build the whole job payload for a CLOSED run. `core` = RunCore (its sql is the DO's own epoch log), `env.DB` = D1.
 * Throws on a D1 problem: the caller (RunDO) catches, logs and swallows it.
 */
export async function buildVerifyPayload(env, core, meta) {
  const rows = core.sql.exec('SELECT seq, kind, args, h, log_len, seed, log_delta FROM epochs ORDER BY seq').toArray();
  const entries = [];
  const parsed = [];
  let runMode = 'short';
  let closeArgs = {};
  for (const r of rows) {
    let d = []; try { d = JSON.parse(r.log_delta); } catch { d = []; }
    if (Array.isArray(d)) entries.push(...d);
    let a = {}; try { a = JSON.parse(r.args); } catch { a = {}; }
    if (r.kind === 'run_start' && a && a.mode) runMode = a.mode;
    if (r.kind === 'close') closeArgs = a || {};
    else parsed.push({ r, a: a && typeof a === 'object' ? a : {} });
  }

  const missionRow = await env.DB.prepare('SELECT tier FROM mission_escrow WHERE run_id = ?').bind(meta.run_id).first();
  const run = await env.DB.prepare('SELECT created_at FROM runs WHERE run_id = ?').bind(meta.run_id).first();
  const createdAt = run ? run.created_at : Math.floor(Number(meta.created_at) / 1000);
  // Newcomer as the server decided it at creation: runs of this player that had a battle and were created before this one
  // (one open run per player, so every earlier run is already finished). Same threshold as runs.js (NEWCOMER_RUNS = 5).
  const nc = await env.DB.prepare('SELECT COUNT(*) AS n FROM runs WHERE player_id = ? AND battles_done >= 1 AND created_at < ? AND run_id != ?')
    .bind(meta.player_id, createdAt, meta.run_id).first();
  // Unlocks as they stood when the run started (a later purchase must not change the replay).
  const un = await env.DB.prepare('SELECT unlock_id FROM unlocks WHERE player_id = ? AND at <= ?').bind(meta.player_id, createdAt).all();
  const unlockIds = ((un && un.results) || []).map((x) => x.unlock_id);

  const server_header = buildServerHeader({ meta, runMode, missionRow, newcomer: !nc || nc.n < 5 });
  const server_loadout = buildServerLoadout({ unlockIds, ranked: server_header.ranked });

  const tape = parsed.map(({ r, a }) => {
    const extra = { h: r.h, log_len: num(r.log_len) };
    if (r.kind === 'run_start') {
      extra.run_id = meta.run_id;
      extra.client_nonce = meta.client_nonce;
      extra.header = { newcomer: server_header.newcomer, depth_stage: server_header.depth_stage, ...(server_header.mission ? { mission: server_header.mission } : {}) };
    }
    return { seq: num(r.seq), kind: r.kind, args: a, seed: num(r.seed), extra };
  });

  let summary = {};
  try { summary = JSON.parse(meta.summary || '{}'); } catch { summary = {}; }
  const claim = { outcome: meta.outcome };
  if (summary && Number.isSafeInteger(summary.score) && summary.score >= 0) claim.score = summary.score;

  return {
    schema: 1,
    server_header,
    server_loadout,
    client_header: sanitizeLogHeader(closeArgs.log_header) || {},
    client_claim: claim,
    entries,
    tape,
  };
}
