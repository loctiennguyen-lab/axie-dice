class_name StatusHeads
extends Control
## Status icons above the head of every Axie, enemy and boss (UI-03 round 2, screens/02-combat/spec.md:
## "status chip centred above each Axie head": icon 22 + Rowdies 20 count, wood-2, radius 8).
## One chip row per unit. CombatView calls sync() every frame with the head point it got from
## CombatStage3D.get_unit_screen_pos(); a unit with no point (dead, hidden, behind the camera) or with
## `hidden` set (victory march) gets its row hidden at once, so nothing is left floating.
## The head point is decided in ONE place, CombatView._status_head_anchor(); move units around and only
## that function changes.
##
## Icons: assets/icons/web (UnitPortrait._STATUS_ICON). `enrage` uses enrage.png (the angry red spiky ball
## from the Atia icon set, outlined to match). A status with no icon falls back to the 3-letter label chip.

signal unit_clicked(uid: int)
signal unit_inspect(uid: int)

const MAX_SHOWN := 4
const GAP := 8.0
const _SHIELD_ICON := preload("res://assets/icons/web/shield.png")
const _BUFFS := ["shield", "regen", "thorns", "undying", "enrage"]

var _rows: Dictionary = {}   # uid -> {"row": HBoxContainer, "sig": String}


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


## entries: Array of {uid:int, anchor:Vector2 (CombatView coords; x < 0 = no point), hidden:bool, shield:int,
## status:Dictionary, frozen:bool (opt)}. Units missing from `entries` are dropped.
func sync(entries: Array) -> void:
	var seen := {}
	for e in entries:
		var uid := int(e["uid"])
		seen[uid] = true
		var items := items_for(int(e.get("shield", 0)), e.get("status", {}), bool(e.get("frozen", false)))
		var anchor: Vector2 = e["anchor"]
		var show := not bool(e.get("hidden", false)) and anchor.x >= 0.0 and not items.is_empty()
		if not show:
			if _rows.has(uid):
				(_rows[uid]["row"] as Control).visible = false
			continue
		var ent: Dictionary = _rows.get(uid, {})
		var sig := str(items)
		if ent.is_empty() or ent["sig"] != sig:
			ent = _rebuild(uid, items, ent)
			_rows[uid] = ent
		var row: HBoxContainer = ent["row"]
		row.visible = true
		row.size = row.get_combined_minimum_size()
		row.position = anchor - Vector2(row.size.x * 0.5, row.size.y)
	for uid in _rows.keys():
		if not seen.has(uid):
			(_rows[uid]["row"] as Node).queue_free()
			_rows.erase(uid)


## Ordered [key, count] list: shield first, then every status with a count above zero.
static func items_for(shield: int, status: Dictionary, frozen := false) -> Array:
	var items: Array = []
	if shield > 0:
		items.append(["shield", shield])
	for k in UI3.STATUS_CODE:
		if k != "shield" and int(status.get(k, 0)) > 0:
			items.append([k, int(status[k])])
	if frozen and int(status.get("freeze", 0)) <= 0:
		items.append(["freeze", 1])   # a frozen die is a unit flag, not a counted status
	return items


## Icon for a status key, or null when the project has none (the chip then shows the 3-letter code).
static func icon_for(key: String) -> Texture2D:
	if key == "shield":
		return _SHIELD_ICON
	return UnitPortrait._STATUS_ICON.get(key, null)


## The chip row of one unit (for tests / tooltips); null when none is built.
func row_of(uid: int) -> HBoxContainer:
	return _rows[uid]["row"] if _rows.has(uid) else null


func _rebuild(uid: int, items: Array, old: Dictionary) -> Dictionary:
	var row: HBoxContainer
	if old.is_empty():
		row = HBoxContainer.new()
		row.name = "Status%d" % uid
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 4)
		add_child(row)
	else:
		row = old["row"]
		for c in row.get_children():
			row.remove_child(c)
			c.queue_free()
	var shown := mini(items.size(), MAX_SHOWN if items.size() <= MAX_SHOWN else MAX_SHOWN - 1)
	for i in shown:
		var key := String(items[i][0])
		var n := int(items[i][1])
		var chip := _chip(key, n)
		UI3Tooltip.bind(chip, UnitPortrait._effect_tooltip(key, n))
		chip.mouse_filter = Control.MOUSE_FILTER_STOP
		chip.gui_input.connect(_on_chip_input.bind(uid))
		row.add_child(chip)
	if items.size() > shown:
		var more := UI3.plate(&"info")
		more.add_child(UI3.label("+%d" % (items.size() - shown), "LabelDisplay"))
		var hidden: PackedStringArray = []
		for j in range(shown, items.size()):
			hidden.append(UnitPortrait._effect_tooltip(String(items[j][0]), int(items[j][1])))
		UI3Tooltip.bind(more, "\n\n".join(hidden))
		more.mouse_filter = Control.MOUSE_FILTER_STOP
		row.add_child(more)
	return {"row": row, "sig": str(items)}


func _chip(key: String, n: int) -> Control:
	var tex := icon_for(key)
	if tex == null:
		return UI3.status_label_chip(key, n)
	var tint := UI3Theme.color("shield") if key == "shield" else \
		UI3Theme.color("success_text" if _BUFFS.has(key) else "danger_text")
	return UI3.status_tex_chip(tex, n, tint)


func _on_chip_input(ev: InputEvent, uid: int) -> void:
	if not (ev is InputEventMouseButton) or not (ev as InputEventMouseButton).pressed:
		return
	match (ev as InputEventMouseButton).button_index:
		MOUSE_BUTTON_LEFT:
			unit_clicked.emit(uid)
		MOUSE_BUTTON_RIGHT:
			unit_inspect.emit(uid)
