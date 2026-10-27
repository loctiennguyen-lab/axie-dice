class_name StoreScreen
extends Control
## Store (key 7), UI-03 screen 19: design/handoffs/ui-03-redesign/round-1/handoff/screens/19-store/spec.md.
## Built on UI3Meta (shared meta shell). One primary per screen: "Claim Gem"; tile buttons are secondary,
## the confirm dialog owns its own primary.
## L1 rules (Liam 12/10): gift Gem buys Gem-priced goods (ticket bundles, cosmetics) through
## StoreCatalog -> MetaState.spend("gem") -> GemWallet. Every USD button is drawn but disabled
## ("Playtest: purchases disabled"); no fake purchase. Moon Card buy disabled, no trial.
## Prices come from gem.json (StoreCatalog); the Gem pack ladder (gem_packs) is display-only. Guest/offline only block purchases when the
## remote wallet flag is on, otherwise an info banner (same rule as Echo Box / Missions).
## Drawn: M7a main (Gem tab strip), Gem/Moon/Tickets/Cosmetics tabs, confirm (M7e-h), result line,
## short-of-Gem state. Not drawn: Aid prices tab content, Starter Pack, spending limit/confirm 250 USD
## (no data, no USD purchases in L1), loading frame.

const _Econ := preload("res://scripts/meta/economy_db.gd")
const _SB := preload("res://scripts/meta/store_catalog.gd")
const VIOLET := Color("6B4AA8")
const TABS := ["gem", "cosmetics", "tickets", "moon"]
const TAB_NAMES := {"gem": "Gem packs", "cosmetics": "Cosmetics", "tickets": "Tickets", "moon": "Moon Card"}
const DETAIL_W := 440
const USD_REASON := "Buying disabled in the playtest"
const RARITY_TOKEN := {"uncommon": "rarity_uncommon", "rare": "rarity_rare", "epic": "rarity_epic", "legendary": "rarity_legendary", "mythic": "rarity_mythic"}
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

var _shell: Dictionary
var _panel: Control
var _banner_host: VBoxContainer
var _strip_host: HBoxContainer
var _body_host: VBoxContainer
var _modal_layer: Control
var _tab_btns: Dictionary = {}
var _detail: PanelContainer
## Selected tile key per tab ("" = first item). Tiles only select; the buy action is the detail plate.
var selected := ""


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
	if ev is InputEventKey and ev.pressed and not ev.echo and ev.is_action_pressed(&"menu_back"):
		if _modal_layer.get_child_count() > 0:
			close_modal()
		else:
			_on_back()
		if is_inside_tree():   # a handler above may have changed scene
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
	UI3Meta.clear(_banner_host)
	match s:
		"offline":
			UI3Meta.banner(_banner_host, "Can't reach the server" if remote_on else "You're offline",
				"Spending Gem needs a connection; nothing is spent." if remote_on else "Gem purchases run on this device for now.")
		"guest":
			UI3Meta.banner(_banner_host, "Sign in to spend Gem" if remote_on else "You're signed out",
				"Guests can read every price." if remote_on else "Purchases are kept on this device. Sign in to keep them.")
	_refresh()


## Selects a tile (key like "usd_80", "ticket_6", "cos_<id>", "moon").
func select(key: String) -> void:
	selected = key
	_refresh()


func set_tab(t: String) -> void:
	tab = t
	last_result = ""
	selected = ""
	_refresh()


func open_confirm(title: String, detail: String, price: int, action: Callable) -> void:
	close_modal()
	var no := UI3.button("Not now", &"secondary", &"M")
	no.name = "NotNow"
	no.pressed.connect(close_modal)
	var yes := UI3.button("Buy for %d Gem" % price, &"primary", &"M")
	yes.name = "ConfirmBuy"
	var why := block_reason(price)
	if why != "":
		UI3.set_disabled_reason(yes, why)
	for cb in [no, yes]:
		(cb as Button).add_theme_stylebox_override("focus", UI3Theme.focus_style(UI3Theme.radius("l")))
	yes.pressed.connect(func() -> void:
		close_modal()
		action.call())
	var m := UI3.modal(title, "%s\nCost %d Gem. You hold %d." % [detail, price, gems()], [no, yes], 0)
	m.cancelled.connect(close_modal)
	_modal_layer.add_child(m)


