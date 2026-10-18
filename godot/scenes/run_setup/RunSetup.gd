class_name RunSetup
extends Control
## M1 Run Setup (Portal, key 1). Spec: design/handoffs/ui-02-round3 README §0, §2 M1.
## Layout: shell 1520 x (880 + extra height) at left 200 / top 116, wood header band 64, party row
## on top (5 slots 272 x 176), three columns (Mode + Length | Ascension | Kit/Boon), footer 84.
## Reads MetaState (asc_max, u_full, vault, runs), ContentDB (heroes, ascension_mods) and starts the
## run through RunState.begin_run() (L1 epoch seam). Holds no game rules of its own.
##
## States drawn: normal, locked Full / locked Ascension chips, newcomer (no Kit/Boon column),
## loading (skeleton), offline (Begin disabled), open run (Continue / New run), Begin rejected,
## picker sub-view. Daily (3 tries per UTC day) and Ranked (5 runs first, no imported Axies) are live in L1 C2
## when dice are server-rolled. Not wired: Kit/Boon purchase,
## preset save/load, seed well, Leaderboard button. Those render disabled with the reason shown.

const EconomyDBScript := preload("res://scripts/meta/economy_db.gd")
const SCREEN_ID := "portal"
const RUN_MAP := "res://scenes/run_map/RunMap.tscn"
const COMBAT := "res://scenes/combat/Combat.tscn"
const ASC_MAX := 10
const PARTY_SIZE := 5
const NEWCOMER_RUNS := 5

# TODO lane U token: darker wood for small-caps section labels on cream.
const WOOD_DARK := Color("6E2F18")

const FAIRNESS := "Aid makes you stronger for one run. Players who buy more can win more. The Pure leaderboard only counts runs without Aid."

const RULES := [
	[1, "Lean Pack", "Shop prices +15% · selling refunds 40%, not 50%"],
	[2, "Elite Escort", "Every elite fight brings 1 extra monster"],
	[3, "Short Dice", "Base rerolls 2 → 1 · relic rerolls still add"],
	[4, "Boss Clock", "Enrage from turn 10: +20%/turn, max +100%"],
	[5, "Eternal Gift", "Elite relics are Eternal (max 2) · weaken announced"],
	[6, "First Pact", "First boss: you must take 1 of 3 pacts"],
	[7, "Narrow Offer", "Reward screens offer 2 cards, not 3"],
	[8, "Cramped Pack", "Passive relic slots 8 → 7"],
	[9, "Hunted", "+2 elites on the map · boss clock from turn 8"],
	[10, "Last Stand", "Every boss requires a pact · no reward reroll"],
]

## "normal" | "loading" | "offline" | "open_run". Set before add_child or call set_state().
var state := "normal"
## Derive state from AccountService (offline). Tests that drive state by hand turn this off.
var use_account := true
## Server-rolled dice on (ProjectSettings "axie/epoch_source" == "remote"; RemoteEpochSource.flag_on()
## once lane S lands it). Only then does OFFLINE block Begin; otherwise it is just a banner.
var remote_on: bool = String(ProjectSettings.get_setting("axie/epoch_source", "")) == "remote"
## Tests: replaces AccountService.status. Returns an AccountService.Status int.
var account_status_hook: Callable
## Tests: a stand-in for the AccountService autoload (needs `status` and `changed`).
var account_service: Node
## Tests: replaces AccountService.sign_in().
var sign_in_hook: Callable = Callable()
## Tests: skip the scene change after a successful Begin.
var no_scene_change := false
## Tests: replace the real RunState call. Receives the params Dictionary, returns {ok, code}.
var start_hook: Callable = Callable()

var party: Array[String] = []
var mode := "short"
var ascension := 0
var begin_error := ""
## L1 C2: "normal" | "daily" | "ranked". Only changes through select_kind().
var kind := "normal"
## Daily tries today, from GET /api/run/daily: {used, max}. Empty until loaded.
var daily_tries: Dictionary = {}
## Tests: replaces RunState.run_session().daily_info. Receives done(ok, data).
var daily_info_hook: Callable = Callable()
var _kind_btns: Dictionary = {}

var _panel: PanelContainer
var _body: VBoxContainer
var _footer_msg: Label
var _begin_btn: Button
var _party_row: HBoxContainer
var _party_label: Label
var _asc_chips: Array[Button] = []
var _asc_title: Label
var _asc_mult: Label
var _asc_rule: Label
var _stage: Control
var _asc_tip: Label
var _short_btn: Button
var _full_btn: Button
var _mode_detail: Label
var _banner_host: VBoxContainer
var _modal_layer: Control
var _picker_slot := -1
var _picker_tab := "all"
var _picker_cls := "all"
var _picker_sel := ""
var _presets_tab := "load"
## Test/QA hook: leaderboard popup source (null = LeaderboardSource.make_default()).
var lb_source: LeaderboardSource = null
var _picker_grid: GridContainer


func _ready() -> void:
	RunState.discard_unresumable_run()
	if party.is_empty():
		party = _initial_party()
	ascension = clampi(ascension, 0, ascension_ceiling())
	_build()
	if account_service == null:
		account_service = AccountService
	if use_account:
		state = account_state()
		# Sign-in can finish while this screen is open (browser flow): re-evaluate instead of
		# keeping a stale "Sign in to play".
		account_service.changed.connect(_on_account_changed)
		tree_exiting.connect(func() -> void:
			if is_instance_valid(account_service) and account_service.changed.is_connected(_on_account_changed):
				account_service.changed.disconnect(_on_account_changed))
	set_state(state)
	load_daily_tries()
	var _notice := RunState.take_discard_notice()
	if _notice != "":
		var l := Label.new()
		l.text = _notice
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_banner_host.add_child(l)


## Run Setup state from the account: only a signed-in player who lost the connection is
## "offline"; a guest or an expired/revoked session is "guest" (L1: sign-in required to play, only
## enforced while remote_on). Reads AccountService.status unless account_status_hook is set (tests).
func account_state() -> String:
	var svc: Node = account_service if account_service != null else AccountService
	var st: int = account_status_hook.call() if account_status_hook.is_valid() else svc.status
	if st == AccountService.Status.OFFLINE:
		return "offline"
	# Signing in / reconciling the cloud save: the active profile may still switch or be replaced.
	if st == AccountService.Status.CHECKING:
		return "loading"
	if bool(svc.get("reconciling")):
		return "loading"
	var phase: Variant = svc.get("desktop_phase")
	if phase != null and String(phase) != "idle":
		return "loading"
	if remote_on and (st == AccountService.Status.GUEST or st == AccountService.Status.EXPIRED):
		return "guest"
	return "normal"


## True while a modal (hero picker, preset, leaderboard...) is open. AccountService waits for this
## before rebuilding the screen.
func has_modal() -> bool:
	return _modal_layer != null and _modal_layer.get_child_count() > 0


