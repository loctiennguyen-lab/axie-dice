extends Control
## Result.tscn root — v2 redesign (docs/design-handoff-v2, "Godot Run Flow v2.dc.html" RESULT
## tab + spec §06/§09). Replaces the v1 stacked-prose screen with the mockup's five-column
## party row, a single six-tile stat ribbon (fed by RunStatsAccumulator, §09), a three-card
## currency row, and two bottom CTAs. Reads the RunState snapshot BEFORE end_run() is called
## (architecture plan §3.2.4), same ordering rule the v1 file already followed.
##
## GEOMETRY SOURCE: party row top 262 (portrait 152, plate 168 overlapping -16, gap 28), stat
## ribbon top 558 height 106, card row top 692 (560-wide cream shard card, the only cream
## surface on the screen), CTAs 340/250 x72 at bottom 52 — all pinned numbers from the v2
## brief. Anything not given a pinned number below is marked `# FLAGGED:` with the value this
## file assumed, per this task's own instruction to pick a reasonable value and move on rather
## than re-extract the mockup HTML pixel by pixel.
##
## RANKED / SAVE RUN RECORD is a real, already-shipped feature (t_result_screen.gd pins all
## three of its states) that the v2 mockup's RESULT tab does not depict at all — the mockup
## has no ranked-score concept. `# FLAGGED:` — kept as a slim strip between the card row and
## the CTAs rather than dropped, since dropping it would regress a shipped feature nothing else
## surfaces.
##
## PARTY HP: `# FLAGGED:` — this port resets HP/shield/status to full between combats
## (damage_pipeline.gd's own header note; RunState.roster carries no "current hp" field), so
## there is no persisted "final HP below max" for a survived run — every surviving roster
## member always reads as full HP here. The mockup's hpColor/hpPct fields imply a live bar;
## a true partial-HP concept would need a RunState schema change, out of scope for this task.

@onready var _root: Control = self

const _RARITY_LABEL := ["Common", "Uncommon", "Rare", "Epic", "Legendary"]

# Stat-ribbon tile order + per-tile accent colour, taken verbatim from the mockup's `stats`
# array (WAVES/NODES CLEARED and TURNS TAKEN and KILLS are cream-white, DAMAGE DEALT is
# DANGER red, BIGGEST HIT is PRIMARY orange, AXIES LOST is SUCCESS green) — fixed per tile,
# not value-conditional; the mockup shows one static palette, not a threshold scheme.
const _TILE_ORDER := ["nodes", "turns", "damage", "kills", "biggest", "axies"]


func _ready() -> void:
	var won := RunState.phase == RunState.RunPhase.WON

	# Snapshot every field this screen needs OUT of RunState/RunStatsAccumulator before
	# end_run() runs — same ordering rule v1 followed (architecture plan §3.2.4).
	var snapshot := {
		"won": won,
		"mode": RunState.mode,
		"ascension": RunState.ascension,
		"seed": RunState.run_seed,
		"shards_this_run": RunState.shards_this_run,
		"relic_ids": RunState.owned_relic_ids.duplicate(),
		"roster": RunState.roster.duplicate(true),
		"stats": RunStatsAccumulator.snapshot(RunState.mode),
		"ranked": RunState.ranked,
		"action_log": RunState.action_log,
	}

	RunState.end_run(won)   # pushes shards + XP into MetaState (see v1's own note on ordering)
	snapshot["xp_gained"] = RunState.last_run_xp
	snapshot["pass_level"] = MetaState.bp_level()
	snapshot["daily_mission_granted"] = RunState.daily_mission_granted

	_build_ui(snapshot)


func _build_ui(s: Dictionary) -> void:
	_build_background()
	_build_title_band(s)
	_build_party_row(s["roster"] as Array)
	_build_stat_ribbon(s["stats"] as Dictionary)
	_build_card_row(s)
	_build_ranked_strip(s)   # FLAGGED addition — see file header
	_build_cta_row()


