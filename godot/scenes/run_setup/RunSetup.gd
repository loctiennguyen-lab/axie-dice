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
	[3, "Short Dice", "Base rerolls 2 → 1 · Core rerolls still add"],
	[4, "Boss Clock", "Enrage from turn 10: +20%/turn, max +100%"],
	[5, "Eternal Gift", "Elite Cores are Eternal (max 2) · weaken announced"],
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
var _block_reason: Label
## True from the Start click until the server answers (can take ~15 s when an old run has to be closed first).
var _busy := false
var _busy_text := ""
var _busy_gen := 0
## Screen-side guard: RunSession gives up after 3 x 8 s, so a hung start is released a bit later than that.
var start_timeout_s := 35.0
## Tests only: scene path to try instead of the run map.
var run_map_override := ""
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
var _anchor_lbl: Label
var _asc_lock: Label
var _full_lock: Label
const ANCHOR_STAGE := 2   ## mirrors RunState.anchor_gate_reason (depth_stage >= 2)
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
var _picker_obj: RunSetupPicker   ## popups (leaderboard, Axie picker, team presets); state stays on this screen


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
		load_daily_tries()   # BUG-0008: the first fetch ran before sign-in finished and was never repeated


func _unhandled_key_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo and ev.is_action_pressed(&"menu_back"):
		if _modal_layer.get_child_count() > 0:
			close_modal()
		else:
			_on_back()
		if is_inside_tree():   # a handler above may have changed scene
			get_viewport().set_input_as_handled()
	elif ev is InputEventKey and ev.pressed and not ev.echo and not ev.alt_pressed and not ev.ctrl_pressed \
			and not ev.meta_pressed and _modal_layer.get_child_count() == 0:
		if ev.keycode == KEY_B and not is_newcomer():
			open_leaderboard()
			if is_inside_tree():   # a handler above may have changed scene
				get_viewport().set_input_as_handled()
		elif ev.keycode == KEY_S:
			open_save_preset()
			if is_inside_tree():   # a handler above may have changed scene
				get_viewport().set_input_as_handled()


# ---------------------------------------------------------------- public API (also used by tests)

func ascension_ceiling() -> int:
	return mini(ASC_MAX, MetaState.asc_max)


func is_full_unlocked() -> bool:
	return MetaState.has_unlock("u_full")


## BUG-0001: the "Aid for this run" panel (Starting Boon / Run Kit, Gem prices) only shows when buying Aid on
## this screen exists in the build. Switch: `setup_aid_enabled` in assets/data/economy/aid_prices.json (false in
## the beta, store off). Turn it on and the panel comes back as it was.
static func setup_aid_enabled() -> bool:
	return bool(EconomyDBScript.get_table("aid_prices").get("setup_aid_enabled", false))


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
		"newcomer": is_newcomer(), "depth_stage": MetaState.depth_stage(),
		"anchor": true}   # opt-in; the engine itself refuses ranked / daily / stage < 2


## Fetches the Daily tries. Only meaningful when dice are server-rolled; quiet on failure (the buttons
## then stay disabled with the reason).
func load_daily_tries() -> void:
	if not remote_on and not daily_info_hook.is_valid():
		return
	var cb := func(ok: bool, data: Dictionary) -> void:
		if ok:
			daily_tries = {"used": int(data.get("used", 0)), "max": int(data.get("max", 3))}
		elif not MetaState.server_daily().is_empty():
			daily_tries = MetaState.server_daily()   # BUG-0008: the /api/econ copy when /api/run/daily failed
		_refresh_kind()
		_refresh_footer()
	if daily_info_hook.is_valid():
		daily_info_hook.call(cb)
	else:
		RunState.run_session().daily_info(cb)


func _party_has_vault() -> bool:
	return MetaState.team_has_vault_pick(party)


## True when the account is a guest or its session expired (works with or without remote dice).
func _signed_out() -> bool:
	var svc: Node = account_service if account_service != null else AccountService
	var st: int = account_status_hook.call() if account_status_hook.is_valid() else svc.status
	return st == AccountService.Status.GUEST or st == AccountService.Status.EXPIRED


