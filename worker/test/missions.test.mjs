// Mission stake escrow (L1 option A): create/validate, settle won/lost/abandon/refund, cap, shard ledger,
// currency filter on /api/wallet, newcomer gate, ALLOW_GATED_MODES untouched. Same node:sqlite D1 as runs.test.mjs.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { DatabaseSync } from 'node:sqlite';
import worker from '../src/index.js';
import { RunCore } from '../src/run_core.js';
import { settleEscrow, payoutFor, PAYOUT_CAP, _setTableForTest } from '../src/missions.js';
import { sweepPending, PENDING_TTL_S } from '../src/runs.js';
import { RunDO, SUPPORTED_RULE_VERSIONS } from '../src/run_do.js';

const RULES = SUPPORTED_RULE_VERSIONS.at(-1);   // mission runs only take the current rules version
const mig = (f) => readFileSync(new URL(`../migrations/${f}`, import.meta.url), 'utf8');
// Frozen fixture (the 10/2026 L1 numbers the expectations below are written for), not the live missions.json,
// which lane N-C rewrites for the beta ladder.
const table = { payout_cap: 20000, tiers: {"N1": {"mode": "short", "ascension": 3, "stake": 300, "m_base": 2.15, "m_scale": 1.0}, "N2": {"mode": "short", "ascension": 4, "stake": 500, "m_base": 2.4, "m_scale": 1.0}, "N3": {"mode": "short", "ascension": 6, "stake": 800, "m_base": 3.6, "m_scale": 1.0}, "N4": {"mode": "short", "ascension": 7, "stake": 1200, "m_base": 4.4, "m_scale": 1.0}, "N5": {"mode": "short", "ascension": 9, "stake": 1800, "m_base": 7.85, "m_scale": 0.9}, "N6": {"mode": "full", "ascension": 9, "stake": 2500, "m_base": 8.0, "m_scale": 1.0}} };
_setTableForTest(table);