# ===========================================================================
# Background — plate + directional scrim (handoff §00/§Background formula, RESULT variant)
# ===========================================================================
func _build_background() -> void:
	var plate_host := Control.new()
	plate_host.name = "PlateHost"
	plate_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(plate_host)
	move_child(plate_host, 0)
	# FLAGGED: "entrance.jpg" — the exact background the RESULT tab mockup itself uses.
	DangoTheme.build_plate(plate_host, load("res://assets/backgrounds/origins/scene/4-entrance.jpg"), DangoTheme.Scrim.RESULT)


# ===========================================================================
# Title band — outcome chip, RUN COMPLETE, seed line. FLAGGED: vertical rhythm approximated
# via VBoxContainer auto-layout (chip / title / subtitle, small gaps) rather than the mockup's
# exact top:50 / margin-top:12 / margin-top:8 offsets — not one of the geometry numbers this
# task's brief pinned.
# ===========================================================================
func _build_title_band(s: Dictionary) -> void:
	var won := bool(s["won"])
	var accent := DangoTheme.SUCCESS if won else DangoTheme.DANGER

	var col := VBoxContainer.new()
	col.name = "TitleBand"
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 10)
	col.set_anchors_preset(Control.PRESET_TOP_WIDE)
	col.offset_top = 40.0
	col.offset_bottom = 40.0
	add_child(col)

	var chip := PanelContainer.new()
	chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	chip.add_theme_stylebox_override("panel", DangoTheme.solid_chip_style(accent, 10, 4, Vector2(18, 8)))
	col.add_child(chip)
	var chip_text := "%s · %s RUN · ASCENSION %d" % [
		"VICTORY" if won else "DEFEAT",
		"FULL" if String(s["mode"]) == "full" else "SHORT",
		int(s["ascension"]),
	]
	var chip_lbl := DangoTheme.display_label(chip_text, 14, DangoTheme.ink_on(accent))
	chip.add_child(chip_lbl)

	# FLAGGED: mockup is 92px; scaled down.
	var title := DangoTheme.display_label("RUN COMPLETE", 64, DangoTheme.CREAM_RAISED)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Seed %d · replayable from the main menu" % int(s["seed"])
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", DangoTheme.TEXT)
	col.add_child(subtitle)


# ===========================================================================
# Party row — top 262, portrait 152, plate 168 overlapping -16, gap 28 (pinned).
# ===========================================================================
func _build_party_row(roster: Array) -> void:
	var band := Control.new()
	band.name = "PartyRow"
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.set_anchors_preset(Control.PRESET_TOP_WIDE)
	band.offset_top = 262.0
	band.custom_minimum_size = Vector2(0, 310.0)
	add_child(band)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 28)
	row.set_anchors_preset(Control.PRESET_TOP_WIDE)
	band.add_child(row)

	for entry in roster:
		row.add_child(_build_party_column(entry as Dictionary))


