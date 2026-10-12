class_name TrayColumn
extends RefCounted
## One dice-tray column, Dice UI R1 (README 3 "Dice tray"): 272 x 176, panel r20, border 3 LINE
## (4 GOLD when selected or a legal ally target), padding 12, gap 10.
##
##   die   104 x 104 r22 border 3, face icon 40 + Baloo 34, fill = the face's tint
##   right class icon 24 + name (Baloo 18) / party HP bar h26 (the ONLY party HP readout) /
##         status chips (max 4, then "+N")
##   strip six faces h34 r9: rolled face border OUTLINE, the others #B89A74 at .8; icon 18 +
##         Baloo 15 numeral
##
## Selected die: lifts 26 px, 4px gold ring + 3px outline ring (the soft halo is dropped: it is the
## element "Reduce flashing" removes anyway, and StyleBoxFlat has no blur).
## The column is still a Button (toggle) so `%DieSlot0`, focus and the tests keep working.

const W := 272.0
const H := 176.0
const DIE := 104.0
const LIFT := 26.0
const PAD := 12.0

const _STATUS_ICON := {
	"poison": "poison", "burn": "burn", "regen": "regen", "blind": "blind", "weaken": "weaken",
	"vulnerable": "vuln", "thorns": "thorns", "stun": "stun", "undying": "undying",
}


static func build(btn: Button) -> Dictionary:
	btn.custom_minimum_size = Vector2(W, H)
	btn.clip_contents = false
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(root)

	# --- die holder (lifts as a unit with its rings) ---
	var holder := Control.new()
	holder.name = "DieHolder"
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.position = Vector2(PAD, PAD)
	holder.size = Vector2(DIE, DIE)
	root.add_child(holder)
	var ring_dark := Panel.new()
	ring_dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring_dark.position = Vector2(-7, -7)
	ring_dark.size = Vector2(DIE + 14, DIE + 14)
	ring_dark.add_theme_stylebox_override("panel", _ring(DangoTheme.OUTLINE, 3, 29))
	ring_dark.visible = false
	holder.add_child(ring_dark)
	var ring_gold := Panel.new()
	ring_gold.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring_gold.position = Vector2(-4, -4)
	ring_gold.size = Vector2(DIE + 8, DIE + 8)
	ring_gold.add_theme_stylebox_override("panel", _ring(DangoTheme.GOLD, 4, 26))
	ring_gold.visible = false
	holder.add_child(ring_gold)
	var die := PanelContainer.new()
	die.mouse_filter = Control.MOUSE_FILTER_IGNORE
	die.size = Vector2(DIE, DIE)
	var die_style := HudKit.box(DangoTheme.CREAM_100, 22, 3, DangoTheme.OUTLINE, Vector2(3, 4))
	die.add_theme_stylebox_override("panel", die_style)
	holder.add_child(die)
	var dcol := VBoxContainer.new()
	dcol.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dcol.alignment = BoxContainer.ALIGNMENT_CENTER
	dcol.add_theme_constant_override("separation", 0)
	die.add_child(dcol)
	var die_icon := HudKit.tex_rect(null, 40)
	die_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	dcol.add_child(die_icon)
	var die_num := HudKit.label("", 34, DangoTheme.OUTLINE)
	die_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dcol.add_child(DangoTheme.line_box(die_num, 34, 1.0))

	# --- right column ---
	var right := VBoxContainer.new()
	right.name = "Right"
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.position = Vector2(PAD + DIE + 10.0, PAD)
	right.size = Vector2(W - PAD * 2.0 - DIE - 10.0, DIE)
	right.add_theme_constant_override("separation", 6)
	root.add_child(right)
	var name_row := HBoxContainer.new()
	name_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_row.add_theme_constant_override("separation", 6)
	right.add_child(name_row)
	var cls_frame := PanelContainer.new()
	cls_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cls_frame.custom_minimum_size = Vector2(24, 24)
	cls_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cls_frame.add_theme_stylebox_override("panel", HudKit.box(DangoTheme.CREAM_RAISED, 7, 2))
	var cls_icon := TextureRect.new()
	cls_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cls_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cls_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cls_frame.add_child(cls_icon)
	name_row.add_child(cls_frame)
	var name_label := HudKit.label("", 18, DangoTheme.INK)
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(name_label)
	var hp := HPBar.new()
	hp.set_kind(HPBar.Kind.PARTY, 26, 9, 16)
	hp.text_mode = true
	hp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_child(hp)
	var chips := HBoxContainer.new()
	chips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chips.add_theme_constant_override("separation", 4)
	chips.custom_minimum_size = Vector2(0, 26)
	right.add_child(chips)

	# --- face strip ---
	var strip := HBoxContainer.new()
	strip.name = "FaceStrip"
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.position = Vector2(PAD, PAD + DIE + 10.0)
	strip.size = Vector2(W - PAD * 2.0, 34)
	strip.add_theme_constant_override("separation", 4)
	root.add_child(strip)
	var cells: Array = []
	for _i in 6:
		var cell := PanelContainer.new()
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.custom_minimum_size = Vector2(0, 34)
		var crow := HBoxContainer.new()
		crow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		crow.alignment = BoxContainer.ALIGNMENT_CENTER
		crow.add_theme_constant_override("separation", 1)
		cell.add_child(crow)
		var ci := HudKit.tex_rect(null, 18)
		crow.add_child(ci)
		var cn := HudKit.label("", 15, DangoTheme.OUTLINE)
		crow.add_child(cn)
		strip.add_child(cell)
		cells.append({"panel": cell, "icon": ci, "num": cn})

	# Reroll-toss overlay (CombatView._start_reroll_toss) and the plain caption (dead / unrolled).
	var overlay := PanelContainer.new()
	overlay.name = "RerollOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.visible = false
	overlay.add_theme_stylebox_override("panel", HudKit.box(DangoTheme.CREAM_100, 20, 4, DangoTheme.LINE))
	var oi := HudKit.tex_rect(HudKit.icon("reroll"), 40)
	oi.set_anchors_preset(Control.PRESET_CENTER)
	overlay.add_child(oi)
	btn.add_child(overlay)

	return {"button": btn, "root": root, "holder": holder, "die": die, "die_style": die_style,
		"die_icon": die_icon, "die_num": die_num, "ring_gold": ring_gold, "ring_dark": ring_dark,
		"cls_icon": cls_icon, "name_label": name_label, "hp": hp, "chips": chips, "cells": cells,
		"reroll_overlay": overlay, "lifted": false, "panel_style": null}


