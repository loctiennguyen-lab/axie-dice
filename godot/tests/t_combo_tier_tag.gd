extends Node
## GU 4: PAIR and FULL tags differ by colour, frame AND glyph count (colour never alone), both carry the word.
var _checks := 0
var _fails: Array[String] = []

func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)

func _glyphs(n: Node) -> int:
	var c := 0
	for k in n.find_children("*", "TextureRect", true, false):
		c += 1
	return c

func _ready() -> void:
	var pair := UI3.combo_tier_tag(false)
	var full := UI3.combo_tier_tag(true)
	add_child(pair)
	add_child(full)
	var sp := pair.get_theme_stylebox("panel") as StyleBoxFlat
	var sf := full.get_theme_stylebox("panel") as StyleBoxFlat
	_check((pair.find_child("ComboWord", true, false) as Label).text == "PAIR", "pair word")
	_check((full.find_child("ComboWord", true, false) as Label).text == "FULL", "full word")
	_check(sp.bg_color != sf.bg_color, "different fill colour")
	_check(sf.border_width_left >= 4 and sp.border_width_left == 0, "FULL has the thick frame, PAIR none")
	_check(_glyphs(pair) == 2 and _glyphs(full) == 3, "glyphs: 2 cards vs 3 cards")
	var cv: String = FileAccess.get_file_as_string("res://scenes/combat/CombatView.gd")
	_check(not cv.contains('tr("COMBO")'), "combat banner no longer says plain COMBO")
	_check(cv.contains("combo_tier_tag(full)"), "combat banner uses the tier tag")
	pair.queue_free()
	full.queue_free()
	for m in _fails:
		print("t_combo_tier_tag: FAIL — %s" % m)
	if _fails.is_empty():
		print("t_combo_tier_tag: PASS — %d checks OK" % _checks)
	get_tree().quit(0 if _fails.is_empty() else 1)
