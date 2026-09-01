# Visual Redesign Spec — "Lunacia Void" Direction

Status: DRAFT — ready for `ui-programmer` implementation, pending `creative-director` / product-owner sign-off.
Author: art-director
Date: 2026-09-01
Trigger: third round of "UI/UX chưa đẹp" feedback. Prior two rounds fixed point bugs (layout,
contrast, class-tint, acting-unit glow) — user confirmed via survey the complaint is systemic
across **all four** of: layout/spacing consistency, information density, color identity,
typography. This spec replaces "patch the bug" with a coherent direction.

Reference files read before writing this spec: `src/style.css` (full, 906 lines), `src/ui.js`
(`paintDieFace`, `unitCard`, `scCombat`, `dieBox`), `src/data.js` (`RAR_COL`, `CLASS_COLOR`),
`src/icons.js` (`IC_G`/`IC_COL`/`FT_IC`/`ST_IC`).

Hard constraints this spec does not violate (see `style.css` header comment and
`.claude/agent-memory/art-director/project_axie-dice-tactics.md`):
- DOM + CSS only. No canvas/WebGL, no image assets — icons stay inline-SVG via `icons.js`.
- Single static HTML file, `build.py` string-concatenation, deployed to Vercel — no runtime
  network fetches (no Google Fonts `<link>`).
- "Mỗi màu nói một điều": semantic effect colors (`--dmg/--shd/--heal/--man/--poi/--burn/--deb`),
  rarity colors (`--r0..r4`), and class colors (`CLASS_COLOR`) must not share a hue family in a
  way that creates a *new* meaning collision. This spec's palette changes were checked against
  all three tables (see §1.3).
- Existing structural decisions with documented rationale are kept: intent-block-on-top
  (transparency pillar), HP number pulled out of the bar (contrast), glow reserved for
  selection/legal-target/Mythic/acting-unit, `--pan-hi` "table plane" vs flat "deck plane".

---

## 1. Color System — "Lunacia Void"

### 1.1 Diagnosis

The current neutral scale (`--bg #0b0d10` → `--pan3 #39434f`) is blue-gray with no hue
personality — it reads as "generic dark-mode SaaS", not as the world of a specific game called
*Lunacia Mutants*. Meanwhile every *meaningful* color slot (semantic, rarity, class) is already
saturated and doing real work. The fix is not "add a new accent color" (there is no hue left to
claim without a collision — see the audit in §1.3) — it's to **give the neutral scale itself a
hue identity**, so the world the pieces sit in feels specific, and let the existing gold
`--acc` read as the brand color it already functionally is (CTA, Mythic, currency, Lunacia Pass).

### 1.2 Direction: deep violet-black "void" neutrals, gold stays the singular hero accent

Shift every neutral/surface token from blue-gray to a desaturated violet-black. This is a small
hue rotation (~15-20°) at controlled saturation — not a new "purple UI" — so existing borders,
text, and every semantic/rarity/class color sitting on top of it are unaffected in contrast, only
in *mood*. Paired with unchanged saturated accents, it reads as moonlit/mutant rather than
flat terminal-gray. It also directly reinforces the "Lunacia" (moon) namesake.

| Token | Old | New | Notes |
|---|---|---|---|
| `--bg` | `#0b0d10` | `#0b0a14` | base void |
| `--bg-top` | `#151a20` | `#171426` | body gradient top |
| `--pan` | `#1e242c` | `#201d33` | menu/deck-plane surface |
| `--pan2` | `#2a323d` | `#2a2638` | +1 surface step |
| `--pan3` | `#39434f` | `#3a3449` | +2 surface step (hover) |
| `--pan-hi` | `#333c47` | `#423b54` | "table plane" (unit/die) |
| `--line` | `#4a5563` | `#524a68` | decorative rule |
| `--line2` | `#707c8c` | `#786d99` | card border |
| `--txt` | `#e9edf3` | `#eee9f5` | slight warm-violet white, keeps ≥13:1 on `--bg` |
| `--dim` | `#a1aec0` | `#a89fc2` | secondary text |
| `--off` | `#7d8794` | `#7d759 0` → `#7d7590` | disabled-only |

