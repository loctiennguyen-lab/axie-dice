class_name AvatarFrame
extends RefCounted
## B12: wraps an avatar Control with an equipped cosmetic frame. Uses only CosmeticArt's public
## API (manifest, make_node) so the art loader can change underneath without touching this.


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
