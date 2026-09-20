extends Node
## Gate for the LUNACIA PASS and UNLOCKS screens (docs/design-handoff-v2 v2 restyle).
##
## WHAT IS ACTUALLY AT RISK
## ------------------------
##  1. **The regression this task exists to close.** Until these two screens landed, their
##     Main Menu nav tiles were wired disabled (see MainMenu.gd's "GAP FLAGGED" note) and
##     spending Gene Shard / claiming Pass rewards was unreachable from the UI at all.
##     `t_mainmenu_ui.gd::test_disabled_nav_tiles_use_player_facing_tooltips` now asserts both
##     tiles are enabled; this file asserts the screens they route to actually work.
##  2. **A `face`-type Pass milestone rendering as claimable.** `MetaState.claim_bp_reward()`
##     already refuses these (FACE_POOL is unported) — if the screen ever shows one as
##     "CLAIM NOW", pressing it is a button that fails silently after being pressed, exactly the
##     failure this project already shipped once in the event system.
##  3. **An inert unlock (`u_relic1`/`u_relic2`/`u_face1`/`u_face2`) hiding what it does.**
##     Buying one is a real, refundless spend of Gene Shard for an effect this port has not
##     built; the "NO EFFECT YET" tag is the only thing telling the player that before they buy.
##
## Run: godot --headless --path godot res://tests/t_pass_unlocks.tscn

const PASS_SCENE := "res://scenes/pass/Pass.tscn"
const UNLOCKS_SCENE := "res://scenes/unlocks/Unlocks.tscn"

const EXPECTED_TESTS: Array[String] = [
	"test_pass_screen_renders_all_thirty_track_levels",
	"test_claiming_a_claim_now_reward_updates_state_and_view",
	"test_a_face_type_reward_never_becomes_claimable",
	"test_unlocks_screen_renders_all_ten_ladder_rows",
	"test_buying_an_available_unlock_spends_shards_and_flips_the_row",
	"test_the_no_effect_yet_tag_appears_on_exactly_the_four_inert_ids",
	"test_no_label_leaks_a_null_or_nan_into_its_text",
]

var _failures: Array[String] = []
var _checks := 0
var _completed: Array[String] = []
## Both screens read/write MetaState (the real save autoload) directly — borrow it whole and put
## it back, same pattern as t_vault.gd / t_guides_daily.gd.
var _save_guard := SaveGuard.new()


func _ready() -> void:
	print("=== t_pass_unlocks: start ===")
	await get_tree().process_frame
	_save_guard.capture()

	await test_pass_screen_renders_all_thirty_track_levels()
	await test_claiming_a_claim_now_reward_updates_state_and_view()
	await test_a_face_type_reward_never_becomes_claimable()
	await test_unlocks_screen_renders_all_ten_ladder_rows()
	await test_buying_an_available_unlock_spends_shards_and_flips_the_row()
	await test_the_no_effect_yet_tag_appears_on_exactly_the_four_inert_ids()
	await test_no_label_leaks_a_null_or_nan_into_its_text()

	_save_guard.restore()

	for name in EXPECTED_TESTS:
		if not _completed.has(name):
			_failures.append(("test '%s' did not run to completion — a runtime error aborted it "
				+ "part-way and every assertion after that point was skipped") % name)

	print("=== t_pass_unlocks: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_pass_unlocks: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_pass_unlocks: FAIL — %s" % f)
	get_tree().quit(1)


func _done(test_name: String) -> void:
	_completed.append(test_name)


func _assert(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)


func _spawn(scene_path: String) -> Control:
	var node := (load(scene_path) as PackedScene).instantiate() as Control
	add_child(node)
	return node


func _free_and_wait(node: Node) -> void:
	node.queue_free()
	await get_tree().process_frame


# ===========================================================================
# PASS
# ===========================================================================

func test_pass_screen_renders_all_thirty_track_levels() -> void:
	var screen := _spawn(PASS_SCENE)
	await get_tree().process_frame
	await get_tree().process_frame

	var tiles := screen.find_children("PassTile_*", "Button", true, false)
	_assert(tiles.size() == ContentDB.BP_TRACK.size(),
		"Pass screen rendered %d tiles, expected %d (one per BP_TRACK entry)"
		% [tiles.size(), ContentDB.BP_TRACK.size()])
	for lv in range(1, ContentDB.BP_MAX_LEVEL + 1):
		_assert(screen.find_child("PassTile_%d" % lv, true, false) != null,
			"no tile for level %d" % lv)

	await _free_and_wait(screen)
	_done("test_pass_screen_renders_all_thirty_track_levels")


