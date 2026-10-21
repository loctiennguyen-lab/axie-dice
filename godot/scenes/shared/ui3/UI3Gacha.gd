class_name UI3Gacha
extends RefCounted
## Gacha Core-pick helpers (production/gacha-contract.md). Pure timing plan + face-down cover + seen-tier memory.
## Knobs: assets/data/ui/gacha_timing.json. UI only: reads no rng, changes no state.

const TIMING_PATH := "res://assets/data/ui/gacha_timing.json"
const TIER_KEY := ["moss", "amber", "crystal"]
const TIER_TOKEN := ["rarity_rare", "rarity_legendary", "rarity_epic"]
const TIER_WORD := ["Moss", "Amber", "Crystal"]

## -1 auto (instant only under CombatView.disable_juice_for_tests), 0 force animated, 1 force instant.
static var instant_override := -1
static var _timing: Dictionary = {}
static var _seen: Dictionary = {}
static var _seen_key := ""
static var sfx_log: Array[String] = []


static func timing() -> Dictionary:
	if _timing.is_empty():
		var f := FileAccess.open(TIMING_PATH, FileAccess.READ)
		var d = JSON.parse_string(f.get_as_text()) if f != null else null
		_timing = d if d is Dictionary else {"aura_sec": {"moss": 0.6, "amber": 0.9, "crystal": 1.5, "repeat": 0.4},
			"flip_stagger_sec": 0.18, "flip_sec": 0.35, "jackpot_extra_sec": 0.6}
	return _timing


static func is_instant() -> bool:
	if instant_override >= 0:
		return instant_override == 1
	return CombatView.disable_juice_for_tests


## True the first time `tier` is seen in the run keyed by `run_key` (and marks it seen).
static func first_seen(run_key: String, tier: int) -> bool:
	if run_key != _seen_key:
		_seen_key = run_key
		_seen = {}
	var first := not _seen.has(tier)
	_seen[tier] = true
	return first


static func reset_seen() -> void:
	_seen_key = ""
	_seen = {}


## Pure schedule. Returns {aura, flips:[start sec of each flip], flip, jackpot_at, jackpot, total}.
static func plan(n: int, tier: int, first: bool, jackpot: bool, reduce_flash: bool, flip_sec := -1.0) -> Dictionary:
	var t := timing()
	var au: Dictionary = t["aura_sec"]
	var aura := float(au[TIER_KEY[clampi(tier, 0, 2)]]) if first else float(au["repeat"])
	var fl := float(t["flip_sec"]) if flip_sec < 0.0 else flip_sec
	var flips: Array[float] = []
	for i in n:
		flips.append(aura + i * float(t["flip_stagger_sec"]))
	var end := aura + maxf(n - 1, 0) * float(t["flip_stagger_sec"]) + fl
	var jp := jackpot and not reduce_flash
	var jat := end
	if jp:
		end += float(t["jackpot_extra_sec"])
	return {"aura": aura, "flips": flips, "flip": fl, "jackpot": jp, "jackpot_at": jat, "total": end}


static func tier_color(tier: int) -> Color:
	return UI3Theme.color(TIER_TOKEN[clampi(tier, 0, 2)])


## The card back: raised plate, tier-coloured border, tier word (colour never alone) and a pulsing halo ring child.
static func build_cover(tier: int) -> Panel:
	var accent := tier_color(tier)
	var cover := Panel.new()
	cover.name = "CardBack"
	cover.mouse_filter = Control.MOUSE_FILTER_STOP
	cover.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("panel_raised"),
		UI3Theme.radius("l"), UI3Theme.stroke("selected"), accent))
	var halo := Panel.new()
	halo.name = "Halo"
	halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hs := UI3Theme.flat(Color(0, 0, 0, 0), UI3Theme.radius("l") + 8, UI3Theme.stroke("hairline"), accent)
	halo.add_theme_stylebox_override("panel", hs)
	halo.set_anchors_preset(Control.PRESET_FULL_RECT)
	halo.offset_left = -8
	halo.offset_top = -8
	halo.offset_right = 8
	halo.offset_bottom = 8
	halo.modulate.a = 0.0
	cover.add_child(halo)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 16)
	var ic := TextureRect.new()
	ic.texture = UI3.icon("ui_mooncard")
	ic.custom_minimum_size = Vector2(96, 96)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(ic)
	var w := UI3.label(tr_word(tier), "LabelTitle")
	w.name = "TierWord"
	w.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	w.add_theme_color_override("font_color", accent)
	w.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(w)
	cover.add_child(box)
	return cover


static func tr_word(tier: int) -> String:
	return TranslationServer.translate(TIER_WORD[clampi(tier, 0, 2)])


static func play_sfx(host: Node, event: String) -> void:
	sfx_log.append(event)
	if is_instant() or CombatView.disable_juice_for_tests or host == null or not host.is_inside_tree():
		return
	var d: Dictionary = (timing().get("sfx", {}) as Dictionary).get(event, {})
	var path := String(d.get("path", ""))
	if path == "" or not ResourceLoader.exists(path):
		return
	CombatAudioDirector._ensure_buses()
	var p := AudioStreamPlayer.new()
	p.bus = "SFX"
	p.stream = load(path)
	p.volume_db = float(d.get("db", 0.0))
	p.finished.connect(p.queue_free)
	host.add_child(p)
	p.play()
