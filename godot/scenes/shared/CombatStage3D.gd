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

const _EYE_HEIGHT := 1.3            # world-space Y offset above a unit's slot origin — roughly
	# eye level for both the capsule placeholder (base at y=0.8, height 1.4) and AxieCharacter3D.
const _EYE_LIGHT_ENERGY := 1.4       # "small" point light — enough to read as a personality
	# accent (spec §5.3), never bright enough to act as gameplay lighting on its own.
const _EYE_LIGHT_RANGE := 0.6
const _EYE_LIGHT_SPAWN_DURATION := 0.15   # spec §10 "Eye-glow spawn: fade 0->target, 150ms ease out"

## Boss visual. Every boss is a Chimera sprite, exactly like every rank-and-file enemy —
## MonsterArt.BOSS_SPRITES maps all six ContentDB boss keys, and `is_boss` only changes SCALE
## (_BOSS_SCALE), never the source of the art.
##
## A previous pass gave `agony` and `gooey_king` dedicated 3D models from
## `third_party/axie-3d-assets` (Paladill and Pomodoro). That was removed on the user's explicit
## rule: monsters and bosses come only from the Chimera library. It was not merely an art
## preference — "Pomodoro" is the display name of the Bug-class HERO in the player's own party
## (ContentDB._hero("Pomodoro", "bug", ...)), so the game was fielding a boss that was one of the
## player's own characters. tests/t_assets.gd now asserts no monster or boss art may share a
## hero's identity, so this cannot come back silently.
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
const _BOSS_SCALE := 2.15

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
const _ENEMY_SPRITE_HEIGHT_M := 1.7

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
const _ROW_SPACING_PARTY := 1.9
const _ROW_SPACING_ENEMY := 2.6
const _POS_Y := 0.0
const _POS_Z_PARTY := 3.0    # near row (camera-facing) — party
const _POS_Z_ENEMY := -4.1   # far row — enemies, reads as "further back" per JRPG convention

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
const _PARTY_FACING_Y_DEG := 180.0
const _ENEMY_FACING_Y_DEG := 0.0

# --- Click-to-3D-model picking (bug report: attacking wasn't achievable — see CombatView.gd
## file-level note / report for the root-cause writeup). No CollisionShape3D exists on any unit
## here (AxieCharacter3D/capsule placeholder are pure visual meshes, and adding physics bodies
## just for point-and-click target selection would be new scope this pass doesn't need) — so
## picking is a plain screen-space nearest-point test: each alive unit's world position is
## projected to 2D via Camera3D.unproject_position(), and whichever projection is closest to the
## click (within _CLICK_PICK_RADIUS_PX) wins. Cheap, framework-free, and more than accurate
## enough for a battlefield of at most ~11 well-separated units. ---
const _CLICK_PICK_RADIUS_PX := 70.0
const _CLICK_TARGET_HEIGHT := 0.9   # world-space Y offset added to a unit's slot origin before
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
const HEAD_HEIGHT := 1.55

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
	# Safe to flip: Combat.tscn's layout puts this stage in its OWN vertical band (MidStage,
	# 20%-72% of the screen) that never overlaps EnemyBand/BottomBand where the UnitPortrait
	# cards live — confirmed by reading Combat.tscn's anchors before making this change, not
	# assumed — so this does not steal any click that used to reach a portrait.
	mouse_filter = Control.MOUSE_FILTER_STOP
	_viewport.transparent_bg = true
	_viewport.own_world_3d = true
	_base_position = position
	_build_world()


func _build_world() -> void:
	_world = Node3D.new()
	_world.name = "World"
	_viewport.add_child(_world)

	var cam := Camera3D.new()
	cam.position = Vector3(0.0, 4.5, 13.2)
	cam.rotation_degrees = Vector3(-14.0, 0.0, 0.0)
	cam.fov = 34.0
	cam.current = true
	_world.add_child(cam)
	_camera = cam

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, -30.0, 0.0)
	sun.light_energy = 1.15
	_world.add_child(sun)

	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.42, 0.42, 0.46)
	env.ambient_light_energy = 0.75
	we.environment = env
	_world.add_child(we)

	_shadow_texture = _build_shadow_texture()


