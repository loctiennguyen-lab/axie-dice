class_name LandEdit
extends Node
## Land v1 "Sửa Land" mode (design/proposals/land-v1-spec.md §3-4): places, drags, rotates and stores decor on the
## 3D ground, plus the Craft and Rewards tabs. Rules live in LandDecor; this node owns the instances, the ghost,
## the side panel and the input. Land.gd (LandHub) hands in what it owns through `setup()`.

signal mode_changed(on: bool)

const Parts := preload("res://scenes/land/ui5/LandEditParts.gd")
const PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")
const PANEL_W := 480
const PICK_PAD := 0.25
const DRAG_MIN_PX := 6.0

var active: bool = false

var _hub: Node3D
var _ui: Control
var _cam: Camera3D
var _inst: Callable            # path -> Node3D
var _aabb: Callable            # (Node3D, Transform3D) -> AABB
var _ctx: Callable             # () -> {zones, lanes, props}
var _toast: Callable           # (text, hold, tone)
var _floor: Callable           # () -> float, the HUD scale boost

var _nodes: Array[Node3D] = []     # parallel to MetaState.land_decor_placed
var _tab: String = "place"
var _sel_id: String = ""           # a stored copy picked in the panel, waiting for a click on the ground
var _sel_idx: int = -1             # a placed decor picked on the ground
var _pend_rot: int = 0
var _dragging: bool = false
var _drag_orig: Dictionary = {}
var _press_px := Vector2.ZERO
var _ghost: Node3D
var _ring: MeshInstance3D
var _ring_mat: StandardMaterial3D
var _ring_r: float = 0.0

var _panel: PanelContainer
var _head_score: Label
var _head_cap: Label
var _list: VBoxContainer
var _rotate_btn: Button
var _store_btn: Button
var _why_tip: PanelContainer
var _why_label: Label
var _tab_btns := {}
var _tabs: Ui5TabBar
var _wallet_hidden: Array = []   # [cell, was_visible] of the CurrencyPlate cells hidden while editing
var _hint_head: Label


func setup(hub: Node3D, ui: Control, cam: Camera3D, inst: Callable, aabb: Callable, ctx: Callable, toast: Callable, floor_fn: Callable) -> void:
	_hub = hub
	_ui = ui
	_cam = cam
	_inst = inst
	_aabb = aabb
	_ctx = ctx
	_toast = toast
	_floor = floor_fn


# ================================================================ placed decor (scene side)

func _placed() -> Array:
	return MetaState.land_decor_placed


## Validates the saved list against the Land (zones, lanes, caps), puts what no longer fits back in storage, then
## instances the rest. Call after the buildings exist and before random props are scattered.
func build_placed(tier: int) -> Array:
	var ctx: Dictionary = _ctx.call()
	var clean := LandDecor.sanitize(_placed(), MetaState.land_decor_owned, tier)
	var kept: Array = []
	for e in clean:
		# ignore = out-of-range index: skips the cap/storage checks sanitize() already did, ignores no neighbour.
		if LandDecor.placement_block(String(e["id"]), Vector3(float(e["x"]), 0, float(e["z"])), kept, ctx, tier,
				MetaState.land_decor_owned, 1 << 20) == "":
			kept.append(e)
	MetaState.land_decor_placed = kept   # memory only: a load never writes the save
	var feet: Array = []
	for e in kept:
		_nodes.append(_spawn(e))
		feet.append({"p": Vector3(float(e["x"]), 0, float(e["z"])), "r": float(LandDecor.def(String(e["id"]))["footprint_r"])})
	return feet


func _spawn(e: Dictionary) -> Node3D:
	var n := _make_node(String(e["id"]), Vector3(float(e["x"]), 0, float(e["z"])), int(e["rot"]))
	if n != null:
		_hub.add_child(n)
	return n


func _make_node(id: String, pos: Vector3, rot: int) -> Node3D:
	var n: Node3D = _inst.call(LandDecor.scene_path(id))
	if n == null:
		return null
	var s := float(LandDecor.def(id)["scale"])
	var box: AABB = _aabb.call(n, Transform3D.IDENTITY)
	n.scale = Vector3.ONE * s
	n.rotation_degrees.y = rot * 45.0
	n.position = Vector3(pos.x, -box.position.y * s, pos.z)
	return n


func _set_pos(n: Node3D, id: String, pos: Vector3) -> void:
	if n == null:
		return
	var box: AABB = _aabb.call(n, Transform3D.IDENTITY)
	n.position = Vector3(pos.x, -box.position.y * float(LandDecor.def(id)["scale"]), pos.z)