func _on_account_changed() -> void:
	if use_account and state in ["normal", "loading", "offline", "guest"] and account_state() != state:
		set_state(account_state())


func _unhandled_key_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_ESCAPE:
		if _modal_layer.get_child_count() > 0:
			close_modal()
		else:
			_on_back()
		get_viewport().set_input_as_handled()
	elif ev is InputEventKey and ev.pressed and not ev.echo and not ev.alt_pressed and not ev.ctrl_pressed \
			and not ev.meta_pressed and _modal_layer.get_child_count() == 0:
		if ev.keycode == KEY_B and not is_newcomer():
			open_leaderboard()
			get_viewport().set_input_as_handled()
		elif ev.keycode == KEY_S:
			open_save_preset()
			get_viewport().set_input_as_handled()


# ---------------------------------------------------------------- public API (also used by tests)

func ascension_ceiling() -> int:
	return mini(ASC_MAX, MetaState.asc_max)


func is_full_unlocked() -> bool:
	return MetaState.has_unlock("u_full")


func is_newcomer() -> bool:
	return MetaState.is_newcomer()


## Returns false (and changes nothing) for a locked level.
func select_ascension(n: int) -> bool:
	if n < 0 or n > ascension_ceiling():
		return false
	ascension = n
	_refresh_asc()
	_refresh_footer()
	return true


func select_length(m: String) -> bool:
	if m == "full" and not is_full_unlocked():
		return false
	if m != "short" and m != "full":
		return false
	mode = m
	_refresh_mode()
	return true


## Puts hero `key` into slot `i`. Refused when the key is unknown, or it is a Vault Axie already in
## another slot (starters may repeat, see TeamPresets.may_repeat).
func set_slot(i: int, key: String) -> bool:
	if i < 0 or i >= PARTY_SIZE or not ContentDB.heroes.has(key):
		return false
	if TeamPresets.seat_taken(party, i, key):
		return false
	while party.size() < PARTY_SIZE:
		party.append("")
	party[i] = key
	_refresh_party()
	_refresh_footer()
	return true


## Picker rule (UI-03 33): a Vault Axie already in another slot moves to slot `i`; slot i's previous
## Axie takes its old slot. A starter is copied (it may repeat), the other seat is left alone.
func swap_into_slot(i: int, key: String) -> bool:
	if i < 0 or i >= PARTY_SIZE or not ContentDB.heroes.has(key):
		return false
	var from := party.find(key)
	if from < 0 or from == i or TeamPresets.may_repeat(key):
		return set_slot(i, key)
	while party.size() < PARTY_SIZE:
		party.append("")
	var prev: String = party[i]
	party[i] = key
	party[from] = prev
	_refresh_party()
	_refresh_footer()
	return true


func clear_slot(i: int) -> void:
	if i >= 0 and i < party.size():
		party[i] = ""
		_refresh_party()
		_refresh_footer()


func filled_count() -> int:
	var n := 0
	for k in party:
		if k != "":
			n += 1
	return n


func start_params() -> Dictionary:
	var keys: Array[String] = []
	for k in party:
		if k != "":
			keys.append(k)
	return {"team_keys": keys, "mode": mode, "ascension": ascension, "kind": kind, "ranked": kind == "ranked",
		"newcomer": is_newcomer()}


## Fetches the Daily tries. Only meaningful when dice are server-rolled; quiet on failure (the buttons
## then stay disabled with the reason).
func load_daily_tries() -> void:
	if not remote_on and not daily_info_hook.is_valid():
		return
	var cb := func(ok: bool, data: Dictionary) -> void:
		if ok:
			daily_tries = {"used": int(data.get("used", 0)), "max": int(data.get("max", 3))}
		_refresh_kind()
		_refresh_footer()
	if daily_info_hook.is_valid():
		daily_info_hook.call(cb)
	else:
		RunState.run_session().daily_info(cb)


func _party_has_vault() -> bool:
	return MetaState.team_has_vault_pick(party)


## Why `k` ("daily" | "ranked") cannot be picked right now, or "" when it can.
func kind_block_reason(k: String) -> String:
	if k == "normal":
		return ""
	if not remote_on:
		return "Needs the online build"
	if state == "guest":
		return "Sign in to play"
	if state == "offline":
		return "Needs a connection"
	if k == "daily":
		if daily_tries.is_empty():
			return "Loading tries…"
		if int(daily_tries["used"]) >= int(daily_tries["max"]):
			return "No tries left today"
		return ""
	if is_newcomer():
		var need := int(EconomyDBScript.get_table("missions").get("newcomer_runs", 5))
		return "Opens after %d runs · %d of %d" % [need, mini(MetaState.runs_with_battle, need), need]
	if _party_has_vault():
		return "Imported Axies can't play Ranked"
	return ""


## Picks Normal / Daily / Ranked. False (nothing changes) when blocked.
func select_kind(k: String) -> bool:
	if k != "normal" and k != "daily" and k != "ranked":
		return false
	if kind_block_reason(k) != "":
		return false
	kind = k
	_refresh_kind()
	_refresh_footer()
	return true


func _kind_sub(k: String) -> String:
	var why := kind_block_reason(k)
	if k == "daily" and not daily_tries.is_empty() and why == "":
		return "%d of %d left" % [int(daily_tries["max"]) - int(daily_tries["used"]), int(daily_tries["max"])]
	if why != "":
		return why
	return "free choice" if k == "normal" else "leaderboard"


func _refresh_kind() -> void:
	if kind != "normal" and kind_block_reason(kind) != "":
		kind = "normal"   # e.g. a vault Axie was just added while Ranked was picked
	for k in _kind_btns:
		var b: Button = _kind_btns[k]
		var why := kind_block_reason(k)
		b.disabled = why != ""
		b.tooltip_text = why
		b.text = "%s · %s" % [String(k).capitalize(), _kind_sub(k)]
		b.set_pressed_no_signal(kind == k)
		_mark_selected(b, kind == k)


## Why Begin is disabled, or "" when it is allowed.
func begin_block_reason() -> String:
	if state == "guest" and remote_on:
		return "Sign in to play"
	if state == "offline" and remote_on:
		return "Needs a connection to roll dice"
	if state == "loading":
		return "Signing you in…" if use_account and account_state() == "loading" else "Loading…"
	if kind != "normal":
		var kw := kind_block_reason(kind)
		if kw != "":
			return kw
	var missing := PARTY_SIZE - filled_count()
	if missing > 0:
		return "Pick %d more Ax%s to begin" % [missing, "ie" if missing == 1 else "ies"]
	return ""


