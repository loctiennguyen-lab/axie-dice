# Chimera Monster Art Mapping — DRAFT

**Status: DRAFT — proposal only, not yet implemented or approved.** This is a
curation pass for the product owner to review/adjust. No code has been changed.
Once a final table is signed off, wiring the chosen files into `src/client.html`
(replacing `MON_SPR`/`monArt2()`'s Hero-reskin fallback with real per-monster
art) is a separate implementation task for `technical-artist`/`ui-programmer`.

**Revision 2026-09-08:** the product owner reviewed the original 21-pick
table and returned 4 decisions. This revision applies them: `cleaver` and
`e_plague` are re-sourced from newly-available master-kit material (§2/§3),
`egg` now has a real pick instead of the Hero-reskin fallback (§4),
`machito`/`shilin` exclusion is confirmed unchanged (§5), and §1's
duplicate-file claim is corrected after an actual hash check disproved most
of it. Every pick not named above is unchanged from the original pass.

## Scope

- Covers every **regular/elite monster key** in `MON_SPR` (`src/client.html:2826`)
  that is **not** one of the 6 boss keys (`gooey_king, mecha, frost_lord,
  plague_mother, mirror, agony` + `agony2`). Bosses are explicitly untouched —
  their art was locked in a prior session and stays exactly as-is.
- 17 normal-tier keys + 4 elite keys = 21 assignments below, plus `egg`
  (resolved 2026-09-08, real pick — see §4), for 22 total assignments.
- Source art: 75 PNGs in `Chimeras/` (22 creature families, numbered
  `-01-00.png` through `-04/05-00.png` variants per family), cross-referenced
  against `pve-chimeras.json` for each family's in-game name and
  ability/passive naming (e.g. `aqua-slime-def` = `"OldSlime"`, passive
  `greasy_scoundrel`) where that added useful signal.
- Every file below was opened and visually inspected directly — none of this
  table is inferred from filenames alone.
- **Added for this revision (2026-09-08):** two more folders from the product
  owner's master kit, not available during the original 21-item pass —
  `Portraits/` (22 single-portrait mascot/icon renders, one clean canonical
  image per creature family) and `Starters/` (19 numbered "Starter Axie"
  avatar files) — consulted specifically for the `cleaver`/`e_plague`
  re-source and the `egg` pick below.

## 1. Data-quality note — corrected 2026-09-08

The original pass through this section claimed a large number of files were
**byte-for-byte identical** to differently-named files elsewhere in the set,
and printed a table of alleged duplicate clusters spanning roughly 15 file
groups across 8+ creature families. **That claim was an overclaim, and the
table has been removed.** It was written from visual inspection alone — this
agent has no Bash/shell access and cannot hash-compare files — and the
orchestrating session has since run an actual md5 comparison. Result: most
of the claimed duplicate clusters are **false**. For example,
`daddy-bear-01-00.png` and `mommy-bear-01-00.png` were claimed identical;
they in fact hash completely differently and are genuinely different image
files (this matters directly — see the corrected `cleaver` pick in §2,
sourced from `daddy-bear-01-00.png` on its own merits).

Only **one** exact, confirmed duplicate exists anywhere in the set:
`flowering-treant-01-00.png` and `treant-03-00.png` are byte-identical.
Neither file was used anywhere in this table, so this doesn't affect any
pick, then or now.

What was likely actually going on, and what produced the original
"duplicate" impression: a number of files across different creature families
genuinely **are** visually similar or share a template — same composition,
palette, or pose, recolored/re-rendered per family (e.g. several families
each have a "silhouette against a full moon on a mountain peak" wolf image;
`daddy-bear-01` and `mommy-bear-01` both show a near-identical dark horned
creature with a sword and shield). That's a real production pattern in this
kit, and it reads as "familiar" on a quick look — but "looks familiar" is not
"is byte-identical," and the two must not be conflated again in a future
pass.

**Also worth flagging honestly:** while re-examining files for this
revision's three items (§2 `cleaver`, §3 `e_plague`, §4 `egg`), a couple of
unrelated files were opened for comparison along the way and turned out to
show content that doesn't match their row's *written rationale* elsewhere in
this table — not a duplicate-naming issue, a content-description issue.
Example: `bugling`'s chosen file, `aqua-slime-def-02-00.png`, actually shows
a fish/frog creature sliding down a hillside past a flying arrow, not "a
wide-eyed blob-frog resting on a lilypad" as that row currently states.
Re-verifying `cleaver`/`e_plague`/`egg` was this pass's actual scope, so that
row hasn't been touched here — but it's a signal that a fuller content
re-check across all 21 original rows (not just the old duplicate-list) would
be worth doing before `technical-artist` wires any of this into
`src/client.html`.

## 2. Proposed mapping — normal-tier monsters (17)

