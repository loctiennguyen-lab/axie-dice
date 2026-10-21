# Anchor MVP: spec UI (chọn Anchor, nhà, đột biến Cặp, Thức tỉnh)

Ngày 21/10/2026. Bản nháp cho Liam duyệt, rồi giao ui-programmer. Chưa sửa code, chưa commit.
Nguồn luật: `design/proposals/mutation-and-keystones-v1.md` (mục 2, 3, "Liam chốt 23/10"). Nhịp + khung gacha: `production/gacha-contract.md`
(GachaReveal / GachaFx / banner Cặp-Đủ). Luật UI: `godot/CLAUDE.md`. Chữ trong game là tiếng Anh, qua `tr()`; câu luật lấy từ data qua
`UI3.describe()`, không ghép tay, và **không chép số vào text**: số nấc 1 / nấc 2 lấy từ data (số còn chờ sim chỉnh).

Phản hồi gốc của Liam: game "rời rạc, thiếu đột biến khi ráp combo Lõi đặc biệt". Hai việc UI phải làm:
1. Người chơi **thấy build đang thành hình** (Anchor + nhà + x/2 ở một chỗ cố định, nhìn là biết).
2. Khoảnh khắc thức tỉnh **to và khác hẳn** banner combo, nhưng HUD không phình ra.

## 0. Nguyên tắc và ngân sách HUD

- HUD thường trực chỉ thêm **2 thứ**: ô Anchor và chip "House Cores x/2" (mục 2). Không thanh tiến độ, không panel mới.
- Mọi thứ còn lại là **sự kiện** (hiện rồi tắt): banner lúc ráp, popup lần đầu trong trận, float khi tác động.
- Ba lớp độ to, không lẫn nhau:

| Lớp | Là gì | Độ to | Chặn input? |
|---|---|---|---|
| Combo / Cặp thường | banner hiện có | panel giữa, scrim 55%, 1.6 s (Cặp) / 2.8 s (Đủ) | click-through |
| Đột biến Cặp | thêm 1 dòng vào banner Cặp, trong trận là banner nhỏ + float | như dòng trên | không |
| **Thức tỉnh** | full-screen moment | scrim 80%, thẻ Anchor 3x giữa màn, vòng sóng, rung, âm riêng, ≤2.5 s | có, bấm là bỏ qua |

- Màu mã hoá cơ chế thì luôn kèm glyph + chữ. Nhà = glyph + tên nhà; không có nhà nào nhận biết chỉ bằng màu.
- Không violet cho thức tỉnh: violet chỉ dành cho bề mặt trả tiền (luật toàn cục). "Vàng" là hướng của spec này, token do art-director chốt.
- Không blur, gradient, shader, mask. Vòng sóng / mảnh vỡ là Line2D + hình phẳng, giống jackpot của GachaFx.

### Token / asset cần thêm (không dựng tại chỗ, thêm vào `tokens_ui3.json` + `UI3.gd`)

- Màu nhà + thức tỉnh: **đã chốt và đã thêm vào `tokens_ui3.json`** (art-director, 21/10). Tương phản đo trên `plate`, đều >= 6.2:1. Màu chỉ để viền/khung/chip; nhà luôn đọc bằng glyph + tên.

