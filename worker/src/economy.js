// Server economy (SR1): Shard / Stone / ticket balances, unlocks, Echo Box, claims. D1 is the only source of truth;
// the client keeps a display cache. Reuses wallets + wallet_ledger (currency 'shard' | 'stone' | 'ticket').
//
// Every money change is ONE DB.batch (a transaction in D1). Shape of a batch:
//   1. a zero-delta MARKER ledger row, idem `op:<kind>:<req_id>`  -> a retry of the same request hits UNIQUE
//      and gets the stored answer back instead of paying twice;
//   2. (optional) a zero-delta POSITION row (`echobox:<player>:<n>`, `buy:<player>:<day>:<k>`) -> two different
//      requests that read the same state collide on UNIQUE, the loser answers 409 `conflict` and retries;
//   3. per currency: ledger row, then `UPDATE wallets ... balance + delta`; CHECK (balance >= 0) rolls the whole
//      batch back when funds are short. Caps (ticket hold 999, 30 ticket buys a day) are triggers in 0011.
// (The older idea "UPDATE ... WHERE balance >= ?, ledger WHERE changes() = 1" cannot branch inside a batch;
//  this is the review's second option.)
import echo from '../../godot/assets/data/economy/echobox.json' with { type: 'json' };
import daily from '../../godot/assets/data/economy/daily.json' with { type: 'json' };
import { shared } from './accounts.js';
import { balanceOfCur } from './wallet.js';
import pass from '../../godot/assets/data/economy/pass_v2.json' with { type: 'json' };
import decor from '../../godot/assets/data/land/decor.json' with { type: 'json' };
import { UNLOCKS, RUN_SHARD_MAX } from './econ_tables.js';
import { tierStone, stoneDayCap } from './missions.js';
import { scoreFromSummary } from './leaderboard.js';
import { CLOSE_SANITY } from './run_core.js';

const { json } = shared;
const nowS = () => Math.floor(Date.now() / 1000);
const utcDay = (s) => new Date(s * 1000).toISOString().slice(0, 10);
const isUnique = (e) => /UNIQUE/i.test(String((e && e.message) || e));
const errText = (e) => String((e && e.message) || e);
export const CURRENCIES = ['shard', 'stone', 'ticket'];
const RARITIES = ['common', 'uncommon', 'rare', 'epic', 'legendary', 'mythic'];
const REQ_RE = /^[A-Za-z0-9_-]{8,64}$/;
export const isEconPath = (p) => p === '/api/econ' || p === '/api/econ/claim' || p === '/api/econ/spend' || p === '/api/echobox/open';

// ---------------------------------------------------------------- statements

const ensureRow = (env, pid, cur) => env.DB.prepare('INSERT OR IGNORE INTO wallets (player_id, currency, balance) VALUES (?, ?, 0)').bind(pid, cur);
const ledger = (env, pid, cur, delta, reason, idem, at) =>
  env.DB.prepare('INSERT INTO wallet_ledger (player_id, currency, delta, reason, idem_key, at) VALUES (?, ?, ?, ?, ?, ?)').bind(pid, cur, delta, reason, idem, at);
/** The three statements that move `delta` of `cur` (key must be unique per player). */
const move = (env, pid, cur, delta, reason, idem, at) => [
  ensureRow(env, pid, cur),
  ledger(env, pid, cur, delta, reason, `${cur}:${idem}`, at),
  env.DB.prepare('UPDATE wallets SET balance = balance + ? WHERE player_id = ? AND currency = ?').bind(delta, pid, cur),
];

/** Run `stmts` as one atomic op under marker `op:<opKey>`. `answer` is stored in the marker so a retry replays it.
 *  -> {ok:true, dup?, answer} | {ok:false, code:'insufficient'|'hold_cap'|'day_cap'|'conflict'|...} */
async function runOp(env, pid, opKey, answer, stmts, at) {
  const marker = ledger(env, pid, 'op', 0, JSON.stringify(answer ?? {}), `op:${opKey}`, at);
  try {
    await env.DB.batch([marker, ...stmts]);
    return { ok: true, answer };
  } catch (e) {
    const m = errText(e);
    if (isUnique(e)) {
      const row = await env.DB.prepare('SELECT reason FROM wallet_ledger WHERE player_id = ? AND idem_key = ?').bind(pid, `op:${opKey}`).first();
      if (row) { let a = {}; try { a = JSON.parse(row.reason); } catch { /* keep {} */ } return { ok: true, dup: true, answer: a }; }
      return { ok: false, code: 'conflict' };
    }
    if (/HOLD_CAP/.test(m)) return { ok: false, code: 'hold_cap' };
    if (/DAY_CAP/.test(m)) return { ok: false, code: 'day_cap' };
    if (/CHECK/i.test(m)) return { ok: false, code: 'insufficient' };
    throw e;
  }
}