class Stmt {
  constructor(db, sql) { this.db = db; this.sql = sql; this.args = []; }
  bind(...a) { this.args = a; return this; }
  async first() { return this.db.prepare(this.sql).get(...this.args) ?? null; }
  async all() { return { results: this.db.prepare(this.sql).all(...this.args) }; }
  async run() { const r = this.db.prepare(this.sql).run(...this.args); return { success: true, meta: { changes: Number(r.changes) } }; }
}
class FakeD1 {
  constructor() {
    this.db = new DatabaseSync(':memory:'); this.db.exec('PRAGMA foreign_keys = ON;');
    for (const f of ['0001_accounts.sql', '0002_runs.sql', '0009_depth_stage.sql', '0003_wallet.sql', '0005_token_revocation.sql', '0006_leaderboard.sql', '0007_mission_escrow.sql', '0010_mission_unlock.sql']) this.db.exec(mig(f));
  }
  prepare(s) { return new Stmt(this.db, s); }
  async batch(stmts) { const out = []; for (const s of stmts) out.push(await s.run()); return out; }
}
function fakeDo({ failInit = false } = {}) {
  const cores = new Map();
  return {
    cores,
    idFromName: (n) => n,
    get: (name) => ({
      async fetch(url, init) {
        const path = new URL(typeof url === 'string' ? url : url.url).pathname;
        if (failInit && path === '/init') throw new Error('boom');
        let core = cores.get(name);
        if (!core) {
          const db = new DatabaseSync(':memory:');
          const sql = { exec(q, ...b) { const st = db.prepare(q); if (/^\s*select/i.test(q)) { const r = st.all(...b); return { toArray: () => r }; } if (/^\s*(insert|update|delete)/i.test(q)) { st.run(...b); return { toArray: () => [] }; } db.exec(q); return { toArray: () => [] }; } };
          core = new RunCore(sql, { supportsRules: () => true });
          cores.set(name, core);
        }
        if (path === '/init') { const o = await core.init(JSON.parse(init.body)); return new Response(JSON.stringify(o), { status: o.ok ? 200 : 409 }); }
        if (path === '/abandon') return new Response(JSON.stringify(core.abandonInfo()), { status: 200 });
        return new Response('{}', { status: 404 });
      },
    }),
  };
}
async function setup(extra = {}) {
  const DB = new FakeD1();
  const env = { DB, RUN_DO: fakeDo(extra.do), RUN_TOKEN_KEY: 'k', SESSION_SIGNING_KEY: 's', ...extra.env };
  for (const [id, token] of [['google:1', 'tok1'], ['google:2', 'tok2']]) {
    DB.db.prepare('INSERT INTO players (id, email, display_name, created_at, last_login_at) VALUES (?, ?, ?, 1, 1)').run(id, `${id}@x`, id);
    const hash = Buffer.from(await crypto.subtle.digest('SHA-256', new TextEncoder().encode(token))).toString('base64url');
    DB.db.prepare('INSERT INTO sessions (id_hash, player_id, created_at, expires_at) VALUES (?, ?, 1, 9999999999)').run(hash, id);
  }
  // enough finished runs to pass the newcomer gate (5 with a fight)
  const seed = (player, n) => { for (let i = 0; i < n; i++) DB.db.prepare(`INSERT INTO runs (run_id, player_id, mode, ascension, rules_version, state, created_at, closed_at, outcome, battles_done) VALUES (?, ?, 'normal', 0, ?, 'closed', 1, 2, 'lost', 1)`).run(`${player.slice(-1)}${i}`.padStart(32, 'a'), player, RULES); };
  if (!extra.newcomer) { seed('google:1', 5); seed('google:2', 5); }
  // These tests are about escrow, not the unlock chain: open every tier for both players (missions_unlock covers the chain).
  if (!extra.locked) for (const p of ['google:1', 'google:2']) for (const t of ['N1', 'N2', 'N3', 'N4', 'N5']) DB.db.prepare('INSERT INTO mission_wins (run_id, player_id, tier, at) VALUES (?, ?, ?, 1)').run(`seed-${p}-${t}`, p, t);
  const call = (path, { method = 'GET', body, token = 'tok1' } = {}) =>
    worker.fetch(new Request(`https://axiedice.fun${path}`, {
      method, headers: { cookie: `ad_session=${token}`, 'content-type': 'application/json' },
      body: body === undefined ? undefined : JSON.stringify(body),
    }), env);
  const mission = (tier = 'N1', over = {}, opts) => {
    const t = table.tiers[tier];
    return call('/api/run', { method: 'POST', body: { rules_version: RULES, kind: 'mission', ascension: t.ascension, mission: { tier, stake: t.stake }, ...over }, ...opts });
  };
  const escrow = async (opts) => (await call('/api/missions/escrow', opts)).json();
  const shardRows = (player = 'google:1') => DB.db.prepare(`SELECT delta, reason, idem_key FROM wallet_ledger WHERE player_id = ? AND currency = 'shard' ORDER BY id`).all(player).map((r) => ({ ...r }));
  const row = (runId) => DB.db.prepare('SELECT * FROM mission_escrow WHERE run_id = ?').get(runId);
  return { DB, env, call, mission, escrow, shardRows, row };
}
const enterBattle = (env, runId) => env.RUN_DO.cores.get(runId).sql.exec(   // the DO's own log now has a 'node' epoch
  `INSERT INTO epochs (seq, kind, args, h, log_len, seed, log_delta, attempt, req_digest, at) VALUES (1, 'node', '{}', 'h', 1, 1, '[]', 0, 'd', 1)`);
const close = async (env, DB, runId, outcome) => {   // what RunDO._syncClosed does after run_close
  DB.db.prepare(`UPDATE runs SET state = 'closed', outcome = ?, closed_at = 5 WHERE run_id = ?`).run(outcome, runId);
  return settleEscrow(env, runId, outcome);
};

