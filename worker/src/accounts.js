// Accounts: Google sign-in, sessions and cloud saves (claude/ACCOUNT_SYSTEM_v1.md §4-§5).
//
//   GET  /auth/login[?return=<url>][&switch=1]  -> Google consent (authorization code + PKCE)
//   GET  /auth/callback                         <- Google; creates the profile on first sign-in
//   POST /auth/logout                           ends this device's session
//   GET  /api/me                                who is signed in, or 401
//   GET  /api/save                              { rev, meta, run, updated_at }
//   PUT  /api/save  { rev, meta?, run? }        write if `rev` is still current, else 409
//
// The code is exchanged here, with the client secret, so no token ever reaches the page. The
// browser only ever holds an HttpOnly session cookie.
//
// Bindings: DB (D1). Vars: GOOGLE_CLIENT_ID, PUBLIC_ORIGIN (optional). Secrets:
// GOOGLE_CLIENT_SECRET, SESSION_SIGNING_KEY.

const GOOGLE_AUTH = 'https://accounts.google.com/o/oauth2/v2/auth';
const GOOGLE_TOKEN = 'https://oauth2.googleapis.com/token';
const GOOGLE_JWKS = 'https://www.googleapis.com/oauth2/v3/certs';
const GOOGLE_ISSUERS = ['https://accounts.google.com', 'accounts.google.com'];

// The only redirect URI registered with Google is on the apex domain, so sign-in always runs
// there. Cookies carry Domain=axiedice.fun so a player who opened www.axiedice.fun is signed in
// on www as well.
const DEFAULT_ORIGIN = 'https://axiedice.fun';
const COOKIE_DOMAIN = 'axiedice.fun';

const SESSION_COOKIE = 'ad_session';
const OAUTH_COOKIE = 'ad_oauth';
const SESSION_TTL_S = 30 * 24 * 3600;
const OAUTH_TTL_S = 10 * 60;
const CLOCK_SKEW_S = 60;
// A meta save with a full 20-Axie vault is ~30 KB. The cap only exists to refuse junk.
const MAX_SAVE_BYTES = 512 * 1024;
const JWKS_MAX_AGE_MS = 6 * 3600 * 1000;

import { parseDesktopLogin, loopbackUrl, issueDesktopCode, bearerPlayer, DESKTOP_ROUTES } from './desktop_auth.js';

const enc = new TextEncoder();
const now = () => Math.floor(Date.now() / 1000);

// ---------------------------------------------------------------- encoding + crypto helpers

