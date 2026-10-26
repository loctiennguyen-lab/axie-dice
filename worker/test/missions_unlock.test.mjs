// N-W 2: winning tier N opens N+1 (mission_wins, migration 0010); GET /api/missions/unlocks; a tier that is not
// unlocked is refused 403 tier_not_unlocked. All six tiers are buyable once unlocked (no tier_locked).
import { test, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { setup, useFixture } from './_mission_harness.mjs';
import { settleEscrow, reconcileEscrows } from '../src/missions.js';

beforeEach(() => useFixture());
const err = async (r) => (await r.json()).error;
const wins = (DB, p = 'google:1') => DB.db.prepare('SELECT tier, COUNT(*) AS n FROM mission_wins WHERE player_id = ? GROUP BY tier ORDER BY tier').all(p).map((r) => [r.tier, r.n]);

test('only N1 is open for a new player; N2..N6 are 403 tier_not_unlocked with no escrow and no stake taken', async () => {
  const s = await setup();
  for (const t of ['N2', 'N3', 'N4', 'N5', 'N6']) {
    const r = await s.mission(t);
    assert.equal(r.status, 403, t);
    assert.equal(await err(r), 'tier_not_unlocked', t);
  }
  assert.equal(s.escrows(), 0);
  assert.deepEqual(s.shard(), []);
  const u = await s.unlocks();
  assert.deepEqual(Object.entries(u.tiers).map(([k, v]) => [k, v.unlocked]), [['N1', true], ['N2', false], ['N3', false], ['N4', false], ['N5', false], ['N6', false]]);
});

test('winning N(k) opens N(k+1) only: the whole chain N1..N6, one step at a time', async () => {
  const s = await setup();
  for (const [i, t] of ['N1', 'N2', 'N3', 'N4', 'N5'].entries()) {
    const next = `N${i + 2}`;
    assert.equal((await s.mission(next, { token: 'tok1' })).status, 403, `${next} before ${t}`);
    await s.play(t);
    assert.equal((await s.unlocks()).tiers[next].unlocked, true, `${next} after ${t}`);
    if (i < 4) assert.equal((await s.unlocks()).tiers[`N${i + 3}`].unlocked, false);   // N(k+2) still shut
  }
  const six = await s.mission('N6');
  assert.equal(six.status, 200);
});

test('skipping is impossible: a win at N1 does not open N3', async () => {
  const s = await setup();
  await s.play('N1');
  assert.equal(await err(await s.mission('N3')), 'tier_not_unlocked');
});

test('a loss, a refund, an abandon or an open run do not count as a win', async () => {
  const s = await setup();
  await s.play('N1', 'lost');
  await s.play('N1', 'refunded');
  const open = await (await s.mission('N1')).json();
  assert.equal(await err(await s.mission('N2')), 'tier_not_unlocked');   // an open N1 run is no win
  await s.call(`/api/run/${open.run_id}/abandon`, { method: 'POST' });
  assert.deepEqual(wins(s.DB), []);
  assert.equal(await err(await s.mission('N2')), 'tier_not_unlocked');
});

test('a win is counted once per run: repeated settle and reconcile never double it, and it needs the escrow to be won', async () => {
  const s = await setup();
  const id = await s.play('N1');
  await settleEscrow(s.env, id, 'won'); await settleEscrow(s.env, id, 'lost'); await reconcileEscrows(s.env, 'google:1');
  assert.deepEqual(wins(s.DB), [['N1', 1]]);
  assert.equal((await s.unlocks()).tiers.N1.wins, 1);
});

test('a win written by the reconcile path (close never settled) opens the next tier too', async () => {
  const s = await setup();
  const { run_id } = await (await s.mission('N1')).json();
  s.DB.db.prepare(`UPDATE runs SET state = 'closed', outcome = 'won', closed_at = 5 WHERE run_id = ?`).run(run_id);
  assert.equal((await s.unlocks()).tiers.N2.unlocked, false);   // not settled yet
  await s.escrow();                                             // GET /escrow reconciles
  assert.equal((await s.unlocks()).tiers.N2.unlocked, true);
});

test('unlocks are per player', async () => {
  const s = await setup();
  await s.play('N1');
  assert.equal((await s.mission('N2', { token: 'tok2' })).status, 403);
  assert.equal((await s.unlocks({ token: 'tok2' })).tiers.N2.unlocked, false);
  assert.equal((await s.mission('N2')).status, 200);
});

test('unlock_wins: a tier can ask for more than one win of the previous tier', async () => {
  useFixture({ N2: { mode: 'short', ascension: 1, stake: 500, m_base: 2.4, m_scale: 1.0, rules: ['M6'], unlock_wins: 2 } });
  const s = await setup();
  await s.play('N1');
  let u = (await s.unlocks()).tiers.N2;
  assert.deepEqual([u.unlocked, u.wins, u.needs], [false, 0, 2]);
  assert.equal((await s.unlocks()).tiers.N1.wins, 1);
  assert.equal(await err(await s.mission('N2')), 'tier_not_unlocked');
  await s.play('N1');
  assert.equal((await s.unlocks()).tiers.N2.unlocked, true);
  assert.equal((await s.mission('N2')).status, 200);
});

test('GET /api/missions/unlocks needs a session; other methods are 404', async () => {
  const s = await setup();
  assert.equal((await s.unlocks({ token: 'nope' })).error, 'unauthenticated');
  assert.equal((await s.call('/api/missions/unlocks', { method: 'POST', body: {} })).status, 404);
});

test('the win row is written in the settle batch: wins stay if the escrow is read later, and shard ledger is unaffected', async () => {
  const s = await setup();
  await s.play('N1');
  assert.deepEqual(s.shard().map((x) => x.delta), [-300, 600]);
  assert.deepEqual(wins(s.DB), [['N1', 1]]);
});
