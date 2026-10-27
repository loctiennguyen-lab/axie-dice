class_name MissionsScreen
extends Control
## M6 Nhiem vu / Missions (key 3). Spec: design/handoffs/ui-02-round3 README section 2 M6, frames M6a-M6l.
## Board = MissionBoard.offers() on MetaState: tiers, stakes, multipliers, unlock gates and lock reasons
## are all read from economy/missions.json + rules/mission_rules.json. Nothing numeric lives here.
## Card follows the art-director decluttered layout: tier + mode, Stake / Pay / Stone tiles, rules line,
## button. Full rule rows, the m multiplier and the stake warning live in the confirm modal (M6c).
## Detail card (beta §5): rules in words, Stake -> Win back -> Net, "Estimate (bot)" win chance and average
## return, a fixed warning from N3 up, and a disabled Stake button that says why. The win chance is a BOT
## estimate (missions.json est_win_pct), labelled as such.
##
## Paying the stake: MetaState.take_mission_stake() escrows it and returns the mission id; RunState.end_run
## settles it, a failed begin_run refunds it, abandon is settled in SettingsView.
## Drawn: M6a/b board (locked tiers per lock_reason), M6c confirm, M6g newcomer, M6h not enough Shard,
## M6i open run, M6j offline, M6k guest, M6l tall (cards flow into a scroll, extra height to the grid).
## Not drawn: M6d/e/f results (belong to the Result screen), "table updated" line (no data).

const _Econ := preload("res://scripts/meta/economy_db.gd")
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
var _banner_host: VBoxContainer
var _modal_layer: Control
var _balance: Label
var _table_host: VBoxContainer
var _detail: PanelContainer


func _ready() -> void:
	_build()
	selected = _default_tier()
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
				_banner("Old run, stake refunded", "That mission started before an update, so your %s Shard stake was returned." % UI3.fmt(int(ap.get("payout", 0))), false)
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


## First tier you can stake, else the first on the board.
func _default_tier() -> String:
	var all := offers()
	for o in all:
		if bool((o as Dictionary).unlocked):
			return String((o as Dictionary).tier)
	return String((all[0] as Dictionary).tier) if not all.is_empty() else ""


func select_tier(tier_id: String) -> void:
	if not offer(tier_id).is_empty():
		selected = tier_id
		_refresh()


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
		return "Loading..."
	if _syncing:
		return "Checking your last mission..."
	if _starting and not own_start:
		return tr("Starting…")
	if _account_blocks():
		return "Needs a connection" if state == "offline" else "Sign in to stake Shard"
	if not bool(o.unlocked):
		return lock_text(o)
	if usable_shards() < int(o.stake):
		return "Need %d more Shard" % (int(o.stake) - usable_shards())
	return ""


func lock_text(o: Dictionary) -> String:
	match String(o.lock_reason):
		"disabled":
			return "Closed for now"
		"newcomer":
			var need := int(_Econ.get_table("missions").get("newcomer_runs", 5))
			return "Play %d runs first (you have %d)" % [need, MetaState.gate_runs_with_battle()]
		"chain":
			var need := int(o.get("unlock_need", 1))
			var prev := String(o.get("unlock_prev", ""))
			if prev != "" and not MissionBoard.tier_unlocked(prev, MetaState):
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
	return String(o.lock_reason)


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
			_banner(w.value, "Nothing was spent.", true)
			return {"ok": false, "code": "syncing"}
	var mid := MetaState.take_mission_stake(tier_id, int(o.stake))
	if mid == "":
		_banner("Could not take the stake", "Nothing was spent.", true)
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
			_banner(begin_error, "Download the new version to play Missions. Your stake was returned.", false)
			return r
		var msg := begin_error_text(code)
		begin_error = String(msg[0])
		_banner(String(msg[0]), String(msg[1]), false)
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
				_banner("Can't reach the dice server", "Cards are readable. Stakes need a connection; nothing is spent.", true)
			else:
				_banner("You're offline", "Missions run on this device for now; progress syncs when you reconnect.", false)
		"guest":
			if remote_on:
				_banner("Sign in to stake Shard", "Guests can read every card. Staking needs an account.", false)
			else:
				_banner("You're signed out", "Missions run on this device. Sign in to keep your progress across devices.", false)
		"open_run":
			_banner("You have a run open", "Only one run can be open. Finish or abandon it to take a mission.", false)
	_refresh()


