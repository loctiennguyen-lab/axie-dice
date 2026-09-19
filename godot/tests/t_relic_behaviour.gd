extends Node
## Proof that each newly-authored relic CHANGES something, by running the real engine with
## the relic owned and comparing against the same seed without it.
##
## WHY THIS IS SEPARATE FROM t_relic_completeness
## ----------------------------------------------
## That test proves the wiring: every `hook_key` resolves to a TABLE entry declaring the right
## events. It cannot prove the bodies work, and it did not: `r_broodmother` shipped calling
## `Unit.set_used()`, which does not exist — the method is `mark_used()`. GDScript resolves
## that at call time, on an untyped local, so neither the syntax preflight nor a wiring check
## could see it. The relic would have crashed the first time an enemy died while it was owned.
##
## So the invariant here is deliberately coarse and behavioural: own the relic, drive the real
## CombatEngine, and require an OBSERVABLE difference. A relic whose body never runs, throws,
## or is a no-op fails. That is a weaker claim than "the numbers match src/engine.js" — the
## per-relic numbers are asserted individually below where the JS body is unambiguous — but it
## is the claim that catches a whole class of silent-nothing bugs at once.
##
## Run: godot --headless --path godot res://tests/t_relic_behaviour.tscn

const SEED := 90210

## `bird1` is in this roster on purpose, in place of `bug1`. Three relics —
## r_cleaveall, r_marrowdrill and r_thousandcuts — only act on damage faces that ALREADY
## carry pierce or cleave/aoe, and no tier-1 die except Bird's has one. With the obvious
## starter roster they each produced no change, and a test that only asked "did anything
## change?" would have reported them broken; a test that asserted nothing would have passed
## them while proving nothing. Bird T1 ships 2 pierce and 1 cleave damage face, which is what
## gives those three something real to bite on.
const ROSTER := ["plant1", "beast1", "aqua1", "reptile1", "bird1"]

## Relics whose effect is visible in the party's dice the moment combat is built (modFace),
## paired with an assertion over the built die. `null` means "just require a difference".
const DIE_RELICS := ["r_claw", "r_carapace", "r_pierceall", "r_cleaveall", "r_bloodmouth",
	"r_gorehook", "r_barbedhide", "r_heart", "r_ear", "r_talonedge", "r_marrowdrill",
	"r_bloomscale", "r_rotmouth", "r_squallmark", "r_fang", "r_pyroclasm", "r_wildfire",
	"r_bloodpact", "r_plaguelord", "r_soulforge", "r_stormcall", "r_ancientgene",
	"r_worldpiercer", "r_tidalbrand", "r_deathmark", "r_bloodthorn", "r_regrow",
	"r_growthcore", "r_thousandcuts", "r_windlash", "r_apexferal"]

var _failures: Array[String] = []
var _checks := 0


func _ready() -> void:
	print("=== t_relic_behaviour: start ===")
	test_every_die_relic_actually_changes_a_die()
	test_claw_adds_exactly_one_to_damage_faces_only()
	test_ancientgene_multiplies_and_rounds_up()
	test_ancientgene_runs_after_flat_adders()
	test_heart_raises_max_hp_by_twelve()
	test_bloodpact_cuts_max_hp_and_never_below_four()
	test_thousandcuts_halves_after_the_adders_and_adds_multi()
	test_turn_start_mana_relics_grant_on_turn_one_only()
	test_regrow_floors_regen_without_stacking()
	test_scalecrown_floors_thorns_on_the_whole_party()
	test_every_turn_start_and_roll_end_hook_survives_a_real_turn()
	test_on_kill_hooks_survive_a_real_enemy_death()
	test_every_path_that_writes_growth_is_visible_to_the_reader()

	print("=== t_relic_behaviour: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_relic_behaviour: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_relic_behaviour: FAIL — %s" % f)
	get_tree().quit(1)


func _assert(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)


func _roster(keys: Array) -> Array:
	var out: Array = []
	for i in keys.size():
		out.append({
			"persistent_id": i + 1, "hero_key": keys[i], "tier": 1,
			"max_hp": ContentDB.heroes[keys[i]]["max_hp"],
			"muts": [], "growth": {}, "bonus_hp": 0,
		})
	return out


func _combat(relic_ids: Array, pw: int = 2) -> CombatEngine:
	var c := CombatEngine.new()
	c.setup_new({
		"node_id": "t_relic_behaviour", "kind": "battle", "pw": pw, "ascension": 0,
		"roster_snapshot": _roster(ROSTER),
		"relic_ids": relic_ids, "combat_seed": SEED, "bonus_reroll": 0,
	})
	return c


