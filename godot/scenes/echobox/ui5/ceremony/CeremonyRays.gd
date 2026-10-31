extends Control
## UI-05 S9b: RaysProposal (20-echo--reveal-rare-plus / -mythic, PROPOSAL, not yet approved). 8 bars in the rarity colour behind
## the art, alpha 0.3 at rest, fading out towards the rim (the HTML mask). It spins slowly for 2 s and settles
## (motion-batch3 "Rays behind the art"). Removed under Reduce motion and Reduce flashing by the caller.

var ray_color := Color.WHITE
var spin := true


func _init() -> void:
	name = "RaysProposal"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(func() -> void:
		pivot_offset = size * 0.5
		queue_redraw())


func _ready() -> void:
	pivot_offset = size * 0.5
	if spin:
		var tw := create_tween()
		tw.tween_property(self, "rotation_degrees", 30.0, 2.0).from(0.0).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.75
	var inner := Color(ray_color.r, ray_color.g, ray_color.b, 0.3)
	var outer := Color(ray_color.r, ray_color.g, ray_color.b, 0.0)
	var half := deg_to_rad(6.0)
	for i in 8:
		var a := TAU * float(i) / 8.0
		var pts := PackedVector2Array([c, c + Vector2.from_angle(a - half) * r, c + Vector2.from_angle(a + half) * r])
		draw_polygon(pts, PackedColorArray([inner, outer, outer]))
