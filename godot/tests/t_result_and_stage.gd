extends Node
## Gate for two UI fixes made on 2026-09-19 that nothing else holds in place: the ground-contact
## shadow under every unit, and the reading order of the end-of-run screen.
##
## WHY EITHER NEEDS A GATE
## -----------------------
##  1. **The shadow is a silent dependency on three unrelated spawn paths.** `spawn_unit()` builds
##     a unit as a Chimera sprite, an `AxieCharacter3D` rig, or a capsule placeholder, and each
##     computes its own shadow width. A change to any one of those can drop the shadow for that
##     branch alone — and the symptom is a character that looks slightly "pasted on", which is
##     exactly the thing nobody files a bug about.
##  2. **Reading order is invisible to every other test.** The screen still renders, every section
##     still has its content, and nothing errors if the order goes back to putting currency above
##     the run's own story. Order is the whole fix, so order is what gets pinned.
##
## Run: godot --headless --path godot res://tests/t_result_and_stage.tscn

const STAGE_SCENE := "res://scenes/shared/CombatStage3D.tscn"
const RESULT_SCENE := "res://scenes/result/Result.tscn"

## UPDATED 2026-09-20 for the v2 Result screen (docs/design-handoff-v2, RESULT tab). v1 built
## this screen as stacked text sections with literal headers ("RELICS COLLECTED", "PROGRESS",
## "PARTY", ...) and this constant pinned their reading order. v2 replaces that with named
## visual bands (party row / stat ribbon / card row / CTAs) that carry no such header text —
## "PROGRESS" and "PARTY" do not appear anywhere on the v2 screen as strings, so the old
## substring-order check cannot express the same rule any more.
##
## The RULE itself has NOT moved and is still checked below, just against band NAMES instead
## of header text: PartyRow (this run's build) reads above StatRibbon (this run's performance)
## reads above CardRow (shard/pass/relics) reads above the CTAs — outcome, then build, then
## currency, top to bottom.
##
## UPDATED (routing task, FIX-PASS-02 §1 item 4): the CTA row ("RUN IT AGAIN" / "MAIN MENU")
## used to be its own `CtaRow` Control anchored to the bottom of the raw viewport; it is now
## folded into the shared shell's `Footer` bar (DangoScreen.build()/add_back_button()/
## add_footer_action(), the same BACK + primary-action convention Pass/Unlocks/Vault/Guides
## already use) — see ResultView.gd's `_build_cta_row()`. `Footer` is what now stands in for
## "the CTAs" at the bottom of the reading order.
##
## One piece of the old rule DID get overridden, on purpose, by the mockup: v1 deliberately put
## "RELICS COLLECTED" ABOVE the shard/pass totals ("the relics are the story of THIS run and
## belong above the shard/XP totals, which look the same after every run"). The v2 mockup's
## card row is Shard / Pass / Relics, left to right, and per this project's own standing rule
## ("where the spec and a mockup disagree, the mockup is right") that literal order is what
## ResultView.gd now builds — see that file's `_build_card_row()` comment. So this file no
## longer asserts relics-before-currency; it only checks that all three cards are still present.
const EXPECTED_BAND_ORDER: Array[String] = ["PartyRow", "StatRibbon", "CardRow", "Footer"]
const EXPECTED_CARD_ROW_CAPTIONS: Array[String] = ["GENE SHARD", "LUNACIA PASS", "RELICS CARRIED"]

const EXPECTED_TESTS: Array[String] = [
	"test_every_spawned_unit_gets_a_ground_shadow",
	"test_a_bigger_unit_gets_a_bigger_shadow",
	"test_the_result_screen_reads_build_before_currency",
	"test_the_result_screen_leaks_no_null_or_nan",
]

## `ResultView._ready()` runs `RunState.end_run()`, which writes straight into the player's real
## `MetaState` save. See `save_guard.gd`.
var _guard := SaveGuard.new()

var _failures: Array[String] = []
var _checks := 0
var _completed: Array[String] = []


func _ready() -> void:
	print("=== t_result_and_stage: start ===")
	await get_tree().process_frame
	_guard.capture()

	await test_every_spawned_unit_gets_a_ground_shadow()
	await test_a_bigger_unit_gets_a_bigger_shadow()
	await test_the_result_screen_reads_build_before_currency()
	await test_the_result_screen_leaks_no_null_or_nan()

	_guard.restore()

	for name in EXPECTED_TESTS:
		if not _completed.has(name):
			_failures.append(("test '%s' did not run to completion — a runtime error aborted it "
				+ "part-way and every assertion after that point was skipped") % name)

	print("=== t_result_and_stage: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_result_and_stage: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_result_and_stage: FAIL — %s" % f)
	get_tree().quit(1)


func _done(test_name: String) -> void:
	_completed.append(test_name)


func _assert(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)


func _make_stage() -> Node:
	var stage: Node = (load(STAGE_SCENE) as PackedScene).instantiate()
	add_child(stage)
	await get_tree().process_frame
	return stage


