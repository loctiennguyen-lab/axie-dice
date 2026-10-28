class_name PassView
extends Control
## M4 Season Pass (key 5). UI-03 round-2 screen 21 on UI3Meta (design/handoffs/ui-03-redesign/round-2/handoff/screens/21-season-pass).
## Season 1 = free track only; the Season 2 premium row is a muted note, nothing to buy.
## Data and every claim go through MetaState -> PassV2 (pass_claim_free, pass_claim_weekly); this
## screen only draws state and calls the API, so a double claim is refused by PassV2 itself.
## Drawn: level badge + XP bar, Claim all, 3 weekly cards, 30-node track (one row of 8 per page, UI-04),
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
	"out_of_season": "The season is not running", "nothing_to_claim": "Nothing to claim",
	"offline": "Can't reach the server", "unauthenticated": "Sign in to claim", "bad_request": "The server did not accept that claim",
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

## Level shown in the detail plate and the one the popup opens for (0 = none yet).
var selected_lv := 0

var _shell: Dictionary
var _banner_host: VBoxContainer
var _modal_layer: Control
var _left: VBoxContainer
var _detail: PanelContainer
var _tiles := {}   # lv -> PanelContainer (grid tile)
var _page := -1   # track page 0..3; -1 = open on the page of the default level
var _prev_level := -1   # level at the last refresh, to play pass_level_up when XP crosses one
var _page_label: Label
var _prev_btn: Button
var _next_btn: Button
var _badge: Control
var _xp_bar: ProgressBar


func _ready() -> void:
	_build()
	if use_account:
		state = derive_state()
	refresh()
	if is_remote():   # show the server's Pass numbers, not an old cache
		MetaState.econ_remote().refresh(func(_r: Dictionary) -> void:
			if is_inside_tree():
				refresh())


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


func is_remote() -> bool:
	return MetaState.econ_remote() != null


## Text for a server refusal code: our table first, then the wallet's wording, else the raw code.
func remote_msg(code: String) -> String:
	if REASONS.has(code):
		return String(REASONS[code])
	var m := RemoteEcon.message_for(code)
	return m if not m.ends_with("Nothing was spent.") else "Server refused: %s" % code


## Remote claim answer -> last_result + redraw. ok_text is shown on success.
func _remote_done(r: Dictionary, ok_text: String) -> void:
	last_result = ok_text if bool(r.get("ok", false)) else remote_msg(String(r.get("code", "server")))
	if is_inside_tree():
		refresh()


func claim_level(lv: int) -> Dictionary:
	if is_remote():
		MetaState.pass_claim_free_async(lv, func(r: Dictionary) -> void: _remote_done(r, "Level %d claimed" % lv))
		return {"ok": false, "reason": "pending", "rewards": []}
	var r: Dictionary = MetaState.pass_claim_free(lv)
	last_result = "Level %d claimed" % lv if bool(r.get("ok", false)) else String(REASONS.get(r.get("reason", ""), "Could not claim"))
	refresh()
	return r


func claim_all() -> int:
	if is_remote():
		_claim_all_remote(PassV2.claimable_levels(MetaState), 0)
		return 0
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


func _claim_all_remote(levels: Array, n: int) -> void:
	if levels.is_empty():
		_remote_done({"ok": true}, "Claimed %d levels" % n)
		return
	var rest: Array = levels.slice(1)
	MetaState.pass_claim_free_async(int(levels[0]), func(r: Dictionary) -> void:
		if not bool(r.get("ok", false)):
			_remote_done(r, "")
			return
		_claim_all_remote(rest, n + 1))


func claim_weekly(task_id: String) -> Dictionary:
	if is_remote():
		MetaState.pass_claim_weekly_async(task_id, func(r: Dictionary) -> void: _remote_done(r, "+500 XP"))
		return {"ok": false, "reason": "pending", "xp": 0}
	var r: Dictionary
	if today_override == "":
		r = MetaState.pass_claim_weekly(today(), task_id)
	else:
		r = PassV2.claim_weekly(MetaState, today(), task_id, today())   # test clock, same rules
	last_result = "+%d XP" % int(r.get("xp", 0)) if bool(r.get("ok", false)) else String(REASONS.get(r.get("reason", ""), "Could not claim"))
	refresh()
	return r