## Radial gradient blob (black, alpha _SHADOW_ALPHA at center, fading to fully transparent at the
## texture's own edge) — the ground-contact shadow's shared texture. Same GradientTexture2D
## technique as CombatView.gd's _build_gradient_textures() vignette, applied to a flat 3D quad
## instead of a 2D TextureRect (see the "Ground-contact shadow" const block above for the full
## rationale). fill_to=(1.0, 0.5), not the diagonal corner CombatView.gd's vignette uses, so the
## gradient's radius reaches exactly the texture's own horizontal edge — a clean circular falloff
## for a shadow blob, rather than a softer corner-to-corner falloff meant for a screen vignette.
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
func spawn_unit(uid: int, cls: String, is_enemy: bool, slot_index: int, slot_count: int,
		is_boss: bool = false, unit_key: String = "") -> void:
	var slot := Node3D.new()
	slot.name = "Slot_%d" % uid
	slot.position = _slot_position(is_enemy, slot_index, slot_count)
	slot.rotation_degrees.y = _ENEMY_FACING_Y_DEG if is_enemy else _PARTY_FACING_Y_DEG
	_world.add_child(slot)

	var character: AxieCharacter3D = null
	var visual: Node3D = null
	var is_named_boss := is_enemy and is_boss
	var shadow_width := _CHARACTER_SHADOW_WIDTH_M   # overwritten by whichever branch below runs

	if is_enemy and MonsterArt.texture_for(unit_key, is_boss) != null:
		# Real Chimera sprite branch (ui-programmer, real-monster-art follow-up — bug report:
		# "4 quái là 4 bóng đen giống hệt nhau", production/qa/evidence/
		# 2026-09-18_real-flow-varied-enemies.png). Covers every rank-and-file enemy (all 21
		# ContentDB.enemies keys are mapped — MonsterArt.MONSTER_SPRITES, verified by
		# tests/t_assets.gd) AND the 4 boss keys with no dedicated .glb above (all 6
		# ContentDB.bosses keys are mapped too — MonsterArt.BOSS_SPRITES, same test). Never
		# taken for party units (`is_enemy` guards it) — the AxieCharacter3D rig stays the party
		# visual, per the standing "party never gets the enemy treatment" decision.
		var tex := MonsterArt.texture_for(unit_key, is_boss)
		var target_height := _ENEMY_SPRITE_HEIGHT_M * (_BOSS_SCALE if is_named_boss else 1.0)
		var sprite := _make_enemy_sprite(tex, target_height)
		slot.add_child(sprite)
		visual = sprite
		# Exact width already on hand for free: pixel_size * source texture width, same math
		# _make_enemy_sprite() used to derive pixel_size from target_height in the first place.
		shadow_width = float(tex.get_width()) * sprite.pixel_size
	else:
		var desc := AxieDescriptor.new()
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
				character.root.scale = Vector3.ONE * _BOSS_SCALE   # see _BOSS_SCALE comment — never
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
			shadow_width = _CHARACTER_SHADOW_WIDTH_M * (_BOSS_SCALE if is_named_boss else 1.0)
		else:
			visual = _make_placeholder(cls, is_enemy)
			if is_named_boss:
				visual.scale = Vector3.ONE * _BOSS_SCALE
			slot.add_child(visual)
			shadow_width = _CAPSULE_SHADOW_WIDTH_M * (_BOSS_SCALE if is_named_boss else 1.0)

	var shadow := _make_ground_shadow(shadow_width)
	slot.add_child(shadow)

	var eye_light := _make_eye_light(cls)
	slot.add_child(eye_light)

	_units[uid] = {"slot": slot, "character": character, "visual": visual,
		"idle_tween": null, "dying": false, "eye_light": eye_light, "shadow": shadow,
	}
	# A real AxieCharacter3D rig breathes via its own looping Idle clip. Everything else — the
	# Chimera sprite enemies and the capsule placeholder — has no animation rig, so it gets the
	# code-driven Tween bob instead.
	if character == null or character.playable == null:
		_start_idle_bob(uid)


