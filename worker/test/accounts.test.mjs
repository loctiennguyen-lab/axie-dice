// Accounts end-to-end against a real SQLite database (the D1 migration, applied verbatim) and a
// fake Google that signs real RS256 ID tokens. Run from worker/:  node --test test/
import { test, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { DatabaseSync } from 'node:sqlite';
import worker from '../src/index.js';
import { _test } from '../src/accounts.js';

const CLIENT_ID = 'test-client.apps.googleusercontent.com';
const ORIGIN = 'https://axiedice.fun';
const MIGRATION = readFileSync(new URL('../migrations/0001_accounts.sql', import.meta.url), 'utf8');

// ---------------------------------------------------------------- D1 stand-in over node:sqlite

class Stmt {
  constructor(db, sql) { this.db = db; this.sql = sql; this.args = []; }
  bind(...args) { this.args = args; return this; }
  async first() { return this.db.prepare(this.sql).get(...this.args) ?? null; }
  async all() { return { results: this.db.prepare(this.sql).all(...this.args) }; }
  async run() { const r = this.db.prepare(this.sql).run(...this.args); return { success: true, meta: { changes: Number(r.changes) } }; }
}
class FakeD1 {
  constructor() { this.db = new DatabaseSync(':memory:'); this.db.exec('PRAGMA foreign_keys = ON;'); this.db.exec(MIGRATION); }
  prepare(sql) { return new Stmt(this.db, sql); }
  async batch(stmts) {
    this.db.exec('BEGIN');
    try { const out = []; for (const s of stmts) out.push(await s.run()); this.db.exec('COMMIT'); return out; }
    catch (e) { this.db.exec('ROLLBACK'); throw e; }
  }
}

// ---------------------------------------------------------------- fake Google

const b64url = (buf) => Buffer.from(buf).toString('base64url');
const keys = await crypto.subtle.generateKey(
  { name: 'RSASSA-PKCS1-v1_5', modulusLength: 2048, publicExponent: new Uint8Array([1, 0, 1]), hash: 'SHA-256' },
  true, ['sign', 'verify'],
);
const publicJwk = { ...(await crypto.subtle.exportKey('jwk', keys.publicKey)), kid: 'k1', alg: 'RS256', use: 'sig' };

async function signIdToken(claims, { kid = 'k1', key = keys.privateKey } = {}) {
  const h = b64url(JSON.stringify({ alg: 'RS256', kid, typ: 'JWT' }));
  const p = b64url(JSON.stringify(claims));
  const sig = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, new TextEncoder().encode(`${h}.${p}`));
  return `${h}.${p}.${b64url(sig)}`;
}

let google; // per-test knobs + record of what the Worker sent
function installFakeGoogle() {
  google = { user: { sub: '1001', email: 'liam@skymavis.com', name: 'Liam', hd: 'skymavis.com', email_verified: true },
             tamper: {}, tokenCalls: [], challenge: null, nonce: null, tokenStatus: 200 };
  globalThis.fetch = async (input, init = {}) => {
    const url = String(input);
    if (url === 'https://www.googleapis.com/oauth2/v3/certs') {
      return Response.json({ keys: [publicJwk] });
    }
    if (url === 'https://oauth2.googleapis.com/token') {
      const form = new URLSearchParams(String(init.body));
      google.tokenCalls.push(Object.fromEntries(form));
      if (google.tokenStatus !== 200) return new Response('{"error":"invalid_grant"}', { status: google.tokenStatus });
      // PKCE: the verifier must hash to the challenge sent at /auth/login.
      const digest = b64url(await crypto.subtle.digest('SHA-256', new TextEncoder().encode(form.get('code_verifier'))));
      if (digest !== google.challenge) return new Response('{"error":"invalid_grant"}', { status: 400 });
      const t = Math.floor(Date.now() / 1000);
      const claims = { iss: 'https://accounts.google.com', aud: CLIENT_ID, iat: t, exp: t + 3600,
                       nonce: google.nonce, ...google.user, ...google.tamper };
      return Response.json({ id_token: await signIdToken(claims), access_token: 'x', token_type: 'Bearer' });
    }
    throw new Error(`unexpected fetch ${url}`);
  };
}

// ---------------------------------------------------------------- harness

let env;
beforeEach(() => {
  env = { DB: new FakeD1(), GOOGLE_CLIENT_ID: CLIENT_ID, GOOGLE_CLIENT_SECRET: 'shh', SESSION_SIGNING_KEY: 'k'.repeat(64) };
  installFakeGoogle();
  _test.resetJwksCache();
});

