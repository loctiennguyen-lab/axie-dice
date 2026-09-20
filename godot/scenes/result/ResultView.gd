extends Control
## Result.tscn root - the RESULT screen of `docs/design-handoff-v2/mockups-v2/run-flow-v2.html`.
##
## Every number here is read out of that mockup's own markup: the victory pill and RUN COMPLETE
## at `top:50px` (Baloo 92 with a `0 5px 0` text shelf), the five-column party row at
## `top:262px` (152px portrait tile over a 168-wide plate pulled up 8px), the six-cell stat
## ribbon at `top:558px` (height 106, `left/right:80px`), the three panels at `top:692px`
## (560-wide cream shard card, a flexible Lunacia Pass card, a 392-wide relics card, `gap:18px`)
## and the two buttons at `bottom:52px` (340x72 and 250x72, `gap:16px`).
##
## THE HORIZONTAL COORDINATES ARE ABSOLUTE ON PURPOSE; THE VERTICAL ONES ARE A BASELINE.
##
## `project.godot` runs `window/stretch/aspect="expand"` (restored 2026-09-20 evening), so the
## canvas keeps its 1920 width - every x below is exactly where the mockup put it - but GROWS
## VERTICALLY. 1080 is the minimum height, not the height. Every band here is therefore
## TOP-anchored with `grow_vertical = GROW_DIRECTION_END`, so the slack lands at the bottom of
## the screen as honest empty artwork (FIX-PASS-03 §1) rather than opening a hole mid-screen,
## and the two CTAs at the foot are BOTTOM-anchored so they ride the real edge.
##
## The three stacked tops (_PARTY_TOP / _RIBBON_TOP / _CARDS_TOP) are the mockup's numbers and
## are what you get at 1080. They are a FLOOR, not a fixed position: RES-03 and RES-04 state
## those two gaps as relationships ("28px below the party row", "28px below the ribbon"), so
## _relayout_bands() measures the band above and pushes the next one down if it grew past its
## baseline. See _BAND_GAP.
##
## An earlier pass subtracted DangoScreen.SAFE from each of these and re-derived the rest,
## because the shell's content column is inset by 48/84 and re-centres itself on resize. That
## indirection is gone: the shell is used for its plate/scrim stack and the layout host is the
## full canvas.
##
## Reads the RunState snapshot BEFORE end_run() is called (architecture plan 3.2.4).
##
## RANKED / SAVE RUN RECORD is a real, already-shipped feature (t_result_screen.gd pins all
## three of its states) that the mockup's RESULT screen does not depict at all - it has no
## ranked-score concept. `# FLAGGED:` - kept as a caption line inside the GENE SHARD card
## rather than dropped, since dropping it would regress a shipped feature nothing else surfaces.
##
## PARTY HP: `# FLAGGED:` - this port resets HP/shield/status to full between combats
## (damage_pipeline.gd's own header note; RunState.roster carries no "current hp" field), so
## there is no persisted "final HP below max" for a survived run - every surviving roster
## member always reads as full HP here. The mockup's hpColor/hpPct fields imply a live bar;
## a true partial-HP concept would need a RunState schema change, out of scope for this task.

## PADDING CONVENTION. A StyleBoxFlat's `content_margin` is measured from the box's OUTER edge
## and REPLACES the border width - it is not added to it. CSS measures `padding` from INSIDE the
## border. So every padding copied out of the mockup is written here as `border + padding`:
## `padding:18px 22px` on a `4px` border is a content margin of 26 x 22, not 22 x 18.

## The mockup's plate for this screen: `assets/bg/entrance.jpg`.
const BG_MOCKUP_PATH := "assets/bg/entrance.jpg"

## Band geometry, straight off the mockup.
const _TITLE_TOP := 50.0
const _PARTY_TOP := 262.0
const _PARTY_GAP := 28
const _RIBBON_TOP := 558.0
const _RIBBON_H := 106.0
const _CARDS_TOP := 692.0
## RES-03 / RES-04 state these two positions as RELATIONSHIPS - the ribbon "28px below the
## party row", the card row "28px below the ribbon" - while the mockup states them as the two
## absolute tops above. Both are honoured: the mockup top is the baseline, and _relayout_bands()
## pushes a band down only if the one above it grew past it. A party column is not a fixed
## height (a long name wraps, a plate can carry an extra row), and when it grew the plate used
## to run into the ribbon.
const _BAND_GAP := 28.0
const _SIDE := 80.0
const _FOOTER_BOTTOM := 52.0
const _FOOTER_H := 72.0
## Each stat cell's own `padding-left`, and the height of the 2px rule on its left edge. The
## rule is the CELL's border in the mockup, so it is as tall as the cell's content (a 38px
## value on a 1.0 line, 7px of margin, an 11px caption), not as tall as the 106px ribbon.
const _STAT_PAD_LEFT := 26.0
const _STAT_RULE_H := 58.0

