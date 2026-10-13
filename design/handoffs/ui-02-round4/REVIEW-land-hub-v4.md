# Review: Land hub v4 (for L1 build)

Looked at: `Dice UI R1 - Land Hub v4.dc.html` (frames 01a-01d, template, dock/keys code), `01-hub-v4.jpg` (02 not opened, same frames), `houses.json`, `LandNav.gd`, `Land.gd` (BUILDINGS/PLOTS/key handler), R3 README §1. v4 is the L1 pick, so this is about what must change before we build, not whether to change direction.

Short version: the look and the 3x3 lattice are fine and buildable. But v4 still has the VIP/Moon Card stuff (cut), only shows 2 of 6 biomes, has no entry for half the screens we have, and leaves out every non-happy state (offline, guest, newcomer, loading, mission run open).

## 1. Logic errors

1. **"New run" while a run is open has one confirm, but there are two cases.** v4 says "asks to confirm first". If the open run is a mission run (N1-N3), abandoning loses the stake. The confirm must say that, with the amount. A normal run just says progress is lost. v4 draws neither dialog.
2. **Enter = RUN / Continue clashes with focus.** The hub also has dock buttons, rail buttons and houses that take focus (focus ring per R3). When something is focused, Enter should press that thing. Land.gd today only treats Enter as RUN when nothing has focus (`gui_get_focus_owner() == null`). v4 doesn't say what happens. Also the Portal key `1` from R3 is gone from v4 (RUN shows "Enter", no `1`). Pick one: keep `1` and Enter, or drop `1`, and say so.
3. **Signs only on hover/focus = nothing on touch and web.** A tap opens the screen right away, so touch players never see a sign (name, key, "Season 1 · ends 29 Dec 2026", "Builds at Genesis Land"). The Pass end date and the "builds at X Land" text exist only in the sign. These must also be reachable another way (long-press, or a visible line somewhere).
4. **Dock dots are colour-only.** The bubbles on the Land say FREE / CLAIM / NEW, but the dock dot is just an orange circle, so FREE, CLAIM and NEW look the same there (also fails "not colour alone"). Dock should carry the same word or a glyph.
5. **Dock hides things.** Dock has 6 entries (Team 2, Missions 3, Vault 6, Echo 4, Pass 5, Store 7). Mastery Hall (key 8) is "Land only", so a player who never hovers that building has no way to know it exists, even though its NEW bubble is there. Dock label says "Team" while the sign says "House" and R3 says House. Pick one name.
6. **Overlap in 01b:** the "New run" tag and Continue block sit on top of the Vault at (960, 930). In the screenshot the Vault and its NEW bubble are half behind them. The Vault is the lowest lattice slot and is under the dock area even in 01a.
7. **01a "new player, day 1" shows Pass CLAIM and Echo FREE.** A first-day player has nothing in Pass to claim. Maybe true (first-login reward), but it should be checked, not assumed. Also nothing draws the first-run state: no hint on RUN, nothing about the tutorial.
8. **Land tier is two 12 px words** ("Savannah Land") on the profile chip and nothing else. No Land Stone cost, no upgrade button, no key L. The player has no way to reach the upgrade screen (R3 M15) from the hub as drawn.

## 2. Missing pieces

Screens that exist (LandNav SCREENS / R3 map) with no entry in v4:
- **Profile (P)**: the chip top-left is drawn like a label, no key, no hover, no hint that it opens anything.
- **Leaderboard (B)**: no entry. R3 put it in Run Setup's header; v4 doesn't say if that still stands.
- **Land upgrade (L)**: none (see 1.8).
- **Unlocks**: no entry in v4, houses.json, or R3's key list. LandNav has the id. Need a decision where it lives.
- **Guides**: R3 folds it into Codex rail. Fine, but confirm.
- **Account**: in Settings for now. Fine, but guest needs a visible "sign in" somewhere.
- Daily (D) and Codex (C) exist but the rail buttons show no key chips (the dock buttons do).
- Settings has no key chip (R3: Esc on the hub). OK, but say it; and Esc must close a modal/sign first.
- **Gamepad**: dropped by Liam. v4 draws none. Fine.

