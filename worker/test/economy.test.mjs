// Server economy (SR1): starter grant, spend/claim idempotency, parallel double-spend, Echo Box port.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { DatabaseSync } from 'node:sqlite';
import { createHash } from 'node:crypto';
import worker from '../src/index.js';
import { openNormal, ticketPrice, ticketCost, poolIds } from '../src/economy.js';
import echo from '../../godot/assets/data/economy/echobox.json' with { type: 'json' };

import { mkEnv } from './_econ_harness.mjs';
const call = (env, path, method = 'GET', body, tok = 'tok1') => worker.fetch(new Request(`https://axiedice.fun${path}`, {
  method, headers: { cookie: `ad_session=${tok}`, origin: 'https://axiedice.fun', 'content-type': 'application/json' }, body: body ? JSON.stringify(body) : undefined }), env);
const j = async (p) => { const r = await p; return { status: r.status, ...(await r.json()) }; };
const setBal = (env, pid, cur, n) => env.DB.db.prepare('INSERT INTO wallets (player_id, currency, balance) VALUES (?, ?, ?) ON CONFLICT(player_id, currency) DO UPDATE SET balance = ?').run(pid, cur, n, n);
const R = (n) => `req_${String(n).padStart(8, '0')}`;

test('economy: needs a session; first GET grants the starter once', async () => {
  const env = mkEnv();
  assert.equal((await call(env, '/api/econ', 'GET', null, 'bad')).status, 401);
  const a = await j(call(env, '/api/econ'));
  assert.equal(a.shard, 500); assert.equal(a.ticket, 3); assert.equal(a.stone, 0);
  const b = await j(call(env, '/api/econ'));
  assert.equal(b.shard, 500, 'starter not repeated');
  assert.equal((await j(call(env, '/api/econ', 'GET', null, 'tok2'))).shard, 500, 'per player');
});

test('economy: unlock purchase charges once; same req id is a replay; owned and poor are refused', async () => {
  const env = mkEnv();
  const buy = (sku, n) => j(call(env, '/api/econ/spend', 'POST', { sku, req_id: R(n) }));
  const a = await buy('unlock:u_full', 1);   // 120
  assert.equal(a.ok, true); assert.equal(a.shard, 380); assert.deepEqual(a.unlocks, ['u_full']);
  const dup = await buy('unlock:u_full', 1);
  assert.equal(dup.dup, true); assert.equal(dup.shard, 380);
  assert.equal((await buy('unlock:u_full', 2)).code, 'owned');
  const poor = await buy('unlock:u_reroll2', 3);   // 650 > 380
  assert.equal(poor.status, 402); assert.equal(poor.code, 'insufficient'); assert.equal(poor.shard, 380);
  assert.equal((await buy('unlock:nope', 4)).status, 400);
});

test('economy: two parallel purchases on the same balance charge only what the balance allows', async () => {
  const env = mkEnv();
  await call(env, '/api/econ');
  setBal(env, 'p1', 'shard', 500);
  // u_hp 500 and u_hp2 600 / u_start 400: 500 covers exactly one of u_hp or (u_start); never both.
  const rs = await Promise.all([
    j(call(env, '/api/econ/spend', 'POST', { sku: 'unlock:u_hp', req_id: R(1) })),
    j(call(env, '/api/econ/spend', 'POST', { sku: 'unlock:u_start', req_id: R(2) })),
  ]);
  assert.equal(rs.filter((r) => r.ok).length, 1);
  const s = await j(call(env, '/api/econ'));
  assert.ok(s.shard === 0 || s.shard === 100); assert.equal(s.unlocks.length, 1);
  // Same request id sent three times in parallel: one charge.
  setBal(env, 'p1', 'shard', 1000);
  const same = await Promise.all([1, 2, 3].map(() => j(call(env, '/api/econ/spend', 'POST', { sku: 'unlock:u_reroll', req_id: R(9) }))));
  assert.ok(same.every((r) => r.ok));
  assert.equal((await j(call(env, '/api/econ'))).shard, 780);
});

