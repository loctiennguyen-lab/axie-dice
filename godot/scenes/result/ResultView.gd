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
const PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")
const Parts := preload("res://scenes/result/ui5/ResultParts.gd")

var _plate: Control = null
var _plate_scroll: ScrollContainer = null
var _body: VBoxContainer = null
var _notice_host: VBoxContainer = null
var _run_id := ""
var _snap: Dictionary = {}
var last_card_text := ""   ## test hook: what the last "Copy run card" sent to the clipboard (headless has no clipboard)
var _back: Button = null
var _copy_btn: Button = null
var _copy_slot: HBoxContainer = null


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

	if PassView.seen_level < 0:
		PassView.seen_level = PassV2.level_for_xp(int(MetaState.pass_season.get("xp", 0)))   # so the Pass screen can play its level-up
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
	_back.grab_focus.call_deferred()
	_play_end_moment()


func _build_ui(s: Dictionary) -> void:
	var bg := TextureRect.new()
	bg.name = "PlateHost"   # full-rect backdrop; t_ui_laws L0 (frame: ResultBackground)
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

	# `.res-plate`: result_plate_w wide, centred, top and bottom space 24 from the window; the card scroll takes the rest.
	var plate := UI3.plate(&"dialog")
	plate.name = "ResultPlate"
	var psb := UI3Theme.get_theme().get_stylebox("panel", "PanelDialog").duplicate() as StyleBox   # `.res-plate` padding 24 / 24 / 20 (shared dialog theme stays)
	psb.content_margin_left = UI3Theme.space("24")
	psb.content_margin_right = UI3Theme.space("24")
	psb.content_margin_top = UI3Theme.space("24")
	psb.content_margin_bottom = UI3Theme.space("20")
	plate.add_theme_stylebox_override("panel", psb)
	var w := UI3Theme.size_of("result_plate_w")
	var m := float(UI3Theme.space("24"))
	plate.anchor_left = 0.5
	plate.anchor_right = 0.5
	plate.anchor_top = 0.0
	plate.anchor_bottom = 1.0
	plate.offset_left = -w / 2.0
	plate.offset_right = w / 2.0
	plate.offset_top = m
	plate.offset_bottom = -m
	add_child(plate)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", UI3Theme.space("12"))
	plate.add_child(outer)

	outer.add_child(_build_header(s))
	var unlock := _build_title_unlock(s)
	if unlock != null:
		outer.add_child(unlock)
	outer.add_child(_build_party_row(s["roster"] as Array))
	outer.add_child(_build_stat_grid(s["stats"] as Dictionary))
	var best := _best_set_line(s["stats"] as Dictionary)
	if best != null:
		outer.add_child(best)
	_plate_scroll = ScrollContainer.new()
	_plate_scroll.name = "CardScroll"
	_plate_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_plate_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_plate_scroll.custom_minimum_size.y = 96.0
	_plate_scroll.get_v_scroll_bar().custom_minimum_size.x = UI3Theme.SCROLL_W   # visible overflow (t_ui_laws L2)
	outer.add_child(_plate_scroll)
	var inset := MarginContainer.new()   # `.rcard` margin-right 12: room for the scroll bar
	inset.name = "CardInset"
	inset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inset.add_theme_constant_override("margin_right", UI3Theme.space("12"))
	_plate_scroll.add_child(inset)
	_body = _build_card_rows(s)
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inset.add_child(_body)
	_notice_host = VBoxContainer.new()
	_notice_host.name = "NoticeHost"
	outer.add_child(_notice_host)   # outside the scroll: an offline notice is never hidden
	outer.add_child(_build_actions())
	_plate = plate

	_build_version_tag()
	_build_equipped_avatar()


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
	l.name = "VersionTag"
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
	col.add_theme_constant_override("separation", UI3Theme.space("4"))
	var new_best := won and int(s["power_level"]) > int(s["best_before"])
	if new_best:
		var chip := Parts.tag(tr("New best") + " · A%d" % int(s["ascension"]), "NewBestChip")
		chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(chip)
	var title := _centered(tr("Run won") if won else tr("Defeated"), "LabelDisplay")
	title.name = "Title"
	title.add_theme_font_size_override("font_size", UI3Theme.size_of("text_banner"))
	if not won:
		title.add_theme_color_override("font_color", UI3Theme.color("danger_text"))
	col.add_child(title)
	var sub := _centered("%s · A%d · %s" % [tr("Full run") if String(s["mode"]) == "full" else tr("Short run"),
		int(s["ascension"]), tr("Seed %d") % int(s["seed"])], "LabelMuted")
	sub.name = "SubLine"
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
	var row := Parts.tag(tr("New title: %s") % ", ".join(names), "NewTitleRow")   # `.tag.next`, stretched
	row.size_flags_horizontal = Control.SIZE_FILL
	(row.get_node("Text") as Label).name = "NewTitle"
	return row


