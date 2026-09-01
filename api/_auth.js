/**
 * Shared, non-route helpers for player accounts (design/gdd/player-accounts.md,
 * docs/architecture/adr-0002-player-accounts.md). Not a route itself — Vercel
 * ignores files starting with `_`, same convention as api/_engine.js. Used by
 * api/auth.js (register/login, hashes/verifies passwords, signs tokens) and
 * api/sync-save.js (verifies tokens on every request) so the scrypt hashing
 * and HMAC token logic lives in exactly one place instead of being duplicated.
 */
const crypto = require('crypto');
const { promisify } = require('util');
const scrypt = promisify(crypto.scrypt);

// 30-day session expiry (design/gdd/player-accounts.md §3 Login, ADR-0002 Decision).
const TOKEN_TTL_MS = 30 * 24 * 60 * 60 * 1000;

/** crypto.scrypt(password, salt, 64) per ADR-0002 §Formulas — never store the raw password. */
async function hashPassword(password, salt) {
  const buf = await scrypt(password, salt, 64);
  return buf.toString('hex');
}

/** Constant-time compare via crypto.timingSafeEqual — mismatched lengths must not throw. */
async function verifyPassword(password, salt, storedHashHex) {
  const candidateHex = await hashPassword(password, salt);
  const a = Buffer.from(candidateHex, 'hex');
  const b = Buffer.from(String(storedHashHex), 'hex');
  if (a.length !== b.length) return false;
  return crypto.timingSafeEqual(a, b);
}

function b64url(buf) {
  return Buffer.from(buf).toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}
function b64urlToBuf(str) {
  let s = String(str).replace(/-/g, '+').replace(/_/g, '/');
  while (s.length % 4) s += '=';
  return Buffer.from(s, 'base64');
}

/**
 * Stateless signed session token: base64url(JSON payload) + '.' + base64url(HMAC-SHA256
 * digest of the payload segment). Not JWT-spec-compliant, just self-verifiable — avoids
 * a server-side session store / extra Redis round-trip per request (ADR-0002 Decision).
 */
function signToken(username, secret) {
  const payload = JSON.stringify({ u: username, exp: Date.now() + TOKEN_TTL_MS });
  const payloadB64 = b64url(Buffer.from(payload, 'utf8'));
  const sig = crypto.createHmac('sha256', secret).update(payloadB64).digest();
  return payloadB64 + '.' + b64url(sig);
}

/** Verifies signature (constant-time) and expiry. Returns {username} or null — never throws. */
function verifyToken(token, secret) {
  if (typeof token !== 'string' || !token) return null;
  const idx = token.lastIndexOf('.');
  if (idx <= 0) return null;
  const payloadB64 = token.slice(0, idx);
  const sigB64 = token.slice(idx + 1);

  let expectedSig, givenSig;
  try {
    expectedSig = crypto.createHmac('sha256', secret).update(payloadB64).digest();
    givenSig = b64urlToBuf(sigB64);
  } catch (e) {
    return null;
  }
  if (givenSig.length !== expectedSig.length) return null;
  if (!crypto.timingSafeEqual(givenSig, expectedSig)) return null;

  let payload;
  try { payload = JSON.parse(b64urlToBuf(payloadB64).toString('utf8')); } catch (e) { return null; }
  if (!payload || typeof payload.u !== 'string' || typeof payload.exp !== 'number') return null;
  if (Date.now() > payload.exp) return null;

  return { username: payload.u };
}

module.exports = { hashPassword, verifyPassword, signToken, verifyToken };
