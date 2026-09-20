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
const BG_MOCKUP_PLATE := "assets/bg/rocky.jpg"

## Shown under the ID field when importing cannot work on this build at all. The concrete reason
## comes from `AxieApi.unavailable_reason()`; this is the lead-in sentence.
const IMPORT_UNAVAILABLE_PREFIX := "Import is unavailable on this build. "

var _list: GridContainer
var _record_scroll: ScrollContainer
var _record_fade: TextureRect
var _count_label: Label
var _count_caption: Label
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

## FIX-PASS-02 §1 item 4: `content` already supplies the safe area and the 84px rail
## (`DangoScreen.RAIL_X`). This screen's columns sit at absolute margins narrower than the rail
## (64px, not 84), so their offsets against `content` are `old_absolute_margin - RAIL_X` —
## preserving the same distance from the real screen edge the mockup asked for.
var _content: Control
const HEADER_INSET := 64.0 - 84.0     # -20: 20px INSIDE the standard rail
const IMPORT_LEFT := 64.0 - 84.0      # same column as the header
## Mockup: `left:620` for the record column (was 592 here, a 28px drift).
const RECORD_LEFT := 620.0 - 84.0
const RECORD_RIGHT := -64.0 + 84.0
## FIXED 2026-09-20 (mockup pass): `content`'s top edge is already the 48px safe line, so a
## mockup `top:256` is 208 here. These were being added ON TOP of the shell's inset, which put
## the header at 96 and both columns at 304 — every vertical measurement on this screen was 48
## low.
const HEADER_TOP := 48.0 - 48.0
const RECORD_TOP := 256.0 - 48.0

## V3 — SETTLED BY THE MOCKUP, so the panel does not move. The review flagged the import
## panel's outer edge at x=66 as "confirm against the mockup's own value before moving", and
## `meta-screens-v2.html`'s Vault draws it at `left:64` (its header row is `left:64; right:64`
## too). `IMPORT_LEFT` above already resolves to 64. Vault does NOT take Team Select's 56 or
## the shell's 84 — it has its own inset and this is it.
##
## BOX MODEL (design review 2026-09-20). Every fixed size below is the mockup's CONTENT box and
## the black border adds OUTSIDE it, so an outer size is the mockup's number plus its border on
## each edge that has one. This is the single error the review found across all three meta
## screens, and these constants are the whole of it on this one.
const IMPORT_PANEL_W := 528.0      ## width:520 + border:4 each side
const EYEBROW_CHIP_H := 40.0       ## height:34 + border:3
const COUNT_CHIP_H := 64.0         ## height:56 + border:4
const ID_FIELD_H := 56.0           ## height:50 + border:3
const SCAN_SIZE := Vector2(118, 56)  ## width:112; height:50 + border:3
const CARD_BAND_H := 48.0          ## height:44 + border-bottom:4
const CARD_FLAG_H := 28.0          ## height:24 + border:2
const PREVIEW_BOX_H := 230.0       ## height:224 + border:3
const REMOVE_BTN_H := 56.0         ## height:50 + border:3


func _ready() -> void:
	# G1, RESOLVED BY THE OWNER (20 Sep 2026): the meta screens keep a BACK button.
	#
	# The design review was right that no v2 mockup draws a footer bar — in `meta-screens-v2.html`
	# all seven meta screens are closed by a shared `META` tab strip across the top, which this
	# build does not have. So this pass removed the bar, and that left the Vault with no on-screen
	# way out at all: Esc worked, a mouse did not. The owner's call is to keep a back control on
	# the meta screens rather than build the tab strip, so the footer stays here.
	#
	# Scoped deliberately. This is the META screens only — Run Map and Result still pass `false`,
	# because unlike the Vault their mockups DO draw their own closing controls (SAVE & QUIT at
	# the foot of the map's rail; RUN IT AGAIN and MAIN MENU centred at `bottom:52`), and the bar
	# was actively displacing them. Pass, Unlocks, Guides, Codex and Team Select already keep
	# theirs, so the Vault matches its siblings again.
	var shell := DangoScreen.build(self, MockupAssets.tex(BG_MOCKUP_PLATE),
		DangoTheme.Scrim.DEFAULT, true)
	_content = shell["content"]
	# FIXED 2026-09-20: the bar above was being built and then left EMPTY - `shell["footer"]`
	# was never read. So the screen carried a 72px chrome bar with nothing in it and still had
	# no mouse way out, which is the exact defect the comment above says the owner asked to
	# close. FIX-PASS-03 §8: BACK lives in the footer on all seven meta screens, never on art.
	DangoScreen.add_back_button(shell["footer"] as HBoxContainer, func() -> void:
		get_tree().change_scene_to_file(MAIN_MENU_SCENE))

	_build_header()
	_build_import_panel()
	_build_record_panel()
	refresh()


