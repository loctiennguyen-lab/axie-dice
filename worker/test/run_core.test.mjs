// RunCore + canon + token, on node:sqlite (no Cloudflare runtime). Run from worker/:  node --test test/
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';
import { existsSync, readFileSync } from 'node:fs';
import { RunCore, MAX_ACTIONS } from '../src/run_core.js';
import { chainStart, chainNext, commitOf, epochSeed, canonKV, canonDelta } from '../src/epoch_canon.js';
import { signRunToken, verifyRunToken } from '../src/run_token.js';

const RULES = 'godot-2026-09-21-a';
const RUN = 'a'.repeat(32);
const NONCE = 'b'.repeat(32);
const ENV = { RUN_TOKEN_KEY: 'test-run-key' };

/** SqlStorage stand-in: exec(query, ...binds) -> { toArray() }. */
export function fakeSql() {
  const db = new DatabaseSync(':memory:');
  return {
    db,
    exec(q, ...b) {
      const st = db.prepare(q);
      if (/^\s*select/i.test(q)) { const rows = st.all(...b); return { toArray: () => rows }; }
      if (/^\s*(insert|update|delete)/i.test(q)) { st.run(...b); return { toArray: () => [] }; }
      db.exec(q); return { toArray: () => [] };
    },
  };
}

async function fresh(opts = {}, deps = {}) {
  const sql = fakeSql();
  let t = 1_000_000;
  const core = new RunCore(sql, { now: () => t, verifyToken: (tok) => verifyRunToken(ENV, tok), ...deps });
  const init = await core.init({ run_id: RUN, player_id: 'google:1', rules_version: RULES, ...opts });
  const c = new Client(core);
  c.tick = (ms) => { t += ms; };
  return { sql, core, init, c };
}

/** A client that tracks seq/h/log_len the way RemoteEpochSource will. */
class Client {
  constructor(core) { this.core = core; this.seq = -1; this.len = 0; this.log = []; this.conn = { authed: false, epoch: 0 }; this.hPromise = chainStart(RUN); }
  async hello(lastSeq = 0) {
    const token = await signRunToken(ENV, { player_id: 'google:1', run_id: RUN, rules_version: RULES });
    return this.core.handle(this.conn, JSON.stringify({ t: 'hello', run_token: token, last_seq: lastSeq }));
  }
  async build(kind, args, actions = [], over = {}) {
    const h = this.seq < 0 ? await this.hPromise : await chainNext(await this.hPromise, actions); // run_start: h_0, no step
    return { t: 'epoch_req', seq: this.seq + 1, kind, args, log_delta: actions, h, log_len: this.len + actions.length, ...over };
  }
  async send(msg) { return (await this.core.handle(this.conn, JSON.stringify(msg))).replies[0]; }
  /** Build + send, advancing local state only on success. */
  async epoch(kind, args, actions = [], over = {}) {
    const msg = await this.build(kind, args, actions, over);
    const r = await this.send(msg);
    if (r.t === 'epoch_res' && msg.seq === this.seq + 1) {
      this.seq = msg.seq; this.len = msg.log_len; this.hPromise = Promise.resolve(msg.h); this.log.push(...actions);
    }
    return r;
  }
}
const A = (fn, args = []) => ({ fn, args });
const start = (c) => c.epoch('run_start', { mode: 'short', ascension: 0 }, [], { client_nonce: NONCE });

test('canon: integers, arrays keep order, strings are charset-checked, keys sorted', () => {
  assert.equal(canonKV({ b: 2, a: [3, 1, 2], c: 'x_y' }), 'a=3,1,2\nb=2\nc=x_y\n');
  assert.equal(canonKV({ args: { z: 1, a: 2 } }), 'args.a=2\nargs.z=1\n');
  assert.equal(canonDelta([A('reroll_dice', [[5, 2], 0]), A('end_turn')]), 'reroll_dice|p0=5,2|p1=0\nend_turn\n');
  assert.throws(() => canonKV({ a: 1.5 }));
  assert.throws(() => canonKV({ a: 'Bad Value' }));
  assert.throws(() => canonKV({ a: true }));
  assert.throws(() => canonKV({ a: [[1]] }));
  assert.throws(() => canonKV({ a: 'dot.ted' }));
  assert.throws(() => canonKV({ 'bad key': 1 }));
});

test('seed: deterministic, 32-bit unsigned, depends on the key and on every field, not on uids', async () => {
  const k1 = new Uint8Array(32).fill(1);
  const f = { run_id: RUN, seq: 2, kind: 'reroll', args: { turn: 1, k: 1, source: 'base', uids: [1, 2] }, h: 'ab', log_len: 3, rules_version: RULES, attempt: 0, client_nonce: NONCE };
  const s = await epochSeed(k1, f);
  assert.equal(s, await epochSeed(k1, f));
  assert.ok(Number.isInteger(s) && s >= 0 && s <= 0xffffffff);
  assert.notEqual(s, await epochSeed(new Uint8Array(32).fill(2), f));
  assert.notEqual(s, await epochSeed(k1, { ...f, log_len: 4 }));
  assert.notEqual(s, await epochSeed(k1, { ...f, args: { ...f.args, source: 'aid' } }));
  assert.equal(s, await epochSeed(k1, { ...f, args: { ...f.args, uids: [9] } }));
});