# ---------------------------------------------------------------------------
# Party row: this run's five Axies (name, tier).
# ---------------------------------------------------------------------------
func _build_party_row(roster: Array) -> Control:
	var row := GridContainer.new()   # `.party-cells`: 5 equal columns, gap 8, no plates
	row.name = "PartyRow"
	row.columns = maxi(roster.size(), 1)
	row.add_theme_constant_override("h_separation", UI3Theme.space("8"))
	for e in roster:
		var entry: Dictionary = e
		var hero_key := String(entry.get("hero_key", ""))
		var def: Dictionary = ContentDB.heroes.get(hero_key, {})
		var cell := MarginContainer.new()   # `.party-cells .cell` padding 4
		cell.name = "PartyCell"
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for side in ["left", "right", "top", "bottom"]:
			cell.add_theme_constant_override("margin_" + side, UI3Theme.space("4"))
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 0)
		cell.add_child(v)
		var nm := _centered("", "LabelDisplay")
		nm.name = "PartyName"
		nm.autowrap_mode = TextServer.AUTOWRAP_OFF
		nm.clip_text = true
		nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		v.add_child(nm)
		Ui5Ellipsis.set_text(nm, String(def.get("n", hero_key)))   # B9: "Pomod…" at 1280, never "Pomodor"
		v.add_child(_centered("T%d" % int(entry.get("tier", 1)), "LabelMuted"))
		row.add_child(cell)
	return row


# ---------------------------------------------------------------------------
# Stats: 3-column grid, value Rowdies 24 over a muted label.
# ---------------------------------------------------------------------------
func _build_stat_grid(stats: Dictionary) -> Control:
	var grid := GridContainer.new()
	grid.name = "StatGrid"
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", UI3Theme.space("16"))
	grid.add_theme_constant_override("v_separation", UI3Theme.space("8"))
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
	var l := UI3.label("", "LabelDisplay")
	l.name = "BestSetLine"
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if b.is_empty() or int(b.get("size", 0)) < 3:
		l.text = tr("No Set this run. Next time try keeping 3 dice of the same part.")
	else:
		l.text = tr("Best set") + ": %s ×%d · %s" % [V4Ui.part_name(int(b.get("part", 0))), int(b["size"]), V4Ui.mult_text(int(b["m100"]))]
		# B5 (QA 29/10): accent_text is ink for amber fills (~1.2:1 on the plate); on the plate the highlight is `accent`.
		l.add_theme_color_override("font_color", UI3Theme.color("accent"))
	return l


# ---------------------------------------------------------------------------
# Earnings: Gene Shard, Lunacia Pass, relics, mission stake.
# ---------------------------------------------------------------------------
func _build_card_rows(s: Dictionary) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.name = "CardRow"
	col.add_theme_constant_override("separation", UI3Theme.space("8"))
	var stake := _build_stake_box(s)
	if stake != null:
		col.add_child(stake)
	col.add_child(_build_shard_card(s))
	col.add_child(_build_pass_card(s))
	var anchor := _build_anchor_card(s)
	if anchor != null:
		col.add_child(anchor)
	col.add_child(_build_relics_card(s["relic_ids"] as Array, String(s.get("run_rule", "")), s.get("core_impact", {}) as Dictionary))
	var combos := _build_combos_card(s)
	if combos != null:
		col.add_child(combos)
	var pad := Control.new()   # breathing room under the last card so the scroll never ends on a clipped line
	pad.name = "EndPad"
	pad.custom_minimum_size.y = 8
	col.add_child(pad)
	return col


