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
