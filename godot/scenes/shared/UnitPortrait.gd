extends Control
class_name UnitPortrait
## Feet-anchored unit HUD column — CB-07 … CB-13 (FIX-PASS-03 §4). Positioned every frame by
## CombatView using CombatStage3D.get_unit_screen_pos(uid, FEET_HEIGHT).
##
## Structure, top to bottom, per CB-07 (enemy) and CB-08 (party):
##   StatusStrip  — CB-13. FIXED 28px tall whether or not it holds anything, so the nameplate
##                  below it never moves as statuses come and go. Shield is the FIRST chip here.
##   Card         — CB-09/CB-10. The nameplate proper.
##     TopRow     — name (left, ellipsised) · incoming chip (party only) · HP cur/max (right)
##     HPBar      — CB-10 row 2, plus CB-11's at-risk slice for the party
##     ShieldBar  — CB-10 row 3, its OWN bar, fill INFO, width = shield / max_hp
## The enemy's intent badge (CB-14) is a separate node above this one — see UnitHeadHUD.gd.
##
## ── WHAT CHANGED, AND WHY IT MATTERS (FIX-PASS-03 G-04 / CB-09) ────────────────────────────
##
## This file is the spec's named example of a failure it has seen twice. The previous version
## carried this comment, verbatim:
##
##     "Party nameplates are unchanged — C1 is enemy-only, and the party row already reads
##      correctly at its current size."
##
## That is how the build ended up with enemy plates at 176 wide and party plates at a
## text-measured width floored at 132 — two nameplate systems in one screen. CB-09 states its
## scope explicitly ("Applies to EVERY nameplate in combat — all five party plates and every
## enemy plate. One width, one height per side, regardless of how long the name is. No
## text-measured widths.") so both sides are built from the same constants here:
##
##     176 wide, both sides. Enemy 64 tall, party 68 — the extra 4 is the class edge.
##
## The per-plate text measuring is GONE. It existed to stop long names clipping, and the
## replacement for that is `text_overrun_behavior = TRIM_ELLIPSIS` on the name label (CB-10
## says "ellipsised"), which solves the same problem without letting a name decide a plate's
## geometry. "Venomaw" now reads "Venomaw"; a name too long for 176px reads "Venoma…", which is
## a truncation the player can see, not the corrupt-looking mid-glyph cut this used to produce.
##
## The SHIELD BADGE IS DELETED. It was a pill overlapping the plate's top-right corner, and
## CB-10 forbids it twice over — shield "is never a segment inside the HP track and never a
## badge overlapping the HP number". Shield now reads in two sanctioned places: its own bar
## (CB-10 row 3) and the first chip of the status strip (CB-13).
##
## Icon source: assets/icons/web/ (the live web build's own icon set) — the user's explicit
## requirement is that both builds show the same icons, unchanged.

signal clicked(uid: int)

## Right-click anywhere on this nameplate — always the inspector, never a game action. Mirrors
## CombatStage3D.unit_inspect_requested (right-clicking the model itself); CombatView connects
## both to the same _open_unit_inspect(). Left-click stays context-dependent (a legal target is
## a target), which is why "what does this do?" needs a door of its own.
signal inspect_requested(uid: int)

## CB-09 — ONE width for every nameplate in combat, both sides. Not a floor, not a minimum that
## a long name may exceed: the width. See the class comment.
const WIDTH := 176.0
const ENEMY_HEIGHT := 64.0
const PARTY_HEIGHT := 68.0          # +4 for the class edge
const CLASS_EDGE_W := 6             # CB-09: the party plate's class-coloured top border —
	# L1's first named exception to "one outline, pure black"
const STATUS_STRIP_H := 28.0        # CB-13 — fixed, always

## Back-compat alias: CombatView._layout_unit_visuals() and tests refer to ENEMY_WIDTH. There is
## only one width now (CB-09), so it points at the same constant rather than being a second
## number that can drift from it.
const ENEMY_WIDTH := WIDTH

