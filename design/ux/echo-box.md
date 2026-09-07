# UX Spec — Echo Box (Standalone Screen + Ceremony Redesign)

> **Status**: Designed, pending implementation
> **Author**: ux-designer (2026-09-07)
> **Trigger**: Product owner feedback — current Echo Box UI is "cực kì xấu"
> (extremely ugly), makes players not want to play. Explicit reference:
> Genshin Impact's wish/summon screen. This spec answers "what does a strong
> gacha screen's *structure and ceremony* look like here", reusing every art
> asset and FX/SFX primitive already in the codebase — no new assets, no
> canvas/WebGL, no new libraries, no CDN.
> **Scope**: Presentation layer only (layout, motion, copy placement, data
> shape for a new log). Does **not** touch `ECHO_BOX_RARITY_ODDS`,
> `echoCost()`/`ECHO.introCost`, `ECHO_FUSE_COST`, or `chestGradeFor()`'s
> deterministic chest-grade mapping — those are `economy-designer` territory.
> Stays additive to the naming decisions already locked in
> `design/quick-specs/echo-box-double-gacha-ux.md` ("Rank" = account-level
> `echoTier()`, "Chest"/"Chest Grade" = per-pull `chestGradeFor()`; this spec
> does not reopen that).

## 0. Source references (traceability, current as of this pass)

| What | Where |
|---|---|
| `scEchoBox()` | `src/client.html:3211` — currently called from inside `scCollection()` at `src/client.html:3201` |
| `scCollection()` | `src/client.html:3176` |
| Screen router (`if(screen===...)` chain) | `src/client.html:2915` area (`scCollection`/`scHistory` wired at 2915, 2919) |
| `scMenu()` — menu-tile grid | `src/client.html:3077`, PROGRESS group at `3116-3124` |
| `menuTile()` | `src/client.html:3071` |
| `scHistory()` (localStorage list precedent) | `src/client.html:4364`; storage key `HK='axiedice_history_v1'` (`2289`), cap `HISTORY_MAX_RUNS=20` (`2296`), trim at `4191` |
| Chest reveal (already implemented, 2-step) | `src/client.html:3232-3268` — `echoBoxOpen()`, `echoBoxResult`/`echoChestRevealed` state, 850ms auto-chain `setTimeout` at `3243` |
| Fuse rows | `src/client.html:3270-3286` |
| `CHEST_ART`, `.chestreveal`, `.chest-<grade>` (6-colour ladder) | art `src/art4.js`; CSS `src/client.html:438-447` |
| `.rcard`/`.rbadge`/`.rchip` (rarity 5-colour ladder, `--r0..--r4`) | CSS `src/client.html:961-985`, `604-606`; vars `114` |
| `.bpbar`/`.bpfill` (progress-bar pattern to reuse for Rank) | CSS `src/client.html:1027-1029` |
| `.iempty` (empty-state convention) | CSS `1154`; usage precedent `scHistory()` `4370` |
| `.echosec` (current Echo Box panel wrapper) | CSS `430-432` |
| FX primitives | `flashScreen(cls)` `2792`, `hitstop(ms)` `2793`, `bigText(t,cls)` `2794`, `shake(n)` `2781`, all gated by `wantsLessFlash()` `2791` (`META.reduceFlash \|\| prefersReducedMotion()`) |
| SFX bank | `src/client.html:1530+` — relevant: `ui`, `hover`, `coin`, `legend`, `mythic`, `boss` |
| Precedent combo for top-rarity drama (mirror this) | `src/client.html:2848-2849`: `if(f.r>=4){SFX.mythic();hitstop(140);flashScreen('myth');bigText('MYTHIC','');} else if(f.r>=3){SFX.legend();flashScreen('gold');}` |
| Cosmetic pools (real art, no new assets) | `src/cosmetics.js:8` `COSMETIC_AVATARS` (`.src` base64), `32` `COSMETIC_DECOR`, `47` `COSMETIC_BACKGROUNDS` (both may carry `.style` instead of art), `61` `COSMETIC_TITLES` (text only), `78` `COSMETIC_POOLS` |
| `RARITY` labels | `src/data.js:13` |
| `kbAct()` (real tab-order for divs) | `src/client.html:2183` |

