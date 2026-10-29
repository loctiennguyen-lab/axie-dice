class_name BossIntro
extends Control
## Boss intro (design/ux/screens/52-boss-intro/spec.md, with Liam's overrides): the boss's 3D model
## stands in front of its plain Chimera painting for about 3.3 s, then hands off to combat.
## Always the full version (no seen flag). PRESENTATION ONLY: no RunState, no rules, no RNG.
##
## UI-05 b1: this screen is the camera reveal only. The BossIntroBand (BOSS tag, name, HP / SHELL / ENRAGE, rhythm)
## shows once, at the start of the fight over the arena (frame boss-intro--default, scenes/combat/ui5/U5BossBand.gd),
## where the real numbers exist; showing it here too would put the same band on screen twice in a row (Liam 29/10).
## The only control shown is the SkipHint "Click or [Space] to skip" bottom right (no Fight button).
## Motion: painting slow zoom, camera push-in, the boss roars (then idles), a rim light flash in time
## with the roar. With MetaState.reduce_flash on: no zoom, push-in, flash, shake or slide; it cuts in
## and holds 2.0 s.
## Skip: click anywhere, KeyBindings `boss_intro_skip` (Space / Enter) or Esc, all only after 300 ms
## (so the click that pressed the map node cannot skip it). Esc is consumed here so the in-run menu
## does not open on top of this screen. The overlay joins `ui3_modal` so map tooltips stay quiet under it.

signal finished

const GUARD_MS := 300
const HOLD_SEC := 3.1          # auto-advance, then OUT_SEC fade = about 3.3 s
const HOLD_SEC_RM := 2.0
const OUT_SEC := 0.2
const IN_SEC := 0.24
const ROAR_AT := 0.45
const FLASH_AT := 0.85         # about when the roar opens its mouth wide
const BG_ASPECT := 1673.0 / 2048.0
const _PanelParts := preload("res://scenes/combat/ui5/PanelParts.gd")
const MODEL_H := 4.0           # fitted model height in metres
const CAM_CLOSE_DIST := 13.0   # end of the push-in (was 11.2 before the UI-05 top band)
const FOV := 34.0

var data: Dictionary = {}
var elapsed_ms := 0
var is_skipped := false
var is_done := false
var skip_hint: HBoxContainer = null

var _t0 := -1
var _bg: TextureRect
var _vp_box: SubViewportContainer
var _vp: SubViewport
var _cam: Camera3D
var _pivot: Node3D
var _rim: OmniLight3D
var _flash: ColorRect
var _fade: ColorRect
var _player: AnimationPlayer = null
var _clips := {}
var _flash_on := true
var _tw: Tween = null


## Prepares the screen for a boss key (BossIntroData). Call before adding to the tree.
## False = no art for this boss: the caller skips the intro.
func setup(boss_key: String) -> bool:
	data = BossIntroData.info(boss_key)
	return not data.is_empty()


func _ready() -> void:
	if data.is_empty():
		return
	_flash_on = not (MetaState.reduce_flash or UI3Motion.reduced())
	theme = UI3Theme.get_theme()
	add_to_group("ui3_modal")
	UI3Tooltip.hide_all(get_tree())
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	_build_bg()
	_build_stage()
	_build_skip_hint()
	_flash = ColorRect.new()
	_flash.name = "RoarFlash"
	_flash.color = Color(UI3Theme.color("text"), 0.0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_flash)
	_fade = ColorRect.new()
	_fade.name = "Fade"
	_fade.color = UI3Theme.color("bg")
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_fade)
	resized.connect(_layout)
	gui_input.connect(_on_gui_input)
	_fade.color.a = 1.0   # black while the first frames (model + painting upload) hitch
	_layout()
	grab_focus.call_deferred()
	_start_after_warmup()


## The first frames after loading a model and a 2048 px painting can take hundreds of ms. Run the timeline
## and the skip guard from the third frame on, so the push-in is not eaten by the hitch (the screen is black until then).
func _start_after_warmup() -> void:
	for i in 3:
		await get_tree().process_frame
	if is_done or not is_inside_tree():
		return
	_t0 = Time.get_ticks_msec()
	_play()


# ---------------------------------------------------------------- build

func _build_bg() -> void:
	var clip := Control.new()
	clip.name = "BgClip"
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(clip)
	_bg = TextureRect.new()
	_bg.name = "Painting"
	_bg.texture = load(String(data["bg_path"])) as Texture2D
	_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg.stretch_mode = TextureRect.STRETCH_SCALE
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.add_child(_bg)


