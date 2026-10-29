class_name U5TurnBanner
extends Control
## UI-05 b1 lane E: "Your turn" / "Enemy turn" band (data-name TurnBanner, moment-turn-banner.html).
## Full width, size.banner_h high at y 200, banner_player / banner_enemy fill, text_hero 56. Slides in 240 EXPO OUT,
## holds 500, slides out 240 QUAD IN; the label punches 0.8 -> 1.08 -> 1. Numbers: motion rows
## turn_banner_player / turn_banner_enemy. Click or Space ends it. A click is only held during the first
## block_input_ms (240), after that it also reaches the game. On the "Your turn" band Space and every combat key
## (End turn, Reroll, 1-5, Undo, Hold, Aid) only skip the band for its whole duration: they never act on the fight
## while the intents are still hidden (Liam 29/10). Only the left / right mouse button skips (not the wheel). Nothing
## is read while a modal or the pause menu is open. Frees itself when done.

var run: UI3Motion.Timeline
var label: Label
var player := false
var _t0 := 0
var _block_ms := 240
var _on_done := Callable()


static func moment_id(is_player: bool) -> String:
	return "turn_banner_player" if is_player else "turn_banner_enemy"


## Build the band under `parent` (a full-rect Control) and play it. on_done runs once the band is gone (or skipped).
static func show_on(parent: Control, is_player: bool, on_done := Callable()) -> U5TurnBanner:
	var id := moment_id(is_player)
	var row: Dictionary = UI3Motion.table().get(id, {})
	var b := U5TurnBanner.new()
	b.name = "TurnBanner"
	b.player = is_player
	b._on_done = on_done
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.set_anchors_preset(Control.PRESET_TOP_WIDE)
	var y := float(row.get("y", 200))
	b.offset_top = y
	b.offset_bottom = y + float(UI3Theme.size_of("banner_h"))
	var plate := U5Moments.band(String(row.get("band_color", "banner_player" if is_player else "banner_enemy")), 0.0,
		float(UI3Theme.size_of("banner_h")), "Band")
	plate.set_anchors_preset(Control.PRESET_FULL_RECT)
	b.add_child(plate)
	b.label = U5Moments.band_label(plate, TranslationServer.translate("Your turn" if is_player else "Enemy turn"),
		String(row.get("size_token", "text_hero")), String(row.get("text_color", "text")),
		String(row.get("shadow_color", "plate_ink")))
	b._block_ms = int(row.get("block_input_ms", 240))
	b.modulate.a = 0.0
	parent.add_child(b)
	b._t0 = Time.get_ticks_msec()
	b.run = UI3Motion.play_timeline(id, {"band": b, "label": b.label}, {"host": b, "on_done": b._done})
	return b


## End the band now (a skip, or a new turn banner replaces it: then run_on_done = false drops its callback).
func finish(run_on_done := true) -> void:
	if not run_on_done:
		_on_done = Callable()
	if run != null and not run.done:
		run.skip()
	elif not is_queued_for_deletion():
		_done()


func _done() -> void:
	visible = false
	name = "TurnBannerDone"   # the next band takes the data-name at once
	if not is_queued_for_deletion():
		queue_free()
	if _on_done.is_valid():
		var cb := _on_done
		_on_done = Callable()
		cb.call()


## A left / right click (not the wheel, not a release).
static func skip_click(event: InputEvent) -> bool:
	var mb := event as InputEventMouseButton
	return mb != null and mb.pressed and (mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_RIGHT)


## Space, or a key bound to a combat action (End turn, Reroll, Undo, Hold, Aid, die 1-5). Not Esc (the pause menu)
## and not Inspect (it only shows information).
static func combat_key(event: InputEvent) -> bool:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return false
	if k.keycode == KEY_SPACE:
		return true
	KeyBindings.ensure()
	for a in [KeyBindings.COMBAT_END_TURN, KeyBindings.COMBAT_REROLL, KeyBindings.COMBAT_UNDO, KeyBindings.COMBAT_HOLD,
			KeyBindings.COMBAT_AID]:
		if event.is_action_pressed(a):
			return true
	for a in KeyBindings.DIE_ACTIONS:
		if event.is_action_pressed(a):
			return true
	return false


## True while a UI3 modal or the combat pause menu is open above the moments: the bands leave the input alone then.
static func input_blocked(n: Node) -> bool:
	if n == null or not n.is_inside_tree():
		return true
	if UI3Tooltip.modal_open(n.get_tree()):
		return true
	var p := n.get_parent()
	while p != null:
		if p is CombatView:
			return (p as CombatView).pause_menu_open()
		p = p.get_parent()
	return false


func _input(event: InputEvent) -> void:
	if run == null or run.done or input_blocked(self):
		return
	var mouse := skip_click(event)
	var space := false
	if event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		space = combat_key(event) if player else (event as InputEventKey).keycode == KEY_SPACE
	if not (mouse or space):
		return
	var held := Time.get_ticks_msec() - _t0 < _block_ms
	finish()
	if (held or (space and player)) and is_inside_tree():
		get_viewport().set_input_as_handled()
