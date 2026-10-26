-- M1 reset (Liam 26/10): everyone starts again as a NEW player. Do not run by hand: use tools/reset_m1.sh
-- (dry run by default). __RESET_ID__ and __NOW__ are filled in by the script. Players, sessions and desktop
-- tokens are kept (people stay signed in); everything the game saved or earned is deleted.
-- Order matters only for foreign keys: children first.
DELETE FROM mission_wins;
DELETE FROM mission_escrow;
DELETE FROM leaderboard_scores;
DELETE FROM raid_points;
DELETE FROM raid_daily;
DELETE FROM raid_challenges;
DELETE FROM raid_defense;
DELETE FROM runs;
DELETE FROM saves;
DELETE FROM inventory;
DELETE FROM unlocks;
DELETE FROM pass_xp;
DELETE FROM echobox_state;
DELETE FROM starter_claims;   -- so the starter grant is paid again, like a new account
DELETE FROM wallets;
DELETE FROM wallet_ledger;
-- One marker per player; GET /api/econ returns it as reset_id so a device that still holds old numbers can tell.
INSERT INTO wallet_ledger (player_id, currency, delta, reason, idem_key, at)
  SELECT id, 'op', 0, '{}', 'op:reset:__RESET_ID__', __NOW__ FROM players;
