extends RefCounted
class_name DangoTheme
## Dango design-system palette (design/art-director review, see
## `/Users/loc.tien.nguyen/Downloads/review-uiux-battle-screen.md`, applied 2026-09-17) —
## single source of truth for every combat-UI color touched by that review, so nothing drifts
## back to the old per-file ad-hoc color literals (StyleBoxFlat colors hand-picked per node in
## Combat.tscn/CombatView.gd before this pass).
##
## FONT DEVIATION (flagged per collaboration protocol): the review specifies "Work Sans". No
## font ships in this repo (no assets/fonts/ dir, confirmed via `find` before writing this) and
## this pass does not fetch new binary/font assets without explicit approval — every Label
## below intentionally leaves font unset so it falls back to Godot's built-in default theme
## font. FONT constant below is the single choke point to wire in a real Work Sans
## DynamicFont later (add the .ttf under assets/fonts/, preload it here, assign it from a
## Theme resource applied to CanvasLayer/Root in Combat.tscn) — no other file should
## special-case fonts once that lands.

const BG := Color(0x13 / 255.0, 0x16 / 255.0, 0x1B / 255.0)
const BG_PANEL := Color(0x13 / 255.0, 0x16 / 255.0, 0x1B / 255.0, 0.82)
const BG_PANEL_SOFT := Color(0x13 / 255.0, 0x16 / 255.0, 0x1B / 255.0, 0.55)
const PRIMARY := Color(0xFF / 255.0, 0x93 / 255.0, 0x45 / 255.0)   # Kam — primary/selection/CTA
const SUCCESS := Color(0x3F / 255.0, 0xCD / 255.0, 0x3C / 255.0)   # high HP / heal
const DANGER := Color(0xF5 / 255.0, 0x45 / 255.0, 0x40 / 255.0)    # low HP / warning / invalid
const INFO := Color(0x00 / 255.0, 0xB8 / 255.0, 0xFF / 255.0)      # shield / mana / info accents
const TEXT := Color(0.93, 0.94, 0.96)
const TEXT_DIM := Color(0.93, 0.94, 0.96, 0.55)
const BORDER := Color(0, 0, 0, 1)

const FONT: Font = null   # see file header — swap in a preloaded Work Sans DynamicFont here

## Die-face TYPE colors (godot-port die-slot-content pass, ui-programmer task 3/4 — "hiện nội
## dung ô skill giống bản web"). Deliberately mirrors src/client.html's FT_COLOR table / CSS
## custom properties byte-for-byte (--dmg:#F54540 --shd:#31C6FF --heal:#3FCD3C --man:#bf6bff
## --poi:#a8d84a --acc:#FF9345 --deb:#ff8fc7) rather than inventing a new scheme, per the task's
## explicit instruction to match that reference. dmg/heal/buff already equal this file's own
## DANGER/SUCCESS/PRIMARY (kept as references below, not re-declared); shield/mana/poison/debuff
## have no prior equivalent in this file and are added here.
##
## FLAGGED DEVIATION: UnitHeadHUD._INTENT_TYPE_COLOR (enemy intent badge, a separate widget) uses
## a smaller/different palette for poison/debuff (reuses PRIMARY / a hand-picked purple) — this
## task's scope is the die tray only (CombatView._update_dice_tray()); the intent badge is left
## exactly as-is on purpose, not overlooked. A future pass could reconcile the two.
const SHIELD_BLUE := Color(0x31 / 255.0, 0xC6 / 255.0, 0xFF / 255.0)
const MANA_PURPLE := Color(0xBF / 255.0, 0x6B / 255.0, 0xFF / 255.0)
const POISON_GREEN := Color(0xA8 / 255.0, 0xD8 / 255.0, 0x4A / 255.0)
const DEBUFF_PINK := Color(0xFF / 255.0, 0x8F / 255.0, 0xC7 / 255.0)


## HP-bar / threat color per hp% — review P0 #2 ("tô xanh -> cam -> đỏ theo ngưỡng").
static func hp_color(pct: float) -> Color:
	if pct > 0.6:
		return SUCCESS
	elif pct > 0.3:
		return PRIMARY
	return DANGER


## Die-face TYPE color lookup — see the const block above for the src/client.html mirroring
## rationale. Unknown/"blank" types fall back to TEXT_DIM (matches --dim there).
static func die_type_color(face_type: String) -> Color:
	match face_type:
		"dmg": return DANGER
		"shield": return SHIELD_BLUE
		"heal": return SUCCESS
		"mana", "summon": return MANA_PURPLE
		"poison": return POISON_GREEN
		"buff": return PRIMARY
		"debuff": return DEBUFF_PINK
		_: return TEXT_DIM


