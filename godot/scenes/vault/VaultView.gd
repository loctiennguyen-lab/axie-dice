extends Control
## The Vault screen — imported Axie NFTs, their derived dice, and the 3D preview built from each
## one's genes. Port of `scVaultHub()`'s VAULT tab (src/client.html:3311-3420).
##
## v2 RESTYLE (docs/design-handoff-v2 §PASS·UNLOCKS·VAULT·GUIDES·CODEX, screenshot
## `screenshots/12-vault.png`): plate + scrim background, an import panel on the left with the
## disabled-import reason on a DANGER plate, and cream record cards on the right whose preview box
## is labelled "AxieCharacter3D · FROM GENES" — the exact wording the task brief calls for. All
## `MetaState`/`AxieApi` logic below is UNCHANGED from the pre-restyle version; only construction
## of the visuals changed. Every node name a test looks up by (`Row_<id>`, `Preview`, `DieStrip`,
## `AxieIdField`, `ScanButton`, `ImportStatus`, `RemoveButton`, `StaleBadge`, `SecretBadge`) is
## preserved exactly.
##
## FLAGGED: the mockup shows a "USE IN TEAM" button on every record. There is no existing
## single-slot hand-off action to wire it to — a vault Axie is already selectable from the normal
## hero dropdown on MainMenu/TeamSelect (it registers into `ContentDB.heroes` as `vault_<id>`,
## same as any other hero), and Guides' one-click hand-off replaces the WHOLE team, not one slot.
## Inventing a partial-team hand-off is a real UX decision (which slot does it replace?) that
## belongs to ux-designer, not to a restyle pass — so this screen keeps REMOVE only, and this note
## says why "USE IN TEAM" is missing rather than leaving it unexplained.
##
## WHAT IS DELIBERATELY NOT HERE
## -----------------------------
## The LEADERBOARD and HISTORY tabs. In the JS build all three live behind one `scVaultHub()`
## because they happened to share a header; they have nothing else in common, and the leaderboard
## depends on the ranked replay-verify strategy that is still an open decision
## (`production/wayfinder/map.md`, frontier A). Copying the tab bar now would ship two buttons
## that lead nowhere.
##
## IMPORT IS LIVE (2026-09-19)
## --------------------------
## Typing an ID fetches the real Axie through `AxieApi` and builds both halves from one response:
## `newGenes` drives the 3D rig, `parts` drives the die. Nothing is faked and no image is
## downloaded.
##
## `AxieApi` shells out to `curl` because the gateway's Cloudflare check blocks Godot's own
## HTTPRequest (measured: HTTP 403, challenge page) — see that file for the full reasoning and for
## the one real limit: **a web export cannot do this**, because it has no `OS.execute`. The screen
## asks `AxieApi.is_available()` and, when the answer is no, disables the field WITH THE REASON ON
## SCREEN rather than leaving a button that looks live and does nothing.

const PREVIEW_SCENE := "res://scenes/shared/AxiePreview3D.tscn"
const MAIN_MENU_SCENE := "res://scenes/main_menu/MainMenu.tscn"

# The plate the mockup asks for. The whole painted set already ships under
# `assets/backgrounds/origins/scene/`, under the kit's own numbered names — the short names the
# handoff uses (`temple.jpg`, `deep-forest.jpg`, `rocky.jpg`) are the same art, renamed for the
# HTML mockups. Three screens briefly fell back to the wrong plate on the belief that these
# images were missing; they never were. Look in that directory before concluding a background
# does not exist, and do not copy the handoff's copies in — that is how a project ends up with
# two of every background and no rule about which one is canonical.
const BG_TEXTURE := "res://assets/backgrounds/origins/scene/9-rocky-mountain-1.jpg"

## Shown under the ID field when importing cannot work on this build at all. The concrete reason
## comes from `AxieApi.unavailable_reason()`; this is the lead-in sentence.
const IMPORT_UNAVAILABLE_PREFIX := "Import is unavailable on this build. "

var _list: HFlowContainer
var _count_label: Label
var _empty_label: Label

