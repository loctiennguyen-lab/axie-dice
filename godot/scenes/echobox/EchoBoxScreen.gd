class_name EchoBoxScreen
extends Control
## M5 Echo Box (key 4). Spec: design/handoffs/ui-02-round3 README section 2 M5, frames M5a-M5w.
## Layout: shell panel (left/right 200, top 116) with wood header band 64, ticket bar 64, tabs 46,
## stage + right column (pity bars, pool tiles, duplicates line), rates modal, reveal ceremony.
## Logic is EchoBox (scripts/meta/echo_box.gd) on MetaState: open_normal / buy_tickets. This scene
## holds no odds of its own: pity thresholds, pool sizes, rates and prices are all read from the
## economy table (EchoBox / EconomyDB). Pulls are client-side today (echo_box.gd says the server
## rolls later); `pull_hook` is the seam for that.
##
## Drawn: normal, no tickets, loading, offline, guest, server error (pull failed), Seasonal locked
## ("coming later", no Open button), reveal Stone / cosmetic NEW / duplicate, Open 10 + summary,
## Skip, rates modal, buy confirm, reduce-flashing static reveal, "your last pull" recovery.
## Seasonal tab (live since 19/10): EchoBox.open_season, 5 tickets a pull, 8 pulls a day, progress per tier,
## milestones, the 11-item series grid. Reveal reuses the normal reveal cards. Not drawn: M5t explainer, vault card,
## series end date (series end 26 Jan 2027 is [INF]).

const SCREEN_ID := "echobox"
const _Econ := preload("res://scripts/meta/economy_db.gd")
const PULL_N := 10
const CHEST_BY_RARITY := {"common": "Bronze", "uncommon": "Silver", "rare": "Gold", "epic": "Platinum",
	"legendary": "Diamond", "mythic": "Lunacian"}
const STONE_CHEST := {100: "Bronze", 250: "Bronze", 500: "Silver", 1000: "Gold", 2500: "Platinum", 10000: "Lunacian"}

## "normal" | "loading" | "offline" | "guest" | "error" | "last_pull"
var state := "normal"
var tab := "regular"
## Tests: no scene change, no tween waits.
var no_scene_change := false
var instant := false
## Static reveal: no rim glow, 200 ms fade (M5u). TODO lane U: one global flag in Settings.
var reduce_flashing := false
## Tests / server seam: Callable(n:int) -> Array of result Dictionaries (EchoBox.open_normal shape).
var pull_hook: Callable = Callable()
## First season pull of the play session asks for a confirm (README M5o; Liam 20/10: once per session, not per visit).
## Session-only, never saved. Tests set season_confirmed explicitly so they do not depend on order.
static var _season_confirmed_session := false
var season_confirmed: bool:
	get: return _season_confirmed_session
	set(v): _season_confirmed_session = v
var rng := RandomNumberGenerator.new()
var results: Array = []
var error_text := ""
## Derive state from AccountService (guest/offline). Tests that drive state by hand turn this off.
var use_account := true
## Remote Gem wallet on (ProjectSettings "axie/gem_wallet" == "remote"). Only then do guest/offline
## block pulls and buying; while tickets are local they just show the info banner. Tests override.
var remote_on: bool = String(ProjectSettings.get_setting("axie/gem_wallet", "")) == "remote"
## Tests: replaces AccountService.status. Returns an AccountService.Status int.
var account_status_hook: Callable

const DETAIL_W := 456
## Rarity -> UI-03 colour token (the tokens have four tiers; uncommon reads as rare, mythic as legendary).
const RARITY_TOKEN := {"common": "rarity_common", "uncommon": "rarity_uncommon", "rare": "rarity_rare",
	"epic": "rarity_epic", "legendary": "rarity_legendary", "mythic": "rarity_mythic"}
const CARD_W := 300.0
const CARD_H_10 := 380.0
const CARD_W_1 := 480.0
const CARD_H_1 := 660.0
const FLIP_S := 0.16
const FLIP_GAP := 0.12

var _shell: Dictionary
var _col: VBoxContainer
var _body: HBoxContainer
var _banner_host: VBoxContainer
var _bar_host: HBoxContainer
var _stage_host: VBoxContainer
var _stage_v: VBoxContainer
## Last result shown in the strip under the chest (EchoBox.open_normal shape); empty = nothing yet.
var last_open: Dictionary = {}
var _opening := false
var _idle_tw: Tween
var _side_host: VBoxContainer
var _tab_btns: Dictionary = {}
var _modal_layer: Control
var _skip := false


func _ready() -> void:
	rng.randomize()
	_build()
	if use_account:
		state = account_state()
	set_state(state)


## Echo Box state from the account: guest and expired sign-in cannot hold tickets (R3 M5l),
## offline blocks pulls (M5k), everything else is "normal". Reads AccountService.status unless
## account_status_hook is set (tests).
func account_state() -> String:
	var st: int = account_status_hook.call() if account_status_hook.is_valid() else AccountService.status
	match st:
		AccountService.Status.GUEST, AccountService.Status.EXPIRED:
			return "guest"
		AccountService.Status.OFFLINE:
			return "offline"
	return "normal"


## Re-derive before a spend. Leaves transient states (loading/error/last_pull) alone unless the
## account itself blocks.
func _recheck_account() -> void:
	if not use_account:
		return
	var a := account_state()
	if a != "normal" and state != a:
		set_state(a)
	elif a == "normal" and (state == "guest" or state == "offline"):
		set_state("normal")


func _unhandled_key_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		if ev.is_action_pressed(&"menu_back"):
			if _modal_layer.get_child_count() > 0:
				close_modal()
			else:
				_on_back()
			if is_inside_tree():   # a handler above may have changed scene
				get_viewport().set_input_as_handled()
		elif ev.keycode == KEY_SPACE and (_modal_layer.get_child_count() > 0 or _opening):
			_skip = true


# ---------------------------------------------------------------- public API (also tests)

func tickets() -> int:
	return int(MetaState.tickets.get("normal", 0))


## True when guest/offline actually stops pulls and buying (remote wallet only).
func _account_blocks() -> bool:
	return remote_on and (state == "offline" or state == "guest")


func today() -> String:
	return Time.get_date_string_from_system(true)


func is_guest() -> bool:
	return state == "guest"


func box_cfg() -> Dictionary:
	return ((_Econ.get_table("echobox").get("boxes", {}) as Dictionary).get("normal", {}) as Dictionary)


func next_price() -> int:
	return EchoBox.cost_for(MetaState, today(), 1)


## Why pulling n is not allowed right now, or "" when it is.
func pull_block_reason(n: int) -> String:
	var seasonal := tab == "seasonal"
	if seasonal and not EchoBox.season_enabled():
		return "Season box is not live"
	if state == "loading":
		return "Loading..."
	if _account_blocks():
		return "Needs a connection - nothing is spent" if state == "offline" else "Sign in to get tickets"
	if seasonal:
		if season_pulls_left() < n:
			return "%d of %d today - resets 00:00 UTC" % [season_cap_day(), season_cap_day()] if season_pulls_left() == 0 \
				else "Only %d pulls left today" % season_pulls_left()
		if tickets() < n * season_cost():
			return "Not enough tickets (%d of %d)" % [tickets(), n * season_cost()]
		return ""
	if tickets() < n:
		return "Not enough tickets (%d of %d)" % [tickets(), n]
	return ""


func season_cost() -> int:
	return int(EchoBox.season_cfg().get("ticket_cost", 5))


## Cap N_t for a tier. Vault (doubled N) is not wired into the screen yet; flip this when it is.
func _season_cap(tier: String) -> int:
	return EchoBox.season_cap(tier, false)


func season_cap_day() -> int:
	return int(EchoBox.season_cfg().get("pull_cap_day", 8))


## Pulls still allowed today (UTC), from the saved series state.
func season_pulls_left() -> int:
	var st := EchoBox.season_state(MetaState)
	var used := int(st["day_pulls"]) if String(st["day"]) == today() else 0
	return maxi(season_cap_day() - used, 0)


## Season results look like normal ones for the reveal cards: rarity = tier.
func _season_result(r: Dictionary) -> Dictionary:
	var o := r.duplicate()
	o["season"] = true
	o["rarity"] = String(r.get("tier", ""))
	o["fragments"] = 0
	return o


## Real pull: n tickets through EchoBox.open_normal (or pull_hook). Returns the result list.
func pull(n: int) -> Array:
	_recheck_account()
	if pull_block_reason(n) != "":
		return []
	var out: Array = []
	if pull_hook.is_valid():
		out = pull_hook.call(n)
	elif MetaState.econ_remote() != null and tab != "seasonal":
		# SR1: the server rolls and pays; this screen only plays what it was told.
		for i in n:
			var r := await _remote_open()
			if not bool(r.get("ok", false)):
				break
			out.append(r)
	elif tab == "seasonal":
		for i in n:
			var r := EchoBox.open_season(MetaState, rng, today())
			if not r.get("ok", false):
				break
			out.append(_season_result(r))
	else:
		for i in n:
			var r := EchoBox.open_normal(MetaState, rng)
			if not r.get("ok", false):
				break
			out.append(r)
	if out.is_empty():
		error_text = "Could not open the box. Your tickets were not spent."
		set_state("error")
		return out
	error_text = "Opened %d of %d" % [out.size(), n] if out.size() < n else ""
	results = out
	_refresh_bar()
	await _play_ceremony(out)
	return out


