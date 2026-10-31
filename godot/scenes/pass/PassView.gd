class_name PassView
extends Control
## M4 Season Pass (key 5). UI-03 round-2 screen 21 on UI3Meta (design/handoffs/ui-03-redesign/round-2/handoff/screens/21-season-pass).
## Season 1 = free track only; the Season 2 premium row is a muted note, nothing to buy.
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
const PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")
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

var _modal_layer: Control
var _left: VBoxContainer
var _banner_host: VBoxContainer
var _tiles := {}   # lv -> PanelContainer (grid tile)


func _ready() -> void:
	_build()
	if use_account:
		state = derive_state()
	refresh()
	_initial_focus()
	if is_remote():   # show the server's Pass numbers, not an old cache
		MetaState.econ_remote().refresh(func(_r: Dictionary) -> void:
			if is_inside_tree():
				refresh())


## Keyboard / pad start on ClaimAll when it is live, else on Back (never on a tile: a focused tile would pick a level).
func _initial_focus() -> void:
	if get_viewport() == null:
		return
	var all := find_child("ClaimAllButton", true, false) as Button
	var tgt: Button = all if all != null and not all.disabled else find_child("BackButton", true, false) as Button
	if tgt != null and get_viewport().gui_get_focus_owner() == null:
		tgt.grab_focus.call_deferred()


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
			_remote_done(r, "+%d Shards" % sh))
		return 0
	var s := PassV2.claim_post30(MetaState)
	last_result = "+%d Shards" % s if s > 0 else "Nothing to claim"
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


## Last day of the season: `end_day` in pass_v2.json is the first day AFTER it (exclusive).
func last_day() -> String:
	var e := String(cfg().get("end_day", ""))
	return GemWallet.utc_day(int(Time.get_unix_time_from_datetime_string(e + "T00:00:00")) - 86400)


func season_text() -> String:
	var c := cfg()
	match season_phase():
		"before": return "Season 1 · starts %s" % fmt_day(String(c.get("start_day", "")))
		"over": return "Season 1 · ended %s" % fmt_day(last_day())
	return "Season 1 · ends %s" % fmt_day(last_day())


static func reward_text(r: Dictionary) -> String:
	var v = r.get("value")
	match String(r.get("type", "")):
		"shard": return "%d Shard%s" % [int(v), "" if int(v) == 1 else "s"]
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



# ---------------------------------------------------------------- build (UI-05 b23 S10, frames 21-pass--*)

const COLS := 6
const TILE_H := 132

var _detail: Ui5DetailPlate
var _tile_btn := {}   # lv -> Button


func _build() -> void:
	_shell = UI3Meta.build(self, PassSummary.NAME, "", _on_back)
	(_shell["panel"] as Control).name = "PlateHost"   # t_ui_laws L0
	(_shell["back"] as Control).name = "BackButton"
	(_shell["sub"] as Label).name = "SubLine"
	_modal_layer = _shell["modal_layer"]
	var body := HBoxContainer.new()
	body.name = "Body"
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", UI3Theme.space("24"))
	(_shell["col"] as VBoxContainer).add_child(body)
	_left = VBoxContainer.new()
	_left.name = "Content"
	_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_left.add_theme_constant_override("separation", UI3Theme.space("12"))
	_left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var left_scroll := UI3Meta.scroll(_left)
	left_scroll.name = "LeftScroll"
	body.add_child(left_scroll)
	_detail = Ui5DetailPlate.new()
	_detail.setup("pass_detail_w", "Pick a level", "Select a level to see its reward.", "Pick a level")
	_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(_detail)


func refresh() -> void:
	if _left == null:
		return
	UI3Meta.clear(_left)
	_tile_btn.clear()
	(_shell["sub"] as Label).text = season_text()
	var ban := VBoxContainer.new()
	ban.name = "BannerHost"
	ban.add_theme_constant_override("separation", UI3Theme.space("8"))
	_left.add_child(ban)
	match state:
		"offline":
			ban.add_child(PassParts.banner(&"warn", "Can't reach the server" if remote_on else "You're offline",
				"Gem gifts need a connection." if remote_on else "Your pass progress is kept on this device."))
		"guest":
			ban.add_child(PassParts.banner(&"info", "You're signed out", "Pass progress is kept on this device. Sign in to keep it."))
	match season_phase():
		"before":
			ban.add_child(PassParts.banner(&"info", "The season has not started", "XP starts counting on %s." % fmt_day(String(cfg().get("start_day", "")))))
		"over":
			ban.add_child(PassParts.banner(&"info", "The season is over", "XP stopped. Rewards you already reached can still be claimed."))
	_banner_host = ban
	var ready_n := claimable_count()
	_build_level_card(ready_n)
	if last_result != "":
		_left.add_child(PassParts.result_line(last_result))
	_build_weekly()
	_build_track(ready_n)
	_build_extra_rows()
	if selected_lv != 0 and _def(selected_lv).is_empty():
		selected_lv = 0
	if selected_lv != 0:
		select_level(selected_lv)
	else:
		_draw_detail()


