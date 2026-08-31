# UX Spec — Combat Log (T15)

> **Status**: Designed, pending implementation
> **Author**: ux-designer (2026-09-01)
> **Priority**: #1 in `docs/review-2026-08-31.md` UX findings — higher than the onboarding hint bar, because this game's entire value proposition is transparency ("Không có gì trong game này bị giấu khỏi bạn") and there is currently no persistent record of what happened in combat, which breaks that promise specifically for players who lose and want to know why.

## 0. What the engine actually emits

`src/engine.js` pushes typed events via `EV(s,{...})` into `s.ev`:

| `t` | Fields | Fired when |
|---|---|---|
| `use` | `uid, side, tgt, aoe` | A unit executes its rolled face |
| `hit` | `src, uid, v, crit` | Damage lands (also Thorns reflect, `src`=unit that got thorned) |
| `ft` | `uid, txt, cls, big` | Floating-text moment — `cls` is `dmg`/`heal`/`shd`/`poi`/`man`/`buf`/`deb` |
| `hp` | `uid, hp, maxHp, shield` | HP/shield bar sync (fires after most other events) |
| `death` | `uid` | Unit reaches 0 HP |
| `eact` | `uid` | Enemy acting (no `use` precedes enemy innate abilities) |
| `tick` | *(none)* | Status-tick turn boundary |
| `phase` | `uid` | Boss phase transition |

**Implementation constraint**: `src/fx.js` `playEvents()` does `const evs=S.ev.slice(); S.ev=[];` — it drains `s.ev` every frame. The combat log must tap the same `evs` array `playEvents()` captures (or subscribe to `EV()` directly), not read `s.ev` after the fact.

## Detailed Rules — Information Architecture

The raw stream is too granular for 1:1 display (one die-use can emit 4-6 events). The log **compiles**, one line per action: start a new entry on `use`/`eact`, keep appending `hit`/`ft`/`death` until the next `use`/`eact`/`tick`.

| Raw event(s) | Compiled log line |
|---|---|
| `use` (uid, tgt) | Opens line: `<Actor> (<Part>) → <Target>` (or `→ all` if `aoe`) |
| `hit` (v, crit) | `· N dmg` or `· CRIT N dmg`; if a prior shield absorbed part of it, append `(M blocked by Shield)` |
| `ft` cls=`dmg` | Folded into `hit` line (source of truth is `hit.v`, `ft` only drives crit/big styling) |
| `ft` cls=`heal` | `· +N HP` |
| `ft` cls=`shd` (+N) | `· +N Shield` |
| `ft` cls=`shd` (-N) | Folds into the `hit` line as `(N blocked by Shield)` |
| `ft` cls=`poi` | `· Poison +N` (apply) or `· N Poison damage` (tick) |
| `ft` cls=`man` | `· +N Mana` |
| `ft` cls=`buf`/`deb` | `· <plain-language status>` via a raw-text→phrase lookup table |
| `death` | `· ☠ defeated` suffix, bold/colored, heavier divider after |
| `phase` | Full-width banner: `⚡ <Boss> enters Phase 2` (not folded into a normal line) |
| `tick` | Thin divider row: `— Turn N —` |
| `hp` | Not its own line (rendering signal) — **exception**: if it arrives with no `use`/`eact` open (e.g. passive regen), synthesize `<Unit> · regen +N HP` |
| `eact` | Opens an entry like `use`, for innate/no-target enemy actions; also the actor-attribution fallback when `hit.src` is null (area effects) |

**Face/part lookup**: `use` doesn't carry which face/part was used — the log-compiling code looks it up via `u.die[u.rolled]` at the moment `use` fires (valid because `.rolled` doesn't change until the next ROLL phase).

**Example**:
```
Turn 4
  Chomper (Horn) → Sprout · 8 dmg (5 blocked by Shield)
  Sprout (Back) → self · +6 Shield
  Gooey Slime → Fry · 5 dmg · Poison +2
— Turn 5 —
  Fry · Poison 2 damage
  Mecha Beetle enters Phase 2
```

## Detailed Rules — Interaction

- **Toggle, default closed.** Header button `LOG`, same family as `UNDO`/`1x`/`2x`/`3x`/`INFO`/`SET`. State remembered in `localStorage` — a player who opens it once wants it open every future combat.
- **Newest entries at top**, prepend above — avoids fighting read position, unlike bottom-anchored auto-scroll.
- **Never steal manual scroll position.** If the player has scrolled into history, new entries do not snap them back — show an unread pill (`• 6 new ▲`) instead. Auto-jump-to-top only when already at scroll position 0.
- **Persistence scope: current combat only**, cleared at next wave/combat start (matches HP reset between waves).
- **Defeat is the one required exception — freeze the log, auto-open it, keep it accessible through the defeat/retry screen as a "Battle Report."** This is the actual payoff of the feature — the ticket exists because players who lose can't verify why; clearing the log the instant defeat triggers would defeat the point.
- Full-run history retention across multiple combats is explicitly out of scope for this pass (would be scope creep beyond T15).

## Detailed Rules — Accessibility

