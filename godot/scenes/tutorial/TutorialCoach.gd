extends CanvasLayer
class_name TutorialCoach
## The onboarding coach: everything the tutorial draws ON TOP of the real combat screen.
##
## It owns no game state and reads no engine. TutorialView.gd decides what the current step is
## and calls into here; this file only knows how to dim the screen, cut a hole in the dim, and
## put a card next to the hole. That split is what lets the tutorial run on the production
## Combat.tscn instead of a hand-built stand-in of it.
##
## HOW THE DIM AND THE CLICK-LOCK ARE THE SAME THING. The dim is not one translucent sheet with
## a shader hole punched in it — it is FOUR opaque-ish bands (above / below / left / right of
## the spotlight rect), each MOUSE_FILTER_STOP. So the lit rectangle is literally a gap in the
## overlay: a click there reaches whatever is underneath with no forwarding, no
## `set_input_as_handled()`, and no "which control was under the cursor" arithmetic that could
## disagree with what the player can see. Everywhere else, the click hits a band and stops.
##
## The bands are the VISIBLE lock only. The step-lock that actually has to hold is
## CombatView._gated() — Space, Escape and CombatStage3D's own unit_clicked path never travel
## through this overlay at all. See CombatView's `_tutorial` comment.

signal cta_pressed
signal reward_chosen(index: int)
## What skipping loses, said in the corner button tooltip and in the confirm.
const SKIP_WHAT := "You miss the step-by-step tips on rolling dice, picking targets and Cores."

signal skip_pressed

const Parts := preload("res://scenes/tutorial/ui5/TutorialParts.gd")
const RewardCardUi := preload("res://scenes/shared/ui5/RewardCard.gd")
const _GAP := 18.0          # between the spotlight edge and the card
const _MARGIN := 24.0       # minimum distance from any screen edge
const _HOLE_PAD := 10.0     # how far the lit rect is grown past the control it frames
const _STARTER_ICONS := {"Shard": "res://assets/ui3/icons/cur_shard.png", "Ticket": "res://assets/ui3/icons/cur_ticket.png",
	"Gem": "res://assets/ui3/icons/cur_gem.png"}

var _DIM := Color(0.075, 0.086, 0.106, 0.7)   # scrim rgb at 70% (the frame's spotlight dim), set in _ready
var _bands: Array[ColorRect] = []
var _ring: Panel
var _ring_style: StyleBoxFlat
var _ring_tween: Tween

var _card: PanelContainer
var _card_title: Label
var _card_body: Label
var _card_cta: Button
var _card_step: Label
var _card_skip: Button

var _curtain: Control
var _scrim: ColorRect
var _curtain_title: Label
var _curtain_body: Label
var _curtain_cta: Button
var _curtain_skip: Button
var _starter: PanelContainer
var _starter_line: Label
var _starter_row: HBoxContainer
var _reward: Control          # TutorialRewardPick
var _reward_row: HBoxContainer
var _reward_cards: Array = []
var _reward_sel := -1
var _take: Button
var _skip_modal: Control
var _root: Control

var _target: Control = null
var _target_rect: Rect2 = Rect2()
var _has_hole: bool = false
var _dim: bool = false
var _last_hole: Rect2 = Rect2(-1, -1, -1, -1)
var _last_card_size: Vector2 = Vector2(-1, -1)


func _init() -> void:
	layer = 30   # above CombatView's own board (0) and its Info panel (29)


func _ready() -> void:
	_root = Control.new()
	_root.name = "TutorialPanel"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = UI3Theme.get_theme()
	var sc := UI3Theme.color("scrim")
	_DIM = Color(sc.r, sc.g, sc.b, 0.7)
	add_child(_root)

	for _i in 4:
		var band := ColorRect.new()
		band.name = "Dim"
		band.color = _DIM
		band.mouse_filter = Control.MOUSE_FILTER_STOP
		_root.add_child(band, true)
		_bands.append(band)

	_ring = Panel.new()
	_ring.name = "Spotlight"
	_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ring_style = StyleBoxFlat.new()
	_ring_style.bg_color = Color(0, 0, 0, 0)
	_ring_style.border_color = UI3Theme.color("coach_ring")
	_ring_style.set_border_width_all(UI3Theme.stroke("selected"))
	_ring_style.set_corner_radius_all(UI3Theme.radius("xl"))
	_ring.add_theme_stylebox_override("panel", _ring_style)
	_root.add_child(_ring)

	_build_card()
	_build_curtain()
	_build_reward()
	clear()