function b64url(bytes) {
  let s = '';
  const arr = bytes instanceof Uint8Array ? bytes : new Uint8Array(bytes);
  for (let i = 0; i < arr.length; i++) s += String.fromCharCode(arr[i]);
  return btoa(s).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function b64urlDecode(str) {
  const s = str.replace(/-/g, '+').replace(/_/g, '/');
  const bin = atob(s + '==='.slice((s.length + 3) % 4));
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}

const b64urlJson = (obj) => b64url(enc.encode(JSON.stringify(obj)));
const parseB64urlJson = (str) => JSON.parse(new TextDecoder().decode(b64urlDecode(str)));

function randomToken(bytes = 32) {
  return b64url(crypto.getRandomValues(new Uint8Array(bytes)));
}

async function sha256b64url(text) {
  return b64url(await crypto.subtle.digest('SHA-256', enc.encode(text)));
}

async function hmacKey(env) {
  if (!env.SESSION_SIGNING_KEY) throw new Error('SESSION_SIGNING_KEY is not set');
  return crypto.subtle.importKey(
    'raw', enc.encode(env.SESSION_SIGNING_KEY), { name: 'HMAC', hash: 'SHA-256' }, false,
    ['sign', 'verify'],
  );
}

async function signValue(env, payload) {
  const body = b64urlJson(payload);
  const sig = await crypto.subtle.sign('HMAC', await hmacKey(env), enc.encode(body));
  return `${body}.${b64url(sig)}`;
}

/** The payload if the signature is ours and it has not expired, otherwise null. */
async function verifyValue(env, value) {
  if (!value || value.indexOf('.') < 0) return null;
  const [body, sig] = value.split('.');
  let ok = false;
  try {
    // subtle.verify compares in constant time; a string compare of two MACs would not.
    ok = await crypto.subtle.verify('HMAC', await hmacKey(env), b64urlDecode(sig), enc.encode(body));
  } catch {
    return null;
  }
  if (!ok) return null;
  const payload = parseB64urlJson(body);
  if (typeof payload.exp !== 'number' || payload.exp < now()) return null;
  return payload;
}

// ---------------------------------------------------------------- origins + cookies

const publicOrigin = (env) => env.PUBLIC_ORIGIN || DEFAULT_ORIGIN;
const isOurHost = (host) => host === COOKIE_DOMAIN || host.endsWith('.' + COOKIE_DOMAIN);

/** Origins a page may call us from, and that a post-login redirect may go back to. */
function isAllowedOrigin(origin, url) {
  if (!origin) return false;
  if (origin === url.origin) return true;
  try {
    const o = new URL(origin);
    return o.protocol === 'https:' && isOurHost(o.hostname) && o.port === '';
  } catch {
    return false;
  }
}

/**
 * Where to send the player after sign-in. Only our own origins, so /auth/login can never be
 * used as an open redirect.
 */
function safeReturnTo(raw, url, env) {
  const fallback = `${isOurHost(url.hostname) ? publicOrigin(env) : url.origin}/`;
  if (!raw) return fallback;
  try {
    const target = new URL(raw, url.origin);
    if (!isAllowedOrigin(target.origin, url)) return fallback;
    target.hash = '';
    target.searchParams.delete('auth');
    target.searchParams.delete('auth_error');
    return target.toString();
  } catch {
    return fallback;
  }
}

function withParam(target, key, value) {
  const u = new URL(target);
  u.searchParams.set(key, value);
  return u.toString();
}

function readCookie(request, name) {
  const header = request.headers.get('Cookie') || '';
  for (const part of header.split(';')) {
    const i = part.indexOf('=');
    if (i < 0) continue;
    if (part.slice(0, i).trim() === name) return part.slice(i + 1).trim();
  }
  return null;
}

function cookie(name, value, url, { maxAge, path = '/' }) {
  let c = `${name}=${value}; Path=${path}; Max-Age=${maxAge}; HttpOnly; SameSite=Lax`;
  if (url.protocol === 'https:') c += '; Secure';
  if (isOurHost(url.hostname)) c += `; Domain=${COOKIE_DOMAIN}`;
  return c;
}

// ---------------------------------------------------------------- responses

const NO_STORE = {
  'Cache-Control': 'no-store',
  'Cross-Origin-Resource-Policy': 'same-origin',
  'X-Content-Type-Options': 'nosniff',
};

function json(body, status = 200, extra = {}) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json; charset=utf-8', ...NO_STORE, ...extra },
  });
}

function redirect(location, cookies = []) {
  const headers = new Headers({ Location: location, ...NO_STORE });
  for (const c of cookies) headers.append('Set-Cookie', c);
  return new Response(null, { status: 302, headers });
}

const methodNotAllowed = (allow) => json({ error: 'method_not_allowed' }, 405, { Allow: allow });

// ---------------------------------------------------------------- Google ID token

let jwksCache = { keys: null, at: 0 };

