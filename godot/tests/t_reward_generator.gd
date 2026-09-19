extends Node
## Headless gate for RewardGenerator (checklist step 4, reward-system pass —
## design/gdd/godot-port-rule-spec.md §9). Implemented as a scene
## (t_reward_generator.tscn) run via `godot --headless --path godot
## tests/t_reward_generator.tscn`, NOT a bare `--script` SceneTree override — same reasoning
## as tests/t_map_invariants.gd's doc comment: on a cold .godot/ cache, `--script` mode does
## not reliably resolve OTHER class_name scripts (RewardGenerator, RelicDef, Rng) as known
## global identifiers, while a normal scene's _ready() goes through the standard bootstrap.
##
## Covers:
##  1. generate() always returns exactly `count` rewards across many seeds/tiers/pw.
##  2. every reward's `t` is one of the 4 implemented types (relic/hp/reroll/shard).
##  3. "reroll" never appears twice in the same offer.
##  4. "reroll" never appears at all once max_rerolls_now >= 4.
##  5. "relic" rewards never repeat an id already owned or already offered in the same batch.
##  6. determinism: same seed + same inputs -> byte-identical output.
##  7. generate_shop_items(): 2 distinct relics + heal + reroll, costs match the real
##     src/data.js RELIC_SHOP_COST/40/110 tables, no duplicate relic ids.
##  8. pick_relic() respects the exclude list and the rarity band.

const SEED_COUNT := 2000
## Every reward type RewardGenerator is allowed to emit. This list is a GATE, not a mirror:
## widening it is a deliberate act that should accompany a real port, which is why the Phase-1
## reward pass showed up here as four loud failures rather than passing silently.
##
## src/engine.js genRewards()'s pool (engine.js:1054-1068) has nine types. Ported so far:
##   level  — hero tier-up (pushed TWICE in JS, the highest-weight reward)
##   ascend — the fallback growth path for units that can no longer tier up
##   relic · hp · reroll · chaos · curse
## Still unported, both blocked on a FACE_POOL/RUNES table that does not exist in ContentDB:
##   face   — gene mutation
##   rune   — imbue a keyword onto a face
## `shard` is NOT a JS reward type — it is an invention of this port; see reward_generator.gd.
const VALID_TYPES := ["relic", "hp", "reroll", "shard", "level", "ascend", "chaos", "curse"]

var _synthetic_roster: Array = [
	{"persistent_id": 1, "hero_key": "plant1", "tier": 1, "max_hp": 17, "muts": [], "growth": {}, "bonus_hp": 0},
	{"persistent_id": 2, "hero_key": "beast1", "tier": 1, "max_hp": 12, "muts": [], "growth": {}, "bonus_hp": 0},
	{"persistent_id": 3, "hero_key": "aqua1", "tier": 1, "max_hp": 13, "muts": [], "growth": {}, "bonus_hp": 0},
	{"persistent_id": 4, "hero_key": "reptile1", "tier": 1, "max_hp": 16, "muts": [], "growth": {}, "bonus_hp": 0},
	{"persistent_id": 5, "hero_key": "bug1", "tier": 1, "max_hp": 14, "muts": [], "growth": {}, "bonus_hp": 0},
]

var _fail_count := 0
var _first_failure := ""


func _ready() -> void:
	_check_shape_and_types()
	_check_reroll_rules()
	_check_relic_dedup()
	_check_determinism()
	_check_shop_items()
	_check_pick_relic_bounds()

	if _fail_count == 0:
		print("t_reward_generator: PASS — all checks green across %d seeds" % SEED_COUNT)
		get_tree().quit(0)
	else:
		print("t_reward_generator: FAIL (%d failing checks) — first: %s" % [_fail_count, _first_failure])
		get_tree().quit(1)


func _fail(msg: String) -> void:
	_fail_count += 1
	if _first_failure == "":
		_first_failure = msg
	push_error("t_reward_generator: %s" % msg)


func _check_shape_and_types() -> void:
	for i in SEED_COUNT:
		var seed_value := i * 104729 + 7
		var tier := i % 4
		var pw := i % 20
		var max_rerolls_now := 2 + (i % 4)   # cycles 2,3,4,5 -> exercises the reroll gate
		var rng := Rng.new(seed_value)
		var out := RewardGenerator.generate(pw, tier, rng, [], _synthetic_roster, max_rerolls_now, 3)
		if out.size() != 3:
			_fail("generate() returned %d rewards (want 3) at seed=%d tier=%d pw=%d" % [
				out.size(), seed_value, tier, pw])
			continue
		for r in out:
			var t := String(r.get("t", ""))
			if not VALID_TYPES.has(t):
				_fail("unexpected reward type '%s' at seed=%d" % [t, seed_value])
			if String(r.get("title", "")) == "":
				_fail("reward of type '%s' has an empty title at seed=%d" % [t, seed_value])


