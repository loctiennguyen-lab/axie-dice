// Raid R1 ghost (design/proposals/land-v1-spec.md section 6). A player saves a "defence team" snapshot; other
// players fight it as AI enemies built client-side. Nobody loses anything: the only reward is Raid points
// (badges), never Stone or any economy value.
// RISK: like the leaderboard, the server does not replay the fight. It trusts the client's won/turns claim only
// inside bounds: the challenge must be the caller's, open, under 30 minutes old, not finished too fast, and the
// points are server-computed from the daily caps. Real replay verification is a later lane.
//
//   POST /api/raid/defense   { team:[unit], skin:{}, power_hint }  -> { ok, ghost_id }
//        unit = { key, cls, hp, die:[6 x {type, value, kw?:[..]}] }   1..5 units
//   GET  /api/raid/opponents                                         -> { opponents:[{ghost_id,name,team,skin,power_hint}], points }
//   POST /api/raid/start     { ghost_id }                            -> { challenge_id, seed, team, skin, name }
//   POST /api/raid/finish    { challenge_id, won, turns, h }  h = sha256hex("id|seed|won(0/1)|turns")   -> { ok, points, counted, reason?, total, badge? }
//        errors: 401 / 403 forbidden|not_yours|own_ghost / 404 not_found / 409 already_done|expired / 422 bad_result|too_fast
import { shared } from './accounts.js';

const { json } = shared;
export const TEAM_MAX = 5;
export const FACES = 6;
export const BODY_MAX = 6000;            // bytes of the whole request body
export const CLASSES = ['plant', 'beast', 'aqua', 'reptile', 'bug', 'bird'];
export const FACE_TYPES = ['dmg', 'shield', 'heal', 'mana', 'poison', 'debuff', 'buff', 'summon', 'blank'];
export const OPPONENTS = 5;
export const PER_GHOST_DAILY = 3;
export const DAILY_RAIDS = 5;
export const POINTS_WIN = 3;
export const POINTS_LOSS = 1;
export const BADGES = [10, 30, 75, 150, 300];   // 5 Raid milestones (total points)
export const CHALLENGE_TTL_S = 30 * 60;
export const MIN_FIGHT_S = 8;            // a fight cannot honestly end sooner
export const OPEN_MAX = 6;              // unfinished challenges per player inside the TTL
export const TURNS_MAX = 60;

const nowS = () => Math.floor(Date.now() / 1000);
const utcDay = (s) => new Date(s * 1000).toISOString().slice(0, 10);
const intIn = (v, lo, hi) => Number.isInteger(v) && v >= lo && v <= hi;
const hex = (n) => { const b = new Uint8Array(n); crypto.getRandomValues(b); return Array.from(b, (x) => x.toString(16).padStart(2, '0')).join(''); };

export const isRaidPath = (p) => p === '/api/raid/defense' || p === '/api/raid/opponents' || p === '/api/raid/start' || p === '/api/raid/finish';

/** Pure: validate + normalise a defence team. Returns the clean array, or null = refuse. Unknown fields are dropped. */
export function validateTeam(team) {
  if (!Array.isArray(team) || team.length < 1 || team.length > TEAM_MAX) return null;
  const out = [];
  for (const u of team) {
    if (!u || typeof u !== 'object' || Array.isArray(u)) return null;
    if (typeof u.key !== 'string' || !/^[a-z0-9_]{1,32}$/.test(u.key)) return null;
    if (!CLASSES.includes(u.cls)) return null;
    if (!intIn(u.hp, 1, 999)) return null;
    if (!Array.isArray(u.die) || u.die.length !== FACES) return null;
    const die = [];
    for (const f of u.die) {
      if (!f || typeof f !== 'object' || Array.isArray(f)) return null;
      if (!FACE_TYPES.includes(f.type)) return null;
      if (!intIn(f.value, 0, 99)) return null;
      const kw = f.kw === undefined ? [] : f.kw;
      if (!Array.isArray(kw) || kw.length > 4 || !kw.every((k) => typeof k === 'string' && /^[a-z_]{1,16}$/.test(k))) return null;
      die.push({ type: f.type, value: f.value, kw });
    }
    out.push({ key: u.key, cls: u.cls, hp: u.hp, die });
  }
  return out;
}

/** Pure: display-only skin. {frame?, title?} ids; anything else is dropped. null = refuse. */
export function validateSkin(skin) {
  if (skin === undefined || skin === null) return {};
  if (typeof skin !== 'object' || Array.isArray(skin)) return null;
  const out = {};
  for (const k of ['frame', 'title', 'die_skin']) {
    if (skin[k] === undefined || skin[k] === null || skin[k] === '') continue;
    if (typeof skin[k] !== 'string' || !/^[A-Za-z0-9_.-]{1,40}$/.test(skin[k])) return null;
    out[k] = skin[k];
  }
  return out;
}

/** Pure: which badge milestone does going from `before` to `after` points cross? Highest index (1..5) or null. */
export function badgeCrossed(before, after) {
  let hit = null;
  BADGES.forEach((m, i) => { if (before < m && after >= m) hit = i + 1; });
  return hit;
}

