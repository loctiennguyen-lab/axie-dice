class_name MissionsScreen
extends Control
## M6 Nhiem vu / Missions (key 3). Spec: design/handoffs/ui-02-round3 README section 2 M6, frames M6a-M6l.
## Board = MissionBoard.offers() on MetaState: tiers, stakes, multipliers, unlock gates and lock reasons
## are all read from economy/missions.json + rules/mission_rules.json. Nothing numeric lives here.
## Card follows the art-director decluttered layout: tier + mode, Stake / Pay / Stone tiles, rules line,
## button. Full rule rows, the m multiplier and the stake warning live in the confirm modal (M6c).
## No win-rate or expected-return line: no data source exists yet.
##
## Paying the stake: MetaState.take_mission_stake() escrows it and returns the mission id; RunState.end_run
## settles it, a failed begin_run refunds it, abandon is settled in SettingsView.
## Drawn: M6a/b board (locked tiers per lock_reason), M6c confirm, M6g newcomer, M6h not enough Shard,
## M6i open run, M6j offline, M6k guest, M6l tall (cards flow into a scroll, extra height to the grid).
## Not drawn: M6d/e/f results (belong to the Result screen), "table updated" line (no data).

const _Econ := preload("res://scripts/meta/economy_db.gd")
const RUN_MAP := "res://scenes/run_map/RunMap.tscn"
const RULE_NAMES := {"M1": "Harsh clock", "M2": "Spike stack", "M3": "Hunted", "M4": "Heavy hits", "M5": "Thick boss"}

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
var begin_error := ""
var day_override := ""

var _panel: PanelContainer
var _col: VBoxContainer
var _banner_host: VBoxContainer
var _strip_host: HBoxContainer
var _grid_host: VBoxContainer
var _modal_layer: Control


func _ready() -> void:
	_build()
	if remote_on:
		MissionEscrowSync.reconcile(func(applied: bool) -> void:
			if applied and is_inside_tree():
				_refresh())
	if use_account:
		state = derive_state()
	set_state(state)


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


func _account_blocks() -> bool:
	return remote_on and (state == "offline" or state == "guest")


func _unhandled_key_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_ESCAPE:
		if _modal_layer.get_child_count() > 0:
			close_modal()
		else:
			_on_back()
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
	if _starting and not own_start:
		return "Starting..."
	if _account_blocks():
		return "Needs a connection" if state == "offline" else "Sign in to stake Shard"
	if not bool(o.unlocked):
		return lock_text(o)
	if usable_shards() < int(o.stake):
		return "Need %d more Shard" % (int(o.stake) - usable_shards())
	return ""


func lock_text(o: Dictionary) -> String:
	var t: Dictionary = (_Econ.get_table("missions").get("tiers", {}) as Dictionary).get(String(o.tier), {})
	match String(o.lock_reason):
		"disabled":
			return "Not in this build"
		"newcomer":
			var need := int(_Econ.get_table("missions").get("newcomer_runs", 5))
			return "Play %d runs first (you have %d)" % [need, MetaState.runs_with_battle]
		"house":
			return "Needs Mission House level %d" % int(t.get("house_level", 1))
		"full_a9":
			return "Win a Full run on Ascension %d first" % int(t.get("ascension", 9))
		"asc_win":
			return "Win a run on Ascension %d first" % int(t.get("unlock_win_asc", 0))
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
		bits.append("enemy damage x%s" % _num(float(m.enemy_dmg)))
	if m.has("elite_hp"):
		bits.append("elite HP x%s" % _num(float(m.elite_hp)))
	if m.has("boss_hp"):
		bits.append("boss HP x%s" % _num(float(m.boss_hp)))
	if m.has("normal_hp"):
		bits.append("normal enemy HP x%s" % _num(float(m.normal_hp)))
	if m.has("elite_dmg"):
		bits.append("elite damage x%s" % _num(float(m.elite_dmg)))
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
		"kind": "mission", "newcomer": false,
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
	_refresh()   # block_reason() reports "Starting..." so every stake button is disabled
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
	var mid := MetaState.take_mission_stake(tier_id, int(o.stake))
	if mid == "":
		_banner("Could not take the stake", "Nothing was spent.", true)
		return {"ok": false, "code": "stake"}
	var params := mission_params(tier_id, mid)
	var r: Dictionary = (await start_hook.call(params)) if (test_mode and start_hook.is_valid()) else (await RunState.begin_run(params))
	if not r.get("ok", false):
		MetaState.refund_mission_stake()
		begin_error = "Could not start the mission, try again."
		_banner(begin_error, "Code: %s" % String(r.get("code", "?")), false)
		return r
	begin_error = ""
	if not no_scene_change and is_inside_tree():
		get_tree().change_scene_to_file(RUN_MAP)
	return r


