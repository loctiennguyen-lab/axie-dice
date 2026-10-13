class_name PassView
extends Control
## M4 Season Pass (key 5), R3 frames M4a-M4f. Spec: design/handoffs/ui-02-round3 README section 2 M4.
## Data and every claim go through MetaState -> PassV2 (pass_claim_free, pass_claim_weekly); this
## screen only draws state and calls the API, so a double claim is refused by PassV2 itself.
## Drawn: level badge + XP bar, Claim all, 3 weekly cards, 30-node track (horizontal scroll),
## premium row (locked, "Season 2", no purchase), post-30 loop row, reward detail card, banners for
## offline/guest, before-season and season-over. Rewards already reached stay claimable after the
## season ends; only XP and weekly claims stop (PassV2). Not drawn: loading skeleton (no async data).
## Title names for A5/A10 are Ascension rewards, not Pass, and are not touched here.
## Gaps for E: MetaState has no pass_claim_post30 wrapper (loop row calls PassV2.claim_post30) and no
## pass-state getter (view reads MetaState.pass_season + PassV2 statics).

const _Econ := preload("res://scripts/meta/economy_db.gd")
const MONTHS := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
const TASK_NAMES := {"play_runs": "Play %d runs", "win_runs": "Win %d runs", "reach_boss": "Reach a boss in %d run"}
const NODE_W := 132.0
const NODE_H := 254.0
const REASONS := {
	"gem_needs_server": "Gem gifts need a connection", "not_reached": "Not reached yet",
	"already_claimed": "Already claimed", "season_over": "The season is over, no more XP",
	"week_over": "That week is over", "not_done": "Task not finished",
}

## "normal" | "offline" | "guest"
var state := "normal"
var no_scene_change := false
var use_account := true
var remote_on: bool = String(ProjectSettings.get_setting("axie/gem_wallet", "")) == "remote"
var account_status_hook: Callable
## Tests: ISO day to act as "today"; empty = real UTC day.
var today_override := ""
var last_result := ""

var _root: VBoxContainer
var _banner_host: VBoxContainer
var _body: VBoxContainer
var _detail: Label


func _ready() -> void:
	var shell := DangoScreen.build(self, MockupAssets.tex("assets/bg/temple.jpg"), DangoTheme.Scrim.DEFAULT, true)
	DangoScreen.add_back_button(shell["footer"], _on_back)
	var scroll := ScrollContainer.new()
	scroll.name = "PageScroll"
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	DangoTheme.style_scrollbars(scroll)
	shell["content"].add_child(scroll)
	_root = VBoxContainer.new()
	_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_root.add_theme_constant_override("separation", 12)
	scroll.add_child(_root)
	_banner_host = VBoxContainer.new()
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 12)
	_root.add_child(_banner_host)
	_root.add_child(_body)
	if use_account:
		state = derive_state()
	refresh()


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


func _on_back() -> void:
	if is_inside_tree() and not no_scene_change:
		LandNav.back_to_land()


# ---------------------------------------------------------------- state (also tests)

func today() -> String:
	return today_override if today_override != "" else MetaState.today_utc()


func cfg() -> Dictionary:
	return _Econ.get_table("pass_v2")


## "before" | "active" | "over"
func season_phase() -> String:
	if today() < String(cfg().get("start_day", "")):
		return "before"
	return "active" if PassV2.season_active(today()) else "over"


func _same_season() -> bool:
	return String(MetaState.pass_season.get("id", "")) == String(cfg().get("season_id", ""))


## Pass progress of the current season; a save from another season reads as empty (no mutation).
func ps() -> Dictionary:
	return MetaState.pass_season if _same_season() else PassV2.new_state(String(cfg().get("season_id", "")))


func xp() -> int:
	return int(ps().get("xp", 0))


func level() -> int:
	return PassV2.level_for_xp(xp())


## "claimed" | "claimable" | "next" | "locked" (not reached) for node `lv`.
func node_state(lv: int) -> String:
	if (ps().get("claimed_free", []) as Array).has(lv):
		return "claimed"
	if lv <= level():
		return "claimable"
	return "next" if lv == level() + 1 else "locked"


func claim_level(lv: int) -> Dictionary:
	var r: Dictionary = MetaState.pass_claim_free(lv)
	last_result = "Level %d claimed" % lv if bool(r.get("ok", false)) else String(REASONS.get(r.get("reason", ""), "Could not claim"))
	refresh()
	return r


