// Gem wallet in D1: balance + append-only ledger with server-built idempotency keys.
// Every change is one DB.batch (a transaction in D1): ledger row first, then the balance update whose
// CHECK(balance >= 0) rolls the whole batch back when funds are short. A duplicate idem_key trips the
// UNIQUE index, rolls back, and is reported as an idempotent replay, never a second charge.
import { shared } from './accounts.js';
import { GIFT, SEASON_GIFT } from './aid_prices.js';

const { json } = shared;
const CUR = 'gem';
const nowS = () => Math.floor(Date.now() / 1000);
const utcDay = (s) => new Date(s * 1000).toISOString().slice(0, 10);

export async function balanceOf(env, playerId) {
  const r = await env.DB.prepare('SELECT balance FROM wallets WHERE player_id = ? AND currency = ?').bind(playerId, CUR).first();
  return r ? r.balance : 0;
}

const isUnique = (e) => /UNIQUE/i.test(String((e && e.message) || e));

async function replay(env, playerId, idem) {
  const row = await env.DB.prepare('SELECT delta FROM wallet_ledger WHERE player_id = ? AND idem_key = ?').bind(playerId, idem).first();
  return row ? { ok: true, dup: true, delta: row.delta, balance: await balanceOf(env, playerId) } : null;
}

/** Apply delta (+grant / -spend). Returns {ok, balance, dup?} or {ok:false, code:'insufficient'|'error'}. */
export async function applyDelta(env, playerId, delta, reason, idem, at = nowS()) {
  if (!Number.isSafeInteger(delta) || delta === 0) return { ok: false, code: 'bad_amount' };
  const first = await replay(env, playerId, idem);
  if (first) return first;
  try {
    await env.DB.batch([
      env.DB.prepare('INSERT OR IGNORE INTO wallets (player_id, currency, balance) VALUES (?, ?, 0)').bind(playerId, CUR),
      env.DB.prepare('INSERT INTO wallet_ledger (player_id, currency, delta, reason, idem_key, at) VALUES (?, ?, ?, ?, ?, ?)')
        .bind(playerId, CUR, delta, reason, idem, at),
      env.DB.prepare('UPDATE wallets SET balance = balance + ? WHERE player_id = ? AND currency = ?').bind(delta, playerId, CUR),
    ]);
  } catch (e) {
    if (isUnique(e)) return (await replay(env, playerId, idem)) || { ok: false, code: 'error' };
    if (/CHECK/i.test(String(e && e.message || e))) return { ok: false, code: 'insufficient' };
    throw e;
  }
  return { ok: true, balance: await balanceOf(env, playerId) };
}

export const spendGem = (env, playerId, n, reason, idem) => applyDelta(env, playerId, -n, reason, idem);

/** Daily gift: min(300, room under the 900 cap), once per UTC day. At the cap the day is NOT used up. */
export async function claimDaily(env, playerId, at = nowS()) {
  const day = utcDay(at);
  const next = (Math.floor(at / 86400) + 1) * 86400;
  const idem = `grant:${playerId}:${day}`;
  const used = await replay(env, playerId, idem);
  if (used) return { ok: false, granted: 0, reason: 'already_claimed', balance: used.balance, next_utc: next };
  const bal = await balanceOf(env, playerId);
  const room = GIFT.balance_cap - bal;
  if (room <= 0) return { ok: false, granted: 0, reason: 'at_cap', balance: bal, next_utc: at };
  const amount = Math.min(GIFT.per_day, room);
  const r = await applyDelta(env, playerId, amount, 'grant:playtest_grant', idem, at);
  if (!r.ok) return { ok: false, granted: 0, reason: 'error', balance: bal, next_utc: next };
  if (r.dup) return { ok: false, granted: 0, reason: 'already_claimed', balance: r.balance, next_utc: next };
  return { ok: true, granted: amount, reason: '', balance: r.balance, next_utc: next };
}

/** Season gift milestone 1 or 2 (pass level 10 / 20). Idempotent per (account, season, milestone) through the
 *  ledger idem key, so at most 2 x 90 Gem per season. The pass level itself is client state (L1); the cap is the guard. */
