class_name AvatarFrame
extends RefCounted
## B12: wraps an avatar Control with an equipped cosmetic frame. Uses only CosmeticArt's public
## API (manifest, make_node) so the art loader can change underneath without touching this.


## `avatar` wrapped with frame `frame_id` drawn over it, `total_px` square; the avatar is sized to the
## frame's window. Unknown / empty frame: returns `avatar` at `fallback_px`, no wrapper.
static func wrap(avatar: Control, total_px: float, frame_id: String, fallback_px: float) -> Control:
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
	avatar.custom_minimum_size = Vector2(win, win)
	avatar.size = Vector2(win, win)
	avatar.position = Vector2((total_px - win) * 0.5, (total_px - win) * 0.5)
	root.add_child(avatar)
	root.add_child(fr)
	return root
