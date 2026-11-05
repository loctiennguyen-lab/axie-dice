extends Node
## Art batch 3 + 4 + D (5/11): dice skin textures 512, frame bases 256 (window 162), HUD + currency icons.
## Guards: the 8 unused hl names are gone and nobody calls them, HudKit "reroll" is ui_reroll, HUD icons have
## 64 / 32 variants, every cur_* has its sizes, every skin has a 512 albedo and a normal map, frame bases are 256.

const HL_GONE := ["gem", "gift", "skip", "mooncard", "undo", "lock", "drawback", "eternal"]
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
		_assert(n != null and n.get_width() == 512, "%s normal is 512" % f)
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
					if Vector2(x - 127.5, y - 127.5).length() < 80.0 and img.get_pixel(x, y).a > 0.05:
						inner += 1
			_assert(inner < 40, "%s window (r 80 of 256) is clear, %d px not" % [fn, inner])
	_assert(bases == 27, "27 frame bases, got %d" % bases)
	for f in ["res://scripts/ui/hud_kit.gd"]:
		_assert(FileAccess.get_file_as_string(f).find("HL_DIR") >= 0, "hud_kit still reads hl")
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
