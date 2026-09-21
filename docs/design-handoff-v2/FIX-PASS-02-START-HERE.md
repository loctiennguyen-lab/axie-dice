# START HERE — Axie Dice UI fix package

Prepared 2026-09-20 from a read of the actual GDScript in `godot/`, plus the QA captures.

## What is in here

```
godot/RENAME-TO-CLAUDE.md          → rename to godot/CLAUDE.md   (loaded every Claude Code session)
godot/scenes/shared/DangoScreen.gd → new file, drop in as-is
godot/tests/t_ui_laws.gd           → new file, drop in as-is
FIX-PASS-02.md                     → root causes + per-screen work
reference/target-screens/*.png     → what each screen is supposed to look like
reference/FIX-PASS-01-superseded.md → previous pass, kept for history only — do not work from it
```

The three files under `godot/` mirror the repo layout. Copy the tree over `godot/`, then rename
`godot/RENAME-TO-CLAUDE.md` to `godot/CLAUDE.md`.

## What to tell Claude Code

> Read `godot/CLAUDE.md` and `FIX-PASS-02.md`. Do §1 of FIX-PASS-02 first, in order, and stop
> after it: keep `stretch/aspect="expand"`, delete `panel_style()` / `BG_PANEL` / `BG_PANEL_SOFT`
> from `DangoTheme.gd` and fix every resulting compile error with `surface_style()`, extend
> `gen_theme.gd` per RC5 and regenerate `dango.tres`, then route every scene through
> `DangoScreen.build()`. Run `tests/t_ui_laws.gd` and report which laws still fail. Do not start
> §5 or §6 until §1 passes.

Work one section per task, not the whole file at once. Ask for the report at the end of each —
the rule in `CLAUDE.md` is that unfinished items get named, not silently skipped.

## Order

1. §1 — the four foundation changes. Nothing else can be verified before this.
2. §3 — the nameplate (`UnitPortrait.gd`, `UnitHeadHUD.gd`). One size, 196×64, party and enemy.
3. §5 — Codex. Currently the only screen in the game with no styling at all.
4. §6 / §6b / §6c — Combat, Run Map, and the reward/shop/event/treasure overlays.
5. §4 — everything else in the scene inventory, in table order.
6. §8 — the done checklist, re-captured at two different window sizes.

## Two files still to come

`UnitPortrait.gd` and `Codex.gd` are specified in §3 and §5 but not yet written out as source.
Ask for them if Claude Code's own versions miss again.