func claim_loop() -> int:
	if is_remote():
		MetaState.pass_claim_post30_async(func(r: Dictionary) -> void:
			var sh := int((r.get("result", {}) as Dictionary).get("shards", 0))
			_remote_done(r, "+%d Shard" % sh))
		return 0
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


static func reward_text(r: Dictionary) -> String:
	var v = r.get("value")
	match String(r.get("type", "")):
		"shard": return "%d Shard" % int(v)
		"stone": return "%s Stone" % _thousands(int(v))
		"ticket": return "%d ticket%s" % [int(v), "" if int(v) == 1 else "s"]
		"gem": return "%d Gem" % int(v)
		"cosmetic": return cosmetic_name(String(v))
		"title": return "Title: %s" % String(v).capitalize()
		"unlock": return "Unlock: %s" % unlock_name(String(v))
	return String(v)


## Player name of a cosmetic id (manifest), never the internal id.
static func cosmetic_name(id: String) -> String:
	var n := CosmeticTile.any_name(id)
	return n if n != "" else "Cosmetic reward"


## Player name of a Shard unlock id (ContentDB.UNLOCKS "n"), never the internal id.
static func unlock_name(id: String) -> String:
	for d in ContentDB.UNLOCKS:
		if String((d as Dictionary)["id"]) == id:
			return String((d as Dictionary)["n"]).capitalize() if String((d as Dictionary)["n"]).to_upper() == String((d as Dictionary)["n"]) else String((d as Dictionary)["n"])
	return "Permanent unlock"


static func _thousands(n: int) -> String:
	var s := str(n)
	return s if n < 1000 else "%s,%s" % [s.substr(0, s.length() - 3), s.substr(s.length() - 3)]




# ---------------------------------------------------------------- build

const DETAIL_W := 456
const PER_PAGE := 8   # UI-04 M4: one row of 8 level cards, ‹ 1-8 of 30 › pages, no vertical scroll
const TILE_H := 220   # tokens size.pass_level_card_h


func _build() -> void:
	_shell = UI3Meta.build(self, PassSummary.NAME, "", _on_back)
	(_shell["panel"] as Control).name = "PlateHost"   # t_ui_laws L0
	_banner_host = _shell["banner_host"]
	_modal_layer = _shell["modal_layer"]
	(_shell["sub"] as Label).name = "SeasonText"
	var body := HBoxContainer.new()
	body.name = "Body"
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", UI3Meta.GAP)
	(_shell["col"] as VBoxContainer).add_child(body)
	_left = VBoxContainer.new()
	_left.name = "Content"
	_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_left.add_theme_constant_override("separation", UI3Theme.space("16"))
	_left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# S4-10: when banners + weekly tasks leave less than two track rows (1280x720), the column scrolls
	# instead of cutting LV 7-12 under the bottom bars.
	var left_scroll := UI3Meta.scroll(_left)
	left_scroll.name = "LeftScroll"
	body.add_child(left_scroll)
	_detail = UI3.plate(&"plate")
	_detail.name = "DetailCard"
	_detail.custom_minimum_size = Vector2(DETAIL_W, 0)
	body.add_child(_detail)


