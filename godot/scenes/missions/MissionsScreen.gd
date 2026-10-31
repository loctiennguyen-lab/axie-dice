class_name MissionsScreen
extends Control
## M6 Nhiem vu / Missions (key 3). Spec: design/handoffs/ui-02-round3 README section 2 M6, frames M6a-M6l.
## Board = MissionBoard.offers() on MetaState: tiers, stakes, multipliers, unlock gates and lock reasons
## are all read from economy/missions.json + rules/mission_rules.json. Nothing numeric lives here.
## Card follows the art-director decluttered layout: tier + mode, Stake / Pay / Stone tiles, rules line,
## button. Full rule rows, the m multiplier and the stake warning live in the confirm modal (M6c).
## Detail card (beta §5): rules in words, Stake -> Win back -> Net, estimated win chance (simulated) and average
## return on every tier, a warning on every tier whose win chance is under 50%, and a disabled Stake button that says why.
## The win chance is a BOT estimate (missions.json est_win_pct), labelled as simulated.
##
## Paying the stake: MetaState.take_mission_stake() escrows it and returns the mission id; RunState.end_run
## settles it, a failed begin_run refunds it, abandon is settled in SettingsView.
## Drawn: M6a/b board (locked tiers per lock_reason), M6c confirm, M6g newcomer, M6h not enough Shard,
## M6i open run, M6j offline, M6k guest, M6l tall (cards flow into a scroll, extra height to the grid).
## Not drawn: M6d/e/f results (belong to the Result screen), "table updated" line (no data).

const _Econ := preload("res://scripts/meta/economy_db.gd")
const PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")
const RUN_MAP := "res://scenes/run_map/RunMap.tscn"
const RULE_NAMES := {"M1": "Harsh clock", "M2": "Spike stack", "M3": "Hunted", "M4": "Heavy hits", "M5": "Thick boss", "M6": "Sturdy foes", "M7": "Fierce elites"}

## "normal" | "loading" | "offline" | "guest" | "open_run"
var state := "normal"
var no_scene_change := false
var use_account := true
var remote_on: bool = String(ProjectSettings.get_setting("axie/gem_wallet", "")) == "remote"
var account_status_hook: Callable

## Tests: Callable(params) -> {ok, code}; default RunState.begin_run.
var start_hook: Callable
## start_hook is only honoured when a test sets this; the game path always uses RunState.begin_run.
var test_mode := false
var _starting := false
## True while the last-mission check (reconcile) and the unlock refresh are in flight: no stake until done.
var _syncing := false
var begin_error := ""
var day_override := ""

## Tier shown in the detail plate (UI-03 screen 40).
var selected := ""

var _shell: Dictionary
var _modal_layer: Control
var _balance: Label
var _table_host: VBoxContainer
var _detail: PanelContainer


func _ready() -> void:
	_build()
	if use_account:
		state = derive_state()
	set_state(state)
	sync_server()


## reconcileEscrows BEFORE the balance and the buy button are trusted: close a stake the server settled while we
## were away, then refresh which tiers the win chain has opened. Offline / local dice: both are no-ops and the
## screen keeps the cache. Safe to call again (e.g. after a run).
func sync_server(force := false) -> void:
	if not (remote_on or force) or _syncing:
		return
	_syncing = true
	_refresh()
	MissionEscrowSync.reconcile_status(func(_st: String) -> void:
		MissionEscrowSync.fetch_unlocks(func(_ok: bool) -> void:
			_syncing = false
			if not is_inside_tree():
				return
			var ap := MissionEscrowSync.take_applied()
			if String(ap.get("state", "")) == "refunded":
				_banner("Old run, stake refunded", "That mission started before an update, so your %s Shards stake was returned." % UI3.fmt(int(ap.get("payout", 0))), &"ok")
			_refresh(), force), force)


## Derived from the account and the saved run. Guest/offline only BLOCK staking when the remote
## wallet flag is on; otherwise they show an info banner (same rule as Echo Box).
func derive_state() -> String:
	if RunState.has_saved_run():
		return "open_run"
	var st: int = account_status_hook.call() if account_status_hook.is_valid() else AccountService.status
	match st:
		AccountService.Status.GUEST, AccountService.Status.EXPIRED:
			return "guest"
		AccountService.Status.OFFLINE:
			return "offline"
	return "normal"