func close_modal() -> void:
	UI3Meta.clear(_modal_layer)


var _gift_pending := false


func claim_gift() -> Dictionary:
	if _account_blocks():
		return {"ok": false, "reason": "blocked"}
	if GiftClaim.is_remote():
		if _gift_pending:
			return {"ok": false, "granted": 0, "reason": "pending"}
		_gift_pending = true
		last_result = GiftClaim.message({"reason": "pending"})
		_refresh()
		GiftClaim.claim_async(_on_gift_result)
		return {"ok": false, "granted": 0, "reason": "pending"}
	var r := MetaState.claim_gem_gift_now()
	_on_gift_result(r, GiftClaim.message(r), bool(r.get("ok", false)))
	return r


func _on_gift_result(r: Dictionary, text: String, ok: bool) -> void:
	_gift_pending = false
	last_result = text
	if not is_inside_tree():
		return
	_refresh()
	if not ok and String(r.get("reason", "")) != "already_claimed" and String(r.get("reason", "")) != "at_cap":
		GiftClaim.toast(self, text, &"error")


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
	_shell = UI3Meta.build(self, "Store", "Gem packs, cosmetics, tickets", _on_back)
	_panel = _shell["panel"]
	_panel.name = "PlateHost"   # t_ui_laws L0
	var col: VBoxContainer = _shell["col"]
	_banner_host = _shell["banner_host"]
	_modal_layer = _shell["modal_layer"]
	for t in TABS:
		var b := UI3Meta.tab(String(TAB_NAMES[t]), t == tab)
		b.name = "Tab_" + t
		b.pressed.connect(set_tab.bind(t))
		(_shell["header_right"] as Control).add_child(b)
		_tab_btns[t] = b
	var strip := UI3.plate(&"plate")
	strip.name = "GiftStrip"
	_strip_host = HBoxContainer.new()
	_strip_host.add_theme_constant_override("separation", UI3Theme.space("16"))
	strip.add_child(_strip_host)
	col.add_child(strip)
	(_shell["sub"] as Label).theme_type_variation = ""   # readable cream, not the muted token
	var body := HBoxContainer.new()
	body.name = "BodyRow"
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", UI3Meta.GAP)
	col.add_child(body)
	_body_host = VBoxContainer.new()
	_body_host.name = "Body"
	_body_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body_host.add_theme_constant_override("separation", UI3Theme.space("16"))
	body.add_child(_body_host)
	_detail = UI3.plate(&"plate")
	_detail.name = "Detail"
	_detail.custom_minimum_size = Vector2(DETAIL_W, 0)
	body.add_child(_detail)


func _clear(n: Node) -> void:
	UI3Meta.clear(n)


func _fmt(n: int) -> String:
	return UI3.fmt(n)


func _note(text: String) -> Label:
	var l := UI3.label(text, "LabelMuted")
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


## Tile: a selectable card. Returns [card, content VBox]; `key` names the invisible select button `btn_name`.
func _tile(key: String, btn_name: String) -> Array:
	var on := key == selected
	var p := UI3.plate(&"card_selected" if on else &"card")
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", UI3Theme.space("8"))
	p.add_child(v)
	var b := Button.new()
	b.name = btn_name
	b.flat = true
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for st in ["normal", "hover", "pressed", "disabled", "hover_pressed"]:
		b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	b.add_theme_stylebox_override("focus", UI3Theme.focus_style(UI3Theme.radius("l")))
	b.pressed.connect(select.bind(key))
	p.add_child(b)
	return [p, v]


func _tile_text(v: VBoxContainer, title: String, sub: String) -> void:
	var t := UI3.label(title, "LabelTitle")
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(t)
	var m := UI3.label(sub, "LabelMuted")
	m.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(m)


## Badge: neutral wood tag, or (token != "") outlined in the colour token, text in the same colour.
func _badge(text: String, token := "") -> Control:
	if token == "":
		return UI3Meta.tag(text)
	var c := PanelContainer.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.custom_minimum_size = Vector2(0, UI3.CHIP_H)
	var col := UI3Theme.color(token)
	c.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("notice_bg"), UI3Theme.radius("s"), 2, col, Vector4(12, 0, 12, 0)))
	var l := UI3.label(text, "LabelDisplay")
	l.add_theme_color_override("font_color", col)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	c.add_child(l)
	return c


