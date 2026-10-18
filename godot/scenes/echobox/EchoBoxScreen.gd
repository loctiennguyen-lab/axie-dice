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

const DETAIL_W := 440
## Rarity -> UI-03 colour token (the tokens have four tiers; uncommon reads as rare, mythic as legendary).
const RARITY_TOKEN := {"common": "rarity_common", "uncommon": "rarity_rare", "rare": "rarity_rare",
	"epic": "rarity_epic", "legendary": "rarity_legendary", "mythic": "rarity_legendary"}

var _shell: Dictionary
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
			_banner("Can't reach the dice server", "Opening needs a connection; nothing is spent. Cached counts are greyed.", true)
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
	for t in [["regular", "Regular"], ["seasonal", "Seasonal · coming later"]]:
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
	var bar := UI3.plate(&"plate")
	bar.name = "TicketPlate"
	_bar_host = HBoxContainer.new()
	_bar_host.name = "TicketBar"
	_bar_host.add_theme_constant_override("separation", UI3Theme.space("24"))
	bar.add_child(_bar_host)
	_stage_host.add_child(bar)
	_stage_host.move_child(bar, 0)
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


func _refresh_bar() -> void:
	_clear(_bar_host)
	var t := UI3.label("Tickets  %d / 999" % tickets(), "LabelScreenTitle")
	t.name = "Tickets"
	if state == "offline" and remote_on:
		t.modulate.a = 0.6   # cached count
	_bar_host.add_child(t)
	var per := int(_Econ.get_table("echobox").get("fragments_per_ticket", 10))
	var frags := int(MetaState.echobox_pity.get("fragments", 0))
	var fl := UI3.label("Fragments  %d/%d" % [frags, per], "LabelMuted")
	fl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_bar_host.add_child(fl)
	var fb := ProgressBar.new()
	fb.name = "Fragments"
	fb.theme = UI3Theme.get_theme()
	fb.custom_minimum_size = Vector2(220, 16)
	fb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fb.max_value = per
	fb.value = frags
	fb.show_percentage = false
	_bar_host.add_child(fb)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bar_host.add_child(sp)
	var price := next_price()
	var pl := UI3.label("Next ticket  %s Shards" % (UI3.fmt(price) if price >= 0 else "-"), "LabelMuted")
	pl.name = "NextPrice"
	pl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_bar_host.add_child(pl)
	var buy := UI3.button("Buy ticket  %s" % (UI3.fmt(price) if price >= 0 else "max today"), &"secondary", &"S")
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
	# keep the ticket plate (child 0), rebuild the rest
	while _stage_host.get_child_count() > 1:
		var c := _stage_host.get_child(1)
		_stage_host.remove_child(c)
		c.queue_free()
	var seasonal := tab == "seasonal"
	var stage := UI3.plate(&"plate")
	stage.name = "StagePlate"
	stage.custom_minimum_size = Vector2(0, 360)
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var cc := CenterContainer.new()
	stage.add_child(cc)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", UI3Theme.space("16"))
	cc.add_child(v)
	# Chest stand-in (300): tier chest art is not in the build yet.
	var chest := UI3.label("Mystic Chest" if seasonal else "Gold Chest", "LabelScreenTitle")
	chest.name = "Chest"
	chest.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chest.custom_minimum_size = Vector2(0, 200)
	chest.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	v.add_child(chest)
	if seasonal:
		var l := UI3.label("Season box · coming later", "LabelTitle")
		l.name = "ComingLater"
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l)
		# L1: no Open button on the Seasonal tab; EchoBox.open_season does not exist.
	else:
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", UI3Theme.space("16"))
		v.add_child(row)
		var n_big := PULL_N
		var o1 := UI3.button("Open 1", &"secondary", &"M")
		o1.name = "Open1"
		o1.pressed.connect(func() -> void: pull(1))
		var on := UI3.button("Open %d" % n_big, &"primary", &"L")
		on.name = "OpenN"
		on.pressed.connect(func() -> void: pull(n_big))
		var rt := UI3.button("Rates", &"quiet", &"M")
		rt.name = "Rates"
		rt.pressed.connect(open_rates)
		for b in [o1, on]:
			var why := pull_block_reason(1 if b == o1 else n_big)
			if why != "":
				UI3.set_disabled_reason(b, why)   # a disabled button says why
				b.tooltip_text = why
		row.add_child(o1)
		row.add_child(on)
		row.add_child(rt)
		var why1 := pull_block_reason(1)
		# The reason lives inside the disabled buttons only (one place in every state).
		if why1 != "":
			if why1.begins_with("Not enough") and not _account_blocks():
				var sc := UI3.button("Buy enough for 1 pull", &"secondary", &"S")
				sc.name = "BuyEnough"
				sc.pressed.connect(buy_ticket)
				sc.disabled = next_price() < 0 or MetaState.shard_pool < next_price()
				v.add_child(sc)
	_stage_host.add_child(stage)
	if not results.is_empty():
		# the result list takes the room: the stage shrinks, the summary scrolls instead of overflowing
		stage.custom_minimum_size = Vector2(0, 0)
		stage.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		chest.custom_minimum_size = Vector2(0, 80)
		var sc := UI3Meta.scroll(_build_summary())
		sc.name = "SummaryScroll"
		_stage_host.add_child(sc)


