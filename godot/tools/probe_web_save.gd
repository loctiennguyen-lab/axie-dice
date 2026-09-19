extends Node
## Round 2: the first save persists and every later one is silently lost (measured). This probe
## tests candidate REMEDIES so the bug report arrives with a fix instead of a shrug.

func _ready() -> void:
	await get_tree().process_frame
	var report: Array[String] = []

	# --- what the engine's own path does (the bug) ---------------------------
	var before := MetaState.runs
	MetaState.runs = before + 1
	MetaState.save_to_disk()
	report.append("engine_save: loaded=%d wrote=%d" % [before, MetaState.runs])

	# --- remedy 1: can GDScript reach Emscripten's FS to force a flush? ------
	var bridge := "unavailable"
	if OS.has_feature("web"):
		var probe: Variant = JavaScriptBridge.eval("(typeof FS)", true)
		bridge = "FS visible to eval: %s" % str(probe)
		var synced: Variant = JavaScriptBridge.eval(
			"(function(){try{FS.syncfs(false,function(){});return 'called';}catch(e){return 'threw: '+e;}})()",
			true)
		report.append("remedy_syncfs: %s / %s" % [bridge, str(synced)])
	else:
		report.append("remedy_syncfs: not a web build")

	# --- remedy 2: localStorage through the JS bridge ------------------------
	# Synchronous, and entirely ours: if this survives a reload, the save path has a home on
	# the web that does not depend on when Godot decides to flush its filesystem.
	var ls_prior := "none"
	if OS.has_feature("web"):
		var got: Variant = JavaScriptBridge.eval("window.localStorage.getItem('probe_runs')", true)
		ls_prior = str(got)
		var next := (int(ls_prior) if ls_prior.is_valid_int() else 0) + 1
		JavaScriptBridge.eval("window.localStorage.setItem('probe_runs','%d')" % next, true)
		report.append("remedy_localstorage: read=%s wrote=%d" % [ls_prior, next])

	for line in report:
		print("PROBE2 ", line)

	var label := Label.new()
	label.text = "\n".join(report) + "\n\nReload: engine_save 'loaded' and localStorage 'read'\nboth have to go up by 1."
	label.position = Vector2(40, 40)
	label.add_theme_font_size_override("font_size", 22)
	add_child(label)
