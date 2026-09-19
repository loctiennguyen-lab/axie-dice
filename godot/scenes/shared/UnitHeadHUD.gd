extends Control
class_name UnitHeadHUD
## Above-head INTENT badge only (review-uiux-battle-screen.md P0 #3 "badge intent nổi trên đầu
## quái"). Positioned every frame by CombatView using
## CombatStage3D.get_unit_screen_pos(uid, CombatStage3D.HEAD_HEIGHT) — this Control's `position`
## is recomputed so its BOTTOM edge sits at that head point (content grows upward as rows
## appear), width is fixed (see WIDTH) rather than measured, so positioning never has to wait a
## frame on container layout.
##
## STATUS ICONS MOVED OUT (ui-programmer, nameplate-rebuild pass — bug report: "icon trạng thái
## trôi tự do, không gắn vào ai", review-uiux-battle-screen.md P1 #10). They used to float here,
## above the head, disconnected from any visible "owner" line. They now live on the owning
## UnitPortrait (the feet Nameplate) instead, as a row of pills under the HP bar — see that
## file's `_status_row`. `set_status()` below is kept as a callable no-op purely because
## CombatView.gd calls it unconditionally every frame and this file may not edit that call site;
## it does nothing on purpose, not by omission.
##
## Icon source (ui-programmer, web-icon-parity pass): swapped from the Axie Origins Kit set
## (assets/icons/intent/, assets/icons/status_origins/) to assets/icons/web/ — the user's
## explicit requirement is that the Godot build reuse the SAME icons as the live web build
## (src/art7.js), unchanged. This also drops the old per-magnitude dmg-icon tiering
## (WeakAttack/AttackMelee/StrongAttack): the web build has no such tiering, just one dmg icon
## plus the rolled number itself (already shown via `_intent_number`), so matching it means
## simplifying, not porting the tiering across.

signal intent_hover_changed(uid: int, hovering: bool)

const WIDTH := 120.0
const _ICON_SIZE := Vector2(20, 20)

## Enemy-intent face `type` -> web icon (src/art7.js parity, see class comment). `blank` is the
## fix for a real bug (production/qa/evidence/2026-09-18_real-flow-varied-enemies.png, bug
## report P0 #2): combat_engine.gd's `_do_face()` (line ~677) treats face type "blank" as a
## real, legal "this face does nothing" — it is NOT a hidden/unknown intent, so it must not
## render as one. Before this fix, "blank" fell into the `_:` default below and rendered as a
## literal question mark, indistinguishable from a genuinely hidden intent (a case that does
## not exist anywhere in this game today — rule spec §2 "minh bạch triệt để", enemy intent is
## always public). The `_:` default is kept as a true last-resort fallback for a
## future/unrecognized face type, and — per that same "never actually hidden today" fact — is
## drawn as a plain "?" in the existing number Label rather than a new icon asset, since no web
## icon for "hidden" exists to reuse.
const _INTENT_ICON := {
	"dmg": preload("res://assets/icons/web/dmg.png"),
	"shield": preload("res://assets/icons/web/shield.png"),
	"heal": preload("res://assets/icons/web/heal.png"),
	"mana": preload("res://assets/icons/web/mana.svg"),
	"summon": preload("res://assets/icons/web/summon.png"),
	"buff": preload("res://assets/icons/web/buff.svg"),
	"poison": preload("res://assets/icons/web/poison.png"),
	"debuff": preload("res://assets/icons/web/debuff.svg"),
	"blank": preload("res://assets/icons/web/blank.svg"),
}

const _INTENT_TYPE_COLOR := {
	"dmg": DangoTheme.DANGER, "shield": DangoTheme.INFO, "heal": DangoTheme.SUCCESS,
	"poison": Color(0.65, 0.35, 0.85), "mana": DangoTheme.INFO,
	"debuff": DangoTheme.PRIMARY, "buff": DangoTheme.PRIMARY,
}

var uid: int = -1
var _column: VBoxContainer
var _intent_panel: PanelContainer
var _intent_icon: TextureRect
var _intent_number: Label
var _intent_target_label: Label
var _intent_style: StyleBoxFlat