func set_state(s: String) -> void:
	state = s
	if _panel == null:
		return
	_clear_banners()
	_body.visible = s != "loading" and s != "open_run"
	_stage.visible = s != "loading" and s != "open_run"
	_panel.visible = s != "open_run"
	var sk := _panel.get_node_or_null("Col/Skeleton")
	if sk:
		sk.get_parent().remove_child(sk)
		sk.queue_free()
	var oc := get_node_or_null("OpenRun")
	if oc:
		remove_child(oc)
		oc.queue_free()
	if s == "loading":
		_build_skeleton()
	elif s == "open_run":
		_build_open_run()
	elif s == "guest":
		_add_banner("Sign in to play", "Dice are rolled on the server, so runs need an account.", false, true)
	elif s == "offline":
		if remote_on:
			_add_banner("Can't reach the dice server", "Last updated %s. Dice are rolled on the server in this build."
				% Time.get_time_string_from_system().substr(0, 5), true)
		else:
			_add_banner("You're offline", "Dice roll on this device for now; progress syncs when you reconnect.", false)
	_refresh_footer()


## Begin. Uses start_hook if set (tests), otherwise RunState.begin_run().
func begin() -> Dictionary:
	if use_account and state in ["normal", "loading", "offline", "guest"] and account_state() != state:
		set_state(account_state())
	if begin_block_reason() != "":
		return {"ok": false, "code": "blocked"}
	var params := start_params()
	var r: Dictionary
	if start_hook.is_valid():
		r = await start_hook.call(params)
	else:
		r = await RunState.begin_run(params)
	if not r.get("ok", false):
		if String(r.get("code", "")) == "unauthenticated":
			# Session expired or revoked after the screen opened: same message as a guest, no retry banner.
			set_state("guest")
			return r
		var code := String(r.get("code", "?"))
		if code == "run_in_progress":
			# A saved run can resume the run the server still holds: offer Continue, never abandon it here.
			begin_error = ""
			set_state("open_run")
			return r
		var msg := begin_error_text(code)
		begin_error = msg[0]
		_add_banner(msg[0], msg[1], false)
		return r
	begin_error = ""
	if not no_scene_change and is_inside_tree():
		get_tree().change_scene_to_file(RUN_MAP)
	return r


## [title, detail] shown when Begin fails with `code` (RunState.begin_run -> RemoteEpochSource create error).
## Pure, so a test can check every code. "Nothing was spent" holds: no run was created.
static func begin_error_text(code: String) -> Array:
	match code:
		"run_open":
			return ["An old run is still open on the server", "We could not close it. Nothing was spent. Try again in a moment."]
		"daily_tries":
			return ["No Daily tries left today", "Daily resets at 00:00 UTC. Nothing was spent."]
		"daily_cap":
			return ["No runs left today", "You reached today's run limit. It resets at 00:00 UTC. Nothing was spent."]
		"not_available":
			return ["Not available yet", "This kind of run is not open right now. Nothing was spent."]
		"newcomer_locked":
			return ["Ranked unlocks after 5 runs", "Play 5 runs with at least one fight first. Nothing was spent."]
		"vault_banned":
			return ["Imported Axies can't play Ranked", "Take them out of the party or pick another kind. Nothing was spent."]
		"version":
			return ["Update the game", "This version is too old to start a run. Reload to get the latest. Nothing was spent."]
		"offline":
			return ["Can't reach the dice server", "Check your connection and try again. Nothing was spent."]
	return ["Could not roll dice, try again.", "Nothing was spent. Code: %s" % code]


func open_picker(slot: int) -> void:
	_picker_slot = slot
	_picker_tab = "all"
	_picker_cls = "all"
	_picker_sel = ""
	_show_picker()


func open_leaderboard() -> void:
	if is_newcomer():
		return
	_show_leaderboard_popup()


## Full Leaderboard screen (the popup's secondary button).
func open_full_leaderboard() -> void:
	if is_newcomer():
		return
	if is_inside_tree() and not no_scene_change:
		LandNav.open(&"leaderboard")


## UI-03 35: top 5 for the picked Ascension, own row pinned under them. States: loading, error, normal.
func _show_leaderboard_popup() -> void:
	var v := _modal_box(640, "LeaderboardPopup")
	var asc_n := ascension
	v.add_child(_lbl(tr("Leaderboard"), "LabelScreenTitle"))
	var sub := _lbl(tr("Ascension %d · this season") % asc_n, "LabelMuted")
	sub.name = "LbSub"
	v.add_child(sub)
	var rows_box := VBoxContainer.new()
	rows_box.name = "LbRows"
	rows_box.add_theme_constant_override("separation", 8)
	v.add_child(rows_box)
	var loading := _lbl(tr("Loading..."), "LabelMuted")
	rows_box.add_child(loading)
	var acts := HBoxContainer.new()
	acts.add_theme_constant_override("separation", 16)
	acts.alignment = BoxContainer.ALIGNMENT_END
	v.add_child(acts)
	var close := UI3.button(tr("Close"), &"secondary", &"M")
	close.name = "CloseLeaderboard"
	close.pressed.connect(close_modal)
	acts.add_child(close)
	var full := UI3.button(tr("Full Leaderboard"), &"primary", &"M")
	full.name = "FullLeaderboard"
	full.pressed.connect(open_full_leaderboard)
	acts.add_child(full)
	_focus_later(close)
	_lb_load(rows_box, acts, full, loading)


## Fetches the board into rows_box. On error "Try again" becomes the primary and "Full Leaderboard" drops to secondary.
func _lb_load(rows_box: VBoxContainer, acts: HBoxContainer, full: Button, loading: Control) -> void:
	var src: LeaderboardSource = lb_source if lb_source != null else LeaderboardSource.make_default()
	var asc_n := ascension
	src.fetch({"asc": asc_n, "period": "season", "mode": mode}, func(res: Dictionary) -> void:
		if not is_instance_valid(rows_box):
			return
		for c in rows_box.get_children():
			c.queue_free()
		if not bool(res.get("ok", false)):
			var e := _lbl(tr("Can't load the board right now. Try again later."), "LabelMuted")
			e.name = "LbError"
			e.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			rows_box.add_child(e)
			if is_instance_valid(full):
				acts.remove_child(full)
				full.queue_free()
			var full2 := UI3.button(tr("Full Leaderboard"), &"secondary", &"M")
			full2.name = "FullLeaderboard"
			full2.pressed.connect(open_full_leaderboard)
			acts.add_child(full2)
			var retry := UI3.button(tr("Try again"), &"primary", &"M")
			retry.name = "LbRetry"
			retry.pressed.connect(func() -> void:
				for c in rows_box.get_children():
					c.queue_free()
				rows_box.add_child(_lbl(tr("Loading..."), "LabelMuted"))
				acts.remove_child(retry)
				retry.queue_free()
				_lb_load(rows_box, acts, full2, null))
			acts.add_child(retry)
			_focus_later(retry)
			return
		var rows: Array = res.get("rows", [])
		if rows.is_empty():
			rows_box.add_child(_lbl(tr("No scores yet this season."), "LabelMuted"))
		for i in mini(5, rows.size()):
			rows_box.add_child(_lb_row(rows[i], false))
		var me: Dictionary = res.get("me", {})
		if not me.is_empty():
			var mr := _lb_row(me, true)
			mr.name = "LbMe"
			rows_box.add_child(mr)
		if String(res.get("updated", "")) != "":
			rows_box.add_child(_lbl(tr("Last updated %s") % String(res["updated"]), "LabelMuted")))


