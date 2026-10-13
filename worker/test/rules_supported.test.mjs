import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { rulesSupported, SUPPORTED_RULES } from '../src/run_do.js';

test('the Godot client current RULES_VERSION is accepted by the Worker', () => {
  const src = readFileSync(new URL('../../godot/scripts/core/action_log.gd', import.meta.url), 'utf8');
  const m = src.match(/^const RULES_VERSION := "([^"]+)"/m);
  assert.ok(m, 'RULES_VERSION not found in action_log.gd');
  assert.ok(SUPPORTED_RULES.has(m[1]), `Worker does not accept ${m[1]}: add it to SUPPORTED_RULE_VERSIONS in run_do.js`);
  assert.equal(rulesSupported({}, m[1]), true);
  assert.equal(rulesSupported({}, 'godot-0000-bogus'), false);
});
