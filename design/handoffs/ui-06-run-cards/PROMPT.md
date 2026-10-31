# UI-06 (Lõi, Anchor, Luật run + art thay AI): prompt cho Claude Design

**Cho Liam:** dán phần dưới dòng `---` vào cùng project Claude Design đã làm UI-05, đính kèm
`AxieDice-UI06-inputs.zip`. Zip do Claude Code dựng sau khi anh duyệt prompt này. Gồm:
- bản UI-05 đợt 2 đã chốt (`round-2/`: html, tokens, build, README);
- `game-data-cores.md`: 6 Anchor, 67 Lõi, 17 Luật run thật, lấy từ data; không lấy `c_test_*`; có sẵn 10 Lõi mẫu đủ họ và bậc;
- `screens-current/`: ảnh các màn hiện tại, chụp lại với data thật;
- `art-to-replace/`: art cần thay;
- `axie-reference/`: art Axie chính thức từ `asset-library/design-library/`;
- `art-bible-extract.md`: mục 4 (màu), "Dấu hiệu AI cần loại", "Cách tạo ảnh đúng chất" của art bible, dịch sang tiếng Anh.

Quyết định của Liam (1/11) đã ghi vào prompt:
- phạm vi gồm Anchor pick + Awaken, Core offer, Run rule offer, Lõi đang có trong run, cộng art đang lộ AI (art lúc chọn Lõi, hình thẻ thưởng, hình độ hiếm, icon ô run map);
- được làm lại thiết kế thẻ;
- icon vẽ theo nhóm, không vẽ riêng từng Lõi;
- art theo phong cách Axie chính thức;
- tham chiếu: LoL Arena, Balatro, Hades, Slay the Spire;
- có motion spec.

---

UI-05 is in the game and the owner is happy with it. Thank you. This round is narrower. It covers the **build layer of a run**: the cards you pick (Anchors, Cores, Run Rules), how the ones you own show up during the run, and the art on and around them. You may **redesign the cards and the pick screens**. The rules, the data and the flow of the run stay as they are.

## What the owner doesn't like today
1. **No thrill, and rarity doesn't land.** Picking a Core should feel like opening a pack. Moss → Amber → Crystal is a small chip today. A Crystal card should look and feel rare before you read a word.
2. **Hard to read and hard to compare.** The effect is a block of text. With 3–4 cards side by side you can't tell quickly which one you want.
3. **No identity.** Every Core gets a generic glyph (egg, arrow, bolt), so cards blur together.
4. **You can't see a Core doing anything.** In a fight, when a Core or an Anchor fires, the player barely notices. PAIR/FULL combos and Anchor awaken progress (2 of 5 House Cores) aren't clear either.
5. **Some art looks AI-made**, and he wants all of it replaced:
   - the art at the top of each Core offer card;
   - the reward and shop illustrations;
   - the rarity pictures;
   - the run-map node icons.

## References (take the idea, not the look)
- **LoL Arena augments:** the tier reads instantly from the frame (silver / gold / prismatic). The text is short. Each card has its own reroll, and our game already works that way.
- **Balatro:** cards have personality. They wobble and shake, and numbers pop when something triggers. It feels good.
- **Hades boons:** each family has one colour and one emblem. The frame follows the rarity. One short headline, then the detail.
- **Slay the Spire relics:** owned relics sit as a row of small icons that flash when they fire. The tooltip is clear.

## Art direction: official Axie style
- Match the official Axie / Lunacia art in `axie-reference/`:
  - round, warm and bright shapes;
  - big flat colour areas with 2–3 tone steps;
  - a thin outline in a darker shade of the same colour, never pure black;
  - one light from the top-left;
  - a soft contact shadow.
- **Never draw an Axie or a creature yourself.** If a picture needs one, leave a slot and name the render you need. We render it from the real 3D model.
- Emblems and icons are hand-built vector in 3 layers (base, symbol, highlight).
- Painted texture is fine only inside frames and backgrounds.
- Every picture must pass the 12 checks in `art-bible-extract.md`:
  - no plastic gloss;
  - no fake text;
  - no muddy gradient;
  - no uneven outline;
  - no halo around cut-outs;
  - and the rest of the list.