signal _remote_answered

## One server open. Returns the result Dictionary (EchoBox.open_normal shape) with ok=true, or {ok:false, reason}.
func _remote_open() -> Dictionary:
	var box: Array = []
	MetaState.econ_remote().open_box(func(r: Dictionary) -> void:
		box.append(r)
		_remote_answered.emit())
	if box.is_empty():
		await _remote_answered
	var a: Dictionary = box[0]
	if not bool(a["ok"]):
		return {"ok": false, "reason": String(a["code"])}
	var res: Dictionary = (a["result"] as Dictionary).duplicate()
	res["ok"] = true
	return res


## Buy one ticket for Shards (EchoBox.buy_tickets). Returns the logic result.
func buy_ticket() -> Dictionary:
	_recheck_account()
	if _account_blocks():
		return {"ok": false, "reason": "state"}
	if MetaState.econ_remote() != null:
		var got: Array = []
		MetaState.econ_remote().buy_tickets(1, func(r: Dictionary) -> void:
			got.append(r)
			_remote_answered.emit())
		if got.is_empty():
			await _remote_answered
		var rr: Dictionary = got[0]
		_refresh_all()
		return {"ok": bool(rr["ok"]), "cost": int((rr["result"] as Dictionary).get("cost", 0)), "reason": String(rr["code"])}
	var r := EchoBox.buy_tickets(MetaState, today(), 1)
	if r.get("ok", false):
		MetaState.save_to_disk()
	_refresh_all()
	return r


func select_tab(t: String) -> void:
	tab = t
	_refresh_all()


func set_state(s: String) -> void:
	state = s
	if _shell.is_empty():
		return
	UI3Meta.clear(_banner_host)
	_body.visible = s != "loading"
	var sk := _col.get_node_or_null("Skeleton")
	if sk:
		_col.remove_child(sk)
		sk.queue_free()
	if s == "loading":
		_build_skeleton()
	elif s == "offline":
		if remote_on:
			_banner("Can't reach the server", "Opening needs a connection; nothing is spent. Cached counts are greyed.", true)
		else:
			_banner("You're offline", "Boxes open on this device for now; progress syncs when you reconnect.", false)
	elif s == "guest":
		if remote_on:
			_banner("Sign in to use this.", "Guests can read the rates and pool. Tickets and pulls need an account.", false)
		else:
			_banner("You're signed out", "Boxes open on this device. Sign in to keep your tickets across devices.", false)
	elif s == "error":
		_banner("Pull failed (server error)", error_text if error_text != "" else "Your tickets were not spent.", true)
	elif s == "last_pull":
		_banner("Your last pull", "The window closed mid-pull. The server kept the result; here it is.", false)
	_refresh_all()


func open_rates() -> void:
	close_modal()
	var m := _modal("Rates", 760)
	var v: VBoxContainer = m.find_child("V", true, false)
	if tab == "seasonal":
		_season_rates(v)
		_modal_close_row(v)
		return
	v.add_child(UI3.label("Regular box · each pull is exactly one reward", "LabelMuted"))
	var rows: Array = box_cfg().get("table", [])
	var total := 0.0
	for r in rows:
		total += float((r as Dictionary).get("weight", 0))
	var grid := GridContainer.new()
	grid.name = "RatesTable"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 40)
	v.add_child(grid)
	for r in rows:
		var d: Dictionary = r
		var nm := ("%s Stone" % int(d.get("amount", 0))) if String(d.get("kind")) == "stone" \
			else ("%s cosmetic" % String(d.get("rarity", "")).capitalize())
		grid.add_child(UI3.label(nm))
		grid.add_child(UI3.label("%.3f%%" % (float(d.get("weight", 0)) / total * 100.0)))
	var pt := UI3.label(_pity_text(), "LabelMuted")
	pt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(pt)
	_modal_close_row(v)


func _season_rates(v: VBoxContainer) -> void:
	var cfg := EchoBox.season_cfg()
	v.add_child(UI3.label("Season box · each pull is exactly one reward", "LabelMuted"))
	var txt := "Each pull tests Mythic, then Legendary, then Epic. The chance rises with every miss and resets on a hit: p(c) = (2c-1) / (N^2-(c-1)^2), certain at the cap."
	for t in ["mythic", "legendary", "epic"]:
		txt += "\n%s: cap %d" % [t.capitalize(), _season_cap(t)]
	var l := UI3.label(txt)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(l)
	var rows: Array = cfg.get("stone_table", [])
	var total := 0.0
	for r in rows:
		total += float((r as Dictionary).get("weight", 0))
	v.add_child(UI3.label("A pull that hits no tier gives Stone:", "LabelMuted"))
	var grid := GridContainer.new()
	grid.name = "RatesTable"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 40)
	v.add_child(grid)
	for r in rows:
		grid.add_child(UI3.label("%s Stone" % UI3.fmt(int((r as Dictionary).get("amount", 0)))))
		grid.add_child(UI3.label("%.2f%%" % (float((r as Dictionary).get("weight", 0)) / total * 100.0)))


func open_confirm_buy() -> void:
	var no := UI3.button("Cancel", &"secondary", &"M")
	no.name = "Cancel"
	no.pressed.connect(close_modal)
	var yes := UI3.button("Buy", &"primary", &"M")
	yes.name = "ConfirmBuy"
	yes.pressed.connect(func() -> void:
		close_modal()
		buy_ticket())
	var m := UI3.modal("Buy a ticket?", "The next ticket costs %d Shards, more than twice today's first one." % next_price(),
		[no, yes], 1)
	m.cancelled.connect(close_modal)
	_modal_layer.add_child(m)


func close_modal() -> void:
	if _modal_layer != null:
		UI3Meta.clear(_modal_layer)


# ---------------------------------------------------------------- build

func _build() -> void:
	_shell = UI3Meta.build(self, "Echo Box", "Spend tickets, get Stone or a cosmetic", _on_back)
	(_shell["panel"] as Control).name = "PlateHost"   # t_ui_laws L0
	_col = _shell["col"]
	_banner_host = _shell["banner_host"]
	_modal_layer = _shell["modal_layer"]
	for t in [["regular", "Regular"], ["seasonal", "Seasonal"]]:
		var b := UI3Meta.tab(String(t[1]), t[0] == tab)
		b.name = "Tab_" + String(t[0])
		b.pressed.connect(select_tab.bind(String(t[0])))
		(_shell["header_right"] as Control).add_child(b)
		_tab_btns[t[0]] = b
	_body = HBoxContainer.new()
	_body.name = "Body"
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", UI3Meta.GAP)
	_col.add_child(_body)
	_stage_host = VBoxContainer.new()
	_stage_host.name = "Stage"
	_stage_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stage_host.add_theme_constant_override("separation", UI3Theme.space("16"))
	_body.add_child(_stage_host)
	# One stage plate: ticket bar on top, chest stage + buttons + last-open strip below (UI-04 M3).
	var plate := UI3.plate(&"plate")
	plate.name = "StagePlate"
	plate.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_stage_v = VBoxContainer.new()
	_stage_v.name = "StageV"
	_stage_v.add_theme_constant_override("separation", UI3Theme.space("16"))
	plate.add_child(_stage_v)
	_bar_host = HBoxContainer.new()
	_bar_host.name = "TicketBar"
	_bar_host.add_theme_constant_override("separation", UI3Theme.space("16"))
	_stage_v.add_child(_bar_host)
	_stage_host.add_child(plate)
	_side_host = VBoxContainer.new()
	_side_host.name = "Side"
	_side_host.custom_minimum_size = Vector2(DETAIL_W, 0)
	_side_host.add_theme_constant_override("separation", UI3Theme.space("16"))
	_body.add_child(_side_host)


func _on_back() -> void:
	if is_inside_tree() and not no_scene_change:
		LandNav.back_to_land()


func _banner(msg: String, detail: String, with_retry: bool) -> void:
	var btns: Array = []
	if with_retry:
		btns.append({"name": "TryAgain", "text": "Try again", "primary": true, "cb": func() -> void: set_state("normal")})
	UI3Meta.banner(_banner_host, msg, detail, btns)


## Dialog on a scrim in the modal layer: returns the scrim; the content VBox is "V" (first child = title).
func _modal(title: String, w: float) -> Control:
	var c := UI3Meta.scrim(_modal_layer, "Modal")
	var card := UI3.plate(&"dialog")
	card.name = "Card"
	card.custom_minimum_size = Vector2(w, 0)
	c.add_child(card)
	var v := VBoxContainer.new()
	v.name = "V"
	v.add_theme_constant_override("separation", UI3Theme.space("16"))
	card.add_child(v)
	v.add_child(UI3.label(title, "LabelTitle"))
	return c.get_parent()