test('economy: tickets use the stepped price, day cap, and parallel buys with different ids cannot reuse a price', async () => {
  const env = mkEnv();
  await call(env, '/api/econ');
  setBal(env, 'p1', 'shard', 100000);
  const buy = (n, id) => j(call(env, '/api/econ/spend', 'POST', { sku: `ticket:${n}`, req_id: R(id) }));
  const a = await buy(2, 1);
  assert.equal(a.shard, 100000 - ticketPrice(1) - ticketPrice(2)); assert.equal(a.ticket, 5);
  const rs = await Promise.all([buy(1, 2), buy(1, 3)]);
  assert.equal(rs.filter((r) => r.ok).length >= 1, true);
  for (const r of rs) assert.ok(r.ok || r.code === 'conflict');
  const s = await j(call(env, '/api/econ'));
  assert.equal(s.buy_count, 2 + rs.filter((r) => r.ok).length);
  // push to the cap
  setBal(env, 'p1', 'ticket', 0);
  const left = 30 - s.buy_count;
  assert.equal((await buy(left, 10)).ok, true);
  assert.equal((await buy(1, 11)).code, 'day_cap');
  assert.equal(ticketCost(0, 31), -1);
});

test('economy: ticket hold cap 999 is a database trigger', async () => {
  const env = mkEnv();
  await call(env, '/api/econ');
  setBal(env, 'p1', 'shard', 100000); setBal(env, 'p1', 'ticket', 998);
  const r = await j(call(env, '/api/econ/spend', 'POST', { sku: 'ticket:2', req_id: R(1) }));
  assert.equal(r.code, 'hold_cap'); assert.equal(r.ticket, 998); assert.equal(r.shard, 100000, 'nothing charged');
});

test('economy: daily claim needs a closed run today, pays once per day; weekly needs 4 daily claims', async () => {
  const env = mkEnv();
  await call(env, '/api/econ');
  assert.equal((await j(call(env, '/api/econ/claim', 'POST', { kind: 'daily' }))).code, 'no_run_today');
  const now = Math.floor(Date.now() / 1000);
  env.DB.db.prepare(`INSERT INTO runs (run_id, player_id, mode, rules_version, state, created_at, closed_at, outcome, battles_done) VALUES (?, 'p1', 'normal', 'x', 'closed', ?, ?, 'won', 3)`).run('a'.repeat(32), now - 5, now - 1);
  const c = await j(call(env, '/api/econ/claim', 'POST', { kind: 'daily' }));
  assert.equal(c.ok, true); assert.equal(c.shard, 560); assert.equal(c.stone, 500);
  const again = await j(call(env, '/api/econ/claim', 'POST', { kind: 'daily' }));
  assert.equal(again.dup, true); assert.equal(again.shard, 560);
  assert.equal((await j(call(env, '/api/econ/claim', 'POST', { kind: 'weekly' }))).code, 'not_enough_days');
  assert.equal((await j(call(env, '/api/econ/claim', 'POST', { kind: 'daily_run' }))).code, 'no_run_today');
});

const insRun = (env, id, pid, mode, battles, shards) => env.DB.db.prepare(
  `INSERT INTO runs (run_id, player_id, mode, rules_version, state, created_at, closed_at, battles_done, summary_json) VALUES (?, ?, ?, 'x', 'closed', 1, 2, ?, ?)`)
  .run(id, pid, mode, battles, JSON.stringify({ shards }));

test('economy C1/C2: run reward is computed on the server, once per run, own closed non-mission runs only', async () => {
  const env = mkEnv();
  await call(env, '/api/econ');
  const claim = (run_id, extra = {}) => j(call(env, '/api/econ/claim', 'POST', { kind: 'run', run_id, ...extra }));
  assert.equal((await claim('b'.repeat(32))).code, 'run_not_closed');
  insRun(env, 'b'.repeat(32), 'p1', 'normal', 4, 120);
  const r = await claim('b'.repeat(32), { amount: 99999 });   // the amount in the request is ignored
  assert.equal(r.shard, 620);
  assert.equal((await claim('b'.repeat(32))).shard, 620, 'replay: no second payment');
  insRun(env, 'c'.repeat(32), 'p1', 'normal', 4, 999999);     // absurd recorded value is clamped
  assert.equal((await claim('c'.repeat(32))).shard, 620 + 3000);
  insRun(env, 'd'.repeat(32), 'p1', 'mission', 4, 500);       // C2: Mission runs pay through escrow only
  assert.equal((await claim('d'.repeat(32))).code, 'run_not_closed');
  insRun(env, 'e'.repeat(32), 'p1', 'normal', 0, 500);        // no battle played
  assert.equal((await claim('e'.repeat(32))).code, 'run_not_closed');
  insRun(env, 'f'.repeat(32), 'p2', 'normal', 4, 500);        // someone else's run
  assert.equal((await claim('f'.repeat(32))).code, 'run_not_closed');
  insRun(env, '1'.repeat(32), 'p1', 'normal', 4, 0);
  assert.equal((await claim('1'.repeat(32))).code, 'nothing_to_claim');
});