- **Palette = art bible section 4.**
  - Cream `#FFE9C2` is the lightest colour and dark brown `#24140B` is the darkest. Never use `#FFFFFF` or `#000000`.
  - Plates are warm brown (`#3A2418`–`#24140B`), never navy or grey.
  - Rarity colours: Moss `#7DAA48` (rough wood and moss, matte), Amber `#F2A33A` (clear resin with bubbles), Crystal `#7FB6F0` (cut crystal, glossy).
  - Crystal is the only place the game uses cold light to say "rare".
- **Rarity must read without colour too:** in greyscale and by shape, for example 1/2/3 shards plus a rough / rounded / faceted frame. Colour alone is never enough.
- Frames may carry texture, shine or a glow. Our UI rule is flat StyleBox with hard shadows, and no CSS blur, gradient, mask or shader. So draw those effects **into the frame image** (nine-patch PNG or SVG) and list each one as an asset.
- **Colour rules:**
  - Family colours must not be violet, red, or any of the 6 Axie class hues. Pair each family colour with its emblem and shape.
  - Gem violet means paid surfaces only.
  - Red means danger only. A tradeoff Core may use red on its cost text or chip, never on the frame.

## Icons: one set per family, not one per Core
- **7 family emblems:**
  - 6 Core families, from `core_axis`: `stat`, `dice`, `pos` (position), `mana`, `quest`, `rule`;
  - plus **Run Rule**. It is a separate card type (17 of them), with its own look next to the Cores.
- **Small badges** for the tags that change how you play: `attack`, `nonattack`, `tradeoff`, `convert_to_dmg`, `front`, `egg`. `meme` (3 joke Cores) is your call: a badge, or nothing.
- **6 Anchor house emblems:** `volley`, `gambler`, `mana_mine`, `kin`, `embers`, `big_hand`. These are all the Anchors in the game. Redraw them in the new style; today's versions are in `art-to-replace/houses/`.
- **Run-map node icons:** battle, elite, boss, shop, event, treasure (`art-to-replace/map-icons/node_*`).
- **Reward / shop / overlay illustrations** (`art-to-replace/cards/`):
  - rewards: `card_level`, `card_ascend`, `card_hp`, `card_reroll`, `card_chaos`, `card_curse`, `card_relic`;
  - shop: `shop_heal`, `shop_relic` (the Core pick in the shop uses it too);
  - the big art on the event and treasure overlays: `node_event`, `node_treasure`. These are different files from the small map icons of the same name.
- **Rarity pictures** `relic_r0`–`r4`: the shop shows one by item rarity 0–4 (Common → Legendary). If your new frames carry rarity well enough, say they replace these. Otherwise redraw them.

## Text: make it scannable without hand-writing 67 cards
- Card text comes from data (`UI3.describe()`).
  - Anchors already have a short tagline, then Rule, then Awakens.
  - Cores have one description.
- Propose a structure that works for any Core. For example:
  - a short headline: max ~28 characters, one line at 1280;
  - the detail;
  - numbers and keywords (SET, Cracked, Held, Overcast, Temp Face) shown as styled chips or glyphs.
- Show it on the 10 sample Cores marked in `game-data-cores.md`.
- If a headline field is needed, say so. We'll add it to the data and write the copy. Don't invent effects.
- What a Core does is shown two ways only: by its card (headline + chips), and by a firing moment in combat. Don't invent a new tracking system.

## Scope (every state at 1920×1080 and the same at 1280×720)
- **47-core-offer:**
  - face-down;
  - revealed for each tier;
  - 3 cards and pick 1 of 4;
  - one selected;
  - reroll used / none left;
  - the Crystal cap warning;
  - PAIR/FULL combo tags;
  - the combo banner after Take;
  - the "Make room" sheet at 6 of 6;
  - a Core that is a House Core of your Anchor (show "+1 to awaken").
