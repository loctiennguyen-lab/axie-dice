/**
 * POST /api/submit-run — leaderboard anti-cheat (design/gdd/leaderboard-system.md
 * "Nộp điểm & xác thực", docs/architecture/adr-0001-leaderboard-backend-infrastructure.md).
 *
 * The client NEVER sends a score. It sends {seed, teamKeys, mode, ascension,
 * actions: [{fn,args}, ...], displayName, walletAddr?, engineVersion}. This
 * function replays those exact engine.js calls in order, server-side, and
 * computes the score itself from the replay's real outcome — a forged score
 * field would simply be ignored (there isn't one to forge; score is derived,
 * never accepted as input).
 *
 * MVP scope (see src/ui.js startRun() comment for the matching client side):
 * this endpoint only accepts "Ranked Run" submissions, where every
 * META-derived bonus (Unlocks, Battle Pass perks, Import Axie vault picks)
 * was already zeroed client-side before play — because none of that
 * meta-progression is synced to a server anywhere, there is no way for this
 * function to independently verify a player's real Shard/Unlock/Vault state,
 * so it can't trust bonuses derived from it. Forcing them to zero here too
 * (never trusting whatever the client sends for mode/ascension-derived
 * newGame options beyond mode/ascension/seed/teamKeys themselves) closes
 * that gap rather than assuming the client behaved.
 */
const { loadEngine } = require('./_engine');

const ALLOWED_FNS = new Set([
  'chooseNode', 'playerUseDie', 'playerUseRelic', 'doReroll',
  'endTurn', 'undo', 'takeReward', 'eventChoose', 'eventDone', 'shopBuy', 'shopDone',
]);
const RETURN_CHECKED_FNS = new Set(['playerUseDie', 'playerUseRelic', 'doReroll', 'undo']);
const MAX_ACTIONS = 3000; // generous vs. a real run's realistic action count; blocks log-spam
const VALID_HERO_KEY = /^(plant|beast|aqua|reptile|bug|bird)[123]$/;

function badRequest(res, msg) {
  res.status(400).json({ accepted: false, reason: msg });
}

async function upstash(...args) {
  const url = process.env.UPSTASH_REDIS_REST_URL;
  const token = process.env.UPSTASH_REDIS_REST_TOKEN;
  if (!url || !token) return null; // caller decides how to handle "not configured"
  const r = await fetch(url + '/' + args.map(encodeURIComponent).join('/'), {
    headers: { Authorization: 'Bearer ' + token },
  });
  return r.json();
}