# ================================================================ UI

func build_ui() -> void:
	_panel = PanelParts.panel(PanelParts.plate_box("l", UI3Theme.space("16")), "EditLandPanel")
	_panel.visible = false
	var v := VBoxContainer.new()
	v.name = "Col"
	v.add_theme_constant_override("separation", UI3Theme.space("12"))
	_panel.add_child(v)
	var ttl := Ui5Text.label("Edit Land", "text_title", "text", true)
	ttl.name = "Title"
	v.add_child(ttl)
	var lines := VBoxContainer.new()
	lines.name = "Lines"
	lines.add_theme_constant_override("separation", 0)
	v.add_child(lines)
	_head_score = Ui5Text.label("", "text_body", "text_muted")
	_head_score.name = "AestheticLine"
	lines.add_child(_head_score)
	_head_cap = Ui5Text.label("", "text_body", "text_muted")
	_head_cap.name = "PlacedLine"
	lines.add_child(_head_cap)
	_tabs = Parts.tabs(0, func(i: int) -> void: _set_tab(["place", "craft", "rewards"][i]))
	v.add_child(_tabs)
	for i in 3:
		_tab_btns[["place", "craft", "rewards"][i]] = _tabs.get_node(Parts.TAB_NAMES[i])
	var sc := ScrollContainer.new()
	sc.name = "Scroll"
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.get_v_scroll_bar().custom_minimum_size.x = UI3Theme.SCROLL_W
	_list = VBoxContainer.new()
	_list.name = "List"
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", UI3Theme.space("8"))
	sc.add_child(_list)
	v.add_child(sc)
	var tools := VBoxContainer.new()
	tools.name = "Tools"
	tools.add_theme_constant_override("separation", UI3Theme.space("8"))
	_rotate_btn = UI3.button("Rotate", &"secondary", &"S")
	_rotate_btn.name = "RotateButton"
	_rotate_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rotate_btn.tooltip_text = "Rotate · R"
	_rotate_btn.pressed.connect(rotate_selected)
	tools.add_child(_rotate_btn)
	_store_btn = UI3.button("Store", &"secondary", &"S")
	_store_btn.name = "StoreButton"
	_store_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_store_btn.tooltip_text = "Store · Del"
	_store_btn.pressed.connect(store_selected)
	tools.add_child(_store_btn)
	v.add_child(tools)
	var done := UI3.button("Done", &"primary", &"M")
	done.name = "DoneButton"
	done.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	done.tooltip_text = "Done · Esc"
	done.pressed.connect(exit)
	v.add_child(done)
	_ui.add_child(_panel)
	# GhostHint: tooltip plate by the cursor, "Placing: <name>" and the reason when the spot is refused.
	_why_tip = PanelParts.panel(UI3Theme.flat(UI3Theme.color("plate"), UI3Theme.radius("m"), UI3Theme.stroke("rim"),
		UI3Theme.color("plate_rim"), Vector4(UI3Theme.space("16"), UI3Theme.space("12"), UI3Theme.space("16"), UI3Theme.space("12")),
		PanelParts.lip(UI3Theme.color("plate_ink"))), "GhostHint")
	_why_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_why_tip.visible = false
	var hv := VBoxContainer.new()
	hv.add_theme_constant_override("separation", UI3Theme.space("4"))
	_why_tip.add_child(hv)
	_hint_head = Ui5Text.label("", "text_body", "text", true)
	_hint_head.name = "Placing"
	hv.add_child(_hint_head)
	_why_label = Ui5Text.label("", "text_body", "danger_text")
	_why_label.name = "Why"
	hv.add_child(_why_label)
	_ui.add_child(_why_tip)


func layout() -> void:
	if _panel == null:
		return
	var f := float(_floor.call())
	var w := _ui.size.x
	var h := _ui.size.y
	_panel.scale = Vector2(f, f)
	_panel.custom_minimum_size = Vector2(PANEL_W, 0)
	_panel.size = Vector2(PANEL_W, (h - 104.0 * f - 24.0) / f)
	_panel.position = Vector2(w - 24.0 - PANEL_W * f, 104.0 * f)


func _set_tab(t: String) -> void:
	_tab = t
	# set_pressed_no_signal skips the ButtonGroup, so unpress the other tabs by hand: only the open tab is outlined.
	for k in _tab_btns:
		(_tab_btns[k] as Button).set_pressed_no_signal(String(k) == t)
	refresh()


