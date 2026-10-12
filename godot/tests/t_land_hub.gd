extends Node
## Gate for the Land hub scene: it builds, every house is a clickable box routed through LandNav
## (never a direct change_scene), locked plots never navigate, keys 1-9 map to the shortcut bar.
## Run: godot --headless --path godot res://tests/t_land_hub.tscn

var _fails: Array[String] = []
var _checks := 0


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)
		printerr("FAIL: ", msg)


func _ready() -> void:
	print("=== t_land_hub: start ===")
	var seen_was := MetaState.tutorial_seen
	MetaState.tutorial_seen = true      # in memory only
	LandNav.dry_run = true
	var hub := (load("res://scenes/land/Land.tscn") as PackedScene).instantiate() as LandHub
	add_child(hub)
	await get_tree().process_frame
	await get_tree().process_frame

	for id in ["portal", "house", "missions", "echobox", "pass", "vault", "store"]:
		_check(hub.find_child("Hit_" + id, true, false) != null, "thiếu hộp bấm cho " + id)
	for id in ["mastery", "gallery"]:
		_check(hub.find_child("Plot_" + id, true, false) != null, "thiếu ô đất khoá " + id)
	for k in range(1, 10):
		_check(hub.find_child("Shortcut%d" % k, true, false) != null, "thiếu phím tắt %d" % k)

	# House -> screen through LandNav.
	LandNav.last_path = ""
	(hub.find_child("Hit_pass", true, false) as Button).emit_signal("pressed")
	_check(LandNav.last_path == "res://scenes/pass/Pass.tscn", "Pass path: " + LandNav.last_path)
	LandNav.last_path = ""
	(hub.find_child("Hit_vault", true, false) as Button).emit_signal("pressed")
	_check(LandNav.last_path == "res://scenes/vault/Vault.tscn", "Vault path: " + LandNav.last_path)
	LandNav.last_path = ""
	(hub.find_child("Hit_house", true, false) as Button).emit_signal("pressed")
	_check(LandNav.last_path == "res://scenes/main_menu/TeamSelect.tscn", "House path: " + LandNav.last_path)
	# Shortcut 6 = Vault.
	LandNav.last_path = ""
	(hub.find_child("Shortcut6", true, false) as Button).emit_signal("pressed")
	_check(LandNav.last_path == "res://scenes/vault/Vault.tscn", "phím 6 phải mở Vault")
	# Locked shortcuts (Mastery 8, Gallery 9) must not navigate.
	LandNav.last_path = ""
	(hub.find_child("Shortcut8", true, false) as Button).emit_signal("pressed")
	(hub.find_child("Shortcut9", true, false) as Button).emit_signal("pressed")
	_check(LandNav.last_path == "", "Mastery/Gallery khoá không được điều hướng")
	# Screens that do not exist yet are 'Coming soon', not a crash or a blank scene.
	LandNav.last_path = ""
	(hub.find_child("Hit_missions", true, false) as Button).emit_signal("pressed")
	_check(LandNav.last_path == "" or LandNav.is_available(&"missions"), "Missions chưa có màn thì không đổi scene")
	# Run plate -> run_setup when there is no open run.
	var plate := hub.find_child("RunPlate", true, false) as Button
	var cont := hub.find_child("ContinuePanel", true, false) as Control
	_check(plate != null and cont != null, "thiếu Run plate / Continue panel")
	if plate != null and cont != null:
		_check(plate.visible != cont.visible, "Run plate và Continue panel phải loại trừ nhau")
		if plate.visible:
			LandNav.last_path = ""
			plate.emit_signal("pressed")
			_check(LandNav.last_path == LandNav.resolve(&"run_setup"), "Run plate phải mở run_setup")

	# Layout follows the window: plate centre x stays on the house centre at any height.
	var pass_plate := hub.find_child("Hit_pass", true, false) as Button
	_check(String((hub.META["pass"] as Dictionary)["sub"]).ends_with("29 Dec 2026"), "Pass sub-line phải ghi 29 Dec 2026")
	_check(absf(pass_plate.position.x + pass_plate.size.x * 0.5 - 1450.0) < 1.0, "hộp Pass lệch tâm x")

	hub.queue_free()
	await get_tree().process_frame

	# All six Lands build; Mastery opens at Arctic (3), Gallery at Genesis (5).
	for tier in range(1, 7):
		LandHub.tier_override = tier
		var h := (load("res://scenes/land/Land.tscn") as PackedScene).instantiate() as LandHub
		add_child(h)
		await get_tree().process_frame
		var mastery_built := h.find_child("Hit_mastery", true, false) != null
		_check(mastery_built == (tier >= 3), "tier %d: Mastery built=%s" % [tier, mastery_built])
		_check((h.find_child("Plot_mastery", true, false) != null) == (tier < 3), "tier %d: ô Mastery" % tier)
		var gal := h.find_child("Plot_gallery", true, false)
		_check(gal != null and bool(gal.get("locked")) == (tier < 5), "tier %d: Gallery khoá sai" % tier)
		_check((h.find_child("UpgradeLand", true, false) != null) == (tier < 6), "tier %d: nút Upgrade" % tier)
		_check(h.find_child("Hit_portal", true, false) != null, "tier %d: thiếu Portal" % tier)
		h.queue_free()
		await get_tree().process_frame
	LandHub.tier_override = 0
	LandNav.dry_run = false
	MetaState.tutorial_seen = seen_was
	_check_scene_deps("res://assets/land/homeland/scenes")
	if _fails.is_empty():
		print("=== t_land_hub: PASS (%d checks) ===" % _checks)
		get_tree().quit(0)
	else:
		printerr("=== t_land_hub: FAIL (%d/%d) ===" % [_fails.size(), _checks])
		get_tree().quit(1)


## Every HomeLand scene Land can place: all dependencies exist on disk (a clean checkout must not
## have broken refs, e.g. files swallowed by .gitignore) and the scene instantiates.
func _check_scene_deps(dir_path: String) -> void:
	var scenes: Array[String] = []
	_collect_scenes(dir_path, scenes)
	_check(scenes.size() > 0, "no Land scenes found under " + dir_path)
	for sp in scenes:
		for d in ResourceLoader.get_dependencies(sp):
			var parts := String(d).split("::")
			var dp := parts[parts.size() - 1]
			if dp == "":
				dp = parts[0]
			_check(ResourceLoader.exists(dp) or FileAccess.file_exists(dp), "%s depends on missing %s" % [sp, dp])
		var ps := load(sp) as PackedScene
		_check(ps != null, sp + " does not load")
		if ps != null:
			var inst := ps.instantiate()
			_check(inst != null, sp + " does not instantiate")
			if inst != null:
				inst.free()


func _collect_scenes(dir_path: String, out: Array[String]) -> void:
	for f in DirAccess.get_files_at(dir_path):
		if f.ends_with(".tscn"):
			out.append(dir_path.path_join(f))
	for d in DirAccess.get_directories_at(dir_path):
		_collect_scenes(dir_path.path_join(d), out)
