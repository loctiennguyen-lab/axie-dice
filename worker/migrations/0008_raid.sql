-- Raid R1 ghost (design/proposals/land-v1-spec.md section 6). A player saves a defence team snapshot; others
-- fight it as AI enemies. Nobody loses anything: only Raid points (badges), no Stone, no economy.
-- Apply like the other migrations (a deliberate separate step, never automatic).
CREATE TABLE raid_defense (
  player_id   TEXT PRIMARY KEY REFERENCES players(id) ON DELETE CASCADE,
  ghost_id    TEXT NOT NULL UNIQUE,        -- opaque public id (random hex): the player id never leaves the server
  team_json   TEXT NOT NULL,               -- validated snapshot, see raid.js validateTeam
  skin_json   TEXT NOT NULL,               -- display-only {frame?, title?}, validated
  power_hint  INTEGER NOT NULL,
  updated_at  INTEGER NOT NULL
);
CREATE TABLE raid_challenges (
  challenge_id TEXT PRIMARY KEY,           -- 32 hex
  attacker_id  TEXT NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  defender_id  TEXT NOT NULL,              -- the defender's player id (internal)
  seed         INTEGER NOT NULL,           -- server-issued combat seed
  created_at   INTEGER NOT NULL,
  state        TEXT NOT NULL DEFAULT 'open',   -- open | done
  result       TEXT                        -- JSON {won,turns,h,points,counted}
);
CREATE INDEX raid_ch_attacker ON raid_challenges(attacker_id, state, created_at);
-- per attacker, per UTC day, per ghost: counts finished raids (points only while under the caps)
CREATE TABLE raid_daily (
  attacker_id TEXT NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  day         TEXT NOT NULL,
  defender_id TEXT NOT NULL,
  count       INTEGER NOT NULL,
  PRIMARY KEY (attacker_id, day, defender_id)
);
CREATE TABLE raid_points (
  player_id TEXT PRIMARY KEY REFERENCES players(id) ON DELETE CASCADE,
  points    INTEGER NOT NULL
);
