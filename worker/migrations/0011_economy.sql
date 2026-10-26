-- Server economy (SR1, Liam 26/10: M1 reset, no balance import, no daily payout cap).
-- Shard / Stone / ticket balances reuse `wallets` + `wallet_ledger` (currency 'shard' | 'stone' | 'ticket').
-- Only ADDs. Apply like the other migrations (production is a separate, deliberate step).

-- Permanent unlocks (u_hp, u_reroll, ...). The server signs the loadout from this table.
CREATE TABLE unlocks (
  player_id  TEXT NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  unlock_id  TEXT NOT NULL,
  at         INTEGER NOT NULL,
  PRIMARY KEY (player_id, unlock_id)
);

-- Echo Box state. pity_json = {opens, since_<rarity>, fragments} (same shape the client used to keep in
-- echobox_pity). buy_day/buy_count = tickets bought with Shard today (UTC), for the stepped price and the day cap.
CREATE TABLE echobox_state (
  player_id  TEXT PRIMARY KEY REFERENCES players(id) ON DELETE CASCADE,
  opens      INTEGER NOT NULL DEFAULT 0,
  pity_json  TEXT NOT NULL DEFAULT '{}',
  buy_day    TEXT NOT NULL DEFAULT '',
  buy_count  INTEGER NOT NULL DEFAULT 0
);

-- Cosmetics won from the Echo Box (the std_* pool). Other sources (Pass, store) are still client-side.
CREATE TABLE inventory (
  player_id  TEXT NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  item_id    TEXT NOT NULL,
  at         INTEGER NOT NULL,
  PRIMARY KEY (player_id, item_id)
);

-- Hard limits live in the database so two parallel requests cannot both pass a read-then-write check.
CREATE TRIGGER wallets_ticket_hold_cap BEFORE UPDATE ON wallets
WHEN NEW.currency = 'ticket' AND NEW.balance > 999
BEGIN SELECT RAISE(ABORT, 'HOLD_CAP exceeded'); END;

CREATE TRIGGER echobox_buy_day_cap BEFORE UPDATE ON echobox_state
WHEN NEW.buy_count > 30
BEGIN SELECT RAISE(ABORT, 'DAY_CAP exceeded'); END;

-- One starter grant per durable identity (players.id = google:<sub>). No foreign key on purpose: deleting an
-- account and registering again must not hand out the starter a second time.
CREATE TABLE starter_claims (
  identity TEXT PRIMARY KEY,
  at       INTEGER NOT NULL
);
