extends SubViewportContainer
class_name CombatStage3D
## Single shared 3D "battlefield" for every unit in a combat (godot-port-rule-spec.md UI
## layout task, perf fix). Before this: each UnitPortrait built its OWN SubViewport +
## Camera3D + DirectionalLight3D + WorldEnvironment (up to 11 full copies per fight — 5
## party + up to ~6 enemies). Now: exactly ONE of each, shared — every AxieCharacter3D (or
## capsule fallback, same safety net as before) is just a child Node3D placed at a fixed
## slot position in this one shared world. UnitPortrait.gd owns none of the 3D setup; it is a
## pure 2D name/HP/status/intent card (see its file header). It CAN, however, be clicked
## directly on its 3D model now too — see unit_clicked signal below (bug report: clicking the
## big model in the middle of the screen used to do nothing at all).
##
## Positioning is fixed-slot, not physics or pathing: party sits on a near row
## (_POS_Z_PARTY), enemies on a far row (_POS_Z_ENEMY), evenly centered per row. No
## animation/Tween here — that is architecture-plan checklist step 7 (juice pass), out of
## scope for this layout pass.
##
## Renders with a TRANSPARENT background (SubViewport.transparent_bg=true +
## Environment.background_mode=BG_CLEAR_COLOR) so Combat.tscn's Background TextureRect art
## shows through behind the characters instead of a flat color box. BG_CLEAR_COLOR (=0) was
## read directly off the installed Godot 4.7.2 binary via a throwaway --headless script
## before use, not assumed from training data — VERSION.md flags 4.4-4.6 as a knowledge gap
## for this LLM and this project is actually pinned to 4.7.2 (see report: VERSION.md itself
## is stale and should be corrected by whoever owns it).

## Emitted when the player clicks directly on a unit's 3D model (see _gui_input()/
## _pick_unit_at() further down). CombatView.gd connects this straight to the SAME handler used
## for UnitPortrait.clicked (_on_target_clicked) — this is a second input path into the existing
## click-click flow, never a new one (matches the project's own drag-and-drop precedent in
## technical-preferences.md: a second input path calling into the same handler).
signal unit_clicked(uid: int)

## Right-click on a unit's 3D model — ALWAYS the inspector, whether or not a die is selected.
##
## Left-click is context-dependent by design (src/client.html:5273: a legal target is a target,
## everything else opens the inspector), which means that while a die IS selected there is no
## left-click that can answer "what does this thing do?". Right-click is the second door, and
## it never changes game state. CombatView connects this to _open_unit_inspect() directly.
signal unit_inspect_requested(uid: int)

## catalog.json's `colors` table (addons/axie_mixer_3d_assets/catalog.json) has ~5-6 swatches
## per class ("<class>-00" .. "<class>-06"). The "-00" swatch (index 0/6/11/17/22/27 — what
## this table used to point at) is every class's near-white/cream DEFAULT skin tone
## (verified against catalog.json: beast-00 primary1=fdfcf2, plant-00=fefdf1,
## aquatic-00=f4fff4, bug-00=fffaf5, bird-00=fff7ff, reptile-00=fff7ff — all near-white),
## because the shader's `primary_color` (s_axie_mixer_v5.gdshader) tints the texture's
## alpha>=0.7 band, which covers most of the visible body — so "-00" reads as pale/washed
## white for every class alike (bug report: "model Axie 3D đều trắng nhạt giống hệt nhau").
## Picking each class's saturated "iconic" swatch instead fixes legibility:
const _CLASS_COLOR_VARIANT := {
	"plant": 8,    # plant-02  primary=afdb1b (bright green)
	"beast": 3,    # beast-03  primary=fdb014 (orange)
	"aqua": 14,    # aquatic-03 primary=00dff3 (cyan blue)
	"reptile": 30, # reptile-03 primary=9967fb (violet/purple)
	"bug": 20,     # bug-03    primary=ff433e (red)
	"bird": 26,    # bird-04   primary=ff78b4 (pink)
}
const _ENEMY_COLOR_VARIANT := 44   # Mech:01 — primary=505050 dark grey (index 43/Mech:00's
	# primary was the same near-white default described above); dark grey reads as clearly
	# "metal/neutral" and distinct from every hero class color above.

const _PLACEHOLDER_COLOR := {
	"plant": Color(0.35, 0.7, 0.35), "beast": Color(0.75, 0.55, 0.3), "aqua": Color(0.3, 0.55, 0.85),
	"reptile": Color(0.55, 0.35, 0.75), "bug": Color(0.75, 0.7, 0.2), "bird": Color(0.85, 0.4, 0.4),
}
const _ENEMY_PLACEHOLDER_COLOR := Color(0.55, 0.2, 0.2)

## Eye-glow color table (design/ux/combat-screen-shroom-gloom-inspired.md §5.3/§8, Decision 3 —
## resolved: real `OmniLight3D`, NOT a reuse of `AxieMysticGlow` — that pipeline stays reserved
## for the Cosmic/Mythic-die rarity signal, see that file's own header and this spec's §0/§15).
## Deliberately a SEPARATE table from `_CLASS_COLOR_VARIANT` above (per spec §8: that table is a
## mesh-recolor swatch INDEX into catalog.json, not a usable `Color` — a light needs an actual
## `Color`). Non-hero enemy (`cls==""`) falls back to `_ENEMY_EYE_GLOW_COLOR` (grey-red), exactly
## as the spec's Data Requirements table specifies — this is keyed purely by `cls`, independent
## of `is_enemy`, so an enemy that happens to BE one of the 6 hero classes still reads with that
## class's own eye color (only `_ENEMY_COLOR_VARIANT`'s body recolor, done elsewhere, signals
## "this is an enemy").
const _EYE_GLOW_COLOR := {
	"plant": Color(0.55, 1.0, 0.35),
	"beast": Color(1.0, 0.65, 0.15),
	"aqua": Color(0.25, 0.85, 1.0),
	"reptile": Color(0.7, 0.35, 1.0),
	"bug": Color(1.0, 0.25, 0.2),
	"bird": Color(1.0, 0.45, 0.75),
}
const _ENEMY_EYE_GLOW_COLOR := Color(0.75, 0.35, 0.32)   # grey-red, non-hero enemy fallback

const _EYE_HEIGHT := 1.3 * UNIT_SCALE            # world-space Y offset above a unit's slot origin — roughly
	# eye level for both the capsule placeholder (base at y=0.8, height 1.4) and AxieCharacter3D.
const _EYE_LIGHT_ENERGY := 1.4       # "small" point light — enough to read as a personality
	# accent (spec §5.3), never bright enough to act as gameplay lighting on its own.
const _EYE_LIGHT_RANGE := 0.6
const _EYE_LIGHT_SPAWN_DURATION := 0.15   # spec §10 "Eye-glow spawn: fade 0->target, 150ms ease out"

## Boss visual. Every boss is a Chimera sprite, exactly like every rank-and-file enemy —
## MonsterArt.BOSS_SPRITES maps all six ContentDB boss keys, and `is_boss` only changes SCALE
## (_BOSS_SCALE), never the source of the art.
##
## 3D MODELS FOR FOUR BOSSES — restored 2026-09-19, under a rule the owner AMENDED.
##
## The old rule was "monsters and bosses come only from the Chimera library", written after a
## boss shipped wearing `pomodoro` — which is the display name of the Bug-class HERO in the
## player's own party, so the game was fielding one of the player's own characters as a boss.
## That specific failure is still forbidden and still gated (`t_assets`, by IDENTITY not by
## filename). What the owner changed is the blanket part: with no new Chimera art available,
## Starter Axie models MAY be used for bosses **provided they do not collide with a hero**.
##
## Four do not: paladill, kotaro, xia, kibo. Two never will: `pomodoro` and `machito` are hero
## names. The remaining two (bing, tripp) are deliberately unused — they read as friendly pets,
## and a boss that looks like a pet is the same mistake in a different costume.
##
## Why models rather than more sprites: the kit has 21 usable Chimeras for 17 monsters, 4 elites
## and 6 bosses. Somebody has to share, and the boss is the worst candidate — the fight a run
## builds toward should not look like the thing you already killed twice, only bigger. A model
## is also animated, so a boss breathes while the rank and file are flat billboards.
##
## --- Fallback-tier constants below (unmapped boss keys only) ---
## STATUS as of the enemy-sprite pass (ui-programmer, real-monster-art follow-up): this
## AxieCharacter3D-recolor tier is UNREACHABLE today, not just de-prioritized. spawn_unit()'s
## branch order below is glb (2 keys) -> Chimera sprite (MonsterArt, checked next) -> this
## recolor tier last — and MonsterArt.BOSS_SPRITES now maps all 6 ContentDB boss keys
## (verified directly against that file + tests/t_assets.gd's "every boss has a sprite that
## loads" gate), so every is_boss unit_key resolves at the sprite tier before ever reaching
## here. This block is kept, unedited, purely as a safety net for a FUTURE boss key that ships
## with no MonsterArt entry yet (a mapping omission, not today's normal case) — it must not be
## read as live/exercised code, only as a defensive fallback. If MonsterArt ever loses coverage
## of a boss key, this is what renders instead of nothing.
## Indices are catalog.json `colors` table entries (same table _CLASS_COLOR_VARIANT/
## _ENEMY_COLOR_VARIANT above already read from — verified directly against the file, not
## guessed), picked to be a clearly MORE saturated/darker shade than the hero-class swatch of the
## same family already in use above, so a boss never reads as "an oversized party member":
## (Boss/monster 3D models now come from assets/atia/atia_models.json via MonsterArt.resolve(); see
## _make_atia_model(). The old BOSS_MODELS table and _BOSS_MODEL_HEIGHT_M no longer exist.)

const _BOSS_COLOR_VARIANT := {
	"agony": 21,       # bug-04, primary=df2e54 (deep blood-red) — CHIMERA_NOTES.md's retired
		# portrait for this boss was a werewolf/agony-themed fierce red brute; darker/deeper than
		# the bug-CLASS hero swatch (bug-03, index 20, ff433e) already used above, so a red bug-
		# class hero and this boss are never visually identical.
	"gooey_king": 15,  # aquatic-04, primary=00b8ff (deep saturated blue) — CHIMERA_NOTES.md's
		# retired portrait was a big blue slime boss; more saturated than the aqua-CLASS hero
		# swatch (aquatic-03, index 14, 00dff3 cyan) already used above, same "distinct from the
		# hero of the same family" rationale as agony.
}
## Uniform scale multiplier applied to a boss's AxieCharacter3D.root (or the capsule placeholder,
## on the from_descriptor()==null fallback path) — within the user-specified 1.4-1.6x range,
## picked at the midpoint so every boss reads as clearly larger than any rank-and-file enemy
## (always scale 1.0) without per-boss tuning.
## Verified against a real boss screenshot, not computed: at 1.5 the FROST LORD rendered
## NO LARGER than a party Axie, because the enemy row sits further from the camera
## (_POS_Z_ENEMY) and perspective already shrinks it. The multiplier has to beat that
## foreshortening before it starts reading as "boss".
## 2.15 -> 1.85 on 20 Sep 2026, and the multiplier going DOWN is how the boss gets BIGGER.
##
## _ENEMY_SPRITE_HEIGHT_M just rose 1.7 -> 2.55, and this multiplies it. Left at 2.15 a boss
## would be 5.48m, projecting ~311px, with its top at y = 469 - 311 = 158. The enemy nameplate
## is now pinned at y=125 and runs to y=189 (CombatView._ENEMY_PLATE_TOP, from combat-v2.html's
## absolutely-positioned enemy column), so the boss's head would come up THROUGH its own
## nameplate by about 31px. That is the exact failure an earlier pass wrote a warning about in
## this file: raising the sprite height "is NOT safe to do alone".
##
## 1.85 keeps the boss's top clear of the plate with a margin: 2.55 * 1.85 = 4.72m, ~268px,
## top at y ~= 201, twelve pixels below the plate. In absolute terms the boss still grew —
## ~208px before this change, ~268px after — it is only the RATIO to a rank-and-file monster
## that fell, from 2.15 to 1.85. A boss still reads as a boss; it just no longer wears its
## nameplate as a hat.
##
## These figures come from the projection arithmetic above, not from a capture. Measure a real
## boss encounter before trusting the 12px margin.
const _BOSS_SCALE := 2.2

## Target on-screen height (meters) for a rank-and-file enemy's Chimera Sprite3D (see
## spawn_unit()'s `elif is_enemy and MonsterArt.texture_for(...)` branch and
## _make_enemy_sprite() below). The 20 source PNGs are trimmed to their own art (different pixel
## dimensions per creature — a slime and a treant do not share an aspect ratio), so sizing by a
## flat scale factor would make some creatures read bigger than others for no gameplay reason;
## sizing by TARGET WORLD HEIGHT instead (pixel_size = height / texture.get_height()) makes
## every enemy occupy roughly the same vertical footprint on the battlefield regardless of its
## source image's own resolution. Picked close to HEAD_HEIGHT (1.55, below) so a sprite's own
## top edge roughly lines up with where UnitHeadHUD already anchors itself — verified against a
## real screenshot afterward, not just computed (this file's own recurring note: --headless
## cannot render real pixels). Bosses multiply this by _BOSS_SCALE, same as every other boss
## up-sizing path in this file.
## 1.7 -> 2.55 on 20 Sep 2026: the owner's "monsters 1.5x bigger".
##
## The design review measured the gap this closes. At _POS_Z_ENEMY the enemy row sits about
## 20.2 world units from the camera, so one metre projects to roughly 1148.06 / 20.2 = 56.8px:
## a 1.7m sprite rendered ~97px against the 166-196px combat-v2.html draws, leaving ~147px of
## empty air between a pinned nameplate and the creature under it. 2.55m renders ~145px and
## closes most of that.
##
## This does NOT fully reach the mockup, and that is not a rounding error. The mockup is flat
## 2D and draws both rows at one scale; a single perspective camera over one ground plane
## cannot give two rows equal apparent size AND vertical separation. Going further means a
## per-row scale compensation or a second camera — a design decision, not a constant.
const _ENEMY_SPRITE_HEIGHT_M := 2.55

