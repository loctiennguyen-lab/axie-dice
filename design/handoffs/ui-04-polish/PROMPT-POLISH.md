# UI-04 polish prompt for Claude Design

**Tóm tắt cho Liam (theo câu trả lời 28/10):**
1. **Phạm vi:** polish trên bản UI-03 đang chạy. Giữ bố cục, component và cây container; chỉ nâng màu, chữ, khoảng cách, chuyển động, hiệu ứng.
2. **Cảm giác:** gọn, dễ đọc, dễ thương kiểu Lunacia, cao cấp. Hiệu ứng mạnh chỉ ở khoảnh khắc lớn: thắng trận, mở hộp, chọn Core, thức tỉnh Anchor, lên cấp. Lúc bình thường thì yên.
3. **Art:** chỉ dùng art đang có, không vẽ icon hay minh hoạ mới. Được đổi màu, ghép lại, thêm chuyển động và particle từ texture sẵn có.
4. **Kèm theo:**
   - Ảnh từng màn ở 1920x1080 và 1280x720 (`screens-current/`).
   - Danh sách lỗi UX còn lại (mục 6).
   - Luật UI để code được trong Godot (mục 4).
   - `tokens_ui3.json` đang dùng.
   - Bộ icon đang có.
5. **Đầu ra và ưu tiên:**
   - Đầu ra giống round 2: zip gồm README, tokens.json, components.md, motion.md, `screens/<id>/spec.md`, HTML.
   - Thứ tự: trận đánh → bản đồ run và chọn Core/Anchor → Land và Run setup → màn meta và Result.

---

# Brief: polish pass on the live UI of Axie Dice (UI-04)

## 1. Where we are

Axie Dice is a turn-based dice-combat roguelike, live on the web and as a desktop app. The UI you designed in **UI-03 (A4 Blend on Terrariums, round 1 + round 2)** is now fully built in Godot and running. Players and the owner have played it for weeks.

This round is **polish, not a redesign**. The layouts, the component set, the container trees and the screen ids from round 2 stay. We want the same screens to look and feel finished: like a commercial game people want to spend on, not a prototype.

**Sent with this brief:**
- `screens-current/`: every screen of the build as it is today, at 1920x1080 and 1280x720, plus `INDEX.md` (one line per image). This is the starting point: polish what you see.
- `tokens_ui3.json`: the tokens the game reads today (colours, sizes, borders, shadows).
- `round-2-handoff/`: your round-2 README, components.md, motion.md and screen specs, for reference and ids.
- `icons/`: every icon and image already in the game: `ui3/` (UI-03 icons), `game/` (face, status, map-node and web icons), `chests/` (Echo Box chests). **Use only these.** No new icons, illustrations or item art this round.

## 2. The feel we want

The owner picked all four. Balance them like this:
1. **Clean and easy to read (always).** Less text on screen, clear hierarchy, numbers that matter are big, the rest is quiet. A new player should know what to press next on every screen.
2. **Cute Lunacia (always).** Soft, round, warm, friendly, close to the Axie world. Playful details are welcome: a bounce, a wobble, a little hop. Never grim or "tech".
3. **Premium, worth paying for (always).** Consistent spacing, crisp plates, confident type, rewards and currencies that feel valuable. Gem violet only on paid surfaces.
4. **Juicy, lots of effects (only at big moments).** Win a fight, open an Echo Box, reveal a Core, an Anchor awakens, level up, a big hit lands, a boss phase changes, a run ends. These moments get full treatment: punch, shake, particles, number pops, light sweeps. Everyday actions (hover, select a die, end turn) stay short and calm.

## 3. What you may change

- Colours, contrast, surface tints, stroke and shadow values (update tokens).
- Type: size choice within the allowed set, weight, case, letter spacing, line height.
- Spacing, padding, alignment, grouping inside the existing containers.
- Plate shapes and corner radii, using flat StyleBoxes.
- How existing icons and images are used: size, tint, background chips, badges, composition.
- Copy length and wording, when it makes a screen clearer. Keep meanings exact and flag every change.
- Motion and effects (section 5).

What stays:
- Screen structure and the component list. A new component needs a reason in the README first.
- The 3D world (Land, arenas, Axies) and the dice.
- Game mechanics, numbers, prices.

## 4. Rules so we can build it in Godot (unchanged from UI-03)

- Canvas 1920x1080, stretch `canvas_items` + `expand`. 1280x720 is a 0.667 scale and must still read well. Show both sizes for every changed screen.
- Text sizes: only 16 (key hints only) / 18 / 24 / 32, plus 36 for the turn banner and 28/20 for dice numbers.
- Fonts: Rowdies 700 for headings and numbers, Work Sans 400 for body. Never mix the two in one label.
- Hit areas ≥ 44 px. 8 px grid, 24 px screen margin.
- Text is cream, never pure white.
- One primary button per screen, at most 2 secondary.
- Selected: 4 px cream outline. Focus: 2 px amber ring, 4 px offset.
- Disabled controls say why, in text or a tooltip.
- Red only for danger.
- Panels: flat StyleBox + hard shadow. No blur, no gradient, no mask, no shader on UI panels. One translucent background per panel. Modal scrim is neutral-1 at 80%.
- A colour that encodes a mechanic always comes with that mechanic's glyph.
- A screen fits or scrolls. A cut-off row with no scrollbar is the worst bug.
- At most 7 information groups per screen.
- **Effects that are allowed** (all buildable without UI shaders):
  - Tweens on position, scale, rotation and modulate/alpha.
  - Screen/camera shake.
  - Number pop and count-up.
  - Flash by modulate.
  - 2D particles (CPUParticles2D/GPUParticles2D) using textures from `icons/` or simple shapes.
  - Sprite-sheet-free light sweeps done as a moving translucent plate.
  - Ask before you rely on anything else.

