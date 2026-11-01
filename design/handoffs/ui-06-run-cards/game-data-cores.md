# Axie Dice: Cores, Anchors and Run Rules (real data, 1 Nov 2026)

Generated from the game data (`godot/resources/relics/*.tres`, `assets/data/rules/*.json`). Test entries (`c_test_*`, `rule_test_*`) are left out. Text is the in-game English text. Numbers are real.

**Core tiers:** Moss (tier 0) → Amber (tier 1) → Crystal (tier 2, strongest, capped per run). **Families** (`core_axis`): `stat` = Stat, `dice` = Dice, `pos` = Position, `mana` = Mana, `quest` = Quest, `rule` = Rule. A run holds up to 6 Cores.

**Glossary shown on the Anchor screen:** SET = 3+ dice that match and fire together. M = a die's damage multiplier. Cracked = a die broken by a risky reroll (Gamble). Held = a die you keep for next turn. Temp Face = a die that joins any SET for one turn. House Cores = the 5 Cores tied to an Anchor.

## 10 sample Cores for the text-structure examples

- `c_thorn_shield` Thorn Shield (Amber, Stat): End of your turn, every 2 leftover Shield on an Axie turns into 1 Thorns (that Shield is lost).
- `c_dewdrop` Dewdrop (Moss, Stat): +1 Mana at the start of every turn.
- `c_concord` Concord (Crystal, Dice): Start of turn: Axies of the same class roll the same face. Each face used right after a face from the same part gets +2.
- `c_cache_plate` Cache Plate (Amber, Dice): When you Hold a die showing a shield face, its Axie gains half that Shield now (rounded up, min 2, max 6, no M). Once per die per turn. The die keeps its full face for next turn.
- `c_descend` Take The Field (Crystal, Position): Pick a back-row Axie with heal faces: it moves to the front for good, its heal and buff faces become damage faces +2, +8 Max HP, 30% lifesteal.
- `c_backline_glow` Backline Glow (Amber, Position): Back-row Axies: buff, heal and mana faces get +50% (rounded up, at most +8).
- `c_deep_current` Deep Current (Crystal, Mana): Leftover Mana carries into the next combat (up to 12) instead of resetting.
- `c_golden_thread` Golden Thread (Amber, Mana): Wild Face costs 1 less Mana (min 1) and can be used 2 times per fight. A Set of four made with a Wild Face gets +0.20 M.
- `c_chimera_hunt` Chimera Hunt (Amber, Quest): Quest in 3 steps: kill 8 enemies with a finishing die for +1 Core reroll; kill 20 for an Amber Core pick; kill a boss with a finishing die for a Crystal Core pick.
- `c_blood_sign` Blood Sign (Crystal, Rule): Damage faces add 1 poison per 3 damage dealt (rounded down). Poison faces also deal damage equal to half their value.

## Anchors (6, all of them)

### Volley (`a_volley`, house `h_volley`, emblem `house_volley`)
- Tagline: A matching group of 3+ dice also hits every enemy.
- Rule: Every turn a SET of 3+ fires once: all enemies take 40/65/90% of the SET's base total (max 20).
- Awakens: **Thorn Storm**: The SET fires a second time when you use its last die, and the blast pierces enemy Shield. (when you hold 2 of the 5 House Cores)
- House Cores: Shield Wave (`c_sonic_shield`), Thorn Shield (`c_thorn_shield`), Living Wall (`c_living_wall`), Backline Glow (`c_backline_glow`), Take The Field (`c_descend`)
- House mutation: **Spiked Shield**: tier 1: 1/3 of the Shield from a Shield-face die in a SET turns into Thorns until the end of the enemy turn (rounded down, max 4 per Axie). Tier 2: Thorns keep the full number; the Shield is not reduced.

### Gambler (`a_gambler`, house `h_gambler`, emblem `house_gambler`)
- Tagline: Safer rerolls (Gambles) that make your groups stronger.
- Rule: A clean Gamble (2+ dice, none Cracked): every SET this turn +0.55 (max +0.60). Gamble Crack chance 10% (normally 30%).
- Awakens: **Second Wind**: Once per turn, when a Gamble Cracks, the Cracked dice are rerolled at once for free. (when you hold 2 of the 5 House Cores)
- House Cores: Elder Trunk (`c_elder_trunk`), Thorn Shield (`c_thorn_shield`), Hollow Core (`c_hollow_core`), Mana Ward (`c_mana_ward`), Thorn Pact (`c_thorn_pact`)
- House mutation: **Crack Mana**: tier 1: First time each turn a die Cracks from a Gamble: +1 mana. Tier 2: First two times each turn a die Cracks from a Gamble: +1 mana each.

