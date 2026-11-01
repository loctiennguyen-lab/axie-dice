# UI-06: kế hoạch code (Lõi, Anchor, Luật run, art mới)

Bản giao của Claude Design: `design/handoffs/ui-06-run-cards/round-1/_zip/ui06/`.
- `README.md` mục "Our notes" và "Note for Claude Code" là luật của đợt này.
- Hai file HTML: Drop A gồm 24 state, Drop B gồm 13 state, mỗi state có bản 1920 và 1280.
- `tokens.json` (`_changed_ui06`), `assets/ui6/png` (173 file, 14 MB), `moments/`, `motion-ui06.md`.
- Xem khung: chạy `preview_start ui06` (cổng 8770).

## Quyết định của Liam (1/11, chép nguyên ý vào mọi brief)
1. Hướng art **1a "Carved Material"**. Liam đã duyệt với Claude Design: bản vẽ lại lần 2, icon theo bộ icon Axie.
2. **Headline để trong file UI riêng** `godot/assets/data/ui/core_headlines.json` (id → chuỗi), không đặt trong `.tres`.
   - Tối đa **24 ký tự**. Có test chặn. Chuỗi rỗng thì ẩn dòng.
   - Writer viết, một agent cao cấp cùng chuyên môn duyệt. Không cần Liam duyệt.
3. **Anchor kích hoạt làm luôn trong UI-06.** Review (lead-programmer) cho thấy Anchor **đã phát** `core_fired` sẵn:
   - `combat_engine.gd` gọi `CoreHooks.fire(anchor_id, …)` khoảng 9 chỗ (kind rule / awaken / mana / reroll);
   - `CombatView._on_core_fired` đã nhận id `a_*`.

   Vậy UI-06 chỉ làm phần vẽ:
   - KHÔNG sửa file luật, KHÔNG tăng RULES_VERSION, không deploy Worker, run dở không bị huỷ.
   - Một vài Anchor chỉ phát cho unit đầu (Kin, Big Hand) hoặc phát tổng (blast). Giữ nguyên, UI vẽ theo uid có sẵn.
   - Muốn phát cho từng unit thì mới phải sửa luật. Hỏi Liam riêng nếu cần.
4. Badge tag: chỉ hiện `attack`, `tradeoff`, `convert_to_dmg`, `front`, `egg`.
   - Ẩn `nonattack`. `meme` không có badge.
   - `tradeoff` đứng đầu, là badge đỏ duy nhất. Tối đa 3 badge, cộng chip họ.
5. Luật cũ vẫn giữ:
   - Chỉ hiện phím Space.
   - Không chọn sẵn khi lấy/mua. Nút primary tắt thì phải nói lý do.
   - Chữ cạnh icon căn giữa theo icon.
   - Chữ ≥ 14 px thật ở 1280.
   - `data-name` = tên node.
   - Hiệu ứng (glow, chất liệu) đã nướng vào PNG nine-patch, không dùng shader.

## Làn (theo thứ tự)

### L0: Nền (làm trước, một agent `ui-programmer`; review yêu cầu thêm phần "Bổ sung theo review" ở cuối mục)
- Chép `assets/ui6/png` sang `godot/assets/ui6/`.
  - Gồm icon `_32/_64/_128`, frame/art window nine-patch, minh hoạ `_320/_640`, relic_r0–r4.
  - Chạy `--import`.
  - Đo cỡ pck tăng thêm. Quá 15 MB thì báo, có thể bỏ bản `_640`.
- Gộp token `_changed_ui06` và `_size_1280_overrides._ui06_keys` vào `tokens_ui3.json`.
  - Margin nine-patch lấy từ `ninepatch.json`.
  - Sửa test token cho khớp.
- Component dùng chung, đặt trong `scenes/shared/ui6/`:
  - `TierFrame` (NinePatchRect theo bậc), `TierCrest`, `TierShards`, `FamilyEmblem`, `TagBadges` (theo luật 4);
  - `Chipify`: số + đơn vị thành chip số, từ khoá glossary thành chip từ khoá. Regex lấy theo `gen-ui06a.js`;
  - `CoreHeadline`: đọc json, kèm test ≤ 24 ký tự.
- Nạp file headline sau khi writer xong và đã duyệt (`design/handoffs/ui-06-run-cards/headlines-draft.md`).
- **Bổ sung theo review:**
  - **Bản thử nine-patch trước:** một CoreCard tĩnh × 3 bậc ở 1920 và 1280, chụp ảnh. Margin Moss/Crystal 100 px trên thẻ 280 px ở 1280 phải không ăn hết thẻ. Chỉ khi ảnh đạt mới mở L1–L3. Trong repo chưa có NinePatchRect nào, đây là kỹ thuật mới.
  - **`CoreVisuals`** (`scenes/shared/ui6/`): tách hằng và chip khỏi `CorePanel` (AXIS_ICON, word_chip…), chốt API.
    - L1 (`RunMapOffers`) và L3 (`AnchorCard`) gọi `CoreVisuals`, không gọi `CorePanel`.
    - Sau đó L2 mới được đổi `CorePanel`.
  - **`UI6Assets`:** một chỗ trả đường dẫn emblem họ / badge / house emblem / node icon / minh hoạ / frame. Các làn không tự ghép chuỗi.
  - **`AwakenProgress`** (chip n/2 + pip + HouseTag): component chung, L1/L2/L3 chỉ gọi vào.
  - **Icon ô run map và minh hoạ:** L0 thay file tài sản (cùng tên id), không đụng code của làn.
  - Chạy suite trước và sau L0, ghi danh sách test sẽ vỡ cho từng làn (t_ui5_core_offer, t_ui5_rule_offer, t_ui5_make_room, t_ui5_shop, t_ui5_anchor_pick, token test, t_combo_*…).
  - Reduce motion và Reduce flashing là hai cờ riêng, mọi moment phải theo (`t_reduce_motion_rest`).
  - KHÔNG `git add` thư mục `_zip/`.

