// SR0: run_close sanity (WRITE-ONLY; it only catches the LAZY, it does NOT stop a faked win) + run token bound to a live login. Run from worker/:  node --test test/
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { DatabaseSync } from 'node:sqlite';
import { RunCore, CLOSE_SANITY } from '../src/run_core.js';
import { chainStart, chainNext } from '../src/epoch_canon.js';
import { signRunToken, verifyRunToken } from '../src/run_token.js';
import { helloAllowed } from '../src/run_do.js';

const RULES = 'godot-2026-09-21-a';
const RUN = 'c'.repeat(32);
const NONCE = 'd'.repeat(32);
const ENV = { RUN_TOKEN_KEY: 'k' };
const A = (fn, args = []) => ({ fn, args });

function fakeSql() {
  const db = new DatabaseSync(':memory:');
  return { exec(q, ...b) { const st = db.prepare(q); if (/^\s*select/i.test(q)) { const r = st.all(...b); return { toArray: () => r }; } if (/^\s*(insert|update|delete)/i.test(q)) { st.run(...b); return { toArray: () => [] }; } db.exec(q); return { toArray: () => [] }; } };
}

/** A run walking `rows` nodes (one per row, last = boss unless noBoss), spending `secs` seconds, then run_close with `outcome`. */
async function playAndClose({ mapMode = 'short', rows = 18, secs = 600, outcome = 'won', noBoss = false, padLog = 0, mode = 'normal', hook = null } = {}) {
  let t = 1_000_000;
  const events = [];
  const core = new RunCore(fakeSql(), { now: () => t, verifyToken: (tok) => verifyRunToken(ENV, tok), log: (e, d) => events.push([e, d]) });
  await core.init({ run_id: RUN, player_id: 'google:1', rules_version: RULES, mode });
  if (hook) hook(core);
  const conn = { authed: false, epoch: 0 };
  const token = await signRunToken(ENV, { player_id: 'google:1', run_id: RUN, rules_version: RULES });
  await core.handle(conn, JSON.stringify({ t: 'hello', run_token: token, last_seq: 0 }));
  let seq = 0, len = 0, h = await chainStart(RUN);
  let r = await core.handle(conn, JSON.stringify({ t: 'epoch_req', seq, kind: 'run_start', args: { mode: mapMode, ascension: 0 }, log_delta: [], h, log_len: 0, client_nonce: NONCE }));
  assert.equal(r.replies[0].t, 'epoch_res');
  for (let row = 1; row <= rows; row++) {
    const boss = row === rows && !noBoss;
    const delta = [A('enter_node', [`r${row}_c0`, boss ? 'boss' : 'battle'])];
    if (row === rows) for (let i = 0; i < padLog; i++) delta.push(A('end_turn'));
    h = await chainNext(h, delta); len += delta.length; seq += 1;
    r = await core.handle(conn, JSON.stringify({ t: 'epoch_req', seq, kind: 'node', args: { node_id: `r${row}_c0` }, log_delta: delta, h, log_len: len }));
    assert.equal(r.replies[0].t, 'epoch_res', JSON.stringify(r.replies[0]));
    // a node epoch is consumed by the next enter_node; the last one by the closing delta below
  }
  t += secs * 1000;
  const closing = [A('end_turn')];
  const h2 = await chainNext(h, [A('enter_node', [`r${rows}_c0`, 'x'])].slice(0, 0).concat(closing));
  // the final node epoch is consumed by enter_node: close with an enter_node-free delta is refused, so consume it properly
  const consume = [A('enter_node', ['r1_c1', 'battle'])];
  void h2;
  const hc = await chainNext(h, consume);
  const out = await core.handle(conn, JSON.stringify({ t: 'run_close', seq: seq + 1, outcome, log_delta: consume, h: hc, log_len: len + consume.length, summary: { battles_done: rows } }));
  return { core, out: out.replies[0], events };
}

test('a plausible won run passes the sanity check', async () => {
  const { core, out, events } = await playAndClose({ padLog: 30 });
  assert.equal(out.t, 'closed');
  const s = core.closeSanity();
  assert.equal(s.ok, true, JSON.stringify(s));
  assert.equal(s.map_mode, 'short');
  assert.equal(events.filter((e) => e[0] === 'close_sanity').length, 0);
});

test('"won" with no boss, too few nodes, no log and no time is marked, NOT turned into lost', async () => {
  const { core, out, events } = await playAndClose({ rows: 2, secs: 1, noBoss: true });
  assert.equal(out.t, 'closed', 'the close is still accepted');
  assert.equal(core.meta().outcome, 'won', 'outcome is untouched (write-only)');
  const s = core.closeSanity();
  assert.equal(s.ok, false);
  assert.deepEqual(s.fails.sort(), ['few_nodes', 'no_final_boss', 'short_log', 'too_fast']);
  const ev = events.find((e) => e[0] === 'close_sanity');
  assert.ok(ev && ev[1].fails.includes('too_fast'));
});

test('each check trips alone: speed, log length, final boss', async () => {
  assert.deepEqual((await playAndClose({ padLog: 30, secs: 5 })).core.closeSanity().fails, ['too_fast']);
  assert.deepEqual((await playAndClose({ padLog: 0 })).core.closeSanity().fails, ['short_log']);
  assert.deepEqual((await playAndClose({ padLog: 30, noBoss: true })).core.closeSanity().fails, ['no_final_boss']);
});