## One line under Mode: Anchors exist, when they unlock, and whether they are open now.
func anchor_line() -> String:
	var open := MetaState.depth_stage() >= ANCHOR_STAGE
	if kind != "normal":
		return tr("Anchor: only in Normal runs.")
	if open:
		return tr("Anchor: unlocked. You pick one at the start of the run.")
	return tr("Anchor: locked. You pick one at the start of the run once you reach stage %d.") % ANCHOR_STAGE


## Why `k` ("daily" | "ranked") cannot be picked right now, or "" when it can.
func kind_block_reason(k: String) -> String:
	if k == "normal":
		return ""
	if not remote_on:
		# Real reason, not dev wording: signed out -> sign in; otherwise no connection.
		return "Sign in to play %s" % String(k).capitalize() if _signed_out() else "Needs a connection"
	if state == "guest":
		return "Sign in to play %s" % String(k).capitalize()
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
		return "Opens after %d runs · %d of %d" % [need, mini(MetaState.gate_runs_with_battle(), need), need]
	if MetaState.depth_stage() < 3:
		return "Ranked opens at depth stage 3"
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


## Disabled look as in the frame (grey plate, lock icon + text as an HBox, no Button.icon). Not-locked: plain text.
func _set_lock_look(b: Button, locked: bool, txt: String, icon_px := 18, gap := 8) -> void:
	var old := b.get_node_or_null("LockRow")
	if old != null:
		b.remove_child(old)
		old.queue_free()
	for k in ["normal", "hover", "pressed", "focus"]:
		if locked:
			b.add_theme_stylebox_override(k, b.get_theme_stylebox("disabled"))
		else:
			b.remove_theme_stylebox_override(k)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		if locked:
			b.add_theme_color_override(c, b.get_theme_color("font_disabled_color"))
		else:
			b.remove_theme_color_override(c)
	b.icon = null
	if not locked:
		b.text = txt
		return
	b.text = ""
	var row := HBoxContainer.new()
	row.name = "LockRow"
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", gap)
	var ic := TextureRect.new()
	ic.name = "LockIcon"
	ic.texture = UI3.icon("ui_lock")
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.custom_minimum_size = Vector2(icon_px, icon_px)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(ic)
	var lb := Label.new()
	lb.name = "LockText"
	lb.text = txt
	lb.add_theme_color_override("font_color", b.get_theme_color("font_disabled_color"))
	lb.add_theme_font_override("font", b.get_theme_font("font"))
	lb.add_theme_font_size_override("font_size", b.get_theme_font_size("font_size"))
	lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(lb)
	b.add_child(row, true)


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
		b.set_pressed_no_signal(kind == k)
		_set_lock_look(b, why != "", "%s · %s" % [String(k).capitalize(), _kind_sub(k)])
		_mark_selected(b, kind == k)   # after the lock look: it resets the style overrides
	if _anchor_lbl != null:
		_anchor_lbl.text = anchor_line()


## Why Begin is disabled, or "" when it is allowed.
func begin_block_reason() -> String:
	if _busy:
		return _busy_text
	if state == "guest" and remote_on:
		return "Sign in to play"
	if state == "offline" and remote_on:
		return "Needs a connection to the server"
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
		_add_banner("Sign in to play", "Runs are played on the server, so they need an account.", false, true)
	elif s == "offline":
		if remote_on:
			_add_banner("Can't reach the server", "Last updated %s. Runs are played on the server in this build."
				% Time.get_time_string_from_system().substr(0, 5), true)
		else:
			_add_banner("You're offline", "Runs play on this device for now; progress syncs when you reconnect.", false)
	_refresh_footer()


