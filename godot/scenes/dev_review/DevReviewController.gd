extends Control
## DevReview.tscn — the "review studio" debug harness (architecture plan §3, built
## right after the 4-scene skeleton, per the Jaatster workflow this port follows:
## test any part of the game via script instead of playing from the start every time).
##
## Run directly: godot --path godot scenes/dev_review/DevReview.tscn
## (never wired into MainMenu navigation — dev-only, matches src/devtools.js's own
## "stripped from production builds" precedent, see .claude/docs/technical-preferences.md)
##
## Implemented: seed input + jump-to-combat (bypasses RunMap entirely).
##
## Still stubbed: headless auto-play log mode and "force resync + diff". This comment used to
## say they were blocked on CombatEngine not existing — that stopped being true in the Phase-1
## parity pass, and `tests/t_full_run_loop.gd` now walks the whole real run headlessly, which
## is most of what the log mode was wanted for. So these two are a CHOICE not to build a dev
## tool, not a dependency waiting to be met; whoever wants them can write them today.

@onready var _seed_input: LineEdit = %SeedInput
@onready var _jump_combat_button: Button = %JumpCombatButton
@onready var _jump_map_button: Button = %JumpMapButton
@onready var _headless_button: Button = %HeadlessLogButton
@onready var _status_label: Label = %StatusLabel

const PLACEHOLDER_TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]

func _ready() -> void:
	_seed_input.text = "12345"
	_jump_combat_button.pressed.connect(_on_jump_combat)
	_jump_map_button.pressed.connect(_on_jump_map)
	_headless_button.pressed.connect(_on_headless_stub)

func _current_seed() -> int:
	return int(_seed_input.text) if _seed_input.text.is_valid_int() else 12345

func _on_jump_combat() -> void:
	# Bypasses RunMap entirely, per architecture plan §3: seed a minimal run, then set
	# up pending_combat directly using a node-derived combat_seed (Rng.derive_combat_seed)
	# so this is reproducible — a fixed dice-roll sequence for repeat testing, exactly
	# what the Jaatster workflow calls for.
	RunState.start_new_run(_current_seed(), PLACEHOLDER_TEAM, "short", 0, false)
	var combat_seed := Rng.derive_combat_seed(_current_seed(), "dev_review_jump", 0)
	RunState.pending_combat = {
		"node_id": "dev_review_jump", "kind": "battle", "pw": 0, "ascension": 0,
		"roster_snapshot": RunState.roster.duplicate(true),
		"relic_ids": [], "combat_seed": combat_seed,
	}
	RunState.set_phase(RunState.RunPhase.COMBAT)
	get_tree().change_scene_to_file("res://scenes/combat/Combat.tscn")

func _on_jump_map() -> void:
	RunState.start_new_run(_current_seed(), PLACEHOLDER_TEAM, "short", 0, false)
	get_tree().change_scene_to_file("res://scenes/run_map/RunMap.tscn")

func _on_headless_stub() -> void:
	_status_label.text = ("Headless auto-play log mode needs CombatEngine " +
		"(checklist step 4) — not implemented yet.")
