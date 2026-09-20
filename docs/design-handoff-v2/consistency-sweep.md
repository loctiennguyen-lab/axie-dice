# v2 UI consistency sweep — 2026-09-20

Scope: the eight non-combat v2 screens (Main Menu, Team Select, Pass, Unlocks, Vault, Guides,
Run Map, Result). Combat and its shared widgets (`CombatView.gd`, `UnitHeadHUD.gd`,
`UnitPortrait.gd`, `HPBar.gd`, `CombatStage3D.*`) were out of file-scope (another agent is
mid-edit there) — audited read-only, findings handed off at the bottom of this doc.

`godot/tools/run_tests.sh`: **44/44 green**, both before and after this pass (re-run after
every fix in this doc; final run quoted below).

## What was checked and found clean (no action needed)

- **`TextureRect` without `expand_mode`.** Every `TextureRect.new()` call site across all eight
  screens already sets `expand_mode = TextureRect.EXPAND_IGNORE_SIZE` (several with a comment
  explaining the exact bug this sweep was told to look for — it had already been hit and fixed
  once, e.g. `RunMapController.gd`'s `_build_token()` icon, `ResultView.gd`'s relic-chip icon).
  No `TextureRect` scene nodes exist in any of the eight screens' `.tscn` files either.
- **`Button.icon` sizing.** One call site (`UnlocksView.gd`), already carries
  `icon_max_width`.
- **`DangoTheme.display_label()` / the Baloo 2 leading bug.** Grepped every
  `add_theme_font_override("font", DangoTheme.FONT_DISPLAY` site (37 across Main Menu, Team
  Select, Result). All but one are single-line Button captions or fixed-string Labels, which
  cannot exhibit the leading gap (`display_label()`'s whole job is correcting the line height of
  a label that *breaks a line*). The one multi-line case that existed — `MainMenu.gd`'s
  "AXIE DICE\nTACTICS" title — already goes through `display_label()`, with a comment
  explaining exactly this history. Did not mass-convert the remaining single-line sites to
  `display_label()`: that would be a large, low-value refactor of working, tested code for a bug
  that provably cannot occur on a single line, which the brief's "do not chase small tidiness
  points" instruction argues against. Left as a follow-up note below, not fixed.
- **`ScrollContainer` styling.** Four of five screen scrolls already call
  `DangoTheme.style_scrollbars()` + `clip_contents = true`. The fifth (`RunMapController.gd`'s
  rail scroll) had `style_scrollbars()` but relied on `ScrollContainer`'s implicit
  `clip_contents == true` default rather than setting it — fixed for consistency, see below.
- **`shadow_size` outside DangoTheme helpers.** Every direct `shadow_size =` assignment in the
  eight screens is `0` (the hard-shelf rule). No blurred shadows found.
- **Contrast / `INK_ON_PRIMARY`.** No white or cream ink found set directly on a `PRIMARY` fill;
  every PRIMARY-filled surface routes ink through `INK_ON_PRIMARY`/`ink_on()`.
- **Leaks** (empty string / `<null>` / `nan` / raw id where a name belongs). None found in the
  eight screens' capture evidence or in the string-building code read during this pass.

## Fixes applied

### 1. Vault die-strip grid didn't fill its card (visible layout defect)

`VaultView._build_die_strip()` builds a 3-column `GridContainer` of part-face chips. The chips
had no horizontal size flag, so `GridContainer` sized each column to its children's *minimum*
width and left the rest of the row's width — which the card itself correctly fills — as dead
cream space. Visible on the pre-fix capture: the die-part chips filled roughly half the card
width, mockup fills them edge to edge. Fixed by adding
`chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL` before adding each chip to the grid.
Re-captured; the fix visibly closes the gap (`2026-09-20_meta-v2_vault.png`).

### 2. Colour literals duplicating existing `DangoTheme` tokens (five screens)