func _gem_art(px: float) -> Control:
	var t := TextureRect.new()
	t.texture = UI3.icon("cur_gem")
	t.custom_minimum_size = Vector2.ONE * px
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


## Right-hand detail plate: art, title + badge, body, price rows, reason, one 72 primary ("DetailBuy").
## `art` may be null; `reason` != "" disables the primary and replaces its label.
func _show_detail(art: Control, title: String, badge: String, body: String, rows: Array,
		action_text: String, reason: String, on_press: Callable, badge_color := "") -> void:
	_clear(_detail)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI3Theme.space("16"))
	_detail.add_child(v)
	var ah := CenterContainer.new()
	ah.custom_minimum_size = Vector2(0, 200)
	ah.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if art != null:
		ah.add_child(art)
	v.add_child(ah)
	var th := HBoxContainer.new()
	th.add_theme_constant_override("separation", UI3Theme.space("8"))
	var tl := UI3.label(title, "LabelScreenTitle")
	tl.name = "DetailTitle"
	tl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	th.add_child(tl)
	if badge != "":
		th.add_child(_badge(badge, badge_color))
	v.add_child(th)
	var bl := _note(body)
	bl.name = "DetailBody"
	bl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bl.custom_minimum_size = Vector2(DETAIL_W - 64, 0)
	v.add_child(bl)
	for r in rows:
		var h := HBoxContainer.new()
		var k := UI3.label(String(r[0]), "LabelMuted")
		k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(k)
		h.add_child(UI3.label(String(r[1])))
		v.add_child(h)
	var b := UI3.button(action_text, &"primary", &"L")
	b.name = "DetailBuy"
	if reason != "":
		UI3.set_disabled_reason(b, reason)
		var rl := UI3.label(reason)
		rl.name = "DetailReason"
		rl.theme_type_variation = "LabelMuted"   # a missing resource is not an error
		rl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(rl)
	else:
		b.pressed.connect(on_press)
	v.add_child(b)


# ---------------------------------------------------------------- refresh

func _refresh() -> void:
	if _panel == null:
		return
	var gv := _shell["content"].find_child("value_cur_gem", true, false) as Label
	if gv != null:
		gv.text = UI3.fmt(gems())
	_refresh_strip()
	for t in _tab_btns:
		(_tab_btns[t] as Button).set_pressed_no_signal(t == tab)
	_clear(_body_host)
	_clear(_detail)
	if state == "loading":
		_body_host.add_child(_note("Loading..."))
		return
	if last_result != "":
		var r := UI3.label(last_result, "LabelTitle")
		r.name = "Result"
		_body_host.add_child(r)
	match tab:
		"gem": _tab_gem()
		"moon": _tab_moon()
		"tickets": _tab_tickets()
		"cosmetics": _tab_cosmetics()


func _refresh_strip() -> void:
	_clear(_strip_host)
	var g: Dictionary = _Econ.get_table("gem").get("gift", {})
	var cap := int(g.get("balance_cap", 900))
	var per := int(g.get("per_day", 300))
	_strip_host.add_child(UI3.label("Playtest: Gem is free (%d a day, hold up to %d)" % [per, cap]))
	var now := int(Time.get_unix_time_from_system())
	var claimed_today: bool = MetaState.gem_gift_day != "" and GemWallet.utc_day(now) <= MetaState.gem_gift_day
	var note := ""
	if claimed_today:
		note = "Next claim %s 00:00 UTC" % Time.get_date_string_from_unix_time(GemWallet.next_utc_midnight(now))
	elif gems() >= cap:
		note = "You hold %d, nothing to claim" % gems()
	var nl := UI3.label(note, "LabelMuted")
	nl.name = "GiftNote"
	nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_strip_host.add_child(nl)
	# Secondary: the screen's one primary is the detail plate's buy button.
	var c := UI3.button("Claim %d Gem" % per, &"secondary", &"M")
	c.name = "ClaimGift"
	if _account_blocks():
		UI3.set_disabled_reason(c, "Needs a connection" if state == "offline" else "Sign in to claim")
	elif claimed_today:
		UI3.set_disabled_reason(c, "Already claimed today")
	elif gems() >= cap:
		UI3.set_disabled_reason(c, "Gem full")
	c.pressed.connect(claim_gift)
	_strip_host.add_child(c)


