extends RefCounted
class_name DangoTheme
## Dango design-system palette (design/art-director review, see
## `/Users/loc.tien.nguyen/Downloads/review-uiux-battle-screen.md`, applied 2026-09-17) —
## single source of truth for every combat-UI color touched by that review, so nothing drifts
## back to the old per-file ad-hoc color literals (StyleBoxFlat colors hand-picked per node in
## Combat.tscn/CombatView.gd before this pass).
##
## FONTS (resolved 2026-09-20 — this section used to be a standing TODO). Both families now
## ship under `assets/fonts/` and both are wired below. The split is two families with two
## jobs, from the v2 UI handoff §02 TYPE SCALE:
##
##   FONT_DISPLAY  Baloo 2     every title, EVERY NUMERAL, unit names, die values, button labels
##   FONT_UI       Work Sans   prose only — log lines, passives, relic and event body text
##
## Baloo 2 on display type is a recorded deviation from Dango's Work Sans, approved 20 Sep 2026.
## The reason is worth keeping because it is not taste: a neutral grotesk set against
## black-outlined flat-tone cards reads as a dashboard, and the whole first pass of this
## redesign was rejected for exactly that. Baloo 2's weight and rounded terminals match the
## 9-unit black outline the icon kit is drawn with, so type and art look authored by one hand.
##
## DO NOT set a font on an individual Label. Everything resolves through the one Theme built by
## `build_theme()` and saved at `res://resources/theme/dango.tres`, applied on the root Control
## of every scene. A per-Label override is how a screen silently drifts off the type scale.

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

## Display face — Baloo 2. Three weights, because the type scale calls for 700 and 800 and the
## 600 is what keeps a 12px caption from turning into a blob at chip size.
const FONT_DISPLAY: Font = preload("res://assets/fonts/Baloo2-ExtraBold.ttf")      # w800
const FONT_DISPLAY_BOLD: Font = preload("res://assets/fonts/Baloo2-Bold.ttf")      # w700
const FONT_DISPLAY_SEMI: Font = preload("res://assets/fonts/Baloo2-SemiBold.ttf")  # w600

## Reading face — Work Sans. Paragraphs only.
const FONT_UI: Font = preload("res://assets/fonts/WorkSans-Medium.ttf")            # w500
const FONT_UI_SEMI: Font = preload("res://assets/fonts/WorkSans-SemiBold.ttf")     # w600
const FONT_UI_BOLD: Font = preload("res://assets/fonts/WorkSans-Bold.ttf")         # w700

## Kept under its original name so nothing that already reads `DangoTheme.FONT` has to change.
## It resolves to the READING face on purpose: the Theme's default font is what an unstyled
## Label gets, and an unstyled Label is almost always a line of prose. Display type is opted
## into, never inherited.
const FONT: Font = FONT_UI

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
	# v2: a solid SUCCESS fill with black ink, not an 18%-alpha wash of SUCCESS. Under the
	# "colour is a solid fill, never a tint" rule the washed version lost the colour entirely —
	# which defeated the whole point of this style existing separately from `disabled`.
	var sb := StyleBoxFlat.new()
	sb.bg_color = SUCCESS
	sb.border_color = Color.BLACK
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 14.0
	sb.content_margin_right = 14.0
	sb.content_margin_top = 7.0
	sb.content_margin_bottom = 7.0
	sb.shadow_color = SHELF
	sb.shadow_size = 0
	sb.shadow_offset = Vector2(0, 4)
	return sb


