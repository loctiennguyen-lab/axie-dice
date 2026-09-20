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
# BG_PANEL and BG_PANEL_SOFT are DELETED (FIX-PASS-02 RC2). They were one translucent fill at
# 0.82 / 0.55 alpha, and while they existed the combat HUD kept using them: a translucent plate,
# a 2px non-black border and a blurred `shadow_size = 8` survived three redesign passes because
# the old API was still callable. Deleting them is what forced every call site onto
# `surface_style()`. If you need a dark surface, pick the one whose JOB matches — PANEL for
# chrome, PANEL_DEEP for a plate on artwork, WELL for something that holds something else.
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

## Status colours — CB-13 (status chip) and CB-16 (status aura). Taken VERBATIM from the v2
## combat mockup's own `AURA` table (docs/design-handoff-v2/mockups-v2/combat-v2.html), not
## chosen here: poison #A8D84A, thorns #FFB23F, burn #FF9345, weaken #FF8FC7, vuln #F54540,
## regen #3FCD3C, stun #FFD76A, freeze #8BDCFF. Six of those eight are already tokens and are
## referenced as such rather than re-typed as a second literal.
##
## FLAGGED — `blind` and `undying` are real statuses in `Unit.status` (see unit.gd) but the
## mockup's table has NO entry for either, so their two colours are the only ones on this list
## I chose rather than read. `blind` borrows the debuff family's pink and `undying` the cream
## highlight. Both are marked here so a design answer can replace them rather than having to
## first discover that a guess was made.
const STATUS_THORNS := Color(0xFF / 255.0, 0xB2 / 255.0, 0x3F / 255.0)
const STATUS_FREEZE := Color(0x8B / 255.0, 0xDC / 255.0, 0xFF / 255.0)

static func status_color(key: String) -> Color:
	match key:
		"poison": return POISON_GREEN       # #A8D84A
		"thorns": return STATUS_THORNS      # #FFB23F
		"burn": return PRIMARY              # #FF9345
		"weaken": return DEBUFF_PINK        # #FF8FC7
		"vulnerable": return DANGER         # #F54540 (mockup key "vuln")
		"regen": return SUCCESS             # #3FCD3C
		"stun": return WARN_YELLOW          # #FFD76A
		"freeze": return STATUS_FREEZE      # #8BDCFF
		"blind": return DEBUFF_PINK         # FLAGGED — not in the mockup table
		"undying": return CREAM_HI          # FLAGGED — not in the mockup table
		_: return MUTED_TEXT


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


## Die-face TYPE icon lookup — G-01 / L7 (FIX-PASS-03 §3): a colour block never stands alone for
## a mechanic, so every type swatch in the game carries this glyph inside it.
##
## SPEC DEVIATION, deliberate: FIX-PASS-03 §4/§8 and §11.6 name `assets/fx/` as the glyph source.
## That directory has never existed in this repo. All seven face types plus `blank` DO ship, at
## `assets/icons/web/` — the live web build's own icon set (src/art7.js parity), which
## tests/t_assets.gd already gates. Nothing is missing and nothing is substituted; only the path
## in the spec is wrong. See the task report for §11.6.
const FACE_TYPE_ICON := {
	"dmg": preload("res://assets/icons/web/dmg.png"),
	"shield": preload("res://assets/icons/web/shield.png"),
	"heal": preload("res://assets/icons/web/heal.png"),
	"poison": preload("res://assets/icons/web/poison.png"),
	"summon": preload("res://assets/icons/web/summon.png"),
	"mana": preload("res://assets/icons/web/mana.svg"),
	"buff": preload("res://assets/icons/web/buff.svg"),
	"debuff": preload("res://assets/icons/web/debuff.svg"),
	"blank": preload("res://assets/icons/web/blank.svg"),
}


## The glyph for a face type. Unknown types fall back to `blank` rather than returning null, so a
## swatch is never a bare colour block by accident — which is the whole point of G-01.
static func face_type_icon(face_type: String) -> Texture2D:
	return FACE_TYPE_ICON.get(face_type, FACE_TYPE_ICON["blank"])