test('table sanity: payouts are the documented 645 / 1200 / 2880', () => {
  assert.deepEqual(['N1', 'N2', 'N3'].map((t) => payoutFor(table.tiers[t].stake, table.tiers[t].m_base * table.tiers[t].m_scale)), [645, 1200, 2880]);
  assert.equal(PAYOUT_CAP, 20000);
});

test('create: mission is open (not not_available); escrow row + shard stake-out are written with the run', async () => {
  const { mission, row, shardRows } = await setup();
  const r = await mission('N2');
  assert.equal(r.status, 200);
  const j = await r.json();
  const e = row(j.run_id);
  assert.equal(e.tier, 'N2'); assert.equal(e.stake, 500); assert.equal(e.state, 'open'); assert.equal(e.payout, 0);
  assert.ok(Math.abs(e.payout_mult - 2.4) < 1e-9);
  assert.deepEqual(shardRows(), [{ delta: -500, reason: 'mission_stake:N2', idem_key: `mission_stake:${j.run_id}` }]);
});

test('create: validation. N4..N6 are buyable once unlocked (no tier_locked), bad tier 400, stake/ascension must match the table (409), no block 400', async () => {
  const { mission, call, DB } = await setup();
  for (const bad of [{ tier: 'N7', stake: 1 }, { tier: 'n1', stake: 300 }, { tier: 'N1', stake: '300' }, { tier: 'N1' }, 'N1', null, [], { tier: '__proto__', stake: 300 }]) {
    assert.equal((await mission('N1', { mission: bad })).status, 400, JSON.stringify(bad));
  }
  const r = await mission('N1', { mission: { tier: 'N1', stake: 1 } });
  assert.equal(r.status, 409); assert.equal((await r.json()).error, 'stake_mismatch');
  assert.equal((await mission('N1', { mission: { tier: 'N1', stake: 800 } })).status, 409);
  assert.equal((await (await mission('N3', { ascension: 3 })).json()).error, 'tier_mismatch');
  assert.equal((await call('/api/run', { method: 'POST', body: { rules_version: RULES, kind: 'mission', ascension: 3 } })).status, 400);
  // a mission block on a non-mission run is refused, not silently ignored
  assert.equal((await call('/api/run', { method: 'POST', body: { rules_version: RULES, kind: 'normal', mission: { tier: 'N1', stake: 300 } } })).status, 400);
  assert.equal(DB.db.prepare('SELECT COUNT(*) AS n FROM mission_escrow').get().n, 0);
  assert.equal(DB.db.prepare(`SELECT COUNT(*) AS n FROM wallet_ledger WHERE currency = 'shard'`).get().n, 0);
});

test('create: newcomer gate like ranked; a second run while one is open is 409 and leaves no second escrow', async () => {
  const a = await setup({ newcomer: true });
  const r = await a.mission('N1');
  assert.equal(r.status, 403); assert.equal((await r.json()).error, 'newcomer_locked');
  const b = await setup();
  assert.equal((await b.mission('N1')).status, 200);
  assert.equal((await b.mission('N2')).status, 409);
  assert.equal(b.DB.db.prepare('SELECT COUNT(*) AS n FROM mission_escrow').get().n, 1);
  assert.equal(b.shardRows().length, 1);
});

test('ALLOW_GATED_MODES is untouched: still lifts the newcomer gate for ranked and mission; not set = gate holds', async () => {
  const a = await setup({ newcomer: true, env: { ALLOW_GATED_MODES: '1' } });
  assert.equal((await a.mission('N1')).status, 200);
  const b = await setup({ newcomer: true });
  assert.equal((await (await b.call('/api/run', { method: 'POST', body: { rules_version: RULES, kind: 'ranked' } })).json()).error, 'newcomer_locked');
});

