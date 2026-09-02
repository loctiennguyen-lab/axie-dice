/**
 * GET /api/leaderboard?mode=short|full&ascension=0-10
 * Read-only. Returns the top 100 rows of the (mode, ascension) Ranked Run
 * board written by submit-run.js. See design/gdd/leaderboard-system.md and
 * ADR-0001 — MVP scope is one board per (mode, ascension), no Standard/
 * Collector split and no separate Daily view yet (see submit-run.js header
 * for why the split needs a server-side progression sync this beta doesn't
 * have; fast-follow, not forgotten).
 */
const TOP_N = 100;

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
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Content-Type', 'application/json');
  if (req.method === 'OPTIONS') { res.status(200).end(); return; }
  if (req.method !== 'GET') { res.status(405).json({ error: 'Method not allowed' }); return; }

  const mode = req.query.mode === 'full' ? 'full' : 'short';
  const ascension = Math.max(0, Math.min(10, parseInt(req.query.ascension, 10) || 0));
  const board = 'lb:' + mode + ':' + ascension;

  const zres = await upstash('zrange', board, '0', String(TOP_N - 1), 'REV', 'WITHSCORES');
  if (zres === null) {
    res.status(200).json({ mode, ascension, rows: [], configured: false });
    return;
  }
  const raw = (zres && zres.result) || [];
  const rows = [];
  for (let i = 0; i < raw.length; i += 2) {
    let parsed;
    try { parsed = JSON.parse(raw[i]); } catch (e) { continue; }
    rows.push({
      rank: rows.length + 1,
      name: parsed.name,
      wallet: parsed.wallet,
      score: Number(raw[i + 1]),
      won: !!parsed.won,
      step: parsed.step,
      submittedAt: parsed.ts,
      // team/relics: absent on entries submitted before this field existed —
      // the client must treat a missing/empty array as "no data", not an error.
      team: Array.isArray(parsed.team) ? parsed.team : [],
      relics: Array.isArray(parsed.relics) ? parsed.relics : [],
    });
  }
  res.setHeader('Cache-Control', 'public, max-age=30');
  res.status(200).json({ mode, ascension, rows, configured: true });
};
