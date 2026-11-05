class_name DailyScreen
extends Control
## M8 Daily (key D). Spec: design/handoffs/ui-02-round3 README section 2 M8, frames M8a-M8e.
## Three cards: Daily reward (MetaState.claim_daily_mission, idempotent per UTC day), Weekly bonus
## (display only), L1 Gem gift (MetaState.claim_gem_gift_now). Numbers from daily.json / gem.json.
## No live countdown: the next claim is a date plus "00:00 UTC".
## claim_daily_mission grants Shard + Stone + Pass XP; the weekly card shows the day chips (MetaState.weekly_daily_days)
## and pays itself on the last day. "Not yet" on the combo card = not formed today.
## Guest/offline only block claims when the remote wallet flag is on, otherwise an info banner.

const _Econ := preload("res://scripts/meta/economy_db.gd")

## "normal" | "offline" | "guest"
var state := "normal"
var no_scene_change := false
var use_account := true
var remote_on: bool = String(ProjectSettings.get_setting("axie/gem_wallet", "")) == "remote"
var account_status_hook: Callable
var last_result := ""          ## Gem gift claim text (shown in the Gem gift card only)
var daily_result := ""         ## Daily reward claim text (shown in the Daily reward card only)
var day_override := ""


var _shell: Dictionary
var _banner_host: VBoxContainer
var _body: VBoxContainer
var test_mode := false
var sign_in_calls := 0
var daily_result_ok := true
var _combo_host: VBoxContainer


func _ready() -> void:
	_build()
	if use_account:
		state = derive_state()
	set_state(state)
	if MetaState.econ_remote() != null:   # today's claim / week count come from the server snapshot, not an old cache
		MetaState.econ_remote().refresh(func(_r: Dictionary) -> void:
			if is_inside_tree():
				_refresh())
	# Hotfix 5/11: "You hold" and the Gem gift state read the wallet, which the server can fill after this screen
	# is built. Fetch it now and redraw.
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
	if UI3Meta.esc_back(ev, _shell, _on_back):
		if is_inside_tree():   # a handler above may have changed scene
			get_viewport().set_input_as_handled()


func today() -> String:
	return day_override if day_override != "" else MetaState.today_utc()


func _blocks() -> bool:
	return remote_on and state != "normal"


func daily_claimed() -> bool:
	return MetaState.daily_date == today()


## Claims the daily reward once per UTC day. Returns true only when something was granted.
func claim_daily() -> bool:
	if _blocks() or daily_claimed():
		return false
	if MetaState.econ_remote() != null:
		# SR1: the server pays (needs a closed run today); the cache updates from its answer.
		if _daily_pending:
			return false
		_daily_pending = true
		_refresh()
		MetaState.econ_remote().claim("daily", {}, func(r: Dictionary) -> void:
			_daily_pending = false
			daily_result_ok = bool(r["ok"])
			daily_result = "Claimed" if daily_result_ok else RemoteEcon.message_for(String(r["code"]))
			if daily_result_ok and (r["result"] as Dictionary).has("weekly"):
				daily_result += " · weekly bonus paid"
			_refresh()
			if daily_result_ok:
				_play_claim_moment())
		return false
	var ok := MetaState.claim_daily_mission()
	var d: Dictionary = _Econ.get_table("daily").get("daily_reward", {})
	daily_result_ok = ok
	daily_result = "+%s Shards, +%s Stone, +%s Pass XP" % [UI3.fmt(int(d.get("shards", 0))), UI3.fmt(int(d.get("stone", 0))), UI3.fmt(int(d.get("xp", 0)))] if ok else "Already claimed today"
	_refresh()
	if ok:
		_play_claim_moment()
	return ok


## UI-05 b23 lane M3: `daily-claim` (button press + reward rows pop). Only plays what exists here; the chip fly / count rows
## need the shell chips and stay data. Not in instant / headless runs.
func _play_claim_moment() -> void:
	if not is_inside_tree() or _cards_host == null or UI3Gacha.is_instant() or DisplayServer.get_name() == "headless":
		return
	# The cards were just rebuilt: the VBox has not placed the button yet, and the timeline captures `position` as its base.
	# Played at once it would settle the button at (0,0) on top of the reward rows. Wait until the containers have sorted.
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_inside_tree() or _cards_host == null:
		return
	var rows: Array = []
	var card := _cards_host.find_child("DailyCard", true, false)
	for n in ["RewardShards", "RewardStone", "RewardXp"]:
		var row := card.find_child(n, true, false) if card != null else null
		if row != null:
			rows.append(row)
	for r in rows:
		(r as Control).pivot_offset = (r as Control).size / 2.0
	UI3Motion.play_timeline("daily-claim", {"claim_btn": _cards_host.find_child("DailyClaim", true, false), "rows": rows},
		{"host": self, "only": ["claim_press", "rows_pop"]})


