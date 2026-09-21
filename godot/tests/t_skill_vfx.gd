extends Node
## Regression test for the Origins skill-VFX plate: SkillVfxCatalog's lookup and
## SkillVfxLayer's playback. The MOTION half of the feature (a ranged face plants instead of
## lunging) is asserted in t_action_motion.gd, which is the only file in this suite that runs
## with juice on.
##
## WHAT IS WORTH PINNING HERE
## --------------------------
## 1. The catalog is complete. 42 sheets were copied in by hand from the kit; a missing one
##    means a class silently loses an action, which no other test would notice.
## 2. The lookup order. Body part first, face type only as a fallback — the same order
##    CombatAudio.face_sfx_path() uses. If these two ever diverge, an Axie gores in the
##    speakers and slashes on screen.
## 3. `is_ranged` really is the data's flag and really is cast/projectile/throw. The lunge
##    decision hangs off it.
## 4. The layer survives the inputs it will actually get: an unknown key, two units on the
##    same spot, a self-target.
##
## Run: godot --headless --path godot res://tests/t_skill_vfx.tscn

const _CLASSES := ["plant", "beast", "aqua", "reptile", "bug", "bird"]
const _ACTIONS := ["bite", "gore", "slash", "smash", "cast", "projectile", "throw"]
const _RANGED_ACTIONS := ["cast", "projectile", "throw"]

var _fails: Array[String] = []
var _checks := 0


