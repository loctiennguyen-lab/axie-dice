class_name Anchors
extends RefCounted
## Anchor (Lõi chủ) + house data API. Design: design/proposals/mutation-and-keystones-v1.md (2.1, 2.2, "Liam chốt 23/10").
## Pure + static; no rng except the one passed in. Data: assets/data/rules/anchors.json, houses.json. Effects NOT coded here.
## `owned` = an owned-id Array that already includes finished quest Cores (RunState.combo_owned_ids()).

const ANCHORS_PATH := "res://assets/data/rules/anchors.json"
const HOUSES_PATH := "res://assets/data/rules/houses.json"
const AWAKEN_NEED := 2  ## any 2 house Cores awaken the Anchor (Liam 23/10)

static var _anchors: Array = []
static var _houses: Array = []
static var _loaded := false


static func _read(path: String) -> Array:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return []
	var data = JSON.parse_string(f.get_as_text())
	return data if data is Array else []


static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	_anchors = _read(ANCHORS_PATH)
	_houses = _read(HOUSES_PATH)


## Test hook: drop the cache.
static func reload() -> void:
	_loaded = false
	_anchors = []
	_houses = []


## All 6 Anchor rows.
static func all() -> Array:
	_load()
	return _anchors


## Anchors with enabled=true (MVP: Volley, Gambler, Mana Mine).
static func enabled() -> Array:
	var out: Array = []
	for a in all():
		if bool(a.get("enabled", false)):
			out.append(a)
	return out


static func get_def(anchor_id: String) -> Dictionary:
	for a in all():
		if String(a["id"]) == anchor_id:
			return a
	return {}


static func houses() -> Array:
	_load()
	return _houses


static func get_house(house_id: String) -> Dictionary:
	for h in houses():
		if String(h["id"]) == house_id:
			return h
	return {}


## 3 distinct ids drawn from `enabled_ids` (sorted first so the result depends only on the set + rng state).
## Fewer than 3 candidates: returns them all (sorted).
static func offer_three(rng: Rng, enabled_ids: Array) -> Array:
	var pool: Array = []
	for id in enabled_ids:
		if not pool.has(String(id)):
			pool.append(String(id))
	pool.sort()
	if pool.size() <= 3:
		return pool
	var out: Array = []
	for i in 3:
		var j := rng.next_int(pool.size())
		out.append(pool[j])
		pool.remove_at(j)
	return out


## How many of the Anchor's 5 house Cores are owned.
static func house_count(owned: Array, anchor_id: String) -> int:
	var n := 0
	for id in get_def(anchor_id).get("house_cores", []):
		if owned.has(id):
			n += 1
	return n


## Awakened = at least 2 house Cores owned (any 2).
static func is_awakened(owned: Array, anchor_id: String) -> bool:
	return house_count(owned, anchor_id) >= AWAKEN_NEED


## House id that owns `combo_id`, or "".
static func house_of_combo(combo_id: String) -> String:
	for h in houses():
		if (h["combo_ids"] as Array).has(combo_id):
			return String(h["id"])
	return ""


## Mutation tier of a house: 0 none, 1 = a Pair of one of its combos, 2 = a Full combo or Pairs of 2 combos.
## `combo_state` = CoreCombos.state(owned) (combo id -> "pair"|"full"; hidden combos are already absent).
## A jackpot only ever reads "full", so it lands on tier 2 directly.
static func mutation_tier(_owned: Array, house_id: String, combo_state: Dictionary) -> int:
	var pairs := 0
	for cid in get_house(house_id).get("combo_ids", []):
		var t := String(combo_state.get(cid, ""))
		if t == "full":
			return 2
		if t == "pair":
			pairs += 1
	return 2 if pairs >= 2 else pairs