func _build_party_column(e: Dictionary) -> Control:
	var hero_key := String(e.get("hero_key", ""))
	var hero_def: Dictionary = ContentDB.heroes.get(hero_key, {})
	var cls := String(hero_def.get("cls", ""))
	var accent := DangoTheme.class_color(cls)
	var effective_hp := int(e.get("max_hp", 0)) + int(e.get("bonus_hp", 0))

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", -16)   # the -16 overlap, pinned

	var portrait := PanelContainer.new()
	portrait.custom_minimum_size = Vector2(152, 152)
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var portrait_sb := StyleBoxFlat.new()
	portrait_sb.bg_color = accent
	portrait_sb.border_color = Color.BLACK
	portrait_sb.set_border_width_all(5)
	portrait_sb.set_corner_radius_all(26)
	portrait_sb.shadow_color = DangoTheme.SHELF_DEEP
	portrait_sb.shadow_size = 0
	portrait_sb.shadow_offset = Vector2(0, 8)
	portrait.add_theme_stylebox_override("panel", portrait_sb)
	col.add_child(portrait)

	var art := TextureRect.new()
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE   # see the relic-chip icon's comment below
	var art_path := "res://assets/portraits/%s.png" % cls
	if ResourceLoader.exists(art_path):
		art.texture = load(art_path)
	portrait.add_child(art)

	var plate := PanelContainer.new()
	plate.custom_minimum_size = Vector2(168, 0)
	plate.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	plate.add_theme_stylebox_override("panel",
		DangoTheme.surface_style(DangoTheme.Surface.PANEL_OVER_CLASS, 15, 3, 5.0, Vector2(12, 11)))
	col.add_child(plate)

	var plate_col := VBoxContainer.new()
	plate_col.alignment = BoxContainer.ALIGNMENT_CENTER
	plate_col.add_theme_constant_override("separation", 7)
	plate.add_child(plate_col)

	var name_lbl := DangoTheme.display_label(String(hero_def.get("n", hero_key)), 22, DangoTheme.CREAM_RAISED)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plate_col.add_child(name_lbl)

	var tier_row := HBoxContainer.new()
	tier_row.alignment = BoxContainer.ALIGNMENT_CENTER
	tier_row.add_theme_constant_override("separation", 9)
	plate_col.add_child(tier_row)

	var tier_lbl := DangoTheme.display_label("T%d" % int(e.get("tier", 1)), 12, DangoTheme.TEXT_DIM)
	tier_row.add_child(tier_lbl)

	# Always full HP — see file header FLAGGED note on why this port has no persisted
	# "current HP below max" for a roster entry between fights.
	var hp_lbl := DangoTheme.display_label("%d/%d" % [effective_hp, effective_hp], 16,
		DangoTheme.hp_color(1.0))
	tier_row.add_child(hp_lbl)

	var bar_bg := PanelContainer.new()
	bar_bg.custom_minimum_size = Vector2(138, 9)
	var bar_bg_sb := StyleBoxFlat.new()
	bar_bg_sb.bg_color = Color.BLACK
	bar_bg_sb.border_color = Color.BLACK
	bar_bg_sb.set_border_width_all(2)
	bar_bg_sb.set_corner_radius_all(5)
	bar_bg.add_theme_stylebox_override("panel", bar_bg_sb)
	plate_col.add_child(bar_bg)
	var bar_fill := ColorRect.new()
	bar_fill.color = DangoTheme.hp_color(1.0)
	bar_fill.set_anchors_preset(Control.PRESET_FULL_RECT)
	bar_bg.add_child(bar_fill)

	return col


# ===========================================================================
# Stat ribbon — top 558, height 106 (pinned). ONE dark panel, six flex columns divided by
# 2px rgba(255,147,69,.22) rules — not six wells.
# ===========================================================================
func _build_stat_ribbon(stats: Dictionary) -> void:
	var host := PanelContainer.new()
	host.name = "StatRibbon"
	host.set_anchors_preset(Control.PRESET_TOP_WIDE)
	host.offset_top = 558.0
	host.offset_left = 80.0
	host.offset_right = -80.0
	host.custom_minimum_size = Vector2(0, 106)
	host.add_theme_stylebox_override("panel",
		DangoTheme.surface_style(DangoTheme.Surface.PANEL_DEEP, 18, 4, 7.0, Vector2(26, 0)))
	add_child(host)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	host.add_child(row)

	var cleared := int(stats.get("nodes_cleared", 0))
	var total := int(stats.get("nodes_total", 0))
	var tiles := [
		["NODES CLEARED", "%d / %d" % [cleared, total], DangoTheme.CREAM_RAISED],
		["TURNS TAKEN", str(int(stats.get("turns_taken", 0))), DangoTheme.CREAM_RAISED],
		["DAMAGE DEALT", str(int(stats.get("damage_dealt", 0))), DangoTheme.DANGER],
		["KILLS", str(int(stats.get("kills", 0))), DangoTheme.CREAM_RAISED],
		["BIGGEST HIT", str(int(stats.get("biggest_hit", 0))), DangoTheme.PRIMARY],
		["AXIES LOST", str(int(stats.get("axies_lost", 0))), DangoTheme.SUCCESS],
	]
	for i in tiles.size():
		if i > 0:
			var divider := ColorRect.new()
			divider.color = DangoTheme.primary_divider_alpha()
			divider.custom_minimum_size = Vector2(2, 60)
			divider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(divider)
		row.add_child(_build_stat_tile(String(tiles[i][0]), String(tiles[i][1]), tiles[i][2]))


