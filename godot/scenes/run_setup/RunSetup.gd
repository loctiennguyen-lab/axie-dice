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
## picker sub-view. Not wired (no game logic exists yet): Daily / Ranked modes, Kit/Boon purchase,
## preset save/load, seed well, Leaderboard button. Those render disabled with the reason shown.

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
## Tests: skip the scene change after a successful Begin.
var no_scene_change := false
## Tests: replace the real RunState call. Receives the params Dictionary, returns {ok, code}.
var start_hook: Callable = Callable()

var party: Array[String] = []
var mode := "short"
var ascension := 0
var begin_error := ""

var _panel: PanelContainer
var _body: VBoxContainer
var _footer_msg: Label
var _begin_btn: Button
var _party_row: HBoxContainer
var _party_label: Label
var _asc_chips: Array[Button] = []
var _asc_title: Label
var _asc_mult: Label
var _asc_rules: VBoxContainer
var _asc_tip: Label
var _short_btn: Button
var _full_btn: Button
var _mode_detail: Label
var _banner_host: VBoxContainer
var _modal_layer: Control
var _picker_slot := -1
var _picker_tab := "all"
var _picker_grid: GridContainer


func _ready() -> void:
	if party.is_empty():
		party = _initial_party()
	ascension = clampi(ascension, 0, ascension_ceiling())
	_build()
	if use_account:
		state = account_state()
	set_state(state)


## Run Setup state from the account: only a signed-in player who lost the connection is
## "offline". Guests play locally, so a guest is "normal". Reads AccountService.status unless
## account_status_hook is set (tests).
func account_state() -> String:
	var st: int = account_status_hook.call() if account_status_hook.is_valid() else AccountService.status
	return "offline" if st == AccountService.Status.OFFLINE else "normal"


func _unhandled_key_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_ESCAPE:
		if _modal_layer.get_child_count() > 0:
			close_modal()
		else:
			_on_back()
		get_viewport().set_input_as_handled()


# ---------------------------------------------------------------- public API (also used by tests)

func ascension_ceiling() -> int:
	return mini(ASC_MAX, MetaState.asc_max)


func is_full_unlocked() -> bool:
	return MetaState.has_unlock("u_full")


func is_newcomer() -> bool:
	return MetaState.runs < NEWCOMER_RUNS


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


## Puts hero `key` into slot `i`. Refused when the key is unknown or already in another slot.
func set_slot(i: int, key: String) -> bool:
	if i < 0 or i >= PARTY_SIZE or not ContentDB.heroes.has(key):
		return false
	for j in party.size():
		if j != i and party[j] == key:
			return false
	while party.size() < PARTY_SIZE:
		party.append("")
	party[i] = key
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
	return {"team_keys": keys, "mode": mode, "ascension": ascension, "ranked": false,
		"newcomer": is_newcomer()}


## Why Begin is disabled, or "" when it is allowed.
func begin_block_reason() -> String:
	if state == "offline" and remote_on:
		return "Needs a connection to roll dice"
	if state == "loading":
		return "Loading…"
	var missing := PARTY_SIZE - filled_count()
	if missing > 0:
		return "Pick %d more Ax%s to begin" % [missing, "ie" if missing == 1 else "ies"]
	return ""


func set_state(s: String) -> void:
	state = s
	if _panel == null:
		return
	for c in _banner_host.get_children():
		c.queue_free()
	_body.visible = s != "loading" and s != "open_run"
	var sk := _panel.get_node_or_null("Skeleton")
	if sk:
		sk.queue_free()
	var oc := _panel.get_node_or_null("OpenRun")
	if oc:
		oc.queue_free()
	if s == "loading":
		_build_skeleton()
	elif s == "open_run":
		_build_open_run()
	elif s == "offline":
		if remote_on:
			_add_banner("Can't reach the dice server", "Last updated %s. Dice are rolled on the server in this build."
				% Time.get_time_string_from_system().substr(0, 5), true)
		else:
			_add_banner("You're offline", "Dice roll on this device for now; progress syncs when you reconnect.", false)
	_refresh_footer()


