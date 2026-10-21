class_name GachaFx
extends Control
## Gacha moments that are not the card flip: A5 bet spin (Dim Stone) and the combo banner (Pair / Full).
## UI only. The result is always decided before this runs; nothing here reads rng or changes state.
## Click / Space / Enter skips a spin to its result. The banner is click-through (a click only dismisses it).

signal finished

var events: Array[String] = []
var running := false
var _label: Label
var _frame: PanelContainer
var _names: Array = []
var _final := ""
var _tween: Tween


## Pure: `ticks` intervals that add up to `total`, short first, long last (the wheel slows down).
static func spin_schedule(total: float, ticks: int) -> Array[float]:
	var w: Array[float] = []
	var sum := 0.0
	for i in ticks:
		var x := float(i + 1) / float(ticks)
		w.append(0.4 + x * x * 3.6)
		sum += w[i]
	var out: Array[float] = []
	for i in ticks:
		out.append(total * w[i] / sum)
	return out


## Pure: names shown on each tick. Cycles through `pool`, never ends on anything but `final`.
static func spin_faces(pool: Array, final: String, ticks: int) -> Array[String]:
	var out: Array[String] = []
	var others: Array = pool.filter(func(n): return n != final)
	for i in ticks - 1:
		out.append(String(others[i % others.size()]) if not others.is_empty() else final)
	out.append(final)
	return out


## Builds the spin plate centred on the screen and runs it. pool: real Crystal Core names; final: the granted Core.
## card_rect (global): when given, the plate sits ON the picked card, so the other cards stay visible.
func start_spin(pool: Array, final: String, accent: Color, card_rect := Rect2()) -> void:
	z_index = 50   # UI3 card panels use z_index 6; without this the plate drew behind the cards
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cc)
	_frame = PanelContainer.new()
	_frame.name = "SpinPlate"
	_frame.custom_minimum_size = Vector2(640, 200)
	var on_card := card_rect.size.x > 0.0
	if on_card:
		_frame.custom_minimum_size = card_rect.size
	_frame.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("panel"), UI3Theme.radius("l"),
		UI3Theme.stroke("selected"), accent))
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 12)
	_frame.add_child(v)
	var cap := UI3.label(tr("Rolling a Crystal Core"), "LabelMuted")
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(cap)
	_label = UI3.label("", "LabelScreenTitle")
	_label.name = "SpinName"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_label)
	if on_card:
		cc.queue_free()
		add_child(_frame)
		_frame.global_position = card_rect.position
		_frame.size = card_rect.size
		cap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	else:
		cc.add_child(_frame)
	_final = final
	var t := UI3Gacha.timing()
	var ticks := 16
	var faces := spin_faces(pool, final, ticks)
	_names = faces
	if UI3Gacha.is_instant():
		events.append("instant")
		_label.text = final
		_done()
		return
	running = true
	events.append("spin")
	var sched := spin_schedule(float(t.get("spin_sec", 2.0)), ticks)
	_tween = create_tween()
	for i in ticks:
		_tween.tween_callback(_tick.bind(i))
		_tween.tween_interval(sched[i])
	_tween.tween_callback(_stop)
	_tween.tween_interval(float(t.get("spin_hold_sec", 0.6)))
	_tween.tween_callback(_done)


func _tick(i: int) -> void:
	_label.text = String(_names[i])
	events.append("tick:%d" % i)
	_pop(1.0 + 0.1 * float(i) / 16.0, 0.12)


## Slot-reel feel: each name pops in; the last one lands bigger. No pop with reduce flashing.
func _pop(amount: float, sec: float) -> void:
	if MetaState.reduce_flash or _label == null:
		return
	_label.pivot_offset = _label.size / 2.0
	_label.scale = Vector2.ONE * amount
	create_tween().tween_property(_label, "scale", Vector2.ONE, sec).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _stop() -> void:
	_label.text = _final
	_pop(1.3, 0.35)
	events.append("stop")
	UI3Gacha.play_sfx(self, "spin_stop")


func _done() -> void:
	running = false
	finished.emit()


func skip() -> void:
	if not running:
		return
	events.append("skip")
	if _tween != null:
		_tween.kill()
	_label.text = _final
	_done()


func _input(ev: InputEvent) -> void:
	if not running:
		return
	if name == "ComboBanner":   # a click / Space dismisses it (and is consumed: nothing below it reacts)
		if (ev is InputEventMouseButton and ev.pressed) or (ev is InputEventKey and ev.pressed and not ev.echo \
				and (ev.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_ESCAPE])):
			get_viewport().set_input_as_handled()
			_banner_end()
		return
	if (ev is InputEventMouseButton and ev.pressed) or (ev is InputEventKey and ev.pressed and not ev.echo \
			and (ev.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER])):
		get_viewport().set_input_as_handled()
		skip()


