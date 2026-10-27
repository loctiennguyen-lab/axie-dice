-- SR-V: shadow verifier queue (ADD ONLY). One row per closed run, only written when env VERIFY_SHADOW=1.
-- The row never feeds rewards, outcome or the leaderboard; it is read by the shadow runner and by humans.
-- Apply locally with: npx wrangler d1 migrations apply axie-dice-db --local   (remote is a separate, deliberate step)
CREATE TABLE IF NOT EXISTS verify_queue (
  run_id        TEXT PRIMARY KEY,
  rules_version TEXT NOT NULL,
  platform      TEXT NOT NULL DEFAULT 'unknown',
  state         TEXT NOT NULL DEFAULT 'pending' CHECK (state IN ('pending', 'ok', 'mismatch', 'error')),
  srv_outcome   TEXT,
  payload_json  TEXT,
  result_json   TEXT,
  reason        TEXT,
  attempts      INTEGER NOT NULL DEFAULT 0,
  created_at    INTEGER NOT NULL,
  claimed_at    INTEGER,
  finished_at   INTEGER
);
CREATE INDEX IF NOT EXISTS verify_queue_state ON verify_queue (state, created_at);