## Begin. Uses start_hook if set (tests), otherwise RunState.begin_run().
func begin() -> Dictionary:
	if use_account and state in ["normal", "offline"] and account_state() != state:
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
		begin_error = "Could not roll dice, try again."
		_add_banner(begin_error, "Nothing was spent. Code: %s" % String(r.get("code", "?")), false)
		return r
	begin_error = ""
	if not no_scene_change and is_inside_tree():
		get_tree().change_scene_to_file(RUN_MAP)
	return r


func open_picker(slot: int) -> void:
	_picker_slot = slot
	_picker_tab = "all"
	_show_picker()


func close_modal() -> void:
	for c in _modal_layer.get_children():
		c.queue_free()


# ---------------------------------------------------------------- build

func _initial_party() -> Array[String]:
	var src: Array[String] = MainMenu.pending_team if not MainMenu.pending_team.is_empty() \
		else MainMenu.DEFAULT_TEAM
	var out: Array[String] = []
	for k in src:
		if ContentDB.heroes.has(k) and out.size() < PARTY_SIZE and not out.has(k):
			out.append(k)
	return out


func _build() -> void:
	# Placeholder plate until lane L's blurred Land backdrop exists; DangoScreen supplies PlateHost + scrim.
	DangoScreen.build(self, MockupAssets.tex("assets/bg/rocky.jpg"), DangoTheme.Scrim.DEFAULT, false)

	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.anchor_right = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = 200
	_panel.offset_right = -200
	_panel.offset_top = 116
	_panel.offset_bottom = -84
	var sb := StyleBoxFlat.new()
	sb.bg_color = DangoTheme.CREAM
	sb.set_corner_radius_all(28)
	sb.set_border_width_all(4)
	sb.border_color = DangoTheme.LINE
	sb.set_content_margin_all(0)
	_panel.add_theme_stylebox_override("panel", sb)
	_panel.clip_contents = true
	add_child(_panel)

	var col := VBoxContainer.new()
	col.name = "Col"
	col.add_theme_constant_override("separation", 0)
	_panel.add_child(col)
	col.add_child(_build_header())
	_banner_host = VBoxContainer.new()
	col.add_child(_banner_host)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	DangoTheme.style_scrollbars(scroll)
	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_theme_constant_override("margin_left", 24)
	pad.add_theme_constant_override("margin_right", 24)
	pad.add_theme_constant_override("margin_top", 14)
	pad.add_theme_constant_override("margin_bottom", 14)
	scroll.add_child(pad)
	_body = VBoxContainer.new()
	_body.name = "Body"
	_body.add_theme_constant_override("separation", 14)
	pad.add_child(_body)

	_build_party_block()
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 18)
	_body.add_child(cols)
	cols.add_child(_build_mode_col())
	cols.add_child(_build_asc_col())
	if not is_newcomer():
		cols.add_child(_build_kit_col())
	col.add_child(_build_footer())

	_modal_layer = Control.new()
	_modal_layer.name = "Modals"
	_modal_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_modal_layer)

	_refresh_party()
	_refresh_mode()
	_refresh_asc()


func _label(text: String, size: int, color: Color = DangoTheme.INK, display := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
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
	var title := _label("Run Setup", 36, DangoTheme.CREAM_RAISED, true)
	title.name = "Title"
	row.add_child(title)
	var sub := _label("Portal · pick a party, a length and an Ascension", 16, DangoTheme.CREAM)
	sub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sub.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(sub)
	var lb := _button("Leaderboard  B", 190, 48)
	lb.disabled = true
	lb.tooltip_text = "Leaderboard is not in this build"
	row.add_child(lb)
	return band


func _build_party_block() -> void:
	var head := HBoxContainer.new()
	head.custom_minimum_size = Vector2(0, 40)
	head.add_theme_constant_override("separation", 10)
	_party_label = _label("", 18, WOOD_DARK, true)
	_party_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_party_label)
	for t in ["Load preset", "Save as preset  S"]:
		var b := _button(t, 170, 40)
		b.disabled = true
		b.tooltip_text = "Team presets are not in this build"
		head.add_child(b)
	_body.add_child(head)
	_party_row = HBoxContainer.new()
	_party_row.name = "PartyRow"
	_party_row.add_theme_constant_override("separation", 16)
	_body.add_child(_party_row)