/** The stored answer of an op that already ran (a retry), or null. Checked first so a retry of a purchase that
 *  succeeded is a replay, not "already owned" / "no tickets". */
async function priorOp(env, pid, opKey) {
  const row = await env.DB.prepare('SELECT reason FROM wallet_ledger WHERE player_id = ? AND idem_key = ?').bind(pid, `op:${opKey}`).first();
  if (!row) return null;
  let a = {}; try { a = JSON.parse(row.reason); } catch { /* keep {} */ }
  return { ok: true, dup: true, answer: a };
}

// ---------------------------------------------------------------- Pass XP

export const passLevel = (xp) => { let lv = 0; for (const l of pass.levels) if (xp >= l.xp_total) lv = l.lv; return lv; };
const passStart = () => Date.parse(`${pass.start_day}T00:00:00Z`) / 1000;
const passEnd = () => Date.parse(`${pass.end_day}T00:00:00Z`) / 1000;
const passRow = (env, pid) => env.DB.prepare('INSERT OR IGNORE INTO pass_xp (player_id, season) VALUES (?, ?)').bind(pid, pass.season_id);

/** Run XP after the per-day cap (same rule as PassV2.add_run_xp): full rate up to run_full_rate_until, then
 *  run_over_rate, never past run_cap_day. -> {granted, used} */
export function capRunXp(raw, used) {
  const x = pass.xp;
  const full = Math.max(0, Math.min(raw, x.run_full_rate_until - used));
  const granted = Math.min(full + Math.floor((raw - full) * x.run_over_rate), Math.max(0, x.run_cap_day - used));
  return { granted, used: used + granted };
}

/** Add the XP of every valid closed run in the season that was not counted yet (oldest first). Valid = same gate as
 *  the `run` claim. Raw XP = the run's summary score, bounded by leaderboard.scoreFromSummary (the client's Pass XP
 *  formula as a ceiling). Idempotent per run (marker) and ordered (position row on `n`); a lost race just means
 *  the next call picks the run up. Until the verifier (B3) the run itself is still the client's claim. */
export async function syncPassXp(env, pid, at = nowS()) {
  const { results } = await env.DB.prepare(
    `SELECT r.run_id, r.ascension, r.outcome, r.created_at, r.closed_at, r.summary_json FROM runs r
      WHERE r.player_id = ? AND r.${VALID_RUN.replaceAll(' AND ', ' AND r.')} AND r.closed_at >= MAX(?, COALESCE((SELECT counted_to FROM pass_xp WHERE player_id = r.player_id AND season = ?), 0)) AND r.closed_at < ?
        AND NOT EXISTS (SELECT 1 FROM wallet_ledger l WHERE l.player_id = r.player_id AND l.idem_key = 'op:passxp:' || r.run_id)
      ORDER BY r.closed_at, r.run_id LIMIT 50`,
  ).bind(pid, passStart(), pass.season_id, passEnd()).all();
  for (const r of results) {
    const row = (await env.DB.prepare('SELECT day, day_xp, n FROM pass_xp WHERE player_id = ? AND season = ?').bind(pid, pass.season_id).first()) || { day: '', day_xp: 0, n: 0 };
    const sc = runTimeOk(r) ? scoreFromSummary(r.summary_json, { asc: r.ascension, won: r.outcome === 'won' }) : null;
    const day = utcDay(r.closed_at);
    const { granted, used } = capRunXp(sc ? sc.score : 0, row.day === day ? row.day_xp : 0);
    const res = await runOp(env, pid, `passxp:${r.run_id}`, { xp: granted }, [
      ledger(env, pid, 'op', 0, '{}', `passpos:${pass.season_id}:${row.n}`, at),
      passRow(env, pid),
      env.DB.prepare('UPDATE pass_xp SET xp = xp + ?, day = ?, day_xp = ?, n = n + 1, counted_to = MAX(counted_to, ?) WHERE player_id = ? AND season = ?').bind(granted, day, used, r.closed_at, pid, pass.season_id),
    ], at);
    if (!res.ok) break;   // conflict: another request is counting; stop, the next call continues
  }
}

const maxPassXp = () => pass.levels[pass.levels.length - 1].xp_total;
const weekStartS = (at) => (Math.floor((Math.floor(at / 86400) + 3) / 7) * 7 - 3) * 86400;   // Monday 00:00 UTC of `at`'s week
const inSeasonAt = (at) => at >= passStart() && at < passEnd();

/** Weekly task progress for the week of `at`, from closed runs on the server: runs = every closed run with a battle
 *  (Mission runs count, as in PassV2.record_run), wins = outcome won, boss = summary.bosses_started >= 1. */