## 5. Motion and effects deliverable

Extend `motion.md` with one table row per moment: trigger, what moves, duration (ms), easing (Godot Tween trans/ease names), delay chain, particles (texture from `icons/`, amount, lifetime, spread, colour token), sound cue name (we map it), skip rule (any click or Space skips long sequences). Cover at least these moments:
- **Combat:**
  - die selected
  - die used
  - hit / crit / big hit on enemy
  - Axie knocked out
  - shield gained
  - turn banner
  - enemy intent reveal
  - boss phase change
  - victory
  - defeat
- **Run:**
  - Core offer reveal (Moss / Amber / Crystal tiers get rising intensity)
  - Core taken
  - Anchor awaken
  - level up
  - reward taken
  - treasure
- **Meta:**
  - Echo Box open (normal, duplicate, rare+)
  - Pass level up
  - Daily claim
  - Land tier up
  - currency gain on the HUD (count-up + fly-to-chip)

Keep every everyday transition ≤ 200 ms. Long moments must be skippable.

## 6. Known issues the polish should solve

These come from our UX review and live play. Most wording bugs are already fixed in the build. These remain, or are better solved visually:
- **Combat HUD:**
  - The dice tray, enemy intent plates, the End turn block and the Undo/Hold/Wild/Overcast row look like separate prototypes. Unify them.
  - New states shipped recently that need proper visuals:
    - the big-hit warning on an intent ("Can knock out an Axie")
    - A/B suffixes on repeated enemy names
    - the IDLE intent
    - the "Waiting for server…" state (all actions greyed)
    - the attrition card (shows from 3 turns before it starts)
    - the Space key cap on End turn
- **Elite / Leader / Shell tags:** three tag kinds now exist (ELITE, LEADER, SHELL). Make them distinct and readable at 1280x720.
- **Run map and Cores:**
  - Core tiers are named Moss → Amber → Crystal. A hint line explains them today. Make the tier read at a glance using colour plus an existing glyph.
  - Core category tags reuse arrows that also mean Weaken or Level up. We have no new icons, so solve it with tint, chip shape or a short text tag.
  - The run map chip shows the Anchor name and progress ("Kin · House Cores 0/2") and "Run rule: <name>". Make both clear without clutter.
- **Anchor pick:** three dense cards (summary line, rule, price, awakens, glossary). Make the price and the awaken condition easy to compare across the three.
- **Missions:**
  - Six tier cards carry stake, payout, net, estimated win chance and warnings.
  - Locked tiers are dimmed with a full condition.
  - Make the risk ladder obvious and the screen feel premium: this is where Shards are staked.
- **Result:** win / lose / mission lost. Shards change, the Pass card ("Season Pass, Lv N, x/y XP") and run stats. The run ending should feel like a moment (section 5).
- **Echo Box:**
  - Opening must be the most exciting moment in the meta.
  - Buttons show cost ("Open 10 · 10 tickets"), and Open 10 asks for confirmation.
  - Duplicate reveals and pity bars need clearer visuals.
- **Pass:** at 1280x720 the left column now scrolls, so there are two scrollbars on one screen. Find a layout without the double scroll inside the same structure.
- **Land:**
  - HUD chips (Shard / Stone / Gem, Upgrade Land, Daily, Start run), toasts (shown one at a time) and the tier-up banner.
  - Keep the 3D Land as the hero.
- **Run setup:**
  - Mode buttons with lock reasons ("Opens after 5 runs · 1 of 5", "Sign in to play Daily").
  - New lines for Anchor and for the A7+ lock reason.
- **NetNotice (offline / slow):**
  - Small, top-centre, names the failed action ("Could not send your turn"), with RETRY as the primary button.
  - The "Update required" bar sits on the top edge.
  - Both need to feel intentional, not like error dumps.
- **Text density:** several screens still read as walls of small text. Cut, group and size up where the rules allow.

## 7. Deliverables (same format as round 2)

One zip:
- `README.md`:
  - A table of screens you changed (round-2 id, what changed, why).
  - New or changed tokens and components listed first.
  - Flags for anything unsure.
- `tokens.json`: full file, changed keys marked in a `_changed` list.
- `components.md`: changed components only, with every state.
- `motion.md`: the full table from section 5.
- `screens/<id>/spec.md` for every changed screen, using the round-2 ids. Mark changed lines. Keep the container-tree style, string limits, states, focus order and Esc behaviour.
- `.dc.html` design files, plus one self-contained HTML that shows **before (our screenshot) and after** for every changed screen, at 1920x1080 and 1280x720.

## 8. Rules for you

- Do not invent mechanics, prices, rewards or copy meaning. If a polish idea needs a rule change, put it in README as a proposal and do not draw it as if it exists.
- Use only the icons and images in `icons/` and `screens-current/`. If something truly needs new art, list it in README under "Art requests" and draw a labelled placeholder.
- Keep every screen ≤ 7 groups with one primary action.
- Respect the 3D: never cover the party, the enemies, the boss or the dice in use. Mark the safe area on combat and Land.