func _build_stat_tile(caption: String, value: String, color: Color) -> Control:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 7)
	col.alignment = BoxContainer.ALIGNMENT_CENTER

	var value_lbl := DangoTheme.display_label(value, 38, color)
	value_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	col.add_child(value_lbl)

	var caption_lbl := DangoTheme.display_label(caption, 11,
		DangoTheme.CAPTION_MUTED)
	col.add_child(caption_lbl)

	return col


# ===========================================================================
# Card row — top 692 (pinned). Gene Shard (560-wide cream card, the only cream surface on
# the screen) / Lunacia Pass / Relics carried, left to right, matching the mockup's own order.
#
# NOTE, a deliberate v2 change worth recording: v1 (2026-09-19 UX audit) put "RELICS
# COLLECTED" ABOVE the shard/pass totals on purpose — "the relics are the story of THIS run
# and belong above the shard/XP totals, which look the same after every run." The v2 mockup's
# card row reverses that, left to right: Shard, Pass, Relics. Per this task's own standing
# rule ("where the spec and a mockup disagree, the mockup is right"), the mockup's literal
# order is implemented here — t_result_and_stage.gd's ordering test is updated in the same
# commit with a comment pointing at this note.
# ===========================================================================
func _build_card_row(s: Dictionary) -> void:
	var host := Control.new()
	host.name = "CardRow"
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.set_anchors_preset(Control.PRESET_TOP_WIDE)
	host.offset_top = 692.0
	host.offset_left = 80.0
	host.offset_right = -80.0
	host.custom_minimum_size = Vector2(0, 150.0)   # FLAGGED: height not pinned; card content dictates
	add_child(host)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.add_child(row)

	row.add_child(_build_shard_card(s))
	row.add_child(_build_pass_card(s))
	row.add_child(_build_relics_card(s["relic_ids"] as Array))


func _build_shard_card(s: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(560, 0)
	card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	# BUG FIX (caught in this task's own screenshot QA): cream_card_style()'s default pad is
	# Vector2(-1, -1) — surface_style()'s own convention for "leave margins at Godot's zero",
	# meant for callers that add their own MarginContainer. This card never did, so its content
	# sat flush against the panel edge and its top caption read as clipped. 18/22 matches the
	# mockup's own `padding:18px 22px` on this exact card.
	var shard_card_sb := DangoTheme.cream_card_style()
	shard_card_sb.content_margin_left = 22.0
	shard_card_sb.content_margin_right = 22.0
	shard_card_sb.content_margin_top = 18.0
	shard_card_sb.content_margin_bottom = 18.0
	card.add_theme_stylebox_override("panel", shard_card_sb)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	card.add_child(col)

	var caption := DangoTheme.display_label("GENE SHARD EARNED", 12,
		Color(0x8A / 255.0, 0x74 / 255.0, 0x50 / 255.0))
	col.add_child(caption)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	col.add_child(row)

	var amount_group := HBoxContainer.new()
	amount_group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	amount_group.add_theme_constant_override("separation", 13)
	row.add_child(amount_group)

	var shard_icon := TextureRect.new()
	shard_icon.custom_minimum_size = Vector2(44, 44)
	shard_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	shard_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE   # see relic-chip icon's comment
	const _SHARD_ICON_PATH := "res://assets/icons/web/shard.png"
	if ResourceLoader.exists(_SHARD_ICON_PATH):
		shard_icon.texture = load(_SHARD_ICON_PATH)
	amount_group.add_child(shard_icon)

	var amount := DangoTheme.display_label("+%d" % int(s["shards_this_run"]), 58, DangoTheme.INK)
	amount_group.add_child(amount)

	# BUG FIX (caught in this task's own screenshot QA): a real vault total ("POOL NOW 29055")
	# is wider than the mockup's placeholder ("POOL NOW 748") and, with `right` given no width
	# budget of its own, the label's natural single-line width could exceed what was left of
	# the fixed 560px card and spill past the panel's edge. `right` now shares the row's width
	# with `amount_group` (both SIZE_EXPAND_FILL) and both wide labels clip to an ellipsis
	# rather than overflow, so this holds regardless of how large the pool or payout ever get.
	var right := VBoxContainer.new()
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right)

	var breakdown := Label.new()
	var daily_bonus := ContentDB.DAILY_MISSION_SHARD if bool(s.get("daily_mission_granted", false)) else 0
	breakdown.text = "%d run payout%s" % [
		int(s["shards_this_run"]) - daily_bonus,
		"  ·  %d daily" % daily_bonus if daily_bonus > 0 else "",
	]
	breakdown.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	breakdown.clip_text = true
	breakdown.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	breakdown.add_theme_font_size_override("font_size", 13)
	breakdown.add_theme_color_override("font_color", DangoTheme.INK_ON_CREAM_MUTED)
	right.add_child(breakdown)

	var pool := DangoTheme.display_label("POOL NOW %d" % MetaState.shard_pool, 19, DangoTheme.INK)
	pool.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pool.clip_text = true
	pool.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	right.add_child(pool)

	return card