func set_state(s: String) -> void:
	state = s
	if _panel == null:
		return
	for c in _banner_host.get_children():
		c.queue_free()
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
				_banner("Playing as a guest", "Missions run on this device. Sign in to keep your progress across devices.", false)
		"open_run":
			_banner("You have a run open", "Only one run can be open. Finish or abandon it to take a mission.", false)
	_refresh()


func open_confirm(tier_id: String) -> void:
	close_modal()
	var o := offer(tier_id)
	if o.is_empty():
		return
	var m := _modal("Stake %d Shard?" % int(o.stake), 600)
	var v: VBoxContainer = m.find_child("V", true, false)
	v.add_child(_label("%s - %s, Ascension %d" % [tier_id, String(o.mode).capitalize(), int(o.ascension)], 18, DangoTheme.INK_2))
	for line in rule_lines(o):
		v.add_child(_label(String(line), 16))
	var pay := _label("If you win you get %d Shard back (x%s). If you fail, the stake is lost." % [
		int(o.payout), _num(float(o.m))], 16)
	pay.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(pay)
	v.add_child(_label("No Aid in a mission run.", 14, DangoTheme.INK_2))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var no := _button("Not now", 260, 48)
	no.name = "NotNow"
	no.pressed.connect(close_modal)
	var yes := _button("Stake %d and play" % int(o.stake), 260, 48, true)
	yes.name = "ConfirmStake"
	yes.disabled = block_reason(tier_id) != ""
	yes.pressed.connect(func() -> void:
		close_modal()
		start(tier_id))
	row.add_child(no)
	row.add_child(yes)
	v.add_child(row)
	no.grab_focus()   # focus starts on the safe choice


func close_modal() -> void:
	for c in _modal_layer.get_children():
		c.queue_free()


# ---------------------------------------------------------------- build

func _build() -> void:
	DangoScreen.build(self, MockupAssets.tex("assets/bg/rocky.jpg"), DangoTheme.Scrim.DEFAULT, false)
	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.anchor_right = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = 120
	_panel.offset_right = -120
	_panel.offset_top = 116
	_panel.offset_bottom = -84
	var sb := StyleBoxFlat.new()
	sb.bg_color = DangoTheme.CREAM
	sb.set_corner_radius_all(28)
	sb.set_border_width_all(4)
	sb.border_color = DangoTheme.LINE
	_panel.add_theme_stylebox_override("panel", sb)
	_panel.clip_contents = true
	add_child(_panel)
	_col = VBoxContainer.new()
	_col.name = "Col"
	_col.add_theme_constant_override("separation", 0)
	_panel.add_child(_col)
	_col.add_child(_build_header())
	_banner_host = VBoxContainer.new()
	_col.add_child(_banner_host)
	var strip := PanelContainer.new()
	strip.custom_minimum_size = Vector2(0, 48)
	var ssb := StyleBoxFlat.new()
	ssb.bg_color = DangoTheme.CREAM_200
	ssb.content_margin_left = 24
	ssb.content_margin_right = 24
	strip.add_theme_stylebox_override("panel", ssb)
	_strip_host = HBoxContainer.new()
	_strip_host.name = "HouseStrip"
	_strip_host.add_theme_constant_override("separation", 20)
	strip.add_child(_strip_host)
	_col.add_child(strip)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_col.add_child(scroll)
	DangoTheme.style_scrollbars(scroll)
	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for s in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + s, 20)
	scroll.add_child(pad)
	_grid_host = VBoxContainer.new()
	_grid_host.name = "GridHost"
	_grid_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_child(_grid_host)
	_modal_layer = Control.new()
	_modal_layer.name = "Modals"
	_modal_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_modal_layer)


