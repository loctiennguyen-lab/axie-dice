---
label: wayfinder:task
status: resolved
claimed_by: null
blocks: []
blocked_by: []
created: 2026-09-18
---

## Question

Not a decision — this is the data-gathering work the RunMap tuning decision (see
"Not yet specified" on the map) is waiting on, per the architecture plan's checklist
step 5.

The user already decided the row count must go up from the old JS 12/20-step lengths
(bossSteps force 3-4 convergent rows; the branching graph needs room around those to
not fracture into disconnected segments). What's still unmeasured: the actual
row-count, `TUNE.base`/`growth` curve, K (minimum distinct-path count), and how
Ascension≥9's extra-elite placement maps onto the new graph (forced row vs. avoidable
node).

AFK task: run `tools/sim.js` (and/or the Godot-side `run_map_generator.gd` once it
exists) across a spread of candidate row-counts and growth curves, holding the
existing `budget(pw)`/`count(pw)` formulas fixed (already verified compatible with a
branching graph in the rule spec — `pw` accrues per node regardless of type, so budget
at the boss is path-independent). Produce a short comparison table: row-count/curve
combo → resulting difficulty curve, path-count, and whether the 10 invariants in
`godot-port-rule-spec.md` §7 hold.

Resolve this ticket by posting that data. It unblocks (graduates) a new Grilling
ticket to actually lock in the numbers with the user — don't decide the numbers here,
just produce what's needed to discuss them.

---

## Resolved 2026-09-19 — data, and the decision it unblocked

### Measured

`budget(pw)` is driven by nodes COMPLETED, so a longer map raises every encounter. Comparing
each boss against the live JS build, at the original `growth` 1.15:

| boss | JS row/pw → budget | Godot row/pw → budget | delta |
|---|---|---|---|
| #1 | r4 / pw3 → 16.0 | r6 / pw5 → 21.1 | +32% |
| #2 | r8 / pw7 → 27.9 | **r12 / pw11 → 48.9** | **+75%** |
| #3 | r12 / pw11 → 48.9 | r18 / pw17 → 71.7 | +47% |

FULL mode: +52% / +68% / +48% / +63%.

**The project's recorded "+34%" was wrong**, and wrong in a way that hid the real problem. It
read `pw` at the final boss as 18 — the row number — when `power_level` counts nodes already
completed and is 17 there. The true final-boss figure is +47%, and the final boss was never the
worst case: the **mid-boss was +75%**, met by a team that has not had time to tier up.

### Map structure (300 seeds × 2 modes, real generator)

| | short (18 rows) | full (30 rows) |
|---|---|---|
| nodes per graph | 32–40, avg 34.1 | 55–65, avg 59.0 |
| widest row | 2–3 | 2–3 |
| generator retries | **0** | **0** |
| hard failures | **0** | **0** |

The graph itself needs no attention. Every one of the 10 invariants holds on every seed without
a single retry, so the row count is not what needs changing — the curve is.

### Candidate curves, against the auto-player

`t_full_run_loop` drives a deliberately weak auto-player (never rerolls, never plays a relic)
over four seeds. Read the result as a relative gauge between curves, **not** as a win rate.

| growth | boss #1 / #2 / #3 vs JS | auto-player |
|---|---|---|
| 1.100 | +6% / +7% / −14% | 4 wins / 0 deaths |
| 1.115 | +13% / +24% / +1% | 2 wins / 2 deaths |
| **1.125** | **+18% / +37% / +13%** | **2 wins / 2 deaths** ← chosen |
| 1.135 | +24% / +51% / +25% | 2 wins / 2 deaths |
| 1.150 | +32% / +75% / +47% | 0 wins / 4 deaths (original) |

The curve that matched JS most closely on paper (1.100) produced a game a player doing nothing
right still wins every time. 1.115–1.135 form a plateau on this measure; the user chose 1.125.

### Applied

`ContentDB.TUNE.growth` 1.150 → **1.125**, with the table above recorded at the constant. No
other knob touched: `base`, `growth2`, `knee`, `elite_mult`, the row counts and the boss rows
are all unchanged, and `budget(pw)`/`count(pw)` are untouched as the ticket required.

### A real bug this surfaced

Softening the curve let runs reach row 18 for the first time, and that immediately threw:

```
SCRIPT ERROR: Invalid access to property or key 'poison' … status_engine.gd:114
```

`DamagePipeline.check_boss_phase()` resets a boss's `status` to `{}` on the flip to phase 2.
`StatusEngine.tick_status()` then read `u.status["poison"]` directly — the key the phase change
had just removed. Poisoning agony to death aborted the status tick, so **every unit queued
after it that turn lost its burn, regen and decay**. Pre-existing; only unreachable because the
auto-player had never survived that far. Fixed, with a regression test in `t_boss_encounters`
that was verified to fail (2 failures) with the fix removed.

### What this ticket does NOT settle

Per its own instruction, the numbers here are data, not a decision about K (distinct-path
count) or the Ascension≥9 extra-elite placement. Both remain open. The row counts are now
evidence-backed as *fine* — the generator never strains — so the graduated grilling ticket
should be about the curve and elite placement, not about row count.