## Combo banner: a BIG panel in the middle of the screen over the Core-pick overlay, with a light scrim.
## Pair: one gold frame, "PAIR" tag, 1.6 s. Full: thicker frame + extra inner ring, "FULL" tag, 2.8 s, bigger, other sound.
## Name at 32 px (36 is for turn banners only). A click or Space dismisses it early. Returns the node (added to `parent`).
static func banner(parent: Node, tier: String, combo_name: String, core_ids: Array = []) -> Control:
	var full := tier == "full"
	var root := GachaFx.new()
	root.z_index = 50
	root.name = "ComboBanner"
	root.theme = UI3Theme.get_theme()   # its parent is a CanvasLayer: no theme to inherit
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var scrim := ColorRect.new()
	scrim.name = "BannerScrim"
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.color = Color(UI3Theme.color("bg"), 0.55)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(scrim)
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(cc)
	var gold := UI3Theme.color("accent")
	var ink := UI3Theme.color("accent_text")
	# Outer gold frame
	var outer := PanelContainer.new()
	outer.name = "BannerPlate"
	outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer.custom_minimum_size = Vector2(960 if full else 760, 0)
	outer.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("panel"), UI3Theme.radius("l"),
		12 if full else 6, gold, Vector4(12, 12, 12, 12)))
	cc.add_child(outer)
	var mid := PanelContainer.new()
	mid.name = "BannerRing"
	mid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mid.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("panel_raised"), UI3Theme.radius("m"),
		4, UI3Theme.color("text"), Vector4(12, 12, 12, 12)))
	outer.add_child(mid)
	var inner_parent: Control = mid
	if full:   # third ring: Full reads as "more"
		var ring3 := PanelContainer.new()
		ring3.name = "BannerRing3"
		ring3.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ring3.add_theme_stylebox_override("panel", UI3Theme.flat(Color(0, 0, 0, 0), UI3Theme.radius("m"), 4, gold,
			Vector4(8, 8, 8, 8)))
		mid.add_child(ring3)
		inner_parent = ring3
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 16)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner_parent.add_child(v)
	# glyph row: 2 cards = Pair, 3 = Full (colour never alone: the word is there too)
	var glyphs := HBoxContainer.new()
	glyphs.name = "ComboGlyphs"
	glyphs.alignment = BoxContainer.ALIGNMENT_CENTER
	glyphs.add_theme_constant_override("separation", 32)
	glyphs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in (3 if full else 2):
		var def = RelicRegistry.get_def(String(core_ids[i])) if i < core_ids.size() else null
		var cell := VBoxContainer.new()
		cell.name = "ComboCore%d" % i
		cell.add_theme_constant_override("separation", 4)
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ic := TextureRect.new()
		ic.texture = UI3.icon(String(CorePanel.AXIS_ICON.get(String(def.core_axis), "face_buff")) if def != null else "ui_mooncard")
		ic.custom_minimum_size = Vector2(72, 72)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(ic)
		if def != null:
			var nm := UI3.label(UI3.title_case(UI3.player_text(String(def.name))), "LabelMuted")
			nm.name = "CoreName"
			nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cell.add_child(nm)
		glyphs.add_child(cell)
	v.add_child(glyphs)
	# gold tag with dark text
	var tagrow := HBoxContainer.new()
	tagrow.alignment = BoxContainer.ALIGNMENT_CENTER
	tagrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tag := UI3.combo_tier_tag(full, false)
	tag.name = "BannerTag"
	(tag.find_child("ComboWord", true, false) as Label).name = "TagText"
	tagrow.add_child(tag)
	v.add_child(tagrow)
	var l := UI3.label(combo_name, "LabelScreenTitle")   # 32
	l.name = "BannerText"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_color_override("font_color", gold if full else UI3Theme.color("text"))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(l)
	var hint := UI3.label(TranslationServer.translate("Click to continue"), "LabelMuted")
	hint.name = "BannerHint"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(hint)
	parent.add_child(root)
	root.set_meta("tier", tier)
	UI3Gacha.play_sfx(root, "full" if full else "pair")
	var secs := float(UI3Gacha.timing().get("banner_full_sec" if full else "banner_pair_sec", 1.6))
	if UI3Gacha.is_instant():
		return root
	root.running = true
	outer.pivot_offset = Vector2(outer.custom_minimum_size.x / 2.0, 120)
	outer.scale = Vector2(0.7, 0.7)
	var pop := root.create_tween()
	pop.tween_property(outer, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var tw := root.create_tween()
	tw.tween_interval(secs)
	tw.tween_callback(root._banner_end)
	return root


func _banner_end() -> void:
	if not running:
		return
	running = false
	finished.emit()
	queue_free()
