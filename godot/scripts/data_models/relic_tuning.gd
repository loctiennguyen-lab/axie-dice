class_name RelicTuning
extends Resource
## Tuning numbers for the relic slot model (relic-set-v2 §3.1, interfaces §2.4). One instance:
## resources/relics/relic_tuning.tres. Designers change numbers there, not in relic_slots.gd.

@export var passive_slots: int = 8
@export var passive_slots_cramped: int = 7     ## from `cramped_from_ascension`
@export var cramped_from_ascension: int = 8    ## A8 Cramped Pack
@export var active_slots: int = 3
@export var active_slots_extra: int = 1        ## added while hollowchalice is owned
@export var g_slots: int = 1                   ## global multiplier slot
@export var a_slots: int = 2                   ## archetype multiplier slots
@export var sell_pct: int = 50                 ## % of the rarity buy price
@export var sell_pct_ascended: int = 40        ## % from `sell_pct_from_ascension`
@export var sell_pct_from_ascension: int = 1
@export var chalice_id: String = "r_hollowchalice"
@export var g_cap: float = 2.5                 ## G_axie ceiling (relic-set-v2 §3.3)
@export var oc_nondmg_cap: float = 2.0         ## cumulative ascend/forge multiplier ceiling on Shield/Heal/Mana faces
@export var relic_reroll_cap: int = 4          ## Reroll gained from relics per turn (§3.6, F-22)
@export var chaos_reroll_cap: int = 6          ## a_chaos: Reroll gained from actives per turn

## --- Offer system (relic-set-v2 §4, design/l1-relic-answers.md §8). Weights are integers. ---
## source -> [Common, Rare, Epic, Legendary]; a rarity with no valid relic is dropped and the rest renormalised.
@export var rarity_weights: Dictionary = {
	"battle": [65, 35, 0, 0], "battle_late": [50, 38, 12, 0], "milestone": [0, 70, 30, 0],
	"elite": [0, 45, 40, 15], "boss": [0, 0, 70, 30], "shop": [35, 40, 22, 3],
	"treasure": [0, 50, 40, 10], "chest": [0, 55, 45, 0], "bet_small": [0, 0, 70, 30],
	"gamble_legend": [0, 0, 0, 100],
}
@export var m_neutral: int = 4
@export var m_lean: int = 12
@export var m_payoff_mult: int = 2
@export var m_floor: int = 1
@export var payoff_layers: PackedStringArray = PackedStringArray(["payoff", "engine", "scaling"])
@export var tag_order: PackedStringArray = PackedStringArray(
	["exec", "shield", "pierce", "mana", "thorns", "summon", "growth", "poison", "crit", "aoe", "burn"])
@export var twinfates_id: String = "r_twinfates"
@export var twinfates_exclusive: PackedStringArray = PackedStringArray(
	["r_tidalbrand", "r_infinitedie", "r_tidecaller", "r_devilsreroll", "r_cullingorder",
	"r_apexpredator", "r_alphafang", "a_chaos"])
@export var chalice_dead_draws: PackedStringArray = PackedStringArray(["r_ear", "r_tidecaller"])
@export var fortune_id: String = "r_fortuneledger"
@export var fortune_blocked_from_ascension: int = 10
@export var pact_groups: PackedStringArray = PackedStringArray(["reroll", "dice", "mana"])
@export var tweak_budget_per_turn: int = 2   ## Tweaks per turn shared by every dice relic (amberdie's hold is separate)
@export var flip_offset: int = 3             ## flipside: face i becomes (i + offset) mod 6
@export var pact_offer_size: int = 3
@export var pact_weight: int = 4


## --- Depth v3 Core (lane B). All offer numbers live here, not in code. ---
@export var core_slots: int = 6
@export var rule_slots: int = 1
@export var core_t_cap_short: int = 3          ## max owned Crystal (tier 2) Cores, Short
@export var core_t_cap_full: int = 4
@export var core_reroll_max: int = 2           ## Core rerolls per run (one card each)
@export var combo_reroll_cap: int = 2          ## gacha: max +1 Core reroll per run from first-time combo Pairs (knob core.combo_reroll_cap)
@export var core_cards: int = 3
@export var core_shop_cost: int = 60           ## shards for a Moss Core pick in the shop (economy-designer to price)
@export var core_cards_first_extra: int = 4    ## pick 1 with perk relic0/relic1
@export var rule_cards: int = 2
@export var rule_none_pct: int = 10            ## from run 2: chance one of the two rule cards is "no rule"
@export var core_picks_short: int = 4
@export var core_picks_full: int = 6
## Extra Core picks (Short only, 6-pick run): [[elite_tier, mid_tier], weight]. Drawn once at new_run from its own Rng, so the 4 milestone
## tiers (tier_chains_short) never change. The elite pick opens after the first won Elite that is not already a milestone node;
## the mid pick opens after the `core_extra_pick_nodes`-th finished node. Both open as bonus offers (do not shift milestone indexes).
@export var core_extra_tiers_short: Array = [[[1, 0], 45], [[2, 0], 20], [[1, 1], 35]]
@export var core_extra_pick_nodes: int = 3     ## knob core.extra_pick_nodes (0 = no mid pick)
@export var core_extra_elite_max: int = 1      ## knob core.extra_elite_max (Elite wins that give an extra pick; 0 = none)
## Tier chains for picks 1..4 (Short), weight each. 0 moss, 1 amber, 2 crystal.
@export var tier_chains_short: Array = [
	[[0, 1, 2, 1], 30], [[0, 1, 1, 2], 20], [[0, 0, 2, 1], 15], [[0, 1, 2, 2], 10],
	[[0, 0, 2, 2], 10], [[0, 0, 1, 2], 10], [[0, 1, 1, 1], 5]]
## Full adds two final picks drawn from these [[t5,t6], weight].
@export var tier_tail_full: Array = [[[1, 2], 40], [[2, 2], 25], [[1, 1], 35]]
@export var core_stat_max_per_offer: int = 1
## R1 (core-visibility-fix): an axis is drawn with weight min(valid Cores in its cell, this).
@export var axis_weight_cap: int = 4
## Anchor (lane AE 2a): relative weight of the Anchor's house Cores when a Core offer picks inside an axis cell.
## Reroll (reroll_card) never applies it (anchor-mvp QA #13). 1.0 = no bias.
@export var anchor_house_bias: float = 5.0
## Anchor: relative weight of an axis that holds one of the Anchor's house Cores, when a Core offer draws axes (anchor.axis_bias). Not used by reroll.
@export var anchor_axis_bias: float = 3.0
## Anchor: extra weight of a Core that is a 2nd member of a combo the player already holds 1 member of (only with an Anchor; reroll never; 1.0 = off).
@export var anchor_partner_bias: float = 3.0
@export var core_quest_max_per_offer: int = 1
## Where Core pick 2.. opens: ["row", n] = after the node on map row n, ["boss", k] = after the k-th boss.
@export var core_triggers_short: Array = [["row", 5], ["boss", 1], ["boss", 2]]
@export var core_triggers_full: Array = [["row", 5], ["boss", 1], ["boss", 2], ["row", 18], ["boss", 3]]