## Small pill stylebox for a die face's keyword chips (review P0 §3.3 lineage — see
## CombatView._update_die_slot_rich()). `accent` is the face's own die_type_color() so a chip's
## border/text reads as "belonging to" its die, matching src/client.html's per-type `.kwtag`
## border-color rule (`.die.t_dmg .kwtag{border-color:color-mix(...var(--dmg)...)}` etc.).
static func kw_chip_style(accent: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.04, 0.06, 0.88)
	sb.border_color = Color(accent.r, accent.g, accent.b, 0.6)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 4.0
	sb.content_margin_right = 4.0
	sb.content_margin_top = 0.0
	sb.content_margin_bottom = 0.0
	return sb


## `border` defaults to BORDER, so every existing call is unchanged. It exists because a panel
## sometimes has to carry a STATE — a vault record that needs re-scanning, say — and a coloured
## border is a signal that survives being scrolled past, which a line of red text inside an
## otherwise identical card does not.
static func panel_style(bg: Color = BG_PANEL, border_w: int = 2, radius: int = 8,
		margin: float = 6.0, border: Color = BORDER) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = margin
	sb.content_margin_right = margin
	sb.content_margin_top = margin * 0.66
	sb.content_margin_bottom = margin * 0.66
	return sb


## Button visual state — see `reference_dangotheme-button-state-spec.md` (art-director,
## decided 2026-09-19) for the full rule this encodes: HOVER changes colour only (never
## geometry); PRESSED changes colour in the OPPOSITE direction from hover AND geometry
## (border_width +1, content_margin_top +1.0 / content_margin_bottom -1.0 — net zero, so
## minimum-size and the outer Control rect never move) AND drops any shadow; DISABLED never
## uses the hover/pressed colour direction and never inherits `warning` — it only flattens via
## reduced alpha/saturation. This NORMAL/HOVER asymmetry vs. PRESSED's colour+shape combo is
## deliberate: it is what makes hover and pressed distinguishable from EACH OTHER, not just
## each one individually distinguishable from normal.
enum ButtonState { NORMAL, HOVER, PRESSED, DISABLED }


## A button for something the player ALREADY HAS. Not a state of `Button` — Godot has no such
## state — but a look applied through `style_button(..., owned = true)`.
##
## WHY IT CANNOT SHARE THE DISABLED LOOK. The shop greys out a card both when it is bought and
## when it costs more than the player can pay, and those two mean opposite things: "bought" is
## permanent and is a SUCCESS; "too expensive" is temporary and may be worth coming back for.
## Sharing one grey makes a shop the player has been buying from read as broken or sold out —
## you have to stop and read the small text in each button to tell them apart. So OWNED keeps
## normal brightness and takes the SUCCESS colour, and only "cannot afford" stays dimmed.
static func owned_button_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(SUCCESS.r, SUCCESS.g, SUCCESS.b, 0.18)
	sb.border_color = SUCCESS
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 12.0
	sb.content_margin_right = 12.0
	sb.content_margin_top = 6.0
	sb.content_margin_bottom = 6.0
	return sb


## A small coloured chip for a rarity tier. Common/Uncommon/Rare/Epic/Legendary = 0..4, matching
## the `rar` field `reward_generator.gd` already puts on every reward, shop item and relic.
##
## Lives here rather than in one screen because the Result screen grew its own version first and
## the reward/shop/event/treasure cards — the screens where rarity actually changes a decision —
## never got one. One definition, so the two cannot drift apart.
const RARITY_NAMES: Array[String] = ["Common", "Uncommon", "Rare", "Epic", "Legendary"]
const RARITY_COLORS: Array[Color] = [
	Color(0.68, 0.71, 0.76),                      # Common — plain grey, deliberately unexciting
	Color(0.25, 0.80, 0.24),                      # Uncommon — green
	Color(0.20, 0.72, 1.00),                      # Rare — blue
	Color(0.75, 0.42, 1.00),                      # Epic — purple
	Color(1.00, 0.58, 0.27),                      # Legendary — orange
]


static func rarity_color(rar: int) -> Color:
	return RARITY_COLORS[clampi(rar, 0, RARITY_COLORS.size() - 1)]


static func rarity_name(rar: int) -> String:
	return RARITY_NAMES[clampi(rar, 0, RARITY_NAMES.size() - 1)]


