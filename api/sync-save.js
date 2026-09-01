/**
 * GET/POST /api/sync-save — progression cloud save (design/gdd/player-accounts.md,
 * docs/architecture/adr-0002-player-accounts.md). Both methods require an
 * `Authorization: Bearer <token>` header signed by api/auth.js (verified here via
 * api/_auth.js verifyToken — same HMAC secret, no server-side session store).
 * Reuses the same Vercel Functions + Upstash Redis infra as api/leaderboard.js /
 * api/submit-run.js; see those files for the identical upstash() REST helper this
 * file copies verbatim.
 *
 * GET  -> {meta: <META JSON> | null}
 * POST -> body {meta}, response {ok:true, savedAt}. `meta.savedAt` is always
 *         stamped SERVER-SIDE, never trusted from the client (ADR-0002 Key
 *         Interfaces) — the client's cross-device conflict resolution depends on
 *         a consistent clock for this field.
 */
const { verifyToken } = require('./_auth');

// Same rationale/limit as api/auth.js registration: bounds Redis storage abuse,
// generous vs. any real META payload.
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

module.exports = async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.setHeader('Content-Type', 'application/json');
  if (req.method === 'OPTIONS') { res.status(200).end(); return; }
  if (req.method !== 'GET' && req.method !== 'POST') { res.status(405).json({ ok: false, error: 'Method not allowed' }); return; }

  const secret = process.env.AUTH_JWT_SECRET;
  if (!secret) { res.status(200).json({ ok: false, error: 'Accounts are not configured on this server yet' }); return; }

  const authHeader = req.headers.authorization || req.headers.Authorization || '';
  const token = authHeader.indexOf('Bearer ') === 0 ? authHeader.slice(7).trim() : '';
  const claims = token ? verifyToken(token, secret) : null;
  if (!claims) { res.status(401).json({ ok: false, error: 'Missing or invalid session token' }); return; }

  const key = 'save:' + claims.username;

  if (req.method === 'GET') {
    const r = await upstash('get', key);
    if (r === null) { res.status(200).json({ ok: false, error: 'Save storage not configured on this server yet' }); return; }
    if (!r.result) { res.status(200).json({ meta: null }); return; }
    let meta;
    try { meta = JSON.parse(r.result); } catch (e) { res.status(200).json({ meta: null }); return; }
    res.status(200).json({ meta });
    return;
  }

  // POST
  let body = req.body;
  if (typeof body === 'string') { try { body = JSON.parse(body); } catch (e) { res.status(400).json({ ok: false, error: 'Invalid JSON' }); return; } }
  if (!body || typeof body.meta !== 'object' || body.meta === null) { res.status(400).json({ ok: false, error: 'Missing meta' }); return; }

  const meta = body.meta;
  const savedAt = Date.now();
  meta.savedAt = savedAt; // server-stamped, never trusted from the client (ADR-0002)

  const serialized = JSON.stringify(meta);
  if (Buffer.byteLength(serialized, 'utf8') > MAX_META_BYTES) { res.status(400).json({ ok: false, error: 'Save data too large' }); return; }

  const w = await upstash('set', key, serialized);
  if (w === null) { res.status(200).json({ ok: false, error: 'Save storage not configured on this server yet' }); return; }
  res.status(200).json({ ok: true, savedAt });
};