## Begin. Uses start_hook if set (tests), otherwise RunState.begin_run().
func begin() -> Dictionary:
	if use_account and state in ["normal", "loading", "offline", "guest"] and account_state() != state:
		set_state(account_state())
	if _busy:
		return {"ok": false, "code": "busy"}
	if begin_block_reason() != "":
		return {"ok": false, "code": "blocked"}
	var params := start_params()
	var r: Dictionary
	_set_busy(true, tr("Starting…"))
	_busy_gen += 1
	var gen := _busy_gen
	if is_inside_tree():
		get_tree().create_timer(start_timeout_s).timeout.connect(func() -> void:
			if _busy and gen == _busy_gen:
				_set_busy(false)
				_add_banner("Couldn't start — try again", "Nothing was spent.", false))
	var sess: RunSession = null
	if not start_hook.is_valid() and RemoteEpochSource.flag_on():
		sess = RunState.run_session()
		sess.phase_changed.connect(_on_start_phase)
	if start_hook.is_valid():
		r = await start_hook.call(params)
	else:
		r = await RunState.begin_run(params)
	if sess != null and is_instance_valid(sess):
		sess.phase_changed.disconnect(_on_start_phase)
	var leaving: bool = r.get("ok", false) and not no_scene_change and is_inside_tree()
	if not leaving and gen == _busy_gen:
		_set_busy(false)   # success that changes scene stays busy: no second click while the map loads
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
		if UpdateRequired.is_update_code(code) and is_inside_tree():
			UpdateRequired.show(self, code)   # Begin refused by an old build: update modal, banner stays as the fallback
		var msg := begin_error_text(code)
		begin_error = msg[0]
		_add_banner(msg[0], msg[1], false)
		return r
	begin_error = ""
	if not no_scene_change and is_inside_tree():
		var err := get_tree().change_scene_to_file(run_map_override if run_map_override != "" else RUN_MAP)
		if err != OK:
			_set_busy(false)
			begin_error = "Couldn't open the run map"
			_add_banner("Couldn't open the run map", "Try Start run again.", false)
	return r


func _set_busy(on: bool, text := "") -> void:
	_busy = on
	_busy_text = text if on else ""
	if is_inside_tree() and _footer_msg != null:
		_refresh_footer()


## RunSession tells us which step the server call is on (RemoteEpochSource._recover_open_run).
func _on_start_phase(phase: String) -> void:
	if _busy and phase == "closing_old":
		_set_busy(true, tr("Closing your old run…"))
	elif _busy and phase == "creating":
		_set_busy(true, tr("Starting…"))


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
		"version", "mission_needs_update":
			return ["Update the game", "This version is too old to start a run. Reload to get the latest. Nothing was spent."]
		"offline":
			return ["Can't reach the server", "Check your connection and try again. Nothing was spent."]
	return ["Could not start the run, try again.", "Nothing was spent. Code: %s" % code]


## Lazy: tests build the screen with no tree, so this cannot wait for _ready.
func _picker() -> RunSetupPicker:
	if _picker_obj == null:
		_picker_obj = RunSetupPicker.new(self)
	return _picker_obj


func open_picker(slot: int) -> void:
	_picker().open_picker(slot)


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
	_picker()._show_leaderboard_popup()


## Fetches the board into rows_box. On error "Try again" becomes the primary and "Full Leaderboard" drops to secondary.
func _lb_load(rows_box: VBoxContainer, acts: HBoxContainer, full: Button, loading: Control) -> void:
	_picker()._lb_load(rows_box, acts, full, loading)


func _lb_row(r: Dictionary, own: bool) -> PanelContainer:
	return _picker()._lb_row(r, own)

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
	if b.get_node_or_null("LockRow") != null:
		return   # locked: keeps the disabled look
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
	_picker()._show_presets(tab)


func _presets_load_body(v: VBoxContainer, acts: HBoxContainer) -> void:
	_picker()._presets_load_body(v, acts)