## A comparable snapshot of the whole party: every face's type/part/value/keywords plus max HP.
func _party_shape(c: CombatEngine) -> String:
	var parts: Array = []
	for u in c.party:
		var faces: Array = []
		for f in u.die:
			var kw: Array = (f["keywords"] as Array).duplicate()
			kw.sort()
			faces.append("%s/%s/%d/%s" % [f.get("part", ""), f.get("type", ""),
				int(f.get("value", 0)), ",".join(PackedStringArray(kw))])
		parts.append("%d|%s" % [u.max_hp, " ".join(PackedStringArray(faces))])
	return "\n".join(PackedStringArray(parts))


# ---------------------------------------------------------------------------

## The broad net. Each of these relics rewrites the die or max HP at build time, so owning it
## must make the party observably different on an identical seed. A body that silently does
## nothing — a wrong field name, an `if` that never matches — fails here.
func test_every_die_relic_actually_changes_a_die() -> void:
	var baseline := _party_shape(_combat([]))
	for rid in DIE_RELICS:
		var shaped := _party_shape(_combat([rid]))
		_assert(shaped != baseline,
			"relic '%s' owned makes no difference to the party at all — its modFace body "
				% rid + "either never matches a face or never runs")


func test_claw_adds_exactly_one_to_damage_faces_only() -> void:
	var plain := _combat([])
	var clawed := _combat(["r_claw"])
	for i in plain.party.size():
		for j in (plain.party[i] as Unit).die.size():
			var before: Dictionary = plain.party[i].die[j]
			var after: Dictionary = clawed.party[i].die[j]
			var want: int = int(before.get("value", 0)) + (1 if String(before.get("type", "")) == "dmg" else 0)
			_assert(int(after.get("value", 0)) == want,
				"r_claw on party %d face %d (%s): expected %d, got %d"
					% [i, j, before.get("type", ""), want, int(after.get("value", 0))])


## JS: `if (f.v > 0) f.v = Math.ceil(f.v * 1.3)`. Blanks (value 0) must stay 0 — a blanket
## multiply would turn every blank face into a 0 that still reads as a real face downstream.
func test_ancientgene_multiplies_and_rounds_up() -> void:
	var plain := _combat([])
	var gened := _combat(["r_ancientgene"])
	for i in plain.party.size():
		for j in (plain.party[i] as Unit).die.size():
			var v := int((plain.party[i].die[j] as Dictionary).get("value", 0))
			var want: int = int(ceil(float(v) * 1.3)) if v > 0 else 0
			var got := int((gened.party[i].die[j] as Dictionary).get("value", 0))
			_assert(got == want,
				"r_ancientgene on party %d face %d: expected ceil(%d*1.3)=%d, got %d"
					% [i, j, v, want, got])


## INV-1, the reason mf_phase exists. r_claw is an "add", r_ancientgene a "mul". The result
## must be ceil((v+1)*1.3) — the multiplier last — and must NOT depend on which order the two
## relic ids were picked up in.
func test_ancientgene_runs_after_flat_adders() -> void:
	var plain := _combat([])
	var a := _combat(["r_claw", "r_ancientgene"])
	var b := _combat(["r_ancientgene", "r_claw"])
	_assert(_party_shape(a) == _party_shape(b),
		"owning r_claw + r_ancientgene gives a different party depending on pickup order — "
		+ "INV-1 broken: a relic's power is a range instead of a number")
	for i in plain.party.size():
		for j in (plain.party[i] as Unit).die.size():
			var f: Dictionary = plain.party[i].die[j]
			var v := int(f.get("value", 0))
			var adds: int = 1 if String(f.get("type", "")) == "dmg" else 0
			var want: int = int(ceil(float(v + adds) * 1.3)) if (v + adds) > 0 else 0
			var got := int((a.party[i].die[j] as Dictionary).get("value", 0))
			_assert(got == want,
				"party %d face %d: expected the add BEFORE the multiply, ceil((%d+%d)*1.3)=%d, got %d"
					% [i, j, v, adds, want, got])


func test_heart_raises_max_hp_by_twelve() -> void:
	var plain := _combat([])
	var hearty := _combat(["r_heart"])
	for i in plain.party.size():
		_assert(hearty.party[i].max_hp == plain.party[i].max_hp + 12,
			"r_heart on party %d: expected %d max HP, got %d"
				% [i, plain.party[i].max_hp + 12, hearty.party[i].max_hp])


