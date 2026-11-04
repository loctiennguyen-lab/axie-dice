class_name TierFrame
extends NinePatchRect
## UI-06 card frame. NinePatchRect with the tier's material (Moss rough plank / Amber resin / Crystal facets) or the
## Run Rule plaque. Margins come from tokens.ninepatch (px of the 1920 PNG). The canvas is already scaled 2/3 at
## 1280 (stretch canvas_items), so margins stay in logical px and corners are never squeezed as long as the card
## is wider than both side margins plus a few px; fit_margins() shrinks them proportionally if a card is ever
## narrower than that (tooltips, strips). Edges use STRETCH. Mouse-transparent. Children go in a sibling Content
## node, never inside the frame.

var tier := 0
var run_rule := false
var _key := ""
## Art batch 1 (4/11): the frame PNGs have a transparent centre, so the card body is a flat plate panel drawn behind
## the frame ("BodyFill"). Its edge sits BODY_INSET px in, under the frame band (>= 31 px), scaled with the margins.
const BODY_INSET := 14.0
var _fill: Panel


## tier 0/1/2; run_rule = true uses the Run Rule plaque (tier is ignored).
func setup(p_tier: int, p_run_rule := false) -> TierFrame:
	tier = clampi(p_tier, 0, 2)
	run_rule = p_run_rule
	name = "TierFrame"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_STRETCH
	axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_STRETCH
	texture = UI6Assets.frame_run_rule() if run_rule else UI6Assets.frame(tier)
	_key = "frame_run_rule" if run_rule else "frame_core_" + UI6Assets.tier_key(tier)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if _fill == null:
		_fill = Panel.new()
		_fill.name = "BodyFill"
		_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_fill.show_behind_parent = true
		_fill.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("plate"), UI3Theme.radius("s"), 0))
		_fill.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(_fill)
	if not resized.is_connected(fit_margins):
		resized.connect(fit_margins)
	fit_margins()
	return self


## Patch margins for the current size: the token values, shrunk only when left+right (or top+bottom) would eat
## the card (keeping at least 24 px of stretchable centre).
func fit_margins() -> void:
	var m := UI6Assets.ninepatch_margins(_key)
	fit_patch(self, m)
	if _fill != null:
		var k := float(patch_margin_left) / maxf(1.0, float(m.x))
		inset_fill(_fill, BODY_INSET * k)


## Pulls a full-rect fill `inset` px in from every side.
static func inset_fill(c: Control, inset: float) -> void:
	c.offset_left = inset
	c.offset_top = inset
	c.offset_right = -inset
	c.offset_bottom = -inset


## Applies margins m = [L, T, R, B] to any NinePatchRect, shrunk proportionally when the rect is too small to keep
## 24 px of stretchable centre. Shared by TierFrame and ArtWindow.
static func fit_patch(np: NinePatchRect, m: Vector4i) -> void:
	var l := float(m.x)
	var t := float(m.y)
	var r := float(m.z)
	var b := float(m.w)
	var kx := minf(1.0, maxf(0.0, np.size.x - 24.0) / maxf(1.0, l + r)) if np.size.x > 0.0 else 1.0
	var ky := minf(1.0, maxf(0.0, np.size.y - 24.0) / maxf(1.0, t + b)) if np.size.y > 0.0 else 1.0
	np.patch_margin_left = int(l * kx)
	np.patch_margin_right = int(r * kx)
	np.patch_margin_top = int(t * ky)
	np.patch_margin_bottom = int(b * ky)
