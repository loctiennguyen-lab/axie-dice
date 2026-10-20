// Raid R1 ghost: defence snapshot validation, opponents, start/finish, caps, points, badges, 4xx branches.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { DatabaseSync } from 'node:sqlite';
import worker from '../src/index.js';
import { validateTeam, validateSkin, badgeCrossed, BADGES, PER_GHOST_DAILY, DAILY_RAIDS, POINTS_WIN, POINTS_LOSS, MIN_FIGHT_S, CHALLENGE_TTL_S, OPEN_MAX, resultHash } from '../src/raid.js';

const mig = (f) => readFileSync(new URL(`../migrations/${f}`, import.meta.url), 'utf8');
class Stmt {
  constructor(db, sql) { this.db = db; this.sql = sql; this.args = []; }
  bind(...a) { this.args = a; return this; }
  async first() { return this.db.prepare(this.sql).get(...this.args) ?? null; }
  async all() { return { results: this.db.prepare(this.sql).all(...this.args) }; }
  async run() { const r = this.db.prepare(this.sql).run(...this.args); return { success: true, meta: { changes: Number(r.changes) } }; }
}
class FakeD1 {
  constructor() {
    this.db = new DatabaseSync(':memory:'); this.db.exec('PRAGMA foreign_keys = ON;');
    for (const f of ['0001_accounts.sql', '0008_raid.sql']) this.db.exec(mig(f));
  }
  prepare(s) { return new Stmt(this.db, s); }
}
const unit = (key = 'plant1', over = {}) => ({ key, cls: 'plant', hp: 20, die: Array.from({ length: 6 }, (_, i) => ({ type: i % 2 ? 'shield' : 'dmg', value: 3 + i, kw: i === 0 ? ['pierce'] : [] })), ...over });
const team = (n = 3) => Array.from({ length: n }, (_, i) => unit(`hero${i}`));

async function setup() {
  const DB = new FakeD1();
  const env = { DB, SESSION_SIGNING_KEY: 's' };
  for (const [id, token] of [['google:1', 'tok1'], ['google:2', 'tok2'], ['google:3', 'tok3']]) {
    DB.db.prepare('INSERT INTO players (id, email, display_name, created_at, last_login_at) VALUES (?, ?, ?, 1, 1)').run(id, `${id}@x`, `Name${id.slice(-1)} Last`);
    const hash = Buffer.from(await crypto.subtle.digest('SHA-256', new TextEncoder().encode(token))).toString('base64url');
    DB.db.prepare('INSERT INTO sessions (id_hash, player_id, created_at, expires_at) VALUES (?, ?, 1, 9999999999)').run(hash, id);
  }
  const call = (path, { method = 'GET', body, token = 'tok1', raw, headers } = {}) =>
    worker.fetch(new Request(`https://axiedice.fun${path}`, {
      method, headers: { cookie: `ad_session=${token}`, 'content-type': 'application/json', ...headers },
      body: raw !== undefined ? raw : body === undefined ? undefined : JSON.stringify(body),
    }), env);
  const defend = (token, over = {}) => call('/api/raid/defense', { method: 'POST', token, body: { team: team(), skin: { frame: 'f1' }, power_hint: 120, ...over } });
  const ghostOf = (pid) => DB.db.prepare('SELECT ghost_id FROM raid_defense WHERE player_id = ?').get(pid).ghost_id;
  const start = (gid, token = 'tok1') => call('/api/raid/start', { method: 'POST', token, body: { ghost_id: gid } });
  const age = (cid, secs) => DB.db.prepare('UPDATE raid_challenges SET created_at = created_at - ? WHERE challenge_id = ?').run(secs, cid);
  const H = 'a'.repeat(32);
  const finish = async (cid, over = {}, token = 'tok1') => {
    const row = DB.db.prepare('SELECT seed FROM raid_challenges WHERE challenge_id = ?').get(cid);
    const b = { challenge_id: cid, won: true, turns: 6, ...over };
    if (b.h === undefined) b.h = row ? await resultHash(cid, row.seed, b.won, b.turns) : H;
    return call('/api/raid/finish', { method: 'POST', token, body: b });
  };
  // start a challenge and make it old enough to finish
  const fight = async (gid, token = 'tok1') => { const r = await (await start(gid, token)).json(); age(r.challenge_id, MIN_FIGHT_S + 1); return r.challenge_id; };
  return { DB, env, call, defend, ghostOf, start, finish, fight, age };
}

