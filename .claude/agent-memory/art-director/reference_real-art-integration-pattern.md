---
name: reference-real-art-integration-pattern
description: How real (non-sprite) Axie art is wired into src/client.html today via realArtWrap()/unitArtImg(), and why that specific wrap must NOT be reused for a general house-art reskin
metadata:
  type: reference
---

`src/client.html` has a real-art pipeline built 2026-09-03 for the Vault/
Import-Axie feature, found while writing
`design/quick-specs/real-art-adoption-plan-2026-09-07.md`:

- `HEROES[key].image` (or `vault.image`) holds a data URI of real Axie art.
- `unitArtImg(u,cls)` → `realArtWrap(h&&h.image, sprOf(u.cls,u.artIdx), cls)`
- `realArtWrap()` (`client.html:2607-2617`) wraps real art in a gold frame +
  glow **and a badge reading `⛓ "Real Axie NFT art"`** (CSS at
  `client.html:137-149`, `.axie-id`/`.axie-id-badge`). This badge's entire
  purpose is to mark "this unit is a real blockchain asset the player owns,"
  as a deliberate Gestalt fix (art-director consult, 2026-09-03) for the
  earlier problem of painterly real art and house pixel sprites sitting in
  identical unframed `<img>` slots and reading as broken/placeholder.

**The trap:** if any future work (e.g. a full-roster real-art reskin of
starter Heroes/Bosses/field monsters) sets `.image` on static, non-player-
owned entries and reuses this same function, every one of those units will
render the "Real Axie NFT art" badge and falsely claim NFT ownership that
doesn't exist. This is a UI-semantics bug, not just a visual one — it
renders an ownership claim.

**How to apply:** any future "make everything use real art" work needs a
**second**, parallel wrap (e.g. `houseArtWrap()`/a `.house-art` CSS class)
that keeps the `image-rendering:auto` + rounded-frame treatment but drops the
badge/tooltip entirely. Keep `.image`+`realArtWrap()`+the `⛓` badge scoped
strictly to player-imported Vault Axies (`importAxieToVault`/
`ensureVaultHero`, `client.html:2433-2459`). See [[project_axie-dice-tactics]]
for the fuller Origins-kit review this came out of.