## Eye-glow point light (design/ux/combat-screen-shroom-gloom-inspired.md §5.1/§5.3) — added
## unconditionally, after the character/placeholder/boss-sprite branch above, so every spawned
## unit gets one regardless of which visual path it took (acceptance criteria §14: "visible on
## every spawned unit ... without any material introspection failure on the capsule-placeholder
## fallback path"). Child of `slot`, not `visual` — so it moves/rotates with the unit and (via
## _start_death_fade()'s scale-to-zero on `slot`, run from play_death()) collapses toward the
## origin alongside the death fade, independent of whether `visual` is a real rig, a capsule, or
## a billboard sprite.
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
func _make_enemy_sprite(texture: Texture2D, target_height: float) -> Sprite3D:
	var sprite := Sprite3D.new()
	sprite.texture = texture
	sprite.centered = true
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.shaded = false
	sprite.double_sided = true
	var tex_h := float(texture.get_height())
	sprite.pixel_size = target_height / maxf(tex_h, 1.0)
	# Sprite3D is centered on its own node by default (`centered = true` above) — offsetting the
	# NODE up by half the target height puts the sprite's bottom edge (its feet, since the source
	# PNGs are alpha-trimmed tight to the creature) at the slot's own y=0 ground plane, matching
	# FEET_HEIGHT/every other visual path in this file (AxieCharacter3D.root, the capsule
	# placeholder) which all sit with their base at y=0 too.
	sprite.position = Vector3(0.0, target_height * 0.5, 0.0)
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
	for i in uids.size():
		var entry: Dictionary = _units.get(int(uids[i]), {})
		if entry.is_empty():
			continue
		var slot: Node3D = entry["slot"]
		if is_instance_valid(slot):
			slot.position = _slot_position(is_enemy, i, uids.size())


func has_unit(uid: int) -> bool:
	return _units.has(uid)


## Test/QA accessor — the ground-contact shadow mesh spawned for `uid` (see spawn_unit()'s
## _make_ground_shadow() call), or null if `uid` is unknown. Public so tests/QA scripts can assert
## shadow presence/sizing without reaching into the private `_units` dictionary.
func get_shadow_mesh(uid: int) -> MeshInstance3D:
	var entry: Dictionary = _units.get(uid, {})
	return entry.get("shadow")


func _slot_position(is_enemy: bool, slot_index: int, slot_count: int) -> Vector3:
	var spacing := _ROW_SPACING_ENEMY if is_enemy else _ROW_SPACING_PARTY
	var x := (float(slot_index) - (float(slot_count) - 1.0) * 0.5) * spacing
	var z := _POS_Z_ENEMY if is_enemy else _POS_Z_PARTY
	return Vector3(x, _POS_Y, z)


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
func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	if mb.button_index != MOUSE_BUTTON_LEFT or not mb.pressed:
		return
	var uid := _pick_unit_at(mb.position)
	if uid != -1:
		unit_clicked.emit(uid)
		accept_event()


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
func play_action(uid: int, face_type: String = "") -> void:
	var entry: Dictionary = _units.get(uid, {})
	if entry.is_empty() or bool(entry.get("dying", false)):
		return
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
	if character == null or not is_instance_valid(character) or character.playable == null:
		return
	character.playable.play(AnimNames.IdleGetHit, "", false)


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
	var character: AxieCharacter3D = entry.get("character")
	var playable: AxiePlayable = null
	if character != null and is_instance_valid(character):
		playable = character.playable
	if CombatView.disable_juice_for_tests or playable == null:
		_start_death_fade(uid, entry)
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
	var tw := create_tween()
	tw.set_parallel(true)
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
		var character: AxieCharacter3D = entry.get("character")
		if character != null and is_instance_valid(character) and character.playable != null:
			character.playable.set_default(AnimNames.Run)
			character.playable.play(AnimNames.Run, "", true)
		# Local +Z is this addon's own documented "front" axis (see comment above) — transforming
		# it through the slot's own basis gives the world-space direction the unit is actually
		# facing right now, regardless of row/rotation convention.
		var world_dir: Vector3 = slot.transform.basis * Vector3(0.0, 0.0, 1.0)
		var target: Vector3 = slot.position + world_dir * distance
		tw.tween_property(slot, "position", target, duration) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		moved = true
	if not moved:
		tw.kill()
		return
	await tw.finished


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
		var character = entry.get("character")
		if character != null:
			(character as AxieCharacter3D).dispose()
	_units.clear()
	if _active_shake_tween != null and _active_shake_tween.is_valid():
		_active_shake_tween.kill()
	_active_shake_tween = null