/** Pure: the 64-hex digest the client sends, same formula as RaidClient.result_hash. */
export async function resultHash(challengeId, seed, won, turns) {
  const d = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(`${challengeId}|${seed}|${won ? 1 : 0}|${turns}`));
  return Array.from(new Uint8Array(d), (x) => x.toString(16).padStart(2, '0')).join('');
}

const displayName = (n) => (String(n || '').trim().split(/\s+/)[0].replace(/@.*$/, '').slice(0, 16)) || 'Player';

async function readBody(request, url) {
  if (request.headers.get('Origin') && !shared.isAllowedOrigin(request.headers.get('Origin'), url)) return { err: json({ error: 'forbidden' }, 403) };
  let text;
  try { text = await request.text(); } catch { return { err: json({ error: 'bad_request' }, 400) }; }
  if (text.length > BODY_MAX) return { err: json({ error: 'too_large' }, 413) };
  let body;
  try { body = JSON.parse(text); } catch { return { err: json({ error: 'bad_request' }, 400) }; }
  if (!body || typeof body !== 'object' || Array.isArray(body)) return { err: json({ error: 'bad_request' }, 400) };
  return { body };
}

async function saveDefense(request, env, url, player) {
  const { body, err } = await readBody(request, url);
  if (err) return err;
  const team = validateTeam(body.team);
  const skin = validateSkin(body.skin);
  if (!team || !skin || !intIn(body.power_hint, 0, 9999)) return json({ error: 'bad_request' }, 400);
  const t = nowS();
  const existing = await env.DB.prepare('SELECT ghost_id FROM raid_defense WHERE player_id = ?').bind(player.id).first();
  const ghostId = existing ? existing.ghost_id : hex(8);
  await env.DB.prepare(
    `INSERT INTO raid_defense (player_id, ghost_id, team_json, skin_json, power_hint, updated_at) VALUES (?, ?, ?, ?, ?, ?)
     ON CONFLICT(player_id) DO UPDATE SET team_json = excluded.team_json, skin_json = excluded.skin_json, power_hint = excluded.power_hint, updated_at = excluded.updated_at`,
  ).bind(player.id, ghostId, JSON.stringify(team), JSON.stringify(skin), body.power_hint, t).run();
  return json({ ok: true, ghost_id: ghostId });
}

async function opponents(env, player) {
  const rows = await env.DB.prepare(
    `SELECT d.ghost_id, d.team_json, d.skin_json, d.power_hint, p.display_name AS name
       FROM raid_defense d JOIN players p ON p.id = d.player_id
      WHERE d.player_id != ? ORDER BY RANDOM() LIMIT ?`,
  ).bind(player.id, OPPONENTS).all();
  const list = (rows.results || []).map((r) => ({
    ghost_id: r.ghost_id, name: displayName(r.name), team: JSON.parse(r.team_json), skin: JSON.parse(r.skin_json), power_hint: r.power_hint,
  }));
  const pts = await env.DB.prepare('SELECT points FROM raid_points WHERE player_id = ?').bind(player.id).first();
  return json({ opponents: list, points: pts ? pts.points : 0 });
}

async function start(request, env, url, player) {
  const { body, err } = await readBody(request, url);
  if (err) return err;
  if (typeof body.ghost_id !== 'string' || !/^[a-f0-9]{16}$/.test(body.ghost_id)) return json({ error: 'bad_request' }, 400);
  const g = await env.DB.prepare(
    `SELECT d.player_id, d.team_json, d.skin_json, p.display_name AS name FROM raid_defense d JOIN players p ON p.id = d.player_id WHERE d.ghost_id = ?`,
  ).bind(body.ghost_id).first();
  if (!g) return json({ error: 'not_found' }, 404);
  if (g.player_id === player.id) return json({ error: 'own_ghost' }, 403);
  const t = nowS();
  const open = await env.DB.prepare(`SELECT COUNT(*) AS n FROM raid_challenges WHERE attacker_id = ? AND state = 'open' AND created_at > ?`).bind(player.id, t - CHALLENGE_TTL_S).first();
  if (open.n >= OPEN_MAX) return json({ error: 'rate_limited' }, 429);
  const challengeId = hex(16);
  const seed = 1 + (crypto.getRandomValues(new Uint32Array(1))[0] % 2147483646);
  await env.DB.prepare('INSERT INTO raid_challenges (challenge_id, attacker_id, defender_id, seed, created_at, state) VALUES (?, ?, ?, ?, ?, ?)')
    .bind(challengeId, player.id, g.player_id, seed, t, 'open').run();
  return json({ challenge_id: challengeId, seed, team: JSON.parse(g.team_json), skin: JSON.parse(g.skin_json), name: displayName(g.name) });
}