var _gift_pending := false
var _daily_pending := false   # a remote daily claim is on its way: the button stays off so a double click sends one request


func claim_gift() -> Dictionary:
	if _blocks():
		return {"ok": false, "reason": "blocked"}
	if GiftClaim.is_remote():
		# Server wallet: the answer comes later. Show "Claiming..." and refresh when it lands.
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


func gift_state() -> String:
	var g: Dictionary = _Econ.get_table("gem").get("gift", {})
	var now := int(Time.get_unix_time_from_system())
	if MetaState.gem_gift_day != "" and GemWallet.utc_day(now) <= MetaState.gem_gift_day:
		return "done"
	if MetaState.gem_wallet().balance() >= int(g.get("balance_cap", 900)):
		return "cap"
	return "claim"



func set_state(s: String) -> void:
	state = s
	if _shell.is_empty():
		return
	UI3Meta.clear(_banner_host)
	if s == "offline":
		_banner_host.add_child(Ui5DailyParts.banner(&"warn", "You are offline" if not remote_on else "Can't reach the server",
			"Claims run on this device for now." if not remote_on else "Claims need a connection."))
	elif s == "guest":
		_banner_host.add_child(Ui5DailyParts.banner(&"info", "You're signed out" if not remote_on else "Sign in to claim",
			"Rewards are kept on this device." if not remote_on else "Guests have no wallet and no rewards.", _sign_in))
	_refresh()


func _sign_in() -> void:
	if test_mode:
		sign_in_calls += 1
		return
	AccountService.sign_in()


func _on_back() -> void:
	if is_inside_tree() and not no_scene_change:
		LandNav.back_to_land()


func _build() -> void:
	_shell = UI3Meta.build(self, "Daily", "Claim once a day, resets 00:00 UTC", _on_back)
	(_shell["panel"] as Control).name = "PlateHost"   # t_ui_laws L0
	(_shell["back"] as Control).name = "BackButton"
	(_shell["sub"] as Control).name = "SubLine"
	var col: VBoxContainer = _shell["col"]
	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(center)
	_body = VBoxContainer.new()
	_body.name = "Body"
	_body.add_theme_constant_override("separation", UI3Theme.space("20"))
	center.add_child(_body)
	_banner_host = VBoxContainer.new()
	_banner_host.name = "BannerHost"
	_body.add_child(_banner_host)
	_cards_host = HBoxContainer.new()
	_cards_host.name = "CardRow"
	_cards_host.add_theme_constant_override("separation", UI3Theme.space("24"))
	_body.add_child(_cards_host)
	_combo_host = VBoxContainer.new()
	_combo_host.name = "ComboHost"
	_body.add_child(_combo_host)


var _cards_host: HBoxContainer


## Weekly strip text: the word says claimed / not yet, so the amber fill is never the only signal.
static func day_chip_text(day: int, claimed: bool) -> String:
	return "Day %d · %s" % [day, "claimed" if claimed else "not yet"]


## Button at the bottom of a card. `label` is the live text, `reason` non-empty = disabled and says why ("label · reason").
func _claim_button(nm: String, label: String, reason: String, cb: Callable, primary: bool, gem_icon := false) -> Button:
	var b: Button
	if primary:
		b = Ui5ClaimButton.make(label, &"L")
	else:
		b = PanelParts.button(label, &"secondary", &"M")
	if gem_icon and reason == "" and not primary:   # frame 41-daily--unclaimed: secondary has the Gem icon; the amber primary has none
		_gem_cluster(b)
	b.name = nm
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if reason != "":
		Ui5DisabledReason.apply(b, reason)
	b.pressed.connect(cb)
	return b


const PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")


