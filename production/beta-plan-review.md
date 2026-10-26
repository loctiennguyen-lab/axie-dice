# Review plan beta (`production/beta-plan.md`)

Người review: producer (độc lập, không viết plan) · 26/10/2026 · Chỉ đọc code/doc, không chạy Godot.
Đã xét cả 10 câu trả lời Liam ghi ở đầu 3 doc brainstorm (5 chỗ khác khuyến nghị: 2, 3, 6, 8, 9) và tin Atia/cosmetics.

## Verdict: APPROVE WITH CHANGES

Khung làn, quy tắc worktree, quy trình release và rollback ổn. Nhưng plan viết trước khi Liam trả lời từng câu nên giờ
sai ở 5 chỗ. Beta chạy chủ yếu desktop mà plan chỉ có đường release web. Hai chỗ đó phải sửa trước khi mở làn.
Sửa xong thì rút lịch được khoảng 10 ngày (giao Liam polish ~27/11 thay vì 7-8/12).

## CHẶN

**C1. Plan đi ngược 5 câu Liam vừa trả lời.** Phải sửa:
- Dòng 7 + LD-D: "tier 2 giữ 40k, không hạ giá" → Liam cho **hạ tier 2 xuống 20k** (sẽ xoá tiến độ sau beta). LD-D tính lại m1-m8 với 20k + 2 Rare + 8 common; phương án (a)/(b) viết lại vì giả định "tier vẫn 40k" không còn.
- N-W việc 3 + rủi ro "N4-N6 giữ tắt tới đó" + R1b: Liam **bật cược cả 6 bậc**, Worker kiểm rules/mở bậc vẫn làm nhưng **không chặn bật**. Bỏ cờ `tier_locked` chờ R1b. Lưu ý: `missions.json` được Worker import thẳng (`missions.js:9`) và client chặn ở `RunState.begin_run` qua `MissionBoard.tier_enabled`, nên bật bậc = sửa data + deploy cả Worker lẫn client cùng đợt.
- §6 ngày 3-8/11, §8 dòng "số m không khớp người", §9 câu 1: Liam **khoá số theo sim bot**, không chơi 30 run. Bỏ bước 2b và câu 1. Hệ quả: sim N-S là nguồn số DUY NHẤT, nên tiêu chí "xong" của N-S (CI 95%, N6 cận trên < 5%) phải giữ chặt, không nới vì gấp.
- SR1: Liam chọn **M1 reset** (không nhập số dư) và **không trần payout ngày**. Bỏ khỏi SR1: nhập theo M2, số dư chờ, `econ_import`, trần ngày. Dòng 219 ("M2 nhập số dư, trần tạm theo ngày") ghi sai, sửa. SR1 từ L xuống ~M.
- LD-M + LD-A bước 4 (cờ web nhẹ): ưu tiên thấp, ra khỏi đường găng của R2. §9 câu 2 (máy Windows iGPU đo web) bỏ hoặc dời.

**C2. Không có đường release desktop.** §5 chỉ có `export-web.sh` → R2 → Worker. Beta chạy chủ yếu desktop thì mỗi đợt có
client đổi cần: `tools/build_desktop.sh` (mac + Windows), nơi đặt bản tải, cách báo tester. Thêm nữa, bản desktop cũ không tự
cập nhật: hết cửa sổ 7 ngày của `-t`, Worker trả `409 {error:'version'}` (`runs.js:57`). Tôi không thấy chỗ client đổi 409 đó
thành câu "có bản mới, tải lại". Đề xuất: (1) thêm bước desktop vào quy trình §5 và cột "Desktop" vào bảng đợt; (2) làn I (hoặc
N-C) thêm test + màn báo "cần bản mới" khi gặp 409 version, làm trước R1; (3) cửa sổ giữ `-t` tính từ ngày bản desktop mới
có link tải, không phải ngày deploy web.

## NÊN SỬA

