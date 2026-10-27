// SR-V: shadow verify queue. Run from worker/:  node --test test/verify_queue.test.mjs
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';
import { readFileSync } from 'node:fs';
import { handleVerify, enqueueVerify, signVerify, checkResult, isVerifyPath } from '../src/verify_queue.js';

const KEY = 'test-key-not-a-secret';
const RUN = 'a'.repeat(32);
const NOW = 1_800_000_000;

/** Tiny D1 stand-in over node:sqlite, with the real migration. */
function fakeDb() {
  const db = new DatabaseSync(':memory:');
  db.exec(readFileSync(new URL('../migrations/0012_verify.sql', import.meta.url), 'utf8'));
  db.exec(`CREATE TABLE runs (run_id TEXT PRIMARY KEY, player_id TEXT, mode TEXT, state TEXT, created_at INTEGER, battles_done INTEGER DEFAULT 0);
    CREATE TABLE mission_escrow (run_id TEXT PRIMARY KEY, tier TEXT);
    CREATE TABLE unlocks (player_id TEXT, unlock_id TEXT, at INTEGER, PRIMARY KEY (player_id, unlock_id));`);
  return { raw: db, prepare(q) { return { bind(...b) { return {
    async first() { return db.prepare(q).get(...b) ?? null; },
    async all() { return { results: db.prepare(q).all(...b) }; },
    async run() { const r = db.prepare(q).run(...b); return { meta: { changes: Number(r.changes) } }; },
    _run() { const r = db.prepare(q).run(...b); return { meta: { changes: Number(r.changes) } }; },
  }; } }; },
  async batch(stmts) { return stmts.map((s) => s._run()); } };
}
const good = (over = {}) => ({ ok: true, reason: '', rules_version: 'godot-x', outcome: 'won', score: 100, nodes: 5, log_len: 50, ms: 20, ...over });

async function call(env, path, body, { ts = NOW, key = KEY } = {}) {
  const text = JSON.stringify(body);
  const sig = await signVerify(key, ts, 'POST', path, text);
  const req = new Request('https://x' + path, { method: 'POST', body: text, headers: { 'x-verify-ts': String(ts), 'x-verify-sig': sig } });
  return handleVerify(req, env, new URL(req.url), NOW);
}
async function queued(outcome = 'won') {
  const env = { DB: fakeDb(), VERIFY_SHADOW: '1', VERIFY_HMAC_KEY: KEY };
  assert.equal(await enqueueVerify(env, { run_id: RUN, rules_version: 'godot-x', outcome, payload: { header: {}, entries: [], tape: [] } }), true);
  return env;
}

test('paths', () => { assert.ok(isVerifyPath('/api/verify/next')); assert.ok(!isVerifyPath('/api/run')); });

test('shadow is off by default: enqueue writes nothing', async () => {
  const env = { DB: fakeDb() };
  assert.equal(await enqueueVerify(env, { run_id: RUN, rules_version: 'v', outcome: 'won', payload: {} }), false);
  assert.equal(env.DB.raw.prepare('SELECT COUNT(*) n FROM verify_queue').get().n, 0);
});

test('enqueue never throws and never touches the run outcome (DB error is swallowed)', async () => {
  const env = { VERIFY_SHADOW: '1', DB: { prepare() { throw new Error('boom'); } } };
  assert.equal(await enqueueVerify(env, { run_id: RUN, rules_version: 'v', outcome: 'won', payload: {} }), false);
});

test('oversized payload is recorded as error, not queued', async () => {
  const env = { DB: fakeDb(), VERIFY_SHADOW: '1' };
  await enqueueVerify(env, { run_id: RUN, rules_version: 'v', outcome: 'won', payload: { x: 'y'.repeat(1_000_001) } });
  assert.equal(env.DB.raw.prepare('SELECT state, reason FROM verify_queue').get().reason, 'payload_too_large');
});

test('no key configured: endpoints do not exist', async () => {
  const env = { DB: fakeDb() };
  const r = await handleVerify(new Request('https://x/api/verify/next', { method: 'POST', body: '{}' }), env, new URL('https://x/api/verify/next'), NOW);
  assert.equal(r.status, 404);
});

test('bad signature, wrong key, stale timestamp are all 401', async () => {
  const env = await queued();
  assert.equal((await call(env, '/api/verify/next', {}, { key: 'other' })).status, 401);
  assert.equal((await call(env, '/api/verify/next', {}, { ts: NOW - 500 })).status, 401);
  const req = new Request('https://x/api/verify/next', { method: 'POST', body: '{}', headers: { 'x-verify-ts': String(NOW), 'x-verify-sig': 'ab'.repeat(32) } });
  assert.equal((await handleVerify(req, env, new URL(req.url), NOW)).status, 401);
  // a signature for one body does not authorise another
  const sig = await signVerify(KEY, NOW, 'POST', '/api/verify/next', '{}');
  const req2 = new Request('https://x/api/verify/next', { method: 'POST', body: '{"a":1}', headers: { 'x-verify-ts': String(NOW), 'x-verify-sig': sig } });
  assert.equal((await handleVerify(req2, env, new URL(req2.url), NOW)).status, 401);
  assert.equal(env.DB.raw.prepare('SELECT attempts FROM verify_queue').get().attempts, 0, 'unsigned calls claim nothing');
});