## Esc closes the screen too. Kept now that the footer is back — it costs nothing and a
## keyboard player should not have to reach for the mouse to leave.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _build_header() -> void:
	# One HBox with an EXPAND_FILL spacer, not two independently-positioned Controls — a fixed
	# pixel width on the count chip clipped its own text the moment the number grew past a
	# 2-digit guess (found on the QA capture: "2 / 20 IMPORTED" ran off the right edge of the
	# screen). Sizing to content through the box layout, the way Pass/Unlocks' headers already
	# do, cannot clip regardless of how wide the number gets.
	var row := HBoxContainer.new()
	row.name = "HeaderRow"
	row.set_anchors_preset(Control.PRESET_TOP_WIDE)
	row.offset_left = HEADER_INSET
	row.offset_right = -HEADER_INSET
	row.offset_top = HEADER_TOP
	_content.add_child(row)

	var col := VBoxContainer.new()
	col.name = "HeaderCol"
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 9)
	row.add_child(col)

	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(0, EYEBROW_CHIP_H)
	chip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	chip.add_theme_stylebox_override("panel",
		DangoTheme.solid_chip_style(DangoTheme.SHIELD_BLUE, 9, 3, Vector2(14, 6)))
	var eyebrow := DangoTheme.display_label("IMPORT A REAL AXIE NFT", 14,
		DangoTheme.INK_ON_SHIELD, 800, 0.16)
	eyebrow.add_theme_constant_override("line_spacing", 0)
	chip.add_child(eyebrow)
	col.add_child(chip)

	col.add_child(DangoTheme.display_label("THE VAULT", 56, DangoTheme.CREAM_RAISED,
		800, 0.02))

	var sub := _body_label("Its six real body parts become a playable die. The 3D model is built"
		+ " from the same genes, on the same rig your party uses.")
	# CORRECTED 2026-09-20 (mockup pass): `SUBTITLE_TEXT` IS `#A6B0BF` and names this exact
	# label in its own docstring. MUTED_TEXT (`#8C95A4`) was a near-miss standing in for it.
	sub.add_theme_color_override("font_color", DangoTheme.SUBTITLE_TEXT)
	sub.custom_minimum_size.x = 900   # mockup: max-width 900
	col.add_child(sub)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	var count_chip := PanelContainer.new()
	count_chip.name = "ImportCountChip"
	count_chip.custom_minimum_size = Vector2(0, COUNT_CHIP_H)
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

	_count_caption = DangoTheme.display_label("IMPORTED", 13, DangoTheme.INK_ON_SHIELD, 800, 0.1)
	_count_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_count_caption.add_theme_constant_override("line_spacing", 0)
	count_row.add_child(_count_caption)


