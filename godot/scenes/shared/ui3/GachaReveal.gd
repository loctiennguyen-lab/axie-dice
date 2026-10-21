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
	for c in cards:
		var card := c as Control
		var col := card.get_child(0) as Control
		col.modulate.a = 0.0
		var cover := UI3Gacha.build_cover(int(card.get_meta("gacha_tier", tier)), from_tier)
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
		if not is_instance_valid(cv):
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
		if not MetaState.reduce_flash:
			var base := cv.position
			var tw := create_tween()
			for j in 4:
				tw.tween_property(cv, "position", base + Vector2(4 if j % 2 == 0 else -4, 0), 0.04)
			tw.tween_property(cv, "position", base, 0.04)


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
	if _shake_host == null or not is_instance_valid(_shake_host):
		return
	var px := float(UI3Gacha.timing().get("shake_px", 6))
	var base := _shake_host.position
	var tw := create_tween()
	for k in 6:
		tw.tween_property(_shake_host, "position", base + Vector2(px if k % 2 == 0 else -px, 0), 0.08)
	tw.tween_property(_shake_host, "position", base, 0.05)


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