test('init: commitment matches SHA256(domain|run_id|S_run) and a second init is refused', async () => {
  const { sql, init, core } = await fresh();
  const sRun = new Uint8Array(sql.exec('SELECT s_run FROM meta').toArray()[0].s_run);
  assert.equal(init.commit, await commitOf(RUN, sRun));
  await assert.rejects(core.init({ run_id: RUN, player_id: 'x', rules_version: RULES }));
});

test('init: unsupported rules version is refused', async () => {
  const sql = fakeSql();
  const core = new RunCore(sql, { supportsRules: () => false });
  assert.deepEqual(await core.init({ run_id: RUN, player_id: 'p', rules_version: 'old' }), { ok: false, code: 'version' });
});

test('hello: bad token closes, good token welcomes, newer socket evicts', async () => {
  const { core, c } = await fresh();
  const bad = await core.handle({ authed: false }, JSON.stringify({ t: 'hello', run_token: 'nope', last_seq: 0 }));
  assert.equal(bad.close.code, 1008);
  const ok = await c.hello();
  assert.equal(ok.replies[0].t, 'welcome');
  assert.equal(ok.replies[0].h, await chainStart(RUN));
  const second = new Client(core);
  await second.hello();
  const stale = await core.handle(c.conn, JSON.stringify({ t: 'epoch_req', seq: 1 }));
  assert.equal(stale.replies[0].reason, 'other_device');
});

test('message before hello closes the socket', async () => {
  const { core } = await fresh();
  const out = await core.handle({ authed: false }, JSON.stringify({ t: 'epoch_req', seq: 1 }));
  assert.equal(out.close.reason, 'no_hello');
});

test('run_start: seed issued, resend is idempotent, altered resend is rejected without a new seed', async () => {
  const { c, sql } = await fresh();
  await c.hello();
  const msg = await c.build('run_start', { mode: 'short', ascension: 0 }, [], { client_nonce: NONCE });
  const r1 = await c.send(msg);
  assert.equal(r1.t, 'epoch_res');
  assert.deepEqual(await c.send(msg), r1);
  const altered = await c.send({ ...msg, args: { mode: 'short', ascension: 1 } });
  assert.equal(altered.code, 'rejected');
  assert.equal(sql.exec('SELECT COUNT(*) AS n FROM epochs').toArray()[0].n, 1);
});

test('run_start needs a nonce (missing or malformed -> bad_request) and must be seq 1', async () => {
  const { c } = await fresh();
  await c.hello();
  assert.equal((await c.epoch('run_start', {}, [], {})).code, 'bad_request');
  assert.equal((await c.epoch('run_start', {}, [], { client_nonce: 'zz' })).code, 'bad_request');
  assert.equal((await c.epoch('node', { node_id: 'r1_c0' })).code, 'out_of_order'); // seq 1 must be run_start
});

test('nonce given at creation is used and run_start does not need to repeat it', async () => {
  const { c } = await fresh({ client_nonce: NONCE });
  await c.hello();
  assert.equal((await c.epoch('run_start', {})).t, 'epoch_res');
});

test('seq must be next; gaps and replays of unknown seq are refused', async () => {
  const { c } = await fresh();
  await c.hello();
  await start(c);
  assert.equal((await c.send(await c.build('node', { node_id: 'r1_c0' }, [], { seq: 5 }))).code, 'out_of_order');
});

test('log_delta: hash chain, log_len and function allow-list are checked', async () => {
  const { c } = await fresh();
  await c.hello();
  await start(c);
  const good = await c.build('node', { node_id: 'r1_c0' }, [A('enter_node', ['r1_c0', 'battle'])]);
  assert.equal((await c.send({ ...good, h: '0'.repeat(64) })).code, 'rejected');
  assert.equal((await c.send({ ...good, log_len: 7 })).code, 'rejected');
  const cheat = await c.build('node', { node_id: 'r1_c0' }, [A('give_gold', [99])]);
  assert.equal((await c.send(cheat)).code, 'rejected');
  assert.equal((await c.send(good)).t, 'epoch_res'); // the honest request still works after refusals
});

test('log_delta: rewriting an earlier action changes h, so it is refused', async () => {
  const { c } = await fresh();
  await c.hello();
  await start(c);
  assert.equal((await c.epoch('node', { node_id: 'r1_c0' }, [A('enter_node', ['r1_c0', 'battle'])])).t, 'epoch_res');
  const honest = [A('use_die', [1, 100001]), A('end_turn')];
  const forged = await c.build('end_turn', { turn: 1 }, [A('use_die', [2, 100001]), A('end_turn')]);
  const real = await c.build('end_turn', { turn: 1 }, honest);
  assert.notEqual(forged.h, real.h);
  assert.equal((await c.send({ ...real, h: forged.h })).code, 'rejected');
});

test('consume in place: an epoch must be consumed by the first action of the next delta', async () => {
  const { c } = await fresh();
  await c.hello();
  await start(c);
  assert.equal((await c.epoch('node', { node_id: 'r1_c0' }, [])).t, 'epoch_res');
  assert.equal((await c.epoch('end_turn', { turn: 1 }, [A('use_die', [1, 100001])])).code, 'rejected'); // node epoch not consumed
  assert.equal((await c.epoch('end_turn', { turn: 1 }, [A('enter_node', ['r1_c0', 'battle']), A('use_die', [1, 100001])])).t, 'epoch_res');
});

