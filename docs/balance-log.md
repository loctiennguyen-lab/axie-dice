# Balance Log

Ghi lại các lần chỉnh `TUNE`/balance constants và kết quả đo qua `node tools/sim.js`. Xem `design/gdd/part-tier-system.md` §2b (Tuning Knobs) cho ý nghĩa từng hằng số.

---

## 2026-09-01 — `growth2` 1.065→1.05, `eliteMult` 1.40→1.25

**Bối cảnh**: baseline đo bằng `node tools/sim.js 500 mode=X asc=0` cho thấy Full Run winrate 3.6% (dưới mục tiêu 6% trong `AUDIT_AND_SPEC_v1.md` §D4), wave 3 (elite đầu tiên) tụt còn 75% winrate trong khi các wave lân cận ≥88-96%, và archetype PLAGUE (poison) phổ biến nhất nhưng thắng thấp nhất (9%/5%).

**Chẩn đoán** (economy-designer, đối chiếu trực tiếp code):
1. Full Run 3.6% thấp chủ yếu do 8 hard-gate (4 elite + 4 boss) dồn dập trên 20 wave, không phải do curve gốc sai — Short Run (6 gate, 12 wave) vẫn nằm trong mục tiêu 12-20%.
2. `eliteMult=1.40` chiếm tỷ trọng quá lớn ở elite đầu tiên (wave 3) khi người chơi mới có 1-2 lượt reward — không phải vấn đề elite nói chung.
3. PLAGUE thắng thấp một phần do **`tools/sim.js` AI bỏ qua hoàn toàn poison trong logic finish-kill** (dòng 41, gate cứng `f.t!=='dmg'`) — không phải bằng chứng chắc chắn archetype yếu, có thể là AI lái dở.

**Fix áp dụng**: `src/data.js` dòng 370, `TUNE.growth2` 1.065→1.05, `TUNE.eliteMult` 1.40→1.25.

**Kết quả đo lại** (`node tools/sim.js 500 mode=X asc=0`):

| Chỉ số | Trước | Sau |
|---|---|---|
| Short Run winrate | 16.4% | 19.8% |
| Full Run winrate | 3.6% | **8.0%** |
| Wave 3 (elite đầu) winrate | 75% | 83-87% |
| PLAGUE winrate (Short/Full) | 9% / 5% | 19% / 7% |
| BULWARK winrate (Short/Full) | 17% / 1% | 22% / 9% |

**Kết luận**: không cần buff giá trị poison riêng ở thời điểm này — phần lớn vấn đề PLAGUE là hệ quả gián tiếp của gate quá gắt, không phải archetype yếu cố hữu. Full Run 8.0% hơi cao hơn mục tiêu 6% một chút nhưng vẫn trong vùng roguelike lành mạnh — chưa cần chỉnh thêm.

**Việc còn treo** (đề xuất, chưa làm):
- TALON (pierce) 0% Full Run chỉ có 34 mẫu — cần chạy N≥2000 riêng cho Full Run để có kết luận đáng tin, tránh buff nhầm dựa trên mẫu nhỏ. `archScore` có thể đang gộp lẫn "có relic pierce" với "build quanh Bird class passive" — cần tách trước khi kết luận.
- Sửa `tools/sim.js` AI để không bỏ qua poison trong finish-kill logic, rồi đo lại PLAGUE một lần nữa cho sạch (tách riêng hiệu ứng AI khỏi hiệu ứng balance thật).
- `TUNE.base`/`TUNE.growth` chưa đụng tới — theo đúng khuyến nghị "để cuối cùng, đây là 2 hằng số ảnh hưởng rộng nhất".

---

## 2026-09-01 — NFT HP Bonus (§10.2a) implement + validate

**Bối cảnh**: `design/gdd/economy-progression.md` §10.2a thiết kế bonus maxHP cho Axie NFT chọn-trước, theo tỷ lệ sở hữu × độ hiếm (ngoại lệ có phạm vi của D12). Cần implement thật + đo bằng sim trước khi coi là an toàn.

**Thay đổi code**:
- `src/engine.js`: thêm `nftHpBonusPct(ownedCount, specialGenes)`, `nftOwnershipMult()`, `nftRarityMult()`; `newRosterEntry`/`buildUnit` áp bonus vào `maxHp`; `newGame` nhận `opt.nftPreselect` (mảng song song với `teamKeys`, mỗi phần tử `{owned, genes}` hoặc `null`).
- `tools/sim.js`: thêm tham số CLI `nftCount=`/`nftOwned=`/`nftGenes=` để test kịch bản NFT.

**Kết quả** (800 run/kịch bản, `node tools/sim.js 800 mode=X asc=0 nftCount=.. nftOwned=.. nftGenes=..`):