async function googleKey(kid) {
  const fresh = Date.now() - jwksCache.at < JWKS_MAX_AGE_MS;
  let jwk = fresh && jwksCache.keys ? jwksCache.keys.find((k) => k.kid === kid) : null;
  if (!jwk) {
    // Google rotates keys; an unknown kid means refetch before deciding the token is bad.
    const res = await fetch(GOOGLE_JWKS);
    if (!res.ok) throw new Error(`jwks ${res.status}`);
    const body = await res.json();
    jwksCache = { keys: body.keys || [], at: Date.now() };
    jwk = jwksCache.keys.find((k) => k.kid === kid);
  }
  if (!jwk) throw new Error('unknown signing key');
  return crypto.subtle.importKey(
    'jwk', jwk, { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['verify'],
  );
}

/** The claims if the token is genuine, for this app, current, and carries our nonce. */
async function verifyIdToken(idToken, env, expectedNonce) {
  const parts = String(idToken || '').split('.');
  if (parts.length !== 3) throw new Error('malformed token');
  const header = parseB64urlJson(parts[0]);
  if (header.alg !== 'RS256') throw new Error('unexpected alg');
  const key = await googleKey(header.kid);
  const signed = enc.encode(`${parts[0]}.${parts[1]}`);
  if (!(await crypto.subtle.verify('RSASSA-PKCS1-v1_5', key, b64urlDecode(parts[2]), signed))) {
    throw new Error('bad signature');
  }
  const c = parseB64urlJson(parts[1]);
  const t = now();
  if (!GOOGLE_ISSUERS.includes(c.iss)) throw new Error('bad issuer');
  const aud = Array.isArray(c.aud) ? c.aud : [c.aud];
  if (!aud.includes(env.GOOGLE_CLIENT_ID)) throw new Error('bad audience');
  if (typeof c.exp !== 'number' || c.exp + CLOCK_SKEW_S < t) throw new Error('expired');
  if (typeof c.iat === 'number' && c.iat - CLOCK_SKEW_S > t) throw new Error('issued in future');
  if (!expectedNonce || c.nonce !== expectedNonce) throw new Error('bad nonce');
  if (typeof c.sub !== 'string' || !c.sub) throw new Error('no subject');
  return c;
}

// ---------------------------------------------------------------- sessions

async function currentPlayer(request, env) {
  // A Bearer header decides alone: an invalid one is signed-out, the cookie is never consulted.
  const bearer = await bearerPlayer(request, env);
  if (bearer !== null) return bearer || null;
  const token = readCookie(request, SESSION_COOKIE);
  if (!token) return null;
  const row = await env.DB.prepare(
    `SELECT p.id, p.email, p.display_name, p.hd
       FROM sessions s JOIN players p ON p.id = s.player_id
      WHERE s.id_hash = ? AND s.expires_at > ?`,
  ).bind(await sha256b64url(token), now()).first();
  return row || null;
}

const publicPlayer = (p) => ({
  id: p.id,
  email: p.email,
  name: p.display_name,
  hd: p.hd || null,
  sky_mavis: p.hd === 'skymavis.com',
});

/** Writes from a page must come from our own origin. SameSite=Lax already blocks most of this. */
function sameOriginWrite(request, url) {
  // A Bearer header cannot be attached by a cross-site page without a CORS preflight, which we never grant.
  if (request.headers.get('Authorization')) return true;
  return isAllowedOrigin(request.headers.get('Origin'), url);
}

// ---------------------------------------------------------------- handlers

async function handleLogin(request, env, url) {
  if (request.method !== 'GET') return methodNotAllowed('GET');
  // Sign-in only runs on the origin registered with Google; www hops over first.
  if (isOurHost(url.hostname) && url.origin !== publicOrigin(env)) {
    return redirect(`${publicOrigin(env)}${url.pathname}${url.search}`);
  }
  if (!env.GOOGLE_CLIENT_ID) return json({ error: 'not_configured' }, 503);

  const state = randomToken();
  const nonce = randomToken();
  const verifier = randomToken(48);
  const returnTo = safeReturnTo(url.searchParams.get('return'), url, env);
  // Desktop: the loopback target is validated here and carried inside the signed cookie.
  let desktop;
  if (url.searchParams.get('desktop') === '1') {
    desktop = parseDesktopLogin(url);
    if (!desktop) return json({ error: 'bad_desktop_params' }, 400);
  }
  const oauth = await signValue(env, { s: state, n: nonce, v: verifier, r: returnTo, d: desktop, exp: now() + OAUTH_TTL_S });

  const params = new URLSearchParams({
    client_id: env.GOOGLE_CLIENT_ID,
    redirect_uri: `${url.origin}/auth/callback`,
    response_type: 'code',
    scope: 'openid email profile',
    state,
    nonce,
    code_challenge: await sha256b64url(verifier),
    code_challenge_method: 'S256',
  });
  // Switch account must show Google's account chooser even if one account is already active.
  if (url.searchParams.get('switch') === '1') params.set('prompt', 'select_account');

  return redirect(`${GOOGLE_AUTH}?${params}`, [
    cookie(OAUTH_COOKIE, oauth, url, { maxAge: OAUTH_TTL_S, path: '/auth' }),
  ]);
}

async function handleCallback(request, env, url) {
  if (request.method !== 'GET') return methodNotAllowed('GET');
  const clearOauth = cookie(OAUTH_COOKIE, '', url, { maxAge: 0, path: '/auth' });
  const oauth = await verifyValue(env, readCookie(request, OAUTH_COOKIE));
  const fallback = safeReturnTo(null, url, env);
  const dk = oauth && oauth.d;
  const fail = (code, to = fallback) => (dk
    ? redirect(loopbackUrl(dk, { error: code }), [clearOauth])
    : redirect(withParam(to, 'auth_error', code), [clearOauth]));

  // No cookie means it expired (10 min), was blocked, or this is a replayed URL.
  if (!oauth) return fail('expired');
  const back = oauth.r || fallback;
  // Google reports cancel and policy blocks as ?error= (access_denied, admin_policy_enforced, ...).
  const gErr = url.searchParams.get('error');
  if (gErr) return fail(/^[a-z_]{1,64}$/.test(gErr) ? gErr : 'google', back);
  if (url.searchParams.get('state') !== oauth.s) return fail('state', back);
  const code = url.searchParams.get('code');
  if (!code) return fail('google', back);

  let tokenRes;
  try {
    tokenRes = await fetch(GOOGLE_TOKEN, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        code,
        client_id: env.GOOGLE_CLIENT_ID,
        client_secret: env.GOOGLE_CLIENT_SECRET,
        redirect_uri: `${url.origin}/auth/callback`,
        grant_type: 'authorization_code',
        code_verifier: oauth.v,
      }),
    });
  } catch (err) {
    console.error('token exchange unreachable', String(err));
    return fail('network', back);
  }
  if (!tokenRes.ok) {
    console.error('token exchange failed', tokenRes.status, (await tokenRes.text()).slice(0, 300));
    return fail('token', back);
  }

  let claims;
  try {
    claims = await verifyIdToken((await tokenRes.json()).id_token, env, oauth.n);
  } catch (err) {
    console.error('id token rejected', String(err));
    return fail('token', back);
  }
  if (claims.email_verified === false) return fail('email_unverified', back);

  const t = now();
  const playerId = `google:${claims.sub}`;
  if (dk) {
    // Desktop: no cookie session. Upsert the player, mint the one-time code, hand it to the loopback port.
    await env.DB.prepare(
      `INSERT INTO players (id, email, display_name, hd, created_at, last_login_at) VALUES (?, ?, ?, ?, ?, ?)
       ON CONFLICT(id) DO UPDATE SET email = excluded.email, display_name = excluded.display_name,
                                     hd = excluded.hd, last_login_at = excluded.last_login_at`,
    ).bind(playerId, claims.email || null, claims.name || null, claims.hd || null, t, t).run();
    const code = await issueDesktopCode(env, playerId, dk);
    return redirect(loopbackUrl(dk, { code }), [clearOauth]);
  }
  const sessionToken = randomToken(32);
  await env.DB.batch([
    env.DB.prepare(
      `INSERT INTO players (id, email, display_name, hd, created_at, last_login_at)
       VALUES (?, ?, ?, ?, ?, ?)
       ON CONFLICT(id) DO UPDATE SET email = excluded.email, display_name = excluded.display_name,
                                     hd = excluded.hd, last_login_at = excluded.last_login_at`,
    ).bind(playerId, claims.email || null, claims.name || null, claims.hd || null, t, t),
    env.DB.prepare('DELETE FROM sessions WHERE player_id = ? AND expires_at <= ?').bind(playerId, t),
    env.DB.prepare('INSERT INTO sessions (id_hash, player_id, created_at, expires_at) VALUES (?, ?, ?, ?)')
      .bind(await sha256b64url(sessionToken), playerId, t, t + SESSION_TTL_S),
  ]);

  return redirect(withParam(back, 'auth', 'signed_in'), [
    clearOauth,
    cookie(SESSION_COOKIE, sessionToken, url, { maxAge: SESSION_TTL_S }),
  ]);
}

