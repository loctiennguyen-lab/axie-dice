extends Control
## Result.tscn root - UI-03 10 (round 2 wins): one 640 plate on the 3D backdrop with a scrim. Header (badge,
## "Run won" / "Defeated", sub line), title-unlock row, party row, 3-column stat grid, earnings rows (Gene
## Shard, Lunacia Pass XP, relics, mission stake), the offline notice and the two actions. Pure view over the
## RunState snapshot taken BEFORE end_run() (architecture plan 3.2.4); every reward and submit path is the
## one RunState already runs.
##
## RANKED / SAVE RUN RECORD is a real, shipped feature (t_result_screen pins its three states) kept as a
## caption in the Gene Shard card. FLAGGED: "Run again" still goes to the main menu (nothing restarts a run
## from a seed). FLAGGED: party HP is always full here (RunState.roster has no current HP between fights).
## FLAGGED: the Pass XP icon is missing from the art kit, so it is the spec's "XP" circle.

const BG_PATH := "assets/bg/entrance.jpg"
const PLATE_W := 640.0

var _plate: Control = null
var _plate_scroll: ScrollContainer = null
var _body: VBoxContainer = null
var _notice_host: VBoxContainer = null
var _run_id := ""
var _back: Button = null


func _ready() -> void:
	theme = UI3Theme.get_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var won := RunState.phase == RunState.RunPhase.WON

	# Snapshot every field this screen needs OUT of RunState/RunStatsAccumulator before
	# end_run() runs (architecture plan 3.2.4).
	var snapshot := {
		"won": won,
		"mode": RunState.mode,
		"ascension": RunState.ascension,
		"seed": RunState.run_seed,
		"shards_this_run": RunState.shards_this_run,
		"relic_ids": RunState.owned_relic_ids.filter(func(x) -> bool: return not String(x).begins_with("__")),
		"roster": RunState.roster.duplicate(true),
		"stats": RunStatsAccumulator.snapshot(RunState.mode),
		"ranked": RunState.ranked,
		"action_log": RunState.action_log,
		# Taken BEFORE end_run() pushes this run's XP in, so the "+N levels" pill can say how
		# many levels THIS run bought rather than what level the player happens to be.
		"pass_level_before": MetaState.bp_level(),
		"best_before": MetaState.best,
		"power_level": RunState.power_level,
		"stake_before": MetaState.mission_escrow.duplicate(),
		"mission_run": not RunState.mission.is_empty(),
	}
	var log: ActionLog = RunState.action_log
	_run_id = String(log.header.get("run_id", "")) if log != null else ""
	snapshot["mission_won"] = bool(RunState.mission_outcome(won)["won"])

	RunState.end_run(won)   # pushes shards + XP into MetaState
	snapshot["xp_gained"] = RunState.last_run_xp
	snapshot["pass_level"] = MetaState.bp_level()
	snapshot["daily_mission_granted"] = RunState.daily_mission_granted
	snapshot["new_titles"] = MetaState.last_run_new_titles.duplicate()   # C7: only this run's grants
	snapshot["stake_open"] = not MetaState.mission_escrow.is_empty()   # server-settled stakes close later

	_build_ui(snapshot)
	if bool(snapshot["ranked"]):
		# Neutral until RunState reports the real submit status (follow-up for the next RULES_VERSION bump,
		# which will call show_submit_notice). No fake "offline".
		var n := UI3.label(tr("Your score goes to the leaderboard when the run closes."), "LabelMuted")
		n.name = "SubmitLine"
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_notice_host.add_child(n)
	_fit.call_deferred()
	_back.grab_focus.call_deferred()