## Every spawn path, not just the one a hero happens to take. A hero class goes down the rig
## branch, a monster with Chimera art down the sprite branch, and a monster with no art at all
## down the capsule placeholder — the branch most likely to be forgotten, because it is the one
## that already looks wrong.
func test_every_spawned_unit_gets_a_ground_shadow() -> void:
	var stage := await _make_stage()
	var cases := {
		1: {"cls": "plant", "key": "", "enemy": false, "label": "hero rig"},
		2: {"cls": "", "key": "gooey_slime", "enemy": true, "label": "monster / placeholder"},
	}
	for uid in cases:
		var c: Dictionary = cases[uid]
		# spawn_unit(uid, cls, is_enemy, slot_index, slot_count, is_boss, unit_key)
		stage.spawn_unit(int(uid), str(c["cls"]), bool(c["enemy"]), 0, 1, false, str(c["key"]))
		await get_tree().process_frame
		var shadow: MeshInstance3D = stage.get_shadow_mesh(int(uid))
		_assert(shadow != null,
			"a %s unit spawned with NO ground shadow — it will read as pasted on top of the "
			% str(c["label"]) + "background art rather than standing in the scene")
		if shadow != null:
			_assert(shadow.visible, "the %s unit's shadow exists but is hidden" % str(c["label"]))
			_assert(shadow.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
				"the %s unit's fake shadow casts a real shadow of its own" % str(c["label"]))
	stage.queue_free()
	_done("test_every_spawned_unit_gets_a_ground_shadow")


## The point of a contact shadow is that it matches the thing standing on it. One fixed size for
## every unit puts a small shadow under a boss and a wide one under an egg, which reads worse than
## no shadow at all — the eye reads the mismatch as the model floating.
func test_a_bigger_unit_gets_a_bigger_shadow() -> void:
	var stage := await _make_stage()
	stage.spawn_unit(10, "plant", false, 0, 1, false, "")
	stage.spawn_unit(11, "", true, 0, 1, true, "gooey_king")
	await get_tree().process_frame

	var small: MeshInstance3D = stage.get_shadow_mesh(10)
	var boss: MeshInstance3D = stage.get_shadow_mesh(11)
	_assert(small != null and boss != null, "one of the two test units has no shadow to compare")
	if small != null and boss != null:
		var sm := small.mesh as QuadMesh
		var bm := boss.mesh as QuadMesh
		_assert(sm != null and bm != null, "a shadow is not the QuadMesh this test expects")
		if sm != null and bm != null:
			_assert(bm.size.x > sm.size.x,
				"a named boss got a shadow %s wide and a normal unit got %s — the shadow does not "
				% [str(bm.size.x), str(sm.size.x)]
				+ "track unit size, so a boss appears to hover over a puddle")
	stage.queue_free()
	_done("test_a_bigger_unit_gets_a_bigger_shadow")


## The reorder itself, expressed against v2's band structure — see EXPECTED_BAND_ORDER's
## comment for why this no longer reads section-header text.
func test_the_result_screen_reads_build_before_currency() -> void:
	RunState.start_new_run(5150, ["plant1", "beast1", "aqua1", "reptile1", "bug1"],
		"short", 0, false)
	RunState.power_level = 4
	RunState.shards_this_run = 88
	var screen := (load(RESULT_SCENE) as PackedScene).instantiate()
	add_child(screen)
	await get_tree().process_frame

	# Bands, in the order they actually appear as children of the screen root.
	var seen: Array[String] = []
	for want in EXPECTED_BAND_ORDER:
		var node := screen.find_child(want, true, false)
		if node != null:
			seen.append(want)
	_assert(seen.size() == EXPECTED_BAND_ORDER.size(),
		"found %d of the %d expected bands on the Result screen: %s"
		% [seen.size(), EXPECTED_BAND_ORDER.size(), str(seen)])
	# Compare by on-screen Y position (top offset), not by tree/add_child order — a band that
	# is reparented under an intermediate host still has to actually READ top-to-bottom.
	var tops: Array[float] = []
	for want in EXPECTED_BAND_ORDER:
		var node := screen.find_child(want, true, false) as Control
		tops.append(node.global_position.y if node != null else -1.0)
	var ordered := true
	for i in range(1, tops.size()):
		if tops[i] <= tops[i - 1]:
			ordered = false
	_assert(ordered,
		("the Result screen's bands do not read top to bottom in the order %s (Y offsets %s) "
		+ "— outcome, then this run's build (party/stats), then meta-currency (shard/pass/"
		+ "relics), then the CTAs")
		% [str(EXPECTED_BAND_ORDER), str(tops)])

	# The card row's three captions are all present — see EXPECTED_CARD_ROW_CAPTIONS' comment
	# for why their RELATIVE order is no longer asserted here.
	var card_text := ""
	var card_row := screen.find_child("CardRow", true, false)
	if card_row != null:
		for node in _descendants_for_text(card_row):
			var lbl := node as Label
			if lbl != null:
				card_text += lbl.text.to_upper() + "\n"
	for caption in EXPECTED_CARD_ROW_CAPTIONS:
		_assert(card_text.contains(caption),
			"the Result screen's card row is missing '%s' — full card row text: %s"
			% [caption, card_text])

	screen.queue_free()
	RunState.reset()
	_done("test_the_result_screen_reads_build_before_currency")


func _descendants_for_text(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for child in node.get_children():
		out.append_array(_descendants_for_text(child))
	return out


## The project's standing UI rule, applied to the screen that shows the most derived numbers.
func test_the_result_screen_leaks_no_null_or_nan() -> void:
	RunState.start_new_run(5151, ["plant1", "beast1", "aqua1", "reptile1", "bug1"],
		"short", 0, false)
	var screen := (load(RESULT_SCENE) as PackedScene).instantiate()
	add_child(screen)
	await get_tree().process_frame

	var seen := 0
	for node in screen.find_children("*", "Label", true, false):
		var text := (node as Label).text
		seen += 1
		for leak in ["<NULL>", "NaN", "undefined", "inf"]:
			_assert(not text.contains(leak),
				"a Label on the Result screen reads '%s' — it leaks '%s'" % [text, leak])
	_assert(seen > 8, "only %d labels found; the sweep is not reaching the sections" % seen)

	screen.queue_free()
	RunState.reset()
	_done("test_the_result_screen_leaks_no_null_or_nan")