test('settle won: payout = stake x mult through the real close path, one shard row, idempotent', async () => {
  const { mission, env, DB, row, shardRows, escrow } = await setup();
  const { run_id } = await (await mission('N3')).json();
  const s = await close(env, DB, run_id, 'won');
  assert.equal(s.state, 'won'); assert.equal(s.payout, 2880);
  assert.deepEqual(shardRows().map((r) => r.delta), [-800, 2880]);
  await close(env, DB, run_id, 'won'); await settleEscrow(env, run_id, 'lost'); await settleEscrow(env, run_id, 'refunded');
  assert.equal(row(run_id).state, 'won');
  assert.equal(shardRows().length, 2);
  const e = await escrow();
  assert.equal(e.open, null);
  assert.deepEqual(e.settled.map((x) => [x.run_id, x.state, x.payout]), [[run_id, 'won', 2880]]);
});

test('settle lost: no payout, no second ledger row; a late won/refund cannot reopen it', async () => {
  const { mission, env, DB, row, shardRows } = await setup();
  const { run_id } = await (await mission('N1')).json();
  assert.equal((await close(env, DB, run_id, 'lost')).state, 'lost');
  await settleEscrow(env, run_id, 'won');
  assert.equal(row(run_id).state, 'lost'); assert.equal(row(run_id).payout, 0);
  assert.deepEqual(shardRows().map((r) => r.delta), [-300]);
});

test('abandon = lost (open run); abandoning a pending run that never started refunds it', async () => {
  const { mission, call, row, shardRows, DB, env } = await setup();
  const a = await (await mission('N1')).json();
  enterBattle(env, a.run_id);
  assert.equal((await call(`/api/run/${a.run_id}/abandon`, { method: 'POST' })).status, 200);
  assert.equal(row(a.run_id).state, 'lost');
  assert.deepEqual(shardRows().map((r) => r.delta), [-300]);
  const b = await (await mission('N2')).json();
  DB.db.prepare(`UPDATE runs SET state = 'pending' WHERE run_id = ?`).run(b.run_id);
  await call(`/api/run/${b.run_id}/abandon`, { method: 'POST' });
  assert.equal(row(b.run_id).state, 'refunded');
  assert.deepEqual(shardRows().map((r) => r.delta), [-300, -500, 500]);
});

test('infra_error refunds: DO init failure, and a stale pending run swept by the cron', async () => {
  const a = await setup({ do: { failInit: true } });
  const r = await a.mission('N2');
  assert.equal(r.status, 502);
  const e = a.DB.db.prepare('SELECT * FROM mission_escrow').get();
  assert.equal(e.state, 'refunded'); assert.equal(e.payout, 500);
  assert.deepEqual(a.shardRows().map((x) => x.delta), [-500, 500]);
  const b = await setup();
  const { run_id } = await (await b.mission('N1')).json();
  b.DB.db.prepare(`UPDATE runs SET state = 'pending', created_at = 1 WHERE run_id = ?`).run(run_id);
  await sweepPending(b.env, 1 + PENDING_TTL_S + 10);
  assert.equal(b.row(run_id).state, 'refunded');
  assert.deepEqual(b.shardRows().map((x) => x.delta), [-300, 300]);
});

test('cap: the payout is clamped to the table cap even if the stored multiplier would exceed it', async () => {
  const { mission, env, DB, row } = await setup();
  const { run_id } = await (await mission('N3')).json();
  DB.db.prepare('UPDATE mission_escrow SET stake = 5000, payout_mult = 8 WHERE run_id = ?').run(run_id);   // 40,000 raw
  const s = await close(env, DB, run_id, 'won');
  assert.equal(s.payout, 20000); assert.equal(row(run_id).payout, 20000);
  assert.equal(payoutFor(2500, 8), 20000);   // N6 exactly at the cap is not "over"
});