## THE type-swatch builder — G-01 / L7. Every place that says "this face is of type X" builds it
## here: the die card (CB-23, 26/16), the unit inspector (CB-30, 22/14), Team Select's face cell
## (TEAM-04, 22/14) and the Vault's variant (VLT-05, 21/13).
##
## Three of those four used to build their own bare coloured square inline. That is exactly how
## this codebase ends up with a mechanic encoded as colour-plus-glyph on one screen and colour
## alone on another, which is the failure G-01 exists to close — so the swatch is a single
## function and the per-screen difference is reduced to two integers.
##
## `size` is the outer square; `icon_size` should stay at ~60-65% of it (L7).
static func type_swatch(face_type: String, size: int = 22, icon_size: int = 14,
		radius: int = 6, border_w: int = 3) -> PanelContainer:
	var swatch := PanelContainer.new()
	swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	swatch.custom_minimum_size = Vector2(size, size)
	swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	swatch.add_theme_stylebox_override("panel",
		solid_chip_style(die_type_color(face_type), radius, border_w, Vector2.ZERO))
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	swatch.add_child(center)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(icon_size, icon_size)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = face_type_icon(face_type)
	center.add_child(icon)
	return swatch


# kw_chip_style() and rarity_chip() — DELETED 2026-09-20.
#
# Both were the v1 way of showing a mechanic: a dark pill with a 1px coloured border and the
# colour repeated in the font. L4 forbids the first ("colour is a solid fill, never a wash") and
# L5 the second ("ink is chosen per fill, never by desaturating the fill"). Every call site had
# already moved to `solid_chip_style()` + `ink_on()` — the die card's keyword pills, the shop
# row's rarity chip, the status strip — so these two were reachable and wrong, which is exactly
# how the old look came back twice before (see RC2 in FIX-PASS-02, same story with panel_style).
#
# The replacement for a rarity chip is
#     solid_chip_style(rarity_color(rar), radius, border_w, pad)
# with its label at `ink_on(rarity_color(rar))` — see RunMapController._solid_rarity_chip().


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


## G3 — make a rounded frame actually CLIP its children to the rounded shape.
##
## `clip_contents = true` is NOT this. It clips children to the Control's RECT, which is square,
## so a full-bleed child — a class-coloured header band, a cream body, an accent strip — paints
## straight across the frame's corner radius. The card then reads pointed at the corners and
## rounded along the edges, which is the defect the 20 Sep review logged as G3 on the Team
## Select cards and the RUN SETUP panel, and which is latent anywhere a header sits on a body
## inside a rounded frame: die cards, Result cards, Vault cards, Reward cards, the Codex panel.
##
## `clip_children = CLIP_CHILDREN_AND_DRAW` masks children by what the PARENT drew — the rounded
## StyleBoxFlat — so the corners come back. `clip_contents` stays on with it: it is the cheap
## rectangular pre-clip and it still does useful work on a long label.
##
## It must be AND_DRAW, never ONLY. `CLIP_CHILDREN_ONLY` uses the parent purely as a mask and
## **does not draw the parent itself**, so every frame this was called on lost its own fill,
## border and shelf while keeping its children — the die card, the Team Select card, the Result
## and Vault cards, the Guides card, the Codex panel and the RUN SETUP panel all rendered as
## loose content floating on the background. That reads as "the card is missing", not as a
## clipping bug, which is why it survived a whole review pass.
##
## Call this on the FRAME, never on the header or body. Giving the child its own matching
## top-left/top-right radii is the other way to do it, and it is the wrong way here: it has to
## be repeated at every child, it has to be kept in step with the frame's radius by hand, and
## it does nothing for the bottom two corners of the body.
static func clip_to_frame(frame: Control) -> void:
	frame.clip_contents = true
	frame.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW


