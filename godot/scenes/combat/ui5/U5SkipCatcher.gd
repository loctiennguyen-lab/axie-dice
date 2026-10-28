class_name U5SkipCatcher
extends Node
## UI-05 b1 lane E: "Skip with a click or Space" for the in-fight moments (crit, big hit, knockout, boss phase,
## defeat tint). Lives on the Ui5Moments layer of the combat view. A click or Space jumps every running skippable
## moment to its end state. A click is never eaten (it still picks a die or a target); Space is eaten while a
## moment runs, so skipping a moment never also ends the turn. The turn banner and the Victory band read their
## own input (U5TurnBanner / U5VictoryBand). UI only: never touches the fight.

var _runs: Array[UI3Motion.Timeline] = []
## The combat view (WeakRef). When the fight is over (the crit / big hit was the last blow) Space is not eaten:
## it also reaches the Victory band / victory march.
var view: WeakRef


## Track a timeline so a click / Space can skip it. Finished timelines drop out by themselves.
func add(run: UI3Motion.Timeline) -> void:
	if run != null and not run.done:
		_runs.append(run)


## True while at least one skippable moment is still playing (lane A's SkipHint can read this).
func running() -> bool:
	_prune()
	return not _runs.is_empty()


## Jump every tracked moment to its end state. Returns how many were running.
func skip_all() -> int:
	_prune()
	var n := _runs.size()
	for r in _runs.duplicate():
		r.skip()
	_runs.clear()
	return n


func _prune() -> void:
	_runs = _runs.filter(func(r: UI3Motion.Timeline) -> bool: return r != null and not r.done)


func _input(event: InputEvent) -> void:
	if not running():
		return
	var mouse := event is InputEventMouseButton and (event as InputEventMouseButton).pressed
	var space := event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo \
		and (event as InputEventKey).keycode == KEY_SPACE
	if not (mouse or space):
		return
	skip_all()
	if space and is_inside_tree() and not _fight_over():
		get_viewport().set_input_as_handled()


func _fight_over() -> bool:
	var v: Variant = view.get_ref() if view != null else null
	if not (v is CombatView):
		return false
	var cv: CombatView = v
	return cv._combat != null and (cv._combat.won or cv._combat.lost)


func _exit_tree() -> void:
	UI3Motion.end_hitstop()   # the moments this layer played may have started one