**N1. Thứ tự lệch ưu tiên Liam ở Atia.** Liam xếp Nhiệm vụ > Land > **Atia** > Server RNG > cosmetics. Plan để Atia sau
SR1/SR-V (chỗ R5). Atia giờ có phạm vi (thêm quái mới từ kho Atia, brainstorm riêng). Đề xuất: brainstorm Atia chạy song song
3-7/11, làm ngay sau R2, trước SR1. Riêng SR0 làm sớm (R0) là đúng dù Server RNG xếp thứ 4: nó nhỏ, và giờ bật cả 6 bậc
mà không có trần payout thì kiểm tối thiểu ở `run_close` là thứ duy nhất soi "thắng giả" để mở bậc/nhận thưởng. Ghi rõ lý do này trong plan.

**N2. Bump RULES_VERSION: lẫn "đổi fingerprint" với "đổi kết quả run".** `t_rules_version` canh cả thư mục
`autoload`, `scripts/meta`, `scripts/core`, `assets/data/rules`. Vậy prelude (sửa `MetaState.gd`), N-C (`mission_board.gd`),
SR1 (`MetaState`, `RunState`) đều đổi fingerprint. Có tiền lệ (14/10, Land upgrade): chỉ cần ghim lại FINGERPRINT kèm ghi chú
"Run result: NO", không bump. Đề xuất: bỏ điều kiện "-v nếu file Land nằm trong fingerprint" (Land không đổi kết quả run thì không cần
-v). Ngược lại, **quái Atia mới chắc chắn đổi kết quả run → cần bump riêng**, plan đang nói "một lần duy nhất -u" là thiếu. Một `-u`
ở R1 đủ cho V5 + Nhiệm vụ, với điều kiện mọi thay đổi `mission_rules.json`/`ascension.json` xong TRƯỚC R1 (không còn hiệu chuẩn nên làm được).

**N3. Run Nhiệm vụ đang dở lúc bump bị mất cược.** Client không chơi tiếp run khác luật (`RunState.gd:2041`); escrow chỉ hoàn khi
`epochs === 0` (`runs.js:183`), còn lại thành `lost`. Ngày deploy R1, ai đang dở run N1-N3 sẽ mất Shard vì lỗi của mình. Đề xuất: N-W
cho `reconcileEscrows` hoàn cược khi `runs.rules_version` khác bản hiện tại, có test. Thêm: Worker chỉ có MỘT bảng mission (bản -u),
nên trong 7 ngày giữ `-t` thì run thường nhận cả hai bản, còn run Nhiệm vụ chỉ nhận `-u` (client cũ nhận lỗi rõ, không phải `rules_mismatch` khó hiểu).

**N4. Chồng file `runs.js`.** Kiểm mở bậc lúc mua phải đọc D1 theo người chơi, mà `validateMission` hiện đồng bộ, gọi ở `runs.js:70`
(file plan giao cho SR-W). Đề xuất: cho N-W đúng chỗ gọi đó (ngoại lệ có tên, như `loadPckManifest` ở `index.js`); SR0 không đụng `runs.js`.
Ghi luôn giới hạn vào tiêu chí "xong" của N-W: sửa save thì bị chặn, nhưng `won` vẫn do client báo tới B3 nên run giả vẫn mở được bậc.
Liam đã chấp nhận rủi ro này ở câu 9; plan nên ghi thẳng ra, đừng viết "không mua được N2 khi chưa thắng N1" như thể đã chặn hết.

**N5. Prelude chỉ thêm field thì chưa đủ.** LD-A bước 3 (tặng 90 Shard một lần) và N-C (đọc cache mở bậc) cần hàm trong `MetaState`,
không chỉ field. Đề xuất: prelude thêm luôn hàm rỗng/đơn giản (`grant_land_gift_once()`, `set_mission_unlocks()`), làn chỉ sửa thân
hàm qua yêu cầu cho I. Đổi tên `land_starter_granted` (dễ nhầm với `starter_granted` đã có, `MetaState.gd:103`) thành `land_gift_granted`.
Field Land phải tính lại theo tier 20k trước khi ghi prelude.