func _lb_row(r: Dictionary, own: bool) -> PanelContainer:
	var p := UI3.plate(&"plate")
	p.custom_minimum_size.y = 56
	if own:
		p.theme_type_variation = "PanelCardSelected"
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	p.add_child(h)
	var rk := _lbl("#%d" % int(r.get("rank", 0)), "LabelTitle")
	rk.custom_minimum_size.x = 64
	h.add_child(rk)
	var nm := _lbl(String(r.get("name", tr("You"))).substr(0, 20), "LabelTitle")
	nm.clip_text = true
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(nm)
	h.add_child(_lbl(UI3.fmt(int(r.get("score", 0))), "LabelTitle"))
	return p


# ---------------------------------------------------------------- team presets (R3 M2)

## Loads a saved team into the party. Seats whose Axie is gone stay empty. False if no such preset.
func load_preset(i: int) -> bool:
	if i < 0 or i >= TeamPresets.count():
		return false
	var usable := TeamPresets.usable_party(MetaState.team_presets[i])
	party = []
	for k in usable:
		party.append(k)
	_refresh_party()
	_refresh_footer()
	close_modal()
	return true


## Saves the current party under `name` in the first free slot. Returns "" or the reason it failed.
func save_preset(name: String) -> String:
	var padded: Array = []
	for i in PARTY_SIZE:
		padded.append(party[i] if i < party.size() else "")
	var r := TeamPresets.add(name, padded)
	if r == "":
		close_modal()
	return r


# ---------------------------------------------------------------- UI-03 (A4 Blend) helpers

func _lbl(text: String, variation := "") -> Label:
	return UI3.label(text, variation)


## Selected = 4 px cream outline on the button's own styles (never the focus ring).
func _mark_selected(b: Button, on: bool) -> void:
	for k in ["normal", "hover", "pressed"]:
		var base: StyleBox = b.get_meta("base_" + k) if b.has_meta("base_" + k) else null
		if on:
			var src: StyleBox = base if base != null else b.get_theme_stylebox(k)
			var sb := src.duplicate() as StyleBoxFlat
			if sb != null:
				sb.border_color = UI3Theme.color("selected_outline")
				sb.set_border_width_all(UI3Theme.stroke("selected"))
				b.add_theme_stylebox_override(k, sb)
		elif base != null:
			b.add_theme_stylebox_override(k, base)
		else:
			b.remove_theme_stylebox_override(k)


## 4 px cream outline drawn as an overlay child, for tall buttons (picker tile, preset row).
func _outline(b: Button, on: bool) -> void:
	var o := b.get_node_or_null("SelOutline") as Panel
	if o == null:
		if not on:
			return
		o = Panel.new()
		o.name = "SelOutline"
		o.set_anchors_preset(Control.PRESET_FULL_RECT)
		o.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sb := StyleBoxFlat.new()
		sb.draw_center = false
		sb.border_color = UI3Theme.color("selected_outline")
		sb.set_border_width_all(UI3Theme.stroke("selected"))
		sb.set_corner_radius_all(UI3Theme.radius("m"))
		o.add_theme_stylebox_override("panel", sb)
		b.add_child(o)
	o.visible = on


## Narrower horizontal padding so six difficulty cells fit the 384 px inside the plate.
func _tight(b: Button) -> void:
	for k in ["normal", "hover", "pressed", "disabled"]:
		var sb := b.get_theme_stylebox(k).duplicate() as StyleBoxFlat
		if sb == null:
			continue
		sb.content_margin_left = 4
		sb.content_margin_right = 4
		b.add_theme_stylebox_override(k, sb)
		if k != "disabled":
			b.set_meta("base_" + k, sb)


## Full-rect scrim + centred dialog plate. Returns the VBox inside the plate (dim -> Center -> plate -> v).
func _modal_box(width: float, plate_name: String) -> VBoxContainer:
	close_modal()
	var dim := ColorRect.new()
	dim.color = UI3Theme.color("scrim")
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_modal_layer.add_child(dim)
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(c)
	var p := UI3.plate(&"dialog")
	p.name = plate_name
	p.custom_minimum_size.x = width
	c.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	p.add_child(v)
	return v


func open_load_presets() -> void:
	_show_presets("load")


func open_save_preset() -> void:
	_show_presets("save")


## UI-03 34: one modal, two tabs (Load / Save current). Load rows are 72 high; a row with a missing Axie says so.
func _show_presets(tab: String) -> void:
	_presets_tab = tab
	var v := _modal_box(640, "LoadPresets" if tab == "load" else "SavePresetModal")
	v.add_child(_lbl(tr("Team presets"), "LabelScreenTitle"))
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	v.add_child(tabs)
	var tl := UI3.tab(tr("Load"), tab == "load")
	tl.name = "TabLoad"
	tl.pressed.connect(func() -> void: _show_presets("load"))
	tabs.add_child(tl)
	var ts := UI3.tab(tr("Save current"), tab == "save")
	ts.name = "TabSave"
	ts.pressed.connect(func() -> void: _show_presets("save"))
	tabs.add_child(ts)
	var acts := HBoxContainer.new()
	acts.add_theme_constant_override("separation", 16)
	acts.alignment = BoxContainer.ALIGNMENT_END
	var cancel := UI3.button(tr("Cancel"), &"secondary", &"M")
	cancel.name = "ClosePresets"
	cancel.pressed.connect(close_modal)
	if tab == "load":
		_presets_load_body(v, acts)
	else:
		_presets_save_body(v, acts)
	v.add_child(acts)
	acts.add_child(cancel)
	acts.move_child(cancel, 0)
	if tab == "load":
		_focus_later(cancel)


func _presets_load_body(v: VBoxContainer, acts: HBoxContainer) -> void:
	if TeamPresets.count() == 0:
		var none := _lbl(tr("No saved teams yet. Build one in Team presets (House)."), "LabelMuted")
		none.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(none)
	var go := UI3.button(tr("Load team"), &"primary", &"M")
	go.name = "ConfirmLoadPreset"
	UI3.set_disabled_reason(go, tr("Load team") + " · " + tr("Pick a team"))
	var rows: Array[Button] = []
	for i in TeamPresets.count():
		var e: Dictionary = MetaState.team_presets[i]
		var miss := TeamPresets.missing_count(e)
		var b := UI3.button("%s%s" % [String(e["name"]).substr(0, 20), " · %d seats empty" % miss if miss > 0 else ""], &"secondary", &"M")
		b.name = "Preset%d" % i
		b.custom_minimum_size.y = 72
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		b.pressed.connect(func() -> void:
			for o in rows:
				_outline(o, o == b)
			go.set_meta("preset", i)
			UI3.clear_disabled_reason(go))
		rows.append(b)
		v.add_child(b)
	go.pressed.connect(func() -> void:
		if go.has_meta("preset"):
			load_preset(int(go.get_meta("preset"))))
	acts.add_child(go)


