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
const USD_REASON := "Buying disabled in the playtest"
const RARITY_TOKEN := {"rare": "rarity_rare", "epic": "rarity_epic", "legendary": "rarity_legendary", "mythic": "rarity_legendary"}
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
	UI3Meta.clear(_banner_host)
	match s:
		"offline":
			UI3Meta.banner(_banner_host, "Can't reach the dice server" if remote_on else "You're offline",
				"Spending Gem needs a connection; nothing is spent." if remote_on else "Gem purchases run on this device for now.")
		"guest":
			UI3Meta.banner(_banner_host, "Sign in to spend Gem" if remote_on else "You're signed out",
				"Guests can read every price." if remote_on else "Purchases are kept on this device. Sign in to keep them.")
	_refresh()


func set_tab(t: String) -> void:
	tab = t
	last_result = ""
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
	yes.pressed.connect(func() -> void:
		close_modal()
		action.call())
	var m := UI3.modal(title, "%s\nCost %d Gem. You hold %d." % [detail, price, gems()], [no, yes], 0)
	m.cancelled.connect(close_modal)
	_modal_layer.add_child(m)


func close_modal() -> void:
	UI3Meta.clear(_modal_layer)


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
	_body_host = VBoxContainer.new()
	_body_host.name = "Body"
	_body_host.add_theme_constant_override("separation", UI3Theme.space("16"))
	col.add_child(UI3Meta.scroll(_body_host))


func _clear(n: Node) -> void:
	UI3Meta.clear(n)


func _fmt(n: int) -> String:
	return UI3.fmt(n)


func _note(text: String) -> Label:
	var l := UI3.label(text, "LabelMuted")
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _grid(node_name: String, cols: int) -> GridContainer:
	var g := GridContainer.new()
	g.name = node_name
	g.columns = cols
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", UI3Theme.space("16"))
	g.add_theme_constant_override("v_separation", UI3Theme.space("16"))
	return g


func _tile() -> Array:
	var p := UI3.plate(&"card")
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI3Theme.space("8"))
	p.add_child(v)
	return [p, v]


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
	var c := UI3.button("Claim %d Gem" % per, &"primary", &"M")
	c.name = "ClaimGift"
	if _account_blocks():
		UI3.set_disabled_reason(c, "Needs a connection" if state == "offline" else "Sign in to claim")
	elif claimed_today:
		UI3.set_disabled_reason(c, "Already claimed today")
	elif gems() >= cap:
		UI3.set_disabled_reason(c, "Gem full")
	c.pressed.connect(claim_gift)
	_strip_host.add_child(c)
	var buy := UI3.button("Buy Gem", &"secondary", &"M")
	buy.name = "BuyGem"
	_disable_usd(buy)
	_strip_host.add_child(buy)


func _disable_usd(b: Button) -> void:
	if not usd_enabled():
		UI3.set_disabled_reason(b, USD_REASON)


func _tab_gem() -> void:
	var grid := _grid("GemGrid", 3)
	for pk in _SB.gem_packs():
		var n := int((pk as Dictionary).gems)
		var t := _tile()
		var v: VBoxContainer = t[1]
		v.add_child(UI3.label("%s Gem" % _fmt(n), "LabelTitle"))
		v.add_child(UI3.label("$%.2f" % float((pk as Dictionary).usd), "LabelMuted"))
		var b := UI3.button("Buy with USD", &"secondary", &"M")
		b.name = "Usd_%d" % n
		_disable_usd(b)
		v.add_child(b)
		grid.add_child(t[0])
	_body_host.add_child(grid)


func _tab_moon() -> void:
	var t := _tile()
	var v: VBoxContainer = t[1]
	var mc := _SB.moon_card()
	v.add_child(UI3.label("Moon Card", "LabelTitle"))
	v.add_child(_note("A daily Gem, ticket and boon for %d days. Coming soon: not in this playtest." % int(mc.get("days", 30))))
	var b := UI3.button("Buy Moon Card", &"secondary", &"M")
	b.name = "MoonBuy"
	UI3.set_disabled_reason(b, "Coming soon")
	v.add_child(b)
	(t[0] as Control).size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	(t[0] as Control).custom_minimum_size.x = 560
	_body_host.add_child(t[0])


func _tab_tickets() -> void:
	var grid := _grid("TicketGrid", 4)
	for bd in _SB.bundles():
		var d: Dictionary = bd
		var n := int(d.tickets)
		var price := int(d.gems)
		var t := _tile()
		var v: VBoxContainer = t[1]
		v.add_child(UI3.label("%d tickets" % n, "LabelTitle"))
		v.add_child(UI3.label("Echo Box tickets", "LabelMuted"))
		var why := block_reason(price)
		var b := UI3.button("%s Gem" % _fmt(price), &"secondary", &"M")
		b.name = "Ticket_%d" % n
		if why != "":
			UI3.set_disabled_reason(b, why)
		b.pressed.connect(open_confirm.bind("%d tickets" % n, "Adds %d Echo Box tickets." % n, price, buy_bundle.bind(n)))
		v.add_child(b)
		grid.add_child(t[0])
	_body_host.add_child(grid)


func _tab_cosmetics() -> void:
	var grid := _grid("CosGrid", 4)
	for it in cosmetic_items():
		var d: Dictionary = it
		var id := String(d.id)
		var price := int(d.price)
		var owned := MetaState.cosmetics_owned.has(id)
		var t := _tile()
		var v: VBoxContainer = t[1]
		var art := CosmeticTile.art(id, 72.0)
		if art != null:
			v.add_child(art)
		var nm := CosmeticTile.display_name(id)
		var nl := UI3.label(nm if nm != "" else id, "LabelTitle")
		nl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		v.add_child(nl)
		var rl := UI3.label(String(d.rarity).capitalize(), "LabelMuted")
		rl.add_theme_color_override("font_color", UI3Theme.color(String(RARITY_TOKEN.get(d.rarity, "rarity_rare"))))
		v.add_child(rl)
		var why := "Owned" if owned else block_reason(price)
		var b := UI3.button("%s Gem" % _fmt(price), &"secondary", &"M")
		b.name = "Cos_" + id
		if why != "":
			UI3.set_disabled_reason(b, why)
		b.pressed.connect(open_confirm.bind(id if nm == "" else nm, "Adds this cosmetic to your collection.", price, buy_cosmetic.bind(id, String(d.rarity))))
		v.add_child(b)
		grid.add_child(t[0])
	_body_host.add_child(grid)
	_body_host.add_child(_note("Season items: only from the Seasonal Echo Box. Cosmetic prices are placeholders."))