func _build_card() -> void:
	_card = Parts.step_card()
	_root.add_child(_card)
	_card_step = _card.find_child("StepLabel", true, false) as Label
	_card_title = _card.find_child("Title", true, false) as Label
	_card_body = _card.find_child("Body", true, false) as Label
	_card_skip = _card.find_child("SkipButton", true, false) as Button
	_card_cta = _card.find_child("GotItButton", true, false) as Button
	_card_skip.tooltip_text = SKIP_WHAT
	_card_skip.pressed.connect(_ask_skip)
	_card_cta.pressed.connect(func(): cta_pressed.emit())


func _build_curtain() -> void:
	_scrim = ColorRect.new()
	_scrim.name = "Scrim"
	_scrim.color = UI3Theme.color("scrim")
	_scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	_scrim.add_to_group("ui3_modal")   # no HUD tooltip while the welcome / end / starter screens are up (BUG-0005)
	_root.add_child(_scrim)

	_curtain = CenterContainer.new()
	_curtain.name = "Curtain"
	_curtain.set_anchors_preset(Control.PRESET_FULL_RECT)
	_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_curtain)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UI3Theme.space("24"))
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	_curtain.add_child(col)

	_curtain_title = UI3.label("", "LabelScreenTitle")
	_curtain_title.name = "Title"
	_curtain_title.add_theme_font_size_override("font_size", UI3Theme.size_of("text_banner"))
	_curtain_title.add_theme_color_override("font_color", UI3Theme.color("text"))
	_curtain_title.add_theme_color_override("font_shadow_color", UI3Theme.color("plate_ink"))
	_curtain_title.add_theme_constant_override("shadow_offset_y", 4)
	_curtain_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_curtain_title)

	_curtain_body = UI3.label("")
	_curtain_body.name = "Body"
	_curtain_body.custom_minimum_size = Vector2(UI3Theme.size_of("curtain_body_w"), 0)
	_curtain_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_curtain_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_curtain_body)

	# StarterPackCard: plate 560, pad 32, gap 16: line, then a row of cells (Shard / Ticket / Gem).
	_starter = Parts.PanelParts.panel(Ui5HudStyle.plate_box(UI3Theme.radius("l"), Vector4(32, 32, 32, 32)), "StarterPackCard")
	_starter.custom_minimum_size = Vector2(UI3Theme.size_of("starter_card_w"), 0)
	_starter.visible = false
	var sv := VBoxContainer.new()
	sv.add_theme_constant_override("separation", UI3Theme.space("16"))
	_starter.add_child(sv)
	_starter_line = Parts.PanelParts.text("", "text_title", "text", true)
	_starter_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_starter_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_starter_line.custom_minimum_size.x = UI3Theme.size_of("starter_card_w") - 64.0
	sv.add_child(_starter_line)
	_starter_row = HBoxContainer.new()
	_starter_row.name = "Cells"
	_starter_row.add_theme_constant_override("separation", UI3Theme.space("12"))
	sv.add_child(_starter_row)
	col.add_child(_starter)

	_curtain_cta = UI3.button("", &"primary", &"L")
	_curtain_cta.name = "CtaButton"
	_curtain_cta.custom_minimum_size.x = 260
	_curtain_cta.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_curtain_cta.pressed.connect(func(): cta_pressed.emit())
	col.add_child(_curtain_cta)

	_curtain_skip = UI3.button(TranslationServer.translate("Skip tutorial"), &"secondary", &"S")
	_curtain_skip.name = "SkipTutorialButton"
	_curtain_skip.tooltip_text = SKIP_WHAT
	_curtain_skip.focus_mode = Control.FOCUS_NONE
	_curtain_skip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_curtain_skip.pressed.connect(_ask_skip)
	col.add_child(_curtain_skip)


