extends Node
## Manual VISUAL QA capture for the reward/event/shop/treasure loop (checklist step 4 —
## design/gdd/godot-port-rule-spec.md §9). NOT part of the automated regression suite — see
## qa_anim_capture.gd's header for why (Visual/Feel evidence is ADVISORY per
## coding-standards.md's Test Evidence table, and this MUST run non-headless: --headless's
## dummy rasterizer returns no texture, same limitation t_stage3d_facing.gd documents).
##
## Drives RunState/RunMapController the same white-box way qa_anim_capture.gd drives
## CombatView — direct method calls / signal emission on real nodes instead of simulated
## mouse input — then screenshots the actual rendered window at each step:
##   1. fresh map render
##   2. event node: prompt -> chosen option's result message -> back on map
##   3. shop node: item list -> after buying one item -> after "DONE"
##   4. treasure node: auto-granted reward reveal -> back on map
##   5. post-combat reward overlay (3 cards) -> after taking one
##
## Run: /path/to/Godot --path godot tests/qa_reward_loop_capture.tscn
## Do not point this at a terminal/window the user (or another agent) is actively using.

const _EVIDENCE_DIR := "/Users/loc.tien.nguyen/my-game/production/qa/evidence"
const _TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
const _SEED := 555001

var _shot_index := 0
var _map: Node


## Borrows the player's real save file and puts it back byte for byte. This capture drives real
## run state — and loading `Result.tscn` alone is enough, because `ResultView._ready()` calls
## `RunState.end_run()`, which banks shards and XP into `MetaState`. See `save_guard.gd`.
var _guard := SaveGuard.new()

func _ready() -> void:
	_guard.capture()
	var tree := get_tree()
	DirAccess.make_dir_recursive_absolute(_EVIDENCE_DIR)

	RunState.start_new_run(_SEED, _TEAM, "short", 0, false)
	RunState.shards_this_run = 200   # enough to afford every shop item in this pass

	await _load_map()
	await _settle()
	_shot("01_map_start")

	await _run_event_flow()
	await _run_shop_flow()
	await _run_treasure_flow()
	_free_map()

	await _run_post_combat_reward_flow()

	print("qa_reward_loop_capture: done, %d frame(s) written to %s" % [_shot_index, _EVIDENCE_DIR])
	_guard.restore()
	tree.quit(0)


# ===========================================================================
# Map instantiation helpers
# ===========================================================================

func _load_map() -> void:
	var scene: Node = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(scene)
	_map = scene
	await _settle()


func _free_map() -> void:
	if is_instance_valid(_map):
		_map.queue_free()
	_map = null


func _settle(frames: int = 2) -> void:
	for i in frames:
		await get_tree().process_frame


# ===========================================================================
# Flow drivers — each forces RunState.enter_node() directly (bypassing the graph's own
# reachability gate, same white-box liberty qa_anim_capture.gd takes with CombatView's
# click handlers) so every node type is reachable regardless of this seed's actual graph
# shape, then interacts with the resulting overlay via real Button.pressed signals.
# ===========================================================================

func _run_event_flow() -> void:
	var node_id := _first_node_id_of_type("event")
	if node_id == "":
		push_warning("qa_reward_loop_capture: no 'event' node in this seed's graph")
		return
	RunState.enter_node(node_id, "event")
	await _settle()
	_shot("02_event_prompt")
	if _press_prefix("CHOOSE"):
		await _settle()
		_shot("03_event_result")
		_press("CONTINUE")
		await _settle()
		_shot("04_event_back_on_map")


func _run_shop_flow() -> void:
	var node_id := _first_node_id_of_type("shop")
	if node_id == "":
		push_warning("qa_reward_loop_capture: no 'shop' node in this seed's graph")
		return
	RunState.enter_node(node_id, "shop")
	await _settle()
	_shot("05_shop_open")
	if _press_prefix("BUY"):
		await _settle()
		_shot("06_shop_after_buy")
	_press("DONE")
	await _settle()
	_shot("07_shop_back_on_map")


func _run_treasure_flow() -> void:
	var node_id := _first_node_id_of_type("treasure")
	if node_id == "":
		push_warning("qa_reward_loop_capture: no 'treasure' node in this seed's graph")
		return
	RunState.enter_node(node_id, "treasure")
	await _settle()
	_shot("08_treasure_reveal")
	_press("CONTINUE")
	await _settle()
	_shot("09_treasure_back_on_map")


## Fabricates a won-combat result directly (no real CombatEngine run needed — see
## RunState.apply_combat_result()) so RunState.pending_rewards is populated before RunMap.tscn
## is instantiated again; its _ready() -> _maybe_show_pending_reward() then shows the overlay
## immediately, exactly as it would right after CombatView._finish()'s win branch.
func _run_post_combat_reward_flow() -> void:
	RunState.current_node_id = String(RunState.map_graph.get("start_node_id", "n1"))
	RunState.apply_combat_result({
		"won": true, "shards_earned": 25, "kind": "battle", "pw": RunState.power_level,
	})
	await _load_map()
	_shot("10_post_combat_reward")
	if _press_prefix("TAKE"):
		await _settle()
		_shot("11_reward_taken_map")
	_free_map()


func _first_node_id_of_type(node_type: String) -> String:
	for row in (RunState.map_graph.get("rows", []) as Array):
		for n in (row as Array):
			if String((n as Dictionary).get("node_type", "")) == node_type:
				return String((n as Dictionary).get("id", ""))
	return ""


# ===========================================================================
# Overlay interaction — real Button nodes built by RunMapController's procedural overlay
# UI; found by tree walk (there is no unique_name_in_owner path since card count varies).
# ===========================================================================

func _overlay_buttons() -> Array:
	var out: Array = []
	if is_instance_valid(_map):
		_collect_buttons(_map, out)
	return out


func _collect_buttons(node: Node, out: Array) -> void:
	if node is Button:
		out.append(node)
	for c in node.get_children():
		_collect_buttons(c, out)


func _press(text_exact: String) -> bool:
	for b in _overlay_buttons():
		if String((b as Button).text) == text_exact:
			(b as Button).emit_signal("pressed")
			return true
	return false


func _press_prefix(prefix: String) -> bool:
	for b in _overlay_buttons():
		if String((b as Button).text).begins_with(prefix):
			(b as Button).emit_signal("pressed")
			return true
	return false


func _shot(tag: String) -> void:
	var vp := get_viewport()
	if vp == null:
		return
	var img := vp.get_texture().get_image()
	var path := "%s/%s_reward-loop_%s.png" % [_EVIDENCE_DIR, _today(), tag]
	img.save_png(path)
	_shot_index += 1
	print("qa_reward_loop_capture: saved %s" % path)


## Today, as `YYYY-MM-DD`, for naming the files this capture writes.
##
## The date used to be typed into the filename by hand. That makes a screenshot LIE the moment
## the capture is re-run: the picture is regenerated, the name still says the day it was first
## written, and anyone reading the folder — or a report linking to it — concludes the evidence is
## stale when it is current. Stamping it at run time means a filename can only ever be right.
func _today() -> String:
	var d := Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d" % [int(d["year"]), int(d["month"]), int(d["day"])]
