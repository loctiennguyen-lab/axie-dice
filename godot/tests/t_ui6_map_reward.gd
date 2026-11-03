extends Node
## UI-06 moment map-reward (MapRewardFx): the node bob / boss breathe loops die when the node leaves the tree, Reduce motion
## removes bob / sway / pop / shake (and `done` still fires), the hover ring appears, no tween is left behind after stop().
var _checks := 0
var _fails: Array[String] = []


func _ok(c: bool, m: String) -> void:
	_checks += 1
	if not c:
		_fails.append(m)


func _frames(n := 3) -> void:
	for _i in n:
		await get_tree().process_frame


func _ready() -> void:
	print("=== t_ui6_map_reward: start ===")
	var was := MetaState.reduce_motion
	UI3Gacha.instant_override = 0
	MetaState.reduce_motion = false
	var host := Control.new()
	host.size = Vector2(400, 400)
	add_child(host)

	# bob: loops, then dies with the node
	var glyph := TextureRect.new()
	glyph.size = Vector2(32, 32)
	host.add_child(glyph)
	MapRewardFx.bob_glyph(glyph)
	await _frames()
	_ok(MapRewardFx.live_count(glyph) == 1, "bob runs one loop")
	await get_tree().create_timer(0.4).timeout
	_ok(glyph.position.y < -0.5, "glyph moved up (%.2f)" % glyph.position.y)
	var tw: Tween = glyph.get_meta(MapRewardFx.META)[0]
	host.remove_child(glyph)   # leaves the tree without being freed
	_ok(not tw.is_valid() or not tw.is_running(), "bob stops when the node leaves the tree")
	_ok(MapRewardFx.live_count(glyph) == 0, "no live tween after leaving the tree")
	glyph.free()

	# breathe
	var helm := TextureRect.new()
	helm.size = Vector2(56, 56)
	host.add_child(helm)
	MapRewardFx.breathe(helm)
	await get_tree().create_timer(0.5).timeout
	_ok(helm.scale.x > 1.0, "helm breathes")
	MapRewardFx.stop(helm)
	_ok(MapRewardFx.live_count(helm) == 0, "stop() kills the breathe loop")
	helm.queue_free()

	# hover ring + lift
	var btn := Button.new()
	btn.size = Vector2(56, 56)
	btn.position = Vector2(100, 100)
	host.add_child(btn)
	MapRewardFx.hover_token(btn, true, Vector2(100, 100), Vector2.ONE)
	await get_tree().create_timer(0.25).timeout
	_ok(is_equal_approx(btn.position.y, 94.0) and is_equal_approx(btn.scale.x, 1.06), "hover lifts -6 and 1.06 (%s %s)" % [btn.position, btn.scale])
	_ok(btn.get_node_or_null("HoverRing") != null and (btn.get_node("HoverRing") as Control).modulate.a > 0.99, "cream ring shown")
	MapRewardFx.hover_token(btn, false, Vector2(100, 100), Vector2.ONE)
	await get_tree().create_timer(0.25).timeout
	_ok(is_equal_approx(btn.position.y, 100.0) and (btn.get_node("HoverRing") as Control).modulate.a < 0.01, "hover off restores")

	# sway: only while hovered, rests at 0 after
	var art := Panel.new()
	art.size = Vector2(80, 80)
	host.add_child(art)
	MapRewardFx.sway(art, true)
	await get_tree().create_timer(0.7).timeout
	_ok(absf(art.rotation) > 0.005, "sway rotates while hovered")
	MapRewardFx.sway(art, false)
	_ok(art.rotation == 0.0 and MapRewardFx.live_count(art) == 0, "sway off: rest, no tween")

	# art pop
	MapRewardFx.art_pop(art, 0.0)
	_ok(is_equal_approx(art.scale.x, 0.7), "art pop starts at 0.7")
	await get_tree().create_timer(0.5).timeout
	_ok(is_equal_approx(art.scale.x, 1.0), "art pop ends at 1")

	# chest: shake + sparkles, then done once
	var chest := Panel.new()
	chest.size = Vector2(100, 100)
	host.add_child(chest)
	var done := [0]
	MapRewardFx.chest_open(chest, func() -> void: done[0] += 1)
	await get_tree().create_timer(0.2).timeout
	_ok(done[0] == 0, "done waits for the shake")
	await get_tree().create_timer(0.35).timeout
	var nsp := chest.find_children("Sparkle*", "TextureRect", false, false).size()
	_ok(nsp == 12, "12 sparkles popped (%d, children %d)" % [nsp, chest.get_child_count()])
	await get_tree().create_timer(0.6).timeout
	_ok(done[0] == 1, "done fired once after the squash")
	await get_tree().create_timer(1.0).timeout
	_ok(chest.find_children("Sparkle*", "", false, false).is_empty(), "sparkles freed")

	# Reduce motion: nothing moves, done at once, no tween left
	MetaState.reduce_motion = true
	var g2 := TextureRect.new()
	g2.size = Vector2(32, 32)
	host.add_child(g2)
	MapRewardFx.bob_glyph(g2)
	MapRewardFx.breathe(g2)
	MapRewardFx.sway(g2, true)
	MapRewardFx.art_pop(g2, 0.0)
	_ok(MapRewardFx.live_count(g2) == 0 and g2.scale == Vector2.ONE, "reduced: no bob / breathe / sway / pop")
	var chest2 := Panel.new()
	chest2.size = Vector2(100, 100)
	host.add_child(chest2)
	done[0] = 0
	MapRewardFx.chest_open(chest2, func() -> void: done[0] += 1)
	_ok(done[0] == 1 and chest2.rotation == 0.0 and chest2.find_children("Sparkle*", "", false, false).is_empty(), "reduced: opens at once, no shake / sparkles")
	MapRewardFx.chest_drop(chest2)
	_ok(chest2.position.y == 0.0, "reduced: chest drop does not move")
	var b2 := Button.new()
	b2.size = Vector2(56, 56)
	host.add_child(b2)
	MapRewardFx.hover_token(b2, true, Vector2.ZERO, Vector2.ONE)
	_ok(is_equal_approx(b2.position.y, -6.0), "reduced: hover = end state at once")

	MetaState.reduce_motion = was
	UI3Gacha.instant_override = -1
	host.queue_free()
	print("=== t_ui6_map_reward: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	for f in _fails:
		print("FAIL: ", f)
	if _fails.is_empty():
		print("t_ui6_map_reward: PASS")
	get_tree().quit(0 if _fails.is_empty() else 1)
