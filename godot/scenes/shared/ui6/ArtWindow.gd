class_name ArtWindow
extends Control
## UI-06 Core card art window: the tier's art-window nine-patch ("ArtWindowFrame") with the family emblem
## ("FamilyEmblem") centred in it. Height = token size.core_art_h, emblem = size.core_emblem (both already
## 1280-aware through UI3Theme.size_of). `emblem_scale` < 1 shrinks the emblem (design: 0.7 when a combo/cap strip
## shares the card, and the window itself shrinks to 60%: set `height_scale`).

const EMBLEM_BOOST := 1.5   # Liam 2/11: library emblems read small in the window (art-director review), so emblem x1.5 ...
const WINDOW_BOOST := 1.1   # ... and the window grows 10% (25% pushed a long-text card's Reroll onto the frame edge)

var tier := 0
var emblem: TextureRect
var frame: NinePatchRect
## Art batch 1 (4/11): the window PNG is an empty frame; the inside is a flat tier_<tier>_bg panel behind it ("WindowFill").
const FILL_INSET := 10.0
const BAND_K := 0.8
var _fill: Panel


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
	_fill = Panel.new()
	_fill.name = "WindowFill"
	_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fill.show_behind_parent = true
	_fill.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("tier_%s_bg" % UI6Assets.tier_key(tier)), UI3Theme.radius("s"), 0))
	_fill.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.add_child(_fill)
	var key := "artwin_" + UI6Assets.tier_key(tier)
	if not frame.resized.is_connected(_fit):
		frame.resized.connect(_fit)
	_fit_key = key
	_fit()
	var cc := CenterContainer.new()
	cc.name = "EmblemCenter"
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cc.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(cc)
	var es := float(UI3Theme.size_of("core_emblem")) * emblem_scale * EMBLEM_BOOST
	# Art batch 1 (4/11): the window is a framed opening now (band ~0.8 x the patch margin). Centre the emblem on the
	# opening and cap it so the picture (~90 % of the PNG) stays inside it instead of riding over the band.
	var m := UI6Assets.ninepatch_margins(_fit_key)
	cc.offset_top = BAND_K * m.y
	cc.offset_bottom = -BAND_K * m.w
	es = minf(es, (custom_minimum_size.y - BAND_K * (m.y + m.w)) * 1.1)
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
	var m := UI6Assets.ninepatch_margins(_fit_key)
	TierFrame.fit_patch(frame, m)
	if _fill != null:
		TierFrame.inset_fill(_fill, FILL_INSET * float(frame.patch_margin_left) / maxf(1.0, float(m.x)))
