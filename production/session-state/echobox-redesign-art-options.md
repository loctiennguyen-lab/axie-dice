# Echo Box Redesign — Visual Options (no code, no winner picked)

## What already exists (confirmed via `src/client.html`, `scEchoBox()` ~3678)

- **Pool art is already real**, not generic icons: `echoShowChip()` renders
  `item.src||item.img` (actual cosmetic thumbnails) in a rarity-bordered
  `.echoshow.rN` chip (`--r0..--r4`), with swatch/pill fallbacks for
  style-only/text-only items. `echoHeroPicks()` flattens top-3-per-category
  into one wrapped strip — pools aren't visually grouped today.
- **Rank already has real treatment**: `.echorank-name` in `--acc` gold +
  the shared `.bpbar` progress component (same bar used elsewhere in-game,
  not bespoke).
- **The pull button already glows**: `.echopull.glow` / `@keyframes
  echopullGlow`, 2.2s ease-in-out, gated by `wantsLessFlash()` in JS AND a
  `prefers-reduced-motion` CSS fallback. It's thinner than `.unit.p.echo5`'s
  `echo-eclipse-pulse` (single soft shadow vs. ring + dual gold/purple
  layering) but already shares echo5's exact 2.2s timing.
- **Fuse panel and pull log are already plain stacked sections** (`.fusepanel`,
  `.colsec`), always visible, no demotion mechanism.
- **Two reusable patterns already exist elsewhere** — no new component
  needed: a 2-way tab switch (`.cfgrow` + `.btn.sm.on`, used in
  scAccount login/register) and an inline-expand accordion (Set-based
  expanded state, used in Vault chips / Leaderboard / History rows).

## Option 2 — Hero moment for OPEN ECHO BOX

- **A. Upgrade existing glow only** — swap `echopullGlow`'s box-shadow
  values for echo5's fuller ring+dual-color recipe; timing already matches.
  Cost: LOW (CSS value swap, no new state).
- **B. Featured single-pool banner card** above the flattened strip
  (enlarge the rarest/newest pickup) using existing thumbnail art. Cost:
  MEDIUM (new "featured pick" logic + card CSS, no JS pull-logic change).
- **C. A + B combined**, banner sitting directly behind/above the glowing
  button so art + glow read as one focal unit. Strongest Genshin-echo
  feel; highest coordination cost (two elements must share visual weight).
  Cost: MEDIUM-HIGH.

## Option 3 — Demote FUSE DUPLICATES / PULL LOG

- **A. Tab switch** (reuse `.cfgrow`/`.btn.sm.on` exactly): "FUSE" / "LOG"
  toggle swaps panel content under the pull button. Cost: LOW — one new
  state var, zero new CSS.
- **B. Accordion** (reuse Vault/Leaderboard's Set-based expand pattern):
  both sections start collapsed as headers, click to expand inline. Keeps
  both scannable at a glance; costs more vertical space than a tab. Cost:
  LOW-MEDIUM.
- **C. Side rail** (2-column layout, pull hero ~65% left / fuse+log
  narrow right rail, ≥1200px breakpoint only, stacks on mobile). No
  existing 2-column pattern in this screen family to reuse. Cost: HIGH.

## Cost summary

| Option | Effort | Reuses existing pattern? |
|---|---|---|
| 2A glow upgrade | Low | Yes (echo5 recipe) |
| 2B featured banner | Medium | Partial (art yes, layout no) |
| 2C banner+glow combo | Medium-High | Partial |
| 3A tabs | Low | Yes (scAccount tabs) |
| 3B accordion | Low-Medium | Yes (Vault/Leaderboard) |
| 3C side rail | High | No |
