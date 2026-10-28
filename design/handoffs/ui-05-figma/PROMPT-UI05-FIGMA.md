# UI-05 prompt for Claude Design: redo the UI in Figma

**Tóm tắt cho Liam (theo câu trả lời 28/10):**
1. **Lý do làm lại:** Liam chưa ưng UI-04 ở ba chỗ.
   - Code ra chưa giống thiết kế.
   - Bản thiết kế chưa đủ đẹp.
   - Hiệu ứng chưa đã.

   Nhánh UI-04 được giữ lại, không deploy.
2. **Hướng mới:**
   - Nhìn như game mobile thương mại.
   - Đúng chất Axie / Lunacia.
   - Ít plate hơn, để cảnh 3D và nhân vật nổi lên. HUD mỏng.
3. **Quy trình:** Claude Design dựng thiết kế trong **Figma**, theo luật đặt tên và auto-layout để mình đọc thẳng số đo, màu, ảnh qua MCP (Framelink + Figma chính thức) rồi code đúng từng px. Hiệu ứng lớn thì giao **prototype HTML chạy được** kèm bảng thông số.
4. **Phạm vi:** toàn bộ UI, chia 4 đợt.
   1. Trận đấu.
   2. Run.
   3. Land + Run setup.
   4. Meta + các màn còn thiếu.

   Duyệt xong đợt trước mới làm đợt sau.
5. **Art:** chỉ dùng art đang có. Cần art mới thì ghi vào "Art requests", chưa vẽ.

---

# Brief: rebuild the Axie Dice UI in Figma (UI-05)

## 1. Why we are doing this again

You designed UI-03 (A4 Blend on Terrariums) and the UI-04 polish. We built UI-04 in Godot, and the owner played it. Verdict: not there yet, for three reasons.
1. **The build does not match the design.** Sizes, spacing, colour and feel drift between your HTML frames and our Godot screens. We read numbers from specs by hand, and things get lost.
2. **The design itself is not good enough yet.** It still reads as a tidy prototype, not a game people want to spend on.
3. **The big moments are not exciting.** Winning, opening a box, revealing a Core, an Anchor awakening: they look correct but don't feel great.

This round fixes all three:
- The design lives in **Figma**, built so we can read it straight into code.
- The direction moves (section 2).
- Big moments come as **runnable prototypes**, not only tables.

## 2. Direction

Hit all three at once:
- **Commercial mobile game.**
  - Look at the best-selling gacha / roguelike games for the bar.
  - Chunky, confident UI: thick readable numbers, buttons that look pressable, depth from hard shadows and bevels, clear rarity colours, rewards that look valuable.
  - Nothing looks like a web app or a dashboard.
- **Axie / Lunacia.**
  - Soft, round, warm, friendly, bright.
  - Hand-drawn feeling where the art allows.
  - Cute, never grim or "tech".
- **Less box, more world.**
  - The 3D scene and the Axies are the hero.
  - HUD pieces are thin and float over the scene at the edges.
  - Fewer full plates, and no panel bigger than its content.
  - In combat, show more arena and characters and less UI.

Keep from before: Rowdies + Work Sans, cream text (never pure white), one primary per screen, Gem violet only on paid surfaces, red only for danger.

You may change: palette, plate shapes, button style, iconography usage, layout and density inside each screen, which info is always visible and which sits behind a tap.

## 3. Deliverable 1: the Figma file (most important)

We read your Figma file with an MCP that extracts layout, styles, variables and images. Build it so the extraction maps 1:1 to Godot.

**File structure**
- Page `00 Foundations`: variables, text styles, effect styles, the component library.
- Page `01 Combat`, `02 Run`, `03 Land & Setup`, `04 Meta`: one per batch (section 5).
- Page `99 Archive`: explorations. We ignore it.

