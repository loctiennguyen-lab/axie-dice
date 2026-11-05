class_name StoreScreen
extends Control
## Store (key 7), UI-05 frames 19-store* (ui05-meta2-screens.html). Header tabs (Ui5TabBar), GiftStrip, tile Grid, Ui5DetailPlate.
## Nothing is picked at first; the detail plate says "Pick an item". Buy is the amber primary; the free Gem gift is amber
## primary S while no Buy is live, else a secondary with the Gem icon. The confirm dialog (BuyConfirm) puts focus on Not now.
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
const PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")
const VIOLET := Color("6B4AA8")
const TABS := ["gem", "cosmetics", "tickets", "moon"]
const TAB_NAMES := {"gem": "Gem packs", "cosmetics": "Cosmetics", "tickets": "Tickets", "moon": "Moon Card"}
const PICK := "Pick an item"
const PICK_BODY := "Select a tile to see its price and what it adds."
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
var _strip_host: VBoxContainer
var _result_host: VBoxContainer
var _body_host: VBoxContainer
var _modal_layer: Control
var _tab_btns: Dictionary = {}
var _detail: Ui5DetailPlate
var last_ok := true
var sign_in_calls := 0
var test_mode := false
var _first_focus_done := false
## Selected tile key per tab ("" = first item). Tiles only select; the buy action is the detail plate.
var selected := ""


func _ready() -> void:
	_build()
	if use_account:
		state = derive_state()
	set_state(state)
	# Hotfix 5/11: the server Gem wallet can answer after this screen is built (Land showed Gem 0 next to a 900
	# wallet). Fetch it now and redraw, so prices, "need N more" and the gift card use the real balance.
	var gw := MetaState.gem_wallet()
	if gw.has_method("refresh"):
		gw.call("refresh", func(_ok: bool) -> void:
			if is_inside_tree():
				_refresh())


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
	last_ok = code == ""
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
			_banner_host.add_child(Ui5DailyParts.banner(&"warn", "Can't reach the server" if remote_on else "You're offline",
				"Spending Gem needs a connection; nothing is spent." if remote_on else "Gem purchases run on this device for now."))
		"guest":
			_banner_host.add_child(Ui5DailyParts.banner(&"info", "Sign in to spend Gem" if remote_on else "You're signed out",
				"Guests can read every price." if remote_on else "Purchases are kept on this device. Sign in to keep them.", _sign_in))
	_refresh()


func _sign_in() -> void:
	if test_mode:
		sign_in_calls += 1
		return
	AccountService.sign_in()


## Selects a tile (key like "usd_80", "ticket_6", "cos_<id>", "moon"). Selecting again keeps it picked.
func select(key: String) -> void:
	selected = key
	_refresh()


func set_tab(t: String) -> void:
	tab = t
	last_result = ""
	selected = ""
	_refresh()


