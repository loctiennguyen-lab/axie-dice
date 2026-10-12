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