test('GET /api/missions/escrow: open escrow, last settlements, per player, reconciles a close that never wrote back', async () => {
  const { mission, escrow, DB, row } = await setup();
  const { run_id } = await (await mission('N1')).json();
  let e = await escrow();
  assert.equal(e.open.run_id, run_id); assert.equal(e.open.stake, 300); assert.deepEqual(e.settled, []);
  assert.equal((await escrow({ token: 'tok2' })).open, null);
  // run closed (D1 run row updated) but the settle write failed: the GET settles it
  DB.db.prepare(`UPDATE runs SET state = 'closed', outcome = 'won', closed_at = 5 WHERE run_id = ?`).run(run_id);
  e = await escrow();
  assert.equal(e.open, null); assert.equal(e.settled[0].state, 'won'); assert.equal(e.settled[0].payout, 645);
  assert.equal(row(run_id).state, 'won');
  assert.equal((await escrow({ token: 'nope' })).error, 'unauthenticated');
});

test('wallet: /api/wallet ledger_tail shows Gem rows only, shard rows never mix in', async () => {
  const { mission, call, DB } = await setup();
  DB.db.prepare(`INSERT INTO wallets (player_id, currency, balance) VALUES ('google:1', 'gem', 10)`).run();
  DB.db.prepare(`INSERT INTO wallet_ledger (player_id, currency, delta, reason, idem_key, at) VALUES ('google:1', 'gem', 10, 'grant:x', 'k1', 1)`).run();
  await mission('N1');
  const w = await (await call('/api/wallet')).json();
  assert.equal(w.gem, 10);
  assert.deepEqual(w.ledger_tail.map((r) => r.reason), ['grant:x']);
});

// ---- security review fixes (16/10): server settlement is the truth, races, bounded close ----

const closedDo = async (env, runId, { outcome = 'won', mode = 'mission', player = 'google:1', alarmFails = false } = {}) => {
  const sent = []; let alarm = null;
  const ctx = { storage: { sql: (() => { const db = new DatabaseSync(':memory:'); return { exec(q, ...b) { const st = db.prepare(q); if (/^\s*select/i.test(q)) { const r = st.all(...b); return { toArray: () => r }; } if (/^\s*(insert|update|delete)/i.test(q)) { st.run(...b); return { toArray: () => [] }; } db.exec(q); return { toArray: () => [] }; } }; })(),
    getAlarm: async () => alarm, setAlarm: async (t) => { if (alarmFails) throw new Error('alarm down'); alarm = t; } }, getWebSockets: () => [], acceptWebSocket() {} };
  const d = new RunDO(ctx, env);
  await d.core.init({ run_id: runId, player_id: player, mode, ascension: 0, rules_version: RULES });
  ctx.storage.sql.exec(`UPDATE meta SET state = 'closed', outcome = ?, summary = '{"battles_done":3}' WHERE id = 1`, outcome);
  const ws = { send: (m) => sent.push(JSON.parse(m)), close() {}, serializeAttachment() {}, deserializeAttachment: () => ({}) };
  d.core.handle = async () => ({ replies: [{ t: 'closed', seq: 9 }] });   // the chain check is run_core's own test; here only the close plumbing
  return { d, ws, sent, alarm: () => alarm };
};

test('abandon of a mission run that never entered a battle refunds the stake (run_start failed on the client)', async () => {
  const { mission, call, row, shardRows, DB } = await setup();
  const a = await (await mission('N1')).json();   // POST /api/run done, no run_start / node ever sent
  assert.equal((await call(`/api/run/${a.run_id}/abandon`, { method: 'POST' })).status, 200);
  assert.equal(DB.db.prepare('SELECT state FROM runs WHERE run_id = ?').get(a.run_id).state, 'abandoned');
  assert.equal(row(a.run_id).state, 'refunded'); assert.equal(row(a.run_id).payout, 300);
  assert.deepEqual(shardRows().map((r) => r.delta), [-300, 300]);
  // idempotent: a second abandon neither refunds nor loses anything
  await call(`/api/run/${a.run_id}/abandon`, { method: 'POST' });
  assert.deepEqual(shardRows().map((r) => r.delta), [-300, 300]);
  // GET reflects the server's settlement, which is what the client mirror applies
  const e = await (await call('/api/missions/escrow')).json();
  assert.deepEqual(e.settled.map((x) => [x.state, x.payout]), [['refunded', 300]]);
});