test('full mode needs the longer map (row 30), short boss at row 18 is not enough', async () => {
  const { core } = await playAndClose({ mapMode: 'full', rows: 18, padLog: 80, secs: 3000 });
  const s = core.closeSanity();
  assert.equal(s.final_row, 30);
  assert.ok(s.fails.includes('no_final_boss') && s.fails.includes('few_nodes') === false);
});

test('a lost run is never judged', async () => {
  const { core } = await playAndClose({ rows: 1, secs: 0, outcome: 'lost', noBoss: true });
  const s = core.closeSanity();
  assert.equal(s.ok, true);
  assert.equal(s.mode_checked, false);
});

test('closeSanity is null while the run is open', async () => {
  const core = new RunCore(fakeSql(), {});
  await core.init({ run_id: RUN, player_id: 'p', rules_version: RULES });
  assert.equal(core.closeSanity(), null);
});

test('thresholds stay low and documented (tune from logs before enforcing)', () => {
  assert.ok(CLOSE_SANITY.min_enter_ratio <= 0.5 && CLOSE_SANITY.min_secs_per_row <= 10);
});

test('a sanity check that THROWS never blocks the close: reply ok, outcome and summary untouched', async () => {
  const { core, out } = await playAndClose({ padLog: 30, hook: (c) => { c.closeSanity = () => { throw new Error('boom'); }; } });
  assert.equal(out.t, 'closed');
  assert.equal(core.meta().state, 'closed');
  assert.equal(core.meta().outcome, 'won');
  assert.equal(JSON.parse(core.meta().summary).battles_done, 18);
});

test('the D1 write-back survives a throwing sanity: same outcome row, no srv.sanity', async () => {
  const { RunDO } = await import('../src/run_do.js');
  const sockets = [];
  const ctx = { storage: { sql: fakeSql(), getAlarm: async () => null, setAlarm: async () => {} }, getWebSockets: () => sockets, acceptWebSocket: () => {} };
  const calls = [];
  const d = new RunDO(ctx, { DB: { prepare: (q) => ({ bind: (...a) => ({ run: async () => { calls.push([q, a]); return { meta: { changes: 1 } }; } }) }) } });
  await d.core.init({ run_id: RUN, player_id: 'p', rules_version: RULES });
  d.core.sql.exec(`UPDATE meta SET state = 'closed', outcome = 'won', summary = '{"battles_done":3}' WHERE id = 1`);
  d.core.closeSanity = () => { throw new Error('boom'); };
  await d._syncClosed();
  assert.equal(calls.length, 1);
  assert.equal(calls[0][1][0], 'won');
  assert.equal(JSON.parse(calls[0][1][3]).srv.sanity, undefined);
});

// ---------------------------------------------------------------- token bound to a live login

const mig = (f) => readFileSync(new URL(`../migrations/${f}`, import.meta.url), 'utf8');
function d1() {
  const db = new DatabaseSync(':memory:');
  for (const f of ['0001_accounts.sql', '0002_runs.sql', '0009_depth_stage.sql', '0005_token_revocation.sql', '0004_desktop_auth.sql']) db.exec(mig(f));
  db.exec(`INSERT INTO players (id, email, display_name, created_at, last_login_at) VALUES ('google:1','a@x','a',1,1)`);
  db.exec(`INSERT INTO runs (run_id, player_id, mode, rules_version, state, created_at, token_jti) VALUES ('${RUN}','google:1','normal','${RULES}','open',1,'j1')`);
  const stmt = (sql) => { let args = []; const o = { bind: (...a) => { args = a; return o; }, first: async () => db.prepare(sql).get(...args) ?? null }; return o; };
  return { db, prepare: stmt };
}
const claims = { player_id: 'google:1', run_id: RUN, jti: 'j1' };

test('hello needs a live login: no session = refused; cookie session or live device = allowed', async () => {
  const DB = d1();
  const env = { DB };
  assert.equal(await helloAllowed(env, claims, 100), false, 'token alone is not enough');
  DB.db.exec(`INSERT INTO sessions (id_hash, player_id, created_at, expires_at) VALUES ('h','google:1',1,500)`);
  assert.equal(await helloAllowed(env, claims, 100), true);
  assert.equal(await helloAllowed(env, claims, 501), false, 'expired session');
  DB.db.exec(`INSERT INTO device_sessions (id, player_id, label, refresh_hash, created_at, last_seen) VALUES ('d1','google:1','mac','r',1,1)`);
  assert.equal(await helloAllowed(env, claims, 501), true, 'desktop device');
  DB.db.exec(`UPDATE device_sessions SET revoked = 1`);
  assert.equal(await helloAllowed(env, claims, 501), false, 'revoked device');
});

test('logout (session row deleted) kills a token that is still inside its TTL; jti and lock still apply', async () => {
  const DB = d1();
  DB.db.exec(`INSERT INTO sessions (id_hash, player_id, created_at, expires_at) VALUES ('h','google:1',1,9999999999)`);
  const env = { DB };
  assert.equal(await helloAllowed(env, claims), true);
  assert.equal(await helloAllowed(env, { ...claims, jti: 'old' }), false, 'rotated jti');
  DB.db.exec(`UPDATE players SET locked_at = 5`);
  assert.equal(await helloAllowed(env, claims), false, 'locked');
  DB.db.exec(`UPDATE players SET locked_at = NULL`);
  DB.db.exec(`DELETE FROM sessions`);
  assert.equal(await helloAllowed(env, claims), false, 'logged out');
  assert.equal(await helloAllowed({}, claims), false, 'no DB fails closed');
});