Grepped every `Color(`/`Color8(`/`Color.<NAME>` outside `DangoTheme.gd` across the eight
screens. Several were byte-for-byte re-derivations of tokens the system already carries —
in one case (`RunMapController.gd`'s `_EDGE_LIVE`) the code's own comment already said
"— CREAM_HI" and never made the connection into an actual reference. Converted every exact
match to the shared constant, and removed the now-dead local consts:

| Screen(s) | Local name removed | Now reads |
|---|---|---|
| `MainMenu.gd` | `_SUBTITLE_LAVENDER` | `DangoTheme.INFO_TEXT_ON_WELL` |
| `MainMenu.gd` | `_MUTED_BROWN` | `DangoTheme.INK_ON_CREAM_MUTED` |
| `TeamSelect.gd` (2 sites) | inline literal | `DangoTheme.INK_ON_CREAM_MUTED` |
| `ResultView.gd` (1 site) | inline literal | `DangoTheme.INK_ON_CREAM_MUTED` |
| `ResultView.gd` (1 site) | inline literal | `DangoTheme.MUTED_TEXT` (this token's own doc comment already names "XP-to-next line" as its example job — this was that exact line, hand-coded instead of referenced) |
| `RunMapController.gd` | `_FOG_INK` | `DangoTheme.MUTED_TEXT` |
| `RunMapController.gd` | `_TICK_INK` | `DangoTheme.INK_ON_SUCCESS` |
| `RunMapController.gd` | `_EDGE_LIVE` | `DangoTheme.CREAM_HI` |

Two more literals were identical to each other **across two files** but did not previously exist
in `DangoTheme` at all — promoted rather than left duplicated, per the brief's "prefer fixing the
system" instruction:

- `Color(0x6F,0x78,0x87)` — `RunMapController.gd`'s `_MUTED` (rail eyebrow/seed/stat captions,
  5 sites) and `ResultView.gd` (3 inline sites, stat-ribbon captions). Promoted to
  `DangoTheme.CAPTION_MUTED`.
- `Color(0xA9,0xB3,0xC2)` — `RunMapController.gd`, two inline sites (tier chip ink, relic-count
  ink), both on a `WELL` surface. Promoted to `DangoTheme.CHIP_INK_ON_WELL`.

And one formula duplicated **three times across two files**: a 22%-alpha wash of `PRIMARY` for
hairline dividers, independently re-derived at `RunMapController.gd` (x2) and `ResultView.gd`
(x1, one of the three even re-typed PRIMARY's own RGB bytes instead of referencing the constant).
Added `DangoTheme.primary_divider_alpha()` and pointed all three call sites at it.

Left alone, with reasoning:

- `MainMenu.gd`'s `_DARK_ON_PRIMARY_DIM` — no existing match in `DangoTheme`, used only for this
  screen's BEGIN RUN / CONTINUE RUN button subtitles. A genuine one-off, kept local (its comment
  was corrected, since it used to also claim this about the two literals that turned out to be
  duplicates).
- `TeamSelect.gd`'s passive-panel body ink (`Color(0x3A,0x1E,0x07)`) and keyword ink
  (`Color(0xB4,0x60,0x0C)`) — close to but not exact matches of any existing token; did not
  invent a promotion for a near-miss without a second real duplicate to justify it. Flagged as a
  follow-up below rather than guessed at.
- `GuidesView.gd`'s archetype accent colour (`Color(str(arch.get("c", "")))`) — this is
  data-driven (parses a hex string from `ContentDB.ARCH`, the team-archetype record), not a
  hardcoded UI literal, analogous to `DangoTheme.node_tone()` reading from a data dict. Not a
  violation of this rule; left as-is.
- `RunMapController.gd`'s current-node selection ring (`ring_sb.border_color = DangoTheme.PRIMARY`)
  and Combat's selected/targetable portrait borders (see combat findings below) — a pulsing
  "you are here" / "this is selected" indicator is a different kind of object than a card/chip
  outline, and the brief itself carves out exactly one exception for a non-black border (the
  DANGER-bordered warning button) for the same reason: the colour IS the signal. Treated as the
  same category of deliberate exception, not fixed.

### 3. `RunMapController.gd`'s rail `ScrollContainer` missing explicit `clip_contents`

Added `scroll.clip_contents = true` next to its `style_scrollbars()` call, matching the other
four screens' scrolls. `ScrollContainer` defaults this to `true` already, so there was no visible
bug — this is the one purely-internal-consistency fix in this pass, done because it was a
one-line, zero-risk change directly called out by the brief's checklist.

### Cross-screen convention check (BACK button, header block) — audited, no fix needed

Compared the four screens with a hand-rolled `_build_back_button()` (Pass, Unlocks, Vault,
Guides — no shared `DangoTheme` helper exists for it yet). Initially looked like drift: Pass and
Unlocks anchor BACK at `x=84`, Vault at `x=64`, Guides at `x=52`. Traced each screen's own header
margin and found every BACK button's `x` exactly matches **that screen's own** header/content
left inset (`Pass`/`Unlocks` header row is `offset_left = 84`; `Vault`'s is `64`; `Guides`' is
`52`) — confirmed against the mockup screenshots, which use three different left margins across
these screens too (Pass's title sits further right than Vault's). So this is each screen
correctly matching its own redline, not four screens drifting from a shared one. Did not force a
single shared `x` — that would be *introducing* a mismatch against the mockups to solve a
mismatch that doesn't exist between the screens. The Y-inset differs by 4px (Pass/Unlocks
`-72`, Vault/Guides `-68`); left alone as genuinely below the "chase small pixel offsets"
threshold the brief warns against.

No shared `back_button()` helper was added to `DangoTheme` for the same reason: the four
implementations are otherwise identical (same button, same style call, same scene-change), and
the only difference (`x`) is a deliberate per-screen value, not something a shared helper should
paper over with a default that would then need per-call overriding anyway. Noted below as a
"could still be worth it for future screens" item rather than done now.

