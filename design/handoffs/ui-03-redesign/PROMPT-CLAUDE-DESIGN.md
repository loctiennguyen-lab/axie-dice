# Prompt cho Claude Design: làm lại toàn bộ UI Axie Dice (UI-03)

**Tóm tắt cho Liam:**
1. Làm lại từ đầu, không vá. Dùng **Terrariums design system** (thay Dango). Claude Design được vẽ lại và vẽ art mới. Main Menu bỏ, Land hub 3D là màn đầu tiên sau đăng nhập.
2. 3 vòng: A = 3 cách áp Terrariums vào game (khác nhau về bố cục, mật độ, cách HUD nằm trên 3D), mỗi cách vẽ trên 4 màn (Land HUD, Combat HUD, Run Map, Store). Anh chọn 1. B = design system. C = tất cả màn, theo thứ tự ưu tiên. Anh chưa chọn xong vòng A thì không làm tiếp.
3. Chống "trông như AI": luật đếm được (tối đa 1 nút chính, 3 cỡ chữ, 2 độ đậm, 7 nhóm thông tin mỗi màn), có danh sách cấm, mỗi màn có checklist tự kiểm.
4. Hợp đồng code khớp với project: 1920×1080, `canvas_items` + `expand`, chỉ dùng flex/grid (map thẳng sang container Godot), tokens.json theo schema cố định, 9-slice có margin, bảng motion theo Tween, chữ tối thiểu 18 px ở 1920.
5. Danh sách màn chia 3 mức Must/Should/Could, mỗi màn ghi rõ trạng thái cần vẽ.

---

# Brief: redesign the whole UI of Axie Dice (UI-03)

## 1. The game, and why we are redoing it

Axie Dice is a turn-based dice-combat roguelike. You walk around a 3D hub (the Land), pick a party of Axies, and start a run. A run is a map of fights, events, shops, treasure and bosses; after a boss you pick a pact. In a fight you roll dice, each face is an action, you drag or click a die onto a target, then end the turn. Between fights you take rewards. Meta layer: Vault, Season Pass, Echo Box (gacha), Store, Missions, Daily, Leaderboard, Profile and cosmetics, Land upgrades. Engine is Godot 4.7, so the UI is Control nodes with a Theme. It ships as a desktop app (macOS, Windows) and on the web; mouse first, keyboard supported, touch laptops should work (44 px targets), but no touch-first layouts.

Why we redo it. The owner looked at every screen: ugly, cluttered, too many elements, looks AI-made. What we saw in the current build:
- Combat: the boss card overlaps the boss, ~11 px text in the decision area, eight unlabeled empty slots, a chip ("A6 v") nobody understands.
- Land hub: the Run button sticks to the bottom edge, a black tooltip clashes with everything, labels vanish into the trees.
- Run map: white text on cream panels, nodes are dark squares with "?" and no hierarchy.
- Result, Vault, Pass: unreadable text on busy backgrounds, text clipped at the edge, internal strings leaking ("[INF]", "Stat unlock: U Reroll").
- Store, Presets, Profile: 20-60% of each panel empty, six identical grey buttons, flat colour squares where art should be.
- Past mockup rounds were dense (10+ elements per card), too small (12 px at 1920 is 8 px at 1280), and hard to build because every screen invented its own components.

You may redraw everything and draw new art (icons, frames, panels, dice faces, chests, item art, avatars). **Use the Terrariums design system** as the visual base for everything. It replaces our old Dango design system (the cream/wood look); do not carry Dango over. The Main Menu no longer exists: after the boot/sign-in screen the player lands in the 3D Land hub, and every meta screen opens from it.

**Sent with this brief** (same zip):
- `world-3d/`: the 3D Land hub and combat arenas as they are today. The 3D world stays; your UI sits on top of it. **The HUD in these shots is the old UI: ignore it completely** and look only at the world behind it (colours, where the party and enemies stand, what space is free). We send no screenshots of the old screens on purpose: start from a blank page.
- `game-data.md`: real names and strings (Axie classes, the 8 die face types, relics, pacts, actives, currencies, map nodes, longest strings). Use these, do not invent names.
- `art/`: art already in the game (class portraits, face/status/map-node icons, UI icons, Echo Box chests). Redraw any of it if your variant needs to.
- `design-library/`: contact sheets and icons of Homeland art we are allowed to use (read its `INDEX.md`; refer to an image by its path).

