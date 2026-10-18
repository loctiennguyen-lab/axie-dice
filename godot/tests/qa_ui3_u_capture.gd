extends Node
## QA (lane U): captures UI-03 round-2 meta screens. Not headless. Screens = env AXIE_U_SCREENS (comma list).
## godot/tools/with_lock.sh bash godot/tools/shot.sh res://tests/qa_ui3_u_capture.tscn 1920x1080
## Writes $ADT_EVIDENCE_DIR/ui3-<screen>-<W>x<H>.png (window size of the run).
var _guard := SaveGuard.new()


func _ready() -> void:
	_guard.capture()
	MetaState.tutorial_seen = true
	var list := OS.get_environment("AXIE_U_SCREENS").split(",", false)
	var dir := OS.get_environment("ADT_EVIDENCE_DIR")
	var win := DisplayServer.window_get_size()
	for sc in list:
		var node: Node = await _make(sc)
		for i in 20:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/ui3-%s-%dx%d.png" % [dir, sc, win.x, win.y])
		print("U_CAPTURE ", sc, " ", (node as Control).size if node is Control else "-", " ", node.get_child_count() if node != null else -1, " ", node.visible if node is CanvasItem else "")
		if node != null:
			node.queue_free()
		await get_tree().process_frame
	_guard.restore()
	get_tree().quit(0)


func _make(sc: String) -> Node:
	if sc.begins_with("pass"):
		MetaState.pass_season = PassV2.new_state("s1")
		MetaState.pass_season["xp"] = 3000 if sc != "pass-early" else 200
		MetaState.pass_season["level"] = 5 if sc != "pass-early" else 0
		MetaState.pass_season["claimed_free"] = [1, 2] if sc != "pass-early" else []
		var s: PassView = load("res://scenes/pass/Pass.tscn").instantiate()
		s.use_account = false
		s.no_scene_change = true
		s.today_override = "2026-11-10"
		add_child(s)
		await get_tree().process_frame
		if sc == "pass-popup":
			s.open_reward(5)
		elif sc == "pass-gift":
			s.select_level(10)
			s.open_reward(10)
		elif sc == "pass-guest":
			s.state = "guest"
			s.refresh()
		return s
	if sc.begins_with("vault"):
		MetaState.vault.clear()
		if sc != "vault-empty":
			for id in ["11778888", "2402", "910"]:
				var parts: Array = []
				for slot in ["mouth", "horn", "back", "tail", "eyes", "ears"]:
					parts.append({"id": "plant-%s" % slot, "name": "Leaf %s" % slot, "class": "plant", "type": slot, "specialGenes": null})
				MetaState.vault_import({"id": id, "class": "plant", "parts": parts, "genes": "0x1234"})
		var v: VaultView = load("res://scenes/vault/Vault.tscn").instantiate()
		v.use_account = false
		v.no_scene_change = true
		v.state = "guest" if sc == "vault-guest" else "normal"
		v.remote_on = sc == "vault-guest"
		add_child(v)
		await get_tree().process_frame
		if sc == "vault-lookup":
			v._id_field.text = "11778888"
			v._set_status("Looking up Axie #11778888…")
		elif sc == "vault-notfound":
			v._id_field.text = "99999999"
			v._on_fetch_completed({"ok": false, "message": "No Axie with ID 99999999 was found."})
		elif sc == "vault-error":
			v._id_field.text = "11778888"
			v._on_fetch_completed({"ok": false, "message": "Could not reach the Axie service. Check your connection and try again."})
		elif sc == "vault-remove":
			v._on_remove_pressed("2402")
		return v
	return null