var _screen: Control          ## the full-canvas layout host - see the header note
var _shell_content: Control   ## DangoScreen's own inset column; unused by this screen

## The three stacked bands, kept so _relayout_bands() can measure one against the next.
var _party_band: Control = null
var _ribbon_host: PanelContainer = null
var _cards_host: Control = null

func _ready() -> void:
	# The shell is used for its plate -> scrim stack only. No footer bar: the mockup's RESULT
	# screen has two free-standing buttons at `bottom:52px`, not a footer band, and they live
	# in a Control named `Footer` so UI law L4 still has something to find.
	#
	# G2, 20 Sep 2026: build() now takes the screen's OWN insets after `combat`. This screen's
	# mockup is `left:80px; right:80px` on the stat ribbon, the card row and the title block, so
	# 80 is what the shell is told rather than the shared RAIL_X default of 84 that had been
	# overriding it. The mockup states no single top/bottom inset for this screen - the title
	# band sits at top:50 and the CTA row at bottom:52, each anchored on its own - so those two
	# are left at the shell's defaults rather than invented here.
	var built := DangoScreen.build(self, MockupAssets.tex(BG_MOCKUP_PATH),
		DangoTheme.Scrim.RESULT, false, false, _SIDE)
	_shell_content = built["content"]
	# Renamed so the full-canvas host below can carry the name `Content`, which is what the
	# screen's content region actually is. DangoScreen owns the node it returns, so it is
	# renamed rather than removed.
	_shell_content.name = "ShellContent"
	_shell_content.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_screen = Control.new()
	_screen.name = "Content"
	_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_screen)

	var won := RunState.phase == RunState.RunPhase.WON

	# Snapshot every field this screen needs OUT of RunState/RunStatsAccumulator before
	# end_run() runs (architecture plan 3.2.4).
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
		# Taken BEFORE end_run() pushes this run's XP in, so the "+N LEVELS" pill can say how
		# many levels THIS run bought rather than what level the player happens to be.
		"pass_level_before": MetaState.bp_level(),
	}

	RunState.end_run(won)   # pushes shards + XP into MetaState
	snapshot["xp_gained"] = RunState.last_run_xp
	snapshot["pass_level"] = MetaState.bp_level()
	snapshot["daily_mission_granted"] = RunState.daily_mission_granted

	_build_ui(snapshot)


func _build_ui(s: Dictionary) -> void:
	_build_title_band(s)
	_build_party_row(s["roster"] as Array)
	_build_stat_ribbon(s["stats"] as Dictionary)
	_build_card_row(s)
	_build_cta_row()
	# Deferred: the party columns have no size until the first layout pass, so measuring here
	# would read zero and leave the ribbon at its mockup baseline whether or not that is clear.
	_relayout_bands.call_deferred()


## RES-03 / RES-04. See _BAND_GAP. Idempotent, and cheap enough to run on every party resize.
func _relayout_bands() -> void:
	if _party_band == null or _ribbon_host == null or _cards_host == null:
		return
	var party_h: float = maxf(_party_band.size.y, _party_band.get_combined_minimum_size().y)
	var ribbon_top: float = maxf(_RIBBON_TOP, _PARTY_TOP + party_h + _BAND_GAP)
	_ribbon_host.offset_top = ribbon_top
	_ribbon_host.offset_bottom = ribbon_top + _RIBBON_H
	var cards_top: float = maxf(_CARDS_TOP, ribbon_top + _RIBBON_H + _BAND_GAP)
	_cards_host.offset_top = cards_top
	_cards_host.offset_bottom = cards_top


