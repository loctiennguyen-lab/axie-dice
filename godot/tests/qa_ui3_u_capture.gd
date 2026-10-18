extends Node
## QA (lane U): captures UI-03 round-2 meta screens. Not headless. Screens = env AXIE_U_SCREENS (comma list).
## godot/tools/with_lock.sh bash godot/tools/shot.sh res://tests/qa_ui3_u_capture.tscn 1920x1080
## Writes $ADT_EVIDENCE_DIR/ui3-<screen>-<W>x<H>.png (window size of the run).
var _guard := SaveGuard.new()
## A real Axie gene string (same as qa_vault_combat_capture); fake genes render as "0/6 parts".
const GENES := "0x180000000000030002018040810800000001000c080043040001000c0800800200010014084083020001000c1860430600010008100085060001000408604506"


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
	if sc.begins_with("chip"):
		var svc2 := AccountService
		if sc == "chip-in":
			svc2.account = {"id": "google:qa", "name": "Loc Tien", "sky_mavis": true}
			svc2.status = AccountServiceScript.Status.SAVED
		else:
			svc2.account = {}
			svc2.status = AccountServiceScript.Status.GUEST
		var host := Control.new()
		host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		host.theme = UI3Theme.get_theme()
		var bg := ColorRect.new()
		bg.color = UI3Theme.color("bg")
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		host.add_child(bg)
		var chip := AccountUI.build_chip(svc2, func() -> void: pass)
		chip.position = Vector2(40, 40)
		host.add_child(chip)
		add_child(host)
		return host
	if sc.begins_with("acct"):
		var svc := AccountService
		var layer: CanvasLayer = svc._ui_layer()
		var info := {"local": {"shards": 60, "xp": 340, "vault": 3, "runs": 12, "wins": 4, "run": "Short · Ascension 0"},
			"cloud": {"shards": 25, "xp": 820, "vault": 6, "runs": 20, "wins": 7, "run": "",
				"updated_at": int(Time.get_unix_time_from_system()) - 3 * 86400}}
		match sc:
			"acct-welcome": return AccountUI.show_welcome(layer)
			"acct-choose": return AccountUI.show_choice(layer, "choose", info, func(_c: String) -> void: pass)
			"acct-conflict": return AccountUI.show_choice(layer, "conflict", info, func(_c: String) -> void: pass)
			"acct-move": return AccountUI.show_choice(layer, "move", info, func(_c: String) -> void: pass)
			_: return AccountUI.show_toast(layer, "access_denied")
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
	if sc.begins_with("codex") or sc.begins_with("guides") or sc.begins_with("unlocks"):
		MetaState.shard_pool = 400
		var scn: String = {"codex": "res://scenes/codex/Codex.tscn", "guides": "res://scenes/guides/Guides.tscn",
			"unlocks": "res://scenes/unlocks/Unlocks.tscn"}[sc.split("-")[0]]
		var cs: Control = load(scn).instantiate()
		add_child(cs)
		await get_tree().process_frame
		if sc == "codex-status":
			cs._select_tab("st")
		elif sc == "codex-search":
			cs._search.text = "shield"
			cs._on_search_changed("shield")
		elif sc == "codex-empty":
			cs._search.text = "zzzq"
			cs._on_search_changed("zzzq")
		return cs
	if sc.begins_with("echo"):
		MetaState.tickets = {"normal": 0 if sc == "echo-none" else 3}
		MetaState.shard_pool = 900
		var es: EchoBoxScreen = load("res://scenes/echobox/EchoBoxScreen.tscn").instantiate()
		es.use_account = false
		es.no_scene_change = true
		es.instant = true
		add_child(es)
		await get_tree().process_frame
		if sc == "echo-seasonal":
			es.select_tab("seasonal")
		return es
	if sc.begins_with("vault"):
		MetaState.vault.clear()
		if sc != "vault-empty":
			for id in ["11778888", "2402", "910"]:
				var parts: Array = []
				for slot in ["mouth", "horn", "back", "tail", "eyes", "ears"]:
					parts.append({"id": "plant-%s" % slot, "name": "Leaf %s" % slot, "class": "plant", "type": slot, "specialGenes": null})
				MetaState.vault_import({"id": id, "class": "plant", "parts": parts, "genes": GENES})
		var v: VaultView = load("res://scenes/vault/Vault.tscn").instantiate()
		v.use_account = false
		v.no_scene_change = true
		v.state = "guest" if sc == "vault-guest" else "normal"
		v.remote_on = sc == "vault-guest"
		add_child(v)
		await get_tree().process_frame
		if sc == "vault-lookup":
			v._id_field.text = "11778888"
			var lp: Array = []
			for slot in ["mouth", "horn", "back", "tail", "eyes", "ears"]:
				lp.append({"id": "plant-%s" % slot, "name": "Leaf %s" % slot, "class": "plant", "type": slot})
			v._on_fetch_completed({"ok": true, "axie": {"id": "11778888", "class": "plant", "parts": lp, "genes": GENES}})
		elif sc == "vault-lookup-bad":
			v._id_field.text = "11778888"
			v._on_fetch_completed({"ok": true, "axie": {"id": "11778888", "class": "plant", "parts": [], "genes": "0x01"}})
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