## BuyConfirm (frame 19-store--confirm): Title, Body, Cost row, Footer [Not now + Space][Buy]. Focus starts on Not now.
func open_confirm(title: String, detail: String, price: int, action: Callable) -> void:
	close_modal()
	var root := UI3.ModalRoot.new()
	root.theme = UI3Theme.get_theme()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.name = "Modal"
	root.add_to_group("ui3_modal")
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
	var dlg := PanelParts.panel(PanelParts.plate_box("xl", UI3Theme.space("32")), "BuyConfirm")
	dlg.custom_minimum_size.x = UI3Theme.size_of("defeat_panel_w")
	center.add_child(dlg)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UI3Theme.space("20"))
	dlg.add_child(col)
	var head := VBoxContainer.new()
	head.add_theme_constant_override("separation", UI3Theme.space("4"))
	col.add_child(head)
	var ttl := Ui5Text.label(title, "text_banner", "text", true)
	ttl.name = "Title"
	ttl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head.add_child(ttl)
	var bl := Ui5Text.label(detail, "text_body", "text")
	bl.name = "Body"
	bl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head.add_child(bl)
	col.add_child(Ui5ProfileParts.kv("Cost", "%s Gem" % _fmt(price), "CostRow"))
	var no := PanelParts.button("Not now", &"secondary", &"M")
	no.name = "NotNowButton"
	no.pressed.connect(close_modal)
	var yes := PanelParts.button("Buy for %s Gem" % _fmt(price), &"primary", &"M")
	yes.name = "BuyButton"
	var why := block_reason(price)
	if why != "":
		Ui5DisabledReason.apply(yes, why)
	else:
		yes.pressed.connect(func() -> void:
			close_modal()
			action.call())
	col.add_child(Ui5ModalFooter.make(yes, no))
	root.actions = [no, yes]
	root.focus_index = 0
	root.cancelled.connect(close_modal)
	_modal_layer.add_child(root)
	var cap := Ui5Keycap.make("Space")
	no.add_child(cap)
	Ui5HudStyle.place_trailing(no, cap, UI3Theme.space("24"))
	no.resized.connect(func() -> void:
		if is_instance_valid(cap):
			Ui5HudStyle.place_trailing(no, cap, UI3Theme.space("24")))


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
		last_ok = true
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
	last_ok = ok
	if not is_inside_tree():
		return
	_refresh()
	if not ok and String(r.get("reason", "")) != "already_claimed" and String(r.get("reason", "")) != "at_cap":
		GiftClaim.toast(self, text, &"error")


func _on_back() -> void:
	if is_inside_tree() and not no_scene_change:
		LandNav.back_to_land()


# ---------------------------------------------------------------- build

func _build() -> void:
	_shell = UI3Meta.build(self, "Store", "Gem packs, cosmetics, tickets", _on_back)
	(_shell["back"] as Control).name = "BackButton"
	(_shell["sub"] as Control).name = "SubLine"
	_panel = _shell["panel"]
	_panel.name = "PlateHost"   # t_ui_laws L0
	_modal_layer = _shell["modal_layer"]
	var col: VBoxContainer = _shell["col"]
	_banner_host = _shell["banner_host"]
	var cur := find_child("Currencies", true, false)
	if cur != null:
		cur.visible = false   # frame: the header plate holds Back, Title, SubLine and the tabs only
	var hr: Control = _shell["header_right"]
	var trow := (_shell["sub"] as Control).get_parent()
	hr.get_parent().remove_child(hr)
	hr.name = "Tabs"
	trow.add_child(hr)
	var bar := Ui5TabBar.new()
	bar.setup(TABS.map(func(t: String) -> String: return String(TAB_NAMES[t])), TABS.find(tab), true)
	bar.name = "TabBar"
	hr.add_child(bar)
	var node_names := ["GemPacksTab", "CosmeticsTab", "TicketsTab", "MoonCardTab"]
	for i in TABS.size():
		var b := bar.get_child(i) as Button
		b.name = node_names[i]
		_tab_btns[TABS[i]] = b
	bar.tab_selected.connect(func(i: int) -> void: set_tab(TABS[i]))
	var row := HBoxContainer.new()
	row.name = "Body"
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", UI3Theme.space("24"))
	col.add_child(row)
	var left := VBoxContainer.new()
	left.name = "Left"
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", UI3Theme.space("16"))
	row.add_child(left)
	_strip_host = VBoxContainer.new()
	_strip_host.name = "StripHost"
	left.add_child(_strip_host)
	_result_host = VBoxContainer.new()
	_result_host.name = "ResultHost"
	left.add_child(_result_host)
	_body_host = VBoxContainer.new()
	_body_host.name = "GridHost"
	_body_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sc := UI3Meta.scroll(_body_host)
	sc.name = "GridScroll"
	left.add_child(sc)
	_detail = Ui5DetailPlate.new()
	_detail.setup("store_detail_w", PICK, PICK_BODY, PICK)
	row.add_child(_detail)
	# Title + body live in their own VBox "Info", apart from the art: the Title is the item's heading (left, as in the frame),
	# not a label of the Gem icon, so ui5_align_check must not pair it with the art.
	var scol := _detail.scroll.get_child(0)
	var info := VBoxContainer.new()
	info.name = "Info"
	info.add_theme_constant_override("separation", UI3Theme.space("8"))
	scol.add_child(info)
	for c in [_detail.title, _detail.body]:
		c.get_parent().remove_child(c)
		info.add_child(c)