func open_confirm(tier_id: String) -> void:
	close_modal()
	var o := offer(tier_id)
	if o.is_empty():
		return
	if selected != tier_id:   # the detail plate behind the dialog always shows the dialog's tier
		select_tier(tier_id)
	var lines: Array[String] = ["%s · %s, Ascension %d" % [tier_id, String(o.mode).capitalize(), int(o.ascension)], ""]
	for line in rule_lines(o):
		lines.append(String(line))
	lines.append("")
	lines.append("Win: %s Shard back (×%s), net %s. Lose or abandon: you lose all %s, no refund." % [
		UI3.fmt(int(o.payout)), _num(float(o.m)), _signed(int(o.net)), UI3.fmt(int(o.stake))])
	lines.append("Estimate (bot): about %s%% to win." % _num(float(o.est_win_pct)))
	lines.append("No Continue and no Aid in a mission run.")
	var no := UI3.button("Not now", &"secondary", &"M")
	no.name = "NotNow"
	var yes := UI3.button("Stake %d and play" % int(o.stake), &"primary", &"M")
	yes.name = "ConfirmStake"
	yes.disabled = block_reason(tier_id) != ""
	no.pressed.connect(close_modal)
	yes.pressed.connect(func() -> void:
		close_modal()
		start(tier_id))
	var m := UI3.modal("Stake %d Shard?" % int(o.stake), "\n".join(lines), [no, yes], 0)   # focus starts on the safe choice
	m.cancelled.connect(close_modal)
	_modal_layer.add_child(m)


func close_modal() -> void:
	if _modal_layer != null:
		UI3Meta.clear(_modal_layer)


# ---------------------------------------------------------------- build

const COLS := [["TIER", 120, false], ["MODE", 140, false], ["STAKE", 160, true], ["WIN BACK", 160, true],
	["STONE", 120, true], ["RULES", 0, false]]
const ROW_H := 96
const DETAIL_W := 440


func _build() -> void:
	_shell = UI3Meta.build(self, "Missions", "Stake Shards on a hard run", _on_back)
	_banner_host = _shell["banner_host"]
	(_shell["panel"] as Control).name = "PlateHost"   # t_ui_laws L0
	_modal_layer = _shell["modal_layer"]
	var col: VBoxContainer = _shell["col"]
	var note := UI3.plate(&"plate")
	note.name = "Explainer"
	var nrow := HBoxContainer.new()
	nrow.add_theme_constant_override("separation", UI3Theme.space("24"))
	note.add_child(nrow)
	var exv := VBoxContainer.new()
	exv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	exv.add_theme_constant_override("separation", UI3Theme.space("8"))
	var ex := UI3.label("Win a hard run to get your stake back with a bonus. Lose it and the stake is gone.", "LabelMuted")
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	exv.add_child(ex)
	var gl := UI3.label("A = Ascension (extra difficulty). Estimate (bot) = win chance measured with a bot. Stone = Land currency. Starter Shard can't be staked.", "LabelMuted")
	gl.name = "Glossary"
	gl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	exv.add_child(gl)
	nrow.add_child(exv)
	_balance = UI3.label("", "LabelTitle")
	_balance.name = "Balance"
	nrow.add_child(_balance)
	col.add_child(note)
	var body := HBoxContainer.new()
	body.name = "Body"
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", UI3Meta.GAP)
	col.add_child(body)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", UI3Theme.space("16"))
	body.add_child(left)
	_table_host = VBoxContainer.new()
	_table_host.name = "TableHost"
	_table_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_table_host.add_theme_constant_override("separation", UI3Theme.space("8"))
	left.add_child(_table_host)
	_detail = UI3.plate(&"plate")
	_detail.name = "Detail"
	_detail.custom_minimum_size = Vector2(DETAIL_W, 0)
	body.add_child(_detail)