func _modal_close_row(v: VBoxContainer) -> void:
	var b := UI3.button("Close", &"primary", &"M")
	b.name = "Close"
	b.tooltip_text = "Esc"
	b.pressed.connect(close_modal)
	v.add_child(b)
	_focus_later(b)


func _focus_later(c: Control) -> void:
	(func() -> void:
		if is_instance_valid(c) and c.is_inside_tree():
			c.grab_focus()).call_deferred()


func _rarity_color(rar: String) -> Color:
	return UI3Theme.color(String(RARITY_TOKEN.get(rar, "rarity_common")))


## Rarity colour for text on a dark plate (mythic has its own text token).
func _rarity_text(rar: String) -> Color:
	return UI3Theme.color("rarity_mythic_text") if rar == "mythic" else _rarity_color(rar)


# ---------------------------------------------------------------- refresh

func _clear(n: Node) -> void:
	UI3Meta.clear(n)


func _refresh_all() -> void:
	if _shell.is_empty():
		return
	for k in _tab_btns:
		(_tab_btns[k] as Button).button_pressed = k == tab
	_refresh_bar()
	_refresh_stage()
	_refresh_side()


## The header wallet follows MetaState by itself (UI3Meta.WalletSync); this just makes it instant after a pull / buy.
func _sync_wallet() -> void:
	var w := find_child("WalletSync", true, false)
	if w != null:
		w.call("sync")


## Pill (64 high by default) on the stage plate: raised fill, no border.
func _pill(h := 64) -> PanelContainer:
	var p := PanelContainer.new()
	p.theme = UI3Theme.get_theme()
	p.custom_minimum_size = Vector2(0, h)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("panel_raised"), UI3Theme.radius("pill"), 0,
		Color.TRANSPARENT, Vector4(12, 0, 20, 0)))
	return p


func _icon(icon_name: String, px: float, node_name := "") -> TextureRect:
	var t := TextureRect.new()
	if node_name != "":
		t.name = node_name
	t.texture = UI3.currency_icon(icon_name, px)
	t.custom_minimum_size = Vector2(px, px)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


## Rowdies label at `size` in a given colour.
func _dlabel(text: String, col: Color, size := 18) -> Label:
	var l := UI3.label(text, "LabelDisplay")
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l


func _meter(w: float, h: float, value: float, max_v: float, fill: Color, node_name := "") -> ProgressBar:
	var pb := ProgressBar.new()
	if node_name != "":
		pb.name = node_name
	pb.theme = UI3Theme.get_theme()
	pb.custom_minimum_size = Vector2(w, h)
	pb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pb.max_value = max_v
	pb.value = value
	pb.show_percentage = false
	pb.add_theme_stylebox_override("background", UI3Theme.flat(UI3Theme.color("hp_track"), int(h / 2.0)))
	pb.add_theme_stylebox_override("fill", UI3Theme.flat(fill, int(h / 2.0)))
	return pb


## Price chip inside a button (secondary variant; the primary one goes through UI3.button_with_cost).
func _cost_in_button(b: Button, kind: StringName, amount: int, reserve := 96, primary := false) -> void:
	var chip := UI3.cost_chip(kind, amount)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in chip.find_children("*", "Control", true, false):
		(c as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("keycap_bg" if primary else "panel"),
		UI3Theme.radius("pill"), 0, Color.TRANSPARENT, Vector4(10, 0, 14, 0)))
	chip.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	chip.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	chip.grow_vertical = Control.GROW_DIRECTION_BOTH
	chip.offset_right = -UI3Theme.space("16")
	b.add_child(chip)
	for st in ["normal", "hover", "pressed", "disabled"]:
		var s := b.get_theme_stylebox(st, b.theme_type_variation).duplicate() as StyleBoxFlat
		s.content_margin_right += reserve + UI3Theme.space("8")
		b.add_theme_stylebox_override(st, s)


## Primary button with the price chip inside (same as UI3.button_with_cost, but resolves the theme variation
## by name: button_with_cost reads the default-theme stylebox when the button is not in the tree yet).
func _primary_cost(text: String, kind: StringName, amount: int, size := &"L") -> Button:
	var b := UI3.button(text, &"primary", size)
	_cost_in_button(b, kind, amount, 96, true)
	return b


## DUPLICATE chip: square (radius 4), 2 px muted border, Rowdies 18 uppercase, with side padding.
func _dup_chip() -> PanelContainer:
	var p := PanelContainer.new()
	p.name = "DupChip"
	p.theme = UI3Theme.get_theme()
	p.custom_minimum_size = Vector2(0, 32)
	p.add_theme_stylebox_override("panel", UI3Theme.flat(Color.TRANSPARENT, 4, 2, UI3Theme.color("text_muted"), Vector4(10, 0, 10, 0)))
	var l := _dlabel("DUPLICATE", UI3Theme.color("text"))
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p.add_child(l)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


func _drop_cost_chip(b: Button) -> void:
	for cc in b.find_children("CostChip", "Control", true, false):
		cc.queue_free()


func _refresh_bar() -> void:
	_sync_wallet()
	_clear(_bar_host)
	var tp := _pill()
	tp.name = "TicketsChip"
	var th := HBoxContainer.new()
	th.add_theme_constant_override("separation", 10)
	tp.add_child(th)
	th.add_child(_icon("cur_ticket", 44, "TicketIcon"))
	var t := UI3.label("%d" % tickets(), "LabelScreenTitle")
	t.name = "Tickets"
	if state == "offline" and remote_on:
		t.modulate.a = 0.6   # cached count
	th.add_child(t)
	var tl := UI3.label("tickets", "LabelMuted")
	tl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	th.add_child(tl)
	_bar_host.add_child(tp)
	var per := int(_Econ.get_table("echobox").get("fragments_per_ticket", 10))
	var frags := int(MetaState.echobox_pity.get("fragments", 0))
	var fp := _pill()
	fp.name = "FragmentsChip"
	var fh := HBoxContainer.new()
	fh.add_theme_constant_override("separation", 12)
	fp.add_child(fh)
	fh.add_child(_icon("cur_fragment", 36, "FragmentIcon"))
	fh.add_child(_meter(180, 12, frags, per, UI3Theme.color("tier_crystal"), "Fragments"))
	var fl := _dlabel("%d/%d" % [frags, per], UI3Theme.color("text"))
	fl.name = "FragmentsCount"
	fh.add_child(fl)
	fp.tooltip_text = "%d Fragments = 1 ticket" % per
	_bar_host.add_child(fp)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bar_host.add_child(sp)
	var price := next_price()
	var buy := UI3.button("Buy ticket", &"secondary", &"M")
	buy.name = "BuyTicket"
	var why := ""
	if _account_blocks() or state == "loading":
		why = "Not available right now"
	elif price < 0:
		why = "Daily limit reached (30)"
	elif MetaState.shard_pool < price:
		why = "Not enough Shards"
	if why != "":
		UI3.set_disabled_reason(buy, why)
		buy.tooltip_text = why
	else:
		_cost_in_button(buy, &"shard", price, 96)
	buy.pressed.connect(_on_buy_pressed)
	_bar_host.add_child(buy)


func _on_buy_pressed() -> void:
	var first := EchoBox.ticket_price(1)
	var price := next_price()
	if price > 2 * first:
		open_confirm_buy()
	else:
		buy_ticket()


## Gold (or Mystic) chest on two chest_disc circles (520 / 360) and a floor shadow; idle bob via echo_idle.
func _chest_stage(seasonal: bool) -> Control:
	var host := Control.new()
	host.name = "ChestStage"
	host.custom_minimum_size = Vector2(520, 520)
	host.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var disc := UI3Theme.color("chest_disc")
	for d in [["DiscOuter", 520.0, Vector2(0, 0)], ["DiscInner", 360.0, Vector2(80, 80)]]:
		var p := Panel.new()
		p.name = String(d[0])
		var sb := StyleBoxFlat.new()
		sb.bg_color = disc
		sb.set_corner_radius_all(int(float(d[1]) / 2.0))
		p.add_theme_stylebox_override("panel", sb)
		p.position = d[2]
		p.size = Vector2(float(d[1]), float(d[1]))
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		host.add_child(p)
	var sh := Panel.new()
	sh.name = "FloorShadow"
	var ssb := StyleBoxFlat.new()
	ssb.bg_color = Color(0.043, 0.047, 0.059, 0.4)
	ssb.set_corner_radius_all(12)
	sh.add_theme_stylebox_override("panel", ssb)
	sh.position = Vector2(100, 460)
	sh.size = Vector2(320, 24)
	sh.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(sh)
	var chest := TextureRect.new()
	chest.name = "Chest"
	chest.texture = load("res://assets/echobox/chests/themed/mystic-chest.png" if seasonal else "res://assets/echobox/chests/tiers/chest_gold.png")
	chest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	chest.size = Vector2(360, 360)
	chest.position = Vector2(80, 70)
	chest.pivot_offset = Vector2(180, 340)
	chest.tooltip_text = "Mystic Chest" if seasonal else "Gold Chest"
	host.add_child(chest)
	return host