# ===========================================================================
# Title band - mockup `top:50px`, centred: a 36px outcome pill, RUN COMPLETE at Baloo 92 with
# `margin-top:12px`, and the seed line at 14 with `margin-top:8px`.
# ===========================================================================
func _build_title_band(s: Dictionary) -> void:
	var won := bool(s["won"])
	var accent := DangoTheme.SUCCESS if won else DangoTheme.DANGER

	var col := VBoxContainer.new()
	col.name = "TitleBand"
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 0)
	col.set_anchors_preset(Control.PRESET_TOP_WIDE)
	# The mockup spans this block `left:0;right:0` and centres inside it. A centred column has
	# the same centre line inset to the screen's 80px gutter, so it is inset - UI law L1 wants
	# nothing positioned outside the safe area, and nothing here moves by obeying it.
	col.grow_vertical = Control.GROW_DIRECTION_END
	col.offset_left = _SIDE
	col.offset_right = -_SIDE
	col.offset_top = _TITLE_TOP
	col.offset_bottom = _TITLE_TOP
	_screen.add_child(col)

	var chip := PanelContainer.new()
	chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	chip.custom_minimum_size.y = 36.0
	var chip_sb := DangoTheme.solid_chip_style(accent, 10, 4, Vector2(22, 4))
	chip_sb.shadow_color = DangoTheme.SHELF
	chip_sb.shadow_size = 0
	chip_sb.shadow_offset = Vector2(0, 5)
	chip.add_theme_stylebox_override("panel", chip_sb)
	col.add_child(chip)
	var chip_text := "%s - %s RUN - ASCENSION %d" % [
		"VICTORY" if won else "DEFEAT",
		"FULL" if String(s["mode"]) == "full" else "SHORT",
		int(s["ascension"]),
	]
	var chip_lbl := DangoTheme.display_label(chip_text, 14, DangoTheme.ink_on(accent), 800, 0.2)
	chip_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chip.add_child(chip_lbl)

	col.add_child(_spacer(12.0))
	var title := DangoTheme.display_label("RUN COMPLETE" if won else "RUN OVER", 92,
		DangoTheme.CREAM_RAISED, 800, 0.01)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Mockup: `text-shadow: 0 5px 0 rgba(0,0,0,.55)` - the same hard shelf every surface on this
	# screen uses, on type. `shadow_outline_size 0` is what keeps it a solid offset copy rather
	# than the blur this design system exists to get rid of.
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	title.add_theme_constant_override("shadow_offset_x", 0)
	title.add_theme_constant_override("shadow_offset_y", 5)
	title.add_theme_constant_override("shadow_outline_size", 0)
	# Baloo 2 reports a ~147px font box at `font_size = 92`, against the 92px line the mockup
	# draws. Unboxed, the title band grew by ~55px and pushed the seed line straight down into
	# the party row, where it rendered behind the portraits.
	col.add_child(DangoTheme.line_box(title, 92, 1.0))

	col.add_child(_spacer(8.0))
	var subtitle := Label.new()
	subtitle.text = "Seed %d - replayable from the main menu" % int(s["seed"])
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_override("font",
		DangoTheme.tracked_font(DangoTheme.FONT_UI, 0.02, 14))
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", DangoTheme.TEXT)
	_screen_shadow(subtitle)
	col.add_child(subtitle)


## The mockup gives the two lines that sit directly on the painted plate a soft drop shadow
## (`text-shadow:0 1px 3px rgba(0,0,0,.9)`). Godot's font shadow is hard-edged, so this is the
## nearest honest equivalent: a 1px offset at the mockup's own alpha.
func _screen_shadow(lbl: Label) -> void:
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	lbl.add_theme_constant_override("shadow_offset_x", 0)
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	lbl.add_theme_constant_override("shadow_outline_size", 0)


func _spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


# ===========================================================================
# Party row - mockup `top:262px`, centred, `gap:28px`, `align-items:flex-end`.
# ===========================================================================
func _build_party_row(roster: Array) -> void:
	var band := Control.new()
	band.name = "PartyRow"
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.set_anchors_preset(Control.PRESET_TOP_WIDE)
	band.grow_vertical = Control.GROW_DIRECTION_END
	band.offset_left = _SIDE      # see _build_title_band() on why a centred row is inset
	band.offset_right = -_SIDE
	band.offset_top = _PARTY_TOP
	band.offset_bottom = _PARTY_TOP
	_screen.add_child(band)
	_party_band = band
	band.resized.connect(_relayout_bands)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", _PARTY_GAP)
	row.set_anchors_preset(Control.PRESET_TOP_WIDE)
	band.add_child(row)

	for entry in roster:
		row.add_child(_build_party_column(entry as Dictionary))