## The chip itself, ready to add to a card header. Built here so every screen that shows a
## rarity shows the same thing.
static func rarity_chip(rar: int) -> PanelContainer:
	var accent := rarity_color(rar)
	var box := PanelContainer.new()
	box.name = "RarityChip"
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_theme_stylebox_override("panel", kw_chip_style(accent))
	var lbl := Label.new()
	lbl.text = rarity_name(rar).to_upper()
	# 12px floor for anything a player has to read — see the visual backlog's P1 #2.
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", accent)
	box.add_child(lbl)
	return box


## Themes a ScrollContainer's bars to the Dango palette. Godot's default bar is the one element
## on an otherwise dark, themed screen that still looks like stock engine UI.
static func style_scrollbars(node: Control) -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = Color(BG_PANEL_SOFT.r, BG_PANEL_SOFT.g, BG_PANEL_SOFT.b, 0.35)
	track.set_corner_radius_all(4)
	track.content_margin_left = 2.0
	track.content_margin_right = 2.0
	var grabber := StyleBoxFlat.new()
	grabber.bg_color = Color(PRIMARY.r, PRIMARY.g, PRIMARY.b, 0.5)
	grabber.set_corner_radius_all(4)
	var grabber_hi := StyleBoxFlat.new()
	grabber_hi.bg_color = Color(PRIMARY.r, PRIMARY.g, PRIMARY.b, 0.8)
	grabber_hi.set_corner_radius_all(4)
	for axis in ["VScrollBar", "HScrollBar"]:
		node.add_theme_stylebox_override("scroll", track)
		node.add_theme_stylebox_override("grabber", grabber)
		node.add_theme_stylebox_override("grabber_highlight", grabber_hi)
		node.add_theme_stylebox_override("grabber_pressed", grabber_hi)


## Primary CTA button look (End Turn) — filled Kam orange, per review P1 #8.
## `state` selects the hover/pressed/disabled variant (see `ButtonState` above and the state
## spec doc). Default stays NORMAL so every pre-existing call (`primary_button_style()`,
## `primary_button_style(warn)`) keeps compiling and rendering exactly as before.
static func primary_button_style(warning: bool = false, state: ButtonState = ButtonState.NORMAL) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()

	if state == ButtonState.DISABLED:
		# Disabled ignores `warning` entirely and never borrows hover/pressed's colour direction —
		# flattened via alpha only, per spec.
		var flat := PRIMARY.darkened(0.3)
		sb.bg_color = Color(flat.r, flat.g, flat.b, 0.45)
		sb.border_color = Color(0, 0, 0, 0.3)   # not spec'd numerically — inferred from the
			# normal-state border (Color(0,0,0,0.6)) at the same ~0.45-0.5x alpha the bg got;
			# flag for art-director sign-off if a sharper answer is wanted later.
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(12)
		sb.content_margin_left = 18.0
		sb.content_margin_right = 18.0
		sb.content_margin_top = 10.0
		sb.content_margin_bottom = 10.0
		return sb

	match state:
		ButtonState.HOVER:
			sb.bg_color = PRIMARY.lightened(0.15)
		ButtonState.PRESSED:
			sb.bg_color = PRIMARY.darkened(0.12)
		_:
			sb.bg_color = PRIMARY

	sb.border_color = DANGER if warning else Color(0, 0, 0, 0.6)
	var border_w := 3 if warning else 2
	if state == ButtonState.PRESSED:
		border_w += 1   # pressed = colour + geometry (spec)
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 18.0
	sb.content_margin_right = 18.0
	var margin_shift := 1.0 if state == ButtonState.PRESSED else 0.0
	sb.content_margin_top = 10.0 + margin_shift
	sb.content_margin_bottom = 10.0 - margin_shift
	if warning and state != ButtonState.PRESSED:
		# Pressed always drops the shadow (spec). Hover keeps it — hover only changes colour,
		# and removing the warning glow on hover would read as the warning going away.
		sb.shadow_color = Color(DANGER.r, DANGER.g, DANGER.b, 0.6)
		sb.shadow_size = 8
	return sb


