# World Tour ("Lunacia Atlas")

> **Status**: Draft v6 — World Tour ĐÃ ĐƯỢC IMPLEMENT trong `src/client.html`/`src/data.js` (không còn chỉ là thiết kế trên giấy). v6 sửa Tầng 2 (chuỗi nhiệm vụ cổng khó) sau khi product owner từ chối bản v4/v5 (xem lý do ở §Tầng 2) — code hiện tại (`tourQuestStep()`, `client.html:4417-4424`) vẫn chạy theo logic v4/v5 cũ, CHƯA cập nhật theo v6; đây là việc bàn giao tiếp theo cho `lead-programmer`/`gameplay-programmer`.
> **Author**: game-designer (Claude Code), theo yêu cầu chuyển tiếp qua lead, 2026-09-07 (bản v1), sửa lại 2026-09-07 (bản v2, sau khi product owner trả lời 3 câu hỏi mở của v1; bản v3, cùng ngày, sau khi lead tải thêm `Map2-new.png` và `WorldMapSelection.png`; bản v4, cùng ngày, sau khi product owner chốt tên map và yêu cầu chuỗi nhiệm vụ thay cho cổng khó đơn điều kiện); bản v5, 2026-09-08, sau khi product owner chọn option (a) cho câu hỏi mở #3 (badge Map1 khớp cổng thật); bản v6, cùng ngày, sau khi product owner TỪ CHỐI chuỗi 4-bước của v4/v5 (câu hỏi mở #2) và yêu cầu thiết kế lại — xem §Tầng 2 cho chẩn đoán + đề xuất mới.
> **Last Updated**: 2026-09-08
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

### Tầng 2 (giữa-map) — cổng khó là một chuỗi 4 bước, qua 3 TRỤC khác nhau (v6 — thay thế hoàn toàn thiết kế v4/v5)

**Vì sao v4/v5 bị product owner từ chối (chẩn đoán, đã đối chiếu với code thật)**: bản v4/v5 xếp 3 bước 2-3-4 thành 3 ngưỡng khác nhau trên CÙNG MỘT field đơn điệu (`META.fullAscMax`: `>=1`, `>=2`, `>=3`). Vì `fullAscMax` có thể nhảy thẳng từ 0 lên 3 chỉ trong MỘT lần thắng (một người chơi kỹ năng cao thắng Full Run đầu tiên của họ đã ở Ascension 2+), toàn bộ "chuỗi 4 bước" sụp thành đúng 1 điều kiện đơn mà nó được thiết kế ra để thay thế — đúng với chính nhóm người chơi có kỹ năng cao nhất, tức nhóm ĐÁNG LẼ phải cảm nhận rõ nhất cảm giác "một cột mốc thật". Với người chơi chậm hơn, 3 bước tuần tự nhưng cùng LÀ MỘT việc lặp lại ở độ khó tăng dần ("thắng Full Run" 3 lần) — vẫn là cày cuốc mặc áo nhiệm vụ, không phải một chuỗi thử thách đa dạng. Cả 2 nhánh đều vi phạm chính tiêu chuẩn playtest mà bản thân doc đặt ra (AC-11: "cảm giác vừa đạt cột mốc thật", không phải "chỉ chờ đủ số").

