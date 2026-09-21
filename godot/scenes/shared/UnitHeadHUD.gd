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

## FIX-PASS-01 §2.1 C3/C4 (2026-09-20): was 120 — the spec pins this to the SAME 176px width as
## the (now-enlarged, see UnitPortrait.ENEMY_WIDTH) enemy nameplate it anchors above, so the badge
## reads as belonging to that plate instead of floating at its own arbitrary width.
const WIDTH := 176.0

## C2 — the badge's OUTER height. combat-v2.html gives the badge `height:36px` with no
## `box-sizing`, so its 36 is the CONTENT box and the `border:3px solid #000` sits outside it:
## 3 + 36 + 3 = 42 rendered pixels. Godot draws a StyleBoxFlat's border INSIDE the Control's
## rect, so the panel has to be 42 for its interior to be the mockup's 36 — a panel set to 36
## renders a 30px interior and a badge three pixels short at each edge.
##
## It is a const rather than a measured height because CombatView reserves this slot whether or
## not a badge is in it (see Q3 / `set_intent(false, ...)`): an enemy with no telegraphed action
## hides its badge, and a measured height would then collapse the slot and drag that one
## enemy's nameplate 42px up out of the row. The status strip already works this way
## (UnitPortrait.STATUS_STRIP_H, "FIXED 28px whether or not it holds anything").
const HEIGHT := 42.0
## combat-v2.html pads the live badge `0 9px 0 5px` — 5 on the tile side, 9 after the text.
## Empty States Spec §1 pads the word-only badge `0 14px` on both sides.
const _PAD_TILE := 5.0
const _PAD_LIVE_RIGHT := 9.0
const _PAD_TEXT := 14.0
const _ICON_SIZE := Vector2(16, 16)

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

## The badge FILL, per combat-v2.html: `intentBg` is the face type's own colour and the whole
## plate is filled with it (the mockup only ever draws dmg/shield, at #F54540 and #31C6FF — which
## are exactly `die_type_color()`'s DANGER and SHIELD_BLUE). This used to be a separate,
## smaller palette that reused PRIMARY for both buff and debuff and a hand-picked purple for
## poison, and it painted the NUMBER rather than the plate. Resolved against
## `DangoTheme.die_type_color()` instead, so a die face and the intent that threatens you with it
## are the same colour everywhere on this screen — the reconciliation DangoTheme's own
## "FLAGGED DEVIATION" note asked a future pass to make.

## The mockup's `rgba(0,0,0,.26)` glyph tile inside the badge — a darkening of the badge's own
## fill, not a colour of its own, so it is expressed as black-at-alpha rather than as a token.
const _TILE_TINT := Color(0, 0, 0, 0.26)

## The mockup's `2px/18px` divider between the value and the target: `rgba(0,0,0,.28)`. Same
## reasoning as _TILE_TINT — a darkening of the badge's own fill, expressed as black-at-alpha
## rather than as a token. It was being tinted toward the resolved ink colour, which is not what
## the mockup draws and which made the rule vanish on the darker intent fills.
const _DIVIDER_TINT := Color(0, 0, 0, 0.28)
const _DIVIDER_SIZE := Vector2(2, 18)

var uid: int = -1
var _column: VBoxContainer
var _intent_panel: PanelContainer
var _icon_tile: PanelContainer
var _intent_icon: TextureRect
var _intent_number: Label
var _intent_divider: ColorRect
var _intent_target_label: Label
## Empty States Spec §1 — the single-word badge ("NO MOVE" / "HIDDEN") and the "?" that sits in
## the icon tile for the hidden state.
var _intent_word: Label
var _intent_tile_glyph: Label
var _intent_style: StyleBoxFlat