## Left as follow-ups (not fixed this pass)

1. **`TeamSelect.gd` near-miss ink colours** (`0x3A1E07`, `0xB4600C`) — worth a second look with
   the mockup redlines open side-by-side to decide whether they're deliberate variants or typos
   of `INK_ON_CREAM_SOFT`/a darkened `PRIMARY`.
2. **Result screen's run-stat ribbon reads all zero** (`TURNS TAKEN`, `DAMAGE DEALT`, `KILLS`,
   `BIGGEST HIT` all show `0` in the victory capture). This is a data-plumbing question, not a UI
   rendering bug — `RunStatsAccumulator.gd`/`t_run_stats_accumulator.gd` are both present in this
   session's working tree (new/untracked) and look like exactly the in-flight fix for this; not
   touched here since it's state, not display, and outside this pass's file scope.
3. **A shared `DangoTheme.back_button()` helper** — not needed today (see above), but if a ninth
   meta screen is added, worth revisiting once there are enough call sites that per-screen `x`
   values plus a shared style stop being "four screens, four numbers" and start being real drift.
4. Mass-converting single-line `FONT_DISPLAY` labels to `display_label()` for uniformity's sake —
   explicitly not done (see "checked and found clean" above); would be a large low-risk-but-
   zero-defect refactor, flagged rather than done unasked.

## Combat findings — handed to the combat agent, not touched here

Read-only audit of `CombatView.gd`, `UnitHeadHUD.gd`, `UnitPortrait.gd`, `HPBar.gd`,
`CombatStage3D.*` using the same grep checklist as the eight screens. None of these were edited.

- **`UnitPortrait.gd:108` — `shadow_size = 8`.** This is a real hit on the "exactly one shadow,
  `shadow_size = 0`" rule — a blurred shadow rather than a hard shelf, on the `_selected_style`
  StyleBoxFlat. Worth checking directly; every other `shadow_size` assignment found in these five
  files was `0`.
- **`UnitPortrait.gd:106` (`border_color = DangoTheme.PRIMARY`, selected) and `:110`
  (`border_color = DangoTheme.INFO`, targetable)** — non-black borders. Likely the same
  deliberate "the colour IS the signal" exception as the map's current-node ring (see above), but
  flagging so the combat agent can confirm intent rather than this sweep guessing at combat's own
  spec.
- **`UnitHeadHUD.gd:134`** (`_intent_style.border_color = col`) and **`CombatView.gd:736`**
  (`sb.border_color = color`) — both set a border from a variable rather than a literal; could
  not confirm from a read-only pass whether `col`/`color` ever resolves to something other than
  black or a deliberate semantic accent. Worth a two-minute check.
- **Re-run the colour-literal grep on these five files before merging further combat work**:
  `UnitHeadHUD.gd` (4 `Color(` sites), `UnitPortrait.gd` (11), `HPBar.gd` (2), `CombatView.gd`
  (13), `CombatStage3D.*` (14). Given `DangoTheme.gd`'s own header notes a full combat-colour
  review already happened 2026-09-17, most of these are probably already-approved intentional
  values rather than drift — this sweep did not have file access to verify each one against that
  review, so listing the raw counts rather than asserting a verdict.
- **`TextureRect`/`expand_mode` counts matched 1:1** in every one of these files (10 `TextureRect.new()`
  + 10 `expand_mode` in `CombatView.gd`; 1+1 in `UnitHeadHUD.gd`) — looks clean, but a count match
  isn't a line-by-line proof; worth a real check once combat's edit is done, same as everything
  else on this list.
- No `ScrollContainer` in combat scripts, no `FONT_DISPLAY` overrides found.

## Test suite

```
$ godot/tools/run_tests.sh
================ 44 tests: 44 passed, 0 failed ================
```
Run after every fix in this doc (including the intermediate GDScript typo caught by
`Godot --headless --path godot --import` before running tests — a stray `//` line comment in a
GDScript block, fixed immediately, never reached the test run).

## Screens re-captured

Only the screens actually changed by this pass:

- `production/qa/evidence/2026-09-20_meta-v2_vault.png` (Vault — the die-strip fix; Pass/Unlocks/
  Guides also re-saved by the same capture script but are pixel-identical, they share the run)
- `production/qa/evidence/2026-09-20_run_map_v2.png` (Run Map — colour-token swap only, no visual
  change expected or found)
- `production/qa/evidence/2026-09-20_menu-result_01_mainmenu_default.png`,
  `_02_mainmenu_reconfigured.png`, `_03_teamselect_default.png`, `_04_teamselect_reconfigured.png`,
  `_05_result_victory.png`, `_06_result_defeat_no_relics.png` (Main Menu / Team Select / Result —
  colour-token swap only, no visual change expected or found)

Pass, Unlocks and Guides were not touched (no edits landed in `PassView.gd`, `UnlocksView.gd` or
`GuidesView.gd`), so their existing 2026-09-20 captures still reflect current code.