func select_tier(tier_id: String) -> void:
	if not offer(tier_id).is_empty():
		selected = tier_id   # picking only moves the ring and the plate: no log, no server call
		_update_rows()
		_draw_detail()


func _account_blocks() -> bool:
	return remote_on and (state == "offline" or state == "guest")


func _unhandled_key_input(ev: InputEvent) -> void:
	if UI3Meta.esc_back(ev, _shell, _on_back):
		if is_inside_tree():   # a handler above may have changed scene
			get_viewport().set_input_as_handled()


# ---------------------------------------------------------------- public API (also tests)

func today() -> String:
	return day_override if day_override != "" else MetaState.today_utc()


func offers() -> Array:
	return MissionBoard.offers(today(), MetaState)


func offer(tier_id: String) -> Dictionary:
	for o in offers():
		if String((o as Dictionary).tier) == tier_id:
			return o
	return {}


## Shard that may be staked. The starter grant cannot be staked (README M6), so it is taken off the
## balance (MetaState.starter_shard_locked).
func usable_shards() -> int:
	return MetaState.stake_usable_shards()


## Why this tier cannot be staked right now, or "" when it can.
## Order: account/open run, tier lock, balance.
func block_reason(tier_id: String, own_start := false) -> String:
	var o := offer(tier_id)
	if o.is_empty():
		return "Unknown mission"
	if state == "open_run":
		return "Finish or abandon your open run first"
	if state == "loading":
		return tr("Loading…")
	if _syncing:
		return tr("Checking your last mission…")
	if _starting and not own_start:
		return tr("Starting…")
	if _account_blocks():
		return "Needs a connection" if state == "offline" else "Sign in to stake Shards"
	if not bool(o.unlocked):
		return lock_text(o)
	if usable_shards() < int(o.stake):
		return "Need %d more Shards" % (int(o.stake) - usable_shards())
	return ""


func lock_text(o: Dictionary) -> String:
	match String(o.lock_reason):
		"disabled":
			return "Closed for now"
		"newcomer":
			# the full condition: the newcomer gate AND the win chain (a tier behind a win still needs it after the 5 runs)
			var need := int(_Econ.get_table("missions").get("newcomer_runs", 5))
			var base := "Play %d runs first (you have %d)" % [need, MetaState.gate_runs_with_battle()]
			var win := _chain_text(o)
			return base if win == "" else "%s, then %s" % [base, win.substr(0, 1).to_lower() + win.substr(1)]
		"chain":
			return _chain_text(o)
	return String(o.lock_reason)


## "Win N2 to unlock" / "Win N2 then N3 to unlock" / "Win N2 2 times to unlock (1/2)"; "" when the win chain is met.
func _chain_text(o: Dictionary) -> String:
	if MissionBoard.tier_unlocked(String(o.tier), MetaState):
		return ""
	var need := int(o.get("unlock_need", 1))
	var prev := String(o.get("unlock_prev", ""))
	if prev == "":
		return ""
	if not MissionBoard.tier_unlocked(prev, MetaState):
		# prev is locked too: list every tier that still has to be won, in order, same wording as the plain case
		var chain: Array[String] = [prev]
		var t := MissionBoard.prev_tier(prev)
		while t != "" and not MissionBoard.tier_unlocked(t, MetaState):
			chain.push_front(t)
			t = MissionBoard.prev_tier(t)
		if t != "":
			chain.push_front(t)
		return "Win %s to unlock" % " then ".join(chain)
	if need <= 1:
		return "Win %s to unlock" % prev
	return "Win %s %d times to unlock (%d/%d)" % [prev, need, int(o.get("unlock_wins", 0)), need]


## "Name: effect" lines for a mission's rules, text derived from the mods in mission_rules.json.
func rule_lines(o: Dictionary) -> Array:
	var out: Array = []
	var std: Dictionary = ContentDB.mission_table.get("standard", {})
	out.append("Standard: " + _mods_text(std))
	var table: Dictionary = ContentDB.mission_table.get("rules", {})
	for id in (o.rules as Array):
		out.append("%s: %s" % [RULE_NAMES.get(String(id), String(id)), _mods_text(table.get(String(id), {}))])
	return out