async function weeklyProgress(env, pid, at) {
  const from = weekStartS(at);
  const r = await env.DB.prepare(
    `SELECT COUNT(*) AS runs, COALESCE(SUM(outcome = 'won'), 0) AS wins,
            COALESCE(SUM(CASE WHEN json_valid(summary_json) AND COALESCE(json_extract(summary_json, '$.bosses_started'), 0) >= 1 THEN 1 ELSE 0 END), 0) AS boss
       FROM runs WHERE player_id = ? AND state = 'closed' AND battles_done >= 1 AND closed_at >= ? AND closed_at < ?`,
  ).bind(pid, Math.max(from, passStart()), Math.min(from + 7 * 86400, passEnd())).first();
  return { runs: r.runs, wins: r.wins, boss: r.boss };
}
const post30Claimed = async (env, pid) => {
  const per = pass.post30_loop.shard;
  const r = await env.DB.prepare(`SELECT COALESCE(SUM(delta), 0) AS n FROM wallet_ledger WHERE player_id = ? AND currency = 'shard' AND idem_key LIKE ?`).bind(pid, `shard:claim:post30:${pass.season_id}:%`).first();
  return Math.floor((r ? r.n : 0) / per);
};

// ---------------------------------------------------------------- reads

async function state(env, pid) {
  const [w, u, inv, es] = await Promise.all([
    env.DB.prepare(`SELECT currency, balance FROM wallets WHERE player_id = ? AND currency IN ('shard','stone','ticket')`).bind(pid).all(),
    env.DB.prepare('SELECT unlock_id FROM unlocks WHERE player_id = ? ORDER BY at, unlock_id').bind(pid).all(),
    env.DB.prepare('SELECT item_id FROM inventory WHERE player_id = ? ORDER BY at, item_id').bind(pid).all(),
    env.DB.prepare('SELECT opens, pity_json, buy_day, buy_count FROM echobox_state WHERE player_id = ?').bind(pid).first(),
  ]);
  const bal = { shard: 0, stone: 0, ticket: 0 };
  for (const r of w.results) bal[r.currency] = r.balance;
  let pity = {};
  try { pity = es ? JSON.parse(es.pity_json) : {}; } catch { pity = {}; }
  const rs = await env.DB.prepare(`SELECT idem_key FROM wallet_ledger WHERE player_id = ? AND idem_key LIKE 'op:reset:%' ORDER BY id DESC LIMIT 1`).bind(pid).first();
  const px = await env.DB.prepare('SELECT xp FROM pass_xp WHERE player_id = ? AND season = ?').bind(pid, pass.season_id).first();
  const claimed = await env.DB.prepare(`SELECT idem_key FROM wallet_ledger WHERE player_id = ? AND currency = 'op' AND idem_key LIKE ?`).bind(pid, `op:claim:pass:${pass.season_id}:%`).all();
  const xp = px ? px.xp : 0;
  const wk = await env.DB.prepare(`SELECT idem_key FROM wallet_ledger WHERE player_id = ? AND currency = 'op' AND idem_key LIKE ?`).bind(pid, `op:claim:pass_weekly:${utcDay(weekStartS(nowS()))}:%`).all();
  const wprog = inSeasonAt(nowS()) ? await weeklyProgress(env, pid, nowS()) : { runs: 0, wins: 0, boss: 0 };
  const loops = Math.max(0, Math.floor((xp - maxPassXp()) / pass.post30_loop.xp));
  const p30 = await post30Claimed(env, pid);
  return {
    pass: { weekly: { week: utcDay(weekStartS(nowS())), ...wprog, claimed: wk.results.map((x) => x.idem_key.split(':').pop()) },
      post30: { pending: Math.max(0, loops - p30), claimed: p30 },
      season: pass.season_id, xp, level: passLevel(xp), claimed: claimed.results.map((r) => Number(r.idem_key.split(':').pop())).sort((a, b) => a - b) },
    reset_id: rs ? rs.idem_key.slice('op:reset:'.length) : '',
    shard: bal.shard, stone: bal.stone, ticket: bal.ticket,
    unlocks: u.results.map((r) => r.unlock_id), owned: inv.results.map((r) => r.item_id),
    pity, opens: es ? es.opens : 0, buy_day: es ? es.buy_day : '', buy_count: es ? es.buy_count : 0,
  };
}

/** First sight of an account: the fixed starter grant (daily.json `starter`), once, under marker `op:starter:v1`. */
export async function ensureStarter(env, pid, at = nowS()) {
  if (await priorOp(env, pid, 'starter:v1')) return { ok: true, dup: true };   // one cheap SELECT, no batch per request
  const s = daily.starter || {};
  // N4: once per durable identity (players.id = google:<sub>), kept in starter_claims WITHOUT a foreign key, so a
  // deleted-and-re-registered account cannot collect the starter again. UNIQUE failure rolls the batch back.
  const stmts = [env.DB.prepare('INSERT INTO starter_claims (identity, at) VALUES (?, ?)').bind(pid, at)];
  if (s.shards > 0) stmts.push(...move(env, pid, 'shard', s.shards, 'starter', 'starter:v1', at));
  if (s.tickets > 0) stmts.push(...move(env, pid, 'ticket', s.tickets, 'starter', 'starter:v1', at));
  stmts.push(env.DB.prepare('INSERT OR IGNORE INTO echobox_state (player_id) VALUES (?)').bind(pid));
  return runOp(env, pid, 'starter:v1', {}, stmts, at);
}