## TutorialRewardPick: Title, Body, CardRow of three RewardCards, Footer > TakeButton (off and saying why until a pick).
func _build_reward() -> void:
	_reward = CenterContainer.new()
	_reward.name = "TutorialRewardPick"
	_reward.set_anchors_preset(Control.PRESET_FULL_RECT)
	_reward.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_reward)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UI3Theme.space("24"))
	_reward.add_child(col)
	var t := Parts.PanelParts.text("", "text_banner", "text", true)
	t.name = "Title"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(t)
	var b := Parts.PanelParts.text("")
	b.name = "Body"
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size.x = UI3Theme.size_of("curtain_body_w")
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(b)
	_reward_row = HBoxContainer.new()
	_reward_row.name = "CardRow"
	_reward_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_reward_row.add_theme_constant_override("separation", UI3Theme.space("12"))
	_reward_row.custom_minimum_size.y = UI3Theme.size_of("reward_card_h")
	_reward_row.sort_children.connect(_lift_selected)
	col.add_child(_reward_row)
	var foot := HBoxContainer.new()
	foot.name = "Footer"
	foot.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(foot)
	_take = UI3.button(TranslationServer.translate("Take"), &"primary", &"L")
	_take.name = "TakeButton"
	_take.custom_minimum_size.x = UI3Theme.size_of("d_take_min_w")
	_take.pressed.connect(func(): if _reward_sel >= 0: reward_chosen.emit(_reward_sel))
	foot.add_child(_take)


func _lift_selected() -> void:
	for c in _reward_cards:
		if is_instance_valid(c):
			c.position.y -= float(c.call("lift_px"))


func _select_reward(i: int) -> void:
	_reward_sel = i
	for k in _reward_cards.size():
		(_reward_cards[k] as Control).call("set_selected", k == i)
	_reward_row.queue_sort()
	_refresh_take()


func _refresh_take() -> void:
	if _reward_sel < 0:
		Parts.remove_space_cap(_take)
		UI3.set_disabled_reason(_take, TranslationServer.translate("Pick a reward"))
	else:
		if _take.disabled:
			UI3.clear_disabled_reason(_take)
		Parts.add_space_cap(_take)


## Skip (button or Esc) asks first: UI3 modal, Keep going focused (Space); only the confirm emits `skip_pressed`.
func _ask_skip() -> void:
	if _skip_modal != null and is_instance_valid(_skip_modal):
		return
	var keep := UI3.button(TranslationServer.translate("Keep going"), &"secondary")
	keep.name = "KeepGoingButton"
	keep.set_meta("cap_variant", &"plain")
	var go := UI3.button(TranslationServer.translate("Skip tutorial"), &"primary")
	go.name = "SkipTutorialButton"
	var m := UI3.modal("Skip the tutorial?", SKIP_WHAT + " You can replay it any time from Settings.", [keep, go], 0)
	m.name = "SkipConfirm"
	_skip_modal = m
	keep.pressed.connect(func(): m.queue_free())
	m.cancelled.connect(func(): m.queue_free())
	go.pressed.connect(func():
		m.queue_free()
		skip_pressed.emit())
	_root.add_child(m)
	Parts.add_space_cap(keep)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _starter != null and _starter.is_visible_in_tree():
		cta_pressed.emit()   # 38: Esc = Go to the Land
		if is_inside_tree():   # a handler above may have changed scene
			get_viewport().set_input_as_handled()
		return
	# Esc = Skip tutorial (asks to confirm). The open modal handles its own Esc (Cancel).
	if event.is_action_pressed("ui_cancel") and (_card.visible or _scrim.visible) \
			and (_skip_modal == null or not is_instance_valid(_skip_modal)):
		_ask_skip()
		if is_inside_tree():   # a handler above may have changed scene
			get_viewport().set_input_as_handled()


# ===========================================================================
# Public API — TutorialView drives all of it
# ===========================================================================

