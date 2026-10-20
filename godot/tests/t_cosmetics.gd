extends Node
## Gate for cosmetic art (Cosmetics v7): every cosmetic id the game names resolves to files,
## manifest and files agree, textures are the expected size and have alpha.
## Run: godot --headless --path godot res://tests/t_cosmetics.tscn

var _fail := 0
var _n := 0


func _ok(c: bool, msg: String) -> void:
	_n += 1
	if not c:
		_fail += 1
		print("FAIL: ", msg)


func _ready() -> void:
	var m := CosmeticArt.manifest()
	var dice: Dictionary = m.get("dice", {})
	var frames: Dictionary = m.get("frames", {})
	_ok(dice.size() == 26 and frames.size() == 27, "26 dice + 27 frames (%d/%d)" % [dice.size(), frames.size()])
	_ok(not CosmeticArt.animation_pending(), "animated layers delivered")
	_ok(is_equal_approx(float(m.get("frame_scale", 0)), 1.5), "manifest frame_scale 1.5")

	# frames: every layer file exists, 256 RGBA, window Ø162 is transparent, no loose file left behind
	var referenced := {}
	for id in frames:
		var e: Dictionary = frames[id]
		var ls := CosmeticArt.layers(id)
		_ok(ls.size() == (e.get("files", []) as Array).size() and ls.size() >= 1, "%s: all %d layer files resolve" % [id, (e.get("files", []) as Array).size()])
		_ok(int(e.get("window_diameter_px", 0)) == 162 and int(e.get("size", 0)) == 256, "%s: window 162 of 256" % id)
		_ok(ls.filter(func(l): return String(l.layer) == "base").size() == 1, "%s has one base layer" % id)
		for l in ls:
			referenced[l.path] = true
			_check_tex(l.path, 256)
			_ok(not (l.add as bool), "%s.%s is a normal-blend layer" % [id, l.layer])
			if l.layer != "base":
				var spec := CosmeticArt.anim_spec(id, String(l.layer))
				_ok(not spec.is_empty() or String(l.layer) == "base", "%s.%s has an anim spec" % [id, l.layer])
				for sp in spec:
					_ok(["spin", "pulse", "sweep"].has(sp.type) and bool(sp.get("reduce_static", false)), "%s.%s anim type %s, held when Reduce flashing" % [id, l.layer, sp.type])
					if sp.type == "pulse":
						_ok(float(sp.period) >= 1.4, "%s.%s pulse period %.1f >= 1.4 s" % [id, l.layer, float(sp.period)])
			var img := (load(l.path) as Texture2D).get_image()
			var edge_max := 0.0   # outer 4 px of the 256 px layer must be fully transparent (R4 margin rule)
			for k in 256:
				for d in 4:
					edge_max = maxf(edge_max, maxf(maxf(img.get_pixel(k, d).a, img.get_pixel(k, 255 - d).a),
						maxf(img.get_pixel(d, k).a, img.get_pixel(255 - d, k).a)))
			_ok(edge_max == 0.0, "%s.%s: outer 4 px are transparent (max alpha %.3f)" % [id, l.layer, edge_max])
			_ok(img.get_pixel(128, 128).a < 0.02 and img.get_pixel(128 + 70, 128).a < 0.02 and img.get_pixel(128, 128 - 70).a < 0.02,
				"%s.%s: window stays clear (r <= 70)" % [id, l.layer])
	for f in DirAccess.get_files_at("res://assets/cosmetics/frames"):
		if f.ends_with(".png"):
			_ok(referenced.has("res://assets/cosmetics/frames/" + f), "frames/%s is referenced" % f)

	# every cosmetic id named in economy data resolves (fx_*, title_*, std_* have no art by design)
	var named := {}
	for f in DirAccess.get_files_at("res://assets/data/economy"):
		if f.ends_with(".json"):
			var txt := FileAccess.get_file_as_string("res://assets/data/economy/" + f)
			var re := RegEx.create_from_string("\"((?:die|frame)_[a-z0-9_]+)\"")
			for r in re.search_all(txt):
				named[r.get_string(1)] = true
	_ok(named.size() >= 13, "found named cosmetic ids (%d)" % named.size())
	for id in named:
		_ok(CosmeticArt.has_art(id), "id resolves: " + id)

	# placeholder pool ids and non-art ids stay empty, never crash
	for id in ["std_e_001", "fx_e_rune", "title_s1_echo", "frame_x_nope"]:
		_ok(CosmeticArt.layers(id).is_empty() and CosmeticArt.make_node(id, 64) == null, "no art, no node: " + id)

	# anchor rule: frame = avatar x 1.5, centred (Cosmetics R2)
	for pair in [[40.0, 60.0, -10.0], [48.0, 72.0, -12.0], [64.0, 96.0, -16.0], [96.0, 144.0, -24.0], [160.0, 240.0, -40.0]]:
		_ok(is_equal_approx(AvatarFrame.frame_size(pair[0]), pair[1]) and AvatarFrame.frame_offset(pair[0]).is_equal_approx(Vector2(pair[2], pair[2])),
			"avatar %d -> frame %d at %d" % [pair[0], pair[1], pair[2]])
	var av := Panel.new()
	var h := AvatarFrame.wrap_holder(av, 48.0, "frame_e_firefly")
	var fnode: Control = h.get_child(1)
	_ok(h.custom_minimum_size == Vector2(48, 48) and fnode.size == Vector2(72, 72) and fnode.position == Vector2(-12, -12),
		"Land chip holder stays 48, frame node 72 at -12")
	_ok(fnode.mouse_filter == Control.MOUSE_FILTER_IGNORE and not h.clip_contents, "frame ignores the mouse, holder does not clip")
	_ok(fnode.get_child_count() == 3, "firefly node stacks 3 layers")
	h.free()
	var plain := Panel.new()
	_ok(AvatarFrame.wrap_holder(plain, 48.0, "") == plain, "no frame: the avatar itself")
	plain.free()

	# Reduce flashing: no Tweens, held values from the spec
	MetaState.reduce_flash = true
	var sn := CosmeticArt.make_node("frame_m_eclipse", 150)
	add_child(sn)
	await get_tree().create_timer(0.3).timeout
	_ok(is_equal_approx(sn.get_node("shadow").modulate.a, 0.0) and is_equal_approx(sn.get_node("corona").modulate.a, 0.0), "reduce: eclipse layers held at 0")
	sn.queue_free()
	var rn := CosmeticArt.make_node("frame_e_runering", 150)
	add_child(rn)
	await get_tree().create_timer(0.3).timeout
	_ok(is_equal_approx(rn.get_node("runes").rotation, 0.0) and is_equal_approx(rn.get_node("glow").modulate.a, 0.68), "reduce: runes rotation 0, glow 0.68")
	rn.queue_free()
	MetaState.reduce_flash = false
	var fn := CosmeticArt.make_node("frame_e_runering", 150)
	add_child(fn)
	await get_tree().create_timer(1.0).timeout
	_ok(fn.get_node("runes").rotation != 0.0, "motion on: runes turn")
	fn.queue_free()
	print("t_cosmetics: %d checks, %d failed" % [_n, _fail])
	print("PASS" if _fail == 0 else "FAIL")
	get_tree().quit(0 if _fail == 0 else 1)


func _check_tex(path: String, px: int, need_alpha := true) -> void:
	var t := load(path) as Texture2D
	_ok(t != null, "loads " + path)
	if t:
		_ok(t.get_width() == px and t.get_height() == px, "%s is %dx%d" % [path, px, px])
		if need_alpha:
			_ok(t.get_image().detect_alpha() != Image.ALPHA_NONE, "%s has alpha" % path)