### Mana Mine (`a_mana_mine`, house `h_mana_mine`, emblem `house_mana_mine`)
- Tagline: Make a group on your first roll and get extra Mana.
- Rule: When the first roll of a turn makes a SET: +2 mana. Overcast costs only 1.
- Awakens: **Double Beat**: Overcast can be used twice per turn (the second costs 2 mana). (when you hold 2 of the 5 House Cores)
- House Cores: Mana Pool (`c_mana_pool`), Deep Current (`c_deep_current`), Rising Wave (`c_tidecaller`), Overflow (`c_overflow`), Dewdrop (`c_dewdrop`)
- House mutation: **Mana Overflow**: tier 1: At end of turn with 3+ mana left: spend 1 mana, all enemies take 2 damage (once per turn, after Mana Pool and Mana Ward). Tier 2: 4 damage.

### Kin (`a_kin`, house `h_kin`, emblem `house_kin`)
- Tagline: Groups of the same class hit harder, mixed groups hit weaker.
- Rule: A SET with 3+ dice of the same class gets +0.30.
- Cost: A SET without 3+ dice of the same class gets -0.25.
- Awakens: **Unison**: First turn of each fight, Axies of the same class roll the same part (up to a SET of four). (when you hold 2 of the 5 House Cores)
- House Cores: Nest (`c_nest`), Golden Egg (`c_golden_egg`), Bloodline Ward (`c_bloodline_ward`), Early Scales (`c_early_scales`), Last Testament (`c_last_testament`)
- House mutation: **Cover**: tier 1: First turn with a SET each turn, the front-row Axie with least HP (Egg included) gets Shield = 2 x SET dice (not multiplied by the SET). Tier 2: 3 x SET dice.

