# RELIC ROSTER EXPANSION — 50 relic mới (48 + 2 bắt buộc từ audit)

### Axie Dice Tactics · tài liệu ROSTER (không phải GDD)

> **Phạm vi:** file này chỉ chứa **nội dung relic mới**. Khung hệ thống (taxonomy, power-budget
> model, luật rarity-tier, luật anti-stacking/de-dup, sửa gốc `ARCH`/`faceArch()`, retune 44 relic
> hiện có, acceptance criteria) thuộc `design/gdd/relic-system.md` do `systems-designer` viết.
> **Tại thời điểm viết file này, `design/gdd/relic-system.md` CHƯA TỒN TẠI** (đã kiểm tra bằng glob).
> Vì vậy §2 ghi rõ mọi **giả định** tôi thiết kế dựa trên, để hoà giải khi merge.
>
> **Tác giả:** game-designer · **Ngày:** 2026-09-03
> **Đối chiếu code:** `src/data.js` (44 entry `RELICS` tại `:357`, `ARCH`, `PASSIVE`, `FACE_POOL`,
> `TUNE`/`CURVE`, `MON`/`BOSSES`), `src/engine.js` (`relicPool`, `mkReward`, `genRewards`, `rlist`/
> `rhas`/`rsum`/`rmax`/`rmul_`/`rcall`, `faceArch`, `doFace`, `execFace`, `dealDamage`, `applyShield`,
> `applyHeal`, `addStatus`, `tickStatus`, `archScore`, `playerUseRelic`, `genShop`).

---

## 0. TRẠNG THÁI SAU AUDIT INV-1 — bản đang đọc là bản ĐÃ RETUNE

> **Sửa đổi ngày 2026-09-03 bởi `systems-designer`.** Mọi con số trong tài liệu này đã được áp
> **nguyên văn** theo audit bắt buộc ở `relic-system.md` **§6.7.1 – §6.7.8**. Phần §1–§3 (chẩn đoán,
> dữ liệu sim, phát hiện từ code) **không đổi** — chúng vẫn là lý do tồn tại của từng relic. Phần
> §4–§17 đã được viết lại theo trạng thái sau audit.

### 0.1 Vì sao có bản retune này

Khiếu nại gốc của product owner: *"trước chưa có GDD nên các buff rất linh tinh và có tình trạng
buff tier dưới mạnh hơn tier trên"*. `relic-system.md` §3.12 biến khiếu nại đó thành một bất biến
đo được:

```
Band[r] = [C_r × 0.85, C_r × 1.15],  C_r = 13.2 × SIG[r],  SIG = [1, 1.4154, 2, 2.8308]
INV-1:  U_r < L_{r+1}  ∀ r ∈ {0,1,2}   VÀ   RP của mọi relic ∈ Band[rarity của nó]
```

| bậc | tâm `C_r` | `Band[r]` |
|---|---|---|
| 0 COMMON | 13.20 | **[11.22, 15.18]** |
| 1 RARE | 18.68 | **[15.88, 21.48]** |
| 2 EPIC | 26.40 | **[22.44, 30.36]** |
| 3 LEGENDARY | 37.37 | **[31.76, 42.98]** |

Các dải **không giao nhau do cấu tạo**: rời nhau đòi hỏi `(1+τ)/(1−τ) < 1.4130`; `τ = 0.15` cho
1.3529 ✓. Dung sai `±20%` của bản nháp cho 1.50 ⇒ **giao nhau là chắc chắn về mặt số học** — đó là
gốc toán học của khiếu nại.

**Kết quả đo trên 48 relic của tài liệu này: 37 vi phạm INV-1.** Tất cả đã được sửa theo bảng §0.2.
11 relic PASS nguyên trạng: `r_marrowdrill` `r_worldpiercer` `a_bloom` `r_broodpouch` `r_scalecrown`
`r_gorehook` `r_scentofblood` `r_pandemic` `r_bloodhymn` — cộng `r_talonedge` và `r_tinderbox`, hai
relic **hợp dải nhưng vẫn phải đổi bậc** vì AC-4 (phủ bậc), không phải vì RP.

### 0.2 Bảng thay đổi đã áp — 48 entry cũ

`RP sau` lấy nguyên từ `relic-system.md` §6.7; **không** được tính lại bằng tay ở đây.
`tools/t_relic.mjs` là trọng tài duy nhất cho INV-1 trên toàn bộ 94 relic.

| id | rar trước → sau | RP sau | Loại thay đổi | Tóm tắt |
|---|---|---|---|---|
| `r_talonedge` | 0 → **1** | 20.55 | bậc + phạm vi | pierce faces +2 **và** horn dmg faces +1 (AC-4: TALON thiếu RARE thứ 2) |
| `r_marrowdrill` | 1 | 19.13 | — | PASS. Thêm `mfPhase:'kw'`, `mload 0`, `ex []` |
| `r_thousandcuts` | 2 | 30.00 | **thiết kế** | mỗi đòn `ceil(f.v/2)+2` (trước: 0 RP — trung hoà damage, §7 E1) |
| `r_worldpiercer` | 3 | 42.86 | — | PASS, **cách trần 0.12 RP** — xem cảnh báo ở §5 |
| `r_dawnlance` | 3 | 38.90 | **thiết kế** | điều kiện `full HP` (tần suất ~30%) → **> 50% HP**, mọi đòn, +90% |
| `a_pinning` | 1 | 18.75 | sàn | damage **tối thiểu 6** ⇒ không còn là thẻ chết |
| `r_seedling` | 0 | 13.70 | cơ chế mới | thêm `growthAll:1` (G1) — `growthPlus` đơn thuần chỉ 3.14 RP |
| `r_heartwood` | 1 | 21.12 | cơ chế mới | `growthAll:2` từ lượt 2, **bỏ `ri(6)`** ⇒ hết tiêu RNG |
| `r_bloomscale` | 1 | 20.05 | magnitude | thêm `growthPlus:3` |
| `r_quickenroot` | 2 | 28.30 | phạm vi | guard `s.turn <= 1` ⇒ chỉ chạy từ lượt 2 |
| `r_worldtree` | 3 | 39.60 | **trần cứng** | `GROWTH_KEEP_CAP = 3` (trước: không trần, ≈70 RP) |
| `a_bloom` | 2 | 29.25 | — | PASS |
| `r_broodpouch` | 0 | 13.00 | — | PASS |
| `r_eggshell` | 1 | 16.40 | magnitude | Shield 3 → **2** (21.90 nằm trong vùng cấm) |
| `r_broodmother` | 1 | 18.50 | magnitude | thêm "*Egg gây thêm 1 damage*" |
| `r_apexbrood` | 2 | 23.50 | magnitude | Max HP +4 → **+8** |
| `r_hivequeen` | 3 | 38.00 | **thiết kế** | Egg nhận `modFace` của bạn; `tokenCap` 4 → **6**; `mload 2` |
| `a_clutch` | 1 | 16.00 | magnitude | `v:2` → **`v:1`** (2 egg/lượt = 52 RP) |
| `r_barbedhide` | 0 | 13.98 | magnitude | `thornsPlus` 2 → **1**, thêm rider *shield faces +1* |
| `r_bloodthorn` | 1 | 19.48 | hook + rider | `onThorns` → **`onDmgTaken`** (QĐ-2); thêm rider *shield faces +1* |
| `r_glassspine` | 1 → **2** | 23.80 | bậc | 23.80 nằm trong `Band[2]`; AEGIS thiếu EPIC thứ 2 |
| `r_retributor` | 2 | 23.80 | phạm vi | chỉ kích hoạt khi Axie bị đánh **đang có Shield** |
| `r_ironmaiden` | 3 | 33.25 | **phạm vi** | *mọi địch* → **một địch nhiều HP nhất**; cap 12 → **7** (`IRONMAIDEN_CAP`) |
| `r_scalecrown` | 3 | 39.50 | — | PASS |
| `a_bramblewall` | 1 | 18.75 | magnitude | `thorns:6` → **`thorns:5`** |
| `r_gorehook` | 0 | 11.88 | — | PASS. `mfPhase:'kw'` |
| `r_scentofblood` | 1 | 17.56 | — | PASS |
| `r_cullingorder` | 1 → **2** | 25.70 | **phạm vi + bậc** | *mọi Axie* → **một Axie ít HP nhất**; 3 → **4**; lên EPIC (AC-4) |
| `r_deathspiral` | 2 | 26.60 | magnitude | 12 → **7** |
| `r_apexferal` | 3 | 35.06 | magnitude | ngưỡng xử tử 10% → **15%** (31.73 thiếu 0.03 RP so với sàn) |
| `a_coupdegrace` | 2 | 22.76 | magnitude | `v:22` → **`v:14`** |
| `r_pandemic` | 2 | 23.80 | — | PASS |
| `r_tinderbox` | 0 (**giữ nguyên**) | 13.79 | ❌ **CHỈ THỊ BỊ HUỶ** | §6.7.6 yêu cầu lên RARE `+3`; **huỷ** vì `r_wildfire` bị AC-9 đẩy **lên** RARE (không phải xuống COMMON), nên INFERNO cần `r_tinderbox` ở COMMON. Xem §11. |
| `r_hearthcore` | 2 | 28.00 | magnitude | tick thứ hai chỉ **70%** (`burnTickRatio:0.7`) |
| `a_pyre` | 1 → **2** | 26.10 | giá + bậc | `cost:4` → **`cost:7`** |
| `r_lastwall` | 1 → **0** | 12.75 | bậc | 12.75 nằm trong `Band[0]`; hiệu ứng giữ nguyên |
| `a_aegisfont` | 2 | 22.48 | giá + magnitude | `cost:6` → **8**, `v:18` → **8** |
| `r_tidalbrand` | 1 → **0** | 11.90 | bậc + rider | thêm *"+1 Reroll đầu mỗi trận"*; entry-point COMMON của CONDUIT |
| `r_manaspring` | 2 | 22.50 | phạm vi | bỏ scale theo số Axie ⇒ **`+2` Mana phẳng/lượt** |
| `r_conduitcrown` | 3 | 33.50 | magnitude | thêm *"+2 Mana đầu mỗi lượt"* (11.00 = 35% của LEGENDARY) |
| `r_keeneye` | 0 → **2** | 27.40 | bậc + magnitude | đòn crit pity gây thêm **4** damage (AC-4: APEX thiếu EPIC thứ 2) |
| `r_predatorpoise` | 1 → **0** | 12.60 | bậc | entry-point COMMON của APEX; hiệu ứng giữ nguyên |
| `r_bloodhymn` | 1 | 20.05 | — | PASS |
| `r_shatterpoint` | 2 | 29.38 | magnitude | đòn crit gây thêm **5** damage (7.10 = 27% của EPIC) |
| `a_perfectstrike` | 1 | 19.00 | giá + magnitude | `cost:4` → **5**, `v:11` → **8** |
| `r_gustwing` | 0 → **1** | 19.88 | bậc | 19.88 nằm trong `Band[1]`; giữ `cleaveRatio 0.75` |
| `r_windlash` | 1 → **2** | 28.50 | bậc + rider | thêm *mouth dmg faces +1* (21.55 vượt trần RARE 0.07) |
| `r_squallmark` | 2 → **1** | 17.91 | **phạm vi + bậc** | chỉ mặt `eyes` type `heal`/`debuff` (bỏ `buff`) |

**Tổng: 37 thay đổi bắt buộc, 37 đã áp, 1 sau đó BỊ HUỶ bởi khung** (`r_tinderbox` — xem dòng trên)
⇒ **36 thay đổi có hiệu lực.** 11 entry PASS giữ nguyên hiệu ứng (1 trong số đó, `r_talonedge`,
đổi bậc vì AC-4; `r_tinderbox` nay quay về nhóm PASS nguyên trạng).

🔒 **INV-9 (`relic-system.md`, mới):** RP của một relic chỉ được dựa trên cơ chế **LIVE** trong
`src/engine.js`, hoặc **PENDING** kèm tham chiếu `eng: '<ENG-id>'`. Mọi entry trong tài liệu này
thoả điều đó: relic dùng field chưa có đều mang nhãn 🔧 **ENG-n** ngay trên tiêu đề, và hai entry
PLAGUE mới (`r_rotbite`, `r_rotmouth`) chỉ dùng `modDmg`/`modFace` — **LIVE**, không cần `eng`.

🔒 **Biên dải nay LÀM TRÒN VÀO TRONG và có tính quy phạm:** `L_r = ceil(C_r × 0.85 × 100)/100`,
`U_r = floor(C_r × 1.15 × 100)/100` ⇒ COMMON [11.22, 15.18] · RARE [**15.89**, 21.48] ·
EPIC [22.44, 30.36] · LEGENDARY [31.77, **42.97**]. Hai entry nằm sát biên cần đọc theo bảng này:
`r_worldpiercer` (42.86 — cách trần **0.11**, không phải 0.12) và `r_windlash` (bản trước 21.55,
vượt trần RARE **0.07**). Cả hai kết luận **không đổi** dưới dải chặt hơn.

### 0.3 Hai entry MỚI bắt buộc — PLAGUE

`relic-system.md` §6.7.7 bác đề nghị D4 của tài liệu này (lấp slot poison bằng **retag**): sau §6 của
họ, **không relic nào trong 44 vừa hợp bậc vừa có cơ chế đọc được là poison** để chuyển sang, và
Superlinear Axis Law (§4.6.5) chặn mọi scaler poison ở dưới EPIC. Vì vậy PLAGUE nhận đúng 2 entry
mới, cả hai là `rule` **phạm vi hẹp** và **không tạo thêm một stack poison nào ở bậc thấp**:

| id | Tên | rar | RP | Field | `mload`/`ex` |
|---|---|---|---|---|---|
| `r_rotbite` | Rot Bite | **0 C** | 13.79 | `modDmg` | 0 / `poisonAmpFlat` |
| `r_rotmouth` | Rotmouth | **1 R** | 19.50 | `modFace` (`mfPhase:'kw'`) | 0 / — |

⇒ **Roster hợp nhất: 44 + 48 + 2 = 94 relic** (78 passive + 16 active). Mọi chỗ trong tài liệu này
từng ghi "92" đã đổi thành **94**; §4 đã được viết lại.

### 0.4 Việc đã bàn giao ngược lại cho `relic-system.md`

| # | Việc | Trạng thái |
|---|---|---|
| 1 | `r_infinitedie` xuống RARE (bỏ `safeReroll`) để CONDUIT đủ R≥2 | **Không thuộc tài liệu này** — `r_infinitedie` là 1 trong 44. §6.7.8 khuyến nghị phương án (a); chờ product owner. |
| 2 | 4 field mới cần vào bảng `mload` §3.6 của họ | Đã đề nghị lại ở §17.5 D3 (bản cập nhật) |
| 3 | 6 `ex` token mới | Liệt kê ở §17.2 (bản cập nhật) |

---

## 1. Mục tiêu coverage đang thiết kế theo

### 1.1 Mục tiêu hình dạng (shape target)

Mỗi archetype phải có tối thiểu, tính cả relic cũ + mới:

| Tier | Số passive tối thiểu / archetype | Lý do |
|---|---|---|
| COMMON | ≥1 | **On-ramp.** `mkReward` band cho reward tier 0 là `[0, 1+(pwr>6?1:0)]` (`engine.js:691`) — nghĩa là trước power-level 7, người chơi CHỈ thấy được COMMON/RARE. Không có COMMON thì archetype đó **không thể khởi động trước wave ~7**. |
| RARE | ≥2 | Tầng "đổi luật nhẹ" — nơi build thật sự hình thành, và tầng cao nhất còn với tới được ở early game. |
| EPIC | ≥2 | Payoff giữa game. Gate bởi unlock `u_relic1` (`relicPool` đọc `s.unlockRelicMax`). |
| LEGENDARY | ≥1 (≥2 cho 5 archetype ưu tiên) | Trần build. Gate bởi `u_relic2`. |
| ACTIVE | ≥1 | Hôm nay 6/8 active mang tag `mana`/`crit` bất kể chúng làm gì → 6 archetype có **0** active. |

### 1.2 Dữ liệu thực đo — cái này lái mọi quyết định bên dưới

`node tools/sim.js` 300 run · SHORT (12 wave) · Ascension 0 · winrate tổng **20.0%**.

| archetype | run/300 | winrate | relic | Chẩn đoán của tôi | Việc tôi làm |
|---|---|---|---|---|---|
| PLAGUE (poison) | 90 (30%) | 16% | 5 | Phễu rộng nhất, dưới trung bình → **hút người chơi rồi làm họ thua** | **+1 relic duy nhất**, và là relic *lateral* (phân phối lại poison đã trả, không thêm stack) |
| BULWARK (shield) | 59 (20%) | 31% | 6 | Khoẻ, đủ relic | +1 passive (lấp RARE) + 1 active |
| CONDUIT (mana) | 35 (12%) | 29% | 7 | Khoẻ, nhưng **0 LEGENDARY** | +3, trong đó LEGENDARY đầu tiên |
| APEX (crit) | 30 (10%) | 10% | 4 | **YẾU THẬT.** Xem §3.4 | +4, thiết kế để **sửa lỗi**, không phải nới pool |
| INFERNO (burn) | 29 (10%) | 10% | 4 | **YẾU THẬT.** Xem §3.5 | +2, trong đó 1 EPIC là *engine* mà archetype đang thiếu |
| TEMPEST (aoe) | 22 (7%) | 18% | 4 | Trung bình | +3 |
| TALON (pierce) | 14 (5%) | 14% | **2** | Thiếu relic + hơi yếu | +5 passive + 1 active |
| SWARM (summon) | 12 (4%) | **33%** | **2** | **KHOẺ NHẤT GAME, chỉ là không với tới được** | +5 nhưng **chỉ mở đường, không tăng trần** — xem §1.3 |
| EVOLVE (growth) | 5 (1.7%) | 20% | **2** | Gần như không tồn tại trong play | +5 passive + 1 active, ưu tiên COMMON/RARE |
| AEGIS (thorns) | 4 (1.3%) | 25% | **2** | Trên trung bình, **không với tới được** | +6 nhưng **chỉ mở đường** — xem §1.3 |

Nhịp độ: wave 12 (boss cuối) chỉ thắng 37% (101 chết), wave 10 elite 73%. ⇒ **mọi relic đóng vai
"engine starter" phải online trước wave 10**, tức phải nằm ở COMMON/RARE (§1.1).

### 1.3 Luật tự áp: access ≠ power

`playrate` và `winrate` **không đi cùng nhau**. SWARM 33% winrate trên 12 run và AEGIS 25% trên 4 run
không phải archetype yếu — chúng **không với tới được**, vì 2 relic là quá ít để rút vào được.

⇒ **Với SWARM và AEGIS, tôi thiết kế để tăng số lối vào, KHÔNG tăng trần.** Cụ thể, các quyết định
đã bị tôi tự hạ xuống sau khi đọc số:

| Relic | Bản nháp đầu (đã bỏ) | Bản ship | Lý do |
|---|---|---|---|
| `r_hivequeen` | Egg copy die của Axie dẫn đầu ở 50% giá trị | Egg chỉ thừa hưởng **class** (và passive class đó) + 40% Max HP của Axie dẫn đầu, **giữ die egg gốc** | Bản nháp là một cú tăng trần rất lớn trên archetype đã có winrate cao nhất game |
| `r_apexbrood` | Egg +6 Max HP, +3 dmg | Egg +4 Max HP, +2 dmg | `hiveMind` đã scale theo **số** egg còn sống → giữ egg sống = đã là buff; nên buff egg phải nhỏ |
| `r_retributor` | Thorns lan sang lân cận ở 1/2 | ở **1/3** | Đây là relic duy nhất trong nhóm thorns thật sự nâng trần |
| `r_ironmaiden` | 2× thorns cao nhất, cap 20 | **1×**, cap **12** | Vẫn là win condition (AEGIS hiện không giết được gì) nhưng vừa phải |
| LEGENDARY thorns #2 | `r_thornedcrown` (đòn của bạn mang theo thorns — nâng trần lần 2) | `r_scalecrown` (cả đội nhận passive SCALES — **mở đường**) | Không đặt 2 LEGENDARY nâng trần lên một archetype 25% winrate |
| POISON | 2 relic mới (`r_rotcarrier` cộng thêm stack) | **1 relic**, lateral | 30% playrate / 16% winrate: phễu đã quá rộng, không được cộng sức mạnh vào đó |

## 2. Giả định về framework (cần hoà giải với `relic-system.md`)

`relic-system.md` chưa tồn tại khi tôi viết file này. Mọi giả định dưới đây là **điểm hoà giải khi merge**.

| # | Giả định | Nếu sai thì sao |
|---|---|---|
| **A1** | `ARCH` được thêm khoá `exec` (thành 11 archetype). `PASSIVE.beast.a === 'exec'` nên hiện Beast **không có archetype nào được track**, và 2 relic `a:'exec'` hiện có bị `archScore` bỏ qua lặng lẽ (`engine.js:883` — `sc[r.a]!=null` là false). | 5 relic `a:'exec'` của tôi **vẫn chạy đúng số**; chỉ có tracker UI và `archScore` không đếm. Không relic nào *hỏng*. |
| **A2** | `faceArch()` học được `thorns` (và `exec`). Hiện `faceArch` (`engine.js:755-766`) **không bao giờ** trả về `thorns` → AEGIS là archetype được track mà không mặt nào feed được, làm Reptile (`SCALES`=thorns) bị mắc cạn. | Không relic thorns nào của tôi phụ thuộc vào việc này để *hoạt động*. Chỉ ảnh hưởng tracker + `mkReward`'s `arch` label trên reward face. |
| **A3** | **Power budget theo rarity** (mô hình làm việc của tôi, hiệu chuẩn từ relic hiện có — xem §2.1). | Nếu `systems-designer` chốt mô hình khác, mọi con số của tôi phải scale lại theo cùng một tỉ lệ; hình dạng thiết kế không đổi. |
| **A4** | **Không có cap số relic người chơi giữ** (đã xác nhận: `s.relics` là array không giới hạn). | Vì vậy tôi ship **0 global multiplier mới**. Xem §17. |
| **A5** ✅ **ĐÃ ĐƯỢC PHÁN — ĐƯỢC PHÉP** (product owner, 2026-09-03; xem `relic-system.md` §14 QĐ-1). 9 relic bên dưới giữ trạng thái "chạy hôm nay". | Relic hook **được phép** gọi hàm engine (`dealDamage`, `addStatus`, `applyShield`, `applyHeal`, `aliveE`, `mkAlly`, `rollUnit`, `ft`, `EV`). Đã xác minh: cả 3 đường load đều **concatenate** `data.js`+`engine.js` vào một scope. Xem §3.1. | Nếu `systems-designer` cấm điều này như một luật kiến trúc, **9 relic** của tôi chuyển từ "chạy hôm nay" sang "cần engine work": `r_heartwood`, `r_broodmother`, `r_eggshell`, `r_apexbrood`, `r_hivequeen`, `r_cullingorder`, `r_deathspiral`, `r_ironmaiden`, `r_manaspring`. |
| **A6** | `relicPool` rút **uniform trong band rarity**, không weight. Thêm N relic vào một tier ⇒ **loãng** tỉ lệ rút của từng relic trong tier đó. | Đây là *tính năng*, không phải lỗi: nó giảm "mọi run đều ra cùng một build". Nhưng nó cũng làm relic ký-sinh-combo khó gặp hơn — nên tôi giữ mọi COMMON đứng-một-mình-vẫn-dùng-được. |
| **A7** | Không có luật de-dup theo archetype trong `relicPool` (chỉ loại relic đã giữ: `!s.relics.includes(r.id)`). | Chống-stack của tôi là **do cấu trúc** (dùng field đọc bằng `rmax`, trigger loại trừ nhau, cộng-sau-khi-nhân), không dựa vào luật pool. Xem §17. |
| **A8** | Giá shop `[45,75,120,180][rar]` (`engine.js:858`) tự áp cho relic mới. | Tôi ship **0 relic `rar:4`** — `[45,75,120,180][4]` là `undefined` → fallback `60`, tức một relic Mythic sẽ rẻ hơn một relic Epic. Đó là bug sẵn có; tôi không kích hoạt nó. |

### 2.1 Mô hình power budget đang dùng (hiệu chuẩn từ relic hiện có)

Neo: tại `pw≈6`, `CURVE.budget(6) ≈ 10.5×1.15⁶ ≈ 24`; party dùng 5 mặt/lượt, giá trị mặt TB ≈ 6
⇒ **output tham chiếu ≈ 30/lượt**.

| Tier | Ngân sách | Đối chiếu relic thật |
|---|---|---|
| COMMON | **+10% một trục ≈ +3 điểm/lượt** | `r_claw` (+1 mọi mặt dmg): ~3 mặt dmg dùng/lượt ⇒ **+3/lượt = +10%** ✅ đúng neo |
| RARE | ≈2× COMMON (+20%), *hoặc* đổi luật có điều kiện | `r_carapace` (+3 shield) ⇒ ~+4.5/lượt ≈ **+15%** (hơi trên COMMON — đúng như brief đã nêu) |
| EPIC | ≈3× COMMON (+30%) kèm đổi luật | `r_venomengine` (`poisonTicks:2`) = ×2 sát thương poison |
| LEGENDARY | ≈5× COMMON (+50%) và/hoặc **đảo luật**, có thể kèm giá | `r_bloodpact` (−25% maxHP, ×1.6 dmg) |

**Cảnh báo poison bậc hai đã áp giá:** `r_fang` (COMMON, +2 stack poison) — poison giảm 1 stack/lượt
nên tổng ≈ `v(v+1)/2`; cộng 2 vào stack `v` làm tổng tăng `2v+3`. Ở `v=4` là **+11 điểm mỗi lần dùng
mặt poison**, ~0.8 lần/lượt ⇒ **+9/lượt ≈ +30%**, tức **gấp 3 lần `r_claw` ở cùng tier COMMON**.
Đây chính là lỗi brief đã chỉ ra. Relic poison duy nhất tôi thêm (`r_pandemic`) **không thêm stack nào**.

## 3. Năm phát hiện nền tảng từ code (đọc trước khi đánh giá bất kỳ entry nào)

### 3.1 Relic hook CÓ THỂ gọi hàm engine — và chưa relic nào làm

Cả 3 đường load đều nối `data.js` rồi `engine.js` vào **một scope duy nhất**:
`build.py:4-5` (`%DATA%` trước `%ENGINE%`), `tools/sim.js:10-12` (`vm.runInContext` trên chuỗi đã nối),
`api/_engine.js:26-29` (y hệt). Thân hàm hook chỉ *chạy* trong lúc chơi, sau khi cả hai file đã load
⇒ tham chiếu tới `dealDamage`/`addStatus`/`aliveE`/`mkAlly`/`ft`/`EV` là **hợp lệ**.

Toàn bộ 44 relic hiện có chỉ mutate state phẳng hoặc dùng `ctx` helper (`ctx.splash`, `ctx.explode`,
`ctx.addStatus`). **Không relic nào từng gọi một hàm engine.** Đây là khoảng thiết kế lớn nhất còn
trống, và nó **tốn 0 engine work** — lý do 30/48 relic của tôi chạy được ngay.

> ⚠️ Rủi ro cần `lead-programmer` xác nhận: điều này tạo phụ thuộc ngược `data.js` → `engine.js`.
> Hợp lệ với 3 loader hiện tại, nhưng sẽ **vỡ** nếu ai đó `require('src/data.js')` độc lập.
> Nếu bị cấm ⇒ xem A5.

### 3.2 `onRollEnd` là hook thật, chưa ai dùng · 3 hook khác là hook chết

- `onRollEnd(s, null)` **được gọi** tại `engine.js:277`, cuối `rollAll()` — sau khi roll và sau
  `resolveCantrips`. **Không** được gọi bởi `doReroll` ⇒ đúng **1 lần/lượt**. Không relic nào dùng.
  Đây là điểm duy nhất đọc được **mặt mà mỗi Axie vừa roll ra**. Tôi dùng nó cho `r_quickenroot`,
  `r_omenmark`, `r_keeneye`.
- `onPoison`, `onDmgTaken`, `onTurnEnd` được **tài liệu hoá tại `data.js:355` nhưng KHÔNG BAO GIỜ
  được gọi** (grep toàn `src/`: chỉ khớp trong chính comment đó). Relic dùng chúng sẽ im lặng không
  làm gì. **Tôi không dùng cái nào.**

### 3.3 `undying` đã implement đầy đủ nhưng không gì trong game cấp nó

`addStatus` có nhánh `undying` (`engine.js:399`) và `dealDamage` tiêu thụ nó (`:330`, kèm float text
`'UNDYING'`). Grep: **không** face, monster, boss, event hay relic nào cấp `undying`. Một cơ chế
hoàn chỉnh, có cả feedback hình ảnh, với **0 content**. `r_lastwall` (§12) kích hoạt nó.

### 3.4 Chẩn đoán APEX (crit, 10% winrate — một nửa baseline)

Bốn nguyên nhân độc lập, đọc trực tiếp từ code:

1. **Crit không có sàn.** `u.critNow = ... && rnd()*100 < cc` (`:254`) — thuần phương sai. Không
   relic nào cho một crit *đảm bảo*. Trong một game mà pillar là "minh bạch triệt để", archetype duy
   nhất mà payoff không thể lên kế hoạch được chính là archetype yếu nhất. Không phải trùng hợp.
2. **Crit đánh nhau với reroll economy.** `rollUnit` **tính lại** `u.critNow` mỗi lần roll (`:254`).
   Reroll để tìm mặt tốt ⇒ **xoá mất crit đã roll được**. Reroll là bề mặt kỹ năng chính của game
   (combo-decision-memo §1: "Reroll" là 1 trong 2 quyết định thật) — APEX bị phạt vì chơi giỏi.
3. **Crit không kết nối với gì cả.** Nó là một multiplier trần trụi. Poison/burn có status engine;
   crit chỉ có một con số. Lấy `r_apexpredator` là hết build.
4. **Hai trong bốn "relic crit" không phải relic crit.** `r_echostone` (`firstEcho`) mang tag `crit`
   nhưng không liên quan gì tới crit. Và `a_ult` — active LEGENDARY của archetype — **không thể crit**:
   `playerUseRelic` (`:566-575`) không bao giờ set `o.crit`, nên `if(o.crit) v*=rmax(s,'critMult',2)`
   (`:321`) không bao giờ chạy. APEX thực chất có **2** relic hoạt động.

⇒ Tôi thêm 4 relic, mỗi cái nhắm đúng một nguyên nhân: `r_keeneye` (sàn/pity), `r_predatorpoise`
(gỡ xung đột reroll), `r_omenmark` (crit đảm bảo), `r_shatterpoint` (payoff thứ cấp). `a_perfectstrike`
sửa nguyên nhân #4.

### 3.5 Chẩn đoán INFERNO (burn, 10% winrate)

**Luật decay của burn tự huỷ khả năng tích luỹ của chính nó.**

- `tickStatus:658`: `u.st.burn = rhas(s,'burnSlow') ? u.st.burn-1 : Math.floor(u.st.burn/2)`.
  Mặc định **giảm một nửa mỗi lượt** ⇒ stack `B` gây tổng ≈ `B + B/2 + B/4 ≈ 2B`.
  Poison cùng stack gây `B(B+1)/2`. Ở `B=6`: **burn 12, poison 21**.
- `Math.floor` làm burn 1 → 0, nên mọi lần cấp burn nhỏ đều bốc hơi.
- **Tệ nhất:** cấp `burn:2` mỗi đòn đạt **điểm cân bằng ở stack 4** (4 → halve 2 → +2 = 4). Nghĩa là
  `r_ember` ("mọi đòn cấp Burn 2", RARE) **plateau ở ~4 sát thương/lượt/mục tiêu, mãi mãi**. Việc
  cộng thêm stack bị chính luật halving ăn.
- `burnMult` là `rmax` và **chỉ `r_solarcore` (LEGENDARY) có nó**. ⇒ **Không có gì giữa RARE và
  LEGENDARY.** Toàn bộ tính khả thi của INFERNO treo vào việc rút được đúng **một RARE**: `r_wildfire`
  (`burnSlow`), thứ duy nhất làm burn trở thành bậc hai.

⇒ Sửa **không phải** là thêm relic cấp stack (halving sẽ ăn hết). Sửa là một EPIC **nhân output**
thay vì cộng stack: `r_hearthcore` (`burnTicks:2`, đối xứng với `poisonTicks` của poison, đọc bằng
`rmax` nên không tự stack, và **không** cộng dồn nguy hiểm với `r_wildfire` như relic cấp stack).

## 4. Bảng coverage: hiện có + mới = mục tiêu

Đếm relic hiện có: **44** = 36 passive + 8 active. Kiểm chứng theo tag `a:` và `rar:` trong `RELICS`.

### 4.1 Phân bố của **50 relic mới** sau audit

> **Bảng này đã được viết lại hoàn toàn.** Bản trước cộng "cũ + mới" và cả hai cột đều **hết hạn**:
> cột "cũ" không tính bản retune 44 relic (`relic-system.md` §6, có đổi bậc và retag), cột "mới"
> dùng bậc **trước** audit. Bảng dưới **chỉ** kê 50 entry do tài liệu này sở hữu, ở bậc **sau** audit.
> Phủ archetype hợp nhất trên toàn bộ 94 relic là **`relic-system.md` §6.7.8** — xem §4.1b.

