import { readFileSync } from 'node:fs';
import { DatabaseSync } from 'node:sqlite';
import { createHash } from 'node:crypto';
const mig = (f) => readFileSync(new URL(`../migrations/${f}`, import.meta.url), 'utf8');
class Stmt {
  constructor(db, sql) { this.db = db; this.sql = sql; this.args = []; }
  bind(...a) { this.args = a; return this; }
  async first() { return this.db.prepare(this.sql).get(...this.args) ?? null; }
  async all() { return { results: this.db.prepare(this.sql).all(...this.args) }; }
  async run() { const r = this.db.prepare(this.sql).run(...this.args); return { success: true, meta: { changes: Number(r.changes) } }; }
}
class TxD1 {
  constructor() { this.db = new DatabaseSync(':memory:'); this.db.exec('PRAGMA foreign_keys = ON;'); for (const f of ['0001_accounts.sql', '0002_runs.sql', '0009_depth_stage.sql', '0003_wallet.sql', '0007_mission_escrow.sql', '0010_mission_unlock.sql', '0011_economy.sql']) this.db.exec(mig(f)); }
  prepare(s) { return new Stmt(this.db, s); }
  batch(stmts) { const run = (this.q || Promise.resolve()).then(() => this._batch(stmts)); this.q = run.catch(() => {}); return run; }
  async _batch(stmts) { this.db.exec('BEGIN'); try { const o = []; for (const s of stmts) o.push(await s.run()); this.db.exec('COMMIT'); return o; } catch (e) { this.db.exec('ROLLBACK'); throw e; } }
}
export const mkEnv = () => {
  const DB = new TxD1();
  DB.db.prepare(`INSERT INTO players (id, display_name, created_at, last_login_at) VALUES ('p1', 'p', 1, 1), ('p2', 'q', 1, 1)`).run();
  for (const [tok, id] of [['tok1', 'p1'], ['tok2', 'p2']]) {
    DB.db.prepare('INSERT INTO sessions (id_hash, player_id, created_at, expires_at) VALUES (?, ?, 1, 9999999999)').run(createHash('sha256').update(tok).digest('base64url'), id);
  }
  return { DB };
};
