class_name RaidScreen
extends Control
## Raid R1 ghost (lane RV, design/proposals/land-v1-spec.md section 6). Minimal UI3 screen:
## list up to 5 other players' defence teams ("ghosts"), fight one on the real combat screen (the ghost's
## dice play as ordinary enemies, see RaidGhost), then show the result and the Raid points.
## Nobody loses anything. Online only: signed out / offline show the reason instead of a list.
## The team you attack with and defend with is one of your saved presets (House), cycled with one button;
## with no preset it is the starter trio. Nothing is stored in MetaState: the Worker holds the defence.
## Points: win 3, loss 1; at most 5 raids a day count (3 per ghost). More fights are allowed, they just don't score.

const PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")
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
var _info_line: HBoxContainer
var _info_tone := &"info"
var _view: Node = null
var _challenge: Dictionary = {}
var _busy := false
var _req := 0
var _focus_fight := -1


func _ready() -> void:
	if use_account:
		var st: int = AccountService.status
		guest = st == AccountService.Status.GUEST or st == AccountService.Status.EXPIRED
		offline = st == AccountService.Status.OFFLINE
	_build()
	reload()
	_ensure_focus()


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
	if _busy:
		return
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
		_set_info("That team has no usable Axie.", &"error")
		return
	_busy = true
	_redraw()
	client.save_defense(team, {}, RaidGhost.power_hint(team), func(ok: bool, d: Dictionary) -> void:
		_busy = false
		if ok:
			_set_info("Defence team set: %s." % team_name(), &"ok")
		else:
			_set_info(_error_text(String(d.get("code", "server"))), &"error")
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
			_set_info(_error_text(String(d.get("code", "server"))), &"error")
			_redraw()
			return
		if not RaidGhost.is_valid_team(d.get("team")):
			_set_info("That ghost can't be fought right now.", &"error")
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
	var prev_pending: Dictionary = RunState.pending_combat   # not ours: put it back once the combat has consumed ours
	RunState.pending_combat = {"node_id": "raid", "kind": "battle", "pw": 0, "ascension": 0,
		"combat_seed": int(_challenge.get("seed", 1)), "roster_snapshot": roster, "relic_ids": [],
		"tutorial": true, "ghost_team": _challenge.get("team", [])}
	_shell["panel"].visible = false
	_view = load("res://scenes/combat/Combat.tscn").instantiate()
	add_child(_view)   # CombatView._ready() takes and clears pending_combat
	RunState.pending_combat = prev_pending
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


func _set_info(t: String, tone := &"info") -> void:
	_info_tone = tone
	if _info_line != null:
		Ui5RaidParts.set_info(_info_line, t, tone)


func _show_result() -> void:
	var r := last_result
	var tone := &"info"
	if not bool(r.get("ok", false)):
		tone = &"error"
	elif bool(r.get("won", false)) and bool(r.get("counted", false)):
		tone = &"ok"
	_set_info(result_text(), tone)


# ------------------------------------------------------------ UI
## Frames r01-r10 (ui05-meta1-screens.html): Header (shell) / Body { TopPlate { PointsLine, RuleLine, InfoLine,
## TeamButton, DefenceButton }, GhostList { GhostRow { FightButton } | EmptyState | FailedState { ToneDisc, RetryButton } } }.

func _build() -> void:
	_shell = UI3Meta.build(self, "Raid", "Fight another player's defence team", _on_back)
	(_shell["panel"] as Control).name = "PlateHost"   # t_ui_laws L0
	(_shell["back"] as Control).name = "BackButton"
	(_shell["sub"] as Control).name = "SubLine"
	var col: VBoxContainer = _shell["col"]
	var body := VBoxContainer.new()
	body.name = "Body"
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", UI3Theme.space("16"))
	col.add_child(body)
	var tp := Ui5RaidParts.top_plate()
	body.add_child(tp["plate"])
	var txt: VBoxContainer = tp["txt"]
	_points_lbl = Ui5RaidParts.wrap_label("PointsLine", "", "text_title", "text", true)
	txt.add_child(_points_lbl)
	txt.add_child(Ui5RaidParts.wrap_label("RuleLine", "Win 3 points, loss 1. 5 raids a day score, 3 per ghost. You can always fight more, they just don't score. Nobody loses anything.", "text_body", "text_muted"))
	_info_line = Ui5RaidParts.info_line()
	_info = _info_line.get_node("InfoText")
	txt.add_child(_info_line)
	var row: HBoxContainer = tp["row"]
	_team_btn = PanelParts.button("", &"secondary", &"M")
	_team_btn.name = "TeamButton"
	_team_btn.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_team_btn.pressed.connect(cycle_team)
	row.add_child(_team_btn)
	_def_btn = PanelParts.button("Set as defence team", &"primary", &"L")
	_def_btn.name = "DefenceButton"
	_def_btn.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_def_btn.pressed.connect(save_defense)
	row.add_child(_def_btn)
	_def_btn.custom_minimum_size.x = _defence_min_w()
	_list = VBoxContainer.new()
	_list.name = "GhostList"
	_list.add_theme_constant_override("separation", UI3Theme.space("8"))
	body.add_child(UI3Meta.scroll(_list))


## The Defence button keeps one width for its three labels, so the text column does not jump when it goes blocked.
func _defence_min_w() -> float:
	var f: Font = _def_btn.get_theme_font("font")
	var fs: int = _def_btn.get_theme_font_size("font_size")
	var w := 0.0
	for t in ["Set as defence team", "Sign in to raid", "Raids need a connection"]:
		w = maxf(w, f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
	return w + UI3Theme.space("32") * 2 + 8.0


func _redraw() -> void:
	if _list == null:
		return
	var fo := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	_focus_fight = int(fo.get_meta("ghost_idx", -1)) if fo != null and _list.is_ancestor_of(fo) else -1
	UI3Meta.clear(_list)
	_points_lbl.text = "Raid points %d · %s" % [points, next_badge_text()]
	var team_full := "Team: %s" % team_name()
	var tf: Font = _team_btn.get_theme_font("font")
	var tfs: int = _team_btn.get_theme_font_size("font_size")
	_team_btn.text = Ui5Ellipsis.fit(team_full, tf, tfs, UI3Theme.size_of("tooltip_w") - UI3Theme.space("24") * 2 - 8.0)
	_team_btn.tooltip_text = team_full if _team_btn.text != team_full else ""
	var presets_n := (MetaState.team_presets as Array).size()
	_team_btn.disabled = presets_n < 2   # busy is guarded in cycle_team: a disabled button would drop the keyboard focus
	var why := block_reason()
	if why != "":
		Ui5DisabledReason.apply(_def_btn, why)
	else:
		Ui5DisabledReason.clear(_def_btn)
		_def_btn.disabled = false   # busy is guarded in save_defense: a disabled button would drop the keyboard focus
	match status:
		"loading":
			for _i in 2:
				var sk := UI3.skeleton_row(UI3Theme.size_of("raid_row_h"))
				sk.name = "Skeleton"
				_list.add_child(sk, true)
		"empty":
			_list.add_child(Ui5RaidParts.center_block("EmptyState", "No ghosts yet. Set your own defence team, others will find it.")["block"])
		"failed":
			var t := "Sign in to raid." if fail_code == "guest" else _error_text(fail_code)
			var can_retry := fail_code != "guest" and fail_code != "offline"
			var cb := Ui5RaidParts.center_block("FailedState", t, &"error" if can_retry else &"info", true)
			if can_retry:
				var rb := PanelParts.button("Retry", &"secondary", &"M")
				rb.name = "RetryButton"
				rb.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
				rb.pressed.connect(reload)
				(cb["col"] as Control).add_child(rb)
			_list.add_child(cb["block"])
		_:
			for i in opponents.size():
				_list.add_child(_ghost_row(i), true)
	if is_inside_tree() and _view == null:
		var back := _list.find_children("FightButton", "Button", true, false)
		if _focus_fight >= 0 and _focus_fight < back.size():
			(back[_focus_fight] as Button).grab_focus()   # the list was rebuilt under the player's focus: give it back
		else:
			_ensure_focus.call_deferred()


func _ghost_row(i: int) -> Control:
	var o: Dictionary = opponents[i]
	var names: Array = []
	for u in (o.get("team", []) as Array):
		var key := String((u as Dictionary).get("key", ""))
		names.append(String((ContentDB.heroes.get(key, {}) as Dictionary).get("n", key.capitalize())))
	var parts := Ui5RaidParts.ghost_row("%s · power %d" % [String(o.get("name", "Player")), int(o.get("power_hint", 0))], ", ".join(names))
	var b: Button = parts["fight"]
	b.set_meta("ghost_idx", i)
	b.pressed.connect(challenge.bind(i))
	return parts["row"]


## Keeps a keyboard focus on the screen: the primary Defence button when it can act, else Retry, else Back.
## Never moves focus off a control the player is on, and does nothing while the combat view is open.
func _ensure_focus() -> void:
	if not is_inside_tree() or _view != null:
		return
	var cur := get_viewport().gui_get_focus_owner()
	if cur != null and is_ancestor_of(cur) and cur.is_visible_in_tree() and not (cur is BaseButton and (cur as BaseButton).disabled):
		return
	var target: Control = _def_btn
	if _def_btn.disabled:
		target = find_child("RetryButton", true, false) as Control
		if target == null:
			target = find_child("BackButton", true, false) as Control
	if target != null:
		target.grab_focus()