func _build_ui(s: Dictionary) -> void:
	var bg := TextureRect.new()
	bg.name = "PlateHost"   # full-rect backdrop; t_ui_laws L0
	bg.texture = MockupAssets.tex(BG_PATH)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var scrim := ColorRect.new()
	scrim.name = "Scrim"
	scrim.color = UI3Theme.color("scrim")
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)
	var center := CenterContainer.new()
	center.name = "Content"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var plate := UI3.plate(&"dialog")
	plate.name = "ResultPlate"
	plate.custom_minimum_size = Vector2(PLATE_W, 0)
	center.add_child(plate)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 24)
	plate.add_child(outer)

	outer.add_child(_build_header(s))
	var unlock := _build_title_unlock(s)
	if unlock != null:
		outer.add_child(unlock)
	outer.add_child(_build_party_row(s["roster"] as Array))
	outer.add_child(_build_stat_grid(s["stats"] as Dictionary))
	# Fit-or-scroll: only the earnings column scrolls when the window is short; header, stats, the
	# offline notice and the actions always stay in view.
	_plate_scroll = ScrollContainer.new()
	_plate_scroll.name = "CardScroll"
	_plate_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_plate_scroll.get_v_scroll_bar().custom_minimum_size.x = UI3Theme.SCROLL_W   # visible overflow (t_ui_laws L2)
	outer.add_child(_plate_scroll)
	_body = _build_card_rows(s)
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_plate_scroll.add_child(_body)
	_notice_host = VBoxContainer.new()
	_notice_host.name = "NoticeHost"
	outer.add_child(_notice_host)   # outside the scroll: an offline notice is never hidden
	outer.add_child(_build_actions())
	_plate = plate

	_build_version_tag()
	_build_equipped_avatar()


## Caps the scroll area to what the window can show; below that the plate hugs its content.
func _fit() -> void:
	if _body == null or _plate == null:
		return
	_plate_scroll.custom_minimum_size.y = 0.0
	var others := _plate.get_combined_minimum_size().y   # everything but the scroll (it is 0 now)
	var avail := get_viewport_rect().size.y - 48.0 - others - 24.0
	_plate_scroll.custom_minimum_size.y = minf(_body.get_combined_minimum_size().y, maxf(avail, 120.0))


func _on_notice_layout() -> void:
	await get_tree().process_frame
	_fit()


## B12: the player's avatar in its equipped frame, top-left. Only drawn when a frame is equipped.
func _build_equipped_avatar() -> void:
	if MetaState.equipped_frame == "":
		return
	var av := ProfileView.make_avatar(88.0)
	av.name = "EquippedAvatar"
	av.position = Vector2(32, 32)
	add_child(av)


## Build number, small, bottom-right. Only when application/config/version is set.
func _build_version_tag() -> void:
	var v := String(ProjectSettings.get_setting("application/config/version", ""))
	if v == "":
		return
	var l := UI3.label("v" + v, "LabelKeyHint")
	l.name = "BuildTag"
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 10)
	l.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	l.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(l)


func _centered(text: String, variation := "") -> Label:
	var l := UI3.label(text, variation)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


# ---------------------------------------------------------------------------
# Header: badge "New best - A5" (a win above the old best floor), title, sub line.
# ---------------------------------------------------------------------------
func _build_header(s: Dictionary) -> Control:
	var won := bool(s["won"])
	var col := VBoxContainer.new()
	col.name = "TitleBand"
	col.add_theme_constant_override("separation", 8)
	var new_best := won and int(s["power_level"]) > int(s["best_before"])
	if new_best:
		var chip := UI3.chip(tr("New best") + " · A%d" % int(s["ascension"]))
		chip.name = "NewBestBadge"
		chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(chip)
	var title := _centered(tr("Run won") if won else tr("Defeated"), "LabelScreenTitle")
	title.name = "ResultTitle"
	if not won:
		title.add_theme_color_override("font_color", UI3Theme.color("danger_text"))
	col.add_child(title)
	var sub := _centered("%s · A%d · %s" % [tr("Full run") if String(s["mode"]) == "full" else tr("Short run"),
		int(s["ascension"]), tr("Seed %d") % int(s["seed"])], "LabelMuted")
	sub.name = "ResultSub"
	col.add_child(sub)
	return col


## C7: "New title: X" only on the run that earned it (MetaState.last_run_new_titles is rebuilt per run).
func _build_title_unlock(s: Dictionary) -> Control:
	var new_titles: Array = s.get("new_titles", [])
	if new_titles.is_empty():
		return null
	var names: Array[String] = []
	for id in new_titles:
		names.append(TitleNames.display(String(id)))
	var row := UI3.plate(&"row")
	row.name = "NewTitleRow"
	var l := _centered(tr("New title: %s") % ", ".join(names), "LabelDisplay")
	l.name = "NewTitle"
	l.add_theme_color_override("font_color", UI3Theme.color("accent"))
	row.add_child(l)
	return row