// ---------------------------------------------------------------- tickets (stepped price, same as EchoBox.ticket_price)

export function ticketPrice(k) {
  const t = echo.tickets;
  const raw = t.base_price * Math.pow(t.growth, k - 1);
  const step = t.round_to;
  // GDScript roundf = half away from zero; the values are positive so Math.round matches.
  return Math.round(raw / step) * step;
}
export function ticketCost(have, n) {
  const cap = echo.tickets.buy_cap_day;
  if (!Number.isSafeInteger(n) || n <= 0 || have + n > cap) return -1;
  let total = 0;
  for (let k = have + 1; k <= have + n; k++) total += ticketPrice(k);
  return total;
}

async function buyTickets(env, pid, n, req, at) {
  const prior = await priorOp(env, pid, `ticket_buy:${req}`);
  if (prior) return prior;
  const day = utcDay(at);
  const st = await state(env, pid);
  const have = st.buy_day === day ? st.buy_count : 0;
  const cost = ticketCost(have, n);
  if (cost < 0) return { ok: false, code: 'day_cap' };
  if (st.ticket + n > echo.tickets.hold_cap) return { ok: false, code: 'hold_cap' };
  const stmts = [
    ledger(env, pid, 'op', 0, '{}', `buy:${pid}:${day}:${have}`, at),   // position: parallel buys with other req ids collide here
    ...move(env, pid, 'shard', -cost, 'ticket_buy', `ticket_buy:${req}`, at),
    ...move(env, pid, 'ticket', n, 'buy', `ticket_buy:${req}`, at),
    env.DB.prepare('INSERT OR IGNORE INTO echobox_state (player_id) VALUES (?)').bind(pid),
    env.DB.prepare('UPDATE echobox_state SET buy_day = ?, buy_count = ? WHERE player_id = ?').bind(day, have + n, pid),
  ];
  return runOp(env, pid, `ticket_buy:${req}`, { cost, n }, stmts, at);
}

async function buyUnlock(env, pid, id, req, at) {
  if (!Object.hasOwn(UNLOCKS, id)) return { ok: false, code: 'unknown_sku' };
  const prior = await priorOp(env, pid, `unlock:${req}`);
  if (prior) return prior;
  const owned = await env.DB.prepare('SELECT 1 AS x FROM unlocks WHERE player_id = ? AND unlock_id = ?').bind(pid, id).first();
  if (owned) return { ok: false, code: 'owned' };
  const stmts = [
    ...move(env, pid, 'shard', -UNLOCKS[id], `unlock:${id}`, `unlock:${id}`, at),   // key per unlock id: one purchase ever
    env.DB.prepare('INSERT INTO unlocks (player_id, unlock_id, at) VALUES (?, ?, ?)').bind(pid, id, at),
  ];
  return runOp(env, pid, `unlock:${req}`, { id, cost: UNLOCKS[id] }, stmts, at);
}

// ---------------------------------------------------------------- claims

/** One idempotent reward bundle: {shards, stone, tickets, items[], unlocks[]} under marker `op:<key>`. */
function bundle(env, pid, key, p, reason, at) {
  const st = [];
  if (p.shards > 0) st.push(...move(env, pid, 'shard', p.shards, reason, key, at));
  if (p.stone > 0) st.push(...move(env, pid, 'stone', p.stone, reason, key, at));
  if (p.tickets > 0) st.push(...move(env, pid, 'ticket', p.tickets, reason, key, at));
  if (p.gem > 0) st.push(...move(env, pid, 'gem', p.gem, reason, key, at));   // same wallets/ledger rows applyDelta uses for Gem
  for (const i of p.items || []) st.push(env.DB.prepare('INSERT OR IGNORE INTO inventory (player_id, item_id, at) VALUES (?, ?, ?)').bind(pid, i, at));
  for (const u of p.unlocks || []) st.push(env.DB.prepare('INSERT OR IGNORE INTO unlocks (player_id, unlock_id, at) VALUES (?, ?, ?)').bind(pid, u, at));
  return runOp(env, pid, key, { shards: p.shards || 0, stone: p.stone || 0, tickets: p.tickets || 0, gem: p.gem || 0, items: p.items || [] }, st, at);
}

