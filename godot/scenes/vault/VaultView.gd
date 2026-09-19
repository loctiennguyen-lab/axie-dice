extends Control
## The Vault screen — imported Axie NFTs, their derived dice, and the 3D preview built from each
## one's genes. Port of `scVaultHub()`'s VAULT tab (src/client.html:3311-3420).
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

## Shown under the ID field when importing cannot work on this build at all. The concrete reason
## comes from `AxieApi.unavailable_reason()`; this is the lead-in sentence.
const IMPORT_UNAVAILABLE_PREFIX := "Import is unavailable on this build. "

## Three regions, not one scrolling column.
##
## Everything used to live inside a single ScrollContainer. With up to twenty rows that pushed
## two things off screen exactly when they were needed most: the sentence explaining why SCAN is
## disabled (which the RE-SCAN line on row 18 depends on), and the BACK button — the only way out
## of the screen, which got further away the more Axies you owned.
@onready var _header: VBoxContainer = %HeaderRoot
@onready var _content: VBoxContainer = %ContentRoot
@onready var _footer: VBoxContainer = %FooterRoot

var _count_label: Label
var _list: VBoxContainer
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
	_api = AxieApi.new()
	_api.name = "AxieApi"
	_api.completed.connect(_on_fetch_completed)
	add_child(_api)

	_build_header()
	_build_import_row()
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 10)
	_content.add_child(_list)
	_empty_label = _body_label("")
	_content.add_child(_empty_label)
	_build_back_button()
	refresh()


## Rebuilds the list from `MetaState.vault`. Public so a test can drive it after changing the
## store, and called after every mutation — the vault is at most twenty rows, so re-rendering all
## of it is cheaper to reason about than patching rows in place.
func refresh() -> void:
	for child in _list.get_children():
		child.queue_free()
		_list.remove_child(child)

	var entries := MetaState.vault
	# The word "FULL", not only the colour. Colour alone is the single signal a colour-blind
	# player does not get — and once the network layer lands this is the only thing telling
	# someone why their next import was refused.
	var full := MetaState.vault_is_full()
	_count_label.text = "%d / %d imported%s" % [
		entries.size(), MetaState.VAULT_MAX, "  ·  FULL" if full else ""]
	_count_label.add_theme_color_override("font_color",
		DangoTheme.DANGER if full else DangoTheme.PRIMARY)
	_empty_label.visible = entries.is_empty()
	# Just the state, not the reason — the reason is already on screen two lines above, under the
	# control it disables, and printing the same sentence twice in a row reads as a bug.
	_empty_label.text = "No Axies imported yet." if entries.is_empty() else ""

	for entry in entries:
		_list.add_child(_build_row(entry))


func _build_header() -> void:
	var title := Label.new()
	title.text = "VAULT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", DangoTheme.TEXT)
	_header.add_child(title)

	var sub := _body_label("Real Axie NFTs, converted to dice. Imports stay at form tier 1 and "
		+ "are not eligible for a Ranked Run.")
	sub.add_theme_color_override("font_color", DangoTheme.TEXT_DIM)
	_header.add_child(sub)

	_count_label = _body_label("")
	_count_label.add_theme_font_size_override("font_size", 18)
	_header.add_child(_count_label)