var _api: AxieApi
var _id_field: LineEdit
var _scan_button: Button
var _status_label: Label
var _preview_box: PanelContainer
## The Axie currently being previewed, straight from `AxieApi` — the exact payload that will be
## handed to `MetaState.vault_import()` if the player confirms. Held whole rather than as parts,
## so the record that gets stored is provably the one that was shown.
var _pending_axie: Dictionary = {}


func _ready() -> void:
	var plate_host := Control.new()
	plate_host.name = "PlateHost"
	plate_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(plate_host)
	DangoTheme.build_plate(plate_host, load(BG_TEXTURE), DangoTheme.Scrim.DEFAULT)

	_build_header()
	_build_import_panel()
	_build_record_panel()
	_build_back_button()
	refresh()


func _build_header() -> void:
	# One HBox with an EXPAND_FILL spacer, not two independently-positioned Controls — a fixed
	# pixel width on the count chip clipped its own text the moment the number grew past a
	# 2-digit guess (found on the QA capture: "2 / 20 IMPORTED" ran off the right edge of the
	# screen). Sizing to content through the box layout, the way Pass/Unlocks' headers already
	# do, cannot clip regardless of how wide the number gets.
	var row := HBoxContainer.new()
	row.name = "HeaderRow"
	row.set_anchors_preset(Control.PRESET_TOP_WIDE)
	row.offset_left = 64.0
	row.offset_right = -64.0
	row.offset_top = 48.0
	add_child(row)

	var col := VBoxContainer.new()
	col.name = "HeaderCol"
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 9)
	row.add_child(col)

	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(0, 34)
	chip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	chip.add_theme_stylebox_override("panel",
		DangoTheme.solid_chip_style(DangoTheme.SHIELD_BLUE, 9, 3, Vector2(14, 6)))
	var eyebrow := DangoTheme.display_label("IMPORT A REAL AXIE NFT", 14,
		DangoTheme.INK_ON_SHIELD, 800)
	eyebrow.add_theme_constant_override("line_spacing", 0)
	chip.add_child(eyebrow)
	col.add_child(chip)

	col.add_child(DangoTheme.display_label("THE VAULT", 56, DangoTheme.CREAM_RAISED))

	var sub := _body_label("Its six real body parts become a playable die. The 3D model is built"
		+ " from the same genes, on the same rig your party uses.")
	sub.add_theme_color_override("font_color", DangoTheme.TEXT_DIM)
	col.add_child(sub)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	var count_chip := PanelContainer.new()
	count_chip.name = "ImportCountChip"
	count_chip.custom_minimum_size = Vector2(0, 56)
	count_chip.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var chip_sb := DangoTheme.surface_style(DangoTheme.Surface.PANEL, 13, 4, 5.0, Vector2(18, 0))
	chip_sb.bg_color = DangoTheme.SHIELD_BLUE
	count_chip.add_theme_stylebox_override("panel", chip_sb)
	row.add_child(count_chip)

	var count_row := HBoxContainer.new()
	count_row.alignment = BoxContainer.ALIGNMENT_CENTER
	count_row.add_theme_constant_override("separation", 8)
	count_chip.add_child(count_row)

	_count_label = DangoTheme.display_label("", 34, DangoTheme.INK_ON_SHIELD)
	_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_row.add_child(_count_label)


