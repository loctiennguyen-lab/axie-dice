class_name RerollSfx
extends Node
## Placeholder synth SFX for the reroll sequence.
## Every sound is rendered once into an AudioStreamWAV at startup, so it plays through the
## normal AudioStreamPlayer path on desktop AND web (no AudioStreamGenerator, which the web
## Sample playback path cannot handle). Swap `_bank` entries for real samples later:
##   sfx.set_sample("lock", preload("res://audio/dice_lock.wav"))

const RATE := 22050
const VOICES := 10

@export var bus: StringName = &"SFX"
@export var volume_db: float = -4.0
@export var enabled: bool = true

var _bank: Dictionary = {}          # name -> AudioStreamWAV
var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	var use_bus := bus if AudioServer.get_bus_index(bus) >= 0 else &"Master"
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = use_bus
		p.volume_db = volume_db
		# Web builds default to Sample playback; this project forces Stream (see
		# AUDIO_SILENCE_INVESTIGATION.md). Set it per player too, as a safety net.
		if "playback_type" in p:
			p.set("playback_type", 1)  # AudioServer.PLAYBACK_TYPE_STREAM
		add_child(p)
		_players.append(p)
	_build_bank()


## Replace a synth sound with a real sample. `name` is one of the keys used in play().
func set_sample(name: String, stream: AudioStream) -> void:
	_bank[name] = stream


## kind: open, toss, thud, lock (n = how many dice already locked), max, spin,
## grade (n = tier 0..3), whoosh, pop (n = arrival index).
func play(kind: String, n: int = 0) -> void:
	if not enabled:
		return
	var key := kind
	match kind:
		"lock": key = "lock_%d" % clampi(n, 0, 12)
		"grade": key = "grade_%d" % clampi(n, 0, 3)
		"pop": key = "pop_%d" % clampi(n, 0, 10)
	var s: AudioStream = _bank.get(key)
	if s == null:
		s = _bank.get(kind)
	if s == null:
		return
	var p := _players[_next % VOICES]
	_next += 1
	p.stream = s
	p.play()


# ── synth ────────────────────────────────────────────────────────────────────

func _build_bank() -> void:
	var b := _buf(0.2)
	_noise(b, 0.0, 0.16, 0.5, 700.0)
	_tone(b, 0.0, 0.18, 170.0, 80.0, "sine", 0.3)
	_bank["open"] = _wav(b)

	b = _buf(0.45)
	_noise(b, 0.0, 0.4, 0.3, 2600.0)
	_noise(b, 0.08, 0.3, 0.2, 1800.0)
	_bank["toss"] = _wav(b)

	b = _buf(0.12)
	_tone(b, 0.0, 0.1, 120.0, 55.0, "sine", 0.3)
	_noise(b, 0.0, 0.05, 0.25, 900.0)
	_bank["thud"] = _wav(b)

	for n in 13:
		b = _buf(0.16)
		_noise(b, 0.0, 0.035, 0.45, 3400.0)
		_tone(b, 0.0, 0.13, 480.0 * pow(1.122, n), 0.0, "triangle", 0.2)
		_bank["lock_%d" % n] = _wav(b)

	b = _buf(0.45)
	var steps := [0, 4, 7, 12]
	for i in steps.size():
		_tone(b, i * 0.055, 0.2, 660.0 * pow(2.0, steps[i] / 12.0), 0.0, "square", 0.06)
	_bank["max"] = _wav(b)

	b = _buf(0.6)
	_tone(b, 0.0, 0.55, 260.0, 1100.0, "saw", 0.045)
	_bank["spin"] = _wav(b)

	var tiers := [[0, 7, 12], [0, 7, 12], [0, 4, 7, 12], [0, 4, 7, 12, 16, 19]]
	for t in 4:
		var st: Array = tiers[t]
		b = _buf(0.4 + st.size() * 0.07)
		for i in st.size():
			_tone(b, i * 0.07, 0.34, 523.0 * pow(2.0, st[i] / 12.0), 0.0, "triangle", 0.16)
		_bank["grade_%d" % t] = _wav(b)

	b = _buf(0.3)
	_noise(b, 0.0, 0.28, 0.3, 1300.0)
	_bank["whoosh"] = _wav(b)

	for n in 11:
		b = _buf(0.1)
		_tone(b, 0.0, 0.08, 700.0 + n * 60.0, 1400.0, "sine", 0.18)
		_bank["pop_%d" % n] = _wav(b)


func _buf(sec: float) -> PackedFloat32Array:
	var a := PackedFloat32Array()
	a.resize(int(sec * RATE))
	return a


func _tone(b: PackedFloat32Array, t0: float, dur: float, f0: float, f1: float, wave: String, vol: float) -> void:
	var i0 := int(t0 * RATE)
	var n := int(dur * RATE)
	var ph := 0.0
	for i in n:
		var idx := i0 + i
		if idx >= b.size():
			break
		var p := float(i) / n
		var f := f0 if f1 <= 0.0 else f0 * pow(f1 / f0, p)   # exponential slide
		ph = fmod(ph + f / RATE, 1.0)
		var v := 0.0
		match wave:
			"sine": v = sin(ph * TAU)
			"triangle": v = 4.0 * absf(ph - 0.5) - 1.0
			"square": v = 1.0 if ph < 0.5 else -1.0
			_: v = 2.0 * ph - 1.0
		# 8 ms attack, exponential-ish decay (matches the WebAudio ramps in the design)
		var env := minf(1.0, i / (0.008 * RATE)) * pow(1.0 - p, 2.2)
		b[idx] += v * env * vol


func _noise(b: PackedFloat32Array, t0: float, dur: float, vol: float, freq: float) -> void:
	# White noise with (1-p)^2 envelope through a biquad band-pass, Q = 1.1.
	var w0 := TAU * freq / RATE
	var alpha := sin(w0) / (2.0 * 1.1)
	var a0 := 1.0 + alpha
	var b0 := alpha / a0
	var b2 := -alpha / a0
	var a1 := -2.0 * cos(w0) / a0
	var a2 := (1.0 - alpha) / a0
	var x1 := 0.0; var x2 := 0.0; var y1 := 0.0; var y2 := 0.0
	var i0 := int(t0 * RATE)
	var n := int(dur * RATE)
	for i in n:
		var idx := i0 + i
		if idx >= b.size():
			break
		var x := (randf() * 2.0 - 1.0) * pow(1.0 - float(i) / n, 2.0)
		var y := b0 * x + b2 * x2 - a1 * y1 - a2 * y2
		x2 = x1; x1 = x; y2 = y1; y1 = y
		b[idx] += y * vol * 1.6


func _wav(b: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(b.size() * 2)
	for i in b.size():
		bytes.encode_s16(i * 2, int(clampf(b[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	return w
