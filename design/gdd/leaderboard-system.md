# Leaderboard System

> **Status**: In Design
> **Author**: Claude Code (2026-09-01), theo yêu cầu product owner
> **Last Updated**: 2026-09-01
> **Implements Pillar**: Minh bạch triệt để — mở rộng sang cạnh tranh: thứ hạng phải minh bạch và không thể gian lận bằng thủ thuật client, cùng tinh thần với "không giấu thông tin trong combat".
> **Quyết định kiến trúc đi kèm**: đây là hệ thống ĐẦU TIÊN của dự án cần backend/server — khác với kiến trúc "1 file HTML, không server" hiện tại (`.claude/docs/technical-preferences.md`). Product owner đã xác nhận chấp nhận thêm backend nhẹ (2026-09-01). **Cần `/architecture-decision` riêng** để ghi ADR chính thức trước khi implement — doc này chỉ là spec thiết kế/gameplay.

## Overview

Hệ thống bảng xếp hạng cho phép người chơi so sánh thành tích với nhau, dùng chính seed xác định (deterministic) đã có sẵn trong engine để xác thực điểm số mà không cần hệ chống gian lận phức tạp: server re-simulate lại đúng log hành động của client bằng `src/engine.js` (giống cách `tools/sim.js` đã chạy headless), chỉ chấp nhận điểm nếu kết quả khớp.

## Player Fantasy

"Điểm số của tôi là thật — không ai âm thầm chỉnh sửa để leo hạng." Người chơi tin vào bảng xếp hạng theo đúng cách họ tin vào intent địch hiển thị công khai trong combat: vì hệ thống *chứng minh được* nó đúng, không phải vì được yêu cầu tin.

## Detailed Rules

### Core Rules — Loại bảng xếp hạng

Theo quyết định 2026-09-01, **2 bảng song song** cho mỗi tổ hợp (mode, ascension):

| Bảng | Điều kiện đội hình | Mục đích |
|---|---|---|
| **Standard** | Đội hình tuyển 100% ngẫu nhiên giữa run (không dùng quyền chọn-trước NFT) | Đo kỹ năng thuần, ai cũng như nhau |
| **Collector** | Có dùng quyền chọn-trước Axie NFT (§G8, `AUDIT_AND_SPEC_v1.md`) ở bất kỳ mức độ nào | Đo thành tích của người sở hữu NFT, tách khỏi Standard để không làm loãng ý nghĩa "ai cũng như nhau" |

Một run tự động gắn nhãn Standard hay Collector tại thời điểm bắt đầu (dựa trên việc người chơi có dùng slot chọn-trước NFT nào không), không đổi được giữa chừng.

### Core Rules — Trục xếp hạng

Xếp theo **(mode, ascension)** riêng biệt — không gộp Short/Full hay các mức Ascension khác nhau vào cùng một bảng, vì độ khó khác nhau khiến điểm không so sánh được. Tổng cộng: 2 mode × 11 mức Ascension (0-10) × 2 bảng (Standard/Collector) = 44 bảng con. Trang chủ leaderboard mặc định hiện bảng (mode, ascension) mà người chơi vừa chơi gần nhất.

### Core Rules — Loại xếp hạng theo thời gian

- **Daily** (theo `DAILY-YYYY-MM-DD` seed đã có sẵn trong `src/ui.js`): mọi người chơi cùng seed đó trong ngày, thứ hạng reset mỗi ngày UTC.
- **All-time**: điểm cao nhất mọi thời điểm, không giới hạn seed — người chơi seed tự chọn hoặc ngẫu nhiên.
- Daily và All-time là 2 view riêng của cùng dữ liệu server, không nhân đôi số bảng con.

### Core Rules — Công thức điểm (Score)

