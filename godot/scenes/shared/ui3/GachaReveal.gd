class_name GachaReveal
extends Node
## Face-down cards -> tier halo -> flip left to right. Any click / Space / Enter skips to the end (and is consumed).
## Reduce flashing: no halo pulse, no shake, no sparkles. Test hooks: `events`, `running`.

signal finished

var events: Array[String] = []
var running := false
var _cards: Array = []
var _covers: Array = []
var _tier := 0
var _from := -1
var _plan: Dictionary = {}
var _tween: Tween
var _shake_host: Control
var _pulses: Array[Tween] = []
var _sparkles: Array[Control] = []


## cards: Controls (PanelContainer cards whose first child is the content column). shake_host: node to jiggle on jackpot.
func start(cards: Array, tier: int, first: bool, jackpot: bool, shake_host: Control = null, flip_sec := -1.0, from_tier := -1) -> void:
	_cards = cards
	_tier = tier
	_from = from_tier
	_shake_host = shake_host
	var reduce := MetaState.reduce_flash
	_plan = UI3Gacha.plan(cards.size(), tier, first, jackpot, reduce, flip_sec, from_tier)
	if UI3Gacha.is_instant():
		events.append("instant")
		_done()
		return
	running = true
	var near := from_tier > tier
	events.append("aura")
	UI3Gacha.play_sfx(self, UI3Gacha.TIER_KEY[clampi(from_tier if near else tier, 0, 2)])
	var reason_given := false
	for c in cards:
		var card := c as Control
		var col := card.get_child(0) as Control
		col.modulate.a = 0.0
		# Only a card the Crystal cap really pulled down (it sits at the offer's tier) holds the higher aura and cracks;
		# a lower card of the same offer (e.g. Moss) is not demoted and keeps its own tier look.
		var ct := int(card.get_meta("gacha_tier", tier))
		var demoted := near and ct == tier
		var cover := UI3Gacha.build_cover(ct, from_tier if demoted else -1, demoted and not reason_given)
		cover.set_meta("demoted", demoted)
		reason_given = reason_given or demoted
		card.add_child(cover)
		_covers.append(cover)
		var halo := cover.get_node("Halo") as Panel
		var tw := create_tween()
		tw.tween_property(halo, "modulate:a", 1.0, minf(0.3, float(_plan["aura"])))
		if not reduce:
			var pulse := create_tween().set_loops()
			_pulses.append(pulse)
			pulse.tween_property(halo, "self_modulate:a", 0.45, 0.35)
			pulse.tween_property(halo, "self_modulate:a", 1.0, 0.35)
	_tween = create_tween()
	# One timeline: sleep to each flip start.
	var t := 0.0
	if near:
		_tween.tween_interval(float(_plan["crack_at"]))
		_tween.tween_callback(_crack)
		t = float(_plan["crack_at"])
	for i in cards.size():
		var at := float(_plan["flips"][i])
		_tween.tween_interval(at - t)
		t = at
		_tween.tween_callback(_flip.bind(i))
	_tween.tween_interval(float(_plan["total"]) - t)
	_tween.tween_callback(_done)


## Near-miss: the cap-held higher border breaks into the real tier, short reason line, small shake.
func _crack() -> void:
	events.append("crack")
	UI3Gacha.play_sfx(self, "near_miss")
	for k in _covers.size():
		var cv := _covers[k] as Control
		if not is_instance_valid(cv) or not bool(cv.get_meta("demoted", false)):
			continue
		var real := UI3Gacha.tier_color(int(_cards[k].get_meta("gacha_tier", _tier)))
		var st := cv.get_meta("style") as StyleBoxFlat
		var w := cv.find_child("TierWord", true, false) as Label
		if st != null:
			st.border_color = real
		if w != null:
			w.text = UI3Gacha.tr_word(int(_cards[k].get_meta("gacha_tier", _tier)))
			w.add_theme_color_override("font_color", real)
		(cv.find_child("Halo", true, false) as Panel).add_theme_stylebox_override("panel",
			UI3Theme.flat(Color(0, 0, 0, 0), UI3Theme.radius("l") + 8, UI3Theme.stroke("hairline"), real))
		var why := cv.find_child("ReasonLine", true, false) as Control
		if why != null:
			create_tween().tween_property(why, "modulate:a", 1.0, 0.15)
		_crack_lines(cv)
		if not MetaState.reduce_flash:
			var base := cv.position
			var tw := create_tween()
			for j in 4:
				tw.tween_property(cv, "position", base + Vector2(4 if j % 2 == 0 else -4, 0), 0.04)
			tw.tween_property(cv, "position", base, 0.04)


## Visible fracture: dark jagged strokes that cut across the border at three spots (flat Line2D, no shader).
func _crack_lines(cv: Control) -> void:
	var sz := cv.size
	var ink := UI3Theme.color("bg")
	var spots: Array = [
		[Vector2(sz.x * 0.28, -6), Vector2(sz.x * 0.31, 14), Vector2(sz.x * 0.26, 30), Vector2(sz.x * 0.30, 46)],
		[Vector2(sz.x + 6, sz.y * 0.35), Vector2(sz.x - 14, sz.y * 0.38), Vector2(sz.x - 30, sz.y * 0.33), Vector2(sz.x - 46, sz.y * 0.37)],
		[Vector2(sz.x * 0.7, sz.y + 6), Vector2(sz.x * 0.67, sz.y - 14), Vector2(sz.x * 0.72, sz.y - 30), Vector2(sz.x * 0.68, sz.y - 46)]]
	for pts in spots:
		var ln := Line2D.new()
		ln.name = "CrackLine"
		ln.width = 8.0
		ln.default_color = ink
		ln.joint_mode = Line2D.LINE_JOINT_SHARP
		for pt in pts:
			ln.add_point(pt)
		cv.add_child(ln)


