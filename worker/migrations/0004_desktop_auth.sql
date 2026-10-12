-- Desktop login via the Worker (ADR 4.8, C5): one-time codes + per-device sessions with rotating refresh.
-- Only hashes are stored, so a copy of these tables signs nobody in.
CREATE TABLE desktop_codes (
  code_hash   TEXT PRIMARY KEY,
  player_id   TEXT NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  challenge   TEXT NOT NULL,            -- PKCE S256 challenge the client committed to
  expires_at  INTEGER NOT NULL          -- 60 s
);

CREATE TABLE device_sessions (
  id                 TEXT PRIMARY KEY,
  player_id          TEXT NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  label              TEXT NOT NULL,
  refresh_hash       TEXT NOT NULL UNIQUE,
  prev_refresh_hash  TEXT,                -- the refresh token just rotated away, honoured for a grace window
  rotated_at         INTEGER,
  created_at         INTEGER NOT NULL,
  last_seen          INTEGER NOT NULL,
  revoked            INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX device_sessions_by_player ON device_sessions(player_id);

CREATE TABLE device_tokens (
  token_hash  TEXT PRIMARY KEY,
  device_id   TEXT NOT NULL REFERENCES device_sessions(id) ON DELETE CASCADE,
  expires_at  INTEGER NOT NULL
);
CREATE INDEX device_tokens_by_device ON device_tokens(device_id);
