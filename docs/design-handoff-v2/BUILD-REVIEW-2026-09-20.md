# BUILD REVIEW — 20 Sep 2026 (design side, pass 6)

Nguồn: `Build Review 2026-09-20.dc.html` (Claude Design). Đây là **change list**, không phải
spec — bốn mockup trong `mockups-v2/` vẫn là chuẩn duy nhất, và mọi số dưới đây được trích
từ markup của chúng rồi đối chiếu bằng cách quét pixel trên ảnh QA thật.

**Ảnh đã đo:** Combat, Run Map, Main Menu, Team Select, Result, Vault — đều 1920×1080, đều ngày 2026-09-20.
**Ảnh CŨ, phải chụp lại trước khi sửa:** Reward, Shop, Event, Treasure (mới nhất 2026-09-19).
**Chưa đo:** Pass, Unlocks, Guides, Codex, Settings, Unit Inspect.


## §A · MƯỜI LỖI NẶNG NHẤT (xếp theo mức phá cách đọc màn hình)


### 1. `C1` — COMBAT — Hàng quái dính liền thành một dải 688px

**Hiện tại (đo được).** 4 nameplate chạy x=616→1303, 172px mỗi cái, **0px cách nhau**. Badge intent cũng vậy. Bốn đơn vị đọc ra như một widget HUD.

**Mockup.** Cột quái `width:186`, `gap:104` → còn 114px nền giữa hai plate. Cả khối còn phải cao hơn 185px: badge intent đỉnh y=75, build đang y=260.

**Chi phí:** 1 sửa


### 2. `C2` — COMBAT — Badge intent tô màu xám của nameplate thay vì màu loại đòn

**Hiện tại (đo được).** Lấy mẫu màu tại (700,276) ra `#161A21` — trùng xám nameplate. Cả hàng telegraph thành một dải xám.

**Mockup.** `background: e.intentBg` theo loại: dmg `#F54540`, shield `#31C6FF`, heal `#3FCD3C`, mana `#BF6BFF`, poison `#A8D84A`, buff `#FF9345`, debuff `#FF8FC7`. Cao 36 + viền 3.

**Chi phí:** 1 sửa


### 3. `C3` — COMBAT — Thanh shield biến mất khỏi MỌI nameplate

**Hiện tại (đo được).** Quét cột x=660 (quái): plate y335→398, chỉ 1 thanh HP 8px, rồi 16px plate phẳng. Party x=500 y sau thanh HP còn 15px trống. Shield không hiện ở đâu cả.

**Mockup.** Thanh thứ hai ngay dưới HP, hình học y hệt: `height:8; radius:5; bg:#0B0D12; border:2px #000; margin-top:4`, fill `#31C6FF`. Chỗ 15–16px trống chính là chỗ của nó.

**Chi phí:** 1 sửa/loại plate


### 4. `R1` — RUN MAP — Bảng toạ độ làn và hàng sai, làn phải chạy ra ngoài bàn cờ

**Hiện tại (đo được).** Đo được làn x=540/1155/1771, hàng y=112…895. Node hàng 1 bị banner boss che mất 2/3.

**Mockup.** `LANES={l:780,c:1150,r:1520}`, `ROWS={r1:946…r7:238}`. Bước làn 370 (không phải 615), bước hàng 118 (không phải 130).

**Chi phí:** 1 sửa (2 bảng hằng số)


### 5. `G1` — MAP·RESULT·VAULT — Thanh footer tự thêm vào, nuốt mất CTA của màn

**Hiện tại (đo được).** Thanh 69px ở y=1011→1080 mang nút BACK. Ở Result nó đẩy RUN IT AGAIN từ nút 340×72 giữa màn thành 132×44 góc phải, và **xoá hẳn MAIN MENU**.

**Mockup.** **Không mockup nào có footer.** Result đóng bằng hai nút giữa màn ở `bottom:52`: RUN IT AGAIN 340×72 và MAIN MENU 250×72, `gap:16`. Map đóng bằng SAVE & QUIT là pill 52px ở đáy cột trái, `bottom:28`.

**Chi phí:** rebuild nhỏ/màn


### 6. `R2` — RUN MAP — Mọi cạnh bản đồ vẽ cùng một nét đứt mảnh → không thấy nhánh đi được

**Hiện tại (đo được).** Một nét đứt tối cho tất cả: đã đi, sương mù, đang mở như nhau.