async function handleLogout(request, env, url) {
  if (request.method !== 'POST') return methodNotAllowed('POST');
  if (!sameOriginWrite(request, url)) return json({ error: 'forbidden_origin' }, 403);
  const token = readCookie(request, SESSION_COOKIE);
  if (token) {
    await env.DB.prepare('DELETE FROM sessions WHERE id_hash = ?').bind(await sha256b64url(token)).run();
  }
  return new Response(null, {
    status: 204,
    headers: { ...NO_STORE, 'Set-Cookie': cookie(SESSION_COOKIE, '', url, { maxAge: 0 }) },
  });
}

async function handleMe(request, env) {
  if (request.method !== 'GET') return methodNotAllowed('GET');
  const player = await currentPlayer(request, env);
  if (!player) return json({ error: 'signed_out' }, 401);
  return json(publicPlayer(player));
}

function parseBlob(text) {
  if (text == null) return null;
  try {
    return JSON.parse(text);
  } catch {
    return null;
  }
}

async function readSave(env, playerId) {
  const row = await env.DB.prepare(
    'SELECT meta_json, run_json, rev, updated_at FROM saves WHERE player_id = ?',
  ).bind(playerId).first();
  if (!row) return { rev: 0, meta: null, run: null, updated_at: null };
  return { rev: row.rev, meta: parseBlob(row.meta_json), run: parseBlob(row.run_json), updated_at: row.updated_at };
}

