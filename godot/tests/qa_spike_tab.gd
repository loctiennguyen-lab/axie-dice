extends Control
## QA capture (6/11): an enemy plate with the "BIG HIT IN 2" tab (spike icon) next to a boss plate with the
## "ENRAGE IN 9" tab (boss-clock on its dark disc), on the forest backdrop colour, at the window size.
## Writes production/qa/icons-0611/spike-tab-<w>x<h>.png. Run through godot/tools/shot.sh (not headless).

func _ready() -> void:
	theme = UI3Theme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("#2f4a2a")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var row := HBoxContainer.new()
	row.position = Vector2(40, 40)
	row.add_theme_constant_override("separation", 40)
	add_child(row)
	for boss in [false, true]:
		var p := UnitPortrait.new()
		row.add_child(p)
		p.setup(100 + int(boss), "Mirror Chimera" if boss else "Bomblet", "", true, boss, "")
		p.set_nick("", "Mirror Chimera" if boss else "Bomblet")
		p.update_stats(152 if boss else 15, 152 if boss else 15, 0, {})
		p.set_intent({"show": true, "type": "dmg", "num": 27 if boss else 11, "label": "ATTACK", "target": "Olek", "big_hit": false})
		if boss:
			p.set_tab({"icon": HudKit.icon("boss-clock"), "text": "ENRAGE IN 9", "right": "then +20%/turn", "pips": []})
		else:
			p.set_tab({"bg": UI3Theme.color("accent"), "ink": UI3Theme.color("accent_text"), "icon": HudKit.icon("spike"),
				"text": "BIG HIT IN 2", "right": "HITS 30", "pips": []})
	for _i in 8:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var vs := get_viewport().get_visible_rect().size
	var dir := ProjectSettings.globalize_path("res://").path_join("../production/qa/icons-0611")
	DirAccess.make_dir_recursive_absolute(dir)
	get_viewport().get_texture().get_image().save_png(dir.path_join("spike-tab-%dx%d.png" % [int(vs.x), int(vs.y)]))
	get_tree().quit(0)