func _refresh_party() -> void:
	if _party_row == null:
		return
	for c in _party_row.get_children():
		_party_row.remove_child(c)
		c.queue_free()
	_party_label.text = "PARTY · %d OF %d" % [filled_count(), PARTY_SIZE]
	for i in PARTY_SIZE:
		_party_row.add_child(_build_slot(i))


func _build_slot(i: int) -> Control:
	var key := party[i] if i < party.size() else ""
	var card := PanelContainer.new()
	card.name = "Slot%d" % i
	card.custom_minimum_size = Vector2(272, 176)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(20)
	sb.set_border_width_all(3)
	sb.set_content_margin_all(10)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	card.add_child(v)
	if key == "":
		sb.bg_color = DangoTheme.CREAM_RAISED.darkened(0.04)
		sb.border_color = DangoTheme.LINE
		sb.draw_center = true
		card.add_theme_stylebox_override("panel", sb)
		var pick := _button("Pick an Axie", 0, 52)
		pick.name = "Pick"
		pick.size_flags_vertical = Control.SIZE_EXPAND_FILL
		pick.pressed.connect(open_picker.bind(i))
		v.add_child(pick)
		return card
	var def: Dictionary = ContentDB.heroes.get(key, {})
	var cls := String(def.get("cls", ""))
	sb.bg_color = DangoTheme.CREAM_RAISED
	sb.border_color = DangoTheme.LINE
	card.add_theme_stylebox_override("panel", sb)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	v.add_child(top)
	var dot := ColorRect.new()                     # class-colour portrait stand-in (52)
	dot.custom_minimum_size = Vector2(52, 52)
	dot.color = DangoTheme.class_color(cls)
	top.add_child(dot)
	var names := VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.add_child(_label(String(def.get("n", key)), 19, DangoTheme.INK, true))
	names.add_child(_label("%s · HP %d" % [cls.capitalize(), int(def.get("max_hp", 0))], 14, DangoTheme.INK_ON_CREAM_MUTED))
	top.add_child(names)
	var vault := MetaState.is_vault_key(key)
	var tag := _label("Vault" if vault else "Starter", 14, DangoTheme.INK)
	tag.custom_minimum_size = Vector2(0, 24)
	v.add_child(tag)
	var faces := HBoxContainer.new()
	faces.add_theme_constant_override("separation", 3)
	for f in (def.get("die", []) as Array):
		var cell := Label.new()
		cell.custom_minimum_size = Vector2(34, 34)
		cell.text = str(int((f as Dictionary).get("value", 0)))
		cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cell.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
		cell.add_theme_font_size_override("font_size", 16)
		cell.add_theme_color_override("font_color", DangoTheme.INK)
		var cs := StyleBoxFlat.new()
		cs.bg_color = DangoTheme.die_type_color(String((f as Dictionary).get("type", ""))).lightened(0.35)
		cs.set_corner_radius_all(8)
		cell.add_theme_stylebox_override("normal", cs)
		faces.add_child(cell)
	v.add_child(faces)
	var acts := HBoxContainer.new()
	acts.add_theme_constant_override("separation", 8)
	var swap := _button("Swap", 90, 44)
	swap.name = "Swap"
	swap.pressed.connect(open_picker.bind(i))
	acts.add_child(swap)
	var clr := _button("Clear", 90, 44)
	clr.name = "Clear"
	clr.pressed.connect(clear_slot.bind(i))
	acts.add_child(clr)
	v.add_child(acts)
	return card