## Ground-contact shadow (visual-polish backlog P1-1, 2026-09-19 QA audit —
## production/qa/2026-09-19_visual-polish-backlog.md: "cả 5 Axie phe ta lẫn quái đứng trên cát
## ... nhưng không có vùng tối dưới chân ... khiến chúng trông như dán đè lên ảnh nền"). A flat,
## unshaded quad laid on the ground plane under every unit's `slot`, textured with a radial
## GradientTexture2D — the SAME technique CombatView.gd's own _build_gradient_textures() already
## uses for the battlefield vignette (black, center-to-edge alpha falloff), just applied to a 3D
## quad instead of a 2D TextureRect. Built ONCE (_shadow_texture, set up in _build_world()) and
## shared by every unit's shadow MeshInstance3D — the same Texture2D resource on every quad, only
## each quad's own `size` differs. No PNG asset needed, per the task's own instruction to reuse
## the existing gradient-texture technique rather than ship new art.
##
## Sized off the unit's own on-screen footprint at spawn time (see spawn_unit()'s three branches
## and _make_ground_shadow() below), so a capsule placeholder, a real AxieCharacter3D rig, and a
## Chimera Sprite3D enemy each get a shadow that actually matches how wide THAT unit reads, and a
## boss (_BOSS_SCALE) gets a visibly bigger shadow than a rank-and-file unit — never one fixed
## size for every unit regardless of how big it actually is (task note: "bóng phải co theo kích
## thước unit, đừng cố định một cỡ cho mọi con").
const _SHADOW_ALPHA := 0.35
const _SHADOW_RADIUS_MULT := 0.6    # spec: "bán kính ~0.6× bề rộng model" -> quad size (diameter)
	# = width * _SHADOW_RADIUS_MULT * 2.0
const _SHADOW_Y_OFFSET := 0.02      # just above the y=0 ground plane every visual path in this
	# file already sits its own base on (AxieCharacter3D.root, capsule placeholder, Sprite3D
	# feet) — avoids z-fighting against anything that might ever render exactly at y=0
const _SHADOW_TEXTURE_SIZE := 128   # GradientTexture2D bake resolution for the shared shadow blob

## Approximate on-ground "width" (meters) used to size the shadow quad for visual paths with no
## cheap bounding-box query at spawn time (the real AxieCharacter3D rig) or a fixed known size
## (the capsule placeholder, 2x its own CapsuleMesh.radius). The Chimera sprite enemy branch
## computes its own width directly from the sprite's actual pixel dimensions instead of using
## either constant below (see spawn_unit()'s sprite branch) — it is the one path where an exact
## width is already on hand for free.
const _CHARACTER_SHADOW_WIDTH_M := 1.0   # matches AxieCharacter3D's typical body footprint at
	# this stage's fixed camera framing, cross-checked against the same real screenshots this
	# file's camera-framing-pass comment already cites (production/qa/evidence/
	# 2026-09-18_real-flow-*.png)
const _CAPSULE_SHADOW_WIDTH_M := 0.8     # = 2 x CapsuleMesh.radius (0.4) from _make_placeholder()

const _CLASS_PART_CLASS := {
	"plant": "Plant", "beast": "Beast", "aqua": "Aquatic",
	"reptile": "Reptile", "bug": "Bug", "bird": "Bird",
}

## Variant 2 chosen because it is the ONLY variant number available at skin=S00 level=L1 for
## EVERY part type in EVERY one of the 6 classes (verified by enumerating catalog.json's
## `parts` keys): Back/Ear/Horn/Tail ship variants {2,4,6,8,10,12} per class, but Eye/Mouth
## ship only {2,4,8,10} per class — 2 is the only number in both sets, uniformly, for all 6
## classes. No per-class/per-slot exceptions needed as a result; AxiePartResolver's documented
## S{skin}L{level} → S{skin}L1 → S00L{level} → S00L1 fallback (README "Part fallback khi
## skin/level không có") still applies inside AxieFactory.build_character() as a safety net,
## but skin=0/level=1 already resolves directly for every (class, part type) pair used here.
const _PART_VARIANT := 2
const _PART_TYPES: Array[int] = [
	AxieTypes.Part.MOUTH, AxieTypes.Part.HORN, AxieTypes.Part.BACK,
	AxieTypes.Part.TAIL, AxieTypes.Part.EAR, AxieTypes.Part.EYE,
]

## Framing pass (ui-programmer task 1/4 — "Axie lùi lại", user screenshot feedback: party models
## read as "pressed against the camera" with almost no headroom/margin around them). Values below
## replace the original (_ROW_SPACING 1.7, _POS_Z_PARTY 2.6, _POS_Z_ENEMY -2.2, camera at
## Vector3(0,3.4,9.5)/fov 42) with the camera moved back + narrower FOV (shrinks apparent
## character size — "đứng trên sân" instead of "áp sát camera") plus slightly wider row spacing
## and a party row pulled back a touch, all verified empirically against real screenshots
## (production/qa/evidence/2026-09-18_camera-framing_*.png — this engine's --headless mode
## cannot render real pixels, see t_stage3d_facing.gd's own note, so this was NOT eyeballed from
## numbers alone).
##
## Enemy sprite pass (ui-programmer, real-monster-art follow-up — bug report: "quái là 4 bóng đen
## giống hệt nhau" + nameplates crowding/touching, production/qa/evidence/
## 2026-09-18_real-flow-varied-enemies.png). The enemy row is the FAR row (_POS_Z_ENEMY, further
## from camera) — perspective projection compresses its world-space spacing into a much smaller
## screen-space gap than the same spacing gives the near party row, which is what made 4
## same-width silhouettes (and now 4 differently-shaped Chimera sprites, potentially wider than
## the old capsules) and their nameplates read as crowded/touching even though _ROW_SPACING was a
## single shared value. Split into a per-row constant so the enemy row can be widened
## independently without moving the party row (already tuned) — value picked empirically against
## real screenshots (this file's own long-standing note above: --headless cannot render real
## pixels, so this was verified the same way the camera framing pass above was).
## RETUNED 2026-09-20 against `docs/design-handoff-v2/mockups-v2/combat-v2.html` — the only way
## to move this screen's LAYOUT BOXES, since the party keeps the 3D gene rig and the monsters
## keep their sprites (user decision; godot/CLAUDE.md "Art that is NOT taken from the mockups").
##
## The four numbers below are solved, not guessed. The stage is a SubViewportContainer with
## `stretch = true`, so the SubViewport is the Control's own rect — 1920 x 702 at the 1080-tall
## canvas (Combat.tscn anchors it 0.13 .. 0.78) — and with `fov = 34` vertical the projection is
## a flat `px_per_world_unit = (702/2)/tan(17°) / depth = 1148.06 / depth`, the same on both axes.
##
##   * The mockup's ENEMY column pitch is 186 + 104 = 290px and its band bottoms out at y≈445.
##   * The mockup's PARTY column pitch is 180 + 14 = 194px and its band bottoms out at y≈824.
##
## At the old values the enemy row projected to a 167px pitch — NARROWER than the 176px nameplate
## every enemy carries, which is exactly the "two enemy nameplates sit flush against each other"
## defect. CB-09 forbids fixing that on the plate's side (no text-measured, no capped widths), so
## it is fixed here, where the relationship actually lives.
##
## Depth also had to move, and for a second reason: combat-v2.html stacks BOTH columns as
## status -> nameplate -> model, so the party's plate is now ABOVE its model. At the old row
## depths the two rows were only ~187px apart vertically and a party plate would have landed on
## top of the enemy models. z_party 5.45 / z_enemy -6.5 puts the enemy feet at y≈469 and the
## party feet at y≈824, i.e. 42px of clear air either side of the front line's fixed y=480.
##
## KNOWN CONSEQUENCE, flagged rather than compensated: the enemy row is 1.13x further from the
## camera than it was, so every monster sprite renders ~11% smaller (a 1.7m sprite goes 109px ->
## 97px). Compensating would mean raising `_ENEMY_SPRITE_HEIGHT_M`, and that is NOT safe to do
## alone — `HEAD_HEIGHT` (1.55, shared with the party rig) is what the nameplate anchors to, so a
## taller sprite would push its own head through its plate. See the task report.
## 2026-09-21 — THE PARTY ROW'S TAILS WERE BEING CUT OFF, reported against a 1920x1200 window.
## The arithmetic above solved z_party 5.45 to put the party FEET at y~824 against a band that
## bottoms out at 842: eighteen pixels. A tail hangs below the feet, so eighteen pixels is not
## clearance, it is the bug — and it is a fixed FRACTION of the band (SubViewportContainer
## stretches the render to its rect and the camera keeps its vertical fov), so it clips at every
## window size, not just the tall one. Extending the band down cannot fix it: the cut happens
## inside the render, not at the Control's edge.
##
## So the row moves BACK, not the camera. Moving the camera would drag the enemy row up into its
## own fixed-y nameplates (_ENEMY_COLUMN_TOP), which is a second defect to buy the first one.
## Depth goes 13.2 - 5.45 = 7.75 -> 13.2 - 5.15 = 8.05. Because the projection above is a flat
## `1148.06 / depth`, the on-screen column pitch shrinks by exactly that ratio, so the spacing is
## multiplied by 8.05 / 7.75 = 1.0387 to keep the mockup's 194px pitch. The models render ~4%
## smaller for the same reason; that is the price, and it is in the capture rather than argued
## about here.
##
## 5.15 IS A BALANCE POINT, NOT A ROUND NUMBER. Lifting the row lifts its nameplate stack with
## it, toward the front line at y=480 — so too much lift trades a cut tail for a status chip
## crowding the divider, which is the other half of what was asked for. Measured at this value,
## with `CombatView._DECK_H` at 204 and `_STAGE_BOTTOM_F` at 1.0: the warning chip clears the
## front line by 50px at a 1080 canvas and 73px at 1200, and the tails clear the deck bar at
## both. At 4.85 the tails were fine and the chip clearance fell to 14px.
const _ROW_SPACING_PARTY := 1.511
const _ROW_SPACING_ENEMY := 5.103
const _POS_Y := 0.0
const _POS_Z_PARTY := 5.15    # near row (camera-facing) — party; was 5.45, see above
const _POS_Z_ENEMY := -6.5    # far row — enemies, reads as "further back" per JRPG convention

## Horizontal layout (spec 02-combat/spec.md): world x runs left to right, +z is toward the camera.
## Party: two staggered rows, slots 0,2,4 in front (near the camera), 1,3 behind. Eggs: a third,
## nearest row bottom-left. Enemies: a staggered row on the right. The gate sits beyond them (arena x).
const PARTY_X0 := -10.0
const PARTY_PITCH_X := 1.3
const PARTY_Z_FRONT := 3.6
const PARTY_Z_BACK := -1.4
const EGG_X0 := -10.0
const EGG_PITCH_X := 1.5
const EGG_Z := 6.9
const ENEMY_CENTER_X := 3.6
const ENEMY_PITCH_X := 1.25   # a diagonal: neighbours stand on different depth rows, so they can be close in x
## Enemies stand on three depth rows (back, middle, front), index i takes row i % 3, so units that are close
## in x are far apart in y and 5 enemies fit between the gap and the gate. One enemy stands on the middle row.
const ENEMY_Z_BACK := -5.8
const ENEMY_Z_MID := 0.2
const ENEMY_Z_FRONT := 6.0
const BOSS_POS := Vector3(3.5, 0.0, 0.2)
const ELITE_POS := Vector3(3.5, 0.0, 0.2)   # spec: one elite, bigger
const ELITE_SCALE := 1.4
## Other enemies next to a boss or an elite: two on the front line, two on the back line, clear of the big one.
const ADD_SLOTS: Array[Vector3] = [Vector3(1.4, 0.0, 6.0), Vector3(4.9, 0.0, 6.0), Vector3(-1.0, 0.0, -5.8), Vector3(8.4, 0.0, -5.8)]
## Z of the path / gate lane. The arena is shifted onto it so the road to the gate runs behind the party, not under it.
const LANE_Z := 0.6
var _encounter_kind := ""


## "battle" | "elite" | "boss": decides how the enemy side is laid out. Call before units spawn.
func set_encounter_kind(kind: String) -> void:
	_encounter_kind = kind

## Facing fix (bug report: "Axie đang quay mặt về camera, muốn quay lưng lại tiến lên đánh
## boss"). AxieCharacter3D's default forward is NOT documented in this addon's own README, so
## this was verified against the vendored addon's own source instead of guessed: every one of
## the vendor's demo scripts (third_party/godot-axie-mixer-3d-main/examples/{spawner_demo,
## avatars_demo,collection_demo,mixer_demo}.gd) sets `root.rotation_degrees.y = 0.0` with the
## SAME comment, verbatim, at every call site: "front is +Z, toward the camera" — and every one
## of those demos places its camera on the +Z side looking back toward the origin (e.g.
## demo_kit.gd `ensure_stage()`: cam at `Vector3(0,1.2,3.5)` looking at `Vector3(0,0.7,0)`,
## exactly the "+Z camera, forward=+Z faces it" setup this file also uses (Camera3D below sits
## at `Vector3(0,3.4,9.5)`, i.e. also +Z, looking back toward -Z). So at rotation.y=0 (the
## untouched default used before this fix) a unit's forward vector is +Z, which points AT this
## camera — i.e. every unit, party included, faced the camera. Rotating 180° around Y flips
## local forward from +Z to -Z, which points from the party row (z=+2.6) toward the enemy row
## (z=-2.2, further along -Z) — back to the camera, face toward the enemies, the classic JRPG
## framing this bug report asked for. Enemy row is intentionally left at the default (rotation 0
## — see spawn_unit()) so it keeps facing the camera, per the same JRPG convention ("quái quay
## mặt về camera"). Rotating `slot` (not `character.root` directly) so the capsule placeholder
## fallback path picks up the same fix for free, even though the capsule is visually symmetric.
## HORIZONTAL LAYOUT (Liam, build b831 review): Axies on the left facing +X, enemies on the right
## facing -X. A unit's forward is local +Z, and Ry(t) maps +Z to (sin t, 0, cos t), so +90 faces +X.
const _PARTY_FACING_Y_DEG := 90.0
const _ENEMY_FACING_Y_DEG := -90.0

# --- Click-to-3D-model picking (bug report: attacking wasn't achievable — see CombatView.gd
## file-level note / report for the root-cause writeup). No CollisionShape3D exists on any unit
## here (AxieCharacter3D/capsule placeholder are pure visual meshes, and adding physics bodies
## just for point-and-click target selection would be new scope this pass doesn't need) — so
## picking is a plain screen-space nearest-point test: each alive unit's world position is
## projected to 2D via Camera3D.unproject_position(), and whichever projection is closest to the
## click (within _CLICK_PICK_RADIUS_PX) wins. Cheap, framework-free, and more than accurate
## enough for a battlefield of at most ~11 well-separated units. ---
const _CLICK_PICK_RADIUS_PX := 70.0
const _CLICK_TARGET_HEIGHT := 0.9 * UNIT_SCALE   # world-space Y offset added to a unit's slot origin before
	# projecting — roughly chest/head height (matches the capsule placeholder's own
	# `position.y = 0.8` in _make_placeholder()), so the pick point reads as "the body", not
	# the ground under its feet.

