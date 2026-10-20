class_name RaidScreen
extends Control
## Raid R1 ghost (lane RV, design/proposals/land-v1-spec.md section 6). Minimal UI3 screen:
## list up to 5 other players' defence teams ("ghosts"), fight one on the real combat screen (the ghost's
## dice play as ordinary enemies, see RaidGhost), then show the result and the Raid points.
## Nobody loses anything. Online only: signed out / offline show the reason instead of a list.
## The team you attack with and defend with is one of your saved presets (House), cycled with one button;
## with no preset it is the starter trio. Nothing is stored in MetaState: the Worker holds the defence.
## Points: win 3, loss 1; at most 5 raids a day count (3 per ghost). More fights are allowed, they just don't score.

const STARTER := ["plant1", "beast1", "aqua1"]
const BADGE_AT := [10, 30, 75, 150, 300]

var client: RaidClient = RaidClient.new()
var no_scene_change := false
var use_account := true
## Test/QA overrides (read from the account when use_account).
var guest := false
var offline := false

## "loading" | "ok" | "empty" | "failed"
var status := "loading"
var fail_code := ""
var opponents: Array = []
var points := 0
var team_index := 0
var last_result: Dictionary = {}

var _shell: Dictionary
var _list: VBoxContainer
var _points_lbl: Label
var _team_btn: Button
var _def_btn: Button
var _info: Label
var _view: Node = null
var _challenge: Dictionary = {}
var _busy := false
var _req := 0


func _ready() -> void:
	if use_account:
		var st: int = AccountService.status
		guest = st == AccountService.Status.GUEST or st == AccountService.Status.EXPIRED
		offline = st == AccountService.Status.OFFLINE
	_build()
	reload()


func _unhandled_key_input(ev: InputEvent) -> void:
	if _view == null and UI3Meta.esc_back(ev, _shell, _on_back):
		if is_inside_tree():
			get_viewport().set_input_as_handled()


func _on_back() -> void:
	if is_inside_tree() and not no_scene_change:
		LandNav.back_to_land()


# ------------------------------------------------------------ team choice

## The party (hero keys) used to attack and to defend.
func current_party() -> Array:
	var presets: Array = MetaState.team_presets
	if presets.is_empty():
		return STARTER.duplicate()
	team_index = clampi(team_index, 0, presets.size() - 1)
	var keys: Array = []
	for k in (presets[team_index] as Dictionary).get("party", []):
		if String(k) != "":
			keys.append(String(k))
	return keys if not keys.is_empty() else STARTER.duplicate()


func team_name() -> String:
	var presets: Array = MetaState.team_presets
	if presets.is_empty():
		return "Starter team"
	return String((presets[clampi(team_index, 0, presets.size() - 1)] as Dictionary).get("name", "Team"))


func cycle_team() -> void:
	var n := (MetaState.team_presets as Array).size()
	if n > 1:
		team_index = (team_index + 1) % n
	_redraw()


# ------------------------------------------------------------ server calls

func block_reason() -> String:
	if guest:
		return "Sign in to raid"
	if offline:
		return "Raids need a connection"
	return ""


func reload() -> void:
	_req += 1
	var my := _req
	var why := block_reason()
	if why != "":
		status = "failed"
		fail_code = "guest" if guest else "offline"
		opponents = []
		_redraw()
		return
	status = "loading"
	_redraw()
	client.opponents(func(ok: bool, d: Dictionary) -> void:
		if my != _req:
			return
		if ok:
			opponents = (d.get("opponents", []) as Array).filter(func(o): return o is Dictionary and RaidGhost.is_valid_team((o as Dictionary).get("team")))
			points = int(d.get("points", 0))
			status = "ok" if not opponents.is_empty() else "empty"
		else:
			status = "failed"
			fail_code = String(d.get("code", "server"))
		_redraw())


func save_defense() -> void:
	if _busy or block_reason() != "":
		return
	var team := RaidGhost.snapshot_team(current_party())
	if team.is_empty():
		_set_info("That team has no usable Axie.")
		return
	_busy = true
	_redraw()
	client.save_defense(team, {}, RaidGhost.power_hint(team), func(ok: bool, d: Dictionary) -> void:
		_busy = false
		_set_info("Defence team set: %s." % team_name() if ok else _error_text(String(d.get("code", "server"))))
		_redraw())