Do not touch: `--acc`, `--heal`, `--shd`, `--man`, `--dmg`, `--poi`, `--burn`, `--deb`,
`--hp-full/low/crit`, `--r0..r4`, `CLASS_COLOR` (data.js). These are meaning-carrying and already
functioning; the redesign's job is the stage they perform on, not the actors.

Also update the two shadow tokens to a cool-violet-black shadow instead of pure black, so cast
shadows read as part of the same world instead of a generic drop-shadow:
- `--sh-card: 0 1px 0 rgba(255,255,255,.04) inset, 0 3px 0 rgba(10,6,20,.4), 0 6px 14px rgba(10,6,20,.5)`
- `--sh-hero: 0 1px 0 rgba(255,255,255,.06) inset, 0 4px 0 rgba(10,6,20,.45), 0 10px 22px rgba(10,6,20,.55)`

**Rationale**: violet-black is the one hue family currently *not* claimed by any semantic/rarity/
class table (see audit below), so it's free to become "the world" without creating a fourth
meaning that competes with combat-readable color. It also sits at maximum contrast distance from
`--acc` gold (near-complementary), which is why gold will visually pop *harder* after this change,
not less — solving "no personality" without touching the palette players must read at a glance
mid-fight.

### 1.3 Hue-collision audit (why no new accent token is being added)

| Hue family | Already claimed by |
|---|---|
| Red | `--dmg` |
| Blue | `--shd`, `--r1` |
| Violet/purple | `--man`, `--r2` |
| Gold/amber | `--acc`, `--r3` |
| Pink/magenta | `--deb`, `--r4`, class `bug` |
| Green | `--heal`, class `plant` |
| Lime | `--poi` |
| Orange | `--burn`, class `beast` |
| Teal/cyan | class `aqua` |
| Olive | class `reptile` |
| Indigo | class `bird` |
| Gray | `--r0` |

Every hue on the wheel is already meaningful gameplay information. This is *why* three rounds of
"add a nicer accent color" style fixes couldn't work — there was no room. Recoloring the neutral
scale itself (deep violet-black, very low saturation, far outside the saturation range any
semantic/rarity color uses) is the only move that adds identity without a fourth meaning
collision. Confirmed: `--man`/`--r2` (`#b388ff`) sitting on a violet-black backdrop reads as
"magic on midnight," a reinforcing pairing, not a collision — collisions are about two different
*meanings* sharing one hue, not a color existing near a background of a similar family.

### 1.4 Rarity/Class color table duplication (flag, not fixed here)

Per existing memory (`reference_icon-system-pattern` / `project_axie-dice-tactics`):
`RAR_COL` (`data.js`) and `--r0..r4` (`style.css`) are two hand-kept copies of the same five
values. They are already in sync today (`#9aa4b2 #63b3ff #b388ff #ffc857 #ff5f8f` in both) but this
redesign touches neither, and whoever implements it should unify them into one source (CSS custom
properties read via `getComputedStyle`, or a shared JS constant imported into a `<style>` block at
build time) as a follow-up ADR — flagging again here since this pass is the reason someone will
next be tempted to edit rarity colors and could edit only one copy.

---

## 2. Typography

### 2.1 Diagnosis — sizes used off-role

Type scale is well-designed (6 sizes, each with a documented role in the `--t1..--t6` comment) but
is not applied consistently to that role, which is a direct cause of "chỗ to chỗ nhỏ không đồng
bộ." `--t3` (15px) is explicitly documented as "BODY MẶC ĐỊNH — mô tả, tooltip, Codex, passive."
Some description/prose text correctly uses it; other description/prose text of the *identical
semantic role* uses `--t2` (13px, documented as "chữ phụ, chip, số nhỏ, keyword xúc xắc" — i.e.
short secondary labels, not paragraphs). Concretely:

| Correctly `--t3` (prose/description) | Incorrectly `--t2` (should be `--t3`) |
|---|---|
| `.pasbox .pd` (passive description) | `.ucard .ud` (unlock card description) |
| `.cxp` (codex paragraph) | `.rcard .rd` (reward card description) |
| `.tutbox .pre` (tutorial body) | `.gwhy` (guide "why" prose) |
| `.tips` *(borderline, see below)* | `.ic2s` (unit-info modal stat description) |
| | `.dvsum` / `.dvhint` (dev panel prose) |
| | `.cxsum` / `.cxsumbox` (codex summary prose) |

**Fix**: any block of prose whose job is to be *read*, not *scanned* (a description, a tooltip
body, a passive/ability text, a "why" explanation) uses `--t3`. `--t2` is reserved strictly for
what its own comment says: chips, badges, short single-line secondary metadata under ~30
characters. Apply this rule to the table above (6 selectors) — do not do a blanket find/replace of
every `--t2`, since chip-style uses (`.rchip`, `.mf`, `.citem`, `.icard`) are correct as-is.

### 2.2 Font weight — everything is 700

`body{font-weight:700}` is global with no relief; buttons, labels, AND paragraph body copy are the
same boldness. This flattens hierarchy — a value the player must act on now (a dice number, a
button label) doesn't stand out from a paragraph they're casually reading (Codex prose, a
tooltip). Recommend a second weight token:

```css
--fw-action: 700;   /* existing default — labels, values, buttons, HP numbers, anything scanned */
--fw-prose:  500;    /* new — .t3-role prose blocks: .pasbox .pd, .cxp, .tutbox .pre, .gwhy,
                         .ic2s, .ucard .ud, .rcard .rd, .cxsum, .cxsumbox, .dvsum, .dvhint */
```

Apply `font-weight:var(--fw-prose)` to the prose selector list above (same list as §2.1's fix —
these two changes ship together). Everything else keeps `--fw-action` (no change). This alone
reduces perceived visual noise on text-heavy screens (Codex, Guide, unlock/reward cards) without
touching combat-critical scan text at all.

### 2.3 Font family — two-tier system, no network dependency

Current: `--font: "JetBrains Mono","IBM Plex Mono",ui-monospace,"Courier New",monospace` used for
*everything*, weight 700. JetBrains Mono is a genuinely good choice for the game's data-dense,
tabular-number surfaces (dice values, HP numbers, stat rows) — tabular figures keep columns
aligned, which matters for `.ifrow`/`.cxtable`/`.recap` grids. **Keep it there.** The complaint
isn't that mono is wrong for data; it's that using it for the *brand wordmark and screen titles
too* makes the game's identity indistinguishable from a debug console.

Introduce a second, display-only face for chrome text: the logo, screen titles (`--t5`/`--t6`
roles: `.logo`, `.rewardbox h2`, `.maph`, `.nodecard .nn`), and the section header rows that
currently rely on letter-spacing alone for personality (`.cxh`, `.colsec h3`, `.bptitle`).

**Recommendation: "Chakra Petch" (SemiBold 600 / Bold 700), self-hosted as a base64 WOFF2 `@font-
face` inlined directly in `style.css`.** Geometric, slightly angular/technical letterforms —
reads as "tactics/mutation," not generic — and it is a genuinely small file (~15-20KB per weight
as WOFF2, two weights ≈ 35-40KB total base64'd). This keeps the "single static HTML file, zero
runtime network dependency" rule intact (same reasoning already applied to `art.js` sprite data
being embedded inline rather than fetched) while giving the wordmark and screen titles a distinct
face from the body/data mono.

```css
--font:       "JetBrains Mono","IBM Plex Mono",ui-monospace,"Courier New",monospace; /* unchanged: data/body */
--font-brand: "Chakra Petch","JetBrains Mono",sans-serif; /* new: logo + screen titles only */
```

