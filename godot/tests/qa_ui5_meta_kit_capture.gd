extends Node
## UI-05 b23 lane 0d: screenshot of the meta kit sheet (run through tools/shot.sh, not headless).
const Demo := preload("res://tests/ui5_meta_kit_demo.gd")
const Util := preload("res://tests/qa_ui5_util.gd")

func _ready() -> void:
	UI3Theme.sync_scale()
	var layer := CanvasLayer.new()
	add_child(layer)
	Demo.build(layer)
	for i in 6:
		await get_tree().process_frame
	Util.save(get_viewport(), "components-meta-kit")
	get_tree().quit(0)
