# Review SR1 Worker (kinh tế server) — commit 6320387, nhánh beta/sr1
Reviewer: security-engineer (độc lập). Chạy `node --test test/*.test.mjs`: 302/302. Không sửa gì.

**Verdict: APPROVE WITH CHANGES.** Phần tiền/idempotency/RNG chắc. Có 1 lỗ kinh tế cần vá trước khi bật cho người chơi thật (claim `run`).

## Kiểm theo 6 điểm
1. **Double-spend / race: ĐẠT.** `economy.js:43-60` (runOp): marker `op:<kind>:<req>` + position row (`echobox:<pid>:<opens>` dòng 292, `buy:<pid>:<day>:<have>` dòng 128) + ledger + UPDATE trong MỘT `DB.batch`. D1 batch là transaction, lỗi bất kỳ (UNIQUE, CHECK balance>=0, trigger RAISE(ABORT)) rollback cả batch. Hai request song song đọc cùng state thì đụng UNIQUE ở position, người thua trả 409 `conflict`. Retry cùng req_id: `priorOp` + nhánh UNIQUE trả lại answer đã lưu (`dup:true`). Unlock mua 2 req_id khác nhau song song: đụng key `shard:unlock:<id>` -> conflict. Map lỗi theo regex (UNIQUE trước, rồi HOLD_CAP/DAY_CAP/CHECK) khớp thông báo SQLite/D1. Test harness (node:sqlite BEGIN/ROLLBACK) mô phỏng đúng ngữ nghĩa đó; chưa chạy trên D1 thật (không được deploy), nên thử 1 lần trên D1 staging/local `wrangler d1` trước khi lên prod.
2. **Echo Box: ĐẠT.** `economy.js:207-279` khớp `echo_box.gd:78-107, 283-368` (pick theo weight, forced min rarity, advance pity, missing/duplicate, fragments). `cryptoRand` (202-205) ghép 27+26 bit = 53 bit, `floor(rand*n)` lệch modulo ~2^-53, bỏ qua được. Client không gửi gì ảnh hưởng kết quả (chỉ req_id); `opts.rand` chỉ test truyền, `index.js:386` gọi không có opts. Kết quả chốt trong cùng batch với phí vé nên không "xem trước rồi huỷ" được.
3. **Claim:** xem CHẶN/NÊN SỬA dưới.
4. **Starter:** mỗi player đúng 1 lần (marker `op:starter:v1`, kiểm bằng test). Khách không có `players` nên không có ví. Rủi ro còn lại là nhiều tài khoản Google (500 Shard + 3 vé mỗi cái). Nằm trong phạm vi Liam đã chấp nhận nhưng ghi lại.
5. **Migration 0011: AN TOÀN.** Chỉ CREATE TABLE/TRIGGER, không động bảng cũ. Trigger `wallets_ticket_hold_cap` chỉ khớp currency 'ticket' (không có dòng cũ), `echobox_buy_day_cap` ở bảng mới. Không ảnh hưởng Gem.
6. **wallet.js: KHÔNG ĐỔI hành vi Gem.** `applyDelta` giờ gọi `applyDeltaCur(…,'gem',…)`; nhánh replay trả thêm `balance` đã có sẵn trước đó. OK.

## CHẶN (vá trước khi mở cho người chơi)
- **C1. Claim `run` không có cổng nào ngoài "run đã closed" (`economy.js:186-193`).** Số tiền do client tự gửi (≤ RUN_SHARD_MAX 3000, `econ_tables.js:9`). Mà run "closed" rất rẻ: `run_core.js:513` ghi thẳng closed khi chuỗi hash đúng, chưa có verifier (TODO P3), `battles_done` do client khai (`run_do.js:163`, 0..500) và claim không kiểm. Một người mở/đóng run liên tục (mode normal không giới hạn số lần) và claim 3000 Shard/run, không giới hạn ngày. Liam chấp nhận "số của client + không trần payout ngày", nhưng chưa chắc đã hình dung ra "farm không giới hạn Shard rồi đổi vé/unlock". Đề xuất tối thiểu: (a) bắt `battles_done >= min` như `SEASON_GATES.min_battles` trong `wallet.js:128`, (b) hoặc tính amount phía server từ `summary_json.srv` / công thức cố định theo outcome+stage thay vì số client, (c) hoặc trần số claim `run`/ngày. Cần Liam chọn.
- **C2. Run `mission` cũng claim `run` được** (không lọc `mode`) trong khi mission đã có escrow trả thưởng riêng (`missions.js:101-125`). Cộng với C1 là trả 2 lần. Lọc `mode != 'mission'` (và nên cấm cả `infra_error`/abandoned, hiện đã loại vì state).

