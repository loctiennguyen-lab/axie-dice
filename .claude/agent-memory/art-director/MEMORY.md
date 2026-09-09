# Art Director Memory Index

- [Axie Dice Tactics project context](project_axie-dice-tactics.md) — browser DOM/CSS game; DOES embed real bitmap art (base64) alongside pixel sprites and an SVG icon system. See 2026-09-07 correction, 2026-09-08 Chimera kit duplicate-file warning, 2026-09-09 faction/boss visual-gap finding (HP-fill-is-%-based-not-faction is intentional, don't undo it), 2026-09-09 World Tour map finding, and 2026-09-09 Echo Box gacha-screen finding, inside.
- [Icon system technical pattern](reference_icon-system-pattern.md) — how `IC_G`/`FT_IC`/`icoSvg` work, so new icon proposals stay implementation-compatible.
- [Real-art integration pattern](reference_real-art-integration-pattern.md) — `realArtWrap()`/`⛓ NFT` badge is scoped to player-owned Vault Axies only; don't reuse it for a general art reskin.
- [Reusable UI switch patterns](reference_ui-switch-patterns.md) — existing tab-switch (`.cfgrow`+`.on`) and inline-expand accordion (Set-based) patterns; check before proposing a new toggle/collapse UI.
- [Orchestrator background-task collaboration mode](feedback_orchestrator-collaboration-mode.md) — when a subagent invocation waives the file-write approval pause, and when it doesn't.
