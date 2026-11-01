class_name AnchorFx
extends Control
const Ps := preload("res://scenes/shared/ui5/PanelParts.gd")
const AnchorCardScript := preload("res://scenes/run_map/ui5/AnchorCard.gd")
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
var card_frame: Control = null
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


## UI-06 49-anchor-awaken--moment: a full-width band (AwakenBanner) over a 0.6 scrim. Top to bottom: AwakenEmblem (ui_awaken
## burst behind the house emblem), AwakenKicker "<Anchor> awakens", AwakenName, AwakenText (chips), HouseCoresDone (the two House
## Cores that did it + AwakenMeter 2/2). ContinueHint bottom-right. Timeline keys of motion_ui3 `anchor-awaken` map as:
## tag = kicker, tile = emblem, glyph = burst, name, rule = text, strip = cores row, pip1 = the two meter pips.
func _build(extra_line: String) -> void:
	var house := AnchorAdapter.house_id(anchor_id)
	var hcol := AnchorAdapter.house_color(house)
	var gold := UI3Theme.color("anchor_awake")
	var scrim := ColorRect.new()
	scrim.name = "AwakenScrim"
	scrim.color = Color(UI3Theme.color("bg"), 0.6)   # moment: scrim 0 -> 0.6
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)
	_waves = Control.new()   # kept for the reduce-flash contract (no waves are drawn in the band version)
	_waves.name = "AwakenWaves"
	_waves.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_waves.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_waves)
	var band := PanelContainer.new()
	band.name = "AwakenBanner"
	band.set_anchors_preset(Control.PRESET_HCENTER_WIDE)
	band.anchor_top = 0.5
	band.anchor_bottom = 0.5
	band.offset_left = 0
	band.offset_right = 0
	band.grow_vertical = Control.GROW_DIRECTION_BOTH
	band.custom_minimum_size.y = UI3Theme.size_of("banner_h")
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bsb := UI3Theme.flat(UI3Theme.color("banner_player"), 0, UI3Theme.stroke("rim"), UI3Theme.color("plate_rim"),
		Vector4(0, UI3Theme.space("16"), 0, UI3Theme.space("16")))
	band.add_theme_stylebox_override("panel", bsb)
	add_child(band)
	_card = VBoxContainer.new()
	_card.name = "AwakenColumn"
	_card.alignment = BoxContainer.ALIGNMENT_CENTER
	_card.add_theme_constant_override("separation", UI3Theme.space("8"))
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.add_child(_card)
	var np := 1.0 if UI3Theme.layout_scale() >= 1.0 else 0.75
	# Emblem: burst (200) behind the house emblem (128), .awk box 200 x 160
	var emb := Control.new()
	emb.name = "AwakenEmblem"
	emb.custom_minimum_size = Vector2(200, 160) * np
	emb.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	emb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_frame = emb
	var bs := 200.0 * np
	var burst := TextureRect.new()
	burst.name = "AwakenGlyph"
	burst.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	burst.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	burst.texture = UI6Assets.awaken(128)
	burst.size = Vector2(bs, bs)
	burst.position = Vector2(emb.custom_minimum_size.x - bs, emb.custom_minimum_size.y - bs) * 0.5
	burst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	burst.visible = false
	emb.add_child(burst)
	var hp := 128.0 * np
	var he := TextureRect.new()
	he.name = "HouseEmblem"
	he.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	he.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	he.texture = UI6Assets.house(house, hp)
	he.size = Vector2(hp, hp)
	he.position = (emb.custom_minimum_size - he.size) * 0.5
	he.mouse_filter = Control.MOUSE_FILTER_IGNORE
	emb.add_child(he)
	_card.add_child(emb)
	var tag := Ps.text(TranslationServer.translate("%s awakens") % AnchorAdapter.name_of(anchor_id), "text_title", "anchor_awake", true)
	tag.name = "AwakenKicker"
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(tag)
	var an := Ps.text(AnchorAdapter.awaken_name(anchor_id), "text_hero", "text", true)
	an.name = "AwakenName"
	an.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	an.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(an)
	# AwakenText: .mutation box, anchor_awake border, chips in the rule
	var text_w := UI3Theme.size_of("r3_fx_text_w")
	var tbox := PanelContainer.new()
	tbox.name = "AwakenTextBox"
	tbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tbox.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("plate"), UI3Theme.radius("m"), UI3Theme.stroke("btn"), gold,
		Vector4(16, 8, 16, 8)))
	var rt := AnchorCardScript.rich("AwakenText", AnchorAdapter.awaken_rule(anchor_id), text_w - 32.0)
	tbox.add_child(rt)
	_card.add_child(tbox)
	# HouseCoresDone: the two House Cores that did it + AwakenMeter 2/2
	var done := HBoxContainer.new()
	done.name = "HouseCoresDone"
	done.alignment = BoxContainer.ALIGNMENT_CENTER
	done.add_theme_constant_override("separation", UI3Theme.space("16"))
	done.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shown := 0
	for cid in AnchorAdapter.house_cores(anchor_id):
		if shown >= Anchors.AWAKEN_NEED or not AnchorAdapter.owned().has(cid):
			continue
		done.add_child(_core_done(String(cid), hcol), true)
		shown += 1
	var meter := HBoxContainer.new()
	meter.name = "AwakenMeter"
	meter.add_theme_constant_override("separation", UI3Theme.space("4"))
	meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var pips := AwakenProgress.pips(Anchors.AWAKEN_NEED, gold, 12)
	meter.add_child(pips)
	var cnt := Ps.text("%d / %d" % [Anchors.AWAKEN_NEED, Anchors.AWAKEN_NEED], "text_body", "text")
	cnt.name = "Count"
	cnt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	meter.add_child(cnt)
	done.add_child(meter)
	_card.add_child(done)
	if extra_line != "":   # merged Pair line ("PAIR: X . MUTATION: Y")
		var st := Ps.text(extra_line, "text_title", "text_muted", true)
		st.name = "AwakenStripText"
		st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		st.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		st.custom_minimum_size.x = minf(text_w, 560.0)
		st.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		st.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_card.add_child(st)
	var hint := Ps.on_view(Ps.text(TranslationServer.translate("Click to continue"), "text_body"))
	hint.name = "ContinueHint"
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


