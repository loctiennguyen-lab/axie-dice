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