func _build_import_panel() -> void:
	var panel := PanelContainer.new()
	panel.name = "ImportPanel"
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.offset_left = IMPORT_LEFT
	panel.offset_top = RECORD_TOP
	panel.custom_minimum_size = Vector2(IMPORT_PANEL_W, 0)
	panel.add_theme_stylebox_override("panel",
		DangoTheme.surface_style(DangoTheme.Surface.PANEL, 16, 4, 5.0, Vector2(20, 18)))
	_content.add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)

	var available := AxieApi.is_available()

	var eyebrow := DangoTheme.display_label("IMPORT BY AXIE ID", 13, DangoTheme.MUTED_TEXT, 800, 0.16)
	col.add_child(eyebrow)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 9)
	col.add_child(row)

	_id_field = LineEdit.new()
	_id_field.name = "AxieIdField"
	_id_field.placeholder_text = "e.g. 11778888"
	_id_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_id_field.custom_minimum_size = Vector2(0, ID_FIELD_H)
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
	_scan_button.custom_minimum_size = SCAN_SIZE
	DangoTheme.apply_tracking(_scan_button, 0.08, 15)
	DangoTheme.style_button(_scan_button, true)
	# FLAGGED V2: `style_button(primary=true)`'s DISABLED variant desaturates PRIMARY toward grey
	# (`primary_button_style()`'s DISABLED branch) — correct for a list row that is "unaffordable"
	# or "locked", but SCAN's disabled state here means only "no ID typed yet", an input gate, not
	# an L5 list state. That blend read as a muddy off-palette brown on the QA capture. Per the
	# audit's literal instruction ("PRIMARY + INK_ON_PRIMARY") this button stays fully PRIMARY-lit
	# in every state, including disabled — it just isn't clickable until the field holds a valid
	# ID. A future pass could give "no input yet" its own token in the L5 vocabulary instead of
	# reusing (or here, overriding) the generic button DISABLED look.
	var scan_lit_sb := DangoTheme.primary_button_style(false, DangoTheme.ButtonState.NORMAL)
	_scan_button.add_theme_stylebox_override("disabled", scan_lit_sb)
	_scan_button.add_theme_color_override("font_disabled_color", DangoTheme.INK_ON_PRIMARY)
	_scan_button.pressed.connect(_on_scan_pressed)
	row.add_child(_scan_button)

	if not available:
		var plate := PanelContainer.new()
		plate.name = "UnavailablePlate"
		var plate_sb := DangoTheme.surface_style(DangoTheme.Surface.PANEL, 11, 3, 0.0, Vector2(13, 11))
		plate_sb.bg_color = DangoTheme.DANGER
		plate.add_theme_stylebox_override("panel", plate_sb)
		col.add_child(plate)
		var plate_row := HBoxContainer.new()
		plate_row.add_theme_constant_override("separation", 10)
		plate.add_child(plate_row)
		var plate_icon := TextureRect.new()
		plate_icon.custom_minimum_size = Vector2(20, 20)
		plate_icon.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		plate_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		plate_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		plate_icon.texture = MockupAssets.tex("assets/fx/blind.png")
		plate_row.add_child(plate_icon)
		var plate_lbl := _body_label(IMPORT_UNAVAILABLE_PREFIX + AxieApi.unavailable_reason())
		plate_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		plate_lbl.add_theme_font_size_override("font_size", 13)
		plate_lbl.add_theme_color_override("font_color", DangoTheme.INK_ON_DANGER)
		plate_row.add_child(plate_lbl)

		# The mockup draws SCAN in its inert state on this screen, because the network layer is
		# what is missing. Match that exactly when the build agrees it is unavailable.
		var scan_inert := DangoTheme.surface_style(DangoTheme.Surface.PANEL_RAISED, 11, 3, 0.0,
			Vector2(-1, -1))
		for state_key in ["normal", "hover", "pressed", "disabled"]:
			_scan_button.add_theme_stylebox_override(state_key, scan_inert)
		_scan_button.add_theme_color_override("font_disabled_color", DangoTheme.FAINT_TEXT)
		_scan_button.add_theme_color_override("font_color", DangoTheme.FAINT_TEXT)

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

	col.add_child(DangoTheme.display_label("RANKED RUN", 13, DangoTheme.MUTED_TEXT, 800,
		0.16))
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


## FIX-PASS-02 §1 item 4: the old `anchor_bottom = 1.0` + hand-computed
## `-(SAFE_AREA + FOOTER_HEIGHT)` offset is exactly the pattern the shell's `fit_or_scroll()`
## replaces — `content` already excludes the footer, so nothing here needs to know its height.
func _build_record_panel() -> void:
	# FIX-PASS-01 V1: was an `HFlowContainer` — measured on the QA capture to lay out as ONE
	# 355px column (each card's own `SIZE_EXPAND_FILL` claims the whole remaining line width
	# before the flow's wrap decision runs, so a second card never fits on the same line no
	# matter how much room is actually free). A `GridContainer` with a fixed column count has no
	# such ambiguity: 3 columns, filling the content region, still scrolling per L2 once the
	# (up to 20) records overflow it vertically.
	_list = GridContainer.new()
	_list.name = "RecordList"
	_list.columns = 3
	_list.add_theme_constant_override("h_separation", 16)
	_list.add_theme_constant_override("v_separation", 16)

	_record_scroll = DangoScreen.fit_or_scroll(_list, _record_max_height())
	_record_scroll.name = "RecordScroll"
	_record_scroll.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_record_scroll.offset_left = RECORD_LEFT
	_record_scroll.offset_right = RECORD_RIGHT
	_record_scroll.offset_top = RECORD_TOP
	_content.add_child(_record_scroll)

	var fade := DangoTheme.scroll_fade(DangoTheme.PANEL)
	fade.name = "RecordScrollFade"
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.visible = false
	fade.anchor_left = 0.0
	fade.anchor_right = 1.0
	fade.anchor_top = 0.0
	fade.anchor_bottom = 0.0
	fade.offset_left = RECORD_LEFT
	fade.offset_right = RECORD_RIGHT
	_content.add_child(fade)
	_record_fade = fade

	_empty_label = _body_label("")
	_empty_label.name = "EmptyLabel"
	_empty_label.add_theme_color_override("font_color", DangoTheme.TEXT_DIM)
	_content.add_child(_empty_label)


