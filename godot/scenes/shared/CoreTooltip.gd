class_name CoreTooltip
extends RefCounted
## UI-06 L2: hover / focus tooltip of an owned Core or the Run Rule (frames 03-run-map--core-tooltip and
## --rule-tile-hover). Same structure as the card: CoreName, TierLine ("Amber · Stat"), headline, detail with chips,
## BadgeRow (family chip + tag badges), House line (AwakenProgress.house_tag). The Run Rule tooltip is
## "RunRuleTooltip": name, "Run rule · stays all run", detail. Shown on its own CanvasLayer, 440 wide at most, beside
## the slot (above when there is no room below). Pure view: nothing here touches game state.

const LAYER := "CoreTooltipLayer"
const MAX_W := 440.0

static var _gen := 0
static var _owner: Control = null


## Binds `c` to show the tooltip of `id`. Also keeps a plain-text copy in meta "ui3_tip" (what UI3Tooltip.text_of reads).
static func bind(c: Control, id: String, is_rule: bool, plain: String) -> void:
	c.tooltip_text = ""
	c.set_meta("ui3_tip", plain)
	c.set_meta("core_tip_id", id)
	c.set_meta("core_tip_rule", is_rule)
	if c.has_meta("core_tip_bound"):
		return
	c.set_meta("core_tip_bound", true)
	c.mouse_entered.connect(_arm.bind(c))
	c.mouse_exited.connect(hide_for.bind(c))
	c.focus_entered.connect(show_now.bind(c))
	c.focus_exited.connect(hide_for.bind(c))
	c.tree_exiting.connect(hide_for.bind(c))


static func _arm(c: Control) -> void:
	if not c.is_inside_tree():
		return
	_gen += 1
	var mine := _gen
	await c.get_tree().create_timer(UI3Theme.motion_sec("tooltip_delay_ms")).timeout
	if mine == _gen and is_instance_valid(c) and c.is_inside_tree() and c.get_global_rect().has_point(c.get_global_mouse_position()):
		show_now(c)


static func shown(tree: SceneTree) -> Control:
	var l := tree.root.get_node_or_null(LAYER)
	if l == null:
		return null
	var p := l.get_node_or_null("Plate") as Control
	return p if p != null and p.visible else null


static func hide_for(c: Control) -> void:
	_gen += 1
	if c == null or not c.is_inside_tree() or _owner != c:
		return
	hide_all(c.get_tree())


static func hide_all(tree: SceneTree) -> void:
	var l := tree.root.get_node_or_null(LAYER)
	if l != null:
		l.queue_free()
		l.name = LAYER + "_old"
	_owner = null


static func show_now(c: Control) -> void:
	if not c.is_inside_tree() or not c.is_visible_in_tree() or UI3Tooltip.modal_open(c.get_tree()):
		return
	hide_all(c.get_tree())
	var layer := CanvasLayer.new()
	layer.name = LAYER
	layer.layer = 120
	c.get_tree().root.add_child(layer)
	var tid := String(c.get_meta("core_tip_id", ""))
	var plate := build_anchor(tid) if tid.begins_with("a_") else build(tid, bool(c.get_meta("core_tip_rule", false)))
	plate.name = "Plate"
	plate.theme = UI3Theme.get_theme()
	layer.add_child(plate)
	_owner = c
	var vs := c.get_viewport().get_visible_rect().size
	plate.size = Vector2.ZERO
	var sz := plate.get_combined_minimum_size()
	plate.size = sz
	var r := c.get_global_rect()
	var pos := Vector2(r.position.x, r.end.y + 8.0)
	if pos.y + sz.y > vs.y - 8.0:
		pos.y = r.position.y - 8.0 - sz.y
	pos.x = clampf(pos.x, 8.0, maxf(8.0, vs.x - 8.0 - sz.x))
	plate.position = pos