| Key | Name (role) | Current hint | Chosen file | Rationale |
|---|---|---|---|---|
| `slime` | Gooey Slime (bruiser, weakest) | plant,2 | `slime-02-00.png` | green fish/eel spewing a goo-breath — literal "basic slime" read for the weakest trash mob; hint drops (was only ever a Hero-reskin artifact) |
| `chomper` | Chomper (bruiser) | beast,1 | `gray-wolf-01-00.png` | wolf mid-roar, blood on its teeth — a direct "biting" match, and a wolf is squarely a beast (hint holds) |
| `spikelet` | Spikelet (tank, thorns:3) | reptile,2 | `aqua-slime-atk-01-00.png` | green blob bursting with visible orange-tipped spikes — literal body-match for "Spikelet" and the thorns mechanic |
| `bugling` | Bugling (poisoner, smallest) | bug,0 | `aqua-slime-def-02-00.png` | small, wide-eyed green blob-frog resting on a lilypad — toxic-green, low-key, fits the weakest poison-role unit |
| `jellyfin` | Jellyfin (healer) | aqua,4 | `aqua-wolf-01-00.png` | despite the family name, the art is a finned aquatic dragon-fish by a waterfall — a literal "fin" match, keeps the aqua hint |
| `ravenling` | Ravenling (assassin, pierce) | bird,5 | `dryad-ranger-02-00.png` | a volley of arrows in flight — literal match for a pierce-focused assassin; no bird chimera exists in the kit so the hint can't be kept directly |
| `thornback` | Thornback (tank, thorns:4/cleave) | reptile,5 | `treant-02-00.png` | tree-stump creature roaring as spears/thorns fly at it — literal thorn imagery, escalated combat-worn tank vs. spikelet |
| `venomaw` | Venomaw (poisoner) | bug,4 | `dryad-fighter-03-00.png` | large clawed hand dripping green venom, ominous silhouette — the strongest toxic-color signal in the kit, fits a biting/clawing poison dealer |
| `bruiser` | Bruiser (bruiser, big) | beast,7 | `daddy-bear-02-00.png` | bear warrior charging with a huge two-handed axe — literal heavy-melee bruiser, bear = beast (hint holds) |
| `hexeye` | Hexeye (mage, debuff-heavy) | bug,7 | `dryad-mage-03-00.png` | dark cosmic swirl with a ghostly clawed hand reaching out — the kit's only "curse caster" art, fits blind/vulnerable/freeze |
| `cleaver` | Cleaver (bruiser, cleave) | beast,4 | `daddy-bear-01-00.png` | **re-sourced 2026-09-08** — dark horned creature gripping a curved gold sword with a raised wooden shield, the clearest actual bladed weapon found in the kit; a stronger literal "cleave" match than the earlier body-slam pick. Pairs with `bruiser`'s `daddy-bear-02-00.png` (two-handed axe) as a second "bear-warrior" beat from the same family — same precedent as the wolf lineage already spanning chomper/stalker/e_ravager |
| `warden` | Warden (healer, biggest, shield+heal+thorns) | plant,7 | `flowering-treant-02-00.png` | mossy stump with a blooming lotus — grove-guardian nurture imagery for the biggest healer/shield hybrid, keeps the plant hint |
| `stalker` | Stalker (assassin, pierce/exec) | bird,3 | `alpha-wolf-01-00.png` | wolf/ram biting into a fresh, bloody kill — an apex predator finishing off prey is a literal match for the "exec" mechanic |
| `pyrewing` | Pyrewing (mage, burn/aoe) | bird,7 | `forest-slime-fighter-04-00.png` | slime detonating in a radiant fiery burst — carries the "burn" damage type via color even without a literal wing; no winged/draconic chimera exists in the kit |
| `broodmaw` | Broodmaw (summoner) | bug,5 | `mommy-bear-04-00.png` | large bear standing beside a small cub in a forest clearing — a parent+offspring pairing is a direct visual metaphor for "summons a minion" |
| `bomblet` | Bomblet (kamikaze, self-destruct aoe) | aqua,7 | `aqua-slime-sup-02-00.png` | creature diving fast down a sunset cliff toward impact — reads as a kamikaze dive |
| `totem` | Chimera Totem (buffer, stationary aura) | plant,4 | `forest-slime-flower-03-00.png` | squat ceramic jar/vessel creature with a glowing flower growing from it — a stationary vessel emanating magic is a literal "totem/idol" |

## 3. Proposed mapping — elite tier (4)

| Key | Name (role) | Current hint | Chosen file | Rationale |
|---|---|---|---|---|
| `e_ravager` | Elite Ravager (bruiser, biggest) | beast,8 | `werewolf-02-00.png` | lone werewolf silhouetted against a full moon on a mountain peak — the most dramatic apex-predator escalation of the wolf lineage already used for chomper/stalker |
| `e_plague` | Elite Plaguebearer (poisoner, biggest) | bug,8 | `aqua-slime-boss-03-00.png` | **re-sourced 2026-09-08** — an ornate toad/frog creature on a lilypad, radiating a cloud of glowing spore-like bubbles from its head — the clearest "toxic gas / plague" visual signal found across both `Chimeras/` and `Portraits/`. Replaces the earlier `aqua-slime-boss-02-00.png` pick, which on a fresh look is a comedic water-jet-vs-hiding-creature scene with no toxic read at all; this file is still distinct from the GOOEY KING boss's own `-05` variant of the same family (different file, not a rule violation — flagged so nobody reads the elite and the boss as sharing art) |
| `e_bulwark` | Elite Bulwark (tank, biggest) | plant,8 | `treant-fighter-02-00.png` | armored wooden warrior taking a volley of arrows and still standing — the armed/armored escalation of the treant tank lineage (spikelet → thornback → e_bulwark) |
| `e_archon` | Elite Archon (mage, biggest) | aqua,8 | `dryad-mage-01-00.png` | calm, ancient frog-mystic on a lilypad haloed by glowing spore-orbs — a composed elder-caster read fits "Archon," deliberately contrasts with hexeye's more frantic curse imagery from the same family |

