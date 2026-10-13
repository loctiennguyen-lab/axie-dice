# Review: Land hub v5 vs our 13-item fix list

What I read: the v5 `.dc.html` source (frame data, notes, key table, mesh table, state rules, fix list, lines ~270-425) plus the v4 review and decisions I/J. I did not render v5. The three `screenshots/0x-hub-check.jpg` files are NOT v5: I opened 03 and it still shows the Moon Card popup, so they are old. That means everything below about layout (overlaps, text size) is from the numbers in the code and the designer's own notes, not from looking at the picture. Someone should open the .dc.html once in a browser before we build.

## 1. The 13 items

| # | Item | Result | Evidence |
|---|------|--------|----------|
| 1 | Remove VIP / Moon Card | DONE | No VIP/Moon in the file (grep). Store badges are FREE/CLAIM/NEW only. |
| 2 | Draw all 6 tiers | DONE | TIERS has 6 palettes + own trees; frames: Savannah 01a/c/d, Forest 01b/e, Arctic 01f, Mystic 01g, Genesis 01h (8 slots), Luna 01i. |
| 3 | Land tier + Land Stone + key L + upgrade/max states | DONE | Chip shows tier, n/6, stone bar, L. 01f = UPGRADE ready (1000/1000), 01i = max tier. Need values (300/600/1000/1600/2400) are placeholders. |
| 4 | Leaderboard = Billboard Big, key B; Unlocks in Profile; P/D/C chips | DONE | `board` def uses billboard_big, key B. Chip says "Profile · Unlocks", chevron, P. D and C chips on the rail. |
| 5 | Dock badges not colour-only | DONE | Dock uses word pills FREE/CLAIM/NEW/OFFLINE/LOCKED. |
| 6 | Remove Mastery Hall | DONE | No Mastery building; key 8 unused; Gallery stays from Genesis. |
| 7 | Non-hover way to read signs | DONE | Names toggle on the rail / hold Alt shows all signs; touch: first tap = sign with Open, second tap opens; Pass date in dock; Gallery plot label always on. |
| 8 | Two New-run confirms | DONE | 01d normal, 01e mission ("You lose 150 Gene Shard"). Focus starts on Keep playing. |
| 9 | Overlap with Vault/Continue | PARTIAL | Claimed fixed by moving the lattice up 50 px (22 px gap), also at 8 slots and 1240 tall. Cannot confirm without a render. |
| 10 | States: guest, offline, loading, newcomer, first launch, Missions badge | DONE | 01h guest, 01g offline (banner + Retry), 01i loading, 01a newcomer + "Start here", Missions badge + "Missions N1–N3". |
| 11 | Key table | DONE | Table covers Enter (follows focus), 1 kept, 2-7, B, N, L, P, D, C, Alt, Esc (closes first), locked keys show reason. |
| 12 | Real building names | PARTIAL | Weaponsmith / Jeweler / Alchemy / EquipmentStall / GemStorage / House / Billboard Big are all named and "House" is used. Gallery still uses a stand-in sprite (`hl/b/mastery.png`, the old Mastery art) and mesh is "(mesh name?)". |
| 13 | Text size | PARTIAL | 14 px minimum at 1920x1080, and a scale-floor note (0.85) for 1280x720. Reasonable, but nothing shows it works; 0.85 floor may not fit the lattice at 720. |

## 2. New issues / conflicts

1. **Slots swapped vs decision J.** J says the Leaderboard goes in Mastery Hall's old slot. In v5 the board is at the top slot (-1,-1) (old Gallery slot) and Gallery moved to (-1,0), which was Mastery's slot. Harmless for the lattice, but it is not what we wrote. Easy for us to accept; just say which one is final. Plot label for the empty Gallery sits at (-1,0) accordingly.
2. **Newcomer lock is a new rule they made up.** Missions and Leaderboard locked for the first 5 runs ("Opens after 5 runs"). They flag it as a proposal. We have not decided it. I don't see anything in L1 decisions that locks Missions by run count (and N1-N3 stays in L1 per I). Needs Liam's yes/no. If no, remove the LOCKED look from 01a.
3. **Mission stake 150 Gene Shard is a placeholder.** Real amount/source is for lane A/E, as they say. Not a design bug, but lane L cannot finish the mission dialog until we know where the number comes from.
4. **Portal and Leaderboard turn 45°.** New requirement for lane L (yaw on SM_Portal_01 and the board). Their sprites don't show it. Check this looks right in 3D before committing; low risk.
5. **Gallery art is wrong/old** (Mastery sprite reused). It is only built at Genesis+, so it can't block L1 build of the lower tiers, but we need the real mesh name from lane I.
6. **Alt as a key chip on "Names".** Alt alone toggles the browser menu bar on Windows and can steal focus in web builds. Fine for desktop; for web, the button must be the primary way and Alt a bonus. Minor.
7. **Land Stone need values** (300/600/1000/1600/2400) are placeholders; lane L must read the real costs from the Land upgrade data, not copy these.
8. **Leaderboard has no dock entry** (only on the Land + key B). That fits our decision, but offline/locked states are readable only on the Land. Fine, just noting it is intentional.
9. **Screenshots in the zip are stale** (still v3/v4 look). Not a design issue, just don't use them as the reference.

Nothing else conflicts with L1: no VIP, no Mastery Hall, 6 tiers, Missions pinned to lv1 (stated in mesh table), Pass ends 29 Dec 2026, Unlocks inside Profile.

## 3. Paste-ready for Claude Design (only what is still missing)

```
Land hub v5 - small leftovers

1. Gallery: replace the stand-in sprite (hl/b/mastery.png is the old Mastery Hall art) with a real Gallery building, or tell us the mesh name. Until then label it clearly as a placeholder.
2. Confirm the slot plan: Leaderboard at the top slot and Gallery at (-1,0), or Leaderboard in the old Mastery slot (-1,0) and Gallery at the top. Our decision was Leaderboard in the old Mastery slot.
3. Newcomer lock (Missions + Leaderboard for 5 runs) is your proposal and is NOT approved yet. Please draw 01a with an easy way to remove it (or show a version without it).
4. Show proof for the Vault/Continue spacing and for 1280x720 (one screenshot each, current v5). The screenshots in the folder are old (still Moon Card).
5. Web: the Names toggle button must work without Alt; Alt is optional (browser menu key on Windows).
```

## 4. Verdict

**BUILD AFTER SMALL FIXES.** All 13 items are answered and nothing conflicts with the L1 decisions. Lane L can start on the lattice, chip, dock, states, key table and dialogs now. Before it touches the Leaderboard slot and the newcomer lock, Liam should decide points 1-2 above (slot, newcomer lock). Gallery art and a real render of v5 can follow in parallel.