## echo_idle: first cycle through the motion table, then a smooth ping-pong with the table's numbers.
func _start_idle(chest: Control) -> void:
	if instant or UI3Motion.reduced() or chest == null:
		return
	var m: Dictionary = UI3Motion.table().get("echo_idle", {})
	if m.is_empty():
		return
	var home := chest.position
	var ms_in := float((m["in"] as Dictionary).get("ms", 1200)) / 1000.0
	var ms_out := float((m["out"] as Dictionary).get("ms", 1200)) / 1000.0
	_idle_tw = UI3Motion.play("echo_idle", chest, {"on_done": func() -> void:
		if not is_instance_valid(chest) or not chest.is_inside_tree():
			return
		var tw := chest.create_tween().set_loops()
		_idle_tw = tw
		tw.tween_property(chest, "position", home + Vector2(0, -6), ms_in).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(chest, "position", home + Vector2(0, 6), ms_out).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)})


func _chest_tex(tier: String) -> Texture2D:
	return load("res://assets/echobox/chests/tiers/chest_%s.png" % tier.to_lower()) as Texture2D


func _result_name(r: Dictionary) -> String:
	if String(r.get("kind")) == "stone":
		return "%s Stone" % UI3.fmt(int(r.get("amount", 0)))
	return CosmeticTile.any_name(String(r.get("item", "")))


## What the "Last open" strip shows (every pull sets it; public so captures can).
func set_last_open(r: Dictionary) -> void:
	last_open = r.duplicate()
	if _stage_v != null and not _shell.is_empty():
		_refresh_stage()


func _last_open_strip() -> Control:
	var s := PanelContainer.new()
	s.name = "LastOpen"
	s.theme = UI3Theme.get_theme()
	s.custom_minimum_size = Vector2(0, 80)
	s.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("panel_raised"), 16, 0, Color.TRANSPARENT,
		Vector4(20, 0, 20, 0)))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	s.add_child(h)
	h.add_child(_dlabel("LAST OPEN", UI3Theme.color("text_muted")))
	if last_open.is_empty():
		var none := UI3.label("Nothing yet. Open a box to see it here.", "LabelMuted")
		none.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(none)
		return s
	var ic := TextureRect.new()
	ic.texture = _chest_tex(_chest_tier(last_open))
	ic.custom_minimum_size = Vector2(48, 48)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(ic)
	var nm := _dlabel(_result_name(last_open).left(60), UI3Theme.color("text"))
	nm.name = "LastName"
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	h.add_child(nm)
	var kind := UI3.label(_reward_title(last_open), "LabelMuted")
	kind.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kind.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	h.add_child(kind)
	if bool(last_open.get("duplicate", false)):
		h.add_child(_dup_chip())
		var fr := HBoxContainer.new()
		fr.add_theme_constant_override("separation", 6)
		fr.add_child(_icon("cur_fragment", 24))
		var fv := int(last_open.get("tickets_back", 0)) if last_open.has("season") else int(last_open.get("fragments", 0))
		fr.add_child(_dlabel("+%d" % fv, UI3Theme.color("text")))
		h.add_child(fr)
	return s


func _refresh_stage() -> void:
	# keep the ticket bar (child 0 of StageV), rebuild the rest
	while _stage_v.get_child_count() > 1:
		var c := _stage_v.get_child(1)
		_stage_v.remove_child(c)
		c.queue_free()
	for c in _stage_host.get_children():
		if c.name == "SummaryScroll":
			_stage_host.remove_child(c)
			c.queue_free()
	var seasonal := tab == "seasonal"
	var has_summary := not results.is_empty()
	var plate := _stage_host.get_node("StagePlate") as Control
	plate.size_flags_vertical = Control.SIZE_SHRINK_BEGIN if has_summary else Control.SIZE_EXPAND_FILL
	var cs := _chest_stage(seasonal)
	if has_summary:
		cs.custom_minimum_size = Vector2(520, 0)
		cs.visible = false
	_stage_v.add_child(cs)
	var chest := cs.find_child("Chest", true, false) as Control
	var v := VBoxContainer.new()
	v.name = "StageActions"
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", UI3Theme.space("16"))
	_stage_v.add_child(v)
	if seasonal:
		var l := UI3.label("5 tickets per pull. A small set of rare items. A full set is guaranteed within 80 pulls (400 tickets). Max 8 pulls a day.", "LabelMuted")
		l.name = "SeasonLine"
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 640
		l.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(l)
		var left := UI3.label("Pulls left today  %d / %d" % [season_pulls_left(), season_cap_day()], "LabelTitle")
		left.name = "PullsLeft"
		left.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(left)
		var srow := HBoxContainer.new()
		srow.alignment = BoxContainer.ALIGNMENT_CENTER
		srow.add_theme_constant_override("separation", UI3Theme.space("16"))
		v.add_child(srow)
		var n_big := clampi(season_pulls_left(), 1, PULL_N)
		var ok1 := pull_block_reason(1) == ""
		var okn := n_big > 1 and pull_block_reason(n_big) == ""
		var so: Button
		if ok1 and not okn:
			so = _primary_cost("Open 1", &"ticket", season_cost())
		else:
			so = UI3.button("Open 1", &"secondary", &"M")
			if ok1:
				_cost_in_button(so, &"ticket", season_cost(), 96)
		so.name = "SeasonOpen"
		so.pressed.connect(_on_season_open.bind(1))
		srow.add_child(so)
		if not ok1:
			UI3.set_disabled_reason(so, pull_block_reason(1))
			so.tooltip_text = pull_block_reason(1)
			_drop_cost_chip(so)
		if n_big > 1:
			var sn: Button
			if okn:
				sn = _primary_cost("Open %d" % n_big, &"ticket", season_cost() * n_big)
			else:
				sn = UI3.button("Open %d" % n_big, &"secondary", &"M")
			sn.name = "SeasonOpenN"
			sn.pressed.connect(_on_season_open.bind(n_big))
			srow.add_child(sn)
			if not okn:
				UI3.set_disabled_reason(sn, pull_block_reason(n_big))
				sn.tooltip_text = pull_block_reason(n_big)
				_drop_cost_chip(sn)
		var srt := UI3.button("Rates", &"quiet", &"S")
		srt.name = "Rates"
		srt.pressed.connect(open_rates)
		srow.add_child(srt)
	else:
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", UI3Theme.space("16"))
		v.add_child(row)
		var n_big := PULL_N
		# One primary: Open 10 when usable, else Open 1 when usable.
		var n_ok := pull_block_reason(n_big) == ""
		var one_ok := pull_block_reason(1) == ""
		var o1: Button
		if one_ok and not n_ok:
			o1 = _primary_cost("Open 1", &"ticket", 1)
		else:
			o1 = UI3.button("Open 1", &"secondary", &"M")
			if one_ok:
				_cost_in_button(o1, &"ticket", 1, 96)
		o1.name = "Open1"
		o1.pressed.connect(func() -> void: pull(1))
		var on: Button
		if n_ok:
			on = _primary_cost("Open %d" % n_big, &"ticket", n_big)
		else:
			on = UI3.button("Open %d" % n_big, &"secondary", &"M")
		on.name = "OpenN"
		on.pressed.connect(_on_open_many.bind(n_big))
		for b in [o1, on]:
			var why := pull_block_reason(1 if b == o1 else n_big)
			if why != "":
				UI3.set_disabled_reason(b, why)   # a disabled button says why
				b.tooltip_text = why
				_drop_cost_chip(b)
		row.add_child(o1)
		row.add_child(on)
		if pull_block_reason(1).begins_with("Not enough") and not _account_blocks():
			var bt := _bar_host.find_child("BuyTicket", true, false) as Control
			if bt != null:
				_focus_later(bt)
	if not has_summary:
		var fill := Control.new()
		fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_stage_v.add_child(fill)
	_stage_v.add_child(_last_open_strip())
	if has_summary:
		# the result list takes the room: the summary scrolls instead of overflowing
		var sc := UI3Meta.scroll(_build_summary())
		sc.name = "SummaryScroll"
		_stage_host.add_child(sc)
	elif chest != null:
		_start_idle(chest)


## Button text for a normal pull; the ticket cost is a chip inside the button.
static func open_label(n: int) -> String:
	return "Open %d" % n


## Spending several tickets in one press asks first (S3-16); the dialog says what it costs and what is left.
func _on_open_many(n: int) -> void:
	if _modal_layer.get_child_count() > 0:
		return
	var no := UI3.button("Cancel", &"secondary", &"M")
	no.name = "CancelOpenN"
	no.pressed.connect(close_modal)
	var yes := UI3.button(open_label(n), &"primary", &"M")
	yes.name = "ConfirmOpenN"
	yes.pressed.connect(func() -> void:
		close_modal()
		pull(n))
	var m := UI3.modal("Open %d boxes?" % n, "This spends %d tickets and leaves you %d." % [n, tickets() - n], [no, yes], 1)
	m.cancelled.connect(close_modal)
	_modal_layer.add_child(m)