## Tile grid as a VBox of HBox rows (rows and tiles stretch to fill the height; BoxContainer rows).
func _grid(node_name: String, cols: int) -> VBoxContainer:
	var g := VBoxContainer.new()
	g.name = node_name
	g.set_meta("cols", cols)
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.size_flags_vertical = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("separation", UI3Theme.space("16"))
	return g


func _put(g: VBoxContainer, tile: Control) -> void:
	var cols := int(g.get_meta("cols"))
	var row: HBoxContainer = null
	if g.get_child_count() > 0:
		row = g.get_child(g.get_child_count() - 1) as HBoxContainer
	if row == null or row.get_child_count() >= cols:
		row = HBoxContainer.new()
		row.size_flags_vertical = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", UI3Theme.space("16"))
		g.add_child(row)
	row.add_child(tile)


func _tab_gem() -> void:
	var packs := _SB.gem_packs()
	if packs.is_empty():
		return
	if not selected.begins_with("usd_"):
		selected = "usd_%d" % int((packs[0] as Dictionary).gems)
	var grid := _grid("GemGrid", 3)
	var cur: Dictionary = packs[0]
	for pk in packs:
		var n := int((pk as Dictionary).gems)
		var key := "usd_%d" % n
		if key == selected:
			cur = pk
		var t := _tile(key, "Usd_%d" % n)
		var v: VBoxContainer = t[1]
		v.add_child(_gem_art(72))
		_tile_text(v, "%s Gem" % _fmt(n), "$%.2f" % float((pk as Dictionary).usd))
		_put(grid, t[0])
	_body_host.add_child(grid)
	var usd_on := usd_enabled()
	_show_detail(_gem_art(160), "%s Gem" % _fmt(int(cur.gems)), "$%.2f" % float(cur.usd),
		"Gem pays for tickets and cosmetics.", [["You hold", "%s Gem" % _fmt(gems())]],
		"Buy with USD", "" if usd_on else USD_REASON, func() -> void: pass)


func _tab_moon() -> void:
	selected = "moon"
	var mc := _SB.moon_card()
	var grid := _grid("MoonGrid", 1)
	var t := _tile("moon", "MoonTile")
	var v: VBoxContainer = t[1]
	v.add_child(_gem_art(72))
	_tile_text(v, "Moon Card", "%d days" % int(mc.get("days", 30)))
	_put(grid, t[0])
	_body_host.add_child(grid)
	_show_detail(_gem_art(160), "Moon Card", "Coming soon",
		"A daily Gem, ticket and boon for %d days. Not in this playtest." % int(mc.get("days", 30)),
		[["Daily Gem", str(int(mc.get("daily_gem", 0)))], ["Daily tickets", str(int(mc.get("daily_tickets", 0)))]],
		"Buy Moon Card", "Coming soon", func() -> void: pass)
	# keep the old node name for the disabled buy button
	(_detail.find_child("DetailBuy", true, false) as Button).name = "MoonBuy"


func _tab_tickets() -> void:
	var bundles := _SB.bundles()
	if bundles.is_empty():
		return
	if not selected.begins_with("ticket_"):
		selected = "ticket_%d" % int((bundles[0] as Dictionary).tickets)
	var grid := _grid("TicketGrid", 4)
	var cur: Dictionary = bundles[0]
	for bd in bundles:
		var d: Dictionary = bd
		var n := int(d.tickets)
		var key := "ticket_%d" % n
		if key == selected:
			cur = d
		var t := _tile(key, "Ticket_%d" % n)
		var v: VBoxContainer = t[1]
		v.add_child(_gem_art(56))
		_tile_text(v, "%d tickets" % n, "%s Gem" % _fmt(int(d.gems)))
		_put(grid, t[0])
	_body_host.add_child(grid)
	var n2 := int(cur.tickets)
	var price := int(cur.gems)
	_show_detail(null, "%d tickets" % n2, "%s Gem" % _fmt(price), "Adds %d Echo Box tickets." % n2,
		[["Cost", "%s Gem" % _fmt(price)], ["You hold", "%s Gem" % _fmt(gems())]],
		"Buy for %s Gem" % _fmt(price), block_reason(price),
		open_confirm.bind("%d tickets" % n2, "Adds %d Echo Box tickets." % n2, price, buy_bundle.bind(n2)))