const weekOf = (day) => Math.floor((day + 3) / 7);   // Monday-based week of a unix-day index
// A run that counts for rewards: closed, played at least one battle, not a Mission run (those pay via escrow).
// NOTE (Liam accepted until B3): `closed`, `battles_done` and summary are the client's claims, there is no verifier
// yet, so this cannot stop a forged run. It only stops the cheap cases (empty runs, double pay, Mission double pay).
/** Cheap-fake guard (not a payout cap): a run cannot have taken less server time than SR0's CLOSE_SANITY gives per
 *  map row (min_secs_per_row x rows reached; a won run must have reached the final row of its mode). Time is
 *  closed_at - created_at on OUR clock. The number of epochs the Durable Object issued would be a second check, but
 *  it lives in the DO's own SQLite, not in D1, and run_do.js is not ours to change; so it is NOT checked here. */
export function runTimeOk(run) {
  let sum = {}; try { sum = JSON.parse(run.summary_json || '{}') || {}; } catch { sum = {}; }
  const mode = sum.len === 'full' ? 'full' : 'short';
  const rows = run.outcome === 'won' ? CLOSE_SANITY.final_row[mode] : Math.min(Number.isSafeInteger(sum.pw) ? sum.pw : 1, CLOSE_SANITY.final_row[mode]);
  return (run.closed_at || 0) - (run.created_at || 0) >= CLOSE_SANITY.min_secs_per_row * Math.max(1, rows);
}
const VALID_RUN = `state = 'closed' AND battles_done >= 1 AND mode != 'mission'`;
async function closedRunToday(env, pid, at, mode) {
  const d0 = Math.floor(at / 86400) * 86400;
  const r = await env.DB.prepare(
    `SELECT COUNT(*) AS n FROM runs WHERE player_id = ? AND ${VALID_RUN} AND closed_at >= ? AND closed_at < ?${mode ? ' AND mode = ?' : ''}`,
  ).bind(...(mode ? [pid, d0, d0 + 86400, mode] : [pid, d0, d0 + 86400])).first();
  return !!r && r.n > 0;
}