func _presets_save_body(v: VBoxContainer, acts: HBoxContainer) -> void:
	var edit := LineEdit.new()
	edit.name = "PresetName"
	edit.max_length = TeamPresets.NAME_MAX
	edit.text = "Team %d" % (TeamPresets.count() + 1)
	edit.custom_minimum_size = Vector2(0, 48)
	v.add_child(edit)
	var slotline := _lbl(tr("Saves to slot %d") % (TeamPresets.count() + 1), "LabelMuted")
	v.add_child(slotline)
	var save := UI3.button(tr("Save team"), &"primary", &"M")
	save.name = "ConfirmSavePreset"
	var refresh_save := func(_t := "") -> void:
		var why := TeamPresets.save_block_reason(party)
		if why == "" and TeamPresets.clean_name(edit.text) == "":
			why = tr("Give the team a name")
		if why == "" and not TeamPresets.has_room():
			why = tr("All preset slots are used")
		if why == "":
			UI3.clear_disabled_reason(save)
		else:
			UI3.set_disabled_reason(save, tr("Save team") + " · " + why)
	edit.text_changed.connect(refresh_save)
	refresh_save.call()
	save.pressed.connect(func() -> void: save_preset(edit.text))
	acts.add_child(save)
	_focus_later(edit)


func _focus_later(c: Control) -> void:
	var f := func() -> void:
		if is_instance_valid(c) and c.is_inside_tree():
			c.grab_focus()
	f.call_deferred()


func close_modal() -> void:
	for c in _modal_layer.get_children():
		_modal_layer.remove_child(c)
		c.queue_free()


# ---------------------------------------------------------------- build

func _initial_party() -> Array[String]:
	var src: Array[String] = MainMenu.pending_team if not MainMenu.pending_team.is_empty() \
		else MainMenu.DEFAULT_TEAM
	# One-shot hand-off (Vault / Guides / Presets): consume it so it never leaks into a later setup.
	MainMenu.pending_team = []
	var out: Array[String] = []
	for k in src:
		if ContentDB.heroes.has(k) and out.size() < PARTY_SIZE and (TeamPresets.may_repeat(k) or not out.has(k)):
			out.append(k)
	return out


func _build() -> void:
	theme = UI3Theme.get_theme()
	var bg := ColorRect.new()
	bg.name = "PlateHost"   # screen backdrop (neutral-1); the 3D party view will draw over it
	bg.color = UI3Theme.color("bg")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Left plate 432 w: header, banners, mode, length, difficulty.
	_panel = UI3.plate(&"plate")
	_panel.name = "Panel"
	_panel.custom_minimum_size.x = 432
	_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_panel.offset_left = 24
	_panel.offset_top = 24
	add_child(_panel)
	var col := VBoxContainer.new()
	col.name = "Col"
	col.add_theme_constant_override("separation", 16)
	_panel.add_child(col)
	col.add_child(_build_header())
	_banner_host = VBoxContainer.new()
	_banner_host.add_theme_constant_override("separation", 8)
	col.add_child(_banner_host)
	_body = VBoxContainer.new()
	_body.name = "Body"
	_body.add_theme_constant_override("separation", 16)
	col.add_child(_body)
	_build_mode_col()
	_build_asc_col()

	# Party over the 3D safe area (480,200 -> 1896,840).
	_stage = Control.new()
	_stage.name = "Stage"
	_stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)
	var area := VBoxContainer.new()
	area.name = "PartyArea"
	area.set_anchors_preset(Control.PRESET_TOP_LEFT)
	area.offset_left = 480
	area.offset_top = 40
	area.offset_right = 1896
	area.add_theme_constant_override("separation", 16)
	_stage.add_child(area)
	_party_label = _lbl("", "LabelTitle")
	area.add_child(_party_label)
	_party_row = HBoxContainer.new()
	_party_row.name = "PartyRow"
	_party_row.add_theme_constant_override("separation", 88)
	area.add_child(_party_row)

	if not is_newcomer():
		var kit := _build_kit_col()
		kit.set_anchors_preset(Control.PRESET_TOP_LEFT)   # under the party block, same left edge
		kit.offset_left = 480
		kit.offset_top = 520
		_stage.add_child(kit)

	# Bottom right: reason line above, actions below.
	var br := VBoxContainer.new()
	br.name = "Actions"
	br.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	br.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	br.grow_vertical = Control.GROW_DIRECTION_BEGIN
	br.offset_right = -24
	br.offset_bottom = -24
	br.add_theme_constant_override("separation", 12)
	_stage.add_child(br)
	_footer_msg = _lbl("")
	_footer_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_footer_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_footer_msg.custom_minimum_size.x = 560
	br.add_child(_footer_msg)
	var acts := HBoxContainer.new()
	acts.alignment = BoxContainer.ALIGNMENT_END
	acts.add_theme_constant_override("separation", 16)
	br.add_child(acts)
	var lb := UI3.button(tr("Leaderboard"), &"quiet")
	lb.name = "LeaderboardBtn"
	lb.disabled = is_newcomer()
	lb.tooltip_text = tr("Opens after %d runs") % NEWCOMER_RUNS if is_newcomer() else ""
	lb.pressed.connect(open_leaderboard)
	acts.add_child(lb)
	var khB := UI3.key_hint("B")
	khB.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	acts.add_child(khB)
	var save_b := UI3.button(tr("Save preset"), &"quiet")
	save_b.name = "SavePreset"
	save_b.pressed.connect(open_save_preset)
	acts.add_child(save_b)
	var khS := UI3.key_hint("S")
	khS.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	acts.add_child(khS)
	var load_b := UI3.button(tr("Team presets"), &"secondary", &"M")
	load_b.name = "LoadPreset"
	load_b.pressed.connect(open_load_presets)
	acts.add_child(load_b)
	_begin_btn = UI3.button(tr("Start run"), &"primary", &"L")
	_begin_btn.name = "Begin"
	_begin_btn.pressed.connect(func() -> void: begin())
	acts.add_child(_begin_btn)

	_modal_layer = Control.new()
	_modal_layer.name = "Modals"
	_modal_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_modal_layer)

	_refresh_party()
	_refresh_mode()
	_refresh_asc()


func _build_header() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var back := UI3.button(tr("← Back  Esc"), &"quiet")
	back.name = "Back"
	back.pressed.connect(_on_back)
	row.add_child(back)
	var title := _lbl(tr("Run setup"), "LabelScreenTitle")
	title.name = "Title"
	row.add_child(title)
	return row


func _refresh_party() -> void:
	if _party_row == null:
		return
	for c in _party_row.get_children():
		_party_row.remove_child(c)
		c.queue_free()
	_party_label.text = tr("Party · %d of %d") % [filled_count(), PARTY_SIZE]
	for i in PARTY_SIZE:
		_party_row.add_child(_build_slot(i))
	_refresh_kind()


