extends Control
class_name UnitPortrait
## Feet-anchored Nameplate (review-uiux-battle-screen.md P0 #4: "bỏ hẳn hàng thẻ HP ... gắn
## nameplate ngay dưới chân từng Axie"). Positioned every frame by CombatView using
## CombatStage3D.get_unit_screen_pos(uid, CombatStage3D.FEET_HEIGHT) — this Control's
## top-center sits at that point (own width is fixed, see WIDTH, so centering never has to wait
## a frame on container layout).
##
## REBUILT (ui-programmer, nameplate-rebuild pass — bug report: name overlapped by the shield
## badge, two enemy nameplates touching, a 3-4px misaligned HP bar, ~10px HP numbers on bright
## sand; review-uiux-battle-screen.md P0 #5, P1 #6, P1 #10). Layout is now:
##   header row: NameLabel (left, expand) + HPLabel (right, "hp/max", 17px bold-via-outline)
##   HPBar: full width beneath the header, 14px
##   StatusRow: a row of pills (icon + stack count) under the HP bar, ONE PER ACTIVE STATUS —
##     hidden (0 height) when the unit has no active status, so a status-free unit's card stays
##     at its compact base size. This is what review P1 #10 ("icon trạng thái trôi tự do") asked
##     for: status now visibly belongs to this card instead of floating disconnected above the
##     head (see UnitHeadHUD.gd, which no longer draws them at all).
##   ShieldBadge: a small pill OVERLAPPING the top-right corner of the card (anchored outside
##     the header row, not squeezed into it) — this is what used to collide with long names; it
##     now overflows the corner instead of sharing the name's row.
## `update_stats()`'s `status` param used to be discarded (`_status`, unused) — CombatView.gd
## already passed it every frame, so wiring the status row up needed no CombatView.gd change.
##
## Icon source: assets/icons/web/ (the live web build's own icon set, src/art7.js) — the user's
## explicit requirement is that both builds show the same icons, unchanged.
##
## Class name kept as `UnitPortrait` (not renamed to e.g. `Nameplate`) to avoid an unrelated
## rename touching every call site (CombatView.gd, tests) for a purely cosmetic reason — see
## task report.

signal clicked(uid: int)

## Minimum plate width. Only a floor for very short names — the actual width comes from the
## name label's own measured text (see setup()), so a long name widens its plate and a short
## one does not. Sizing every plate to the LONGEST possible name instead made neighbouring
## enemy plates touch, which the UI review had already flagged once.
const WIDTH := 132.0

## status key -> web icon (assets/icons/web/, src/art7.js parity). Same 9 keys Unit.status can
## ever hold (unit.gd's own field comment: "poison/burn/regen/blind/weaken/vulnerable/thorns/
## stun/undying -> int stack count" — freeze is deliberately NOT one of them, it's the separate
## `frozen`/`frozen_next` bool pair, see that file). "vulnerable" is the one key whose web icon
## file is named differently ("vuln.png", not "vulnerable.png") — confirmed against
## tests/t_assets.gd's own REQUIRED_PNG_ICONS list before relying on it here.
const _STATUS_ICON := {
	"poison": preload("res://assets/icons/web/poison.png"),
	"burn": preload("res://assets/icons/web/burn.png"),
	"regen": preload("res://assets/icons/web/regen.png"),
	"blind": preload("res://assets/icons/web/blind.png"),
	"weaken": preload("res://assets/icons/web/weaken.png"),
	"vulnerable": preload("res://assets/icons/web/vuln.png"),
	"thorns": preload("res://assets/icons/web/thorns.png"),
	"stun": preload("res://assets/icons/web/stun.png"),
	"undying": preload("res://assets/icons/web/undying.png"),
}

# --- Juice tuning (unchanged from the pre-review pass) ---
## Float-text color per EventBus.float_text `css_class` payload — see report for the original
## grep across damage_pipeline.gd/status_engine.gd/combat_engine.gd float_text.emit() call sites.
const _FLOAT_COLOR := {
	"dmg": Color(0.95, 0.25, 0.2), "heal": Color(0.35, 0.9, 0.45), "shd": Color(0.55, 0.8, 1.0),
	"poi": Color(0.65, 0.35, 0.85), "buf": Color(1.0, 0.85, 0.3), "deb": Color(1.0, 0.55, 0.2),
	"man": Color(0.3, 0.9, 0.85),
}
const _FLOAT_CRIT_COLOR := Color(1.0, 0.78, 0.15)
const _CRIT_GLOW_OUTLINE_COLOR := Color(0.55, 0.08, 0.02)
const _CRIT_GLOW_SHADOW_COLOR := Color(0.35, 0.95, 1.0, 0.9)
const _CRIT_GLOW_OUTLINE_SIZE := 4
const _CRIT_GLOW_SHADOW_SIZE := 5
const _FLOAT_RISE := 40.0
const _FLOAT_DURATION := 0.7
const _RESONANCE_FLASH_COLOR := Color(1.6, 1.6, 0.8)
const _RESONANCE_FLASH_IN := 0.12
const _RESONANCE_FLASH_OUT := 0.18
const _DEATH_FADE_DURATION := 0.45

