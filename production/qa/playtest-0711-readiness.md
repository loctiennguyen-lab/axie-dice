# Kiểm bản live trước playtest 7/11/2026

Người kiểm: qa-lead, 6/11/2026. Bản live: 658afc3 (code giống 8d9668c), RULES_VERSION -w, Worker bd77027e, web pck 02fe988a, desktop b2484.

## Kết luận: GO (có điều kiện)

Không thấy lỗi S1. Có một S2 về web (tải 373 MB). Nên bảo tester dùng desktop trước, đúng như tester guide đã ghi, và báo rõ web lần đầu tải lâu. Đăng nhập Google thật và máy Windows sạch chưa kiểm được (xem cuối file).

**Điều kiện bắt buộc (review producer 6/11):** driver chạy bằng khách, mà khách bị chặn run khi `epoch_source=remote`, nên driver chạy với epoch nội bộ, KHÔNG đi qua Worker. Đường mọi tester sẽ đi (đăng nhập Google → run server tung xúc xắc → màn Result → cloud save) chưa ai kiểm trên live. GO chỉ đúng khi tối nay Liam tự chạy xong một run có đăng nhập trên desktop b2484 (và nếu kịp, trên web), chơi tới màn Result, và bảng Result hiện đủ.

## Lỗi

| Mức | Lỗi | Tái hiện | Bằng chứng |
|---|---|---|---|
| S2 | Web tải rất nặng: `index.pck` 373.6 MB (không nén), `index.wasm` 38.8 MB (nén br còn 9.5 MB). Đây là nguyên nhân "web tải chậm" mà người ta thấy. Máy có mạng chậm sẽ đợi nhiều phút. | Mở https://axiedice.fun, bấm TAP TO START. | `curl -I` index.pck: content-length 373593548, content-type octet-stream, không có content-encoding. Đo bên dưới. |
| S3 | Màn Result: ảnh chụp chỉ thấy nền Land, không thấy bảng kết quả (polish #3 vẫn còn trong ảnh). Log có node `ResultPlate/CardScroll` với nhiều nhãn OFFSCREEN (CoreImpactList, ComboRow). Chưa rõ là chụp quá sớm hay bảng thật sự trễ/nằm dưới màn. | Driver QA win seed 59 1280x720, tới cuối run. | `production/qa/playtest-0711/win-1280/flow-win--result-1280x720.png`, `win-1280/run.log` (QA_CLIP result) |
| S3 | Bốn nút Undo/Hold/Wild/Overcast vẫn chỉ 64 px, lý do tắt không hiện (polish #5). | Vào trận, chọn xúc xắc. | `win-1280/run.log`: QA_CLIP "Hold: pick a die need=160 have=64", "Wild: no valid die need=177", "Overcast need=203" |
| S3 | Log engine: `ERROR: Rect2 size is negative ... encloses (rect2.h:135)` lặp 5 lần mỗi run, không có SCRIPT ERROR đi kèm. Không thấy hậu quả trong ảnh, nhưng có chỗ nào đó đang tính rect âm. | Mỗi run QA, quanh lúc thưởng/Core. | `win-1280/run.log` dòng 1052, 1077, 1100, 1122, 1143; `free-1920/run.log` 5 dòng |
| S3 | Nhãn `PSN 4` của kẻ địch nằm y=-29 (lệch lên trên mép màn) lúc enemy-turn (polish #17, nằm ngoài nhóm A, chỉ ghi lại). | Combat, enemy turn khi quái dính độc. | `win-1280/run.log` QA_CLIP enemy-turn |
| S3 (chưa chắc) | Ảnh chụp web headless có dải xanh đậm ở đáy (khoảng 20% chiều cao). Có thể do cửa sổ headless 1280x720 chứ không phải lỗi game. Chưa kiểm trên trình duyệt thật. | Xem `web/shot-14-213s.png` trong scratchpad (không lưu trong repo). | Ảnh 0.5 đã xem. |

Ghi chú: `ERROR: Couldn't open directory at path "user://acct"` xuất hiện ở đầu và cuối log. Đó là user dir test còn trống, không phải lỗi của người chơi.

## Web (https://axiedice.fun)

Đo bằng Chrome for Testing headless (điều khiển qua CDP), không cache, từ máy dev này. Trình duyệt built-in `mcp__Claude_Browser__*` không có trong phiên của tôi nên tôi không dùng được. Số đo từ headless, sát thực tế nhưng không phải trình duyệt của tester.

| Mốc | Thời gian |
|---|---|
| Mở trang tới màn đầu dùng được (splash "TAP TO START", có nút) | dưới 1 giây (ảnh đầu ở giây 16 đã thấy, các request xong ở 1.2 s) |
| Bấm START tới hết tải `index.wasm` (9.5 MB nén) | khoảng 3 giây |
| Bấm START tới hết tải `index.pck` (374 MB) | khoảng 79 giây, tốc độ khoảng 4.7 MB/s |
| Tới màn đăng nhập hiện ra | khoảng 83 giây sau khi bấm START (api/me trả 401 là bình thường khi chưa đăng nhập) |

- Một lần đo khác bằng curl: 30 MB đầu của pck mất 24 s, tức khoảng 1.2 MB/s, tương đương cỡ 5 phút cho cả file. Tốc độ phụ thuộc đường mạng, nên máy công ty có thể nhanh hơn hoặc chậm hơn.
- Splash chỉ hiện nút, không thấy thanh tiến độ trong ảnh chụp lúc đang tải pck (ảnh `shot-03` tới `shot-05` giống nhau). Tester có thể tưởng bị treo. Chưa xác nhận kỹ vì tôi chỉ đọc ảnh nhỏ.
- Console lỗi: 0 `console.error`, 0 exception. Network: 1 `index.pck net::ERR_ABORTED` ở giây 94.5, là lần request đầu bị huỷ ngay rồi trình duyệt gửi lại request thứ hai (200 và tải xong), không phải lỗi thật.
- Màn đăng nhập trên web có đủ: "Continue with Google", "Play as guest", Terms, Privacy. Panel nằm đúng trong màn. Polish #1 (SignInPanel trôi khỏi màn) đã hết ở bản này.
- Guest: bấm "Play as guest" vào thẳng trận tutorial "Welcome to Axie Dice!" có nút Start và Skip tutorial. Tôi không chơi tiếp trên web.

## Worker API (chỉ GET)

| Route | Kết quả |
|---|---|
| `/` | 200 |
| `/api/leaderboard` | 200 |
| `/download` | 200 |
| `/terms`, `/privacy` | 200 |
| `/api/axie` (thiếu tham số) | 400, đúng ý |
| `/api/econ` (không đăng nhập) | 401, đúng ý |
| `/api/missions`, `/api/raid` (không có route GET gốc) | 404, các route thật là `/api/missions/escrow|unlocks`, `/api/raid/*`, đều cần đăng nhập, tôi không gọi |

Không có route nào trả 5xx. Thời gian trả lời 0.3 đến 0.9 s.

## Driver QA (chạy trên source, user dir test của with_lock)

| Run | Kết quả |
|---|---|
| win seed 59, 1280x720, QA_ENTRY=1 (Login, guest, Land, run) | Chạy xong 105 s. 7 trận, 188 action, `log_complete` true, `patched_matches_ui` true (UI cho đúng kết quả RunBot), verifier ok, 0 QA_ANOMALY, 0 SCRIPT ERROR. Run này kết thúc `won:false`, score 190, 1 lần thua. Cờ "win" chỉ là kịch bản driver (giống RunBot), không bắt buộc thắng. Run này chạy epoch nội bộ, không qua Worker. |
| free seed 2, 1920x1080 | Chạy xong 56 s. 2 lần thua (Continue miễn phí rồi End run), `log_complete` true, `patched_matches_ui` true, verifier ok, 0 QA_ANOMALY, 0 SCRIPT ERROR. |

Ảnh và log: `/Users/loc.tien.nguyen/my-game/production/qa/playtest-0711/win-1280/` (40 ảnh + `run.log`) và `/Users/loc.tien.nguyen/my-game/production/qa/playtest-0711/free-1920/` (22 ảnh + `run.log`).

Màn đăng nhập khi chạy bằng driver (cả hai lúc chưa đăng nhập): có nút Continue with Google, Play as guest, Terms, Privacy, panel nằm trong màn. Ảnh: `win-1280/flow-win--login-returning-guest-1280x720.png`.

QA_CLIP: đã bỏ các dòng đã biết là không phải lỗi (Victory band, ScrollContainer). Còn lại đáng ghi là các mục S3 ở bảng trên.

## Save thật của Liam

Trước khi chạy tôi sao lưu `~/Library/Application Support/Godot/app_userdata/Axie Dice (Godot port)/` (114 file, có sha) vào scratchpad. Sau khi chạy, so sha: giống hệt, không file nào đổi. `with_lock.sh` ở cây chính dùng user dir test riêng nên vốn không chạm save thật. Không cần khôi phục.

Lưu ý: `git status` thấy hai file chưa theo dõi trong `godot/`: `godot/tests/tmp_login_probe.gd.uid` và `godot/unreach_homeland.txt`. Không phải tôi tạo (tôi không ghi vào repo ngoài thư mục `production/qa/`). Có thể của làn khác. Nên xem trước khi commit lần sau.

## Đối chiếu nhóm A của polish-0311-list (mục 1 đến 7 và 23)

| # | Thấy trong run vừa chạy? |
|---|---|
| 1 Đăng nhập | Hết lỗi: nút đủ, panel nằm trong màn (driver và web). |
| 2 Slot 9 of 8 / Make room | Không kiểm lại bằng ảnh (run này không qua slot-swap). Chưa kiểm. |
| 3 Result | Còn thấy: ảnh chỉ có nền Land. Xem bảng lỗi. |
| 4 Đường nối Lõi tới Axie | Chưa xem riêng. Chưa kiểm. |
| 5 Bốn nút công cụ | Còn thấy trong log (64 px, lý do không hiện). |
| 6 Tên boss bị cắt | Chưa kiểm: boss run này không phải loại tên dài. Chưa kiểm. |
| 7 Shop | Run này không đi qua shop. Chưa kiểm. |
| 23 Stuck ở Core offer | Không thấy: run seed 59 qua 5 lần chọn Core, không đứng yên. Seed 7 không chạy, nên chưa loại hẳn. |

## Chưa kiểm được và vì sao

- Đăng nhập Google thật và mọi thứ sau đăng nhập (run xếp hạng, server roll xúc xắc, cloud save, Missions, Leaderboard submit): bạn dặn không đăng nhập. Chưa kiểm.
- Desktop trên máy Windows sạch và macOS sạch: không chạy app desktop trên máy này (dùng save và tài khoản thật của Liam). Chưa kiểm. Link zip: HEAD 6/11 cả hai trả 200, content-length 298113357 (mac) / 274541106 (win), khớp manifest.
- Web trên trình duyệt thật của tester (Chrome/Edge có GPU, mạng văn phòng): tôi chỉ có Chrome headless trên máy dev. Chưa kiểm hiệu năng khung hình trên web.
- Chơi tiếp trên web sau tutorial: chưa vào Land trên web, chỉ tới tutorial.
- Seed 7 (QA_SHOP) và các run thua/thắng khác: không chạy, theo yêu cầu gọn.
- Soak dài, bộ nhớ trình duyệt qua nhiều run: chưa kiểm.

## Việc nên làm cho Liam trước sáng mai (chỉ gợi ý, tôi không sửa gì)

1. Nói rõ trong tin nhắn mời: dùng desktop; web lần đầu tải 373 MB, cần chờ vài phút và thấy màn như treo là bình thường.
2. Trên máy Windows sạch: tải zip, mở theo hướng dẫn SmartScreen, vào được màn đăng nhập, đăng nhập Google, chơi một trận, thoát giữa run rồi mở lại xem có Continue không.
3. Với một tài khoản thử: đăng nhập web, rồi desktop, xem tiến độ đi theo tài khoản.
4. Cân nhắc nén `index.pck` (br/gzip) ở Worker hoặc tách bớt asset cho web, nhưng việc này để sau playtest, không nên đụng đêm nay.
