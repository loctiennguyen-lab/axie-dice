class_name StoreScreen
extends Control
## M7 Store (key 7). Spec: design/handoffs/ui-02-round3 README section 2 M7, frames M7a-M7n.
## L1 rules (Liam 12/10): gift Gem buys Gem-priced goods (ticket bundles, cosmetics) through
## StoreCatalog -> MetaState.spend("gem") -> GemWallet. Every USD button is drawn but disabled
## ("Playtest: purchases disabled"); no fake purchase. Moon Card buy disabled, no trial.
## Prices come from gem.json (StoreCatalog); GEM_PACKS below are display-only labels of the USD
## ladder (README M7), not read by any purchase path. Guest/offline only block purchases when the
## remote wallet flag is on, otherwise an info banner (same rule as Echo Box / Missions).
## Drawn: M7a main (Gem tab strip), Gem/Moon/Tickets/Cosmetics tabs, confirm (M7e-h), result line,
## short-of-Gem state. Not drawn: Aid prices tab content, Starter Pack, spending limit/confirm 250 USD
## (no data, no USD purchases in L1), loading frame.

const _Econ := preload("res://scripts/meta/economy_db.gd")
const _SB := preload("res://scripts/meta/store_catalog.gd")
const VIOLET := Color("6B4AA8")
## Display-only: Gem packs the USD buttons will sell once purchases open [INF].
const GEM_PACKS := [80, 420, 880, 1800, 4650, 9600]
const TABS := ["gem", "moon", "tickets", "cosmetics", "aid"]
const TAB_NAMES := {"gem": "Gem", "moon": "Moon Card", "tickets": "Tickets", "cosmetics": "Cosmetics", "aid": "Aid prices"}
const REASONS := {
	"no_gems": "Not enough Gem", "hold_cap": "You can't hold that many tickets",
	"owned": "You already own this", "not_for_sale": "Not for sale",
	"not_in_normal_pool": "Only from the Seasonal Echo Box", "unknown_bundle": "Unknown bundle",
}

## "normal" | "loading" | "offline" | "guest"
var state := "normal"
var tab := "gem"
var no_scene_change := false
var use_account := true
var remote_on: bool = String(ProjectSettings.get_setting("axie/gem_wallet", "")) == "remote"
var account_status_hook: Callable
var last_result := ""

var _panel: PanelContainer
var _banner_host: VBoxContainer
var _strip_host: HBoxContainer
var _tab_host: HBoxContainer
var _body_host: VBoxContainer
var _modal_layer: Control
var _gem_label: Label


func _ready() -> void:
	_build()
	if use_account:
		state = derive_state()
	set_state(state)


func derive_state() -> String:
	var st: int = account_status_hook.call() if account_status_hook.is_valid() else AccountService.status
	match st:
		AccountService.Status.GUEST, AccountService.Status.EXPIRED:
			return "guest"
		AccountService.Status.OFFLINE:
			return "offline"
	return "normal"


func _unhandled_key_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_ESCAPE:
		if _modal_layer.get_child_count() > 0:
			close_modal()
		else:
			_on_back()
		get_viewport().set_input_as_handled()


# ---------------------------------------------------------------- public API (also tests)

func gems() -> int:
	return MetaState.gem_wallet().balance()


func usd_enabled() -> bool:
	return _SB.usd_enabled()


func _account_blocks() -> bool:
	return remote_on and (state == "offline" or state == "guest")


## Why a Gem purchase of `price` cannot happen now, or "".
func block_reason(price: int) -> String:
	if state == "loading":
		return "Loading..."
	if _account_blocks():
		return "Needs a connection" if state == "offline" else "Sign in to spend Gem"
	if gems() < price:
		return "need %d more Gem" % (price - gems())
	return ""


func cosmetic_items() -> Array:
	var box: Dictionary = (_Econ.get_table("echobox").get("boxes", {}) as Dictionary).get("normal", {})
	var out: Array = []
	for r in ["rare", "epic", "legendary", "mythic"]:
		var ids: Array = EchoBox.pool_ids(box, r)
		for i in mini(2, ids.size()):
			out.append({"id": String(ids[i]), "rarity": r, "price": _SB.cosmetic_price(r)})
	return out


