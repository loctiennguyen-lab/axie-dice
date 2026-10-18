class_name DailyScreen
extends Control
## M8 Daily (key D). Spec: design/handoffs/ui-02-round3 README section 2 M8, frames M8a-M8e.
## Three cards: Daily reward (MetaState.claim_daily_mission, idempotent per UTC day), Weekly bonus
## (display only), L1 Gem gift (MetaState.claim_gem_gift_now). Numbers from daily.json / gem.json.
## No live countdown: the next claim is a date plus "00:00 UTC".
## GAPS (lane E/S): claim_daily_mission grants Shard + Pass XP but not the 500 Stone in daily.json,
## so Stone is not promised on the card; there is no "finished a run today" flag (M8b "Not yet") and
## no weekly day counter (dots), so the weekly card shows the rule only.
## Guest/offline only block claims when the remote wallet flag is on, otherwise an info banner.

const _Econ := preload("res://scripts/meta/economy_db.gd")

## "normal" | "offline" | "guest"
var state := "normal"
var no_scene_change := false
var use_account := true
var remote_on: bool = String(ProjectSettings.get_setting("axie/gem_wallet", "")) == "remote"
var account_status_hook: Callable
var last_result := ""
var day_override := ""

const CARD_W := 416

var _shell: Dictionary
var _banner_host: VBoxContainer
var _body: HBoxContainer


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
	if UI3Meta.esc_back(ev, _shell, _on_back):
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
	var ok := MetaState.claim_daily_mission()
	var d: Dictionary = _Econ.get_table("daily").get("daily_reward", {})
	last_result = "+%d Shard, +%d Stone, +%d Pass XP" % [int(d.get("shards", 0)), int(d.get("stone", 0)), int(d.get("xp", 0))] if ok else "Already claimed today"
	_refresh()
	return ok


func claim_gift() -> Dictionary:
	if _blocks():
		return {"ok": false, "reason": "blocked"}
	var r := MetaState.claim_gem_gift_now()
	match String(r.get("reason", "")):
		"": last_result = "+%d Gem" % int(r.get("granted", 0))
		"already_claimed": last_result = "Gem gift already claimed today"
		"at_cap": last_result = "You hold the maximum, nothing to claim"
	_refresh()
	return r


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
		_banner("You are offline" if not remote_on else "Can't reach the dice server",
			"Claims run on this device for now." if not remote_on else "Claims need a connection.")
	elif s == "guest":
		_banner("You're signed out" if not remote_on else "Sign in to claim",
			"Rewards are kept on this device." if not remote_on else "Guests have no wallet and no rewards.")
	_refresh()


func _on_back() -> void:
	if is_inside_tree() and not no_scene_change:
		LandNav.back_to_land()


func _build() -> void:
	_shell = UI3Meta.build(self, "Daily", "Claim once a day, resets 00:00 UTC", _on_back)
	(_shell["panel"] as Control).name = "PlateHost"   # t_ui_laws L0
	_banner_host = _shell["banner_host"]
	var col: VBoxContainer = _shell["col"]
	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(center)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI3Theme.space("24"))
	center.add_child(v)
	_body = HBoxContainer.new()
	_body.name = "Body"
	_body.add_theme_constant_override("separation", UI3Theme.space("24"))
	v.add_child(_body)
	var close := UI3.button("Close", &"secondary", &"M")
	close.name = "Close"
	close.tooltip_text = "Esc"
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(_on_back)
	v.add_child(close)


func _banner(msg: String, detail: String) -> void:
	UI3Meta.banner(_banner_host, msg, detail)


## One 416 card: title, sub-line, item rows [[label, value]], optional extra control, optional button.
func _card(name_: String, title: String, sub: String, items: Array, btn: Button, extra: Control = null) -> Control:
	var p := UI3.plate(&"card")
	p.name = name_
	p.custom_minimum_size = Vector2(CARD_W, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI3Theme.space("16"))
	p.add_child(v)
	v.add_child(UI3.label(title, "LabelScreenTitle"))
	var t := UI3.label(sub, "LabelMuted")
	t.name = "Sub"
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	for it in items:
		var r := UI3.plate(&"row")
		r.custom_minimum_size = Vector2(0, 48)
		var h := HBoxContainer.new()
		r.add_child(h)
		var l := UI3.label(String(it[0]))
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(l)
		h.add_child(UI3.label(String(it[1]), "LabelTitle"))
		v.add_child(r)
	if extra != null:
		v.add_child(extra)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sp)
	if btn != null:
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(btn)
	return p


