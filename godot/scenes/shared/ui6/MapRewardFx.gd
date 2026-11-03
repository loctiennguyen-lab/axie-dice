class_name MapRewardFx
extends RefCounted
## UI-06 moment `map-reward` (motion-ui06.md "Map nodes / Treasure opens / Reward card in"). Static helpers, one per layer.
## Every tween is created on the node it animates and kept in meta "ui6_fx" (Array[Tween]), so `stop(node)` kills them and a
## node leaving the tree (tree_exiting) kills its loops. Reduce motion drops every layer the table marks "removed"
## (bob, breathe, sway, pop, shake, squash, sparkles) and keeps fade <= 120 ms / the end state; Reduce flashing keeps all of them.

const META := "ui6_fx"
const BOB_SEC := 1.6
const BREATHE_SEC := 2.0
const SWAY_SEC := 2.4


static func _reduced() -> bool:
	return UI3Motion.reduced() or UI3Gacha.is_instant()


## Tween bound to `node`, remembered in its meta, killed when the node leaves the tree.
static func _tween(node: Node) -> Tween:
	var tw := node.create_tween()
	var list: Array = node.get_meta(META, [])
	list = list.filter(func(t: Variant) -> bool: return t != null and (t as Tween).is_valid())
	list.append(tw)
	node.set_meta(META, list)
	if not node.tree_exiting.is_connected(stop.bind(node)):
		node.tree_exiting.connect(stop.bind(node))
	return tw


## Kill every tween this class started on `node`.
static func stop(node: Node) -> void:
	if not is_instance_valid(node):
		return
	for t in node.get_meta(META, []):
		if t != null and (t as Tween).is_valid():
			(t as Tween).kill()
	node.set_meta(META, [])


## Number of live tweens on `node` (tests).
static func live_count(node: Node) -> int:
	var n := 0
	for t in node.get_meta(META, []):
		if t != null and (t as Tween).is_valid() and (t as Tween).is_running():
			n += 1
	return n


## Current node: the glyph (not the token) bobs y 0 -> -4 -> 0, 1600 ms, loops. Removed under Reduce motion.
static func bob_glyph(glyph: Control) -> void:
	if glyph == null or _reduced():
		return
	stop(glyph)
	var rest := glyph.position.y
	var tw := _tween(glyph)
	tw.set_loops()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(glyph, "position:y", rest - 4.0, BOB_SEC * 0.5)
	tw.tween_property(glyph, "position:y", rest, BOB_SEC * 0.5)


## Boss helm (the glyph) breathes 1 -> 1.05 -> 1, 2000 ms, loops; call only when the boss is reachable.
static func breathe(glyph: Control) -> void:
	if glyph == null or _reduced():
		return
	stop(glyph)
	glyph.pivot_offset = glyph.size / 2.0
	var tw := _tween(glyph)
	tw.set_loops()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(glyph, "scale", Vector2.ONE * 1.05, BREATHE_SEC * 0.5)
	tw.tween_property(glyph, "scale", Vector2.ONE, BREATHE_SEC * 0.5)


## Map token hover: y -6 and scale x1.06 plus a 2 px cream ring fading in (140 ms cubic out). `rest_pos` / `rest_scale`
## are the token's rest. Reduce motion = end state at once (the ring fades in <= 120 ms).
static func hover_token(btn: Button, on: bool, rest_pos: Vector2, rest_scale: Vector2) -> void:
	if not is_instance_valid(btn):
		return
	var ring := btn.get_node_or_null("HoverRing") as Panel
	if ring == null:
		ring = Panel.new()
		ring.name = "HoverRing"
		ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sb := UI3Theme.flat(Color(0, 0, 0, 0), int(btn.size.x * 0.5) + 4, 2, UI3Theme.color("selected_outline"))
		sb.set_expand_margin_all(4.0)
		ring.add_theme_stylebox_override("panel", sb)
		ring.modulate.a = 0.0
		btn.add_child(ring)
	var to_pos := rest_pos + (Vector2(0, -6) if on else Vector2.ZERO)
	var to_scale := rest_scale * (1.06 if on else 1.0)
	var a := 1.0 if on else 0.0
	var key := "ui6_hover_tw"
	var old = btn.get_meta(key, null)
	if old is Tween and (old as Tween).is_valid():
		(old as Tween).kill()
	if _reduced():
		btn.position = to_pos
		btn.scale = to_scale
		var tr_ := btn.create_tween()
		btn.set_meta(key, tr_)
		tr_.tween_property(ring, "modulate:a", a, 0.1)
		return
	var tw := btn.create_tween()
	btn.set_meta(key, tw)
	tw.set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(btn, "position", to_pos, 0.14)
	tw.tween_property(btn, "scale", to_scale, 0.14)
	tw.tween_property(ring, "modulate:a", a, 0.14)