func _plate(min_w: float, border: Color = DangoTheme.LINE, fill: Color = DangoTheme.CREAM_DISABLED) -> PanelContainer:
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


func _chip_style(fill: Color, border: Color, shelf := 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.set_corner_radius_all(10)
	s.set_border_width_all(2)
	s.border_color = border
	s.shadow_color = DangoTheme.LINE
	s.shadow_size = 0
	s.shadow_offset = Vector2(0, shelf)
	return s


func _seg_button(text: String, sub: String, h: float) -> Button:
	var b := Button.new()
	b.toggle_mode = true
	b.custom_minimum_size = Vector2(0, h)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.text = text if sub == "" else "%s\n%s" % [text, sub]
	b.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	b.add_theme_font_size_override("font_size", 18)
	return b


func _build_mode_col() -> Control:
	var p := _plate(440)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	p.add_child(v)
	v.add_child(_label("MODE", 16, WOOD_DARK, true))
	var seg := HBoxContainer.new()
	seg.add_theme_constant_override("separation", 6)
	v.add_child(seg)
	var normal := _seg_button("Normal", "free choice", 62)
	normal.name = "ModeNormal"
	normal.button_pressed = true
	_style_seg(normal, true)
	seg.add_child(normal)
	for t in [["Daily", "not in this build"], ["Ranked", "not in this build"]]:
		var b := _seg_button(t[0], t[1], 62)
		b.name = "Mode" + t[0]
		b.disabled = true
		b.tooltip_text = "%s is not in this build" % t[0]
		_style_seg(b, false)
		seg.add_child(b)
	v.add_child(_label("LENGTH", 16, WOOD_DARK, true))
	var lrow := HBoxContainer.new()
	lrow.add_theme_constant_override("separation", 6)
	v.add_child(lrow)
	var grp := ButtonGroup.new()
	_short_btn = _seg_button("Short", "", 54)
	_short_btn.name = "LenShort"
	_short_btn.button_group = grp
	_short_btn.pressed.connect(select_length.bind("short"))
	lrow.add_child(_short_btn)
	_full_btn = _seg_button("Full", "", 54)
	_full_btn.name = "LenFull"
	_full_btn.button_group = grp
	_full_btn.pressed.connect(func() -> void:
		if not select_length("full"):
			_refresh_mode())
	if not is_full_unlocked():
		_full_btn.tooltip_text = "Win a Short run to unlock Full"
	lrow.add_child(_full_btn)
	_mode_detail = _label("", 15, DangoTheme.INK)
	_mode_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_mode_detail)
	return p


