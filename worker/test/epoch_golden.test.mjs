// Runs lane A's shared vectors (godot/tests/data/epoch_golden.json, copied to test/epoch_golden.json).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { canonKV, canonDelta, chainStart, chainNext, commitOf, epochSeed, rowTypeDigest, nodeRow, _bytes } from '../src/epoch_canon.js';

const g = JSON.parse(readFileSync(new URL('./epoch_golden.json', import.meta.url), 'utf8'));
const sRun = _bytes.fromHex(g.s_run_hex);

test('golden: commit and h0', async () => {
  assert.equal(await commitOf(g.run_id, sRun), g.commit);
  assert.equal(await chainStart(g.run_id), g.h0);
});

test('golden: action lines', () => {
  for (const l of g.action_lines) assert.equal(canonDelta([l.action]), l.canon);
});

test('golden: hash chain (h_n from raw h_{n-1})', async () => {
  let h = g.h0;
  for (const c of g.chain) {
    assert.equal(canonDelta(c.delta), c.canon);
    h = await chainNext(h, c.delta);
    assert.equal(h, c.h);
  }
});

test('golden: request canon and seeds (uids excluded)', async () => {
  for (const e of g.epochs) {
    const r = e.request;
    const { uids, ...args } = r.args;
    assert.equal(canonKV({ ...r, args }), e.canon);
    assert.equal(await epochSeed(sRun, r), e.seed);
  }
});

test('golden: invalid actions are refused', () => {
  for (const i of g.invalid) {
    if (i.kind === 'action') assert.throws(() => canonDelta([i.action]), i.why);
  }
});

test('golden: rowtype digests and node ids', async () => {
  for (const r of g.rowtypes) assert.equal(await rowTypeDigest(sRun, g.run_id, r.row), r.digest);
  for (const n of g.node_ids) assert.equal(nodeRow(n.id), n.row, n.id);
});
