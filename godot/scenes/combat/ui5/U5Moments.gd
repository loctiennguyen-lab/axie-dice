class_name U5Moments
extends RefCounted
## UI-05 b1 lane E: the ten combat moments (design/handoffs/ui-05-figma/round-1/motion-batch1.md + moments/*.html).
## CombatView calls these from its event-replay, turn, victory and defeat paths (one line each). Every number is a
## layer row in assets/data/ui/motion_ui3.json, played with UI3Motion.play_timeline (Reduce motion, skip and
## hit-stop are handled there). Layers whose target is a 3D node or another lane's node (enemy plate HP bar,
## DieCard greying) stay in the table as data and are skipped here.
## All visuals live on one CanvasLayer "Ui5Moments" (layer 2: over the HUD, under the victory-march UI and
## NetNotice). Nothing here takes the mouse (MOUSE_FILTER_IGNORE) or touches the fight; tests (disable_juice_for_tests)
## get no nodes at all.

const LAYER_NAME := "Ui5Moments"
const CANVAS_LAYER := 2
## Damage float from damage_pipeline.gd: "CRIT LINK -12". The number is shown without the sign (design), the CRIT
## word becomes the CRIT tag.
const DMG_RE := "^(CRIT )?(LINK )?-(\\d+)$"
## A throw-away node is freed this long after its moment ends (particles outlive the layers).
const LINGER_SEC := 1.2


# ---------------------------------------------------------------- layer

## True when moments may play on `v` (in the tree, not a headless test).
static func on(v: Node) -> bool:
	return v != null and is_instance_valid(v) and v.is_inside_tree() and not CombatView.disable_juice_for_tests


## The full-rect overlay root on the Ui5Moments layer (created on first use).
static func root(v: Node) -> Control:
	var layer := v.get_node_or_null(LAYER_NAME) as CanvasLayer
	if layer == null:
		layer = CanvasLayer.new()
		layer.name = LAYER_NAME
		layer.layer = CANVAS_LAYER
		v.add_child(layer)
		var r := Control.new()
		r.name = "Root"
		r.set_anchors_preset(Control.PRESET_FULL_RECT)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(r)
		var c := U5SkipCatcher.new()
		c.name = "SkipCatcher"
		c.view = weakref(v)
		layer.add_child(c)
	return layer.get_node("Root") as Control


static func catcher(v: Node) -> U5SkipCatcher:
	root(v)
	return v.get_node(LAYER_NAME + "/SkipCatcher") as U5SkipCatcher


## True while a skippable moment (crit, big hit, knockout, boss phase, defeat) is playing. For lane A's SkipHint.
static func skippable_running(v: Node) -> bool:
	return v != null and v.get_node_or_null(LAYER_NAME) != null and catcher(v).running()


static func _track(v: Node, id: String, run: UI3Motion.Timeline) -> void:
	if bool((UI3Motion.table().get(id, {}) as Dictionary).get("skippable", false)):
		catcher(v).add(run)


## Frees `nodes` LINGER_SEC after `run` ends (or at once when the moment never started).
## Timers outlive the scene, so they hold WeakRefs, never the nodes (a freed capture is an engine error).
static func _free_after(run: UI3Motion.Timeline, nodes: Array) -> void:
	var refs: Array = []
	for n in nodes:
		if n is Node and is_instance_valid(n):
			refs.append(weakref(n))
	var drop := func() -> void:
		for w in refs:
			var n: Node = (w as WeakRef).get_ref()
			if n == null:
				continue
			var tree := n.get_tree()
			if tree == null:
				n.queue_free()
			else:
				tree.create_timer(LINGER_SEC).timeout.connect(func() -> void:
					var m: Node = (w as WeakRef).get_ref()
					if m != null:
						m.queue_free())
	if run.done:
		drop.call()
	else:
		run.finished.connect(drop, CONNECT_ONE_SHOT)


## Screen shake for the moment tables: CombatStage3D.shake (it already obeys Reduce motion and the test flag).
static func shake_cb(v: CombatView) -> Callable:
	var vw: WeakRef = weakref(v)
	return func(px: float, sec: float) -> void:
		var cv: CombatView = vw.get_ref()
		if cv != null and is_instance_valid(cv._stage3d):
			cv._stage3d.shake(px, sec)


