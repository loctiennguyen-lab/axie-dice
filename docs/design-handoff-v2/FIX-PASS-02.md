# FIX-PASS-02 — root causes, not symptoms

Written 2026-09-20 after reading the actual GDScript in `godot/`, not just the QA screenshots.
**This file replaces FIX-PASS-01.** FIX-PASS-01 was written from screenshots; it described
symptoms, and it got symptom-shaped fixes that made the build worse in places. Everything below
is traced to a line of source.

Do §1 before anything else. §1 and §2 together remove most of what §5 lists.

---

## 0. Why the last pass did not work — five root causes, with proof

### RC1 · The window is not 1920×1080, so every redline lands in the wrong place

`project.godot`:

```
window/size/viewport_width=1920
window/size/viewport_height=1080
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"      # ← this
```

`aspect="expand"` does not letterbox. On the reporter's window (≈2387×1540, a 1.55 aspect) Godot
keeps the horizontal scale and **grows the logical viewport vertically**: the game is laid out in
roughly **1920 × 1238** logical pixels, not 1920 × 1080.

Every consequence in the screenshots follows from this:

- ~158 logical px of dead space appear in the middle and bottom of every screen — the empty band
  between the enemy rank and the party in Combat, and a large part of the "empty panel" in Pass
  and Guides that FIX-PASS-01 blamed entirely on panel anchoring.
- Anything anchored to the bottom moves down 158px relative to everything positioned by an
  absolute `offset_top` taken from a 1080-tall redline. The two halves of a screen drift apart.
  This is the "text lệch khung" being reported: the redlines are correct and the canvas is not.
- Screens are unreproducible: the layout differs on every window size, so a fix that looks right
  in one window is broken in another, and QA captures do not match what the reporter sees.

**Fix — keep `expand`, and make the screens actually use the canvas.**

Do **not** switch to `aspect="keep"`. Letterboxing would throw away real screen width and leave
black bars on a wide monitor. `expand` stays. What has to change is the assumption underneath
every screen: **1920×1080 is the MINIMUM canvas, not the design canvas.** No screen may compute a
position from a hardcoded 1920 or 1080 again.

Three mechanical rules that make `expand` safe:

1. **Full-bleed bands anchor to the real viewport edges.** The Combat top bar, the deck bar and
   the footer use `PRESET_TOP_WIDE` / `PRESET_BOTTOM_WIDE`, never an absolute y.
2. **Body content lives in a centred max-width column,** so extra width becomes margin instead of
   stretched text:
   ```gdscript
   const CONTENT_MAX := 1800.0
   var col_w: float = minf(canvas.x - RAIL_X * 2.0, CONTENT_MAX)
   # centre it: content.offset_left = (canvas.x - col_w) * 0.5, offset_right = -that
   ```
3. **Anything that used an absolute y from a 1080 redline is re-expressed as a top offset inside
   `content`** (§2), which is already inset by the safe area. A redline's `offset_top = 202`
   stays 202 — but 202 *from the top of `content`*, not from the top of a canvas whose height
   nobody controls.

Regions that must *fill* rather than sit at a fixed size: the Run Map graph (§6b), the Combat
stage, and every modal (§6c). They read `get_viewport_rect().size` at layout time and on
`resized`, and lay out in normalised 0..1 space scaled into that rect.

**Nothing else in this file can be verified until this is done.** Re-capture all QA screens at two
different window sizes; both must be correct, and neither may clip or leave a void.

### RC2 · Two surface systems are live at once

`DangoTheme.gd` ships both the v1 API and the v2 API, and the combat HUD never left v1:

```gdscript
# UnitPortrait.gd:_ready()
_base_style      = DangoTheme.panel_style(DangoTheme.BG_PANEL_SOFT, 2, 8, 5.0)  # 0.55 alpha, 2px border
_selected_style  = DangoTheme.panel_style(DangoTheme.BG_PANEL, 3, 8, 5.0)
_selected_style.shadow_size = 8                                                  # a BLURRED shadow

# UnitHeadHUD.gd:_init()
_intent_style = DangoTheme.panel_style(Color(0.04, 0.04, 0.06, 0.9), 2, 8, 5.0)  # hand-picked literal
_intent_style.border_color = col                                                 # not black
```