func test_claiming_a_claim_now_reward_updates_state_and_view() -> void:
	# Arrange: a shard-type milestone with a known level, fully earned and not yet claimed.
	MetaState.xp = 0
	MetaState.bp_claimed.clear()
	var target: Dictionary = {}
	for e in ContentDB.BP_TRACK:
		if String((e as Dictionary).get("type", "")) == "shard":
			target = e
			break
	_assert(not target.is_empty(), "no shard-type BP_TRACK entry to test against")
	if target.is_empty():
		_done("test_claiming_a_claim_now_reward_updates_state_and_view")
		return
	var lv := int(target.get("lv", 0))
	var need := 0
	for i in range(1, lv + 1):
		need += ContentDB.bp_xp_for_level(i)
	MetaState.xp = need
	_assert(MetaState.bp_level() >= lv, "granting %d xp did not reach level %d" % [need, lv])

	var screen := _spawn(PASS_SCENE)
	await get_tree().process_frame
	await get_tree().process_frame
	var tile := screen.find_child("PassTile_%d" % lv, true, false) as Button
	_assert(tile != null, "no tile rendered for level %d" % lv)
	if tile == null:
		await _free_and_wait(screen)
		_done("test_claiming_a_claim_now_reward_updates_state_and_view")
		return
	_assert(not tile.disabled, "an earned, unclaimed shard reward's tile is disabled")

	var shards_before := MetaState.shard_pool
	tile.pressed.emit()
	await get_tree().process_frame

	_assert(MetaState.bp_claimed.has(lv), "pressing the tile did not mark level %d claimed" % lv)
	_assert(MetaState.shard_pool == shards_before + int(target.get("value", 0)),
		"shard pool went %d -> %d, expected +%d"
		% [shards_before, MetaState.shard_pool, int(target.get("value", 0))])

	var tile_after := screen.find_child("PassTile_%d" % lv, true, false) as Button
	_assert(tile_after != null and tile_after.disabled,
		"the tile still accepts a press after its reward was claimed")

	await _free_and_wait(screen)
	_done("test_claiming_a_claim_now_reward_updates_state_and_view")


## Regression guard for the exact failure named in this file's header comment #2.
func test_a_face_type_reward_never_becomes_claimable() -> void:
	MetaState.xp = 999999
	MetaState.bp_claimed.clear()
	var face_levels: Array[int] = []
	for e in ContentDB.BP_TRACK:
		if String((e as Dictionary).get("type", "")) == "face":
			face_levels.append(int((e as Dictionary).get("lv", 0)))
	_assert(not face_levels.is_empty(), "no face-type BP_TRACK entry to test against")

	var screen := _spawn(PASS_SCENE)
	await get_tree().process_frame
	await get_tree().process_frame
	for lv in face_levels:
		var tile := screen.find_child("PassTile_%d" % lv, true, false) as Button
		_assert(tile != null, "no tile rendered for face-type level %d" % lv)
		if tile != null:
			_assert(tile.disabled,
				"level %d's face reward tile is CLICKABLE — pressing it would fail silently, "
				% lv + "since claim_bp_reward() refuses 'face' rewards outright")
			var shards_before := MetaState.shard_pool
			tile.pressed.emit()
			await get_tree().process_frame
			_assert(not MetaState.bp_claimed.has(lv),
				"level %d got marked claimed even though its reward cannot be granted" % lv)
			_assert(MetaState.shard_pool == shards_before,
				"level %d's blocked tile changed the shard pool anyway" % lv)

	await _free_and_wait(screen)
	_done("test_a_face_type_reward_never_becomes_claimable")


# ===========================================================================
# UNLOCKS
# ===========================================================================

func test_unlocks_screen_renders_all_ten_ladder_rows() -> void:
	var screen := _spawn(UNLOCKS_SCENE)
	await get_tree().process_frame
	await get_tree().process_frame

	for def in ContentDB.UNLOCKS:
		var id := String((def as Dictionary).get("id", ""))
		_assert(screen.find_child("UnlockRow_" + id, true, false) != null,
			"no row rendered for unlock '%s'" % id)

	await _free_and_wait(screen)
	_done("test_unlocks_screen_renders_all_ten_ladder_rows")


