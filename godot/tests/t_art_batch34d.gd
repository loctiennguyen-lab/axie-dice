extends Node
## Art batch 3 + 4 + D (5/11). Checks: the 10 removed hl icons (8 unused names + reroll + pact) are gone from disk and
## no .gd / .tscn / .tres / .json under res:// refers to them; HudKit picks the _32 / _64 variants, maps "reroll" to
## ui_reroll and "pact" to ui_mooncard, and draws boss-clock on a dark disc (6/11);
## every cur_* has its sizes; every dice skin has a 512 albedo and a 512 normal; the 27 frame bases are 256 with a clear
## window (r 76 of 256).

const HL_GONE := ["gem", "gift", "skip", "mooncard", "undo", "lock", "drawback", "eternal", "reroll", "pact"]
## Removed from hl/ but still asked for by name: HudKit maps them (reroll -> ui_reroll, pact -> ui_mooncard, Liam 6/11).
const HL_MAPPED := ["reroll", "pact"]
const HL_KEPT := ["aid", "attrition", "lethal", "spike"]
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
	var pc := HudKit.icon("pact", 28.0)
	_assert(pc != null and pc.resource_path.contains("ui_mooncard"), "HudKit pact is the moon card, got %s" % (pc.resource_path if pc else "null"))
	# boss-clock (Liam 6/11): drawn on a dark plate_ink disc with a plate_rim ring, per variant, cached
	for px in [0.0, 28.0, 64.0]:
		var bc := HudKit.icon("boss-clock", px)
		_assert(bc is ImageTexture, "boss-clock @%d is the composed disc texture" % int(px))
		if bc is ImageTexture:
			var im := bc.get_image()
			var w := im.get_width()
			_assert(im.get_pixel(0, 0).a < 0.05, "boss-clock @%d corner stays transparent" % int(px))
			var top := im.get_pixel(w / 2, int(w * 0.06))
			_assert(top.a > 0.9 and top.get_luminance() < 0.5, "boss-clock @%d has a dark disc at the top edge (%s)" % [int(px), top])
			var face := im.get_pixel(int(w * 0.3), int(w * 0.5))   # clock face, left of centre (the hand sits right of it)
			_assert(face.get_luminance() > top.get_luminance() + 0.25, "boss-clock @%d: the clock is drawn on the disc (%s)" % [int(px), face])
			_assert(HudKit.icon("boss-clock", px) == bc, "boss-clock @%d is cached" % int(px))
	_assert(HudKit.icon("boss-clock", 28.0).get_width() == 32, "boss-clock at 28 px builds from the _32 file")
	_assert(HudKit.icon("boss-clock", 64.0).get_width() == 64, "boss-clock at 64 px builds from the _64 file")
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


## Nobody may still name a removed hl icon: `hl/<name>` anywhere, or `icon("<name>")` (HL_MAPPED names are exempt
## from the second form: HudKit maps them to UI kit icons).
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
			if not HL_MAPPED.has(n):
				_assert(txt.find('icon("%s")' % n) < 0, "%s calls icon(\"%s\")" % [dir.path_join(f), n])