func _mods_text(m: Dictionary) -> String:
	var bits: Array[String] = []
	if m.has("enemy_dmg"):
		bits.append("enemy damage ×%s" % _num(float(m.enemy_dmg)))
	if m.has("elite_hp"):
		bits.append("elite HP ×%s" % _num(float(m.elite_hp)))
	if m.has("boss_hp"):
		bits.append("boss HP ×%s" % _num(float(m.boss_hp)))
	if m.has("normal_hp"):
		bits.append("Normal enemy HP ×%s" % _num(float(m.normal_hp)))
	if m.has("elite_dmg"):
		bits.append("Elite fight dice values ×%s (damage, shields, heals)" % _num(float(m.elite_dmg)))
	if m.has("extra_elite"):
		bits.append("+%d elites" % int(m.extra_elite))
	if m.has("spike_period_delta"):
		bits.append("big hits come %d turn sooner" % absi(int(m.spike_period_delta)))
	if m.has("clock_override"):
		var c: Dictionary = m.clock_override
		bits.append("boss clock from turn %d, +%d%% per turn, up to %d stacks" % [
			int(c.get("start", 0)), int(c.get("step_pct", 0)), int(c.get("max_stacks", 0))])
	return ", ".join(bits)


func _num(f: float) -> String:
	return ("%.2f" % f).rstrip("0").rstrip(".")


## Header of the run RunState.begin_run() reads (RunState.mission).
func mission_params(tier_id: String, mission_id: String = "") -> Dictionary:
	var o := offer(tier_id)
	var t: Dictionary = (_Econ.get_table("missions").get("tiers", {}) as Dictionary).get(tier_id, {})
	var keys: Array[String] = []
	var src: Array[String] = MainMenu.pending_team if not MainMenu.pending_team.is_empty() else MainMenu.DEFAULT_TEAM
	for k in src:
		if ContentDB.heroes.has(k) and not keys.has(k):
			keys.append(k)
	return {
		"team_keys": keys, "mode": String(o.mode), "ascension": int(o.ascension), "ranked": false,
		"kind": "mission", "newcomer": false, "depth_stage": MetaState.depth_stage(),
		"anchor": true,   # Liam 26/10: Anchors in Missions like a normal run (stage gate still applies)
		"mission": {
			"mission_id": mission_id if mission_id != "" else "%s|%s" % [today(), tier_id], "tier": int(tier_id.substr(1)),
			"rules": (o.rules as Array).duplicate(), "stake": int(o.stake),
			"m_base": float(t.get("m_base", 0)), "m_scale": float(t.get("m_scale", 1.0)), "m_eff": float(o.m),
		}}


## Take the stake (MetaState escrow), then start the run with the mission header. {ok, code}.
func start(tier_id: String) -> Dictionary:
	if _starting:
		return {"ok": false, "code": "busy"}
	_starting = true
	_refresh()   # block_reason() reports "Starting…" so every stake button is disabled
	var res := await _start_inner(tier_id)
	_starting = false
	if is_inside_tree():
		_refresh()
	return res


func _start_inner(tier_id: String) -> Dictionary:
	if use_account and state in ["normal", "offline", "guest"]:
		var d := derive_state()
		if d != state:
			set_state(d)
	if block_reason(tier_id, true) != "":
		return {"ok": false, "code": "blocked"}
	var o := offer(tier_id)
	# An old mirror of a server stake whose run is gone from this device: close it from the server's settlement
	# first. Still unknown (e.g. the last close failed offline): block, never mark it a loss.
	if not MetaState.mission_escrow.is_empty() and not MetaState._saved_run_exists():
		var w := MissionEscrowSync.prepare_new_stake()
		if not w.done:
			await w.finished
		if w.value != "":
			_banner(w.value, "Nothing was spent.", &"error", false, true)
			return {"ok": false, "code": "syncing"}
	var mid := MetaState.take_mission_stake(tier_id, int(o.stake))
	if mid == "":
		_banner("Could not take the stake", "Nothing was spent.", &"error", false, true)
		return {"ok": false, "code": "stake"}
	var params := mission_params(tier_id, mid)
	var r: Dictionary = (await start_hook.call(params)) if (test_mode and start_hook.is_valid()) else (await RunState.begin_run(params))
	if not r.get("ok", false):
		MetaState.refund_mission_stake()
		var code := String(r.get("code", "?"))
		if UpdateRequired.is_update_code(code):
			begin_error = "This version is out of date"
			if is_inside_tree():
				UpdateRequired.show(self, code)
			_banner(begin_error, "Download the new version to play Missions. Your stake was returned.", &"error")
			return r
		var msg := begin_error_text(code)
		begin_error = String(msg[0])
		_banner(String(msg[0]), String(msg[1]), &"error")
		return r
	begin_error = ""
	if not no_scene_change and is_inside_tree():
		get_tree().change_scene_to_file(RUN_MAP)
	return r