## status key -> web icon (assets/icons/web/, src/art7.js parity). Same 9 keys Unit.status can
## ever hold (unit.gd: "poison/burn/regen/blind/weaken/vulnerable/thorns/stun/undying -> int
## stack count" — freeze is deliberately NOT one of them, it's the separate `frozen`/
## `frozen_next` bool pair). "vulnerable" is the one key whose web icon file is named
## differently ("vuln.png"), confirmed against tests/t_assets.gd's own list.
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
const _ICON_SHIELD := preload("res://assets/icons/web/shield.png")
const _ICON_DMG := preload("res://assets/icons/web/dmg.png")

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
@onready var _inner: PanelContainer = %Inner
@onready var _column: VBoxContainer = %Column
@onready var _status_strip: CenterContainer = %StatusStrip
@onready var _status_row: HBoxContainer = %StatusRow
@onready var _name_label: Label = %NameLabel
@onready var _hp_label: Label = %HPLabel
@onready var _hp_bar: HPBar = %HPBar
@onready var _shield_bar: HPBar = %ShieldBar
@onready var _incoming_chip: PanelContainer = %IncomingChip
@onready var _incoming_icon: TextureRect = %IncomingIcon
@onready var _incoming_label: Label = %IncomingLabel
@onready var _click_catcher: Button = %ClickCatcher

var uid: int = -1
var _dying: bool = false   # true once play_death_fade() has been triggered — guards
	# update_stats() from clobbering the fade Tween's modulate
var _base_style: StyleBoxFlat
var _selected_style: StyleBoxFlat
var _targetable_style: StyleBoxFlat
var _is_enemy: bool = false
var _incoming: int = 0     # CB-11/CB-12 — committed incoming damage, party only


func _ready() -> void:
	custom_minimum_size.x = WIDTH
	_column.add_theme_constant_override("separation", 8 if _is_enemy else 5)   # CB-07 / CB-08
	# C3 — combat-v2.html fills the shield track with #31C6FF, which is `SHIELD_BLUE`.
	# `INFO` is #00B8FF: close enough to look deliberate and wrong enough to be a different
	# blue from the shield chip beside it on the die card and in the status strip.
	_shield_bar.use_fixed_fill(DangoTheme.SHIELD_BLUE)                        # CB-10 row 3
	# CB-12's 12px dmg glyph. EXPAND_IGNORE_SIZE is NOT optional: the web icons do not ship at
	# the slot sizes this UI asks for, and a TextureRect left on the default EXPAND_KEEP_SIZE
	# reports the TEXTURE's natural size as its minimum. The QA capture of this pass showed
	# exactly that — dmg.png at full size blew the incoming chip up into a block that covered
	# two whole party nameplates. Same gotcha the status-chip icons already guard against.
	_incoming_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_incoming_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_incoming_icon.texture = _ICON_DMG
	_incoming_chip.mouse_filter = Control.MOUSE_FILTER_STOP   # so it can carry a tooltip; the
		# handler below keeps it a click target for the plate all the same
	_incoming_chip.gui_input.connect(_on_hud_chip_gui_input)
	_click_catcher.pressed.connect(func(): clicked.emit(uid))
	_click_catcher.gui_input.connect(_on_click_catcher_gui_input)
	# THE CATCHER GOES FIRST, NOT LAST. Godot picks GUI input by walking children in REVERSE
	# order, so a full-rect Button added last is in front of every sibling — including the
	# status chips, which is why a chip could never be hovered and therefore could never show
	# a tooltip (`Viewport._gui_get_tooltip()` only ever asks the control it actually picked).
	# Moved behind the column instead: the chips (MOUSE_FILTER_STOP, see _status_chip()) take
	# the hover where they are, and every other pixel of the plate still falls through to the
	# catcher because the whole column above it is MOUSE_FILTER_IGNORE. `flat = true` means the
	# catcher draws nothing in any state, so its depth has no visual consequence.
	move_child(_click_catcher, 0)


