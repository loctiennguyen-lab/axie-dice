extends Control
## Result.tscn root - UI-03 10 (round 2 wins): one 640 plate on a pre-rendered arena of the run's biome (boss biome on a win, the biome you fell in on a loss) with a scrim. Header (badge,
## "Run won" / "Defeated", sub line), title-unlock row, party row, 3-column stat grid, earnings rows (Gene
## Shard, Lunacia Pass XP, relics, mission stake), the offline notice and the two actions. Pure view over the
## RunState snapshot taken BEFORE end_run() (architecture plan 3.2.4); every reward and submit path is the
## one RunState already runs.
##
## RANKED / SAVE RUN RECORD is a real, shipped feature (t_result_screen pins its three states) kept as a
## caption in the Gene Shard card. FLAGGED: "Run again" still goes to the main menu (nothing restarts a run
## from a seed). FLAGGED: party HP is always full here (RunState.roster has no current HP between fights).
## FLAGGED: the Pass XP icon is missing from the art kit, so it is the spec's "XP" circle.

const BG_DIR := "res://assets/ui3/result_bg/"   # pre-rendered empty biome arenas (Blender dioramas), 1440x810 jpg
const BG_FALLBACK := "savannah"

var _plate: Control = null
var _shard_amount: Label = null   # the hero count-up target (null on a lost stake)
var _shard_src: Label = null
var _body: VBoxContainer = null
var _notice_host: VBoxContainer = null
var _run_id := ""
var _snap: Dictionary = {}
var last_card_text := ""   ## test hook: what the last "Copy run card" sent to the clipboard (headless has no clipboard)
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
		"relic_ids": RunState.owned_relic_ids.filter(func(x) -> bool:
			return not String(x).begins_with("__") and String(x) != RunState.run_rule),
		"run_rule": RunState.run_rule,
		"core_impact": RunState.core_impact.duplicate(true),
		"combo_done": ComboAdapter.done().duplicate(),            # lane GM: before end_run() clears the run
		"skipped_t": ComboAdapter.skipped_t().duplicate(),
		"anchor_id": AnchorAdapter.current_id(),                  # Anchor lane: read before end_run() clears the run
		"anchor_awakened": AnchorAdapter.awakened(),
		"house_tiers": RunState.house_tiers_now() if RunState.has_method("house_tiers_now") else {},
		"roster": RunState.roster.duplicate(true),
		"stats": RunStatsAccumulator.snapshot(RunState.mode),
		"ranked": RunState.ranked,
		"action_log": RunState.action_log,
		# Taken BEFORE end_run() pushes this run's XP in, so the "+N levels" pill can say how
		# many levels THIS run bought rather than what level the player happens to be.
		"pass_xp_before": int(MetaState.pass_season.get("xp", 0)),
		"pass_season_before": String(MetaState.pass_season.get("id", "")),
		"best_before": MetaState.best,
		"power_level": RunState.power_level,
		"stake_before": MetaState.mission_escrow.duplicate(),
		"mission_run": not RunState.mission.is_empty(),
	}
	var log: ActionLog = RunState.action_log
	_run_id = String(log.header.get("run_id", "")) if log != null else ""
	snapshot["mission_won"] = bool(RunState.mission_outcome(won)["won"])

	RunState.end_run(won)   # pushes shards + XP into MetaState
	# Pass XP granted this run: local = change in the Pass v2 state (day cap applied, 0 outside the season);
	# remote = the server counts it later, so no number is claimed (-1).
	var pass_after := int(MetaState.pass_season.get("xp", 0))
	snapshot["pass_xp_gained"] = -1 if MetaState.econ_remote() != null else (
		maxi(pass_after - int(snapshot["pass_xp_before"]), 0) if String(MetaState.pass_season.get("id", "")) == String(snapshot["pass_season_before"]) else 0)
	snapshot["daily_mission_granted"] = RunState.daily_mission_granted
	snapshot["new_titles"] = MetaState.last_run_new_titles.duplicate()   # C7: only this run's grants
	snapshot["stake_open"] = not MetaState.mission_escrow.is_empty()   # server-settled stakes close later

	_snap = snapshot
	_build_ui(snapshot)
	if bool(snapshot["ranked"]):
		# Neutral until RunState reports the real submit status (follow-up for the next RULES_VERSION bump,
		# which will call show_submit_notice). No fake "offline".
		var n := UI3.label(tr("Your score goes to the leaderboard when the run closes."), "LabelMuted")
		n.name = "SubmitLine"
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_notice_host.add_child(n)
	_play_motion.call_deferred()
	_back.grab_focus.call_deferred()


