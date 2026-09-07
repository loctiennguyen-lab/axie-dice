# World Tour ("Lunacia Atlas")

> **Status**: Draft v4 — product owner đã chốt tên chính thức 2 map ("Lovely Forest I"/"Lovely Forest II") và yêu cầu thiết kế lại cổng khó giữa-map thành một CHUỖI NHIỆM VỤ tuần tự (thay vì 1 điều kiện đơn `progress(map1)>=T(10) AND ascMax>=3`). 2 câu hỏi mở ở cuối file trước khi bàn giao cho lead-programmer/ui-programmer/art-director.
> **Author**: game-designer (Claude Code), theo yêu cầu chuyển tiếp qua lead, 2026-09-07 (bản v1), sửa lại 2026-09-07 (bản v2, sau khi product owner trả lời 3 câu hỏi mở của v1; bản v3, cùng ngày, sau khi lead tải thêm `Map2-new.png` và `WorldMapSelection.png`; bản v4, cùng ngày, sau khi product owner chốt tên map và yêu cầu chuỗi nhiệm vụ thay cho cổng khó đơn điều kiện).
> **Last Updated**: 2026-09-07
> **Implements Pillar**: Không có pillar tương ứng trong `game-concept.md` hiện tại (`game-concept.md` chỉ liệt kê một pillar: "Minh bạch triệt để", thuộc về combat). World Tour là hệ **retention/meta thuần**, không chạm combat trực tiếp — ngoại trừ cổng giữa-map, lần đầu tiên một hệ meta của dự án đòi hỏi một CHUỖI chiến thắng combat thực sự tăng dần độ khó, không chỉ tham gia.
> **Phân biệt với 2 hệ meta đã có** (bắt buộc đọc trước khi review):
> | | Battle Pass (`scBP`, "Lunacia Pass") | Echo Box (`cosmetics.js`) | **World Tour (doc này)** |
> |---|---|---|---|
> | Trục tiến trình | XP theo hiệu suất từng run (thắng/thua/wave/elite/boss/ascension) | Không có trục — mở hộp độc lập | **Hybrid 2 tầng: (a) trong-map = số run cộng dồn, không phụ thuộc hiệu suất; (b) giữa-map = một CHUỖI NHIỆM VỤ tuần tự, mỗi bước khó hơn bước trước** |
> | Phần thưởng | Deterministic theo level | **Gacha** (random rarity, có duplicate/fuse) | **Deterministic theo ô cụ thể** |
> | Hình thức UI | Danh sách mốc dọc (progress bar + list) | Grid bộ sưu tập + nút mở hộp | **2 bản đồ hình ảnh riêng biệt (chapter), đường đi có hướng, có cổng khoá dạng chuỗi nhiệm vụ giữa hai bản đồ** |
> | Reset? | Không (vĩnh viễn, không giới hạn cấp dù đã MAX 30) | Không | Không — nhưng có điểm KẾT THÚC rõ ràng sau map thứ 2 (v1 dừng ở "sắp có thêm", không lặp vô hạn) |
> | Cảm giác thiết kế | "Tôi chơi giỏi/nhiều thì lên level" | "Tôi may thì trúng đồ hiếm" | **"Tôi cứ chơi là đi tiếp trong một chương — nhưng để sang chương mới, tôi phải hoàn thành cả một chuỗi thử thách tăng dần"** |

---

## Overview

World Tour là một hệ tiến trình cấp **meta, persistent** (không reset theo run, khác hẳn `scMap()` — bản đồ node chọn đường trong một run duy nhất), gồm **đúng 2 map/chapter riêng biệt cho v1**: Map 1 (**"Lovely Forest I"** — rừng/miếu, xem §Detailed Rules) và Map 2 (**"Lovely Forest II"** — hồ/ao sen, xem §Detailed Rules). Tên chính thức đã được product owner chốt (thay cho đề xuất "Olek Grove"/"Puffy Lagoon" của game-designer ở bản v3, chưa được duyệt) — xem §Câu hỏi mở đã đóng. Mỗi map là một chuỗi ô mốc tuyến tính riêng, không rẽ nhánh. Bên trong một map, vị trí người chơi được xác định bởi số run đã chơi kể từ khi map đó bắt đầu tính (participation, không phụ thuộc thắng/thua) — y hệt tinh thần bản v1 cũ. Nhưng để **chuyển từ Map 1 sang Map 2**, người chơi phải vượt qua một **cổng khó dạng CHUỖI NHIỆM VỤ tuần tự** (nhiều bước, mỗi bước khó hơn bước trước, phải hoàn thành đúng thứ tự) — không chỉ đơn thuần tích luỹ đủ số run, và không còn là một điều kiện đơn giản kiểm cùng lúc. Đây là điểm khác biệt cốt lõi so với bản thảo v1: tiến trình không còn là MỘT trục liên tục duy nhất, mà là hai tầng lồng nhau — nhẹ nhàng bên trong mỗi chương, có một CHUỖI thử thách thật giữa hai chương.

## Player Fantasy

*"Trong chương này, tôi chỉ cần tiếp tục lên đường — nhưng để bước sang chương tiếp theo, tôi phải chứng minh mình đã mạnh lên thật sự."*

Fantasy vẫn giữ tinh thần bản v1 ở tầng trong-map: Lunacia Pass thưởng **hiệu suất**, Echo Box thưởng **may mắn**, World Tour (trong một map) thưởng **sự hiện diện** — chỉ cần ngồi vào bàn và chơi. Nhưng bản v2 thêm một lớp cảm xúc mới ở ranh giới giữa hai map: cổng khó là một **cột mốc tự hào thật**, không phải một con số tích luỹ — nó phục vụ **Competence** (SDT) theo cách mà phần còn lại của hệ thống cố tình tránh né (bản thân participation-track không đo skill). Về MDA, tầng trong-map vẫn là **Discovery** pha **Submission** nhẹ như bản v1; tầng cổng-khó bổ sung một nhịp **Challenge** ngắn, có chủ đích, đúng một lần cho mỗi lần chuyển chương — không lặp lại liên tục để không biến cả hệ thống thành một hệ thi đấu.

Landmark tile bên trong mỗi map (hạ boss đầu tiên, mở Ascension lần đầu, hạ boss cuối) vẫn neo vào các cột mốc gameplay thật đã nêu ở bản v1, phục vụ **Relatedness** qua việc gắn tiến trình meta với khoảnh khắc cụ thể trong run.

## Detailed Rules

### Cấu trúc — 2 map/chapter riêng biệt, không phải 1 bàn cờ 16 ô

**v1 có đúng 2 map**, dựa trên 2 tấm art thật đã xác nhận tồn tại trong Drive (`Map1-new.png`, `Map2-new.png`):