test('validateTeam: accepts a clean team, drops unknown fields, refuses every bad shape', () => {
  const ok = validateTeam([{ ...unit(), evil: 'x' }]);
  assert.equal(ok.length, 1);
  assert.equal(ok[0].evil, undefined);
  for (const bad of [null, [], 'x', team(6), [unit('Bad Key')], [unit('k', { cls: 'dragon' })], [unit('k', { hp: 0 })], [unit('k', { hp: 1000 })], [unit('k', { hp: 1.5 })],
    [unit('k', { die: [] })], [{ ...unit(), die: unit().die.map((f, i) => (i ? f : { ...f, type: 'explode' })) }], [{ ...unit(), die: unit().die.slice(0, 5) }], [{ ...unit(), die: unit().die.map((f, i) => (i ? f : { ...f, value: 100 })) }],
    [{ ...unit(), die: unit().die.map((f, i) => (i ? f : { ...f, type: 'DMG' })) }], [{ ...unit(), die: unit().die.map((f, i) => (i ? f : { ...f, kw: ['a', 'b', 'c', 'd', 'e'] })) }],
    [{ ...unit(), die: unit().die.map((f, i) => (i ? f : { ...f, kw: [1] })) }], [[]], [null]]) assert.equal(validateTeam(bad), null, JSON.stringify(bad).slice(0, 60));
});

test('validateSkin and badgeCrossed', () => {
  assert.deepEqual(validateSkin(undefined), {});
  assert.deepEqual(validateSkin({ frame: 'f_1', junk: 1 }), { frame: 'f_1' });
  assert.equal(validateSkin({ frame: '<script>' }), null);
  assert.equal(validateSkin([]), null);
  assert.equal(validateSkin({ title: 5 }), null);
  assert.equal(badgeCrossed(0, 9), null);
  assert.equal(badgeCrossed(9, 10), 1);
  assert.equal(badgeCrossed(0, 400), 5);
  assert.equal(badgeCrossed(10, 12), null);
  assert.equal(BADGES.length, 5);
});

test('defense: needs login, validates, upserts and keeps the same ghost id', async () => {
  const { call, defend, DB, ghostOf } = await setup();
  assert.equal((await call('/api/raid/defense', { method: 'POST', token: 'nope', body: {} })).status, 401);
  assert.equal((await call('/api/raid/defense', { method: 'GET' })).status, 404);
  assert.equal((await defend('tok1', { team: [] })).status, 400);
  assert.equal((await defend('tok1', { power_hint: -1 })).status, 400);
  assert.equal((await defend('tok1', { skin: { frame: 'bad frame!' } })).status, 400);
  assert.equal((await call('/api/raid/defense', { method: 'POST', raw: 'not json' })).status, 400);
  assert.equal((await call('/api/raid/defense', { method: 'POST', raw: '[1]' })).status, 400);
  assert.equal((await call('/api/raid/defense', { method: 'POST', raw: JSON.stringify({ pad: 'x'.repeat(7000) }) })).status, 413);
  assert.equal((await call('/api/raid/defense', { method: 'POST', body: { team: team() }, headers: { Origin: 'https://evil.example' } })).status, 403);
  assert.equal(DB.db.prepare('SELECT COUNT(*) AS n FROM raid_defense').get().n, 0);
  const a = await (await defend('tok1')).json();
  assert.equal(a.ok, true); assert.match(a.ghost_id, /^[a-f0-9]{16}$/);
  const b = await (await defend('tok1', { power_hint: 300, team: team(5) })).json();
  assert.equal(b.ghost_id, a.ghost_id);
  const row = DB.db.prepare('SELECT * FROM raid_defense WHERE player_id = ?').get('google:1');
  assert.equal(row.power_hint, 300);
  assert.equal(JSON.parse(row.team_json).length, 5);
  assert.equal(ghostOf('google:1'), a.ghost_id);
});

test('opponents: excludes self, hides player ids, first name only', async () => {
  const { call, defend } = await setup();
  assert.deepEqual((await (await call('/api/raid/opponents')).json()).opponents, []);
  await defend('tok1'); await defend('tok2'); await defend('tok3');
  assert.equal((await call('/api/raid/opponents', { token: 'nope' })).status, 401);
  const r = await (await call('/api/raid/opponents')).json();
  assert.equal(r.opponents.length, 2);
  assert.equal(r.points, 0);
  const text = JSON.stringify(r);
  assert.ok(!text.includes('google:'));
  assert.ok(r.opponents.every((o) => /^Name[23]$/.test(o.name) && o.team.length === 3));
});

