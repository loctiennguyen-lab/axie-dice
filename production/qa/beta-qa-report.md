# Báo cáo QA beta (qa-lead, 28/10/2026)

Theo `production/qa/beta-qa-plan.md` mục 4, mục 8. Mình ký phần QA, Liam quyết GO/NO-GO.
Số test, soak và deploy lấy từ log ở các file nguồn, mình không chạy lại trong lượt viết báo cáo này.

## 0. Bản đang chạy
- RULES_VERSION `godot-2026-10-26-v`.
- Web: pck md5 `b554725a` (QA2, 27/10). Desktop b1790 (3e4def9). Worker từ b95a83d8 lên các bản sau (có SR-V).
- SR-V (server tự replay run) chạy bóng từ 28/10: D1 0012, `VERIFY_SHADOW=1`, runner trên Mac của Liam. Chưa chấm run nào vì chưa có run kết thúc trên client mới.
- Quyết định của Liam đã vào bản: không thêm luật chống trận kéo dài; perk tắt khi kinh tế do server giữ; verifier chạy trên Mac Liam trước; thêm cài đặt Reduce motion.
- App desktop và web của Liam đăng nhập hai tài khoản Google khác nhau, tiến độ không chung.

## 1. Tầng 2a: tự động
| Mục | Kết quả |
|---|---|
| Suite Godot | 277/277 (số đo mới nhất 276/276 + 1 test mới) |
| Worker | 381/381 |
| Trên int/qa1 | 270/271, chỉ `t_combo_fired` đỏ vì kỳ vọng chữ cũ, đã sửa |
| Trên int/qa2 | 271/273, 2 test đỏ vì chữ cũ (`t_anchor_flow_gut_progress`, `t_tooltip_modal`), đã sửa |

Chưa ghi nhận trong các log: lượt chạy `AXIE_RELEASE=1` riêng và `grep -c _tmp missions.json` = 0 (plan 2a mục 1 và 3). Cần xác nhận trước khi mời người ngoài.

## 2. Tầng 2b: soak bot (bản R3, chạy 27/10 và 28/10)
- 27.069 run, 381 ô. WON 1.250, LOST 25.816, STUCK_TURNS 3.
- Replay qua RunVerifier: ok 12.902, bỏ qua 14.164 ô ép Anchor/Luật (harness chưa replay được loại này), skip_stuck 3. Lệch replay ở lượt 28/10: 0. (Lượt 27/10 có 1 lệch, xem dưới.)
- 0 crash, 0 SCRIPT ERROR, 0 treo.
- 1.905 dòng `ERROR:` đều là `Couldn't open directory at path "user://acct"`. Đó là nhiễu của môi trường soak, không phải lỗi game.
- Lệch Nhiệm vụ 85% của 26/10 đã hết nhờ sửa verifier ở R3.

3 run STUCK_TURNS (seed để tái hiện):
- 500024: N2, attack_spam.
- 300026: Mana Mine + Pilot Light, random_legal.
- 400008: Mana Mine + Upside Down, expert.
- Cả ba là trận kéo dài khi chỉ còn 1 Axie: quái tự hồi (heal/ward/mend) ngang sát thương ta gây, attrition dừng ở +25%. Engine vẫn chạy đều, không kẹt cứng. Người chơi thật có reroll, mana, chọn mặt nên dễ phá hơn bot. Tệ nhất là một trận chán và rất dài.
- Liam quyết: không thêm luật. Ghi nhận là rủi ro nhịp (S3), không phải lỗi.
- Run lệch replay 27/10 (live 100, replay 110) chỉ xảy ra ở run STUCK: bot kết thúc giữa trận, `compute_run_xp` của bot và replay tính khác. Người chơi thật không gặp vì bỏ run thì không có điểm. Việc nhỏ cho sau: harness coi STUCK là skip.

Chưa đủ so với plan: ô expert/Atia và thống kê "mỗi ô có thắng" chưa được đọc kỹ trong báo cáo này; số WON 4,6% chung cho thấy game khó, chuyển N-S xem.

## 3. Tầng 2c: luồng thật trên production
Đã chạy:
- Khách (không đăng nhập): 15 API tạo run / tiêu tiền / nhận thưởng / ghi save đều 401. Leaderboard GET mở. PASS.
- Live smoke (bot, phiên desktop của Liam): 1 lần `--full` + 3 lần thường, PASS. Gồm run thật, thắng trận, thưởng, mất mạng rồi RETRY, Continue sau khi thoát, Daily, bỏ run sạch.
- Web, tài khoản Liam: FLOW-19 run thường + thưởng Level Up; FLOW-29 tải lại giữa run rồi Continue (gặp BUG-0006, đã sửa); bỏ run có xác nhận rõ; FLOW-23 Echo Box 3 vé (pity tăng); FLOW-21 Daily (lỗi chữ/nút, đã sửa); Pass hiện đúng "mùa chưa bắt đầu".
- Sau QA1 và QA2: web kiểm lại chip Gem, chữ Loading, Start-here, nút Upgrade Land, dòng Anchor ở Run Setup, giải thích Pity, Daily. Hiện đúng.