## Lane GM (D3): combos the run put together (Pair / Full, Full in a gold frame) and the near-miss line "Skipped"
## (up to 3 Crystal Cores that were offered and not taken). Hidden when there is nothing to say and no combo data.
func _build_combos_card(s: Dictionary) -> Control:
	var done: Dictionary = s.get("combo_done", {})
	var skipped := RunCard.skipped_names(s.get("skipped_t", []) as Array)
	if done.is_empty() and skipped.is_empty() and ComboAdapter.all().is_empty():
		return null
	var c := Parts.card("CombosCard")
	var col: VBoxContainer = c["col"]
	col.add_child(_card_caption(tr("Combos") + " · %d" % done.size()))
	if done.is_empty():
		var none := UI3.label(tr("No combos this run."))
		none.name = "NoCombos"
		col.add_child(none)
	for cid in done:
		var full := String(done[cid]) == "full"
		col.add_child(Parts.combo_row(("ComboRowFull_%s" if full else "ComboRow_%s") % cid,
			UI3.title_case(ComboAdapter.display_name(String(cid))), full))
	if not skipped.is_empty():
		var sk := UI3.label(tr("Skipped") + ": " + ", ".join(skipped), "LabelMuted")
		sk.name = "SkippedLine"
		sk.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(sk)
	return c["card"]


## Own card ABOVE the Cores card: the run's Anchor, awake state and the Mutations it reached. null = no Anchor this run.
func _build_anchor_card(s: Dictionary) -> Control:
	var anchor_id := String(s.get("anchor_id", ""))
	if anchor_id == "":
		return null
	var c := Parts.card("AnchorCard")
	var col: VBoxContainer = c["col"]
	col.add_child(_card_caption(tr("Anchor")))
	col.add_child(_anchor_row(anchor_id, bool(s.get("anchor_awakened", false))))
	var mut := _mutation_line(s.get("house_tiers", {}) as Dictionary)
	if mut != null:
		col.add_child(mut)
	return c["card"]


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
	var c := Parts.card("ShardCard")
	var col: VBoxContainer = c["col"]
	var mrun := bool(s.get("mission_run", false))
	col.add_child(_card_caption(tr("Run reward (separate from your stake)") if mrun else tr("Gene Shard earned")))
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", UI3Theme.space("12"))
	col.add_child(line)
	var cur := HBoxContainer.new()
	cur.name = "CurLine"
	cur.add_theme_constant_override("separation", UI3Theme.space("8"))
	line.add_child(cur)
	var ic := TextureRect.new()
	ic.texture = UI3.icon("cur_shard")
	ic.custom_minimum_size = Vector2.ONE * UI3Theme.size_of("icon_m")
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cur.add_child(ic)
	var amount := PanelParts.text("+%s" % UI3.fmt(int(s["shards_this_run"])), "text_banner", "text", true)
	amount.name = "ShardAmount"
	amount.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cur.add_child(amount)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	right.add_theme_constant_override("separation", 0)
	line.add_child(right)
	var daily_bonus := ContentDB.DAILY_MISSION_SHARD if bool(s.get("daily_mission_granted", false)) else 0
	var breakdown := UI3.label((tr("%d from the run itself") if mrun else tr("%d run payout")) % (int(s["shards_this_run"]) - daily_bonus)
		+ (" · " + tr("%d daily") % daily_bonus if daily_bonus > 0 else ""), "LabelMuted")
	breakdown.name = "ShardBreakdown"
	breakdown.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	breakdown.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(breakdown)
	var pool := UI3.label(tr("Shards now %s") % UI3.fmt(MetaState.shard_pool), "LabelDisplay")
	pool.name = "ShardPool"
	pool.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pool.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(pool)
	if not mrun:   # a staked mission is never Ranked: "no verifiable score" would be the wrong message
		col.add_child(_build_ranked_caption(s))
	if bool(s.get("ranked", false)):
		# Neutral until RunState reports the real submit status (show_submit_notice). No fake "offline".
		var n := UI3.label(tr("Your score goes to the leaderboard when the run closes."))
		n.name = "SubmitLine"
		n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(n)
	return c["card"]