func _clear(n: Node) -> void:
	UI3Meta.clear(n)


func _fmt(n: int) -> String:
	return UI3.fmt(n)


## Detail plate content for the picked item. `reason` != "" disables the primary and replaces its label.
func _show_detail(art: Control, title: String, body: String, rows: Array, action_text: String, reason: String, on_press: Callable) -> void:
	_detail.show_item(title)
	var ab := Ui5StoreParts.art_box(art, 200)
	ab.name = "DetailArt"
	var inner := _detail.scroll.get_child(0)
	inner.add_child(ab)
	inner.move_child(ab, 0)
	_detail.add_line(body)
	for r in rows:
		_detail.body.add_child(Ui5ProfileParts.kv(String(r[0]), String(r[1]), "Row"))
	var b := _detail.set_primary(action_text, reason)
	b.name = "BuyButton"
	if reason == "":
		b.pressed.connect(on_press)


func _show_empty() -> void:
	_detail.show_empty()
	var inner := _detail.scroll.get_child(0)
	var ab := Ui5StoreParts.art_box(null, 200)
	ab.name = "DetailArt"
	inner.add_child(ab)
	inner.move_child(ab, 0)
	_detail.primary.name = "BuyButton"


func _buy_reason(price: int) -> String:
	var why := block_reason(price)
	return ("Buy · " + why) if why.begins_with("need") else why


# ---------------------------------------------------------------- refresh

func _refresh() -> void:
	if _panel == null:
		return
	var fo := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	var focus_name := String(fo.name) if fo != null and is_ancestor_of(fo) else ""
	for t in _tab_btns:
		(_tab_btns[t] as Button).set_pressed_no_signal(t == tab)
	_clear(_body_host)
	_clear(_result_host)
	if state == "loading":
		_body_host.add_child(Ui5Text.label("Loading…", "text_body", "text_muted"))
		_show_empty()
		_refresh_strip(false)
		return
	_remove_detail_art()
	match tab:
		"gem": _tab_gem()
		"moon": _tab_moon()
		"tickets": _tab_tickets()
		"cosmetics": _tab_cosmetics()
	var live := _detail.primary != null and not _detail.primary.disabled
	_refresh_strip(live)
	if last_result != "":
		_result_host.add_child(Ui5DailyParts.result_line(last_result, &"ok" if last_ok else &"error"))
	_restore_focus.call_deferred(focus_name)


func _remove_detail_art() -> void:
	var inner := _detail.scroll.get_child(0)
	for c in inner.get_children():
		if c.name == "DetailArt":
			inner.remove_child(c)
			c.queue_free()


func _restore_focus(nm: String) -> void:
	if not is_inside_tree():
		return
	var n: Control = null
	if nm != "":
		n = find_child(nm, true, false) as Control
		if n is BaseButton and (n as BaseButton).disabled:
			n = null
	if n == null and not _first_focus_done:
		_first_focus_done = true
		n = _tab_btns[tab] as Control
	elif n == null and get_viewport().gui_get_focus_owner() == null:
		n = _tab_btns[tab] as Control
	if n != null:
		n.grab_focus()