export async function claimSeasonGift(env, playerId, seasonId, milestone, at = nowS()) {
  if (typeof seasonId !== 'string' || !/^[A-Za-z0-9_-]{1,24}$/.test(seasonId)) return { ok: false, reason: 'bad_request' };
  if (!Number.isSafeInteger(milestone) || milestone < 1 || milestone > SEASON_GIFT.milestones) return { ok: false, reason: 'bad_request' };
  const r = await applyDelta(env, playerId, SEASON_GIFT.per_milestone, 'grant:season_gift', `season:${playerId}:${seasonId}:${milestone}`, at);
  if (!r.ok) return { ok: false, reason: 'error' };
  if (r.dup) return { ok: false, granted: 0, reason: 'already_claimed', balance: r.balance };
  return { ok: true, granted: SEASON_GIFT.per_milestone, reason: '', balance: r.balance };
}

export const isWalletPath = (p) => p === '/api/gem/season_gift' || p === '/api/wallet' || p === '/api/gem/claim' || p === '/api/wallet/spend';
const MAX_SPEND = 5000;

export async function handleWallet(request, env, url) {
  try {
    const player = await shared.currentPlayer(request, env);
    if (!player) return json({ error: 'unauthenticated' }, 401);
    // Per player, not per IP: shared IPs (offices, CGNAT) must not eat each other's budget. SAVE_LIMITER
    // is reused so the Free plan needs no extra binding; a missing binding (tests, dev) means no limit.
    if (env.SAVE_LIMITER) {
      const { success } = await env.SAVE_LIMITER.limit({ key: `w:${player.id}` });
      if (!success) return json({ error: 'rate_limited' }, 429);
    }
    if (url.pathname === '/api/wallet' && request.method === 'GET') {
      const tail = await env.DB.prepare('SELECT delta, reason, at FROM wallet_ledger WHERE player_id = ? ORDER BY id DESC LIMIT 20').bind(player.id).all();
      return json({ gem: await balanceOf(env, player.id), ledger_tail: tail.results });
    }
    if (url.pathname === '/api/gem/claim' && request.method === 'POST') {
      const o = request.headers.get('Origin');
      if (o && !shared.isAllowedOrigin(o, url)) return json({ error: 'forbidden' }, 403);
      return json(await claimDaily(env, player.id));
    }
    if (url.pathname === '/api/gem/season_gift' && request.method === 'POST') {
      const o = request.headers.get('Origin');
      if (o && !shared.isAllowedOrigin(o, url)) return json({ error: 'forbidden' }, 403);
      let b;
      try { const txt = await request.text(); b = txt.length <= 256 ? JSON.parse(txt) : null; } catch { b = null; }
      if (!b) return json({ error: 'bad_request' }, 400);
      const r = await claimSeasonGift(env, player.id, b.season_id, b.milestone);
      return json(r, r.reason === 'bad_request' ? 400 : 200);
    }
    if (url.pathname === '/api/wallet/spend' && request.method === 'POST') {
      // Store purchases (tickets, cosmetics). The player can only ever lose their OWN Gem here; what the
      // purchase grants is still client-side in L1 (goods are not on the server yet).
      const o = request.headers.get('Origin');
      if (o && !shared.isAllowedOrigin(o, url)) return json({ error: 'forbidden' }, 403);
      let b;
      try { const txt = await request.text(); b = txt.length <= 1024 ? JSON.parse(txt) : null; } catch { b = null; }
      if (!b || !Number.isSafeInteger(b.amount) || b.amount < 1 || b.amount > MAX_SPEND
        || typeof b.reason !== 'string' || !/^[a-z0-9_:.-]{1,48}$/.test(b.reason)
        || typeof b.idem !== 'string' || !/^[A-Za-z0-9_-]{8,64}$/.test(b.idem)) return json({ error: 'bad_request' }, 400);
      const r = await spendGem(env, player.id, b.amount, `spend:${b.reason}`, `spend:${b.idem}`);
      return json(r.ok ? { ok: true, balance: r.balance, dup: !!r.dup } : { ok: false, code: r.code, balance: await balanceOf(env, player.id) }, r.ok ? 200 : 402);
    }
    return json({ error: 'not_found' }, 404);
  } catch (err) {
    console.error('wallet error', String(err && err.stack || err));
    return json({ error: 'server' }, 500);
  }
}