## JS: `u.maxHp = Math.max(4, Math.round(u.maxHp * 0.85))`. The floor of 4 is the part worth
## a test: without it the relic could reduce a small unit to 0 max HP, which is not "risk".
func test_bloodpact_cuts_max_hp_and_never_below_four() -> void:
	var plain := _combat([])
	var pacted := _combat(["r_bloodpact"])
	for i in plain.party.size():
		var want: int = maxi(4, int(round(float(plain.party[i].max_hp) * 0.85)))
		_assert(pacted.party[i].max_hp == want,
			"r_bloodpact on party %d: expected %d max HP, got %d"
				% [i, want, pacted.party[i].max_hp])
		_assert(pacted.party[i].max_hp >= 4, "r_bloodpact took party %d below the floor of 4" % i)


## Two phases on one relic: the keyword in "kw", the halving in "add". The halving must see
## the value AFTER other adders, so it is asserted against the value the same build produces.
func test_thousandcuts_halves_after_the_adders_and_adds_multi() -> void:
	var plain := _combat([])
	var cut := _combat(["r_thousandcuts"])
	var pierce_faces := 0
	for i in plain.party.size():
		for j in (plain.party[i] as Unit).die.size():
			var before: Dictionary = plain.party[i].die[j]
			var after: Dictionary = cut.party[i].die[j]
			if String(before.get("type", "")) != "dmg" or not (before["keywords"] as Array).has("pierce"):
				continue
			pierce_faces += 1
			var want: int = int(ceil(float(before.get("value", 0)) / 2.0)) + 2
			_assert(int(after.get("value", 0)) == want,
				"r_thousandcuts on a pierce face: expected ceil(%d/2)+2=%d, got %d"
					% [int(before.get("value", 0)), want, int(after.get("value", 0))])
			var has_multi := false
			for k in (after["keywords"] as Array):
				if String(k).begins_with("multi"):
					has_multi = true
			_assert(has_multi, "r_thousandcuts left a pierce face without a multi keyword")
	_assert(pierce_faces > 0,
		"no starting die has a pierce damage face, so this test proved nothing — pick a "
		+ "roster that has one rather than leaving the assertion vacuous")


## These three grant Mana on turn 1 only. Asserting the amount AND that turn 2 adds nothing
## is the point: `if (s.turn === 1)` is easy to drop, and the relic would then print money.
func test_turn_start_mana_relics_grant_on_turn_one_only() -> void:
	for pair in [["r_voidgene", 1], ["r_infinitedie", 1], ["r_manaflood", 3]]:
		var rid: String = pair[0]
		var amount: int = pair[1]
		var plain := _combat([])
		var withr := _combat([rid])
		_assert(withr.mana == plain.mana + amount,
			"%s: expected %d Mana at combat start, got %d (baseline %d)"
				% [rid, plain.mana + amount, withr.mana, plain.mana])
		var before_t2 := withr.mana
		withr.turn = 2
		RelicHooks.fire(withr, "on_turn_start", {"combat": withr})
		_assert(withr.mana == before_t2,
			"%s granted Mana again on turn 2 — the turn==1 guard is missing" % rid)


## `Math.max(existing, 2)` is a floor. Firing it twice must not reach 4.
func test_regrow_floors_regen_without_stacking() -> void:
	var c := _combat(["r_regrow"])
	for u in c.party:
		_assert(int(u.status.get("regen", 0)) >= 2,
			"r_regrow left party member %d without Regen 2 at combat start" % u.uid)
	RelicHooks.fire(c, "on_turn_start", {"combat": c})
	for u in c.party:
		_assert(int(u.status.get("regen", 0)) == 2,
			"r_regrow stacked Regen to %d on a second turn — it must be a floor, not an add"
				% int(u.status.get("regen", 0)))


func test_scalecrown_floors_thorns_on_the_whole_party() -> void:
	var c := _combat(["r_scalecrown"])
	for u in c.party:
		_assert(int(u.status.get("thorns", 0)) >= 2,
			"r_scalecrown left party member %d without Thorns 2" % u.uid)


## The crash-catcher. Every relic with an on_turn_start or on_roll_end body is owned at once
## and a real turn is driven; anything that calls a method that does not exist, or reads a
## field under the wrong name, throws here rather than in front of a player.
func test_every_turn_start_and_roll_end_hook_survives_a_real_turn() -> void:
	var ids: Array = []
	for def in RelicRegistry.all_defs_sorted():
		var hk := String(def.hook_key)
		if hk == "" or not RelicHooks.TABLE.has(hk):
			continue
		var entry: Dictionary = RelicHooks.TABLE[hk]
		if entry.has("on_turn_start") or entry.has("on_roll_end"):
			ids.append(def.id)
	_assert(ids.size() >= 10,
		"expected at least 10 turn-start/roll-end relics to exercise, found %d" % ids.size())

	var c := _combat(ids)
	# Turn 1 already ran inside setup_new(); drive a second turn so the turn>1 branches
	# (r_heartwood's growth guard, r_quickenroot's growth) actually execute too.
	c.turn = 2
	RelicHooks.fire(c, "on_turn_start", {"combat": c})
	RelicHooks.fire(c, "on_roll_end", {"combat": c})
	_assert(c.party.size() >= 5, "the party vanished while firing every turn hook at once")
	_assert(c.mana >= 0, "mana went negative while firing every turn hook at once")


