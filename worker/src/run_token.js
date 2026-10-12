// Run token: HMAC-signed {player_id, run_id, rules_version, exp}, TTL <= 2h (ADR 4.6). It travels in
// the first WebSocket message (`hello`), never in a URL. Its key is RUN_TOKEN_KEY, separate from
// SESSION_SIGNING_KEY (ADR 4.8 S14: one key per purpose). Set it with `wrangler secret put`.
const enc = new TextEncoder();
export const RUN_TOKEN_TTL_S = 2 * 3600;

const b64url = (buf) => Buffer.from(buf).toString('base64url');
const key = (env) => {
  if (!env.RUN_TOKEN_KEY) throw new Error('RUN_TOKEN_KEY is not set');
  return crypto.subtle.importKey('raw', enc.encode(env.RUN_TOKEN_KEY), { name: 'HMAC', hash: 'SHA-256' }, false, ['sign', 'verify']);
};

export async function signRunToken(env, { player_id, run_id, rules_version }, nowS = Math.floor(Date.now() / 1000)) {
  const body = b64url(enc.encode(JSON.stringify({ v: 1, player_id, run_id, rules_version, exp: nowS + RUN_TOKEN_TTL_S })));
  const sig = await crypto.subtle.sign('HMAC', await key(env), enc.encode(`run.${body}`));
  return `${body}.${b64url(sig)}`;
}

/** The claims if the signature is ours and the token has not expired, else null. */
export async function verifyRunToken(env, token, nowS = Math.floor(Date.now() / 1000)) {
  if (typeof token !== 'string' || token.length > 1024) return null;
  const [body, sig, extra] = token.split('.');
  if (!body || !sig || extra !== undefined) return null;
  try {
    const ok = await crypto.subtle.verify('HMAC', await key(env), Buffer.from(sig, 'base64url'), enc.encode(`run.${body}`));
    if (!ok) return null;
    const claims = JSON.parse(Buffer.from(body, 'base64url').toString('utf8'));
    return claims.v === 1 && typeof claims.exp === 'number' && claims.exp > nowS ? claims : null;
  } catch { return null; }
}
