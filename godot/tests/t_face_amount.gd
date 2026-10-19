extends Node
## Every face in part_faces.json that has an amount must display a non-zero number. Buff and
## debuff faces are printed with v=0 and keep the amount in a keyword ("weaken:N"); the display
## must resolve it. Run: godot --headless --path godot res://tests/t_face_amount.tscn

var _checks := 0
var _fails: Array[String] = []


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _ready() -> void:
	print("=== t_face_amount: start ===")
	var pf: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/part_faces.json"))
	var faces: Array = []
	for fam in (pf["familyVariant"] as Dictionary).values():
		for slot in (fam as Dictionary).values():
			for tpl in (slot as Dictionary).values():
				var t: Dictionary = tpl
				for tier in ["C", "O", "P"]:
					faces.append({"type": t["t"], "value": int((t["v"] as Dictionary)[tier]), "keywords": t["k"],
						"n": int((t["v"] as Dictionary)[tier])})
	for sg in (pf["signatureFace"] as Dictionary).values():
		faces.append({"type": sg["t"], "value": int(sg["v"]), "keywords": sg["k"], "n": int(sg["v"])})
	for f in faces:
		var t := String(f["type"])
		var kws: Array = []
		for k in f["keywords"]:
			var ks := String(k)
			kws.append(ks.substr(0, ks.length() - 1) + str(f["n"]) if ks.ends_with(":N") else ks)
		var face := {"type": t, "value": 0 if (t == "debuff" or t == "buff") else int(f["value"]), "keywords": kws}
		var has_kw_amount := false
		for k in kws:
			var p := String(k).split(":")
			has_kw_amount = has_kw_amount or (p.size() > 1 and FaceAmount.AMOUNT_KW.has(p[0]) and int(p[1]) > 0)
		var has_amount: bool = int(face["value"]) > 0 or ((t == "debuff" or t == "buff") and has_kw_amount)
		if has_amount:
			_check(FaceAmount.display_value(face, int(face["value"])) > 0, "face shows 0: %s" % str(face))
	# the reported case
	var w := {"type": "debuff", "value": 0, "keywords": ["weaken:3", "aoe"]}
	_check(FaceAmount.display_value(w, 0) == 3, "weaken:3 shows 3")
	_check(FaceAmount.fill_n("deals N less damage", 3) == "deals 3 less damage", "N replaced")
	_check(FaceAmount.display_value({"type": "blank", "keywords": []}, 0) == 0, "blank stays 0")
	_check(FaceAmount.display_value({"type": "debuff", "keywords": ["stun"]}, 0) == 0, "stun has no number")
	_check(FaceAmount.display_value({"type": "dmg", "keywords": ["poison:2"]}, 0) == 0, "dmg keeps live 0 (blind)")
	_check(_checks > 100, "scanned many faces (%d)" % _checks)
	for m in _fails:
		print("t_face_amount: FAIL - %s" % m)
	if _fails.is_empty():
		print("t_face_amount: PASS - %d checks OK" % _checks)
	get_tree().quit(0 if _fails.is_empty() else 1)
