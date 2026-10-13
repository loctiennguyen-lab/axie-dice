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
## Not drawn (no seasonal logic exists; EchoBox.open_season is missing): M5n/o/p/q/r/s/t/w.

const SCREEN_ID := "echobox"
const _Econ := preload("res://scripts/meta/economy_db.gd")
const PULL_N := 10
const CHEST_BY_RARITY := {"common": "Bronze", "uncommon": "Silver", "rare": "Gold", "epic": "Platinum",
	"legendary": "Diamond", "mythic": "Lunacian"}
const STONE_CHEST := {100: "Bronze", 250: "Bronze", 500: "Silver", 1000: "Gold", 2500: "Platinum", 10000: "Lunacian"}
# TODO lane U token: darker wood for small-caps section labels on cream.
const WOOD_DARK := Color("6E2F18")
# TODO lane U token: fragment bar colour (R3 README M5 ticket bar).
const FRAG_TEAL := Color("5FCFCB")

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

var _panel: PanelContainer
var _col: VBoxContainer
var _body: HBoxContainer
var _banner_host: VBoxContainer
var _bar_host: HBoxContainer
var _stage_host: VBoxContainer
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
		if ev.keycode == KEY_ESCAPE:
			if _modal_layer.get_child_count() > 0:
				close_modal()
			else:
				_on_back()
			get_viewport().set_input_as_handled()
		elif ev.keycode == KEY_SPACE and _modal_layer.get_child_count() > 0:
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
	if tab != "regular":
		return "Season box - coming later"
	if state == "loading":
		return "Loading..."
	if _account_blocks():
		return "Needs a connection - nothing is spent" if state == "offline" else "Sign in to get tickets"
	if tickets() < n:
		return "Not enough tickets (%d of %d)" % [tickets(), n]
	return ""


## Real pull: n tickets through EchoBox.open_normal (or pull_hook). Returns the result list.
func pull(n: int) -> Array:
	_recheck_account()
	if pull_block_reason(n) != "":
		return []
	var out: Array = []
	if pull_hook.is_valid():
		out = pull_hook.call(n)
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
	_refresh_all()
	await _play_ceremony(out)
	return out


## Buy one ticket for Shards (EchoBox.buy_tickets). Returns the logic result.
func buy_ticket() -> Dictionary:
	_recheck_account()
	if _account_blocks():
		return {"ok": false, "reason": "state"}
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
	if _panel == null:
		return
	for c in _banner_host.get_children():
		c.queue_free()
	_body.visible = s != "loading"
	var sk := _col.get_node_or_null("Skeleton")
	if sk:
		sk.queue_free()
	if s == "loading":
		_build_skeleton()
	elif s == "offline":
		if remote_on:
			_banner("Can't reach the dice server", "Opening needs a connection; nothing is spent. Cached counts are greyed.", true)
		else:
			_banner("You're offline", "Boxes open on this device for now; progress syncs when you reconnect.", false)
	elif s == "guest":
		if remote_on:
			_banner("Sign in to use this.", "Guests can read the rates and pool. Tickets and pulls need an account.", false)
		else:
			_banner("Playing as a guest", "Boxes open on this device. Sign in to keep your tickets across devices.", false)
	elif s == "error":
		_banner("Pull failed (server error)", error_text if error_text != "" else "Your tickets were not spent.", true)
	elif s == "last_pull":
		_banner("Your last pull", "The window closed mid-pull. The server kept the result; here it is.", false)
	_refresh_all()


func open_rates() -> void:
	close_modal()
	var m := _modal("Rates", 760)
	var v: VBoxContainer = m.find_child("V", true, false)
	v.add_child(_label("Regular box - each pull is exactly one reward", 16, DangoTheme.INK_2))
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
		grid.add_child(_label(nm, 16))
		grid.add_child(_label("%.3f%%" % (float(d.get("weight", 0)) / total * 100.0), 16))
	v.add_child(_label(_pity_text(), 14, DangoTheme.INK_2))
	_modal_close_row(v)