func _on_back() -> void:
	if is_inside_tree() and not no_scene_change:
		LandNav.back_to_land()


func _banner(msg: String, detail: String, with_retry: bool) -> void:
	var btns: Array = []
	if with_retry:
		btns.append({"name": "TryAgain", "text": "Try again", "primary": true, "cb": func() -> void: set_state("normal")})
	UI3Meta.banner(_banner_host, msg, detail, btns)


# ---------------------------------------------------------------- refresh

func _cell(text: String, w: int, variation := "", right := false) -> Label:
	var l := UI3.label(text, variation)
	if w > 0:
		l.custom_minimum_size = Vector2(w, 0)
	else:
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if right else HORIZONTAL_ALIGNMENT_LEFT
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _refresh() -> void:
	if _shell.is_empty():
		return
	var usable := usable_shards()
	_balance.text = "Stakeable %s · Starter %s (can't be staked)" % [
		UI3.fmt(usable), UI3.fmt(maxi(MetaState.shard_pool - usable, 0))]
	UI3Meta.clear(_table_host)
	if state == "loading":
		for i in 4:
			_table_host.add_child(UI3.skeleton_row(ROW_H))
		UI3Meta.clear(_detail)
		return
	if offer(selected).is_empty():
		selected = _default_tier()
	var head := HBoxContainer.new()
	head.name = "Head"
	head.add_theme_constant_override("separation", UI3Theme.space("16"))
	var hpad := MarginContainer.new()
	hpad.add_theme_constant_override("margin_left", 24)
	hpad.add_theme_constant_override("margin_right", 24)
	hpad.add_child(head)
	for c in COLS:
		head.add_child(_cell(String(c[0]), int(c[1]), "LabelMuted", bool(c[2])))
	_table_host.add_child(hpad)
	var rows := VBoxContainer.new()
	rows.name = "Grid"
	rows.add_theme_constant_override("separation", UI3Theme.space("8"))
	for o in offers():
		rows.add_child(_row(o))
	var sc := UI3Meta.scroll(rows)
	sc.name = "Scroll"
	_table_host.add_child(sc)
	_draw_detail()


func _rule_names(o: Dictionary) -> String:
	var names: Array[String] = []
	for r in (o.rules as Array):
		names.append(String(RULE_NAMES.get(String(r), String(r))))
	return ", ".join(names) if not names.is_empty() else "Standard only"


func _row(o: Dictionary) -> Control:
	var id := String(o.tier)
	var locked := not bool(o.unlocked)
	var b := UI3.button("", &"secondary", &"M")
	b.name = "Card_" + id
	b.set_meta("selected", id == selected)   # not a toggle: the pressed style would fill the row cream
	if id == selected:
		# selected = 4 px cream outline (selected-card style), drawn as an overlay: no lift, no fill change
		var ring := Panel.new()
		ring.name = "SelectedRing"
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ring.add_theme_stylebox_override("panel", UI3Theme.flat(Color.TRANSPARENT, UI3Theme.radius("m"), 4,
			UI3Theme.color("selected_outline")))
		b.add_child(ring)
	b.custom_minimum_size = Vector2(0, ROW_H)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UI3Theme.space("16"))
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 24
	h.offset_right = -24
	b.add_child(h)
	h.add_child(_cell(id, 120, "LabelScreenTitle"))
	h.add_child(_cell("%s · A%d" % [String(o.mode).capitalize(), int(o.ascension)], 140))
	h.add_child(_cell(UI3.fmt(int(o.stake)), 160, "LabelTitle", true))
	h.add_child(_cell("%s (×%s)" % [UI3.fmt(int(o.payout)), _num(float(o.m))], 160, "", true))
	h.add_child(_cell("+%d" % int(o.stone), 120, "", true))
	if locked:
		var lk := _cell("Locked: " + lock_text(o), 0)
		lk.name = "LockNote"
		h.add_child(lk)
	else:
		var rl := _cell(_rule_names(o), 0)
		rl.name = "Rules"
		h.add_child(rl)
	b.pressed.connect(select_tier.bind(id))
	return b