## NÊN SỬA
- N1. `claim daily` (`economy.js:171-173`) và `daily_run` chỉ cần 1 run closed bất kỳ, không cần battles. Mức thưởng cố định 1 lần/ngày nên rủi ro thấp, nhưng nên dùng chung cổng `battles_done` với C1.
- N2. `run` với `amount === 0` trả ok không ghi marker (dòng 191), sau đó vẫn claim >0 được. Vô hại, nhưng nên trả bad_request cho 0 để rõ nghĩa.
- N3. `ensureStarter` chạy trên MỌI request (dòng 325, 333): mỗi lần là 1 batch cố ý đụng UNIQUE rồi 1 SELECT. Thêm `priorOp` kiểm trước (1 SELECT rẻ, không batch) để giảm tải D1.
- N4. Starter có thể cấp lại nếu player bị xoá rồi đăng ký lại (id mới, ledger CASCADE). Hiện chưa thấy route xoá tài khoản; nếu thêm (GDPR) cần nhớ chặn lặp (lưu hash sub đã nhận starter).
- N5. Mission escrow (`missions.js:8`) ghi ledger 'shard' nhưng KHÔNG đụng `wallets`, trong khi giờ ví Shard là thật. Stake/payout mission chưa trừ/cộng số dư server -> cần lane nối (ngoài diff này, nhưng nếu bật cả hai thì Shard mission là tiền ảo không ràng buộc).
- N6. `openBox` (dòng 288) cắt `tickets_back` theo hold_cap nhưng vẫn tiêu fragments: mất vé hoàn khi đầy 999. Hiếm, nên ghi chú hoặc giữ fragments.
- N7. `claim weekly` đếm từ ledger `shard:claim:daily:%` theo `at`; đúng và dùng UTC server nên đổi múi giờ không lách được. Nhưng phụ thuộc `daily_reward.shards > 0`; nếu sau này đặt 0 thì weekly không bao giờ mở. Thêm test hoặc đếm qua marker `op:claim:daily:%`.

## Vòng 2 — e635086, 686fe58, 6ee8272, b905de9 (test 313/313)
**Verdict: APPROVE WITH CHANGES.** Một lỗi CHẶN (reset thiếu bảng), còn lại sửa tốt hoặc là rủi ro đã nêu.

Đã đóng: C2 (VALID_RUN loại mission, `economy.js:~236`), N1 (daily/daily_run cần battles_done>=1), N3 (priorOp trước batch), N4 (`starter_claims` không FK; UNIQUE rollback cả batch), N2 (amount 0 -> nothing_to_claim). N5 có cờ `ECON_SHARD_WALLET` (missions.js:99): thứ tự ensureShard/ledger/applyShard với `changes()=1` đúng, thiếu tiền thì CHECK rollback cả run. Mặc định TẮT, nhớ bật cùng lúc với lane client, nếu không Shard mission vẫn chỉ là sổ ghi. Save: PUT cắt, GET không trả các key server (`accounts.js:409-424`), đủ 7 key. Mọi claim mới đều qua runOp/bundle với marker `op:claim:*` nên idempotent; pass_weekly/post30/mission/pass/land mỗi cái có khoá riêng.

CHẶN
- **R1. `scripts/reset_m1.sql` + `tools/reset_m1.sh` thiếu bảng `pass_xp`** (tạo ở 0011, FK tới players nên KHÔNG bị CASCADE khi giữ player). Sau reset XP Pass cũ còn nguyên, run mới cộng dồn lên, level Pass nhảy ngay. Thêm `DELETE FROM pass_xp;` vào SQL và `pass_xp` vào `TABLES` (dry-run đếm). Còn lại đủ: mission_wins, mission_escrow, leaderboard_scores, raid_*, runs, saves, inventory, unlocks, echobox_state, starter_claims, wallets, wallet_ledger; giữ players/sessions/device_*/desktop_codes; không đụng d1_migrations. Thứ tự con trước cha ổn.
- Script an toàn: mặc định dry-run (chỉ SELECT COUNT), `--yes` mới xoá; tuy nhiên `--yes` không kèm `--remote` chạy trên local, `--remote` không kèm `--yes` chỉ đếm, đúng ý. Nên thêm bước hỏi gõ lại "RESET" khi `--remote --yes`, và chạy snapshot tự động (hiện chỉ nằm trong comment). Starter sau reset: xoá cả `starter_claims` lẫn ledger (mất `op:starter:v1`) nên GET đầu tiên cấp lại đúng 1 lần; marker `op:reset:<id>` khác key nên không cản. Đúng.