func _build_pass_card(s: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	card.add_theme_stylebox_override("panel",
		DangoTheme.surface_style(DangoTheme.Surface.PANEL_DEEP, 18, 4, 7.0, Vector2(22, 18)))

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 11)
	card.add_child(col)

	var caption := DangoTheme.display_label("LUNACIA PASS", 12,
		DangoTheme.CAPTION_MUTED)
	col.add_child(caption)

	var prog: Dictionary = MetaState.bp_progress()
	var level_row := HBoxContainer.new()
	level_row.add_theme_constant_override("separation", 12)
	col.add_child(level_row)

	var lv := DangoTheme.display_label("LV %d" % int(prog["level"]), 44, DangoTheme.CREAM_RAISED)
	level_row.add_child(lv)

	var xp_lbl := Label.new()
	xp_lbl.text = "+%d XP this run  ·  %d XP total" % [int(s.get("xp_gained", 0)), MetaState.xp]
	xp_lbl.add_theme_font_size_override("font_size", 13)
	xp_lbl.add_theme_color_override("font_color", DangoTheme.MUTED_TEXT)
	level_row.add_child(xp_lbl)

	return card


func _build_relics_card(relic_ids: Array) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(392, 0)
	card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	card.add_theme_stylebox_override("panel",
		DangoTheme.surface_style(DangoTheme.Surface.PANEL_DEEP, 18, 4, 7.0, Vector2(20, 18)))

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	card.add_child(col)

	var caption := DangoTheme.display_label("RELICS CARRIED · %d" % relic_ids.size(), 12,
		DangoTheme.CAPTION_MUTED)
	col.add_child(caption)

	if relic_ids.is_empty():
		var none_lbl := Label.new()
		none_lbl.text = "None this run."
		none_lbl.add_theme_font_size_override("font_size", 13)
		none_lbl.add_theme_color_override("font_color", DangoTheme.TEXT_DIM)
		col.add_child(none_lbl)
		return card

	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 9)
	flow.add_theme_constant_override("v_separation", 9)
	col.add_child(flow)
	for relic_id in relic_ids:
		flow.add_child(_build_relic_chip(String(relic_id)))

	return card


func _build_relic_chip(relic_id: String) -> PanelContainer:
	var def = RelicRegistry.get_def(relic_id)
	var display_name := String(def.name) if def != null else relic_id
	var rarity := int(def.rarity) if def != null else 0
	var accent := DangoTheme.rarity_color(rarity)

	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override("panel", DangoTheme.solid_chip_style(accent, 11, 3, Vector2(13, 8)))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	chip.add_child(row)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(20, 20)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# BUG FIX (caught in this task's own screenshot QA): TextureRect's default expand_mode
	# (EXPAND_KEEP_SIZE) makes its MINIMUM size equal the texture's native size — 320x320 for
	# these card illustrations (see CardArt.gd's header) — regardless of custom_minimum_size,
	# because Godot takes the larger of the two. Inside a single-child container (PanelContainer)
	# that gets force-fit and is invisible; inside a multi-child HBoxContainer (this chip's own
	# row) it is not, and the relic chip rendered at ~320px, blowing out the whole card row.
	# EXPAND_IGNORE_SIZE makes the texture's native size NOT contribute to minimum size, so the
	# 20x20 custom_minimum_size above is the one that actually applies.
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var icon_path := "res://assets/cards/relic_r%d.png" % clampi(rarity, 0, 4)
	if ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path)
	row.add_child(icon)

	var name_lbl := DangoTheme.display_label(display_name.to_upper(), 14, DangoTheme.ink_on(accent))
	row.add_child(name_lbl)

	return chip


