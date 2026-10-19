extends Node
## SkillVfxLayer.play_on_unit: a self clip (start-of-fight mana/buff) stays on its unit, small and unrotated;
## a cross-field clip never exceeds the clamped scale. Run: godot --headless --path godot res://tests/t_skill_vfx_self.tscn
var _fails := 0


func _check(ok: bool, msg: String) -> void:
	if not ok:
		_fails += 1
		print("FAIL: ", msg)


func _ready() -> void:
	var layer := SkillVfxLayer.new()
	add_child(layer)
	var pos := Vector2(300, 500)
	_check(layer.play_on_unit("plant_cast", pos), "self clip plays")
	var e: Dictionary = layer._active[0]
	_check(e["origin"] == pos and is_zero_approx(float(e["rot"])), "self clip is on the unit, unrotated")
	_check(float(e["scale"]) <= 0.6, "self clip is small (%s)" % e["scale"])
	_check(not layer.play_on_unit("no_such_clip", pos), "unknown clip returns false")
	layer.stop_all()
	_check(layer.play("plant_cast", Vector2(200, 500), Vector2(1700, 500)), "cross-field clip plays")
	_check(float((layer._active[0] as Dictionary)["scale"]) <= 1.3 + 0.001, "cross-field scale is clamped")
	print("t_skill_vfx_self: ", "PASS - checks OK" if _fails == 0 else "FAIL %d" % _fails)
	get_tree().quit(1 if _fails > 0 else 0)
