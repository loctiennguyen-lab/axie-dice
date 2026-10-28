# UI-04 prep: token audit, motion hook, token check

Branch `ui4/prep` (from godot-port f2b17d7). Scan covers `godot/scenes/**` and `godot/scripts/ui/**` (98 .gd files).
Counts below are lines found by grep on the day of the audit (28/10), not unique values.

## Result

| What | Found | Fixed (same value, now via token) | Left |
|---|---|---|---|
| Colour literals (`Color(`, `Color.html`, `"#hex"`) | 142 lines (12 are UI3Theme's own loaders, fine) | 4 (DiceRoller3D) | ~126 |
| Font size numbers in `add_theme_font_size_override` | 108 lines (incl. token reads) | 56 (18/24/36/16 -> `text_body/text_title/text_banner/text_key_hint`) | 17 literal overrides |
| StyleBox corner/border/shadow/margin literals | 178 lines | 0 (no 1:1 token with certainty, see below) | all |
| `create_tween` in scenes/scripts/ui | 75 | 2 call sites moved to `UI3Motion` | 73 |

## Fixed

- 56x `add_theme_font_size_override("font_size" | "normal_font_size", 18|24|36|16)` replaced by `UI3Theme.size_of("text_body" | "text_title" | "text_banner" | "text_key_hint")`. Files: tray_column, RunMapController, TutorialCoach, ResultView, CombatView, WildPicker, BoLayer, DefeatPanel, StatusHeads, AidPanel, CombatHud, RerollBar, PassView, UnitPortrait, CorePanel, UI3, GachaFx, AnchorFx, others. (grep `UI3Theme.size_of("text_` to list.)
- `DiceRoller3D.gd`: consts `IVORY` (FFE5B4) -> `color("die_body")`, `INK` (291808) -> `color("accent_text")`, `SKIN_INK` (2B1E17) -> `color("die_ink")`, tile `shadow_color` -> `color("die_ink")`. Consts removed (no other users).

## Left: font sizes with no token (new token needed)

| file:line | value | proposal |
|---|---|---|
| UI3.gd:341, 614, 642; CombatHud.gd:116, 134; CombatView.gd:993; EchoBoxScreen.gd:1149, 1163; UnitPortrait.gd:219 | 20 | new token `size.text_label_s` = 20 (round 2 uses 20 for names/shrink step; CLAUDE.md says "no other size", so Design should confirm or drop it) |
| CombatView.gd:720 (13), 1000 (14), 1610 (15) | 13/14/15 | below the 16 floor: should become 16/18, Design decides |
| CombatView.gd:1613 | 40 | `size.float_2` is 40 but is a float size; banner is `text_banner` 36 per tokens. Check against new spec |
| UnitPortrait.gd:349 | 32/28 | `text_screen_title` / `num_die` |
| DiceRoller3D.gd:312 | 72 | new token `size.num_die_big` |
| AccountScreen.gd:103 | 64 | new token `size.logo` |
| AnchorFx.gd:184 | 24/18 | text_title/text_body (conditional expression, left as is) |
| UI3.gd:571 `FLOAT_SIZE := [24,32,40]` | | tokens `float_0/1/2` exist, const array still hardcoded (const cannot call a function) |

## Left: colours

Same value exists as a token (safe next, but inside `const` or arrays so a refactor to functions is needed):

| file:line | value | token |
|---|---|---|
| hud_kit.gd:84-86 | PIPS arrays FF9345 / F54540 | `face_buff` / `hp_enemy`; FFB23F, F56A40, C9302B have no token |
| DiceStage.gd:46-47 | 794225 / 3E2618 (3D sky) | btn_secondary hover / `panel_raised` (3D environment, not UI, left) |
| UI3Theme.gd:34-36 | scrollbar grabber 794225 / 8F5230 / A76238 | new tokens `scroll_grabber`, `scroll_grabber_hover`, `scroll_grabber_pressed` |
| TutorialCoach.gd:28 | dim 05060A @ 72% | `scrim` (comment says it is replaced in _ready) |
| CombatView.gd:964 | black @ 72% dim | `scrim` (changes look: 13161b @ 80%) |
| CombatView.gd:666 | `_SCRIM_INK` 24140B | new token `ink_scrim` |
| UI3Tooltip.gd:121 | shadow black @ 35% | new token `shadow.tooltip` |

New tokens needed (no equivalent today):

| file:line | value | proposed name |
|---|---|---|
| CombatView.gd:658-659 | class colours plant 7DC943, beast FFB23F, aqua 39C5F3, reptile B679F7, bug F2624F, bird 8BDCFF | `color.class_plant` ... `class_bird` |
| CombatStage3D.gd:63-86 | class tints + eye glow (3D) | `class_*_3d`, `class_*_glow` (3D placeholders, low priority) |
| DiceRoller3D.gd:67-69 | face-type ring colours (B81221, 1E8FBF, 7A3FB5 ...) | `ring_dmg` ... (differ from `face_*` tokens) |
| UnitPortrait.gd:55-57 | intent tints FFD0C0 ... | `intent_tint_*` |
| RunSetup.gd:24 | WOOD_DARK 6E2F18 | `wood_dark` |
| StoreScreen.gd:17 | VIOLET 6B4AA8 | `gem` family has gem_bg/border/text; check if VIOLET is still used |
| LandUpgradeScreen.gd:242 | six tier colours | `tier_1..6` |
| Land.gd (23 lines) | 3D Land hub colours, ring/marker | Land is outside UI-03 scope; list only |
| CombatArena3D.gd, ArenaV2*.gd, BossIntro.gd | 3D lights, sky, fog | 3D scene art, not UI tokens |
| DiceStage.gd, CorePanel.gd:108 etc. | modulate tints, `Color(1,1,1,0.4/0.55)` for locked/dim | new tokens `alpha_locked` 0.4, `alpha_dim` 0.55 (ProfileView 152/483/571, MissionsScreen 548, AnchorPick 169) |
| `Color(0,0,0,0)` in ~10 places | transparent | not a token, use `Color.TRANSPARENT` (cosmetic) |

## Left: StyleBox / margins (all risky, no 1:1 proof)

178 lines. Most are `content_margin_*` pairs (8/12/16/24 map to `space.*`) and `set_corner_radius_all(n)` / `UI3Theme.flat(..., n, ...)` with literal radii (7, 9, 10, 14, 24, 32, 40 are not in `radius.*`: s4 m8 l12 die20 die_egg14). Worst offenders: UnitPortrait (tab/chip styles), UnitHeadHUD (`_PAD_*`, radius 7/10), CombatView:696 (radius 9, margin 11), DiceRoller3D (radius 40/10/14/5, border 8), UI3.gd:365-511 (chip margins 2/4/6/8/12), Land.gd:488-492 (radius 70, border 6, shadow 24), TutorialCoach:95-96 (border 4, radius 12 = `stroke.selected`, `radius.l`), RunMapController:554-565. Border widths 2/3/4 = `stroke.hairline` / `selected`; 3 has no token. Not touched because each change risks a 1 px visual shift and needs a screenshot compare.

## 2. Motion hook: `UI3Motion`

- Code: `godot/scenes/shared/ui3/UI3Motion.gd`; data: `godot/assets/data/ui/motion_ui3.json`; test: `t_ui3_motion` (20 checks).
- API: `UI3Motion.play(moment_id, node, opts) -> Tween` (null when skipped), plus `has_moment`, `moment_ids`, `duration_sec`, `validate_moment`, `reload`.
- Moment shape: `in` / `out` phases (`ms`, `trans`, `ease`, `delay_ms`, `props{scale, alpha, offset, rotation_deg}` each with `from`/`to`/own trans/ease), `hold_ms`, `shake{px,ms}`, `particles{texture,amount,lifetime_ms,spread_deg,speed,color_token}`, `sfx` (event name from `gacha_timing.json` `sfx`, goes through `UI3Gacha.play_sfx`, so silent in tests), `skippable`, `hide_on_done`, `free_on_done`.
- opts: `hold_ms`, `skip`/`instant`, `reduced` (jumps to end state when `skippable`), `scale_ms` (duration multiplier), `on_done`.
- Seeded moments (same timings as before): `turn_banner` (390/750/360), `combo_banner` (180/1550/250).
- Call sites now using it: `CombatView._show_turn_banner`, CombatView combo chip.
- Still hardcoded (73 `create_tween` sites), biggest first: CombatStage3D 37, CombatView ~32 (float chips 2680/3472/3634, die flip 3997, ...), GachaReveal 32, BossIntro 28, AnchorFx 24, CorePanel 14, GachaFx 12 (timing in `gacha_timing.json`, a separate table, left alone), RunMapController 10, UnitPortrait 9, DiceStage 8, DiceRoller3D 8, DiceSkinFx 7, CosmeticArt 7, ProfileView 7, RerollTags 7, Land 6, EchoBox 6, HPBar 5, gift_claim 4, BoLayer 4, TutorialCoach 3.
- Not wired yet: user motion preference (only `MetaState.reduce_flash` exists, for flashes). Callers pass `reduced`. Decide with Design's motion.md whether to add a global "reduce motion" setting.
- Applying a motion.md: add or edit entries in `motion_ui3.json`, run `t_ui3_motion` (it validates every entry), then move more call sites one by one with `UI3Motion.play`.

## 3. Token swap check

`godot/tools/check_tokens.sh <candidate tokens.json>` (python3 only, no Godot, ~1 s).

- Exit 0 = OK, 1 = problem, 2 = usage. Prints ERROR / warn lines, then the list of values that changed vs the current `tokens_ui3.json`.
- ERROR: a key the code reads (`UI3Theme.color/size_of/size_dict/radius/space/stroke/motion_sec("x")` found in scenes, scripts, tests) is missing or wrong type; a current key vanished; a type changed; a colour is not `#rrggbb[aa]`; contrast list gone.
- warn: extra keys (game ignores them until code reads them).
- Then to apply: copy over `godot/assets/data/ui/tokens_ui3.json`, run `t_ui3_theme` (recomputes contrast), `t_ui_laws`, screenshots at 1920x1080 and 1280x720.
- Verified: current file passes (0 changed); a doctored copy (missing `color.hp`, string size, changed accent, extra radius) fails with the right 4 errors.
- Limit: it only sees literal keys. Keys built at runtime (e.g. `"face_" + type`) are covered by the baseline diff (check 2), not check 1.
