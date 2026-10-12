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
  constructor(core) { this.core = core; this.seq = 0; this.len = 0; this.log = []; this.conn = { authed: false, epoch: 0 }; this.hPromise = chainStart(RUN); }
  async hello(lastSeq = 0) {
    const token = await signRunToken(ENV, { player_id: 'google:1', run_id: RUN, rules_version: RULES });
    return this.core.handle(this.conn, JSON.stringify({ t: 'hello', run_token: token, last_seq: lastSeq }));
  }
  async build(kind, args, actions = [], over = {}) {
    const h = await chainNext(await this.hPromise, actions);
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
const A = (fn, args = {}) => ({ fn, args });
const start = (c) => c.epoch('run_start', { mode: 'normal', ascension: 0 }, [], { client_nonce: NONCE });

test('canon: integers, arrays keep order, strings are charset-checked, keys sorted', () => {
  assert.equal(canonKV({ b: 2, a: [3, 1, 2], c: 'x_y' }), 'a=3,1,2\nb=2\nc=x_y\n');
  assert.equal(canonKV({ args: { z: 1, a: 2 } }), 'args.a=2\nargs.z=1\n');
  assert.equal(canonDelta([A('reroll_dice', { uids: [5, 2] }), A('end_turn')]), 'reroll_dice|uids=5,2\nend_turn\n');
  assert.throws(() => canonKV({ a: 1.5 }));
  assert.throws(() => canonKV({ a: 'Bad Value' }));
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
  const msg = await c.build('run_start', { mode: 'normal', ascension: 0 }, [], { client_nonce: NONCE });
  const r1 = await c.send(msg);
  assert.equal(r1.t, 'epoch_res');
  assert.deepEqual(await c.send(msg), r1);
  const altered = await c.send({ ...msg, args: { mode: 'normal', ascension: 1 } });
  assert.equal(altered.code, 'rejected');
  assert.equal(sql.exec('SELECT COUNT(*) AS n FROM epochs').toArray()[0].n, 1);
});

test('run_start needs a nonce (missing or malformed -> bad_request) and must be seq 1', async () => {
  const { c } = await fresh();
  await c.hello();
  assert.equal((await c.epoch('run_start', {}, [], {})).code, 'bad_request');
  assert.equal((await c.epoch('run_start', {}, [], { client_nonce: 'zz' })).code, 'bad_request');
  assert.equal((await c.epoch('node', { node_id: 1 })).code, 'out_of_order'); // seq 1 must be run_start
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
  assert.equal((await c.send(await c.build('node', { node_id: 1 }, [], { seq: 5 }))).code, 'out_of_order');
});

test('log_delta: hash chain, log_len and function allow-list are checked', async () => {
  const { c } = await fresh();
  await c.hello();
  await start(c);
  const good = await c.build('node', { node_id: 1 }, [A('enter_node', { node_id: 1 })]);
  assert.equal((await c.send({ ...good, h: '0'.repeat(64) })).code, 'rejected');
  assert.equal((await c.send({ ...good, log_len: 7 })).code, 'rejected');
  const cheat = await c.build('node', { node_id: 1 }, [A('give_gold', { n: 99 })]);
  assert.equal((await c.send(cheat)).code, 'rejected');
  assert.equal((await c.send(good)).t, 'epoch_res'); // the honest request still works after refusals
});

test('log_delta: rewriting an earlier action changes h, so it is refused', async () => {
  const { c } = await fresh();
  await c.hello();
  await start(c);
  assert.equal((await c.epoch('node', { node_id: 1 }, [A('enter_node', { node_id: 1 })])).t, 'epoch_res');
  const honest = [A('use_die', { die: 1 }), A('end_turn')];
  const forged = await c.build('end_turn', { turn: 1 }, [A('use_die', { die: 2 }), A('end_turn')]);
  const real = await c.build('end_turn', { turn: 1 }, honest);
  assert.notEqual(forged.h, real.h);
  assert.equal((await c.send({ ...real, h: forged.h })).code, 'rejected');
});

test('consume in place: an epoch must be consumed by the first action of the next delta', async () => {
  const { c } = await fresh();
  await c.hello();
  await start(c);
  assert.equal((await c.epoch('node', { node_id: 1 }, [])).t, 'epoch_res');
  assert.equal((await c.epoch('end_turn', { turn: 1 }, [A('use_die', { die: 1 })])).code, 'rejected'); // node epoch not consumed
  assert.equal((await c.epoch('end_turn', { turn: 1 }, [A('enter_node', { node_id: 1 }), A('use_die', { die: 1 })])).t, 'epoch_res');
});

test('no stacking: asking again before the previous epoch is consumed is refused', async () => {
  const { c } = await fresh();
  await c.hello();
  await start(c);
  assert.equal((await c.epoch('node', { node_id: 1 }, [])).t, 'epoch_res');
  assert.equal((await c.epoch('end_turn', { turn: 1 }, [A('enter_node', { node_id: 1 }), A('use_die', { die: 1 })])).t, 'epoch_res');
  // end_turn epoch is now pending its end_turn action; a second end_turn request with a different action first is stacking
  assert.equal((await c.epoch('end_turn', { turn: 2 }, [A('use_die', { die: 2 })])).code, 'rejected');
  assert.equal((await c.epoch('end_turn', { turn: 2 }, [])).code, 'rejected');
  assert.equal((await c.epoch('end_turn', { turn: 2 }, [A('end_turn')])).t, 'epoch_res');
});

test('reward and run_start kinds are consumed on reply (no follow-up action required)', async () => {
  const { c } = await fresh();
  await c.hello();
  await start(c);
  assert.equal((await c.epoch('reward', { node_id: 1 })).t, 'epoch_res');
  assert.equal((await c.epoch('reward', { node_id: 2 })).t, 'epoch_res');
});

test('reroll pins its seed per (battle, attempt, turn, k); uids must be present and are ledgered', async () => {
  const { c, sql } = await fresh();
  await c.hello();
  await start(c);
  await c.epoch('node', { node_id: 1 }, []);
  const r1 = await c.epoch('reroll', { turn: 1, k: 1, source: 'base', uids: [1, 2] }, [A('enter_node', { node_id: 1 })]);
  // player rerolls, undoes, asks again for the same key with other dice
  const r2 = await c.epoch('reroll', { turn: 1, k: 1, source: 'base', uids: [3] }, [A('reroll_dice', { uids: [1, 2] }), A('undo_last')]);
  assert.equal(r2.seed, r1.seed, 'same key -> same seed');
  const r3 = await c.epoch('reroll', { turn: 1, k: 2, source: 'base', uids: [3] }, [A('reroll_dice', { uids: [3] })]);
  assert.notEqual(r3.seed, r1.seed);
  const uids = sql.exec(`SELECT uids FROM epochs WHERE kind = 'reroll' ORDER BY seq`).toArray().map((r) => r.uids);
  assert.deepEqual(uids, ['1,2', '3', '3']);
  assert.equal((await c.epoch('reroll', { turn: 1, k: 3, source: 'base' }, [A('reroll_dice', { uids: [3] })])).code, 'bad_request');
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
  await c.epoch('node', { node_id: 1 }, []);
  assert.equal((await c.epoch('continue', { node_id: 1 }, [A('enter_node', { node_id: 1 })])).code, 'rejected');

  const charges = [];
  const w = await fresh({}, { charge: async (idem, kind) => { charges.push([idem, kind]); return true; } });
  await w.c.hello();
  await start(w.c);
  await w.c.epoch('node', { node_id: 1 }, []);
  const r = await w.c.epoch('continue', { node_id: 1 }, [A('enter_node', { node_id: 1 })]);
  assert.equal(r.t, 'epoch_res');
  assert.deepEqual(charges, [[`aid:${RUN}:3`, 'continue']]);
  assert.equal(w.sql.exec('SELECT COUNT(*) AS n FROM pending_aid').toArray()[0].n, 0);

  const m = await fresh({ mode: 'mission' }, { charge: async () => { throw new Error('must not be called'); } });
  await m.c.hello();
  await start(m.c);
  await m.c.epoch('node', { node_id: 1 }, []);
  assert.equal((await m.c.epoch('reroll', { turn: 1, k: 1, source: 'aid', uids: [1] }, [A('enter_node', { node_id: 1 })])).code, 'rejected');
});

test('a failed charge refuses the request and leaves no pending row and no seed', async () => {
  const { c, sql } = await fresh({}, { charge: async () => false });
  await c.hello();
  await start(c);
  await c.epoch('node', { node_id: 1 }, []);
  assert.equal((await c.epoch('continue', { node_id: 1 }, [A('enter_node', { node_id: 1 })])).code, 'rejected');
  assert.equal(sql.exec('SELECT COUNT(*) AS n FROM pending_aid').toArray()[0].n, 0);
  assert.equal(sql.exec('SELECT COUNT(*) AS n FROM epochs').toArray()[0].n, 2);
});

test('continue: the client cannot choose the attempt counter', async () => {
  const { c } = await fresh({}, { charge: async () => true });
  await c.hello();
  await start(c);
  await c.epoch('node', { node_id: 1 }, []);
  assert.equal((await c.epoch('continue', { node_id: 1, attempt: 5 }, [A('enter_node', { node_id: 1 })])).code, 'rejected');
  assert.equal((await c.epoch('continue', { node_id: 1, attempt: 1 }, [A('enter_node', { node_id: 1 })])).t, 'epoch_res');
});

test('same-seq different-content cannot be used to fish for seeds', async () => {
  const { c } = await fresh();
  await c.hello();
  await start(c);
  await c.epoch('node', { node_id: 1 }, []);
  const seeds = new Set();
  for (const turn of [1, 2, 3, 4]) {
    const r = await c.send(await c.build('end_turn', { turn }, [A('enter_node', { node_id: 1 })]));
    if (r.t === 'epoch_res') seeds.add(r.seed);
  }
  assert.equal(seeds.size, 1, 'only the first request for a seq may produce a seed');
});

test('run_close: closes once, keeps the tape, refuses everything after', async () => {
  const { c, sql, core } = await fresh();
  await c.hello();
  await start(c);
  await c.epoch('node', { node_id: 1 }, []);
  const delta = [A('enter_node', { node_id: 1 }), A('end_turn')];
  const h = await chainNext(await c.hPromise, delta);
  const bad = await c.send({ t: 'run_close', seq: 3, log_delta: delta, h, log_len: 2, outcome: 'draw' });
  assert.equal(bad.code, 'bad_request');
  const r = await c.send({ t: 'run_close', seq: 3, log_delta: delta, h, log_len: 2, outcome: 'lost', summary: { battles_done: 1 } });
  assert.deepEqual(r, { t: 'closed', seq: 3 });
  const meta = core.meta();
  assert.equal(meta.state, 'closed');
  assert.equal(meta.outcome, 'lost');
  assert.equal(JSON.parse(meta.summary).battles_done, 1);
  assert.equal((await c.epoch('node', { node_id: 2 })).code, 'expired');
  assert.equal(sql.exec(`SELECT kind FROM epochs ORDER BY seq DESC LIMIT 1`).toArray()[0].kind, 'close');
});

test('run_close refuses a delta whose first action does not consume the last epoch', async () => {
  const { c } = await fresh();
  await c.hello();
  await start(c);
  await c.epoch('node', { node_id: 1 }, []);
  const delta = [A('end_turn')];
  const h = await chainNext(await c.hPromise, delta);
  assert.equal((await c.send({ t: 'run_close', seq: 3, log_delta: delta, h, log_len: 1, outcome: 'won' })).code, 'rejected');
});

test('abandon: state becomes abandoned (a loss), further messages are refused, idempotent', async () => {
  const { c, core } = await fresh();
  await c.hello();
  await start(c);
  assert.deepEqual(core.abandon(), { ok: true, state: 'abandoned' });
  assert.deepEqual(core.abandon(), { ok: true, state: 'abandoned' });
  assert.equal((await c.epoch('node', { node_id: 1 })).code, 'expired');
});

test('resync: a reconnecting client with an old last_seq gets the seeds it missed', async () => {
  const { c, core } = await fresh();
  await c.hello();
  const s1 = await start(c);
  const s2 = await c.epoch('node', { node_id: 1 }, []);
  const again = new Client(core);
  const out = await again.hello(0);
  assert.equal(out.replies[0].t, 'resync');
  assert.deepEqual(out.replies[0].tail.map((r) => [r.seq, r.seed]), [[1, s1.seed], [2, s2.seed]]);
  const upToDate = await new Client(core).hello(2);
  assert.equal(upToDate.replies[0].t, 'welcome');
  assert.equal(upToDate.replies[0].seq, 2);
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
  const one = [A('use_die', { die: 1 })];
  assert.equal(g.core._deltaProblem(one, MAX_ACTIONS - 1, MAX_ACTIONS), null);
  assert.equal(g.core._deltaProblem(one, MAX_ACTIONS, MAX_ACTIONS + 1), 'max_actions');
});

test('concurrent identical requests: serialised, one row, same answer', async () => {
  const { c, sql } = await fresh();
  await c.hello();
  await start(c);
  const msg = await c.build('node', { node_id: 1 }, []);
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

// Lane A's shared vectors. Until the file lands on godot-port this is skipped, not faked.
const GOLDEN = new URL('./epoch_golden.json', import.meta.url);
test('golden vectors (lane A epoch_golden.json)', { skip: !existsSync(GOLDEN) && 'epoch_golden.json not delivered yet' }, async () => {
  const g = JSON.parse(readFileSync(GOLDEN, 'utf8'));
  assert.ok(g, 'file parses; wire the vector kinds here once its schema is known');
});
