extends Node
## UI-06 token merge gate (lane L0): every key in tokens._changed_ui06 exists with a readable type, the nine-patch
## group matches assets/ui6/ninepatch.json and names real PNGs, the UI-06 1280 overrides map to size tokens and
## are what size_of returns at 1280, and the values the owner fixed (tier colours, card sizes) cannot be reverted
## silently. No network, no save access.

var _failures: Array[String] = []
var _checks := 0
var _guard := SaveGuard.new()

const HEX_RE := "^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$"


func _ready() -> void:
	print("=== t_ui6_tokens: start ===")
	_guard.capture()
	await get_tree().process_frame
	_test_changed()
	_test_ninepatch()
	_test_overrides()
	UI3Theme.set_scale_override(-1.0)
	_ok(_checks >= 90, "only %d checks ran" % _checks)
	_guard.restore()
	print("=== t_ui6_tokens: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_ui6_tokens: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_ui6_tokens: FAIL — %s" % f)
	get_tree().quit(1)


func _ok(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)


func _test_changed() -> void:
	var t := UI3Theme.tokens()
	var hex := RegEx.create_from_string(HEX_RE)
	var keys: Array = t.get("_changed_ui06", [])
	_ok(keys.size() >= 40, "_changed_ui06 missing or short (%d)" % keys.size())
	for p in keys:
		var parts := String(p).split(".", true, 1)
		var group: Dictionary = t.get(parts[0], {})
		_ok(parts.size() == 2 and group.has(parts[1]), "_changed_ui06 lists %s but tokens_ui3.json has no such key" % p)
		if parts.size() != 2:
			continue
		var v: Variant = group.get(parts[1])
		if parts[0] == "size":
			_ok(typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT, "%s must be a number, got %s" % [p, str(v)])
		elif parts[0] == "color":
			var c := String((v as Dictionary).get("value", "")) if typeof(v) == TYPE_DICTIONARY else ""
			_ok(hex.search(c) != null, "%s is not #rrggbb: %s" % [p, str(v)])
	var want := {"tier_moss": "#7daa48", "tier_amber": "#f2a33a", "tier_crystal": "#7fb6f0", "core_headline": "#ffc445",
		"house_volley": "#8a9cb2", "fam_mana": "#4e9a86", "anchor_fire": "#ffd21f"}
	for k in want:
		var cv := String(((t.get("color", {}) as Dictionary).get(k, {}) as Dictionary).get("value", ""))
		_ok(cv.to_lower() == want[k], "color.%s = %s, want %s" % [k, cv, want[k]])
	var sizes: Dictionary = t.get("size", {})
	_ok(int(sizes.get("core_card_h", -1)) == 600, "size.core_card_h must be 600 (UI-06), got %s" % str(sizes.get("core_card_h")))
	_ok(int(sizes.get("anchor_card_h", -1)) == 676, "size.anchor_card_h must be 676")
	_ok(int(sizes.get("shards_h", -1)) == 64 and int(sizes.get("core_pad", -1)) == 36, "shards_h / core_pad not the UI-06 values")


func _test_ninepatch() -> void:
	var np: Dictionary = UI3Theme.tokens().get("ninepatch", {})
	var f := FileAccess.open("res://assets/ui6/ninepatch.json", FileAccess.READ)
	_ok(f != null, "assets/ui6/ninepatch.json missing")
	if f == null:
		return
	var file_np: Dictionary = JSON.parse_string(f.get_as_text())
	for k in file_np:
		if k == "note":
			continue
		_ok(np.has(k), "tokens.ninepatch has no %s" % k)
		var m: Array = np.get(k, [])
		_ok(m.size() == 4, "ninepatch.%s is not [L,T,R,B]" % k)
		_ok(m == file_np[k], "ninepatch.%s differs from assets/ui6/ninepatch.json" % k)
		_ok(ResourceLoader.exists("res://assets/ui6/%s.png" % k), "no PNG assets/ui6/%s.png for ninepatch.%s" % [k, k])


func _test_overrides() -> void:
	var t := UI3Theme.tokens()
	var raw: Dictionary = t.get("_size_1280_overrides", {})
	var sizes: Dictionary = t.get("size", {})
	var keys: Array = raw.get("_ui06_keys", [])
	_ok(keys.size() >= 12, "_size_1280_overrides._ui06_keys missing")
	for k in keys:
		_ok(raw.has(k), "_ui06_keys names %s but there is no override" % k)
		_ok(sizes.has(String(k).replace("-", "_")), "override %s has no size token" % k)
	var want := {"core_card_w": 280, "core_card_h": 500, "core_art_h": 88, "core_emblem": 72, "core_pad": 22, "offer_top": 24,
		"tip_core_w": 340, "rule_card_w": 400, "rule_card_h": 470, "rule_emblem": 64, "back_art": 140,
		"anchor_card_w": 400, "anchor_card_h": 456}
	var ov := UI3Theme._overrides_logical()
	for k in want:
		_ok(int(ov.get(k, -1)) == want[k], "1280 override %s = %s, want %d" % [k, str(ov.get(k)), want[k]])
	# size_of at 1280 must land on the override in real px (only tokens that exist as size tokens).
	UI3Theme.set_scale_override(2.0 / 3.0)
	for k in want:
		if sizes.has(k):
			var real := float(UI3Theme.size_of(k)) * 2.0 / 3.0
			_ok(absf(real - float(want[k])) <= 1.0, "%s at 1280 = %.1f real px, want %d" % [k, real, want[k]])
