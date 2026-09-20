extends Control
## UNLOCKS — the ten-item, spend-once-keep-forever shard ladder. Restyle target:
## docs/design-handoff-v2 §UNLOCKS, screenshot `screenshots/11-unlocks.png`.
##
## THIS SCREEN CLOSES A REAL REGRESSION, NOT A COSMETIC GAP. v1 rendered this list inline on the
## scrolling Main Menu; v2 deleted that when the menu became a fixed title screen, and until this
## scene existed the UNLOCKS nav tile was wired disabled (see MainMenu.gd's now-resolved "GAP
## FLAGGED" note). Buying a shard-bought unlock was unreachable in the UI.
##
## All data and rules are real and pre-existing: `ContentDB.UNLOCKS` (10 entries, display order is
## ladder order), `ContentDB.UNLOCKS_WITHOUT_EFFECT` (the 4 sold-but-inert ids), and
## `MetaState.has_unlock()` / `buy_unlock()`. Nothing here invents a rule — it is presentation over
## state that already worked.

const MAIN_MENU_SCENE := "res://scenes/main_menu/MainMenu.tscn"

# The plate the mockup asks for. The whole painted set already ships under
# `assets/backgrounds/origins/scene/`, under the kit's own numbered names — the short names the
# handoff uses (`temple.jpg`, `deep-forest.jpg`, `rocky.jpg`) are the same art, renamed for the
# HTML mockups. Three screens briefly fell back to the wrong plate on the belief that these
# images were missing; they never were. Look in that directory before concluding a background
# does not exist, and do not copy the handoff's copies in — that is how a project ends up with
# two of every background and no rule about which one is canonical.
const BG_MOCKUP_PLATE := "assets/bg/deep-forest.jpg"

## Mockup path, resolved through MockupAssets — never a hand-written res:// string (rule 2).
const SHARD_ICON := "assets/fx/shard.png"

var _list: VBoxContainer
var _shard_label: Label
var _status_label: Label
var _list_scroll: ScrollContainer
var _list_fade: TextureRect

## FIX-PASS-02 §1 item 4: `content` already supplies the safe area and the 84px rail, so this
## screen's own left/right offsets against it drop the extra 84 they used to add on top of it.
var _content: Control

## Absolute margin (from the viewport edge) the mockup wants for the reading column: 360px, wider
## than the standard 84px rail. `content`'s left/right edges already sit 84px in, so the same
## visual margin from here is 360 - 84 = 276.
const LIST_INSET := 276.0
## FIXED 2026-09-20 (mockup pass): `content`'s top edge already IS the 48px safe line, so the
## mockup's `top:196` is 148 here. It was being added on top of the shell's inset (rendering at
## 244) — the same +48 drift the Pass and Vault screens carried.
const LIST_TOP := 196.0 - 48.0
## The mockup's header is the SAME 1200-wide centred column as the list, not the full content
## width — the shard chip's right edge lines up with the price buttons below it.
const HEADER_TOP := 54.0 - 48.0


func _ready() -> void:
	var shell := DangoScreen.build(self, MockupAssets.tex(BG_MOCKUP_PLATE),
		DangoTheme.Scrim.DEFAULT, true)
	_content = shell["content"]

	_build_header()
	_build_list_panel()
	_build_footer(shell["footer"])
	refresh()