| archetype | C | R | E | L | passive | active | **tổng mới** |
|---|---|---|---|---|---|---|---|
| pierce TALON | 0 | 3 | 1 | 2 | 5 | 1 | **6** |
| growth EVOLVE | 1 | 2 | 2 | 1 | 5 | 1 | **6** |
| summon SWARM | 1 | 3 | 1 | 1 | 5 | 1 | **6** |
| thorns AEGIS | 1 | 2 | 2 | 2 | 6 | 1 | **7** |
| exec FERAL | 1 | 1 | 3 | 1 | 5 | 1 | **6** |
| poison PLAGUE | 1 | 1 | 1 | 0 | 3 | 0 | **3** 🆕 |
| burn INFERNO | **1** | 0 | 2 | 0 | 2 | 1 | **3** |
| shield BULWARK | 1 | 0 | 1 | 0 | 1 | 1 | **2** |
| mana CONDUIT | 1 | 0 | 1 | 1 | 3 | 0 | **3** |
| crit APEX | 1 | 2 | 2 | 0 | 4 | 1 | **5** |
| aoe TEMPEST | 0 | 2 | 1 | 0 | 3 | 0 | **3** |
| **TỔNG** | **9** | **16** | **17** | **8** | **42** | **8** | **50** |

**Đọc bảng này ĐÚNG cách:** ô trống **không** phải lỗi phủ. AC-4 (C≥1, R≥2, E≥2, L≥1 mỗi archetype)
đo trên **toàn bộ 94 relic**, không đo riêng roster mới. Hai archetype nay không có COMMON trong
roster mới — **pierce** (`r_talonedge` lên RARE) và **aoe** (`r_gustwing` lên RARE) — và cả hai lấy
slot COMMON từ bản retune 44 relic. INFERNO **giữ** COMMON của mình (`r_tinderbox`), vì `r_wildfire`
bị AC-9 đẩy lên RARE thay vì xuống COMMON.

🔒 **Hệ quả vận hành: hai tài liệu PHẢI ship cùng nhau.** Nếu chỉ ship roster mới, TALON/INFERNO/
TEMPEST mất on-ramp COMMON và theo §1.1 sẽ **không khởi động được trước wave ~7**. Nếu chỉ ship
retune, PLAGUE thiếu COMMON/RARE. Đây là ràng buộc mới do audit tạo ra và nó không tồn tại ở bản trước.

### 4.1b Phủ archetype hợp nhất — 94 relic (nguồn: `relic-system.md` §6.7.8)

| archetype | C | R | E | L | passive | active | **tổng** |
|---|---|---|---|---|---|---|---|
| pierce TALON | 1 | 2 | 2 | 2 | 7 | 2 | **9** |
| growth EVOLVE | 1 | 2 | 2 | 2 | 7 | 1 | **8** |
| summon SWARM | 1 | 3 | 2 | 1 | 7 | 1 | **8** |
| thorns AEGIS | 1 | 2 | 2 | 3 | 8 | 1 | **9** |
| exec FERAL | 3 | 2 | 2 | 2 | 9 | 1 | **10** |
| poison PLAGUE | 1 | 2 | 2 | 2 | 7 | 1 | **8** |
| burn INFERNO | 1 | 2 | 2 | 1 | 6 | 1 | **7** |
| shield BULWARK | 2 | 2 | 2 | 1 | 7 | 3 | **10** |
| mana CONDUIT | 1 | 1 ⚠️ | 3 | 2 | 7 | 3 | **10** |
| crit APEX | 1 | 2 | 2 | 2 | 7 | 1 | **8** |
| aoe TEMPEST | 1 | 2 | 2 | 1 | 6 | 1 | **7** |
| **TỔNG** | **14** | **22** | **23** | **19** | **78** | **16** | **94** |

`max/min = 10/7 = 1.43 ≤ 1.6` ✅ · mọi archetype ≤ 10 ✅ · mọi ô C≥1, R≥2, E≥2, L≥1 ✅ **trừ một**:

⚠️ **CONDUIT chỉ có 1 RARE passive** (`r_ear`) vì `r_voidgene`/`r_infinitedie`/`r_manaspring` đều
rơi vào EPIC theo RP. **Việc này KHÔNG thuộc tài liệu này** — cả ba relic đó nằm trong 44 relic
sẵn có. `relic-system.md` §6.7.8 nêu hai lối và khuyến nghị **(a)**: hạ `r_infinitedie` xuống RARE
bằng cách bỏ mệnh đề `safeReroll` (0 content mới). Chờ product owner. Ghi ở §0.4.

### 4.1c Phân bố theo bậc sau audit (50 relic mới)

| bậc | số relic | relic đã ĐỔI BẬC vào/ra |
|---|---|---|
| COMMON | **9** | **vào:** `r_lastwall` (←R) · `r_tidalbrand` (←R) · `r_predatorpoise` (←R) · `r_rotbite` 🆕 · **ra:** `r_talonedge` (→R) · `r_keeneye` (→E) |
| RARE | **16** | **vào:** `r_talonedge` (←C) · `r_gustwing` (←C) · `r_squallmark` (←E) · `r_rotmouth` 🆕 · **ra:** 3 xuống C, `r_glassspine`/`r_cullingorder`/`r_windlash`/`a_pyre` lên E |
| EPIC | **17** | **vào:** `r_glassspine` · `r_cullingorder` · `r_windlash` · `a_pyre` · `r_keeneye` · **ra:** `r_squallmark` (→R) |
| LEGENDARY | **8** | **không relic nào đổi bậc vào hoặc ra.** Cả 8 giữ nguyên bậc; 5/8 phải đổi số hoặc cơ chế. |
| **TỔNG** | **50** | 13 relic đổi bậc · 2 entry mới |

**Ba quan sát về hình dạng, và cả ba đều là hệ quả của mô hình chứ không phải sở thích:**

1. **EPIC phình to nhất (+5 ròng).** `Band[2]` = [22.44, 30.36] là dải **rộng nhất theo giá trị
   tuyệt đối** trong ba bậc dưới, nên relic "đổi luật có điều kiện" — kiểu thiết kế tự nhiên nhất
   khi viết roster — hầu hết đáp xuống đó.
2. **Dòng chảy ra khỏi RARE là lớn nhất (−4 ròng).** RARE là bậc bị dùng làm "mặc định" khi người
   viết không chắc, và nó có dải **hẹp nhất theo tỉ lệ** ⇒ tỉ lệ trượt cao nhất.
3. **Không LEGENDARY nào đổi bậc, nhưng 5/8 phải sửa nội dung.** Trực giác về "cái gì nghe như
   LEGENDARY" **đúng**; trực giác về *bao nhiêu* thì sai — theo cả hai chiều (`r_ironmaiden` 66.50
   quá mạnh, `r_dawnlance` 6.80 và `r_hivequeen` 12.10 quá yếu).

### 4.2 Active

| archetype | cũ | mới | tổng | id mới |
|---|---|---|---|---|
| mana | 4 | 0 | 4 | — |
| shield | 1 | **1** | 2 | `a_aegisfont` |
| aoe | 1 | 0 | 1 | — |
| poison | 1 | 0 | 1 | — |
| crit | 1 | **1** | 2 | `a_perfectstrike` |
| burn | **0** | **1** | 1 | `a_pyre` |
| pierce | **0** | **1** | 1 | `a_pinning` |
| growth | **0** | **1** | 1 | `a_bloom` |
| summon | **0** | **1** | 1 | `a_clutch` |
| thorns | **0** | **1** | 1 | `a_bramblewall` |
| exec | **0** | **1** | 1 | `a_coupdegrace` |
| **TỔNG** | **8** | **8** | **16** | Mọi archetype ≥1 active ✅ |

**Bậc của 8 active mới ĐÃ ĐỔI sau audit** (bảng `id mới` ở trên vẫn đúng — chỉ bậc và giá đổi):

| active | rar trước → sau | cost trước → sau | v trước → sau |
|---|---|---|---|
| `a_pinning` | 1 | 3 | — (thêm sàn **min 6**) |
| `a_bloom` | 2 | 5 | 3 — ✅ PASS nguyên trạng |
| `a_clutch` | 1 | 4 | **2 → 1** |
| `a_bramblewall` | 1 | 3 | `thorns:6` → **`thorns:5`** |
| `a_coupdegrace` | 2 | 5 | **22 → 14** |
| `a_pyre` | **1 → 2** | **4 → 7** | — |
| `a_aegisfont` | 2 | **6 → 8** | **18 → 8** |
| `a_perfectstrike` | 1 | **4 → 5** | **11 → 8** |

🔒 **7/8 active phải đổi số, và tất cả vì CÙNG MỘT lỗi mô hình.** §4.3 #1 nói đúng rằng active dùng
lại **mỗi lượt** (`s.usedActives=[]` chạy ngay sau `s.turn++`, `engine.js:633`), nhưng vài phép định
giá trong bản trước vẫn lặng lẽ giả định "một lần mỗi trận" — rõ nhất ở `a_pyre` (so với `a_plague`
theo damage **mỗi lần dùng**) và `a_aegisfont` (so hiệu suất **mỗi MP**). Mô hình `RP_act` của
`relic-system.md` định giá theo `N*` = số lần dùng khả thi mỗi trận, và đó là lý do 5 active bị đo
là **34–52 RP** trong khi mang nhãn RARE/EPIC. Bài học ghi lại: **với active, mana là trần duy nhất,
nên `cost` là tuning knob mạnh hơn `v`.**

**Tổng roster sau expansion: 44 + 48 + 2 = 94 relic** (78 passive + 16 active).
Mọi chỗ ghi "92" hoặc "84" trong các tài liệu liên quan (`game-concept.md`, `bloodline-system.md`)
phải thành **94** — `relic-system.md` §11 mục 13-14.

### 4.3 Nhắc lại 3 sự thật về ACTIVE (đã xác minh lại từ source)

1. **Active dùng lại MỖI LƯỢT, không phải 1 lần/trận.** `s.usedActives=[]` tại `engine.js:633`.
   Cổng duy nhất là `if(s.usedActives.includes(id)||s.mana<it.act.cost) return false` (`:564`).
   ⇒ Giới hạn thật là **thu nhập mana**. Mọi giá bên dưới đã tính theo "lặp mỗi lượt".
2. **`kind` chỉ có đúng 8 giá trị, không có nhánh default** (`:566-575`): `heal` `dmg` `ult`
   `shieldall` `dmgall` `poisonall` `stun` `reroll`. `kind` lạ ⇒ **trừ mana, đốt slot, không làm gì**.
3. **`kind:'ult'` hardcode giá trị shield**: `aliveP(s).forEach(t=>applyShield(s,t,10))` — số `10` là
   literal, không phải `a.v`. Không thể có `ult` thứ hai với shield khác mà không sửa engine.

**Bổ chính (tôi đọc khác thông tin nhận được):** `dmg`/`dmgall`/`ult` **KHÔNG THỂ crit**. Chúng
truyền `{pierce, attack:true}` — `o.crit` không bao giờ được set, nên `if(o.crit) v*=rmax(s,'critMult',2)`
(`:321`) không bao giờ chạy. Chúng *có* nhận `dmgMult`, `modDmg`, FERAL (nếu `aliveP(s)[0]` là Beast),
`piercePlus`, và *có* trigger `onHit` + Thorns địch. Đây là gốc của §3.4 #4.

## 5. PIERCE — TALON (5 passive + 1 active)

> Đo được: 14 run/300 (5%), winrate 14%, **2 relic**. Thiếu relic *và* hơi yếu ⇒ đây là archetype duy
> nhất trong 4 nhóm đói mà tôi vừa mở đường vừa được phép nâng nhẹ trần.
> Engine class: **Bird TALON** — `Pierce +3 dmg`, và mặt `aoe` cũng nhận Pierce.
> **Sau audit (§0.2):** phân bố bậc của nhóm này là R2 · E1 · L2 + 1 active RARE. TALON **không còn
> COMMON nào trong roster mới** — slot COMMON của archetype do bản retune 44 relic cấp
> (`relic-system.md` §6.7.8). Đây là hệ quả trực tiếp của việc `r_talonedge` phải lên RARE.

### `r_talonedge` — Talon Edge · **RARE** · `a:'pierce'` · `mfPhase:'add'` · `mload 0` · `ex: []`

- **d:** `'Faces that already Pierce deal 2 more. Horn attacks deal 1 more.'`
- **Hiệu ứng chính xác:** hai mệnh đề cộng phẳng, áp trên cùng một lượt `modFace`:
  1. `+2` value cho mọi mặt `t==='dmg'` đã có keyword `pierce`;
  2. `+1` value cho mọi mặt `t==='dmg'` có `p==='horn'`.
- **Field:** `modFace:u=>u.die.forEach(f=>{ if(f.t!=='dmg') return; if(hasKw(f,'pierce')) f.v+=2; if(f.p==='horn') f.v+=1; })` — **chạy hôm nay**. `mfPhase:'add'`.
- 🔧 **Đã đổi bậc `0 → 1` theo `relic-system.md` §6.7.1.** RP 15.00 của bản COMMON **hợp dải** `Band[0]` — nó **không** vi phạm INV-1. Nó bị đổi vì **AC-4 (phủ bậc)**: sau retune, TALON chỉ còn **1 RARE**, dưới mức tối thiểu R≥2 của §1.1. Mệnh đề Horn `+1` là phần công suất được thêm để RP đạt đích RARE 20.55.
- **Số:** bird1 có 2/6 mặt pierce; Horn là part `dmg` phổ biến thứ hai sau Mouth ⇒ hai mệnh đề cộng lại ≈ **+5/lượt**.
- **Event:** không phát event lúc chiến đấu — hiển thị **trên mặt die** (ui đọc `faceValue`). Đây là kiểu "visible" hợp lệ cho mọi relic `modFace`.
- **Vì sao tồn tại:** cửa vào RARE thứ hai của TALON, và nó là relic duy nhất trong nhóm thưởng cho **cả** hai nguồn pierce (keyword sẵn có *và* part Horn mà `r_pierceall` chiếm).
- ⚠️ **Hai mệnh đề CHỒNG NHAU và đó là kết quả đã biết, không phải lỗi.** Một mặt Horn `dmg` **đã có** `pierce` ăn **cả hai** ⇒ `+3`. Với `r_pierceall` (Horn → pierce) hoặc `r_worldpiercer` (mọi mặt dmg → pierce) trong tay, **mọi** mặt Horn rơi vào trường hợp đó. Do INV-5 chạy pha **KW trước pha ADD**, việc này **luôn** xảy ra khi giữ một trong hai relic đó — không còn phụ thuộc thứ tự nhặt như bản trước. Đây là điểm cần `tools/t_relic.mjs` đo lại RP trong tổ hợp, và là lý do relic này mang `mfPhase:'add'` chứ không phải `'kw'`.
- ✅ **ENG-0/INV-5 đã gỡ bug thứ tự nhặt.** Bản trước ghi ⚠️ "nhặt `r_pierceall` trước ⇒ khác kết quả". Sau INV-5 (`relic-system.md` §3.12, §11 mục 18) `modFace` sắp theo `[PHASE_RANK, rar, RELIC_INDEX]` ⇒ **kết quả độc lập thứ tự nhặt**. Cảnh báo cũ đã hết hiệu lực.

### `r_marrowdrill` — Marrow Drill · RARE · `a:'pierce'` · `mfPhase:'kw'` · `mload 0` · `ex: []`

- ✅ **PASS INV-1 nguyên trạng** (RP 19.13, `Band[1]` = [15.88, 21.48], đích RARE của TALON 20.55).
  Thay đổi duy nhất theo §6.7.1: khai báo `mfPhase:'kw'`, `mload:0`, `ex:[]`.
- **d:** `'RULE: every Pierce damage face also applies Weaken 2.'`
- **Hiệu ứng chính xác:** thêm keyword `weaken:2` vào mọi mặt `t==='dmg'` có `pierce` và **chưa** có `weaken`.
- **Field:** `modFace` (inject keyword) — **chạy hôm nay**.
- **kwPure Direction Law:** mặt `dmg` ⇒ `kwPure` đi tới **địch** qua `hit()` (`engine.js:494`) ⇒ **an toàn**. `weaken` nằm trong danh sách `addStatus` thật (`:394`) ⇒ **đã implement**, không phải bẫy như `shieldself:N`.
- **Chỉ `t==='dmg'`, có lý do:** nhánh `f.t==='poison'` của `doFace` (`:510-514`) **không bao giờ truyền `kwPure`**. Mặt poison+pierce có thật trong `FACE_POOL` (`FR(3,'tail','poison',9,'aoe','pierce')`) — inject vào đó sẽ **trơ hoàn toàn**. Guard `t==='dmg'` tránh đúng cái bẫy đó.
- **Số:** ~1.7 lần/lượt × `Weaken 2`; `faceValue` (`:409`) làm `v=max(0, v-weaken)` trên mặt `dmg` của địch. Giảm ~2 dmg mỗi mặt địch bị weaken, decay 1/lượt, cộng dồn.
- **Event:** `ft` (`'WEA2'`, class `deb`) từ `addStatus:395`.
- **Vì sao tồn tại:** Bird có HP thấp nhất game (11/16/23) và TALON **không có payoff phòng ngự nào**. Đây là relic pierce duy nhất trả bằng *survivability*. Đúng bài học `combo-decision-memo` §3: **không trả thêm trên cùng trục damage** — trả bằng tài nguyên khác trục.

### `r_thousandcuts` — Thousand Cuts · EPIC · `a:'pierce'` · **hai entry `modFace`** · `mload 1` · `ex: []`

- **d:** `'RULE: every Pierce face strikes twice, each strike for half damage plus 2.'`
- 🔧 **ĐỔI THIẾT KẾ, không phải retune số** (`relic-system.md` §6.7.1). Bản trước **đáng giá ≈0 RP** và vi phạm §7 E1 (điều kiện tần suất 0): "đánh 2 lần nửa damage" là **trung hoà damage** — `2 × ceil(v/2) ≈ v`. Toàn bộ giá trị đến từ **bonus phẳng mỗi đòn**, mà một party chuẩn (không Bird, không `piercePlus`) có **0** bonus phẳng ⇒ relic EPIC đáng giá 0. Bản mới cấp bonus phẳng đó **từ chính relic**.
- **Hiệu ứng chính xác:** với mọi mặt `t==='dmg'` có `pierce`:
  1. **pha KW** — nếu mặt **đã có** `multi:N` ⇒ **thay thế** bằng `multi:N*2`; nếu chưa ⇒ push `multi:2`;
  2. **pha ADD** — `f.v = Math.ceil(f.v/2) + 2`.
- 🔒 **Phải khai HAI entry `modFace` ở hai pha** (`mfPhase:'kw'` và `mfPhase:'add'`), theo `relic-system.md` §11 mục 18: relic này là **trường hợp duy nhất trong roster** vừa đổi keyword vừa đổi `f.v`. Gộp một entry sẽ phá INV-5.
- **Bắt buộc "thay thế", không "append":** `kwVal` (`engine.js:17`) `return` ở **match đầu tiên** ⇒ push thêm `multi:2` lên mặt đã có `multi:3` sẽ bị **bỏ qua hoàn toàn**.
- **Field:** `modFace` ×2 — **chạy hôm nay** (phụ thuộc INV-5 để xác định thứ tự, xem ENG-0).
- **Số:** mỗi đòn `ceil(v/2)+2` ⇒ tổng danh nghĩa `v+4` **cộng thêm** phần nhân đôi mọi bonus phẳng. **Lãi:** `piercePlus` (`rsum`, `:318`) áp **mỗi đòn** ⇒ nhân đôi; Bird `+3` nhân đôi; `onHit` trigger nhân đôi (`r_ember`, `r_solarcore`). **Lỗ:** Thorns địch phản đòn **nhân đôi** (`:339`) — Mecha boss `permThorns ≈ max(2, 0.09×budget)`, `thornback` 4, `warden` 5, `e_bulwark` 6.
- ⚠️ **Tương tác pha ADD với `r_talonedge`:** cả hai ở pha ADD; INV-5 sắp theo `rar` ⇒ `r_talonedge` (rar 1) chạy **trước** `r_thousandcuts` (rar 2) ⇒ `ceil((v+2)/2)+2`, **không** phải `ceil(v/2)+2+2`. Tất định, và đây là kết quả **duy nhất** có thể xảy ra sau INV-5.
- **Event:** **hai** event `hit` thay vì một ⇒ *dễ thấy hơn*, không phải khó thấy hơn.
- **Vì sao tồn tại:** relic đầu tiên trong game có **đánh đổi hai chiều thật** (nhiều đòn = nhiều phản đòn). Nó biến "địch có Thorns hay không" thành một quyết định trước trận, chứ không phải một con số.
- **Edge:** `f.v===1` ⇒ `ceil(0.5)+2 = 3`, hai đòn = 6. Mặt pierce giá trị thấp lãi tương đối lớn nhất — có chủ đích, đó là chỗ bonus phẳng đáng giá nhất. Mặt `heavy`+`pierce`: không ảnh hưởng (`heavy` chỉ chặn reroll).

### `r_worldpiercer` — World Piercer · LEGENDARY · `a:'pierce'` · `mfPhase:'kw'` · `mload 1` · `ex: ['pierceInjectAll']`

- ✅ **PASS INV-1 nguyên trạng** (RP 42.86) — **nhưng cách trần `Band[3]` (42.98) đúng 0.12 RP.**
- 🚨 **CẢNH BÁO TUNING BẮT BUỘC (`relic-system.md` §6.7.1).** Relic này là entry sát trần nhất trong cả 94. **Mọi** thay đổi tương lai chạm `KW(pierce)` hoặc `piercePlus` — kể cả một `+1` ở relic khác — sẽ đẩy `r_worldpiercer` **ra ngoài** dải LEGENDARY mà không ai sửa gì trên chính nó. Bất kỳ ai tune hai trục đó **phải** chạy lại `tools/t_relic.mjs` và đọc mục này trước.
- **d:** `'RULE: every damage face gains Pierce, and your Pierce no longer triggers Thorns.'`
- **Hiệu ứng chính xác:** `modFace` inject `pierce` vào mọi mặt `t==='dmg'` chưa có; **và** `piercePlus:1`.
- **Field:** `modFace` + `piercePlus:1` — **chạy hôm nay**. `piercePlus` bất kỳ giá trị truthy nào đều bật `skipThorns = pierce && rhas(s,'piercePlus')` (`:338`) ⇒ `1` là giá trị nhỏ nhất bật được miễn nhiễm Thorns mà không bơm thêm damage.
- **Số:** vô hiệu hoá **toàn bộ** Shield địch; miễn nhiễm Thorns địch (~20-30 damage/lượt tránh được ở late pw với 4 đòn/lượt); `+1`/đòn.
- **Event:** `hit` **không kèm** `ft` màu shield ⇒ người chơi thấy shield địch *không* trừ. Đây là feedback bằng sự vắng mặt, và nó đã tồn tại (`:328`).
- **Vì sao tồn tại:** hoàn thiện một **họ LEGENDARY đối xứng, đọc được**: `r_stormcall` (mọi mặt dmg nhận Cleave) · `r_worldpiercer` (nhận Pierce) · `r_apexferal` (nhận Execute). Ba trục, một khuôn, không trùng luật.

### `r_dawnlance` — Dawn Lance · LEGENDARY · `a:'pierce'` · `mload 2` ⚠️ · `ex: ['dmgMultCond']`

- **d:** `'RULE: your attacks against an enemy above half HP deal 90% more damage.'`
- 🔧 **ĐỔI THIẾT KẾ, không phải retune số** (`relic-system.md` §6.7.1). Bản trước đo **6.80 RP = 17% của một LEGENDARY**. Hai lỗi cộng lại: (1) điều kiện *"mục tiêu **full** HP"* chỉ đúng ~30% số đòn; (2) nó chỉ áp cho đòn **`pierce`**, trong khi FERAL — thứ nó cố đối xứng — áp cho **mọi** đòn. Bản mới sửa cả hai: nới điều kiện thành **> 50% HP**, bỏ ràng buộc `pierce`, nâng hệ số lên **+90%**.
- **Hiệu ứng chính xác:** `modDmg` — nếu `ctx.tgt.hp > ctx.tgt.maxHp * 0.5` ⇒ `v = Math.ceil(v * 1.9)`.
- **Field:** `modDmg({s,src,tgt,v})` — **chạy hôm nay, KHÔNG còn cần ENG-1.** Bản mới chỉ đọc `tgt`, không cần biết đòn có `pierce` hay không. ENG-1 vẫn tồn tại cho `r_bloodhymn`/`r_shatterpoint` nhưng **relic này đã rời khỏi danh sách gate**.
- 🔒 **`mload: 2` — đây là relic `mload 2` DUY NHẤT về damage trong roster mới.** Nó là multiplier toàn cục có điều kiện, cùng hạng `r_bloodpact` (`×1.6`). Hệ quả cố ý: giữ `r_dawnlance` ⇒ **không** thêm được `r_bloodpact` hay `r_ancientgene`. Đó là giá của việc nới điều kiện từ 30% lên ~65% số đòn.
- 🔒 **Điều kiện là bù chính xác của FERAL, không phải phủ định lỏng lẻo.** FERAL/`exec` dùng `tgt.hp < tgt.maxHp*0.5` (`:316`). Điều kiện ở đây là `>` chứ **không** phải `>=` ⇒ tại đúng `hp === maxHp*0.5` **không** relic nào áp. Khe hở này có chủ đích: nó giữ hai luật **loại trừ nhau tuyệt đối**, nên không tồn tại đòn nào ăn cả `×1.6` FERAL lẫn `×1.9` này.
- **Số:** ~65% số đòn (mọi địch bắt đầu ở 100% HP và chỉ rơi xuống dưới nửa ở cuối vòng đời). Damage **dồn về đầu trận** rồi tự tắt — dynamic ngược với mọi relic khác trong game (tất cả relic hiện có đều mạnh dần hoặc phẳng).
- **Event:** thân relic tự gọi `ft(s,ctx.tgt,'LANCE','dmg')` **chỉ khi** bonus áp dụng (relic được gọi `ft` — §3.1) ⇒ không cần engine work cho event.
- **Vì sao tồn tại:** **đối xứng cố ý với FERAL** (Beast: +60% khi mục tiêu <50% HP). Hai LEGENDARY nhìn nhau: một thưởng cho việc *kết thúc*, một thưởng cho việc *mở màn*. Một party không thể ăn trọn cả hai trên cùng một đòn ⇒ đó là **intransitive balance** thật, không phải hai bản sao của một buff.
- ⚠️ **Vị trí trong pipeline damage, cần biết:** `modDmg` chạy ở `:320`, **sau** `dmgMult` (`:319`) và **trước** `critMult` (`:321`) ⇒ `×1.9` **nhân chồng** với crit. Một đòn crit vào địch trên nửa HP là `×3.8` ở `critMult 2`. Trần thật của tổ hợp này là **`mload`**: `r_dawnlance` một mình đã chiếm hết trần 2, nên nó **không thể** cùng tồn tại với `r_apexpredator` (`critBonus`+`critMult` = `mload 2`), `r_bloodpact`, hay `r_ancientgene`. `critMult 2` mặc định vẫn áp — đó là mức đã tính trong RP 38.90.

### `a_pinning` — Pinning Lance · RARE · `a:'pierce'` · 🔧 **ENG-13**

- **d:** `'[MP 3] Destroy one enemy Shield and deal damage equal to the Shield destroyed, minimum 6.'`
- **act:** `{cost:3, kind:'shatter', min:6, tgt:'enemy'}` — `kind:'shatter'` là **mới** (ENG-13).
- 🔧 **Đã thêm SÀN 6 theo §6.7.1.** Bản trước đo **11.25 RP**, dưới sàn RARE 15.88: damage bằng đúng lượng shield phá được ⇒ **0 trước địch không giáp**, và kỳ vọng `V_out` chỉ 9.0. Sàn 6 biến nó từ "thẻ chết có điều kiện" thành "đòn yếu tệ nhất, đòn mạnh tốt nhất".
- **Số:** shield địch ở `pw≈10` trên role `tank` ≈ 12-20 ⇒ **12-20 damage với MP3** (so với `a_chomp` MP3 → 12 pierce). Đánh địch **không** có shield ⇒ **6 damage** thay vì 0.
- 🔒 **Sàn 6 huỷ câu hỏi mở của ENG-13.** Bản trước hỏi `systems-designer` chốt: dùng lên địch không shield thì thất bại-không-tiêu-mana (a) hay thành công-0-damage (b). Với sàn 6, active **luôn** có hiệu ứng ⇒ nhánh `ok=false` bị **xoá khỏi spec**. Xem ENG-13 bản cập nhật.
- **Event:** `ft` (shield mất, chỉ khi `sh>0`) + `hit` + `hp` + có thể `death`.
- **Vì sao tồn tại:** **frustra balance** đúng nghĩa — mạnh vượt trội trước `e_bulwark`/`thornback`/Mecha, yếu nhưng **không vô dụng** trước `bruiser`. Nó tự cân bằng theo **đầu tư của địch**, không theo con số ta chọn. Và nó cho pierce một active mà không phải là "a_chomp nhưng to hơn".

## 6. GROWTH — EVOLVE (5 passive + 1 active)

> Đo được: **5 run/300 (1.7%)**, winrate 20%, **2 relic**. Gần như **không tồn tại trong play**.
> Toàn bộ nhóm này ưu tiên **COMMON/RARE** vì đó là tầng duy nhất với tới được trước wave 7 (§1.1),
> và §1.2 cho thấy engine phải online trước wave 10.
> Sự thật cơ chế nền: `growth` chỉ tồn tại **trong một trận** (`u.growth` nằm trên unit, party được
> `buildUnit` lại mỗi trận) ⇒ EVOLVE mạnh ở trận boss dài, yếu ở trận ngắn. Đó là hình dạng thật của nó.

### `r_seedling` — Seedling Core · COMMON · `a:'growth'` · 🔧 **ENG-2 + ENG-18 (G1)** · `mload 0` · `ex: []`

- **d:** `'Every face grows by 1 each turn. Growth faces grow by 2 instead of 1.'`
- 🔧 **Đã thêm mệnh đề `growthAll: 1` theo §6.7.2.** Bản trước đo **3.14 RP = 24% của một COMMON**. Nguyên nhân đo được: `growthPlus:1` **chỉ** áp cho mặt **đã có** keyword `growth`, và tần suất đó là `p_eff = 0.20`. `relic-system.md` §4.5 ví dụ 5 chứng minh `growth` gần **vô giá trị** ở `Ω=5` (trận trung bình 5 lượt) khi nó chỉ cộng cho đúng mặt vừa dùng.
- **Hiệu ứng chính xác:** hai mệnh đề:
  1. `growthAll: 1` — đầu mỗi lượt, **mọi** mặt (`f.v > 0`) của mỗi Axie không-token `+1` vĩnh viễn trong trận;
  2. `growthPlus: 1` — mặt có keyword `growth` tăng `1 + rsum(s,'growthPlus')` = **2** mỗi lần dùng.
- **Field:** `growthAll` (`rsum`, cần **ENG-18** = G1 của `relic-system.md` §10) + `growthPlus` (`rsum`, cần **ENG-2**).
- 🔒 **G1 chuyển từ *tuỳ chọn* sang *BẮT BUỘC*.** `relic-system.md` §10 G1 và §18 kết luận 1 nói rõ: **`growth` không có bậc nào hợp lệ nếu không có `growthAll`** — mọi thiết kế growth-thuần đều nằm dưới dải. Nếu G1 bị cắt scope thì **EVOLVE không tồn tại được** và 3/5 relic nhóm này phải bị rút.
- **Số:** `growthAll:1` cho `1 × (Ω−1) × n × p_dmg` ≈ 10.6 RP; `growthPlus:1` cho phần còn lại. Tổng 13.70, đích COMMON 13.20.
- **Event:** ENG-2 **đồng thời bổ sung `ft(s,u,'GROW +N','buf')`** — hiện tại `growth` **không phát event nào** (`doFace:539` chỉ cộng số), tức nó vô hình trừ khi người chơi tự so sánh mặt die. Đây là một lỗ visibility đang tồn tại mà ENG-2 vá luôn.
- **Vì sao tồn tại:** cửa vào duy nhất của EVOLVE ở tier với tới được sớm. Cộng hưởng mạnh với `r_growthcore` (EPIC, mọi mặt dmg nhận growth) mà **không** trùng luật với nó (một cái *cấp* growth, một cái làm growth *nhanh hơn*).

### `r_heartwood` — Heartwood · RARE · `a:'growth'` · 🔧 **ENG-18 (G1)** · `mload 0` · `ex: []`

