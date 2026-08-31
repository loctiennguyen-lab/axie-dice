# COMBO — Memo quyết định
### Axie Dice Tactics · phụ lục cho `BLOODLINE_SYSTEM_v1.md` §4

> **Trạng thái:** cần anh chốt. Khuyến nghị đã đổi so với doc v1.1 sau khi mô hình hoá.
> **Tự audit:** phân tích v1 của tôi có một lỗi code chí mạng (tham số `scope` không được thi hành → TEAM và TARGET chạy cùng công thức). Mọi số ở memo này là từ mô hình v2 đã viết lại. Nhật ký ở §6.

---

## 1. Phát hiện nền: Axie Dice không có quyết định "dùng mặt nào"

Trong Axie Origins, chain/combo là quyết định **vì energy giới hạn số thẻ bạn đánh**. Trong Axie Dice, **mọi mặt roll ra đều được dùng** — không có gì để đánh đổi. Hai bề mặt quyết định duy nhất là:

1. **Reroll** — die nào đổi
2. **Gán** — mỗi mặt đi đâu

⇒ Bất kỳ luật combo nào key vào *cái bạn roll ra* đều **không phải quyết định, mà là stat do RNG phát**. Đây là bộ lọc chính để loại phương án.

---

## 2. Bốn phương án, kết quả đo

Điều kiện chung: thr=3 · bonus 20% **tuyến tính** · cap 30% · OFF-density khống chế 3/6 mọi class · gán tối ưu brute-force · overkill bị lãng phí · thưởng mạng 6.0.

### Option A — PER-HERO (nhiều mặt trên một hero)

**Loại — và vì lý do thiết kế, không phải chi phí.**

Một hero thực thi N mặt sẽ nhắm vào **một mục tiêu**. Nghĩa là nhóm combo trong Option A **luôn dùng chung mục tiêu** — tức nó *bằng đúng về mặt toán học* với Option B. Điểm khác biệt duy nhất có thể có là "hero cho đi mặt thì không hành động", nhưng cái đó chỉ có giá nếu hành động mang giá trị **ngoài** bản thân mặt xúc xắc — tức phải có passive/trigger theo hero, thứ hiện chưa tồn tại trong engine.

⇒ **A = B + viết lại mô hình engine + thêm một khái niệm UI, đổi lấy zero khác biệt cơ học.** Bị trội hoàn toàn. (Doc v1.1 §4.1 khuyến nghị A — **khuyến nghị đó sai**, và đây là chỗ sửa quan trọng nhất.)

### Option B — TARGET (cùng mục tiêu)

**Loại.** Chi phí cơ hội đo được ≈ 0.

| Encounter | Δpower | Tần suất kích hoạt |
|---|---|---|
| BOSS 1×90 | +1.9% | 10.8% |
| ELITE 2×45 | +2.5% | 10.8% |
| PACK 3×28 | **+0.0%** | 7.9% |
| SWARM 5×14 | **+0.0%** | **0.0%** |

Ba vấn đề:

- **Dồn hoả lực vốn đã là chiến lược trội** trong mọi game tactics. Thưởng cho việc người chơi đã làm sẵn = stat, không phải quyết định. Đo bằng bộ giải tối ưu: combo làm **đổi** cách gán ở ≤1.6% số lượt.
- **Với boss (1 địch), B ≡ TEAM về toán học** — không có lựa chọn dồn hay dàn. Ta không thể loại TEAM vì "không cần quyết định" rồi chọn một phương án có đúng tính chất đó trong mọi trận boss.
- **Với swarm, cơ chế tự tắt** (+0.0%) — overkill nuốt sạch bonus. Cái thay đổi theo encounter là **payout**, không phải **chi phí**. Đó là phương sai, không phải quyết định.

### Option C — TEAM (đếm toàn đội)

**Trung thực nhưng quá yếu để trả giá hệ thống.** +0.6% đến +2.5% power ở thr=3. Hai cách làm nó có nghĩa, cả hai đều hỏng:

- Hạ ngưỡng xuống 2 → kích hoạt **67%** số lượt ⇒ thành stat.
- Nâng bonus → suy biến build dồn part: die 3/6 horn = +35%, **die 5/6 horn = +81%**. Và §5.5 Meta Morph *thiết kế sẵn* con đường dồn part đó.

### Option D — DECLARE ("Gọi mặt") · **KHUYẾN NGHỊ**

Đầu lượt, người chơi **tuyên bố một loại part** sẽ đuổi theo. Reroll để đuổi. Đạt ngưỡng → bonus lớn. **Trượt → không được gì, và đã tiêu reroll.**

| Party | Reroll | Tỷ lệ trúng | Δpower | σ/µ (swing) |
|---|---|---|---|---|
| mono-beast | 1 | 51% | +18.8% | 17.7% |
| mono-beast | 2 | 55% | +24.2% | 17.4% |
| 3 Plant + 2 Beast | 1 | 33% | +13.2% | 15.3% |
| 3 Plant + 2 Beast | 2 | 37% | +17.6% | 15.6% |
| toàn khác class | 1 | 31% | +12.8% | 15.2% |
| toàn khác class | 2 | 32% | +15.8% | 15.0% |

Vì sao đây là phương án duy nhất đạt mục tiêu thiết kế:

- **Giá trị đến từ một lựa chọn có rủi ro**, không phải từ bonus thụ động. Trượt 45-69% số lần là **thất bại thật**.
- **Nó làm đúng thứ §4.2 muốn**: biến reroll từ công cụ *sửa sai* thành công cụ *theo đuổi*. Ba phương án kia đều không làm được — chúng thưởng cho cái bạn đã có.
- **Không đổi mô hình engine.** Không cần nhiều mặt trên một hero. Một phần tử UI, một quyết định mỗi lượt.
- **Δpower +13-24%** ≈ 1.5-3 item, và **σ/µ 15-18%** chính là juice — độ nảy giữa các lượt, thứ ba phương án kia không tạo ra.

Điểm cần biết: tỷ lệ tuyên bố là **~100%** — "có tuyên bố không" không phải quyết định. Quyết định nằm ở **tuyên bố cái gì**, và ở đó có kỹ năng thật (đọc die của cả đội, ước lượng xác suất, cân giữa mặt đang cầm và mặt đang đuổi).

---

## 3. BLOODCHAIN — luận điểm trực giao đã bị bác bỏ

Doc v1.1 và phân tích đầu của tôi đều tuyên bố hai trục không tương quan. **Sai.** Bằng chứng ban đầu là artifact: "mono-class" trong mô hình cũ là mono-**Plant**, class có ít mặt tấn công nhất — tôi đang đo mật độ tấn công chứ không đo độ đa dạng class.

Đo lại ở **OFF-density khống chế** (mọi class đúng 3/6 mặt tấn công):

| Party | combo:2 | combo:3 |
|---|---|---|
| mono-plant | 67.3% | **24.5%** |
| mono-beast | 67.2% | 24.4% |
| mono-bird | 67.2% | 24.4% |
| **toàn khác class** | 54.0% | **10.6%** |

Mono-class đạt combo:3 **gấp 2.3 lần**. Hai trục **tương quan dương**, và party mono-class ăn cả BLOODCHAIN lẫn combo rate cao nhất. Đây đúng là kịch bản thất bại §4.1 đã cảnh báo, chỉ là trước đó tôi tưởng đã tránh được.

**Đề xuất sửa: BLOODCHAIN không được thưởng bằng damage.**

Cho nó trả bằng **tài nguyên khác trục**: +1 charge reroll, +mana, +shield, hoặc cleanse. Khi đó nó không cộng dồn với COMBO trên cùng một đại lượng, và trực giao là **do cấu trúc**, không phải do may mắn thống kê. Bonus: +1 reroll lại chính là thứ nuôi Option D — mono-class chơi được "gọi mặt" tự tin hơn, đúng fantasy chain của Origins, mà không nhân damage.

Giữ nguyên: dưới tuyến tính, có cap (2 hero = mức 1, 5 hero = mức 3, không phải 4 mức).

---

