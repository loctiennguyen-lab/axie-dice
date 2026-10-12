extends Node
## Gate cho LandNav + houses.json (l1-interfaces.md mục 7).
## Run: godot --headless --path godot res://tests/t_land_nav.tscn

const REQUIRED_IDS: Array[StringName] = [&"run_setup", &"echobox", &"pass", &"missions", &"store",
	&"vault", &"codex", &"settings", &"guides", &"unlocks", &"team_select", &"account"]

var _fails: Array[String] = []
var _checks := 0


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)
		printerr("FAIL: ", msg)


func _ready() -> void:
	print("=== t_land_nav: start ===")
	LandNav.dry_run = true
	for id in REQUIRED_IDS:
		_check(LandNav.SCREENS.has(id), "SCREENS thiếu id %s" % id)
	# Màn đã có thật thì phải resolve được.
	for id in [&"run_setup", &"team_select", &"pass", &"vault", &"codex", &"settings", &"guides",
			&"unlocks", &"account", &"daily"]:
		_check(LandNav.is_available(id), "%s phải có màn (hoặc fallback)" % id)
	_check(LandNav.resolve(&"khong_co_id") == "", "id lạ phải resolve rỗng")
	# open ghi path + params; back_to_land xoá params.
	LandNav.open(&"vault", {"from": "land"})
	_check(LandNav.last_path == "res://scenes/vault/Vault.tscn", "open(vault) path: " + LandNav.last_path)
	_check(LandNav.current_params().get("from", "") == "land", "params không được giữ")
	LandNav.last_path = ""
	LandNav.open(&"khong_co_id")
	_check(LandNav.last_path == "", "open id lạ không được đổi scene")
	LandNav.back_to_land()
	_check(LandNav.last_path == LandNav.land_scene(), "back_to_land path")
	_check(LandNav.current_params().is_empty(), "back_to_land phải xoá params")
	# run_setup fallback về MainMenu cũ bật cờ legacy.
	if not ResourceLoader.exists("res://scenes/run_setup/RunSetup.tscn"):
		LandNav.open(&"run_setup")
		_check(LandNav.legacy_setup_open, "run_setup fallback phải bật legacy_setup_open")
	LandNav.back_to_land()
	_check(not LandNav.legacy_setup_open, "back_to_land phải tắt legacy_setup_open")
	# Round 3 screens: keys 1 (Portal) and 4 (Echo Box) open the real scenes; Back returns to Land.
	LandNav.open(&"run_setup")
	_check(LandNav.last_path == "res://scenes/run_setup/RunSetup.tscn", "key 1 -> RunSetup: " + LandNav.last_path)
	_check(not LandNav.legacy_setup_open, "RunSetup thật không được bật legacy_setup_open")
	LandNav.open(&"echobox")
	_check(LandNav.last_path == "res://scenes/echobox/EchoBoxScreen.tscn", "key 4 -> EchoBoxScreen: " + LandNav.last_path)
	_check(LandNav.SCREENS[&"missions"]["scene"] == "res://scenes/missions/MissionsScreen.tscn", "missions route")
	# houses.json
	var txt := FileAccess.get_file_as_string("res://assets/land/houses.json")
	var arr = JSON.parse_string(txt)
	_check(arr is Array and arr.size() == 9, "houses.json phải là mảng 9 nhà")
	if arr is Array:
		var seen := {}
		for h in arr:
			_check(h is Dictionary and h.has_all(["house_id", "screen_id", "badge_screen_id", "unlock"]),
				"nhà thiếu field: %s" % str(h))
			if h is Dictionary:
				_check(not seen.has(h.get("house_id")), "house_id trùng " + str(h.get("house_id")))
				seen[h.get("house_id")] = true
				var sid := StringName(h.get("screen_id", ""))
				var locked: bool = (h.get("unlock", {}) as Dictionary).has("min_tier")
				_check(locked or LandNav.SCREENS.has(sid), "house %s trỏ id không có trong SCREENS" % h.get("house_id"))
	LandNav.dry_run = false
	if _fails.is_empty():
		print("=== t_land_nav: PASS (%d checks) ===" % _checks)
		get_tree().quit(0)
	else:
		printerr("=== t_land_nav: FAIL (%d/%d) ===" % [_fails.size(), _checks])
		get_tree().quit(1)
