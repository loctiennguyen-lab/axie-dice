// Gem wallet in D1: balance + append-only ledger with server-built idempotency keys.
// Every change is one DB.batch (a transaction in D1): ledger row first, then the balance update whose
// CHECK(balance >= 0) rolls the whole batch back when funds are short. A duplicate idem_key trips the
// UNIQUE index, rolls back, and is reported as an idempotent replay, never a second charge.
import { shared } from './accounts.js';
import { GIFT, SEASON_GIFT, SEASONS, SEASON_GATES } from './aid_prices.js';

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

/** Grant up to `amount`, clipped so the balance never exceeds `cap`. The clip is computed INSIDE the batch from the
 *  live balance (ledger row and balance update share one transaction), so concurrent claims cannot both read the
 *  same old balance and overshoot. Returns {ok, granted, balance, dup?}; granted 0 = at cap (no ledger row kept). */
export async function grantCapped(env, playerId, amount, cap, reason, idem, at = nowS()) {
  if (!Number.isSafeInteger(amount) || amount < 1 || !Number.isSafeInteger(cap)) return { ok: false, code: 'bad_amount' };
  const first = await replay(env, playerId, idem);
  if (first) return { ...first, granted: 0 };
  try {
    await env.DB.batch([
      env.DB.prepare('INSERT OR IGNORE INTO wallets (player_id, currency, balance) VALUES (?, ?, 0)').bind(playerId, CUR),
      env.DB.prepare(
        `INSERT INTO wallet_ledger (player_id, currency, delta, reason, idem_key, at)
         SELECT player_id, currency, MAX(0, MIN(?, ? - balance)), ?, ?, ? FROM wallets WHERE player_id = ? AND currency = ?`,
      ).bind(amount, cap, reason, idem, at, playerId, CUR),
      env.DB.prepare(
        `UPDATE wallets SET balance = balance + COALESCE((SELECT delta FROM wallet_ledger WHERE player_id = ? AND idem_key = ?), 0)
          WHERE player_id = ? AND currency = ?`,
      ).bind(playerId, idem, playerId, CUR),
    ]);
  } catch (e) {
    if (isUnique(e)) { const d = await replay(env, playerId, idem); return d ? { ...d, granted: 0 } : { ok: false, code: 'error' }; }
    throw e;
  }
  const row = await env.DB.prepare('SELECT delta FROM wallet_ledger WHERE player_id = ? AND idem_key = ?').bind(playerId, idem).first();
  const granted = row ? row.delta : 0;
  if (granted === 0) await env.DB.prepare('DELETE FROM wallet_ledger WHERE player_id = ? AND idem_key = ? AND delta = 0').bind(playerId, idem).run();
  return { ok: true, granted, balance: await balanceOf(env, playerId) };
}

export const spendGem = (env, playerId, n, reason, idem) => applyDelta(env, playerId, -n, reason, idem);

/** Daily gift: min(300, room under the 900 cap), once per UTC day. At the cap the day is NOT used up. */
export async function claimDaily(env, playerId, at = nowS()) {
  const day = utcDay(at);
  const next = (Math.floor(at / 86400) + 1) * 86400;
  const idem = `grant:${playerId}:${day}`;
  const used = await replay(env, playerId, idem);
  if (used) return { ok: false, granted: 0, reason: 'already_claimed', balance: used.balance, next_utc: next };
  const r = await grantCapped(env, playerId, GIFT.per_day, GIFT.balance_cap, 'grant:playtest_grant', idem, at);
  if (!r.ok) return { ok: false, granted: 0, reason: 'error', balance: await balanceOf(env, playerId), next_utc: next };
  if (r.dup) return { ok: false, granted: 0, reason: 'already_claimed', balance: r.balance, next_utc: next };
  if (r.granted === 0) return { ok: false, granted: 0, reason: 'at_cap', balance: r.balance, next_utc: at };
  return { ok: true, granted: r.granted, reason: '', balance: r.balance, next_utc: next };
}

/** Season gift milestone 1 or 2 (pass level 10 / 20). The season id must be in the server SEASONS table (exact
 *  match), the claim must fall in [start, end + grace], milestone 2 needs milestone 1 in the ledger, and each
 *  milestone needs a minimum number of closed runs inside the season window (SEASON_GATES). The grant is
 *  clipped to the room under the shared Gem balance cap. Idempotent per (account, season, milestone). */
export async function claimSeasonGift(env, playerId, seasonId, milestone, at = nowS()) {
  if (typeof seasonId !== 'string' || !Object.hasOwn(SEASONS, seasonId)) return { ok: false, reason: 'bad_request' };
  if (!Number.isSafeInteger(milestone) || milestone < 1 || milestone > SEASON_GIFT.milestones) return { ok: false, reason: 'bad_request' };
  const season = SEASONS[seasonId];
  const start = Date.parse(`${season.start}T00:00:00Z`) / 1000;
  const end = Date.parse(`${season.end}T00:00:00Z`) / 1000 + 86400; // end date inclusive
  if (at < start || at >= end + SEASON_GATES.grace_days * 86400) return { ok: false, granted: 0, reason: 'out_of_season' };
  const idem = (m) => `season:${playerId}:${seasonId}:${m}`;
  const used = await replay(env, playerId, idem(milestone));
  if (used) return { ok: false, granted: 0, reason: 'already_claimed', balance: used.balance };
  if (milestone > 1 && !(await replay(env, playerId, idem(milestone - 1)))) return { ok: false, granted: 0, reason: 'need_previous' };
  const row = await env.DB.prepare(
    `SELECT COUNT(*) AS n FROM runs WHERE player_id = ? AND state = 'closed' AND battles_done >= ? AND closed_at >= ? AND closed_at < ?`,
  ).bind(playerId, SEASON_GATES.min_battles, start, end).first();
  if (((row && row.n) || 0) < SEASON_GATES.min_runs[milestone]) return { ok: false, granted: 0, reason: 'not_enough_runs' };
  const r = await grantCapped(env, playerId, SEASON_GIFT.per_milestone, SEASON_GATES.balance_cap, 'grant:season_gift', idem(milestone), at);
  if (!r.ok) return { ok: false, reason: 'error' };
  if (r.dup) return { ok: false, granted: 0, reason: 'already_claimed', balance: r.balance };
  if (r.granted === 0) return { ok: false, granted: 0, reason: 'at_cap', balance: r.balance };
  return { ok: true, granted: r.granted, reason: '', balance: r.balance };
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