**Đề xuất v6 — quyết định dứt khoát, không phải một danh sách phương án**: giữ nguyên **4 bước** (trong dải an toàn 3-5 đã ghi ở §Tuning Knobs) và giữ nguyên ngưỡng cuối (`fullAscMax>=3` — chưa từng bị đánh giá là quá dễ/khó qua các bản v3/v4, chỉ có ĐƯỜNG ĐI tới đó bị từ chối). Thay 3 ngưỡng chồng trên `fullAscMax` bằng **3 TRỤC khác nhau**, dùng field đã có sẵn, đã track sẵn, không cần thêm state mới ngoài `fullAscMax` (đã duyệt ở câu hỏi mở #3):

| Bước | Tên nhiệm vụ | Điều kiện | Trục năng lực đo | Nguồn dữ liệu |
|---|---|---|---|---|
| 1 | Hoàn thành Map 1 | `progress(map1) >= T(10) = 110` | Hiện diện (participation) | Đã có — `progress()` công thức #2 |
| 2 | Thắng đủ 5 trận (mọi mode/độ khó) | `META.wins >= 5` | Năng lực thắng được trận, không chỉ chơi | **Đã có, KHÔNG cần field mới** — `META.wins` tăng ở mọi lượt thắng (`client.html:4387`), chưa từng được World Tour dùng tới |
| 3 | Từng đạt Ascension 2 (mode bất kỳ) | `META.ascMax >= 2` | Trần kỹ năng, không phân biệt mode | **Đã có, KHÔNG cần field mới** — cùng dòng `client.html:4387` |
| 4 (final — mở Map 2) | Thắng 1 Full Run ở Ascension 2 trở lên | `META.fullAscMax >= 3` | Kỹ năng + bền bỉ ở mode dài | `META.fullAscMax` (đã duyệt, câu hỏi mở #3) |

`questStep(state)` (định nghĩa đầy đủ ở §Formulas #3) vẫn là một giá trị TÍNH RA từ `progress(map1)`, `META.wins`, `META.ascMax`, `META.fullAscMax` — không lưu trữ thành field riêng. `gateCleared() = (questStep(state) >= 4)`.

**Vì sao thiết kế này KHÔNG THỂ sụp thành 1 điều kiện đơn theo cùng cách v4/v5 đã sụp**: `META.ascMax` và `META.fullAscMax` cùng cập nhật trong CÙNG một lần thắng, và `fullAscMax` không bao giờ vượt quá `ascMax` (đã xác nhận tại `client.html:4387-4391` — nhánh `ascMax` luôn chạy trước nhánh `fullAscMax` trên cùng một lần thắng) — nên bước 4 đạt được LUÔN kéo theo bước 3 đã đạt, không có mâu thuẫn. Nhưng `META.wins` là một bộ đếm ĐỘC LẬP, không tỉ lệ theo độ khó — một trận thắng ngoạn mục dù ở Ascension cao đến đâu cũng chỉ cộng `wins` thêm 1. Với `W=5`, người chơi kỹ năng cao thắng ngay Full Run đầu tiên ở Ascension 2+ vẫn kẹt ở bước 2 ("còn thiếu 4 trận thắng") dù đã đủ điều kiện SỐ cho bước 4 — chuỗi giờ đòi cả **một khối lượng thắng tối thiểu** LẪN **một đỉnh kỹ năng**, không thể mua đứt toàn bộ chỉ bằng một trận đấu may/giỏi. Vẫn có thể nhảy nhiều bước cùng lúc (vd một người đã có sẵn `wins>=5` và `ascMax>=2` từ trước, lần đầu thắng Full Run Ascension 2 sẽ nhảy thẳng bước 1→4 nếu Map 1 cũng vừa xong) — đây là hành vi CHỦ Ý, chỉ khác v4/v5 ở chỗ nó đòi hỏi ĐÃ TÍCH LUỸ trước đó, không phải một sự kiện đơn lẻ mua được cả chuỗi.

**Phương án đã cân nhắc và loại bỏ — chuỗi boss cụ thể theo Ascension** (vd "hạ `agony` ở Ascension 1+", "ở Ascension 2+"): sẽ cần thêm MỘT field theo dõi mới (`META.bosses` chỉ ghi nhận đã hạ boss đó bao giờ chưa, không ghi Ascension lúc hạ), và vì `agony` chắc chắn là boss cuối của MỌI Full Run thắng, "hạ agony ở Ascension N" và "thắng Full Run ở Ascension N" về bản chất là cùng một sự kiện đổi tên — không thêm nội dung thật, chỉ thêm field phải track. Loại bỏ để giữ đúng nguyên tắc "không thêm field mới ngoài `fullAscMax` đã duyệt" nếu có cách khác đạt được đa dạng-trục mà không cần.

**Vì sao KHÔNG dùng boss cụ thể ("hạ 1 boss ở Ascension 1+") làm một bước riêng** (khác gợi ý ban đầu của product owner): giữ nguyên lý do đã nêu ở bản v4 — `gooey_king` (boss đầu Map 1) đã là điều kiện landmark của Tile 4 Map 1 (§Ô mốc), nên gần như chắc chắn đã bị hạ trước khi Bước 1 xong; thêm nó làm bước riêng không thật sự khó hơn.

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

### 3. Cổng khó giữa-map — chuỗi nhiệm vụ `questStep()` (v6 — 3 trục, thay thế bản v4/v5 dùng 1 trục `fullAscMax`)

```
questStep(state) =
  0   nếu  progress(map1) < T(10)                                     // chưa xong Map 1
  1   nếu  progress(map1) >= T(10)  AND  wins < W                     // Map 1 xong, chưa đủ số trận thắng
  2   nếu  progress(map1) >= T(10)  AND  wins >= W  AND  ascMax < 2    // đủ trận thắng, chưa từng chạm Ascension 2
  3   nếu  progress(map1) >= T(10)  AND  wins >= W  AND  ascMax >= 2  AND  fullAscMax < 3   // đủ cả 2 trục trên, chưa thắng Full Run ở Asc 2+
  4   nếu  progress(map1) >= T(10)  AND  wins >= W  AND  ascMax >= 2  AND  fullAscMax >= 3  // GATE CLEARED

W = 5   (hằng số, xem §Tuning Knobs)
gateCleared() = ( questStep(state) >= 4 )
```

`questStep()` **không phải một field lưu trữ** — tính lại mỗi lần render, giống triết lý `badgeTier()` (§Formulas #6). Cả 3 field điều kiện (`META.wins`, `META.ascMax`, `META.fullAscMax`) đều **đã có sẵn, KHÔNG field nào mới** — chỉ `META.fullAscMax` (đã duyệt ở câu hỏi mở #3) và `META.tourClaimed`/`META.tourMap2Base` (đã có từ v1) từng cần thêm field; v6 không thêm field nào nữa.

| Biến | Ý nghĩa | Miền giá trị | Ví dụ |
|---|---|---|---|
| `progress(map1)` | Số run tương đối đã tích luỹ trong Map 1 (công thức #2) | số nguyên ≥0 | `progress(map1)=109` → chưa đủ, `questStep` kẹt ở 0 bất kể 3 field còn lại |
| `T(10)` | Ngưỡng ô cuối Map 1 | hằng số = 110 | — |
| `META.wins` | Tổng số trận THẮNG cộng dồn, mọi mode/Ascension (đã có, `client.html:4387`, `META.wins++` mỗi lần `S.phase==='won'`) | số nguyên ≥0, mặc định 0 | `wins=4` → chưa đủ bước 2 dù Ascension cao thế nào |
| `W` | Ngưỡng số trận thắng cần cho bước 2 | hằng số = 5 (xem §Tuning Knobs) | — |
| `META.ascMax` | Cấp Ascension cao nhất đã từng thắng, MỌI mode (đã có, cùng dòng `client.html:4387`) | số nguyên 0-10, mặc định 0 | `ascMax=2` → đủ bước 3 |
| `META.fullAscMax` | Cấp Ascension cao nhất đã từng thắng, CHỈ mode Full (đã có, `client.html:4391`, câu hỏi mở #3 đã duyệt) | số nguyên 0-10, mặc định 0 | `fullAscMax=3` → đủ bước 4 |

**Biên giá trị**:
- `progress(map1)=109, wins=99, ascMax=10, fullAscMax=10` → `questStep=0` (Map 1 chưa xong — participation luôn là điều kiện tiên quyết, bất kể 3 field còn lại cao thế nào).
- `progress(map1)=110, wins=4, ascMax=10, fullAscMax=10` → `questStep=1` (**ca kiểm thử trọng tâm**: dù đã đủ điều kiện SỐ cho bước 4 ở 2 trục kia, thiếu đúng 1 trận thắng vẫn kẹt ở bước 1 — đây chính là hành vi mới thay thế lỗi "sụp thành 1 điều kiện" của v4/v5).
- `progress(map1)=110, wins=5, ascMax=1, fullAscMax=0` → `questStep=2` (đủ trận thắng, nhưng chưa từng chạm Ascension 2).
- `progress(map1)=110, wins=5, ascMax=2, fullAscMax=1` → `questStep=3` (đủ 2 trục đầu, còn thiếu thắng Full Run ở Ascension 2+).
- `progress(map1)=110, wins=5, ascMax=2, fullAscMax=3` → `questStep=4` → `gateCleared()=true` — Map 2 mở khoá, `base(map2)` snapshot (không đổi cơ chế so với v4).
- `progress(map1)=110, wins=50, ascMax=10, fullAscMax=10` → vẫn `questStep=4` (không có bước 5).
- **Nhảy nhiều bước hợp lệ**: một người chơi đã có sẵn `wins>=5` và `ascMax>=2` từ trước (nhờ chơi Short Run nhiều), lần đầu tiên thắng Full Run đã ở Ascension 2+ → nhảy thẳng bước 1→4 (nếu Map 1 cũng vừa xong cùng lúc). Khác v4/v5 ở chỗ: điều này đòi hỏi ĐÃ TÍCH LUỸ `wins`/`ascMax` từ trước qua nhiều trận, không mua được chỉ bằng đúng một trận đấu — xem §Detailed Rules để so sánh với lỗi đã sửa.

### 4. Điều kiện landmark trong-map — không đổi dạng so với bản v1

```
eligible(tile) = ( progress(tile.map) >= T(tile.idx) ) AND ( tile.landmarkCond ? tile.landmarkCond(META) : true )
```

### 5. Phần thưởng — vẫn không có công thức (tra bảng tĩnh), đây vẫn là điểm mấu chốt thiết kế

Không đổi từ bản v1: không roll, không RNG, không tỉ lệ hiếm. Việc "không có formula" ở đây vẫn là bằng chứng thiết kế cho yêu cầu deterministic.

### 6. Cấp huy hiệu hoàn thành map — `badgeTier(map)` (mới, v3; sửa v5 — xem Câu hỏi mở #3, ĐÃ ĐÓNG)

```
badgeTier(map) = 'none'    nếu progress(map) < T(10)
badgeTier(map) = 'silver'  nếu progress(map) >= T(10)  AND  fullAscMax <  goldThreshold(map)
badgeTier(map) = 'gold'    nếu progress(map) >= T(10)  AND  fullAscMax >= goldThreshold(map)

goldThreshold(map1) = 3
goldThreshold(map2) = 5
```

| Biến | Ý nghĩa | Miền giá trị | Ví dụ |
|---|---|---|---|
| `progress(map)` | Công thức #2, số run tương đối đã tích luỹ trong map đó | số nguyên ≥0 | `progress(map1)=110` → đủ Silver |
| `goldThreshold(map)` | Ngưỡng `fullAscMax` cần để lên Gold, riêng theo từng map | hằng số: map1=3, map2=5 | — |
| `fullAscMax` | `META.fullAscMax` (v5: đổi từ `ascMax`, xem Câu hỏi mở #3 ĐÃ ĐÓNG) | số nguyên 0-10 | `fullAscMax=2` → Silver, chưa Gold (map1) |

**Biên giá trị**: `progress(map1)=109, fullAscMax=10` → `'none'` (chưa đủ participation, bất kể fullAscMax cao thế nào). `progress(map1)=110, fullAscMax=2` → `'silver'`. `progress(map1)=110, fullAscMax=3` → `'gold'`. `progress(map2)=110, fullAscMax=4` → `'silver'` (đủ cho Gold map1 nhưng CHƯA đủ cho Gold map2, vì `goldThreshold` khác nhau theo map — không dùng chung một hằng số). `progress(map2)=110, fullAscMax=5` → `'gold'`.

**v5 (2026-09-08)**: đổi từ `ascMax` sang `fullAscMax` theo quyết định product owner ở Câu hỏi mở #3 (option a) — badge giờ LUÔN đồng nghĩa với cổng Map2 thật (cả hai cùng đọc `fullAscMax`), đánh đổi: badge Gold Map1 giờ khó đạt hơn bản v3/v4 (cần thắng Full Run, không còn tính Short Run).

## Edge Cases

- **Người chơi cũ, `META.runs` đã rất lớn khi tính năng ra mắt** (vd 180 run có sẵn): Map 1 dùng `base=0` nên vẫn thấy nhiều ô đã đủ điều kiện ngay (đúng như bản v1) — CLAIM ALL xử lý việc này trong Map 1. **Map 2 KHÔNG bị ảnh hưởng bởi lịch sử `META.runs` cũ** vì `base(map2)` chỉ được snapshot tại đúng thời điểm vượt cổng, không phải tại thời điểm feature ra mắt — một veteran vẫn phải tích luỹ đúng 110 run MỚI sau khi vượt cổng để hoàn thành Map 2, không được "miễn phí" nhờ lịch sử chơi trước đó. Đây là hành vi CHỦ ĐÍCH, ngăn việc baseline tuyệt đối biến Map 2 thành vô nghĩa.
- **Người chơi đang ở GIỮA chuỗi nhiệm vụ (`questStep` 1, 2, hoặc 3)** (v6 — thay thế hoàn toàn bảng thông báo của v4/v5): màn chọn chương KHÔNG được chỉ hiện "còn khoá" chung chung — PHẢI hiện rõ **ĐANG Ở BƯỚC NÀO trong 4 bước** VÀ **bước đó cần gì để qua bước kế tiếp**, đúng bảng ở §Detailed Rules:
  - `questStep=0` → "Hoàn thành Map 1 (còn X ô nữa)".
  - `questStep=1` → "Bước 1/3 xong. Cần: Thắng đủ 5 trận (còn thiếu {5-wins} trận)".
  - `questStep=2` → "Bước 2/3 xong. Cần: Từng đạt Ascension 2 (mode bất kỳ)".
  - `questStep=3` → "Bước 3/3 xong. Cần: Thắng 1 Full Run ở Ascension 2 trở lên — mở Map 2!".
  Đây là trạng thái được kỳ vọng tồn tại lâu dài với phần lớn playerbase (đủ 5 trận thắng không tầm thường với người chơi mới, Ascension 2 cần thời gian tích luỹ), không phải lỗi. Không được gộp 4 bước thành một câu duy nhất kiểu "cần thắng Full Run ở Ascension 2" khi player đang ở bước 1 — phải luôn hiện ĐÚNG bước kế tiếp, không nhảy cóc thông báo trước khi player đạt bước liền trước.
- **`ascMax`/`fullAscMax` đã cao từ trước (nhờ nhảy nhiều bước) nhưng `wins` CHƯA đủ** (v6, **ca kiểm thử trọng tâm của thiết kế mới** — đây chính là lỗ hổng mà v6 sửa so với v4/v5): một người chơi kỹ năng rất cao có thể đã đạt `ascMax=10`/`fullAscMax=10` chỉ sau vài trận, nhưng nếu `wins<5` thì `questStep` vẫn kẹt ở bước 1, thông báo phải nói đúng lý do còn thiếu là **số trận thắng** ("Thắng đủ 5 trận"), KHÔNG nói "cần đạt Ascension cao hơn" (đã đủ từ trước) — theo đúng định nghĩa `questStep()` ở §Formulas #3 (bước 1 kiểm `wins` trước, độc lập với `ascMax`/`fullAscMax`).
- **`fullAscMax` đã cao từ trước (nhờ nhảy cóc) nhưng Map 1 CHƯA xong** (không đổi từ v4 — vd người chơi kỹ năng cao nhưng ít run, hiếm nhưng có thể): `questStep` kẹt ở 0 cho tới khi `progress(map1)>=T(10)`, thông báo phải nói đúng lý do còn thiếu là **participation** ("Hoàn thành nốt Map 1"), KHÔNG nói "cần thắng thêm trận"/"cần Ascension cao hơn" (có thể đã đủ từ trước) — participation luôn là điều kiện tiên quyết của bước 1, độc lập với 3 field còn lại.
- **Hoàn thành CẢ 2 map** (Map 1 claim hết + Map 2 claim hết): màn hình chọn chương hiện một thẻ Map 3 ở trạng thái tĩnh, khoá, với nội dung cụ thể: tiêu đề **"Chương tiếp theo — Sắp ra mắt"**, mô tả ngắn kiểu "Bạn đã hoàn thành toàn bộ World Tour hiện có. Chương mới sẽ được thêm trong bản cập nhật sau." — không để trống, không hiện lỗi, không hiện số ngưỡng giả (vì map 3 chưa tồn tại, không có T(i) nào để tính). Hai map đã hoàn thành vẫn xem lại được (đường đi + item đã nhận), không bị ẩn.
- **`META.runs` không bao giờ giảm** (không đổi từ bản v1) → cả `progress(map1)` và `progress(map2)` (sau khi có baseline) đều không thể tụt lùi.
- **Ô landmark đủ ngưỡng T(i) nhưng chưa đủ điều kiện phụ** (không đổi từ bản v1, áp dụng riêng cho từng landmark của từng map — vd Map 1 tile 4 đủ run nhưng chưa từng hạ `gooey_king` vì luôn bỏ dở trước wave 4/5): hiện rõ ĐANG THIẾU GÌ, không chỉ nói "chưa đủ điều kiện".
- **Badge tự nâng cấp Silver→Gold không cần hành động của player** (mới, v3): vì `badgeTier()` tính lại mỗi lần render màn chọn chương (không lưu trạng thái badge), một player đã có Silver ở Map 1 rồi sau đó thắng thêm một Full Run ở Ascension 2 (đạt `fullAscMax=3`, v5) sẽ thấy badge chuyển thẳng sang Gold ở lần mở màn hình tiếp theo — không có màn "chúc mừng lên Gold" riêng trong bản v1 này (chỉ badge đổi icon lặng lẽ); nếu cần một khoảnh khắc ăn mừng rõ ràng hơn, đây là điểm `ux-designer` có thể bổ sung ở bản sau, không phải yêu cầu bắt buộc của v1.
- **Veteran đã đạt `fullAscMax>=5` (đủ Gold cả 2 map, v5) TRƯỚC KHI claim hết ô của map đó**: `badgeTier()` vẫn trả về `'none'` cho tới khi `progress(map) >= T(10)` — fullAscMax cao không "miễn" điều kiện participation của Silver, đúng công thức #6 (điều kiện AND, không phải OR).
- **Claim hai lần cùng một ô** (không đổi nguyên tắc từ bản v1, nhưng khoá định danh ô đổi format): `META.tourClaimed` giờ cần định danh CẢ map lẫn ô để không nhầm "tile 4 của Map 1" với "tile 4 của Map 2" — đề xuất định dạng chuỗi composite `"1:4"`/`"2:4"` thay vì số nguyên đơn thuần như bản v1. `tourClaim(mapIdx, tileIdx)` kiểm tra `META.tourClaimed.includes(`${mapIdx}:${tileIdx}`)` trước khi cấp thưởng.
- **Đồng bộ nhiều thiết bị**: không đổi nguyên tắc từ bản v1 (dùng cơ chế merge `META` hiện có) — nhưng giờ CŨNG cần đảm bảo `base(map2)` (một số nguyên nullable, không phải mảng) được đồng bộ đúng, nếu không hai thiết bị có thể snapshot `base(map2)` tại hai thời điểm khác nhau và cho ra 2 giá trị khác nhau cho cùng người chơi — cần lead-programmer xác nhận thứ tự ưu tiên khi merge (dùng giá trị NHỎ HƠN, tức baseline sớm hơn/có lợi hơn cho người chơi, hay giá trị từ cloud luôn thắng theo pattern hiện tại). **`META.fullAscMax` (field mới, v4) merge theo đúng pattern đã dùng cho `META.ascMax`** (lấy giá trị LỚN HƠN giữa 2 thiết bị — monotonic, không bao giờ giảm) — không cần quy tắc merge mới, chỉ áp dụng lại quy tắc sẵn có cho một field cùng kiểu dữ liệu (số nguyên 0-10, tăng dần).
- **Vật phẩm "độc quyền Tour" lỡ bị thêm nhầm vào `COSMETIC_POOLS`** (không đổi từ bản v1): vẫn cần unit test khẳng định tập 3 item độc quyền không giao với bất kỳ pool nào, chạy trong `tools/ci.mjs`.

## Dependencies

| Hệ thống | Quan hệ | Hướng dữ liệu |
|---|---|---|
| `META` object | Cần `tourClaimed:[]` (mảng chuỗi composite `"map:tile"`), `tourMap2Base:null` (số nguyên nullable, snapshot một lần), và `fullAscMax:0` (đã có trong `DEF_META`, câu hỏi mở #3 đã duyệt) — **v6 không thêm field nào nữa**: bước 2/3 của chuỗi (§Tầng 2) dùng `META.wins`/`META.ascMax`, cả hai đã tồn tại sẵn trong `DEF_META` từ trước World Tour. Đọc `META.runs`, `META.wins`, `META.bosses`, `META.ascMax`, `META.fullAscMax` làm điều kiện mở ô VÀ điều kiện chuỗi nhiệm vụ cổng khó. | World Tour ĐỌC 5 field (toàn bộ đã có sẵn), GHI 2 field mới (`tourClaimed`/`tourMap2Base`) |
| Run lifecycle (`client.html:3909` `META.runs++`, `:4368` `META.bosses.push`, `:4387` `META.wins++`/`META.ascMax`, `:4391` `META.fullAscMax` — **số dòng đã xác minh lại 2026-09-08, bản v4/v5 trước đó ghi sai số dòng `:3402`/`:3861`/`:3869`, đã lệch do các commit sau đó**) | **Đã implement đầy đủ, không cần sửa thêm cho v6**: `META.wins++` và `META.ascMax` cập nhật cùng dòng `:4387`; `META.fullAscMax` cập nhật ở nhánh kế tiếp `:4391` (`if(S.mode==='full'){...}`, chạy SAU nhánh `ascMax` trong cùng một lần thắng — thứ tự này là lý do `fullAscMax` không bao giờ vượt `ascMax`, xem §Detailed Rules/Tầng 2). v6 chỉ cần sửa `tourQuestStep()` (`client.html:4417-4424`, hiện vẫn chạy logic v4/v5 cũ) để đọc 3 field theo công thức mới ở §Formulas #3 — không chạm run lifecycle. | Một chiều — World Tour giờ chỉ ĐỌC, không cần run lifecycle ghi thêm gì mới |
| `cosmetics.js` | Cần ≥3 item MỚI độc quyền (landmark), không đưa vào `COSMETIC_POOLS`. Tỉ lệ độc quyền/tái dùng cho ô thường TBD (xem §Detailed Rules) | Hai chiều, không đổi từ bản v1 |
| `data.js` `BOSSES`/`BOSS_ORDER_12`/`BOSS_ORDER_20`/`BOSS_ALT`, và `ASCENSION` (dùng cho chuỗi nhiệm vụ cổng khó) | Landmark tile 4/Map1 và tile cuối/Map2 đọc `META.bosses`. `badgeTier()` (v5) đọc `META.fullAscMax`. **Chuỗi nhiệm vụ (`questStep()`, v6) đọc CẢ 3 field `META.wins`/`META.ascMax`/`META.fullAscMax`** — nếu logic cập nhật bất kỳ field nào trong 3 field này đổi trong tương lai (vd thêm mode mới, đổi công thức `ascMax`), cả `questStep()` lẫn `badgeTier()` cần được xét lại vì chia sẻ nguồn dữ liệu | Một chiều nhưng giòn — v6 tăng số field `questStep()` phụ thuộc từ 1 lên 3 so với v4/v5, đổi lại loại bỏ được lỗi sụp-thành-1-điều-kiện (đánh đổi có chủ đích, xem §Detailed Rules/Tầng 2) |
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
| Số bước trong chuỗi nhiệm vụ cổng khó (hiện: 4 — participation + 3 trục khác nhau, v6) | **Gate knob** | 3-5 (dưới 3 thì gần như quay lại 1 điều kiện đơn, mất cảm giác "chuỗi"; trên 5 thì UI mid-chain dễ gây mệt mỏi, mỗi bước cần message riêng) | 4 giữ đúng khuyến nghị "3-5 bước" của product owner ở cận trên vừa phải — đủ cảm giác hành trình mà không cần quá nhiều màn thông báo trạng thái. **v6**: 4 bước giữ nguyên số lượng nhưng đổi CHẤT — mỗi bước giờ đo một trục năng lực khác nhau (participation/wins/ascMax/fullAscMax) thay vì 3 ngưỡng chồng trên cùng 1 field, sửa đúng lỗi khiến v4/v5 bị từ chối |
| `W` — ngưỡng `META.wins` cho bước 2 (hiện: 5) | **Gate knob, MỚI v6** | 3-15 (dưới 3 gần như luôn đúng ngay khi Map 1 xong, mất ý nghĩa là một bước riêng vì Map 1 tự nó đã cần nhiều run hơn 3 trận thắng; trên 15 có thể khiến bước 2 trở thành nút thắt lâu hơn cả bước 3-4 cộng lại, lệch trọng số) | **5 là giá trị CHƯA qua đo đạc bằng dữ liệu thật** (dự án chưa có telemetry số trận thắng trung bình trước khi hoàn thành Map 1) — chọn dựa trên trực giác "đủ để chứng minh có thể thắng lặp lại, không phải một lần ăn may", cần xác nhận lại bằng playtest hoặc `tools/sim.js` trước khi khoá cứng |
| Ngưỡng `META.ascMax` cho bước 3 (hiện: 2) | **Gate knob** | Hẹp hơn các knob khác một cách có chủ đích: phải > 1 (trùng landmark `ascMax>=1` sẵn có ở Map 1 tile 10, nếu bằng sẽ không phải một bước mới) và phải < 3 (bước 4 đã ngầm định `ascMax>=2` vì `fullAscMax<=ascMax`, nên bước 3 phải thấp hơn ngưỡng bước 4 mới có ý nghĩa là một bước tuần tự riêng) — trên thực tế **chỉ có giá trị nguyên 2 thoả cả hai ràng buộc** | 2 là giá trị duy nhất hợp lệ với các ràng buộc đã nêu, không phải một lựa chọn trong dải rộng như các knob khác |
| `goldThreshold`/`fullAscMax` ngưỡng bước 4 (hiện: 3, không đổi từ v3/v4/v5) | **Gate knob** | 2-6 (dưới 2 trùng landmark `ascMax>=1`; trên 6 rất ít người chơi đạt Full Run ở Ascension đó, có thể khoá Map 2 mãi mãi với phần lớn playerbase) | Giữ nguyên giá trị số 3 từ gate đơn của v3 (đã hợp lý, xem lý do cũ) — v6 không đổi ngưỡng cuối, chỉ đổi ĐƯỜNG ĐI 3 bước trước đó |
| Vị trí landmark trong mỗi map (hiện: tile 4 & 10 ở Map 1; tile 10 ở Map 2) | **Gate knob** | Chỉ gắn vào field không có nhánh RNG | Không đổi lý do từ bản v1; vị trí Map 2 có thể cần xê dịch theo bố cục art thật |
| Tỉ lệ item độc quyền / tái dùng cho ô THƯỜNG | **Gate knob** | **TBD — chưa chốt, không có giá trị mặc định trong bản này** | Theo yêu cầu product owner: để quyết định sau, không khoá cứng trong revision này |
| Nút CLAIM ALL — animation riêng theo từng item | **Feel knob** | — | Không đổi từ bản v1 |
| `goldThreshold(map1)` (hiện: 3, = trùng cổng Map1↔Map2) | **Gate knob** | Nên giữ bằng đúng ngưỡng cổng Map1→Map2 để badge phản ánh đúng ý nghĩa "đủ điều kiện mở map sau" — nếu tách rời 2 giá trị, cần lý do rõ ràng | Trùng cổng khó theo chủ đích, tái dùng một ngưỡng cho hai mục đích, tránh 2 con số dễ lệch nhau khi tuning về sau |
| `goldThreshold(map2)` (hiện: 5, capstone) | **Gate knob** | 4-8 (phải LỚN HƠN `goldThreshold(map1)=3` để giữ thang 3 bậc có ý nghĩa; trên 8 rủi ro gần như không ai đạt Gold map cuối) | 5 tạo khoảng cách đều với bậc `1→3` trước đó (landmark map1 → cổng/gold map1 → gold map2), vẫn nằm trong thang 0-10 Ascension hiện có |

## Acceptance Criteria

**Functional (tự động hoá được):**
1. `DEF_META.tourClaimed` mặc định `[]`; `DEF_META.tourMap2Base` mặc định `null`; `DEF_META.fullAscMax` mặc định `0`, cho tài khoản mới.
2. **(SỬA, v6 — thay thế phép kiểm 1-trục `fullAscMax` của v4/v5)** Cho trước `progress(map1)`, `META.wins`, `META.ascMax`, `META.fullAscMax` bất kỳ, `questStep()` phải khớp chính xác công thức 3-trục ở §Formulas #3 tại các giá trị biên: `progress=109,wins=99,ascMax=10,fullAscMax=10→questStep=0` (participation luôn chặn trước) · `progress=110,wins=4,ascMax=10,fullAscMax=10→questStep=1` (**ca bắt buộc**: đủ điều kiện số ở 2 trục kia nhưng thiếu đúng 1 trận thắng vẫn kẹt bước 1 — đây là test trực tiếp xác nhận lỗi v4/v5 đã được sửa, không được phép fail) · `progress=110,wins=5,ascMax=1,fullAscMax=0→questStep=2` · `progress=110,wins=5,ascMax=2,fullAscMax=1→questStep=3` · `progress=110,wins=5,ascMax=2,fullAscMax=3→questStep=4` (=`gateCleared()`).
2b. **(v4, giữ nguyên tinh thần ở v6)** `questStep()` không bao giờ "nhảy lùi": cho trước một chuỗi giá trị `wins`/`ascMax`/`fullAscMax` tăng dần theo thời gian, `questStep()` tính lại mỗi lần cũng phải tăng dần hoặc giữ nguyên, không bao giờ giảm — kể cả khi `progress(map1)` đạt ngưỡng SAU khi 3 field kia đã cao sẵn (trường hợp "nhảy nhiều bước" nêu ở §Edge Cases, `questStep` phải nhảy thẳng lên giá trị đúng theo 3 field hiện có ngay khi participation vừa đủ, không kẹt ở 1 rồi tăng dần từng bước một cách giả tạo).
3. Khi `questStep()` đạt 4 (`gateCleared()=true`) lần đầu, `META.tourMap2Base` được gán đúng MỘT LẦN bằng giá trị `META.runs` hiện tại; các lần đánh giá sau đó (kể cả khi `META.runs` tiếp tục tăng) không ghi đè lại giá trị đã snapshot.
3b. **(MỚI, v4)** Cho một run vừa thắng với `S.mode==='full'` và `S.asc` bất kỳ, `META.fullAscMax` cập nhật đúng công thức mirror ở §Detailed Rules/Tầng 2 (`if(S.asc>=fullAscMax && fullAscMax<10) fullAscMax=min(10,S.asc+1)`) — và **không cập nhật** khi `S.mode==='short'` dù `S.asc` cao đến đâu (test âm: thắng Short Run ở Ascension 5 không làm `fullAscMax` nhúc nhích).
4. Trong một map, cho trước `META.runs`/`META.bosses`/`META.ascMax` bất kỳ, ô đủ điều kiện phải khớp bảng ngưỡng `T(i)` tại các giá trị biên tương tự bản v1 (N=1 không ô nào mở, N=2 đúng ô 1 mở, v.v., áp dụng riêng cho từng map với baseline tương ứng).
5. Claim một ô cấp ĐÚNG MỘT vật phẩm cố định; claim lại ô đã claim là no-op — không cấp trùng.
6. 3 item độc quyền landmark không xuất hiện trong bất kỳ `COSMETIC_POOLS[cat]` nào — kiểm bằng test tự động trong `tools/ci.mjs`.
7. `META.tourClaimed` (định dạng composite mới) và `META.tourMap2Base` đều có mặt trong payload sync.
8. **(SỬA, v5 — thay `ascMax` bằng `fullAscMax`, xem Câu hỏi mở #3 ĐÃ ĐÓNG)** `badgeTier(map)` khớp chính xác công thức ở §Formulas #6 tại các giá trị biên: `progress=109,fullAscMax=10→'none'` · `progress=110,fullAscMax=2→'silver'` (map1) · `progress=110,fullAscMax=3→'gold'` (map1) · `progress=110,fullAscMax=4→'silver'` (map2, chưa đạt ngưỡng 5) · `progress=110,fullAscMax=5→'gold'` (map2).

**Experiential (playtest xác nhận):**
9. Người chơi mới thấy VÀ claim được ít nhất ô 1 của Map 1 trong phiên chơi đầu tiên (≤20 phút) mà không cần hướng dẫn.
10. **(SỬA, v6)** Người chơi vừa hoàn thành Map 1 nhưng đang ở bất kỳ bước 1-3 nào của chuỗi (thiếu `wins`, thiếu `ascMax>=2`, hoặc thiếu `fullAscMax>=3`) mô tả đúng LÝ DO CỤ THỂ CỦA BƯỚC ĐÓ bằng lời của họ (không cần thuật ngữ thiết kế, và không nhầm lẫn giữa 3 lý do khác nhau) — xác nhận thông báo lý do khoá đủ rõ ràng VÀ đủ phân biệt giữa các bước, không gây cảm giác "bí ẩn không lối thoát".
11. **(TĂNG CƯỜNG, v6)** Người chơi vừa vượt cổng khó lần đầu (chuyển sang Map 2) mô tả cảm giác là "vừa đạt được một cột mốc thật" chứ không phải "chỉ là chờ đủ số" — VÀ khi được hỏi lại, kể được ÍT NHẤT 2 LOẠI thử thách khác nhau họ phải vượt qua (vd "phải thắng đủ nhiều trận" VÀ "phải lên tới Ascension cao"), không chỉ nhắc lại một con số Ascension duy nhất — xác nhận chuỗi 3-trục (v6) thực sự được cảm nhận là đa dạng, không phải một thử thách lặp lại 3 lần dưới tên khác nhau.
12. Người chơi hoàn thành cả 2 map thấy màn "Chương tiếp theo — Sắp ra mắt" và mô tả cảm giác là "còn tiếp, không phải hết game" — không mô tả là lỗi hoặc màn hình trống.
13. Người chơi đạt Silver trên một map mô tả đúng nó là "đã xong map" và phân biệt được bằng lời của họ rằng Gold là "khó hơn, cần thắng ở độ khó cao" — xác nhận badge 2 cấp truyền tải đúng ý nghĩa participation-vs-skill mà không cần đọc tooltip.

---

## Câu hỏi mở cần Product Owner/Lead xác nhận (v4 — cập nhật sau khi đổi tên map + thiết kế lại cổng khó thành chuỗi nhiệm vụ)

1. ~~Cần xem `Map2-new.png`~~ / ~~"World Map Selection.PNG"~~ / ~~Tên chính thức 2 map~~ — **ĐÃ XÁC NHẬN cả 3** ở các bản trước: 10 ô/map giữ nguyên, wireframe đã tích hợp đủ vào §Detailed Rules, tên map là **"Lovely Forest I"/"Lovely Forest II"** (product owner chốt, thay đề xuất "Olek Grove"/"Puffy Lagoon" cũ).
2. **Xác nhận chuỗi nhiệm vụ 4 bước — ĐÃ ĐÓNG (2026-09-08, bản v6)**: product owner từ chối đề xuất v4/v5 (4 bước cùng dùng `fullAscMax`, xem lý do sụp-thành-1-điều-kiện ở §Detailed Rules/Tầng 2). Đề xuất thay thế của game-designer: vẫn 4 bước, nhưng qua **3 trục khác nhau** — Map 1 xong → `wins>=5` → `ascMax>=2` → `fullAscMax>=3` (không field mới nào ngoài `fullAscMax` đã duyệt). Xem §Detailed Rules/Tầng 2, §Formulas #3, §Edge Cases, §Tuning Knobs, §Acceptance Criteria AC-2/2b/10/11 đã cập nhật theo bản v6 này. **Còn chờ**: product owner xác nhận đồng ý bản v6, và `W=5` (ngưỡng `wins` bước 2) là giá trị trực giác chưa qua đo đạc — có thể cần chỉnh sau khi có dữ liệu thật (xem §Tuning Knobs).
3. **(v4) Lệch giữa badge Gold Map1 và cổng khó thật — ĐÃ ĐÓNG (2026-09-08)**: product owner chọn **(a)** — `badgeTier()` đổi sang đọc `META.fullAscMax` (khớp tuyệt đối với cổng Map2), xem §Formulas #6 (v5) và AC-8 (v5) đã cập nhật. Đã sửa `src/client.html` (`tourBadgeTier()`) và `src/data.js` (comment `TOUR_GOLD_THRESHOLD`).
4. **Field `META.fullAscMax` — ĐÃ ĐÓNG, đã xác nhận implement đúng (2026-09-08)**: xác minh trực tiếp trong `client.html` — cập nhật ở dòng `:4391` (`if(S.mode==='full'){...}`), chạy ngay sau nhánh `META.ascMax` ở dòng `:4387` trong cùng khối `if(S.phase==='won')`, không có race condition (cùng một lần thắng, tuần tự, không bất đồng bộ). World Tour hiện đã implement đầy đủ trong code (không chỉ trên giấy) — việc còn lại là cập nhật `tourQuestStep()` (`client.html:4417-4424`) theo công thức v6 mới ở §Formulas #3, hiện vẫn chạy logic v4/v5 cũ.