## CB-09 — the one plate style, for both sides.
##
## The party plate's 6px class-coloured top edge is L1's first named exception to "one outline,
## pure black", and a StyleBoxFlat carries exactly ONE border colour — so it cannot be a border.
## It is built as TWO NESTED PANELS instead: the outer `Card` is filled with the class colour and
## carries the black outline, radius and shelf; the inner panel is `PANEL_DEEP` and is inset from
## the top by 6px, leaving exactly that much of the outer fill showing as the edge.
##
## The first attempt here made the edge a second CHILD of `Card` with `PRESET_TOP_WIDE` anchors.
## That does not work and the QA capture showed why: `PanelContainer` is a Container, so it
## overrides its children's anchors and offsets and stretches each one to its full rect — the
## "6px edge" rendered as a full-card block of class colour over the whole nameplate. A Container
## child cannot position itself; it has to be given a slot.
func _apply_card_styles(cls: String) -> StyleBoxFlat:
	# The outer's content margins ARE the border. `PanelContainer` lays its child out inside the
	# stylebox's content margins and nowhere else, so with those at 0 the inner panel covered the
	# 3px black outline completely — which is why the 20 Sep capture showed nameplates with no
	# outline on any side while the die cards beside them had one. Each margin equals the border
	# width on that side.
	var outer := DangoTheme.surface_style(
		DangoTheme.Surface.PANEL_DEEP, 12, 3, 4.0, Vector2(3, 3))   # radius 12, 3px black, shelf 4
	var inner := StyleBoxFlat.new()
	inner.bg_color = DangoTheme.surface_color(DangoTheme.Surface.PANEL_DEEP)
	inner.set_corner_radius_all(9)          # plate radius 12 minus the 3px border
	inner.content_margin_left = 10.0        # CB-09 padding 5/10, applied on the inner panel so
	inner.content_margin_right = 10.0       # the class edge above sits flush against the border
	inner.content_margin_top = 5.0
	# Top-aligned, no bottom padding. The mockup's own rows (20 + 4 + 12 + 4 + 12 = 52) already
	# exceed the 49px its 5px bottom padding would leave, so the plate reads with ~2px under the
	# shield bar and the padding never gets to apply. Reserving 5 here instead pushes the shield
	# bar out of a fixed-height plate.
	inner.content_margin_bottom = 0.0
	if not _is_enemy:
		outer.bg_color = DangoTheme.class_color(cls)   # shows through as the top edge
		# C4 / C8 — the edge measured 3px in the build, half of what combat-v2.html draws, and
		# this is why. `surface_style()` puts a 3px black border on all four sides; a
		# `content_margin_top` of 6 then inset the inner panel 6px from the CARD's top edge, so
		# the black border ate the first 3 of those 6 and only 3px of class colour was ever
		# visible. The mockup's party plate has NO black top border at all —
		# `border:3px #000` followed by `border-top:6px solid {{ p.cls }}` REPLACES the top
		# border with the class colour — so the top border goes to 0 and the full 6px of the
		# outer fill shows. Left/right/bottom stay pure black at 3 (L1), and 68 = 6 + 59 + 3
		# keeps PARTY_HEIGHT exactly where CLAUDE.md pins it.
		outer.border_width_top = 0
		outer.content_margin_top = float(CLASS_EDGE_W)   # the class edge replaces the top border
		inner.corner_radius_top_left = 0
		inner.corner_radius_top_right = 0
	_inner.add_theme_stylebox_override("panel", inner)
	return outer


## Called once per unit when a combat starts (CombatView._spawn_portrait).
func setup(p_uid: int, display_name: String, cls: String, is_enemy: bool) -> void:
	uid = p_uid
	_is_enemy = is_enemy
	_name_label.text = display_name

	_column.add_theme_constant_override("separation", 8 if is_enemy else 5)

	# CB-10 row 1 type. Both sides, one scale — the previous build gave the enemy 17/15 and left
	# the party on the scene's own 15/17, which is the same enemy-only split CB-09 rejects.
	# combat-v2.html draws the name at Baloo 17/700 with `letter-spacing:.02em` on BOTH sides —
	# `apply_tracking()` sets the face, the size and the tracking in one call.
	DangoTheme.apply_tracking(_name_label, 0.02, 17, 700)   # Baloo 700
	# combat-v2.html inks the name #FFF8EA on both sides — CREAM_RAISED, not the generic TEXT
	# grey-white the scene file shipped with.
	_name_label.add_theme_color_override("font_color", DangoTheme.CREAM_RAISED)
	_hp_label.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)          # Baloo 800
	_hp_label.add_theme_font_size_override("font_size", 18)
	_incoming_label.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	_incoming_label.add_theme_font_size_override("font_size", 14)
	_incoming_label.add_theme_color_override("font_color", DangoTheme.CREAM_RAISED)

	# CB-12 — DANGER fill, radius 6, NO border.
	_incoming_chip.add_theme_stylebox_override("panel",
		DangoTheme.solid_chip_style(DangoTheme.DANGER, 6, 0, Vector2(5, 0)))

	_base_style = _apply_card_styles(cls)
	_selected_style = _base_style.duplicate()
	_selected_style.border_color = DangoTheme.PRIMARY
	_targetable_style = _base_style.duplicate()
	_targetable_style.border_color = DangoTheme.INFO
	_card.add_theme_stylebox_override("panel", _base_style)

	# CB-09: fixed size, both sides. No text measuring — see the class comment.
	_card.custom_minimum_size = Vector2(WIDTH, ENEMY_HEIGHT if is_enemy else PARTY_HEIGHT)
	custom_minimum_size = Vector2(WIDTH, STATUS_STRIP_H
		+ _column.get_theme_constant("separation")
		+ (ENEMY_HEIGHT if is_enemy else PARTY_HEIGHT))
	size = custom_minimum_size