func refresh() -> void:
	if _panel == null:
		return
	var placed := _placed()
	var score := LandDecor.aesthetic(placed)
	var nxt := LandDecor.next_milestone(score)
	_head_score.text = "Aesthetic %d" % score + ("" if nxt.is_empty() else " · next reward at %d" % int(nxt["points"]))
	_head_cap.text = "Placed %d of %d (Land tier %d)" % [placed.size(), LandDecor.tier_cap(MetaState.land_tier), MetaState.land_tier]
	# remember which row/button had focus, so the rebuild below can give it back
	var fo := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	var f_row := -1
	var f_id := ""
	var f_btn := ""
	if fo != null and _list.is_ancestor_of(fo):
		var rw: Node = fo
		while rw.get_parent() != _list:
			rw = rw.get_parent()
		f_row = rw.get_index()
		f_id = String(rw.get_meta("decor_id", ""))
		f_btn = String(fo.name)
	for c in _list.get_children():
		c.queue_free()
		_list.remove_child(c)
	match _tab:
		"craft":
			_build_craft()
		"rewards":
			_build_rewards()
		_:
			_build_place()
	var has_sel := _sel_idx >= 0 and _sel_idx < placed.size()
	if has_sel or _sel_id != "":
		Ui5DisabledReason.clear(_rotate_btn)
	else:
		Ui5DisabledReason.apply(_rotate_btn, "Rotate · pick a decor")
	if has_sel:
		Ui5DisabledReason.clear(_store_btn)
	else:
		Ui5DisabledReason.apply(_store_btn, "Store · pick a decor")
	if has_sel or _sel_id != "":
		_rotate_btn.tooltip_text = "Rotate · R"
	if has_sel:
		_store_btn.tooltip_text = "Store · Del"
	if f_row >= 0:
		call_deferred("_restore_focus", f_row, f_id, f_btn)


func _rarity_word(r: String) -> String:
	return {"C": "Common", "R": "Rare", "E": "Epic"}.get(r, r)


func _rarity_token(r: String) -> String:
	return {"C": "rarity_common", "R": "rarity_rare", "E": "rarity_epic"}.get(r, "text_muted")


func _sbtn(text: String) -> Button:
	var b := UI3.button(text, &"secondary", &"S")
	b.custom_minimum_size.x = 120
	return b


func _build_place() -> void:
	var owned := MetaState.land_decor_owned
	var any := false
	for d in LandDecor.all_defs():
		var id := String(d["id"])
		var have := int(owned.get(id, 0))
		if have <= 0:
			continue
		any = true
		var left := LandDecor.in_storage(id, _placed(), owned)
		var b := _sbtn("Place")
		b.name = "PlaceButton"
		if left <= 0:
			UI3.set_disabled_reason(b, "All placed")
		else:
			b.pressed.connect(_pick_stored.bind(id))
		var rr := String(d["rarity"])
		var prow := Parts.row("DecorRow", String(d["name"]), _rarity_word(rr), _rarity_token(rr), " · %d in storage of %d" % [left, have], b, id == _sel_id)
		prow.set_meta("decor_id", id)
		_list.add_child(prow, true)
	if not any:
		_list.add_child(Parts.empty_state("Nothing to place yet. Craft decor with Shards in the Craft tab."))


func _build_craft() -> void:
	for d in LandDecor.all_defs():
		var id := String(d["id"])
		if not bool(d["craftable"]):
			continue
		var why := LandDecor.craft_block(id, MetaState.land_tier, MetaState.land_decor_owned, MetaState.shard_pool)
		var b := _sbtn("Craft · %d" % int(d["shard_cost"]))
		b.name = "CraftButton"
		b.icon = UI3.currency_icon("cur_shard", UI3Theme.size_of("icon_s"))
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", UI3Theme.size_of("icon_s"))
		b.custom_minimum_size.x = 136
		var rr := String(d["rarity"])
		var sub := " · own %d of %d" % [int(MetaState.land_decor_owned.get(id, 0)), int(d["max_own"])]
		if why != "":
			Ui5DisabledReason.apply(b, "Locked")
			b.icon = null
			sub += " · " + why
		else:
			b.pressed.connect(_craft.bind(id))
		var crow := Parts.row("CraftRow", String(d["name"]), _rarity_word(rr), _rarity_token(rr), sub, b)
		crow.set_meta("decor_id", id)
		_list.add_child(crow, true)


