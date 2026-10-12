class_name HudStateStub
extends RefCounted
## STUB of `CombatEngine.hud_state()` (production/l1-interfaces.md §3.2) until lane A delivers.
##
## Shape is the contract:
##   { turn, rerolls, max_rerolls, mana, tweak_left,
##     clock:     {active, start_turn, turns_left, stacks, pct},       # boss enrage clock
##     attrition: {active, start_turn, stacks, pct},
##     enemy_next:{uid -> {dmg, spike, turns_to_spike}},               # ONE merged number
##     boss_phase:{uid -> {phase, thresholds}},
##     newcomer }
##
## The engine has no attrition / clock / spike yet, so the stub reports the truth: both inactive
## (`active=false`), enemy dmg = the live face value, no spike. CombatView calls
## `CombatView._hud_state()`, which prefers the real `hud_state()` the moment it exists.
##
## `override` lets QA captures and tests force any state (a Dictionary merged over the result,
## per key), so every R1 frame can be screenshotted before lane A lands:
##   HudStateStub.override = {"attrition": {...}, "clock_for_boss": {...}, "spike": {...}}

## Merged (shallow, per top-level key) over the computed dictionary. Cleared by tests.
static var override: Dictionary = {}

const ATTR_START := 6
const ATTR_STEP := 5
const ATTR_CAP := 25


## Pure helper the UI and the tests share: attrition for a turn per README 3a
## (0 before turn 6, +5% per turn from turn 6, +25% MAX from turn 10).
static func attrition_for_turn(turn: int, newcomer: bool = false) -> Dictionary:
	if newcomer:
		return {"active": false, "start_turn": ATTR_START, "stacks": 0, "pct": 0}
	var stacks := maxi(0, turn - ATTR_START + 1)
	var pct := mini(stacks * ATTR_STEP, ATTR_CAP)
	return {"active": pct > 0, "start_turn": ATTR_START, "stacks": stacks, "pct": pct}


## Intent number per README 3a: base x (1 + enrage% + attrition%) x spike_mult, round half up.
static func merged_intent(base: int, enrage_pct: int, attrition_pct: int, spike_mult: float = 1.0) -> int:
	return int(floor(float(base) * (1.0 + (enrage_pct + attrition_pct) / 100.0) * spike_mult + 0.5))


static func from_engine(c: CombatEngine) -> Dictionary:
	var st := {
		"turn": c.turn, "rerolls": c.rerolls, "max_rerolls": c.max_rerolls,
		"mana": c.mana, "tweak_left": 0,
		"clock": {"active": false, "start_turn": 10, "turns_left": 0, "stacks": 0, "pct": 0},
		"attrition": {"active": false, "start_turn": ATTR_START, "stacks": 0, "pct": 0},
		"enemy_next": {}, "boss_phase": {}, "newcomer": false,
	}
	for e in c.enemies:
		if e.hp <= 0:
			continue
		var fi := int(e.intent.get("face_index", -1))
		if fi >= 0 and fi < e.die.size():
			st["enemy_next"][e.uid] = {"dmg": int(c._face_value(e, fi)), "spike": false,
				"turns_to_spike": 0}
		if e.is_boss:
			st["boss_phase"][e.uid] = {"phase": int(e.custom_state.get("phase", 1)),
				"thresholds": [66, 33]}
	for k in override:
		st[k] = override[k]
	return st
