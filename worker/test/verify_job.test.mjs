// SR-V job builder + the RunDO enqueue hook. Run from worker/:  node --test test/verify_job.test.mjs
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';
import { readFileSync } from 'node:fs';
import { RunDO } from '../src/run_do.js';
import { runBonuses, buildServerHeader, buildServerLoadout, sanitizeLogHeader } from '../src/verify_job.js';

const RULES = 'godot-2026-10-26-v';
const RUN = 'c'.repeat(32);
const NOW = 1_800_000_000;

function sqlStub() {
  const db = new DatabaseSync(':memory:');
  return { exec(q, ...b) { const st = db.prepare(q); if (/^\s*select/i.test(q)) { const r = st.all(...b); return { toArray: () => r }; } if (/^\s*(insert|update|delete)/i.test(q)) { st.run(...b); return { toArray: () => [] }; } db.exec(q); return { toArray: () => [] }; } };
}
function fakeD1() {
  const db = new DatabaseSync(':memory:');
  db.exec(readFileSync(new URL('../migrations/0012_verify.sql', import.meta.url), 'utf8'));
  db.exec(`CREATE TABLE runs (run_id TEXT PRIMARY KEY, player_id TEXT, mode TEXT, ascension INTEGER, rules_version TEXT, state TEXT, created_at INTEGER,
      closed_at INTEGER, outcome TEXT, battles_done INTEGER DEFAULT 0, summary_json TEXT, depth_stage INTEGER);
    CREATE TABLE mission_escrow (run_id TEXT PRIMARY KEY, tier TEXT, state TEXT DEFAULT 'open');
    CREATE TABLE unlocks (player_id TEXT, unlock_id TEXT, at INTEGER, PRIMARY KEY (player_id, unlock_id));`);
  return { raw: db, prepare(q) { return { bind(...b) { return {
    async first() { return db.prepare(q).get(...b) ?? null; },
    async all() { return { results: db.prepare(q).all(...b) }; },
    async run() { const r = db.prepare(q).run(...b); return { meta: { changes: Number(r.changes) } }; },
  }; } }; } };
}

/** A closed run in a DO + an open one in D1, as _syncClosed sees it. */
async function closedRun({ kind = 'normal', env = {}, tier = null, unlocks = [], summary = {}, closeArgs = '{}', d1 = fakeD1(), depth = 3, outcome = 'won' } = {}) {
  const ctx = { storage: { sql: sqlStub(), getAlarm: async () => null, setAlarm: async () => {} }, getWebSockets: () => [] };
  const rdo = new RunDO(ctx, { DB: d1, VERIFY_SHADOW: '1', ...env });
  await rdo.core.init({ run_id: RUN, player_id: 'p1', mode: kind, ascension: 2, rules_version: RULES, client_nonce: 'd'.repeat(32), depth_stage: depth });
  const ins = (seq, k, args, delta, logLen, seed, h) => rdo.core.sql.exec(
    `INSERT INTO epochs (seq, kind, args, h, log_len, seed, log_delta, attempt, req_digest, at) VALUES (?, ?, ?, ?, ?, ?, ?, 0, 'd', 1)`, seq, k, JSON.stringify(args), h, logLen, seed, JSON.stringify(delta));
  ins(0, 'run_start', { mode: 'full', ascension: 2 }, [], 0, 11, 'h0');
  ins(1, 'node', { node_id: 'r1_c0' }, [{ fn: 'enter_node', args: ['r1_c0', 'battle'] }], 1, 22, 'h1');
  ins(2, 'close', JSON.parse(closeArgs), [{ fn: 'end_turn', args: [] }], 2, 0, 'h2');
  rdo.core.sql.exec(`UPDATE meta SET state = 'closed', outcome = ?, summary = ? WHERE id = 1`, outcome, JSON.stringify(summary));
  d1.raw.prepare(`INSERT INTO runs (run_id, player_id, mode, ascension, rules_version, state, created_at, depth_stage) VALUES (?, 'p1', ?, 2, ?, 'open', ?, ?)`).run(RUN, kind, RULES, NOW, depth);
  // escrow is pre-settled so the unrelated settle batch (needs the full wallet schema) is skipped
  if (tier) d1.raw.prepare(`INSERT INTO mission_escrow (run_id, tier, state) VALUES (?, ?, 'lost')`).run(RUN, tier);
  for (const u of unlocks) d1.raw.prepare(`INSERT INTO unlocks (player_id, unlock_id, at) VALUES ('p1', ?, ?)`).run(typeof u === 'string' ? u : u.id, typeof u === 'string' ? NOW - 100 : u.at);
  return { rdo, d1 };
}
const queued = (d1) => d1.raw.prepare('SELECT * FROM verify_queue').all();

