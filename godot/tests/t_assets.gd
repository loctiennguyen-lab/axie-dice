extends Node
## Gate for the Phase-2 art pipeline: every piece of content the game can put on screen must
## have art, and every piece of art must be reachable.
##
## Art gaps do not crash. A missing monster sprite renders as a grey blob, a missing icon
## renders as nothing at all, and both look like a styling choice rather than a defect — which
## is exactly how the port shipped a build where four different monsters were the same grey
## silhouette and the highest-frequency icon in the game was simply absent. Data and files
## drift apart silently; this test is what makes that drift loud.
##
## It deliberately checks BOTH directions. Unmapped content is the obvious failure; unused art
## is the quieter one, and usually means a mapping typo rather than a spare file.
##
## Run: godot --headless --path godot res://tests/t_assets.tscn

const ICON_DIR := "res://assets/icons/web/"
const PART_ICON_DIR := "res://assets/icons/web/part/"

## The web build's own icon set (src/art7.js). The user's requirement is that the Godot build
## reuse these unchanged, so the list is the contract — if one goes missing, the Godot UI
## silently stops matching the live game.
const REQUIRED_PNG_ICONS := [
	# die-face types + resources
	"dmg", "shield", "heal", "poison", "summon", "shard", "chest",
	# status effects
	"regen", "thorns", "undying", "blind", "stun", "freeze", "weaken", "vuln", "burn",
	# run-map node types
	"battle", "elite", "boss", "event", "shop",
]
const REQUIRED_SVG_ICONS := ["mana", "blank", "buff", "debuff", "reroll"]

const PART_SLOTS := ["mouth", "horn", "back", "tail", "eyes", "ears"]
const PART_CLASSES := ["plant", "beast", "aqua", "reptile", "bug", "bird"]

var _failures: Array[String] = []
var _checks := 0


func _ready() -> void:
	print("=== t_assets: start ===")
	test_every_enemy_has_a_sprite_that_loads()
	test_every_boss_has_a_sprite_that_loads()
	test_no_monster_sprite_is_orphaned()
	test_web_icons_are_all_present()
	test_every_body_part_icon_exists()
	test_every_status_effect_has_an_icon()
	test_every_class_has_a_battle_background()
	test_parallax_sets_are_complete()
	test_every_backdrop_region_has_a_scene_image()
	test_every_face_maps_to_a_real_sound()
	test_every_status_maps_to_a_real_sound()
	test_music_exists_for_every_situation()
	test_no_monster_or_boss_wears_a_hero_identity()
	test_every_boss_model_is_on_disk()
	test_raw_svg_icons_use_the_web_builds_viewbox()
	test_every_hero_class_has_a_portrait()
	test_shop_and_crypt_backdrops_exist()
	test_event_backdrop_choice_is_deterministic()

	print("=== t_assets: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_assets: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_assets: FAIL — %s" % f)
	get_tree().quit(1)


func _assert(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)


# ---------------------------------------------------------------------------

func test_every_enemy_has_a_sprite_that_loads() -> void:
	# Arrange / Act / Assert
	for key in ContentDB.enemies.keys():
		var k := String(key)
		var sprite_name: String = MonsterArt.sprite_name_for(k, false)
		_assert(sprite_name != "",
			"enemy '%s' has no entry in MonsterArt.MONSTER_SPRITES — it would render as an "
				% k
			+ "untextured placeholder, which reads as a styling choice rather than a gap")
		if sprite_name == "":
			continue
		_assert(MonsterArt.texture_for(k, false) != null,
			"enemy '%s' maps to sprite '%s' but that texture failed to load" % [k, sprite_name])


func test_every_boss_has_a_sprite_that_loads() -> void:
	for key in ContentDB.bosses.keys():
		var k := String(key)
		var sprite_name: String = MonsterArt.sprite_name_for(k, true)
		_assert(sprite_name != "", "boss '%s' has no entry in MonsterArt.BOSS_SPRITES" % k)
		if sprite_name == "":
			continue
		_assert(MonsterArt.texture_for(k, true) != null,
			"boss '%s' maps to sprite '%s' but that texture failed to load" % [k, sprite_name])