# ---------------------------------------------------------------------------
# Party row: this run's five Axies (name, tier).
# ---------------------------------------------------------------------------
func _build_party_row(roster: Array) -> Control:
	var row := HBoxContainer.new()
	row.name = "PartyRow"
	row.add_theme_constant_override("separation", 8)
	for e in roster:
		var entry: Dictionary = e
		var hero_key := String(entry.get("hero_key", ""))
		var def: Dictionary = ContentDB.heroes.get(hero_key, {})
		var p := UI3.plate(&"row")
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 0)
		p.add_child(v)
		var nm := _centered(String(def.get("n", hero_key)), "LabelDisplay")
		nm.autowrap_mode = TextServer.AUTOWRAP_OFF
		nm.clip_text = true
		nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		v.add_child(nm)
		v.add_child(_centered("T%d" % int(entry.get("tier", 1)), "LabelMuted"))
		row.add_child(p)
	return row


# ---------------------------------------------------------------------------
# Stats: 3-column grid, value Rowdies 24 over a muted label.
# ---------------------------------------------------------------------------
func _build_stat_grid(stats: Dictionary) -> Control:
	var grid := GridContainer.new()
	grid.name = "StatRibbon"
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	var cleared := int(stats.get("nodes_cleared", 0))
	var total := int(stats.get("nodes_total", 0))
	# The cell names what RunStatsAccumulator counts: this port has no "waves", only map nodes.
	var tiles := [
		[tr("Nodes cleared"), "%d / %d" % [cleared, total]],
		[tr("Turns taken"), str(int(stats.get("turns_taken", 0)))],
		[tr("Damage dealt"), UI3.fmt(int(stats.get("damage_dealt", 0)))],
		[tr("Kills"), str(int(stats.get("kills", 0)))],
		[tr("Biggest hit"), str(int(stats.get("biggest_hit", 0)))],
		[tr("Axies lost"), str(int(stats.get("axies_lost", 0)))],
	]
	for t in tiles:
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_theme_constant_override("separation", 0)
		v.add_child(UI3.label(String(t[1]), "LabelTitle"))
		v.add_child(UI3.label(String(t[0]), "LabelMuted"))
		grid.add_child(v)
	return grid


# ---------------------------------------------------------------------------
# Earnings: Gene Shard, Lunacia Pass, relics, mission stake.
# ---------------------------------------------------------------------------
func _build_card_rows(s: Dictionary) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.name = "CardRow"
	col.add_theme_constant_override("separation", 12)
	col.add_child(_build_shard_card(s))
	col.add_child(_build_pass_card(s))
	col.add_child(_build_relics_card(s["relic_ids"] as Array))
	var stake := _build_stake_box(s)
	if stake != null:
		col.add_child(stake)
	return col


func _card_caption(text: String) -> Label:
	var l := UI3.label(text, "LabelMuted")
	l.name = "Caption"
	return l


func _build_shard_card(s: Dictionary) -> Control:
	var card := UI3.plate(&"row")
	card.name = "ShardCard"
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	card.add_child(col)
	col.add_child(_card_caption(tr("Gene Shard earned")))
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = UI3Theme.size_of("row")
	row.add_theme_constant_override("separation", 12)
	col.add_child(row)
	var ic := TextureRect.new()
	ic.texture = UI3.icon("cur_shard")
	ic.custom_minimum_size = Vector2.ONE * UI3Theme.size_of("icon_m")
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(ic)
	var amount := UI3.label("+%s" % UI3.fmt(int(s["shards_this_run"])), "LabelTitle")
	amount.name = "ShardAmount"
	row.add_child(amount)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(right)
	var daily_bonus := ContentDB.DAILY_MISSION_SHARD if bool(s.get("daily_mission_granted", false)) else 0
	var breakdown := UI3.label(tr("%d run payout") % (int(s["shards_this_run"]) - daily_bonus)
		+ (" · " + tr("%d daily") % daily_bonus if daily_bonus > 0 else ""), "LabelMuted")
	breakdown.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	breakdown.clip_text = true
	breakdown.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	right.add_child(breakdown)
	var pool := UI3.label(tr("Pool now %s") % UI3.fmt(MetaState.shard_pool), "LabelDisplay")
	pool.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pool.clip_text = true
	pool.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	right.add_child(pool)
	col.add_child(_build_ranked_caption(s))
	return card


