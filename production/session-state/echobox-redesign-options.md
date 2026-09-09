# Echo Box Layout Options — Vertical+Horizontal Redesign

**Status**: Research only, no decision made. Grounded against live `scEchoBox()`
(`src/client.html:3678-3801+`) and its CSS (`client.html:470-509`).

## Confirmed current structure

Every block is a `margin:0 auto`, `max-width:420-1050px` centered rail:
`.echohero` (strip of pool chips, 1050px) → `.echorank` (bar, 420px) →
`.echopull` (button, 420px) → reveal area (`.chestreveal`/`.rcard`) →
`.fusepanel` (4 rows, 520px) → `PULL LOG` (`.colsec`) → `BACK`. This is the
post-2026-09-07-spec (`design/ux/echo-box.md`) implementation — that spec
already promoted the screen out of Collection and gave it real components,
but ordered them all top-to-bottom with no side-by-side grouping, which is
exactly the PM's current complaint.

## Options

**A — Two-column hero (banner+rank left, pull action right).**
`.echohero` + `.echorank` stack in a left column; `.echopull` sits large in a
right column, vertically centered against them — mirrors Genshin's
banner-art-left / Wish-button-bottom-right relationship. Fuse panel + log
stay below, full-width, unchanged. Cheapest change (touches layout only, zero
new components) but only fixes the top third of the scroll.

**B — Hero row + tabbed secondary (Pull / Fuse / Log).**
Same two-column hero as A, but `.fusepanel` and `PULL LOG` move into a
tab strip below the hero — only one panel expanded at a time instead of both
always-open. Closest to Genshin, where Wish History is a separate view, not
inline. Removes the most vertical length of any option; cost is one new
tab-switch interaction to design/build (must stay `kbAct()`-focusable per the
existing keyboard-gap tracked in `reference_axiedice_ui_rules`).

**C — Persistent sidebar, swappable main area.**
Rank + pull button become a persistent right-hand sidebar (visible at all
times); hero banner, fuse panel, and log each become swappable "views" in a
left main area selected by a small menu. Strongest Genshin parallel (pity
counter always visible in a corner) but the biggest structural change —
effectively a mini-router inside one screen, most implementation risk.

**D — Full-width hero, then a 2-column secondary row.**
`.echohero` stays full-width across the top (unchanged). Below it, one row
splits into `.echorank`+`.echopull` (left) and `.fusepanel` (right) as two
cards side by side. Log stays full-width below, collapsed by default
(`<details>` or existing disclosure pattern) rather than tabbed. Balances A's
simplicity with B's length reduction; no new interaction pattern beyond a
collapse toggle.

## Desktop vs. mobile (landscape-only, breakpoints 1199/899/599)

Options A, B, D need a documented stacked fallback below 899px (repeat existing
`.echohero`/`.echorank` pattern: `flex-direction:row` above 899px → `column`
below, same mechanism already used elsewhere for 3-breakpoint layouts).
Option C is the highest mobile risk — a persistent sidebar competes hardest
for width at 899px and below, and this project's phone-portrait users are
already gated behind a rotate-hint, so a landscape-only sidebar has less room
than it would on a real tablet/desktop target.

No option is recommended over another here — this file is input for the next
discussion, not a decision.
