class_name VaultView
extends Control
## The Vault (UI-03 round-2 screen 25, on UI3Meta): imported Axie NFTs, their derived dice and the 3D preview
## built from each one's genes. Left = collection grid (record cards), right = 440 plate with the import
## (Axie ID + Scan), status, local-only note and the import preview. Guests may browse and import into the local
## Vault; offline only blocks Scan. All MetaState / AxieApi logic is unchanged from the Dango version.
## Node names tests look up by are kept: Row_<id>, Preview, DieStrip, AxieIdField, ScanButton, ImportStatus,
## RemoveButton, StaleBadge, SecretBadge, RemoveConfirm, KeepButton, ConfirmRemoveButton, AddButton.
## USE IN TEAM puts the Axie in the first slot that is not already a Vault pick and opens Run Setup.
## Import shells out to curl (AxieApi); a web export cannot, so the field is disabled with the reason shown.

const PREVIEW_SCENE := "res://scenes/shared/AxiePreview3D.tscn"
const MAIN_MENU_SCENE := "res://scenes/main_menu/MainMenu.tscn"
## Shown under the ID field when importing cannot work on this build at all.
const IMPORT_UNAVAILABLE_PREFIX := "Import is unavailable on this build. "
const DETAIL_W := 440
const COLS := 3
const PREVIEW_H := 260

var _list: GridContainer
var _record_scroll: ScrollContainer
var _count_label: Label
var _count_caption: Label
var _empty_label: Label
var _api: AxieApi
var _id_field: LineEdit
var _scan_button: Button
var _status_label: Label
var _preview_box: PanelContainer
var _pending_axie: Dictionary = {}
var state := "normal"
var use_account := true
var remote_on: bool = String(ProjectSettings.get_setting("axie/gem_wallet", "")) == "remote"
var account_status_hook: Callable
var no_scene_change := false
var _first_refresh := true
var _shell: Dictionary
var _modal_layer: Control
var _right: VBoxContainer
var _body: HBoxContainer


func _ready() -> void:
	_shell = UI3Meta.build(self, "Vault", "Own Axies and look up any Axie", _on_back)
	(_shell["panel"] as Control).name = "PlateHost"   # t_ui_laws L0
	_modal_layer = _shell["modal_layer"]
	if use_account:
		state = derive_state()
	_build_notice()
	_body = HBoxContainer.new()
	_body.name = "Body"
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", UI3Meta.GAP)
	(_shell["col"] as VBoxContainer).add_child(_body)
	_build_record_panel()
	_build_import_panel()
	refresh()


func _unhandled_key_input(ev: InputEvent) -> void:
	if UI3Meta.esc_back(ev, _shell, _on_back):
		if is_inside_tree():   # a handler above may have changed scene
			get_viewport().set_input_as_handled()


func derive_state() -> String:
	var st: int = account_status_hook.call() if account_status_hook.is_valid() else AccountService.status
	match st:
		AccountService.Status.GUEST, AccountService.Status.EXPIRED:
			return "guest"
		AccountService.Status.OFFLINE:
			return "offline"
	return "normal"


func _on_back() -> void:
	if is_inside_tree() and not no_scene_change:
		LandNav.back_to_land()


func _build_notice() -> void:
	var host: VBoxContainer = _shell["banner_host"]
	if state == "offline":
		UI3Meta.banner(host, "Offline: scanning needs a connection",
			"Your collection is kept on this device.")
	elif state == "guest" and remote_on:
		UI3Meta.banner(host, "Sign in to keep your Vault",
			"Your Vault is stored on this device. Sign in to keep it across devices.")


func _build_record_panel() -> void:
	var left := VBoxContainer.new()
	left.name = "Content"
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", UI3Theme.space("16"))
	_body.add_child(left)
	var head := UI3.plate(&"plate")
	head.name = "ImportCountChip"
	var hr := HBoxContainer.new()
	hr.add_theme_constant_override("separation", UI3Theme.space("16"))
	head.add_child(hr)
	var ht := UI3.label("Your Axies", "LabelTitle")
	ht.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hr.add_child(ht)
	_count_label = UI3.label("", "LabelScreenTitle")
	hr.add_child(_count_label)
	_count_caption = UI3.label("IMPORTED", "LabelMuted")
	_count_caption.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hr.add_child(_count_caption)
	left.add_child(head)
	_list = GridContainer.new()
	_list.name = "RecordList"
	_list.columns = COLS
	_list.add_theme_constant_override("h_separation", UI3Theme.space("16"))
	_list.add_theme_constant_override("v_separation", UI3Theme.space("16"))
	_record_scroll = UI3Meta.scroll(_list)
	_record_scroll.name = "RecordScroll"
	left.add_child(_record_scroll)
	_empty_label = UI3.label("", "LabelMuted")
	_empty_label.name = "EmptyLabel"
	_empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_empty_label.size_flags_vertical = Control.SIZE_EXPAND_FILL   # centred in the empty area
	left.add_child(_empty_label)