func _style_seg(b: Button, on: bool) -> void:
	var fill := DangoTheme.PRIMARY if on else DangoTheme.CREAM_DISABLED
	var border := DangoTheme.LINE
	for k in ["normal", "hover", "pressed", "disabled", "focus"]:
		var st := _chip_style(fill, border, 4 if on else 0)
		if k == "focus":
			st.draw_center = false
			st.border_color = DangoTheme.GOLD
			st.set_border_width_all(4)
		b.add_theme_stylebox_override(k, st)
	for c in ["font_color", "font_pressed_color", "font_hover_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(c, DangoTheme.INK)
	b.add_theme_color_override("font_disabled_color", DangoTheme.INK_DISABLED)


func _refresh_mode() -> void:
	if _short_btn == null:
		return
	var full_ok := is_full_unlocked()
	_short_btn.set_pressed_no_signal(mode == "short")
	_full_btn.set_pressed_no_signal(mode == "full")
	_style_seg(_short_btn, mode == "short")
	_style_seg(_full_btn, mode == "full" and full_ok)
	if not full_ok:
		_full_btn.text = "Full  🔒"
		_full_btn.add_theme_color_override("font_color", DangoTheme.INK_DISABLED)
	var cfg: Dictionary = RunMapGenerator.MODE_CONFIG.get(mode, {})
	var txt := "%s · %d rows · %d bosses" % [mode.capitalize(), int(cfg.get("total_rows", 0)),
		(cfg.get("boss_rows", []) as Array).size()]
	if not full_ok:
		txt += "\nFull is locked. Win a Short run to unlock Full."
	_mode_detail.text = txt


func _build_asc_col() -> Control:
	var p := _plate(0)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	p.add_child(v)
	v.add_child(_label("ASCENSION", 16, WOOD_DARK, true))
	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 6)
	v.add_child(chips)
	_asc_chips.clear()
	for n in ASC_MAX + 1:
		var b := Button.new()
		b.name = "Asc%d" % n
		b.custom_minimum_size = Vector2(44, 44)
		b.text = "A%d" % n
		b.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
		b.add_theme_font_size_override("font_size", 16)
		b.pressed.connect(_on_asc_pressed.bind(n))
		chips.add_child(b)
		_asc_chips.append(b)
	_asc_title = _label("", 26, DangoTheme.INK, true)
	v.add_child(_asc_title)
	_asc_mult = _label("", 15, DangoTheme.LINE)
	v.add_child(_asc_mult)
	_asc_tip = _label("", 14, DangoTheme.DUSK_INK)
	v.add_child(_asc_tip)
	var well := _plate(0, DangoTheme.LINE, DangoTheme.CREAM_TRACK)
	v.add_child(well)
	_asc_rules = VBoxContainer.new()
	_asc_rules.add_theme_constant_override("separation", 2)
	well.add_child(_asc_rules)
	return p


func _on_asc_pressed(n: int) -> void:
	if not select_ascension(n):
		_asc_tip.text = "Win a run at A%d to unlock A%d" % [n - 1, n]


func _refresh_asc() -> void:
	if _asc_title == null:
		return
	_asc_tip.text = ""
	var ceil := ascension_ceiling()
	for n in _asc_chips.size():
		var b := _asc_chips[n]
		var locked := n > ceil
		var sel := n == ascension
		var fill := DangoTheme.PRIMARY if sel else (DangoTheme.CREAM_DISABLED if locked else DangoTheme.CREAM_RAISED)
		for k in ["normal", "hover", "pressed", "disabled"]:
			b.add_theme_stylebox_override(k, _chip_style(fill, DangoTheme.LINE, 4 if sel else 0))
		var f := _chip_style(fill, DangoTheme.GOLD)
		f.draw_center = false
		f.set_border_width_all(4)
		b.add_theme_stylebox_override("focus", f)
		for c in ["font_color", "font_hover_color", "font_pressed_color"]:
			b.add_theme_color_override(c, DangoTheme.INK_DISABLED if locked else DangoTheme.INK)
		b.tooltip_text = "Win a run at A%d to unlock A%d" % [n - 1, n] if locked else ""
		b.text = "A%d" % n + ("🔒" if locked else "")
	var m: Dictionary = ContentDB.ascension_mods(ascension)
	if ascension == 0:
		_asc_title.text = "A0 · Normal"
		var clk: Dictionary = m.get("clock", {})
		_asc_mult.text = "No extra rules · light boss clock from turn %d" % int(clk.get("start", 14))
	else:
		_asc_title.text = "A%d · %s" % [ascension, RULES[ascension - 1][1]]
		_asc_mult.text = "%d rule%s active · Enemy HP ×%.2f · Damage ×%.2f · Boss HP ×%.2f" % [
			ascension, "" if ascension == 1 else "s", float(m.get("hp", 1.0)),
			float(m.get("dmg", 1.0)), float(m.get("boss_hp", 1.0))]
	for c in _asc_rules.get_children():
		_asc_rules.remove_child(c)
		c.queue_free()
	for r in RULES:
		var lvl: int = r[0]
		if lvl > ascension:
			break
		var line: String = r[2]
		var grey := false
		if lvl == 4 and ascension >= 9:
			line = "Enrage from turn 8 (A9): +20%/turn, max +100%"
		if lvl == 6 and ascension >= 10:
			line = "Replaced by A10"
			grey = true
		_asc_rules.add_child(_rule_row(lvl, r[1], line, lvl == ascension, grey))
	if ascension == 0:
		_asc_rules.add_child(_label("Pick a higher level to add rules.", 15, DangoTheme.INK_ON_CREAM_MUTED))