test('economy N1: daily claim uses the same valid-run gate (battles >= 1, not Mission)', async () => {
  const env = mkEnv();
  await call(env, '/api/econ');
  const now = Math.floor(Date.now() / 1000);
  const ins = (id, mode, b) => env.DB.db.prepare(`INSERT INTO runs (run_id, player_id, mode, rules_version, state, created_at, closed_at, battles_done) VALUES (?, 'p1', ?, 'x', 'closed', ?, ?, ?)`).run(id, mode, now - 5, now - 1, b);
  ins('a'.repeat(32), 'normal', 0); ins('b'.repeat(32), 'mission', 5);
  assert.equal((await j(call(env, '/api/econ/claim', 'POST', { kind: 'daily' }))).code, 'no_run_today');
  ins('c'.repeat(32), 'normal', 1);
  assert.equal((await j(call(env, '/api/econ/claim', 'POST', { kind: 'daily' }))).ok, true);
});

test('economy N3/N4: starter runs no batch after the first time, and never twice for the same identity', async () => {
  const env = mkEnv();
  await call(env, '/api/econ');
  let batches = 0; const ob = env.DB.batch.bind(env.DB); env.DB.batch = (x) => { batches++; return ob(x); };
  await call(env, '/api/econ'); await call(env, '/api/econ');
  assert.equal(batches, 0);
  // delete the account and register it again under the same durable id: no second starter
  env.DB.db.exec('PRAGMA foreign_keys = ON');
  env.DB.db.prepare(`DELETE FROM players WHERE id = 'p1'`).run();
  env.DB.db.prepare(`INSERT INTO players (id, display_name, created_at, last_login_at) VALUES ('p1', 'p', 1, 1)`).run();
  env.DB.db.prepare('INSERT INTO sessions (id_hash, player_id, created_at, expires_at) VALUES (?, ?, 1, 9999999999)').run((await import('node:crypto')).createHash('sha256').update('tok1').digest('base64url'), 'p1');
  const s = await j(call(env, '/api/econ'));
  assert.equal(s.shard, 0); assert.equal(s.ticket, 0);
});

// ------------------------------------------------------------ Echo Box

const seeded = (seed) => () => { seed = (seed * 1664525 + 1013904223) >>> 0; return seed / 4294967296; };

test('echobox: distribution over 100k pulls matches the table weights', () => {
  const rows = echo.boxes.normal.table;
  const total = rows.reduce((a, r) => a + r.weight, 0);
  const rand = seeded(7);
  const hit = {}; let pity = {}; const owned = new Set();
  const N = 100000;
  let stone = 0;
  for (let i = 0; i < N; i++) {
    const r = openNormal(pity, owned, rand);
    pity = r.pity;
    if (r.kind === 'stone') { hit[`s${r.amount}`] = (hit[`s${r.amount}`] || 0) + 1; stone++; }
    else hit[r.rarity] = (hit[r.rarity] || 0) + 1;
  }
  // Stone rows are not touched by pity, so their frequency equals weight / total.
  for (const row of rows.filter((x) => x.kind === 'stone')) {
    const exp = row.weight / total; const got = (hit[`s${row.amount}`] || 0) / N;
    assert.ok(Math.abs(got - exp) < 0.006, `stone ${row.amount}: ${got} vs ${exp}`);
  }
  const stoneW = rows.filter((x) => x.kind === 'stone').reduce((a, r) => a + r.weight, 0);
  assert.ok(Math.abs(stone / N - stoneW / total) < 0.006);
});