**Mockup.** Mỗi cạnh vẽ **hai lần**: nền `stroke:#000; width:14`, phủ `width:6` màu, `linecap:round`, **vẽ hết 11 nét đen trước rồi mới tới màu**. past `#4A525F` liền · live `#FFC79B` liền · skip/fog `#242A34` đứt `9 10`.

**Chi phí:** 1 sửa


### 7. `C4` — COMBAT — Nameplate mất viền đen và bóng shelf

**Hiện tại (đo được).** x=660: nhảy thẳng từ pixel cảnh `#2B551B` sang plate `#161A21`, không viền cạnh nào. Party chỉ có 3px đen ở trên, trái/phải/dưới không có.

**Mockup.** Cả hai: `border:3px #000; box-shadow:0 4px 0 rgba(0,0,0,.5); radius:12`. Party thêm `border-top:6px solid {cls}` — gấp đôi vạch build đang vẽ. **176×64 và 176×68 thì đã đúng rồi.**

**Chi phí:** 1 sửa


### 8. `G2` — MAP·RESULT·TEAM — Một lề chung đang đè lên lề riêng của từng màn

**Hiện tại (đo được).** Đo mép trái: map x=84, Result x=88, Team Select x=88, Main Menu x=84.

**Mockup.** Mỗi màn có lề riêng: Map `left:28`, Result `left:80/right:80`, Team Select `left:56/right:56`, Main Menu `left:84` (màn duy nhất build làm đúng). Lề chung 84–88 đang lấy mất 56px hành trình của panel map và 32px bề ngang thẻ Team Select.

**Chi phí:** 1 sửa nếu là hằng số chung


### 9. `C5` — COMBAT — Hàng đội canh giữa canvas; thiết kế đặt lệch trái

**Hiện tại (đo được).** 5 plate tại x=475/673/871/1071/1269, bước 198, tâm x=960.

**Mockup.** Container `top:484; left:402`, cột `width:180`, `gap:14` → bước 194, tâm x=880. **Người review tự đánh dấu là CHƯA CHẮC**: 402 đẩy đội lệch trái 80px, có thể cố ý (chừa chỗ cho cột reroll) hoặc là số thừa. Bước 194 thì chắc chắn đúng.

**Chi phí:** 1 sửa


### 10. `R3` — RUN MAP — Mô tả relic ở panel map bị cắt giữa chữ

**Hiện tại (đo được).** "RULE: whenever you c…" — một dòng, ellipsis. Không đọc được relic làm gì.

**Mockup.** `11px/600/1.35/#6F7887`, **không giới hạn bề rộng, không ellipsis** — nó xuống dòng. Bề ngang khả dụng 261px, đủ hai dòng.

**Chi phí:** 1 sửa (bật autowrap)


---

## §B · PHẦN CÒN LẠI, THEO MÀN


### COMBAT

| ID | Hiện tại | Mockup | Thành phần |
| --- | --- | --- | --- |
| `C6` | Front line is a 3px rule at y=513, inset x400→1525, no end caps. | top:480; left:40; right:40; height:6; radius:3; #000 + 2px rgba(243,231,211,.16) highlight inset 44 + two 14px diamonds rotate(45deg) at left:32 / right:32 | Front line divider |
| `C7` | Dice card total width 180 (172 cream + 4px borders); header 36 incl. border. | card width:180 + border:4 = 188 outer, gap:14 → pitch 202. Header height:36 + border-bottom:3 | Die tray cards ×5 |
| `C8` | Party class stripe reads 3px. | border-top:6px solid {cls} — plant #7DC943, beast #FFB23F, aqua #39C5F3, reptile #B679F7, bug #F2624F | Party nameplate top edge |
| `C9` | Status chip on Machito sits over the sprite's feet, below the nameplate. | Statuses are the FIRST child of the column, above the nameplate: height:28 row, chips height:28, padding:0 8px 0 4px, radius:9, border:3px #000, icon 16px, count 16px/#1A1206 | Party + enemy status chips |
| `C10` | Party nameplate order is sprite-above-plate. | Column order is statuses → nameplate → sprite for BOTH rows. Enemy row already does this; party row is inverted. Confirm against the 3D rig's anchor before moving — flagged, not asserted | Party column stacking |
| `C11` | Incoming-damage pill on Buba/Puffy sits between name and HP. | Correct — display:{{ incomingDisp }}; height:18; padding:0 5px 0 3px; radius:6; #F54540; 12px dmg icon; 14px/#FFF8EA. No change | Party incoming badge |