func _build_import_panel() -> void:
	var panel := PanelContainer.new()
	panel.name = "ImportPanel"
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.offset_left = 64.0
	panel.offset_top = 256.0
	panel.custom_minimum_size = Vector2(500, 0)
	panel.add_theme_stylebox_override("panel",
		DangoTheme.surface_style(DangoTheme.Surface.PANEL, 16, 4, 5.0, Vector2(18, 16)))
	add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)

	var available := AxieApi.is_available()

	var eyebrow := DangoTheme.display_label("IMPORT BY AXIE ID", 13, DangoTheme.MUTED_TEXT, 800)
	col.add_child(eyebrow)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 9)
	col.add_child(row)

	_id_field = LineEdit.new()
	_id_field.name = "AxieIdField"
	_id_field.placeholder_text = "e.g. 11778888"
	_id_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_id_field.custom_minimum_size = Vector2(0, 50)
	_id_field.editable = available
	_id_field.add_theme_stylebox_override("normal",
		DangoTheme.surface_style(DangoTheme.Surface.WELL, 11, 3, 0.0, Vector2(14, 0)))
	# Enter submits. Typing an ID and pressing Return is what everyone tries first, and a field
	# that ignores it feels broken even though the button beside it works.
	_id_field.text_submitted.connect(func(_t: String) -> void: _on_scan_pressed())
	_id_field.text_changed.connect(func(_t: String) -> void: _refresh_scan_enabled())
	row.add_child(_id_field)

	_scan_button = Button.new()
	_scan_button.name = "ScanButton"
	_scan_button.text = "SCAN"
	_scan_button.custom_minimum_size = Vector2(112, 50)
	DangoTheme.style_button(_scan_button, true)
	_scan_button.pressed.connect(_on_scan_pressed)
	row.add_child(_scan_button)

	if not available:
		var plate := PanelContainer.new()
		plate.name = "UnavailablePlate"
		var plate_sb := DangoTheme.surface_style(DangoTheme.Surface.PANEL, 11, 3, 0.0, Vector2(13, 11))
		plate_sb.bg_color = DangoTheme.DANGER
		plate.add_theme_stylebox_override("panel", plate_sb)
		col.add_child(plate)
		var plate_lbl := _body_label(IMPORT_UNAVAILABLE_PREFIX + AxieApi.unavailable_reason())
		plate_lbl.add_theme_font_size_override("font_size", 13)
		plate_lbl.add_theme_color_override("font_color", DangoTheme.INK_ON_DANGER)
		plate.add_child(plate_lbl)

	_status_label = _body_label("")
	_status_label.name = "ImportStatus"
	_status_label.add_theme_color_override("font_color", DangoTheme.MUTED_TEXT)
	if not available:
		_status_label.text = IMPORT_UNAVAILABLE_PREFIX + AxieApi.unavailable_reason()
		_status_label.add_theme_color_override("font_color", DangoTheme.DANGER)
	col.add_child(_status_label)

	var rule := ColorRect.new()
	rule.custom_minimum_size = Vector2(0, 3)
	rule.color = Color.BLACK
	col.add_child(rule)

	col.add_child(DangoTheme.display_label("RANKED RUN", 13, DangoTheme.MUTED_TEXT, 800))
	var ranked_note := PanelContainer.new()
	ranked_note.add_theme_stylebox_override("panel",
		DangoTheme.surface_style(DangoTheme.Surface.WELL, 11, 3, 0.0, Vector2(13, 11)))
	col.add_child(ranked_note)
	var ranked_lbl := _body_label("Imported Axies are blocked in Ranked. Every submission plays"
		+ " the same baseline die.")
	ranked_lbl.add_theme_font_size_override("font_size", 13)
	ranked_lbl.add_theme_color_override("font_color", DangoTheme.INFO_TEXT_ON_WELL)
	ranked_note.add_child(ranked_lbl)

	_preview_box = PanelContainer.new()
	_preview_box.name = "ImportPreview"
	_preview_box.add_theme_stylebox_override("panel",
		DangoTheme.surface_style(DangoTheme.Surface.PANEL_RAISED, 11, 3, 4.0, Vector2(12, 10)))
	_preview_box.visible = false
	col.add_child(_preview_box)

	_refresh_scan_enabled()


func _build_record_panel() -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "RecordScroll"
	scroll.set_anchors_preset(Control.PRESET_TOP_WIDE)
	scroll.offset_left = 592.0
	scroll.offset_right = -64.0
	scroll.offset_top = 256.0
	scroll.offset_bottom = -30.0
	scroll.anchor_bottom = 1.0
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	DangoTheme.style_scrollbars(scroll)
	# ScrollContainer does not clip its content by default in this Godot version — without
	# this, a list longer than the container's rect draws straight through it and over
	# whatever sits below (found on the Unlocks QA capture: row 10 bled past the panel and
	# over the BACK button).
	scroll.clip_contents = true
	add_child(scroll)

	# HFlowContainer, not a fixed HBox: up to VAULT_MAX (20) records must wrap onto more than one
	# row rather than being squeezed to zero width or spilling off the right edge, which a straight
	# left-to-right row (the mockup's own layout, drawn for exactly 2 records) cannot do.
	_list = HFlowContainer.new()
	_list.name = "RecordList"
	_list.add_theme_constant_override("h_separation", 16)
	_list.add_theme_constant_override("v_separation", 16)
	scroll.add_child(_list)

	_empty_label = _body_label("")
	_empty_label.name = "EmptyLabel"
	_empty_label.add_theme_color_override("font_color", DangoTheme.TEXT_DIM)
	add_child(_empty_label)