func _record_max_height() -> float:
	# The footer is back (see `_ready()`), so the list stops above it. `RECORD_TOP` is already
	# relative to `_content`, whose height is the canvas less the two safe insets AND the footer.
	return get_viewport_rect().size.y - DangoScreen.SAFE * 2.0 - DangoScreen.FOOTER_H - RECORD_TOP


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
	_count_label.text = "%d / %d" % [entries.size(), MetaState.VAULT_MAX]
	_count_label.add_theme_color_override("font_color",
		DangoTheme.DANGER if full else DangoTheme.INK_ON_SHIELD)
	_count_caption.text = "FULL" if full else "IMPORTED"
	_count_caption.add_theme_color_override("font_color",
		DangoTheme.DANGER if full else DangoTheme.INK_ON_SHIELD)
	_empty_label.visible = entries.is_empty()
	# Just the state, not the reason — the reason is already on screen two lines above, under the
	# control it disables, and printing the same sentence twice in a row reads as a bug.
	_empty_label.text = "No Axies imported yet." if entries.is_empty() else ""

	for entry in entries:
		_list.add_child(_build_row(entry))

	# L2 fade: only when the list actually overflows its region — 0-2 records is the common case
	# and does not need one. Deferred because `get_combined_minimum_size()` on the just-populated
	# grid is only accurate once this frame's layout pass has run.
	call_deferred("_update_record_fade")