func _build_ui(s: Dictionary) -> void:
	var bg := TextureRect.new()
	bg.name = "PlateHost"   # full-rect backdrop; t_ui_laws L0
	bg.texture = load(_bg_path(bool(s["won"]))) as Texture2D
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

	# UI-04 10-result: one 880 panel, no inner scroll. Groups: header (title, sub, new title, party), Shards, Pass,
	# Stats, Cores (+ Anchor, Combos), tip, notices, footer.
	var plate := UI3.plate(&"dialog")
	plate.name = "ResultPlate"
	plate.custom_minimum_size = Vector2(UI3Theme.size_of("result_panel_w"), 0)
	center.add_child(plate)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 16)
	plate.add_child(outer)

	outer.add_child(_build_header(s))
	var unlock := _build_title_unlock(s)
	if unlock != null:
		outer.add_child(unlock)
	outer.add_child(_build_party_row(s["roster"] as Array))
	_body = _build_card_rows(s)
	outer.add_child(_body)
	_notice_host = VBoxContainer.new()
	_notice_host.name = "NoticeHost"
	outer.add_child(_notice_host)   # an offline notice is never hidden
	outer.add_child(_build_actions())
	_plate = plate

	_build_version_tag()
	_build_equipped_avatar()


## UI-04 run_end_win / run_end_lose: panel scale 0.96 -> 1 + fade, and the Shard hero counts up on a win.
func _play_motion() -> void:
	if _plate == null:
		return
	_plate.pivot_offset = _plate.size * 0.5
	var won := bool(_snap.get("won", false))
	UI3Motion.play("run_end_win" if won else "run_end_lose", _plate)
	if won and _shard_amount != null and not UI3Motion.reduced() and DisplayServer.get_name() != "headless":
		var total := int(_snap.get("shards_this_run", 0))
		var lbl := _shard_amount
		var tw := create_tween()
		tw.tween_method(func(v: float) -> void:
			if is_instance_valid(lbl):
				lbl.text = tr("+%s Shards") % UI3.fmt(int(v)), 0.0, float(total), 0.8).set_delay(0.24) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.finished.connect(func() -> void:
			if is_instance_valid(lbl):
				lbl.text = tr("+%s Shards") % UI3.fmt(total))


## Backdrop jpg for the run's biome: the boss biome on a win, the biome of the node the run ended on
## on a loss (same CombatArena3D.biome_for the fights used). Falls back to savannah.
func _bg_path(won: bool) -> String:
	var g := RunMapGraph.from_data(RunState.map_graph) if not RunState.map_graph.is_empty() else null
	var biome := ""
	if g != null and not g.boss_rows.is_empty():
		var total := g.rows.size()
		var row := int(g.boss_rows[0])
		var is_boss := true
		if not won:
			var n := g.find_node(RunState.current_node_id)
			if n != null:
				row = n.row
				is_boss = n.node_type == "boss"
		biome = CombatArena3D.biome_for(row, is_boss, total)
	var path := BG_DIR + biome + ".jpg"
	return path if biome != "" and ResourceLoader.exists(path) else BG_DIR + BG_FALLBACK + ".jpg"


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
	title.add_theme_font_size_override("font_size", UI3Theme.size_of("text_banner"))   # spec: title 36
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
		var nm := _centered("%s · T%d" % [String(def.get("n", hero_key)), int(entry.get("tier", 1))], "LabelMuted")
		nm.autowrap_mode = TextServer.AUTOWRAP_OFF
		nm.clip_text = true
		nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		p.add_child(nm)
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


## "Best set: FIVE HORNS ×2.6" (combat-v4.md 6.2). Reads `best_bo` {part,size,m100} from the run stats; while
## RunStatsAccumulator has no such field (it needs the v4 RULES_VERSION bump) the line is not drawn at all.
## Present but empty = a run without a Set: one encouraging line.
func _best_set_line(stats: Dictionary) -> Control:
	if not stats.has("best_bo"):
		return null
	var b: Dictionary = stats["best_bo"] if stats["best_bo"] is Dictionary else {}
	var l := UI3.label("", "LabelMuted")
	l.name = "BestSetLine"
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", UI3Theme.size_of("text_body"))   # UI-04: tip is body 18, not a 24 headline
	if b.is_empty() or int(b.get("size", 0)) < 3:
		l.text = tr("No Set this run. Next time try keeping 3 dice of the same part.")
		l.add_theme_color_override("font_color", UI3Theme.color("text_muted"))
	else:
		l.text = tr("Best set") + ": %s x%d  %s" % [V4Ui.part_name(int(b.get("part", 0))), int(b["size"]), V4Ui.mult_text(int(b["m100"]))]
		l.add_theme_color_override("font_color", UI3Theme.color("accent_text"))
	return l


