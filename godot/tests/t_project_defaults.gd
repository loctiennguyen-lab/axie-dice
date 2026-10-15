extends Node
## L1 B1: the shipped project defaults turn on server-rolled dice and the remote Gem wallet.
## Tests that need local dice must force it themselves, not rely on this default.

func _ready() -> void:
	var fails := 0
	var cfg := ConfigFile.new()
	var err := cfg.load("res://project.godot")
	if err != OK or String(cfg.get_value("axie", "epoch_source", "")) != "remote":
		fails += 1
		print("FAIL: project.godot [axie] epoch_source != remote")
	if err != OK or String(cfg.get_value("axie", "gem_wallet", "")) != "remote":
		fails += 1
		print("FAIL: project.godot [axie] gem_wallet != remote")
	var ep := FileAccess.get_file_as_string("res://export_presets.cfg")
	if ep.contains("epoch_source") or ep.contains("gem_wallet") or ep.contains("scripts/net"):
		fails += 1
		print("FAIL: export_presets.cfg overrides the flags or excludes scripts/net")
	print("t_project_defaults: ", "PASS" if fails == 0 else "FAILED (%d)" % fails)
	get_tree().quit(1 if fails > 0 else 0)