## Starts a fight against opponents[i]: asks the Worker for a challenge (seed + snapshot), then opens the combat.
func challenge(i: int) -> void:
	if _busy or _view != null or block_reason() != "" or i < 0 or i >= opponents.size():
		return
	_busy = true
	_redraw()
	client.start(String((opponents[i] as Dictionary).get("ghost_id", "")), func(ok: bool, d: Dictionary) -> void:
		_busy = false
		if not ok:
			_set_info(_error_text(String(d.get("code", "server"))))
			_redraw()
			return
		if not RaidGhost.is_valid_team(d.get("team")):
			_set_info("That ghost can't be fought right now.")
			_redraw()
			return
		_challenge = d
		_launch_combat())


func _launch_combat() -> void:
	var roster: Array = []
	var keys := current_party()
	for i in keys.size():
		roster.append({"persistent_id": i + 1, "hero_key": keys[i], "tier": 1, "max_hp": 0, "muts": [], "growth": {}, "bonus_hp": 0})
	# `tutorial: true` is the existing "embedded fight" contract: the combat screen writes nothing into the run
	# or the save and reports the outcome through tutorial_combat_finished instead of changing scene.
	RunState.pending_combat = {"node_id": "raid", "kind": "battle", "pw": 0, "ascension": 0,
		"combat_seed": int(_challenge.get("seed", 1)), "roster_snapshot": roster, "relic_ids": [],
		"tutorial": true, "ghost_team": _challenge.get("team", [])}
	_shell["panel"].visible = false
	_view = load("res://scenes/combat/Combat.tscn").instantiate()
	add_child(_view)
	_view.connect("tutorial_combat_finished", _on_fight_over)


func _on_fight_over(won: bool) -> void:
	var turns := 1
	if _view != null:
		var eng: Variant = _view.get("_combat")
		if eng != null:
			turns = maxi(1, int(eng.turn))
		_view.queue_free()
		_view = null
	_shell["panel"].visible = true
	report_result(won, turns)


## Sends the result for the open challenge and shows the answer.
func report_result(won: bool, turns: int) -> void:
	var cid := String(_challenge.get("challenge_id", ""))
	if cid == "":
		return
	var seed := int(_challenge.get("seed", 0))
	var ghost := String(_challenge.get("name", "?"))
	_challenge = {}
	_busy = true
	_redraw()
	client.finish(cid, won, turns, RaidClient.result_hash(cid, seed, won, turns), func(ok: bool, d: Dictionary) -> void:
		_busy = false
		last_result = d.duplicate()
		last_result["ok"] = ok
		last_result["won"] = won
		last_result["ghost"] = ghost
		if ok:
			points = int(d.get("total", points))
		_show_result()
		_redraw())


# ------------------------------------------------------------ text

func _error_text(code: String) -> String:
	match code:
		"unauthenticated":
			return "Sign in to raid."
		"offline":
			return "Can't reach the server."
		"not_found":
			return "That ghost is gone. Refresh the list."
		"rate_limited":
			return "Too many raids at once. Wait a moment."
		"too_large", "bad_request":
			return "The server didn't accept that team."
	return "Server error. Try again."


func result_text() -> String:
	var r := last_result
	if r.is_empty():
		return ""
	var head := ("You beat %s's ghost." if bool(r.get("won", false)) else "%s's ghost beat you.") % String(r.get("ghost", "?"))
	if not bool(r.get("ok", false)):
		return head + " The result could not be saved: " + _error_text(String(r.get("code", "server")))
	if bool(r.get("counted", false)):
		var s := head + " +%d Raid points (total %d)." % [int(r.get("points", 0)), int(r.get("total", 0))]
		if int(r.get("badge", 0)) > 0:
			s += " New Raid badge %d!" % int(r["badge"])
		return s
	var why := "Daily raid limit reached" if String(r.get("reason", "")) == "daily_cap" else "You already scored 3 times on this ghost today"
	return head + " No points: " + why + "."