func _build_card_rows(s: Dictionary) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.name = "CardRow"
	col.add_theme_constant_override("separation", 16)
	col.add_child(_build_shard_card(s))
	var stake := _build_stake_box(s)
	if stake != null:
		col.add_child(stake)
	col.add_child(_build_pass_card(s))
	col.add_child(_build_stat_grid(s["stats"] as Dictionary))
	col.add_child(_build_cores_group(s))
	var tip := _best_set_line(s["stats"] as Dictionary)
	if tip != null:
		col.add_child(tip)
	return col


## Cores group: Anchor line, the Cores card, Combos (only when there is something to say).
func _build_cores_group(s: Dictionary) -> Control:
	var g := VBoxContainer.new()
	g.name = "CoresGroup"
	g.add_theme_constant_override("separation", 8)
	var anchor := _build_anchor_card(s)
	if anchor != null:
		g.add_child(anchor)
	g.add_child(_build_relics_card(s["relic_ids"] as Array, String(s.get("run_rule", "")), s.get("core_impact", {}) as Dictionary))
	var combos := _build_combos_card(s)
	if combos != null:
		g.add_child(combos)
	return g


## A name chip: panel-raised, radius s, optional 4 px accent frame (Most impact / Full combo).
func _name_chip(text: String, count_text := "", framed := false) -> PanelContainer:
	var p := PanelContainer.new()
	p.theme = UI3Theme.get_theme()
	var sb := UI3Theme.flat(UI3Theme.color("panel_raised"), UI3Theme.radius("s"), 4 if framed else 0,
		UI3Theme.color("accent") if framed else UI3Theme.color("panel_raised"))
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	p.add_theme_stylebox_override("panel", sb)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	p.add_child(row)
	var nm := UI3.label(text, "LabelDisplay")
	nm.name = "CoreName"
	nm.add_theme_font_size_override("font_size", UI3Theme.size_of("text_body"))
	row.add_child(nm)
	if count_text != "":
		var c := UI3.label(count_text, "LabelDisplay")
		c.name = "CoreCount"
		c.add_theme_font_size_override("font_size", UI3Theme.size_of("text_body"))
		c.add_theme_color_override("font_color", UI3Theme.color("accent"))   # kam-6
		row.add_child(c)
	return p


## Combos: caption "COMBOS · n" + chips (Full = accent frame) + the near-miss "Skipped" line.
func _build_combos_card(s: Dictionary) -> Control:
	var done: Dictionary = s.get("combo_done", {})
	var skipped := RunCard.skipped_names(s.get("skipped_t", []) as Array)
	if done.is_empty() and skipped.is_empty() and ComboAdapter.all().is_empty():
		return null
	var card := UI3.plate(&"row")
	card.name = "CombosCard"
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	card.add_child(col)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	col.add_child(head)
	head.add_child(_card_caption(tr("Combos") + " · %d" % done.size()))
	if done.is_empty():
		var none := UI3.label(tr("No combos this run."), "LabelMuted")
		none.name = "NoCombos"
		head.add_child(none)
	else:
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 8)
		flow.add_theme_constant_override("v_separation", 8)
		col.add_child(flow)
		for cid in done:
			var full := String(done[cid]) == "full"
			var chip := _name_chip(UI3.title_case(ComboAdapter.display_name(String(cid))), tr("Full") if full else tr("Pair"), full)
			chip.name = "ComboRow_%s" % cid
			flow.add_child(chip)
	if not skipped.is_empty():
		var sk := UI3.label(tr("Skipped") + ": " + ", ".join(skipped), "LabelMuted")
		sk.name = "SkippedLine"
		sk.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(sk)
	return card


## Anchor: one row (house glyph, "Anchor · Name", awake state) + the Mutations line. null = no Anchor this run.
func _build_anchor_card(s: Dictionary) -> Control:
	var anchor_id := String(s.get("anchor_id", ""))
	if anchor_id == "":
		return null
	var card := UI3.plate(&"row")
	card.name = "AnchorCard"
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	card.add_child(col)
	col.add_child(_anchor_row(anchor_id, bool(s.get("anchor_awakened", false))))
	var mut := _mutation_line(s.get("house_tiers", {}) as Dictionary)
	if mut != null:
		col.add_child(mut)
	return card