### Embers (`a_embers`, house `h_embers`, emblem `house_embers`)
- Tagline: Keep 2 dice for next turn and they hit much harder.
- Rule: You may Hold 2 dice; a Held die used next turn gets +2.25 (a die's M never goes above 3.00).
- Cost: Only Held dice carry over.
- Awakens: **Passed Flame**: Once per turn a carried Held die joins any SET as a Temp Face, free of mana (up to a SET of four). (when you hold 2 of the 5 House Cores)
- House Cores: Kindle (`c_kindle`), Smoldering Coals (`c_smoldering`), Cache Plate (`c_cache_plate`), Three Dice (`c_three_dice`), Overflow (`c_overflow`)
- House mutation: **Last Strike**: tier 1: The die you use last in the turn, if part of a SET, gives +0.30 multiplier (still under m_cap). Tier 2: +0.60.

### Big Hand (`a_big_hand`, house `h_big_hand`, emblem `house_big_hand`)
- Tagline: Groups of 4 or 5 dice hit harder, groups of 3 get nothing.
- Rule: A SET of four or five gets +0.90 (a die's M never goes above 3.00).
- Cost: A SET of three (the most common) gets no bonus.
- Awakens: **Sixth Hand**: Each turn with a SET of four or more, roll one bonus die to use this turn (it does not join the SET). (when you hold 2 of the 5 House Cores)
- House Cores: Hunter's Reward (`c_hunters_reward`), Golden Thread (`c_golden_thread`), Support Hand (`c_support_hand`), Sixth Die (`c_sixth_die`), Final Blow (`c_finisher`)
- House mutation: **Hunt Four**: tier 1: On a turn with exactly a SET of three, the first Safe reroll is free (once per turn, still counts toward the 3 rolls). Tier 2: The second Safe reroll costs only 1 mana.

## Cores (67)

| id | name | tier | family | tags | text |
|---|---|---|---|---|---|
| `c_meme_copycat` | Copycat | Moss | Dice | meme | Each turn you have a Set, your weakest die outside it copies the Set's part, but only for 1. |
| `c_finisher` | Final Blow | Moss | Dice | nonattack | The last die you use each turn gets +1 for every die used before it (max +4). |
| `c_hunters_reward` | Hunter's Reward | Moss | Dice | nonattack | First time each turn a paid reroll makes a Set appear or grow: that reroll's Mana is refunded and every Axie in the Set gains 3 Shield. |
| `c_meme_jumpy` | Jumpy Dice | Moss | Dice | meme | After the roll, two random dice jump and swap places. Sometimes it helps. |
| `c_prime_chain` | Prime Chain | Moss | Dice | nonattack, convert_to_dmg | Using a shield or mana face primes the neighbouring Axies: their next damage face this turn deals +3. |
| `c_cache_plate` | Cache Plate | Amber | Dice | nonattack | When you Hold a die showing a shield face, its Axie gains half that Shield now (rounded up, min 2, max 6, no M). Once per die per turn. The die keeps its full face for next turn. |
| `c_plague_spread` | Contagion | Amber | Dice | nonattack, convert_to_dmg | When a poisoned enemy dies, its remaining poison spreads to every living enemy. Poison faces give +2 stacks. |
| `c_cracked_glass` | Cracked Glass | Amber | Dice | nonattack, convert_to_dmg | A Cracked die that you use also sprays shards: pierce damage to all enemies equal to half its face value (rounded up), up to 3 times per turn. |
| `c_field_medic` | Field Medic | Amber | Dice | nonattack, tradeoff | Damage faces deal 2 less (min 1). Heal, shield, poison, mana and debuff faces get +3. |
| `c_fissure` | Fissure | Amber | Dice | nonattack, convert_to_dmg | Poison and debuff faces that hit make the enemy take +25% from all damage until the end of next turn and strip its Armor. |
| `c_kindle` | Kindle | Amber | Dice | nonattack | A Held die has Focus: used next turn it deals +4 (+8 if held two turns in a row). |
| `c_prism` | Prism | Amber | Dice | nonattack | End of turn: if you used 4 or more different face types, the whole team gains 3 Shield and +2 Mana. |
| `c_sonic_shield` | Shield Wave | Amber | Dice | nonattack, convert_to_dmg | Shield and heal faces also deal damage equal to half their value (rounded up) to the enemy targeting that Axie. |
| `c_steady_hold` | Steady Hold | Amber | Dice | nonattack | You can Hold 2 dice per turn, and the same die can be held two turns in a row. A Held die gets +1 for every turn it has been held (max +3), lost once it is used. |
| `c_support_hand` | Support Hand | Amber | Dice | nonattack | In a Set of three or more, each die showing a shield, heal or mana face gets +2 (counts toward the +10 flat cap). |
| `c_wicked_tally` | Wicked Tally (not offered now) | Amber | Dice | attack | Each time a finishing die kills an enemy it gets +1 for the run (max +6). |
| `c_concord` | Concord | Crystal | Dice | nonattack | Start of turn: Axies of the same class roll the same face. Each face used right after a face from the same part gets +2. |
| `c_magma_seed` | Magma Seed (not offered now) | Crystal | Dice | nonattack | A die Held two turns in a row erupts when used: its damage face hits ALL enemies for x1.25 (rounded up), no armor pierce. This Core lets a die be Held again. |
| `c_mirror_face` | Mirror Face | Crystal | Dice | nonattack | The first die you use each turn is not spent: use it a second time, with a new target. The second use gets no Prime, Finisher or Focus. |
| `c_sixth_die` | Sixth Die | Crystal | Dice | nonattack | Each turn, roll one extra die from a random living Axie. Use it this turn; it vanishes at end of turn. |
| `c_three_dice` | Three Dice | Crystal | Dice | nonattack, tradeoff | You can use at most 3 dice per turn. Dice you did not use are Held automatically and have Focus +3 next turn. |
| `c_toxic_still` | Toxic Still | Crystal | Dice | nonattack, tradeoff | Damage faces deal 2 less (min 1). End of turn: every poisoned enemy gains poison equal to half its stacks (rounded up, max +4). |
| `c_whittle` | Whittled Die | Crystal | Dice | nonattack, tradeoff | The team's weakest face slot is locked: a die that rolls it rerolls once. Every other face gets +1. |
| `c_mana_pool` | Mana Pool | Moss | Mana | nonattack | Mana faces give +1. End of turn: every 3 unspent Mana earns 1 more (max +3 per turn). |
| `c_tidecaller` | Rising Wave | Moss | Mana | nonattack, convert_to_dmg | Every 2 Mana you spend deals 2 damage to all enemies. |
| `c_smoldering` | Smoldering Coals | Moss | Mana | nonattack | End of turn: each Held die gives +1 Mana (max +2 per turn). |
| `c_golden_thread` | Golden Thread | Amber | Mana | nonattack | Wild Face costs 1 less Mana (min 1) and can be used 2 times per fight. A Set of four made with a Wild Face gets +0.20 M. |
| `c_mana_ward` | Mana Ward | Amber | Mana | nonattack | End of turn, spend up to 6 unused Mana: every 2 Mana gives each front-row Axie 3 Shield. |
| `c_overflow` | Overflow | Amber | Mana | nonattack, convert_to_dmg | Mana above 8 turns into pierce damage to all enemies and drops back to 8. |
| `c_thorn_pact` | Thorn Pact | Amber | Mana | nonattack, tradeoff | Rerolls cost no Mana but 2 HP of the Axie being rerolled (not allowed at 2 HP or less). Axies at half HP or lower get +2 on every face. |
| `c_deep_current` | Deep Current | Crystal | Mana | nonattack | Leftover Mana carries into the next combat (up to 12) instead of resetting. |
| `c_hollow_core` | Hollow Core | Crystal | Mana | nonattack | No free reroll. Every reroll costs 1 Mana, up to 8 per turn. Mana faces give +1. Each die you reroll gets +1 until end of turn (max +10). |
| `c_bastion` | Bastion | Moss | Position | nonattack, front | Front-row Axies take 2 less from single-target hits. |
| `c_bloodline_ward` | Bloodline Ward | Moss | Position | nonattack | When an Axie gains Shield from a shield face, each adjacent Axie of the same class gains half of it (rounded up). |
| `c_spearhead` | Spearhead (not offered now) | Moss | Position | attack, front | Front-row Axies: damage faces +2. |
| `c_backline_glow` | Backline Glow | Amber | Position | nonattack | Back-row Axies: buff, heal and mana faces get +50% (rounded up, at most +8). |
| `c_gatekeeper` | Gatekeeper | Amber | Position | nonattack, front | Enemies that hit a front-row Axie with a single-target attack take 3 pierce thorns. Each such hit gives your team's next damage face +2 (max +6, ends with the turn). |
| `c_growing_shell` | Growing Shell | Amber | Position | nonattack, front | Each enemy a front-row Axie kills gives it +1 Max HP for the run. If it falls, it loses two thirds of the stacks. |
| `c_melting_pot` | Melting Pot | Amber | Position | nonattack, tradeoff | If your team has 3 or more classes and no two Axies share a class, every Set gets +0.25 M. |
| `c_squad_up` | Squad Up (not offered now) | Amber | Position | attack | Axies next to an Axie of the same class: damage faces +2. |
| `c_thorn_growth` | Thorn Growth | Amber | Position | nonattack, front | Each time a front-row Axie is hit by a single-target attack, it gains +1 Thorns for the rest of the fight. |
| `c_living_wall` | Living Wall | Crystal | Position | nonattack, front | Only slot 1 is the front row. That Axie gets +12 Max HP and 2 Thorns. The other four are the back row. |
| `c_open_ranks` | Open Ranks | Crystal | Position | nonattack, front | No back row: all 5 Axies are front row, and every front-row Core applies to the whole team. |
| `c_descend` | Take The Field | Crystal | Position | nonattack, convert_to_dmg | Pick a back-row Axie with heal faces: it moves to the front for good, its heal and buff faces become damage faces +2, +8 Max HP, 30% lifesteal. |
| `c_chimera_hunt` | Chimera Hunt | Amber | Quest | attack | Quest in 3 steps: kill 8 enemies with a finishing die for +1 Core reroll; kill 20 for an Amber Core pick; kill a boss with a finishing die for a Crystal Core pick. |
| `c_collector` | Collector | Amber | Quest | nonattack | Quest: use 4 different face types in one turn, in 3 different fights. Until done: +1 Mana every turn. |
| `c_dry_well` | Dry Well | Amber | Quest | nonattack | Quest: spend 40 Mana in total. Until done: +2 Mana at the start of each fight. |
| `c_key_strike` | Key Strike | Amber | Quest | nonattack | Quest: use a Held die for 9 or more damage, 3 times. Until done: the same die can be held two turns in a row. |
| `c_night_watch` | Night Watch | Amber | Quest | nonattack | Quest: beat the next boss without losing an Axie. Until done: front-row Axies +3 Max HP. |
| `c_fossil` | Fossil | Moss | Rule | nonattack | Does nothing now and takes a slot. Your next Core pick is one tier higher (Crystal: 4 cards; already 4 cards: +1 Core reroll), then it disappears. Only shows at picks 1-2. |
| `c_meme_nametag` | Name Tag | Moss | Rule | meme | Start of combat: a random enemy gets a silly name. Kill it for +1 Mana. |
| `c_nest` | Nest | Moss | Rule | nonattack, egg | Start of combat: 1 Egg. Eggs count as front row, so single-target enemy attacks can pick them. |
| `c_spore_burst` | Spore Burst | Moss | Rule | nonattack, convert_to_dmg | When an Axie falls it bursts: every enemy loses 20% of its Max HP (boss 8%), ignoring Shield. Eggs burst for half. |
| `c_dim_stone` | Dim Stone | Amber | Rule | nonattack | Pick this: nothing now, but you get a random Crystal Core of another axis. Not at pick 2, not at the last pick. |
| `c_golden_egg` | Golden Egg | Amber | Rule | nonattack | When an Egg dies, or hatches (once per turn): +3 Mana, 4 Shield to your weakest Axie, and your team's next damage face gets +3. |
| `c_blood_sign` | Blood Sign | Crystal | Rule | nonattack, convert_to_dmg | Damage faces add 1 poison per 3 damage dealt (rounded down). Poison faces also deal damage equal to half their value. |
| `c_cascade` | Cascade | Crystal | Rule | attack | Damage faces used back to back form a chain: the 2nd gets +2, the 3rd +4, the 4th +6, the 5th+ +8. Using a non-damage face breaks the chain. |
| `c_high_roller` | High Roller | Crystal | Rule | nonattack, tradeoff | A Gamble of 3+ dice: if no die Cracks, every die in it gets +2 until end of turn. If one die Cracks, all of them Crack. |
| `c_last_testament` | Last Testament | Crystal | Rule | nonattack | When an Axie falls, every living Axie of its class gets +2 on every face until the end of the fight (max +6). Eggs do not count. |
| `c_loop` | Loop | Crystal | Rule | nonattack | Cantrip faces reroll and are used one extra time each turn. |
| `c_thorn_rebound` | Rebound | Crystal | Rule | nonattack, tradeoff | The Axie with the most Thorns reflects its Thorns a second time on every hit, but it cannot use damage faces. |
| `c_sacrifice` | Sacrifice | Crystal | Rule | nonattack, tradeoff | Start of combat: the Axie in slot 5 sleeps (no die, cannot be targeted). The other four get +2 on every face and 1 extra free reroll each turn. |
| `c_verdict` | Verdict (not offered now) | Crystal | Rule | attack | Enemies under 20% HP die at once (not bosses). Finishing faces always Execute. |
| `c_dewdrop` | Dewdrop | Moss | Stat | nonattack | +1 Mana at the start of every turn. |
| `c_early_scales` | Early Scales | Moss | Stat | nonattack | Start of combat: front-row Axies gain 5 Shield. |
| `c_elder_trunk` | Elder Trunk | Moss | Stat | nonattack, tradeoff | Every Axie gets +8 Max HP, but every damage face deals 1 less (min 1). |
| `c_thorn_shield` | Thorn Shield | Amber | Stat | nonattack | End of your turn, every 2 leftover Shield on an Axie turns into 1 Thorns (that Shield is lost). |

## Run Rules (17, plus `rule_none` = no rule)

One Run Rule is offered before the first Core pick and stays all run. It has its own slot.

- `rule_balance` **Balance**: From the 3rd damage face each turn, damage faces deal 2 less (min 1). Every non-damage face you use gives +1 Mana. You cannot stack five attacks.
- `rule_cheap_mana` **Cheap Mana**: Every reroll costs 1 Mana, there is no free reroll, and you get at most 5 rerolls a turn. Teams without Mana get stuck.
- `rule_crow` **Crow Herald**: The fight before each Core pick (from pick 2): win within 5 turns (boss 7) with nobody down and the pick is one tier higher; if an Axie falls, one tier lower.
- `rule_dry_steppe` **Dry Steppe**: Mana does not carry over: leftover Mana is lost at end of turn. +2 Mana at the start of every turn.
- `rule_hard_shell` **Hard Shell**: Every enemy has Armor 2: single-target damage faces deal 2 less (min 1). Poison, pierce, thorns and AoE are not reduced. Shield, poison and debuff faces get +2.
- `rule_heavy_finish` **Heavy Finish**: The last die you use each turn gets +3, but enemies deal 10% more damage.
- `rule_high_stakes` **High Stakes**: Every paid reroll is a Gamble (Crack 20% per die, no Mana cost). A clean Gamble gives each rerolled Axie 3 Shield, and the first clean Gamble each turn gives +1 Mana. Free rerolls stay Safe.
- `rule_old_forest` **Old Forest**: Every Axie and enemy has +30% HP. Heal and poison faces are 50% stronger. Fights run long, so spamming damage runs out of steam.
- `rule_pack_alpha` **Pack Alpha**: In normal and elite fights the enemy with the most HP is the Pack Alpha (+25% HP). While it lives, other enemies take 50% less from single-target damage faces (min 1; AoE, poison, thorns and pierce are not reduced). When it falls, every other enemy loses 20% of its current HP. Not in boss fights.
- `rule_pilot_light` **Pilot Light**: Turn 1 of each fight your damage faces deal 0, but you can Hold up to 4 dice, and each die Held on turn 1 gets +3 when used on turn 2. Normal and elite enemies have +10% HP. Not in boss fights.
- `rule_quick_beat` **Quick Beat**: Boss rhythm is only 2 turns (Strike, Hollow, Strike...), and Strike turns hit 20% harder.
- `rule_rising_tide` **Rising Tide**: Each fight one row is in the water: the front row takes 25% less damage, or the back row's damage faces get +2. They alternate fight by fight.
- `rule_set_is_king` **Set Is King**: A die inside a SET (3+) gets +2 on its face; a die in no SET gets -2 (min 1). No free reroll.
- `rule_starfall` **Genesis Starfall**: Your first Core pick is a Crystal Core. Normal and elite enemies have +15% HP all run.
- `rule_tundra` **Tundra**: No free reroll (rerolls cost 2 Mana). You can Hold 2 dice, and a Held die gets +2 when used next turn.
- `rule_upside_down` **Upside Down**: Single-target enemy attacks pick the back row first. The front row only takes AoE.
- `rule_wasteland` **Mystic Wasteland**: Only 3 Core picks (no pick after the elite), but each shows 4 cards. Every Axie +4 Max HP.

## Core combos (PAIR / FULL / jackpot)

Holding the PAIR Cores (and then the FULL one) of a combo shows PAIR/FULL tags on offer cards and a combo banner after Take.

- **Lunacia Rain** (jackpot): Cascade + Sixth Die + Thorn Shield
- **Golden Turtle Fortress**: PAIR Living Wall + Thorn Shield; FULL + Gatekeeper
- **Toxic Bloom Guard**: PAIR Shield Wave + Backline Glow; FULL + Blood Sign
- **Golden Egg Blast**: PAIR Nest + Golden Egg; FULL + Spore Burst
- **Rising Tide**: PAIR Rising Wave + Overflow; FULL + Backline Glow
- **Lakebed Fishing Rod**: PAIR Hollow Core + Mana Ward; FULL + Kindle
- **Shield Engine**: PAIR Shield Wave + Thorn Shield; FULL + Prime Chain
- **Finishing Stroke**: PAIR Final Blow + Chimera Hunt; FULL + Prime Chain
- **Ancient Turtle**: PAIR Living Wall + Early Scales; FULL + Growing Shell
- **Molting**: PAIR Take The Field + Thorn Shield; FULL + Bastion
- **Bramble Hide**: PAIR Elder Trunk + Thorn Shield; FULL + Thorn Pact
- **Dice Rainbow**: PAIR Collector + Sixth Die; FULL + Prism
- **Slow Burn**: PAIR Overflow + Three Dice; FULL + Dewdrop
- **Endless Mana Loop**: PAIR Mana Pool + Deep Current; FULL + Loop
- **Chorus Wall**: PAIR Bloodline Ward + Thorn Shield; FULL + Early Scales
- **Funeral Pyre**: PAIR Last Testament + Spore Burst; FULL + Thorn Pact
- **Banked Fire**: PAIR Cache Plate + Smoldering Coals; FULL + Kindle
- **Sewn Hand**: PAIR Golden Thread + Hunter's Reward; FULL + Sixth Die
- **Hand of Aid**: PAIR Support Hand + Backline Glow; FULL + Shield Wave
- **Glass Bet**: PAIR Cracked Glass + Hollow Core; FULL + Mana Ward
- **High Roller Table**: PAIR High Roller + Hunter's Reward
- **Hot Pot**: PAIR Melting Pot + Prism; FULL + Collector

## Firing in combat

Each real firing sends one event: `core_fired(core_id, unit, amount, kind)`. It names the Axie or enemy it touched and the number. It does not name a die.