func buy_bundle(count: int) -> String:
	var price := 0
	for b in _SB.bundles():
		if int((b as Dictionary).tickets) == count:
			price = int((b as Dictionary).gems)
	var why := block_reason(price)
	if why != "":
		return why
	var r: String = _SB.buy_ticket_bundle(MetaState, count)
	_after(r, "%d tickets added" % count)
	return r


func buy_cosmetic(item_id: String, rarity: String) -> String:
	var why := block_reason(_SB.cosmetic_price(rarity))
	if why != "":
		return why
	var r: String = _SB.buy_cosmetic(MetaState, item_id, rarity)
	_after(r, "Added to your collection")
	return r


func _after(code: String, ok_text: String) -> void:
	last_result = ok_text if code == "" else String(REASONS.get(code, code))
	if _panel != null:
		_refresh()


func set_state(s: String) -> void:
	state = s
	if _panel == null:
		return
	for c in _banner_host.get_children():
		c.queue_free()
	match s:
		"offline":
			_banner("Can't reach the dice server" if remote_on else "You're offline",
				"Spending Gem needs a connection; nothing is spent." if remote_on else "Gem purchases run on this device for now.")
		"guest":
			_banner("Sign in to spend Gem" if remote_on else "You're signed out",
				"Guests can read every price." if remote_on else "Purchases are kept on this device. Sign in to keep them.")
	_refresh()


func set_tab(t: String) -> void:
	tab = t
	last_result = ""
	_refresh()


func open_confirm(title: String, detail: String, price: int, action: Callable) -> void:
	close_modal()
	var m := _modal(title, 600)
	var v: VBoxContainer = m.find_child("V", true, false)
	var d := _label(detail, 16)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(d)
	v.add_child(_label("Cost %d Gem. You hold %d." % [price, gems()], 16, DangoTheme.INK_2))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var no := _button("Not now", 260, 48)
	no.name = "NotNow"
	no.pressed.connect(close_modal)
	var yes := _button("Buy for %d Gem" % price, 260, 48, true)
	yes.name = "ConfirmBuy"
	yes.disabled = block_reason(price) != ""
	yes.pressed.connect(func() -> void:
		close_modal()
		action.call())
	row.add_child(no)
	row.add_child(yes)
	v.add_child(row)
	no.grab_focus()


func close_modal() -> void:
	for c in _modal_layer.get_children():
		c.queue_free()


func claim_gift() -> Dictionary:
	if _account_blocks():
		return {"ok": false, "reason": "blocked"}
	var r := MetaState.claim_gem_gift_now()
	last_result = "Claimed %d Gem" % int(r.get("granted", 0)) if bool(r.get("ok", false)) else _gift_reason(r)
	_refresh()
	return r


func _gift_reason(r: Dictionary) -> String:
	match String(r.get("reason", "")):
		"already_claimed": return "Already claimed today"
		"at_cap": return "You hold the maximum, nothing to claim"
	return "Could not claim"


func _on_back() -> void:
	if is_inside_tree() and not no_scene_change:
		LandNav.back_to_land()


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
	var sb := StyleBoxFlat.new()   # paid surface: violet border needs a DangoTheme "paid" variation (lane U); LINE for now (t_ui_laws L7)
	sb.bg_color = DangoTheme.CREAM
	sb.set_corner_radius_all(28)
	sb.set_border_width_all(4)
	sb.border_color = DangoTheme.LINE
	_panel.add_theme_stylebox_override("panel", sb)
	_panel.clip_contents = true
	add_child(_panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	_panel.add_child(col)
	col.add_child(_build_header())
	_banner_host = VBoxContainer.new()
	col.add_child(_banner_host)
	var strip := PanelContainer.new()
	strip.custom_minimum_size = Vector2(0, 56)
	var ssb := StyleBoxFlat.new()
	ssb.bg_color = DangoTheme.CREAM_200
	ssb.content_margin_left = 24
	ssb.content_margin_right = 24
	strip.add_theme_stylebox_override("panel", ssb)
	_strip_host = HBoxContainer.new()
	_strip_host.name = "GiftStrip"
	_strip_host.add_theme_constant_override("separation", 20)
	strip.add_child(_strip_host)
	col.add_child(strip)
	_tab_host = HBoxContainer.new()
	_tab_host.name = "Tabs"
	_tab_host.add_theme_constant_override("separation", 8)
	var tm := MarginContainer.new()
	tm.add_theme_constant_override("margin_left", 20)
	tm.add_theme_constant_override("margin_top", 10)
	tm.add_child(_tab_host)
	col.add_child(tm)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	DangoTheme.style_scrollbars(scroll)
	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for s in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + s, 20)
	scroll.add_child(pad)
	_body_host = VBoxContainer.new()
	_body_host.name = "Body"
	_body_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body_host.add_theme_constant_override("separation", 12)
	pad.add_child(_body_host)
	_modal_layer = Control.new()
	_modal_layer.name = "Modals"
	_modal_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_modal_layer)