# ===========================================================================
# Ranked strip — FLAGGED addition, see file header. A real, already-tested feature
# (t_result_screen.gd) the v2 mockup has no equivalent for; kept as a slim, quiet strip
# between the card row and the CTAs rather than dropped.
# ===========================================================================
func _build_ranked_strip(s: Dictionary) -> void:
	var host := PanelContainer.new()
	host.name = "RankedStrip"
	host.set_anchors_preset(Control.PRESET_TOP_WIDE)
	host.offset_top = 862.0   # FLAGGED: between the card row (~842 bottom) and CTAs (top ~956)
	host.offset_left = 80.0
	host.offset_right = -80.0
	host.add_theme_stylebox_override("panel",
		DangoTheme.surface_style(DangoTheme.Surface.PANEL_ON_ART, 12, 2, 0.0, Vector2(18, 8)))
	add_child(host)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	host.add_child(row)

	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", DangoTheme.TEXT_DIM)

	if not bool(s.get("ranked", false)):
		label.text = "This run was not Ranked, so it has no verifiable score."
		row.add_child(label)
		return

	var log: ActionLog = s.get("action_log")
	if log == null or not log.is_complete():
		label.text = "This run's record is incomplete, so its score cannot be verified."
		row.add_child(label)
		return

	label.text = "Ranked · no leaderboard is live yet — you can save this run's verifiable record."
	row.add_child(label)

	var btn := Button.new()
	btn.text = "SAVE RUN RECORD"
	btn.custom_minimum_size = Vector2(0, 36)
	DangoTheme.style_button(btn, false)
	btn.pressed.connect(func() -> void:
		var path := _save_run_record(log)
		label.text = ("Saved to %s" % path) if path != "" else "Could not write the run record."
		btn.disabled = true)
	row.add_child(btn)


func _save_run_record(log: ActionLog) -> String:
	var stamp := Time.get_datetime_string_from_system().replace(":", "-")
	var path := "user://run_record_%s.json" % stamp
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return ""
	f.store_string(JSON.stringify(log.to_data()))
	f.close()
	return ProjectSettings.globalize_path(path)


# ===========================================================================
# CTA row — 340/250 x 72 at bottom 52 (pinned). Both navigate to Main Menu: a true "instant
# replay with the same seed/team" is a MainMenu.tscn feature (out of this task's owned files
# — see report) so RUN IT AGAIN is, today, a more prominent way to do the same thing MAIN MENU
# does. FLAGGED, not silently assumed equivalent.
# ===========================================================================
func _build_cta_row() -> void:
	var host := Control.new()
	host.name = "CtaRow"
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	host.offset_top = -124.0
	host.offset_bottom = -52.0
	add_child(host)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.add_child(row)

	var again := Button.new()
	again.text = "RUN IT AGAIN"
	again.custom_minimum_size = Vector2(340, 72)
	again.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	again.add_theme_font_size_override("font_size", 25)
	DangoTheme.style_button(again, true)
	again.pressed.connect(_on_menu_pressed)
	row.add_child(again)

	var menu := Button.new()
	menu.text = "MAIN MENU"
	menu.custom_minimum_size = Vector2(250, 72)
	menu.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	menu.add_theme_font_size_override("font_size", 20)
	DangoTheme.style_button(menu, false, false, DangoTheme.TEXT_DIM)
	menu.pressed.connect(_on_menu_pressed)
	row.add_child(menu)


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")