func _build_header() -> void:
	var row := HBoxContainer.new()
	row.name = "HeaderRow"
	row.set_anchors_preset(Control.PRESET_TOP_WIDE)
	row.offset_left = LIST_INSET
	row.offset_right = -LIST_INSET
	row.offset_top = HEADER_TOP
	_content.add_child(row)

	var title_col := VBoxContainer.new()
	title_col.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	title_col.add_theme_constant_override("separation", 10)
	row.add_child(title_col)

	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(0, 34)
	chip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	chip.add_theme_stylebox_override("panel",
		DangoTheme.solid_chip_style(DangoTheme.PRIMARY, 9, 3, Vector2(14, 6)))
	var eyebrow_lbl := DangoTheme.display_label("SPEND ONCE · KEEP FOREVER", 14,
		DangoTheme.INK_ON_PRIMARY, 800, 0.16)
	eyebrow_lbl.add_theme_constant_override("line_spacing", 0)
	chip.add_child(eyebrow_lbl)
	title_col.add_child(chip)

	title_col.add_child(DangoTheme.display_label("UNLOCKS", 56, DangoTheme.CREAM_RAISED,
		800, 0.02))

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	var shard_chip := PanelContainer.new()
	shard_chip.name = "ShardChip"
	shard_chip.custom_minimum_size = Vector2(0, 56)
	shard_chip.size_flags_vertical = Control.SIZE_SHRINK_END
	var shard_sb := DangoTheme.surface_style(DangoTheme.Surface.CREAM, 13, 4, 5.0,
		Vector2(18, 0))
	shard_sb.content_margin_left = 12.0   # mockup: padding 0 18px 0 12px
	shard_chip.add_theme_stylebox_override("panel", shard_sb)
	row.add_child(shard_chip)

	var shard_row := HBoxContainer.new()
	shard_row.add_theme_constant_override("separation", 10)
	shard_chip.add_child(shard_row)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(30, 30)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = MockupAssets.tex(SHARD_ICON)
	shard_row.add_child(icon)

	_shard_label = DangoTheme.display_label("0", 34, DangoTheme.INK)
	_shard_label.name = "ShardLabel"
	_shard_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	shard_row.add_child(_shard_label)


## FIX-PASS-02 §1 item 4: the old `anchor_bottom = 1.0` + hand-computed
## `-(SAFE_AREA + FOOTER_HEIGHT)` offset is exactly the pattern the shell's `fit_or_scroll()`
## replaces — `content` already excludes the footer, so nothing here needs to know its height.
func _build_list_panel() -> void:
	_list = VBoxContainer.new()
	_list.name = "UnlockList"
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 10)

	_list_scroll = DangoScreen.fit_or_scroll(_list, _list_max_height())
	_list_scroll.name = "ListScroll"
	_list_scroll.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_list_scroll.offset_left = LIST_INSET
	_list_scroll.offset_right = -LIST_INSET
	_list_scroll.offset_top = LIST_TOP
	_content.add_child(_list_scroll)

	# L2: a scrollbar the player can see is only half of "there is more below" — the 24px fade is
	# the other half. Visibility is now computed in `_update_list_fade()` against the real
	# available height, rather than assumed unconditionally true.
	_list_fade = DangoTheme.scroll_fade(DangoTheme.PANEL)
	_list_fade.name = "ListScrollFade"
	_list_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_list_fade.visible = false
	_list_fade.anchor_left = 0.0
	_list_fade.anchor_right = 1.0
	_list_fade.anchor_top = 0.0
	_list_fade.anchor_bottom = 0.0
	_list_fade.offset_left = LIST_INSET
	_list_fade.offset_right = -LIST_INSET
	_content.add_child(_list_fade)

	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	_status_label.visible = false
	_status_label.add_theme_font_size_override("font_size", 13)
	_status_label.add_theme_color_override("font_color", DangoTheme.DANGER)
	_content.add_child(_status_label)


func _list_max_height() -> float:
	return get_viewport_rect().size.y - DangoScreen.SAFE * 2.0 - DangoScreen.FOOTER_H - LIST_TOP


func _update_list_fade() -> void:
	if _list == null or _list_scroll == null or _list_fade == null:
		return
	var natural := _list.get_combined_minimum_size().y
	var max_h := _list_max_height()
	var overflow := natural > max_h
	_list_fade.visible = overflow
	if overflow:
		var bottom := LIST_TOP + minf(natural, max_h)
		_list_fade.offset_top = bottom - DangoTheme.SCROLL_FADE_HEIGHT
		_list_fade.offset_bottom = bottom


## FIX-PASS-01 L4/U4: BACK lives in the shared footer bar, not floating on the art over the
## (now correctly scrolling) list. §1 item 4: the footer is `DangoScreen.build()`'s.
func _build_footer(footer: HBoxContainer) -> void:
	DangoScreen.add_back_button(footer, func() -> void:
		get_tree().change_scene_to_file(MAIN_MENU_SCENE))


func refresh() -> void:
	_shard_label.text = str(MetaState.shard_pool)
	for child in _list.get_children():
		child.queue_free()
		_list.remove_child(child)
	for def in ContentDB.UNLOCKS:
		_list.add_child(_build_row(def))
	# `queue_free()`'d rows are still in the tree (and counted by `get_combined_minimum_size()`)
	# until the end of this frame — same reasoning as PassView.refresh()'s own deferred call.
	call_deferred("_update_list_fade")