# ---------------------------------------------------------------- anchors

## Canvas point at `frac` of unit `uid`'s height (1 = just above the head), from the 3D stage. Falls back to the
## top centre of its plate, then the screen centre.
static func head(v: CombatView, uid: int, frac := 1.0) -> Vector2:
	var u: Unit = v._combat.by_uid(uid) if v._combat != null else null
	var st: CombatStage3D = v._stage3d
	if u != null and is_instance_valid(st):
		var h: float = CombatStage3D.AXIE_HEAD_HEIGHT if u.side == "p" else st.head_height_of(uid, CombatStage3D.HEAD_HEIGHT)
		var p := st.get_unit_screen_pos(uid, h * frac)
		if p.x >= 0.0:
			return st.global_position + p
	var pt: Variant = v._portraits.get(uid)
	if pt is Control and is_instance_valid(pt):
		var r := (pt as Control).get_global_rect()
		return Vector2(r.get_center().x, r.position.y)
	return root(v).size * 0.5


static func _place_center(c: Control, at: Vector2) -> void:
	c.size = c.get_combined_minimum_size()
	c.pivot_offset = c.size * 0.5
	c.position = at - c.size * 0.5


## An empty 0x0 Control at `at`: particles burst from it.
static func _fx_anchor(r: Control, at: Vector2) -> Control:
	var a := Control.new()
	a.name = "Fx"
	a.mouse_filter = Control.MOUSE_FILTER_IGNORE
	a.position = at
	r.add_child(a)
	return a


# ---------------------------------------------------------------- builders

## Big number / title label: Rowdies at a size token, hard 4 px drop shadow (moments: text-shadow 0 4px 0).
static func hero_label(text: String, size_token: String, color_token: String, shadow_token := "plate_ink") -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", UI3Theme.font_display())
	l.add_theme_font_size_override("font_size", UI3Theme.size_of(size_token))
	l.add_theme_color_override("font_color", UI3Theme.color(color_token))
	l.add_theme_color_override("font_shadow_color", UI3Theme.color(shadow_token))
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", 4)
	l.add_theme_constant_override("shadow_outline_size", 0)
	return l


## Pill tag (CRIT / BIG HIT / OUT): filled, radius pill, padding 0 14, height from a size token.
static func pill(text: String, bg_token: String, text_token: String, h_token: String, text_size_token: String,
		border_token := "") -> PanelContainer:
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := UI3Theme.size_of(h_token)
	var bw := UI3Theme.stroke("btn") if border_token != "" else 0
	p.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color(bg_token), int(h * 0.5), bw,
		UI3Theme.color(border_token) if border_token != "" else Color.TRANSPARENT, Vector4(14, 0, 14, 0)))
	p.custom_minimum_size = Vector2(0, h)
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", UI3Theme.font_display())
	l.add_theme_font_size_override("font_size", UI3Theme.size_of(text_size_token))
	l.add_theme_color_override("font_color", UI3Theme.color(text_token))
	p.add_child(l)
	return p


## Full-screen flat overlay (flash, vignette, tint, scrim), invisible until a layer fades it in.
static func overlay(color_token: String, node_name := "Overlay") -> ColorRect:
	var c := ColorRect.new()
	c.name = node_name
	c.color = Color(UI3Theme.color(color_token), 1.0)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.modulate.a = 0.0
	return c


## Full-width band (turn / phase / victory): flat colour, 2 px plate_rim top and bottom, 8 px plate_ink lip.
static func band(color_token: String, y: float, h: float, node_name := "Band") -> Control:
	var b := Control.new()
	b.name = node_name
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.set_anchors_preset(Control.PRESET_TOP_WIDE)
	b.offset_top = y
	b.offset_bottom = y + h
	var p := Panel.new()
	p.name = "Plate"
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.set_anchors_preset(Control.PRESET_FULL_RECT)
	var sb := StyleBoxFlat.new()
	sb.bg_color = UI3Theme.color(color_token)
	sb.border_width_top = UI3Theme.stroke("rim")
	sb.border_width_bottom = UI3Theme.stroke("rim")
	sb.border_color = UI3Theme.color("plate_rim")
	sb.shadow_color = UI3Theme.color("plate_ink")
	sb.shadow_offset = Vector2(0, float((UI3Theme.tokens().get("shadow", {}) as Dictionary).get("lip_l", 8)))
	sb.shadow_size = 1   # Godot draws no shadow at 0; 1 = a hard lip
	p.add_theme_stylebox_override("panel", sb)
	b.add_child(p)
	b.resized.connect(func() -> void: b.pivot_offset = b.size * 0.5)
	return b