**Frames**
- One top-level frame per screen state, at **1920×1080**, named `<screen-id>/<state>`, e.g. `02-combat/player-turn`, `02-combat/waiting`, `30-defeat/paid`. Screen ids follow `screens-current/INDEX.md` and the UI-04 ids.
- For every screen, also one **1280×720** frame of the same state. Not a scaled copy: check that it reads well at that size, and use the same components.
- Mark the 3D safe areas as a locked layer named `safe-area` (party, enemies, boss, dice in use, Land centre).

**Auto-layout = Godot containers**
- Use auto-layout everywhere: vertical → VBox, horizontal → HBox, wrap → Grid.
- Fixed vs fill vs hug sizing must be set on purpose. We copy it as is.
- Absolute positioning only for the floating HUD clusters at screen edges, and only with constraints set: left/right/top/bottom/center. We copy them as anchors.
- No groups for layout, only frames with auto-layout.

**Names = node names**
- Layer names are PascalCase, the name we will give the Godot node, e.g. `EndTurnButton`, `IntentBlock`, `TierBand`, `ShardHero`.
- No "Frame 123", "Group 4", "Rectangle".
- Text layers are named for what they hold, e.g. `Title`, `Value`, `Reason`.

**Variables = tokens**
- Every colour, radius, spacing, stroke and text size is a Figma **variable**, never a raw value on a layer.
- Collections: `color`, `radius`, `space`, `size`, `stroke`.
- Variable names use the same snake_case as our `tokens_ui3.json`: keep existing names where the meaning is the same, add new ones with a short description.
- Shadows are effect styles named like our shadow tokens.
- **Two shadows our build already needs:** `btn_secondary_pressed` (y 2, `#1a120d`) and `keycap_pressed` (y 1, `#000000a0`). Keep them, or replace them with your own pressed-state shadows for those two cases.
- **One source for layout numbers:** dock widths, card sizes, panel widths, column widths. Make them `size` variables, so changing one number in Figma changes it everywhere in our code.

**Components**
- Every repeated element is a component with **variants for every state**: default, hover, pressed, focus, disabled-with-reason, selected, locked, waiting.
- Same names as our component list where it applies: KeyCap, TierChip, CategoryChip, HouseChip, RunRuleChip, EnemyTag, NameSuffix, IntentBlock, AttritionCard, ActionDock, DiceDock, NetNotice, UpdateBar, button variants.
- New components get a one-line description in Figma.

**Assets**
- Only existing art: `icons/` (ui3, game, chests) and the captures. Same icon files as UI-04.
- Mark every image layer with **Export** settings: PNG at 1x and 2x, or SVG for flat icons. Name it like the file it comes from, so we can match it.
- If something needs new art, put a labelled placeholder and list it under "Art requests" on the Foundations page.

**Godot limits (same as before)**
- Text sizes only 16 / 18 / 24 / 32 / 36, plus 28/20 for numbers on dice. Ask if you truly need another; one larger "hero" size for big numbers is negotiable.
- Hit areas ≥ 44.
- Flat fills plus hard shadows, bevels made from strokes and offset layers. No blur, no gradient fills on UI panels, no masks.
- One translucent background per panel.
- If you want a gradient or glow, say where; we may do it with a texture.

## 4. Deliverable 2: runnable prototypes of the big moments

For each moment, one small self-contained HTML/CSS/JS file that plays the moment at 1920×1080. Add a "replay" button and a "reduce motion" toggle, so the owner can judge the feel and we can copy it.

