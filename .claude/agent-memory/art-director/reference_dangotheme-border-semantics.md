---
name: dangotheme-border-semantics
description: DangoTheme card-border color is reserved for STATE alerts, not category/archetype tagging — use an inset left-edge stripe for category identity instead
metadata:
  type: reference
---

Decision made 2026-09-19 while choosing how SAMPLE TEAMS guide cards
(`godot/scenes/guides/GuidesView.gd`, `_build_card`) should carry their
archetype color, after `ux-designer` flagged a P2 (peripheral-vision
recognition while fast-scrolling) and deferred the color choice to
art-director.

**The rule:** `DangoTheme.panel_style()`'s `border` parameter (added
2026-09-19, defaults to `DangoTheme.BORDER` black) is reserved for
**state/alert signaling** — e.g. a Vault record that needs re-scanning — per
its own doc comment ("a panel sometimes has to carry a STATE... a coloured
border is a signal that survives being scrolled past"). Do NOT also use
full-perimeter border color to encode a static category (archetype,
faction, rarity, etc.) on the same card type. Two different meanings
("something needs your attention" vs. "this belongs to category X") must
not share one visual channel (card border color), or players lose the
ability to tell them apart — the same failure mode as the HP-fill/faction
collision documented in [[project_axie-dice-tactics]]'s 2026-09-09 entry.

**The pattern chosen instead, for category/archetype identity:** an inset
left-edge accent stripe — a separate solid-fill element (Panel/ColorRect,
not the card's own StyleBoxFlat border) placed inside the card's existing
black-bordered PanelContainer, before the content MarginContainer. Spec
for the SAMPLE TEAMS case: 5px wide, full card height, 100% opacity solid
fill using the archetype's own `ARCH[key].c` hex (no new color, `ARCH` is
copied verbatim from the live JS build and must not be edited), rounded to
match the card's corner radius (8px) on the top-left/bottom-left corners
only. Godot detail: `StyleBoxFlat.border_color` only accepts one color for
all four sides, so a single-sided colored border isn't possible via
`panel_style()` alone — the stripe must be a distinct child element, not a
`panel_style()` border-width trick.

**Why inset, not flush with the card edge or full-perimeter:** keeps the
outer silhouette/black border identical across every card in the app
(consistent cross-screen "this is a card" grammar), and avoids the
border-color state-channel collision above. A left-edge position (rather
than top, or a background tint) is what peripheral vision actually keys
off during fast vertical scrolling — a fixed x-position, continuous
color blob — matching the interaction need `ux-designer` described,
without touching text contrast (a background tint was rejected specifically
because it would put 10 different archetype hues, some light like
`#ffd76a`/`#66e08a`, behind body text tuned only for the plain `#13161B`
background, reopening a contrast-verification job per archetype).

**Known latent collision, not yet active:** `ARCH.burn` (`#ff9a4d`) is
near-identical in hue to `DangoTheme.PRIMARY` (`#FF9345`, the CTA/selection
orange). No live guide uses `burn` today (the 4 SAMPLE TEAMS guides use
shield/poison/crit/mana only), so this hasn't surfaced yet — but re-check
by eye the first time a `burn`-archetype card ships next to a `PRIMARY`
CTA button, since `ARCH` hex values cannot be changed (copied verbatim from
the live JS build, per `godot/autoload/ContentDB.gd` comment).