func _refresh_strip(buy_live: bool) -> void:
	_clear(_strip_host)
	var g: Dictionary = _Econ.get_table("gem").get("gift", {})
	var cap := int(g.get("balance_cap", 900))
	var per := int(g.get("per_day", 300))
	var now := int(Time.get_unix_time_from_system())
	var claimed_today: bool = MetaState.gem_gift_day != "" and GemWallet.utc_day(now) <= MetaState.gem_gift_day
	var note := ""
	if claimed_today:
		note = "Next claim %s 00:00 UTC" % Time.get_date_string_from_unix_time(GemWallet.next_utc_midnight(now))
	elif gems() >= cap:
		note = "You hold %d, nothing to claim" % gems()
	var label := "Claim %d Gem" % per
	var reason := ""
	if _account_blocks():
		reason = "Needs a connection" if state == "offline" else "Sign in to claim"
	elif claimed_today:
		reason = "Already claimed today"
	elif gems() >= cap:
		reason = "Gem full"
	var c: Button
	if reason != "":
		c = Ui5ClaimButton.secondary_with_gem(label + " · " + reason)
		c.icon = null
		Ui5DisabledReason.apply(c, label + " · " + reason)
	elif buy_live:
		c = Ui5ClaimButton.secondary_with_gem(label)
		c.icon = null
		Ui5StoreParts.gem_cluster(c)
	else:
		c = Ui5ClaimButton.make(label, &"S")
	c.name = "GiftButton"
	c.pressed.connect(claim_gift)
	_strip_host.add_child(Ui5StoreParts.gift_strip("Playtest: Gem is free (%d a day, hold up to %d)" % [per, cap], note, c))


## Grid of tiles (cols columns) with equal cells.
func _grid(node_name: String, cols: int) -> GridContainer:
	var g := GridContainer.new()
	g.name = node_name
	g.columns = cols
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", UI3Theme.space("16"))
	g.add_theme_constant_override("v_separation", UI3Theme.space("16"))
	return g


func _label(t: String, tok: String, clr := "text", disp := false) -> Label:
	var l := Ui5Text.label(t, tok, clr, disp)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	return l


func _tab_gem() -> void:
	var packs := _SB.gem_packs()
	var grid := _grid("Grid", 3)
	var cur := {}
	for pk in packs:
		var n := int((pk as Dictionary).gems)
		var key := "usd_%d" % n
		if key == selected:
			cur = pk
		var t := Ui5StoreParts.tile("GemPackTile_%d" % n, key == selected, UI3Theme.color("gem_border"))
		var v := t.get_node("Col") as VBoxContainer
		v.add_child(Ui5StoreParts.art_box(Ui5StoreParts.gem_art(72)))
		v.add_child(_label("%s Gem" % _fmt(n), "text_title"))
		v.add_child(_label("$%.2f" % float((pk as Dictionary).usd), "text_body", "text_muted"))
		t.pressed.connect(select.bind(key))
		grid.add_child(t)
	_body_host.add_child(grid)
	if cur.is_empty():
		_show_empty()
		return
	_show_detail(Ui5StoreParts.gem_art(120), "%s Gem" % _fmt(int(cur.gems)),
		"Gem pays for tickets and cosmetics.", [["You hold", "%s Gem" % _fmt(gems())]],
		"Buy with USD", "" if usd_enabled() else USD_REASON, func() -> void: pass)


func _tab_moon() -> void:
	var mc := _SB.moon_card()
	var grid := _grid("Grid", 1)
	var t := Ui5StoreParts.tile("MoonCardTile", true, UI3Theme.color("accent"))
	var v := t.get_node("Col") as VBoxContainer
	v.add_child(Ui5StoreParts.art_box(Ui5StoreParts.gem_art(72)))
	v.add_child(_label("Moon Card", "text_title"))
	v.add_child(_label("%d days" % int(mc.get("days", 30)), "text_body", "text_muted"))
	t.pressed.connect(select.bind("moon"))
	grid.add_child(t)
	_body_host.add_child(grid)
	selected = "moon"
	_show_detail(Ui5StoreParts.gem_art(120), "Coming soon",
		"A daily Gem, ticket and boon for %d days. Not in this playtest." % int(mc.get("days", 30)),
		[["Daily Gem", str(int(mc.get("daily_gem", 0)))], ["Daily tickets", str(int(mc.get("daily_tickets", 0)))]],
		"Buy Moon Card", "Buy Moon Card · Coming soon", func() -> void: pass)