**No Axie drawings.** In the game an Axie is always a live 3D model. Wherever a screen shows an Axie, leave a labelled frame "AXIE 3D" (same rule as the 3D viewport placeholders). Draw those frames at the real on-screen sizes in `game-data.md` ("Axie and enemy size on screen"): in combat the party row takes x 455–1460, y 630–890 at 1920×1080, and the HUD must not cover it.

## 2. Process: three rounds, we approve each

**Round A: three ways to apply Terrariums.** All three use the Terrariums design system. They differ in layout, density and how the HUD sits over the 3D world, not in colour swaps. Each one is drawn on the same four screens at 1920×1080: Land hub HUD, Combat HUD (player turn, a die selected), Run Map (mid-run), Store (Gem packs tab: proves the variant can carry a dense list). Per variant add one style tile showing how Terrariums is applied (palette with the one named accent colour, type pairing, a panel, primary and secondary button, six icons, one die face) and a one-line rationale. Add one 1280×720 frame of the Combat HUD per variant so we can judge text size. Say what each variant costs to build in Godot (low/medium/high, and why).

**Nothing past Round A happens until Liam picks a variant.** Do not start Round B or C early and do not blend variants on your own. Liam may ask for one revision of the chosen variant.

**Round B: design system**: Terrariums as applied in the chosen variant, plus the game-specific pieces: tokens and components (section 4), one frame per component with all variants and states.

**Round C: all screens** (section 5) in priority order, built only from Round B components. A screen that needs a new component sends that component back to Round B first.

## 3. Style guardrails (against the "AI look")

Countable rules, per screen:
- At most 1 primary action and 2 secondary actions visible at once.
- At most 7 information groups. A group is one block the eye reads as a unit (a card, a stat row, a list, a header). If a screen needs more, split it or move detail behind hover/click (the Info panel).
- At most 3 text sizes and 2 weights per panel.
- One named accent colour per variant, taken from Terrariums, and it means one thing (for example "act now"). Every other colour carries meaning (state, rarity, face type, damage) and is listed with that meaning in tokens.json.

Banned unless you write down why: glow, glass/frosted panels, neon rims, gradient fills across panels, sparkles, ornament flourishes, decorative dividers, empty frames, stacked shadows, inner glow, more than one stroke on an object, emoji-style icons, generic fantasy icons. Where Terrariums itself uses one of these, Terrariums wins: note where, and keep it to that use.

Also:
- Panels hug their content. Space is fine; a panel sized taller than its content is not.
- On Land and Combat the 3D world is the hero. The HUD sits on the edges, keeps the centre clear, and never covers the party, the enemies, the boss or the dice in use. Mark the safe area.
- Text never sits straight on 3D or a busy image: it gets a plate or a scrim.
- Use real game content (our Axies, dice faces, relics, Gem/Shard/Stone) drawn with intent. Axie names, face labels and relic names come from the game data we send, not invented ones.
- Each Round C screen's README row ticks this checklist: 1 primary, ≤2 secondary, ≤7 groups, ≤3 sizes / 2 weights, no banned items, text on plates, panel hugs content, focus order and Esc stated. If the 18 px floor and the 7-group cap clash on a screen (Combat at 1280×720 is the likely one), flag it in the README instead of quietly breaking one.

## 4. Codeability contract

Everything below is a requirement. If an idea breaks one, say so and propose the closest buildable thing. Terrariums decides the look; this section decides how it is built. If Terrariums uses an effect from the not-OK list (for example frosted glass), keep the look with the buildable version (a flat translucent fill instead of live blur) and list where you did that.

**Canvas and scaling**
- The project uses Godot stretch mode `canvas_items`, aspect `expand`, base 1920×1080. Scale = min(w/1920, h/1080); extra width or height becomes extra space, never letterbox. Draw for that: say for every screen where extra space goes (the 3D view or the panel body, never a stretched HUD element). 1280×720 is the smallest supported size.
- 8 px grid for spacing, sizes and radii (4 px allowed for hairlines and icon padding).

