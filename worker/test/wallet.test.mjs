import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, existsSync } from 'node:fs';
import { DatabaseSync } from 'node:sqlite';
import worker from '../src/index.js';
import { applyDelta, spendGem, claimDaily, claimSeasonGift, balanceOf } from '../src/wallet.js';
import { PRICES, GIFT, totalCap } from '../src/aid_prices.js';
import { RunCore } from '../src/run_core.js';
import { chainStart, chainNext } from '../src/epoch_canon.js';
import { fakeSql } from './run_core.test.mjs';

const mig = (f) => readFileSync(new URL(`../migrations/${f}`, import.meta.url), 'utf8');
class Stmt {
  constructor(db, sql) { this.db = db; this.sql = sql; this.args = []; }
  bind(...a) { this.args = a; return this; }
  async first() { return this.db.prepare(this.sql).get(...this.args) ?? null; }
  async all() { return { results: this.db.prepare(this.sql).all(...this.args) }; }
  async run() { const r = this.db.prepare(this.sql).run(...this.args); return { success: true, meta: { changes: Number(r.changes) } }; }
}
class TxD1 {
  constructor() { this.db = new DatabaseSync(':memory:'); this.db.exec('PRAGMA foreign_keys = ON;'); for (const f of ['0001_accounts.sql', '0002_runs.sql', '0003_wallet.sql']) this.db.exec(mig(f)); }
  prepare(s) { return new Stmt(this.db, s); }
  // D1 runs one batch at a time per database; the chain stands in for that.
  batch(stmts) { const run = (this.q || Promise.resolve()).then(() => this._batch(stmts)); this.q = run.catch(() => {}); return run; }
  async _batch(stmts) { this.db.exec('BEGIN'); try { const o = []; for (const s of stmts) o.push(await s.run()); this.db.exec('COMMIT'); return o; } catch (e) { this.db.exec('ROLLBACK'); throw e; } }
}
const mkEnv = () => {
  const DB = new TxD1();
  DB.db.prepare(`INSERT INTO players (id, display_name, created_at, last_login_at) VALUES ('p1', 'p', 1, 1), ('p2', 'q', 1, 1)`).run();
  return { DB };
};
const DAY = 86400 * 20000;

test('spend: insufficient funds changes nothing; exact funds work; ledger records both', async () => {
  const env = mkEnv();
  assert.equal((await applyDelta(env, 'p1', 100, 'grant:test', 'g1')).balance, 100);
  assert.deepEqual(await spendGem(env, 'p1', 101, 'aid:R1', 's1'), { ok: false, code: 'insufficient' });
  assert.equal(await balanceOf(env, 'p1'), 100);
  assert.equal((await spendGem(env, 'p1', 100, 'aid:R1', 's2')).balance, 0);
  assert.equal(env.DB.db.prepare('SELECT COUNT(*) AS n FROM wallet_ledger').get().n, 2, 'failed spend left no ledger row');
});

test('idempotency: the same key never pays twice, even in parallel', async () => {
  const env = mkEnv();
  await applyDelta(env, 'p1', 300, 'grant:test', 'g');
  const rs = await Promise.all([1, 2, 3].map(() => spendGem(env, 'p1', 90, 'aid:R1', 'aid:run:3')));
  assert.ok(rs.every((r) => r.ok));
  assert.equal(await balanceOf(env, 'p1'), 210);
  assert.equal((await spendGem(env, 'p1', 90, 'aid:R1', 'aid:run:3')).dup, true);
});

test('wallets are per player', async () => {
  const env = mkEnv();
  await applyDelta(env, 'p1', 50, 'grant:test', 'g');
  assert.equal(await balanceOf(env, 'p2'), 0);
  assert.equal((await spendGem(env, 'p2', 1, 'x', 'k')).code, 'insufficient');
});

test('daily claim: 300, once per UTC day, capped at 900, at-cap does not burn the day', async () => {
  const env = mkEnv();
  const d = (n) => DAY + n * 86400 + 100;
  const c1 = await claimDaily(env, 'p1', d(0));
  assert.deepEqual([c1.ok, c1.granted, c1.balance], [true, 300, 300]);
  assert.equal((await claimDaily(env, 'p1', d(0) + 5000)).reason, 'already_claimed');
  assert.equal((await claimDaily(env, 'p1', d(1))).balance, 600);
  assert.equal((await claimDaily(env, 'p1', d(2))).balance, 900);
  const capped = await claimDaily(env, 'p1', d(3));
  assert.deepEqual([capped.ok, capped.reason], [false, 'at_cap']);
  await spendGem(env, 'p1', 90, 'aid:R1', 'spend1');
  const again = await claimDaily(env, 'p1', d(3) + 10); // same day as the at_cap answer
  assert.deepEqual([again.ok, again.granted, again.balance], [true, 90, 900]); // only the room, day now used
  assert.equal((await claimDaily(env, 'p1', d(3) + 20)).reason, 'already_claimed');
  assert.equal(c1.next_utc, DAY + 86400);
});

