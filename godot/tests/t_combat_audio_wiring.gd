extends Node
## Gate for combat audio: everything that acts in a fight must be able to make a sound, and
## the test build must make none.
##
## WHY THIS IS A SEPARATE GATE FROM t_assets
## -----------------------------------------
## `t_assets` already proves the audio FILES exist and that a hero's die faces resolve to
## them. It cannot catch the failure this test exists for, because it only ever asks the
## mapping about the six hero classes. Monsters have no class at all — `ContentDB` never sets
## one, and `Unit.cls` defaults to "" — so `CombatAudio.face_sfx_path()` returned "" for every
## monster and every boss in the game. Half of all the blows in a fight would have been
## silent. Nothing crashes, nothing warns, and a reviewer watching a video would hear a fight
## that merely sounded sparse.
##
## That is the same shape as every other bug this port has shipped and later found: absence
## presenting itself as a style choice. So the invariant is stated over CONTENT, not over
## files — every enemy and every boss ContentDB can spawn, checked through the same call the
## director makes at runtime.
##
## Run: godot --headless --path godot res://tests/t_combat_audio_wiring.tscn

## The face types a monster die can carry (ContentDB._load_enemies uses part "m" throughout,
## so the type fallback is the only thing standing between a monster and silence).
const MONSTER_FACE_TYPES := ["dmg", "shield", "heal", "poison", "buff", "debuff", "summon"]

## Every effect the director asks CombatAudio for by name. Kept here rather than read from
## CombatAudio so that deleting a STATUS_SFX entry the director still uses is a failure
## instead of a silent no-op.
const CUES_THE_DIRECTOR_PLAYS := [
	"shield", "heal", "buff", "debuff", "poison", "summon",   # CombatAudioDirector.TYPE_CUE
	"crit",       # on a critical hit
	"death",      # on unit_died
	"undying",    # on boss_phase_changed (the kit's power_awaken)
	"burn", "regen",   # the remaining status_tick payload values StatusEngine can send
]

var _failures: Array[String] = []
var _checks := 0


func _ready() -> void:
	print("=== t_combat_audio_wiring: start ===")
	test_every_enemy_has_an_audible_voice()
	test_every_boss_has_an_audible_voice()
	test_voice_class_prefers_a_heros_own_class()
	test_hit_phase_never_falls_back_to_the_swing()
	test_every_cue_the_director_plays_resolves()
	test_status_tick_payload_values_all_have_a_sound()
	test_buses_exist_and_mute_is_reversible()
	test_director_is_silent_in_test_mode()

	print("=== t_combat_audio_wiring: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_combat_audio_wiring: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_combat_audio_wiring: FAIL — %s" % f)
	get_tree().quit(1)


func _assert(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)


# ---------------------------------------------------------------------------

## THE regression this file was written for. A monster's `cls` is "", which the mapping reads
## as "no such class" and answers with "" — silence. Asked through `voice_class()`, the way
## the director asks, every monster must still land on a real file.
func test_every_enemy_has_an_audible_voice() -> void:
	for key in ContentDB.enemies.keys():
		var k := String(key)
		var voice := CombatAudio.voice_class("", k, false)
		_assert(voice != "",
			"enemy '%s' resolves to no voice class — every one of its attacks would be silent" % k)
		for ft in MONSTER_FACE_TYPES:
			# Monster faces all carry part "m", so the type fallback is the whole story here.
			var path := CombatAudio.face_sfx_path(voice, "m", ft, "attack")
			_assert(path != "" and ResourceLoader.exists(path),
				"enemy '%s' (voice '%s') has no sound for a '%s' face — got '%s'" % [k, voice, ft, path])


func test_every_boss_has_an_audible_voice() -> void:
	for key in ContentDB.bosses.keys():
		var k := String(key)
		var voice := CombatAudio.voice_class("", k, true)
		_assert(voice != "",
			"boss '%s' resolves to no voice class — the whole fight would be silent" % k)
		for ft in MONSTER_FACE_TYPES:
			var path := CombatAudio.face_sfx_path(voice, "m", ft, "attack")
			_assert(path != "" and ResourceLoader.exists(path),
				"boss '%s' (voice '%s') has no sound for a '%s' face — got '%s'" % [k, voice, ft, path])


## A hero must keep its own voice even though its key would also resolve through the sprite
## table if it ever collided with a monster key. The unit's own class wins when it has one.
func test_voice_class_prefers_a_heros_own_class() -> void:
	for cls in ["plant", "beast", "aqua", "reptile", "bug", "bird"]:
		_assert(CombatAudio.voice_class(cls, "slime", false) == cls,
			"a %s hero borrowed a monster's voice instead of using its own class" % cls)
	# And an unknown class falls through to the monster path rather than returning "".
	_assert(CombatAudio.voice_class("not_a_class", "slime", false) != "",
		"an unrecognised class returned no voice at all — that is silence, not a fallback")