async function claim(env, pid, b, at) {
  const day = utcDay(at);
  const dIdx = Math.floor(at / 86400);
  const grant = (cfg, key, reason, extra = []) => {
    const stmts = [...extra];
    if (cfg.shards > 0) stmts.push(...move(env, pid, 'shard', cfg.shards, reason, key, at));
    if (cfg.stone > 0) stmts.push(...move(env, pid, 'stone', cfg.stone, reason, key, at));
    return runOp(env, pid, key, { shards: cfg.shards || 0, stone: cfg.stone || 0 }, stmts, at);
  };
  switch (b.kind) {
    case 'daily':   // any closed run today
      if (!(await closedRunToday(env, pid, at))) return { ok: false, code: 'no_run_today' };
      // +daily_bonus Pass XP (no run cap), in season, in the same batch as the reward
      return grant(daily.daily_reward, `claim:daily:${day}`, 'daily', at >= passStart() && at < passEnd()
        ? [passRow(env, pid), env.DB.prepare('UPDATE pass_xp SET xp = xp + ? WHERE player_id = ? AND season = ?').bind(pass.xp.daily_bonus, pid, pass.season_id)] : []);
    case 'daily_run':   // first finished Daily-mode run
      if (!(await closedRunToday(env, pid, at, 'daily'))) return { ok: false, code: 'no_run_today' };
      return grant(daily.daily_run_reward, `claim:daily_run:${day}`, 'daily_run');
    case 'weekly': {   // >= min_days daily claims inside this Monday-based week (counted from OUR ledger)
      const w = weekOf(dIdx);
      const from = (w * 7 - 3) * 86400;
      const r = await env.DB.prepare(
        `SELECT COUNT(*) AS n FROM wallet_ledger WHERE player_id = ? AND currency = 'shard' AND idem_key LIKE 'shard:claim:daily:%' AND at >= ? AND at < ?`,
      ).bind(pid, from, from + 7 * 86400).first();
      if (!r || r.n < daily.weekly_bonus.min_days) return { ok: false, code: 'not_enough_days' };
      return grant(daily.weekly_bonus, `claim:weekly:${w}`, 'daily_weekly');
    }
    case 'run': {   // Shard reward of ONE closed run, once per run id. The amount is computed HERE from what the run
      // recorded at close (summary_json.shards), never taken from the request, and clamped to RUN_SHARD_MAX.
      if (typeof b.run_id !== 'string' || !/^[0-9a-f]{32}$/.test(b.run_id)) return { ok: false, code: 'bad_request' };
      const run = await env.DB.prepare(`SELECT summary_json, outcome, created_at, closed_at FROM runs WHERE run_id = ? AND player_id = ? AND ${VALID_RUN}`).bind(b.run_id, pid).first();
      if (!run) return { ok: false, code: 'run_not_closed' };
      if (!runTimeOk(run)) return { ok: false, code: 'run_too_short' };
      let sum = {}; try { sum = JSON.parse(run.summary_json || '{}') || {}; } catch { sum = {}; }
      const amount = Math.max(0, Math.min(RUN_SHARD_MAX, Number.isSafeInteger(sum.shards) ? sum.shards : 0));
      if (amount === 0) return { ok: false, code: 'nothing_to_claim' };
      return grant({ shards: amount }, `claim:run:${b.run_id}`, 'run');
    }
    case 'pass_weekly': {   // 500 XP for one finished weekly task of THIS week (in season), progress counted from our runs
      if (!inSeasonAt(at)) return { ok: false, code: 'out_of_season' };
      const t = pass.weekly_tasks.tasks.find((x) => x.id === b.task);
      if (!t) return { ok: false, code: 'bad_request' };
      const prog = await weeklyProgress(env, pid, at);
      if (prog[t.counter] < t.target) return { ok: false, code: 'not_done' };
      const key = `claim:pass_weekly:${utcDay(weekStartS(at))}:${t.id}`;
      return runOp(env, pid, key, { xp: pass.weekly_tasks.xp_each }, [
        passRow(env, pid),
        env.DB.prepare('UPDATE pass_xp SET xp = xp + ? WHERE player_id = ? AND season = ?').bind(pass.weekly_tasks.xp_each, pid, pass.season_id),
      ], at);
    }
    case 'pass_post30': {   // every full post30_loop.xp above level 30 = post30_loop.shard Shard; claims all pending loops
      const st = await state(env, pid);
      const total = Math.max(0, Math.floor((st.pass.xp - maxPassXp()) / pass.post30_loop.xp));
      const done = await post30Claimed(env, pid);
      if (total <= done) return { ok: false, code: 'nothing_to_claim' };
      // key names the loop count reached: two parallel claims from the same state collide on it
      return grant({ shards: (total - done) * pass.post30_loop.shard }, `claim:post30:${pass.season_id}:${total}`, 'pass_loop');
    }
    case 'mission': {   // Stone of a WON Mission run: from the settled escrow + the table, nothing from the client
      if (typeof b.run_id !== 'string' || !/^[0-9a-f]{32}$/.test(b.run_id)) return { ok: false, code: 'bad_request' };
      const e = await env.DB.prepare(`SELECT tier, state FROM mission_escrow WHERE run_id = ? AND player_id = ?`).bind(b.run_id, pid).first();
      if (!e || e.state !== 'won') return { ok: false, code: 'run_not_closed' };
      const d0 = Math.floor(at / 86400) * 86400;
      const used = await env.DB.prepare(`SELECT COALESCE(SUM(delta), 0) AS n FROM wallet_ledger WHERE player_id = ? AND currency = 'stone' AND reason = 'mission_win' AND at >= ? AND at < ?`).bind(pid, d0, d0 + 86400).first();
      const amount = Math.max(0, Math.min(tierStone(e.tier), stoneDayCap() - (used ? used.n : 0)));   // table's per-day Stone cap (design number, not a Shard payout cap)
      if (amount === 0) return { ok: false, code: 'nothing_to_claim' };
      // position row: two claims of different runs that read the same day total collide here, the loser retries
      return grant({ stone: amount }, `claim:mission:${b.run_id}`, 'mission_win', [ledger(env, pid, 'op', 0, '{}', `stonepos:${utcDay(at)}:${used ? used.n : 0}`, at)]);
    }
    case 'pass': {   // free reward of Pass level `level` (1..30). NOTE: Pass XP/level is still client-side, so the level is the
      // client's claim -> now the SERVER's: lv must be <= the level from pass_xp (syncPassXp). Gem goes to the server Gem wallet in the same batch.
      const lv = b.level;
      if (!Number.isSafeInteger(lv) || lv < 1 || lv > pass.levels.length) return { ok: false, code: 'bad_request' };
      const start = Date.parse(`${pass.start_day}T00:00:00Z`) / 1000;
      if (at < start) return { ok: false, code: 'out_of_season' };
      await syncPassXp(env, pid, at);
      if (lv > passLevel(((await state(env, pid)).pass).xp)) return { ok: false, code: 'not_reached' };
      const free = pass.levels[lv - 1].free;
      const pay = { shards: 0, stone: 0, tickets: 0, gem: 0, items: [], unlocks: [] };
      for (const r of free) {
        if (r.type === 'shard') pay.shards += r.value;
        else if (r.type === 'stone') pay.stone += r.value;
        else if (r.type === 'ticket') pay.tickets += r.value;
        else if (r.type === 'gem') pay.gem += r.value;
        else if (r.type === 'cosmetic') pay.items.push(r.value);
        else if (r.type === 'title') pay.items.push(`title:${r.value}`);
        else if (r.type === 'unlock' && Object.hasOwn(UNLOCKS, r.value)) pay.unlocks.push(r.value);
      }
      if (pay.unlocks.length) {   // already owned -> Shard at shop price (ECO-13), same as the client rule
        const have = new Set((await state(env, pid)).unlocks);
        for (const u of pay.unlocks.splice(0)) { if (have.has(u)) pay.shards += UNLOCKS[u]; else pay.unlocks.push(u); }
      }
      return bundle(env, pid, `claim:pass:${pass.season_id}:${lv}`, pay, 'pass', at);
    }
    case 'land': {   // COSMETICS ONLY (titles, frames, dice skins, a trophy decor): no Shard/Stone/ticket, so trusting the
      // client's Land score is accepted (nothing that can be sold or spent). Do not add currency rewards here
      // without a server-side Land score. milestone items from decor.json; `points` is the client's Land score, must reach the milestone's number
      const m = decor.milestones.find((x) => x.id === b.milestone);
      if (!m || !Number.isSafeInteger(b.points)) return { ok: false, code: 'bad_request' };
      if (b.points < m.points) return { ok: false, code: 'not_reached' };
      const items = m.kind === 'multi' ? [...m.items, ...(m.decor ? [m.decor] : [])] : [m.item];
      return bundle(env, pid, `claim:land:${m.id}`, { items }, 'land', at);
    }
    default: return { ok: false, code: 'bad_request' };
  }
}