### RUN MAP

| ID | Hiện tại | Mockup | Thành phần |
| --- | --- | --- | --- |
| `R4` | Node corners are square. | border-radius:18px, and 24px on the current node. ColorRect cannot do this — needs a Panel with StyleBoxFlat corner_radius | All 12 nodes |
| `R5` | Left panel outer edge at x=84, top ≈93. | top:28; left:28; width:344; bottom:28; radius:18; border:4px #000; box-shadow:0 7px 0 rgba(0,0,0,.55) | Run panel |
| `R6` | SAVE & QUIT is the last row inside the panel card. | Separate pill at the foot of the column: height:52; radius:14; rgba(27,31,39,.92); border:4px #000; box-shadow:0 6px 0 rgba(0,0,0,.55); 16px/.18em/#8C95A4 | SAVE & QUIT |
| `R7` | The open elite node at (540,372) shows no label chip; the open battle at (1156,372) does. | labelDisp is flex for here AND open. Chip height:30; padding:0 12px; radius:9; border:3px #000; box-shadow:0 3px 0 rgba(0,0,0,.45); 14px/.08em. here → #FF9345 on #2A1505, open → #FFF8EA on #1A1206 | Node labels |
| `R8` | Boss banner overlaps the row-1 node. | Banner is top:30; right:28; height:66 — it clears row r7 at y=238 once R1 lands. No banner change needed | Boss banner |
| `R9` | 'THE PATH' block starts at x≈452. | top:30; left:396. Title 44px Baloo 800 #FFF8EA with text-shadow:0 3px 0 rgba(0,0,0,.6); sub 13px/600/#EDF1F6 with text-shadow:0 1px 3px rgba(0,0,0,.9), margin-top:5 | Screen header |

### MAIN MENU

| ID | Hiện tại | Mockup | Thành phần |
| --- | --- | --- | --- |
| `M1` | RUN SETUP panel outer box is 1270→1834, 564 wide. | width:566 + border:5 each side = 576 outer; right:84 → left edge lands at x=1260 | RUN SETUP panel |
| `M2` | BEGIN RUN outer height 86 (y538→623). | height:86 plus border:5px #000 = 96 outer. Check the same off-by-the-border on every fixed-height box on this screen | BEGIN RUN |
| `M3` | Nav tiles are 66 outer; first row y891→956, second y966→1031. | height:66 plus border:3 = 72 outer; grid gap:9; bottom:46; right:84; width:452 | Nav tiles ×5 |
| `M4` | Team cards 220 outer, pitch 233. | width:220 plus border:4 = 228 outer; gap:13 → pitch 241; radius:15; box-shadow:0 6px 0 rgba(0,0,0,.5); header height:34 + border-bottom:3 | Team cards ×5 |
| `M5` | Nav tile values sit hard against the tile's left edge, left of their own labels. | Tile padding is 9px 11px for both lines; label 12px/.08em/#C7BBD6, value 17px. They share one left edge | Nav tile value row |

### RESULT

| ID | Hiện tại | Mockup | Thành phần |
| --- | --- | --- | --- |
| `S1` | Stats strip at top 586, inset 88. | top:558; left:80; right:80; height:106; radius:18; #161A21; border:4px #000; box-shadow:0 7px 0 rgba(0,0,0,.55) | Stats strip |
| `S2` | Three-card row at top 722, inset 88. | top:692; left:80; right:80; gap:18; widths 560 / flex / 392; all radius:18, border:4px #000, box-shadow:0 7px 0 rgba(0,0,0,.55) | Shard / Pass / Relics |
| `S3` | Relic chips read ~34 tall. | height:40; padding:0 13px 0 7px; radius:11; border:3px #000; icon 20px; 14px/.04em/#1A1206; wrap gap:9 | RELICS CARRIED chips |
| `S4` | Roster geometry is correct — 214 pitch, 152 tile, 168 plate, -8 tuck. | No change. width:186 column, gap:28; tile 152 radius:26 border:5 shadow 0 8px 0; plate 168 margin-top:-8 radius:15 border:3 | Final roster |

### TEAM SELECT