## One party seat: 168 square preview (class colour stand-in until the 3D view lands) + a 200 w plate.
func _build_slot(i: int) -> Control:
	var key := party[i] if i < party.size() else ""
	var card := VBoxContainer.new()
	card.name = "Slot%d" % i
	card.custom_minimum_size.x = 200
	card.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	card.add_theme_constant_override("separation", 8)
	var preview := Panel.new()
	preview.name = "Preview"
	preview.custom_minimum_size = Vector2(168, 168)
	preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var psb := StyleBoxFlat.new()
	psb.set_corner_radius_all(UI3Theme.radius("m"))
	preview.add_theme_stylebox_override("panel", psb)
	card.add_child(preview)
	if key == "":
		psb.draw_center = false
		psb.border_color = UI3Theme.color("disabled_border")
		psb.set_border_width_all(2)
		var pick := UI3.button(tr("+ Add Axie"), &"secondary", &"M")
		pick.name = "Pick"
		pick.set_anchors_preset(Control.PRESET_FULL_RECT)
		pick.pressed.connect(open_picker.bind(i))
		var flat := StyleBoxEmpty.new()
		for k in ["normal", "hover", "pressed"]:
			pick.add_theme_stylebox_override(k, flat)
		preview.add_child(pick)
		return card
	var def: Dictionary = ContentDB.heroes.get(key, {})
	var cls := String(def.get("cls", ""))
	psb.bg_color = UI3Theme.color("viewport")
	var port_path := "res://assets/portraits/%s.png" % cls
	if ResourceLoader.exists(port_path):
		var pic := TextureRect.new()
		pic.name = "Portrait"
		pic.texture = load(port_path)
		pic.set_anchors_preset(Control.PRESET_FULL_RECT)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		preview.add_child(pic)
	else:
		var initial := _lbl(String(def.get("n", key)).substr(0, 1), "LabelScreenTitle")
		initial.set_anchors_preset(Control.PRESET_FULL_RECT)
		initial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		initial.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		preview.add_child(initial)
	var plate := UI3.plate(&"plate")
	card.add_child(plate)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	plate.add_child(v)
	var nm := _lbl(String(def.get("n", key)), "LabelTitle")
	nm.clip_text = true
	nm.custom_minimum_size.x = 150
	v.add_child(nm)
	var vault := MetaState.is_vault_key(key)
	var meta := _lbl("%s · %s" % [cls.capitalize(), tr("Vault") if vault else tr("Starter")], "LabelMuted")
	meta.clip_text = true
	v.add_child(meta)
	v.add_child(_lbl(tr("Max HP %d") % int(def.get("max_hp", 0)), "LabelMuted"))
	var acts := HBoxContainer.new()
	acts.add_theme_constant_override("separation", 8)
	v.add_child(acts)
	var swap := UI3.button(tr("Swap"), &"secondary", &"S")
	swap.name = "Swap"
	swap.pressed.connect(open_picker.bind(i))
	acts.add_child(swap)
	var clr := UI3.button(tr("Clear"), &"secondary", &"S")
	clr.name = "Clear"
	clr.pressed.connect(clear_slot.bind(i))
	acts.add_child(clr)
	return card


func _build_mode_col() -> void:
	_body.add_child(_lbl(tr("Mode"), "LabelMuted"))
	for k in ["normal", "daily", "ranked"]:
		var b := UI3.button(String(k).capitalize(), &"secondary", &"M")
		b.name = "Mode" + String(k).capitalize()
		b.toggle_mode = true
		b.pressed.connect(select_kind.bind(k))
		_kind_btns[k] = b
		_body.add_child(b)
	_refresh_kind()
	var grp := ButtonGroup.new()
	var lrow := HBoxContainer.new()
	lrow.add_theme_constant_override("separation", 8)
	_body.add_child(lrow)
	_short_btn = UI3.button(tr("Short"), &"secondary", &"M")
	_short_btn.name = "LenShort"
	_short_btn.toggle_mode = true
	_short_btn.button_group = grp
	_short_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_short_btn.pressed.connect(select_length.bind("short"))
	lrow.add_child(_short_btn)
	_full_btn = UI3.button(tr("Full"), &"secondary", &"M")
	_full_btn.name = "LenFull"
	_full_btn.toggle_mode = true
	_full_btn.button_group = grp
	_full_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_full_btn.pressed.connect(func() -> void:
		if not select_length("full"):
			_refresh_mode())
	if not is_full_unlocked():
		_full_btn.tooltip_text = tr("Win a Short run to unlock Full")
	lrow.add_child(_full_btn)
	_mode_detail = _lbl("", "LabelMuted")
	_mode_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mode_detail.custom_minimum_size.x = 384
	_body.add_child(_mode_detail)


func _refresh_mode() -> void:
	if _short_btn == null:
		return
	var full_ok := is_full_unlocked()
	_short_btn.set_pressed_no_signal(mode == "short")
	_full_btn.set_pressed_no_signal(mode == "full")
	_mark_selected(_short_btn, mode == "short")
	_mark_selected(_full_btn, mode == "full" and full_ok)
	_full_btn.text = tr("Full") if full_ok else tr("Full · locked")
	var cfg: Dictionary = RunMapGenerator.MODE_CONFIG.get(mode, {})
	var txt := "%s · %d rows · %d bosses" % [mode.capitalize(), int(cfg.get("total_rows", 0)),
		(cfg.get("boss_rows", []) as Array).size()]
	if not full_ok:
		txt += "\n" + tr("Full is locked. Win a Short run to unlock Full.")
	_mode_detail.text = txt


func _build_asc_col() -> void:
	_body.add_child(_lbl(tr("Difficulty"), "LabelMuted"))
	_asc_chips.clear()
	if is_newcomer():
		var one := _lbl(tr("Difficulty opens after %d runs. You play A0 · Normal.") % NEWCOMER_RUNS)
		one.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		one.custom_minimum_size.x = 384
		_body.add_child(one)
	else:
		var grid := GridContainer.new()
		grid.name = "AscGrid"
		grid.columns = 6
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		_body.add_child(grid)
		for n in ASC_MAX + 1:
			var b := UI3.button("A%d" % n, &"secondary", &"S")
			b.name = "Asc%d" % n
			b.toggle_mode = false
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.add_theme_constant_override("icon_max_width", 14)
			b.add_theme_constant_override("h_separation", 2)
			b.custom_minimum_size.x = 0
			b.pressed.connect(_on_asc_pressed.bind(n))
			grid.add_child(b)
			_tight(b)
			_asc_chips.append(b)
	_asc_title = _lbl("", "LabelTitle")
	_body.add_child(_asc_title)
	_asc_mult = _lbl("", "LabelMuted")
	_asc_mult.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_asc_mult.custom_minimum_size.x = 384
	_body.add_child(_asc_mult)
	_asc_rule = _lbl("")
	_asc_rule.name = "AscRule"
	_asc_rule.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_asc_rule.custom_minimum_size.x = 384
	_body.add_child(_asc_rule)
	_asc_tip = _lbl("")
	_asc_tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_asc_tip.custom_minimum_size.x = 384
	_asc_tip.add_theme_color_override("font_color", UI3Theme.color("danger_text"))
	_body.add_child(_asc_tip)


