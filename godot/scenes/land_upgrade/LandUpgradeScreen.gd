class_name LandUpgradeScreen
extends Control
## M15 Land upgrade (key L). Spec: design/handoffs/ui-02-round3 README section 2 M15, frames
## M15a-M15e. Six tier rows: thumbnail, name, what it adds, cost + cumulative, button.
## Costs and the on/off switch come from EconomyDB land_tiers.json only. While
## `upgrade_enabled` is false (L1) every button reads "Not in this build" and prices stay readable.
## Spending goes through MetaState.upgrade_land() (ledgered). Confirm says it cannot be undone.

const _Eco := preload("res://scripts/meta/economy_db.gd")
const TIER_NAMES: Array[String] = ["Savannah", "Forest", "Arctic", "Mystic", "Genesis", "LunaLanding"]
## Tier gates that Land.gd reads from houses.json are listed here only by name.
const ADDS: Dictionary = {
	2: "+3 preset slots · new decor set",
	3: "+3 preset slots · Mastery house",
	4: "New decor set",
	5: "Gallery",
	6: "Final Land · new decor set",
}

var no_scene_change := false
var _shell: Dictionary
var _rows: VBoxContainer
var _head: PanelContainer
var _detail: PanelContainer
var _sel := 0
var _toast_host: VBoxContainer
var _modal: Control


func _ready() -> void:
	_shell = UI3Meta.build(self, "Land upgrade", "", _on_back)
	var col: VBoxContainer = _shell["col"]
	var body := HBoxContainer.new()
	body.name = "Body"
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", UI3Meta.GAP)
	col.add_child(body)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", UI3Meta.GAP)
	body.add_child(left)
	_head = UI3.plate(&"plate")
	_head.name = "HeaderPlate"
	left.add_child(_head)
	_toast_host = VBoxContainer.new()
	_toast_host.name = "ToastHost"
	left.add_child(_toast_host)
	_rows = VBoxContainer.new()
	_rows.name = "Rows"
	_rows.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_rows.add_theme_constant_override("separation", UI3Theme.space("8"))
	left.add_child(UI3Meta.scroll(_rows))
	_detail = UI3.plate(&"plate")
	_detail.name = "DetailPlate"
	_detail.custom_minimum_size = Vector2(440, 0)
	body.add_child(_detail)
	_sel = _default_sel()
	_redraw()


## Row shown in the detail plate by default: the next tier to buy, or the top one.
func _default_sel() -> int:
	return mini(MetaState.land_tier + 1, _Eco.land_max_tier())


func _unhandled_key_input(ev: InputEvent) -> void:
	if UI3Meta.esc_back(ev, _shell, _on_back):
		get_viewport().set_input_as_handled()


func _on_back() -> void:
	if is_inside_tree() and not no_scene_change:
		LandNav.back_to_land()


static func fmt(n: int) -> String:
	return UI3.fmt(n)


## Cumulative Stone from the tier you are on up to `tier` (what it takes to reach it from here).
func cumulative(tier: int) -> int:
	var sum := 0
	for t in range(MetaState.land_tier, tier):
		sum += _Eco.land_tier_cost(t)
	return sum


## "locked" (L1 switch off) | "done" | "current" | "afford" | "short" | "later" for tier row n.
func row_state(tier: int) -> String:
	if tier <= MetaState.land_tier:
		return "current" if tier == MetaState.land_tier else "done"
	if not _Eco.land_upgrade_enabled():
		return "locked"
	if tier > MetaState.land_tier + 1:
		return "later"
	return "afford" if MetaState.stone >= _Eco.land_tier_cost(tier - 1) else "short"


func _redraw() -> void:
	UI3Meta.clear(_rows)
	var max_t := _Eco.land_max_tier()
	for tier in range(1, max_t + 1):
		_rows.add_child(_row(tier))
	if MetaState.land_tier >= max_t:
		var l := UI3.label("Top tier reached. Nothing to buy.", "LabelMuted")
		l.name = "MaxNote"
		_rows.add_child(l)
	_sel = clampi(_sel, 1, max_t)
	_draw_head()
	_draw_detail()


