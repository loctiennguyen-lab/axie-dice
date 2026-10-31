class_name AnchorFx
extends Control
const Ps := preload("res://scenes/shared/ui5/PanelParts.gd")
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
var _tl: UI3Motion.Timeline = null
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


## Per-Anchor float line when the awakened rule does its thing in combat ("awaken" core_fired kind). `amount` is what the engine reports
## (Unison: dice synced, Passed Flame: mana saved, Sixth Hand: 1 bonus die). Names come from data; the verb is the only fixed text.
const AWAKEN_VERB := {"a_kin": "%s: %d in step", "a_embers": "%s: free", "a_big_hand": "%s: bonus die"}


static func awaken_line(id: String, amount: int) -> String:
	var nm := AnchorAdapter.awaken_name(id)
	if nm == "":
		nm = AnchorAdapter.name_of(id)
	if not AWAKEN_VERB.has(id):
		return nm
	var f := TranslationServer.translate(String(AWAKEN_VERB[id]))
	return (f % [nm, amount]) if f.contains("%d") else (f % nm)


static func arm(id: String) -> void:
	pending = id


static func duration() -> float:
	var t := UI3Gacha.timing()
	return float(t.get("awaken_reduced_sec", 1.6)) if CombatView.motion_suppressed() else float(t.get("awaken_sec", 2.5))


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
	scrim.color = Color(UI3Theme.color("bg"), 0.6)   # round-2 moment: scrim 0 -> 0.6
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
	_card.add_theme_constant_override("separation", UI3Theme.space("16"))
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cc.add_child(_card)
	# Static layout = round-2/moments/moment-anchor-awaken.html #grp: tag 28 gold, tile (plate, house border, glyph + name),
	# name 56 gold, rule (body, <= r3_fx_text_w), strip pill, hint. Gap 16. Sizes are tokens (r3_fx_*).
	var tile := UI3Theme.size_of("r3_fx_tile")
	var frame_w := UI3Theme.size_of("r3_fx_frame")
	var text_w := UI3Theme.size_of("r3_fx_text_w")
	var tag := Ps.on_view(Ps.text(TranslationServer.translate("ANCHOR AWAKENED"), "num_die", "anchor_awake", true))
	tag.name = "AwakenTag"
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(tag)
	var row := CenterContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(row)
	card_frame = PanelContainer.new()
	card_frame.name = "AnchorCard"
	card_frame.custom_minimum_size = Vector2(tile, tile)
	card_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_frame.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("plate"), UI3Theme.radius("xl"), frame_w, hcol,
		Vector4(frame_w, frame_w, frame_w, frame_w), Ps.lip(UI3Theme.color("plate_ink"), true)))
	row.add_child(card_frame)
	var cv := VBoxContainer.new()
	cv.alignment = BoxContainer.ALIGNMENT_CENTER
	cv.add_theme_constant_override("separation", UI3Theme.space("8"))
	cv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_frame.add_child(cv)
	var gpx := UI3Theme.size_of("r3_fx_glyph")
	var ic := Ps.icon_rect(UI3.icon(AnchorAdapter.house_icon(house)), gpx, "HouseGlyph")
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cv.add_child(ic)
	var nm := Ps.text(AnchorAdapter.name_of(anchor_id), "text_title", "text", true)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cv.add_child(nm)
	var mark := UI3Theme.size_of("r3_fx_mark")
	var aw := TextureRect.new()
	aw.name = "AwakenGlyph"
	aw.texture = UI3.icon(CorePanel.AWAKEN_ICON)
	aw.custom_minimum_size = Vector2(mark, mark)
	aw.size = Vector2(mark, mark)
	aw.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	aw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aw.visible = false
	# Gold disc (56) behind the glyph: html #mark, right -18 / top -18 of the tile.
	var disc := Panel.new()
	disc.name = "AwakenDisc"
	disc.size = Vector2(mark, mark)
	disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	disc.add_theme_stylebox_override("panel", UI3Theme.flat(gold, int(mark / 2.0)))
	disc.visible = false
	var holder := Control.new()
	holder.name = "AwakenGlyphHolder"
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.position = Vector2(tile - mark + UI3Theme.space("16") + 2, -UI3Theme.space("16") - 2)
	holder.add_child(disc)
	holder.add_child(aw)
	card_frame.add_child(holder)
	var an := Ps.text(AnchorAdapter.awaken_name(anchor_id), "text_hero", "anchor_awake", true)
	an.name = "AwakenName"
	an.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	an.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(an)
	var ar := Ps.on_view(Ps.text(AnchorAdapter.awaken_rule(anchor_id)))
	ar.name = "AwakenRule"
	ar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ar.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ar.custom_minimum_size.x = text_w
	ar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(ar)
	var strip_text := extra_line if extra_line != "" else "%s %d/%d" % [TranslationServer.translate("House Cores"), Anchors.AWAKEN_NEED, Anchors.AWAKEN_NEED]
	# Pill plate, 48 high: label + two 16 px house-coloured dots (html #strip).
	var strip := PanelContainer.new()
	strip.name = "AwakenStrip"
	strip.custom_minimum_size = Vector2(0, 48)
	strip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("plate"), 24, 0, Color.TRANSPARENT,
		Vector4(20, 0, 20, 0), Ps.lip(UI3Theme.color("plate_ink"), true)))
	_card.add_child(strip)
	var srow := HBoxContainer.new()
	srow.alignment = BoxContainer.ALIGNMENT_CENTER
	srow.add_theme_constant_override("separation", UI3Theme.space("12"))
	srow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.add_child(srow)
	var st := Ps.text(strip_text, "text_title" if extra_line != "" else "text_body", "text_muted", true)
	st.name = "AwakenStripText"
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	st.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	st.custom_minimum_size.x = minf(text_w, 560.0)
	st.mouse_filter = Control.MOUSE_FILTER_IGNORE
	srow.add_child(st)
	for k in 2:
		var dot := Panel.new()
		dot.name = "AwakenPip%d" % (k + 1)
		dot.custom_minimum_size = Vector2(16, 16)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.add_theme_stylebox_override("panel", UI3Theme.flat(hcol, 8))
		srow.add_child(dot)
	# Hint: bottom-right corner of the screen, 24 / 24 (html .hint).
	var hint := Ps.on_view(Ps.text(TranslationServer.translate("Click to continue"), "text_key_hint"))
	hint.name = "AwakenHint"
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	hint.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hint.offset_right = -24
	hint.offset_bottom = -24
	add_child(hint)
	for n in _fade_nodes():
		n.modulate.a = 0.0
	card_frame.modulate.a = 0.0