## One column - mockup: `width:186px`; a 152px portrait tile (radius 26, class fill, 5px black,
## shelf `0 8px 0`) over a 168-wide plate pulled up 8px with `padding:16px 12px 11px`.
##
## The plate's 16px TOP padding is what absorbs that 8px overlap, so the name's cap height
## still clears the portrait's bottom edge - the portrait and the type never overlap by more
## than the 8px the plate pays back. The portrait also has to DRAW above the plate for the
## overlap to read as "the plate tucks under the portrait": a VBoxContainer draws by child
## index, so the portrait keeps index 0 for layout and wins the draw with z_index.
func _build_party_column(e: Dictionary) -> Control:
	var hero_key := String(e.get("hero_key", ""))
	var hero_def: Dictionary = ContentDB.heroes.get(hero_key, {})
	var cls := String(hero_def.get("cls", ""))
	var accent := DangoTheme.class_color(cls)
	var effective_hp := int(e.get("max_hp", 0)) + int(e.get("bonus_hp", 0))

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", -8)
	col.custom_minimum_size.x = 186.0
	col.size_flags_vertical = Control.SIZE_SHRINK_END   # mockup: `align-items:flex-end`

	var portrait := PanelContainer.new()
	portrait.custom_minimum_size = Vector2(152, 152)
	portrait.z_index = 1
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	# Without this the art (sized to the FULL rect with no inset) paints over the stylebox's
	# own border ring, which is what "the 5px black outline is missing" actually was.
	portrait.clip_contents = true
	var portrait_sb := StyleBoxFlat.new()
	portrait_sb.bg_color = accent
	portrait_sb.border_color = Color.BLACK
	portrait_sb.set_border_width_all(5)
	portrait_sb.set_corner_radius_all(26)
	# Inset exactly the border width so the art starts INSIDE the ring instead of on top of it.
	portrait_sb.content_margin_left = 5.0
	portrait_sb.content_margin_right = 5.0
	portrait_sb.content_margin_top = 5.0
	portrait_sb.content_margin_bottom = 5.0
	portrait_sb.shadow_color = DangoTheme.SHELF_DEEP
	portrait_sb.shadow_size = 0
	portrait_sb.shadow_offset = Vector2(0, 8)
	portrait.add_theme_stylebox_override("panel", portrait_sb)
	col.add_child(portrait)

	var art := TextureRect.new()
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	# EXPAND_IGNORE_SIZE: without it a TextureRect reports the SOURCE texture's pixel size as
	# its own minimum size, and no layout will shrink a Control below that.
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.texture = MockupAssets.tex("assets/portrait/%s.png" % cls)
	portrait.add_child(art)

	var plate := PanelContainer.new()
	plate.custom_minimum_size = Vector2(168, 0)
	plate.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var plate_sb := StyleBoxFlat.new()
	plate_sb.bg_color = DangoTheme.PANEL_OVER_CLASS   # mockup: `rgba(11,13,18,.9)`
	plate_sb.border_color = Color.BLACK
	plate_sb.set_border_width_all(3)
	plate_sb.set_corner_radius_all(15)
	plate_sb.shadow_color = DangoTheme.SHELF
	plate_sb.shadow_size = 0
	plate_sb.shadow_offset = Vector2(0, 5)
	plate_sb.content_margin_left = 15.0
	plate_sb.content_margin_right = 15.0
	plate_sb.content_margin_top = 19.0
	plate_sb.content_margin_bottom = 14.0
	plate.add_theme_stylebox_override("panel", plate_sb)
	col.add_child(plate)

	var plate_col := VBoxContainer.new()
	plate_col.alignment = BoxContainer.ALIGNMENT_CENTER
	plate_col.add_theme_constant_override("separation", 0)
	plate.add_child(plate_col)

	var name_lbl := DangoTheme.display_label(
		String(hero_def.get("n", hero_key)), 22, DangoTheme.CREAM_RAISED, 800, 0.02)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plate_col.add_child(name_lbl)

	plate_col.add_child(_spacer(7.0))
	var tier_row := HBoxContainer.new()
	tier_row.alignment = BoxContainer.ALIGNMENT_CENTER
	tier_row.add_theme_constant_override("separation", 9)
	plate_col.add_child(tier_row)

	var tier_lbl := DangoTheme.display_label(
		"T%d" % int(e.get("tier", 1)), 12, DangoTheme.CHIP_INK_ON_WELL, 800, 0.12)
	tier_row.add_child(tier_lbl)

	# Always full HP - see the file header's FLAGGED note on why this port has no persisted
	# "current HP below max" for a roster entry between fights.
	var hp_lbl := DangoTheme.display_label(
		"%d/%d" % [effective_hp, effective_hp], 16, DangoTheme.hp_color(1.0))
	tier_row.add_child(hp_lbl)

	plate_col.add_child(_spacer(8.0))
	var bar_bg := Panel.new()
	bar_bg.custom_minimum_size = Vector2(138, 9)
	bar_bg.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bar_bg.clip_contents = true
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
# Stat ribbon - mockup `top:558px; left:80px; right:80px; height:106px`: ONE PANEL_DEEP panel
# (radius 18, 4px black, shelf `0 7px 0`) holding six flex cells, each with `padding-left:26px`
# and, from the second on, a 2px `rgba(255,147,69,.22)` rule on its left edge.
# ===========================================================================
func _build_stat_ribbon(stats: Dictionary) -> void:
	var host := PanelContainer.new()
	host.name = "StatRibbon"
	host.set_anchors_preset(Control.PRESET_TOP_WIDE)
	host.offset_left = _SIDE
	host.offset_right = -_SIDE
	host.offset_top = _RIBBON_TOP
	host.offset_bottom = _RIBBON_TOP + _RIBBON_H
	host.custom_minimum_size = Vector2(0, _RIBBON_H)
	host.add_theme_stylebox_override("panel",
		DangoTheme.surface_style(DangoTheme.Surface.PANEL_DEEP, 18, 4, 7.0, Vector2(-1, -1)))
	_screen.add_child(host)
	_ribbon_host = host

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	host.add_child(row)

	# FLAGGED: the mockup's first cell reads "WAVES CLEARED". This port resolves one reward
	# offer per NODE and has no wave concept anywhere in its data (ContentDB.gd says so in as
	# many words), so the cell names what RunStatsAccumulator actually counts.
	var cleared := int(stats.get("nodes_cleared", 0))
	var total := int(stats.get("nodes_total", 0))
	# Per-tile accent, taken verbatim from the mockup's `stats` array: cleared/turns/kills are
	# cream-white, DAMAGE DEALT is DANGER red, BIGGEST HIT is PRIMARY orange, AXIES LOST is
	# SUCCESS green. Fixed per tile, not value-conditional - the mockup shows one static
	# palette, not a threshold scheme, so a zero here is still green.
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
			divider.custom_minimum_size = Vector2(2, _STAT_RULE_H)
			divider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(divider)
		var pad := Control.new()
		pad.custom_minimum_size = Vector2(_STAT_PAD_LEFT, 0)
		row.add_child(pad)
		row.add_child(_build_stat_tile(String(tiles[i][0]), String(tiles[i][1]), tiles[i][2]))


