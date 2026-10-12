class_name LandNav
extends RefCounted
## Điều hướng giữa Land hub và các màn meta (l1-interfaces.md mục 7, hợp đồng L <-> M).
##
## Màn meta không tự biết chuyển về đâu: chúng gọi `LandNav.back_to_land()`. Land và các màn
## khác mở màn qua `LandNav.open(screen_id)`. Bảng SCREENS là nơi DUY NHẤT giữ đường dẫn scene.
## Màn chưa có ("scene" không tồn tại) thì dùng "fallback" (màn cũ); không có cả hai thì
## `is_available()` trả false và `open()` không làm gì (hub hiện nhãn SOON).

## Cảnh Land. Giai đoạn skeleton trỏ về MainMenu cũ; Land.tscn thay vào khi hub xong.
const LAND_SCENE := "res://scenes/land/Land.tscn"
const LEGACY_MENU := "res://scenes/main_menu/MainMenu.tscn"

## screen_id -> {scene, fallback}. M gửi yêu cầu cho L nếu cần thêm id.
const SCREENS: Dictionary = {
	&"run_setup": {"scene": "res://scenes/run_setup/RunSetup.tscn", "fallback": LEGACY_MENU},
	&"team_select": {"scene": "res://scenes/main_menu/TeamSelect.tscn"},
	&"missions": {"scene": "res://scenes/missions/Missions.tscn"},
	&"echobox": {"scene": "res://scenes/echobox/EchoBox.tscn"},
	&"pass": {"scene": "res://scenes/pass/Pass.tscn"},
	&"store": {"scene": "res://scenes/store/Store.tscn"},
	&"vault": {"scene": "res://scenes/vault/Vault.tscn"},
	&"codex": {"scene": "res://scenes/codex/Codex.tscn"},
	&"settings": {"scene": "res://scenes/settings/Settings.tscn"},
	&"guides": {"scene": "res://scenes/guides/Guides.tscn"},
	# Mastery Hall / Gallery: no screens yet (lane M); the hub shows "Coming soon".
	&"mastery": {"scene": "res://scenes/mastery/Mastery.tscn"},
	&"gallery": {"scene": "res://scenes/gallery/Gallery.tscn"},
	&"unlocks": {"scene": "res://scenes/unlocks/Unlocks.tscn"},
	# Tài khoản hiện nằm trong Settings (AccountUI chip), chưa có màn riêng.
	&"account": {"scene": "res://scenes/account/Account.tscn",
		"fallback": "res://scenes/settings/Settings.tscn"},
}

static var _params: Dictionary = {}
## Cờ cho MainMenu cũ: true = đang được mở như màn Run Setup tạm, đừng đá về Land.
static var legacy_setup_open: bool = false
## Test: không đổi scene thật, chỉ ghi lại đường dẫn định mở.
static var dry_run: bool = false
static var last_path: String = ""


## Đường dẫn scene sẽ mở cho id này, "" nếu chưa có gì để mở.
static func resolve(screen_id: StringName) -> String:
	var entry: Dictionary = SCREENS.get(screen_id, {})
	if entry.is_empty():
		return ""
	var scene: String = entry.get("scene", "")
	if scene != "" and ResourceLoader.exists(scene):
		return scene
	var fb: String = entry.get("fallback", "")
	if fb != "" and ResourceLoader.exists(fb):
		return fb
	return ""


static func is_available(screen_id: StringName) -> bool:
	return resolve(screen_id) != ""


## Mở màn meta. `params` đọc lại ở màn đích bằng `current_params()`.
static func open(screen_id: StringName, params: Dictionary = {}) -> void:
	var path := resolve(screen_id)
	if path == "":
		push_warning("LandNav.open: '%s' chưa có màn nào để mở" % screen_id)
		return
	_params = params.duplicate()
	legacy_setup_open = (path == LEGACY_MENU)
	_change(path)


## Về Land. Màn meta gọi hàm này thay vì change_scene về MainMenu.
static func back_to_land() -> void:
	_params = {}
	legacy_setup_open = false
	_change(land_scene())


static func current_params() -> Dictionary:
	return _params


## Land.tscn nếu đã có, không thì MainMenu cũ (giai đoạn skeleton).
static func land_scene() -> String:
	return LAND_SCENE if ResourceLoader.exists(LAND_SCENE) else LEGACY_MENU


static func _change(path: String) -> void:
	last_path = path
	if dry_run:
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		push_error("LandNav: không có SceneTree")
		return
	tree.change_scene_to_file(path)
