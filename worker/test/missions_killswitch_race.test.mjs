// Review fixes (security-engineer 26/10): per-tier kill switch, two parallel buys = one escrow, and a check
// against the REAL missions.json that every tier carries a `rules` array (skips with a reason until lane N-C
// writes the 6-tier table; lane I turns the skip into a hard fail at the R1 merge).
import { test, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, readdirSync } from 'node:fs';
import { setup, useFixture } from './_mission_harness.mjs';

beforeEach(() => useFixture());
const err = async (r) => (await r.json()).error;

test('enabled:false in the table -> 403 tier_locked; missing flag = on', async () => {
  useFixture({ N1: { mode: 'short', ascension: 0, stake: 300, m_base: 2.0, m_scale: 1.0, rules: [], enabled: false } });
  const s = await setup();
  const r = await s.mission('N1');
  assert.equal(r.status, 403); assert.equal(await err(r), 'tier_locked');
  assert.equal(s.escrows(), 0);
  useFixture();
  assert.equal((await (await setup()).mission('N1')).status, 200);
});

test('MISSION_TIERS_OFF locks exactly the listed tiers, read at runtime', async () => {
  const s = await setup({ env: { MISSION_TIERS_OFF: 'N2, N5' } });
  await s.play('N1');
  assert.equal(await err(await s.mission('N2')), 'tier_locked');
  assert.equal((await s.mission('N1')).status, 200);           // not listed: still fine
  s.env.MISSION_TIERS_OFF = '';                                // lifted without a rebuild
  await s.close((await s.DB.db.prepare(`SELECT run_id FROM runs WHERE state='open'`).get()).run_id, 'lost');
  assert.equal((await s.mission('N2')).status, 200);
});

test('two parallel buys by one player: exactly one escrow and one stake row, the other is 409 run_open', async () => {
  const s = await setup();
  const rs = await Promise.all([s.mission('N1'), s.mission('N1')]);
  assert.deepEqual(rs.map((r) => r.status).sort(), [200, 409]);
  assert.equal(s.escrows(), 1);
  assert.deepEqual(s.shard().map((x) => x.delta), [-300]);
});

test('real missions.json: every tier has a rules array (skipped with a reason until N-C writes the table)', (t) => {
  const tbl = JSON.parse(readFileSync(new URL('../../godot/assets/data/economy/missions.json', import.meta.url), 'utf8'));
  const missing = Object.entries(tbl.tiers).filter(([, v]) => !Array.isArray(v.rules)).map(([k]) => k);
  if (missing.length) { t.skip(`missions.json has no rules array on ${missing.join(',')} yet (lane N-C): the Worker treats them as rules: []`); return; }
  assert.equal(Object.keys(tbl.tiers).length, 6);
  for (const v of Object.values(tbl.tiers)) assert.ok(v.rules.every((r) => /^M\d+$/.test(r)));
});

test('src/ never imports the test-only table hook', () => {
  for (const f of readdirSync(new URL('../src/', import.meta.url))) {
    if (f === 'missions.js') continue;
    assert.ok(!readFileSync(new URL(`../src/${f}`, import.meta.url), 'utf8').includes('_setTableForTest'), f);
  }
});