func _build_header() -> Control:
	var band := PanelContainer.new()
	band.custom_minimum_size = Vector2(0, 72)
	var sb := StyleBoxFlat.new()
	sb.bg_color = VIOLET
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
	var t := _label("Store", 36, DangoTheme.CREAM_RAISED, true)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(t)
	_gem_label = _label("", 20, DangoTheme.CREAM_RAISED)
	_gem_label.name = "GemChip"
	_gem_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_gem_label)
	var buy := _button("Buy Gem", 150, 48)
	buy.name = "BuyGem"
	_disable_usd(buy)
	row.add_child(buy)
	return band


func _disable_usd(b: Button) -> void:
	b.disabled = not usd_enabled()
	if b.disabled:
		b.tooltip_text = "Playtest: purchases disabled"


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


func _clear(n: Node) -> void:
	for c in n.get_children():
		n.remove_child(c)
		c.queue_free()


func _banner(msg: String, detail: String) -> void:
	var p := PanelContainer.new()
	p.name = "Banner"
	var sb := StyleBoxFlat.new()
	sb.bg_color = DangoTheme.DUSK
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	p.add_theme_stylebox_override("panel", sb)
	var t := VBoxContainer.new()
	t.add_child(_label(msg, 18, DangoTheme.DUSK_INK, true))
	t.add_child(_label(detail, 14, DangoTheme.DUSK_INK))
	p.add_child(t)
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
	_gem_label.text = "Gem %d" % gems()
	_refresh_strip()
	_clear(_tab_host)
	for t in TABS:
		var b := _button(String(TAB_NAMES[t]), 150, 46, t == tab)
		b.name = "Tab_" + t
		b.pressed.connect(set_tab.bind(t))
		_tab_host.add_child(b)
	_clear(_body_host)
	if state == "loading":
		_body_host.add_child(_label("Loading...", 18, DangoTheme.INK_2))
		return
	if last_result != "":
		var r := _label(last_result, 18, DangoTheme.INK, true)
		r.name = "Result"
		_body_host.add_child(r)
	match tab:
		"gem": _tab_gem()
		"moon": _tab_moon()
		"tickets": _tab_tickets()
		"cosmetics": _tab_cosmetics()
		"aid": _body_host.add_child(_note("Aid prices are shown inside a run. This list is not in this build."))


func _note(text: String) -> Label:
	var l := _label(text, 16, DangoTheme.INK_2)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _refresh_strip() -> void:
	_clear(_strip_host)
	var g: Dictionary = _Econ.get_table("gem").get("gift", {})
	var cap := int(g.get("balance_cap", 900))
	var per := int(g.get("per_day", 300))
	_strip_host.add_child(_label("Playtest: Gem is free (%d a day, hold up to %d)" % [per, cap], 18))
	var now := int(Time.get_unix_time_from_system())
	var claimed_today: bool = MetaState.gem_gift_day != "" and GemWallet.utc_day(now) <= MetaState.gem_gift_day
	var note := ""
	if claimed_today:
		note = "Next claim %s 00:00 UTC" % Time.get_date_string_from_unix_time(GemWallet.next_utc_midnight(now))
	elif gems() >= cap:
		note = "You hold %d, nothing to claim" % gems()
	var nl := _label(note, 14, DangoTheme.INK_2)
	nl.name = "GiftNote"
	nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_strip_host.add_child(nl)
	var c := _button("Claim %d Gem" % per, 220, 48, true)
	c.name = "ClaimGift"
	c.disabled = _account_blocks() or claimed_today or gems() >= cap
	c.pressed.connect(claim_gift)
	_strip_host.add_child(c)
	var sp := _label("Spending limit applies when purchases open", 14, DangoTheme.INK_2)
	sp.name = "SpendNote"
	_strip_host.add_child(sp)


