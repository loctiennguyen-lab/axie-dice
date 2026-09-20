extends SceneTree
func _init() -> void:
	for spec in [[38,800,0.0],[9,700,0.06],[18,800,0.01],[17,700,0.02]]:
		var l := DangoTheme.display_label("88", int(spec[0]), DangoTheme.INK, int(spec[1]), float(spec[2]))
		var root := Control.new()
		root.add_child(l)
		get_root().add_child(root)
		print("size=", spec[0], " min=", l.get_combined_minimum_size(), " leading=",
			DangoTheme.leading_for(DangoTheme.FONT_DISPLAY, int(spec[0])),
			" fontH=", DangoTheme.FONT_DISPLAY.get_height(int(spec[0])))
		root.queue_free()
	quit()
