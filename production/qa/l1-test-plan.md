# Kế hoạch test L1 (khung) / L1 test plan (skeleton)

Trạng thái: KHUNG (12/10/2026). Lane R viết, lane I và qa-lead duyệt. Các mục có "TBD" điền dần tới 29/10.
Nguồn: `production/l1-sprint-plan.md` §2 (RC1 29/10, QA + soak 29–31/10, RC2 31/10) và §4 (danh sách cắt).

Scope: bản tải về macOS + Windows, không ký, cho nội bộ Sky Mavis + ~50 người mời. Web chỉ dự phòng.

---

## 1. Ma trận build / Build matrix

| Build | Máy test | Ai | Trạng thái |
|---|---|---|---|
| macOS universal (.zip, .dmg) | Mac Apple Silicon, Mac Intel (nếu có) | R + 2 người | Chặn: cần lane I bật `import_etc2_astc` (xem mục 6) |
| Windows x86_64 (.zip, exe embed pck) | Windows 10, Windows 11 | R + 2 người | Build 12/10 |
| Web (dự phòng, nếu còn giữ) | Chrome, Safari, Edge | R | Không ưu tiên |

Mỗi bản RC phải có: số build, hash commit, dung lượng, `.sha256`, `BUILD_INFO.txt`.

## 2. Smoke checklist (chạy trên mỗi build trước khi gửi)

Thời lượng mục tiêu: 20 phút. Đánh dấu PASS / FAIL / N/A và ghi ngày, build, máy.

**Cài và mở**
- [ ] Mở app lần đầu theo hướng dẫn (`l1-install-guide.md`), không có lỗi đen màn hình.
- [ ] Màn đầu hiện đủ: logo, nút chính, không có chữ thiếu (`undefined`, `TBD`, ô trống).
- [ ] Cửa sổ đổi kích thước, toàn màn hình, thoát bằng nút thoát đều chạy.

**Tài khoản và save (phải qua `SaveStore`)**
- [ ] Đăng nhập (hoặc tạo tài khoản thử). Đăng xuất, đăng nhập lại: save còn nguyên.
- [ ] Tắt app giữa lúc đang ở menu, mở lại: không mất Shard/Stone/Gem.
- [ ] Mất mạng giữa run: game báo rõ, không mất run đã có, nối lại được hoặc báo lỗi có mã.

**Run (combat)**
- [ ] Bắt đầu run thường, đánh tới ít nhất một trận thường, một elite.
- [ ] Trận có quái Atia 3D hiện đúng, anim chạy, không crash khi đổi trận.
- [ ] Relic nhặt được hiện đúng tên và mô tả; không có relic trùng hiển thị lệch.
- [ ] Continue/Aid: hiện giá bằng Gem tặng, trừ đúng, không trừ hai lần.
- [ ] Thua run: màn kết quả hiện, số liệu khớp với các trận đã đánh.
- [ ] Thắng hoặc thua xong: quay về menu không kẹt.

**Chế độ**
- [ ] Thường, Daily, Ranked: mỗi chế độ vào được, bắt đầu được run.
- [ ] Nhiệm vụ N1–N4 (nếu còn bật theo §4 của plan): nhận, cọc Shard trừ lúc tạo run, nhận thưởng khi xong.
- [ ] Ascension 0 và 3: chọn được, hiện đúng luật thêm.

**Âm thanh và hiệu năng**
- [ ] Có tiếng (nhạc nền, tiếng đánh). Tắt/bật trong Settings có tác dụng.
- [ ] Không rớt xuống dưới 30 FPS khi đứng trong combat 3D (ghi số đo, xem mục 3).

**Lỗi thường gặp**
- [ ] Không có màn "Lỗi không xác định" khi bấm nút chính.
- [ ] Log không có `SCRIPT ERROR` (xem mục 5 để lấy log).

## 3. Kế hoạch soak / Soak plan

Mục đích: tìm rò rỉ bộ nhớ, crash sau nhiều giờ, lỗi save tích lũy.

| Soak | Thời lượng | Máy | Nội dung |
|---|---|---|---|
| S-1 | 2 giờ | Mac + Win | Chạy liên tục run thường, không tắt app, Ascension 0 |
| S-2 | 4 giờ | Mac + Win | Ma trận chế độ xoay vòng (thường, Daily, Ranked, Nhiệm vụ), Ascension 0/3/6/9 |
| S-3 | 1 ngày (nền) | 1 máy mỗi nền tảng | Mở app, đóng mở run lặp lại, mất mạng giữa run 3 lần |
| S-4 | Cài sạch | Máy chưa từng cài | Cài từ zip, mở, chơi 1 run, gỡ, cài lại; save có còn không |

