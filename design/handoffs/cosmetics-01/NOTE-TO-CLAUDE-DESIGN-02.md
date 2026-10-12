# Ghi chú gửi Claude Design — Cosmetics 01, lượt sửa 2

Soạn 12/10/2026 từ `REVIEW.md` §9, sửa theo quyết định A1–A5 của Liam (đầu `REVIEW.md`).
Liam dán phần tiếng Anh bên dưới vào Claude Design, kèm các file đính kèm ở cuối.

---

Thanks for Cosmetics 01 v6. The 20 die plates are in and in good shape. Decisions on our side and what we need next:

**Direction (decided)**
- **Style:** keep the Homeland look you used (soft gradients, warm red-brown linework). It fits the 3D world. The one rule: at small sizes (36–40 px) every plate and frame needs a bold, dark outline so it still reads as an object.
- **Mythic colour:** `#FF3D6E` (Luna Crimson) is approved for rarity chips, borders, tier names and frames only. Never put white (≈3.4:1) or cream (≈2.8:1) text on it. Use dark ink `#1A1206`. One shared night background for Mythic: `#2A0F2E`.
- **Legendary frame:** a gold sun (`sunburst`), not the silver-teal gears.

**Die plates (fixes)**
1. Keep the value row clean. Pull the sun rays of `die_l_gold` down so nothing rises above y=410 at 512; lower the mushroom caps on `die_e_spore`; cut the vertical centre seam of `die_r_bug` short (stop before y=225); soften the scale/hex/weave lines inside the calm zone on `die_r_aqua`, `die_r_reptile`, `die_c_reed` (about 40% less contrast).
2. `die_e_s1_founder`: the "SEASON 1" ribbon uses a serif italic. Use Baloo 2 800 or drop the text for a numeral badge. It is unreadable below 104 px.
3. Mythic dark skins (`die_m_redcrystal`, `die_m_moon`): the border disappears into the night field at 36 px. Use a black or near-black border. Put `#FF3D6E` into one detail on `die_m_redcrystal` (the crystal core works).
4. Epic and above: deliver a clean base plate with no baked glow, plus a separate transparent `glow.png`, and a MAX layer for the two Mythic skins (full moon, open eyes, grown crystals). Baked items to pull out: spore halos and spores (`die_e_spore`), seam glow (`die_l_relic_stone`), corner stars (`die_e_s1_founder`).
5. Please include the previews we asked for (`preview_104_64_36`) and the overall contact sheet. They were not in the package.
6. For Rare, add one small shared "frost" detail (cold-blue rim or snowflake facet) so the tier reads as Arctic across all six class skins.
7. Keep the lilac on `die_r_reptile`: Reptile is the purple class, the Epic chip tells the tiers apart.

**Frames: redraw all 21 in one style**
The five frames we sent (`frames/`) are Homeland sample frames. Use them as the reference for style, shape language and colour, but please draw all 21 fresh in that one style so the set is consistent. Do not reuse the bitmaps.
- Full list: c_bird, c_plant, c_beast, c_aqua, c_reptile, c_bug · u_pond, u_vine, u_mushroom, u_campfire · r_frost, r_snowglobe, r_aurora, r_icicle · e_runering, e_firefly, e_s1_founder · l_sunburst, l_sovereign · m_eclipse, m_crystal.
- Fix the themes of the three that were off: `frame_e_runering` is a rune ring (not a bowl), `frame_l_sunburst` is a gold sun, `frame_m_eclipse` uses the crimson/night Mythic palette (keep the crescent moon on top).
- Spec per frame: 256×256 square transparent PNG, centred Ø168 window, the frame may overlap the window edge by at most 8 px, readable at 40 px, previews at 40/96/256 around a dummy avatar. Frames in the same tier must differ in silhouette or colour block at 40 px. The four Rare frames must also not read as Uncommon green.
- Epic and above: static base + the moving layer as a separate PNG (rune spin, fireflies, sun idle...), a short loop spec, and a Reduce-flashing variant.
- The six biome contact sheets are attached. Please use them: Savannah for Common, Forest for Uncommon, Arctic for Rare, Mystic for Epic, Genesis for Legendary, LunaLanding for Mythic.

**FX: spec updates only (no new art)**
Add the missing face-type colour bits to `fx_r_frost`, `fx_e_rune`, `fx_m_lunar`; cap the four "40 per die" FX at 34; make the `fx_m_lunar` sheen ≤ 0.25 s, dim only the tray under the dice, one eclipse per roll (not per die); the reduced variant of `fx_u_ember` holds a single flame shape; match `fx_l_sunfire` to the new gold-sun `frame_l_sunburst`.

---

## File đính kèm (Liam tải lên cùng ghi chú)
- 5 khung tham chiếu: `godot/assets/cosmetics/frames/*.png`
- 6 contact sheet biome (chỉ có trên máy, không commit):
  `asset-library/godot-ready/contact_sheets/HomeLand_Asset_Environment_{Savannah,Forest,Arctic,Mystic,Genesis,LunaLanding}_1.png`
- Manifest hiện tại để Claude Design giữ đúng ID: `godot/assets/cosmetics/cosmetics_manifest.json`