## Themes a ScrollContainer's bars, and — the part that actually matters — gives them a WIDTH.
##
## FIX-PASS-01 L2: several scenes already called this and still had an invisible scrollbar,
## because styling a bar that is 0px wide styles nothing. A list clipped by the bottom of the
## screen with no visible bar was called "the single worst defect in this build" and "reads as a
## crash" — the player has no way to know there is more. So this now sets `custom_minimum_size`
## on the real VScrollBar/HScrollBar nodes, which is where the bar's size comes from; the
## colours come from the project Theme (`tools/gen_theme.gd`) and do not need overriding here.
##
## Pass `fade = true` on a panel whose content runs under its bottom edge to also get the 24px
## fade the law asks for; it is a separate node, so the caller owns where it sits.
static func style_scrollbars(node: Control) -> void:
	var vbar: VScrollBar = null
	var hbar: HScrollBar = null
	if node is ScrollContainer:
		vbar = (node as ScrollContainer).get_v_scroll_bar()
		hbar = (node as ScrollContainer).get_h_scroll_bar()
	elif node is VScrollBar:
		vbar = node as VScrollBar
	elif node is HScrollBar:
		hbar = node as HScrollBar
	if vbar != null:
		vbar.custom_minimum_size.x = SCROLLBAR_THICKNESS
	if hbar != null:
		hbar.custom_minimum_size.y = SCROLLBAR_THICKNESS


## The 24px "there is more below" fade for a scrolled region (FIX-PASS-01 L2). Returns the node
## so the caller can anchor it over the bottom edge of the panel that holds the scroll.
static func scroll_fade(fill: Color = PANEL) -> TextureRect:
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 1.0])
	grad.colors = PackedColorArray([Color(fill.r, fill.g, fill.b, 0.0), fill])
	var tex := GradientTexture2D.new()
	tex.width = 8
	tex.height = 64
	tex.fill = GradientTexture2D.FILL_LINEAR
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to = Vector2(0.5, 1.0)
	tex.gradient = grad
	var rect := TextureRect.new()
	rect.name = "ScrollFade"
	rect.texture = tex
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.custom_minimum_size.y = SCROLL_FADE_HEIGHT
	return rect


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
## DELIBERATELY left null by every PRIMARY call site today, `_end_turn_button` included: END
## TURN's label is not `Button.text`/a font-colour override at all any more — it's a real child
## Label (`CombatView._style_end_turn_button()`) inked `INK_ON_PRIMARY` directly, and
## `_update_end_turn_ui()` no longer touches a font colour on the Button itself. The white-on-
## orange ~2.2:1 failure this paragraph used to call "explicitly OUT OF SCOPE" is fixed
## (FIX-PASS-01 §2.1 C9, 2026-09-20) — this paragraph was left describing the old behaviour after
## the fix landed, which is its own small bug; corrected in the same pass as C9.
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

## The one fill that says "this is not an attack". Empty States Spec §1 puts the enemy's
## NO MOVE / HIDDEN badge on #242A34 precisely because it is OUTSIDE the die-type palette
## (red / blue / green / purple): the colour alone has to carry "there is no move here" before
## the player reads a single letter. It is close to PANEL_RAISED (#262C36) and deliberately not
## the same token — PANEL_RAISED is a surface you put things ON, this is the whole object.
const INERT_FILL := Color(0x24 / 255.0, 0x2A / 255.0, 0x34 / 255.0)

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

# ── Mockup colours that had no token, added 20 Sep 2026 ──────────────────────────────────────
# Each of these appears verbatim in the v2 mockups and had no name here, so three separate
# passes each reached for "the nearest sanctioned token" and landed on a different near-miss:
# MUTED_TEXT stood in for two different greys, SHELF for a lighter black, STATUS_FREEZE for a
# text colour. Approximating a colour is not matching a design, and a near-miss that lives in
# code is indistinguishable from a deliberate choice six weeks later. These are the real values.

## `#B4600C` — the accent heading on a cream card: the inspector's `PASSIVE ·` eyebrow and Team
## Select's face-keyword line. PRIMARY is too light to sit on cream; this is its darker sibling.
const ACCENT_ON_CREAM := Color(0xB4 / 255.0, 0x60 / 255.0, 0x0C / 255.0)