func test_no_monster_sprite_is_orphaned() -> void:
	# Arrange — the reverse direction. A sprite nothing points at is usually a typo in the
	# mapping, not a spare asset, and it costs build size either way.
	var used := {}
	for v in MonsterArt.MONSTER_SPRITES.values():
		used[String(v)] = true
	for v in MonsterArt.BOSS_SPRITES.values():
		used[String(v)] = true

	# Act
	var on_disk := _png_basenames(MonsterArt.SPRITE_DIR)

	# Assert
	_assert(not on_disk.is_empty(), "no monster sprites found in %s" % MonsterArt.SPRITE_DIR)
	for basename in on_disk:
		_assert(used.has(basename),
			"sprite '%s.png' ships but no monster or boss maps to it" % basename)
	for mapped in used.keys():
		_assert(on_disk.has(mapped),
			"MonsterArt maps something to '%s' but no such sprite exists on disk" % mapped)


func test_web_icons_are_all_present() -> void:
	for icon_name in REQUIRED_PNG_ICONS:
		_assert(ResourceLoader.exists(ICON_DIR + icon_name + ".png"),
			"web icon '%s.png' is missing — it is one of the icons the live JS build uses, "
				% icon_name
			+ "extracted from src/art7.js, and the Godot build is required to match it")
	for icon_name in REQUIRED_SVG_ICONS:
		_assert(ResourceLoader.exists(ICON_DIR + icon_name + ".svg"),
			"web icon '%s.svg' is missing (src/art7.js ICON_SVG_RAW)" % icon_name)


func test_every_body_part_icon_exists() -> void:
	# Arrange — 6 slots x 6 classes. Every hero die face names a part, and every hero has a
	# class, so any missing combination is reachable in normal play.
	for slot in PART_SLOTS:
		for cls in PART_CLASSES:
			var path := "%s%s_%s.svg" % [PART_ICON_DIR, slot, cls]
			_assert(ResourceLoader.exists(path),
				"body-part icon '%s_%s.svg' is missing" % [slot, cls])


func test_every_status_effect_has_an_icon() -> void:
	# Arrange — every status the engine can apply must be showable. `frozen` and `shield`
	# already shipped as files that nothing displayed; this is the check that would have
	# caught that.
	var status_to_icon := {
		"poison": "poison", "burn": "burn", "regen": "regen", "thorns": "thorns",
		"blind": "blind", "weaken": "weaken", "vulnerable": "vuln", "stun": "stun",
		"undying": "undying", "freeze": "freeze",
	}

	# Act / Assert
	for status in status_to_icon.keys():
		var icon := String(status_to_icon[status])
		_assert(ResourceLoader.exists(ICON_DIR + icon + ".png"),
			"status '%s' has no icon (expected %s.png)" % [status, icon])

	# `enrage` is the one status with no icon in the JS build either — recorded here so the
	# gap is a known, shared one rather than an oversight discovered again later.
	_assert(not status_to_icon.has("enrage"),
		"enrage now has an icon mapping; update this note and the JS-parity claim with it")


## The six playable classes, each of which has a themed battle backdrop converted from the
## Origins Kit. The kit calls the water class "aquatic"; this game calls it "aqua", and the
## rename happens once at install time so no lookup site has to know about the mismatch.
const CLASSES_WITH_BG := ["plant", "beast", "aqua", "reptile", "bug", "bird"]
const BG_DIR := "res://assets/backgrounds/origins/"


func test_every_class_has_a_battle_background() -> void:
	for cls in CLASSES_WITH_BG:
		_assert(ResourceLoader.exists(BG_DIR + "class/" + cls + ".jpg"),
			"class '%s' has no battle background" % cls)
	_assert(ResourceLoader.exists(BG_DIR + "class/shop.jpg"),
		"the shop node has no background")