## The RANKED / SAVE RUN RECORD line (see the file header): three states, never a button that does nothing.
func _build_ranked_caption(s: Dictionary) -> Control:
	var row := VBoxContainer.new()
	row.name = "RankedCaption"
	row.add_theme_constant_override("separation", UI3Theme.space("8"))
	var label := UI3.label("", "LabelMuted")
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
	var btn := UI3.button(tr("Save run record"), &"quiet", &"S")   # a quiet link: max 2 secondaries on the screen
	btn.name = "SaveRecordButton"
	btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	row.add_child(btn)
	btn.pressed.connect(func() -> void:
		var path := _save_run_record(log)
		btn.disabled = true
		btn.visible = false
		if path != "":
			row.add_child(Parts.tone_line(tr("Saved to %s") % path, "SavedLine"))
		else:
			label.text = tr("Could not write the run record.")
			row.add_child(label))
	return row


func _build_pass_card(s: Dictionary) -> Control:
	var c := Parts.card("PassCard")
	var col: VBoxContainer = c["col"]
	col.add_child(_card_caption(tr(PassSummary.NAME)))
	var info: Dictionary = PassSummary.info(MetaState.pass_season)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", UI3Theme.space("12"))
	col.add_child(line)
	var left := HBoxContainer.new()
	left.add_theme_constant_override("separation", UI3Theme.space("12"))
	line.add_child(left)
	left.add_child(Parts.xp_disc())
	var lv := UI3.label(tr("Lv %d") % int(info["level"]), "LabelTitle")
	lv.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	left.add_child(lv)
	var xl := UI3.label(PassSummary.line(info, int(s.get("pass_xp_gained", -1))), "LabelMuted")
	xl.name = "PassXpLine"
	xl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	xl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	xl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	xl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART   # the design wraps this line, never cuts it
	line.add_child(xl)
	# Progress bar: a Panel (not a container) so the partial fill keeps its width.
	var track := Panel.new()
	track.name = "PassBar"
	track.custom_minimum_size = Vector2(0, UI3Theme.size_of("hp_bar_l"))
	track.clip_contents = true
	track.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("hp_track"), UI3Theme.radius("pill"), 0, Color.TRANSPARENT))
	col.add_child(track)
	var fill := ColorRect.new()
	fill.color = UI3Theme.color("accent")
	fill.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	fill.anchor_right = clampf(float(info["percent"]) / 100.0, 0.0, 1.0)
	fill.offset_right = 0.0
	track.add_child(fill)
	return c["card"]


## Depth v3: the run's Cores plus the Run Rule it played under (the old "Relics carried" card).
func _build_relics_card(relic_ids: Array, run_rule_id: String = "", impact: Dictionary = {}) -> Control:
	var c := Parts.card("CoresCard")
	var col: VBoxContainer = c["col"]
	col.add_child(_card_caption(tr("Cores") + " · %d" % relic_ids.size()))
	if run_rule_id != "":
		var rdef = RelicRegistry.get_def(run_rule_id)
		var rname := String(rdef.name) if rdef != null else run_rule_id
		col.add_child(UI3.label(tr("Run Rule") + ": " + UI3.title_case(UI3.player_text(rname))))
	if relic_ids.is_empty():
		col.add_child(UI3.label(tr("None this run.")))
		return c["card"]
	# Depth v3 lane VZ: one line per Core with what it did this run; the biggest contributor is marked "Most impact".
	var ids: Array = relic_ids.map(func(x): return String(x))
	var real_ids: Array = ids.filter(func(x): return not RelicSlots.is_pact(String(x)))   # Pacts never take "Most impact"
	var top := CoreFeedback.top_core(impact, real_ids)
	var list := VBoxContainer.new()
	list.name = "CoreImpactList"
	list.add_theme_constant_override("separation", UI3Theme.space("8"))
	col.add_child(list)
	for id in ids:
		var def = RelicRegistry.get_def(String(id))
		var row := HBoxContainer.new()   # `.line`: name left, what it did right
		row.name = "CoreRow_%s" % id
		row.add_theme_constant_override("separation", UI3Theme.space("12"))
		var nm := UI3.label(UI3.title_case(UI3.player_text(String(def.name) if def != null else String(id))), "LabelDisplay")
		nm.name = "CoreName"
		nm.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		if String(id) == top:
			nm.add_theme_color_override("font_color", UI3Theme.color("accent"))
		row.add_child(nm)
		var e: Dictionary = impact.get(String(id), {})
		var is_pact := RelicSlots.is_pact(String(id))
		var txt := CoreFeedback.impact_text(e) if not e.is_empty() else tr("Not triggered this run")
		if is_pact:
			txt = tr("Pact · passive")
			if def != null and String(def.description) != "":
				txt += "\n" + UI3.player_text(String(def.description))
		if String(id) == top:
			txt = tr("Most impact") + " · " + txt
		var im := UI3.label(txt, "LabelMuted" if (e.is_empty() or is_pact) else "")
		im.name = "CoreImpact"
		im.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		im.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		im.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(im)
		list.add_child(row)
	return c["card"]