That is three v2 laws broken in four lines: a translucent fill instead of an opaque surface, a
2px non-black border, and `shadow_size = 8` — the blurred drop shadow the entire v2 pass exists
to delete. The meta screens use `surface_style()`; the combat HUD uses `panel_style()`. That
split *is* the "half the game still looks like the old dashboard" complaint.

Telling anyone to "apply the outline and shelf" cannot work while the old API is still callable.

**Fix — delete the v1 API from `DangoTheme.gd`:**

```gdscript
# DELETE these three:
const BG_PANEL      := Color(...)
const BG_PANEL_SOFT := Color(...)
static func panel_style(...) -> StyleBoxFlat
```

The compile errors are the deliverable. Every call site moves to `surface_style()`. Then:

```bash
rg 'panel_style\(|BG_PANEL|shadow_size = [1-9]' godot/    # must return ZERO hits
```

`shadow_size` may only ever be `0`. A shelf is `shadow_size = 0` + `shadow_offset = Vector2(0, n)`.

### RC3 · Symptom-scoped wording produced symptom-scoped fixes

FIX-PASS-01 said *"Enemy nameplates are half size."* `UnitPortrait.gd` now reads:

```gdscript
const WIDTH := 132.0
const ENEMY_WIDTH := 176.0
const ENEMY_MIN_HEIGHT := 64.0
## ...Party nameplates are unchanged — C1 is enemy-only, and the party row already reads
## correctly at its current size.
```

The party plates were left at 132px with ~11px text, and their width still comes from *measured
text*, so five party members produce five different plate widths. Combined with a shield badge
that is positioned relative to that measured width, `Pomodoro 14/14` is now literally cut in half
by its own shield pill. The fix made the screen worse than before it.

**Rule for this pass:** every instruction below states what it applies to, exhaustively. Where a
rule says *every*, it means every — party and enemy, all six meta screens, all ten Codex tabs. If
an instruction seems not to apply somewhere, it applies; ask instead of scoping it down.

### RC4 · Coverage was whatever I had screenshotted

`Codex.gd` is 40 lines and contains **no reference to `DangoTheme` at all**. No plate, no scrim,
no safe area, no title, stock `Button` tabs, and a single `RichTextLabel` with `fit_content` and
no width cap, carrying hardcoded colours (`#ffd76a`, `#f4f0ff`) and BBCode `[table=2]` for layout.
It renders on flat engine grey with 2300px line lengths. It was never touched by any pass because
it was not in my list.

§4 is a complete inventory of every scene in the repo. Nothing is omitted, so nothing can be
skipped for not being mentioned.

### RC5 · The project Theme does not cover stock widget classes

`project.godot` sets `theme/custom="res://resources/theme/dango.tres"`, generated by
`tools/gen_theme.gd`. But the generated theme evidently does not define defaults for `Button`,
`OptionButton`, `TabBar`, `RichTextLabel`, `ScrollBar`, `LineEdit` or `CheckBox` — which is why
the Codex tab row and the Vault's `Olek (Plant)` dropdown render as stock Godot widgets on screens
where nobody called `style_button()` by hand.

**Fix:** extend `gen_theme.gd` so every one of those classes has a default StyleBox and font size
drawn from `DangoTheme`. An unstyled widget must be visually impossible, not merely discouraged.
Regenerate and commit `dango.tres` in the same change:

```bash
godot --headless --path godot --script tools/gen_theme.gd
```

---

## 1. Do these four things first, in this order

1. `window/stretch/aspect="keep"` in `project.godot`.
2. Delete `panel_style()`, `BG_PANEL`, `BG_PANEL_SOFT`; fix every compile error with
   `surface_style()`; assert `shadow_size` is 0 everywhere.
3. Extend `gen_theme.gd` per RC5 and regenerate `dango.tres`.
4. Add `DangoTheme.build_screen()` (§2) and route **every** scene through it.

Then re-capture all QA screens. Only after that, work §5.

---

## 2. `build_screen()` — the shell every scene must use

Add to `DangoTheme.gd`. No scene may position anything against the raw viewport again.