## [title, detail] for a failed mission start. Pure. The stake is always returned when the start fails.
static func begin_error_text(code: String) -> Array:
	match code:
		"tier_not_unlocked":
			return ["This tier is not open yet", "Win the tier before it first. Your stake was returned."]
		"mission_rules_mismatch":
			return ["This mission doesn't match the server", "Update the game and try again. Your stake was returned."]
		"tier_locked", "tier_disabled":
			return ["This tier is closed right now", "Try another tier. Your stake was returned."]
		"stake_mismatch", "tier_mismatch":
			return ["The mission table changed", "Reload the game to get the new table. Your stake was returned."]
	return ["Could not start the mission, try again.", "Your stake was returned. Code: %s" % code]


func _signed(n: int) -> String:
	return ("+" if n >= 0 else "-") + UI3.fmt(absi(n))


func set_state(s: String) -> void:
	state = s
	if _shell.is_empty():
		return
	UI3Meta.clear(_banner_host)
	match s:
		"offline":
			if remote_on:
				_banner("Can't reach the server", "Cards are readable. Stakes need a connection; nothing is spent.", &"warn", false, true)
			else:
				_banner("You're offline", "Missions run on this device for now; progress syncs when you reconnect.", &"info")
		"guest":
			if remote_on:
				_banner("Sign in to stake Shards", "Guests can read every card. Staking needs an account.", &"info", true)
			else:
				_banner("You're signed out", "Missions run on this device. Sign in to keep your progress across devices.", &"info")
		"open_run":
			_banner("You have a run open", "Only one run can be open. Finish or abandon it to take a mission.", &"warn")
	_refresh()


