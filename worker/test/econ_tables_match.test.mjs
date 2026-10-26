// The unlock prices the server charges must equal the ones the client shows (ContentDB.UNLOCKS).
import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { UNLOCKS } from '../src/econ_tables.js';

test('unlock prices match godot/autoload/ContentDB.gd', () => {
  const src = readFileSync(new URL('../../godot/autoload/ContentDB.gd', import.meta.url), 'utf8');
  const block = src.slice(src.indexOf('const UNLOCKS := ['), src.indexOf('const UNLOCKS_WITHOUT_EFFECT'));
  const got = {};
  for (const m of block.matchAll(/"id": "(u_[a-z0-9]+)".*?"cost": (\d+)/g)) got[m[1]] = Number(m[2]);
  assert.deepEqual(got, UNLOCKS);
});
