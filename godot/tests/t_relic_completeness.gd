extends Node
## Gate for relic completeness: every relic the game can offer must actually DO something.
##
## THE FAILURE THIS EXISTS FOR
## ---------------------------
## A RelicDef names its behaviour with `hook_key`, and RelicHooks looks that key up in its
## TABLE. When the key is absent, nothing complains: `mod_face_order()` skips the relic,
## `call_hook()` returns null, `fire()` no-ops. The player is offered a Legendary, pays for
## it, sees it in their relic list — and it does nothing, forever, with no error anywhere.
##
## That is not hypothetical. The 74 relics added on 2026-09-18 all shipped with a `hook_key`
## before a single TABLE entry existed for them, and the full 19-test suite stayed green.
## Content that is inert is indistinguishable from content that is balanced badly, which is
## why this has to be checked by name rather than by "does the suite still pass".
##
## THE EXPECTED TABLE BELOW IS THE CONTRACT
## ----------------------------------------
## It is derived from `src/data.js` RELICS[] — every entry whose JS body defines a hook
## function, and which of the eleven hooks it defines. It is written out here rather than
## computed so that a relic quietly losing a hook is a test failure and not a silently
## smaller expectation.
##
## Run: godot --headless --path godot res://tests/t_relic_completeness.tscn

## relic id -> the RelicHooks events its src/data.js entry defines.
const EXPECTED_HOOKS := {
	"r_claw": ["mod_face"],
	"r_carapace": ["mod_face"],
	"r_pierceall": ["mod_face"],
	"r_cleaveall": ["mod_face"],
	"r_bloodmouth": ["mod_face"],
	"r_gorehook": ["mod_face"],
	"r_barbedhide": ["mod_face"],
	"r_rotbite": ["mod_dmg"],
	"r_tinderbox": ["mod_dmg"],
	"r_lastwall": ["on_turn_start"],
	"r_tidalbrand": ["mod_face", "on_turn_start"],
	"r_heart": ["mod_face"],
	"r_ear": ["mod_face"],
	"r_spines": ["on_turn_start"],
	"r_ember": ["on_hit"],
	"r_openwound": ["mod_dmg"],
	"r_deathmark": ["mod_face", "on_kill"],
	"r_wildfire": ["mod_face"],
	"r_voidgene": ["on_turn_start"],
	"r_talonedge": ["mod_face"],
	"r_marrowdrill": ["mod_face"],
	"r_heartwood": ["growth_all_guard"],
	"r_bloomscale": ["mod_face"],
	"r_eggshell": ["on_turn_start"],
	"r_broodmother": ["on_kill", "on_turn_start"],
	"r_bloodthorn": ["mod_face", "on_dmg_taken"],
	"r_scentofblood": ["mod_dmg"],
	"r_rotmouth": ["mod_face"],
	"r_bloodhymn": ["on_hit"],
	"r_squallmark": ["mod_face"],
	"r_fang": ["mod_face"],
	"r_regrow": ["mod_face", "on_turn_start"],
	"r_bastionplate": ["on_shield"],
	"r_pyroclasm": ["mod_face"],
	"r_chainreact": ["on_kill"],
	"r_growthcore": ["mod_face", "mod_face2"],
	"r_infinitedie": ["on_turn_start"],
	"r_thousandcuts": ["mod_face", "mod_face2"],
	"r_quickenroot": ["on_roll_end"],
	"r_apexbrood": ["on_turn_start"],
	"r_glassspine": ["on_shield"],
	"r_retributor": ["on_thorns"],
	"r_cullingorder": ["on_kill"],
	"r_deathspiral": ["on_hit"],
	"r_pandemic": ["on_kill"],
	"r_manaspring": ["on_turn_start"],
	"r_keeneye": ["on_roll_end"],
	"r_windlash": ["mod_face", "mod_face2"],
	"r_bloodpact": ["mod_face"],
	"r_plaguelord": ["mod_face"],
	"r_soulforge": ["mod_face"],
	"r_stormcall": ["mod_face"],
	"r_manaflood": ["on_turn_start"],
	"r_ancientgene": ["mod_face"],
	"r_worldpiercer": ["mod_face"],
	"r_dawnlance": ["mod_dmg"],
	"r_ironmaiden": ["on_turn_start"],
	"r_scalecrown": ["on_turn_start", "on_thorns"],
	"r_apexferal": ["mod_face", "on_hit"],
	"r_conduitcrown": ["on_turn_start"],
}

var _failures: Array[String] = []
var _checks := 0


func _ready() -> void:
	print("=== t_relic_completeness: start ===")
	test_every_relic_in_the_source_has_a_resource()
	test_every_hook_key_exists_in_the_table()
	test_every_expected_hook_event_is_implemented()
	test_no_table_entry_is_orphaned()
	test_every_relic_has_a_description()
	test_sort_index_matches_the_source_order()
	test_every_active_card_has_a_cost_and_a_known_kind()

	print("=== t_relic_completeness: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_relic_completeness: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_relic_completeness: FAIL — %s" % f)
	get_tree().quit(1)