@onready var _card: PanelContainer = %Card
@onready var _name_label: Label = %NameLabel
@onready var _hp_label: Label = %HPLabel
@onready var _hp_bar: HPBar = %HPBar
@onready var _status_row: HBoxContainer = %StatusRow
@onready var _shield_badge: PanelContainer = %ShieldBadge
@onready var _shield_icon: TextureRect = %ShieldIcon
@onready var _shield_label: Label = %ShieldLabel
@onready var _click_catcher: Button = %ClickCatcher

var uid: int = -1
var _dying: bool = false   # true once play_death_fade() has been triggered — guards
	# update_stats() from clobbering the fade Tween's modulate (see that function's comment)
var _base_style: StyleBoxFlat
var _selected_style: StyleBoxFlat
var _targetable_style: StyleBoxFlat


func _ready() -> void:
	custom_minimum_size.x = WIDTH
	_shield_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE   # web icon (shield.png) doesn't
		# ship at exactly this 13x13 slot's size — see UnitHeadHUD._intent_icon's comment for
		# the same TextureRect sizing gotcha
	_shield_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_click_catcher.pressed.connect(func(): clicked.emit(uid))

	_base_style = DangoTheme.panel_style(DangoTheme.BG_PANEL_SOFT, 2, 8, 5.0)
	_selected_style = DangoTheme.panel_style(DangoTheme.BG_PANEL, 3, 8, 5.0)
	_selected_style.border_color = DangoTheme.PRIMARY
	_selected_style.shadow_color = Color(DangoTheme.PRIMARY.r, DangoTheme.PRIMARY.g, DangoTheme.PRIMARY.b, 0.6)
	_selected_style.shadow_size = 8
	_targetable_style = DangoTheme.panel_style(DangoTheme.BG_PANEL_SOFT, 2, 8, 5.0)
	_targetable_style.border_color = DangoTheme.INFO
	_card.add_theme_stylebox_override("panel", _base_style)


## Called once per unit when a combat starts (CombatView._spawn_portrait).
func setup(p_uid: int, display_name: String, _cls: String, _is_enemy: bool) -> void:
	uid = p_uid
	_name_label.text = display_name
	# The label is EXPAND_FILL inside its row, so Godot lets it shrink to nothing and clip the
	# text — which is how "Venomaw" once rendered as "Venon" and "FROST LORD" as "FRC". Telling
	# the label its own text width makes the card's combined minimum account for the name, so
	# every plate ends up exactly as wide as it needs and no wider. A blanket floor would fix
	# the clipping too, but at the cost of padding short names out until neighbouring plates
	# touch each other.
	var font := _name_label.get_theme_font("font")
	var font_size := _name_label.get_theme_font_size("font_size")
	if font != null:
		_name_label.custom_minimum_size.x = font.get_string_size(
			display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	_resync_size()


## Called from CombatView._rebuild_all() — the single "read model, redraw" entry point.
## Deliberately does NOT force modulate/visibility while _dying is true — see play_death_fade().
## `status` used to be discarded (`_status`, unused) — now drives _rebuild_status_pills(); see
## class comment for why this needed no CombatView.gd change.
func update_stats(hp: int, max_hp: int, shield: int, status: Dictionary) -> void:
	_hp_bar.set_stats(hp, max_hp, shield)
	_hp_label.text = "%d/%d" % [maxi(hp, 0), maxi(max_hp, 1)]
	_shield_badge.visible = shield > 0
	if shield > 0:
		_shield_label.text = str(shield)
	_rebuild_status_pills(status)
	_resync_size()
	if hp > 0:
		_dying = false
		visible = true
		modulate = Color(1, 1, 1, 1)
	elif not _dying:
		modulate = Color(1, 1, 1, 0)
		visible = false


## Status-effect pills — moved here from UnitHeadHUD.gd (see class comment). One pill per
## active status (icon + stack count), hidden entirely when there are none so a status-free
## unit's card doesn't grow past its base header+bar size.
func _rebuild_status_pills(status: Dictionary) -> void:
	for c in _status_row.get_children():
		c.queue_free()
	for key in _STATUS_ICON:
		var v := int(status.get(key, 0))
		if v <= 0:
			continue
		var chip := PanelContainer.new()
		chip.add_theme_stylebox_override("panel", DangoTheme.panel_style(Color(0.04, 0.04, 0.06, 0.85), 1, 8, 3.0))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 2)
		var icon := TextureRect.new()
		icon.texture = _STATUS_ICON[key]
		icon.custom_minimum_size = Vector2(15, 15)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE   # see _ready()'s shield-icon comment —
			# same web-icon-not-exactly-this-size gotcha applies to every status icon here
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)
		var lbl := Label.new()
		lbl.text = str(v)
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", Color.WHITE)
		lbl.add_theme_color_override("font_outline_color", Color.BLACK)
		lbl.add_theme_constant_override("outline_size", 2)
		row.add_child(lbl)
		chip.add_child(row)
		_status_row.add_child(chip)
	_status_row.visible = _status_row.get_child_count() > 0