func _build_stage() -> void:
	_vp_box = SubViewportContainer.new()
	_vp_box.name = "Stage"
	_vp_box.stretch = true
	_vp_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vp_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_vp_box)
	_vp = SubViewport.new()
	_vp.transparent_bg = true
	_vp.own_world_3d = true
	_vp.msaa_3d = Viewport.MSAA_2X
	_vp_box.add_child(_vp)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.64, 0.72)
	env.ambient_light_energy = 0.8
	var we := WorldEnvironment.new()
	we.environment = env
	_vp.add_child(we)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-35, 30, 0)
	key.light_energy = 1.3
	_vp.add_child(key)
	_rim = OmniLight3D.new()
	_rim.position = Vector3(-2.6, 3.2, -2.2)   # behind and to the side: reads as a rim on the silhouette
	_rim.omni_range = 12.0
	_rim.light_color = Color(1.0, 0.82, 0.55)
	_rim.light_energy = 0.9
	_vp.add_child(_rim)
	_cam = Camera3D.new()
	_cam.fov = FOV
	_vp.add_child(_cam)
	_cam.current = true
	_pivot = Node3D.new()
	_pivot.name = "BossPivot"
	_vp.add_child(_pivot)
	_load_model()


func _load_model() -> void:
	var reg := MonsterArt.resolve(String(data["key"]), true)
	var model: Node3D = null
	if String(reg.get("kind", "")) == "glb" and ResourceLoader.exists(String(reg.get("path", ""))):
		var packed := load(String(reg["path"])) as PackedScene
		if packed != null:
			model = packed.instantiate() as Node3D
	if model == null:
		# No 3D model (sprite-only boss): the flat Chimera sprite, same framing.
		var tex := MonsterArt.texture_for(String(data["key"]), true)
		if tex == null:
			return
		var spr := Sprite3D.new()
		spr.texture = tex
		spr.pixel_size = MODEL_H / float(tex.get_height())
		spr.centered = true
		spr.position.y = MODEL_H * 0.5
		spr.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		_pivot.add_child(spr)
		return
	_pivot.add_child(model)
	model.rotation_degrees.y = float(reg.get("intro_facing_deg", reg.get("facing_deg", 0.0)))   # intro camera differs from combat: optional own angle
	_fit(model)
	if VenomPool.wants(reg):
		VenomPool.attach(model, MetaState.reduce_flash)
	_setup_anims(model, reg)


func _fit(model: Node3D) -> void:
	var box := CombatStage3D._model_aabb(model)
	var raw := CombatStage3D._visual_bounds(model)
	if box.size.y < 0.05 or (raw.y - raw.x) > box.size.y * 20.0:
		if raw.y - raw.x > 0.001:
			var f := MODEL_H / (raw.y - raw.x)
			model.scale = Vector3.ONE * f
			model.position = Vector3(0.0, -raw.x * f, 0.0)
		return
	var f2 := MODEL_H / box.size.y
	model.scale = Vector3.ONE * f2
	var c := box.get_center()
	model.position = Vector3(-c.x * f2, -box.position.y * f2, -c.z * f2)


## Per-instance clip copies (idle loops, roar plays once). Roar falls back to cast, then attack.
func _setup_anims(model: Node3D, reg: Dictionary) -> void:
	var player := model.get_node_or_null("Animations") as AnimationPlayer
	if player == null:
		for n in CombatStage3D._descendants(model):
			if n is AnimationPlayer:
				player = n as AnimationPlayer
				break
	if player == null:
		return
	var cfg: Dictionary = reg.get("anims", {})
	var roar_slot := ""
	for s in ["roar", "cast", "attack"]:
		if cfg.has(s) and player.has_animation(String(cfg[s])):
			roar_slot = s
			break
	var lib := AnimationLibrary.new()
	for slot_name in ["idle", roar_slot]:
		if slot_name == "" or not cfg.has(slot_name) or not player.has_animation(String(cfg[slot_name])):
			continue
		var clip := String(cfg[slot_name])
		if lib.has_animation(clip):
			continue
		var copy := player.get_animation(clip).duplicate() as Animation
		copy.loop_mode = Animation.LOOP_LINEAR if slot_name == "idle" else Animation.LOOP_NONE
		lib.add_animation(clip, copy)
	if lib.get_animation_list().is_empty():
		return
	for ln in player.get_animation_library_list():
		player.remove_animation_library(ln)
	player.add_animation_library("", lib)
	_player = player
	_clips = {"idle": String(cfg.get("idle", "")),
		"roar": String(cfg.get(roar_slot, "")) if roar_slot != "" else ""}
	if String(_clips["idle"]) != "" and player.has_animation(String(_clips["idle"])):
		player.play(String(_clips["idle"]))


## SkipHint (bottom right, on the view): "Click or" [Space] "to skip". Only the Space key is shown (Liam 28/10).
func _build_skip_hint() -> void:
	skip_hint = HBoxContainer.new()
	skip_hint.name = "SkipHint"
	skip_hint.add_theme_constant_override("separation", UI3Theme.space("8"))
	skip_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skip_hint.add_child(_PanelParts.on_view(_PanelParts.text(tr("Click or"))))
	var cap := UI3.keycap(KeyBindings.key_name(KEY_SPACE), true)
	cap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	skip_hint.add_child(cap)
	skip_hint.add_child(_PanelParts.on_view(_PanelParts.text(tr("to skip"))))
	skip_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	skip_hint.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	skip_hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var m := UI3Theme.space("screen")
	skip_hint.offset_right = -m
	skip_hint.offset_bottom = -m
	skip_hint.offset_left = -m
	skip_hint.offset_top = -m
	add_child(skip_hint)