func _on_asc_pressed(n: int) -> void:
	if not select_ascension(n):
		_asc_tip.text = tr("Win a run at A%d to unlock A%d") % [n - 1, n]


func _refresh_asc() -> void:
	if _asc_title == null:
		return
	_asc_tip.text = ""
	var ceil := ascension_ceiling()
	for n in _asc_chips.size():
		var b := _asc_chips[n]
		var locked := n > ceil
		_mark_selected(b, n == ascension)
		b.icon = UI3.icon("ui_lock") if locked else null
		b.modulate.a = 0.6 if locked else 1.0
		b.tooltip_text = tr("Win a run at A%d to unlock A%d") % [n - 1, n] if locked else ""
	var m: Dictionary = ContentDB.ascension_mods(ascension)
	if ascension == 0:
		_asc_title.text = "A0 · Normal"
		var clk: Dictionary = m.get("clock", {})
		_asc_mult.text = tr("No extra rules")
		_asc_rule.text = tr("Light boss clock from turn %d") % int(clk.get("start", 14))
	else:
		_asc_title.text = "A%d · %s" % [ascension, RULES[ascension - 1][1]]
		_asc_mult.text = "%d rule%s active · Enemy HP ×%.2f · Damage ×%.2f · Boss HP ×%.2f" % [
			ascension, "" if ascension == 1 else "s", float(m.get("hp", 1.0)),
			float(m.get("dmg", 1.0)), float(m.get("boss_hp", 1.0))]
		var line: String = RULES[ascension - 1][2]
		_asc_rule.text = line


func _build_kit_col() -> Control:
	var p := UI3.plate(&"plate")
	p.name = "KitBoon"
	p.custom_minimum_size.x = 416
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	p.add_child(v)
	v.add_child(_lbl(tr("Aid for this run"), "LabelTitle"))
	for t in [["Starting Boon", "38 Gem ≈ 0.42 USD"], ["Run Kit", "60 Gem ≈ 0.67 USD"]]:
		var row := UI3.plate(&"row")
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 12)
		row.add_child(h)
		var names := VBoxContainer.new()
		names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		names.add_child(_lbl(t[0]))
		var sub := _lbl(t[1], "LabelMuted")
		names.add_child(sub)
		var nib_row := HBoxContainer.new()
		nib_row.add_theme_constant_override("separation", 8)
		var lock := TextureRect.new()
		lock.texture = UI3.icon("ui_lock")
		lock.custom_minimum_size = Vector2(20, 20)
		lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		nib_row.add_child(lock)
		var nib := _lbl(tr("Not in this build"), "LabelMuted")
		nib.name = "NotInBuild"
		nib_row.add_child(nib)
		names.add_child(nib_row)
		row.modulate.a = 0.6
		h.add_child(names)
		v.add_child(row)
	var f := _lbl(FAIRNESS, "LabelMuted")
	f.name = "Fairness"
	f.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	f.custom_minimum_size.x = 368
	v.add_child(f)
	return p


func _refresh_footer() -> void:
	if _footer_msg == null:
		return
	var why := begin_block_reason()
	var summary := "Party %d of %d · %s · A%d" % [filled_count(), PARTY_SIZE, mode.capitalize(), ascension]
	if kind != "normal":
		summary += " · " + kind.capitalize()
	_footer_msg.text = summary if why == "" else "%s\n%s" % [summary, why]
	if why == "":
		UI3.clear_disabled_reason(_begin_btn)
	elif filled_count() < PARTY_SIZE and state in ["normal", "offline", "guest"] and (kind == "normal" or kind_block_reason(kind) == ""):
		_begin_btn.text = tr("Start run") + " · %d of %d" % [filled_count(), PARTY_SIZE]
		_begin_btn.disabled = true
	else:
		UI3.set_disabled_reason(_begin_btn, why)


# ---------------------------------------------------------------- states

## One banner at a time: a new one replaces the old (two identical errors used to stack up).
func _clear_banners() -> void:
	for c in _banner_host.get_children():
		_banner_host.remove_child(c)   # out of the tree now, so a count right after this is already right
		c.queue_free()


func _add_banner(msg: String, detail: String, with_retry: bool, with_sign_in: bool = false) -> void:
	_clear_banners()
	var p := UI3.plate(&"notice")
	p.name = "Banner"
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	p.add_child(v)
	var t := _lbl(msg, "LabelTitle")
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.custom_minimum_size.x = 368
	v.add_child(t)
	var d := _lbl(detail)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size.x = 368
	v.add_child(d)
	if with_retry:
		var r := UI3.button(tr("Try again"), &"secondary", &"S")
		r.pressed.connect(func() -> void: set_state("normal"))
		v.add_child(r)
	if with_sign_in:
		var si := UI3.button(tr("Sign in"), &"primary", &"M")
		si.name = "SignInButton"
		si.pressed.connect(_on_sign_in)
		v.add_child(si)
	_banner_host.add_child(p)


## Opens the existing sign-in flow (AccountService: Google on web, browser flow on desktop).
func _on_sign_in() -> void:
	if sign_in_hook.is_valid():
		sign_in_hook.call()
	else:
		(account_service if account_service != null else AccountService).sign_in()


func _build_skeleton() -> void:
	var sk := VBoxContainer.new()
	sk.name = "Skeleton"
	sk.add_theme_constant_override("separation", 12)
	for i in 4:
		sk.add_child(UI3.skeleton_row())
	var col := _panel.get_node("Col")
	col.add_child(sk)
	col.move_child(sk, 2)


func _build_open_run() -> void:
	var holder := CenterContainer.new()
	holder.name = "OpenRun"
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	var card := UI3.plate(&"dialog")
	card.custom_minimum_size.x = 560
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	card.add_child(v)
	v.add_child(_lbl(tr("You have an unfinished run"), "LabelScreenTitle"))
	v.add_child(_lbl(tr("Saved run on disk"), "LabelMuted"))
	var cont := UI3.button(tr("Continue run"), &"primary", &"L")
	cont.name = "Continue"
	cont.pressed.connect(_on_continue)
	v.add_child(cont)
	var nw := UI3.button(tr("New run"), &"secondary", &"M")
	nw.name = "NewRun"
	nw.pressed.connect(_on_new_run)
	v.add_child(nw)
	var note := _lbl(tr("A new run ends the current run. Aid you used is not refunded."), "LabelMuted")
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size.x = 496
	v.add_child(note)
	holder.add_child(card)
	add_child(holder)
	move_child(holder, get_child_count() - 2)   # under the modal layer
	_focus_later(cont)


