extends Node
## Art redo batch 2 (Liam 4/11): from the Homeland library 2 house emblems, 4 die-face icons and 4 Boss Pact icons;
## drawn by Claude Design the Gambler emblem, 5 pacts and 6 UI glyphs (64 default + hand-redrawn 32 / 128). Batch 2b
## (5/11) redrew Embers, Mana Mine, Kin, Lone Wolf, Patient Fang and added a 16 px reroll glyph. Guards: each loads its
## PNG (not the old AI SVG), no house gets the cream LightDisc any more, every pact has its own icon, a small glyph picks
## the 32 redraw (reroll the 16), the action-tile glyph is flat cream, and the mockup paths that still say `.svg` land on
## the PNG.

const HOUSES := ["h_volley", "h_mana_mine", "h_embers", "h_big_hand", "h_gambler", "h_kin"]
const LIB_FACES := ["face_blank", "face_buff", "face_debuff", "face_mana"]
const LIB_PACTS := ["r_twinfates", "r_ironvow", "r_tithepips", "r_devilsreroll"]
const DRAWN_PACTS := ["r_bloodpact", "r_lonewolf", "r_brittledice", "r_patientfang", "r_hollowchalice"]
const GLYPHS := ["ui_check", "ui_lock", "ui_menu", "ui_reroll", "ui_settings", "ui_undo"]

var _failures: Array[String] = []
var _checks := 0


func _ready() -> void:
	for h in HOUSES:
		var t := UI6Assets.house(h)
		_assert(t != null and t.resource_path.ends_with(".png"), "%s should load the painted PNG, got %s" % [h, _path(t)])
		_assert(not UI6Assets.needs_disc(t), "%s is painted art, it must not get the cream disc" % h)
	for f in LIB_FACES:
		var t := UI3.icon(f)
		_assert(t != null and t.resource_path.ends_with(".png"), "%s should load the library PNG, got %s" % [f, _path(t)])
		_assert(not UI6Assets.needs_disc(t), "%s must not get the cream disc" % f)
		var web := MockupAssets.tex("assets/fx/%s.svg" % f.trim_prefix("face_"))
		_assert(web != null and web.resource_path.ends_with(".png"), "mockup fx/%s.svg should land on the PNG" % f)
	_assert(MockupAssets.part_icon("", "plant") != null, "empty part slot must still resolve (blank.svg -> blank.png)")
	var moon := UI3.icon("ui_mooncard")
	for id in LIB_PACTS + DRAWN_PACTS:
		_assert(RelicRegistry.get_def(id) != null and String(RelicRegistry.get_def(id).pact_group) != "",
			"%s is not a pact any more: update this list" % id)
	for id in LIB_PACTS + DRAWN_PACTS:
		var t := UI6Assets.pact(id)
		_assert(t != null and t != moon and t.resource_path.ends_with("pact_%s.png" % id.trim_prefix("r_")),
			"%s should have its own icon, got %s" % [id, _path(t)])
	_assert(UI6Assets.pact("r_not_a_pact") == moon, "a pact with no art falls back to the moon card")
	for g in GLYPHS:
		var d := UI3.icon(g)
		_assert(d != null and d.resource_path.ends_with("%s.png" % g) and d.get_width() == 64,
			"%s default should be the 64 PNG, got %s" % [g, _path(d)])
		var small := UI3.icon(g, 20.0)
		var want := 16 if g == "ui_reroll" else 32
		_assert(small != null and small.get_width() == want, "%s at 20 px should pick the %d redraw" % [g, want])
		var s24 := UI3.icon(g, 24.0)
		_assert(s24 != null and s24.get_width() == 32, "%s at 24 px should pick the 32 redraw" % g)
		var mid := UI3.icon(g, 36.0)
		_assert(mid != null and mid.get_width() == 64, "%s at 36 px should stay on the 64" % g)
		var big := UI3.icon(g, 96.0)
		_assert(big != null and big.get_width() == 128, "%s at 96 px should pick the 128" % g)
		_assert(not UI6Assets.needs_disc(d), "%s is cream art: a cream disc behind it would hide it" % g)
	var flat := UI3.flat_cream_icon("ui_lock", 24.0).get_image()
	var cream := UI3Theme.color("text")
	var off := 0
	for y in flat.get_height():
		for x in flat.get_width():
			var c := flat.get_pixel(x, y)
			if c.a > 0.1 and (absf(c.r - cream.r) > 0.02 or absf(c.g - cream.g) > 0.02 or absf(c.b - cream.b) > 0.02):
				off += 1
	_assert(flat.get_width() == 32 and off == 0, "flat_cream_icon must be one cream colour (%d pixels off)" % off)
	var tinted := UI3.cream_icon("ui_lock", 24.0)
	_assert(tinted != null and tinted != UI3.flat_cream_icon("ui_lock", 24.0), "cream and flat variants are cached apart")
	print("t_art_batch2_lib: %d checks, %d failure(s)" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_art_batch2_lib: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_art_batch2_lib: FAIL — %s" % f)
	get_tree().quit(1)


func _path(t: Texture2D) -> String:
	return "null" if t == null else t.resource_path


func _assert(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_failures.append(msg)
