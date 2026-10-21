class_name DiceMomentAudio
extends Node
## Depth v4 dice-moment sounds (design/audio/v4-dice-moments.md). Event names `dm_*`; each maps to a file in EVENTS.
## Only 4 events have a placeholder file today (the spec's [TEMP] list); every other event has an empty path = it
## stays silent, and the slot is already here: drop an .ogg into assets/audio/sfx/dice/ and fill the path.
## Plays on the "SFX" bus, so audio_sfx_volume and audio_muted already apply. Two private voices (spec 5), so a
## combat AoE never cuts a Set sound. Reads no game state, consumes no RNG. Headless tests (disable_juice_for_tests)
## build no players at all.

const SFX_BUS := "SFX"
const WINDOW_SEC := 0.5            # a lower-priority event inside this window after a higher one is dropped (spec 4.4)
const STATUS := "res://assets/audio/sfx/status/"
const DICE := "res://assets/audio/sfx/dice/"

## event -> {path, db, prio}. path "" = silent until the asset exists.
const EVENTS := {
	"dm_set5": {"path": "", "db": 0.0, "prio": 100},
	"dm_set4": {"path": "", "db": -1.0, "prio": 90},
	"dm_set3": {"path": STATUS + "power_gain.ogg", "db": -2.0, "prio": 80},        # TEMP, also the crit sound
	"dm_overcast_charge": {"path": STATUS + "power_awaken.ogg", "db": -3.0, "prio": 70},   # TEMP
	"dm_wild_match": {"path": "", "db": -4.0, "prio": 60},
	"dm_gamble_clean": {"path": STATUS + "cleanse.ogg", "db": -5.0, "prio": 50},   # TEMP
	"dm_crack": {"path": "", "db": -8.0, "prio": 45},
	"dm_wild_pick": {"path": "", "db": -6.0, "prio": 40},
	"dm_gamble_arm": {"path": "", "db": -5.0, "prio": 35},
	"dm_pair": {"path": "", "db": -9.0, "prio": 30},
	"dm_reroll_safe": {"path": "", "db": -6.0, "prio": 25},
	"dm_roll": {"path": "", "db": -6.0, "prio": 20},
	"dm_land": {"path": "", "db": -12.0, "prio": 10},
	"dm_combo": {"path": STATUS + "power_gain.ogg", "db": -3.0, "prio": 85},       # TEMP (lane GM B5)
	"dm_crack_fade": {"path": STATUS + "cleanse.ogg", "db": -10.0, "prio": 15},    # TEMP
}

var _silent := false
var _voices: Array[AudioStreamPlayer] = []
var _next := 0
var _last_prio := -1
var _last_at := -100.0
var played: Array[String] = []     # test hook: events that were let through (even when their file is missing)


func _ready() -> void:
	_silent = CombatView.disable_juice_for_tests
	if _silent:
		return
	CombatAudioDirector._ensure_buses()
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.bus = SFX_BUS
		add_child(p)
		_voices.append(p)
	EventBus.die_wild.connect(func(_u: int, _s: int): play("dm_wild_pick"))
	EventBus.die_overcast.connect(func(_u: int, _b: int, _a: int): play("dm_overcast_charge"))


## Pure rule: does `event` get through given the last played one? (separate so tests need no audio device)
func admits(event: String, now: float) -> bool:
	var d: Dictionary = EVENTS.get(event, {})
	if d.is_empty():
		return false
	var prio := int(d["prio"])
	return now - _last_at > WINDOW_SEC or prio >= _last_prio


## Fires `event`. Returns true when it was let through (not whether a file exists).
func play(event: String, now: float = -1.0) -> bool:
	if _silent:
		return false
	if now < 0.0:
		now = Time.get_ticks_msec() / 1000.0
	if not admits(event, now):
		return false
	var d: Dictionary = EVENTS[event]
	_last_prio = int(d["prio"])
	_last_at = now
	played.append(event)
	var path := String(d["path"])
	if path == "" or _voices.is_empty() or not ResourceLoader.exists(path):
		return true
	var p := _voices[_next]
	_next = (_next + 1) % _voices.size()
	p.stream = load(path)
	p.volume_db = float(d["db"])
	p.play()
	return true
