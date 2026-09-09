---
name: reference-ui-switch-patterns
description: Two reusable state-toggle UI patterns already implemented in src/client.html (tab switch, inline-expand accordion) — check these before proposing a new toggle/collapse mechanism
metadata:
  type: reference
---

Before proposing a new tab bar, segmented control, or collapsible panel for
any screen in `src/client.html`, check these two existing patterns first —
both are proven, reuse existing CSS, and need no new component:

- **2-way tab switch**: `.cfgrow` wrapping two `.btn.sm` buttons, active one
  gets `.on`. Toggles a plain JS state var + `render()`. Example: `scAccount`
  / `buildAuthForm()`'s LOG IN / REGISTER toggle (`acctMode`). Cost: lowest —
  one state var, zero new CSS.
- **Inline-expand accordion**: a `Set` of expanded keys (e.g. `vaultExpanded`,
  `historyExpanded`, Leaderboard's row-expand set) toggled on click; expanded
  rows render extra detail inline, nothing navigates away. Keeps content
  scannable as headers first. Cost: low-medium — needs a Set + toggle
  function, no new CSS component.

Used in the 2026-09-09 Echo Box gacha-screen redesign options
([[project_axie-dice-tactics]]) to demote FUSE DUPLICATES / PULL LOG without
inventing a new mechanism. Re-verify both patterns still exist at their cited
call sites before recommending them again — this is a snapshot of
2026-09-09's `client.html`, not a guarantee.
