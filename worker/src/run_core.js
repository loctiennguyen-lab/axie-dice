// RunCore: the rules of one run's Durable Object, with no Cloudflare types in it.
//
// The DO class (run_do.js) is a thin shell: it owns the WebSockets and hands every message to
// RunCore.handle(). RunCore talks to storage through `sql.exec(query, ...binds)` (the same shape as
// Durable Object SqlStorage: returns an object with toArray()), so node tests run it on node:sqlite.
//
// What it enforces is the syntactic part of ADR server-authoritative-rng §4.3 / §4.6: append-only
// log with a hash chain, one valid request per seq, no overlapping epochs, consume-in-place,
// pinned reroll seeds, budgets. It never runs game rules: that is the verifier's job (later).
import { AID_BY_KIND, BOSS_CONTINUE_PRICE, PRICES, totalCap } from './aid_prices.js';
import { canonKV, chainStart, chainNext, commitOf, epochSeed, isCanonScalar, nodeRow, MAX_PARAMS, _bytes } from './epoch_canon.js';

export const MAX_EPOCHS = 400;
export const MAX_ACTIONS = 3000;
export const MAX_MSG_BYTES = 16 * 1024;
export const BUCKET_BURST = 20;
export const BUCKET_PER_S = 5;

/** Mirrors ActionLog.ALLOWED_FNS (godot/scripts/core/action_log.gd) plus the ADR 4.2 additions. */
export const ALLOWED_FNS = new Set([
  'enter_node', 'use_die', 'play_active', 'reroll_dice', 'end_turn', 'undo_last', 'take_reward',
  'reroll_rewards', 'event_choose', 'event_done', 'shop_buy', 'shop_done',
  'shop_refresh', 'continue', 'pact_reroll',
  // lane A PR2
  'tweak', 'hold_pick', 'loaded_pick', 'sell_relic', 'swap_on_full', 'reorder_party', 'aid_use',
]);

/** kind -> action(s) that consume it at position log_len (ADR 4.2). null = consumed on reply. A list means any of them. */
export const KINDS = {
  run_start: { consume: null, paid: false },
  node: { consume: 'enter_node', paid: false },
  end_turn: { consume: 'end_turn', paid: false },
  reroll: { consume: 'reroll_dice', paid: false }, // paid when args.source === 'aid'
  reward: { consume: null, paid: false },
  reward_reroll: { consume: ['reroll_rewards', 'take_reward'], paid: false },
  event_choice: { consume: ['event_choose', 'event_done'], paid: false },
  shop_roll: { consume: ['shop_buy', 'shop_done'], paid: false }, // shop_done: leaving without buying must not soft-lock
  shop_refresh: { consume: 'shop_refresh', paid: true },
  continue: { consume: 'continue', paid: true },
  pact_reroll: { consume: 'pact_reroll', paid: true },
};

export const FREE_CONTINUE = { kinds: ['elite', 'boss'], max_asc: 2 }; // aid_prices.json free_continue
const IDENT = /^[a-z0-9_]+$/;

// Allowed arg keys per kind. Anything else is refused: args feed the seed and the ledger, so an
// open vocabulary would let a client vary them to fish for seeds. Values are checked in _argsProblem.
const ARG_KEYS = {
  run_start: ['mode', 'ascension'],
  node: ['node_id'],
  end_turn: ['turn', 'attempt'], // attempt only present when > 0 (lane A)
  reroll: ['turn', 'k', 'source', 'uids', 'attempt'],
  reward: ['node_id'],
  reward_reroll: ['k', 'node_id'],
  event_choice: ['choice', 'index', 'node_id'],
  shop_roll: ['node_id', 'item'],
  shop_refresh: ['node_id', 'k'],
  continue: ['node_id', 'attempt'],
  pact_reroll: ['node_id', 'slot'],
};
const SOURCES = new Set(['base', 'aid']);
const MODES = new Set(['short', 'full']); // game length (RunParams.mode); run kind lives in D1
const MAX_TURN = 200;
const MAX_K = 20;
const MAX_ID = 100000;