func open_confirm(tier_id: String) -> void:
	close_modal()
	var o := offer(tier_id)
	if o.is_empty():
		return
	if selected != tier_id:   # the detail plate behind the dialog always shows the dialog's tier
		select_tier(tier_id)
	var stake_txt := UI3.fmt(int(o.stake))
	var root := UI3.ModalRoot.new()
	root.theme = UI3Theme.get_theme()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.name = "Modal"
	root.add_to_group("ui3_modal")
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		UI3Tooltip.hide_all(tree)
	var scrim := ColorRect.new()
	scrim.name = "Scrim"
	scrim.color = UI3Theme.color("scrim")
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(scrim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	var dlg := PanelParts.panel(PanelParts.plate_box("xl", UI3Theme.space("32")), "StakeConfirm")
	dlg.custom_minimum_size.x = UI3Theme.size_of("defeat_panel_w")
	center.add_child(dlg)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UI3Theme.space("20"))
	dlg.add_child(col)
	var ttl := Ui5Text.label("Stake %s Shards?" % stake_txt, "text_banner", "text", true)
	ttl.name = "Title"
	col.add_child(ttl)
	var body := VBoxContainer.new()
	body.name = "Body"
	body.add_theme_constant_override("separation", UI3Theme.space("8"))
	col.add_child(body)
	var add := func(t: String, tok := "text_body", clr := "text_muted", disp := false) -> Label:
		var l := Ui5Text.label(t, tok, clr, disp)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_child(l)
		return l
	add.call("%s · %s, Ascension %d" % [tier_id, String(o.mode).capitalize(), int(o.ascension)], "text_body", "text", true)
	for line in rule_lines(o):
		add.call(String(line))
	body.add_child(MissionParts.kv_row("Win: %s Shards back (×%s)" % [UI3.fmt(int(o.payout)), _num(float(o.m))], "", "WinRow"))
	body.add_child(MissionParts.kv_row("Net if you win: %s Shards" % _signed(int(o.net)), "", "NetRow"))
	body.add_child(MissionParts.lose_box("", "Lose or abandon: you lose all %s Shards, no refund" % stake_txt))
	add.call("Estimated win chance (simulated): about %s%%" % _num(float(o.est_win_pct)))
	add.call("No Continue and no Aid in a mission run.")
	var no := PanelParts.button("Not now", &"secondary", &"M")
	no.name = "NotNowButton"
	var cap := Ui5Keycap.make("Space")
	var yes := PanelParts.button("Stake %s and play" % stake_txt, &"primary", &"M")
	yes.name = "StakeButton"
	yes.disabled = block_reason(tier_id) != ""
	no.pressed.connect(close_modal)
	yes.pressed.connect(func() -> void:
		close_modal()
		start(tier_id))
	col.add_child(Ui5ModalFooter.make(yes, no))
	root.actions = [no, yes]
	root.focus_index = 0   # focus starts on the safe choice
	root.cancelled.connect(close_modal)
	_modal_layer.add_child(root)
	no.add_child(cap)   # Space presses the focused Not now
	var cw := int(cap.get_combined_minimum_size().x) + UI3Theme.space("8")
	cap.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	cap.offset_left = -cw
	cap.offset_right = -UI3Theme.space("8")
	for st in ["normal", "hover", "pressed", "focus"]:   # room for the cap inside the button, text stays centred in the rest
		var sb := no.get_theme_stylebox(st) as StyleBoxFlat
		if sb != null:
			var d := sb.duplicate() as StyleBoxFlat
			d.content_margin_right = d.content_margin_right + cw
			no.add_theme_stylebox_override(st, d)


func close_modal() -> void:
	if _modal_layer != null:
		UI3Meta.clear(_modal_layer)


# ---------------------------------------------------------------- build

var _banner_host: VBoxContainer
var _balance_icon: TextureRect
var _rows := {}


func _build() -> void:
	_shell = UI3Meta.build(self, "Missions", "Stake Shards on a hard run", _on_back)
	(_shell["back"] as Control).name = "BackButton"
	(_shell["sub"] as Control).name = "SubLine"
	(_shell["panel"] as Control).name = "PlateHost"   # t_ui_laws L0
	_modal_layer = _shell["modal_layer"]
	var col: VBoxContainer = _shell["col"]
	var body := VBoxContainer.new()
	body.name = "Body"
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", UI3Theme.space("16"))
	col.add_child(body)
	var note := PanelParts.panel(UI3Theme.flat(UI3Theme.color("plate"), UI3Theme.radius("l"), UI3Theme.stroke("rim"),
		UI3Theme.color("plate_rim"), Vector4(UI3Theme.space("16"), UI3Theme.space("12"), UI3Theme.space("16"), UI3Theme.space("12")),
		PanelParts.lip(UI3Theme.color("plate_ink"))), "Explainer")
	var nrow := HBoxContainer.new()
	nrow.add_theme_constant_override("separation", UI3Theme.space("24"))
	note.add_child(nrow)
	var exv := VBoxContainer.new()
	exv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nrow.add_child(exv)
	var ex := Ui5Text.label("Win a hard run to get your stake back with a bonus. Lose it and the stake is gone.", "text_body", "text")
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	exv.add_child(ex)
	var gl := Ui5Text.label("A = Ascension (extra difficulty). Stone = Land currency. Starter Shards = the free Shards you began with; they can't be staked. Win chances are simulated with a bot.", "text_body", "text_muted")
	gl.name = "Glossary"
	gl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	exv.add_child(gl)
	var bal := HBoxContainer.new()
	bal.name = "Balance"
	bal.add_theme_constant_override("separation", UI3Theme.space("8"))
	bal.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_balance_icon = PanelParts.icon_rect(UI3.currency_icon("cur_shard", UI3Theme.size_of("icon_m")), UI3Theme.size_of("icon_m"))
	bal.add_child(_balance_icon)
	_balance = Ui5Text.label("", "text_title", "text", true)
	_balance.name = "Value"
	bal.add_child(_balance)
	nrow.add_child(bal)
	body.add_child(note)
	_banner_host = VBoxContainer.new()
	_banner_host.name = "BannerHost"
	body.add_child(_banner_host)
	var main := HBoxContainer.new()
	main.name = "Main"
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_theme_constant_override("separation", UI3Theme.space("24"))
	body.add_child(main)
	_table_host = VBoxContainer.new()
	_table_host.name = "Table"
	_table_host.add_theme_constant_override("separation", UI3Theme.space("8"))
	var sc := UI3Meta.scroll(_table_host)
	sc.name = "TableScroll"
	main.add_child(sc)
	var dp := Ui5DetailPlate.new()
	dp.setup("mission_detail_w", "Pick a tier", "Select a tier to see its stake, payout and rules.", "Pick a tier")
	dp.scroll.get_v_scroll_bar().custom_minimum_size.x = UI3Theme.SCROLL_W   # visible overflow (t_ui_laws L2)
	_detail = dp
	main.add_child(dp)