**Layout that maps to Godot containers**
- In the .dc.html use flex or grid only. No `position:absolute` except for modals, tooltips, toasts and the HUD layer over a 3D viewport.
- Give each screen as a container tree (HBox/VBox/Grid/Margin/Scroll + anchors). For each node give min size and whether it expands or stays fixed (Godot uses custom_minimum_size and expand/fill size flags, not flex-grow ratios).
- Say which region scrolls. Say for every label whether it wraps or truncates with an ellipsis.
- HUD over 3D: give the safe-area rectangle in 1920 px and each HUD block's anchor (edge or corner) and margin.

**tokens.json, fixed schema**
- Export the Terrariums tokens (plus anything added for the game) into this schema.
- Top-level keys: `color`, `font`, `size`, `radius`, `space`, `stroke`, `shadow`, `motion`, `z`. `font` maps each family and weight to its TTF file name.
- Colours as `#RRGGBB` or `#RRGGBBAA`. Sizes as plain integers in px, not strings.
- Each colour entry: value, meaning. Every text/background pair used, with its contrast ratio.
- Component styles keyed like Godot Theme items (`Button/styles/normal`, `Button/styles/hover`, `Button/styles/pressed`, `Button/styles/disabled`, `Button/styles/focus`, `Label/font_sizes/...`). Each StyleBox is either `flat` (bg, border width per side, radius per corner, shadow offset and colour, content margins) or `texture` (file, 9-slice margins, content margins).
- In the HTML, use CSS variables named after the token keys (`--color-accent`, `--space-16`), so a number in the source is the number we build with.

**Components: one fixed set**
Each with named variants and separate styles for normal, hover, pressed, disabled, focus, selected (where it applies). Say whether pressed shifts the label. Selected (current tab, equipped item) and focus (keyboard) are different states and must look different. The focus ring must not rely on colour alone. Disabled controls show the reason as text.
Minimum set: Button (primary, secondary, quiet, danger; M and L), IconButton, Tab, Chip/Badge, Panel (shell, card, plate), Modal, Confirm dialog (normal, warning, price), Tooltip / Info panel, ProgressBar, Slider, Toggle, Dropdown, ListRow, Tile (item, Axie, die), Toast, Network notice (offline with Retry), ScrollBar, Currency pill, Die face tile (8 face types + blank), Axie card, HP bar with shield and poison, Enemy intent marker, Turn banner.

**Art and assets**
- Prefer flat rounded boxes with borders (free in Godot) over textured frames. Textures only where they pay off.
- 9-slice art: `slices.json` lists file, margins l/t/r/b, minimum size, and whether the centre stretches or tiles. Content margins (padding) are given separately.
- Raster assets as PNG at @1x and @2x; say which one the 1920 layout uses. Monochrome icons as SVG plus a @2x PNG, with a flag saying they are tinted in code (modulate). File names `[category]_[name]_[variant]_[size].png`, e.g. `ui_btn_primary_hover.png`, `icon_gem_24.svg`.
- Fonts: use the Terrariums fonts (we currently ship Baloo 2 and Work Sans from Dango; they go unless Terrariums uses them). Any font must be OFL, cover Vietnamese diacritics, and come as one static TTF per weight (no variable fonts) with the licence file.
- 3D areas (Land view, combat stage, Axie previews) are flat grey placeholders labelled "3D VIEWPORT: combat stage", with the safe area marked.

**Effects**
- OK: flat and rounded StyleBox, borders, hard offset shadows, solid fills, textures, text outline up to 4 px (thin outlines only on large text, they get costly as font size grows), simple tweens (fade, slide, scale).
- Behind modals: a flat dark scrim (solid colour with alpha). No live blur; it needs a viewport capture and is slow on the web renderer.
- Not OK: gradients across panels, dashed borders, inner glow, backdrop blur, blend modes, SVG filters, clip-path and masks, animated shaders on UI, text on a curve, stacked semi-transparent layers (one translucent fill per panel is fine), full-screen translucent overlays other than the modal scrim.

**Motion**
A table per component and screen, including the hand-off between the 3D view and the HUD (opening a building, entering a fight, the victory run through the gate): trigger, property, duration (ms), Godot Tween transition and ease (e.g. `TRANS_CUBIC`, `EASE_OUT`), delay, and the reduce-motion behaviour (usually instant). Nothing flashes more than 3 times a second.