## Painting crop pinned to about 23-92% of the image height (the boss sits in 39-78%); never a centre crop.
func _layout() -> void:
	if _bg == null:
		return
	var w := size.x
	var h := w * BG_ASPECT
	if h < size.y:
		h = size.y
		w = h / BG_ASPECT
	_bg.size = Vector2(w, h)
	var top := clampf(h * 0.23, 0.0, maxf(h - size.y, 0.0))
	_bg.position = Vector2((size.x - w) * 0.5, -top)
	_bg.pivot_offset = Vector2(w * 0.5, top + size.y * 0.6)


# ---------------------------------------------------------------- motion

## Camera for push-in progress t (0 = wide, 1 = close).
func _cam_set(t: float) -> void:
	# UI-05: the close end stays far enough back that the head clears the BossIntroBand by 24 px (keep-clear box).
	var dist := lerpf(16.5, CAM_CLOSE_DIST, t)
	var look_y := lerpf(1.7, 1.45, t)
	_cam.position = Vector3(lerpf(0.5, 0.0, t), look_y + 0.55, dist)
	_cam.look_at(Vector3(0.0, look_y, 0.0))
	_cam.v_offset = 1.45   # slides the frame down so the head clears the UI-05 top band (feet land about 88% down)


func _play() -> void:
	_pivot.rotation_degrees.y = -20.0
	if not _flash_on:
		_cam_set(0.8)
		_pivot.rotation_degrees.y = -8.0
		_fade.color.a = 0.0
		_start_roar()
		_tw = create_tween()
		_tw.tween_interval(HOLD_SEC_RM)
		_tw.tween_callback(_finish)
		return
	_cam_set(0.0)
	_fade.color.a = 1.0
	_tw = create_tween().set_parallel(true)
	_tw.tween_property(_fade, "color:a", 0.0, IN_SEC)
	# Painting: slow zoom for the whole beat.
	_tw.tween_property(_bg, "scale", Vector2.ONE * 1.14, HOLD_SEC + OUT_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Camera push-in: fast start, long settle.
	_tw.tween_method(_cam_set, 0.0, 1.0, 1.9).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT).set_delay(0.1)
	_tw.tween_property(_pivot, "rotation_degrees:y", -8.0, 2.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tw.tween_callback(_start_roar).set_delay(ROAR_AT)
	_tw.tween_callback(_roar_flash).set_delay(FLASH_AT)
	_tw.tween_callback(_finish).set_delay(HOLD_SEC)


func _start_roar() -> void:
	if _player == null or String(_clips.get("roar", "")) == "":
		return
	_player.play(String(_clips["roar"]), 0.1)
	if String(_clips.get("idle", "")) != "":
		_player.queue(String(_clips["idle"]))


## Rim light surge, a short cream screen flash and a small camera jolt, in time with the roar.
## Not run at all with Reduce flashing.
func _roar_flash() -> void:
	if not _flash_on or is_done:
		return
	var t := create_tween()
	t.tween_property(_rim, "light_energy", 9.0, 0.08)
	t.tween_property(_rim, "light_energy", 1.6, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var f := create_tween()
	f.tween_property(_flash, "color:a", 0.28, 0.06)
	f.tween_property(_flash, "color:a", 0.0, 0.2)
	var base := _vp_box.position
	var s := create_tween()
	for i in 4:
		var a := 10.0 * (1.0 - float(i) / 4.0)
		s.tween_property(_vp_box, "position", base + Vector2(a if i % 2 == 0 else -a, -a * 0.5), 0.04)
	s.tween_property(_vp_box, "position", base, 0.04)


# ---------------------------------------------------------------- skip / finish

func _process(_delta: float) -> void:
	if _t0 >= 0:
		elapsed_ms = Time.get_ticks_msec() - _t0


## True once the 300 ms guard has passed.
func can_skip() -> bool:
	return _t0 >= 0 and Time.get_ticks_msec() - _t0 >= GUARD_MS


## Fight / click / key. Ignored inside the guard window. Jumps to the 200 ms out-fade (a cut with Reduce flashing).
func skip() -> void:
	if is_skipped or is_done or not can_skip():
		return
	is_skipped = true
	_finish()


func _finish() -> void:
	if is_done:
		return
	is_done = true
	if _tw != null and _tw.is_valid():
		_tw.kill()
	if not _flash_on:
		finished.emit()
		return
	var t := create_tween()
	t.tween_property(_fade, "color:a", 1.0, OUT_SEC)
	t.tween_callback(func() -> void: finished.emit())


func _on_gui_input(ev: InputEvent) -> void:
	var mb := ev as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		skip()
		accept_event()


func _input(ev: InputEvent) -> void:
	var k := ev as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	if ev.is_action_pressed(&"boss_intro_skip") or k.keycode == KEY_ESCAPE:
		skip()
		get_viewport().set_input_as_handled()   # Esc must not open the in-run menu over this screen
