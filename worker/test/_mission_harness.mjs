// Shared harness for the N-W mission tests: same node:sqlite D1 as missions.test.mjs, plus a six-tier fixture
// table of its own (never reads godot/assets/data/economy/missions.json, which belongs to lane N-C).
import { readFileSync } from 'node:fs';
import { DatabaseSync } from 'node:sqlite';
import worker from '../src/index.js';
import { RunCore } from '../src/run_core.js';
import { settleEscrow, _setTableForTest } from '../src/missions.js';
import { SUPPORTED_RULE_VERSIONS } from '../src/run_do.js';

export const RULES = SUPPORTED_RULE_VERSIONS.at(-1);
export const OLD_RULES = SUPPORTED_RULE_VERSIONS.at(-2);
const mig = (f) => readFileSync(new URL(`../migrations/${f}`, import.meta.url), 'utf8');

export const FIXTURE = {
  version: 2, payout_cap: 20000,
  tiers: {
    N1: { mode: 'short', ascension: 0, stake: 300, m_base: 2.0, m_scale: 1.0, rules: [] },
    N2: { mode: 'short', ascension: 1, stake: 500, m_base: 2.4, m_scale: 1.0, rules: ['M6'] },
    N3: { mode: 'short', ascension: 3, stake: 800, m_base: 3.6, m_scale: 1.0, rules: ['M5', 'M6'] },
    N4: { mode: 'short', ascension: 4, stake: 1200, m_base: 4.4, m_scale: 1.0, rules: ['M1', 'M7'] },
    N5: { mode: 'short', ascension: 6, stake: 1800, m_base: 7.85, m_scale: 0.9, rules: ['M2', 'M4', 'M5'] },
    N6: { mode: 'full', ascension: 6, stake: 2500, m_base: 8.0, m_scale: 1.0, rules: ['M1', 'M5', 'M6', 'M7'] },
  },
};
export const useFixture = (over) => _setTableForTest(over ? { ...FIXTURE, tiers: { ...FIXTURE.tiers, ...over } } : FIXTURE);

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
    for (const f of ['0001_accounts.sql', '0002_runs.sql', '0009_depth_stage.sql', '0003_wallet.sql', '0005_token_revocation.sql', '0006_leaderboard.sql', '0007_mission_escrow.sql', '0010_mission_unlock.sql']) this.db.exec(mig(f));
  }
  prepare(s) { return new Stmt(this.db, s); }
  async batch(stmts) { const out = []; for (const s of stmts) out.push(await s.run()); return out; }
}
function fakeDo() {
  const cores = new Map();
  return {
    cores, idFromName: (n) => n,
    get: (name) => ({
      async fetch(url, init) {
        const path = new URL(typeof url === 'string' ? url : url.url).pathname;
        let core = cores.get(name);
        if (!core) {
          const db = new DatabaseSync(':memory:');
          const sql = { exec(q, ...b) { const st = db.prepare(q); if (/^\s*select/i.test(q)) { const r = st.all(...b); return { toArray: () => r }; } if (/^\s*(insert|update|delete)/i.test(q)) { st.run(...b); return { toArray: () => [] }; } db.exec(q); return { toArray: () => [] }; } };
          core = new RunCore(sql, { supportsRules: () => true });
          cores.set(name, core);
        }
        if (path === '/init') { const o = await core.init(JSON.parse(init.body)); return new Response(JSON.stringify(o), { status: o.ok ? 200 : 409 }); }
        if (path === '/abandon') return new Response(JSON.stringify(core.abandonInfo()), { status: 200 });
        return new Response('{}', { status: 404 });
      },
    }),
  };
}

export async function setup(extra = {}) {
  const DB = new FakeD1();
  const env = { DB, RUN_DO: fakeDo(), RUN_TOKEN_KEY: 'k', SESSION_SIGNING_KEY: 's', ...extra.env };
  for (const [id, token] of [['google:1', 'tok1'], ['google:2', 'tok2']]) {
    DB.db.prepare('INSERT INTO players (id, email, display_name, created_at, last_login_at) VALUES (?, ?, ?, 1, 1)').run(id, `${id}@x`, id);
    const hash = Buffer.from(await crypto.subtle.digest('SHA-256', new TextEncoder().encode(token))).toString('base64url');
    DB.db.prepare('INSERT INTO sessions (id_hash, player_id, created_at, expires_at) VALUES (?, ?, 1, 9999999999)').run(hash, id);
    for (let i = 0; i < 5; i++) DB.db.prepare(`INSERT INTO runs (run_id, player_id, mode, ascension, rules_version, state, created_at, closed_at, outcome, battles_done) VALUES (?, ?, 'normal', 0, ?, 'closed', 1, 2, 'lost', 1)`).run(`${id.slice(-1)}${i}`.padStart(32, 'a'), id, RULES);
  }
  const call = (path, { method = 'GET', body, token = 'tok1' } = {}) =>
    worker.fetch(new Request(`https://axiedice.fun${path}`, {
      method, headers: { cookie: `ad_session=${token}`, 'content-type': 'application/json' },
      body: body === undefined ? undefined : JSON.stringify(body),
    }), env);
  /** POST /api/run kind=mission. `rules` defaults to the tier's fixed set; pass `rules: undefined` key via over.mission to omit. */
  const mission = (tier = 'N1', { mission: mOver, token, rules_version = RULES, ...over } = {}) => {
    const t = FIXTURE.tiers[tier];
    return call('/api/run', { method: 'POST', token, body: { rules_version, kind: 'mission', ascension: t.ascension, mission: { tier, stake: t.stake, rules: t.rules, ...mOver }, ...over } });
  };
  const close = (runId, outcome) => {   // what RunDO._syncClosed does after run_close
    DB.db.prepare(`UPDATE runs SET state = 'closed', outcome = ?, closed_at = 5 WHERE run_id = ?`).run(outcome, runId);
    return settleEscrow(env, runId, outcome);
  };
  /** Buy a tier and finish it with `outcome` (default won). Returns the run id. */
  const play = async (tier, outcome = 'won', opts) => {
    const r = await mission(tier, opts);
    if (r.status !== 200) throw new Error(`mission ${tier} refused: ${r.status} ${JSON.stringify(await r.json())}`);
    const { run_id } = await r.json();
    await close(run_id, outcome);
    return run_id;
  };
  const unlocks = async (opts) => (await call('/api/missions/unlocks', opts)).json();
  const escrow = async (opts) => (await call('/api/missions/escrow', opts)).json();
  const row = (runId) => DB.db.prepare('SELECT * FROM mission_escrow WHERE run_id = ?').get(runId);
  const shard = (player = 'google:1') => DB.db.prepare(`SELECT delta, reason FROM wallet_ledger WHERE player_id = ? AND currency = 'shard' ORDER BY id`).all(player).map((r) => ({ ...r }));
  const escrows = () => DB.db.prepare('SELECT COUNT(*) AS n FROM mission_escrow').get().n;
  const enterBattle = (runId) => env.RUN_DO.cores.get(runId).sql.exec(
    `INSERT INTO epochs (seq, kind, args, h, log_len, seed, log_delta, attempt, req_digest, at) VALUES (1, 'node', '{}', 'h', 1, 1, '[]', 0, 'd', 1)`);
  return { DB, env, call, mission, close, play, unlocks, escrow, row, shard, escrows, enterBattle };
}
