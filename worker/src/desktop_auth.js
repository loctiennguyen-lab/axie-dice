// Desktop sign-in through the Worker (ADR server-authoritative-rng 4.8, C5). The Google secret stays
// here; the game only ever holds a short-lived access token and a rotating refresh token.
//
//   1. game opens a loopback port, makes a PKCE verifier, opens the browser at
//        /auth/login?desktop=1&challenge=<S256>&port=<n>&state=<s>
//   2. after Google, accounts.js calls issueDesktopCode() and redirects to http://127.0.0.1:<n>/cb?code&state
//   3. game POSTs {code, verifier} to /auth/desktop/token -> {access, refresh, expires_in}
//   4. POST /auth/refresh {refresh} rotates (grace window for a lost response); reuse outside it revokes the device
//
// A request with "Authorization: Bearer" is authenticated by it ALONE: cookies are ignored (bearerPlayer).
// No imports from accounts.js (accounts imports this file), so the few helpers are repeated here.
const enc = new TextEncoder();
const nowS = () => Math.floor(Date.now() / 1000);

export const CODE_TTL_S = 60;
export const ACCESS_TTL_S = 20 * 60;
export const REFRESH_TTL_S = 60 * 24 * 3600;
export const GRACE_S = 45;
const MAX_DEVICES = 10;

const b64url = (bytes) => {
  let s = '';
  for (const b of new Uint8Array(bytes)) s += String.fromCharCode(b);
  return btoa(s).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
};
const randomToken = (n = 32) => b64url(crypto.getRandomValues(new Uint8Array(n)));
const sha = async (t) => b64url(await crypto.subtle.digest('SHA-256', enc.encode(t)));
const json = (body, status = 200) => new Response(JSON.stringify(body), {
  status, headers: { 'Content-Type': 'application/json; charset=utf-8', 'Cache-Control': 'no-store' },
});

const CHALLENGE = /^[A-Za-z0-9_-]{43}$/;
const STATE = /^[A-Za-z0-9_-]{16,128}$/;

/** Validated {challenge, port, state} from the login query, or null. Loopback only, never a free redirect. */
export function parseDesktopLogin(url) {
  const challenge = url.searchParams.get('challenge') || '';
  const state = url.searchParams.get('state') || '';
  const port = Number(url.searchParams.get('port'));
  if (!CHALLENGE.test(challenge) || !STATE.test(state) || !Number.isInteger(port) || port < 1024 || port > 65535) return null;
  return { c: challenge, p: port, s: state };
}

/** Where the browser is sent after Google: always http://127.0.0.1:<port>/cb. */
export const loopbackUrl = (d, params) => {
  const u = new URL(`http://127.0.0.1:${d.p}/cb`);
  for (const [k, v] of Object.entries({ ...params, state: d.s })) u.searchParams.set(k, v);
  return u.toString();
};

/** After a verified Google login: mint the one-time code the game will exchange. */
export async function issueDesktopCode(env, playerId, d) {
  const code = randomToken(32);
  const t = nowS();
  await env.DB.batch([
    env.DB.prepare('DELETE FROM desktop_codes WHERE expires_at <= ?').bind(t),
    env.DB.prepare('INSERT INTO desktop_codes (code_hash, player_id, challenge, expires_at) VALUES (?, ?, ?, ?)')
      .bind(await sha(code), playerId, d.c, t + CODE_TTL_S),
  ]);
  return code;
}

async function newPair(env, deviceId, t) {
  const access = randomToken(32);
  const refresh = randomToken(32);
  return { access, refresh, accessHash: await sha(access), refreshHash: await sha(refresh), exp: t + ACCESS_TTL_S };
}

async function readJson(request) {
  try { const b = await request.json(); return b && typeof b === 'object' && !Array.isArray(b) ? b : null; } catch { return null; }
}

async function handleToken(request, env) {
  if (request.method !== 'POST') return json({ error: 'method_not_allowed' }, 405);
  const b = await readJson(request);
  if (!b || typeof b.code !== 'string' || typeof b.verifier !== 'string' || b.verifier.length < 43 || b.verifier.length > 128) return json({ error: 'bad_request' }, 400);
  const t = nowS();
  const codeHash = await sha(b.code);
  const row = await env.DB.prepare('SELECT player_id, challenge, expires_at FROM desktop_codes WHERE code_hash = ?').bind(codeHash).first();
  // Single use even when the verifier is wrong: a guessed verifier burns the code.
  const del = await env.DB.prepare('DELETE FROM desktop_codes WHERE code_hash = ?').bind(codeHash).run();
  if (!row || del.meta.changes !== 1 || row.expires_at <= t) return json({ error: 'invalid_code' }, 400);
  if ((await sha(b.verifier)) !== row.challenge) return json({ error: 'invalid_code' }, 400);

  const deviceId = randomToken(12);
  const p = await newPair(env, deviceId, t);
  const label = typeof b.label === 'string' ? b.label.replace(/[^\w .-]/g, '').slice(0, 40) || 'Desktop' : 'Desktop';
  await env.DB.batch([
    // Oldest devices fall off past the cap, so a leaked login cannot pile up sessions forever.
    env.DB.prepare(`DELETE FROM device_sessions WHERE id IN (SELECT id FROM device_sessions WHERE player_id = ? ORDER BY last_seen DESC LIMIT -1 OFFSET ?)`).bind(row.player_id, MAX_DEVICES - 1),
    env.DB.prepare('INSERT INTO device_sessions (id, player_id, label, refresh_hash, created_at, last_seen) VALUES (?, ?, ?, ?, ?, ?)')
      .bind(deviceId, row.player_id, label, p.refreshHash, t, t),
    env.DB.prepare('INSERT INTO device_tokens (token_hash, device_id, expires_at) VALUES (?, ?, ?)').bind(p.accessHash, deviceId, p.exp),
  ]);
  return json({ access: p.access, refresh: p.refresh, expires_in: ACCESS_TTL_S, device_id: deviceId });
}