```gdscript
const SAFE := 48.0          # every edge, every screen
const FOOTER_H := 72.0
const RAIL_X := 84.0        # left/right content inset on meta screens

## Builds plate → scrim → content → footer and returns the two Controls a screen fills in.
## `content` is already inside the safe area and above the footer; anchor children to IT,
## never to the scene root. `footer` is null when `with_footer` is false (Combat, Main Menu).
static func build_screen(host: Control, plate: Texture2D, kind: Scrim = Scrim.DEFAULT,
		with_footer: bool = true, combat: bool = false) -> Dictionary:
	var plate_host := Control.new()
	plate_host.name = "PlateHost"
	plate_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.add_child(plate_host)
	build_plate(plate_host, plate, kind, combat)

	var footer: HBoxContainer = null
	if with_footer:
		var bar := PanelContainer.new()
		bar.name = "Footer"
		bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		bar.offset_top = -FOOTER_H
		var sb := surface_style(Surface.PANEL, 0, 0, 0.0, Vector2(RAIL_X, 14))
		sb.border_color = Color.BLACK
		sb.border_width_top = 3          # frame: top rule only, no shelf
		bar.add_theme_stylebox_override("panel", sb)
		host.add_child(bar)
		footer = HBoxContainer.new()
		footer.name = "FooterRow"
		footer.add_theme_constant_override("separation", 12)
		bar.add_child(footer)

	var content := Control.new()
	content.name = "Content"
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = RAIL_X
	content.offset_right = -RAIL_X
	content.offset_top = SAFE
	content.offset_bottom = -(SAFE + (FOOTER_H if with_footer else 0.0))
	host.add_child(content)
	return {"content": content, "footer": footer}


## The BACK button. Always the first child of the footer. Never anywhere else.
static func add_back_button(footer: HBoxContainer, on_press: Callable) -> Button:
	var b := Button.new()
	b.name = "BackButton"
	b.text = "BACK"
	b.custom_minimum_size = Vector2(120, 44)
	style_button(b, false)
	b.pressed.connect(on_press)
	footer.add_child(b)
	return b


## Wraps `inner` so it hugs its content and scrolls only when it genuinely overflows `max_h`.
## This is the fix for "a 5-row grid in a panel anchored to the bottom of the screen".
static func fit_or_scroll(inner: Control, max_h: float) -> Control:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.clip_contents = true
	scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	scroll.custom_minimum_size.y = minf(inner.get_combined_minimum_size().y, max_h)
	style_scrollbars(scroll)
	scroll.get_v_scroll_bar().custom_minimum_size.x = 10   # style_scrollbars alone leaves it invisible
	scroll.add_child(inner)
	return scroll
```

Rules that follow from this and are not negotiable:

- A scene calls `build_screen()` as the **first** statement of `_ready()`.
- No `set_anchors_preset(PRESET_BOTTOM_LEFT)` anywhere outside `build_screen()`.
- No `anchor_bottom = 1.0` on a content panel. Height comes from the content; the cap comes from
  `fit_or_scroll()`.
- Empty painted background below a short list is the correct result. Empty *panel* is not.

---

## 3. The nameplate — one component, one size, no exceptions

`UnitPortrait.gd`. This replaces `WIDTH` / `ENEMY_WIDTH` / measured-text sizing entirely.

```gdscript
const PLATE := Vector2(196, 64)   # EVERY nameplate: party and enemy, identical
```

- Fixed 196×64. **Delete the measured-text width logic and `set_width_cap()`.** Variable widths
  are the cause of the current clipping; five plates in a row must be five identical rectangles.
- Name label: `clip_text = true`, `text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS`,
  17px `FONT_DISPLAY_BOLD`, expands. HP label: 15px `FONT_DISPLAY_BOLD`, shrink-end, min 12px gap
  from the name. A long name ellipsises; it never pushes the HP number out of the plate.
- Surface: `surface_style(Surface.PANEL_DEEP, 10, 3, 4.0, Vector2(10, 6))`. Selected state changes
  `border_color` to `PRIMARY` and nothing else — no `shadow_size`, no geometry change.
