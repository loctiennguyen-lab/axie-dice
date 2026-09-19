# Claude Code Game Studios -- Game Studio Agent Architecture

Indie game development managed through 49 coordinated Claude Code subagents.
Each agent owns a specific domain, enforcing separation of concerns and quality.

## Technology Stack

- **Engine**: Godot 4.7.2 — chosen 2026-09-17/18, confirmed as the project's primary direction
  going forward on 2026-09-18 ("Godot chính là main" — see below). The `src/` vanilla-JS/HTML5
  build (`.claude/docs/technical-preferences.md`'s old "Custom — no engine" entry) is the
  **legacy/live production build**, kept running as-is (real players, ranked leaderboard) until
  the Godot port reaches feature parity + an anti-cheat/replay-verify equivalent — see
  `production/session-state/godot-port-active.md` backlog. New feature work happens in `godot/`.
- **Language**: GDScript
- **Version Control**: Git — work happens on branch `godot-port` (not yet merged to `main`;
  `main` still serves the live JS build's deploy pipeline, see `production/session-state/active.md`)
- **Build System**: Godot's own editor/export pipeline (`godot/project.godot`); no separate
  build step for iteration (`godot --path godot` runs directly)
- **Asset Pipeline**: `godot/assets/`, `godot/addons/axie_mixer_3d*` (3D Axie renderer),
  `third_party/` (vendored upstream asset packages, e.g. `axie-3d-assets`,
  `godot-axie-mixer-3d-main` — kept as delivered, only the needed files are copied into
  `godot/assets/`/`godot/addons/`)

> **Godot-first, JS-legacy note (2026-09-18)**: this project's Godot port
> (`design/gdd/godot-port-rule-spec.md`, architecture at
> `/Users/loc.tien.nguyen/.claude/plans/mellow-scribbling-mochi.md`) is now the primary
> development target — **not** an experiment or a parallel prototype. Route new gameplay/UI/
> content work to `godot/` and the generic engine-agnostic agents (`gameplay-programmer`,
> `ui-programmer`, `lead-programmer`) rather than reviving JS-side work, unless a task explicitly
> targets the still-live `src/` build (bugfixes, ranked-leaderboard integrity, deploy). The
> Godot `godot-port` branch has **not** been merged into `main` and the live JS deploy is
> **unaffected** — this is a documentation/direction update, not a branch/deploy change (see
> `production/session-state/godot-port-active.md` for the full current-state backlog and the
> reasoning for keeping them separate for now).

> **Note**: Engine-specialist agents exist for Godot, Unity, and Unreal with
> dedicated sub-specialists — this project uses the Godot set
> (`godot-gdscript-specialist`, `godot-specialist`, etc.) going forward.

## Project Structure

@.claude/docs/directory-structure.md

## Engine Version Reference

@docs/engine-reference/godot/VERSION.md

## Technical Preferences

@.claude/docs/technical-preferences.md

## Coordination Rules

@.claude/docs/coordination-rules.md

## Collaboration Protocol

**User-driven collaboration, not autonomous execution.**
Every task follows: **Question -> Options -> Decision -> Draft -> Approval**

- Agents MUST ask "May I write this to [filepath]?" before using Write/Edit tools
- Agents MUST show drafts or summaries before requesting approval
- Multi-file changes require explicit approval for the full changeset
- No commits without user instruction

See `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md` for full protocol and examples.

> **First session?** If the project has no engine configured and no game concept,
> run `/start` to begin the guided onboarding flow.

## Coding Standards

@.claude/docs/coding-standards.md

## Context Management

@.claude/docs/context-management.md