func _tab_gem() -> void:
	var grid := GridContainer.new()
	grid.name = "GemGrid"
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	for n in GEM_PACKS:
		var p := _plate(0)
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var v := VBoxContainer.new()
		v.add_child(_label("%s Gem" % _fmt(int(n)), 26, DangoTheme.INK, true))
		var b := _button("Buy with USD", 0, 60)
		b.name = "Usd_%d" % int(n)
		_disable_usd(b)
		v.add_child(b)
		v.add_child(_label("Playtest: purchases disabled", 14, DangoTheme.INK_2))
		p.add_child(v)
		grid.add_child(p)
	_body_host.add_child(grid)


func _tab_moon() -> void:
	var p := _plate(0)
	var v := VBoxContainer.new()
	v.add_child(_label("Moon Card", 26, DangoTheme.INK, true))
	v.add_child(_note("Not in this build. No trial, no purchase."))
	var b := _button("Buy Moon Card", 260, 48, true)
	b.name = "MoonBuy"
	b.disabled = true
	b.tooltip_text = "Playtest: purchases disabled"
	v.add_child(b)
	p.add_child(v)
	_body_host.add_child(p)


func _tab_tickets() -> void:
	var grid := GridContainer.new()
	grid.name = "TicketGrid"
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 16)
	for bd in _SB.bundles():
		var d: Dictionary = bd
		var n := int(d.tickets)
		var price := int(d.gems)
		var p := _plate(0)
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var v := VBoxContainer.new()
		v.add_child(_label("%d tickets" % n, 24, DangoTheme.INK, true))
		var why := block_reason(price)
		var b := _button(why if why != "" else "%s Gem" % _fmt(price), 0, 48, why == "")
		b.name = "Ticket_%d" % n
		b.disabled = why != ""
		b.pressed.connect(open_confirm.bind("%d tickets" % n, "Adds %d Echo Box tickets." % n, price, buy_bundle.bind(n)))
		v.add_child(b)
		p.add_child(v)
		grid.add_child(p)
	_body_host.add_child(grid)


func _tab_cosmetics() -> void:
	var grid := GridContainer.new()
	grid.name = "CosGrid"
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	for it in cosmetic_items():
		var d: Dictionary = it
		var id := String(d.id)
		var price := int(d.price)
		var owned := MetaState.cosmetics_owned.has(id)
		var p := _plate(0)
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var v := VBoxContainer.new()
		var art := CosmeticTile.art(id, 72.0)
		if art != null:
			v.add_child(art)
		var nm := CosmeticTile.display_name(id)
		v.add_child(_label(nm if nm != "" else id, 18, DangoTheme.INK, true))
		v.add_child(_label(String(d.rarity).capitalize(), 14, DangoTheme.INK_2))
		var why := "Owned" if owned else block_reason(price)
		var b := _button(why if why != "" else "%s Gem" % _fmt(price), 0, 48, why == "")
		b.name = "Cos_" + id
		b.disabled = why != ""
		b.pressed.connect(open_confirm.bind(id, "Adds this cosmetic to your collection.", price, buy_cosmetic.bind(id, String(d.rarity))))
		v.add_child(b)
		p.add_child(v)
		grid.add_child(p)
	_body_host.add_child(grid)
	_body_host.add_child(_note("Season items: only from the Seasonal Echo Box. Cosmetic prices are placeholders."))


func _fmt(n: int) -> String:
	var s := str(n)
	var out := ""
	for i in s.length():
		if i > 0 and (s.length() - i) % 3 == 0:
			out += ","
		out += s[i]
	return out
