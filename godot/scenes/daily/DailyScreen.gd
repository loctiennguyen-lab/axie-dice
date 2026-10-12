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

var _panel: PanelContainer
var _banner_host: VBoxContainer
var _body: VBoxContainer


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
		_on_back()
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
	last_result = "+%d Shard, +%d Pass XP" % [int(d.get("shards", 0)), int(d.get("xp", 0))] if ok else "Already claimed today"
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
	if _panel == null:
		return
	for c in _banner_host.get_children():
		c.queue_free()
	if s == "offline":
		_banner("You are offline" if not remote_on else "Can't reach the dice server",
			"Claims run on this device for now." if not remote_on else "Claims need a connection.")
	elif s == "guest":
		_banner("Playing as a guest" if not remote_on else "Sign in to claim",
			"Rewards are kept on this device." if not remote_on else "Guests have no wallet and no rewards.")
	_refresh()


func _on_back() -> void:
	if is_inside_tree() and not no_scene_change:
		LandNav.back_to_land()


func _build() -> void:
	DangoScreen.build(self, MockupAssets.tex("assets/bg/rocky.jpg"), DangoTheme.Scrim.DEFAULT, false)
	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -400
	_panel.offset_right = 400
	_panel.offset_top = -200
	_panel.offset_bottom = 200
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var sb := StyleBoxFlat.new()
	sb.bg_color = DangoTheme.CREAM
	sb.set_corner_radius_all(28)
	sb.set_border_width_all(4)
	sb.border_color = DangoTheme.LINE
	_panel.add_theme_stylebox_override("panel", sb)
	add_child(_panel)
	var col := VBoxContainer.new()
	_panel.add_child(col)
	var band := PanelContainer.new()
	var hb := StyleBoxFlat.new()
	hb.bg_color = DangoTheme.LINE
	hb.corner_radius_top_left = 24
	hb.corner_radius_top_right = 24
	hb.content_margin_left = 16
	hb.content_margin_right = 16
	band.add_theme_stylebox_override("panel", hb)
	band.custom_minimum_size = Vector2(0, 64)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	band.add_child(row)
	var back := _button("← Back  Esc", 150, 48)
	back.name = "Back"
	back.pressed.connect(_on_back)
	row.add_child(back)
	row.add_child(_label("Daily", 36, DangoTheme.CREAM_RAISED, true))
	col.add_child(band)
	_banner_host = VBoxContainer.new()
	col.add_child(_banner_host)
	var pad := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + s, 20)
	_body = VBoxContainer.new()
	_body.name = "Body"
	_body.add_theme_constant_override("separation", 12)
	pad.add_child(_body)
	col.add_child(pad)


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


func _card(name_: String, title: String, text: String, btn: Button, border: Color = DangoTheme.LINE) -> Control:
	var p := PanelContainer.new()
	p.name = name_
	var sb := StyleBoxFlat.new()
	sb.bg_color = DangoTheme.CREAM_RAISED
	sb.set_corner_radius_all(16)
	sb.set_border_width_all(3)
	sb.border_color = border
	sb.set_content_margin_all(14)
	p.add_theme_stylebox_override("panel", sb)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	p.add_child(h)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(_label(title, 24, DangoTheme.INK, true))
	var t := _label(text, 16, DangoTheme.INK_2)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	h.add_child(v)
	if btn != null:
		h.add_child(btn)
	return p


func _refresh() -> void:
	if _body == null:
		return
	for c in _body.get_children():
		_body.remove_child(c)
		c.queue_free()
	if last_result != "":
		var r := _label(last_result, 18, DangoTheme.INK, true)
		r.name = "Result"
		_body.add_child(r)
	var d: Dictionary = _Econ.get_table("daily").get("daily_reward", {})
	var claimed := daily_claimed()
	var cb := _button("Claimed" if claimed else "Claim", 190, 56, not claimed)
	cb.name = "ClaimDaily"
	cb.disabled = claimed or _blocks()
	cb.pressed.connect(claim_daily)
	_body.add_child(_card("DailyCard", "Daily reward",
		"%d Shard + %d Pass XP. Resets at %s." % [int(d.get("shards", 0)), int(d.get("xp", 0)), String(_Econ.get_table("daily").get("reset", "00:00 UTC"))], cb))
	var w: Dictionary = _Econ.get_table("daily").get("weekly_bonus", {})
	_body.add_child(_card("WeeklyCard", "Weekly bonus",
		"Claim the daily reward on %d days in a week: +%d Shard + %d Stone." % [int(w.get("min_days", 4)), int(w.get("shards", 0)), int(w.get("stone", 0))], null))
	var g: Dictionary = _Econ.get_table("gem").get("gift", {})
	var gs := gift_state()
	var gb := _button("Claimed" if gs == "done" else ("Claim %d Gem" % int(g.get("per_day", 300))), 190, 56, gs == "claim")
	gb.name = "ClaimGift"
	gb.disabled = gs != "claim" or _blocks()
	gb.pressed.connect(claim_gift)
	var gtxt := "Playtest: Gem is free, %d a day, hold up to %d." % [int(g.get("per_day", 300)), int(g.get("balance_cap", 900))]
	if gs == "cap":
		gtxt = "You hold %d, nothing to claim." % MetaState.gem_wallet().balance()
	_body.add_child(_card("GiftCard", "Gem gift", gtxt, gb))