## First season pull of the session confirms (tickets spent / left, pulls left); later ones go straight through.
func _on_season_open(n: int) -> void:
	if season_confirmed:
		pull(n)
		return
	var no := UI3.button("Cancel", &"secondary", &"M")
	no.name = "Cancel"
	no.pressed.connect(close_modal)
	var yes := UI3.button("Open", &"primary", &"M")
	yes.name = "ConfirmSeason"
	yes.pressed.connect(func() -> void:
		season_confirmed = true
		close_modal()
		pull(n))
	var cost := n * season_cost()
	var m := UI3.modal("Open the season box?", "This spends %d tickets and leaves you %d. Pulls left today after this: %d of %d." % [
		cost, tickets() - cost, season_pulls_left() - n, season_cap_day()], [no, yes], 1)
	m.cancelled.connect(close_modal)
	_modal_layer.add_child(m)


func _pity_text() -> String:
	var parts: Array[String] = []
	for s in (box_cfg().get("pity", {}) as Dictionary).get("steps", []):
		parts.append("%s every %d cosmetic pulls" % [String(s["min_rarity"]).capitalize(), int(s["pulls"])])
	return "Guaranteed minimum: " + " · ".join(parts)


func _refresh_side() -> void:
	_clear(_side_host)
	if tab == "seasonal":
		_refresh_side_season()
		return
	var pity := UI3.plate(&"plate")
	pity.name = "PityPanel"
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	pity.add_child(v)
	var th := HBoxContainer.new()
	th.add_theme_constant_override("separation", 10)
	th.add_child(UI3.label("Pity", "LabelTitle"))
	var sub := UI3.label("cosmetic pulls only", "LabelMuted")
	sub.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	th.add_child(sub)
	var rt := UI3.button("Rates", &"quiet", &"S")
	rt.name = "Rates"
	rt.pressed.connect(open_rates)
	th.add_child(rt)
	v.add_child(th)
	for s in (box_cfg().get("pity", {}) as Dictionary).get("steps", []):
		var rar := String(s["min_rarity"])
		var need := int(s["pulls"])
		var have := mini(int(MetaState.echobox_pity.get("since_" + rar, 0)), need)
		var r := VBoxContainer.new()
		r.add_theme_constant_override("separation", 6)
		var top := HBoxContainer.new()
		var nm := _dlabel(rar.capitalize(), _rarity_text(rar))
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top.add_child(nm)
		top.add_child(UI3.label("%d/%d" % [have, need], "LabelMuted"))
		r.add_child(top)
		var pb := _meter(120, 10, have, need, _rarity_color(rar), "Pity_" + rar)
		pb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(pb)
		v.add_child(r)
	var ph := UI3.label("Each bar fills toward a guaranteed rarity.", "LabelMuted")
	ph.name = "PityHelp"
	ph.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(ph)
	_side_host.add_child(pity)
	var pool := UI3.plate(&"plate")
	pool.name = "PoolPanel"
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 14)
	pool.add_child(pv)
	var total := 0
	var grid := GridContainer.new()
	grid.name = "PoolGrid"
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", UI3Theme.space("8"))
	grid.add_theme_constant_override("v_separation", UI3Theme.space("8"))
	var ph2 := HBoxContainer.new()
	ph2.add_child(UI3.label("Pool", "LabelTitle"))
	var cnt_l := UI3.label("", "LabelMuted")
	cnt_l.name = "PoolCount"
	cnt_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cnt_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ph2.add_child(cnt_l)
	pv.add_child(ph2)
	pv.add_child(grid)
	for rar in EchoBox.RARITIES:
		var spec: Dictionary = (box_cfg().get("pool", {}) as Dictionary).get(rar, {})
		var c := int(spec.get("count", 0))
		total += c
		var ids := EchoBox.pool_ids(box_cfg(), rar)
		var own := 0
		for id in ids:
			if MetaState.cosmetics_owned.has(id):
				own += 1
		var tile := UI3.plate(&"row")
		tile.name = "Pool_" + rar
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var tsb := UI3Theme.flat(UI3Theme.color("panel_raised"), 12, 0, Color.TRANSPARENT, Vector4(8, 10, 8, 10))
		tsb.border_width_top = 4
		tsb.border_color = _rarity_color(String(rar))
		tile.add_theme_stylebox_override("panel", tsb)
		var tv := VBoxContainer.new()
		tv.alignment = BoxContainer.ALIGNMENT_CENTER
		tv.add_theme_constant_override("separation", 2)
		var ti := TextureRect.new()
		ti.name = "PoolChest"
		ti.texture = _chest_tex(String(CHEST_BY_RARITY.get(String(rar), "Bronze")))
		ti.custom_minimum_size = Vector2(40, 40)
		ti.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ti.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ti.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		tv.add_child(ti)
		var tn := _dlabel(String(rar).capitalize(), _rarity_text(String(rar)))
		tn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tv.add_child(tn)
		var tc := UI3.label("%d/%d" % [own, c], "LabelMuted")
		tc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tv.add_child(tc)
		tile.add_child(tv)
		grid.add_child(tile)
	cnt_l.text = "%d cosmetics" % total
	var dup := UI3.label("A duplicate becomes Fragments; 10 Fragments = 1 ticket. Never Shards.", "LabelMuted")
	dup.name = "DupLine"
	dup.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pv.add_child(dup)
	_side_host.add_child(pool)


func _season_names() -> Dictionary:
	return EchoBox.season_cfg().get("titles", {})


func _refresh_side_season() -> void:
	var cfg := EchoBox.season_cfg()
	var st := EchoBox.season_state(MetaState)
	var owned: Array = st["owned"]
	var items: Dictionary = cfg.get("items", {})
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UI3Theme.space("16"))
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# progress per tier
	var pp := UI3.plate(&"plate")
	pp.name = "SeasonProgress"
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", UI3Theme.space("8"))
	pp.add_child(pv)
	var total_have := 0
	var total := 0
	for t in ["mythic", "legendary", "epic"]:
		total += (items.get(t, []) as Array).size()
	total_have = owned.size()
	pv.add_child(UI3.label("Lunar Echo · %d / %d · pulls opened %d" % [total_have, total, int(st["opens"])], "LabelTitle"))
	for t in ["mythic", "legendary", "epic"]:
		var cap := _season_cap(t)
		var have := 0
		for it in items.get(t, []):
			if owned.has(it):
				have += 1
		var n_t := (items.get(t, []) as Array).size()
		var c := int(st["c_" + t])
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", UI3Theme.space("8"))
		var nm := UI3.label(t.capitalize())
		nm.custom_minimum_size = Vector2(110, 0)
		r.add_child(nm)
		var pb := ProgressBar.new()
		pb.name = "Season_" + t
		pb.theme = UI3Theme.get_theme()
		pb.custom_minimum_size = Vector2(120, 16)
		pb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pb.max_value = cap
		pb.value = mini(c, cap) if have < n_t else cap
		pb.show_percentage = false
		pb.add_theme_stylebox_override("fill", UI3Theme.flat(_rarity_color(t), UI3Theme.radius("s")))
		r.add_child(pb)
		r.add_child(UI3.label("%d/%d" % [have, n_t], "LabelMuted"))
		pv.add_child(r)
		var chance := UI3.label("%s: pull %d of %d, %s" % [
			"Set done" if have >= n_t else "Next pull", c + 1, cap,
			"dup tickets back" if have >= n_t else ("%.1f%% (certain at %d)" % [EchoBox.season_hit_prob(c + 1, cap, float(cfg.get("escalation_k", 2))) * 100.0, cap])], "LabelMuted")
		chance.name = "Chance_" + t
		chance.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		pv.add_child(chance)
	col.add_child(pp)
	# milestones
	var mp := UI3.plate(&"plate")
	mp.name = "SeasonMilestones"
	var mv := VBoxContainer.new()
	mv.add_theme_constant_override("separation", UI3Theme.space("8"))
	mp.add_child(mv)
	mv.add_child(UI3.label("Milestones", "LabelTitle"))
	var done: Array = st["milestones"]
	for m in cfg.get("milestones", []):
		var md: Dictionary = m
		var rw := String(md.get("reward", ""))
		var parts: Array[String] = []
		parts.append(_reward_name(rw))
		if String(md.get("also", "")) != "":
			parts.append(_reward_name(String(md["also"])))
		var got := done.has("m%d" % int(md.get("opens", 0)))
		var row := UI3.label("%s %d pulls: %s" % ["Done" if got else "At", int(md.get("opens", 0)), " + ".join(parts)])
		row.name = "Milestone_%d" % int(md.get("opens", 0))
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if got:
			row.add_theme_color_override("font_color", UI3Theme.color("text_muted"))
		mv.add_child(row)
	var crow := UI3.label("%s Full set: %s" % ["Done" if done.has("complete") else "At", _reward_name(String(cfg.get("complete_reward", "")))])
	crow.name = "Milestone_complete"
	crow.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mv.add_child(crow)
	col.add_child(mp)
	# the 11-item pool grid
	var pool := UI3.plate(&"plate")
	pool.name = "SeasonPool"
	var gv := VBoxContainer.new()
	gv.add_theme_constant_override("separation", UI3Theme.space("8"))
	pool.add_child(gv)
	gv.add_child(UI3.label("Series items", "LabelTitle"))
	var grid := GridContainer.new()
	grid.name = "SeasonGrid"
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", UI3Theme.space("8"))
	grid.add_theme_constant_override("v_separation", UI3Theme.space("8"))
	gv.add_child(grid)
	for t in ["mythic", "legendary", "epic"]:
		for it in items.get(t, []):
			grid.add_child(_season_tile(String(it), t, owned.has(it)))
	col.add_child(pool)
	var dup := UI3.label("Once a tier is complete, a duplicate gives tickets back. Never Shards.", "LabelMuted")
	dup.name = "DupLine"
	dup.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(dup)
	var sc := UI3Meta.scroll(col)
	sc.name = "SideScroll"
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_side_host.add_child(sc)