## Mission runs: the stake settles with the run. Won = payout (it includes the stake) comes back; lost = the
## stake is gone. A stake the server settles later says so instead of guessing.
func _build_stake_box(s: Dictionary) -> Control:
	var e: Dictionary = s.get("stake_before", {})
	var stake := int(e.get("stake", 0))
	if not bool(s.get("mission_run", false)) or stake <= 0:
		return null
	var won := bool(s.get("mission_won", false))
	var next_line := _next_tier_line(String(e.get("tier", "")), won).strip_edges()
	var bg := "chip"   # `.stakebox.wait` / `.won` / `.lost`
	var msg := ""
	var st := UI3.fmt(stake)
	if bool(s.get("stake_open", false)):
		msg = tr("Your %s Shards stake settles with the server. Check Missions.") % st
		next_line = ""
	elif won:
		bg = "success_bg"
		msg = tr("Mission won. Your %s Shards stake comes back as %s Shards, +%s Stone.") % [st, UI3.fmt(int(e.get("payout", 0))), UI3.fmt(int(e.get("stone", 0)))]
	else:
		bg = "danger_bg"
		msg = tr("Mission lost. You lose your %s Shards stake (−%s Shards). No payout, no Stone.") % [st, st]
	var box := PanelParts.panel(UI3Theme.flat(UI3Theme.color(bg), UI3Theme.radius("m"), 0, Color.TRANSPARENT,
		Vector4(UI3Theme.space("16"), UI3Theme.space("12"), UI3Theme.space("16"), UI3Theme.space("12"))), "StakeBox")
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI3Theme.space("4"))
	box.add_child(v)
	var l := UI3.label(msg, "LabelDisplay")
	l.name = "StakeText"
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(l)
	if next_line != "":
		var n := UI3.label(next_line)
		n.name = "StakeNext"
		n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(n)
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
	var host := VBoxContainer.new()   # `.res-actions`: [Run again ... Copy run card] over the full-width Back button
	host.name = "Actions"
	host.add_theme_constant_override("separation", UI3Theme.space("12"))
	var mission_run := bool(_snap.get("mission_run", false))
	var sub := HBoxContainer.new()
	sub.name = "SubActions"
	sub.add_theme_constant_override("separation", UI3Theme.space("12"))
	host.add_child(sub)
	var again := UI3.button(tr("Play a normal run") if mission_run else tr("Run again"), &"secondary", &"S")
	again.name = "RunAgainButton"
	again.pressed.connect(_on_menu_pressed)
	sub.add_child(again)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sub.add_child(sp)
	_copy_slot = HBoxContainer.new()
	_copy_slot.name = "CopySlot"
	_copy_slot.add_theme_constant_override("separation", UI3Theme.space("8"))
	sub.add_child(_copy_slot)
	_copy_btn = UI3.button(tr("Copy run card"), &"quiet", &"S")   # quiet: the screen already has its secondary button
	_copy_btn.name = "CopyButton"
	_copy_btn.pressed.connect(_on_copy_card.bind(_copy_btn))
	_copy_slot.add_child(_copy_btn)
	_back = UI3.button(tr("Back to Missions") if mission_run else tr("Back to Land"), &"primary", &"L")
	_back.name = "BackButton"
	_back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_back.custom_minimum_size.y = UI3Theme.size_of("btn_l")
	_back.pressed.connect(_on_missions_pressed if mission_run else _on_menu_pressed)
	_back.tooltip_text = tr("Space or Enter")
	var cap := Ui5Keycap.make("Space", &"primary")   # the one key on screen (Space)
	cap.name = "KeyCap"
	_back.add_child(cap)
	_back.resized.connect(_place_cap.bind(cap))
	host.add_child(_back)
	return host