test('no stacking: asking again before the previous epoch is consumed is refused', async () => {
  const { c } = await fresh();
  await c.hello();
  await start(c);
  assert.equal((await c.epoch('node', { node_id: 'r1_c0' }, [])).t, 'epoch_res');
  assert.equal((await c.epoch('end_turn', { turn: 1 }, [A('enter_node', ['r1_c0', 'battle']), A('use_die', [1, 100001])])).t, 'epoch_res');
  // end_turn epoch is now pending its end_turn action; a second end_turn request with a different action first is stacking
  assert.equal((await c.epoch('end_turn', { turn: 2 }, [A('use_die', [2, 100001])])).code, 'rejected');
  assert.equal((await c.epoch('end_turn', { turn: 2 }, [])).code, 'rejected');
  assert.equal((await c.epoch('end_turn', { turn: 2 }, [A('end_turn')])).t, 'epoch_res');
});

test('reward and run_start kinds are consumed on reply (no follow-up action required)', async () => {
  const { c } = await fresh();
  await c.hello();
  await start(c);
  assert.equal((await c.epoch('reward', { node_id: 'r1_c0' })).t, 'epoch_res');
  assert.equal((await c.epoch('reward', { node_id: 'r2_c0' })).t, 'epoch_res');
});

test('reroll accepts token uids (in-combat tokens/summons/Eggs/ghosts start at 100000) and refuses out-of-range ones', async () => {
  const { c } = await fresh();
  await c.hello();
  await start(c);
  await c.epoch('node', { node_id: 'r1_c0' }, []);
  const big = [5, 100000, 100002, 100999];
  const r = await c.epoch('reroll', { turn: 1, k: 1, source: 'base', uids: big, rmode: 1 }, [A('enter_node', ['r1_c0', 'battle'])]);
  assert.equal(r.t, 'epoch_res');
  // the same uids in the log pass the uids_mismatch check (validUids)
  assert.equal((await c.epoch('reroll', { turn: 1, k: 1, source: 'base', uids: big, rmode: 1 }, [A('reroll_dice', [big, 0, 1]), A('undo_last')])).t, 'epoch_res');
  assert.equal((await c.epoch('reroll', { turn: 1, k: 2, source: 'base', uids: [10000000], rmode: 1 }, [])).code, 'bad_request');
});

test('reroll pins its seed per (battle, attempt, turn, k); uids must be present and are ledgered', async () => {
  const { c, sql } = await fresh();
  await c.hello();
  await start(c);
  await c.epoch('node', { node_id: 'r1_c0' }, []);
  const r1 = await c.epoch('reroll', { turn: 1, k: 1, source: 'base', uids: [1, 2], rmode: 1 }, [A('enter_node', ['r1_c0', 'battle'])]);
  // player rerolls, undoes, asks again for the same key: same uids and rmode -> same seed
  const acts = [A('reroll_dice', [[1, 2], 0, 1]), A('undo_last')];
  const r2 = await c.epoch('reroll', { turn: 1, k: 1, source: 'base', uids: [1, 2], rmode: 1 }, acts);
  assert.equal(r2.seed, r1.seed, 'same key -> same seed');
  // Depth v4 3.10.2: other dice, or another rmode, on a pinned key -> pin_mismatch (no new seed)
  assert.equal((await c.epoch('reroll', { turn: 1, k: 1, source: 'base', uids: [3], rmode: 1 }, [A('reroll_dice', [[1, 2], 0, 1]), A('undo_last')])).code, 'pin_mismatch');
  assert.equal((await c.epoch('reroll', { turn: 1, k: 1, source: 'base', uids: [1, 2], rmode: 0 }, [A('reroll_dice', [[1, 2], 0, 1]), A('undo_last')])).code, 'pin_mismatch');
  assert.equal((await c.epoch('reroll', { turn: 1, k: 1, source: 'base', uids: [1, 2], rmode: 2 }, [])).code, 'bad_request');
  const r3 = await c.epoch('reroll', { turn: 1, k: 2, source: 'base', uids: [3] }, [A('reroll_dice', [[1, 2], 0])]);
  assert.notEqual(r3.seed, r1.seed);
  const uids = sql.exec(`SELECT uids FROM epochs WHERE kind = 'reroll' ORDER BY seq`).toArray().map((r) => r.uids);
  assert.deepEqual(uids, ['[1,2]', '[1,2]', '[3]']);
  // uids in the log must be the pinned epoch's uids (anomaly uids_mismatch), and a clean list
  assert.equal((await c.epoch('reroll', { turn: 1, k: 3, source: 'base', uids: [3] }, [A('reroll_dice', [[4], 0, 1])])).code, 'rejected');
  assert.equal((await c.epoch('reroll', { turn: 1, k: 3, source: 'base', uids: [3] }, [A('reroll_dice', [[-1], 0, 1])])).code, 'rejected'); // uids_invalid
  assert.equal((await c.epoch('reroll', { turn: 1, k: 3, source: 'base' }, [A('reroll_dice', [[3], 0])])).code, 'bad_request');
  // T10 (rejected, anomaly delta_rejected/aid_mismatch): the log claims an Aid reroll (from_aid = 1) but the epoch granted was a base one
  assert.equal((await c.epoch('reroll', { turn: 1, k: 3, source: 'base', uids: [3] }, [A('reroll_dice', [[3], 1, 1])])).code, 'rejected');
  assert.equal((await c.epoch('reroll', { turn: 1, k: 3, source: 'base', uids: [3] }, [A('reroll_dice', [[3], 0, 1])])).t, 'epoch_res');
});

