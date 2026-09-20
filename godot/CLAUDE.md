# UI rules — read before touching any file under `godot/scenes/`

These are not suggestions and they are not per-task. They hold for every UI change in this repo.

## The source of truth is the mockups, not a prose spec

**The design source of truth is the four HTML mockups in `docs/design-handoff-v2/mockups-v2/`:**

| File | Screens |
| --- | --- |
| `combat-v2.html` | Combat |
| `run-flow-v2.html` | Run Map · Reward · Shop · Event · Treasure · Result |
| `meta-screens-v2.html` | Main Menu · Team Select · Vault · Pass · Unlocks · Guides · Codex |
| `handoff-spec-v2.html` | background/token notes — **NOT normative**, see below |

Read the numbers out of the mockup's own markup. A width in the HTML is the width; a gap is the
gap. Do not re-derive them from a prose restatement, and do not round them.

**The mockups own numbers; they do not own positions** (user decision, 20 Sep 2026, revised
that evening). Read a width, height, padding, radius, border, gap, font size or colour straight
out of the markup and type it in as drawn. Do **not** read a y coordinate out of one: the canvas
is `expand`, so a 1080-tall mockup is the minimum canvas and an absolute `top:` copied from it
lands somewhere else on a real window. Positions are expressed as relationships — see rule 2.

`docs/design-handoff-v2/FIX-PASS-03.md` is **normative for behaviour**: the ten global laws
(L1–L10), the four global changes (G-01–G-04), the per-screen item IDs, and the rule that every
item states its complete "applies to" set. Quote its IDs in commits. Where it gives a number
that a mockup also gives, the mockup wins; where it states a law, a relationship or a scope, it
wins. `FIX-PASS-01.md`, `FIX-PASS-02.md`, `FIX-PASS-02-START-HERE.md`, `consistency-sweep.md`
and `UI-LAWS-BASELINE.md` are **historical** — read them for the reasoning behind a past
decision, never for what a screen should look like.

**Where `handoff-spec-v2.html` disagrees with a screen mockup, the screen mockup wins**
(user decision, 20 Sep 2026). Known disagreements, all resolved in the mockup's favour:
the party column pitch (spec §03 says 212+16; `combat-v2.html` draws 180+14), the deck height
(spec §01 says 296; the mockup draws 216), and the stage band offsets in spec §01. Those spec
numbers are from an earlier iteration.

---

## The six rules that keep being broken

**1 · One surface API.** `DangoTheme.surface_style()` and nothing else.
`panel_style()`, `BG_PANEL`, `BG_PANEL_SOFT` are deleted. `shadow_size` is **always 0** — a shelf
is `shadow_size = 0` + `shadow_offset = Vector2(0, n)`. Borders are **pure black**. No
hand-picked `Color(0.04, 0.04, 0.06, 0.9)` literals: if a fill is not in `DangoTheme`, it does
not exist. When a mockup uses a colour `DangoTheme` has no name for, add the token — do not
inline the hex.

**2 · 1920×1080 is the MINIMUM canvas, not the design canvas.** `window/stretch/aspect="expand"`
as of 20 Sep 2026. `expand` does not letterbox: it keeps the horizontal scale and grows the
logical viewport vertically, so a 2387×1540 window lays out in roughly 1920×1238. An absolute
`offset_top` copied off a 1080-tall mockup is therefore **wrong**, and it is wrong differently on
every window. Three mechanical rules make this safe:

- **Full-bleed bands** — the combat top bar, the combat deck, the meta footer — anchor to a real
  viewport edge (`PRESET_TOP_WIDE` / `PRESET_BOTTOM_WIDE`), never to an absolute y.
- **Everything else lives in the content column** that `DangoScreen.build()` returns, already
  inset by the safe area and above the footer, centred at `min(viewport_w − 2×84, max_w)`.
  Extra width becomes margin, never stretch.
- **Blocks stack by relationship**, the way FIX-PASS-03 words them: "28px below the party row",
  "immediately right of the node chip". A band's own height and its gap to its neighbour are
  mockup numbers; where the stack starts is not.

Regions that must *fill* rather than sit at a fixed size — the Run Map graph, the combat stage,
every modal — read `get_viewport_rect().size` at layout time **and on `resized`**, lay out in
normalised 0..1 space, and fit into the region (`DangoScreen.fit_points()`,
`DangoScreen.modal_width()`). Vertical slack goes to the bottom: a screen whose content fits is
top-aligned with honest empty artwork below it. Empty painted background is fine; empty *panel*
is not.

`rg '\b1920\b|\b1080\b' scenes/` must not return a layout position.

**3 · A screen either fits or scrolls.** The mockups are all one 1080-tall screen with nothing
clipped, so at the minimum canvas a screen that needs a scrollbar is laid out wrong before the
scrollbar is. Taller windows only add slack, never take it away, so this holds at every size. A
row clipped by the screen edge with no visible scrollbar is the worst defect this project has
shipped — cap with `DangoScreen.fit_or_scroll()`, which hugs its content and scrolls only on a
genuine overflow.

**4 · Ink on fill, never white on colour.** Any text on `PRIMARY`, a class colour or a rarity
colour goes through `DangoTheme.ink_on(fill)`. Never fix a contrast failure by desaturating the
fill into a pastel — colour is a solid fill, never a tint. Never fix it by darkening a background
plate either; put the text on its own plate instead.