func _rule_row(lvl: int, nm: String, line: String, current: bool, grey: bool) -> Control:
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(0, 30)
	var sb := StyleBoxFlat.new()
	sb.bg_color = DangoTheme.PRIMARY if current else Color(0, 0, 0, 0)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 8
	row.add_theme_stylebox_override("panel", sb)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	row.add_child(h)
	var ink := DangoTheme.INK_DISABLED if grey else DangoTheme.INK
	var code := _label("A%d" % lvl, 15, ink, true)
	code.custom_minimum_size = Vector2(36, 0)
	h.add_child(code)
	var n := _label(nm, 15, ink, true)
	n.custom_minimum_size = Vector2(120, 0)
	h.add_child(n)
	var d := _label(line, 14, ink)
	d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(d)
	if current:
		h.add_child(_label("NEW", 12, DangoTheme.INK, true))
	return row


func _build_kit_col() -> Control:
	var p := _plate(400, DangoTheme.GEM_SHELF, DangoTheme.GEM_PANEL_TINT)
	p.name = "KitBoon"
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	p.add_child(v)
	v.add_child(_label("AID FOR THIS RUN", 16, DangoTheme.GEM_INK, true))
	for t in [["Starting Boon", "38 Gem ≈ 0.42 USD"], ["Run Kit", "60 Gem ≈ 0.67 USD"]]:
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 58)
		var names := VBoxContainer.new()
		names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		names.add_child(_label(t[0], 17, DangoTheme.GEM_INK, true))
		names.add_child(_label(t[1], 14, DangoTheme.GEM_INK))
		row.add_child(names)
		var add := _button("Add", 90, 44)
		add.disabled = true
		add.tooltip_text = "Aid purchase is not in this build"
		row.add_child(add)
		v.add_child(row)
	var f := _label(FAIRNESS, 14, DangoTheme.GEM_INK)
	f.name = "Fairness"
	f.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(f)
	return p


func _build_footer() -> Control:
	var band := PanelContainer.new()
	band.custom_minimum_size = Vector2(0, 84)
	var sb := StyleBoxFlat.new()
	sb.bg_color = DangoTheme.CREAM_DISABLED
	sb.corner_radius_bottom_left = 24
	sb.corner_radius_bottom_right = 24
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	band.add_theme_stylebox_override("panel", sb)
	var h := HBoxContainer.new()
	band.add_child(h)
	_footer_msg = _label("", 17, DangoTheme.INK)
	_footer_msg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_footer_msg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_footer_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	h.add_child(_footer_msg)
	_begin_btn = _button("Begin run", 380, 60, true)
	_begin_btn.name = "Begin"
	_begin_btn.add_theme_font_size_override("font_size", 24)
	_begin_btn.pressed.connect(func() -> void: begin())
	h.add_child(_begin_btn)
	return band


func _refresh_footer() -> void:
	if _footer_msg == null:
		return
	var why := begin_block_reason()
	_begin_btn.disabled = why != ""
	var summary := "Party %d of %d · %s · A%d" % [filled_count(), PARTY_SIZE, mode.capitalize(), ascension]
	_footer_msg.text = summary if why == "" else "%s\n%s" % [summary, why]


# ---------------------------------------------------------------- states

func _add_banner(msg: String, detail: String, with_retry: bool) -> void:
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
	h.add_child(_label("⚠", 28, DangoTheme.DUSK_INK))
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