- Class dot 10px at the left of the header row.
- HP bar 14px, full plate width, trough `WELL_DEEP`, fill `hp_color(pct)`.
- **Shield badge:** stop positioning it relative to measured width. Anchor it outside the plate's
  top-right corner — `position = Vector2(PLATE.x - 18, -12)`, added as a sibling *after* the card
  so it draws on top. With a fixed plate width it can no longer overlap the HP number.
- Status row: below the HP bar, inside the plate; the plate grows to 64 + 22 per status row.
  It may not break the plate's outline, which it currently does on Machito.

`UnitHeadHUD.gd`: `WIDTH = 196` to match. Badge surface becomes
`surface_style(Surface.PANEL_DEEP, 8, 3, 4.0, Vector2(8, 3))` with a **black** border; the intent
type colour goes on the *icon and the number*, not on the border. Drop
`_intent_number`'s `Color.WHITE` + `outline_size = 3` — on an opaque `PANEL_DEEP` plate the text
outline is doing nothing except making 22px type look muddy.

---

## 4. Scene inventory — every scene, with required action

`R` = rebuild against §2, `F` = fix listed defects, `V` = verify only after §1.

| Scene | State | Action |
| --- | --- | --- |
| `codex/Codex.gd` + `CodexContent.gd` | **never styled** — no `DangoTheme` reference | **R** — see §5 |
| `settings/SettingsView.gd` | never reviewed | **R** |
| `tutorial/TutorialView.gd` | never reviewed | **R** |
| `combat/InfoPanelView.gd` | never reviewed; shares Codex BBCode | **R** |
| reward / shop / event / treasure overlays (in `RunMapController.gd`) | never reviewed | **R** |
| `combat/CombatView.gd` + `Combat.tscn` | partial | **F** §6 |
| `shared/UnitPortrait.gd`, `UnitHeadHUD.gd` | v1 surfaces | **F** §3 |
| `run_map/RunMapController.gd` | partial | **F** (FIX-PASS-01 §2.2 R1–R7 still open) |
| `result/ResultView.gd` | partial | **F** (FIX-PASS-01 §2.3 S1–S6 still open) |
| `main_menu/MainMenu.gd` | partial | **F** (M1–M5) |
| `main_menu/TeamSelect.gd` | close | **F** (T1–T3) |
| `pass/PassView.gd` | partial | **F** (P1–P4) via `fit_or_scroll` |
| `unlocks/UnlocksView.gd` | partial | **F** (U1–U4) via `fit_or_scroll` |
| `vault/VaultView.gd` | partial | **F** (V1–V5) |
| `guides/GuidesView.gd` | partial | **F** (G1–G4) |
| `shared/HPBar.gd`, `TargetLinesLayer.gd`, `BattleBackdrop.gd` | — | **V** |
| `dev_review/` | internal tool | skip |

A scene marked **R** gets: `build_screen()`, an eyebrow chip + display title at the top of
`content`, its body inside `fit_or_scroll()`, and `add_back_button()` in the footer. Nothing else
invented.

---

## 5. Codex rebuild (`Codex.gd`, `CodexContent.gd`)

This screen is currently the worst in the build and needs the most direction.

1. `build_screen(self, load(BG), Scrim.DEFAULT, true)`. Eyebrow `EVERY RULE, NOTHING HIDDEN`,
   title `CODEX` at 56px `display_label`. Delete the `"CODEX  -  every rule..."` string that is
   currently prepended to the body text.
2. Tab row: `style_button(b, false)` on each; selected tab uses `primary_button_style()` with
   `INK_ON_PRIMARY`. Min height 44. Wrap in an `HFlowContainer` — ten tabs must wrap, not run off
   the edge.
3. Body panel: `surface_style(Surface.PANEL, 18, 4, 7.0, Vector2(28, 24))`, **`max_width 1100`**,
   centred in `content`. 2300px lines are the single biggest reason the screen is unreadable.
4. `RichTextLabel` → keep, but:
   - `fit_content = true` inside `fit_or_scroll(body, content_height)`.
   - Delete `const _H := "[b][color=#ffd76a]%s[/color][/b]\n"`. Section headings use `PRIMARY`
     (`#FF9345`) via a colour pushed from `DangoTheme`, not a hardcoded gold that exists nowhere
     else in the design.
   - Delete the `#f4f0ff` literal.
   - Body text 16px `FONT_UI`, line spacing 6, `TEXT`. Headings 20px `FONT_DISPLAY_BOLD`.