/** null when args are acceptable for the kind, else an internal reason. */
export function argsProblem(kind, args) {
  const allowed = ARG_KEYS[kind];
  if (!allowed) return 'kind';
  for (const [k, v] of Object.entries(args)) {
    if (!allowed.includes(k)) return `key_${k}`;
    if (k === 'source') { if (!SOURCES.has(v)) return 'source'; continue; }
    if (k === 'mode') { if (!MODES.has(v)) return 'mode'; continue; }
    if (k === 'uids') {
      if (!Array.isArray(v) || v.length === 0 || v.length > 16 || !v.every((x) => Number.isSafeInteger(x) && x >= 0 && x <= MAX_ID)) return 'uids';
      continue;
    }
    if (k === 'turn') { if (!Number.isSafeInteger(v) || v < 1 || v > MAX_TURN) return 'turn'; continue; }
    if (k === 'k') { if (!Number.isSafeInteger(v) || v < 1 || v > MAX_K) return 'k'; continue; }
    if (k === 'item') { if (typeof v !== 'string' || !IDENT.test(v)) return 'item'; continue; }
    if (k === 'node_id') { if (nodeRow(v) < 1) return 'node_id'; continue; }
    if (!Number.isSafeInteger(v) || v < 0 || v > MAX_ID) return `val_${k}`;
  }
  if (kind === 'end_turn' && args.turn === undefined) return 'turn';
  if (kind === 'reroll' && (args.turn === undefined || args.k === undefined || args.source === undefined)) return 'reroll_args';
  return null;
}
// NOTE for the verifier (P3): the server only checks that turn/k are in range. The verifier MUST
// check that the (turn, k) of each reroll epoch matches the real turn and reroll count at that log
// position, otherwise a client could request seeds under invented keys.

const fail = (seq, code) => ({ t: 'epoch_err', seq, code });
const isPaid = (kind, args) => KINDS[kind].paid || (kind === 'reroll' && args.source === 'aid');

export class RunCore {
  /**
   * deps: { now():ms, charge?(idemKey, kind, args, meta) -> Promise<bool>,
   *         checkHello?(claims) -> Promise<boolean> (D1: jti current, account not locked),
   *         verifyToken?(token) -> Promise<{player_id, run_id, rules_version}|null>,
   *         supportsRules?(v) -> bool, log?(event, detail) }
   */
  constructor(sql, deps = {}) {
    this.sql = sql;
    this.deps = { now: () => Date.now(), ...deps };
    this.queue = Promise.resolve(); // serialises messages: DO storage is sequential, awaits are not
    this.bucket = { tokens: BUCKET_BURST, at: this.deps.now() };
  }

  static initSchema(sql) {
    sql.exec(`CREATE TABLE IF NOT EXISTS meta (
      id INTEGER PRIMARY KEY CHECK (id = 1), run_id TEXT NOT NULL, player_id TEXT NOT NULL,
      is_guest INTEGER NOT NULL, mode TEXT NOT NULL, ascension INTEGER NOT NULL DEFAULT 0, rules_version TEXT NOT NULL,
      s_run BLOB NOT NULL, client_nonce TEXT, session_epoch INTEGER NOT NULL DEFAULT 0,
      state TEXT NOT NULL, outcome TEXT, summary TEXT, created_at INTEGER NOT NULL)`);
    sql.exec(`CREATE TABLE IF NOT EXISTS pending_aid (
      seq INTEGER PRIMARY KEY, aid TEXT NOT NULL, idem_key TEXT NOT NULL, state TEXT NOT NULL)`);
    // One row per epoch, no secondary index (ADR 4.6 F4). req_digest makes a resend idempotent;
    // pin_key marks reroll rows; uids is the committed (not seeded) reroll list.
    sql.exec(`CREATE TABLE IF NOT EXISTS epochs (
      seq INTEGER PRIMARY KEY, kind TEXT NOT NULL, args TEXT NOT NULL, h TEXT NOT NULL,
      log_len INTEGER NOT NULL, seed INTEGER NOT NULL, log_delta TEXT NOT NULL,
      attempt INTEGER NOT NULL, req_digest TEXT NOT NULL, pin_key TEXT, uids TEXT, aid TEXT, at INTEGER NOT NULL)`);
  }

