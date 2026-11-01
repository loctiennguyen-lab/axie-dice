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
	if not resized.is_connected(fit_margins):
		resized.connect(fit_margins)
	fit_margins()
	return self


## Patch margins for the current size: the token values, shrunk only when left+right (or top+bottom) would eat
## the card (keeping at least 24 px of stretchable centre).
func fit_margins() -> void:
	fit_patch(self, UI6Assets.ninepatch_margins(_key))


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
