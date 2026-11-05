extends Node
## Manual visual QA (non-headless), art batch 3+4+D: Profile frame preview for m_crystal and e_reef_01 (real
## ProfileView, real avatar), and the 26 dice thumbnails as two sheets of 13. Writes to $ADT_EVIDENCE_DIR.
var _guard := SaveGuard.new()


func _out() -> String:
	var o := OS.get_environment("ADT_EVIDENCE_DIR")
	return o if o != "" else QaPaths.evidence_dir()


func _wait(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(name: String) -> void:
	DirAccess.make_dir_recursive_absolute(_out())
	var p := "%s/%s.png" % [_out(), name]
	get_tree().root.get_texture().get_image().save_png(p)
	print("saved ", p)


func _ready() -> void:
	_guard.capture()
	var tag := OS.get_environment("QA_TAG") if OS.get_environment("QA_TAG") != "" else "1920"
	MetaState.tutorial_seen = true
	MetaState.cosmetics_owned.assign(["die_c_clay", "frame_m_crystal", "frame_e_reef_01", "frame_c_aqua"])
	MetaState.equipped_die_skin = "die_c_clay"
	MetaState.equipped_frame = "frame_m_crystal"
	AccountService.account = {"id": "google:qa", "name": "Liam", "email": "q@skymavis.com", "sky_mavis": true}
	AccountService.status = AccountServiceScript.Status.SAVED
	var pv: ProfileView = ProfileView.new()
	pv.no_scene_change = true
	pv.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(pv)
	pv.cat = "frame"
	pv.set_tab(1)
	for fid in ["frame_m_crystal", "frame_e_reef_01"]:
		pv.selected = fid
		pv.refresh()
		await _wait(90)
		_shot("profile-%s-%s" % [fid, tag])
	pv.queue_free()
	AccountService.account = {}
	AccountService.status = AccountServiceScript.Status.GUEST
	# thumbnail sheets, 13 per image
	var bg := ColorRect.new()
	bg.color = Color("2B1E17")
	bg.size = Vector2(1400, 600)
	add_child(bg)
	get_window().size = Vector2i(1400, 600)
	for f in DirAccess.get_files_at("user://thumbs"):
		DirAccess.remove_absolute("user://thumbs/" + f)
	var ids := DiceSkin.ids()
	for half in 2:
		var holder := Control.new()
		add_child(holder)
		for k in 13:
			var i := half * 13 + k
			if i >= ids.size():
				break
			var tex := await DiceThumb.get_thumb(self, String(ids[i]))
			var tr := TextureRect.new()
			tr.texture = tex
			tr.size = Vector2(200, 200)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.position = Vector2(5 + (k % 7) * 200, 5 + (k / 7) * 290)
			holder.add_child(tr)
			var l := Label.new()
			l.text = String(ids[i])
			l.position = tr.position + Vector2(4, 205)
			holder.add_child(l)
		await _wait(4)
		_shot("dice-thumbs-%d-of-2" % (half + 1))
		holder.queue_free()
	_guard.restore()
	get_tree().quit(0)
