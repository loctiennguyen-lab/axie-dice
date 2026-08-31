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
