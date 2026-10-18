# Components — A4 Blend

Every component is a flat StyleBox (tokens.json → theme). States: normal, hover, pressed, disabled, focus, selected. **Selected ≠ focus:** selected = 4 px cream (#FFE5B4) outline (+ lift on cards and dice); focus = 2 px amber (#FFB444) ring with 4 px offset, a second shape, never colour alone. Pressed moves the whole control down 2 px including the label. Disabled controls always say why in their own text.

| Component | Variants / sizes | Normal | Hover | Pressed | Disabled | Selected | Used in |
|---|---|---|---|---|---|---|---|
| Button | primary L (72, Rowdies 32), primary M (56, Rowdies 18), secondary M (56), secondary S (48), danger M (56), quiet (text link, 44 hit) | primary: kam-6 fill, kam-1 text, drop shadow 0 4 wood-1 · secondary: wood-3 fill, cream text · danger: red-4 fill, cream text | kam-7 / wood-4 / red-5 | y +2, shadow 2 | neutral-4 fill, neutral-5 2 px border, neutral-9 text with reason | — | all screens |
| IconButton | 48×48, radius 8, icon 32 | wood-3 | wood-4 | y +2 | neutral-4 | — | back (←), menu (≡), settings |
| Tab | h 56, pad 0 24, Rowdies 18 | wood-1 | wood-2 | — | — | wood-3 + 3 px cream outline | meta screens |
| Chip / Badge | h 32, pad 0 12, Rowdies 18 | kam-6 fill, kam-1 text ("New best") | — | — | — | — | Result |
| Key hint chip | Work Sans 16, 2 px neutral-5 border, radius 4 | — | — | — | — | — | Land hub plates, Run map |
| Panel · plate | radius 8, pad 16 (HUD) / 24 (detail) | wood-1 @ 90% | — | — | — | — | HUD and meta |
| Panel · card | radius 12, pad 24 | wood-1 @ 90% | wood-2 | — | opacity 0.4 (bought / sold out) | wood-2 + 4 px cream outline + y −18 | Reward, Pact, Store tiles |
| Modal / Confirm dialog | 560 w, radius 12, pad 32, scrim neutral-1 @ 80%; variants info (1 btn), confirm (amber), destructive (red, focus on Cancel), price | wood-1 opaque | — | — | — | — | system |
| Info panel (die info) | 288 w, wood-2, pad 10 12 | Rowdies 18 title + Work Sans 18 body | — | — | — | — | Combat |
| ProgressBar | HP 10 h (Axie) / 8 h (enemy) / 16 h (boss, pass tier), radius 4 | track neutral-1, fill green-6 / red-6 / kam-6 | — | — | — | — | Combat, Run map, Pass |
| Slider / Toggle / Dropdown | row-embedded, 72 row h | value text right-aligned Rowdies 24 | row wood-2 | — | — | row outline cream | Settings |
| ListRow | min 48 (dense) / 72–96 (meta), radius 8, pad 0 12–24 | wood-2 | wood-3 | — | opacity 0.5 (claimed) / 0.6 (locked) | wood-2 + 4 px cream outline | everywhere |
| Tile · item | art box + name (Rowdies 24, ellipsis) + badge (Work Sans 18, rarity colour) | wood-1 @ 90% | — | — | art at 40% (locked) | wood-2 + cream outline | Store, Profile, Codex |
| Tile · Axie | square preview ≥ 160 (aspect 1), name + slot | 2 px neutral-7 frame | — | — | dashed red-8 "Missing" | cream outline | Vault, Presets, Run setup |
| Die face tile | 88 (Axie) / 56 (Egg), radius 20 / 14, ivory kam-9, glyph 36 / 22 + value Rowdies 28 / 20, side = hard shadow 0 6 in face colour, word under it | tilt ±2–5° | — | — | opacity 0.4 + "· used" | lift −18, rotation 0, shadow 12, 3 px cream outline offset 5 | Combat |
| Axie card (tray column) | 152 w: die 96 slot, word row 22, name + HP row, HP bar 10 | — | — | — | — | — | Combat |
| HP bar with shield + poison | HP green + Shield blue segment on one track; Shield/Poison count as a chip above the Axie head (wood-2, icon 22 + Rowdies 20) | — | — | — | — | — | Combat |
| Enemy intent marker | face icon 20 + Work Sans 18 ("8", "5 all", "18 to all") | — | — | — | — | acting: cream outline row | Combat enemy list |
| Target label | h 36, cream fill, wood-1 text, "Target · Name" | — | — | — | reason version: red-2 fill, cream text | — | Combat |
| Turn banner | full width × 120, wood-1 @ 90%, Rowdies 36 + Work Sans 18 sub | — | — | — | — | — | Combat |
| Toast | h 56, wood-1, 8 px status dot (green-6 / red-6), max 3 stacked, no actions | — | — | — | — | — | system |
| Network notice | wood-2 row, text + secondary S "Retry"; reconnecting = 24 spinner | — | — | — | — | — | system, Land hub, Result |
| ScrollBar | 8 w, radius 4, grabber wood-4 on wood-1 | — | wood-5 | wood-6 | — | — | long lists |
| Currency pill | icon 32 + Rowdies 24, inside one plate, 24 gap | — | — | — | — | — | Land hub, meta header |
| Coach card | 640 w, wood-1, radius 12, pad 24, arrow 32×20 toward spotlight; spotlight = scrim with a 12 px-radius hole + 4 px cream outline | — | — | — | — | — | Tutorial |

Face types (always glyph + word + colour): ATTACK red-6 (word in red-7 for contrast), SHIELD blue-7, HEAL green-6, POISON axie-plant, MANA purple-7, BUFF kam-5, WEAKEN axie-bird, SUMMON kam-8, BLANK neutral-6 ("–").

Reference frames: the A4 .dc.html files show every component in use; there is no separate component sheet file.
