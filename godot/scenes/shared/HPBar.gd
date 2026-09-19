extends Control
class_name HPBar
## Single smooth HP bar (coordinator addendum, 2026-09-18 — replaces the earlier segmented/notched
## version from review-uiux-battle-screen.md P0 #2). The per-HP notch grid read as visual clutter
## once zoomed out to the pulled-back camera framing added later in the same pass — user asked for
## "1 thanh máu + số HP" instead. One continuous fill rect sized by hp/max_hp, colored by overall
## percentage via DangoTheme.hp_color() (green -> Kam orange -> danger red thresholds). Shield reads
## as a thin cyan cap along the top edge of the fill (an absorb amount, not its own HP scale) — the
## numeric "+N" shield readout lives on the owning Nameplate/UnitHeadHUD instead, next to this bar,
## not drawn inside it.
##
## Damage-preview (set_preview(), review P0 #2 "vệt đỏ nhạt ngay trên thanh") draws a pale
## danger-red segment at the leading edge of the fill, sized proportionally to the previewed
## damage. Hover-driven only (CombatView wires this to die-tray/enemy-intent hover — see that
## file's _on_die_slot_mouse_entered() and _on_enemy_intent_hover()) — never mutates hp/max_hp
## itself, purely a display guess using the raw rolled face value, not a DamagePipeline replay.

const _EMPTY_COLOR := Color(1, 1, 1, 0.12)
const _SHIELD_CAP_HEIGHT := 3.0
const _SHIELD_CAP_GAP := 2.0
const _PREVIEW_ALPHA := 0.8
const _BORDER_COLOR := Color(0, 0, 0, 0.55)

## Numeric HP readout MOVED OUT of this bar (ui-programmer, nameplate-rebuild pass — bug report:
## "HP numbers ~10px on bright sand", review-uiux-battle-screen.md P0 #5). Drawing the number
## inside this bar capped its size at whatever fit inside a 12-14px-tall strip, which is well
## under the task's 16-18px-bold requirement. The number now lives in UnitPortrait's own
## header row (a real Label, sized independently of this bar's height) — see UnitPortrait.gd's
## `_hp_label`. This file now draws ONLY the bar itself.
var _hp: int = 0
var _max_hp: int = 1
var _shield: int = 0
var _preview_dmg: int = 0


func _init() -> void:
	# Height bumped 12->14 (nameplate-rebuild pass, bug report: "thanh máu chỉ cao 3-4px" —
	# with the HP number no longer stealing vertical space by being drawn inside this bar, the
	# full 14px now actually renders as bar instead of being shared with text).
	custom_minimum_size = Vector2(96, 14)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_stats(hp: int, max_hp: int, shield: int) -> void:
	_hp = hp
	_max_hp = maxi(max_hp, 1)
	_shield = maxi(shield, 0)
	queue_redraw()


func set_preview(dmg: int) -> void:
	_preview_dmg = maxi(dmg, 0)
	queue_redraw()


func clear_preview() -> void:
	set_preview(0)


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var has_shield_cap := _shield > 0
	var bar_h := size.y - (_SHIELD_CAP_HEIGHT + _SHIELD_CAP_GAP if has_shield_cap else 0.0)
	bar_h = maxf(bar_h, 4.0)
	# Empty track first, full width — the fill rect below only covers the filled fraction.
	draw_rect(Rect2(0.0, 0.0, size.x, bar_h), _EMPTY_COLOR, true)
	var pct := float(_hp) / float(_max_hp)
	var fill_color: Color = DangoTheme.hp_color(pct)
	var fill_w := size.x * clampf(pct, 0.0, 1.0)
	if fill_w > 0.0:
		draw_rect(Rect2(0.0, 0.0, fill_w, bar_h), fill_color, true)
	# Preview: a pale-red segment carved out of the leading (right) edge of the current fill,
	# sized proportionally to the previewed damage — "vệt đỏ nhạt ngay trên thanh" from the
	# original review, now drawn as one continuous segment instead of a run of notches.
	if _preview_dmg > 0 and _hp > 0:
		var preview_pct := minf(float(_preview_dmg) / float(_max_hp), pct)
		var preview_w := size.x * preview_pct
		var preview_color := DangoTheme.DANGER
		preview_color.a = _PREVIEW_ALPHA
		draw_rect(Rect2(fill_w - preview_w, 0.0, preview_w, bar_h), preview_color, true)
	draw_rect(Rect2(0.0, 0.0, size.x, bar_h), _BORDER_COLOR, false, 1.5)
	if has_shield_cap:
		draw_rect(Rect2(0.0, bar_h + _SHIELD_CAP_GAP, size.x, _SHIELD_CAP_HEIGHT), DangoTheme.INFO, true)
