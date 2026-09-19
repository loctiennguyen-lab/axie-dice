class_name CombatAudioDirector
extends Node
## Turns combat events into sound. Owned by CombatView as a child node, one per combat.
##
## WHY THIS IS NOT IN CombatView
## ----------------------------
## CombatView's own discipline (see its header) is that every EventBus handler funnels into
## `_rebuild_all()`, the one place that reads combat state. Audio does not fit that shape: it
## reacts to the event itself, not to the state after it, and it must NOT re-read anything.
## Keeping it in a separate node lets both rules stay true, and means audio can be switched
## off by simply not adding the child.
##
## WHAT IT NEVER DOES
## ------------------
## Reads no game state, decides no game outcome, and consumes no RNG. Every choice here is
## either a direct function of the event payload or a deterministic lookup in CombatAudio —
## the music track included, which is picked from the node id's hash, never `randi()`. This
## port's whole RNG design exists so runs replay identically; audio must stay outside it.
##
## HEADLESS TEST MODE
## ------------------
## `CombatView.disable_juice_for_tests` is checked ONCE, in `_ready()`. When it is set, the
## director builds no players at all and connects to nothing, so there is no code path from a
## combat event to an audio call. That is deliberate: a flag checked at each play site can be
## flipped mid-test and start making noise, and a headless CI machine with no audio device
## should never have had a stream handed to it in the first place.

## Bus names created on demand. Godot ships a project with only "Master"; this project has no
## default_bus_layout.tres, so the buses are made here rather than in a resource file that
## would have to be kept in sync by hand.
const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"

## How many sounds can overlap. An AoE face landing on five enemies fires five `hit_landed`
## in the same frame, and a single player would cut each one off with the next — the fight
## would get quieter exactly when it should get louder. Eight covers the widest AoE plus the
## swing and a status cue on top.
const SFX_VOICES := 8

## The landing sound follows the swing by roughly the time the animation takes to connect.
## Playing both on the same frame reads as one thick noise rather than as cause and effect.
const HIT_DELAY_SEC := 0.12

## Music fades rather than cutting, at both ends. A hard stop on `combat_finished` lands on
## top of the victory moment and reads as a bug.
const MUSIC_FADE_IN_SEC := 0.8
const MUSIC_FADE_OUT_SEC := 0.6

## Ceiling for the music bus in dB, i.e. what `audio_music_volume == 1.0` means. Music sits
## under the effects deliberately: the SFX carry the information.
const MUSIC_MAX_DB := -8.0
const SFX_MAX_DB := -2.0

## Below this the slider is treated as off. Linear-to-dB has no finite value at zero.
const SILENCE_EPSILON := 0.001

## Face types that deserve a second, class-agnostic cue on top of the swing — "what happened"
## as distinct from "who did it". `dmg` is absent on purpose: damage already speaks through
## the swing and the landing, and a third layer on the most common face in the game turns
## every attack into a pile-up.
const TYPE_CUE := {
	"shield": "shield",
	"heal": "heal",
	"buff": "buff",
	"debuff": "debuff",
	"poison": "poison",
	"summon": "summon",
}

var _music_player: AudioStreamPlayer = null
var _sfx_players: Array[AudioStreamPlayer] = []
var _next_voice: int = 0
var _silent: bool = false

## uid -> voice class (a CombatAudio.CLASS_TO_KIT key), filled by `register_unit()`. The
## director needs a unit's voice when `hit_landed` fires, and that payload carries only uids.
## Caching it here rather than asking CombatEngine keeps the "reads no game state" rule true.
var _voices: Dictionary = {}

## uid -> {"part": String, "type": String} from the most recent `face_used` by that unit, so
## the landing sound can match the swing that caused it. Same reason CombatView keeps its own
## `_last_face_used_by_uid` — `hit_landed` does not carry the face.
var _last_face: Dictionary = {}


func _ready() -> void:
	_silent = CombatView.disable_juice_for_tests
	if _silent:
		return
	_ensure_buses()
	apply_settings()
	_build_players()
	_connect_event_bus()


# ===========================================================================
# Bus setup and volume — static so a settings screen can drive them with no
# combat running, and so the values survive between scenes.
# ===========================================================================

## Idempotent: safe to call from every combat. `AudioServer` state is global and outlives the
## scene, so the second combat of a run finds the buses already there.
static func _ensure_buses() -> void:
	for bus_name in [MUSIC_BUS, SFX_BUS]:
		if AudioServer.get_bus_index(bus_name) != -1:
			continue
		var idx := AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, "Master")


## Pushes MetaState's persisted settings onto the buses. Called on every combat start so a
## change made elsewhere (or a save loaded after this scene was written) is picked up.
static func apply_settings() -> void:
	_ensure_buses()
	_set_bus_level(MUSIC_BUS, MetaState.audio_music_volume, MUSIC_MAX_DB)
	_set_bus_level(SFX_BUS, MetaState.audio_sfx_volume, SFX_MAX_DB)
	var muted: bool = MetaState.audio_muted
	for bus_name in [MUSIC_BUS, SFX_BUS]:
		AudioServer.set_bus_mute(AudioServer.get_bus_index(bus_name), muted)