func _hide_all() -> void:
	_has_hole = false
	_dim = false
	_target = null
	_card.visible = false
	_ring.visible = false
	_scrim.visible = false
	_curtain.visible = false
	_reward.visible = false
	for b in _bands:
		b.visible = false


func clear() -> void:
	_hide_all()


## A coached step: dim everything, cut a hole around `target` (a Control on the combat screen,
## or null for "no hole — dim nothing, just show the card"), and put the card beside it.
## `dim=false` is the free-play case: nothing is dimmed and nothing is blocked.
## The card's Skip is always there; the Got it button (with the Space keycap) only when `cta` is not empty.
func show_step(step_label: String, title: String, body: String, cta: String,
		target: Control, extra_rect: Rect2 = Rect2(), dim: bool = true) -> void:
	_hide_all()
	_target = target
	_target_rect = extra_rect
	_has_hole = target != null or extra_rect.size.x > 0.0
	_dim = dim and _has_hole

	_card_step.text = step_label
	_card_step.visible = step_label != ""
	_card_title.text = title
	_card_body.text = body
	_card_body.visible = body != ""
	_card_cta.text = cta
	_card_cta.visible = cta != ""
	_card.visible = true
	_ring.visible = _dim
	for b in _bands:
		b.visible = _dim
	if cta != "":
		Parts.add_space_cap(_card_cta)
		_card_cta.focus_mode = Control.FOCUS_ALL
		_card_cta.grab_focus.call_deferred()
	else:
		Parts.remove_space_cap(_card_cta)
	_last_hole = Rect2(-1, -1, -1, -1)   # force a re-place now that the text changed
	_place()
	_pulse_ring()


## A full-screen moment with nothing behind it to teach: welcome, win, loss. Scrim over the real combat.
func show_curtain(title: String, body: String, cta: String, skip := true) -> void:
	_hide_all()
	_scrim.color = UI3Theme.color("scrim")
	_scrim.visible = true
	_curtain.visible = true
	_curtain_body.visible = body != ""
	_curtain_title.text = title
	_curtain_body.text = body
	_curtain_cta.text = cta
	_curtain_cta.visible = cta != ""
	_curtain_skip.visible = skip
	_starter.visible = false
	UI3Tooltip.hide_all(get_tree())   # a plate raised by the HUD just before the curtain must not stay on top of it
	if cta != "":
		Parts.add_space_cap(_curtain_cta)
		_curtain_cta.grab_focus.call_deferred()


## 38: the starter pack after the tutorial. `entries` = [{"label": "Shards", "value": "500", "sub": "..."}].
## Read-only: the grant is MetaState's own (daily.json "starter"); this only shows it.
func show_starter(title: String, line: String, entries: Array, cta: String) -> void:
	show_curtain(title, "", cta)
	_curtain_body.visible = false
	_curtain_skip.visible = false
	_starter.visible = true
	_starter_line.text = line
	for c in _starter_row.get_children():
		_starter_row.remove_child(c)
		c.queue_free()
	for e in entries:
		var lab := String(e.get("label", ""))
		var kind := lab.trim_suffix("s")
		var tex: Texture2D = load(String(_STARTER_ICONS.get(kind, _STARTER_ICONS["Gem"]))) as Texture2D
		_starter_row.add_child(Parts.starter_cell(kind, tex, String(e.get("value", "")), lab, String(e.get("sub", ""))), true)
	_curtain_cta.grab_focus.call_deferred()


## The reward beat: Scrim + TutorialRewardPick. Nothing is picked until the player picks (Take is off and says so).
func show_rewards(title: String, body: String, flavors: Array) -> void:
	_hide_all()
	_scrim.color = UI3Theme.color("scrim")
	_scrim.visible = true
	_reward.visible = true
	(_reward.find_child("Title", true, false) as Label).text = title
	(_reward.find_child("Body", true, false) as Label).text = body
	for c in _reward_row.get_children():
		_reward_row.remove_child(c)
		c.queue_free()
	_reward_cards.clear()
	for i in flavors.size():
		var card := _reward_card(flavors[i], i)
		_reward_row.add_child(card, true)
		_reward_cards.append(card)
	_select_reward(-1)
	_reward_cards[0].grab_focus.call_deferred()


