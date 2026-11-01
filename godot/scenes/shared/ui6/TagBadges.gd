class_name TagBadges
extends RefCounted
## Which Core tags get a badge, in which order (Liam 1/11): only attack, tradeoff, convert_to_dmg, front, egg.
## nonattack is hidden, meme has no badge. tradeoff goes first and is the only red badge. At most 3 badges (the
## family chip is extra). Everything else in `tags` is ignored, data order is kept for the rest.

const SHOWN := ["attack", "tradeoff", "convert_to_dmg", "front", "egg"]
const MAX_BADGES := 3
const LABEL := {"attack": "Attack", "tradeoff": "Tradeoff", "convert_to_dmg": "Turns into damage",
	"front": "Front row", "egg": "Egg"}


## Tags to show, already ordered and capped. `tags` is a core's tags (PackedStringArray / Array).
static func pick(tags) -> Array:
	var out: Array = []
	var seen := {}
	for t in tags:
		seen[String(t)] = true
	if seen.has("tradeoff"):
		out.append("tradeoff")
	for t in tags:
		var s := String(t)
		if s != "tradeoff" and SHOWN.has(s) and not out.has(s):
			out.append(s)
	return out.slice(0, MAX_BADGES)


static func label_of(tag: String) -> String:
	return TranslationServer.translate(String(LABEL.get(tag, tag)))


## One TagBadge node: icon + word. Tradeoff text is danger red (tradeoff_text), the others cream. Name "TagBadge",
## meta "tag".
static func badge(tag: String) -> PanelContainer:
	var border := UI3Theme.color("tradeoff_text") if tag == "tradeoff" else UI3Theme.color("text_muted")
	var px := float(UI3Theme.size_of("badge"))
	var c := UI3.icon_chip(label_of(tag), UI6Assets.badge(tag, px), border, "TagBadge")
	c.set_meta("tag", tag)
	var ic := c.find_child("Icon", true, false) as TextureRect
	if ic != null:
		ic.custom_minimum_size = Vector2(px, px)
	var tx := c.find_child("Text", true, false) as Label
	if tx != null and tag == "tradeoff":
		tx.add_theme_color_override("font_color", UI3Theme.color("tradeoff_text"))
	return c


## BadgeRow: FamilyChip first (when `axis` != ""), then pick(tags) badges. Name "BadgeRow".
static func row(tags, axis := "") -> HFlowContainer:
	var r := HFlowContainer.new()
	r.name = "BadgeRow"
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.alignment = FlowContainer.ALIGNMENT_CENTER
	r.add_theme_constant_override("h_separation", 8)
	r.add_theme_constant_override("v_separation", 8)
	if axis != "":
		r.add_child(CoreVisuals.family_chip(axis))
	for t in pick(tags):
		r.add_child(badge(String(t)))
	return r