func test_buying_an_available_unlock_spends_shards_and_flips_the_row() -> void:
	# Pick the first unlock the player does not already own, and fund exactly its cost. Skips
	# the four inert ids on purpose — buying one here would leave it permanently owned for the
	# rest of this file's run and quietly invalidate
	# test_the_no_effect_yet_tag_appears_on_exactly_the_four_inert_ids's "not owned" setup.
	var target: Dictionary = {}
	for def in ContentDB.UNLOCKS:
		var id := String((def as Dictionary).get("id", ""))
		if not MetaState.has_unlock(id) and not ContentDB.UNLOCKS_WITHOUT_EFFECT.has(id):
			target = def
			break
	_assert(not target.is_empty(), "every unlock is already owned; cannot test buying one")
	if target.is_empty():
		_done("test_buying_an_available_unlock_spends_shards_and_flips_the_row")
		return
	var id := String(target.get("id", ""))
	var cost := int(target.get("cost", 0))
	MetaState.shard_pool = cost

	var screen := _spawn(UNLOCKS_SCENE)
	await get_tree().process_frame
	await get_tree().process_frame
	var row := screen.find_child("UnlockRow_" + id, true, false)
	_assert(row != null, "no row for '%s'" % id)
	if row == null:
		await _free_and_wait(screen)
		_done("test_buying_an_available_unlock_spends_shards_and_flips_the_row")
		return
	var buy := row.find_child("BuyButton", true, false) as Button
	_assert(buy != null, "row '%s' has no BuyButton" % id)
	_assert(buy != null and not buy.disabled,
		"BuyButton for '%s' is disabled while the player can afford it" % id)

	buy.pressed.emit()
	await get_tree().process_frame

	_assert(MetaState.has_unlock(id), "buying '%s' did not register it as owned" % id)
	_assert(MetaState.shard_pool == 0,
		"shard pool is %d after spending exactly the cost, expected 0" % MetaState.shard_pool)

	var row_after := screen.find_child("UnlockRow_" + id, true, false)
	var buy_after := row_after.find_child("BuyButton", true, false) as Button if row_after else null
	_assert(buy_after != null and buy_after.disabled,
		"the row still offers to buy '%s' after it was bought" % id)
	_assert(buy_after != null and buy_after.text == "OWNED",
		"the bought row's button says '%s', expected 'OWNED'"
		% (buy_after.text if buy_after else "<missing>"))

	await _free_and_wait(screen)
	_done("test_buying_an_available_unlock_spends_shards_and_flips_the_row")


func test_the_no_effect_yet_tag_appears_on_exactly_the_four_inert_ids() -> void:
	for id in ContentDB.UNLOCKS_WITHOUT_EFFECT:
		if MetaState.has_unlock(id):
			MetaState.unlocks.erase(id)
	MetaState.shard_pool = 999999   # afford everything, so only OWNED can beat the inert tag

	var screen := _spawn(UNLOCKS_SCENE)
	await get_tree().process_frame
	await get_tree().process_frame

	for def in ContentDB.UNLOCKS:
		var id := String((def as Dictionary).get("id", ""))
		var row := screen.find_child("UnlockRow_" + id, true, false)
		if row == null:
			_assert(false, "no row for '%s'" % id)
			continue
		var has_tag := false
		for lbl in row.find_children("*", "Label", true, false):
			if String((lbl as Label).text) == "NO EFFECT YET":
				has_tag = true
				break
		var should_have_tag := ContentDB.UNLOCKS_WITHOUT_EFFECT.has(id)
		_assert(has_tag == should_have_tag,
			"unlock '%s': NO EFFECT YET tag present=%s, expected=%s"
			% [id, has_tag, should_have_tag])

	await _free_and_wait(screen)
	_done("test_the_no_effect_yet_tag_appears_on_exactly_the_four_inert_ids")


# ===========================================================================
# Cross-cutting
# ===========================================================================

## Mirrors t_vault.gd's own sweep: a Label reading a literal "null"/"nan"/"<null>" is a data leak
## the player sees directly, and no prior test in this file was checking label TEXT, only
## presence.
func test_no_label_leaks_a_null_or_nan_into_its_text() -> void:
	var leaks := ["<null>", "nan", "inf", "Nil", "null"]
	var seen := 0
	for scene_path in [PASS_SCENE, UNLOCKS_SCENE]:
		var screen := _spawn(scene_path)
		await get_tree().process_frame
		await get_tree().process_frame
		for node in screen.find_children("*", "Label", true, false):
			var text := String((node as Label).text)
			seen += 1
			for leak in leaks:
				_assert(not text.contains(leak),
					"a Label on '%s' reads '%s' — it leaks '%s' to the player"
					% [scene_path, text, leak])
		await _free_and_wait(screen)
	_assert(seen > 30, "only %d labels found across both screens; the sweep is not reaching them"
		% seen)
	_done("test_no_label_leaks_a_null_or_nan_into_its_text")