test('start: 404 unknown ghost, 403 own ghost, 400 bad id, returns snapshot + server seed, open-challenge cap', async () => {
  const { call, defend, ghostOf, start, DB } = await setup();
  await defend('tok1'); await defend('tok2');
  assert.equal((await start('0'.repeat(16))).status, 404);
  assert.equal((await start('zz')).status, 400);
  assert.equal((await start(ghostOf('google:1'))).status, 403);
  assert.equal((await start(ghostOf('google:2'), 'nope')).status, 401);
  const r = await (await start(ghostOf('google:2'))).json();
  assert.match(r.challenge_id, /^[a-f0-9]{32}$/);
  assert.ok(Number.isInteger(r.seed) && r.seed > 0);
  assert.equal(r.team.length, 3); assert.equal(r.name, 'Name2');
  for (let i = 1; i < OPEN_MAX; i++) assert.equal((await start(ghostOf('google:2'))).status, 200);
  assert.equal((await start(ghostOf('google:2'))).status, 429);
  assert.equal(DB.db.prepare("SELECT COUNT(*) AS n FROM raid_challenges WHERE state = 'open'").get().n, OPEN_MAX);
});

test('finish: result bounds, ownership, one-shot, too fast, expired', async () => {
  const { call, defend, ghostOf, start, finish, fight, age, DB } = await setup();
  await defend('tok2');
  const g = ghostOf('google:2');
  const cid = (await (await start(g)).json()).challenge_id;
  assert.equal((await finish(cid, {}, 'nope')).status, 401);
  assert.equal((await finish('xyz')).status, 400);
  assert.equal((await finish('0'.repeat(32))).status, 404);
  assert.equal((await finish(cid, { won: 'yes' })).status, 422);
  assert.equal((await finish(cid, { turns: 0 })).status, 422);
  assert.equal((await finish(cid, { turns: 999 })).status, 422);
  assert.equal((await finish(cid, { h: 'short' })).status, 422);
  assert.equal((await finish(cid)).status, 422);                       // too_fast
  assert.equal((await (await finish(cid)).json()).error, 'too_fast');
  assert.equal((await finish(cid, {}, 'tok3')).status, 403);           // someone else's challenge
  age(cid, MIN_FIGHT_S + 1);
  const ok = await (await finish(cid)).json();
  assert.deepEqual([ok.ok, ok.points, ok.counted, ok.total], [true, POINTS_WIN, true, POINTS_WIN]);
  const again = await finish(cid);
  assert.equal(again.status, 409);
  assert.equal((await again.json()).error, 'already_done');
  assert.equal(DB.db.prepare('SELECT points FROM raid_points WHERE player_id = ?').get('google:1').points, POINTS_WIN);
  // expired
  const c2 = (await (await start(g)).json()).challenge_id;
  age(c2, CHALLENGE_TTL_S + 5);
  const exp = await finish(c2);
  assert.equal(exp.status, 409);
  assert.equal((await exp.json()).error, 'expired');
  assert.equal((await call('/api/raid/opponents', { token: 'tok1' })).status, 200);
});

test('points: loss gives 1, win gives 3; per-ghost cap 3/day then no points but still playable', async () => {
  const { defend, ghostOf, finish, fight, DB } = await setup();
  await defend('tok2'); await defend('tok3');
  const g2 = ghostOf('google:2');
  const outcomes = [];
  for (let i = 0; i < PER_GHOST_DAILY + 2; i++) outcomes.push(await (await finish(await fight(g2), { won: i === 0 })).json());
  assert.deepEqual(outcomes.map((o) => o.points), [POINTS_WIN, POINTS_LOSS, POINTS_LOSS, 0, 0]);
  assert.equal(outcomes[3].counted, false); assert.equal(outcomes[3].reason, 'ghost_cap');
  assert.equal(outcomes[4].ok, true);
  assert.equal(outcomes[4].total, POINTS_WIN + 2 * POINTS_LOSS);
  // another ghost still counts
  const o = await (await finish(await fight(ghostOf('google:3')))).json();
  assert.equal(o.counted, true);
  assert.equal(DB.db.prepare('SELECT SUM(count) AS n FROM raid_daily').get().n, 4);
});

