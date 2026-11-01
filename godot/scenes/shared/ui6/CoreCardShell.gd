class_name CoreCardShell
extends Control
## UI-06 CoreCard / RuleCard skeleton. Builds, with the HTML frame's node names: TierFrame, TierCrest (Core only),
## Content > Body (VBox) > ArtWindow > FamilyEmblem (Core only). Lanes add Name / Headline / Detail / BadgeRow /
## Reroll to `body`. Size = token core_card_w x core_card_h (rule_card_* for a Run Rule); content inset =
## core_pad, plus half the crest height on top so nothing sits under the crest. A Run Rule shell is the walnut
## plaque: no crest, no art window.
##   var card := CoreCardShell.new().setup(tier, "stat")
##   card.body.add_child(name_label) ...

var tier := 0
var is_rule := false
var frame: TierFrame
var crest: TierCrest
var art_window: ArtWindow
var content: MarginContainer
var body: VBoxContainer


## `family` is a core_axis ("stat" ... "rule"); ignored for a Run Rule. Combo / cap cards: pass art_height_scale 0.6
## and emblem_scale 0.7 (design).
func setup(p_tier: int, family: String, p_is_rule := false, art_height_scale := 1.0, emblem_scale := 1.0) -> CoreCardShell:
	tier = clampi(p_tier, 0, 2)
	is_rule = p_is_rule
	name = "RuleCard" if is_rule else "CoreCard"
	mouse_filter = Control.MOUSE_FILTER_PASS
	custom_minimum_size = Vector2(UI3Theme.size_of("rule_card_w" if is_rule else "core_card_w"),
		UI3Theme.size_of("rule_card_h" if is_rule else "core_card_h"))
	frame = TierFrame.new().setup(tier, is_rule)
	add_child(frame)
	content = MarginContainer.new()
	content.name = "Content"
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var pad := UI3Theme.size_of("core_pad")
	for side in ["left", "right", "bottom"]:
		content.add_theme_constant_override("margin_" + side, pad)
	var top := pad
	if not is_rule:
		top += int(UI3Theme.size_of("shards_h") * 0.5)
	content.add_theme_constant_override("margin_top", top)
	add_child(content)
	body = VBoxContainer.new()
	body.name = "Body"
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_theme_constant_override("separation", 8)
	content.add_child(body)
	if not is_rule:
		art_window = ArtWindow.new().setup(tier, family, art_height_scale, emblem_scale)
		body.add_child(art_window)
		crest = TierCrest.new().setup(tier)
		add_child(crest)
		crest.place_on(custom_minimum_size)
		if not resized.is_connected(_place_crest):
			resized.connect(_place_crest)
	return self


func _place_crest() -> void:
	if crest != null:
		crest.place_on(size)