test('echobox: pity steps force the minimum rarity and reset lower counters', () => {
  const cosRows = echo.boxes.normal.table.filter((r) => r.kind === 'cosmetic');
  assert.ok(cosRows.length > 0);
  // Always draw the first row (rand ~ 0) = a Stone row or common; with the rare counter due, a cosmetic >= rare must come.
  const rand = () => 0.0;
  const first = openNormal({ since_rare: 15 }, new Set(), rand);
  if (first.kind === 'cosmetic') assert.ok(['rare', 'epic', 'legendary', 'mythic'].includes(first.rarity));
  // Force a cosmetic row by picking a high rand that lands in the common cosmetic: use scripted rand lists.
  const script = (vals) => { let i = 0; return () => vals[Math.min(i++, vals.length - 1)]; };
  const total = echo.boxes.normal.table.reduce((a, r) => a + r.weight, 0);
  const stoneW = echo.boxes.normal.table.filter((r) => r.kind === 'stone').reduce((a, r) => a + r.weight, 0);
  const xCos = (stoneW + 0.01) / total;   // just inside the first cosmetic row
  const forced = openNormal({ since_epic: 60, since_rare: 60 }, new Set(), script([xCos, 0.0, 0.0]));
  assert.equal(forced.kind, 'cosmetic');
  assert.ok(['epic', 'legendary', 'mythic'].includes(forced.rarity), `forced ${forced.rarity}`);
  assert.equal(forced.pity.since_rare, 0); assert.equal(forced.pity.since_epic, 0);
  assert.ok(forced.pity.since_legendary >= 1 || forced.rarity !== 'epic');
});

test('echobox: duplicates give fragments, 10 fragments = 1 ticket back', () => {
  const box = echo.boxes.normal;
  const ids = poolIds(box, 'common');
  const owned = new Set(ids);
  const script = (vals) => { let i = 0; return () => vals[Math.min(i++, vals.length - 1)]; };
  const total = box.table.reduce((a, r) => a + r.weight, 0);
  const stoneW = box.table.filter((r) => r.kind === 'stone').reduce((a, r) => a + r.weight, 0);
  const xCom = (stoneW + 0.01) / total;
  const first = box.table.find((r) => r.kind === 'cosmetic');
  assert.equal(first.rarity, 'common');
  let pity = { fragments: 8 };
  const r = openNormal(pity, owned, script([xCom, 0.5]));
  assert.equal(r.duplicate, true); assert.equal(r.fragments, echo.dup_fragments.common);
  assert.equal(r.tickets_back, Math.floor((8 + echo.dup_fragments.common) / 10));
  assert.equal(r.pity.fragments, (8 + echo.dup_fragments.common) % 10);
});

test('echobox endpoint: spends a ticket, pays stone or items, retry replays, parallel opens cannot reuse a pity position', async () => {
  const env = mkEnv();
  await call(env, '/api/econ');
  const fixed = seeded(3);
  const { handleEcon } = await import('../src/economy.js');
  const open = (id) => handleEcon(new Request('https://axiedice.fun/api/echobox/open', { method: 'POST', headers: { cookie: 'ad_session=tok1', 'content-type': 'application/json' }, body: JSON.stringify({ req_id: R(id) }) }), env, new URL('https://axiedice.fun/api/echobox/open'), { rand: fixed }).then(async (r) => ({ status: r.status, ...(await r.json()) }));
  const a = await open(1);
  assert.equal(a.ok, true); assert.equal(a.ticket, 2); assert.equal(a.opens, 1);
  if (a.result.kind === 'stone') assert.equal(a.stone, a.result.amount); else assert.ok(a.owned.includes(a.result.item));
  const dup = await open(1);
  assert.equal(dup.dup, true); assert.equal(dup.ticket, 2); assert.equal(dup.opens, 1);
  const rs = await Promise.all([open(2), open(3)]);
  assert.equal(rs.filter((r) => r.ok).length >= 1, true);
  for (const r of rs) assert.ok(r.ok || r.code === 'conflict');
  const s = await j(call(env, '/api/econ'));
  assert.equal(s.opens, 1 + rs.filter((r) => r.ok).length);
  assert.equal(s.ticket, 3 - s.opens + 0);   // no recycle yet: pool is empty of owned items
  setBal(env, 'p1', 'ticket', 0);
  assert.equal((await open(20)).code, 'no_tickets');
  assert.equal((await open(20)).status, 402);
});