- **d:** `'RULE: from the second turn on, every face on each Axie grows by 2 for the rest of the fight.'`
- 🔧 **ĐỔI CƠ CHẾ theo §6.7.2.** Bản trước đo **1.76 RP = 9% của một RARE** — thấp nhất toàn roster. Nguyên nhân đo được: "1 mặt **ngẫu nhiên**/Axie/lượt" đúng bằng **1/6** của `growthAll:1`, và `growthAll:1` mới chỉ là 10.6 RP.
- **Hiệu ứng chính xác:** `growthAll: 2`, có guard `s.turn > 1` ⇒ từ lượt 2, **mọi** mặt (`f.v > 0`) của mỗi Axie không-token `+2` vĩnh viễn trong trận.
- **Field:** `growthAll` (`rsum`) + guard lượt — cần **ENG-18** (G1). Guard `s.turn > 1` nằm trong thân relic, không nằm trong spec G1.
- 🔒 **BỎ `ri(6)` ⇒ relic không còn tiêu RNG.** Đây là lợi ích phụ quan trọng: bản trước *dịch* RNG stream mỗi lượt, hợp lệ nhưng làm mọi bug replay khó chẩn đoán hơn. Bản mới **tất định tuyệt đối, không chạm `rnd()`** — đúng pillar "minh bạch triệt để" và giảm bề mặt rủi ro cho `soak.mjs`.
- **Kiểm chứng guard:** `startCombat` set `s.turn=1` (`:229`) **rồi** gọi `rcall(s,'onTurnStart')` (`:235`) ⇒ lượt 1 bị bỏ qua ✅. `endTurn` làm `s.turn++` (`:632`) **rồi** `rcall` (`:635`) ⇒ chạy từ lượt 2 ✅. (G1 spec đặt điểm gọi trong `endTurn` sau `rollAll`; guard `s.turn>1` cho cùng kết quả ở cả hai điểm.)
- **Số:** `2 × (Ω−1) × n × p_dmg` ≈ 21.1 RP, đích RARE của EVOLVE 18.68. Chậm hơn `r_seedling` một lượt nhưng gấp đôi tốc độ — đúng hình dạng "payoff trận dài" của archetype.
- **Event:** `ft` (`'GROW +2'`, class `buf`) qua `EVrelic` trong spec G1.
- ⚠️ **`growthAll` là `rsum` ⇒ `r_seedling` + `r_heartwood` = `growthAll 3`/lượt.** Cả hai `mload 0` nên **không gì cấm cặp này**. Cộng phẳng, không nhân, nên nó không suy biến — nhưng nó là cặp cộng dồn mạnh nhất của EVOLVE. Ghi ở §17.4.
- **Vì sao tồn tại:** EVOLVE hiện **không có RARE nào** — nó nhảy thẳng từ không-gì tới EPIC. Đây là relic khiến archetype tồn tại ở early game, và nó không cần mặt `growth` nào có sẵn (khác `r_seedling`) ⇒ nó là relic EVOLVE duy nhất **luôn** hoạt động.

### `r_bloomscale` — Bloomscale · RARE · `a:'growth'` · 🔧 **ENG-2** · `mfPhase:'kw'` · `mload 0` · `ex: []`

- **d:** `'RULE: every Back and Eyes face gains Growth, and Growth faces grow by 4 instead of 1.'`
- 🔧 **Đã thêm `growthPlus: 3` theo §6.7.2.** Bản trước đo **4.35 RP** — mệnh đề tiêm `growth` vào `back`+`eyes` chỉ cho `p = 0.277` đơn vị phơi nhiễm × 15.7 RP/đơn vị. Tiêm keyword mà không tăng tốc độ tích luỹ là quá rẻ ở `Ω=5`.
- **Hiệu ứng chính xác:** hai mệnh đề:
  1. `modFace` inject `growth` vào mọi mặt có `(f.p==='back' || f.p==='eyes')` **và** `f.v > 0` **và** chưa có `growth`;
  2. `growthPlus: 3` ⇒ mặt có `growth` tăng `1 + rsum(s,'growthPlus')` mỗi lần dùng.
- 🔒 **`growthPlus` là `rsum` ⇒ cộng dồn với `r_seedling` (`+1`) thành `+5`/lần dùng.** Đây là **cố ý** và là lý do relic này **không mang `ex`**: hai relic cùng trục nhưng **không** dead-draw nhau (một cái *cấp* growth cho part mới, một cái tăng tốc). Cộng phẳng, `mload 0` cả hai.
- **Field:** `modFace` (`mfPhase:'kw'`) + `growthPlus` (`rsum`, cần **ENG-2**).
- **kwPure Direction Law:** `growth` nằm trong **danh sách loại trừ** của `kwPure` (`:489`) ⇒ nó **không bao giờ** đi qua `addStatus` ⇒ an toàn hướng với **mọi** loại mặt. Đây là lý do 5 relic inject-keyword hiện có đều an toàn, và tôi giữ nguyên tính chất đó.
- **Guard `f.v>0`, có lý do:** mặt `buff`/`debuff` có `v===0` (reptile `thorns:2`, bug `weaken:2`). `faceValue` cộng `u.growth[fi]` vào `v` nhưng nhánh `buff`/`debuff` của `doFace` **chỉ dùng `kwPure`, bỏ qua `v`** ⇒ growth trên mặt đó **hoàn toàn vô nghĩa** và sẽ trông như relic bị hỏng.
- **Số:** ~1.5 lần dùng back/eyes/lượt × `+1` ⇒ đến lượt 5, shield/heal cao hơn +3-4.
- **Event:** không có event runtime — hiển thị trên mặt die; kèm `ft 'GROW'` nếu ENG-2 được làm.
- **Vì sao tồn tại:** `r_growthcore` chỉ phủ mặt `dmg`. Đây là **con đường duy nhất** tới một build EVOLVE phòng ngự (Plant: shield lớn dần + BULWARK `+2` + Thorns 2 khi shield ≥10). Nó biến EVOLVE từ "một trục" thành "hai trục" và làm sâu bản sắc Plant (constraint 9).

### `r_quickenroot` — Quickenroot · EPIC · `a:'growth'` · `mload 0` · `ex: []`

- **d:** `'RULE: from the second turn on, the face each Axie has rolled grows by 1 permanently.'`
- 🔧 **Đã thêm guard `s.turn <= 1` theo §6.7.2.** Bản trước đo **33.30 RP — nằm gọn trong `Band[3]`**, tức một EPIC đứng ở bậc LEGENDARY: `onRollEnd` đặt `+1` growth lên **đúng mặt sắp dùng**, nên nó cho `+1` damage **ngay lượt đó** × 5 Axie × 5 lượt, **cộng** phần tích luỹ. Bỏ lượt 1 cắt đúng phần dồn-đầu.
- **Hiệu ứng chính xác:** `onRollEnd` — **nếu `s.turn <= 1` thì return**; ngược lại với mỗi Axie sống có `u.rolled >= 0`, `!u.used`, `u.die[u.rolled].v > 0`: `u.growth[u.rolled] += 1`.
- **Field:** `onRollEnd:s=>{ if(s.turn<=1) return; aliveP(s).forEach(u=>{ if(u.rolled>=0&&!u.used&&u.die[u.rolled].v>0){ u.growth[u.rolled]=(u.growth[u.rolled]||0)+1; ft(s,u,'GROW','buf'); } }); }` — **chạy hôm nay**.
- 🔒 **Guard đọc `s.turn` trong `onRollEnd`, không phải `onTurnStart` — phải kiểm đúng điểm gọi.** `rollAll` chạy trong `startCombat` (khi `s.turn===1`) và trong `endTurn` **sau** `s.turn++`. Nên `s.turn<=1` loại **đúng** vòng roll đầu tiên và không loại gì khác ✅.
- **Điểm mấu chốt:** `onRollEnd` **chỉ** được `rollAll` gọi (`:277`), **không** được `doReroll` gọi ⇒ đúng **1 lần/lượt**, và nó thưởng cho mặt bạn **không reroll**. Đó là một quyết định thật, ngược chiều reroll economy — và là điều duy nhất trong roster này tạo ra căng thẳng đó.
- **Determinism:** không dùng RNG ✅.
- **Số:** `+5`/lượt, đặt đúng lên mặt bạn **sắp dùng**, cộng dồn vĩnh viễn trong trận. Đến lượt 5, các mặt roll thường xuyên đã `+4~5`. Yếu ở trận ngắn, mạnh ở trận boss ⇒ đúng hình dạng EVOLVE.
- **Event:** `ft` (`'GROW'`) × số Axie sống, mỗi lượt.
- **Vì sao tồn tại:** đây là relic khiến `growth` thật sự *hoạt động*. Mọi nguồn growth hiện có yêu cầu bạn **dùng đúng mặt đó** nhiều lần (xác suất 1/6 mỗi lượt); relic này growth mặt bạn **đang có**, nên nó không phụ thuộc may mắn.

### `r_worldtree` — World Tree · LEGENDARY · `a:'growth'` · 🔧 **ENG-3** · `mload 1` · `ex: []`

- **d:** `'RULE: your Axie keep half of everything they grew, up to +3 per face, for the rest of the run.'`
- 🔧 **Đã thêm TRẦN CỨNG `GROWTH_KEEP_CAP = 3` theo §6.7.2.** Bản trước đo **≈70 RP = 1.6× trần LEGENDARY**, và là **relic duy nhất trong game tích luỹ qua các trận không có trần**. Đây chính là rủi ro §17.6 #1 mà chính tài liệu này tự ghi nhận là "ngoại suy, chưa đo" — audit đã phán quyết thay vì chờ sim.
- **Hiệu ứng chính xác:** `growthKeep:1`. Khi kết thúc trận, với mỗi roster entry và mỗi slot mặt `k`:
  `re.grown[k] = Math.min(GROWTH_KEEP_CAP, seeded + Math.floor(earned/2))` với `GROWTH_KEEP_CAP = 3`.
  Công thức đầy đủ + lý do phải trừ phần đã seed: xem **ENG-3** (§16).