## State priority is OWNED > TOO EXPENSIVE > NO EFFECT YET > AVAILABLE.
##
## FLAGGED: the mockup's own demo rows never combine "inert" with "cannot afford" (its 4 inert
## rows are all affordable, its 3 too-expensive rows are all non-inert) so this ordering is
## inferred, not read off the mockup. It falls out of the mockup's OWNED-beats-INERT rule already
## visible in its own render logic (`tag: owned ? "OWNED" : inert ? "NO EFFECT YET" : ...`) —
## "can you even afford it" reads as a more fundamental gate than "is it worth buying", so
## TOO EXPENSIVE is checked first among the non-owned states.
func _build_row(def: Dictionary) -> PanelContainer:
	var id := String(def.get("id", ""))
	var cost := int(def.get("cost", 0))
	var owned := MetaState.has_unlock(id)
	var inert := ContentDB.UNLOCKS_WITHOUT_EFFECT.has(id)
	var afford := MetaState.shard_pool >= cost
	var too_expensive := not owned and not afford

	var row := PanelContainer.new()
	row.name = "UnlockRow_" + id
	row.custom_minimum_size = Vector2(0, 74)
	var row_bg: Color = DangoTheme.CREAM if owned else (DangoTheme.WELL if too_expensive else DangoTheme.PANEL)
	var sb := DangoTheme.surface_style(DangoTheme.Surface.PANEL, 13, 4, 4.0, Vector2(16, 0))
	sb.bg_color = row_bg
	row.add_theme_stylebox_override("panel", sb)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	row.add_child(hbox)
	# PanelContainer stretches its one child to fill; give the row real vertical centring for its
	# contents via a CenterContainer-like margin instead of stacking another wrapper.
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var step_badge := PanelContainer.new()
	step_badge.custom_minimum_size = Vector2(38, 38)
	step_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var step_sb := StyleBoxFlat.new()
	step_sb.bg_color = DangoTheme.SUCCESS if owned else DangoTheme.WELL
	step_sb.border_color = Color.BLACK
	step_sb.set_border_width_all(3)
	step_sb.set_corner_radius_all(10)
	step_badge.add_theme_stylebox_override("panel", step_sb)
	var step_num := ContentDB.UNLOCKS.find(def) + 1
	var step_lbl := DangoTheme.display_label(str(step_num), 17,
		DangoTheme.INK_ON_SUCCESS if owned else DangoTheme.FAINT_TEXT)
	step_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	step_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	step_badge.add_child(step_lbl)
	hbox.add_child(step_badge)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_theme_constant_override("separation", 3)
	hbox.add_child(info)

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 9)
	info.add_child(name_row)

	var name_lbl := DangoTheme.display_label(String(def.get("n", "")), 20,
		DangoTheme.INK if owned else DangoTheme.CREAM_RAISED, 800, 0.01)
	name_row.add_child(name_lbl)

	# RESTORED 2026-09-20 (mockup pass): FIX-PASS-01 U3 deleted the "AVAILABLE" chip as
	# redundant with the price button. meta-screens-v2.html renders a tag on EVERY row
	# (`tag: owned ? "OWNED" : inert ? "NO EFFECT YET" : locked ? "TOO EXPENSIVE" : "AVAILABLE"`)
	# and godot/CLAUDE.md puts the mockup above a superseded prose pass. The row's state
	# PRIORITY below is this build's own (see the note on this function) — only the missing
	# fourth tag came back.
	var tag_text := "AVAILABLE"
	var tag_bg := DangoTheme.PRIMARY
	if owned:
		tag_text = "OWNED"
		tag_bg = DangoTheme.SUCCESS
	elif too_expensive:
		tag_text = "TOO EXPENSIVE"
		tag_bg = DangoTheme.RARITY_COLORS[0]
	elif inert:
		tag_text = "NO EFFECT YET"
		tag_bg = DangoTheme.WARN_YELLOW
	if not tag_text.is_empty():
		var tag := PanelContainer.new()
		tag.custom_minimum_size = Vector2(0, 22)
		tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tag.add_theme_stylebox_override("panel",
			DangoTheme.solid_chip_style(tag_bg, 6, 2, Vector2(8, 0)))
		# One ink for every tag colour on this row (matches the mockup literally — its tag colour
		# is `#1A1206` regardless of which fill it sits on), because SUCCESS/WARN_YELLOW/
		# RARITY_COLORS[0] are all light enough for dark ink to clear 4.5:1.
		var tag_lbl := DangoTheme.display_label(tag_text, 12, DangoTheme.INK, 800, 0.08)
		tag_lbl.add_theme_constant_override("line_spacing", 0)
		tag.add_child(tag_lbl)
		name_row.add_child(tag)

	var desc_lbl := Label.new()
	desc_lbl.text = String(def.get("d", ""))
	desc_lbl.add_theme_font_size_override("font_size", 13)
	desc_lbl.add_theme_color_override("font_color",
		DangoTheme.INK_ON_CREAM_MUTED if owned else DangoTheme.MUTED_TEXT)
	info.add_child(desc_lbl)

	var buy := Button.new()
	buy.name = "BuyButton"
	buy.custom_minimum_size = Vector2(176, 46)
	buy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	buy.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	buy.add_theme_font_size_override("font_size", 21)
	if owned:
		buy.text = "OWNED"
		buy.disabled = true
		DangoTheme.style_button(buy, true, false, null, true)
	else:
		buy.text = str(cost)
		buy.icon = MockupAssets.tex(SHARD_ICON)
		buy.expand_icon = false
		# Without this the button's minimum size balloons to the icon's native pixel
		# dimensions (the shard art is a large source image) instead of the 176x46 the
		# mockup calls for.
		buy.add_theme_constant_override("icon_max_width", 19)
		buy.add_theme_constant_override("h_separation", 8)
		if too_expensive:
			# CHANGED 2026-09-20 (mockup pass): FIX-PASS-01 U2 gave this `DISABLED_FILL`
			# (#4A3F58) under L5's UNAFFORDABLE reading. meta-screens-v2.html draws the
			# too-expensive price as a WELL fill with #5C6573 ink — which is exactly
			# `ListState.LOCKED`'s own fill and ink, so it is still the system's vocabulary,
			# just the other rung of it. Called out in the task report because it also softens
			# the "never dim the price" rule DangoTheme states for UNAFFORDABLE.
			var unafford_sb := _price_button_style(
				DangoTheme.list_state_fill(DangoTheme.ListState.LOCKED))
			for state_key in ["normal", "hover", "pressed", "disabled"]:
				buy.add_theme_stylebox_override(state_key, unafford_sb)
			var unafford_ink := DangoTheme.list_state_ink(DangoTheme.ListState.LOCKED)
			for color_key in ["font_color", "font_hover_color", "font_pressed_color",
					"font_disabled_color"]:
				buy.add_theme_color_override(color_key, unafford_ink)
			buy.disabled = true
		else:
			DangoTheme.style_button(buy, true)
			# Re-cut to the mockup's own price-button geometry: radius 12, 3px outline, 16px
			# side padding and NO shelf (the row it sits on carries the only shelf here).
			for state_key in ["normal", "hover", "pressed", "disabled"]:
				var lit := buy.get_theme_stylebox(state_key).duplicate() as StyleBoxFlat
				lit.set_corner_radius_all(12)
				lit.set_border_width_all(3)
				lit.content_margin_left = 16.0
				lit.content_margin_right = 16.0
				lit.content_margin_top = 0.0
				lit.content_margin_bottom = 0.0
				lit.shadow_offset = Vector2.ZERO
				buy.add_theme_stylebox_override(state_key, lit)
			buy.pressed.connect(_on_buy_pressed.bind(id))
	hbox.add_child(buy)

	return row


## The mockup's price button: 176x46, radius 12, 3px black outline, 16px side padding, no
## shelf of its own. One builder so the lit and the too-expensive variants cannot drift apart.
func _price_button_style(fill: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = Color.BLACK
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 16.0
	sb.content_margin_right = 16.0
	sb.content_margin_top = 0.0
	sb.content_margin_bottom = 0.0
	return sb


func _on_buy_pressed(id: String) -> void:
	var err := MetaState.buy_unlock(id)
	if err != "":
		_status_label.text = err
		_status_label.visible = true
		return
	_status_label.visible = false
	refresh()
