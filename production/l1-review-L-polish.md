# Review: lane L, Land hub polish (0b9b7d6, fe8b549)

Verdict: MERGE WITH FOLLOW-UPS

Limits of this review: no shell in my session, so I could not run `git show` or shrink the images. I read the three screenshots at original size and checked Land.gd, houses.json and the R3 backdrop with Grep. I did not read the diff line by line.

## Against Liam's ask
- Warm light: done. Sun is `ffe2b0` at 1.25, ambient `fff1d6`, shadow blur 2.2. This matches the R3 palette (cream `F4E6C6`, amber `FAD27C/F2B652/DE9A3C`, sky `A9DDF0`). Tiers 4 and 6 switch to lavender light, which is a deliberate biome choice. R3 only defines the warm set, so please confirm Liam wants the lavender.
- Soft shadows: on, but hard to see. They show under the houses in the portal-yaw shot and barely in tier1. Not a blocker.
- Portal rotated 90 degrees: `houses.json` has yaw 90 for the portal. The opening faces the camera and is readable in all three shots. Done. The Land.gd table default is still 0.0, which is fine because the json overrides it.
- Pass shows 29 Dec 2026: done. The label reads "Season 1 · ends 29 Dec 2026" (Land.gd:95). It is visible in tier1 and tier4.
- Real dirt / biome terrain: only partly done. The top slab is still a flat saturated orange in tier1 and flat purple in tier4. What you see is a gradient with scattered tufts and rocks. It reads as a painted tabletop, not dirt ground.
- Denser decor: done. Trees, rocks, tufts and puffballs fill the plot.

## Must-fix
None blocking merge. One item to confirm with Liam before he signs off: is the flat-coloured slab acceptable as "real dirt ground"? If he expects visible soil texture, that is a FIX FIRST for that item.

## Follow-ups
1. Tier4 ground: the many white translucent squares look like floating paper or z-fighting flecks, and some cross the paths near the portal and Echo Box. Make them smaller or fewer, or make them read as stones or flowers. Keep the portal centre and the paths clear.
2. Tier1 clutter: tufts and rocks sit right behind and beside the Portal, and under the RUN plate. The pink Axie also overlaps a bush near the House. Add a keep-out radius around the portal and the paths, about 150 px at the 1920 reference.
3. The RUN plate overlaps the Portal base. This is probably older than this change, but the denser decor makes it more visible.
4. Check the 12 px floor on the plot subtitles ("Builds at Arctic Land", "Team presets"). They look about 9-10 px in the 1200 px view. That is only my estimate, since the screenshots are scaled. Check against the 1920 render.
5. Tier1 shows stray CLAIM badges away from any house (right edge, near the Vault). Confirm they are anchored to the correct building.
6. Lighting is ortho-fast and tuned for the Land only. CombatArena3D uses sky ambient at 0.9 and per-biome light. If Land and arenas should feel like one world, align the ambient source and energy later.
7. Nothing in the three shots shows floating props or stretched textures.