func _build_import_panel() -> void:
	var panel := UI3.plate(&"plate")
	panel.name = "ImportPanel"
	panel.custom_minimum_size = Vector2(DETAIL_W, 0)
	_body.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UI3Theme.space("16"))
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# Right margin = scrollbar width + gap so the Scan button is never under the scrollbar.
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_right", UI3Theme.SCROLL_W + UI3Theme.space("8"))
	pad.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pad.add_child(col)
	panel.add_child(UI3Meta.scroll(pad))   # a taller import preview scrolls, never clips
	_right = col
	var available := AxieApi.is_available()
	col.add_child(UI3.label("Import by Axie ID", "LabelScreenTitle"))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI3Theme.space("8"))
	col.add_child(row)
	_id_field = LineEdit.new()
	_id_field.theme = UI3Theme.get_theme()
	_id_field.name = "AxieIdField"
	_id_field.placeholder_text = "e.g. 11778888"
	_id_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_id_field.custom_minimum_size = Vector2(0, 56)
	_id_field.editable = available
	_id_field.text_submitted.connect(func(_t: String) -> void: _on_scan_pressed())
	_id_field.text_changed.connect(func(_t: String) -> void: _refresh_scan_enabled())
	row.add_child(_id_field)
	_scan_button = UI3.button("Scan", &"primary", &"M")
	_scan_button.name = "ScanButton"
	_scan_button.pressed.connect(_on_scan_pressed)
	row.add_child(_scan_button)
	if not available:
		var plate := UI3.plate(&"notice")
		plate.name = "UnavailablePlate"
		var pl := UI3.label(IMPORT_UNAVAILABLE_PREFIX + AxieApi.unavailable_reason())
		pl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		plate.add_child(pl)
		col.add_child(plate)
	_status_label = UI3.label("", "LabelMuted")
	_status_label.name = "ImportStatus"
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if not available:
		_status_label.text = IMPORT_UNAVAILABLE_PREFIX + AxieApi.unavailable_reason()
		_status_label.add_theme_color_override("font_color", UI3Theme.color("danger_text"))
	col.add_child(_status_label)
	_preview_box = UI3.plate(&"card")
	_preview_box.name = "ImportPreview"
	_preview_box.visible = false
	col.add_child(_preview_box)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(sp)
	var local := UI3.label("Your Vault is kept on this device. Imported Axies are blocked in Ranked: every submission plays the same baseline die.", "LabelMuted")
	local.name = "LocalNote"
	local.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(local)
	_refresh_scan_enabled()


func _set_status(text: String, kind := "muted") -> void:
	_status_label.text = text
	match kind:
		"error": _status_label.add_theme_color_override("font_color", UI3Theme.color("danger_text"))
		"ok": _status_label.add_theme_color_override("font_color", UI3Theme.color("success_text"))
		_: _status_label.add_theme_color_override("font_color", UI3Theme.color("text_muted"))


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
	var full := MetaState.vault_is_full()
	_count_label.text = "%d / %d" % [entries.size(), MetaState.VAULT_MAX]
	_count_label.add_theme_color_override("font_color", UI3Theme.color("danger_text") if full else UI3Theme.color("text"))
	_count_caption.text = "FULL" if full else "IMPORTED"   # the word, not only the colour
	_record_scroll.modulate.a = 0.62 if state == "offline" else 1.0   # greyed but readable
	_empty_label.visible = entries.is_empty()
	_record_scroll.visible = not entries.is_empty()
	_empty_label.text = "Your Vault is empty. Type an Axie ID on the right and press Scan." if entries.is_empty() else ""
	if _first_refresh and entries.is_empty() and _id_field != null and _id_field.editable and is_inside_tree():
		_id_field.grab_focus()   # the empty state focuses the ID field
	_first_refresh = false
	for entry in entries:
		_list.add_child(_build_row(entry))


## SCAN is enabled only for something that could actually be an Axie ID.
func _refresh_scan_enabled() -> void:
	if _scan_button == null:
		return
	var busy := not _status_label.text.is_empty() and _status_label.text.begins_with("Looking up")
	# One primary at a time: once a looked-up Axie waits to be added, "Add to Vault" is it.
	_scan_button.theme_type_variation = "ButtonSecondary" if not _pending_axie.is_empty() else "ButtonPrimaryM"
	_scan_button.disabled = (not AxieApi.is_available()) or busy or state == "offline" \
		or not AxieApi.is_valid_axie_id(_id_field.text)