## "New run" on the unfinished-run card: the old run ends here (stake lost, save gone), as the card says.
## Without this the save would stay, and with server dice every Begin would answer "run in progress" again.
func _on_new_run() -> void:
	MetaState.settle_mission_stake(false, true)   # no-op unless a mission stake is open
	RunState.clear_saved_run()
	set_state("normal")


func _on_continue() -> void:
	if RunContinue.busy:
		return
	if not RunState.load_run():
		RunState.clear_saved_run()
		set_state("normal")
		return
	var st: String = await RunContinue.reconnect(self, _on_continue,
			find_child("Continue", true, false) as BaseButton)
	if st == "gone":
		set_state("normal")
		_on_back()   # Land shows RunState's discard notice
		return
	if st != "ok":
		return
	if not no_scene_change:
		get_tree().change_scene_to_file(COMBAT if not RunState.resume_combat.is_empty() else RUN_MAP)


func _on_back() -> void:
	if is_inside_tree() and not no_scene_change:
		LandNav.back_to_land()


# ---------------------------------------------------------------- picker

func _pick_keys() -> Array[String]:
	var keys: Array[String] = []
	if _picker_tab != "vault":
		keys.append_array(MainMenu.T1_HERO_KEYS)
	if _picker_tab != "starter":
		for entry in MetaState.vault:
			if MetaState.vault_stale(entry):
				continue
			var k := MetaState.vault_key(entry)
			if ContentDB.heroes.has(k) and not keys.has(k):
				keys.append(k)
	return keys


func _pick_classes() -> Array[String]:
	var cl: Array[String] = []
	for k in _pick_keys():
		var c := String(ContentDB.heroes[k].get("cls", ""))
		if c != "" and not cl.has(c):
			cl.append(c)
	return cl


## UI-03 33: modal 1120, class filter chips, 5-column grid of square previews, Cancel / "Put in slot n".
## A tile only selects; the primary button commits through set_slot().
func _show_picker() -> void:
	var v := _modal_box(1120, "Picker")
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	v.add_child(head)
	var t := _lbl(tr("Pick an Axie · slot %d") % (_picker_slot + 1), "LabelScreenTitle")
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var chips := HBoxContainer.new()
	chips.name = "PickerFilters"
	chips.add_theme_constant_override("separation", 8)
	v.add_child(chips)
	var opts: Array = [["all", tr("All")], ["starter", tr("Starter")], ["vault", tr("Vault")]]
	for o in opts:
		var tb := UI3.tab(String(o[1]), _picker_tab == o[0])
		tb.name = "Tab_" + String(o[0])
		tb.custom_minimum_size.y = 44
		tb.pressed.connect(func() -> void:
			_picker_tab = o[0]
			_show_picker())
		chips.add_child(tb)
	for c in _pick_classes():
		var cb := UI3.tab(c.capitalize(), _picker_cls == c)
		cb.name = "Class_" + c
		cb.custom_minimum_size.y = 44
		cb.pressed.connect(func() -> void:
			_picker_cls = "all" if _picker_cls == c else c
			_show_picker())
		chips.add_child(cb)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 570
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_picker_grid = GridContainer.new()
	_picker_grid.columns = 5
	_picker_grid.add_theme_constant_override("h_separation", 12)
	_picker_grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(_picker_grid)
	var put := UI3.button(tr("Put in slot %d") % (_picker_slot + 1), &"primary", &"M")
	put.name = "PutInSlot"
	var tiles: Array[Button] = []
	var shown := 0
	for k in _pick_keys():
		var def: Dictionary = ContentDB.heroes[k]
		var cls := String(def.get("cls", ""))
		if _picker_cls != "all" and cls != _picker_cls:
			continue
		shown += 1
		var taken := TeamPresets.seat_taken(party, _picker_slot, k)
		var b := _picker_tile(k, def, taken)
		b.pressed.connect(func() -> void:
			_picker_sel = k
			for o in tiles:
				_outline(o, o == b)
			UI3.clear_disabled_reason(put))
		tiles.append(b)
		_picker_grid.add_child(b)
		if k == _picker_sel:
			_outline.call_deferred(b, true)
	if shown == 0:
		var msg := tr("Your Vault is empty. Import an Axie in the Vault.") if _picker_tab == "vault" and _picker_cls == "all" else tr("No Axie matches this filter.")
		var em := _lbl(msg, "LabelMuted")
		em.name = "PickerEmpty"
		v.add_child(em)
	if _picker_sel == "" or not _pick_keys().has(_picker_sel):
		UI3.set_disabled_reason(put, tr("Put in slot %d") % (_picker_slot + 1) + " · " + tr("Pick an Axie"))
	put.pressed.connect(func() -> void:
		if _picker_sel != "" and swap_into_slot(_picker_slot, _picker_sel):
			close_modal())
	var acts := HBoxContainer.new()
	acts.add_theme_constant_override("separation", 16)
	acts.alignment = BoxContainer.ALIGNMENT_END
	v.add_child(acts)
	var cancel := UI3.button(tr("Cancel"), &"secondary", &"M")
	cancel.name = "CancelPicker"
	cancel.pressed.connect(close_modal)
	acts.add_child(cancel)
	acts.add_child(put)


## Square preview (portrait >= 160), name (ellipsis), class and Max HP. 50% and disabled when the Axie sits in another slot.
func _picker_tile(k: String, def: Dictionary, taken: bool) -> Button:
	var b := UI3.button("", &"secondary", &"M")
	b.name = "Tile_" + k
	b.custom_minimum_size = Vector2(188, 276)
	b.tooltip_text = tr("In slot %d · picking it swaps") % (party.find(k) + 1) if taken else ""
	b.set_meta("base_normal", b.get_theme_stylebox("normal"))
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 4)
	col.offset_left = 8
	col.offset_top = 8
	col.offset_right = -8
	col.offset_bottom = -8
	b.add_child(col)
	var cls := String(def.get("cls", ""))
	var pv := Panel.new()
	pv.custom_minimum_size = Vector2(168, 168)
	pv.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var psb := StyleBoxFlat.new()
	psb.bg_color = UI3Theme.color("viewport")
	psb.set_corner_radius_all(UI3Theme.radius("m"))
	pv.add_theme_stylebox_override("panel", psb)
	col.add_child(pv)
	var port_path := "res://assets/portraits/%s.png" % cls
	if ResourceLoader.exists(port_path):
		var pic := TextureRect.new()
		pic.texture = load(port_path)
		pic.set_anchors_preset(Control.PRESET_FULL_RECT)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pv.add_child(pic)
	var nm := _lbl(String(def.get("n", k)).substr(0, 20), "LabelTitle")
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nm.clip_text = true
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(nm)
	var sub := _lbl("%s · %s %d" % [cls.capitalize(), tr("HP"), int(def.get("max_hp", 0))], "LabelMuted")
	sub.clip_text = true
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(sub)
	if taken:
		b.modulate.a = 0.5
	return b