Confirm current line numbers against `grep -n "function scEchoBox\|function scCollection"` before implementation — this doc cites the 2026-09-07 state.

---

## 1. Echo Box becomes its own screen

**Problem with today's placement**: `scEchoBox()` renders at the *bottom* of `scCollection()`, underneath three `.colgrid` walls of "???" locked placeholders (Relics/Die Faces/Bosses). A gacha screen — the game's most re-visited, dopamine-driving loop — is currently the least discoverable, most buried thing in the menu. Every strong gacha UX reference (Genshin's Wish, Arknights' Headhunting) gives the gacha its own top-level destination with a dedicated entry point, never nests it under a progress-tracking screen.

**Change**:
- New top-level screen state `screen==='echobox'`, added to the router alongside `collection`/`history` (`src/client.html:2915` area): `else if(screen==='echobox') root.appendChild(scEchoBox());`
- `scEchoBox()` is restructured to return a full `.screen.menu.echobox` wrapper (matching `scHistory()`'s shape: `h1.logo.sm` title, content, `BACK` button to `'menu'`) instead of a `.colsec.echosec` fragment.
- New menu tile in `scMenu()`'s **PROGRESS** group (`src/client.html:3116-3124`, alongside PASS/COLLECTION/UNLOCKS/TOUR):
  ```
  progGrid.appendChild(menuTile('ECHO BOX', <subtitle>, ()=>{ screen='echobox'; render(); }, <flag>));
  ```
  - Subtitle: `tier>0 ? 'Rank '+tierName : 'New!'` — mirrors how COLLECTION's subtitle shows live counts, not a static label.
  - Flag (glow border, same mechanism as PASS's `nb>0`): `true` when `META.shards>=cost` (player can afford a pull right now). This is an affordance, not nagging — it tells the player "there's something actionable here" exactly like the Battle Pass unclaimed-reward glow already does, so it reuses an existing visual vocabulary rather than inventing a new "new!" badge.
  - Placement in PROGRESS (not REFERENCE) is deliberate: Echo Box is a spend/progression action like the Battle Pass, not a lookup screen like Codex/Vault/Leaderboard/History. The grid (`repeat(4,152px)`) wraps a 5th tile to its own row automatically — no CSS layout change required.

**What replaces the full panel at the bottom of Collection**: not nothing (Echo Box's cosmetic rewards are part of "what's left to collect," so a total blackout would break Collection's own promise of visible progress), and not a duplicate of the full panel (that's the buried-gacha problem again). A **slim pointer row**, same `.colsec` wrapper as the three grids above it:

```
[chest icon]  ECHO BOX — spend leftover Shard on cosmetics
              Rank: Waning · 3/10 to next rank            [→]
```

- One clickable row (real `kbAct()`-focusable div or a `<button>`), `onclick={ screen='echobox'; render(); }`.
- Shows the Rank readout (read-only teaser) but **no pull action, no chest art, no fuse rows** — all of that lives only on the standalone screen. This keeps Collection's job ("what have I collected") separate from Echo Box's job ("pull more"), instead of doing both halfway in two places.

---

## 2. Hero banner — "what's obtainable," using existing real art

Genshin's banner sells the pull by showing the *actual* featured art up front. This project has real art for avatars (`COSMETIC_AVATARS[key].src`, base64 PNG) and CSS-swatch art for decor/backgrounds (`.style` class), plus text-only titles. No new assets — the banner is a curated *display* of existing pool data.

**Structure — `.echohero`**, top of the standalone screen, above the fold:
- A horizontal strip (wraps on narrow widths, same breakpoint logic as `.menu-grid`) of ~10-14 small item chips, `.echoshow`, sampled across all 4 pools (`COSMETIC_POOLS`), weighted toward Epic+/Legendary/Mythic entries (show the aspirational stuff, exactly why Genshin's banner leads with the 5-star, not a random 3-star).
- Each chip: real thumbnail (`item.src` for avatars, colored swatch div for decor/background using `item.style`, or a styled text pill for titles) inside a rarity-colored border reusing the existing `--r0..--r4` ladder (same visual language as `.citem`/`.rchip`, not a new palette).
- **Owned vs. unowned treatment (no new art needed)**: owned items render full-color; unowned items render the *same real thumbnail* under a CSS filter (`grayscale(1) brightness(.55)` or similar — `art-director`'s exact values) rather than a "???" blackout. This is a deliberate difference from Collection's `.citem.locked` pattern: Collection is inventory-tracking (full mystery is fine, nothing to sell), but a gacha banner's entire job is to create desire for the specific thing you don't have yet — showing the real silhouette-but-dimmed art does that; a flat "???" doesn't.
- One caption line under the strip: `"4 pools · {ownedCount}/{totalCount} collected"` — ties the banner back to actual collection progress without re-showing Collection's full grids.

---

## 3. Primary pull action — real visual weight

Today: a plain `<button class="btn cta">OPEN BOX</button>` with cost as a separate plain text line above it. Undersells the game's core monetization/engagement loop.

**New `.echopull` control** (extends `.btn.cta`, still a real `<button>` — Fitts's Law: this is the single most-clicked control on the screen, it should have the largest, most central tap target):
- Minimum height ~64-72px (vs. current default button height), full-width within the screen's content column, placed directly under the Rank meter (§7) and hero banner (§2) — not below a scroll.
- **Two-line label inside the button itself**, not a separate text line above it: `"OPEN ECHO BOX"` / `"{cost} SHARD"` — cost lives on the point of action, one less place to look.
- Disabled state (`META.shards<cost`): grayed per existing `.dis` convention, but the second line changes to `"Need {cost-shards} more Shard"` instead of just going mute — a disabled control must still tell the player what to do next, not just that it can't be clicked (accessibility: functional without relying on opacity/color alone).
- `onmouseenter → SFX.hover()` (unchanged, already present).
- Optional idle "breathing" glow (new CSS keyframe, box-shadow pulse only, no new library) to draw the eye — **must** ship with a `prefers-reduced-motion`/`wantsLessFlash()` off-switch from day one, same pattern already used for `.rbadge`'s reduced-motion override (`src/client.html:831-832`). This is the one net-new bit of motion in this spec; flagging it explicitly so `ui-programmer` doesn't skip the a11y branch.

---

## 4. Reveal choreography — re-staging the EXISTING 2-step flow

The 2-step structure (chest grade → auto-chain → cosmetic) and its data (`echoBoxOpen()`, `chestGradeFor()`, the 850ms `setTimeout`) are unchanged. This section only re-times the *presentation* around it.

**Step 0 — click** (`ob.onclick`, `src/client.html:3233`):
1. `echoBoxOpen()` runs (cost deducted — unchanged).
2. `hitstop(60)` — a short punch on click, before anything renders, so the click itself has weight (currently nothing happens between click and the chest appearing).
3. `render()` mounts the chest reveal (unchanged trigger point).

**Step 1 — chest lands** (`.chestreveal`, mounts on the render from step 0):
1. Entrance: CSS-only scale/fade-in (~200ms) on mount — currently the chest just appears with no transition.
2. `shake(n)` scaled to chest grade, mirroring how boss phase-transitions already scale `shake()` to moment weight (precedent `src/client.html:5794`): Bronze/Silver `shake(1)` (or skip), Gold/Platinum `shake(2)`, Diamond `shake(2)`, Lunacian `shake(3)`.
3. `flashScreen('gold')` for Gold/Platinum/Diamond only — **not** Bronze/Silver (those are the two most common outcomes; flashing on every single pull causes flash-fatigue and dilutes the signal for when it matters — ties to the "no flashing content without warning" a11y rule by keeping flashes rare and meaningful, not constant).
4. Lunacian gets its own top-tier combo, mirroring the existing Mythic-cosmetic precedent (`2848-2849`) rather than inventing a new one: `SFX.boss()` (a "this is the rare one" sound distinct from `SFX.mythic()`, which this spec reserves for the *cosmetic* Mythic reveal in Step 2 — using the same sound at both the chest-grade and cosmetic-rarity moments would blur the "Chest ≠ Rank ≠ cosmetic rarity" distinction the naming spec already fought to establish) + `hitstop(120)` + `flashScreen('myth')` + `shake(3)` + `bigText('LUNACIAN CHEST!!', 'Rarest pull in the game')`.
5. Existing SFX split at chest-click (`chestBox.onclick`, `3258`) stays as the manual-skip path; the auto-chain timer fires the same beats if the player doesn't click first.

**Step 1→2 transition**: auto-chain unchanged at 850ms for Bronze/Silver/Gold/Platinum (keeps bulk-opening fast, per the prior spec's reasoning). **Tunable knob, not a requirement**: Diamond/Lunacian may hold the beat slightly longer (~1100ms) since the player has just been told this is a big pull — purely a presentation timing value, not one of the frozen economy constants, so `ui-programmer` can adjust without needing sign-off, but should not make Bronze/Silver slower (that's the volume path).

**Step 2 — cosmetic `.rcard` reveal**: same component (`RARITY[r.rar]` badge, item/`DUPLICATE`, category, Rank-title line), full drama matrix in §5.

---

## 5. Rarity-tiered visual drama — full matrix

Two separate drama passes exist per pull: the **chest-grade** pass (§4 above, keyed to the 6 chest grades) and the **cosmetic-rarity** pass below (keyed to the 5 `RARITY` tiers, fires when the `.rcard` mounts in Step 2). Keeping them visually distinct (different SFX choices, chest pass never uses `SFX.mythic()`) is what keeps "Chest Grade" and "cosmetic Rarity" legible as two different systems, per the naming decision in the prior spec.

**Cosmetic-rarity reveal matrix** (fires on `.rcard` mount, mirrors the existing precedent at `src/client.html:2848-2849` so this screen's feedback language matches the rest of the game rather than inventing a third convention):

| Rarity (`r.rar`) | SFX | flashScreen | hitstop | shake | bigText |
|---|---|---|---|---|---|
| Common (r0) | `SFX.coin()` | — | — | — | — |
| Rare (r1) | `SFX.coin()` | — | — | — | — |
| Epic (r2) | `SFX.legend()` | `'gold'` | — | — | — |
| Legendary (r3) | `SFX.legend()` | `'gold'` | — | `shake(1)` | — |
| Mythic (r4) | `SFX.mythic()` | `'myth'` | `140` | `shake(3)` | `'MYTHIC'` |

Common/Rare deliberately get **no** flash/shake/hitstop — reserving those primitives for Epic+ is what makes them read as significant when they do fire (contrast is the whole mechanism; if everything shakes, nothing feels rare).

`DUPLICATE` pulls play the same matrix for their rolled rarity (a Mythic duplicate is still a Mythic-tier moment, worth the fanfare, even though the fusion-progress line communicates "you already have this").

---

## 6. Pull-history log

No such log exists today (Echo Box has zero record of past pulls). `scHistory()` (`src/client.html:4364`) is the direct precedent to copy the *pattern* from, not the data shape.

**Storage** (new key, same convention as `HK='axiedice_history_v1'` at `2289`):
```js
const EK = 'axiedice_echolog_v1';
const ECHOLOG_MAX = 30; // trim oldest past this, same trim-on-write pattern as HISTORY_MAX_RUNS (src/client.html:4191)
function loadEchoLog(){ /* same try/localStorage.getItem/JSON.parse/catch shape as loadHistory() */ }
function saveEchoLog(list){ /* same shape as saveHistory() */ }
```

**Entry shape** (captured at the moment a pull fully resolves, i.e. when `echoChestRevealed` flips true and the `.rcard` mounts — reuses fields already present on `echoBoxResult`, no new roll data):
```js
{
  ts: Date.now(),
  chestK: r.chest.k,       // 'bronze'..'lunacian'
  chestN: r.chest.n,
  rar: r.rar,              // 0-4, RARITY index
  dup: r.dup,              // bool
  itemName: r.n || null,   // null when dup
  cat: r.cat || null,
  tierTitle: r.tierTitle || null  // Rank title, if this pull crossed a Rank boundary
}
```

**Display**: a `PULL LOG` section near the bottom of the screen (below the fuse panel, §8 — this is a passive reference, not an action, so it sits after the actionable stuff, matching Genshin's own "Wish History" being a secondary link rather than front-and-center). Rows reuse `scHistory()`'s compact-row visual language (`.histrow`-equivalent, new class `.echologrow`): chest-grade icon thumbnail + `.rchip r{rar}` rarity chip + item name or "Duplicate" + relative timestamp. Flat list, most recent first, no per-row expand (unlike History's accordion — a gacha log entry has nothing further to disclose, it's already one line). Empty state uses the existing `.iempty` convention: `"No pulls yet — open your first Echo Box above."` A `CLEAR LOG` control mirrors `CLEAR HISTORY`'s `confirm()`-gated danger button (`4373-4375`).

---

## 7. Rank/pity meter — prominent status readout

Today: one plain sentence, `Echo Boxes Opened: ${opened} · Rank: ${tierName} · ${inTier}/${ECHO.tierSize} to next rank` (`src/client.html:3228`). This is exactly the kind of persistent progress state that a `.bpbar` already exists to solve — the Battle Pass never shows its level as a sentence, it shows a bar.

**New `.echorank` block**, placed near the top of the standalone screen (below the hero banner, above the pull button — this is read-only state the player should register before deciding to pull, same position Genshin gives its pity counter):
- Header row: `"RANK: {tierName}"` (large, `--t4`/`--t5` scale) + a secondary stat chip `"{opened} boxes opened"`.
- `.bpbar.big` / `.bpfill` reused directly (same component, not a lookalike) showing `inTier/ECHO.tierSize` fill.
- Caption under the bar: `"{inTier}/{ECHO.tierSize} to next rank"`.
- This block is **read-only** (no click target) — its job is status, not action.

---

## 8. Fuse section — clean secondary panel

Today: 5 raw `.fuserow` divs with no wrapper, no heading, competing visually with the hero pull action above them.

**New `.fusepanel`** (a `.colsec`-style card, visually demoted relative to the hero/pull/rank block above — smaller heading scale, `--pan2`-tier background rather than the primary panel background, so it reads as "secondary sink," not "second thing to do here"):
- Header: `"FUSE DUPLICATES"` + one-line explainer (reuse existing copy convention, e.g. `"{ECHO_FUSE_COST} duplicates of a rarity → 1 upgrade."`).
- Each `.fuserow` redesigned as a compact horizontal card: `.rchip r{r}` rarity label + a **small** `.bpbar` variant (not `.bpbar.big`) showing `dc/ECHO_FUSE_COST` progress instead of bare text + the `FUSE`/`FUSE (SHARD REFUND)` button right-aligned.
- Rows at `0/{ECHO_FUSE_COST}` stay visible but at reduced opacity (same visual language as `.dis`) rather than being hidden — the player should always be able to see the mechanic exists and what it costs, just not have it visually compete for attention when there's nothing to act on. (Rejected alternative: hiding empty rows behind a disclosure toggle — adds a click to see a mechanic that's core to the loop; transparency here matters more than tidiness, consistent with this project's stated "nothing hidden from the player" value referenced in `combat-log.md`.)

---

## 9. Implementation notes for `ui-programmer`

- **Router**: add `else if(screen==='echobox') root.appendChild(scEchoBox());` near `src/client.html:2915-2919`; `scEchoBox()`'s return value changes from a `.colsec.echosec` fragment to a full `.screen.menu.echobox` wrapper (h1 + content + `BACK`→`'menu'`), matching `scHistory()`'s shape.
- **`scCollection()`**: delete the `w.appendChild(scEchoBox())` call (`3201`); add a new small `scEchoBoxPointer()` returning the slim `.colsec` row from §1, appended in its place.
- **`scMenu()`**: new `menuTile('ECHO BOX', ...)` call in the PROGRESS grid (`3116-3124`).
- **New CSS classes** (names proposed here, palette/spacing is `art-director`'s call, not mine): `.echohero`, `.echoshow` (+ `.echoshow.locked` for the dimmed-unowned treatment), `.echorank`, `.echopull`, `.echologrow`, `.fusepanel`. Reused as-is, no new variant needed: `.bpbar`/`.bpfill`, `.rcard`/`.rbadge`/`.rchip`, `.chestreveal`/`.chest-<grade>`, `.iempty`, `.colsec`.
- **Keyboard-only compliance** (per the open a11y gap already tracked in this project — see `docs/axiedice-source/ORIGINAL_PROJECT_CLAUDE.md` and the keyboard-audit note this agent already has on file): every new interactive element in this spec — the Collection pointer row, the pull-log's rows if they ever become clickable, the chest reveal button — must be a real `<button>` or carry `kbAct()`, exactly like the existing `chestBox`/`ob` elements already are. Do not introduce a new clickable-div-with-no-focus-handling pattern.
- **Motion/flash gating**: every new FX call in §4/§5 routes through the existing `flashScreen()`/`hitstop()`/`shake()` (already gated by `wantsLessFlash()`); the one net-new CSS animation (the `.echopull` idle glow, §3) must get its own `prefers-reduced-motion`/`wantsLessFlash()` off-switch, following the `.rbadge` precedent (`831-832`) — do not assume the shared gate covers pure-CSS keyframes automatically.
- **Ordering on the standalone screen, top to bottom**: hero banner (§2) → Rank meter (§7) → primary pull button (§3) → in-place reveal area (chest → cosmetic card, unchanged mechanic) → fuse panel (§8) → pull-history log (§6) → `BACK`.
- **No new assets, no canvas/WebGL, no CDN, no new animation library** — every visual in this spec is either already-existing art (`COSMETIC_AVATARS[key].src`, `CHEST_ART`, `.style` swatches) or CSS (existing classes, one new keyframe for the idle pull-button glow, one new CSS filter for dimmed-unowned banner chips). No constraint from the brief needed to be broken to deliver this.

---

## Open questions (need PM / other-agent decision, not mine to make)

1. **Exact colors/spacing for the 6 new proposed CSS classes** (`.echohero`, `.echoshow`, `.echorank`, `.echopull`, `.echologrow`, `.fusepanel`) and the dimmed-unowned filter values — `art-director`.
2. **Which specific items populate the hero banner's ~10-14 showcase slots** (curated by hand vs. auto-selected "highest rarity per pool" at render time) — leaning toward auto-selected (zero maintenance as new cosmetics ship) but flagging since a hand-curated "featured" rotation is also a legitimate reference-Genshin move (their banners rotate a *specific* promoted character) — `game-designer`/PM call on whether Echo Box ever wants a rotating "featured" cosmetic.
3. **Diamond/Lunacian auto-chain hold time (~1100ms vs. keeping 850ms uniform)** — a tuning knob, not a hard requirement; needs a quick playtest feel-check, not a design decision made blind.
4. **`ECHOLOG_MAX` cap value (proposed 30)** — arbitrary starting number matched loosely to `HISTORY_MAX_RUNS=20` scaled up since pulls happen far more often than runs; no strong reasoning behind the exact number, open to `game-designer`/`gameplay-programmer` adjustment.
