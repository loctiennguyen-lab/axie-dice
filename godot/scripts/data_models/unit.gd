class_name Unit
extends RefCounted
## Mutable runtime combat unit — party member, enemy, or in-combat token/ally.
## Deliberately NOT a Resource: Resources are cached-by-path static data
## (architecture plan §6 "Luật cứng cho MỌI data model dạng Resource" — mutating one
## would leak state into the next run/combat). See design/gdd/godot-port-rule-spec.md
## §3-§4 for the field semantics ported here from engine.js buildUnit()/mkMonster()/mkBoss().
##
## `to_data()`/`from_data()` must round-trip losslessly — CombatEngine's own round-trip
## test (tests/t_combat_roundtrip.gd) embeds every Unit via these.

var uid: int = 0
var side: String = "p"          # "p" (player/token) or "e" (enemy)
var key: String = ""            # hero key ("plant1") or monster key ("slime")
var n: String = ""              # display name
var cls: String = ""            # plant/beast/aqua/reptile/bug/bird — "" for non-hero enemies
var role: String = ""           # enemy AI role (bruiser/assassin/tank/healer/poisoner/mage/
                                 # summoner/kamikaze/buffer/boss/token) — "" for player units
var tier: int = 1
var is_boss: bool = false
var is_token: bool = false      # rule spec §4 — tokens never count toward realP() win/loss check

var hp: int = 0
var max_hp: int = 0
var shield: int = 0

## poison/burn/regen/blind/weaken/vulnerable/thorns/stun/undying -> int stack count.
## freeze is intentionally NOT here — engine.js models it as the frozen/frozen_next
## flags below, not a decaying stack (rule spec §3 "freeze" bullet + addStatus()).
var status: Dictionary = {}

var frozen: bool = false        # can't reroll this turn (player) — JS u.frozen
var frozen_next: bool = false   # will become `frozen` at the next roll — JS u.frozenNext
var overdrive: bool = false     # transient per-turn boss buff (mecha trait) — JS u.overdrive
var resonant_now: bool = false  # transient: current face benefits from Formation Resonance
var heavy: bool = false         # current rolled face has the `heavy` keyword — recomputed
                                 # every roll, blocks reroll (JS u.heavy)

## 6 faces, each {part: String, type: String, value: int, keywords: Array[String], rarity: int}.
## `rarity` (0..4, COMMON..MYTHIC) is carried through even though the minimum spec only asked
## for {type,value,part,keywords} — it's free to keep (straight copy from HEROES data) and is
## needed later for "Golden/Cosmic Die" visual tier (rule spec §11); dropping it would mean
## re-adding it as a schema change once that UI ships.
var die: Array = []

## face_index (int) -> permanent growth bonus for that face, accumulated in-combat via the
## `growth` keyword (engine.js doFace ENG-2), the `grow` active card, the growthAll relics and
## r_quickenroot. This comment used to claim String keys "so to_data() is directly JSON-safe";
## that was true of the accessors and of nothing else, and the mismatch made most growth inert.
## JSON turns every key into a string on the way out, so from_data() coerces them back — see
## get_growth() below.
var growth: Dictionary = {}

## Current roll state. Empty array = "not rolled yet this turn" (JS u.rolled=-1).
## Exactly one entry when rolled: {face_index: int, crit_now: bool, used: bool}.
## Modeled as an Array (per spec) rather than a bare Dictionary so a future mechanic
## granting a unit more than one active roll doesn't require a schema change — today
## every unit still only ever has 0 or 1 entries, matching engine.js's single u.rolled/
## u.critNow/u.used scalars exactly.
var rolled: Array = []

var roster_index: int = -1      # index into RunState.roster — Formation Resonance key
                                 # (rule spec §4: position in s.roster, NEVER combat-board
                                 # position). -1 for tokens/enemies (never resonate).

## Open bucket for boss-specific counters (turn_count, split_done, phase, trait, adds,
## add_cap, permanent_thorns, die2/max_hp2 for phase-2 dice, summons key, sc scale factor)
## so adding a new boss later never requires touching this schema (architecture plan §8).
var custom_state: Dictionary = {}

## Enemy-only: chosen intent for this turn, {face_index: int, target_uid: int}. Empty
## when not rolled / dead. target_uid of -1 means "no valid target" (JS e.intent.tgt=null).
var intent: Dictionary = {}

var _dead: bool = false         # onEnemyDeath() dedup guard — JS e._dead


# ---------------------------------------------------------------------------
# Roll-state helpers (keep the Array-of-0-or-1 schema from leaking into call sites)
# ---------------------------------------------------------------------------

func has_rolled() -> bool:
	return not rolled.is_empty()