func open_confirm_buy() -> void:
	var m := _modal("Buy a ticket?", 560)
	var v: VBoxContainer = m.find_child("V", true, false)
	v.add_child(_label("The next ticket costs %d Shards, more than twice today's first one." % next_price(), 16))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var no := _button("Cancel", 160, 48)
	no.pressed.connect(close_modal)
	var yes := _button("Buy", 160, 48, true)
	yes.name = "ConfirmBuy"
	yes.pressed.connect(func() -> void:
		close_modal()
		buy_ticket())
	row.add_child(no)
	row.add_child(yes)
	v.add_child(row)


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
	_panel.offset_left = 200
	_panel.offset_right = -200
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
	var bar := PanelContainer.new()
	bar.custom_minimum_size = Vector2(0, 64)
	var bsb := StyleBoxFlat.new()
	bsb.bg_color = DangoTheme.CREAM_200
	bsb.content_margin_left = 24
	bsb.content_margin_right = 24
	bar.add_theme_stylebox_override("panel", bsb)
	_bar_host = HBoxContainer.new()
	_bar_host.name = "TicketBar"
	_bar_host.add_theme_constant_override("separation", 20)
	bar.add_child(_bar_host)
	_col.add_child(bar)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	var tm := MarginContainer.new()
	tm.add_theme_constant_override("margin_left", 24)
	tm.add_theme_constant_override("margin_top", 10)
	tm.add_child(tabs)
	for t in [["regular", "Regular"], ["seasonal", "Seasonal"]]:
		var b := _button(String(t[1]), 180, 46)
		b.name = "Tab_" + String(t[0])
		b.pressed.connect(select_tab.bind(String(t[0])))
		tabs.add_child(b)
		_tab_btns[t[0]] = b
	_col.add_child(tm)
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
	_body = HBoxContainer.new()
	_body.name = "Body"
	_body.add_theme_constant_override("separation", 20)
	pad.add_child(_body)
	_stage_host = VBoxContainer.new()
	_stage_host.name = "Stage"
	_stage_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stage_host.add_theme_constant_override("separation", 12)
	_body.add_child(_stage_host)
	_side_host = VBoxContainer.new()
	_side_host.name = "Side"
	_side_host.custom_minimum_size = Vector2(380, 0)
	_side_host.add_theme_constant_override("separation", 12)
	_body.add_child(_side_host)
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
	row.add_child(_label("Echo Box", 36, DangoTheme.CREAM_RAISED, true))
	var sub := _label("Spend tickets, get Stone or a cosmetic", 16, DangoTheme.CREAM)
	sub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sub.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(sub)
	return band


func _on_back() -> void:
	if is_inside_tree() and not no_scene_change:
		LandNav.back_to_land()


# ---------------------------------------------------------------- refresh

func _clear(n: Node) -> void:
	for c in n.get_children():
		n.remove_child(c)
		c.queue_free()


func _refresh_all() -> void:
	if _panel == null:
		return
	for k in _tab_btns:
		(_tab_btns[k] as Button).disabled = false
		(_tab_btns[k] as Button).text = String(k).capitalize()
	(_tab_btns["seasonal"] as Button).text = "Seasonal  (coming later)"
	_refresh_bar()
	_refresh_stage()
	_refresh_side()


func _refresh_bar() -> void:
	_clear(_bar_host)
	var offline := state == "offline" and remote_on
	var t := _label("Tickets  %d / 999" % tickets(), 20, DangoTheme.INK_3 if offline else DangoTheme.INK, true)
	t.name = "Tickets"
	_bar_host.add_child(t)
	var per := int(_Econ.get_table("echobox").get("fragments_per_ticket", 10))
	var frags := int(MetaState.echobox_pity.get("fragments", 0))
	var fb := ProgressBar.new()
	fb.name = "Fragments"
	fb.custom_minimum_size = Vector2(220, 20)
	fb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fb.max_value = per
	fb.value = frags
	fb.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = FRAG_TEAL
	fill.set_corner_radius_all(8)
	fb.add_theme_stylebox_override("fill", fill)
	_bar_host.add_child(_label("Fragments  %d/%d" % [frags, per], 16, DangoTheme.INK_2))
	_bar_host.add_child(fb)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bar_host.add_child(sp)
	var price := next_price()
	var pl := _label("Next ticket  %s Shards" % (str(price) if price >= 0 else "-"), 16, DangoTheme.INK_2)
	pl.name = "NextPrice"
	_bar_host.add_child(pl)
	var buy := _button("Buy ticket  %s" % (str(price) if price >= 0 else "max today"), 210, 48, true)
	buy.name = "BuyTicket"
	var why := ""
	if _account_blocks() or state == "loading":
		why = "Not available right now"
	elif price < 0:
		why = "Daily limit reached (30)"
	elif MetaState.shard_pool < price:
		why = "Not enough Shards"
	buy.disabled = why != ""
	buy.tooltip_text = why
	buy.pressed.connect(_on_buy_pressed)
	_bar_host.add_child(buy)


func _on_buy_pressed() -> void:
	var first := EchoBox.ticket_price(1)
	var price := next_price()
	if price > 2 * first:
		open_confirm_buy()
	else:
		buy_ticket()