  // ------------------------------------------------------------------ creation

  /** Called once, right after the D1 batch inserted runs(state=pending). Returns the commitment. */
  async init({ run_id, player_id, is_guest = false, mode = 'normal', ascension = 0, rules_version, client_nonce = null }) {
    RunCore.initSchema(this.sql);
    if (this.meta()) throw new Error('run already initialised');
    if (!/^[a-f0-9]{32}$/.test(run_id)) throw new Error('bad run_id');
    if (this.deps.supportsRules && !this.deps.supportsRules(rules_version)) return { ok: false, code: 'version' };
    const sRun = crypto.getRandomValues(new Uint8Array(32)); // never leaves the DO while the run is open
    this.sql.exec(
      `INSERT INTO meta (id, run_id, player_id, is_guest, mode, ascension, rules_version, s_run, client_nonce, state, created_at)
       VALUES (1, ?, ?, ?, ?, ?, ?, ?, ?, 'open', ?)`,
      run_id, player_id, is_guest ? 1 : 0, mode, ascension, rules_version, sRun, client_nonce, this.deps.now(),
    );
    return { ok: true, commit: await commitOf(run_id, sRun) };
  }

  meta() {
    try { return this.sql.exec('SELECT * FROM meta WHERE id = 1').toArray()[0] || null; } catch { return null; }
  }

  last() {
    return this.sql.exec('SELECT * FROM epochs ORDER BY seq DESC LIMIT 1').toArray()[0] || null;
  }

  // ------------------------------------------------------------------ message entry

  /** Serialised entry point. conn = per-socket state {authed, epoch}. Returns {replies, close?}. */
  handle(conn, raw, io = {}) {
    // io.load()/io.save(conn) read and write the socket attachment INSIDE the queue, so two messages
    // arriving back to back on one socket cannot both read the same stale state.
    const run = this.queue.then(async () => {
      const c = io.load ? (io.load() || { authed: false, epoch: 0 }) : conn;
      const out = await this._handle(c, raw);
      if (io.save) io.save(c);
      return out;
    });
    this.queue = run.catch(() => {});
    return run;
  }

  _take() {
    const t = this.deps.now();
    this.bucket.tokens = Math.min(BUCKET_BURST, this.bucket.tokens + ((t - this.bucket.at) / 1000) * BUCKET_PER_S);
    this.bucket.at = t;
    if (this.bucket.tokens < 1) return false;
    this.bucket.tokens -= 1;
    return true;
  }

  async _handle(conn, raw) {
    if (typeof raw !== 'string' || raw.length > MAX_MSG_BYTES) return { replies: [], close: { code: 1009, reason: 'size' } };
    if (!this._take()) return { replies: [], close: { code: 1008, reason: 'rate' } };
    let msg;
    try { msg = JSON.parse(raw); } catch { return { replies: [{ t: 'epoch_err', seq: 0, code: 'bad_request' }] }; }
    if (!msg || typeof msg !== 'object') return { replies: [{ t: 'epoch_err', seq: 0, code: 'bad_request' }] };
    const meta = this.meta();
    if (!meta) return { replies: [], close: { code: 1008, reason: 'no_run' } };
    if (msg.t === 'hello') return this._hello(conn, meta, msg);
    if (!conn.authed) return { replies: [], close: { code: 1008, reason: 'no_hello' } };
    if (conn.epoch !== meta.session_epoch) return { replies: [{ t: 'bye', reason: 'other_device' }], close: { code: 4000, reason: 'other_device' } };
    if (meta.state !== 'open') return { replies: [fail(msg.seq | 0, 'expired')] };
    switch (msg.t) {
      case 'epoch_req': return { replies: [await this._epochReq(meta, msg)] };
      case 'run_close': return { replies: [await this._runClose(meta, msg)] };
      case 'aid_req': return { replies: [fail(msg.seq | 0, 'rejected')] }; // TODO(wallet): needs Gem decision (LIAM-2)
      default: return { replies: [fail(0, 'bad_request')] };
    }
  }

