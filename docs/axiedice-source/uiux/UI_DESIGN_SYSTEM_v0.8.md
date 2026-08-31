# Axie Dice Tactics — UI design system (v0.8)

The old interface was not ugly so much as *undecided*. Every element competed:
a maroon background as saturated as the Axies, glow on almost everything, five
border weights, fourteen font sizes, and the same information printed in three
places at once. This pass gives the game one set of rules and applies them
everywhere.

## The four rules

**1. The background is neutral. Colour carries meaning.**
Surfaces are a single family of desaturated greys (`#0e1013` → `#2c333e`). The
Axie sprites are now the only saturated thing on screen, which is what a player
should look at first. Every colour that remains says something specific:

| Colour | Means |
|---|---|
| Gold `#ffc857` | You can act here — your selection, a legal target, the confirm button |
| Red `#ff6b6b` | Damage |
| Blue `#63b3ff` | Shield |
| Green `#5fd68a` | Healing and health |
| Purple `#b388ff` | Mana |
| Lime `#a8d84a` | Poison |
| Pink `#ff8fc7` | Debuff |

Rarity keeps its own five colours and is never used for anything else.

**2. Six type sizes, and no more.** 9 / 11 / 13 / 17 / 26 / 40. Anything that
needed a size in between was the wrong size.

**3. One border weight, two radii, spacing on a 4px grid.**

**4. Glow marks exactly three things.** Your selected die, a legal target, and
Mythic rarity. Before this, boss cards, elite cards, golden dice, rare rewards,
the mana orb and the end-turn button all glowed, so nothing did.

## What changed on the board

**The two header bars became one.** Wave number, wave type, turn, rerolls,
Shard, Ascension, undo, speed, info and settings now live in a single strip.
The wave counter used to be printed twice — once as text, once as a row of
numbered boxes. It is now one bold `3/12` plus a row of dots, which reads
faster and takes a third of the space.

**The build read-out moved into INFO.** `BUILD · PLAGUE 3 · BULWARK 2 · CONDUIT 1`
was on screen every frame of every fight. It is worth checking between
decisions, not during them.

**The `- - - VS - - -` divider is gone.** Two rows facing each other do not need
to be told they are opposed.

**Die labels are gone.** Each die sat under its own Axie and repeated its name.
The alignment already says which die belongs to whom.

**The hint bar retires after wave 1.** New players get the controls line; after
that it only appears when there is something specific to say.

**The mana orb became a pill.** A circular gauge with a number, a label and a
rising fill inside 50 pixels was three things fighting for the same space.
`MANA 6` is legible at a glance.

**The board is vertically centred** rather than bottom-anchored, and the leaner
layout now fits a 1280×720 window at full scale — the auto-fit shrink no longer
has to engage on a laptop.

## What changed elsewhere

- **Menu:** stat row became one joined strip; the version, tips and buttons sit
  on a clear vertical rhythm.
- **Team select:** each Axie card is one column — sprite, name, class, passive,
  die preview — with the class colour reduced to a 3px underline.
- **Map:** node cards carry a coloured top rule instead of a full coloured
  border and a pulsing shadow.
- **Reward / shop / event:** cards share one shape and one internal order, with
  `TAKE` pinned to the bottom so every card is the same height.
- **Codex:** left rail navigation with an active marker; tables are real grids.
- **Lunacia Pass:** every node is the same compact card; the progress bar is
  centred under the title instead of floating at the left edge.
- **Info panel:** the six die faces are now a real table — index, icon, part,
  value, keywords, rarity — so faces line up column for column across Axies.

## Bugs fixed on the way

- The Codex table header shared a class name with the section heading, so every
  table carried a phantom empty row.
- The Lunacia Pass header and its reward nodes shared four class names, which is
  why level numbers rendered at 26px inside the cards.
- The Sample Teams cards styled the wrong elements entirely (`.gb` is the bullet,
  not the Axie tile).
- Several glyphs — `▸ ☠ ♾ ↯ ↺ ✕` — have no glyph in the pixel font and were
  rendering as empty boxes in floating combat text, the modal close button and
  the guide bullets. Replaced with words or CSS shapes.

## Working on this file

`src/style.css` is ordered by screen and the four rules are stated at the top.
Before adding a colour, check whether an existing semantic colour already means
that thing. Before adding a font size, check whether one of the six fits.