test('points: daily cap of 5 raids across ghosts, then 0 points with reason daily_cap', async () => {
  const { defend, ghostOf, finish, fight } = await setup();
  await defend('tok2'); await defend('tok3');
  const gs = [ghostOf('google:2'), ghostOf('google:3')];
  const res = [];
  for (let i = 0; i < DAILY_RAIDS + 2; i++) res.push(await (await finish(await fight(gs[i % 2]), { won: false })).json());
  // 2 ghosts x 3 = 6 slots but only 5 raids per day
  assert.deepEqual(res.map((r) => r.counted), [true, true, true, true, true, false, false]);
  assert.equal(res[5].reason, 'daily_cap');
  assert.equal(res[6].total, DAILY_RAIDS * POINTS_LOSS);
});

test('badge: returned only when a milestone is crossed', async () => {
  const { defend, ghostOf, finish, fight, DB } = await setup();
  await defend('tok2');
  DB.db.prepare('INSERT INTO raid_points (player_id, points) VALUES (?, ?)').run('google:1', BADGES[0] - 1);
  const r = await (await finish(await fight(ghostOf('google:2')), { won: false })).json();
  assert.equal(r.badge, 1);
  assert.equal(r.total, BADGES[0]);
  const r2 = await (await finish(await fight(ghostOf('google:2')), { won: false })).json();
  assert.equal(r2.badge, undefined);
});

test('rate limiter: RUN_LIMITER refusal gives 429', async () => {
  const { env, call } = await setup();
  env.RUN_LIMITER = { limit: async () => ({ success: false }) };
  assert.equal((await call('/api/raid/opponents')).status, 429);
});

test('parallel finishes cannot beat the caps (5 a day, 3 per ghost)', async () => {
  const { defend, ghostOf, finish, fight, DB } = await setup();
  await defend('tok2'); await defend('tok3');
  // one ghost: 6 open challenges finished at once -> exactly 3 count
  const g2 = ghostOf('google:2');
  const ids = [];
  for (let i = 0; i < OPEN_MAX; i++) ids.push(await fight(g2));
  const rs = await Promise.all(ids.map((id) => finish(id, { won: false }).then((r) => r.json())));
  assert.equal(rs.filter((r) => r.counted).length, PER_GHOST_DAILY);
  assert.equal(DB.db.prepare('SELECT SUM(count) AS n FROM raid_daily').get().n, PER_GHOST_DAILY);
  assert.equal(DB.db.prepare('SELECT points FROM raid_points WHERE player_id = ?').get('google:1').points, PER_GHOST_DAILY * POINTS_LOSS);
  // two ghosts: 3 more on g3 would make 6 -> only 2 more count (day total 5)
  const g3 = ghostOf('google:3');
  const ids2 = [];
  for (let i = 0; i < 4; i++) ids2.push(await fight(g3));
  const rs2 = await Promise.all(ids2.map((id) => finish(id, { won: false }).then((r) => r.json())));
  assert.equal(rs2.filter((r) => r.counted).length, DAILY_RAIDS - PER_GHOST_DAILY);
  assert.equal(DB.db.prepare('SELECT SUM(count) AS n FROM raid_daily').get().n, DAILY_RAIDS);
  assert.ok(rs2.filter((r) => !r.counted).every((r) => r.reason === 'daily_cap'));
});

test('finish: h must be the sha256 of id|seed|won|turns (wrong seed, wrong result, random hex all refused)', async () => {
  const { defend, ghostOf, finish, fight, DB } = await setup();
  await defend('tok2');
  const cid = await fight(ghostOf('google:2'));
  const seed = DB.db.prepare('SELECT seed FROM raid_challenges WHERE challenge_id = ?').get(cid).seed;
  for (const h of ['a'.repeat(64), await resultHash(cid, seed + 1, true, 6), await resultHash(cid, seed, false, 6)]) {
    const r = await finish(cid, { h });
    assert.equal(r.status, 422);
    assert.equal((await r.json()).error, 'bad_result');
  }
  assert.equal(DB.db.prepare('SELECT state FROM raid_challenges WHERE challenge_id = ?').get(cid).state, 'open');   // a bad h burns nothing
  assert.equal((await finish(cid)).status, 200);
});