// ------------------------------------------------------------ SR1 client support: save split, source claims, reset

test('save split: PUT drops server-owned meta keys, GET never returns them', async () => {
  const env = mkEnv();
  const put = (rev, meta) => call(env, '/api/save', 'PUT', { rev, meta });
  const r = await put(0, { shard_pool: 999999, stone: 5, tickets: { normal: 9 }, unlocks: ['u_hp'], echobox_pity: { a: 1 }, starter_granted: true, starter_shard_locked: 3, runs: 7 });
  assert.equal(r.status, 200);
  const stored = JSON.parse(env.DB.db.prepare(`SELECT meta_json FROM saves WHERE player_id = 'p1'`).get().meta_json);
  assert.deepEqual(stored, { runs: 7 });
  env.DB.db.prepare(`UPDATE saves SET meta_json = ?`).run(JSON.stringify({ shard_pool: 1e9, runs: 1 }));   // an old row from before the split
  assert.deepEqual((await j(call(env, '/api/save'))).meta, { runs: 1 });
  assert.equal((await j(call(env, '/api/econ'))).shard, 500, 'balance unaffected by the save');
});

test('claim mission: Stone from the settled escrow and the table, once, capped per day', async () => {
  const env = mkEnv();
  await call(env, '/api/econ');
  const { _setTableForTest } = await import('../src/missions.js');
  _setTableForTest({ payout_cap: 20000, stone_day_cap: 10, tiers: { N1: { stake: 300, m_base: 2, stone: 4 }, N2: { stake: 500, m_base: 2, stone: 8 } } });
  const esc = (id, tier, state) => { env.DB.db.prepare(`INSERT INTO runs (run_id, player_id, mode, rules_version, state, created_at) VALUES (?, 'p1', 'mission', 'x', 'closed', 1)`).run(id); env.DB.db.prepare(`INSERT INTO mission_escrow (run_id, player_id, tier, stake, payout_mult, state, created_at) VALUES (?, 'p1', ?, 1, 1, ?, 1)`).run(id, tier, state); };
  const claim = (id, extra) => j(call(env, '/api/econ/claim', 'POST', { kind: 'mission', run_id: id, ...extra }));
  esc('a'.repeat(32), 'N1', 'lost'); esc('b'.repeat(32), 'N1', 'won'); esc('c'.repeat(32), 'N2', 'won');
  assert.equal((await claim('a'.repeat(32))).code, 'run_not_closed');
  assert.equal((await claim('b'.repeat(32), { amount: 999 })).stone, 4);
  assert.equal((await claim('b'.repeat(32))).stone, 4, 'replay');
  assert.equal((await claim('c'.repeat(32))).stone, 10, 'clipped to the day cap: 4 + min(8, 6)');
  _setTableForTest();
});

const inSeason = async (fn) => { const real = Date.now; Date.now = () => Date.parse('2026-11-10T12:00:00Z'); try { await fn(Math.floor(Date.now() / 1000)); } finally { Date.now = real; } };