func _build_back_button() -> void:
	var back := Button.new()
	back.name = "BackButton"
	back.text = "BACK"
	back.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	back.position = Vector2(64, -44 - 24)
	back.custom_minimum_size = Vector2(0, 44)
	DangoTheme.style_button(back, false)
	back.pressed.connect(func() -> void:
		get_tree().change_scene_to_file(MAIN_MENU_SCENE))
	add_child(back)


## Rebuilds the list from `MetaState.vault`. Public so a test can drive it after changing the
## store, and called after every mutation — the vault is at most twenty rows, so re-rendering all
## of it is cheaper to reason about than patching rows in place.
func refresh() -> void:
	if _api == null:
		_api = AxieApi.new()
		_api.name = "AxieApi"
		_api.completed.connect(_on_fetch_completed)
		add_child(_api)

	for child in _list.get_children():
		child.queue_free()
		_list.remove_child(child)

	var entries := MetaState.vault
	# The word "FULL", not only the colour. Colour alone is the single signal a colour-blind
	# player does not get — and once the network layer lands this is the only thing telling
	# someone why their next import was refused.
	var full := MetaState.vault_is_full()
	_count_label.text = "%d / %d%s" % [
		entries.size(), MetaState.VAULT_MAX, "  ·  FULL" if full else "  IMPORTED"]
	_count_label.add_theme_color_override("font_color",
		DangoTheme.DANGER if full else DangoTheme.INK_ON_SHIELD)
	_empty_label.visible = entries.is_empty()
	# Just the state, not the reason — the reason is already on screen two lines above, under the
	# control it disables, and printing the same sentence twice in a row reads as a bug.
	_empty_label.text = "No Axies imported yet." if entries.is_empty() else ""

	for entry in entries:
		_list.add_child(_build_row(entry))


## SCAN is enabled only for something that could actually be an Axie ID. Letting it fire on "abc"
## costs a round trip to learn what the field could have said immediately.
func _refresh_scan_enabled() -> void:
	if _scan_button == null:
		return
	var busy := not _status_label.text.is_empty() and _status_label.text.begins_with("Looking up")
	_scan_button.disabled = (not AxieApi.is_available()) or busy \
		or not AxieApi.is_valid_axie_id(_id_field.text)


func _on_scan_pressed() -> void:
	if not AxieApi.is_available() or not AxieApi.is_valid_axie_id(_id_field.text):
		return
	_preview_box.visible = false
	_pending_axie = {}
	_status_label.text = "Looking up Axie #%s…" % _id_field.text.strip_edges()
	_status_label.add_theme_color_override("font_color", DangoTheme.MUTED_TEXT)
	_refresh_scan_enabled()
	_api.request_axie(_id_field.text)


func _on_fetch_completed(result: Dictionary) -> void:
	if not bool(result.get("ok", false)):
		_status_label.text = str(result.get("message", "Could not fetch that Axie."))
		_status_label.add_theme_color_override("font_color", DangoTheme.DANGER)
		_pending_axie = {}
		_preview_box.visible = false
		_refresh_scan_enabled()
		return
	_pending_axie = result["axie"]
	_status_label.text = ""
	_build_import_preview(_pending_axie)
	_refresh_scan_enabled()


