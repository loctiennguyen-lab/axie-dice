class_name MainMenu
extends Control
## MainMenu.tscn root. The old main menu is gone (Liam dropped it, 16/10); this scene is now a
## pure ROUTER. It is still the project's boot scene (project.godot) and the target of every
## "back to menu" button, so `_ready()` is the single choke point every entry funnels through:
##   1. save has never seen the tutorial -> Tutorial.tscn
##   2. otherwise                        -> the Land hub (LandNav.land_scene())
## It draws nothing.
##
## The constants and the `pending_team` hand-off below are still read by RunSetup,
## Guides, Vault, Missions and TeamPresets, so they stay here (scenes/main_menu/ is outside the
## rule-fingerprinted dirs). `pending_team` is a static var rather than RunState/MetaState
## because a team the player is CONSIDERING is neither run state nor persistent state.

const T1_HERO_KEYS: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1", "bird1"]
const DEFAULT_TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
const TEAM_SIZE := 5
const TUTORIAL_SCENE := "res://scenes/tutorial/Tutorial.tscn"
const LOGIN_SCENE := "res://scenes/login/LoginScreen.tscn"
## How long the router waits for /api/me when a cached account is still being checked.
const CHECK_WAIT_S := 6.0

## True once the sign-in screen has been passed (or was not needed) in this game launch. Not reset by "back to menu".
static var login_passed := false

## A team handed over by Guides / Sample Teams, read by RunSetup.
static var pending_team: Array[String] = []


## Where `_ready()` sends the player. Split out so a test can check the decision without
## changing scene.
static func route_target() -> String:
	if MetaState.needs_tutorial():
		return TUTORIAL_SCENE
	return LandNav.land_scene()


## True when the sign-in screen must be shown now: nobody signed in, or the session expired. Once per launch.
static func login_needed(svc: Node = null) -> bool:
	if svc == null:
		svc = AccountService
	if login_passed:
		return false
	var signed_in: bool = not svc.account.is_empty() and (int(svc.status) != AccountServiceScript.Status.EXPIRED
		or String(svc.desktop_phase) == "signed_in")
	return not signed_in


## Where the router sends the player: "wait" (a cached session is being checked) | LOGIN_SCENE | TUTORIAL | Land.
## Order: offline -> sign-in screen (not signed in, or EXPIRED) -> Tutorial or Land.
static func entry_target(svc: Node = null) -> String:
	if svc == null:
		svc = AccountService
	if svc.gate_reason() != "":
		return LOGIN_SCENE
	if not login_passed and svc.enabled and int(svc.status) == AccountServiceScript.Status.CHECKING:
		return "wait"
	if login_needed(svc):
		return LOGIN_SCENE
	return route_target()


func _ready() -> void:
	_go()


func _go() -> void:
	var t := entry_target()
	if t == "wait":
		if not AccountService.changed.is_connected(_on_account_changed):
			AccountService.changed.connect(_on_account_changed)
		get_tree().create_timer(CHECK_WAIT_S).timeout.connect(_wait_over)
		return
	if AccountService.changed.is_connected(_on_account_changed):
		AccountService.changed.disconnect(_on_account_changed)
	if t != LOGIN_SCENE:
		login_passed = true
	get_tree().change_scene_to_file.call_deferred(t)


func _wait_over() -> void:
	if is_inside_tree() and AccountService.changed.is_connected(_on_account_changed):
		AccountService.changed.disconnect(_on_account_changed)
		var t := LOGIN_SCENE if login_needed() else route_target()
		if t != LOGIN_SCENE:
			login_passed = true
		get_tree().change_scene_to_file.call_deferred(t)


func _on_account_changed() -> void:
	if is_inside_tree() and entry_target() != "wait":
		_go()