## Frame -> the double `anchor_awake` frame + the awaken glyph.
func _swap_frame() -> void:
	var gold := UI3Theme.color("anchor_awake")
	var hcol := AnchorAdapter.house_color(AnchorAdapter.house_id(anchor_id))
	card_frame.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("plate"), UI3Theme.radius("xl"), UI3Theme.size_of("r3_fx_frame"), gold, Vector4(UI3Theme.size_of("r3_fx_frame"), UI3Theme.size_of("r3_fx_frame"), UI3Theme.size_of("r3_fx_frame"), UI3Theme.size_of("r3_fx_frame")), Ps.lip(UI3Theme.color("plate_ink"), true)))
	if card_frame.get_node_or_null("InnerFrame") == null:
		var inner := Panel.new()
		inner.name = "InnerFrame"
		inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var gi := UI3Theme.size_of("r3_fx_frame") + UI3Theme.stroke("focus_offset")
		inner.offset_left = gi
		inner.offset_top = gi
		inner.offset_right = -gi
		inner.offset_bottom = -gi
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_theme_stylebox_override("panel", UI3Theme.flat(Color(0, 0, 0, 0), UI3Theme.radius("m"), UI3Theme.stroke("btn"), hcol))
		card_frame.add_child(inner)
	(card_frame.find_child("AwakenDisc", true, false) as Control).visible = true
	(card_frame.find_child("AwakenGlyph", true, false) as Control).visible = true


## The text nodes that fade in (hint lives on the screen, the rest in the column).
func _fade_nodes() -> Array[Control]:
	var out: Array[Control] = []
	for n in ["AwakenTag", "AwakenName", "AwakenRule", "AwakenStrip"]:
		out.append(_card.get_node(n) as Control)
	out.append(get_node("AwakenHint") as Control)
	return out


func _show_final() -> void:
	card_frame.modulate.a = 1.0
	for n in _fade_nodes():
		n.modulate.a = 1.0
	(card_frame.find_child("AwakenGlyph", true, false) as Control).modulate.a = 1.0
	_swap_frame()
	_card.scale = Vector2.ONE


func _animate() -> void:
	var reduced := CombatView.motion_suppressed()
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
		for n in _fade_nodes():
			_tw.parallel().tween_property(n, "modulate:a", 1.0, 0.3)
		_tw.tween_interval(maxf(total - 0.9, 0.1))
		_tw.tween_callback(_end)
		return
	# Full motion: the `anchor-awaken` layers of motion_ui3.json (round-2 moment-anchor-awaken). Rays have no texture yet.
	var scrim := get_node("AwakenScrim") as Control
	scrim.modulate.a = 0.0
	card_frame.pivot_offset = card_frame.size * 0.5
	var glyph := card_frame.find_child("AwakenGlyph", true, false) as Control
	glyph.modulate.a = 0.0
	glyph.pivot_offset = glyph.size * 0.5
	var nm := _card.get_node("AwakenName") as Control
	nm.pivot_offset = nm.size * 0.5
	var pips: Array = []
	for k in 2:
		var pip := _card.find_child("AwakenPip%d" % (k + 1), true, false) as Control
		pip.pivot_offset = pip.size * 0.5
		pips.append(pip)
	var tg := {"scrim": scrim, "tag": _card.get_node("AwakenTag"), "tile": card_frame, "glyph": glyph, "name": nm,
		"rule": _card.get_node("AwakenRule"), "strip": _card.get_node("AwakenStrip"), "pip1": pips,
		"hint": get_node("AwakenHint"), "group": _card}
	var opts := {"host": self, "on_done": _end,
		"shake": func(px: float, sec: float) -> void: UI3Motion.wobble(self, px, sec)}
	if _fly_to.size != Vector2.ZERO:
		opts["fly_to"] = _fly_to.get_center()
	_tw.tween_interval(0.46)   # frame turns double (layer "frame": set at once, no tween)
	_tw.tween_callback(_swap_frame)
	_tl = UI3Motion.play_timeline("anchor-awaken", tg, opts)


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
	if _tl != null and not _tl.done:
		_tl.skip()
	log.append("end")
	finished.emit()
	if skipped or _tl != null or not is_inside_tree() or _fly_to.size == Vector2.ZERO or CombatView.motion_suppressed():
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
