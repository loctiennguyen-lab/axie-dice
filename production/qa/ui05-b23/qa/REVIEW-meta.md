# REVIEW màn meta, UI-05 đợt 2+3

Gốc ảnh: `/Users/loc.tien.nguyen/my-game-wt/u5b-qa/production/qa/ui05-b23/qa/` (viết tắt Q/). Chủ yếu xem 1280 (khắt khe nhất). Không so từng pixel với frame HTML, chưa mở file thiết kế.

## Lỗi

### Chặn deploy (nghi, cần xác nhận luồng thật)
1. [chặn deploy] Daily, trạng thái đã nhận Daily nhưng chưa nhận Gem gift: nút "Claim · Claimed today" nhảy lên đè đầu thẻ Daily reward, che tiêu đề và hàng Shards. Ảnh: Q/1280/daily/41-daily--gem-gift--1280.png, Q/1920/moments_b3/daily-claim-mid.png. Cảnh "claimed" thì đúng. Nghi: daily scene (`godot/scenes/` daily/Daily*.gd), nút claim đặt absolute/không nằm trong container khi trạng thái này.

### Nên sửa
2. [nên sửa] Info panel keywords trong combat dùng theme Godot mặc định (nền xám #222, font Open Sans, nút "X", chữ ~10-11 px), lệch hẳn UI-05, vi phạm chữ >=14 px. Ảnh: Q/codex/infopanel-keywords--1280.png (bản không đuôi cũng vậy). Nghi: InfoPanel scene/script chưa theme.
3. [nên sửa] Keycap "Space" nằm trên nút tắt/huỷ (Cancel, Close, Not now, Keep it, Keep editing, Skip) trong khi nút chính không có. Vi phạm luật "keycap chỉ trên nút chính". Ảnh: Q/1280/echo/20-echo--open10-confirm--1280.png, 20-echo--rates--1280.png, 20-echo--buy-confirm--1280.png, 20-echo--seasonal-confirm--1280.png, Q/1280/store/19-store--confirm--1280.png, Q/1280/missions/40-missions--confirm-1280x720.png, Q/1280/presets/t05-presets--picker--1280.png, t06-presets--discard--1280.png, t07-presets--delete--1280.png, Q/1280/echo_ceremony/20-echo--opening-1280x720.png (Skip). Nghi: hàm dựng modal dùng chung (ConfirmDialog / meta kit) gán keycap cho nút focus mặc định. Nếu thiết kế cố ý để Cancel là mặc định an toàn thì cần Liam quyết.
4. [nên sửa] Pass: chữ bị cắt "..." trên nút/ô: "Next · needs ...", "Reach Level ..." (L20-L30), "Founder's S...", "Lunacia So...". Ảnh: Q/1280/pass/21-pass--live-1280x720.png, 21-pass--scrolled-1280x720.png.
5. [nên sửa] Pass nút task "Claim · The season is not running" gập 3 dòng, tràn khung nút (đã biết). Ảnh: Q/1280/pass/21-pass--before-1280x720.png, 21-pass--over-1280x720.png, Q/anchor/anchorfx_1920x1080.png (bản 1920 cũng 3 dòng). Nghi: task row trong Pass scene, nút rộng cố định. "Claim · Task not finished" 2 dòng cũng sát khung.
6. [nên sửa] Missions N6 (title tier): panel chi tiết tràn, dòng "No Continue and no Aid." bị cắt dưới nút Stake, có scrollbar nhỏ trong panel. Ảnh: Q/1280/missions/40-missions--title-tier-1280x720.png.
7. [nên sửa] Tab đang chọn một tab khác nhưng vòng focus trắng vuông vẫn dính trên tab cũ (Gem packs, Overview, Audio, Cosmetics). Vòng này vuông, lệch kiểu so với vòng focus bo tròn xanh. Ảnh: Q/1280/store/19-store--cosmetics--1280.png, 19-store--tickets--1280.png, 19-store--moon-card--1280.png; Q/1280/profile/24-profile--cosmetics-dice--1280.png, titles--1280.png; Q/1280/settings/26-settings--controls--1280.png, accessibility--1280.png. Echo tab Regular/Seasonal lúc idle cũng có vòng trắng vuông (Q/1280/echo/20-echo--idle--1280.png). Nghi: code tab bar tự vẽ "selected" bằng focus style / grab_focus không nhả.
8. [nên sửa] Store tab Tickets và Moon Card dùng icon kim cương (Gem) làm art, không phải vé / thẻ. Placeholder. Ảnh: Q/1280/store/19-store--tickets--1280.png, 19-store--moon-card--1280.png. Moon Card còn tự chọn sẵn (tile sáng viền + panel đã mở) khi chưa bấm; Store Cosmetics ở guest/offline cũng chọn sẵn Frost Crown (Q/1280/store/19-store--guest--1280.png, 19-store--offline--1280.png) — nếu không phải fixture thì vi phạm "không chọn sẵn".
9. [nên sửa] Echo no-tickets: nút "Buy enough for 1 pull" kéo ngang hết khung, to bất thường, lệch kiểu so với các nút khác. Ảnh: Q/1280/echo/20-echo--no-tickets--1280.png.
10. [nên sửa] Echo seasonal: nút "Open 1" sáng (primary) cạnh nút xám "Not enough tickets (24 of 40)" gây hiểu nhầm nút nào bấm được. Ảnh: Q/1280/echo/20-echo--seasonal--1280.png.
11. [nên sửa] Settings: nội dung chỉ chiếm ~640 px bên trái, bên phải trống ~380 px, scrollbar dính mép phải xa nội dung. Có thể lệch frame. Ảnh: Q/1280/settings/26-settings--audio--1280.png (và các ảnh settings khác).
12. [nên sửa] Hiệu ứng viền sáng/glow quanh thẻ reveal Epic/Legendary/Mythic (halo tím/vàng/cyan) — kiểm lại xem có phải hiệu ứng PROPOSAL không. Ảnh: Q/1280/echo_ceremony/20-echo--reveal-rare-plus-1280x720.png, 20-echo--reveal-mythic-1280x720.png, 20-echo--reveal-duplicate-1280x720.png.
13. [nên sửa] Anchor awakened: hạt lá (sparks) rơi đè chữ "ANCHOR AWAKENED" và mô tả ("part" bị che). Nếu là FX trong thiết kế thì chỉ cần hạ z-order. Ảnh: Q/anchor/anchorfx_1280x720.png.

### Nhỏ
14. [nhỏ] Echo Mythic/Legendary: art trống ở khung flip (xác nhận). Ảnh: Q/1920/moments_b3/echo-open-mythic-flip.png và echo-open-rare-flip.png (cả hai, không chỉ Mythic): chữ tên/độ hiếm đã hiện nhưng art chưa có. Ảnh reveal cuối ở 1280 có art đủ, nên nhiều khả năng nạp trễ so với animation. Nghi: ceremony script nạp texture khi flip.
15. [nhỏ] Thanh viền rarity trên đầu thẻ reveal/open10 là đường thẳng nhô ra ngoài góc bo của thẻ. Ảnh: Q/1280/echo_ceremony/20-echo--reveal-new-1280x720.png, 20-echo--open10-1280x720.png, Q/1920/moments_b3/open-10-mid-b.png. Tiêu đề "Reveal" / "Open 10" sát/chạm mép trên thẻ.
16. [nhỏ] Echo seasonal sau milestone: panel kết quả tràn hộp, thẻ 500 Stone bị cắt đáy, rương bị đẩy lên. Ảnh: Q/1280/echo/20-echo--seasonal-milestone--1280.png.
17. [nhỏ] Echo guest: "Buy ticket · Not available right now" rớt xuống hàng riêng, dòng Tickets hơi chật. Ảnh: Q/1280/echo/20-echo--guest--1280.png.
18. [nhỏ] Codex Basics: lỗi chính tả "several node's are open". Ảnh: Q/codex/29-codex--basics--1280.png. Anchor detail thẻ hẹp ở giữa, lệch so với lưới. Ảnh: Q/codex/29-codex--anchor-detail--1280.png. Tile Anchors "Picked · Awakened" gập 3 dòng.
19. [nhỏ] Missions: bảng (header TIER/MODE, cột Mode/Rules xám) và đoạn mô tả đầu trang trông ~13 px, chưa đo. Nghi chữ <14 px. Ảnh: Q/1280/missions/40-missions--open-1280x720.png.
20. [nhỏ] Daily/Store: nút "Claim 300 Gem" đổi kiểu giữa các trạng thái (cam không icon ở gem-packs vs nâu có icon ở cosmetic-picked). Ảnh: Q/1280/store/19-store--gem-packs--1280.png vs 19-store--cosmetic-picked--1280.png. Có thể do trạng thái.
21. [nhỏ] Pass 1280: popup Claim ổn, nhưng Pass "Claim 4150 Shards" chip trong footer khác kiểu so với các nút khác (nhỏ). Ảnh: Q/1280/pass/21-pass--loop-1280x720.png.

Không thấy: chuỗi minh hoạ "Liam"/số giả (có "Test Player" ở Profile, coi là fixture), hiệu ứng rays/vòng sáng ngoài mục 12, art trống ngoài mục 14.

## Số lỗi
Chặn deploy: 1 (nghi) · Nên sửa: 12 · Nhỏ: 8 (tổng 21 mục)

## Đã xem (khoảng 118 ảnh)
- Pass 1280: live, detail, before, popup, claimed, over, scrolled, loop, offline, guest (10/10)
- Echo 1280: idle, open10-confirm, rates, buy-confirm, seasonal, seasonal-milestone, seasonal-cap, no-tickets, last-pull, guest, error, seasonal-confirm (12/16)
- Echo ceremony 1280: 7/7
- moments_b3 1920: 14/14
- anchorfx 1280 (1), meta_kit 1920 (1)
- Daily 1280: 7/7
- Store 1280: 13/13; Store 1920: cosmetic-picked, confirm (2)
- Missions 1280: 16/16
- Profile 1280: 8/8 (chỉ bản có/không --1280 thứ nhất)
- Settings 1280: audio, controls, key-capture, controls-combat, run, abandon-armed, accessibility, abandon-mission (8/16)
- Codex: basics, cores, combos, anchors, anchor-detail, search, search-none (1280), guides--1280, unlocks--1280, infopanel-keywords--1280 (10)
- Presets 1280: 9/9

## CHƯA xem
- Toàn bộ: account (28 ảnh), gate (8), raid (20), system (~26), presets 1920, missions 1920, profile 1920
- Pass 1920, Echo 1920, Echo ceremony 1920, Daily 1920, Store 1920 (trừ 2 ảnh), Settings 1920, Codex bản 1920 và các ảnh codex bản không --1280 (guides, unlocks, anchors...), anchorfx 1920
- Settings 1280 còn: account-out, account-out-web, account-in, account-confirm, account-expired, in-run, và các ảnh thứ hai trùng tên --1280
- Echo 1280 còn: loading, offline, rates-season, và 1 ảnh khác
- Profile 1280 bản thư mục 1280 không đuôi (trùng nội dung)
Tổng ảnh nhóm này ước tính hơn 450 (nhiều ảnh trùng giữa thư mục 1920/ và 1280/), đã xem ~118.

---

# Phần 2 (bổ sung): account, gate, raid, system, settings/echo 1280 còn thiếu, bản 1920

Gốc ảnh: Q/ như trên. Không so pixel với frame HTML. Cỡ chữ "nghi" là ước bằng mắt, chưa đo.

## Sửa lại Phần 1
- Mục 3 (keycap trên nút huỷ): theo luật mới, keycap trên nút an toàn Cancel / Keep it / Not now / Keep editing là ĐÚNG. Chỉ còn sai ở nút TẮT: xem P2-6 và nút "Skip" ở echo opening (mục 3 cũ). Các ảnh confirm (open10-confirm, buy-confirm, seasonal-confirm, store confirm, missions confirm, presets discard/delete/picker) KHÔNG phải lỗi, coi như đóng.
- Xác nhận lại ở 1920 (không tính thêm vào số lỗi): mục 1 Daily nút "Claim · Claimed today" đè đầu thẻ (Q/1920/daily/41-daily--gem-gift.png), mục 5 Pass "Claim · The season is not running" 3 dòng tràn nút (Q/1920/pass/21-pass--over-1920x1080.png), mục 7 vòng focus trắng dính tab cũ (store, profile, echo ở 1920), mục 11 settings lệch trái (1920 còn rõ hơn, nội dung 960 px, trống ~620 px phải, scrollbar sát mép), mục 12 halo tím quanh thẻ mythic, mục 15 vạch rarity nhô ra ngoài góc thẻ.

## Lỗi mới

### Chặn deploy
Không thấy lỗi mới ở mức này.

### Nên sửa
P2-1. [nên sửa] Echo seasonal 1920: ô Series items có tên dài "Glowcap Grove" bị bẻ dòng và đè lên nhau trong ô nhỏ, đọc không ra ("Glowc / ap / Grow..."). Ảnh: Q/1920/echo/20-echo--seasonal.png (ô hàng 2, cột 3). Chưa kiểm ở 1280. Nghi: ô lưới series trong echo scene, chưa cắt/ellipsis tên.
P2-2. [nên sửa] Unlocks: các mục "NO EFFECT YET" (Relic Pool II/III, Gene Pool II/III) vẫn có nút giá bấm được. Người chơi mất Shards cho thứ chưa có tác dụng. Nút chỉ có icon + số, không có động từ "Unlock". Ảnh: Q/codex/unlocks.png, unlocks--1280.png. Nghi: codex Unlocks tab. Cần Liam quyết: khoá nút hay ẩn mục.
P2-3. [nên sửa] Raid guest / offline: nút xám "Sign in to raid" / "Raids need a connection" nằm đúng vị trí nút chính nhưng không bấm được, và không có đường nào đăng nhập từ màn này (chỉ có dòng chữ "Sign in to raid."). Nút nói lý do là tốt, nhưng nhãn "Sign in to raid" nghe như lệnh. Ảnh: Q/1280/raid/r08-raid--guest--1280.png, r09-raid--offline--1280.png. Nghi: raid scene, trạng thái guest.
P2-4. [nên sửa] Gate "Choose a save": nút "Keep this device" tô cam (chính) và nút "Keep cloud" nâu, tức là có chọn sẵn một bên cho quyết định không đảo ngược (bên kia chỉ giữ 7 ngày). Không có keycap, không có vòng focus. Tiêu đề phụ "This device has guest progress" dính sát đoạn mô tả. Ảnh: Q/1280/gate/a15-choose-a-save--1280.png. So với a16 (có keycap Space trên "Move progress") thì hai màn cùng họ mà khác kiểu. Nghi: AccountUI gate / choose-save panel.
P2-5. [nên sửa] Update bar và netnotice toast: chữ thân ~13 px (nghi), nút "Reload the page" / "Download" trong bar nhỏ (~130x30 px, chữ ~12-13 px nghi). Ảnh: Q/1280/system/18-update--bar-web--1280.png, 18-update--bar-desktop--1280.png, 18-netnotice--*--1280.png. Nghi: update bar + NetNotice scene. Cần đo thật font size.
P2-6. [nên sửa] Echo Rates modal: nút "Close" có keycap Space (nút tắt, vi phạm luật). Ảnh: Q/1280/echo/20-echo--rates-season--1280.png (và rates ở các trạng thái khác). Ngược lại update modal "Close" và sign-in overlay "Close" không có keycap, đúng. Nghi: hàm dựng modal Rates gán keycap cho nút focus mặc định.
P2-7. [nên sửa] Raid: nút "Fight" nhỏ (~58x30 px, thấp hơn nút chính 48 px) và dòng đội hình (Buba, Pomodoro...) ~13 px màu nhạt, nghi dưới 14 px. Đây là hành động chính của màn. Ảnh: Q/1280/raid/r01-raid--list--1280.png. Nghi: raid row scene.

### Nhỏ
P2-8. [nhỏ] Raid: chip "Team: Thorn Wall" / "Team: Starter team" cùng kiểu với nút bấm, không rõ bấm được hay chỉ là nhãn. Ảnh: Q/1280/raid/r01, r10.
P2-9. [nhỏ] Raid: đoạn luật tự mâu thuẫn, "Win 3 points, loss 1" rồi "Nobody loses anything". Ảnh: Q/1280/raid/r01-raid--list--1280.png (mọi ảnh raid). Sửa chữ.
P2-10. [nhỏ] Gate welcome "Continue without signing in" là chữ trơn nhạt ~13 px, không giống nút; và trái với a01 "Dice are rolled on our server, so you need an account to start a run". Ảnh: Q/1280/gate/a14-welcome-panel--1280.png, Q/1280/account/a01-account--signed-out--1280.png.
P2-11. [nhỏ] Overlay đăng nhập: thứ tự nút không thống nhất. Màn account (a02) Cancel trái, "Open browser again" phải; overlay (a09) "Open browser again" full-width trên, Cancel nhỏ dưới. Ảnh: Q/1280/account/a02-account--waiting--1280.png vs a09-signin-overlay--waiting--1280.png.
P2-12. [nhỏ] Account signed-in: focus mặc định rơi vào "Sign out" thay vì nút an toàn. Ảnh: Q/1280/account/a06-account--signed-in--1280.png. Nút chính ở a01/a04/a05 cũng không có keycap Space trong khi Done/Reload/Claim có, kiểu không đều.
P2-13. [nhỏ] Store Moon Card: panel phải ghi "Coming soon" thay cho tên món "Moon Card"; ô vẫn dùng icon kim cương placeholder (đã biết mục 8). Ảnh: Q/1920/store/19-store--moon-card.png.
P2-14. [nhỏ] Store cosmetics: panel Luna Heart Crown (Mythic, mua 720 Gem) ghi "Season items: only from the Seasonal Echo Box" ngay trên nút mua, mâu thuẫn. Ảnh: Q/1920/store/19-store--short-of-gem.png. Nghi: chuỗi mô tả chung cho mọi món.
P2-15. [nhỏ] Presets: "Copy" / "Delete" là link gạch chân nhỏ, hành động xoá nhìn yếu hơn "Edit". Ảnh: Q/1920/presets/t02-presets--grid.png.
P2-16. [nhỏ] Settings key-capture: hai dòng hướng dẫn trùng ("Click a shortcut, then press the new key. Esc cancels." và "Press a key for ... Esc cancels."). Ảnh: Q/1920/settings/26-settings--key-capture.png.
P2-17. [nhỏ] Profile Cosmetics: ô "Honey Clay" (Locked, ô thứ 4) chọn sẵn khi chưa bấm, panel hiện "Equip · Locked". Có thể do capture. Ảnh: Q/1920/profile/24-profile--cosmetics-locked.png.
P2-18. [nhỏ] Codex Guides: viền chọn hàng đầu "LIVING WALL" bị cắt đỉnh bởi khung cuộn. Ảnh: Q/codex/guides.png.
P2-19. [nhỏ] Missions 1920: đoạn mô tả đầu trang xuống 3 dòng, từ "bot." mồ côi. Ảnh: Q/1920/missions/40-missions--title-tier-1920x1080.png.
P2-20. [nhỏ] Echo ceremony reveal 1920: thẻ cao ~650 px nhưng nội dung chỉ chiếm ~500 px, trống ~120 px dưới. Open10: hàng thẻ trên chồng lên thanh Tickets phía sau, tiêu đề "Open 10" chạm đỉnh thẻ. Ảnh: Q/1920/echo_ceremony/20-echo--reveal-mythic-1920x1080.png, 20-echo--open10-1920x1080.png.
P2-21. [nhỏ] Echo loading (1280): khối xám lớn trống, không chữ "Loading" hay spinner. Ảnh: Q/1280/echo/20-echo--loading--1280.png. Raid loading (r05) tương tự, chỉ có 2 thanh xám.

Không thấy: chuỗi minh hoạ "Liam" hay số giả (Mira/Kito/Tuan Anh ở raid, Test Player ở account coi là fixture), hiệu ứng rays/sparks/vòng sáng mới ngoài mục 12 của Phần 1, nút tắt nào khác có keycap, chọn sẵn trong màn mua (store gem-packs/cosmetics 1920 không chọn sẵn).

Đã khen: system modals/toast (netnotice, update) nhất quán, nút tắt không keycap, reason hiển thị rõ; confirm Missions/Store có keycap trên nút an toàn đúng; Daily weekly-gem-cap, Store owned-result, Profile titles có lý do trên nút tắt.

## Số lỗi Phần 2
Chặn deploy: 0 · Nên sửa: 7 · Nhỏ: 14 (tổng 21 mục mới)

## Đã xem Phần 2 (86 ảnh)
- Account 1280: 11 (a01, a02, a04, a05, a06, a07, a08, a09, a11, a12, a17), gate 1280: 4/4
- Raid 1280: 10/10
- System 1280: 13/13 (netnotice offline/busy/rejected/server-error/run-gone/action-lead/timeout/expired, update modal-web/modal-desktop/missions/bar-web/bar-desktop)
- Settings 1280: account-out, account-out-web, account-in, account-confirm, account-expired, in-run (6) + abandon-mission (1)
- Echo 1280: rates-season, offline, loading (3)
- 1920: pass live/popup/over (3), echo idle/seasonal/seasonal-cap/buy-confirm (4), daily unclaimed/gem-gift/weekly-gem-cap (3), settings audio/key-capture/account-in (3), echo_ceremony reveal-mythic/open10/reveal-stone (3), store cosmetics/short-of-gem/owned-result/gem-full(=tickets)/moon-card/confirm (6), profile overview-empty/cosmetics-locked/titles (3) + guest 1280 (1), missions title-tier/confirm/refund/open-run (4), presets grid/editor-edit/discard (3)
- Codex (thư mục Q/codex/, không có codex trong 1920/): cores, anchors, guides, unlocks, search-none (5)

## CHƯA xem sau Phần 2
- 1920: account/gate/raid/system không có thư mục riêng (chỉ có bản 1280); pass before/detail/claimed/scrolled/loop/offline/guest; echo (các trạng thái còn lại); daily claimed/claiming/offline/guest; settings (các tab còn lại); profile (các tab còn lại); presets (empty, samples, picker, delete, new, guest); missions (open, picked, challenge, locked, need-shards, guest, offline, newcomer, closed, loading, checking, error); echo_ceremony (opening, reveal-new/duplicate/rare-plus); store (gem-packs, picked, tickets, gift-claimed, offline, guest)
- 1280: account a03, a10, a18 (toast expired); settings account bản trùng không đuôi
- Chưa đo font size thật, mọi chỗ "nghi" cần đo bằng công cụ