## `UnitPortrait` is a plain Control, not a Container, so it does not automatically grow to fit
## `_card`'s own content (the status-pill row's visibility toggling above changes `_card`'s
## combined minimum size every time it flips). Called after every content change
## (update_stats() above) rather than relying on Godot to propagate a child's
## minimum_size_changed signal up through a non-Container parent, which it does not do for
## free. `size` is also set explicitly (not just custom_minimum_size) because CombatView.gd's
## _layout_unit_visuals() reads `UnitPortrait.WIDTH` (a constant) for its own x-centering math,
## not this control's live `size` — but ClickCatcher/anything anchored fill to THIS Control
## still needs `size` itself to be correct, not just the minimum-size hint.
func _resync_size() -> void:
	var min_size := _card.get_combined_minimum_size()
	# WIDTH is a FLOOR, not a suggestion. The name label is EXPAND_FILL inside its row, so its
	# own minimum width is effectively zero — the card's combined minimum therefore does NOT
	# account for the text, and taking it verbatim let the plate collapse until the name was
	# clipped mid-glyph. That misreads badly: "Venomaw" clipped after the 'm' looks like
	# "Venon", and "FROST LORD" looks like "FRC" — a corrupt name, not a truncated one.
	min_size.x = maxf(min_size.x, WIDTH)
	custom_minimum_size = min_size
	size = min_size


func set_selected(v: bool) -> void:
	_card.add_theme_stylebox_override("panel", _selected_style if v else _base_style)


## View-only "plausible click target" affordance — see CombatStage3D.gd's set_targetable() for
## the full rationale. Never called for the currently-selected unit's own card (CombatView
## guards this), so it never fights set_selected()'s style above.
func set_targetable(v: bool) -> void:
	_card.add_theme_stylebox_override("panel", _targetable_style if v else _base_style)


## Damage-preview passthrough to the embedded HPBar — review P0 #2 ("vệt đỏ nhạt ngay trên
## thanh"), driven by CombatView hover handlers (die-tray hover / enemy-intent hover).
func set_preview_damage(dmg: int) -> void:
	_hp_bar.set_preview(dmg)


func clear_preview_damage() -> void:
	_hp_bar.clear_preview()


# ===========================================================================
# Juice (checklist step 7) — each triggered directly from a CombatView.gd EventBus handler
# using ONLY that signal's own payload. Checks CombatView.disable_juice_for_tests first and, in
# that mode, creates no Tween at all (see that file's HEADLESS TEST MODE comment).
# ===========================================================================

func spawn_float_text(text: String, css_class: String, big: int) -> void:
	if CombatView.disable_juice_for_tests or not is_inside_tree():
		return
	var lbl := Label.new()
	lbl.text = text
	var is_crit := css_class == "dmg" and big >= 2
	var color: Color = _FLOAT_CRIT_COLOR if is_crit else _FLOAT_COLOR.get(css_class, Color.WHITE)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", 26 if big >= 2 else (20 if big == 1 else 15))
	if is_crit:
		lbl.add_theme_color_override("font_outline_color", _CRIT_GLOW_OUTLINE_COLOR)
		lbl.add_theme_constant_override("outline_size", _CRIT_GLOW_OUTLINE_SIZE)
		lbl.add_theme_color_override("font_shadow_color", _CRIT_GLOW_SHADOW_COLOR)
		lbl.add_theme_constant_override("shadow_offset_x", 0)
		lbl.add_theme_constant_override("shadow_offset_y", 0)
		lbl.add_theme_constant_override("shadow_outline_size", _CRIT_GLOW_SHADOW_SIZE)
	lbl.z_index = 5
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.position = Vector2(size.x * 0.5 - 20.0 + randf_range(-10.0, 10.0), -18.0)
	add_child(lbl)

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", lbl.position.y - _FLOAT_RISE, _FLOAT_DURATION)
	tw.tween_property(lbl, "modulate:a", 0.0, _FLOAT_DURATION)
	tw.chain().tween_callback(lbl.queue_free)


## Brighten-then-settle flash (same recipe as the pre-review pass, just on `modulate` instead
## of `self_modulate` — this card's tint is no longer "free" for juice to borrow now that
## set_selected()/set_targetable() communicate via stylebox swaps instead of a self_modulate
## tint). Respects whatever alpha update_stats()/play_death_fade() currently has it at.
func flash_resonance() -> void:
	if CombatView.flashes_suppressed() or not is_inside_tree():
		return
	var base := modulate
	var flash := _RESONANCE_FLASH_COLOR
	flash.a = base.a
	var tw := create_tween()
	tw.tween_property(self, "modulate", flash, _RESONANCE_FLASH_IN)
	tw.tween_property(self, "modulate", base, _RESONANCE_FLASH_OUT)


func play_death_fade() -> void:
	if _dying or not is_inside_tree():
		return
	_dying = true
	if CombatView.disable_juice_for_tests:
		modulate.a = 0.0
		visible = false
		return
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, _DEATH_FADE_DURATION)
	tw.finished.connect(func(): visible = false)
