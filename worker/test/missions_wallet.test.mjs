// N5: with ECON_SHARD_WALLET=1 a Mission stake is taken from the server Shard balance and the payout added back.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkEnv } from './_econ_harness.mjs';
import { escrowStatements, settleEscrow, _setTableForTest } from '../src/missions.js';

_setTableForTest({ payout_cap: 20000, tiers: { N1: { mode: 'short', ascension: 3, stake: 300, m_base: 2, m_scale: 1 } } });
const bal = (env) => (env.DB.db.prepare(`SELECT balance FROM wallets WHERE player_id='p1' AND currency='shard'`).get() || { balance: null }).balance;
const mkRun = (env, id) => env.DB.db.prepare(`INSERT INTO runs (run_id, player_id, mode, rules_version, state, created_at) VALUES (?, 'p1', 'mission', 'x', 'open', 1)`).run(id);
const open = (env, id) => env.DB.batch(escrowStatements(env, { runId: id, playerId: 'p1', tier: 'N1', stake: 300, mult: 2, at: 5 }));

test('flag on: stake is charged, win pays stake x mult once, short funds roll the escrow back', async () => {
  const env = { ...mkEnv(), ECON_SHARD_WALLET: '1' };
  env.DB.db.prepare(`INSERT INTO wallets VALUES ('p1','shard',500)`).run();
  mkRun(env, 'a'.repeat(32));
  await open(env, 'a'.repeat(32));
  assert.equal(bal(env), 200);
  await settleEscrow(env, 'a'.repeat(32), 'won'); await settleEscrow(env, 'a'.repeat(32), 'won');
  assert.equal(bal(env), 800, '200 + 600, paid once');
  env.DB.db.prepare(`UPDATE runs SET state = 'closed'`).run();
  mkRun(env, 'b'.repeat(32));
  env.DB.db.prepare(`UPDATE wallets SET balance = 100`).run();
  await assert.rejects(open(env, 'b'.repeat(32)));
  assert.equal(bal(env), 100); assert.equal(env.DB.db.prepare(`SELECT COUNT(*) n FROM mission_escrow WHERE run_id = ?`).get('b'.repeat(32)).n, 0);
});

test('flag off (default): wallets untouched, as in L1', async () => {
  const env = mkEnv();
  mkRun(env, 'c'.repeat(32));
  await open(env, 'c'.repeat(32));
  assert.equal(bal(env), null);
});
