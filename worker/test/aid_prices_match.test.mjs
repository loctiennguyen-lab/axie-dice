// The client's display catalog (godot/assets/data/economy/aid_prices.json) must show the same numbers the
// server charges (worker/src/aid_prices.js). Checklist L1 B2.
import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { PRICES, totalCap, BOSS_CONTINUE_PRICE } from '../src/aid_prices.js';

const cfg = JSON.parse(readFileSync(new URL('../../godot/assets/data/economy/aid_prices.json', import.meta.url), 'utf8'));

test('per-aid price and cap_run match the server', () => {
  for (const [id, p] of Object.entries(PRICES)) {
    const c = cfg.aids[id];
    assert.ok(c, `client catalog has ${id}`);
    assert.equal(c.price, p.price, `${id} price`);
    // R5 is capped per pact in the client file (the server's cap_run 4 is only the abuse ceiling).
    if ('cap_run' in c) assert.equal(c.cap_run, p.cap_run, `${id} cap_run`);
    else assert.equal(id, 'R5');
  }
});

test('boss Continue price matches', () => {
  assert.equal(cfg.aids.R1.boss_price, BOSS_CONTINUE_PRICE);
});

test('total cap per run matches for every ascension', () => {
  for (let a = 0; a <= 10; a++) {
    const want = a >= cfg.total_cap_split_asc ? cfg.total_cap.a9_a10 : cfg.total_cap.a0_a8;
    assert.equal(totalCap(a), want, `A${a}`);
  }
});