## Frame e04 writes "N points · Label"; a long label would wrap to 3 lines in the 320 px panel, so it shortens to "pts".
func _reward_title(pts: int, label: String) -> String:
	var full := "%d points · %s" % [pts, label]
	return full if full.length() <= 28 else "%d pts · %s" % [pts, label]


func _build_rewards() -> void:
	var score := LandDecor.aesthetic(_placed())
	for m in LandDecor.milestones():
		var id := String(m["id"])
		var pts := int(m["points"])
		var claimed := MetaState.land_milestones_claimed.has(id)
		var b := _sbtn("Claim")
		b.name = "ClaimButton"
		if claimed:
			Ui5DisabledReason.apply(b, "Claimed")
		elif score < pts:
			Ui5DisabledReason.apply(b, "Need %d" % pts)
		else:
			b.pressed.connect(_claim.bind(id))
		var wrow := Parts.row("RewardRow", _reward_title(pts, String(m["label"])), "", "", "No Stone, no power.", b)
		wrow.set_meta("milestone_id", id)
		_list.add_child(wrow, true)


func _craft(id: String) -> void:
	var why := LandDecor.craft(id)
	if why != "":
		_toast.call(why, 2.0, &"error")
	else:
		_toast.call("Crafted %s" % String(LandDecor.def(id)["name"]), 1.6, &"ok")
	refresh()


func _claim(id: String) -> void:
	if MetaState.econ_remote() != null:
		LandDecor.claim_remote(id, func(err: String) -> void:
			_toast.call(err if err != "" else "Reward claimed", 2.0, &"error" if err != "" else &"ok")
			refresh())
		return
	var why := LandDecor.claim(id)
	_toast.call(why if why != "" else "Reward claimed", 2.0, &"error" if why != "" else &"ok")
	refresh()


func _pick_stored(id: String) -> void:
	_sel_id = id
	_sel_idx = -1
	_pend_rot = 0
	_drop_ghost()
	_ghost = _make_node(id, Vector3(0, 0, 0), _pend_rot)
	if _ghost != null:
		_ghost.name = "PlacingGhost"
		_hub.add_child(_ghost)
		_ghost.visible = false
	_update_ring(Vector3.ZERO, id, false)
	refresh()


# ================================================================ enter / leave

func _restore_focus(row: int, id: String, btn: String) -> void:
	if not active or _list.get_child_count() == 0:
		return
	var rw: Node = null
	for c in _list.get_children():
		if id != "" and String(c.get_meta("decor_id", "")) == id:
			rw = c
	if rw == null:
		rw = _list.get_child(mini(row, _list.get_child_count() - 1))
	var bs := rw.find_children("*", "Button", true, false)
	for b in bs:
		if String(b.name) == btn and (b as Button).focus_mode != Control.FOCUS_NONE:
			(b as Button).grab_focus()
			return
	for b in bs:
		if (b as Button).focus_mode != Control.FOCUS_NONE:
			(b as Button).grab_focus()
			return
	var tb := _tab_btns.get(_tab) as Button
	if tb != null:
		tb.grab_focus()


func _focus_tab() -> void:
	var tb := _tab_btns.get(_tab) as Button
	if active and tb != null and tb.is_visible_in_tree():
		tb.grab_focus()


func _focus_hud_button() -> void:
	var eb := get_tree().root.find_child("EditLandButton", true, false) as Control
	if eb != null and eb.is_visible_in_tree():
		eb.grab_focus()


func enter() -> void:
	if active:
		return
	active = true
	_panel.visible = true
	_hide_wallet_cells(true)
	layout()
	refresh()
	mode_changed.emit(true)
	call_deferred("_focus_tab")


func exit() -> void:
	if not active:
		return
	_cancel_drag()
	_sel_id = ""
	_sel_idx = -1
	_drop_ghost()
	_hide_ring()
	_why_tip.visible = false
	active = false
	_panel.visible = false
	_hide_wallet_cells(false)
	mode_changed.emit(false)
	call_deferred("_focus_hud_button")


## Frame e01: while editing, the CurrencyPlate shows only the settings button (cells hidden, put back on exit).
func _hide_wallet_cells(on: bool) -> void:
	if on:
		var w: Variant = _hub.get("_wallet")
		if w is Control:
			for n in ["ShardValue", "StoneValue", "GemValue"]:
				var c := (w as Control).find_child(n, true, false) as Control
				if c != null:
					_wallet_hidden.append([c, c.visible])
					c.visible = false
	else:
		for e in _wallet_hidden:
			if is_instance_valid(e[0]):
				(e[0] as Control).visible = bool(e[1])
		_wallet_hidden.clear()
	if _hub.has_method("_layout"):
		_hub.call("_layout")