test('runBonuses mirrors MetaState.run_bonuses minus perks', () => {
  assert.deepEqual(runBonuses([]), { bonus_reroll: 0, hp_bonus: 0, start_relic_max_rarity: -1, reward_reroll_max: 1 });
  assert.deepEqual(runBonuses(['u_reroll', 'u_reroll2', 'u_hp', 'u_hp2', 'u_start']), { bonus_reroll: 2, hp_bonus: 5, start_relic_max_rarity: 0, reward_reroll_max: 1 });
  assert.deepEqual(runBonuses(['u_reroll', 'u_hp']), { bonus_reroll: 1, hp_bonus: 3, start_relic_max_rarity: -1, reward_reroll_max: 1 });
  assert.deepEqual(runBonuses(['u_full', 'u_face1']), runBonuses([]), 'other unlocks do not change the run');
});

test('server header: kind and mission must agree', () => {
  const meta = { rules_version: RULES, mode: 'mission', ascension: 1, depth_stage: 2 };
  const ok = buildServerHeader({ meta, runMode: 'short', missionRow: { tier: 'N1' }, newcomer: false });
  assert.equal(ok.header_mismatch, false); assert.equal(ok.mission.tier, 'N1'); assert.equal(ok.kind, 'mission'); assert.equal(ok.ranked, false);
  assert.equal(buildServerHeader({ meta, runMode: 'short', missionRow: null }).header_mismatch, true, 'mission kind without escrow');
  assert.equal(buildServerHeader({ meta: { ...meta, mode: 'normal' }, runMode: 'short', missionRow: { tier: 'N1' } }).header_mismatch, true, 'escrow on a non-mission run');
  assert.equal(buildServerHeader({ meta: { ...meta, mode: 'normal', depth_stage: null }, runMode: 'x', missionRow: null }).depth_stage, 3);
  assert.equal(buildServerHeader({ meta: { ...meta, mode: 'ranked' }, runMode: 'full', missionRow: null }).ranked, true);
});

test('ranked loadout pins the flags the rules pin; others are listed as unknown', () => {
  assert.deepEqual(buildServerLoadout({ unlockIds: [], ranked: true }).forced, { rules_on: true, core_off: false, anchor: false });
  assert.deepEqual(buildServerLoadout({ unlockIds: [], ranked: true }).server_unknown, ['boon_id']);
  assert.deepEqual(buildServerLoadout({ unlockIds: [], ranked: false }).server_unknown, ['anchor', 'rules_on', 'core_off', 'boon_id']);
});

test('log_header whitelist: junk is dropped, good fields kept', () => {
  assert.deepEqual(sanitizeLogHeader({ team_keys: ['a', 'b'], content_version: 'v1', local_secret: 5, loadout: { anchor: true, rules_on: 1, boon_id: 'x_y', evil: 1 }, extra: 1 }),
    { team_keys: ['a', 'b'], content_version: 'v1', local_secret: 5, loadout: { anchor: true, boon_id: 'x_y' } });
  assert.equal(sanitizeLogHeader({ team_keys: ['a', 'b', 'c', 'd', 'e', 'f'] }), null);
  assert.equal(sanitizeLogHeader({ team_keys: [1] }), null);
  assert.equal(sanitizeLogHeader('x'), null);
});