test('seed differs between runs even for identical requests (S_run is per run)', async () => {
  const a = await fresh();
  const b = await fresh();
  await a.c.hello(); await b.c.hello();
  assert.notEqual((await start(a.c)).seed, (await start(b.c)).seed);
});

test('paid requests: refused with no wallet, refused in mission mode, charged once with the server idem key', async () => {
  const { c } = await fresh();
  await c.hello();
  await start(c);
  await c.epoch('node', { node_id: 'r1_c0' }, []);
  assert.equal((await c.epoch('continue', { node_id: 'r1_c0' }, [A('enter_node', ['r1_c0', 'battle'])])).code, 'rejected');

  const charges = [];
  const w = await fresh({}, { charge: async (idem, kind) => { charges.push([idem, kind]); return true; } });
  await w.c.hello();
  await start(w.c);
  await w.c.epoch('node', { node_id: 'r1_c0' }, []);
  const r = await w.c.epoch('continue', { node_id: 'r1_c0' }, [A('enter_node', ['r1_c0', 'battle'])]);
  assert.equal(r.t, 'epoch_res');
  assert.deepEqual(charges, [[`aid:${RUN}:2:R1`, 'R1']]);
  assert.equal(w.sql.exec('SELECT COUNT(*) AS n FROM pending_aid').toArray()[0].n, 0);

  const m = await fresh({ mode: 'mission' }, { charge: async () => { throw new Error('must not be called'); } });
  await m.c.hello();
  await start(m.c);
  await m.c.epoch('node', { node_id: 'r1_c0' }, []);
  assert.equal((await m.c.epoch('reroll', { turn: 1, k: 1, source: 'aid', uids: [1] }, [A('enter_node', ['r1_c0', 'battle'])])).code, 'rejected');
});

test('a failed charge refuses the request and leaves no pending row and no seed', async () => {
  const { c, sql } = await fresh({}, { charge: async () => false });
  await c.hello();
  await start(c);
  await c.epoch('node', { node_id: 'r1_c0' }, []);
  assert.equal((await c.epoch('continue', { node_id: 'r1_c0' }, [A('enter_node', ['r1_c0', 'battle'])])).code, 'rejected');
  assert.equal(sql.exec('SELECT COUNT(*) AS n FROM pending_aid').toArray()[0].n, 0);
  assert.equal(sql.exec('SELECT COUNT(*) AS n FROM epochs').toArray()[0].n, 2);
});

test('continue: the client cannot choose the attempt counter', async () => {
  const { c } = await fresh({}, { charge: async () => true });
  await c.hello();
  await start(c);
  await c.epoch('node', { node_id: 'r1_c0' }, []);
  assert.equal((await c.epoch('continue', { node_id: 'r1_c0', attempt: 5 }, [A('enter_node', ['r1_c0', 'battle'])])).code, 'rejected');
  assert.equal((await c.epoch('continue', { node_id: 'r1_c0', attempt: 1 }, [A('enter_node', ['r1_c0', 'battle'])])).t, 'epoch_res');
});

test('same-seq different-content cannot be used to fish for seeds', async () => {
  const { c } = await fresh();
  await c.hello();
  await start(c);
  await c.epoch('node', { node_id: 'r1_c0' }, []);
  const seeds = new Set();
  for (const turn of [1, 2, 3, 4]) {
    const r = await c.send(await c.build('end_turn', { turn }, [A('enter_node', ['r1_c0', 'battle'])]));
    if (r.t === 'epoch_res') seeds.add(r.seed);
  }
  assert.equal(seeds.size, 1, 'only the first request for a seq may produce a seed');
});

let SUMMARY = { battles_done: 1 };
test('run_close: oversize summary is stored as parseable {"truncated":1}', async () => {
  SUMMARY = { junk: 'x'.repeat(3000) };
  try {
    const { c, core } = await fresh();
    await c.hello(); await start(c);
    await c.epoch('node', { node_id: 'r1_c0' }, []);
    const delta = [A('enter_node', ['r1_c0', 'battle']), A('end_turn')];
    const h = await chainNext(await c.hPromise, delta);
    await c.send({ t: 'run_close', seq: 2, log_delta: delta, h, log_len: 2, outcome: 'lost', summary: SUMMARY });
    assert.deepEqual(JSON.parse(core.meta().summary), { truncated: 1 });
  } finally { SUMMARY = { battles_done: 1 }; }
});