const call = (path, { method = 'GET', cookie, origin, body, host = ORIGIN, ip } = {}) => {
  const headers = {};
  if (cookie) headers.Cookie = cookie;
  if (ip) headers['CF-Connecting-IP'] = ip;
  if (origin) headers.Origin = origin;
  if (body !== undefined) headers['Content-Type'] = 'application/json';
  return worker.fetch(new Request(host + path, { method, headers, body: body === undefined ? undefined : JSON.stringify(body) }), env);
};

const cookieValue = (res, name) => {
  for (const c of res.headers.getSetCookie()) if (c.startsWith(name + '=')) return c.split(';')[0].slice(name.length + 1);
  return null;
};

/** Runs /auth/login then /auth/callback the way a browser would; returns the callback response. */
async function signIn({ returnTo = `${ORIGIN}/`, mutateCallback } = {}) {
  const login = await call(`/auth/login?return=${encodeURIComponent(returnTo)}`);
  assert.equal(login.status, 302);
  const g = new URL(login.headers.get('Location'));
  google.challenge = g.searchParams.get('code_challenge');
  google.nonce = g.searchParams.get('nonce');
  const oauth = cookieValue(login, 'ad_oauth');
  let qs = `state=${g.searchParams.get('state')}&code=good-code`;
  let cookie = `ad_oauth=${oauth}`;
  if (mutateCallback) ({ qs, cookie } = mutateCallback({ qs, cookie, google: g }));
  const cb = await call(`/auth/callback?${qs}`, { cookie });
  return { login, cb, session: cookieValue(cb, 'ad_session') };
}

// ---------------------------------------------------------------- sign-in

test('login redirects to Google with PKCE, nonce and state, and sets a short-lived signed cookie', async () => {
  const res = await call('/auth/login');
  assert.equal(res.status, 302);
  const g = new URL(res.headers.get('Location'));
  assert.equal(g.origin + g.pathname, 'https://accounts.google.com/o/oauth2/v2/auth');
  assert.equal(g.searchParams.get('client_id'), CLIENT_ID);
  assert.equal(g.searchParams.get('redirect_uri'), 'https://axiedice.fun/auth/callback');
  assert.equal(g.searchParams.get('scope'), 'openid email profile');
  assert.equal(g.searchParams.get('code_challenge_method'), 'S256');
  assert.ok(g.searchParams.get('state') && g.searchParams.get('nonce'));
  assert.equal(g.searchParams.get('prompt'), null);
  const c = res.headers.getSetCookie().find((x) => x.startsWith('ad_oauth='));
  assert.match(c, /HttpOnly/); assert.match(c, /Secure/); assert.match(c, /SameSite=Lax/);
  assert.match(c, /Path=\/auth/); assert.match(c, /Max-Age=600/); assert.match(c, /Domain=axiedice.fun/);
});

test('switch=1 forces the Google account chooser', async () => {
  const g = new URL((await call('/auth/login?switch=1')).headers.get('Location'));
  assert.equal(g.searchParams.get('prompt'), 'select_account');
});

test('www hops to the apex before sign-in, because only the apex redirect URI is registered', async () => {
  const res = await call('/auth/login?return=x', { host: 'https://www.axiedice.fun' });
  assert.equal(res.status, 302);
  assert.equal(res.headers.get('Location'), 'https://axiedice.fun/auth/login?return=x');
});

test('first sign-in creates the profile and a session; /api/me then knows the player', async () => {
  const { cb, session } = await signIn({ returnTo: 'https://www.axiedice.fun/?x=1' });
  assert.equal(cb.status, 302);
  assert.equal(cb.headers.get('Location'), 'https://www.axiedice.fun/?x=1&auth=signed_in');
  assert.ok(session);
  const sc = cb.headers.getSetCookie().find((x) => x.startsWith('ad_session='));
  assert.match(sc, /HttpOnly/); assert.match(sc, /Domain=axiedice.fun/); assert.match(sc, /Max-Age=2592000/);
  assert.ok(cb.headers.getSetCookie().some((x) => x.startsWith('ad_oauth=;') && /Max-Age=0/.test(x)), 'oauth cookie cleared');

  // The secret and verifier went to Google's token endpoint, never into a URL.
  assert.equal(google.tokenCalls[0].client_secret, 'shh');
  assert.equal(google.tokenCalls[0].redirect_uri, 'https://axiedice.fun/auth/callback');

  const me = await call('/api/me', { cookie: `ad_session=${session}` });
  assert.equal(me.status, 200);
  assert.deepEqual(await me.json(), { id: 'google:1001', email: 'liam@skymavis.com', name: 'Liam', hd: 'skymavis.com', sky_mavis: true });

  // Only a hash of the token is stored.
  const row = env.DB.db.prepare('SELECT id_hash FROM sessions').get();
  assert.notEqual(row.id_hash, session);
});