## CB-11 / CB-12 — committed incoming damage for this unit. Set by CombatView every rebuild;
## party only, and 0 for everything else.
func set_incoming(amount: int) -> void:
	_incoming = maxi(amount, 0)


## Called from CombatView._rebuild_all() — the single "read model, redraw" entry point.
func update_stats(hp: int, max_hp: int, shield: int, status: Dictionary) -> void:
	var safe_max := maxi(max_hp, 1)
	_hp_bar.set_stats(hp, safe_max)
	_hp_label.text = "%d/%d" % [maxi(hp, 0), safe_max]
	_hp_label.add_theme_color_override("font_color",
		DangoTheme.hp_color(float(maxi(hp, 0)) / float(safe_max)))    # CB-10: hp_color(pct)

	# CB-10 row 3 — shield as its own bar, width = shield / max_hp clamped to 100%.
	#
	# The bar is ALWAYS drawn, empty trough and all. combat-v2.html renders the shield row
	# unconditionally (its `shieldPct` is simply "0%" on a unit with no shield), and hiding it
	# was making the plate's two bars sit at two different heights depending on whether a unit
	# happened to be shielded — inside a plate whose own height is fixed at 64/68.
	_shield_bar.set_stats(mini(shield, safe_max), safe_max)

	# CB-11 — the at-risk slice: min(hp, max(0, incoming - shield)). Party only; enemies never
	# get an incoming value, so this is 0 for them and draws nothing.
	_hp_bar.set_at_risk(mini(maxi(hp, 0), maxi(0, _incoming - shield)))

	# CB-12 — hidden entirely when incoming is 0. Hidden, not dimmed.
	_incoming_chip.visible = (not _is_enemy) and _incoming > 0
	if _incoming_chip.visible:
		_incoming_label.text = str(_incoming)
		_incoming_chip.tooltip_text = ("Incoming %d\nDamage the enemies have already declared "
			+ "against this Axie this turn. Shield is subtracted first.") % _incoming

	_rebuild_status_chips(status, shield)
	if hp > 0:
		_dying = false
		visible = true
		modulate = Color(1, 1, 1, 1)
	elif not _dying:
		modulate = Color(1, 1, 1, 0)
		visible = false


## CB-13 — the status strip. A centred row in a strip of FIXED 28px height, so the nameplate
## below never moves as statuses come and go (the old row hid itself at 0 height, which made
## every plate jump the moment a poison stack landed). Shield is the FIRST chip, on SHIELD_BLUE.
func _rebuild_status_chips(status: Dictionary, shield: int) -> void:
	for c in _status_row.get_children():
		c.queue_free()
	if shield > 0:
		_status_row.add_child(
			_status_chip(_ICON_SHIELD, shield, DangoTheme.SHIELD_BLUE, "shield"))
	for key in _STATUS_ICON:
		var v := int(status.get(key, 0))
		if v > 0:
			_status_row.add_child(
				_status_chip(_STATUS_ICON[key], v, DangoTheme.status_color(key), key))
	# The STRIP stays visible and 28 tall regardless; only its contents come and go.