func _on_back() -> void:
	if is_inside_tree() and not no_scene_change:
		LandNav.back_to_land()


func _banner(msg: String, detail: String, tone: StringName, with_sign_in := false, with_retry := false) -> void:
	UI3Meta.clear(_banner_host)
	_banner_host.add_child(MissionParts.banner(tone, msg, detail, _sign_in if with_sign_in else Callable(), _retry if with_retry else Callable()))


## A signed-out or expired account: with the remote wallet on, a guest has no Shards to show and cannot stake.
func _retry() -> void:
	set_state(derive_state() if use_account else "normal")


func is_guest_view() -> bool:
	return remote_on and state == "guest"


var sign_in_calls := 0


func _sign_in() -> void:
	if test_mode:
		sign_in_calls += 1
		return
	AccountService.sign_in()


# ---------------------------------------------------------------- refresh

func _refresh() -> void:
	if _shell.is_empty():
		return
	var usable := usable_shards()
	_balance_icon.visible = not is_guest_view()
	if is_guest_view():   # a guest has no wallet: no numbers (the cached ones belong to nobody)
		_balance.text = "Sign in to see your Shards"
	else:
		_balance.text = "Stakeable %s · Starter %s" % [UI3.fmt(usable), UI3.fmt(maxi(MetaState.shard_pool - usable, 0))]
	UI3Meta.clear(_table_host)
	_rows.clear()
	_table_host.add_child(MissionParts.head_row())
	if state == "loading" or _syncing:
		for i in maxi(offers().size(), 1):
			var sk := UI3.skeleton_row(UI3Theme.size_of("mission_row_h"))
			sk.name = "Skeleton"
			_table_host.add_child(sk)
		_draw_detail()
		return
	for o in offers():
		var row := _row(o)
		_rows[String((o as Dictionary).tier)] = row
		_table_host.add_child(row)
	_update_rows()
	_draw_detail()


func _rule_names(o: Dictionary) -> String:
	var names: Array[String] = []
	for r in (o.rules as Array):
		names.append(String(RULE_NAMES.get(String(r), String(r))))
	return ", ".join(names) if not names.is_empty() else "Standard only"


func _row_locked(o: Dictionary) -> bool:
	return not bool(o.unlocked) and not is_guest_view()   # a guest sees rule text, no lock lines


func _row(o: Dictionary) -> Control:
	var id := String(o.tier)
	var locked := _row_locked(o)
	var r := MissionTierRow.new()
	r.setup_tier(id, [id, "%s · A%d" % [String(o.mode).capitalize(), int(o.ascension)], UI3.fmt(int(o.stake)),
		"%s (×%s)" % [UI3.fmt(int(o.payout)), _num(float(o.m))], "+%d" % int(o.stone),
		("Locked: " + lock_text(o)) if locked else _rule_names(o)], locked)
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.pressed.connect(select_tier.bind(id))
	return r


## Ring + dim follow `selected` and the lock state; nothing is selected when the screen opens.
func _update_rows() -> void:
	for id in _rows:
		var r := _rows[id] as MissionTierRow
		if is_instance_valid(r):
			r.set_tier_state(String(id) == selected, r.locked)