const isPlainObject = (v) => v !== null && typeof v === 'object' && !Array.isArray(v);

async function handleSave(request, env, url) {
  const player = await currentPlayer(request, env);
  if (request.method === 'GET') {
    if (!player) return json({ error: 'signed_out' }, 401);
    return json(await readSave(env, player.id));
  }
  if (request.method !== 'PUT') return methodNotAllowed('GET, PUT');
  if (!sameOriginWrite(request, url)) return json({ error: 'forbidden_origin' }, 403);
  if (!player) return json({ error: 'signed_out' }, 401);

  const text = await request.text();
  if (enc.encode(text).length > MAX_SAVE_BYTES) return json({ error: 'too_large' }, 413);
  let body;
  try {
    body = JSON.parse(text);
  } catch {
    return json({ error: 'bad_json' }, 400);
  }
  if (!isPlainObject(body) || !Number.isInteger(body.rev) || body.rev < 0) {
    return json({ error: 'bad_request', detail: 'rev must be a non-negative integer' }, 400);
  }
  const hasMeta = 'meta' in body;
  const hasRun = 'run' in body;
  if (!hasMeta && !hasRun) return json({ error: 'bad_request', detail: 'nothing to save' }, 400);
  if (hasMeta && !isPlainObject(body.meta)) return json({ error: 'bad_request', detail: 'meta must be an object' }, 400);
  if (hasRun && body.run !== null && !isPlainObject(body.run)) {
    return json({ error: 'bad_request', detail: 'run must be an object or null' }, 400);
  }

  const t = now();
  const metaJson = hasMeta ? JSON.stringify(body.meta) : null;
  const runJson = hasRun && body.run !== null ? JSON.stringify(body.run) : null;
  let changes;
  if (body.rev === 0) {
    // First write for this player. DO NOTHING on conflict: a row already there means another
    // device wrote first, which is exactly the conflict case.
    const res = await env.DB.prepare(
      `INSERT INTO saves (player_id, meta_json, run_json, rev, updated_at) VALUES (?, ?, ?, 1, ?)
       ON CONFLICT(player_id) DO NOTHING`,
    ).bind(player.id, metaJson, runJson, t).run();
    changes = res.meta.changes;
  } else {
    const sets = ['rev = rev + 1', 'updated_at = ?'];
    const args = [t];
    if (hasMeta) { sets.push('meta_json = ?'); args.push(metaJson); }
    if (hasRun) { sets.push('run_json = ?'); args.push(runJson); }
    const res = await env.DB.prepare(
      `UPDATE saves SET ${sets.join(', ')} WHERE player_id = ? AND rev = ?`,
    ).bind(...args, player.id, body.rev).run();
    changes = res.meta.changes;
  }

  if (!changes) {
    // Someone else (another tab or device) saved since this client last read. Hand back what is
    // on the server so the game can show both and let the player choose.
    return json({ error: 'conflict', server: await readSave(env, player.id) }, 409);
  }
  return json({ rev: body.rev + 1, updated_at: t });
}