func _reward_name(id: String) -> String:
	var t: Dictionary = _season_names()
	if t.has(id):
		return TitleNames.display(TitleNames.PREFIX + String(t[id]))
	var n := CosmeticTile.any_name(id)
	return n if n != "" else id


func _season_tile(item: String, tier: String, have: bool) -> Control:
	var tile := UI3.plate(&"row")
	tile.name = "Item_" + item
	tile.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("panel"), UI3Theme.radius("m"), 3,
		_rarity_color(tier), Vector4(4, 4, 4, 4)))
	tile.tooltip_text = "%s (%s)%s" % [_reward_name(item), tier.capitalize(), "" if have else " - not yet found"]
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	tile.add_child(v)
	var art := _cosmetic_art(item, 64.0, false)
	if art == null:
		art = _fx_badge(64.0)
	v.add_child(art)
	var nm := UI3.label(_reward_name(item) if have else "?")
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nm.custom_minimum_size.x = 80
	nm.clip_text = true
	v.add_child(nm)
	if not have:
		art.modulate = Color(0.1, 0.1, 0.12, 0.9)   # named silhouette, nothing hidden
		tile.modulate.a = 0.8
	return tile


## Dice FX have no baked art: a plain labelled badge so the slot is never empty.
func _fx_badge(px: float) -> Control:
	var c := CenterContainer.new()
	c.name = "Art"
	c.custom_minimum_size = Vector2(px, px)
	c.size = Vector2(px, px)
	c.add_child(UI3.label("FX", "LabelTitle"))
	return c


func _build_summary() -> Control:
	var p := UI3.plate(&"plate")
	p.name = "Summary"
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI3Theme.space("8"))
	p.add_child(v)
	var stone := 0
	var new_n := 0
	var dup_n := 0
	for r in results:
		if String(r.get("kind")) == "stone":
			stone += int(r.get("amount", 0))
		elif bool(r.get("duplicate", false)):
			dup_n += 1
		else:
			new_n += 1
	v.add_child(UI3.label("%s · %d Stone · %d new · %d %s" % [
		"Last pull" if state == "last_pull" else "Result", stone, new_n, dup_n, "duplicate" if dup_n == 1 else "duplicates"], "LabelTitle"))
	if error_text.begins_with("Opened "):
		var pl := UI3.label(error_text, "LabelMuted")
		pl.name = "PartialPull"
		v.add_child(pl)
	var ms: Array[String] = _milestone_lines(results)
	if not ms.is_empty():
		var mr := HBoxContainer.new()
		mr.name = "MilestoneLine"
		mr.add_theme_constant_override("separation", UI3Theme.space("8"))
		for t in ms:
			mr.add_child(UI3.chip(t))
		v.add_child(mr)
	var grid := GridContainer.new()
	grid.name = "ResultGrid"
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", UI3Theme.space("8"))
	grid.add_theme_constant_override("v_separation", UI3Theme.space("8"))
	v.add_child(grid)
	for r in results:
		grid.add_child(_result_cell(r, "summary"))
	return p


## Milestones / full-set reached by the pulls in `results` (season only).
func _milestone_lines(list: Array) -> Array[String]:
	var out: Array[String] = []
	var cfg := EchoBox.season_cfg()
	for r in list:
		for id in r.get("milestones", []):
			out.append("Milestone: %s" % _reward_name(String(id)))
		if bool(r.get("complete", false)):
			out.append("Set complete: %s" % _reward_name(String(cfg.get("complete_reward", ""))))
	return out


func _reward_title(r: Dictionary) -> String:
	if String(r.get("kind")) == "stone":
		return "%d Stone" % int(r.get("amount", 0))
	return "%s cosmetic" % String(r.get("rarity", "")).capitalize()


func _chest_tier(r: Dictionary) -> String:
	if String(r.get("kind")) == "stone":
		return String(STONE_CHEST.get(int(r.get("amount", 0)), "Bronze"))
	return String(CHEST_BY_RARITY.get(String(r.get("rarity", "common")), "Bronze"))


func _rarity_idx(r: Dictionary) -> int:
	return EchoBox.RARITIES.find(String(r.get("rarity", ""))) if String(r.get("kind")) != "stone" else 0


func _result_cell(r: Dictionary, mode := "summary") -> Control:
	if mode != "summary":
		return _reveal_card(r, mode == "single")
	var rar := "common" if String(r.get("kind")) == "stone" else String(r.get("rarity", "common"))
	var c := UI3.plate(&"card")
	c.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("panel"), UI3Theme.radius("m"), 3,
		_rarity_color(rar), Vector4(12, 12, 12, 12)))
	c.custom_minimum_size = Vector2(128, 150)
	var v := VBoxContainer.new()
	c.add_child(v)
	var art: Control = null
	if String(r.get("kind")) == "cosmetic":
		art = _cosmetic_art(String(r.get("item", "")), 72.0, false)
	elif String(r.get("kind")) == "stone":
		var ic := TextureRect.new()
		ic.name = "StoneIcon"
		ic.texture = UI3.currency_icon("cur_stone", 72.0)
		ic.custom_minimum_size = Vector2(72, 72)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art = ic
	if art != null:
		c.custom_minimum_size = Vector2(128, 230)
		v.add_child(art)
		if String(r.get("kind")) == "cosmetic":
			var nm: Label = UI3.label(CosmeticTile.display_name(String(r.get("item", ""))))
			nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			v.add_child(nm)
	v.add_child(UI3.label(_reward_title(r), "LabelTitle"))
	var tag := "Stone"
	if String(r.get("kind")) != "stone":
		tag = ("Duplicate +%d frag" % int(r.get("fragments", 0))) if bool(r.get("duplicate", false)) else "NEW"
	v.add_child(UI3.label(tag, "LabelMuted"))
	v.add_child(UI3.label(_chest_tier(r) + " chest", "LabelMuted"))
	return c


