// QA: Season Pass season 1 start (3/11/2026 00:00 UTC). Fixed clock via Date.now, no real time.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import worker from '../src/index.js';
import pass from '../../godot/assets/data/economy/pass_v2.json' with { type: 'json' };
import { mkEnv } from './_econ_harness.mjs';

const call = (env, path, method = 'GET', body) => worker.fetch(new Request(`https://axiedice.fun${path}`, {
  method, headers: { cookie: 'ad_session=tok1', origin: 'https://axiedice.fun', 'content-type': 'application/json' }, body: body ? JSON.stringify(body) : undefined }), env);
const j = async (p) => { const r = await p; return { status: r.status, ...(await r.json()) }; };
const T = (s) => Date.parse(s) / 1000;
const START = T('2026-11-03T00:00:00Z');
const at = async (iso, fn) => { const real = Date.now; Date.now = () => Date.parse(iso); try { return await fn(); } finally { Date.now = real; } };
const run = (env, id, created, closed, { score = 370, won = true, boss = 1, mode = 'normal' } = {}) => env.DB.db.prepare(
  `INSERT INTO runs (run_id, player_id, mode, ascension, rules_version, state, created_at, closed_at, outcome, battles_done, summary_json) VALUES (?, 'p1', ?, 0, 'x', 'closed', ?, ?, ?, 5, ?)`)
  .run(id, mode, created, closed, won ? 'won' : 'lost', JSON.stringify({ score, len: 'short', pw: 10, bosses_started: boss, elites: 1 }));
const id = (c) => c.repeat(32);
const claim = (env, kind, extra) => j(call(env, '/api/econ/claim', 'POST', { kind, ...extra }));

test('data: season 1 starts 2026-11-03 00:00 UTC, 8 weeks, ends 2026-12-29; Nov 2 is a Monday', () => {
  assert.equal(pass.season_id, 's1');
  assert.equal(pass.start_day, '2026-11-03');
  assert.equal(pass.end_day, '2026-12-29');
  assert.equal((T('2026-12-29T00:00:00Z') - START) / 86400, pass.weeks * 7);
  assert.equal(new Date('2026-11-02T00:00:00Z').getUTCDay(), 1);
  assert.equal(new Date('2026-11-09T00:00:00Z').getUTCDay(), 1);
  assert.equal(pass.levels[0].xp_total, 500);
  assert.deepEqual(pass.levels[0].free, [{ type: 'shard', value: 300 }]);
});

test('before the start (2/11 23:59:59 UTC): runs give 0 Pass XP, level and weekly claims refused, daily gives no XP', async () => {
  const env = mkEnv();
  await at('2026-11-02T23:59:59Z', async () => {
    run(env, id('a'), START - 7200, START - 5);
    const s = await j(call(env, '/api/econ'));
    assert.deepEqual([s.pass.xp, s.pass.level, s.pass.season], [0, 0, 's1']);
    assert.deepEqual([s.pass.weekly.runs, s.pass.weekly.wins, s.pass.weekly.boss], [0, 0, 0]);
    assert.equal(s.pass.weekly.week, '2026-11-02');
    assert.equal((await claim(env, 'pass', { level: 1 })).code, 'out_of_season');
    assert.equal((await claim(env, 'pass_weekly', { task: 'play_runs' })).code, 'out_of_season');
    const d = await claim(env, 'daily');
    assert.equal(d.ok, true); assert.equal(d.pass.xp, 0, 'daily claim before the season adds no Pass XP');
  });
});

test('a run closed before the start but synced/claimed after does not count', async () => {
  const env = mkEnv();
  await at('2026-11-02T23:00:00Z', () => j(call(env, '/api/econ')));
  run(env, id('a'), START - 7200, START - 1);
  run(env, id('b'), START - 7200, START - 3600);
  await at('2026-11-03T00:00:00Z', async () => {
    const s = await j(call(env, '/api/econ'));
    assert.equal(s.pass.xp, 0);
    assert.equal(s.pass.weekly.runs, 0);
    assert.equal((await claim(env, 'pass', { level: 1 })).code, 'not_reached');
  });
});

test('exact start 3/11 00:00:00 UTC: run closed at START counts; level 1 at 500 XP pays the 300 Shard of the table', async () => {
  const env = mkEnv();
  await at('2026-11-02T20:00:00Z', () => j(call(env, '/api/econ')));
  await at('2026-11-03T00:00:00Z', async () => {
    run(env, id('a'), START - 3600, START);
    const s = await j(call(env, '/api/econ'));
    assert.equal(s.pass.xp, 370);
    assert.equal(s.pass.level, 0);
    assert.equal((await claim(env, 'pass', { level: 1 })).code, 'not_reached', '370 < 500');
    run(env, id('b'), START + 100, START + 4000);
    const s2 = await j(call(env, '/api/econ'));
    assert.equal(s2.pass.xp, 740); assert.equal(s2.pass.level, 1);
    const c = await claim(env, 'pass', { level: 1 });
    assert.equal(c.ok, true);
    assert.equal(c.shard - s2.shard, pass.levels[0].free[0].value, 'paid = table value (300)');
    assert.deepEqual(c.pass.claimed, [1]);
    assert.equal((await claim(env, 'pass', { level: 1 })).shard, c.shard, 'once');
  });
});