module.exports = async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  res.setHeader('Content-Type', 'application/json');
  if (req.method === 'OPTIONS') { res.status(200).end(); return; }
  if (req.method !== 'POST') { res.status(405).json({ accepted: false, reason: 'Method not allowed' }); return; }

  let body = req.body;
  if (typeof body === 'string') { try { body = JSON.parse(body); } catch (e) { badRequest(res, 'Invalid JSON'); return; } }
  if (!body || typeof body !== 'object') { badRequest(res, 'Missing body'); return; }

  const { seed, teamKeys, mode, ascension, actions, displayName, walletAddr, engineVersion } = body;

  // ---- shape validation (reject early, cheaply, before touching the engine) ----
  if (!Number.isInteger(seed)) return badRequest(res, 'seed must be an integer');
  if (!Array.isArray(teamKeys) || teamKeys.length !== 5 || !teamKeys.every((k) => VALID_HERO_KEY.test(k))) {
    return badRequest(res, 'teamKeys must be exactly 5 starter hero keys (Vault/Import Axie picks are not eligible for Ranked Run)');
  }
  if (mode !== 'short' && mode !== 'full') return badRequest(res, 'mode must be short or full');
  if (!Number.isInteger(ascension) || ascension < 0 || ascension > 10) return badRequest(res, 'ascension must be 0-10');
  if (!Array.isArray(actions) || actions.length === 0 || actions.length > MAX_ACTIONS) {
    return badRequest(res, 'actions must be a non-empty array under ' + MAX_ACTIONS + ' entries');
  }
  if (!actions.every((a) => a && typeof a === 'object' && ALLOWED_FNS.has(a.fn) && Array.isArray(a.args))) {
    return badRequest(res, 'every action must be {fn, args} with fn in the allowed engine call list');
  }
  const name = (typeof displayName === 'string' ? displayName : '').trim().slice(0, 24) || 'Anonymous';

  // loadEngine() reads src/data.js + src/engine.js from disk (see api/_engine.js) —
  // this crashed in production once already (ENOENT: /var/task/src/data.js) because
  // Vercel's function bundler couldn't statically trace the dynamic fs.readFileSync
  // path and left those files out of the deployed bundle; vercel.json now forces
  // them in via functions.includeFiles, but this try/catch is defense-in-depth so a
  // future regression of that same gap degrades to a clear JSON error instead of an
  // uncaught crash (FUNCTION_INVOCATION_FAILED, a non-JSON response the client's
  // r.json() then throws on — surfaces to the player as a misleading generic
  // "Network error", not the real cause).
  let G;
  try { G = loadEngine(); }
  catch (e) { res.status(500).json({ accepted: false, reason: 'Server-side engine failed to load — this is a deployment issue, not your run. Try again shortly.' }); return; }
  if (engineVersion !== G.ENGINE_VERSION) {
    res.status(409).json({ accepted: false, reason: 'Client engine version out of date (' + engineVersion + ' vs server ' + G.ENGINE_VERSION + ') — refresh and replay.' });
    return;
  }

  // ---- replay: fresh state, forced-zero meta bonuses (see file header), real actions only ----
  let s;
  try {
    s = G.newGame(seed, teamKeys, { mode, asc: ascension, bonusReroll: 0, metaHpBonus: 0, startRelics: [] });
  } catch (e) {
    res.status(400).json({ accepted: false, reason: 'newGame failed to initialize with the given seed/team' });
    return;
  }
  for (let i = 0; i < actions.length; i++) {
    const a = actions[i];
    let ok;
    try { ok = G[a.fn](s, ...a.args); }
    catch (e) {
      // Diagnostic-only: a real, unexplained client/server replay divergence
      // was reported in production and couldn't be reproduced with a
      // synthetic self-replay test (same code, same process, passed clean),
      // so the next real occurrence needs to leave enough in `vercel logs`
      // to actually diagnose it — no player-identifying data beyond the
      // already-public displayName, and this is a debug aid, not a feature.
      console.error('[submit-run] replay threw', JSON.stringify({
        seed, teamKeys, mode, ascension, actionIndex: i, action: a,
        window: actions.slice(Math.max(0, i - 3), i + 1), errMsg: e.message,
      }));
      res.status(400).json({ accepted: false, reason: 'Replay threw at action ' + i + ' (' + a.fn + ')' }); return;
    }
    if (RETURN_CHECKED_FNS.has(a.fn) && ok === false) {
      console.error('[submit-run] replay rejected', JSON.stringify({
        seed, teamKeys, mode, ascension, actionIndex: i, action: a,
        window: actions.slice(Math.max(0, i - 3), i + 1),
        partySnapshot: s.party && s.party.map((u) => ({ uid: u.uid, n: u.n, hp: u.hp, used: u.used, side: u.side })),
        phase: s.phase, step: s.step,
      }));
      res.status(400).json({ accepted: false, reason: 'Replay rejected action ' + i + ' (' + a.fn + ') as invalid — log does not match a legal game session' });
      return;
    }
  }
  if (s.phase !== 'won' && s.phase !== 'lost') {
    res.status(400).json({ accepted: false, reason: 'Replayed run did not reach a won/lost end state — incomplete submission' });
    return;
  }

  const score = G.runXp(s, s.phase === 'won');
  const board = 'lb:' + mode + ':' + ascension;
  // Team/relics come from the server's OWN replayed `s`, never from the
  // client-submitted body — same trust boundary as `score` above, so
  // displaying "what did the #1 player actually run" on the Leaderboard adds
  // no new spoofing surface (a forged team would just be the wrong team for
  // whatever score the real replay produced, immediately implausible).
  const team = s.roster.map((e) => {
    const u = G.buildUnit(e, s);
    return { n: u.n, cls: u.cls, tier: u.tier, artIdx: u.artIdx, die: u.die.map(G.faceText) };
  });
  const relics = s.relics.map((id) => G.RELIC_BY_ID[id]).filter(Boolean).map((r) => ({ n: r.n, rar: r.rar, d: r.d }));
  const entry = JSON.stringify({
    name,
    wallet: typeof walletAddr === 'string' ? walletAddr.slice(0, 64) : null,
    score,
    won: s.phase === 'won',
    step: s.step,
    ts: Date.now(),
    team,
    relics,
  });

  const zres = await upstash('zadd', board, String(score), entry);
  if (zres === null) {
    res.status(200).json({ accepted: true, score, stored: false, reason: 'Leaderboard storage not configured on the server (UPSTASH_REDIS_REST_URL/TOKEN missing) — score computed but not saved.' });
    return;
  }
  res.status(200).json({ accepted: true, score, stored: true });
};
