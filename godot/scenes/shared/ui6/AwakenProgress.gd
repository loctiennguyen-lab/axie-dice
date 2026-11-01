class_name AwakenProgress
extends RefCounted
## Awaken progress widgets shared by the Core offer (HouseTag), Cores strip / tooltip / menu (chip) and the Anchor
## card (meter). READ ONLY: counts come from AnchorAdapter (RunState / test_state), nothing here changes state.

## "n/2" for the current Anchor (0/2 without an Anchor).
static func count() -> int:
	return AnchorAdapter.house_count()


static func need() -> int:
	return Anchors.AWAKEN_NEED


static func text(n: int = -1) -> String:
	return "%d/%d" % [count() if n < 0 else n, need()]


## Row of `need()` pips, the first `n` lit in `color`. Name "AwakenPips". Mouse-transparent.
static func pips(n: int, color: Color, px: int = 12) -> HBoxContainer:
	var r := HBoxContainer.new()
	r.name = "AwakenPips"
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.add_theme_constant_override("separation", 4)
	for i in need():
		var p := Panel.new()
		p.custom_minimum_size = Vector2(px, px)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var lit := i < n
		p.add_theme_stylebox_override("panel", UI3Theme.flat(color if lit else Color(0, 0, 0, 0), UI3Theme.radius("pill"), 2, color))
		p.set_meta("lit", lit)
		r.add_child(p)
	return r


## Chip "<pips> n/2" in the Anchor's house colour. Name "AwakenChip"; children "AwakenPips" and "Count". Null when
## there is no Anchor. Awakened Anchors show a full 2/2.
static func chip() -> PanelContainer:
	var id := AnchorAdapter.current_id()
	if id == "":
		return null
	var col := AnchorAdapter.house_color(AnchorAdapter.house_id(id))
	var n := need() if AnchorAdapter.awakened() else count()
	var c := UI3.icon_chip(text(n), null, col, "AwakenChip")
	var row := c.get_child(0) as HBoxContainer
	row.add_child(pips(n, col))
	row.move_child(row.get_child(row.get_child_count() - 1), 0)
	var l := c.find_child("Text", true, false) as Label
	if l != null:
		l.name = "Count"
	c.set_meta("n", n)
	return c


## "+1 to awaken" / "Awakens" tag for a House Core of the current Anchor, in the house colour with the house emblem.
## Name "HouseTag", meta "state" = "awakens" | "plus_one". Null when this Core is not a House Core, or the Anchor
## has already awakened.
static func house_tag(core_id: String) -> PanelContainer:
	if not AnchorAdapter.has_anchor() or AnchorAdapter.awakened() or not AnchorAdapter.is_house_core(core_id):
		return null
	var house := AnchorAdapter.house_id(AnchorAdapter.current_id())
	var wa := AnchorAdapter.would_awaken(core_id)
	var label := TranslationServer.translate("Awakens") if wa else TranslationServer.translate("+1 to awaken")
	var c := UI3.icon_chip(label, UI6Assets.house(house, 32), AnchorAdapter.house_color(house), "HouseTag")
	c.set_meta("state", "awakens" if wa else "plus_one")
	return c