func refresh() -> void:
	if _left == null:
		return
	UI3Meta.clear(_banner_host)
	UI3Meta.clear(_left)
	(_shell["sub"] as Label).text = season_text()
	match state:
		"offline":
			UI3Meta.banner(_banner_host, "Can't reach the server" if remote_on else "You're offline",
				"Gem gifts need a connection." if remote_on else "Your pass progress is kept on this device.")
		"guest":
			UI3Meta.banner(_banner_host, "You're signed out", "Pass progress is kept on this device. Sign in to keep it.")
	match season_phase():
		"before":
			UI3Meta.banner(_banner_host, "The season has not started", "XP starts counting on %s." % fmt_day(String(cfg().get("start_day", ""))))
		"over":
			UI3Meta.banner(_banner_host, "The season is over", "XP stopped. Rewards you already reached can still be claimed.")
	_build_level_card()
	_build_weekly()
	_build_track()
	_build_extra_rows()
	if last_result != "":
		var res := UI3.label(last_result, "LabelTitle")
		res.name = "ResultLine"
		_left.add_child(res)
	if selected_lv == 0 or _def(selected_lv).is_empty():
		selected_lv = _default_level()
	select_level(selected_lv)
	_level_up_check()


## UI-04 motion pass_level_up: when XP crossed a level since the last draw, the bar counts up and the badge pops.
func _level_up_check() -> void:
	var lv := level()
	if _prev_level >= 0 and lv > _prev_level and _badge != null and is_instance_valid(_badge):
		if _xp_bar != null:
			var target := _xp_bar.value
			_xp_bar.value = 0
			var tw := _xp_bar.create_tween()
			tw.tween_property(_xp_bar, "value", target, 0.0 if UI3Motion.reduced() else 0.6)
		UI3Motion.play("pass_level_up", _badge)
	_prev_level = lv


func _def(lv: int) -> Dictionary:
	for d in cfg().get("levels", []):
		if int((d as Dictionary)["lv"]) == lv:
			return d
	return {}


## First claimable level, else the next one to reach, else 1.
func _default_level() -> int:
	var c := PassV2.claimable_levels(MetaState) if _same_season() else []
	if not c.is_empty():
		return int(c[0])
	return mini(level() + 1, 30)


## Detail plate follows the focused / hovered / clicked tile.
func select_level(lv: int) -> void:
	if _def(lv).is_empty():
		return
	if _tiles.has(selected_lv) and is_instance_valid(_tiles[selected_lv]):
		UI3.set_card_selected(_tiles[selected_lv], false, false)
	selected_lv = lv
	if _tiles.has(lv) and is_instance_valid(_tiles[lv]):
		UI3.set_card_selected(_tiles[lv], true, false)
	_draw_detail()


## Why `lv` cannot be claimed now, or "" when it can.
func level_reason(lv: int) -> String:
	match node_state(lv):
		"claimed": return "Already claimed"
		"claimable": return ""
	if season_phase() == "over":
		return "Not reached before the season ended"
	return "Not reached yet · %s XP to go" % UI3.fmt(maxi(int(_def(lv).get("xp_total", 0)) - xp(), 0))


func reward_lines(def: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for r in def.get("free", []):
		out.append(reward_text(r))
		match String((r as Dictionary).get("type", "")):
			"gem": out.append("Season gift, paid once at this level.")
			"unlock": out.append("If you already own it, you get its Shard price instead.")
	return out


func _draw_detail() -> void:
	UI3Meta.clear(_detail)
	var def := _def(selected_lv)
	if def.is_empty():
		return
	var lv := selected_lv
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI3Theme.space("16"))
	_detail.add_child(v)
	var has_art := false
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UI3Theme.space("16"))
	var t := UI3.label("Level %d" % lv, "LabelScreenTitle")
	t.name = "DetailTitle"
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	head.add_child(UI3Meta.tag(_state_word(node_state(lv))))
	v.add_child(head)
	for r in def.get("free", []):
		if String((r as Dictionary).get("type", "")) == "cosmetic":
			var art := CosmeticTile.art(String(r.get("value", "")), 200.0)
			if art != null:
				var art_host := CenterContainer.new()
				art_host.custom_minimum_size = Vector2(0, 200)
				art_host.add_child(art)
				v.add_child(art_host)
				has_art = true
				break
	var dt := UI3.label("\n".join(reward_lines(def)))
	dt.name = "DetailText"
	dt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(dt)
	var why := level_reason(lv)
	if why != "" and node_state(lv) != "claimed":
		var wl := UI3.label(why, "LabelMuted")
		wl.name = "DetailReason"
		wl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(wl)
	# No art for this level: the plate hugs its content instead of stretching an empty gap.
	_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL if has_art else Control.SIZE_SHRINK_BEGIN
	if has_art:
		var sp := Control.new()
		sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
		v.add_child(sp)
	var b := UI3.button("Claim level %d" % lv, &"primary", &"L")
	b.name = "DetailClaim"
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if node_state(lv) == "claimable":
		b.pressed.connect(claim_level.bind(lv))
	else:
		b.text = "Claimed" if node_state(lv) == "claimed" else "Reach level %d to claim" % lv
		UI3.set_disabled_reason(b, "Already claimed" if node_state(lv) == "claimed" else "Not reached yet")
	v.add_child(b)