States not drawn at all:
- **Offline**: Store, Pass, Echo Box (server-rolled dice), Daily, Leaderboard need online. No disabled dock/house state, no offline banner.
- **Guest**: no name (chip says "Liam"), no "local only / sign in" line.
- **Loading** (waiting on the server for badges/wallet): nothing. Wallet numbers and bubbles need a placeholder.
- **Newcomer (first 5 runs)**: which hub things are hidden? Aid is a Run Setup/combat thing, but hub should be told what to hide (Mastery/Gallery plots? Leaderboard? Store Aid?). Not drawn, needs a rule.
- **Locked houses** with no min_tier lock but a min_runs lock (Land.gd reads `min_runs`): no locked look other than the empty plot.
- Missions: no badge in any frame, even though houses.json gives Missions a badge id. No "new/claim" bubble and no sub line.
- Vault shows only NEW; what about claimable/other badges? Probably fine, just say which are possible per house.
- Per-biome frames: only Savannah and Arctic are drawn (see 3).

## 3. Conflicts with L1 decisions

1. **VIP / Moon Card (cut for L1):** all of this must go: frame 01c (the whole Moon Card popup: 4.99 USD, "VIP · 30 days", "20 Gem a day", "1 Echo ticket a day", "Continue at -25%"), the `VIP` badge colour, the `VIP` bubble on Store in 01b, and the note "Moon Card is always in the Store". Also the "No Gene Shard boost / No Land Stone boost" rows. The popup also contradicts "online-only/no paid shortcuts" tone we agreed for L1. Store badge slot stays, it just can't say VIP.
2. **Land has 6 tiers, v4 shows 2.** Only Savannah and Arctic. Forest has no frame (the code only branches on `arctic`; correction by art-director 13/10), Mystic, Genesis, LunaLanding are not drawn at all. Gallery should appear built at Genesis (tier 5) and Mastery at Arctic (tier 3); v4 only shows Mastery built. No frame for tier 5/6 with all 8 slots full (that is the busiest layout and the one that will have overlap problems).
3. **House level per tier.** Our Land.gd steps House/Alchemy/etc up with tier (lv1..lv4). v4 uses the same sprite at every tier, which is fine for design, but the Missions house **cannot be upgraded** under L1. Land.gd currently picks `Weaponsmith_lv%d` for missions, so lane L has to pin Missions to lv1.
4. **Missions N1-N3 only:** not contradicted, but also not stated anywhere in v4. A sign/sub line for Missions would help ("3 missions" or similar) and must not promise more.
5. **Pass season ends 29 Dec 2026:** v4 matches, but only in the hover sign (see 1.3).
6. **Seasonal box:** none in v4. Good.
7. **Sprite names look swapped:** v4 uses `mastery.png` for Missions, `gallery.png` for Store, `armorsmith.png` for Mastery Hall. Our game uses Weaponsmith for Missions, Jeweler for Store, Armorsmith for Mastery Hall, GemStorage for Vault, Alchemy for Echo Box, EquipmentStall for Pass, and Mastery/Gallery are real separate buildings. Not a rule conflict, but Claude Design should know which real mesh each is, or the lattice picture won't match what we render.

## 4. Fix list for Claude Design (paste-ready)

