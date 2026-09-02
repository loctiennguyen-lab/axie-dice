/**
 * GET /api/admin-stats — aggregate telemetry for tools/admin-dashboard.html
 * (docs/architecture/telemetry-dashboard-design.md §4). Read-only, admin-only:
 * gated by a separate ADMIN_DASHBOARD_TOKEN env var, NOT a player JWT — this
 * exposes counts across every player, so it must never be reachable with an
 * ordinary session token. Reads a handful of `tel:*` keys written by
 * api/auth.js (account.created/session.login) and api/telemetry.js
 * (run.started/run.ended); see those files for the key layout.
 *
 * Query: ?days=30 (default 30, max 90 — matches tel:dau:* 90-day EXPIRE)
 */
const DEFAULT_DAYS = 30;
const MAX_DAYS = 90;

async function upstash(...args) {
  const url = process.env.UPSTASH_REDIS_REST_URL;
  const token = process.env.UPSTASH_REDIS_REST_TOKEN;
  if (!url || !token) return null;
  const r = await fetch(url + '/' + args.map(encodeURIComponent).join('/'), {
    headers: { Authorization: 'Bearer ' + token },
  });
  return r.json();
}

function hashToObj(r) {
  const flat = (r && r.result) || [];
  const o = {};
  for (let i = 0; i < flat.length; i += 2) o[flat[i]] = Number(flat[i + 1]) || 0;
  return o;
}

function dateStr(offsetDays) {
  const d = new Date();
  d.setUTCDate(d.getUTCDate() - offsetDays);
  return d.toISOString().slice(0, 10);
}

module.exports = async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Authorization');
  res.setHeader('Content-Type', 'application/json');
  if (req.method === 'OPTIONS') { res.status(200).end(); return; }
  if (req.method !== 'GET') { res.status(405).json({ error: 'Method not allowed' }); return; }

  const adminToken = process.env.ADMIN_DASHBOARD_TOKEN;
  if (!adminToken) { res.status(200).json({ error: 'Admin dashboard is not configured on this server yet' }); return; }

  const authHeader = req.headers.authorization || req.headers.Authorization || '';
  const given = authHeader.indexOf('Bearer ') === 0 ? authHeader.slice(7).trim() : '';
  if (!given || given !== adminToken) { res.status(401).json({ error: 'Invalid admin token' }); return; }

  const days = Math.max(1, Math.min(MAX_DAYS, parseInt(req.query.days, 10) || DEFAULT_DAYS));
  const dates = Array.from({ length: days }, (_, i) => dateStr(days - 1 - i)); // oldest -> newest

  const [totalsRes, waveRes, playersRes] = await Promise.all([
    upstash('hgetall', 'tel:totals'),
    upstash('hgetall', 'tel:totals:wave'),
    upstash('scard', 'tel:players'),
  ]);

  if (totalsRes === null) { res.status(200).json({ configured: false }); return; }

  const perDay = await Promise.all(
    dates.map((d) => Promise.all([upstash('hgetall', 'tel:d:' + d), upstash('scard', 'tel:dau:' + d)]))
  );

  const daily = dates.map((d, i) => ({
    date: d,
    ...hashToObj(perDay[i][0]),
    dau: (perDay[i][1] && perDay[i][1].result) || 0,
  }));

  res.setHeader('Cache-Control', 'private, max-age=30');
  res.status(200).json({
    configured: true,
    players: (playersRes && playersRes.result) || 0,
    totals: hashToObj(totalsRes),
    waveHistogram: hashToObj(waveRes),
    daily,
  });
};