func _presets_save_body(v: VBoxContainer, acts: HBoxContainer) -> void:
	_picker()._presets_save_body(v, acts)


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
	_panel.name = "SetupColumn"
	_panel.custom_minimum_size.x = UI3Theme.size_of("setup_col_w")
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
	area.offset_left = 24 + UI3Theme.size_of("setup_col_w") + 24
	area.offset_top = 24
	area.offset_right = 1896
	area.add_theme_constant_override("separation", 16)
	_stage.add_child(area)
	_party_label = _lbl("", "LabelTitle")
	_party_label.name = "PartyHeader"
	area.add_child(_party_label)
	_party_row = HBoxContainer.new()
	_party_row.name = "PartyRow"
	_party_row.add_theme_constant_override("separation", UI3Theme.space("16"))
	area.add_child(_party_row)

	if not is_newcomer() and setup_aid_enabled():
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
	_footer_msg.name = "FooterLine"
	_footer_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_footer_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_footer_msg.custom_minimum_size.x = 0
	br.add_child(_footer_msg)
	_block_reason = _lbl("", "LabelMuted")
	_block_reason.name = "BlockReason"
	_block_reason.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	br.add_child(_block_reason)
	var acts := HBoxContainer.new()
	acts.alignment = BoxContainer.ALIGNMENT_END
	acts.add_theme_constant_override("separation", 16)
	br.add_child(acts)
	var lb := UI3.button(tr("Leaderboard"), &"quiet")
	lb.name = "LeaderboardButton"
	lb.disabled = is_newcomer()
	lb.tooltip_text = tr("Opens after %d runs") % NEWCOMER_RUNS if is_newcomer() else ""
	lb.pressed.connect(open_leaderboard)
	acts.add_child(lb)
	var save_b := UI3.button(tr("Save preset"), &"quiet")
	save_b.name = "SavePresetButton"
	save_b.pressed.connect(open_save_preset)
	acts.add_child(save_b)
	var load_b := UI3.button(tr("Team presets"), &"secondary", &"M")
	load_b.name = "TeamPresetsButton"
	load_b.pressed.connect(open_load_presets)
	acts.add_child(load_b)
	_begin_btn = UI3.button(tr("Start run"), &"primary", &"L")
	_begin_btn.name = "StartButton"
	_begin_btn.pressed.connect(func() -> void: begin())
	_begin_btn.custom_minimum_size.x = 300
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
	var back := UI3.button(tr("← Back"), &"quiet")
	back.name = "BackButton"
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
		_party_row.add_child(_build_slot(i), true)
	_refresh_kind()


## One party seat (frame PartySlot): a plate that fills its column, square portrait on top, then name / class / HP / Swap + Clear.
## Columns are equal (EXPAND_FILL, min width 0); the name is cut with an ellipsis, so text length never moves a column.
func _build_slot(i: int) -> Control:
	var key := party[i] if i < party.size() else ""
	var card := UI3.plate(&"plate")
	card.name = "PartySlot" if key != "" else "PartySlotEmpty"
	card.custom_minimum_size.x = 0
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI3Theme.space("8"))
	card.add_child(v)
	var ar := Control.new()
	ar.name = "PortraitBox"
	ar.resized.connect(func() -> void:   # square: height follows the column width
		if absf(ar.custom_minimum_size.y - ar.size.x) > 0.5:
			ar.custom_minimum_size.y = ar.size.x)
	v.add_child(ar)
	var preview := Panel.new()
	preview.name = "Preview"
	var psb := StyleBoxFlat.new()
	psb.set_corner_radius_all(UI3Theme.radius("m"))
	preview.add_theme_stylebox_override("panel", psb)
	preview.set_anchors_preset(Control.PRESET_FULL_RECT)
	ar.add_child(preview)
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
		initial.name = "Portrait"
		initial.set_anchors_preset(Control.PRESET_FULL_RECT)
		initial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		initial.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		preview.add_child(initial)
	var nm := _lbl("", "LabelTitle")
	nm.name = "Name"
	nm.custom_minimum_size.x = 0
	nm.clip_text = true
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER   # Liam 29/10: text under a picture is centred on it
	v.add_child(nm)
	Ui5Ellipsis.set_text(nm, String(def.get("n", key)))
	var vault := MetaState.is_vault_key(key)
	var meta := _lbl("%s · %s" % [cls.capitalize(), tr("Vault") if vault else tr("Starter")], "LabelMuted")
	meta.name = "ClassLine"
	meta.clip_text = true
	meta.custom_minimum_size.x = 0
	meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER   # Liam 29/10: text under a picture is centred on it
	v.add_child(meta)
	var hp := _lbl(tr("Max HP %d") % int(def.get("max_hp", 0)))
	hp.name = "HpLine"
	hp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER   # Liam 29/10: text under a picture is centred on it
	v.add_child(hp)
	var acts := HBoxContainer.new()
	acts.add_theme_constant_override("separation", UI3Theme.space("8"))
	v.add_child(acts)
	var swap := UI3.button(tr("Swap"), &"secondary", &"S")
	swap.name = "SwapButton"
	swap.custom_minimum_size.x = 0
	swap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	swap.pressed.connect(open_picker.bind(i))
	acts.add_child(swap)
	var clr := UI3.button(tr("Clear"), &"secondary", &"S")
	clr.name = "ClearButton"
	clr.custom_minimum_size.x = 0
	clr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clr.pressed.connect(clear_slot.bind(i))
	acts.add_child(clr)
	return card