## One cell - value at Baloo 38, caption at Baloo 11 with `margin-top:7px`. FLAGGED (conflict):
## UI law L8 in DangoTheme.gd/t_ui_laws.gd sets a 12px type floor, and the mockup sets 11 here.
## godot/CLAUDE.md rule 5 is explicit that a mockup number wins over that floor ("including
## where that is 9px or 11px"), so 11 is what is built and the conflict is reported.
func _build_stat_tile(caption: String, value: String, color: Color) -> Control:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.add_theme_constant_override("separation", 7)

	var value_lbl := DangoTheme.display_label(value, 38, color)
	value_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	col.add_child(value_lbl)

	var caption_lbl := DangoTheme.display_label(caption, 11, DangoTheme.CAPTION_MUTED, 800, 0.16)
	col.add_child(caption_lbl)

	return col


# ===========================================================================
# Card row - mockup `top:692px; left:80px; right:80px`, `gap:18px`, `align-items:stretch`:
# a 560-wide cream Gene Shard card (the only cream surface on the screen), a flexible Lunacia
# Pass card, and a 392-wide relics card, left to right in that order.
# ===========================================================================
func _build_card_row(s: Dictionary) -> void:
	var host := Control.new()
	host.name = "CardRow"
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.set_anchors_preset(Control.PRESET_TOP_WIDE)
	host.grow_vertical = Control.GROW_DIRECTION_END
	host.offset_left = _SIDE
	host.offset_right = -_SIDE
	host.offset_top = _CARDS_TOP
	host.offset_bottom = _CARDS_TOP
	_screen.add_child(host)
	_cards_host = host

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	row.set_anchors_preset(Control.PRESET_TOP_WIDE)
	host.add_child(row)

	row.add_child(_build_shard_card(s))
	row.add_child(_build_pass_card(s))
	row.add_child(_build_relics_card(s["relic_ids"] as Array))