## Label filling a band, centred; keeps its pivot in the middle so a scale punch grows from the centre.
static func band_label(b: Control, text: String, size_token: String, color_token: String, shadow_token: String) -> Label:
	var l := hero_label(text, size_token, color_token, shadow_token)
	l.name = "Label"
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	b.add_child(l)
	l.resized.connect(func() -> void: l.pivot_offset = l.size * 0.5)
	l.pivot_offset = l.size * 0.5
	return l


# ---------------------------------------------------------------- moments

## Hit / crit / big hit (CombatView._on_hit_landed, at impact): tag, screen flash, light sweep, sparks, hit-stop.
## The number comes with the damage float (float_text below); the screen shake with CombatView._play_hit_juice.
static func on_hit(v: CombatView, uid: int, mid: String) -> void:
	if not on(v) or not UI3Motion.has_moment(mid):
		return
	var r := root(v)
	var at := head(v, uid)
	var made: Array = []
	var targets := {"fx": _fx_anchor(r, at)}
	made.append(targets["fx"])
	var lt := UI3Motion.layer(mid, "tag")
	if not lt.is_empty():
		var big := mid == "big_hit"
		var tag := pill(TranslationServer.translate(String(lt.get("text", ""))), String(lt.get("color_token", "accent")),
			String(lt.get("text_token", "text")), "btn_s" if big else "status_chip_h", "text_title" if big else "text_body")
		tag.name = "BigHitTag" if big else "CritTag"
		r.add_child(tag)
		_place_center(tag, at + Vector2(-40.0 if big else 0.0, -128.0 if big else -96.0))
		targets["tag"] = tag
		made.append(tag)
	var lf := UI3Motion.layer(mid, "flash")
	if not lf.is_empty():
		var fl := overlay(String(lf.get("color_token", "text_on_viewport")), "ScreenFlash")
		r.add_child(fl)
		targets["flash"] = fl
		made.append(fl)
	var ls := UI3Motion.layer(mid, "sweep")
	if not ls.is_empty() and not MetaState.reduce_flash and not UI3Motion.reduced():
		var sw := _sweep_bar(v, r, uid, mid, ls)
		if sw != null:
			targets["sweep"] = sw
			made.append(sw.get_parent() if sw.get_parent() != r else sw)
	var run := UI3Motion.play_timeline(mid, targets, {"host": r, "except": ["number", "shake"]})
	_track(v, mid, run)
	_free_after(run, made)


## Crit: a 120 px bar across the hit enemy's plate (clipped to it). Big hit: a 200 px bar across the screen.
static func _sweep_bar(v: CombatView, r: Control, uid: int, mid: String, ls: Dictionary) -> Control:
	var bar := ColorRect.new()
	bar.name = "LightSweep"
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.color = Color(UI3Theme.color(String(ls.get("color_token", "text_on_viewport"))), 1.0)
	bar.modulate.a = 0.0
	bar.rotation = deg_to_rad(20.0)   # skewX(-20deg) in the HTML
	var w := float(ls.get("width", 120.0))
	if mid == "big_hit":
		bar.size = Vector2(w, r.size.y * 1.4)
		bar.position = Vector2(0.0, -r.size.y * 0.2)
		r.add_child(bar)
		return bar
	var pt: Variant = v._portraits.get(uid)
	if not (pt is Control) or not is_instance_valid(pt):
		bar.free()
		return null
	var rect := (pt as Control).get_global_rect()
	var clip := Control.new()
	clip.name = "SweepClip"
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.position = rect.position
	clip.size = rect.size
	r.add_child(clip)
	bar.size = Vector2(w, rect.size.y * 1.6)
	bar.position = Vector2(0.0, -rect.size.y * 0.3)
	clip.add_child(bar)
	return bar