func _cancel_drag() -> void:
	if _dragging and _sel_idx >= 0 and _sel_idx < _nodes.size() and not _drag_orig.is_empty():
		_set_pos(_nodes[_sel_idx], String(_drag_orig["id"]), Vector3(float(_drag_orig["x"]), 0, float(_drag_orig["z"])))
	_dragging = false


func _drop_ghost() -> void:
	if _ghost != null:
		_ghost.queue_free()
		_ghost = null


# ================================================================ ring (valid / invalid marker)

func _update_ring(pos: Vector3, id: String, ok: bool) -> void:
	var r := float(LandDecor.def(id).get("footprint_r", 0.5))
	if _ring == null:
		_ring = MeshInstance3D.new()
		_ring_mat = StandardMaterial3D.new()
		_ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_ring.material_override = _ring_mat
		_hub.add_child(_ring)
	if _ring.mesh == null or not is_equal_approx(r, _ring_r):
		var m := CylinderMesh.new()
		m.top_radius = r
		m.bottom_radius = r
		m.height = 0.04
		m.radial_segments = 32
		_ring.mesh = m
		_ring_r = r
	var c := UI3Theme.color("accent") if ok else UI3Theme.color("danger")
	_ring_mat.albedo_color = Color(c.r, c.g, c.b, 0.55)
	_ring.position = Vector3(pos.x, 0.06, pos.z)
	_ring.visible = true


func _hide_ring() -> void:
	if _ring != null:
		_ring.visible = false


func _show_why(text: String, at: Vector2) -> void:
	var head := ""
	if _sel_id != "" and not _dragging:
		head = "Placing: %s" % String(LandDecor.def(_sel_id)["name"])
	_hint_head.text = head
	_hint_head.visible = head != ""
	_why_label.text = text
	_why_label.visible = text != ""
	_why_tip.visible = head != "" or text != ""
	_why_tip.reset_size()
	_why_tip.position = at + Vector2(24, 24)


# ================================================================ input

func ground_at(screen: Vector2) -> Vector3:
	var o := _cam.project_ray_origin(screen)
	var n := _cam.project_ray_normal(screen)
	if absf(n.y) < 0.0001:
		return Vector3.INF
	return o + n * (-o.y / n.y)


func _snap_pos(p: Vector3) -> Vector3:
	if Input.is_key_pressed(KEY_SHIFT):
		return Vector3(snappedf(p.x, 0.01), 0, snappedf(p.z, 0.01))
	return Vector3(LandDecor.snap(p.x), 0, LandDecor.snap(p.z))


func _pick(g: Vector3) -> int:
	var best := -1
	var bd := INF
	var placed := _placed()
	for i in placed.size():
		var e: Dictionary = placed[i]
		var d := Vector2(g.x - float(e["x"]), g.z - float(e["z"])).length()
		var r := maxf(float(LandDecor.def(String(e["id"]))["footprint_r"]), 0.6) + PICK_PAD
		if d < r and d < bd:
			best = i
			bd = d
	return best


func _over_panel(screen: Vector2) -> bool:
	return _panel.visible and Rect2(_panel.position, _panel.size * _panel.scale).has_point(screen)


