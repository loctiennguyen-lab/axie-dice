/**
 * POST /api/telemetry — coarse run start/end signals for the admin dashboard
 * (docs/architecture/telemetry-dashboard-design.md). NOT anti-cheat: unlike
 * api/submit-run.js, nothing here feeds the leaderboard or unlocks anything,
 * so gameplay fields are trusted after cheap sanity clamps, not replayed.
 * Identity/timestamp are still server-verified/stamped, same trust boundary
 * as api/sync-save.js. This endpoint must NEVER block or fail visibly to the
 * player — the client fires it fire-and-forget (see src/ui.js sendTelemetry()).
 *
 * Body: {type:'run.started', mode, ascension, ranked}
 *    or {type:'run.ended', mode, ascension, ranked, outcome, wave, durationMs}
 * account.created/session.login are NOT sent here — they piggyback directly
 * inside api/auth.js's register/login handlers (zero extra client round trip).
 */
const { verifyToken } = require('./_auth');

const MAX_WAVE = 60;
const MAX_DURATION_MS = 4 * 60 * 60 * 1000; // 4h — generous outlier clamp, not a real session cap

async function upstash(...args) {
  const url = process.env.UPSTASH_REDIS_REST_URL;
  const token = process.env.UPSTASH_REDIS_REST_TOKEN;
  if (!url || !token) return null;
  const r = await fetch(url + '/' + args.map(encodeURIComponent).join('/'), {
    headers: { Authorization: 'Bearer ' + token },
  });
  return r.json();
}

function todayUTC() {
  return new Date().toISOString().slice(0, 10);
}

module.exports = async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.setHeader('Content-Type', 'application/json');
  if (req.method === 'OPTIONS') { res.status(200).end(); return; }
  // Telemetry failures must never be player-visible: always 200, even on
  // malformed input or missing config — the client doesn't branch on this.
  if (req.method !== 'POST') { res.status(200).json({ ok: false }); return; }

  const secret = process.env.AUTH_JWT_SECRET;
  if (!secret) { res.status(200).json({ ok: false }); return; }

  const authHeader = req.headers.authorization || req.headers.Authorization || '';
  const token = authHeader.indexOf('Bearer ') === 0 ? authHeader.slice(7).trim() : '';
  const claims = token ? verifyToken(token, secret) : null;
  if (!claims) { res.status(200).json({ ok: false }); return; }

  let body = req.body;
  if (typeof body === 'string') { try { body = JSON.parse(body); } catch (e) { res.status(200).json({ ok: false }); return; } }
  if (!body || typeof body !== 'object') { res.status(200).json({ ok: false }); return; }

  const type = body.type;
  if (type !== 'run.started' && type !== 'run.ended') { res.status(200).json({ ok: false }); return; }

  const mode = body.mode === 'full' ? 'full' : 'short';
  const ranked = !!body.ranked;
  const day = todayUTC();

  const totalsKey = 'tel:totals';
  const dayKey = 'tel:d:' + day;
  const dauKey = 'tel:dau:' + day;

  const calls = [
    upstash('sadd', 'tel:players', claims.username),
    upstash('sadd', dauKey, claims.username),
    upstash('expire', dauKey, String(90 * 24 * 60 * 60)),
  ];

  if (type === 'run.started') {
    calls.push(upstash('hincrby', totalsKey, 'runs_started', '1'));
    calls.push(upstash('hincrby', dayKey, 'runs_started', '1'));
    if (ranked) calls.push(upstash('hincrby', totalsKey, 'runs_started:ranked', '1'));
  } else {
    // run.ended — outcome/wave/durationMs are client-reported and spoofable,
    // but this only feeds an aggregate histogram/average, never anything
    // competitive or reward-granting, so clamps (not replay) are enough.
    const outcome = body.outcome === 'win' || body.outcome === 'loss' || body.outcome === 'quit' ? body.outcome : 'quit';
    let wave = parseInt(body.wave, 10);
    if (!Number.isFinite(wave) || wave < 0) wave = 0;
    if (wave > MAX_WAVE) wave = MAX_WAVE;
    let durationMs = parseInt(body.durationMs, 10);
    if (!Number.isFinite(durationMs) || durationMs < 0) durationMs = 0;
    if (durationMs > MAX_DURATION_MS) durationMs = MAX_DURATION_MS;

    calls.push(upstash('hincrby', totalsKey, 'runs_ended:' + outcome, '1'));
    calls.push(upstash('hincrby', dayKey, 'runs_ended:' + outcome, '1'));
    calls.push(upstash('hincrby', totalsKey, 'duration_sum_ms', String(durationMs)));
    calls.push(upstash('hincrby', totalsKey, 'duration_count', '1'));
    calls.push(upstash('hincrby', 'tel:totals:wave', String(wave), '1'));
  }

  const results = await Promise.all(calls);
  const configured = results.some((r) => r !== null);
  res.status(200).json({ ok: configured });
};
