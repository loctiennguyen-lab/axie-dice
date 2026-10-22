class_name AnchorFx
extends Control
## Lane AU2 job 4: the Anchor AWAKENING moment (design/ux/anchor-mvp.md section 4). Blocks input, scrim 80%, the Anchor card
## big in the middle, frame turns to the double `anchor_awake` frame, two house-coloured waves, shake. At most 2.5 s
## (1.6 s with Reduce flashing: no shake, no waves, fades only). Click / Space / Enter / A / Esc jump to the end.
## The animation only SHOWS what RunState already did: it never changes a result.

signal finished

## Latched when the engine says the Anchor woke (EventBus.anchor_awakened) and no moment has played yet this run.
## RunMapController plays it on the next map beat; the Core-pick path plays it right after taking the card.
static var pending := ""
static var played_run := ""            ## "<seed>:<anchor>" already shown (once per run; resuming a run does not replay)
static var log: Array = []             ## test hook: "play", "skip", "end"

var running := false
var skipped := false
var anchor_id := ""
var card_frame: PanelContainer = null
var _card: Control = null
var _waves: Control = null
var _tw: Tween = null
var _wave_r := [-1.0, -1.0]
var _fly_to := Rect2()


static func run_key() -> String:
	return "%d:%s" % [int(RunState.get("_core_base_seed")), AnchorAdapter.current_id()]


## Marks the pending moment as shown and returns true when there is one to play (and the run has not seen it).
static func take_pending() -> bool:
	if pending == "":
		return false
	var key := run_key()
	pending = ""
	if played_run == key:
		return false
	played_run = key
	return true


static func arm(id: String) -> void:
	pending = id


static func duration() -> float:
	var t := UI3Gacha.timing()
	return float(t.get("awaken_reduced_sec", 1.6)) if CombatView.flashes_suppressed() else float(t.get("awaken_sec", 2.5))


## Builds and starts the moment under `parent`. `extra_line` = merged Pair line ("PAIR: X . MUTATION: Y"), "" = plain.
## `fly_to` = global rect of the HUD Anchor tile (Rect2() = just fade).
static func play(parent: Node, id: String, extra_line := "", fly_to := Rect2()) -> AnchorFx:
	var fx := AnchorFx.new()
	fx.anchor_id = id
	fx.name = "AnchorAwaken"
	fx._fly_to = fly_to
	fx.theme = UI3Theme.get_theme()
	fx.z_index = 60
	fx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fx.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(fx)
	fx._build(extra_line)
	log.append("play")
	UI3Gacha.play_sfx(fx, "awaken")
	if UI3Gacha.is_instant():
		fx._show_final()
		fx.log.append("end")
		fx.queue_free()   # instant mode (tests / headless): content is built for this frame only, never blocks input
		return fx
	fx.running = true
	fx._animate()   # coroutine: waits one frame for the containers to size, then starts the tween
	return fx


