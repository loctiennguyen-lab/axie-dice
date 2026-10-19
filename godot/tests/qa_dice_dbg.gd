extends Node
func _ready() -> void:
	get_window().size = Vector2i(1280, 400)
	var roller := DiceRoller3D.new()
	add_child(roller)
	var skin := "die_m_moon"
	await roller.prepare(DiceStage.THUMB_FACES, skin)
	for v in 5:
		var st := DiceStage.new()
		st.setup(Vector2i(250, 300), skin, DiceStage.THUMB_FACES, false)
		st.position = Vector2(v * 255, 0)
		add_child(st)
		var m: StandardMaterial3D = (st.die.get_surface_override_material(0) as StandardMaterial3D).duplicate()
		var f: StandardMaterial3D = (st.die.get_surface_override_material(3) as StandardMaterial3D).duplicate()
		match v:
			0: m.emission_enabled = false
			1: m.emission_energy_multiplier = 0.0; m.emission_texture = null
			2: pass
			3: m.uv1_triplanar = false
			4: m.emission_enabled = false; f.emission_enabled = false
		print(v, " body em ", m.emission_enabled, " e=", m.emission_energy_multiplier, " tex=", m.emission_texture)
		st.die.set_surface_override_material(0, m)
		for i in 6:
			st.die.set_surface_override_material(i + 1, f if v < 4 else f)
	for _i in 5:
		await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_environment("ADT_EVIDENCE_DIR") + "/dbg.png")
	get_tree().quit(0)