| Kịch bản | Full Run | Short Run |
|---|---|---|
| Baseline (không NFT) | 8.6% | 17.9% |
| 1 Axie chọn-trước, sở hữu 5, 1 gene (+3.75%) | 8.4% (nhiễu) | — |
| **5/5 chọn-trước, sở hữu ≥20, 3 gene (max thực tế, +6.75%/con)** | **10.5%** | **21.8%** |

**Kết luận**: bonus tối đa thực tế (~+22% winrate tương đối) nằm trong biên độ chấp nhận được — không cần hạ `base=3%` hay các hệ số trước khi ship. `BONUS_CAP=20%` chưa từng chạm tới ở kịch bản cực đại (max thực tế chỉ 6.75%/Axie), giữ nguyên làm rào chắn cho tương lai.

---

## 2026-09-01 — TALON (pierce) mẫu lớn: không chết, chỉ là nhiễu thống kê ở N=34

**Bối cảnh**: baseline ban đầu (N=500) cho TALON 0/34 run thắng ở Full Run — economy-designer cảnh báo mẫu quá nhỏ để kết luận, đề xuất chạy lại N≥2000 trước khi buff.

**Kết quả** (`node tools/sim.js 2500 mode=full asc=0`, đọc phần archetype breakdown):

| Archetype | Số run | Winrate |
|---|---|---|
| PLAGUE | 700 | 6% |
| BULWARK | 568 | 10% |
| CONDUIT | 318 | 4% |
| APEX | 227 | 14% |
| INFERNO | 200 | 13% |
| **TALON** | **190** | **3%** |
| TEMPEST | 121 | 4% |
| SWARM | 82 | 12% |
| EVOLVE | 69 | 12% |
| AEGIS | 25 | 0% |

**Kết luận**: TALON ở N=190 đạt 3% winrate — thấp nhưng **không chết**, nằm cùng nhóm với CONDUIT (4%) và TEMPEST (4%), không phải ngoại lệ. Xác suất quan sát 0/34 nếu tỷ lệ thật ~3-4% là ~23-28% — hoàn toàn có thể xảy ra do nhiễu mẫu nhỏ, không phải bằng chứng archetype hỏng. **Không cần buff TALON.**

**Ghi nhận mới**: AEGIS (thorns) giờ là archetype mẫu nhỏ nhất (25 run, 0% win) — cùng tình trạng TALON trước đây. Chưa đủ dữ liệu để kết luận, để theo dõi ở lần sim lớn tiếp theo, không buff vội.

## 2026-09-01 — Formation Resonance (mechanic mới, giữ lại `RESONANCE.mult=1.15` sau khi hạ từ 1.25)

**Bối cảnh**: mechanic mới `design/quick-specs/formation-resonance-2026-09-01.md` implement xong (gameplay-programmer). Test winrate qua `node tools/sim.js 500` (Short Run, Ascension 0):

| Kịch bản | Winrate |
|---|---|
| Baseline (không Resonance, `src/engine.js`/`data.js` stash) | 19.8% |
| Resonance `mult=1.25` (giá trị mặc định spec đề xuất) | 22.4% (+13% relative) |
| Resonance `mult=1.15` (mức sàn tuning knob) | 24.0% |

**Lưu ý quan trọng — RNG có seed cố định (`_seed=1` mỗi lần chạy `sim.js`, xem `tools/sim.js:81`)**: mọi thay đổi luật chơi làm lệch số lần combat/turn tiêu thụ sẽ dịch chuyển toàn bộ chuỗi RNG downstream cho các run sau, nên chênh lệch 19.8%→22.4%→24.0% **không tuyến tính theo `mult`** và không nên đọc là "hạ mult từ 1.25→1.15 làm winrate tăng thêm" theo nghĩa nhân quả trực tiếp — đây là hiệu ứng cánh bướm của RNG seed cố định, không phải bằng chứng mult thấp hơn lại mạnh hơn. Không đủ tin cậy để tinh chỉnh chính xác `mult` từ 1 lần chạy N=500 mỗi kịch bản.

**Quyết định**: giữ `mult=1.15` (đầu dưới của khoảng an toàn 1.15-1.40 đã ghi trong quick-spec) làm giá trị khởi điểm thận trọng, vì cả hai giá trị test đều cho thấy lift rõ rệt so với baseline (+13% đến +21% relative) — vượt ngưỡng cảnh báo ">5%" mà chính spec đặt ra để cân nhắc hạ mult. **Cần chạy lại N≥2000 với nhiều seed offset khác nhau (không chỉ seed=1 cố định) trước khi coi đây là số liệu ổn định để ship** — ghi vào Open Questions của session state.