KHÔNG chạy được, kèm lý do:
| FLOW | Lý do |
|---|---|
| FLOW-1/2/3/7 Nhiệm vụ (mua, thắng, thua, mở bậc) | Chưa mua thử trên production: tài khoản web của Liam mới 0/5 run hợp lệ theo server. Cần 5 run có thắng trận. Bị BUG-0008 chặn trước đó, nay đã sửa nhưng chưa làm lại |
| FLOW-5 bump hoàn cược giữa run Nhiệm vụ | Chưa chuẩn bị run dở trước deploy; cần một lần bump có chủ đích |
| FLOW-4 ngắt mạng bằng tay giữa run Nhiệm vụ | Chỉ có live smoke (bot) mất mạng → RETRY. Chưa rút mạng bằng tay lúc xúc xắc bay / chờ seed / END TURN |
| FLOW-14 ngắt mạng nhiều thời điểm | Như trên |
| FLOW-15 hai thiết bị, đăng nhập máy khác giữa run | Không có tài khoản phụ, và hai app của Liam dùng hai tài khoản Google khác nhau. Bẫy `sid` (đăng xuất B giết token A) chưa kiểm |
| FLOW-9..12 Land nâng tier 2 (20k Stone) | Chưa ghi nhận chạy ở các log nguồn |
| FLOW-6 desktop bản cũ thấy màn "có bản mới" | Chưa ghi nhận |
| Windows (FLOW-26, 33) | Chưa có máy, chưa kiểm |
| Tài khoản `qa-fresh` (người mới, khách đăng ký) | Chờ Liam, chưa tạo |
| RTT PB/PA | Desktop: phần lớn 80-450 ms, có 1465, 1292, 3042 ms (node đầu run). Web: 999-1204 ms nhưng đo khi khung bị ẩn nên không dùng được. Chưa đủ 100 mẫu/nền tảng, p95 chưa tính. Liam chưa quyết PB/PA |
| FLOW-16 reset M1 trên tài khoản Liam | Reset đã xảy ra từ R3; chỉ kiểm gián tiếp (BUG-0004, 0006). Chưa có tài khoản mới để xem thông báo reset lần đầu |

Phiên desktop của Liam bị đăng xuất sau 4 lần live smoke: không chạy lại live smoke trên phiên của Liam nếu chưa hỏi.

## 4. Săn chỗ khó hiểu
- 39 màn x 2 cỡ (1920x1080, 1280x720), chụp offline; ux-designer review độc lập: 44 dòng (0 S1, 6 S2, 23 S3, 15 S4). Chi tiết: `production/qa/ux-hunt-review-2026-10-27.md`.
- 6 S2 đã sửa hết ở QA1 (số Pass lệch, thông báo reset, chooser "played somewhere else", cảnh báo mất cược khi thua, nhãn khoá N6, "Pool now").
- Phần lớn S3/S4 sửa ở QA2. Bỏ qua có lý do: S4-7 (icon riêng cho từng nhóm Lõi, cần art), S3-14 (khách vẫn "Sign in to play" vì xúc xắc do server tung, đã có tooltip), S3-12 Armor (tooltip có sẵn).
- Chưa kiểm được qua ảnh: tooltip hover, focus bàn phím/gamepad ở modal tier và thẻ Anchor, chữ "Outside a SET", banner hoàn cược thật, cỡ chữ 24/32, âm thanh. Chỉ có lượt người-mới offline; lượt thứ hai trên tài khoản Liam stage cao mới làm một phần qua các FLOW ở trên.
- Còn mở: màn Pass có hai thanh cuộn ở 1280x720.
- `production/qa/bugs/liam-notes.md` còn trống, bắt đầu dùng khi Liam polish.

## 5. Bug
Tất cả 8 bug trong `production/qa/bugs/INDEX.md` đã sửa và đang chạy trên production. Không còn S1 và S2 mở trong index.

| ID | Mức | Tóm tắt | Trạng thái |
|---|---|---|---|
| 0001 | S3 | Panel Aid hiện giá USD + "Not in this build" | sửa, live 27/10 |
| 0002 | S3 | Start run đứng ~15 s không báo | sửa, live từ R2 |
| 0003 | S2 | Undo/tải giữa trận mất bonus G ascend/forge | sửa, hotfix b1705 |
| 0004 | S2 | Sau reset R3 hiện số dư cũ + kẹt Continue run | sửa, hotfix b1752 |
| 0005 | S4 | Tooltip ý định quái sót ở màn tutorial | sửa, live 27/10 |
| 0006 | S2 | Tải lại giữa run hiện "played somewhere else" (500 vs 0) + thiếu thông báo reset | sửa, e712bab |
| 0007 | S2 | Result và Pass lệch tên, XP, thưởng | sửa, live 27/10 |
| 0008 | S2 | Cổng 5 run client đếm khác server | sửa, Worker b95a83d8 + web |

Lưu ý quy trình: index ghi "đã sửa, live", chưa phải "Verified/Closed" theo vòng đời plan. Phần lớn được xác nhận bằng QA web sau deploy; BUG-0006/0008 cần chạy lại đúng các bước trên tài khoản mới (xem mục 6).
Bug còn mở (S4/S3, đã biết): S4-7 icon Lõi; Pass hai thanh cuộn; trận kéo dài (rủi ro nhịp, Liam đã quyết không sửa).

