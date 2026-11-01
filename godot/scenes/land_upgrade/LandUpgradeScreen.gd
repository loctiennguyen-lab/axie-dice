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
	2: "+3 preset slots · New decor set · +2 Rare decor",
	3: "+3 preset slots · Mastery house",
	4: "New decor set",
	5: "Gallery",
	6: "Final Land · new decor set",
}

## Where each new thing is found, shown in the tier-up banner on Land.
const ADDS_WHERE: Dictionary = {
	2: "+3 preset slots: House · New decor set and +2 Rare decor: Edit Land",
	3: "+3 preset slots: House · Mastery house: on your Land",
	4: "New decor set: Edit Land",
	5: "Gallery: on your Land",
	6: "New decor set: Edit Land",
}

const Parts := preload("res://scenes/land_upgrade/ui5/LandUpgradeParts.gd")

var no_scene_change := false
var _shell: Dictionary
var _rows: VBoxContainer
var _head_host: VBoxContainer
var _detail: Ui5DetailPlate
var _sel := 0
var _toast_host: VBoxContainer
var _modal: Control
var _stone_value: Label
var _done := false   # set after a successful upgrade so a double tap cannot toast an error


func _ready() -> void:
	_shell = UI3Meta.build(self, "Land upgrade", "", _on_back)
	(_shell["panel"] as Control).name = "PlateHost"   # t_ui_laws L0
	_stone_value = Parts.header(_shell, MetaState.stone)
	var col: VBoxContainer = _shell["col"]
	var body := HBoxContainer.new()
	body.name = "Body"
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", UI3Meta.GAP)
	col.add_child(body)
	var left := VBoxContainer.new()
	left.name = "TierList"
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", UI3Theme.space("12"))
	body.add_child(left)
	_head_host = VBoxContainer.new()
	left.add_child(_head_host)
	_rows = VBoxContainer.new()
	_rows.name = "Rows"
	_rows.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_rows.add_theme_constant_override("separation", UI3Theme.space("12"))
	left.add_child(UI3Meta.scroll(_rows))
	_detail = Ui5DetailPlate.new()
	_detail.setup("upgrade_detail_w", "", "", "", 12)
	body.add_child(_detail)
	_toast_host = VBoxContainer.new()
	_toast_host.name = "ToastHost"
	_toast_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_host.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_toast_host.offset_top = UI3Theme.space("24")
	add_child(_toast_host)
	_sel = _default_sel()
	_redraw()


## Row shown in the detail plate by default: the next tier to buy, or the top one.
func _default_sel() -> int:
	return mini(MetaState.land_tier + 1, _Eco.land_max_tier())


## Display name of tier n ("Luna Landing", not the id).
## "Savannah Land", but "Luna Landing" already says it.
static func land_title(n: int) -> String:
	var nm := tier_name(n)
	return nm if nm.ends_with("Landing") else nm + " Land"


static func tier_name(n: int) -> String:
	return TIER_NAMES[clampi(n, 1, 6) - 1].replace("LunaLanding", "Luna Landing")


func _unhandled_key_input(ev: InputEvent) -> void:
	if UI3Meta.esc_back(ev, _shell, _on_back):
		if is_inside_tree():   # a handler above may have changed scene
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
	_sel = clampi(_sel, 1, max_t)
	for tier in range(1, max_t + 1):
		var r := _row(tier)
		_rows.add_child(r, true)
		r.focus_entered.connect(_select.bind(tier))
		r.gui_input.connect(_row_input.bind(tier))
		r.mouse_entered.connect(_select.bind(tier))
	_stone_value.text = fmt(MetaState.stone)
	_draw_head()
	_draw_detail()
	call_deferred("_focus_first")


func _focus_first() -> void:
	if not is_inside_tree():
		return
	var tgt := find_child("UpgradeButton", true, false) as Button
	if tgt == null or tgt.disabled:
		tgt = null
		var rr := find_child("TierRow%d" % _sel, true, false)
		if rr != null:
			tgt = rr.find_child("RowButton", true, false) as Button
	if tgt == null or tgt.focus_mode == Control.FOCUS_NONE:
		tgt = find_child("BackButton", true, false) as Button
	if tgt != null:
		tgt.grab_focus()