func _check_reroll_rules() -> void:
	for i in 500:
		var seed_value := i * 92821 + 3
		var rng := Rng.new(seed_value)
		# max_rerolls_now < 4: reroll is eligible; must never appear more than once.
		var out := RewardGenerator.generate(i % 15, i % 4, rng, [], _synthetic_roster, 2, 3)
		var reroll_count := 0
		for r in out:
			if String(r.get("t", "")) == "reroll":
				reroll_count += 1
		if reroll_count > 1:
			_fail("reroll appeared %d times in one offer at seed=%d" % [reroll_count, seed_value])

		# max_rerolls_now >= 4: reroll must never appear at all.
		var rng2 := Rng.new(seed_value)
		var out2 := RewardGenerator.generate(i % 15, i % 4, rng2, [], _synthetic_roster, 4, 3)
		for r2 in out2:
			if String(r2.get("t", "")) == "reroll":
				_fail("reroll appeared with max_rerolls_now=4 at seed=%d" % seed_value)


func _check_relic_dedup() -> void:
	var owned := ["r_ember", "r_spines"]
	for i in 500:
		var seed_value := i * 65537 + 11
		var rng := Rng.new(seed_value)
		# High tier (band [2,4]) to maximize relic-type pressure and dedup exposure.
		var out := RewardGenerator.generate(i % 10, 3, rng, owned, _synthetic_roster, 2, 3)
		var seen: Array = []
		for r in out:
			if String(r.get("t", "")) != "relic":
				continue
			var key := String(r.get("key", ""))
			if owned.has(key):
				_fail("relic reward '%s' duplicates an owned relic at seed=%d" % [key, seed_value])
			if seen.has(key):
				_fail("relic reward '%s' duplicated within one offer at seed=%d" % [key, seed_value])
			seen.append(key)


func _check_determinism() -> void:
	for i in 100:
		var seed_value := i * 7919 + 1
		var tier := i % 4
		var pw := i % 12
		var out1 := RewardGenerator.generate(pw, tier, Rng.new(seed_value), [], _synthetic_roster, 2, 3)
		var out2 := RewardGenerator.generate(pw, tier, Rng.new(seed_value), [], _synthetic_roster, 2, 3)
		if out1 != out2:
			_fail("generate() not deterministic for seed=%d tier=%d pw=%d" % [seed_value, tier, pw])


func _check_shop_items() -> void:
	for i in 200:
		var seed_value := i * 51893 + 5
		var rng := Rng.new(seed_value)
		var items := RewardGenerator.generate_shop_items(rng, [])
		var relic_ids: Array = []
		var saw_heal := false
		var saw_reroll := false
		for it in items:
			var kind := String(it.get("kind", ""))
			if kind == "relic":
				var rid := String(it.get("key", ""))
				if relic_ids.has(rid):
					_fail("shop offered duplicate relic '%s' at seed=%d" % [rid, seed_value])
				relic_ids.append(rid)
				var rar := int(it.get("rar", -1))
				var expected_cost: int = RewardGenerator.RELIC_SHOP_COST[clampi_local(rar, 0, 4)]
				if int(it.get("cost", -1)) != expected_cost:
					_fail("shop relic '%s' cost %d != expected %d (rar=%d) at seed=%d" % [
						rid, int(it.get("cost", -1)), expected_cost, rar, seed_value])
			elif kind == "heal":
				saw_heal = true
				if int(it.get("cost", -1)) != RewardGenerator.HEAL_ITEM_COST:
					_fail("shop heal item cost mismatch at seed=%d" % seed_value)
			elif kind == "reroll":
				saw_reroll = true
				if int(it.get("cost", -1)) != RewardGenerator.REROLL_ITEM_COST:
					_fail("shop reroll item cost mismatch at seed=%d" % seed_value)
		if relic_ids.size() != 2:
			_fail("shop offered %d relics (want 2) at seed=%d" % [relic_ids.size(), seed_value])
		if not saw_heal:
			_fail("shop missing heal item at seed=%d" % seed_value)
		if not saw_reroll:
			_fail("shop missing reroll item at seed=%d" % seed_value)


func _check_pick_relic_bounds() -> void:
	var rng := Rng.new(999)
	for i in 300:
		var def := RewardGenerator.pick_relic(rng, ["r_ember"], 1, 3)
		if def == null:
			continue
		if def.id == "r_ember":
			_fail("pick_relic() returned an excluded id")
		if def.rarity < 1 or def.rarity > 3:
			_fail("pick_relic() returned rarity %d outside [1,3]" % def.rarity)


static func clampi_local(v: int, lo: int, hi: int) -> int:
	return mini(maxi(v, lo), hi)