**Text and access**
- Real English strings, no lorem. Each dynamic label has a max length in characters and a width budget in px. Show the longest case once, and test every Round C screen with strings 40% longer. A few strings are Vietnamese today (ascension titles), so test one Vietnamese string per screen that shows titles.
- Minimum 18 px at 1920 for anything the player must read (12 px at 1280×720). 16 px only for key-hint chips (about 11 px at 1280×720, so never for anything the player must read). HP, damage and currency numerals larger.
- Contrast at least 4.5:1 for text (3:1 at 24 px and up), including disabled text that still carries information. Hit areas at least 44 px.
- Every screen states its focus order and what Esc does, in one line. In combat and on the run map, Esc opens the in-run menu.

## 5. Screen inventory, priority and states

Priority: **Must** = a playtester hits it in their first run; **Should** = meta screens used in week one; **Could** = do last. Draw Must first and deliver it before Should. One frame per state listed (small changes can share a frame if both are labelled).

**Must** (deliver in this order: Land hub, Combat, Run Map, Reward, Result, then the rest of Must)
- Boot / sign-in: loading, signed out with Sign in, signing in, error, offline.
- Land hub HUD: first visit, returning player, signed out ("Sign in to play"), offline, building locked (newcomer), building hover label, resume-run prompt.
- Team Select / Run Setup (party, mode, difficulty): newcomer, locked difficulty, empty party, starting (loading), offline, server rejected start.
- Run Map: start, mid-run, boss next, node hover, locked node.
- Combat HUD: player turn, die selected with legal targets, illegal target with reason, enemy turn and intents, boss fight, turn banner, Aid tray (newcomer variant without paid Aid), Defeat panel, quit confirm.
- In-run menu (Esc): resume, settings, save and quit, abandon run (confirm).
- Reward: normal, reroll, skip. Shop: normal, bought, sold out, nothing affordable. Event: choices (rest, forge, pray and others), outcome. Treasure: closed, opened.
- Pact (after a boss): three cards, swap a card, confirm.
- Result: win, loss, new record, offline (not submitted).
- Tutorial coach overlay in combat.
- System: confirm dialog (3 variants), toast, network notice with Retry, loading skeleton, modal scrim.

**Should**
- Store: Gem packs (USD buying disabled, with reason), cosmetics, Moon Card tab, guest, offline. Moon Card popup.
- Echo Box: closed, confirm buy, opening, reveal (1 and 10), pity, rates, failed pull.
- Season Pass: normal, premium locked, season not started, offline.
- Missions and Daily: normal, locked (newcomer), in progress, claimed, offline.
- Leaderboard: loading, empty, error, own row pinned.
- Profile and Cosmetics: guest, tile states (owned, equipped, locked, seasonal).
- Vault: empty, lookup, not found, error, guest.
- Account: welcome overlay after sign-in, sync conflict ("choose a save"), errors. Settings.
- Team Presets: empty, full, delete confirm, missing Axie. Land Upgrade: affordable, not affordable.

**Could**
- Codex (with search), Guides, Unlocks.

Not in scope: Main Menu (removed), dev review tool, gamepad.

## 6. Delivery format

One folder per round: `round-a/`, `round-b/`, `round-c/`.

- `README.md`: what is in the folder, decisions taken, open questions for Liam (one page max), anything that breaks section 4, and (Round C) the guardrail checklist per screen.
- `contact-sheet.png`: every frame as a labelled thumbnail on one image.
- Round A: `a1-<name>/`, `a2-<name>/`, `a3-<name>/`, each with `style-tile.png`, four 1920×1080 frames and one 1280×720 Combat HUD frame.
- Round B: `tokens.json`, `slices.json`, `motion.md`, `components/` (one frame per component, all states), `assets/` (final names), `fonts/`.
- Round C: `screens/<screen-name>/` with `01-normal.png`, `02-<state>.png`, …, one 1280×720 frame, and `spec.md` (container tree with min sizes and size flags, token and component names, strings with max lengths and width budgets, wrap/truncate, scroll regions, anchors, focus order, Esc).
- Source (.dc.html) next to the PNGs. If the picture and the spec disagree, the spec wins, so keep them in sync.

Do not ship Round B before Liam picks in Round A, and do not ship Round C before Liam approves Round B.
