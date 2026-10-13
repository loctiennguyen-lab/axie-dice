// RunDO: one Durable Object per run. Thin shell over RunCore (src/run_core.js): it owns the sockets,
// the SQLite handle and the D1 write-back, the rules live in RunCore. The class name `RunDO` is
// frozen: renaming a Durable Object class needs a migration that cannot be rolled back safely.
//
// Hibernation rules (ADR 4.6 F12): nothing lives in memory that cannot be rebuilt from SQLite, no
// setTimeout/setInterval, only alarm(), and ping/pong goes through setWebSocketAutoResponse so a
// keep-alive does not wake the object.
import { RunCore } from './run_core.js';
import { verifyRunToken } from './run_token.js';
import { spendGem, claimFreeContinue } from './wallet.js';
import { PRICES } from './aid_prices.js';

// Rule versions this build can still serve (ADR 4.6 bye{version}). THE one place to bump: add the new
// ActionLog.RULES_VERSION (godot/scripts/core/action_log.gd) here at every bump; test/rules_supported.test.mjs
// fails if the client's current value is missing. The Worker only checks the hash chain, it never runs game
// rules (run_core.js header), so accepting a version needs no Worker rule change.
export const SUPPORTED_RULE_VERSIONS = ['godot-2026-09-21-a', 'godot-2026-10-13-j', 'godot-2026-10-13-k'];
export const SUPPORTED_RULES = new Set(SUPPORTED_RULE_VERSIONS);

const json = (body, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } });

/** Whether this build still serves a rules version (env var SUPPORTED_RULES overrides the default). */
export const rulesSupported = (env, v) =>
  (env.SUPPORTED_RULES ? env.SUPPORTED_RULES.split(',').includes(v) : SUPPORTED_RULES.has(v));

/** A socket that has not sent a valid hello within this long is closed by alarm() (ADR F12: alarm is the only timer). */
export const HELLO_DEADLINE_MS = 10_000;

export class RunDO {
  constructor(ctx, env) {
    this.ctx = ctx;
    this.env = env;
    RunCore.initSchema(ctx.storage.sql);
    this.core = new RunCore(ctx.storage.sql, {
      verifyToken: (t) => verifyRunToken(env, t),
      checkHello: async (claims) => {
        if (!env.DB || !claims.jti) return false;
        const row = await env.DB.prepare(
          `SELECT r.token_jti, p.locked_at FROM runs r JOIN players p ON p.id = r.player_id WHERE r.run_id = ? AND r.player_id = ?`,
        ).bind(claims.run_id, claims.player_id).first();
        return !!row && row.locked_at == null && row.token_jti === claims.jti;
      },
      supportsRules: (v) => rulesSupported(env, v),
      // Gem is charged in D1 inside the request that earns the seed (ADR 4.9). The idem key is built by
      // RunCore as aid:{run}:{seq}, so a retried request replays the old charge instead of paying twice.
      charge: async (idem, aid, _args, meta, price) => {
        const amount = price ?? (PRICES[aid] && PRICES[aid].price);
        if (!Number.isSafeInteger(amount) || amount < 1) return false; // fail closed: never charge an undefined price
        const r = await spendGem(env, meta.player_id, amount, `aid:${aid}`, idem);
        return r.ok;
      },
      claimFreeContinue: (meta, seq) => claimFreeContinue(env, meta.player_id, meta.run_id, seq),
      log: (event, detail) => console.warn('run anomaly', event, JSON.stringify(detail)),
    });
    if (typeof WebSocketRequestResponsePair !== 'undefined') {
      ctx.setWebSocketAutoResponse(new WebSocketRequestResponsePair('ping', 'pong'));
    }
  }

