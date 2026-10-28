# UI-05 prompt for Claude Design: redo the UI (HTML → Figma)

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
3. **Quy trình (Liam chốt 28/10):** Claude Design không vào được Figma, nên vẫn vẽ bằng HTML. Nhưng mỗi màn phải là một khối HTML sạch: flex, tên phần tử bằng tên node Godot, màu và kích thước bằng biến CSS.
   - Claude Code đưa từng màn vào **Figma của Liam** (connector Figma chính thức, đã đăng nhập).
   - Liam chỉnh trực tiếp trong Figma tới khi ưng.
   - Claude Code đọc lại số đo từ Figma rồi code. **Figma là bản chuẩn cuối.**
   - Hiệu ứng lớn vẫn giao dạng prototype HTML chạy được, kèm bảng thông số.
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
- Your HTML goes into **Figma**. The owner polishes it there, and we read exact numbers back from Figma.
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

## 3. Deliverable 1: screen HTML built to become Figma (most important)

You cannot reach Figma, so you deliver HTML as before. We then convert each screen into the owner's Figma file with Figma's HTML-to-Figma import. The owner polishes it there, and we read the final numbers back from Figma to code it. **Figma becomes the source of truth.** So build the HTML so the import is clean and the numbers survive:

**One file per batch, one element per screen state**
- `ui05-<batch>-screens.html`, self-contained: all CSS in `<style>`.
- Images either as base64 data URIs or as relative paths to `assets/`; we inline them before import.
- Each screen state is one `<section class="frame" id="<screen-id>--<state>">` at exactly **1920×1080** (e.g. `02-combat--player-turn`, `30-defeat--paid`). The import turns each `.frame` into its own Figma frame, with at most 20 per call, so keep a batch around that.
- For every screen, also one **1280×720** frame of the same state (`...--player-turn--1280`). Not a scaled copy: check that it reads well at that size.
- The 3D area is a plain placeholder block (`class="safe-area"`) with a label. No screenshots under the UI unless the frame is a "before" reference.

**Layout = Godot containers**
- Use only flexbox (row → HBox, column → VBox) and CSS grid (→ GridContainer). No floats, no transforms for layout, no absolute positioning, except the floating HUD clusters at the screen edges (→ Godot anchors). For those, use `position:absolute` with top/left/right/bottom in px.
- Fixed sizes in px. Use `flex:1` only where a Godot node should expand.

**Names = node names**
- Every meaningful element has an `id` or `data-name` in PascalCase: the Godot node name, e.g. `EndTurnButton`, `IntentBlock`, `TierBand`, `ShardHero`.
- These become the Figma layer names, and we keep them in code.

**Tokens = CSS variables**
- Every colour, radius, spacing, stroke, text size and shadow is a CSS custom property, named exactly like our `tokens_ui3.json` keys (`--color-plate`, `--radius-l`, `--size-dock-w`…). Keep existing names where the meaning is the same; add new ones with a comment.
- **One source for layout numbers:** dock widths, card sizes, panel widths and column widths are `--size-*` variables, never repeated literals.
- **Two shadows our build already needs:** `btn_secondary_pressed` (y 2, `#1a120d`) and `keycap_pressed` (y 1, `#000000a0`). Keep them, or replace them with your own pressed-state shadows for those two cases.
- Also send the full token list as `tokens.json` (same schema as `tokens_ui3.json`).

**Components and states**
- Repeated pieces get one CSS class and appear in a `components` frame showing every state: default, hover, pressed, focus, disabled-with-reason, selected, locked, waiting.
- Same names as our component list where it applies: KeyCap, TierChip, CategoryChip, HouseChip, RunRuleChip, EnemyTag, NameSuffix, IntentBlock, AttritionCard, ActionDock, DiceDock, NetNotice, UpdateBar, button variants.

**Assets**
- Only existing art: `icons/` (ui3, game, chests) and the captures.
- Keep each icon's file name in `data-src` so we can match it.
- If something needs new art, put a labelled placeholder and list it under "Art requests".

**Godot limits (same as before)**
- Text sizes only 16 / 18 / 24 / 32 / 36, plus 28/20 for numbers on dice. Ask if you truly need another; one larger "hero" size for big numbers is negotiable.
- Hit areas ≥ 44.
- Flat fills plus hard shadows (`box-shadow` with 0 blur). Bevels from borders and offset layers.
- No blur, no `filter`, no gradient fills on UI panels, no masks or `clip-path`.
- One translucent background per panel.
- If you want a gradient or glow, say where; we may do it with a texture.
- If something can't be shown in HTML (a stretch rule, 9-slice margins, focus order, Esc behaviour), write it in a `<!-- godot: ... -->` comment inside the element.

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

- `ui05-<batch>-screens.html` (section 3), `tokens.json`, `assets/`.
- The HTML prototypes plus the motion table for that batch (section 4).
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
- Anything Godot needs that HTML can't show goes in a `<!-- godot: ... -->` comment (section 3).
