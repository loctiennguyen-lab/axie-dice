class_name LandUpgradeScreen
extends Control
## M15 Land upgrade (key L). Spec: design/handoffs/ui-02-round3 README section 2 M15, frames
## M15a-M15e. Six tier rows: thumbnail, name, what it adds, cost + cumulative, button.
## Costs and the on/off switch come from EconomyDB land_tiers.json only. While
## `upgrade_enabled` is false (L1) every button reads "Not in this build" and prices stay readable.
## Spending goes through MetaState.upgrade_land() (ledgered). Confirm says it cannot be undone.

const _Shell := preload("res://scenes/shared/R3Shell.gd")
const _Eco := preload("res://scripts/meta/economy_db.gd")
const TIER_NAMES: Array[String] = ["Savannah", "Forest", "Arctic", "Mystic", "Genesis", "LunaLanding"]
const ROW_H := 84.0
## Thumbnail colours per tier (the Land's ground tone); the Land itself draws the real look.
const TIER_TINT: Array[String] = ["F2B652", "8DCB5A", "BFE3F2", "9A7BD0", "5FBF9A", "E8D27A"]
## Tier gates that Land.gd reads from houses.json are listed here only by name.
const ADDS: Dictionary = {
	2: "+3 preset slots · new decor set",
	3: "+3 preset slots · Mastery house [INF]",
	4: "New decor set [INF]",
	5: "Gallery [INF]",
	6: "Final Land · new decor set [INF]",
}

var no_scene_change := false
var _shell: Dictionary
var _rows: VBoxContainer
var _stone_lbl: Label
var _toast_host: VBoxContainer
var _modal: Control


func _ready() -> void:
	_shell = _Shell.build(self, "Land upgrade", "Land Stone buys the next Land", _on_back)
	var right: HBoxContainer = _shell["header_right"]
	_stone_lbl = _Shell.label("", 20, DangoTheme.INK_ON_PRIMARY, true)
	_stone_lbl.name = "StoneLabel"
	right.add_child(_stone_lbl)
	var col: VBoxContainer = _shell["col"]
	var pad := MarginContainer.new()
	pad.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for s in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + s, 24 if s in ["left", "right"] else 16)
	col.add_child(pad)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	pad.add_child(v)
	_toast_host = VBoxContainer.new()
	_toast_host.name = "ToastHost"
	v.add_child(_toast_host)
	_rows = VBoxContainer.new()
	_rows.name = "Rows"
	_rows.add_theme_constant_override("separation", 8)
	v.add_child(_Shell.fit_in(_rows, _shell["panel"], 64.0 + 32.0 + 40.0))
	_redraw()


func _unhandled_key_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_ESCAPE:
		if _modal != null:
			_close_modal()
		else:
			_on_back()
		get_viewport().set_input_as_handled()


func _on_back() -> void:
	if is_inside_tree() and not no_scene_change:
		LandNav.back_to_land()


static func fmt(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	for i in s.length():
		if i > 0 and (s.length() - i) % 3 == 0:
			out += ","
		out += s[i]
	return ("-" if n < 0 else "") + out


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
	_stone_lbl.text = "Stone %s" % fmt(MetaState.stone)
	_Shell.clear(_rows)
	var max_t := _Eco.land_max_tier()
	for tier in range(1, max_t + 1):
		_rows.add_child(_row(tier))
	if MetaState.land_tier >= max_t:
		var l := _Shell.label("Top tier reached. Nothing to buy.", 16, DangoTheme.INK_ON_CREAM_MUTED)
		l.name = "MaxNote"
		_rows.add_child(l)


func _row(tier: int) -> Control:
	var st := row_state(tier)
	var p := PanelContainer.new()
	p.name = "Tier%d" % tier
	p.custom_minimum_size = Vector2(0, ROW_H)
	var cur := st == "current"
	p.add_theme_stylebox_override("panel", _Shell.surface(
		DangoTheme.Surface.CREAM_RAISED, 16, 4 if cur else 3, Vector2(12, 8),
		DangoTheme.CREAM_DISABLED if st == "done" else null,
		DangoTheme.PRIMARY if cur else null))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	p.add_child(h)
	var thumb := Panel.new()
	thumb.custom_minimum_size = Vector2(110, 62)
	var tb := _Shell.surface(DangoTheme.Surface.CREAM_RAISED, 12, 3, Vector2(0, 0), Color(TIER_TINT[tier - 1]))
	thumb.add_theme_stylebox_override("panel", tb)
	h.add_child(thumb)
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 2)
	h.add_child(mid)
	var name_txt := "%s Land" % TIER_NAMES[tier - 1]
	if cur:
		name_txt += " · you are here"
	mid.add_child(_Shell.label(name_txt, 22, DangoTheme.INK, true))
	var adds := _Shell.label(String(ADDS.get(tier, "Starting Land")), 14, DangoTheme.INK_ON_CREAM_MUTED)
	adds.name = "Adds"
	mid.add_child(adds)
	var cost_box := VBoxContainer.new()
	cost_box.custom_minimum_size = Vector2(190, 0)
	cost_box.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(cost_box)
	if tier > 1:
		var c := _Shell.label("%s Stone" % fmt(_Eco.land_tier_cost(tier - 1)), 20, DangoTheme.INK, true)
		c.name = "Cost"
		cost_box.add_child(c)
		if tier > MetaState.land_tier:
			var cu := _Shell.label("%s total from here" % fmt(cumulative(tier)), 13, DangoTheme.INK_ON_CREAM_MUTED)
			cu.name = "Cumulative"
			cost_box.add_child(cu)
	var b := _Shell.button(_button_text(tier, st), 190, 48, st == "afford")
	b.name = "Btn"
	b.disabled = st != "afford"
	b.pressed.connect(_ask.bind(tier))
	h.add_child(b)
	return p


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
	_modal = _Shell.confirm(_shell["modal_layer"], "Spend %s Stone?" % fmt(cost),
		"%s becomes %s. This cannot be undone.\nStone after: %s." % [
			TIER_NAMES[tier - 2], TIER_NAMES[tier - 1], fmt(MetaState.stone - cost)],
		"Keep Stone", "Upgrade to %s" % TIER_NAMES[tier - 1], confirm_upgrade, _close_modal)


func _close_modal() -> void:
	if _modal != null:
		_modal.queue_free()
		_modal = null


## Runs the upgrade (also what the confirm button calls). True when the tier went up.
func confirm_upgrade() -> bool:
	_close_modal()
	var ok := MetaState.upgrade_land()
	if ok:
		_toast("Your Land is now %s" % TIER_NAMES[MetaState.land_tier - 1])
	else:
		_toast("Could not upgrade")
	_redraw()
	return ok


func _toast(msg: String) -> void:
	_Shell.clear(_toast_host)
	var l := _Shell.label(msg, 18, DangoTheme.INK, true)
	l.name = "Toast"
	_toast_host.add_child(l)