NÊN SỬA / rủi ro còn lại
- N8. **claim `run`**: amount giờ lấy từ `summary.shards` (không từ request) nhưng summary và battles_done vẫn do client khai và chưa có verifier, nên C1 chỉ giảm chứ chưa hết: mở/đóng run rẻ rồi tự khai shards 3000 vẫn farm được không giới hạn. Gate server-side rẻ còn thiếu: `closed_at - created_at >= X giây` (cả hai là giờ server), hoặc số epoch DO >= N, hoặc trần số claim `run`/ngày. Cần Liam chấp nhận rõ hoặc chọn một.
- N9. **claim `land`**: `points` do client khai, server không có điểm Land, nên ai cũng gửi points=999 lấy hết mọi mốc (title/cosmetic/decor, không phải Shard). Idempotent theo mốc, bị chặn bởi danh sách mốc, nhưng là cosmetic miễn phí. Chấp nhận nếu cosmetic Land không bán tiền thật; nếu có thì cần server giữ layout Land.
- N10. **pass_weekly** đếm run từ bảng `runs` (battles_done/summary.bosses_started do client, mission tính vào đúng như PassV2). Giả mạo được nhưng bị chặn trên: mỗi tuần chỉ vài task x 500 XP; XP run còn trần ngày (1500/2000, `capRunXp`). Chấp nhận được.
- N11. **claim `mission` Stone**: trần stone/ngày đọc rồi ghi không có position row, hai claim song song cho 2 run thắng khác nhau cùng vượt trần ngày được (chỉ cần 2 run mission thắng cùng ngày). Thêm position row `mission_stone:<pid>:<day>:<used>` như buy ticket.
- N12. `syncPassXp` chạy trên MỌI request, tối đa 50 batch tuần tự mỗi lần (economy.js:~92). Đúng nhưng nặng khi người chơi có nhiều run chưa đếm; cân nhắc chỉ sync ở GET /api/econ và claim `pass`.

## Vòng 3 — 1940288 (test 314/314, `bash -n tools/reset_m1.sh` OK)
**Verdict: APPROVE.** R1, N8 (một phần), N11, N12 đã xử lý; không còn CHẶN.
- R1 xong: `pass_xp` có trong SQL reset và TABLES dry-run. `--remote --yes` phải gõ đúng "RESET axie-dice-db", snapshot `d1 export` bắt buộc thành công và không rỗng trước khi xoá. Dry-run vẫn là mặc định.
- N8: `runTimeOk` (economy.js ~254) dùng giờ server `closed_at - created_at >= min_secs_per_row x rows` (won phải đủ hàng cuối). Chặn run mở-đóng tức thì, nhưng `pw` và `len` trong summary vẫn do client khai nên run "lost, pw=1" chỉ cần vài giây, và chưa có giới hạn mở nhiều run song song. Giảm tốc farm, không chặn hẳn; chấp nhận cho tới verifier B3.
- N11: position row `stonepos:<day>:<used>` đúng. N12: cursor `counted_to` giảm quét lại; run đóng với `closed_at` nhỏ hơn cursor sẽ bị bỏ qua (hiếm vì closed_at là giờ server đơn điệu). Run không qua `runTimeOk` vẫn ghi marker với XP 0 nên không quét lại.
- Lưu ý triển khai: cột `counted_to` thêm thẳng vào `0011_economy.sql`. Nếu 0011 đã áp trên DB nào (staging/local) thì phải tạo lại bảng `pass_xp`, hoặc tách `0012 ALTER TABLE`. Production chưa áp thì không sao.
- `land` ghi rõ chỉ cosmetic, chấp nhận.