func _pity_text() -> String:
	var parts: Array[String] = []
	for s in (box_cfg().get("pity", {}) as Dictionary).get("steps", []):
		parts.append("%s every %d cosmetic pulls" % [String(s["min_rarity"]).capitalize(), int(s["pulls"])])
	return "Guaranteed minimum: " + " · ".join(parts)


func _refresh_side() -> void:
	_clear(_side_host)
	var pity := UI3.plate(&"plate")
	pity.name = "PityPanel"
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI3Theme.space("8"))
	pity.add_child(v)
	v.add_child(UI3.label("Pity · cosmetic pulls only", "LabelTitle"))
	for s in (box_cfg().get("pity", {}) as Dictionary).get("steps", []):
		var rar := String(s["min_rarity"])
		var need := int(s["pulls"])
		var have := mini(int(MetaState.echobox_pity.get("since_" + rar, 0)), need)
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", UI3Theme.space("8"))
		var nm := UI3.label(rar.capitalize())
		nm.custom_minimum_size = Vector2(110, 0)
		r.add_child(nm)
		var pb := ProgressBar.new()
		pb.name = "Pity_" + rar
		pb.theme = UI3Theme.get_theme()
		pb.custom_minimum_size = Vector2(120, 16)
		pb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pb.max_value = need
		pb.value = have
		pb.show_percentage = false
		pb.add_theme_stylebox_override("fill", UI3Theme.flat(_rarity_color(rar), UI3Theme.radius("s")))
		r.add_child(pb)
		r.add_child(UI3.label("%d/%d" % [have, need], "LabelMuted"))
		v.add_child(r)
	_side_host.add_child(pity)
	var pool := UI3.plate(&"plate")
	pool.name = "PoolPanel"
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", UI3Theme.space("8"))
	pool.add_child(pv)
	var total := 0
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", UI3Theme.space("8"))
	grid.add_theme_constant_override("v_separation", UI3Theme.space("8"))
	pv.add_child(UI3.label("Pool", "LabelTitle"))
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
		tile.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("panel"), UI3Theme.radius("m"), 3,
			_rarity_color(String(rar)), Vector4(8, 8, 8, 8)))
		var tl := UI3.label("%s\n%d/%d" % [String(rar).capitalize(), own, c])
		tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tile.add_child(tl)
		grid.add_child(tile)
	pv.add_child(UI3.label("%d cosmetics in the pool" % total, "LabelMuted"))
	_side_host.add_child(pool)
	var dup := UI3.label("A duplicate becomes Fragments; 10 Fragments = 1 ticket. Never Shards.", "LabelMuted")
	dup.name = "DupLine"
	dup.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_side_host.add_child(dup)


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
	v.add_child(UI3.label("%s · %d Stone · %d new · %d duplicates" % [
		"Last pull" if state == "last_pull" else "Result", stone, new_n, dup_n], "LabelTitle"))
	if error_text.begins_with("Opened "):
		var pl := UI3.label(error_text, "LabelMuted")
		pl.name = "PartialPull"
		v.add_child(pl)
	var grid := GridContainer.new()
	grid.name = "ResultGrid"
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", UI3Theme.space("8"))
	grid.add_theme_constant_override("v_separation", UI3Theme.space("8"))
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
	var rar := "common" if String(r.get("kind")) == "stone" else String(r.get("rarity", "common"))
	var c := UI3.plate(&"card")
	c.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("panel"), UI3Theme.radius("m"), 3,
		_rarity_color(rar), Vector4(12, 12, 12, 12)))
	c.custom_minimum_size = Vector2(128, 150)
	var v := VBoxContainer.new()
	c.add_child(v)
	var art: Control = null
	if String(r.get("kind")) == "cosmetic":
		art = CosmeticTile.art(String(r.get("item", "")), 72.0)
	if art != null:
		c.custom_minimum_size = Vector2(128, 230)
		v.add_child(art)
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


func _build_skeleton() -> void:
	var sk := VBoxContainer.new()
	sk.name = "Skeleton"
	sk.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sk.add_child(UI3.skeleton_row(360))
	_col.add_child(sk)


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
	var skip := UI3.button("Skip", &"secondary", &"M")
	skip.name = "Skip"
	skip.tooltip_text = "Space"
	skip.pressed.connect(func() -> void: _skip = true)
	v.add_child(skip)
	var rim := _rarity_color("common" if String(top.get("kind")) == "stone" else String(top.get("rarity", "common")))
	var chest := UI3.label("%s chest" % _chest_tier(top), "LabelScreenTitle")
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
	v.remove_child(skip)
	skip.queue_free()
	(v.get_child(0) as Label).text = "Reveal" if out.size() == 1 else "Open %d" % out.size()
	var grid := GridContainer.new()
	grid.name = "RevealGrid"
	grid.columns = 1 if out.size() == 1 else 5
	grid.add_theme_constant_override("h_separation", UI3Theme.space("8"))
	grid.add_theme_constant_override("v_separation", UI3Theme.space("8"))
	for r in out:
		grid.add_child(_result_cell(r))
	v.add_child(grid)
	var done := UI3.button("Done", &"primary", &"M")
	done.name = "Done"
	done.pressed.connect(func() -> void:
		close_modal()
		_refresh_all())
	v.add_child(done)
	_focus_later(done)
	_refresh_all()