test('daily XP cap uses the UTC day of closing: day 3/11 capped, 4/11 starts fresh', async () => {
  const env = mkEnv();
  await at('2026-11-03T01:00:00Z', () => j(call(env, '/api/econ')));
  for (let i = 0; i < 5; i++) run(env, id('abcde'[i]), START + 100 + i * 5000, START + 4000 + i * 5000);
  const d2 = T('2026-11-04T00:00:00Z');
  run(env, id('f'), d2 + 100, d2 + 4000);
  await at('2026-11-04T06:00:00Z', async () => {
    const s = await j(call(env, '/api/econ'));
    // day 1: 4 x 370 = 1480 full + 5th (370): 20 full + floor(350*0.2)=70 -> 1570; day 2 fresh: 370
    assert.equal(s.pass.xp, 1570 + 370);
  });
});

test('weekly: first week counts only from 3/11 (not Mon 2/11), resets Mon 9/11 00:00 UTC', async () => {
  const env = mkEnv();
  await at('2026-11-03T00:00:00Z', () => j(call(env, '/api/econ')));
  run(env, id('a'), T('2026-11-02T08:00:00Z'), T('2026-11-02T09:00:00Z'));
  run(env, id('b'), T('2026-11-03T08:00:00Z'), T('2026-11-03T09:00:00Z'));
  run(env, id('c'), T('2026-11-08T22:00:00Z'), T('2026-11-08T23:59:59Z'), { won: false, boss: 0 });
  run(env, id('d'), T('2026-11-09T00:00:00Z') - 3600, T('2026-11-09T00:00:00Z'), { boss: 1 });
  await at('2026-11-08T23:59:59Z', async () => {
    const s = await j(call(env, '/api/econ'));
    assert.equal(s.pass.weekly.week, '2026-11-02');
    assert.deepEqual([s.pass.weekly.runs, s.pass.weekly.wins, s.pass.weekly.boss], [2, 1, 1], 'a (2/11) excluded; d (9/11) not yet');
  });
  await at('2026-11-09T00:00:00Z', async () => {
    const s = await j(call(env, '/api/econ'));
    assert.equal(s.pass.weekly.week, '2026-11-09');
    assert.deepEqual([s.pass.weekly.runs, s.pass.weekly.wins, s.pass.weekly.boss], [1, 1, 1]);
  });
});

test('weekly claim in week 1 pays 500 XP once; nothing carries into week 2', async () => {
  const env = mkEnv();
  await at('2026-11-03T00:00:00Z', () => j(call(env, '/api/econ')));
  run(env, id('a'), T('2026-11-03T08:00:00Z'), T('2026-11-03T09:00:00Z'));
  await at('2026-11-03T10:00:00Z', async () => {
    const a = await claim(env, 'pass_weekly', { task: 'reach_boss' });
    assert.equal(a.ok, true); assert.equal(a.pass.xp, 370 + 500);
    assert.deepEqual(a.pass.weekly.claimed, ['reach_boss']);
    assert.equal((await claim(env, 'pass_weekly', { task: 'reach_boss' })).pass.xp, 870, 'once');
  });
  await at('2026-11-09T00:00:00Z', async () => {
    const s = await j(call(env, '/api/econ'));
    assert.deepEqual(s.pass.weekly.claimed, []);
    assert.equal(s.pass.weekly.boss, 0);
    assert.equal((await claim(env, 'pass_weekly', { task: 'reach_boss' })).code, 'not_done');
  });
});

test('edge: run started 2/11, closed 3/11 counts (by closing time), weekly too', async () => {
  const env = mkEnv();
  await at('2026-11-02T22:00:00Z', () => j(call(env, '/api/econ')));
  run(env, id('a'), T('2026-11-02T23:30:00Z'), T('2026-11-03T00:30:00Z'));
  await at('2026-11-03T00:31:00Z', async () => {
    const s = await j(call(env, '/api/econ'));
    assert.equal(s.pass.xp, 370);
    assert.equal(s.pass.weekly.runs, 1);
  });
});

test('a pre-start run is never picked up later when the season is open', async () => {
  const env = mkEnv();
  await at('2026-11-02T23:59:00Z', async () => {
    run(env, id('a'), START - 7000, START - 60);
    await j(call(env, '/api/econ')); await j(call(env, '/api/econ'));
  });
  await at('2026-11-20T12:00:00Z', async () => {
    assert.equal((await j(call(env, '/api/econ'))).pass.xp, 0);
  });
});