## The RANKED / SAVE RUN RECORD line (see the file header): three states, never a button that does nothing.
func _build_ranked_caption(s: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.name = "RankedCaption"
	row.add_theme_constant_override("separation", 12)
	var label := UI3.label("", "LabelMuted")
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if not bool(s.get("ranked", false)):
		label.text = tr("This run was not Ranked, so it has no verifiable score.")
		row.add_child(label)
		return row
	var log: ActionLog = s.get("action_log")
	if log == null or not log.is_complete():
		label.text = tr("This run's record is incomplete, so its score cannot be verified.")
		row.add_child(label)
		return row
	label.text = tr("Ranked. You can save this run's verifiable record.")
	row.add_child(label)
	var btn := UI3.button(tr("Save run record"), &"quiet", &"S")   # a quiet link: max 2 secondaries on the screen
	btn.name = "SaveRecord"
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(func() -> void:
		var path := _save_run_record(log)
		label.text = (tr("Saved to %s") % path) if path != "" else tr("Could not write the run record.")
		btn.disabled = true)
	row.add_child(btn)
	return row


func _build_pass_card(s: Dictionary) -> Control:
	var card := UI3.plate(&"row")
	card.name = "PassCard"
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	card.add_child(col)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	col.add_child(head)
	var cap := _card_caption(tr("Lunacia Pass"))
	cap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(cap)
	var gained: int = maxi(int(s.get("pass_level", 0)) - int(s.get("pass_level_before", 0)), 0)
	if gained > 0:
		var pill := UI3.chip(tr("Lv %d · +%d this run") % [int(s.get("pass_level", 0)), gained])
		pill.name = "LevelsPill"
		head.add_child(pill)
	var prog: Dictionary = MetaState.bp_progress()
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = UI3Theme.size_of("row")
	row.add_theme_constant_override("separation", 12)
	col.add_child(row)
	# The art kit has no Pass XP icon (spec flag): a plain "XP" circle stands in.
	var xp := PanelContainer.new()
	xp.name = "XpIcon"
	xp.custom_minimum_size = Vector2.ONE * 40.0
	xp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	xp.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("accent"),
		20, 0, Color.TRANSPARENT, Vector4(0, 0, 0, 0)))
	var xl := UI3.label("XP", "LabelDisplay")
	xl.add_theme_color_override("font_color", UI3Theme.color("die_ink"))
	xl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	xl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	xp.add_child(xl)
	row.add_child(xp)
	row.add_child(UI3.label(tr("Lv %d") % int(prog["level"]), "LabelTitle"))
	var line := UI3.label(_pass_xp_line(int(prog["level"]), int(prog["into_level"]), int(prog["needed"]),
		int(s.get("xp_gained", 0))), "LabelMuted")
	line.name = "PassXpLine"
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	line.clip_text = true
	line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(line)
	# Progress bar: a Panel (not a container) so the partial fill keeps its width.
	var track := Panel.new()
	track.custom_minimum_size = Vector2(0, 16)
	track.clip_contents = true
	track.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("hp_track"), 8, 2, UI3Theme.color("disabled_border")))
	col.add_child(track)
	var fill := ColorRect.new()
	fill.color = UI3Theme.color("accent")
	fill.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	fill.anchor_right = clampf(float(prog.get("percent", 0.0)) / 100.0, 0.0, 1.0)
	fill.offset_right = 0.0
	track.add_child(fill)
	return card


## "380 / 500 XP · Lv 8 pays 80 shard", from this build's own BP track; the tail only claims a shard payout
## when the next milestone really is one.
func _pass_xp_line(level: int, into: int, needed: int, xp_gained: int) -> String:
	if needed <= 0:
		return tr("Max level") + " · " + tr("+%d XP this run") % xp_gained
	var head := "%d / %d XP" % [into, needed]
	for entry in ContentDB.BP_TRACK:
		var e: Dictionary = entry
		if int(e.get("lv", 0)) == level + 1 and String(e.get("type", "")) == "shard":
			return "%s · %s" % [head, tr("Lv %d pays %d shard") % [level + 1, int(e.get("value", 0))]]
	return "%s · %s" % [head, tr("+%d XP this run") % xp_gained]


