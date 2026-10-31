extends Node
## UI-05 b23 lane S13: Codex frames at 1920x1080 and 1280x720. Not headless: godot/tools/shot.sh res://tests/qa_ui5_codex_capture.tscn
## Writes production/qa/ui05-b23/s13/29-codex--<state>[--1280].png
var _guard := SaveGuard.new()


func _ready() -> void:
	_guard.capture()
	var out := ProjectSettings.globalize_path("res://").path_join("../production/qa/ui05-b23/s13").simplify_path()
	DirAccess.make_dir_recursive_absolute(out)
	await get_tree().process_frame
	MetaState.reload_from_store()
	var ids: Array = []
	for d in RelicRegistry.all_defs_sorted():
		if RelicSlots.is_core(d) and not d.disabled and int(d.rarity) <= 2 and ids.size() < 8:
			ids.append(String(d.id))
	MetaState.core_codex = {}
	for i in ids:
		MetaState.core_codex[i] = {"seen": true, "picked": true}
	MetaState.anchor_codex = {"a_volley": {"seen": true, "picked": true, "awakened": true}}
	for size in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		UI3Theme.set_scale_override(1.0 if size.x >= 1920 else 2.0 / 3.0)
		get_window().size = size
		var sfx := "" if size.x >= 1920 else "--1280"
		for st in ["basics", "cores", "combos", "anchors", "anchor-detail", "search", "search-none"]:
			var v: Node = (load("res://scenes/codex/Codex.tscn") as PackedScene).instantiate()
			add_child(v)
			for _i in 4:
				await get_tree().process_frame
			match st:
				"basics": v._select_tab("basic")
				"cores": v._select_tab("cores")
				"combos": v._select_tab("combos")
				"anchors": v._select_tab("anchors")
				"anchor-detail":
					v._select_tab("anchors")
					v.tile_for("a_volley").activated.emit()
				"search":
					v._search.text = "poison"
					v._on_search_changed("poison")
				"search-none":
					v._search.text = "zzqx"
					v._on_search_changed("zzqx")
			for _i in 10:
				await get_tree().process_frame
			get_viewport().get_texture().get_image().save_png("%s/29-codex--%s%s.png" % [out, st, sfx])
			v.queue_free()
			await get_tree().process_frame
		for pair in [["res://scenes/guides/Guides.tscn", "guides"], ["res://scenes/unlocks/Unlocks.tscn", "unlocks"], ["res://scenes/combat/InfoPanelView.tscn", "infopanel-keywords"]]:
			var w: Node = (load(pair[0]) as PackedScene).instantiate()
			if w.get("no_scene_change") != null:
				w.set("no_scene_change", true)
			add_child(w)
			for _i in 4:
				await get_tree().process_frame
			if pair[1] == "infopanel-keywords":
				w.setup(null, [])
				w._select_tab("kw")
			for _i in 10:
				await get_tree().process_frame
			get_viewport().get_texture().get_image().save_png("%s/%s%s.png" % [out, pair[1], sfx])
			w.queue_free()
			await get_tree().process_frame
	UI3Theme.set_scale_override(-1.0)
	_guard.restore()
	get_tree().quit(0)