## Shows what WOULD be stored, before it is stored. The die is the thing that matters in play and
## the player cannot see it anywhere else, so importing blind would mean finding out what an Axie
## is worth only after spending a vault slot on it.
func _build_import_preview(axie: Dictionary) -> void:
	for child in _preview_box.get_children():
		_preview_box.remove_child(child)
		child.queue_free()

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_preview_box.add_child(row)

	var preview := (load(PREVIEW_SCENE) as PackedScene).instantiate() as AxiePreview3D
	preview.name = "Preview"
	preview.custom_minimum_size = Vector2(140, 140)
	row.add_child(preview)
	preview.set_genes(str(axie.get("genes", "")))

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)
	row.add_child(info)

	var die := AxieToDie.build({
		"id": axie.get("id", ""), "class": axie.get("class", ""), "parts": axie.get("parts", []),
	})
	var title := DangoTheme.display_label(str(die.get("n", "Axie")), 19, DangoTheme.CREAM_RAISED)
	info.add_child(title)

	var secret := _optional_string(die.get("secret_cls"))
	var shown := secret if not secret.is_empty() else str(die.get("cls", ""))
	var stats := _body_label("%s  ·  HP %d  ·  purity %d/6  ·  gene tier %d" % [
		shown.to_upper(), int(die.get("max_hp", 0)), int(die.get("purity", 0)),
		int(die.get("gene_tier", 0))])
	stats.add_theme_color_override("font_color", DangoTheme.MUTED_TEXT)
	info.add_child(stats)
	info.add_child(_build_die_strip(die.get("die", [])))

	# The part names the die was actually derived from. Without them "2 dmg" is a number with no
	# provenance, and a player comparing two Axies has nothing to compare.
	var part_names := PackedStringArray()
	for pt in axie.get("parts", []):
		part_names.append("%s: %s" % [str((pt as Dictionary).get("type", "?")),
			str((pt as Dictionary).get("name", "?"))])
	var parts_lbl := _body_label(", ".join(part_names))
	parts_lbl.add_theme_font_size_override("font_size", 11)
	parts_lbl.add_theme_color_override("font_color", DangoTheme.MUTED_TEXT)
	info.add_child(parts_lbl)

	var already := MetaState.vault_index_of(str(axie.get("id", ""))) >= 0
	var full := MetaState.vault_is_full()
	var add := Button.new()
	add.name = "AddButton"
	add.custom_minimum_size = Vector2(0, 42)
	# Three different situations, three different words. "ADD TO VAULT" on a vault that cannot
	# take one more is a button that fails after being pressed.
	if already:
		add.text = "UPDATE VAULT ENTRY"
	elif full:
		add.text = "VAULT FULL (%d/%d)" % [MetaState.vault.size(), MetaState.VAULT_MAX]
	else:
		add.text = "ADD TO VAULT"
	add.disabled = full and not already
	DangoTheme.style_button(add, true)
	add.pressed.connect(_on_add_pressed)
	info.add_child(add)

	_preview_box.visible = true


func _on_add_pressed() -> void:
	if _pending_axie.is_empty():
		return
	var res := MetaState.vault_import({
		"id": _pending_axie.get("id", ""),
		"class": _pending_axie.get("class", ""),
		"parts": _pending_axie.get("parts", []),
		"genes": _pending_axie.get("genes", ""),
	})
	if not bool(res.get("ok", false)):
		_status_label.text = ("Vault is full (%d/%d)." % [MetaState.vault.size(),
			MetaState.VAULT_MAX]) if str(res.get("err", "")) == "vault_full" \
			else "Could not add this Axie."
		_status_label.add_theme_color_override("font_color", DangoTheme.DANGER)
		return
	_status_label.text = "%s %s." % [
		"Updated" if bool(res.get("updated", false)) else "Added",
		str(_pending_axie.get("id", ""))]
	_status_label.add_theme_color_override("font_color", DangoTheme.SUCCESS)
	_pending_axie = {}
	_preview_box.visible = false
	_id_field.text = ""
	_refresh_scan_enabled()
	refresh()


