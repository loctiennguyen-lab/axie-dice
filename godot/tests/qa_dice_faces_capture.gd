extends Node
## QA sheet: one die rendered face-on for each of its 6 surfaces (+X -X +Y -Y +Z -Z), turned with the
## same result_basis() the roller uses, so every thumbnail must read upright. NOT headless.
## Writes ui3-dice-faces.png to $ADT_EVIDENCE_DIR.

func _ready() -> void:
	get_window().size = Vector2i(1200, 800)
	var roller := DiceRoller3D.new()
	add_child(roller)
	var faces: Array = [
		{"type": "dmg", "value": 5}, {"type": "shield", "value": 2}, {"type": "heal", "value": 3},
		{"type": "poison", "value": 4}, {"type": "mana", "value": 1}, {"type": "buff", "value": 6}]
	await roller.prepare(faces)
	var bg := ColorRect.new()
	bg.color = Color("2B1E17")
	bg.size = Vector2(1200, 800)
	add_child(bg)
	for s in 6:
		var c := SubViewportContainer.new()
		c.stretch = true
		c.size = Vector2(380, 380)
		c.position = Vector2(10 + (s % 3) * 396, 10 + (s / 3) * 396)
		var vp := SubViewport.new()
		vp.own_world_3d = true
		vp.size = Vector2i(380, 380)
		c.add_child(vp)
		add_child(c)
		var cam := Camera3D.new()
		cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		cam.size = 1.5
		cam.position = Vector3(0, 0, 3)
		vp.add_child(cam)
		var sun := DirectionalLight3D.new()
		sun.rotation_degrees = Vector3(-20, 20, 0)
		vp.add_child(sun)
		var env := WorldEnvironment.new()
		env.environment = Environment.new()
		env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.environment.ambient_light_color = Color(0.7, 0.7, 0.72)
		vp.add_child(env)
		var die := DiceRoller3D.make_die_mesh(faces, 1.0)
		die.transform.basis = DiceRoller3D.result_basis(Basis.IDENTITY, s, Vector3.BACK, Vector3.UP) * die.transform.basis
		vp.add_child(die)
	for _i in 6:
		await RenderingServer.frame_post_draw
	var out := OS.get_environment("ADT_EVIDENCE_DIR")
	if out == "":
		out = ProjectSettings.globalize_path("res://").path_join("../production/qa/evidence").simplify_path()
	get_viewport().get_texture().get_image().save_png(out + "/ui3-dice-faces.png")
	print("QA: saved ui3-dice-faces")
	get_tree().quit(0)