## TierHeader: "<Land> · tier n of 6", the Stone bar and the progress line.
func _draw_head() -> void:
	UI3Meta.clear(_head_host)
	var cur := MetaState.land_tier
	var max_t := _Eco.land_max_tier()
	var title := "%s · tier %d of %d" % [land_title(cur), cur, max_t]
	if cur >= max_t:
		_head_host.add_child(Parts.tier_header(title, 1, 1, "Top tier reached."))
		return
	var need := _Eco.land_tier_cost(cur)
	_head_host.add_child(Parts.tier_header(title, MetaState.stone, need,
		"%s / %s Land Stone for %s" % [fmt(MetaState.stone), fmt(need), tier_name(cur + 1)]))


func _select(tier: int) -> void:
	if tier == _sel:
		return
	_sel = tier
	for r in _rows.get_children():
		if r.name.begins_with("TierRow"):
			var n := int(String(r.name).substr(7))
			(r as PanelContainer).add_theme_stylebox_override("panel", _row_box(n == tier))
	_draw_detail()


func _row_box(ring: bool) -> StyleBoxFlat:
	var probe := Parts.tier_row(1, "", "", "", "", Button.new(), ring, false)
	var sb := probe.get_theme_stylebox("panel") as StyleBoxFlat
	probe.free()
	return sb


## DetailPlate for row `_sel`: TierArt, Name + StateTag, Adds, cost rows, then the wide UpgradeButton (disabled = its reason).
func _draw_detail() -> void:
	var tier := _sel
	var st := row_state(tier)
	_detail.show_item("")
	_detail.title.visible = false
	var art := Panel.new()
	art.name = "TierArt"
	art.custom_minimum_size.y = UI3Theme.size_of("upgrade_art_h")
	art.add_theme_stylebox_override("panel", UI3Theme.flat(Parts.tint(tier), UI3Theme.radius("m")))
	art.clip_contents = true
	art.set_meta("align_not_icon", true)   # the tier render is a picture block, not an icon the text below centres on
	var prev_path := "res://assets/land/tier_previews/tier_%d.png" % clampi(tier, 1, 6)
	if ResourceLoader.exists(prev_path):   # Liam 1/11 (q6): a real Land render of that tier (tests/qa_land_tier_render.gd); the tint stays as fallback
		var pic := TextureRect.new()
		pic.name = "TierPreview"
		pic.texture = load(prev_path)
		pic.set_anchors_preset(Control.PRESET_FULL_RECT)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.add_child(pic)
	_detail.body.add_child(art)
	var head := HBoxContainer.new()
	head.name = "NameRow"
	head.add_theme_constant_override("separation", UI3Theme.space("12"))
	_detail.body.add_child(head)
	var t := Ui5Text.label(land_title(tier), "text_screen_title", "text", true)
	t.name = "Name"
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head.add_child(t)
	head.add_child(Parts.state_tag(_badge(st)))
	_detail.add_line(String(ADDS.get(tier, "Starting Land")), "text_muted").name = "Adds"
	var cost := _Eco.land_tier_cost(tier - 1) if tier > 1 else 0
	if tier > MetaState.land_tier:
		_detail.body.add_child(Parts.kv("CostRow", "Cost", "%s Stone" % fmt(cost)))
		if true:
			_detail.body.add_child(Parts.kv("TotalRow", "Total from here", "%s Stone" % fmt(cumulative(tier))))
			if st == "afford":
				_detail.body.add_child(Parts.kv("AfterRow", "Stone after", "%s Stone" % fmt(MetaState.stone - cost)))
	if MetaState.land_tier >= _Eco.land_max_tier():
		_detail.add_line("Top tier reached. Nothing to buy.").name = "TopLine"
		return
	var up: Button
	match st:
		"afford":
			up = _detail.set_primary("Upgrade")
			up.pressed.connect(_ask.bind(tier))
		"short":
			var why := "Need %s more Stone" % fmt(cost - MetaState.stone)
			up = _detail.set_primary(why, why)
		"locked":
			up = _detail.set_primary("Not in this build", "Not in this build")
		"later":
			var why2 := "Upgrade %s first" % tier_name(tier - 1)
			up = _detail.set_primary(why2, why2)
		_:
			up = _detail.set_primary(_button_text(tier, st), _button_text(tier, st))
	up.name = "UpgradeButton"


## Detail badge: Current / Owned / Next (the tier to buy) / Locked (later tiers, or L1 switch off).
func _badge(st: String) -> String:
	match st:
		"current": return "Current"
		"done": return "Owned"
		"afford", "short": return "Next"
	return "Locked"