func _build_import_row() -> void:
	var available := AxieApi.is_available()

	var box := PanelContainer.new()
	box.name = "ImportRow"
	box.add_theme_stylebox_override("panel", DangoTheme.panel_style())
	if not available:
		# Dimmed as a whole. Godot's disabled styling only greys the text INSIDE the field, so the
		# box would keep the same border and fill as the live Axie cards below it and read as a
		# working search bar to anyone who did not stop to read the sentence underneath.
		box.modulate = Color(1, 1, 1, 0.45)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	margin.add_child(row)
	box.add_child(margin)

	_id_field = LineEdit.new()
	_id_field.name = "AxieIdField"
	_id_field.placeholder_text = "Axie ID  (e.g. 123)"
	_id_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_id_field.editable = available
	# Enter submits. Typing an ID and pressing Return is what everyone tries first, and a field
	# that ignores it feels broken even though the button beside it works.
	_id_field.text_submitted.connect(func(_t: String) -> void: _on_scan_pressed())
	_id_field.text_changed.connect(func(_t: String) -> void: _refresh_scan_enabled())
	row.add_child(_id_field)

	_scan_button = Button.new()
	_scan_button.name = "ScanButton"
	_scan_button.text = "SCAN"
	_scan_button.custom_minimum_size = Vector2(110, 0)
	DangoTheme.style_button(_scan_button, true)
	_scan_button.pressed.connect(_on_scan_pressed)
	row.add_child(_scan_button)

	_header.add_child(box)

	_status_label = _body_label("")
	_status_label.name = "ImportStatus"
	_status_label.add_theme_color_override("font_color", DangoTheme.TEXT_DIM)
	_header.add_child(_status_label)

	_preview_box = PanelContainer.new()
	_preview_box.name = "ImportPreview"
	_preview_box.add_theme_stylebox_override("panel",
		DangoTheme.panel_style(DangoTheme.BG_PANEL, 2, 8, 6.0, DangoTheme.PRIMARY))
	_preview_box.visible = false
	_header.add_child(_preview_box)

	if not available:
		# The reason, on screen, next to the thing it disables — not in a tooltip the player has
		# to find by hovering a control that looks broken.
		_status_label.text = IMPORT_UNAVAILABLE_PREFIX + AxieApi.unavailable_reason()
		_status_label.add_theme_color_override("font_color", DangoTheme.DANGER)
	_refresh_scan_enabled()


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
	_status_label.add_theme_color_override("font_color", DangoTheme.TEXT_DIM)
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

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	_preview_box.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)

	var preview := (load(PREVIEW_SCENE) as PackedScene).instantiate() as AxiePreview3D
	preview.name = "Preview"
	preview.custom_minimum_size = Vector2(150, 150)
	row.add_child(preview)
	preview.set_genes(str(axie.get("genes", "")))

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)
	row.add_child(info)

	var die := AxieToDie.build({
		"id": axie.get("id", ""), "class": axie.get("class", ""), "parts": axie.get("parts", []),
	})
	var title := Label.new()
	title.text = str(die.get("n", "Axie"))
	title.add_theme_font_size_override("font_size", 19)
	title.add_theme_color_override("font_color", DangoTheme.TEXT)
	info.add_child(title)

	var secret := _optional_string(die.get("secret_cls"))
	var shown := secret if not secret.is_empty() else str(die.get("cls", ""))
	var stats := _body_label("%s  ·  HP %d  ·  purity %d/6  ·  gene tier %d" % [
		shown.to_upper(), int(die.get("max_hp", 0)), int(die.get("purity", 0)),
		int(die.get("gene_tier", 0))])
	stats.add_theme_color_override("font_color", DangoTheme.TEXT_DIM)
	info.add_child(stats)
	info.add_child(_build_die_strip(die.get("die", [])))

	# The part names the die was actually derived from. Without them "2 dmg" is a number with no
	# provenance, and a player comparing two Axies has nothing to compare.
	var part_names := PackedStringArray()
	for pt in axie.get("parts", []):
		part_names.append("%s: %s" % [str((pt as Dictionary).get("type", "?")),
			str((pt as Dictionary).get("name", "?"))])
	var parts_lbl := _body_label(", ".join(part_names))
	parts_lbl.add_theme_font_size_override("font_size", 12)
	parts_lbl.add_theme_color_override("font_color", DangoTheme.TEXT_DIM)
	info.add_child(parts_lbl)

	var already := MetaState.vault_index_of(str(axie.get("id", ""))) >= 0
	var full := MetaState.vault_is_full()
	var add := Button.new()
	add.name = "AddButton"
	add.custom_minimum_size = Vector2(0, 40)
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
	# A stale record gets a DANGER border, not just red text inside an identical card. Scrolling
	# a twenty-row list, a small red sentence is easy to pass; a differently-framed card is not.
	var stale_card := MetaState.vault_stale(entry)
	card.add_theme_stylebox_override("panel",
		DangoTheme.panel_style(DangoTheme.BG_PANEL, 2, 8, 6.0, DangoTheme.DANGER) if stale_card
		else DangoTheme.panel_style())

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	card.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)

	# The 3D preview, rebuilt from the genes stored with the record. This is why the record keeps
	# `genes` at all — no image is cached, and nothing is fetched.
	var preview := (load(PREVIEW_SCENE) as PackedScene).instantiate() as AxiePreview3D
	preview.name = "Preview"
	preview.custom_minimum_size = Vector2(150, 150)
	row.add_child(preview)
	preview.set_genes(str(entry.get("genes", "")))

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)
	row.add_child(info)

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 6)
	info.add_child(name_row)
	var nm := Label.new()
	nm.text = str(entry.get("n", "Axie"))
	nm.add_theme_font_size_override("font_size", 19)
	nm.add_theme_color_override("font_color", DangoTheme.TEXT)
	name_row.add_child(nm)

	# A secret class is mapped to a real class for its passive; saying only the mapped one would
	# hide the thing that makes the Axie unusual, and saying only the secret one would leave the
	# player wondering which passive they actually get.
	#
	# `secret_cls` is NULL, not "", on an ordinary Axie — `AxieToDie` mirrors the JS `secretCls:
	# null` there and `t_axie_to_die` pins it, so the fix belongs here and not in the converter.
	# `str(null)` is the string "<NULL>", which is not empty: the first version of this line
	# printed "<NULL>" as the class name and lit the ◈ SECRET badge on every single Axie. Caught
	# by looking at the screenshot; no assertion in `t_vault` was looking at label text.
	var secret := _optional_string(entry.get("secret_cls"))
	var shown_class := secret if not secret.is_empty() else str(entry.get("cls", ""))
	var cls_lbl := Label.new()
	cls_lbl.text = shown_class.to_upper()
	cls_lbl.add_theme_font_size_override("font_size", 14)
	cls_lbl.add_theme_color_override("font_color", DangoTheme.PRIMARY)
	name_row.add_child(cls_lbl)
	if not secret.is_empty():
		var badge := Label.new()
		badge.name = "SecretBadge"
		badge.text = "◈ SECRET · plays as %s" % str(entry.get("cls", "")).to_upper()
		badge.add_theme_font_size_override("font_size", 12)
		badge.add_theme_color_override("font_color", DangoTheme.MANA_PURPLE)
		name_row.add_child(badge)

	var stats := _body_label("HP %d  ·  purity %d/6  ·  gene tier %d" % [
		int(entry.get("max_hp", 0)), int(entry.get("purity", 0)), int(entry.get("gene_tier", 0))])
	stats.add_theme_color_override("font_color", DangoTheme.TEXT_DIM)
	info.add_child(stats)

	info.add_child(_build_die_strip(entry.get("die", [])))

	if MetaState.vault_stale(entry):
		var stale := Label.new()
		stale.name = "StaleBadge"
		stale.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		# The instruction has to carry its own caveat. "RE-SCAN NEEDED" in DANGER red reads as an
		# action to take right now — but re-scanning needs the network layer, which is not in this
		# build, and the explanation for that lives at the top of a list that can be twenty rows
		# long. A player scrolled to row 18 would see an urgent red order they cannot obey and no
		# reason why. So the line names the one thing they CAN do, right where they read it.
		stale.text = ("RE-SCAN NEEDED — this die was built under older rules and cannot be"
			+ " played. Re-scanning needs the network layer, which is not in this build yet;"
			+ " REMOVE is the only action available for now.")
		stale.add_theme_font_size_override("font_size", 13)
		stale.add_theme_color_override("font_color", DangoTheme.DANGER)
		info.add_child(stale)

	var remove := Button.new()
	remove.name = "RemoveButton"
	remove.text = "REMOVE"
	# Without this the button stretches to the row's full height and reads as a tall empty panel
	# with a word in it, rather than as a button.
	remove.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	remove.custom_minimum_size = Vector2(110, 40)
	DangoTheme.style_button(remove, false)
	remove.pressed.connect(_on_remove_pressed.bind(str(entry.get("axie_id", ""))))
	row.add_child(remove)
	return card