Đo và ghi cho mỗi soak:
- Bộ nhớ đầu và cuối (Activity Monitor / Task Manager), mỗi 30 phút.
- FPS trung bình trong combat 3D (TBD: công cụ đo, lane R + performance-analyst).
- Số crash, số `SCRIPT ERROR`, thời điểm xảy ra, bước đã làm trước đó.
- Thời lượng thực tế so với kế hoạch.

Điều kiện đạt: không crash trong soak S-1 và S-2; bộ nhớ không tăng quá 30% trong 2 giờ; mọi save đọc lại được.

## 4. Mẫu báo lỗi / Bug report template

Dán vào kênh báo lỗi (TBD: kênh, ví dụ một thread chung). Một lỗi một báo cáo.

```
Tiêu đề: [ngắn, có chế độ + màn hình]  ví dụ: "Ranked: thua run xong kẹt ở màn kết quả"
Mức độ: S1 chặn chơi / S2 lỗi lớn có cách tránh / S3 lỗi nhỏ / S4 chữ, hình
Build: AxieDice-0.1.0-L1-bXXX-<hash>-<nền tảng>.zip  (tên file hoặc dòng build: trong BUILD_INFO.txt)
Hệ điều hành: (ví dụ macOS 15.2 Apple Silicon / Windows 11 23H2)
Tài khoản / chế độ / Ascension: 
Có mạng không: có / không / chập chờn

Các bước tái hiện:
1.
2.
3.

Kết quả thực tế:
Kết quả mong đợi:
Tần suất: 1 lần / thỉnh thoảng / luôn luôn
Ảnh chụp màn hình hoặc quay màn hình: (đính kèm)
Save: đã giữ thư mục save chưa (có / không)
```

Lưu ý: không xóa thư mục save trước khi báo lỗi. Đường dẫn save nằm trong `l1-install-guide.md`.

## 5. Kiểm tra telemetry / Telemetry checks

Mục đích: đảm bảo số liệu L1 (run, Nhiệm vụ, cọc) được ghi đúng để đối soát. Đây là việc của S và E, lane R chỉ kiểm.

- [ ] Sau mỗi run hoàn tất, có một dòng kết quả phía server (D1 `axie-dice-db`) với đúng số trận và kết quả. TBD: tên bảng, sau khi lane S chốt schema.
- [ ] Run bị bỏ giữa chừng (đóng app) có trạng thái riêng, không bị ghi thành thắng.
- [ ] Số Gem tặng đã nhận trong ngày khớp với sổ phía server (TBD: UTC reset).
- [ ] Nhiệm vụ: cọc lúc tạo run được ghi, và hoàn tất/thất bại đều có bản ghi.
- [ ] Khi tắt mạng, sự kiện xếp hàng và gửi lại sau; không gửi trùng khi nối lại.
- [ ] Bản build không gửi dữ liệu dev (cờ dev tắt trong bản phát hành; kiểm bằng log đăng nhập).

Các mục TBD được hỏi lane S (server) và lane E (economy) trước 24/10.

## 6. Chặn hiện tại và việc cần làm / Current blockers

| # | Việc | Ai | Hạn |
|---|---|---|---|
| 1 | Bật `rendering/textures/vram_compression/import_etc2_astc=true` trong `godot/project.godot` để xuất macOS universal. Template 4.7.2 không có bản x86_64 riêng, nên không có đường lùi. | Lane I | 14/10 |
| 2 | Chọn tên bundle id (đang để `fun.axiedice.game`) và phiên bản hiển thị | Liam | 14/10 |
| 3 | Danh sách máy của ~50 người mời (mac Intel/Apple Silicon, Windows) | Liam | 24/10 |
| 4 | Số build hiển thị trong game (hiện chỉ có trong tên file và `BUILD_INFO.txt`) | Lane U | 24/10 |
| 5 | Kênh báo lỗi và người nhận | Liam / qa-lead | 24/10 |

## 7. Điều kiện đi tiếp / Exit criteria cho RC1 (29/10)

- Smoke mục 2 đạt trên ít nhất một máy mỗi nền tảng, không S1.
- Soak S-1 và S-2 đạt mục 3.
- Cài sạch S-4 đạt trên Mac và Windows.
- Hướng dẫn `l1-install-guide.md` đã được một người chưa từng cài thử theo, không cần hỏi thêm.
- Số liệu mục 6 (cấu hình tối thiểu) đã điền.
