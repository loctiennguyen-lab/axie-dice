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
	_ok(dice.size() == 20 and frames.size() == 21, "20 dice + 21 frames (%d/%d)" % [dice.size(), frames.size()])
	_ok(not m.has("frames_with_art") and not m.has("frames_waiting_for_art"), "old frame keys gone")
	_ok(not CosmeticArt.animation_pending(), "animated layers delivered (v8)")

	# every layer file exists, right size, has alpha, no loose file left unreferenced
	var referenced := {}
	for id in dice:
		var ls := CosmeticArt.layers(id)
		var want: Array = ["plate"] if int(dice[id].tier) <= 2 else ["base", "glow"] + (["max"] if int(dice[id].tier) == 5 else [])
		_ok(ls.map(func(l): return l.layer) == want, "%s layers %s" % [id, want])
		for l in ls:
			referenced[l.path] = true
			# plates/base are full-bleed opaque squares (the die token masks them); glow/max overlays carry alpha
			_check_tex(l.path, 512, l.layer != "plate" and l.layer != "base")
			_ok((l.add as bool) == (l.layer == "glow"), "%s glow is additive only" % id)
	for id in frames:
		var ls := CosmeticArt.layers(id)
		_ok(ls.size() >= 1 and ls[0].layer == "base", "%s has base" % id)
		var al: Array = frames[id].get("anim_layers", [])
		_ok(ls.size() == 1 + al.size(), "%s lists base + %d anim layers (%d)" % [id, al.size(), ls.size()])
		_ok(ls.map(func(l): return l.layer).slice(1) == al.map(func(a): return a.name), "%s layer names match anim_layers" % id)
		for a in al:
			_ok(not CosmeticArt.anim_spec(id, a.name).is_empty(), "%s.%s has an anim spec" % [id, a.name])
			for sp in CosmeticArt.anim_spec(id, a.name):
				_ok(["spin", "pulse", "sweep"].has(sp.type), "%s.%s anim type %s" % [id, a.name, sp.type])
		for pf in frames[id].get("preview_files", []):
			referenced["res://assets/cosmetics/" + String(pf)] = true
		for l in ls:
			referenced[l.path] = true
			_check_tex(l.path, 256)
	for sub in ["dice", "frames"]:
		for f in DirAccess.get_files_at("res://assets/cosmetics/" + sub):
			if f.ends_with(".png"):
				_ok(referenced.has("res://assets/cosmetics/%s/%s" % [sub, f]), "unreferenced file " + f)

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
		_ok(CosmeticArt.has_art(id) and not CosmeticArt.layers(id).is_empty(), "id resolves: " + id)

	# placeholder pool ids and non-art ids stay empty, never crash
	for id in ["std_e_001", "fx_e_rune", "title_s1_echo", "frame_x_nope"]:
		_ok(CosmeticArt.layers(id).is_empty() and CosmeticArt.make_node(id, 64) == null, "no art, no node: " + id)
	var fn := CosmeticArt.make_node("frame_e_runering", 150)
	_ok(fn != null and fn.get_child_count() == 3 and fn.get_node("rune_orbit") is TextureRect, "runering node stacks base + 2 layers")
	if fn:
		fn.free()
	var n := CosmeticArt.make_node("die_m_moon", 104)
	_ok(n != null and n.get_child_count() == 3, "moon die node has 3 layers")
	_ok(n != null and (n.get_node("glow") as TextureRect).material is CanvasItemMaterial, "glow layer additive")
	if n:
		n.free()
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