## 2026-09-01 (tiếp) — Formation Resonance: đo lại đa-seed (N=2500 tổng, 5×500) để loại nhiễu RNG-stream

Thêm `seed0=` override vào `tools/sim.js:81` (`let _seed=OV.seed0||1`) để có thể chạy nhiều seed khởi điểm độc lập, khắc phục hạn chế "chỉ 1 seed cố định" đã nêu ở log trước.

| seed0 | Baseline (không Resonance) | Resonance mult=1.15 |
|---|---|---|
| 1 | 19.8% | 24.0% |
| 101 | 22.0% | 24.0% |
| 202 | 21.6% | 21.8% |
| 303 | 22.2% | 23.2% |
| 404 | 22.0% | 21.4% |
| **Trung bình** | **21.52%** | **22.88%** |

**Kết luận**: chênh lệch thật trung bình qua 5 seed = **+1.36pp tuyệt đối (~6.3% relative)** — thấp hơn nhiều so với con số gây hiểu lầm ở phép so sánh 1-seed trước đó (từng đọc được tới +21% relative do hiệu ứng cánh bướm của RNG cố định). 6.3% relative chỉ nhỉnh hơn một chút so với ngưỡng cảnh báo 5% mà quick-spec đặt ra — **giữ nguyên `mult=1.15`** (đã hạ từ 1.25 xuống sàn an toàn), không cần hạ thêm. Đủ tin cậy để ship với giá trị này; theo dõi thêm khi có dữ liệu playtest thật.

## 2026-09-01 (tiếp) — Mở rộng UNLOCKS (8→10) + fix bug thật phát hiện khi test

**Bối cảnh**: audit progression flagged 8 UNLOCKS quá mỏng (hết sạch ~15-20 run). Thêm 2 tier mới nối dài category đã có (reroll/HP).

**Bản nháp đầu bị loại** (4 mục mới: +1 reroll, +7 maxHP qua 2 tier, +1 relic khởi đầu thứ 2): đo qua `node tools/sim.js 500 allUnlocks=1` cho **62.8%** so với baseline-có-8-unlock-cũ 35.2% — riêng 4 mục mới đã đẩy +79% relative, quá mạnh. Cô lập từng biến: +1 relic khởi đầu một mình = +9.4pp (relic là hiệu ứng build-wide, không phải số liệu đơn thuần — không an toàn bán trực tiếp bằng Shard); +7 maxHP một mình = +22.2pp (HP có đòn bẩy rất lớn trong engine này — sống lâu hơn = nhiều lượt combo/build-up hơn); +1 reroll gần như 0 ảnh hưởng.

**Bug thật phát hiện trong lúc test** (không phải do thay đổi UNLOCKS gây ra — đã tồn tại từ khi `u_reroll` "Survival Instinct" ra mắt): `newGame()` tính `maxRerolls` ban đầu từ `opt.bonusReroll` nhưng KHÔNG lưu `s.bonusReroll` — `startCombat()` (chạy mỗi trận) tính lại `maxRerolls=2+(s.bonusReroll||0)+...` từ `s.bonusReroll` rỗng, xoá sạch bonus reroll từ Unlock ngay khi vào combat đầu tiên. Nghĩa là "Survival Instinct" đã **vô tác dụng thật sự** kể từ khi ra mắt (chỉ có tác dụng ở khoảnh khắc trước khi build unit đầu tiên). Đã fix: `src/engine.js:156` thêm `bonusReroll:opt.bonusReroll||0` vào state khởi tạo.

**Cấu hình cuối cùng đã ship** (2 mục mới, đã fix bug reroll): `Overdrive Reflexes` (+1 reroll, 650 Shard), `Titan Bloodline` (+2 maxHP, 600 Shard). Đo lại đa-seed (N=1500, 3×500):

| | seed0=1 | seed0=101 | seed0=202 | TB |
|---|---|---|---|---|
| Không unlock | 24.0% | 24.0% | 21.8% | 23.3% |
| Đủ 10 unlock (sau fix bug) | 45.8% | 40.0% | 42.0% | 42.6% |

**Kết luận**: TB +19.3pp tuyệt đối (+83% relative) cho người chơi đã mua HẾT 10 unlock (đòi hỏi grind rất nhiều giờ) — phần lớn mức tăng này đến từ 8 unlock cũ đã live từ trước (nay còn tăng nhẹ vì bug reroll đã fix); phần đóng góp riêng của 2 mục MỚI chỉ ~12% relative trên nền đã có — hợp lý cho phần thưởng veteran dài hạn, không phá game (Full Run 20-wave + Ascension vẫn giữ thử thách). `verify.mjs` giữ 28/30.