- 🔒 **`GROWTH_KEEP_CAP` phải là hằng có tên trong `data.js`**, không phải số `3` trần trong thân relic — cùng lý do và cùng khuôn với `IRONMAIDEN_CAP` (§17.6 #2). Trần này là thứ chịu toàn bộ tải chống-suy-biến của EVOLVE qua nhiều trận.
- 🔒 **Trần áp lên `re.grown` (phần MANG QUA TRẬN), không lên `u.growth` (phần trong trận).** Growth kiếm được trong một trận vẫn không có trần — `r_quickenroot`/`r_heartwood` vẫn tích luỹ tự do đến hết trận. Chỉ phần **bền qua trận** bị chặn ở `+3`/mặt. Đây là ranh giới đúng: nó giữ nguyên hình dạng "trận boss dài = payoff lớn" của archetype, chỉ cắt phần cộng dồn vô hạn xuyên run.
- **Field:** `growthKeep` (`rhas`) + hạ tầng `re.grown` + hằng `GROWTH_KEEP_CAP` — cần **ENG-3**.
- **Số:** trần `+3` × 6 mặt × 5 Axie = **+90 giá trị mặt tối đa toàn party**, đạt được sau ~3-4 trận rồi **bão hoà**. Trước audit con số này là `+240` và **không bao giờ** bão hoà.
- ✅ **Rủi ro §17.6 #1 đã đóng bằng phương án (c) mở rộng.** Ba lựa chọn ghi ở đó là (a) `mload 1`, (b) `ex` chung, (c) hạ tỉ lệ giữ. Audit áp **(a) + trần cứng**: `mload: 1` **và** cap 3. Cặp `r_quickenroot` + `r_worldtree` vì vậy vẫn hợp lệ (`mload` 0+1 = 1) nhưng phần compounding của nó đã có trần.
- **Event:** không có event runtime; giá trị mặt die **cao hơn hẳn ngay từ đầu trận** ⇒ hiển thị ở màn hình die/reward. Đề nghị ENG-3 phát thêm một dòng trên reward screen.
- **Vì sao tồn tại:** vá đúng điểm yếu cốt lõi của archetype (growth reset mỗi trận). Đây là LEGENDARY duy nhất trong game thay đổi **cấu trúc run**, không phải một trận.
- ⚠️ **Nhịp độ:** đây là engine **muộn**, và §1.2 nói engine phải online trước wave 10. Nó không. Chấp nhận được vì nó là LEGENDARY (gate bởi `u_relic2`) — nhưng nghĩa là early game của EVOLVE **phải** dựa vào `r_seedling`/`r_heartwood`/`r_bloomscale`. Đó là lý do 3/5 relic nhóm này nằm ở C/R.

### `a_bloom` — Bloom Surge · EPIC · `a:'growth'` · 🔧 **ENG-11** · `mload 0` · `ex: []`

- ✅ **PASS INV-1 nguyên trạng** (RP 29.25 theo `RP_act` với `N* = 3`, `Band[2]` = [22.44, 30.36]). Đây là **active duy nhất trong 8 active mới** không phải đổi giá hay đổi giá trị — `MP 5` cho một hiệu ứng chỉ tích luỹ (không tức thời) là mức giá đúng ngay từ đầu.
- **d:** `'[MP 5] The face each Axie has rolled grows by 3 permanently.'`
- **act:** `{cost:5, kind:'grow', v:3, tgt:'self'}` — `kind:'grow'` là **mới** (ENG-11).
- **Số:** `+15` rải mỗi lần dùng, lặp mỗi lượt ⇒ 5 lượt = `+75` rải. Bị chặn bởi mana và bởi độ dài trận.
- **Event:** `ft` (`'GROW +3'`) × số Axie sống.
- **Vì sao tồn tại:** EVOLVE không có cách nào **tiêu** một early game tốt — nó chỉ biết chờ. Mana là tài nguyên duy nhất nó có thể chuyển thành thời gian. Relic này làm **CONDUIT + EVOLVE** thành một build chéo thật, và nó là active đầu tiên của archetype (từ 0).

## 7. SUMMON — SWARM (5 passive + 1 active) · access, không phải power

> Đo được: 12 run/300 (4%), winrate **33% — CAO NHẤT GAME**, **2 relic**.
> ⇒ **Không buff.** Mọi entry dưới đây là *sustain* hoặc *quyền truy cập*, không phải nâng trần.
> Sự thật cơ chế: `mkAlly` (`:239-244`) — `sc=max(1, budget(pw)/14)`, `hp=max(4, round(6·sc·0.55))`,
> die = `scaleDie(MON.egg.die, sc*0.5)`, `cls:'aqua'`, `token:1`. **Token KHÔNG nhận `modFace`**
> (chỉ `buildUnit` gọi nó). Cap **4** token sống (`doFace:532`). Token không tính vào `realP` ⇒
> không cứu được bạn khỏi thua, cũng không làm bạn thua. `hiveMind` (`faceValue:411`) cộng
> `rsum(hiveMind) × số egg sống` vào **mọi mặt dmg của cả party** ⇒ **giữ egg sống ĐÃ LÀ buff damage**.
> Đó là lý do mọi buff egto ở đây đều nhỏ.

### `r_broodpouch` — Brood Pouch · COMMON · `a:'summon'`

- **d:** `'Start every fight with an Axie Egg.'`
- **Hiệu ứng chính xác:** `startSummon:1`.
- **Field:** `startSummon` (`rsum`, đọc tại `startCombat:226`) — **chạy hôm nay**.
- **Số:** 1 egg ≈ 1 die phụ/lượt ở ~nửa giá trị ≈ **+3/lượt**, cộng một thân thể hút đòn. Cộng dồn `rsum` với `r_swarmnest` (2) + `r_hivemind` (1) ⇒ tối đa **4 = đúng cap**, không tràn.
- **Event:** unit mới xuất hiện lúc bắt đầu trận (party render); không cần event mới.
- **Vì sao tồn tại:** SWARM **không có COMMON và không có RARE** ⇒ theo §1.1 nó **không thể** khởi động trước power-level 7. Đây là bản vá truy cập rẻ nhất có thể, và nó **không nâng trần** (egg thứ 1 là egg yếu nhất về giá trị biên vì `hiveMind` scale theo số lượng).

### `r_eggshell` — Eggshell Ward · RARE · `a:'summon'` · `mload 0` · `ex: []`

- **d:** `'RULE: every Axie Egg gains 2 Shield at the start of each turn.'`
- 🔧 **Đã hạ Shield 3 → 2 theo §6.7.3.** Bản trước đo **21.90 RP — nằm trong VÙNG CẤM** giữa trần RARE (21.48) và sàn EPIC (22.44). Đây là loại vi phạm INV-1 nguy hiểm nhất vì nó không nhìn ra được bằng mắt: relic *có vẻ* đúng bậc, nhưng RP của nó rơi vào khe không bậc nào sở hữu.
- **Hiệu ứng chính xác:** `onTurnStart` — mỗi token còn sống nhận `applyShield(s, u, 2)`.
- **Field:** `onTurnStart:s=>s.party.forEach(u=>{ if(u.token&&u.hp>0) applyShield(s,u,2); })` — **chạy hôm nay** (§3.1).
- **Tự chặn trên:** `applyShield` cap ở `t.maxHp*2` (`:377`). Egg `maxHp ≈ 4-10` ⇒ cap **8-20** ⇒ 2/lượt tích tới cap rồi **dừng**. Không cần cap thủ công. Egg là `cls:'aqua'` nên **không** ăn Plant `+2`.
- **Số:** 2 × tối đa 6 egg (`tokenCap` mới, xem `r_hivequeen`) = **12 mitigation/lượt** ở trạng thái full egg — mà full egg cần đầu tư LEGENDARY mới có. Ở cap mặc định 4 là **8/lượt**.
- **Event:** `ft` (`'+3'`, class `shd`) + `hp` từ `applyShield:378`.
- **Vì sao tồn tại:** egg chết vì bất kỳ đòn AoE nào (`hp = max(4, …)`). Đây là *sustain*, không phải trần — và giữ egg sống là điều kiện tiên quyết để `hiveMind` có nghĩa.

### `r_broodmother` — Broodmother · RARE · `a:'summon'` · `mload 0` · `ex: []`

- **d:** `'RULE: whenever an enemy dies, hatch an Axie Egg. Your Eggs deal 1 more damage.'`
- 🔧 **Đã thêm mệnh đề "+1 damage cho Egg" theo §6.7.3.** Bản trước đo **9.75 RP**, dưới sàn RARE 15.88. Nguyên nhân đo được: **cap token nuốt phần lớn số lần nở** — với 4-5 kill/trận nhưng cap 4, số egg-lượt **hữu ích** thực tế chỉ tăng ~1.5. Mệnh đề damage cấp giá trị không bị cap ăn.
- **Hiệu ứng chính xác:** hai mệnh đề:
  1. `onKill` — nếu số token sống `< rmax(s,'tokenCap',4)`: tạo 1 egg qua `mkAlly(s)`, `rollUnit`, `used=true`, push vào `s.party`;
  2. `onTurnStart` — một lần cho mỗi token (cờ `u.eggDmg`): mọi mặt `t==='dmg'` của nó `v += 1`.
- 🔒 **Mệnh đề 2 dùng CÙNG KHUÔN với `r_apexbrood`** (cờ trên unit, không phải `modFace`): token **không bao giờ** đi qua `buildUnit` nên `modFace` không với tới chúng. Cờ `u.eggDmg` riêng biệt với `u.eggBuff` của `r_apexbrood` ⇒ hai relic cộng dồn đúng, mỗi cái áp đúng một lần.
- **Field:** `onKill` + `onTurnStart` + cờ — **chạy hôm nay** (§3.1).
- **`used=true` là bắt buộc:** khớp đúng quy ước của mặt `summon` (`doFace:532`) và tránh bug `rolled=-1` đã ghi trong `game-concept.md` §Edge Cases ("mọi code đọc mặt die phải guard `rolled≥0`"). `rollUnit` trước, `used` sau ⇒ egg có mặt hợp lệ để hiển thị nhưng không hành động lượt nó sinh ra.
- **Determinism:** `rollUnit` tiêu RNG đã seed ⇒ tất định khi replay ✅.
- **Số:** 4-5 kill/trận ⇒ bù đắp tổn thất, giữ số egg gần cap thay vì tụt về 0.
- **Event:** `ft` (`'HATCH'`) + `hp`; party có thành viên mới ⇒ ui re-render (đường này đã tồn tại cho mặt `summon`).
- **Vì sao tồn tại:** thất bại thật của SWARM là **hao mòn** — bạn nhận egg một lần rồi chúng chết. Relic này giữ archetype **online**, không nâng trần (nó chỉ khôi phục về cap 4 vốn đã có).

### `r_apexbrood` — Apex Brood · EPIC · `a:'summon'` · `mload 0` · `ex: []`

- **d:** `'RULE: Axie Eggs have 8 more Max HP and their attacks deal 2 more.'`
- 🔧 **Đã nâng Max HP +4 → +8 theo §6.7.3.** Bản trước đo **20.50 RP**, dưới sàn EPIC 22.44. Mệnh đề `dmg += 2` giữ **nguyên** — audit nâng đúng trục **survivability**, không nâng damage, vì `hiveMind` đã biến việc giữ egg sống thành damage (xem lời mở §7).
- **Hiệu ứng chính xác:** một lần cho mỗi token: `maxHp += 8`, `hp += 8`, và mọi mặt `t==='dmg'` của nó `v += 2`.
- **Field:** `onTurnStart:s=>s.party.forEach(u=>{ if(u.token&&u.hp>0&&!u.eggBuff){ u.eggBuff=1; u.maxHp+=8; u.hp+=8; u.die.forEach(f=>{ if(f.t==='dmg') f.v+=2; }); EVhp(s,u); } })` — **chạy hôm nay**.
- 🔒 **`maxHp += 8` cũng nâng trần Shield của egg** vì `applyShield` cap ở `maxHp*2` (`:377`): egg `maxHp` 4-10 → 12-18 ⇒ cap shield 24-36. Với `r_eggshell` (2/lượt) trần đó không bao giờ chạm tới, nên đây là nâng trần **danh nghĩa**, không phải thực tế. Ghi lại để QA không đọc nhầm là cộng dồn.
- **Vì sao dùng cờ trên unit chứ không `modFace`:** token **không bao giờ** đi qua `buildUnit` ⇒ `modFace` không với tới chúng. Cờ `u.eggBuff` nằm trên unit, unit nằm trong `party`, `party` nằm trong `SNAP` (`:547`) và `snap()` dùng `clone()` (JSON round-trip) ⇒ **undo khôi phục đúng cờ** ✅.
- **Số:** 4 egg × (`+2` dmg, `+4` HP) = **+8/lượt + 16 HP**. Đã **hạ từ bản nháp `+3`/`+6`** (§1.3) vì `hiveMind` biến survivability thành damage.
- **Event:** `hp` (`EVhp`).
- **Edge:** egg sinh **giữa lượt** chỉ được buff ở `onTurnStart` **lượt sau**; nếu trận kết thúc trước thì nó không bao giờ được buff. Chấp nhận (không sai số, chỉ là timing), ghi lại để QA không báo là bug.
- **Vì sao tồn tại:** egg scale theo `budget(pw)` nên không lỗi thời, nhưng chúng vẫn là unit giấy. Đây là relic duy nhất làm egg **đáng để giữ**.

### `r_hivequeen` — Hive Queen · LEGENDARY · `a:'summon'` · 🔧 **ENG-20** · `mload 2` ⚠️ · `ex: ['eggInherit']`

- **d:** `'RULE: your Axie Eggs inherit every relic that reshapes your dice, and you may keep 6 Eggs.'`
- 🔧 **ĐỔI THIẾT KẾ TOÀN BỘ, không phải retune số** (`relic-system.md` §6.7.3). Bản trước đo **12.10 RP = 36% của một LEGENDARY** — tài liệu này đã **tự nghi ngờ** đúng chỗ ("có thể *quá* nhẹ", §18). Audit đo ra nguyên nhân: (1) kế thừa class chỉ có tác dụng **thật** với 2/6 class; (2) copy **1** mặt lên die 6 mặt của egg chỉ đổi **~1/6** số lần roll. **Không con số nào đưa được bản cũ tới LEGENDARY** — nó cần một **đòn bẩy cấu trúc**, và đó là lý do audit thay cơ chế thay vì nhân hệ số.
- **Hiệu ứng chính xác:** hai mệnh đề, **bỏ toàn bộ mệnh đề class/HP/copy-face**:
  1. **`eggInherit`** — mọi Axie Egg nhận **toàn bộ `modFace` của bạn**, áp lên die egg theo đúng thứ tự pha INV-5;
  2. **`tokenCap: 6`** — số Egg tối đa cùng lúc lên 6 (mặc định 4).
- **Field:** `eggInherit` (`rhas`) + `tokenCap` (`rmax`) — cần **ENG-20**. `mkAlly` hôm nay **không** chạy `modFace` (chỉ `buildUnit` chạy) và cap 4 là **số trần** ở `doFace:532`; cả hai phải thành knob.
- 🔒 **Đây là lối vào đúng, vì nó biến egg từ "unit phụ" thành "phần mở rộng của build".** Người chơi cầm `r_pierceall` + `r_talonedge` thấy egg của mình cũng xuyên giáp; cầm `r_apexferal` thấy egg cũng xử tử. Nó **không thêm một con số nào** — nó nhân giá trị của những relic bạn **đã có**, nên công suất tự scale theo độ sâu build thay vì theo một hằng số.
- 🔒 **`mload: 2` là GIÁ của việc mở cánh cửa §7 E9 đang đóng, và là quyết định có ý thức.** `relic-system.md` §7 E9 cấm relic nhân output của relic khác. Relic này **cố ý** vi phạm khuôn đó, và `mload 2` — hết trần — là cái giá: giữ `r_hivequeen` ⇒ **không** thêm được bất kỳ multiplier nào khác (`r_bloodpact`, `r_ancientgene`, `r_apexpredator`, `r_dawnlance`, `r_hearthcore`…). Đó là điều duy nhất giữ nó trong dải.
- ⚠️ **Đảo ngược có ý thức một quyết định cũ của chính tài liệu này.** §17.3 (bản trước) ghi *"Relic set `tokenCap`: **không làm, có chủ đích**"* vì `hiveMind` scale theo **số** token nên nới cap là "cách nới tệ nhất". Lập luận đó **vẫn đúng** — và đó chính là lý do việc nới cap được đặt ở **LEGENDARY, mload 2, đúng một relic**. Hệ quả phải biết: với `r_hivemind` (`hiveMind:1`), cap 4→6 cộng thêm `+2` damage cho **mọi mặt dmg của cả party**. Đã tính trong RP 38.00; ghi lại ở §17.4.
- **Số:** die egg đi từ `scaleDie(MON.egg.die, sc*0.5)` trần trụi sang die mang **mọi** luật `modFace` của party × tối đa 6 token.
- **Event:** `ft` (`'HATCH'`) + `hp` khi egg nhận `modFace`; die egg hiển thị giá trị mới trên UI party.
- **Vì sao tồn tại:** fantasy LEGENDARY của SWARM ("đàn của bạn mang dòng máu của bạn") — bản cũ diễn đạt nó bằng **class**, thứ engine gần như không tiêu thụ; bản mới diễn đạt bằng **die**, thứ engine tiêu thụ mỗi lượt.
- ❌ **Đã bỏ:** kế thừa `cls`/`pas`, `maxHp = max(u.maxHp, ceil(lead.maxHp*0.4))`, và `u.die[0] = clone(mặt mạnh nhất)`. Phân tích cũ về việc class inheritance chỉ hoạt động với Plant/Beast **giữ giá trị lịch sử** (nó là bằng chứng để bỏ), nhưng **không còn mô tả relic này**.

### `a_clutch` — Clutch Call · RARE · `a:'summon'` · 🔧 **ENG-12** · `mload 0` · `ex: []`

- **d:** `'[MP 4] Summon 1 Axie Egg.'`
- **act:** `{cost:4, kind:'summon', v:1, tgt:'self'}` — `kind:'summon'` là **mới** (ENG-12). Spec phải tôn trọng `rmax(s,'tokenCap',4)` và set `used=true`, giống `doFace:532`.
- 🔧 **Đã hạ `v: 2 → 1` theo §6.7.3.** Bản trước đo **34.00 RP — nằm gọn trong `Band[3]`**, tức một RARE đứng ở bậc LEGENDARY. Phép đo: 2 egg mỗi lượt tới cap là **52 RP giá trị token** đổi lấy 8 mana. Đây là hệ quả trực tiếp của việc active **lặp lại mỗi lượt** (§4.3 #1) — một sai số về tần suất, không phải về giá trị đơn lẻ.
- **Số:** 1 egg/lượt với MP4, chặn ở `tokenCap` (4, hoặc 6 với `r_hivequeen`). Lặp mỗi lượt nhưng cap làm nó tự tắt.
- **Event:** `ft` (`'SUMMON'`) + `hp` cho mỗi egg mới.
- **Vì sao tồn tại:** hôm nay egg chỉ đến từ `startSummon` (relic) hoặc mặt `summon` (phải rút được đúng mặt trong `FACE_POOL`). Đây là relic duy nhất biến SWARM thành archetype chơi được **mà không phụ thuộc face RNG** — đúng định nghĩa "access" ở §1.3.

## 8. THORNS — AEGIS (6 passive + 1 active) · access, không phải power

> Đo được: **4 run/300 (1.3%)**, winrate 25% (trên baseline 20%), **2 relic**. Không tồn tại trong play.
> ⇒ **Không buff trần.** Chủ yếu mở đường.
> **Ba sự thật cơ chế lái toàn bộ nhóm này:**
> 1. **`thorns` KHÔNG BAO GIỜ decay.** `tickStatus` (`:640-662`) giảm `poison`, `burn`, `regen`, `blind`,
>    `weaken`, `vulnerable` — **`thorns` không xuất hiện ở đâu**. Giá trị tổng của nó **vô hạn theo số lượt**.
>    ⇒ Mọi nguồn thorns **cộng dồn** là một quả bom hẹn giờ. Tôi dùng **sàn (floor)**, không dùng cộng dồn.
> 2. `th *= rmax(s,'thornsMult',1)` (`:341`) **không làm tròn** ⇒ `thornsMult` **phải là số nguyên**,
>    nếu không sẽ ra HP phân số. Tôi không thêm `thornsMult` nào.
> 3. Thorns chỉ nổ khi `o.attack` (`:339`) ⇒ nó **phản ứng**: bạn phải sống và phải *không* giết nhanh.
>    Đó là chốt an toàn tự nhiên của archetype, và là lý do nó không giết được gì (xem `r_ironmaiden`).

### `r_barbedhide` — Barbed Hide · COMMON · `a:'thorns'` · 🔧 **ENG-4** · `mfPhase:'add'` · `mload 0` · `ex: []`

- **d:** `'Your Thorns deal 1 more damage. Shield faces give 1 more.'`
- 🔧 **Đã hạ `thornsPlus` 2 → 1 và thêm rider Shield, theo §6.7.4.** Bản trước đo **17.00 RP — nằm gọn trong `Band[1]`**, tức một COMMON đứng ở bậc RARE. Phép đo: `thornsPlus:2` đáng `H × 2 × κ_def`, và hệ số phòng thủ `κ_def` làm mỗi điểm thorns đắt hơn nhiều so với cảm giác. Rider `shield +1` rẻ hơn `thornsPlus +1` nên nó là cách đúng để lấp phần RP còn thiếu.
- **Hiệu ứng chính xác:** hai mệnh đề:
  1. `thornsPlus: 1`;
  2. `modFace` — `+1` value cho mọi mặt `t==='shield'` (`mfPhase:'add'`).
- **Field:** `thornsPlus` (`rsum`, cần **ENG-4**) + `modFace`.
- 🔒 **Rider Shield dùng chung mệnh đề với `r_bloodthorn` — cộng dồn, KHÔNG dead-draw, KHÔNG mang `ex`.** Hai relic cùng cộng `+1` vào mặt `shield` ⇒ giữ cả hai cho `+2`. Cộng phẳng ở pha ADD nên không suy biến, và mỗi relic vẫn mang một mệnh đề chính **khác nhau** (`thornsPlus` vs hồi máu khi bị đánh) ⇒ không relic nào trở nên vô nghĩa. Đây đúng là trường hợp luật `ex` **không** áp: `ex` chặn *trùng luật*, không chặn *cộng dồn phẳng*.
- 🔒 **Yêu cầu thiết kế bắt buộc của ENG-4: cộng SAU khi nhân.** `th = th*rmax(s,'thornsMult',1) + rsum(s,'thornsPlus')`. Nếu cộng *trước*, nó sẽ nhân với `r_mirrorshell` (`×3`) và một COMMON biến thành `+6`. Đây là chống-stack **do cấu trúc** (A7).
- **Số:** `+2` mỗi đòn địch đánh vào × ~4 đòn/lượt = **+8/lượt**. Chỉ có tác dụng nếu bạn *có* thorns (Reptile luôn có; class khác cần `r_spines`/`r_glassspine`/mặt `thorns:N`).
- **Event:** event `hit` sẵn có (`:342`, `EV(s,{t:'hit',src:tgt.uid,uid:src.uid,v:th})`) đã hiển thị đúng con số mới ✅ — không cần event mới.
- **Vì sao tồn tại:** AEGIS không có COMMON ⇒ không với tới được trước power-level 7 (§1.1).

### `r_bloodthorn` — Bloodthorn · RARE · `a:'thorns'` · 🔧 **ENG-19 (`onDmgTaken`)** · `mfPhase:'add'` · `mload 0` · `ex: []`

- **d:** `'RULE: when an Axie is struck, it heals a third of its own Thorns. Shield faces give 1 more.'`
- 🔧 **Đã đổi HOOK và thêm rider, theo §6.7.4.** Bản trước đo **14.00 RP**, dưới sàn RARE 15.88. Hai thay đổi:
  1. **rider `shield +1`** (cùng mệnh đề với `r_barbedhide`) để đạt dải;
  2. **`onThorns` → `onDmgTaken`** — **QĐ-2 của product owner đã duyệt implement `onDmgTaken`** (`relic-system.md` §14), nên relic này diễn đạt được ý định gốc **trực tiếp** thay vì đi vòng qua một hook chỉ nổ khi thorns nổ.
- **Hiệu ứng chính xác:** hai mệnh đề:
  1. `onDmgTaken` — nếu `ctx.attack` **và** `ctx.tgt.side==='p'` **và** `ctx.tgt.st.thorns > 0` **và** `ctx.tgt.hp > 0` ⇒ `applyHeal(s, ctx.tgt, Math.ceil(ctx.tgt.st.thorns / 3))`;
  2. `modFace` — `+1` value cho mọi mặt `t==='shield'` (`mfPhase:'add'`).
- **Field:** hook `onDmgTaken(s,{src,tgt,dealt,attack})` — cần **ENG-19**. `modFace` chạy hôm nay.
- 🔒 **`r_bloodthorn` ĐÃ ĐƯỢC GỠ khỏi danh sách gate của ENG-5.** ENG-5 (`onThorns`) vẫn cần thiết, nhưng chỉ còn gate `r_retributor` và `r_scalecrown`. Xem §16.
- 🔒 **Guard `ctx.attack` là bắt buộc để giữ ĐÚNG con số cũ.** `onDmgTaken` (G2(b)) được gọi cho **mọi** lần trừ HP, kể cả tick poison/burn với `src=null`. Thorns thì chỉ nổ khi `o.attack` (`:339`). Không có guard `attack`, tần suất trigger tăng vọt và relic sẽ vượt dải. Vì vậy ENG-19 **phải** đưa `attack` vào ctx — đây là phần mở rộng duy nhất tài liệu này yêu cầu thêm so với G2(b) nguyên bản.
- 🔒 **KHÔNG guard `dealt > 0`, có lý do.** Một Axie AEGIS thường có Shield, nên yêu cầu HP thật sự bị trừ sẽ cắt phần lớn số lần trigger và làm relic tụt xuống dưới dải lần nữa. "Bị đánh" ở đây nghĩa là **hứng một đòn tấn công**, đúng ngữ nghĩa mà thorns dùng.
- **Số:** đọc **`tgt.st.thorns` thô**, không phải `th` đã nhân. Ở `thornsMult 1` (mọi build không có `r_mirrorshell`) hai bản **cho đúng cùng một con số** — đó là cơ sở của RP 19.48 và của yêu cầu "cùng số" trong audit. Thorns 6 ⇒ heal 2 mỗi đòn × ~4 đòn/lượt = **8 heal/lượt**.
- 🔒 **Đọc thô là chống-stack có cấu trúc, không phải sơ suất.** Nếu đọc `th` sau `thornsMult`, `r_mirrorshell` (`×3`) sẽ **nhân ba lượng hồi máu** của một relic RARE ⇒ RP nhảy ra ngoài dải mà không ai chạm vào `r_bloodthorn`. Cùng nguyên tắc "cộng sau khi nhân" của ENG-4.
- **Event:** `ft` (`'+3'`, class `heal`) + `hp` từ `applyHeal:370-371`.
- **Vì sao tồn tại:** hình dạng AEGIS là "để địch tự sát trên giáp của bạn", nhưng **không gì** chuyển việc đó thành sustain. Payoff phản ứng là câu trả lời trung thực — và nó **không nằm trên trục damage**, đúng khuyến nghị `combo-decision-memo` §3 (trả bằng tài nguyên khác trục để tránh cộng dồn bậc hai).

### `r_glassspine` — Glass Spine · **EPIC** · `a:'thorns'` · 🔧 **ENG-6** · `mload 0` · `ex: ['thornsFloorShield']`

- 🔧 **Đã đổi bậc `1 → 2` theo §6.7.4. Hiệu ứng GIỮ NGUYÊN.** Hai lý do độc lập cùng chỉ về một hướng: (1) RP 23.80 **nằm gọn trong `Band[2]`** = [22.44, 30.36], tức nó **đã là** một EPIC bị dán nhãn RARE — chính xác loại lỗi product owner khiếu nại; (2) sau retune, AEGIS chỉ còn **1 EPIC** ⇒ vi phạm AC-4 (E≥2). Một thay đổi bậc sửa cả hai.
- ✅ **Đề nghị D1 của tài liệu này ĐÃ ĐƯỢC CHẤP NHẬN.** `ex: ['thornsFloorShield']`, tách khỏi `thornsFloorFlat` (`r_spines`, `r_scalecrown`): sàn-có-điều-kiện-4 nằm **trên** sàn-vô-điều-kiện-2/3 và **cả hai cùng đóng góp** ⇒ chúng không dead-draw nhau. Xem §17.5 D1.
- **d:** `'RULE: any Axie you give Shield to has at least Thorns 4.'`
- **Hiệu ứng chính xác:** `onShield` — `ctx.tgt.st.thorns = max(ctx.tgt.st.thorns || 0, 4)`.
- **Field:** `onShield` ctx cần thêm `tgt` — cần **ENG-6** (hôm nay ctx chỉ là `{v, splash}`, `:380`).
- 🔒 **SÀN, không phải cộng dồn — đây là quyết định thiết kế trung tâm của cả nhóm.** `addStatus` **luôn cộng** (`:395`) và thorns **không decay** (sự thật #1 ở trên) ⇒ bất kỳ nguồn thorns cộng dồn nào cũng vô hạn theo số lượt. Một sàn là **idempotent** ⇒ **không thể suy biến**, dù người chơi shield 10 lần/lượt.
- **Số:** sàn 4 (so với `r_spines` 3, Reptile 2, Plant 2). Với `thornsMult 3` ⇒ 12/đòn.
- **Event:** thân relic phải tự gọi `ft(s,ctx.tgt,'THO 4','buf')` **chỉ khi** nó thật sự nâng giá trị lên (phép gán `Math.max` không tự phát event nào).
- **Vì sao tồn tại:** **đây là relic access của AEGIS.** Hôm nay chỉ Reptile có thorns đáng tin; Plant có 2 khi shield ≥10 (`:379`). Relic này cho **bất kỳ class nào có một mặt shield** thorns thật — chính xác là lý do AEGIS chỉ chơi 4/300 run.

### `r_retributor` — Retributor · EPIC · `a:'thorns'` · 🔧 **ENG-5** · `mload 0` · `ex: []`

- **d:** `'RULE: when a shielded Axie Thorns an attacker, the two enemies beside it take a third as much.'`
- 🔧 **Đã thêm điều kiện `tgt.shield > 0` theo §6.7.4.** Bản trước đo **34.00 RP — nằm gọn trong `Band[3]`**, tức một EPIC ở bậc LEGENDARY. Phép đo: `th 4 → d 2` × 2 lân cận × `H = 10` lần bị đánh mỗi trận. Điều kiện Shield cắt tần suất xuống đúng những lượt bạn **đã trả giá** để dựng giáp, mà không đụng tới con số 1/3.
- **Hiệu ứng chính xác:** `onThorns` — **chỉ khi `ctx.tgt.shield > 0`**; `d = ceil(ctx.th/3)`; với mỗi lân cận của `ctx.src` trong `aliveE(s)`: `dealDamage(s, null, x, d, {pierce:1, attack:false})`.
- 🔒 **Kiểm `tgt.shield` tại thời điểm hook chạy — tức SAU khi đòn đánh đã ăn vào shield.** `dealDamage` trừ shield ở `:328`, khối thorns ở `:339-349`, hook ENG-5 gọi sau `EVhp` (`:347`). Nên một đòn **phá sạch** shield sẽ **không** kích relic này ở chính đòn đó. Có chủ đích: nó thưởng cho việc **giữ** giáp, không phải cho việc **có** giáp một lần.
- 🔗 **Cộng hưởng cố ý với `r_glassspine`** (sàn Thorns 4 khi được cấp Shield): hai relic AEGIS cùng key vào "Axie đang có Shield". Điều kiện của `r_retributor` gần như **luôn đúng** trong build có `r_glassspine`, và đó là cách nhóm này tự tạo build thay vì tự chặn.
- **Field:** hook `onThorns` (**ENG-5**) + `dealDamage`/`neighborsOf`/`aliveE` (§3.1).
- **`src=null` là cố ý:** bỏ qua **toàn bộ** block phía nguồn (`:315-322`) ⇒ không FERAL, không `dmgMult`, không `modDmg`, không crit. `attack:false` ⇒ **không** kích thorns đệ quy. `pierce:1` ⇒ ngang bằng đường thorns chính, thứ trừ HP trực tiếp và vốn đã bỏ qua shield (`:343`).
- **Số:** thorns 3 × mult 3 = 9 ⇒ 3 cho mỗi 2 lân cận × 4 đòn/lượt = **+24/lượt rải**. Đã **hạ từ bản nháp `/2`** (§1.3).
- **Event:** `hit` + `hp` (+ `death`) cho mỗi lân cận.
- **Vì sao tồn tại:** cầu AEGIS + TEMPEST, và là **chỗ duy nhất tôi cho phép nâng trần** ở archetype này.

### `r_ironmaiden` — Iron Maiden · LEGENDARY · `a:'thorns'` · `mload 0` · `ex: []`

- **d:** `'RULE: at the start of every turn, the enemy with the most HP takes damage equal to your highest Thorns, up to 7.'`
- 🔧 **THAY ĐỔI PHẠM VI — vi phạm NẶNG NHẤT toàn roster mới** (`relic-system.md` §6.7.4). Bản trước đo **66.50 RP = 155% trần LEGENDARY**. Phép đo: `min(12, thorns) × 4 địch × 5 lượt` = **240 damage danh nghĩa**, bão hoà ở `D = 70` — tức **relic này một mình kết thúc encounter**. Không con số nào cứu được bản cũ: ngay cả cap 1 vẫn là damage lên **mọi** địch **mỗi** lượt, vô điều kiện. Phải đổi **phạm vi**.
- **Hiệu ứng chính xác:** `onTurnStart` — `th = Math.min(IRONMAIDEN_CAP, Math.max(0, …`st.thorns` lớn nhất trong các Axie sống))` với `IRONMAIDEN_CAP = 7`; nếu `th > 0`, **địch sống có `hp` cao nhất** nhận `dealDamage(s, null, e, th, {pierce:1, attack:false})`.
- 🔒 **Một địch, KHÔNG phải mọi địch.** Đây là thay đổi mang toàn bộ trọng lượng: nó cắt hệ số 4-5× (số địch, `CURVE.count(pw)`) và biến relic từ "dọn wave" thành "áp lực đơn mục tiêu bền bỉ".
- 🔒 **Chọn "nhiều HP nhất", không phải "ít HP nhất" — có lý do.** Nhắm địch yếu nhất sẽ **chồng lên** win condition sẵn có của party (thứ vốn đã giết được mục tiêu yếu) và biến relic thành máy dọn xác. Nhắm địch **khoẻ nhất** đặt nó vào đúng chỗ AEGIS thua: những trận kéo dài trước tank/boss. Tie-break: địch **đầu tiên** theo thứ tự `aliveE(s)` ⇒ tất định, không RNG.
- 🔒 **Cap `12 → 7`, và phải là hằng có tên `IRONMAIDEN_CAP` trong `data.js`** — không để số trần trong thân relic. Đây là yêu cầu §17.6 #2 do chính tài liệu này nêu, nay thành bắt buộc. Cap chịu lực vì keyword `thorns:N` trên mặt **có** cộng dồn qua `addStatus` và thorns **không decay**: `reptile3` có `F('back','shield',6,'thorns:4')` ⇒ Thorns 20+ ở lượt 5.
- 🔒 **KHÔNG áp `thornsMult`** ⇒ không cộng dồn với `r_mirrorshell` (`×3`). Cố ý, giữ nguyên từ bản trước.
- **Số:** tối đa **7/lượt lên một mục tiêu** = ~35 damage/trận, thay vì 240. Vẫn là win condition (AEGIS hiện không giết được gì) nhưng không còn thay thế cả party.
- **Event:** `hit` + `hp` (+ `death`) cho **một** địch, mỗi lượt.
- **Vì sao tồn tại:** AEGIS **hiện không giết được gì** — nó là archetype phòng ngự không có win condition, và đó là lý do nó chỉ chơi 4/300 dù winrate 25%. Đây là win condition, nay được định giá đúng bậc.
- ⚠️ **Hệ quả nhịp độ đã biết và chấp nhận:** relic không còn dọn được đám địch yếu, nên AEGIS vẫn cần một nguồn AoE khác (`r_retributor`, hoặc TEMPEST). Đó là **hình dạng đúng**: một LEGENDARY không nên tự nó là toàn bộ win condition của archetype.

### `r_scalecrown` — Scale Crown · LEGENDARY · `a:'thorns'` · 🔧 **ENG-5**

- **d:** `'RULE: every Axie gains the Reptile SCALES passive — always Thorns 2, and your Thorns also apply Poison 1.'`
- **Hiệu ứng chính xác:** `onTurnStart` — mọi Axie sống: `st.thorns = max(st.thorns||0, 2)`. **Và** `onThorns` — nếu `ctx.tgt.cls !== 'reptile'`, `addStatus(s, ctx.src, ['poison:1'])`.
- **Field:** `onTurnStart` (chạy hôm nay) + hook `onThorns` (**ENG-5**).
- **Guard `cls!=='reptile'`:** `dealDamage:344` **đã** làm việc này cho Reptile thật ⇒ không guard sẽ áp poison hai lần cho Reptile.
- 🔒 **Gọi `addStatus` KHÔNG truyền `src`, cố ý.** Truyền `ctx.tgt` làm `src` sẽ bật VIRULENT `+2` của Bug (`:386` kiểm `src.cls==='bug'`) **và** `poisonSpread` (`:388`). Đó là một cú bơm sức mạnh cho poison **qua cửa sau** — và poison là archetype 30% playrate / 16% winrate mà §1.2 nói rõ **không được cộng thêm**. Bỏ `src` ⇒ AEGIS đứng ngoài đường cong sức mạnh của poison. Poison là **bậc hai** (§2.1); đây không phải chi tiết nhỏ.
- **Kiểm tra dead-draw (constraint 6):** giữ cùng `r_spines` (cả party luôn Thorns 3) ⇒ `max(3,2)=3` ⇒ **mệnh đề Thorns 2 của tôi trở nên trơ**. Nhưng **mệnh đề poison là nội dung thật** và không relic nào khác có ⇒ **không phải dead draw**. Ghi rõ ở đây theo yêu cầu constraint 6.
- **Số:** cho **bất kỳ** party thorns 2 nền + Poison 1 mỗi lần phản đòn (~4/lượt, rải trên những địch đã đánh bạn, decay 1/lượt).
- **Event:** `ft` (`'PSN 1'`, class `poi`) từ `addStatus:387`; `ft` cho thorns floor khi nó nâng giá trị.
- **Vì sao tồn tại:** **LEGENDARY access** (§1.3) — thay cho bản nháp `r_thornedcrown` vốn là cú nâng trần thứ hai. Nó làm sâu bản sắc Reptile bằng cách **xuất khẩu** nó (constraint 9), và là relic duy nhất cho thorns cho một party **không có Reptile nào và không có mặt shield nào**.

### `a_bramblewall` — Bramble Wall · RARE · `a:'thorns'` · 🔧 **ENG-10** · `mload 0` · `ex: []`

- **d:** `'[MP 3] Every Axie Thorns become at least 5.'`
- **act:** `{cost:3, kind:'kw', mode:'min', kw:'thorns:5', scope:'party', tgt:'self'}` — `kind:'kw'` là **mới** (ENG-10).
- 🔧 **Đã hạ `thorns:6 → thorns:5` theo §6.7.4.** Bản trước đo **27.25 RP — nằm gọn trong `Band[2]`**, tức một RARE ở bậc EPIC. Phép đo: nâng Thorns từ nền ~2 lên 6 là `+4 × H × κ_def`. Giữ `mode:'min'` **không đổi** — ngữ nghĩa sàn là điều kiện tồn tại của thẻ này, không phải một tuning knob.
- 🔒 **Ngữ nghĩa "sàn" là toàn bộ lý do relic này tồn tại được.** Active dùng lại **mỗi lượt** (§4.3 #1). Một active `thorns +6/lượt` sẽ đạt Thorns 18 ở lượt 3, × `thornsMult 3` = **54 mỗi đòn**, và vì thorns không decay thì nó **không có trần**. Sàn thì **idempotent**: bấm lại không làm gì thêm.
- **Số:** cho một party không-Reptile thorns thật **ngay lượt 1** với MP3, một lần; sau đó là thẻ chết đến khi thorns tụt xuống. Active **setup**, giá trị dồn về đầu.
- **Event:** `ft` (`'THO 6'`, class `buf`) cho mỗi Axie mà nó thật sự nâng.
- **Vì sao tồn tại:** cửa vào — AEGIS trên bất kỳ class nào, ngay lượt đầu, không cần chờ rút relic passive.

## 9. EXEC — FERAL (5 passive + 1 active)

> `exec` là archetype của **Beast** (`PASSIVE.beast.a === 'exec'`) và hôm nay nó **không tồn tại trong
> `ARCH`** ⇒ Beast là class duy nhất không có archetype nào được track, và 2 relic `a:'exec'` hiện có bị
> `archScore:883` bỏ qua lặng lẽ. Toàn nhóm này giả định **A1**.
> Cơ chế: `lowHp = tgt.hp < tgt.maxHp*0.5`; `if(lowHp && (src.cls==='beast'||o.exec)) v=ceil(v*1.6)` (`:316-317`).
> Keyword `exec` bật `o.exec`, và `exec` **nằm trong danh sách loại trừ `kwPure`** (`:489`) ⇒ mọi phép
> inject `exec` đều an toàn hướng với mọi loại mặt.

### `r_gorehook` — Gorehook · COMMON · `a:'exec'`

- **d:** `'RULE: every Horn and Tail damage face gains Execute.'`
- **Hiệu ứng chính xác:** `modFace` inject `exec` vào mọi mặt `t==='dmg'` có `p==='horn'` hoặc `p==='tail'`, chưa có `exec`.
- **Field:** `modFace` — **chạy hôm nay**.
- **Kiểm tra trùng:** `r_pierceall` chiếm Horn với `pierce`, `r_cleaveall` chiếm Tail với `cleave` — **keyword khác nhau**, cộng dồn tốt, không trùng luật.
- **Số:** ~2 lần dùng horn/tail dmg/lượt; `exec` = `×1.6` khi mục tiêu <50% HP (~30-35% số đòn) ⇒ **≈+10%** tổng. Đúng neo COMMON.
- **Event:** giá trị `hit` lớn hơn; không cần event mới.
- **Vì sao tồn tại:** exec/FERAL không có COMMON ⇒ archetype của Beast không có cửa vào sớm nào (§1.1).

### `r_scentofblood` — Scent of Blood · RARE · `a:'exec'`

- **d:** `'RULE: enemies below half HP take 4 more damage from every attack.'`
- **Hiệu ứng chính xác:** `modDmg` — `ctx.tgt.hp < ctx.tgt.maxHp*0.5 ? ctx.v+4 : ctx.v`.
- **Field:** `modDmg` — **chạy hôm nay** (không cần ENG-1: chỉ đọc `tgt`, không cần biết đòn có pierce/exec).
- 🔒 **Thứ tự pipeline có lợi và cố ý:** FERAL `×1.6` ở `:317`, `dmgMult` ở `:319`, **rồi** `modDmg` ở `:320`. Nên `+4` được cộng **sau** mọi multiplier ⇒ nó **phẳng, không cộng dồn** với `r_bloodpact` (`×1.6`) hay `r_ancientgene`.
- **Số:** `+4` trên ~30-40% số đòn ≈ `+1.5`/đòn × 4 đòn = **+6/lượt ≈ +15-20%**.
- **Event:** giá trị `hit` lớn hơn.
- **Vì sao tồn tại:** payoff của exec là một **multiplier**, và multiplier không giúp gì khi bạn **không kết thúc được**. Một số cộng phẳng có giá trị tương đối lớn hơn trên các đòn nhỏ — đúng bài toán "gọt 20% HP cuối" mà FERAL đang thua.

### `r_cullingorder` — Culling Order · **EPIC** · `a:'exec'` · `mload 0` · `ex: []`

- **d:** `'RULE: whenever an enemy dies, your most wounded Axie heals 4 and gains 4 Shield.'`
- 🔧 **THAY ĐỔI PHẠM VI + BẬC — vi phạm nặng thứ hai toàn roster** (`relic-system.md` §6.7.5). Bản trước đo **96.50 RP = 5.2× trần RARE**. Phép đo: `4.5 kill × 5 Axie × (3 heal + 3 shield)` = **67 heal + 67 shield mỗi trận**, trong khi tổng damage địch gây ra cả trận là `T_in = 70`. **Relic này một mình vô hiệu hoá sát thương của encounter.** Đối chiếu `r_regrow` trong bản trước (~50/trận) **sai** vì nó bỏ qua hệ số 5 Axie.
- **Hiệu ứng chính xác:** `onKill` — chọn **một** Axie: trong các Axie sống **không phải token**, lấy cái có `hp` nhỏ nhất; áp `applyHeal(s,u,4)` rồi `applyShield(s,u,4)`.
- 🔒 **Một Axie, KHÔNG phải mọi Axie.** Đây là phần cắt thật (÷5). Con số `3 → 4` là phần **bù lại** để relic đạt đích EPIC 26.40 sau khi cắt — nó **không** phải một buff.
- 🔒 **Tie-break tất định:** `hp` nhỏ nhất; hoà thì lấy cái đứng trước trong `s.party`. `Array.prototype.sort` ổn định trong JS hiện đại và `s.party` có thứ tự cố định ⇒ **không RNG, replay an toàn** ✅. Chọn theo `hp` thuần (không phải `hp+shield`) khác có chủ đích với `r_lastwall`: ở đây ta muốn **hồi máu** cho cái sắp chết, không phải cứu cái sắp vỡ giáp.
- 🔒 **Loại token khỏi lựa chọn.** Egg có `maxHp` 4-10 nên gần như **luôn** là unit ít HP nhất ⇒ không loại thì relic sẽ dồn toàn bộ giá trị vào token và trở nên vô hình. Cùng quy ước với `r_lastwall`.
- 🔧 **Đổi bậc `1 → 2`:** RP sau khi sửa là 25.70, nằm trong `Band[2]`; và FERAL chỉ có **1 EPIC** ⇒ vi phạm AC-4. Một thay đổi sửa cả hai.
- **Field:** `onKill` + `applyHeal`/`applyShield`/`aliveP` — **chạy hôm nay** (§3.1).
- **Số:** mỗi kill = 4 heal + 4 shield (Plant nhận 6 shield nhờ BULWARK `:376`) lên **một** Axie. 4-5 kill/trận ⇒ ~18 heal + 18 shield/trận, **dồn về các lượt có kill**.
- **Event:** `ft` (`heal`) + `ft` (`shd`) + `hp` cho **một** Axie.
- **Vì sao tồn tại:** FERAL là glass cannon (Beast 12/18/26 HP — thấp nhất cùng Bird) và thất bại thật của nó là **chết**, không phải thiếu damage. "Giết để sống" làm sâu fantasy Beast và trả bằng **tài nguyên khác trục** (`combo-decision-memo` §3). Việc nó dồn vào **một** Axie cũng làm cơ chế **đọc được**: người chơi thấy rõ ai được cứu.
- ⚠️ Cộng hưởng với `r_holyfont` (`healShield`): `applyHeal 4` tự sinh 4 shield (`:372`) *rồi* `applyShield 4` ⇒ 8-10 shield/kill trên một Axie. Nhẹ, có chủ đích, ghi ở §17.4.

### `r_deathspiral` — Death Spiral · EPIC · `a:'exec'` · `mload 0` · `ex: []`

- **d:** `'RULE: the first time each enemy drops below half HP, it takes 7 damage immediately.'`
- 🔧 **Đã hạ `12 → 7` theo §6.7.5.** Bản trước đo **45.60 RP — TRÊN trần LEGENDARY** (42.97), tức một EPIC vượt cả bậc cao nhất. Phép đo: `12 × 4 địch × κ_choice`. Bản trước ước lượng "60/trận ≈ 15% tổng HP encounter" và **đánh giá thấp** vì bỏ qua `κ_choice` — damage này đến **đúng lúc** mục tiêu sắp chết, nên mỗi điểm đáng giá hơn damage rải.
- **Hiệu ứng chính xác:** `onHit` — nếu `tgt.hp>0` và `tgt.hp < tgt.maxHp*0.5` và cờ `tgt.spiraled` chưa set: set cờ, rồi `dealDamage(s, null, tgt, 7, {pierce:1, attack:false})`.
- **Field:** `onHit` + `dealDamage` — **chạy hôm nay** (§3.1).
- 🔒 **`src=null` chặn đệ quy vô hạn:** block `onHit` trong `dealDamage` (`:351`) yêu cầu `src && src.side==='p'` ⇒ đòn `src=null` **không** kích lại `onHit` ⇒ không có vòng lặp. Đây là lý do tôi dùng `null` chứ không dùng Axie nào.
- **Một lần / mỗi địch / mỗi trận:** cờ nằm trên unit địch; `enemies` nằm trong `SNAP` (`:547`) và `snap()` dùng `clone()` ⇒ **undo khôi phục đúng cờ** ✅.
- **Số:** 7 pierce/địch/trận × 5 địch = **35/trận** danh nghĩa, nhưng mỗi điểm rơi đúng vào cửa sổ mục tiêu sắp chết.
- **Event:** `hit` + `hp` (+ `death`).
- **Vì sao tồn tại:** cảm giác "kết thúc" — và quan trọng hơn, nó **dạy** người chơi ngưỡng 50% có ý nghĩa. Hôm nay ngưỡng đó **hoàn toàn vô hình**: FERAL và `exec` đều key vào nó nhưng không gì báo cho người chơi biết khi nào nó được vượt qua.
- **Tuning knob:** `7` là số phẳng (theo quy ước sẵn có: `r_chainreact` explode 8, `r_hollowbone` +4). Nó yếu dần ở late `pw`. Nếu cần scale, đề nghị `ceil(0.07 × CURVE.budget(s.pw))` — nhưng chỉ sau khi sim, và **phải chạy lại `tools/t_relic.mjs`** vì scale theo `pw` đổi RP của relic ở mọi power level.

### `r_apexferal` — Apex Feral · LEGENDARY · `a:'exec'` · `mfPhase:'kw'` · `mload 0` · `ex: []`

- **d:** `'RULE: every damage face gains Execute, and any enemy left at 15% HP or less dies immediately.'`
- 🔧 **Đã nâng ngưỡng xử tử `10% → 15%` theo §6.7.5.** Bản trước đo **31.73 RP — thiếu đúng 0.03 RP** so với sàn LEGENDARY 31.76. `relic-system.md` gọi đây là **ca sách giáo khoa cho INV-3**: một relic có thể "đúng cảm giác" mà vẫn nằm ngoài dải, và chỉ một phép đo mới thấy. Không thay đổi nào khác — mệnh đề `exec` toàn cục giữ nguyên.
- **Hiệu ứng chính xác:** `modFace` inject `exec` vào mọi mặt `t==='dmg'`; **và** `onHit` — nếu `tgt.hp>0 && tgt.hp <= ceil(tgt.maxHp*0.15)` ⇒ `dealDamage(s, null, tgt, tgt.hp, {pierce:1, attack:false})`.
- **Field:** `modFace` + `onHit` + `dealDamage` — **chạy hôm nay** (§3.1). `src=null` chặn đệ quy như `r_deathspiral`.
- **Số:** `×1.6` trên ~35% số đòn ⇒ **≈+21%** tổng damage; cộng việc dọn sạch phần "còn 1 HP" — vốn là damage bị lãng phí thật (overkill bị bỏ, xem `combo-decision-memo` §2 điều kiện mô hình).
- **Event:** `hit` + `hp` + `death`.
- **Vì sao tồn tại:** hoàn thiện họ LEGENDARY đối xứng: `r_stormcall` (mọi mặt dmg nhận **Cleave**) · `r_worldpiercer` (nhận **Pierce**) · `r_apexferal` (nhận **Execute**). Ba trục, một khuôn, không trùng luật. Và nó **xuất khẩu bản sắc Beast** cho cả party (constraint 9).

### `a_coupdegrace` — Coup de Grâce · EPIC · `a:'exec'` · 🔧 **ENG-14** · `mload 0` · `ex: []`

- **d:** `'[MP 5] Deal 14 damage to one enemy, executing.'`
- **act:** `{cost:5, kind:'dmg', v:14, exec:1, tgt:'enemy'}` — cần **ENG-14** (truyền `exec:a.exec` vào `dealDamage`; hôm nay nhánh `dmg` chỉ truyền `{pierce:a.pierce, attack:true}`).
- 🔧 **Đã hạ `v: 22 → 14` theo §6.7.5.** Bản trước đo **36.25 RP — nằm gọn trong `Band[3]`**, tức một EPIC ở bậc LEGENDARY. Nguyên nhân là **tần suất, không phải giá trị đơn lẻ**: với `N* = 3` (số lần dùng khả thi mỗi trận ở MP 5), 22 damage × 3 lần đã vượt ngân sách. Đây là một trong 5 active bị định giá sai vì giả định "1 lần/trận" lọt vào bản trước — xem §4.3 #1.
- **Số:** 14 nền; **23** khi mục tiêu <50% HP (`ceil(14×1.6)`).
- **Tam giác intransitive giữa 3 active đơn mục tiêu:** `a_chomp` (MP3, 12 pierce — đáng tin cậy) · `a_pinning` (MP3, 6-20 — thắng địch có Shield) · `a_coupdegrace` (MP5, 14-23 — thắng địch đã bị thương). Không cái nào trội hoàn toàn. Tam giác **vẫn đứng** sau khi hạ số: `a_coupdegrace` vẫn là đòn đơn mục tiêu mạnh nhất **khi điều kiện của nó đúng**.
- **Event:** `hit` + `hp` (+ `death`).
- ⚠️ **Hai cạm bẫy chung của mọi active damage:** (1) `attack:true` ⇒ **kích Thorns địch**, và Thorns phản vào `aliveP(s)[0]` chứ không phải Axie bạn chọn; (2) **không thể crit** (§4.3 bổ chính).
- **Vì sao tồn tại:** exec có **0** active. Và đây là active duy nhất scale theo **trạng thái bạn vừa tạo ra**, thay vì một con số cố định.

## 10. POISON — PLAGUE (3 passive) · **+2 entry bắt buộc từ audit**

> Đo được: **90 run/300 (30% — phễu rộng nhất game)**, winrate **16% (dưới baseline 20%)**, 5 relic.
> ⇒ PLAGUE **hút người chơi rồi làm họ thua**. §1.2 nói rõ: **không thêm sức mạnh vào đây.**
> Poison là **bậc hai** (§2.1: cộng 2 stack vào stack `v` làm tổng tăng `2v+3`) nên "chỉ thêm một
> chút stack" không tồn tại như một lựa chọn.
>
> 🔧 **Nhóm này đi từ 1 lên 3 entry theo `relic-system.md` §6.7.7.** Bản trước dừng ở **1 relic** và
> đề nghị (D4) lấp slot COMMON/RARE của PLAGUE bằng cách **retag một relic sẵn có**. Audit đã **bác
> đề nghị đó bằng phép đo**: sau retune 44 relic, **không relic nào vừa hợp bậc vừa có cơ chế đọc
> được là poison** để chuyển sang, và **Superlinear Axis Law** (`relic-system.md` §4.6.5) chặn **mọi**
> scaler poison ở dưới EPIC — tức không thể tạo một relic poison COMMON/RARE bằng cách nhân bất cứ
> thứ gì. PLAGUE vì vậy nhận đúng 2 entry mới.
>
> 🔒 **Cả hai entry mới tuân thủ ràng buộc gốc của §1.2/§1.3.** `r_rotbite` là **damage amp**, không
> tạo stack — cùng khuôn với `r_tinderbox` của INFERNO. `r_rotmouth` **có** áp stack, nhưng
> `poison:2` trên một part duy nhất là mức thấp nhất diễn đạt được một RARE poison, và nó thay thế
> việc phải nâng trần đơn-mục-tiêu ở EPIC/LEGENDARY. Trần của PLAGUE **không đổi**.

### `r_pandemic` — Pandemic · EPIC · `a:'poison'`

- **d:** `'RULE: when a poisoned enemy dies, every other enemy gains half its Poison.'`
- **Hiệu ứng chính xác:** `onKill` — `p = floor(ctx.tgt.st.poison / 2)`; nếu `p>0`, mỗi địch sống khác nhận `addStatus(s, x, ['poison:'+p])`.
- **Field:** `onKill` + `addStatus`/`aliveE` — **chạy hôm nay** (§3.1).
- 🔒 **Gọi `addStatus` KHÔNG truyền `src`, cố ý.** Không `src` ⇒ **không** VIRULENT `+2` của Bug (`:386`), **không** `poisonSpread` của `r_plaguelord` (`:388`). ⇒ Relic này **không thể** sinh thêm stack nào ngoài phần chia lại. Đó chính là định nghĩa "lateral" ở §1.3, và nó là điều kiện để relic này được phép tồn tại.
- **Số:** thuần phân phối lại. Giết địch yếu nhất đang mang 8 stack ⇒ 4 stack lên mọi địch còn lại. Trần đơn-mục-tiêu của PLAGUE **không đổi**.
- **Event:** `ft` (`'PSN N'`, class `poi`) × số địch, từ `addStatus:387`.
- **Kiểm tra trùng với `r_plaguelord`:** `poisonSpread` lan khi **áp poison**, sang **lân cận**, ở nửa giá trị (`:388-391`). Relic này lan khi **chết**, sang **toàn bộ**, ở nửa stack tồn. **Trigger khác, phạm vi khác** ⇒ không trùng luật. Chúng cộng hưởng — ghi ở §17.
- **Vì sao tồn tại:** điểm yếu đo được của PLAGUE không phải trần đơn mục tiêu (cái đó ổn) mà là **poison phải được áp 5 lần** khi `CURVE.count(pw)` đã lên 5-6 địch. Relic này vá đúng chỗ đó **mà không nâng trần và không thêm stack** — loại relic poison duy nhất mà §1.2 cho phép.

### `r_rotbite` — Rot Bite · **COMMON** · `a:'poison'` · 🆕 **ENTRY MỚI** · `mload 0` · `ex: ['poisonAmpFlat']`

- **d:** `'RULE: poisoned enemies take 2 more damage from every attack.'`
- 🆕 **Entry mới bắt buộc, `relic-system.md` §6.7.7.** PLAGUE **không có COMMON nào** ⇒ theo §1.1 archetype có playrate lớn nhất game (30%) **không thể khởi động trước power-level 7**. Đây là on-ramp đó.
- **Hiệu ứng chính xác:** `modDmg` — `ctx.tgt.st.poison > 0 ? ctx.v + 2 : ctx.v`.
- **Field:** `modDmg` — **chạy hôm nay, 0 engine work**. Chỉ đọc `tgt.st`, không cần ENG-1.
- 🔒 **Cố ý KHÔNG tạo một stack poison nào.** Đây là điều kiện để một relic poison mới được phép tồn tại (§1.2, §17.3). Nó tấn công điểm yếu của PLAGUE **từ ngoài** đường cong bậc hai: poison đã trả giá rồi, relic này làm nó **đáng giá hơn** thay vì **nhiều hơn**.
- 🔒 **Thứ tự pipeline có lợi:** `modDmg` chạy ở `:320`, **sau** `dmgMult` (`:319`) ⇒ `+2` là **phẳng, không nhân** với `r_bloodpact`/`r_ancientgene`. Cùng cấu trúc chống-stack với `r_scentofblood` và `r_tinderbox`.
- 🔒 **`ex: ['poisonAmpFlat']` — tách khỏi `r_openwound`.** `r_openwound` (sẵn có) cho `+30%` **phần trăm**; relic này cho `+2` **phẳng** ⇒ **không trùng luật**, giữ cả hai được. Đây đúng lập luận §11 đã dùng cho cặp `r_tinderbox` vs `r_openwound`. Nhưng hai relic **phải mang token khác nhau** (`poisonAmpFlat` vs `poisonAmpPct`) để một relic amp poison thứ ba trong tương lai không bị gộp nhầm vào cùng một nhóm.
- **Số:** `+2` trên các đòn vào mục tiêu đang nhiễm ≈ **+6/lượt** khi poison đã lên. RP 13.79, đích COMMON 13.20 (Δaim 0.59).
- **Event:** giá trị `hit` lớn hơn; không cần event mới.
- **Vì sao tồn tại:** chẩn đoán §10 nói điểm yếu thật của PLAGUE là **phải áp poison 5 lần** khi `CURVE.count(pw)` đã lên 5-6 địch. Một damage amp giúp những đòn **không** phải poison cũng đóng góp vào cùng một kế hoạch, nên nó rút ngắn đúng cái đuôi dài đó — ở tầng rẻ nhất.

### `r_rotmouth` — Rotmouth · **RARE** · `a:'poison'` · 🆕 **ENTRY MỚI** · `mfPhase:'kw'` · `mload 0` · `ex: []`

- **d:** `'RULE: every Mouth damage face also applies Poison 2.'`
- 🆕 **Entry mới bắt buộc, `relic-system.md` §6.7.7.** PLAGUE chỉ có **1 RARE** ⇒ vi phạm AC-4 (R≥2).
- **Hiệu ứng chính xác:** `modFace` inject `poison:2` vào mọi mặt `t==='dmg'` có `p==='mouth'` và **chưa** có `poison`.
- **Field:** `modFace` (`f.k`) — **chạy hôm nay**. `mfPhase:'kw'`.
- 🔒 **kwPure Direction Law — an toàn, và đã kiểm đúng cả hai bẫy:**
  1. mặt `t==='dmg'` ⇒ `kwPure` đi tới **địch** qua `hit()` (`engine.js:494`) ⇒ đúng hướng. Tiêm `poison` vào mặt `shield`/`heal` sẽ **đầu độc chính Axie của bạn**;
  2. guard `t==='dmg'` cũng tránh bẫy §7 E3: nhánh `f.t==='poison'` của `doFace` (`:510-514`) **không bao giờ truyền `kwPure`** ⇒ keyword tiêm vào mặt type `poison` là **trơ hoàn toàn**. Mouth **có** cả mặt `dmg` lẫn mặt `poison` trong `FACE_POOL`, nên guard này là bắt buộc, không phải phòng xa.
- ⚠️ **`src` ĐƯỢC truyền, khác `r_pandemic`/`r_scalecrown` — và đó là cố ý.** Vì poison áp qua `hit()`, `addStatus` nhận `src` ⇒ **VIRULENT của Bug `+2` (`:386`) CÓ áp dụng**, và `poisonSpread` của `r_plaguelord` (`:388`) cũng vậy. `relic-system.md` §6.7.7 đã định giá đúng trường hợp xấu nhất đó: `RP_class = 19.50 × 1.35 = 26.3 = 1.41× band`, **dưới trần class 2.2** ✓. Đây là khác biệt có chủ đích: một relic *cấp* poison qua mặt đánh **nên** ăn passive class; một relic *phân phối lại* poison (`r_pandemic`) thì **không**.
- **Số:** `p(mouth ∧ dmg) = 0.278` — slot damage rộng nhất game ⇒ ~1.5 lần dùng/lượt × `poison:2`. RP 19.50, đích RARE 18.68 (Δaim 0.82).
- **Event:** `ft` (`'PSN 2'`, class `poi`) từ `addStatus:387`, mỗi đòn mouth.
- **Kiểm tra trùng luật:** `r_windlash` (TEMPEST) cũng chiếm **Mouth**, nhưng tiêm `cleave` — **keyword khác** ⇒ cộng dồn thật, không trùng. Cặp `r_rotmouth` + `r_windlash` cho mouth vừa lan vừa nhiễm; splash **cũng** mang `kwPure` qua `hit()` ⇒ poison lan theo cleave. Ghi ở §17.4.

## 11. BURN — INFERNO (2 passive + 1 active)

> Đo được: 29 run/300 (10%), winrate **10% — một nửa baseline**, 4 relic. **Yếu thật.**
> Chẩn đoán đầy đủ ở **§3.5**: luật halving tự huỷ khả năng tích luỹ của burn (`r_ember` **plateau ở
> ~4 damage/lượt/mục tiêu, mãi mãi**), và **không có gì giữa RARE và LEGENDARY** vì `burnMult` chỉ
> tồn tại trên đúng một relic LEGENDARY. Toàn bộ tính khả thi của archetype treo vào việc rút được
> `r_wildfire`.
> ⇒ Cả 2 passive dưới đây **cố ý không cấp thêm stack** — halving sẽ ăn hết. Chúng tấn công từ ngoài luật decay.
>
> 🔧 **Sau audit:** `r_tinderbox` **giữ COMMON** (chỉ thị đổi bậc của §6.7.6 đã bị huỷ — xem entry);
> `r_hearthcore` nhận `burnTickRatio 0.7` (bản `×2` sạch đo 40.00 RP, và nhân dồn với `r_solarcore`
> thành `×4` — một cặp compounding tài liệu này **không phát hiện**); `a_pyre` lên EPIC ở MP 7.
> INFERNO chốt ở **C 1 · R 2 · E 2 · L 1 · active 1** trên toàn bộ 94 relic.

### `r_tinderbox` — Tinderbox · **COMMON** · `a:'burn'` · `mload 0` · `ex: ['burnAmpFlat']`

- **d:** `'RULE: enemies with Burn take 2 more damage from every attack.'`
- ✅ **PASS INV-1 nguyên trạng** (RP 13.79, `Band[0]` = [11.22, 15.18], đích COMMON 13.20).
- ⚠️ **Chỉ thị "lên RARE, `+2 → +3`" của §6.7.6 ĐÃ BỊ HUỶ — relic giữ nguyên COMMON `+2`.** Lý do là một hệ quả dây chuyền, không phải đảo ý kiến. `r_wildfire` bị phát hiện vi phạm **AC-9** (`mload > 0 ⇒ rar ≥ 1`) khi đứng ở COMMON, và `burnSlow` **thật sự là `mload 1`**: nó đổi burn từ `≈2B` sang `B(B+1)/2` — biến burn thành bậc hai. ⇒ `r_wildfire` **buộc phải** lên RARE, và RARE là **bậc thấp nhất nó có thể chiếm**, do `mload` và mô hình dải cùng quyết định chứ không phải do ai chọn. Việc đó để lại cho INFERNO một chỗ trống **COMMON `mload 0`** — và `r_tinderbox` là relic lấp đúng chỗ đó.
- 🔒 **Đây là ví dụ sạch của việc AC-4 và AC-9 tương tác.** §6.7.6 chuyển `r_tinderbox` lên RARE vì tin rằng `r_wildfire` sẽ **xuống** COMMON. Khi AC-9 đẩy `r_wildfire` theo hướng **ngược lại**, tiền đề của chỉ thị biến mất và chỉ thị tự huỷ. Không có con số nào của `r_tinderbox` sai — chỉ có giả định về hàng xóm của nó.
- **Hiệu ứng chính xác:** `modDmg` — `ctx.tgt.st.burn > 0 ? ctx.v+2 : ctx.v`.
- **Field:** `modDmg` — **chạy hôm nay**, field LIVE trong `src/engine.js:320` ⇒ thoả **INV-9**.
- **Số:** `+2` trên các đòn vào mục tiêu đang cháy ≈ **+6/lượt** khi burn đã lên ≈ +12%. Đúng neo COMMON.
- ✅ **INFERNO chốt ở C 1 · R 2 · E 2 · L 1 · active 1.** `r_tinderbox` giữ vai trò **on-ramp COMMON** mà §1.1 yêu cầu — đúng vai trò tài liệu này thiết kế cho nó ngay từ đầu.
- **Event:** giá trị `hit` lớn hơn.
- **Kiểm tra trùng với `r_openwound`** (RULE: mục tiêu có Poison nhận +30% damage): **status khác** (burn vs poison), **phẳng vs phần trăm** ⇒ không trùng luật. Giữ cả hai là một build "hai status, một trục amp" hợp lý.
- **Vì sao tồn tại:** burn không có COMMON. Và theo §3.5, damage của chính burn plateau ở ~4/lượt ⇒ một **damage amp** làm việc *áp* burn trở nên đáng giá **dù bản thân burn nhỏ**. Nó tấn công điểm yếu đã chẩn đoán **từ bên ngoài luật decay**, nên không bị halving ăn.

### `r_hearthcore` — Hearthcore · EPIC · `a:'burn'` · 🔧 **ENG-7** · `mload 1` · `ex: ['burnTicks']`

- **d:** `'RULE: Burn deals its damage twice per turn; the second tick deals 70%.'`
- 🔧 **Đã thêm `burnTickRatio: 0.7` theo §6.7.6.** Hai lỗi độc lập: (1) bản trước đo **40.00 RP — nằm gọn trong `Band[3]`**, tức một EPIC ở bậc LEGENDARY; (2) **cặp compounding tài liệu này không phát hiện** — nó nhân dồn với `r_solarcore` (`burnMult:2`) thành **×4 output burn**. Tick thứ hai ở 70% hạ cả hai: `×1.7` thay vì `×2`, và cặp với `r_solarcore` thành `×3.4` thay vì `×4`.
- **Hiệu ứng chính xác:** `burnTicks:2` + `burnTickRatio:0.7` — trong `tickStatus`, nhánh burn của địch chạy `rmax(s,'burnTicks',1)` lần; tick thứ `i ≥ 2` gây `ceil(damage × rmax(s,'burnTickRatio',1))`.
- 🔒 **Cặp `r_hearthcore` + `r_solarcore` được PHÉP tồn tại, và `mload` là thứ giữ nó lại.** `mload` 1+1 = **2 = hết trần** ⇒ build đó **không thể** thêm `r_pyroclasm` hay bất kỳ multiplier nào khác. `×3.4` là trần cứng của INFERNO, không phải điểm khởi đầu của một chuỗi.
- **Field:** `burnTicks` (`rmax`) — cần **ENG-7**. **Đối xứng chính xác** với `poisonTicks` của poison (`tickStatus:641`, cũng `rmax`) ⇒ không phát minh khái niệm mới, chỉ vá một chỗ bất đối xứng.
- 🔒 **Chỉ áp cho địch**, ngang bằng `burnMult` (`:653` đã có kiểm `u.side==='e'`) ⇒ không bao giờ nhân đôi burn trên Axie của bạn.
- 🔒 **Chống stack:** `rmax` ⇒ không tự cộng dồn. Và khác relic cấp-stack, nó **không** cộng dồn bậc hai với `r_wildfire` — nó là một `×2` sạch trên bất kỳ base nào.
- **Số:** `×2` output burn. `r_ember` plateau 4/lượt ⇒ **8/lượt**. Với `r_wildfire` (`burnSlow`, làm burn thành bậc hai) thì là `×2` trên một base lớn hơn nhiều.
- **Event:** **hai** event `hit`/`hp` cho mỗi mục tiêu đang cháy mỗi lượt (thay vì một) ⇒ dễ thấy hơn, và nó làm rõ với người chơi rằng relic đang hoạt động.
- **Vì sao tồn tại:** **đây là bản vá cho lỗi đã chẩn đoán ở §3.5.** Nó lấp đúng khoảng trống RARE→LEGENDARY, và nó nhân **output** chứ không cộng **stack**, nên luật halving không thể ăn nó. Nếu chỉ được sửa INFERNO bằng một relic, đây là relic đó.

### `a_pyre` — Pyre Bloom · **EPIC** · `a:'burn'` · 🔧 **ENG-10** · `mload 0` · `ex: []`

- **d:** `'[MP 7] Apply Burn 6 to every enemy.'`
- **act:** `{cost:7, kind:'kw', mode:'add', kw:'burn:6', scope:'allEnemies', tgt:'self'}` — `kind:'kw'` là **mới** (ENG-10).
- 🔧 **Đã nâng `cost: 4 → 7` và bậc `1 → 2` theo §6.7.6.** Bản trước đo **43.00 RP — TRÊN trần LEGENDARY**, từ một thẻ dán nhãn RARE. **Giá trị mỗi lần dùng không đổi; cái sai là số lần dùng.** Ở MP 4, `N* = 3` (ba lần mỗi trận); ở MP 7, `N* = 2`. Đó là toàn bộ thay đổi — Burn 6 vẫn là Burn 6.
- ❌ **Lập luận định giá cũ đã SAI và được ghi lại làm bằng chứng.** Bản trước so `a_pyre` (MP4) với `a_plague` (MP4, EPIC) và kết luận "yếu hơn nhiều ⇒ RARE là đúng tier". Phép so đó **đúng về damage đơn lẻ nhưng bỏ qua tần suất**: cả hai đều lặp **mỗi lượt** (§4.3 #1), nên "yếu hơn mỗi lần dùng" không hạ được bậc khi số lần dùng bằng nhau. Đây là ví dụ rõ nhất trong tài liệu này của giả định "1 lần/trận" lọt vào một phép so sánh nghe hợp lý.
- **Số & định giá:** Burn 6 ⇒ ≈**12** damage mỗi địch theo halving mặc định (§3.5) × 5 địch = **60/lần dùng**, `N* = 2` ⇒ 120/trận. Với `r_hearthcore`/`r_wildfire` con số này lớn hơn nhiều — nhưng đó là giá trị của **relic kia**, không phải của active.
- **Lặp mỗi lượt:** ở MP 7, thu nhập mana không CONDUIT (2-4/lượt) chỉ đủ dùng cách lượt ⇒ nó thành **mana sink thật**, đúng vai trò EPIC.
- **Event:** `ft` (`'BUR6'`, class `deb`) × số địch, rồi `hit`/`hp` mỗi lượt khi tick.
- **Vì sao tồn tại:** burn có **0** active, và đây là cách duy nhất gieo burn lên cả wave mà không phải rút được đúng mặt `aoe`+`burn` trong `FACE_POOL`.

## 12. SHIELD — BULWARK (1 passive + 1 active)

> Đo được: 59 run/300 (20%), winrate **31%** (khoẻ), 6 relic — chỉ thiếu 1 slot RARE.
> ⇒ Chỉ lấp slot, **không nâng sức mạnh**. Cả hai entry dưới đây đã bị tôi hạ xuống có ý thức.

### `r_lastwall` — Last Wall · **COMMON** · `a:'shield'` · `mload 0` · `ex: ['undyingGrant']`

- 🔧 **Đã đổi bậc `1 → 0` theo §6.7.6. Hiệu ứng GIỮ NGUYÊN.** RP 12.75 **nằm trong `Band[0]`** = [11.22, 15.18], dưới sàn RARE 15.88. Phép đo: một cứu mạng mỗi lượt ≈ **0.6 cái chết thật sự chặn được mỗi trận** — phần lớn các lượt, Axie yếu nhất không bị đánh chết. Audit **không** buff nó lên RARE, có lý do ghi rõ: `relic-system.md` §3.10 kết luận 1 cấm biến "fix phủ bậc" thành buff, và BULWARK đã ở **31% winrate**.
- ✅ **Nó vẫn là relic duy nhất trong game cấp `undying`** (§3.3) — giá trị "mở khoá một cơ chế chết" không đổi khi bậc đổi. Ở COMMON nó còn **dễ gặp hơn**, tức cơ chế `undying` xuất hiện trong nhiều run hơn. Đó là kết quả tốt hơn cho một cơ chế có sẵn cả float text mà **0 content** kích hoạt.
- **d:** `'RULE: at the start of every turn, your most endangered Axie survives its next killing blow with 1 HP.'`
- **Hiệu ứng chính xác:** `onTurnStart` — trong các Axie sống **không phải token**, chọn cái có `hp+shield` nhỏ nhất, set `st.undying = 1` (nếu chưa có).
- **Field:** `onTurnStart` + `ft` — **chạy hôm nay** (§3.1).
- 🎯 **Relic này kích hoạt một cơ chế đã chết (§3.3).** `undying` được implement đầy đủ: `addStatus:399` set nó, `dealDamage:330` tiêu thụ nó và **đã có sẵn float text `'UNDYING'`**. Grep toàn repo: **không** face, monster, boss, event hay relic nào cấp `undying`. Một cơ chế hoàn chỉnh, có cả feedback hình ảnh, với **0 content**. Đây là content đó.
- **Determinism:** `Array.prototype.sort` là **stable** trong JS hiện đại và thứ tự đầu vào lấy từ `s.party` (tất định) ⇒ **không dùng RNG, tất định tuyệt đối** ✅. Quy tắc tie-break `hp+shield` **trùng đúng** quy tắc role `assassin` đã dùng (`pickEnemyIntent:262`) ⇒ nhất quán với quy ước sẵn có.
- **Số:** **một** cứu mạng mỗi lượt, trên Axie nguy hiểm nhất. Đối chiếu `r_soulforge` (LEGENDARY: shield không cap + 25% DR).
- **Event:** `ft` (`'UNDYING'`, class `buf`) lúc cấp, **và** float `'UNDYING'` sẵn có lúc tiêu thụ (`:330`) ⇒ feedback hai đầu, đã được build từ trước.
- **Vì sao tồn tại:** §1.2 cho thấy tường thật là **wave 12 (thắng 37%, 101 chết)** và kiểu chết đặc trưng là **một Axie bốc hơi trong một lượt**. Đây là một cái *sàn*, không phải một cú nâng trần — nó không thêm damage, không thêm shield, chỉ cấm một loại thua đột ngột.
- ⚠️ **Đã hạ từ bản nháp.** Bản đầu cấp `undying` cho **mỗi Axie, một lần mỗi trận** = 5 cứu mạng/trận. Với BULWARK đã ở 31% winrate, đó là quá nhiều. Bản ship là **1/lượt, chỉ cho Axie yếu nhất**.

### `a_aegisfont` — Aegis Font · EPIC · `a:'shield'` · `mload 0` · `ex: []`

- **d:** `'[MP 8] Grant 8 Shield to the whole party.'`
- **act:** `{cost:8, kind:'shieldall', v:8, tgt:'self'}` — **chạy hôm nay, 0 engine work** (`kind:'shieldall'` đã implement, `:570`).
- 🔧 **Đã nâng `cost: 6 → 8` VÀ hạ `v: 18 → 8` theo §6.7.6.** Bản trước đo **52.30 RP = 2.4× trần EPIC** — vi phạm nặng thứ ba toàn roster. Phép đo dứt khoát: `5 Axie × 18 Shield = 90 mitigation mỗi lượt`, trong một trận mà **tổng damage địch gây ra là `T_in = 70`**. Thẻ này một mình hấp thụ nhiều hơn cả encounter, mỗi lượt.
- ❌ **Lập luận "3.0 shield/MP vs `a_wall` 2.67/MP" của bản trước là SAI về cấu trúc.** Nó so **hiệu suất mỗi MP** và kết luận scaling đúng chiều. Nhưng hiệu suất mỗi MP không phải thứ bị chặn — **`T_in` mới là**. Khi output vượt tổng damage đầu vào, mọi điểm shield thêm đều **vô giá trị theo trận**, nên relic không "hiệu quả hơn", nó chỉ **thừa**. Đây là lý do audit hạ `v` mạnh hơn nhiều so với nâng `cost`.
- **Số:** 8 (+2/Axie cho Plant nhờ BULWARK ⇒ 10) × 5 Axie = **40-50 shield/lần dùng**, `N* = 2` ở MP 8 ⇒ ~80-100/trận so với `T_in = 70`. Vẫn là một trong những thẻ phòng ngự mạnh nhất, nhưng không còn phủ định encounter.
- **Chặn trên:** `applyShield` cap `maxHp*2` mỗi Axie (`:377`) trừ khi có `noShieldCap` (`r_soulforge`). ⇒ Spam không vượt được cap.
- **Event:** `ft` (`'+18'`, class `shd`) + `hp` × 5, từ `applyShield:378`.
- **Vì sao tồn tại:** hôm nay chỉ có **1** active shield (`a_wall`). Đây là mana sink cho phép **CONDUIT chơi BULWARK** — một tuyến build chéo thật. Nó **cố ý chỉ là một con số**: BULWARK ở 31% winrate không cần thêm luật mới, chỉ cần thêm chỗ để tiêu mana.

## 13. MANA — CONDUIT (3 passive)

> Đo được: 35 run/300 (12%), winrate 29% (khoẻ), 7 relic — nhưng **0 LEGENDARY**. Nó là archetype
> duy nhất không có trần. Aqua CONDUIT: mọi Mana `+1`, mỗi 4 Mana tiêu ⇒ 1 Reroll (`:578-581`).

### `r_tidalbrand` — Tidalbrand · **COMMON** · `a:'mana'` · `mfPhase:'kw'` · `mload 0` · `ex: []`

- **d:** `'RULE: every Ears face also grants 1 Reroll. Start each fight with 1 extra Reroll.'`
- 🔧 **Đã đổi bậc `1 → 0` và thêm rider theo §6.7.6.** Bản trước đo **10.50 RP — DƯỚI sàn COMMON** (11.22), tức nó không hợp bậc nào. Rider `+1 Reroll đầu trận` nâng nó vào `Band[0]` (11.90, Δaim 0.02 — entry sát đích nhất toàn roster).
- ✅ **Đây là entry-point COMMON BẮT BUỘC của CONDUIT** (`relic-system.md` §5.2 ghi chú ³): on-ramp của archetype **phải là passive**, không được là mana sink. CONDUIT có 3 active nhưng trước bản này **không có COMMON passive nào**.
- ✅ **Xung đột dead-draw với `r_voidgene` đã được giải ở phía kia.** Bản trước 100% trùng mệnh đề `mana → rerollup` của `r_voidgene` bản draft ⇒ dead draw §3.7. `relic-system.md` §6.3 đã đổi `r_voidgene` sang chức năng khác ⇒ **không còn trùng**, và `r_tidalbrand` không cần mang `ex`.
- **Hiệu ứng chính xác:** hai mệnh đề:
  1. `modFace` inject `rerollup` vào mọi mặt `p==='ears'` chưa có;
  2. `onTurnStart` — nếu `s.turn === 1` ⇒ `s.rerolls += 1`.
- **Field:** `modFace` + `onTurnStart` — **chạy hôm nay**. `rerollup` được xử lý ở `doFace:538` (`if(hasKw(f,'rerollup')&&u.side==='p') s.rerolls++`) và **nằm trong danh sách loại trừ `kwPure`** (`:489`) ⇒ an toàn hướng.
- 🔒 **Guard `s.turn === 1` là cách đúng để nói "đầu mỗi trận" mà KHÔNG cần hook mới.** `startCombat` set `s.turn=1` (`:229`) rồi gọi `rcall(s,'onTurnStart')` (`:235`) ⇒ chạy đúng một lần mỗi trận ✅. Không tồn tại hook `onCombatStart`, và tài liệu này **không** thêm một cái chỉ cho `+1` reroll.
- **Số:** mặt `ears` **luôn** là `cantrip` ⇒ nó tự kích hoạt trong `resolveCantrips` (`:279-284`, có trần 6 vòng chống loop) ⇒ ~1 mặt ears/die ⇒ **+1-2 reroll/lượt miễn phí**.
- **Định giá đã có bằng chứng:** comment tại `data.js:552` ghi rằng reroll đo được **ảnh hưởng gần như 0 tới winrate qua nhiều seed** (nên `u_reroll` chỉ `+1`). ⇒ RARE là đúng tier, và tôi **không** nâng nó lên EPIC dù nghe mạnh.
- **Event:** không có event mới; `s.rerolls` hiển thị trên HUD.
- **Vì sao tồn tại:** biến reroll từ "van xả xui" thành **tài nguyên của một archetype**, và nó là cách duy nhất CONDUIT trả bằng thứ không phải mana.

### `r_manaspring` — Mana Spring · EPIC · `a:'mana'` · `mload 0` · `ex: []`

- **d:** `'RULE: at the start of every turn, gain 2 Mana.'`
- 🔧 **Đã BỎ phần scale theo số Axie theo §6.7.6.** Bản trước đo **56.25 RP = 2.4× trần EPIC**. Phép đo: `+5 mana/lượt × 5 lượt × R_mana 2.25` = 56 RP — nó **gần như nhân đôi thu nhập mana của cả trận**, và mana là tài nguyên mà 16 active đều rút từ đó. Bản trước tự gọi nó là "relic bật engine" và đó chính xác là vấn đề: một EPIC không được phép là điều kiện tiên quyết của cả một tầng nội dung.
- **Hiệu ứng chính xác:** `onTurnStart` — `s.mana += 2`.
- **Field:** `onTurnStart:s=>{ const p=aliveP(s).filter(u=>!u.token); if(!p.length) return; s.mana+=2; ft(s,p[0],'+2 MP','man'); }` — **chạy hôm nay** (§3.1). Guard `!p.length` vẫn bắt buộc: `ft` cần một unit hợp lệ.
- ❌ **Mất một tính chất tốt, ghi lại có ý thức:** bản cũ **tự giảm khi party chết dần** (feedback âm tự nhiên). Bản phẳng không còn tính chất đó. Đây là cái giá của việc đưa relic về dải; đổi lại nó **đọc được** hơn (một con số, không phải một hàm) và không còn thưởng cho việc giữ 5 Axie sống bằng một trục thứ hai.
- **Số:** `+2` mana/lượt = 10/trận ⇒ khoảng **2 lần dùng active rẻ thêm mỗi trận**, không phải một nền kinh tế mới.
- **Event:** `ft` (`'+2 MP'`, class `man`).
- **Vì sao tồn tại:** payoff của CONDUIT **là** các active, nhưng nút cổ chai là thu nhập mana. Đây là relic bật engine, và nó là điều kiện tiên quyết để 8 active mới của tôi (§4.2) có chỗ dùng.
- ⚠️ Với `r_manaflood` (`manaOverflow`): mana chưa tiêu cuối lượt thành AoE damage ⇒ `+5` AoE miễn phí/lượt. Ghi ở §17.

### `r_conduitcrown` — Conduit Crown · LEGENDARY · `a:'mana'` · 🔧 **ENG-16** · `mload 1` ⚠️ · `ex: ['actReuse']`

- **d:** `'RULE: each of your Lunacia cards may be used twice per turn, and you gain 2 Mana at the start of every turn.'`
- 🔧 **Đã thêm mệnh đề `+2 Mana/lượt` theo §6.7.6.** Bản trước đo **11.00 RP = 35% của một LEGENDARY** — dưới cả sàn COMMON. Phép đo chỉ ra lỗi mô hình của bản trước: `actReuse` chỉ nới **trần số lần dùng mỗi lượt**, nhưng nút cổ chai thật của CONDUIT là **mana**, không phải số slot. Lợi ích thực vì vậy chỉ là `Θ(c)` tăng cho các active rẻ. Mệnh đề mana tấn công đúng nút cổ chai đó.
- **Hiệu ứng chính xác:** hai mệnh đề:
  1. `actReuse:2` — số lần dùng mỗi active trong một lượt tăng từ 1 lên `rmax(s,'actReuse',1)`. **Không áp dụng cho active rarity ≥3** (giới hạn nằm trong spec ENG-16, không nằm ở relic);
  2. `onTurnStart` — `s.mana += 2`.
- **Field:** `actReuse` (`rmax`, cần **ENG-16**) + `onTurnStart` (chạy hôm nay).
- ✅ **`mload: 1` — đề nghị D3 của tài liệu này ĐÃ ĐƯỢC PHÊ CHUẨN** (§6.7.6). Lập luận được chấp nhận nguyên văn: `actReuse` **nhân output của active**, và bằng 0 nếu build không có active ⇒ đúng định nghĩa "multiplier phạm vi archetype" ⇒ 1, không phải 2.
- ⚠️ **Cộng dồn mana với `r_manaspring`:** cả hai nay cấp `+2`/lượt phẳng ⇒ **`+4`/lượt** nếu giữ cả hai. Hợp lệ (`mload` 0+1 = 1) và có chủ đích: đó **là** build CONDUIT. Ghi ở §17.4.
- 🔒 **Vì sao loại trừ rarity ≥3:** `a_ult` là MP10 → 40 pierce + 10 shield toàn party. Dùng 2 lần/lượt = 80 pierce. Chặn ở tầng rarity là **một điều kiện trong engine**, rẻ hơn và an toàn hơn là cân lại `a_ult`.
- **Số:** không thêm sức mạnh trực tiếp — nó **nâng trần của một tài nguyên bạn vẫn phải tự kiếm**. Với `a_aegisfont` (MP6) dùng 2 lần cần MP12/lượt ⇒ chỉ khả thi khi đã có `r_manaspring` + Aqua.
- **Event:** không có event mới (các active tự phát event của chúng).
- **Vì sao tồn tại:** LEGENDARY đầu tiên của CONDUIT. Nó là LEGENDARY duy nhất trong game **không cộng một con số nào** — nó chỉ mở rộng cái bạn đã có, đúng fantasy "spam active, không bao giờ hết Mana" trong `ARCH.mana.d`.
- ⚠️ **`mload` tôi tự gán là 1 và cần `systems-designer` xác nhận.** Bảng §3.6 không phủ `actReuse`. Lập luận của tôi: nó nhân **output của active**, có điều kiện (bằng 0 nếu build không có active) ⇒ khớp định nghĩa "multiplier phạm vi archetype" ⇒ 1, không phải 2.

## 14. CRIT — APEX (4 passive + 1 active)

> Đo được: 30 run/300 (10%), winrate **10% — một nửa baseline 20%**, 4 relic. **Yếu nhất game.**
> Chẩn đoán 4 nguyên nhân độc lập ở **§3.4**. Bốn entry dưới đây **mỗi cái nhắm đúng một nguyên nhân**.
> Đây không phải nới pool.
>
> 🔒 **Cả 4 entry đều `mload 0`, và đó là quyết định thiết kế, không phải tình cờ.**
> `relic-system.md` §3.6 xếp `critBonus` = mload 1, và `r_apexpredator` (`critBonus:35 + critMult:3`)
> = 1+1 = **2 = hết trần**. Bản nháp của tôi cho `r_keeneye` `critBonus:10` và cho `r_shatterpoint`
> thêm `critBonus:15` — cả hai sẽ **loại trừ lẫn nhau với chính LEGENDARY của archetype**, đúng cái
> bẫy §3.6 tự cảnh báo ("luật sẽ cấm chính build APEX"). Tôi đã bỏ **toàn bộ `critBonus`** khỏi
> roster mới. Điều này trùng khớp với §3.4: APEX thiếu **sàn**, không thiếu **tỉ lệ** — và
> `critBonus` chính là "thêm tỉ lệ", tức là thêm phương sai vào archetype đang chết vì phương sai.
> ⇒ Cả 4 relic mới cùng tồn tại được với `r_apexpredator`.
>
> 🔧 **Sau audit, lập luận trên GIỮ NGUYÊN nhưng phải đọc chính xác hơn.** `r_keeneye` (`+4`) và
> `r_shatterpoint` (`+5`) nay **có** cộng damage — nhưng qua **`critFlat`** (thêm **giá trị**, cộng
> **sau** `critMult`, ENG-21), **không** qua `critBonus` (thêm **tỉ lệ**). Phân biệt đó là toàn bộ
> lý do cả 5 relic APEX vẫn `mload 0`/`mload 2` cùng tồn tại được, và nó khớp §3.4: APEX thiếu
> **sàn**, không thiếu **tỉ lệ**.
> Bậc cũng đã đổi: `r_keeneye` C→**E**, `r_predatorpoise` R→**C**. APEX trong roster mới là
> **C 1 · R 2 · E 2 + 1 active**.

### `r_keeneye` — Keen Eye · **EPIC** · `a:'crit'` · 🔧 **ENG-21** · `mload 0` · `ex: ['critPity']`

- **d:** `'RULE: if no Axie rolled a critical hit this turn, your first attack this turn crits and deals 4 more damage.'`
- 🔧 **Đã đổi bậc `0 → 2` và thêm `+4` damage theo §6.7.6.** Hai lý do độc lập: (1) RP 15.60 của bản COMMON rơi vào **VÙNG CẤM** (15.18 – 15.88) — không bậc nào sở hữu khoảng đó; (2) APEX chỉ có **1 EPIC** ⇒ vi phạm AC-4. Mệnh đề `+4` là phần công suất để đạt đích EPIC 26.40.
- **Hiệu ứng chính xác:** `onRollEnd` — xoá cờ `pityCrit` trên mọi Axie sống; nếu **không** Axie sống nào có `critNow`, chọn Axie sống đầu tiên (theo thứ tự `s.party`) có `rolled>=0`, `!used`, `die[rolled].t==='dmg'` và set `critNow = true` **và** `pityCrit = 1`. **Và** `critFlat: 4` áp cho đòn mang cờ đó.
- **Field:** `onRollEnd` (chạy hôm nay) + 🔒 **`critFlatPity: 4`** (`rsum`, cần **ENG-21**) —
  **KHÔNG phải `critFlat`**. ENG-21 khai **hai** field tách biệt: `critFlat` áp cho **mọi** crit
  (`r_shatterpoint`) còn `critFlatPity` **chỉ** áp cho đòn mang cờ `src.pityCrit` (relic này). Dòng
  này trước đây ghi `critFlat` và **pass implement đã ship đúng chữ đó**, biến `+4` thành hiệu ứng
  áp cho mọi crit — tức `+9` trên **mọi** crit khi giữ cả hai relic, thay vì `+9` trên đòn pity và
  `+5` trên các crit khác như 17.4 mô tả. Đó là **≥35.60 RP = `Band[3]`**, một EPIC đứng trong dải
  LEGENDARY. Xem `relic-system.md` §6.7.6 hộp `r_keeneye`.
- 🔒 **`+4` PHẢI cộng SAU `critMult` — đây là lý do ENG-21 tồn tại.** `modDmg` chạy ở `:320`, **trước** `if(o.crit) v*=rmax(s,'critMult',2)` ở `:321`. Cộng `+4` qua `modDmg` sẽ bị **nhân theo crit**: `+8` ở `critMult 2`, **`+12`** với `r_apexpredator` (`critMult:3`) ⇒ relic bay khỏi dải mà không ai chạm vào nó. ENG-21 đặt `critFlat` **sau** `:321` nên `+4` là `+4`, luôn luôn. Cùng nguyên tắc cấu trúc với ENG-4 (`thornsPlus` cộng sau khi nhân).
- 🔒 **Cờ `pityCrit` giới hạn `+4` vào ĐÚNG đòn pity, không phải mọi crit.** Xoá cờ ở đầu `onRollEnd` mỗi lượt ⇒ không có cờ tồn đọng. Cờ nằm trên unit, unit nằm trong `SNAP` (`:547`), `snap()` dùng `clone()` ⇒ **undo khôi phục đúng** ✅. Không dùng RNG ✅.
- 🎯 **Đây là một pity system**, đúng nghĩa kỹ thuật: bảo đảm trong N lần thử (N=1 lượt). Nó nhắm **nguyên nhân #1 của §3.4 (crit không có sàn)**.
- **Determinism:** không dùng RNG. `p[0]` lấy theo thứ tự `s.party` (tất định). ✅
- **Số:** biến crit từ "0-2 lần/lượt tuỳ may" thành "**≥1 lần/lượt, luôn luôn**". Ở `critMult 2` đó là `+1` mặt damage/lượt ≈ **+8-10/lượt**; với `r_apexpredator` (`critMult:3`) là `+2` mặt.
- **Event:** `ft` (`'CRIT!'`) lúc cấp, **và** `critNow` hiển thị **ngay trên mặt die lúc roll** — đường này đã tồn tại (`:252-255` với comment "hiện lên mặt dice → giữ pillar Deterministic"). ⇒ Người chơi thấy crit **trước khi** quyết định gán mặt.
- **Vì sao tồn tại:** APEX không có COMMON, và quan trọng hơn: nó biến crit từ phương sai thành **thông tin có thể lập kế hoạch** — điều kiện để archetype này tồn tại được trong một game mà pillar là "minh bạch triệt để".

### `r_predatorpoise` — Predator's Poise · **COMMON** · `a:'crit'` · 🔧 **ENG-15** · `mload 0` · `ex: []`

- 🔧 **Đã đổi bậc `1 → 0` theo §6.7.6. Hiệu ứng GIỮ NGUYÊN.** RP 12.60 **nằm trong `Band[0]`**, dưới sàn RARE. Phép đo nói đúng bản chất relic: nó **gỡ một hình phạt**, không cộng damage ⇒ giá trị của nó bằng **số crit cứu được qua reroll**, một con số nhỏ ngay cả trong build crit.
- ✅ **Đây là entry-point COMMON của APEX**, và nó `mload 0` nên cùng tồn tại được với `r_apexpredator` — tức người chơi có thể bắt đầu build crit từ wave đầu và giữ nguyên hướng đó tới LEGENDARY. Với archetype yếu nhất game (10% winrate), on-ramp rẻ quan trọng hơn một con số lớn.
- **d:** `'RULE: rerolling an Axie no longer cancels a critical hit it had already rolled.'`
- **Hiệu ứng chính xác:** khi `rollUnit` chạy lại trên một Axie phe người chơi mà `critNow` đang là `true`, giữ `critNow = true` bất kể kết quả roll mới (miễn mặt mới là `t==='dmg'`).
- **Field:** cần **ENG-15**.
- 🎯 Nhắm **nguyên nhân #2 của §3.4**: `rollUnit` **tính lại** `u.critNow` mỗi lần roll (`:254`) ⇒ reroll để tìm mặt tốt **xoá mất crit đã có**. Reroll là 1 trong 2 bề mặt quyết định thật của game (`combo-decision-memo` §1) ⇒ hôm nay APEX **bị phạt vì chơi giỏi**. Relic này gỡ đúng xung đột đó.
- **Số:** không cộng damage. Nó **gỡ một hình phạt**. Với 2-4 reroll/lượt, giá trị là "bạn không còn phải chọn giữa mặt tốt và crit".
- **Event:** float `'CRIT!'` giữ nguyên trên die sau reroll.
- **Vì sao tồn tại:** relic duy nhất trong game sửa một **phản-cộng-hưởng giữa hai hệ thống** thay vì cộng thêm sức mạnh. Nếu chỉ được sửa APEX bằng một relic, tôi chọn cái này chứ không phải `r_keeneye`.

### `r_bloodhymn` — Blood Hymn · RARE · `a:'crit'` · 🔧 **ENG-1** · `mload 0` · `ex: []`

- **d:** `'RULE: critical hits grant 2 Mana.'`
- **Hiệu ứng chính xác:** `onHit` — nếu `ctx.crit` và `ctx.dealt > 0` ⇒ `s.mana += 2`.
- **Field:** `onHit` cần thêm `crit` vào ctx — **ENG-1**.
- 🎯 Nhắm **nguyên nhân #3 của §3.4**: crit là **một multiplier trần trụi, không kết nối với gì cả**. Đây là payoff thứ cấp đầu tiên của crit — và nó trả bằng **trục khác** (mana), đúng khuyến nghị `combo-decision-memo` §3, nên nó **không cộng dồn bậc hai** trên trục damage.
- **Số:** với `r_keeneye` bảo đảm ≥1 crit/lượt ⇒ **≥2 mana/lượt**, ~4-8 nếu build crit thật. Đủ để trả một active mỗi 1-2 lượt.
- **Event:** `ft` (`'+2 MP'`, class `man'`) từ thân relic.
- **Vì sao tồn tại:** mở tuyến **APEX + CONDUIT**, và cho crit một lý do tồn tại ngoài con số damage.

### `r_shatterpoint` — Shatterpoint · EPIC · `a:'crit'` · 🔧 **ENG-8 + ENG-21** · `mload 0` · `ex: []`

- **d:** `'RULE: critical hits ignore Shield and deal 5 more damage.'`
- 🔧 **Đã thêm `+5` damage theo §6.7.6.** Bản trước đo **7.10 RP = 27% của một EPIC** — thấp thứ hai toàn roster. Phép đo: "crit bỏ qua Shield" chỉ đáng `D × p_crit × tỉ lệ shield hấp thụ`, và cả ba thừa số đều nhỏ hơn cảm giác. Bản trước ước lượng "+10-15% hiệu quả" và **đánh giá cao gấp đôi**.
- **Hiệu ứng chính xác:** hai mệnh đề:
  1. `critPierce:1` — trong `dealDamage`, nếu `o.crit` và `rhas(s,'critPierce')` ⇒ `pierce = true`;
  2. `critFlat: 5` — mọi đòn crit `+5`, cộng **sau** `critMult`.
- **Field:** `critPierce` (`rhas`, cần **ENG-8**) + `critFlat` (`rsum`, cần **ENG-21**).
- 🔒 **Vẫn KHÔNG thêm `critBonus`, và `mload` vẫn là 0** — lập luận §14 giữ nguyên và audit xác nhận nó: `critBonus` là "thêm **tỉ lệ**", tức thêm phương sai vào archetype đang chết vì phương sai, **và** nó sẽ loại trừ chính `r_apexpredator`. `critFlat` là "thêm **giá trị**" trên các crit bạn đã có ⇒ đúng chẩn đoán §3.4.
- ⚠️ **`critFlat` là `rsum` ⇒ cộng dồn với `r_keeneye`.** Giữ cả hai: đòn crit pity đầu lượt nhận **`+9`**, các crit khác `+5`. Cả hai `mload 0`, cả hai EPIC ⇒ **không gì cấm cặp này**. Cộng phẳng sau mọi multiplier nên nó không suy biến, nhưng nó là cặp mạnh nhất của APEX sau audit. Ghi ở §17.4.
- **Số:** crit là ~20-65% số đòn tuỳ đầu tư; cho chúng bỏ qua shield ≈ **+10-15%** hiệu quả, và **nhiều hơn nhiều** trước role `tank`/`e_bulwark`/Mecha.
- **Intransitive so với TALON:** pierce bỏ qua shield **đáng tin cậy**; crit-pierce bỏ qua shield **ngẫu nhiên nhưng kèm ×2 damage**. Hai câu trả lời khác nhau cho cùng một vấn đề, không cái nào trội.
- **Event:** `hit` với `crit:true` **và không** có `ft` màu shield ⇒ hai tín hiệu cùng lúc.
- **Vì sao tồn tại:** payoff thứ cấp thứ hai, và nó là EPIC crit đầu tiên **thật sự nói về crit** (`r_echostone` mang tag `crit` nhưng không liên quan gì — §3.4 #4).

### `a_perfectstrike` — Perfect Strike · RARE · `a:'crit'` · 🔧 **ENG-14** · `mload 0` · `ex: []`

- **d:** `'[MP 5] Deal 8 damage to one enemy. This attack always crits.'`
- **act:** `{cost:5, kind:'dmg', v:8, crit:1, tgt:'enemy'}` — cần **ENG-14** (truyền `crit:a.crit`).
- 🔧 **Đã nâng `cost: 4 → 5` và hạ `v: 11 → 8` theo §6.7.6.** Bản trước đo **39.00 RP — nằm gọn trong `Band[3]`**, tức một RARE ở bậc LEGENDARY. Nguyên nhân lại là **tần suất**: `N* = 3` ở MP 4. Ở MP 5 với `v: 8`, `N* = 4` nhưng mỗi lần dùng nhỏ hơn nhiều ⇒ 19.00, đích RARE 18.68.
- ⚠️ **`critMult` làm relic này scale mạnh theo build, và đó là điểm cần đo:** 8 → **16** ở `critMult 2`; **24** với `r_apexpredator` (`critMult:3`); **+`critFlat`** nếu giữ `r_shatterpoint` (`+5`, cộng sau) ⇒ tối đa **29**. RP 19.00 tính ở `critMult 2` mặc định — build APEX đầy đủ đẩy nó cao hơn, nhưng đó là giá trị của **những relic kia**, đúng như nguyên tắc định giá của `RP_act`.
- 🎯 Nhắm **nguyên nhân #4 của §3.4**: `a_ult` là active LEGENDARY của APEX và **không thể crit** vì `playerUseRelic` không bao giờ set `o.crit` (§4.3 bổ chính). Đây là active crit **đầu tiên thực sự crit**.
- **Số:** 11 → **22** ở `critMult 2`; **33** với `r_apexpredator` (`critMult:3`). So với `a_lance`/`a_pinning` (MP3-4): mạnh hơn **nếu** đã đầu tư crit, yếu hơn nếu chưa ⇒ **gating theo archetype đúng chiều**.
- **Event:** `hit` với `crit:true` + `ft` (`'CRIT -22'`, `big:2`) từ `dealDamage:329` ⇒ `fx.js` chạy animation crit sẵn có.
- **Vì sao tồn tại:** nó cũng **chứng minh** ENG-14 hoạt động, nên nó là test case cho chính engine work đó.

## 15. AOE — TEMPEST (3 passive)

> Đo được: 22 run/300 (7%), winrate 18% (sát baseline), 4 relic. Trung bình đều — chỉ cần lấp slot.
> Cơ chế: `cleave` đánh lân cận ở `ceil(v*0.5)` (`doFace:506`); `aoe` đánh **mọi** địch ở **full** `v`
> (`:498`) — **không có chia giá trị**, nên `aoe` mạnh hơn `cleave` rất nhiều.

### `r_gustwing` — Gustwing · **RARE** · `a:'aoe'` · 🔧 **ENG-9** · `mload 1` · `ex: ['cleaveRatio']`

- **d:** `'RULE: Cleave attacks deal 75% damage to neighbours instead of 50%.'`
- 🔧 **Đã đổi bậc `0 → 1` theo §6.7.6. Con số `0.75` GIỮ NGUYÊN.** RP 19.88 **nằm gọn trong `Band[1]`**, tức một COMMON đứng ở bậc RARE. Phép đo: `cleaveRatio 0.5 → 0.75` là **+50% trên toàn bộ phần splash** của một build đã cam kết vào cleave — không phải một buff nhỏ.
- ✅ **Audit xác nhận lập luận "vì sao 0.75 chứ không 1.0" của bản trước là đúng** và **không** đổi con số. Với `r_stormcall` (LEGENDARY, mọi mặt dmg nhận cleave), ratio `1.0` sẽ biến mọi đòn thành 3 mục tiêu full damage. Đổi **bậc** là cách sửa đúng ở đây, không phải đổi **số** — relic vốn được thiết kế tốt, chỉ bị dán nhãn sai.
- **Hiệu ứng chính xác:** `cleaveRatio:0.75` — `doFace:506` dùng `ceil(v * rmax(s,'cleaveRatio',0.5))`.
- **Field:** `cleaveRatio` (`rmax`) — cần **ENG-9**.
- **Số:** `+50%` trên phần splash. Có cleave sẵn ⇒ ~+10-15%; không có mặt cleave nào ⇒ **0**. RARE có điều kiện.
- ⚠️ **Hệ quả AC-4: TEMPEST nay không có COMMON trong roster mới.** Slot COMMON của archetype do bản retune 44 relic cấp (`relic-system.md` §6.7.8). Cùng ràng buộc ship-chung như `r_tinderbox`/INFERNO.
- **Vì sao `0.75` chứ không `1.0`:** với `r_stormcall` (LEGENDARY, **mọi** mặt dmg nhận cleave), ratio `1.0` biến mọi đòn thành 3 mục tiêu full damage = `+100%` damage từ một COMMON. `0.75` giữ nó ở mức COMMON kể cả trong build tệ nhất.
- **Event:** giá trị `hit` lớn hơn trên lân cận.
- **Vì sao tồn tại:** TEMPEST không có COMMON. Và nó là relic duy nhất chạm vào **cleave** thay vì **aoe** — hai keyword này có sức mạnh rất khác nhau và hôm nay không gì phân biệt chúng.

### `r_windlash` — Windlash · **EPIC** · `a:'aoe'` · **hai entry `modFace`** · `mload 0` · `ex: []`

- **d:** `'RULE: every Mouth damage face gains Cleave and deals 1 more.'`
- 🔧 **Đã đổi bậc `1 → 2` và thêm rider `+1` theo §6.7.6.** Bản trước đo **21.55 RP — VÙNG CẤM, vượt trần RARE đúng 0.07 RP** (trần dẫn xuất 21.4858). Đây là ca cận biên nhất toàn roster: relic *gần như* hợp bậc, và chỉ một phép đo mới thấy nó không. Nguyên nhân: `p(mouth ∧ dmg) = 0.278` là **slot damage rộng nhất game**. Rider `+1` đưa nó lên đích EPIC thay vì cố gọt xuống RARE.
- **Hiệu ứng chính xác:** hai mệnh đề, khai ở **hai pha** (như `r_thousandcuts`):
  1. **pha KW** — inject `cleave` vào mọi mặt `t==='dmg'`, `p==='mouth'`, chưa có `cleave` **và chưa có `aoe`** (mặt đã `aoe` thì `cleave` là vô nghĩa — `doFace:498` rẽ nhánh `aoe` trước và không bao giờ tới `cleave`);
  2. **pha ADD** — `+1` value cho mọi mặt `t==='dmg'`, `p==='mouth'`.
- 🔒 **Rider `+1` cũng nhân theo splash**, vì `cleave` tính lân cận từ `v` **sau** `modFace`: `ceil((v+1) × cleaveRatio)`. Với `r_gustwing` (`0.75`) đó là `+0.75`/lân cận. Đã tính trong RP 28.50.
- **Field:** `modFace` ×2 — **chạy hôm nay**. `cleave` nằm trong danh sách loại trừ `kwPure` ⇒ an toàn hướng.
- **Kiểm tra trùng:** `r_cleaveall` chiếm **Tail**; đây là **Mouth**. Part khác ⇒ không trùng luật, và Mouth là part dmg phổ biến nhất nên nó rộng hơn.
- **Số:** ~1.5 lần dùng mouth/lượt × splash `ceil(v*0.5)` lên tối đa 2 lân cận ⇒ **≈+9/lượt ≈ +20%**.
- **Event:** thêm event `hit` cho mỗi lân cận.
- **Cộng hưởng có chủ đích với `r_bloodmouth`** (Mouth nhận `lifesteal`): `hit()` áp lifesteal **mỗi đòn** (`:493`) ⇒ splash cũng hồi máu. Hai relic RARE cùng part, cộng hưởng thật, không trùng luật. Ghi ở §17.

### `r_squallmark` — Squallmark · **RARE** · `a:'aoe'` · `mfPhase:'kw'` · `mload 0` · `ex: []`

- **d:** `'RULE: every Eyes face that heals or weakens gains Area.'`
- 🔧 **THU HẸP PHẠM VI + đổi bậc `2 → 1` theo §6.7.6.** Bản trước đo **21.80 RP — VÙNG CẤM** (21.4858 – 22.44): không bậc nào sở hữu khoảng đó. Nguyên nhân đo được: **ba loại mặt `eyes` có giá trị rất khác nhau khi thêm `aoe`** — `debuff` **10.84** · `heal` **7.08** · `buff` (thorns) **3.89**. Gộp cả ba vào một relic là trộn ba mức giá vào một cái nhãn.
- **Hiệu ứng chính xác:** `modFace` inject `aoe` vào mọi mặt `p==='eyes'` có `t==='heal'` **hoặc** `t==='debuff'`, chưa có `aoe`. **Bỏ nhánh `buff`.**
- 🔒 **Bỏ `buff` là lựa chọn đúng trong ba nhánh, vì hai lý do cùng chiều:** (1) nó là nhánh **rẻ nhất** (3.89) nên bỏ nó cắt ít giá trị nhất cho mỗi điểm RP; (2) nhánh `buff` của `eyes` là **thorns của Reptile**, và nó là **trường hợp Direction Law duy nhất phải kiểm bằng tay** trong relic này. Bỏ nó cũng bỏ luôn một tương tác phải kiểm — lợi ích phụ mà audit ghi rõ.
- **Field:** `modFace` — **chạy hôm nay**. `aoe` nằm trong danh sách loại trừ `kwPure` ⇒ an toàn hướng.
- **Kiểm tra hướng cho từng loại mặt `eyes` CÒN LẠI:** `heal` (plant/aqua) ⇒ `friends.forEach` = toàn party ✅ · `debuff` weaken/vulnerable/blind (bug/beast/bird) ⇒ `foes` ✅. Hai nhánh bị loại khỏi phạm vi: `buff` thorns (reptile) và `summon` (`FR(2,'eyes','summon',1,'cantrip')` — nhánh summon **bỏ qua `aoe`** hoàn toàn, `:531-533`, nên vốn đã vô hại). **Không có trường hợp nào sai hướng.**
- **Hiệu chuẩn tier:** `FACE_POOL` xếp `FR(1,'eyes','heal',7,'aoe')` và `FR(1,'eyes','debuff',0,'weaken:3','aoe')` là **mặt RARE** ⇒ "eyes + aoe" giá bằng 1 mặt RARE. Sau khi thu hẹp còn 2/3 nhánh, relic cấp ~2-3 nâng cấp RARE thay vì 5 ⇒ **RARE là đúng bậc**.
- **Số:** mặt heal 6 đơn mục tiêu ⇒ 6 heal × 5 Axie = 30. Mặt `weaken:4` đơn ⇒ weaken toàn bộ 5 địch. RP 17.91, đích RARE của TEMPEST 17.12.
- **Event:** `ft` + `hp` × 5 mục tiêu thay vì 1.
- **Vì sao tồn tại:** TEMPEST hôm nay **chỉ** là archetype tấn công (`r_cleaveall`/`r_chainreact`/`r_stormcall` đều là damage). Đây là relic aoe đầu tiên áp lên **utility**, mở tuyến TEMPEST + BULWARK (party-wide heal) và TEMPEST + PLAGUE (debuff toàn wave).

## 16. REQUIRES NEW ENGINE WORK

**21 mục sau audit** (17 + 4 mới). **31/50 relic chạy được với 0 engine work**; 19 relic bị gate.
Mỗi mục dưới đây đủ chi tiết để scope và build **không cần hỏi lại tôi**. Cột "S/M/L" là ước lượng
công sức tương đối.

> **Audit đổi cả hai chiều, không chỉ thêm.** Gỡ gate: `r_dawnlance` (bản mới chỉ đọc `tgt` ⇒ rời
> ENG-1), `r_bloodthorn` (chuyển ENG-5 → ENG-19). Thêm gate: `r_seedling`/`r_heartwood` (ENG-18),
> `r_hivequeen` (ENG-20), `r_keeneye`/`r_shatterpoint` (ENG-21). Hai entry PLAGUE mới
> (`r_rotbite`, `r_rotmouth`) **không cần engine work nào** — cả hai dùng field đã có.

### Tóm tắt

| # | Mục | Loại | Relic bị gate | Cỡ |
|---|---|---|---|---|
| **ENG-0** | Thứ tự `modFace` tất định (3 pha) | Sửa bug sẵn có | 5 của tôi + `r_claw`/`r_ancientgene` sẵn có | **M** |
| **ENG-1** | Làm giàu ctx của `onHit` + `modDmg` | Mở rộng hook | `r_bloodhymn` (~~`r_dawnlance`~~ đã gỡ) | S |
| **ENG-2** | `growthPlus` + float `GROW` | Field mới | `r_seedling` | S |
| **ENG-3** | Growth bền qua các trận | Hạ tầng mới | `r_worldtree` | **L** |
| **ENG-4** | `thornsPlus` (cộng **sau** khi nhân) | Field mới | `r_barbedhide` | S |
| **ENG-5** | Hook `onThorns` | Hook mới | `r_retributor`, `r_scalecrown` (~~`r_bloodthorn`~~ đã gỡ) | S |
| **ENG-6** | `tgt` trong ctx của `onShield` | Mở rộng hook | `r_glassspine` | S |
| **ENG-7** | `burnTicks` | Field mới | `r_hearthcore` | S |
| **ENG-8** | `critPierce` | Field mới | `r_shatterpoint` | S |
| **ENG-9** | `cleaveRatio` | Field mới | `r_gustwing` | S |
| **ENG-10** | `act.kind:'kw'` (mode × scope) | Kind mới | `a_pyre`, `a_bramblewall` | M |
| **ENG-11** | `act.kind:'grow'` | Kind mới | `a_bloom` | S |
| **ENG-12** | `act.kind:'summon'` | Kind mới | `a_clutch` | S |
| **ENG-13** | `act.kind:'shatter'` | Kind mới | `a_pinning` | S |
| **ENG-14** | Truyền `exec`/`crit` cho active | Sửa bug | `a_coupdegrace`, `a_perfectstrike` | S |
| **ENG-15** | Giữ `critNow` qua reroll | Field + logic | `r_predatorpoise` | S |
| **ENG-16** | `actReuse` (chỉ rarity ≤2) | Field mới | `r_conduitcrown` | S |
| **ENG-17** | Sửa comment hook ở `data.js:354-356` | Sửa tài liệu | — | S |
| **ENG-18** 🆕 | `growthAll` (= **G1** của `relic-system.md` §10) | Field mới — **khung sở hữu** | `r_seedling`, `r_heartwood` | M |
| **ENG-19** 🆕 | `onDmgTaken` (= **G2(b)**) + `attack` trong ctx | Hook mới — QĐ-2 đã duyệt | `r_bloodthorn` | S |
| **ENG-20** 🆕 | `eggInherit`: `mkAlly` chạy `modFace` + `tokenCap` thành knob | Hạ tầng mới | `r_hivequeen` | **M** |
| **ENG-21** 🆕 | `critFlat` (`rsum`), cộng **SAU** `critMult` | Field mới | `r_keeneye`, `r_shatterpoint` | S |

**4 mục engine mới do audit tạo ra.** Tổng nay là **21 mục**; 3 trong 4 mục mới là hệ quả trực tiếp
của việc relic bị đo là quá yếu và cần **đòn bẩy cấu trúc** thay vì số lớn hơn.

### ENG-18 — `growthAll` (G1)

**Khung sở hữu mục này**, không phải roster: spec đầy đủ ở `relic-system.md` §10 G1.
```
growthAll: N  →  trong endTurn(), sau rollAll (engine.js:637):
  s.party.forEach(p => { if(p.hp>0 && !p.token)
    p.die.forEach((f,i) => { if(f.v>0) p.growth[i] = (p.growth[i]||0) + N; }); });
  EVrelic(s, id, p.uid);
```
🔒 **G1 chuyển từ *tuỳ chọn* sang *BẮT BUỘC*.** `relic-system.md` §18 kết luận 1: `growth` **không
có bậc hợp lệ nào** nếu không có `growthAll`. Cắt G1 ⇒ `r_seedling` (3.14 RP) và `r_heartwood`
(1.76 RP) đều rơi khỏi dải và **EVOLVE không tồn tại được**.
🔒 Guard `!p.token` bắt buộc: token không đi qua `buildUnit` và `u.growth` của chúng không bền.
**Gate:** `r_seedling` (`N=1`), `r_heartwood` (`N=2`, kèm guard `s.turn>1` trong thân relic).

### ENG-19 — `onDmgTaken` + `attack` trong ctx

QĐ-2 (product owner, 2026-09-03) **đã duyệt implement** `onDmgTaken`. Spec gốc ở
`relic-system.md` §10 G2(b): `rcall(s,'onDmgTaken',{src,tgt,dealt})` trong `dealDamage` sau
`if(tgt.side==='p') s.stat.taken+=dealt` (`:336`).

**Mở rộng bắt buộc của tài liệu này:** ctx phải kèm **`attack: !!o.attack`**.
```
:336  rcall(s,'onDmgTaken',{src, tgt, dealt, attack:!!o.attack});
```
🔒 **Không có `attack`, `r_bloodthorn` sẽ vượt dải.** Hook nổ cho **mọi** lần trừ HP, kể cả tick
poison/burn (`src=null`). Thorns chỉ nổ khi `o.attack` (`:339`). Giữ đúng tần suất cũ là điều kiện
để RP 19.48 đúng.
🔒 Hook chạy **sau** khi shield đã hấp thụ (`:328`) ⇒ relic đọc được `dealt` thật.
**Gate:** `r_bloodthorn`. ⇒ **ENG-5 thu hẹp** còn `r_retributor` + `r_scalecrown`.

### ENG-20 — `eggInherit` + `tokenCap`

Hai sửa đổi, cùng gate `r_hivequeen`:

**(1) `mkAlly` chạy `modFace`.** Hôm nay chỉ `buildUnit:54` chạy `modFace`, nên token **không bao
giờ** nhận nó (§7 đã ghi sự thật này).
```
trong mkAlly(s), sau khi dựng die:
  if(rhas(s,'eggInherit')) for(const r of mfSorted(s)) if(r.modFace) r.modFace(a);
```
🔒 **Phải dùng cùng thứ tự pha INV-5** (`mfSorted`) như `buildUnit`, nếu không die egg sẽ phụ thuộc
thứ tự nhặt trong khi die Axie thì không — một nguồn không-tất-định mới.
🔒 `modFace` viết cho Axie phải an toàn trên die egg: die egg có `p`/`t` hợp lệ nên mọi guard
`f.t==='dmg'`/`f.p==='mouth'` hoạt động bình thường; relic nào không khớp thì **no-op**, không throw.

**(2) `tokenCap` thành knob ở CẢ HAI điểm đọc cap:**
```
doFace:532     …filter(x=>x.token&&x.hp>0).length < rmax(s,'tokenCap',4)
ENG-12 summon  (đã dùng rmax, giữ nguyên)
startCombat:227 startSummon vẫn KHÔNG kiểm cap (hành vi sẵn có, không đổi)
```
🔒 Cap **4** phải là mặc định của `rmax` ⇒ không relic nào set thì hành vi không đổi.
**Gate:** `r_hivequeen` (`eggInherit:1`, `tokenCap:6`).

### ENG-21 — `critFlat`, cộng SAU `critMult`

**Spec:** trong `dealDamage`, **ngay sau** `:321` (`if(o.crit) v*=rmax(s,'critMult',2);`):
```
:321a  if(o.crit && src && src.side==='p'){
         let cf = rsum(s,'critFlat');
         if(src.pityCrit) cf += rsum(s,'critFlatPity');   // r_keeneye
         if(cf>0) v += cf;
       }
```
🔒 **Vị trí là toàn bộ nội dung của mục này.** Cộng qua `modDmg` (`:320`) sẽ bị `critMult` **nhân**:
`+5` thành `+15` với `r_apexpredator` (`critMult:3`) ⇒ `r_shatterpoint` bay khỏi `Band[2]` mà không
ai chạm vào nó. Cùng nguyên tắc cấu trúc với ENG-4 (`thornsPlus` cộng sau khi nhân) — đây là lần
thứ hai luật "cộng sau khi nhân" cứu một relic khỏi vi phạm dải, nên nó nên được viết thành **luật
chung** trong `relic-system.md`, không phải hai ngoại lệ rời rạc.
🔒 Tách `critFlatPity` (`r_keeneye`, chỉ áp cho đòn mang cờ `pityCrit`) khỏi `critFlat`
(`r_shatterpoint`, mọi crit) ⇒ hai phạm vi khác nhau, cộng dồn đúng khi giữ cả hai (`+9` trên đòn
pity, `+5` trên các crit khác).
**Gate:** `r_keeneye`, `r_shatterpoint`.

### ENG-0 — Thứ tự `modFace` tất định · **bug đang tồn tại, không phải tính năng mới**

`buildUnit:54` chạy `for(const r of rlist(s)) if(r.modFace) r.modFace(u)` theo thứ tự `s.relics`,
tức **thứ tự người chơi nhặt được relic**. Hệ quả **đã có trong build hiện tại**:

```
r_claw (+1 mọi mặt dmg)  +  r_ancientgene (×1.4 mọi mặt)
  nhặt claw trước:        ceil((v+1)*1.4)     v=6 → 10
  nhặt ancientgene trước: ceil(v*1.4)+1       v=6 → 10   (trùng ở v=6)
  v=10 →                  ceil(11*1.4)=16  vs  ceil(14)+1=15   ← LỆCH
```

Tất định khi replay (cùng `s.relics` ⇒ cùng kết quả) nên **không phải lỗi replay** — nhưng là lỗi
**cân bằng và tính đoán trước được**, vi phạm pillar "minh bạch triệt để".

**Spec:** chạy `modFace` theo **3 pha**, mỗi pha giữ thứ tự `s.relics`:
1. **Pha KW** — relic chỉ thêm/bớt keyword hoặc đổi `t`/`p`.
2. **Pha ADD** — relic cộng/trừ phẳng `f.v`, `u.maxHp`, `u.growth`.
3. **Pha MUL** — relic nhân `f.v`.

Phân loại bằng một field khai báo trên relic, ví dụ `mfPhase: 'kw'|'add'|'mul'` (mặc định `'add'`).
**Không** đoán bằng cách đọc thân hàm.

**Phân pha sau audit (đã đổi):**

| pha | relic |
|---|---|
| **KW** | `r_marrowdrill` · `r_bloomscale` · `r_worldpiercer` · `r_apexferal` · `r_gorehook` · `r_tidalbrand` · `r_squallmark` · `r_rotmouth` 🆕 · `r_thousandcuts`¹ · `r_windlash`¹ |
| **ADD** | `r_talonedge` · `r_barbedhide` 🆕 · `r_bloodthorn` 🆕 · `r_thousandcuts`¹ · `r_windlash`¹ |
| **MUL** | *(không có relic mới nào)* |

¹ **HAI relic — không còn một — khai `modFace` ở CẢ HAI pha:** `r_thousandcuts` (KW thêm `multi:2`,
ADD đổi `f.v = ceil(f.v/2)+2`) và `r_windlash` (KW tiêm `cleave`, ADD `+1` mouth dmg). ✅ **Phương án
"tách" đã được chốt** — `relic-system.md` §11 mục 18 quy định `r_thousandcuts` khai **hai** entry
`modFace` ở hai pha; `r_windlash` theo cùng khuôn sau khi audit thêm rider `+1` cho nó.

🔒 **Thứ tự trong pha ADD nay có hệ quả số học thật.** `r_talonedge` (rar 1, `+2` pierce faces) và
`r_thousandcuts` (rar 2, `ceil(v/2)+2`) đều ở pha ADD trên **cùng** các mặt pierce. INV-5 sắp theo
`[PHASE_RANK, rar, RELIC_INDEX]` ⇒ `r_talonedge` trước ⇒ `ceil((v+2)/2)+2`. Đây là kết quả **duy
nhất** có thể xảy ra, và nó **không** phụ thuộc thứ tự nhặt — đúng mục đích của INV-5.
Ba relic cộng `+1` vào mặt `shield` (`r_barbedhide`, `r_bloodthorn`) thì giao hoán ⇒ thứ tự không đổi kết quả.

> ⚠️ **Mục này thuộc framework, không thuộc roster.** Tôi liệt kê vì 9 relic của tôi tiêm keyword
> và 2 relic cộng phẳng, nên tôi *phụ thuộc* vào nó, nhưng quyền quyết định là của `relic-system.md`.

### ENG-1 — Làm giàu ctx của `onHit` và `modDmg`

Hôm nay (`engine.js:352`): `r.onHit(s, {type, dealt, tgt, addStatus})` — **không có** `src`,
`pierce`, `crit`. Và (`:320`): `r.modDmg({s, src, tgt, v})` — **không có** `pierce`, `crit`, `exec`.
⇒ Không relic nào có thể phản ứng theo *loại đòn*, đó là lý do cả TALON và APEX không có payoff thứ cấp.

**Spec:**
```
:320  v = r.modDmg({s, src, tgt, v, pierce, crit:!!o.crit, exec:!!o.exec})
:352  r.onHit(s, {type, dealt, tgt, src, pierce, crit:!!o.crit, addStatus})
```
`pierce` phải là biến `pierce` **đã tính** ở `:313-318` (đã gộp `o.pierce` và bird-aoe), không phải `o.pierce` thô.

**Gate:** `r_dawnlance` (cần `pierce` trong `modDmg`), `r_bloodhymn` (cần `crit` trong `onHit`).
**Không phá gì:** thêm khoá vào object literal, mọi relic hiện có bỏ qua.

### ENG-2 — `growthPlus` + float text `GROW`

`doFace:539`: `if(hasKw(f,'growth')) u.growth[fi]=(u.growth[fi]||0)+1;`

**Spec:**
```
if(hasKw(f,'growth')){
  const g = 1 + rsum(s,'growthPlus');
  u.growth[fi] = (u.growth[fi]||0) + g;
  ft(s, u, 'GROW +'+g, 'buf');       // ← MỚI: growth hiện KHÔNG phát event nào
}
```
`ft` phải nằm **trong** guard `!isEcho` sẵn có (`:535`) để mặt `echo` không phát 2 lần.
**Gate:** `r_seedling`. **Lợi ích phụ:** vá lỗ visibility của `growth` cho **mọi** nguồn growth, kể cả `r_growthcore` sẵn có.

### ENG-3 — Growth bền qua các trận  ⚠️ mục lớn nhất

Hôm nay `u.growth` nằm trên **unit**, và `startCombat:225` làm `s.party = s.roster.map(r=>buildUnit(r,s))`
⇒ growth **mất sạch** mỗi trận.

**Spec, 3 điểm sửa:**
1. `newRosterEntry` (`:29`) thêm `grown:{}`.
2. `buildUnit`, **sau** vòng `muts` và **trước** `modFace` (tức chèn ở `:53`):
   `if(re.grown) for(const k in re.grown) u.growth[k]=(u.growth[k]||0)+re.grown[k];`
3. `finishCombat` (`:669`), **trước** `genRewards`:
```
const GROWTH_KEEP_CAP = 3;                                // ← hằng có tên trong data.js
if(rhas(s,'growthKeep')) for(const re of s.roster){
  const u = s.party.find(p=>p.uid===re.uid); if(!u) continue;
  for(const k in u.growth){
    const seeded = re.grown[k]||0;                        // phần đã mang vào trận
    const earned = (u.growth[k]||0) - seeded;             // phần kiếm được TRẬN NÀY
    if(earned>0) re.grown[k] = Math.min(GROWTH_KEEP_CAP,  // ← TRẦN CỨNG (audit §6.7.2)
                                        seeded + Math.floor(earned/2));
  }
}
```
🔒 **`GROWTH_KEEP_CAP = 3` là bắt buộc, không phải tuỳ chọn.** Không trần, `r_worldtree` đo **≈70 RP**
= 1.6× trần LEGENDARY, và nó là relic **duy nhất** tích luỹ qua các trận ⇒ giá trị tăng vô hạn theo
số wave. Phải là **hằng có tên trong `data.js`** kèm comment trỏ về §6, cùng khuôn `IRONMAIDEN_CAP`.
🔒 Trần áp lên `re.grown` (**phần bền**), **không** lên `u.growth` (phần trong trận) ⇒ EVOLVE vẫn
tích luỹ tự do trong một trận boss dài. Đó là ranh giới giữ nguyên hình dạng archetype.
🔒 **Phải trừ `seeded`.** Nếu chỉ làm `re.grown[k]=floor(u.growth[k]/2)` thì phần growth cũ bị
**giảm một nửa mỗi trận** ⇒ relic sẽ *mất* giá trị theo thời gian, ngược hoàn toàn ý định.

**Gate:** `r_worldtree`. **Cần thêm:** `s.roster` đã nằm trong save/replay nên `grown` tự bền; xác
nhận `api/submit-run.js` không schema-validate `roster` chặt chẽ (nếu có, phải thêm khoá).

### ENG-4 — `thornsPlus`

`dealDamage:340-341`: `let th=tgt.st.thorns; if(tgt.side==='p') th*=rmax(s,'thornsMult',1);`

**Spec:** `if(tgt.side==='p') th = th*rmax(s,'thornsMult',1) + rsum(s,'thornsPlus');`

🔒 **Cộng SAU khi nhân — bắt buộc.** Cộng trước sẽ nhân với `r_mirrorshell` (`×3`) và biến một
COMMON `+2` thành `+6`. Đây là chống-stack do cấu trúc (§17).
🔒 `th` phải là **số nguyên** sau phép tính (`thornsMult` nguyên, `thornsPlus` nguyên ⇒ ✅) vì
`:343` làm `src.hp -= th` trực tiếp, không làm tròn.
**Gate:** `r_barbedhide`.

### ENG-5 — Hook `onThorns`

Khối thorns (`:339-349`) **không có hook nào** ⇒ toàn bộ archetype AEGIS không thể mở rộng.

**Spec:** sau `EVhp(s,src)` ở `:347` và **trước** `if(src.hp<=0&&src.side==='e') onEnemyDeath(s,src)`:
```
rcall(s,'onThorns',{tgt, src, th});
```
`tgt` = unit **có** Thorns (Axie của bạn) · `src` = kẻ tấn công · `th` = damage thorns **đã tính**
(sau `thornsMult`/`thornsPlus`).

🔒 **Gọi sau `EVhp`, trước `onEnemyDeath`** để: (a) HP đã được ghi nhận vào event stream trước khi
hook chạy; (b) nếu hook giết `src` thì `onEnemyDeath` ngay sau đó vẫn bắt được.
🔒 Hook **không được** gọi `dealDamage` với `attack:true` trên `tgt` ⇒ vô hạn đệ quy. Relic của tôi
dùng `attack:false` + `src:null`. **Ghi luật này vào comment tại điểm gọi.**
**Gate:** `r_bloodthorn`, `r_retributor`, `r_scalecrown`.

### ENG-6 — `tgt` trong ctx của `onShield`

`applyShield:380`: `rcall(s,'onShield',{v, splash:...})` — **không có** target ⇒ relic không biết ai vừa được shield.

**Spec:** `rcall(s,'onShield',{v, tgt:t, splash:...})`  (biến `t` là tham số của `applyShield`).
**Gate:** `r_glassspine`. Một từ. `r_bastionplate` sẵn có không bị ảnh hưởng.

### ENG-7 — `burnTicks`

`tickStatus:651-659` chạy burn **một lần**; poison đã có `poisonTicks` qua `rmax` (`:641`). Bất đối xứng.

**Spec:**
```
if(u.st.burn>0){
  const bm = rmax(s,'burnMult',1);
  const bt = (u.side==='e') ? Math.max(1, rmax(s,'burnTicks',1)) : 1;
  const br = rmax(s,'burnTickRatio',1);            // ← MỚI (audit §6.7.6)
  const base = u.st.burn*(u.side==='e'?bm:1);
  for(let i=0;i<bt;i++) if(u.hp>0)
    dealDamage(s,null,u, i===0 ? base : Math.ceil(base*br), {pierce:1});
  ... (burnSpread + decay giữ nguyên, chạy MỘT lần sau vòng lặp)
}
```
🔒 **`burnTickRatio` chỉ áp cho tick thứ `i ≥ 1`** (tức tick thứ hai trở đi). Tick đầu **luôn** full
⇒ relic không bao giờ là nerf khi giữ một mình, và hành vi mặc định (`bt=1`) hoàn toàn không đổi.
🔒 Mặc định `rmax(...,1)` ⇒ không relic nào set thì `br=1` và code chạy y như cũ.
🔒 `bt` chỉ áp cho `u.side==='e'` (ngang bằng `bm` ở `:653`) ⇒ không bao giờ nhân đôi burn trên Axie bạn.
🔒 Guard `u.hp>0` trong vòng lặp (giống `poisonTicks` ở `:647`) ⇒ không đánh xác.
🔒 Decay và `burnSpread` chạy **một lần**, ngoài vòng lặp ⇒ nếu không, burn sẽ halve 2 lần/lượt và relic thành **nerf**.
**Gate:** `r_hearthcore`.

### ENG-8 — `critPierce`

**Spec:** trong `dealDamage`, ngay sau `let pierce=!!o.pierce;` (`:313`):
`if(o.crit && src && src.side==='p' && rhas(s,'critPierce')) pierce = true;`
Phải đặt **trước** khối `if(pierce){ v += bird+piercePlus }` (`:318`) ⇒ crit-pierce cũng ăn `piercePlus`. Cố ý.
**Gate:** `r_shatterpoint`.

### ENG-9 — `cleaveRatio`

**Spec:** `doFace:506` — `neighborsOf(foes,tgt).forEach(t=>hit(t, Math.ceil(v * rmax(s,'cleaveRatio',0.5))))`
`rmax` mặc định `0.5` ⇒ hành vi hiện tại không đổi khi không giữ relic nào. **Gate:** `r_gustwing`.

### ENG-10 — `act.kind:'kw'`

Kind tổng quát để áp keyword/status qua active. **Thay thế nhu cầu về 4 kind riêng lẻ.**

**Spec:** thêm vào chuỗi `if/else` của `playerUseRelic` (`:566-575`):
```
else if(a.kind==='kw'){
  const mode  = a.mode || 'add';                    // 'add' | 'min'
  const [kn,kvRaw] = a.kw.split(':');  const kv = kvRaw ? +kvRaw : 1;
  let list;
  if(a.scope==='allEnemies')   list = aliveE(s).slice();
  else if(a.scope==='party')   list = aliveP(s).slice();
  else if(a.scope==='enemy'){  if(!tgt||tgt.side!=='e'||tgt.hp<=0) ok=false; else list=[tgt]; }
  else if(a.scope==='ally'){   if(!tgt||tgt.side!=='p'||tgt.hp<=0) ok=false; else list=[tgt]; }
  else ok=false;
  if(ok) for(const t of list){
    if(mode==='min'){ if((t.st[kn]||0) < kv){ t.st[kn]=kv; ft(s,t,kn.slice(0,3).toUpperCase()+kv,'buf'); } }
    else addStatus(s, t, [a.kw]);                   // KHÔNG truyền src — xem ghi chú
  }
}
```
🔒 **`mode:'min'` (sàn) là bắt buộc cho `a_bramblewall`.** Active dùng lại **mỗi lượt** (§4.3 #1) và
`thorns` **không decay** ⇒ một active `thorns +6/lượt` là vô hạn. Sàn thì idempotent.
🔒 **`mode:'min'` gán trực tiếp `t.st[kn]`, không qua `addStatus`** — `addStatus` luôn *cộng*.
🔒 **`mode:'add'` gọi `addStatus` KHÔNG truyền `src`** ⇒ không kích VIRULENT `+2` của Bug và
`poisonSpread`. Nếu sau này có active `kw` với `poison:N`, việc truyền `src` sẽ làm nó thành bậc hai (§2.1).
🔒 `mode:'min'` chỉ hợp lệ với status **số nguyên, không decay hoặc decay chậm** (`thorns`, `regen`).
Dùng `min` với `stun`/`freeze`/`undying` là **vô nghĩa** (chúng là cờ 0/1) — validate ở data, không ở engine.
**Gate:** `a_pyre` (`add`/`allEnemies`/`burn:6`), `a_bramblewall` (`min`/`party`/`thorns:6`).

### ENG-11 — `act.kind:'grow'`

**Spec:**
```
else if(a.kind==='grow'){
  let n=0;
  for(const u of aliveP(s)) if(u.rolled>=0 && u.die[u.rolled].v>0){
    u.growth[u.rolled]=(u.growth[u.rolled]||0)+a.v; ft(s,u,'GROW +'+a.v,'buf'); n++;
  }
  if(!n) ok=false;                                  // không ai đủ điều kiện → không tiêu mana
}
```
🔒 `if(!n) ok=false` ⇒ không bao giờ đốt mana mà không có hiệu ứng. Nhánh `ok=false` sẵn có
(`:575`) đã pop undo và return false. **Gate:** `a_bloom`.

### ENG-12 — `act.kind:'summon'`

**Spec:**
```
else if(a.kind==='summon'){
  let n=0;
  for(let i=0;i<a.v;i++){
    if(s.party.filter(x=>x.token&&x.hp>0).length>=rmax(s,'tokenCap',4)) break;
    const al=mkAlly(s); rollUnit(s,al); al.used=true; s.party.push(al);
    ft(s,al,'SUMMON','buf'); EVhp(s,al); n++;
  }
  if(!n) ok=false;
}
```
🔒 `used=true` (giống `doFace:532`) ⇒ egg không hành động lượt nó sinh ra, và tránh bug `rolled=-1`.
🔒 Dùng `rmax(s,'tokenCap',4)` thay vì hằng `4` để cap thành tuning knob — **nhưng tôi KHÔNG ship
relic nào set `tokenCap`** (§7: `hiveMind` scale theo **số** token nên nới cap là cách nới tệ nhất).
🔒 `if(!n) ok=false` ⇒ đã đầy egg thì không tiêu mana. **Gate:** `a_clutch`.

### ENG-13 — `act.kind:'shatter'`

**Spec:**
```
else if(a.kind==='shatter'){
  if(!tgt || tgt.side!=='e' || tgt.hp<=0) ok=false;
  else {
    const sh = tgt.shield;
    if(sh>0){ tgt.shield=0; ft(s,tgt,'-'+sh,'shd'); EVhp(s,tgt); }
    const dv = Math.max(a.min||0, sh);              // ← SÀN (audit §6.7.1)
    dealDamage(s, aliveP(s)[0], tgt, dv, {pierce:1, attack:false});
  }
}
```
✅ **Câu hỏi mở của mục này ĐÃ BỊ HUỶ bởi audit, không phải được trả lời.** Bản trước hỏi: dùng lên
địch không shield thì (a) thất bại-không-tiêu-mana hay (b) thành công-0-damage? Audit thêm
**`min: 6`** cho `a_pinning` (§6.7.1, vì bản không-sàn đo 11.25 RP — dưới sàn RARE), nên active
**luôn** có hiệu ứng và nhánh `ok=false` cho `sh<=0` **không còn tồn tại**. Đánh đổi đã ghi: frustra
balance yếu đi một chút, đổi lấy một thẻ hợp dải và không bao giờ là thẻ chết.
🔒 `ft` shield chỉ phát khi `sh>0` ⇒ không hiện `-0` trên địch không giáp.
🔒 `attack:false` ⇒ không kích Thorns địch (khác các active damage khác, cố ý: đây là đòn "gỡ giáp").
🔒 `pierce:1` ⇒ shield vừa bị xoá nên không có gì chặn, nhưng để tường minh.
**Gate:** `a_pinning`.

### ENG-14 — Truyền `exec` và `crit` cho active damage

Hôm nay (`:568-571`) nhánh `dmg`/`dmgall`/`ult` **không** truyền `exec` hay `crit` ⇒ `a_ult` mang
tag archetype `crit` mà **không thể crit** (§3.4 #4, §4.3 bổ chính).

**Spec:**
```
:568  dealDamage(s,u,tgt,a.v,{pierce:a.pierce, exec:a.exec, crit:!!a.crit, attack:true});
:571  ... dealDamage(s,u,t,a.v,{exec:a.exec, crit:!!a.crit, attack:true});
```
🔒 **KHÔNG sửa nhánh `ult`** (`:569`). Thêm `crit` vào `a_ult` (MP10, 40 pierce) cho `40×3=120`
damage một mục tiêu với `r_apexpredator`. Nếu `systems-designer` muốn `a_ult` crit được thì phải
cân lại `a_ult` cùng lúc — **không** phải hệ quả phụ của mục này.
🔒 `crit:!!a.crit` ⇒ active không khai báo `crit` vẫn giữ hành vi cũ chính xác.
**Gate:** `a_coupdegrace` (`exec:1`), `a_perfectstrike` (`crit:1`).

### ENG-15 — Giữ `critNow` qua reroll

`rollUnit:248-256` tính lại `u.critNow` mỗi lần roll ⇒ reroll xoá crit đã có (§3.4 #2).

**Spec:** trong `rollUnit`, thay `:254`:
```
const keep = u.side==='p' && u.critNow && rhas(s,'critPreserve');
u.critNow = u.side==='p' && f.t==='dmg' && (keep || (cc>0 && rnd()*100<cc));
```
🔒 **`rnd()` vẫn phải được gọi trong cả hai trường hợp**, nếu không RNG stream sẽ lệch giữa
"giữ crit" và "không giữ" ⇒ **vỡ replay**. Viết lại an toàn:
```
const roll = (cc>0) ? (rnd()*100 < cc) : false;     // luôn tiêu RNG như cũ
u.critNow = u.side==='p' && f.t==='dmg' && (keep || roll);
```
Đây là mục **duy nhất** trong danh sách có rủi ro determinism thật. Bắt buộc chạy
`node tools/soak.mjs` sau khi làm.
🔒 `keep` yêu cầu mặt mới cũng là `t==='dmg'` (đã có trong biểu thức) — crit trên mặt shield là vô nghĩa.
**Gate:** `r_predatorpoise`. Field: `critPreserve` (`rhas`).

### ENG-16 — `actReuse` (chỉ áp cho active rarity ≤2)

**Spec:** `playerUseRelic:564` thay `if(s.usedActives.includes(id) || s.mana<it.act.cost) return false;`
```
const lim = (it.rar<=2) ? Math.max(1, rmax(s,'actReuse',1)) : 1;
if(s.usedActives.filter(x=>x===id).length >= lim || s.mana < it.act.cost) return false;
```
`s.usedActives.push(id)` (`:576`) giữ nguyên ⇒ nó đã cho phép nhiều bản ghi cùng id.
🔒 **`it.rar<=2` là chốt an toàn**, không phải trang trí: `a_ult` (rar 3) dùng 2 lần = 80 pierce/lượt.
🔒 `s.usedActives` đã nằm trong `SNAP` (`:547`) ⇒ undo hoạt động đúng, không cần sửa gì thêm.
🔒 UI (`ui.js:1414`, `:2717`) tính `used = S.usedActives.includes(id)` ⇒ **phải sửa cùng lúc**
thành phép so sánh số lần, nếu không thẻ sẽ hiện "đã dùng" trong khi engine vẫn cho dùng.
**Gate:** `r_conduitcrown`.

### ENG-17 — Sửa comment tài liệu hook ở `data.js:354-356`

Comment hiện tại **sai theo cả hai hướng** và là cạm bẫy trực tiếp cho người thiết kế relic tiếp theo:

```
hooks: modFace(u) build-time · onRollEnd(s) · onTurnStart(s) · modDmg(ctx)->v
onKill(s,ctx) · onShield(s,ctx) · onPoison(s,ctx) · onDmgTaken(s,ctx) · onTurnEnd(s)
```

- **Liệt kê 3 hook chết:** `onPoison`, `onDmgTaken`, `onTurnEnd` — grep `engine.js`: **0 lần xuất hiện**
  ngoài chính comment này. Relic dùng chúng sẽ **im lặng không làm gì**.
- **Thiếu 1 hook đang sống:** `onHit` — **được gọi** tại `:352` với ctx `{type, dealt, tgt, addStatus}`
  và **3 relic hiện có đang dùng nó** (`r_ember`, `r_solarcore`, và `r_openwound` dùng `modDmg`).
  Nó không có trong comment.

**Spec:** viết lại thành danh sách **chỉ gồm hook thật**, kèm ctx chính xác của từng cái, và một
dòng ghi rõ "3 hook `onPoison`/`onDmgTaken`/`onTurnEnd` đã bị **xoá khỏi tài liệu** vì chưa bao giờ
được implement — nếu cần thì phải thêm điểm gọi trước".
Sau ENG-1/ENG-5, comment phải phản ánh ctx mới. **Không gate relic nào**, nhưng nó là mục có tỉ lệ
lợi ích/chi phí cao nhất trong danh sách: nó ngăn đúng loại lỗi mà chính brief của roster này đã cảnh báo.

## 17. ANTI-SYNERGY AUDIT

### 17.1 Hoà giải với `relic-system.md` (đọc trước §2)

`relic-system.md` đã landed sau khi tôi viết §2. Đối chiếu:

| Giả định §2 | Trạng thái | Ghi chú |
|---|---|---|
| **A1** `ARCH` thêm `exec` | ✅ **XÁC NHẬN** — §3.3 | 5 relic `a:'exec'` của tôi được track đúng. |
| **A2** `faceArch()` học `thorns` | ✅ **XÁC NHẬN** — §3.4 (bảng ưu tiên tường minh) | AEGIS không còn mắc cạn. |
| **A3** Power budget | ⚠️ **ĐƠN VỊ KHÁC** — họ dùng **RP**; tôi dùng **% output/lượt** | Dùng RP làm chuẩn. Cột `%` của họ khớp trực tiếp với con số `%` của tôi; mọi entry của tôi đã ghi `%` nên chuyển đổi được. **Không có xung đột thực chất.** |
| **A4** Không cap số relic | ❌ **BỊ THAY** — `RELIC_CAP = 10` + `mload` cap 2 (§3.6) | **Củng cố** quyết định của tôi: tôi ship **0 multiplier toàn cục**. Xem 17.2. |
| **A5** Hook được gọi hàm engine | ✅ **ĐÃ PHÁN: ĐƯỢC PHÉP** — product owner 2026-09-03, xem `relic-system.md` §14 QĐ-1 | **Đã giải quyết.** 9 relic (`r_heartwood`, `r_broodmother`, `r_eggshell`, `r_apexbrood`, `r_hivequeen`, `r_cullingorder`, `r_deathspiral`, `r_ironmaiden`, `r_manaspring`) giữ "chạy hôm nay", KHÔNG chuyển sang engine work. Rủi ro merge lớn nhất đã đóng. |
| **A6** `relicPool` uniform | ✅ hợp | `ex`/`mload` lọc ở điểm phát ⇒ pool loãng thêm; xem E5 của họ. |
| **A7** Không de-dup | ❌ **BỊ THAY** — `ex` token (§3.7) | Tôi đã gán `ex` cho từng relic ở 17.2. **3 điểm không đồng ý** ở 17.5. |
| **A8** Không ship `rar:4` | ✅ giữ | 0 relic `rar:4`. |

### 17.2 `mload` / `ex` cho toàn bộ **50** relic mới — bảng đầy đủ

> **Bảng này là nguồn duy nhất cho `mload`/`ex` của 50 entry mới.** `relic-system.md` §6.7 kê RP và
> thay đổi nhưng **bỏ trống `mload`/`ex` cho phần lớn 48 relic**, nên hai bất biến chống-stack
> (`mload` cap 2, de-dup theo `ex`) chỉ kiểm được trên 46/94 relic. Điền đủ bảng dưới là thứ đóng
> khoảng trống đó cho `tools/t_relic.mjs`.

| id | arch | rar | `mload` | `ex` | Lý do |
|---|---|---|---|---|---|
| `r_talonedge` | pierce | 1 | 0 | — | cộng phẳng `modFace` |
| `r_marrowdrill` | pierce | 1 | 0 | — | tiêm keyword, part riêng |
| `r_thousandcuts` | pierce | 2 | **1** | — | nhân **số đòn**, ⇒ nhân mọi bonus phẳng mỗi đòn |
| `r_worldpiercer` | pierce | 3 | **1** | `pierceInjectAll` | `piercePlus` + tiêm pierce toàn bộ |
| `r_dawnlance` | pierce | 3 | **2** ⚠️ | `dmgMultCond` | multiplier damage toàn cục có điều kiện, cùng hạng `r_bloodpact` |
| `a_pinning` | pierce | 1 | 0 | — | active, giá trị phẳng |
| `r_seedling` | growth | 0 | 0 | — | `growthAll`+`growthPlus` đều cộng phẳng (`rsum`) |
| `r_heartwood` | growth | 1 | 0 | — | `growthAll` cộng phẳng |
| `r_bloomscale` | growth | 1 | 0 | — | tiêm keyword + `growthPlus` phẳng |
| `r_quickenroot` | growth | 2 | 0 | — | cộng phẳng theo lượt |
| `r_worldtree` | growth | 3 | **1** | — | tích luỹ **xuyên trận**; đã kèm trần `GROWTH_KEEP_CAP` |
| `a_bloom` | growth | 2 | 0 | — | active, cộng phẳng |
| `r_broodpouch` | summon | 0 | 0 | — | `startSummon` (`rsum`) |
| `r_eggshell` | summon | 1 | 0 | — | shield phẳng |
| `r_broodmother` | summon | 1 | 0 | — | hồi token + damage phẳng |
| `r_apexbrood` | summon | 2 | 0 | — | HP/damage phẳng trên token |
| `r_hivequeen` | summon | 3 | **2** ⚠️ | `eggInherit` | nhân output của **mọi `modFace` khác** (mở cửa §7 E9) + nới `tokenCap` (nhân `hiveMind`) |
| `a_clutch` | summon | 1 | 0 | — | active, tạo token, chặn bởi cap |
| `r_barbedhide` | thorns | 0 | 0 | — | `thornsPlus` cộng **sau** khi nhân (ENG-4) |
| `r_bloodthorn` | thorns | 1 | 0 | — | hồi máu theo thorns **thô**, không theo `th` đã nhân |
| `r_glassspine` | thorns | 2 | 0 | `thornsFloorShield` | sàn **có điều kiện** — tách khỏi `thornsFloorFlat` (D1) |
| `r_retributor` | thorns | 2 | 0 | — | chia lại thorns sang lân cận, tỉ lệ cố định |
| `r_ironmaiden` | thorns | 3 | 0 | — | damage phẳng có trần cứng; **không** áp `thornsMult` |
| `r_scalecrown` | thorns | 3 | 0 | `thornsFloorFlat` | sàn **vô điều kiện** (cùng `r_spines`) |
| `a_bramblewall` | thorns | 1 | 0 | — | active, ngữ nghĩa sàn ⇒ idempotent |
| `r_gorehook` | exec | 0 | 0 | — | tiêm `exec` lên horn+tail |
| `r_scentofblood` | exec | 1 | 0 | — | cộng phẳng **sau** `dmgMult` |
| `r_cullingorder` | exec | 2 | 0 | — | heal/shield phẳng, một mục tiêu |
| `r_deathspiral` | exec | 2 | 0 | — | damage phẳng, một lần/địch |
| `r_apexferal` | exec | 3 | 0 | `execInjectAll` | tiêm `exec` **toàn bộ** mặt dmg ⇒ superset của `r_gorehook` |
| `a_coupdegrace` | exec | 2 | 0 | — | active, damage phẳng |
| `r_pandemic` | poison | 2 | 0 | — | phân phối lại, **không** truyền `src` ⇒ không sinh stack |
| `r_rotbite` 🆕 | poison | 0 | 0 | `poisonAmpFlat` | amp **phẳng** — tách khỏi `poisonAmpPct` của `r_openwound` |
| `r_rotmouth` 🆕 | poison | 1 | 0 | — | tiêm `poison` lên mouth; part riêng |
| `r_tinderbox` | burn | **0** | 0 | `burnAmpFlat` | amp **phẳng** — đối xứng `poisonAmpFlat`, tách khỏi `r_openwound`. `mload 0` là **điều kiện** để nó giữ được COMMON (AC-9) |
| `r_hearthcore` | burn | 2 | **1** | `burnTicks` | nhân **output** burn (`rmax`) |
| `a_pyre` | burn | 2 | 0 | — | active, cấp stack phẳng |
| `r_lastwall` | shield | 0 | 0 | `undyingGrant` | relic duy nhất cấp `undying`; token giữ chỗ cho relic thứ hai |
| `a_aegisfont` | shield | 2 | 0 | — | active, shield phẳng |
| `r_tidalbrand` | mana | 0 | 0 | — | tiêm `rerollup` lên ears + reroll phẳng |
| `r_manaspring` | mana | 2 | 0 | — | thu nhập mana **phẳng**, không nhân |
| `r_conduitcrown` | mana | 3 | **1** | `actReuse` | nhân **output của active** (`rmax`), = 0 nếu build không có active |
| `r_keeneye` | crit | 2 | 0 | `critPity` | bảo đảm crit bằng gán cờ ⇒ mọi relic pity khác trùng 100% |
| `r_predatorpoise` | crit | 0 | 0 | — | gỡ hình phạt reroll, không cộng damage |
| `r_bloodhymn` | crit | 1 | 0 | — | trả bằng **mana**, khác trục damage |
| `r_shatterpoint` | crit | 2 | 0 | — | `critPierce` (`rhas`) + `critFlat` cộng **sau** `critMult` |
| `a_perfectstrike` | crit | 1 | 0 | — | active, damage phẳng (crit nhân là của relic khác) |
| `r_gustwing` | aoe | 1 | **1** | `cleaveRatio` | nhân phần splash (`rmax`) |
| `r_windlash` | aoe | 2 | 0 | — | tiêm `cleave` lên mouth + cộng phẳng |
| `r_squallmark` | aoe | 1 | 0 | — | tiêm `aoe` lên eyes heal/debuff |

**Tổng hợp `mload` sau audit:**

| `mload` | Số relic | Relic |
|---|---|---|
| **2** | **2** ⚠️ | `r_dawnlance` · `r_hivequeen` |
| **1** | 6 | `r_thousandcuts` · `r_worldpiercer` · `r_worldtree` · `r_hearthcore` · `r_conduitcrown` · `r_gustwing` |
| **0** | 43 | tất cả còn lại, **gồm cả 5 relic APEX và cả 8 active** |

> ⚠️ **Thay đổi chính sách so với bản trước.** Bản trước tuyên bố *"Tôi ship **0** relic `mload 2`"*.
> Audit đã **buộc phải phá** tuyên bố đó **hai lần**, cả hai ở LEGENDARY và cả hai vì cùng một lý do:
> relic đo được **quá yếu** (`r_dawnlance` 6.80 RP, `r_hivequeen` 12.10 RP) và **không con số nào**
> đưa được chúng tới dải LEGENDARY — chúng cần một **đòn bẩy cấu trúc**, và mọi đòn bẩy cấu trúc đủ
> lớn đều là một multiplier. `mload: 2` là **giá** của đòn bẩy đó: mỗi relic này một mình chiếm hết
> trần, nên nó loại trừ `r_bloodpact`, `r_ancientgene`, `r_apexpredator` và **lẫn nhau**. Đây là
> đánh đổi có ý thức, không phải trượt phạm vi.
>
> Con số `mload 1` **giữ nguyên 6**: `r_dawnlance` rời nhóm (lên `mload 2`) nhưng `r_worldtree`
> được **thêm** vào (đề nghị D3 chọn phương án `mload 1`, §6.7.2) — trừ một, cộng một. Bản trước
> ghi "6 xuống 5" và liệt kê 6 id ngay bên cạnh; cột số đã được sửa cho khớp danh sách, danh sách
> mới là nguồn đúng (đối chiếu với `RELICS` bản ship: đúng 6 relic mới mang `mload 1`).

**`ex` token mới tài liệu này đề nghị** (ngoài các token đã có ở `relic-system.md` §3.7):

| Token | Relic mang | Lý do |
|---|---|---|
| `critPity` | `r_keeneye` | Bất kỳ relic nào bảo đảm crit bằng `Math.max`/gán cờ đều trùng 100%. |
| `actReuse` | `r_conduitcrown` | Field `rmax` ⇒ cái nhỏ hơn là dead draw. |
| `cleaveRatio` | `r_gustwing` | Field `rmax`. |
| `burnTicks` | `r_hearthcore` | Field `rmax` — cùng lý do `poisonTicks` đã có token. |
| `thornsFloorShield` | `r_glassspine` | **Tách khỏi `thornsFloorFlat`** — xem 17.5 D1 (đã được chấp nhận). |
| `thornsFloorFlat` | `r_scalecrown` (+ `r_spines` sẵn có) | Sàn vô điều kiện. |
| `poisonAmpFlat` 🆕 | `r_rotbite` | Amp poison **phẳng**. Phải tách khỏi `poisonAmpPct` (`r_openwound`, phần trăm) — hai luật khác nhau, cùng tồn tại được. |
| `poisonAmpPct` 🆕 | `r_openwound` (sẵn có) | Cặp đối xứng của token trên; **cần `relic-system.md` gán cho relic sẵn có**. |
| `burnAmpFlat` 🆕 | `r_tinderbox` | Đối xứng chính xác với `poisonAmpFlat` trên trục burn. |
| `dmgMultCond` 🆕 | `r_dawnlance` | Multiplier damage toàn cục **có điều kiện**; token chung với `r_bloodpact` nếu framework muốn chặn cặp đó ngoài `mload`. |
| `eggInherit` 🆕 | `r_hivequeen` | Bất kỳ relic nào cho token thừa hưởng `modFace` đều trùng 100%. |
| `pierceInjectAll` 🆕 | `r_worldpiercer` | Superset của `r_pierceall`/`r_talonedge` — xem D2. |
| `execInjectAll` 🆕 | `r_apexferal` | Superset của `r_gorehook` — xem D2. |
| `undyingGrant` 🆕 | `r_lastwall` | Giữ chỗ: relic thứ hai cấp `undying` sẽ trùng luật hoàn toàn. |

**Không mang `ex`:** 36 relic còn lại. Mọi relic tiêm keyword lên **part khác nhau** (`r_marrowdrill`
pierce-faces · `r_windlash` mouth · `r_rotmouth` mouth (keyword khác) · `r_gorehook` horn+tail ·
`r_bloomscale` back+eyes · `r_squallmark` eyes · `r_tidalbrand` ears) đều **cộng dồn thật**, không
trùng ⇒ đúng luật "một token cho mỗi *luật*". Hai mệnh đề rider `shield +1` (`r_barbedhide` +
`r_bloodthorn`) **cố ý không mang token**: cộng phẳng không phải trùng luật, và mỗi relic vẫn giữ
một mệnh đề chính riêng.

### 17.3 Những cộng hưởng tôi CỐ Ý tránh

| Đã bỏ | Vì sao |
|---|---|
| Mọi `critBonus` mới | §3.6 xếp nó `mload 1` và `r_apexpredator` đã dùng hết trần 2 ⇒ relic APEX mới sẽ **loại trừ chính LEGENDARY của APEX**. Và §3.4: APEX thiếu **sàn**, không thiếu **tỉ lệ**. |
| Mọi nguồn thorns **cộng dồn** | `thorns` **không decay** ⇒ mọi nguồn cộng dồn là vô hạn theo số lượt. Tôi chỉ dùng **sàn** (`Math.max`) và **cộng phẳng sau khi nhân** (ENG-4). |
| Mọi relic **thêm stack poison** | Poison là bậc hai (§2.1: `+2` stack = `+2v+3` damage) và PLAGUE đã 30% playrate / 16% winrate. `r_rotcarrier` đã bị cắt. |
| Mọi relic **thêm stack burn** | Luật halving ăn chúng (§3.5) **và** chúng cộng dồn bậc hai với `r_wildfire`. `r_immolation` (aoe faces cấp `burn:3`) đã bị cắt và thay bằng `r_hearthcore` (nhân **output**, không thêm **stack**). |
| ~~Relic set `tokenCap`~~ ⚠️ **ĐÃ ĐẢO** | Bản trước: *"không làm, có chủ đích"* vì `hiveMind` scale theo **số** token (`:411`) ⇒ nới cap nhân với `hiveMind`. **Audit đã đảo quyết định này** (§6.7.3): `r_hivequeen` nay set `tokenCap: 6`. Lập luận cũ **vẫn đúng** — và đó chính là lý do việc nới cap bị đặt ở **LEGENDARY, `mload 2`, đúng một relic**, chứ không rải ra. Xem 17.4. |
| LEGENDARY thorns thứ hai nâng trần | `r_thornedcrown` (đòn của bạn mang theo thorns) đã bị thay bằng `r_scalecrown` (access). AEGIS ở 25% winrate không cần 2 cú nâng trần. |
| `a_bramblewall` dạng cộng dồn | Active dùng lại **mỗi lượt** + thorns không decay = vô hạn. Ngữ nghĩa **sàn** (ENG-10 `mode:'min'`) làm nó idempotent. Audit hạ `thorns:6→5` nhưng **giữ nguyên `mode:'min'`** — ngữ nghĩa sàn là điều kiện tồn tại, không phải knob. |
| Mọi `critBonus` mới (**tái xác nhận sau audit**) | `r_keeneye`/`r_shatterpoint` nay có `+4`/`+5` damage, nhưng qua `critFlat` (**giá trị**, cộng sau `critMult`), **không** qua `critBonus` (**tỉ lệ**). Giữ `mload 0` cho cả hai ⇒ build APEX vẫn giữ được cả 5 relic. |

### 17.4 Cặp nguy hiểm tôi CÓ Ý THỨC ship

| Cặp | Hệ quả | Cái gì chặn nó |
|---|---|---|
| **`r_seedling` + `r_heartwood`** 🆕 | `growthAll` là `rsum` ⇒ **`+3`/lượt lên MỌI mặt của MỌI Axie**, tích luỹ cả trận | Cả hai `mload 0` ⇒ **không gì cấm.** Cộng phẳng nên không suy biến, nhưng đây là cặp cộng dồn mạnh nhất của EVOLVE. **Ưu tiên đo #1 sau audit.** |
| **`r_keeneye` + `r_shatterpoint`** 🆕 | `critFlat` là `rsum` ⇒ đòn crit pity đầu lượt `+9`, các crit khác `+5` | Cả hai `mload 0`, cả hai EPIC ⇒ **không gì cấm.** Cộng **sau** `critMult` (ENG-21) nên không bị nhân — đó là toàn bộ lý do ENG-21 tồn tại. |
| **`r_hivequeen` + `r_hivemind`/`r_swarmnest`** 🆕 | `tokenCap` 4→6 **nhân** với `hiveMind` (`:411` scale theo **số** token) ⇒ `+2` damage lên mọi mặt dmg của cả party | `r_hivequeen` `mload 2` = **hết trần** ⇒ loại trừ mọi multiplier khác. Đã tính trong RP 38.00. Đây là cặp audit **cố ý** cho phép. |
| **`r_dawnlance` + crit** 🆕 | `×1.9` (modDmg, `:320`) **nhân chồng** `critMult` (`:321`) ⇒ `×3.8` ở `critMult 2` | `mload 2` chặn `r_apexpredator` (`critMult 3`) ⇒ trần thực tế là `×3.8`, không phải `×5.7`. |
| `r_quickenroot` + `r_worldtree` | `+5` growth/lượt, tích luỹ **xuyên trận** | ✅ **ĐÃ ĐÓNG.** `GROWTH_KEEP_CAP = 3` chặn phần bền ở `+3`/mặt (bão hoà sau ~3-4 trận), **và** `r_worldtree` nay `mload 1`. Ước lượng `+240` cũ nay có trần cứng ở `+90` toàn party. Xem 17.6 #1. |
| `r_ironmaiden` + mặt thorns cộng dồn | `reptile3` có `F('back','shield',6,'thorns:4')` ⇒ Thorns 20+ ở lượt 5 | ✅ **ĐÃ THU HẸP.** `IRONMAIDEN_CAP = 7` (từ 12) **và** phạm vi còn **một** địch (từ mọi địch). Trần đi từ 240 damage/trận xuống ~35. |
| `r_hearthcore` + `r_solarcore` | `burnTicks` × `burnMult` ⇒ output burn `×3.4` | ✅ `burnTickRatio 0.7` hạ từ `×4` xuống `×3.4`, **và** `mload` 1+1 = **2 = hết trần** ⇒ không thể thêm `r_pyroclasm`. Cặp này audit phát hiện, bản trước **không** thấy. |
| `r_worldpiercer` + `r_hollowbone` | mọi mặt `+5` damage và miễn nhiễm Thorns | `mload` 1+1 = **2 = hết trần**. Chặn tốt. |
| `r_thousandcuts` + `r_hollowbone` | `piercePlus:4` áp **2 lần** mỗi mặt pierce, và nay mỗi đòn còn `+2` từ chính relic | `mload` 1+1 = **2**. Và Thorns phản đòn cũng nhân đôi = giá thật. |
| `r_manaspring` + `r_conduitcrown` 🆕 | Cả hai nay `+2` mana/lượt phẳng ⇒ **`+4`/lượt** | `mload` 0+1 = 1, hợp lệ. Có chủ đích: đó **là** build CONDUIT. Thu nhập, không phải multiplier. |
| `r_manaspring` + `r_manaflood` | mana chưa tiêu → AoE damage | Nhẹ hơn nhiều sau audit (`+5` → `+2` mana/lượt). Cả hai `mload 0`. |
| `r_cullingorder` + `r_holyfont` | `applyHeal 4` tự sinh 4 shield rồi `applyShield 4` ⇒ 8-10 shield/kill | Nhẹ hơn bản trước vì phạm vi còn **một** Axie (từ 5). Có chủ đích. |
| `r_pandemic` + `r_plaguelord` | Lan khi **áp** (lân cận) **và** khi **chết** (toàn bộ) | `r_pandemic` **không truyền `src`** ⇒ không sinh stack mới. Chỉ phân phối lại. |
| `r_rotmouth` + `r_windlash` 🆕 | Mouth vừa `cleave` vừa `poison:2`; splash **cũng** mang `kwPure` ⇒ poison lan theo cleave | Keyword khác nhau ⇒ không trùng luật. Nhưng `r_rotmouth` **có** truyền `src` ⇒ Bug VIRULENT `+2` áp cho **cả** splash. Đã tính trong `RP_class` 26.3 (1.41× band, dưới trần 2.2). |
| `r_rotmouth` + `r_rotbite` 🆕 | Áp poison qua mouth **rồi** ăn `+2` damage vì mục tiêu đã nhiễm | Có chủ đích — đó là build PLAGUE cấp thấp mà archetype đang thiếu. Cả hai `mload 0`, không relic nào thêm stack ở bậc EPIC/LEGENDARY. |
| `r_windlash` + `r_bloodmouth` | Mouth vừa `cleave` vừa `lifesteal` ⇒ hồi máu cả từ splash | Có chủ đích, không trùng luật. `r_windlash` nay EPIC nên cặp này đắt hơn trước. |
| `r_barbedhide` + `r_bloodthorn` 🆕 | Cả hai cùng cấp rider *shield faces +1* ⇒ `+2` | Cộng phẳng, **không** dead-draw (mỗi relic giữ một mệnh đề chính riêng) ⇒ cố ý **không** mang `ex`. |
| `r_glassspine` + `r_retributor` 🆕 | `r_glassspine` cấp Thorns 4 khi shield ⇒ điều kiện `tgt.shield>0` của `r_retributor` gần như **luôn đúng** | Có chủ đích: đây là cách AEGIS **tự tạo build** thay vì tự chặn. Cả hai `mload 0`, cả hai EPIC. |

### 17.5 Bốn điểm bất đồng với `relic-system.md` — **TẤT CẢ ĐÃ ĐƯỢC PHÁN QUYẾT**

| # | Đề nghị của tài liệu này | Phán quyết (`relic-system.md` §6.7) |
|---|---|---|
| **D1** | Tách `thornsFloorFlat` / `thornsFloorShield` | ✅ **CHẤP NHẬN nguyên văn.** `r_glassspine` mang `thornsFloorShield`, `r_scalecrown` + `r_spines` mang `thornsFloorFlat`. |
| **D2** | `exSub` bất đối xứng, **hoặc** chấp nhận tường minh rằng subset chết khi lấy superset | ✅ **ĐÃ PHÁN — CHỌN PHƯƠNG ÁN 1 (`exSub`).** `relic-system.md` §3.7a. Lý do đảo khuyến nghị: đo bằng máy trên **tập mặt thật** cho thấy **3 cặp tập con** đang sống (`r_pierceall` ⊂ `r_worldpiercer` 9⊂29 · `r_gorehook` ⊂ `r_apexferal` 17⊂31 · `r_windlash` ⊂ `r_stormcall` 15⊂26) — **gồm cả cặp `pierce` mà tài liệu này tưởng là độc lập**. Phương án 2 (chấp nhận + ghi chú) vi phạm pillar §2.3 "trần rõ ràng thay vì trần ẩn": game sẽ đề nghị một relic mà tooltip nói dối. `exSub` tốn ~5 dòng trong `relicConflict()` vốn đã phải viết (§10 R1). Ba relic subset nhận `exSub`; `r_stormcall` giữ `ex: ['cleaveInject']` làm neo. |
| **D3** | 8 field mới cần `mload` | ✅ **CHẤP NHẬN**, với hai sửa đổi: `growthKeep` chốt ở **1** (không phải "0 hoặc 1"), và **hai field mới phát sinh** từ audit cần bổ sung — xem D3 bên dưới. |
| **D4** | Lấp slot poison bằng **retag**, không thêm content | ❌ **BÁC BỎ, có bằng chứng.** Không relic nào trong 44 vừa hợp bậc vừa có cơ chế đọc được là poison; Superlinear Axis Law chặn mọi scaler poison dưới EPIC. ⇒ **2 entry mới bắt buộc** (`r_rotbite`, `r_rotmouth`). Xem §0.3, §10. |

**D1 — `thornsFloor` là một token quá thô.** §3.7 gộp mọi relic đặt sàn Thorns vào một token. Nhưng
`r_glassspine` đặt sàn **có điều kiện** (chỉ khi bạn shield Axie đó), còn `r_spines` đặt sàn **vô
điều kiện**. Chúng **không** dead-draw lẫn nhau: sàn 4-khi-shield nằm *trên* sàn 3-luôn-luôn, và cả
hai đều đóng góp. Gộp một token sẽ **cấm AEGIS chồng hai relic access** — đúng thứ archetype 1.3%
playrate cần nhất.
**Đề nghị:** tách `thornsFloorFlat` (vô điều kiện: `r_spines`, `r_scalecrown`) và
`thornsFloorShield` (có điều kiện: `r_glassspine`).

**D2 — `ex` là đối xứng, nhưng họ LEGENDARY "mọi mặt dmg nhận X" tạo dead-draw BẤT ĐỐI XỨNG.** Ba
trường hợp, và một là relic sẵn có:

| Superset | Subset | Chiều |
|---|---|---|
| `r_worldpiercer` (mọi mặt dmg → pierce) | `r_pierceall` (horn → pierce) | giữ superset ⇒ subset **100% chết** |
| `r_apexferal` (mọi mặt dmg → exec) | `r_gorehook` (horn+tail → exec) | như trên |
| `r_stormcall` (mọi mặt dmg → cleave) **← sẵn có** | `r_cleaveall` (tail), `r_windlash` (mouth) | như trên |

`ex` đối xứng sẽ chặn **cả hai chiều** ⇒ giữ `r_pierceall` (RARE) sẽ **cấm** `r_worldpiercer`
(LEGENDARY), mà đó là nâng cấp lớn. Sai chiều.
**Đề nghị:** thêm khái niệm `exSub: [tokens]` — "không đề nghị relic này nếu đã giữ một superset",
nhưng superset **vẫn được** đề nghị khi đã giữ subset (và khi nhận, subset thành lịch sử — chấp nhận).
Nếu không muốn thêm luật: **chấp nhận tường minh** rằng subset trở thành dead khi lấy superset, và
ghi vào tài liệu. Tôi thiên về phương án 2 (đơn giản hơn) nhưng nó **phải được nói ra**.

> ✅ **PHÁN QUYẾT: phương án 1 (`exSub`).** Xem `relic-system.md` §3.7a. Hai điều bảng trên ghi
> **sai**, đã sửa khi phán quyết:
> 1. **Cặp `pierce` KHÔNG "như trên" — nó bị bảng này xếp nhầm thành độc lập ở chỗ khác.** Đo trên
>    mặt thật: `horn` **chỉ** mang `dmg`, nên "mọi mặt `horn`" (`r_pierceall`, 9 mặt) nằm **trọn**
>    trong "mọi mặt `dmg`" (`r_worldpiercer`, 29 mặt). Việc gán hai token khác nhau
>    (`pierceInject` / `pierceInjectAll`) dựa trên một tính độc lập **chỉ có trong hệ type**.
> 2. **Cặp `r_cleaveall` đã tự tan.** Audit đổi `r_cleaveall` thành "+2 damage cho mặt đã có
>    `cleave`/`aoe`" (§6.1), nó **không còn tiêm** `cleave` ⇒ không còn là subset của `r_stormcall`.
>    Chỉ `r_windlash` còn lại trong ô đó.
>
> Giới hạn đã biết và **cố ý không đóng**: lấy subset **trước** rồi superset sau vẫn kẹt subset
> **hồi tố**. Đóng nó cần refund/xoá relic = content thật. `exSub` mua nửa có giá trị hơn: pool
> **không bao giờ đề nghị** một relic đã chết sẵn.

**D3 — Bảng `mload` §3.6 không phủ các field mới.** Trạng thái sau phán quyết:

| Field | `mload` | Trạng thái |
|---|---|---|
| `growthPlus` | 0 | ✅ chốt |
| `thornsPlus` | 0 | ✅ chốt (cộng **sau** khi nhân, ENG-4) |
| `critPierce` | 0 | ✅ chốt |
| `critPreserve` | 0 | ✅ chốt |
| `growthKeep` | **1** | ✅ chốt ở 1 (bản trước để ngỏ "0 hoặc 1") |
| `burnTicks` | **1** | ✅ chốt (đối xứng `poisonTicks`) |
| `cleaveRatio` | **1** | ✅ chốt |
| `actReuse` | **1** | ✅ chốt |
| `growthAll` 🆕 | **0** | ⚠️ **MỚI — cần phê chuẩn.** Cộng phẳng (`rsum`) lên `f.v`, không nhân gì. Cùng hạng `growthPlus`. |
| `burnTickRatio` 🆕 | **0** | ⚠️ **MỚI — cần phê chuẩn.** Nó **giảm** output (0.7 < 1) và chỉ có nghĩa khi đi kèm `burnTicks` (`mload 1`) ⇒ tính `mload` hai lần cho cùng một hiệu ứng là sai. |
| `critFlat` 🆕 | **0** | ⚠️ **MỚI — cần phê chuẩn.** Cộng phẳng **sau** `critMult` (ENG-21) ⇒ theo đúng tiền lệ `thornsPlus`. |
| `eggInherit` 🆕 | **2** | ⚠️ **MỚI.** Đã tự gán 2 vì nó nhân output của mọi `modFace` khác. Xem `r_hivequeen`. |
| `tokenCap` 🆕 | **—** | Không tính riêng: nó chỉ được set bởi `r_hivequeen`, và relic đó đã `mload 2`. |

**D4 — Poison dừng ở R1.** ❌ **ĐÃ BỊ BÁC.** Đề nghị retag không khả thi (bằng chứng ở §0.3/§10).
PLAGUE nhận **2 entry mới**: `r_rotbite` (COMMON) và `r_rotmouth` (RARE). Roster lên **94**.

### 17.6 Rủi ro cân bằng — trạng thái sau audit

**#1 — `r_quickenroot` + `r_worldtree`** ✅ **ĐÃ ĐÓNG.** Audit áp **cả hai** biện pháp: `growthKeep`
= `mload 1` (phương án a) **và** trần cứng `GROWTH_KEEP_CAP = 3` (mạnh hơn phương án c). Phần bền
xuyên trận nay bão hoà ở `+3`/mặt sau ~3-4 trận thay vì tăng mãi. Sim vẫn nên chạy, nhưng nó không
còn là rủi ro **không trần**.

**#2 — Cap của `r_ironmaiden`** ✅ **ĐÃ ĐÓNG, mạnh hơn đề nghị.** Audit làm cả hai việc: hạ cap
**12 → 7** *và* thu phạm vi từ **mọi địch → một địch (nhiều HP nhất)**. Yêu cầu "viết thành hằng có
tên" nay là **bắt buộc**: `IRONMAIDEN_CAP = 7` trong `data.js`. Cùng khuôn cho `GROWTH_KEEP_CAP = 3`.

**#3 — 5 relic APEX cùng tồn tại** ⚠️ **VẪN MỞ, và nay lớn hơn.** `r_apexpredator` + `r_keeneye` +
`r_predatorpoise` + `r_bloodhymn` + `r_shatterpoint` — tất cả `mload 0` trừ `r_apexpredator`. Audit
**tăng** công suất hai trong số đó (`critFlat` `+4` và `+5`), nên cú nâng tổng lên APEX lớn hơn bản
trước. Lập luận giữ nguyên và audit không bác: §3.4 tìm ra 4 lỗi độc lập, mỗi relic sửa một lỗi, và
phần thêm là **giá trị** (`critFlat`) chứ không phải **phương sai** (`critBonus`). Hành động đề nghị
**không đổi**: đo APEX riêng sau khi ship; nếu vượt đích ~20% thì nerf `r_apexpredator`
(`critMult` 3→2), **không** nerf 5 relic mới.

**#4 — `r_seedling` + `r_heartwood` là chỗ compounding không trần MỚI** 🆕. `growthAll` là `rsum`,
cả hai `mload 0`, và nó áp lên **mọi mặt của mọi Axie mỗi lượt**. Không trần trong trận (trần
`GROWTH_KEEP_CAP` chỉ chặn phần **xuyên trận**). Đây là chỗ thay thế đúng vị trí rủi ro #1 cũ.
**Ưu tiên đo #1** sau khi ship: chạy sim với **chỉ** hai relic này bật. Nếu vượt: (a) gán
`growthAll` = `mload 1`, hoặc (b) `ex` chung — **không** hạ `N`, vì `N` là thứ giữ chúng trong dải.

**#3 — 4 relic APEX đều `mload 0`, nên một build APEX đầy đủ giữ được CẢ NĂM.**
`r_apexpredator` (`critMult:3`, mload 2) + `r_keeneye` + `r_predatorpoise` + `r_bloodhymn` +
`r_shatterpoint` ⇒ ≥1 crit đảm bảo mỗi lượt, crit `×3`, crit xuyên shield, crit sinh mana, crit sống
qua reroll. Đó là **cú nâng lớn nhất trong toàn bộ tài liệu này**, đặt lên archetype yếu nhất (10%).
Nó **có chủ đích** — §3.4 tìm ra 4 lỗi độc lập và mỗi relic sửa một lỗi — nhưng 4 bản sửa cùng lúc
**có thể vượt đích**. Mục tiêu là ~20% (baseline), không phải 35%. Hành động đề nghị: đo APEX riêng
sau khi ship, và nếu vượt thì nerf **`r_apexpredator`** (`critMult` 3→2, việc của
`systems-designer` trong danh sách retune) chứ **không** nerf 4 relic mới — vì chúng là phần *sàn*,
còn `critMult:3` là phần *phương sai*, và §3.4 nói rõ phương sai chính là bệnh.

## 18. Đã hoãn (deferred)

| Hạng mục | Trạng thái | Lý do / bàn giao |
|---|---|---|
| **Slot COMMON + RARE của poison** | ✅ **ĐÃ GIẢI — bằng 2 entry mới, không phải retag** | Đề nghị retag (D4) **bị bác có bằng chứng**: không relic nào trong 44 vừa hợp bậc vừa đọc được là poison, và Superlinear Axis Law chặn mọi scaler poison dưới EPIC. ⇒ `r_rotbite` (C) + `r_rotmouth` (R). Xem §0.3, §10. |
| `r_rotcarrier` (đòn vào mục tiêu đã nhiễm ⇒ `+1` stack) | **Đã cắt** | Thêm stack poison, tức bơm sức mạnh vào phễu đã quá rộng. |
| `r_immolation` (mặt `aoe` cấp `burn:3`) | **Đã cắt** | Thêm stack burn ⇒ bị halving ăn (§3.5) **và** cộng dồn bậc hai với `r_wildfire`. Thay bằng `r_hearthcore`. |
| `r_thornedcrown` (đòn của bạn mang theo Thorns) | **Đã cắt** | Cú nâng trần thứ hai trên AEGIS (25% winrate). Thay bằng `r_scalecrown` (access). |
| `r_hivequeen` bản copy die của lead | ✅ **CÂU HỎI MỞ ĐÃ ĐƯỢC TRẢ LỜI — và câu trả lời là "quá nhẹ"** | Tài liệu này tự đặt câu hỏi *"bản đã hạ có thể quá nhẹ"* và tự đề nghị nới thành **2 mặt**, **không** nới `tokenCap`. Audit đo được **12.10 RP = 36% của một LEGENDARY** ⇒ nghi ngờ đúng, **nhưng cả hai đề nghị đều sai hướng**: copy 2 mặt vẫn chỉ đổi ~2/6 số lần roll. Cơ chế bị thay hoàn toàn bằng `eggInherit`, **và** `tokenCap` **được** nới lên 6 — đúng thứ tài liệu này loại trừ. Giá: `mload 2`. Xem §7, §17.4. |
| `r_skyhunter` (pierce vs địch không shield `+6`) | **Đã cắt** | Điều kiện gần như luôn đúng ⇒ thực chất là `+6` phẳng vô điều kiện, không phải một luật. |
| `a_lance` (MP4 → 18 pierce) | **Đã cắt** | Gần như strict upgrade của `a_chomp`; thay bằng `a_pinning` (`shatter`) để tạo tam giác intransitive thật (§9). |
| LEGENDARY thứ 2 cho burn/shield/poison/mana/crit/aoe | **Không làm** | Mục tiêu §1.1 là L≥1 cho các archetype này (đã đạt); L≥2 chỉ dành cho 5 archetype ưu tiên. |
| 4 relic `a:''` không tag (`r_claw`, `r_heart`, `r_bloodmouth`, `r_infinitedie`) | **Không thuộc phạm vi** | Retag là việc của `systems-designer` (§4.1). |
| Kích hoạt `onPoison` / `onDmgTaken` / `onTurnEnd` | **Không cần** | **Không** relic nào trong 48 relic dùng chúng. ENG-17 chỉ **xoá chúng khỏi tài liệu**. Nếu tương lai cần, phải thêm điểm gọi trước. |
| Relic set `tokenCap` | **Không làm, có chủ đích** | ENG-12 để nó thành knob; nới cap nhân với `hiveMind` ⇒ cách nới tệ nhất (17.3). |
| Cân lại `a_ult` để crit được | **Không thuộc phạm vi** | ENG-14 **cố ý không sửa** nhánh `ult`. `40×3=120` một mục tiêu. Bàn giao cho `systems-designer` cùng đợt retune. |
| Sim xác nhận mọi con số | **Chưa chạy** | `game-concept.md` §Tuning Knobs: *"Mọi thay đổi giá trị ship phải chạy qua `tools/sim.js`, không chốt bằng đọc spec"*. Mọi con số trong tài liệu này là **mô hình hoá, chưa đo**. Ưu tiên đo: 17.6 #1, #3, rồi `r_ironmaiden`. |


---

## 19. QUYẾT ĐỊNH CỦA PRODUCT OWNER — 2026-09-03

Ba quyết định đã chốt, ghi đầy đủ ở `relic-system.md` §14. Phần ảnh hưởng trực tiếp tới roster này:

| # | Quyết định | Ảnh hưởng tới roster |
|---|---|---|
| **QĐ-1** | Relic hook trong `data.js` **được phép** gọi hàm `engine.js` | Giả định **A5 được chuẩn y**. 9 relic giữ trạng thái "chạy hôm nay". Con số "30/48 ship không cần engine work" vì vậy **đứng vững** — không tụt xuống 21/48. |
| **QĐ-2** | **CÓ** implement `onDmgTaken` | Mở thêm không gian cho AEGIS/BULWARK diễn đạt "khi bị đánh thì…". Các relic thorns/shield hiện phải đi đường vòng qua `onThorns` (`ENG-5`) nên **được xét lại**: cái nào diễn đạt tự nhiên hơn bằng `onDmgTaken` thì chuyển, và `ENG-5` có thể thu hẹp hoặc bỏ. **Việc cần làm ở lượt merge.** |
| **QĐ-3** | **SỬA CẢ 3** bug có sẵn trong cùng bản này | `ENG-0` (thứ tự `modFace`) và `ENG-14` (`a_ult` không crit được) **lên trạng thái bắt buộc**, không còn là "bug có sẵn, tuỳ chọn". Thêm bug thứ 3 — giá shop `rar:4` ở `src/engine.js:858` — vào danh sách, dù roster này ship 0 relic `rar:4`: sửa nó **mở lại tầng Mythic** cho các bản sau. |

## 20. THAY ĐỔI KHUNG XẢY RA TRONG LÚC ÁP AUDIT — 2026-09-03

Bốn thay đổi ở `relic-system.md` landed **sau** khi §6.7 được viết và **trong lúc** tài liệu này áp
audit. Ghi lại vì chúng đổi kết luận, và vì đây chính xác là loại trôi dạt mà một bảng tóm tắt cũ
sẽ che mất.

| # | Thay đổi khung | Ảnh hưởng tới tài liệu này |
|---|---|---|
| **1** | **`r_wildfire` bị AC-9 đẩy lên RARE** (`burnSlow` là `mload 1`, mà `mload > 0 ⇒ rar ≥ 1`) | ❌ **Huỷ một chỉ thị của §6.7.6.** `r_tinderbox` **giữ COMMON `+2`** thay vì lên RARE `+3`. Tiền đề của chỉ thị ("`r_wildfire` xuống COMMON") đã đảo chiều. **37 chỉ thị đã áp → 36 có hiệu lực.** |
| **2** | **`INV-9`**: RP chỉ được dựa trên cơ chế **LIVE** trong `src/engine.js`, hoặc **PENDING** kèm `eng: '<ENG-id>'`; nếu không ⇒ **DEAD**, hard-fail | ✅ **Đã thoả.** Mọi relic dùng field chưa tồn tại đều mang nhãn 🔧 **ENG-n** trên tiêu đề (21 mục ở §16). Hai entry PLAGUE mới dùng `modDmg`/`modFace` — LIVE. |
| **3** | **Biên dải làm tròn VÀO TRONG, có tính quy phạm**: RARE [15.89, 21.48], LEGENDARY [31.77, 42.97] | ✅ **Không entry nào đổi kết luận.** Hai ca sát biên đã kiểm lại: `r_worldpiercer` 42.86 (cách trần **0.11**) và `r_windlash` (bản trước 21.55, vượt trần RARE 0.07 ⇒ vẫn phải lên EPIC). |
| **4** | **CONDUIT tự lấp được slot RARE** | ✅ Mục §0.4 #1 và cảnh báo ⚠️ ở §4.1b **đóng lại**; không cần phán quyết của product owner nữa. |

🔒 **Bài học vận hành, đáng ghi hơn cả bốn dòng trên:** ba trong bốn thay đổi này bắt nguồn từ
`tools/t_relic.mjs` chứ không từ đọc lại tài liệu. Công cụ đã (a) tái tạo độc lập con số **37/48 vi
phạm** của §6.7 bằng đường đi khác, (b) bắt `r_tinderbox` lệch giữa hai tài liệu, (c) chỉ ra §6.7 bỏ
trống `mload`/`ex` cho 48/94 relic khiến hai bất biến chống-stack chỉ kiểm được nửa roster — khoảng
trống mà §17.2 của tài liệu này nay đã lấp đủ. **Không con số RP nào trong tài liệu này được coi là
đúng cho tới khi `t_relic.mjs` xác nhận.**
