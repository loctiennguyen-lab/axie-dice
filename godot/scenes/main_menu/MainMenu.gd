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

## A team handed over by Guides / Sample Teams, read by RunSetup.
static var pending_team: Array[String] = []


## Where `_ready()` sends the player. Split out so a test can check the decision without
## changing scene.
static func route_target() -> String:
	if MetaState.needs_tutorial():
		return TUTORIAL_SCENE
	return LandNav.land_scene()


func _ready() -> void:
	# B4: nothing opens (not even the tutorial) until the server answers.
	if AccountService.gate_reason() != "":
		var layer := CanvasLayer.new()
		layer.layer = 100
		add_child(layer)
		AccountUI.show_offline_gate(layer, AccountService)
		AccountService.changed.connect(_on_account_changed)
		return
	get_tree().change_scene_to_file.call_deferred(route_target())


func _on_account_changed() -> void:
	if AccountService.gate_reason() == "":
		AccountService.changed.disconnect(_on_account_changed)
		get_tree().change_scene_to_file.call_deferred(route_target())