func _anchor_row(id: String, awake: bool) -> Control:
	var row := HBoxContainer.new()
	row.name = "AnchorRow"
	var house := AnchorAdapter.house_id(id)
	var ic := TextureRect.new()
	ic.texture = UI3.icon(AnchorAdapter.house_icon(house))
	ic.custom_minimum_size = Vector2.ONE * UI3Theme.size_of("icon_m")
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.modulate = AnchorAdapter.house_color(house)
	row.add_child(ic)
	var nm := UI3.label("%s · %s" % [tr("Anchor"), AnchorAdapter.name_of(id)], "LabelDisplay")
	nm.name = "AnchorName"
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(nm)
	var st := UI3.label(tr("Awakened") if awake else tr("Not awakened"), "LabelDisplay" if awake else "LabelMuted")
	st.name = "AnchorState"
	if awake:
		st.add_theme_color_override("font_color", UI3Theme.color("anchor_awake"))
	row.add_child(st)
	return row


## "Mutations: Name (T1), Name (T2)" from the house tiers the run reached; null when none.
func _mutation_line(tiers: Dictionary) -> Control:
	var parts: Array[String] = []
	for h in tiers:
		var t := int(tiers[h])
		if t <= 0:
			continue
		var nm := String(AnchorAdapter.mutation_of(String(h))["name"])
		if nm != "":
			parts.append("%s (%s %d)" % [nm, tr("level"), t])
	if parts.is_empty():
		return null
	var l := UI3.label(tr("Mutations") + ": " + ", ".join(parts), "LabelMuted")
	l.name = "MutationsLine"
	l.mouse_filter = Control.MOUSE_FILTER_STOP
	UI3Tooltip.bind(l, tr("Mutations are upgrades to your Anchor's House. Each time you held more of its Cores this run, a mutation went up one level."))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


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
	var mrun := bool(s.get("mission_run", false))
	var stake := int((s.get("stake_before", {}) as Dictionary).get("stake", 0))
	# Loss with a settled stake (spec state 46): the hero is the stake gone, in a red-2 box, no particles.
	var lost_stake := mrun and not bool(s.get("mission_won", false)) and not bool(s.get("stake_open", false)) and stake > 0
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 72
	row.add_theme_constant_override("separation", 16)
	col.add_child(row)
	var ic := TextureRect.new()
	ic.name = "ShardGlyph"
	ic.texture = UI3.icon("cur_shard")
	ic.custom_minimum_size = Vector2.ONE * 72.0
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(ic)
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.alignment = BoxContainer.ALIGNMENT_CENTER
	mid.add_theme_constant_override("separation", 0)
	row.add_child(mid)
	var amount := UI3.label("", "LabelTitle")
	amount.name = "ShardAmount"
	amount.add_theme_font_size_override("font_size", UI3Theme.size_of("text_banner"))   # spec: 36
	if lost_stake:
		amount.text = "−" + tr("%s Shards") % UI3.fmt(stake)
		amount.add_theme_color_override("font_color", UI3Theme.color("danger_text"))
		var box := PanelContainer.new()
		box.name = "StakeLostBox"
		box.theme = UI3Theme.get_theme()
		box.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("trade_cost_bg"), UI3Theme.radius("m"), 0,
			Color.TRANSPARENT, Vector4(12, 4, 12, 4)))
		box.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		box.add_child(amount)
		mid.add_child(box)
	else:
		amount.text = tr("+%s Shards") % UI3.fmt(int(s["shards_this_run"]))
		mid.add_child(amount)
	_shard_amount = amount if not lost_stake else null
	var daily_bonus := ContentDB.DAILY_MISSION_SHARD if bool(s.get("daily_mission_granted", false)) else 0
	var src_text := tr("Mission stake lost") if lost_stake else (tr("Run reward, separate from your stake") if mrun
		else (tr("%d run payout") % (int(s["shards_this_run"]) - daily_bonus)
			+ (" · " + tr("%d daily") % daily_bonus if daily_bonus > 0 else "")))
	_shard_src = UI3.label(src_text, "LabelMuted")
	_shard_src.name = "ShardSource"
	_shard_src.clip_text = true
	_shard_src.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	mid.add_child(_shard_src)
	var right := VBoxContainer.new()
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	right.add_theme_constant_override("separation", 0)
	row.add_child(right)
	var cap := UI3.label(tr("Shards now"), "LabelMuted")
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(cap)
	var pool := UI3.label(UI3.fmt(MetaState.shard_pool), "LabelTitle")
	pool.name = "ShardPool"
	pool.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(pool)
	if not mrun:   # a staked mission is never Ranked: "no verifiable score" would be the wrong message
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
	var info: Dictionary = PassSummary.info(MetaState.pass_season)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	card.add_child(row)
	# The art kit has no Pass XP icon (spec flag): a plain "XP" circle stands in (48 in UI-04).
	var xp := PanelContainer.new()
	xp.name = "XpIcon"
	xp.custom_minimum_size = Vector2.ONE * 48.0
	xp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	xp.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("accent"),
		24, 0, Color.TRANSPARENT, Vector4(0, 0, 0, 0)))
	var xl := UI3.label("XP", "LabelDisplay")
	xl.add_theme_color_override("font_color", UI3Theme.color("die_ink"))
	xl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	xl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	xp.add_child(xl)
	row.add_child(xp)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 4)
	row.add_child(v)
	var head := UI3.label("%s · %s" % [tr(PassSummary.NAME), tr("Lv %d") % int(info["level"])], "LabelTitle")
	head.name = "PassHead"
	v.add_child(head)
	var line := UI3.label(PassSummary.line(info, int(s.get("pass_xp_gained", -1))), "LabelMuted")
	line.name = "PassXpLine"
	line.clip_text = true
	line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(line)
	# Progress bar 12 high: a Panel (not a container) so the partial fill keeps its width.
	var track := Panel.new()
	track.custom_minimum_size = Vector2(0, 12)
	track.clip_contents = true
	track.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("hp_track"), 6, 2, UI3Theme.color("disabled_border")))
	v.add_child(track)
	var fill := ColorRect.new()
	fill.color = UI3Theme.color("accent")
	fill.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	fill.anchor_right = clampf(float(info["percent"]) / 100.0, 0.0, 1.0)
	fill.offset_right = 0.0
	track.add_child(fill)
	return card