**N6. Reset M1 phải đi qua cloud save.** Nếu chỉ đặt 0 ở ví server mà save client/cloud còn số cũ, `reload_from_store()` hoặc lần đồng
bộ sau sẽ đưa số cũ về. Đề xuất: SR1 làm reset qua `SaveStore` + ghi đè cloud save, có test "đăng nhập máy khác sau reset thấy 0".
R3 là điểm không quay lại (rollback Worker không trả lại số dư): snapshot cả `d1 export` lẫn bảng cloud save trước khi chạy, và Liam
báo tester trước. Cần Liam nói rõ reset gồm những gì (xem câu hỏi).

**N7. Khoá Godot.** Brief nói khoá chung làm các làn chạy tuần tự. Không còn đúng: từ `l1-lanes.md` (dòng 45) mỗi worktree có user dir
+ khoá riêng, plan dòng 188 viết đúng. Giới hạn thật là CPU, và khoá TRONG một worktree: sim N-S chạy nhiều giờ giữ khoá `beta/ns` làm
chính làn đó không chạy được test. Đề xuất: sim chạy ở worktree riêng (`ns-sim1..n`, mỗi cái override.cfg riêng), `beta/ns` chỉ để viết tool.
Không chạy suite merge của I cùng lúc với sim đầy CPU (dễ ra hang-kill giả).

## GỢI Ý

- G1. V5 cần ép 2 Luật run khi sim. `sim_balance.gd` có `--force` (Lõi) nhưng chưa chắc ép được Luật run, mà V5 không được sửa file này. Ngày 1 N-S thêm cờ đó cho V5.
- G2. N-W viết test theo fixture bảng 6 bậc, đừng dựa vào `missions.json` hiện tại vì N-C sẽ thay bảng.
- G3. SR-V (verifier chạy bóng) không giúp người chơi beta thấy gì và chi phí Containers chưa biết. Cho nó chạy nền, không chặn QA tổng/polish.
- G4. LD-R (5 thưởng mốc trùng pool): giao luôn cho đợt khung cosmetics (Liam cho agent tự chọn số), có ngày, khỏi treo test đỏ.
- G5. Mỗi đợt có Nhiệm vụ: QA thêm FLOW "bump giữa run Nhiệm vụ → được hoàn cược" (N3).

## Lịch đề xuất (bỏ hiệu chuẩn + bỏ nhập số dư)

| Ngày | Việc |
|---|---|
| 27-28/10 | Prelude (field theo 20k + hàm), mở worktree, N-S tool, V5 vòng 1, N-W, SR0, LD-D, CL |
| 29-30/10 | R0 (SR0 chỉ-ghi). Anchor đóng băng 28/10. Brainstorm Atia + cosmetics bắt đầu song song |
| ~4-5/11 | **R1 = Nhiệm vụ đủ 6 bậc** nếu sim xong; trễ thì N1-N3 trước, N4-N6 ngay khi có số (không chờ ai chơi). Có cả bản desktop |
| ~7-9/11 | **R2 Land** (LD-A 1-3, LD-B, tier 20k; cờ web nhẹ để sau) |
| ~10-17/11 | Atia (theo brainstorm, bump riêng) ∥ SR1 bản M (M1 reset, không trần) |
| ~18-21/11 | R-Atia, R3 (SR1 + B4, reset). SR-V chạy nền |
| ~22-26/11 | Khung cosmetics + LD-R, rồi QA tổng 2 ngày → giao Liam polish **~27/11** |

Phần chưa chắc nhất vẫn là tốc độ sim (N-S) và phạm vi Atia; hai brainstorm đó chưa có nên ngày ~10/11 trở đi là ước.

## Câu hỏi cho Liam (thay 3 câu cũ)

Câu 1 (30 run) và câu 2 (máy iGPU) thừa. Giữ câu 3 (cho sim chạy đêm, không chơi save thật khi QA cây chính). Thêm 2 câu:
1. **Tester nhận bản desktop thế nào và có chấp nhận "bản cũ không chơi được, phải tải bản mới" không?** Khuyến nghị: có, link tải cố định + màn báo khi gặp 409 version.
2. **Reset M1 gồm gì và lúc nào?** Shard, Stone, unlock, cả tier/decor Land và chuỗi thắng Nhiệm vụ? Khuyến nghị: reset tất cả trừ Gem và lịch sử run, làm ở R3 trước khi mời tester rộng, để không phải xoá hai lần sát nhau.

