// Server copy of the prices the client shows. test/econ_tables_match.test.mjs compares it with
// godot/autoload/ContentDB.gd (UNLOCKS) so the two cannot drift apart silently.
export const UNLOCKS = {
  u_full: 120, u_relic1: 150, u_face1: 180, u_reroll: 220, u_relic2: 280,
  u_face2: 350, u_start: 400, u_hp: 500, u_reroll2: 650, u_hp2: 600,
};
// Upper bound for the Shard reward of ONE closed run, claimed by run id. The amount itself is the client's number
// until the verifier (B3) exists; Liam accepted that risk (26/10, no daily cap), this only stops absurd values.
export const RUN_SHARD_MAX = 3000;