  // ------------------------------------------------------------------ hello / resync

  async _hello(conn, meta, msg) {
    const claims = this.deps.verifyToken ? await this.deps.verifyToken(msg.run_token) : null;
    if (!claims || claims.run_id !== meta.run_id || claims.player_id !== meta.player_id) {
      return { replies: [], close: { code: 1008, reason: 'auth' } };
    }
    // ADR 4.6: ask D1 again at hello (token not revoked, account not locked). Fail closed on any error.
    if (this.deps.checkHello) {
      let ok = false;
      try { ok = await this.deps.checkHello(claims); } catch { ok = false; }
      if (!ok) { this._anomaly('hello_revoked', { run_id: meta.run_id }); return { replies: [], close: { code: 1008, reason: 'auth' } }; }
    }
    if (claims.rules_version !== meta.rules_version) return { replies: [{ t: 'bye', reason: 'version' }], close: { code: 4001, reason: 'version' } };
    const epoch = meta.session_epoch + 1; // newest socket wins, the DO shell evicts the older ones
    this.sql.exec('UPDATE meta SET session_epoch = ? WHERE id = 1', epoch);
    conn.authed = true;
    conn.epoch = epoch;
    const last = this.last();
    const seq = last ? last.seq : -1; // -1 = no epoch yet (seq starts at 0)
    const h = last ? last.h : await chainStart(meta.run_id);
    const logLen = last ? last.log_len : 0;
    const from = Number.isInteger(msg.last_seq) && msg.last_seq >= -1 ? msg.last_seq : seq;
    if (from < seq) {
      const tail = this.sql.exec('SELECT seq, kind, seed FROM epochs WHERE seq > ? ORDER BY seq', from).toArray();
      return { replies: [{ t: 'resync', tail, seq, h, log_len: logLen }], evictOthers: true };
    }
    return { replies: [{ t: 'welcome', seq, h, log_len: logLen, state: meta.state }], evictOthers: true };
  }

  // ------------------------------------------------------------------ log delta checks

  /** Syntactic check of a delta. Returns null when fine, else an internal reason string. */
  _deltaProblem(delta, prevLen, claimedLen) {
    if (!Array.isArray(delta)) return 'delta_not_array';
    if (prevLen + delta.length > MAX_ACTIONS) return 'max_actions';
    if (claimedLen !== prevLen + delta.length) return 'log_len';
    for (const a of delta) {
      if (!a || typeof a !== 'object' || !ALLOWED_FNS.has(a.fn)) return 'fn';
      const args = a.args ?? [];
      if (!Array.isArray(args) || args.length > MAX_PARAMS) return 'args';
      for (const v of args) {
        if (Array.isArray(v)) { if (!v.every(isCanonScalar)) return 'arg_val'; } else if (!isCanonScalar(v)) return 'arg_val';
      }
    }
    return null;
  }

  /** The previous epoch must be consumed by delta[0] (no stacking, ADR 4b) unless it consumes on reply. */
  _consumeProblem(prev, delta) {
    if (!prev) return null;
    const need = KINDS[prev.kind].consume;
    if (!need) return null;
    if (delta.length === 0 || ![].concat(need).includes(delta[0].fn)) return 'unconsumed';
    return null;
  }