## 4. `egg` — resolved 2026-09-08

Previously "no confident match, keep Hero-reskin fallback" — nothing in the
75-file `Chimeras/` set reads as an actual egg, hatchling, or small neutral
token, every candidate was a fully grown creature. The product owner
rejected keeping the fallback and pointed at a new source instead:
`Starters/`, 19 numbered "Starter Axie" avatar files from the same official
kit — small, round-badge-framed, cute mascot-style portraits, a different
register entirely from the `Chimeras/` action-pose set.

`egg` is `MON_SPR.egg` (`src/client.html:2826`), used for the **player's own
summoned Axie Egg ally token** (the `r_hivequeen` relic), not an enemy
monster — so the right read for this pick is "small, friendly, basic-looking
Axie avatar," not a fearsome creature. That's exactly the `Starters/`
folder's whole aesthetic.

| Key | Name (role) | Chosen file | Rationale |
|---|---|---|---|
| `egg` | Axie Egg (summoned ally token) | `Starters/1.png` | Small orange/pumpkin-toned creature, big round eyes, blue bow tie, warm palette, in the round starter-badge frame — reads as a friendly, harmless companion rather than a threat, fitting a low-stakes summoned-ally token. This is a low-stakes pick (per the product owner, any reasonable small/cute/neutral file works); `1.png` was chosen partly because it's the file the product owner themselves cited as a sample when describing this folder. |

## 5. Explicitly excluded (resolved)

- **`machito` (all 4 variants) and `shilin` (variants 01–03, `-04` is the
  MECHA boss's file).** Excluded entirely. Every non-boss variant of these two
  families is a comedic/flavor vignette (sleeping in bed, eating, a fiesta
  dance, a hit-reaction close-up, a weapon-VFX-only shot) — no combat-ready
  creature pose exists outside the one already claimed by the boss. Recommend
  leaving both families unused for regular monsters; `machito` ends up as the
  one fully spare family out of 22 (21 were needed), which is expected, not a
  gap.
- **Other unused files, noted so nobody re-derives them from a filename
  later:** `dryad-ranger-01` (vine wreath, no creature), `dryad-mage-02` (teal
  vortex, no creature), `treant-fighter-03` (a shield/plank VFX shot, no
  creature), `flowering-treant-03` (two unrelated resting creatures, doesn't
  match "flowering treant"), `werewolf-03` (a gauntlet-like object on a
  vehicle, unclear what it depicts), and the two 4-way/2-way duplicate
  clusters in §1 with "no creature visible." None of these were used above.

## 6. Status — all 4 original open questions resolved (2026-09-08)

1. ~~OK with `cleaver`/`e_plague` as medium-confidence picks?~~ Re-sourced,
   see §2/§3.
2. ~~OK excluding `machito`/`shilin`?~~ Confirmed, see §5.
3. ~~OK leaving `egg` on the Hero-reskin fallback?~~ Rejected — real pick
   assigned, see §4.
4. ~~Re-verify the §1 duplicate list against the master kit?~~ Done — see §1;
   the claim was mostly false and is corrected in place.

**One new item surfaced while doing the above** (§1, "also worth flagging
honestly"): `bugling`'s row description doesn't match what its chosen file
(`aqua-slime-def-02-00.png`) actually shows. This table's 21 original rows
were written in one earlier pass and have NOT been re-verified end to end —
only `cleaver`/`e_plague`/`egg` were in this revision's scope. Recommend a
full content re-check of every row (not just the ones touched here) before
`technical-artist` wires any of this into `src/client.html`, since at least
one description/file mismatch is now confirmed to exist somewhere in the
untouched rows and there may be others.

## 7. Implementation note (not part of this proposal)

This project doesn't use discrete per-asset files with the studio's generic
`[category]_[name]_[variant]_[size].ext` naming convention — real art here is
embedded as base64 and looked up by JS object key, the same pattern as the
existing `HOUSE_ART`/`BOSS_ART` objects (see `src/client.html:2826-2845`,
`.claude/agent-memory/art-director/reference_real-art-integration-pattern.md`).
The natural target for this table, once approved, is a parallel `MON_ART`
object keyed by monster key (e.g. `MON_ART.slime`), consumed by a
`monArt2()`-equivalent that **does not** route through `realArtWrap()` /
the `⛓ "Real Axie NFT art"` badge — these are non-owned field monsters, not
player-owned Vault Axies. That implementation is out of scope for this
curation pass.
