// Drift guard: runBonuses (verify_job.js) must give the committed fixture values. The Godot side
// (godot/tests/t_run_bonuses_fixture.gd) checks MetaState.run_bonuses against the SAME file.
import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { runBonuses } from '../src/verify_job.js';

const fx = JSON.parse(readFileSync(new URL('./fixtures/run_bonuses_cases.json', import.meta.url), 'utf8'));

test('fixture is non-trivial', () => {
  assert.ok(fx.cases.length >= 8);
  assert.ok(fx.cases.some((c) => c.unlocks.length === 0));
});

for (const c of fx.cases) {
  test(`runBonuses matches fixture for [${c.unlocks.join(',')}]`, () => {
    assert.deepEqual(runBonuses(c.unlocks), c.expected);
  });
}