## Text on the disabled button of the next level to reach: how much XP is still missing.
func next_text(lv: int) -> String:
	var left := maxi(int(PassV2.level_def(lv).get("xp_total", 0)) - xp(), 0)
	return "Next · needs %s XP" % UI3.fmt(left) if left > 0 else "Next level"


static func _state_word(st: String) -> String:
	match st:
		"claimed": return "Claimed"
		"claimable": return "Ready"
		"next": return "Next"
	return "Locked"


func _build_level_card() -> void:
	var card := UI3.plate(&"plate")
	card.name = "LevelCard"
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI3Theme.space("24"))
	card.add_child(row)
	var lv := level()
	var badge := UI3.plate(&"card")
	badge.custom_minimum_size = Vector2(96, 96)
	var bl := UI3.label(str(lv), "LabelScreenTitle")
	bl.name = "LevelNumber"
	bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# S4-10: the big number says what it is.
	var bcol := VBoxContainer.new()
	bcol.alignment = BoxContainer.ALIGNMENT_CENTER
	bcol.add_theme_constant_override("separation", 0)
	var cap := UI3.label("Level", "LabelMuted")
	cap.name = "LevelCaption"
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bcol.add_child(cap)
	bcol.add_child(bl)
	badge.add_child(bcol)
	row.add_child(badge)
	_badge = badge
	badge.pivot_offset = Vector2(48, 48)
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mid.add_theme_constant_override("separation", UI3Theme.space("8"))
	var cur_total := int(PassV2.level_def(lv).get("xp_total", 0))
	var bar := ProgressBar.new()
	bar.name = "XpBar"
	bar.theme = UI3Theme.get_theme()
	bar.custom_minimum_size = Vector2(0, 16)
	bar.show_percentage = false
	var info := ""
	if PassV2.level_def(lv + 1).size() > 0:
		var need := need_for(lv + 1)
		bar.max_value = need
		bar.value = xp() - cur_total
		info = "%s / %s XP to level %d" % [UI3.fmt(xp() - cur_total), UI3.fmt(need), lv + 1]
	else:
		var loop := int((cfg().get("post30_loop", {}) as Dictionary).get("xp", 2000))
		bar.max_value = loop
		bar.value = (xp() - PassV2.max_xp()) % loop
		info = "Loop: %s / %s XP" % [UI3.fmt(int(bar.value)), UI3.fmt(loop)]
	var il := UI3.label(info, "LabelTitle")
	il.name = "XpInfo"
	mid.add_child(il)
	mid.add_child(bar)
	_xp_bar = bar
	mid.add_child(UI3.label("Level L needs 500 + 40 × (L − 1) XP", "LabelMuted"))
	row.add_child(mid)
	var all := UI3.button("Claim all", &"secondary", &"M")
	all.name = "ClaimAll"
	all.custom_minimum_size.x = 240
	all.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	all.disabled = PassV2.claimable_levels(MetaState).is_empty() if _same_season() else true
	if all.disabled:
		all.text = "Nothing to claim"
	all.pressed.connect(claim_all)
	row.add_child(all)
	_left.add_child(card)