test('signing in again keeps the same profile and refreshes name/email', async () => {
  await signIn();
  google.user = { ...google.user, name: 'Liam N', email: 'new@skymavis.com' };
  const { session } = await signIn();
  assert.equal(env.DB.db.prepare('SELECT COUNT(*) n FROM players').get().n, 1);
  const me = await (await call('/api/me', { cookie: `ad_session=${session}` })).json();
  assert.equal(me.name, 'Liam N'); assert.equal(me.email, 'new@skymavis.com');
});

test('a personal Gmail account works and is not marked Sky Mavis', async () => {
  google.user = { sub: '2002', email: 'someone@gmail.com', name: 'Someone', email_verified: true };
  const { session } = await signIn();
  const me = await (await call('/api/me', { cookie: `ad_session=${session}` })).json();
  assert.equal(me.hd, null); assert.equal(me.sky_mavis, false);
});

// ---------------------------------------------------------------- sign-in failures

const errorOf = (res) => new URL(res.headers.get('Location')).searchParams.get('auth_error');

test('player cancels on Google -> back to the game with auth_error=access_denied, no session', async () => {
  const { cb, session } = await signIn({ mutateCallback: ({ cookie, google: g }) => ({ cookie, qs: `state=${g.searchParams.get('state')}&error=access_denied` }) });
  assert.equal(errorOf(cb), 'access_denied'); assert.equal(session, null);
});

test('company policy block is passed through so the game can explain it', async () => {
  const { cb } = await signIn({ mutateCallback: ({ cookie, google: g }) => ({ cookie, qs: `state=${g.searchParams.get('state')}&error=admin_policy_enforced` }) });
  assert.equal(errorOf(cb), 'admin_policy_enforced');
});

test('state mismatch is refused', async () => {
  const { cb, session } = await signIn({ mutateCallback: ({ cookie }) => ({ cookie, qs: 'state=forged&code=good-code' }) });
  assert.equal(errorOf(cb), 'state'); assert.equal(session, null);
});

test('missing or tampered oauth cookie is treated as expired', async () => {
  const a = await signIn({ mutateCallback: ({ qs }) => ({ qs, cookie: '' }) });
  assert.equal(errorOf(a.cb), 'expired');
  const b = await signIn({ mutateCallback: ({ qs, cookie }) => ({ qs, cookie: cookie.slice(0, -3) + 'AAA' }) });
  assert.equal(errorOf(b.cb), 'expired');
});

test('ID token for another app, with a wrong nonce, or expired is rejected', async () => {
  for (const tamper of [{ aud: 'someone-else' }, { nonce: 'wrong' }, { exp: 1000 }, { iss: 'https://evil.example' }]) {
    google.tamper = tamper;
    const { cb, session } = await signIn();
    assert.equal(errorOf(cb), 'token', JSON.stringify(tamper)); assert.equal(session, null);
  }
});

test('ID token signed by an unknown key is rejected', async () => {
  const other = await crypto.subtle.generateKey(
    { name: 'RSASSA-PKCS1-v1_5', modulusLength: 2048, publicExponent: new Uint8Array([1, 0, 1]), hash: 'SHA-256' }, true, ['sign', 'verify']);
  const t = Math.floor(Date.now() / 1000);
  const forged = await signIdToken({ iss: 'https://accounts.google.com', aud: CLIENT_ID, sub: '1', nonce: 'n', exp: t + 60 }, { key: other.privateKey });
  await assert.rejects(_test.verifyIdToken(forged, env, 'n'), /bad signature/);
});

test('Google token endpoint failure -> auth_error=token', async () => {
  google.tokenStatus = 500;
  const { cb } = await signIn();
  assert.equal(errorOf(cb), 'token');
});

test('unverified email is refused', async () => {
  google.user = { ...google.user, email_verified: false };
  assert.equal(errorOf((await signIn()).cb), 'email_unverified');
});