## Secondary button look (Reroll) — outline only, review P1 #8 ("secondary nhỏ hơn").
## `state` — see `primary_button_style()`'s doc comment and the state spec doc. HOVER keeps
## `BG_PANEL_SOFT`'s 0.55 alpha but lightens rgb + brightens the border ("translucent glow").
## PRESSED jumps alpha to 0.85 with UNCHANGED rgb (opaque, not lightened) + darkened border +
## border_width 3 ("solid, sunken") — opposite alpha/lightness direction from hover on purpose,
## the key legibility trick for an outline button whose fill is mostly transparent.
static func secondary_button_style(state: ButtonState = ButtonState.NORMAL) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	var border_w := 2

	match state:
		ButtonState.HOVER:
			sb.bg_color = BG_PANEL_SOFT.lightened(0.08)   # alpha unaffected by lightened()
			sb.border_color = PRIMARY.lightened(0.2)
		ButtonState.PRESSED:
			sb.bg_color = Color(BG_PANEL_SOFT.r, BG_PANEL_SOFT.g, BG_PANEL_SOFT.b, 0.85)
			sb.border_color = PRIMARY.darkened(0.15)
			border_w = 3
		ButtonState.DISABLED:
			# Not numerically spec'd (the spec's disabled formula was given for the primary
			# family only) — inferred analog: flatten via alpha only, same direction/intent as
			# primary's disabled, no hover/pressed colour direction, no shadow, no geometry
			# change. Flagging for art-director sign-off same as primary's disabled border.
			sb.bg_color = Color(BG_PANEL_SOFT.r, BG_PANEL_SOFT.g, BG_PANEL_SOFT.b, 0.25)
			sb.border_color = Color(PRIMARY.r, PRIMARY.g, PRIMARY.b, 0.35)
		_:
			sb.bg_color = BG_PANEL_SOFT
			sb.border_color = PRIMARY

	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 12.0
	sb.content_margin_right = 12.0
	var margin_shift := 1.0 if state == ButtonState.PRESSED else 0.0
	sb.content_margin_top = 6.0 + margin_shift
	sb.content_margin_bottom = 6.0 - margin_shift
	return sb


## One-call convenience that applies all four StyleBox states (+ matching font colours across
## all four `font_*color` Button keys, if `font_color` is given) to `btn` in one place. Exists
## because six call sites × up to 4 repeated `add_theme_stylebox_override()` lines is exactly
## the kind of duplication that drifts out of sync — which is how this project ended up with
## no hover/pressed feedback anywhere in the first place (some call sites forced
## normal==hover==pressed to the same StyleBoxFlat, others only ever set "normal").
##
## `font_color`, if non-null, is applied to font_color/font_hover_color/font_pressed_color
## identically, and to font_disabled_color at 0.6x alpha — Button has 4 SEPARATE font colour
## theme keys (font_color/font_hover_color/font_pressed_color/font_disabled_color), not one key
## reused, so a hover/press with no override falls back to Godot's default theme colour rather
## than the one this call site chose.
##
## DELIBERATELY left null by every PRIMARY call site today: no call site sets a primary-button
## font colour except `_end_turn_button` (already `Color.WHITE`, kept as-is), because the
## existing white-on-orange text is a separate, already-flagged ~2.2:1 contrast failure
## (see the state-spec doc) that is explicitly OUT OF SCOPE for this pass — fixing it here would
## silently change primary buttons' NORMAL look, which was not asked for.
## `owned` marks a button for something the player already has — see `owned_button_style()` for
## why that cannot be the same look as "disabled". It overrides every state (an owned button is
## not clickable, so hover and pressed never really happen; giving them the same box stops Godot
## flashing a stock grey if it ever does).
static func style_button(btn: Button, primary: bool, warning: bool = false,
		font_color: Variant = null, owned: bool = false) -> void:
	if owned:
		for state_key in ["normal", "hover", "pressed", "disabled"]:
			btn.add_theme_stylebox_override(state_key, owned_button_style())
		for color_key in ["font_color", "font_hover_color", "font_pressed_color",
				"font_disabled_color"]:
			btn.add_theme_color_override(color_key, SUCCESS)
		return
	if primary:
		btn.add_theme_stylebox_override("normal", primary_button_style(warning, ButtonState.NORMAL))
		btn.add_theme_stylebox_override("hover", primary_button_style(warning, ButtonState.HOVER))
		btn.add_theme_stylebox_override("pressed", primary_button_style(warning, ButtonState.PRESSED))
		btn.add_theme_stylebox_override("disabled", primary_button_style(warning, ButtonState.DISABLED))
	else:
		btn.add_theme_stylebox_override("normal", secondary_button_style(ButtonState.NORMAL))
		btn.add_theme_stylebox_override("hover", secondary_button_style(ButtonState.HOVER))
		btn.add_theme_stylebox_override("pressed", secondary_button_style(ButtonState.PRESSED))
		btn.add_theme_stylebox_override("disabled", secondary_button_style(ButtonState.DISABLED))

	if font_color is Color:
		var c: Color = font_color
		btn.add_theme_color_override("font_color", c)
		btn.add_theme_color_override("font_hover_color", c)
		btn.add_theme_color_override("font_pressed_color", c)
		btn.add_theme_color_override("font_disabled_color", Color(c.r, c.g, c.b, c.a * 0.6))