## How many levels "Claim all" would take now.
func claimable_count() -> int:
	return PassV2.claimable_levels(MetaState).size() if _same_season() else 0


func _def(lv: int) -> Dictionary:
	for d in cfg().get("levels", []):
		if int((d as Dictionary)["lv"]) == lv:
			return d
	return {}


## Detail plate follows the focused / hovered / clicked tile. Nothing is picked until then.
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
		if String((r as Dictionary).get("type", "")) != "cosmetic":
			out.append(reward_text(r))
		match String((r as Dictionary).get("type", "")):
			"gem": out.append("Season gift, paid once at this level.")
			"unlock": out.append("If you already own it, you get its Shard price instead.")
	return out


func _cos_ids(def: Dictionary) -> Array:
	var ids := []
	for r in def.get("free", []):
		if String((r as Dictionary).get("type", "")) == "cosmetic":
			ids.append(String(r.get("value", "")))
	return ids


func _draw_detail() -> void:
	if _detail == null:
		return
	var def := _def(selected_lv)
	if def.is_empty():
		_detail.show_empty()
		return
	var lv := selected_lv
	var st := node_state(lv)
	_detail.show_item("Level %d" % lv)
	_detail.body.add_child(UI3Meta.tag(_state_word(st)))
	for cid in _cos_ids(def):
		var art := CosmeticTile.art(String(cid), 200.0)
		if art != null:
			var host := CenterContainer.new()
			host.name = "FrameArt"
			host.custom_minimum_size = Vector2(0, 200)
			host.add_child(art)
			_detail.body.add_child(host)
		var tier := PassParts.tier_of(String(cid))
		var nm := _detail.add_line(CosmeticTile.display_name(String(cid)), "text")
		nm.name = "RewardName"
		var tw := _detail.add_line(PassParts.tier_word(tier))
		tw.name = "RewardTier"
		tw.add_theme_color_override("font_color", DiceSkin.tier_text_color(tier))
	for ln in reward_lines(def):
		_detail.add_line(ln, "text_muted" if ln.begins_with("If you") or ln.begins_with("Season gift") else "text")
	var b: Button
	match st:
		"claimed":
			b = _detail.set_primary("Claimed")
			Ui5ClaimButton.set_claimed(b)
		"claimable":
			# Claim all is the screen's one primary while a level is ready: this one is a wide secondary.
			_detail.set_primary("Claim level %d" % lv)
			for c in _detail.footer.get_children():
				_detail.footer.remove_child(c)
				c.queue_free()
			b = PanelParts.button("Claim level %d" % lv, &"secondary", &"L")
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.custom_minimum_size.y = UI3Theme.size_of("btn_l")
			_detail.footer.add_child(b)
			_detail.primary = b
			b.pressed.connect(claim_level.bind(lv))
		_:
			var why := "Reach Level %d" % lv if season_phase() != "over" else "Not claimed"
			b = _detail.set_primary(why, why)
	b.name = "ClaimLevelButton"


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


func _build_level_card(ready_n: int) -> void:
	var card := PassParts.plate("LevelCard", UI3Theme.space("16"), UI3Theme.space("20"))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI3Theme.space("20"))
	card.add_child(row)
	var lv := level()
	var badge := VBoxContainer.new()
	badge.name = "LevelBadge"
	badge.alignment = BoxContainer.ALIGNMENT_CENTER
	badge.add_theme_constant_override("separation", 0)
	var cap := Ui5Text.label("Level", "text_body", "text_muted")
	cap.name = "LevelCaption"
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_child(cap)
	var bl := Ui5Text.label(str(lv), "text_banner", "text", true)
	bl.name = "LevelNumber"
	bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_child(bl)
	row.add_child(badge)
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mid.add_theme_constant_override("separation", UI3Theme.space("4"))
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
	var il := Ui5Text.label(info, "text_title", "text")
	il.name = "XpInfo"
	mid.add_child(il)
	mid.add_child(bar)
	mid.add_child(Ui5Text.label("Level L needs 500 + 40 × (L − 1) XP", "text_body", "text_muted"))
	row.add_child(mid)
	var txt := "Claim all · %d level%s" % [ready_n, "" if ready_n == 1 else "s"] if ready_n > 0 else "Claim all · Nothing to claim"
	var all := Ui5ClaimButton.make(txt, &"M")
	all.name = "ClaimAllButton"
	all.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	all.disabled = ready_n == 0
	all.pressed.connect(claim_all)
	row.add_child(all)
	_left.add_child(card)