func _build(extra_line: String) -> void:
	var house := AnchorAdapter.house_id(anchor_id)
	var hcol := AnchorAdapter.house_color(house)
	var gold := UI3Theme.color("anchor_awake")
	var scrim := ColorRect.new()
	scrim.name = "AwakenScrim"
	scrim.color = Color(UI3Theme.color("bg"), 0.8)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)
	_waves = Control.new()
	_waves.name = "AwakenWaves"
	_waves.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_waves.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_waves.draw.connect(func() -> void:
		var c := _waves.size * 0.5
		if float(_wave_r[0]) > 0.0:
			_waves.draw_arc(c, float(_wave_r[0]), 0.0, TAU, 96, hcol, 4.0)
		if float(_wave_r[1]) > 0.0:
			_waves.draw_arc(c, float(_wave_r[1]), 0.0, TAU, 96, gold, 4.0))
	add_child(_waves)
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cc)
	_card = VBoxContainer.new()
	_card.name = "AwakenColumn"
	_card.add_theme_constant_override("separation", 12)
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cc.add_child(_card)
	var tag := UI3.label(TranslationServer.translate("ANCHOR AWAKENED"), "LabelDisplay")
	tag.name = "AwakenTag"
	tag.add_theme_font_size_override("font_size", 24)
	tag.add_theme_color_override("font_color", gold)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(tag)
	var row := CenterContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(row)
	card_frame = PanelContainer.new()
	card_frame.name = "AnchorCard"
	card_frame.custom_minimum_size = Vector2(280, 280)
	card_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_frame.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("panel_raised"), UI3Theme.radius("l"), 4, hcol, Vector4(16, 16, 16, 16)))
	row.add_child(card_frame)
	var cv := VBoxContainer.new()
	cv.alignment = BoxContainer.ALIGNMENT_CENTER
	cv.add_theme_constant_override("separation", 12)
	cv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_frame.add_child(cv)
	var ic := TextureRect.new()
	ic.name = "HouseGlyph"
	ic.texture = UI3.icon(AnchorAdapter.house_icon(house))
	ic.custom_minimum_size = Vector2(120, 120)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cv.add_child(ic)
	var nm := UI3.label(AnchorAdapter.name_of(anchor_id), "LabelScreenTitle")
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cv.add_child(nm)
	var aw := TextureRect.new()
	aw.name = "AwakenGlyph"
	aw.texture = UI3.icon(CorePanel.AWAKEN_ICON)
	aw.custom_minimum_size = Vector2(56, 56)
	aw.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	aw.position = Vector2(280 - 16 - 56 - 4, 4)   # top-right corner; a plain Control holder so the PanelContainer does not stretch it over the name
	aw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aw.visible = false
	var holder := Control.new()
	holder.name = "AwakenGlyphHolder"
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(aw)
	card_frame.add_child(holder)
	var an := UI3.label(AnchorAdapter.awaken_name(anchor_id), "LabelScreenTitle")
	an.name = "AwakenName"
	an.add_theme_color_override("font_color", gold)
	an.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	an.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(an)
	var ar := UI3.label(AnchorAdapter.awaken_rule(anchor_id), "LabelMuted")
	ar.name = "AwakenRule"
	ar.add_theme_font_size_override("font_size", 24)
	ar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ar.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ar.custom_minimum_size.x = 760
	ar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(ar)
	var strip := UI3.label(extra_line if extra_line != "" else "%s %d/%d" % [TranslationServer.translate("House Cores"), Anchors.AWAKEN_NEED, Anchors.AWAKEN_NEED], "LabelMuted")
	strip.name = "AwakenStrip"
	strip.add_theme_font_size_override("font_size", 24 if extra_line != "" else 18)
	strip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	strip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	strip.custom_minimum_size.x = 760
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(strip)
	var hint := UI3.label(TranslationServer.translate("Click to continue"), "LabelMuted")
	hint.name = "AwakenHint"
	hint.add_theme_font_size_override("font_size", 16)   # key hint size (token)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(hint)
	for n in ["AwakenTag", "AwakenName", "AwakenRule", "AwakenStrip", "AwakenHint"]:
		(_card.get_node(n) as Control).modulate.a = 0.0
	card_frame.modulate.a = 0.0


## Frame -> the double `anchor_awake` frame + the awaken glyph.
func _swap_frame() -> void:
	var gold := UI3Theme.color("anchor_awake")
	var hcol := AnchorAdapter.house_color(AnchorAdapter.house_id(anchor_id))
	card_frame.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("panel_raised"), UI3Theme.radius("l"), 6, gold, Vector4(16, 16, 16, 16)))
	if card_frame.get_node_or_null("InnerFrame") == null:
		var inner := Panel.new()
		inner.name = "InnerFrame"
		inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		inner.offset_left = 10
		inner.offset_top = 10
		inner.offset_right = -10
		inner.offset_bottom = -10
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_theme_stylebox_override("panel", UI3Theme.flat(Color(0, 0, 0, 0), UI3Theme.radius("m"), 3, hcol))
		card_frame.add_child(inner)
	(card_frame.find_child("AwakenGlyph", true, false) as Control).visible = true