func _build_relics_card(relic_ids: Array) -> Control:
	var card := UI3.plate(&"row")
	card.name = "RelicsCard"
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	card.add_child(col)
	col.add_child(_card_caption(tr("Relics carried") + " · %d" % relic_ids.size()))
	if relic_ids.is_empty():
		col.add_child(UI3.label(tr("None this run.")))
		return card
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 8)
	col.add_child(flow)
	for id in relic_ids:
		var def = RelicRegistry.get_def(String(id))
		var p := UI3.plate(&"row")
		p.add_child(UI3.label(UI3.title_case(UI3.player_text(String(def.name) if def != null else String(id))), "LabelDisplay"))
		flow.add_child(p)
	return card


## Mission runs: the stake settles with the run. Won = payout (it includes the stake) comes back; lost = the
## stake is gone. A stake the server settles later says so instead of guessing.
func _build_stake_box(s: Dictionary) -> Control:
	var e: Dictionary = s.get("stake_before", {})
	var stake := int(e.get("stake", 0))
	if not bool(s.get("mission_run", false)) or stake <= 0:
		return null
	var box: PanelContainer
	if bool(s.get("stake_open", false)):
		box = UI3.trade_box(&"gain", tr("Your %d Shard stake settles with the server. Check Missions.") % stake)
	elif bool(s.get("mission_won", false)):
		box = UI3.trade_box(&"gain", tr("Mission won. Your %d Shard stake comes back as %d Shards.") % [stake, int(e.get("payout", 0))])
	else:
		box = UI3.trade_box(&"cost", tr("Mission lost. You lose your %d Shard stake.") % stake)
	box.name = "StakeBox"
	return box


# ---------------------------------------------------------------------------
# Offline notice: the ranked score submit ended without a score on the board.
# ---------------------------------------------------------------------------
## Hook for the real submit status (not wired yet, see _ready): ok = score is on the board, otherwise code is
## "offline" or "server". Shows the notice with Retry.
func show_submit_notice(ok: bool, code: String) -> void:
	_show_notice(ok, code)


func _show_notice(ok: bool, code: String, retrying := false) -> void:
	for c in _notice_host.get_children():
		_notice_host.remove_child(c)
		c.queue_free()
	if ok:
		return
	var msg := tr("Score not submitted: you are offline. Your run and rewards are saved.") if code == "offline" \
		else tr("Score not submitted: the server did not accept it. Your run and rewards are saved.")
	var n := UI3.net_notice(msg, tr("Retry"), _retry_submit, retrying)
	n.name = "NetNotice"
	_notice_host.add_child(n)
	_on_notice_layout()


func _retry_submit() -> void:
	if _run_id == "":
		return
	_show_notice(false, "offline", true)
	RemoteLeaderboardSource.new().submit_run(_run_id, func(ok: bool, d: Dictionary) -> void:
		if is_inside_tree():
			_show_notice(ok, "" if ok else String(d.get("code", "server"))))


func _save_run_record(log: ActionLog) -> String:
	var stamp := Time.get_datetime_string_from_system().replace(":", "-")
	var path := "user://run_record_%s.json" % stamp
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return ""
	f.store_string(JSON.stringify(log.to_data()))
	f.close()
	return ProjectSettings.globalize_path(path)


# ---------------------------------------------------------------------------
# Actions: Run again (secondary) and Back to Land (primary L, expand). Both go to the main menu (FLAGGED).
# ---------------------------------------------------------------------------
func _build_actions() -> Control:
	var host := HBoxContainer.new()
	host.name = "Footer"
	host.add_theme_constant_override("separation", 16)
	var again := UI3.button(tr("Run again"), &"secondary", &"M")
	again.name = "RunAgain"
	again.custom_minimum_size.y = UI3Theme.size_of("btn_l")
	again.pressed.connect(_on_menu_pressed)
	host.add_child(again)
	_back = UI3.button(tr("Back to Land"), &"primary", &"L")
	_back.name = "BackButton"
	_back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_back.pressed.connect(_on_menu_pressed)
	host.add_child(_back)
	return host


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if is_inside_tree():   # a handler above may have changed scene
			get_viewport().set_input_as_handled()
		_on_menu_pressed()


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")
