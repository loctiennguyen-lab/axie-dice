extends Node
## QA-only (UI-05 b1 QA, item 7): opens another capture scene with the design scale pinned the way the game pins it at
## 1280x720 (UI3Theme 2/3 override), so 1280 shots of the meta screens are comparable with the combat ones.
##   QA_PIN_SCENE=res://tests/qa_settings_capture.tscn godot/tools/shot.sh res://tests/qa_ui5_pin.tscn 1280x720
## At 1920 nothing is pinned (scale 1.0). The target scene does its own capture and quits.


func _ready() -> void:
	var target := OS.get_environment("QA_PIN_SCENE")
	var small := get_window().size.x < 1600
	UI3Theme.set_scale_override(2.0 / 3.0 if small else 1.0)
	print("QA_PIN scale=%s target=%s window=%s" % [2.0 / 3.0 if small else 1.0, target, get_window().size])
	await get_tree().process_frame
	get_tree().change_scene_to_file(target)
