# Fonts — SIL Open Font License 1.1

Both families here are redistributed under the SIL Open Font License, Version 1.1
(https://scripts.sil.org/OFL). Static instances fetched from Google Fonts on 2026-09-20.

| File | Family | Weight | Upstream |
| --- | --- | --- | --- |
| `Baloo2-SemiBold.ttf` | Baloo 2 | 600 | https://fonts.google.com/specimen/Baloo+2 |
| `Baloo2-Bold.ttf` | Baloo 2 | 700 | " |
| `Baloo2-ExtraBold.ttf` | Baloo 2 | 800 | " |
| `WorkSans-Medium.ttf` | Work Sans | 500 | https://fonts.google.com/specimen/Work+Sans |
| `WorkSans-SemiBold.ttf` | Work Sans | 600 | " |
| `WorkSans-Bold.ttf` | Work Sans | 700 | " |

## Why two families

`design_handoff_axie_dice_ui` §02 · TYPE SCALE. Baloo 2 carries every piece of DISPLAY
type (titles, all numerals, unit names, die values, button labels); Work Sans carries
PROSE only (log lines, passives, relic and event body text). The Baloo 2 half is a
recorded, approved deviation from Dango's Work Sans — the reason is that a neutral
grotesk on black-outlined flat-tone cards reads as a dashboard, not as Lunacia.

Do not add a third family, and do not set a font on an individual `Label`: everything
goes through `res://resources/theme/dango.tres`, whose fonts are these files.