## `face_sfx_path(..., "hit")` substitutes the swing when the kit recorded no landing sound.
## That is right for the swing itself and wrong for the landing: a melee blow would play its
## own swing twice, once on use and once on impact. The director passes allow_fallback=false
## for exactly this reason, so the flag has to actually suppress the substitution.
func test_hit_phase_never_falls_back_to_the_swing() -> void:
	for cls in ["plant", "beast", "aqua", "reptile", "bug", "bird"]:
		for part in ["mouth", "horn", "back", "tail", "eyes", "ears"]:
			var swing := CombatAudio.face_sfx_path(cls, part, "dmg", "attack")
			var landing := CombatAudio.face_sfx_path(cls, part, "dmg", "hit", false)
			_assert(landing != swing,
				"%s/%s: the 'hit' phase returned the swing file, so every blow would "
					% [cls, part]
				+ "sound twice — allow_fallback=false did not suppress the substitution")
			if landing != "":
				_assert(ResourceLoader.exists(landing),
					"%s/%s: 'hit' resolved to a path that does not exist (%s)" % [cls, part, landing])


func test_every_cue_the_director_plays_resolves() -> void:
	for cue in CUES_THE_DIRECTOR_PLAYS:
		var path := CombatAudio.status_sfx_path(cue)
		_assert(path != "" and ResourceLoader.exists(path),
			"the director plays cue '%s' but it maps to nothing (got '%s')" % [cue, path])


## StatusEngine sends the names of the effects that actually resolved. Each has to be a key
## the sound table knows, or the tick is silent for that effect with no error anywhere.
func test_status_tick_payload_values_all_have_a_sound() -> void:
	for status in ["poison", "burn", "regen"]:
		_assert(CombatAudio.status_sfx_path(status) != "",
			"StatusEngine can report '%s' in status_tick but it has no sound" % status)


func test_buses_exist_and_mute_is_reversible() -> void:
	var was_muted: bool = MetaState.audio_muted
	CombatAudioDirector.apply_settings()
	for bus_name in [CombatAudioDirector.MUSIC_BUS, CombatAudioDirector.SFX_BUS]:
		_assert(AudioServer.get_bus_index(bus_name) != -1,
			"audio bus '%s' was not created — volume and mute have nothing to act on" % bus_name)

	# Mute must reach the buses, not just the saved flag: a mute that only writes to MetaState
	# looks correct in the save file and still plays sound.
	MetaState.audio_muted = true
	CombatAudioDirector.apply_settings()
	for bus_name in [CombatAudioDirector.MUSIC_BUS, CombatAudioDirector.SFX_BUS]:
		_assert(AudioServer.is_bus_mute(AudioServer.get_bus_index(bus_name)),
			"bus '%s' still audible after muting" % bus_name)

	MetaState.audio_muted = false
	CombatAudioDirector.apply_settings()
	for bus_name in [CombatAudioDirector.MUSIC_BUS, CombatAudioDirector.SFX_BUS]:
		_assert(not AudioServer.is_bus_mute(AudioServer.get_bus_index(bus_name)),
			"bus '%s' stayed muted after unmuting — mute is a one-way trip" % bus_name)

	# A zero slider must be silence, not merely quiet: linear_to_db(0) is -inf.
	CombatAudioDirector._set_bus_level(CombatAudioDirector.SFX_BUS, 0.0,
		CombatAudioDirector.SFX_MAX_DB)
	var db := AudioServer.get_bus_volume_db(AudioServer.get_bus_index(CombatAudioDirector.SFX_BUS))
	_assert(db <= -60.0 and is_finite(db),
		"a volume of 0 produced %f dB — expected a finite, inaudible value" % db)

	MetaState.audio_muted = was_muted
	CombatAudioDirector.apply_settings()


## The headless suite and CI have no audio device, and a test that makes noise is a test that
## can hang waiting for one. The director checks the flag ONCE, in _ready(), and must then
## build no players and connect to nothing at all — a flag re-checked at each play site can be
## flipped mid-test, and a stream would already have been handed to a device that is not there.
func test_director_is_silent_in_test_mode() -> void:
	var was_disabled: bool = CombatView.disable_juice_for_tests
	CombatView.disable_juice_for_tests = true

	var director := CombatAudioDirector.new()
	add_child(director)

	_assert(director.get_child_count() == 0,
		"the director built %d audio player(s) in test mode — it must build none"
			% director.get_child_count())
	_assert(not EventBus.face_used.is_connected(director._on_face_used),
		"the director connected to face_used in test mode — there must be no path from a "
		+ "combat event to an audio call at all")
	_assert(not EventBus.status_tick.is_connected(director._on_status_tick),
		"the director connected to status_tick in test mode")

	# And the public entry points must be harmless rather than crash on the players that were
	# never built — CombatView calls these unconditionally.
	director.register_unit(1, "plant", "plant1", false)
	director.start_music("r1_c0", false)
	director.stop_music()
	_checks += 1   # reaching this line without an error IS the assertion

	director.queue_free()
	CombatView.disable_juice_for_tests = was_disabled