func _init() -> void:
	custom_minimum_size = Vector2(WIDTH, 0)
	size = Vector2(WIDTH, 0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_column = VBoxContainer.new()
	_column.custom_minimum_size = Vector2(WIDTH, 0)
	_column.add_theme_constant_override("separation", 2)
	_column.alignment = BoxContainer.ALIGNMENT_END
	_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_column)

	# combat-v2.html's intent badge: height 36, padding `0 9px 0 5px`, radius 10, a solid fill in
	# the intent's own type colour on a 3px black outline, shelf `0 4px 0`, gap 7. Inside it, in
	# order: a 22px dark-tinted tile (radius 7) holding the 16px glyph, the value at Baloo 20/800
	# in ink, a 2px divider, and the target at Baloo 11/800.
	#
	# The previous version was a PANEL_DEEP plate with a coloured NUMBER on it. That is the
	# opposite of what the mockup draws, and it is why the enemy intent read as chrome rather
	# than as a threat.
	var centre := CenterContainer.new()
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_column.add_child(centre)

	_intent_panel = PanelContainer.new()
	_intent_panel.visible = false
	_intent_panel.custom_minimum_size = Vector2(0, HEIGHT)   # C2 — 36 interior + 3px border ×2
	_intent_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_intent_panel.mouse_entered.connect(func(): intent_hover_changed.emit(uid, true))
	_intent_panel.mouse_exited.connect(func(): intent_hover_changed.emit(uid, false))
	_intent_style = DangoTheme.solid_chip_style(DangoTheme.DANGER, 10, 3, Vector2(-1, -1))
	_intent_style.content_margin_left = _PAD_TILE
	_intent_style.content_margin_right = _PAD_LIVE_RIGHT
	_intent_style.content_margin_top = 0.0
	_intent_style.content_margin_bottom = 0.0
	_intent_style.shadow_color = DangoTheme.SHELF
	_intent_style.shadow_size = 0
	_intent_style.shadow_offset = Vector2(0, 4)
	_intent_panel.add_theme_stylebox_override("panel", _intent_style)
	centre.add_child(_intent_panel)

	var intent_row := HBoxContainer.new()
	intent_row.add_theme_constant_override("separation", 7)
	intent_row.alignment = BoxContainer.ALIGNMENT_CENTER
	intent_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_intent_panel.add_child(intent_row)

	_icon_tile = PanelContainer.new()
	_icon_tile.custom_minimum_size = Vector2(22, 22)
	_icon_tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_icon_tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon_tile.add_theme_stylebox_override("panel",
		DangoTheme.solid_chip_style(_TILE_TINT, 7, 0, Vector2.ZERO))
	var icon_centre := CenterContainer.new()
	icon_centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon_tile.add_child(icon_centre)
	_intent_icon = TextureRect.new()
	_intent_icon.custom_minimum_size = _ICON_SIZE
	_intent_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE   # the web icon PNGs/SVGs do not
		# all ship at this 16x16 slot's size, and EXPAND_KEEP_SIZE (the TextureRect default)
		# would let a texture's own native size win over custom_minimum_size in the container's
		# minimum-size math.
	_intent_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_intent_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_centre.add_child(_intent_icon)
	intent_row.add_child(_icon_tile)

	_intent_number = DangoTheme.display_label("", 20, DangoTheme.INK, 800)
	_intent_number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_intent_number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intent_row.add_child(_intent_number)

	_intent_divider = ColorRect.new()
	_intent_divider.custom_minimum_size = _DIVIDER_SIZE
	_intent_divider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_intent_divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_intent_divider.color = _DIVIDER_TINT
	intent_row.add_child(_intent_divider)

	_intent_target_label = DangoTheme.display_label("", 11, DangoTheme.INK, 800, 0.04)
	_intent_target_label.visible = false
	_intent_target_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_intent_target_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intent_row.add_child(_intent_target_label)

	# Empty States Spec §1. The word that IS the badge when there is no move: "NO MOVE", or
	# "HIDDEN" beside a "?" tile. Baloo 2 800 / 13 / .14em / line 1, ink MUTED_TEXT (#8C95A4,
	# 4.9:1 on the inert fill).
	_intent_word = DangoTheme.display_label("", 13, DangoTheme.MUTED_TEXT, 800, 0.14)
	_intent_word.name = "IntentWord"
	_intent_word.visible = false
	_intent_word.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_intent_word.add_theme_constant_override("line_spacing", 0)
	_intent_word.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intent_row.add_child(_intent_word)

	# The "?" for the hidden state lives IN the icon tile, not in the value slot: the spec keeps
	# the tile there ("giữ ô icon vì có ẩn một giá trị") and reserves "?" for this state alone.
	_intent_tile_glyph = DangoTheme.display_label("", 15, DangoTheme.MUTED_TEXT, 800)
	_intent_tile_glyph.visible = false
	_intent_tile_glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_centre.add_child(_intent_tile_glyph)