## Vòng 2 (26/10): plan v2

**Verdict: APPROVE.** Cả 2 CHẶN đã đóng: plan khớp 5 câu Liam trả lời, có đường release desktop, màn 409 và cửa sổ `-t` tính từ link tải.
N1-N7 và G1-G5 đã xử lý hợp lý. Còn 4 chỗ nhỏ dưới đây. Làn tự sửa trong lúc làm được, không cần thêm vòng review plan.

Kiểm 3 chỗ người viết chưa tự kiểm:
- `runs.js:70`: đúng. `validateMission(body.mission, ascension)` đồng bộ, không có `env`/người chơi, nên N-W phải sửa chỗ gọi. Sửa luôn comment dòng 66 ("N4..N6 are locked in this build").
- `RunState.gd:2041`: đúng, kèm kiểm ở 2079/2153. Save khác luật bị từ chối, rồi `remote_epoch_source.gd` (~131-137) tự gọi `session.abandon` khi người chơi mở run mới.
- `runs.js:183`: plan ghi sai chỗ. Dòng 183 nằm trong `abandon()`, không phải `reconcileEscrows` (hàm đó ở `missions.js:84-90`). Đường mất cược thật lúc bump là: client mới tự abandon → `epochs > 0` → `lost`. Run bị cron dọn thì đi qua `reconcileEscrows` → `lost`.

NÊN SỬA (vòng 2):
- V2-1. N-W việc 3: hoàn cược phải sửa ở **cả hai** chỗ: `abandon()` (`runs.js:183`) và `reconcileEscrows` (thêm `r.rules_version` vào JOIN ở `missions.js:85`). "Bản hiện tại" lấy là phần tử cuối của `SUPPORTED_RULE_VERSIONS`. Không mở lỗ hoàn cược tuỳ ý vì tạo run Nhiệm vụ đã bắt buộc bản mới nhất. Test `missions_refund_on_bump` phủ cả 2 đường.
- V2-2. Prelude không cần đợi LD-D. Ba field (`land_tier_banner_seen` số, `land_gift_granted` bool, `mission_unlock_cache`) không phụ thuộc ngưỡng 20k, ngưỡng nằm ở `land_tiers.json`. Ở vòng 1 tôi viết "tính lại theo 20k trước khi ghi prelude" là thừa, rút lại. Bỏ mũi tên "Prelude (cần số LD-D)" để prelude chạy ngày 1 như cũ.
- V2-3. Rollback đợt có bump (R1, R-Atia): sau khi bản desktop `-u` đã phát, `wrangler rollback` đưa Worker về danh sách không có `-u`. Khi đó desktop mới gặp 409 và màn "tải bản mới" lại trỏ đúng bản đang bị lùi, thành vòng lặp. Ghi rõ: đợt có bump thì sửa tiến (hotfix), chỉ rollback Worker kèm đổi link desktop về `build/old/` cùng lúc.
- V2-4. Để R-Atia (~16-18/11) và R3 reset (~18-21/11) cách nhau ít nhất 2 ngày, để lỗi của mỗi đợt tách bạch. SR1 xếp M là lạc quan (ví nhiều currency + idempotency + tách save + reset qua cloud + B4); ước M-L, nếu trễ thì dời R-CF, không dời QA tổng.

Chỗ cắm Atia/CF: hợp lý. AT đứng trước SR1, đợi CL, bump `-v` riêng, sim ở worktree riêng; câu 4 cho Liam lối thoát nếu brainstorm Atia trễ. CF đi kèm LD-R, chỉ ghim fingerprint. Dòng 4 ghi "Atia chưa có": cập nhật thành `atia-roster-expansion-brainstorm.md` (đang review), điền phạm vi AT sau khi doc được duyệt. Trong mục 2, AT giữ "monster data": nếu file đó nằm trong `assets/data/rules` hoặc `autoload` thì I ghim và bump `-v` cùng đợt, không làn nào khác đụng.