func _on_scan_pressed() -> void:
	if not AxieApi.is_available() or not AxieApi.is_valid_axie_id(_id_field.text):
		return
	_preview_box.visible = false
	_pending_axie = {}
	_set_status("Looking up Axie #%s…" % _id_field.text.strip_edges())
	_refresh_scan_enabled()
	_api.request_axie(_id_field.text)


func _on_fetch_completed(result: Dictionary) -> void:
	if not bool(result.get("ok", false)):
		_set_status(str(result.get("message", "Could not fetch that Axie.")), "error")
		_pending_axie = {}
		_preview_box.visible = false
		_refresh_scan_enabled()
		return
	_pending_axie = result["axie"]
	_set_status("")
	_build_import_preview(_pending_axie)
	_refresh_scan_enabled()


## Shows what WOULD be stored, before it is stored.
func _build_import_preview(axie: Dictionary) -> void:
	UI3Meta.clear(_preview_box)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI3Theme.space("8"))
	_preview_box.add_child(v)
	var preview := (load(PREVIEW_SCENE) as PackedScene).instantiate() as AxiePreview3D
	preview.name = "Preview"
	preview.custom_minimum_size = Vector2(220, 220)
	var square := AspectRatioContainer.new()
	square.ratio = 1.0
	square.custom_minimum_size = Vector2(0, 220)
	square.add_child(preview)
	v.add_child(square)
	preview.set_genes(str(axie.get("genes", "")))
	var die := AxieToDie.build({
		"id": axie.get("id", ""), "class": axie.get("class", ""), "parts": axie.get("parts", []),
	})
	v.add_child(UI3.label(str(die.get("n", "Axie")), "LabelTitle"))
	var secret := _optional_string(die.get("secret_cls"))
	var shown := secret if not secret.is_empty() else str(die.get("cls", ""))
	var stats := UI3.label("%s · HP %d · purity %d/6 · gene tier %d" % [
		shown.to_upper(), int(die.get("max_hp", 0)), int(die.get("purity", 0)),
		int(die.get("gene_tier", 0))], "LabelMuted")
	stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(stats)
	v.add_child(_build_die_strip(die.get("die", [])))
	var part_names := PackedStringArray()
	for pt in axie.get("parts", []):
		part_names.append("%s: %s" % [str((pt as Dictionary).get("type", "?")),
			str((pt as Dictionary).get("name", "?"))])
	var parts_lbl := UI3.label(", ".join(part_names), "LabelMuted")
	parts_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(parts_lbl)
	var already := MetaState.vault_index_of(str(axie.get("id", ""))) >= 0
	var full := MetaState.vault_is_full()
	var add := UI3.button("Update Vault entry" if already else "Add to Vault", &"primary", &"M")
	add.name = "AddButton"
	if full and not already:
		UI3.set_disabled_reason(add, "Vault full (%d/%d)" % [MetaState.vault.size(), MetaState.VAULT_MAX])
	add.pressed.connect(_on_add_pressed)
	v.add_child(add)
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
		_status_label.text = "This Axie came back without gene data, so there is nothing to build a die from."
		_status_label.add_theme_color_override("font_color", UI3Theme.color("danger_text"))
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
		_status_label.add_theme_color_override("font_color", UI3Theme.color("danger_text"))
		return
	_status_label.text = "%s %s." % [
		"Updated" if bool(res.get("updated", false)) else "Added",
		str(_pending_axie.get("id", ""))]
	_status_label.add_theme_color_override("font_color", UI3Theme.color("success_text"))
	_pending_axie = {}
	_preview_box.visible = false
	_id_field.text = ""
	_refresh_scan_enabled()
	refresh()