const ROUTES = {
  '/auth/login': handleLogin,
  '/auth/callback': handleCallback,
  '/auth/logout': handleLogout,
  '/api/me': handleMe,
  '/api/save': handleSave,
  ...DESKTOP_ROUTES,
};

export const isAccountsPath = (pathname) => Object.prototype.hasOwnProperty.call(ROUTES, pathname);

// ---------------------------------------------------------------- rate limits
//
// Cloudflare's Workers Rate Limiting binding (wrangler.toml `[[ratelimits]]`). Counters are per
// Cloudflare location and eventually consistent: this stops floods and scripted abuse, it is not
// exact accounting. /api/me is left out on purpose: the game calls it on every page load.
//
// Sign-in is keyed by IP. One sign-in is two requests (login + callback), so 30/min still lets a
// room of players on one office IP sign in together. Saves are keyed by session when there is
// one, so players behind a shared IP never use up each other's budget; the game pushes at most
// once per few seconds and backs off on any error, so 60/min is far above real play.
//
// A missing binding (local tests, `wrangler dev` without it) means no limit, never an outage.
const LIMITERS = {
  '/auth/login': 'AUTH_LIMITER',
  '/auth/callback': 'AUTH_LIMITER',
  '/auth/logout': 'AUTH_LIMITER',
  '/api/save': 'SAVE_LIMITER',
  '/auth/desktop/token': 'AUTH_LIMITER',
  '/auth/refresh': 'AUTH_LIMITER',
};

async function overLimit(request, env, url) {
  const limiter = env[LIMITERS[url.pathname]];
  if (!limiter) return false;
  let key = `ip:${request.headers.get('CF-Connecting-IP') || 'unknown'}`;
  if (url.pathname === '/api/save') {
    const token = readCookie(request, SESSION_COOKIE);
    if (token) key = `s:${await sha256b64url(token)}`;
  }
  const { success } = await limiter.limit({ key });
  return !success;
}

function rateLimited(request, env, url) {
  // Login and callback are full-page navigations: send the player back to the game with a reason
  // it can show, instead of leaving them on a bare JSON page.
  if (url.pathname === '/auth/login' || url.pathname === '/auth/callback') {
    const back = safeReturnTo(url.pathname === '/auth/login' ? url.searchParams.get('return') : null, url, env);
    return redirect(withParam(back, 'auth_error', 'rate_limited'));
  }
  return json({ error: 'rate_limited' }, 429, { 'Retry-After': '60' });
}

export async function handleAccounts(request, env, url) {
  try {
    if (await overLimit(request, env, url)) return rateLimited(request, env, url);
    return await ROUTES[url.pathname](request, env, url);
  } catch (err) {
    console.error('accounts error', url.pathname, String(err && err.stack || err));
    return json({ error: 'server' }, 500);
  }
}

// Exposed for tests only.
export const _test = { verifyIdToken, signValue, verifyValue, resetJwksCache: () => { jwksCache = { keys: null, at: 0 }; } };

// Shared with src/runs.js (run creation needs the same session lookup and origin allowlist).
export const shared = { currentPlayer, isAllowedOrigin, json };
