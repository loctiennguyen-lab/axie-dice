extends Node
## Land v1: decor.json is sound and every scene loads.
func _ready() -> void:
	var fails: Array[String] = []
	var ids := {}
	var defs := LandDecor.all_defs()
	if defs.size() != 17:
		fails.append("expected 16 craftable + trophy, got %d" % defs.size())
	for d in defs:
		var id := String(d["id"])
		if ids.has(id) or not id.begins_with("decor_"):
			fails.append("bad/dup id " + id)
		ids[id] = true
		if bool(d["craftable"]) and int(d["shard_cost"]) <= 0:
			fails.append("cost " + id)
		if int(d["max_own"]) <= 0 or float(d["footprint_r"]) <= 0.0 or float(d["scale"]) <= 0.0:
			fails.append("numbers " + id)
		if not ResourceLoader.exists(LandDecor.scene_path(id)) or load(LandDecor.scene_path(id)) == null:
			fails.append("scene " + id)
	if LandDecor.tier_cap(1) != 10 or LandDecor.tier_cap(6) != 54:
		fails.append("caps")
	for m in LandDecor.milestones():
		for it in ([m["item"]] if m.has("item") else m["items"]):
			if not CosmeticArt.has_art(String(it)) and not String(it).begins_with("title:"):
				fails.append("milestone item " + String(it))
	for f in fails:
		print("FAIL ", f)
	print("t_decor_data: %s" % ("PASS" if fails.is_empty() else "FAIL"))
	get_tree().quit(1 if not fails.is_empty() else 0)