## [Gem icon][text] drawn as one centred HBox over the button (Button.icon would overlap the centred text). The button keeps
## its own text (tests, screen readers) but draws it transparent.
func _gem_cluster(b: Button) -> void:
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color", "font_disabled_color"]:
		b.add_theme_color_override(c, Color.TRANSPARENT)
	var h := HBoxContainer.new()
	h.name = "GemCluster"
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_theme_constant_override("separation", UI3Theme.space("12"))
	var ic := PanelParts.icon_rect(UI3.currency_icon("cur_gem", UI3Theme.size_of("icon_s")), UI3Theme.size_of("icon_s"))
	ic.name = "GemIcon"
	h.add_child(ic)
	var l := Ui5Text.label(b.text, "text_title", "text", true)
	l.name = "GemText"
	h.add_child(l)
	b.add_child(h)


func _icon(n: String) -> Texture2D:
	return UI3.currency_icon(n, UI3Theme.size_of("icon_m"))


func _refresh() -> void:
	if _body == null:
		return
	_refresh_combo()
	UI3Meta.clear(_cards_host)
	var cfg := _Econ.get_table("daily")
	var d: Dictionary = cfg.get("daily_reward", {})
	var reset := String(cfg.get("reset", "00:00 UTC"))
	var claimed := daily_claimed()
	var blocked := _blocks()
	var no_wallet := remote_on and state == "guest"
	var why := "Claimed today" if claimed else ("Sign in to claim" if state == "guest" else "Needs a connection")
	var g: Dictionary = _Econ.get_table("gem").get("gift", {})
	var gs := gift_state()
	var daily_ok := not claimed and not blocked and not _daily_pending
	if _daily_pending:
		why = "Claiming…"
	var gift_ok := gs == "claim" and not blocked and not _gift_pending
	var primary_gift := gift_ok and not daily_ok
	var held := 0 if no_wallet else MetaState.gem_wallet().balance()
	# --- DailyCard
	var c := Ui5DailyParts.card("DailyCard")
	var v: VBoxContainer = c["col"]
	v.add_child(Ui5DailyParts.title("Daily reward"))
	var r1 := Ui5DailyParts.kv(_icon("cur_shard"), "Shards", "+" + UI3.fmt(int(d.get("shards", 0))))
	r1.name = "RewardShards"
	v.add_child(r1)
	var r2 := Ui5DailyParts.kv(_icon("cur_stone"), "Stone", "+" + UI3.fmt(int(d.get("stone", 0))))
	r2.name = "RewardStone"
	v.add_child(r2)
	var r3 := Ui5DailyParts.kv(null, "Pass XP", "+" + UI3.fmt(int(d.get("xp", 0))))
	r3.name = "RewardXp"
	v.add_child(r3)
	v.add_child(Ui5DailyParts.note("Claimed. Next one at %s." % reset if claimed else "Finish a run (win or lose) today to claim. Resets at %s." % reset))
	_spacer(v)
	if daily_result != "":
		v.add_child(Ui5DailyParts.result_line(daily_result, &"ok" if daily_result_ok else &"error"))
	v.add_child(_claim_button("DailyClaim", "Claim", "" if daily_ok else "Claim · " + why, claim_daily, true))
	_cards_host.add_child(c["plate"])
	# --- WeeklyCard
	var w: Dictionary = cfg.get("weekly_bonus", {})
	var need := int(w.get("min_days", 4))
	var have := 0 if no_wallet else mini(MetaState.weekly_daily_days(), need)
	var paid := MetaState.weekly_bonus_paid() and not no_wallet
	c = Ui5DailyParts.card("WeeklyCard")
	v = c["col"]
	v.add_child(Ui5DailyParts.title("Weekly bonus"))
	v.add_child(Ui5DailyParts.kv(_icon("cur_shard"), "Shards", "+" + UI3.fmt(int(w.get("shards", 0)))))
	v.add_child(Ui5DailyParts.kv(_icon("cur_stone"), "Stone", "+" + UI3.fmt(int(w.get("stone", 0)))))
	v.add_child(Ui5DailyParts.note("Claim the daily reward on %d days in a week. %d of %d so far.%s" % [need, have, need, " Paid this week." if paid else ""]))
	var grid := GridContainer.new()
	grid.name = "WeekStrip"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", UI3Theme.space("8"))
	grid.add_theme_constant_override("v_separation", UI3Theme.space("8"))
	for i in need:
		grid.add_child(Ui5DailyParts.day_chip(day_chip_text(i + 1, i < have), i < have, "DayChip" if i == 0 else "DayChip%d" % (i + 1)))
	v.add_child(grid)
	_spacer(v)
	var wb := _claim_button("WeeklyStatus", "", "Paid this week" if paid else "%d of %d days · pays on day %d" % [have, need, need], func() -> void: pass, false)
	v.add_child(wb)
	_cards_host.add_child(c["plate"])
	# --- GemGiftCard
	var cap := int(g.get("balance_cap", 900))
	var gem_label := "Claim %d Gem" % int(g.get("per_day", 300))
	var greason := ""
	if _gift_pending:
		gem_label = "Claiming…"
		greason = "Claiming…"
	elif gs == "done":
		greason = gem_label + " · Claimed today"
	elif gs == "cap":
		greason = gem_label + " · At the cap"
	elif not gift_ok:
		greason = gem_label + " · " + why
	c = Ui5DailyParts.card("GemGiftCard", true)
	v = c["col"]
	v.add_child(Ui5DailyParts.title("Gem gift"))
	v.add_child(Ui5DailyParts.kv(_icon("cur_gem"), "Gem a day", "+" + UI3.fmt(int(g.get("per_day", 300)))))
	v.add_child(Ui5DailyParts.kv(_icon("cur_gem"), "You hold", UI3.fmt(held)))
	v.add_child(Ui5DailyParts.kv(_icon("cur_gem"), "Hold up to", UI3.fmt(cap)))
	v.add_child(Ui5DailyParts.note("Free Gems during the beta. You can hold up to %s." % UI3.fmt(cap) if gs != "cap" else "You hold %s, nothing to claim." % UI3.fmt(held)))
	_spacer(v)
	if last_result != "" and not _gift_pending:
		v.add_child(Ui5DailyParts.result_line(last_result, &"ok" if last_result.begins_with("+") else &"error"))
	v.add_child(_claim_button("GemClaim", gem_label, greason, claim_gift, primary_gift, true))
	_cards_host.add_child(c["plate"])
	call_deferred("_focus_first")