  async fetch(request) {
    const url = new URL(request.url);
    if (request.method === 'POST' && url.pathname === '/init') {
      const out = await this.core.init(await request.json());
      return json(out, out.ok ? 200 : 409);
    }
    if (request.method === 'POST' && url.pathname === '/abandon') {
      const out = this.core.abandon();
      return json(out, out.ok ? 200 : 404);
    }
    if (request.headers.get('Upgrade') === 'websocket') {
      const pair = new WebSocketPair();
      this.ctx.acceptWebSocket(pair[1]);
      pair[1].serializeAttachment({ authed: false, epoch: 0, at: Date.now() });
      const existing = await this.ctx.storage.getAlarm();
      const want = Date.now() + HELLO_DEADLINE_MS;
      if (existing == null || existing > want) await this.ctx.storage.setAlarm(want);
      return new Response(null, { status: 101, webSocket: pair[0] });
    }
    return json({ error: 'not_found' }, 404);
  }

  async webSocketMessage(ws, message) {
    const out = await this.core.handle(null, typeof message === 'string' ? message : '', {
      load: () => ws.deserializeAttachment(),
      save: (c) => ws.serializeAttachment(c),
    });
    for (const r of out.replies) ws.send(JSON.stringify(r));
    if (out.evictOthers) {
      for (const other of this.ctx.getWebSockets()) {
        if (other === ws) continue;
        try { other.send(JSON.stringify({ t: 'bye', reason: 'other_device' })); other.close(4000, 'other_device'); } catch { /* already gone */ }
      }
    }
    if (out.close) ws.close(out.close.code, out.close.reason);
    if (out.replies.some((r) => r.t === 'closed')) await this._syncClosed();
  }

  async webSocketClose(ws, code, reason) { try { ws.close(code, reason); } catch { /* already closed */ } }
  async webSocketError(ws) { try { ws.close(1011, 'error'); } catch { /* already closed */ } }

  /** Write the closed run back to D1; on failure retry from alarm() (the only timer a DO may use). */
  async _syncClosed() {
    const meta = this.core.meta();
    if (!meta || !this.env.DB || meta.state !== 'closed' || meta.outcome == null) return; // never touch an open run
    try {
      let s = {};
      try { s = JSON.parse(meta.summary || '{}'); } catch { s = {}; }
      if (!s || typeof s !== 'object' || Array.isArray(s)) s = {};
      // What the server itself saw (epoch log), next to the client's claim: Aid ids actually charged, in order.
      // Not trusted from the client, and no migration: reports read it with json_extract(summary_json, '$.srv.aids').
      let srv = { aids: [] };
      try { srv = { aids: this.core.sql.exec('SELECT aid FROM epochs WHERE aid IS NOT NULL ORDER BY seq').toArray().map((r) => r.aid) }; } catch { /* keep empty */ }
      const merged = JSON.stringify({ ...s, srv });
      await this.env.DB.prepare(
        `UPDATE runs SET state = 'closed', outcome = ?, closed_at = ?, battles_done = ?, summary_json = ?
          WHERE run_id = ? AND state = 'open'`,
      ).bind(meta.outcome, Math.floor(Date.now() / 1000), Number.isInteger(s.battles_done) && s.battles_done >= 0 && s.battles_done <= 500 ? s.battles_done : 0, merged, meta.run_id).run();
    } catch (err) {
      console.error('run close sync failed', String(err));
      await this.ctx.storage.setAlarm(Date.now() + 30_000);
    }
  }

  async alarm() {
    const m = this.core.meta();
    if (m && m.state === 'closed') await this._syncClosed();
    // Close sockets that never said hello; re-arm for the youngest one still waiting.
    const now = Date.now();
    let next = null;
    for (const ws of this.ctx.getWebSockets()) {
      let att = null;
      try { att = ws.deserializeAttachment(); } catch { /* unreadable = treat as unauthed */ }
      if (att && att.authed) continue;
      const due = ((att && att.at) || 0) + HELLO_DEADLINE_MS;
      if (due <= now) { try { ws.close(1008, 'no_hello'); } catch { /* already gone */ } } else if (next === null || due < next) next = due;
    }
    if (next !== null) await this.ctx.storage.setAlarm(next);
  }
}