func _build_row(entry: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "Row_" + str(entry.get("axie_id", ""))
	card.custom_minimum_size = Vector2(360, 0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", DangoTheme.cream_card_style(Color.TRANSPARENT))

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 0)
	card.add_child(outer)

	var stale_card := MetaState.vault_stale(entry)
	var cls := str(entry.get("cls", ""))
	var secret := _optional_string(entry.get("secret_cls"))
	var shown_class := secret if not secret.is_empty() else cls

	# A stale record gets a DANGER header, not just red text inside an identical card. Scrolling
	# a twenty-row list, a small red sentence is easy to pass; a differently-coloured header is
	# not.
	var band := PanelContainer.new()
	band.custom_minimum_size = Vector2(0, 44)
	var band_sb := StyleBoxFlat.new()
	band_sb.bg_color = DangoTheme.DANGER if stale_card else DangoTheme.class_color(shown_class)
	band_sb.border_width_bottom = 4
	band_sb.border_color = Color.BLACK
	band_sb.corner_radius_top_left = 12
	band_sb.corner_radius_top_right = 12
	band_sb.content_margin_left = 14.0
	band_sb.content_margin_right = 14.0
	band.add_theme_stylebox_override("panel", band_sb)
	outer.add_child(band)

	var band_row := HBoxContainer.new()
	band_row.alignment = BoxContainer.ALIGNMENT_CENTER
	band.add_child(band_row)

	var nm := DangoTheme.display_label(str(entry.get("n", "Axie")), 20, DangoTheme.INK)
	band_row.add_child(nm)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	band_row.add_child(spacer)

	var flag_text := "RE-SCAN NEEDED" if stale_card else "READY"
	var flag_bg := DangoTheme.WARN_YELLOW if stale_card else DangoTheme.SUCCESS
	var flag := PanelContainer.new()
	flag.add_theme_stylebox_override("panel", DangoTheme.solid_chip_style(flag_bg, 7, 2, Vector2(9, 2)))
	var flag_lbl := DangoTheme.display_label(flag_text, 12, DangoTheme.INK, 800)
	flag_lbl.add_theme_constant_override("line_spacing", 0)
	flag.add_child(flag_lbl)
	band_row.add_child(flag)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	outer.add_child(margin)

	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 10)
	margin.add_child(info)

	# A secret class is mapped to a real class for its passive; saying only the mapped one would
	# hide the thing that makes the Axie unusual, and saying only the secret one would leave the
	# player wondering which passive they actually get.
	var meta_bits := ["Axie #%s" % str(entry.get("axie_id", "")), shown_class.to_upper(),
		"%d HP" % int(entry.get("max_hp", 0))]
	var meta_lbl := _body_label(" · ".join(meta_bits))
	meta_lbl.add_theme_font_size_override("font_size", 12)
	meta_lbl.add_theme_color_override("font_color", DangoTheme.INK_ON_CREAM_MUTED)
	info.add_child(meta_lbl)
	if not secret.is_empty():
		var badge := Label.new()
		badge.name = "SecretBadge"
		badge.text = "◈ SECRET · plays as %s" % cls.to_upper()
		badge.add_theme_font_size_override("font_size", 12)
		badge.add_theme_color_override("font_color", DangoTheme.MANA_PURPLE)
		info.add_child(badge)

	var preview_box := PanelContainer.new()
	preview_box.custom_minimum_size = Vector2(0, 224)
	preview_box.add_theme_stylebox_override("panel",
		DangoTheme.surface_style(DangoTheme.Surface.CREAM_RAISED, 14, 3, 0.0, Vector2(-1, -1)))
	preview_box.clip_contents = true
	info.add_child(preview_box)

	var caption := DangoTheme.display_label("AxieCharacter3D · FROM GENES", 11,
		DangoTheme.INK_ON_CREAM_MUTED, 800)
	caption.set_anchors_preset(Control.PRESET_TOP_LEFT)
	caption.position = Vector2(11, 9)
	caption.add_theme_constant_override("line_spacing", 0)
	preview_box.add_child(caption)

	# The 3D preview, rebuilt from the genes stored with the record. This is why the record keeps
	# `genes` at all — no image is cached, and nothing is fetched.
	var preview := (load(PREVIEW_SCENE) as PackedScene).instantiate() as AxiePreview3D
	preview.name = "Preview"
	preview.set_anchors_preset(Control.PRESET_FULL_RECT)
	preview_box.add_child(preview)
	preview.set_genes(str(entry.get("genes", "")))

	var die_caption := DangoTheme.display_label("DIE FROM ITS SIX REAL PARTS", 12,
		DangoTheme.INK_ON_CREAM_MUTED, 800)
	info.add_child(die_caption)
	info.add_child(_build_die_strip(entry.get("die", [])))

	if stale_card:
		var stale := Label.new()
		stale.name = "StaleBadge"
		stale.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		# The instruction has to carry its own caveat. "RE-SCAN NEEDED" reads as an action to take
		# right now — but re-scanning needs the network layer, which is not in this build, and the
		# explanation for that lives at the top of a list that can be twenty rows long. A player
		# scrolled to the bottom would see an urgent order they cannot obey and no reason why. So
		# the line names the one thing they CAN do, right where they read it.
		stale.text = ("This die was built under older rules and cannot be played. Re-scanning"
			+ " needs the network layer, which is not in this build yet; REMOVE is the only"
			+ " action available for now.")
		stale.add_theme_font_size_override("font_size", 12)
		stale.add_theme_color_override("font_color", DangoTheme.DANGER)
		info.add_child(stale)

	var remove := Button.new()
	remove.name = "RemoveButton"
	remove.text = "REMOVE"
	remove.custom_minimum_size = Vector2(0, 46)
	# Flat DANGER fill with ink on it, not `style_button(primary, warning=true)` — that helper's
	# `warning` flag only recolours the BORDER to DANGER and keeps the PRIMARY orange fill (it
	# exists for the End Turn button's "this ends the turn" accent, a different job). REMOVE needs
	# the fill itself to read as destructive, matching the mockup's solid red button.
	var remove_sb := DangoTheme.secondary_button_style(DangoTheme.ButtonState.NORMAL)
	remove_sb.bg_color = DangoTheme.DANGER
	remove.add_theme_stylebox_override("normal", remove_sb)
	var remove_hover := remove_sb.duplicate() as StyleBoxFlat
	remove_hover.bg_color = DangoTheme.DANGER.lightened(0.15)
	remove.add_theme_stylebox_override("hover", remove_hover)
	remove.add_theme_stylebox_override("pressed", remove_hover)
	for color_key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		remove.add_theme_color_override(color_key, DangoTheme.INK_ON_DANGER)
	remove.pressed.connect(_on_remove_pressed.bind(str(entry.get("axie_id", ""))))
	info.add_child(remove)
	return card