## The six faces, as value + type, in slot order. Deliberately the same numbers the die card in
## combat shows: a player comparing an import against a starter hero is comparing these.
func _build_die_strip(die: Array) -> HBoxContainer:
	var strip := HBoxContainer.new()
	strip.name = "DieStrip"
	strip.add_theme_constant_override("separation", 4)
	for f in die:
		var face: Dictionary = f
		var chip := Label.new()
		var value := int(face.get("v", 0))
		var ftype := str(face.get("t", "blank"))
		chip.text = ("—" if ftype == "blank" else "%d %s" % [value, ftype])
		chip.add_theme_font_size_override("font_size", 12)
		chip.add_theme_color_override("font_color", DangoTheme.die_type_color(ftype))
		var box := PanelContainer.new()
		box.add_theme_stylebox_override("panel",
			DangoTheme.kw_chip_style(DangoTheme.die_type_color(ftype)))
		box.add_child(chip)
		strip.add_child(box)
	return strip


func _on_remove_pressed(axie_id: String) -> void:
	MetaState.vault_remove(axie_id)
	refresh()


func _build_back_button() -> void:
	var back := Button.new()
	back.name = "BackButton"
	back.text = "BACK"
	back.custom_minimum_size = Vector2(0, 44)
	DangoTheme.style_button(back, false)
	back.pressed.connect(func() -> void:
		get_tree().change_scene_to_file(MAIN_MENU_SCENE))
	_footer.add_child(back)


## "" for a missing or null value, instead of GDScript's "<NULL>". Records carry real nulls
## wherever the JS carries them, so every optional field read into a Label has to come through
## here — the alternative is a UI rule violation that only a screenshot finds.
static func _optional_string(value: Variant) -> String:
	return "" if value == null else str(value)


func _body_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_color", DangoTheme.TEXT)
	return lbl