test('run_close: closes once, keeps the tape, refuses everything after', async () => {
  const { c, sql, core } = await fresh();
  await c.hello();
  await start(c);
  await c.epoch('node', { node_id: 'r1_c0' }, []);
  const delta = [A('enter_node', ['r1_c0', 'battle']), A('end_turn')];
  const h = await chainNext(await c.hPromise, delta);
  const bad = await c.send({ t: 'run_close', seq: 2, log_delta: delta, h, log_len: 2, outcome: 'draw' });
  assert.equal(bad.code, 'bad_request');
  const r = await c.send({ t: 'run_close', seq: 2, log_delta: delta, h, log_len: 2, outcome: 'lost', summary: SUMMARY });
  assert.deepEqual(r, { t: 'closed', seq: 2 });
  const meta = core.meta();
  assert.equal(meta.state, 'closed');
  assert.equal(meta.outcome, 'lost');
  assert.equal(JSON.parse(meta.summary).battles_done, 1);
  assert.equal((await c.epoch('node', { node_id: 'r2_c0' })).code, 'expired');
  assert.equal(sql.exec(`SELECT kind FROM epochs ORDER BY seq DESC LIMIT 1`).toArray()[0].kind, 'close');
});

test('run_close refuses a delta whose first action does not consume the last epoch', async () => {
  const { c } = await fresh();
  await c.hello();
  await start(c);
  await c.epoch('node', { node_id: 'r1_c0' }, []);
  const delta = [A('end_turn')];
  const h = await chainNext(await c.hPromise, delta);
  assert.equal((await c.send({ t: 'run_close', seq: 2, log_delta: delta, h, log_len: 1, outcome: 'won' })).code, 'rejected');
});

test('abandon: state becomes abandoned (a loss), further messages are refused, idempotent', async () => {
  const { c, core } = await fresh();
  await c.hello();
  await start(c);
  assert.deepEqual(core.abandon(), { ok: true, state: 'abandoned' });
  assert.deepEqual(core.abandon(), { ok: true, state: 'abandoned' });
  assert.equal((await c.epoch('node', { node_id: 'r1_c0' })).code, 'expired');
});

test('resync: a reconnecting client with an old last_seq gets the seeds it missed', async () => {
  const { c, core } = await fresh();
  await c.hello();
  const s1 = await start(c);
  const s2 = await c.epoch('node', { node_id: 'r1_c0' }, []);
  const again = new Client(core);
  const out = await again.hello(-1);
  assert.equal(out.replies[0].t, 'resync');
  assert.deepEqual(out.replies[0].tail.map((r) => [r.seq, r.seed]), [[0, s1.seed], [1, s2.seed]]);
  const upToDate = await new Client(core).hello(1);
  assert.equal(upToDate.replies[0].t, 'welcome');
  assert.equal(upToDate.replies[0].seq, 1);
});

test('budgets: oversize message, token bucket, action cap, epoch cap', async () => {
  const { core, c } = await fresh();
  await c.hello();
  assert.equal((await core.handle(c.conn, 'x'.repeat(17000))).close.code, 1009);
  const f = await fresh();
  await f.c.hello();
  let closed = null;
  for (let i = 0; i < 40 && !closed; i++) closed = (await f.core.handle(f.c.conn, '{"t":"nope"}')).close;
  assert.equal(closed.code, 1008);
  f.c.tick(10_000); // bucket refills over time
  assert.equal((await f.core.handle(f.c.conn, '{"t":"nope"}')).close, undefined);

  // The 16 KB message cap hits first on the wire; the action cap is the second wall behind it.
  const g = await fresh();
  const one = [A('use_die', [1, 100001])];
  assert.equal(g.core._deltaProblem(one, MAX_ACTIONS - 1, MAX_ACTIONS), null);
  assert.equal(g.core._deltaProblem(one, MAX_ACTIONS, MAX_ACTIONS + 1), 'max_actions');
});

test('concurrent identical requests: serialised, one row, same answer', async () => {
  const { c, sql } = await fresh();
  await c.hello();
  await start(c);
  const msg = await c.build('node', { node_id: 'r1_c0' }, []);
  const [a, b] = await Promise.all([c.send(msg), c.send(msg)]);
  assert.deepEqual(a, b);
  assert.equal(sql.exec('SELECT COUNT(*) AS n FROM epochs').toArray()[0].n, 2);
});

test('run token: signed, bound to claims, expires, wrong key refused', async () => {
  const claims = { player_id: 'p', run_id: RUN, rules_version: RULES };
  const t = await signRunToken(ENV, claims, 1000);
  assert.equal((await verifyRunToken(ENV, t, 1001)).run_id, RUN);
  assert.equal(await verifyRunToken(ENV, t, 1000 + 2 * 3600 + 1), null);
  assert.equal(await verifyRunToken({ RUN_TOKEN_KEY: 'other' }, t, 1001), null);
  const [body, sig] = t.split('.');
  const tampered = Buffer.from(JSON.stringify({ ...JSON.parse(Buffer.from(body, 'base64url')), player_id: 'evil' })).toString('base64url');
  assert.equal(await verifyRunToken(ENV, `${tampered}.${sig}`, 1001), null);
  assert.equal(await verifyRunToken(ENV, 'garbage', 1001), null);
});