func _init() -> void:
	custom_minimum_size = Vector2(WIDTH, 0)
	size = Vector2(WIDTH, 0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_column = VBoxContainer.new()
	_column.custom_minimum_size = Vector2(WIDTH, 0)
	_column.add_theme_constant_override("separation", 2)
	_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_column)

	_intent_panel = PanelContainer.new()
	_intent_panel.visible = false
	_intent_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_intent_panel.mouse_entered.connect(func(): intent_hover_changed.emit(uid, true))
	_intent_panel.mouse_exited.connect(func(): intent_hover_changed.emit(uid, false))
	_intent_style = DangoTheme.panel_style(Color(0.04, 0.04, 0.06, 0.9), 2, 8, 5.0)
	_intent_panel.add_theme_stylebox_override("panel", _intent_style)
	var intent_row := HBoxContainer.new()
	intent_row.add_theme_constant_override("separation", 4)
	_intent_icon = TextureRect.new()
	_intent_icon.custom_minimum_size = _ICON_SIZE
	_intent_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE   # web icon PNGs/SVGs (see class
		# comment) don't all ship at exactly this 20x20 badge slot's size — EXPAND_KEEP_SIZE
		# (the TextureRect default) would let a texture's own native size win over
		# custom_minimum_size in the container's minimum-size math; IGNORE_SIZE keeps every
		# intent icon the same badge size regardless of its source resolution.
	_intent_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	intent_row.add_child(_intent_icon)
	_intent_number = Label.new()
	_intent_number.add_theme_font_size_override("font_size", 22)
	_intent_number.add_theme_color_override("font_color", Color.WHITE)
	_intent_number.add_theme_color_override("font_outline_color", Color.BLACK)
	_intent_number.add_theme_constant_override("outline_size", 3)
	intent_row.add_child(_intent_number)
	_intent_panel.add_child(intent_row)
	_column.add_child(_intent_panel)

	_intent_target_label = Label.new()
	_intent_target_label.visible = false
	_intent_target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_intent_target_label.add_theme_font_size_override("font_size", 11)
	_intent_target_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	_intent_target_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_intent_target_label.add_theme_constant_override("shadow_offset_x", 1)
	_intent_target_label.add_theme_constant_override("shadow_offset_y", 1)
	_column.add_child(_intent_target_label)


## `has_intent`/`face_type`/`value` mirror CombatView._format_intent()'s own reads of
## Unit.intent (public information by design, rule spec §2 "minh bạch triệt để") — this file
## never reads Unit/CombatEngine itself, only what CombatView hands it.
##
## `blank` gets its own branch (see _INTENT_ICON's comment for the bug this fixes): a blank
## face never has a real rolled value or a real target (combat_engine.gd's `_pick_enemy_intent`
## leaves target_uid at -1 for it — CombatView.gd then hands this file the placeholder string
## "?" as `target_name`), so showing the value number or the "-> ?" target line for it would
## still read as "hidden", exactly the bug this branch exists to remove. Showing neither is the
## honest "does nothing" reading the task asked for.
func set_intent(has_intent: bool, face_type: String, value: int, target_name: String) -> void:
	_intent_panel.visible = has_intent
	_intent_target_label.visible = has_intent
	if not has_intent:
		return
	var col: Color = _INTENT_TYPE_COLOR.get(face_type, DangoTheme.PRIMARY)
	_intent_style.border_color = col
	if face_type == "blank":
		_intent_icon.texture = _INTENT_ICON["blank"]
		_intent_number.text = ""
		_intent_target_label.visible = false
		return
	var icon := _intent_icon_for(face_type)
	_intent_icon.texture = icon
	if icon == null:
		# Unrecognized face type with no web-icon mapping — the one case where a literal "?" is
		# honest, per the task's "only show ? if the intent genuinely is hidden" requirement. No
		# such type is ever rolled by any shipped enemy today (see class comment: only
		# dmg/shield are live, blank is handled above) — this is a safety net for a
		# future/unmapped type, not a path any current playthrough reaches.
		_intent_number.text = "?"
	else:
		_intent_number.text = str(value) if value > 0 else ""
	_intent_target_label.text = "-> %s" % target_name


func _intent_icon_for(face_type: String) -> Texture2D:
	return _INTENT_ICON.get(face_type, null)


## Status-effect display moved to UnitPortrait (see class comment) — kept as a callable no-op
## because CombatView.gd calls `hud.set_status(u.status)` unconditionally every frame and this
## file may not edit that call site to remove the call.
func set_status(_status: Dictionary) -> void:
	pass


## CombatView reads this every frame (after set_intent()/set_status() for this rebuild) to
## anchor this Control's bottom edge at the world head point — see class comment.
func total_height() -> float:
	return _column.get_combined_minimum_size().y
