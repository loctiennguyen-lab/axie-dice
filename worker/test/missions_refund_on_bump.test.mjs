// N-W 3: a mission stake is refunded when the run was created under older rules than the current ones, on BOTH
// paths: abandon() and reconcileEscrows (GET /escrow, cron sweep). A bump is simulated by rewriting
// runs.rules_version of a run created under the current rules.
import { test, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { setup, useFixture, OLD_RULES } from './_mission_harness.mjs';
import { sweepPending } from '../src/runs.js';
import { BUMP_STALE_S } from '../src/missions.js';

beforeEach(() => useFixture());
const bump = (s, id, ageS = BUMP_STALE_S + 3600) => s.DB.db.prepare('UPDATE runs SET rules_version = ?, created_at = ? WHERE run_id = ?').run(OLD_RULES, Math.floor(Date.now() / 1000) - ageS, id);   // default: a cold run
const start = async (s, tier = 'N1', opts) => (await (await s.mission(tier, opts)).json()).run_id;
const abandon = (s, id) => s.call(`/api/run/${id}/abandon`, { method: 'POST' });

test('abandon: run on current rules after a battle stays a loss (no free map reroll)', async () => {
  const s = await setup();
  const id = await start(s); s.enterBattle(id);
  await abandon(s, id);
  assert.equal(s.row(id).state, 'lost');
  assert.deepEqual(s.shard().map((x) => x.delta), [-300]);
});

test('abandon: run on older rules after a battle is refunded', async () => {
  const s = await setup();
  const id = await start(s); s.enterBattle(id); bump(s, id);
  assert.equal((await abandon(s, id)).status, 200);
  assert.equal(s.row(id).state, 'refunded'); assert.equal(s.row(id).payout, 300);
  assert.deepEqual(s.shard().map((x) => [x.delta, x.reason]), [[-300, 'mission_stake:N1'], [300, 'mission_refund']]);
  assert.equal(s.DB.db.prepare('SELECT state FROM runs WHERE run_id = ?').get(id).state, 'abandoned');
  await abandon(s, id);                                    // idempotent
  assert.equal(s.shard().length, 2);
});

test('reconcile via GET /escrow: an open run on older rules is refunded, one on current rules is left alone', async () => {
  const s = await setup();
  const old = await start(s); bump(s, old);
  const e = await s.escrow();
  assert.equal(e.open, null);
  assert.deepEqual(e.settled.map((x) => [x.run_id, x.state, x.payout]), [[old, 'refunded', 300]]);
  const t = await setup();
  const cur = await start(t);
  const f = await t.escrow();
  assert.equal(f.open.run_id, cur); assert.deepEqual(f.settled, []);
});

test('reconcile: an abandoned run whose settle failed is a refund on older rules, a loss on current rules', async () => {
  const s = await setup();
  const a = await start(s); s.enterBattle(a);
  s.DB.db.prepare(`UPDATE runs SET state = 'abandoned', outcome = 'lost', closed_at = 5 WHERE run_id = ?`).run(a);
  await s.escrow();
  assert.equal(s.row(a).state, 'lost');
  const t = await setup();
  const b = await start(t); bump(t, b);
  t.DB.db.prepare(`UPDATE runs SET state = 'abandoned', outcome = 'lost', closed_at = 5 WHERE run_id = ?`).run(b);
  await t.escrow();
  assert.equal(t.row(b).state, 'refunded');
  assert.deepEqual(t.shard().map((x) => x.delta), [-300, 300]);
});

test('reconcile: a run that really closed keeps its result on older rules (won pays, lost stays lost)', async () => {
  const s = await setup();
  const w = await start(s); bump(s, w);
  s.DB.db.prepare(`UPDATE runs SET state = 'closed', outcome = 'won', closed_at = 5 WHERE run_id = ?`).run(w);
  await s.escrow();
  assert.equal(s.row(w).state, 'won'); assert.equal(s.row(w).payout, 600);
  const t = await setup();
  const l = await start(t); bump(t, l);
  t.DB.db.prepare(`UPDATE runs SET state = 'closed', outcome = 'lost', closed_at = 5 WHERE run_id = ?`).run(l);
  await t.escrow();
  assert.equal(t.row(l).state, 'lost');
});

test('cron sweep (everyone) refunds older-rules open runs too, once', async () => {
  const s = await setup();
  const id = await start(s); bump(s, id);
  await sweepPending(s.env);
  await sweepPending(s.env);
  assert.equal(s.row(id).state, 'refunded');
  assert.deepEqual(s.shard().map((x) => x.delta), [-300, 300]);
});

test('a pending run on older rules is not touched by reconcile (creation is still in flight)', async () => {
  const s = await setup();
  const id = await start(s); bump(s, id);
  s.DB.db.prepare(`UPDATE runs SET state = 'pending' WHERE run_id = ?`).run(id);
  await s.escrow();
  assert.equal(s.row(id).state, 'open');
});

test('after the refund the player can start a mission run on current rules again', async () => {
  const s = await setup();
  const id = await start(s); bump(s, id);
  await s.escrow();                                        // refunds; the old run row is still open
  await abandon(s, id);                                    // client abandons the stale run
  assert.equal((await s.mission('N1')).status, 200);
});

test('infra_error and never-started refunds are unchanged', async () => {
  const s = await setup();
  const id = await start(s);                               // no epoch answered
  await abandon(s, id);
  assert.equal(s.row(id).state, 'refunded');
});

test('a LIVE older-rules run (young) is not refunded by reconcile or cron: it can still win and pay', async () => {
  const s = await setup();
  const id = await start(s); s.enterBattle(id); bump(s, id, 10 * 60);    // bumped 10 min after it started
  await s.escrow(); await sweepPending(s.env);
  assert.equal(s.row(id).state, 'open');
  await s.close(id, 'won');
  assert.equal(s.row(id).state, 'won'); assert.equal(s.row(id).payout, 600);
  assert.equal(s.DB.db.prepare('SELECT COUNT(*) AS n FROM mission_wins').get().n, 1);
});

test('the same run once it is cold (older than BUMP_STALE_S) is refunded by the sweep; abandon refunds at any age', async () => {
  const s = await setup();
  const id = await start(s); bump(s, id, BUMP_STALE_S + 60);
  await sweepPending(s.env);
  assert.equal(s.row(id).state, 'refunded');
  const t = await setup();
  const y = await start(t); t.enterBattle(y); bump(t, y, 60);
  await abandon(t, y);
  assert.equal(t.row(y).state, 'refunded');
});