## 4. Dải giá trị đề xuất (để sim.js xác nhận, không phải để ship thẳng)

| Tham số | Đề xuất | Lý do |
|---|---|---|
| Ngưỡng | **3** | thr=2 kích hoạt 54-67% ⇒ thành stat |
| Bonus | **+30-35%** trên các mặt trúng, **tuyến tính** | bù cho tỷ lệ trượt 45-69% |
| Cap tổng | **+35%** | §4.3 #1; chặn suy biến bậc hai |
| Reroll charge | **1 base, 2-3 qua upgrade** | charge thứ 2 chỉ +4pp tỷ lệ trúng ⇒ upgrade có giá trị nhưng không phá |
| BLOODCHAIN | **không phải damage** | §3 |

---

## 5. Giới hạn của mô hình — đọc trước khi trích số

Mô hình này **chỉ để chọn giữa các phương án**, không để chốt giá trị ship.

Không mô hình hoá: shield & status, relic, cơ chế boss, đường cong reward, hành vi địch, thứ tự hành động, trạng thái nhiều lượt. Giá trị mặt là hằng số giả định. Người chơi được giả định chơi tối ưu (brute-force), người thật sẽ yếu hơn — nên Δpower thực tế **thấp hơn** con số ở đây.

**Mọi giá trị ship phải qua `sim.js` với đầy đủ engine, 500+ run, và chỉ số nghiệm thu là *archetype diversity* chứ không chỉ winrate** (§9 #2).

---

## 6. Tự audit — nhật ký sửa v1 → v2

| # | Lỗi trong phân tích v1 | Ảnh hưởng | Đã sửa |
|---|---|---|---|
| 1 | 🔴 Tham số `scope` khai báo nhưng **không được đọc** — TEAM và TARGET chạy cùng công thức | Toàn bộ bảng so sánh chỉ đo tác dụng của reroll, không đo cơ chế | Viết lại, scope thi hành thật, có encounter/HP/gán/overkill |
| 2 | 🔴 Luận điểm trực giao là artifact của DIE_BIAS tự chọn (mono = mono-Plant = ít mặt OFF nhất) | Kết luận đảo dấu khi kiểm soát | Khống chế OFF-density 3/6; kết luận **bị bác bỏ**, xem §3 |
| 3 | 🔴 Không mô hình chi phí cơ hội thật của TARGET | "Chi phí cơ hội thật" là suy đoán, đo ra ≈0 | Bộ giải gán tối ưu; TARGET **bị loại** |
| 4 | 🟠 `dps_multiplier` **không áp ngưỡng** — mọi số DPS là thr=2 trong khi đề xuất thr=3 | Phóng đại ~2× | Ngưỡng được áp |
| 5 | 🟠 Bonus **bậc hai** theo kích thước nhóm, không có cap — vi phạm chính ràng buộc §4.3 #1 của doc | Suy biến: die 5/6 horn = +81% | Tuyến tính + cap |
| 6 | 🟠 `greedy_reroll` reroll **tất cả** die không khớp (2.76 die/charge) và đuổi theo part không phải OFF ở 59% số lượt | "+23% giết TEAM" thực ra ≈ 3 lần reroll đơn | 1 die/charge, chỉ đuổi part OFF |
| 7 | 🟠 Cộng thẳng BLOODCHAIN % với damage-per-OFF-face — khác mẫu số | Sai đơn vị | Chỉ số power thống nhất |
| 8 | 🟡 Option A chưa từng được mô hình hoá, bị loại bằng lập luận chi phí | Lỗ hổng lập luận | §2 loại A bằng lập luận thiết kế |
| 9 | 🟡 Chỉ đếm nhóm lớn nhất, bỏ qua nhóm thứ hai | Dưới-ước lượng TARGET | Ghi nhận; không đổi kết luận |

**Điều rút ra cho quy trình:** đây là lần thứ hai liên tiếp một vòng kiểm chứng độc lập lật ngược kết luận chính. Với mọi thay đổi hệ thống từ nay, mô hình định lượng + audit chéo là bước bắt buộc **trước** khi trình, không phải sau.