static func _ring(color: Color, w: int, r: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.draw_center = false
	sb.border_color = color
	sb.set_border_width_all(w)
	sb.set_corner_radius_all(r)
	return sb


## Paints the column. `d`:
##   name:String, class_icon:Texture2D, hp, max_hp, shield, status:Dictionary, incoming:int
##   faces:Array[{type, value}]  rolled:int (-1 = not rolled)  alive, spent:bool
##   selected, legal_target:bool  icons: status key -> Texture2D   tip:String  status_tip:Callable
static func update(content: Dictionary, d: Dictionary) -> void:
	var btn: Button = content["button"]
	var alive := bool(d.get("alive", true))
	var spent := bool(d.get("spent", false))
	var rolled := int(d.get("rolled", -1))
	var faces: Array = d.get("faces", [])
	(content["name_label"] as Label).text = String(d.get("name", ""))
	(content["cls_icon"] as TextureRect).texture = d.get("class_icon", null)
	var hp: HPBar = content["hp"]
	hp.set_stats(int(d.get("hp", 0)), int(d.get("max_hp", 1)))
	hp.set_at_risk(mini(int(d.get("hp", 0)), maxi(0, int(d.get("incoming", 0)) - int(d.get("shield", 0)))))
	HudKit.fill_status_row(content["chips"], d.get("status", {}), int(d.get("shield", 0)),
		d.get("icons", {}), d.get("status_tip", Callable()), 4)

	# The die: the rolled face's icon + number on its tint.
	var die_style: StyleBoxFlat = content["die_style"]
	var icon: TextureRect = content["die_icon"]
	var num: Label = content["die_num"]
	if alive and rolled >= 0 and rolled < faces.size():
		var f: Dictionary = faces[rolled]
		var ftype := String(f.get("type", ""))
		die_style.bg_color = DangoTheme.face_tint(ftype)
		icon.texture = DangoTheme.face_type_icon(ftype)
		icon.visible = true
		var v := int(f.get("value", 0))
		num.text = str(v) if v > 0 else ""
	else:
		die_style.bg_color = DangoTheme.CREAM_300
		icon.visible = false
		num.text = "KO" if not alive else "-"
	# Strip.
	var cells: Array = content["cells"]
	for i in cells.size():
		var c: Dictionary = cells[i]
		var panel: PanelContainer = c["panel"]
		if i >= faces.size():
			panel.visible = false
			continue
		panel.visible = true
		var ff: Dictionary = faces[i]
		var t := String(ff.get("type", ""))
		var on := i == rolled
		var sb := HudKit.box(DangoTheme.face_tint(t), 9, 2,
			DangoTheme.OUTLINE if on else Color("B89A74"))
		panel.add_theme_stylebox_override("panel", sb)
		panel.modulate.a = 1.0 if on else 0.8
		(c["icon"] as TextureRect).texture = DangoTheme.face_type_icon(t)
		var fv := int(ff.get("value", 0))
		(c["num"] as Label).text = str(fv) if (fv > 0 and t != "buff" and t != "debuff") else ""

	# Column frame.
	var selected := bool(d.get("selected", false))
	var lit := selected or bool(d.get("legal_target", false))
	var panel_sb := HudKit.box(DangoTheme.PANEL, 20, 4 if lit else 3,
		DangoTheme.GOLD if lit else DangoTheme.LINE, Vector2(3, 5))
	for st in ["normal", "hover", "pressed", "disabled", "focus"]:
		btn.add_theme_stylebox_override(st, panel_sb)
	btn.add_theme_stylebox_override("focus", DangoTheme.focus_ring_style(20))
	(content["root"] as Control).modulate.a = 0.55 if (spent or not alive) else 1.0
	(content["ring_gold"] as Panel).visible = selected
	(content["ring_dark"] as Panel).visible = selected
	btn.tooltip_text = String(d.get("tip", ""))


## Lifts / drops the die (selected: -26 px). Animated unless `instant`.
static func set_lifted(view: Node, content: Dictionary, lifted: bool, instant: bool) -> void:
	if bool(content["lifted"]) == lifted:
		return
	content["lifted"] = lifted
	var holder: Control = content["holder"]
	var y := PAD - (LIFT if lifted else 0.0)
	if instant or not holder.is_inside_tree():
		holder.position.y = y
		return
	var tw := view.create_tween()
	tw.tween_property(holder, "position:y", y, 0.16) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT if lifted else Tween.EASE_IN)
