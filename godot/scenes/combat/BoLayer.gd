class_name BoLayer
extends Control
## UI-05 b1 lane B: the SET banners above the dice tray (README "Update · DieCard parts and SETs"). One SetBanner per live SET of
## the engine snapshot `bo`, in a centred row named SetBanners (set_banner_h high, kept when empty so the tray never jumps).
## This is the ONLY SET banner: the old floating "FOUR HORNS ×2.2!" label and the per-group frames are gone (each DieCard draws
## its SET ring now). A new or higher four / five pops its banner (scale, none with Reduce motion). Never blocks input.
## Redraws only when asked (refresh) by CombatView, on EventBus.bo_changed and after the tray layout.

var row: HBoxContainer
var _banners: Array[SetBanner] = []
var _row_rect := Rect2()
var _last_bo: Array = []
var _seen: Dictionary = {}              # part -> best size already announced this fight/turn
var _pop_tween: Tween = null
var _pop_until_ms := 0
var _last_key := Vector3i(-1, 0, 0)     # (part, size, m100) of the banner last announced
## Text of the SET last announced ("SET OF 4 ×2.2 · Mouth"), "" once that SET is gone (test hook, qa_smoke).
var last_banner: String = ""
## Kept so older callers still compile: banners have their own row now, they no longer follow the card rects.
var label_lift := 0.0
var cards_provider: Callable = Callable()
## group dict -> real M in percent (engine bo_group_m100: Anchor / Core set_add / Overcast / cap). Unset = raw snapshot m100.
var m100_provider := Callable()
## group dict -> {tex: Texture2D (part glyph), overcast: bool, tip: String}. Unset = no glyph, no Overcast mark.
var info_provider := Callable()


func _init() -> void:
	name = "BoLayer"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 7
	row = HBoxContainer.new()
	row.name = "SetBanners"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", UI3Theme.space("12"))
	add_child(row)


func _m100(g: Dictionary) -> int:
	if m100_provider.is_valid():
		return int(m100_provider.call(g))
	return int(g["m100"])


## Where the SetBanners row sits (DiceDock layout: the top band of the dock, dice_dock_w wide).
func set_row_rect(r: Rect2) -> void:
	_row_rect = r
	row.position = r.position
	row.size = r.size


## Rebuilds the banners from the engine snapshot `bo` (one per group, engine order: first SET colour a, second b).
## `_cards` is unused now (kept for the old signature).
func refresh(bo: Array, _cards: Dictionary = {}) -> void:
	_last_bo = bo
	while _banners.size() < bo.size():
		var nb := SetBanner.new()
		nb.name = "SetBanner" if _banners.is_empty() else "SetBanner%d" % _banners.size()
		row.add_child(nb)
		_banners.append(nb)
	var live_key := false
	for i in _banners.size():
		var b := _banners[i]
		b.visible = i < bo.size()
		if not b.visible:
			continue
		var g: Dictionary = bo[i]
		var info: Dictionary = info_provider.call(g) if info_provider.is_valid() else {}
		b.setup(int(g["part"]), int(g["size"]), _m100(g), String(SetPreview.SET_KEYS[i % SetPreview.SET_KEYS.size()]),
			info.get("tex", null), bool(info.get("overcast", false)), String(info.get("tip", "")))
		if b.key == _last_key:
			live_key = true
			last_banner = b.text
	if not live_key:
		_drop_announce()
	set_row_rect(_row_rect)


## The SET last announced is gone (reroll broke it, Wild changed it, the fight moved on): forget it at once.
func _drop_announce() -> void:
	last_banner = ""
	_last_key = Vector3i(-1, 0, 0)
	_pop_until_ms = 0
	if _pop_tween != null:
		_pop_tween.kill()
		_pop_tween = null
	for b in _banners:
		b.scale = Vector2.ONE


## Visible banners' tray labels, "SET OF 3 ×1.3" (same words as before UI-05).
func group_labels() -> Array[String]:
	var out: Array[String] = []
	for b in _banners:
		if b.visible:
			out.append(b.label)
	return out


## Visible banners' full text, "SET OF 4 ×2.2 · Mouth".
func banner_texts() -> Array[String]:
	var out: Array[String] = []
	for b in _banners:
		if b.visible:
			out.append(b.text)
	return out


## Visible SetBanner nodes, in engine order.
func banners() -> Array[SetBanner]:
	var out: Array[SetBanner] = []
	for b in _banners:
		if b.visible:
			out.append(b)
	return out


## True while a four / five pop is on screen (the coach bubble waits for it).
func banner_up() -> bool:
	return last_banner != "" and Time.get_ticks_msec() < _pop_until_ms


## Call when the engine snapshot changed: a NEW or HIGHER four / five pops its banner. `_tray_top` kept for the old signature.
func announce(bo: Array, _tray_top: float = 0.0) -> void:
	var live := {}
	for i in bo.size():
		var g: Dictionary = bo[i]
		var sz := int(g["size"])
		live[int(g["part"])] = sz
		if V4Ui.has_banner(sz) and sz > int(_seen.get(int(g["part"]), 0)) and i < _banners.size():
			_pop(_banners[i], sz)
	_seen = live


func _pop(b: SetBanner, sz: int) -> void:
	last_banner = b.text
	_last_key = b.key
	_pop_until_ms = Time.get_ticks_msec() + int(V4Ui.banner_secs(sz) * 1000.0)
	if _pop_tween != null:
		_pop_tween.kill()
	b.scale = Vector2.ONE
	if CombatView.disable_juice_for_tests or UI3Motion.reduced() or not is_inside_tree():
		return
	b.pivot_offset = b.size * 0.5
	_pop_tween = create_tween()
	_pop_tween.tween_property(b, "scale", Vector2.ONE * 1.12, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_pop_tween.tween_property(b, "scale", Vector2.ONE, 0.18)


## Resets what was announced (new turn / new roll), so the next four announces again.
func reset_seen() -> void:
	_seen.clear()