func _tab_cosmetics() -> void:
	var items := cosmetic_items()
	if items.is_empty():
		return
	var ids: Array = items.map(func(i: Dictionary) -> String: return "cos_" + String(i.id))
	if not ids.has(selected):
		selected = ids[0]
	var grid := _grid("CosGrid", 4)
	var cur: Dictionary = items[0]
	for it in items:
		var d: Dictionary = it
		var id := String(d.id)
		var key := "cos_" + id
		if key == selected:
			cur = d
		var t := _tile(key, "Cos_" + id)
		var v: VBoxContainer = t[1]
		# 48-store-pass-tiles: 240 x 336 tile, 4 px tier strip, art 208 x 168 on wood-2, name, tier word, action row 48
		(t[0] as Control).custom_minimum_size = Vector2(240, 336)
		v.alignment = BoxContainer.ALIGNMENT_BEGIN
		var tier_idx := maxi(EchoBox.RARITIES.find(String(d.rarity)), 0)
		var strip := ColorRect.new()
		strip.custom_minimum_size = Vector2(0, 4)
		strip.color = DiceSkin.tier_color(tier_idx)
		strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(strip)
		var have := MetaState.cosmetics_owned.has(id)
		var box := Panel.new()
		box.name = "ArtBox"
		box.custom_minimum_size = Vector2(208, 168)
		box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.clip_contents = true
		box.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("panel_raised"), UI3Theme.radius("s")))
		var art := CosmeticTile.art(id, 160.0)
		if art != null:
			art.mouse_filter = Control.MOUSE_FILTER_IGNORE
			art.position = Vector2(24, 4)
			if have:
				art.modulate.a = 0.5   # owned: art at 50%
			box.add_child(art)
		v.add_child(box)
		var nm := CosmeticTile.display_name(id)
		var nl := UI3.label((nm if nm != "" else id).left(18), "LabelTitle")
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(nl)
		var rl := UI3.label(String(d.rarity).capitalize())
		rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rl.add_theme_color_override("font_color", DiceSkin.tier_text_color(tier_idx))
		v.add_child(rl)
		var sp := Control.new()
		sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
		sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(sp)
		if have:
			var ow := UI3.label("Owned", "LabelMuted")
			ow.name = "OwnedWord"
			ow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			ow.custom_minimum_size = Vector2(0, 48)
			ow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			ow.mouse_filter = Control.MOUSE_FILTER_IGNORE
			v.add_child(ow)
		else:
			var chip := UI3.cost_chip(&"gem", int(d.price))
			chip.name = "PriceChip"
			chip.custom_minimum_size = Vector2(0, 48)
			chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
			v.add_child(chip)
		_put(grid, t[0])
	_body_host.add_child(grid)
	var id2 := String(cur.id)
	var price := int(cur.price)
	var nm2 := CosmeticTile.display_name(id2)
	var owned := MetaState.cosmetics_owned.has(id2)
	var art2 := CosmeticTile.art(id2, 160.0)
	_show_detail(art2, nm2 if nm2 != "" else id2, String(cur.rarity).capitalize(),
		"Adds this cosmetic to your collection. Season items: only from the Seasonal Echo Box. Prices are placeholders.",
		[["Cost", "%s Gem" % _fmt(price)], ["You hold", "%s Gem" % _fmt(gems())]],
		"Buy for %s Gem" % _fmt(price), "Owned" if owned else block_reason(price),
		open_confirm.bind(nm2 if nm2 != "" else id2, "Adds this cosmetic to your collection.", price, buy_cosmetic.bind(id2, String(cur.rarity))),
		String(RARITY_TOKEN.get(cur.rarity, "rarity_rare")))