## Damage / shield numbers (CombatView._on_float_text, at impact). Returns true when this replaced the old float:
## "-12" / "CRIT -12" damage and "+6" shield. "PHASE 2" is dropped (the Phase band says it). Everything else
## (status words, heals, "0") keeps the old float.
static func float_text(v: CombatView, uid: int, text: String, css_class: String, _big: int) -> bool:
	if not on(v):
		return false
	if css_class == "deb" and text.begins_with("PHASE "):
		return true
	var mid := ""
	var shown := ""
	if css_class == "dmg":
		var m := RegEx.create_from_string(DMG_RE).search(text)
		if m == null:
			return false
		var value := int(m.get_string(3))
		mid = v._hit_moment_id(uid, value, m.get_string(1) != "")
		shown = str(value)
	elif css_class == "shd" and text.begins_with("+"):
		mid = "shield_gain"
		shown = text
	else:
		return false
	var l := UI3Motion.layer(mid, "number")
	if l.is_empty():
		return false
	var r := root(v)
	var lbl := hero_label(shown, String(l.get("size_token", "text_hero")), String(l.get("color_token", "text")))
	lbl.name = "HitNumber"
	r.add_child(lbl)
	_place_center(lbl, head(v, uid) + Vector2(0.0, -40.0))
	var run := UI3Motion.play_timeline(mid, {"number": lbl}, {"host": r, "only": ["number"]})
	_track(v, mid, run)
	_free_after(run, [lbl])
	return true


## Shield gained (CombatView._on_hp_changed when the shield goes up): bubble + rising glints. The "+N" is float_text.
static func shield_gain(v: CombatView, uid: int) -> void:
	if not on(v):
		return
	var r := root(v)
	var at := head(v, uid, 0.5)
	var b := Panel.new()
	b.name = "ShieldBubble"
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lb := UI3Motion.layer("shield_gain", "bubble")
	var col := UI3Theme.color(String(lb.get("color_token", "face_shield")))
	var sb := StyleBoxFlat.new()   # moment-only bubble: 140 px, 6 px ring, 13% fill (moment-shield.html)
	sb.bg_color = Color(col, 0.13)
	sb.border_color = col
	sb.set_border_width_all(6)
	sb.set_corner_radius_all(70)
	b.add_theme_stylebox_override("panel", sb)
	b.custom_minimum_size = Vector2(140, 140)
	b.modulate.a = 0.0
	r.add_child(b)
	_place_center(b, at)
	var fx := _fx_anchor(r, at)
	var run := UI3Motion.play_timeline("shield_gain", {"bubble": b, "fx": fx}, {"host": r, "except": ["number"]})
	_free_after(run, [b, fx])


## Party Axie knocked out (CombatView._on_unit_died, side "p"): red vignette pulse, "Knocked out" over the Axie,
## OUT stamp on its DieCard (stays while the Axie is down), screen shake.
static func axie_ko(v: CombatView, uid: int) -> void:
	if not on(v):
		return
	var r := root(v)
	var made: Array = []
	var lv := UI3Motion.layer("axie_ko", "vignette")
	var vig := overlay(String(lv.get("color_token", "danger_bg")), "KoVignette")
	r.add_child(vig)
	made.append(vig)
	var ll := UI3Motion.layer("axie_ko", "label")
	var lbl := hero_label(TranslationServer.translate(String(ll.get("text", "Knocked out"))),
		String(ll.get("size_token", "text_banner")), String(ll.get("color_token", "danger_text")))
	lbl.name = "KnockedOut"
	lbl.modulate.a = 0.0
	r.add_child(lbl)
	_place_center(lbl, head(v, uid) + Vector2(0.0, -24.0))
	made.append(lbl)
	var targets := {"vignette": vig, "label": lbl}
	var card := _die_card_for(v, uid)
	if card != null:
		var ls := UI3Motion.layer("axie_ko", "stamp")
		var st := U5KoStamp.make(v, uid, card, TranslationServer.translate(String(ls.get("text", "OUT"))),
			String(ls.get("color_token", "danger_text")))
		r.add_child(st)
		st.follow()
		targets["stamp"] = st
	var run := UI3Motion.play_timeline("axie_ko", targets, {"host": r, "shake": shake_cb(v)})
	_track(v, "axie_ko", run)
	_free_after(run, made)