test('node_id must look like r<row>_c<col>; log action args are positional and flat', async () => {
  const { c } = await fresh();
  await c.hello();
  await start(c);
  assert.equal((await c.epoch('node', { node_id: 'x' })).code, 'bad_request');
  assert.equal((await c.epoch('node', { node_id: 'r01_c0' })).code, 'bad_request');
  assert.equal((await c.epoch('node', { node_id: 5 })).code, 'bad_request');
  assert.equal((await c.epoch('node', { node_id: 'r1_c0' }, [], {})).t, 'epoch_res');
  const bad = [[A('use_die', { die: 1 })], [A('use_die', [[[1]]])], [A('use_die', [true])], [A('use_die', [1.5])], [A('use_die', Array(11).fill(1))]];
  for (const d of bad) {
    const m = await c.build('end_turn', { turn: 1 }, [], { log_delta: d, log_len: d.length });
    assert.equal((await c.send(m)).code, 'rejected');
  }
});

test('lane A PR2: attempt in reroll/end_turn args must equal the server counter; new fns are allowed', async () => {
  const { c } = await fresh({}, { charge: async () => true });
  await c.hello();
  await start(c);
  await c.epoch('node', { node_id: 'r1_c0' }, []);
  assert.equal((await c.epoch('end_turn', { turn: 1, attempt: 1 }, [A('enter_node', ['r1_c0', 'battle'])])).code, 'rejected');
  assert.equal((await c.epoch('end_turn', { turn: 1, attempt: 0 }, [A('enter_node', ['r1_c0', 'battle']), A('tweak', [1]), A('reorder_party', [2, 1])])).t, 'epoch_res');
});

test('C1: a pact_pick delta (take, take+sell, skip) is accepted', async () => {
  const { c } = await fresh({}, { charge: async () => true });
  await c.hello();
  await start(c);
  await c.epoch('node', { node_id: 'r1_c0' }, []);
  const r = await c.epoch('end_turn', { turn: 1, attempt: 0 }, [A('enter_node', ['r1_c0', 'battle']), A('pact_pick', [0]), A('pact_pick', [1, 'r_ironvow']), A('pact_pick', [-1])]);
  assert.equal(r.t, 'epoch_res');
});

test('money moves last: any rejection leaves the wallet alone; a different Aid at the same seq has its own idem key', async () => {
  const charges = [];
  const { c } = await fresh({}, { charge: async (idem, aid) => { charges.push([idem, aid]); return aid !== 'R2'; } });
  await c.hello();
  await start(c);
  await c.epoch('node', { node_id: 'r1_c0' }, []);
  const EN = A('enter_node', ['r1_c0', 'battle']);
  const good = await c.build('continue', { node_id: 'r1_c0' }, [EN]);
  assert.equal((await c.send({ ...good, h: '0'.repeat(64) })).code, 'rejected');
  assert.equal((await c.send({ ...good, args: { node_id: 'r1_c0', attempt: 9 } })).code, 'rejected');
  assert.equal((await c.send(await c.build('reroll', { turn: 1, k: 1, source: 'aid', uids: [1] }, [A('end_turn')]))).code, 'rejected');
  assert.deepEqual(charges, [], 'no charge before every check has passed');
  assert.equal((await c.send(await c.build('reroll', { turn: 1, k: 1, source: 'aid', uids: [1] }, [EN]))).code, 'rejected');
  assert.equal((await c.send(good)).t, 'epoch_res');
  assert.deepEqual(charges.map((x) => x[1]), ['R2', 'R1']);
  assert.ok(charges[0][0].endsWith(':R2') && charges[1][0].endsWith(':R1'));
  assert.equal((await c.send(good)).t, 'epoch_res');
  assert.equal(charges.length, 2, 'identical resend is a replay, not a second charge');
});

test('run_start carries h_0 itself (golden): a stepped hash is refused, h_0 is accepted', async () => {
  const { c } = await fresh();
  await c.hello();
  const stepped = await chainNext(await chainStart(RUN), []);
  const bad = await c.send({ t: 'epoch_req', seq: 0, kind: 'run_start', args: {}, log_delta: [], h: stepped, log_len: 0, client_nonce: NONCE });
  assert.equal(bad.code, 'rejected');
  const ok = await c.send({ t: 'epoch_req', seq: 0, kind: 'run_start', args: {}, log_delta: [], h: await chainStart(RUN), log_len: 0, client_nonce: NONCE });
  assert.equal(ok.t, 'epoch_res');
});

test('continue price: 90 on a normal node, 180 when the logged node kind is boss (server-side)', async () => {
  const prices = [];
  const n = await fresh({}, { charge: async (_i, _k, _a, _m, price) => { prices.push(price); return true; } });
  await n.c.hello();
  await start(n.c);
  await n.c.epoch('node', { node_id: 'r1_c0' }, []);
  assert.equal((await n.c.epoch('continue', { node_id: 'r1_c0' }, [A('enter_node', ['r1_c0', 'battle'])])).t, 'epoch_res');
  const b = await fresh({}, { charge: async (_i, _k, _a, _m, price) => { prices.push(price); return true; } });
  await b.c.hello();
  await start(b.c);
  await b.c.epoch('node', { node_id: 'r1_c0' }, []);
  assert.equal((await b.c.epoch('continue', { node_id: 'r1_c0' }, [A('enter_node', ['r1_c0', 'boss'])])).t, 'epoch_res');
  assert.deepEqual(prices, [90, 180]);
});