## The tooltip plate for a Core / Run Rule id. Public so tests can inspect the tree without hovering.
static func build(id: String, is_rule: bool) -> PanelContainer:
	var def = RelicRegistry.get_def(id)
	var plate := PanelContainer.new()
	plate.name = "RunRuleTooltip" if is_rule else "CoreTooltip"
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("panel"), UI3Theme.radius("m"), 3, UI3Theme.color("text_muted")))
	var m := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, UI3Theme.space("16"))
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(m)
	var col := VBoxContainer.new()
	col.custom_minimum_size.x = MAX_W - 2.0 * UI3Theme.space("16")
	col.add_theme_constant_override("separation", UI3Theme.space("8"))
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(col)
	if def == null:
		col.add_child(UI3.label(id))
		return plate
	var tier := clampi(int(def.rarity), 0, 2)
	var axis := String(def.core_axis)
	var nm := UI3.label(UI3.title_case(UI3.player_text(String(def.name))), "LabelTitle")
	nm.name = "CoreName"
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(nm)
	var tl: Label
	if is_rule:
		tl = UI3.label(TranslationServer.translate("Run rule") + " · " + TranslationServer.translate("stays all run"), "LabelMuted")
		tl.name = "TierLine"
	else:
		tl = UI3.label("%s · %s" % [TranslationServer.translate(CoreVisuals.tier_name(tier)), CoreVisuals.family_name(axis)])
		tl.name = "TierLine"
		tl.add_theme_color_override("font_color", CoreVisuals.tier_text_color(tier))
	col.add_child(tl)
	if not is_rule:
		var hl := UI3.label("")
		hl.name = "Headline"
		hl.add_theme_color_override("font_color", UI3Theme.color("core_headline"))
		CoreHeadline.apply(hl, id)
		col.add_child(hl)
	var detail := RichTextLabel.new()
	detail.name = "Detail"
	detail.bbcode_enabled = true
	detail.fit_content = true
	detail.scroll_active = false
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail.add_theme_font_size_override("normal_font_size", UI3Theme.size_of("text_body"))
	detail.add_theme_color_override("default_color", UI3Theme.color("text"))
	detail.text = Chipify.bbcode(UI3.player_text(String(def.description)))
	detail.custom_minimum_size.x = MAX_W - 2.0 * UI3Theme.space("16")
	col.add_child(detail)
	if not is_rule:
		col.add_child(TagBadges.row(def.tags, axis))
		var ht := AwakenProgress.house_tag(id)
		if ht != null:
			ht.name = "HouseTag"
			col.add_child(ht)
		elif AnchorAdapter.has_anchor() and AnchorAdapter.is_house_core(id):
			var hn := UI3.label("%s %s" % [TranslationServer.translate("House Core of"), AnchorAdapter.house_name(AnchorAdapter.house_id(AnchorAdapter.current_id()))], "LabelMuted")
			hn.name = "HouseLine"
			col.add_child(hn)
	return plate


## Anchor tooltip: name, "Anchor · <House>", rule, price, awaken line, AwakenChip (n/2) and the house Cores (Owned marked).
static func build_anchor(id: String) -> PanelContainer:
	var plate := build("", false)   # empty shell with the same frame
	plate.name = "AnchorTooltip"
	var col := plate.get_child(0).get_child(0) as VBoxContainer
	for c in col.get_children():
		c.queue_free()
	var house := AnchorAdapter.house_id(id)
	var nm := UI3.label(AnchorAdapter.name_of(id), "LabelTitle")
	nm.name = "CoreName"
	col.add_child(nm)
	var tl := UI3.label("%s · %s" % [TranslationServer.translate("Anchor"), AnchorAdapter.house_name(house)])
	tl.name = "TierLine"
	tl.add_theme_color_override("font_color", AnchorAdapter.house_color(house))
	col.add_child(tl)
	var rule := RichTextLabel.new()
	rule.name = "Detail"
	rule.bbcode_enabled = true
	rule.fit_content = true
	rule.scroll_active = false
	rule.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rule.add_theme_font_size_override("normal_font_size", UI3Theme.size_of("text_body"))
	rule.add_theme_color_override("default_color", UI3Theme.color("text"))
	var txt := AnchorAdapter.rule_text(id)
	if AnchorAdapter.price_text(id) != "":
		txt += "\n" + AnchorAdapter.price_text(id)
	txt += "\n%s %s: %s" % [TranslationServer.translate("Awakens:"), AnchorAdapter.awaken_name(id), AnchorAdapter.awaken_rule(id)]
	rule.text = Chipify.bbcode(txt)
	rule.custom_minimum_size.x = MAX_W - 2.0 * UI3Theme.space("16")
	col.add_child(rule)
	var chip := AwakenProgress.chip()
	if chip != null:
		col.add_child(chip)
	var own := AnchorAdapter.owned()
	for cid in AnchorAdapter.house_cores(id):
		var d = RelicRegistry.get_def(String(cid))
		var l := UI3.label("%s %s" % [TranslationServer.translate("Owned") + ":" if own.has(cid) else "-", String(d.name) if d != null else String(cid)], "LabelMuted")
		l.name = "HouseCoreLine"
		col.add_child(l)
	return plate