func _build_mode_col() -> void:
	var ml := _lbl(tr("Mode"), "LabelMuted")
	ml.name = "ModeLabel"
	_body.add_child(ml)
	for k in ["normal", "daily", "ranked"]:
		var b := UI3.button(String(k).capitalize(), &"secondary", &"M")
		b.name = String(k).capitalize() + "Toggle"
		b.toggle_mode = true
		b.clip_text = true
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.pressed.connect(select_kind.bind(k))
		_kind_btns[k] = b
		_body.add_child(b)
	_refresh_kind()
	var grp := ButtonGroup.new()
	var lrow := HBoxContainer.new()
	lrow.add_theme_constant_override("separation", 8)
	_body.add_child(lrow)
	_short_btn = UI3.button(tr("Short"), &"secondary", &"M")
	_short_btn.name = "ShortToggle"
	_short_btn.toggle_mode = true
	_short_btn.clip_text = true
	_short_btn.button_group = grp
	_short_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_short_btn.pressed.connect(select_length.bind("short"))
	lrow.add_child(_short_btn)
	_full_btn = UI3.button(tr("Full"), &"secondary", &"M")
	_full_btn.name = "FullToggle"
	_full_btn.toggle_mode = true
	_full_btn.clip_text = true
	_full_btn.button_group = grp
	_full_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_full_btn.pressed.connect(func() -> void:
		if not select_length("full"):
			_refresh_mode())
	if not is_full_unlocked():
		_full_btn.tooltip_text = tr("Win a Short run to unlock Full")
	lrow.add_child(_full_btn)
	_mode_detail = _lbl("", "LabelMuted")
	_mode_detail.name = "LengthDetail"
	_mode_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mode_detail.custom_minimum_size.x = 0
	_body.add_child(_mode_detail)
	_full_lock = _lbl("", "LabelMuted")
	_full_lock.name = "FullLockLine"
	_full_lock.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_child(_full_lock)
	_anchor_lbl = _lbl("", "LabelMuted")
	_anchor_lbl.name = "AnchorLine"
	_anchor_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_anchor_lbl.custom_minimum_size.x = 0
	_body.add_child(_anchor_lbl)
	_anchor_lbl.text = anchor_line()


func _refresh_mode() -> void:
	if _short_btn == null:
		return
	var full_ok := is_full_unlocked()
	_short_btn.set_pressed_no_signal(mode == "short")
	_full_btn.set_pressed_no_signal(mode == "full")
	var cfg: Dictionary = RunMapGenerator.MODE_CONFIG.get(mode, {})
	var txt := "%s · %d rows · %d bosses" % [mode.capitalize(), int(cfg.get("total_rows", 0)),
		(cfg.get("boss_rows", []) as Array).size()]
	_mode_detail.text = txt
	_full_lock.text = "" if full_ok else tr("Full is locked. Win a Short run to unlock Full.")
	_full_lock.visible = not full_ok
	_full_btn.disabled = false   # stays clickable so the reason shows; drawn as disabled
	_set_lock_look(_full_btn, not full_ok, tr("Full") if full_ok else tr("Full · locked"))
	_mark_selected(_short_btn, mode == "short")
	_mark_selected(_full_btn, mode == "full" and full_ok)