**Tái dùng nguyên công thức XP của Lunacia Pass** (`game-concept.md` Formulas #4) làm Score — không phát minh công thức mới, tránh hai con số cạnh tranh ý nghĩa với nhau:

```
Score = 30 + 10×wave_vượt_qua + 30×Elite + 60×Boss + 150×(nếu thắng) + 25×Ascension + 40×(nếu Full Run)
```

### Core Rules — Nộp điểm & xác thực (anti-cheat qua deterministic replay)

```
1. CLIENT chơi hết run (thắng hoặc thua), ghi lại action log đầy đủ:
   {seed, teamKeys, mode, ascension, nftPreselect[], actions: [{type, uid, tgtUid, ...}, ...]}
   — đây chính là chuỗi lệnh gọi playerUseDie/doReroll/endTurn/... mà engine.js đã nhận trong lúc chơi.
2. CLIENT gửi log này (KHÔNG gửi Score tính sẵn) lên server.
3. SERVER re-run engine.js (Node, headless — kiến trúc y hệt tools/sim.js đã có) với đúng seed +
   action log đó, tự tính lại toàn bộ trận đấu và ra Score từ kết quả THẬT của lần replay.
4. SERVER chỉ ghi nhận Score tự tính được — không bao giờ tin Score client gửi lên.
5. Nếu replay lỗi (action không hợp lệ ở bước nào đó theo đúng luật engine.js) → từ chối, không ghi điểm.
```

Vì `engine.js` đã là pure function, seeded, không đụng DOM (xem `docs/axiedice-source/ORIGINAL_PROJECT_CLAUDE.md` §3 "Ranh giới engine ↔ UI"), server không cần viết lại logic game — dùng thẳng `src/engine.js` trong môi trường Node, đúng cách `tools/sim.js` đã chứng minh khả thi.

## Formulas

Không có formula mới ngoài Score (tái dùng công thức Pass ở trên). Xem `game-concept.md` Formulas #4 cho bảng biến số đầy đủ.

## Edge Cases

- **Action log quá dài / spam request**: giới hạn kích thước log hợp lý (một run dài nhất — Full Run Ascension 10 — có trần số lượt hữu hạn vì `s.turn>45` là điều kiện thua ở `tools/sim.js`; áp dụng giới hạn tương tự phía server, từ chối log vượt ngưỡng).
- **Client mất kết nối giữa chừng khi đang nộp điểm**: không ảnh hưởng gameplay local (run đã chơi xong offline-first); chỉ retry nộp log, không cần giữ session server trong lúc chơi.
- **Hai người chơi có cùng Score tuyệt đối**: tiebreak theo thời gian nộp sớm hơn (giữ nguyên tinh thần "ai làm được trước" thay vì random).
- **Người chơi đổi từ Standard sang Collector giữa mùa** (mua thêm NFT giữa chừng): chỉ ảnh hưởng các run MỚI sau khi mua; run cũ giữ nguyên nhãn bảng đã nộp, không hồi tố.
- **Seed Daily bị lộ/chia sẻ trước khi ngày đó thật sự bắt đầu** (múi giờ): dùng UTC cố định cho ngưỡng đổi ngày, tránh người chơi múi giờ khác chơi seed "ngày mai" sớm hơn.
- **Replay không khớp do version engine.js đổi giữa lúc chơi và lúc server xử lý** (deploy mới giữa chừng): server phải versioning engine.js theo build, chỉ replay bằng đúng phiên bản engine tại thời điểm seed được tạo — nếu không, patch cân bằng (như `docs/balance-log.md` 2026-09-01) sẽ làm mọi log cũ replay ra điểm khác, từ chối oan.

## Dependencies

| Hệ thống | Quan hệ |
|---|---|
| `game-concept.md` (Lunacia Pass, Formulas #4) | Leaderboard Score tái dùng nguyên công thức XP — không có formula riêng |
| `AUDIT_AND_SPEC_v1.md` §G8 (NFT hybrid) | Quyết định tách bảng Standard/Collector xuất phát trực tiếp từ đây |
| `economy-progression.md` §12.2 | Đã có kế hoạch phân đoạn Gauntlet/leaderboard theo Ascension từ trước — leaderboard này hiện thực hoá đúng kế hoạch đó |
| `docs/axiedice-source/ORIGINAL_PROJECT_CLAUDE.md` §2-3 (kiến trúc build, ranh giới engine/UI) | Anti-cheat dựa thẳng vào việc `engine.js` đã pure/deterministic — nếu ranh giới này bị phá (engine đụng DOM/side-effect), replay verification không còn đáng tin |
| `tools/sim.js` | Bằng chứng khả thi kỹ thuật — server chỉ cần chạy lại đúng cách `sim.js` đã làm, không viết engine riêng |
| **Cần mới**: ADR cho lựa chọn backend cụ thể (serverless function, DB nhẹ) | Chưa có — phải chạy `/architecture-decision` trước khi implement |

## Tuning Knobs

| Knob | Giá trị đề xuất | Ảnh hưởng |
|---|---|---|
| Số dòng leaderboard hiển thị (top-N) | 100 | Quá nhỏ → người chơi trung bình không thấy mình đâu; quá lớn → tải chậm |
| Giới hạn độ dài action log chấp nhận | theo trần lượt (turn>45/run, nhân với số wave tối đa) | Chặn spam mà không chặn nhầm run hợp lệ |
| Ngưỡng đổi ngày Daily seed | UTC 00:00 | Cố định, không theo múi giờ người chơi |

## Acceptance Criteria

- **GIVEN** hai người chơi nộp cùng một run giả (copy log của nhau), **WHEN** server replay, **THEN** cả hai nhận đúng điểm giống nhau — không có lợi thế cho việc gửi log giả nếu nó không phải log của một run hợp lệ đã chơi.
- **GIVEN** client sửa Score gửi lên cao hơn thực tế, **WHEN** server replay theo action log thật, **THEN** server bỏ qua Score client gửi và chỉ ghi điểm tự tính — Score gian lận không bao giờ xuất hiện trên bảng.
- **GIVEN** một run dùng quyền chọn-trước NFT ở bất kỳ mức nào, **WHEN** nộp điểm, **THEN** run đó chỉ xuất hiện ở bảng Collector, không xuất hiện ở Standard.
- **GIVEN** hai run cùng mode nhưng khác Ascension, **WHEN** xem leaderboard, **THEN** chúng nằm ở 2 bảng con khác nhau, không bao giờ so sánh trực tiếp.
- **GIVEN** action log được nộp sau khi engine.js đã có bản vá cân bằng mới (ví dụ đợt sửa `docs/balance-log.md` 2026-09-01), **WHEN** server replay, **THEN** server dùng đúng phiên bản engine tại thời điểm seed/run diễn ra, không dùng phiên bản mới nhất.

## Open Questions

- Backend cụ thể chưa chọn (serverless function + DB nào) — cần `/setup-engine`-tương-đương cho hạ tầng backend hoặc một ADR riêng, ngoài phạm vi GDD này.
- Có cần leaderboard theo archetype (ví dụ "top PLAGUE run") không, hay chỉ theo (mode, ascension, Standard/Collector) như hiện tại? Chưa quyết — đề xuất để Phase 2 nếu engagement với leaderboard cơ bản đủ tốt.
- Cơ chế versioning engine.js cho replay (Edge Cases mục cuối) cần thiết kế kỹ hơn ở tầng kiến trúc — đây là rủi ro kỹ thuật thật, nên là một mục riêng trong ADR sắp tới, không chỉ ghi chú ở đây.