async function finish(request, env, url, player) {
  const { body, err } = await readBody(request, url);
  if (err) return err;
  if (typeof body.challenge_id !== 'string' || !/^[a-f0-9]{32}$/.test(body.challenge_id)) return json({ error: 'bad_request' }, 400);
  if (typeof body.won !== 'boolean' || !intIn(body.turns, 1, TURNS_MAX) || typeof body.h !== 'string' || !/^[a-f0-9]{16,64}$/.test(body.h)) return json({ error: 'bad_result' }, 422);
  const c = await env.DB.prepare('SELECT attacker_id, defender_id, seed, created_at, state FROM raid_challenges WHERE challenge_id = ?').bind(body.challenge_id).first();
  if (!c) return json({ error: 'not_found' }, 404);
  if (c.attacker_id !== player.id) return json({ error: 'not_yours' }, 403);
  if (c.state !== 'open') return json({ error: 'already_done' }, 409);
  const t = nowS();
  if (t - c.created_at > CHALLENGE_TTL_S) return json({ error: 'expired' }, 409);
  if (t - c.created_at < MIN_FIGHT_S) return json({ error: 'too_fast' }, 422);
  // h binds the claim to this challenge and its server seed (raid_client.gd result_hash). Not a proof of play, but a
  // forged call must know the seed the server issued to this player.
  if (body.h !== await resultHash(body.challenge_id, c.seed, body.won, body.turns)) return json({ error: 'bad_result' }, 422);
  // claim the challenge first: a double submit (or a race) can only win once
  const claim = await env.DB.prepare(`UPDATE raid_challenges SET state = 'done' WHERE challenge_id = ? AND state = 'open'`).bind(body.challenge_id).run();
  if (!claim.meta || claim.meta.changes !== 1) return json({ error: 'already_done' }, 409);
  const day = utcDay(t);
  // ONE statement decides both caps, so parallel finishes cannot slip past them: the row is inserted (or its count
  // bumped) only while the day total is under DAILY_RAIDS and this ghost's count is under PER_GHOST_DAILY.
  const bump = await env.DB.prepare(
    `INSERT INTO raid_daily (attacker_id, day, defender_id, count)
     SELECT ?1, ?2, ?3, 1 WHERE (SELECT COALESCE(SUM(count), 0) FROM raid_daily WHERE attacker_id = ?1 AND day = ?2) < ?4
     ON CONFLICT(attacker_id, day, defender_id) DO UPDATE SET count = count + 1 WHERE count < ?5`,
  ).bind(player.id, day, c.defender_id, DAILY_RAIDS, PER_GHOST_DAILY).run();
  const counted = !!(bump.meta && bump.meta.changes === 1);
  let reason;
  if (!counted) {
    const total = await env.DB.prepare('SELECT COALESCE(SUM(count), 0) AS n FROM raid_daily WHERE attacker_id = ? AND day = ?').bind(player.id, day).first();
    reason = total.n >= DAILY_RAIDS ? 'daily_cap' : 'ghost_cap';
  }
  const points = counted ? (body.won ? POINTS_WIN : POINTS_LOSS) : 0;
  let badge = null;
  let was;
  if (counted) {
    await env.DB.prepare(
      `INSERT INTO raid_points (player_id, points) VALUES (?, ?) ON CONFLICT(player_id) DO UPDATE SET points = points + excluded.points`,
    ).bind(player.id, points).run();
    const now = await env.DB.prepare('SELECT points FROM raid_points WHERE player_id = ?').bind(player.id).first();
    was = now.points - points;   // derived after the atomic add, so parallel finishes cannot double-report a badge
    badge = badgeCrossed(was, was + points);
  } else {
    const cur = await env.DB.prepare('SELECT points FROM raid_points WHERE player_id = ?').bind(player.id).first();
    was = cur ? cur.points : 0;
  }
  const result = { won: body.won, turns: body.turns, h: body.h, points, counted };
  await env.DB.prepare('UPDATE raid_challenges SET result = ? WHERE challenge_id = ?').bind(JSON.stringify(result), body.challenge_id).run();
  const out = { ok: true, points, counted, total: was + points };
  if (reason) out.reason = reason;
  if (badge) out.badge = badge;
  return json(out);
}

export async function handleRaid(request, env, url) {
  try {
    const p = url.pathname;
    const wantsGet = p === '/api/raid/opponents';
    if (request.method !== (wantsGet ? 'GET' : 'POST')) return json({ error: 'not_found' }, 404);
    const player = await shared.currentPlayer(request, env);
    if (!player) return json({ error: 'unauthenticated' }, 401);
    if (env.RUN_LIMITER) {
      const { success } = await env.RUN_LIMITER.limit({ key: `raid:${player.id}` });
      if (!success) return json({ error: 'rate_limited' }, 429);
    }
    if (p === '/api/raid/defense') return await saveDefense(request, env, url, player);
    if (wantsGet) return await opponents(env, player);
    if (p === '/api/raid/start') return await start(request, env, url, player);
    if (p === '/api/raid/finish') return await finish(request, env, url, player);
    return json({ error: 'not_found' }, 404);
  } catch (e) {
    console.error('raid error', url.pathname, String((e && e.stack) || e));
    return json({ error: 'server' }, 500);
  }
}
