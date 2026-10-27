class_name UI3Gacha
extends RefCounted
## Gacha Core-pick helpers (production/gacha-contract.md). Pure timing plan + face-down cover + seen-tier memory.
## Knobs: assets/data/ui/gacha_timing.json. UI only: reads no rng, changes no state.

const TIMING_PATH := "res://assets/data/ui/gacha_timing.json"
const TIER_KEY := ["moss", "amber", "crystal"]
const TIER_TOKEN := ["rarity_rare", "rarity_legendary", "rarity_epic"]
const TIER_WORD := ["Common", "Rare", "Epic"]

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
static func plan(n: int, tier: int, first: bool, jackpot: bool, reduce_flash: bool, flip_sec := -1.0, from_tier := -1) -> Dictionary:
	var t := timing()
	# Near-miss: cards open as `from_tier` (the cap-held higher tier), crack to `tier` at `crack_at`, then flip.
	var nm := float(t.get("near_miss_sec", 0.6)) if from_tier > tier else 0.0
	var au: Dictionary = t["aura_sec"]
	# The halo shows the capped (higher) tier, so a near-miss holds the longer higher-tier aura before it cracks.
	var aura_tier := from_tier if from_tier > tier else tier
	var aura := float(au[TIER_KEY[clampi(aura_tier, 0, 2)]]) if first else float(au["repeat"])
	var fl := float(t["flip_sec"]) if flip_sec < 0.0 else flip_sec
	var flips: Array[float] = []
	for i in n:
		flips.append(aura + nm + i * float(t["flip_stagger_sec"]))
	var end := aura + nm + maxf(n - 1, 0) * float(t["flip_stagger_sec"]) + fl
	var jp := jackpot and not reduce_flash
	var jat := end
	if jp:
		end += float(t["jackpot_extra_sec"])
	return {"aura": aura, "near_miss": nm, "crack_at": aura, "flips": flips, "flip": fl, "jackpot": jp, "jackpot_at": jat, "total": end}


static func tier_color(tier: int) -> Color:
	return UI3Theme.color(TIER_TOKEN[clampi(tier, 0, 2)])


## The card back: raised plate, tier-coloured border, tier word (colour never alone) and a pulsing halo ring child.
static func build_cover(tier: int, from_tier := -1, with_reason := true) -> Panel:
	var near := from_tier > tier
	var accent := tier_color(from_tier if near else tier)
	var cover := Panel.new()
	cover.name = "CardBack"
	cover.mouse_filter = Control.MOUSE_FILTER_STOP
	var cs := UI3Theme.flat(UI3Theme.color("panel_raised"), UI3Theme.radius("l"), UI3Theme.stroke("selected"), accent)
	cover.add_theme_stylebox_override("panel", cs)
	cover.set_meta("style", cs)
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
	var w := UI3.label(tr_word(from_tier if near else tier), "LabelTitle")
	w.name = "TierWord"
	w.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	w.add_theme_color_override("font_color", accent)
	w.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(w)
	if near and with_reason:
		box.add_child(reason_strip())
	cover.add_child(box)
	return cover


## The near-miss reason, on the one card that carries it: "Crystal cap reached - max N Crystal Cores this run"
## (N is the engine's cap for this mode). Cream text on a solid notice plate with an amber border (readable, not red).
static func reason_strip() -> PanelContainer:
	var strip := PanelContainer.new()
	strip.name = "ReasonLine"
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := UI3Theme.flat(UI3Theme.color("notice_bg"), UI3Theme.radius("m"), UI3Theme.stroke("hairline"),
		UI3Theme.color("accent"), Vector4(16, 12, 16, 12))
	strip.add_theme_stylebox_override("panel", sb)
	var l := UI3.label(TranslationServer.translate("Crystal cap reached \u2014 max %d Crystal Cores this run") \
		% CoreOffer.t_cap(String(RunState.get("mode"))), "LabelDisplay")
	l.name = "ReasonText"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 300
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.add_child(l)
	strip.modulate.a = 0.0
	return strip


## Tier this offer would have been without the Crystal cap (2), or -1. UI-only read of the run state:
## milestone offer (not a bonus one), chain says Crystal, the offer came out lower, owned Crystals >= cap.
## Ignores bumps and Mua Sao (they never make it a false positive, only a missed near-miss).
static func capped_from(offer_tier: int) -> int:
	if offer_tier >= 2:
		return -1
	var pick := int(RunState.get("_core_offer_pick"))
	if int(RunState.get("core_pick_index")) != pick + 1:
		return -1
	var chain: Array = RunState.get("core_tier_chain")
	if pick < 0 or pick >= chain.size() or int(chain[pick]) != 2:
		return -1
	if CoreOffer.owned_crystal_count(RunState.owned_relic_ids) < CoreOffer.t_cap(String(RunState.get("mode"))):
		return -1
	return 2


