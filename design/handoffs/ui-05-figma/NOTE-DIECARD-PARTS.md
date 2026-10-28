# UI-05 batch 1: DieCard must show the part (note for Claude Design)

Your component sheet's **DieCard** dropped the part. Parts are the core of combat, so please add them back.

**Why it matters**
- Every die belongs to one body **part** of its Axie: back, ears, eyes, horn, mouth or tail, each in one of the six classes.
- A **SET** is formed by dice of the **same part**: "SET OF 4 ×2.2" in the tray. Sizes 3 / 4 / 5 give ×1.3 / ×2.2 / ×2.6.
- Anchors build on this too:
  - Kin: same-class SETs hit harder.
  - Big Hand: SETs of 4–5 hit harder.
  - Embers: Held dice join a SET.
- The player plans every turn around which dice share a part. Without the part on the card, they can't see a SET coming.

**What the DieCard needs (all states: default, selected, used, waiting)**
1. **Part chip:**
   - The part glyph, from `icons/game/web/part/<part>_<class>.svg`, 72 files.
   - A short word, so the part still reads in grayscale or for colour-blind players.
   - Sits on the card, close to the die. It must stay visible when the card is selected and the die lifts. In the UI-04 build the lifted die covered the badge.
2. **SET preview:**
   - When dice of the same part are on the board, each card in the SET shows its value change, e.g. "5 → 8".
   - Give the SET members a shared highlight (same outline, tint or link line), so the group reads at a glance.
3. **SET banner** above the tray: "SET OF 4 ×2.2", which already exists. Restyle it to match the new tray.
4. **Special dice:**
   - Wild / Temp Face: a wild die joins any SET as a Temp Face.
   - Held die (Embers): carried to next turn.
   - Overcast: covers the whole SET.

   Each needs its own small mark on the card, so these dice don't look like plain dice.

Please send this as an update to your batch 1 sheet, plus a combat frame showing a live SET of 3 and of 4 with the previews.