test('pass XP: server adds run XP (clamped, day cap), claim only up to the server level, once per level', async () => {
  await inSeason(async (now) => {
    const env = mkEnv();
    const s0 = await j(call(env, '/api/econ'));
    assert.deepEqual(s0.pass, { season: 's1', xp: 0, level: 0, claimed: [] });
    const pass = (level) => j(call(env, '/api/econ/claim', 'POST', { kind: 'pass', level }));
    assert.equal((await pass(1)).code, 'not_reached', 'client cannot claim a level it did not earn');
    const run = (id, closed, score, pw = 10, extra = {}) => env.DB.db.prepare(`INSERT INTO runs (run_id, player_id, mode, ascension, rules_version, state, created_at, closed_at, outcome, battles_done, summary_json) VALUES (?, 'p1', ?, 0, 'x', 'closed', 1, ?, 'won', 5, ?)`)
      .run(id, extra.mode || 'normal', closed, JSON.stringify({ score, len: 'short', pw, bosses_started: 1, elites: 1 }));
    run('a'.repeat(32), now - 100, 400);           // within the formula cap: 30+100+60+150+30 = 370 -> clamped to 370
    run('b'.repeat(32), now - 90, 370);             // exactly the formula ceiling
    run('c'.repeat(32), now - 80, 400, 10, { mode: 'mission' });   // Mission runs give no Pass XP here
    const s1 = await j(call(env, '/api/econ'));
    assert.equal(s1.pass.xp, 740);
    assert.equal(s1.pass.level, 1);   // level 1 needs 500
    assert.equal((await j(call(env, '/api/econ'))).pass.xp, 740, 'not counted twice');
    const a = await pass(1);
    assert.equal(a.shard, 800); assert.deepEqual(a.pass.claimed, [1]);
    assert.equal((await pass(1)).shard, 800);
    assert.equal((await pass(2)).code, 'not_reached');
  });
});

test('pass XP: day cap (1500 full, 20% after, 2000 max) and daily-claim bonus', async () => {
  await inSeason(async (now) => {
    const { capRunXp } = await import('../src/economy.js');
    assert.deepEqual(capRunXp(1000, 0), { granted: 1000, used: 1000 });
    assert.deepEqual(capRunXp(1000, 1000), { granted: 500 + 100, used: 1600 });
    assert.deepEqual(capRunXp(5000, 1990), { granted: 10, used: 2000 });
    const env = mkEnv();
    await call(env, '/api/econ');
    env.DB.db.prepare(`INSERT INTO runs (run_id, player_id, mode, rules_version, state, created_at, closed_at, battles_done) VALUES (?, 'p1', 'normal', 'x', 'closed', 1, ?, 2)`).run('d'.repeat(32), now - 5);
    const c = await j(call(env, '/api/econ/claim', 'POST', { kind: 'daily' }));
    assert.equal(c.pass.xp, 100);
  });
});

test('claim land: milestone items from decor.json, needs the points, once', async () => {
  const env = mkEnv();
  await call(env, '/api/econ');
  const land = (milestone, points) => j(call(env, '/api/econ/claim', 'POST', { kind: 'land', milestone, points }));
  assert.equal((await land('m2', 5)).code, 'not_reached');
  assert.equal((await land('nope', 50)).status, 400);
  assert.deepEqual((await land('m1', 5)).owned, ['title:Gardener']);
  assert.deepEqual((await land('m1', 5)).owned, ['title:Gardener']);
  const m8 = await land('m8', 100);
  assert.ok(m8.owned.includes('frame_l_sunburst') && m8.owned.includes('decor_trophy'));
});

test('reset M1: SQL deletes everything, leaves players/sessions, marks reset_id, starter is paid again', async () => {
  const env = mkEnv();
  await call(env, '/api/econ');
  await call(env, '/api/econ/spend', 'POST', { sku: 'unlock:u_full', req_id: R(1) });
  await call(env, '/api/save', 'PUT', { rev: 0, meta: { runs: 3 } });
  assert.equal((await j(call(env, '/api/econ'))).reset_id, '');
  const sql = readFileSync(new URL('../scripts/reset_m1.sql', import.meta.url), 'utf8').replaceAll('__RESET_ID__', 'T1').replaceAll('__NOW__', '1700000000');
  env.DB.db.exec(sql);
  const n = (t) => env.DB.db.prepare(`SELECT COUNT(*) n FROM ${t}`).get().n;
  for (const t of ['saves', 'unlocks', 'wallets', 'runs', 'starter_claims']) assert.equal(n(t), 0, t);
  assert.equal(n('players'), 2); assert.equal(n('sessions'), 2);
  const s = await j(call(env, '/api/econ'));
  assert.equal(s.reset_id, 'T1'); assert.equal(s.shard, 500); assert.deepEqual(s.unlocks, []);
  assert.equal((await j(call(env, '/api/save'))).rev, 0, 'cloud save gone: another device sees no old numbers');
});