Apply `font-family:var(--font-brand)` only to: `.logo`, `.logo.sm`, `.rewardbox h2`,
`.rewardbox.end h2`, `.maph`, `.cxh`. Do **not** apply it to numbers, buttons, or any `--t1/--t2`
label — those stay mono for scan-speed and column alignment.

**Fallback if base64 font embedding is rejected on file-size or build-pipeline grounds** (this is
a call for `ui-programmer`/`technical-artist` on `build.py` output size, not an art call): use a
bold system sans-serif stack for the same selector list instead of a custom face —
`font-family: ui-sans-serif, "Segoe UI", system-ui, sans-serif; font-weight:900; letter-spacing`
unchanged. This still separates brand chrome from body/data mono using zero extra bytes and zero
network calls, at the cost of losing the bespoke character Chakra Petch would add. Either option
resolves the complaint; the base64 option is the stronger identity move.

---

## 3. Combat Screen — Information Density

### 3.1 Diagnosis (from `unitCard()` / `dieBox()` / `paintDieFace()` in `src/ui.js`)

A single 158px-wide `.unit` card simultaneously renders, always-on: sprite, passive-dot avatar
overlay, name+tier text, HP number pair, HP bar, shield bar (icon+number) when present, a status
row that can hold up to ~9 different icon+number chips at 11px each (`ST_IC` has poison/burn/
regen/thorns/blind/weaken/vulnerable/stun/undying, plus frozen), and — for enemies — a full intent
block (icon, value, target arrow, up to 3 keyword tags). Its paired `.diebox` (160×120px) then
stacks: part-name label, heavy banner, effect-type icon, value number, a *spelled-out* keyword
text row (`AOE · PIERCE`-style, `--t2`/13px), a crit badge, and a rarity dot — seven independent
visual elements in one small rounded rect. None of this is wrong information to have on screen
(the game's transparency pillar wants it visible) — it's simply never been triaged into
"always/glance" vs "only-when-relevant."

### 3.2 Fix 1 — status row: cap visible chips, size them up, overflow on demand

Current: `.stats span{font-size:var(--t1)}` (11px icon+number), unbounded count, unbounded row
wrap. Change:
- Bump the status chip icon size from the `t` variant (11px) to the `ii` variant (15px) already
  defined in `.icow.ii svg` — status effects are combat-relevant state, they deserve to be as
  legible as intent icons, not the smallest icon on the card.
- Priority-sort before render: `stun` and `undying` first (they change what a unit *can do* this
  turn), then `poison`/`burn` (ongoing damage, must-track), then everything else. Render the
  first **3** in the row; if more are active, render a 4th chip reading `+N` in `--dim` color that
  expands the full list as a tooltip/hover (reuse the existing `title=` attribute pattern already
  used per-chip — no new interaction code, just move the aggregation from "always all" to
  "top 3 + overflow").
- This caps the row at a fixed max width regardless of how many statuses are stacked, which is
  what actually stops the card from feeling like it's "full of tiny icons" in a heavy-debuff
  fight — the worst case (5+ statuses) is exactly when density was worst before.

### 3.3 Fix 2 — die face: convert spelled-out keywords to icon chips

`.dk` currently renders `kws.map(kwText).join(' · ')` as plain text at 13px — e.g. "AOE · PIERCE"
— stacked below the value number on an already-busy face. Extend the existing `FT_IC`/`ST_IC`
lookup pattern (documented in `reference_icon-system-pattern` memory) with a parallel `KW_IC` map
for face keywords (`aoe, pierce, chain, multi, exec, cleave, heavy, cantrip`), each a small 8×8
`IC_G` glyph (technical-artist to draw: e.g. aoe = burst/radiating dot, pierce = arrow-through,
chain = linked links, multi = ×2 glyph, exec = skull, cleave = slash arc). Render as a single row
of `ico(KW_IC[k],'t')` icons instead of text. This is a straight net *reduction* in rendered glyph
count per keyword (one 8×8 icon vs. an average 6-character word) and removes the only text
element on the die face that isn't a number or the (already-icon-paired) part name.

**Interim option if new icon art isn't ready this sprint**: at minimum, stop rendering every
keyword inline. Show only combat-decision-critical keywords on the face itself (`aoe`, `heavy`,
`exec` — the ones that change whether/how a player should commit this die) and drop purely
informational ones (`multi`, `chain`, `pierce`, `cleave`, `cantrip`) from the compact face,
relying on the **existing** unit-inspect modal (`modal='unit'`, already wired via `c.onclick` in
`unitCard()` for non-targetable cards) to show full keyword text on demand. No new interaction
pattern needed — this modal already exists and already lists every face.

### 3.4 Fix 3 — die face: merge the two competing top-corner overlays

`.heavytag` (a banner spanning the full top edge) and `.rartag` (a 6px dot, top-right corner) are
two independently-`position:absolute` elements that can render on the same die simultaneously
(a Heavy Legendary face) fighting for the same 6-8px of vertical space. Merge into one **top
accent strip**: a 3px-tall bar spanning the full card width, colored by rarity (`--r1..r4`, same
as today's dot, just wider and flatter instead of a dot) with a small weight-icon (⚖ or a filled
triangle, drawn as an `IC_G` glyph) inset at its left edge only when `heavy` is present. One
element, one visual slot, still communicates both facts.

### 3.5 Fix 4 — HP number: drop the redundant "HP" text label

`.hpnum` currently renders `HP` then `12/20` — the label is redundant with position (it always
sits directly above the health bar, which also carries `aria-label="Health"` for screen readers,
so accessibility is unaffected by removing the visual label). Cutting the word "HP" from every
single unit card on the board removes one text element × up to 10 simultaneous units on screen at
once, for zero information loss.

### 3.6 Fix 5 — grow the card, don't shrink the content, at desktop widths only

Increase `--unit-w` 158px→172px and `--die-w`/`--die-h` 160px→176px / 120px→128px **only inside
the existing `@media (min-width:1200px)` implicit default tier** (i.e. do not touch the three
breakpoint overrides at 1199/899/599px — that math is load-bearing per the T10 comment block and
verified against `tools/verify.mjs`). Combined with Fixes 1-4 (fewer/larger elements, not more),
the net result on a normal desktop viewport is the *same information* with real padding around
each icon instead of icons touching each other's bounding boxes — this is the single highest-
leverage change for "feels cramped" on the screen where the user spends the most time.

### 3.7 Fix 6 — standardize internal card rhythm to the spacing scale

Within `.unit`, vertical gaps between stacked blocks (sprite → name → HP bar → shield bar → status
row → intent) currently use ad hoc values (`margin-bottom:2px` on `.spr`, `4px` on `.nm`,
`margin-top:4px` on `.stats`) instead of the `--s1..--s7` scale that exists for exactly this.
Standardize every inter-block gap in `.unit` and `.die` to `var(--s1)` (4px) except the one
structurally-necessary exception: `.hpbar{margin-top:20px}`, which exists to reserve room for the
absolutely-positioned `.hpnum` sitting above the track (documented in the T05 comment). Rename
that one magic number to a token so its purpose is visible at the definition site instead of only
in a comment three lines away: `--hp-num-offset: 20px;` in `:root`, used as
`.hpbar{margin-top:var(--hp-num-offset)}`.

---

## 4. Spacing Consistency

### 4.1 Diagnosis

`--s1..--s7` (4/8/12/16/24/32/48px) exists and is used correctly in newer code (the 2026-09-01
"Table plane" and Formation Resonance additions all reference `var(--sN)` tokens). Older code
throughout the file uses hand-picked pixel values that happen to be close to, but not on, the
4px grid — this is the direct, measurable cause of "chỗ to chỗ nhỏ không đồng bộ": near-identical
components (every "card" pattern on the page) currently ship with **at least eight different**
padding pairs for what is visually the same shape:

| Selector | Current padding | On-grid? |
|---|---|---|
| `.ucard` | `12px` | yes (`--s3`) but literal |
| `.nodecard` | `18px 14px` | no |
| `.rewardbox` | `22px` | no |
| `.rcard` | `16px 12px 12px` | yes but literal |
| `.gcard` | `18px` | no |
| `.icard2` | `14px` | no |
| `.bpnode` | `12px 10px` | no (10) |
| `.psc` | `7px` | no |
| `.stat` | `9px 20px` | no (9) |
| `.mdhead` | `14px 18px` | no |
| `.cxpane` | `20px 22px` | no (22) |
| `.tutbox` | `26px 30px` | no |

### 4.2 Fix — two-tier canonical card padding

Add to `:root`:
```css
--card-pad-sm: var(--s3); /* 12px — compact/chip-style cards: .psc, .bpnode, .icard2 */
--card-pad:    var(--s4); /* 16px — standard content cards: .ucard, .nodecard, .gcard, .rcard, .rewardbox, .mdhead, .cxpane, .tutbox */
```
Reassign every selector in the table above to one of the two tokens (content cards → `--card-pad`,
compact/list-row cards → `--card-pad-sm`), replacing the literal pixel values. This is a
mechanical, low-risk pass — no layout dimensions change meaningfully (differences are ≤6px per
side) but every card on every screen now shares one of exactly two padding values instead of
eleven, which is what actually reads as "designed" rather than "organically grown."

Also snap the two remaining off-grid non-card values found in the audit: `.pasdot{top:4px;
left:4px}` is already on-grid but should reference `var(--s1)` instead of a literal, and
`.pasdot{width:24px;height:24px}` should reference the existing `--icon-md` token (already `24px`
in `:root`) instead of repeating the literal — this is the kind of drift that causes the two
tokens to silently diverge if one is ever tuned later.

---

## 5. Implementation Handoff

**Scope for `ui-programmer`** (all in `src/style.css` unless noted):
1. §1.2 — 11 token value edits in `:root` (neutrals + 2 shadow tokens). Zero selector changes.
2. §2.1/§2.2 — add `--fw-prose` token; apply `font-size:var(--t3);font-weight:var(--fw-prose)` to
   the 6-selector prose list.
3. §2.3 — add `--font-brand` token + `@font-face` (base64 WOFF2, coordinate with
   `technical-artist` on `build.py` output size before committing to this vs. the system-font
   fallback); apply to the 6-selector chrome list.
4. §3.2/§3.4/§3.5/§3.6/§3.7 — `unitCard()`/`dieBox()`/`paintDieFace()` changes in `src/ui.js`
   (priority-sort + cap status chips, merge heavy/rarity overlay markup, drop `HP` label text,
   `--unit-w`/`--die-w`/`--die-h` bump inside the default (≥1200px) tier only) plus matching CSS.
5. §3.3 — new `KW_IC` icon set: **delegate art (8×8 `IC_G` grids) to `technical-artist`**, this
   agent only specifies which 8 keywords need glyphs and what each should communicate at-a-glance
   (see list in §3.3). Interim text-triage fallback (§3.3 second paragraph) can ship independently
   and immediately, ahead of new icon art.
6. §4.2 — `--card-pad`/`--card-pad-sm` tokens + reassignment across the 12-selector table.

**Verification**: run `tools/verify.mjs` after each numbered step above (must hold ≥29/30) and a
soak pass (`tools/soak.mjs`) after the `unitCard()`/`dieBox()` structural edits in step 4, per the
project's existing rule that `.die`/`.unit` element-lifecycle changes are a known regression
source for drag/drop.

**Not in scope for this spec** (flagged, not actioned): unifying `RAR_COL`/`--r0..r4` (§1.4) —
separate ADR-sized task for `lead-programmer`/`ui-programmer`.