test('claim is parallel-safe: two simultaneous claims grant once', async () => {
  const env = mkEnv();
  const rs = await Promise.all([claimDaily(env, 'p1', DAY + 1), claimDaily(env, 'p1', DAY + 2)]);
  assert.equal(rs.filter((r) => r.ok).length, 1);
  assert.equal(await balanceOf(env, 'p1'), 300);
});

async function http(env, path, method = 'GET', token = 'tok') {
  return worker.fetch(new Request(`https://axiedice.fun${path}`, { method, headers: { cookie: `ad_session=${token}` } }), env);
}
test('endpoints: /api/wallet and /api/gem/claim need a session and report the ledger', async () => {
  const env = mkEnv();
  const hash = Buffer.from(await crypto.subtle.digest('SHA-256', new TextEncoder().encode('tok'))).toString('base64url');
  env.DB.db.prepare('INSERT INTO sessions (id_hash, player_id, created_at, expires_at) VALUES (?, ?, 1, 9999999999)').run(hash, 'p1');
  assert.equal((await http(env, '/api/wallet', 'GET', 'bad')).status, 401);
  const claim = await (await http(env, '/api/gem/claim', 'POST')).json();
  assert.equal(claim.granted, 300);
  const w = await (await http(env, '/api/wallet')).json();
  assert.equal(w.gem, 300);
  assert.equal(w.ledger_tail[0].reason, 'grant:playtest_grant');
  assert.equal((await (await http(env, '/api/gem/claim', 'POST')).json()).reason, 'already_claimed');
});

test('price table matches the client display table', { skip: !existsSync(new URL('../../godot/assets/data/economy/aid_prices.json', import.meta.url)) }, () => {
  const j = JSON.parse(readFileSync(new URL('../../godot/assets/data/economy/aid_prices.json', import.meta.url), 'utf8'));
  for (const id of Object.keys(PRICES)) {
    assert.equal(PRICES[id].price, j.aids[id].price, id);
    assert.equal(PRICES[id].cap_run, j.aids[id].cap_run ?? PRICES[id].cap_run, id);
  }
  assert.equal(totalCap(0), j.total_cap.a0_a8);
  assert.equal(totalCap(9), j.total_cap.a9_a10);
  assert.equal(GIFT.per_day, 300);
});

// ---- charging inside epoch_req (RunCore + real wallet)
const RUN = 'c'.repeat(32), NONCE = 'd'.repeat(32), RULES = 'godot-2026-09-21-a';
async function paidRun(gems, opts = {}) {
  const env = mkEnv();
  if (gems) await applyDelta(env, 'p1', gems, 'grant:test', 'seed');
  const core = new RunCore(fakeSql(), {
    now: () => 1, verifyToken: async () => ({ run_id: RUN, player_id: 'p1', rules_version: RULES }),
    charge: async (idem, aid, _a, meta) => (await spendGem(env, meta.player_id, PRICES[aid].price, `aid:${aid}`, idem)).ok,
  });
  await core.init({ run_id: RUN, player_id: 'p1', rules_version: RULES, client_nonce: NONCE, ...opts });
  const conn = { authed: false, epoch: 0 };
  await core.handle(conn, JSON.stringify({ t: 'hello', run_token: 'x', last_seq: 0 }));
  let seq = -1, len = 0, h = await chainStart(RUN);
  const ep = async (kind, args, actions = [], extra = {}) => {
    const nh = seq < 0 ? h : await chainNext(h, actions);
    const msg = { t: 'epoch_req', seq: seq + 1, kind, args, log_delta: actions, h: nh, log_len: len + actions.length, ...extra };
    const r = (await core.handle(conn, JSON.stringify(msg))).replies[0];
    if (r.t === 'epoch_res') { seq++; len = msg.log_len; h = nh; }
    return r;
  };
  await ep('run_start', { mode: 'short', ascension: 0 });
  await ep('node', { node_id: 'r1_c0' });
  return { env, ep, core };
}
const EN = { fn: 'enter_node', args: ['r1_c0', 'battle'] };

test('continue costs 90 Gem inside the request; too poor = refused and no seed, no charge', async () => {
  const poor = await paidRun(89);
  assert.equal((await poor.ep('continue', { node_id: 'r1_c0' }, [EN])).code, 'rejected');
  assert.equal(await balanceOf(poor.env, 'p1'), 89);
  const rich = await paidRun(200);
  const r = await rich.ep('continue', { node_id: 'r1_c0' }, [EN]);
  assert.equal(r.t, 'epoch_res');
  assert.equal(await balanceOf(rich.env, 'p1'), 110);
});

test('a resent paid request replays the answer and does not charge twice', async () => {
  const { env, core, ep } = await paidRun(200);
  const r = await ep('continue', { node_id: 'r1_c0' }, [EN]);
  assert.equal(r.t, 'epoch_res');
  assert.equal(await balanceOf(env, 'p1'), 110);
});