func _build_weekly() -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UI3Theme.space("8"))
	var h := UI3.label("Weekly tasks · %s" % week_reset_text(), "LabelTitle")
	h.name = "WeeklyTitle"
	box.add_child(h)
	var row := HBoxContainer.new()
	row.name = "WeeklyRow"
	row.add_theme_constant_override("separation", UI3Theme.space("16"))
	var xp_each := int((cfg().get("weekly_tasks", {}) as Dictionary).get("xp_each", 500))
	var live := season_phase() == "active"
	for st in PassV2.weekly_status(MetaState, today()):
		var id := String(st["id"])
		var card := UI3.plate(&"card")
		card.name = "Weekly_" + id
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", UI3Theme.space("16"))
		card.add_child(hb)
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(UI3.label(String(TASK_NAMES.get(id, id)) % int(st["target"]), "LabelTitle"))
		var pl := UI3.label("%d / %d · +%d XP" % [int(st["progress"]), int(st["target"]), xp_each], "LabelMuted")
		pl.name = "Progress"
		v.add_child(pl)
		var pb := ProgressBar.new()
		pb.name = "ProgressBar"
		pb.theme = UI3Theme.get_theme()
		pb.custom_minimum_size = Vector2(0, 12)
		pb.show_percentage = false
		pb.max_value = maxi(int(st["target"]), 1)
		pb.value = mini(int(st["progress"]), int(st["target"]))
		v.add_child(pb)
		hb.add_child(v)
		var b := UI3.button("Claimed" if st["claimed"] else "Claim", &"secondary", &"S")
		b.name = "WeeklyClaim_" + id
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.disabled = bool(st["claimed"]) or not bool(st["done"]) or not live
		b.pressed.connect(claim_weekly.bind(id))
		hb.add_child(b)
		row.add_child(card)
	box.add_child(row)
	_left.add_child(box)


func _build_track() -> void:
	_tiles.clear()
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UI3Theme.space("16"))
	var h := UI3.label("Free track", "LabelTitle")
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(h)
	_prev_btn = UI3.button("‹", &"secondary", &"S")
	_prev_btn.name = "PagePrev"
	_prev_btn.custom_minimum_size.x = UI3Theme.size_of("hit_min")
	_prev_btn.pressed.connect(set_page.bind(-1, true))
	head.add_child(_prev_btn)
	_page_label = UI3.label("", "LabelTitle")
	_page_label.name = "PageLabel"
	_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_page_label.custom_minimum_size.x = 120
	head.add_child(_page_label)
	_next_btn = UI3.button("›", &"secondary", &"S")
	_next_btn.name = "PageNext"
	_next_btn.custom_minimum_size.x = UI3Theme.size_of("hit_min")
	_next_btn.pressed.connect(set_page.bind(1, true))
	head.add_child(_next_btn)
	_left.add_child(head)
	var row := HBoxContainer.new()
	row.name = "TrackRow"
	row.add_theme_constant_override("separation", UI3Theme.space("8"))
	for def in cfg().get("levels", []):
		var tile := _tile(def)
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(tile)
	_left.add_child(row)
	if _page < 0:
		_page = (_default_level() - 1) / PER_PAGE
	set_page(0, true)


func page_count() -> int:
	return maxi(ceili(float(cfg().get("levels", []).size()) / PER_PAGE), 1)


## Shows page `_page + delta` (delta 0 = redraw). Cards of other pages stay built but hidden, so every
## NodeBtn_* exists; no scroll, no re-layout of the rest of the screen.
func set_page(delta: int, _ignored := true) -> void:
	_page = clampi(_page + delta, 0, page_count() - 1)
	var n: int = cfg().get("levels", []).size()
	for lv in _tiles:
		(_tiles[lv] as Control).visible = (int(lv) - 1) / PER_PAGE == _page
	if _page_label != null:
		_page_label.text = "%d–%d of %d" % [_page * PER_PAGE + 1, mini((_page + 1) * PER_PAGE, n), n]
		_prev_btn.disabled = _page == 0
		_next_btn.disabled = _page >= page_count() - 1