## Same crash-catcher for the death path, which is where `r_broodmother` called a method that
## does not exist. Killing a real enemy through DamagePipeline fires on_kill for every owned
## relic at once.
func test_on_kill_hooks_survive_a_real_enemy_death() -> void:
	var ids: Array = []
	for def in RelicRegistry.all_defs_sorted():
		var hk := String(def.hook_key)
		if hk == "" or not RelicHooks.TABLE.has(hk):
			continue
		if (RelicHooks.TABLE[hk] as Dictionary).has("on_kill"):
			ids.append(def.id)
	_assert(ids.size() >= 4, "expected at least 4 on-kill relics, found %d" % ids.size())

	var c := _combat(ids)
	var victim: Unit = c.alive_enemies()[0]
	var tokens_before := 0
	for u in c.party:
		if u.is_token:
			tokens_before += 1

	DamagePipeline.resolve({"combat": c, "src": null, "tgt": victim,
		"value": victim.hp + victim.shield + 999, "pierce": true, "attack": false})

	_assert(victim.hp <= 0, "the victim survived a hit for more than its total HP")
	# r_broodmother hatches an egg on a kill; that it ran at all is the assertion, since this
	# is the exact path whose body was calling a nonexistent method.
	var tokens_after := 0
	for u in c.party:
		if u.is_token:
			tokens_after += 1
	_assert(tokens_after > tokens_before,
		"r_broodmother was owned and an enemy died, but no Axie Egg hatched (%d -> %d tokens)"
			% [tokens_before, tokens_after])


## `Unit.growth` had two incompatible key conventions living in the same field, and the halves
## never met: `get_growth()`/`add_growth()` used `str(face_index)` while the `grow` active card,
## the growthAll relics, r_quickenroot and RunState._apply_growth_keep() all wrote the plain
## integer. `_face_value()` reads through `get_growth()`, so four of the five sources of growth
## in the game produced a number that was stored and never applied — silently, with no error.
##
## Asserted by OUTCOME, not by reading the accessor: write growth the way each caller writes it,
## then ask the engine what the face is worth. A future change that flips the convention at one
## end only fails here, which is what the original code needed and did not have.
func test_every_path_that_writes_growth_is_visible_to_the_reader() -> void:
	var c := _combat([])
	var u: Unit = c.party[0]
	var fi := -1
	for i in u.die.size():
		if int((u.die[i] as Dictionary).get("value", 0)) > 0:
			fi = i
			break
	_assert(fi >= 0, "no starting face carries a value, so this test proved nothing")
	if fi < 0:
		return
	var base: int = c._face_value(u, fi)

	# Path 1 — the accessor (the `growth` keyword on a face uses this).
	u.growth.clear()
	u.add_growth(fi, 3)
	_assert(c._face_value(u, fi) == base + 3,
		"growth written through add_growth() is not reaching _face_value(): expected %d, got %d"
			% [base + 3, c._face_value(u, fi)])

	# Path 2 — a direct integer-keyed write, which is what the `grow` card, growthAll and
	# r_quickenroot all do.
	u.growth.clear()
	u.growth[fi] = 4
	_assert(c._face_value(u, fi) == base + 4,
		"growth written with an integer key is not reaching _face_value(): expected %d, got %d "
			% [base + 4, c._face_value(u, fi)]
		+ "— the grow card, r_seedling, r_heartwood, r_quickenroot and r_worldtree all write "
		+ "this way, and every one of them would be inert")

	# Path 3 — both together must add, not shadow one another.
	u.growth.clear()
	u.growth[fi] = 2
	u.add_growth(fi, 3)
	_assert(c._face_value(u, fi) == base + 5,
		"two growth sources on one face did not stack: expected %d, got %d (one convention is "
			% [base + 5, c._face_value(u, fi)] + "shadowing the other)")
	u.growth.clear()

	# Path 4 — growthAll, driven for real. r_seedling grows EVERY face each turn.
	var grown := _combat(["r_seedling"])
	var g: Unit = grown.party[0]
	var before: Array = []
	for i in g.die.size():
		before.append(grown._face_value(g, i))
	grown.end_turn()
	var moved := 0
	for i in g.die.size():
		if grown._face_value(g, i) > int(before[i]):
			moved += 1
	_assert(moved > 0,
		"r_seedling (growthAll) changed no face value over a real turn — the relic is inert")
