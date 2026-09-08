# Axie roguelike icon set — 25 icons

23 of 25 are shipped Axie art, copied from source: 6 part icons from `dango-icons`, 17 from the Origins
asset kit (11 effects and all 6 nodes). Only 2 had no asset and were drawn to the kit's rules:
energy and blank.

`manifest.json` maps every slot to its file and its upstream asset — read that at import time.

## Part (6) — `@axieinfinity/dango-icons`
Import from the package in code; the copies in `icons/part/` are for reference and previews.

| Slot | Export | Class |
| --- | --- | --- |
| MOUTH | `MouthBugIcon` | Bug (red) |
| HORN | `HornBugIcon` | Bug (red) |
| BACK | `BackAquaticIcon` | Aquatic (blue) |
| TAIL | `TailPlantIcon` | Plant (green) |
| EYES | `EyesPlantIcon` | Plant (green) |
| EARS | `EarsReptileIcon` | Reptile (purple) |

All eight class variants of each slot are on disk (`Aquatic`, `Beast`, `Bird`, `Bug`, `Neutral`,
`NeutralActive`, `Plant`, `Reptile`) — swap the suffix to follow the Axie's class.

`icons/part/blank.svg` is new (no "no part" asset exists).

## Effects (11) — Origins asset kit
Source: `Assets/OriginsKit/Textures/StatusIcons/` in `axie-origins-asset-kit-main`. PNG, ~128×135, transparent.

| Slot | Kit file | Note |
| --- | --- | --- |
| SHIELD | `buff_shield_boost.png` | |
| REGEN | `regrow.png` | |
| THORNS | `buff_spike.png` | |
| UNDYING | `goo_revival.png` | |
| POISON | `debuff_poison.png` | |
| BURN | `burn.png` | |
| WEAKEN | `debuff_weak.png` | |
| VULNERABLE | `debuff_vulnerable.png` | |
| BLIND | `debuff_fear.png` | **placeholder** — the kit has no blind asset; fear is a different mechanic |
| STUN | `debuff_stunned.png` | |
| FROZEN | `debuff_sleep.png` | **placeholder** — the kit has no ice/freeze asset; sleep is a different mechanic |

## Node (6)
| Slot | Source |
| --- | --- |
| BATTLE | kit `wolf_pack.png` |
| ELITE | kit `bloodmoon.png` |
| BOSS | kit `buff_fury.png` |
| EVENT | kit `secret_card.png` |
| MERCHANT | kit `snake_jar.png` |
| TREASURE | kit `rune_neutral_hybrid_1.png` |

## Cost (1)
`icons/cost/energy.svg` — new SVG.

## Rules the two new SVGs follow
Derived by sampling the kit PNGs, not invented:

- 128 viewBox, matching the StatusIcons canvas.
- One outline: pure `#000000`, 9 units, round joins and caps. It carries the silhouette at 16px.
- Two flat tones per icon — a base and one lighter block. **No gradients**; there are none anywhere in the kit.
- Energy: `#9970F7` / `#C3A7FF`, sampled off `debuff_stunned.png`. Blank is the exception —
  Dango neutral `#8E97A8` / `#C3CBD8`, since it marks the absence of a part rather than depicting one.
- Nothing thinner than ~6 units; the set is specified for 16–24px.

## Open items
1. **Blind** borrows `debuff_fear` and **Frozen** borrows `debuff_sleep`. Both are the right look for
   the wrong mechanic — replace them if the game ships blind and freeze art.
2. `z_snake_jar.png` is a byte-identical duplicate of `snake_jar.png`; there is no second jar in the kit.
3. Only **energy** and **blank** are drawn. Everything else traces to a shipped asset.
