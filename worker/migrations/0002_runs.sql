-- Server-rolled runs (ADR server-authoritative-rng §4.9/§4.10). Apply LOCALLY with
--   npx wrangler d1 migrations apply axie-dice-db --local
-- Staging/production application is a separate, deliberate step (lane S never runs it).

-- One row per created run. D1 is the arbiter of "one open run per account": the partial unique
-- index counts pending and open, so two simultaneous POST /api/run cannot both pass.
CREATE TABLE runs (
  run_id         TEXT PRIMARY KEY,           -- 32 hex chars, also the Durable Object name
  player_id      TEXT NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  mode           TEXT NOT NULL,              -- the run KIND: normal | daily | ranked | mission
  ascension      INTEGER NOT NULL DEFAULT 0,
  rules_version  TEXT NOT NULL,
  state          TEXT NOT NULL,              -- pending | open | closed | abandoned | infra_error
  created_at     INTEGER NOT NULL,           -- unix seconds
  closed_at      INTEGER,
  outcome        TEXT,                       -- won | lost (client claim until the verifier exists)
  battles_done   INTEGER NOT NULL DEFAULT 0,
  summary_json   TEXT,                       -- run_close.summary, telemetry only
  commit_hash    TEXT                        -- commitment returned at creation; /api/run/open returns it again
);
CREATE UNIQUE INDEX runs_one_open_per_player ON runs(player_id) WHERE state IN ('pending', 'open');
CREATE INDEX runs_by_player_day ON runs(player_id, created_at);