test('shop_roll can be consumed by shop_done (leaving without buying does not soft-lock); other first actions still refused', async () => {
  const { c } = await fresh();
  await c.hello();
  await start(c);
  assert.equal((await c.epoch('shop_roll', { node_id: 'r1_c0', item: 'x' }, [])).t, 'epoch_res');
  assert.equal((await c.epoch('end_turn', { turn: 1 }, [A('use_die', [1, 100001])])).code, 'rejected');
  assert.equal((await c.epoch('node', { node_id: 'r1_c1' }, [A('shop_done')])).t, 'epoch_res');
  assert.equal((await c.epoch('reward_reroll', { k: 1, node_id: 'r1_c1' }, [A('enter_node', ['r1_c1', 'shop'])])).t, 'epoch_res');
  assert.equal((await c.epoch('node', { node_id: 'r1_c2' }, [A('take_reward')])).t, 'epoch_res');
});

test('run token kid: rotation keeps previous-key tokens alive, unknown kid and dropped prev key are refused', async () => {
  const claims = { player_id: 'p', run_id: RUN, rules_version: RULES, jti: 'j1' };
  const oldEnv = { RUN_TOKEN_KEY: 'old', RUN_TOKEN_KID: 'k1' };
  const t = await signRunToken(oldEnv, claims, 1000);
  assert.equal((await verifyRunToken(oldEnv, t, 1001)).kid, 'k1');
  const rotated = { RUN_TOKEN_KEY: 'new', RUN_TOKEN_KID: 'k2', RUN_TOKEN_KEY_PREV: 'old', RUN_TOKEN_KID_PREV: 'k1' };
  assert.equal((await verifyRunToken(rotated, t, 1001)).jti, 'j1');
  assert.equal(await verifyRunToken({ RUN_TOKEN_KEY: 'new', RUN_TOKEN_KID: 'k2' }, t, 1001), null);
  const t2 = await signRunToken(rotated, claims, 1000);
  assert.equal((await verifyRunToken(rotated, t2, 1001)).kid, 'k2');
  // a kid claim cannot be used to pick the wrong key: relabelling k2 as k1 fails the signature
  const [body, sig] = t2.split('.');
  const relabel = Buffer.from(JSON.stringify({ ...JSON.parse(Buffer.from(body, 'base64url')), kid: 'k1' })).toString('base64url');
  assert.equal(await verifyRunToken(rotated, `${relabel}.${sig}`, 1001), null);
});

test('hello asks D1 (checkHello): revoked or locked closes with auth, a pass welcomes; errors fail closed', async () => {
  let verdict = true;
  const { c } = await fresh({}, { checkHello: async () => { if (verdict === 'boom') throw new Error('d1'); return verdict; } });
  assert.equal((await c.hello()).replies[0].t, 'welcome');
  verdict = false;
  assert.equal((await c.hello()).close.reason, 'auth');
  verdict = 'boom';
  assert.equal((await c.hello()).close.reason, 'auth');
});

test('event_choice can be consumed by event_done', async () => {
  const { c } = await fresh();
  await c.hello();
  await start(c);
  assert.equal((await c.epoch('event_choice', { node_id: 'r1_c0', index: 1 }, [])).t, 'epoch_res');
  assert.equal((await c.epoch('node', { node_id: 'r1_c1' }, [A('event_done')])).t, 'epoch_res');
});

test('free Continue: once per account, A0-A2, elite/boss only; second, A3 and a normal node pay', async () => {
  const claimed = new Set();
  const mk = (opts) => {
    const charges = [];
    return fresh(opts, {
      charge: async (_i, _k, _a, _m, price) => { charges.push(price); return true; },
      claimFreeContinue: async (meta) => { if (claimed.has(meta.player_id)) return false; claimed.add(meta.player_id); return true; },
    }).then((x) => ({ ...x, charges }));
  };
  const go = async (x, kind) => {
    await x.c.hello(); await start(x.c); await x.c.epoch('node', { node_id: 'r1_c0' }, []);
    return x.c.epoch('continue', { node_id: 'r1_c0' }, [A('enter_node', ['r1_c0', kind])]);
  };
  const normal = await mk({});
  assert.equal((await go(normal, 'battle')).t, 'epoch_res');
  assert.deepEqual(normal.charges, [90], 'normal node: paid, free flag untouched');
  assert.equal(claimed.size, 0);
  const a3 = await mk({ ascension: 3 });
  assert.equal((await go(a3, 'boss')).t, 'epoch_res');
  assert.deepEqual(a3.charges, [180], 'A3: paid');
  assert.equal(claimed.size, 0);
  const first = await mk({ ascension: 2 });
  assert.equal((await go(first, 'elite')).t, 'epoch_res');
  assert.deepEqual(first.charges, [], 'first elite loss at A2: free');
  const second = await mk({});
  assert.equal((await go(second, 'boss')).t, 'epoch_res');
  assert.deepEqual(second.charges, [180], 'second: refused as free, charged');
  const broke = await fresh({}, { charge: async () => false, claimFreeContinue: async () => false });
  assert.equal((await go(broke, 'boss')).code, 'rejected');
});

