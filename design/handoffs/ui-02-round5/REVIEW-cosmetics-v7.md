# Review: Cosmetics 01 v7 (Claude Design) vs NOTE-TO-CLAUDE-DESIGN-02

Reviewed 13/10/2026. Looked at: README, manifest (v7 vs our godot/assets/cosmetics one), contact sheet, 40 px check, 104/64/36 preview, file list. I did not open the .dc.html or the big JS, and I could not measure pixel sizes or alpha (no shell here), so "256x256 transparent" and "overlap <= 8 px" are taken from the README/manifest and from the contact sheet (blue window looks clean and the rings hug it). Someone should run `sips`/Godot on the PNGs to confirm before import.

## Verdict: ACCEPT WITH FIXES

Almost everything we asked for is in. The gaps are (1) several same-tier Common/Rare frames are still too alike at 40 px, (2) the moving layers for Epic+ frames come as one combined PNG per frame instead of the separate layers the loop specs describe, (3) the manifest structure changed and needs a loader/merge check. None of these block a first import of the dice.

## Per-item table

| # | Item | Status | Notes |
|---|---|---|---|
| 1 | 21 frames, exact ids (c_bird ... m_crystal) | DONE | All 21 `frame_*_base.png` present, ids match the note exactly. |
| 2 | 256x256 transparent, window O168, overlap <= 8 | DONE (unverified) | Manifest says 256, centre 128/128, O168, max overlap 8. Contact sheet looks right. Needs a pixel check. |
| 3 | Readable at 40 px | PARTIAL | Dark outline works, rings read as objects. But see 4. |
| 4 | Same-tier silhouettes differ | PARTIAL | Common: beast (ears), aqua (fin), reptile (spikes) are fine. plant, bug, bird are near-identical orange zig-zag rings at 40 px; the motif is a tiny dot on top. Rare: snowglobe and icicle are both a plain white ring with a lump on top at 40 px; frost (spikes) and aurora (dark navy) are fine. Uncommon, Epic, Legendary, Mythic are fine. |
| 5 | Rare frames don't read as Uncommon green | DONE | All four are white/ice/periwinkle/navy, no green. |
| 6 | Themes fixed | DONE | runering = violet rune ring with gems and orbit ring; sunburst = gold sun crest on gold ring; eclipse = night + crimson with cream crescent on top. |
| 7 | Epic+ separate moving layer | PARTIAL | 7 `_anim.png` exist, but one PNG per frame, "static pose". The loop specs name separate layers (`anim/rune_orbit.png`, `rune_glow.png`, `fireflies.png`, `lantern_glow.png`, `stars.png`, `shield_sheen.png`, `sun_glow.png`, `sparkles.png`, `crown_sheen.png`, `gem_glints.png`, `eclipse.png`, `core_glow.png`, `glint.png`). None of those files are in the export. Rune orbit (spins) and rune glow (pulses) can't be animated independently from one PNG. |
| 8 | Loop spec | DONE | Durations, easing, opacity ranges given for all 7. |
| 9 | Reduce-flashing variant | DONE (spec only) | Written per frame, spec text only, no extra art. That is fine because they are opacity/speed changes. |
| 10 | Die fix 1: clean value row | DONE | Contact sheet shows clean number zone on all 20. Sun rays lowered, spore caps low, bug seam shortened, aqua/reptile/reed calmed. |
| 11 | Die fix 2: Founder ribbon | DONE | No lettering; numeral "1" shield, ribbon plain. Readable at 36 px. |
| 12 | Die fix 3: Mythic borders | DONE | Border #0E0608 on both. #FF3D6E is in the crystal cores on redcrystal. Visible at 36 px. |
| 13 | Die fix 4: glow split + MAX | DONE | Epic/Legendary: `_base` + `_glow`; Mythic: base + glow + `_max`. Baked halos/spores/seams/corner stars moved to glow per spec. Not checked pixel-by-pixel (glow PNGs not viewed). |
| 14 | Die fix 5: previews | DONE | `preview_104_64_36.png` and `contact-sheet.png` both included. |
| 15 | Die fix 6: Rare frost detail | PARTIAL | Cold-blue inner rim + tiny snowflake facet bottom-left on all six. It works but the snowflake is very small (about 8 px at 104); at 36 px it is a dot. Tier reads Arctic mostly from the blue rim. |
| 16 | Die fix 7: reptile lilac | DONE | Kept, lilac. |
| 17 | Mythic #FF3D6E rules | DONE | Used on chip, borders, tier name, frames, crystal cores. Ink #1A1206. Eclipse frame says "carries no text". Night #2A0F2E shared. |
| 18 | FX spec updates | DONE | Four "40 per die" FX now <= 34; face-type bits added to r_frost, e_rune, m_lunar; lunar sheen 0.22 s, tray-only dim, one eclipse per roll; ember reduced = one flame shape; sunfire matches sunburst. |
| 19 | Manifest ids match ours | DONE for dice/fx/tiers | All 20 die ids and all fx ids identical to godot/assets/cosmetics/cosmetics_manifest.json. Frames: all 21 ids present. |

