// Run token: HMAC-signed {player_id, run_id, rules_version, exp}, TTL <= 2h (ADR 4.6). It travels in
// the first WebSocket message (`hello`), never in a URL. Its key is RUN_TOKEN_KEY, separate from
// SESSION_SIGNING_KEY (ADR 4.8 S14: one key per purpose). Set it with `wrangler secret put`.
const enc = new TextEncoder();
export const RUN_TOKEN_TTL_S = 2 * 3600;

// No Buffer: Workers only has it behind nodejs_compat, which this project does not enable.
const b64url = (buf) => {
  let bin = '';
  for (const b of new Uint8Array(buf)) bin += String.fromCharCode(b);
  return btoa(bin).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
};
const unb64url = (str) => {
  const bin = atob(str.replace(/-/g, '+').replace(/_/g, '/') + '==='.slice((str.length + 3) % 4));
  return Uint8Array.from(bin, (c) => c.charCodeAt(0));
};
// Key rotation (no deploy of secrets from code, Liam does `wrangler secret put`):
//   1. move the old secret to RUN_TOKEN_KEY_PREV and set RUN_TOKEN_KID_PREV to its kid;
//   2. put the new secret in RUN_TOKEN_KEY and a NEW kid in RUN_TOKEN_KID;
//   3. after 2h (the token TTL) unset RUN_TOKEN_KEY_PREV. Tokens signed before the rotation keep working meanwhile.
// A token without a kid (issued before kid existed) is checked against the current key.
export const currentKid = (env) => env.RUN_TOKEN_KID || 'k1';
const secretFor = (env, kid) => {
  if (kid === undefined || kid === currentKid(env)) return env.RUN_TOKEN_KEY;
  if (env.RUN_TOKEN_KEY_PREV && kid === (env.RUN_TOKEN_KID_PREV || '')) return env.RUN_TOKEN_KEY_PREV;
  return null;
};
const importKey = (secret) => {
  if (!secret) throw new Error('run token key is not set');
  return crypto.subtle.importKey('raw', enc.encode(secret), { name: 'HMAC', hash: 'SHA-256' }, false, ['sign', 'verify']);
};
const key = (env, kid) => importKey(secretFor(env, kid));

/** Fresh token id. The runs row stores the current one; a hello whose jti differs is revoked. */
export const newJti = () => Array.from(crypto.getRandomValues(new Uint8Array(12)), (b) => b.toString(16).padStart(2, '0')).join('');

export async function signRunToken(env, { player_id, run_id, rules_version, jti }, nowS = Math.floor(Date.now() / 1000)) {
  const body = b64url(enc.encode(JSON.stringify({ v: 1, kid: currentKid(env), jti, player_id, run_id, rules_version, exp: nowS + RUN_TOKEN_TTL_S })));
  const sig = await crypto.subtle.sign('HMAC', await key(env, currentKid(env)), enc.encode(`run.${body}`));
  return `${body}.${b64url(sig)}`;
}

/** The claims if the signature is ours and the token has not expired, else null. */
export async function verifyRunToken(env, token, nowS = Math.floor(Date.now() / 1000)) {
  if (typeof token !== 'string' || token.length > 1024) return null;
  const [body, sig, extra] = token.split('.');
  if (!body || !sig || extra !== undefined) return null;
  try {
    const claims = JSON.parse(new TextDecoder().decode(unb64url(body)));
    if (!claims || typeof claims !== 'object') return null;
    if (claims.kid !== undefined && typeof claims.kid !== 'string') return null;
    if (!secretFor(env, claims.kid)) return null; // unknown kid
    const ok = await crypto.subtle.verify('HMAC', await key(env, claims.kid), unb64url(sig), enc.encode(`run.${body}`));
    if (!ok) return null;
    return claims.v === 1 && typeof claims.exp === 'number' && claims.exp > nowS ? claims : null;
  } catch { return null; }
}