## The six faces, as value + type, in slot order. Deliberately the same numbers the die card in
## combat shows: a player comparing an import against a starter hero is comparing these.
func _build_die_strip(die: Array) -> GridContainer:
	var grid := GridContainer.new()
	grid.name = "DieStrip"
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for f in die:
		var face: Dictionary = f
		var value := int(face.get("v", 0))
		var ftype := str(face.get("t", "blank"))
		var accent := DangoTheme.die_type_color(ftype)

		var chip := PanelContainer.new()
		# FIXED 2026-09-20 consistency sweep: without an expand flag, GridContainer sizes each
		# column to its children's minimum width only — the grid itself was stretched to the
		# card's full width by the parent VBox, but the three columns of chips inside it were
		# not, leaving a dead cream gap on the right of every die-strip row (found on this
		# screen's own QA capture). The mockup's three-column grid fills the card edge to edge.
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chip.add_theme_stylebox_override("panel",
			DangoTheme.surface_style(DangoTheme.Surface.CREAM_RAISED, 10, 3, 0.0, Vector2(9, 8)))
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 5)
		chip.add_child(col)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 7)
		col.add_child(row)
		var value_lbl := DangoTheme.display_label(
			"—" if ftype == "blank" else str(value), 22, DangoTheme.INK)
		row.add_child(value_lbl)
		var swatch := PanelContainer.new()
		swatch.custom_minimum_size = Vector2(17, 17)
		swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var swatch_sb := StyleBoxFlat.new()
		swatch_sb.bg_color = accent
		swatch_sb.border_color = Color.BLACK
		swatch_sb.set_border_width_all(2)
		swatch_sb.set_corner_radius_all(5)
		swatch.add_theme_stylebox_override("panel", swatch_sb)
		row.add_child(swatch)

		var caption := DangoTheme.display_label(ftype.to_upper(), 10, DangoTheme.INK_ON_CREAM_MUTED, 800)
		caption.add_theme_constant_override("line_spacing", 0)
		col.add_child(caption)

		grid.add_child(chip)
	return grid


func _on_remove_pressed(axie_id: String) -> void:
	MetaState.vault_remove(axie_id)
	refresh()


## "" for a missing or null value, instead of GDScript's "<NULL>". Records carry real nulls
## wherever the JS carries them, so every optional field read into a Label has to come through
## here — the alternative is a UI rule violation that only a screenshot finds.
static func _optional_string(value: Variant) -> String:
	return "" if value == null else str(value)


func _body_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", DangoTheme.TEXT)
	return lbl