### L1: Chọn Lõi + Luật run (`ui-programmer`)
- Mọi state của **47-core-offer**: mặt úp (cả Crystal), 3 bậc, chọn 1 trong 4, selected, reroll, Crystal cap, combo tag, combo banner (socket), make room, house core ("+1 to awaken").
- **05-run-rule-offer**: RuleCard bảng gỗ kiểu walnut plaque.
- Moments: `offer-reveal` (nén trước khi lật, settle có lò xo), `card-interact`, `take-to-strip`. Thời gian lấy từ `motion-ui06.md`.
- File: `RunMapOffers.gd`, `run_map/ui5/CoreCard.gd`, `RuleCard.gd`, `MakeRoomSheet.gd`, `ComboBand.gd`.

### L2: Lõi đang có + kích hoạt (`ui-programmer`)
- **03-run-map**:
  - CoresPlate thành socket theo bậc, kèm emblem họ, shard nhỏ, house dot;
  - RunRuleSlot dùng con dấu;
  - tooltip Lõi và tooltip Luật.
- **02-combat**:
  - CombatCorePlate dưới RunInfo, kèm tooltip;
  - **CoreFireFX**: socket loé, đường nối tới unit, số bật lên. Nhiều lần kích hoạt cách nhau 180 ms, tối đa 6 cùng lúc;
  - **AnchorFireFX** màu vàng: `id.begins_with("a_")` thì AnchorTile loé.
- **menu--cores-owned** (RunPauseMenu): hàng Anchor 1/2, mỗi Lõi một hàng có headline + shard, hàng Luật run.
- Moments: `core-firing`.
- File (L2 sở hữu): `RunMapHud.gd`, `RunMapController.gd` (AnchorTile, awaken trên map), `combat/ui5/RunInfo.gd`, `CombatHud.gd`, `CombatView.gd` (`_on_core_fired`), `shared/CorePanel.gd`, `RunPauseMenu.gd` (kể cả hàng Anchor, dùng `AwakenProgress`), file mới `combat/ui5/CoreFireFX.gd` (+ AnchorFireFX).
- Thêm test: preview / forecast (`CoreHooks.mute`) không làm socket loé.

### L3: Drop B (`ui-programmer`)
- **48-anchor-pick** (none / picked / locked): AnchorCard mới, AwakenMeter 0/2, House Cores dạng chip có emblem + shard.
- **49-anchor-awaken**: banner moment và trạng thái sau đó.
- Tiến độ awaken dùng `AwakenProgress` của L0:
  - L3 gắn vào Anchor card và banner;
  - L1 gắn vào thẻ Lõi;
  - L2 gắn vào strip và menu.
- Icon ô run map, kèm mũ boss.
- Minh hoạ reward / treasure / event / shop: thay file trong `CardArt`. Shop Core card dùng emblem họ + shard. relic_r0–r4 mới.
- Moments: `anchor-awaken`, `map-reward`.
- File (L3 sở hữu): `shared/ui3/AnchorPick.gd`, `shared/ui3/AnchorFx.gd` (moment awaken), `run_map/ui5/AnchorCard.gd`, `ShopCoreCard.gd`, `RunMapShop/Event/Treasure.gd`, `data_models/card_art.gd`.
- KHÔNG đụng `RunMapController.gd` / `CombatView.gd` / `RunPauseMenu.gd` (của L2). Icon ô map L0 đã thay file.

### ~~R: Phát sự kiện khi Anchor kích hoạt~~: BỎ. Anchor đã phát `core_fired` sẵn (xem quyết định 3), không sửa file luật.

## Chạy và gộp
- Nhánh tích hợp `int/ui06`, tách từ `godot-port`.
- L0 xong và review xong thì mới tách L1, L2, L3 từ `int/ui06`. Ba làn này chạy song song, không đụng file của nhau.
  - Chỗ chung là HouseTag / pip / chip awaken, đã chia ở trên.
  - Mỗi làn một worktree, luật chạy như `production/polish-0111-lane-rules.md`.
- Mỗi làn: test của làn kiểm data-name có đủ không, ở cả 1920 và 1280, chữ ≥ 14 px, căn giữa. Chụp ảnh so với frame. Review độc lập rồi mới gộp.
- Sau khi gộp đủ: suite đủ `AXIE_RELEASE=1` (`AXIE_HANG_KILL=2400`, vì suite giờ chạy > 1200 s), Worker test.
- QA luồng thật: một run từ chọn Anchor tới boss, xem Lõi và Anchor kích hoạt. Soak có `--verify`.
- Deploy: web + desktop. Không đổi Worker, run dở không bị huỷ. Hỏi Liam trước khi deploy.

## Ước lượng
L0 khoảng 1 làn. L1, L2, L3 mỗi làn 1–2 lượt agent. R nhỏ. Cộng tích hợp, QA, deploy. Nhanh nhất là L1–L3 song song sau L0.

## Câu hỏi còn mở
- Pck tăng khoảng 14 MB nếu giữ đủ PNG `_640`. Có chấp nhận không (giới hạn web +60 MB đã chốt cho quái Atia)? Mặc định: giữ, đo thật rồi báo.
