-- Mission tier unlock by win chain (beta, N-W): winning tier N opens N+1. One row per WON mission run, written in
-- the same batch that settles its escrow as 'won' (missions.js settleEscrow), keyed by run so a retried settle
-- cannot count a win twice. No FK to runs/mission_escrow on purpose: a win stays counted even if the run row is
-- ever pruned. Only ADD: nothing existing is touched. Apply BEFORE deploying the Worker that writes it.
-- Caveat (accepted by Liam 26/10): `won` is still the client's claim until the verifier lands, so a fake won run
-- can open the next tier; the server only stops a save edit from buying a tier the player never won through.
CREATE TABLE mission_wins (
  run_id     TEXT PRIMARY KEY,
  player_id  TEXT NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  tier       TEXT NOT NULL,
  at         INTEGER NOT NULL
);
CREATE INDEX mission_wins_by_player ON mission_wins(player_id, tier);
