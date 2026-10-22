class_name BoLayer
extends Control
## Depth v4 Set frames over the dice tray (spec 1.2 / 1.4). Reads the engine snapshot `bo`, draws one flat frame
## per group plus its label; fours and fives also get a banner. No blur, no gradient. Never blocks input.
## Redraws only when asked (refresh) by CombatView, which does so on EventBus.bo_changed and after tray layout.

const FRAME_W := 4.0
const LABEL_H := 32.0
const BANNER_Y_FROM_TRAY := 84.0

var _groups: Array = []                 # [{rect: Rect2, label: String, size: int, tier4: bool}]
var _labels: Array[Label] = []
var _banner: Label = null
var _banner_tween: Tween = null
var label_lift := 0.0                   # raised while the REROLL chips sit above the cards
var cards_provider: Callable = Callable()   # () -> uid -> Rect2 in this layer's space; polled so frames follow a tray that moves
var _last_bo: Array = []
## group dict -> real M in percent (engine m100_for: Anchor/Embers/Overcast adds included). Unset = raw snapshot m100.
var m100_provider := Callable()
var _last_cards: Dictionary = {}
var last_banner: String = ""            # test hook
var _seen: Dictionary = {}              # part -> best size already announced this fight/turn
var _banner_key := Vector3i(-1, 0, 0)   # (part, size, m100) the visible banner announces


func _m100(g: Dictionary) -> int:
	if m100_provider.is_valid():
		return int(m100_provider.call(g))
	return int(g["m100"])


func _init() -> void:
	name = "BoLayer"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 7


## `cards`: uid -> Rect2 (global-in-layer rect of the tray card). `bo`: engine snapshot.
func refresh(bo: Array, cards: Dictionary) -> void:
	_last_bo = bo
	_last_cards = cards.duplicate()
	_drop_stale_banner(bo)
	_groups.clear()
	for g in bo:
		var r := Rect2()
		var first := true
		for uid in (g["uids"] as Array):
			if not cards.has(int(uid)):
				continue
			var cr: Rect2 = cards[int(uid)]
			r = cr if first else r.merge(cr)
			first = false
		if first:
			continue
		var sz := int(g["size"])
		var m := _m100(g)
		_groups.append({"rect": r.grow(6.0), "label": V4Ui.set_label(sz, m),
			"size": sz, "part": int(g["part"]), "m100": m})
	while _labels.size() < _groups.size():
		var l := UI3.label("", "LabelDisplay")
		l.add_theme_font_size_override("font_size", 24)
		l.add_theme_color_override("font_color", UI3Theme.color("accent_text"))
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var sb := UI3Theme.flat(UI3Theme.color("accent"), UI3Theme.radius("s"))
		sb.content_margin_left = 12
		sb.content_margin_right = 12
		l.add_theme_stylebox_override("normal", sb)
		l.name = "SetLabel%d" % _labels.size()
		add_child(l)
		_labels.append(l)
	for i in _labels.size():
		var l := _labels[i]
		l.visible = i < _groups.size()
		if l.visible:
			var gd: Dictionary = _groups[i]
			l.text = String(gd["label"])
			var r: Rect2 = gd["rect"]
			var w := maxf(l.get_minimum_size().x, 160.0)
			l.size = Vector2(w, LABEL_H)
			l.position = Vector2(r.position.x + (r.size.x - w) * 0.5, r.position.y - LABEL_H - 2.0 - label_lift)
	queue_redraw()


## The tray can move after the snapshot (layout pass, resize, mode switch): follow the live card rects so the
## label centre always equals the frame centre.
func _process(_dt: float) -> void:
	if not cards_provider.is_valid() or not visible:
		return
	var now: Dictionary = cards_provider.call()
	if now != _last_cards:
		refresh(_last_bo, now)


## The banner and the tray label must never disagree: a banner whose (part, size, multiplier) is no longer a
## current Set (reroll broke it, Wild changed it, a die was used) is cut at once instead of fading out.
func _drop_stale_banner(bo: Array) -> void:
	if _banner == null or not _banner.visible:
		return
	for g in bo:
		if Vector3i(int(g["part"]), int(g["size"]), _m100(g)) == _banner_key:
			return
	_banner.visible = false
	last_banner = ""
	if _banner_tween != null:
		_banner_tween.kill()


func _draw() -> void:
	var col := UI3Theme.color("accent")
	for gd in _groups:
		var r: Rect2 = gd["rect"]
		var w := FRAME_W + (2.0 if int(gd["size"]) >= 4 else 0.0)   # four / five: thicker frame
		draw_rect(r, col, false, w)


func group_labels() -> Array[String]:
	var out: Array[String] = []
	for gd in _groups:
		out.append(String(gd["label"]))
	return out


## Call when the engine snapshot changed: announces a NEW or HIGHER four / five with a banner.
func announce(bo: Array, tray_top: float) -> void:
	var live := {}
	for g in bo:
		live[int(g["part"])] = int(g["size"])
		var sz := int(g["size"])
		if V4Ui.has_banner(sz) and sz > int(_seen.get(int(g["part"]), 0)):
			_show_banner(V4Ui.banner_text(int(g["part"]), sz, _m100(g)), sz, tray_top,
				Vector3i(int(g["part"]), sz, _m100(g)))
	_seen = live


func _show_banner(text: String, size: int, tray_top: float, key := Vector3i(-1, 0, 0)) -> void:
	last_banner = text
	_banner_key = key
	if _banner == null:
		_banner = UI3.label("", "LabelDisplay")
		_banner.name = "SetBanner"
		_banner.add_theme_font_size_override("font_size", 36)
		_banner.add_theme_color_override("font_color", UI3Theme.color("accent_text"))
		_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sb := UI3Theme.flat(UI3Theme.color("accent"), UI3Theme.radius("m"), 4, UI3Theme.color("selected_outline"))
		sb.content_margin_left = 24
		sb.content_margin_right = 24
		_banner.add_theme_stylebox_override("normal", sb)
		add_child(_banner)
	_banner.text = text
	_banner.size = Vector2(_banner.get_minimum_size().x, 64.0)
	var vs := get_viewport_rect().size
	_banner.position = Vector2((vs.x - _banner.size.x) * 0.5, tray_top - BANNER_Y_FROM_TRAY - 64.0)
	_banner.visible = true
	_banner.modulate.a = 1.0
	if _banner_tween != null:
		_banner_tween.kill()
	if not is_inside_tree():
		return
	_banner_tween = create_tween()
	_banner_tween.tween_interval(V4Ui.banner_secs(size))
	if not (CombatView.disable_juice_for_tests or MetaState.reduce_flash):
		_banner_tween.tween_property(_banner, "modulate:a", 0.0, 0.15)   # reduce-flash: plain cut, no fade
	_banner_tween.tween_callback(func(): _banner.visible = false)


## Resets what was announced (new turn / new roll), so the next four announces again.
func reset_seen() -> void:
	_seen.clear()