func _row(tier: int) -> Control:
	var st := row_state(tier)
	var cost := ""
	var cum := ""
	if tier > 1 and tier > MetaState.land_tier:
		cost = "%s Stone" % fmt(_Eco.land_tier_cost(tier - 1))
		cum = "%s total from here" % fmt(cumulative(tier))
	var b := UI3.button(_button_text(tier, st), &"secondary", &"S")
	b.disabled = st != "afford"
	b.custom_minimum_size.x = 200
	b.pressed.connect(_ask.bind(tier))
	b.focus_entered.connect(_select.bind(tier))
	b.mouse_entered.connect(_select.bind(tier))
	if b.disabled:
		b.tooltip_text = b.text
	return Parts.tier_row(tier, land_title(tier), String(ADDS.get(tier, "Starting Land")), cost, cum, b, tier == _sel, st == "done")


func _row_input(ev: InputEvent, tier: int) -> void:
	if ev.is_action_pressed("ui_accept"):
		_ask(tier)
		if is_inside_tree():   # a handler above may have changed scene
			get_viewport().set_input_as_handled()


func _button_text(tier: int, st: String) -> String:
	match st:
		"locked": return "Not in this build"
		"done": return "Owned"
		"current": return "Current"
		"afford": return "Upgrade"
		"short":
			return "Need %s more" % fmt(_Eco.land_tier_cost(tier - 1) - MetaState.stone)
	return "Upgrade %s first" % tier_name(tier - 1)


func _ask(tier: int) -> void:
	if _modal != null or row_state(tier) != "afford":
		return
	var cost := _Eco.land_tier_cost(tier - 1)
	var keep := UI3.button("Keep Stone", &"secondary", &"M")
	keep.name = "KeepStoneButton"
	keep.pressed.connect(_close_modal)
	var yes := UI3.button("Upgrade to %s" % tier_name(tier), &"primary", &"M")
	yes.name = "UpgradeToButton"
	yes.pressed.connect(confirm_upgrade.bind(tier))
	var root := UI3.ModalRoot.new()
	root.theme = UI3Theme.get_theme()
	root.name = "Confirm"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_to_group("ui3_modal")
	var scrim := ColorRect.new()
	scrim.name = "Scrim"
	scrim.color = UI3Theme.color("scrim")
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(scrim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	var dlg := Parts.PanelParts.panel(Parts.PanelParts.plate_box("xl", UI3Theme.space("32")), "UpgradeConfirm")
	dlg.custom_minimum_size.x = UI3Theme.size_of("modal_s_w")
	center.add_child(dlg)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI3Theme.space("20"))
	dlg.add_child(v)
	var ttl := Ui5Text.label("Spend %s Stone?" % fmt(cost), "text_banner", "text", true)
	ttl.name = "Title"
	ttl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(ttl)
	var bd := Ui5Text.label("%s becomes %s. This cannot be undone.\nStone after: %s." % [
		tier_name(tier - 1), tier_name(tier), fmt(MetaState.stone - cost)], "text_body", "text")
	bd.name = "Body"
	bd.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(bd)
	v.add_child(Ui5ModalFooter.make(yes, keep))
	root.actions = [keep, yes]
	root.focus_index = 0   # focus starts on the safe choice
	root.cancelled.connect(_close_modal)
	_shell["modal_layer"].add_child(root)
	_modal = root
	var cap := Ui5Keycap.make("Space")
	keep.add_child(cap)   # Space presses the focused Keep Stone; no keycap on Upgrade
	Ui5HudStyle.place_trailing(keep, cap, UI3Theme.space("16"))
	keep.resized.connect(func() -> void: Ui5HudStyle.place_trailing(keep, cap, UI3Theme.space("16")))


func _close_modal() -> void:
	if _modal != null:
		_modal.queue_free()
		_modal = null


## Runs the upgrade (also what the confirm button calls). True when the tier went up.
## `target` is the tier the dialog promised; anything but land_tier + 1 is refused, so a stale
## or double press cannot buy a second tier.
func confirm_upgrade(target: int) -> bool:
	_close_modal()
	if _done or target <= MetaState.land_tier:
		return false   # a second press of the same confirm: already upgraded, say nothing
	var ok := target == MetaState.land_tier + 1 and MetaState.upgrade_land()
	if ok:
		_done = true
		_toast("Your Land is now %s" % TIER_NAMES[MetaState.land_tier - 1])
		if not no_scene_change and is_inside_tree():
			LandNav.back_to_land()   # Land reads the new tier in _ready and shows the banner once
			return true
	else:
		_toast("Could not upgrade", &"error")
	_redraw()
	return ok


func _toast(msg: String, tone := &"ok") -> void:
	UI3Meta.clear(_toast_host)
	_toast_host.add_child(Ui5Toast.make(msg, tone))