func _build_row(entry: Dictionary) -> PanelContainer:
	var card := UI3.plate(&"card")
	card.name = "Row_" + str(entry.get("axie_id", ""))
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", UI3Theme.space("8"))
	card.add_child(info)
	var stale_card := MetaState.vault_stale(entry)
	var cls := str(entry.get("cls", ""))
	var secret := _optional_string(entry.get("secret_cls"))
	var shown_class := secret if not secret.is_empty() else cls
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UI3Theme.space("8"))
	var nm := UI3.label(str(entry.get("n", "Axie")), "LabelTitle")
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	head.add_child(nm)
	head.add_child(UI3Meta.tag("Re-scan needed" if stale_card else "Ready"))
	info.add_child(head)
	info.add_child(UI3.label(" · ".join(["Axie #%s" % str(entry.get("axie_id", "")), shown_class.to_upper(),
		"%d HP" % int(entry.get("max_hp", 0))]), "LabelMuted"))
	if not secret.is_empty():
		var badge := UI3.label("◈ Secret · plays as %s" % cls.to_upper())
		badge.name = "SecretBadge"
		info.add_child(badge)
	var preview := (load(PREVIEW_SCENE) as PackedScene).instantiate() as AxiePreview3D
	preview.name = "Preview"
	preview.custom_minimum_size = Vector2(PREVIEW_H, PREVIEW_H)   # square, never under 160 (spec 25)
	preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var square := AspectRatioContainer.new()
	square.name = "PreviewSquare"
	square.ratio = 1.0
	square.custom_minimum_size = Vector2(0, PREVIEW_H)
	square.size_flags_vertical = Control.SIZE_EXPAND_FILL
	square.add_child(preview)
	info.add_child(square)
	preview.set_genes(str(entry.get("genes", "")))
	info.add_child(_build_die_strip(entry.get("die", []), cls))
	if stale_card:
		var stale := UI3.label("This die was built under older rules and cannot be played. Re-scanning needs a connection; Remove is the only action for now.")
		stale.name = "StaleBadge"
		stale.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		stale.add_theme_color_override("font_color", UI3Theme.color("danger_text"))
		info.add_child(stale)
	var actions := HBoxContainer.new()
	actions.name = "ActionRow"
	actions.add_theme_constant_override("separation", UI3Theme.space("8"))
	info.add_child(actions)
	var use_btn := UI3.button("Use in team", &"secondary", &"M")
	use_btn.name = "UseInTeamButton"
	use_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if stale_card:
		UI3.set_disabled_reason(use_btn, "Re-import first")
	use_btn.tooltip_text = ("Re-import this Axie before using it. Its die was built under older rules."
		if stale_card else "Puts this Axie in your team and opens Run Setup.")
	use_btn.pressed.connect(_on_use_in_team_pressed.bind(str(entry.get("axie_id", ""))))
	actions.add_child(use_btn)
	var remove := UI3.button("Remove", &"secondary", &"M")
	remove.name = "RemoveButton"
	remove.pressed.connect(_on_remove_pressed.bind(str(entry.get("axie_id", ""))))
	actions.add_child(remove)
	return card


func _build_die_strip(die: Array, _cls := "") -> GridContainer:
	var grid := GridContainer.new()
	grid.name = "DieStrip"
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", UI3Theme.space("8"))
	grid.add_theme_constant_override("v_separation", UI3Theme.space("8"))
	for f in die:
		var face: Dictionary = f
		var ft := StringName(str(face.get("t", "blank")))
		if not UI3.FACE_TYPES.has(ft):
			ft = &"blank"
		var tile := UI3.die_tile(ft, int(face.get("v", 0)), &"axie")
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(tile)
	return grid


func _on_use_in_team_pressed(axie_id: String) -> void:
	var key := MetaState.VAULT_KEY_PREFIX + axie_id
	if not ContentDB.heroes.has(key):
		MetaState.ensure_vault_heroes()
	if not ContentDB.heroes.has(key):
		push_warning("VaultView: no hero registered for %s; not handing it to Team Select" % key)
		return

	var team: Array[String] = MainMenu.pending_team.duplicate()
	if team.size() != MainMenu.TEAM_SIZE:
		team = MainMenu.DEFAULT_TEAM.duplicate()
	if not team.has(key):
		var slot := MainMenu.TEAM_SIZE - 1
		for i in MainMenu.TEAM_SIZE:
			if not MetaState.is_vault_key(team[i]):
				slot = i
				break
		team[slot] = key
	MainMenu.pending_team = team
	# Team building lives in Run Setup now; it seeds its party from MainMenu.pending_team.
	if not no_scene_change:
		LandNav.open(&"run_setup")


## M3d: Remove asks first. Focus lands on "Keep it" so a stray Enter never deletes.
func _on_remove_pressed(axie_id: String) -> void:
	_close_confirm()
	var keep := UI3.button("Keep it", &"secondary", &"M")
	keep.name = "KeepButton"
	keep.pressed.connect(_close_confirm)
	var yes := UI3.button("Remove", &"danger", &"M")
	yes.name = "ConfirmRemoveButton"
	yes.pressed.connect(func() -> void:
		MetaState.vault_remove(axie_id)
		_close_confirm()
		refresh())
	var m := UI3.modal("Remove from Vault?", "Axie #%s leaves your Vault. You can import it again later." % axie_id, [keep, yes], 0)
	m.name = "RemoveConfirm"
	m.cancelled.connect(_close_confirm)
	_modal_layer.add_child(m)


func _close_confirm() -> void:
	if _modal_layer == null:
		return
	for c in _modal_layer.get_children():
		_modal_layer.remove_child(c)
		c.queue_free()


static func _optional_string(value: Variant) -> String:
	return "" if value == null else str(value)
