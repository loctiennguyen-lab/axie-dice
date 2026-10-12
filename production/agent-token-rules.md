# Quy tắc dùng token cho agent (Liam, 12/10/2026)

Liam muốn đi nhanh nhưng **không phung phí token**. Đây là cách làm việc, không phải giới hạn cứng. Mọi agent (làn code,
reviewer, thiết kế) đọc file này trước khi bắt đầu và làm theo.

## Đọc
- Chỉ đọc đúng chỗ cần: `grep -n` để tìm, rồi `sed -n 'a,bp'` hoặc Read có `offset/limit`. Không Read cả file > 300 dòng
  nếu chỉ cần một hàm.
- Không đọc lại tài liệu mà prompt đã tóm tắt. Không đọc lại file mình vừa sửa.
- Review thì đọc **diff** (`git show`, `git diff a..b -- path`), không đọc lại cả file.
- Ảnh: chỉ xem khi thật cần, thu nhỏ trước (`sips -Z 1200 in.png --out /tmp/x.png`), mỗi ảnh xem một lần.

## Chạy
- Lúc đang sửa: chạy **test lẻ** liên quan. Cả suite chỉ chạy **một lần** trước khi commit hoặc bàn giao.
- Không chạy lại suite nhiều lần liền nhau "cho chắc". Đỏ thì đọc đúng dòng lỗi, sửa, chạy lại test đó.
- Không vòng lặp chờ/poll. Việc dài thì chạy nền một lần rồi làm việc khác, hoặc dừng và báo.
- Không in log dài ra màn hình: `| tail -20` hoặc `grep` dòng lỗi.

## Làm việc
- Commit sớm, commit nhỏ, khi xanh. Không để việc dở không commit tới cuối lượt (mất việc = tốn gấp đôi).
- Bị chặn (thiếu quyết định, thiếu file của làn khác): **dừng và báo**, không đi tìm hiểu lan man.
- Một việc vượt ~30 lần gọi tool mà chưa xong: dừng ở commit xanh gần nhất, báo phần còn lại.
- Không làm thêm ngoài phạm vi được giao; ý tưởng thêm thì ghi một dòng vào báo cáo.

## Báo cáo
- Tối đa ~15 dòng: đã làm gì (commit hash), test (số), còn gì, cần ai quyết. Không dán log, không kể lại quá trình.

## Điều phối (người giao việc)
- Tối đa **4 agent chạy cùng lúc** (kể cả reviewer).
- Việc mới, không liên quan việc cũ → agent mới với prompt gọn (agent cũ mang context lớn, mỗi lượt đắt). Chỉ dùng
  SendMessage cho agent cũ khi là việc tiếp nối ngắn.
- Prompt gửi agent: nêu file cần đọc và đoạn cần đọc, không bảo "đọc hết".
- Reviewer: chỉ kiểm diff + chạy test liên quan; review việc nhỏ có thể gộp.
- Việc đơn giản (kiểm số, đọc tài liệu, đổi chữ) dùng model rẻ hơn (`model: "haiku"` hoặc sonnet); việc khó mới dùng mặc định.