func _ready() -> void:
	print("=== t_skill_vfx: start ===")
	_test_every_class_action_pair_has_a_clip()
	_test_the_lookup_matches_combat_audio()
	_test_ranged_is_exactly_the_three_kit_actions()
	_test_clip_metadata_is_playable()
	_test_the_layer_plays_and_finishes()
	_test_the_layer_survives_degenerate_input()

	if _fails.is_empty():
		print("t_skill_vfx: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
	else:
		for f in _fails:
			print("  FAIL: %s" % f)
		print("t_skill_vfx: FAIL — %d of %d checks failed" % [_fails.size(), _checks])
		get_tree().quit(1)


## Every class x action the copy step was supposed to bring over. The count is spelled out
## rather than derived so that deleting an atlas AND its catalog entry still fails.
func _test_every_class_action_pair_has_a_clip() -> void:
	var missing: Array[String] = []
	for cls in _CLASSES:
		for action in _ACTIONS:
			var kit_class := String(CombatAudio.CLASS_TO_KIT.get(cls, ""))
			var key := "%s_%s" % [kit_class, action]
			if SkillVfxCatalog.clip(key).is_empty():
				missing.append(key)
			elif not ResourceLoader.exists(SkillVfxCatalog.atlas_path(key)):
				missing.append(key + " (catalog entry but no atlas)")
	_check(missing.is_empty(), "missing skill VFX clips: %s" % str(missing))
	_check(_CLASSES.size() * _ACTIONS.size() == 42,
		"this test assumes the 6x7 grid the copy step produced; it now describes %d pairs"
		% (_CLASSES.size() * _ACTIONS.size()))


## The part decides, the type only fills in. Same order as CombatAudio.face_sfx_path().
func _test_the_lookup_matches_combat_audio() -> void:
	_check(SkillVfxCatalog.clip_key("plant", "horn", "dmg") == "plant_gore",
		"horn should gore, got '%s'" % SkillVfxCatalog.clip_key("plant", "horn", "dmg"))
	_check(SkillVfxCatalog.clip_key("plant", "mouth", "dmg") == "plant_bite",
		"mouth should bite, got '%s'" % SkillVfxCatalog.clip_key("plant", "mouth", "dmg"))
	# The part WINS over the type: a mouth face whose type says "projectile" still bites.
	_check(SkillVfxCatalog.clip_key("plant", "mouth", "poison") == "plant_bite",
		"the body part must beat the face type, got '%s'"
		% SkillVfxCatalog.clip_key("plant", "mouth", "poison"))
	# Enemies have no meaningful part ("m"), so the type is all there is.
	_check(SkillVfxCatalog.clip_key("plant", "m", "poison") == "plant_projectile",
		"an unknown part should fall back to the face type, got '%s'"
		% SkillVfxCatalog.clip_key("plant", "m", "poison"))
	# The kit calls the water class "aquatic"; this game calls it "aqua".
	_check(SkillVfxCatalog.clip_key("aqua", "tail", "dmg") == "aquatic_slash",
		"aqua must map to the kit's 'aquatic', got '%s'"
		% SkillVfxCatalog.clip_key("aqua", "tail", "dmg"))
	_check(SkillVfxCatalog.clip_key("nonsense", "tail", "dmg") == "",
		"an unknown class must yield no clip, not a broken key")
	_check(SkillVfxCatalog.clip_key("plant", "", "") == "",
		"a face with neither part nor type must yield no clip")


func _test_ranged_is_exactly_the_three_kit_actions() -> void:
	for cls in _CLASSES:
		var kit_class := String(CombatAudio.CLASS_TO_KIT.get(cls, ""))
		for action in _ACTIONS:
			var key := "%s_%s" % [kit_class, action]
			var want: bool = action in _RANGED_ACTIONS
			_check(SkillVfxCatalog.is_ranged(key) == want,
				"%s: is_ranged=%s, expected %s" % [key, SkillVfxCatalog.is_ranged(key), want])
	_check(not SkillVfxCatalog.is_ranged(""),
		"an empty key must not read as ranged — a unit with no clip keeps its melee lunge")
	_check(not SkillVfxCatalog.is_ranged("no_such_clip"),
		"an unknown key must not read as ranged")


## A sheet that cannot be indexed draws nothing, and nothing is exactly what this feature
## looked like before it existed — so the grid has to actually cover the frame count.
func _test_clip_metadata_is_playable() -> void:
	for cls in _CLASSES:
		var kit_class := String(CombatAudio.CLASS_TO_KIT.get(cls, ""))
		for action in _ACTIONS:
			var key := "%s_%s" % [kit_class, action]
			var m := SkillVfxCatalog.clip(key)
			if m.is_empty():
				continue   # already reported by the completeness check
			var cols := int(m.get("cols", 0))
			var rows := int(m.get("rows", 0))
			var frames := int(m.get("frames", 0))
			_check(cols > 0 and rows > 0 and frames > 0,
				"%s: degenerate grid cols=%d rows=%d frames=%d" % [key, cols, rows, frames])
			_check(cols * rows >= frames,
				"%s: grid %dx%d cannot hold %d frames" % [key, cols, rows, frames])
			_check(float(m.get("fps", 0.0)) > 0.0, "%s: fps is not positive" % key)
			_check(int(m.get("peak_frame", -1)) >= 0
					and int(m.get("peak_frame", 0)) < frames,
				"%s: peak_frame %d is outside 0..%d" % [key, int(m.get("peak_frame", -1)),
					frames - 1])
			_check(SkillVfxLayer.clip_duration(key) > 0.0,
				"%s: zero duration would end the clip before a frame is drawn" % key)
			_check(SkillVfxLayer.clip_peak_time(key) <= SkillVfxLayer.clip_duration(key),
				"%s: the peak lands after the clip ends" % key)


func _test_the_layer_plays_and_finishes() -> void:
	var layer := SkillVfxLayer.new()
	add_child(layer)   # no size assignment: the layer is PRESET_FULL_RECT and play() takes
		# explicit coordinates, so setting size only earns Godot's anchor-override warning
	_check(not layer.is_playing(), "a fresh layer should not be playing anything")
	var ok: bool = layer.play("plant_cast", Vector2(400, 700), Vector2(900, 300))
	_check(ok, "plant_cast failed to start")
	_check(layer.is_playing(), "the layer reports nothing playing right after a successful play")
	# Fast-forward past the end by hand rather than waiting 2.5s of wall clock.
	var dur := SkillVfxLayer.clip_duration("plant_cast")
	layer._process(dur + 0.1)
	_check(not layer.is_playing(),
		"the clip was still playing %.2fs after its own %.2fs duration"
		% [dur + 0.1, dur])
	layer.queue_free()


func _test_the_layer_survives_degenerate_input() -> void:
	var layer := SkillVfxLayer.new()
	add_child(layer)
	_check(not layer.play("", Vector2(10, 10), Vector2(20, 20)),
		"an empty key must be refused, not played")
	_check(not layer.play("no_such_clip", Vector2(10, 10), Vector2(20, 20)),
		"an unknown key must be refused, not played")
	# Self-target and coincident points: the scale clamp is what keeps these drawable.
	_check(layer.play("plant_bite", Vector2(500, 500), Vector2(500, 500)),
		"a zero-length attacker->target span must still play (clamped), not be dropped")
	_check(layer.is_playing(), "the clamped clip did not start")
	layer.stop_all()
	_check(not layer.is_playing(), "stop_all() left something playing")
	layer.queue_free()


func _check(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_fails.append(msg)
