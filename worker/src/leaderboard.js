// Ranked leaderboard (L1 C2, design/gdd/leaderboard-system.md). Score = the Pass XP formula
//   30 + 10*(waves) + 30*elites + 60*bosses + 150*won + 25*ascension + 40*full
// computed by the client (RunState.close_summary().score) and sent in run_close.summary.
// RISK (P3): the server does not replay or verify run results yet, so the score is the client's claim,
// trusted through the run hash chain only. We bound it, we require a closed ranked run owned by the caller,
// and one run gives one row - nothing more. Real verification is a later lane.
//
//   POST /api/leaderboard/submit  { run_id }    -> { ok, score, season, rank }   (409 not_closed, 403 not_ranked ...)
//   GET  /api/leaderboard?board=season|daily&mode=short|full&asc=0..10&limit=1..100
//                                 -> { season, board, mode, ascension, day, entries:[{rank,name,score,won}],
//                                      self:{rank,score}|null, total }
import { shared } from './accounts.js';

const { json } = shared;
export const SEASON_DEFAULT = 'S1';
export const SCORE_MAX = 1500;       // a Full A10 win with every elite/boss is ~1000; headroom, still a hard bound
const LIMIT_DEFAULT = 50;
const LIMIT_MAX = 100;
const nowS = () => Math.floor(Date.now() / 1000);
const utcDay = (s) => new Date(s * 1000).toISOString().slice(0, 10);
const season = (env) => (typeof env.LB_SEASON === 'string' && /^[A-Za-z0-9_-]{1,16}$/.test(env.LB_SEASON) ? env.LB_SEASON : SEASON_DEFAULT);

export const isLeaderboardPath = (p) => p === '/api/leaderboard' || p === '/api/leaderboard/submit';

/** Pure: pick a sane {score, mode} from a run's stored summary. null = refuse. */
export function scoreFromSummary(summaryJson) {
  let s;
  try { s = JSON.parse(summaryJson || '{}'); } catch { return null; }
  if (!s || typeof s !== 'object' || Array.isArray(s)) return null;
  if (!Number.isInteger(s.score) || s.score < 0 || s.score > SCORE_MAX) return null;
  if (s.len !== 'short' && s.len !== 'full') return null;
  return { score: s.score, mode: s.len };
}