func _build_weekly() -> void:
	var h := Ui5Text.label("Weekly tasks · %s" % week_reset_text(), "text_title", "text")
	h.name = "TasksTitle"
	_left.add_child(h)
	var row := HBoxContainer.new()
	row.name = "Tasks"
	row.add_theme_constant_override("separation", UI3Theme.space("16"))
	var xp_each := int((cfg().get("weekly_tasks", {}) as Dictionary).get("xp_each", 500))
	var live := season_phase() == "active"
	for st in PassV2.weekly_status(MetaState, today()):
		var id := String(st["id"])
		var card := PassParts.plate("TaskCard", UI3Theme.space("12"), UI3Theme.space("16"))
		card.set_meta("task_id", id)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", UI3Theme.space("12"))
		card.add_child(hb)
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var tl := Ui5Text.label(String(TASK_NAMES.get(id, id)) % int(st["target"]), "text_title", "text")
		tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(tl)
		var pl := Ui5Text.label("%d / %d · +%d XP" % [int(st["progress"]), int(st["target"]), xp_each], "text_body", "text_muted")
		pl.name = "Progress"
		v.add_child(pl)
		hb.add_child(v)
		var b := PanelParts.button("Claim", &"secondary", &"S")
		b.name = "ClaimButton"
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size.x = UI3Theme.space("32") * 6   # wraps a long reason inside the card (frame: max 55%), never char by char
		b.set_meta("task_id", id)
		if bool(st["claimed"]):
			Ui5ClaimButton.set_claimed(b)
			b.name = "ClaimButton"
		elif not live:
			b.text = "Claim · The season is not running"
			b.disabled = true
		elif not bool(st["done"]):
			b.text = "Claim · Task not finished"
			b.disabled = true
		b.tooltip_text = b.text if b.disabled else ""
		b.pressed.connect(claim_weekly.bind(id))
		hb.add_child(b)
		row.add_child(card, true)
	_left.add_child(row)


func _build_track(ready_n: int) -> void:
	_tiles.clear()
	var h := Ui5Text.label("Free track", "text_title", "text")
	h.name = "TrackTitle"
	_left.add_child(h)
	var grid := GridContainer.new()
	grid.name = "TrackGrid"
	grid.columns = COLS
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", UI3Theme.space("12"))
	grid.add_theme_constant_override("v_separation", UI3Theme.space("12"))
	for def in cfg().get("levels", []):
		var tile := _tile(def)
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(tile, true)
	var sc := UI3Meta.scroll(grid)
	sc.name = "TrackScroll"
	sc.custom_minimum_size.y = UI3Theme.size_of("pass_tile_h") * 2 + UI3Theme.space("12")   # two full rows
	_left.add_child(sc)


func _tile(def: Dictionary) -> Control:
	var lv := int(def["lv"])
	var st := node_state(lv)
	var p := PassParts.plate("PassTile", UI3Theme.space("12"), UI3Theme.space("12"))
	p.set_meta("lv", lv)
	p.custom_minimum_size = Vector2(0, UI3Theme.size_of("pass_tile_h"))
	_tiles[lv] = p
	if st == "locked":
		p.modulate.a = 0.75
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI3Theme.space("4"))
	p.add_child(v)
	var top := HBoxContainer.new()
	top.name = "Head"
	top.add_theme_constant_override("separation", UI3Theme.space("8"))
	var lvl := Ui5Text.label("Level %d" % lv, "text_title", "text")
	lvl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(lvl)
	for r in def.get("free", []):
		if String((r as Dictionary).get("type", "")) == "gem":
			top.add_child(UI3Meta.tag("Season gift"))
	v.add_child(top)
	var rest: Array[String] = []
	for r in def.get("free", []):
		if String((r as Dictionary).get("type", "")) == "cosmetic":
			var cid := String(r.get("value", ""))
			var blk := PassParts.cosmetic_block(cid, 40.0)
			if st != "claimable":
				blk.modulate.a = 0.5 if st == "claimed" else 0.7
			v.add_child(blk)
		else:
			rest.append(reward_text(r))
	if not rest.is_empty():
		var rl := Ui5Text.label(", ".join(rest), "text_body", "text_muted" if _cos_ids(def).size() > 0 else "text")
		rl.name = "RewardText"
		rl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(rl)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(sp)
	var b := PanelParts.button("", &"secondary", &"S")
	b.name = "TileButton"
	match st:
		"claimed":
			Ui5ClaimButton.set_claimed(b)
			b.name = "TileButton"
		"claimable":
			b.text = "Claim"   # secondary: Claim all is the screen's one primary
			b.pressed.connect(claim_level.bind(lv))
		"next":
			b.text = next_text(lv)
			b.disabled = true
		_:
			b.text = "Reach Level %d" % lv if season_phase() != "over" else "Not claimed"
			b.disabled = true
	# A long state ends in "…" with the whole text in the tooltip, so it never widens the column (B6).
	b.clip_text = true
	b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	b.tooltip_text = b.text
	b.focus_entered.connect(select_level.bind(lv))
	b.mouse_entered.connect(select_level.bind(lv))
	v.add_child(b)
	_tile_btn[lv] = b
	p.gui_input.connect(func(ev: InputEvent) -> void:
		var mb := ev as InputEventMouseButton
		if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			open_reward(lv))
	p.mouse_entered.connect(select_level.bind(lv))
	return p