## Depth v3: the run's Cores plus the Run Rule, as ONE line (UI-04): caption "CORES · n", "none triggered this run"
## when nothing fired, then a name chip per Core ("×n" in accent when it fired). The per-Core detail (what it did,
## Most impact, Pact passive) moved into each chip's tooltip; the biggest contributor keeps the 4 px accent frame.
func _build_relics_card(relic_ids: Array, run_rule_id: String = "", impact: Dictionary = {}) -> Control:
	var card := UI3.plate(&"row")
	card.name = "RelicsCard"
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	card.add_child(col)
	var ids: Array = relic_ids.map(func(x): return String(x))
	var real_ids: Array = ids.filter(func(x): return not RelicSlots.is_pact(String(x)))   # Pacts never take "Most impact"
	var top := CoreFeedback.top_core(impact, real_ids)
	var any_fired := false
	for id in ids:
		if not RelicSlots.is_pact(String(id)) and int((impact.get(String(id), {}) as Dictionary).get("n", 0)) > 0:
			any_fired = true
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	col.add_child(head)
	head.add_child(_card_caption(tr("Cores") + " · %d" % ids.size()))
	if ids.is_empty():
		head.add_child(UI3.label(tr("None this run."), "LabelMuted"))
		return card
	if not any_fired:
		var none := UI3.label(tr("none triggered this run"), "LabelMuted")
		none.name = "NoneTriggered"
		head.add_child(none)
	if run_rule_id != "":
		var rdef = RelicRegistry.get_def(run_rule_id)
		var rname := String(rdef.name) if rdef != null else run_rule_id
		var rr := UI3.label(tr("Run Rule") + ": " + UI3.title_case(UI3.player_text(rname)), "LabelMuted")
		rr.name = "RunRuleLine"
		rr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rr.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		head.add_child(rr)
	var flow := HFlowContainer.new()
	flow.name = "CoreImpactList"
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 8)
	col.add_child(flow)
	for id in ids:
		var def = RelicRegistry.get_def(String(id))
		var e: Dictionary = impact.get(String(id), {})
		var is_pact := RelicSlots.is_pact(String(id))
		var n := int(e.get("n", 0))
		var is_top := String(id) == top
		var chip := _name_chip(UI3.title_case(UI3.player_text(String(def.name) if def != null else String(id))),
			("×%d" % n) if (n > 0 and not is_pact) else "", is_top)
		chip.name = "CoreRow_%s" % id
		var txt := CoreFeedback.impact_text(e) if not e.is_empty() else tr("Not triggered this run")
		if is_pact:
			txt = tr("Pact · passive")
			if def != null and String(def.description) != "":
				txt += "\n" + UI3.player_text(String(def.description))
		if is_top:
			txt = tr("Most impact") + " · " + txt
		chip.mouse_filter = Control.MOUSE_FILTER_STOP
		UI3Tooltip.bind(chip, txt)
		flow.add_child(chip)
	return card



