class_name AnchorFx
extends Control
## Lane AU2 job 4: the Anchor AWAKENING moment (design/ux/anchor-mvp.md section 4). Blocks input, scrim 80%, the Anchor card
## big in the middle, frame turns to the double `anchor_awake` frame, 8 slow rays (anchor_awake 7%), title letters pop.
## UI-04: UI3Motion "anchor_awaken" drives scale + particles; rays / scrim / letters are drawn here (the engine does not run them).
## With Reduce flashing or Reduce motion: fades only, rays static, no particles. Click / Space / Enter / A / Esc jump to the end.
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
var _rays: Control = null
var _tw: Tween = null
var _ray_rot := 0.0                    ## radians; advances 12 deg/s (UI-04 motion table) unless motion is reduced
var _rays_static := false
var _letters: Array[Label] = []
var _fly_to := Rect2()


const CARD_PX := 320.0   ## double-frame card (UI-04 R4)
const GLYPH_PX := 140.0
const PARTICLE_PX := 24.0


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
	scrim.color = Color(UI3Theme.color("bg"), 0.8)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)
	_rays = Control.new()
	_rays.name = "AwakenRays"
	_rays.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rays.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rays.modulate.a = 0.0
	_rays.draw.connect(_draw_rays)
	add_child(_rays)
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cc)
	_card = VBoxContainer.new()
	_card.name = "AwakenColumn"
	_card.add_theme_constant_override("separation", 12)
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cc.add_child(_card)
	_card.child_entered_tree.connect(_fit_particles)
	var tag := HBoxContainer.new()   # one Label per letter so the title can pop letter by letter
	tag.name = "AwakenTag"
	tag.alignment = BoxContainer.ALIGNMENT_CENTER
	tag.add_theme_constant_override("separation", 0)
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for ch in String(TranslationServer.translate("ANCHOR AWAKENED")):
		var lt := UI3.label(ch, "LabelDisplay")
		lt.add_theme_font_size_override("font_size", UI3Theme.size_of("text_banner"))
		lt.add_theme_color_override("font_color", gold)
		lt.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tag.add_child(lt)
		_letters.append(lt)
	_card.add_child(tag)
	var row := CenterContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(row)
	card_frame = PanelContainer.new()
	card_frame.name = "AnchorCard"
	card_frame.custom_minimum_size = Vector2(CARD_PX, CARD_PX)
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
	ic.custom_minimum_size = Vector2(GLYPH_PX, GLYPH_PX)
	ic.modulate = hcol
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cv.add_child(ic)
	var nm := UI3.label(AnchorAdapter.name_of(anchor_id), "LabelScreenTitle")
	nm.name = "AnchorName"
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cv.add_child(nm)
	var aw := TextureRect.new()
	aw.name = "AwakenGlyph"
	aw.texture = UI3.icon(CorePanel.AWAKEN_ICON)
	aw.custom_minimum_size = Vector2(56, 56)
	aw.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	aw.position = Vector2(CARD_PX - 16 - 56 - 4, 4)   # top-right corner; a plain Control holder so the PanelContainer does not stretch it over the name
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
	ar.add_theme_font_size_override("font_size", UI3Theme.size_of("text_title"))   # 24, wrap 2 at 760
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
	var hint := HBoxContainer.new()
	hint.name = "AwakenHint"
	hint.alignment = BoxContainer.ALIGNMENT_CENTER
	hint.add_theme_constant_override("separation", 8)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for part in [UI3.label(TranslationServer.translate("Click or"), "LabelKeyHint"), UI3.keycap("Space", true), UI3.label(TranslationServer.translate("to continue"), "LabelKeyHint")]:
		hint.add_child(part)
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


## The engine burst uses the sprite at native size (a fragment is ~100 px): shrink it to PARTICLE_PX so it reads as sparks.
func _fit_particles(n: Node) -> void:
	if n is CPUParticles2D and (n as CPUParticles2D).texture != null:
		var cp := n as CPUParticles2D
		var k := PARTICLE_PX / maxf(float(cp.texture.get_width()), 1.0)
		cp.scale_amount_min = k
		cp.scale_amount_max = k


func _show_final() -> void:
	card_frame.modulate.a = 1.0
	for n in ["AwakenTag", "AwakenName", "AwakenRule", "AwakenStrip", "AwakenHint"]:
		(_card.get_node(n) as Control).modulate.a = 1.0
	_swap_frame()
	_card.scale = Vector2.ONE
	_rays.modulate.a = 1.0
	_rays_static = true
	_rays.queue_redraw()