| Map | Tên chính thức (đã chốt) | Nội dung art | Trạng thái xem xét |
|---|---|---|---|
| Map 1 | **"Lovely Forest I"** | 3014×985px — đường mòn xuyên rừng: trái là cỏ/bụi cây sáng, giữa là cây cổ thụ + cổng torii đỏ, phải là vách đá thông tối. Không có ô mốc vẽ sẵn — nền trơn để UI overlay | **Đã xem trực tiếp** |
| Map 2 | **"Lovely Forest II"** | 3176×1339px — hồ/ao sen: trái là đập đá + 2 ao sen nhỏ tách biệt, giữa là hồ chính nước xanh ngọc với đảo cây nhỏ giữa hồ + cầu gỗ bắc qua suối phía dưới, phải chuyển sang rừng thông xanh đậm (đối lập tông đất/rừng của Map 1 bằng tông nước/hồ) — cùng bố cục "trái sáng → phải tối, thông xanh đậm" như Map 1, xác nhận cặp đôi thị giác chủ đích | **Đã xem trực tiếp** |

Mỗi map có bộ ô mốc RIÊNG (đếm lại từ ô 1), không phải một dải 16 ô nối dài. Sau khi hoàn thành CẢ 2 map, màn hình chuyển sang trạng thái **"Chương tiếp theo sắp ra mắt"** (xem §Edge Cases) — không phải "TOUR COMPLETE" tĩnh vĩnh viễn như bản v1, vì product owner đã xác nhận sẽ có thêm map sau này (dù chưa tồn tại ở v1).

**Vì sao không giữ nguyên 16 ô một map**: yêu cầu mới đòi 2 map độc lập bằng art thật — ghép chúng thành một dải 16 ô sẽ xoá mất ranh giới "chương" mà 2 tấm art riêng biệt vốn đã ngụ ý (mỗi map có bối cảnh hình ảnh khác nhau, không liền mạch về mặt không gian). Số ô mỗi map được đề xuất là **10** (xem lý do ở §Formulas/§Tuning Knobs), thấp hơn 16 gốc, vì tổng hành trình giờ trải qua 2 map — giữ 16 ô/map sẽ gần gấp đôi tổng thời lượng hoàn thành so với bản v1 (272 run → có thể hơn 500 run cộng dồn), vượt xa mốc tham chiếu Echo Point Tier 1 (~46 giờ) mà bản v1 cố tình bám sát.

### Tầng 1 (trong-map) — participation, tính RIÊNG cho từng map

