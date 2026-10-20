class_name LandEdit
extends Node
## Land v1 "Sửa Land" mode (design/proposals/land-v1-spec.md §3-4): places, drags, rotates and stores decor on the
## 3D ground, plus the Craft and Rewards tabs. Rules live in LandDecor; this node owns the instances, the ghost,
## the side panel and the input. Land.gd (LandHub) hands in what it owns through `setup()`.

signal mode_changed(on: bool)

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
	_panel = UI3.plate(&"plate")
	_panel.name = "EditPanel"
	_panel.visible = false
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI3Theme.space("8"))
	_panel.add_child(v)
	v.add_child(UI3.label("Edit Land", "LabelTitle"))
	_head_score = UI3.label("", "LabelMuted")
	_head_score.name = "ScoreLabel"
	v.add_child(_head_score)
	_head_cap = UI3.label("", "LabelMuted")
	_head_cap.name = "CapLabel"
	v.add_child(_head_cap)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", UI3Theme.space("8"))
	var grp := ButtonGroup.new()
	for t in [["place", "Place"], ["craft", "Craft"], ["rewards", "Rewards"]]:
		var b := UI3.tab(String(t[1]), String(t[0]) == _tab)
		b.name = "Tab_" + String(t[0])
		b.button_group = grp
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_set_tab.bind(String(t[0])))
		tabs.add_child(b)
		_tab_btns[String(t[0])] = b
	v.add_child(tabs)
	var sc := ScrollContainer.new()
	sc.name = "Scroll"
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_list = VBoxContainer.new()
	_list.name = "List"
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", UI3Theme.space("8"))
	sc.add_child(_list)
	v.add_child(sc)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI3Theme.space("8"))
	_rotate_btn = UI3.button("Rotate · R", &"secondary", &"S")
	_rotate_btn.name = "RotateButton"
	_rotate_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rotate_btn.pressed.connect(rotate_selected)
	row.add_child(_rotate_btn)
	_store_btn = UI3.button("Store · Del", &"secondary", &"S")
	_store_btn.name = "StoreButton"
	_store_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_store_btn.pressed.connect(store_selected)
	row.add_child(_store_btn)
	v.add_child(row)
	var done := UI3.button("Done · Esc", &"primary", &"M")
	done.name = "DoneButton"
	done.pressed.connect(exit)
	v.add_child(done)
	_ui.add_child(_panel)
	_why_tip = UI3.plate(&"notice")
	_why_tip.name = "WhyTip"
	_why_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_why_tip.visible = false
	_why_label = UI3.label("")
	_why_tip.add_child(_why_label)
	_ui.add_child(_why_tip)


func layout() -> void:
	if _panel == null:
		return
	var f := float(_floor.call())
	var w := _ui.size.x
	var h := _ui.size.y
	_panel.scale = Vector2(f, f)
	_panel.custom_minimum_size = Vector2(PANEL_W, 0)
	_panel.size = Vector2(PANEL_W, (h - 112.0 - 24.0) / f)
	_panel.position = Vector2(w - 24.0 - PANEL_W * f, 112.0)


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
		UI3.clear_disabled_reason(_rotate_btn)
	else:
		UI3.set_disabled_reason(_rotate_btn, "Rotate · pick a decor")
	if has_sel:
		UI3.clear_disabled_reason(_store_btn)
	else:
		UI3.set_disabled_reason(_store_btn, "Store · pick a decor")


func _row(title: String, sub: String, btn: Button, selected := false) -> PanelContainer:
	var card := UI3.plate(&"card")
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UI3Theme.space("8"))
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var t := UI3.label(title)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	var s := UI3.label(sub, "LabelMuted")
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(s)
	h.add_child(v)
	h.add_child(btn)
	card.add_child(h)
	if selected:
		UI3.set_card_selected(card, true, false)
	return card


func _rarity_word(r: String) -> String:
	return {"C": "Common", "R": "Rare", "E": "Epic"}.get(r, r)


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
		var b := UI3.button("Place", &"secondary", &"S")
		b.name = "Place_" + id
		b.custom_minimum_size.x = 120
		if left <= 0:
			UI3.set_disabled_reason(b, "All placed")
		else:
			b.pressed.connect(_pick_stored.bind(id))
		_list.add_child(_row(String(d["name"]), "%s · %d in storage of %d" % [_rarity_word(String(d["rarity"])), left, have], b, id == _sel_id))
	if not any:
		var l := UI3.label("Nothing to place yet. Craft decor with Shard in the Craft tab.", "LabelMuted")
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_list.add_child(l)


func _build_craft() -> void:
	for d in LandDecor.all_defs():
		var id := String(d["id"])
		if not bool(d["craftable"]):
			continue
		var why := LandDecor.craft_block(id, MetaState.land_tier, MetaState.land_decor_owned, MetaState.shard_pool)
		var b := UI3.button("Craft · %d" % int(d["shard_cost"]), &"secondary", &"S")
		b.name = "Craft_" + id
		b.custom_minimum_size.x = 136
		var sub := "%s · own %d of %d" % [_rarity_word(String(d["rarity"])), int(MetaState.land_decor_owned.get(id, 0)), int(d["max_own"])]
		if why != "":
			UI3.set_disabled_reason(b, "Locked")
			sub += " · " + why
		else:
			b.pressed.connect(_craft.bind(id))
		_list.add_child(_row(String(d["name"]), sub, b))


func _build_rewards() -> void:
	var score := LandDecor.aesthetic(_placed())
	for m in LandDecor.milestones():
		var id := String(m["id"])
		var pts := int(m["points"])
		var claimed := MetaState.land_milestones_claimed.has(id)
		var b := UI3.button("Claim", &"secondary", &"S")
		b.name = "Claim_" + id
		b.custom_minimum_size.x = 120
		if claimed:
			UI3.set_disabled_reason(b, "Claimed")
		elif score < pts:
			UI3.set_disabled_reason(b, "Need %d" % pts)
		else:
			b.pressed.connect(_claim.bind(id))
		_list.add_child(_row("%d points · %s" % [pts, String(m["label"])], "No Stone, no power.", b))


func _craft(id: String) -> void:
	var why := LandDecor.craft(id)
	if why != "":
		_toast.call(why, 2.0, &"error")
	else:
		_toast.call("Crafted %s" % String(LandDecor.def(id)["name"]), 1.6, &"ok")
	refresh()


func _claim(id: String) -> void:
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
		_hub.add_child(_ghost)
		_ghost.visible = false
	_update_ring(Vector3.ZERO, id, false)
	refresh()


# ================================================================ enter / leave

func enter() -> void:
	if active:
		return
	active = true
	_panel.visible = true
	layout()
	refresh()
	mode_changed.emit(true)


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
	mode_changed.emit(false)


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
	_why_label.text = text
	_why_tip.visible = text != ""
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