test('caps: R1 once per run, R2 four, total six; guests and missions never pay', async () => {
  const { ep, env } = await paidRun(2000);
  assert.equal((await ep('continue', { node_id: 'r1_c0' }, [EN])).t, 'epoch_res');
  assert.equal((await ep('continue', { node_id: 'r1_c0' }, [{ fn: 'continue', args: [] }])).code, 'rejected'); // R1 cap
  let ok = 0;
  let first = true;
  for (let k = 1; k <= 6; k++) {
    const acts = first ? [{ fn: 'continue', args: [] }] : [{ fn: 'reroll_dice', args: [[1], 0] }];
    first = false;
    const r = await ep('reroll', { turn: 1, k, source: 'aid', uids: [1] }, acts);
    if (r.t === 'epoch_res') ok++;
  }
  assert.equal(ok, 4); // R2 cap_run
  assert.equal(await balanceOf(env, 'p1'), 2000 - 90 - 4 * 15);
  const g = await paidRun(500, { is_guest: true });
  assert.equal((await g.ep('continue', { node_id: 'r1_c0' }, [EN])).code, 'rejected');
  assert.equal(await balanceOf(g.env, 'p1'), 500);
});

test('POST /api/wallet/spend: validates input, charges once per idem, 402 when poor', async () => {
  const env = mkEnv();
  const hash = Buffer.from(await crypto.subtle.digest('SHA-256', new TextEncoder().encode('tok'))).toString('base64url');
  env.DB.db.prepare('INSERT INTO sessions (id_hash, player_id, created_at, expires_at) VALUES (?, ?, 1, 9999999999)').run(hash, 'p1');
  await applyDelta(env, 'p1', 200, 'grant:test', 'g');
  const spend = (body) => worker.fetch(new Request('https://axiedice.fun/api/wallet/spend', { method: 'POST', headers: { cookie: 'ad_session=tok', 'content-type': 'application/json' }, body: JSON.stringify(body) }), env);
  assert.equal((await spend({ amount: -5, reason: 'x', idem: 'abcdefgh' })).status, 400);
  assert.equal((await spend({ amount: 5, reason: 'Bad Reason', idem: 'abcdefgh' })).status, 400);
  assert.equal((await spend({ amount: 5, reason: 'ticket', idem: 'short' })).status, 400);
  const a = await (await spend({ amount: 120, reason: 'ticket_bundle', idem: 'purchase_0001' })).json();
  assert.equal(a.balance, 80);
  const again = await (await spend({ amount: 120, reason: 'ticket_bundle', idem: 'purchase_0001' })).json();
  assert.deepEqual([again.ok, again.dup, again.balance], [true, true, 80]);
  const poor = await spend({ amount: 120, reason: 'ticket_bundle', idem: 'purchase_0002' });
  assert.equal(poor.status, 402);
  assert.equal((await poor.json()).balance, 80);
});

test('wallet endpoints are rate limited per player (limiter keyed by player id)', async () => {
  const env = mkEnv();
  const keys = [];
  env.SAVE_LIMITER = { limit: async ({ key }) => { keys.push(key); return { success: keys.length <= 2 }; } };
  const hash = Buffer.from(await crypto.subtle.digest('SHA-256', new TextEncoder().encode('tok'))).toString('base64url');
  env.DB.db.prepare('INSERT INTO sessions (id_hash, player_id, created_at, expires_at) VALUES (?, ?, 1, 9999999999)').run(hash, 'p1');
  assert.equal((await http(env, '/api/wallet')).status, 200);
  assert.equal((await http(env, '/api/gem/claim', 'POST')).status, 200);
  assert.equal((await http(env, '/api/wallet')).status, 429);
  assert.deepEqual([...new Set(keys)], ['w:p1']);
});

test('season gift: 90 per milestone, 2 per season, idempotent, new season pays again, bad input refused', async () => {
  const env = mkEnv();
  const a = await claimSeasonGift(env, 'p1', 's1', 1);
  assert.deepEqual([a.ok, a.granted, a.balance], [true, 90, 90]);
  const dup = await claimSeasonGift(env, 'p1', 's1', 1);
  assert.deepEqual([dup.ok, dup.reason, dup.balance], [false, 'already_claimed', 90]);
  assert.equal((await claimSeasonGift(env, 'p1', 's1', 2)).balance, 180);
  assert.equal((await claimSeasonGift(env, 'p1', 's1', 3)).reason, 'bad_request');
  assert.equal((await claimSeasonGift(env, 'p1', 'bad id!', 1)).reason, 'bad_request');
  assert.equal(await balanceOf(env, 'p1'), 180, 'never more than 2 x 90 per season');
  assert.equal((await claimSeasonGift(env, 'p1', 's2', 1)).balance, 270);
  assert.equal(await balanceOf(env, 'p2'), 0, 'other account untouched');
});
