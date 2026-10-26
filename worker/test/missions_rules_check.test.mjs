// N-W 1: the `rules` a client sends must equal the tier's fixed set; a wrong or empty set at N2+ is a 400 with a
// clear code, and nothing is written. Also: a mission run only takes the current rules version.
import { test, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { setup, useFixture, RULES, OLD_RULES } from './_mission_harness.mjs';

beforeEach(() => useFixture());
const err = async (r) => (await r.json()).error;

test('the exact rule set is accepted, in any order', async () => {
  const s = await setup();
  await s.play('N1');   // buys N1 with its empty set and wins it
  await s.play('N2');
  assert.equal((await s.mission('N3', { mission: { rules: ['M6', 'M5'] } })).status, 200);
});

test('N2+ with rules [] or no rules is refused 400 mission_rules_mismatch, no escrow, no shard row', async () => {
  const s = await setup();
  await s.play('N1');
  for (const rules of [[], undefined, null]) {
    const r = await s.mission('N2', { mission: { rules } });
    assert.equal(r.status, 400, String(rules));
    assert.equal(await err(r), 'mission_rules_mismatch');
  }
  assert.equal(s.escrows(), 1);                       // only N1's
  assert.deepEqual(s.shard().map((x) => x.delta), [-300, 600]);
});

test('wrong, extra, missing, duplicated or malformed rules are all refused', async () => {
  const s = await setup();
  await s.play('N1'); await s.play('N2');
  const cases = [['M5'], ['M5', 'M6', 'M7'], ['M5', 'M5'], ['M5', 'M7'], ['m5', 'm6'], [5, 6], 'M5,M6', { 0: 'M5', 1: 'M6' }, [['M5', 'M6']], ['M5', null]];
  for (const rules of cases) {
    const r = await s.mission('N3', { mission: { rules } });
    assert.equal(r.status, 400, JSON.stringify(rules));
    assert.equal(await err(r), 'mission_rules_mismatch', JSON.stringify(rules));
  }
  assert.equal(s.escrows(), 2);
});

test('N1 has an empty set: rules missing or [] pass, anything else is refused', async () => {
  const s = await setup();
  assert.equal((await s.mission('N1', { mission: { rules: undefined } })).status, 200);
  const t = await setup();
  assert.equal((await t.mission('N1', { mission: { rules: ['M6'] } })).status, 400);
});

test('rules of another tier do not pass (N2 with the N3 set)', async () => {
  const s = await setup();
  await s.play('N1');
  assert.equal(await err(await s.mission('N2', { mission: { rules: ['M5', 'M6'] } })), 'mission_rules_mismatch');
});

test('stake/ascension mismatches keep their own codes and come before the rules check', async () => {
  const s = await setup();
  assert.equal(await err(await s.mission('N2', { mission: { stake: 1, rules: [] } })), 'stake_mismatch');
  assert.equal(await err(await s.mission('N2', { ascension: 4, mission: { rules: [] } })), 'tier_mismatch');
});

test('a tier whose table entry has no rules array is not rules-checked (old A/B table)', async () => {
  useFixture({ N1: { mode: 'short', ascension: 0, stake: 300, m_base: 2.0, m_scale: 1.0 } });
  const s = await setup();
  assert.equal((await s.mission('N1', { mission: { rules: ['anything'] } })).status, 200);
});

test('no tier_locked any more: N6 can be bought once the chain is won', async () => {
  const s = await setup();
  for (const t of ['N1', 'N2', 'N3', 'N4', 'N5']) await s.play(t);
  const r = await s.mission('N6');
  assert.equal(r.status, 200);
});

test('mission run on an older (still supported) rules version: 409 mission_needs_update, nothing written', async () => {
  const s = await setup();
  const r = await s.mission('N1', { rules_version: OLD_RULES });
  assert.equal(r.status, 409);
  assert.equal(await err(r), 'mission_needs_update');
  assert.equal(s.escrows(), 0);
  assert.deepEqual(s.shard(), []);
  // a normal run on the same old version is still accepted (the -t window), and the current one works for missions
  assert.equal((await s.call('/api/run', { method: 'POST', body: { rules_version: OLD_RULES, kind: 'normal' } })).status, 200);
  const t = await setup();
  assert.equal((await t.mission('N1', { rules_version: RULES })).status, 200);
});

test('a version the Worker does not serve at all stays the generic 409 version', async () => {
  const s = await setup();
  assert.equal(await err(await s.mission('N1', { rules_version: 'godot-1999-01-01-z' })), 'version');
});