func _tile(def: Dictionary) -> Control:
	var lv := int(def["lv"])
	var st := node_state(lv)
	var p := UI3.plate(&"card")
	p.name = "Node_%d" % lv
	p.custom_minimum_size = Vector2(158, TILE_H)
	_tiles[lv] = p
	if st == "locked":
		p.modulate.a = 0.75
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI3Theme.space("8"))
	p.add_child(v)
	var top := HBoxContainer.new()
	var lvl := UI3.label("LV %d" % lv, "LabelTitle")
	lvl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(lvl)
	for r in def.get("free", []):
		if String((r as Dictionary).get("type", "")) == "gem":
			top.add_child(UI3Meta.tag("Season gift"))
	v.add_child(top)
	var cos_id := ""
	for r in def.get("free", []):
		if String((r as Dictionary).get("type", "")) == "cosmetic" and CosmeticTile.art(String(r.get("value", "")), 8.0) != null:
			cos_id = String(r.get("value", ""))
			break
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI3Theme.space("8"))
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if cos_id != "":
		_cosmetic_reward_block(v, cos_id, st)
	else:
		for r in def.get("free", []):
			if String((r as Dictionary).get("type", "")) == "cosmetic":
				var art := CosmeticTile.art(String(r.get("value", "")), 48.0)
				if art != null:
					row.add_child(art)
					break
	var names: Array[String] = []
	for r in def.get("free", []):
		names.append(reward_text(r))
	var rl := UI3.label(", ".join(names))
	rl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rl.size_flags_vertical = Control.SIZE_SHRINK_BEGIN   # text hugs the top when a cosmetic tile makes the row taller
	rl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if cos_id == "":
		row.add_child(rl)
		v.add_child(row)
	var hot := cos_id != "" and st == "claimable"   # a cosmetic tile ready to claim: Claim is its one primary
	var b := UI3.button("", &"primary" if hot else &"secondary", &"M" if hot else &"S")
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
			b.clip_text = true
			b.tooltip_text = next_text(lv)
			b.disabled = true
		_:
			b.text = "Reach LV %d" % lv if season_phase() != "over" else "Not claimed"
			b.disabled = true
	b.focus_entered.connect(select_level.bind(lv))
	b.mouse_entered.connect(select_level.bind(lv))
	v.add_child(b)
	# Click on the tile body opens the reward popup.
	p.gui_input.connect(func(ev: InputEvent) -> void:
		var mb := ev as InputEventMouseButton
		if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			open_reward(lv))
	p.mouse_entered.connect(select_level.bind(lv))
	return p


## 48-store-pass-tiles for a dice skin / frame reward: 4 px tier strip, art box (wood-2) with the art at 100% when
## claimable, 50% when claimed, 40% when locked, then name (18 chars) and the tier word in its colour. The action
## button below is the tile's own (Claim stays the one primary). Pure look: claim logic is untouched.
func _cosmetic_reward_block(v: VBoxContainer, cos_id: String, st: String) -> void:
	var art_id := Cosmetics.art_id(cos_id)
	var tier := 0
	var m: Dictionary = CosmeticArt.manifest()
	var e: Variant = (m.get("dice", {}) as Dictionary).get(art_id, (m.get("frames", {}) as Dictionary).get(art_id, {}))
	if e is Dictionary:
		tier = int((e as Dictionary).get("tier", 0))
	var strip := ColorRect.new()
	strip.name = "TierStrip"
	strip.custom_minimum_size = Vector2(0, 4)
	strip.color = DiceSkin.tier_color(tier)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(strip)
	# Compact on purpose: strip, a 64 px art box, a one-line name and the tier word, so the tile is only about 25 px
	# taller than a normal one and its button stays visible whenever the row's top is.
	var box := Panel.new()
	box.name = "ArtBox"
	box.custom_minimum_size = Vector2(0, 48)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.clip_contents = true
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("panel_raised"), UI3Theme.radius("s")))
	var art := CosmeticTile.art(cos_id, 44.0)
	if art != null:
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.modulate.a = 0.4 if st == "locked" or st == "next" else (0.5 if st == "claimed" else 1.0)
		var cc := CenterContainer.new()
		cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cc.add_child(art)
		box.add_child(cc)
	v.add_child(box)
	var nm := UI3.label(CosmeticTile.display_name(cos_id).left(18), "LabelTitle")
	nm.name = "RewardName"
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nm.clip_text = true
	nm.add_theme_font_size_override("font_size", UI3Theme.size_of("text_body"))
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(nm)
	var tw := UI3.label(DiceSkin.TIER_NAMES.values()[clampi(tier, 0, 5)])
	tw.name = "RewardTier"
	tw.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tw.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	tw.clip_text = true
	tw.add_theme_color_override("font_color", DiceSkin.tier_text_color(tier))
	tw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(tw)