## A small coloured chip for a rarity tier. Common/Uncommon/Rare/Epic/Legendary = 0..4, matching
## the `rar` field `reward_generator.gd` already puts on every reward, shop item and relic.
##
## Lives here rather than in one screen because the Result screen grew its own version first and
## the reward/shop/event/treasure cards — the screens where rarity actually changes a decision —
## never got one. One definition, so the two cannot drift apart.
const RARITY_NAMES: Array[String] = ["Common", "Uncommon", "Rare", "Epic", "Legendary"]
## Exact v2 hexes (handoff §Colour · Rarity). They were eyeballed approximations of these until
## 2026-09-20; the epic and legendary values now equal MANA_PURPLE and PRIMARY exactly, which is
## intended — rarity and mana share a purple, and legendary IS the Kam orange.
const RARITY_COLORS: Array[Color] = [
	Color(0xC6 / 255.0, 0xCE / 255.0, 0xDA / 255.0),   # Common — plain grey, deliberately unexciting
	Color(0x40 / 255.0, 0xCC / 255.0, 0x3D / 255.0),   # Uncommon
	Color(0x33 / 255.0, 0xB8 / 255.0, 0xFF / 255.0),   # Rare
	Color(0xBF / 255.0, 0x6B / 255.0, 0xFF / 255.0),   # Epic
	Color(0xFF / 255.0, 0x94 / 255.0, 0x45 / 255.0),   # Legendary
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
		# Disabled ignores `warning` entirely and never borrows hover/pressed's colour direction.
		# v2 change: it flattens by DESATURATING the fill, not by dropping alpha — the ink on top
		# stays at full strength, because the label on a button you cannot press is usually the
		# reason you cannot press it.
		var flat := PRIMARY.darkened(0.42)
		sb.bg_color = Color(flat.r * 0.72 + 0.16, flat.g * 0.72 + 0.14, flat.b * 0.72 + 0.17)
		sb.border_color = Color.BLACK
		sb.set_border_width_all(4)
		sb.set_corner_radius_all(15)
		sb.content_margin_left = 18.0
		sb.content_margin_right = 18.0
		sb.content_margin_top = 10.0
		sb.content_margin_bottom = 10.0
		return sb

	# v2 values, from the END TURN redline: hover lightens to #FFAC6B, active darkens to
	# #E2761F. Spelled as hex rather than as .lightened()/.darkened() because these two are
	# redlined colours, not derived ones.
	match state:
		ButtonState.HOVER:
			sb.bg_color = Color(0xFF / 255.0, 0xAC / 255.0, 0x6B / 255.0)
		ButtonState.PRESSED:
			sb.bg_color = Color(0xE2 / 255.0, 0x76 / 255.0, 0x1F / 255.0)
		_:
			sb.bg_color = PRIMARY

	# One outline, pure black — except on a warning button, where the border is carrying a
	# meaning (abandon the run) that the fill cannot, since the fill is the primary colour.
	sb.border_color = DANGER if warning else Color.BLACK
	var border_w := 4
	if state == ButtonState.PRESSED:
		border_w += 1   # pressed = colour + geometry
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(15)
	sb.content_margin_left = 18.0
	sb.content_margin_right = 18.0
	var margin_shift := 1.0 if state == ButtonState.PRESSED else 0.0
	sb.content_margin_top = 10.0 + margin_shift
	sb.content_margin_bottom = 10.0 - margin_shift

	# The shelf, and the press taking it away. `shadow_size = 0` is what keeps it a hard offset
	# block instead of the blurred drop shadow the whole v2 pass exists to remove.
	if state != ButtonState.PRESSED:
		sb.shadow_color = SHELF_DEEP
		sb.shadow_size = 0
		sb.shadow_offset = Vector2(0, 6)
	return sb


## Secondary / utility button look — v2 rebuilds this as a PANEL_RAISED object rather than the
## v1 translucent outline.
##
## WHY THE v1 LOOK WAS REPLACED, since its own spec argued for it. v1 made the secondary button
## a mostly-transparent fill with a PRIMARY outline, and distinguished its states by ALPHA
## (hover keeps 0.55 and lightens rgb; pressed jumps to 0.85 with rgb unchanged). That works on
## a flat dark canvas. It stops working the moment the button sits on a bright painted plate,
## which after the background formula is now every screen: an alpha change against unpredictable
## art is not a reliable signal, and the orange outline started reading as a selection state.
##
## v2 keeps the STRUCTURE of the old contract intact — hover changes colour only, pressed
## changes colour and geometry in the opposite direction and drops the shelf, disabled borrows
## neither direction — and changes only the values: an opaque `PANEL_RAISED` fill, a pure-black
## outline, and a hover that fills PRIMARY (from the REROLL redline, "hover fill PRIMARY").
## `t_button_states.gd` was updated in the same commit and still asserts every one of those
## structural rules.
static func secondary_button_style(state: ButtonState = ButtonState.NORMAL) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	var border_w := 3

	match state:
		ButtonState.HOVER:
			sb.bg_color = PRIMARY
		ButtonState.PRESSED:
			sb.bg_color = PRIMARY.darkened(0.22)
			border_w = 4
		ButtonState.DISABLED:
			sb.bg_color = PANEL_RAISED.darkened(0.38)
		_:
			sb.bg_color = PANEL_RAISED

	sb.border_color = Color.BLACK
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 14.0
	sb.content_margin_right = 14.0
	var margin_shift := 1.0 if state == ButtonState.PRESSED else 0.0
	sb.content_margin_top = 7.0 + margin_shift
	sb.content_margin_bottom = 7.0 - margin_shift
	if state != ButtonState.PRESSED and state != ButtonState.DISABLED:
		sb.shadow_color = SHELF
		sb.shadow_size = 0
		sb.shadow_offset = Vector2(0, 4)
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
			btn.add_theme_color_override(color_key, INK)
		return
	if primary:
		# v2 closes the flagged ~2.2:1 failure at its source: white on Kam orange is gone, and a
		# primary button inks itself at #2A1505 (11.4:1) unless the call site names a colour.
		# It is done HERE rather than at each call site so the pairing cannot come back.
		if not (font_color is Color):
			font_color = INK_ON_PRIMARY
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


# ═══════════════════════════════════════════════════════════════════════════════════════════
# v2 SURFACE SYSTEM — design_handoff_axie_dice_ui, §02 TOKENS
# ═══════════════════════════════════════════════════════════════════════════════════════════
#
# WHAT THIS ADDS AND WHY IT IS A SEPARATE BLOCK. Everything above is the COLOUR set, and the
# handoff's own §02 says that set was already right. What the build had no vocabulary for at all
# was ELEVATION: every panel in the game was one `BG_PANEL` at 0.82 alpha, so nothing on screen
# read as being in front of anything else. That is most of why the port looked like a dark
# dashboard instead of like Axie.
#
# The vocabulary is six surfaces doing six different jobs, and the job — not the look — is what
# picks one:
#
#   PANEL         chrome that FRAMES the screen        top bar, bottom deck, secondary buttons
#   PANEL_DEEP    an opaque panel ON the painted art   nameplates, map run card, stat ribbon
#   PANEL_ON_ART  as PANEL_DEEP but the art reads through   SAVE & QUIT, menu nav tiles
#   PANEL_RAISED  a utility object sitting on a panel  utility buttons, wave chip, reroll
#   WELL          anything that HOLDS something else   mana card, wave track, locked pass tile
#   CARD_CREAM    anything the player has to READ      die cards, inspector, reward cards
#
# PANEL and PANEL_DEEP are two opaque dark tones that coexist on purpose. A `#1B1F27` fill in a
# mockup is not a leftover from v1 — check which job the surface is doing before "correcting" it.
#
# THREE ART RULES, quoted from the icon kit's own README and extended from 128px glyphs to
# screen chrome. A surface that breaks one is wrong even if it matches its redline:
#
#   1. One outline: pure #000000. 3px on chips and bars, 4px on cards and rails, 5–6px on hero
#      objects. Never a translucent hairline, never rgba.
#   2. Two flat tones per surface, no gradients. A base fill and at most one lighter block — a
#      solid band, not a ramp. The only gradients in the entire design are the background scrims.
#   3. Shadows are hard shelves, not blur: `shadow_size = 0` with a `shadow_offset` of +4 to +8
#      on y. A pressed button drops its shelf and translates down — the shelf being taken away
#      IS the press. A blurred shadow is the single clearest tell of the look this replaces.

const BG_DEEP := Color(0x07 / 255.0, 0x08 / 255.0, 0x0B / 255.0)          # behind the 3D stage
const INK_ON_PRIMARY := Color(0x2A / 255.0, 0x15 / 255.0, 0x05 / 255.0)   # 11.4:1 on Kam orange
const INK := Color(0x1A / 255.0, 0x12 / 255.0, 0x06 / 255.0)              # 12.9:1 on cream

const PANEL := Color(0x1B / 255.0, 0x1F / 255.0, 0x27 / 255.0)
const PANEL_DEEP := Color(0x16 / 255.0, 0x1A / 255.0, 0x21 / 255.0)
const PANEL_ON_ART := Color(0x1B / 255.0, 0x1F / 255.0, 0x27 / 255.0, 0.92)
const PANEL_OVER_CLASS := Color(0x0B / 255.0, 0x0D / 255.0, 0x12 / 255.0, 0.90)
const PANEL_RAISED := Color(0x26 / 255.0, 0x2C / 255.0, 0x36 / 255.0)
const WELL := Color(0x10 / 255.0, 0x13 / 255.0, 0x1A / 255.0)
const WELL_TRACK := Color(0x14 / 255.0, 0x18 / 255.0, 0x20 / 255.0)       # the wave track only
const WELL_DEEP := Color(0x0B / 255.0, 0x0D / 255.0, 0x12 / 255.0)        # HP-bar trough
const DECK := Color(0x17 / 255.0, 0x1A / 255.0, 0x21 / 255.0)             # the bottom action bar

const CREAM := Color(0xF3 / 255.0, 0xE7 / 255.0, 0xD3 / 255.0)
const CREAM_RAISED := Color(0xFF / 255.0, 0xF8 / 255.0, 0xEA / 255.0)
const CREAM_TRACK := Color(0xD6 / 255.0, 0xC6 / 255.0, 0xA8 / 255.0)      # unrolled face bars
const CREAM_HI := Color(0xFF / 255.0, 0xC7 / 255.0, 0x9B / 255.0)         # current pip, SPACE chip

const FUTURE := Color(0x39 / 255.0, 0x40 / 255.0, 0x4E / 255.0)           # spent pip, future wave
const AT_RISK := Color(0x7A / 255.0, 0x1F / 255.0, 0x1C / 255.0)          # HP the telegraph takes
const DISABLED_FILL := Color(0x4A / 255.0, 0x3F / 255.0, 0x58 / 255.0)    # unaffordable active

const SHELF := Color(0, 0, 0, 0.50)     # plates
const SHELF_DEEP := Color(0, 0, 0, 0.55)  # hero objects

## The one rule that governs `DISABLED`, written here because it is the one most often got wrong:
## a disabled surface is a flat DESATURATED FILL with its ink at FULL strength — never a blanket
## `modulate.a`. Blanket opacity drops the text along with the card, and on the surface this rule
## exists for (a relic active you cannot afford) the cost line is the entire reason the card is
## on screen. Dim the fill, keep the number readable.


## ── v2 meta-screen ink (PASS / UNLOCKS / VAULT / GUIDES, docs/design-handoff-v2) ──────────────
##
## Added for the four meta screens' restyle. These are additional ink/text tones the mockup uses
## beyond the existing INK / INK_ON_PRIMARY / TEXT_DIM set — the tint rule ("colour is a solid
## fill, never a wash") means each fill needs its own hand-picked ink rather than one alpha-mixed
## formula, so a new fill colour on a meta screen generally means a new ink token here too.
##
## FLAGGED simplification: the mockup uses two very-similar cream-ink browns for body copy
## (#3A2A12 on the Pass claimed-tile title and the Guides "why" paragraph) and (#5A4525 on the
## Guides bullet list) — folded into the one INK_ON_CREAM_SOFT below. The difference reads as
## noise, not signal, at this project's font sizes, and the whole point of this file is a small,
## reusable vocabulary rather than one token per pixel sample.
const INK_ON_SUCCESS := Color(0x07 / 255.0, 0x26 / 255.0, 0x0A / 255.0)      # ink on a SUCCESS fill (Pass "CLAIM NOW" tile)
const INK_ON_DANGER := Color(0x2A / 255.0, 0x08 / 255.0, 0x06 / 255.0)       # ink on a DANGER fill (Vault's disabled-import plate, REMOVE button)
const INK_ON_SHIELD := Color(0x06 / 255.0, 0x22 / 255.0, 0x2E / 255.0)       # ink on SHIELD_BLUE (Vault's header eyebrow + imported-count chip)
const INK_ON_CREAM_MUTED := Color(0x6B / 255.0, 0x54 / 255.0, 0x33 / 255.0)  # captions/meta text on cream (Vault subtitle, Guides difficulty tag, Pass "CLAIMED" state text)
const INK_ON_CREAM_SOFT := Color(0x3A / 255.0, 0x2A / 255.0, 0x12 / 255.0)   # body prose on cream, one step lighter than INK (Guides "why"/"how" text)
const MUTED_TEXT := Color(0x8C / 255.0, 0x95 / 255.0, 0xA4 / 255.0)         # secondary text on a dark panel — a solid grey, not TEXT_DIM's alpha wash (Unlocks row description, XP-to-next line)
const FAINT_TEXT := Color(0x5C / 255.0, 0x65 / 255.0, 0x73 / 255.0)         # tertiary/locked text on a dark panel, dimmer than MUTED_TEXT (Pass "NEEDS LV n", Unlocks locked step number)
const WARN_YELLOW := Color(0xFF / 255.0, 0xD7 / 255.0, 0x6A / 255.0)         # "NO EFFECT YET" and similar advisory-not-danger tags
const INFO_TEXT_ON_WELL := Color(0xC7 / 255.0, 0xBB / 255.0, 0xD6 / 255.0)   # pale mana-tinted advisory text inside a WELL (Vault's RANKED RUN note)

## ADDED 2026-09-20 consistency sweep: RunMapController and ResultView had each independently
## picked this exact hex for the same job (a caption one step dimmer than TEXT, brighter than
## MUTED_TEXT) — RunMapController's rail eyebrow/seed/stat captions and Result's stat-ribbon
## labels. Promoted here rather than left as two file-local consts because that convergence is
## itself the signal a shared token belongs in the system (see this file's own "prefer fixing the
## SYSTEM" rule).
const CAPTION_MUTED := Color(0x6F / 255.0, 0x78 / 255.0, 0x87 / 255.0)
## ADDED 2026-09-20: RunMapController's tier chip ("T1") and relic-count ink on a WELL surface,
## used twice in that file with the same inline literal. One token so the two cannot drift apart.
const CHIP_INK_ON_WELL := Color(0xA9 / 255.0, 0xB3 / 255.0, 0xC2 / 255.0)


## Every Axie class, at full strength. These are semantic: a class colour may never be
## recoloured to pass a contrast check — put the text on ink instead, which is what the cream
## die-card header and the Result nameplate both do.
const CLASS_COLORS := {
	"plant": Color(0x7D / 255.0, 0xC9 / 255.0, 0x43 / 255.0),
	"beast": Color(0xFF / 255.0, 0xB2 / 255.0, 0x3F / 255.0),
	"aqua": Color(0x39 / 255.0, 0xC5 / 255.0, 0xF3 / 255.0),
	"reptile": Color(0xB6 / 255.0, 0x79 / 255.0, 0xF7 / 255.0),
	"bug": Color(0xF2 / 255.0, 0x62 / 255.0, 0x4F / 255.0),
	"bird": Color(0x8B / 255.0, 0xDC / 255.0, 0xFF / 255.0),
}


## Falls back to PRIMARY rather than to grey: an unknown class is a content bug, and a Kam-orange
## header is loud enough to be noticed in a playtest, where a grey one would be read as intended.
static func class_color(cls: String) -> Color:
	var key := cls.strip_edges().to_lower()
	return CLASS_COLORS.get(key, PRIMARY)


## Map-node tones, as base / top block / bottom lip. Three flat tones, not a gradient — the top
## block covers the upper 44% of the token and the lip the lower 19%, which is how a flat fill
## reads as a solid object under the no-gradient rule.
const NODE_TONES := {
	"battle": [Color(0xD8 / 255.0, 0x34 / 255.0, 0x2F / 255.0), Color(0xF5 / 255.0, 0x45 / 255.0, 0x40 / 255.0), Color(0xA3 / 255.0, 0x23 / 255.0, 0x20 / 255.0)],
	"elite": [Color(0xA3 / 255.0, 0x53 / 255.0, 0xE8 / 255.0), Color(0xBF / 255.0, 0x6B / 255.0, 0xFF / 255.0), Color(0x7B / 255.0, 0x34 / 255.0, 0xB8 / 255.0)],
	"event": [Color(0x1F / 255.0, 0xA8 / 255.0, 0xDE / 255.0), Color(0x31 / 255.0, 0xC6 / 255.0, 0xFF / 255.0), Color(0x16 / 255.0, 0x78 / 255.0, 0x9E / 255.0)],
	"merchant": [Color(0xE8 / 255.0, 0x80 / 255.0, 0x2F / 255.0), Color(0xFF / 255.0, 0x93 / 255.0, 0x45 / 255.0), Color(0xB3 / 255.0, 0x5B / 255.0, 0x15 / 255.0)],
	"treasure": [Color(0xE5 / 255.0, 0xAC / 255.0, 0x2A / 255.0), Color(0xFF / 255.0, 0xC4 / 255.0, 0x45 / 255.0), Color(0xA9 / 255.0, 0x7C / 255.0, 0x12 / 255.0)],
	"visited": [Color(0xC6 / 255.0, 0xB7 / 255.0, 0x9B / 255.0), Color(0xE2 / 255.0, 0xD5 / 255.0, 0xBC / 255.0), Color(0x9A / 255.0, 0x8B / 255.0, 0x70 / 255.0)],
	"fog": [Color(0x16 / 255.0, 0x1A / 255.0, 0x22 / 255.0), Color(0x1F / 255.0, 0x24 / 255.0, 0x2E / 255.0), Color(0x0F / 255.0, 0x12 / 255.0, 0x18 / 255.0)],
	# ADDED for RunMap v2 (docs/design-handoff-v2, RUN MAP screen): an inert, never-visited
	# sibling node (a branch the player didn't take) — the mockup's TONE_SKIP, missing from
	# this table until now. Same family as PANEL_RAISED, one step lighter/darker per band.
	"skip": [Color(0x26 / 255.0, 0x2C / 255.0, 0x36 / 255.0), Color(0x32 / 255.0, 0x38 / 255.0, 0x47 / 255.0), Color(0x19 / 255.0, 0x1D / 255.0, 0x25 / 255.0)],
}


## `kind` is the node type, or "visited"/"fog" for state. Boss reuses "battle" deliberately —
## the boss is told apart by size, by the ribbon in the header and by the DANGER pip on the wave
## track, not by a sixth colour nobody has learned yet.
static func node_tone(kind: String) -> Array:
	return NODE_TONES.get(kind, NODE_TONES["battle"])


enum Surface { PANEL, PANEL_DEEP, PANEL_ON_ART, PANEL_OVER_CLASS, PANEL_RAISED, WELL, WELL_TRACK, WELL_DEEP, DECK, CREAM, CREAM_RAISED }


static func surface_color(kind: Surface) -> Color:
	match kind:
		Surface.PANEL: return PANEL
		Surface.PANEL_DEEP: return PANEL_DEEP
		Surface.PANEL_ON_ART: return PANEL_ON_ART
		Surface.PANEL_OVER_CLASS: return PANEL_OVER_CLASS
		Surface.PANEL_RAISED: return PANEL_RAISED
		Surface.WELL: return WELL
		Surface.WELL_TRACK: return WELL_TRACK
		Surface.WELL_DEEP: return WELL_DEEP
		Surface.DECK: return DECK
		Surface.CREAM: return CREAM
		Surface.CREAM_RAISED: return CREAM_RAISED
	return PANEL


## The one constructor every v2 surface goes through.
##
## `shelf` is the hard offset shadow in pixels — 0 for a surface that is part of the frame
## (the top bar is not floating above anything), 4 on a plate, 6–8 on a hero object. It is
## implemented as `shadow_size = 0` plus a y-only `shadow_offset`, which is what makes it a
## shelf rather than the blurred drop shadow this system exists to get rid of.
##
## `pad` is (horizontal, vertical) content margin. Passing Vector2(-1, -1) leaves the margins at
## Godot's zero, which is what a surface that is positioned by anchors rather than by a
## container wants.
static func surface_style(kind: Surface, radius: int = 13, border_w: int = 3,
		shelf: float = 0.0, pad: Vector2 = Vector2(12, 8)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = surface_color(kind)
	sb.border_color = Color.BLACK
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	if pad.x >= 0.0:
		sb.content_margin_left = pad.x
		sb.content_margin_right = pad.x
	if pad.y >= 0.0:
		sb.content_margin_top = pad.y
		sb.content_margin_bottom = pad.y
	if shelf > 0.0:
		sb.shadow_color = SHELF_DEEP if shelf >= 6.0 else SHELF
		sb.shadow_size = 0
		sb.shadow_offset = Vector2(0, shelf)
	return sb


## A cream reading surface with its class-coloured top border. `accent` at Color.TRANSPARENT
## means no band — a plain cream card, which is what the reward and treasure cards are.
static func cream_card_style(accent: Color = Color.TRANSPARENT, radius: int = 15,
		border_w: int = 4, shelf: float = 6.0, raised: bool = false) -> StyleBoxFlat:
	var sb := surface_style(Surface.CREAM_RAISED if raised else Surface.CREAM,
		radius, border_w, shelf, Vector2(-1, -1))
	if accent.a > 0.0:
		sb.border_color = Color.BLACK
		sb.expand_margin_top = 0.0
	return sb


## A status / rarity / keyword chip: the colour at FULL strength with black ink on it, never an
## 8%-alpha wash of it. The tinted-to-6–14% version is exactly what made the first pass read as
## an analytics panel — every one of these colours was there and none of them was visible.
##
## Note this is a DIFFERENT object from `kw_chip_style()` above, which is the dark-panel keyword
## pill (a dark fill with a coloured border). This one is the solid chip. Both ship because the
## die card uses the solid chip on cream and the inspector uses the outlined pill on dark.
static func solid_chip_style(fill: Color, radius: int = 9, border_w: int = 3,
		pad: Vector2 = Vector2(8, 1)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = Color.BLACK
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = pad.x
	sb.content_margin_right = pad.x
	sb.content_margin_top = pad.y
	sb.content_margin_bottom = pad.y
	return sb


## Ink that stays legible on `fill`. Used by every solid chip so a caller never has to guess
## whether a status colour wants black or cream on it — and so nobody "fixes" a contrast failure
## by desaturating the status colour, which the handoff forbids.
static func ink_on(fill: Color) -> Color:
	var luma := fill.r * 0.2126 + fill.g * 0.7152 + fill.b * 0.0722
	return INK if luma > 0.42 else CREAM


## ADDED 2026-09-20 consistency sweep: a translucent PRIMARY wash for hairline dividers only —
## RunMapController and ResultView had each independently recomputed `Color(PRIMARY.r, .g, .b,
## 0.22)` at three call sites between them. NOT for a chip or card fill (those are solid, never a
## wash — see `solid_chip_style()`/`rarity_chip()`); a divider is the one place in the system a
## tint beats a block, because a solid-orange rule line would out-weigh the content it separates.
static func primary_divider_alpha() -> Color:
	return Color(PRIMARY.r, PRIMARY.g, PRIMARY.b, 0.22)


# ── Background formula ─────────────────────────────────────────────────────────────────────
#
# Every screen is: painted plate → directional scrim → UI. Do the stage background FIRST on any
# screen — every other value on that screen was tuned against it.
#
# The rule that this exists to enforce: never darken the whole plate to fix a contrast failure.
# The painted Lunacia backgrounds are the strongest art asset in the project and the first pass
# ran them at 18–30% brightness and threw that away. Where text sits on art, give the text a
# plate instead.

enum Scrim { DEFAULT, COMBAT, RESULT, MENU }

const SCRIM_INK := Color(0x0E / 255.0, 0x10 / 255.0, 0x16 / 255.0)


## The scrim as a texture ready for a TextureRect stretched over the plate.
##
## DEFAULT is radial and everything else is linear, because only the default has no single
## direction to favour: a map or a shop needs ink in the corners and open art in the middle,
## while combat, Result and the menu each have one edge that has to carry type.
static func scrim_texture(kind: Scrim = Scrim.DEFAULT) -> GradientTexture2D:
	var grad := Gradient.new()
	var tex := GradientTexture2D.new()
	tex.width = 256
	tex.height = 256

	match kind:
		Scrim.COMBAT:
			# Dark under the top bar and under the deck, open through the band where the models
			# stand. This is the one that makes the arena look lit rather than washed.
			grad.offsets = PackedFloat32Array([0.0, 0.26, 0.52, 0.80, 1.0])
			grad.colors = PackedColorArray([
				_scrim(0.62), _scrim(0.20), _scrim(0.10), _scrim(0.50), _scrim(0.76)])
			tex.fill = GradientTexture2D.FILL_LINEAR
			tex.fill_from = Vector2(0.5, 0.0)
			tex.fill_to = Vector2(0.5, 1.0)
		Scrim.RESULT:
			# The title band needs ink; the party row in the middle does not.
			grad.offsets = PackedFloat32Array([0.0, 0.22, 0.40, 0.88, 1.0])
			grad.colors = PackedColorArray([
				_scrim(0.80), _scrim(0.52), _scrim(0.34), _scrim(0.82), _scrim(0.92)])
			tex.fill = GradientTexture2D.FILL_LINEAR
			tex.fill_from = Vector2(0.5, 0.0)
			tex.fill_to = Vector2(0.5, 1.0)
		Scrim.MENU:
			# The only HORIZONTAL scrim in the design: ink under the title on the left, art left
			# open on the right. 100deg in CSS is very nearly left-to-right with a slight tilt;
			# the tilt is reproduced by ending the ramp a little below where it started.
			grad.offsets = PackedFloat32Array([0.0, 0.28, 0.52, 0.78, 1.0])
			grad.colors = PackedColorArray([
				_scrim(0.94), _scrim(0.80), _scrim(0.30), _scrim(0.52), _scrim(0.78)])
			tex.fill = GradientTexture2D.FILL_LINEAR
			tex.fill_from = Vector2(0.0, 0.41)
			tex.fill_to = Vector2(1.0, 0.59)
		_:
			grad.offsets = PackedFloat32Array([0.0, 0.52, 1.0])
			grad.colors = PackedColorArray([_scrim(0.04), _scrim(0.40), _scrim(0.84)])
			tex.fill = GradientTexture2D.FILL_RADIAL
			tex.fill_from = Vector2(0.55, 0.08)
			tex.fill_to = Vector2(1.80, 1.03)   # radius ≈ 125% × 95% of the box, per the formula

	tex.gradient = grad
	return tex


static func _scrim(alpha: float) -> Color:
	return Color(SCRIM_INK.r, SCRIM_INK.g, SCRIM_INK.b, alpha)


## The colour grade for the painted plate underneath the scrim. Combat runs one notch darker and
## less saturated than everywhere else because it has type at both the top and the bottom edge.
static func plate_material(combat: bool = false) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://resources/shaders/plate_grade.gdshader")
	mat.set_shader_parameter("brightness", 0.74 if combat else 0.82)
	mat.set_shader_parameter("saturation", 1.02 if combat else 1.05)
	return mat


## Builds the plate → scrim stack under `host` and returns the TextureRect holding the plate, so
## the caller can swap `texture` per region without rebuilding anything. Both children are
## MOUSE_FILTER_IGNORE and full-rect, so they never eat a click meant for the screen above them.
##
## Call this before laying out anything else on a screen. The handoff is blunt about the order
## and it is not stylistic: every colour value on a screen was picked against the plate that
## ends up behind it, so a screen built first and back-plated afterwards has to be re-tuned.
static func build_plate(host: Control, plate: Texture2D, kind: Scrim = Scrim.DEFAULT,
		combat: bool = false) -> TextureRect:
	var art := TextureRect.new()
	art.name = "Plate"
	art.texture = plate
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.material = plate_material(combat)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.add_child(art)

	var scrim := TextureRect.new()
	scrim.name = "Scrim"
	scrim.texture = scrim_texture(kind)
	scrim.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scrim.stretch_mode = TextureRect.STRETCH_SCALE
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.add_child(scrim)
	return art


# ── Display type: leading ───────────────────────────────────────────────────────────────────
#
# MEASURED, not guessed: Baloo 2 reports a line height of 142px at font size 88 — 1.61em. That
# is normal for the family (its vertical metrics carry Devanagari, which needs the room) and it
# is invisible on a single-line label. On a two-line display title it opens a gap the design
# never has: the mockup sets `line-height: .92` on every display block, and at 88px the
# difference between the two is 61 pixels of dead air in the middle of the largest object on
# the screen.
#
# Godot's `line_spacing` is an ABSOLUTE pixel constant, so one value in the Theme cannot serve
# an 88px title and a 15px caption. It has to be derived per label from the real metrics, which
# is what this does. Any multi-line Baloo 2 label wants it.

const DISPLAY_LEADING := 0.92


## The `line_spacing` constant that makes `font` at `size` sit on a `ratio`-em line.
## Returns a negative number for Baloo 2, which is the point.
static func leading_for(font: Font, size: int, ratio: float = DISPLAY_LEADING) -> int:
	return int(round(size * ratio - font.get_height(size)))


## A display-type Label, correctly leaded. Use this rather than setting the three overrides by
## hand — the leading is the one that gets forgotten, and it only shows up on the labels big
## enough for it to matter.
##
## `weight` is 800 (default), 700 or 600; anything else falls back to 800 rather than silently
## picking a face nobody chose.
static func display_label(text: String, size: int, color: Color = TEXT,
		weight: int = 800) -> Label:
	var font: Font = FONT_DISPLAY
	if weight == 700:
		font = FONT_DISPLAY_BOLD
	elif weight == 600:
		font = FONT_DISPLAY_SEMI
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_override("font", font)
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_constant_override("line_spacing", leading_for(font, size))
	return lbl