async function handleRefresh(request, env) {
  if (request.method !== 'POST') return json({ error: 'method_not_allowed' }, 405);
  const b = await readJson(request);
  if (!b || typeof b.refresh !== 'string' || b.refresh.length > 128) return json({ error: 'bad_request' }, 400);
  const t = nowS();
  const h = await sha(b.refresh);
  const cur = await env.DB.prepare('SELECT * FROM device_sessions WHERE refresh_hash = ?').bind(h).first();
  let dev = cur;
  let graceHit = false;
  if (!cur) {
    const prev = await env.DB.prepare('SELECT * FROM device_sessions WHERE prev_refresh_hash = ?').bind(h).first();
    if (!prev) return json({ error: 'invalid_refresh' }, 401);
    if (prev.revoked || !prev.rotated_at || t - prev.rotated_at > GRACE_S) {
      // An old refresh token came back after its grace window: treat as stolen, kill the device.
      await env.DB.prepare('UPDATE device_sessions SET revoked = 1 WHERE id = ?').bind(prev.id).run();
      return json({ error: 'invalid_refresh' }, 401);
    }
    dev = prev; graceHit = true;
  }
  if (dev.revoked || t - dev.created_at > REFRESH_TTL_S) return json({ error: 'invalid_refresh' }, 401);
  const p = await newPair(env, dev.id, t);
  const stmts = graceHit
    // Lost-response retry: keep the same prev (so further retries still work), just hand out a fresh pair.
    ? [env.DB.prepare('UPDATE device_sessions SET refresh_hash = ?, last_seen = ? WHERE id = ?').bind(p.refreshHash, t, dev.id)]
    : [env.DB.prepare('UPDATE device_sessions SET prev_refresh_hash = refresh_hash, refresh_hash = ?, rotated_at = ?, last_seen = ? WHERE id = ?').bind(p.refreshHash, t, t, dev.id)];
  stmts.push(
    env.DB.prepare('DELETE FROM device_tokens WHERE device_id = ? AND expires_at <= ?').bind(dev.id, t),
    env.DB.prepare('INSERT INTO device_tokens (token_hash, device_id, expires_at) VALUES (?, ?, ?)').bind(p.accessHash, dev.id, p.exp),
  );
  await env.DB.batch(stmts);
  return json({ access: p.access, refresh: p.refresh, expires_in: ACCESS_TTL_S, device_id: dev.id });
}

/**
 * Player for a Bearer request. null means "no Bearer header" -> caller falls back to the cookie;
 * false means a Bearer header was present but invalid -> caller must answer 401 and NOT try cookies.
 */
export async function bearerPlayer(request, env) {
  const auth = request.headers.get('Authorization');
  if (!auth) return null;
  const m = /^Bearer ([A-Za-z0-9_-]{20,100})$/.exec(auth);
  if (!m) return false;
  const t = nowS();
  const row = await env.DB.prepare(
    `SELECT p.id, p.email, p.display_name, p.hd, d.id AS device_id
       FROM device_tokens k JOIN device_sessions d ON d.id = k.device_id JOIN players p ON p.id = d.player_id
      WHERE k.token_hash = ? AND k.expires_at > ? AND d.revoked = 0`,
  ).bind(await sha(m[1]), t).first();
  return row || false;
}

async function handleDevices(request, env) {
  const p = await bearerPlayer(request, env);
  if (!p) return json({ error: 'unauthenticated' }, 401);
  if (request.method === 'GET') {
    const r = await env.DB.prepare('SELECT id, label, created_at, last_seen FROM device_sessions WHERE player_id = ? AND revoked = 0 ORDER BY last_seen DESC').bind(p.id).all();
    return json({ devices: r.results.map((d) => ({ ...d, current: d.id === p.device_id })) });
  }
  if (request.method === 'POST') {
    const b = await readJson(request);
    if (!b) return json({ error: 'bad_request' }, 400);
    // {id} revokes one device, {all:true} signs out everywhere (this device included).
    if (b.all === true) await env.DB.prepare('UPDATE device_sessions SET revoked = 1 WHERE player_id = ?').bind(p.id).run();
    else if (typeof b.id === 'string') await env.DB.prepare('UPDATE device_sessions SET revoked = 1 WHERE id = ? AND player_id = ?').bind(b.id, p.id).run();
    else return json({ error: 'bad_request' }, 400);
    return json({ ok: true });
  }
  return json({ error: 'method_not_allowed' }, 405);
}

export const DESKTOP_ROUTES = {
  '/auth/desktop/token': handleToken,
  '/auth/refresh': handleRefresh,
  '/auth/devices': handleDevices,
};