// ---------------------------------------------------------------- Echo Box (port of EchoBox.open_normal)

const randInt = (rand, lo, hi) => lo + Math.floor(rand() * (hi - lo + 1));
/** Uniform float in [0,1) from crypto (53 bits). */
export function cryptoRand() {
  const a = new Uint32Array(2); crypto.getRandomValues(a);
  return ((a[0] >>> 5) * 67108864 + (a[1] >>> 6)) / 9007199254740992;
}

function pick(rows, rand, minRarity) {
  const minI = minRarity ? RARITIES.indexOf(minRarity) : -1;
  const pool = [];
  let total = 0;
  for (const r of rows) {
    if (minI >= 0 && (r.kind !== 'cosmetic' || RARITIES.indexOf(r.rarity) < minI)) continue;
    pool.push(r); total += Number(r.weight) || 0;
  }
  const x = rand() * total;
  let acc = 0;
  for (const r of pool) { acc += Number(r.weight) || 0; if (x < acc) return r; }
  return pool[pool.length - 1];
}
const stepKey = (rar) => `since_${rar}`;
function forcedMin(pity, box) {
  let forced = ''; let best = -1;
  for (const s of box.pity.steps) {
    if ((pity[stepKey(s.min_rarity)] || 0) >= s.pulls) {
      const ri = RARITIES.indexOf(s.min_rarity);
      if (ri > best) { best = ri; forced = s.min_rarity; }
    }
  }
  return forced;
}
function advancePity(pity, box, rarity) {
  const ri = RARITIES.indexOf(rarity);
  for (const s of box.pity.steps) {
    const k = stepKey(s.min_rarity);
    pity[k] = RARITIES.indexOf(s.min_rarity) <= ri ? 0 : (pity[k] || 0) + 1;
  }
}
export function poolIds(box, rarity) {
  const spec = (box.pool || {})[rarity] || {};
  const out = [];
  for (let i = 1; i <= (spec.count || 0); i++) out.push(`${spec.id_prefix}_${String(i).padStart(3, '0')}`);
  return out;
}

/** One normal-box pull. Pure: (pity, owned:Set, rand) -> result; mutates a COPY of pity.
 *  -> {kind, amount, rarity, item, duplicate, fragments, tickets_back, pity} */
export function openNormal(pityIn, owned, rand, cfg = echo) {
  const box = cfg.boxes.normal;
  const pity = { ...pityIn };
  pity.opens = (pity.opens || 0) + 1;
  const rows = box.table;
  const res = { kind: '', amount: 0, rarity: '', item: '', duplicate: false, fragments: 0, tickets_back: 0 };
  const row = pick(rows, rand, '');
  if (row.kind === 'stone') { res.kind = 'stone'; res.amount = row.amount; }
  else {
    res.kind = 'cosmetic';
    const forced = forcedMin(pity, box);
    let rarity = row.rarity || 'common';
    if (forced && RARITIES.indexOf(rarity) < RARITIES.indexOf(forced)) rarity = pick(rows, rand, forced).rarity || forced;
    res.rarity = rarity;
    advancePity(pity, box, rarity);
    const ids = poolIds(box, rarity);
    const missing = ids.filter((i) => !owned.has(i));
    if (ids.length === 0) { /* nothing to give */ }
    else if (missing.length > 0) res.item = missing[randInt(rand, 0, missing.length - 1)];
    else {
      res.duplicate = true;
      res.item = ids[randInt(rand, 0, ids.length - 1)];
      const gain = (cfg.dup_fragments || {})[rarity] || 0;
      const per = cfg.fragments_per_ticket || 10;
      const frags = (pity.fragments || 0) + gain;
      res.tickets_back = Math.floor(frags / per);
      pity.fragments = frags % per;
      res.fragments = gain;
    }
  }
  res.pity = pity;
  return res;
}