## The DieCard (tray slot button) of party unit `uid`, or null.
static func _die_card_for(v: CombatView, uid: int) -> Control:
	if v._combat == null:
		return null
	var units: Array = v._party_dice_units()
	for k in mini(units.size(), v._die_slot_buttons.size()):
		if (units[k] as Unit).uid == uid:
			var b: Variant = v._die_slot_buttons[k]
			return b as Control if b is Control and is_instance_valid(b) else null
	return null


## Boss crosses a phase tick (CombatView._on_boss_phase_changed): hit-stop, screen flash, "Phase N" band over the
## boss's mid-body for ~1 s, shake, shell shards.
static func boss_phase(v: CombatView, uid: int) -> void:
	if not on(v):
		return
	var r := root(v)
	var row: Dictionary = UI3Motion.table().get("boss_phase", {})
	var made: Array = []
	var lf := UI3Motion.layer("boss_phase", "flash")
	var fl := overlay(String(lf.get("color_token", "text_on_viewport")), "ScreenFlash")
	r.add_child(fl)
	made.append(fl)
	var mid := head(v, uid, 0.5)
	var h := float(row.get("band_h", UI3Theme.size_of("banner_h")))
	var lb := UI3Motion.layer("boss_phase", "band")
	var b := band(String(lb.get("color_token", "plate")), mid.y - h * 0.5, h, "PhaseBand")
	b.modulate.a = 0.0
	r.add_child(b)
	var u: Unit = v._combat.by_uid(uid) if v._combat != null else null
	var n := int(u.custom_state.get("phase", 2)) if u != null else 2
	band_label(b, TranslationServer.translate(String(lb.get("text", "Phase %d"))) % n,
		String(lb.get("size_token", "text_hero")), String(lb.get("text_token", "text")), "plate_ink")
	made.append(b)
	var fx := _fx_anchor(r, mid)
	made.append(fx)
	var run := UI3Motion.play_timeline("boss_phase", {"flash": fl, "band": b, "fx": fx}, {"host": r, "shake": shake_cb(v)})
	_track(v, "boss_phase", run)
	_free_after(run, made)


## "Your turn" / "Enemy turn" band (CombatView._on_turn_phase_changed). on_done runs when the band is gone
## (at once when moments are off), e.g. the intent reveal after Your turn.
static func turn_banner(v: CombatView, player: bool, on_done := Callable()) -> void:
	if not on(v):
		if on_done.is_valid():
			on_done.call()
		return
	for old in root(v).get_children():
		if old is U5TurnBanner:
			(old as U5TurnBanner).finish(false)   # its reveal belongs to a turn that is already over
	U5TurnBanner.show_on(root(v), player, on_done)


## +80 ms per enemy (intent_reveal.delay_per_index_ms).
static func intent_stagger_sec() -> float:
	return float((UI3Motion.table().get("intent_reveal", {}) as Dictionary).get("delay_per_index_ms", 80)) / 1000.0


## Hide every live enemy's intent block until the reveal pops it (so it does not show, vanish and pop). The
## U5IntentHider re-hides blocks a plate rebuild brings back during the band, and restores stragglers later.
static func hide_intents(v: CombatView, until_sec: float) -> void:
	if not on(v) or v._combat == null:
		return
	U5IntentHider.start(root(v).get_parent(), v, until_sec + 0.5)


## The intent reveal starts (CombatView._reveal_intents): stop hiding the blocks.
static func reveal_started(v: Node) -> void:
	if v == null or not is_instance_valid(v):
		return
	var h := v.get_node_or_null(LAYER_NAME + "/IntentHider") as U5IntentHider
	if h != null:
		h.stop()