## Header plate: title + Stone progress toward the next tier.
func _draw_head() -> void:
	UI3Meta.clear(_head)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI3Theme.space("8"))
	_head.add_child(v)
	var cur := MetaState.land_tier
	v.add_child(UI3.label("%s Land · tier %d of %d" % [TIER_NAMES[clampi(cur, 1, 6) - 1], cur, _Eco.land_max_tier()], "LabelTitle"))
	if cur >= _Eco.land_max_tier():
		v.add_child(UI3.label("Top tier reached.", "LabelMuted"))
		return
	var need := _Eco.land_tier_cost(cur)
	var bar := ProgressBar.new()
	bar.name = "StoneBar"
	bar.show_percentage = false
	bar.min_value = 0
	bar.max_value = maxf(need, 1)
	bar.value = clampf(MetaState.stone, 0, need)
	bar.custom_minimum_size = Vector2(0, 16)
	v.add_child(bar)
	var l := UI3.label("%s / %s Land Stone for %s" % [fmt(MetaState.stone), fmt(need), TIER_NAMES[cur]], "LabelMuted")
	l.name = "StoneLine"
	v.add_child(l)


func _select(tier: int) -> void:
	if tier == _sel:
		return
	_sel = tier
	for r in _rows.get_children():
		if r.name.begins_with("Tier"):
			r.theme_type_variation = "PanelCardSelected" if r.name == "Tier%d" % tier else "PanelRow"
	_draw_detail()


## Detail plate for row `_sel`: art, name + status, what it adds, cost rows, reason, primary Upgrade.
func _draw_detail() -> void:
	UI3Meta.clear(_detail)
	var tier := _sel
	var st := row_state(tier)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI3Theme.space("16"))
	_detail.add_child(v)
	var art := Panel.new()
	art.custom_minimum_size = Vector2(0, 200)
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art.add_theme_stylebox_override("panel", UI3Theme.flat(_tint(tier), UI3Theme.radius("s")))
	v.add_child(art)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UI3Theme.space("8"))
	v.add_child(head)
	var t := UI3.label("%s Land" % TIER_NAMES[tier - 1], "LabelScreenTitle")
	t.name = "DetailTitle"
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var badge := _badge(st)
	if badge != "":
		var tg := UI3Meta.tag(badge)
		tg.name = "DetailBadge"
		head.add_child(tg)
	var adds := UI3.label(String(ADDS.get(tier, "Starting Land")))
	adds.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	adds.custom_minimum_size.x = 392
	v.add_child(adds)
	if tier > 1:
		var cost := _Eco.land_tier_cost(tier - 1)
		v.add_child(_info_row("Cost", "%s Stone" % fmt(cost), "Cost"))
		if tier > MetaState.land_tier:
			v.add_child(_info_row("Total from here", "%s Stone" % fmt(cumulative(tier)), "Cumulative"))
			if MetaState.stone >= cost:
				v.add_child(_info_row("Stone after", fmt(MetaState.stone - cost), "After"))
	var up := UI3.button("Upgrade", &"primary", &"L")
	up.name = "DetailUpgrade"
	up.pressed.connect(_ask.bind(tier))
	match st:
		"afford":
			pass
		"short":
			var why := UI3.label("Need %s more Stone" % fmt(_Eco.land_tier_cost(tier - 1) - MetaState.stone))
			why.add_theme_color_override("font_color", UI3Theme.color("danger_text"))
			why.name = "Reason"
			v.add_child(why)
			UI3.set_disabled_reason(up, "Need %s Stone" % fmt(_Eco.land_tier_cost(tier - 1) - MetaState.stone))
		"locked":
			UI3.set_disabled_reason(up, "Not in this build")
		"later":
			UI3.set_disabled_reason(up, "Upgrade %s first" % TIER_NAMES[tier - 2])
		_:
			UI3.set_disabled_reason(up, _button_text(tier, st))
	v.add_child(up)


## Detail badge: Current / Owned / Next (the tier to buy) / Locked (later tiers, or L1 switch off).
func _badge(st: String) -> String:
	match st:
		"current": return "Current"
		"done": return "Owned"
		"afford", "short": return "Next"
	return "Locked"


func _info_row(k: String, val: String, nm: String) -> Control:
	var r := UI3.plate(&"row")
	r.custom_minimum_size = Vector2(0, 48)
	var h := HBoxContainer.new()
	r.add_child(h)
	var a := UI3.label(k, "LabelMuted")
	a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(a)
	var b := UI3.label(val, "LabelTitle")
	b.name = nm
	h.add_child(b)
	return r