## KeyCap: HTML `.btn` centres the whole group [label + 12 + keycap]. Every button style gets content_margin_right
## widened by cap width + 12 so the label shifts left; the keycap sits 12 px after the label, centred vertically.
func _place_cap(cap: Control) -> void:
	if _back == null or not is_instance_valid(cap):
		return
	cap.size = cap.get_combined_minimum_size()
	var extra := cap.size.x + float(UI3Theme.space("12"))
	var ml := 0.0
	var mrt := 0.0
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sb := UI3Theme.get_theme().get_stylebox(st, String(_back.theme_type_variation))
		if sb == null:
			continue
		var d := sb.duplicate() as StyleBox
		if not _back.has_meta("cap_base_" + st):
			_back.set_meta("cap_base_" + st, d.content_margin_right if d.content_margin_right >= 0.0 else sb.get_margin(SIDE_RIGHT))
		var base := float(_back.get_meta("cap_base_" + st))
		d.content_margin_right = base + extra
		if d.content_margin_left < 0.0:
			d.content_margin_left = sb.get_margin(SIDE_LEFT)
		_back.add_theme_stylebox_override(st, d)
		if st == "normal":
			ml = d.content_margin_left
			mrt = d.content_margin_right
	var font := _back.get_theme_font("font")
	var fs := _back.get_theme_font_size("font_size")
	var tw := font.get_string_size(_back.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	cap.position = Vector2((ml + _back.size.x - mrt + tw) / 2.0 + UI3Theme.space("12"), (_back.size.y - cap.size.y) / 2.0)


## Lane GM (D4): run card text to the clipboard; the button says "Copied" for the next click.
func _on_copy_card(btn: Button) -> void:
	last_card_text = RunCard.text(_snap)
	DisplayServer.clipboard_set(last_card_text)
	btn.visible = false   # CopiedLine (ToneDisc + "Copied") takes its place
	btn.disabled = true
	if _copy_slot.get_node_or_null("CopiedLine") == null:
		_copy_slot.add_child(Parts.tone_line(tr("Copied"), "CopiedLine"))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if is_inside_tree():   # a handler above may have changed scene
			get_viewport().set_input_as_handled()
		_on_menu_pressed()


func _on_missions_pressed() -> void:
	LandNav.open(&"missions")


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")


## UI-05 b23 lane M3: `run-end-win` / `run-end-lose` from motion_ui3.json. Input is never locked (the Back-unlock row is data).
## Not in instant / headless runs. The XP fill has no node here; Space stays "Back to Land", so skip is a click on the scrim.
func _play_end_moment() -> void:
	if UI3Gacha.is_instant() or DisplayServer.get_name() == "headless" or _plate == null:
		return
	await get_tree().process_frame
	if not is_inside_tree() or _plate == null:
		return
	var won := bool(_snap.get("won", false))
	var tg := {"scrim": find_child("Scrim", false, false), "plate": _plate}
	var title := find_child("Title", true, false) as Control
	if title != null:
		title.pivot_offset = title.size / 2.0
		tg["title"] = title
	var grid := find_child("StatGrid", true, false)
	var counts := {}
	var count_cb := Callable()
	if grid != null:
		tg["stats"] = grid.get_children()
		var dmg := (grid.get_child(2).get_child(0) as Label) if grid.get_child_count() > 2 else null
		if dmg != null:
			tg["damage"] = dmg
			counts["damage_count"] = [0, int((_snap["stats"] as Dictionary).get("damage_dealt", 0))]
	if _body != null:
		tg["cards"] = _body.get_children()
	var amt := find_child("ShardAmount", true, false)
	if amt != null:
		tg["shards"] = amt
		counts["shards_count"] = [0, int(_snap.get("shards_this_run", 0))]
	UI3Motion.play_timeline("run-end-win" if won else "run-end-lose", tg, {"host": self, "counts": counts})