## 6. Rủi ro còn lại
1. Nhiệm vụ trên production chưa mua thử một lần nào. Đây là chỗ tiền thật của game (cược Shard). Đã có test Worker và live smoke bot, nhưng chưa có người chơi thật.
2. Hoàn cược khi bump và ngắt mạng giữa run Nhiệm vụ chưa thử tay. S1 tiềm năng (mất cược hai lần).
3. Hai thiết bị / đăng nhập máy khác giữa run chưa kiểm (bẫy `sid`).
4. Windows chưa kiểm. Mac chưa notarize (hỏi lại Liam: người ngoài sẽ gặp cảnh báo bảo mật).
5. RTT: chưa có mẫu thật; Liam chưa chốt PB/PA. Desktop có đỉnh 1-3 s ở node đầu run, trên ngưỡng p95 ~1,4 s Liam đặt.
6. Thông báo reset chưa nhìn thấy trên tài khoản mới; chưa kiểm hai thiết bị.
7. Pass bắt đầu 3/11: chưa kiểm khi mùa mở (nhận mốc, XP khớp giữa Result và Pass sau BUG-0007).
8. SR-V chưa chấm run nào; chỉ ghi nhận, không đổi thưởng. Mac tắt thì job chờ (bỏ sau 14 ngày).
9. Trận kéo dài khi còn 1 Axie: có thể gặp thật ở Mana Mine / Nhiệm vụ N2.
10. Soak: 14.164 ô ép Anchor/Luật chưa replay được, nên phần lớn tổ hợp Anchor x Luật chưa có kiểm replay.
11. Chưa đạt tiêu chí plan mục 4 #3 (FLOW-5, 14, 15, 16 "không thể bỏ") và #7 (RTT). Hai điểm này là khoảng trống chính giữa báo cáo và tiêu chí đã đặt.

## 7. Đề xuất
**GO cho closed beta với Liam và tester đã quen. NO-GO cho tester ngoài cho tới khi đủ các điều kiện dưới.**

Lý do GO hẹp: 0 crash trên 27.069 run bot, 0 replay lệch ở lượt cuối, không còn S1/S2 mở, server từ chối khách ở mọi API tiền/run, S2 UX đã sửa hết. Nhưng đường tiền Nhiệm vụ chưa có người chơi thật, và vài FLOW "không thể bỏ" chưa chạy.

Điều kiện trước khi mời người ngoài:
1. Mua Nhiệm vụ trên production ít nhất N1: thắng một lần, thua một lần, bỏ một lần. Cần 5 run có thắng trận trên tài khoản web trước (hoặc tài khoản phụ). Đối chiếu số dư trước/sau (FLOW-1, 2, 3, 7).
2. FLOW-4 và 14 bằng tay (rút mạng ở xúc xắc bay, chờ seed, END TURN, màn thưởng, giữa run Nhiệm vụ) và FLOW-5 (bump giữa run Nhiệm vụ → hoàn cược đủ).
3. FLOW-15 hai thiết bị cùng một tài khoản; kiểm bẫy `sid`. Cần tài khoản phụ hoặc cho hai app cùng dùng một tài khoản Google.
4. Một tài khoản mới đi hết: tutorial, thông báo reset lần đầu, Daily, Echo Box.
5. Kiểm Windows (hoặc ghi rõ "chưa hỗ trợ Windows" trong lời mời).
6. Notarize bản mac, hoặc nói rõ cách mở cho tester.
7. Kiểm Pass khi mùa mở 3/11 (một lần nhận mốc, XP khớp Result/Pass).
8. Mẫu RTT thật >= 100 mỗi nền tảng (web: DevTools Console, khung không bị ẩn), rồi Liam chốt PB/PA.
9. Xác nhận `AXIE_RELEASE=1` xanh và `_tmp` = 0 trong `missions.json`.
10. Chạy `/smoke-check` lại ngay trên build cuối trước khi gửi lời mời.

Sau closed beta vài ngày: xem `bash verifier/stats.sh` (điều kiện thôi chạy bóng: 0 lệch, >= 500 run mỗi nền tảng, >= 7 ngày) và `liam-notes.md`, rồi đóng chính thức các bug trong index.

## Bổ sung (28/10, sau khi đối chiếu log)
- `grep -c _tmp godot/assets/data/economy/missions.json` = 0 (đo 28/10).
- Suite `AXIE_RELEASE=1` đã chạy ở mỗi đợt release:
  - R1: 245/245.
  - R2: 250/250.
  - R-Atia: 251/251.
  - Hotfix BUG-0003: 253/253.
  - R3: 264/264. Hotfix BUG-0004: 267/267.
  - Nguồn: `production/release/deploy-2026-10-2*.md`.
  - QA1, QA2, SR-V và UI-04 mới chạy suite thường (270–277), chưa chạy lại với `AXIE_RELEASE=1`. Việc này làm ở bản build cuối, trước khi mời tester ngoài.