func _tab_tickets() -> void:
	var grid := _grid("Grid", 4)
	var cur := {}
	for bd in _SB.bundles():
		var d: Dictionary = bd
		var n := int(d.tickets)
		var key := "ticket_%d" % n
		if key == selected:
			cur = d
		var t := Ui5StoreParts.tile("TicketTile_%d" % n, key == selected, UI3Theme.color("accent"))
		var v := t.get_node("Col") as VBoxContainer
		v.add_child(Ui5StoreParts.art_box(Ui5StoreParts.gem_art(72)))
		v.add_child(_label("%d tickets" % n, "text_title"))
		v.add_child(Ui5StoreParts.gem_cost_wide(int(d.gems)))
		t.pressed.connect(select.bind(key))
		grid.add_child(t)
	_body_host.add_child(grid)
	if cur.is_empty():
		_show_empty()
		return
	var n2 := int(cur.tickets)
	var price := int(cur.gems)
	_show_detail(Ui5StoreParts.gem_art(120), "%d tickets" % n2, "Adds %d Echo Box tickets." % n2,
		[["Cost", "%s Gem" % _fmt(price)], ["You hold", "%s Gem" % _fmt(gems())]],
		"Buy for %s Gem" % _fmt(price), _buy_reason(price),
		open_confirm.bind("%d tickets" % n2, "Adds %d Echo Box tickets." % n2, price, buy_bundle.bind(n2)))


func _tab_cosmetics() -> void:
	var grid := _grid("Grid", 4)
	var cur := {}
	for it in cosmetic_items():
		var d: Dictionary = it
		var id := String(d.id)
		var key := "cos_" + id
		if key == selected:
			cur = d
		var tier_idx := maxi(EchoBox.RARITIES.find(String(d.rarity)), 0)
		var have := MetaState.cosmetics_owned.has(id)
		var t := Ui5StoreParts.tile("CosmeticTile_" + id, key == selected, DiceSkin.tier_color(tier_idx))
		var v := t.get_node("Col") as VBoxContainer
		var art := CosmeticTile.art(id, UI3Theme.size_of("cos_art"))
		if art != null and have:
			art.modulate.a = 0.5
		v.add_child(Ui5StoreParts.art_box(art))
		var nm := CosmeticTile.display_name(id)
		v.add_child(_label(nm if nm != "" else id, "text_title"))
		var rl := _label(String(d.rarity).capitalize(), "text_body")
		rl.add_theme_color_override("font_color", DiceSkin.tier_text_color(tier_idx))
		v.add_child(rl)
		v.add_child(Ui5StoreParts.owned_button() if have else Ui5StoreParts.gem_cost_wide(int(d.price)))
		t.pressed.connect(select.bind(key))
		grid.add_child(t)
	_body_host.add_child(grid)
	if cur.is_empty():
		_show_empty()
		return
	var id2 := String(cur.id)
	var price := int(cur.price)
	var nm2 := CosmeticTile.display_name(id2)
	var nm3 := nm2 if nm2 != "" else id2
	var owned := MetaState.cosmetics_owned.has(id2)
	_show_detail(CosmeticTile.art(id2, UI3Theme.size_of("cos_art")), nm3,
		"%s. Adds this cosmetic to your collection. Season items: only from the Seasonal Echo Box." % String(cur.rarity).capitalize(),
		[["Cost", "%s Gem" % _fmt(price)], ["You hold", "%s Gem" % _fmt(gems())]],
		"Buy for %s Gem" % _fmt(price), "Owned" if owned else _buy_reason(price),
		open_confirm.bind(nm3, "Adds this cosmetic to your collection.", price, buy_cosmetic.bind(id2, String(cur.rarity))))