test('return URL cannot point off-site (no open redirect)', async () => {
  const { cb } = await signIn({ returnTo: 'https://evil.example/steal' });
  assert.equal(cb.headers.get('Location'), 'https://axiedice.fun/?auth=signed_in');
});

// ---------------------------------------------------------------- me / logout

test('/api/me without a session is 401 signed_out', async () => {
  const res = await call('/api/me');
  assert.equal(res.status, 401); assert.deepEqual(await res.json(), { error: 'signed_out' });
  assert.equal(res.headers.get('Cache-Control'), 'no-store');
});

test('logout ends only this session and clears the cookie', async () => {
  const a = (await signIn()).session;
  const b = (await signIn()).session; // second device
  const out = await call('/auth/logout', { method: 'POST', cookie: `ad_session=${a}`, origin: ORIGIN });
  assert.equal(out.status, 204);
  assert.match(out.headers.get('Set-Cookie'), /ad_session=; .*Max-Age=0/);
  assert.equal((await call('/api/me', { cookie: `ad_session=${a}` })).status, 401);
  assert.equal((await call('/api/me', { cookie: `ad_session=${b}` })).status, 200);
});

test('logout from another site is refused', async () => {
  const s = (await signIn()).session;
  const res = await call('/auth/logout', { method: 'POST', cookie: `ad_session=${s}`, origin: 'https://evil.example' });
  assert.equal(res.status, 403);
});

test('expired session is signed out', async () => {
  const s = (await signIn()).session;
  env.DB.db.exec('UPDATE sessions SET expires_at = 1');
  assert.equal((await call('/api/me', { cookie: `ad_session=${s}` })).status, 401);
});

// ---------------------------------------------------------------- saves

test('save round trip, partial updates, run clearing and conflicts', async () => {
  const s = `ad_session=${(await signIn()).session}`;
  const put = (body, origin = ORIGIN) => call('/api/save', { method: 'PUT', cookie: s, origin, body });

  assert.deepEqual(await (await call('/api/save', { cookie: s })).json(), { rev: 0, meta: null, run: null, updated_at: null });

  let r = await put({ rev: 0, meta: { shard_pool: 60, vault: [] }, run: { row: 3 } });
  assert.equal(r.status, 200); assert.equal((await r.json()).rev, 1);

  // Meta only: the run is left alone.
  r = await put({ rev: 1, meta: { shard_pool: 75, vault: [] } });
  assert.equal((await r.json()).rev, 2);
  let got = await (await call('/api/save', { cookie: s })).json();
  assert.deepEqual(got.meta, { shard_pool: 75, vault: [] }); assert.deepEqual(got.run, { row: 3 }); assert.equal(got.rev, 2);

  // Another device still holding rev 1 tries to save -> 409 with the server copy to compare.
  r = await put({ rev: 1, meta: { shard_pool: 1 } });
  assert.equal(r.status, 409);
  const conflict = await r.json();
  assert.equal(conflict.error, 'conflict'); assert.equal(conflict.server.rev, 2); assert.equal(conflict.server.meta.shard_pool, 75);

  // A second "first write" is a conflict too, not an overwrite.
  assert.equal((await put({ rev: 0, meta: { shard_pool: 1 } })).status, 409);

  // Abandon/finish run: run: null clears it.
  r = await put({ rev: 2, run: null });
  assert.equal((await r.json()).rev, 3);
  got = await (await call('/api/save', { cookie: s })).json();
  assert.equal(got.run, null); assert.equal(got.meta.shard_pool, 75);
});

test('saves are per player', async () => {
  const a = `ad_session=${(await signIn()).session}`;
  await call('/api/save', { method: 'PUT', cookie: a, origin: ORIGIN, body: { rev: 0, meta: { owner: 'a' } } });
  google.user = { sub: '3003', email: 'b@gmail.com', name: 'B', email_verified: true };
  const b = `ad_session=${(await signIn()).session}`;
  assert.equal((await (await call('/api/save', { cookie: b })).json()).rev, 0);
});

