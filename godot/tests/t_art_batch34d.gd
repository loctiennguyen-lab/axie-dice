extends Node
## Art batch 3 + 4 + D (5/11). Checks: the 9 removed hl icons (8 unused names + reroll) are gone from disk and no .gd /
## .tscn / .tres / .json under res:// refers to them; HudKit picks the _32 / _64 variants and maps "reroll" to ui_reroll;
## every cur_* has its sizes; every dice skin has a 512 albedo and a 512 normal; the 27 frame bases are 256 with a clear
## window (r 76 of 256).

const HL_GONE := ["gem", "gift", "skip", "mooncard", "undo", "lock", "drawback", "eternal", "reroll"]
const HL_KEPT := ["aid", "attrition", "boss-clock", "lethal", "pact", "spike"]
const CUR := {"cur_fragment": [24, 32, 64], "cur_gem": [24, 32, 64], "cur_shard": [24, 32, 64], "cur_ticket": [24, 32, 64],
	"cur_stone": [16, 24, 32, 64]}

var _failures: Array[String] = []
var _checks := 0


func _ready() -> void:
	for n in HL_GONE:
		for ext in [".png", ".svg"]:
			_assert(not FileAccess.file_exists("res://assets/icons/hl/" + n + ext), "hl/%s%s should be deleted" % [n, ext])
	for n in HL_KEPT:
		_assert(HudKit.icon(n) != null and HudKit.icon(n).resource_path.ends_with(n + ".png"), "%s master is the PNG" % n)
		_assert(HudKit.icon(n, 28.0).resource_path.ends_with(n + "_32.png"), "%s at 28 px uses _32" % n)
		_assert(HudKit.icon(n, 64.0).resource_path.ends_with(n + "_64.png"), "%s at 64 px uses _64" % n)
	var rr := HudKit.icon("reroll")
	_assert(rr != null and rr.resource_path.contains("ui_reroll"), "HudKit reroll is ui_reroll, got %s" % (rr.resource_path if rr else "null"))
	for c in CUR:
		_assert(UI3.icon(c) != null, "%s master loads" % c)
		for s in CUR[c]:
			_assert(ResourceLoader.exists("res://assets/ui3/icons/%s_%d.png" % [c, s]), "%s_%d exists" % [c, s])
		_assert(UI3.currency_icon(c, 24).resource_path.ends_with("%s_24.png" % c), "%s at 24 px uses the _24 file" % c)
	_assert(UI3.icon("cur_stone_reveal").get_width() == 256, "cur_stone_reveal is 256")
	for f in DirAccess.get_directories_at("res://assets/cosmetics/dice"):
		var a := load("res://assets/cosmetics/dice/%s/albedo.png" % f) as Texture2D
		_assert(a != null and a.get_width() == 512 and a.get_height() == 512, "%s albedo is 512" % f)
		var n := load("res://assets/cosmetics/dice/%s/normal.png" % f) as Texture2D
		_assert(n != null and n.get_width() == 512 and n.get_height() == 512, "%s normal is 512x512" % f)
	var bases := 0
	for fn in DirAccess.get_files_at("res://assets/cosmetics/frames"):
		if fn.ends_with("_base.png"):
			bases += 1
			var t := load("res://assets/cosmetics/frames/" + fn) as Texture2D
			_assert(t.get_width() == 256 and t.get_height() == 256, "%s is 256" % fn)
			var img := t.get_image()
			var inner := 0
			for y in 256:
				for x in 256:
					if Vector2(x - 127.5, y - 127.5).length() < 76.0 and img.get_pixel(x, y).a > 0.05:
						inner += 1
			_assert(inner < 40, "%s window (r 76 of 256) is clear, %d px not" % [fn, inner])
	_assert(bases == 27, "27 frame bases, got %d" % bases)
	_scan_refs("res://")
	if _failures.is_empty():
		print("PASS t_art_batch34d (%d checks)" % _checks)
		get_tree().quit(0)
	else:
		for m in _failures:
			print("FAIL: ", m)
		get_tree().quit(1)


func _assert(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_failures.append(msg)


## Nobody may still name a removed hl icon: `hl/<name>` anywhere, or `icon("<name>")` (reroll is exempt for the
## second form: HudKit.icon("reroll") is the live mapping to ui_reroll).
func _scan_refs(dir: String) -> void:
	for d in DirAccess.get_directories_at(dir):
		if d.begins_with(".") or d == "homeland":
			continue
		_scan_refs(dir.path_join(d))
	for f in DirAccess.get_files_at(dir):
		if not (f.ends_with(".gd") or f.ends_with(".tscn") or f.ends_with(".tres") or f.ends_with(".json")):
			continue
		if f == "t_art_batch34d.gd":
			continue
		var txt := FileAccess.get_file_as_string(dir.path_join(f))
		for n in HL_GONE:
			_assert(txt.find("hl/" + n) < 0, "%s mentions hl/%s" % [dir.path_join(f), n])
			if n != "reroll":
				_assert(txt.find('icon("%s")' % n) < 0, "%s calls icon(\"%s\")" % [dir.path_join(f), n])