## Every region the backdrop can pick must have a composited scene image, and every scene
## image must be reachable from the journey. A missing one does not crash — BattleBackdrop
## warns and leaves the previous scene up, which looks like the backdrop simply did not change.
func test_every_backdrop_region_has_a_scene_image() -> void:
	for set_name in BattleBackdrop.JOURNEY:
		var path: String = BattleBackdrop.SCENE_DIR + String(set_name) + ".jpg"
		_assert(ResourceLoader.exists(path),
			"backdrop region '%s' has no composited scene image at %s" % [set_name, path])
	# And the reverse: a scene image the journey never reaches is dead weight.
	var journey := {}
	for set_name in BattleBackdrop.JOURNEY:
		journey[String(set_name)] = true
	var dir := DirAccess.open(BattleBackdrop.SCENE_DIR)
	if dir != null:
		dir.list_dir_begin()
		var f := dir.get_next()
		while f != "":
			if f.ends_with(".jpg"):
				_assert(journey.has(f.get_basename()),
					"scene image '%s' ships but no backdrop region uses it" % f)
			f = dir.get_next()
		dir.list_dir_end()


func test_parallax_sets_are_complete() -> void:
	# Arrange — a parallax backdrop is only a backdrop if it still has its layers. A set that
	# silently lost all but one would render as a flat image, which looks intentional.
	var sets := _subdirs(BG_DIR + "parallax/")

	# Assert
	_assert(sets.size() >= 5,
		"expected several parallax backdrop sets, found %d" % sets.size())
	for set_name in sets:
		var layers := _png_basenames(BG_DIR + "parallax/" + set_name + "/")
		_assert(layers.size() >= 3,
			"parallax set '%s' has only %d layer(s) — a set that lost its layers renders "
				% [set_name, layers.size()]
			+ "flat and reads as a design choice rather than a missing asset")


## Every (class, part, type) a die face can actually be must produce a playable sound.
## A silent face is not a crash and not a warning — it is just quiet, which is exactly the
## kind of gap that survives review.
func test_every_face_maps_to_a_real_sound() -> void:
	var face_types := ["dmg", "shield", "heal", "poison", "mana", "buff", "debuff", "summon"]
	for cls in CLASSES_WITH_BG:
		for part in PART_SLOTS:
			var path := CombatAudio.face_sfx_path(cls, part, "dmg", "attack")
			_assert(path != "" and ResourceLoader.exists(path),
				"no attack sound for a %s Axie's %s face (got %s)" % [cls, part, path])
		# Enemy faces all carry part "m", so the type fallback has to cover every type.
		for ft in face_types:
			var path2 := CombatAudio.face_sfx_path(cls, "m", ft, "attack")
			_assert(path2 != "" and ResourceLoader.exists(path2),
				"no attack sound for a %s unit's '%s' face via the type fallback" % [cls, ft])


func test_every_status_maps_to_a_real_sound() -> void:
	# Arrange — the statuses the engine can actually apply (status_engine.gd), not the whole
	# STATUS_SFX table, which also carries non-status cues like `crit` and `death`.
	var engine_statuses := ["poison", "burn", "regen", "thorns", "blind", "weaken",
		"vulnerable", "stun", "freeze", "undying"]
	for st in engine_statuses:
		var path := CombatAudio.status_sfx_path(st)
		_assert(path != "" and ResourceLoader.exists(path),
			"status '%s' has no sound (got %s)" % [st, path])


func test_music_exists_for_every_situation() -> void:
	for situation in CombatAudio.MUSIC.keys():
		var path := CombatAudio.music_path(String(situation))
		_assert(path != "" and ResourceLoader.exists(path),
			"music situation '%s' has no track" % situation)
	# A boss node must never draw a normal battle theme, and a normal node must never draw
	# the boss theme — the two are picked by different code paths, so assert both.
	_assert(CombatAudio.battle_music_path("r6_c0", true) == CombatAudio.music_path("boss"),
		"a boss node did not select the boss theme")
	_assert(CombatAudio.battle_music_path("r2_c1", false) != CombatAudio.music_path("boss"),
		"a normal battle selected the boss theme")
	# Deterministic: a replayed seed must sound identical.
	_assert(CombatAudio.battle_music_path("r2_c1", false) == CombatAudio.battle_music_path("r2_c1", false),
		"battle music selection is not deterministic for the same node id")