## GENE SHARD EARNED - mockup: 560 wide, `padding:18px 22px`, radius 18, 4px black, shelf
## `0 7px 0`, on CREAM; the caption at 12, then a 44px glyph beside the total at Baloo 58 with
## the payout breakdown right-aligned opposite it.
func _build_shard_card(s: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(560, 0)
	var shard_card_sb := DangoTheme.cream_card_style(Color.TRANSPARENT, 18, 4, 7.0)
	shard_card_sb.content_margin_left = 26.0
	shard_card_sb.content_margin_right = 26.0
	shard_card_sb.content_margin_top = 22.0
	shard_card_sb.content_margin_bottom = 22.0
	card.add_theme_stylebox_override("panel", shard_card_sb)
	DangoTheme.clip_to_frame(card)   # G3

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	card.add_child(col)

	# FLAGGED (token): the mockup inks this caption #8A7450, a mid-brown on cream DangoTheme has
	# no name for. INK_ON_CREAM_MUTED (#6B5433) is the named caption ink for this surface.
	var caption := DangoTheme.display_label("GENE SHARD EARNED", 12,
		DangoTheme.INK_ON_CREAM_MUTED, 800, 0.2)
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
	shard_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shard_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	shard_icon.texture = MockupAssets.tex("assets/fx/shard.png")
	amount_group.add_child(shard_icon)

	var amount := DangoTheme.display_label("+%d" % int(s["shards_this_run"]), 58, DangoTheme.INK)
	amount_group.add_child(amount)

	# A real vault total ("POOL NOW 29055") is wider than the mockup's placeholder, and with no
	# width budget of its own this column's natural width could exceed what is left of the fixed
	# 560px card and spill past the panel's edge. Both wide labels share the row and clip to an
	# ellipsis instead, so this holds regardless of how large the pool or payout ever get.
	var right := VBoxContainer.new()
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 3)
	row.add_child(right)

	# FLAGGED (token): the mockup sets the daily-bonus fragment of this line in #2E7D2B, a green
	# on cream DangoTheme has no name for, while the rest of the line is #6B5433. A Label carries
	# one colour, so the whole line reads INK_ON_CREAM_MUTED rather than inlining a second hex
	# or splitting it into a RichTextLabel the design does not ask for.
	var breakdown := Label.new()
	var daily_bonus := ContentDB.DAILY_MISSION_SHARD if bool(s.get("daily_mission_granted", false)) else 0
	breakdown.text = "%d run payout%s" % [
		int(s["shards_this_run"]) - daily_bonus,
		"  -  %d daily" % daily_bonus if daily_bonus > 0 else "",
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

	col.add_child(_build_ranked_caption(s))

	return card


## The RANKED / SAVE RUN RECORD line - see the file header note (a real, already-shipped
## feature the mockup has no equivalent for), folded into the GENE SHARD card as a caption row.
func _build_ranked_caption(s: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", DangoTheme.TYPE_CAPTION)
	label.add_theme_color_override("font_color", DangoTheme.INK_ON_CREAM_MUTED)

	if not bool(s.get("ranked", false)):
		label.text = "This run was not Ranked, so it has no verifiable score."
		row.add_child(label)
		return row

	var log: ActionLog = s.get("action_log")
	if log == null or not log.is_complete():
		label.text = "This run's record is incomplete, so its score cannot be verified."
		row.add_child(label)
		return row

	label.text = "Ranked - no leaderboard is live yet - you can save this run's verifiable record."
	row.add_child(label)

	var btn := Button.new()
	btn.text = "SAVE RUN RECORD"
	btn.custom_minimum_size = Vector2(0, 30)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	DangoTheme.style_button(btn, false)
	btn.add_theme_font_size_override("font_size", DangoTheme.TYPE_MIN)
	btn.pressed.connect(func() -> void:
		var path := _save_run_record(log)
		label.text = ("Saved to %s" % path) if path != "" else "Could not write the run record."
		btn.disabled = true)
	row.add_child(btn)
	return row


## LUNACIA PASS - mockup: the flexible middle card, `padding:18px 22px`, radius 18 on
## PANEL_DEEP; the caption at 12 opposite a SUCCESS "+N LEVELS" pill, then "LV n" at Baloo 44
## beside the XP line, over a 15px progress bar (radius 9, 3px black, PRIMARY fill).
func _build_pass_card(s: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel",
		DangoTheme.surface_style(DangoTheme.Surface.PANEL_DEEP, 18, 4, 7.0, Vector2(26, 22)))

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	card.add_child(col)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	col.add_child(head)
	var caption := DangoTheme.display_label("LUNACIA PASS", 12, DangoTheme.CAPTION_MUTED, 800, 0.2)
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(caption)

	var gained: int = maxi(int(s.get("pass_level", 0)) - int(s.get("pass_level_before", 0)), 0)
	if gained > 0:
		var pill := PanelContainer.new()
		pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pill.custom_minimum_size.y = 24.0
		pill.add_theme_stylebox_override("panel",
			DangoTheme.solid_chip_style(DangoTheme.SUCCESS, 7, 2, Vector2(11, 2)))
		var pill_lbl := DangoTheme.display_label(
			"+%d LEVEL%s" % [gained, "S" if gained > 1 else ""], 12, DangoTheme.INK_ON_SUCCESS,
			800, 0.08)
		pill_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		pill.add_child(pill_lbl)
		head.add_child(pill)

	col.add_child(_spacer(11.0))
	var prog: Dictionary = MetaState.bp_progress()
	var level := int(prog["level"])
	var into := int(prog["into_level"])
	var needed := int(prog["needed"])

	var level_row := HBoxContainer.new()
	level_row.add_theme_constant_override("separation", 12)
	col.add_child(level_row)
	level_row.add_child(DangoTheme.display_label("LV %d" % level, 44, DangoTheme.CREAM_RAISED))

	var xp_lbl := Label.new()
	xp_lbl.text = _pass_xp_line(level, into, needed, int(s.get("xp_gained", 0)))
	xp_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	xp_lbl.clip_text = true
	xp_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	xp_lbl.add_theme_font_size_override("font_size", 13)
	xp_lbl.add_theme_color_override("font_color", DangoTheme.MUTED_TEXT)
	level_row.add_child(xp_lbl)

	col.add_child(_spacer(12.0))
	# A Panel, NOT a PanelContainer: a Container force-fits every child to its own content rect
	# on each layout pass, which would stretch the partial fill below back to full width.
	var track := Panel.new()
	track.custom_minimum_size = Vector2(0, 15)
	track.clip_contents = true
	var track_sb := StyleBoxFlat.new()
	track_sb.bg_color = DangoTheme.WELL_DEEP
	track_sb.border_color = Color.BLACK
	track_sb.set_border_width_all(3)
	track_sb.set_corner_radius_all(9)
	track.add_theme_stylebox_override("panel", track_sb)
	col.add_child(track)
	var fill := ColorRect.new()
	fill.color = DangoTheme.PRIMARY
	fill.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	fill.anchor_right = clampf(float(prog.get("percent", 0.0)) / 100.0, 0.0, 1.0)
	fill.offset_right = 0.0
	track.add_child(fill)

	return card


## "380 / 500 XP - Lv 8 pays 80 shard", the mockup's own line, from this build's own BP track.
## The tail only claims a shard payout when the next milestone actually IS one; every other
## milestone type says what the run earned instead of describing a reward it cannot name in
## four words.
func _pass_xp_line(level: int, into: int, needed: int, xp_gained: int) -> String:
	if needed <= 0:
		return "MAX LEVEL  -  +%d XP this run" % xp_gained
	var head := "%d / %d XP" % [into, needed]
	for entry in ContentDB.BP_TRACK:
		var e: Dictionary = entry
		if int(e.get("lv", 0)) == level + 1 and String(e.get("type", "")) == "shard":
			return "%s  -  Lv %d pays %d shard" % [head, level + 1, int(e.get("value", 0))]
	return "%s  -  +%d XP this run" % [head, xp_gained]


## RELICS CARRIED - mockup: 392 wide, `padding:18px 20px`, radius 18 on PANEL_DEEP; the caption
## at 12, then the relic chips wrapping at `gap:9px`.
func _build_relics_card(relic_ids: Array) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(392, 0)
	card.add_theme_stylebox_override("panel",
		DangoTheme.surface_style(DangoTheme.Surface.PANEL_DEEP, 18, 4, 7.0, Vector2(24, 22)))

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	card.add_child(col)

	var caption := DangoTheme.display_label("RELICS CARRIED - %d" % relic_ids.size(), 12,
		DangoTheme.CAPTION_MUTED, 800, 0.2)
	col.add_child(caption)

	if relic_ids.is_empty():
		var none_lbl := Label.new()
		none_lbl.text = "None this run."
		none_lbl.add_theme_font_size_override("font_size", 13)
		none_lbl.add_theme_color_override("font_color", DangoTheme.MUTED_TEXT)
		col.add_child(none_lbl)
		return card

	# The mockup wraps these chips (`display:flex; flex-wrap:wrap; gap:9px`), so they wrap here.
	# A 2-column GridContainer was tried instead, to keep an odd count from leaving a short last
	# row; that is not what the mockup draws, and it forces every chip to one column width
	# regardless of how short its name is.
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 9)
	flow.add_theme_constant_override("v_separation", 9)
	col.add_child(flow)
	for relic_id in relic_ids:
		flow.add_child(_build_relic_chip(String(relic_id)))

	return card


## One relic chip - mockup: height 40, `padding:0 13px 0 7px`, radius 11, 3px black, filled with
## the relic's rarity colour, holding a 20px glyph and the name at Baloo 14 in ink.
func _build_relic_chip(relic_id: String) -> PanelContainer:
	var def = RelicRegistry.get_def(relic_id)
	var display_name := String(def.name) if def != null else relic_id
	var rarity := int(def.rarity) if def != null else 0
	var accent := DangoTheme.rarity_color(rarity)

	var chip := PanelContainer.new()
	chip.custom_minimum_size.y = 40.0
	var chip_sb := DangoTheme.solid_chip_style(accent, 11, 3, Vector2(0, 3))
	chip_sb.content_margin_left = 10.0
	chip_sb.content_margin_right = 16.0
	chip.add_theme_stylebox_override("panel", chip_sb)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	chip.add_child(row)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(20, 20)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# EXPAND_IGNORE_SIZE: these card illustrations are 320x320, and a TextureRect's minimum size
	# is the texture's own size unless this is set - which blew the whole card row out once.
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.texture = CardArt.texture_for_reward("relic", rarity)
	row.add_child(icon)

	var name_lbl := DangoTheme.display_label(display_name.to_upper(), 14,
		DangoTheme.ink_on(accent), 800, 0.04)
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(name_lbl)

	return chip


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
# The two bottom buttons - mockup `bottom:52px`, centred, `gap:16px`: RUN IT AGAIN at 340x72
# on PRIMARY (radius 16, 5px black, shelf `0 7px 0`, Baloo 25) and MAIN MENU at 250x72 on
# `rgba(27,31,39,.92)` (PANEL_ON_ART) in #8C95A4 (MUTED_TEXT) at Baloo 20.
#
# The host is named `Footer` because that is what it is for this screen, and UI law L4 - "the
# exit never floats loose on the art" - looks for that name. The mockup draws no footer BAND
# here, so there is none.
#
# FLAGGED: "RUN IT AGAIN" cannot yet be a true instant replay - nothing in this build restarts
# a run from a seed without going through the menu - so both buttons navigate to Main Menu,
# unchanged from before this pass.
# ===========================================================================
func _build_cta_row() -> void:
	var host := Control.new()
	host.name = "Footer"
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	host.offset_left = _SIDE      # see _build_title_band() on why a centred row is inset
	host.offset_right = -_SIDE
	host.offset_top = -(_FOOTER_BOTTOM + _FOOTER_H)
	host.offset_bottom = -_FOOTER_BOTTOM
	_screen.add_child(host)

	var row := HBoxContainer.new()
	row.name = "FooterRow"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.add_child(row)

	var again := _cta_button("RUN IT AGAIN", 340.0, 25, DangoTheme.PRIMARY,
		DangoTheme.INK_ON_PRIMARY, 0.14)
	again.pressed.connect(_on_menu_pressed)
	row.add_child(again)

	var menu := _cta_button("MAIN MENU", 250.0, 20, DangoTheme.PANEL_ON_ART,
		DangoTheme.MUTED_TEXT, 0.14)
	menu.name = "BackButton"
	menu.pressed.connect(_on_menu_pressed)
	row.add_child(menu)


func _cta_button(text: String, width: float, font_px: int, fill: Color, ink: Color,
		tracking_em: float = 0.0) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(width, _FOOTER_H)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	btn.add_theme_font_size_override("font_size", font_px)
	# The mockup's own `letter-spacing` on this button's label, verbatim in em.
	DangoTheme.apply_tracking(btn, tracking_em, font_px)
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = Color.BLACK
	sb.set_border_width_all(5)
	sb.set_corner_radius_all(16)
	sb.shadow_color = DangoTheme.SHELF_DEEP
	sb.shadow_size = 0
	sb.shadow_offset = Vector2(0, 7)
	for state_key in ["normal", "pressed", "disabled", "focus"]:
		btn.add_theme_stylebox_override(state_key, sb)
	# FLAGGED (token): the mockup lightens RUN IT AGAIN to #FFA85F on hover, a tint of Kam that
	# DangoTheme has no name for. Rather than inline a second orange here, the PRIMARY button
	# keeps its fill on hover and only the dark button changes (to its mockup hover ink,
	# #F3E7D3 = CREAM). The missing token is reported.
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_color_override("font_color", ink)
	btn.add_theme_color_override("font_hover_color",
		ink if fill.is_equal_approx(DangoTheme.PRIMARY) else DangoTheme.CREAM)
	btn.add_theme_color_override("font_pressed_color", ink)
	return btn


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")