## The Button of level `lv` in the grid (tests, QA).
func tile_button(lv: int) -> Button:
	return _tile_btn.get(lv) as Button


## The weekly task's Claim button (tests, QA).
func task_button(id: String) -> Button:
	for c in find_children("TaskCard*", "PanelContainer", true, false):
		if String(c.get_meta("task_id", "")) == id:
			return c.find_child("ClaimButton", true, false) as Button
	return null


## Reward popup: every reward of the level, its state, Close and (when ready) Claim with the Space keycap.
func open_reward(lv: int) -> void:
	var def := _def(lv)
	if def.is_empty() or _modal_layer.get_child_count() > 0:
		return
	select_level(lv)
	var lines: Array = reward_lines(def)
	var why := level_reason(lv)
	if why != "":
		lines.append(why)
	var claimable := node_state(lv) == "claimable"
	var pop := PassParts.level_popup("Level %d · Free track" % lv, _cos_ids(def), lines, claimable)
	var m: UI3.ModalRoot = pop["root"]
	var shut := func() -> void:
		if is_instance_valid(m) and m.get_parent() != null:
			m.get_parent().remove_child(m)
			m.queue_free()
	(pop["close"] as Button).pressed.connect(shut)
	m.cancelled.connect(shut)
	var claim := pop["claim"] as Button
	if claim != null:
		claim.pressed.connect(func() -> void:
			shut.call()
			claim_level(lv))
	_modal_layer.add_child(m)
	PassParts.place_claim_cap(claim)


func _build_extra_rows() -> void:
	var prem := PassV2.premium_state()
	var pr := PassParts.plate("PremiumRow", UI3Theme.space("8"), UI3Theme.space("16"), "m")
	var ph := HBoxContainer.new()
	ph.add_theme_constant_override("separation", UI3Theme.space("16"))
	pr.add_child(ph)
	var rib := UI3Meta.tag(String(prem["label"]).to_upper())
	rib.name = "PremiumRibbonTag"
	ph.add_child(rib)
	var rl := rib.get_child(0) as Label
	rl.name = "PremiumRibbon"
	var pt := Ui5Text.label("Premium track: locked, opens in season %d. Nothing to buy now." % int(prem["unlock_season"]), "text_body", "text_muted")
	pt.name = "PremiumText"
	ph.add_child(pt)
	_left.add_child(pr)
	var loop: Dictionary = cfg().get("post30_loop", {})
	var shard := int(loop.get("shard", 50))
	var lr := PassParts.plate("LoopRow", UI3Theme.space("8"), UI3Theme.space("12"), "m")
	var lh := HBoxContainer.new()
	lh.add_theme_constant_override("separation", UI3Theme.space("16"))
	lr.add_child(lh)
	var done := int(ps().get("post30_claimed", 0)) * shard
	var pend := PassV2.post30_pending(MetaState) if _same_season() else 0
	var ll := Ui5Text.label("After level 30: every %s XP = %d Shards · claimed so far %d Shards" % [
		UI3.fmt(int(loop.get("xp", 2000))), shard, done], "text_body", "text")
	ll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ll.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ll.name = "LoopText"
	lh.add_child(ll)
	var lb := PanelParts.button("Claim %d Shards" % (pend * shard) if pend > 0 else "Nothing yet", &"secondary", &"S")
	lb.name = "LoopClaimButton"
	lb.disabled = pend <= 0
	lb.pressed.connect(claim_loop)
	lh.add_child(lb)
	_left.add_child(lr)