async function submit(request, env, url, player) {
  if (request.headers.get('Origin') && !shared.isAllowedOrigin(request.headers.get('Origin'), url)) return json({ error: 'forbidden' }, 403);
  let body;
  try { body = await request.json(); } catch { return json({ error: 'bad_request' }, 400); }
  const runId = body && typeof body === 'object' ? body.run_id : null;
  if (typeof runId !== 'string' || !/^[a-f0-9]{32}$/.test(runId)) return json({ error: 'bad_request' }, 400);
  const run = await env.DB.prepare('SELECT player_id, mode, ascension, state, outcome, battles_done, closed_at, summary_json FROM runs WHERE run_id = ?').bind(runId).first();
  if (!run || run.player_id !== player.id) return json({ error: 'not_found' }, 404);
  if (run.mode !== 'ranked') return json({ error: 'not_ranked' }, 403);
  // Only a run the Durable Object closed counts: 'abandoned' and 'infra_error' never reach a board.
  if (run.state !== 'closed' || run.outcome == null) return json({ error: 'not_closed' }, 409);
  if (!(run.battles_done >= 1)) return json({ error: 'no_battles' }, 422);
  const sc = scoreFromSummary(run.summary_json);
  if (!sc) return json({ error: 'bad_score' }, 422);
  const won = run.outcome === 'won' ? 1 : 0;
  const at = run.closed_at || nowS();
  const seasonId = season(env);
  // INSERT OR IGNORE: the second submit of the same run is a harmless replay.
  await env.DB.prepare(
    `INSERT OR IGNORE INTO leaderboard_scores (run_id, player_id, season, mode, ascension, score, won, day, created_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
  ).bind(runId, player.id, seasonId, sc.mode, run.ascension, sc.score, won, utcDay(at), nowS()).run();
  const stored = await env.DB.prepare('SELECT score, season, mode, ascension FROM leaderboard_scores WHERE run_id = ?').bind(runId).first();
  const rank = await rankOf(env, player.id, { season: stored.season, mode: stored.mode, asc: stored.ascension, day: null });
  return json({ ok: true, score: stored.score, season: stored.season, mode: stored.mode, ascension: stored.ascension, rank: rank ? rank.rank : null });
}

/** Best score per player on one board, and the caller's competition rank (ties share a rank). */
async function rankOf(env, playerId, f) {
  const where = f.day ? 'day = ? AND mode = ? AND ascension = ?' : 'season = ? AND mode = ? AND ascension = ?';
  const args = [f.day || f.season, f.mode, f.asc];
  const mine = await env.DB.prepare(`SELECT MAX(score) AS best FROM leaderboard_scores WHERE ${where} AND player_id = ?`).bind(...args, playerId).first();
  if (!mine || mine.best == null) return null;
  const ahead = await env.DB.prepare(
    `SELECT COUNT(*) AS n FROM (SELECT player_id, MAX(score) AS best FROM leaderboard_scores WHERE ${where} GROUP BY player_id) WHERE best > ?`,
  ).bind(...args, mine.best).first();
  return { rank: ahead.n + 1, score: mine.best };
}

async function read(request, env, url) {
  const q = url.searchParams;
  const board = q.get('board') === 'daily' ? 'daily' : 'season';
  const mode = q.get('mode') === 'full' ? 'full' : 'short';
  const asc = Number.parseInt(q.get('asc') ?? '0', 10);
  if (!Number.isInteger(asc) || asc < 0 || asc > 10) return json({ error: 'bad_request' }, 400);
  const limit = Math.min(LIMIT_MAX, Math.max(1, Number.parseInt(q.get('limit') ?? String(LIMIT_DEFAULT), 10) || LIMIT_DEFAULT));
  const day = board === 'daily' ? utcDay(nowS()) : null;
  const seasonId = season(env);
  const f = { season: seasonId, mode, asc, day };
  const where = day ? 'day = ? AND mode = ? AND ascension = ?' : 'season = ? AND mode = ? AND ascension = ?';
  const args = [day || seasonId, mode, asc];
  const rows = await env.DB.prepare(
    `SELECT s.player_id AS pid, p.display_name AS name, s.best AS score,
            (SELECT won FROM leaderboard_scores w WHERE w.player_id = s.player_id AND w.score = s.best AND ${where.replace(/\b(day|mode|ascension|season)\b/g, 'w.$1')} ORDER BY w.created_at LIMIT 1) AS won
       FROM (SELECT player_id, MAX(score) AS best, MIN(created_at) AS first_at FROM leaderboard_scores WHERE ${where} GROUP BY player_id) s
       JOIN players p ON p.id = s.player_id
      ORDER BY s.best DESC, s.first_at ASC LIMIT ?`,
  ).bind(...args, ...args, limit).all();
  const list = rows.results || [];
  const entries = [];
  let prev = null; let rank = 0;
  list.forEach((r, i) => {
    if (r.score !== prev) { rank = i + 1; prev = r.score; }
    entries.push({ rank, name: displayName(r.name), score: r.score, won: !!r.won });
  });
  const total = (await env.DB.prepare(`SELECT COUNT(DISTINCT player_id) AS n FROM leaderboard_scores WHERE ${where}`).bind(...args).first()).n;
  let self = null;
  const player = await shared.currentPlayer(request, env);
  if (player) self = await rankOf(env, player.id, f);
  return json({ season: seasonId, board, mode, ascension: asc, day, entries, self, total });
}

/** First name only, 16 chars: the board is public, an email-shaped display name must not leak. */
function displayName(n) {
  const s = String(n || '').trim().split(/\s+/)[0].replace(/@.*$/, '').slice(0, 16);
  return s || 'Player';
}

export async function handleLeaderboard(request, env, url) {
  try {
    if (env.RUN_LIMITER) {
      const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
      const { success } = await env.RUN_LIMITER.limit({ key: `lb:${ip}` });
      if (!success) return json({ error: 'rate_limited' }, 429);
    }
    if (url.pathname === '/api/leaderboard' && request.method === 'GET') return await read(request, env, url);
    if (url.pathname === '/api/leaderboard/submit' && request.method === 'POST') {
      const player = await shared.currentPlayer(request, env);
      if (!player) return json({ error: 'unauthenticated' }, 401);
      return await submit(request, env, url, player);
    }
    return json({ error: 'not_found' }, 404);
  } catch (err) {
    console.error('leaderboard error', url.pathname, String(err && err.stack || err));
    return json({ error: 'server' }, 500);
  }
}
