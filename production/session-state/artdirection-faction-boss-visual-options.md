# Faction / Boss Visual Distinction — Options (scratch, no decision made)

## Confirmed current state (`src/client.html` grep, 2026-09-09)
- `.unit.p` (ally): bottom border `3px var(--cc)` (class color) + `--cc`-tinted gradient bg.
- `.unit.e` (enemy): top border `3px var(--dmg)` (crimson `#ff6b6b`) + flat `--pan-hi` bg, no tint.
- `.unit.big` (boss): only adds width; `border-color:var(--dmg)` — **identical red** to any regular enemy. Map-node boss preview (`.n_boss`) also uses `border-top-color:var(--dmg)`. Elite already gets its own hue (`--burn` orange) — precedent for hue-only faction/tier coding, itself unaddressed a11y debt.
- `.bossdesc` (flavor text) exists on the boss card today but with no banner/frame treatment — same typography as any status text.
- HP fill (`--hp-full/low/crit`) is **intentionally** %-based, identical both sides — this is the live fix for audit finding P0-3 (`UIUX_AUDIT_v0.9.md`), confirmed by code comment "`mã hoá % HP, không mã hoá phe`". Enemies previously had a fixed danger-red fill that masked their true HP%. **Do not re-couple HP fill to faction** — that regresses a fixed bug. Faction must be encoded elsewhere.

## Faction options (CSS-only, reuse `--acc` gold / `--dmg` crimson / `--cc` class colors)

| # | Option | Mechanism | Cost | A11y risk |
|---|---|---|---|---|
| A | Corner badge icon | New 8x8 `IC_G` icon (shield=ally, skull=enemy), tinted `--acc`/`--dmg`, corner-pinned like existing `.pasdot` | Low — 1 CSS class + 2 icons, follows existing icon pattern | Low — pairs shape+color |
| B | Frame-shape asymmetry | Ally keeps rounded corners; enemy gets squared top corners (`border-radius` override) | Very low — CSS only | Low, but subtle at a glance alone |
| C | Directional tint | Enemy gets a corner-vignette gradient (mirrors existing `.unit.p` `color-mix()` gradient but different shape/direction, not just hue) | Low — reuses existing gradient technique | Medium if used alone (still hue-led) |
| D | Text chip ("YOU"/"FOE") | New pill, always visible | Medium — adds density to an already-audited-for-density card | Lowest (text is color-independent) |

**Recommendation to consider:** A+B together (icon + shape) gives a colorblind-safe pair at low cost; C is a nice-to-have layered on top, not a substitute; D conflicts with the 2026-09-01 chip-density pass.

## Boss escalation options (reuse `BOSS_ART`/`sprMon()`, no new sprite)

| # | Option | Mechanism | Cost |
|---|---|---|---|
| 1 | Crimson+gold name banner | Promote `.bossdesc`/name into a title-plate strip (crimson bg, gold text) above the portrait, reusing the `.nbn`/`.nd` pattern already shipped on the map-node boss preview but currently absent from the live combat card | Low — CSS + moving an existing element |
| 2 | Screen-level vignette | Radial crimson scrim behind the boss card only, toggled via a class on `scCombat()` when `u.boss`, reusing the layered-gradient technique already used by `#bgLayer` | Medium — needs one JS class toggle, still CSS-only visuals |
| 3 | Pulsing crimson ring | Same technique as `.unit.p.echo5`'s pulse box-shadow, mirrored for bosses as an ally-side "prestige" ↔ boss-side "danger" visual metaphor | Low — CSS only; must use distinct timing/color from `.unit.acting` so a boss doesn't look permanently "mid-action" |
| 4 | Ornate portrait ring only | Double-ring gold/crimson frame around `.spr` (not the whole card), removing `.mut` tint on boss art (partially already done via `.real`) | Low — CSS `::before`/`::after` only, zero new art |

No option here has been chosen — flagging 1+3 as the cheapest combo (banner + ring) if the product owner wants an escalation pass in the same PR as the faction fix, since both reuse patterns (`.nbn`, `.echo5`) already proven in this codebase.