func _build_asc_col() -> void:
	var dl := _lbl(tr("Difficulty"), "LabelMuted")
	dl.name = "DifficultyLabel"
	_body.add_child(dl)
	_asc_chips.clear()
	if is_newcomer():
		var one := _lbl(tr("Difficulty opens after %d runs. You play A0 · Normal.") % NEWCOMER_RUNS)
		one.name = "NewcomerLine"
		one.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		one.custom_minimum_size.x = 0
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
			b.name = "AscChipA%d" % n
			b.toggle_mode = false
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.add_theme_constant_override("icon_max_width", 14)
			b.add_theme_constant_override("h_separation", 2)
			b.custom_minimum_size.x = 0
			b.pressed.connect(_on_asc_pressed.bind(n))
			grid.add_child(b)
			_tight(b)
			_asc_chips.append(b)
	_asc_lock = _lbl("", "LabelMuted")
	_asc_lock.name = "UnlockLine"
	_asc_lock.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_asc_lock.custom_minimum_size.x = 0
	_asc_lock.visible = false
	if not is_newcomer():
		_body.add_child(_asc_lock)
	var det := VBoxContainer.new()
	det.name = "AscDetail"
	det.add_theme_constant_override("separation", 4)
	_body.add_child(det)
	_asc_title = _lbl("", "LabelTitle")
	_asc_title.name = "AscTitle"
	det.add_child(_asc_title)
	_asc_mult = _lbl("", "LabelMuted")
	_asc_mult.name = "AscRules"
	_asc_mult.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_asc_mult.custom_minimum_size.x = 0
	det.add_child(_asc_mult)
	_asc_rule = _lbl("")
	_asc_rule.name = "AscRule"
	_asc_rule.add_theme_color_override("font_color", UI3Theme.color("accent"))
	_asc_rule.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_asc_rule.custom_minimum_size.x = 0
	det.add_child(_asc_rule)
	_asc_tip = _lbl("")
	_asc_tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_asc_tip.custom_minimum_size.x = 0
	_asc_tip.add_theme_color_override("font_color", UI3Theme.color("danger_text"))
	_body.add_child(_asc_tip)


func _on_asc_pressed(n: int) -> void:
	if not select_ascension(n):
		_asc_tip.text = tr("Win a run at A%d to unlock A%d") % [n - 1, n]


func _refresh_asc() -> void:
	if _asc_title == null:
		return
	var ceil := ascension_ceiling()
	_asc_tip.text = ""
	if _asc_lock != null:
		_asc_lock.text = tr("A%d unlocks after you win A%d.") % [ceil + 1, ceil] if ceil < ASC_MAX else ""
		_asc_lock.visible = _asc_lock.text != ""
	for n in _asc_chips.size():
		var b := _asc_chips[n]
		var locked := n > ceil
		_set_lock_look(b, locked, "A%d" % n, 14, 4)
		_mark_selected(b, n == ascension)
		b.modulate.a = 1.0
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
	_refresh_footer_inner()


func _refresh_footer_inner() -> void:
	if _footer_msg == null:
		return
	var why := begin_block_reason()
	var summary := "Party %d of %d · %s · A%d" % [filled_count(), PARTY_SIZE, mode.capitalize(), ascension]
	if kind != "normal":
		summary += " · " + kind.capitalize()
	if _busy:
		_footer_msg.text = summary
		_block_reason.text = tr("This can take a few seconds. Please wait.")
		UI3.set_disabled_reason(_begin_btn, why)
		return
	_footer_msg.text = summary
	_block_reason.text = why
	_block_reason.visible = why != ""
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
	return _picker()._pick_keys()


func _pick_classes() -> Array[String]:
	return _picker()._pick_classes()


## UI-03 33: modal 1120, class filter chips, 5-column grid of square previews, Cancel / "Put in slot n".
## A tile only selects; the primary button commits through set_slot().
func _show_picker() -> void:
	_picker()._show_picker()


## Square preview (portrait >= 160), name (ellipsis), class and Max HP. 50% and disabled when the Axie sits in another slot.
func _picker_tile(k: String, def: Dictionary, taken: bool) -> Button:
	return _picker()._picker_tile(k, def, taken)
