class_name ArtWindow
extends Control
## UI-06 Core card art window: the tier's art-window nine-patch ("ArtWindowFrame") with the family emblem
## ("FamilyEmblem") centred in it. Height = token size.core_art_h, emblem = size.core_emblem (both already
## 1280-aware through UI3Theme.size_of). `emblem_scale` < 1 shrinks the emblem (design: 0.7 when a combo/cap strip
## shares the card, and the window itself shrinks to 60%: set `height_scale`).

const EMBLEM_BOOST := 1.5   # Liam 2/11: library emblems read small in the window (art-director review), so emblem x1.5 ...
const WINDOW_BOOST := 1.25  # ... and the window grows 25% so it still fits

var tier := 0
var emblem: TextureRect
var frame: NinePatchRect


func setup(p_tier: int, family: String, height_scale := 1.0, emblem_scale := 1.0) -> ArtWindow:
	tier = clampi(p_tier, 0, 2)
	name = "ArtWindow"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0, UI3Theme.size_of("core_art_h") * height_scale * WINDOW_BOOST)
	frame = NinePatchRect.new()
	frame.name = "ArtWindowFrame"
	frame.texture = UI6Assets.artwin(tier)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_STRETCH
	frame.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_STRETCH
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(frame)
	var key := "artwin_" + UI6Assets.tier_key(tier)
	if not frame.resized.is_connected(_fit):
		frame.resized.connect(_fit)
	_fit_key = key
	_fit()
	var cc := CenterContainer.new()
	cc.name = "EmblemCenter"
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(cc)
	var es := float(UI3Theme.size_of("core_emblem")) * emblem_scale * EMBLEM_BOOST
	emblem = TextureRect.new()
	emblem.name = "FamilyEmblem"
	emblem.texture = UI6Assets.family(family if UI6Assets.FAMILIES.has(family) else "stat", es)
	emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	emblem.custom_minimum_size = Vector2(es, es)
	emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cc.add_child(emblem)
	return self


var _fit_key := ""


func _fit() -> void:
	TierFrame.fit_patch(frame, UI6Assets.ninepatch_margins(_fit_key))
