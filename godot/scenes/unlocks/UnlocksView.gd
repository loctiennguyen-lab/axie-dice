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
const BG_TEXTURE := "res://assets/backgrounds/origins/scene/7-deep-forest.jpg"

const SHARD_ICON := "res://assets/icons/web/shard.png"

var _list: VBoxContainer
var _shard_label: Label
var _status_label: Label


func _ready() -> void:
	var plate_host := Control.new()
	plate_host.name = "PlateHost"
	plate_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(plate_host)
	DangoTheme.build_plate(plate_host, load(BG_TEXTURE), DangoTheme.Scrim.DEFAULT)

	_build_header()
	_build_list_panel()
	_build_back_button()
	refresh()


func _build_header() -> void:
	var row := HBoxContainer.new()
	row.name = "HeaderRow"
	row.set_anchors_preset(Control.PRESET_TOP_WIDE)
	row.offset_left = 84.0
	row.offset_right = -84.0
	row.offset_top = 54.0
	add_child(row)

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
		DangoTheme.INK_ON_PRIMARY, 800)
	eyebrow_lbl.add_theme_constant_override("line_spacing", 0)
	chip.add_child(eyebrow_lbl)
	title_col.add_child(chip)

	title_col.add_child(DangoTheme.display_label("UNLOCKS", 56, DangoTheme.CREAM_RAISED))

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	var shard_chip := PanelContainer.new()
	shard_chip.name = "ShardChip"
	shard_chip.custom_minimum_size = Vector2(0, 56)
	shard_chip.size_flags_vertical = Control.SIZE_SHRINK_END
	shard_chip.add_theme_stylebox_override("panel",
		DangoTheme.surface_style(DangoTheme.Surface.CREAM, 13, 4, 5.0, Vector2(18, 0)))
	row.add_child(shard_chip)

	var shard_row := HBoxContainer.new()
	shard_row.add_theme_constant_override("separation", 10)
	shard_chip.add_child(shard_row)

	if ResourceLoader.exists(SHARD_ICON):
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(30, 30)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = load(SHARD_ICON)
		shard_row.add_child(icon)

	_shard_label = DangoTheme.display_label("0", 34, DangoTheme.INK)
	_shard_label.name = "ShardLabel"
	_shard_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	shard_row.add_child(_shard_label)


func _build_list_panel() -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "ListScroll"
	scroll.set_anchors_preset(Control.PRESET_TOP_WIDE)
	scroll.offset_left = 360.0
	scroll.offset_right = -360.0
	scroll.offset_top = 196.0
	scroll.offset_bottom = -100.0
	scroll.anchor_bottom = 1.0
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	DangoTheme.style_scrollbars(scroll)
	# ScrollContainer does not clip its content by default in this Godot version — without
	# this, a list longer than the container's rect draws straight through it and over
	# whatever sits below (found on the Unlocks QA capture: row 10 bled past the panel and
	# over the BACK button).
	scroll.clip_contents = true
	add_child(scroll)

	_list = VBoxContainer.new()
	_list.name = "UnlockList"
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 10)
	scroll.add_child(_list)

	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	_status_label.visible = false
	_status_label.add_theme_font_size_override("font_size", 13)
	_status_label.add_theme_color_override("font_color", DangoTheme.DANGER)
	add_child(_status_label)


func _build_back_button() -> void:
	var back := Button.new()
	back.name = "BackButton"
	back.text = "BACK"
	back.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	back.position = Vector2(84, -44 - 28)
	back.custom_minimum_size = Vector2(0, 44)
	DangoTheme.style_button(back, false)
	back.pressed.connect(func() -> void:
		get_tree().change_scene_to_file(MAIN_MENU_SCENE))
	add_child(back)


func refresh() -> void:
	_shard_label.text = str(MetaState.shard_pool)
	for child in _list.get_children():
		child.queue_free()
		_list.remove_child(child)
	for def in ContentDB.UNLOCKS:
		_list.add_child(_build_row(def))


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
		DangoTheme.INK if owned else DangoTheme.CREAM_RAISED)
	name_row.add_child(name_lbl)

	var tag_text: String
	var tag_bg: Color
	if owned:
		tag_text = "OWNED"
		tag_bg = DangoTheme.SUCCESS
	elif too_expensive:
		tag_text = "TOO EXPENSIVE"
		tag_bg = DangoTheme.RARITY_COLORS[0]
	elif inert:
		tag_text = "NO EFFECT YET"
		tag_bg = DangoTheme.WARN_YELLOW
	else:
		tag_text = "AVAILABLE"
		tag_bg = DangoTheme.PRIMARY
	var tag := PanelContainer.new()
	tag.custom_minimum_size = Vector2(0, 22)
	tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tag.add_theme_stylebox_override("panel", DangoTheme.solid_chip_style(tag_bg, 6, 2, Vector2(8, 0)))
	# One ink for every tag colour on this row (matches the mockup literally — its tag colour is
	# `#1A1206` regardless of which fill it sits on), because SUCCESS/PRIMARY/WARN_YELLOW/
	# RARITY_COLORS[0] are all light enough for dark ink to clear 4.5:1.
	var tag_lbl := DangoTheme.display_label(tag_text, 12, DangoTheme.INK, 800)
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
	if owned:
		buy.text = "OWNED"
		buy.disabled = true
		DangoTheme.style_button(buy, true, false, null, true)
	else:
		buy.text = str(cost)
		if ResourceLoader.exists(SHARD_ICON):
			buy.icon = load(SHARD_ICON)
			buy.expand_icon = false
			# Without this the button's minimum size balloons to the icon's native pixel
			# dimensions (the shard art is a large source image) instead of the 176x50 the
			# redline calls for — found by screenshot, not by the gate, since no test measures a
			# button's rect in pixels.
			buy.add_theme_constant_override("icon_max_width", 19)
		DangoTheme.style_button(buy, true)
		buy.disabled = too_expensive
		if not too_expensive:
			buy.pressed.connect(_on_buy_pressed.bind(id))
	hbox.add_child(buy)

	return row


func _on_buy_pressed(id: String) -> void:
	var err := MetaState.buy_unlock(id)
	if err != "":
		_status_label.text = err
		_status_label.visible = true
		return
	_status_label.visible = false
	refresh()