func _build_skeleton() -> void:
	var sk := VBoxContainer.new()
	sk.name = "Skeleton"
	sk.add_theme_constant_override("separation", 14)
	sk.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for h in [176, 360]:
		var w := Panel.new()
		w.custom_minimum_size = Vector2(0, h)
		var sb := StyleBoxFlat.new()
		sb.bg_color = DangoTheme.CREAM_TRACK
		sb.set_corner_radius_all(20)
		w.add_theme_stylebox_override("panel", sb)
		sk.add_child(w)
	_panel.get_node("Col").add_child(sk)
	_panel.get_node("Col").move_child(sk, 2)


func _build_open_run() -> void:
	var holder := CenterContainer.new()
	holder.name = "OpenRun"
	holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var card := _plate(640)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	card.add_child(v)
	v.add_child(_label("You have an unfinished run", 26, DangoTheme.INK, true))
	var line := "Saved run on disk"
	v.add_child(_label(line, 16, DangoTheme.INK_ON_CREAM_MUTED))
	var cont := _button("Continue run", 0, 60, true)
	cont.name = "Continue"
	cont.pressed.connect(_on_continue)
	v.add_child(cont)
	var nw := _button("New run", 0, 48)
	nw.name = "NewRun"
	nw.pressed.connect(func() -> void: set_state("normal"))
	v.add_child(nw)
	v.add_child(_label("A new run ends the current run. Aid you used is not refunded.", 14, DangoTheme.INK))
	holder.add_child(card)
	_panel.get_node("Col").add_child(holder)
	_panel.get_node("Col").move_child(holder, 2)
	cont.grab_focus.call_deferred()


func _on_continue() -> void:
	if not RunState.load_run():
		RunState.clear_saved_run()
		set_state("normal")
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


func _show_picker() -> void:
	close_modal()
	var dim := ColorRect.new()
	dim.color = Color(0x24 / 255.0, 0x14 / 255.0, 0x0B / 255.0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.offset_left = 200
	dim.offset_right = -200
	dim.offset_top = 116
	dim.offset_bottom = -84
	_modal_layer.add_child(dim)
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(c)
	var p := _plate(1000, DangoTheme.LINE, DangoTheme.CREAM)
	p.name = "Picker"
	c.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	p.add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	v.add_child(head)
	var back := _button("← Back", 120, 44)
	back.pressed.connect(close_modal)
	head.add_child(back)
	var t := _label("Run Setup › Party › Slot %d" % (_picker_slot + 1), 24, DangoTheme.INK, true)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	for tab in ["all", "starter", "vault"]:
		var tb := _button(tab.capitalize(), 100, 44, tab == _picker_tab)
		tb.name = "Tab_" + tab
		tb.pressed.connect(func() -> void:
			_picker_tab = tab
			_show_picker())
		head.add_child(tb)
	_picker_grid = GridContainer.new()
	_picker_grid.columns = 5
	_picker_grid.add_theme_constant_override("h_separation", 10)
	_picker_grid.add_theme_constant_override("v_separation", 10)
	v.add_child(_picker_grid)
	for k in _pick_keys():
		var def: Dictionary = ContentDB.heroes[k]
		var taken := party.has(k) and party.find(k) != _picker_slot
		var b := _button("%s\n%s" % [String(def.get("n", k)), String(def.get("cls", "")).capitalize()], 124, 80)
		b.name = "Tile_" + k
		b.disabled = taken
		b.tooltip_text = "Already in another slot" if taken else ""
		b.pressed.connect(func() -> void:
			if set_slot(_picker_slot, k):
				close_modal())
		_picker_grid.add_child(b)
	if _picker_tab == "vault" and _pick_keys().is_empty():
		v.add_child(_label("Your Vault is empty. Import an Axie in the Vault.", 16, DangoTheme.INK_ON_CREAM_MUTED))