func _reward_card(f: Dictionary, index: int) -> PanelContainer:
	var rar := String(f.get("rarity", "Common"))
	var col := UI3Theme.color("rarity_rare" if rar == "Rare" else "rarity_common")
	var card := RewardCardUi.new()
	card.name = "RewardCard"
	card.setup(String(f.get("category", "")), rar, col, UI3.icon(String(f.get("icon", "ui_mooncard"))), String(f.get("title", "")))
	var d := Parts.PanelParts.text(String(f.get("desc", "")))
	d.name = "RewardBody"
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size.x = UI3Theme.size_of("reward_card_w") - 2 * UI3Theme.space("20")
	card.text_box.add_child(d)
	card.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_select_reward(index)
			_take.grab_focus()   # Take shows the Space cap now, so Space must press it, not re-pick the card
		elif ev.is_action_pressed("ui_accept") and not ev.is_echo():
			_select_reward(index)
			_take.grab_focus())
	return card


# ===========================================================================
# Layout
# ===========================================================================

func _process(_delta: float) -> void:
	if _has_hole:
		_place()


func _hole_rect() -> Rect2:
	var r := _target_rect
	if is_instance_valid(_target) and _target.is_visible_in_tree():
		r = _target.get_global_rect()
	return r.grow(_HOLE_PAD)


func _place() -> void:
	var screen := Vector2(_root.size)
	if screen.x <= 0.0:
		screen = Vector2(get_viewport().get_visible_rect().size)
	var hole := _hole_rect().intersection(Rect2(Vector2.ZERO, screen))
	if hole.size.x <= 0.0 or hole.size.y <= 0.0:
		hole = Rect2(screen * 0.5, Vector2.ZERO)
	var card_size := _card.get_combined_minimum_size()
	card_size.x = maxf(card_size.x, UI3Theme.size_of("step_card_w"))
	if hole.is_equal_approx(_last_hole) and card_size.is_equal_approx(_last_card_size):
		return
	_last_hole = hole
	_last_card_size = card_size

	# Four bands, no overlap: anything outside the hole is covered exactly once (the visible click-lock).
	_set_band(0, Rect2(0, 0, screen.x, hole.position.y))
	_set_band(1, Rect2(0, hole.end.y, screen.x, screen.y - hole.end.y))
	_set_band(2, Rect2(0, hole.position.y, hole.position.x, hole.size.y))
	_set_band(3, Rect2(hole.end.x, hole.position.y, screen.x - hole.end.x, hole.size.y))

	_ring.position = hole.position
	_ring.size = hole.size
	if not _dim:
		for b in _bands:
			b.visible = false

	var above := hole.position.y > screen.y * 0.5
	var y := (hole.position.y - _GAP - card_size.y) if above else (hole.end.y + _GAP)
	var x := hole.get_center().x - card_size.x * 0.5
	_card.position = Vector2(
		clampf(x, _MARGIN, maxf(_MARGIN, screen.x - card_size.x - _MARGIN)),
		clampf(y, _MARGIN, maxf(_MARGIN, screen.y - card_size.y - _MARGIN)))
	_card.size = card_size


func _set_band(i: int, r: Rect2) -> void:
	var b := _bands[i]
	b.position = r.position
	b.size = Vector2(maxf(r.size.x, 0.0), maxf(r.size.y, 0.0))


## A slow breath on the ring, so the eye finds the lit control without an arrow pointing at it.
func _pulse_ring() -> void:
	if _ring_tween != null and _ring_tween.is_valid():
		_ring_tween.kill()
	_ring.modulate.a = 1.0
	if not _dim or UI3Motion.reduced():
		return
	_ring_tween = create_tween().set_loops()
	_ring_tween.tween_property(_ring, "modulate:a", 0.35, 0.65) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_ring_tween.tween_property(_ring, "modulate:a", 1.0, 0.65) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
