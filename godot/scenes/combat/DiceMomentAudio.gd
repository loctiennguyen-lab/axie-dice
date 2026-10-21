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
const UI := "res://assets/audio/sfx/ui/"   # MyGame SFX (Sky Mavis IP, Liam allowed 23/10): design/audio/v4-dice-moments.md section 8

## Layer lists (spec 7.5). Entry may carry "layers": [{path | paths, db, pitch, pj, delay_ms}]. `paths` = random variant,
## `pj` = random pitch +-pj. An entry with "layers" ignores "path"/"db". Old single-file entries still work.
const TAPS := [UI + "ui_tap_01.ogg", UI + "ui_tap_02.ogg", UI + "ui_tap_03.ogg"]
const L_ROLL := [{"paths": TAPS, "db": -6.0, "pitch": 1.0, "pj": 0.05}]
const L_SET5 := [{"path": UI + "talent_capstone_unlock.ogg", "db": 0.0},
	{"path": UI + "axie_level_up.ogg", "db": -4.0, "delay_ms": 120}]
## gamble tick: one tap repeated, quickening, pitch climbing (A4 -> D5 is about x1.33)
const L_ARM := [{"path": UI + "ui_tap_03.ogg", "db": -5.0, "pitch": 1.0}, {"path": UI + "ui_tap_03.ogg", "db": -5.0, "pitch": 1.07, "delay_ms": 170},
	{"path": UI + "ui_tap_03.ogg", "db": -5.0, "pitch": 1.14, "delay_ms": 320}, {"path": UI + "ui_tap_03.ogg", "db": -5.0, "pitch": 1.22, "delay_ms": 440},
	{"path": UI + "ui_tap_03.ogg", "db": -5.0, "pitch": 1.33, "delay_ms": 540}]
const L_COMBO_FULL := [{"path": UI + "axie_level_up.ogg", "db": -3.0},
	{"path": UI + "talent_capstone_unlock.ogg", "db": -4.0, "delay_ms": 100}]

## event -> {path, db, prio}. path "" = silent until the asset exists.
const EVENTS := {
	"dm_set5": {"path": "", "db": 0.0, "prio": 100, "layers": L_SET5},
	"dm_set4": {"path": "", "db": -1.0, "prio": 90},
	"dm_set3": {"path": STATUS + "power_gain.ogg", "db": -2.0, "prio": 80},        # TEMP, also the crit sound
	"dm_overcast_charge": {"path": STATUS + "power_awaken.ogg", "db": -3.0, "prio": 70},   # TEMP
	"dm_wild_match": {"path": "", "db": -4.0, "prio": 60, "layers": [{"path": UI + "ui_confirm_02.ogg", "db": -4.0, "pitch": 1.2}]},
	"dm_gamble_clean": {"path": STATUS + "cleanse.ogg", "db": -5.0, "prio": 50},   # TEMP
	"dm_crack": {"path": "", "db": -8.0, "prio": 45, "layers": [{"path": UI + "overflow_death_crack.ogg", "db": -8.0, "pitch": 1.3}]},
	"dm_wild_pick": {"path": "", "db": -6.0, "prio": 40, "layers": [{"path": UI + "ui_confirm_01.ogg", "db": -6.0}]},
	"dm_gamble_arm": {"path": "", "db": -5.0, "prio": 35, "layers": L_ARM},
	"dm_pair": {"path": "", "db": -9.0, "prio": 30, "layers": [{"path": UI + "ui_toast.ogg", "db": -9.0}]},
	"dm_reroll_safe": {"path": "", "db": -6.0, "prio": 25, "layers": [{"path": UI + "resource_collect_01.ogg", "db": -6.0}]},
	"dm_roll": {"path": "", "db": -6.0, "prio": 20, "layers": L_ROLL},
	"dm_reroll_free": {"path": "", "db": -6.0, "prio": 20, "layers": L_ROLL},
	"dm_land": {"path": "", "db": -12.0, "prio": 10, "layers": [{"path": UI + "ui_tap_02.ogg", "db": -12.0, "pitch": 1.2}]},
	"dm_core_open": {"path": "", "db": -4.0, "prio": 55, "layers": [{"path": UI + "ui_modal_open.ogg", "db": -4.0}]},
	"dm_core_hover": {"path": "", "db": -14.0, "prio": 5, "layers": [{"path": UI + "ui_tap_01.ogg", "db": -14.0, "pitch": 1.5}]},
	"dm_core_pick": {"path": "", "db": -1.0, "prio": 88, "layers": [{"path": UI + "star_activate.ogg", "db": -1.0}]},
	"dm_combo": {"path": "", "db": -3.0, "prio": 85, "layers": [{"path": UI + "star_activate.ogg", "db": -3.0}]},       # TEMP (lane GM B5)
	"dm_combo_full": {"path": "", "db": -3.0, "prio": 86, "layers": L_COMBO_FULL},
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
	if d.has("layers") and not _voices.is_empty():
		play_layers(self, d["layers"])
		return true
	var path := String(d["path"])
	if path == "" or _voices.is_empty() or not ResourceLoader.exists(path):
		return true
	var p := _voices[_next]
	_next = (_next + 1) % _voices.size()
	p.stream = load(path)
	p.volume_db = float(d["db"])
	p.play()
	return true


## UI-only rng: variants and pitch jitter never touch the engine rng (replay stays deterministic).
static var _ui_rng := RandomNumberGenerator.new()
static var _ui_rng_ready := false


## Plays a layer list on the SFX bus from `host`. Each layer is its own short-lived player so layers overlap.
static func play_layers(host: Node, layers: Array) -> void:
	if host == null or not host.is_inside_tree():
		return
	if not _ui_rng_ready:
		_ui_rng.randomize()
		_ui_rng_ready = true
	CombatAudioDirector._ensure_buses()
	for l in layers:
		var path := String(l.get("path", ""))
		if l.has("paths"):
			var arr: Array = l["paths"]
			path = String(arr[_ui_rng.randi() % arr.size()])
		if path == "" or not ResourceLoader.exists(path):
			continue
		var pj := float(l.get("pj", 0.0))
		var pitch := float(l.get("pitch", 1.0)) + (_ui_rng.randf_range(-pj, pj) if pj > 0.0 else 0.0)
		var delay := float(l.get("delay_ms", 0)) / 1000.0
		var p := AudioStreamPlayer.new()
		p.bus = SFX_BUS
		p.stream = load(path)
		p.volume_db = float(l.get("db", 0.0))
		p.pitch_scale = pitch
		p.finished.connect(p.queue_free)
		host.add_child(p)
		if delay > 0.0:
			host.get_tree().create_timer(delay).timeout.connect(func(): if is_instance_valid(p): p.play())
		else:
			p.play()