test('abandon after run_start but before any battle is a LOSS: the map was seen, no free reroll (Liam 16/10)', async () => {
  const { mission, call, row, env, shardRows } = await setup();
  const a = await (await mission('N1')).json();
  env.RUN_DO.cores.get(a.run_id).sql.exec(   // run_start answered (seq 0), no node epoch yet
    `INSERT INTO epochs (seq, kind, args, h, log_len, seed, log_delta, attempt, req_digest, at) VALUES (0, 'run_start', '{}', 'h', 0, 1, '[]', 0, 'd', 1)`);
  await call(`/api/run/${a.run_id}/abandon`, { method: 'POST' });
  assert.equal(row(a.run_id).state, 'lost'); assert.equal(row(a.run_id).payout, 0);
  assert.deepEqual(shardRows().map((r) => r.delta), [-300]);
});

test('abandon with a battle entered stays a loss; an unknown battle count fails closed to a loss', async () => {
  const { mission, call, row, env } = await setup();
  const a = await (await mission('N1')).json();
  enterBattle(env, a.run_id);
  await call(`/api/run/${a.run_id}/abandon`, { method: 'POST' });
  assert.equal(row(a.run_id).state, 'lost');
  const b = await setup();
  const j = await (await b.mission('N1')).json();
  const real = b.env.RUN_DO.get;
  b.env.RUN_DO.get = (n) => { const s = real(n); return { fetch: async (u, i) => (new URL(u).pathname === '/abandon' ? new Response(JSON.stringify({ ok: true, state: 'abandoned' })) : s.fetch(u, i)) }; };
  await b.call(`/api/run/${j.run_id}/abandon`, { method: 'POST' });
  assert.equal(b.row(j.run_id).state, 'lost');
});

test('race: abandon wins the runs row, a late close sync must not settle the escrow as won', async () => {
  const { mission, call, env, DB, row, shardRows } = await setup();
  const { run_id } = await (await mission('N1')).json();
  enterBattle(env, run_id);
  await call(`/api/run/${run_id}/abandon`, { method: 'POST' });   // runs=abandoned, escrow=lost
  const { d } = await closedDo(env, run_id, { outcome: 'won' });  // the DO closed 'won' just as the abandon landed
  await d._syncClosed();
  assert.equal(DB.db.prepare('SELECT state, outcome FROM runs WHERE run_id = ?').get(run_id).state, 'abandoned');
  assert.equal(row(run_id).state, 'lost'); assert.equal(row(run_id).payout, 0);
  assert.deepEqual(shardRows().map((r) => r.delta), [-300]);
});

test('race: the run closed in the DO (write-back pending) when abandon arrives: abandon does not mark it lost, the close settles it', async () => {
  const { mission, call, env, DB, row, shardRows } = await setup();
  const { run_id } = await (await mission('N1')).json();
  // worker side: the DO answers /abandon with state 'closed' -> runs and escrow untouched by abandon
  env.RUN_DO.cores.get(run_id).sql.exec(`UPDATE meta SET state = 'closed', outcome = 'won' WHERE id = 1`);
  assert.equal((await call(`/api/run/${run_id}/abandon`, { method: 'POST' })).status, 200);
  assert.equal(DB.db.prepare('SELECT state FROM runs WHERE run_id = ?').get(run_id).state, 'open');
  assert.equal(row(run_id).state, 'open');
  // DO side: /abandon on a closed run writes the close back first, then answers
  const { d } = await closedDo(env, run_id, { outcome: 'won' });
  const r = await d.fetch(new Request('https://do/abandon', { method: 'POST' }));
  assert.equal((await r.json()).state, 'closed');
  assert.equal(DB.db.prepare('SELECT state, outcome FROM runs WHERE run_id = ?').get(run_id).state, 'closed');
  assert.equal(row(run_id).state, 'won'); assert.equal(row(run_id).payout, 645);
  assert.deepEqual(shardRows().map((x) => x.delta), [-300, 645]);
});