## Same 72 px row on every card. Only the first claimable card gets the primary look.
func _claim_button(nm: String, text: String, claimable: bool, reason: String, cb: Callable, primary: bool) -> Button:
	var b := UI3.button(text, &"primary" if primary else &"secondary", &"L" if primary else &"M")
	b.name = nm
	b.custom_minimum_size.y = 72
	if not claimable:
		UI3.set_disabled_reason(b, reason)
	b.pressed.connect(cb)
	return b


## Day chip: claimed = amber chip, still to come = outlined plate with normal text (never dimmed).
func _day_chip(text: String, done: bool) -> Control:
	if done:
		return UI3.chip(text)
	var p := PanelContainer.new()
	p.theme = UI3Theme.get_theme()
	p.custom_minimum_size = Vector2(0, UI3.CHIP_H)
	p.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("panel"), UI3Theme.radius("s"), 2,
		UI3Theme.color("text_muted"), Vector4(12, 0, 12, 0)))
	var l := UI3.label(text, "LabelDisplay")
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p


func _refresh() -> void:
	if _body == null:
		return
	UI3Meta.clear(_body)
	var cfg := _Econ.get_table("daily")
	var d: Dictionary = cfg.get("daily_reward", {})
	var reset := String(cfg.get("reset", "00:00 UTC"))
	var claimed := daily_claimed()
	var blocked := _blocks()
	var reason := "Claimed today" if claimed else ("Sign in to claim" if state == "guest" else "Needs a connection")
	var g: Dictionary = _Econ.get_table("gem").get("gift", {})
	var gs := gift_state()
	var daily_ok := not claimed and not blocked
	var gift_ok := gs == "claim" and not blocked
	var primary_daily := daily_ok
	var primary_gift := gift_ok and not daily_ok
	var sub := "Claimed. Next one at %s." % reset if claimed else "Any run counts. Resets at %s." % reset
	if last_result != "":
		sub = last_result
	_body.add_child(_card("DailyCard", "Daily reward", sub, [
		["Shards", "+%d" % int(d.get("shards", 0))], ["Stone", "+%d" % int(d.get("stone", 0))],
		["Pass XP", "+%d" % int(d.get("xp", 0))]],
		_claim_button("ClaimDaily", "Claim", daily_ok, reason, claim_daily, primary_daily)))
	var w: Dictionary = cfg.get("weekly_bonus", {})
	var need := int(w.get("min_days", 4))
	var have := mini(MetaState.weekly_daily_days(), need)
	var strip := HBoxContainer.new()
	strip.name = "WeekStrip"
	strip.add_theme_constant_override("separation", UI3Theme.space("8"))
	for i in need:
		strip.add_child(_day_chip("Day %d" % (i + 1), i < have))
	var paid := MetaState.weekly_bonus_paid()
	# The weekly bonus pays by itself on the last day; the button only says where you are.
	var wreason := "Paid this week" if paid else "%d of %d days · pays on day %d" % [have, need, need]
	var wb := _claim_button("WeeklyStatus", "", false, wreason, func() -> void: pass, false)
	_body.add_child(_card("WeeklyCard", "Weekly bonus",
		"Claim the daily reward on %d days in a week. %d of %d so far.%s" % [need, have, need, " Paid this week." if paid else ""],
		[["Shards", "+%d" % int(w.get("shards", 0))], ["Stone", "+%d" % int(w.get("stone", 0))]], wb, strip))
	var greason := "Claimed today" if gs == "done" else ("At the cap" if gs == "cap" else reason)
	var cap := int(g.get("balance_cap", 900))
	var gtxt := "Playtest: free, up to %d held." % cap
	if gs == "cap":
		gtxt = "You hold %d, nothing to claim." % MetaState.gem_wallet().balance()
	_body.add_child(_card("GiftCard", "Gem gift", gtxt, [
		["Gem a day", "+%d" % int(g.get("per_day", 300))],
		["You hold", str(MetaState.gem_wallet().balance())], ["Hold up to", str(cap)]],
		_claim_button("ClaimGift", "Claim %d Gem" % int(g.get("per_day", 300)), gift_ok, greason, claim_gift, primary_gift)))