func roll_face_index() -> int:
	return int(rolled[0]["face_index"]) if has_rolled() else -1

func roll_crit_now() -> bool:
	return bool(rolled[0]["crit_now"]) if has_rolled() else false

func roll_used() -> bool:
	return bool(rolled[0]["used"]) if has_rolled() else true

func set_roll(face_index: int, crit_now: bool) -> void:
	rolled = [{"face_index": face_index, "crit_now": crit_now, "used": false}]

func clear_roll() -> void:
	rolled = []

func set_crit_now(v: bool) -> void:
	if has_rolled():
		rolled[0]["crit_now"] = v

func mark_used() -> void:
	if has_rolled():
		rolled[0]["used"] = true

func current_face() -> Dictionary:
	var fi := roll_face_index()
	if fi < 0 or fi >= die.size():
		return {}
	return die[fi]

## `growth` is keyed by INTEGER face index. That was not true until 2026-09-19: these two
## accessors used `str(face_index)` while every other writer in the codebase used the plain
## integer, so the two halves never met. `get_growth()` read a string key and found nothing
## written by the `grow` active card (combat_engine.gd), the `growthAll` relics, r_quickenroot
## or the between-combat carry-over in RunState._apply_growth_keep() — five pieces of content
## quietly producing growth that was never applied to a single face.
##
## Integer was chosen over string because every writer but these two already used it, and
## because the JSON save layer already coerces the keys back (RunState._int_keyed(),
## Unit.from_data()). Do not "simplify" either end back to a string key without changing all
## six call sites together.
func get_growth(face_index: int) -> int:
	return int(growth.get(face_index, 0))

func add_growth(face_index: int, amount: int) -> void:
	growth[face_index] = get_growth(face_index) + amount

func is_alive() -> bool:
	return hp > 0


# ---------------------------------------------------------------------------
# Serialization — JSON-safe Dictionary round trip (no Resource, no Callable, no Object refs)
# ---------------------------------------------------------------------------

func to_data() -> Dictionary:
	return {
		"uid": uid, "side": side, "key": key, "n": n, "cls": cls, "role": role, "tier": tier,
		"is_boss": is_boss, "is_token": is_token,
		"hp": hp, "max_hp": max_hp, "shield": shield,
		"status": status.duplicate(true),
		"frozen": frozen, "frozen_next": frozen_next, "overdrive": overdrive,
		"resonant_now": resonant_now, "heavy": heavy,
		"die": die.duplicate(true),
		"growth": growth.duplicate(true),
		"rolled": rolled.duplicate(true),
		"roster_index": roster_index,
		"custom_state": custom_state.duplicate(true),
		"intent": intent.duplicate(true),
		"_dead": _dead,
	}

static func from_data(d: Dictionary) -> Unit:
	var u := Unit.new()
	u.uid = int(d.get("uid", 0))
	u.side = String(d.get("side", "p"))
	u.key = String(d.get("key", ""))
	u.n = String(d.get("n", ""))
	u.cls = String(d.get("cls", ""))
	u.role = String(d.get("role", ""))
	u.tier = int(d.get("tier", 1))
	u.is_boss = bool(d.get("is_boss", false))
	u.is_token = bool(d.get("is_token", false))
	u.hp = int(d.get("hp", 0))
	u.max_hp = int(d.get("max_hp", 0))
	u.shield = int(d.get("shield", 0))
	u.status = (d.get("status", {}) as Dictionary).duplicate(true)
	u.frozen = bool(d.get("frozen", false))
	u.frozen_next = bool(d.get("frozen_next", false))
	u.overdrive = bool(d.get("overdrive", false))
	u.resonant_now = bool(d.get("resonant_now", false))
	u.heavy = bool(d.get("heavy", false))
	u.die = (d.get("die", []) as Array).duplicate(true)
	# Keys are face INDEXES (ints). An in-memory round-trip preserves that; a trip through JSON
	# does not — every key comes back as a string, `growth.get(3)` misses the value stored under
	# "3", and the unit silently loses every point of growth it had earned. Coerced here rather
	# than at the save layer so any future source of this data (a network payload, a fixture
	# file) gets the same guarantee.
	u.growth = {}
	for k in (d.get("growth", {}) as Dictionary):
		u.growth[int(k)] = int((d["growth"] as Dictionary)[k])
	u.rolled = (d.get("rolled", []) as Array).duplicate(true)
	u.roster_index = int(d.get("roster_index", -1))
	u.custom_state = (d.get("custom_state", {}) as Dictionary).duplicate(true)
	u.intent = (d.get("intent", {}) as Dictionary).duplicate(true)
	u._dead = bool(d.get("_dead", false))
	return u