**5 · Type comes from the mockup.** Baloo 2 for every title, button label, chip label and
**every numeral**. Work Sans for prose only — log lines, passive text, item descriptions, event
copy. No per-`Label` font overrides; it all resolves through the one Theme. Use the size the
mockup uses, including where that is 9px or 11px — the old 12px project floor does not override
a mockup number.

**6 · A colour block never stands alone for a mechanic.** Any swatch encoding a die face type,
status, intent or relic slot carries that mechanic's glyph inside it, as the mockups draw it.
Build it with `DangoTheme.type_swatch()` — not inline, which is how three screens drifted apart.
Rarity and class swatches are exempt: those are identities, not mechanics.

---

## Asset paths

The mockups reference assets under names this repo does not use (`assets/fx/dmg.png`,
`assets/part/back-plant.svg`, `assets/bg/deep-forest.jpg`). **Every one of them exists here** —
only the folder naming differs. Translate with `MockupAssets` (`scenes/shared/MockupAssets.gd`)
and never by hand:

| In a mockup | In this repo |
| --- | --- |
| `assets/fx/<n>.png\|svg` | `res://assets/icons/web/<n>.png\|svg` |
| `assets/part/<slot>-<class>.svg` | `res://assets/icons/web/part/<slot>_<class>.svg` |
| `assets/node/<n>.png` | `res://assets/icons/node/<n>.png` |
| `assets/portrait/<class>.png` | `res://assets/portraits/<class>.png` |
| `assets/mon/<n>.png` | `res://assets/monsters/<n>.png` |
| `assets/bg/<n>.jpg` | `res://assets/backgrounds/origins/scene/<n>.jpg`, renumbered |

`tests/t_mockup_assets.gd` proves every path the four mockups name resolves to a real file. If
you add a mockup reference the table does not cover, extend `MockupAssets` and that test — do
not inline a `res://` string in a scene.

**Art that is NOT taken from the mockups** (user decision, 20 Sep 2026): the party Axies and the
monsters/bosses. The mockups draw the party as flat `back-<class>.png` sprites; this build keeps
rendering them with the 3D gene rig (`CombatStage3D` / `AxieCharacter3D`), and monsters keep
their existing Chimera sprites. Match the mockup's **layout boxes** — the 180px party column,
the 186px enemy column — by tuning the stage's camera and slot pitch, not by swapping the art.

---

## How to take a design instruction

**Apply it to every instance, not the one named.** A correction that says "enemy nameplates are
too small" is a statement about nameplates. Fixing enemies and writing *"party nameplates are
unchanged — this is enemy-only"* is how this codebase ended up with two nameplate sizes, five
different plate widths in one row, and a shield badge cutting an HP number in half.

If a rule looks like it does not apply somewhere, it applies. **Ask instead of narrowing scope.**

**Report what you could not do.** A pass that silently skips two of six items and reports success
costs more than one that fixes four and names the other two. If a fix conflicts with something
else, stop and say so.

**Never invent UI.** No chip, badge, eyebrow, divider or helper text that is not in the mockup.
An empty tile, an empty badge or a visible placeholder string is worse than nothing at all.

---

## Required loop for any UI task

1. Open the mockup for that screen and read the element's own markup — width, height, padding,
   radius, border, gap, font size, colour. Not a summary of it.
2. Make the change.
3. `godot --headless --path godot res://tests/t_mockup_assets.tscn` — must pass.
4. `godot --headless --path godot res://tests/t_ui_laws.tscn` — must not regress.
5. `rg 'panel_style\(|BG_PANEL|shadow_size = [1-9]' godot/` — must return nothing.
6. Re-capture the affected QA screen at **two different window sizes** — 1920×1080 and a taller
   non-16:9 one — and put the first beside the mockup. Both must be correct: nothing clipped, no
   void band, content column centred. One capture cannot prove an `expand` layout.
7. In the task report, list every item you did not complete and why.

---

## Where things live

| What | Where |
| --- | --- |
| Colours, surfaces, type, chips, node tones | `scenes/shared/DangoTheme.gd` |
| Mockup-path → repo-path translation | `scenes/shared/MockupAssets.gd` |
| Screen shell, footer, safe area, modal width | `scenes/shared/DangoScreen.gd` |
| Nameplates — **176 wide both sides**, enemy 64 tall, party 68 | `scenes/shared/UnitPortrait.gd` |
| HP bar, shield bar, at-risk slice | `scenes/shared/HPBar.gd` |
| Intent badge | `scenes/shared/UnitHeadHUD.gd` |
| Project-wide widget defaults — **generated** | `tools/gen_theme.gd` → `resources/theme/dango.tres` |

`dango.tres` is generated. Do not hand-edit it; regenerate with
`godot --headless --path godot --script tools/gen_theme.gd` and commit the result in the same
change. It must define defaults for `Button`, `OptionButton`, `TabBar`, `RichTextLabel`,
`ScrollBar`, `LineEdit` and `CheckBox` — an unstyled stock Godot widget must be impossible.

## The `196x64` nameplate is dead

`combat-v2.html` draws nameplates **176 wide on both sides**, 64 tall for an enemy and 68 for a
party member (the extra 4 is the 6px class-coloured top edge minus the shared border). Do not
implement both, and do not reintroduce a text-measured plate width — a plate whose width depends
on the name is how this screen ended up with five different plate widths in one row.