## THREE STATES, THREE SHAPES — Empty States Spec §1 (Claude Design, 2026-09-21).
##
## The old behaviour was `visible = has_intent`: an enemy with nothing telegraphed simply had no
## badge. The spec rejects that on three counts, and they are all measurable rather than
## aesthetic: (1) the enemy column is a 186x370 vertical stack with gap 8, so removing a 42px
## badge yanks the status chips and HP bar up 44px mid-turn; (2) a hole cannot tell "this enemy
## does nothing" apart from "its intent has not been rolled"; (3) the badge is the hover target
## for the intent tooltip, so hiding it takes away the place the player asks "why is it
## standing still".
##
## So the badge never disappears for an enemy, and the three states are three different shapes:
##
##   HAS A MOVE   tile + value + divider + "-> TARGET", fill = the die type's own colour.
##   NO MOVE      ONE element, the word. No tile, no digit, no divider, no target line, and a
##                fill outside the die-type palette. Six separate signals, because the one thing
##                this must never be misread as is "0 damage" — see `_apply_inert_badge()`.
##   HIDDEN       "?" in the tile + the word HIDDEN. The tile stays because a value really is
##                being withheld. "?" appears HERE AND NOWHERE ELSE.
##
## `hide_intent()` is the separate, deliberate path for a PARTY unit, which has no intent slot
## at all — that is the only case where this Control is invisible.
func set_intent(has_intent: bool, face_type: String, value: int, target_name: String) -> void:
	visible = true
	_intent_panel.visible = true
	if not has_intent:
		# The enemy exists but nothing is rolled yet: unknown, not inert.
		_apply_hidden_badge()
		return
	if face_type == "blank":
		# A blank face is a real, legal "this face does nothing" (combat_engine `_do_face()`),
		# never a hidden one — rule spec §2 "minh bạch triệt để". It is the NO MOVE case.
		_apply_inert_badge()
		return
	var icon := _intent_icon_for(face_type)
	if icon == null:
		# An unmapped face type: the build genuinely does not know what is coming. No shipped
		# enemy reaches this today; it is the safety net, and "unknown" is the honest reading.
		_apply_hidden_badge()
		return

	_intent_style.bg_color = DangoTheme.die_type_color(face_type)
	_intent_style.content_margin_left = _PAD_TILE
	_intent_style.content_margin_right = _PAD_LIVE_RIGHT
	_icon_tile.visible = true
	_intent_tile_glyph.visible = false
	_intent_icon.visible = true
	_intent_number.visible = true
	_intent_divider.visible = true
	_intent_target_label.visible = true
	_intent_word.visible = false

	# C2 — combat-v2.html inks the two texts DIFFERENTLY: the value is #1A1206 (`INK`, which is
	# what `ink_on()` already returns for every intent fill that ships today — all seven face
	# colours are bright) and the target is the darker #2A0806 (`INK_ON_DANGER`), which is what
	# demotes the target line under the number instead of two texts competing at one weight.
	# The mockup hardcodes both, but hardcoding the target would reintroduce the
	# near-black-on-dark failure L5 exists to stop if a future intent fill is ever dark — so the
	# darker ink is only taken when `ink_on()` itself resolved to INK, i.e. the fill is bright.
	var ink := DangoTheme.ink_on(_intent_style.bg_color)
	_intent_number.add_theme_color_override("font_color", ink)
	_intent_target_label.add_theme_color_override("font_color",
		DangoTheme.INK_ON_DANGER if ink == DangoTheme.INK else ink)
	_intent_icon.modulate = Color(1, 1, 1, 1)
	_intent_divider.color = _DIVIDER_TINT
	_intent_icon.texture = icon
	_intent_number.text = str(value) if value > 0 else ""
	# C4 / CB-14: a real arrow glyph, not "->", and the name UPPERCASED. combat-v2.html writes
	# the target line as `→ BUBA`; at Baloo 11 with .04em tracking, mixed case reads as body copy
	# next to the 20px value and loses the "this is a label" cue the whole badge depends on.
	_intent_target_label.text = "→ %s" % target_name.to_upper()
	# The badge is already the documented hover target ("the badge is the hover target for the
	# intent tooltip" — see set_intent()'s own header) and until now the hover showed nothing.
	# Spells the telegraph out in words, because the badge itself is three glyphs and a number.
	var what := DangoTheme.face_type_label(face_type)
	var head := "%s → %s" % [what, target_name.to_upper()]
	if value > 0:
		head = "%s %d → %s" % [what, value, target_name.to_upper()]
	_intent_panel.tooltip_text = head + ("\nThis is exactly what this enemy does when the turn "
		+ "ends — the telegraph is never a guess and never random.")