## Big-hit intent at reveal time: border flash (2 steps, cream over the red border), the BigHitStrip slides down,
## the "!" badge pops. Runs `delay_sec` after the reveal starts (same stagger as the pill).
static func intent_bighit(v: CombatView, p_in: UnitPortrait, delay_sec: float) -> void:
	if not on(v) or p_in == null or not is_instance_valid(p_in) or not p_in.is_big_hit():
		return
	var vw: WeakRef = weakref(v)
	var pw: WeakRef = weakref(p_in)
	var start := func() -> void:
		var v2: CombatView = vw.get_ref()
		var p: UnitPortrait = pw.get_ref()
		if p == null or v2 == null or not on(v2):
			return
		var r := root(v2)
		var targets := {}
		var made: Array = []
		var lbf := UI3Motion.layer("intent_reveal", "border_flash")
		var rect := p.get_global_rect()
		if rect.size.x > 0.0 and not lbf.is_empty():
			var ring := Panel.new()
			ring.name = "BigHitFlash"
			ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var sb := StyleBoxFlat.new()
			sb.draw_center = false
			sb.set_border_width_all(UI3Theme.stroke("selected"))   # the big-hit border is 4 px
			sb.border_color = UI3Theme.color(String(lbf.get("color_token", "text_on_viewport")))
			sb.set_corner_radius_all(UI3Theme.radius("l"))
			ring.add_theme_stylebox_override("panel", sb)
			ring.position = rect.position
			ring.size = rect.size
			ring.modulate.a = 0.0
			r.add_child(ring)
			targets["border"] = ring
			made.append(ring)
		var strip := p.find_child("BigHitStrip", true, false) as Control
		var sw: WeakRef = weakref(strip) if strip != null else null
		if strip != null and strip.is_visible_in_tree():
			targets["strip"] = strip
		var badge := p.find_child("BigHitBadge", true, false) as Control
		if badge != null and badge.is_visible_in_tree():
			badge.pivot_offset = badge.size * 0.5
			targets["badge"] = badge
		var settle := func() -> void:
			# the strip sits in a container: hand its position back to the layout once it has slid in
			var st: Control = sw.get_ref() if sw != null else null
			if st != null and st.get_parent() is Container:
				(st.get_parent() as Container).queue_sort()
		var run := UI3Motion.play_timeline("intent_reveal", targets, {"host": r, "except": ["pills"], "on_done": settle})
		_free_after(run, made)
	if delay_sec <= 0.0:
		start.call()
	else:
		v.get_tree().create_timer(delay_sec).timeout.connect(start)


## Victory (CombatView._on_combat_finished, won): the Victory band over a dimmed scene. Stays until end_victory.
static func victory(v: CombatView) -> void:
	if not on(v):
		return
	end_victory(v)
	var sub := "" if v._tutorial else TranslationServer.translate("%s cleared") % v._fight_title()
	U5VictoryBand.show_on(root(v), sub, shake_cb(v))


## The victory march (CombatView._play_victory_march) builds its own "Victory!" plate + Skip button: while the
## band is up it says the same thing, so they are hidden (Space / Enter / Esc / click still skip the march).
static func adopt_march_overlay(v: CombatView, march_ui: Node) -> void:
	if march_ui == null or not is_instance_valid(march_ui) or _victory_band(v) == null:
		return
	var title := march_ui.find_child("MarchTitle", true, false)
	var plate: Node = title.get_parent().get_parent() if title != null and title.get_parent() != null else null
	if plate is CanvasItem:
		(plate as CanvasItem).visible = false
	var skip := march_ui.find_child("MarchSkip", true, false)
	if skip is CanvasItem:
		(skip as CanvasItem).visible = false


static func end_victory(v: CombatView) -> void:
	var b := _victory_band(v)
	if b != null:
		b.queue_free()


static func _victory_band(v: Node) -> U5VictoryBand:
	var layer := v.get_node_or_null(LAYER_NAME)
	if layer == null:
		return null
	for c in (layer.get_node("Root") as Node).get_children():
		if c is U5VictoryBand and not (c as Node).is_queued_for_deletion():
			return c
	return null


## Defeat (CombatView._finish, lost, right after the DefeatPanel opens): red tint pulse over the panel's scrim,
## under the panel. The scrim and the panel's own entrance are the DefeatPanel's (motion row "defeat").
static func defeat(v: CombatView) -> void:
	if not on(v) or v._defeat == null or not is_instance_valid(v._defeat):
		return
	var lt := UI3Motion.layer("defeat", "tint")
	var tint := overlay(String(lt.get("color_token", "danger_bg")), "DefeatTint")
	v._defeat.add_child(tint)
	var scrim := v._defeat.get_node_or_null("Scrim")
	v._defeat.move_child(tint, scrim.get_index() + 1 if scrim != null else 0)
	var run := UI3Motion.play_timeline("defeat", {"tint": tint}, {"host": tint, "only": ["tint"]})
	_track(v, "defeat", run)