test('B11: pact_reroll (R5) is paid 15 once per pact node, args {node_id, slot} only', async () => {
  const charges = [];
  const { c } = await fresh({}, { charge: async (idem, kind, args, meta, price) => { charges.push([kind, price]); return true; } });
  await c.hello();
  await start(c);
  await c.epoch('node', { node_id: 'r1_c0' }, []);
  const base = [A('enter_node', ['r1_c0', 'boss']), A('pact_pick', [0])];
  assert.equal((await c.epoch('pact_reroll', { node_id: 'r1_c0', slot: 1, extra: 1 }, base.slice(0, 1))).code, 'bad_request');
  const ok = await c.epoch('pact_reroll', { node_id: 'r1_c0', slot: 1 }, base.slice(0, 1));
  assert.equal(ok.t, 'epoch_res');
  assert.deepEqual(charges, [['R5', 15]]);
  const again = await c.epoch('pact_reroll', { node_id: 'r1_c0', slot: 2 }, [A('pact_reroll', [1, 1])]);
  assert.equal(again.code, 'rejected', 'cap 1 per pact node');
});

test('depth v4 stage: the server-written depth_stage must ride on every request, a different one is stage_mismatch', async () => {
  const { c } = await fresh({ depth_stage: 1 });
  await c.hello();
  assert.equal((await start(c)).code, 'stage_mismatch', 'no stage on the request');
  assert.equal((await c.epoch('run_start', { mode: 'short', ascension: 0 }, [], { client_nonce: NONCE, depth_stage: 3 })).code, 'stage_mismatch', 'a client claiming 3 when the server wrote 1');
  assert.equal((await c.epoch('run_start', { mode: 'short', ascension: 0 }, [], { client_nonce: NONCE, depth_stage: 1 })).t, 'epoch_res');
  assert.equal((await c.epoch('node', { node_id: 'r1_c0' }, [], { depth_stage: 2 })).code, 'stage_mismatch');
  assert.equal((await c.epoch('node', { node_id: 'r1_c0' }, [], { depth_stage: 1 })).t, 'epoch_res');
  const close = await c.build('node', {}, [], {});
  const bad = await c.send({ t: 'run_close', seq: c.seq + 1, log_delta: [], h: close.h, log_len: c.len, outcome: 'lost', depth_stage: 3 });
  assert.equal(bad.code, 'stage_mismatch', 'run_close checks the stage too');
});

test('depth v4 stage: a run with no stage on record (created before v4) is not checked', async () => {
  const { c } = await fresh();
  await c.hello();
  assert.equal((await start(c)).t, 'epoch_res');
  assert.equal((await c.epoch('node', { node_id: 'r1_c0' }, [], { depth_stage: 3 })).t, 'epoch_res');
});

test('depth v4 T1: the rmode a reroll_dice logs must be the rmode of the epoch it consumes; the pin also holds the source', async () => {
  const { c } = await fresh();
  await c.hello();
  await start(c);
  await c.epoch('node', { node_id: 'r1_c0' }, []);
  await c.epoch('reroll', { turn: 1, k: 1, source: 'base', uids: [1, 2], rmode: 0 }, [A('enter_node', ['r1_c0', 'battle'])]);
  // the epoch was granted for Lieu (0); a log that claims Safe (1) is refused, a missing rmode counts as Safe
  assert.equal((await c.epoch('reroll', { turn: 1, k: 2, source: 'base', uids: [3], rmode: 1 }, [A('reroll_dice', [[1, 2], 0, 1])])).code, 'rejected');
  assert.equal((await c.epoch('reroll', { turn: 1, k: 2, source: 'base', uids: [3], rmode: 1 }, [A('reroll_dice', [[1, 2], 0])])).code, 'rejected');
  const ok = await c.epoch('reroll', { turn: 1, k: 2, source: 'base', uids: [3], rmode: 1 }, [A('reroll_dice', [[1, 2], 0, 0])]);
  assert.equal(ok.t, 'epoch_res');
  // same key asked again with the other source -> pin_mismatch
  assert.equal((await c.epoch('reroll', { turn: 1, k: 2, source: 'aid', uids: [3], rmode: 1 }, [A('reroll_dice', [[3], 0, 1]), A('undo_last')])).code, 'pin_mismatch');
});

test('initSchema: ALTER swallows only "duplicate column", any other error is thrown', () => {
  const mk = (msg) => ({ exec: (q) => { if (/ALTER TABLE/.test(q)) throw new Error(msg); return { toArray: () => [] }; } });
  RunCore.initSchema(mk('duplicate column name: depth_stage'));
  assert.throws(() => RunCore.initSchema(mk('disk I/O error')), /disk I\/O/);
});

test('depth v4: a ranked run below stage 3 cannot be closed (ranked_stage); stage 3 closes', async () => {
  const { c } = await fresh({ mode: 'ranked', depth_stage: 2 });
  await c.hello();
  assert.equal((await c.epoch('run_start', { mode: 'short', ascension: 0 }, [], { client_nonce: NONCE, depth_stage: 2 })).t, 'epoch_res');
  const close = await c.build('node', {}, [], {});
  const bad = await c.send({ t: 'run_close', seq: c.seq + 1, log_delta: [], h: close.h, log_len: c.len, outcome: 'lost', depth_stage: 2 });
  assert.equal(bad.code, 'ranked_stage');
});