func _draw_detail() -> void:
	var dp := _detail as Ui5DetailPlate
	var big := UI3Theme.size_of("text_screen_title")
	if state == "loading" or _syncing:
		var t := tr("Loading…") if state == "loading" else tr("Checking your last mission…")
		dp.show_item(t)
		dp.title.add_theme_font_size_override("font_size", UI3Theme.size_of("text_title"))
		for i in 2:
			dp.body.add_child(UI3.skeleton_row(UI3Theme.size_of("skeleton_h")))
		dp.set_primary(t, t).name = "StakeButton"
		return
	dp.title.add_theme_font_size_override("font_size", big)
	var o := offer(selected)
	if selected == "" or o.is_empty():
		dp.show_empty()
		if dp.primary != null:
			dp.primary.name = "StakeButton"
		return
	var id := selected
	dp.show_item("%s · %s, A%d" % [id, String(o.mode).capitalize(), int(o.ascension)])
	var tier_locked := not bool(o.unlocked) and not _account_blocks()
	if tier_locked:
		dp.body.add_child(MissionParts.locked_tag())
	for line in rule_lines(o):
		dp.add_line(String(line)).name = "RuleLine"
	if not tier_locked:   # a tier you cannot play shows what opens it, not stake money, the lose box, a warning or an estimate
		_draw_detail_money(dp, o)
	var why := block_reason(id)
	var stake_text := "Stake %s and play" % UI3.fmt(int(o.stake))
	var b: Button
	if is_guest_view():
		b = dp.set_primary("Sign in to stake Shards")   # looks active and works: leaving "guest" is its one job
		b.pressed.connect(_sign_in)
	else:
		b = dp.set_primary(stake_text, why)
		b.pressed.connect(open_confirm.bind(id))
	b.name = "StakeButton"


## Stake -> Win back -> Net, Stone, the lose box, the warning and the estimate line (open tiers only).
func _draw_detail_money(dp: Ui5DetailPlate, o: Dictionary) -> void:
	var rows := [["Stake", "%s Shards" % UI3.fmt(int(o.stake)), "StakeRow"],
			["Win back", "%s Shards (×%s)" % [UI3.fmt(int(o.payout)), _num(float(o.m))], "WinBackRow"],
			["Net if you win", "%s Shards" % _signed(int(o.net)), "NetRow"],
			["Stone if you win", "+%d" % int(o.stone), "StoneRow"]]
	for r in rows:
		dp.body.add_child(MissionParts.kv_row(String(r[0]), String(r[1]), String(r[2])))
	dp.body.add_child(MissionParts.lose_box("Lose or abandon", "You lose %s Shards. No refund, no Stone." % UI3.fmt(int(o.stake))))
	var wt := warning_text(effective_warning(o))
	if wt != "":
		dp.body.add_child(MissionParts.warning(wt))
	var est := dp.add_line("Estimated win chance (simulated): about %s%%. On average you get back about %d%% of your stake. Real players may do better or worse." % [
		_num(float(o.est_win_pct)), roundi(float(o.est_return_pct))], "text_muted")
	est.name = "ChanceLine"
	dp.add_line("No Continue and no Aid.", "text_muted")


## The tier's own warning kind (N3+: MissionBoard.warning_kind), else "most_lose" for any tier whose estimated win
## chance is under 50%. In missions.json every tier is: N1 is 12.3% (about 7 in 8 players lose it) and the average
## return is ~65% on all six, so N1/N2 must not look safer than N3.
static func effective_warning(o: Dictionary) -> String:
	var k := String(o.get("warning", ""))
	if k == "" and float(o.get("est_win_pct", 100.0)) < 50.0:
		return "most_lose"
	return k


## Fixed warning per tier kind (MissionBoard.warning_kind). "" = none.
static func warning_text(kind: String) -> String:
	match kind:
		"most_lose":
			return "Most players lose this tier."
		"challenge":
			return "Challenge tier: on average you get back less than your stake."
		"title":
			return "Title tier: almost nobody clears it, and on average you get back far less than your stake."
	return ""
