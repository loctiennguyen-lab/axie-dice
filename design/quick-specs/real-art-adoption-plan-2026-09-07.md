# Real-Art Adoption Plan — Axie Origins Asset Kit (2026-09-07)

Status: DRAFT — planning only, no source files touched this pass.
Author: art-director (consult). Implementation owner (next pass): technical-artist / ui-programmer.

## 0. Why this document exists

Product owner wants to replace ALL current gameplay art (Hero → Boss → field
monster) with real art from the Sky Mavis Axie Origins asset kit (internal
access, same IP as the studio), matching the precedent already shipped in
`src/cosmetics.js` (`COSMETIC_AVATARS`, 59 real portraits/card-art, used today
only for the player's Profile avatar). The game must never surface "this is
Axie Origins art" to the player — it only needs to *look* right.

This plan does not touch `src/client.html` / `src/data.js` / `src/art.js` /
`src/cosmetics.js`. It specifies WHAT to embed and WHERE; the HOW (actual
base64 embedding, CSS, code) is the next pass, owned by `technical-artist`
(asset prep/encoding) and `ui-programmer` (wiring).

## 1. Critical technical finding — do not reuse `.image` / `realArtWrap()` as-is

`src/client.html` already has a real-art pipeline, built 2026-09-03 for the
Vault/Import-Axie feature:

- `HEROES[key].image` (or `vault.image`) — a data URI of real Axie art.
- `unitArtImg(u,cls)` → `realArtWrap(h&&h.image, sprOf(u.cls,u.artIdx), cls)`
- `realArtWrap()` (`client.html:2607-2617`) wraps real art in a gold frame +
  glow AND a small badge reading `⛓ "Real Axie NFT art"` (CSS at
  `client.html:137-149`, `.axie-id-badge`/`.axie-id.real`).

That badge's entire purpose is to tell the player "this specific unit is a
real blockchain asset you own" as distinct from the house pixel-sprite look
everyone else has. If this mass reskin sets `.image` on every static
`HEROES`/`BOSSES`/`MON_SPR` entry through the *same* field and function, every
starter Hero and every Boss will render the `⛓ NFT` badge and claim to be a
real owned NFT — which is false for all of them, and conflates "official
house art" with "player-owned blockchain asset." This is worse than a visual
nit: it is a false ownership claim rendered directly in the UI.

**Recommendation:** introduce a second, parallel field/wrap that reuses the
frame treatment but drops the NFT-specific badge/tooltip entirely:

- New field on `HEROES`/`BOSSES` records, e.g. `.art2` (name TBD by
  `ui-programmer` — avoid colliding with the existing `.image`/`.art` fields).
- New wrap fn, e.g. `houseArtWrap(realSrc, fallbackSrc, imgClass)` — same
  `image-rendering:auto` override and rounded-corner treatment as
  `.axie-id.real img`, but with NO badge element and no "Real Axie NFT art"
  title text. Once real art becomes the *default* look for the whole roster
  (not one imported unit standing out among many sprites), the original
  problem the badge solved — "two incompatible renderings in one unmarked
  slot" — mostly disappears anyway: nearly everything will look painterly.
  A quieter shared CSS class (e.g. `.house-art`, no badge) is enough to keep
  `image-rendering:pixelated` from applying to painterly PNGs.
- `MON_SPR`/`BOSSES` currently hold no per-entry `.image` slot at all — the
  bucketed-reuse table in §3 is the shape that plugs into `sprMon()` /
  `sprOf()` without changing `MON_SPR`'s existing `[class, artIdx]` tuples.

Flagged as an open question for `ui-programmer`/`technical-director` in §4 —
this is the single highest-priority thing to confirm before any embedding
starts, since it is a UI-semantics decision, not just an asset choice.

## 2. HEROES mapping (18 entries) — REVISED 2026-09-07, ground-truth roster

**This revision supersedes the original visual-guess table below entirely.**
Source is no longer the numeric zip extraction (no class metadata, color
guesses) — it is the official `starter_axies_info` roster (Sky Mavis internal
spreadsheet, confirmed by the lead), which lists each of 19 starter Axies with
its ACTUAL class. Confirmed-class portraits for this pass are saved at
`.../scratchpad/drive-starters/` (session-scoped — must be moved into the repo
asset pipeline before implementation, see §5 item 2). No more
High/Medium/Low confidence flags: every row below is class-Confirmed.

**Design decision: one character carries all 3 tiers of its class**, rather
than mixing three unrelated characters per class (which the original table
did — e.g. old beast1/2/3 were three different, unrelated creatures that
merely shared a rough palette). Each of the 6 classes has exactly one starter
character with usable art this session:

- Beast/Plant/Aqua/Reptile (Buba, Olek, Puffy, Machito) each have BOTH a
  Normal portrait and a clean "Awaken" (evolved) portrait — same character,
  more ornate/detailed art.
- Bird/Bug (Momo, Pomodoro) each have ONLY a Normal portrait this session (no
  clean flattened Awaken file exists yet — see roster notes).

Mapping: **tier1 → Normal portrait. Tier2/tier3 → Awaken portrait** where one
exists; where none exists, tier2/tier3 reuse the same Normal file and the
tier1→2→3 visual distinction is carried entirely by CSS (frame/glow/badge
escalation, below) rather than by swapping art. This reads as "this Axie
leveling up" — a stronger Gestalt continuity read for a tier-progression UI
than three unrelated creatures sharing a hue ever did.

| key | current name | character | class | tier1 art | tier2/3 art | note |
|---|---|---|---|---|---|---|
| beast1/2/3 | Cub / Ravager / Alpha Fang | Buba | Beast | Buba-BEAST-confirmed (Normal) | Buba-BEAST-Awaken | |
| plant1/2/3 | Sprout / Bracken / Elder Bramble | Olek | Plant | Olek-PLANT-confirmed (Normal) | Olek-PLANT-Awaken | |
| aqua1/2/3 | Fry / Tidecaller / Abyss Herald | Puffy | Aquatic | Puffy-AQUA-confirmed (Normal) | Puffy-AQUA-Awaken | |
| reptile1/2/3 | Hatchling / Scaleguard / Basilisk | Machito | Reptile | Machito-REPTILE-confirmed (Normal) | Machito-REPTILE-Awaken | character's canonical color is purple, not `CLASS_COLOR.reptile` olive-green — see "Color-identity" note below, do not recolor |
| bug1/2/3 | Grub / Swarmling / Hive Tyrant | Pomodoro | Bug | Pomodoro-BUG-confirmed (Normal — reused for all 3 tiers) | same file | no clean Awaken asset this session; tier2/3 distinction is CSS-only |
| bird1/2/3 | Chick / Skirmisher / Storm Talon | Momo | Bird | Momo-BIRD-confirmed (Normal — reused for all 3 tiers) | same file | **closes the "no Bird art" gap** flagged in the original plan — Momo is a confirmed official Bird starter; retire `AXIE_PIX.bird` pixel-sprite fallback for Heroes once implemented |

All 6 rows: **class Confirmed** (ground truth), replacing every confidence
flag in the original table.

**Color-identity note — Machito (Reptile).** Machito's official art renders
purple, not the olive-green `CLASS_COLOR.reptile` (#8a9a3a) used elsewhere in
the UI. This is the character's real signature color, confirmed by the
roster + product owner — do not recolor the portrait to force it green.
Recommendation: keep `CLASS_COLOR` driving the FRAME/border/glow around the
portrait (as `realArtWrap`/the proposed `houseArtWrap` already do elsewhere),
and let the character's own painted colors show through inside that frame —
the same pattern already used for real NFT Vault Axies, where the frame
follows the mapped game class while the portrait itself stays whatever color
the real art is.

**Tier-escalation CSS ladder** (applies to all 6 classes; proposed, final
values owned by `ui-programmer`/`technical-artist`):
- Tier1: thin frame, no glow, base tier badge.
- Tier2: heavier frame (thicker/gold), soft ambient glow, upgraded tier badge.
- Tier3: thickest/most ornate frame, stronger glow (pulse or particle
  accent), "evolved" tier badge.

This ladder is what carries the tier2-vs-tier3 distinction for Bug/Bird
(identical image across all 3 tiers) and the tier1-vs-tier2/3 distinction
everywhere else — visual hierarchy must not depend on the art alone.

**Asset naming** (per house convention `[category]_[name]_[variant]_[size].[ext]`):
since each class now needs only 1-2 unique source files instead of 3,
propose `char_buba_normal_200.png` / `char_buba_awaken_200.png`,
`char_olek_normal_200.png` / `char_olek_awaken_200.png`,
`char_puffy_normal_200.png` / `char_puffy_awaken_200.png`,
`char_machito_normal_200.png` / `char_machito_awaken_200.png`,
`char_momo_normal_200.png`, `char_pomodoro_normal_200.png` — **10 unique
portrait files now serve all 18 Hero slots**, down from the original plan's
18 unique files (see updated file-size estimate in §5 item 2).

<details>
<summary>Superseded — original visual-guess table (2026-09-07, pre-roster), kept for reference only</summary>

Source was `Avatars/starters/*.png` (200×200, ~30KB each), numeric filenames
only — no ground-truth class metadata was available in this extraction, so
every pick below was a visual read (color palette against `CLASS_COLOR`,
iconography) with a confidence flag, not a certainty. No longer in effect.

| key | current name | proposed file | confidence | reasoning |
|---|---|---|---|---|
| plant1 | Sprout | starters/2.png | High | green blob body, plain/simple — reads as baby-tier plant |
| plant2 | Bracken | starters/20.png | High | green/yellow moss body, bigger & stranger (eyeball) — mid-tier escalation |
| plant3 | Elder Bramble | starters/12.png | Medium | flower/leaf crown carries the plant identity even though palette warms toward pink; most ornate of the three |
| beast1 | Cub | starters/1.png | High | small cat-like face, simple bow tie, cutest/smallest of the beast cluster |
| beast2 | Ravager | starters/11.png | Medium-High | red-orange, bigger, more aggressive expression than beast1 |
| beast3 | Alpha Fang | starters/21.png | Medium | gold/orange, most decorated headpiece of the beast cluster — reads as "elder/alpha" |
| aqua1 | Fry | starters/3.png | High | teal blob, coral horn, water-drop iconography — unambiguous |
| aqua2 | Tidecaller | starters/25.png | High | mint/aqua body, aqua background, more decorated than aqua1 |
| aqua3 | Abyss Herald | starters/18.png | Medium | purple dragon-like face on a water float — indigo body is a stretch, but the aqua staging (float, water background) and "biggest/most powerful of the three" progression carry it |
| reptile1 | Hatchling | starters/17.png | Medium | frog-shaped mouth reads reptilian; palette (pink-red) is the weak point |
| reptile2 | Scaleguard | starters/23.png | Medium | black/white/gold patterned face reads as scale-pattern |
| reptile3 | Basilisk | starters/15.png | Low-Medium | striped dome + ceremonial seal charm — weakest-confidence pick in the Hero table, recommend a second pair of eyes before locking it in |
| bug1 | Grub | starters/7.png | High | magenta/purple body is the closest palette match to `CLASS_COLOR.bug` (#c74fd8) of anything in the kit |
| bug2 | Swarmling | starters/24.png | High | cream body with red heart/spot pattern reads as ladybug — strong bug iconography |
| bug3 | Hive Tyrant | starters/14.png | Low | weakest pick in the whole table — lavender fox-like face, flame-shaped ears; only tenuous link to bug is a purple-adjacent hue. Flagging for replacement if any better bug art turns up |
| bird1-3 | Chick / Skirmisher / Storm Talon | — (no pick) | — | gap — kept pixel sprite |

</details>

## 3. BOSSES mapping (6) + MON_SPR bucketed reuse

### 3a. Bosses — REVISED 2026-09-07: use Chimera card art, not round portraits

**Product owner correction:** Boss art must come from `PvE/Cards/Chimeras/<name>-NN-00.png`
(the dramatic square "card art" style — cinematic pose, action lines, high contrast) for
**all 6 bosses**, not the round `Avatars/portraits/*.png` icon style used for 5 of them in
the original pass below. Card art reads as a boss reveal; portraits read as a roster icon —
wrong register for a boss screen. `agony` already used card art; the other 5 are corrected here.

Every named Chimera in the kit has multiple numbered card variants (`-01-00` through `-05-00`,
count varies per creature) — these are escalating power/story states, confirmed by how `agony`
already uses `werewolf-01` (feral) → `werewolf-04` (full transformation) for its two phases.
For every OTHER boss (single-phase, one fight), this revision picks each creature's **highest
available variant number** — the most powerful/dramatic state on file — since a boss encounter
is already that creature's "final form," not an early one:

| boss key | boss name | trait | proposed file | reuse? | reasoning |
|---|---|---|---|---|---|
| gooey_king | GOOEY KING | split | `Cards/Chimeras/aqua-slime-boss-05-00.png` (highest of 5 variants) | Different variant than `card_aqua_slime_boss` (embedded in cosmetics.js is likely `-01` or `-02` — confirm exact variant before assuming zero-payload reuse) | kit's own filename literally says "boss"; slime identity matches SPLIT (spawns smaller slimes); highest variant = most powerful slime form on file |
| mecha | MECHA CHIMERA | thorns/retaliate | `Cards/Chimeras/shilin-04-00.png` (highest of 4 variants) | No | **searched exhaustively — no robot/mechanical Chimera exists anywhere in the zip's 22-creature roster nor in the broader Drive folder the product owner shared** (checked: full `PvE/Chimeras/` listing, `chimera_abilities` spreadsheet listing all 22 kinds by ability, Drive full-text search for "mecha"/"robot"/"metal"/"steel" combined with "chimera" — nothing). `shilin` (aggressive guardian face, "shocker"/"shield-crusher" abilities per `chimera_abilities` row 68-71) is still the closest "armored guardian that retaliates" read available. **Still needs explicit product-owner sign-off that this stretch is acceptable, or the boss's theme/name may need to change instead of forcing a mismatched reskin.** |
| frost_lord | FROST LORD | freeze | `Cards/Chimeras/aqua-alpha-wolf-02-00.png` (highest of 2 variants) | No | "aqua"-prefixed (cold/water) + "alpha" (pack leader/"Lord") — kit's own naming does the work here |
| plague_mother | PLAGUE MOTHER | summon/poison | `Cards/Chimeras/dryad-mage-04-00.png` (highest of 4 variants) | No | moss/fungus-covered creature with a nest-like bowl on its head reads as corruption + brood/spawn; `chimera_abilities` confirms `dryad-mage` has heal/buff/aoe-debuff kit, fitting a "mother" support-caster read |
| mirror | MIRROR CHIMERA | mirror (copies last move) | `Cards/Chimeras/alpha-wolf-03-00.png` (highest of 3 variants) | No | single oversized eye + skull-mask face — an "uncanny reflection" read fits MIRROR better than a literal mirror image would |
| agony | NIGHTMARE AGONY | two-phase | Phase 1: `Cards/Chimeras/werewolf-01-00.png` · Phase 2: `Cards/Chimeras/werewolf-04-00.png` | **Phase 1 = `card_werewolf` already embedded, zero new payload for that phase** (confirm exact variant matches `-01`) | the kit's 4 numbered werewolf card variants are dramatically different power states — 01 is a bloody feral close-up, 04 is a full electric/lightning transformation. That is an exact visual match for AGONY's existing `die`→`die2` "heals to full and switches to a far deadlier die" mechanic. Only phase 2 (werewolf-04) needs new embedding |

**Note on "reuse — zero new payload" claims above:** `cosmetics.js` already embeds `card_<name>`
entries sourced from this same `Cards/Chimeras/` folder, but the exact numbered variant it used
was not re-verified in this pass — `technical-artist` must confirm which `-NN-00` file
`cosmetics.js`'s `card_aqua_slime_boss` / `card_werewolf` actually contain before assuming this
revision's picks (highest-variant) match byte-for-byte and truly cost zero new payload.

### 3b. MON_SPR — bucketed reuse of the 18 Hero images (no new art needed)

`MON_SPR` already stores `[class, artIdx]` per monster (`client.html:2584`),
and `sprOf(cls,i)` already resolves `i` into a per-class array via `i%9`. The
cheapest, most visually-consistent path is to reuse the **same 18 real Hero
images** for every field monster and elite, bucketed by `artIdx`:

`bucket = floor(artIdx / 3)` → 0 = tier1 art, 1 = tier2 art, 2 = tier3 art.

| MON_SPR key | class, artIdx | bucket → hero art reused | notes |
|---|---|---|---|
| slime | plant, 2 | tier1 → plant1 art (starters/2.png) | also the most literal match by name |
| totem | plant, 4 | tier2 → plant2 art (starters/20.png) | |
| warden | plant, 7 | tier3 → plant3 art (starters/12.png) | |
| chomper | beast, 1 | tier1 → beast1 art (starters/1.png) | |
| cleaver | beast, 4 | tier2 → beast2 art (starters/11.png) | |
| bruiser | beast, 7 | tier3 → beast3 art (starters/21.png) | |
| e_ravager (elite) | beast, 8 | tier3 → beast3 art (starters/21.png) | |
| egg | aqua, 1 | tier1 → aqua1 art (starters/3.png) | |
| jellyfin | aqua, 4 | tier2 → aqua2 art (starters/25.png) | |
| bomblet | aqua, 7 | tier3 → aqua3 art (starters/18.png) | |
| e_archon (elite) | aqua, 8 | tier3 → aqua3 art (starters/18.png) | |
| spikelet | reptile, 2 | tier1 → reptile1 art (starters/17.png) | |
| thornback | reptile, 5 | tier2 → reptile2 art (starters/23.png) | |
| bugling | bug, 0 | tier1 → bug1 art (starters/7.png) | |
| broodmaw | bug, 5 | tier2 → bug2 art (starters/24.png) | |
| venomaw | bug, 4 | tier2 → bug2 art (starters/24.png) | |
| hexeye | bug, 7 | tier3 → bug3 art (starters/14.png) | inherits bug3's low confidence flag |
| e_plague (elite) | bug, 8 | tier3 → bug3 art (starters/14.png) | inherits bug3's low confidence flag |
| ravenling | bird, 5 | tier2 → **gap**, no bird art | keep pixel sprite |
| stalker | bird, 3 | tier2 → **gap**, no bird art | keep pixel sprite |
| pyrewing | bird, 7 | tier3 → **gap**, no bird art | keep pixel sprite |

**Optional Phase 2 (not scoped this pass):** the kit has ~14 more named
portraits not used above (`dryad-fighter`, `dryad-ranger`, `treant`,
`treant-fighter`, `flowering-treant`, `forest-slime-fighter`,
`forest-slime-flower`, `aqua-slime-atk/def/sup`, `aqua-wolf`, `gray-wolf`,
`mommy-bear`, `daddy-bear`) that could later give individual field monsters
their own unique portrait instead of sharing the Hero's — pure flavor
upgrade, no gameplay dependency, lowest priority in this plan.

## 4. Background handling — do NOT embed, follow the audio precedent

`Backgrounds/class/bg-{aquatic,beast,bird,bug,dawn,dusk,mech,plant,reptile}.jpg`
are 1-3.5MB each; embedding all 9 as base64 would add roughly 15-30MB to the
single-file build, which breaks the "single lightweight static file" premise
this project has held everywhere except audio.

**Recommendation: treat backgrounds exactly like `assets/audio/` today.**

- New directory: `assets/art/backgrounds/` (plain files, not base64, not
  committed through `cosmetics.js`/`art.js`).
- `build.py` already has the exact pattern to copy (`AUDIO_DIR`,
  `AUDIO_EXT`, `audio_manifest()`, `%AUDIOMANIFEST%` injection at
  `build.py:9-19`) — propose a parallel `ART_DIR`/`art_manifest()` that
  lists whatever `.jpg`/`.png` files actually exist in
  `assets/art/backgrounds/`, injected as `ART_MANIFEST` the same way, so the
  client never requests a file that was never shipped (avoids the exact
  404-trips-verify.mjs-A11 problem the audio README documents).
  **No `build.py` edit is done in this pass — this is a proposal for
  `technical-director`/`devops-engineer` to implement.**
- `vercel.json`'s buildCommand already copies `assets/audio/*` into
  `build/assets/audio/`; it would need an equivalent line for
  `assets/art/backgrounds/*` into `build/assets/art/backgrounds/`.
- Client-side: CSS `background-image:url(...)` (not a base64 data URI)
  referencing `assets/art/backgrounds/bg-<class>.jpg`, gated by the same
  manifest-check pattern `MUS.sync()` uses (`client.html:1542-1548`) — only
  request a URL that the manifest confirms exists, fail silently and fall
  back to the current flat/CSS background otherwise.
- **Where in the UI these appear is a separate, new feature** — there is no
  existing per-class combat backdrop in `client.html` today (confirmed: no
  `arena-bg`/`combat-bg`/`classBg` hook exists). This plan only specifies
  the *asset delivery mechanism*; the actual "which screen, which element,
  what opacity/overlay so die/unit contrast still passes the UI-rule
  contrast check" is a `ui-programmer`/`ux-designer` design task, not an
  asset-mapping one, and should get its own short spec before implementation.
- The 9 files cover all 6 core classes (`aquatic, beast, bird, bug, plant,
  reptile`) plus the 3 secret classes (`dawn, dusk, mech`, see
  `part-skill-identity.md` §3.10) — full coverage, no gaps here, unlike
  Hero/Boss/MON_SPR art above.
- `Backgrounds/class/` also contains `bg_gauntlet.png`, `bg_metamorph.png`,
  `bg_metamorph2.png`, `bg_shop.png`, and `bg-reptile-2.png` (a second
  reptile variant) — out of scope for the 6/9-class mapping above, noted in
  case they're useful for other screens later.

## 5. Risks / open questions for technical-director / ui-programmer

1. **[Highest priority] `.image`/`realArtWrap()` semantics (§1).** Confirm
   the new field/wrap-function names and that the `⛓ "Real Axie NFT art"`
   badge stays exclusive to actual player-imported Vault Axies. Implementing
   this wrong ships a false ownership claim in the UI, not just a visual bug.
2. **File-size budget — improved by the §2 revision.** The original estimate
   assumed 18 unique hero images; the ground-truth mapping now needs only
   **10 unique portrait files** (Bug/Bird reuse 1 file across all 3 tiers;
   Beast/Plant/Aqua/Reptile reuse their Awaken file across tiers 2 and 3),
   plus up to 6 unique boss images (2 already embedded free). Recompute the
   ~700KB-1MB estimate downward once `technical-artist` has actual file
   sizes for the new portraits (currently sitting in the session scratchpad,
   not yet in the repo — see item 6). Still confirm the actual target
   ceiling before committing (§ "Memory Ceiling" in
   `technical-preferences.md` is currently unconfigured/TBD).
3. **Resize/recompress before embedding?** The new confirmed/Awaken
   portraits are a different art kit/style than the original numeric zip
   extraction — `technical-artist` should re-check target sizes against
   these specific files rather than assuming the old kit's ~30KB average
   carries over.
4. **`mecha` boss (`shilin.png`) is a thematic stretch**, not a visual
   match — flagging explicitly for product-owner sign-off since "no robot
   exists in the kit" is a real constraint, not an oversight. (Unrelated to
   the Hero revision above — Boss art only.)
5. **Backgrounds are a new feature, not just new art** (§4) — needs its own
   short UI spec (placement, overlay/contrast handling) before
   implementation; do not implement the manifest/loader plumbing without
   that spec also being ready, or the assets will ship unused.
6. **NEW — §3b (MON_SPR bucketed reuse) now points at stale hero filenames.**
   §3b was intentionally left unedited in this pass, but its filename column
   still references the SUPERSEDED numeric-kit hero art (e.g. "tier1 →
   plant1 art (starters/2.png)") — those files no longer match §2's revised
   mapping (plant1 is now Olek's Normal portrait). The bucket LOGIC
   (`floor(artIdx/3)` → tier) still holds; only the filename cells need
   re-pointing to the new §2 characters. Flagging so this isn't missed —
   §2 and §3 were revised in separate passes and would otherwise silently
   diverge.
7. **NEW — Hero character variety (product/creative call).** Every class
   currently reuses ONE character across all 3 tiers (§2). The official
   roster lists more candidates per class whose art has not been
   downloaded/verified this session: Beast (Xia, Bing, Hope — Tripp was
   downloaded but which file it is remains unconfirmed), Plant (Ena, Mit,
   Bard — Ena/Bard downloaded but file identity unconfirmed), Aqua (Noir,
   Rouge — not fetched), Reptile (Venoki — not fetched, Machito is the only
   available Reptile art), Bug (Shillin — not fetched, Pomodoro is the only
   available Bug art). Open question: is "1 character × 3 tiers" the
   intended final direction (simpler, more legible per-class identity), or
   should a 2nd/3rd portrait be fetched for classes with candidates (mainly
   Beast/Plant/Aqua) for more roster variety? Note Reptile and Bug have only
   one backup candidate each (Venoki, Shillin) even if variety is wanted —
   full 3-distinct-character coverage isn't achievable for those 2 classes
   regardless of this decision. Needs `lead`/product-owner input before
   `technical-artist` fetches anything further.

## 6. Whole-game pixel retirement audit — REVISED 2026-09-07

Product owner: *"bỏ hẳn phong cách pixel đối với quy mô toàn bộ game"* — audited
every place `src/client.html`/`src/data.js` renders something that isn't already
covered by §2/§3 (Hero/Boss/monster art). Two genuinely different visual
languages exist in this game and they should NOT be conflated:

**A. Character/creature art** (Hero, Boss, field monster) — fully covered by
§2/§3 above. Nothing further needed here.

**B. Functional glyph icons — recommend KEEP, do not touch:**
- `icoSvg()`/`ico()` (`client.html:~1670-1707`) procedurally draws every die-face
  and status-effect icon as an **8×8-grid SVG** (`viewBox="0 0 8 8"`,
  `shape-rendering="crispEdges"`) from `FT_IC` (dmg/shield/heal/mana/poison/
  buff/debuff/summon/blank) and `ST_IC` (poison/burn/regen/thorns/blind/
  weaken/vulnerable/stun/undying) name tables.
- `ARCH` (`data.js`) uses single Unicode glyphs (⛨ ↯ ➤ ✖ ☠ ♨ ✜ ✷ ✥ ✦ ⇗) for
  the 10 playstyle badges.
- **Why keep, not replace:** these render inline at ~14-20px next to a number
  on every single die face and status badge — dozens of instances per screen.
  A painterly Axie-art icon at that size reads as an indistinct colored blob,
  not a symbol; swapping would be a straight legibility regression, not an
  upgrade. Functional iconography staying abstract/geometric while character
  art is painterly is a normal, deliberate split (most illustrated games keep
  this same separation) — this is not leftover "pixel style" in the sense the
  product owner means, it is a different design layer entirely. Flagging
  explicitly so "no more pixel" scope doesn't silently balloon into
  re-authoring ~20 functional icons that were never in question.

**C. Cosmetic decor/background — currently CSS, not images (see §7 for the
concrete expansion plan):**
- `COSMETIC_DECOR` (`cosmetics.js`) already has a frame/"khung" category —
  `ring_plain` → `frame_eclipse`, 9 items — but every one is CSS-drawn
  (`style:'frame-vine'` etc., border/gradient tricks), not an image. Keep
  CSS for common/rare tiers (free, crisp at any size); §7 proposes upgrading
  only the top 1-2 rarities to real art if a suitable Drive asset turns up.
- `COSMETIC_BACKGROUNDS` (11 items) are CSS gradients reusing `CLASS_COLOR` —
  the single highest-value target for real-art replacement, see §7.

**D. Branding — optional, not required:**
- Title screen wordmark (`.logo`/`.logo.sm`, `font-family:var(--font-brand)`)
  is text/font-based, not an image. Drive has a dedicated `Logo` folder
  (unexplored this session) — worth a look if a matching brand mark exists,
  but this is a nice-to-have, not part of the core ask.

**Bottom line for product owner:** "no more pixel" is fully satisfied by §2/§3
(every character/creature is real art now). Recommend explicitly NOT touching
category B (functional icons) — say so if that reading is wrong.

## 7. Echo Box cosmetic library expansion

**Correction to prior framing:** a frame/"khung" category already exists
(`COSMETIC_DECOR`, see §6C) — no new category needed, only a decision on
whether to keep it CSS-only or add real-art tiers.

**Avatar expansion (biggest win, ready to spec now):** the official starter
roster confirmed 9 named characters with known class that were NOT used for
Hero art and are not yet in `COSMETIC_AVATARS`: **Xia, Bing, Hope** (Beast),
**Ena, Mit, Bard** (Plant), **Noir, Rouge** (Aqua), **Venoki** (Reptile),
**Shillin** (Bug) — 9 new avatars, roughly doubling this pool. Deliberately
keeping the Hero cast (Buba/Olek/Puffy/Machito/Pomodoro/Momo) and the Echo Box
avatar cast non-overlapping matters for player fantasy: a pull should always
feel like "a different Axie," never a duplicate of your own roster. None of
these 9 portraits are downloaded yet — lead needs to fetch them (art-director
has no Drive access).

**Background expansion (second-biggest win):** replace/supplement the top
rarity tier(s) of `COSMETIC_BACKGROUNDS`'s 11 CSS-gradient entries with the
real painted class backgrounds already located at `Backgrounds/class/
bg-{aquatic,beast,bird,bug,dawn,dusk,mech,plant,reptile}.jpg` (9 files,
6 playable + 3 secret classes — full coverage). This is the single most
visually dramatic upgrade available for Echo Box specifically, since
backgrounds are currently the ONLY cosmetic category with zero real art in it
at any rarity.

**Box-opening visual:** `cosmetic-gacha-chest.png` (Drive fileId
`1R6k8g4NZBZhuI78ZxlnjGU3tMrFu2e3C`, not yet downloaded) — a literal gacha
chest icon, proposed for the OPEN BOX button/reveal moment
(`scEchoBox()`, `client.html:~3069`), independent of whatever unlock-mechanic
change `economy-designer` lands on separately.

**Asset fetch list for lead (nothing below has been downloaded this session):**
1. 9 starter portraits: Xia, Bing, Hope, Ena, Mit, Bard, Noir, Rouge, Venoki, Shillin
2. `cosmetic-gacha-chest.png`
3. At least 1-2 of the 9 `Backgrounds/class/bg-*.jpg` files, to confirm actual
   file size before committing to replacing all 11 background entries (the
   Hero-art background estimate in §4 was 1-3.5MB/file — confirm this holds
   for a cosmetic-tier use case, since embedding several of these as gacha
   rewards multiplies the payload question §4 already raised for a single
   per-class combat backdrop).

## 8. Status icon replacement mapping — REVISES §6B, `ST_IC` only

**Correction to §6:** §6B's "keep, do not touch" recommendation was written
believing no real-art alternative existed for the 8×8 procedural icon set at
all. A real, comparably-sized alternative now exists for one half of that
set — Drive folder "Battle Status Icon"
(`1OPxS21x_0miVFkEUcUM6kkssqsQ8_yQ5` → `PNG` subfolder
`1vnmfXmaUfMhpXulkPWeNBp9CFi-bLACK`), ~50 icons, 3-12KB each, comparable
payload to the current inline SVG. This section revises §6B for `ST_IC`
(status-effect badges) only.

**Not revised — stays exactly as §6 recommended:**
- `FT_IC` (die-face effect types: dmg/shield/heal/mana/poison/buff/debuff/
  summon/blank) — no change. These render inline on every die face at the
  smallest size in the game; the legibility argument in §6B applies at full
  force and nothing in the new folder changes that math. Note the word
  "poison" appears in both `FT_IC` (a die-face effect type) and `ST_IC` (a
  status badge) — they are different rendering contexts and this section
  only touches the latter.
- `ARCH` Unicode playstyle glyphs (data.js) — no change, no new finding
  applies to these at all; the Battle Status Icon folder has no playstyle-
  badge equivalent.

**`ST_IC` mapping (9 keywords) — NOT visually verified, name-match inference
only. Confidence flagged per row, same convention as the §2 Hero table:**

| `ST_IC` keyword | proposed Drive file | confidence | reasoning |
|---|---|---|---|
| poison | `Poison.png` | High | exact name match |
| regen | `Regen.png` | High | exact name match |
| weaken | `Weak.png` | High | "Weak" is the standard synonym for a weakened/lowered-attack status in this icon-pack naming convention (paired with `Damage Down`, distinct from `Fragile`) |
| vulnerable | `Vulnerable.png` | High | exact name match |
| stun | `Stunned.png` | High | exact name match (adjective vs. our verb-form key, same concept) |
| thorns | `Spike.png` | Medium | not an exact name match, but the strongest visual-metaphor candidate in the FULL 48-icon folder listing (lead has since confirmed the complete listing, not just ~20 titles) for "reflect damage" — a spike/thorn silhouette is a standard iconography choice for a reflect/retaliate status. `Blood Spike.png` (also in the folder) is a secondary candidate if `Spike.png` turns out visually generic |
| blind | none found | — | **Lead confirmed the complete 48-title folder listing (not partial) — no `Blind`/`Miss`/`Confuse`/`Eye`-named icon exists in this folder.** `Zz.png` is almost certainly SLEEP (skip-turn), a different concept from `blind` (miss-chance) — do not use it. Keep current procedural SVG for `blind`. |
| burn | none found | — | **Confirmed absent from the complete 48-title listing** — no `Burn`/`Fire`/`Flame`-named icon anywhere in this specific folder. Keep current procedural SVG. |
| undying | none found | — | **Confirmed absent from the complete 48-title listing** — no `Immortal`/`Phoenix`/`Undying`/`Revive`-named icon in this folder. Keep current procedural SVG. |

**Recommendation:** adopt the 6 High/Medium-confidence rows (`poison`,
`regen`, `weaken`, `vulnerable`, `stun`, `thorns`) once visually confirmed
(swap those `IC_G`/`IC_COL` entries in `icons.js` for image references, per
the same house-art wrap pattern as §1 — new detail for `technical-artist` to
work out, not scoped here). For the other 3 (`blind`, `burn`, `undying`),
**keep the current procedural SVG permanently** — this folder has been fully
enumerated and confirmed not to contain a semantically correct icon for any
of the three; do not substitute a mismatched icon (e.g. `Zz.png` for `blind`)
just to force full coverage, since a wrong-semantic icon actively misleads
the player about what the status does, which is worse than the plain
geometric icon it would replace. A different Drive folder (`Enemy Status
Icon`, `4-Icon-status`, or `Requiem Status Icon` — all seen in passing, none
explored) may hold these 3 if a future pass wants to close the gap.

**Files lead should fetch/view next, in priority order (folder listing is
now complete — remaining work is visual confirmation, not more searching):**
1. `Weak.png`, `Vulnerable.png`, `Stunned.png`, `Poison.png`, `Regen.png`,
   `Spike.png` — the 6 candidate picks, for a quick visual sanity check
   before locking in (name match alone has been wrong before in this
   project's Hero pass — see §2's superseded table).

## 9. Icon Cosmetic types folder — small, optional

Drive folder "Icon Cosmetic types" (`1Velct3Q5kKHrNFbbYKG24IlbcjZG_vKj` →
PNG subfolder `1fBxn1SyyrPJuAyNXCbDx-MHvX9EXWG_O`) has `icon-avatar.png`,
`icon-background.png`, `icon-border.png`. `src/cosmetics.js` confirms exactly
4 cosmetic categories exist (`COSMETIC_POOLS = {avatar, decor, background,
title}`, `cosmetics.js:78`) — 3 of the 4 have a ready-made icon here
(`icon-border.png` reads as the natural stand-in for `decor`, since that
category is frames/"khung"); there is no `icon-title.png` in this folder.

**Proposed use:** small category-label icon next to (not replacing) the text
label in the Echo Box reveal UI and/or the cosmetic wardrobe tabs
(`scProfile()`/wardrobe section, `client.html:3195-3197` — `mkSec('AVATARS',
'avatar',...)`, `mkSec('DECOR','decor',...)`, `mkSec('BACKGROUNDS',
'background',...)`), so a reveal reads "icon + AVATAR" instead of text alone.

**Recommendation: do, but treat as low-priority polish, not blocking.**
Reasoning for "do": these are tiny (unspecified size, but everything else in
this folder family runs 3-12KB) category glyphs, zero ambiguity risk (no
semantic-mapping guesswork like §8 — the filenames name their own category
outright), and low implementation cost (3 static image swaps next to
existing text, no new logic). Reasoning for "not blocking": text labels
already do this job today with no reported confusion; the missing 4th icon
(`title`) means the wardrobe would end up with 3 categories iconified and 1
not, which is an inconsistent pattern unless a 4th icon is sourced or
`title` deliberately stays text-only (asymmetry is a minor Gestalt
consistency ding, not a functional problem). **Decision needed from lead/
product owner: worth a 4th icon search, accept the 3-of-4 asymmetry, or skip
this entirely and keep all 4 as text-only** — art-director has no strong
pull either way given how small the win is relative to §2/§3/§7's higher-
value asset work.