## World-space height offsets (meters above a unit's slot origin) for the 2D overlay layer's
## anchor points — see get_unit_screen_pos() below (review-uiux-battle-screen.md layout pass:
## Nameplate/UnitHeadHUD/TargetLinesLayer all position themselves off of these). CHEST_HEIGHT
## reuses the same value _pick_unit_at() already treats as "the body"; HEAD_HEIGHT is chosen to
## clear both the capsule placeholder (height 1.4, base at y=0.8 -> top ~1.5) and
## AxieCharacter3D's real mesh.
const FEET_HEIGHT := 0.0
const CHEST_HEIGHT := _CLICK_TARGET_HEIGHT
const HEAD_HEIGHT := 1.55 * UNIT_SCALE
const AXIE_HEAD_HEIGHT := 1.3 * UNIT_SCALE   ## status chips of party Axies sit just above the real head

## Per-face-type action clip/pace table (ui-programmer follow-up pass — user report: "chỉ dùng
## WalkAttack cho MỌI hành động — nhàm chán"). Face `type` strings are exactly the rule spec's die-
## face types (godot-port-rule-spec.md §2: dmg/shield/heal/mana/poison/buff/debuff/summon/blank);
## this table only picks among the 11 REAL clips this addon ships (anim_names.gd) — no new clip is
## invented. Two families, matching the rule spec's own "Ally targeting" split (§2: shield/heal/
## buff/mana/summon are self/ally-directed, dmg/poison/debuff are enemy-directed):
##  - enemy-directed (dmg/poison/debuff) -> an *Attack clip (unit visibly closes on its target).
##    `dmg` is untouched (WalkAttack @ 1.0, "giữ như cũ" per the task brief). poison/debuff ALSO
##    switch clip (WalkAttack -> RunAttack), not just speed, so they read as a genuinely different
##    action from a plain damage swing, not the same pose in slow motion.
##  - self/ally-directed (shield/heal/buff/mana/summon) -> IdleCarryItem (stationary — none of
##    these ever target an enemy, so the unit must never "lao về phía trước"), differentiated only
##    by `time_scale`: heal slowest/gentlest, shield/buff a crisp equip-pop, mana the quickest (a
##    one-beat "cantrip" self-trigger), summon neutral.
## Any face_type not listed here (covers "blank" and any future/unrecognized type) falls through to
## _DEFAULT_ACTION_ANIM — the exact pre-existing WalkAttack/1.0 behavior, so nothing regresses for
## a type this table doesn't recognize.
const _ACTION_ANIM_BY_TYPE := {
	"dmg": {"clip": AnimNames.WalkAttack, "time_scale": 1.0},
	"poison": {"clip": AnimNames.RunAttack, "time_scale": 0.7},
	"debuff": {"clip": AnimNames.RunAttack, "time_scale": 0.85},
	"shield": {"clip": AnimNames.IdleCarryItem, "time_scale": 1.05},
	"buff": {"clip": AnimNames.IdleCarryItem, "time_scale": 1.05},
	"heal": {"clip": AnimNames.IdleCarryItem, "time_scale": 0.8},
	"mana": {"clip": AnimNames.IdleCarryItem, "time_scale": 1.35},
	"summon": {"clip": AnimNames.IdleCarryItem, "time_scale": 1.0},
}
const _DEFAULT_ACTION_ANIM := {"clip": AnimNames.WalkAttack, "time_scale": 1.0}

## ── "Ra chiêu" MOTION (2026-09-21) ────────────────────────────────────────────────────────
## The clip table above only reaches units that HAVE a rig. Every monster in the game is a
## billboarded Sprite3D (`_make_enemy_sprite()`) and most bosses are too, so for them
## `play_action()` returned without doing anything at all: a slime announced an attack, the
## number appeared, and nothing on the field moved. This is the motion that covers both — a
## Tween on the unit's own `slot`, which works whether the thing standing in it is a skeletal
## rig, a sprite or the capsule placeholder.
##
## It rides ON TOP of the clip rather than replacing it: a party Axie plays WalkAttack AND
## lunges, which is what makes an attack read as aimed at somebody rather than performed on
## the spot.
##
## WHY `slot` AND NOT `visual`. The idle "breathing" bob (_start_idle_bob()) already owns
## `visual.position:y`, and two tweens on one property fight. `slot` is free: only
## play_victory_march() (end of combat, no actions left) and _start_death_fade() (guarded by
## `dying`) touch it.
const _LUNGE_FRACTION := 0.35   ## how far toward the target, as a fraction of the real gap —
	## a fraction rather than a fixed distance so the enemy row (spacing 5.1) and the party row
	## (spacing 1.455) both read as "a step toward them" instead of one lunging past its target.
const _LUNGE_MAX := 2.6         ## metres. This cap, not _LUNGE_FRACTION, is what every real
	## lunge uses: the only faces that lunge are dmg/poison/debuff, all of which pick a target
	## in the OTHER row, and that gap is ~11.7m, so 35% of it (4.08m) is always clipped to here.
	## Raised from 1.1 on request ("tôi muốn quái đánh đã hơn"): at 1.1 the measured on-screen
	## step was ~16px against a 170px-wide monster sprite, which reads as a lean rather than a
	## strike. 2.6 still leaves the attacker at z=-3.9 from a rest of -6.5, well inside its own
	## half of a board whose midline is 0, so it does not "throw the model into the middle of
	## the board" the way 35% of the raw gap would.
const _LUNGE_OUT := 0.13
const _LUNGE_HOLD := 0.05
const _LUNGE_BACK := 0.20
## Squash/stretch, in SLOT space. Deliberately x/y only, never z: every monster is a camera-
## facing billboard, so a z scale is invisible on exactly the units this exists for.
const _LUNGE_STRETCH := Vector3(0.94, 1.07, 1.0)
const _LUNGE_SQUASH := Vector3(1.10, 0.90, 1.0)
## The in-place alternative for faces that do not reach out and hit someone — shield, buff,
## heal, mana, summon. Dip, rise past 1, settle, with the eye glow pulsing under it.
const _CAST_DIP := 0.10
const _CAST_RISE := 0.16
const _CAST_DIP_SCALE := Vector3(1.07, 0.90, 1.0)
const _CAST_RISE_SCALE := Vector3(0.95, 1.10, 1.0)
const _CAST_GLOW_MULT := 2.6

## Which face types LUNGE. The rest cast in place. Read off what the face actually does to
## somebody else, not off its animation clip: dmg/poison/debuff all pick an enemy and do
## something to it, so the motion should point at that enemy.
const _LUNGE_FACE_TYPES := ["dmg", "poison", "debuff"]

# --- Juice tuning (checklist step 7 — Tween-only, no gameplay logic) ---
const _SHAKE_STEPS := 6
const _DEATH_FADE_DURATION := 0.45   # scale-to-zero "disappear", see _start_death_fade() comment
const _IDLE_BOB_AMP_MIN := 0.05
const _IDLE_BOB_AMP_MAX := 0.1
const _IDLE_BOB_PERIOD_MIN := 1.0
const _IDLE_BOB_PERIOD_MAX := 2.0

@onready var _viewport: SubViewport = %Viewport3D

var _world: Node3D
var _camera: Camera3D
var _sun: DirectionalLight3D
var _env: Environment
var _arena: CombatArena3D = null
var _roller: DiceRoller3D = null
var _flash: ColorRect = null
var _exit_tween: Tween = null   # the running victory march/run, so skip_victory_march() can fast-forward it
## Victory run to the gate: x spread kept (fraction), how far past the portal origin they end, and
## how long the closing white flash takes (it ends exactly when the run does).
const _EXIT_X_PULL := 0.15
const _EXIT_PAST_GATE := 1.0
const _EXIT_FLASH := 0.3
var _shadow_texture: GradientTexture2D   # shared by every unit's ground shadow — see
	# _make_ground_shadow()/_build_shadow_texture() and the "Ground-contact shadow" const block
var _units: Dictionary = {}   # uid -> {"slot": Node3D, "character": AxieCharacter3D,
	# "visual": Node3D (character.root or placeholder mesh — idle-bob target),
	# "idle_tween": Tween, "dying": bool, "eye_light": OmniLight3D, "shadow": MeshInstance3D}
var _base_position: Vector2   # this Control's resting position — shake() always returns here
var _active_shake_tween: Tween = null


func _ready() -> void:
	# Was MOUSE_FILTER_IGNORE ("purely visual, all clicks go through the 2D UnitPortrait cards
	# in the top/bottom bands") — changed to STOP so clicking a unit's 3D model directly now
	# also works (see _gui_input()/unit_clicked signal below; bug report: players instinctively
	# tried clicking the big 3D model in the middle of the screen and got no response at all).
	# Safe: the nameplates and the deck are LATER siblings of this stage in Combat.tscn, and the
	# viewport picks by reverse child order, so neither loses a click to it. (The original
	# reasoning here — "the stage sits in its own MidStage band that never overlaps EnemyBand/
	# BottomBand" — described a layout that no longer exists; those bands were removed in the
	# 2026-09-17 layout rewrite. The conclusion still holds, for the reason above.)
	#
	# This assignment is the AUTHORITY, and it silently beat CombatStage3D.tscn's own
	# `mouse_filter = 2` for as long as both existed. The scene file now says STOP too, so the
	# two agree and reading either one tells the truth.
	mouse_filter = Control.MOUSE_FILTER_STOP
	_viewport.transparent_bg = true
	_viewport.own_world_3d = true
	_base_position = position
	_build_world()
	_roller = DiceRoller3D.new()
	_roller.name = "DiceRoller3D"
	add_child(_roller)
	_roller.setup(_world, _camera, self)


## The dice throw this stage owns (see DiceRoller3D). CombatView feeds it the turn's rolls.
func get_dice_roller() -> DiceRoller3D:
	return _roller


## The 3D slot node of a unit (where its die is thrown from), or null.
func slot_node_of(uid: int) -> Node3D:
	var entry: Dictionary = _units.get(uid, {})
	return entry.get("slot")


## Camera framing constants (kept here so frame_band() can re-derive them).
const _CAM_FOV := 19.0   # wider than before (was 34): the whole field zooms out so the teams have room
## Every unit is drawn at this fraction of its old size (Axies, monsters, boss, elite, eggs alike), so the
## two teams stand clearly apart. Relative sizes are unchanged: boss > elite > normal.
const UNIT_SCALE := 0.9
## Monsters are drawn smaller than Axies (their art is 2.55 m tall; at 0.9 they towered over the party).
const ENEMY_SCALE := 0.75
## Every monster is normalised by its REAL shape, not by its art's own size: sqrt(width x height) of the model
## (opaque pixels for sprites, mesh box for .glb) is scaled to ENEMY_SIZE_M, so a thin tall Thornback and a wide
## round Slime read as the same weight as an Axie. Elite = ELITE_SCALE x that, named boss = _BOSS_SCALE x.
const ENEMY_SIZE_M := 1.7
const _CAM_PITCH_DEG := -30.0
const _CAM_POS := Vector3(-0.2, 17.0, 28.0)   # 3/4 view across the field, slightly from above


## L6: the stage control now covers the whole canvas (height `canvas_h`) instead of a band
## [top, bottom], so the arena has no hard rectangular edge. This widens the vertical fov and
## tips the camera so a world point still lands on the SAME canvas pixel it used to inside the band:
## the focal length in pixels is unchanged (fov grows by canvas_h / band_h) and the optical axis
## moves from the band's centre to the canvas centre by a pure pitch about the camera centre.
## Pure maths, no RNG; safe to call on every resize.
func frame_band(canvas_h: float, top: float, bottom: float) -> void:
	if _camera == null:
		return
	var band_h := maxf(bottom - top, 1.0)
	canvas_h = maxf(canvas_h, band_h)
	var half_tan := tan(deg_to_rad(_CAM_FOV) * 0.5)
	_camera.fov = rad_to_deg(2.0 * atan(half_tan * canvas_h / band_h))
	var focal_px := (band_h * 0.5) / half_tan
	var band_centre := (top + bottom) * 0.5
	var pitch := atan((canvas_h * 0.5 - band_centre) / focal_px)
	_camera.rotation_degrees = Vector3(_CAM_PITCH_DEG - rad_to_deg(pitch), 0.0, 0.0)


func _build_world() -> void:
	_world = Node3D.new()
	_world.name = "World"
	_viewport.add_child(_world)

	var cam := Camera3D.new()
	cam.position = _CAM_POS
	cam.rotation_degrees = Vector3(_CAM_PITCH_DEG, 0.0, 0.0)
	cam.fov = _CAM_FOV
	cam.current = true
	_world.add_child(cam)
	_camera = cam

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, -30.0, 0.0)
	sun.light_energy = 1.15
	_world.add_child(sun)

	_sun = sun
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.42, 0.42, 0.46)
	env.ambient_light_energy = 0.75
	we.environment = env
	_world.add_child(we)
	_env = env

	_shadow_texture = _build_shadow_texture()


## Radial gradient blob (black, alpha _SHADOW_ALPHA at center, fading to fully transparent at the
## texture's own edge) — the ground-contact shadow's shared texture. Same GradientTexture2D
## technique as CombatView.gd's _build_gradient_textures() vignette, applied to a flat 3D quad
## instead of a 2D TextureRect (see the "Ground-contact shadow" const block above for the full
## rationale). fill_to=(1.0, 0.5), not the diagonal corner CombatView.gd's vignette uses, so the
## gradient's radius reaches exactly the texture's own horizontal edge — a clean circular falloff
## for a shadow blob, rather than a softer corner-to-corner falloff meant for a screen vignette.
## Builds the 3D battlefield for a biome id (see CombatArena3D / assets/atia/arenas.json), or
## clears it when `biome_id` is "" (back to the transparent stage over the 2D backdrop).
## Biome for a combat: CombatArena3D.biome_for(row, is_boss, total_rows). Returns false when the
## biome is unknown or the arena is disabled for tests.
func set_arena(biome_id: String, boss: bool = false) -> bool:
	if _world == null:
		return false
	if biome_id == "":
		if _arena != null:
			_arena.clear()
		_viewport.transparent_bg = true
		_env.background_mode = Environment.BG_CLEAR_COLOR
		_env.fog_enabled = false
		_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		_env.ambient_light_energy = 0.75
		_sun.light_color = Color.WHITE
		_sun.light_energy = 1.15
		_sun.shadow_enabled = false
		return true
	if _arena == null:
		_arena = CombatArena3D.new()
		_arena.name = "Arena"
		_arena.position = Vector3(0.0, 0.0, LANE_Z)
		_arena.rotation_degrees.y = -90.0   # arena is authored along -Z; the fight runs along +X (arena z -> world -x)
		_world.add_child(_arena)
		_world.move_child(_arena, 0)
	if _arena.biome_id == biome_id and _arena.is_boss == boss:
		return true
	if not _arena.build(biome_id, _env, _sun, boss):
		return false
	_viewport.transparent_bg = false
	# Soft sun shadows under the Land props and units; only with an arena (flat 2D backdrop
	# fights keep the cheap blob shadows). Short range keeps the shadow map sharp and cheap.
	_sun.shadow_enabled = true
	_sun.shadow_blur = 2.0
	_sun.directional_shadow_max_distance = 45.0
	_sun.shadow_opacity = 0.55
	return true