- Container: `role="log" aria-live="polite"`, always in the DOM, toggled via `max-height`/`opacity` — never unmounted, matching existing panel/modal conventions in the codebase.
- **Separate the visible log from the screen-reader announcement channel.** Per-event `aria-live` at 3x/hold speed would flood a screen reader worse than the 0.6s floating-text problem this ticket fixes. Two consumers, two rates:
  - Visible log: one compiled entry per action, appended instantly, any speed.
  - A visually-hidden `aria-live="polite" aria-atomic="true"` region batches multiple compiled entries into one sentence, updated at most every ~400ms even during hold-to-fast-forward (e.g. *"Turn 4: Chomper dealt 8 damage to Sprout, 5 blocked by shield..."*). This is throttling for the ARIA channel only — the visible log stays complete.
  - Death/defeat still routes through `polite`, not `assertive` — interrupting mid-sentence is worse than a half-second delay, matching the game's "you had the information" ethos over alarm-style interruption.
- No color-only encoding — crit/dmg/heal/shield entries need a text/icon marker alongside color (reuses `fx.js`'s existing float-class icon+color pairing).
- **Font size**: log line body uses `--t2` (13px), accepted as an approved density exception for this list context — matches the precedent already set by `.cxtd` table cells, which also use `--t2` despite the general L2 sentence-text rule preferring `--t3` (15px). Revisit if a playtest shows readability issues; not blocking for the initial spec.

## Detailed Rules — Speed-Slider Interaction

Per `src/fx.js`, `SPD`/`skipHold` only govern `wait()` timers between animation beats — they do not affect whether events exist or arrive.

- **The log's data is always complete, at every speed.** Only visual playback pacing (lunge, flash, floating-number lifetime) compresses at higher speed.
- **The visible log appends synchronously and instantly**, decoupled from `wait()` — cheap DOM append, no need to gate behind animation timing that exists purely for board readability.
- During hold-to-fast-forward, the log may receive a dozen entries within a fraction of a second while board animation is still catching up — expected and desired; it's the mechanism that finally delivers "nothing is hidden" at 3×, unlike floating text which degrades with speed.
- Per-entry insertion: brief opacity fade (~80ms cap), respecting `prefers-reduced-motion`. No smooth-scroll/reflow animation per entry (would visibly strobe at hold-speed).

## Detailed Rules — Visual Placement

Per the combat layout in `AUDIT_AND_SPEC_v1.md` §B8. Board has a fixed 846px minimum width (5×158px dice + gaps + padding per T10's measured breakdown). Tiered placement to avoid ever reflowing the board (would violate the no-layout-shift rule and reopen the Fitts's-law problem already flagged elsewhere as T12):

- **≥1200px desktop with letterbox room** (viewport − 846px ≥ 280px + gap): dock the log outside board bounds, in existing dead space to the right. Zero overlap, zero layout shift — primary target case.
- **900-1199px / 600-899px tablet**: overlay drawer, 280px wide (or viewport-minus-margin on the narrower end), sliding from the right edge, light scrim under just the panel width — not a full-screen dim, since reviewing history shouldn't block glancing at or acting on the board.
- **<600px landscape phone** (portrait already gated behind the rotate-hint): the board's own minimum width leaves no room for a coexisting 280px panel. Log becomes a full-screen modal takeover with an explicit close button, matching existing `.modal`/`.cxpane` behavior.
- **Toggle button**: reuses the existing `.btn` base class (already implements the `::before` 44×44 hit-area expansion) — no new hit-area work.
- **Panel styling**: reuse existing tokens — `background: var(--pan)`, `border: var(--bd) solid var(--line2)`, extending the same selector list already used by `.unit, .die, .pick, .nodecard, .bottombar, .track, .cxpane, .modal` rather than a parallel rule.
- No hardcoded font sizes anywhere in this spec; no `--faint` usage. Log line body `--t2`, timestamps/labels `--t1`.

## Dependencies

- `src/engine.js` event stream (`s.ev`, `EV()`) — the log is a second consumer of data already emitted for `playEvents()`, no new engine hooks needed.
- `src/fx.js` `playEvents()` — must coordinate draining/reading `s.ev` so both consumers see every event (implementation detail, not a design conflict).
- `docs/axiedice-source/uiux/UIUX_IMPLEMENTATION_BRIEF_v1.md` — the 8 UI invariant laws (type scale, no layout shift, tap targets, breakpoints) all apply and are respected above.

## Acceptance Criteria

- **GIVEN** a combat with 20+ die-uses, **WHEN** the player opens the log, **THEN** every action appears as one compiled line in the correct compiled format (not raw events).
- **GIVEN** a run ends in defeat, **WHEN** the defeat screen appears, **THEN** the log is frozen, auto-opened, and remains accessible as a "Battle Report" through to retry — not cleared.
- **GIVEN** playback speed is set to 3× or hold-to-fast-forward is active, **WHEN** multiple actions resolve within a fraction of a second, **THEN** the visible log still shows every compiled entry (no dropped events), while the screen-reader channel batches to ≤1 announcement per ~400ms.
- **GIVEN** a screen-reader user has the log open, **WHEN** a new action resolves, **THEN** they receive one polite, throttled announcement — never a flood of per-event announcements.
- **GIVEN** the viewport is ≥1200px with letterbox room, **WHEN** the log is open, **THEN** the combat board does not shift, resize, or reflow.

## Open Questions

- Post-defeat "Battle Report" freeze/auto-open is treated as in-scope for T15 in this spec (it's the feature's actual payoff) rather than deferred — flag if you'd rather split it into a separate follow-up ticket.
- `--t2` vs `--t3` for log line body: this spec accepts `--t2` as a density exception (precedent: `.cxtd`); revisit after a first implementation pass if playtesting shows it's too small.
- Whether victory should also get a brief grace-period log retention before clearing at next-wave start — not addressed here, left as a future nice-to-have if requested.
