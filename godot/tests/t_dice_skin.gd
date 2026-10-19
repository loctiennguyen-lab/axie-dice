extends Node
## Cosmetics R2 dice skins: loader, ids vs files vs manifest, cache key, value auto-fit with real font metrics,
## body / face materials from the spec, tile trims, thumbnails cache name. Headless.

var _fails: Array[String] = []
var _checks := 0


func _ok(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_fails.append(msg)
		print("FAIL: ", msg)


func _ready() -> void:
	print("=== t_dice_skin: start ===")
	var ids := DiceSkin.ids()
	_ok(ids.size() == 20, "20 skins (%d)" % ids.size())
	var man: Dictionary = CosmeticArt.manifest().get("dice", {})
	for id in ids:
		_ok(man.has(id), "%s is in cosmetics_manifest dice (ids unchanged)" % id)
		_ok(DiceSkin.display_name(id) == String((man[id] as Dictionary).get("name", "")), "%s name is the same in both data files" % id)
		for f in ["albedo.png", "normal.png", "plate.png", "plate_normal.png", "tile_trim_88.png", "tile_trim_56.png", "egg_trim_36.png"]:
			_ok(DiceSkin.has_file(id, f) and ResourceLoader.exists(DiceSkin.ROOT + id + "/" + f), "%s has %s" % [id, f])
		var tier := DiceSkin.tier(id)
		_ok(tier == id.split("_")[1], "%s tier letter matches id" % id)
		_ok(DiceSkin.has_file(id, "plate_emit.png") == (tier in ["e", "l", "m"]), "%s: plate_emit only on Epic+" % id)
		for k in (DiceSkin.info(id).get("files", []) as Array):
			_ok(ResourceLoader.exists(DiceSkin.ROOT + id + "/" + String(k)), "%s file listed exists: %s" % [id, k])
	_ok(not DiceSkin.has("die_x_nope") and DiceSkin.texture("die_x_nope", "albedo.png") == null, "unknown skin: no texture")

	# cache key carries the skin
	var f := {"type": "dmg", "value": 5}
	_ok(DiceRoller3D._key(f) == "dmg:5", "no skin key is the old one")
	_ok(DiceRoller3D._key(f, "die_c_reed") == "die_c_reed|dmg:5", "skin id is in the key")
	_ok(DiceRoller3D._key(f, "die_c_reed") != DiceRoller3D._key(f, "die_r_aqua"), "two skins never share a plate")

	# auto-fit with real Rowdies metrics, floor 44
	var font := UI3Theme.font_display()
	var box := DiceRoller3D.VALUE_BOX.size.x
	for txt in ["1", "5", "12", "88", "99", "188", "999", "1000"]:
		var fs := DiceRoller3D.fit_value_font(txt, font)
		var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		_ok(fs >= DiceRoller3D.VALUE_FONT_MIN and fs <= DiceRoller3D.VALUE_FONT, "%s: size %d inside 44..80" % [txt, fs])
		if fs > DiceRoller3D.VALUE_FONT_MIN:
			_ok(w <= box + 1.0, "%s at %d px is %.1f wide, box %.0f" % [txt, fs, w, box])
	_ok(DiceRoller3D.fit_value_font("1", font) == 80, "one digit keeps 80 px")
	_ok(DiceRoller3D.fit_value_font("88", font) < 80, "88 at 80 px is wider than the box, so it shrinks (Design's table is wrong)")
	_ok(DiceRoller3D.fit_value_font("188", font) <= DiceRoller3D.fit_value_font("88", font), "more digits never get a bigger font")

	# materials
	var gold := DiceSkin.body_material("die_l_gold")
	_ok(gold.uv1_triplanar and gold.metallic == 1.0 and gold.anisotropy_enabled, "gold body: triplanar metal with anisotropy")
	_ok(gold.emission_enabled and gold.emission_operator == BaseMaterial3D.EMISSION_OP_MULTIPLY, "emission multiplies the map (no white wash)")
	_ok(DiceSkin.body_material("die_l_gold") == gold, "one body material per skin")
	var reed := DiceSkin.body_material("die_c_reed")
	_ok(not reed.emission_enabled and not reed.clearcoat_enabled and is_equal_approx(reed.roughness, 0.9), "reed: matte, no emission")
	var fm := DiceSkin.face_material("die_l_gold", null)
	_ok(fm.normal_enabled and is_equal_approx(fm.normal_scale, 1.6) and fm.metallic == 0.0 and fm.clearcoat_enabled, "face: normal 1.6, never metallic")
	_ok(DiceSkin.sheen_material("die_l_gold") != null and DiceSkin.sheen_material("die_c_reed") == null, "sheen only where delivered")

	# die mesh: skin materials on all 7 surfaces, fx only when asked
	var mi := DiceRoller3D.make_die_mesh([f, f, f, f, f, f], 0.5, "die_l_gold", false)
	_ok(mi.get_surface_override_material(0) == gold and mi.get_child_count() == 1, "skin die uses the shared body material + fx node")
	for si in 7:   # the dummy renderer logs an error when a mesh instance with overrides is freed
		mi.set_surface_override_material(si, null)
	mi.free()

	# trims
	_ok(DiceSkin.trim_file(88) == "tile_trim_88.png" and DiceSkin.trim_file(56) == "tile_trim_56.png" and DiceSkin.trim_file(36) == "egg_trim_36.png", "trim file by size")
	var tr := DiceSkin.make_trim("die_m_moon", 88)
	_ok(tr != null and tr.mouse_filter == Control.MOUSE_FILTER_IGNORE, "trim overlay ignores the mouse")
	tr.free()

	# thumbnails: cache name changes with the skin data
	_ok(DiceThumb.cache_name("die_c_reed") != DiceThumb.cache_name("die_r_aqua"), "thumb names differ per skin")
	_ok(DiceThumb.cache_name("die_c_reed").begins_with("die_c_reed_"), "thumb name starts with the id")

	# only the skins of a roll stay in memory
	DiceRoller3D._tex_cache["die_c_reed|dmg:1"] = null
	DiceRoller3D._tex_cache["die_r_aqua|dmg:1"] = null
	DiceRoller3D._tex_cache["dmg:1"] = null
	DiceRoller3D.free_plates_except(["die_r_aqua"])
	_ok(not DiceRoller3D._tex_cache.has("die_c_reed|dmg:1") and DiceRoller3D._tex_cache.has("die_r_aqua|dmg:1") and DiceRoller3D._tex_cache.has("dmg:1"),
		"unused skin faces are freed, the plain die's are kept")
	DiceRoller3D._tex_cache.clear()

	if _fails.is_empty():
		print("PASS: t_dice_skin (%d checks)" % _checks)
		get_tree().quit(0)
	else:
		print("FAIL: t_dice_skin %d of %d" % [_fails.size(), _checks])
		get_tree().quit(1)
