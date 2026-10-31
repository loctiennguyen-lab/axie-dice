class_name NetParts
extends RefCounted
## UI-05 b23 lane S8b: pieces shared by NetNotice and UpdateRequired (frames 18-netnotice--*, 18-update--*).
## Source: design/handoffs/ui-05-figma/round-3/ui05-meta3-screens.html (.hud.plate, .netnotice, .update-bar, .scrim).

const PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")


## `.hud.plate` box: plate fill, rim, hard lip. `warn_rim` swaps the rim for notice_warn (the update bar). Padding per side.
static func hud_box(rad: String, pad_v: int, pad_l: int, pad_r: int, warn_rim := false) -> StyleBoxFlat:
	var rim := UI3Theme.color("notice_warn") if warn_rim else UI3Theme.color("plate_rim")
	return UI3Theme.flat(UI3Theme.color("plate"), UI3Theme.radius(rad), UI3Theme.stroke("rim"), rim,
		Vector4(pad_l, pad_v, pad_r, pad_v), PanelParts.lip(UI3Theme.color("plate_ink")))


## Scrim over the screen under the notice. Never takes the mouse: the notice never locks input (see NetNotice).
static func scrim(blocks_mouse := false) -> ColorRect:
	var s := ColorRect.new()
	s.name = "Scrim"
	s.color = UI3Theme.color("scrim")
	s.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	s.mouse_filter = Control.MOUSE_FILTER_STOP if blocks_mouse else Control.MOUSE_FILTER_IGNORE
	return s


## Space keycap on the trailing edge of a primary button (call once `b` is in the tree).
static func place_space_cap(b: Button) -> void:
	var cap := Ui5Keycap.make("Space", &"primary")
	b.add_child(cap)
	var pad := UI3Theme.space("16")
	Ui5HudStyle.place_trailing(b, cap, pad)
	b.resized.connect(func() -> void:
		if is_instance_valid(b) and is_instance_valid(cap):
			Ui5HudStyle.place_trailing(b, cap, pad))