## Mission runs: the stake settles with the run. Won = payout (it includes the stake) comes back; lost = the
## stake is gone. A stake the server settles later says so instead of guessing.
func _build_stake_box(s: Dictionary) -> Control:
	var e: Dictionary = s.get("stake_before", {})
	var stake := int(e.get("stake", 0))
	if not bool(s.get("mission_run", false)) or stake <= 0:
		return null
	var box: PanelContainer
	var won := bool(s.get("mission_won", false))
	var next_line := _next_tier_line(String(e.get("tier", "")), won)
	if bool(s.get("stake_open", false)):
		box = UI3.trade_box(&"gain", tr("Your %d Shard stake settles with the server. Check Missions.") % stake)
	elif won:
		box = UI3.trade_box(&"gain", (tr("Mission won. Your %d Shard stake comes back as %d Shards, +%d Stone.") % [stake, int(e.get("payout", 0)), int(e.get("stone", 0))]) + next_line)
	else:
		box = UI3.trade_box(&"cost", (tr("Mission lost. You lose your %d Shard stake (-%d Shards). No payout, no Stone.") % [stake, stake]) + next_line)
	box.name = "StakeBox"
	return box


## "\nN4 is still locked until you win N3." / "\nN4 is open." / "" for the last tier or an unknown id.
## After a loss nothing changes, so it reads the unlock cache as it is; after a win the server opens the next one.
func _next_tier_line(tier: String, won: bool) -> String:
	var ids := MissionBoard.tier_ids()
	var i := ids.find(tier)
	if i < 0 or i >= ids.size() - 1:
		return ""
	var nxt := String(ids[i + 1])
	if won:
		return "\n" + tr("%s opens once the server confirms the win.") % nxt
	if MissionBoard.tier_unlocked(nxt, MetaState):
		return "\n" + tr("%s is still open.") % nxt
	return "\n" + tr("%s stays locked until you win %s.") % [nxt, tier]


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
	if code == "offline" and _shard_src != null:
		_shard_src.text = tr("Saved, syncs when online")   # spec state 47
	var msg := tr("Score not submitted: you are offline. Your run and rewards are saved.") if code == "offline" \
		else tr("Score not submitted: the server did not accept it. Your run and rewards are saved.")
	var n := UI3.net_notice(msg, tr("Retry"), _retry_submit, retrying)
	n.name = "NetNotice"
	_notice_host.add_child(n)


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
	var mission_run := bool(_snap.get("mission_run", false))
	var again := UI3.button(tr("Play a normal run") if mission_run else tr("Run again"), &"secondary", &"M")
	again.name = "RunAgain"
	again.custom_minimum_size.y = UI3Theme.size_of("btn_l")
	again.pressed.connect(_on_menu_pressed)
	host.add_child(again)
	var copy := UI3.button(tr("Copy run card"), &"quiet", &"M")   # quiet: the screen already has its 2 secondary buttons (t_result_screen)
	copy.name = "CopyRunCard"
	copy.custom_minimum_size.y = UI3Theme.size_of("btn_l")
	copy.pressed.connect(_on_copy_card.bind(copy))
	host.add_child(copy)
	_back = UI3.button(tr("Back to Missions") if mission_run else tr("Back to Land"), &"primary", &"L")   # primary 72
	_back.name = "BackButton"
	_back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_back.pressed.connect(_on_missions_pressed if mission_run else _on_menu_pressed)
	host.add_child(_back)
	return host


## Lane GM (D4): run card text to the clipboard; the button says "Copied" for the next click.
func _on_copy_card(btn: Button) -> void:
	last_card_text = RunCard.text(_snap)
	DisplayServer.clipboard_set(last_card_text)
	btn.text = tr("Copied")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if is_inside_tree():   # a handler above may have changed scene
			get_viewport().set_input_as_handled()
		_on_menu_pressed()


func _on_missions_pressed() -> void:
	LandNav.open(&"missions")


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")