## Thumbnail colour per tier (the Land's ground tone); the Land itself draws the real look.
static func _tint(tier: int) -> Color:
	return [Color("#c9a24e"), Color("#5f9a4a"), Color("#9cc4d6"), Color("#7a5bb0"), Color("#b0793f"), Color("#d8d0e8")][clampi(tier, 1, 6) - 1]


func _row(tier: int) -> Control:
	var st := row_state(tier)
	var p := UI3.plate(&"card_selected" if tier == _sel else &"row")
	p.name = "Tier%d" % tier
	p.custom_minimum_size = Vector2(0, 96)
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	p.focus_mode = Control.FOCUS_ALL   # reachable by keyboard even when Upgrade is disabled
	p.focus_entered.connect(_select.bind(tier))
	p.gui_input.connect(_row_input.bind(tier))
	if st == "done":
		p.modulate.a = 0.5   # claimed / owned
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UI3Theme.space("16"))
	p.add_child(h)
	var thumb := Panel.new()
	thumb.custom_minimum_size = Vector2(96, 64)
	thumb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	thumb.add_theme_stylebox_override("panel", UI3Theme.flat(_tint(tier), UI3Theme.radius("s")))
	h.add_child(thumb)
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(mid)
	var nl := UI3.label("%s Land" % TIER_NAMES[tier - 1], "LabelTitle")
	nl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_child(nl)
	var adds := UI3.label(String(ADDS.get(tier, "Starting Land")), "LabelMuted")
	adds.name = "Adds"
	mid.add_child(adds)
	var cost_box := VBoxContainer.new()
	cost_box.custom_minimum_size = Vector2(200, 0)
	cost_box.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(cost_box)
	if tier > 1:
		var c := UI3.label("%s Stone" % fmt(_Eco.land_tier_cost(tier - 1)), "LabelTitle")
		c.name = "Cost"
		cost_box.add_child(c)
		if tier > MetaState.land_tier:
			var cu := UI3.label("%s total from here" % fmt(cumulative(tier)), "LabelMuted")
			cu.name = "Cumulative"
			cost_box.add_child(cu)
	var b := UI3.button(_button_text(tier, st), &"secondary", &"S")
	b.name = "Btn"
	b.disabled = st != "afford"
	b.custom_minimum_size.x = 200
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(_ask.bind(tier))
	b.focus_entered.connect(_select.bind(tier))
	b.mouse_entered.connect(_select.bind(tier))
	h.add_child(b)
	return p


func _row_input(ev: InputEvent, tier: int) -> void:
	if ev.is_action_pressed("ui_accept"):
		_ask(tier)
		get_viewport().set_input_as_handled()


func _button_text(tier: int, st: String) -> String:
	match st:
		"locked": return "Not in this build"
		"done": return "Owned"
		"current": return "Current"
		"afford": return "Upgrade"
		"short":
			return "Need %s more" % fmt(_Eco.land_tier_cost(tier - 1) - MetaState.stone)
	return "Upgrade %s first" % TIER_NAMES[tier - 2]


func _ask(tier: int) -> void:
	if _modal != null or row_state(tier) != "afford":
		return
	var cost := _Eco.land_tier_cost(tier - 1)
	_modal = UI3Meta.confirm(_shell["modal_layer"], "Spend %s Stone?" % fmt(cost),
		"%s becomes %s. This cannot be undone.\nStone after: %s." % [
			TIER_NAMES[tier - 2], TIER_NAMES[tier - 1], fmt(MetaState.stone - cost)],
		"Keep Stone", "Upgrade to %s" % TIER_NAMES[tier - 1], confirm_upgrade.bind(tier), _close_modal, false)


func _close_modal() -> void:
	if _modal != null:
		_modal.queue_free()
		_modal = null


## Runs the upgrade (also what the confirm button calls). True when the tier went up.
## `target` is the tier the dialog promised; anything but land_tier + 1 is refused, so a stale
## or double press cannot buy a second tier.
func confirm_upgrade(target: int) -> bool:
	_close_modal()
	var ok := target == MetaState.land_tier + 1 and MetaState.upgrade_land()
	if ok:
		_toast("Your Land is now %s" % TIER_NAMES[MetaState.land_tier - 1])
	else:
		_toast("Could not upgrade")
	_redraw()
	return ok


func _toast(msg: String) -> void:
	UI3Meta.clear(_toast_host)
	var l := UI3.label(msg, "LabelTitle")
	l.name = "Toast"
	_toast_host.add_child(l)