func claim_all() -> int:
	var n := 0
	for lv in PassV2.claimable_levels(MetaState):
		var r: Dictionary = MetaState.pass_claim_free(int(lv))
		if not bool(r.get("ok", false)):
			last_result = String(REASONS.get(r.get("reason", ""), "Could not claim"))
			break
		n += 1
	if n > 0:
		last_result = "Claimed %d levels" % n
	refresh()
	return n


func claim_weekly(task_id: String) -> Dictionary:
	var r: Dictionary
	if today_override == "":
		r = MetaState.pass_claim_weekly(today(), task_id)
	else:
		r = PassV2.claim_weekly(MetaState, today(), task_id, today())   # test clock, same rules
	last_result = "+%d XP" % int(r.get("xp", 0)) if bool(r.get("ok", false)) else String(REASONS.get(r.get("reason", ""), "Could not claim"))
	refresh()
	return r


func claim_loop() -> int:
	var s := PassV2.claim_post30(MetaState)
	last_result = "+%d Shard" % s if s > 0 else "Nothing to claim"
	refresh()
	return s


## XP needed to go from level lv-1 to lv ("Level L needs 500 + 40 x (L - 1)").
func need_for(lv: int) -> int:
	return int(PassV2.level_def(lv).get("xp", 0))


static func fmt_day(iso: String) -> String:
	var p := iso.split("-")
	if p.size() != 3:
		return iso
	return "%d %s %s" % [int(p[2]), MONTHS[clampi(int(p[1]) - 1, 0, 11)], p[0]]


## Next Monday 00:00 UTC after the current week.
func week_reset_text() -> String:
	var mon := PassV2.week_key(today())
	var nxt := GemWallet.utc_day(int(Time.get_unix_time_from_datetime_string(mon + "T00:00:00")) + 7 * 86400)
	return "resets Mon %s, 00:00 UTC" % fmt_day(nxt)


func season_text() -> String:
	var c := cfg()
	match season_phase():
		"before": return "Season 1 · starts %s" % fmt_day(String(c.get("start_day", "")))
		"over": return "Season 1 · ended %s" % fmt_day(String(c.get("end_day", "")))
	return "Season 1 · ends %s" % fmt_day(String(c.get("end_day", "")))


func reward_text(r: Dictionary) -> String:
	var v = r.get("value")
	match String(r.get("type", "")):
		"shard": return "%d Shard" % int(v)
		"stone": return "%s Stone" % _thousands(int(v))
		"ticket": return "%d ticket%s" % [int(v), "" if int(v) == 1 else "s"]
		"gem": return "%d Gem" % int(v)
		"cosmetic": return _pretty(String(v))
		"title": return "Title: %s" % String(v).capitalize()
		"unlock": return "Stat unlock: %s" % _pretty(String(v))
	return String(v)


func _pretty(id: String) -> String:
	var out: Array[String] = []
	for p in id.split("_"):
		out.append(String(p).capitalize())
	return " ".join(out)


func _thousands(n: int) -> String:
	var s := str(n)
	return s if n < 1000 else "%s,%s" % [s.substr(0, s.length() - 3), s.substr(s.length() - 3)]


# ---------------------------------------------------------------- build

func refresh() -> void:
	if _body == null:
		return
	for host in [_banner_host, _body]:
		for c in host.get_children():
			host.remove_child(c)   # detach now so lookups never see the old tree
			c.queue_free()
	match state:
		"offline":
			_banner("Can't reach the dice server" if remote_on else "You're offline",
				"Gem gifts need a connection." if remote_on else "Your pass progress is kept on this device.")
		"guest":
			_banner("Playing as a guest", "Pass progress is kept on this device. Sign in to keep it.")
	match season_phase():
		"before":
			_banner("The season has not started", "XP starts counting on %s." % fmt_day(String(cfg().get("start_day", ""))))
		"over":
			_banner("The season is over", "XP stopped. Rewards you already reached can still be claimed.")
	_build_header()
	_build_level_card()
	_build_weekly()
	_build_track()
	_build_extra_rows()
	_detail = _label("Hover or focus a level to see its reward.", 14, DangoTheme.DUSK_INK)
	_detail.name = "DetailText"
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var dp := _plate(DangoTheme.DUSK, DangoTheme.OUTLINE)
	dp.name = "DetailCard"
	dp.custom_minimum_size = Vector2(300, 0)
	dp.add_child(_detail)
	_body.add_child(dp)
	if last_result != "":
		var res := _label(last_result, 16, DangoTheme.CREAM_RAISED, true)
		res.name = "ResultLine"
		_body.add_child(res)