```
Land hub v4 - changes needed before build

1. Remove everything VIP: frame 01c (Moon Card popup), the VIP badge colour, the VIP bubble on Store in 01b, "Store VIP" in the notes. No VIP trial in L1. Store may carry CLAIM/NEW/FREE badges only.
2. Draw all 6 Land tiers (Savannah, Forest, Arctic, Mystic, Genesis, LunaLanding). Show at least: Savannah (2 empty plots), Arctic (Mastery built), Genesis or higher (Gallery built, all 8 slots full) with a distinct sky/ground palette each. Same lattice at every tier.
3. Add a way to see the Land tier and upgrade it: tier name + Land Stone progress (placeholder numbers, e.g. "86 / 300") on the profile chip or next to the stone chip, with the key L. Land upgrades are paid with Land Stone only. (art-director 13/10) Draw the "can upgrade" badge state and the max-tier state (tier 6, no upgrade).
4. Show a missing-entry plan: Profile (P), Leaderboard (B), Land upgrade (L), Unlocks, Guides, Account/sign-in. Say for each: a button on the hub, inside another screen, or not on the hub. (Unlocks = the screen listing what the player has unlocked so far.) (art-director 13/10) Put key chips (D, C, P) on the rail/profile buttons, and make the profile chip look tappable.
5. Dock badge dots must not rely on colour alone: use the same FREE / CLAIM / NEW text or a glyph (or a count) as the Land bubbles.
6. Add Mastery Hall and Gallery to the discoverability story: either a "More" dock slot, or a visible line when they are built, so a touch player can find Mastery Hall (key 8, in the dock only on the Land) without hover. (art-director 13/10)
7. Touch/web: add a non-hover way to read a building's sign (long-press or a persistent label). The Pass end date (29 Dec 2026) and "Builds at X Land" must be readable without hover.
8. New run while a run is open: draw the confirm dialog, in two versions: normal run (progress lost) and mission run (the mission stake is lost, state the amount). Default focus on Keep playing/Cancel, not on the destructive button.
9. Fix the overlap in 01b: the "New run" tag and Continue block sit over the Vault. Move the tag or the Vault slot. Show the same check at the 8-slot tier.
10. Draw states: guest (no name, "Playing as guest - sign in to save online"), offline (Store, Pass, Echo Box, Daily, Leaderboard disabled with a reason, one banner), loading (wallet + badges placeholders), newcomer (first 5 runs: what is hidden), first launch (RUN hint). Add a Missions badge and a Missions sign line ("N1-N3").
11. Keys: state whether key 1 (the Portal / RUN button) still works alongside Enter, what Enter does when a dock/house button has focus, and that Esc closes sign/modal first, opens Settings only when nothing is open. List all keys in one table (1-8, Enter, N, C, P, D, B, L, Esc).
12. Name the building for each entry: Missions = Weaponsmith, Store = Jeweler, Echo Box = Alchemy, Pass = EquipmentStall, Vault = GemStorage, House = House (call it "House" everywhere, not "Team"), Mastery Hall = Armorsmith. Current sprite names in the file look swapped.
13. Min text: dock key hints and the New-run helper are 12 px, and at a 1280x720 window the whole 1920x1080 layout scales down to about 8 px. Raise them or say it is acceptable at minimum canvas.
```

## 5. Notes for lane L

- **Layout is feasible.** The 3x3 lattice is 8 slots around the Portal with u=(300,150), v=(-300,150). Slot centres at the 1080 canvas: House (-1,1)=(360,580), Missions (0,-1)=(1260,430), Store (1,-1)=(1560,580), Echo (0,1)=(660,730), Pass (1,0)=(1260,730), Vault (1,1)=(960,880), Mastery (-1,0)=(660,430), Gallery (-1,-1)=(960,280). Our `BUILDINGS` table is a wider, non-lattice layout (cx 235...1685), so this is a retune of cx/base/w/h plus `PLOTS` (Gallery plot moves to the top slot, Mastery plot to (660,430)). Eight slots is exactly full, so there is no room for another building. Anything new (Profile, Leaderboard, Land upgrade) has to be a button, not a house.
- **houses.json** needs no new rows for v4. Profile/Leaderboard/Land upgrade/Unlocks are not houses.
- **2D-only things in the mockup.** (a) CSS `drop-shadow` hover glow: in 3D use an outline or rim/emission pass on the hovered mesh. (b) Painted path/plaza polygons on the ground: do as textured ground quads or decals. (c) Sign + bubbles: project the 3D building top to screen and draw Controls there (already how the key chips work). Mind occlusion: a bubble for a back house must not show through a tall front house. (d) The "Axie 3D" dashed ovals are placeholders. Real Axies are decoration only, no click, and must stay out from behind the dock.
- **Dock and rails are plain Controls** pinned to viewport edges (anchor, not mockup y), as the CLAUDE.md `expand` rules say. The land centres in extra height. Test at 1920x1080 and a tall window (v4's 1240), plus 1280x720 for text size.
- **Keys:** `_unhandled_key_input` in Land.gd already does Esc, 0-9 and Enter. Add 8 (Mastery, only if built), N (New run, only when a run is open), C, P, D, B, L as R3 lists. 8 is not in R3's key list, so check with Liam. Don't fire a key for a locked/offline entry; show why instead.
- **Offline/guest/newcomer** need real flags from `AccountService` / `MetaState.is_newcomer`. Disable via LandNav `is_available` plus an online check. Nothing exists on the hub for this yet.
- **Missions house:** pin to lv1 (L1: cannot be upgraded), do not use the tier-stepped `Weaponsmith_lv%d`.
- **Abandon dialog:** the existing New run confirm in `_open_confirm` needs the mission-stake variant (read the open-run kind from the run save). Ask lane A/E for the stake amount source.
- **Moon Card / VIP:** if any VIP code or text already exists in Land.gd or the Store, it should not be built. I only grepped Land.gd for tier/continue/keys, not the Store scene.
- Not checked: `02-hub-v4.jpg` (same frames as 01), v2/v3, and the other `.dc.html` files in the folder.
