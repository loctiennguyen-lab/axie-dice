-- Mission stake escrow (L1 option A, production/proposals/missions-online-l1.md). One row per mission run,
-- inserted in the SAME D1 batch as the run (POST /api/run kind=mission) and closed exactly once when the run
-- ends. The Shard movements are rows in wallet_ledger with currency 'shard' (idem keys mission_stake:{run} /
-- mission_settle:{run}); there is NO wallets balance for Shard (the balance still lives in the client save),
-- so this ledger is a record, not a spend check. Apply like the other migrations (production is a separate,
-- deliberate step).
CREATE TABLE mission_escrow (
  run_id       TEXT PRIMARY KEY REFERENCES runs(run_id) ON DELETE CASCADE,
  player_id    TEXT NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  tier         TEXT NOT NULL,                  -- N1..N3 (N4..N6 are refused at creation)
  stake        INTEGER NOT NULL,               -- Shard, from the server's copy of the table
  payout_mult  REAL NOT NULL,                  -- m_base * m_scale frozen at creation
  state        TEXT NOT NULL DEFAULT 'open' CHECK (state IN ('open', 'won', 'lost', 'refunded')),
  payout       INTEGER NOT NULL DEFAULT 0,     -- Shard paid at settle (0 unless won; the stake itself when refunded)
  created_at   INTEGER NOT NULL,
  settled_at   INTEGER
);
CREATE INDEX mission_escrow_by_player ON mission_escrow(player_id, state, created_at);