func _spacer(v: Control) -> void:
	var sp := Control.new()
	sp.name = "Grow"
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sp)


## Initial / post-claim focus: the first claim that can be pressed, else the back button.
func _focus_first() -> void:
	if not is_inside_tree():
		return
	for n in ["DailyClaim", "GemClaim"]:
		var b := find_child(n, true, false) as Button
		if b != null and not b.disabled:
			b.grab_focus()
			return
	var back := find_child("BackButton", true, false) as Control
	if back != null:
		back.grab_focus()


## Daily challenge "Form combo X" (lane GM D2): wide card under the three claim cards. Done = Pair or Full formed today
## in any run. Reward is a title only (Combo Maker on the 1st, Combo Master on the 7th), never Shards.
func _refresh_combo() -> void:
	if _combo_host == null:
		return
	UI3Meta.clear(_combo_host)
	var t := MetaState.combo_daily_today()
	var cid := String(t["id"])
	if cid == "":
		return
	var done := bool(t["done"])
	var box := PanelParts.plate_box("l", 0)
	box.content_margin_left = UI3Theme.space("20")
	box.content_margin_right = UI3Theme.space("20")
	box.content_margin_top = UI3Theme.space("16")
	box.content_margin_bottom = UI3Theme.space("16")
	var p := PanelParts.panel(box, "ComboCard")
	p.custom_minimum_size.x = UI3Theme.size_of("daily_card_w") * 3 + UI3Theme.space("24") * 2
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UI3Theme.space("16"))
	p.add_child(h)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(left)
	var tl := Ui5Text.label("Form combo: %s" % UI3.title_case(ComboAdapter.display_name(cid)), "text_title", "text", true)
	tl.name = "Title"
	left.add_child(tl)
	var cores: Array[String] = []
	for cc in ComboAdapter.pair_cores(cid):
		cores.append(RunCard.core_name(String(cc)))
	var sub := Ui5Text.label("Hold %s in one run. Pair or Full both count." % " + ".join(cores), "text_body", "text")
	sub.name = "Sub"
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(sub)
	var n := int(t["count"])
	var next_title := "Combo Maker" if n < 1 else ("Combo Master" if n < 7 else "")
	var reward := Ui5Text.label("Reward: title %s (%d done)" % [next_title, n] if next_title != "" else "%d done" % n, "text_body", "text_muted")
	reward.name = "Reward"
	left.add_child(reward)
	h.add_child(Ui5DailyParts.status_chip(done))
	_combo_host.add_child(p)
