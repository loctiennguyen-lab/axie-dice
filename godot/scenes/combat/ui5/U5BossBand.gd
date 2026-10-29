class_name U5BossBand
extends Control
## UI-05 b1 integration: the boss intro band at the START of a boss fight, over the arena (frame boss-intro--default,
## design/handoffs/ui-05-figma/round-1/ui05-combat-panels.html). Lane D's BossIntroBand (BOSS tag, name, facts,
## rhythm) pinned 24 px from the top, lane A's SkipHint "Click or [Space] to skip" bottom right. Motion row
## boss_intro_band (motion_ui3.json): unfold 210, hold 1600, out 210; Reduce motion = alpha only.
## Facts are the boss HUD numbers once the fight is built: HP, SHELL (when the boss has one), ENRAGE (boss clock),
## "2 phases" for a two-phase boss; the rhythm row for rhythm bosses (Prep current on turn 1).
## A click, Space or the End turn key ends it, and that press never reaches the fight (no die picked, no turn ended).
## UI only: reads the engine, never changes it. Shown by U5Moments.turn_banner in front of the first Your turn band.

const BandUi := preload("res://scenes/run_map/ui5/BossIntroBand.gd")
const MOMENT := "boss_intro_band"

var run: UI3Motion.Timeline
var band: PanelContainer
var hint: Control
var _on_done := Callable()
var _skip_early := false   ## a skip during the warm-up frames: the band never plays
var _warm_frames := 0

const WARMUP_MAX := 30


## Band data for the live boss of `v` ({} when there is none). Same words as the boss HUD (HudKit.clock_tab).
static func data_for(v: CombatView) -> Dictionary:
	if v == null or v._combat == null:
		return {}
	var c: CombatEngine = v._combat
	var boss: Unit = null
	for e in c.enemies:
		if e.is_boss and e.hp > 0:
			boss = e
			break
	if boss == null:
		return {}
	var hs: Dictionary = c.hud_state()
	var facts: Array = [{"text": TranslationServer.translate("HP %d") % boss.max_hp, "node": "Hp"}]
	var shell_max := int(boss.custom_state.get("shell_max", 0))
	if shell_max > 0:
		facts.append({"text": TranslationServer.translate("SHELL %d") % shell_max, "color": "shell",
			"icon": UI3.icon("face_shield"), "node": "Shell"})
	var clock: Dictionary = hs.get("clock", {})
	if bool(clock.get("active", false)) and not bool(hs.get("newcomer", false)):
		var tab := HudKit.clock_tab(clock, int(hs.get("turn", c.turn)), 0)
		if not tab.is_empty():
			facts.append({"text": String(tab.get("text", "")), "color": "attrition", "icon": HudKit.icon("boss-clock"),
				"sub": String(tab.get("right", "")), "node": "Enrage"})
	if BossIntroData.phase_count(boss.key) > 1:
		facts.append({"text": TranslationServer.translate("%d phases") % BossIntroData.phase_count(boss.key),
			"color": "accent", "node": "PhaseChip"})
	var steps: Array = []
	var now := -1
	var st: Dictionary = c.boss_rhythm_state(boss)
	if not st.is_empty():
		var ids := ["prep", "strike", "hollow"]
		steps = [TranslationServer.translate("Prep"), TranslationServer.translate("Strike"),
			TranslationServer.translate("Hollow")]
		now = ids.find(String(st.get("phase", "")))
	var nm := String(BossIntroData.info(boss.key).get("name", ""))
	return {"name": nm if nm != "" else boss.n, "tag_word": TranslationServer.translate("BOSS"), "facts": facts,
		"rhythm": steps, "rhythm_now": now}


## Build the band under `parent` (a full-rect Control) and play it. on_done runs once it is gone (or skipped).
static func show_on(parent: Control, d: Dictionary, on_done := Callable()) -> U5BossBand:
	var b := U5BossBand.new()
	b.name = "BossBand"
	b._on_done = on_done
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.set_anchors_preset(Control.PRESET_FULL_RECT)
	b.theme = UI3Theme.get_theme()
	b.band = BandUi.new()
	b.band.setup(d)
	b.band.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	b.band.offset_top = UI3Theme.space("screen")
	b.band.grow_vertical = Control.GROW_DIRECTION_END
	b.band.resized.connect(func() -> void: b.band.pivot_offset = b.band.size * 0.5)   # unfolds from its centre line
	b.add_child(b.band)
	var h := Ui5SkipHint.new()
	h.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	h.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	h.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var m := UI3Theme.space("screen")
	h.offset_right = -m
	h.offset_bottom = -m
	h.offset_left = -m
	h.offset_top = -m
	b.hint = h
	b.add_child(h)
	b.band.modulate.a = 0.0
	h.modulate.a = 0.0
	parent.add_child(b)
	return b


## A boss fight's first frames load the arena and the boss model and can take hundreds of ms; a tween started
## then would jump past the band. It starts once the frames are short again (3rd frame on, at most WARMUP_MAX).
func _process(delta: float) -> void:
	if run != null:
		set_process(false)
		return
	_warm_frames += 1
	if _skip_early:
		set_process(false)
		_done()
		return
	if (_warm_frames >= 3 and delta < 0.1) or _warm_frames >= WARMUP_MAX:
		set_process(false)
		run = UI3Motion.play_timeline(MOMENT, {"band": band, "hint": hint}, {"host": self, "on_done": _done})


## True from creation until the band is gone (also during the warm-up frames).
func showing() -> bool:
	return not is_queued_for_deletion() and visible and (run == null or not run.done)


## Seconds the band stays up (Reduce motion: the reduced timings).
static func duration_sec() -> float:
	return UI3Motion.timeline_sec(MOMENT, UI3Motion.reduced())


## End the band now (a skip). run_on_done = false drops its callback.
func finish(run_on_done := true) -> void:
	if not run_on_done:
		_on_done = Callable()
	if run == null:
		_skip_early = true   # still warming up: _process ends it on its next frame
		if not run_on_done:
			_done()
	elif not run.done:
		run.skip()
	elif not is_queued_for_deletion():
		_done()


func _done() -> void:
	visible = false
	name = "BossBandDone"
	if not is_queued_for_deletion():
		queue_free()
	if _on_done.is_valid():
		var cb := _on_done
		_on_done = Callable()
		cb.call()


func _input(event: InputEvent) -> void:
	if not showing() or _skip_early:
		return
	var press := event is InputEventMouseButton and (event as InputEventMouseButton).pressed
	if not press and event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		press = (event as InputEventKey).keycode == KEY_SPACE
		if not press:
			KeyBindings.ensure()
			press = event.is_action_pressed(KeyBindings.COMBAT_END_TURN)
	if not press:
		return
	if is_inside_tree():
		get_viewport().set_input_as_handled()   # the skip press never picks a die or ends the turn
	finish()
