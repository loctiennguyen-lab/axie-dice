# Review: lane C, biome battlefield (010820f, l1/C)

Verdict: MERGE WITH FOLLOW-UPS (boss look is the one item I would fix before Liam sees it)

Limits: no shell, so no `git show` and no image shrinking. I viewed savannah, forest, luna and savannah-boss at original size. I did NOT view arctic, mystic or genesis. I did not read the diff. The review is visual only.

## What works
- Forest: best of the set. Clear green ground, trees and bushes at the edges, flowers, stone path. Party and enemy stand areas are clear and the axies read well against the ground.
- Party row and enemy row are unobstructed in savannah, forest and luna. Props stay on the flanks.
- Luna: crystals and the red spire give identity, and the dark ground keeps the axies readable. No floating props or z-fighting seen in the four shots. Shadows are soft and sit on the ground.
- Savannah and boss share the same orange-edged stone path, so the arena reads as one family.

## Problems
1. Boss look (author is right): sky and fog go flat brown, so the horizon disappears and the whole screen is one mud tone. The 1.5x portal is cropped by the top of the frame, and only the red cap and the diamond show. The big rock on the right touches the mushroom enemy, which crowds the enemy stand.
2. Portal is cropped at the top in ALL shots, not only the boss (the tower top sits on the frame edge in savannah, forest and luna). The boss only makes it worse.
3. Savannah is washed out: pale yellow sky and ground with almost no value contrast, and the horizon is a faint line. Next to the saturated orange Land hub it looks faded. The fog looks too thick for a non-boss.
4. Luna is a flat navy slab with no horizon or ground texture. Readable, but dull. It has no warmth, unlike the Land hub (lavender tiers 4 and 6 are the Land's own exception).
5. The centre enemy (chameleon) sits right on the portal base, so the two silhouettes merge. Either shift the portal back or lift it.

## Concrete fixes
- Boss: keep the portal at 1.5x only if the camera framing or portal Z moves so the whole tower fits. Otherwise use 1.2x and a larger red glow. Change the sky and fog from brown to a dark red-maroon sky with a lighter orange horizon band, so the horizon reads. Lower the fog density, since "thicker" is what makes it muddy. Keep the sun red and dim, but push the ground saturation up. Move the big flank rock about 1.5 enemy-widths away from the right enemy.
- All biomes: add a portal top margin check, because the top of the tower should not touch the frame at 16:9.
- Savannah: cut the fog density and raise ground saturation or darken it slightly (about 15%), so the horizon and the party rim read.
- Luna: add a lighter horizon band or a few ground flecks. Optional.
- Add a keep-out zone in the prop scatter for the two enemy flanks and the centre portal line, so props never touch the enemy row.
- Land hub link: the Land uses sun ffe2b0 at 1.25 with ambient fff1d6. Check that arena sun and ambient use the same warm values at base, and that biome variation comes from the sky and ground only. This was follow-up 6 of the L review.

## Needs a second look (not viewed)
Arctic, mystic and genesis: check portal crop, white-on-white readability in arctic, and fog contrast in mystic. FPS 120 is the vsync cap, so it says nothing about headroom.