## Chest drops in y -60 -> 0 (320 ms back out). Reduce motion: fade <= 120 ms.
static func chest_drop(chest: Control) -> void:
	if chest == null:
		return
	var rest := chest.position.y
	if _reduced():
		chest.modulate.a = 0.0
		_tween(chest).tween_property(chest, "modulate:a", 1.0, 0.1)
		return
	chest.position.y = rest - 60.0
	var tw := _tween(chest)
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(chest, "position:y", rest, 0.32)


## Open pressed: shake +-4 deg x 2 (360 ms), then (at ~360 ms) pop (12 sparkles up, gravity 900) and squash (220 ms), then `done` at ~0.58 s.
## Reduce motion: no shake / sparkles / squash, `done` fires at once. `done` always fires exactly once.
static func chest_open(chest: Control, done: Callable) -> void:
	if chest == null or not chest.is_inside_tree() or _reduced():
		if done.is_valid():
			done.call()
		return
	chest.pivot_offset = chest.size / 2.0
	var tw := _tween(chest)
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var d := deg_to_rad(4.0)
	for a in [d, -d, d, -d]:
		tw.tween_property(chest, "rotation", a, 0.09)
	tw.tween_property(chest, "rotation", 0.0, 0.0)
	tw.tween_callback(func() -> void: sparkles(chest))
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(chest, "scale", Vector2(1.12, 0.88), 0.11)
	tw.tween_property(chest, "scale", Vector2.ONE, 0.11)
	tw.tween_callback(func() -> void:
		if done.is_valid():
			done.call())


## 12 sparkles thrown up from the middle of `host`, gravity 900 px/s^2 (own tweens on each sprite, freed after ~1 s).
static func sparkles(host: Control, count := 12) -> void:
	if host == null or not host.is_inside_tree() or _reduced():
		return
	var tex := UI6Assets.fx("sparkle", 32)
	var origin := host.size / 2.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 960   # presentation only, fixed so the capture repeats
	for i in count:
		var s := TextureRect.new()
		s.name = "Sparkle"
		s.texture = tex
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		s.custom_minimum_size = Vector2(20, 20)
		s.size = Vector2(20, 20)
		s.pivot_offset = Vector2(10, 10)
		s.position = origin - Vector2(10, 10)
		host.add_child(s, true)
		var v := Vector2(rng.randf_range(-180.0, 180.0), rng.randf_range(-520.0, -320.0))
		var t := 0.9
		var tw := s.create_tween()
		tw.set_parallel(true)
		tw.tween_method(func(k: float) -> void:
			s.position = origin - Vector2(10, 10) + Vector2(v.x * k, v.y * k + 450.0 * k * k), 0.0, t, t)
		tw.tween_property(s, "modulate:a", 0.0, 0.3).set_delay(t - 0.3)
		tw.chain().tween_callback(s.queue_free)


## Reward card art pops 0.7 -> 1.08 -> 1 (260 ms back out, starts 200 ms after the card). Reduce motion: nothing.
static func art_pop(art: Control, delay := 0.2) -> void:
	if art == null or _reduced():
		return
	art.scale = Vector2.ONE * 0.7
	var tw := _tween(art)
	tw.tween_callback(func() -> void: art.pivot_offset = art.size / 2.0)   # after layout
	tw.tween_interval(delay)
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(art, "scale", Vector2.ONE * 1.08, 0.13)
	tw.tween_property(art, "scale", Vector2.ONE, 0.13)


## Idle sway +-1.5 deg, 2400 ms loop, only on the hovered card; `art` is the illustration. Stops on exit.
static func sway(art: Control, on: bool) -> void:
	if art == null:
		return
	var old = art.get_meta("ui6_sway_tw", null)
	if old is Tween and (old as Tween).is_valid():
		(old as Tween).kill()
	art.rotation = 0.0
	if not on or _reduced():
		return
	art.pivot_offset = art.size / 2.0
	var tw := _tween(art)
	art.set_meta("ui6_sway_tw", tw)
	var r := deg_to_rad(1.5)
	tw.set_loops()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(art, "rotation", r, SWAY_SEC * 0.25)
	tw.tween_property(art, "rotation", -r, SWAY_SEC * 0.5)
	tw.tween_property(art, "rotation", 0.0, SWAY_SEC * 0.25)


## Wire the hover sway of a reward card's illustration to the card's mouse enter / exit.
static func wire_card(card: Control, art: Control) -> void:
	if card == null or art == null:
		return
	card.mouse_entered.connect(sway.bind(art, true))
	card.mouse_exited.connect(sway.bind(art, false))
	art_pop(art)