## `#2E7D2B` — SUCCESS darkened for cream. The inspector's `ROLLED` tag. SUCCESS itself fails
## contrast on `#F3E7D3`; INK_ON_SUCCESS is near-black and loses the "this one is live" signal.
const SUCCESS_ON_CREAM := Color(0x2E / 255.0, 0x7D / 255.0, 0x2B / 255.0)

## `#5A3310` — the secondary ink on a Kam-orange fill: `TURN n` in the turn pill, the BEGIN RUN
## and mode-card subtitles, the shop panel's subtitle. INK_ON_PRIMARY at reduced alpha was the
## previous stand-in, which composites differently over every fill it lands on.
const INK_ON_PRIMARY_DIM := Color(0x5A / 255.0, 0x33 / 255.0, 0x10 / 255.0)

## `#98A2B1` — an eyebrow on a raised panel (the combat node chip's `BATTLE NODE`).
const EYEBROW_TEXT := Color(0x98 / 255.0, 0xA2 / 255.0, 0xB1 / 255.0)

## `#7C8695` — the dimmed half of a paired numeral: the ` / 12` after `WAVE 3`. One step below
## EYEBROW_TEXT, and a different colour from MUTED_TEXT despite three passes treating them alike.
const MUTED_TEXT_DIM := Color(0x7C / 255.0, 0x86 / 255.0, 0x95 / 255.0)

## `#DCE2EC` — the label on a PANEL_RAISED utility chip. Brighter than TEXT, because the chip
## fill is lighter than the bar behind it.
const CHIP_TEXT := Color(0xDC / 255.0, 0xE2 / 255.0, 0xEC / 255.0)

## `#A6B0BF` — a subtitle under a screen title, on open artwork (Team Select, Vault, Reward).
const SUBTITLE_TEXT := Color(0xA6 / 255.0, 0xB0 / 255.0, 0xBF / 255.0)

## `rgba(0,0,0,.36)` — the softer of the two blacks the mockups fill small pills with (Team
## Select's TIER pill, the intent badge's inner icon tile at .26). SHELF is .50 and reads heavier.
const SHELF_SOFT := Color(0, 0, 0, 0.36)
const SHELF_FAINT := Color(0, 0, 0, 0.26)


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