for (const kind of ['normal', 'daily', 'ranked', 'mission']) {
  test(`close sync enqueues a ${kind} run with a server-built header and loadout`, async () => {
    const { rdo, d1 } = await closedRun({ kind, tier: kind === 'mission' ? 'N1' : null, unlocks: ['u_hp', 'u_reroll'], summary: { score: 321, platform: 'macos' },
      closeArgs: JSON.stringify({ log_header: { team_keys: ['t1'], content_version: 'cv', loadout: { anchor: true, boon_id: 'b_x' } } }) });
    await rdo._syncClosed(); await rdo._verifyP;
    const rows = queued(d1);
    assert.equal(rows.length, 1);
    assert.equal(rows[0].state, 'pending'); assert.equal(rows[0].kind, kind); assert.equal(rows[0].platform, 'macos');
    assert.equal(rows[0].client_score, 321); assert.equal(rows[0].header_mismatch, 0); assert.equal(rows[0].srv_outcome, 'won');
    const p = JSON.parse(rows[0].payload_json);
    assert.equal(p.server_header.kind, kind);
    assert.equal(p.server_header.mode, 'full');
    assert.equal(p.server_header.ascension, 2);
    assert.equal(p.server_header.ranked, kind === 'ranked');
    assert.equal(p.server_header.depth_stage, 3);
    assert.equal(p.server_header.rules_version, RULES);
    assert.equal(p.server_header.newcomer, true);
    assert.equal(p.server_header.mission === null, kind !== 'mission');
    if (kind === 'mission') assert.equal(p.server_header.mission.tier, 'N1');
    assert.deepEqual(p.server_loadout.bonuses, { bonus_reroll: 1, hp_bonus: 3, start_relic_max_rarity: -1, reward_reroll_max: 1 });
    assert.deepEqual(p.client_header, { team_keys: ['t1'], content_version: 'cv', loadout: { anchor: true, boon_id: 'b_x' } });
    assert.deepEqual(p.entries, [{ fn: 'enter_node', args: ['r1_c0', 'battle'] }, { fn: 'end_turn', args: [] }]);
    assert.deepEqual(p.tape.map((t) => t.kind), ['run_start', 'node'], 'close row is not part of the tape');
    assert.equal(p.tape[0].extra.run_id, RUN); assert.equal(p.tape[0].extra.client_nonce, 'd'.repeat(32));
    assert.equal(p.tape[0].extra.header.depth_stage, 3);
    assert.equal(p.tape[1].extra.h, 'h1'); assert.equal(p.tape[1].extra.log_len, 1); assert.equal(p.tape[1].seed, 22);
    assert.deepEqual(p.client_claim, { outcome: 'won', score: 321 });
    // The close itself is unchanged by the shadow: the run row is closed with the client's outcome.
    assert.equal(d1.raw.prepare('SELECT state, outcome FROM runs').get().state, 'closed');
  });
}

test('mission run without an escrow row is queued with header_mismatch (verifier answers header_mismatch)', async () => {
  const { rdo, d1 } = await closedRun({ kind: 'mission', tier: null });
  await rdo._syncClosed(); await rdo._verifyP;
  const r = queued(d1)[0];
  assert.equal(r.header_mismatch, 1);
  assert.equal(JSON.parse(r.payload_json).server_header.header_mismatch, true);
});

test('unlocks bought after the run started do not count; the client header cannot change bonuses', async () => {
  const { rdo, d1 } = await closedRun({ unlocks: [{ id: 'u_hp', at: NOW - 5 }, { id: 'u_hp2', at: NOW + 50 }],
    closeArgs: JSON.stringify({ log_header: { loadout: { bonuses: { hp_bonus: 99 } } } }) });
  await rdo._syncClosed(); await rdo._verifyP;
  const p = JSON.parse(queued(d1)[0].payload_json);
  assert.equal(p.server_loadout.bonuses.hp_bonus, 3);
  assert.equal(JSON.stringify(p.client_header).includes('99'), false);
});

test('flag off: nothing is queued and nothing is built', async () => {
  const { rdo, d1 } = await closedRun({ env: { VERIFY_SHADOW: '0' } });
  await rdo._syncClosed();
  assert.equal(rdo._verifyP, undefined);
  assert.equal(queued(d1).length, 0);
  assert.equal(d1.raw.prepare('SELECT state FROM runs').get().state, 'closed');
});

test('an abandoned run (D1 not closed by us) is not queued', async () => {
  const d1 = fakeD1();
  const { rdo } = await closedRun({ d1 });
  d1.raw.prepare(`UPDATE runs SET state = 'abandoned', outcome = 'lost'`).run();
  await rdo._syncClosed(); await rdo._verifyP;
  assert.equal(queued(d1).length, 0);
});

test('a broken verify queue never changes the close and never throws', async () => {
  const d1 = fakeD1();
  const { rdo } = await closedRun({ d1 });
  d1.raw.exec('DROP TABLE verify_queue');
  await rdo._syncClosed();
  assert.equal(await rdo._verifyP, false);
  assert.equal(d1.raw.prepare('SELECT state, outcome FROM runs').get().state, 'closed');
  assert.equal(rdo.ctx.storage.getAlarm !== undefined, true);
});

test('the close reply does not wait for the enqueue', async () => {
  const d1 = fakeD1();
  const { rdo } = await closedRun({ d1 });
  const prep = d1.prepare.bind(d1);
  let release; const gate = new Promise((r) => { release = r; });
  d1.prepare = (q) => {
    const st = prep(q);
    if (!/FROM mission_escrow/.test(q)) return st;
    return { bind: (...b) => { const x = st.bind(...b); return { ...x, first: async () => { await gate; return x.first(); } }; } };
  };
  await rdo._syncClosed();           // returns although the enqueue is blocked on D1
  assert.equal(queued(d1).length, 0);
  release(); await rdo._verifyP;
  assert.equal(queued(d1).length, 1);
});

