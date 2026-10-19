extends Node
## QA sheets for the 3D dice skins. NOT headless. Writes to $ADT_EVIDENCE_DIR:
##  cos3d-thumbs.png  (all 20 baked thumbnails, 5 x 4)
##  cos3d-faces-<skin>.png  (every face of three skins, face-on, from the plate renderer)

const FACE_SKINS := ["die_c_reed", "die_r_aqua", "die_l_gold"]


func _out() -> String:
	var out := OS.get_environment("ADT_EVIDENCE_DIR")
	if out == "":
		out = ProjectSettings.globalize_path("res://").path_join("../production/qa/evidence").simplify_path()
	return out


func _ready() -> void:
	get_window().size = Vector2i(1280, 1024)
	var bg := ColorRect.new()
	bg.color = Color("2B1E17")
	bg.size = Vector2(1280, 1024)
	add_child(bg)
	for f in DirAccess.get_files_at("user://thumbs"):
		DirAccess.remove_absolute("user://thumbs/" + f)   # QA always re-bakes
	var ids := DiceSkin.ids()
	for i in ids.size():
		var tex := await DiceThumb.get_thumb(self, String(ids[i]))
		var tr := TextureRect.new()
		tr.texture = tex
		tr.size = Vector2(250, 250)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.position = Vector2(5 + (i % 5) * 255, 5 + (i / 5) * 255)
		add_child(tr)
		var l := Label.new()
		l.text = String(ids[i])
		l.position = tr.position + Vector2(4, 230)
		add_child(l)
	for _i in 4:
		await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out() + "/cos3d-thumbs.png")
	for s in FACE_SKINS:
		await _faces(s)
	print("QA: saved cos3d sheets")
	get_tree().quit(0)


func _faces(skin: String) -> void:
	var faces: Array = [
		{"type": "dmg", "value": 5}, {"type": "shield", "value": 88}, {"type": "heal", "value": 188},
		{"type": "poison", "value": 4}, {"type": "mana", "value": 0}, {"type": "buff", "value": 6}]
	var roller := DiceRoller3D.new()
	add_child(roller)
	await roller.prepare(faces, skin)
	var holder := Control.new()
	add_child(holder)
	for s in 6:
		var st := DiceStage.new()
		st.setup(Vector2i(420, 480), skin, faces, false)
		st.position = Vector2(10 + (s % 3) * 420, 10 + (s / 3) * 490)
		holder.add_child(st)
		# camera straight at the face: undo the thumbnail pose and use result_basis
		st.pivot.basis = DiceRoller3D.result_basis(Basis.IDENTITY, s, (st.vp.get_camera_3d().global_position - st.pivot.global_position).normalized(), Vector3.UP)
	for _i in 6:
		await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out() + "/cos3d-faces-%s.png" % skin)
	holder.queue_free()
	roller.queue_free()