func _update_record_fade() -> void:
	if _list == null or _record_scroll == null or _record_fade == null:
		return
	var natural := _list.get_combined_minimum_size().y
	var max_h := _record_max_height()
	var overflow := natural > max_h
	_record_fade.visible = overflow
	if overflow:
		var bottom := RECORD_TOP + minf(natural, max_h)
		_record_fade.offset_top = bottom - DangoTheme.SCROLL_FADE_HEIGHT
		_record_fade.offset_bottom = bottom


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

	# A record with no usable gene string must never reach the vault. 20 Sep 2026.
	#
	# The owner reported both saved records rendering a large flat black box reading "No gene
	# data for this Axie." That string is `AxieGenePreview.REASON_EMPTY` — the genes field is an
	# empty string, not corrupt and not undecodable. The import path itself is sound
	# (`axie_api.gd` reads the API's `newGenes` and republishes it as `genes`;
	# `axie_to_die.gd` carries it into the record; `MetaState._vault_entry_from_json()`
	# `duplicate(true)`s before overwriting, so the save round-trip preserves it), which means
	# those two records were written empty in the first place and have been unusable on disk
	# ever since.
	#
	# Nothing stopped that, and that is the actual defect: a vault record's whole purpose is to
	# rebuild the 3D rig from its genes — no image is cached and nothing is re-fetched — so
	# storing one without them produces a permanent dead card that no amount of UI work fixes.
	# Refusing the import is recoverable; a silently broken record is not. Existing broken
	# records are NOT repaired by this guard; they have to be removed and re-imported.
	var genes := str(_pending_axie.get("genes", "")).strip_edges()
	if genes.is_empty():
		_status_label.text = "This Axie came back without gene data — nothing to build a die from."
		_status_label.add_theme_color_override("font_color", DangoTheme.DANGER)
		return

	var res := MetaState.vault_import({
		"id": _pending_axie.get("id", ""),
		"class": _pending_axie.get("class", ""),
		"parts": _pending_axie.get("parts", []),
		"genes": genes,
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
	card.add_theme_stylebox_override("panel",
		DangoTheme.cream_card_style(Color.TRANSPARENT, 17, 5, 7.0))
	DangoTheme.clip_to_frame(card)   # G3

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
	band.custom_minimum_size = Vector2(0, CARD_BAND_H)
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

	var nm := DangoTheme.display_label(str(entry.get("n", "Axie")), 20, DangoTheme.INK,
		800, 0.02)
	nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# V2: the mockup's name group is `min-width:0` with `overflow:hidden; text-overflow:
	# ellipsis`, and the flag chip beside it is `flex:0 0 auto`. In Godot a Label's minimum
	# width is its WHOLE text unless an overrun behaviour is set, so a long Axie name made the
	# header row wider than the card and pushed the chip straight through the band's 14px
	# right padding — which is exactly what the review measured on the second card. Trimming
	# to an ellipsis collapses that minimum to 1px, so the name yields and the chip cannot.
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	band_row.add_child(nm)

	var flag_text := "RE-SCAN NEEDED" if stale_card else "READY"
	var flag_bg := DangoTheme.WARN_YELLOW if stale_card else DangoTheme.SUCCESS
	var flag := PanelContainer.new()
	# `height:24` + `border:2` = 28 outer, `padding:0 9px`, and it never shrinks or grows.
	flag.custom_minimum_size = Vector2(0, CARD_FLAG_H)
	flag.size_flags_horizontal = Control.SIZE_SHRINK_END
	flag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	flag.add_theme_stylebox_override("panel", DangoTheme.solid_chip_style(flag_bg, 7, 2, Vector2(9, 2)))
	var flag_lbl := DangoTheme.display_label(flag_text, 12, DangoTheme.INK, 800, 0.08)
	flag_lbl.add_theme_constant_override("line_spacing", 0)
	flag.add_child(flag_lbl)
	band_row.add_child(flag)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 16)
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
	preview_box.custom_minimum_size = Vector2(0, PREVIEW_BOX_H)
	preview_box.add_theme_stylebox_override("panel",
		DangoTheme.surface_style(DangoTheme.Surface.CREAM_RAISED, 14, 3, 0.0, Vector2(-1, -1)))
	preview_box.clip_contents = true
	info.add_child(preview_box)

	# FIX-PASS-01 V3: the "AxieCharacter3D · FROM GENES" caption is gone — a developer-facing
	# class name has no reason to be on a player-facing screen, and it was also under the L8 type
	# floor at 11px. `AxiePreview3D`'s own empty-state styling (WELL fill + one centred 15px line)
	# now carries the "nothing to show yet" case; a populated preview needs no caption at all.
	#
	# The 3D preview, rebuilt from the genes stored with the record. This is why the record keeps
	# `genes` at all — no image is cached, and nothing is fetched.
	var preview := (load(PREVIEW_SCENE) as PackedScene).instantiate() as AxiePreview3D
	preview.name = "Preview"
	preview.set_anchors_preset(Control.PRESET_FULL_RECT)
	preview_box.add_child(preview)
	preview.set_genes(str(entry.get("genes", "")))

	var die_caption := DangoTheme.display_label("DIE FROM ITS SIX REAL PARTS", 12,
		DangoTheme.INK_ON_CREAM_MUTED, 800, 0.14)
	info.add_child(die_caption)
	info.add_child(_build_die_strip(entry.get("die", []), cls))

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
	remove.custom_minimum_size = Vector2(0, REMOVE_BTN_H)
	remove.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	remove.add_theme_font_size_override("font_size", 16)
	DangoTheme.apply_tracking(remove, 0.08, 16)
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
## `cls` is the Axie's class, needed for the per-slot part icon the mockup puts in every face
## cell (`assets/part/<slot>-<class>.svg`). Empty means "no class to draw an icon from" — the
## import preview builds its strip before a class is committed — and the icon is left out rather
## than drawn as a hole.
func _build_die_strip(die: Array, cls: String = "") -> GridContainer:
	var grid := GridContainer.new()
	grid.name = "DieStrip"
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for f in die:
		var face: Dictionary = f
		var value := int(face.get("v", 0))
		var ftype := str(face.get("t", "blank"))

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

		var slot := str(face.get("p", ""))
		if not cls.is_empty() and not slot.is_empty() and slot != "blank":
			var part_icon := TextureRect.new()
			part_icon.custom_minimum_size = Vector2(21, 21)
			part_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			part_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			part_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			part_icon.texture = MockupAssets.part_icon(slot, cls)
			row.add_child(part_icon)

		var value_lbl := DangoTheme.display_label(
			"—" if ftype == "blank" else str(value), 22, DangoTheme.INK)
		row.add_child(value_lbl)
		# VLT-05 / G-01: 21+2*2 swatch holding its 13px type glyph. Was a bare 17px colour block —
		# the exact "colour standing alone for a mechanic" G-01 removes. Shared builder.
		# `width:21;height:21` + `border:2` = 25 outer, holding its 13px type glyph.
		row.add_child(DangoTheme.type_swatch(ftype, 25, 13, 6, 2))

		# Mockup caption is "SLOT · TYPE" at `font-size:10px;letter-spacing:.05em`.
		# RESTORED 2026-09-20: it was held at 12 by the old project type floor, which the
		# project owner has removed in favour of the mockups (godot/CLAUDE.md rule 5).
		var caption_text := ftype.to_upper()
		if not slot.is_empty() and slot != "blank":
			caption_text = "%s · %s" % [slot.to_upper(), ftype.to_upper()]
		var caption := DangoTheme.display_label(
			caption_text, 10, DangoTheme.INK_ON_CREAM_MUTED, 800, 0.05)
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
