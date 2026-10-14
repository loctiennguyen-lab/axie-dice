// POST /api/run & co. against node:sqlite D1 (both migrations) and a fake RUN_DO backed by RunCore.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { DatabaseSync } from 'node:sqlite';
import worker from '../src/index.js';
import { RunCore } from '../src/run_core.js';
import { sweepPending, PENDING_TTL_S } from '../src/runs.js';

const RULES = 'godot-2026-09-21-a';
const mig = (f) => readFileSync(new URL(`../migrations/${f}`, import.meta.url), 'utf8');

class Stmt {
  constructor(db, sql) { this.db = db; this.sql = sql; this.args = []; }
  bind(...a) { this.args = a; return this; }
  async first() { return this.db.prepare(this.sql).get(...this.args) ?? null; }
  async all() { return { results: this.db.prepare(this.sql).all(...this.args) }; }
  async run() { const r = this.db.prepare(this.sql).run(...this.args); return { success: true, meta: { changes: Number(r.changes) } }; }
}
class FakeD1 {
  constructor() { this.db = new DatabaseSync(':memory:'); this.db.exec('PRAGMA foreign_keys = ON;'); this.db.exec(mig('0001_accounts.sql')); this.db.exec(mig('0002_runs.sql')); this.db.exec(mig('0005_token_revocation.sql')); this.db.exec(mig('0006_leaderboard.sql')); }
  prepare(s) { return new Stmt(this.db, s); }
  async batch(stmts) { const out = []; for (const s of stmts) out.push(await s.run()); return out; }
}

function fakeDoNamespace({ failInit = false } = {}) {
  const cores = new Map();
  return {
    cores,
    idFromName: (n) => n,
    get: (name) => ({
      async fetch(url, init) {
        const path = new URL(typeof url === 'string' ? url : url.url).pathname;
        if (failInit && path === '/init') throw new Error('boom');
        let core = cores.get(name);
        if (!core) {
          const db = new DatabaseSync(':memory:');
          const sql = { exec(q, ...b) { const st = db.prepare(q); if (/^\s*select/i.test(q)) { const r = st.all(...b); return { toArray: () => r }; } if (/^\s*(insert|update|delete)/i.test(q)) { st.run(...b); return { toArray: () => [] }; } db.exec(q); return { toArray: () => [] }; } };
          core = new RunCore(sql, { supportsRules: () => true });
          cores.set(name, core);
        }
        if (path === '/init') { const o = await core.init(JSON.parse(init.body)); return new Response(JSON.stringify(o), { status: o.ok ? 200 : 409 }); }
        if (path === '/abandon') return new Response(JSON.stringify(core.abandon()), { status: 200 });
        return new Response('{}', { status: 404 });
      },
    }),
  };
}

async function setup(extra = {}) {
  const DB = new FakeD1();
  const env = { DB, RUN_DO: fakeDoNamespace(extra.do), RUN_TOKEN_KEY: 'k', SESSION_SIGNING_KEY: 's', ...extra.env };
  const mk = async (id, token) => {
    DB.db.prepare('INSERT INTO players (id, email, display_name, created_at, last_login_at) VALUES (?, ?, ?, 1, 1)').run(id, `${id}@x`, id);
    const hash = Buffer.from(await crypto.subtle.digest('SHA-256', new TextEncoder().encode(token))).toString('base64url');
    DB.db.prepare('INSERT INTO sessions (id_hash, player_id, created_at, expires_at) VALUES (?, ?, 1, 9999999999)').run(hash, id);
  };
  await mk('google:1', 'tok1');
  await mk('google:2', 'tok2');
  const call = (path, { method = 'GET', body, token = 'tok1' } = {}) =>
    worker.fetch(new Request(`https://axiedice.fun${path}`, {
      method, headers: { cookie: `ad_session=${token}`, 'content-type': 'application/json' },
      body: body === undefined ? undefined : typeof body === 'string' ? body : JSON.stringify(body),
    }), env);
  return { DB, env, call };
}
const create = (call, over = {}, opts) => call('/api/run', { method: 'POST', body: { rules_version: RULES, ...over }, ...opts });