async function openBox(env, pid, req, at, rand = cryptoRand) {
  const prior = await priorOp(env, pid, `open:${req}`);
  if (prior) return prior;
  const st = await state(env, pid);
  const cost = echo.boxes.normal.ticket_cost || 1;
  if (st.ticket < cost) return { ok: false, code: 'no_tickets' };
  const r = openNormal({ ...st.pity, opens: st.opens }, new Set(st.owned), rand);
  const back = Math.min(r.tickets_back, Math.max(0, echo.tickets.hold_cap - (st.ticket - cost)));
  const { pity, ...pub } = r;
  const answer = { ...pub, tickets_back: back };
  const stmts = [
    ledger(env, pid, 'op', 0, '{}', `echobox:${pid}:${st.opens}`, at),   // position: parallel opens collide here
    ...move(env, pid, 'ticket', -cost, 'open:normal', `open:${req}`, at),
  ];
  if (r.kind === 'stone') stmts.push(...move(env, pid, 'stone', r.amount, 'echobox', `open:${req}`, at));
  if (back > 0) stmts.push(...move(env, pid, 'ticket', back, 'grant:recycle', `recycle:${req}`, at));
  if (r.kind === 'cosmetic' && r.item) stmts.push(env.DB.prepare('INSERT OR IGNORE INTO inventory (player_id, item_id, at) VALUES (?, ?, ?)').bind(pid, r.item, at));
  const { opens, ...pityOnly } = pity;
  stmts.push(
    env.DB.prepare('INSERT OR IGNORE INTO echobox_state (player_id) VALUES (?)').bind(pid),
    env.DB.prepare('UPDATE echobox_state SET opens = ?, pity_json = ? WHERE player_id = ?').bind(opens, JSON.stringify(pityOnly), pid),
  );
  return runOp(env, pid, `open:${req}`, answer, stmts, at);
}

// ---------------------------------------------------------------- HTTP

async function readBody(request, max = 1024) {
  try { const t = await request.text(); return t.length <= max ? JSON.parse(t) : null; } catch { return null; }
}
const STATUS = { insufficient: 402, no_tickets: 402, conflict: 409, owned: 409, day_cap: 409, hold_cap: 409, unknown_sku: 400, bad_request: 400,
  no_run_today: 409, run_too_short: 409, nothing_to_claim: 409, run_not_closed: 409, not_enough_days: 409, out_of_season: 409, not_reached: 409, not_done: 409 };

export async function handleEcon(request, env, url, opts = {}) {
  try {
    const player = await shared.currentPlayer(request, env);
    if (!player) return json({ error: 'unauthenticated' }, 401);
    if (env.SAVE_LIMITER) {
      const { success } = await env.SAVE_LIMITER.limit({ key: `e:${player.id}` });
      if (!success) return json({ error: 'rate_limited' }, 429);
    }
    const at = nowS();
    const pid = player.id;
    if (url.pathname === '/api/econ' && request.method === 'GET') {
      await ensureStarter(env, pid, at);
      await syncPassXp(env, pid, at);
      return json(await state(env, pid));
    }
    if (request.method !== 'POST') return json({ error: 'not_found' }, 404);
    const o = request.headers.get('Origin');
    if (o && !shared.isAllowedOrigin(o, url)) return json({ error: 'forbidden' }, 403);
    const b = await readBody(request);
    if (!b || typeof b !== 'object') return json({ error: 'bad_request' }, 400);
    await ensureStarter(env, pid, at);
    await syncPassXp(env, pid, at);
    let r;
    if (url.pathname === '/api/econ/spend') {
      if (typeof b.req_id !== 'string' || !REQ_RE.test(b.req_id) || typeof b.sku !== 'string') return json({ error: 'bad_request' }, 400);
      const [kind, arg] = b.sku.split(':');
      if (kind === 'unlock') r = await buyUnlock(env, pid, arg, b.req_id, at);
      else if (kind === 'ticket') r = await buyTickets(env, pid, Number(arg), b.req_id, at);
      else r = { ok: false, code: 'unknown_sku' };
    } else if (url.pathname === '/api/econ/claim') r = await claim(env, pid, b, at);
    else if (url.pathname === '/api/echobox/open') {
      if (typeof b.req_id !== 'string' || !REQ_RE.test(b.req_id)) return json({ error: 'bad_request' }, 400);
      r = await openBox(env, pid, b.req_id, at, opts.rand || cryptoRand);
    } else return json({ error: 'not_found' }, 404);
    const snap = await state(env, pid);
    if (!r.ok) return json({ ok: false, code: r.code, ...snap }, STATUS[r.code] || 400);
    return json({ ok: true, dup: !!r.dup, result: r.answer || {}, ...snap });
  } catch (err) {
    console.error('econ error', String(err && err.stack || err));
    return json({ error: 'server' }, 500);
  }
}
export { balanceOfCur };