func _label(text: String, size: int, color: Color = DangoTheme.INK, display := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", maxi(size, 12))
	l.add_theme_color_override("font_color", color)
	if display:
		l.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	return l


func _button(text: String, w: float, h: float, primary := false) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(w, maxf(h, 44))
	b.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	b.add_theme_font_size_override("font_size", 18)
	DangoTheme.style_button(b, primary)
	return b


func _plate(min_w: float, border: Color = DangoTheme.LINE, fill: Color = DangoTheme.CREAM_RAISED) -> PanelContainer:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(min_w, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_corner_radius_all(16)
	sb.set_border_width_all(3)
	sb.border_color = border
	sb.set_content_margin_all(14)
	p.add_theme_stylebox_override("panel", sb)
	return p


func _build_header() -> Control:
	var band := PanelContainer.new()
	band.custom_minimum_size = Vector2(0, 64)
	var sb := StyleBoxFlat.new()
	sb.bg_color = DangoTheme.LINE
	sb.corner_radius_top_left = 24
	sb.corner_radius_top_right = 24
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	band.add_theme_stylebox_override("panel", sb)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	band.add_child(row)
	var back := _button("← Back  Esc", 150, 48)
	back.name = "Back"
	back.pressed.connect(_on_back)
	row.add_child(back)
	row.add_child(_label("Missions", 36, DangoTheme.CREAM_RAISED, true))
	var sub := _label("Stake Shard, win it back with a bonus", 16, DangoTheme.CREAM)
	sub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sub.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(sub)
	var bal := _label("", 18, DangoTheme.CREAM_RAISED)
	bal.name = "Balance"
	bal.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(bal)
	return band


func _on_back() -> void:
	if is_inside_tree() and not no_scene_change:
		LandNav.back_to_land()


func _clear(n: Node) -> void:
	for c in n.get_children():
		n.remove_child(c)
		c.queue_free()


func _banner(msg: String, detail: String, with_retry: bool) -> void:
	var p := PanelContainer.new()
	p.name = "Banner"
	var sb := StyleBoxFlat.new()
	sb.bg_color = DangoTheme.DUSK
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	p.add_theme_stylebox_override("panel", sb)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	p.add_child(h)
	var t := VBoxContainer.new()
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.add_child(_label(msg, 18, DangoTheme.DUSK_INK, true))
	t.add_child(_label(detail, 14, DangoTheme.DUSK_INK))
	h.add_child(t)
	if with_retry:
		var r := _button("Try again", 160, 44, true)
		r.pressed.connect(func() -> void: set_state("normal"))
		h.add_child(r)
	_banner_host.add_child(p)


func _modal(title: String, w: float) -> Control:
	var scrim := ColorRect.new()
	scrim.name = "Modal"
	scrim.color = DangoTheme.SCRIM
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.add_child(cc)
	var card := _plate(w, DangoTheme.LINE, DangoTheme.CREAM)
	card.name = "Card"
	cc.add_child(card)
	var v := VBoxContainer.new()
	v.name = "V"
	v.add_theme_constant_override("separation", 10)
	card.add_child(v)
	v.add_child(_label(title, 26, DangoTheme.INK, true))
	_modal_layer.add_child(scrim)
	return scrim


# ---------------------------------------------------------------- refresh

func _refresh() -> void:
	if _panel == null:
		return
	var bal: Label = _panel.find_child("Balance", true, false)
	bal.text = "Shard %d   Usable for stakes %d" % [MetaState.shard_pool, usable_shards()]
	_clear(_strip_host)
	var lv := MissionBoard.house_level(MetaState)
	var cfg := _Econ.get_table("missions")
	_strip_host.add_child(_label("Mission House Lv %d" % lv, 18, DangoTheme.INK))
	var parts: Array[String] = []
	for h in cfg.get("house", []):
		var d: Dictionary = h
		parts.append("Lv %d: %d Shard + %d Stone" % [int(d.level), int(d.cost_shards), int(d.cost_stone)])
	var costs := _label("   ".join(parts), 14, DangoTheme.INK_2)
	costs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	costs.clip_text = true
	_strip_host.add_child(costs)
	var up := _button("Upgrade", 160, 44)
	up.name = "UpgradeHouse"
	up.disabled = not bool(cfg.get("house_upgrade_enabled", false))
	up.tooltip_text = "Not in this build" if up.disabled else ""
	if up.disabled:
		up.text = "Upgrade (not in this build)"
		up.custom_minimum_size.x = 260
	_strip_host.add_child(up)
	_clear(_grid_host)
	if state == "loading":
		_grid_host.add_child(_label("Loading...", 18, DangoTheme.INK_2))
		return
	var grid := GridContainer.new()
	grid.name = "Grid"
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	_grid_host.add_child(grid)
	for o in offers():
		grid.add_child(_card(o))


func _tile(caption: String, value: String) -> Control:
	var p := _plate(0, DangoTheme.LINE, DangoTheme.CREAM_200)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.add_child(_label(caption, 14, DangoTheme.INK_2))
	v.add_child(_label(value, 22, DangoTheme.INK, true))
	p.add_child(v)
	return p


func _card(o: Dictionary) -> Control:
	var id := String(o.tier)
	var locked := not bool(o.unlocked)
	var p := _plate(0, DangoTheme.LINE, DangoTheme.CREAM_RAISED)
	p.name = "Card_" + id
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.custom_minimum_size.x = 0
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	p.add_child(v)
	var head := HBoxContainer.new()
	head.add_child(_label(id, 26, DangoTheme.INK, true))
	var mode := _label("  %s - Ascension %d" % [String(o.mode).capitalize(), int(o.ascension)], 18, DangoTheme.INK_2)
	mode.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(mode)
	v.add_child(head)
	var tiles := GridContainer.new()
	tiles.columns = 3
	tiles.add_theme_constant_override("h_separation", 8)
	tiles.add_child(_tile("Stake", str(int(o.stake))))
	tiles.add_child(_tile("Pay if you win", str(int(o.payout))))
	tiles.add_child(_tile("Stone", "+%d" % int(o.stone)))
	v.add_child(tiles)
	var names: Array[String] = []
	for r in (o.rules as Array):
		names.append(String(RULE_NAMES.get(String(r), String(r))))
	var rl := _label("Rules: " + (", ".join(names) if not names.is_empty() else "standard only"), 16,
		DangoTheme.INK_DISABLED if locked else DangoTheme.INK)
	rl.name = "Rules"
	rl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(rl)
	var why := block_reason(id)
	if locked:
		var lk := _label("Locked: " + why, 16, DangoTheme.INK_DISABLED)
		lk.name = "LockNote"
		lk.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(lk)
	var b := _button("Stake %d and play" % int(o.stake), 0, 48, true)
	b.name = "Stake_" + id
	b.disabled = why != ""
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if why != "":
		b.tooltip_text = why
		if not locked:
			b.text = why
			b.add_theme_font_size_override("font_size", 16)
	b.pressed.connect(open_confirm.bind(id))
	v.add_child(b)
	return p