## Mouse release is read in _input so it still arrives when the pointer is over the panel (drop = store).
func _input(event: InputEvent) -> void:
	if not active or not _dragging:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_end_drag(event.position)
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventMouseMotion:
		_on_motion(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_press(event.position)


func _on_motion(screen: Vector2) -> void:
	var g := ground_at(screen)
	if g == Vector3.INF:
		return
	var p := _snap_pos(g)
	if _dragging and _sel_idx >= 0:
		var e: Dictionary = _placed()[_sel_idx]
		_set_pos(_nodes[_sel_idx], String(e["id"]), p)
		var why := LandDecor.placement_block(String(e["id"]), p, _placed(), _ctx.call(), MetaState.land_tier, MetaState.land_decor_owned, _sel_idx)
		_update_ring(p, String(e["id"]), why == "")
		_show_why(why, screen)
	elif _sel_id != "":
		if _ghost != null:
			_ghost.visible = true
			_set_pos(_ghost, _sel_id, p)
		var why2 := LandDecor.placement_block(_sel_id, p, _placed(), _ctx.call(), MetaState.land_tier, MetaState.land_decor_owned)
		_update_ring(p, _sel_id, why2 == "")
		_show_why(why2, screen)
	elif _sel_idx >= 0 and _sel_idx < _placed().size():
		_why_tip.visible = false


func _on_press(screen: Vector2) -> void:
	var g := ground_at(screen)
	if g == Vector3.INF:
		return
	var p := _snap_pos(g)
	if _sel_id != "":
		_place_new(_sel_id, p)
		return
	var hit := _pick(g)
	if hit >= 0:
		_sel_idx = hit
		_dragging = true
		_press_px = screen
		_drag_orig = (_placed()[hit] as Dictionary).duplicate()
		var id := String(_drag_orig["id"])
		_update_ring(Vector3(float(_drag_orig["x"]), 0, float(_drag_orig["z"])), id, true)
		refresh()
	elif _sel_idx >= 0 and _sel_idx < _placed().size():
		_move_to(_sel_idx, p)   # click-click fallback (touch): picked one, now click where it goes


func _end_drag(screen: Vector2) -> void:
	var idx := _sel_idx
	_dragging = false
	_why_tip.visible = false
	if idx < 0 or idx >= _placed().size():
		return
	if _over_panel(screen):
		store_selected()
		return
	if screen.distance_to(_press_px) < DRAG_MIN_PX:
		return   # a plain click: just selected
	var p := _snap_pos(ground_at(screen))
	_move_to(idx, p)


func _move_to(idx: int, p: Vector3) -> void:
	var e: Dictionary = _placed()[idx]
	var id := String(e["id"])
	var why := LandDecor.placement_block(id, p, _placed(), _ctx.call(), MetaState.land_tier, MetaState.land_decor_owned, idx)
	if why != "":
		_set_pos(_nodes[idx], id, Vector3(float(e["x"]), 0, float(e["z"])))
		_toast.call(why, 2.0, &"error")
		_update_ring(Vector3(float(e["x"]), 0, float(e["z"])), id, true)
		return
	e["x"] = snappedf(p.x, 0.01)
	e["z"] = snappedf(p.z, 0.01)
	_set_pos(_nodes[idx], id, p)
	_update_ring(p, id, true)
	MetaState.save_to_disk()
	refresh()


func _place_new(id: String, p: Vector3) -> void:
	var why := LandDecor.placement_block(id, p, _placed(), _ctx.call(), MetaState.land_tier, MetaState.land_decor_owned)
	if why != "":
		_toast.call(why, 2.0, &"error")
		return
	var e := {"id": id, "x": snappedf(p.x, 0.01), "z": snappedf(p.z, 0.01), "rot": _pend_rot}
	_placed().append(e)
	_nodes.append(_spawn(e))
	MetaState.save_to_disk()
	if LandDecor.in_storage(id, _placed(), MetaState.land_decor_owned) <= 0:
		_sel_id = ""
		_drop_ghost()
		_hide_ring()
		_why_tip.visible = false
	refresh()


func rotate_selected() -> void:
	if _sel_idx >= 0 and _sel_idx < _placed().size():
		var e: Dictionary = _placed()[_sel_idx]
		e["rot"] = LandDecor.rot_step(int(e["rot"]))
		_nodes[_sel_idx].rotation_degrees.y = int(e["rot"]) * 45.0
		MetaState.save_to_disk()
	elif _sel_id != "":
		_pend_rot = LandDecor.rot_step(_pend_rot)
		if _ghost != null:
			_ghost.rotation_degrees.y = _pend_rot * 45.0


func store_selected() -> void:
	var idx := _sel_idx
	if idx < 0 or idx >= _placed().size():
		return
	_cancel_drag()
	_placed().remove_at(idx)
	var n: Node3D = _nodes[idx]
	_nodes.remove_at(idx)
	if n != null:
		n.queue_free()
	_sel_idx = -1
	_hide_ring()
	_why_tip.visible = false
	MetaState.save_to_disk()
	refresh()


## Keys while the mode is on. Returns true when used. Land routes every key here so hub shortcuts stay quiet.
func handle_key(ev: InputEventKey) -> bool:
	if ev.keycode == KEY_ESCAPE or ev.keycode == KEY_E:
		exit()
	elif ev.keycode == KEY_R:
		rotate_selected()
	elif ev.keycode == KEY_DELETE or ev.keycode == KEY_BACKSPACE:
		store_selected()
	else:
		return false
	return true