func _refresh_stage() -> void:
	_clear(_stage_host)
	var seasonal := tab == "seasonal"
	var stage := _plate(0, DangoTheme.LINE, DangoTheme.MYTHIC_NIGHT if seasonal else DangoTheme.CREAM_300)
	stage.name = "StagePlate"
	stage.custom_minimum_size = Vector2(0, 360)
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 14)
	stage.add_child(v)
	var ink := DangoTheme.DUSK_INK if seasonal else DangoTheme.INK
	# Chest stand-in (300): tier chest art is not in the build yet.
	var chest := _label("Mystic Chest" if seasonal else "Gold Chest", 28, ink, true)
	chest.name = "Chest"
	chest.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chest.custom_minimum_size = Vector2(0, 200)
	chest.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	v.add_child(chest)
	if seasonal:
		var l := _label("Season box - coming later", 22, ink, true)
		l.name = "ComingLater"
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l)
		# L1: no Open button on the Seasonal tab (README M5m); EchoBox.open_season does not exist.
	else:
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 14)
		v.add_child(row)
		var n_big := PULL_N
		var o1 := _button("Open 1", 200, 60, true)
		o1.name = "Open1"
		o1.pressed.connect(func() -> void: pull(1))
		var on := _button("Open %d" % n_big, 200, 60, true)
		on.name = "OpenN"
		on.pressed.connect(func() -> void: pull(n_big))
		var rt := _button("Rates", 150, 60)
		rt.name = "Rates"
		rt.pressed.connect(open_rates)
		for b in [o1, on]:
			var why := pull_block_reason(1 if b == o1 else n_big)
			b.disabled = why != ""
			b.tooltip_text = why
		row.add_child(o1)
		row.add_child(on)
		row.add_child(rt)
		var why1 := pull_block_reason(1)
		if why1 != "":
			var rl := _label(why1, 16, DangoTheme.INK_DISABLED)
			rl.name = "Reason"
			rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			v.add_child(rl)
			if why1.begins_with("Not enough") and not _account_blocks():
				var sc := _button("Buy enough for 1 pull", 260, 48)
				sc.name = "BuyEnough"
				sc.pressed.connect(buy_ticket)
				sc.disabled = next_price() < 0 or MetaState.shard_pool < next_price()
				v.add_child(sc)
	_stage_host.add_child(stage)
	if not results.is_empty():
		_stage_host.add_child(_build_summary())


func _pity_text() -> String:
	var parts: Array[String] = []
	for s in (box_cfg().get("pity", {}) as Dictionary).get("steps", []):
		parts.append("%s every %d cosmetic pulls" % [String(s["min_rarity"]).capitalize(), int(s["pulls"])])
	return "Guaranteed minimum: " + " · ".join(parts)


func _refresh_side() -> void:
	_clear(_side_host)
	var pity := _plate(0)
	pity.name = "PityPanel"
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	pity.add_child(v)
	v.add_child(_label("PITY · cosmetic pulls only", 14, WOOD_DARK, true))
	for s in (box_cfg().get("pity", {}) as Dictionary).get("steps", []):
		var rar := String(s["min_rarity"])
		var need := int(s["pulls"])
		var have := mini(int(MetaState.echobox_pity.get("since_" + rar, 0)), need)
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 8)
		var nm := _label(rar.capitalize(), 16)
		nm.custom_minimum_size = Vector2(90, 0)
		r.add_child(nm)
		var pb := ProgressBar.new()
		pb.name = "Pity_" + rar
		pb.custom_minimum_size = Vector2(150, 18)
		pb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pb.max_value = need
		pb.value = have
		pb.show_percentage = false
		var fill := StyleBoxFlat.new()
		fill.bg_color = DangoTheme.rarity_color(EchoBox.RARITIES.find(rar))
		fill.set_corner_radius_all(8)
		pb.add_theme_stylebox_override("fill", fill)
		r.add_child(pb)
		r.add_child(_label("%d/%d" % [have, need], 14, DangoTheme.INK_2))
		v.add_child(r)
	_side_host.add_child(pity)
	var pool := _plate(0)
	pool.name = "PoolPanel"
	var pv := VBoxContainer.new()
	pool.add_child(pv)
	var total := 0
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	pv.add_child(_label("POOL", 14, WOOD_DARK, true))
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
		var tile := _label("%s\n%d/%d" % [String(rar).capitalize(), own, c], 14, DangoTheme.INK)
		tile.name = "Pool_" + rar
		tile.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tile.custom_minimum_size = Vector2(110, 52)
		grid.add_child(tile)
	pv.add_child(_label("%d cosmetics in the pool" % total, 14, DangoTheme.INK_2))
	_side_host.add_child(pool)
	var dup := _label("A duplicate becomes Fragments; 10 Fragments = 1 ticket. Never Shards.", 14, DangoTheme.INK_2)
	dup.name = "DupLine"
	dup.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dup.custom_minimum_size = Vector2(340, 0)
	_side_host.add_child(dup)


