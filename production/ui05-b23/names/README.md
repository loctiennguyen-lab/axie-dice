# UI-05 dot 2+3: names theo lan

Sinh bang `python3 -I godot/tools/ui5_names.py --all` (tu cay chinh design/handoffs/ui-05-figma). Moi file la cay data-name cua cac frame cua lan; `# godot:` la comment luat trong HTML.

| Lan | Mo ta | Frame (ca 2 co) | Id (khong tinh co) |
|---|---|---|---|
| R1 | Ban do + HUD | 9 | 5 |
| R2 | Offers: core, rule (TRU make-room + combo-banner cua R4; them components-run--cards) | 25 | 13 |
| R3 | Anchor | 8 | 4 |
| R4 | Make room + Combo banner | 4 | 2 |
| R5a | Shop | 6 | 3 |
| R5b | Event + Treasure | 8 | 4 |
| R6 | Menu trong run | 10 | 5 |
| M2 | Moment B2 | 6 moment | - |
| S1a | Land HUD: idle + state RunPlate + tooltip + tier plate | 19 | 10 |
| S1b | Land HUD: toast, coach, confirm, banner offline | 16 | 8 |
| S2 | Edit Land + Land upgrade | 20 | 10 |
| S3a | Run setup: layout chinh | 35 | 18 |
| S3b | Run setup: picker, bang xep hang popup, Load/Save team | 16 | 8 |
| S4a | Team presets | 18 | 9 |
| S4b | Tutorial | 22 | 11 |
| S5 | Missions | 32 | 16 |
| S6 | Result | 24 | 12 |
| S7a | Leaderboard | 20 | 10 |
| S7b | Raid | 20 | 10 |
| S8a1 | Account + sign-in (a01-a12, a17-a18) | 28 | 14 |
| S8a2 | Boot offline, Welcome, ChooseSave, Move progress (a13-a16) | 8 | 4 |
| S8b | NetNotice + Update | 26 | 13 |
| S9a | Echo Box (tru ceremony) | 30 | 15 |
| S9b | Echo Box ceremony: opening, reveal-*, open10 grid, summary | 16 | 8 |
| S10 | Season Pass | 20 | 10 |
| S11a | Daily | 14 | 7 |
| S11b | Store | 26 | 13 |
| S12 | Profile | 16 | 8 |
| S13 | Codex + Guides + Unlocks | 14 | 7 |
| S14 | Settings | 28 | 14 |
| M3 | Moment B3 | 11 moment | - |
| 0d | Meta kit: sheet/setup cua land, meta1, meta2 | 4 | 4 |

Tong frame trong 5 file HTML: 540.

## Frame khong thuoc lan nao (0)
(khong co)

## Frame thuoc nhieu lan (tru 0d, S1a/S3a cung sheet)
(khong co)

## Cach chia / doan
- **S1a**: Chia 01-land (nua dau): idle (signed-in, guest), state RunPlate (loading, continue-run, continue-mission), land tier (tier-up, tier6-max), tooltip; + components-land--sheet.
- **S1b**: Chia 01-land (nua sau): first-visit (coach), toast-error, new-run-confirm, abandon-mission-confirm, banner offline/offline-retry/reconnecting, beta-reset. DOAN: beta-reset xep vao day (banner/thong bao), first-visit la coach.
- **S3a**: Chia 06-run-setup (nua dau): layout chinh va moi state cua no (kieu run, party, start-error, starting, closing...) + components-land--setup.
- **S3b**: Chia 06-run-setup (nua sau): picker, picker-empty, popup bang xep hang (lb-*), Load/Save team (presets-load, presets-save). DOAN: presets-save xep vao S3b cung Load.
- **R2**: DOAN: 47-core-offer--combo-tags (the co nhan combo) o R2; chi combo-banner o R4. Plan ghi R2 '47-core-offer x12 (tru make-room)' nhung R4 cung nhan combo, nen tach combo-banner sang R4.
- **S9a**: DOAN: ceremony = opening + reveal-* + open10 + summary; open10-confirm va seasonal-milestone o S9a.
- **0d**: Chu y: components-land--sheet con nam o S1a, components-land--setup o S3a (trung co chu y).