## Reveal card (20-echo-box): one shape for every result. 300 x 380 in the 10-grid, 480 x 660 for a single pull.
## Dice skin: the baked thumbnail (grid) or a live 3D die that drops in (single); frame on the player's avatar;
## duplicate: the item's art plus a Fragment badge; Stone: the painted stone pile.
func _reveal_card(r: Dictionary, single: bool) -> Control:
	var kind := String(r.get("kind"))
	var stone := kind == "stone"
	var rar := "common" if stone else String(r.get("rarity", "common"))
	var tier := 0 if stone else maxi(EchoBox.RARITIES.find(rar), 0)
	var dup := bool(r.get("duplicate", false))
	var art_px := 416.0 if single else 260.0
	var card := PanelContainer.new()
	card.name = "RevealCard"
	card.custom_minimum_size = Vector2(CARD_W_1 if single else CARD_W, CARD_H_1 if single else CARD_H_10)
	var epic_plus := not stone and tier >= 3
	var glow := DiceSkin.tier_color(tier)
	glow.a = 0.33
	card.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("panel"), UI3Theme.radius("m"),
		3 if epic_plus else 0, DiceSkin.tier_color(tier), Vector4(20, 20, 20, 20),
		{"y": 0, "color": glow, "size": 40} if epic_plus else {}))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	card.add_child(v)
	var strip := ColorRect.new()
	strip.name = "TierStrip"
	strip.custom_minimum_size = Vector2(0, 8 if single else 4)
	strip.color = UI3Theme.color("panel_raised") if stone else DiceSkin.tier_color(tier)
	v.add_child(strip)
	var art := Panel.new()
	art.name = "CardArt"
	art.custom_minimum_size = Vector2(art_px, art_px)
	art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	art.clip_contents = true
	art.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("panel_raised"), UI3Theme.radius("s")))
	v.add_child(art)
	var title := ""
	var line := ""
	var line_col := DiceSkin.tier_text_color(tier)
	if stone:
		var ic := TextureRect.new()
		ic.name = "StoneIcon"
		ic.texture = UI3.icon("cur_stone_reveal")
		var sp := 256.0 if single else 160.0
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.custom_minimum_size = Vector2(sp, sp)
		ic.size = Vector2(sp, sp)
		ic.position = (Vector2(art_px, art_px) - Vector2(sp, sp)) * 0.5
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.add_child(ic)
		title = "%d Stone" % int(r.get("amount", 0))
		line = "Currency"
		line_col = UI3Theme.color("text_muted")
	else:
		var item := String(r.get("item", ""))
		var a := _cosmetic_art(item, art_px, single)
		if a == null:
			a = _fx_badge(art_px)
		art.add_child(a)
		title = CosmeticTile.any_name(item)
		var slot_word := "dice skin" if Cosmetics.slot_of(item) == Cosmetics.SLOT_DIE else ("frame" if Cosmetics.slot_of(item) == Cosmetics.SLOT_FRAME else "dice FX")
		line = "%s %s" % [rar.capitalize(), slot_word]
		if dup:
			line = ("Duplicate · +%d tickets" % int(r.get("tickets_back", 0))) if r.has("season") \
				else "Duplicate · %d Fragments" % int(r.get("fragments", 0))
			line_col = UI3Theme.color("text")
			var badge := HBoxContainer.new()
			badge.name = "DupBadge"
			badge.add_theme_constant_override("separation", 4)
			badge.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
			badge.grow_horizontal = Control.GROW_DIRECTION_BEGIN
			badge.grow_vertical = Control.GROW_DIRECTION_BEGIN
			badge.position = Vector2(art_px - 8.0, art_px - 8.0)
			var fi := TextureRect.new()
			fi.texture = UI3.currency_icon("cur_fragment", 36.0)
			fi.custom_minimum_size = Vector2(36, 36)
			fi.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			fi.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			badge.add_child(fi)
			var bl := UI3.label("+%d" % (int(r.get("tickets_back", 0)) if r.has("season") else int(r.get("fragments", 0))), "LabelDisplay")
			bl.add_theme_font_size_override("font_size", 20)
			badge.add_child(bl)
			art.add_child(badge)
		else:
			var chip := UI3.chip("New")
			chip.name = "NewChip"
			chip.position = Vector2(8, 8)
			art.add_child(chip)
	var nm := UI3.label(title, "LabelScreenTitle" if single else "LabelTitle")
	nm.name = "CardName"
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nm.custom_minimum_size.x = art_px
	if not single and title.length() > 18:
		nm.add_theme_font_size_override("font_size", 20)   # shrink to 20, then ellipsis
	v.add_child(nm)
	var ln := UI3.label(line.left(26))
	ln.name = "CardLine"
	ln.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ln.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	ln.custom_minimum_size.x = art_px
	ln.add_theme_color_override("font_color", line_col)
	v.add_child(ln)
	return card


## Art of a cosmetic inside a `px` square box. Dice: baked thumbnail, or (live) the 3D die dropping in; frames:
## the player's initial on a disc wearing the frame. null when the id has no art.
func _cosmetic_art(item: String, px: float, live: bool) -> Control:
	var a := Cosmetics.art_id(item)
	var slot := Cosmetics.slot_of(a)
	if slot == Cosmetics.SLOT_DIE:
		var tr := TextureRect.new()
		tr.name = "Art"
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.custom_minimum_size = Vector2(px, px)
		tr.size = Vector2(px, px)
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_load_thumb(tr, a, live, px)
		return tr
	if slot == Cosmetics.SLOT_FRAME:
		var letter := "P"
		if AccountService.is_signed_in():
			letter = AccountService.display_name()
		var cell := CenterContainer.new()
		cell.name = "Art"
		cell.custom_minimum_size = Vector2(px, px)
		cell.size = Vector2(px, px)
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(AvatarFrame.letter_preview(a, px * (224.0 / 260.0) / AvatarFrame.SCALE, letter))
		return cell
	return null


func _load_thumb(tr: TextureRect, id: String, live: bool, px: float) -> void:
	# Until the baked thumbnail is ready (or if it never is) the square shows the item name, not a blank.
	var fb := UI3.label(CosmeticTile.any_name(id), "LabelTitle")
	fb.name = "ThumbFallback"
	fb.set_anchors_preset(Control.PRESET_FULL_RECT)
	fb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.add_child(fb)
	var tex: Texture2D = DiceThumb.cached_texture(id)
	if tex == null:
		tex = await DiceThumb.get_thumb(self, id)
	if is_instance_valid(tr) and tex != null:
		tr.texture = tex
		fb.queue_free()
	if not live or DisplayServer.get_name() == "headless" or not is_instance_valid(tr):
		return
	var faces := DiceStage.preview_faces()
	var roller := DiceRoller3D.new()
	add_child(roller)
	await roller.prepare(faces, id)
	roller.queue_free()
	if not is_instance_valid(tr) or not tr.is_inside_tree():
		return
	var st := DiceStage.new()
	st.name = "DiceStage"
	st.setup(Vector2i(int(px), int(px)), id, faces, true)
	st.mouse_filter = Control.MOUSE_FILTER_STOP
	tr.add_child(st)
	tr.texture = null
	st.play_drop()
	st.gui_input.connect(func(ev: InputEvent) -> void:   # click the card to replay the drop
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed and is_instance_valid(st):
			st.play_drop())


func _build_skeleton() -> void:
	var sk := VBoxContainer.new()
	sk.name = "Skeleton"
	sk.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sk.add_child(UI3.skeleton_row(360))
	_col.add_child(sk)


# ---------------------------------------------------------------- ceremony

## Open: chest animation on the stage (echo_open / echo_open10), then the reveal dialog. Skip (Space) is live
## from the first frame. Reduce motion / instant: no animation, dialog straight away.
func _play_ceremony(out: Array) -> void:
	_skip = instant
	var top := out[0] as Dictionary
	for r in out:
		if _rarity_idx(r) > _rarity_idx(top):
			top = r
	set_last_open(out[out.size() - 1] if out.size() == 1 else top)
	var single := out.size() == 1
	var chest := find_child("Chest", true, false) as TextureRect
	if chest != null and chest.is_inside_tree() and not _skip and not UI3Motion.reduced():
		_opening = true
		if _idle_tw != null and _idle_tw.is_valid():
			_idle_tw.kill()   # the idle bob
		chest.position = Vector2(80, 70)
		var tier_tex := _chest_tex(_chest_tier(top))
		var swap := get_tree().create_timer(0.3)
		swap.timeout.connect(func() -> void:
			if is_instance_valid(chest) and tier_tex != null:
				chest.texture = tier_tex)
		var tw := UI3Motion.play("echo_open" if single else "echo_open10", chest, {"skip": false})
		if tw == null:
			tw = UI3Motion.play("echo_open", chest, {})
		var t0 := Time.get_ticks_msec()
		while tw != null and tw.is_valid() and tw.is_running() and not _skip and is_inside_tree() \
				and Time.get_ticks_msec() - t0 < 2500:
			await get_tree().process_frame
		if tw != null and tw.is_valid():
			tw.kill()
		if is_instance_valid(chest):
			chest.scale = Vector2.ONE
			chest.position = Vector2(80, 70)
			if tier_tex != null:
				chest.texture = tier_tex
		_opening = false
		if is_inside_tree() and not _skip and not reduce_flashing and not MetaState.reduce_flash and _rarity_idx(top) >= 2 \
				and String(top.get("kind")) != "stone":
			var hold := get_tree().create_timer(0.6 if _rarity_idx(top) < 5 else 0.9)
			while hold.time_left > 0.0 and not _skip and is_inside_tree():
				await get_tree().process_frame
	_refresh_bar()
	_refresh_side()
	var m := _modal("Reveal" if single else "Open %d" % out.size(), 720 if single else 1760)
	m.name = "Ceremony"
	var card := m.find_child("Card", true, false) as Control
	var v: VBoxContainer = m.find_child("V", true, false)
	var title := v.get_child(0) as Label
	var first := out[0] as Dictionary
	var order: Array = range(out.size())
	var cards: Array = []
	if single:
		title.queue_free()
		_single_reveal(v, first)
	else:
		(v.get_child(0) as Label).text = "Open %d" % out.size()
		order.sort_custom(func(x: int, y: int) -> bool: return _rarity_idx(out[x]) < _rarity_idx(out[y]))   # best last
		var grid := GridContainer.new()
		grid.name = "RevealGrid"
		grid.columns = 5
		grid.add_theme_constant_override("h_separation", 24)
		grid.add_theme_constant_override("v_separation", 24)
		cards.resize(out.size())
		for i in out.size():
			var cd := _result_cell(out[i], "grid")
			cards[i] = cd
			grid.add_child(cd)
		var gc := CenterContainer.new()
		gc.add_child(grid)
		v.add_child(gc)
	var mls: Array[String] = _milestone_lines(out)
	if not mls.is_empty():
		var mrow := HBoxContainer.new()
		mrow.name = "RevealMilestones"
		mrow.alignment = BoxContainer.ALIGNMENT_CENTER
		mrow.add_theme_constant_override("separation", UI3Theme.space("8"))
		for t in mls:
			mrow.add_child(UI3.chip(t))
		v.add_child(mrow)
	var btns := HBoxContainer.new()
	btns.name = "RevealButtons"
	btns.add_theme_constant_override("separation", UI3Theme.space("16"))
	v.add_child(btns)
	if single and String(first.get("kind")) == "cosmetic" and Cosmetics.art_id(String(first.get("item", ""))) != "":
		var art_id := Cosmetics.art_id(String(first.get("item", "")))
		var is_eq := MetaState.equipped_die_skin == art_id or MetaState.equipped_frame == art_id
		if not (bool(first.get("duplicate", false)) and is_eq):   # accepted rule: hidden on an already-equipped duplicate
			var eqb := UI3.button("Equip now", &"quiet", &"M")
			eqb.name = "EquipNow"
			eqb.pressed.connect(func() -> void:
				var why := MetaState.equip_cosmetic(art_id)
				eqb.text = "Equipped" if why == "" else "Couldn't equip"
				eqb.disabled = true)
			btns.add_child(eqb)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btns.add_child(sp)
	var done := UI3.button("Done", &"secondary", &"M")
	done.name = "Done"
	done.pressed.connect(func() -> void:
		close_modal()
		_refresh_all())
	btns.add_child(done)
	var again_n := out.size()
	var ar := pull_block_reason(again_n)
	var again_label := "Open again" if single else "Open %d again" % again_n
	var again: Button
	if ar == "":
		again = _primary_cost(again_label, &"ticket", again_n * (season_cost() if tab == "seasonal" else 1))
	else:
		again = UI3.button(again_label, &"primary", &"L")
		UI3.set_disabled_reason(again, ar)
	again.name = "OpenAgain"
	again.pressed.connect(func() -> void:
		close_modal()
		pull(again_n))
	btns.add_child(again)
	if not (instant or reduce_flashing or MetaState.reduce_flash or UI3Motion.reduced() or DisplayServer.get_name() == "headless"):
		if single:
			card.modulate.a = 0.0
			create_tween().tween_property(card, "modulate:a", 1.0, 0.3)
		else:
			_flip_in(cards, order)
	_focus_later(done)
	if not instant and DisplayServer.get_name() != "headless":
		_play_reveal_moments(v, first, single)