| ID | Hiện tại | Mockup | Thành phần |
| --- | --- | --- | --- |
| `T1` | Card row inset 88 left and right; header block likewise. | Header top:42; left:56; right:56. Cards top:150; left:56; right:56; gap:14; each flex:1 1 0 | Screen insets |
| `T2` | Card header reads ~46 tall. | height:40 plus border-bottom:4px #000 = 44; name 21px/.02em, class 14px/.08em, both #1A1206; padding:0 13px | Card headers ×5 |
| `T3` | Card bottoms are ragged by up to 5px across the five cards. | The keyword line carries min-height:12px precisely so rows stay equal when a face has no keyword. Body padding is 12px 13px 14px | Face tile grid |
| `T4` | SAMPLE TEAMS / CONFIRM TEAM read ~54 tall but sit against the top edge. | Both height:54, radius:13, border:4px #000, box-shadow:0 5px 0 rgba(0,0,0,.45); row top:42, aligned flex-end with the title block | Header buttons |

### VAULT

| ID | Hiện tại | Mockup | Thành phần |
| --- | --- | --- | --- |
| `V1` | A ~320×220 flat black rectangle with 'No gene data for this Axie.' fills the portrait slot on both cards. | The mockup has no empty state for this slot. Needs a designed one — see Q4 | Axie card portrait |
| `V2` | The READY chip on the second card runs to the card's inner edge with no margin. | Chips sit inside the header's padding like every other card header in the kit: padding:0 13px, chip flex:0 0 auto | Card header chip |
| `V3` | Left panel outer edge at x=66. | Vault uses the meta-screen inset. Confirm against the mockup's own value before moving — see G2 | Import panel |

---

## §C · KHÔNG CÓ TRONG MOCKUP — CẦN CHỦ DỰ ÁN QUYẾT


**`Q1` · The footer bar with BACK**

A 69px bar at the foot of Run Map, Result and Vault carrying a generic BACK. No mockup has one, and on Result it has displaced RUN IT AGAIN from a 340×72 centred button to a 132×44 corner button and dropped MAIN MENU entirely.

> **Cần quyết:** Is the bar deliberate global navigation, or scaffolding? If deliberate, the mockups need to absorb it and Result's two CTAs need a new home.


**`Q2` · Enemy shield**

C3 asks for a #31C6FF shield track on the enemy nameplate. The mockup binds it to e.shieldPct, but nothing in the build currently draws enemy shield anywhere.

> **Cần quyết:** Is enemy shield tracked as a separate value from HP? If not, C3 is party-only this pass and enemy is a follow-up.


**`Q3` · The empty intent badge**

The third enemy's intent badge in the combat capture shows a small dot and nothing else — no value, no target, no icon. The mockup has no no-intent state.

> **Cần quyết:** What does an enemy with no telegraphed action look like? Options: hide the badge, or a neutral grey badge with a dash.


**`Q4` · Vault with no gene data**

Both imported Axies render a large flat black box reading 'No gene data for this Axie.' It is the biggest element on the card and it is a failure message.

> **Cần quyết:** Is this a real state players will hit, or a capture artefact? If real it needs a designed empty state at the same 3D-preview size.


**`Q5` · Result stats reading zero**

TURNS TAKEN, DAMAGE DEALT, KILLS and BIGGEST HIT all read 0 on a victory with 9/18 nodes cleared. AXIES LOST reads 0 correctly.

> **Cần quyết:** Telemetry rather than layout, but it is the most prominent thing on the screen. Who owns it?


---

## §E · THỨ TỰ ĐỀ XUẤT

| Mẻ | ID | Chi phí | Người chơi thấy? |
| --- | --- | --- | --- |
| Combat geometry and colour | C1 · C2 · C3 · C4 · C6 · C8 | ~6 edits, one scene | VISIBLE |
| Map grid and edges | R1 · R2 · R3 · R4 · R5 · R6 · R7 | ~7 edits, one scene | VISIBLE |
| Shared screen inset and the footer bar | G1 · G2 — after Q1 | 1 constant + 3 screens | VISIBLE |
| Box sizing on the meta screens | M1–M5 · S1–S3 · T1–T4 | ~12 edits, no logic | SUBTLE |
| Vault states | V1 · V2 · V3 — after Q4 | 1 edit + 1 new state | VISIBLE |
| Reward, Shop, Event, Treasure | blocked on fresh captures | unknown — possibly a rebuild | UNKNOWN |

Mẻ 1 và 2 là khoảng 40 dòng sửa trên hai scene và sẽ đổi ngay cách Combat và Map trông ra sao.
Mẻ 4 là mẻ **sẽ có cảm giác như không có gì thay đổi** — nói trước khi giao.
