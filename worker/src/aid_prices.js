// Server-side Gem prices and per-run caps for paid requests. Source of truth for charging; the
// client's godot/assets/data/economy/aid_prices.json is display only (a test keeps them equal).
// All numbers are tuning knobs (ADR 4.9): change here with a rules/economy bump, not in the client.
export const AID_BY_KIND = (kind, args) =>
  kind === 'continue' ? 'R1'
    : kind === 'reroll' && args.source === 'aid' ? 'R2'
      : kind === 'pact_reroll' ? 'R5'
        : kind === 'shop_refresh' ? 'R6' : null;

export const PRICES = {
  R1: { price: 90, cap_run: 1 },
  R2: { price: 15, cap_run: 4 },
  R5: { price: 15, cap_run: 4 },
  R6: { price: 18, cap_run: 2 },
};
/** Total paid uses per run: A0-A8 6, A9-A10 4 (aid_prices.json total_cap). */
export const totalCap = (ascension) => (ascension >= 9 ? 4 : 6);
export const GIFT = { per_day: 300, balance_cap: 900 };
/** Continue on a boss node (aid_prices.json R1.boss_price). Applied by RunCore._price from the logged node kind. */
export const BOSS_CONTINUE_PRICE = 180;
/** Season Pass gift (gem.json season_gift): 90 Gem at pass level 10 and 90 at level 20, once per account per season. */
export const SEASON_GIFT = { per_milestone: 90, milestones: 2 };
/** Season table (UTC dates, inclusive). Claims are accepted from start until end + grace_days. Unknown ids are refused. */
export const SEASONS = { S1: { start: '2026-11-03', end: '2026-12-29' } };
/** Server gates for season gifts: min completed runs per milestone (closed runs in the season window with
 *  battles_done >= min_battles), the grace after season end, and the balance cap shared with the daily gift. */
export const SEASON_GATES = { min_runs: { 1: 3, 2: 8 }, min_battles: 1, grace_days: 7, balance_cap: GIFT.balance_cap };