test('claim then submit a good result: state ok; same outcome as the server', async () => {
  const env = await queued('won');
  const job = await (await call(env, '/api/verify/next', {})).json();
  assert.equal(job.job.run_id, RUN);
  assert.equal((await (await call(env, '/api/verify/next', {})).json()).job, null, 'leased job is not handed out twice');
  const res = await (await call(env, '/api/verify/result', { run_id: RUN, result: good() })).json();
  assert.equal(res.state, 'ok');
  assert.equal(env.DB.raw.prepare('SELECT payload_json FROM verify_queue').get().payload_json, null, 'payload dropped after the verdict');
});

test('different outcome = mismatch; could-not-judge = error', async () => {
  let env = await queued('lost');
  await call(env, '/api/verify/next', {});
  assert.equal((await (await call(env, '/api/verify/result', { run_id: RUN, result: good({ outcome: 'won' }) })).json()).state, 'mismatch');
  env = await queued('won');
  await call(env, '/api/verify/next', {});
  assert.equal((await (await call(env, '/api/verify/result', { run_id: RUN, result: good({ ok: false, reason: 'bad_header', outcome: 'rejected', score: 0 }) })).json()).state, 'error');
  env = await queued('won');
  await call(env, '/api/verify/next', {});
  assert.equal((await (await call(env, '/api/verify/result', { run_id: RUN, result: good({ ok: false, reason: 'action_rejected', outcome: 'rejected', score: 0 }) })).json()).state, 'mismatch');
});

test('result with the wrong schema is rejected and the job stays pending', async () => {
  const env = await queued();
  await call(env, '/api/verify/next', {});
  const bads = [
    { ...good(), extra: 1 }, (({ ms, ...r }) => r)(good()), good({ ok: 'yes' }), good({ score: -1 }), good({ score: 2_000_000 }),
    good({ ms: 1.5 }), good({ outcome: 'draw' }), good({ reason: 'x'.repeat(65), ok: false, outcome: 'rejected' }), good({ reason: 'DROP TABLE', ok: false, outcome: 'rejected' }),
    good({ ok: true, outcome: 'rejected' }), 'str', null, [],
  ];
  for (const r of bads) {
    const res = await call(env, '/api/verify/result', { run_id: RUN, result: r });
    assert.equal(res.status, 400, JSON.stringify(r));
  }
  assert.equal(env.DB.raw.prepare('SELECT state FROM verify_queue').get().state, 'pending');
  assert.equal(checkResult(good()), '');
});

test('result for an unclaimed or unknown run is refused', async () => {
  const env = await queued();
  assert.equal((await call(env, '/api/verify/result', { run_id: RUN, result: good() })).status, 409);
  assert.equal((await call(env, '/api/verify/result', { run_id: 'b'.repeat(32), result: good() })).status, 404);
});


test('judge: match, outcome and score mismatch, rejected, error', async () => {
  const { judge } = await import('../src/verify_queue.js');
  const job = { srv_outcome: 'won', rules_version: 'godot-x', client_score: 100 };
  assert.deepEqual(judge(good(), job), { state: 'ok', verdict: 'match' });
  assert.equal(judge(good({ score: 99 }), job).verdict, 'score_mismatch');
  assert.equal(judge(good({ outcome: 'lost' }), job).verdict, 'outcome_mismatch');
  assert.equal(judge(good({ score: 1 }), { ...job, client_score: null }).verdict, 'match', 'no client score = not compared');
  assert.equal(judge(good({ ok: false, reason: 'header_mismatch', outcome: 'rejected', score: 0 }), job).verdict, 'rejected');
  assert.equal(judge(good({ ok: false, reason: 'bad_header', outcome: 'rejected', score: 0 }), job).state, 'error');
});

test('result writes verify_results and touches no other table', async () => {
  const env = await queued('won');
  await call(env, '/api/verify/next', {});
  const out = await (await call(env, '/api/verify/result', { run_id: RUN, result: good({ score: 5 }) })).json();
  assert.equal(out.verdict, 'match');
  const r = env.DB.raw.prepare('SELECT verdict, v_score, kind FROM verify_results').get();
  assert.equal(r.verdict, 'match'); assert.equal(r.v_score, 5);
  assert.equal(env.DB.raw.prepare('SELECT COUNT(*) n FROM runs').get().n, 0);
});

async function signedGet(env, path, { key = KEY, ts = NOW } = {}) {
  const sig = await signVerify(key, ts, 'GET', path.split('?')[0], '');
  const req = new Request('https://x' + path, { headers: { 'x-verify-ts': String(ts), 'x-verify-sig': sig } });
  return handleVerify(req, env, new URL(req.url), NOW);
}

test('stats: signed GET only; counts and last mismatches', async () => {
  const env = await queued('won');
  await call(env, '/api/verify/next', {});
  await call(env, '/api/verify/result', { run_id: RUN, result: good({ outcome: 'lost' }) });
  assert.equal((await signedGet(env, '/api/verify/stats', { key: 'other' })).status, 401);
  const noKey = await handleVerify(new Request('https://x/api/verify/stats'), { DB: env.DB }, new URL('https://x/api/verify/stats'), NOW);
  assert.equal(noKey.status, 404);
  const post = await call(env, '/api/verify/stats', {});
  assert.equal(post.status, 405);
  const sres = await signedGet(env, '/api/verify/stats?n=5'); const st = await sres.json(); assert.equal(sres.status, 200, JSON.stringify(st));
  assert.deepEqual(st.queue, [{ state: 'mismatch', n: 1 }]);
  assert.equal(st.last_mismatches[0].run_id, RUN);
  assert.equal(st.last_mismatches[0].verdict, 'outcome_mismatch');
  assert.equal(st.last_mismatches[0].srv_outcome, 'won');
  assert.equal(st.last_mismatches[0].v_outcome, 'lost');
});