test('save input is validated', async () => {
  const s = `ad_session=${(await signIn()).session}`;
  const put = (body, opts = {}) => call('/api/save', { method: 'PUT', cookie: s, origin: ORIGIN, body, ...opts });
  assert.equal((await call('/api/save', { method: 'PUT', origin: ORIGIN, body: { rev: 0, meta: {} } })).status, 401);
  assert.equal((await put({ rev: 0, meta: {} }, { origin: 'https://evil.example' })).status, 403);
  assert.equal((await put({ rev: -1, meta: {} })).status, 400);
  assert.equal((await put({ rev: 0 })).status, 400);
  assert.equal((await put({ rev: 0, meta: [1] })).status, 400);
  assert.equal((await put({ rev: 0, run: 'x' })).status, 400);
  assert.equal((await put({ rev: 0, meta: { blob: 'x'.repeat(600 * 1024) } })).status, 413);
  assert.equal((await call('/api/save', { method: 'DELETE', cookie: s })).status, 405);
});

test('legal pages and unrelated routes still go where they went before', async () => {
  assert.equal((await call('/terms')).status, 200);
  assert.equal((await call('/privacy')).status, 200);
});

// ---------------------------------------------------------------- rate limits

/** Stand-in for Cloudflare's rate limit binding: a fixed budget per key, never refilled. */
function fakeLimiter(limit) {
  const used = new Map();
  return {
    keys: used,
    async limit({ key }) {
      const n = (used.get(key) || 0) + 1;
      used.set(key, n);
      return { success: n <= limit };
    },
  };
}

test('sign-in over the limit goes back to the game with auth_error=rate_limited, per IP', async () => {
  env.AUTH_LIMITER = fakeLimiter(2);
  const ret = encodeURIComponent(`${ORIGIN}/play`);
  assert.equal((await call(`/auth/login?return=${ret}`, { ip: '1.1.1.1' })).status, 302);
  assert.equal((await call(`/auth/login?return=${ret}`, { ip: '1.1.1.1' })).status, 302);
  const blocked = await call(`/auth/login?return=${ret}`, { ip: '1.1.1.1' });
  assert.equal(blocked.status, 302);
  const to = new URL(blocked.headers.get('Location'));
  assert.equal(to.origin + to.pathname, `${ORIGIN}/play`);
  assert.equal(to.searchParams.get('auth_error'), 'rate_limited');
  assert.equal(google.tokenCalls.length, 0);

  // The callback is limited the same way, and never reaches Google's token endpoint.
  const cb = await call('/auth/callback?state=x&code=y', { ip: '1.1.1.1' });
  assert.equal(new URL(cb.headers.get('Location')).searchParams.get('auth_error'), 'rate_limited');
  assert.equal(google.tokenCalls.length, 0);

  // Another IP has its own budget.
  const other = await call(`/auth/login?return=${ret}`, { ip: '2.2.2.2' });
  assert.match(other.headers.get('Location'), /^https:\/\/accounts\.google\.com\//);
});

test('logout over the limit is a 429, not a fake sign-out', async () => {
  env.AUTH_LIMITER = fakeLimiter(0);
  const r = await call('/auth/logout', { method: 'POST', origin: ORIGIN, ip: '1.1.1.1' });
  assert.equal(r.status, 429);
  assert.equal(r.headers.getSetCookie().length, 0);
});

test('saves are limited per session, so players sharing an IP do not share a budget', async () => {
  const a = `ad_session=${(await signIn()).session}`;
  google.user = { sub: '4004', email: 'c@gmail.com', name: 'C', email_verified: true };
  const b = `ad_session=${(await signIn()).session}`;
  env.SAVE_LIMITER = fakeLimiter(1);
  const get = (cookie) => call('/api/save', { cookie, ip: '9.9.9.9' });

  assert.equal((await get(a)).status, 200);
  const blocked = await get(a);
  assert.equal(blocked.status, 429);
  assert.equal(blocked.headers.get('Retry-After'), '60');
  assert.equal((await blocked.json()).error, 'rate_limited');
  assert.equal((await get(b)).status, 200, 'same IP, other player: not blocked');

  // No session: falls back to the IP key (and is then refused as signed out, as before).
  assert.equal((await call('/api/save', { ip: '9.9.9.9' })).status, 401);
  assert.ok([...env.SAVE_LIMITER.keys.keys()].includes('ip:9.9.9.9'));
});

test('/api/me is never rate limited, and no binding means no limit', async () => {
  env.AUTH_LIMITER = fakeLimiter(0);
  env.SAVE_LIMITER = fakeLimiter(0);
  assert.equal((await call('/api/me')).status, 401);
  delete env.AUTH_LIMITER; delete env.SAVE_LIMITER;
  assert.equal((await call('/auth/login')).status, 302);
  assert.match((await call('/auth/login')).headers.get('Location'), /^https:\/\/accounts\.google\.com\//);
});