## Fraction of the viewport height left ABOVE the portal tower top (0 = touching the frame top,
## negative = cropped). 1.0 when there is no arena/portal. Used by the arena framing test.
func portal_top_margin() -> float:
	if _arena == null or _camera == null or _arena.portal_position() == Vector3.ZERO:
		return 1.0
	var top := _arena.portal_top_position()
	if _camera.is_position_behind(top):
		return 1.0
	return _camera.unproject_position(top).y / float(_viewport.size.y)


## Picks and builds the arena for a map node. Pure function of (row, is_boss, total_rows) -
## no RNG, so replays and re-entering a fight always give the same battlefield.
## `total_rows` = RunMapGraph rows.size() (18 standard, 30 full).
func set_arena_for_node(row: int, is_boss: bool, total_rows: int = 18) -> bool:
	return set_arena(CombatArena3D.biome_for(row, is_boss, total_rows), is_boss)


## True when this stage's arena has a gate the party can run through.
func has_gate() -> bool:
	return _arena != null and _arena.portal_position() != Vector3.ZERO


## Portal transition: white flash, swap to the next biome under it, fade back. Await-able.
func transition_to_arena(biome_id: String) -> void:
	if CombatView.disable_juice_for_tests:
		set_arena(biome_id)
		return
	_ensure_flash()
	var tw := create_tween()
	tw.tween_property(_flash, "color:a", 1.0, 0.25).set_ease(Tween.EASE_IN)
	await tw.finished
	set_arena(biome_id)
	var tw2 := create_tween()
	tw2.tween_property(_flash, "color:a", 0.0, 0.35).set_ease(Tween.EASE_OUT)
	await tw2.finished


func _ensure_flash() -> void:
	if _flash != null:
		return
	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_flash)