func _build_summary() -> Control:
	var p := _plate(0)
	p.name = "Summary"
	var v := VBoxContainer.new()
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
	v.add_child(_label("%s · %d Stone · %d new · %d duplicates" % [
		"Last pull" if state == "last_pull" else "Result", stone, new_n, dup_n], 18, DangoTheme.INK, true))
	if error_text.begins_with("Opened "):
		var pl := _label(error_text, 16, DangoTheme.INK_3)
		pl.name = "PartialPull"
		v.add_child(pl)
	var grid := GridContainer.new()
	grid.name = "ResultGrid"
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	v.add_child(grid)
	for r in results:
		grid.add_child(_result_cell(r))
	return p


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


func _result_cell(r: Dictionary) -> Control:
	var c := _plate(128, DangoTheme.rarity_color(_rarity_idx(r)))
	c.custom_minimum_size = Vector2(128, 150)
	var v := VBoxContainer.new()
	c.add_child(v)
	var art: Control = null
	if String(r.get("kind")) == "cosmetic":
		art = CosmeticTile.art(String(r.get("item", "")), 72.0)
	if art != null:
		c.custom_minimum_size = Vector2(128, 230)
		v.add_child(art)
		var nm: Label = _label(CosmeticTile.display_name(String(r.get("item", ""))), 13, DangoTheme.INK)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(nm)
	v.add_child(_label(_reward_title(r), 14, DangoTheme.INK, true))
	var tag := "Stone"
	if String(r.get("kind")) != "stone":
		tag = ("Duplicate +%d frag" % int(r.get("fragments", 0))) if bool(r.get("duplicate", false)) else "NEW"
	v.add_child(_label(tag, 14, DangoTheme.INK_2))
	v.add_child(_label(_chest_tier(r) + " chest", 12, DangoTheme.INK_2))
	return c


func _build_skeleton() -> void:
	var sk := VBoxContainer.new()
	sk.name = "Skeleton"
	sk.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var w := Panel.new()
	w.custom_minimum_size = Vector2(0, 360)
	var sb := StyleBoxFlat.new()
	sb.bg_color = DangoTheme.CREAM_TRACK
	sb.set_corner_radius_all(20)
	w.add_theme_stylebox_override("panel", sb)
	sk.add_child(w)
	_col.add_child(sk)


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


func _modal_close_row(v: VBoxContainer) -> void:
	var b := _button("Close  Esc", 160, 48, true)
	b.pressed.connect(close_modal)
	v.add_child(b)


# ---------------------------------------------------------------- ceremony

## Idle -> pressed -> opening -> reveal -> (Open 10 grid) -> summary. Skip (Space / button)
## is available from the first frame. Mythic <= 2 s. Reduce flashing: static rim, 200 ms fade.
func _play_ceremony(out: Array) -> void:
	_skip = instant
	var top := out[0] as Dictionary
	for r in out:
		if _rarity_idx(r) > _rarity_idx(top):
			top = r
	var m := _modal("Opening...", 520)
	m.name = "Ceremony"
	var v: VBoxContainer = m.find_child("V", true, false)
	var skip := _button("Skip  Space", 160, 48)
	skip.name = "Skip"
	skip.pressed.connect(func() -> void: _skip = true)
	v.add_child(skip)
	var rim := DangoTheme.rarity_color(_rarity_idx(top))
	var chest := _label("%s chest" % _chest_tier(top), 24, DangoTheme.INK, true)
	chest.name = "CeremonyChest"
	v.add_child(chest)
	if not _skip:
		var t := create_tween()
		var dur := 0.2 if reduce_flashing else (1.5 if _rarity_idx(top) >= 5 else 1.2)
		t.tween_property(chest, "modulate", Color(rim.r, rim.g, rim.b, 1.0).lerp(Color.WHITE, 0.5), dur)
		var elapsed := 0.0
		while elapsed < dur and not _skip and is_inside_tree():
			await get_tree().process_frame
			elapsed += get_process_delta_time()
		t.kill()
	v.remove_child(chest)
	chest.queue_free()
	skip.queue_free()
	(v.get_child(0) as Label).text = "Reveal" if out.size() == 1 else "Open %d" % out.size()
	var grid := GridContainer.new()
	grid.name = "RevealGrid"
	grid.columns = 1 if out.size() == 1 else 5
	for r in out:
		grid.add_child(_result_cell(r))
	v.add_child(grid)
	var done := _button("Done", 160, 48, true)
	done.name = "Done"
	done.pressed.connect(func() -> void:
		close_modal()
		_refresh_all())
	v.add_child(done)
	_refresh_all()
