-- Server-side wallet (ADR 4.9). Gem lives here, not in the client save (Liam 12/10).
-- D1 is the only source of truth for the balance; the client keeps a display cache.
CREATE TABLE wallets (
  player_id  TEXT NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  currency   TEXT NOT NULL,                       -- 'gem' for now
  balance    INTEGER NOT NULL DEFAULT 0 CHECK (balance >= 0),
  PRIMARY KEY (player_id, currency)
);

-- Append-only ledger. UNIQUE(player_id, idem_key) makes every money operation idempotent: the key
-- is built by the SERVER from the operation (grant:{player}:{utc-day}, aid:{run}:{seq}, ...).
CREATE TABLE wallet_ledger (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  player_id  TEXT NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  currency   TEXT NOT NULL,
  delta      INTEGER NOT NULL,
  reason     TEXT NOT NULL,
  idem_key   TEXT NOT NULL,
  at         INTEGER NOT NULL,
  UNIQUE (player_id, idem_key)
);
CREATE INDEX wallet_ledger_by_player ON wallet_ledger(player_id, id);