func _build_shadow_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.0, 0.0, 0.0, _SHADOW_ALPHA))
	gradient.set_color(1, Color(0.0, 0.0, 0.0, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = _SHADOW_TEXTURE_SIZE
	tex.height = _SHADOW_TEXTURE_SIZE
	return tex


## One shadow "decal" quad, sized from `width` (see spawn_unit()'s three branches for how each
## visual path computes its own width). Laid flat on the ground plane (rotated -90 deg around X so
## its face normal points up at the camera's downward pitch) rather than billboarded, since it is
## meant to read as sitting ON the ground, not facing the camera like the eye-glow light or the
## enemy Sprite3D. Unshaded + alpha transparency so DirectionalLight3D/ambient light never tints
## it, and shadow-casting is off — this quad IS the shadow, it must not also receive or cast a
## second one.
func _make_ground_shadow(width: float) -> MeshInstance3D:
	var quad := QuadMesh.new()
	var size := maxf(width, 0.01) * (_SHADOW_RADIUS_MULT * 2.0)
	quad.size = Vector2(size, size)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_texture = _shadow_texture
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mi := MeshInstance3D.new()
	mi.mesh = quad
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.rotation_degrees.x = -90.0
	mi.position = Vector3(0.0, _SHADOW_Y_OFFSET, 0.0)
	return mi


## Called once per unit when a combat starts (CombatView._ready()). slot_index/slot_count
## are the unit's position and total count within its own row (party row or enemy row),
## used only to center+space the row — never gameplay data. `is_boss`/`unit_key` (default
## false/"") are the same Unit.is_boss/Unit.key fields CombatView._spawn_portrait() already has
## on hand — optional/defaulted so every existing call site (including t_stage3d_facing.gd/
## t_stage3d_pick.gd, which construct units with no boss concept at all) keeps working unchanged.
## `genes` is the 512-bit Origin gene string of an IMPORTED Axie, or "" for everything else.
## When it is set the party rig is built from those genes instead of the generic per-class
## descriptor, which is what puts the player's own Axie on the battlefield rather than a
## stand-in wearing its class colour. The Vault card already drew it this way; combat did not,
## and that mismatch was the report ("không hiển thị art của Vault Axie trong trận").
func spawn_unit(uid: int, cls: String, is_enemy: bool, slot_index: int, slot_count: int,
		is_boss: bool = false, unit_key: String = "", genes: String = "") -> void:
	var sheet_sprite_name := ""       # see the MonsterAnim block further down
	var atia_info: Dictionary = {}
	var sheet_target: Sprite3D = null
	var slot := Node3D.new()
	slot.name = "Slot_%d" % uid
	var is_egg := not is_enemy and unit_key == "egg"
	slot.position = _slot_position(is_enemy, slot_index, slot_count, is_enemy and is_boss, is_egg)
	slot.rotation_degrees.y = _ENEMY_FACING_Y_DEG if is_enemy else _PARTY_FACING_Y_DEG
	_world.add_child(slot)

	var character: AxieCharacter3D = null
	var visual: Node3D = null
	var is_named_boss := is_enemy and is_boss
	var shadow_width := _CHARACTER_SHADOW_WIDTH_M   # overwritten by whichever branch below runs

	# Atia 3D model from the registry (assets/atia/atia_models.json, via MonsterArt.resolve()).
	# Any failure (kind != glb, missing file, no meshes) falls through to the Chimera sprite.
	var atia: Dictionary = (_make_atia_model(unit_key, is_boss) if is_enemy else {})
	if not atia.is_empty():
		var model: Node3D = atia["node"]
		slot.add_child(model)
		_fit_atia_model(model, atia, ENEMY_SIZE_M * (_BOSS_SCALE if is_named_boss else 1.0))
		visual = model
		shadow_width = clampf(float(atia["width"]) * 0.9, 1.0 * ENEMY_SCALE, 7.0)
		atia_info = atia
		if not CombatView.disable_juice_for_tests:
			if (atia["anims"] as Dictionary).has("idle"):
				_atia_play(atia, "idle", true)
			else:
				_play_model_idle(model)   # mascot .glb: first looping clip it ships with
	elif is_enemy and MonsterArt.texture_for(unit_key, is_boss) != null:
		# Real Chimera sprite branch (ui-programmer, real-monster-art follow-up — bug report:
		# "4 quái là 4 bóng đen giống hệt nhau", production/qa/evidence/
		# 2026-09-18_real-flow-varied-enemies.png). Covers every rank-and-file enemy (all 21
		# ContentDB.enemies keys are mapped — MonsterArt.MONSTER_SPRITES, verified by
		# tests/t_assets.gd) AND the 4 boss keys with no dedicated .glb above (all 6
		# ContentDB.bosses keys are mapped too — MonsterArt.BOSS_SPRITES, same test). Never
		# taken for party units (`is_enemy` guards it) — the AxieCharacter3D rig stays the party
		# visual, per the standing "party never gets the enemy treatment" decision.
		var tex := MonsterArt.texture_for(unit_key, is_boss)
		var sprite := _make_enemy_sprite(tex, ENEMY_SIZE_M * (_BOSS_SCALE if is_named_boss else 1.0))
		slot.add_child(sprite)
		visual = sprite
		# The kit's own name for this creature's art. It is the key into MonsterAnim, and it
		# is recorded here because spawn_unit() is the only place that knows it — play_action()
		# and friends see a uid, not a sprite.
		sheet_sprite_name = MonsterArt.sprite_name_for(unit_key, is_boss)
		sheet_target = sprite
		# Exact width already on hand for free: pixel_size * source texture width, same math
		# _make_enemy_sprite() used to derive pixel_size from target_height in the first place.
		shadow_width = float((_sprite_info(tex)["used"] as Rect2).size.x) * sprite.pixel_size
	else:
		var desc: AxieDescriptor = null
		# Real genes win, and only for a PARTY unit: an enemy has no Axie behind it, and an
		# imported Axie is never on the enemy side.
		if not is_enemy and not genes.strip_edges().is_empty():
			desc = AxieDescriptor.from_genes(genes.strip_edges())
		if desc == null:
			# No genes, or a gene string the decoder would not take — an Axie minted before the
			# Origin format has an empty `newGenes`, and the Vault stores that as "". Falling
			# back to the generic class body is what keeps those importable at all.
			desc = AxieDescriptor.new()
			desc.body = AxieTypes.Body.NORMAL
			if is_named_boss and _BOSS_COLOR_VARIANT.has(unit_key):
				desc.color_variant = int(_BOSS_COLOR_VARIANT[unit_key])
			else:
				desc.color_variant = _ENEMY_COLOR_VARIANT if is_enemy else int(_CLASS_COLOR_VARIANT.get(cls, _ENEMY_COLOR_VARIANT))
			desc.parts = _build_parts(cls)

		character = AxieCharacter3D.from_descriptor(desc)
		if character != null and character.root != null:
			slot.add_child(character.root)
			character.root.position = Vector3.ZERO
			if is_named_boss:
				character.root.scale = Vector3.ONE * _BOSS_SCALE * UNIT_SCALE   # see _BOSS_SCALE comment — never
					# touches `slot`'s own scale so it composes cleanly with set_targetable()'s 1.08x
					# pulse and _start_death_fade()'s scale-to-zero, both of which animate `slot`.
			if character.playable != null:
				# set_default() arms the built-in "fall back to a looping clip once the current
				# one-shot finishes" path that play_action()/play_hit_reaction() below rely on
				# (AxiePlayable.advance_on_complete() -> _play_default_internal(), read that file
				# before touching this) — without it _default_clip_name stays "" forever and a
				# one-shot action/hit-reaction clip would freeze on its last frame instead of
				# returning to Idle. play_death() deliberately clears this back to "" so the Dead
				# clip does NOT auto-resume Idle afterward — see that method's own comment.
				character.playable.set_default(AnimNames.Idle)
				character.playable.play(AnimNames.Idle, "", true)
			visual = character.root
			character.root.scale = Vector3.ONE * UNIT_SCALE * (_BOSS_SCALE if is_named_boss else 1.0)
			shadow_width = _CHARACTER_SHADOW_WIDTH_M * UNIT_SCALE * (_BOSS_SCALE if is_named_boss else 1.0)
		else:
			visual = _make_placeholder(cls, is_enemy)
			visual.scale = Vector3.ONE * UNIT_SCALE * (_BOSS_SCALE if is_named_boss else 1.0)
			slot.add_child(visual)
			shadow_width = _CAPSULE_SHADOW_WIDTH_M * UNIT_SCALE * (_BOSS_SCALE if is_named_boss else 1.0)

	if is_egg and visual != null:
		visual.scale *= 0.62   # tokens read smaller than the Axies they sit beside
		shadow_width *= 0.62
	var shadow := _make_ground_shadow(shadow_width)
	slot.add_child(shadow)

	var eye_light := _make_eye_light(cls)
	slot.add_child(eye_light)

	_units[uid] = {"slot": slot, "character": character, "visual": visual,
		"idle_tween": null, "dying": false, "eye_light": eye_light, "shadow": shadow,
		# `rest_pos` is where the lunge returns to, and `is_enemy` is which way "forward" is
		# when a face has no single target to aim at (AoE). Both are written again by
		# reseat_side(), which is the only other thing that moves a slot between actions.
		"is_enemy": is_enemy, "rest_pos": slot.position, "is_egg": is_egg, "is_boss": is_enemy and is_boss, "action_tween": null,
		# Frame-sheet animation for rigless monsters. `sheet_name` is "" for anything with a
		# real rig (every party Axie), which is what every caller below tests.
		"atia": atia_info,
		"sheet_name": sheet_sprite_name, "sheet_sprite": sheet_target,
		"sheet_tween": null, "sheet_base_tex": (sheet_target.texture if sheet_target != null else null),
		"sheet_base_pixel_size": (sheet_target.pixel_size if sheet_target != null else 0.0),
	}
	# A real AxieCharacter3D rig breathes via its own looping Idle clip. Everything else — the
	# Chimera sprite enemies and the capsule placeholder — has no animation rig, so it gets the
	# code-driven Tween bob instead.
	if (character == null or character.playable == null) and not (atia_info.get("player") != null and (atia_info["anims"] as Dictionary).has("idle")):
		_start_idle_bob(uid)


## Eye-glow point light (design/ux/combat-screen-shroom-gloom-inspired.md §5.1/§5.3) — added
## unconditionally, after the character/placeholder/boss-sprite branch above, so every spawned
## unit gets one regardless of which visual path it took (acceptance criteria §14: "visible on
## every spawned unit ... without any material introspection failure on the capsule-placeholder
## fallback path"). Child of `slot`, not `visual` — so it moves/rotates with the unit and (via
## _start_death_fade()'s scale-to-zero on `slot`, run from play_death()) collapses toward the
## origin alongside the death fade, independent of whether `visual` is a real rig, a capsule, or
## a billboard sprite.
## Instantiates the Atia wrapper scene for `unit_key` from the registry. Returns {} when the
## entry is not kind "glb", the file is missing, or it fails to load, so the caller falls through
## to the Chimera sprite. The returned dict is kept in the unit entry as "atia".
func _make_atia_model(unit_key: String, is_boss: bool) -> Dictionary:
	var reg := MonsterArt.resolve(unit_key, is_boss)
	if String(reg.get("kind", "")) != "glb":
		return {}
	var path := String(reg.get("path", ""))
	if not ResourceLoader.exists(path):
		push_warning("CombatStage3D: '%s' maps to %s, which is missing" % [unit_key, path])
		return {}
	var packed := load(path) as PackedScene
	if packed == null:
		return {}
	var model := packed.instantiate() as Node3D
	if model == null:
		return {}
	# The wrapper's own "Animations" player carries the clips named in the registry. The FBX
	# inside it (Model) often embeds a second AnimationPlayer holding only "Take 001"; taking
	# the first player found in depth-first order picked that one, found none of the registry's
	# clips, and left 13 of the 27 enemies frozen (L6 audit, 16/10). Mascot .glb files have no
	# wrapper, so they fall through to the first player.
	var player: AnimationPlayer = model.get_node_or_null("Animations") as AnimationPlayer
	if player == null:
		for n in _descendants(model):
			if n is AnimationPlayer:
				player = n as AnimationPlayer
				break
	if player != null:
		# Per-instance copy of the clips: Animation resources are shared by every unit that uses
		# the model, so loop mode must not be written on the shared ones.
		var anims_cfg: Dictionary = reg.get("anims", {})
		var lib := AnimationLibrary.new()
		for slot_name in anims_cfg.keys():
			var clip := String(anims_cfg[slot_name])
			if clip != "" and player.has_animation(clip) and not lib.has_animation(clip):
				var copy := player.get_animation(clip).duplicate() as Animation
				copy.loop_mode = Animation.LOOP_LINEAR if slot_name == "idle" else Animation.LOOP_NONE
				lib.add_animation(clip, copy)
		if lib.get_animation_list().size() > 0:
			for lib_name in player.get_animation_library_list():
				player.remove_animation_library(lib_name)
			player.add_animation_library("", lib)
	# Keep only the slots whose clip this player really has, so a wrong name in the registry
	# degrades to the code-driven fallbacks instead of a silent no-op (idle bob, flinch).
	var usable := {}
	var cfg_all: Dictionary = reg.get("anims", {})
	for slot_name in cfg_all.keys():
		if player != null and player.has_animation(String(cfg_all[slot_name])):
			usable[slot_name] = cfg_all[slot_name]
	return {"node": model, "player": player, "reg": reg,
		"anims": usable,
		"speed": (reg.get("anim_speed", {}) as Dictionary).duplicate(), "width": 1.0}


## Scales the model to the registry's height_m (capped by max_width_m), centres it on the slot
## and stands it on the floor. Bounds are measured in the model's own space with every node
## transform applied: FBX imports carry arbitrary root scales (one of these is 0.01), so
## measuring raw mesh AABBs would be wrong. Must run once the model is inside the tree.
func _fit_atia_model(model: Node3D, atia: Dictionary, size_m: float) -> void:
	var reg: Dictionary = atia["reg"]
	model.rotation_degrees.y = float(reg.get("facing_deg", 0.0))
	var box := _model_aabb(model)
	var h := size_m * 1.2
	var wmax := size_m * 2.6
	var raw := _visual_bounds(model)   # raw mesh AABBs; what the mascot .glb files were fitted with
	if box.size.y < 0.05 or (raw.y - raw.x) > box.size.y * 20.0:
		# Skinned .glb whose node transforms do not reflect in get_aabb(): the transformed box is
		# tiny and would give a 200x scale. Fall back to the raw measure, height only.
		if raw.y - raw.x > 0.001:
			var f := h / (raw.y - raw.x)
			model.scale = Vector3.ONE * f
			model.position = Vector3(0.0, -raw.x * f, 0.0)
			atia["width"] = wmax * 0.6
		return
	var wide := maxf(maxf(box.size.x, box.size.z), 0.0001)
	var factor := minf(size_m / sqrt(box.size.y * wide), minf(size_m * 1.9 / box.size.y, wmax / wide))
	model.scale = Vector3.ONE * factor
	var c := box.get_center()
	model.position = Vector3(-c.x * factor, -box.position.y * factor, -c.z * factor)
	atia["width"] = maxf(box.size.x, box.size.z) * factor


## AABB of all meshes in `root`, expressed in root's local space.
static func _model_aabb(root: Node3D) -> AABB:
	var inv := root.global_transform.affine_inverse()
	var box := AABB()
	var first := true
	for node in _descendants(root):
		var mi := node as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var b: AABB = inv * mi.global_transform * mi.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box


## Plays one of the registry's clips ("idle"/"attack"/"hit"/"die") on a unit's Atia model.
## Non-idle clips return to Idle when they end (or to the rest pose when the model has no idle clip),
## except "die" which holds the last frame.
## Returns the clip length in seconds, or 0 when the model has no such clip.
func _atia_play(atia: Dictionary, slot_name: String, loop := false) -> float:
	var player := atia.get("player") as AnimationPlayer
	var clip := String((atia.get("anims", {}) as Dictionary).get(slot_name, ""))
	if player == null or not is_instance_valid(player) or clip == "" or not player.has_animation(clip):
		return 0.0
	var anim := player.get_animation(clip)
	var spd := float((atia.get("speed", {}) as Dictionary).get(slot_name, 1.0))
	player.play(clip, 0.1, spd)
	if not loop and slot_name != "die":
		var idle := String((atia.get("anims", {}) as Dictionary).get("idle", ""))
		if idle != "" and player.has_animation(idle):
			player.queue(idle)
		elif not atia.has("rest_hooked"):
			# No idle clip to queue: without this the model would freeze on the last pose of attack/hit.
			# When a one-shot ends, drop back to rest and let the code bob (_start_idle_bob) carry on.
			atia["rest_hooked"] = true
			var die_clip := String((atia.get("anims", {}) as Dictionary).get("die", ""))
			player.animation_finished.connect(func(finished: StringName) -> void:
				if not is_instance_valid(player) or String(finished) == die_clip \
						or String(finished) == "RESET":
					return
				_atia_rest(player))
	return anim.length / maxf(spd, 0.01)


## Rest pose for a model that has no idle clip: the glTF "RESET" clip when it ships one (applied once),
## else just stop the player. Never called for the die clip (that one holds its last frame on purpose).
static func _atia_rest(player: AnimationPlayer) -> void:
	if player.has_animation("RESET"):
		player.play("RESET")
		player.advance(0.0)
	player.stop()


## The vertical extent of every VisualInstance3D in the tree, in the model's own space, as
## (bottom, top). Both ends are needed: the size to scale by, and the floor to stand on.
static func _visual_bounds(root: Node3D) -> Vector2:
	var top := -INF
	var bottom := INF
	for node in _descendants(root):
		var vi := node as VisualInstance3D
		if vi == null:
			continue
		var aabb := vi.get_aabb()
		# The mesh's own transform relative to the model root matters: a head mesh parented to
		# a neck bone reports an AABB around its own origin, not around the model's.
		var offset := (vi.global_transform.origin - root.global_transform.origin
			if vi.is_inside_tree() else vi.position)
		top = maxf(top, offset.y + aabb.position.y + aabb.size.y)
		bottom = minf(bottom, offset.y + aabb.position.y)
	return Vector2.ZERO if top == -INF else Vector2(bottom, top)


static func _descendants(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for child in node.get_children():
		out.append_array(_descendants(child))
	return out


## Starts whatever looping clip the model ships with, so a boss breathes instead of standing
## frozen next to enemies that bob. Clip names differ between models, so the first looping
## animation is used rather than a hardcoded name.
func _play_model_idle(model: Node3D) -> void:
	if CombatView.disable_juice_for_tests:
		return
	for node in _descendants(model):
		var player := node as AnimationPlayer
		if player == null:
			continue
		var preferred := ""
		for clip in player.get_animation_list():
			var lower := String(clip).to_lower()
			if lower.contains("idle"):
				preferred = String(clip)
				break
			if preferred.is_empty():
				preferred = String(clip)
		if not preferred.is_empty():
			var anim := player.get_animation(preferred)
			if anim != null:
				anim.loop_mode = Animation.LOOP_LINEAR
			player.play(preferred)
		return


func _make_eye_light(cls: String) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.light_color = _EYE_GLOW_COLOR.get(cls, _ENEMY_EYE_GLOW_COLOR)
	light.omni_range = _EYE_LIGHT_RANGE
	light.position = Vector3(0.0, _EYE_HEIGHT, 0.0)
	light.light_energy = 0.0   # fades in below — see spawn-fade tween
	if CombatView.disable_juice_for_tests:
		light.light_energy = _EYE_LIGHT_ENERGY
	else:
		var tw := create_tween()
		tw.tween_property(light, "light_energy", _EYE_LIGHT_ENERGY, _EYE_LIGHT_SPAWN_DURATION) \
			.set_ease(Tween.EASE_OUT)
	return light


## Billboarded 2D Chimera art standing in for the enemy's 3D rig — see spawn_unit()'s sprite
## branch and _ENEMY_SPRITE_HEIGHT_M's comment for why this exists and how it's sized.
## `billboard`/`shaded`/`double_sided`/`pixel_size` are all plain SpriteBase3D/Sprite3D
## properties that have existed unchanged since Godot 3.x — VERSION.md's 4.4-4.7 knowledge-gap
## list (Jolt, FileAccess, shader texture types, AccessKit, RichTextLabel.add_image,
## D3D12-default, IK) does not touch Sprite3D, so this is not a post-cutoff-API risk.
## BILLBOARD_ENABLED (full spherical billboard, always faces the camera) rather than
## BILLBOARD_FIXED_Y: this stage has exactly one static Camera3D at a fixed pitch (_build_world()
## above), so the two modes are visually indistinguishable here, but ENABLED is the more literal
## match for "always face the camera" if a future pass ever adds camera movement.
## Opaque-pixel facts per texture, decoded once: {"pad": transparent rows under the creature,
## "used": Rect2 of the opaque pixels}. Spawns and summons reuse it instead of decompressing the image again.
static var _sprite_info_cache: Dictionary = {}


static func _sprite_info(texture: Texture2D) -> Dictionary:
	var key := texture.get_instance_id()
	if _sprite_info_cache.has(key):
		return _sprite_info_cache[key]
	var info := {"pad": 0.0, "used": Rect2(0.0, 0.0, float(texture.get_width()), float(texture.get_height()))}
	var img := texture.get_image()
	if img != null and not img.is_empty():
		if img.is_compressed():
			img.decompress()
		var used := img.get_used_rect()
		if used.size.y > 0:
			info["used"] = Rect2(used)
			info["pad"] = maxf(float(img.get_height() - (used.position.y + used.size.y)), 0.0)
	_sprite_info_cache[key] = info
	return info


func _make_enemy_sprite(texture: Texture2D, size_m: float) -> Sprite3D:
	var sprite := Sprite3D.new()
	sprite.texture = texture
	sprite.centered = true
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y   # stays upright: a full billboard tilts back with the 3/4 camera and lifts its feet off the floor
	sprite.shaded = false
	sprite.double_sided = true
	var info := _sprite_info(texture)
	var used: Rect2 = info["used"]
	var tex_h := float(texture.get_height())
	# sqrt(w x h) of the opaque pixels becomes size_m; a very tall thin creature is capped at 1.9x size_m tall.
	var px_size := size_m / sqrt(maxf(used.size.x * used.size.y, 1.0))
	px_size = minf(px_size, size_m * 1.9 / maxf(used.size.y, 1.0))
	sprite.pixel_size = px_size
	# Node centred on the texture; drop it by the transparent rows under the creature so its feet touch y = 0.
	sprite.position = Vector3(0.0, tex_h * 0.5 * px_size - float(info.get("pad", 0.0)) * px_size, 0.0)
	return sprite


func _make_placeholder(cls: String, is_enemy: bool) -> MeshInstance3D:
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.4
	mesh.height = 1.4
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _ENEMY_PLACEHOLDER_COLOR if is_enemy else _PLACEHOLDER_COLOR.get(cls, Color(0.6, 0.6, 0.6))
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = Vector3(0.0, 0.8, 0.0)
	return mi


## One fixed part per slot (mouth/horn/back/tail/ear/eye), same variant/skin/level for every
## class — see _CLASS_PART_CLASS/_PART_VARIANT comments above for why this combo was chosen.
## Returns an empty array (plain body, unchanged from before this change) for any `cls` not in
## _CLASS_PART_CLASS — currently only non-hero enemies (ContentDB "slime" etc., cls=="").
func _build_parts(cls: String) -> Array[AxiePartDescriptor]:
	var parts: Array[AxiePartDescriptor] = []
	var part_class: String = String(_CLASS_PART_CLASS.get(cls, ""))
	if part_class.is_empty():
		return parts
	for part_type in _PART_TYPES:
		parts.append(AxiePartDescriptor.new(part_type, 0, part_class, _PART_VARIANT, 1))
	return parts


## Re-seats one side's units across the row. `uids` is that side's units in board order.
##
## Needed because `spawn_unit()` positions a slot ONCE, from the slot_count it was told at the
## time. Anything that joins a fight already in progress — gooey_king's SPLIT, a summoner's
## adds, an Axie Egg — changes that count for everyone on its side, and without a re-seat the
## newcomer is placed as if the row were one shorter and lands on top of a unit already there.
## Called after every spawn, so the row is correct by construction rather than only at t=0.
func reseat_side(uids: Array, is_enemy: bool) -> void:
	# Eggs (party tokens) get their own row; Axies are indexed among themselves. Enemies: a boss stands
	# alone, an elite fight puts the first enemy in the back-centre slot (bigger), everyone else takes
	# the add slots; plain fights use one staggered row (pitch widens with the count, so none overlap).
	var axie_uids: Array = []
	var egg_uids: Array = []
	var lead_uid := -1
	for uid in uids:
		var entry0: Dictionary = _units.get(int(uid), {})
		if entry0.is_empty():
			continue
		if bool(entry0.get("is_egg", false)):
			egg_uids.append(uid)
		elif is_enemy and (bool(entry0.get("is_boss", false)) or (_encounter_kind == "elite" and lead_uid < 0)):
			if lead_uid < 0 or bool(entry0.get("is_boss", false)):
				lead_uid = int(uid)
			else:
				axie_uids.append(uid)
		else:
			axie_uids.append(uid)
	var has_lead := lead_uid >= 0
	for uid in axie_uids.duplicate():
		if int(uid) == lead_uid:
			axie_uids.erase(uid)
	var placed: Array = []   # [uid, position]
	if lead_uid >= 0:
		var lead_entry: Dictionary = _units[lead_uid]
		var is_boss: bool = bool(lead_entry.get("is_boss", false))
		placed.append([lead_uid, BOSS_POS if is_boss else ELITE_POS])
		if not is_boss and not bool(lead_entry.get("elite_scaled", false)):
			lead_entry["elite_scaled"] = true
			var v: Node3D = lead_entry.get("visual")
			if is_instance_valid(v):
				v.scale *= ELITE_SCALE
	for i in axie_uids.size():
		var pos: Vector3
		if is_enemy and has_lead:
			pos = ADD_SLOTS[i % ADD_SLOTS.size()] + Vector3(1.2, 0.0, 0.0) * float(i / ADD_SLOTS.size())
		else:
			pos = _slot_position(is_enemy, i, axie_uids.size())
		placed.append([axie_uids[i], pos])
	for i in egg_uids.size():
		placed.append([egg_uids[i], _slot_position(false, i, egg_uids.size(), false, true)])
	for pl in placed:
		var entry: Dictionary = _units.get(int(pl[0]), {})
		var slot: Node3D = entry["slot"]
		if is_instance_valid(slot):
			slot.position = pl[1]
			entry["rest_pos"] = slot.position   # the lunge's home moved with it
			entry["is_enemy"] = is_enemy


func has_unit(uid: int) -> bool:
	return _units.has(uid)


## Test/QA accessor — the ground-contact shadow mesh spawned for `uid` (see spawn_unit()'s
## _make_ground_shadow() call), or null if `uid` is unknown. Public so tests/QA scripts can assert
## shadow presence/sizing without reaching into the private `_units` dictionary.
func get_shadow_mesh(uid: int) -> MeshInstance3D:
	var entry: Dictionary = _units.get(uid, {})
	return entry.get("shadow")


func _slot_position(is_enemy: bool, slot_index: int, slot_count: int, boss: bool = false, egg: bool = false) -> Vector3:
	if egg:
		return Vector3(EGG_X0 + float(slot_index) * EGG_PITCH_X, _POS_Y, EGG_Z)
	if not is_enemy:
		var front := slot_index % 2 == 0
		return Vector3(PARTY_X0 + float(slot_index) * PARTY_PITCH_X, _POS_Y, PARTY_Z_FRONT if front else PARTY_Z_BACK)
	if boss:
		return BOSS_POS
	var x := ENEMY_CENTER_X + (float(slot_index) - (float(slot_count) - 1.0) * 0.5) * ENEMY_PITCH_X
	if slot_count == 1:
		return Vector3(x, _POS_Y, ENEMY_Z_MID)
	var rows: Array[float] = [ENEMY_Z_BACK, ENEMY_Z_MID, ENEMY_Z_FRONT]
	return Vector3(x, _POS_Y, rows[slot_index % 3])


## Visual-only death reaction — mirrors UnitPortrait's own dim/hide of the 2D card, which
## stays the source of truth for "unit is dead" styling (called every _rebuild_all(), so this
## must be idempotent). Deliberately does NOT force-hide the slot while play_death()'s Dead-clip-
## then-fade sequence owns it (checklist step 7) — play_death() sets entry["dying"]=true
## synchronously, before even the Dead clip starts, specifically so this instant `.visible =
## false` branch (which would otherwise fire the same frame, same call stack, as CombatView.gd's
## play_death() call) never clobbers the death animation before the player sees a single frame of
## it. If alive flips back true (shouldn't happen mid-combat, but keeps this defensive) it always
## resets.
func set_alive(uid: int, alive: bool) -> void:
	var entry: Dictionary = _units.get(uid, {})
	if entry.is_empty():
		return
	var slot: Node3D = entry["slot"]
	if not is_instance_valid(slot):
		return
	if alive:
		entry["dying"] = false
		slot.visible = true
		slot.scale = Vector3.ONE
	elif not bool(entry.get("dying", false)):
		# Defensive fallback only: reaches here if a unit is dead but play_death(uid) was never
		# called for it (e.g. EventBus.unit_died missed for some reason) — keeps this function's
		# contract ("dead units are hidden") correct even without the animation.
		slot.visible = false


## Click-to-3D-model picking (see unit_clicked signal + _CLICK_PICK_RADIUS_PX comments above).
## `event.position` arrives in this Control's own local coordinate space (same space `size`
## below is expressed in), which — because Combat.tscn never applies any extra transform to
## this Control beyond the project's global canvas_items window-stretch (project.godot) — is
## also the same space UnitPortrait's sibling Controls use, so no extra scaling vs. the rest of
## the UI is needed here. It STILL needs scaling against `_viewport.size` though, because
## SubViewportContainer.stretch=true (CombatStage3D.tscn) renders the 3D scene at a fixed
## internal resolution (1280x640) and stretches that texture to fill however big this Control's
## own rect currently is — Camera3D.unproject_position() always returns coordinates in that
## fixed 1280x640 space, never this Control's rect size, so the click position must be
## remapped into that space before comparing against it.
## MOUSE_FILTER — this Control must never be MOUSE_FILTER_IGNORE, or the viewport never picks it
## and everything below is dead code. `_ready()` sets STOP and is the authority; the scene file
## used to say IGNORE anyway, which is a trap worth naming: reading CombatStage3D.tscn alone in
## 2026-09-21's targeting investigation said "the click path is off" when the script had already
## turned it on, and the scene file now agrees with `_ready()` so the next reader is not sent the
## same way. `t_combat_hit_targets.gd` asserts the runtime value rather than either file's text.
const LONG_PRESS_SEC := 0.5
const LONG_PRESS_SLOP_PX := 12.0
var _lp_uid := -1          # touch only: the unit under a held finger; its click waits for the release
var _lp_pos := Vector2.ZERO
var _lp_token := 0
var _lp_fired := false


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and _lp_uid != -1:
		if (event as InputEventMouseMotion).position.distance_to(_lp_pos) > LONG_PRESS_SLOP_PX:
			_lp_cancel()   # a drag is not a press
		return
	if not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	if not mb.pressed:
		if mb.button_index == MOUSE_BUTTON_LEFT and _lp_uid != -1:
			var held := _lp_uid
			var fired := _lp_fired
			_lp_cancel()
			if not fired:
				unit_clicked.emit(held)   # a short touch is still the same click as before
			accept_event()
		return
	if mb.button_index == MOUSE_BUTTON_LEFT and _roller != null and _roller.is_rolling():
		_roller.skip()   # click on the stage while dice fly = jump every die to the tray
		accept_event()
		return
	if mb.button_index != MOUSE_BUTTON_LEFT and mb.button_index != MOUSE_BUTTON_RIGHT:
		return
	var uid := _pick_unit_at(mb.position)
	if uid == -1:
		return
	if mb.button_index == MOUSE_BUTTON_RIGHT:
		unit_inspect_requested.emit(uid)
	elif mb.device == InputEvent.DEVICE_ID_EMULATION:
		# Touch (emulated mouse): hold 500 ms = inspect, release sooner = the usual click.
		_lp_uid = uid
		_lp_pos = mb.position
		_lp_fired = false
		_lp_token += 1
		var token := _lp_token
		get_tree().create_timer(LONG_PRESS_SEC).timeout.connect(func() -> void:
			if token == _lp_token and _lp_uid != -1 and not _lp_fired:
				_lp_fired = true
				unit_inspect_requested.emit(_lp_uid))
	else:
		unit_clicked.emit(uid)
	accept_event()


func _lp_cancel() -> void:
	_lp_uid = -1
	_lp_fired = false
	_lp_token += 1


## The unit under a point in global (window) coordinates, or -1. Same pick as a click.
func pick_unit_at_global(global_pos: Vector2) -> int:
	return _pick_unit_at(global_pos - get_global_rect().position)


func _pick_unit_at(local_pos: Vector2) -> int:
	if _camera == null or not is_instance_valid(_camera) or size.x <= 0.0 or size.y <= 0.0:
		return -1
	var vp_pos := local_pos * (Vector2(_viewport.size) / size)
	var best_uid := -1
	var best_dist := INF
	for uid in _units:
		var entry: Dictionary = _units[uid]
		var slot: Node3D = entry.get("slot")
		if not is_instance_valid(slot) or not slot.visible:
			continue   # dead/hidden units (set_alive()/play_death()) are not pickable
		var world_pos := slot.global_transform.origin + Vector3(0.0, _CLICK_TARGET_HEIGHT, 0.0)
		if _camera.is_position_behind(world_pos):
			continue
		var screen_pos := _camera.unproject_position(world_pos)
		var d := screen_pos.distance_to(vp_pos)
		if d <= _CLICK_PICK_RADIUS_PX and d < best_dist:
			best_dist = d
			best_uid = uid
	return best_uid


## Public world->screen projection for the 2D overlay layer (Nameplate/UnitHeadHUD/
## TargetLinesLayer — CombatView.gd's _layout_unit_visuals(), added for the
## review-uiux-battle-screen.md layout pass). Returns this Control's LOCAL-space position (same
## space _pick_unit_at()'s `local_pos` param uses) or Vector2(-1,-1) if the unit is unknown/
## dead/hidden/behind-camera — every caller must treat a negative-x result as "don't draw
## anything at this uid this frame" (mirrors how _pick_unit_at() already treats -1 as "no unit").
func get_unit_screen_pos(uid: int, height_offset: float) -> Vector2:
	var entry: Dictionary = _units.get(uid, {})
	if entry.is_empty():
		return Vector2(-1, -1)
	var slot: Node3D = entry.get("slot")
	if not is_instance_valid(slot) or not slot.visible:
		return Vector2(-1, -1)
	if _camera == null or not is_instance_valid(_camera) or size.x <= 0.0 or size.y <= 0.0:
		return Vector2(-1, -1)
	var world_pos := slot.global_transform.origin + Vector3(0.0, height_offset, 0.0)
	if _camera.is_position_behind(world_pos):
		return Vector2(-1, -1)
	var screen_pos := _camera.unproject_position(world_pos)
	return screen_pos * (size / Vector2(_viewport.size))


## Screen rectangle (stage-control pixels) covering a unit's model, from the 8 corners of its meshes'
## bounding box. Rect2() when the unit is unknown or hidden. Used by the spacing test and the QA capture.
func unit_screen_rect(uid: int) -> Rect2:
	var entry: Dictionary = _units.get(uid, {})
	if entry.is_empty() or _camera == null:
		return Rect2()
	var slot: Node3D = entry.get("slot")
	if not is_instance_valid(slot) or not slot.visible:
		return Rect2()
	var skip: Array = [entry.get("shadow"), entry.get("eye_light")]
	var box := AABB()
	var first := true
	for node in _descendants(slot):
		var gi := node as GeometryInstance3D
		if gi == null or skip.has(gi) or not gi.visible:
			continue
		var b: AABB
		if gi is Sprite3D and (gi as Sprite3D).texture != null and (gi as Sprite3D).hframes == 1 and (gi as Sprite3D).vframes == 1:
			b = _sprite_world_box(gi as Sprite3D)
		else:
			b = gi.global_transform * gi.get_aabb()
		box = b if first else box.merge(b)
		first = false
	if first or box.size.y < 0.05:
		var o := slot.global_transform.origin
		box = AABB(o + Vector3(-0.5, 0.0, -0.5), Vector3(1.0, HEAD_HEIGHT, 1.0))
	return _project_box(box)


## World box of a billboarded sprite's OPAQUE pixels (the quad's transparent margins are not the creature).
func _sprite_world_box(sp: Sprite3D) -> AABB:
	var tex := sp.texture
	var used: Rect2 = _sprite_info(tex)["used"]
	var w := float(tex.get_width())
	var h := float(tex.get_height())
	var ps := sp.pixel_size
	var right := _camera.global_transform.basis.x
	right.y = 0.0
	right = right.normalized()
	var o := sp.global_transform.origin
	var x0 := (used.position.x - w * 0.5) * ps
	var x1 := (used.end.x - w * 0.5) * ps
	var y0 := (h * 0.5 - used.end.y) * ps
	var y1 := (h * 0.5 - used.position.y) * ps
	var box := AABB(o + right * x0 + Vector3.UP * y0, Vector3.ZERO)
	box = box.expand(o + right * x1 + Vector3.UP * y0)
	box = box.expand(o + right * x0 + Vector3.UP * y1)
	return box.expand(o + right * x1 + Vector3.UP * y1)


func _project_box(box: AABB) -> Rect2:
	var k := size / Vector2(_viewport.size)
	var r := Rect2()
	var have := false
	for i in 8:
		var c := box.position + box.size * Vector3(float(i & 1), float((i >> 1) & 1), float((i >> 2) & 1))
		if _camera.is_position_behind(c):
			continue
		var p := _camera.unproject_position(c) * k
		r = r.expand(p) if have else Rect2(p, Vector2.ZERO)
		have = true
	return r


## Screen rectangle of the gate (portal) model, Rect2() when the arena has none.
func gate_screen_rect() -> Rect2:
	if _arena == null or _arena.portal_position() == Vector3.ZERO:
		return Rect2()
	return _project_box(_arena.portal_world_aabb())


## View-only "this unit is a plausible click target right now" affordance (bug report: no
## visual feedback about which unit was selected / who counts as a valid target). Deliberately
## NOT gameplay-rule-aware — it has no notion of which targets are actually LEGAL for the
## currently-selected die's face (that logic lives in CombatEngine._exec_face()/_do_face(),
## which this file must neither duplicate nor modify per this task's constraints) — it only
## means "a die is selected and this unit is alive, so clicking it will attempt an action".
## An illegal attempt still reaches CombatEngine.use_die() and returns false; CombatView.gd
## surfaces that via a float-text "Invalid target" on the clicked portrait, not via this
## highlight. Scale bump chosen over a material/shader tint because it works identically for
## both the real AxieCharacter3D and the capsule placeholder with zero material introspection.
func set_targetable(uid: int, v: bool) -> void:
	var entry: Dictionary = _units.get(uid, {})
	if entry.is_empty():
		return
	var slot: Node3D = entry.get("slot")
	if not is_instance_valid(slot) or bool(entry.get("dying", false)):
		return   # never fight _start_death_fade()'s scale-to-zero tween
	slot.scale = Vector3.ONE * (1.08 if v else 1.0)


## Action ("ra chiêu") reaction — EventBus.face_used handler, CombatView._on_face_used(). Picks a
## clip + playback speed from _ACTION_ANIM_BY_TYPE keyed by the die face's own `type` (see that
## table's comment) instead of always WalkAttack. Relies on the same set_default(Idle)/
## advance_on_complete() built-in return-to-default path armed in spawn_unit() above — no timer
## needed, AxiePlayable auto-resumes the looping Idle clip once the one-shot clip's last frame
## plays out; an on_complete callback is only wired when time_scale != 1.0, to restore normal
## speed before Idle resumes (see _on_action_time_scale_reset()). No-op for the capsule
## placeholder fallback (no rig to animate) and for a unit already mid-death-sequence.
## `target_uid` is optional and defaults to -1 ("no single target") so the pre-existing two-arg
## call in tests/qa_action_variety_capture.gd keeps working unchanged.
func play_action(uid: int, face_type: String = "", target_uid: int = -1,
		vfx_key: String = "") -> void:
	var entry: Dictionary = _units.get(uid, {})
	if entry.is_empty() or bool(entry.get("dying", false)):
		return
	# Motion FIRST, and outside the rig guard below — this is the half that monsters and bosses
	# get, and they are exactly the units that fail that guard. `vfx_key` is the Origins clip
	# CombatView picked for this face (it owns the class/part lookup); all this file does with
	# it is ask whether the clip is a RANGED one, because that decides lunge vs cast-in-place.
	_play_action_motion(uid, entry, face_type, target_uid, vfx_key)
	# The other half a rigless monster gets: the kit's own attack clip, played as a frame
	# sheet alongside the lunge. No-op for anything with a real rig.
	_play_sheet(entry, "attack")
	if not CombatView.disable_juice_for_tests and (entry.get("atia", {}) as Dictionary).has("player"):
		_atia_play(entry["atia"], "attack")
	var character: AxieCharacter3D = entry.get("character")
	if character == null or not is_instance_valid(character) or character.playable == null:
		return
	var playable: AxiePlayable = character.playable
	playable.time_scale = 1.0   # defensive reset — see _on_action_time_scale_reset() comment;
		# guards against a previous slowed/sped-up one-shot's on_complete never having fired yet
		# (e.g. this same unit's play_action() is called again before its last clip finished).
	var anim: Dictionary = _ACTION_ANIM_BY_TYPE.get(face_type, _DEFAULT_ACTION_ANIM)
	var clip := String(anim["clip"])
	var scale := float(anim["time_scale"])
	if is_equal_approx(scale, 1.0):
		playable.play(clip, "", false)
	else:
		playable.time_scale = scale
		playable.play(clip, "", false, Callable(self, "_on_action_time_scale_reset").bind(uid))


## The lunge/cast Tween — see the _LUNGE_* constant block for the design and for why this
## drives `slot` rather than `visual`.
##
## Every tweener is PARALLEL with an explicit delay rather than chained. Chaining reads more
## naturally but makes the out/impact/recover phases depend on each other's exact durations;
## with delays, each phase states its own place on one timeline, which is the thing that has to
## line up with CombatView's impact delay (CombatView.impact_delay(), which is deliberately the
## same length as _LUNGE_OUT + _LUNGE_HOLD — the moment the attacker is furthest forward is the
## moment the number is supposed to appear on the target).
func _play_action_motion(uid: int, entry: Dictionary, face_type: String,
		target_uid: int, vfx_key: String = "") -> void:
	if CombatView.disable_juice_for_tests:
		return
	var slot: Node3D = entry.get("slot")
	if not is_instance_valid(slot):
		return

	# A second action before the first finished (echo/multi faces, or a fast player) must not
	# leave the model halfway out: kill the old tween and put the slot back before starting.
	var prev = entry.get("action_tween")
	if prev is Tween and (prev as Tween).is_valid():
		(prev as Tween).kill()
	var rest: Vector3 = entry.get("rest_pos", slot.position)
	slot.position = rest
	slot.scale = Vector3.ONE

	var tw := create_tween()
	tw.set_parallel(true)
	entry["action_tween"] = tw

	# Two ways to end up casting in place instead of lunging.
	#  - the face does not reach out and hit anybody (shield/heal/buff/mana/summon): walking at
	#    a target would be actively misleading about who it affects.
	#  - the face DOES hit somebody, but from range. `is_ranged` is the Origins capture's own
	#    flag (cast / projectile / throw), so an Axie that fires a bolt plants its feet and the
	#    bolt covers the distance, while a bite or a gore still closes it. Lunging AND firing
	#    would say two different things about the attack's reach in the same half second.
	if not _LUNGE_FACE_TYPES.has(face_type) or SkillVfxCatalog.is_ranged(vfx_key):
		tw.tween_property(slot, "scale", _CAST_DIP_SCALE, _CAST_DIP) 			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(slot, "scale", _CAST_RISE_SCALE, _CAST_RISE).set_delay(_CAST_DIP) 			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(slot, "scale", Vector3.ONE, _CAST_RISE) 			.set_delay(_CAST_DIP + _CAST_RISE).set_trans(Tween.TRANS_SINE)
		_pulse_eye_light(tw, entry)
		return

	var dir := _lunge_direction(entry, rest, target_uid)
	var dist := _lunge_distance(rest, target_uid)
	var out_pos := rest + dir * dist
	tw.tween_property(slot, "position", out_pos, _LUNGE_OUT) 		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(slot, "scale", _LUNGE_STRETCH, _LUNGE_OUT) 		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(slot, "scale", _LUNGE_SQUASH, _LUNGE_HOLD).set_delay(_LUNGE_OUT) 		.set_trans(Tween.TRANS_SINE)
	tw.tween_property(slot, "position", rest, _LUNGE_BACK) 		.set_delay(_LUNGE_OUT + _LUNGE_HOLD) 		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(slot, "scale", Vector3.ONE, _LUNGE_BACK) 		.set_delay(_LUNGE_OUT + _LUNGE_HOLD) 		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## How long the longest "ra chiêu" motion takes, end to end. CombatView spaces the enemy phase
## by this (CombatView.enemy_step_gap()) so one monster is back on its mark before the next one
## starts — "one at a time" is only true if the gap and the motion agree, and they live in
## different files. The cast branch is the longer of the two, so it decides.
static func action_motion_duration() -> float:
	return maxf(_LUNGE_OUT + _LUNGE_HOLD + _LUNGE_BACK, _CAST_DIP + _CAST_RISE * 2.0)


## Cancels a lunge/cast in flight and puts the slot back exactly on its mark. Safe to call on
## a unit that never moved.
func _stop_action_motion(entry: Dictionary) -> void:
	var tw = entry.get("action_tween")
	if tw is Tween and (tw as Tween).is_valid():
		(tw as Tween).kill()
	entry["action_tween"] = null
	var slot: Node3D = entry.get("slot")
	if is_instance_valid(slot):
		slot.position = entry.get("rest_pos", slot.position)
		slot.scale = Vector3.ONE


## Unit vector from the attacker toward its target. Falls back to "straight at the other row"
## when there is no single target — an AoE face (target_uid -1, or a target that has already
## been despawned) still steps forward, it just does not pick a lane.
func _lunge_direction(entry: Dictionary, rest: Vector3, target_uid: int) -> Vector3:
	# Untyped on purpose: _rest_position_of() returns Vector3-or-null, which GDScript has no
	# way to spell as a static type, and `:=` cannot infer from it.
	var tgt_rest = _rest_position_of(target_uid)
	if tgt_rest != null:
		var delta: Vector3 = (tgt_rest as Vector3) - rest
		delta.y = 0.0
		if delta.length() > 0.001:
			return delta.normalized()
	return Vector3(1.0, 0.0, 0.0) if not bool(entry.get("is_enemy", false)) else Vector3(-1.0, 0.0, 0.0)


func _lunge_distance(rest: Vector3, target_uid: int) -> float:
	var tgt_rest = _rest_position_of(target_uid)
	if tgt_rest == null:
		return _LUNGE_MAX * 0.5   # no target to close on; a half step reads as "winding up"
	return minf(rest.distance_to(tgt_rest as Vector3) * _LUNGE_FRACTION, _LUNGE_MAX)


## The target's resting slot position, or null when there is no usable target. Returns the
## REST position, not the live one: a target mid-lunge of its own (thorns, a simultaneous
## enemy turn) would otherwise drag this attacker's aim around with it.
func _rest_position_of(uid: int):
	if uid < 0:
		return null
	var entry: Dictionary = _units.get(uid, {})
	if entry.is_empty():
		return null
	var slot: Node3D = entry.get("slot")
	if not is_instance_valid(slot):
		return null
	return entry.get("rest_pos", slot.position)


# ---------------------------------------------------------------------------
# Frame-sheet animation for rigless monsters
# ---------------------------------------------------------------------------
## Every party Axie animates from a real skeletal rig (AxiePlayable). Every monster is a
## billboarded Sprite3D, so before this it could only be SLID and SQUASHED — the lunge in
## _play_action_motion() was the whole of its "ra chiêu". These three entry points give it
## the kit's own clips instead, baked to grid sheets offline (see MonsterAnim).
##
## Nothing here replaces the lunge; it rides with it. A monster now steps forward AND swings.
##
## The resting sprite and every sheet share one cell size and one ground line by
## construction (MonsterAnim's header explains why), so swapping `texture` is safe: only the
## picture changes, never the creature's size or footing.


## Plays `state` once on a rigless monster. No-op — cheaply — for a unit with a rig, a unit
## with no sheet for this state, or when juice is off for tests. `on_done` fires whether the
## sheet played or not, so a caller can sequence on it either way.
##
## `restore` returns the sprite to its resting picture when the clip ends. Death passes
## false: a corpse must hold the clip's last frame, and restoring first would stand it back
## up for a frame before the fade.
func _play_sheet(entry: Dictionary, state: String, on_done := Callable(),
		restore := true) -> bool:
	if CombatView.disable_juice_for_tests:
		if on_done.is_valid():
			on_done.call()
		return false
	var sprite: Sprite3D = entry.get("sheet_sprite")
	var sheet_name := String(entry.get("sheet_name", ""))
	if sheet_name == "" or not is_instance_valid(sprite):
		if on_done.is_valid():
			on_done.call()
		return false
	var meta := MonsterAnim.sheet(sheet_name, state)
	if meta.is_empty():
		if on_done.is_valid():
			on_done.call()
		return false
	var path := MonsterAnim.sheet_path(sheet_name, state)
	if not ResourceLoader.exists(path):
		if on_done.is_valid():
			on_done.call()
		return false
	var tex: Texture2D = load(path)
	if tex == null:
		if on_done.is_valid():
			on_done.call()
		return false

	_stop_sheet(entry)
	var cols := maxi(1, int(meta.get("cols", 1)))
	var fw := int(meta.get("frame_w", 1))
	var fh := int(meta.get("frame_h", 1))
	var count := maxi(1, int(meta.get("frames", 1)))
	var fps := maxf(1.0, float(meta.get("fps", 12.0)))

	sprite.texture = tex
	sprite.region_enabled = true
	# pixel_size was derived from the RESTING texture's height. A sheet is many cells tall, so
	# it has to be re-derived from the CELL height or the monster balloons to sheet size.
	sprite.pixel_size = _sheet_pixel_size(entry, fh)
	_set_sheet_frame(sprite, 0, cols, fw, fh)

	var tw := create_tween()
	entry["sheet_tween"] = tw
	tw.tween_method(
		func(f: float) -> void:
			if is_instance_valid(sprite):
				_set_sheet_frame(sprite, clampi(int(f), 0, count - 1), cols, fw, fh),
		0.0, float(count), float(count) / fps)
	tw.finished.connect(func() -> void:
		if restore:
			_restore_sheet(entry)
		if on_done.is_valid():
			on_done.call())
	return true


## The cell height a sheet frame must be drawn at, in metres per pixel, so that a sheet frame
## occupies exactly the same on-screen box as the resting sprite. Derived from the resting
## texture rather than stored, because _make_enemy_sprite() already encoded the boss scale
## into pixel_size and this has to inherit it.
func _sheet_pixel_size(entry: Dictionary, frame_h: int) -> float:
	var sprite: Sprite3D = entry.get("sheet_sprite")
	var base_tex: Texture2D = entry.get("sheet_base_tex")
	if not is_instance_valid(sprite) or base_tex == null or frame_h <= 0:
		return sprite.pixel_size if is_instance_valid(sprite) else 0.01
	# The resting sprite IS one cell of the shared box, so its height is the cell height and
	# the ratio is 1 in practice. Computed rather than assumed so a future re-export with a
	# different resting crop cannot silently resize every monster.
	var base_h := maxf(1.0, float(base_tex.get_height()))
	return float(entry.get("sheet_base_pixel_size", sprite.pixel_size)) * (base_h / float(frame_h))


func _set_sheet_frame(sprite: Sprite3D, index: int, cols: int, fw: int, fh: int) -> void:
	sprite.region_rect = Rect2(float(index % cols) * fw, float(index / cols) * fh, fw, fh)


## Back to the resting picture. Safe on a unit that never played a sheet.
func _restore_sheet(entry: Dictionary) -> void:
	var sprite: Sprite3D = entry.get("sheet_sprite")
	if not is_instance_valid(sprite):
		return
	var base_tex: Texture2D = entry.get("sheet_base_tex")
	if base_tex != null:
		sprite.texture = base_tex
	sprite.region_enabled = false
	var base_px: float = float(entry.get("sheet_base_pixel_size", sprite.pixel_size))
	if base_px > 0.0:
		sprite.pixel_size = base_px


## Cancels a sheet in flight WITHOUT restoring, for callers that are about to start another
## one. play_death() also uses it to freeze a corpse on its last frame.
func _stop_sheet(entry: Dictionary) -> void:
	var tw = entry.get("sheet_tween")
	if tw is Tween and (tw as Tween).is_valid():
		(tw as Tween).kill()
	entry["sheet_tween"] = null


## The eye glow flaring under a cast. Added to the caller's own parallel Tween so it shares one
## timeline with the scale, and restored to _EYE_LIGHT_ENERGY rather than to whatever it happens
## to be at — the spawn fade-in (_make_eye_light()) is the only other writer and it always ends
## there.
func _pulse_eye_light(tw: Tween, entry: Dictionary) -> void:
	var light = entry.get("eye_light")
	if not (light is OmniLight3D) or not is_instance_valid(light as OmniLight3D):
		return
	var lamp := light as OmniLight3D
	tw.tween_property(lamp, "light_energy", _EYE_LIGHT_ENERGY * _CAST_GLOW_MULT, _CAST_DIP) 		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(lamp, "light_energy", _EYE_LIGHT_ENERGY, _CAST_RISE * 1.5) 		.set_delay(_CAST_DIP).set_trans(Tween.TRANS_SINE)


## Restores normal (1.0) playback speed once a slowed/sped-up one-shot action clip (see
## _ACTION_ANIM_BY_TYPE above) finishes. Needed because `time_scale` is a property of the whole
## AxiePlayable, not of one clip — without this, the auto-resumed looping Idle clip would keep
## breathing at that same altered speed indefinitely.
func _on_action_time_scale_reset(uid: int) -> void:
	var entry: Dictionary = _units.get(uid, {})
	if entry.is_empty():
		return
	var character: AxieCharacter3D = entry.get("character")
	if character != null and is_instance_valid(character) and character.playable != null:
		character.playable.time_scale = 1.0


## Hit reaction — EventBus.hit_landed handler, CombatView._on_hit_landed(). Same auto-return-to-
## Idle mechanism as play_action() above (no callback/timer). `uid` here is the unit that just
## TOOK the hit (damage_pipeline.gd emits hit_landed(src_uid, uid, value, crit) with `uid` as the
## target — confirmed by reading both of that file's emit sites, including the thorns/reflect one
## where the roles are swapped but `uid` is still whoever is receiving THIS particular hit).
func play_hit_reaction(uid: int) -> void:
	var entry: Dictionary = _units.get(uid, {})
	if entry.is_empty() or bool(entry.get("dying", false)):
		return
	var character: AxieCharacter3D = entry.get("character")
	_play_sheet(entry, "hit")      # the rigless half; no-op when a rig answers below
	if not CombatView.disable_juice_for_tests and (entry.get("atia", {}) as Dictionary).has("player"):
		if _atia_play(entry["atia"], "hit") <= 0.0:
			_atia_flinch(entry)   # no GetHit clip for this model: squash + recoil in code
	if character == null or not is_instance_valid(character) or character.playable == null:
		return
	character.playable.play(AnimNames.IdleGetHit, "", false)


## Code-driven hit reaction for Atia models that ship no GetHit clip (chomper, bruiser,
## cleaver...): a quick squash and a small recoil away from the party, relative to the pose the
## model was fitted at. Overlapping hits restart it from the fitted pose, never from mid-flinch.
func _atia_flinch(entry: Dictionary) -> void:
	var visual := entry.get("visual") as Node3D
	if visual == null or not is_instance_valid(visual):
		return
	if not entry.has("flinch_base"):
		entry["flinch_base"] = {"scale": visual.scale, "pos": visual.position}
	var old = entry.get("flinch_tween")
	if old is Tween and (old as Tween).is_valid():
		(old as Tween).kill()
	var base_s: Vector3 = entry["flinch_base"]["scale"]
	var base_p: Vector3 = entry["flinch_base"]["pos"]
	visual.scale = base_s
	var tw := create_tween()
	entry["flinch_tween"] = tw
	tw.set_parallel(true)
	tw.tween_property(visual, "scale", base_s * Vector3(1.1, 0.88, 1.1), 0.07) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(visual, "position:x", base_p.x + 0.18, 0.07) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.chain().set_parallel(true)
	tw.tween_property(visual, "scale", base_s, 0.2) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(visual, "position:x", base_p.x, 0.2) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _stop_atia_flinch(entry: Dictionary) -> void:
	var tw = entry.get("flinch_tween")
	if tw is Tween and (tw as Tween).is_valid():
		(tw as Tween).kill()
	var visual := entry.get("visual") as Node3D
	if entry.has("flinch_base") and visual != null and is_instance_valid(visual):
		visual.scale = entry["flinch_base"]["scale"]
		visual.position = entry["flinch_base"]["pos"]


## Death juice (EventBus.unit_died handler, CombatView.gd — now calls play_death(), not the fade
## directly) — plays the real (non-looping) Dead clip FIRST so the player actually sees the death
## pose, then runs the old scale-to-zero "disappear" fade (_start_death_fade(), unchanged logic
## from the pre-animation pass) only once that clip's own on_complete callback fires. `dying` is
## set true up front (before the Dead clip even starts), not after the fade begins — set_alive()/
## set_targetable()/_pick_unit_at() all key off this flag to stop touching/considering this unit
## the instant it dies, not just once the fade tween starts.
## set_default("") disarms the auto-return-to-Idle mechanism play_action()/play_hit_reaction()
## rely on: Dead is non-looping, and without this it would replay Idle (looped) the moment it
## finished, which would look like the unit came back to life for a frame before the fade even
## started. With no default armed, AxiePlayable's _play_default_internal() no-ops and the last
## committed pose (Dead's final frame) simply stays put — verified by reading _apply_graph()/
## _tick(), not assumed.
func play_death(uid: int) -> void:
	var entry: Dictionary = _units.get(uid, {})
	if entry.is_empty() or bool(entry.get("dying", false)):
		return
	entry["dying"] = true
	var idle_tween = entry.get("idle_tween")
	if idle_tween is Tween and (idle_tween as Tween).is_valid():
		(idle_tween as Tween).kill()   # stop the "breathing" bob — nothing to breathe once dead
	# A unit can die mid-lunge (thorns, or a counter that resolves inside its own attack). The
	# death fade tweens `slot.scale` to zero, and the action tween is tweening the same property
	# back to ONE — whichever finishes last wins, which is how a corpse ends up full size and
	# frozen. Kill it and put the slot back on its mark first.
	_stop_action_motion(entry)
	_stop_atia_flinch(entry)
	var character: AxieCharacter3D = entry.get("character")
	var playable: AxiePlayable = null
	if character != null and is_instance_valid(character):
		playable = character.playable
	var atia: Dictionary = entry.get("atia", {})
	if not CombatView.disable_juice_for_tests and atia.has("player"):
		var secs := _atia_play(atia, "die")
		if secs > 0.0:
			get_tree().create_timer(secs + 0.15).timeout.connect(
				func() -> void: _start_death_fade(uid, entry))
			return
	if CombatView.disable_juice_for_tests or playable == null:
		# A rigless monster with a `die` sheet plays it and only then fades, mirroring what
		# the rigged path below does with the Dead clip. _play_sheet() calls back immediately
		# when there is no sheet (5 of the 20 ship a placeholder die clip, see MonsterAnim),
		# so the no-sheet case is exactly the old behaviour.
		# restore=false freezes the corpse on the clip's last frame; see _play_sheet().
		_play_sheet(entry, "die", func() -> void: _start_death_fade(uid, entry), false)
		return
	playable.set_default("")
	playable.play(AnimNames.Dead, "", false, Callable(self, "_on_death_anim_done").bind(uid))


func _on_death_anim_done(uid: int) -> void:
	var entry: Dictionary = _units.get(uid, {})
	if entry.is_empty():
		return
	_start_death_fade(uid, entry)


## Actual scale-to-zero "disappear" tween — Node3D has no built-in modulate/alpha, and alpha-
## fading would mean walking every MeshInstance3D's material and flipping it into transparent
## mode (fragile against AxieCharacter3D's actual mesh setup, and against the capsule
## placeholder). Scale-to-zero is simple, robust, needs no material introspection, and reads
## clearly as "unit is gone". `entry` is passed in by the caller (play_death()/
## _on_death_anim_done()), which already looked it up and already set entry["dying"]=true — no
## guards duplicated here, this only runs the tween itself. In test mode
## (CombatView.disable_juice_for_tests, see that file's HEADLESS TEST MODE comment) skips the
## Tween and jumps straight to the hidden end state.
func _start_death_fade(uid: int, entry: Dictionary) -> void:
	var slot: Node3D = entry.get("slot")
	if not is_instance_valid(slot):
		return
	var eye_light = entry.get("eye_light")   # spec §10: eye-glow fades to 0 alongside the
		# scale-to-zero fade, same duration — a separate Tween on a different property/node, safe
		# to run in parallel with the `slot` scale tween below.
	if CombatView.disable_juice_for_tests:
		slot.scale = Vector3.ZERO
		slot.visible = false
		if eye_light is OmniLight3D and is_instance_valid(eye_light):
			(eye_light as OmniLight3D).light_energy = 0.0
		return
	if eye_light is OmniLight3D and is_instance_valid(eye_light):
		var lt := create_tween()
		lt.tween_property(eye_light, "light_energy", 0.0, _DEATH_FADE_DURATION).set_ease(Tween.EASE_IN)
	var tw := create_tween()
	tw.tween_property(slot, "scale", Vector3.ZERO, _DEATH_FADE_DURATION)
	tw.finished.connect(func():
		if is_instance_valid(slot):
			slot.visible = false)


## Victory march (EventBus.combat_finished(true) handler, CombatView._finish()) — juice pass B:
## "quái chết, Axie chạy tiếp sang ải khác" instead of an abrupt scene cut. Moves every uid in
## `uids` (CombatView passes its currently-alive party) forward along the direction the party
## slot is ACTUALLY FACING after spawn_unit()'s 180-degree turn (_PARTY_FACING_Y_DEG). BUG FIX
## (user report: this originally moved the party TOWARD the camera/backward instead of forward):
## the vendored addon's own documented convention (see spawn_unit()'s _PARTY_FACING_Y_DEG comment
## and every third_party demo script, verbatim: "front is +Z, toward the camera") is that a
## character's face direction is local **+Z**, not -Z. The first version of this method
## transformed local (0,0,-1) instead of (0,0,1) — at the party's rotation.y=180, Ry(180) maps
## local +Z to world -Z (away from camera, correct — this is the "quay lưng đánh" fix already
## applied at spawn) but maps local -Z to world **+Z** (TOWARD the camera — the bug: marching
## backward). Confirmed by direct read of slot.position.z before/after the tween in a throwaway
## script: with local (0,0,1) the target z is LOWER (further from the +Z camera, deeper into
## where the enemy row stood) than the start z, exactly the "tiến qua ải" forward march this was
## supposed to produce. Switches each unit with a real rig from Idle to a looping Run clip for
## the duration of the move. CombatView awaits this before change_scene_to_file() so the player
## actually sees the party leave the field instead of an instant cut. Gated behind
## disable_juice_for_tests like every other Tween-based juice entry point in this file (shake()/
## _start_death_fade()) — skip entirely so a script-driven headless combat (t_combatview_smoke.gd
## plays full real combats back-to-back) never pays this wall-clock cost.
func play_victory_march(uids: Array, distance: float, duration: float) -> void:
	if CombatView.disable_juice_for_tests or uids.is_empty():
		return
	# Arena with a gate (real fights): run along the path THROUGH the portal and flash out at it
	# (Liam 16/10). No arena/portal (tutorial, DevReview): the short fixed-distance march.
	var portal := _arena.portal_position() if _arena != null else Vector3.ZERO
	var to_gate := portal != Vector3.ZERO
	var tw := create_tween()
	tw.set_parallel(true)
	_exit_tween = tw
	var moved := false
	for uid in uids:
		var entry: Dictionary = _units.get(uid, {})
		if entry.is_empty() or bool(entry.get("dying", false)):
			continue
		var slot: Node3D = entry.get("slot")
		if not is_instance_valid(slot):
			continue
		var idle_tween = entry.get("idle_tween")
		if idle_tween is Tween and (idle_tween as Tween).is_valid():
			(idle_tween as Tween).kill()   # marching, not breathing in place
		_stop_action_motion(entry)   # the winning blow's lunge must not tween the slot back
			# to its mark while the march is walking it off the field
		var character: AxieCharacter3D = entry.get("character")
		if character != null and is_instance_valid(character) and character.playable != null:
			character.playable.set_default(AnimNames.Run)
			character.playable.play(AnimNames.Run, "", true)
		var target: Vector3
		if to_gate:
			# Converge on the gate (x pulled to 15% of the row spread so five Axies fit the
			# archway), ending just past the portal origin. Pure function of the arena, no RNG.
			target = Vector3(portal.x + _EXIT_PAST_GATE, slot.position.y, portal.z + (slot.position.z - portal.z) * _EXIT_X_PULL)
		else:
			# Local +Z is this addon's own documented "front" axis (see comment above) —
			# transforming it through the slot's own basis gives the world-space direction the
			# unit is actually facing right now, regardless of row/rotation convention.
			var world_dir: Vector3 = slot.transform.basis * Vector3(0.0, 0.0, 1.0)
			target = slot.position + world_dir * distance
		tw.tween_property(slot, "position", target, duration) \
			.set_trans(Tween.TRANS_SINE if not to_gate else Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		moved = true
	if not moved:
		tw.kill()
		_exit_tween = null
		return
	if to_gate and not CombatView.flashes_suppressed():
		# Same white flash as transition_to_arena(), but it only rises (the scene changes under it).
		_ensure_flash()
		_flash.color.a = 0.0
		tw.tween_property(_flash, "color:a", 1.0, _EXIT_FLASH) \
			.set_delay(maxf(duration - _EXIT_FLASH, 0.0)).set_ease(Tween.EASE_IN)
	await tw.finished
	_exit_tween = null


## Skip button for the exit run: finish the running tween on the next frame (units land on their
## targets, flash completes) instead of killing it, so `await play_victory_march()` still resolves.
func skip_victory_march() -> void:
	if _exit_tween != null and _exit_tween.is_valid():
		_exit_tween.set_speed_scale(1000.0)


## Screen shake (EventBus.hit_landed handler, CombatView.gd) — offsets this whole
## SubViewportContainer's 2D `position` (NOT a Camera3D shake inside the 3D world) by a small
## random amount that decays to zero, then snaps back exactly to _base_position. Chosen over
## shaking the Camera3D because this Control already sits in a fixed HUD layout band
## (MidStage) — a 2D position tween here is trivially bounded/resettable and can't desync the
## 3D camera's fixed framing of the fixed-slot stage. `await`s its own Tween so callers can
## sequence after it, but always resolves (tween.finished fires even if killed early below) —
## see CombatView._begin_hit_animation() for the independent hard failsafe that does not rely on
## this ever completing. In test mode this never even gets called (CombatView._play_hit_juice()
## returns before reaching it), but still guards here defensively in case something ever calls
## shake() directly.
func shake(amplitude: float, duration: float) -> void:
	if CombatView.disable_juice_for_tests or not is_inside_tree():
		return
	if _active_shake_tween != null and _active_shake_tween.is_valid():
		_active_shake_tween.kill()   # a second hit landed before the first shake finished
			# (AOE) — cancel cleanly rather than let two tweens fight over `position`
		position = _base_position
	var tw := create_tween()
	_active_shake_tween = tw
	var step_time := duration / float(_SHAKE_STEPS)
	for i in _SHAKE_STEPS:
		var decay := 1.0 - (float(i) / float(_SHAKE_STEPS))
		var offset := Vector2(randf_range(-amplitude, amplitude), randf_range(-amplitude, amplitude)) * decay
		tw.tween_property(self, "position", _base_position + offset, step_time)
	tw.tween_property(self, "position", _base_position, step_time)
	await tw.finished
	if _active_shake_tween == tw:
		_active_shake_tween = null
	position = _base_position


## Skipped entirely in test mode (CombatView.disable_juice_for_tests) — an infinite-loop Tween
## per unit (up to 7 in a combat) running for the whole real-time duration of a simulated
## headless combat is exactly the kind of long-lived Tween load this flag exists to avoid; see
## CombatView.gd's HEADLESS TEST MODE comment.
func _start_idle_bob(uid: int) -> void:
	if CombatView.disable_juice_for_tests:
		return
	var entry: Dictionary = _units.get(uid, {})
	var visual: Node3D = entry.get("visual")
	if entry.is_empty() or not is_instance_valid(visual):
		return
	var base_y := visual.position.y
	var amp := randf_range(_IDLE_BOB_AMP_MIN, _IDLE_BOB_AMP_MAX)
	var half_period := randf_range(_IDLE_BOB_PERIOD_MIN, _IDLE_BOB_PERIOD_MAX) * 0.5
	var tw := create_tween()
	tw.set_loops()   # infinite — killed explicitly in play_death()/play_victory_march()/dispose_all()
	tw.tween_property(visual, "position:y", base_y + amp, half_period) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(visual, "position:y", base_y, half_period) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	entry["idle_tween"] = tw


## Called from CombatView._exit_tree() — replaces the old per-portrait dispose_visual()
## loop now that there's one shared owner of every AxieCharacter3D.
func dispose_all() -> void:
	for entry in _units.values():
		var idle_tween = entry.get("idle_tween")
		if idle_tween is Tween and (idle_tween as Tween).is_valid():
			(idle_tween as Tween).kill()
		_stop_action_motion(entry)
		var ft = entry.get("flinch_tween")
		if ft is Tween and (ft as Tween).is_valid():
			(ft as Tween).kill()
		var character = entry.get("character")
		if character != null:
			(character as AxieCharacter3D).dispose()
	_units.clear()
	if _active_shake_tween != null and _active_shake_tween.is_valid():
		_active_shake_tween.kill()
	_active_shake_tween = null