## One status chip — height 28, radius 9, 3px black, solid status colour, 16px icon + count in
## Baloo 16 inked by ink_on(). Never a wash of the status colour (L4), never white-on-colour (L5).
##
## `key` is the ENGINE's own status key ("poison", "burn", …, plus "shield"), and it is what
## turns the chip from a coloured glyph into something a player can actually read: it looks the
## rule up in CodexContent.status_tip() and hangs it off the chip as a tooltip. Before this the
## strip was nine unlabelled icons and the only way to learn what one meant was the Codex
## (bug report 2026-09-21, "chỉ vào Icon Effect không hiện mô tả").
func _status_chip(icon_tex: Texture2D, count: int, fill: Color, key: String) -> PanelContainer:
	var chip := PanelContainer.new()
	# STOP, not IGNORE — a tooltip needs the chip to be the control the viewport picks. The
	# plate underneath keeps its click because _on_hud_chip_gui_input() forwards it by hand;
	# MOUSE_FILTER_PASS would NOT do that job, since it propagates to ANCESTORS (all IGNORE
	# here) and never to the ClickCatcher sibling.
	chip.mouse_filter = Control.MOUSE_FILTER_STOP
	chip.tooltip_text = _effect_tooltip(key, count)
	chip.gui_input.connect(_on_hud_chip_gui_input)
	chip.custom_minimum_size = Vector2(0, STATUS_STRIP_H)
	# combat-v2.html: padding `0 8px 0 4px` — the glyph sits tighter to the left edge than the
	# count does to the right, which is what keeps a 1-digit and a 2-digit chip reading alike.
	var chip_style := DangoTheme.solid_chip_style(fill, 9, 3, Vector2(-1, -1))
	chip_style.content_margin_left = 4.0
	chip_style.content_margin_right = 8.0
	chip_style.content_margin_top = 0.0
	chip_style.content_margin_bottom = 0.0
	chip.add_theme_stylebox_override("panel", chip_style)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 3)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	chip.add_child(row)
	var icon := TextureRect.new()
	icon.texture = icon_tex
	icon.custom_minimum_size = Vector2(16, 16)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var lbl := DangoTheme.display_label(str(count), 16, DangoTheme.ink_on(fill), 800)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(lbl)
	return chip


## "Poison 3" + the rule, off the ONE rule-book (CodexContent.statuses()). A key with no written
## rule still gets a readable line rather than a blank tooltip — a missing entry should look like
## missing text, not like a broken hover.
static func _effect_tooltip(key: String, count: int) -> String:
	var tip: Dictionary = CodexContent.status_tip(key)
	if tip.is_empty():
		return "%s %d" % [key.to_upper(), count]
	# The rule-book prints stacking statuses as "Poison N"; the chip already shows the real N.
	var label := String(tip["name"]).trim_suffix(" N")
	return "%s %d\n%s" % [label, count, String(tip["rule"])]


## A status chip (or the incoming-damage chip) is not a button, but it sits on top of the
## plate's own ClickCatcher, so it hands the click back rather than eating it. Without this,
## clicking a poisoned enemy's poison pill would silently do nothing.
func _on_hud_chip_gui_input(ev: InputEvent) -> void:
	if not (ev is InputEventMouseButton) or not (ev as InputEventMouseButton).pressed:
		return
	match (ev as InputEventMouseButton).button_index:
		MOUSE_BUTTON_LEFT:
			clicked.emit(uid)
			accept_event()
		MOUSE_BUTTON_RIGHT:
			inspect_requested.emit(uid)
			accept_event()


## Button only reports `pressed` for the LEFT button, so right-click gets its own path.
func _on_click_catcher_gui_input(ev: InputEvent) -> void:
	if not (ev is InputEventMouseButton) or not (ev as InputEventMouseButton).pressed:
		return
	if (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_RIGHT:
		inspect_requested.emit(uid)
		accept_event()


func set_selected(v: bool) -> void:
	_card.add_theme_stylebox_override("panel", _selected_style if v else _base_style)


## View-only "plausible click target" affordance — see CombatStage3D.set_targetable(). Never
## called for the currently-selected unit's own card (CombatView guards this).
func set_targetable(v: bool) -> void:
	_card.add_theme_stylebox_override("panel", _targetable_style if v else _base_style)


## Damage-preview passthrough to the HP bar — hover-driven (die-tray / enemy-intent hover).
## Distinct from CB-11's at-risk block, which is committed rather than hypothetical.
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