## 8 plates (wedges) in `anchor_awake` at 7%, one every 45 degrees, hard edges (no gradient). Slow rotation set in _process.
func _draw_rays() -> void:
	var c := _rays.size * 0.5
	var col := UI3Theme.color("anchor_awake")
	col.a = 0.07
	var reach := _rays.size.length()
	var half := deg_to_rad(11.0)
	var count := int(UI3Motion.table().get("anchor_awaken", {}).get("rays", {}).get("count", 8))
	for i in count:
		var a := _ray_rot + TAU * float(i) / float(count)
		_rays.draw_colored_polygon(PackedVector2Array([c, c + Vector2.RIGHT.rotated(a - half) * reach, c + Vector2.RIGHT.rotated(a + half) * reach]), col)


func _process(dt: float) -> void:
	if not running or _rays_static or not is_inside_tree():
		return
	var dps := float(UI3Motion.table().get("anchor_awaken", {}).get("rays", {}).get("deg_per_sec", 12))
	_ray_rot += deg_to_rad(dps) * dt
	_rays.queue_redraw()


func _animate() -> void:
	var reduced := CombatView.motion_suppressed()   # Reduce flashing OR Reduce motion: fades only, rays static, no particles
	var total := duration()
	await get_tree().process_frame   # CenterContainer has not sorted yet: size is 0 until the next frame
	if not running or not is_inside_tree():
		return   # skipped / freed during that one frame
	_card.pivot_offset = _card.size * 0.5
	for lt in _letters:
		lt.pivot_offset = lt.size * 0.5
	_tw = create_tween()
	var m: Dictionary = UI3Motion.table().get("anchor_awaken", {})
	var scrim_s := float(m.get("scrim_ms", 160)) / 1000.0
	var title_at := float(m.get("title_delay_ms", 200)) / 1000.0
	var text_at := float(m.get("text_delay_ms", 500)) / 1000.0
	var in_s := float((m.get("in", {}) as Dictionary).get("ms", 360)) / 1000.0
	var hold_s := float(m.get("hold_ms", 900)) / 1000.0
	var scrim := get_node("AwakenScrim") as CanvasItem
	if reduced:
		_rays_static = true
		_rays.modulate.a = 1.0
		_rays.queue_redraw()
		_tw.tween_property(card_frame, "modulate:a", 1.0, 0.3)
		_tw.tween_callback(_swap_frame)
		for n in ["AwakenTag", "AwakenName", "AwakenRule", "AwakenStrip", "AwakenHint"]:
			_tw.parallel().tween_property(_card.get_node(n), "modulate:a", 1.0, 0.3)
		_tw.tween_interval(maxf(total - 0.6, 0.1))
		_tw.tween_callback(_end)
		return
	scrim.modulate.a = 0.0
	_tw.set_parallel(true)
	_tw.tween_property(scrim, "modulate:a", 1.0, scrim_s)
	_tw.tween_property(_rays, "modulate:a", 1.0, scrim_s)
	_tw.tween_property(card_frame, "modulate:a", 1.0, 0.2).set_delay(scrim_s)
	_tw.tween_callback(_swap_frame).set_delay(scrim_s + in_s)
	# Title letters pop one by one from +title_delay; the rest of the text from +text_delay.
	for i in _letters.size():
		var lt := _letters[i]
		lt.modulate.a = 0.0
		lt.scale = Vector2(0.2, 0.2)
		var d := scrim_s + title_at + 0.04 * float(i)
		_tw.tween_property(lt, "modulate:a", 1.0, 0.08).set_delay(d)
		_tw.tween_property(lt, "scale", Vector2.ONE, 0.2).set_delay(d).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tw.tween_property(_card.get_node("AwakenTag"), "modulate:a", 1.0, 0.01).set_delay(scrim_s + title_at)
	var at := {"AwakenName": 0.0, "AwakenRule": 0.1, "AwakenStrip": 0.2, "AwakenHint": 0.3}
	for n in at.keys():
		_tw.tween_property(_card.get_node(n), "modulate:a", 1.0, 0.2).set_delay(scrim_s + text_at + float(at[n]))
	# Scale-in, burst and hold come from the motion table: moment "anchor_awaken" on the column. Its on_done ends the moment.
	var hold_ms := maxf(total - scrim_s - in_s - 0.16, hold_s) * 1000.0
	var opts := {"hold_ms": hold_ms, "on_done": Callable(self, "_end")}
	get_tree().create_timer(scrim_s).timeout.connect(func() -> void:
		if running and is_inside_tree():
			UI3Motion.play("anchor_awaken", _card, opts))


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
	if skipped or not is_inside_tree() or _fly_to.size == Vector2.ZERO or CombatView.motion_suppressed():
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