test('create: returns token+commit, second create is 409, open returns the same commit, abandon frees the slot', async () => {
  const { call } = await setup();
  const r = await create(call);
  assert.equal(r.status, 200);
  const j = await r.json();
  assert.match(j.run_id, /^[a-f0-9]{32}$/);
  assert.ok(j.run_token && j.commit && j.ws_url.endsWith(`/api/run/${j.run_id}/ws`));
  assert.equal((await create(call)).status, 409);
  const open = await (await call('/api/run/open')).json();
  assert.equal(open.run_id, j.run_id);
  assert.equal(open.commit, j.commit);
  assert.equal((await call(`/api/run/${j.run_id}/abandon`, { method: 'POST' })).status, 200);
  assert.equal((await create(call)).status, 200);
});

test('create: unauthenticated 401, null body 400, bad mode 400, unsupported rules 409', async () => {
  const { call } = await setup();
  assert.equal((await create(call, {}, { token: 'nope' })).status, 401);
  assert.equal((await call('/api/run', { method: 'POST', body: 'null' })).status, 400);
  assert.equal((await create(call, { kind: 'cheat' })).status, 400);
  assert.equal((await create(call, { rules_version: 'ancient' })).status, 409);
});

test('create: mission fails closed (403) unless ALLOW_GATED_MODES=1; ranked is open but newcomer-gated', async () => {
  const a = await setup();
  assert.equal((await create(a.call, { kind: 'mission' })).status, 403);
  assert.equal((await (await create(a.call, { kind: 'mission' })).json()).error, 'not_available');
  const r = await create(a.call, { kind: 'ranked' });
  assert.equal(r.status, 403);
  assert.equal((await r.json()).error, 'newcomer_locked');
  const b = await setup({ env: { ALLOW_GATED_MODES: '1' } });
  assert.equal((await create(b.call, { kind: 'mission' })).status, 200);
});

const seedRuns = (DB, n, over = {}) => {
  for (let i = 0; i < n; i++) {
    DB.db.prepare(`INSERT INTO runs (run_id, player_id, mode, ascension, rules_version, state, created_at, closed_at, outcome, battles_done, summary_json)
      VALUES (?, ?, ?, 0, ?, 'closed', 1, 2, 'lost', 1, ?)`)
      .run(`${over.tag || 'a'}${i}`.padStart(32, 'a'), over.player || 'google:1', over.kind || 'normal', RULES, over.summary || '{}');
  }
};

test('ranked: after 5 runs with a fight it opens; a vault Axie is refused; bad team_keys 400', async () => {
  const { call, DB } = await setup();
  seedRuns(DB, 4, { tag: 'b' });
  assert.equal((await (await create(call, { kind: 'ranked' })).json()).error, 'newcomer_locked');
  seedRuns(DB, 1, { tag: 'c' });
  assert.equal((await (await create(call, { kind: 'ranked', team_keys: ['axie_a', 'vault_12'] })).json()).error, 'vault_banned');
  assert.equal((await create(call, { kind: 'ranked', team_keys: 'x' })).status, 400);
  const ok = await create(call, { kind: 'ranked', team_keys: ['a', 'b', 'c', 'd', 'e'] });
  assert.equal(ok.status, 200);
  assert.equal((await ok.json()).header.newcomer, false);
});

test('daily: 3 tries per UTC day, abandoned count, 4th is 429 daily_tries; /api/run/daily reports it', async () => {
  const { call } = await setup();
  assert.deepEqual((({ used, max }) => ({ used, max }))(await (await call('/api/run/daily')).json()), { used: 0, max: 3 });
  for (let i = 0; i < 3; i++) {
    const j = await (await create(call, { kind: 'daily' })).json();
    assert.ok(j.run_id);
    await call(`/api/run/${j.run_id}/abandon`, { method: 'POST' });
  }
  const d = await (await call('/api/run/daily')).json();
  assert.equal(d.used, 3);
  assert.ok(d.resets_at > Math.floor(Date.now() / 1000));
  const r = await create(call, { kind: 'daily' });
  assert.equal(r.status, 429);
  assert.equal((await r.json()).error, 'daily_tries');
  // normal runs are not blocked by it, and another player has their own tries
  assert.equal((await create(call)).status, 200);
  assert.equal((await create(call, { kind: 'daily' }, { token: 'tok2' })).status, 200);
});

test('daily: infra_error run does not use a try', async () => {
  const { call, DB } = await setup();
  for (let i = 0; i < 3; i++) { const j = await (await create(call, { kind: 'daily' })).json(); await call(`/api/run/${j.run_id}/abandon`, { method: 'POST' }); }
  DB.db.prepare(`UPDATE runs SET state = 'infra_error' WHERE rowid = (SELECT MIN(rowid) FROM runs WHERE mode = 'daily')`).run();
  assert.equal((await create(call, { kind: 'daily' })).status, 200);
});