func _build_header() -> void:
	var row := HBoxContainer.new()
	var t := _label("Season Pass", DangoTheme.T_H1, DangoTheme.CREAM_RAISED, true)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(t)
	var s := _label(season_text(), 20, DangoTheme.CREAM_RAISED)
	s.name = "SeasonText"
	row.add_child(s)
	_body.add_child(row)


func _build_level_card() -> void:
	var card := _plate(DangoTheme.CREAM_RAISED, DangoTheme.LINE)
	card.name = "LevelCard"
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	card.add_child(row)
	var lv := level()
	var badge := _plate(DangoTheme.GOLD, DangoTheme.OUTLINE)
	badge.custom_minimum_size = Vector2(72, 72)
	var bl := _label(str(lv), DangoTheme.T_NUM_L, DangoTheme.GOLD_INK, true)
	bl.name = "LevelNumber"
	bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_child(bl)
	row.add_child(badge)
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cur_total := int(PassV2.level_def(lv).get("xp_total", 0))
	var bar := ProgressBar.new()
	bar.name = "XpBar"
	bar.custom_minimum_size = Vector2(0, 26)
	bar.show_percentage = false
	var info := ""
	if PassV2.level_def(lv + 1).size() > 0:
		var need := need_for(lv + 1)
		bar.max_value = need
		bar.value = xp() - cur_total
		info = "%s / %s XP to level %d" % [_thousands(xp() - cur_total), _thousands(need), lv + 1]
	else:
		var loop := int((cfg().get("post30_loop", {}) as Dictionary).get("xp", 2000))
		bar.max_value = loop
		bar.value = (xp() - PassV2.max_xp()) % loop
		info = "Loop: %s / %s XP" % [_thousands(int(bar.value)), _thousands(loop)]
	var fill := StyleBoxFlat.new()
	fill.bg_color = DangoTheme.GOLD
	var back := StyleBoxFlat.new()
	back.bg_color = DangoTheme.BAR_TRACK
	fill.set_corner_radius_all(8)
	back.set_corner_radius_all(8)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", back)
	mid.add_child(bar)
	var il := _label(info, 16)
	il.name = "XpInfo"
	mid.add_child(il)
	mid.add_child(_label("Level L needs 500 + 40 × (L − 1) XP", 14, DangoTheme.INK_2))
	row.add_child(mid)
	var all := _button("Claim all", 220, 60, true)
	all.name = "ClaimAll"
	all.disabled = PassV2.claimable_levels(MetaState).is_empty() if _same_season() else true
	all.pressed.connect(claim_all)
	row.add_child(all)
	_body.add_child(card)


func _build_weekly() -> void:
	_body.add_child(_label("Weekly tasks · %s" % week_reset_text(), 18, DangoTheme.CREAM_RAISED, true))
	var row := HBoxContainer.new()
	row.name = "WeeklyRow"
	row.add_theme_constant_override("separation", 12)
	var xp_each := int((cfg().get("weekly_tasks", {}) as Dictionary).get("xp_each", 500))
	var live := season_phase() == "active"
	for st in PassV2.weekly_status(MetaState, today()):
		var id := String(st["id"])
		var card := _plate(DangoTheme.CREAM_RAISED, DangoTheme.LINE)
		card.name = "Weekly_" + id
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		card.add_child(h)
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(_label(String(TASK_NAMES.get(id, id)) % int(st["target"]), 16))
		var pl := _label("%d / %d · +%d XP" % [int(st["progress"]), int(st["target"]), xp_each], 14, DangoTheme.INK_2)
		pl.name = "Progress"
		v.add_child(pl)
		h.add_child(v)
		var b := _button("Claimed" if st["claimed"] else "Claim", 120, 44, bool(st["done"]) and not bool(st["claimed"]))
		b.name = "WeeklyClaim_" + id
		b.disabled = bool(st["claimed"]) or not bool(st["done"]) or not live
		b.pressed.connect(claim_weekly.bind(id))
		h.add_child(b)
		row.add_child(card)
	_body.add_child(row)


func _build_track() -> void:
	_body.add_child(_label("Free track", 18, DangoTheme.CREAM_RAISED, true))
	var sc := ScrollContainer.new()
	sc.name = "TrackScroll"
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.custom_minimum_size = Vector2(0, NODE_H + 20)
	DangoTheme.style_scrollbars(sc)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	sc.add_child(h)
	for def in cfg().get("levels", []):
		h.add_child(_node(def))
	_body.add_child(sc)