- **48-anchor-pick:** none picked, picked, one card locked ("Unlocks at stage N").
- **49-anchor-awaken:** the moment and the screen after it. Also show awaken progress wherever House Cores show.
- **05-run-rule-offer:** offer, picked. Also the rule tile on the run map.
- **Owned Cores during the run:**
  - the Cores strip on the run map and in combat;
  - the "Cores owned" panel in the in-run menu;
  - the tooltip;
  - **a Core firing in combat**, with an Anchor firing as a variant.
  - The game already sends one event per real firing: `core_fired(core_id, unit, amount, kind)`. So you can point at the **unit** it affected and show the **number**. It does not say which die. Anything that needs the die is a PROPOSAL.
- **The new art in place** on its screens: reward cards, shop, map, treasure, event.

## Motion (prototype + timing table, as in UI-05)
- Offer reveal: face-down → flip. The bigger the tier, the bigger the moment; a Crystal reveal should be the peak.
- Hover, select, reroll one card.
- Take → the Core flies into the Cores strip.
- A Core firing in combat: the icon in the strip flashes, a line or pulse goes to the unit, and the number pops.
- Anchor awaken.
- Every moment needs a reduced version for Settings → Reduce motion / Reduce flashing. Use durations and easing we can copy into `motion_ui3.json`.

## Rules carried over from UI-05 (still apply)
- Style A "Toy Wood" tokens from `round-2/tokens.json`. New or changed keys go in marked "UI-06".
- Type sizes come only from the tokens: 16 / 18 / 24 / 32, plus 36 for banners and 56 hero. No 20 or 22.
- Fonts: Rowdies 700 and Work Sans 400. Never mix the two in one label.
- 1280: no text under 14 px. Where 14 px doesn't fit, add a px value under `_size_1280_overrides`.
- Tap targets are at least 44 px. Use the 8 px grid and 24 px screen margins. Each panel has one background.
- The only keycap shown is Space, on the one primary action.
- Nothing preselected when you pick something to take or buy. The primary stays disabled and says why.
- Text under or beside an icon is centred on the icon.
- Each screen has 1 primary and at most 2 secondary buttons.
- `data-name` = Godot node name. Put `aria-label` with the same PascalCase name on every element that has a `data-name`. Keep `<!-- godot: … -->` comments.
- Use the real names, tiers and numbers from `game-data-cores.md`. Some old captures show "Core 1 / A sample rule…". That is test data, not copy.
- Don't invent mechanics. If an idea needs a rule change, mark it **PROPOSAL**.

## Please work in three steps
1. **Probe.** Send 2 directions on a small set:
   - one Core card per tier;
   - one Run Rule card;
   - one Anchor card;
   - one owned-Core strip with a firing moment;
   - two map node icons;
   - one reward illustration.

   The owner picks one direction before you go on.
2. **Drop A:**
   - Core offer (all states);
   - Run Rule offer and map tile;
   - owned Cores (strip, panel, tooltip, firing);
   - the 7 family emblems and badges;
   - the rarity frames;
   - their motion.
3. **Drop B:**
   - Anchor pick and awaken;
   - the 6 house emblems;
   - map node icons;
   - reward / shop / overlay illustrations;
   - rarity pictures;
   - their motion.

## What to send back (each drop)
- `ui06-run-cards.html`, `tokens.json` (UI-06 keys marked), `assets/`:
  - icons as SVG, plus PNG at 32 / 64 / 128;
  - frames as nine-patch PNG with their margins listed;
  - illustrations as PNG at 320 and 640.
- `moments/` and `motion-ui06.md`.
- `build/`.
- A README with:
  - what changed per screen;
  - new tokens and components;
  - an asset table: file → game id (family, house id, node kind, reward type);
  - the renders you need from us;
  - the text structure rule and the 10 examples;
  - flags and proposals.
