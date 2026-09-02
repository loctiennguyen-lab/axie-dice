/**
 * POST /api/auth — register/login for player accounts (design/gdd/player-accounts.md,
 * docs/architecture/adr-0002-player-accounts.md). Reuses the Vercel Functions +
 * Upstash Redis infra ADR-0001 introduced; see api/leaderboard.js / api/submit-run.js
 * for the identical upstash() REST helper this file copies verbatim.
 *
 * Body: {action: 'register'|'login', username, password, meta?}. `meta` is only read
 * on 'register' — the client's current local META becomes the account's first cloud
 * save (GDD §3 Registration), so no data is lost going from guest to account.
 */
const crypto = require('crypto');
const { hashPassword, verifyPassword, signToken } = require('./_auth');

const USERNAME_RE = /^[a-z0-9_]{3,20}$/;
const MIN_PASSWORD_LEN = 8;
// Generous vs. a real META's size (comparable to the localStorage copy already
// shipping, per ADR-0002 Performance Implications) — bounds Redis storage abuse
// from a malicious/broken client, not a real gameplay constraint.
const MAX_META_BYTES = 512 * 1024;

async function upstash(...args) {
  const url = process.env.UPSTASH_REDIS_REST_URL;
  const token = process.env.UPSTASH_REDIS_REST_TOKEN;
  if (!url || !token) return null;
  const r = await fetch(url + '/' + args.map(encodeURIComponent).join('/'), {
    headers: { Authorization: 'Bearer ' + token },
  });
  return r.json();
}

// Per-IP rate limit, same in-memory pattern as api/axie.js. Lower ceiling than the
// read-only axie proxy — credential-stuffing/brute-force is the concrete risk here
// (ADR-0002 Risks: "Brute-force / credential-stuffing against api/auth.js").
const RATE_LIMIT_WINDOW_MS = 60_000;
const RATE_LIMIT_MAX = 10;
const hits = new Map();
function isRateLimited(ip) {
  const now = Date.now();
  const arr = (hits.get(ip) || []).filter((t) => now - t < RATE_LIMIT_WINDOW_MS);
  arr.push(now);
  hits.set(ip, arr);
  return arr.length > RATE_LIMIT_MAX;
}

const NOT_CONFIGURED = { ok: false, error: 'Accounts are not configured on this server yet' };
const INVALID_CREDS = { ok: false, error: 'Invalid username or password' };

// Telemetry piggyback (docs/architecture/telemetry-dashboard-design.md §3):
// account.created/session.login ride these existing handlers for free — no
// extra client round trip. Best-effort only: a failure here must never block
// login/register, so errors are swallowed, never awaited into the response path.
function todayUTC() { return new Date().toISOString().slice(0, 10); }
function recordTelemetry(username, kind) {
  const day = todayUTC();
  const dauKey = 'tel:dau:' + day;
  Promise.all([
    upstash('sadd', 'tel:players', username),
    upstash('sadd', dauKey, username),
    upstash('expire', dauKey, String(90 * 24 * 60 * 60)),
    upstash('hincrby', 'tel:totals', kind === 'register' ? 'accounts_created' : 'logins', '1'),
    upstash('hincrby', 'tel:d:' + day, kind === 'register' ? 'accounts_created' : 'logins', '1'),
  ]).catch(() => {});
}

module.exports = async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  res.setHeader('Content-Type', 'application/json');
  if (req.method === 'OPTIONS') { res.status(200).end(); return; }
  if (req.method !== 'POST') { res.status(405).json({ ok: false, error: 'Method not allowed' }); return; }

  const ip = (req.headers['x-forwarded-for'] || '').split(',')[0].trim() || 'unknown';
  if (isRateLimited(ip)) { res.status(429).json({ ok: false, error: 'Too many requests, try again in a minute.' }); return; }

  const secret = process.env.AUTH_JWT_SECRET;
  if (!secret) { res.status(200).json(NOT_CONFIGURED); return; }

  let body = req.body;
  if (typeof body === 'string') { try { body = JSON.parse(body); } catch (e) { res.status(400).json({ ok: false, error: 'Invalid JSON' }); return; } }
  if (!body || typeof body !== 'object') { res.status(400).json({ ok: false, error: 'Missing body' }); return; }

  const { action } = body;
  const username = typeof body.username === 'string' ? body.username.toLowerCase() : '';
  const password = typeof body.password === 'string' ? body.password : '';

  if (action !== 'register' && action !== 'login') { res.status(400).json({ ok: false, error: 'action must be register or login' }); return; }
  if (!USERNAME_RE.test(username)) { res.status(400).json({ ok: false, error: 'Username must be 3-20 characters: lowercase letters, numbers, underscore only' }); return; }
  if (password.length < MIN_PASSWORD_LEN) { res.status(400).json({ ok: false, error: 'Password must be at least 8 characters' }); return; }

  const userKey = 'user:' + username;

  if (action === 'register') {
    const existing = await upstash('get', userKey);
    if (existing === null) { res.status(200).json(NOT_CONFIGURED); return; }
    if (existing.result) { res.status(200).json({ ok: false, error: 'Username taken' }); return; }

    const meta = body.meta && typeof body.meta === 'object' ? body.meta : {};
    meta.savedAt = Date.now(); // server-stamped, same rule sync-save.js uses (ADR-0002)
    const serialized = JSON.stringify(meta);
    if (Buffer.byteLength(serialized, 'utf8') > MAX_META_BYTES) { res.status(400).json({ ok: false, error: 'Save data too large' }); return; }

    const salt = crypto.randomBytes(16).toString('hex');
    const hash = await hashPassword(password, salt);
    const record = { username, salt, hash, createdAt: Date.now() };
    await upstash('set', userKey, JSON.stringify(record));
    // Current local META becomes the account's first cloud save (GDD §3 Registration).
    await upstash('set', 'save:' + username, serialized);

    const token = signToken(username, secret);
    recordTelemetry(username, 'register');
    res.status(200).json({ ok: true, token, username });
    return;
  }

  // action === 'login' — same generic response on any failure, no username-enumeration
  // hint (ADR-0002 Key Interfaces / GDD Edge Cases).
  const rec = await upstash('get', userKey);
  if (rec === null) { res.status(200).json(NOT_CONFIGURED); return; }
  if (!rec.result) { res.status(200).json(INVALID_CREDS); return; }

  let record;
  try { record = JSON.parse(rec.result); } catch (e) { res.status(200).json(INVALID_CREDS); return; }
  if (!record || typeof record.salt !== 'string' || typeof record.hash !== 'string') { res.status(200).json(INVALID_CREDS); return; }

  const valid = await verifyPassword(password, record.salt, record.hash);
  if (!valid) { res.status(200).json(INVALID_CREDS); return; }

  const token = signToken(username, secret);
  recordTelemetry(username, 'login');
  res.status(200).json({ ok: true, token, username });
};