func _node(def: Dictionary) -> Control:
	var lv := int(def["lv"])
	var st := node_state(lv)
	var p := _plate(DangoTheme.CREAM_RAISED if st != "locked" else DangoTheme.CREAM_DISABLED,
		DangoTheme.GOLD if st == "claimable" else DangoTheme.LINE)
	p.name = "Node_%d" % lv
	p.custom_minimum_size = Vector2(NODE_W, NODE_H)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	p.add_child(v)
	v.add_child(_label("LV %d" % lv, 15, DangoTheme.INK, true))
	for r in def.get("free", []):
		var rd: Dictionary = r
		if String(rd.get("type", "")) == "cosmetic":
			var art := CosmeticTile.art(String(rd.get("value", "")), 56.0)
			if art != null:
				v.add_child(art)
		var l := _label(reward_text(rd), 14, DangoTheme.INK_DISABLED if st == "locked" else DangoTheme.INK)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(l)
		match String(rd.get("type", "")):
			"gem": v.add_child(_label("Season gift", 12, DangoTheme.GEM_SHELF))
			"unlock": v.add_child(_label("Stat unlock", 12, DangoTheme.GOLD_INK))
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sp)
	var b := _button("", 100, 44, st == "claimable")
	b.name = "NodeBtn_%d" % lv
	match st:
		"claimed":
			b.text = "✓ Claimed"
			b.disabled = true
		"claimable":
			b.text = "CLAIM"
			b.pressed.connect(claim_level.bind(lv))
		"next":
			b.text = "Next"
			b.disabled = true
		_:
			b.text = "Reach LV %d" % lv if season_phase() != "over" else "Not claimed"
			b.disabled = true
	b.add_theme_font_size_override("font_size", 14)
	b.focus_entered.connect(_show_detail.bind(def))
	b.mouse_entered.connect(_show_detail.bind(def))
	v.add_child(b)
	p.mouse_entered.connect(_show_detail.bind(def))
	return p


func _show_detail(def: Dictionary) -> void:
	if _detail == null:
		return
	var parts: Array[String] = []
	for r in def.get("free", []):
		parts.append(reward_text(r))
		if String((r as Dictionary).get("type", "")) == "unlock":
			parts.append("(if you already own it, you get its Shard price instead)")
	_detail.text = "Level %d: %s" % [int(def["lv"]), ", ".join(parts)]


func _build_extra_rows() -> void:
	var prem := PassV2.premium_state()
	var pr := _plate(DangoTheme.CREAM_DISABLED, DangoTheme.INK_3)
	pr.name = "PremiumRow"
	var ph := HBoxContainer.new()
	pr.add_child(ph)
	var rib := _label(String(prem["label"]).to_upper(), 15, DangoTheme.GOLD_INK, true)
	rib.name = "PremiumRibbon"
	ph.add_child(rib)
	var pt := _label("   Premium track: locked, opens in season %d. Nothing to buy now." % int(prem["unlock_season"]), 16, DangoTheme.INK_DISABLED)
	pt.name = "PremiumText"
	ph.add_child(pt)
	_body.add_child(pr)

	var loop: Dictionary = cfg().get("post30_loop", {})
	var shard := int(loop.get("shard", 50))
	var lr := _plate(DangoTheme.CREAM_RAISED, DangoTheme.LINE)
	lr.name = "LoopRow"
	var lh := HBoxContainer.new()
	lh.add_theme_constant_override("separation", 12)
	lr.add_child(lh)
	var done := int(ps().get("post30_claimed", 0)) * shard
	var pend := PassV2.post30_pending(MetaState) if _same_season() else 0
	var ll := _label("After level 30: every %s XP = %d Shard · claimed so far %d Shard" % [
		_thousands(int(loop.get("xp", 2000))), shard, done], 16)
	ll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ll.name = "LoopText"
	lh.add_child(ll)
	var lb := _button("Claim %d Shard" % (pend * shard) if pend > 0 else "Nothing yet", 220, 44, pend > 0)
	lb.name = "LoopClaim"
	lb.disabled = pend <= 0
	lb.pressed.connect(claim_loop)
	lh.add_child(lb)
	_body.add_child(lr)


# ---------------------------------------------------------------- widgets

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


func _plate(fill: Color, border: Color) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_corner_radius_all(16)
	sb.set_border_width_all(3)
	sb.border_color = border
	sb.set_content_margin_all(12)
	p.add_theme_stylebox_override("panel", sb)
	return p


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