## A FRAME bar: a full-bleed band with a black rule on ONE edge and no shelf.
##
## Every other surface helper puts a border on all four sides via `set_border_width_all()`, which
## is right for an object sitting ON the page and wrong for a band that IS the edge of the page.
## The combat top bar, the combat deck bar and the meta-screen footer are all this shape — a bar
## with a shelf would read as floating above the screen, which is the opposite of what a frame
## does. This exists so those three stop hand-rolling the same StyleBoxFlat.
##
## `edge` is SIDE_TOP for a footer, SIDE_BOTTOM for a top bar.
static func frame_bar_style(edge: Side, kind: Surface = Surface.PANEL, width: int = 4,
		pad: Vector2 = Vector2(20, 0)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = surface_color(kind)
	sb.border_color = Color.BLACK
	match edge:
		SIDE_TOP: sb.border_width_top = width
		SIDE_BOTTOM: sb.border_width_bottom = width
		SIDE_LEFT: sb.border_width_left = width
		SIDE_RIGHT: sb.border_width_right = width
	sb.content_margin_left = pad.x
	sb.content_margin_right = pad.x
	sb.content_margin_top = pad.y
	sb.content_margin_bottom = pad.y
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
## This is the ONLY chip builder in the system now: one solid fill, black outline, ink chosen by
## `ink_on()`. The outlined dark pill it used to sit beside is deleted — see the note above.
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
## wash — see `solid_chip_style()`); a divider is the one place in the system a
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
## Letter-spacing, which Godot's `Label` has no property for.
##
## The v2 mockups set `letter-spacing` on nearly every display label — `.3em` on the turn
## banner's eyebrow, `.2em` on the meta section headings, `.14em` on the deck's rack header,
## down to `.01em` on titles. Dropping it is not a small loss: tracking is most of what makes
## an all-caps Baloo chip read as a game label instead of a squashed word, and until now the
## whole project dropped it silently on every screen.
##
## In CSS `letter-spacing` is em-relative; in Godot it is `FontVariation.spacing_glyph`, an
## integer count of PIXELS added after each glyph. So the conversion is `round(em * size)`, and
## it has to be redone per font size — which is why this is a function and not a constant.
##
## Godot also adds the spacing after the LAST glyph, where CSS does not. For a left-aligned
## label nobody can see the difference; for a centred one the text sits `em * size / 2` px left
## of true centre. At the sizes the mockups use that is at most ~2px, and correcting it would
## mean a trailing negative margin on every centred label — not worth the complexity, but
## written down here so the next person measuring a centred chip knows why it is off by one.
static var _tracked_fonts: Dictionary = {}

static func tracked_font(base: Font, tracking_em: float, size: int) -> Font:
	var px := int(round(tracking_em * float(size)))
	if px == 0:
		return base
	var key := "%s|%d" % [base.resource_path, px]
	if _tracked_fonts.has(key):
		return _tracked_fonts[key]
	var fv := FontVariation.new()
	fv.base_font = base
	fv.spacing_glyph = px
	_tracked_fonts[key] = fv
	return fv


## A display (Baloo 2) label at the mockup's own size, weight and tracking.
##
## `tracking_em` is the mockup's `letter-spacing` value verbatim: pass `.14` where the markup
## says `letter-spacing:.14em`, and 0 (the default) where it sets none. Do not pre-convert it
## to pixels — the conversion depends on `size` and is done here so one number in the mockup
## stays one number at the call site.
static func display_label(text: String, size: int, color: Color = TEXT,
		weight: int = 800, tracking_em: float = 0.0) -> Label:
	var font: Font = FONT_DISPLAY
	if weight == 700:
		font = FONT_DISPLAY_BOLD
	elif weight == 600:
		font = FONT_DISPLAY_SEMI
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_override("font", tracked_font(font, tracking_em, size))
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_constant_override("line_spacing", leading_for(font, size))
	return lbl


## Wraps a display Label so it takes up the mockup's LINE BOX instead of Baloo 2's font box.
##
## `line_spacing` fixes the SPACING BETWEEN lines and nothing else: Godot's `Label` still reports
## a minimum height of one full font box, and Baloo 2's font box is enormous — 61px at
## `font_size = 38`, against the 34px line the mockup draws. A `Label` is not a `Container`, so
## that 61 propagates straight up through every row it sits in, and the row grows by 27px that
## nothing in the design accounts for. On the die card this pushed the six-face track clean
## through the bottom of a fixed-height card; the same thing is waiting in every fixed-height row
## with a big numeral in it.
##
## `custom_minimum_size` cannot fix it (it is a floor, not a cap) and neither can a `Label`
## subclass (`Label` overrides `get_minimum_size()` in C++, so a GDScript `_get_minimum_size()`
## is never called). A `MarginContainer` with NEGATIVE vertical margins can: its minimum is the
## child's minimum plus the margins, and it lets the glyphs overhang the box exactly the way a
## CSS line box shorter than the font does.
##
## Use it wherever a display Label sits in a row whose height the design fixes. Where the row is
## free to grow, the plain label is fine.
static func line_box(lbl: Label, size: int, ratio: float = DISPLAY_LEADING) -> MarginContainer:
	var font: Font = lbl.get_theme_font("font")
	if font == null:
		font = FONT_DISPLAY
	var slack: float = font.get_height(size) - size * ratio
	var box := MarginContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if slack > 0.0:
		var top := int(floor(slack * 0.5))
		box.add_theme_constant_override("margin_top", -top)
		box.add_theme_constant_override("margin_bottom", -(int(ceil(slack)) - top))
	box.add_child(lbl)
	return box


## A prose (Work Sans) label at the mockup's own size, weight and tracking.
##
## Every body line in the v2 mockups is `font-weight:600` — the map subtitle, relic and reward
## descriptions, the merchant quote, event copy, the Result seed line, the shard breakdown, the
## XP line. The project theme's default `Label` font is `FONT_UI`, which is WorkSans-**Medium**
## (500), and no file in the codebase referenced `FONT_UI_SEMI` at all until now. So every
## paragraph in the game has been rendering a weight lighter than the design, everywhere, in a
## way that reads as "slightly washed out" rather than as a bug — which is why it survived three
## redesign passes. Route body copy through here and that stops being possible to forget.
##
## `weight` is the mockup's own number: 500, 600 (the default, because that is what the mockups
## overwhelmingly use) or 700. `tracking_em` is its `letter-spacing`, verbatim.
static func prose_label(text: String, size: int, color: Color = TEXT,
		weight: int = 600, tracking_em: float = 0.0) -> Label:
	var font: Font = FONT_UI_SEMI
	if weight == 500:
		font = FONT_UI
	elif weight == 700:
		font = FONT_UI_BOLD
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_override("font", tracked_font(font, tracking_em, size))
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	return lbl


## The same tracking, applied to a Label or Button that already exists — for the cases where a
## widget is built by a helper (`style_button()`, a `.tscn` node) and only needs its spacing
## corrected afterwards.
static func apply_tracking(node: Control, tracking_em: float, size: int,
		weight: int = 800) -> void:
	if tracking_em == 0.0:
		return
	var font: Font = FONT_DISPLAY
	if weight == 700:
		font = FONT_DISPLAY_BOLD
	elif weight == 600:
		font = FONT_DISPLAY_SEMI
	node.add_theme_font_override("font", tracked_font(font, tracking_em, size))
	node.add_theme_font_size_override("font_size", size)



# ═══════════════════════════════════════════════════════════════════════════════════════════
# SCREEN LAWS — FIX-PASS-01 §1
# ═══════════════════════════════════════════════════════════════════════════════════════════
#
# These are NOT in the v2 handoff, and that is exactly why the first build missed them. The
# handoff redlined ELEMENTS and never wrote down the laws governing the SCREEN those elements
# sit on, so the build ended up with widgets that each match their redline and screens that are
# collectively wrong — panels anchored to the viewport with 400px of empty fill under a short
# list, lists sliced by the bottom edge with no scrollbar, a BACK button floating on the art.
#
# Each law below is stated where it can be enforced in code. The ones that cannot be (a screen
# must still choose to top-align a short list) are stated as constants and comments so a future
# screen has something to read.

## L1 · SAFE AREA. 48px on all four sides. Nothing is positioned, anchored or clipped outside
## it. Combat's top bar and bottom deck are the only full-bleed objects in the game.
##
## Left and right may stay at the 84px the screens already use — that is a wider margin, not a
## violation. The BOTTOM is the one that was being treated as 0, and that is where every
## clipped row in the build came from.
const SAFE_AREA := 48.0
const SAFE_AREA_SIDE := 84.0

## L2 · A screen either FITS or SCROLLS — never both empty and clipped. If the content fits, the
## container hugs it and the region is TOP-ALIGNED, leaving honest empty artwork below. Empty
## painted background is fine; empty PANEL is not. If it does not fit: ScrollContainer,
## `clip_contents = true`, and a bar the player can actually see — see `style_scrollbars()`.
const SCROLLBAR_THICKNESS := 10.0
const SCROLL_FADE_HEIGHT := 24.0

## L4 · FOOTER. `BACK` never floats on the art. Every meta screen gets one shared footer bar.
const FOOTER_HEIGHT := 72.0
const FOOTER_BUTTON_MIN_HEIGHT := 44.0

## L8 · TYPE FLOOR. 12px absolute minimum, and 12 ONLY for an all-caps chip label. Body captions
## are 13. Anything a player reads mid-combat is 15 or more.
const TYPE_MIN := 12
const TYPE_CAPTION := 13
const TYPE_COMBAT_MIN := 15


## L4 · The one footer, built once and called from every meta screen (Pass, Unlocks, Guides,
## Vault, Codex, Settings).
##
## It is FRAME, not an object: a full-width bar with a black top border only and NO shelf. A
## shelf would make the page frame look like it floats above the page, which is the opposite of
## what a frame is for.
##
## Returns the HBoxContainer inside it. `BACK` is already added at the left; add a screen's
## primary action to the right of the same bar and it will sit correctly. The content region
## above must stop at `-(SAFE_AREA + FOOTER_HEIGHT)`.
static func build_footer(host: Control, back_text: String = "BACK") -> HBoxContainer:
	var bar := PanelContainer.new()
	bar.name = "Footer"
	var sb := surface_style(Surface.PANEL, 0, 0, 0.0, Vector2(SAFE_AREA_SIDE, 12))
	sb.border_color = Color.BLACK
	sb.border_width_top = 3
	bar.add_theme_stylebox_override("panel", sb)
	bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_top = -(SAFE_AREA + FOOTER_HEIGHT)
	bar.offset_bottom = -SAFE_AREA
	host.add_child(bar)

	var row := HBoxContainer.new()
	row.name = "FooterRow"
	row.add_theme_constant_override("separation", 12)
	bar.add_child(row)

	var back := Button.new()
	back.name = "BackButton"
	back.text = back_text
	back.custom_minimum_size.y = FOOTER_BUTTON_MIN_HEIGHT
	style_button(back, false)
	row.add_child(back)

	var spacer := Control.new()
	spacer.name = "FooterSpacer"
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	return row


## L5 · ONE LOUD STATE PER LIST. In any repeated list, at most one state carries a saturated
## fill; the others step down this ladder.
##
## This is not a styling preference. A Pass screen that paints "claimed" and "claimable" the
## same green is not ugly — it is telling the player something false, and the audit called that
## out as wrong INFORMATION rather than wrong style. On a maxed-out pass the screen should be
## mostly calm cream with the few unclaimed tiles standing out.
enum ListState {
	ACTIONABLE,    # do this now — the one loud fill
	DONE,          # already claimed / already owned
	UNAFFORDABLE,  # available, but you cannot pay for it yet
	LOCKED,        # not yet reachable
}


## The fill for a list row/tile in `state`. `accent` is the loud colour for ACTIONABLE, which
## differs per screen (SUCCESS for a Pass tile, PRIMARY for a shop price).
static func list_state_fill(state: ListState, accent: Color = SUCCESS) -> Color:
	match state:
		ListState.ACTIONABLE: return accent
		ListState.DONE: return CREAM_TRACK
		ListState.UNAFFORDABLE: return DISABLED_FILL
		_: return WELL


## The ink that goes on `list_state_fill()`. Never dims — under the DISABLED rule an
## unaffordable row keeps its price at FULL strength, because the price is the whole reason
## that row is on screen.
static func list_state_ink(state: ListState, accent: Color = SUCCESS) -> Color:
	match state:
		ListState.ACTIONABLE: return ink_on(accent)
		ListState.DONE: return INK_ON_CREAM_MUTED
		ListState.UNAFFORDABLE: return TEXT
		_: return FAINT_TEXT


## The whole box for a list row/tile in `state`, outlined and shelved per L7.
static func list_state_style(state: ListState, accent: Color = SUCCESS,
		radius: int = 12, shelf: float = 4.0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = list_state_fill(state, accent)
	sb.border_color = Color.BLACK
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 12.0
	sb.content_margin_right = 12.0
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 8.0
	if shelf > 0.0 and state != ListState.LOCKED:
		# A LOCKED row is a hole in the page, not an object sitting on it, so it gets no shelf.
		sb.shadow_color = SHELF
		sb.shadow_size = 0
		sb.shadow_offset = Vector2(0, shelf)
	return sb
