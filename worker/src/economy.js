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
import { UNLOCKS, RUN_SHARD_MAX } from './econ_tables.js';

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
  return {
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

const weekOf = (day) => Math.floor((day + 3) / 7);   // Monday-based week of a unix-day index
// A run that counts for rewards: closed, played at least one battle, not a Mission run (those pay via escrow).
// NOTE (Liam accepted until B3): `closed`, `battles_done` and summary are the client's claims, there is no verifier
// yet, so this cannot stop a forged run. It only stops the cheap cases (empty runs, double pay, Mission double pay).
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
  const grant = (cfg, key, reason) => {
    const stmts = [];
    if (cfg.shards > 0) stmts.push(...move(env, pid, 'shard', cfg.shards, reason, key, at));
    if (cfg.stone > 0) stmts.push(...move(env, pid, 'stone', cfg.stone, reason, key, at));
    return runOp(env, pid, key, { shards: cfg.shards || 0, stone: cfg.stone || 0 }, stmts, at);
  };
  switch (b.kind) {
    case 'daily':   // any closed run today
      if (!(await closedRunToday(env, pid, at))) return { ok: false, code: 'no_run_today' };
      return grant(daily.daily_reward, `claim:daily:${day}`, 'daily');
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
      const run = await env.DB.prepare(`SELECT summary_json FROM runs WHERE run_id = ? AND player_id = ? AND ${VALID_RUN}`).bind(b.run_id, pid).first();
      if (!run) return { ok: false, code: 'run_not_closed' };
      let sum = {}; try { sum = JSON.parse(run.summary_json || '{}') || {}; } catch { sum = {}; }
      const amount = Math.max(0, Math.min(RUN_SHARD_MAX, Number.isSafeInteger(sum.shards) ? sum.shards : 0));
      if (amount === 0) return { ok: false, code: 'nothing_to_claim' };
      return grant({ shards: amount }, `claim:run:${b.run_id}`, 'run');
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
  no_run_today: 409, nothing_to_claim: 409, run_not_closed: 409, not_enough_days: 409 };

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
      return json(await state(env, pid));
    }
    if (request.method !== 'POST') return json({ error: 'not_found' }, 404);
    const o = request.headers.get('Origin');
    if (o && !shared.isAllowedOrigin(o, url)) return json({ error: 'forbidden' }, 403);
    const b = await readBody(request);
    if (!b || typeof b !== 'object') return json({ error: 'bad_request' }, 400);
    await ensureStarter(env, pid, at);
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