const closeRanked = (DB, id, player, { score, len = 'short', asc = 0, outcome = 'won', state = 'closed', mode = 'ranked', battles = 4 } = {}) => {
  DB.db.prepare(`INSERT INTO runs (run_id, player_id, mode, ascension, rules_version, state, created_at, closed_at, outcome, battles_done, summary_json)
    VALUES (?, ?, ?, ?, ?, ?, 1, ?, ?, ?, ?)`).run(id, player, mode, asc, RULES, state, Math.floor(Date.now() / 1000), state === 'closed' ? outcome : null, battles, JSON.stringify({ score, len }));
};
const submit = (call, run_id, opts) => call('/api/leaderboard/submit', { method: 'POST', body: { run_id }, ...opts });
const idN = (n) => String(n).padStart(32, 'e');

test('leaderboard submit: only a closed ranked run of the caller, idempotent, bounded score', async () => {
  const { call, DB } = await setup();
  closeRanked(DB, idN(1), 'google:1', { score: 300 });
  closeRanked(DB, idN(2), 'google:1', { score: 300, mode: 'normal' });
  closeRanked(DB, idN(3), 'google:1', { score: 300, state: 'abandoned' });
  closeRanked(DB, idN(4), 'google:1', { score: 99999 });
  closeRanked(DB, idN(5), 'google:1', { score: 300, battles: 0 });
  closeRanked(DB, idN(6), 'google:2', { score: 300 });
  assert.equal((await call('/api/leaderboard/submit', { method: 'POST', body: { run_id: idN(1) }, token: 'nope' })).status, 401);
  assert.equal((await submit(call, 'zz')).status, 400);
  assert.equal((await submit(call, idN(9))).status, 404);
  assert.equal((await submit(call, idN(6))).status, 404);              // someone else's run
  assert.equal((await submit(call, idN(2))).status, 403);              // not ranked
  assert.equal((await submit(call, idN(3))).status, 409);              // not closed
  assert.equal((await submit(call, idN(4))).status, 422);              // score out of bounds
  assert.equal((await submit(call, idN(5))).status, 422);              // no battles
  const ok = await (await submit(call, idN(1))).json();
  assert.deepEqual([ok.ok, ok.score, ok.rank, ok.season], [true, 300, 1, 'S1']);
  await submit(call, idN(1));
  assert.equal(DB.db.prepare('SELECT COUNT(*) AS n FROM leaderboard_scores').get().n, 1);
});

test('leaderboard read: best per player, ties share a rank, self rank, daily view, boards are split by mode/ascension', async () => {
  const { call, DB } = await setup();
  DB.db.prepare(`INSERT INTO players (id, email, display_name, created_at, last_login_at) VALUES ('google:3', 'c@x', 'Cara Long@x', 1, 1)`).run();
  const hash3 = Buffer.from(await crypto.subtle.digest('SHA-256', new TextEncoder().encode('tok3'))).toString('base64url');
  DB.db.prepare(`INSERT INTO sessions (id_hash, player_id, created_at, expires_at) VALUES (?, 'google:3', 1, 9999999999)`).run(hash3);
  closeRanked(DB, idN(1), 'google:1', { score: 400 });
  closeRanked(DB, idN(2), 'google:1', { score: 250 });
  closeRanked(DB, idN(3), 'google:2', { score: 400 });
  closeRanked(DB, idN(4), 'google:3', { score: 100 });
  closeRanked(DB, idN(5), 'google:3', { score: 700, len: 'full', asc: 3 });
  await submit(call, idN(1)); await submit(call, idN(2)); await submit(call, idN(3), { token: 'tok2' });
  await submit(call, idN(4), { token: 'tok3' }); await submit(call, idN(5), { token: 'tok3' });
  const b = await (await call('/api/leaderboard?board=season&mode=short&asc=0')).json();
  assert.deepEqual(b.entries.map((e) => [e.rank, e.score]), [[1, 400], [1, 400], [3, 100]]);
  assert.equal(b.entries[2].name, 'Cara');
  assert.equal(b.total, 3);
  assert.deepEqual(b.self, { rank: 1, score: 400 });
  const d = await (await call('/api/leaderboard?board=daily&mode=short&asc=0&limit=1')).json();
  assert.equal(d.entries.length, 1);
  assert.equal(d.day, new Date().toISOString().slice(0, 10));
  const f = await (await call('/api/leaderboard?mode=full&asc=3', { token: 'tok2' })).json();
  assert.deepEqual(f.entries.map((e) => e.score), [700]);
  assert.equal(f.self, null);
  assert.equal((await call('/api/leaderboard?asc=99')).status, 400);
});