| Token | Hex | Nhà / dùng | Tương phản | Glyph tạm (file thật, `assets/ui3/icons/`) |
|---|---|---|---|---|
| `house_volley` | `#7f9cff` | Volley, xanh periwinkle | 6.2 | `face_shield.png` |
| `house_gambler` | `#ff8cc8` | Gambler, hồng | 7.5 | `node_event.png` |
| `house_mana_mine` | `#9be8c8` | Mana Mine, mint nhạt | 11.3 | `face_mana.svg` |
| `house_kin` | `#a9c4a0` | Kin, xanh sage | 8.5 | `face_heal.png` |
| `house_embers` | `#ff8a6b` | Embers, coral (không đỏ: đỏ = danger) | 7.0 | `face_dmg.png` |
| `house_big_hand` | `#c8a27a` | Big Hand, tan | 6.8 | `face_summon.png` |
| `anchor_awake` | `#ffd21f` | thức tỉnh, vàng chanh | 11.1 | `ui_awaken` = tạm `face_buff.svg` |

  Phân biệt: không nhà nào trùng hue với `rarity_*` (mint nhạt và sage thấp bão hoà, sáng hơn `rarity_rare`; coral đỏ-cam hơn `face_buff`). `anchor_awake` vàng hơn và bão hoà hơn
  `rarity_legendary`/`accent` (#ffb444) và `egg`/cream, nhưng hue gần nên **không bao giờ đứng một mình**: luôn khung đôi hoặc `ui_awaken` + chữ "Awakened". Mù màu: glyph + tên đọc được dù
  mọi nhà thành một màu. Không dùng violet.
  Glyph tạm là icon mặt xúc xắc / node, **nghĩa cũ khác** (face_shield = mặt Khiên...): chỉ để chạy được, phải thay bằng icon thật. Cần vẽ (SVG đơn sắc, lưới 64, nét >= 4,
  đọc được ở 16 px, tô bằng token): Volley = ba mũi tên bay cong; Gambler = viên xúc xắc có vết nứt; Mana Mine = cuốc chim trên tinh thể; Kin = nhà/mái che có ba nấc người;
  Embers = than hồng có tia lửa; Big Hand = bàn tay mở bốn ngón; `ui_awaken` = sao bốn cánh trong vòng tròn.
- Component mới trong `UI3.gd`: `anchor_card()`, `house_chip()`, `awaken_mark()`. Node mới `AnchorFx` (cạnh `GachaFx`, `scenes/shared/ui3/`) cho moment thức tỉnh.
- Knob nhịp thêm vào `gacha_timing.json` (không phải file luật): `anchor_flip_*`, `awaken_total_sec` 2.5, `awaken_reduced_sec` 1.6, `mutation_fire_sec` 1.0.

## 1. Màn chọn Anchor (đầu run)

### 1.1 Khi nào

- `MetaState.depth_stage() >= 3`, sau chọn đội và Luật run, **trước** lượt chọn Lõi đầu. Overlay chạy trong cùng host với overlay chọn Lõi
  (`RunMapController`), không phải màn riêng.
- `depth_stage() < 3`: không có overlay, không có ô Anchor, không có chip, không có tab Anchors trong Codex. Người mới không biết nó tồn tại.
- Tài khoản cũ vào thẳng stage 3: thấy overlay ngay run đầu, kèm **một** coach (V4Coach, một lần):
  "Your Anchor shapes the whole run. Hold 2 of its House Cores to awaken it."
- Thoát giữa chừng (đóng game khi overlay mở): mở lại thì overlay hiện lại, vì Anchor chưa chọn = chưa có action. Không cho đi tiếp mà thiếu Anchor.

### 1.2 Bố cục (canvas 1920x1080, lề 24, lưới 8)

```
 y~96   [Choose your Anchor]                         (32, giữa)
 y~144  [This choice lasts the whole run. No reroll.] (18, giữa)

 y 200  +-----------+  +-----------+  +-----------+     3 thẻ 480x560, khe 48 (tổng 1536, căn giữa)
        |  Anchor A |  |  Anchor B |  |  Anchor C |
        +-----------+  +-----------+  +-----------+

 y~880          [ Take <Name> ]  (primary 320x56, giữa)
 y~944   lý do disabled / gợi ý (18)
```

Không có nút Skip, không Reroll (Liam chốt: không reroll; đây là quyết định định hình run, không bỏ qua được). Đúng 1 primary, 0 secondary.
Esc = mở menu in-run (như run map), không đóng overlay.

### 1.3 Một thẻ Anchor (480 rộng, đệm 24, nội dung 432)

Từ trên xuống:

1. Hàng đầu: glyph nhà 64 + **tên Anchor** (32, ví dụ "Volley"). Dưới tên: nhãn nhà "House: Volley" 18.
2. `RULE` (18, mờ) rồi **một câu luật** (24, tối đa 3 dòng). Đây là phần gain.
3. `PRICE` (18, mờ) rồi một dòng giá (24), chip có ký tự "−" đứng trước (giá là đánh đổi, **không dùng đỏ**: đỏ chỉ cho danger).
   Phần gain dùng ký tự "+" ở dòng RULE nếu câu luật cần. Cả hai phải đọc được khi không có màu.
4. `AWAKENS` (18, mờ): tên luật thức tỉnh (24) + **câu luật đầy đủ một câu (18, tối đa 2 dòng)** + "Hold 2 House Cores" (18). Liam chốt: thẻ hiện đủ luật thức tỉnh (xem mục Chốt).
   Thẻ cao thêm ~44 so với bản chỉ-tên: kiểm lại vừa 560, không thì rút chữ.
5. Hàng "House Cores": 5 icon Lõi ruột 48x48, độ mờ 55% (vẫn đọc được tên qua tooltip, không phải trang trí), nhãn 18 "House Cores" bên dưới.
   Rê / focus vào icon: `UI3Tooltip` tên Lõi + một dòng tác dụng của Lõi đó. Vùng bấm/hover mỗi icon 48 >= 44.
   Không bậc/độ hiếm trên icon (không lộ bậc).

Chữ MVP đề xuất (rule một câu, giá, thức tỉnh; Liam duyệt, số lấy từ data):

| Anchor | RULE | PRICE | AWAKENS |
|---|---|---|---|
| Volley | Once a turn, your Set of 3+ also bursts: every enemy takes part of its damage. | Set bonus −0.15 | Thorn Storm |
| Gambler | Clean Gamble (2+ dice, none Cracked): every Set gets a bonus this turn. | Crack chance goes up | Redo Hand |
| Mana Mine | First turn with a natural Set: +1 mana, and Overcast costs 1. | Wild face costs 3 mana | Double Tempo |

Thẻ cao 560: 72 + 16 + 122 + 16 + 56 + 16 + 56 + 16 + 74 = 444 + đệm 48 = 492, còn dư 68 để thở. Nếu câu luật dịch ra dài hơn 3 dòng thì rút chữ, **không** cắt (một dòng bị cắt không có scroll là lỗi nặng nhất).

### 1.4 Trạng thái và tương tác

| Trạng thái | Hiện | Ghi chú |
|---|---|---|
| Úp (đang lật) | mặt sau thẻ (icon trăng như thẻ Lõi) | không bấm được |
| Mặc định | viền thường | |
| Hover / focus | nổi 1.04 (như thẻ Tinh Thể), focus = vòng amber 2 px cách 4 px | |
| Đã chọn | viền cream 4 px | chọn lại thẻ khác thì bỏ thẻ cũ; **bấm lần nữa vào thẻ đã chọn không bỏ chọn** (tránh chọn hụt) |
| Primary khi chưa chọn | disabled, lý do dưới nút: "Pick one Anchor." | |
| Primary khi đã chọn | "Take Volley" | bấm = nhận, đóng overlay, action `pick_keystone` ghi vào log (làn engine) |

Input:
- Chuột: bấm thẻ = chọn, bấm primary = nhận. Không kéo thả.
- Bàn phím: Trái/Phải = focus giữa 3 thẻ, `1` `2` `3` chọn thẳng, Enter/Space = chọn thẻ đang focus; Tab đưa focus xuống primary, Enter = nhận.
- Gamepad: D-pad trái/phải focus, A = chọn rồi A trên primary = nhận. Không có nút B (không có gì để huỷ).
- Một lần bấm hụt không mất gì: chọn chỉ là đánh dấu, nhận mới là chốt.

### 1.5 Nhịp lật kiểu gacha (dùng lại `GachaReveal`, không viết lại)

Anchor **không có bậc ngẫu nhiên** (MVP cả 3 luôn hiện), nên không có quầng bậc / near-miss / jackpot. Nhịp chỉ để tạo trọng lượng cho một quyết định lớn:

| Bước | Thời gian |
|---|---|
| 3 thẻ úp hiện, quầng trung tính (cream) | 0.9 s lần đầu thấy trong tài khoản/run đầu; 0.4 s các lần sau |
| Lật trái → phải, lệch 180 ms, mỗi lật 0.35 s | tổng ~0.9 s |
| Sau khi thẻ cuối lật xong | mới bấm được |

Bấm chuột / Space / Enter bất kỳ lúc nào = tua hết, **và lần bấm tua không đồng thời là lần chọn thẻ** (phải bấm lần hai mới chọn).
Reduce flashing: bỏ pulse quầng + rung, chỉ còn lật. Âm: `ui_modal_open` khi overlay hiện, `ui_tap` mỗi lật (tạm, audio-director chốt).

### 1.6 Sau khi nhận

Overlay đóng; thẻ Anchor nhỏ lại bay vào ô Anchor trên HUD/Core panel (0.3 s, nếu panel đang hiện; không thì mờ dần). Sang luôn lượt chọn Lõi đầu (bình thường, có
ít nhất một thẻ Lõi ruột theo luật `ks_seed_pick`).

## 2. HUD: Anchor và tiến độ nhà

### 2.1 Ô Anchor (gắn vào CorePanel)

- Ở **đầu trái hàng `CoreSlots`** của `CorePanel` (thay vì panel mới), kích thước 56 (các ô Lõi 44), kèm vạch ngăn mảnh với 6 ô Lõi + 1 ô Luật run. Giữ nguyên `slot_px` của các ô khác.
- Ô gồm: khung theo màu nhà + glyph nhà ở giữa. Rê/focus: tooltip với tên, luật nền, giá, "Awakens: <tên>", "House Cores x/2" và danh sách 5 Lõi ruột
  (cái đã có đánh dấu "Owned"). Vùng hover 56 >= 44.
- Trong trận (`show_counts`): ô Anchor có chip "xN" đếm số lần luật nền/thức tỉnh đã tác động trong trận này, dùng lại cơ chế `_fires` của CorePanel.

### 2.2 Chip "House Cores x/2"

- **Chống quá tải HUD (art-director)**: ngoài trận (run map, màn chọn Lõi) giữ chip một dòng như dưới. **Trong trận không có hàng chip**: `x/2` thành badge góc dưới phải của ô Anchor
  (18, nền `panel_raised`), cột Lõi đã có Giáp/affix/nhịp boss. Cùng góc đó: chưa thức tỉnh = `x/2`, đã thức tỉnh = `xN` (số lần tác động); không bao giờ hai badge cùng lúc. Đã thức tỉnh thì chip ngoài trận cũng bỏ.
- Dưới hàng slot, một chip một dòng, 18, cao 32 (chỉ thông tin, không bấm; mọi tooltip nằm ở ô Anchor): `[glyph nhà] House Cores 1/2`.
- Giá trị `x` = số Lõi ruột đang giữ (đếm từ Lõi sở hữu, không lưu state). `0/2` vẫn hiện (cho biết đang săn cái gì).
- Khi đủ 2/2 và thức tỉnh: chip đổi thành `[ui_awaken] Awakened` khung `anchor_awake`, hết đếm. Đó là trạng thái "sáng".
- **Đã chốt (Chốt 4): thức tỉnh khoá tới hết run**, mất Lõi ruột cũng không tắt: không có toast "sleeps", không có đường quay về chưa thức tỉnh. Cờ thức tỉnh lưu theo run, không tính lại từ Lõi đang giữ.
- Combat HUD: chip nằm trong cột Lõi như hiện nay, **không thêm hàng thứ hai**. Nếu 1280x720 chật: chip rút còn `[glyph] 1/2`, chữ "House Cores" vào tooltip.

### 2.3 Lõi ruột trong panel Lõi

- Ô Lõi thuộc nhà Anchor đang giữ có **viền nhà ngoài**: vòng 3 px màu nhà, cách viền bậc 2 px (viền bậc `rarity_*` giữ nguyên vì "màu bậc" đã là cơ chế khác),
  cộng glyph nhà 16 ở góc dưới phải. Tức là **không** dựa vào màu viền để biết nhà: glyph góc mới là dấu chính.
- Hover: tooltip Lõi thêm dòng "House Core of Volley".
- Ô Lõi không thuộc nhà: không thêm gì (HUD sạch).

### 2.4 Trên màn chọn Lõi (thẻ Lõi)

- Thẻ Lõi ruột có chip trong hàng chip hiện có (cùng hàng "With: X, Y" và nhãn PAIR/FULL): `[glyph nhà] House`.
- Nếu nhận thẻ này làm tổng House Cores lên 2 (tức làm thức tỉnh): chip đổi thành `[glyph nhà] 1/2 → AWAKEN`, khung `anchor_awake`, tên chip 18.
  Giá trị bên trái mũi tên là số đang giữ, không bao giờ là số khác 1 vì đúng 1 thẻ nữa thì mới thức tỉnh.
- Không bao giờ ghi gì về bậc lần chọn kế (hợp đồng gacha không đổi).
- Thẻ vừa làm Cặp vừa làm thức tỉnh: cả nhãn "PAIR! <tên>" và chip "→ AWAKEN" hiện cùng nhau. Thẻ có thể phải dùng 3 hàng chip; thẻ vẫn phải vừa khít, hàng chip xuống dòng chứ không cắt.
- Thẻ hiện "→ AWAKEN" được nổi viền `anchor_awake` 2 px để nhìn ra giữa 3 thẻ (người chơi thấy đây là thẻ "đột biến" trước khi bấm).

## 3. Đột biến Cặp

### 3.1 Lúc ráp (màn chọn Lõi)

Giữ nguyên banner PAIR hiện có (panel giữa, glyph trăng 2, nhãn vàng PAIR, tên combo 32, icon 2 Lõi, 1.6 s). Thêm **dòng đột biến** bên dưới trong cùng panel:

```
[house glyph 24]  MUTATION  <Tên đột biến>        (nhãn 18 + tên 24)
<câu luật một dòng, 18-24>
```

- Panel tự cao thêm một dải 64; thời gian Cặp tăng từ 1.6 lên **2.0 s** (knob), vẫn click-through, vẫn bấm/Space bỏ qua.
- Đủ (FULL): cùng dòng đột biến nhưng ghi "level 2" bằng chữ ("MUTATION · LEVEL 2", không bằng màu). Combo jackpot: vào thẳng level 2.
- Stage 2 (chưa có Anchor): dòng đột biến vẫn hiện (đột biến Cặp mở từ stage 2). Glyph nhà hiện, không hiện chip x/2, không nói gì về Anchor.
- Nếu lần nhận này đồng thời thức tỉnh: **gộp vào moment thức tỉnh** (mục 4), không chiếu hai thứ nối tiếp. Dải đột biến nằm trong moment.

Chữ đề xuất (mỗi nhà một cái; số lấy từ data; Liam duyệt):

| Nhà (glyph) | Tên | Câu luật |
|---|---|---|
| Volley | Thorn Rebound | A third of your Set's Shield turns into Thorns until enemies finish. |
| Gambler | Crack Mana | First Cracked die each turn gives you mana. |
| Mana Mine | Mana Overflow | End your turn with 3+ mana: spend 1, every enemy takes damage. |
| Kin | Shelter | First Set each turn: your weakest front Axie gains Shield. |
| Embers | Last Strike | Your last die hits harder if it is part of a Set. |
| Big Hand | Hunt Four | With a Set of 3, your first Safe reroll each turn is free. |

(Nhà Kin, Embers, Big Hand chưa có Anchor trong MVP nhưng đột biến Cặp của chúng có từ MVP; chỉ banner, chưa chip x/2.)

### 3.2 Trong trận: thấy đột biến tác động

Hai cấp, để không rối:

- **Lần đầu mỗi trận**: banner nhỏ top-centre cùng chỗ banner combo (32, y 120), nhưng khác combo ở 3 chỗ: glyph **nhà** (không phải trăng), nhãn 18 "MUTATION", khung 1 nét theo màu nhà. 1.0 s, không chặn input. Hai banner (combo + đột biến) xếp dọc như quy tắc hai combo (tối đa 2 banner cùng lúc; vượt thì cái sau xuống thành float).
- **Các lần sau** (và mọi lần khi đã có banner): float 24 gần chỗ nó đổi, glyph nhà + tên ngắn, ~0.8 s, và hai ô Lõi của Cặp sáng (dùng `flash_combo`). Mỗi tên đột biến tối đa **một float mỗi lượt**; lần thứ hai trở đi trong lượt gộp thành "x2" trên float có sẵn.

| Đột biến | Hiệu ứng nhìn thấy | Float (24) |
|---|---|---|
| Thorn Rebound | một phần số Khiên trên Axie đổi sang số Gai (số Khiên giảm, số Gai hiện), quái đánh vào thì Gai bật số | "Shield → Thorns" cạnh Axie |
| Crack Mana | giọt mana bay từ viên Nứt vào thanh mana | "+N mana" cạnh thanh mana |
| Mana Overflow | sóng ngang quét qua hàng quái, mỗi quái nhận số | "Overflow" giữa hàng quái |
| Shelter | Khiên bay từ BỘ sang Axie hàng trước nhận | "Shelter" trên Axie nhận |
| Last Strike | dấu "LAST" đóng lên viên cuối, số đòn to hơn | "Last Strike" trên viên |
| Hunt Four | nút Safe hiện "0 mana" kèm glyph nhà trong lượt có hiệu lực | giá trên nút, không float |

Reduce flashing: bỏ sóng/giọt bay, chỉ còn số + float mờ vào.

## 4. THỨC TỉNH

### 4.1 Điều kiện hiện

- Chuyển trạng thái "chưa thức tỉnh → đã thức tỉnh" (số House Cores đang giữ chạm 2; sau đó khoá, xem 2.2) lúc nhận Lõi từ **bất kỳ nguồn nào** (chọn Lõi, shop, sự kiện, treasure).
  Moment chiếu **một lần mỗi run** (cờ "đã chiếu" theo run, cùng cơ chế `first_seen` của `UI3Gacha`; mở lại run đang dở không chiếu lại).
- Nhận Lõi lúc đang trong trận (nếu có đường): xếp hàng, chiếu ngay khi trận xong, trước màn kế.
- Thức tỉnh bằng thẻ vừa làm Cặp: một moment duy nhất, có dải "PAIR: <tên combo> · MUTATION: <tên>" ở dưới.

### 4.2 Dòng thời gian (tổng ≤ 2.5 s, 1920x1080)

| t (s) | Việc |
|---|---|
| 0.00 | Scrim neutral-1 @80% hiện 0.15 s, chặn input. Hit-stop 0.1 s (mọi tween nền đứng). |
| 0.10 | Thẻ Anchor (đúng thẻ vừa chọn đầu run, 280x280 phần khung) xuất hiện giữa màn từ 0.6x lên 1.0x, vượt 1.1x rồi về 1.0x trong 0.4 s. Khung thường (1 nét) hiện. |
| 0.50 | **Khung đổi**: thành khung đôi `anchor_awake` (2 nét, phẳng), glyph `ui_awaken` đóng lên góc. Hai vòng sóng Line2D 4 px (màu nhà rồi vàng), bán kính 0 → 900, 0.6 s. Rung màn 10 px 0.25 s. 12 mảnh hình vuông phẳng bắn ra. |
| 0.60 | Nhãn "ANCHOR AWAKENED" (24) lên trên thẻ. |
| 0.90 | Tên luật thức tỉnh (32, ví dụ "Thorn Storm") dưới thẻ, rồi câu luật một dòng (24) ở 1.1 s. |
| 1.30 | Dải dưới (18): "House Cores 2/2". Nếu gộp Cặp: dải "PAIR: <tên combo> · MUTATION: <tên>" (24) ở 1.3 s. |
| 2.20 | Giữ. Hết 2.2 s thì thẻ nhỏ lại bay về ô Anchor trên HUD (0.3 s, nếu không thấy ô thì mờ dần), scrim tắt. |
| 2.50 | Xong. |

- **Bấm chuột / Space / Enter / A / Esc bất kỳ lúc nào = nhảy tới trạng thái cuối** (thẻ bay về HUD luôn). Esc dùng để bỏ qua, **không** mở menu in-run trong lúc moment chạy.
- Hiển thị tất cả trong khung 1920x1080; 1280x720 scale đều, không đổi bố cục. Mọi chữ <= 32; "to" đến từ thẻ 3x, scrim 80%, vòng, rung và âm, không phải cỡ chữ (36 chỉ cho banner lượt).
- Review art-director: đủ khác FULL, với điều kiện giữ 3 thứ không được rớt khi implement: (a) khung đôi `anchor_awake` + `ui_awaken` (vì vàng gần FULL, hình dáng là thứ phân biệt), (b) chặn input + thẻ 3x, (c) trạng thái
  ở lại trên HUD. Không dùng chữ "FULL"/sao FULL trong moment. Vòng sóng đầu màu nhà, vòng sau `anchor_awake`, để màu nhà cũng góp vào.
- Khác FULL ở đâu (để Liam thấy nó không phải "banner lớn hơn"): FULL = panel ở giữa trên scrim 55%, 2.8 s, click-through, nhãn "FULL". Thức tỉnh = chiếm cả màn, chặn input,
  thẻ Anchor tự là nhân vật chính, có vòng + rung, và **kết quả ở lại** trên HUD (ô Anchor đổi khung vĩnh viễn).
- Reduce flashing: không rung, không vòng sóng, không mảnh bắn, không hit-stop. Thẻ hiện, khung đổi bằng fade 0.3 s, chữ lên fade. Tổng **1.6 s**, vẫn bấm bỏ qua được.

### 4.3 Âm

- FULL đã dùng `axie_level_up` + `talent_capstone_unlock` (`gacha_timing.json` mục `full`). Dùng hai file đó cho thức tỉnh thì Đủ và thức tỉnh nghe giống nhau, mất ý "khác hẳn".
- Đề xuất (chưa nghe thử, audio-director chốt): `asset-library/audio/mygame-sfx/city_hall_upgrade_complete.ogg` (đòn chính, vào ở t 0.50, -2 dB)
  + `talent_capstone_unlock.ogg` ở t 0.70 (-5 dB, làm đuôi) + `direct_burn_ritual.ogg` -10 dB ở t 0.10 làm tiếng "đè" lúc hit-stop (thử xem có hợp không, bỏ nếu nặng nề).
  Phương án nhẹ: chỉ `city_hall_upgrade_complete` + `build_complete`.
- Đột biến lúc phát trong trận (banner nhỏ): `material_credit.ogg` -6 dB (tạm). Float lần sau: không âm (tránh ồn), trừ Crack Mana dùng `resource_collect_01` rất nhỏ.
- Luật thức tỉnh tác động trong trận: một tiếng ngắn `star_activate` -8 dB, mỗi lượt tối đa một lần.
- File mới phải copy vào `godot/assets/audio/sfx/ui/` và qua `t_assets` / `t_v4ui_audio` (đừng bỏ qua test đếm file).

### 4.4 Trong trận: trạng thái "awakened" + luật thức tỉnh tác động

- Ô Anchor trên HUD: khung đôi `anchor_awake`, glyph `ui_awaken` ở góc, badge `xN` (không có hàng chip trong trận, xem 2.2). Nhìn lướt là biết.
- Mỗi lần luật thức tỉnh tác động (và cả luật nền):
  - ô Anchor pulse (như `CorePanel.pulse`, ~0.3 s) + cập nhật "xN";
  - **lần đầu mỗi trận**: banner 32 giữa-trên, khung đôi vàng, nhãn "AWAKENED", tên luật, 1.2 s, không chặn input. Ưu tiên cao hơn banner combo và đột biến (banner nào vượt 2 thì xuống float);
  - các lần sau: float 24 gần chỗ nó đổi, một lần mỗi lượt (lần thứ hai trở đi gộp "x2").

| Luật thức tỉnh | Hiệu ứng nhìn thấy | Float |
|---|---|---|
| Thorn Storm | vụ nổ lần hai quét hàng quái, số hiện từng quái, số Khiên quái bị xuyên nhìn thấy tụt | "Thorn Storm" giữa hàng quái |
| Redo Hand | viên Nứt tự tung lại, số mới hiện, không trừ mana | "Redo" trên các viên |
| Double Tempo | nút Overcast sáng lần hai, hiện giá 2 | "Double Tempo" cạnh nút Overcast |

## 5. Result và Codex

### 5.1 Result

- Thêm **một hàng "Anchor"** làm dòng đầu của thẻ "Combos" (không thêm thẻ mới, không thêm nút: Result đã đủ 2 secondary): `[glyph nhà] Volley · Awakened (fight 4)` hoặc `· Not awakened (House Cores 1/2)`.
  "Fight N" = trận lúc thức tỉnh, trích từ trạng thái đã lưu thống kê, không từ state luật.
- Dưới hàng Anchor (cùng thẻ): hàng "Mutations" liệt kê tên + số lần tác động, tối đa 3 (dư thì "+N more"): `Thorn Rebound x7`. Chữ, không màu.
- Người chơi stage <3: không có hàng Anchor; hàng Mutations vẫn hiện nếu có Cặp.
- Khoảng cách đã dãn ở GU mục 7; thêm hàng thì **kiểm lại cuộn/đệm cuối** ở 1280x720 để dòng "Skipped" không bị cắt.
- "Copy run card" thêm một dòng "Anchor: Volley (awakened)".

### 5.2 Codex: tab "Anchors"

- Thêm vào `BOOK_TABS` của `Codex.gd`: `["anchors", "ANCHORS"]`, **chỉ hiện từ stage 3**.
- Danh sách 3 Anchor MVP. Ô chưa từng chọn = bóng mờ (như tab Cores / Combos), chỉ hiện glyph nhà + "???".
- Ô đã chọn ít nhất một lần: tên, RULE, PRICE đầy đủ, **luật thức tỉnh đầy đủ** (đây là chỗ lộ luật thức tỉnh, xem câu hỏi Liam số 1),
  5 Lõi ruột (đã từng giữ: sáng; chưa: mờ, tooltip tên), và 2-4 combo của nhà kèm đột biến Cặp của nhà.
  Thống kê: "Picked N · Awakened M".
- `MetaState.anchor_codex {anchor_id: {picked, awakened}}`: qua `SaveStore`, **thêm vào `MetaState.reload_from_store()`**, ghi đĩa ở `run_ended` (đúng bài học GM: ghi ở `phase_changed` làm test báo đổi save).
- Tab Combos hiện có: thêm hàng "Mutation: <tên> — <câu luật>" dưới mỗi combo có đột biến (tận dụng cùng text của banner).

## 6. Yêu cầu dữ liệu từ gameplay (ui-programmer đọc, không tự bịa)

UI chỉ đọc. Làn engine cung cấp (tên tạm, chốt theo repo thật): `RunState` Anchor đã chọn; hàm đếm House Cores và `awakened()` tính từ Lõi đang giữ;
`EventBus.anchor_picked`, `anchor_awakened(anchor_id)`, `mutation_formed(house, level)`, `mutation_fired(id, ...)`, `anchor_rule_fired(id)`;
data: tên / luật / giá / luật thức tỉnh / 5 Lõi ruột / nhà từng Anchor + đột biến từng nhà, mọi chữ qua `UI3.describe()`. Chọn Anchor = action (`pick_keystone`,
làn engine + 3 chỗ `ALLOWED_FNS`). Nếu chưa có thì stub bằng adapter như `ComboAdapter` (một chỗ duy nhất đọc API), có hook cho test.

## 7. Truy cập (checklist spec)

- Chỉ bàn phím: chọn Anchor (1/2/3, Trái/Phải, Enter), nhận, bỏ qua moment (Enter/Space/Esc). Đủ.
- Chỉ gamepad: D-pad + A. Đủ.
- Chữ nhỏ nhất 18 (16 chỉ key hint nếu có). Ở 1280x720 (scale 0.667): 18 → 12 px, vẫn là mức tối thiểu hiện tại của UI3.
- Không chỉ dựa vào màu: nhà = glyph + tên; giá = "−"/PRICE + chữ; thức tỉnh = glyph + chữ "Awakened"; đột biến = nhãn "MUTATION".
- Nhấp nháy: sóng/rung/mảnh tắt khi Reduce flashing; không có nhấp nháy > 3 lần/giây ở chỗ nào khác (vòng sóng chỉ chạy một lần, không lặp).
- Phụ đề: không có thoại.
- Scale: thẻ 1536 rộng tại 1920; ở 1280x720 scale đều theo canvas. Không dùng toạ độ y cứng, dựng theo quan hệ.

## 8. Checklist test UI

Test mới (tên tạm; thêm vào sàn suite cùng commit, sửa số trong `.claude/docs/technical-preferences.md`):

- `t_anchor_pick_ui`: stage 2 không thấy overlay; stage 3 có đúng 3 thẻ; không node Reroll/Skip; primary disabled khi chưa chọn kèm lý do; chọn → viền cream 4; lần bấm tua không chọn thẻ; mỗi thẻ có RULE + PRICE + Awakens + 5 icon (vùng >= 44); 1/2/3 chọn được; thoát giữa chừng thì mở lại overlay.
- `t_anchor_hud`: ô Anchor có ở đầu CoreSlots (56); chip "House Cores x/2" đổi theo số Lõi ruột giữ; ô Lõi ruột có glyph nhà (không chỉ màu); nhận Lõi ruột thứ hai → "Awakened"; stage <3 không có gì.
- `t_core_house_chip`: thẻ Lõi ruột có chip nhà; thẻ làm thức tỉnh có "→ AWAKEN"; không có chữ nào lộ bậc kế (kéo `t_gacha_guards` xanh).
- `t_mutation_banner`: PAIR + dòng đột biến, 2.0 s; Đủ ghi "LEVEL 2"; stage 2 vẫn hiện; click-through; không nhân đôi khi gộp với thức tỉnh.
- `t_awaken_moment`: chiếu đúng một lần mỗi run; ≤2.5 s; bấm/Space/Esc nhảy cuối; Reduce flashing: không vòng/rung, ≤1.6 s; mở lại run dở không chiếu lại; chặn input trong lúc chạy; gộp Cặp + thức tỉnh = một moment.
- `t_anchor_combat_fx`: lần đầu = banner, lần sau = float, tối đa 2 banner; thứ tự ưu tiên Awakened > Combo > Mutation; ô Anchor pulse và đếm "xN".
- `t_anchor_result` + `t_anchor_codex`: hàng Anchor/Mutations; tab Anchors chỉ từ stage 3; `reload_from_store` giữ `anchor_codex`; hàng cuối Result không bị cắt ở 1280x720.
- Cập nhật `t_ui_laws` (viền token, cỡ chữ không ngoài tập), `t_ui3_theme` (token mới), `t_v4ui_audio` / `t_assets` (file âm mới).

### Ảnh cần chụp (`godot/tools/shot.sh <scene> WxH`, mỗi cái ở 1920x1080 và 1280x720)

1. Overlay chọn Anchor: úp; lật xong; một thẻ được chọn; primary disabled có lý do.
2. Tooltip icon Lõi ruột trên thẻ Anchor.
3. CorePanel: chưa có Lõi ruột (0/2); 1/2 (viền nhà + glyph); đã thức tỉnh (khung đôi, chip "Awakened").
4. Thẻ Lõi ruột thường; thẻ có "1/2 → AWAKEN"; thẻ vừa PAIR vừa AWAKEN (kiểm hàng chip không cắt).
5. Banner PAIR có dòng đột biến; banner FULL có "LEVEL 2".
6. Moment thức tỉnh: t 0.3 (thẻ), t 0.8 (vòng + khung đổi), t 1.5 (đủ chữ), bản Reduce flashing, bản gộp Cặp + thức tỉnh.
7. Trận: banner đột biến lần đầu, float lần sau, banner thức tỉnh lần đầu, ô Anchor sau khi pulse, ba hiệu ứng thức tỉnh (Thorn Storm / Redo Hand / Double Tempo).
8. Result có hàng Anchor (đã thức tỉnh, chưa thức tỉnh) + Mutations; Codex tab Anchors (bóng mờ + mở).

## 9. Cần Liam duyệt

1. **Thẻ Anchor có lộ luật thức tỉnh không?** Đề xuất: chỉ tên ("Awakens: Thorn Storm"), luật đầy đủ nằm trong Codex và hiện đầy đủ ở moment. Lý do: giữ bất ngờ cho khoảnh khắc "đột biến"; người muốn biết trước thì đọc Codex. Ngược lại: lộ luật trên thẻ thì chọn có thông tin hơn, nhưng Liam đã ghét nội dung vô hình, và đây là bản đổi bất ngờ so với "thấy build hình thành". Anh chọn.
2. **Màu thức tỉnh**: vàng (nhóm FULL) hay màu khác. Violet bị luật toàn cục cấm cho bề mặt không trả tiền, nên spec dùng vàng khung đôi + glyph + vòng sóng để tách khỏi FULL. Màu chính xác do art-director chốt.
3. **Cặp + thức tỉnh cùng lúc = một moment** (không chiếu banner PAIR rồi moment). Đề xuất đồng ý, vì chiếu nối tiếp sẽ dài 4 s+ và làm loãng khoảnh khắc lớn nhất.
4. **Mất Lõi ruột sau khi thức tỉnh**: Anchor tắt thức tỉnh (state tính từ Lõi đang giữ) kèm toast, hay khoá luôn khi đã thức tỉnh? Phụ thuộc game có đường mất/đổi Lõi không (cần hỏi làn engine); UI làm được cả hai.
5. **Âm**: không dùng cùng cặp file với FULL. File đề xuất ở 4.3 chưa nghe thử, cần audio-director/Liam nghe.
6. **Chữ tiếng Anh** của 3 Anchor, 3 luật thức tỉnh, 6 đột biến (bảng mục 1.3, 3.1) là đề xuất của UX; game-designer/Liam sửa trước khi vào data.

## Chốt (agent điều phối, 23/10)
1. Thẻ Anchor hiện ĐỦ luật thức tỉnh (một câu) — người chơi phải thấy mình đang xây hướng tới gì.
2. Màu thức tỉnh: vàng (violet cấm — chỉ cho bề mặt trả tiền). Màu cụ thể: art-director.
3. Cặp + thức tỉnh cùng lúc: gộp một moment.
4. Thức tỉnh KHOÁ tới hết run (đề xuất ghi "không tắt"), kể cả khi mất Lõi ruột.
5. Chữ tiếng Anh + file âm: dùng bản đề xuất, Liam có thể đổi sau.
