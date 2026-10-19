class_name AvatarFrame
extends RefCounted
## B12: wraps an avatar Control with an equipped cosmetic frame. Uses only CosmeticArt's public
## API (manifest, make_node) so the art loader can change underneath without touching this.


## Cosmetics R2 anchor rule: frame node = avatar x 1.5, same centre (window diameter 162 of 256, avatar 170.67).
const SCALE := 1.5


## Frame node size for an avatar of `avatar_px` (40 -> 60, 48 -> 72, 64 -> 96, 96 -> 144, 160 -> 240).
static func frame_size(avatar_px: float) -> float:
	return avatar_px * SCALE


## Top-left of the frame node relative to the avatar's top-left (-10 / -12 / -16 / -24 / -40).
static func frame_offset(avatar_px: float) -> Vector2:
	return -Vector2.ONE * (frame_size(avatar_px) - avatar_px) * 0.5


## `avatar` wrapped with frame `frame_id` drawn over it, `total_px` square; the avatar is sized to the
## frame's window. Unknown / empty frame: returns `avatar` at `fallback_px`, no wrapper.
## `avatar_px` > 0 fixes the avatar size (it may be a little bigger than the window: the frame's rim covers the
## overlap). Otherwise the avatar fills the window. Either way it is centred on the same point as the frame: the
## avatar's real size is used, because a PanelContainer never shrinks below its content (the "?" / initial label
## made the 37 px window avatar 41 x 42, and top-left placement pushed it down-right of the ring).
static func wrap(avatar: Control, total_px: float, frame_id: String, fallback_px: float, avatar_px: float = 0.0) -> Control:
	var entry: Variant = (CosmeticArt.manifest().get("frames", {}) as Dictionary).get(frame_id, null)
	var fr: Control = CosmeticArt.make_node(frame_id, total_px) if entry is Dictionary else null
	if fr == null:
		avatar.custom_minimum_size = Vector2(fallback_px, fallback_px)
		return avatar
	var e: Dictionary = entry
	var win := total_px * float(e.get("window_diameter_px", 168)) / float(e.get("size", 256))
	var root := Control.new()
	root.name = "FramedAvatar"
	root.custom_minimum_size = Vector2(total_px, total_px)
	root.size = Vector2(total_px, total_px)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var want := avatar_px if avatar_px > 0.0 else win
	avatar.custom_minimum_size = Vector2(want, want)
	var m := avatar.get_combined_minimum_size()
	var asz := Vector2(maxf(want, m.x), maxf(want, m.y))
	avatar.size = asz
	avatar.set_anchors_preset(Control.PRESET_TOP_LEFT)
	avatar.position = ((Vector2(total_px, total_px) - asz) * 0.5).round()
	root.add_child(avatar)
	root.add_child(fr)
	return root


## Land account chip (01): a holder exactly `avatar_px` square (so the plate never grows) with the avatar filling it
## and the frame node (avatar x 1.5, centred, mouse ignore) overflowing it. No / unknown frame: just the avatar
## at `avatar_px`. Layers are drawn by CosmeticArt (Tweens off under Reduce flashing).
static func wrap_holder(avatar: Control, avatar_px: float, frame_id: String) -> Control:
	var entry: Variant = (CosmeticArt.manifest().get("frames", {}) as Dictionary).get(frame_id, null)
	var fr: Control = CosmeticArt.make_node(frame_id, frame_size(avatar_px)) if entry is Dictionary else null
	avatar.custom_minimum_size = Vector2(avatar_px, avatar_px)
	if fr == null:
		return avatar
	var holder := Control.new()
	holder.name = "FramedAvatar"
	holder.custom_minimum_size = Vector2(avatar_px, avatar_px)
	holder.size = Vector2(avatar_px, avatar_px)
	holder.clip_contents = false
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	avatar.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.add_child(avatar)
	fr.position = frame_offset(avatar_px)
	fr.size = Vector2.ONE * frame_size(avatar_px)
	holder.add_child(fr)
	return holder


## Letter-disc avatar wearing frame `frame_id` (any frame, not only the equipped one) for previews: Profile
## detail, Echo Box reveal card. Node = avatar x 1.5 and `avatar_px` of avatar; "" = the bare disc.
static func letter_preview(frame_id: String, avatar_px: float, letter: String) -> Control:
	var av := PanelContainer.new()
	av.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("accent"), int(avatar_px * 0.5)))
	av.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ini := UI3.label(letter.left(1).to_upper(), "LabelDisplay")
	ini.add_theme_color_override("font_color", UI3Theme.color("accent_text"))
	ini.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ini.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	av.add_child(ini)
	return AvatarFrame.wrap(av, frame_size(avatar_px), frame_id, avatar_px, avatar_px)
