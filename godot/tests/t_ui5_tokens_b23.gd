extends Node
## UI-05 B2/B3 token merge gate (lane 0a): every key the design listed as changed is in tokens_ui3.json with
## a type UI3Theme can read (sizes are plain numbers, colours #rrggbb), every 1280 override maps to a real
## size token, the _b2_keys/_b3_keys lists only name overrides that exist, and size_of really uses the
## override at 1280 (interpolated in between, untouched at 1920). No network, no save access.

var _failures: Array[String] = []
var _checks := 0
var _guard := SaveGuard.new()

const HEX_RE := "^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$"


func _ready() -> void:
	print("=== t_ui5_tokens_b23: start ===")
	_guard.capture()
	await get_tree().process_frame
	_test_changed_keys()
	_test_overrides()
	_test_size_of_scale()
	UI3Theme.set_scale_override(-1.0)
	_ok(_checks >= 150, "only %d checks ran, the B2/B3 lists were not read" % _checks)
	_guard.restore()
	print("=== t_ui5_tokens_b23: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_ui5_tokens_b23: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_ui5_tokens_b23: FAIL — %s" % f)
	get_tree().quit(1)


func _ok(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)


func _test_changed_keys() -> void:
	var t := UI3Theme.tokens()
	var hex := RegEx.create_from_string(HEX_RE)
	for list_name in ["_changed_b2", "_changed_b3"]:
		var keys: Array = t.get(list_name, [])
		_ok(keys.size() > 50, "%s missing or short (%d)" % [list_name, keys.size()])
		for p in keys:
			var parts := String(p).split(".", true, 1)
			var group: Dictionary = t.get(parts[0], {})
			_ok(group.has(parts[1]), "%s lists %s but tokens_ui3.json has no such key" % [list_name, p])
			var v: Variant = group.get(parts[1])
			match parts[0]:
				"size":
					var scalar := typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT
					var pair := typeof(v) == TYPE_DICTIONARY and (v as Dictionary).has("w")
					_ok(scalar or pair, "%s must be a number or {w,h}, got %s" % [p, str(v)])
				"color":
					var c := String((v as Dictionary).get("value", "")) if typeof(v) == TYPE_DICTIONARY else ""
					_ok(hex.search(c) != null, "%s is not #rrggbb: %s" % [p, str(v)])


func _test_overrides() -> void:
	var t := UI3Theme.tokens()
	var raw: Dictionary = t.get("_size_1280_overrides", {})
	var sizes: Dictionary = t.get("size", {})
	for k in raw:
		var key := String(k)
		if key == "note" or key == "min_text" or key.begins_with("_"):
			continue
		_ok(sizes.has(key.replace("-", "_")), "1280 override %s has no size token %s" % [key, key.replace("-", "_")])
	for list_name in ["_b2_keys", "_b3_keys"]:
		var keys: Array = raw.get(list_name, [])
		_ok(not keys.is_empty(), "_size_1280_overrides.%s missing" % list_name)
		for k in keys:
			_ok(raw.has(k), "%s names %s but there is no such override" % [list_name, k])
	var ov := UI3Theme._overrides_logical()
	for k in ov:
		_ok(not String(k).begins_with("_"), "bookkeeping key %s leaked into the override map" % k)
	# The values the plan fixed (production/ui05-b23-plan.md, lane 0a).
	var want := {"core_card_h": 456, "rule_card_w": 400, "rule_card_h": 460, "anchor_card_w": 400,
		"anchor_card_h": 468, "offer_top": 28, "glossary_w": 1182, "setup_col_w": 360,
		"offline_banner_top": 112, "toast_under_banner": 192, "result_plate_w": 520, "mission_detail_w": 340,
		"lb_detail_w": 340, "echo_side_w": 340, "pass_detail_w": 340, "store_detail_w": 340, "grid_card_h": 300,
		"profile_detail_w": 320, "preview_w": 300, "codex_topics_w": 320, "settings_index_w": 200, "key_btn_w": 160}
	for k in want:
		_ok(int(ov.get(k, -1)) == want[k], "1280 override %s = %s, want %d" % [k, str(ov.get(k)), want[k]])


func _test_size_of_scale() -> void:
	var sizes: Dictionary = UI3Theme.tokens().get("size", {})
	var ov := UI3Theme._overrides_logical()
	for k in ["core_card_h", "rule_card_w", "setup_col_w", "key_btn_w", "mission_detail_w"]:
		UI3Theme.set_scale_override(1.0)
		_ok(UI3Theme.size_of(k) == int(sizes[k]), "%s at 1920 = %d, want token %d" % [k, UI3Theme.size_of(k), int(sizes[k])])
		UI3Theme.set_scale_override(2.0 / 3.0)
		var real := float(UI3Theme.size_of(k)) * 2.0 / 3.0
		_ok(absf(real - float(ov[k])) <= 1.0, "%s at 1280 = %.1f real px, want override %d" % [k, real, int(ov[k])])
		UI3Theme.set_scale_override(0.8)
		var mid := float(UI3Theme.size_of(k)) * 0.8
		var lo := minf(float(ov[k]), float(sizes[k]) * 0.8) - 1.0
		var hi := maxf(float(ov[k]), float(sizes[k]) * 0.8) + 1.0
		_ok(mid >= lo and mid <= hi, "%s at scale 0.8 = %.1f real px, outside [%.0f, %.0f]" % [k, mid, lo, hi])