static func _set_bus_level(bus_name: String, linear: float, max_db: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	var clamped := clampf(linear, 0.0, 1.0)
	if clamped <= SILENCE_EPSILON:
		AudioServer.set_bus_volume_db(idx, -80.0)
		return
	# linear_to_db maps 1.0 to 0 dB; the ceiling shifts the whole range down so a slider at
	# maximum is the intended mix level rather than unity gain.
	AudioServer.set_bus_volume_db(idx, linear_to_db(clamped) + max_db)


## Flips mute, persists it, and returns the new state so the caller can repaint its button.
static func toggle_muted() -> bool:
	MetaState.audio_muted = not MetaState.audio_muted
	MetaState.save_to_disk()
	apply_settings()
	return MetaState.audio_muted


static func is_muted() -> bool:
	return MetaState.audio_muted


static func set_volume(music_linear: float, sfx_linear: float) -> void:
	MetaState.audio_music_volume = clampf(music_linear, 0.0, 1.0)
	MetaState.audio_sfx_volume = clampf(sfx_linear, 0.0, 1.0)
	MetaState.save_to_disk()
	apply_settings()


# ===========================================================================
# Setup
# ===========================================================================

func _build_players() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = MUSIC_BUS
	_music_player.name = "MusicPlayer"
	add_child(_music_player)
	for i in SFX_VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = SFX_BUS
		p.name = "SfxVoice%d" % i
		add_child(p)
		_sfx_players.append(p)


func _connect_event_bus() -> void:
	EventBus.face_used.connect(_on_face_used)
	EventBus.hit_landed.connect(_on_hit_landed)
	EventBus.unit_died.connect(_on_unit_died)
	EventBus.boss_phase_changed.connect(_on_boss_phase_changed)
	EventBus.status_tick.connect(_on_status_tick)


## Every unit in the fight must be registered before combat starts, so `hit_landed` (uids
## only) can find a voice. CombatView calls this as it spawns portraits.
##
## KNOWN GAP, not a silent one: units added DURING a fight (`combat_engine.gd` appends to
## `enemies` for gooey_king's SPLIT and for startSummon) are never registered here, so they
## make no sound. That is not an audio bug to fix inside this file — those units get no
## nameplate and no HP bar either, because CombatView only spawns portraits in `_ready()`.
## Whoever closes that gap should register the voice in the same place the portrait appears;
## until then the director stays quiet for them rather than guessing at a voice.
func register_unit(uid: int, unit_class: String, key: String, is_boss: bool) -> void:
	_voices[uid] = CombatAudio.voice_class(unit_class, key, is_boss)


## Starts the battle theme. `node_id` and `is_boss` come from the combat setup, never from a
## random draw — see the class header.
func start_music(node_id: String, is_boss: bool) -> void:
	if _silent:
		return
	var path := CombatAudio.battle_music_path(node_id, is_boss)
	if path == "":
		return
	var stream := load(path) as AudioStream
	if stream == null:
		return
	_music_player.stream = stream
	_music_player.volume_db = -40.0
	_music_player.play()
	var tween := create_tween()
	tween.tween_property(_music_player, "volume_db", 0.0, MUSIC_FADE_IN_SEC)


func stop_music() -> void:
	if _silent or _music_player == null or not _music_player.playing:
		return
	var tween := create_tween()
	tween.tween_property(_music_player, "volume_db", -40.0, MUSIC_FADE_OUT_SEC)
	tween.tween_callback(_music_player.stop)


# ===========================================================================
# EventBus reactions
# ===========================================================================

func _on_face_used(uid: int, _side: String, _target_uid: int, _aoe: bool,
		face_part: String, _face_name: String, face_type: String) -> void:
	_last_face[uid] = {"part": face_part, "type": face_type}
	var voice := String(_voices.get(uid, ""))
	if voice == "":
		return
	_play(CombatAudio.face_sfx_path(voice, face_part, face_type, "attack"))
	var cue := String(TYPE_CUE.get(face_type, ""))
	if cue != "":
		_play(CombatAudio.status_sfx_path(cue))


func _on_hit_landed(src_uid: int, _uid: int, _value: int, crit: bool) -> void:
	if crit:
		_play(CombatAudio.status_sfx_path("crit"))
	var voice := String(_voices.get(src_uid, ""))
	if voice == "":
		return   # status damage (poison/burn) has no attacker — the tick cue covers it
	var face: Dictionary = _last_face.get(src_uid, {})
	if face.is_empty():
		return
	# allow_fallback=false: a melee face has no `_hit` recording, and substituting the swing
	# here would play it twice for every blow. See CombatAudio.face_sfx_path().
	var path := CombatAudio.face_sfx_path(voice, String(face.get("part", "")),
		String(face.get("type", "")), "hit", false)
	if path != "":
		_play_delayed(path, HIT_DELAY_SEC)


func _on_unit_died(_uid: int) -> void:
	_play(CombatAudio.status_sfx_path("death"))


func _on_boss_phase_changed(_uid: int) -> void:
	_play(CombatAudio.status_sfx_path("undying"))   # power_awaken — the kit's transformation cue


## `statuses` is the set of effects that actually resolved this tick, not everything the
## units are carrying: a poison stack that dealt no damage should make no sound. Deduplicated
## by StatusEngine, so five poisoned enemies produce one poison cue rather than five.
func _on_status_tick(statuses: PackedStringArray) -> void:
	for status in statuses:
		_play(CombatAudio.status_sfx_path(status))


# ===========================================================================
# Playback
# ===========================================================================

## Round-robins the voice pool. Deliberately does NOT look for a free player first: when
## every voice is busy the oldest one is the right one to steal, and searching would instead
## drop the newest sound, which is always the one the player is waiting to hear.
func _play(path: String) -> void:
	if _silent or path == "":
		return
	var stream := load(path) as AudioStream
	if stream == null:
		return
	var p := _sfx_players[_next_voice]
	_next_voice = (_next_voice + 1) % _sfx_players.size()
	p.stream = stream
	p.play()


func _play_delayed(path: String, delay: float) -> void:
	if _silent or path == "":
		return
	var timer := get_tree().create_timer(delay)
	timer.timeout.connect(_play.bind(path))