## CoreSlot (slot picture + family emblem + TierShards + HouseDot) with the Core name beside it.
func _core_done(core_id: String, hcol: Color) -> HBoxContainer:
	var def = RelicRegistry.get_def(core_id)
	var tier := clampi(int(def.rarity) if def != null else 0, 0, 2)
	var axis := String(def.core_axis) if def != null else "stat"
	var row := HBoxContainer.new()
	row.name = "CoreDone"
	row.add_theme_constant_override("separation", UI3Theme.space("8"))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var px := 56.0
	var slot := Control.new()
	slot.name = "CoreSlot"
	slot.custom_minimum_size = Vector2(px, px)
	slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sk := Ps.icon_rect(UI6Assets.slot(tier, px), int(px), "SlotSocket")
	sk.set_anchors_preset(Control.PRESET_FULL_RECT)
	slot.add_child(sk)
	var fe := Ps.icon_rect(CoreVisuals.family_texture(axis, px * 0.6), int(px * 0.6), "FamilyEmblem")
	fe.set_anchors_preset(Control.PRESET_CENTER)
	fe.offset_left = -px * 0.3
	fe.offset_right = px * 0.3
	fe.offset_top = -px * 0.3 - 2
	fe.offset_bottom = px * 0.3 - 2
	slot.add_child(fe)
	var sh := TierShards.new().setup(tier, 14)
	sh.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	sh.grow_horizontal = Control.GROW_DIRECTION_BOTH
	sh.offset_bottom = -2
	slot.add_child(sh)
	var hd := Panel.new()
	hd.name = "HouseDot"
	hd.custom_minimum_size = Vector2(12, 12)
	hd.size = Vector2(12, 12)
	hd.position = Vector2(px - 12, 0)
	hd.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hd.add_theme_stylebox_override("panel", UI3Theme.flat(hcol, 6, 2, UI3Theme.color("plate_ink")))
	slot.add_child(hd)
	row.add_child(slot)
	var nm := Ps.text(UI3.title_case(UI3.player_text(String(def.name))) if def != null else core_id, "text_body", "text")
	nm.name = "CoreName"
	nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(nm)
	return row


## Burst behind the emblem lights up (frame turn in the old card version).
func _swap_frame() -> void:
	(card_frame.find_child("AwakenGlyph", true, false) as Control).visible = true


## The nodes that fade in (hint lives on the screen, the rest in the column).
func _fade_nodes() -> Array[Control]:
	var out: Array[Control] = []
	for n in ["AwakenKicker", "AwakenName", "AwakenTextBox", "HouseCoresDone"]:
		out.append(_card.get_node(n) as Control)
	out.append(get_node("ContinueHint") as Control)
	return out


func _show_final() -> void:
	card_frame.modulate.a = 1.0
	for n in _fade_nodes():
		n.modulate.a = 1.0
	var gly := card_frame.find_child("AwakenGlyph", true, false) as Control
	gly.modulate.a = 1.0
	gly.scale = Vector2.ONE   # the timeline's glyph layer starts rotated / small: the end state is 1 / 0
	gly.rotation = 0.0
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
		_swap_frame()   # the double frame is "set at once" (round-2 spec), not on a timer
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
	var pp := _card.find_child("AwakenPips", true, false)
	for pip in (pp.get_children() if pp != null else []):
		(pip as Control).pivot_offset = (pip as Control).size * 0.5
		pips.append(pip)
	var tg := {"scrim": scrim, "tag": _card.get_node("AwakenKicker"), "tile": card_frame, "glyph": glyph, "name": nm,
		"rule": _card.get_node("AwakenTextBox"), "strip": _card.get_node("HouseCoresDone"), "pip1": pips,
		"hint": get_node("ContinueHint"), "group": _card}
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
