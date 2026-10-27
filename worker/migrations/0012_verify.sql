-- SR-V: shadow verifier (ADD ONLY). Written only when env VERIFY_SHADOW=1. Nothing here feeds rewards, outcome or the leaderboard;
-- it is read by the shadow runner (HMAC endpoints) and by a human (GET /api/verify/stats).
-- Apply locally with: npx wrangler d1 migrations apply axie-dice-db --local   (remote is a separate, deliberate step)
CREATE TABLE IF NOT EXISTS verify_queue (
  run_id          TEXT PRIMARY KEY,
  rules_version   TEXT NOT NULL,
  platform        TEXT NOT NULL DEFAULT 'unknown',
  kind            TEXT NOT NULL DEFAULT 'normal',      -- normal | daily | ranked | mission (server's runs.mode)
  state           TEXT NOT NULL DEFAULT 'pending' CHECK (state IN ('pending', 'ok', 'mismatch', 'error')),
  srv_outcome     TEXT,
  client_score    INTEGER,                             -- summary.score the client claimed (NULL = not sent)
  header_mismatch INTEGER NOT NULL DEFAULT 0,          -- 1 = kind/mission disagree on the server side
  payload_json    TEXT,
  result_json     TEXT,
  reason          TEXT,
  attempts        INTEGER NOT NULL DEFAULT 0,
  created_at      INTEGER NOT NULL,
  claimed_at      INTEGER,
  finished_at     INTEGER
);
CREATE INDEX IF NOT EXISTS verify_queue_state ON verify_queue (state, created_at);

-- One row per verdict from the runner. verdict: match | outcome_mismatch | score_mismatch | rejected | error.
CREATE TABLE IF NOT EXISTS verify_results (
  run_id          TEXT PRIMARY KEY,
  verdict         TEXT NOT NULL,
  kind            TEXT NOT NULL,
  platform        TEXT NOT NULL,
  rules_version   TEXT NOT NULL,
  srv_outcome     TEXT,
  client_score    INTEGER,
  ok              INTEGER NOT NULL,
  reason          TEXT NOT NULL,
  v_outcome       TEXT NOT NULL,
  v_score         INTEGER NOT NULL,
  nodes           INTEGER NOT NULL,
  log_len         INTEGER NOT NULL,
  ms              INTEGER NOT NULL,
  at              INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS verify_results_verdict ON verify_results (verdict, at);