  async _verifyChain(meta, prev, delta, claimedH) {
    // The very first epoch (run_start) carries h_0 itself, with no chain step (golden vectors).
    if (!prev) return delta.length === 0 && claimedH === (await chainStart(meta.run_id)) ? claimedH : null;
    const h = await chainNext(prev.h, delta);
    return h === claimedH ? h : null;
  }

  // ------------------------------------------------------------------ epoch_req

  async _epochReq(meta, m) {
    const seq = Number.isInteger(m.seq) ? m.seq : 0;
    const spec = KINDS[m.kind];
    const args = m.args && typeof m.args === 'object' && !Array.isArray(m.args) ? m.args : null;
    if (!spec || !args || !Number.isInteger(m.seq) || m.seq < 0) return fail(seq, 'bad_request');
    const argBad = argsProblem(m.kind, args);
    if (argBad) { this._anomaly('args_rejected', { seq, why: argBad }); return fail(seq, 'bad_request'); }
    const delta = m.log_delta ?? [];

    let digest;
    try { digest = await this._digest(m, delta, args); } catch { return fail(seq, 'bad_request'); }
    const last = this.last();
    const nextSeq = last ? last.seq + 1 : 0; // run_start is seq 0 (lane A golden)

    // Same seq again: identical content gets the old answer, different content gets nothing new.
    if (last && seq <= last.seq) {
      const row = this.sql.exec('SELECT * FROM epochs WHERE seq = ?', seq).toArray()[0];
      if (row && row.req_digest === digest) return this._reply(row);
      this._anomaly('seq_replay_mismatch', { seq });
      return fail(seq, 'rejected');
    }
    if (seq !== nextSeq) return fail(seq, 'out_of_order');
    if (nextSeq >= MAX_EPOCHS) return fail(seq, 'rejected');
    if ((m.kind === 'run_start') !== (seq === 0)) return fail(seq, 'out_of_order');

    const prevLen = last ? last.log_len : 0;
    const bad = this._deltaProblem(delta, prevLen, m.log_len) || this._consumeProblem(last, delta);
    if (bad) { this._anomaly('delta_rejected', { seq, why: bad }); return fail(seq, 'rejected'); }
    const h = await this._verifyChain(meta, last, delta, m.h);
    if (!h) { this._anomaly('chain_mismatch', { seq }); return fail(seq, 'rejected'); }

    // Nonce: either given at creation, or sent exactly once with run_start (ADR 4.1 / C7).
    let nonce = meta.client_nonce;
    if (m.kind === 'run_start') {
      if (!nonce) {
        if (typeof m.client_nonce !== 'string' || !/^[a-f0-9]{32}$/.test(m.client_nonce)) return fail(seq, 'bad_request');
        nonce = m.client_nonce;
        this.sql.exec('UPDATE meta SET client_nonce = ? WHERE id = 1', nonce);
      }
    } else if (!nonce) return fail(seq, 'out_of_order');

    // Attempt counter is the server's, never the client's.
    const attempt = this._attemptFor(m.kind);
    if (args.attempt !== undefined && args.attempt !== attempt) return fail(seq, 'rejected');

    // Paid requests are checked here (cheap, no money moves)...
    let aid = null;
    if (isPaid(m.kind, args)) {
      aid = AID_BY_KIND(m.kind, args);
      if (meta.mode === 'mission' || meta.is_guest || !aid || this._overCap(meta, aid, m.kind, args)) return fail(seq, 'rejected');
    }

    // Reroll: the first request for a key fixes the seed; later requests for it get the same one.
    let pin = null;
    let seed;
    let uids = null;
    if (m.kind === 'reroll') {
      if (!Array.isArray(args.uids)) return fail(seq, 'bad_request');
      uids = args.uids.join(',');
      pin = `${this._battleSeq()}:${attempt}:${args.turn}:${args.k}`;
      const pinned = this.sql.exec('SELECT seed FROM epochs WHERE pin_key = ? ORDER BY seq LIMIT 1', pin).toArray()[0];
      if (pinned) seed = pinned.seed;
    }
    if (seed === undefined) {
      seed = await epochSeed(meta.s_run instanceof Uint8Array ? meta.s_run : new Uint8Array(meta.s_run), {
        run_id: meta.run_id, seq, kind: m.kind, args, h, log_len: m.log_len,
        rules_version: meta.rules_version, attempt, client_nonce: nonce,
      });
    }
    // ...and the money moves LAST, right before the row is written: nothing above can reject after a charge.
    // The idem key carries the aid id, so a resend of the same seq as a different Aid is a different
    // charge and can never ride on the first price. The seq-level replay above already returns the old
    // answer for an identical resend without charging.
    if (aid) {
      // Sample Continue: once per account, A0-A2, elite/boss node, never the tutorial. The claim is the money move.
      let free = false;
      if (aid === 'R1' && this.deps.claimFreeContinue && FREE_CONTINUE.kinds.includes(this._nodeKind(args.node_id, delta))
          && meta.ascension <= FREE_CONTINUE.max_asc && meta.mode !== 'tutorial') {
        try { free = await this.deps.claimFreeContinue(meta, seq); } catch { free = false; }
      }
      if (!free) {
        const ok = await this._charge(meta, seq, aid, args, this._price(aid, args, delta));
        if (!ok) return fail(seq, 'rejected');
      }
    }
    this.sql.exec(
      `INSERT INTO epochs (seq, kind, args, h, log_len, seed, log_delta, attempt, req_digest, pin_key, uids, aid, at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      seq, m.kind, JSON.stringify(args), h, m.log_len, seed, JSON.stringify(delta), attempt, digest, pin, uids, aid, this.deps.now(),
    );
    return { t: 'epoch_res', seq, seed };
  }

  _reply(row) { return { t: 'epoch_res', seq: row.seq, seed: row.seed }; }

  async _digest(m, delta, args) {
    const body = `${m.kind}\n${canonKV({ ...args })}${m.h}\n${m.log_len}\n${JSON.stringify(delta)}`;
    return _bytes.hex(await crypto.subtle.digest('SHA-256', new TextEncoder().encode(body)));
  }

  _battleSeq() {
    const r = this.sql.exec(`SELECT seq FROM epochs WHERE kind = 'node' ORDER BY seq DESC LIMIT 1`).toArray()[0];
    return r ? r.seq : 0;
  }

  /** Continues since the last node epoch (the continue being requested counts itself). */
  _attemptFor(kind) {
    const nodeSeq = this._battleSeq();
    const n = this.sql.exec(`SELECT COUNT(*) AS n FROM epochs WHERE kind = 'continue' AND seq > ?`, nodeSeq).toArray()[0].n;
    return kind === 'continue' ? n + 1 : n;
  }

  /** Per-run caps (ADR 4.9, checked BEFORE charging): per aid, per node for R5, and the total. */
  _overCap(meta, aid, kind, args) {
    const used = (a) => this.sql.exec('SELECT COUNT(*) AS n FROM epochs WHERE aid = ?', a).toArray()[0].n;
    if (used(aid) >= PRICES[aid].cap_run) return true;
    if (kind === 'pact_reroll') {
      const here = this.sql.exec(`SELECT COUNT(*) AS n FROM epochs WHERE aid = 'R5' AND args LIKE ?`, `%"node_id":"${args.node_id}"%`).toArray()[0].n;
      if (here >= 1) return true; // cap_per_pact
    }
    const total = this.sql.exec('SELECT COUNT(*) AS n FROM epochs WHERE aid IS NOT NULL').toArray()[0].n;
    return total >= totalCap(meta.ascension);
  }

  /** Gem price of a paid request. Continue on a boss node costs BOSS_CONTINUE_PRICE; the node kind comes from the
   *  server's own copy of the log (the enter_node line for args.node_id, this request's delta included). */
  _price(aid, args, delta) {
    if (aid !== 'R1') return PRICES[aid].price;
    return this._nodeKind(args.node_id, delta) === 'boss' ? BOSS_CONTINUE_PRICE : PRICES.R1.price;
  }

  /** Node kind ('boss', 'elite', 'battle', ...) from the server's own log copy (the enter_node line for nodeId,
   *  this request's delta included); null when no such line. */
  _nodeKind(nodeId, delta) {
    const find = (d) => {
      if (!Array.isArray(d)) return null;
      const e = d.find((x) => x && x.fn === 'enter_node' && Array.isArray(x.args) && x.args[0] === nodeId);
      return e ? e.args[1] : null;
    };
    const here = find(delta);
    if (here) return here;
    let kind = null;
    for (const r of this.sql.exec('SELECT log_delta FROM epochs').toArray()) {
      let d; try { d = JSON.parse(r.log_delta); } catch { continue; }
      kind = find(d) || kind;
    }
    return kind;
  }

  async _charge(meta, seq, kind, args, price) {
    if (!this.deps.charge) return false; // no wallet wired (L1: pending the Gem decision) = refuse
    const idem = `aid:${meta.run_id}:${seq}:${kind}`;
    this.sql.exec(`INSERT OR REPLACE INTO pending_aid (seq, aid, idem_key, state) VALUES (?, ?, ?, 'charging')`, seq, kind, idem);
    let ok = false;
    try { ok = await this.deps.charge(idem, kind, args, meta, price); } catch { ok = false; }
    this.sql.exec('DELETE FROM pending_aid WHERE seq = ?', seq);
    return ok;
  }

  _anomaly(event, detail) { if (this.deps.log) this.deps.log(event, detail); }

  // ------------------------------------------------------------------ run_close / abandon

  async _runClose(meta, m) {
    const seq = Number.isInteger(m.seq) ? m.seq : 0;
    const last = this.last();
    if (!last) return fail(seq, 'out_of_order');
    if (seq !== last.seq + 1) return fail(seq, 'out_of_order');
    if (m.outcome !== 'won' && m.outcome !== 'lost') return fail(seq, 'bad_request');
    const delta = m.log_delta ?? [];
    const bad = this._deltaProblem(delta, last.log_len, m.log_len) || this._consumeProblem(last, delta);
    if (bad) { this._anomaly('close_rejected', { why: bad }); return fail(seq, 'rejected'); }
    const h = await this._verifyChain(meta, last, delta, m.h);
    if (!h) { this._anomaly('close_chain_mismatch', {}); return fail(seq, 'rejected'); }
    let summary = JSON.stringify(m.summary && typeof m.summary === 'object' && !Array.isArray(m.summary) ? m.summary : {});
    if (summary.length > 2048) summary = '{"truncated":1}'; // never cut JSON mid-way: it must stay parseable
    // The closing delta is kept as the final epochs row (seed 0, kind 'close') so the tape is complete.
    this.sql.exec(
      `INSERT INTO epochs (seq, kind, args, h, log_len, seed, log_delta, attempt, req_digest, at)
       VALUES (?, 'close', '{}', ?, ?, 0, ?, 0, ?, ?)`,
      seq, h, m.log_len, JSON.stringify(delta), h, this.deps.now(),
    );
    // TODO(verifier, P3): state should go 'closing' -> 'closed' after verify. L1 has no verifier.
    this.sql.exec(`UPDATE meta SET state = 'closed', outcome = ?, summary = ? WHERE id = 1`, m.outcome, summary);
    return { t: 'closed', seq };
  }

  /** abandon = loss, no final delta (ADR 4.6). Idempotent. */
  abandon() {
    const meta = this.meta();
    if (!meta) return { ok: false };
    if (meta.state === 'open') this.sql.exec(`UPDATE meta SET state = 'abandoned', outcome = 'lost' WHERE id = 1`);
    return { ok: true, state: this.meta().state };
  }
}