5. **Replace `_table()`'s BBCode `[table=N]` with a real `GridContainer`.** The current output is
   the misaligned `4 - END TURN Enemies act out…` run-together column in the screenshot. Two
   columns: left fixed 180px `FONT_DISPLAY_SEMI` 15px `CAPTION_MUTED`, right expanding 16px
   `FONT_UI` `TEXT`, row separation 10, a 1px `primary_divider_alpha()` rule between rows.
6. `InfoPanelView.gd` consumes the same content — apply 4 and 5 there too, or the in-combat panel
   keeps the old rendering.

---

## 6. Combat composition (`CombatView.gd`, `Combat.tscn`)

After §1 the vertical dead band shrinks on its own. Then:

- **Die cards are clipped by the bottom edge.** The deck must be a bottom-anchored bar of fixed
  height 196 with the cards' bottom at `-24` inside it. Nothing in the deck may be positioned by
  an absolute y computed from the viewport height.
- **Die-card headers are now washed-out pastels.** The last pass desaturated the class colour to
  fix the white-text contrast. That breaks *"colour is a solid fill, never a tint"*. Restore the
  full-strength `class_color(cls)` fill and set the label to `ink_on(class_color(cls))`.
- **Mana + relic actives are still two floating v1 panels.** One `DECK` bar, full width: mana at
  the left end, relic actives at the right, cards centred. Empty relic slots are `WELL` squares
  with a black 3px border, not black holes.
- **The wave track is still a raw stripe bar** and at Wave 1 it reads as a broken progress bar.
  `WELL_TRACK` trough, radius 8, black 3px; pips `CREAM_TRACK` / `CREAM_HI` / `FUTURE` / `DANGER`.
  Pip width is derived from the wave count, with a minimum of 8px and a 4px gap.
- **The front line is a 1px grey hairline.** 3px, black at 55%, inset to the party bounding box
  +80px, no end caps.
- `Undo / Info / Log / Sound / Quit`: min height 44 (currently ~32), 15px display labels.

---

## 6b. Run Map — the graph does not fill its region (`RunMapController.gd`)

Latest capture: the whole node graph sits in the upper-left third of the canvas; the bottom half
and the right quarter of the screen are empty art. This is not a taste problem, it is the same
absolute-coordinate bug as everywhere else — node positions are computed from a 1920×1080
assumption and then drawn into a canvas that is taller (RC1) and wider than the graph needs.

The graph must be **laid out in normalised space and then fitted to its region**:

```gdscript
# region = the Control returned by build_screen(), minus the 344px rail and a 48px gutter
var region := Rect2(RAIL_W + 48, 0, content.size.x - RAIL_W - 48, content.size.y)
# 1. place nodes in 0..1 space: x = col / (cols - 1), y = row / (rows_visible - 1)
# 2. map to region with a 64px inset so tokens and labels never touch an edge
# 3. NODE = 132x132 (was ~100); token radius 14, black 4, shelf 5, all three NODE_TONES bands
```

Also still open from FIX-PASS-01 §2.2 and visible in the latest capture:

- **R2** — tokens are still single-tone. `node_tone()` returns three colours; only `[0]` is used.
  No top block, no lip, so every node reads as a flat sticker.
- **R3** — the axie head still bleeds out from behind the merchant token. Clip node art to the
  token rect.
- **R5** — over-corrected: edges went from 10px railway to a 2px dotted hairline. 4px, black 70%,
  dash 10/8; the edge into the current node is `PRIMARY`.
- **New** — the `YOU ARE HERE` chip overlaps the node directly below it. It belongs *inside* the
  current token's bottom edge, or the row gap must be ≥ chip height + 16.
- **New** — `SAVE & QUIT` is now inside the rail (correct), but the rail ends at y≈1040 while the
  screen continues; after RC1 this resolves, so re-check rather than re-tuning it by hand now.

---

## 6c. Modals and overlays — reward / shop / event / treasure

From the `CHOOSE A REWARD` capture. These overlays live in `RunMapController.gd` and were never
in any previous pass.