func _flip(i: int) -> void:
	if i >= _cards.size() or not is_instance_valid(_cards[i]):
		return
	events.append("flip:%d" % i)
	var card := _cards[i] as Control
	card.pivot_offset = card.size / 2.0
	var half := float(_plan["flip"]) / 2.0
	var tw := create_tween()
	tw.tween_property(card, "scale:x", 0.0, half)
	tw.tween_callback(_reveal.bind(i))
	tw.tween_property(card, "scale:x", 1.0, half)
	if i == _cards.size() - 1 and bool(_plan["jackpot"]):
		tw.tween_callback(_jackpot)


func _kill_pulses() -> void:
	for pt in _pulses:
		if pt.is_valid():
			pt.kill()
	_pulses.clear()


func _reveal(i: int) -> void:
	if i < _pulses.size():
		_pulses[i].kill()
	if i < _covers.size() and is_instance_valid(_covers[i]):
		(_covers[i] as Node).queue_free()
	if is_instance_valid(_cards[i]):
		((_cards[i] as Control).get_child(0) as Control).modulate.a = 1.0


func _jackpot() -> void:
	events.append("jackpot")
	UI3Gacha.play_sfx(self, "jackpot")
	# Gold ring + sparkles on the card(s) that complete a combo, plus a shake of the whole card row.
	for c in _cards:
		if is_instance_valid(c) and bool((c as Control).get_meta("jackpot_card", false)):
			_sparkle(c as Control)
	if _shake_host == null or not is_instance_valid(_shake_host):
		return
	var px := float(UI3Gacha.timing().get("shake_px", 10))
	var base := _shake_host.position
	var tw := create_tween()
	for k in 8:
		tw.tween_property(_shake_host, "position", base + Vector2(px if k % 2 == 0 else -px, 0), 0.06)
	tw.tween_property(_shake_host, "position", base, 0.05)


## Flat gold diamonds popping around the card edge + a gold ring that pulses twice. No shader, no gradient.
func _sparkle(card: Control) -> void:
	var holder := Control.new()
	holder.name = "Sparkles"
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.z_index = 5
	card.add_child(holder)
	_sparkles.append(holder)
	var gold := UI3Theme.color("accent")
	# The card (a PanelContainer) squeezes its children into the padded content rect: put everything in a free
	# "Inner" Control that is moved back to the card's own top-left corner and sized to the whole card.
	var off := card.get_theme_stylebox("panel").get_offset() if card.get_theme_stylebox("panel") != null else Vector2.ZERO
	var inner := Control.new()
	inner.name = "Inner"
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.position = -off
	inner.size = card.size
	holder.add_child(inner)
	var ring := Panel.new()
	ring.name = "JackpotRing"
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.position = Vector2(-14, -14)
	ring.size = card.size + Vector2(28, 28)
	ring.add_theme_stylebox_override("panel", UI3Theme.flat(Color(0, 0, 0, 0), UI3Theme.radius("l") + 14, 8, gold))
	inner.add_child(ring)
	var rt := create_tween().set_loops(3)
	rt.tween_property(ring, "modulate:a", 0.25, 0.2)
	rt.tween_property(ring, "modulate:a", 1.0, 0.2)
	var sz := card.size
	var rng := RandomNumberGenerator.new()   # cosmetic only, never the run rng
	rng.seed = 7
	for i in 18:
		var d := ColorRect.new()
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		d.color = gold if i % 3 != 0 else UI3Theme.color("text")
		var s := float(rng.randi_range(14, 28))
		d.size = Vector2(s, s)
		d.pivot_offset = d.size / 2.0
		d.rotation = PI / 4.0
		# around the edge band of the card, half outside
		var edge := i % 4
		var fx := rng.randf()
		var fy := rng.randf()
		var pos := Vector2(fx * sz.x, fy * sz.y)
		match edge:
			0: pos.y = -s * 0.5 - rng.randf() * 18.0
			1: pos.y = sz.y - s * 0.5 + rng.randf() * 18.0
			2: pos.x = -s * 0.5 - rng.randf() * 18.0
			3: pos.x = sz.x - s * 0.5 + rng.randf() * 18.0
		d.position = pos
		d.scale = Vector2.ZERO
		inner.add_child(d)
		var tw := create_tween()
		tw.tween_interval(rng.randf() * 0.5)
		tw.tween_property(d, "scale", Vector2.ONE, 0.18)
		tw.tween_property(d, "rotation", PI / 4.0 + PI / 2.0, 0.5)
		tw.tween_property(d, "scale", Vector2.ZERO, 0.22)


## Jump to the final state.
func skip() -> void:
	if not running:
		return
	events.append("skip")
	if _tween != null:
		_tween.kill()
	for i in _cards.size():
		if is_instance_valid(_cards[i]):
			(_cards[i] as Control).scale = Vector2.ONE
			_reveal(i)
	_done()


func _done() -> void:
	running = false
	_kill_pulses()
	for cv in _covers:
		if is_instance_valid(cv):
			(cv as Node).queue_free()
	_covers.clear()
	for sp in _sparkles:
		if is_instance_valid(sp):
			sp.queue_free()
	_sparkles.clear()
	for c in _cards:
		if is_instance_valid(c):
			(c as Control).scale = Vector2.ONE
			((c as Control).get_child(0) as Control).modulate.a = 1.0
	finished.emit()


func _input(ev: InputEvent) -> void:
	if not running:
		return
	if (ev is InputEventMouseButton and ev.pressed) or (ev is InputEventKey and ev.pressed and not ev.echo \
			and (ev.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER])):
		get_viewport().set_input_as_handled()
		skip()