static func tr_word(tier: int) -> String:
	return TranslationServer.translate(TIER_WORD[clampi(tier, 0, 2)])


static func play_sfx(host: Node, event: String) -> void:
	sfx_log.append(event)
	if is_instant() or CombatView.disable_juice_for_tests or host == null or not host.is_inside_tree():
		return
	var d: Dictionary = (timing().get("sfx", {}) as Dictionary).get(event, {})
	if d.has("layers"):
		DiceMomentAudio.play_layers(host, d["layers"])
		return
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


# ---- Combo adapter (API from lane GD: CoreCombos). `combo_provider` lets tests fake the same three methods ----
static var combo_provider: Object = null


## Owned Core ids as CoreCombos wants them (finished quest Cores still count). Falls back to owned_relic_ids.
static func owned_ids() -> Array:
	if RunState.has_method("combo_owned_ids"):
		return RunState.combo_owned_ids()
	return RunState.owned_relic_ids


## {id, tier: "pair"|"full"} when taking `core_id` completes a Pair / Full, else {}.
static func combo_completes(owned: Array, core_id: String) -> Dictionary:
	var r = combo_provider.call("card_completes", owned, core_id) if combo_provider != null \
		else CoreCombos.card_completes(owned, core_id)
	return r if r is Dictionary else {}


## Up to 2 owned Core ids that go with this card (chip "Works with").
static func combo_matches(owned: Array, core_id: String) -> Array:
	var r = combo_provider.call("matches", owned, core_id) if combo_provider != null \
		else CoreCombos.matches(owned, core_id)
	return (r as Array).slice(0, 2) if r is Array else []


static func combo_name(combo_id: String) -> String:
	if combo_provider != null:
		for row in combo_provider.call("all"):
			if row is Dictionary and String(row.get("id", "")) == combo_id:
				return String(row.get("name_en", combo_id))
		return ""
	var row := CoreCombos.get_combo(combo_id)
	return String(row.get("name_en", combo_id)) if not row.is_empty() else ""


## Core ids shown on the banner: 2 for Pair, 3 for Full (owned ones first, in combo order). [] if the combo is unknown.
static func combo_members(combo_id: String, tier: String) -> Array:
	if combo_provider != null:
		return []
	var row := CoreCombos.get_combo(combo_id)
	if row.is_empty():
		return []
	var m: Array = CoreCombos.members(row)
	var owned := owned_ids()
	var sorted: Array = m.filter(func(x): return owned.has(x)) + m.filter(func(x): return not owned.has(x))
	return sorted.slice(0, 3 if tier == "full" else 2)


## combo id -> tier for combos that were raised by going from `before` to `after` owned ids (Pair/Full just formed).
static func combos_formed(before: Array, after: Array) -> Array:
	var b: Dictionary = CoreCombos.state(before)
	var out: Array = []
	var st: Dictionary = CoreCombos.state(after)
	for id in st:
		if String(b.get(id, "")) != String(st[id]):
			out.append({"id": String(id), "tier": String(st[id])})
	return out


## Crystal card silhouette: bevelled (corner_detail 1) opposite corners, flat fill, tier border. No shader / gradient.
static func prism_style(accent: Color, selected := false) -> StyleBoxFlat:
	var sb := UI3Theme.flat(UI3Theme.color("panel_raised"), 32, UI3Theme.stroke("selected"),
		UI3Theme.color("selected_outline") if selected else accent, Vector4(24, 24, 24, 24))
	sb.corner_detail = 1
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	return sb


## Two thin extra rings inside the card (expand_margin on a free Panel): the "facets".
static func prism_frame(accent: Color) -> Panel:
	var f := Panel.new()
	f.name = "PrismFrame"
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := UI3Theme.flat(Color(0, 0, 0, 0), 24, UI3Theme.stroke("hairline"), UI3Theme.color("text"))
	sb.corner_detail = 1
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.expand_margin_left = 16
	sb.expand_margin_right = 16
	sb.expand_margin_top = 16
	sb.expand_margin_bottom = 16
	f.add_theme_stylebox_override("panel", sb)
	var inner := Panel.new()
	inner.name = "PrismInner"
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	var sb2 := sb.duplicate() as StyleBoxFlat
	sb2.border_color = accent
	sb2.expand_margin_left = 8
	sb2.expand_margin_right = 8
	sb2.expand_margin_top = 8
	sb2.expand_margin_bottom = 8
	inner.add_theme_stylebox_override("panel", sb2)
	f.add_child(inner)
	return f
