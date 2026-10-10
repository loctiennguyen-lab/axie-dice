-- Accounts v1 (claude/ACCOUNT_SYSTEM_v1.md §4). Apply with:
--   npx wrangler d1 migrations apply axie-dice-db --remote

-- One row per person. `id` is "<provider>:<subject>" (today only "google:<sub>"), so a second
-- sign-in method later is a new prefix, not a schema change. Email is NOT the key: it can change.
CREATE TABLE players (
  id             TEXT PRIMARY KEY,
  email          TEXT,
  display_name   TEXT,
  hd             TEXT,              -- Google Workspace domain, e.g. "skymavis.com"; NULL for Gmail
  created_at     INTEGER NOT NULL,  -- unix seconds
  last_login_at  INTEGER NOT NULL
);

-- The two blobs the client already writes locally (MetaState / RunState), stored verbatim as
-- JSON text. `rev` is the optimistic-concurrency counter: a write must name the rev it read.
CREATE TABLE saves (
  player_id   TEXT PRIMARY KEY REFERENCES players(id) ON DELETE CASCADE,
  meta_json   TEXT,
  run_json    TEXT,
  rev         INTEGER NOT NULL DEFAULT 0,
  updated_at  INTEGER NOT NULL
);

-- Only a SHA-256 of the session token is stored, so a copy of this table cannot sign anyone in.
CREATE TABLE sessions (
  id_hash     TEXT PRIMARY KEY,
  player_id   TEXT NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  created_at  INTEGER NOT NULL,
  expires_at  INTEGER NOT NULL
);
CREATE INDEX sessions_by_player ON sessions(player_id, expires_at);