Moments:
- **Combat:**
  - hit
  - crit
  - big hit (≥ 25% of the target's max HP, or a knockout)
  - Axie knocked out
  - shield gained
  - turn banner (yours, enemy)
  - enemy intent reveal
  - boss phase change ("Phase 2")
  - victory (with a "Victory" band)
  - defeat
- **Run:**
  - Core offer reveal (face-down → flip), rising by tier: Moss → Amber → Crystal
  - Core taken, flying to the Cores plate
  - Anchor awaken
  - level up
  - reward taken
  - treasure open
- **Meta:**
  - Echo Box open (normal, duplicate → Fragments fly into the meter, Rare+ with rays, Mythic)
  - Open 10
  - Pass level up
  - Daily claim
  - Land tier up
  - currency gain (count-up + fly-to-chip)
  - run end (win / lose)

With each file, a table row per layer of the moment:
- What moves.
- Duration (ms) and delay.
- Easing (Godot Tween trans/ease names).
- Scale, offset, rotation and alpha values.
- Shake (px, ms).
- Hit-stop (ms).
- Particles: texture from `icons/`, amount, lifetime, speed, spread, gravity, size, colour variable.
- Flash and light sweep.
- Sound cue name.
- What Reduce motion removes. Our setting removes shake, hit-stop, particles and slides, and keeps fades ≤ 120 ms.
- How the player skips it (click / Space).

Everyday transitions stay ≤ 200 ms. Big moments must be skippable and should feel generous: layered particles, number pops, light sweeps, a short hit-stop, screen shake where it lands hard.

## 5. Batches (one at a time, owner approves each)

**Batch 1: Combat. Do this first and set the style.**
- 02-combat:
  - player turn, die picked
  - waiting for server
  - enemy turn
  - boss with SHELL and enrage
  - big-hit warning
  - A/B names
  - IDLE intent
  - attrition upcoming / active / max
  - Aid offer
- 30-defeat: paid, free, normal, mission.
- Reward pick: 31-reward-types (HP, Core, ascend, chaos, chaos confirm).
- Boss intro.
- Moments: all combat rows in section 4.

**Batch 2: Run.**
- 03-run-map.
- 47-core-offer (face-down, revealed per tier).
- 48-anchor-pick (none, picked).
- 49-anchor-awaken.
- Run rule offer.
- 13-treasure / event.
- In-run menu.
- Moments: run rows.

**Batch 3: Land & Setup.**
- 01-land-hub (signed in, guest, toasts, tier-up).
- 06-run-setup (stage 1, stage 3, guest, offline, newcomer locks).
- 37-tutorial-curtain.
- Moments: Land tier up, currency gain.

**Batch 4: Meta.**
- 40-missions (open, locked, guest, buy confirm, defeat stake).
- 10-result (win, loss, mission loss, offline).
- 20-echo-box (idle, reveal new, duplicate, open 10 + confirm).
- 21-season-pass (paging, before season start).
- 41-daily, 24-profile, 29-codex, 26-settings.
- 18-system: NetNotice offline / timeout / retrying, Update bar.
- Moments: meta rows.

## 6. Inputs we send

- `screens-current/`: every screen of the live build, both sizes, plus `INDEX.md`. These show where we are today.
- `ui04-built/`: our Godot build of your UI-04 at both sizes. These show where your last design landed and where it drifted.
- `tokens_ui3.json`: current tokens, with the UI-04 names.
- `ui04-handoff/`: your UI-04 README, components.md, motion.md and specs, so you keep ids and rules.
- `icons/`: all art you may use.
- `game-data.md`: real names, strings, numbers. Use these, and don't invent mechanics, prices or rewards.

## 7. What to send back per batch

- The Figma link with view access, plus the frame names in the batch.
- The HTML prototypes plus the motion table for that batch.
- A short README:
  - What changed vs UI-04 and why.
  - New variables and components.
  - Art requests.
  - Flags for anything unsure.
  - Copy changes listed per screen.

## 8. Rules for you

- Do not invent mechanics, prices, rewards or copy meaning. If an idea needs a rule change, write it as a proposal and don't draw it as if it exists.
- At most 7 information groups per screen, one primary action.
- Never cover the party, the enemies, the boss or the dice in use.
- If Figma can't express something Godot needs (a stretch rule, a 9-slice margin, a focus order, Esc behaviour), write it as a sticky note next to the frame.