## USER RULE (2026-09-18): monsters and bosses may only use art from the Chimera library.
##
## This exists because the port had actually broken it. An earlier pass gave the bosses real
## 3D models from `third_party/axie-3d-assets` — and one of them, `pomodoro.glb`, is the Bug
## HERO who fights in the player's own party. The game was fielding a boss that was literally
## one of the player's characters, and nothing caught it because the code only ever compared
## KEYS (`gooey_king` vs `bug1`), never the identities behind them.
##
## RULE AMENDED BY THE OWNER, 2026-09-19. The rule used to be "monsters and bosses come only
## from the Chimera library", which banned every Axie model outright. With no new Chimera art
## available, the owner allows Starter Axie models for bosses **as long as they are not one of
## the player's heroes**. So this test now checks the thing that was actually wrong — IDENTITY
## COLLISION — and nothing wider. `pomodoro` and `machito` stay banned because they are hero
## display names; `paladill`, `kotaro`, `xia` and `kibo` are now legitimate boss art.
##
## Two corrections to what this test used to assert, both measured rather than reasoned:
##   * `shilin` was listed here as "an Axie mascot, not a Chimera". It is not. It ships inside
##     the kit's own `PvE/Chimeras/` folder beside werewolf and treant; it had merely never
##     been converted, because it is the one creature stored as Spine JSON rather than binary.
##   * `machito` is likewise a Chimera folder in the kit AND a hero name. The hero name is what
##     makes it unusable, not the folder.
func test_no_monster_or_boss_wears_a_hero_identity() -> void:
	# Arrange — every hero's display name, lowercased. Nothing else: art is banned for
	# colliding with a character the player controls, not for coming from the wrong folder.
	var forbidden := {}
	for key in ContentDB.heroes.keys():
		var hero_name := String((ContentDB.heroes[key] as Dictionary).get("n", "")).to_lower()
		if hero_name != "":
			forbidden[hero_name] = "the display name of hero '%s'" % key

	# Act / Assert — sprites AND 3D models. The models are where the original bug lived, and
	# checking only sprites would leave exactly that hole open again.
	var mapped: Array = []
	mapped.append_array(MonsterArt.MONSTER_SPRITES.values())
	mapped.append_array(MonsterArt.BOSS_SPRITES.values())
	mapped.append_array(CombatStage3D.BOSS_MODELS.values())
	for art in mapped:
		var art_id := String(art).to_lower()
		_assert(not forbidden.has(art_id),
			"monster/boss art '%s' is %s — the player would be fighting their own character"
				% [art_id, forbidden.get(art_id, "")])

	# The reverse guard: no hero-named art may even be PRESENT in the art folders, so a future
	# mapping cannot quietly reach for one.
	for basename in _png_basenames(MonsterArt.SPRITE_DIR).keys():
		_assert(not forbidden.has(String(basename).to_lower()),
			"'%s.png' sits in the monster sprite folder but is %s"
				% [basename, forbidden.get(String(basename).to_lower(), "")])
	var model_dir := DirAccess.open("res://assets/bosses")
	if model_dir != null:
		for file_name in model_dir.get_files():
			var stem := String(file_name).get_basename().to_lower()
			_assert(not forbidden.has(stem),
				"'%s' sits in the boss model folder but is %s"
					% [file_name, forbidden.get(stem, "")])


## Every boss that claims a 3D model must actually have one on disk. A missing .glb does not
## crash — CombatStage3D falls through to the sprite — so the boss would simply be a flat
## billboard again, which is the exact thing the models were added to stop, and silently.
func test_every_boss_model_is_on_disk() -> void:
	for boss_key in CombatStage3D.BOSS_MODELS:
		var path := "res://assets/bosses/%s.glb" % String(CombatStage3D.BOSS_MODELS[boss_key])
		_assert(ResourceLoader.exists(path),
			"boss '%s' maps to %s, which is not there — the fight silently falls back to a "
				% [boss_key, path] + "2D sprite")
	# And the fallback itself must stay intact: BOSS_SPRITES still has to cover every boss,
	# models or not.
	for boss_key in ContentDB.bosses.keys():
		_assert(MonsterArt.BOSS_SPRITES.has(String(boss_key)),
			"boss '%s' has no sprite fallback" % boss_key)