## Reward detail popup (round 2): every reward of the level, the state, and Claim when it is ready.
func open_reward(lv: int) -> void:
	var def := _def(lv)
	if def.is_empty() or _modal_layer.get_child_count() > 0:
		return
	select_level(lv)
	var lines := reward_lines(def)
	var why := level_reason(lv)
	if why != "":
		lines.append(why)
	var close := UI3.button("Close", &"secondary", &"M")
	close.name = "Close"
	var acts: Array = [close]
	var claim: Button = null
	if node_state(lv) == "claimable":
		claim = UI3.button("Claim", &"primary", &"M")
		claim.name = "Claim"
		acts.append(claim)
	var m := UI3.modal("Level %d · Free track" % lv, "\n".join(lines), acts, acts.size() - 1)
	m.name = "RewardPopup"
	var shut := func() -> void:
		if is_instance_valid(m):
			m.get_parent().remove_child(m)
			m.queue_free()
	close.pressed.connect(shut)
	m.cancelled.connect(shut)
	if claim != null:
		claim.pressed.connect(func() -> void:
			shut.call()
			claim_level(lv))
	_modal_layer.add_child(m)


func _build_extra_rows() -> void:
	var prem := PassV2.premium_state()
	var pr := UI3.plate(&"row")
	pr.name = "PremiumRow"
	var ph := HBoxContainer.new()
	ph.add_theme_constant_override("separation", UI3Theme.space("16"))
	pr.add_child(ph)
	var rib := UI3Meta.tag(String(prem["label"]).to_upper())
	rib.name = "PremiumRibbonTag"
	ph.add_child(rib)
	var rl := rib.get_child(0) as Label
	rl.name = "PremiumRibbon"
	var pt := UI3.label("Premium track: locked, opens in season %d. Nothing to buy now." % int(prem["unlock_season"]), "LabelMuted")
	pt.name = "PremiumText"
	ph.add_child(pt)
	_left.add_child(pr)

	var loop: Dictionary = cfg().get("post30_loop", {})
	var shard := int(loop.get("shard", 50))
	var lr := UI3.plate(&"row")
	lr.name = "LoopRow"
	var lh := HBoxContainer.new()
	lh.add_theme_constant_override("separation", UI3Theme.space("16"))
	lr.add_child(lh)
	var done := int(ps().get("post30_claimed", 0)) * shard
	var pend := PassV2.post30_pending(MetaState) if _same_season() else 0
	var ll := UI3.label("After level 30: every %s XP = %d Shard · claimed so far %d Shard" % [
		UI3.fmt(int(loop.get("xp", 2000))), shard, done])
	ll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ll.name = "LoopText"
	lh.add_child(ll)
	var lb := UI3.button("Claim %d Shard" % (pend * shard) if pend > 0 else "Nothing yet", &"secondary", &"S")
	lb.name = "LoopClaim"
	lb.disabled = pend <= 0
	lb.pressed.connect(claim_loop)
	lh.add_child(lb)
	_left.add_child(lr)