## Single reveal body (M3b): rarity band, art 280, name, DUPLICATE row with Fragments meter.
func _single_reveal(v: VBoxContainer, r: Dictionary) -> void:
	v.alignment = BoxContainer.ALIGNMENT_BEGIN
	v.add_theme_constant_override("separation", 20)
	var stone := String(r.get("kind")) == "stone"
	var rar := "common" if stone else String(r.get("rarity", "common"))
	var dup := bool(r.get("duplicate", false))
	var rc := _rarity_color(rar)
	var band := PanelContainer.new()
	band.name = "RarityBand"
	band.theme = UI3Theme.get_theme()
	band.custom_minimum_size = Vector2(0, 48)
	band.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("panel").lerp(rc, 0.22), 12, 2, rc, Vector4(12, 0, 12, 0)))
	var bh := HBoxContainer.new()
	bh.alignment = BoxContainer.ALIGNMENT_CENTER
	bh.add_theme_constant_override("separation", 10)
	band.add_child(bh)
	var bi := TextureRect.new()
	bi.texture = _chest_tex(_chest_tier(r))
	bi.custom_minimum_size = Vector2(32, 32)
	bi.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bi.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bi.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bh.add_child(bi)
	var bw := _dlabel("STONE" if stone else rar.to_upper(), _rarity_text(rar))
	bw.add_theme_constant_override("outline_size", 0)
	bh.add_child(bw)
	v.add_child(band)
	var art_box := Panel.new()
	art_box.name = "CardArt"
	art_box.custom_minimum_size = Vector2(280, 280)
	art_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	art_box.clip_contents = true
	art_box.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("panel_raised"), 24))
	v.add_child(art_box)
	if stone:
		var ic := TextureRect.new()
		ic.name = "StoneIcon"
		ic.texture = UI3.icon("cur_stone_reveal")
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.size = Vector2(200, 200)
		ic.position = Vector2(40, 40)
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art_box.add_child(ic)
	else:
		var item := String(r.get("item", ""))
		var a := _cosmetic_art(item, 240.0, not dup)
		if a == null:
			a = _fx_badge(240.0)
		a.position = Vector2(20, 20)
		art_box.add_child(a)
	var nb := VBoxContainer.new()
	nb.alignment = BoxContainer.ALIGNMENT_CENTER
	nb.add_theme_constant_override("separation", 4)
	var title := _result_name(r)
	var nm := UI3.label(title, "LabelScreenTitle")
	nm.name = "CardName"
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nm.custom_minimum_size.x = 640
	if title.length() > 20:
		nm.add_theme_font_size_override("font_size", 24)   # shrink to 24, then ellipsis
	nb.add_child(nm)
	var line := "Currency"
	if not stone:
		var slot_word := "dice skin" if Cosmetics.slot_of(String(r.get("item", ""))) == Cosmetics.SLOT_DIE else \
			("frame" if Cosmetics.slot_of(String(r.get("item", ""))) == Cosmetics.SLOT_FRAME else "dice FX")
		line = "%s %s" % [rar.capitalize(), slot_word]
	var ln := UI3.label(line, "LabelMuted")
	ln.name = "CardLine"
	ln.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nb.add_child(ln)
	v.add_child(nb)
	if dup:
		var season := r.has("season")
		var gain := int(r.get("tickets_back", 0)) if season else int(r.get("fragments", 0))
		var row := PanelContainer.new()
		row.name = "DupRow"
		row.theme = UI3Theme.get_theme()
		row.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("panel_raised"), 16, 0, Color.TRANSPARENT, Vector4(20, 16, 20, 16)))
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 16)
		row.add_child(h)
		var chip := _dup_chip()
		chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(chip)
		h.add_child(_icon("cur_ticket" if season else "cur_fragment", 32))
		var gl := UI3.label("+%d %s" % [gain, "tickets" if season else "Fragments"], "LabelTitle")
		gl.name = "DupGain"
		h.add_child(gl)
		if not season:
			var per := int(_Econ.get_table("echobox").get("fragments_per_ticket", 10))
			var now := int(MetaState.echobox_pity.get("fragments", 0))
			var from_v := maxi(now - gain, 0)
			var mt := _meter(0, 12, now, per, UI3Theme.color("tier_crystal"), "DupMeter")
			mt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			mt.set_meta("from", from_v)
			h.add_child(mt)
			var cl := _dlabel("%d/%d" % [now, per], UI3Theme.color("text"))
			cl.name = "DupMeterCount"
			h.add_child(cl)
		v.add_child(row)
	else:
		var nc := UI3.chip("New")
		nc.name = "NewChip"
		nc.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		if not stone:
			v.add_child(nc)
			v.move_child(nc, v.get_child_count() - 1)
		else:
			nc.queue_free()


## echo_rare on the band (Rare+), echo_dupe on the DUPLICATE chip with the meter counting up.
func _play_reveal_moments(v: Control, r: Dictionary, single: bool) -> void:
	if not single:
		return
	var band := v.find_child("RarityBand", true, false) as CanvasItem
	if band != null and String(r.get("kind")) != "stone" and _rarity_idx(r) >= 2:
		UI3Motion.play("echo_rare", band, {})
	var chip := v.find_child("DupChip", true, false) as Control
	if chip != null:
		chip.pivot_offset = chip.size / 2.0
		UI3Motion.play("echo_dupe", chip, {})
		var mt := v.find_child("DupMeter", true, false) as ProgressBar
		if mt != null and mt.has_meta("from"):
			var to_v := mt.value
			mt.value = float(mt.get_meta("from"))
			if not UI3Motion.reduced():
				var tw := mt.create_tween()
				tw.tween_interval(0.2)
				tw.tween_property(mt, "value", to_v, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			else:
				mt.value = to_v


## Cards flip in (scale x 0 -> 1, 160 ms) 120 ms apart, the highest tier last. Reduce flashing: all at once.
func _flip_in(cards: Array, order: Array) -> void:
	for c in cards:
		(c as Control).scale.x = 0.0
	for k in order.size():
		var c := cards[int(order[k])] as Control
		var tw := create_tween()
		tw.tween_interval(FLIP_GAP * k)
		tw.tween_callback(func() -> void: c.pivot_offset = c.size / 2.0)
		tw.tween_property(c, "scale:x", 1.0, FLIP_S).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