## New issues

1. **Manifest shape changed.** Old file has `frames_with_art` (5, with source_file/image_size/window_radius) and `frames_waiting_for_art` (16). New file has a single `frames` object with all 21 plus a new `fx`/`previews`/`outline_rule` set, and each die has `files`/`layers`/`size`/`calm_zone_px`. `proposed: true` on Mythic became `approved: true`. Whatever reads the old keys (tests, loader, `t_assets`) will break or silently skip. Check before replacing.
2. **Anim file names in the loop text don't exist.** Text says `anim/rune_orbit.png` etc.; real files are `frames/frame_<id>_anim.png`. Naming is also off our convention (`char_/ui_...`), but ids are fixed by the manifest so we keep them.
3. **Common frames share one band.** By design ("Common stays simple") but it fails our own same-tier-at-40px rule for plant/bug/bird.
4. **frame_c_bird and frame_u_pond text says "redrawn from Homeland_Avatar frame_3 / frame_1".** We asked for fresh drawings, not reused bitmaps. Looks redrawn in the same style (README says no bitmaps reused), but confirm with Liam if this matters.
5. **Aurora frame:** dark navy band is clearly different, but the ribbons sit outside the 256 box edge-to-edge at the top; check nothing is clipped at the canvas edge.
6. Contact sheet shows frames over a flat blue dummy window, not an avatar. We asked for previews at 40/96/256 around a dummy avatar; the 40 px check is there, 96 and 256 previews of frames are not. Minor.

## Paste-ready fix list for Claude Design (only what's still needed)

```
Thanks, v7 is very close. Remaining fixes:

1. Frames, same tier must differ at 40 px:
   - Common: frame_c_plant, frame_c_bug, frame_c_bird look the same as each other at 40 px (orange zig-zag ring + a tiny motif). Make each motif at least 2x bigger and give each a different top silhouette (like beast ears / aqua fin / reptile spikes already do). Keep the shared Savannah band.
   - Rare: frame_r_snowglobe and frame_r_icicle both read as a plain white ring with a bump on top. Change one of them in colour block or silhouette (e.g. icicle = hanging spikes clearly longer and wider, or give it a pale-blue band instead of white).
2. Epic and above frames: export the moving layers as the separate transparent 256x256 PNGs named in the loop specs (rune_orbit, rune_glow, fireflies, lantern_glow, stars, shield_sheen, sun_glow, sparkles, crown_sheen, gem_glints, eclipse, core_glow, glint), static pose, same canvas and centre as the base. Name them frame_<id>_<layer>.png in frames/. The combined *_anim.png can stay as a preview.
3. Rare dice: make the frost facet bigger (about 14-16 px at 104, so it is still visible at 36) on all six class skins. Keep it out of the value row.
4. Previews: add frame previews at 40 / 96 / 256 around a dummy avatar (not only the 40 px sheet).
5. Manifest: keep the old `frames_with_art` / `frames_waiting_for_art` keys out, but add `"image_size": [256,256]` and `"window_radius_px": 84` per frame so our loader can validate them.
6. Please confirm in one line that no frame uses the old Homeland bitmaps (c_bird and u_pond notes say "redrawn from frame_3 / frame_1").
```

## Import list for our technical-artist (into godot/assets/cosmetics/)

Safe to import now (from `export/cosmetics-01-v7/`):
- `dice/` all 20 skins: 12 `_plate.png`, 6 `_base.png` + `_glow.png` (Epic/Legendary), Mythic `_base`, `_glow`, `_max` (30 files shown in export, glow = blend Add).
- `frames/*_base.png` all 21 (they are final enough; the fixes above only change Common/Rare silhouettes, so re-import those after the next version: c_plant, c_bug, c_bird, r_snowglobe or r_icicle).
- `frames/*_anim.png` (7): import as placeholders only. Wait for the separate layers before building the animation.
- `cosmetics_manifest.json`: merge, do not overwrite blindly. Fix loaders/tests that read `frames_with_art` and `frames_waiting_for_art` first.
- Reference only (don't ship in game): `contact-sheet.png`, `frames_40px_check.png`, `preview_104_64_36.png`.
- Not needed: `Cosmetics 01 v7.dc.html`, `cosmetics-art-v7.js`, screenshots.

Do a pixel check (size 256/512, alpha, window O168 clear of paint) with t_assets after import.