func _show_final() -> void:
	card_frame.modulate.a = 1.0
	for n in ["AwakenTag", "AwakenName", "AwakenRule", "AwakenStrip", "AwakenHint"]:
		(_card.get_node(n) as Control).modulate.a = 1.0
	_swap_frame()
	_card.scale = Vector2.ONE


func _animate() -> void:
	var reduced := CombatView.flashes_suppressed()
	var total := duration()
	await get_tree().process_frame   # CenterContainer has not sorted yet: size is 0 until the next frame
	if not running or not is_inside_tree():
		return   # skipped / freed during that one frame
	_card.pivot_offset = _card.size * 0.5
	_tw = create_tween()
	if reduced:
		_tw.tween_property(card_frame, "modulate:a", 1.0, 0.3)
		_tw.tween_callback(_swap_frame)
		_tw.tween_property(card_frame, "modulate:a", 1.0, 0.3)
		for n in ["AwakenTag", "AwakenName", "AwakenRule", "AwakenStrip", "AwakenHint"]:
			_tw.parallel().tween_property(_card.get_node(n), "modulate:a", 1.0, 0.3)
		_tw.tween_interval(maxf(total - 0.9, 0.1))
		_tw.tween_callback(_end)
		return
	var shake := float(UI3Gacha.timing().get("shake_px", 10))
	_card.scale = Vector2(0.6, 0.6)
	_tw.set_parallel(true)
	_tw.tween_property(card_frame, "modulate:a", 1.0, 0.2).set_delay(0.1)
	_tw.tween_property(_card, "scale", Vector2(1.1, 1.1), 0.3).set_delay(0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tw.tween_property(_card, "scale", Vector2.ONE, 0.1).set_delay(0.4)
	_tw.tween_callback(_swap_frame).set_delay(0.5)
	var reach := maxf(size.x, 900.0)
	_tw.tween_method(func(r: float) -> void:
		_wave_r[0] = r
		_waves.queue_redraw(), 1.0, reach, 0.6).set_delay(0.5)
	_tw.tween_method(func(r: float) -> void:
		_wave_r[1] = r
		_waves.queue_redraw(), 1.0, reach, 0.6).set_delay(0.6)
	_tw.tween_callback(func() -> void: _shake(shake)).set_delay(0.5)
	var at := {"AwakenTag": 0.6, "AwakenName": 0.9, "AwakenRule": 1.1, "AwakenStrip": 1.3, "AwakenHint": 1.6}
	for n in at.keys():
		_tw.tween_property(_card.get_node(n), "modulate:a", 1.0, 0.2).set_delay(float(at[n]))
	_tw.chain().tween_interval(maxf(total - 0.5 - 1.5, 0.0))   # hold up to ~2.2 s
	_tw.chain().tween_callback(_end)


func _shake(px: float) -> void:
	var tw := create_tween()
	var base := position
	for i in 5:
		tw.tween_property(self, "position", base + Vector2(randf_range(-px, px), randf_range(-px, px)), 0.05)
	tw.tween_property(self, "position", base, 0.0)


func skip() -> void:
	if not running:
		return
	skipped = true
	log.append("skip")
	_end()


## Card flies to the HUD Anchor tile (0.3 s; fade when there is none), scrim off, then free. Skipping goes straight to free.
func _end() -> void:
	if not running:
		return
	running = false
	if _tw != null and _tw.is_valid():
		_tw.kill()
	log.append("end")
	finished.emit()
	if skipped or not is_inside_tree() or _fly_to.size == Vector2.ZERO or CombatView.flashes_suppressed():
		queue_free()
		return
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_card, "scale", Vector2(0.2, 0.2), 0.3)
	tw.tween_property(self, "modulate:a", 0.0, 0.3)
	tw.chain().tween_callback(queue_free)


func _input(ev: InputEvent) -> void:
	if not running:
		return
	var hit := false
	if ev is InputEventMouseButton and ev.pressed:
		hit = true
	elif ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_A, KEY_ESCAPE]:
		hit = true
	if hit:
		get_viewport().set_input_as_handled()
		skip()
