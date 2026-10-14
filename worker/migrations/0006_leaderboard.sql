-- Ranked leaderboard (L1 C2). One row per finished ranked run, written by POST /api/leaderboard/submit
-- from the closed `runs` row (never from a client-supplied score). The board shows each player's BEST
-- score per (season, mode, ascension); the daily view filters on `day`. Apply like the other migrations
-- (staging/production is a deliberate separate step).
CREATE TABLE leaderboard_scores (
  run_id      TEXT PRIMARY KEY REFERENCES runs(run_id) ON DELETE CASCADE,  -- one row per run: submit is idempotent
  player_id   TEXT NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  season      TEXT NOT NULL,
  mode        TEXT NOT NULL,              -- short | full (game length, not run kind)
  ascension   INTEGER NOT NULL,
  score       INTEGER NOT NULL,
  won         INTEGER NOT NULL,           -- 0 | 1
  day         TEXT NOT NULL,              -- UTC 'YYYY-MM-DD' the run closed
  created_at  INTEGER NOT NULL
);
CREATE INDEX lb_board ON leaderboard_scores(season, mode, ascension, score DESC);
CREATE INDEX lb_day ON leaderboard_scores(day, mode, ascension, score DESC);
CREATE INDEX lb_player ON leaderboard_scores(player_id, season);