Vị trí trong MỘT map = số run đã chơi tính từ **baseline** của map đó, không phải `META.runs` tuyệt đối cho Map 2 (xem §Formulas #2 vì sao cần baseline riêng). Vẫn dùng công thức bậc hai quen thuộc `T(i) = i×(i+1)` cho từng map — cùng lý do sawtooth nhẹ như bản v1: ô đầu đến nhanh, càng về sau càng giãn nhưng không đột ngột.

- **Map 1**: baseline = 0 (đếm từ tài khoản mới, hoặc từ toàn bộ lịch sử `META.runs` hiện có với người chơi cũ — giữ nguyên hành vi "veteran thấy nhiều ô đã đủ điều kiện ngay" như bản v1, xem §Edge Cases).
- **Map 2**: baseline = giá trị `META.runs` tại đúng thời điểm cổng khó (§Tầng 2) được vượt qua lần đầu, lưu lại một lần (snapshot), không tính lại. Điều này đảm bảo Map 2 luôn là một hành trình MỚI bắt đầu từ 0 run tương đối, kể cả với một veteran đã có sẵn hàng trăm run trước khi vượt cổng — nếu không có baseline riêng, một veteran có thể mở khoá và claim hết map 2 ngay lập tức chỉ vì `META.runs` tuyệt đối của họ đã rất cao, phá vỡ ý nghĩa "map 2 là một chương mới".

### Tầng 2 (giữa-map) — cổng khó là một CHUỖI NHIỆM VỤ 4 bước tuần tự

**Thay đổi cốt lõi so với bản v3**: cổng khó KHÔNG còn là 1 điều kiện đơn kiểm đồng thời — đó là một **chuỗi nhiệm vụ tuần tự 4 bước** (`questStep` 0→4). Mỗi bước phải hoàn thành xong mới lộ/tính bước kế tiếp; UI chỉ hiện "bước hiện tại + yêu cầu bước đó", không hiện toàn bộ 4 bước cùng lúc như một checklist song song. Độ khó tăng dần theo đúng thứ tự chơi thực tế của một người chơi bình thường: tham gia đủ → thắng một Full Run bất kỳ (lần đầu thử mode dài) → leo Ascension trong Full Run → leo cao hơn nữa.

| Bước | Tên nhiệm vụ | Điều kiện | Nguồn dữ liệu | Vì sao khó hơn bước trước |
|---|---|---|---|---|
| 1 | Hoàn thành Map 1 | `progress(map1) >= T(10) = 110` | **Đã có** — `progress()` công thức #2, dùng lại y hệt bản v3 | Sàn tham gia — ai chơi đủ nhiều cũng đạt, không cần kỹ năng |
| 2 | Thắng 1 Full Run (Ascension bất kỳ) | `META.fullAscMax >= 1` | **Field MỚI** — xem giải thích dưới | Lần đầu đòi hỏi chọn đúng mode dài (`RUN_LEN['full']`), không chỉ tham gia |
| 3 | Thắng 1 Full Run ở Ascension 1 trở lên | `META.fullAscMax >= 2` | Field mới ở trên, ngưỡng cao hơn | Đòi thêm một bậc độ khó Ascension, vẫn trong mode dài |
| 4 (final — mở Map 2) | Thắng 1 Full Run ở Ascension 2 trở lên | `META.fullAscMax >= 3` | Field mới ở trên, ngưỡng cao hơn nữa | Ngưỡng số trùng với `ascMax>=3` cũ nhưng giờ SCOPE THEO MODE — khó hơn điều kiện cũ vì cũ chấp nhận cả Short Run |

`questStep(state)` (định nghĩa đầy đủ ở §Formulas #3) là một giá trị TÍNH RA từ `progress(map1)` và `META.fullAscMax` — **không lưu trữ thành field riêng**, giống triết lý "không lưu state suy ra được" đã dùng cho `badgeTier()`. `gateCleared() = (questStep(state) >= 4)`.

**Vì sao cần field mới `META.fullAscMax`** (không tránh được — đã tra `client.html`, xem §Dependencies): `S.mode` (`'full'` hay short) chỉ tồn tại trong state của MỘT run đang chạy, không được ghi vào `META` ở bất kỳ đâu (`DEF_META` — dòng 2111 — không có field nào phân biệt mode đã từng thắng). Bước 2-4 của chuỗi đòi hỏi cụ thể "đã thắng Ở MODE FULL", một trục hoàn toàn khác `META.ascMax` (đếm mọi mode). Không có cách nào suy ra "đã từng thắng Full Run ở Ascension N" từ dữ liệu hiện có mà không thêm ít nhất 1 field mới. `META.fullAscMax` được thiết kế **mirror chính xác logic `META.ascMax`** (`client.html:3869`) nhưng chỉ cập nhật khi `S.mode==='full'`:
```
if(S.phase==='won' && S.mode==='full'){ if(S.asc>=META.fullAscMax && META.fullAscMax<10) META.fullAscMax=Math.min(10,S.asc+1); }
```
Đặt cạnh đúng dòng cập nhật `ascMax` hiện có (~`client.html:3869`) — cùng một khối code, thêm một nhánh điều kiện, không phải một hệ thống theo dõi mới.

**Vì sao KHÔNG dùng boss cụ thể ("hạ 1 boss ở Ascension 1+") làm một bước riêng** (khác gợi ý ban đầu của product owner): `gooey_king` (boss đầu Map 1) đã là điều kiện landmark của Tile 4 Map 1 (§Ô mốc) — muốn hoàn thành Bước 1 (Map 1 xong hẳn) thì gần như chắc chắn đã hạ boss này từ lâu. Thêm nó làm một bước riêng sẽ không thật sự khó hơn — chỉ lặp lại một điều đã ngầm đúng. `META.bosses` cũng không lưu Ascension tại thời điểm hạ boss, nên "hạ boss Ở Ascension 1+" không kiểm chứng được chính xác mà không thêm field theo dõi thứ hai — bỏ bước này để giữ chuỗi ở đúng 1 field mới, không phải 2.

**Tính tuần tự có thật, không phải vẽ lại cùng 1 điều kiện**: vì `META.fullAscMax` tăng dần đơn điệu theo đúng cách chơi thực tế (game chỉ cho chọn Ascension ≤ ascMax hiện có khi bắt đầu run mới — xem `client.html:3301-3306`), một người chơi thường XUYÊN phải thắng Full Run ở Ascension thấp trước khi được phép thử Ascension cao hơn trong mode Full — chuỗi bước 2→3→4 phản ánh đúng trình tự chơi thật, không phải nhãn dán giả cho cùng 1 boolean. Người chơi kỹ năng cao có thể "nhảy cóc" nếu lần đầu tiên họ thắng Full Run đã ở Ascension 2+ (fullAscMax nhảy thẳng lên 3, hoàn thành bước 2-3-4 cùng lúc) — đây là hành vi CHỦ ĐÍCH, nhất quán với cách `ascMax` đã hoạt động ở phần còn lại của doc (xem §Edge Cases bản v3 cũ về veteran thắng nhanh ở Ascension cao).

### Ô mốc (tile) trong mỗi map — hai loại, như bản v1

**Ô thường**: mở khi participation đủ ngưỡng `T(i)` của map đó. Không có điều kiện phụ.

**Ô landmark** (giữ nguyên 3 mốc gameplay thật từ bản v1, phân bổ lại giữa 2 map thay vì dồn cả vào 1 map):

| Map | Ô | Ngưỡng T(i) (tương đối, tính từ baseline map đó) | Điều kiện landmark | Vì sao chọn nguồn này |
|---|---|---|---|---|
| Map 1 | Tile 4 | 20 | `META.bosses.includes('gooey_king')` | Luôn là boss đầu tiên ở cả 2 mode, không nằm trong `BOSS_ALT` — chắc chắn gặp, không phụ thuộc RNG (`data.js:381-382`) |
| Map 1 | Tile 10 (cuối map 1) | 110 | `META.ascMax >= 1` | Mốc "đã từng thắng ít nhất 1 lần" — nhẹ hơn hẳn ngưỡng cổng giữa-map (`ascMax>=3`), cố ý để 2 điều kiện không trùng nhau |
| Map 2 | Tile 10 (cuối map 2, capstone toàn Tour) | 110 (tương đối, tính từ baseline map 2) | `META.bosses.includes('agony')` | Luôn là boss cuối cùng ở cả 2 mode, không nằm trong `BOSS_ALT` — capstone hợp lý cho toàn bộ World Tour |

Map 2 có **9 ô thường (tile 1-9) + 1 ô landmark (tile 10, capstone `agony`)** — đã xác nhận qua art thật `Map2-new.png`, KHÔNG cần điều chỉnh số ô nữa: đường mòn đủ dài và có đủ điểm mốc tự nhiên (đập đá, 2 ao sen trái, hồ chính + đảo giữa, cầu gỗ, chuyển rừng thông phải) để phủ 10 ô mà không bị dồn cụm ở một khúc, tương tự mật độ mốc quan sát được ở Map 1.

**Vì sao vẫn loại `frost_lord`/`mirror` khỏi mọi landmark** (không đổi so với bản v1): hai boss này nằm trong `BOSS_ALT` (`data.js:383`) — random giữa hai lựa chọn, không đảm bảo gặp được đúng con nào chỉ bằng cách chơi đủ nhiều. Ranh giới không đổi: landmark chỉ được trỏ vào dữ liệu chắc chắn xảy ra nếu chơi đủ, không trỏ vào field có nhánh RNG.

### Phần thưởng — vẫn deterministic, KHÔNG qua gacha

Không đổi so với bản v1 ở nguyên tắc: mỗi ô có đúng MỘT vật phẩm cosmetic biết trước, cấp thẳng vào hệ sở hữu hiện có (`META.ownedTitles`/`ownedAvatars`/`ownedDecor`/`ownedBackgrounds`).

**Item độc quyền Tour** (không được nằm trong `COSMETIC_POOLS` Echo Box roll — ranh giới cứng, không đổi từ bản v1): 3 landmark ở trên — "Gooey King Trophy" (Map1 tile 4), "Ascension Threshold" (Map1 tile 10), "Tour Champion" — title + khung profile riêng (Map2 tile cuối, capstone của TOÀN BỘ Tour, không chỉ của Map 2).

**Tỉ lệ item độc quyền / tái dùng cho các ô THƯỜNG (không phải landmark): TBD, chưa chốt.** Bản v1 đề xuất mặc định "toàn bộ ô thường tái dùng pool Echo Box" — **giữ nguyên là placeholder, KHÔNG khoá thành quyết định** theo yêu cầu product owner (câu hỏi này để sau). Bảng ánh xạ ô → item cụ thể sẽ được điền khi tỉ lệ này được chốt; không viết số cụ thể trong doc này để tránh tạo cảm giác đã quyết khi chưa quyết.

### Huy hiệu hoàn thành map — 2 cấp Silver/Gold (mới, theo wireframe `WorldMapSelection.png`)

Wireframe màn chọn chương xác nhận mỗi tile map có một **completion badge dạng sao, 2 CẤP: silver/gold** — không phải nhị phân xong/chưa-xong như giả định ngầm của bản v1/v2. Định nghĩa 2 cấp dưới đây tái dùng đúng field/ngưỡng đã có (không thêm field theo dõi mới, badge là giá trị TÍNH ra, không lưu trữ):

- **Silver** = `progress(map) >= T(10)` của map đó — đã claim hết TẤT CẢ ô (participation đầy đủ). Đúng tinh thần tầng 1 của hệ thống: chỉ cần hiện diện đủ, không đòi kỹ năng.
- **Gold** = Silver **VÀ** một ngưỡng `META.ascMax` cao hơn mức tối thiểu của chính map đó:
  - **Map 1 Gold**: Silver(map1) AND `ascMax >= 3`. Badge Silver/Gold KHÔNG đổi ở bản v4 này (ngoài phạm vi 2 thay đổi được yêu cầu). **Lưu ý phát sinh sau khi cổng khó được thiết kế lại thành chuỗi nhiệm vụ (§Tầng 2)**: ở bản v3, ngưỡng này trùng có chủ đích với gate cũ (`ascMax>=3`, mọi mode), nên Gold Map1 ⇔ đã mở Map2. Ở bản v4, gate final-step dùng `META.fullAscMax>=3` (scoped theo mode Full) — CHẶT hơn `ascMax>=3` (mọi mode). Hệ quả: một người chơi có thể đạt Gold Map1 (`ascMax>=3` qua Short Run) mà VẪN chưa mở được Map 2 (chưa từng thắng Full Run). Badge và gate không còn trùng nhau tuyệt đối — đây là điểm cần product owner xác nhận có chấp nhận được không (xem §Câu hỏi mở), vì thay đổi số ngưỡng `goldThreshold(map1)` nằm ngoài phạm vi 2 thay đổi được giao ở bản này.
  - **Map 2 Gold** (map cuối/capstone của v1): Silver(map2) AND `ascMax >= 5`. Cao hơn Map 1 Gold một bậc rõ ràng, nối tiếp đúng thang `ascMax` đã dùng xuyên suốt doc: `1` (landmark Map1 tile10) → `3` (cổng Map1↔Map2 / Gold Map1) → `5` (Gold Map2) — vẫn một field, ba ngưỡng, không bịa cơ chế mới.
- Vì badge tính theo `ascMax` hiện tại (không snapshot), nếu `ascMax` tăng SAU KHI player đã có Silver, badge tự nâng cấp lên Gold ngay ở lần load màn chọn chương tiếp theo — không cần một hành động "claim badge" riêng (khác claim ô/landmark, vốn cần bấm).

### Tương tác UI (mức yêu cầu chức năng — hình ảnh cụ thể do `ux-designer`/`art-director` quyết)

- Tile `'TOUR'` trong nhóm PROGRESS ở `scMenu()` — không đổi từ bản v1.
- Màn hình `screen='tour'` giờ cần **2 chế độ xem**: **màn chọn chương** (`scTourMapSelect()`, mới) hiện danh sách map dạng hàng ô vuông — đúng bố cục đã xác nhận ở `WorldMapSelection.png` (banner tiêu đề "WORLD MAP" + N ô tile, mỗi ô = 1 map) — và **màn trong-map** (giữ nguyên bố cục đường đi + ô mốc như bản v1).
- Mỗi ô map ở màn chọn chương PHẢI hiện đủ 3 thành phần, theo đúng wireframe:
  1. **Completion badge dạng sao, Silver/Gold** theo `badgeTier()` ở trên (không hiện badge nếu chưa đạt Silver).
  2. **Cờ đánh dấu vị trí hiện tại** (flag pin) — chỉ hiện trên map ĐANG active (map thấp nhất còn ô chưa claim hết); map đã Gold hoặc map còn khoá không cần cờ.
  3. **Trạng thái khoá/mở**, đúng 3 loại: **còn ô chưa claim** · **đã hoàn thành hết ô** (Silver hoặc Gold) · **còn khoá** (hiện rõ lý do cụ thể — participation còn thiếu HAY ascMax còn thiếu, xem §Edge Cases, không được nói chung chung "chưa đủ điều kiện").
- Wireframe cũng xác nhận sẵn UX cho việc **thêm map mới sau này**: một ô tile riêng, trạng thái khoá/xám, đặt cuối hàng — đây chính là trạng thái "Chương tiếp theo — Sắp ra mắt" đã mô tả ở §Edge Cases, hiển thị NGAY trong cùng màn chọn chương (không phải màn riêng), khớp đúng ý đồ gốc trong wireframe.
- Chi tiết "dashed line + X" trên art wireframe (gợi ý điểm treasure/reward vẽ trực tiếp trên path) là mức art — để `ux-designer`/`art-director` quyết cách áp lên ô landmark trong-map, không phải yêu cầu chức năng bắt buộc ở bản này.
- Trong một map: giữ nguyên bố cục đường đi ngang/dọc + 3 trạng thái ô (đã claim / đủ điều kiện chưa claim / chưa đủ điều kiện) như bản v1.
- Nút "CLAIM ALL" vẫn bắt buộc, áp dụng theo TỪNG map (claim hết ô đủ điều kiện trong map đang xem, không claim xuyên map).

## Formulas

### 1. Ngưỡng mở ô trong-map — T(i), tính riêng theo từng map

```
T(i) = i × (i + 1),   i = 1..10   (áp dụng độc lập cho Map 1 và Map 2)
```

| Biến | Ý nghĩa | Miền giá trị |
|---|---|---|
| `i` | Chỉ số ô trong map hiện tại (1-indexed, KHÔNG cộng dồn xuyên map) | số nguyên 1-10 |
| `T(i)` | Số run tương đối (tính từ baseline map đó) cần để mở ô `i` | số nguyên dương, tăng dần |

**Ví dụ tính**: `i=1 → T=2` · `i=4 → T=20` · `i=10 → T=110`. Ô cuối mỗi map cần 110 run tương đối (~18-37 giờ chơi ước lượng, dùng cùng tham chiếu ~10-20 phút/run và ~156 Shard/run như `economy-progression.md` §10.3). Tổng 2 map (nếu chơi liên tục không có khoảng dừng ở cổng khó) là tối đa 220 run tương đối cộng dồn — cùng bậc độ lớn với 272 run của bản v1 một-map, không vượt xa mốc Echo Point Tier 1.

**Lưu ý triển khai**: giữ nguyên khuyến nghị bản v1 — lưu bảng ngưỡng thành dữ liệu tường minh trong `assets/data/` (2 mảng 10 số nguyên, một cho mỗi map), không tính lại bằng công thức mỗi lần.

### 2. Baseline map — vì sao Map 2 cần một giá trị snapshot riêng

```
progress(map) = META.runs − base(map)
base(map1) = 0                                  // cố định, không đổi
base(map2) = META.runs tại thời điểm gateCleared() lần đầu trả về true, lưu 1 lần
```

Nếu không có `base(map2)`, một người chơi đã có `META.runs` rất lớn từ trước (vd 500) sẽ thấy toàn bộ 10 ô Map 2 đủ điều kiện ngay khi vừa vượt cổng — biến "chương mới" thành vô nghĩa. `base(map2)` chỉ được gán MỘT LẦN (giá trị null trước đó); mọi lần tính `progress(map2)` sau đó dùng lại đúng giá trị đã lưu, không tính lại theo công thức động.

### 3. Cổng khó giữa-map — chuỗi nhiệm vụ `questStep()` (v4, thay thế điều kiện đơn của v3)

```
questStep(state) =
  0   nếu  progress(map1) < T(10)                         // chưa xong Map 1
  1   nếu  progress(map1) >= T(10)  AND  fullAscMax < 1    // Map 1 xong, chưa thắng Full Run nào
  2   nếu  progress(map1) >= T(10)  AND  fullAscMax == 1   // đã thắng 1 Full Run (Asc 0)
  3   nếu  progress(map1) >= T(10)  AND  fullAscMax == 2   // đã thắng Full Run ở Asc 1
  4   nếu  progress(map1) >= T(10)  AND  fullAscMax >= 3   // đã thắng Full Run ở Asc 2+ — GATE CLEARED

gateCleared() = ( questStep(state) >= 4 )
```

`questStep()` **không phải một field lưu trữ** — tính lại mỗi lần render, giống triết lý `badgeTier()` (§Formulas #6). `fullAscMax` viết tắt cho `META.fullAscMax` (field mới, xem §Detailed Rules/§Dependencies).

| Biến | Ý nghĩa | Miền giá trị | Ví dụ |
|---|---|---|---|
| `progress(map1)` | Số run tương đối đã tích luỹ trong Map 1 (công thức #2) | số nguyên ≥0 | `progress(map1)=109` → chưa đủ, `questStep` kẹt ở 0 bất kể `fullAscMax` |
| `T(10)` | Ngưỡng ô cuối Map 1 | hằng số = 110 | — |
| `META.fullAscMax` | Cấp Ascension cao nhất đã từng THẮNG **trong mode Full** + 1 (field MỚI — mirror chính xác logic `META.ascMax`, chỉ khác điều kiện `S.mode==='full'`) | số nguyên 0-10, mặc định 0 | `fullAscMax=2` → đã thắng Full Run tối đa ở Ascension 1 → `questStep=3` |

**Biên giá trị**:
- `progress(map1)=109, fullAscMax=10` → `questStep=0` (Map 1 chưa xong — participation luôn là điều kiện tiên quyết, bất kể skill Full Run cao thế nào).
- `progress(map1)=110, fullAscMax=0` → `questStep=1` (Map 1 xong, đang chờ bước 2: thắng 1 Full Run bất kỳ).
- `progress(map1)=110, fullAscMax=1` → `questStep=2`.
- `progress(map1)=110, fullAscMax=2` → `questStep=3`.
- `progress(map1)=110, fullAscMax=3` → `questStep=4` → `gateCleared()=true` — Map 2 mở khoá, `base(map2)` được snapshot ngay tại thời điểm này (không đổi cơ chế snapshot so với v3, chỉ đổi điều kiện kích hoạt).
- `progress(map1)=110, fullAscMax=7` → vẫn `questStep=4` (đã vượt xa ngưỡng cần, không có bước 5 — chuỗi dừng ở 4 cho v1).
- **Nhảy cóc hợp lệ**: một người chơi thắng Full Run ĐẦU TIÊN của họ đã ở Ascension 2 (vd nhờ kỹ năng tích luỹ từ Short Run trước đó) → `fullAscMax` nhảy thẳng 0→3 trong một lần thắng → `questStep` nhảy thẳng 1→4 ngay lập tức, bỏ qua trạng thái hiển thị 2 và 3. Đây là hành vi ĐÚNG THIẾT KẾ (không phải bug) — xem §Detailed Rules.

### 4. Điều kiện landmark trong-map — không đổi dạng so với bản v1

```
eligible(tile) = ( progress(tile.map) >= T(tile.idx) ) AND ( tile.landmarkCond ? tile.landmarkCond(META) : true )
```

### 5. Phần thưởng — vẫn không có công thức (tra bảng tĩnh), đây vẫn là điểm mấu chốt thiết kế

Không đổi từ bản v1: không roll, không RNG, không tỉ lệ hiếm. Việc "không có formula" ở đây vẫn là bằng chứng thiết kế cho yêu cầu deterministic.

### 6. Cấp huy hiệu hoàn thành map — `badgeTier(map)` (mới, v3)

```
badgeTier(map) = 'none'    nếu progress(map) < T(10)
badgeTier(map) = 'silver'  nếu progress(map) >= T(10)  AND  ascMax <  goldThreshold(map)
badgeTier(map) = 'gold'    nếu progress(map) >= T(10)  AND  ascMax >= goldThreshold(map)

goldThreshold(map1) = 3
goldThreshold(map2) = 5
```

| Biến | Ý nghĩa | Miền giá trị | Ví dụ |
|---|---|---|---|
| `progress(map)` | Công thức #2, số run tương đối đã tích luỹ trong map đó | số nguyên ≥0 | `progress(map1)=110` → đủ Silver |
| `goldThreshold(map)` | Ngưỡng `ascMax` cần để lên Gold, riêng theo từng map | hằng số: map1=3, map2=5 | — |
| `ascMax` | `META.ascMax`, đã track sẵn | số nguyên 0-10 | `ascMax=2` → Silver, chưa Gold (map1) |

**Biên giá trị**: `progress(map1)=109, ascMax=10` → `'none'` (chưa đủ participation, bất kể ascMax cao thế nào). `progress(map1)=110, ascMax=2` → `'silver'`. `progress(map1)=110, ascMax=3` → `'gold'`. `progress(map2)=110, ascMax=4` → `'silver'` (đủ cho Gold map1 nhưng CHƯA đủ cho Gold map2, vì `goldThreshold` khác nhau theo map — không dùng chung một hằng số). `progress(map2)=110, ascMax=5` → `'gold'`.

## Edge Cases

- **Người chơi cũ, `META.runs` đã rất lớn khi tính năng ra mắt** (vd 180 run có sẵn): Map 1 dùng `base=0` nên vẫn thấy nhiều ô đã đủ điều kiện ngay (đúng như bản v1) — CLAIM ALL xử lý việc này trong Map 1. **Map 2 KHÔNG bị ảnh hưởng bởi lịch sử `META.runs` cũ** vì `base(map2)` chỉ được snapshot tại đúng thời điểm vượt cổng, không phải tại thời điểm feature ra mắt — một veteran vẫn phải tích luỹ đúng 110 run MỚI sau khi vượt cổng để hoàn thành Map 2, không được "miễn phí" nhờ lịch sử chơi trước đó. Đây là hành vi CHỦ ĐÍCH, ngăn việc baseline tuyệt đối biến Map 2 thành vô nghĩa.
- **Người chơi đang ở GIỮA chuỗi nhiệm vụ (`questStep` 1, 2, hoặc 3)** (mới, v4 — thay thế hoàn toàn cách xử lý "khoá/mở nhị phân" của v3): màn chọn chương KHÔNG được chỉ hiện "còn khoá" chung chung — PHẢI hiện rõ **ĐANG Ở BƯỚC NÀO trong 4 bước** VÀ **bước đó cần gì để qua bước kế tiếp**, đúng bảng ở §Detailed Rules:
  - `questStep=0` → "Hoàn thành Map 1 (còn X ô nữa)".
  - `questStep=1` → "Bước 1/3 xong. Cần: Thắng 1 Full Run (Ascension bất kỳ)".
  - `questStep=2` → "Bước 2/3 xong. Cần: Thắng 1 Full Run ở Ascension 1 trở lên".
  - `questStep=3` → "Bước 3/3 xong. Cần: Thắng 1 Full Run ở Ascension 2 trở lên — mở Map 2!".
  Đây là trạng thái được kỳ vọng tồn tại lâu dài với phần lớn playerbase ở `questStep` 0-2 (Full Run + Ascension cao không tầm thường), không phải lỗi. Không được gộp 4 bước thành một câu duy nhất kiểu "cần thắng Full Run ở Ascension 2" khi player đang ở bước 1 — phải luôn hiện ĐÚNG bước kế tiếp, không nhảy cóc thông báo trước khi player đạt bước liền trước.
- **`fullAscMax` đã cao từ trước (nhờ nhảy cóc) nhưng Map 1 CHƯA xong** (vd người chơi kỹ năng cao nhưng ít run — hiếm nhưng có thể): `questStep` kẹt ở 0 cho tới khi `progress(map1)>=T(10)`, thông báo phải nói đúng lý do còn thiếu là **participation** ("Hoàn thành nốt Map 1"), KHÔNG nói "cần thắng Full Run" (đã đủ từ trước) — theo đúng định nghĩa `questStep()` ở §Formulas #3 (participation luôn là điều kiện tiên quyết của bước 1, độc lập với `fullAscMax`).
- **Hoàn thành CẢ 2 map** (Map 1 claim hết + Map 2 claim hết): màn hình chọn chương hiện một thẻ Map 3 ở trạng thái tĩnh, khoá, với nội dung cụ thể: tiêu đề **"Chương tiếp theo — Sắp ra mắt"**, mô tả ngắn kiểu "Bạn đã hoàn thành toàn bộ World Tour hiện có. Chương mới sẽ được thêm trong bản cập nhật sau." — không để trống, không hiện lỗi, không hiện số ngưỡng giả (vì map 3 chưa tồn tại, không có T(i) nào để tính). Hai map đã hoàn thành vẫn xem lại được (đường đi + item đã nhận), không bị ẩn.
- **`META.runs` không bao giờ giảm** (không đổi từ bản v1) → cả `progress(map1)` và `progress(map2)` (sau khi có baseline) đều không thể tụt lùi.
- **Ô landmark đủ ngưỡng T(i) nhưng chưa đủ điều kiện phụ** (không đổi từ bản v1, áp dụng riêng cho từng landmark của từng map — vd Map 1 tile 4 đủ run nhưng chưa từng hạ `gooey_king` vì luôn bỏ dở trước wave 4/5): hiện rõ ĐANG THIẾU GÌ, không chỉ nói "chưa đủ điều kiện".
- **Badge tự nâng cấp Silver→Gold không cần hành động của player** (mới, v3): vì `badgeTier()` tính lại mỗi lần render màn chọn chương (không lưu trạng thái badge), một player đã có Silver ở Map 1 rồi sau đó thắng thêm ở Ascension 2 (đạt `ascMax=3`) sẽ thấy badge chuyển thẳng sang Gold ở lần mở màn hình tiếp theo — không có màn "chúc mừng lên Gold" riêng trong bản v1 này (chỉ badge đổi icon lặng lẽ); nếu cần một khoảnh khắc ăn mừng rõ ràng hơn, đây là điểm `ux-designer` có thể bổ sung ở bản sau, không phải yêu cầu bắt buộc của v1.
- **Veteran đã đạt `ascMax>=5` (đủ Gold cả 2 map) TRƯỚC KHI claim hết ô của map đó**: `badgeTier()` vẫn trả về `'none'` cho tới khi `progress(map) >= T(10)` — ascMax cao không "miễn" điều kiện participation của Silver, đúng công thức #6 (điều kiện AND, không phải OR).
- **Claim hai lần cùng một ô** (không đổi nguyên tắc từ bản v1, nhưng khoá định danh ô đổi format): `META.tourClaimed` giờ cần định danh CẢ map lẫn ô để không nhầm "tile 4 của Map 1" với "tile 4 của Map 2" — đề xuất định dạng chuỗi composite `"1:4"`/`"2:4"` thay vì số nguyên đơn thuần như bản v1. `tourClaim(mapIdx, tileIdx)` kiểm tra `META.tourClaimed.includes(`${mapIdx}:${tileIdx}`)` trước khi cấp thưởng.
- **Đồng bộ nhiều thiết bị**: không đổi nguyên tắc từ bản v1 (dùng cơ chế merge `META` hiện có) — nhưng giờ CŨNG cần đảm bảo `base(map2)` (một số nguyên nullable, không phải mảng) được đồng bộ đúng, nếu không hai thiết bị có thể snapshot `base(map2)` tại hai thời điểm khác nhau và cho ra 2 giá trị khác nhau cho cùng người chơi — cần lead-programmer xác nhận thứ tự ưu tiên khi merge (dùng giá trị NHỎ HƠN, tức baseline sớm hơn/có lợi hơn cho người chơi, hay giá trị từ cloud luôn thắng theo pattern hiện tại). **`META.fullAscMax` (field mới, v4) merge theo đúng pattern đã dùng cho `META.ascMax`** (lấy giá trị LỚN HƠN giữa 2 thiết bị — monotonic, không bao giờ giảm) — không cần quy tắc merge mới, chỉ áp dụng lại quy tắc sẵn có cho một field cùng kiểu dữ liệu (số nguyên 0-10, tăng dần).
- **Vật phẩm "độc quyền Tour" lỡ bị thêm nhầm vào `COSMETIC_POOLS`** (không đổi từ bản v1): vẫn cần unit test khẳng định tập 3 item độc quyền không giao với bất kỳ pool nào, chạy trong `tools/ci.mjs`.

## Dependencies

| Hệ thống | Quan hệ | Hướng dữ liệu |
|---|---|---|
| `META` object | Cần thêm `tourClaimed:[]` (mảng chuỗi composite `"map:tile"`), `tourMap2Base:null` (số nguyên nullable, snapshot một lần), **và `fullAscMax:0` (MỚI, v4 — mirror `ascMax` nhưng scoped theo `S.mode==='full'`, dùng cho `questStep()` §Formulas #3)** vào `DEF_META`. Đọc `META.runs`, `META.bosses`, `META.ascMax`, `META.fullAscMax` làm điều kiện mở ô VÀ điều kiện chuỗi nhiệm vụ cổng khó. | World Tour ĐỌC 4 field có sẵn/mới, GHI 3 field mới (2 mảng/scalar cũ + 1 số nguyên mới) |
| Run lifecycle (`client.html:3402` `META.runs++`, `:3861` `META.bosses.push`, `:3869` `META.ascMax`) | **Cần sửa** (không còn "không đổi từ v1"): thêm 1 nhánh mới ngay cạnh dòng cập nhật `META.ascMax` ở `:3869` — `if(S.phase==='won' && S.mode==='full'){ if(S.asc>=META.fullAscMax && META.fullAscMax<10) META.fullAscMax=Math.min(10,S.asc+1); }` (xem §Detailed Rules/Tầng 2). Đây là điểm chạm code DUY NHẤT cần sửa ngoài World Tour để chuỗi nhiệm vụ hoạt động. | Hai chiều — lần đầu tiên World Tour cần run lifecycle GHI thêm dữ liệu mới, không chỉ đọc |
| `cosmetics.js` | Cần ≥3 item MỚI độc quyền (landmark), không đưa vào `COSMETIC_POOLS`. Tỉ lệ độc quyền/tái dùng cho ô thường TBD (xem §Detailed Rules) | Hai chiều, không đổi từ bản v1 |
| `data.js` `BOSSES`/`BOSS_ORDER_12`/`BOSS_ORDER_20`/`BOSS_ALT`, và `ASCENSION` (dùng cho chuỗi nhiệm vụ cổng khó) | Landmark tile 4/Map1 và tile cuối/Map2 đọc `META.bosses`. **Chuỗi nhiệm vụ (`questStep()`) đọc `META.fullAscMax`, phụ thuộc bất biến "fullAscMax chỉ tăng khi thắng Ở MODE FULL tại một Ascension level mới cao hơn mọi lần thắng Full Run trước" (mirror `client.html:3869`, thêm điều kiện `S.mode==='full'`)** — nếu logic tăng `ascMax`/thêm mode mới trong tương lai đổi, cả `questStep()` VÀ `badgeTier()` (dùng `ascMax` riêng, không đổi) phải được xét lại độc lập vì giờ có 2 field khác nhau cùng gốc logic | Một chiều nhưng giòn, tương tự bản v1 — độ giòn TĂNG ở v4 vì có 2 field song song (`ascMax`, `fullAscMax`) thay vì 1 |
| `scMenu()`/`menuTile()` | Không đổi từ bản v1 | World Tour → UI menu |
| Màn chọn chương mới (`scTourMapSelect()`) | MỚI so với bản v1 — hiển thị 2 (sau này N) map, mỗi ô cần: badge Silver/Gold (`badgeTier()`, tính không lưu trữ), cờ vị trí hiện tại, 3 trạng thái khoá/mở + lý do khoá cụ thể, và 1 ô "sắp ra mắt" cuối hàng. Bố cục tham chiếu từ wireframe `WorldMapSelection.png` (đã xác nhận) | World Tour → UI, `ux-designer`/`art-director` triển khai art thật từ wireframe |
| Player Accounts / sync (`design/gdd/player-accounts.md`) | `tourClaimed` (định dạng mới), `tourMap2Base`, và **`fullAscMax` (mới, v4)** phải nằm trong payload sync — rủi ro merge nêu ở §Edge Cases áp dụng thêm cho `tourMap2Base` (một scalar, không phải mảng — rủi ro merge khác kiểu, cần race-condition riêng); `fullAscMax` merge theo pattern monotonic sẵn có của `ascMax` (lấy giá trị lớn hơn), không cần quy tắc mới | Hai chiều |
| `economy-progression.md` | Vẫn cần amendment thêm World Tour là hệ thứ ba — không đổi từ bản v1, ngoài phạm vi file này | World Tour → cần dẫn ngược lại |
| `game-concept.md` | Không đổi từ bản v1 | World Tour → game-concept.md |

## Tuning Knobs

| Knob | Loại | Miền an toàn | Lý do giá trị mặc định |
|---|---|---|---|
| Số ô mỗi map (hiện: 10, KHÔNG còn 16 cứng cho toàn hệ thống) | **Curve knob** | 6-16 mỗi map | 10 giữ tổng 2 map (~220 run tối đa nếu không tính thời gian chờ ở cổng khó) cùng bậc độ lớn với bản v1 một-map (272 run) — không cộng dồn thành gần gấp đôi thời lượng nếu giữ 16/map. Có thể cần điều chỉnh riêng cho Map 2 sau khi xem art thật (xem §Câu hỏi mở #1) |
| Công thức ngưỡng `T(i)=i(i+1)` mỗi map | **Curve knob** | Có thể đổi hệ số/bậc | Không đổi lý do từ bản v1 — sawtooth vừa phải |
| Số bước trong chuỗi nhiệm vụ cổng khó (hiện: 4 — participation + 3 mốc `fullAscMax`) | **Gate knob** | 3-5 (dưới 3 thì gần như quay lại 1 điều kiện đơn, mất cảm giác "chuỗi"; trên 5 thì UI mid-chain dễ gây mệt mỏi, mỗi bước cần message riêng) | 4 giữ đúng khuyến nghị "3-5 bước" của product owner ở cận trên vừa phải — đủ cảm giác hành trình mà không cần quá nhiều màn thông báo trạng thái |
| Ngưỡng `fullAscMax` cho từng bước (hiện: bước2=1, bước3=2, bước4=3) | **Gate knob** | Mỗi bước phải > bước trước (đảm bảo tăng dần); bước cuối 2-6 (dưới 2 trùng lặp landmark `ascMax>=1` sẵn có ở Map 1 tile 10; trên 6 rất ít người chơi đạt Full Run ở Ascension đó, có thể khoá Map 2 mãi mãi với phần lớn playerbase) | Bước cuối giữ nguyên giá trị số 3 từ gate đơn của v3 (đã hợp lý, xem lý do cũ) nhưng SCOPE lại theo mode Full — giữ đúng độ khó tương đối đã duyệt, chỉ đổi cách đo |
| Vị trí landmark trong mỗi map (hiện: tile 4 & 10 ở Map 1; tile 10 ở Map 2) | **Gate knob** | Chỉ gắn vào field không có nhánh RNG | Không đổi lý do từ bản v1; vị trí Map 2 có thể cần xê dịch theo bố cục art thật |
| Tỉ lệ item độc quyền / tái dùng cho ô THƯỜNG | **Gate knob** | **TBD — chưa chốt, không có giá trị mặc định trong bản này** | Theo yêu cầu product owner: để quyết định sau, không khoá cứng trong revision này |
| Nút CLAIM ALL — animation riêng theo từng item | **Feel knob** | — | Không đổi từ bản v1 |
| `goldThreshold(map1)` (hiện: 3, = trùng cổng Map1↔Map2) | **Gate knob** | Nên giữ bằng đúng ngưỡng cổng Map1→Map2 để badge phản ánh đúng ý nghĩa "đủ điều kiện mở map sau" — nếu tách rời 2 giá trị, cần lý do rõ ràng | Trùng cổng khó theo chủ đích, tái dùng một ngưỡng cho hai mục đích, tránh 2 con số dễ lệch nhau khi tuning về sau |
| `goldThreshold(map2)` (hiện: 5, capstone) | **Gate knob** | 4-8 (phải LỚN HƠN `goldThreshold(map1)=3` để giữ thang 3 bậc có ý nghĩa; trên 8 rủi ro gần như không ai đạt Gold map cuối) | 5 tạo khoảng cách đều với bậc `1→3` trước đó (landmark map1 → cổng/gold map1 → gold map2), vẫn nằm trong thang 0-10 Ascension hiện có |

## Acceptance Criteria

**Functional (tự động hoá được):**
1. `DEF_META.tourClaimed` mặc định `[]`; `DEF_META.tourMap2Base` mặc định `null`; `DEF_META.fullAscMax` mặc định `0`, cho tài khoản mới.
2. **(SỬA, v4 — thay thế phép kiểm `gateCleared()` đơn của v3)** Cho trước `progress(map1)` và `META.fullAscMax` bất kỳ, `questStep()` phải khớp chính xác bảng 4 bước ở §Detailed Rules/Tầng 2 tại các giá trị biên: `progress=109, fullAscMax=3` → `questStep=0` (participation luôn chặn trước, bất kể fullAscMax cao thế nào) · `progress=110, fullAscMax=0` → `questStep=1` · `progress=110, fullAscMax=1` → `questStep=2` · `progress=110, fullAscMax=2` → `questStep=3` · `progress=110, fullAscMax=3` → `questStep=4` (=`gateCleared()`).
2b. **(MỚI, v4)** `questStep()` không bao giờ "nhảy lùi": cho trước một chuỗi giá trị `fullAscMax` tăng dần theo thời gian (0→1→2→3), `questStep()` tính lại mỗi lần cũng phải tăng dần hoặc giữ nguyên, không bao giờ giảm — kể cả khi `progress(map1)` đạt ngưỡng SAU khi `fullAscMax` đã cao sẵn (trường hợp "nhảy cóc" nêu ở §Edge Cases, `questStep` phải nhảy thẳng lên giá trị đúng theo `fullAscMax` hiện có ngay khi participation vừa đủ, không kẹt ở 1 rồi tăng dần từng bước một cách giả tạo).
3. Khi `questStep()` đạt 4 (`gateCleared()=true`) lần đầu, `META.tourMap2Base` được gán đúng MỘT LẦN bằng giá trị `META.runs` hiện tại; các lần đánh giá sau đó (kể cả khi `META.runs` tiếp tục tăng) không ghi đè lại giá trị đã snapshot.
3b. **(MỚI, v4)** Cho một run vừa thắng với `S.mode==='full'` và `S.asc` bất kỳ, `META.fullAscMax` cập nhật đúng công thức mirror ở §Detailed Rules/Tầng 2 (`if(S.asc>=fullAscMax && fullAscMax<10) fullAscMax=min(10,S.asc+1)`) — và **không cập nhật** khi `S.mode==='short'` dù `S.asc` cao đến đâu (test âm: thắng Short Run ở Ascension 5 không làm `fullAscMax` nhúc nhích).
4. Trong một map, cho trước `META.runs`/`META.bosses`/`META.ascMax` bất kỳ, ô đủ điều kiện phải khớp bảng ngưỡng `T(i)` tại các giá trị biên tương tự bản v1 (N=1 không ô nào mở, N=2 đúng ô 1 mở, v.v., áp dụng riêng cho từng map với baseline tương ứng).
5. Claim một ô cấp ĐÚNG MỘT vật phẩm cố định; claim lại ô đã claim là no-op — không cấp trùng.
6. 3 item độc quyền landmark không xuất hiện trong bất kỳ `COSMETIC_POOLS[cat]` nào — kiểm bằng test tự động trong `tools/ci.mjs`.
7. `META.tourClaimed` (định dạng composite mới) và `META.tourMap2Base` đều có mặt trong payload sync.
8. `badgeTier(map)` khớp chính xác công thức ở §Formulas #6 tại các giá trị biên: `progress=109,ascMax=10→'none'` · `progress=110,ascMax=2→'silver'` (map1) · `progress=110,ascMax=3→'gold'` (map1) · `progress=110,ascMax=4→'silver'` (map2, chưa đạt ngưỡng 5) · `progress=110,ascMax=5→'gold'` (map2).

**Experiential (playtest xác nhận):**
9. Người chơi mới thấy VÀ claim được ít nhất ô 1 của Map 1 trong phiên chơi đầu tiên (≤20 phút) mà không cần hướng dẫn.
10. Người chơi vừa hoàn thành Map 1 nhưng chưa đủ `ascMax>=3` mô tả đúng lý do Map 2 còn khoá bằng lời của họ (không cần thuật ngữ thiết kế) — xác nhận thông báo lý do khoá đủ rõ ràng, không gây cảm giác "bí ẩn không lối thoát".
11. Người chơi vừa vượt cổng khó lần đầu (chuyển sang Map 2) mô tả cảm giác là "vừa đạt được một cột mốc thật" chứ không phải "chỉ là chờ đủ số" — xác nhận cổng khó tạo được nhịp Challenge khác biệt so với phần còn lại của hệ thống.
12. Người chơi hoàn thành cả 2 map thấy màn "Chương tiếp theo — Sắp ra mắt" và mô tả cảm giác là "còn tiếp, không phải hết game" — không mô tả là lỗi hoặc màn hình trống.
13. Người chơi đạt Silver trên một map mô tả đúng nó là "đã xong map" và phân biệt được bằng lời của họ rằng Gold là "khó hơn, cần thắng ở độ khó cao" — xác nhận badge 2 cấp truyền tải đúng ý nghĩa participation-vs-skill mà không cần đọc tooltip.

---

## Câu hỏi mở cần Product Owner/Lead xác nhận (v4 — cập nhật sau khi đổi tên map + thiết kế lại cổng khó thành chuỗi nhiệm vụ)

1. ~~Cần xem `Map2-new.png`~~ / ~~"World Map Selection.PNG"~~ / ~~Tên chính thức 2 map~~ — **ĐÃ XÁC NHẬN cả 3** ở các bản trước: 10 ô/map giữ nguyên, wireframe đã tích hợp đủ vào §Detailed Rules, tên map là **"Lovely Forest I"/"Lovely Forest II"** (product owner chốt, thay đề xuất "Olek Grove"/"Puffy Lagoon" cũ).
2. **Xác nhận chuỗi nhiệm vụ 4 bước cụ thể** (§Detailed Rules/Tầng 2: xong Map1 → thắng 1 Full Run bất kỳ → thắng 1 Full Run Ascension 1+ → thắng 1 Full Run Ascension 2+) — đây là đề xuất CỤ THỂ của game-designer để hiện thực hoá yêu cầu "chuỗi nhiệm vụ đủ khó", chưa phải số bước/nội dung do product owner tự chọn. Đồng ý 4 bước này, hay muốn đổi nội dung/số bước (knob 3-5, xem §Tuning Knobs)?
3. **(MỚI, v4) Lệch giữa badge Gold Map1 và cổng khó thật** — badge Gold Map1 (`§Formulas #6`) vẫn dùng `META.ascMax >= 3` (mọi mode, không đổi từ v3), nhưng cổng khó thật để mở Map2 giờ dùng `META.fullAscMax >= 3` (chỉ tính Full Run, CHẶT hơn). Hệ quả: một người chơi có thể thấy Gold ở Map1 (thắng Ascension 2 bằng Short Run) mà VẪN đang bị khoá ở Map2 (chưa từng thắng Full Run) — badge và cổng không còn đồng nghĩa như thiết kế gốc của badge dự định. 2 hướng xử lý: (a) đổi `goldThreshold(map1)` sang đọc `fullAscMax` thay vì `ascMax` để badge và cổng lại khớp nhau tuyệt đối (đơn giản, nhất quán, nhưng badge Map1 giờ khó đạt hơn dự định ban đầu), hoặc (b) giữ nguyên như hiện tại, chấp nhận badge đo "kỹ năng nói chung" còn cổng đo cụ thể "sẵn sàng cho Map2" — hai ý nghĩa khác nhau, không cần trùng khớp. Cần product owner chọn (a) hay (b) trước khi bàn giao code.
4. **Field mới `META.fullAscMax`** cần 1 dòng code thêm vào run-lifecycle hiện có (`client.html:3869`, cạnh dòng cập nhật `ascMax`) — đã thiết kế xong công thức mirror, chỉ cần `lead-programmer`/`gameplay-programmer` xác nhận vị trí chèn đúng và không có race condition với dòng `ascMax` gốc khi cùng chạy trong 1 lần thắng.