func next_badge_text() -> String:
	for m in BADGE_AT:
		if points < int(m):
			return "Next badge at %d points" % int(m)
	return "All Raid badges earned"


func _set_info(t: String) -> void:
	if _info != null:
		_info.text = t


func _show_result() -> void:
	_set_info(result_text())


# ------------------------------------------------------------ UI

func _build() -> void:
	_shell = UI3Meta.build(self, "Raid", "Fight another player's defence team", _on_back)
	var col: VBoxContainer = _shell["col"]
	var top := UI3.plate(&"plate")
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", UI3Theme.space("8"))
	top.add_child(tv)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI3Theme.space("16"))
	tv.add_child(row)
	_points_lbl = UI3.label("", "LabelTitle")
	_points_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_points_lbl)
	_team_btn = UI3.button("", &"secondary", &"M")
	_team_btn.name = "TeamButton"
	_team_btn.pressed.connect(cycle_team)
	row.add_child(_team_btn)
	_def_btn = UI3.button("Set as defence team", &"primary", &"M")
	_def_btn.name = "DefenseButton"
	_def_btn.pressed.connect(save_defense)
	row.add_child(_def_btn)
	var rule := UI3.label("Win 3 points, loss 1. 5 raids a day score, 3 per ghost. You can always fight more, they just don't score. Nobody loses anything.", "LabelMuted")
	rule.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tv.add_child(rule)
	_info = UI3.label("", "LabelMuted")
	_info.name = "Info"
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tv.add_child(_info)
	col.add_child(top)
	_list = VBoxContainer.new()
	_list.name = "Ghosts"
	_list.add_theme_constant_override("separation", UI3Theme.space("8"))
	col.add_child(UI3Meta.scroll(_list))


func _redraw() -> void:
	if _list == null:
		return
	UI3Meta.clear(_list)
	_points_lbl.text = "Raid points %d · %s" % [points, next_badge_text()]
	_team_btn.text = "Team: %s" % team_name()
	var presets_n := (MetaState.team_presets as Array).size()
	_team_btn.disabled = presets_n < 2 or _busy
	var why := block_reason()
	if why != "":
		UI3.set_disabled_reason(_def_btn, why)
	else:
		UI3.clear_disabled_reason(_def_btn)
		_def_btn.disabled = _busy
	match status:
		"loading":
			_list.add_child(UI3.skeleton_row())
			_list.add_child(UI3.skeleton_row())
		"empty":
			_list.add_child(UI3.label("No ghosts yet. Set your own defence team, others will find it.", "LabelMuted"))
		"failed":
			var t := "Sign in to raid." if fail_code == "guest" else _error_text(fail_code)
			_list.add_child(UI3.label(t, "LabelMuted"))
			if fail_code != "guest" and fail_code != "offline":
				var rb := UI3.button("Retry", &"secondary", &"M")
				rb.name = "Retry"
				rb.pressed.connect(reload)
				_list.add_child(rb)
		_:
			for i in opponents.size():
				_list.add_child(_ghost_row(i))


func _ghost_row(i: int) -> Control:
	var o: Dictionary = opponents[i]
	var p := UI3.plate(&"row")
	p.name = "Ghost%d" % i
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UI3Theme.space("16"))
	p.add_child(h)
	var names: Array = []
	for u in (o.get("team", []) as Array):
		var key := String((u as Dictionary).get("key", ""))
		names.append(String((ContentDB.heroes.get(key, {}) as Dictionary).get("n", key.capitalize())))
	var l := UI3.label("%s · power %d" % [String(o.get("name", "Player")), int(o.get("power_hint", 0))], "LabelTitle")
	l.custom_minimum_size.x = 320
	h.add_child(l)
	var tl := UI3.label(", ".join(names), "LabelMuted")
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	h.add_child(tl)
	var b := UI3.button("Fight", &"secondary", &"S")
	b.name = "Fight%d" % i
	b.disabled = _busy
	b.pressed.connect(challenge.bind(i))
	h.add_child(b)
	return p
