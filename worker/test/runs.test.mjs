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
  async run() { const r = this.db.prepare(this.sql).run(...this.args); return { success: true, meta: { changes: Number(r.changes) } }; }
}
class FakeD1 {
  constructor() { this.db = new DatabaseSync(':memory:'); this.db.exec('PRAGMA foreign_keys = ON;'); this.db.exec(mig('0001_accounts.sql')); this.db.exec(mig('0002_runs.sql')); }
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

test('create: ranked and mission fail closed (403) unless ALLOW_GATED_MODES=1', async () => {
  const a = await setup();
  assert.equal((await create(a.call, { kind: 'ranked' })).status, 403);
  assert.equal((await create(a.call, { kind: 'mission' })).status, 403);
  assert.equal((await (await create(a.call, { kind: 'ranked' })).json()).error, 'not_available');
  const b = await setup({ env: { ALLOW_GATED_MODES: '1' } });
  assert.equal((await create(b.call, { kind: 'mission' })).status, 200);
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