test('daily cap counts neither mission nor infra_error runs', async () => {
  const { call, DB } = await setup({ env: { RUNS_PER_DAY: '2', ALLOW_GATED_MODES: '1' } });
  const abandon = async (j) => call(`/api/run/${j.run_id}/abandon`, { method: 'POST' });
  for (let i = 0; i < 2; i++) { const j = await (await create(call)).json(); await abandon(j); }
  const capped = await create(call);
  assert.equal(capped.status, 429);
  // a mission run is not capped
  assert.equal((await create(call, { kind: 'mission' })).status, 200);
  // infra_error runs do not count: turn one of the earlier runs into one and a slot reopens
  DB.db.prepare(`UPDATE runs SET state = 'abandoned' WHERE mode = 'mission'`).run();
  DB.db.prepare(`UPDATE runs SET state = 'infra_error' WHERE mode = 'normal' AND rowid = (SELECT MIN(rowid) FROM runs WHERE mode = 'normal')`).run();
  assert.equal((await create(call)).status, 200);
});

test('failed DO init marks infra_error and frees the slot', async () => {
  const { call, DB } = await setup({ do: { failInit: true } });
  assert.equal((await create(call)).status, 502);
  assert.equal(DB.db.prepare('SELECT state FROM runs').get().state, 'infra_error');
  assert.equal(DB.db.prepare(`SELECT COUNT(*) AS n FROM runs WHERE state IN ('pending','open')`).get().n, 0);
});

test('stuck pending: create sweeps the player own stale pending, abandon handles pending, cron sweeps all', async () => {
  const { call, DB, env } = await setup();
  const old = Math.floor(Date.now() / 1000) - PENDING_TTL_S - 10;
  const ins = (id, p, t) => DB.db.prepare(`INSERT INTO runs (run_id, player_id, mode, rules_version, state, created_at) VALUES (?, ?, 'normal', ?, 'pending', ?)`).run(id, p, RULES, t);
  ins('1'.repeat(32), 'google:1', old);
  assert.equal((await create(call)).status, 200); // stale pending did not block
  assert.equal(DB.db.prepare('SELECT state FROM runs WHERE run_id = ?').get('1'.repeat(32)).state, 'infra_error');

  const fresh = Math.floor(Date.now() / 1000);
  ins('2'.repeat(32), 'google:2', fresh);
  assert.equal((await call(`/api/run/${'2'.repeat(32)}/abandon`, { method: 'POST', token: 'tok2' })).status, 200);
  assert.equal(DB.db.prepare('SELECT state FROM runs WHERE run_id = ?').get('2'.repeat(32)).state, 'abandoned');

  ins('3'.repeat(32), 'google:2', old);
  assert.equal(await sweepPending(env), 1);
  assert.equal(DB.db.prepare('SELECT state FROM runs WHERE run_id = ?').get('3'.repeat(32)).state, 'infra_error');
  assert.equal(await sweepPending(env), 0);
  // the scheduled() handler is wired to the sweep
  ins('5'.repeat(32), 'google:2', old);
  let waited;
  await worker.scheduled({}, env, { waitUntil: (p) => { waited = p; } });
  assert.equal(await waited, 1);
});

test('token jti: create stores it, /api/run/open mints a new one (the old token is revoked)', async () => {
  const { call, DB } = await setup();
  const claimsOf = (t) => JSON.parse(Buffer.from(t.split('.')[0], 'base64url'));
  const j = await (await create(call)).json();
  const c1 = claimsOf(j.run_token);
  assert.ok(c1.jti && c1.kid);
  assert.equal(DB.db.prepare('SELECT token_jti FROM runs WHERE run_id = ?').get(j.run_id).token_jti, c1.jti);
  const o = await (await call('/api/run/open')).json();
  const c2 = claimsOf(o.run_token);
  assert.notEqual(c2.jti, c1.jti);
  assert.equal(DB.db.prepare('SELECT token_jti FROM runs WHERE run_id = ?').get(j.run_id).token_jti, c2.jti);
});