## A PARTY unit has no intent slot. The only path that hides this Control.
func hide_intent() -> void:
	visible = false
	_intent_panel.visible = false


## NO MOVE. The spec lists six layers that stop this being read as "0 damage", and each one is a
## line here, so none of them can be quietly dropped later:
##   1. no digit glyph exists in the badge at all — there is no 0 to read;
##   2. the 22px tinted tile is gone — that tile IS the "a value lives here" signal;
##   3. no divider and no "-> TARGET" — no target means no attack;
##   4. the fill is `INERT_FILL`, outside the die-type palette, so colour alone says "not a move";
##   5. muted ink on a dark fill inverts the live badge's weight (near-black ink on a bright fill);
##   6. the badge hugs to ~104px against a live badge's ~148px, so the whole enemy row recedes.
func _apply_inert_badge() -> void:
	_intent_style.bg_color = DangoTheme.INERT_FILL
	_intent_style.content_margin_left = _PAD_TEXT
	_intent_style.content_margin_right = _PAD_TEXT
	_icon_tile.visible = false
	_intent_number.visible = false
	_intent_divider.visible = false
	_intent_target_label.visible = false
	_intent_word.visible = true
	_intent_word.text = "NO MOVE"
	_intent_panel.tooltip_text = ("NO MOVE\nThis enemy rolled a blank face. It really does "
		+ "nothing this turn — this is not a 0-damage attack.")


## HIDDEN. Same inert fill and ink — it is not an attack either, and the spec gives it no fill of
## its own — but the tile stays, because a value really is being withheld, and it carries the
## one "?" this whole screen is allowed to draw.
func _apply_hidden_badge() -> void:
	_intent_style.bg_color = DangoTheme.INERT_FILL
	_intent_style.content_margin_left = _PAD_TILE
	_intent_style.content_margin_right = _PAD_TEXT
	_icon_tile.visible = true
	_intent_icon.visible = false
	_intent_icon.texture = null
	_intent_tile_glyph.visible = true
	_intent_tile_glyph.text = "?"
	_intent_number.visible = false
	_intent_divider.visible = false
	_intent_target_label.visible = false
	_intent_word.visible = true
	_intent_word.text = "HIDDEN"
	_intent_panel.tooltip_text = ("HIDDEN\nThis enemy has not rolled its action yet. It will "
		+ "show here as soon as it does.")


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