**The modal is a fixed ~770px column on a canvas over 2300px wide.** Every reward description
wraps to three or four lines inside a narrow box while 60% of the screen sits empty. Width must
be fitted to the canvas:

```gdscript
var w: float = clampf(get_viewport_rect().size.x * 0.55, 900.0, 1280.0)
```

Then the row layout stops fighting for space: art tile 96×96 fixed, text column expanding,
`TAKE` fixed at 160×56. Most descriptions become one or two lines.

- **The three `TAKE` buttons are different heights** because they stretch to their row. Fix at
  56px, `SIZE_SHRINK_CENTER` vertically. A button that changes size per row reads as three
  different buttons.
- **Four competing oranges:** three `TAKE` buttons plus a full-width orange `REROLL`. `TAKE` is
  the primary action and stays `PRIMARY`; `REROLL (1 left)` becomes `secondary_button_style()`.
  Per §L5 of FIX-PASS-01, one loud state per list.
- **Rarity chips are outline-only pills.** `COMMON` / `UNCOMMON` / `LEGENDARY` must be
  `solid_chip_style(rarity_color(rar))` with `ink_on()` — the same chip the Result screen and the
  shop use. Right now rarity is the most important information on the screen and the weakest mark
  on it.
- **The dim behind the modal takes the chrome down with it.** The rail, the boss ribbon and
  `SAVE & QUIT` are dimmed to unreadable. Dim the *map layer only*, or drop the overlay's own
  scrim to `SCRIM_INK` at 0.55 and leave the chrome at full strength.
- **The modal has no outline or shelf** while every card behind it does:
  `surface_style(Surface.PANEL, 18, 5, 8.0, Vector2(24, 22))`.
- Reward-row surfaces are `WELL`, not a second `PANEL` — a row holds something, it is not a plate.

Apply the same six points to the shop, event and treasure overlays; they share this code path.

---

## 7. Make the laws testable — `godot/tests/t_ui_laws.gd`

`t_button_states.gd` already proves this project can assert on StyleBoxes. Add a test that walks
every scene in §4 and fails on:

1. Any `StyleBoxFlat` with `shadow_size != 0`.
2. Any `StyleBoxFlat` with a non-black, non-`PRIMARY` `border_color` (PRIMARY is legal only as a
   selection state).
3. Any `Label`/`RichTextLabel` with an effective font size < 12, or < 15 inside `Combat.tscn`.
4. Any `Control` whose global rect falls outside the 48px safe area of a 1920×1080 viewport.
5. Any `Button` named `BackButton` whose parent is not a `Footer`.
6. Any `Color.WHITE` font colour on a node whose parent StyleBox fill is `PRIMARY` or a class
   colour.
7. A scene root with no `PlateHost` child.

Run it in `tools/ci.mjs`. A rule that is not asserted will drift back within two passes — that is
demonstrably what happened between FIX-PASS-01 and now.

---

## 8. Definition of done

Re-capture **every** screen in §4 at 1920×1080 and check:

- [ ] `rg 'panel_style\(|BG_PANEL|shadow_size = [1-9]' godot/` → zero hits.
- [ ] `rg '1920|1080' godot/scenes/` → no hit is a layout position. Two captures at different window sizes are both correct: no clipping, no void, content column centred.
- [ ] Every modal is width-fitted to the canvas (§6c), not a fixed 770px column.
- [ ] Every scene root has `PlateHost`; no scene renders on engine grey.
- [ ] Every `BACK` is inside a footer bar; none sits on art.
- [ ] All five party nameplates and all enemy nameplates are the same 196×64 rectangle; no name or HP number is clipped, ellipsised-with-room-left, or overlapped by a shield badge.
- [ ] No white text on `PRIMARY` or on a class colour; no class colour rendered as a pastel tint.
- [ ] No text below 12px anywhere; nothing below 15px in Combat.
- [ ] No scrollable region without a visible 10px scrollbar; no row clipped by a screen edge.
- [ ] No panel with more than ~80px of empty fill below its last child.
- [ ] Codex: 1100px measure, real grid tables, orange headings, title and footer present.
- [ ] `t_ui_laws.gd` passes.

If any item cannot be met, stop and report which one and why, rather than scoping the rule down
to the part that was easy. The last pass scoped `C1` to enemies only and shipped a regression.
