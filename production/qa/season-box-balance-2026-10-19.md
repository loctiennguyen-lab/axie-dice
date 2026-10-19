# Season box balance check (19/10/2026, lane E)

Data: `godot/assets/data/economy/echobox.json` boxes.season. Logic: `EchoBox.open_season`.
Sim: 20,000 runs of the exact algorithm (c_t counters, p = (2c-1)/(N^2-(c-1)^2), certain at cap, dup tickets back).

## Config
- 5 normal tickets per pull, cap 8 pulls a day (max 40 tickets a day), escalation k=2.
- Sets: Epic 6 (cap 10), Legendary 3 (cap 20), Mythic 2 (cap 40). 11 items. Vault cap scale x2.
- full_set_pity 80: EconomyDB check max n_t*(N_t+h_t) = max(2*40, 3*21, 6*12) = 80 <= 80. OK, exactly at the limit.

## Results (fresh account, no Vault)
- Pulls to complete: mean 57.7, median 56, p95 75, max 80 (never above the 80 bound). 
- Tickets spent: mean 289 gross, about 285 net (duplicates of finished tiers give back 3.9 tickets on average). Worst case 400.
- Milestones: 12 pulls = 60 tickets (title), 40 pulls = 200 tickets (die_m_moon + title), full set = 289 tickets on average.
- Minimum days to finish: 10 (8 pulls a day). Series runs 12 weeks, so the cap does not block completion.
- Existing t_economy checks (40 seeds: full set <= 80, first Mythic <= 40, Vault <= 160) stay green.

## Ticket income vs need
- Free tickets: 3 starter + 12 from the Pass = 15 (3 pulls).
- Shard route: ticket k of the day costs round5(200 x 1.05^(k-1)). 5 tickets = 1,105 Shard, 10 = 2,515, 30 = 13,275. Buy cap 30 a day.
- Free Shard over one Pass season is about 4,800 (Pass) + 60/day Daily + 150/week Weekly = roughly 9-10k, which buys about 40-45 tickets. A full set (289 tickets) at 5-10 tickets a day costs about 64-72k Shard, so it needs Gem bundles, Mission wins, or a very long grind. The 12-pull title (60 tickets) is reachable by a normal player; the 40-pull exclusive (200 tickets) is a stretch; completion is a spender/grinder goal. This is a design intent question, not a bug. Flag for Liam.

## Invariants (build-spec INV-1..7)
- INV-1/2/3/4/5: the box grants only cosmetics (die/frame/fx/title) and Stone. No part identity, rarity-power or tier changes. OK.
- INV-6: tickets can be bought with Gem (real money) but they buy only cosmetics and Stone, no power. OK. Note Stone (Land currency) comes from the season stone table, EV 1,290 per Stone pull (checked +-3% by EconomyDB). Season box pays about 78% Stone pulls, 5 tickets each: Stone per ticket is lower than the normal box (EV 242 x 0.6 per ticket ~ 145), season is about 1,290 x 0.78 / 5 ~ 200 per ticket. Slightly higher but same order of magnitude. OK.
- INV-7: runs are never gated by tickets. The season box is not on the run path. OK.
- RULES_VERSION: season box does not change run results. No bump needed.

## Findings to act on
1. Seven season items are also in the normal pool art_map (removed in this lane). `die_m_moon` is the 40-pull exclusive reward and is ALSO in the normal Mythic art_map. It is removed from the normal pool too.
2. Epic has no non-season, non-Pass art left: all 4 epic dice/frames are season items or Pass-exclusive Founder items. The normal Epic tier uses the Founder Seal / Founder Laurel as placeholders until new Epic art exists (needs Liam's call).
3. The `title_s1_*` ids were granted as raw ids; TitleNames only reads "title:<NAME>". Fixed in this lane.

No invariant is broken. Safe to enable.