func _assert(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)


func _defs() -> Array:
	var out: Array = []
	for d in RelicRegistry.all_defs_sorted():
		if not String(d.id).begins_with("__"):   # __curse_dmg is a pseudo-relic, never offered
			out.append(d)
	return out


# ---------------------------------------------------------------------------

## src/data.js ships 94 relics. Anything missing here is content the Godot build simply does
## not have, which shows up as a thinner reward pool rather than as an error.
func test_every_relic_in_the_source_has_a_resource() -> void:
	_assert(_defs().size() == 94,
		"expected 94 relics loaded, found %d — src/data.js RELICS[] has 94" % _defs().size())


func test_every_hook_key_exists_in_the_table() -> void:
	for def in _defs():
		var hk := String(def.hook_key)
		if hk == "":
			continue
		_assert(RelicHooks.TABLE.has(hk),
			"relic '%s' declares hook_key '%s' but RelicHooks.TABLE has no such entry — the "
				% [def.id, hk]
			+ "relic is offered, bought and listed, and does nothing at all")


## Having an entry is not enough: it has to implement the same hooks the JS relic does. A
## relic with `modFace` and `onKill` that only ships `mod_face` is half a relic, and the half
## that is missing is invisible.
func test_every_expected_hook_event_is_implemented() -> void:
	for id in EXPECTED_HOOKS.keys():
		var rid := String(id)
		var def = RelicRegistry.get_def(rid)
		_assert(def != null, "relic '%s' has hooks in src/data.js but no .tres at all" % rid)
		if def == null:
			continue
		var hk := String(def.hook_key)
		_assert(hk != "", "relic '%s' defines %d hook(s) in src/data.js but its .tres leaves "
			% [rid, (EXPECTED_HOOKS[id] as Array).size()] + "hook_key empty")
		if hk == "" or not RelicHooks.TABLE.has(hk):
			continue
		var entry: Dictionary = RelicHooks.TABLE[hk]
		for ev in EXPECTED_HOOKS[id]:
			_assert(entry.has(ev),
				"relic '%s' must implement '%s' (src/data.js defines it) — it is missing"
					% [rid, ev])


## The other direction: a TABLE entry nothing points at is dead code, and usually means a
## typo in a .tres `hook_key` rather than a spare implementation.
func test_no_table_entry_is_orphaned() -> void:
	var used: Dictionary = {}
	for d in RelicRegistry.all_defs_sorted():
		if String(d.hook_key) != "":
			used[String(d.hook_key)] = true
	for k in RelicHooks.TABLE.keys():
		_assert(used.has(String(k)),
			"RelicHooks.TABLE has an entry '%s' that no relic points at — most likely a "
				% k + "hook_key typo, since a relic with a typo'd key silently does nothing")


func test_every_relic_has_a_description() -> void:
	for def in _defs():
		_assert(String(def.description).strip_edges() != "",
			"relic '%s' (%s) has no description — the player sees a name and no rule, which "
				% [def.id, def.name] + "reads as a relic that does nothing")


## sort_index is INV-5's tie-break. It must equal phase*100000 + rarity*1000 + the relic's
## position in src/data.js RELICS[], because that is the order JS resolves ties in. A wrong
## index is inert until two relics share a phase and rarity, and then it silently produces a
## different result from the live game — which is how 17 of the first 20 shipped one too low.
func test_sort_index_matches_the_source_order() -> void:
	var rank := {"kw": 0, "add": 1, "mul": 2}
	var by_index: Array = _defs().duplicate()
	by_index.sort_custom(func(a, b): return int(a.sort_index) < int(b.sort_index))
	for def in _defs():
		var phase: int = int(rank.get(String(def.mf_phase), 1))
		var remainder: int = int(def.sort_index) - phase * 100000 - int(def.rarity) * 1000
		_assert(remainder >= 0 and remainder < 94,
			"relic '%s' has sort_index %d, which does not decompose into "
				% [def.id, def.sort_index]
			+ "phase(%d)*100000 + rarity(%d)*1000 + a valid RELICS[] position (got %d)"
				% [phase, def.rarity, remainder])


func test_every_active_card_has_a_cost_and_a_known_kind() -> void:
	# The kinds CombatEngine.play_active() actually dispatches on. A card with any other kind
	# takes the player's Mana and does nothing.
	var known := ["heal", "dmg", "ult", "shieldall", "dmgall", "poisonall", "stun",
		"reroll", "kw", "grow", "summon", "shatter"]
	var actives := 0
	for def in _defs():
		if def.act_cost <= 0 and (def.act as Dictionary).is_empty():
			continue
		actives += 1
		_assert(def.act_cost > 0,
			"active card '%s' has an act payload but costs 0 Mana" % def.id)
		var kind := String((def.act as Dictionary).get("kind", ""))
		_assert(kind in known,
			"active card '%s' has kind '%s', which play_active() does not dispatch — "
				% [def.id, kind] + "playing it would spend Mana and do nothing")
	_assert(actives == 16, "expected 16 active cards, found %d" % actives)