func _tinted(kind: String, title: String, text: String) -> Control:
	var win := kind == "win"
	var p := PanelContainer.new()
	p.name = "Win" if win else "Lose"
	p.theme = UI3Theme.get_theme()
	p.add_theme_stylebox_override("panel", UI3Theme.flat(
		UI3Theme.color("success_bg" if win else "danger_bg"), UI3Theme.radius("m"), 0, Color.TRANSPARENT,
		Vector4(16, 12, 16, 12)))
	var v := VBoxContainer.new()
	p.add_child(v)
	var t := UI3.label(title, "LabelTitle")
	t.add_theme_color_override("font_color", UI3Theme.color("success_text" if win else "danger_text"))
	v.add_child(t)
	var d := UI3.label(text)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(d)
	return p


func _draw_detail() -> void:
	UI3Meta.clear(_detail)
	var o := offer(selected)
	if o.is_empty():
		return
	var id := selected
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", UI3Theme.space("16"))
	_detail.add_child(outer)
	var v := VBoxContainer.new()
	v.name = "DetailBody"
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", UI3Theme.space("16"))
	var pad := MarginContainer.new()   # keeps text off the scrollbar
	pad.add_theme_constant_override("margin_right", 16)
	pad.add_child(v)
	var sc := UI3Meta.scroll(pad)
	sc.name = "DetailScroll"
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(sc)
	var t := UI3.label("%s · %s, A%d" % [id, String(o.mode).capitalize(), int(o.ascension)], "LabelScreenTitle")
	t.name = "DetailTitle"
	v.add_child(t)
	# 1. rules in words (same names as the chips in the run)
	var rules := VBoxContainer.new()
	rules.name = "RuleLines"
	rules.add_theme_constant_override("separation", UI3Theme.space("8"))
	for line in rule_lines(o):
		var rl := UI3.label(String(line))
		rl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rules.add_child(rl)
	v.add_child(rules)
	# 2. Stake -> Win back -> Net
	var money := VBoxContainer.new()
	money.name = "Money"
	money.add_theme_constant_override("separation", UI3Theme.space("8"))
	for row in [["Stake", "%s Shards" % UI3.fmt(int(o.stake)), "StakeValue"],
			["Win back", "%s Shards (×%s)" % [UI3.fmt(int(o.payout)), _num(float(o.m))], "PayValue"],
			["Net if you win", "%s Shards" % _signed(int(o.net)), "NetValue"],
			["Stone if you win", "+%d" % int(o.stone), "StoneValue"]]:
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", UI3Theme.space("16"))
		var kl := UI3.label(String(row[0]), "LabelMuted")
		kl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(kl)
		var vl := UI3.label(String(row[1]), "LabelTitle")
		vl.name = String(row[2])
		hb.add_child(vl)
		money.add_child(hb)
	v.add_child(money)
	v.add_child(_tinted("lose", "Lose or abandon", "You lose %s Shards. No refund, no Stone." % UI3.fmt(int(o.stake))))
	var wt := warning_text(String(o.warning))
	if wt != "":
		var wl := UI3.label(wt)
		wl.name = "Warning"
		wl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		wl.add_theme_color_override("font_color", UI3Theme.color("anchor_price"))
		v.add_child(wl)
	# 3. estimate (bot) and the fixed warning
	var est := UI3.label("Estimate (bot): about %s%% win, you get back about %d%% of the stake on average. Real players may do better or worse." % [
		_num(float(o.est_win_pct)), roundi(float(o.est_return_pct))], "LabelMuted")
	est.name = "Estimate"
	est.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(est)
	var nc := UI3.label("No Continue and no Aid.", "LabelMuted")
	v.add_child(nc)
	var why := block_reason(id)
	var b := UI3.button("Stake %d and play" % int(o.stake), &"primary", &"M")
	b.name = "Stake"
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if why != "":
		UI3.set_disabled_reason(b, why)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size.y = 72
	b.pressed.connect(open_confirm.bind(id))
	outer.add_child(b)


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