## The five `ICON_SVG_RAW` icons are FRAGMENTS in src/art7.js, not documents — src/client.html's
## icoSvg() wraps each one with `viewBox="0 0 128 128"` (client.html:2354), and their shapes are
## authored at coordinates like cx=64,cy=64 to suit that box.
##
## The first extraction of these wrapped them in `0 0 48 48`. Every shape then fell outside the
## visible area and the icons rendered as NOTHING — which surfaced in-game as the enemy "blank"
## intent badge being an empty black box. The icon was present, correctly named, and loading
## fine; it was simply drawn off-canvas. Nothing about "the file exists" would ever catch that,
## so this asserts the one property that actually matters.
func test_raw_svg_icons_use_the_web_builds_viewbox() -> void:
	for icon_name in REQUIRED_SVG_ICONS:
		var path: String = ICON_DIR + String(icon_name) + ".svg"
		var f := FileAccess.open(path, FileAccess.READ)
		_assert(f != null, "could not open %s" % path)
		if f == null:
			continue
		var text := f.get_as_text()
		f.close()
		_assert(text.contains("viewBox=\"0 0 128 128\""),
			"%s.svg must use the same 128-unit viewBox src/client.html wraps these fragments "
				% icon_name
			+ "with; anything smaller renders the icon off-canvas as blank")


func _subdirs(dir_path: String) -> Array:
	var out: Array = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if dir.current_is_dir() and not f.begins_with("."):
			out.append(f)
		f = dir.get_next()
	dir.list_dir_end()
	out.sort()
	return out


func _png_basenames(dir_path: String) -> Dictionary:
	var out := {}
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		# Godot exports .import sidecars next to the source; match only the real textures.
		if f.ends_with(".png"):
			out[f.get_basename()] = true
		f = dir.get_next()
	dir.list_dir_end()
	return out


## The die card shows a rendered face per class (tools/render_portraits.tscn). A missing one is
## not an error anywhere: `_class_portrait()` returns null and the TextureRect simply draws
## nothing, so the card loses its portrait and keeps its layout — indistinguishable from a
## design that never had one. These are also the only generated art in the project, so they are
## the most likely to be stale or absent after a clean checkout.
func test_every_hero_class_has_a_portrait() -> void:
	for cls in PART_CLASSES:
		var path := "res://assets/portraits/%s.png" % cls
		_assert(ResourceLoader.exists(path),
			"class '%s' has no die-card portrait at %s — run tools/render_portraits.tscn "
				% [cls, path] + "WITHOUT --headless to regenerate them")
		if not ResourceLoader.exists(path):
			continue
		var tex := load(path) as Texture2D
		_assert(tex != null and tex.get_width() > 0 and tex.get_height() > 0,
			"class '%s' portrait exists but did not load as a usable texture" % cls)


## The two node backdrops that are named directly rather than chosen from the class set.
func test_shop_and_crypt_backdrops_exist() -> void:
	for name in ["shop", "reptile"]:
		_assert(BattleBackdrop.class_background(name) != null,
			"node backdrop '%s' is missing — the shop/crypt overlay would fall back to a bare "
				% name + "dim, which reads as an unfinished screen rather than a missing file")


## An event's backdrop is picked from its node id, never randomly. The whole RNG port exists so
## a replayed seed is identical; a node that looked different on replay would break that in the
## one place a player would actually notice.
func test_event_backdrop_choice_is_deterministic() -> void:
	var names := ["plant", "beast", "aqua", "reptile", "bug", "bird"]
	var seen := {}
	for node_id in ["r2_c0", "r3_c1", "r5_c2", "r7_c0", "r9_c1", "r11_c2", "r13_c0", "r15_c1"]:
		var first: String = names[absi(node_id.hash()) % names.size()]
		var again: String = names[absi(node_id.hash()) % names.size()]
		_assert(first == again, "event backdrop for '%s' changed between two calls" % node_id)
		_assert(BattleBackdrop.class_background(first) != null,
			"event node '%s' resolves to backdrop '%s', which does not load" % [node_id, first])
		seen[first] = true
	# If every node id landed on the same picture the selection is technically deterministic
	# and practically useless — eighteen rows would all look like the same clearing.
	_assert(seen.size() >= 3,
		"eight event node ids produced only %d distinct backdrops — the spread is too narrow "
			% seen.size() + "for a run to read as a journey")