test('close sync retried after a failed settle still settles (run row already closed by the first attempt)', async () => {
  const { mission, env, DB, row } = await setup();
  const { run_id } = await (await mission('N1')).json();
  const { d } = await closedDo(env, run_id, { outcome: 'won' });
  const realBatch = env.DB.batch.bind(env.DB);
  env.DB.batch = async () => { throw new Error('d1 down'); };
  await d._syncClosed();   // runs UPDATE lands, settle fails, retry armed
  assert.equal(DB.db.prepare('SELECT state FROM runs WHERE run_id = ?').get(run_id).state, 'closed');
  assert.equal(row(run_id).state, 'open');
  env.DB.batch = realBatch;
  await d._syncClosed();   // alarm retry: UPDATE changes 0, but the row is closed by us -> settle
  assert.equal(row(run_id).state, 'won');
});

test('concurrent settle: close sync vs GET /escrow vs abandon on one closed run pays exactly once', async () => {
  const { mission, call, env, DB, row, shardRows } = await setup();
  const { run_id } = await (await mission('N1')).json();
  enterBattle(env, run_id);
  DB.db.prepare(`UPDATE runs SET state = 'closed', outcome = 'won', closed_at = 5 WHERE run_id = ?`).run(run_id);
  env.RUN_DO.cores.get(run_id).sql.exec(`UPDATE meta SET state = 'closed', outcome = 'won' WHERE id = 1`);
  const results = await Promise.all([
    settleEscrow(env, run_id, 'won'),
    call('/api/missions/escrow').then((r) => r.json()),
    call(`/api/run/${run_id}/abandon`, { method: 'POST' }),
    settleEscrow(env, run_id, 'won'),
    call('/api/missions/escrow').then((r) => r.json()),
  ]);
  assert.equal(results[2].status, 200);
  assert.equal(row(run_id).state, 'won'); assert.equal(row(run_id).payout, 645);
  assert.deepEqual(shardRows().map((x) => x.delta), [-300, 645]);
  const e = await (await call('/api/missions/escrow')).json();
  assert.deepEqual(e.settled.map((x) => [x.state, x.payout]), [['won', 645]]);
});

test('close path: a D1 failure (and a failing setAlarm) still sends the closed reply', async () => {
  const { mission, env } = await setup();
  const { run_id } = await (await mission('N1')).json();
  const { d, ws, sent } = await closedDo(env, run_id, { alarmFails: true });
  env.DB.prepare = () => { throw new Error('d1 down'); };
  const errs = []; const log = console.error; console.error = (...a) => errs.push(a.join(' '));
  try { await d.webSocketMessage(ws, '{}'); } finally { console.error = log; }
  assert.deepEqual(sent, [{ t: 'closed', seq: 9 }]);
  assert.ok(errs.some((e) => /close sync failed/.test(e)) && errs.some((e) => /retry alarm failed/.test(e)));
});

test('close path: a hung D1 is bounded; the reply goes out and an alarm is armed for the retry', async () => {
  const { mission, env } = await setup({ env: { CLOSE_SYNC_BUDGET_MS: '25' } });
  const { run_id } = await (await mission('N1')).json();
  const { d, ws, sent, alarm } = await closedDo(env, run_id);
  env.DB.prepare = () => ({ bind: () => ({ run: () => new Promise(() => {}), first: () => new Promise(() => {}) }) });
  const t0 = Date.now();
  await d.webSocketMessage(ws, '{}');
  assert.ok(Date.now() - t0 < 1000);
  assert.deepEqual(sent, [{ t: 'closed', seq: 9 }]);
  assert.ok(alarm() > Date.now());
});
