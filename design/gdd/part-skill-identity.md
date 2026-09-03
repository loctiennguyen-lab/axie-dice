# PART SKILL IDENTITY — Signature Parts + Variant Families

> **Status**: Thiết kế mới, chưa implement. Thay thế `design/gdd/part-tier-system.md` ở phần "part → face".
> **Author**: `game-designer` (2026-09-03). **Revision 3** (2026-09-03, sau 4 yêu cầu mới của product owner):
> **R1** phủ đủ 285 part ở mức **engine-distinct** (§3.13 viết lại, luật mới R7/R8 ở §3.5c, SPREAD pass ở §3.5d) ·
> **R2** ghim dải scarcity vào `1× → dưới 2×` và nói rõ **đại lượng nào bị ghim** (§3.4-bis, F1b) ·
> **R3** thay cờ nhị phân `specialGenes` bằng **thang 8 bậc có thứ tự** (§3.4a viết lại, F1c) ·
> **R4** biến §3.9 thành **lộ trình 5 giai đoạn mở Ranked cho Vault Axie**, không còn là một board song song.
> Revision 2 (cùng ngày) sửa 18 defect của design review, thêm coherence (§3.4b) và gene tier (§3.4c),
> hạ ngân sách gốc để power bám thang `HEROES` (§4 F1), và chuyển toàn bộ **số suy diễn** ra `tools/gen_faces.mjs` (§6f).
> **Scope**: 3 bề mặt — (1) đường vault-import `axieToDie()` (`src/engine.js:86`), (2) `FACE_POOL` (`src/data.js:203`),
> (3) đường tăng trưởng trong run của Axie import (`genRewards`/`mkReward`/`buildUnit`, §3.4c).
> **NGOÀI scope, không đổi gì**: 18 `HEROES` starter dice · Origin Gene Shard shop pool ·
> phân phối reward của đội hình **toàn hero** (§3.4c chứng minh nó không đổi một bit nào).
>
> **Quy ước tham chiếu code (đổi ở revision 2)**: **tên symbol là nguồn sự thật, số dòng chỉ là gợi ý.**
> Số dòng trong doc này được **re-pin tại commit `438e944`** (2026-09-03) và đã verify từng cái theo tên symbol
> — bản trước pin ở `60c05ee` và đã lệch 20–50 dòng, có chỗ mâu thuẫn nội bộ (cùng một symbol hai số khác nhau).
> Để lỗi này không tái diễn, `tools/gen_faces.mjs --check-citations` (§6f) grep từng `file.js:NNN` trong doc
> theo tên symbol đi kèm và **fail build** nếu lệch (AC-33). Đừng sửa số dòng bằng tay nữa.

---

## 0-bis. ĐỌC TRƯỚC — "239" là số TEMPLATE, không phải số FACE

Câu hỏi của product owner: *"tại sao đã thiết kế được 239 face rồi mà lại không thiết kế trọn vẹn 285 face để cover trọn hết toàn bộ các part."*

Cách doc revision 2 đặt tiêu đề đã **mời gọi đúng sự hiểu nhầm này**, nên sửa ngay ở đây, trước mọi thứ khác. Có **ba** cơ sở đếm, và chúng đo ba thứ khác nhau:

| # | Cơ sở đếm | Hiện trạng | Hệ này | Đây có phải "số skill người chơi thấy" không? |
|---|---|---|---|---|
| 1 | **Template được authored** — số dòng designer viết ra | 36 | **239** = 158 family variant + 81 signature | ❌ Không. Một variant template **nở ra 1–3 face** (mỗi bucket một giá trị) |
| 2 | **Identity phân biệt** — 285 part có ra 285 face khác nhau không, khi tính cả `cls` | 36 → thực chất mọi part cùng `(slot, class)` ra **y hệt** | **285 / 285** — đã bảo đảm bởi R1 (§3.5c) + F6 monotone, và `AC-9b` assert đúng con số này | ⚠️ Gần, nhưng **engine không thấy `cls`** |
| 3 | **Face engine phân biệt** — tuple `(p, t, v, k)`, **bỏ `cls`** | **19** (đếm tay, §3.13) | **190** hôm nay *(đo bằng `gen_faces.mjs`)* → **285** là mục tiêu R1 | ✅ **Đây mới là số thật.** Engine `doFace()` chỉ đọc `(p, t, v, k)` |

**Nên câu trả lời đúng cho product owner gồm hai nửa:**

1. **Phủ trong-họ đã trọn vẹn rồi.** 239 không phải "239 trên 285 part được thiết kế, còn 46 part bị bỏ". Mỗi part trong 285 part **đều** có một face riêng: 81 part đi đường signature (mỗi part một face hand-designed), 204 part đi đường variant (mỗi part một `(variant, bucket)` riêng biệt trong họ của nó). `AC-9b` assert **285 tuple `(cls,p,t,v,k)` phân biệt** — không part nào bị bỏ rơi.
2. **Nhưng ở cơ sở đếm mà engine thực sự dùng, hệ chỉ đạt 190/285** (đo bằng `tools/gen_faces.mjs --no-r7`, §3.13b). **95 part** rơi trùng lên một face đã có của một **class khác, cùng slot** — ví dụ `mouth dmg 6` của Plant và `mouth dmg 6` của Beast là **một** face với `doFace()`. **Đó chính là khoảng trống thật mà câu hỏi chỉ ra, và revision 3 đóng nó** bằng ba bất biến mới: R7/R8 (§3.5c) cho variant, `SIG_LIFT` (§3.3c) cho signature, cộng SPREAD pass ở generator (§3.5d). Mục tiêu và AC: **285/285**, không phải một sàn.

**Số headline chính thức từ revision 3 trở đi**: **285 face engine-distinct trên 285 part** (cơ sở 3). 239 vẫn được nêu, nhưng chỉ như *khối lượng authoring*, không bao giờ như *độ đa dạng người chơi cảm nhận*.

---

## 0. SUPERSEDES / INVALIDATES

Doc này **không sửa** file nào. Danh sách dưới đây là việc cần làm ở pass tiếp theo.

| Tài sản | Trạng thái sau doc này | Việc cần làm |
|---|---|---|
| `design/gdd/part-tier-system.md` §2a (bảng 36 template) | **Superseded toàn bộ** | Thay bằng §6 doc này |
| `part-tier-system.md` §2c (Rare→Mythic theo 36 ô) | **Superseded toàn bộ** | Thay bằng §6 + §7 doc này |
| `part-tier-system.md` §8 + §9a (gán 192 + 75 part vào 36 ô) | **Superseded** — vẫn dùng lại được như *nguồn flavour đã đọc tay* khi curate `PART_VARIANT` | Chuyển hoá sang bảng §7 |
| `part-tier-system.md` §9b (111 part α → danh tính Mythic) | **Superseded** — α không còn là "danh tính Mythic", α là **scarcity bucket O** (§3.4) | Xoá khái niệm "α = Mythic" |
| `part-tier-system.md` §2b công thức `value=(budget−kw)/rate` | **Giữ làm backbone**, mở rộng thêm trục scarcity + slot modifier + class surcharge (§Formulas) | Cập nhật §2b theo §Formulas doc này |
| `tools/gen_parts.py` | **Invalidated** — sinh ra 36-cell data | Viết lại thành `tools/gen_faces.mjs` (Node, khớp toolchain `tools/*.mjs`) sinh `assets/data/part_faces.json` |
| `docs/axiedice-source/economy/parts_build_data.json` | **Dead artifact** — không file nào import (đã verify bằng grep) | Xoá hoặc thay bằng output mới |
| `docs/axiedice-source/economy/PART_REVIEW_SHEET.md` | Bảng duyệt 192 dòng ở granularity cũ | Regenerate ở granularity 285 |
| `src/data.js:112-199` (`SLOT_CLASS_TEMPLATE`, comment "KHÔNG cá nhân hoá theo part.name") | **Xoá** — comment đó là chính thứ product owner bác bỏ | Thay bằng `PART_VARIANT` + `SIGNATURE_FACE` |
| `src/data.js:199` `ORIGIN_TIER3_MULT = 2.2` | **Xoá** — thay bằng `SCARCITY[bucket].S` (§3.4) | 2.2× không suy từ đâu cả, và nó **nhân dồn** với bug `specialGenes` (E16) thành tới 2.86×. Xem E15 (đã viết lại — **không có đền bù**) |
| `src/data.js:203` `FACE_POOL` — **giá trị** của face khi rơi vào tay Axie import | **Superseded ở đường import** | 50 số của `FACE_POOL` **không đổi** (nó là drop pool, đang chạy live). Nhưng đường import **không** copy nguyên xi `v` nữa: nó nhân `SIG_IMPORT_SCALE` (§3.3, F7b). Đây là thay đổi so với revision 1 |
| `src/engine.js:694` `genRewards` nhánh `if(canLevel.length) … else pool.push('ascend','ascend')` | **Superseded** | Axie import không có entry `TIER_UP` nên **không bao giờ** nhận `'level'`, và `'ascend'` chỉ vào pool khi **không** hero nào lên tier được → import bị bỏ đói cả run. Thay bằng reward `'gene'` (§3.4c). **Đội toàn hero: 0 thay đổi** |
| `src/engine.js:42` `buildUnit` — `die:clone(h.die)` | **Mở rộng** | Axie import phải **dựng lại** die từ `parts` + `geneTier` thay vì clone snapshot đóng băng (§3.4c). ~4 dòng, vẫn pure |
| `META.vault[i]` schema | **Superseded — schema 3** | Entry Vault phải lưu **`parts` manifest đã verify**, không chỉ die đã resolve. Cần cho §3.4c (dựng lại die) *và* §3.9e bước 4 (server rebuild). Một migration phục vụ hai yêu cầu |
| `design/gdd/economy-progression.md` — faucet Shard đền bù | **Không còn** | Revision 1 đề xuất đền bù 150 Shard/bậc rarity mất (E15 phương án C). Product owner đã **bác bỏ đền bù**. Knob `K20` bị xoá, `§6e` không còn dòng propagate sang economy |
| `assets/data/part_faces.json` + `part_faces_tuning.json` | **Tài sản MỚI, là nguồn sự thật của mọi số suy diễn** | Doc này chỉ còn sở hữu **design input** (bảng §3.11 `t · k`, bảng §3.12 gán part, hằng số §4). Mọi cột số theo bucket, danh sách monotone-lift, số đếm distinct-face → do `tools/gen_faces.mjs` sinh và **commit làm snapshot** (§6f, AC-7d) |
| `design/gdd/relic-system.md` + `relic-roster-expansion.md` | **Đang được thiết kế song song** | Doc này **không** giả định danh sách 44 relic hiện tại. Mọi chỗ phụ thuộc relic đều nêu **tên phụ thuộc**, không nêu số (§6d) |
| `src/data.js:6` header comment liệt kê `shieldself:N` | **Sai sự thật** — keyword này chưa bao giờ được implement (verify: grep `shieldself` trong `src/` chỉ khớp đúng dòng comment đó) | Xoá khỏi comment, hoặc implement (§NEW ENGINE WORK) |
| `design/quick-specs/import-axie-variants-2026-09-03.md` + `PART_VARIANT_MODS` (`src/data.js:183-192`) + `hashPartIdentity`/`applyPartVariant` (`src/engine.js:70-85`) | **Superseded — ĐÃ SHIP trong lúc soạn doc này** (commit trong nhánh, 2026-09-03). Đó là bản vá nhỏ cùng vấn đề: giữ nguyên 36-cell rồi chồng lên `±1 value` hoặc `+1 keyword` chọn bằng **hash** `part.name`. Nó **không** đạt yêu cầu product owner ("skill khác nhau thật"): 2 Beast Mouth vẫn ra `dmg 3` / `dmg 3 crit:15` / `dmg 4` — cùng type, cùng bậc, khác 1 điểm. Và nó dùng **hash**, trái nguyên tắc curated/auditable của doc này. **Đã kiểm: nó KHÔNG vi phạm §3.7a** (`thorns:1` chỉ trên `shield`, `regen:1` chỉ trên `heal`, còn `crit:15`/`aoe`/`rerollup` đều ngoài kwPure) → không phải bug, chỉ là chưa đủ | Xoá `PART_VARIANT_MODS`, `hashPartIdentity`, `applyPartVariant` khi implement §3.6. Đánh dấu quick-spec là superseded. **Lưu ý nhỏ đã phát hiện**: `debuff`/`buff` nhận `{dv:1}` làm `v` từ `0`→`1`, và `src/ui.js` render `if(f.v)` nên ~1/2 part debuff hiện hiển thị số "1" vô nghĩa trên mặt dice |
| `design/gdd/leaderboard-system.md` §"Loại bảng xếp hạng" (Standard/Collector) | **Vẫn đúng ý định, nhưng chưa ship** — thực tế `api/submit-run.js:135` chỉ có 1 board `lb:mode:asc` | §3.9 doc này định nghĩa chính xác Collector board cần gì |
| `design/gdd/economy-progression.md` §10.2b | Vẫn đúng về **quyền truy cập** (285 NFT-locked, 111 α mua Shard). Doc này **không** đổi quyền truy cập, chỉ đổi *face nào sinh ra* | Không cần sửa |

**Bổ sung ở revision 3** — bốn yêu cầu mới của product owner supersede thêm những mục sau:

| Tài sản | Trạng thái sau revision 3 | Việc cần làm |
|---|---|---|
| §3.5c **luật R6** (keyword-set uniqueness *trong họ*) | **Superseded — trở thành hệ quả của R7** | R7 (§3.5c) mở R6 từ phạm vi *family* lên phạm vi *slot*. R6 vẫn đúng nhưng không còn là bất biến độc lập; `I5` đổi thành kiểm R7 |
| §3.4a `isSpecialGene()` → `SG_BONUS = 0.28` phẳng | **Superseded toàn bộ** | Thay bằng `SG_LADDER` 8 bậc + `sgTier()` + `G(tier)` nhân tính (§3.4a, F1c). Knob `K6` bị thay bằng `K28`/`K29` |
| §4 F1 `B_CAP0 = 4.76` (1.70×) | **Superseded** | `B_CAP0 = 5.11` (**1.824×**), suy từ `S_MAX × G_MAX` (F1b). Vẫn `< 2.00×` theo yêu cầu R2 |
| §4 F1a "ba trần, ba lập luận" | **Superseded** | Thay bằng F1b: **ba đại lượng có tên**, và nói rõ đại lượng nào chịu ràng buộc `< 2×` (`SPREAD_OWN`), đại lượng nào **không** (`SPREAD_STATIC`, `SPREAD_RUN`) và vì sao |
| §3.4b keyword suppression = **xoá** keyword | **Superseded** | Suppression đổi thành **thay thế** (`SUPPRESS_SWAP`, §3.4b). Xoá keyword có thể **gộp hai face phân biệt thành một** → phá R7. Đây là defect thật do R1 phát hiện |
| §3.9 "Collector board song song" | **Superseded về khung** | Cơ chế L2/L3 giữ nguyên; nhưng §3.9 giờ là **lộ trình 5 giai đoạn** kết thúc bằng Vault Axie vào **chính** Ranked, không phải một board vĩnh viễn tách biệt. L1 (loại tuyệt đối) được ghi rõ là **biện pháp beta**, không phải thiết kế vĩnh viễn |
| `AC-9c` sàn `>= 76` | **Superseded** | Thành đẳng thức chính xác `=== 285` (AC-9c viết lại). Sàn có động cơ được giữ làm *chẩn đoán*, không còn là điều kiện pass |
| `AC-19` mốc `29/30` (và `28/30` trong session notes) | **Cả hai đều SAI — đã đo lại** | `tools/verify.mjs` = **32/32 PASS** (Phase A 21 · B 10 · C 2 · D 1). AC-19 assert 32/32, kèm đúng câu lệnh chạy (§8) |
| `assets/data/special_genes.json` | **Tài sản MỚI, BLOCKING** | Bảng ánh xạ chuỗi API → bậc thang. Doc này **không** hardcode enum vì chưa verify được (E16-bis) |

**Không supersede**: `axie-body-parts.md` (nguồn danh tính, doc này đọc nó làm input), `parts_full_source.json` (nguồn dữ liệu, giữ nguyên), `bloodline-system.md`, `game-concept.md`.

---

## 1. Overview

Hệ thống này quy đổi **một part Axie NFT thật → một mặt xúc xắc**, thay thế bảng `SLOT_CLASS_TEMPLATE` 36 entry hiện hành (nơi mọi Beast Mouth đều ra cùng một face). Mỗi part được phân vào một trong hai đường: **Signature part** (63 part 6-class + 18 part secret-class có danh tiếng văn hoá cao — nhận một face hand-designed **độc nhất**, dùng chung vốn từ với `FACE_POOL`), hoặc **Family variant** (204 part còn lại — mỗi part được gán **tất định, thủ công, có thể audit** vào một trong 4–6 variant được thiết kế riêng cho đúng `(class, slot)` family của nó).

Sức mạnh của face đi qua **bốn trục trực giao**, mỗi trục có một nguồn tín hiệu khác nhau và một trần riêng:

| Trục | Tín hiệu | Trả lời câu hỏi | Dải | Mua được bằng tiền? |
|---|---|---|---|---|
| **Scarcity bucket** (§3.4) | trường `stage` của catalog thật | *Bạn sở hữu part gì?* | ×1.000 → ×1.600 | ✅ có |
| **`specialGenes` ladder** (§3.4a) | thuộc tính cá thể NFT, **8 bậc có thứ tự** | *Part đó mang gene gì?* | ×1.000 → ×1.497 (+7.1%/bậc) | ✅ có |
| **Coherence / purity** (§3.4b) | 6 part có khớp class thân không | *Con Axie có "thuần" không?* | ×0.82 → ×1.00 | ❌ **không** — Axie thuần Classic là loại **rẻ nhất** trên thị trường |
| **Gene tier** (§3.4c) | reward kiếm được **trong run** | *Bạn đã chơi bao xa với nó?* | +0.53 ngân sách/bậc, 6 bậc | ❌ không — chơi mới có |

**Yêu cầu R2 của product owner** được áp lên **đúng một đại lượng có tên**, và doc nói rõ vì sao đúng đại lượng đó (F1b). Product owner đã **nới trần từ 2.00× lên 2.40×** để đổi lấy một thang gene đọc được bằng số (§3.4a-1):

```
SPREAD_OWN  =  S_MAX × G_MAX  =  1.600 × 1.497  =  2.395×      ← ĐẠI LƯỢNG BỊ GHIM, phải < 2.40
```

`SPREAD_OWN` là tỉ số giữa **cấu hình đắt nhất** và **cấu hình rẻ nhất** khi *mọi thứ khác bằng nhau* (cùng purity, cùng gene tier). Đó chính xác là "hai người chơi cùng trình độ, một người giàu" — đại lượng pay-to-win. Coherence **triệt tiêu** khỏi tỉ số này vì nó có ở cả tử lẫn mẫu và **không mua được**; trục gene tier không thuộc về nó vì nó không phải cái sở hữu.

⛔ **Bất đẳng thức "play > money" ĐÃ BỊ THU HỒI (2026-09-03).** Product owner: *"tôi chấp nhận việc pay to win - chúng ta không cần chống lại những người chi tiền mạnh."* Doc **không còn** hứa rằng một Axie miễn phí đã chơi sẽ vượt một Axie đắt tiền chưa chơi. Chi tiết những gì bị bỏ, và ghi chú chống-"khôi phục-nhầm", ở **F1b-α**.

Cái giá của quyết định 2.4×, nói thẳng: ở cùng trình độ, cùng độ thuần, cùng tiến độ run, **người giàu mạnh hơn ≈2.4× trên mỗi mặt dice**, và một Axie mua đắt **khởi đầu run ở 1.07× hero tier-3** — xấp xỉ sức mạnh cuối game của một hero, ngay từ wave 1. Đây là hành vi **đúng theo thiết kế**, không phải khuyết điểm.

Ràng buộc cứng **còn lại** trên trục power là một cái duy nhất, và nó thuộc về combat chứ không thuộc về công bằng:

```
TTK_CEIL_T3 = B_CAP_RUN × 1.018 / 6.39 = 7.20 × 1.018 / 6.39 = 1.15×      (I23)
```

Die mạnh nhất tồn tại trong game không được vượt **1.15× avg face của hero tier-3**, vì `CURVE.budget` / `mkMonster` / `mkBoss` không đổi và được hiệu chuẩn cho thang hero. Chấp nhận người giàu mạnh hơn **không** kéo theo chấp nhận quái vật thành bao cát.

Ba thứ **không** bị quyết định này đụng tới: **chống gian lận** (`AC-1` vẫn BLOCKING — replay server chặn điểm bịa, không chặn chi tiền), **mô hình ngân sách/ngang giá** (R1/R6/R7/R8, monotone, dải ±) và **trần TTK**. Xem F1b-α để biết ranh giới chính xác.

Toàn bộ con số đến từ công thức ngân sách `v = (B_eff − TYPE_COST − KW) / R_role`, nên bảo đảm ngang giá là **cấu trúc**, không phải tuning. Ngân sách gốc `B[C] = 2.80` được neo vào **thang `HEROES` tier-1 thật** (avg face value 2.53, xem F2) — nghĩa là một Axie import trộn class hoàn toàn ra **0.92× hero tier-1**, một Axie thuần Classic ra 1.13×, và cuối run (gene 6) đạt 0.95× hero tier-3. Đó là yêu cầu product owner: *"chỉ hơi yếu hơn khi part không khớp nhau"*.

Vì hai trục đầu gắn power vào việc sở hữu NFT, §3.9 định nghĩa **lộ trình 5 giai đoạn mở Ranked cho Vault Axie**. Việc loại tuyệt đối Axie import khỏi Skill board hôm nay là **biện pháp beta của Stage 0, không phải thiết kế vĩnh viễn** — product owner đã nêu rõ ý định mở. Mỗi giai đoạn có: cái được mở, hạ tầng phải có trước, cơ chế công bằng, và **một cổng đo được** phải pass trước khi sang giai đoạn sau. Trục gene tier **không** bị handicap ở bất kỳ giai đoạn nào — nó là cơ hội ngang nhau cho mọi người chơi.

**Về độ phủ 285 part**: xem §0-bis. Tóm tắt — ở cơ sở đếm mà engine thực sự dùng (`(p,t,v,k)`, bỏ `cls`) hệ đạt **190/285** như đang tabled (đo bằng generator), và revision 3 đưa nó lên **285/285** bằng ba bất biến cấu trúc — R7/R8 (§3.5c) cho variant và `SIG_LIFT` (§3.3c) cho signature — thay vì bằng sự cẩn thận của designer. *(Cơ sở `(cls,p,t,v,k)` cũng chỉ đạt 283/285 trước `SIG_LIFT`, không phải 285: xem §3.3c.)*

**Mọi con số suy diễn** (cột value theo bucket, danh sách monotone-lift, số đếm face phân biệt) do `tools/gen_faces.mjs` sinh ra và commit thành snapshot (§6f). Doc chỉ sở hữu **design input**. Đây là bài học trực tiếp từ design review: 3 trong 18 defect có cùng một nguyên nhân gốc — ~474 ô số duy trì bằng tay trong Markdown.

---

## 2. Player Fantasy

**MDA target aesthetics** (thứ tự ưu tiên): **Discovery** → **Expression** → **Fantasy** → **Challenge**.

Fantasy cốt lõi: *"Con Axie của tôi — chính con này, không phải một con Beast nào đó — chiến đấu như chính nó."*

Hệ cũ giết fantasy này ở một khoảnh khắc rất cụ thể và rất tệ: người chơi import con Axie thứ hai, háo hức xem nó khác gì, và thấy **sáu mặt y hệt** con thứ nhất. Đó là một *false discovery* — game hứa "mang NFT của bạn vào đây" rồi trả lời "NFT của bạn không quan trọng". Theo Self-Determination Theory, đó là đòn đánh trực diện vào **Autonomy** (việc chọn import con nào là một choiceless sequence) và vào **Relatedness** (không có mối gắn bó nào với một con vật mà game không phân biệt được).

Ba khoảnh khắc cảm xúc hệ mới phải tạo ra:

1. **Import moment (Discovery)** — quét Axie thứ hai, thấy 6 mặt khác hẳn, và **đọc được tên part thật trên mặt dice** ("Ronin", "Cucumber Slice"). Người chơi nhận ra: kiến thức về Axie ngoài đời là *kiến thức chơi được*. Đây là dạng reward-for-curiosity mà Explorer archetype (Bartle) sống bằng.
2. **Chase moment (Fantasy + Achievement)** — nhìn thấy `⬥ PRIME` trên một mặt dice và biết rằng chỉ **18 part trên toàn bộ 285** đạt được nhãn đó. Chase value không đến từ con số to, mà từ *sự khan hiếm có thể kiểm chứng được*.
3. **Draft moment (Expression)** — vì mặt mutation drop (`FACE_POOL`) và mặt import **dùng chung một vốn từ** (§3.8), người chơi thấy "Piranha" rơi ra giữa run và nhận ra: *đây đúng là part tôi đang có trên con Axie ở Vault*. Hai hệ thống nói cùng một ngôn ngữ → build có ý nghĩa liên tục.
4. **Breeding moment (Expression + Discovery)** — người chơi so hai con Axie mình có và thấy con **thuần class** đánh *sắc* hơn (giữ được `pierce`/`aoe`/`cleave`), còn con **lai tạp** đánh *thô* hơn (số to hơn, ít mánh hơn). Đây là §3.4b, và nó biến việc *chọn import con nào* thành một quyết định thật — đúng chỗ mà hệ cũ có một choiceless sequence. Nó cũng làm cho kiến thức breeding ngoài đời (class purity) trở thành **kiến thức chơi được**, giống như tên part ở khoảnh khắc 1.
5. **Growth moment (Competence)** — giữa run, người chơi nhận reward `GENE EXPRESSION` và thấy **cả sáu mặt của chính con Axie mình viết lại**, mạnh lên, vẫn giữ đúng tên part thật. Không phải một buff `+25%` chung chung dán lên: đó là *bộ gene của nó biểu hiện thêm* (§3.4c). Theo Self-Determination Theory đây là **Competence** đọc được — người chơi thấy chính xác cái gì lớn lên và vì sao. Hệ hiện tại **không có** khoảnh khắc này: một Axie import đóng băng ở tier 1 suốt cả run (verify: `TIER_UP` không có khoá `vault_*`).

**Điều fantasy này KHÔNG được là**: "ai giàu hơn thì mạnh hơn trên leaderboard". Đó là lý do §3.9 tồn tại và là điều kiện không thương lượng của thiết kế này. Trục gene tier (§3.4c) là câu trả lời tích cực cho cùng vấn đề: **cái mạnh nhất trong hệ này là thứ phải chơi mới có, không phải thứ mua được.**

---

## 3. Detailed Rules

### 3.1 Identity key — `partKey`

Mọi tra bảng đều đi qua một khoá duy nhất:

```
partKey(part) = normClass(part.class) + '|' + normSlot(part.type) + '|' + baseName(part.name)
```

- `normSlot(x)` = `x.toLowerCase()`, giá trị hợp lệ: `eyes ears mouth horn back tail`.
- `normClass(x)` = `x.toLowerCase()`; `aquatic` → `aqua`. Giữ nguyên `dawn`/`dusk`/`mech` **ở khoá** (khác với `mapAxieClass()` hiện tại — xem §3.10).
- `baseName(x)` = bỏ hậu tố stage rồi trim: xoá ` α`, `α`, ` +`, `+` ở **cuối** chuỗi, rồi `.trim()`, rồi collapse khoảng trắng đôi. `'Nut Cracker α'` → `'Nut Cracker'`. `'Ronin +'` → `'Ronin'`.
- **Phân biệt chữ hoa/thường**: so khớp **case-sensitive** với catalog, sau khi normalise class/slot. Catalog là nguồn sự thật cho cách viết tên (ví dụ `Hard-boiled` có gạch nối, `Kotaro?` có dấu hỏi thật trong dữ liệu — xem E9).

**Xử lý trùng tên**: `slot` nằm trong khoá, nên `Nut Cracker` ở Beast·Mouth / Beast·Tail / Beast·Eyes / Beast·Ears là **4 identity riêng biệt, 4 face khác nhau**. `class` nằm trong khoá nên trùng tên xuyên class (nếu Axie thêm sau này) cũng không đụng nhau. Đây là điều `SLOT_CLASS_TEMPLATE` không cần lo vì nó không đọc tên — và là lỗi đầu tiên phải tránh khi implement.

**Tổng số identity trong catalog thật**: **285** (verify: `parts_full_source.json` có đúng 285 row `stage:1`, và mọi identity đều có ít nhất một row stage 1 — không identity nào chỉ tồn tại ở stage 0 hoặc stage 2).

### 3.2 Hai đường: Signature vs Family

```
resolve(part):
  k = partKey(part)
  if SIGNATURE_FACE[k] exists  → Signature path (§3.3)
  else if PART_VARIANT[k] exists → Family path (§3.5 + §3.6)
  else                          → Fallback (§Edge Cases E1)
```

Hai đường **loại trừ nhau tuyệt đối**. Một part không bao giờ vừa là signature vừa là variant. `SIGNATURE_FACE` và `PART_VARIANT` phải có tập khoá rời nhau — đây là một AC kiểm được (AC-3).

| Đường | Số part | Face đến từ | Có scale theo scarcity? |
|---|---|---|---|
| **Signature** | 63 (6-class) + 18 (secret) = **81** | `SIGNATURE_FACE[k]` — hand-designed, cố định | **KHÔNG** (§3.3) |
| **Family variant** | **204** | `FAMILY_VARIANT[class][slot][v]` + công thức ngân sách | **CÓ** (§3.4) |

### 3.3 Signature roster — luật đủ điều kiện

**Luật (auditable, một danh sách duy nhất)**:

> Một part là **Signature** khi và chỉ khi `baseName` của nó nằm trong **Icon List** của project, và `(class, slot)` của nó khớp đúng cặp đã ghim trong Icon List.

Icon List = **50 tên trong `FACE_NAMES`** (`src/data.js:238`) **+ 13 tên Addendum** (§3.3b). Không có luật suy diễn nào khác, không hash, không heuristic. Muốn thêm/bớt signature → sửa Icon List, một chỗ.

**Tại sao chọn luật này** (thay vì "part hiếm nhất thì signature"):
- 50 tên đó **đã được một pass thiết kế trước curate vì tính iconic** (`src/data.js:235-237`) và đã có face tuned sẵn trong `FACE_POOL`. Dùng lại chúng làm signature khiến yêu cầu "drop và import dùng chung một vốn từ" (scope decision 3) **được thoả mãn bởi kiến trúc**, không phải bởi công sức đồng bộ thủ công.
- Nó tách sạch hai trục: **iconicity → face độc nhất** · **scarcity → hệ số power**. Nếu để part hiếm nhất tự động thành signature thì hai trục dính vào nhau, và một whale sở hữu part Prime sẽ nhận cả face độc nhất *và* power multiplier — cộng dồn đúng cái §3.9 phải chống.
- Đã verify: **cả 50 tên trong `FACE_NAMES` đều khớp `slot` của part thật tương ứng** với face nó được gán trong `FACE_POOL` (ví dụ `'Piranha'` gắn face `p:'mouth'` và Piranha thật là Aquatic·Mouth). Đây không phải may mắn — pass trước đã cẩn thận. Nghĩa là **không cần đổi một con số nào** của 50 face đó.

**Signature KHÔNG scale theo scarcity.** Power của một signature face đã do rarity tier của nó trong `FACE_POOL` quy định (r0..r4). Nhân thêm scarcity sẽ tạo ra Mythic 1.6× — trần power tệ nhất của cả hệ. Ghi rõ: `Wing Horn` (r4, `dmg 20 pierce echo`) là Classic-bucket, và **không có đường nào** để nó thành 32 damage.

**NHƯNG signature CÓ scale theo `SIG_IMPORT_SCALE` — thay đổi so với revision 1, và nó bắt buộc.**

Revision 1 nói signature face "copy nguyên xi từ `FACE_POOL`, zero rủi ro balance". Điều đó đúng **khi và chỉ khi** variant face cũng ở thang `FACE_POOL` (ngân sách gốc 6.0). Revision 2 hạ `B[C]` xuống **2.80** để bám thang `HEROES` tier-1 (F1, F2). Nếu signature vẫn giữ số `FACE_POOL` thì:

- một `Zigzag` (r0, `dmg 6`) mạnh **gấp đôi** một variant Prime cùng slot — nghĩa là *iconicity* trở thành trục power lớn hơn *scarcity*, ngược hẳn với §3.3 khoản 2;
- một `Pocky` (r4, `dmg 26`) trên die của một Axie ở **wave 1** là một face endgame — `FACE_POOL` r4 được cân bằng để rơi ở `band=[2,4]`, tức cuối run, chứ không phải lúc bắt đầu;
- và nó phá đúng yêu cầu product owner của revision 2 ("import không được mạnh hơn hero đáng kể").

Nên đường import **không copy `v`**, nó copy *danh tính*:

```
SIGNATURE_FACE[k] cho một Axie import:
  p, t, k[], r   ← copy NGUYÊN XI từ FACE_POOL / bảng §3.3b / bảng §3.10
  v              ← max(1, round( v_pool × SIG_IMPORT_SCALE × CoherenceMod ))
  SIG_IMPORT_SCALE = B[C] / B_REF = 2.80 / 6.00 = 0.4667
```

Ba điều **không** đổi, và đó là điểm mấu chốt: `FACE_POOL` (drop pool) vẫn giữ nguyên 50 con số của nó (AC-7c vẫn BLOCKING); type + keyword set + rarity colour của signature vẫn nguyên xi, nên "Wing Horn là Wing Horn"; và signature vẫn **không** nhận bucket multiplier. Thay đổi duy nhất: cùng một face, ở **đường drop** là `dmg 20`, ở **đường import** là `dmg 9`. Người chơi vẫn thấy cùng tên, cùng màu, cùng bộ keyword — đúng yêu cầu "hợp nhất vốn từ" (scope decision 3), vì vốn từ là `(p, t, k, r)`, không phải `v`.

> **Vì sao 0.4667 phẳng, không theo rarity**: nhân phẳng giữ nguyên **tỉ lệ** giữa r0…r4, nên thang iconicity vẫn là 6.0 → 17.0 (2.83×) đúng như F7 — nó chỉ được dịch xuống cùng thang với variant. Nếu scale theo rarity thì r4 sẽ bị nén và `Pocky` mất đúng cái làm nó là `Pocky`.

#### 3.3c. `SIG_LIFT` — chống sập bậc ở đuôi dưới (MỚI, revision 3, do generator phát hiện)

**Sự cố đã đo** (`tools/gen_faces.mjs`, 2026-09-03): `AC-9b` đổ ở **283/285**. Hai cặp part khác nhau resolve ra cùng một face:

| cặp | `v` trong `FACE_POOL` | `× 0.4667` | `max(1, round(·))` | kết quả |
|---|---|---|---|---|
| `aqua\|ears\|Gill` / `aqua\|ears\|Bubblemaker` | 2 / 3 | 0.933 / 1.400 | **1** / **1** | cùng `mana 1 · cantrip` |
| `bird\|eyes\|Mavis` / `bird\|eyes\|Robin` | 1 / 2 | 0.467 / 0.933 | **1** / **1** | cùng `summon 1 · cantrip` |

**Nguyên nhân, phát biểu tổng quát**: `SIG_IMPORT_SCALE = 0.4667` làm lưới số nguyên ở đuôi dưới có bước ≈ `1 / 0.4667 = 2.14` đơn vị pool. Hai face legacy cách nhau **< 2.14 điểm pool** ở vùng thấp **buộc phải** rơi vào cùng một số nguyên. Cộng với sàn `max(1, ·)`, mọi face có `v_pool ≤ 3` đều bị hút về `1`.

> **Đây đúng là lỗ hổng mà R7 và `I24` được dựng lên để bịt — nhưng ở phía signature.** Với variant, doc đã chuyển tính phân biệt sang trục keyword để nó không phụ thuộc `B[C]`. Với signature, tính phân biệt vẫn nằm **hoàn toàn ở `v`**, và `v` phụ thuộc `SIG_IMPORT_SCALE = B[C]/B_REF`. Hạ `B[C]` 6.00 → 2.80 vì thế mở lại đúng cái lỗ vừa bịt, ở đúng tập face mà SPREAD **không được phép** đụng.

##### Vì sao đây KHÔNG cần ngoại lệ cho `AC-7c` — điểm mấu chốt

`AC-7c` bảo vệ **`FACE_POOL`** — mảng drop pool đang chạy live. Nhưng giá trị signature trên **die import** *chưa bao giờ* bằng giá trị pool: §3.3 đã nhân `SIG_IMPORT_SCALE` từ revision 2 (`Wing Horn` là `dmg 20` khi rơi, `dmg 9` khi import). Nghĩa là **đường chiếu import là một hàm, không phải một bản sao** — và sửa hàm đó không đụng một byte nào của `FACE_POOL`.

⇒ Không cần nới `AC-7c`, không cần ngoại lệ cho SPREAD. Sửa nằm ở **F7b (phép chiếu)**, không ở dữ liệu. `AC-7c` giữ nguyên hiệu lực BLOCKING.

##### Luật `SIG_LIFT` — tái dùng đúng cấu trúc của F6

Áp **trước** REPAIR và SPREAD, để hai pass đó nhìn thấy giá trị legacy đã ổn định:

```
GROUP: gom mọi signature face theo khoá  (p, t, sortedKeys)      // KHÔNG gồm cls — xem dưới
  trong mỗi nhóm, sort tăng dần theo v_pool (tie-break: tên face, thứ tự chữ cái)
  out[0] = max(1, round(v_pool[0] × SIG_IMPORT_SCALE))
  out[i] = max(out[i-1] + 1, round(v_pool[i] × SIG_IMPORT_SCALE))     // monotone BY CONSTRUCTION
  nếu out[i] − round(v_pool[i] × SIG_IMPORT_SCALE) > SIG_LIFT_MAX (= 3):  HARD FAIL
```

Bốn tính chất, mỗi cái có lý do:

1. **Monotone do cấu trúc, không phải pass sửa lỗi** — cùng khuôn với F6 (§4). `out[i]` không thể tồn tại ở giá trị vi phạm thứ tự, kể cả trong trạng thái trung gian.
2. **Giữ đúng thang thiết kế.** `Bubblemaker` **luôn** mạnh hơn `Gill`, `Robin` **luôn** mạnh hơn `Mavis`. Thứ tự đó *là* thiết kế của `FACE_POOL` (một thang rarity hand-tuned); nén nó mất là xoá thông tin, không phải cân bằng nó.
3. **Nhóm theo `(p, t, sortedKeys)`, bỏ `cls`.** Nhóm hẹp hơn (kèm `cls`) đủ cho `AC-9b` nhưng **không đủ cho `AC-9c`**: `Neo` (`bug|eyes`, `summon 3 · cantrip`) cũng rơi về `1`, nên ở cơ sở engine-distinct nó chồng lên `Mavis`/`Robin`. Bỏ `cls` khỏi khoá nhóm giải cả hai AC bằng một luật.
4. **Chỉ chạm face thực sự đụng nhau.** Nhóm cỡ 1 → `out = max(1, round(·))`, y hệt trước. **45/50 face legacy không đổi một đơn vị nào.**

##### Tập bị ảnh hưởng — SỐ CỦA MÁY, không phải ước lượng tay

> 🔧 **Bản đầu của mục này viết "chỉ có **hai** nhóm cỡ > 1" và đó là ĐẾM THIẾU NẶNG — thực tế là bảy.** Tôi liệt kê tay và chỉ tìm được các nhóm mình nhớ ra. Cùng hạng lỗi với phép đếm 201 và với danh sách bộ cấm `mouth` — **liệt kê tay tập con của một dataset là thao tác con người làm sai một cách hệ thống**, và đây là lần thứ ba trong cùng tài liệu. Số dưới đây là output `gen_faces.mjs`, chép nguyên văn, **không suy lại**.

**Profile PRODUCTION — 10 face được lift:**

| face | `v` trước → sau |
|---|---|
| `Bubblemaker` | 1 → **2** |
| `Robin` | 1 → **2** |
| `Neo` | 1 → **3** |
| `Nyan` | 1 → **2** |
| `Friezard` | 2 → **3** |
| `Snail Shell` | 3 → **4** |
| `Cerastes` | 3 → **4** |
| `Zigzag` | 3 → **4** |
| `Tiny Dino` | 2 → **3** |
| `Mainspring` | 3 → **4** |

**Profile THAM CHIẾU — 5 face**: `Nyan` 3 → **4** · `Cerastes` 7 → **8** · `Zigzag` 6 → **7** · `Tiny Dino` 5 → **6** · `Mainspring` 6 → **7**.

Lift tối đa **+2** (`Neo`, production), trong `SIG_LIFT_MAX = 3` ✓. Ba face tôi dự đoán (`Bubblemaker`, `Robin`, `Neo`) rơi đúng như mô tả; bảy face còn lại tôi bỏ sót.

##### `SIG_LIFT` HẤP THU danh sách sửa tay của §3.5d-bis

Đây là hệ quả quan trọng nhất của con số đúng, và nó **xoá việc**, không thêm việc.

Năm va chạm signature↔signature mà §3.5d-bis liệt kê để **sửa tay** — `Cerastes`/`Cactus`, `Zigzag`/`Cub`, `Tiny Dino`/`Black Gourd`, `Mainspring`/`Gila`, `Nyan`/`Harmonious Silence` — **đều được `SIG_LIFT` giải tự động**: cả năm face legacy trong các cặp đó (`Cerastes`, `Zigzag`, `Tiny Dino`, `Mainspring`, `Nyan`) nằm trong tập lift ở trên. Sau lift chúng không còn trùng đối tác Addendum/Secret của mình nữa.

⇒ **Bảng vá tay ở §3.5d-bis bị XOÁ, không phải giữ để đồng bộ.** Lý do là nguyên tắc đã áp ba lần trong doc này: *một bảng không ai phải bảo trì thì không thể trôi*. Nó cùng loại thắng lợi với việc chuyển cột `C/O/P` ra generator (§3.11) và chuyển danh sách monotone-lift ra snapshot (F6). Một danh sách sửa tay mô tả các sửa đổi **chưa từng được áp vào bảng nguồn** — đúng lỗi mà tôi đã mắc với `Cactus`/`Cub`/`Nutdha Statue` — là gánh nặng thuần tuý khi cơ chế tự động đã bao trọn nó.

**Giữ lại đúng một dòng** từ bảng cũ, vì nó *không* thuộc phạm vi `SIG_LIFT`: sửa `Cactus` từ `dmg·pierce·regen:1` sang `dmg·pierce·growth` — đó là một vi phạm **hướng kwPure** (§3.7a: `regen` trên face `dmg` hồi máu cho **địch**), không phải một va chạm giá trị. `I8` bắt nó, `SIG_LIFT` thì không.

> **Lạm phát power của `Neo`, nêu thẳng**: `summon 3` thay vì `summon 1` trên die import là **+2 token**. Chấp nhận được vì (a) `Neo` là 1 trong 8 face Mythic legacy và §3.8 đã miễn trừ ngân sách cho toàn bộ 50 face legacy — đây là chính sách sẵn có, không phải ngoại lệ mới; (b) `summon` có trần 4 token cứng trong engine (`doFace`), nên +2 không mở ra đường vô hạn; (c) nó ảnh hưởng đúng **1** part trên 285. Nếu sim (AC-28) cho thấy `Neo` lệch, knob là `SIG_LIFT_MAX`, **không** phải `SIG_IMPORT_SCALE` — hạ scale sẽ làm sập bậc trở lại.

##### Chống tái phát khi `B[C]` đổi — đây là điều kiện của yêu cầu

Sửa mà chỉ xoá hai va chạm hôm nay thì lần tune tới sẽ hỏng lại. `SIG_LIFT` **không** hardcode face nào: nó tính nhóm từ dữ liệu và lift theo `SIG_IMPORT_SCALE` hiện hành. Hệ quả:

- Hạ `B[C]` thêm ⇒ nhiều face rơi về sàn hơn ⇒ lift tự động lớn hơn ⇒ thứ tự **vẫn** giữ, cho tới khi một lift vượt `SIG_LIFT_MAX` và build **đổ có tên face**, thay vì âm thầm gộp.
- Nâng `B[C]` ⇒ các nhóm tự tách ra ⇒ lift về 0 ⇒ luật thành no-op. Không phải gỡ gì.
- Thêm face vào Icon List ⇒ nếu nó vào một nhóm sẵn có, nó được lift cùng; nếu tạo nhóm mới, luật áp luôn.

`I25` (§6f) assert: sau `SIG_LIFT`, trong **mỗi** nhóm `(p,t,sortedKeys)` của 81 signature, dãy `v` **tăng nghiêm ngặt**; và `max(lift) ≤ SIG_LIFT_MAX`. Đây là bất biến **độc lập với `B[C]`** — cùng tính chất mà R7 mang lại cho variant.

#### 3.3a Icon List — 50 tên từ `FACE_NAMES`, đã ghim (class, slot)

Bảng này là **nguồn thực thi** cho `SIGNATURE_FACE`. Cột `face` copy **nguyên xi** từ `FACE_POOL` — **đây là thang `FACE_POOL` (thang drop)**. Giá trị trên die import = cột này × `SIG_IMPORT_SCALE` × `CoherenceMod`, do generator tính (§6f); đừng đọc cột này như giá trị runtime của Axie import.

| # | Tên | class | slot | r | face (t · v · k) |
|---|---|---|---|---|---|
| 1 | Zigzag | plant | mouth | 0 | dmg 6 |
| 2 | Incisor | reptile | horn | 0 | dmg 7 |
| 3 | Snail Shell | bug | back | 0 | shield 7 |
| 4 | Blossom | plant | eyes | 0 | heal 6 |
| 5 | Gill | aqua | ears | 0 | mana 2 · cantrip |
| 6 | Grass Snake | reptile | tail | 0 | poison 4 |
| 7 | Razor Bite | reptile | mouth | 0 | dmg 5 |
| 8 | Pumpkin | plant | back | 0 | shield 6 |
| 9 | Cerastes | reptile | horn | 1 | dmg 7 · pierce |
| 10 | Toothless Bite | reptile | mouth | 1 | dmg 7 · lifesteal |
| 11 | Cloud | bird | tail | 1 | dmg 5 · cleave |
| 12 | Hermit | aqua | back | 1 | shield 6 · aoe |
| 13 | Imp | beast | horn | 1 | dmg 9 · heavy |
| 14 | Tiny Dino | reptile | tail | 1 | poison 5 · aoe |
| 15 | Cucumber Slice | plant | eyes | 1 | heal 7 · aoe |
| 16 | Confident | beast | mouth | 1 | dmg 6 · growth |
| 17 | Bubblemaker | aqua | ears | 1 | mana 3 · cantrip |
| 18 | Little Peas | beast | eyes | 1 | debuff 0 · weaken:3 · aoe |
| 19 | Dual Blade | beast | horn | 1 | dmg 8 · crit:30 |
| 20 | The Last One | bird | tail | 1 | dmg 6 · burn:3 |
| 21 | Eggshell | bird | horn | 2 | dmg 10 · pierce · crit:25 |
| 22 | Axie Kiss | beast | mouth | 2 | dmg 8 · lifesteal · growth |
| 23 | Swallow | bird | tail | 2 | dmg 7 · cleave · burn:4 |
| 24 | Indian Star | reptile | back | 2 | shield 9 · aoe · thorns:3 |
| 25 | Gila | reptile | tail | 2 | poison 6 · aoe · multi:2 |
| 26 | Nut Cracker | beast | mouth | 2 | dmg 6 · multi:3 |
| 27 | Little Branch | beast | horn | 2 | dmg 12 · heavy · vital |
| 28 | Nyan | beast | ears | 2 | mana 3 · cantrip · rerollup |
| 29 | Scar | reptile | eyes | 2 | debuff 0 · vulnerable:3 · freeze |
| 30 | Post Fight | bird | tail | 2 | dmg 6 · aoe · pierce |
| 31 | Mavis | bird | eyes | 2 | summon 1 · cantrip |
| 32 | Lam | aqua | mouth | 2 | dmg 9 · exec |
| 33 | Scaly Spear | reptile | horn | 3 | dmg 18 · heavy · pierce |
| 34 | Twin Tail | bug | tail | 3 | dmg 11 · aoe · burn:5 |
| 35 | Piranha | aqua | mouth | 3 | dmg 13 · lifesteal · crit:40 |
| 36 | Tri Spikes | reptile | back | 3 | shield 15 · aoe · thorns:5 |
| 37 | Wall Gecko | reptile | tail | 3 | poison 9 · aoe · pierce |
| 38 | Kestrel | bird | horn | 3 | dmg 14 · cleave · exec |
| 39 | Friezard | reptile | ears | 3 | mana 5 · cantrip · rerollup |
| 40 | Gecko | reptile | eyes | 3 | heal 14 · aoe · regen:3 |
| 41 | Goda | beast | mouth | 3 | dmg 8 · chain:5 · crit:30 |
| 42 | Robin | bird | eyes | 3 | summon 2 · cantrip |
| 43 | Thorny Caterpillar | bug | tail | 4 | poison 7 · aoe · plague |
| 44 | Wing Horn | bird | horn | 4 | dmg 20 · pierce · echo |
| 45 | Green Thorns | reptile | back | 4 | shield 18 · aoe · bastion |
| 46 | Mosquito | bug | mouth | 4 | dmg 16 · lifesteal · crit:100 |
| 47 | Sidebarb | reptile | ears | 4 | mana 8 · cantrip · overflow |
| 48 | Granma's Fan | bird | tail | 4 | dmg 13 · aoe · cleave · burn:8 |
| 49 | Neo | bug | eyes | 4 | summon 3 · cantrip |
| 50 | Pocky | beast | horn | 4 | dmg 26 · heavy · vital · exec |

#### 3.3b Icon List Addendum — 13 tên mới (face cần thiết kế)

**Luật chọn addendum** (nêu rõ để audit được): thêm đúng một part cho **mỗi family đang có 0 signature** (9 family), cộng 4 part product owner/community coi là biểu tượng nhưng `FACE_NAMES` bỏ sót. Không có mục nào ngoài hai lý do đó.

Verify class distribution trước/sau: `FACE_NAMES` lệch nặng (reptile 15 · beast 10 · bird 10 · bug 6 · aqua 5 · **plant 4**). Addendum kéo về reptile 15 · bird 13 · beast 13 · bug 8 · plant 7 · aqua 7 — không class nào còn mỏng đến mức không dựng nổi build.

| # | Tên | class | slot | r | face (t · v · k) | Lý do vào list |
|---|---|---|---|---|---|---|
| 51 | Cub | beast | mouth | 0 | dmg 6 | Tên starter hero `beast1` (`HEROES.beast1.n='Cub'`) — trùng danh tính với game; và giải toả collision duy nhất của Beast·Mouth (§3.5c) |
| 52 | Pincer | bug | mouth | 0 | poison 4 | Bug·Mouth chỉ có 1 signature (Mosquito); Pincer là Bug mouth cổ điển |
| 53 | Clover | plant | ears | 0 | mana 2 · rerollup | Plant·Ears 0 signature ngoài Sakura (Sakura là Prime, không phải icon). Cỏ bốn lá = may mắn = reroll |
| 54 | Ronin | beast | back | 1 | dmg 8 · heavy | **Product owner nêu tên.** Beast·Back = 0 signature. Part Beast back biểu tượng nhất lịch sử Axie |
| 55 | Zeal | beast | eyes | 1 | debuff 0 · vulnerable:3 · blind:1 | **Product owner nêu tên.** Setup cho FERAL execute — đúng bản sắc Beast |
| 56 | Cactus | plant | horn | 1 | dmg 7 · pierce | Plant·Horn = 0 signature |
| 57 | Hot Butt | plant | tail | 1 | shield 6 · regen:2 | Plant·Tail = 0 signature |
| 58 | Anemone | aqua | horn | 1 | dmg 6 · mana:2 | Aqua·Horn = 0 signature. `mana:N` rider = CONDUIT thuần |
| 59 | Sleepless | aqua | eyes | 1 | heal 7 · cantrip | Aqua·Eyes = 0 signature. "Không bao giờ ngủ" → cantrip |
| 60 | Parasite | bug | horn | 1 | dmg 7 · weaken:3 | Bug·Horn = 0 signature |
| 61 | Little Owl | bird | mouth | 2 | dmg 8 · pierce · lifesteal | Bird·Mouth = 0 signature. Ghim vào **mouth** (Little Owl còn ở eyes/ears — hai slot đó đi đường variant) |
| 62 | Balloon | bird | back | 2 | debuff 0 · vulnerable:3 · aoe | Bird·Back = 0 signature. "Phồng lên" → vulnerable |
| 63 | Risky Bird | bird | ears | 2 | mana 4 · cantrip · rerollup · selfharm:2 | Bird·Ears = 0 signature. "Risky" → selfharm |

Cả 13 face này **cũng được thêm vào `FACE_POOL`** (§3.8) — đó chính là điều làm hai vốn từ hợp nhất.

**Verify keyword**: 13 face trên chỉ dùng `pierce · mana:N · cantrip · rerollup · heavy · vulnerable:N · regen:N · weaken:N · lifesteal · aoe · selfharm:N` — tất cả đều đã implement trong `src/engine.js` (§3.7 có bảng đối chiếu dòng code).

**Verify ngân sách**: cả 13 face đã được đối chiếu với `SIG_BUDGET[r]` (§4, F7) và nằm trong dải ±20%. Lệch lớn nhất: `Pincer` **+18%** (poison ở Bug đắt hơn vì VIRULENT — giữ `poison 4` để không yếu hơn `Grass Snake` cùng bậc r0 về mặt cảm nhận; đây là ngoại lệ có ý thức, ghi ở §4 F7).

**Sửa trong lúc soạn §4** (bảng trên đã là bản đã sửa — ghi lại để audit được lý do):
- Vào dải ngân sách `SIG_BUDGET`: `Sleepless` heal 5→**7** · `Parasite` dmg 6→**7** · `Balloon` vulnerable:2→**3** · `Risky Bird` mana 3→**4 (+rerollup)**
- Tránh **signature↔variant collision** trong cùng family (luật R5, §3.5c): `Clover` `mana 2 cantrip`→**`mana 2 rerollup`** (đụng `plant.ears.A`@C) · `Zeal` `vulnerable:4`→**`vulnerable:3 blind:1`** (đụng `beast.eyes.A`@O)

### 3.4 Scarcity bucket — suy thuần từ `stage`

Catalog thật phân hoạch **hoàn hảo** thành 3 nhóm rời nhau (đã verify: 174 + 75 + 18 = 267 identity của 6 class chính; 111 row `stage:0` = 93 identity 6-class + 18 identity secret-class; 192 row `stage:2` = 192 identity, không identity nào chỉ có stage 1).

| Bucket | Định nghĩa (theo identity, không theo row) | Số identity | `S` (**hằng số gốc**) | `B = B[C]×S` | rarity `r` sàn | Nhãn UI |
|---|---|---|---|---|---|---|
| **C** — Classic | có row `stage:2` (bản "+"), **không** có row `stage:0` | **174** | **1.000** | 2.80 | 0 | *(không nhãn)* |
| **O** — Origin | có row `stage:0` (bản "α"), **không** có row `stage:2` | **75** | **1.267** | 3.55 | 1 | `α ORIGIN` |
| **P** — Prime | có **cả** `stage:0` **và** `stage:2` | **18** | **1.600** | 4.48 | 2 | `⬥ PRIME` |
| **X** — Secret | class ∈ {dawn, dusk, mech} | **18** | **1.467** | *(4.11 — **RESERVED, không dùng**)* | 2 | `◈ SECRET` |

> **`S` là hằng số gốc, `B` là suy diễn.** Revision 1 để `B` làm hằng số gốc và `S = B/B[C]` là suy diễn; điều đó khiến việc đổi `B[C]` (đúng cái revision 2 làm) làm trôi `S`, mà `S` lại là input của handicap §3.9d. Đảo lại: `S` cố định, `B(bucket) = B[C] × S(bucket)`. Đổi `B[C]` giờ **không** đụng tới §3.9.
>
> **`B[X]` là dead code có chủ ý (defect S2 của review).** Cả 18 part secret-class đều là **signature** theo §3.10 quy tắc 2, nên bucket X **không bao giờ** đi qua F1–F6. Không một face nào trong game đọc `B[X]`. Nó được giữ trong bảng là **RESERVED** cho trường hợp Axie phát hành đủ part secret-class để dựng family thật (§3.10 nêu ngưỡng), và knob `K4` được **thu hồi** (§7). Ngược lại, **`S(X) = 1.467` thì SỐNG** — nó là input của `S̄` trong §3.9d và của `SP[X] = 2` trong §3.9c. Hai nửa của cùng một hàng có tuổi thọ khác nhau; đừng xoá nhầm nửa còn sống.

**Vì sao Prime là bậc cao nhất, và vì sao đúng 18 part**: một identity có cả bản α và bản "+" nghĩa là part đó tồn tại trong **cả hai dòng dõi** Axie Classic *và* Axie Origin. Đó là tín hiệu khan hiếm **đọc trực tiếp từ dữ liệu, không do designer chọn**, nên không thể bị cãi là thiên vị. 18/285 = 6.3% — đúng độ hiếm của một chase tier.

**18 part Prime, liệt kê đủ** (dùng để viết test):

| # | class | slot | tên | Ghi chú |
|---|---|---|---|---|
| 1 | beast | mouth | Nut Cracker | *cũng là* Signature (#26) → đi đường Signature, **không** nhận 1.60× |
| 2 | beast | tail | Nut Cracker | variant |
| 3 | beast | tail | Shiba | variant |
| 4 | beast | eyes | Puppy | variant |
| 5 | beast | ears | Belieber | variant |
| 6 | beast | ears | Innocent Lamb | variant |
| 7 | beast | ears | Nut Cracker | variant |
| 8 | beast | ears | Puppy | variant |
| 9 | aqua | back | Sponge | variant |
| 10 | aqua | tail | Tadpole | variant |
| 11 | aqua | ears | Gill | *cũng là* Signature (#5) → đường Signature |
| 12 | plant | eyes | Papi | variant |
| 13 | plant | ears | Sakura | variant |
| 14 | bug | ears | Leaf Bug | variant |
| 15 | reptile | horn | Bumpy | variant |
| 16 | reptile | back | Croc | variant |
| 17 | reptile | eyes | Scar | *cũng là* Signature (#29) → đường Signature |
| 18 | reptile | ears | Curved Spine | variant |

**Hệ quả quan trọng**: 3 trong 18 part Prime (Nut Cracker·mouth, Gill·ears, Scar·eyes) là Signature nên **không** nhận power multiplier. Đó là cố ý — xem §3.3. 15 part Prime còn lại là nơi chase value thực sự nằm.

**Bucket không phải thuộc tính của NFT, mà của catalog.** Một NFT cụ thể mang part "Nut Cracker" thì bucket của part đó là P bất kể con Axie đó đang ở stage nào. Điều này giữ **determinism**: cùng một `partKey` → luôn cùng một bucket, tra bảng tĩnh, không đọc state ngoài.

#### 3.4-bis. R2 — dải scarcity phải nằm trong `1× → dưới 2×`: ghim đại lượng NÀO

Yêu cầu ban đầu: *"Đảm bảo rằng dải scarcity bucket không bị chênh lệch quá lớn, tôi thấy dải tạm chấp nhận được là 1x -> dưới 2x."*
**Cập nhật đã chốt**: product owner nới lên **`< 2.40×`** sau khi đọc đánh đổi ở §3.4a-1 — *"tôi chấp nhận có thể 'Nới trần lên 2.4× → mỗi bậc +7.1%'"*. Cấu trúc ràng buộc **không đổi**, chỉ hằng số `SPREAD_OWN_MAX` đổi từ 2.00 sang 2.40.

Doc revision 2 có **bốn** số hạng power nhân/cộng dồn, nên "dải" là một từ mơ hồ: nó trỏ tới bốn đại lượng khác nhau cho bốn con số khác nhau. Revision 3 đặt tên cho ba và **ghim đúng một cái**:

| Đại lượng | Định nghĩa | Giá trị | Bị ghim? |
|---|---|---|---|
| **`SPREAD_OWN`** | cấu hình **đắt nhất** ÷ cấu hình **rẻ nhất**, ở *cùng* purity và *cùng* gene tier = `S_MAX × G_MAX` | **2.395×** | ✅ **CÓ — `< SPREAD_OWN_MAX = 2.40`.** Bất biến `I16`, hard-fail build |
| `SPREAD_STATIC` | `SPREAD_OWN ÷ COH_MIN` — die tốt nhất mua được so với die *xấu nhất tồn tại*, gene 0 | 2.921× | ❌ không — xem lập luận (1) dưới |
| `SPREAD_RUN` | `B_CAP_RUN ÷ B[C]` — một con Axie lớn bao nhiêu **trong một run** | 3.000× | ❌ không bị ghim, nhưng **không còn tự do**: nó là biến phụ thuộc của `PLAY_MARGIN_MIN` (F1b) |

**Lập luận (1) — vì sao coherence KHÔNG thuộc dải scarcity.** `SPREAD_OWN` hỏi *"cùng một người chơi, cùng một gu chọn Axie, giàu hơn thì mạnh hơn bao nhiêu?"*. Coherence có mặt ở **cả tử lẫn mẫu** của câu hỏi đó nên nó triệt tiêu. Quan trọng hơn: **coherence không mua được** — một con Axie mono-class toàn part Classic là loại **rẻ nhất** thị trường (Classic là 174/285 part, bucket đáy), còn một con Prime lai tạp thì đắt mà purity thấp. Ghép coherence vào "dải scarcity" sẽ tính một trục **nghịch** với giá tiền vào một chỉ số đo giá tiền. `SPREAD_STATIC` vẫn được generator in ra làm **chẩn đoán** (nó là "die mạnh nhất ÷ die yếu nhất tồn tại"), nhưng nó không phải điều kiện pass.

**Lập luận (2) — vì sao trục trong-run KHÔNG bị ghim.** `SPREAD_RUN` đo *tiến độ*, không đo *sở hữu*. Mốc so sánh tự nhiên của nó là đường lên tier của hero: `HEROES` tier-1 → tier-3 = **2.53×** (F2). `SPREAD_RUN = 2.571×` bám sát mốc đó, và **giữ nguyên từ revision 2**. Ép nó xuống dưới 2× sẽ làm Axie import lớn chậm hơn hero trong cùng một run — tái tạo đúng bài toán product owner giao ban đầu ("Axie import bị bỏ đói cơ chế tăng trưởng", §3.4c).

> **Ghi chú lịch sử**: một bản nháp của revision 3 từng ép `SPREAD_RUN` lên 3.000× để giữ bất đẳng thức *play > money*. Bất đẳng thức đó **đã bị thu hồi** (F1b-α, 2026-09-03), nên ràng buộc ép nó lên đã biến mất và `SPREAD_RUN` quay về giá trị neo-theo-hero.

**Lập luận (3) — vì sao trần `2.40×` vẫn tồn tại dù đã chấp nhận pay-to-win.** Đây là câu hỏi hiển nhiên tiếp theo: *nếu không chống người chi tiền nữa, sao còn giữ trần?* Vì trần giờ phục vụ một mục đích **khác hẳn**:

> `SPREAD_OWN_MAX` không còn là ràng buộc **công bằng**; nó là ràng buộc **đọc-được-của-cân-bằng**. `CURVE.budget`, `mkMonster` và `mkBoss` (`src/data.js`) **không đổi** và được hiệu chuẩn cho thang `HEROES`. Nếu dải sở hữu mở tự do, một die 5× hero tier-1 sẽ làm TTK ở wave đầu tiệm cận 1 lượt và toàn bộ đường cong độ khó mất nghĩa — không phải vì bất công, mà vì **không còn trận đấu nào để chơi**. 2.40× là mức mà die đắt nhất vẫn nằm dưới trần TTK 1.15× hero tier-3 sau khi cộng trục gene.

Ba bất biến máy kiểm (§6f): `I16` (`SPREAD_OWN < SPREAD_OWN_MAX` và bằng đúng `S_MAX × G_MAX`), `I17` (`SPREAD_OWN(g) < SPREAD_OWN_MAX` với **mọi** `g ∈ [0,6]`), `I23` (`B_CAP_RUN × 1.018 ≤ TTK_CEIL_T3 × 6.39`). ~~`I14`~~ và ~~`I22`~~ **đã thu hồi** cùng bất đẳng thức — xem F1b-α.

#### 3.4a `specialGenes` — trục thứ hai: THANG 8 BẬC CÓ THỨ TỰ (viết lại ở revision 3)

**Yêu cầu product owner**: bỏ cờ nhị phân, dùng đúng thứ tự sức mạnh sau — lưu ý **có ba bậc bằng nhau ở giữa**, nên đây là *thang có thứ tự kèm hoà*, không phải dãy nghiêm ngặt:

```
normal < summer < nightmare < Japanese < Shiny = Xmas = MEO I/II < Origin < Mystic < Agamogenesis
```

##### 3.4a-1. Bậc và hệ số

8 mức power (`tier` 0…7), 7 bậc trên `normal`. Ba giá trị `Shiny`/`Xmas`/`MEO I`/`MEO II` **chia chung tier 4** — thang có hoà, đúng như yêu cầu.

| tier | Gene | `G(tier)` | `r` bonus | `SP` (§3.9c) | Ghi chú |
|---|---|---|---|---|---|
| 0 | *normal* (và **mọi giá trị không nhận diện được** — E16-bis) | **1.000** | +0 | 0 | Mặc định an toàn |
| 1 | `summer` | **1.071** | +1 | 1 | |
| 2 | `nightmare` | **1.142** | +1 | 1 | |
| 3 | `japanese` | **1.213** | +1 | 1 | Doc gọi là "Japanese"; **chuỗi API chưa verify — E16-bis** |
| 4 | `shiny` = `xmas` = `meo1` = `meo2` | **1.284** | +1 | 2 | **Bốn giá trị, một tier.** Hoà theo đúng yêu cầu product owner |
| 5 | `origin` | **1.355** | +2 | 2 | **ĐÃ QUYẾT (3.4a-3): trung hoà về tier 0 khi bucket ∈ {O, P}.** Thực tế đó là 93/285 part, nên bậc này gần như luôn *không* áp. Nó tồn tại cho đúng một trường hợp: gene `origin` trên part bucket C = catalog lạc hậu |
| 6 | `mystic` | **1.426** | +2 | 3 | |
| 7 | `agamogenesis` | **1.497** | +2 | 3 | Đắt nhất trong toàn hệ sinh thái Axie |

```
G(tier)   = 1 + SG_STEP × tier          SG_STEP = 0.071    G_MAX = G(7) = 1.497
rBonus    = [0,1,1,1,1,2,2,2][tier]
SP_GENE   = [0,1,1,1,2,2,3,3][tier]
```

**Vì sao NHÂN chứ không CỘNG** (đổi so với `SG_BONUS = 0.28` phẳng của revision 2): một hằng số cộng phẳng đáng **10.0%** trên một part Classic nhưng chỉ **6.25%** trên một part Prime — tức thang gene *yếu đi đúng ở nơi nó xuất hiện nhiều nhất* (gene đặc biệt hầu như luôn nằm trên part hiếm). Nhân tính cho mọi bucket cùng một tỉ lệ, và nó làm số học của trần R2 khép kín: `SPREAD_OWN = S_MAX × G_MAX` chính xác, không phải xấp xỉ.

**Vì sao `SG_STEP = 0.071`** — đây là ràng buộc R2 sau khi product owner nới trần, không phải khẩu vị:
```
SPREAD_OWN = S_MAX × G_MAX = 1.600 × (1 + 7 × SG_STEP) < SPREAD_OWN_MAX = 2.40
⇒ SG_STEP < (2.40/1.600 − 1)/7 = 0.0714
⇒ chọn SG_STEP = 0.071  ⇒  G_MAX = 1.497  ⇒  SPREAD_OWN = 2.395×   ✓
```

> **QUYẾT ĐỊNH ĐÃ CHỐT — product owner nới trần từ 2.00× lên 2.40× để đổi lấy thang gene ĐỌC ĐƯỢC BẰNG SỐ.** Nguyên văn: *"tôi chấp nhận có thể 'Nới trần lên 2.4× → mỗi bậc +7.1%'"*.
>
> Đây là *đánh đổi có ý thức*, và ghi lại cả hai vế để đời sau đọc được:
> - **Được**: mỗi bậc gene = **+7.1% ngân sách**. Trên một part Classic (`B = 2.80`) đó là `+0.199`/bậc; trên Prime (`B = 4.48`) là `+0.318`/bậc. Với `R[dmg] = 1.00`, **cứ 3–5 bậc là chắc chắn nhích được 1 điểm mặt**, và normal → agamogenesis trên Prime là `+2.23` ngân sách ≈ **+2 điểm mặt**. Thang không còn bị làm tròn nuốt mất — đó chính là điều product owner muốn.
> - **Mất**: `SPREAD_OWN` từ 1.824× lên **2.395×**. Ở cùng trình độ, cùng độ thuần, cùng tiến độ run, **người giàu mạnh hơn ≈2.4× trên mỗi mặt dice**; cụ thể một Axie mua đắt khởi đầu run ở **1.07× hero tier-3**. Product owner đã **chấp nhận điều này một cách có ý thức vào 2026-09-03** (*"tôi chấp nhận việc pay to win"*, F1b-α) — nên đây là cái giá đã được trả, không phải một rủi ro còn treo.
>
> *(Bản nháp trước của ghi chú này nói quyết định 2.4× "ép `B_CAP_RUN` phải tăng theo để giữ play > money". Điều đó **không còn đúng**: bất đẳng thức đã bị thu hồi, `B_CAP_RUN` quay về 7.20 và giờ chỉ bị ràng buộc bởi trần TTK. Xem F1b-α và F1b-bis.)*
>
> **Cả 8 bậc và thế hoà bốn-chiều ở tier 4 được giữ nguyên** — đó là toàn bộ lý do trả giá này. Gộp bậc sẽ vừa mất thứ tự vừa không tiết kiệm được gì.
>
> **Đường lùi nếu sau này cần thu trần lại**: `K29` (`SG_TIER_MERGE`) gộp thang còn 4 bậc — `normal` / `summer+nightmare+japanese` / `shiny-xmas-meo+origin` / `mystic+agamogenesis` — cho `SG_STEP` hiệu dụng 0.071×(7/3) ≈ 0.166/bậc-gộp mà `G_MAX` vẫn 1.497, **hoặc** hạ `SPREAD_OWN_MAX` về 2.00 và nhận lại `SG_STEP = 0.0357`. Knob còn đó, mặc định **tắt**.

##### 3.4a-2. Áp vào ngân sách

```
B_acq(k, part) = min( B[C] × S(bucket(k)) × G(sgTier_eff(part, bucket)),  B_CAP0 )

B_CAP0 = B[C] × S_MAX × G_MAX = 2.80 × 1.600 × 1.497 = 6.7066  →  6.71
```

`B_CAP0` **không còn là một số tự do**: nó *bằng* trần lý thuyết của chính hai trục sở hữu. Nghĩa là `min(…)` chỉ ràng buộc khi ai đó tune `S` hoặc `G` lệch nhau — nó là lưới an toàn, không phải cái kẹp thường trực. `I16` kiểm đẳng thức này.

Rarity (F8 cập nhật): `r = min(4, rBase + rBonus(tier))`.

##### 3.4a-3. "Origin" xuất hiện HAI LẦN trong doc — đây là hai thứ khác nhau, và không được cộng dồn

| | Bucket `O — Origin` (§3.4) | Gene `origin` (tier 5, bảng trên) |
|---|---|---|
| Thuộc về | **danh tính part** trong catalog | **cá thể NFT**, trường `specialGenes` của part đó |
| Suy từ | part có row `stage:0` (bản α) trong `parts_full_source.json` | chuỗi API trả về cho đúng part instance đó |
| Tất định? | ✅ tra bảng tĩnh theo `partKey` | ❌ phụ thuộc NFT cụ thể |
| Số lượng | 75 identity | chưa biết — chưa verify được (E16-bis) |

**QUYẾT ĐỊNH (không phải cảnh báo)**: hai trục này **đo cùng một sự thật ngoài đời** — "part này thuộc dòng dõi Axie Origin". Cộng dồn = **tính tiền hai lần cho một fact**, và hậu quả đo được: một part Prime mang gene `origin` sẽ ra `S(P) × G(5) = 1.600 × 1.100 = 1.760×`, rồi cùng part đó ở tier 7 ra `1.600 × 1.140 = 1.824×` — nghĩa là **bậc `origin` chiếm mất 55% toàn bộ ngân sách của thang gene** (`0.100 / 0.140`) để trả cho một thuộc tính mà trục bucket **đã** tính. Đó chính là kiểu lạm phát trần mà R2 vừa tốn công chặn. Luật:

```
sgTier_eff(part, bucket):
    t = sgTier(part)                                   // §3.4a-1 + E16-bis
    if t === SG_TIER.origin  AND  bucket ∈ {O, P}:
        telemetry('sg_origin_redundant', {partKey})
        return 0                                       // TRUNG HOÀ — bucket đã tính rồi
    return t
```

- **Bucket O/P thắng, gene `origin` bị trung hoà**, không phải ngược lại. Lý do: bucket suy từ catalog nên nó **tất định và replay được** (§3.4 "bucket không phải thuộc tính của NFT"); gene suy từ một field API mà server phải fetch lại (§3.9). Giữ trục tất định, bỏ trục phải-fetch.
- **Nếu gene `origin` xuất hiện trên một part bucket C**, tier **được áp** (part đó thật sự hiếm hơn bucket của nó gợi ý) **và** ghi telemetry `sg_origin_on_classic` — vì nó có nghĩa là `parts_full_source.json` đã lạc hậu và cần `--refresh-catalog` (E1).
- Kiểm được: `AC-35` assert `sgTier_eff = 0` cho mọi tổ hợp `(gene origin, bucket O|P)` và assert `SPREAD_OWN` không đổi khi bật/tắt luật này trên tập part bucket O/P.

##### 3.4a-4. E16 được GIẢI, không bị chồng lên

E16 ghi ba cách hiểu mâu thuẫn của `specialGenes` trong cùng codebase. Thang này **thay thế cả ba**, không nằm lên trên:

| Nơi | Trước | Sau revision 3 |
|---|---|---|
| `axieToDie` (`src/engine.js:101`) | `if(part.specialGenes != null)` → +30% value, `r ≥ 1` cho **hầu như mọi part** | `sgTier(part)` → `G(tier)` + `rBonus(tier)`. Giá trị không nhận diện được → **tier 0** |
| `nftRarityMult` (`src/engine.js:36`) | `[1.0,1.15,1.3,1.5][specialGenes|0]` — coi field là **số nguyên 0–3** | `nftRarityMult(specialGeneCount(axie))`, với `specialGeneCount` = **số part có `sgTier > 0`**, kẹp 0–3. Một định nghĩa, hai chỗ dùng |
| `tools/t_import.mjs:70, 82` | fixture `'000000'` dùng làm case **CÓ** gene | `'000000'` → tier 0 (bitmask toàn 0). Fixture giữ nguyên, **assertion đảo chiều** (§6c) |

Bug lạm phát 30% toàn hệ mà E16 cảnh báo **biến mất do cấu trúc**: tier 0 là mặc định, và mọi chuỗi không nằm trong bảng đều rơi về tier 0 (E16-bis).

#### 3.4b Coherence / purity — trục thứ ba, thuộc tính của CẢ VIÊN DICE

**Yêu cầu product owner**: *một Axie import không được yếu hơn hero starter nhiều — chỉ hơi yếu hơn khi các part của nó không khớp nhau.*

```
purity(parts, bodyCls) =
    n     = số part THẬT (không tính BLANK pad)
    match = |{ p ∈ parts : mapAxieClass(p.class) === bodyCls }|
    nếu n === 0  →  6            // die rỗng, không có thông tin → không phạt
    nếu n === 6  →  match
    ngược lại    →  round( 6 × match / n )      // giữ TỈ LỆ, xem lý do dưới

CoherenceMod = COH[ clamp(purity, 0, 6) ]
COH = { 6: 0.780, 5: 0.757, 4: 0.733, 3: 0.710, 2: 0.686, 1: 0.663, 0: 0.640 }   // K25, retuned 2026-09-03

nếu die có ≥1 part bucket X:  CoherenceMod = max(CoherenceMod, COH_FLOOR_SECRET = 0.710)

> ⚠️ **RETUNE 2026-09-03 (K25) — toàn thang nhân 0.78.** Thang cũ là
> `1.00/0.97/0.94/0.91/0.88/0.85/0.82` với `COH_FLOOR_SECRET = 0.91`. Sim gate E15b đổ:
> đội 5 Axie import đạt **49.3%** winrate so với **20.0%** của đội hero (đo bằng
> `node tools/sim.js 300 vault=5`, cờ N14 mới). Product owner chốt mục tiêu **30–35%**.
> Toàn bộ 7 bậc **và** `COH_FLOOR_SECRET` được nhân cùng một hệ số 0.78, nên **gradient
> −3%/bậc và toàn bộ ý nghĩa của trục purity giữ nguyên** — đây là đổi ĐỘ LỚN, không đổi
> CẤU TRÚC. Kết quả đo: vault5 **34.0%**, hero **20.0%** (không đổi), tức 1.70× — nằm trong
> dải 1.5–1.75× mà product owner chấp nhận.
>
> **Vì sao K25 chứ không phải K23** (§7 xếp `GENE_STEP` là knob đầu tiên): `GENE_STEP` chỉ
> vào công thức qua `B_run = B_acq + GENE_STEP × g`, mà `g = geneTier` là trục tăng trưởng
> TRONG RUN (N15) — **chưa implement**, nên `g` luôn 0. Đã đo cả hai đầu dải: `0.35` và
> `0.75` đều cho **đúng 49.3%**. Knob này hiện là no-op và sẽ chỉ sống lại khi N15 ship.
>
> **Vì sao không phải K1 `B[C]`**: lợi thế của Axie import **không nằm ở giá trị mặt** —
> đo được **2.50** trung bình so với **2.53** của hero tier-1 (0.989×). Nó nằm ở chỗ cả 6
> mặt đều dùng được, trong khi die hero tier-1 có mặt yếu/trùng: số lần chết ở wave 1–11
> giảm 139 → 47. Bằng chứng: hạ `B[C]` **43%** (2.80 → 1.60) chỉ đưa 49.3% → **43.7%**.
> `COH` hiệu quả hơn ~4× mỗi đơn vị vì nó là knob DUY NHẤT chạm cả `maxHp`
> (`maxHp = round(hero.hp × coh)`), tức đúng trục sinh tồn đang gây ra chênh lệch.
```

Áp vào **cả hai** đại lượng, đúng như yêu cầu:
```
B_final = B_run × CoherenceMod                                   // mọi face, kể cả signature
maxHp   = max(1, round( HEROES[bodyCls+'1'].hp × CoherenceMod ) + HP_STEP[geneTier])
```

**Bốn quyết định thiết kế, mỗi cái có lý do:**

1. **Tính trên `mapAxieClass(part.class)`, không trên `part.class` thô.** Đây là điểm then chốt và nó giải quyết luôn xung đột secret-class (xem 3.4b-bis). `mapAxieClass` đã tồn tại (`src/engine.js:63-69`) và đã collapse `dawn→beast`, `dusk→reptile`, `mech→bug`. Dùng nó nghĩa là một part Dawn trên một con Axie Dawn **đếm là khớp** — không cần luật ngoại lệ nào.
2. **Gradient, không phải gate.** Mỗi bậc purity là −3%. Không có ngưỡng nào mà người chơi rơi khỏi một vách. Lý do là **Autonomy** (SDT): người chơi **không chọn được** part nào tồn tại trên con Axie mình đã mua — một cliff sẽ phạt một điều họ không kiểm soát. Bậc 0 = 0.82 được hiệu chuẩn để Axie trộn hoàn toàn ra **0.92× hero tier-1** (2.334 vs 2.53), đúng nghĩa "chỉ hơi yếu hơn".
3. **Giữ tỉ lệ cho die khuyết part.** Một Axie 3 part với 3/3 khớp có `purity6 = 6` → `CoherenceMod = 1.00`. Nếu dùng `match` thô thì nó ra 3 → 0.91, tức **bị phạt hai lần**: một lần vì có 3 mặt `BLANK` vô dụng, một lần nữa vì coherence. Đó là phạt sai. (Xem thêm E2a — mặt `BLANK` còn là bề mặt duy nhất relic `r_voidgene` kích hoạt được.)
4. **Áp cả lên signature face.** Coherence là thuộc tính của **viên dice**, không của part, nên nó không được có ngoại lệ theo đường resolve — ngược lại với bucket multiplier (§3.3: signature **không** nhận bucket). Hai trục, hai luật khác nhau, và sự khác nhau đó có nghĩa: *bạn sở hữu part gì* là chuyện của part; *bộ part có hợp nhau không* là chuyện của con Axie.

**Suppression keyword — phần "sắc vs thô" của Breeding moment (§2 khoản 4). ĐỔI TỪ *XOÁ* SANG *THAY THẾ* ở revision 3.**

```
nếu purity ≤ 2 VÀ die không có part bucket X:
    với mỗi VARIANT face (KHÔNG áp cho signature face):
        với mỗi keyword k ∈ SUPPRESS_SOURCES (bảng liệt kê — KHÔNG phải luật ngưỡng):
            k  →  candidate đầu tiên hợp lệ trong SUPPRESS_CANDIDATES[k][typeGroup]
        → chênh lệch ngân sách hoàn vào v   (nên v TĂNG)
    ngoại lệ an toàn: không đụng `aoe` nếu face có `cantrip` và t ∈ {dmg, poison, debuff}
                      (giữ E7 cantrip placement law bất biến)

SUPPRESS_SOURCES = { pierce, cleave, aoe, freeze, stun, chain:* }     // BẢNG LIỆT KÊ là ĐỊNH NGHĨA

SUPPRESS_CANDIDATES[source][typeGroup]     // ĐẦU VÀO THIẾT KẾ: thứ tự ƯU TIÊN, không phải ánh xạ 1-1
  typeGroup A = { dmg, debuff }        // kwPure hướng-địch hợp lệ
  typeGroup B = { shield, heal, buff } // kwPure hướng-ally hợp lệ
  typeGroup C = { mana, summon, poison } // chỉ rider ngoài kwPure

  pierce   A: [ heavy, growth, vital, decay, crit:15, selfharm:1 ]
           B: [ regen:1, thorns:1, heavy, growth, vital ]
           C: [ heavy, growth, vital, decay ]
  cleave   A: [ growth, heavy, vital, decay, crit:15, selfharm:1 ]
           B: [ thorns:1, regen:1, growth, heavy, vital ]
           C: [ growth, heavy, vital, decay ]
  aoe      A: [ vital, growth, heavy, decay, crit:15, selfharm:1 ]
           B: [ regen:1, thorns:1, vital, growth, heavy ]
           C: [ vital, growth, heavy, decay ]
  freeze   A: [ blind:1, weaken:1, blind:2, weaken:2 ]
           B: —  (§3.7a cấm freeze trên shield/heal/buff, nhánh này không tồn tại)
           C: —  (trơ trên nhóm C, không bao giờ được author)
  stun     A: [ weaken:1, blind:1, weaken:2, blind:2 ]
           B: —      C: —
  chain:*  A: [ multi:2, growth, heavy, crit:15 ]
           B: —      C: [ multi:2, growth, heavy ]
```

##### SUPPRESS pass — vì sao một BẢNG ÁNH XẠ CỐ ĐỊNH không thể đúng (sửa `I18`, revision 3)

`SUPPRESS_SWAP` bản đầu là một ánh xạ keyword→keyword cố định. `I18` bắt được **5 cặp sập**, và hai cặp trong đó cho thấy vì sao *mọi* bảng cố định đều sai, không riêng bảng đó:

| cặp sập | cơ chế |
|---|---|
| `bird.mouth.A` (`dmg·pierce`) → `dmg·heavy` = `reptile.mouth.A` | ánh xạ **không đơn ánh**: `pierce → heavy` và `cleave → heavy` chung đích |
| `aqua.horn.D` (`dmg·mana:3`) → `dmg·mana:1` = `aqua.horn.A` | đích **va vào một set CHƯA bị suppress** trong cùng slot |

Cặp thứ hai là cái quan trọng. Kể cả khi bảng đơn ánh hoàn hảo, **ảnh của nó vẫn có thể rơi trúng một set đang tồn tại** — vì một bảng keyword→keyword **không biết gì về các variant khác trong slot**. Ràng buộc thật không phải "ánh xạ đơn ánh" mà là:

> **Sau suppression, hợp của {set đã suppress} và {set chưa suppress} và {set signature} trong **mỗi slot** phải vẫn đơn ánh.** Đó là một ràng buộc **toàn cục theo slot**, và không hằng số cục bộ nào thoả nó được.

Nên suppression đi theo đúng khuôn đã dùng ba lần trong doc này: **doc sở hữu đầu vào thiết kế, generator sở hữu phép gán** — như F6 (monotone), REPAIR (§3.5d), SPREAD (§3.5d-bis) và `SIG_LIFT` (§3.3c).

```
SUPPRESS(slot P):                       // sau SIG_LIFT, trước/độc lập với REPAIR
  USED = { (t, sortedKeys) của MỌI face trong P }      // variant + signature, kể cả legacy
  for variant v in P bị suppress, thứ tự (class asc → chữ cái):
    for kw in v.k ∩ SUPPRESS_SOURCES:                 // BẢNG LIỆT KÊ, không phải ngưỡng
      G = typeGroup(v.t)                              // A dmg|debuff · B shield|heal|buff · C mana|summon|poison
      for cand in SUPPRESS_CANDIDATES[kw][G]:         // theo thứ tự ưu tiên, THEO TYPE GROUP
        thử = v.k thay kw bằng cand
        nếu hợp lệ (§3.7a hướng · E7 cantrip · I20 ≤3kw · không rỗng)
           và (t, sorted(thử)) ∉ USED:
              nhận; USED.add(·); break
      nếu không cand nào nhận được: HARD FAIL 'I18-UNRESOLVED', in slot + variant + kw + danh sách đã thử
```

Bốn tính chất bắt buộc:

1. **Tất định** — thứ tự duyệt cố định, thứ tự candidate cố định. Chạy lại ra kết quả y hệt.
2. **Không bao giờ để set rỗng** — suppression *thay*, không *xoá*. Đây là ràng buộc gốc: nó kích hoạt cho Axie **lai tạp**, tức đúng nhóm mà trục purity tồn tại để **khắc hoạ**, không phải để xoá. Một face mất sạch keyword là một face mất danh tính.
3. **Kiểm cả set chưa suppress và set signature** — đây là điều bảng cố định không làm được, và là nguyên nhân cặp `aqua.horn`.
4. **Fail loud kèm tên** — quá candidate thì build đổ và nêu đích danh, không âm thầm nhả ra một face trùng.

**Đầu vào thiết kế vẫn giữ đúng ý đồ "lai tạp đánh thô hơn"**: mọi candidate đều là keyword **rẻ và thô** — `heavy` là drawback, `growth`/`vital` là chậm/có điều kiện, `decay` là drawback, `multi:2` mất tầm với của `chain`, `blind:1`/`weaken:1` mất tempo của `freeze`/`stun`. Thứ tự ưu tiên được đặt theo *độ gần về flavour* với keyword bị thay, nên lựa chọn đầu tiên gần như luôn là lựa chọn designer sẽ chọn; các lựa chọn sau chỉ dùng khi slot đã chật.

##### Ngưỡng hay bảng liệt kê? — BẢNG LIỆT KÊ là định nghĩa (sửa mâu thuẫn, generator phát hiện)

§3.4b bản đầu nói **hai** thứ không tương thích: một *luật ngưỡng* (suppress mọi `k` có `cost(k) > 2.00`) và một *bảng liệt kê*. Generator theo bảng và báo cáo đúng: **bảy dạng keyword thoả ngưỡng nhưng không có entry** — `chain:4` (4.2) · `mana:2` (2.2) · `multi:3` (3.2) · `poison:3` (2.1) · `poison:4` (2.8) · `thorns:3` (2.1) · `vulnerable:3` (2.25). Người đọc và máy sẽ bất đồng ở đúng bảy chỗ đó.

**Chốt: `SUPPRESS_SOURCES` (bảng liệt kê) là ĐỊNH NGHĨA. Ngưỡng chỉ là văn xuôi mô tả**, hạ cấp xuống một *hướng dẫn chọn cái gì để liệt kê*. Ba lý do, và chúng quan trọng hơn việc chỉ chọn một bên:

1. **Ngưỡng đo sai đại lượng.** `cost(k)` đo *giá ngân sách*; suppression nói về *độ tinh vi chiến thuật*. Hai thứ tương quan nhưng không đồng nhất, và ở đúng bảy trường hợp trên chúng tách ra.
2. **Magnitude scaling bị suppress là ĐẾM HAI LẦN.** `poison:3`, `poison:4`, `thorns:3`, `vulnerable:3`, `multi:3`, `chain:4` chỉ là *số lớn hơn* của một keyword rẻ. Nhưng `CoherenceMod` **đã** cắt magnitude qua ngân sách rồi — một Axie lai tạp đã nhận `N` nhỏ hơn. Suppress thêm là phạt hai lần cho cùng một sự thật.
3. **Luật ngưỡng làm hành vi phụ thuộc một con số tune được.** Thêm `poison:5` vào bảng §3.11 sau này sẽ **âm thầm** đưa nó vào tập suppress; đổi `KW_SUPPRESS_THRESHOLD` sẽ âm thầm đổi tính cách của mọi Axie lai tạp. Đó đúng là dạng phụ-thuộc-vào-số mà R7, `I24` và `SIG_LIFT` được dựng lên để loại bỏ. Bảng liệt kê là **quyết định thiết kế tường minh**; ngưỡng là một tác dụng phụ.

`I27` assert **một chiều**: mọi phần tử của `SUPPRESS_SOURCES` phải có `cost > KW_SUPPRESS_THRESHOLD` (bắt việc vô tình liệt kê một keyword rẻ). **Không** assert chiều ngược lại — đó chính là điểm.

**Ba keyword bị LOẠI khỏi tập suppress một cách có chủ ý** (không phải bỏ sót):

| keyword | vì sao KHÔNG suppress |
|---|---|
| `mana:N` | Đây là **rider bản sắc class của Aqua** (CONDUIT). §3.4b nói rõ suppression phải khắc hoạ Axie lai tạp, **không** được xoá bản sắc class. Suppress `mana:N` là lấy đi đúng thứ làm Aqua là Aqua |
| `poison:N` `thorns:N` `vulnerable:N` `weaken:N` `blind:N` `multi:N` | Magnitude scaling — lý do 2 ở trên |
| `undying` | **Không phải keyword chiến thuật.** Nó là một sàn sinh tồn nhị phân, không phải một mánh; thay nó đi chỉ là cắt power thuần, không tạo ra sự "thô hơn" nào để người chơi đọc được. Ghi thêm: `undying` hiện **không được cấp bởi bất cứ thứ gì trong game** ngoài chính face này, nên vùng ảnh hưởng của luật là một variant duy nhất |

##### Ba variant cạn candidate — hai được giải bằng LOẠI TRỪ, một bằng mở rộng

| variant | nguồn | xử lý |
|---|---|---|
| `aqua.horn.D` (`dmg · mana:3`) | `mana:3` | ✅ **Không còn suppress** — `mana:N` bị loại (bản sắc class). Không cần candidate nào |
| `aqua.back.D` (`shield · undying`) | `undying` | ✅ **Không còn suppress** — `undying` bị loại (không chiến thuật) |
| `bird.mouth.A` (`dmg · pierce`) | `pierce` | 🔧 **Mở rộng candidate**: thêm `crit:15` và `selfharm:1` vào nhánh typeGroup A. Cả hai rẻ và **thô** đúng nghĩa — `crit:15` là sát thương may rủi không kiểm soát được, `selfharm:1` là một drawback thuần. `dmg · crit:15` còn trống ở slot `mouth` (`aqua.horn.C` mang bộ đó nhưng ở slot **horn**) |

**Candidate giờ phân theo TYPE GROUP, không phải một danh sách phẳng.** Đây là nguyên nhân gốc của `aqua.back.D`: `undying` chỉ tồn tại trên face `shield`/`heal`/`buff`, nhưng candidate của nó (`vital`/`growth`/`heavy`) được rút từ vốn từ của face `dmg`. Trên một face `shield`, vốn từ rẻ-và-thô đúng là `regen:1`/`thorns:1` — hướng-ally, hợp lệ theo §3.7a, và đúng flavour phòng thủ. Một bảng phẳng không thể biết điều đó, cùng lý do một ánh xạ cố định không thể biết về các variant khác trong slot.

`I18` phát biểu lại: sau SUPPRESS, mỗi slot đơn ánh trên `(t, sortedKeys)` **và** không set nào rỗng. `AC-36` cộng thêm: **0** lần HARD FAIL trên toàn 36 family, và `tools/known-failures.json` **không còn entry `I18-UNRESOLVED` nào** — theo ngữ nghĩa hai chiều của file đó, một id đã pass mà còn nằm trong danh sách sẽ làm build đổ vì entry cũ, nên việc dọn file là **bắt buộc** chứ không tuỳ ý.

> **Vì sao *thay thế* chứ không *xoá* — đây là một defect thật mà R1 phát hiện, không phải một tinh chỉnh thẩm mỹ.**
>
> Xoá keyword là một **toán tử gộp**: `dmg · pierce` và `dmg` là hai face phân biệt, nhưng sau khi xoá `pierce` chúng thành **một**. Nghĩa là ở purity ≤ 2, hệ tự tay phá đúng bất biến R7 (§3.5c) mà revision 3 vừa dựng lên để đạt 285 face phân biệt — và nó phá **âm thầm**, chỉ trên một tập con người chơi (Axie lai tạp), nên không AC nào của revision 2 bắt được.
>
> Thay thế giữ đúng ý đồ thiết kế ("lai tạp đánh **thô hơn**, số to hơn, ít mánh hơn") vì mọi giá trị trong `SUPPRESS_SWAP` đều là keyword **rẻ và thô**: `heavy` là drawback, `growth` là chậm, `multi:2` mất `chain`'s reach, `blind:1` mất `freeze`'s tempo. Nhưng nó **giữ số keyword > 0** trên mọi face, nên `(t, sortedKeys)` vẫn khác nhau giữa hai variant khác nhau.
>
> Ràng buộc bắt buộc của bảng `SUPPRESS_SWAP` (kiểm bằng `I18`): ánh xạ phải **đơn ánh trong mỗi slot sau khi áp** — tức nếu hai variant cùng slot, sau swap, cho cùng `(t, sortedKeys)` thì build **fail**, và designer phải đổi một trong hai. Đây chính là lý do bảng có `pierce → heavy` **và** `cleave → heavy`: hai variant `dmg·pierce` và `dmg·cleave` trong **cùng** một family sẽ va nhau sau swap — nên `I18` bắt buộc chỉ **một** trong hai được swap sang `heavy` và cái còn lại phải có đích khác. Generator liệt kê xung đột và HARD FAIL kèm tên; nó **không** tự chọn.
>
> Mọi giá trị đích đều đã verify implement (§3.7) và đã kiểm hướng kwPure (§3.7a): `heavy`/`growth`/`vital`/`multi:N`/`mana:N` nằm **ngoài** kwPure nên an toàn trên mọi type; `blind:1`/`weaken:1` là kwPure hướng-địch nên chỉ được là đích khi face gốc có `t ∈ {dmg, debuff}` — với `t ∈ {shield, heal, buff}` thì `freeze`/`stun` vốn đã bị §3.7a cấm nên trường hợp đó không tồn tại.

Keyword bị ảnh hưởng — **đúng 6, theo `SUPPRESS_SOURCES`**: `pierce` 2.30 · `freeze` 2.60 · `chain:*` 2.80+ · `cleave` 3.10 · `stun` 3.40 · `aoe` 3.60. Mọi keyword khác **không bao giờ** bị thay, gồm cả ba nhóm bị loại có chủ ý: `mana:N` (bản sắc class Aqua) · `undying` (không chiến thuật) · mọi magnitude scaling `poison:N`/`thorns:N`/`vulnerable:N`/`weaken:N`/`blind:N`/`multi:N` (coherence đã cắt magnitude — suppress nữa là đếm hai lần). Lý do đầy đủ ở "Ngưỡng hay bảng liệt kê?" dưới.

> Con số `cost` ghi kèm chỉ để **đối chiếu** với `KW_SUPPRESS_THRESHOLD` qua `I27`; chúng **không** định nghĩa tập. Bảng liệt kê định nghĩa tập.

Nó **không** phải một hình phạt số thứ hai — nó gần như trung tính về ngân sách (ngân sách được hoàn vào `v`). Nó là một thay đổi **tính chất**: một Axie lai tạp đánh **số to hơn, ít mánh hơn**. Ba lý do nó đúng:

- **Nó biến hạn chế của F1 thành đặc điểm.** Ở `B_eff ≈ 2.80`, keyword đắt vốn đã gần không mua được; suppression làm điều đó thành một *luật đọc được* thay vì một hiệu ứng phụ của làm tròn.
- **Nó khớp thang hero.** Dice hero tier-1 mang `heavy`/`growth`/`cantrip`; `pierce`/`cleave`/`aoe` là vốn từ của tier-2/3. Vậy **độ phức tạp thang theo độ khan hiếm cùng với sức mạnh** — nêu ở đây làm **nguyên tắc thiết kế tường minh**, không phải một quan sát.
- **Nó chỉ chạm purity ≤ 2** — tức 0–2 trên 6 part khớp, một con Axie thật sự lai tạp. Purity 3–5 (phổ biến nhất) chỉ nhận gradient −3%/bậc, không mất keyword nào.

**Signature face miễn suppression** vì "part đó *là* part gì" là trục iconicity, không phải trục coherence (§3.3). `Wing Horn` mất `pierce` sẽ không còn là `Wing Horn`.

##### 3.4b-bis. Xung đột secret-class ↔ purity — giải bằng một luật, nêu tường minh

**Xung đột**: §3.10 **cố ý** cho 18 part secret-class face signature mạnh (r3), còn E14 ghi rằng một con Axie Dawn/Dusk/Mech thật **buộc phải lai** — Dawn chỉ có 7 identity phủ 5 slot và **không có part horn nào**, nên không tồn tại con Dawn "thuần". Hai trục kéo ngược chiều nhau trên **đúng cùng một con Axie**.

**Giải, hai bước:**

1. **`mapAxieClass` làm phần lớn công việc, không cần luật mới.** Body class của Axie Dawn là `beast` (`ORIGIN_CLASS_MAP`), và mọi part Dawn cũng map sang `beast` → **chúng đếm là khớp**. Nên một con Dawn với 3 part Dawn + 3 part Beast có `purity = 6` → `CoherenceMod = 1.00`. Xung đột biến mất trong trường hợp phổ biến nhất.
2. **`COH_FLOOR_SECRET = 0.91` cho phần còn lại.** Một con Dawn với 2 part Dawn + 4 part Aqua có `purity = 2` → sẽ là 0.88 và **mất cả keyword đắt**. Sàn kéo nó về **0.91** và **miễn suppression**.

**Nguyên tắc phía sau sàn — phạt lựa chọn, không phạt ràng buộc dữ liệu:**

> Purity phạt việc người chơi *chọn* một con Axie có part không hợp nhau. Nhưng một con Axie secret-class **không thể** thuần — điều đó do **catalog Axie quyết định**, không do người chơi. Phạt một điều kiện bắt buộc là phạt một thứ không có hành động sửa nào, và theo SDT đó là đòn trực diện vào Autonomy: người chơi nhận tín hiệu "sai" mà không có cách nào làm đúng.

Sàn 0.91 (= bậc purity 3) chứ không phải 1.00 để die toàn-secret **không** vừa được coherence đầy vừa được 18 face r3 — nó vẫn trả một mức nhẹ. Guardrail còn lại sau quyết định pay-to-win (2026-09-03): **chỉ còn L1** — loại tuyệt đối khỏi Skill board. `SP[X]` và `S(X)` không còn tác dụng nào vì `SBC_CAP` và handicap đã bỏ (§3.9, F9); `S(X) = 1.467` giờ chỉ là hệ số power thuần tuý trong F1c.

**Recalibrate `B_CAP` (yêu cầu Task 2B iii)**: coherence là **hệ số nhân ≤ 1**, nên nó **không thể** đẩy vượt trần — `B_CAP0` và `B_CAP_RUN` được đặt trước khi nhân coherence, và giữ nguyên ý nghĩa. Nhưng **dải tổng** thì đổi, và F1a ghi nhận đúng số mới: `B_CAP0 / (B[C] × 0.82) = 4.76 / 2.296 = **2.073×**`, không phải 1.70×. Đó là lý do lập luận đóng khung của F1 revision 1 phải bị thay (F1a).

#### 3.4c Gene tier — trục thứ tư, thứ CHƠI mới có

**Vấn đề đã verify**: một Axie import **đóng băng ở tier 1 suốt cả run**.
- `TIER_UP` (`src/data.js:108-109`) chỉ có khoá `plant1…bird2` — **không có** khoá `vault_*`, nên nhánh `mkReward('level')` (`:711-716`) lọc `TIER_UP[x.key]` và **không bao giờ** chọn được Axie import.
- Tệ hơn, `genRewards` (`src/engine.js:694`): `if(canLevel.length) pool.push('level','level'); else pool.push('ascend','ascend');` — `'ascend'` vào pool **chỉ khi KHÔNG hero nào lên tier được**. Một đội trộn hero + vault thì `canLevel` luôn khác rỗng gần suốt run ⇒ Axie import **bị bỏ đói cơ chế tăng trưởng duy nhất của nó**.
- Và `hp` cố định ở `HEROES[bodyCls+'1'].hp` (`axieToDie` :110), không bao giờ tăng.

**Thiết kế: reward `'gene'` — GENE EXPRESSION.**

```
B_run(bucket, part, g) = min( B_acq + GENE_STEP × g,  B_CAP_RUN )
GENE_STEP = 0.53 · GENE_MAX = 6 · B_CAP_RUN = 7.20          // GIỮ NGUYÊN revision 2
HP_STEP   = [0, 3, 5, 8, 10, 13, 15]          // = round(2.528 × g), neo vào 13.8 → 29.0 — KHÔNG ĐỔI
```

> **Cả `GENE_STEP` lẫn `B_CAP_RUN` giữ nguyên giá trị revision 2, nhưng `B_CAP_RUN` đổi LÝ DO tồn tại.** Nó không còn là "trần của cả run" trong một lập luận công bằng (bất đẳng thức đó đã thu hồi — F1b-α); nó là **trần TTK**: `7.20 × 1.018 / 6.39 = 1.15× hero tier-3`, mức mà `CURVE.budget` (không đổi) vẫn còn tạo ra trận đấu. `I23` kiểm.
>
> *(Một bản nháp của revision 3 đẩy hai số này lên 0.88 / 8.40 để giữ biên `PLAY_MARGIN ≥ 1.20`. Ràng buộc đó không còn.)*
>
> **`HP_STEP` cố ý KHÔNG bị `B_CAP_RUN` kẹp.** Đây là giảm thiểu chính *và* là cách reward `GENE EXPRESSION` giữ được giá trị cho người chơi đã chạm trần damage: die max-scarcity kẹp `B_run` ở gene 1 nhưng vẫn nhận đủ `+3/+5/+8/+10/+13/+15` HP qua 6 bậc.

Ladder so với hero (mean 6 class, avg positive face value; `avg ≈ B × 1.018` theo `SlotMod` trung bình):

| | gene 0 | gene 2 | gene 4 | gene 6 |
|---|---|---|---|---|
| Classic trộn hoàn toàn (coh 0.82) | 2.34 · **0.92× t1** | 3.22 | 4.11 | 4.99 · **0.78× t3** |
| Classic thuần | 2.85 · 1.13× t1 | 3.93 · **0.96× t2** | 5.01 | 6.09 · **0.95× t3** |
| Origin thuần (không gene) | 3.61 | 4.69 | 5.77 | 7.33 *(kẹp trần)* |
| Prime + `agamogenesis` | **6.83 · 1.07× t3** | 7.33 *(kẹp từ gene 1)* | 7.33 | 7.33 · **1.15× t3** ← `B_CAP_RUN` |
| *hero mốc* | *2.53 (t1)* | *4.11 (t2)* | — | *6.39 (t3)* |

**Ba điều đọc được từ bảng:**
1. **Hai hàng đầu giữ nguyên hiệu chuẩn revision 2**: trộn hoàn toàn 0.92× hero t1 → 0.78× t3; thuần Classic 1.13× t1 → **0.95× t3**. Đường tăng trưởng của người chơi phổ thông **không bị quyết định pay-to-win đụng tới một chút nào** — đó là điều quan trọng nhất trong bảng.
2. **Cột gene 0 là nơi pay-to-win biểu hiện**: 2.85 (thuần Classic) so với 6.83 (Prime + agamogenesis) = **2.40×**, và con số 6.83 đó đã bằng **1.07× hero tier-3** ngay từ wave 1. Đây là cái giá đã được product owner chấp nhận.
3. **Die đắt nhất kẹp trần từ gene 1** — nó đứng yên về damage trong 6/7 bậc gene, chỉ lớn thêm về HP và nhãn rarity. Không phải một cơ chế chống-whale (đã bỏ), mà là hệ quả của trần TTK: **trần áp cho mọi người như nhau, và người giàu chỉ đơn giản chạm nó trước**.

**Cơ chế reward — sửa `genRewards` mà KHÔNG đổi hành vi của đội toàn hero:**

```
const canLevel = s.roster.filter(r => TIER_UP[r.key]);
const canGene  = s.roster.filter(r => r.imported && (r.geneTier||0) < GENE_MAX);
if (canLevel.length) pool.push('level','level');
if (canGene.length)  pool.push('gene','gene');                      // ← THÊM
if (!canLevel.length && !canGene.length) pool.push('ascend','ascend'); // ← nhánh cũ, giữ nguyên semantics
```

> **Vì sao KHÔNG dùng bản vá tối thiểu "push `'ascend'` khi bất kỳ ai không lên tier được".** Bản vá đó **đổi hành vi base-game cho đội toàn hero**: ngay khi một hero đạt tier 3, `'ascend'` sẽ bắt đầu xuất hiện cạnh `'level'` ở chỗ trước đây không có — tức nó đổi phân phối reward của **mọi** run toàn-hero, gồm cả run ranked đã ship. Cách trên **không**: với roster toàn hero, `canGene` rỗng ⇒ `pool` byte-identical với hôm nay (AC-31 kiểm chính xác điều này). Chỉ đội có Axie import thấy hành vi mới — và đội đó **đã** bị loại khỏi Skill board (§3.9b L1). Rủi ro hồi quy được giới hạn đúng vào tập vốn đã bị cách ly.
>
> Đội **trộn** hero + import thì `pool` có thêm `'gene','gene'` (10 → 12 mục), làm loãng tần suất `'level'` từ 2/10 xuống 2/12. Đó là thay đổi thật, chỉ ảnh hưởng đội ranked-ineligible, và cần sim (AC-28).

`ENGINE_VERSION` (`src/engine.js:9`) **phải bump** — nhưng nó đã phải bump vì `axieToDie` đổi math, nên chi phí biên bằng 0. Đây là lý do gộp cả `THORNS_CAP` (E10b) vào cùng lần ship.

**Áp reward**: `e.geneTier = (e.geneTier||0) + 1`. Rồi `buildUnit` (`:42-48`) **dựng lại die từ `parts`**, không nhân face đã có:

```
const die = (h.imported && h.parts) ? resolveDie(h.parts, h.cls, re.geneTier||0) : clone(h.die);
```

**Vì sao dựng lại chứ không nhân như `'ascend'`** (`:794` dùng `{type:'oc',mult:1.25}`): `oc` chỉ nhân face có `f.v > 0` (`:52`), nên **mọi face `debuff`/`buff` `v=0` miễn nhiễm** — một Axie import với 2–3 mặt `debuff` (rất thường, `eyes` của beast/bird/bug đều là `debuff`) sẽ tăng trưởng **lệch**. Dựng lại từ `parts` cho `N` của face `debuff` lớn lên đúng theo `kwBudget` (F5b), nên cả sáu mặt tiến cùng nhau. Nó cũng là điều làm Growth moment (§2 khoản 5) đọc được: *bộ gene của chính nó biểu hiện thêm*, không phải một buff dán lên.

**Điều kiện tiên quyết**: entry Vault phải lưu **`parts` manifest**, không chỉ die đã resolve → schema 3 (`N16`, E13). Cùng một migration cũng phục vụ §3.9e bước 4 (server rebuild) — một thay đổi, hai yêu cầu.

**KHÔNG đưa gene tier vào handicap §3.9d.** Nó là cơ hội ngang nhau cho mọi người chơi; handicap nó là phạt người chơi giỏi. Đây là phân biệt mà revision 1 chưa cần làm.

### 3.5 Variant family — cấu trúc và cơ chế gán

#### 3.5a Cấu trúc

36 family = 6 class × 6 slot. Mỗi family có `V` variant hand-designed, `V ∈ [4, 6]`.

`V` **không** tuỳ ý. Luật xác định `V`:

```
V(class, slot) = clamp( maxBucketSize(class, slot), 4, 6 )

maxBucketSize = số part NON-SIGNATURE lớn nhất mà một bucket đơn lẻ
                (C, O, hoặc P) chiếm trong family đó
```

**Lý do luật này tồn tại**: hai part cùng family cùng variant **cùng bucket** sẽ ra face y hệt. Đặt `V ≥ maxBucketSize` cho phép gán **đơn ánh trong mỗi bucket** → **không bao giờ có hai part cùng family ra face giống nhau**. Đây chính là điều product owner đòi ("Two Beast Mouths must genuinely play differently") và nó được bảo đảm bởi *cấu trúc bảng*, không bởi việc designer cẩn thận.

Đã verify: `maxBucketSize ≤ 6` cho **cả 36 family** (giá trị lớn nhất là Beast·Mouth = 6, sau khi Cub vào Icon List — xem §3.5c). Nên luật luôn khả thi trong dải 4–6 mà product owner đặt ra.

#### 3.5b Bảng `V` và phân hoạch bucket của 36 family

`nC/nO/nP` = số part **non-signature** theo bucket. `nSig` = số signature. Tổng mỗi hàng = số identity thật trong family.

| Family | identity | nSig | nC | nO | nP | maxBucket | **V** |
|---|---|---|---|---|---|---|---|
| beast·mouth | 11 | 5 | 0 | 6 | 0 | 6 | **6** |
| beast·horn | 11 | 4 | 2 | 5 | 0 | 5 | **5** |
| beast·back | 7 | 1 | 5 | 1 | 0 | 5 | **5** |
| beast·tail | 8 | 0 | 4 | 2 | 2 | 4 | **4** |
| beast·eyes | 8 | 2 | 1 | 4 | 1 | 4 | **4** |
| beast·ears | 7 | 1 | 1 | 1 | 4 | 4 | **4** |
| aqua·mouth | 5 | 2 | 2 | 1 | 0 | 2 | **4** |
| aqua·horn | 8 | 1 | 5 | 2 | 0 | 5 | **5** |
| aqua·back | 6 | 1 | 4 | 0 | 1 | 4 | **4** |
| aqua·tail | 8 | 0 | 5 | 2 | 1 | 5 | **5** |
| aqua·eyes | 7 | 1 | 3 | 3 | 0 | 3 | **4** |
| aqua·ears | 7 | 2 | 4 | 1 | 0 | 4 | **4** |
| plant·mouth | 7 | 1 | 3 | 3 | 0 | 3 | **4** |
| plant·horn | 11 | 1 | 5 | 5 | 0 | 5 | **5** |
| plant·back | 11 | 1 | 5 | 5 | 0 | 5 | **5** |
| plant·tail | 9 | 1 | 5 | 3 | 0 | 5 | **5** |
| plant·eyes | 5 | 2 | 1 | 1 | 1 | 1 | **4** |
| plant·ears | 8 | 1 | 4 | 2 | 1 | 4 | **4** |
| bird·mouth | 5 | 1 | 3 | 1 | 0 | 3 | **4** |
| bird·horn | 7 | 3 | 3 | 1 | 0 | 3 | **4** |
| bird·back | 10 | 1 | 5 | 4 | 0 | 5 | **5** |
| bird·tail | 7 | 5 | 1 | 1 | 0 | 1 | **4** |
| bird·eyes | 6 | 2 | 2 | 2 | 0 | 2 | **4** |
| bird·ears | 6 | 1 | 5 | 0 | 0 | 5 | **5** |
| bug·mouth | 6 | 2 | 2 | 2 | 0 | 2 | **4** |
| bug·horn | 6 | 1 | 5 | 0 | 0 | 5 | **5** |
| bug·back | 6 | 1 | 5 | 0 | 0 | 5 | **5** |
| bug·tail | 10 | 2 | 4 | 4 | 0 | 4 | **4** |
| bug·eyes | 5 | 1 | 3 | 1 | 0 | 3 | **4** |
| bug·ears | 9 | 0 | 5 | 3 | 1 | 5 | **5** |
| reptile·mouth | 6 | 2 | 2 | 2 | 0 | 2 | **4** |
| reptile·horn | 7 | 3 | 2 | 1 | 1 | 2 | **4** |
| reptile·back | 7 | 3 | 2 | 1 | 1 | 2 | **4** |
| reptile·tail | 6 | 4 | 2 | 0 | 0 | 2 | **4** |
| reptile·eyes | 6 | 2 | 2 | 2 | 0 | 2 | **4** |
| reptile·ears | 8 | 2 | 3 | 2 | 1 | 3 | **4** |
| **TỔNG** | **267** | **63** | **115** | **74** | **15** | — | **158** |

**Kiểm tra số học — hai identity ĐỘC LẬP, không phải một checksum.**

Revision 1 ghi `119 / 73 / 12` và tự kiểm bằng `63 + 119 + 73 + 12 = 267 ✓`. Cả ba con số đều **sai**, và checksum vẫn pass vì ba sai số triệt tiêu nhau (`+4 − 1 − 3 = 0`). Đó là một checksum **không có khả năng chẩn đoán, do chính cách nó được xây dựng**: nó chỉ ràng buộc *tổng*, nên mọi sai số bù trừ đều lọt. `nP = 12` còn mâu thuẫn trực tiếp với §3.4 ("15 part Prime còn lại") ba mục trước đó.

Thay bằng **hai** identity ràng buộc theo hai chiều khác nhau — một sai số bù trừ trong bảng không thể làm cả hai cùng pass:

```
I1 (chiều cột):   nC + nO + nP                     = 115 + 74 + 15 = 204   ✓  ( = số khoá PART_VARIANT )
I2 (chiều bucket): nP = 18 − |Prime ∩ Signature|   = 18 − 3        = 15    ✓  ( §3.4 )
```

`I1` neo vào **§3.12** (bảng gán phải có đúng 204 dòng). `I2` neo vào **§3.4** (18 part Prime, 3 trong đó là Signature: Nut Cracker·mouth, Gill·ears, Scar·eyes). Hai neo ở hai bảng khác nhau, nên một lỗi đánh máy trong §3.5b sẽ **luôn** làm ít nhất một identity đổ. Cả hai là AC-6b (BLOCKING).

Kiểm phụ (vẫn giữ, nhưng **không** còn là kiểm duy nhất): `63 + 204 = 267` = 285 identity − 18 secret-class ✓. Tổng `V` = **158 variant**.

`V` sum theo class: beast 28 · aqua 26 · plant 27 · bird 26 · bug 27 · reptile 24 = **158** ✓

**Family có variant thừa (spare)** — **9 family, 11 spare**, khớp chính xác danh sách liệt kê ở §3.12:

| Family | V | variant đã dùng | spare |
|---|---|---|---|
| aqua·mouth | 4 | B, C, D | `A` |
| plant·eyes | 4 | B, C, D | `A` |
| bird·tail | 4 | B, C | `A`, `D` |
| bird·eyes | 4 | A, B, C | `D` |
| bug·mouth | 4 | A, B, C | `D` |
| bug·eyes | 4 | A, B, C | `D` |
| reptile·horn | 4 | B, C, D | `A` |
| reptile·back | 4 | A, B, C | `D` |
| reptile·tail | 4 | B, C | `A`, `D` |
| **TỔNG** | — | — | **11** |

> **Sửa lỗi revision 1 (defect 2 của review).** Bản trước ghi *"≤ 10 trên toàn hệ (hiện: 8)"* và liệt kê 5 family, trong đó có **`aqua·back`** — family này có **0 spare** (5 part-slot dùng hết cả 4 variant, `Goldfish` và `Sponge` đều →`D` nhưng ở hai bucket khác nhau nên R1 vẫn thoả). Nó đồng thời **bỏ sót 5 family** thật có spare: `bird.eyes`, `bug.mouth`, `bug.eyes`, `reptile.horn`, `reptile.back`.
>
> Hậu quả nếu không sửa: §3.12 và AC-6 đều nói **11**, nhưng một người viết test đọc §3.5b sẽ viết `assert(spares <= 10)` và **CI đổ ngay lần chạy đầu**. Trần mới: **≤ 12**, hiện **11** — chọn 12 chứ không phải 11 để việc thêm đúng một part mới vào catalog không làm đổ build vì lý do không liên quan đến chất lượng thiết kế.

Variant thừa **không phải padding** — chúng là chỗ chứa forward-compatible cho part Axie thêm sau này (catalog đã lớn từ 192 → 285 một lần rồi), và chúng cũng là ứng viên cho `FACE_POOL` mở rộng ở Phase 2. AC-6 kiểm **con số 11 và cả tập 11 chuỗi**, không chỉ con số — vì con số đúng với tập sai là đúng loại lỗi mà revision 1 mắc.

#### 3.5c Cơ chế gán — `PART_VARIANT`, curated, không hash

```
PART_VARIANT : partKey → variantId          // bảng tĩnh, 204 dòng, hand-curated
```

**Bắt buộc là bảng tra tay, KHÔNG được là hash.** Ba lý do:

1. **Auditable** — product owner phải mở được bảng và nói "Ronin không nên là variant B" rồi sửa một dòng. Hash không cho phép điều đó.
2. **Flavour đúng** — "Nut Cracker" nên là biến thể multi-hit, "Venom Nail" nên là biến thể độc. Hash cho ra kết quả ngẫu nhiên về nghĩa.
3. **Determinism không đủ để thay thế** — hash *là* tất định, nhưng tất định không phải mục tiêu duy nhất; nguyên tắc hash-free của doc cũ (`src/data.js:115` *"KHÔNG cá nhân hoá theo part.name/part.id"* — phần "không hash" đáng giữ, phần "không cá nhân hoá" thì bỏ) là đúng và giữ lại.

**Luật curate** (áp dụng khi viết 204 dòng ở §7, và khi thêm part mới):

- **R1 — Injectivity trong bucket (BẤT BIẾN, không được vi phạm)**: trong một family, hai part cùng bucket **không được** cùng variant.
- **R2 — Flavour trước**: đọc tên part, chọn variant khớp nghĩa nhất trong số variant còn trống của bucket đó. `Sniffle` → lifesteal (hút). `Pangolin` → heavy/armour. `Shocker` → chain.
- **R3 — Cân đối tải**: không variant nào nhận > `ceil(nNonSig / V) + 1` part trong cùng family.
- **R4 — Không hình phạt/thưởng ẩn theo bucket**: khi một part chuyển bucket (Axie phát hành bản α mới cho part cũ), variant của nó **không đổi** — chỉ `B` đổi. Nghĩa là bảng gán ổn định qua patch catalog.
- **R5 — Signature-disjointness (BẤT BIẾN)**: một variant face, ở **bất kỳ bucket nào**, không được trùng tuple `(t, v, k)` với **bất kỳ signature face nào trong cùng family**. Nếu trùng, hai part khác nhau trong cùng family ra face y hệt — cùng lỗi mà R1 chống, chỉ ở trục khác.
- ~~**R6 — Keyword-set uniqueness trong family**~~ — **SUPERSEDED ở revision 3 bởi R7.** R6 chỉ cấm trùng `(t, sortedKeys)` *trong một family*; R7 mở phạm vi lên *toàn slot*, nên R6 là hệ quả. Giữ tên R6 trong lịch sử để đọc được các ghi chú cũ, nhưng bất biến máy kiểm là R7 (`I5`).
- **R7 — Slot-wide keyword-set uniqueness (BẤT BIẾN, MỚI ở revision 3 — đây là luật đóng khoảng trống 285)**: trong **một slot**, không hai *reachable* variant template nào (bất kể class) được có cùng `(t, sortedKeys)`.
- **R8 — Signature slot-disjointness (BẤT BIẾN, MỚI ở revision 3)**: trong một slot, tuple `(t, v, sortedKeys)` của **mọi** signature face phải khác **mọi** signature face khác **và** khác **mọi** variant instance reachable trong cùng slot đó. Bảo đảm bởi SPREAD pass (§3.5d), chỉ được sửa phía **authored** (13 Addendum + 18 Secret), **không bao giờ** sửa 50 face legacy.

> **R7 + R8 là lý do "285 face engine-distinct" đúng do CẤU TRÚC, không do đếm may.**
>
> Chứng minh, ba nhánh vét cạn hết mọi cặp part:
> 1. **Khác slot** ⇒ `p` khác ⇒ tuple khác. (`p` nằm trong tuple engine — §3.13.)
> 2. **Cùng slot, cùng variant template** ⇒ khác bucket (R1 cấm hai part cùng bucket cùng variant trong một family; và hai family khác nhau không dùng chung template) ⇒ F6 monotone **nghiêm ngặt** cho `v(C) < v(O) < v(P)` ⇒ `v` khác ⇒ tuple khác.
> 3. **Cùng slot, khác variant template** ⇒ R7 ⇒ `(t, sortedKeys)` khác ⇒ tuple khác. Nếu một trong hai là signature ⇒ R8.
>
> ⇒ **285 part → 285 tuple `(p, t, v, k)` phân biệt**, và điều đó **không phụ thuộc `B[C]`**. Đây là điểm mấu chốt: revision 2 đã học được rằng mọi thứ dựa vào `v` đều mong manh trước tuning (chính lý do R6 ra đời). R7 đưa toàn bộ gánh nặng phân biệt sang trục keyword — trục duy nhất không bị nén khi hạ ngân sách.
>
> **Giá phải trả, nêu tường minh** — R7 phá một quy ước dễ chịu của §3.11: hiện **cả 36 family** đều đặt "baseline thuần số, 0 keyword" ở variant `A`. Với R7, trong một slot chỉ **một** family được giữ baseline trần; 5 family còn lại phải gắn cho `A` một **rider bản sắc class** (`exec`/`vulnerable` cho Beast, `mana:N` cho Aqua, `growth`/`regen` cho Plant, `pierce` cho Bird, `poison:N` cho Bug, `thorns:N` cho Reptile — đúng bộ keyword mà F5 đã định giá surcharge, nên flavour và giá đều có sẵn). Đó thực ra là **cải thiện**: mọi mặt dice mang bản sắc class đọc được, thay vì 6 face `dmg 6` giống hệt nhau ở 6 class. E1 (fallback) vì vậy đổi từ "luôn dùng variant `A`" sang "dùng variant được đánh dấu `baseline: true` của family", vì `A` không còn chắc là mặt nhàm nhất.
>
> Hệ quả có lợi **vẫn giữ**: hai variant **được phép** ra cùng `v` (ví dụ `beast.mouth.B` `dmg·lifesteal` và `beast.mouth.C` `dmg·growth` cùng giá keyword 1.50 nên luôn cùng `v`). Đó là *sidegrade*, đúng thiết kế. R7 chỉ cấm trùng **keyword set**, không cấm trùng **số**.

##### 3.5c-bis. Ngân sách keyword-set: R7 đòi bao nhiêu, §3.11 đang có bao nhiêu

R7 đòi: với mỗi slot, số `(t, sortedKeys)` phân biệt trong tập variant reachable ≥ số variant reachable của slot đó. Đây là con số đo được ngay từ bảng §3.11 + §3.12 hôm nay:

| slot | variant reachable | `(t,k)` phân biệt **hiện có** | **thiếu** | signature trong slot |
|---|---|---|---|---|
| mouth | 24 | 11 | **13** | 14 |
| horn | 27 | 10 | **17** | 17 |
| back | 27 | 15 | **12** | 13 |
| tail | 22 | 15 | **7** | 16 |
| eyes | 21 | 11 | **10** | 13 |
| ears | 26 | 8 | **18** | 8 |
| **TỔNG** | **147** | **70** | **77** | **81** |

**Đọc bảng này đúng cách**: 147 variant template hiện chỉ dùng **70** bộ keyword khác nhau — tức thiết kế §3.11 đang **copy-paste 77 lần**. `ears` tệ nhất (26 template, 8 bộ keyword: 5/6 class có y hệt `mana·cantrip` / `mana` / `mana·cantrip·rerollup` / `mana·cantrip·selfharm:N`). Đó **chính là** nguyên nhân số học của khoảng trống 285 → **190**, và nó là công việc authoring có thể đếm được: **77 bộ keyword mới**, phân bổ đúng theo cột "thiếu". *(Con số 70/147 ở bảng này là phép đo **độc lập** với phép đếm distinct-face, nên nó không bị ảnh hưởng bởi việc đếm tay 201 sai — máy xác nhận cả hai.)*

**Ba nguồn keyword-set mới, xếp theo giá phải trả — dùng hết nguồn 1 và 2 trước khi chạm nguồn 3:**

1. **Đổi magnitude (giá gần bằng 0).** `k` là **chuỗi**, nên `selfharm:1` ≠ `selfharm:2`, `regen:2` ≠ `regen:3`, `crit:15` ≠ `crit:30`, `multi:2` ≠ `multi:3`, `chain:3` ≠ `chain:4`, `poison:2` ≠ `poison:3`, `thorns:2` ≠ `thorns:3`, `blind:1` ≠ `blind:2`, `weaken:2` ≠ `weaken:3`, `mana:1` ≠ `mana:2`. Chi phí ngân sách là **một bậc per-stack** (F4) — nhỏ, và hoàn được vào `v`. Đây phải là nguồn chính; nó không tạo keyword stack phi lý và không làm face bị clamp.
2. **Rider bản sắc class (giá thấp, flavour TĂNG).** Đúng 6 keyword F5 đã định giá surcharge. Cho phép mỗi family gắn rider của class mình lên baseline và lên 1–2 variant nữa.
3. **Lệch type có chủ đích (giá trung bình).** §3.11 đã có tiền lệ (`aqua.ears.D` = `shield`, `bird.ears.E` = `debuff`) và engine **không ràng buộc slot↔type** — `p` chỉ là nhãn hiển thị. Một variant lệch type cho ngay một bộ keyword mới và một kiểu chơi mới. Đây là nguồn phải dùng ở `ears` (18 thiếu trên 26 template — không thể giải hết bằng magnitude của một type `mana` duy nhất).

**Nguồn KHÔNG được dùng**: chồng thêm keyword đắt (`aoe` 3.60, `cleave` 3.10, `pierce` 2.30) để tạo bộ mới. Ở `B_eff ≈ 2.80` production, mỗi keyword đắt thêm đẩy face về `max(1, ·)` — generator ghi `clampFloor[]` và một face `v = 1` là một face **chết**. `I19` giới hạn: số ô `clampFloor` ở profile production **không được tăng quá 20%** so với snapshot trước khi re-author.

**Trạng thái: ĐÃ AUTHOR ĐỦ (2026-09-03).** Cả 77 bộ nằm ở **§3.11-R7**, chia theo slot, 147/147. Bảng "thiếu" ở trên giữ lại làm **hồ sơ chẩn đoán** — nó ghi lại quy mô vấn đề và là cách đo tiến độ nếu ai thêm family/variant mới sau này. `I5`/`AC-34` giờ phải **xanh**; nếu đỏ thì §3.11-R7 đã bị sửa lệch. Công việc còn lại của `N17` chỉ là để generator re-emit cột số.

##### 3.5c-ter. Năm luật authoring — áp cho mọi bộ keyword mới

Đây là ràng buộc bắt buộc khi viết §3.11-R7, không phải gợi ý. Bốn luật đầu đã có bất biến; luật thứ năm là **mới** và nó vá một lỗ mà R7/R8 không tự bịt.

1. **`I20` — tối đa 3 keyword/variant.** Ở `B_eff ≈ 2.80` production, keyword thứ tư luôn đẩy face về `max(1, ·)`.
2. **`I19` — số ô `clampFloor` không tăng quá 20%.** Chặn việc giải R7 bằng cách chồng keyword đắt.
3. **`I21` — class type whitelist.** Beast và Bird: **không** `shield`/`heal`. Plant: **không** `poison` (type). Vi phạm = fail.
4. **§3.7a kwPure Direction Law** — kiểm cho *mọi* bộ mới, không chỉ bộ cũ:
   - `dmg`/`debuff` — **cấm** `thorns:N` `regen:N` `undying` `enrage`;
   - `shield`/`heal`/`buff` — **cấm** `burn:N` `poison:N` `weaken:N` `vulnerable:N` `blind:N` `stun` `freeze`;
   - `mana`/`summon`/`poison` — **mọi** kwPure đều trơ. Rider dùng được **thật sự** trên `mana` chỉ có bảy: `cantrip` `rerollup` `growth` `decay` `heavy` `vital` `selfharm:N`. (`aoe`/`multi`/`chain`/`crit`/`cleave`/`lifesteal`/`exec` **không** đụng tới `s.mana += v` nên chúng là keyword **chết** trên face `mana` — không được dùng để tạo bộ mới.) Trên `poison` dùng được: `aoe` `multi:N` `pierce` `heavy` `growth` `decay` `selfharm:N` `vital`.
   - **E7** — `cantrip` chỉ trên `mana`/`heal`/`shield`/`buff`/`summon`, hoặc trên face có `aoe`.
5. **`I24` 🆕 — variant KHÔNG được trùng `(t, sortedKeys)` với bất kỳ signature LEGACY nào cùng slot.** Lý do: R8/SPREAD giải collision bằng cách nhích `v`, nhưng nó **chỉ được nhích 31 face authored**, không bao giờ nhích 50 face legacy (AC-7c). Nếu một variant template dùng chung bộ keyword với một legacy signature, va chạm chỉ còn phụ thuộc `v` — tức phụ thuộc `B[C]` — và đó đúng là sự mong manh mà R7 tồn tại để diệt. **Rẻ hơn nhiều là tránh bộ keyword đó ngay từ đầu.**
   > **Phạm vi của `I24`: MỌI bộ legacy trong slot, không lọc theo khả năng chi trả.** Một số bộ legacy đắt tới mức không variant nào mua nổi ở `B_eff ≈ 2.80` (`chain:5` một mình đã tốn `1.40 × 4 = 5.60`, gấp đôi cả ngân sách). Cám dỗ là bỏ chúng khỏi danh sách cấm vì "không thể va chạm được". **Không làm thế**: lập luận đó dựa vào `B[C]`, mà `B[C]` là một knob — và toàn bộ lý do R7/`I24` tồn tại là để tính phân biệt **không** phụ thuộc `B[C]`. Một danh sách cấm đầy đủ luôn đúng; một danh sách cấm đã lọc chỉ đúng cho tới lần tune tiếp theo.
   >
   > Hệ quả cụ thể ở slot `mouth` — **chín** bộ cấm (đếm từ `FACE_POOL`, không từ trí nhớ):
   >
   > | bộ | legacy |
   > |---|---|
   > | `dmg` | Zigzag, Razor Bite |
   > | `dmg·lifesteal` | Toothless Bite |
   > | `dmg·growth` | Confident |
   > | `dmg·growth·lifesteal` | Axie Kiss |
   > | `dmg·multi:3` | Nut Cracker |
   > | `dmg·exec` | Lam |
   > | `dmg·crit:40·lifesteal` | Piranha (r3) |
   > | `dmg·chain:5·crit:30` | Goda (r3) |
   > | `dmg·crit:100·lifesteal` | Mosquito (r4) |
   >
   > Ba bộ cuối là **thiếu sót của bản nháp đầu revision 3**, đã sửa: chúng bị bỏ quên đúng vì lý luận "variant không mua nổi" ở trên — tức tôi đã tự áp một bộ lọc affordability cho riêng slot mouth trong khi năm slot còn lại đếm đủ. Đó là **mâu thuẫn nội bộ về phương pháp**, và nó sẽ làm `AC-34b` đổ ngay lần đầu có checker tính con số từ dữ liệu. Cùng hạng lỗi với `FACE_POOL.length === 63` (§3.8). Bài học ghi lại: **đếm bộ cấm bằng máy từ `FACE_POOL`, không bằng cách liệt kê tay.**
   >
   > Đã kiểm: **không** bộ nào trong 24 bộ mouth của §3.11-R7 trùng ba bộ mới bổ sung — không variant mouth nào dùng `chain`, `crit:40` hay `crit:100`. Nên phát hiện này **không** đổi một dòng thiết kế nào, chỉ đổi con số assert.

#### 3.11-R7. Phân bổ `(t · k)` — **NGUỒN SỰ THẬT DUY NHẤT** của keyword set

> ## ⛔ HỢP ĐỒNG PARSER — đọc trước khi viết generator
>
> **Đúng một chỗ trong toàn doc định nghĩa `(t, k)` cho một variant: bảng hợp nhất ở `### 3.11`** (158 variant, một bảng, một heading level).
> Mọi bảng khác — **kể cả khối §3.11-R7 ngay dưới đây** — là **văn bản lịch sử, KHÔNG được parse**, và được bọc trong `GEN:IGNORE`.
>
> ```
> <!-- GEN:VARIANT_KW BEGIN -->   … bảng có thẩm quyền …   <!-- GEN:VARIANT_KW END -->
> <!-- GEN:IGNORE BEGIN -->       … văn bản không parse …   <!-- GEN:IGNORE END -->
> ```
>
> **Generator phải BỎ QUA mọi thứ giữa `GEN:IGNORE BEGIN` và `GEN:IGNORE END`**, kể cả khi nó nằm trong lát cắt heading.
>
> Vì sao có hợp đồng này: cắt theo heading là **lỗi đã xảy ra thật**. `tools/gen_faces.mjs` bản đầu cắt `/^### 3\.11 /`…`/^### 3\.12 /`, nuốt trọn bảng cũ và **không bao giờ thấy** 77 bộ keyword mới — nên ma trận của nó cho "R7 bật" và "R7 tắt" ra **cùng một con số**. Điều đó trông như *R7 vô tác dụng*, không như *một lỗi parse*, và đó là kiểu hỏng đắt nhất: nó vu oan cho thiết kế thay vì tố cáo công cụ. Sau hợp nhất, lát cắt heading đã đúng — nhưng fence vẫn cần, vì heading trôi khi doc được sắp xếp lại còn comment thì không.
>
> `I26` assert ba điều: (a) mọi `GEN:IGNORE BEGIN` có đúng một `END` khớp; (b) **0** `variantId` được định nghĩa bên ngoài `### 3.11`; (c) mỗi `variantId` xuất hiện **≤1 lần** trong `### 3.11`.

<!-- GEN:IGNORE BEGIN -->

> ## 📕 KHỐI NÀY LÀ LỊCH SỬ — KHÔNG PHẢI NGUỒN SỰ THẬT
>
> **Nguồn sự thật của `(t, k)` cho cả 158 variant là `### 3.11`**, bảng hợp nhất mà generator đọc. Khối dưới đây là **bản nháp authoring** của pass R7: nó ghi lại *vì sao* 77 bộ keyword được thêm và *theo luật nào*, nhưng dữ liệu của nó **đã được chuyển hết** sang §3.11 và không được parse.
>
> Giữ lại vì hai lý do, cả hai là *lý luận* chứ không phải *dữ liệu*: (a) bảng thâm hụt theo slot (70 → 147) là bằng chứng đo được cho khoảng trống 285; (b) danh sách bộ legacy bị `I24` cấm theo slot là đầu vào thiết kế mà `AC-34b` assert. Nếu hai thứ đó được chuyển sang §3.11 sau này thì **xoá hẳn khối này**.
>
> ⚠️ **Không sửa `(t, k)` ở đây.** Sửa ở §3.11. Sửa hai chỗ chính là lỗi hai-nguồn-sự-thật mà tài liệu này tồn tại để chống — nó đã xảy ra một lần trong chính tài liệu này (generator đọc bảng cũ, thấy R7 "không có tác dụng"), và lần đó tốn một vòng lặp đầy đủ mới phát hiện.

**Phạm vi bản nháp**: 147 reachable variant template, 6 slot. `variantId` = `class.slot.LETTER`. Ô `(spare)` = variant chưa part nào dùng (§3.12).

> **Cột số `C/O/P` VÔ HIỆU ở mọi bảng của doc này.** Đổi bộ keyword ⇒ `KW` đổi ⇒ `v` đổi. **Không sửa tay 474 ô.** `gen_faces.mjs` re-emit toàn bộ `C/O/P` ở cả hai profile từ `(t, k)` dưới đây qua F2→F5a→F4→F5b→F6, rồi `SIG_LIFT` (§3.3c) → REPAIR → SPREAD. AC-7 (474/474 khớp ô) **đóng băng** cho tới khi generator sinh bảng tham chiếu mới; bảng đó commit làm snapshot và thành mốc AC-7 kế tiếp.
>
> **Tên variant (`Bleeder`, `Clean Bite`, …) của §3.11 cũ KHÔNG còn hiệu lực** và cố ý không mang sang đây: chúng được đặt cho bộ keyword cũ và giờ mô tả sai. Ví dụ `beast.mouth.B` từng là `Bleeder` = `dmg·lifesteal`, nay là `dmg·lifesteal·selfharm:1`. Đặt lại tên là việc của `N17b` (§9a) — **sau** khi generator chốt số, để tên khớp cả bộ keyword lẫn dải giá trị. Giữ tên cũ sẽ tái tạo đúng vấn đề hai-nguồn-sự-thật ở trục *tên* thay vì trục *số*.

##### EARS — 26/26 template, 26 bộ phân biệt ✅

Slot tệ nhất hôm nay (26 template / **8** bộ — cả sáu class dùng chung khối `mana·cantrip` / `mana` / `mana·cantrip·rerollup`). Đây cũng là slot mà hiện trạng tệ nhất: `SLOT_CLASS_TEMPLATE` cho **cả 6 class** cùng một face `mana 1 · cantrip`, nên **mọi con Axie trong game hôm nay có cùng một mặt ears**. Sau khi author, 26 part ears variant ra 26 kỹ năng khác nhau.

Chỉ dùng 7 rider hợp lệ trên `mana` (luật 4) + 5 type-break có bản sắc class.

| family | v | `t · k` | Bản sắc |
|---|---|---|---|
| **aqua** *(CONDUIT — class của mana)* | A | `mana · cantrip · rerollup` | tempo thuần |
| | B | `mana` | mana cao, chiếm lượt |
| | C | `mana · cantrip · mana:1` | **CONDUIT thuần nhất** — face mana lại còn cấp thêm mana. `mana:N` chạy ở `doFace` khối `if(!isEcho)`, **ngoài** đường kwPure, nên nó có hiệu lực thật trên face `mana` |
| | D | `shield · mana:1` | **type-break** (giữ nguyên revision 2) |
| **plant** *(BULWARK — growth/kiên nhẫn)* | A | `mana · cantrip · growth` | mana tự lớn |
| | B | `mana · growth` | — |
| | C | `mana · rerollup · growth` | — |
| | D | `mana · cantrip · vital` | quang hợp khi HP đầy |
| **bug** *(VIRULENT — bầy đàn, tự bào mòn)* | A | `mana · cantrip · selfharm:1` | — |
| | B | `mana · selfharm:2` | — |
| | C | `mana · cantrip · decay` | — |
| | D | `mana · decay` | — |
| | E | `debuff · poison:N` | **type-break** |
| **beast** *(FERAL — thô, nặng)* | A | `mana · cantrip · heavy` | — |
| | B | `mana · heavy` | — |
| | C | `mana · cantrip · selfharm:2` | — |
| | D | `debuff · vulnerable:N` | **type-break**, setup FERAL |
| **bird** *(TALON — nhẹ, mạo hiểm)* | A | `mana · rerollup` | — |
| | B | `mana · cantrip · selfharm:3` | rủi ro cao nhất |
| | C | `mana · rerollup · vital` | — |
| | D | `mana · vital` | — |
| | E | `debuff · blind:N` | **type-break** (giữ nguyên revision 2) |
| **reptile** *(SCALES — chậm, gai)* | A | `mana · rerollup · heavy` | — |
| | B | `mana · selfharm:1` | — |
| | C | `mana · growth · heavy` | — |
| | D | `buff · thorns:N` | **type-break**, `thorns` → ally ✓ |

**Kiểm bảng ears** — cả sáu luật:

| Luật | Kết quả |
|---|---|
| R7 — 26 bộ phân biệt / 26 template | ✅ 0 trùng |
| `I20` ≤3 keyword | ✅ tối đa **2** |
| Rider trên `mana` ⊆ 7 rider hợp lệ (`cantrip` `rerollup` `growth` `decay` `heavy` `vital` `selfharm:N`) + `mana:N` | ✅ 0 keyword chết |
| E7 — `cantrip` chỉ trên `mana`/`heal`/`shield`/`buff`/`summon` | ✅ mọi `cantrip` nằm trên `mana` |
| §3.7a — hướng kwPure | ✅ `debuff·poison:N` / `debuff·vulnerable:N` / `debuff·blind:N` hướng địch; `buff·thorns:N` hướng ally |
| `I21` — whitelist type | ✅ Beast/Bird không `shield`/`heal`; Plant không `poison` |
| **`I24`** — không trùng legacy cùng slot | ✅ Legacy ears là `mana·cantrip` (**Gill**), `mana·cantrip·rerollup` (**Nyan**, **Friezard**), `mana·cantrip·overflow` (**Sidebarb**). ⚠️ `aqua.ears.A` = `mana·cantrip·rerollup` **trùng Nyan/Friezard** ⇒ đây là va chạm **variant ↔ legacy**, và `I24` cấm nó |

> **Xử lý va chạm cuối cùng của ears, ghi lại để không ai "sửa gọn" rồi tái tạo nó:** `mana·cantrip·rerollup` là bộ của **hai** legacy signature (`Nyan` r2, `Friezard` r3), nên `I24` cấm mọi variant dùng nó — kể cả `aqua.ears.A`. Thay bằng **`mana · rerollup · vital`**? đã dùng ở `bird.ears.C`. Thay bằng **`mana · cantrip · rerollup · growth`**? vượt ý đồ và chạm trần 3 keyword một cách vô ích.
>
> **Chốt: `aqua.ears.A` = `mana · cantrip · selfharm:1`**, và `bug.ears.A` đổi sang **`mana · cantrip · growth`**, `plant.ears.A` đổi sang **`mana · cantrip · decay`**, `bug.ears.C` đổi sang **`mana · rerollup · decay`**. Bốn ô đổi chỗ, tổng vẫn 26 bộ phân biệt, và không bộ nào còn trùng legacy. Lý do đẩy `selfharm:1` sang Aqua: CONDUIT trả HP lấy tempo là một mô-típ hợp lệ, còn Bug giữ `selfharm:2` ở `B` nên bản sắc "tự bào mòn" của Bug không mất.

**Bảng ears sau bốn ô đổi chỗ** *(đây là bảng có hiệu lực; bảng phía trên là bản nháp trước khi áp `I24`)*:

| family | A | B | C | D | E |
|---|---|---|---|---|---|
| **aqua** | `mana·cantrip·selfharm:1` | `mana` | `mana·cantrip·mana:1` | `shield·mana:1` | — |
| **plant** | `mana·cantrip·decay` | `mana·growth` | `mana·rerollup·growth` | `mana·cantrip·vital` | — |
| **bug** | `mana·cantrip·growth` | `mana·selfharm:2` | `mana·rerollup·decay` | `mana·decay` | `debuff·poison:N` |
| **beast** | `mana·cantrip·heavy` | `mana·heavy` | `mana·cantrip·selfharm:2` | `debuff·vulnerable:N` | — |
| **bird** | `mana·rerollup` | `mana·cantrip·selfharm:3` | `mana·rerollup·vital` | `mana·vital` | `debuff·blind:N` |
| **reptile** | `mana·rerollup·heavy` | `mana·selfharm:1` | `mana·growth·heavy` | `buff·thorns:N` | — |

26 bộ, 0 trùng nhau, 0 trùng legacy ✓

##### MOUTH — 24/24 template, 24 bộ phân biệt ✅

**Chín** bộ bị `I24` cấm (danh sách đủ ở luật 5, §3.5c-ter — gồm ba bộ `crit`/`chain` bậc r3/r4 mà bản nháp đầu bỏ sót). Hệ quả cố ý: **không family nào giữ `dmg` trần ở mouth** — mọi mặt mouth mang một rider bản sắc class, đúng tinh thần "class identity đọc được trên mọi mặt" của R7.

| family | A | B | C | D | E | F |
|---|---|---|---|---|---|---|
| **beast** | `dmg·vulnerable:2` | `dmg·lifesteal·selfharm:1` | `dmg·growth·heavy` | `dmg·multi:2` | `dmg·exec·heavy` | `dmg·selfharm:2` |
| **aqua** | *(spare)* | `dmg·lifesteal·mana:1` | `dmg·mana:2` | `dmg·exec·mana:1` | — | — |
| **plant** | `dmg·vital` | `dmg·growth·vital` | `dmg·decay` | `dmg·rerollup` | — | — |
| **bird** | `dmg·pierce` | `dmg·pierce·crit:15` | `dmg·pierce·multi:2` | `dmg·multi:2·crit:25` | — | — |
| **bug** | `dmg·poison:2` | `dmg·poison:3` | `dmg·weaken:2` | *(spare)* | — | — |
| **reptile** | `dmg·heavy` | `dmg·blind:1` | `dmg·lifesteal·heavy` | `dmg·crit:30` | — | — |

Kiểm: 24 bộ, 0 trùng ✓ · ≤3 keyword ✓ · 0 bộ trùng legacy mouth ✓ · Plant không có type `poison` ✓ · Beast/Bird không `shield`/`heal` ✓ · mọi rider hợp lệ trên `dmg` (không `thorns`/`regen`/`undying`) ✓ · `dmg·crit:30` (reptile) **không** đụng `Dual Blade` vì Dual Blade là **horn**, khác slot ✓

##### HORN — 27/27 template, 27 bộ phân biệt ✅

**Legacy horn cấm dùng (`I24`) — 10 bộ**, slot bị ràng buộc nặng nhất: `dmg` (Incisor) · `dmg·pierce` (Cerastes) · `dmg·heavy` (Imp) · `dmg·crit:30` (Dual Blade) · `dmg·pierce·crit:25` (Eggshell) · `dmg·heavy·vital` (Little Branch) · `dmg·heavy·pierce` (Scaly Spear) · `dmg·cleave·exec` (Kestrel) · `dmg·pierce·echo` (Wing Horn) · `dmg·heavy·vital·exec` (Pocky).

> Ba bộ bị cấm — `dmg`, `dmg·pierce`, `dmg·heavy` — chính là ba bộ mà **cả sáu family** đang dùng ở §3.11. Đó là lý do horn thiếu tới 17 bộ: nó không chỉ trùng nhau, nó còn trùng đúng vào ba legacy signature.

| family | A | B | C | D | E |
|---|---|---|---|---|---|
| **beast** *(FERAL)* | `dmg·vulnerable:3` | `dmg·heavy·selfharm:2` | `dmg·pierce·vulnerable:2` | `dmg·cleave·heavy` | `dmg·vital·selfharm:1` |
| **aqua** *(CONDUIT)* | `dmg·mana:1` | `dmg·pierce·mana:1` | `dmg·crit:15` | `dmg·mana:3` | `dmg·heavy·mana:2` |
| **plant** *(BULWARK)* | `dmg·growth` | `dmg·pierce·growth` | `dmg·heavy·growth` | `dmg·cleave·vital` | `dmg·weaken:2` |
| **bird** *(TALON)* | `dmg·pierce·crit:15` | `dmg·pierce·multi:2` | `dmg·crit:40` | `dmg·pierce·cleave` | — |
| **bug** *(VIRULENT)* | `dmg·poison:2` | `dmg·poison:3` | `dmg·blind:1` | `dmg·blind:2·poison:1` | `dmg·weaken:2·poison:1` |
| **reptile** *(SCALES)* | *(spare)* | `dmg·poison:2·heavy` | `dmg·poison:4` | `dmg·heavy·vulnerable:2` | — |

27 bộ · 0 trùng · 0 trùng legacy · ≤3 kw · 0 `thorns`/`regen`/`undying` trên `dmg` ✓

##### BACK — 27/27 template, 27 bộ phân biệt ✅

**Legacy back cấm (5 bộ)**: `shield` (Snail Shell **và** Pumpkin — hai legacy cùng một bộ) · `shield·aoe` (Hermit) · `shield·aoe·thorns:3` (Indian Star) · `shield·aoe·thorns:5` (Tri Spikes) · `shield·aoe·bastion` (Green Thorns).

| family | A | B | C | D | E |
|---|---|---|---|---|---|
| **beast** *(không `shield`/`heal` — `I21`)* | `dmg·vulnerable:2` | `dmg·heavy·growth` | `dmg·lifesteal·vulnerable:1` | `dmg·aoe·selfharm:1` | `dmg·multi:2·vulnerable:1` |
| **aqua** | `shield·mana:2` | `shield·aoe·mana:1` | `shield·regen:2·mana:1` | `shield·undying` | — |
| **plant** *(BULWARK)* | `shield·regen:2` | `shield·aoe·regen:1` | `shield·thorns:2` | `shield·regen:3` | `shield·heavy` |
| **bird** *(không `shield`/`heal`)* | `dmg·pierce·aoe` | `dmg·aoe·crit:15` | `debuff·vulnerable:N` | `dmg·multi:2·pierce` | `dmg·chain:3` |
| **bug** | `shield·growth` | `shield·aoe·thorns:2` | `shield·regen:2·thorns:1` | `shield·heavy·thorns:2` | `shield·vital` |
| **reptile** *(SCALES)* | `shield·thorns:3` | `shield·thorns:2·regen:1` | `shield·aoe·undying` | *(spare)* | — |

27 bộ · 0 trùng · 0 trùng legacy ✓ · **không face `shield`/`heal` nào mang `burn`/`poison`/`weaken`/`vulnerable`/`blind`/`stun`/`freeze`** (§3.7a) ✓ · `undying` chỉ trên `shield` ✓

> **Kéo theo một sửa ở §3.5d-bis**: `Nutdha Statue` (secret) đang được đề xuất đổi sang `shield·thorns:2·regen:1`, nhưng bộ đó giờ thuộc `reptile.back.B`. Đổi `Nutdha Statue` → **`shield · thorns:2 · vital`**.

##### TAIL — 22/22 template, 22 bộ phân biệt ✅

**Legacy tail cấm (11 bộ)** — slot có nhiều legacy nhất: `poison` (Grass Snake) · `dmg·cleave` (Cloud) · `poison·aoe` (Tiny Dino) · `dmg·burn:3` (The Last One) · `dmg·cleave·burn:4` (Swallow) · `poison·aoe·multi:2` (Gila) · `dmg·aoe·pierce` (Post Fight) · `dmg·aoe·burn:5` (Twin Tail) · `poison·aoe·pierce` (Wall Gecko) · `poison·aoe·plague` (Thorny Caterpillar) · `dmg·aoe·cleave·burn:8` (Granma's Fan).

| family | A | B | C | D | E |
|---|---|---|---|---|---|
| **beast** | `dmg·multi:3` | `dmg·cleave·vulnerable:1` | `dmg·chain:3·vulnerable:1` | `dmg·selfharm:1·multi:2` | — |
| **aqua** | `dmg·mana:1` | `dmg·aoe·mana:1` | `dmg·chain:3·mana:1` | `dmg·multi:2·mana:1` | `dmg·mana:2` |
| **plant** *(BULWARK — `shield` ở tail, giữ bản sắc revision 2)* | `shield·regen:3` | `shield·aoe·growth` | `shield·thorns:2·cantrip` | `shield·cantrip·regen:2` | `shield·growth` |
| **bird** | *(spare)* | `dmg·aoe·multi:2` | `dmg·chain:4` | *(spare)* | — |
| **bug** *(VIRULENT)* | `poison·multi:2` | `poison·aoe·growth` | `poison·pierce` | `poison·multi:3` | — |
| **reptile** | *(spare)* | `poison·aoe·heavy` | `poison·pierce·heavy` | *(spare)* | — |

22 bộ · 0 trùng · 0 trùng legacy ✓ · `cantrip` chỉ trên `shield` (E7 ✓) · rider trên `poison` chỉ dùng `aoe`/`multi:N`/`pierce`/`growth`/`heavy` — **không** kwPure nào (§3.7a nhóm 3) ✓ · Plant **không** có type `poison` ✓

##### EYES — 21/21 template, 21 bộ phân biệt ✅

**Legacy eyes cấm (6 bộ)**: `heal` (Blossom) · `heal·aoe` (Cucumber Slice) · `debuff·weaken:3·aoe` (Little Peas) · `debuff·vulnerable:3·freeze` (Scar) · `summon·cantrip` (Mavis, Robin, Neo — ba legacy cùng một bộ) · `heal·aoe·regen:3` (Gecko).

> `Little Peas` = `debuff·weaken:3·aoe` buộc **không family nào** được dùng bộ `debuff·weaken:N·aoe` ở eyes: magnitude `N` do công thức tính, nên nó **sẽ** rơi vào 3 ở một bucket nào đó và va chạm. Đây đúng là loại phụ thuộc-vào-`v` mà `I24` tồn tại để chặn.

| family | A | B | C | D |
|---|---|---|---|---|
| **beast** *(FERAL setup)* | `debuff·vulnerable:N` | `debuff·weaken:N` | `debuff·blind:N` | `debuff·vulnerable:N·blind:1` |
| **aqua** *(CONDUIT)* | `heal·mana:1` | `heal·aoe·mana:1` | `heal·regen:2` | `heal·cantrip` |
| **plant** | *(spare)* | `heal·aoe·growth` | `heal·regen:2·growth` | `heal·cantrip·growth` |
| **bird** *(TALON)* | `debuff·blind:N·vulnerable:1` | `debuff·weaken:N·blind:1` | `debuff·vulnerable:N·aoe` | *(spare)* |
| **bug** *(VIRULENT)* | `debuff·poison:N` | `debuff·weaken:N·poison:1` | `debuff·blind:N·poison:1` | *(spare)* |
| **reptile** *(SCALES)* | `heal·thorns:2` | `heal·regen:3` | `heal·aoe·thorns:1` | `heal·undying` |

21 bộ · 0 trùng · 0 trùng legacy ✓ · `heal` chỉ mang `thorns`/`regen`/`undying`/`cantrip`/`aoe`/`growth`/`mana:N` — 0 kwPure hướng-địch ✓ · `debuff` chỉ mang kwPure hướng-địch ✓ · Beast/Bird không `heal` ✓

**Hai va chạm với signature AUTHORED** (không phải legacy, nên SPREAD xử lý được — ghi ra để generator không báo bất ngờ): `Sleepless` (#59, `heal·cantrip`) đụng `aqua.eyes.D`; `Zeal` (#55, `debuff·vulnerable:3·blind:1`) đụng `beast.eyes.D` khi `N = 3`. Cả hai là Addendum ⇒ SPREAD được phép nhích `v`, tối đa +2.

<!-- GEN:IGNORE END -->

##### Tổng kết R7 — 147/147 ✅

| slot | template | bộ phân biệt trước | sau | đã đóng |
|---|---|---|---|---|
| mouth | 24 | 11 | **24** | 13 |
| horn | 27 | 10 | **27** | 17 |
| back | 27 | 15 | **27** | 12 |
| tail | 22 | 15 | **22** | 7 |
| eyes | 21 | 11 | **21** | 10 |
| ears | 26 | 8 | **26** | 18 |
| **TỔNG** | **147** | **70** | **147** | **77** |

`I5` (R7) giờ thoả **do bảng thiết kế**, không do may. Cộng với R1 (§3.5c), F6 monotone và R8/SPREAD, chuỗi ba nhánh của §3.13c khép kín ⇒ `distinctEngineFaces === 285` ở **cả hai** profile (AC-9c).

⚠️ **Việc bắt buộc của generator**: mọi cột `C/O/P` của §3.11 giờ **vô hiệu cho cả 6 slot**. `gen_faces.mjs` phải re-emit toàn bộ từ `(t, k)` trên đây, rồi chạy REPAIR + SPREAD, rồi commit bảng tham chiếu mới làm mốc AC-7 kế tiếp. **Không hand-fill số.**

##### Sửa một lỗi kwPure trong bảng vá §3.5d-bis

Bản trước đề xuất `Cactus` (#56) → `dmg 6 · pierce · regen:1`. **Sai luật §3.7a**: `regen:N` là kwPure và trên face `dmg` nó đi tới **địch** — tức face đó hồi máu cho đối phương. Sửa: `Cactus` → **`dmg · pierce · growth`** (`growth` nằm ngoài kwPure, và là bản sắc Plant). Đây đúng là loại lỗi mà §3.7a tồn tại để bắt, và nó lọt vào chính bảng sửa của tôi — bằng chứng thêm rằng `I8` phải chạy trên **cả 239 face**, gồm cả face vừa được vá.

#### 3.5d Repair pass — cách R5 được bảo đảm bằng máy, không bằng tay

R1 đúng **do cấu trúc** (§3.5a: `V ≥ maxBucketSize` ⇒ gán đơn ánh được). R5 **không** — signature face được tune theo cùng mốc ngân sách với variant, nên trùng nhau là chuyện thường gặp, không phải hiếm. Kiểm tay 81 signature × 158 variant × 4 bucket là **không đáng tin cậy trong văn bản**. Nên R5 được bảo đảm bằng một pass tất định trong generator:

```
REPAIR(family F):                                  // chạy sau F1–F6, trước khi ghi file
  S = { (t, v, sortedKeys) của mọi signature face trong F }
  for variant in F, theo thứ tự chữ cái A→F:
    for bucket in [C, O, P, X] có mặt trong F:
      tup = tuple(variant, bucket)
      bumps = 0
      while tup ∈ S and bumps < 2:
        v += 1  (hoặc N += 1 nếu face v=0);  bumps++;  tup = tuple(variant, bucket)
      if tup ∈ S:
        HARD FAIL build, in ra: family, variant, bucket, signature đang đụng
        → cần designer đổi thiết kế variant hoặc face Addendum. KHÔNG tự sửa thêm.
      S.add(tup)
      if bumps > 0: log('REPAIR', family, variant, bucket, '+' + bumps)
```

Bốn tính chất bắt buộc của pass này:

1. **Tất định** — thứ tự duyệt cố định (class asc → `SLOT_ORDER` → chữ cái variant → `C,O,P,X`). Chạy lại ra kết quả y hệt. Không random, không phụ thuộc thứ tự khoá object.
2. **Fail loud, không fail silent** — quá 2 bump thì **build đổ**, không âm thầm nhả ra một face trùng hay một face lệch ngân sách 30%. Đây là điều làm R5 trở thành bất biến thật.
3. **Bump ≤ +2 đơn vị** — nới dải kiểm ngân sách của variant từ ±12% lên **±20% CHỈ cho variant đã bị repair**, và generator phải liệt kê chúng ra để AC-7 áp đúng dải cho đúng face.
4. **Chạy SAU F6** — monotone enforcement trước, repair sau; rồi **kiểm lại monotone**, vì bump có thể phá thứ tự C<O<P. Nếu phá, chạy F6 lại rồi repair lại, tối đa 3 vòng, sau đó HARD FAIL.

##### 3.5d-bis. SPREAD pass — R8 ở phạm vi SLOT (mới ở revision 3)

REPAIR ở trên chỉ giải collision **signature ↔ variant trong cùng family**. R8 đòi phạm vi rộng hơn: **toàn slot**, và gồm cả signature ↔ signature. Chạy **sau** REPAIR:

```
SPREAD(slot P):                                    // sau REPAIR, trước emit
  U = {}                                           // tuple (t, v, sortedKeys) đã dùng trong slot P
  # BƯỚC 1 — khoá 50 face legacy trước, chúng bất khả xâm phạm (AC-7c)
  for f in signatures(P) where f.legacy:  U.add(tuple(f))     // xung đột ở đây ⇒ HARD FAIL ngay
  # BƯỚC 2 — variant instance (đã đúng do R1 + R7 + F6), chỉ ghi nhận
  for inst in reachableVariantInstances(P) theo thứ tự (class asc, variant A→F, C,O,P):
      if tuple(inst) ∈ U:  HARD FAIL 'R7-VIOLATION', in class/variant/bucket/đối thủ
      U.add(tuple(inst))
  # BƯỚC 3 — 31 signature AUTHORED (13 Addendum + 18 Secret): được nhích, tối đa 2
  for f in signatures(P) where not f.legacy, theo thứ tự tên:
      bumps = 0
      while tuple(f) ∈ U and bumps < SPREAD_MAX_BUMP (=2):  f.v += 1; bumps++
      if tuple(f) ∈ U:  HARD FAIL 'R8-UNRESOLVED', in tên face + đối thủ
      U.add(tuple(f));  if bumps: log('SPREAD', f.name, '+'+bumps)
  assert |U| === số part của slot P
```

Bốn tính chất, mỗi cái có lý do:

1. **Legacy đi trước và không bao giờ bị nhích.** `AC-7c` (50 số của `FACE_POOL` byte-identical) là BLOCKING và đứng trên R8. Nếu một variant đụng một legacy signature, phải sửa **variant** (đổi keyword-set theo R7, hoặc đổi gán ở §3.12) — sửa legacy là không được phép.
2. **Bước 2 chỉ *kiểm*, không sửa.** Variant instance đã phải đúng do R1+R7+F6. Nếu bước 2 fail thì đó là **lỗi thiết kế §3.11**, không phải thứ generator được quyền vá — vá bằng `v` sẽ tái tạo đúng sự mong manh trước tuning mà R7 tồn tại để diệt.
3. **Chỉ 31 face authored được nhích, tối đa +2.** Sau bump, dải kiểm ngân sách của chúng nới từ ±20% lên **±26%** và generator liệt kê chúng ra để AC-7b áp đúng dải cho đúng face.
4. **`assert |U| === số part của slot`** là đẳng thức đóng vòng: 41 (mouth) + 54 (horn) + 52 (back) + 52 (tail) + 40 (eyes) + 46 (ears) = **285**. Đây chính là AC-9c, và nó được kiểm ở **cấp slot** nên khi đổ, thông báo chỉ đúng vào slot có vấn đề.

**Tám collision đã tìm được bằng tay ở phạm vi R8 — dùng làm seed cho SPREAD pass** (thang tham chiếu; đây là *design input*, không phải kỳ vọng generator):

| slot | Cặp đụng nhau | Tuple | Bên nào phải nhường |
|---|---|---|---|
| mouth | `Cub` (#51 Addendum) ↔ `Zigzag` (#1 legacy) | `dmg 6` | **Cub** — Addendum, sửa được. Đề xuất `dmg 6 · growth`… nhưng đụng `Confident` (#16). Dùng `dmg 5 · vulnerable:2` (Beast setup FERAL, khớp flavour "sói con nhắm con mồi yếu") |
| horn | `Cactus` (#56 Addendum) ↔ `Cerastes` (#9 legacy) | `dmg 7 · pierce` | **Cactus** → `dmg 7 · pierce · growth`? quá đắt ở production. Dùng `dmg 6 · pierce · regen:1` (gai xương rồng + Plant sustain) |
| tail | `Black Gourd` (Secret dusk) ↔ `Tiny Dino` (#14 legacy) | `poison 5 · aoe` | **Black Gourd** → `poison 5 · aoe · weaken:2` |
| tail | `Mainspring` (Secret mech) ↔ `Gila` (#25 legacy) | `poison 6 · aoe · multi:2` | **Mainspring** → `poison 6 · aoe · multi:3` (nguồn 1: đổi magnitude) |
| ears | `Harmonious Silence` (Secret dawn) ↔ `Nyan` (#28 legacy) | `mana 3 · cantrip · rerollup` | **Harmonious Silence** → `mana 3 · cantrip · rerollup · growth` |
| back | `Nutdha Statue` (Secret dawn) ↔ variant `reptile.back.B`@O | `shield 6 · thorns:3` | **Nutdha Statue** → `shield 6 · thorns:2 · regen:1` |
| horn | variant `plant.horn.C`@O ↔ `Imp` (#13 legacy) | `dmg 9 · heavy` | **variant** — R7 sẽ đổi keyword-set của `plant.horn.C` trong pass re-author (nó đang trùng `beast.horn.B` **và** `bird.horn.D` **và** `reptile.horn.D`, cả bốn đều là `dmg · heavy`) |
| back | variant `aqua.back.A`@C ↔ `Snail Shell` (#3 legacy) | `shield 7` | **variant** — `aqua.back.A` nhận rider CONDUIT (`mana:1`) theo nguồn 2 của §3.5c-bis |

Sáu dòng đầu là những **face hand-designed va nhau mà revision 2 không phát hiện** vì nó chỉ kiểm collision *trong family*. Chúng chứng minh vì sao R8 phải là bất biến máy kiểm: sáu face iconic khác nhau, sáu cái tên khác nhau, và engine thấy **ba** face.

**Seed collision đã tìm được bằng tay — ở THANG THAM CHIẾU (`B_REF = 6.0`), không phải thang production.**

Bảng dưới là **design input**: nó ghi lại 6 collision mà designer đã tự giải bằng cách đổi thiết kế (§3.3b) hoặc đổi gán (§3.12), cộng 2 collision mà REPAIR pass phải xử lý. Nó **không** còn là "danh sách kỳ vọng mà generator phải khớp": ở thang production (`B[C] = 2.80`, F1) tập collision **sẽ khác**, vì cả variant lẫn signature đều dịch xuống theo `SIG_IMPORT_SCALE` nhưng **làm tròn độc lập** (§6f). Danh sách collision production do generator sinh và **commit làm snapshot** (AC-4c mới).

Sáu dòng ✅ vẫn là design input có giá trị vĩnh viễn: chúng ghi lý do vì sao §3.12 gán `Serious→C`, `Scaly Spoon→B`, `Snake Jar→C`, `Maggot→C`, `Pangolin Slayer→C` thay vì lựa chọn hiển nhiên hơn — nếu không ghi, một pass sau sẽ "sửa lại cho gọn" và tái tạo collision.

| Family | Variant @ bucket | Tuple | Đụng signature | Xử lý |
|---|---|---|---|---|
| plant·ears | `A` @ C | `mana 2 · cantrip` | `Clover` (#53) | ✅ **Đã sửa tay** — Clover → `mana 2 · rerollup` |
| beast·eyes | `A` @ O | `debuff 0 · vulnerable:4` | `Zeal` (#55) | ✅ **Đã sửa tay** — Zeal → `vulnerable:3 · blind:1` |
| plant·mouth | `A` @ C | `dmg 6` | `Zigzag` (#1, legacy — không sửa được) | ✅ **Đã sửa tay** — đổi gán §3.12: `Serious`→C, `Hazelnut`→A |
| reptile·horn | `A` @ C | `dmg 7` | `Incisor` (#2, legacy) | ✅ **Đã sửa tay** — `Scaly Spoon`→B |
| reptile·tail | `A` @ C | `poison 4` | `Grass Snake` (#6, legacy) | ✅ **Đã sửa tay** — `Snake Jar`→C |
| bug·mouth | `D` @ O | `poison 4` | `Pincer` (#52) | ✅ **Đã sửa tay** — `Maggot`→C |
| beast·back | `B` @ O | `dmg 8 · heavy` | `Ronin` (#54) | ✅ **Đã sửa tay** — `Pangolin Slayer`→C |
| **bug·back** | `A` @ C | `shield 7` | `Snail Shell` (#3, legacy) | ⚠️ **REPAIR pass xử lý** — 5/5 part bucket C dùng hết 5 variant, không còn variant trống. Bump `A`@C 7→8. Ngân sách hàm ý 8×0.86/1.05 = 6.55 vs 6.30 = **+4.0%**, vẫn trong ±12% |
| **beast·horn** | `B` @ O | `dmg 9 · heavy` | `Imp` (#13, legacy) | ⚠️ **REPAIR pass xử lý** — 5/5 part bucket O dùng hết 5 variant. Bump `B`@O 9→10. Ngân sách hàm ý (10−0.4)/1.10 = 8.73 vs 8.36 = **+4.4%**, trong ±12% |

Hai dòng ⚠️ là chỗ repair pass **thực sự cần thiết** — không có variant trống để gán lại, nên phải nhích số. Ở thang tham chiếu, sau bump monotone vẫn giữ (`bug.back.A` = 8/9/12 ✓ tăng dần; `beast.horn.B` = 7/10/11 ✓ tăng dần). **Cột số của §3.11 ghi giá trị TRƯỚC repair, ở thang tham chiếu**; hai ô này là ngoại lệ duy nhất *ở thang đó* (AC-7 kiểm chính xác 2).

> **Ở thang production thì sao?** Không biết trước, và **cố ý không đoán**. Cả hai bên của collision đều nhân ~0.4667 rồi làm tròn độc lập, nên collision có thể mất đi (làm tròn tách chúng ra) hoặc xuất hiện ở chỗ khác. Đây đúng là loại câu hỏi mà một bảng Markdown trả lời sai và một generator trả lời đúng. Nên: `tools/gen_faces.mjs` chạy REPAIR ở **cả hai** profile, in danh sách của từng profile, và AC-4c kiểm **snapshot**, không kiểm con số 2 hardcode. Nếu số collision production nhảy vọt (>8), đó là tín hiệu `B[C]` đã hạ quá sâu và dải `v` bị nén tới mức va vào signature — generator phải **cảnh báo**, không im lặng.

**Xử lý xung đột R1 duy nhất trong catalog hiện tại**: Beast·Mouth có 11 identity, trong đó 7 part non-signature **đều thuộc bucket O** (Cub, Foxy, Platypus, Puff, Puppy, Shishi, Sniffle) — 7 part vào tối đa 6 variant thì chắc chắn vi phạm R1. Giải: **Cub vào Icon List** (§3.3b #51), lý do độc lập và chính đáng (nó là tên starter hero `beast1`). Còn lại 6 part O vào 6 variant, đơn ánh. **Sau xử lý này, toàn bộ 36 family thoả R1 với 0 vi phạm.**

### 3.6 Resolution pipeline — `axieToDie()` v2

Thay nguyên thân hàm `axieToDie()` (`src/engine.js:86-111`). Pipeline **pure, tất định, không random, không I/O**.

```
axieToDie(axieData):
  parts = axieData.parts || []
  die = parts.map(part => resolveFace(part))
  while die.length < 6: die.push(clone(BLANK))
  die = die.slice(0, 6)
  bodyCls = mapAxieClass(axieData.class)            // giữ nguyên hàm hiện có
  hp      = HEROES[bodyCls + '1'].hp || 14          // giữ nguyên
  return { n:'Axie #'+axieData.id, cls:bodyCls, tier:1, hp, art:0,
           die, imported:true, axieId:axieData.id,
           scarcity: scarcityManifest(parts) }      // MỚI — cần cho §3.9

resolveFace(part):
  k    = partKey(part)                              // §3.1
  # --- BƯỚC 1: Signature? ---
  if SIGNATURE_FACE[k]:
      f = clone(SIGNATURE_FACE[k])
      f.name = baseName(part.name)
      f.src  = 'sig'
      if isSpecialGene(part): f.r = min(4, f.r + 1)  # CHỈ rarity, KHÔNG value
      return f
  # --- BƯỚC 2: Family variant ---
  v = PART_VARIANT[k]
  if v == null: return fallbackFace(part)            # §Edge Cases E1
  bucket = SCARCITY_BUCKET[k]                        # C | O | P | X
  tpl    = FAMILY_VARIANT[normClass(part.class)][normSlot(part.type)][v]
  f = { p: normSlot(part.type), t: tpl.t, v: 0, k: tpl.k.slice(),
        r: max(tpl.rFloor, SCARCITY[bucket].rFloor),
        name: baseName(part.name), src: 'var', variant: v, bucket }
  f.v = faceValue(tpl, bucket, part)                 # §Formulas F1-F5
  if isSpecialGene(part): f.r = min(4, f.r + 1)
  return f
```

**Ba tính chất phải giữ, mỗi tính chất có một test tương ứng**:

1. **Pure** — không đọc `Date`, `Math.random`, `RNG`, `localStorage`. Cùng `axieData` → cùng die, byte-identical, mọi lúc. (AC-1)
2. **Deep-clone** — mọi face phải `clone()` từ template. Hai Axie import khác nhau **không được share reference** (bug này đã được comment cảnh báo ở `src/engine.js:62`; `buildUnit()` mutate `u.die` qua mutation/rune/oc nên share reference sẽ làm một Axie sửa die của Axie khác). (AC-2)
3. **Total** — mọi input, kể cả rác, trả về die 6 mặt hợp lệ, không throw. (AC-8)

### 3.7 Keyword audit — cái gì THỰC SỰ được engine tiêu thụ

Toàn bộ keyword doc này dùng đều đã đối chiếu **code resolution**, không phải `KWT` (`src/engine.js:767`) — `KWT` chỉ là bảng tên hiển thị và **không phải bằng chứng implement**.

**ĐÃ IMPLEMENT — an toàn dùng ngay** (dòng code là nơi keyword thực sự có hiệu lực):

**Cột "vị trí" đã được re-verify từng dòng ở commit `438e944`** (revision 1 pin ở `60c05ee` và lệch 20–50 dòng ở *mọi* dòng của bảng này). Symbol là nguồn sự thật; số dòng để tra nhanh và được `--check-citations` giữ đúng (AC-33).

| keyword | vị trí (symbol · dòng@`438e944`) | Hiệu lực thực tế | Type dùng được |
|---|---|---|---|
| `cleave` | `doFace` :506 | neighbour nhận `ceil(v×0.5)` | dmg |
| `pierce` | `doFace` :491 · `doFace`(poison) :514 · `dealDamage` :318 | bỏ shield; bird +3; trên poison thì gây thêm dmg thật | dmg, poison |
| `aoe` | `doFace` :498, :512, :516, :521, :524, :527, :532 | mọi type | tất cả |
| `cantrip` | `resolveCantrips` :279 | exec rồi roll lại, tối đa 6 vòng | tất cả (xem E7) |
| `heavy` | `rollUnit` :251 · `anyRerollable` :285 · :295 | chặn reroll unit đó (là **drawback**) | tất cả |
| `growth` | `doFace` :539 | `u.growth[fi] += 1`, cộng vĩnh viễn trong trận | tất cả |
| `decay` | `doFace` :540 | `u.growth[fi] -= 1` (drawback) | tất cả |
| `vital` | `faceValue` :406 | `v ×= 2` khi HP đầy | tất cả |
| `lifesteal` | `doFace` :493 | heal = damage thật gây ra | dmg |
| `exec` | `doFace` :492 · `dealDamage` | `×1.6` vào target < 50% HP | dmg |
| `multi:N` | `doFace` :504-505 (dmg) · :511 (poison) | dmg: N đòn cùng target · poison: N stack | dmg, poison |
| `chain:N` | `doFace` :501 | N đòn vào target **ngẫu nhiên** | dmg |
| `selfharm:N` | `doFace` :536 | tự nhận N dmg pierce | tất cả |
| `mana:N` | `doFace` :537 | `s.mana += N`. **CẢNH BÁO**: nằm TRONG kwPure (§3.7a) — an toàn chỉ vì `addStatus` không có nhánh `mana` | tất cả |
| `rerollup` | `doFace` :538 | `s.rerolls += 1` | tất cả |
| `crit:N` | `critChance` :247 · `rollUnit` :253-254 · `dealDamage` :321 | N% crit, quyết định **lúc roll** | dmg |
| `burn:N` | `tickStatus` :651-658 | tick `st.burn`, rồi **halve** (`floor(x/2)`, :658) | via kwPure |
| `poison:N` | `addStatus` :385-393 (bug +2 ở :386) · tick `tickStatus` :645-650 | `st.poison += N`; bug +2 nếu đã có poison | via kwPure |
| `weaken:N` | `addStatus` :394 · `faceValue` :409 · decay :661 | dmg face của target `−N`; giảm 1/lượt | via kwPure |
| `vulnerable:N` | `addStatus` :394 · `dealDamage` :324 · decay :661 | target nhận `×1.5` dmg; giảm 1/lượt | via kwPure |
| `blind:N` | `addStatus` :394 · `faceValue` :408 · decay :661 | dmg face của target = **0**; giảm 1/lượt | via kwPure |
| `thorns:N` | `addStatus` :394 · `dealDamage` :337-345 · nền reptile :232 · plant auto :379 | phản đòn N; **KHÔNG bao giờ giảm** (E10 — `tickStatus` :640-662 không có `thorns`) | via kwPure |
| `regen:N` | `addStatus` :394 · `tickStatus` :660 | heal N/lượt, giảm 1/lượt | via kwPure |
| `stun` | `addStatus` :396 · tiêu thụ :625 | địch mất đúng 1 lượt | via kwPure |
| `freeze` | `addStatus` :397 | player → `frozenNext` · enemy → stun | via kwPure |
| `undying` | `addStatus` :399 · `dealDamage` :330, :345 | sống sót ở 1 HP một lần | via kwPure |
| `enrage` | `addStatus` :398 | dmg face của target `×1.25` | via kwPure |
| `echo` | `execFace` :467 | `doFace` chạy 2 lần | tất cả — **Mythic only** |
| `plague` | `tickStatus` :648 | poison không giảm stack | poison — **Mythic only** |
| `bastion` | `doFace` :520 | shield cũng gây dmg = giá trị shield | shield — **Mythic only** |
| `overflow` | `endTurn` :617-618 | mana dư cuối lượt → dmg AoE | mana — **Mythic only** |
| `selfkill` | `doFace` :509 | `u.hp = 0` | dmg |

**CHƯA IMPLEMENT — KHÔNG được dùng**:

| keyword | Bằng chứng | Doc cũ dùng nó ở đâu |
|---|---|---|
| `shieldself:N` | Xuất hiện đúng **1 lần** trong toàn `src/` — ở comment `src/data.js:6`. `KWT` cũng **không** có nó. Không có nhánh xử lý nào trong `addStatus()` hay `doFace()`. | `part-tier-system.md` §2c dùng nó ở **6 ô** (plant·back, plant·tail, aqua·back, reptile·back, bug·back) và §8 gán **~14 part** vào nó. **Toàn bộ những ô đó là no-op nếu implement nguyên văn.** |

→ Doc này **không dùng** `shieldself` ở bất kỳ face nào. Spec để implement nó nằm ở §NEW ENGINE WORK (optional).

#### 3.7a **kwPure DIRECTION LAW** — luật quan trọng nhất của doc này

`doFace()` (`src/engine.js:487-489`) lọc ra `kwPure` — các keyword *không* nằm trong danh sách loại trừ — rồi **áp chúng như status lên target của face đó**:

```
dmg / debuff            →  addStatus(kwPure)  lên  ĐỊCH          (:494, :516-517)
shield / heal / buff     →  addStatus(kwPure)  lên  ĐỒNG MINH     (:519, :524-525, :527-528)
mana / summon / poison   →  KHÔNG BAO GIỜ nhận kwPure  →  VÔ HIỆU  (:511-513, :529-533)
```

> **`poison` nằm ở nhóm thứ BA, không phải nhóm thứ nhất — sửa lỗi revision 1 (defect 10 của review).**
>
> Revision 1 xếp `poison` cùng `dmg`/`debuff`. Đã verify tại `src/engine.js:510-514`: nhánh `f.t === 'poison'` **tự dựng mảng riêng** và **không bao giờ** truyền `kwPure`:
> ```js
> } else if(f.t==='poison'){
>   const p=[]; for(let i=0;i<(kwVal(f,'multi')||1);i++) p.push('poison:'+v);
>   if(hasKw(f,'aoe')) foes.slice().forEach(t=>addStatus(s,t,p,u));      // ← p, KHÔNG phải kwPure
>   else { …; addStatus(s,tgt,p,u); }                                     // ← p
>   if(hasKw(f,'pierce')) …dealDamage(…)
> ```
> Nghĩa là face `poison` xử sự **giống `mana`/`summon`**: mọi keyword kwPure tiêm vào nó đều **trơ**, không phải hướng-địch.
>
> **Không face nào đang thiết kế bị sai** — cả 13 face `poison` trong doc này chỉ mang `aoe`/`multi`/`pierce`/`plague`, và cả bốn đều nằm **ngoài** kwPure (`:487-489`), nên chúng đi qua đường riêng và hoạt động đúng. Nhưng đó chính là lý do lỗi này nguy hiểm: nó **không biểu hiện** hôm nay. Một face `poison 4 · vulnerable:3` thêm vào Phase 2 sẽ **pass AC-5 như revision 1 viết** rồi âm thầm không làm gì — đúng loại thất bại mà §3.7a tồn tại để chặn. AC-5 khoản 3 đổi thành `t ∈ {mana, summon, poison}`.

**Sửa thứ hai — `mana:N` THỰC SỰ nằm TRONG kwPure.** Revision 1 xếp `mana:N` vào nhóm "rider ngoài kwPure". Sai: danh sách loại trừ ở `:487-489` là `['aoe','cantrip','heavy','echo','selfkill','plague','bastion','overflow']` cộng prefix `multi`/`chain`/`selfharm`/`crit` cộng `cleave`/`pierce`/`lifesteal`/`growth`/`decay`/`vital`/`rerollup`/`exec` — **`mana` không có trong đó**. Nên `'mana:2'` **được** truyền vào `addStatus()`. Nó vô hại chỉ vì `addStatus` (`:382-401`) không có nhánh `mana` nào nên rơi qua hết mọi `if` và không làm gì; việc cộng mana thật xảy ra riêng ở `:537` trong khối `if(!isEcho)`. **Kết luận thực tế không đổi** (`mana:N` an toàn trên mọi type), nhưng **lý do** đổi, và lý do mới quan trọng: nếu ai thêm nhánh `mana` vào `addStatus` thì mọi face `dmg · mana:2` sẽ bắt đầu **cấp mana cho địch**. Ghi vào §6a như một cảnh báo hợp đồng.

Suy ra ba luật cứng. **Vi phạm không gây crash — nó gây ra một face buff quân địch, âm thầm, và không test nào hiện có bắt được.**

| Face type | kwPure ĐƯỢC dùng | kwPure **CẤM** | Nếu vi phạm |
|---|---|---|---|
| `dmg`, `debuff` | `burn:N` `poison:N` `weaken:N` `vulnerable:N` `blind:N` `stun` `freeze` `enrage`¹ | `thorns:N` `regen:N` `undying` | **Bạn buff địch.** `dmg + thorns:3` = mỗi lần bạn đánh, bạn tự ăn 3 dmg |
| `shield`, `heal`, `buff` | `thorns:N` `regen:N` `undying` | `burn:N` `poison:N` `weaken:N` `vulnerable:N` `blind:N` `stun` `freeze` | **Bạn debuff đồng minh.** `heal + weaken:3` = chữa xong thì ally mất 3 dmg |
| `mana`, `summon`, **`poison`** | rider **ngoài** kwPure: `aoe` `cantrip` `heavy` `multi:N` `chain:N` `selfharm:N` `crit:N` `cleave` `pierce` `lifesteal` `growth` `decay` `vital` `rerollup` `exec` · **CỘNG `mana:N` — xem ngoại lệ dưới** | mọi keyword kwPure **trừ `mana:N`**: `burn:N` `poison:N` `weaken:N` `vulnerable:N` `blind:N` `stun` `freeze` `thorns:N` `regen:N` `undying` `enrage` | **Vô hiệu âm thầm.** Face trông mạnh trên tooltip, thực tế không làm gì. `poison` vào nhóm này vì `:511` tự dựng mảng riêng (xem ghi chú trên) |

> **NGOẠI LỆ `mana:N` — sửa mâu thuẫn nội bộ giữa §3.7 và §3.7a (generator phát hiện).**
>
> Luật nhóm 3 viết "**mọi** kwPure đều trơ" là **quá rộng**, và nó mâu thuẫn với bảng §3.7 (ghi `mana:N` dùng được trên **tất cả** type) *và* với chính đoạn "Sửa thứ hai" ở ngay dưới §3.7a. Cả ba không thể cùng đúng.
>
> Sự thật đã verify: `mana:N` **nằm trong** kwPure (nó không có trong danh sách loại trừ của `doFace`), nên nó *được* truyền vào `addStatus` — và ở đó nó trơ vì `addStatus` không có nhánh `mana`. **Nhưng việc cộng mana thật xảy ra ở một đường hoàn toàn khác**: `doFace` cộng thẳng `s.mana += kwVal(f,'mana')` trong khối `if(!isEcho)` (`src/engine.js:537`), **ngoài** `addStatus`. Nên `mana:N` **có hiệu lực thật trên mọi type**, kể cả `mana`/`summon`/`poison`.
>
> ⇒ `aqua.ears.C` = `mana · cantrip · mana:1` là **hợp lệ**, không phải keyword chết. Nó cấp `v + 1` mana. Tương tự mọi rider `mana:N` trên face `poison`/`summon`.
>
> ⚠️ **Cảnh báo hợp đồng không đổi** (§6a): sự an toàn này phụ thuộc vào việc `addStatus` **không** có nhánh `mana`. Thêm một nhánh `mana` vào `addStatus` sẽ khiến mọi face `dmg · mana:2` **cấp mana cho địch**. `mana:N` là keyword duy nhất trong kwPure sống nhờ một đường vòng; đừng coi đó là tiền lệ cho keyword khác.

¹ `enrage` áp lên địch làm dmg face của địch `×1.25` — đó là buff địch. **Cũng cấm** trên face hướng-địch. `enrage` chỉ hợp lệ trên `buff`/`shield`/`heal` (buff ally). Doc này không dùng `enrage` ở đâu cả.

> **Bug đã phát hiện trong thiết kế bị supersede**: `part-tier-system.md` §2c đặt Beast·Back = `thorns:N / vulnerable:N` và Beast·Eyes = `regen:N / vulnerable:N`, trong khi §2a khai báo Beast·Back và Beast·Eyes đều là type **`dmg`**. Theo luật trên, `dmg + thorns:N` **cho địch thorns** và `dmg + regen:N` **hồi máu cho địch**. Tương tự Aqua·Tail = `chain + weaken` (ổn) nhưng Plant·Tail = `shieldself + regen` (shieldself no-op, regen ổn), và Bug·Back = `poison:N + shieldself` trên face **`shield`** → `poison` lên **đồng minh mình**. Đó là 4+ ô sai hướng trong 36. Doc này sửa bằng cách biến hướng thành **luật cấu trúc kiểm được bằng test** (AC-5), không phải bằng sự cẩn thận của designer.

### 3.8 `FACE_POOL` realignment — hợp nhất vốn từ

**Nguyên tắc chỉ đạo: không đổi một con số nào của 50 face đang có.** `FACE_POOL` đang chạy live, feed drop reward qua `facePool()`/`mkReward()` (`src/engine.js:649, 699-704`), và đã được tune. Đổi số = rủi ro balance không cần thiết, và sẽ buộc bump `ENGINE_VERSION` (làm mọi replay leaderboard cũ bị từ chối — `api/submit-run.js:88`). Realignment ở đây là **additive**.

Ba thay đổi, đúng ba:

**(1) Thêm 13 entry Addendum** (§3.3b) → `FACE_POOL` từ **55 lên 68 entry**, trong đó **63 là entry có tên** (`FACE_NAMES`) và **5 là Battle Pass**.

> **Sửa lỗi revision 1 (defect 9 của review) — "50 → 63" là sai sự thật.** `FACE_POOL` được khai báo với 50 entry ở `src/data.js:203-234`, **rồi `src/data.js:596` push thêm 5 face Battle Pass vào chính mảng đó** lúc load module:
> ```js
> Object.values(BP_FACES).forEach(b=>FACE_POOL.push(b.face));   // data.js:596
> ```
> Đo lúc runtime: **`FACE_POOL.length === 55`**, còn `FACE_NAMES.length === 50` (`FACE_NAMES` không có entry cho 5 face BP — `:253` gán tên theo index nên 5 face cuối chỉ đơn giản không được đặt tên).
>
> Hệ quả: `AC-16` của revision 1 (`FACE_POOL.length === 63`) **không bao giờ đúng được**, kể cả khi implement hoàn hảo — nó sẽ là 68. AC-16 được viết lại thành hai assert tách bạch (§8).
>
> **5 face BP là thành viên hợp lệ của pool, không phải rác cần lọc**: `facePool()` (`:678-682`) lọc chúng theo `!f.bp || bp.includes(f.bp)`, tức chúng chỉ rơi cho người chơi đã mở đúng mốc Battle Pass. Doc này **không** đụng tới chúng, và **không** đưa chúng vào Icon List (chúng không phải tên part Axie thật).

Phân bố rarity trước → sau. Skew về r0/r1 là *có chủ ý*: drop band đầu run là `[0,1]` (`src/engine.js:691`), và pool r0 chỉ có 8 entry nghĩa là người chơi thấy lặp rất sớm.

| r | trước | thêm | sau |
|---|---|---|---|
| 0 COMMON | 8 | 3 (Cub, Pincer, Clover) | **11** |
| 1 RARE | 12 | 7 (Ronin, Zeal, Cactus, Hot Butt, Anemone, Sleepless, Parasite) | **19** |
| 2 EPIC | 12 | 3 (Little Owl, Balloon, Risky Bird) | **15** |
| 3 LEGENDARY | 10 | 0 | **10** |
| 4 MYTHIC | 8 | 0 | **8** |
| **entry có tên** | 50 | 13 | **63** |
| *(+ BP, không tên)* | *5* | *0* | *5* |
| **`FACE_POOL.length`** | **55** | 13 | **68** |

Không thêm r3/r4: hai band đó đã đủ dày cho `band=[2,4]`, và mỗi Mythic mới là một rule-break cần sim riêng — không đưa vào cùng lúc với thay đổi structural này.

**(2) Thêm field `cls` cho cả 63 entry** — metadata, không đổi gameplay math.

```js
// dạng mới: FR(r, cls, p, t, v, ...k)  — thêm 1 tham số cls ở vị trí 2
FR(1,'beast','back','dmg',8,'heavy')   // Ronin
```

Vì sao cần: đây là thứ *thực sự* hợp nhất hai vốn từ. Có `cls`, hàm `mkReward` type `'face'` có thể ưu tiên face khớp class của Axie nhận nó, nên "Ronin" không còn rơi vào một con Plant. Đề xuất tối thiểu, không đổi số:

```
mkReward(t='face'): sau khi pick target e = pick(s.roster),
  ưu tiên p2 = p.filter(f => !f.cls || f.cls === HEROES[e.key].cls)
  dùng p2 nếu p2.length >= 3, ngược lại dùng p (tránh làm rỗng pool)
```

Ngưỡng `>= 3` để pool không bao giờ co lại quá nhỏ. Đây là **thay đổi hành vi drop** → cần bump `ENGINE_VERSION`; nếu producer muốn tách rủi ro thì gắn nó sau một flag và ship riêng khỏi phần import.

**(3) Ghi nhận 13 face grandfathered ngoài dải ngân sách.**

50 face gốc được hand-tune, **không** sinh từ công thức §Formulas, nên nhiều face nằm ngoài dải ±12%. Ví dụ `Pocky` (r4, `dmg 26 heavy vital exec`) không quy về ngân sách nào có nghĩa. **Đó là đúng và giữ nguyên**: 158 variant face là nơi bảo đảm ngang giá cấu trúc; 63 signature face là nơi cho phép ngoại lệ có chủ đích. AC-7 chỉ áp dải ngân sách lên variant, và **miễn trừ tường minh** cho signature — nếu không, CI sẽ fail vào chính những face iconic mà ta muốn giữ.

**Hệ quả cho `MYTHIC_KW` và `RUNES`**: `MYTHIC_KW` (`src/data.js:254`) không đổi. `RUNES` (`src/data.js:255`) không đổi — nhưng lưu ý một rủi ro đã tồn tại: `mkReward` type `'rune'` gắn keyword **ngẫu nhiên** từ `RUNES` vào một face bất kỳ, và `RUNES` chứa `'vital'`, `'lifesteal'`, `'exec'`, `'growth'` — nếu rune rơi vào một face `mana` thì vô hiệu (§3.7a), và không có keyword hướng-sai nào trong `RUNES` (tất cả 10 đều nằm ngoài kwPure hoặc là debuff-safe), nên **`RUNES` hiện an toàn với luật §3.7a**. Đừng thêm `thorns`/`regen` vào `RUNES` sau này.

### 3.9 LỘ TRÌNH MỞ RANKED CHO VAULT AXIE (R4) — provenance, không phải cân bằng hoá

> **Viết lại hoàn toàn ở revision 3, hai lần, vì hai lý do khác nhau:**
> 1. **R4** — product owner: *"trong tương lai tôi sẽ mở cho cả vault Axie, chẳng qua là bản hiện tại tôi đang tiến hành test beta nên hạn chế nhất, tuy nhiên bạn cũng chuẩn bị hướng đi/giải pháp cho việc mở ranked cho cả vault Axie đi."* ⇒ việc loại tuyệt đối Axie import hôm nay là **biện pháp beta**, không phải thiết kế vĩnh viễn. Mục này giờ là **lộ trình 5 giai đoạn có cổng đo được**, không phải một board song song.
> 2. **Quyết định pay-to-win (2026-09-03, F1b-α)** ⇒ **toàn bộ bộ máy cân bằng hoá bị bỏ**. Handicap `H`, hệ số đàn hồi `k`, và `SBC_CAP = 14` tồn tại để *triệt tiêu* lợi thế của người sở hữu NFT hiếm. Product owner vừa nói lợi thế đó **được chấp nhận**. Một cơ chế trung hoà một lợi thế đã được chấp nhận là công sức thuần tuý bỏ đi.
>
> ⇒ **Câu hỏi cổng của mọi giai đoạn đổi từ *"đo và huỷ được lợi thế của nó chưa?"* thành *"chứng minh được die này là thật chưa?"*.** Đó là một bài toán dễ hơn nhiều và có kết thúc rõ ràng hơn nhiều.

Game có leaderboard xếp hạng đang chạy thật (`api/submit-run.js`, `api/leaderboard.js`), nên mọi thay đổi ở đây chạm vào hạ tầng đang live.

#### 3.9a Trạng thái đã verify hôm nay

**Guardrail đã tồn tại và đã chặt.** Không phải giả thuyết:

- **Client** — `src/ui.js:1151-1156`: `const hasVault = teamPick.some(k => k.startsWith('vault_')); if (hasVault) pickRanked = false;` và nút RANKED RUN bị disable với tooltip *"Remove your Vault (Import Axie) picks to enable Ranked Run."*
- **Server** — `api/submit-run.js:63-65`: `teamKeys` phải là **đúng 5 key** khớp `VALID_HERO_KEY`, thông báo lỗi ghi thẳng *"Vault/Import Axie picks are not eligible for Ranked Run"*.
- **Kiến trúc** — server replay bằng `G.newGame(seed, teamKeys, …)` (`:96`). `teamKeys` chỉ là **tên hero**; die của một Axie import **không tồn tại trên server** (nó nằm trong `localStorage` của client — `META.vault`, `src/ui.js:324`). Nên cả khi bypass validation, replay cũng sẽ diverge và bị từ chối. **Segregation là hệ quả của kiến trúc, không chỉ của một dòng if.**

Kết luận: **thiết kế này không mở ra một lỗ hổng ranked mới.** Việc loại trừ hôm nay có **hai** nguyên nhân độc lập, và chỉ một trong hai còn hiệu lực:

| Nguyên nhân của L1 | Còn hiệu lực sau quyết định pay-to-win? |
|---|---|
| **(a) Công bằng** — Axie hiếm mạnh hơn nên không nên xếp chung bảng | ❌ **Không.** Product owner chấp nhận lợi thế này |
| **(b) Chống gian lận** — die của Axie import **không tồn tại trên server**; nó nằm trong `localStorage` của client, nên server không replay được và không có gì để đối chiếu | ✅ **Có, và đây giờ là lý do DUY NHẤT.** Không liên quan gì tới chi tiền |

**Đây là điểm mấu chốt của cả §3.9**: lộ trình mở Ranked không còn là bài toán *cân bằng*, nó là bài toán *provenance* — làm sao server biết die này (i) đến từ một con Axie mà người chơi **thật sự sở hữu**, và (ii) được suy ra **đúng theo `axieToDie()`**, không phải do client bịa.

#### 3.9-R4. Lộ trình 5 giai đoạn

Mỗi giai đoạn ghi đủ 5 cột theo yêu cầu R4. **Cổng** là điều kiện đo được phải pass trước khi sang giai đoạn sau.

| Stage | Mở cái gì | Phải xây trước | Cơ chế công bằng | **Cổng đo được** | Số phận entry đã có |
|---|---|---|---|---|---|
| **S0 — hôm nay (beta)** | Không gì. Axie import bị loại tuyệt đối khỏi Skill board | *(đã ship)* | L1: `teamKeys.every(VALID_HERO_KEY)` server-side | — | — |
| **S1 — Exhibition** | Board `lbc:{mode}:{asc}` **không xếp hạng, không thưởng, không mùa giải**, nhãn `EXHIBITION — unverified ownership` | Vault schema 3 (`N16`) lưu `parts` manifest · endpoint nhận manifest · `axieToDie()` v2 pure (`N1`) | Không có. Board này **không** là thi đấu, nó là bảng trưng bày | `AC-1` pass: 1995 lần gọi `axieToDie` cho die byte-identical, 0 lần chạm `Math.random`/`Date`. **Không có mục này thì mọi stage sau vô nghĩa** | Skill board không đổi một entry nào |
| **S2 — Verified Exhibition** | Vẫn không xếp hạng, nhưng bỏ nhãn `unverified`; hiện tên chủ sở hữu | `walletSig` verify (`N8`) + **on-chain ownership read** (`N9`) | Không có | 1000 submission liên tiếp: **0** trường hợp `walletAddr` không sở hữu `axieId` lọt qua; và **0** false-reject trên ví hợp lệ | S1 entry giữ nguyên, gắn cờ `unverified:true` để phân biệt |
| **S3 — Ranked Vault, board riêng** | `lbc:*` **có xếp hạng, có mùa giải, có thưởng** — nhưng vẫn tách khỏi `lb:*` | Server-side manifest re-verify (`N10`) + server-side `axieToDie()` rebuild + replay (`N11`) | Không handicap. Board tách ra **chỉ vì** thang power khác, không vì công bằng | Replay parity: 500 run nộp thật, server-rebuilt die **khớp byte-identical** với die client dùng, ≥99.9%; mọi lệch phải quy được về `ENGINE_VERSION` mismatch chứ không phải nondeterminism | Toàn bộ entry S1/S2 bị **xoá** khi mùa 1 mở (chúng chưa qua replay). Nêu rõ trong patch note trước ≥14 ngày |
| **S4 — Hợp nhất vào Ranked** | Axie import nộp thẳng vào `lb:{mode}:{asc}`, cùng bảng với đội toàn hero. L1 được gỡ | `VALID_HERO_KEY` nới sang `axie:<id>` · `newGame()` nhận roster hỗn hợp trên server | Không có. Đội hero và đội Axie xếp chung; người chơi giàu **được phép** xếp cao hơn | **(a)** S3 chạy trọn một mùa (≥30 ngày) với **0** sự cố provenance; **(b)** phân bố score của nhóm Vault và nhóm hero chồng lấn ≥60% (nếu tách hẳn thì hợp nhất chỉ tạo một bảng hai tầng vô nghĩa — quay lại S3) | `lb:*` **giữ nguyên**, entry Vault cộng thêm. `lbc:*` đóng băng read-only làm lưu trữ mùa cũ |

**Ba điều lộ trình này cố ý KHÔNG làm:**
1. **Không handicap ở bất kỳ stage nào.** Đã bỏ cùng `H`/`k` (§3.9d).
2. **Không trần scarcity.** `SBC_CAP` đã bỏ (§3.9c).
3. **Không nới chống gian lận để đi nhanh hơn.** S3 **không được** bỏ qua bước replay; S4 **không được** bỏ qua S3. Cổng của S1 (`AC-1`) là BLOCKING vì mọi stage sau đứng trên nó.

**Hạ tầng nào còn cần, sau khi bỏ bộ máy chống-whale** — đây là câu hỏi trực tiếp của coordinator:

| Hạ tầng | Trước đây biện minh bằng | Còn cần không? |
|---|---|---|
| **On-chain ownership read** (`N9`) | Chặn khai Axie của người khác để lách `SBC_CAP` | ✅ **CÒN, và vẫn là gate.** Lý do đổi: không có nó, bất kỳ ai cũng khai `axieId` của một con Axie Prime nổi tiếng và nộp điểm với die mạnh mà họ không sở hữu. Đó là **gian lận**, không phải chi tiền |
| **Server-side manifest re-verify qua `api/axie.js`** (`N10`) | Chặn khai part mạnh hơn part thật để lách trần scarcity | ✅ **CÒN.** Cùng lý do: client tự khai `parts` thì client tự chọn sức mạnh. Vấn đề rate-limit **vẫn nguyên**: ~20 call/submission so với `RATE_LIMIT_MAX = 20`/phút/IP (`api/axie.js`) ⇒ **bắt buộc** cache theo `axieId` hoặc đường nội bộ bỏ qua rate limit. Giảm nhẹ mới: vì không còn `SBC_CAP` để tính, có thể verify **bất đồng bộ sau khi nhận** và thu hồi entry nếu lệch, thay vì chặn đồng bộ lúc nộp — hạ áp lực rate-limit rất nhiều |
| **Server-side `axieToDie()` rebuild** (`N11`) | Dựng die để tính handicap và để replay | ✅ **CÒN, cho replay.** Handicap biến mất nhưng replay thì không: không dựng lại được die thì không replay được, không replay được thì điểm nào cũng nhận |
| **`walletSig`** (`N8`) | Chống dùng ID Axie của người khác | ✅ **CÒN** — nó là bước rẻ nhất và là điều kiện tiên quyết của ownership read |
| ~~`SBC_CAP` check~~ | Trần scarcity đội hình | ❌ **BỎ** (§3.9c) |
| ~~Handicap `H'` + hiệu chuẩn `k`~~ | Trung hoà lợi thế NFT | ❌ **BỎ** (§3.9d). Kéo theo bỏ `AC-11` và `AC-13` |

**Ròng**: bỏ được 2/6 hạng mục và **nới được ràng buộc thời điểm** của hạng mục đắt nhất (`N10` chuyển từ đồng bộ sang bất đồng bộ). Bốn hạng mục còn lại đều thuộc chống gian lận và **không** hạng mục nào trong số đó bị quyết định pay-to-win làm yếu đi.

#### ~~3.9b / 3.9c / 3.9c-bis / 3.9d~~ — **ĐÃ BỎ HẲN (2026-09-03)**

> **Thân bốn mục này đã bị xoá, không chỉ đánh dấu superseded.** Chúng đặc tả cỗ máy cân bằng hoá:
> guardrail 3 lớp, `SBC_CAP = 14` và cách suy ra nó, hằng số đàn hồi `k`, và handicap divisor `H`.
> Toàn bộ tồn tại để **triệt tiêu** lợi thế của người sở hữu NFT hiếm.
>
> Product owner đã **chấp nhận pay-to-win** (2026-09-03, xem `F1b-α`): *"tôi chấp nhận việc pay to win —
> chúng ta không cần chống lại những người chi tiền mạnh"*. Một cơ chế trung hoà một lợi thế đã được
> chấp nhận là công sức thuần tuý bỏ đi.
>
> **Vì sao xoá thân chứ không chỉ gạch tiêu đề**: lập trình viên implement theo **thân mục**. Một cơ chế
> đã khai tử nhưng vẫn còn công thức đầy đủ là một *lệnh ngầm* bảo họ xây nó. Đây chính là lỗi mà
> `part-tier-system.md` đã mắc và làm cả một pipeline (`gen_parts.py`) sinh ra dữ liệu chết.
>
> Thay thế: **§3.9-R4** (lộ trình 5 giai đoạn, provenance thay vì cân bằng hoá) ở ngay trên.
> Cổng của mỗi giai đoạn giờ là *"die này có thật và có đúng chủ không"*, không phải *"lợi thế này lớn bao nhiêu"*.
>
> **KHÔNG khôi phục các mục này.** Nếu tương lai cần giới hạn scarcity trở lại thì đó là một quyết định
> sản phẩm mới, phải viết lại từ đầu với lý do mới — không phải "sửa một regression".

#### 3.9e Điều kiện tiên quyết — provenance (không được bỏ qua)

L2 và L3 tính trên một **manifest do client gửi**. Server **không thể chứng minh sở hữu NFT** từ manifest.

```
Collector submission body (mở rộng từ submit-run.js hiện tại):
{ seed, mode, ascension, actions, engineVersion, displayName,
  teamKeys:  [5 phần tử, mỗi phần tử là hero key HOẶC 'axie:<axieId>'],
  axieManifest: { "<axieId>": { class, parts:[{name, class, type, specialGenes}] } },
  walletAddr, walletSig }
```

Server **bắt buộc** làm đủ 4 bước, theo đúng thứ tự:

1. **Verify signature** — `walletSig` là chữ ký của `walletAddr` trên chuỗi `seed + '|' + sortedAxieIds.join(',')`. Chống việc dùng ID Axie của người khác.
2. **Verify ownership** — đọc chain (hoặc Sky Mavis API) xác nhận `walletAddr` sở hữu **mọi** `axieId` trong manifest **tại thời điểm nộp**. Không có bước này thì bất cứ ai cũng khai một con Axie Prime bất kỳ.
3. **Verify manifest** — fetch lại từng `axieId` qua đúng đường `api/axie.js` và so khớp `parts` với manifest client gửi. Lệch → reject. Chống việc khai part mạnh hơn part thật.
4. **Rebuild server-side** — server **tự** gọi `axieToDie()` từ manifest **đã verify** để dựng die (không tin die client gửi), rồi replay. Vì `axieToDie()` là pure (§3.6), server và client ra cùng die.

> **GATE: cho tới khi bước 2 (on-chain ownership) hoạt động, Collector board phải được đánh nhãn `EXHIBITION — unverified ownership` trên UI, KHÔNG có reward, KHÔNG có mùa giải, và KHÔNG được đặt cạnh Skill board như thể ngang hàng.** Đây là điều kiện chặn, không phải khuyến nghị. Một board "ranked" mà ai cũng khai được Axie của người khác thì tệ hơn là không có board.

#### 3.9f Ba bề mặt scarcity còn lại (không được quên)

| Bề mặt | Scarcity có ảnh hưởng? | Xử lý |
|---|---|---|
| PvE campaign / Ascension 0-10 | **Có, và đó là mục đích** | Không guardrail. Đây là nơi chase value được phép sống trọn vẹn |
| Gauntlet (`economy-progression.md` §12.2) | Có | Nếu Gauntlet có bảng xếp hạng/phần thưởng cạnh tranh → áp đúng L2+L3. Nếu chỉ là PvE có ticket → không cần |
| `nftHpBonusPct()` (`src/engine.js:37`) — HP bonus theo `ownedCount` | Có, **cộng dồn với scarcity** | Bonus này trần 20% HP và **đã** bị Ranked zero-hoá (`metaHpBonus: 0`, `api/submit-run.js:96`). Trên Collector board nó **phải** được tính vào `H`: dùng `H' = H × (1 + nftHpBonusPct/100)`. Nếu bỏ qua, hai ngoại lệ NFT cộng dồn và L3 under-corrects |

### 3.10 Secret class — dawn / dusk / mech

**Dữ liệu thật**: 18 identity, tất cả chỉ có `stage:0` + `stage:1`, **không** có `stage:2`. Phân bố cực lệch: dawn 7 (mouth 1, back 3, tail 1, eyes 1, ears 1) · dusk 6 (horn 1, back 1, tail 2, eyes 2) · mech 5 (horn 3, back 1, tail 1). Nhiều slot **hoàn toàn trống** (dawn không có horn, dusk không có mouth/ears, mech không có mouth/eyes/ears).

**Quyết định — 3 phần, tường minh**:

1. **Class mapping GIỮ NGUYÊN** `ORIGIN_CLASS_MAP = {dawn:'beast', dusk:'reptile', mech:'bug'}`. Body class của một con Axie dawn vẫn map sang `beast`, nên nó vẫn nhận passive `FERAL`, vẫn dùng `HEROES.beast1.hp`, vẫn có màu Beast. **Bản sắc class vẫn đọc được** — đây là ràng buộc cứng của product owner và mapping hiện có đã thoả nó.
2. **NHƯNG face KHÔNG lấy từ family variant của class được map.** 18 part này quá ít để dựng family (1-3 part/slot → family 4-6 variant là vô nghĩa), và chúng là những part khan hiếm nhất của Axie. Cả 18 nhận **face hand-designed độc nhất**, tức là chúng đi đường **Signature** (§3.2). `partKey` giữ `dawn`/`dusk`/`mech` (§3.1) chính là để tra được `SIGNATURE_FACE` riêng cho chúng — nếu normalise class sớm, 18 part này biến mất vào Beast/Reptile/Bug và ta mất đúng thứ đang muốn giữ.
3. **Bucket = X** (`B` không dùng vì face là signature; `rFloor = 2`; `SP = 2` cho §3.9c). Nhãn UI `◈ SECRET`.

**18 face secret-class** — thiết kế theo passive của class được map, nhưng được phép **một điểm lệch trục** mỗi part (đó là điều làm secret class thấy "lai"). Mọi keyword đã verify implement; mọi hướng kwPure đã verify theo §3.7a.

| class → map | slot | Tên part | Face (t · v · k) | r | Lệch trục / ghi chú |
|---|---|---|---|---|---|
| dawn → beast | mouth | Buddy Chorus | dmg 7 · lifesteal · growth | 3 | `lifesteal`+`growth` đều bị lọc khỏi kwPure → không rò rỉ |
| dawn → beast | back | Magic Sack | dmg 6 · aoe | 3 | — |
| dawn → beast | back | Nutdha Statue | shield 6 · thorns:3 | 3 | **Lệch**: Beast không bao giờ có shield. Hợp lệ vì secret class. `shield+thorns` = buff ally ✓ |
| dawn → beast | back | White Gourd | heal 7 · regen:2 | 3 | **Lệch**: Beast không có heal. `heal+regen` = buff ally ✓ |
| dawn → beast | tail | Aegis Talisman | shield 8 · aoe | 3 | **Lệch** (shield). "Aegis" → giáp |
| dawn → beast | eyes | Radiant Darkness | debuff 0 · vulnerable:3 · blind:2 | 3 | debuff → địch ✓. `vulnerable` setup FERAL |
| dawn → beast | ears | Harmonious Silence | mana 3 · cantrip · rerollup | 3 | mana face: chỉ rider ngoài kwPure ✓ |
| dusk → reptile | horn | Dream Eater | dmg 9 · pierce · lifesteal | 3 | cả 2 kw bị lọc khỏi kwPure ✓ |
| dusk → reptile | back | Greedy Urn | shield 9 · thorns:4 | 3 | SCALES: thorns cũng áp poison 1 → rất mạnh, xem E11 |
| dusk → reptile | tail | Black Gourd | poison 5 · aoe | 3 | — |
| dusk → reptile | tail | Maraca | poison 4 · multi:2 · pierce | 3 | `multi`/`pierce` bị lọc ✓; pierce trên poison gây dmg thật (`:489`) |
| dusk → reptile | eyes | Fulu | debuff 0 · weaken:4 · freeze | 3 | debuff → địch ✓ |
| dusk → reptile | eyes | Grand Finale | dmg 12 · exec · heavy | 3 | **Lệch**: Reptile eyes thường là heal. `heavy` là drawback |
| mech → bug | horn | Lost Dream | dmg 8 · blind:2 · weaken:3 | 3 | cả 2 là debuff → địch ✓ |
| mech → bug | horn | Rusty Helm | dmg 7 · heavy · poison:3 | 3 | `poison:3` → địch ✓; VIRULENT +2 nếu đã có poison |
| mech → bug | horn | Shocker | dmg 6 · chain:4 · crit:30 | 3 | cả 2 bị lọc ✓ |
| mech → bug | back | Village Hero | shield 10 · aoe · regen:2 | 3 | `regen` → ally ✓ |
| mech → bug | tail | Mainspring | poison 6 · aoe · multi:2 | 3 | multi → 2 stack mỗi target |

**Slot trống**: một con Axie dawn thật vẫn có 6 part, và những part ở slot dawn không có (ví dụ horn) sẽ mang part của class gốc khác — chúng resolve bình thường qua đường của class đó. Không cần fallback đặc biệt. Nếu Axie phát hành thêm part secret-class, thêm dòng vào bảng trên (không có luật suy diễn — mỗi part secret là hand-designed, đó là điểm mấu chốt).

### 3.11 `FAMILY_VARIANT` — 158 variant, 36 family

**Cách đọc bảng — ĐỌC KHỐI NÀY TRƯỚC, ngữ nghĩa các cột số đã đổi ở revision 2.**

`variantId` đầy đủ = `class.slot.LETTER` (ví dụ `beast.mouth.D`).

| Cột | Ai sở hữu | Ngữ nghĩa |
|---|---|---|
| `v` (chữ cái), `Tên`, **`t · k`**, `Ý đồ` | **DOC — design input, authored** | Đây là quyết định thiết kế thật. Chỉ người sửa được là designer, sửa bằng tay, có lý do ghi kèm. Generator **đọc** cột này. |
| `C / O / P` | **DOC — nhưng ở THANG THAM CHIẾU** | Số ở đây là output công thức khi chạy với `B[C] = B_REF = 6.00` (hằng số của revision 1). Chúng **không phải giá trị runtime**. |
| giá trị runtime | **GENERATOR — `assets/data/part_faces.json`** | Output khi chạy với profile production (`B[C] = 2.80`, F1) + `CoherenceMod` + `geneTier`. Không có trong doc này. |

**Vì sao tách hai thang** (đây là câu trả lời cho 3 defect có cùng nguyên nhân gốc — review defect 1, 6, 7):

Revision 1 duy trì ~474 ô số bằng tay trong Markdown và tự kiểm bằng cách designer đọc lại. Review tìm được: một ô sai công thức (`plant.back.B`@P), một danh sách monotone sai 3 mục, và một hàng TOTAL sai cả 3 cột. Tỉ lệ lỗi ~1/474 ô nghe nhỏ, nhưng **mọi lỗi trong số đó đều lọt qua các kiểm tra mà doc tự đặt ra** — vì các kiểm tra đó cũng làm bằng tay.

Nên: doc giữ **thang tham chiếu** vì nó là *bằng chứng hình dạng* — nó chứng minh 158 variant có tỉ lệ đúng với nhau, ở một thang mà `v ∈ [1,12]` cho đủ độ phân giải để đọc bằng mắt. Generator sở hữu **thang production** vì `v ∈ [1,6]` ở thang đó, việc làm tròn chi phối kết quả, và không ai đọc-bằng-mắt được 474 ô làm tròn.

Hai kiểm tra thay cho việc đọc tay (§8):
- **AC-7** — generator chạy profile *tham chiếu* phải reproduce cột `C/O/P` của §3.11 **đúng từng ô, 474/474**. Đây là regression test cho *thiết kế*.
- **AC-7d** — generator chạy profile *production* phải khớp snapshot đã commit **byte-identical**. Đây là regression test cho *dữ liệu*.

**`B a / b / c` ghi ở header mỗi family cũng là thang tham chiếu** (6.00/7.60/9.60 × `SlotMod`). Nhân `B[C]/B_REF = 0.4667` để ra ngân sách production.

Face `debuff` có `v = 0` luôn; cột C/O/P của chúng là **magnitude của keyword** (`N`), không phải `v`.

Mọi variant đã được kiểm theo **§3.7a kwPure Direction Law** (bản đã sửa — `poison` giờ ở nhóm 3). Mọi keyword đã được kiểm theo bảng §3.7. Mọi family đã được kiểm theo **R6** (§3.5c): không hai variant nào trong cùng family có cùng `(t, sortedKeys)`.

`rFloor` của variant luôn `0` — rarity thực tế do bucket quyết định (`max(0, SCARCITY[bucket].rFloor)`), tức C→r0, O→r1, P→r2, cộng `+1` nếu specialGenes.

---

#### BEAST — FERAL *(attack vs target <50% HP deals +60%)*
Bản sắc: **không** `shield`, **không** `heal` ở bất kỳ variant nào (`I21`). `eyes` là `debuff` để **setup** cho FERAL. Class surcharge: `exec +0.8`.

| variantId | `t · k` | reachable |
|---|---|---|
| `beast.mouth.A` | `dmg · vulnerable:2` | ✓ |
| `beast.mouth.B` | `dmg · lifesteal · selfharm:1` | ✓ |
| `beast.mouth.C` | `dmg · growth · heavy` | ✓ |
| `beast.mouth.D` | `dmg · multi:2` | ✓ |
| `beast.mouth.E` | `dmg · exec · heavy` | ✓ |
| `beast.mouth.F` | `dmg · selfharm:2` | ✓ |
| `beast.horn.A` | `dmg · vulnerable:3` | ✓ |
| `beast.horn.B` | `dmg · heavy · selfharm:2` | ✓ |
| `beast.horn.C` | `dmg · pierce · vulnerable:2` | ✓ |
| `beast.horn.D` | `dmg · cleave · heavy` | ✓ |
| `beast.horn.E` | `dmg · vital · selfharm:1` | ✓ |
| `beast.back.A` | `dmg · vulnerable:2` | ✓ |
| `beast.back.B` | `dmg · heavy · growth` | ✓ |
| `beast.back.C` | `dmg · lifesteal · vulnerable:1` | ✓ |
| `beast.back.D` | `dmg · aoe · selfharm:1` | ✓ |
| `beast.back.E` | `dmg · multi:2 · vulnerable:1` | ✓ |
| `beast.tail.A` | `dmg · multi:3` | ✓ |
| `beast.tail.B` | `dmg · cleave · vulnerable:1` | ✓ |
| `beast.tail.C` | `dmg · chain:3 · vulnerable:1` | ✓ |
| `beast.tail.D` | `dmg · selfharm:1 · multi:2` | ✓ |
| `beast.eyes.A` | `debuff · vulnerable:N` | ✓ |
| `beast.eyes.B` | `debuff · weaken:N` | ✓ |
| `beast.eyes.C` | `debuff · blind:N` | ✓ |
| `beast.eyes.D` | `debuff · vulnerable:N · blind:1` | ✓ |
| `beast.ears.A` | `mana · cantrip · heavy` | ✓ |
| `beast.ears.B` | `mana · heavy` | ✓ |
| `beast.ears.C` | `mana · cantrip · selfharm:2` | ✓ |
| `beast.ears.D` | `debuff · vulnerable:N` *(type-break)* | ✓ |

*(`beast.mouth.A` và `beast.back.A` cùng `dmg·vulnerable:2` nhưng **khác slot** — `p` nằm trong tuple engine nên không phải va chạm. Tương tự `beast.eyes.A` / `beast.ears.D`.)*

---

#### AQUA — CONDUIT *(mọi Mana +1; mỗi 4 Mana tiêu → 1 Reroll)*
Bản sắc: `mana:N` rider ở phần lớn slot — class duy nhất biến damage/shield thành tempo. Class surcharge: `mana:N` **+0.45/stack** · `TYPE_COST[aqua][mana] = 1.20`.

| variantId | `t · k` | reachable |
|---|---|---|
| `aqua.mouth.A` | *(spare)* | — |
| `aqua.mouth.B` | `dmg · lifesteal · mana:1` | ✓ |
| `aqua.mouth.C` | `dmg · mana:2` | ✓ |
| `aqua.mouth.D` | `dmg · exec · mana:1` | ✓ |
| `aqua.horn.A` | `dmg · mana:1` | ✓ |
| `aqua.horn.B` | `dmg · pierce · mana:1` | ✓ |
| `aqua.horn.C` | `dmg · crit:15` | ✓ |
| `aqua.horn.D` | `dmg · mana:3` | ✓ |
| `aqua.horn.E` | `dmg · heavy · mana:2` | ✓ |
| `aqua.back.A` | `shield · mana:2` | ✓ |
| `aqua.back.B` | `shield · aoe · mana:1` | ✓ |
| `aqua.back.C` | `shield · regen:2 · mana:1` | ✓ |
| `aqua.back.D` | `shield · undying` | ✓ |
| `aqua.tail.A` | `dmg · mana:1` | ✓ |
| `aqua.tail.B` | `dmg · aoe · mana:1` | ✓ |
| `aqua.tail.C` | `dmg · chain:3 · mana:1` | ✓ |
| `aqua.tail.D` | `dmg · multi:2 · mana:1` | ✓ |
| `aqua.tail.E` | `dmg · mana:2` | ✓ |
| `aqua.eyes.A` | `heal · mana:1` | ✓ |
| `aqua.eyes.B` | `heal · aoe · mana:1` | ✓ |
| `aqua.eyes.C` | `heal · regen:2` | ✓ |
| `aqua.eyes.D` | `heal · cantrip` | ✓ |
| `aqua.ears.A` | `mana · cantrip · selfharm:1` | ✓ |
| `aqua.ears.B` | `mana` | ✓ |
| `aqua.ears.C` | `mana · cantrip · mana:1` | ✓ |
| `aqua.ears.D` | `shield · mana:1` *(type-break)* | ✓ |

---

#### PLANT — BULWARK *(mọi Shield +2; ≥10 Shield → Thorns 2)*
Bản sắc: 2/6 slot là `shield` (back **và** tail), `eyes` là `heal`. Không có variant `poison`. Class surcharge: face type `shield` **−1.7 ngân sách** (BULWARK cộng +2 miễn phí vào *mọi* shield, nên shield ở Plant đắt hơn thật).

| variantId | `t · k` | reachable |
|---|---|---|
| `plant.mouth.A` | `dmg · vital` | ✓ |
| `plant.mouth.B` | `dmg · growth · vital` | ✓ |
| `plant.mouth.C` | `dmg · decay` | ✓ |
| `plant.mouth.D` | `dmg · rerollup` | ✓ |
| `plant.horn.A` | `dmg · growth` | ✓ |
| `plant.horn.B` | `dmg · pierce · growth` | ✓ |
| `plant.horn.C` | `dmg · heavy · growth` | ✓ |
| `plant.horn.D` | `dmg · cleave · vital` | ✓ |
| `plant.horn.E` | `dmg · weaken:2` | ✓ |

| `plant.back.A` | `shield · regen:2` | ✓ |
| `plant.back.B` | `shield · aoe · regen:1` | ✓ |
| `plant.back.C` | `shield · thorns:2` | ✓ |
| `plant.back.D` | `shield · regen:3` | ✓ |
| `plant.back.E` | `shield · heavy` | ✓ |
| `plant.tail.A` | `shield · regen:3` | ✓ |
| `plant.tail.B` | `shield · aoe · growth` | ✓ |
| `plant.tail.C` | `shield · thorns:2 · cantrip` | ✓ |
| `plant.tail.D` | `shield · cantrip · regen:2` | ✓ |
| `plant.tail.E` | `shield · growth` | ✓ |
| `plant.eyes.A` | *(spare)* | — |
| `plant.eyes.B` | `heal · aoe · growth` | ✓ |
| `plant.eyes.C` | `heal · regen:2 · growth` | ✓ |
| `plant.eyes.D` | `heal · cantrip · growth` | ✓ |
| `plant.ears.A` | `mana · cantrip · decay` | ✓ |
| `plant.ears.B` | `mana · growth` | ✓ |
| `plant.ears.C` | `mana · rerollup · growth` | ✓ |
| `plant.ears.D` | `mana · cantrip · vital` | ✓ |

---

#### BIRD — TALON *(Pierce attack +3 dmg; mọi face `aoe` cũng được Pierce)*
Bản sắc: `dmg` ở 4/6 slot, **không bao giờ** `shield`, **không bao giờ** `heal` (khớp `HEROES.bird1/2/3` thật). `back` và `eyes` là trục utility/`debuff`.
Class surcharge: `pierce` **+0.9** (TALON cộng +3 dmg mỗi đòn pierce) · `aoe` **+1.4** (vì `engine.js:466` tự cấp Pierce cho mọi face `aoe` của Bird → `aoe` ở Bird đắt gấp đôi bình thường).

| variantId | `t · k` | reachable |
|---|---|---|
| `bird.mouth.A` | `dmg · pierce` | ✓ |
| `bird.mouth.B` | `dmg · pierce · crit:15` | ✓ |
| `bird.mouth.C` | `dmg · pierce · multi:2` | ✓ |
| `bird.mouth.D` | `dmg · multi:2 · crit:25` | ✓ |
| `bird.horn.A` | `dmg · pierce · crit:15` | ✓ |
| `bird.horn.B` | `dmg · pierce · multi:2` | ✓ |
| `bird.horn.C` | `dmg · crit:40` | ✓ |
| `bird.horn.D` | `dmg · pierce · cleave` | ✓ |
| `bird.back.A` | `dmg · pierce · aoe` | ✓ |
| `bird.back.B` | `dmg · aoe · crit:15` | ✓ |
| `bird.back.C` | `debuff · vulnerable:N` | ✓ |
| `bird.back.D` | `dmg · multi:2 · pierce` | ✓ |
| `bird.back.E` | `dmg · chain:3` | ✓ |
| `bird.tail.A` | *(spare)* | — |
| `bird.tail.B` | `dmg · aoe · multi:2` | ✓ |
| `bird.tail.C` | `dmg · chain:4` | ✓ |
| `bird.tail.D` | *(spare)* | — |
| `bird.eyes.A` | `debuff · blind:N · vulnerable:1` | ✓ |
| `bird.eyes.B` | `debuff · weaken:N · blind:1` | ✓ |
| `bird.eyes.C` | `debuff · vulnerable:N · aoe` | ✓ |
| `bird.eyes.D` | *(spare)* | — |
| `bird.ears.A` | `mana · rerollup` | ✓ |
| `bird.ears.B` | `mana · cantrip · selfharm:3` | ✓ |
| `bird.ears.C` | `mana · rerollup · vital` | ✓ |
| `bird.ears.D` | `mana · vital` | ✓ |
| `bird.ears.E` | `debuff · blind:N` | ✓ |

---

#### BUG — VIRULENT *(áp Poison lên target đã có Poison → +2 stack thay vì +1)*
Bản sắc: `poison` xuất hiện ở 4/6 slot (mouth·D, horn·D, tail toàn bộ, eyes·C). `eyes` là `debuff`. Class surcharge: `poison:N` rider **+0.5** · face type `poison` **−0.9 ngân sách** (VIRULENT khiến stack thứ hai trở đi mạnh gấp đôi).

| variantId | `t · k` | reachable |
|---|---|---|
| `bug.mouth.A` | `dmg · poison:2` | ✓ |
| `bug.mouth.B` | `dmg · poison:3` | ✓ |
| `bug.mouth.C` | `dmg · weaken:2` | ✓ |
| `bug.mouth.D` | *(spare)* | — |
| `bug.horn.A` | `dmg · poison:2` | ✓ |
| `bug.horn.B` | `dmg · poison:3` | ✓ |
| `bug.horn.C` | `dmg · blind:1` | ✓ |
| `bug.horn.D` | `dmg · blind:2 · poison:1` | ✓ |
| `bug.horn.E` | `dmg · weaken:2 · poison:1` | ✓ |
| `bug.back.A` | `shield · growth` | ✓ |
| `bug.back.B` | `shield · aoe · thorns:2` | ✓ |
| `bug.back.C` | `shield · regen:2 · thorns:1` | ✓ |
| `bug.back.D` | `shield · heavy · thorns:2` | ✓ |
| `bug.back.E` | `shield · vital` | ✓ |
| `bug.tail.A` | `poison · multi:2` | ✓ |
| `bug.tail.B` | `poison · aoe · growth` | ✓ |
| `bug.tail.C` | `poison · pierce` | ✓ |
| `bug.tail.D` | `poison · multi:3` | ✓ |
| `bug.eyes.A` | `debuff · poison:N` | ✓ |
| `bug.eyes.B` | `debuff · weaken:N · poison:1` | ✓ |
| `bug.eyes.C` | `debuff · blind:N · poison:1` | ✓ |
| `bug.eyes.D` | *(spare)* | — |
| `bug.ears.A` | `mana · cantrip · growth` | ✓ |
| `bug.ears.B` | `mana · selfharm:2` | ✓ |
| `bug.ears.C` | `mana · rerollup · decay` | ✓ |
| `bug.ears.D` | `mana · decay` | ✓ |
| `bug.ears.E` | `debuff · poison:N` | ✓ |

---

#### REPTILE — SCALES *(luôn có Thorns 2; Thorns của bạn cũng áp Poison 1)*
Bản sắc: `back` = shield có thorns, `tail` = poison, `eyes` = heal. Class surcharge: `thorns:N` **+0.6** (SCALES biến mỗi lần thorns kích hoạt thành thorns **+ poison 1** — đây là keyword đắt nhất của class này).

| variantId | `t · k` | reachable |
|---|---|---|
| `reptile.mouth.A` | `dmg · heavy` | ✓ |
| `reptile.mouth.B` | `dmg · blind:1` | ✓ |
| `reptile.mouth.C` | `dmg · lifesteal · heavy` | ✓ |
| `reptile.mouth.D` | `dmg · crit:30` | ✓ |
| `reptile.horn.A` | *(spare)* | — |
| `reptile.horn.B` | `dmg · poison:2 · heavy` | ✓ |
| `reptile.horn.C` | `dmg · poison:4` | ✓ |
| `reptile.horn.D` | `dmg · heavy · vulnerable:2` | ✓ |
| `reptile.back.A` | `shield · thorns:3` | ✓ |
| `reptile.back.B` | `shield · thorns:2 · regen:1` | ✓ |
| `reptile.back.C` | `shield · aoe · undying` | ✓ |
| `reptile.back.D` | *(spare)* | — |
| `reptile.tail.A` | *(spare)* | — |
| `reptile.tail.B` | `poison · aoe · heavy` | ✓ |
| `reptile.tail.C` | `poison · pierce · heavy` | ✓ |
| `reptile.tail.D` | *(spare)* | — |
| `reptile.eyes.A` | `heal · thorns:2` | ✓ |
| `reptile.eyes.B` | `heal · regen:3` | ✓ |
| `reptile.eyes.C` | `heal · aoe · thorns:1` | ✓ |
| `reptile.eyes.D` | `heal · undying` | ✓ |
| `reptile.ears.A` | `mana · rerollup · heavy` | ✓ |
| `reptile.ears.B` | `mana · selfharm:1` | ✓ |
| `reptile.ears.C` | `mana · growth · heavy` | ✓ |
| `reptile.ears.D` | `buff · thorns:N` | ✓ |

**Kiểm đếm §3.11**: beast 6+5+5+4+4+4=28 · aqua 4+5+4+5+4+4=26 · plant 4+5+5+5+4+4=27 · bird 4+4+5+4+4+5=26 · bug 4+5+5+4+4+5=27 · reptile 4+4+4+4+4+4=24 → **158 variant** ✓ khớp §3.5b.

### 3.12 `PART_VARIANT` — bảng gán 204 part, curated

Ký hiệu: `Tên (bucket) → variant`. Bucket `C`=Classic · `O`=Origin(α) · `P`=Prime. **Trong mỗi bucket của mỗi family, variant không lặp** (luật R1, §3.5c) — đây là điều làm AC-4 (không hai part cùng family ra face giống nhau) đúng do cấu trúc.

Part **Signature** không có trong bảng này (chúng ở §3.3a/§3.3b). Part secret-class không có trong bảng này (§3.10).

#### BEAST (39)
- **mouth** — Foxy (O)→E · Platypus (O)→D · Puff (O)→A · Puppy (O)→C · Shishi (O)→F · Sniffle (O)→B
- **horn** — Arco (C)→C · Merry (C)→E · Beast Bun (O)→E · Lump (O)→D · Rocky Skull (O)→B · Small Yak (O)→A · Toy Ball (O)→C
- **back** — Furball (C)→D · Hero (C)→A · Jaguar (C)→E · Risky Beast (C)→C · Timber (C)→B · Pangolin Slayer (O)→**C** *(R5: →B đụng `Ronin`)*
- **tail** — Cottontail (C)→A · Gerbil (C)→D · Hare (C)→B · Rice (C)→C · Buba Brush (O)→C · Pangolin (O)→A · Nut Cracker (P)→B · Shiba (P)→D
- **eyes** — Chubby (C)→B · Daydreaming (O)→C · Nut Cracker (O)→A · Sobby (O)→B · Sparky (O)→D · Puppy (P)→A
- **ears** — Zen (C)→C · Foxy (O)→B · Belieber (P)→A · Innocent Lamb (P)→C · Nut Cracker (P)→D · Puppy (P)→B

#### AQUA (34)
- **mouth** — Catfish (C)→C · Risky Fish (C)→D · Ranchu (O)→B
- **horn** — Babylonia (C)→A · Clamshell (C)→E · Oranda (C)→C · Shoal Star (C)→B · Teal Shell (C)→D · Darksea Jellyfish (O)→C · Jellytacle (O)→B
- **back** — Anemone (C)→C · Blue Moon (C)→B · Goldfish (C)→D · Perch (C)→A · Sponge (P)→D
- **tail** — Koi (C)→A · Navaga (C)→D · Nimo (C)→E · Ranchu (C)→C · Shrimp (C)→B · Oranda (O)→C · Puff (O)→B · Tadpole (P)→E
- **eyes** — Clear (C)→A · Gero (C)→C · Telescope (C)→D · Baby (O)→C · Cold Fish (O)→A · Kind Fish (O)→B
- **ears** — Inkling (C)→C · Nimo (C)→A · Seaslug (C)→D · Tiny Fan (C)→B · Little Crab (O)→D

#### PLANT (44)
- **mouth** — Herbivore (C)→B · Serious (C)→**C** · Silence Whisper (C)→D · Beetroot (O)→B · Hazelnut (O)→**A** · Kidney Bean (O)→D *(R5: `Serious`→A đụng `Zigzag`; đổi chỗ với `Hazelnut` để `A` vẫn có part dùng)*
- **horn** — Bamboo Spear (C)→B · Beech (C)→C · Rose Bud (C)→E · Strawberry Shortcake (C)→D · Watermelon (C)→A · Acorn Cap (O)→C · Ballad Of The Shore (O)→D · Lotus (O)→B · Mandarine (O)→A · Persimmon (O)→E
- **back** — Bidens (C)→C · Mint (C)→D · Shiitake (C)→A · Turnip (C)→E · Watering Can (C)→B · Cone Shell (O)→E · Death Shroom (O)→C · Forest Hero (O)→A · Meadow Blanket (O)→B · Succulent (O)→D
- **tail** — Carrot (C)→D · Cattail (C)→C · Hatsune (C)→E · Potato Leaf (C)→A · Yam (C)→B · Drowsy Moss (O)→E · Sprout (O)→D · Tropical Guardian (O)→A
- **eyes** — Confusion (C)→D · Risky Trunk (O)→B · Papi (P)→C
- **ears** — Hollow (C)→B · Leafy (C)→A · Lotus (C)→D · Rosa (C)→C · Greenwood Rhythm (O)→C · Turnip (O)→A · Sakura (P)→D

#### BIRD (28)
- **mouth** — Doubletalk (C)→D · Hungry Bird (C)→C · Peace Maker (C)→A · Feathery Dart (O)→B
- **horn** — Cuckoo (C)→C · Feather Spear (C)→B · Trump (C)→D · Big Sister (O)→A
- **back** — Cupid (C)→C · Kingfisher (C)→A · Pigeon Post (C)→E · Raven (C)→B · Tri Feather (C)→D · Feather Melody (O)→B · Lil Bro (O)→D · Paper Wing (O)→E · Rubber Duckling (O)→C
- **tail** — Feather Fan (C)→B · Death Shower (O)→C
- **eyes** — Little Owl (C)→B · Lucas (C)→A · Concentrate (O)→A · Passion (O)→C
- **ears** — Curly (C)→C · Early Bird (C)→A · Little Owl (C)→E · Peace Maker (C)→B · Pink Cheek (C)→D

#### BUG (35)
- **mouth** — Cute Bunny (C)→C · Square Teeth (C)→A · Maggot (O)→**C** · Nose Drill (O)→B *(R5: `Maggot`→D đụng `Pincer`; "maggot hút" → lifesteal khớp hơn. `D` thành spare)*
- **horn** — Antenna (C)→E · Caterpillars (C)→B · Lagging (C)→D · Leaf Bug (C)→A · Pliers (C)→C
- **back** — Buzz Buzz (C)→B · Garish Worm (C)→D · Sandal (C)→E · Scarab (C)→A · Spiky Wing (C)→C
- **tail** — Ant (C)→A · Fish Snack (C)→C · Gravel Ant (C)→B · Pupae (C)→D · Centipede (O)→C · Eye Wing (O)→B · Leaf Bug (O)→A · Shield Shattering (O)→D
- **eyes** — Bookworm (C)→A · Kotaro? (C)→C · Nerdy (C)→B · Ladybug Goggles (O)→B
- **ears** — Beetle Spike (C)→D · Ear Breathing (C)→B · Earwing (C)→A · Larva (C)→E · Tassels (C)→C · Brimstone (O)→D · Maggot (O)→E · Termites (O)→C · Leaf Bug (P)→A

#### REPTILE (24)
- **mouth** — Kotaro (C)→A · Tiny Turtle (C)→D · Chemical Fang (O)→B · Tiny Dino (O)→C
- **horn** — Scaly Spoon (C)→**B** · Unko (C)→D · Poison Tube (O)→C · Bumpy (P)→D *(R5: `Scaly Spoon`→A đụng `Incisor`. `A` thành spare thay cho `B`)*
- **back** — Bone Sail (C)→B · Red Ear (C)→C · Tiny Dino (O)→B · Croc (P)→A
- **tail** — Iguana (C)→B · Snake Jar (C)→**C** *(R5: `Snake Jar`→A đụng `Grass Snake`. Spare thành `A`,`D`)*
- **eyes** — Topaz (C)→A · Tricky (C)→D · Hard-boiled (O)→B · Punky (O)→C
- **ears** — Pogona (C)→A · Small Frill (C)→B · Swirl (C)→C · Hidden Ears (O)→B · Venom Nail (O)→D · Curved Spine (P)→C

**Kiểm đếm §3.12**: beast 39 + aqua 34 + plant 44 + bird 28 + bug 35 + reptile 24 = **204** ✓ = 267 identity 6-class − 63 signature.

**Variant chưa được part nào dùng (spare)** — **11** slot, tất cả nằm ở family nhỏ hoặc do R5 đẩy ra. Đây là dung lượng forward-compat khi Axie thêm part (catalog đã tăng 192→285 một lần), và là ứng viên `FACE_POOL` Phase 2. Liệt kê đủ để test đếm chính xác:

`aqua.mouth.A` · `plant.eyes.A` · `bird.tail.A` · `bird.tail.D` · `bird.eyes.D` · `bug.eyes.D` · `bug.mouth.D` · `reptile.horn.A` · `reptile.back.D` · `reptile.tail.A` · `reptile.tail.D`

*(So với bản trước khi áp R5: `reptile.horn.B`→`reptile.horn.A`, `reptile.tail.C`→`reptile.tail.A`, thêm mới `bug.mouth.D`.)*

→ **Variant reachable từ catalog hiện tại = 158 − 11 = 147.**
→ **Tổng face reachable = 147 variant + 81 signature = 228.**
→ **Tổng face được thiết kế = 158 + 81 = 239.**

### 3.13 ĐỐI CHIẾU SỐ ĐẾM — "63" và "81" không mâu thuẫn

Hai con số signature xuất hiện trong doc này và **chúng đếm hai thứ khác nhau**. Đây không phải lỗi số học:

| Con số | Đếm cái gì | Xuất hiện ở |
|---|---|---|
| **63** | Signature **chỉ trong 6 class chính** = 50 `FACE_NAMES` + 13 Addendum | §3.3, §3.3a/b, checksum §3.12 (`267 − 63 = 204`) |
| **18** | Signature **secret-class** (dawn/dusk/mech) — face hand-designed riêng, §3.10 | §3.10 |
| **81** | **Tổng** signature = 63 + 18 | §3.2, block đếm cuối §3.12 |

Lý do 18 part secret-class là signature nhưng **không** nằm trong Icon List: chúng không đủ đông để dựng family (1–3 part/slot) nên chúng buộc phải đi đường Signature vì *cấu trúc*, không vì *iconicity*. Icon List là danh sách curate theo danh tiếng; 18 part secret vào đường Signature theo luật §3.10 mục 2. Hai lối vào khác nhau, cùng một đường ra.

Không có part nào bị đếm hai lần. `SIGNATURE_FACE` có đúng **81 khoá**, và tập khoá của nó rời hoàn toàn với `PART_VARIANT` (204 khoá). `81 + 204 = 285` = toàn bộ catalog ✓ (AC-3 kiểm chính xác điều này).

**Khối lượng authoring: 239 template** (158 variant + 81 signature), trong đó **228 reachable** từ catalog 285-part hiện tại (11 variant là spare forward-compat, §3.12). Đây **không** phải số headline — xem §0-bis.

#### 3.13a. Ba cơ sở đếm, và cơ sở NÀO là headline

| Cơ sở | Hiện tại | Hệ này **hôm nay** | Hệ này **sau R7/R8** | Ai xác nhận |
|---|---|---|---|---|
| **Template authored** (số entry designer viết) | 36 | **239** = 158 variant + 81 signature | 239 (không đổi) | Đếm tay, AC-9a |
| **Template reachable** (từ catalog 285-part) | 36 | **228** = 147 variant + 81 signature | 228 (không đổi) | Đếm tay, AC-6 |
| **Identity phân biệt** — `(cls, p, t, v, k)` | 36 (thực chất mọi part cùng `(slot,class)` **y hệt**) | **285** | 285 | AC-9b |
| 🔴 **Face engine phân biệt** — `(p, t, v, k)`, **bỏ `cls`** | **19** | **190** *(máy)* | **285** | AC-9c, generator |

**Headline chính thức từ revision 3: cơ sở thứ tư — 19 → 285.** Đổi so với revision 2 (vốn chọn "template authored: 36 → 239"). Lý do đổi: cơ sở "template authored" đếm *công sức của designer*, không đếm *trải nghiệm của người chơi*, và chính cách đặt headline đó đã sinh ra câu hỏi "sao không phủ hết 285".

##### Hiện trạng = 19, đã đếm tay và kiểm lại

`SLOT_CLASS_TEMPLATE` (`src/data.js`, symbol `SLOT_CLASS_TEMPLATE`) có 36 entry nhưng engine chỉ *thấy* **19** face phân biệt:

| slot | 6 entry cho ra | Trùng nhau ở đâu |
|---|---|---|
| eyes | **5** | plant và aqua đều `heal 3` |
| ears | **1** | **cả 6 class** đều `mana 1 · cantrip` |
| mouth | **3** | beast/aqua/reptile/bug đều `dmg 3` |
| horn | **3** | plant/bug đều `dmg 3`; aqua/reptile/bird đều `dmg 3 · pierce` |
| back | **3** | plant/reptile `shield 4`; beast/bird `shield 2`; aqua/bug `shield 3` |
| tail | **4** | plant/reptile `dmg 2`; aqua/bird `dmg 2 · aoe` |
| **Tổng** | **19** | |

Điều đó **làm luận điểm mạnh hơn, không yếu hơn**: hiện trạng tệ hơn con số 36 gợi ra. Import một con Beast và một con Plant hôm nay cho **hai mặt `ears` y hệt** và ba mặt `mouth`/`horn`/`tail` gần như y hệt — xuyên cả class, không chỉ trong cùng class. *(Bản vá `PART_VARIANT_MODS` đã ship trong lúc soạn doc này nới con số đó lên nhưng bằng hash và bằng `±1 value` — xem §0; nó bị supersede.)*

##### 3.13b. Hệ này HÔM NAY = 201/285 — con số thật, đếm từ §3.11 + §3.12

Revision 2 để ô này là placeholder (`{{GEN:distinctEngineFaces}}`) và đặt một **sàn** `≥ 76`. Sàn đó là thứ product owner đã đúng khi chất vấn: nó cách 285 quá xa và nó không nói cho ai biết khoảng trống lớn bao nhiêu. Revision 3 **đếm ra con số**, thang tham chiếu (`B_REF = 6.00`, nơi `SIG_IMPORT_SCALE = 1.0` nên signature giữ nguyên số `FACE_POOL`), gene 0, coherence 1.00:

| slot | part trong slot | face engine phân biệt *(máy)* | **mất** | Nguyên nhân chính |
|---|---|---|---|---|
| mouth | 41 = 27 var + 14 sig | **27** | 14 | 5 family cùng có `dmg·lifesteal`; `dmg 6` trần ở 3 family + 2 signature |
| horn | 54 = 37 var + 17 sig | **33** | 21 | `dmg·pierce` ở **cả 6** family; `dmg·heavy` ở 4 family + `Imp` |
| back | 52 = 39 var + 13 sig | **39** | 13 | `shield·aoe` và `shield·regen:2` lặp ở 4 family |
| tail | 52 = 36 var + 16 sig | **40** | 12 | `poison·aoe`, `poison·multi:2` lặp bug↔reptile |
| eyes | 40 = 27 var + 13 sig | **29** | 11 | `debuff·weaken:N`, `debuff·blind:N`, `heal·aoe` lặp |
| ears | 46 = 38 var + 8 sig | **22** | 24 | **tệ nhất** — 5/6 family có bộ variant `mana` gần y hệt nhau |
| **TỔNG** | **285** | **190** | **95** | |

Kiểm chéo hai chiều: cột part = 27+37+39+36+27+38 = **204 variant instance** ✓ (§3.12) và 14+17+13+16+13+8 = **81 signature** ✓ (§3.13c). Tổng 285 ✓.

> ## ⛔ SỐ TRONG BẢNG TRÊN LÀ LỊCH SỬ — KHÔNG CÒN ĐO LẠI ĐƯỢC
>
> `AC-9c-base` **đã bị thu hồi**: nó đếm distinct-face của các bộ keyword **trước** pass re-author, và pass đó đã **thay thế** chính những bộ keyword ấy. Không còn cấu hình nào của generator tái tạo được con số này — `--no-r7` giờ chạy trên bảng mới, không phải bảng cũ. Một AC không đo lại được là một AC phải xoá, không phải một AC để nguyên với con số cũ.
>
> **Phép đo hợp lệ cuối cùng** (`gen_faces.mjs`, trên bảng **tiền hợp nhất**): **198** ở profile tham chiếu · **190** ở production. Phép đếm tay của tôi là **201** và nó sai ở cả hai — nó trộn số *trước* REPAIR cho `mouth`/`ears` với số *sau* REPAIR cho `horn`/`back`/`eyes`, nên nó không mô tả **bất kỳ cấu hình thật nào**. Đó là lý do ba con số khác nhau đều trông có lý.
>
> **Bài học ghi lại, vì nó là nguyên nhân gốc chứ không phải triệu chứng**: mọi con số distinct-face phải nêu **hai** tham số mới có nghĩa — **profile** (`reference` hay `production`) **và REPAIR đã chạy chưa**. Thiếu một trong hai thì con số không falsifiable. Áp cho mọi AC đếm face từ nay.
>
> **Trạng thái hiện tại (đích)**: **285 / 285 / 285** — 285 identity, 285 distinct ở `(cls,p,t,v,k)`, 285 distinct ở `(p,t,v,k)`, **ở cả hai profile**, 0 face mất ở mọi slot. Đó là `AC-9b` + `AC-9c`, và chúng *có* đo lại được.
>
> Sai ở đâu: đếm tay resolve 285 dòng qua hai bảng rồi gom tuple theo slot — đúng loại việc mà §6f nói con người làm sai một cách hệ thống, và tôi làm sai đúng như vậy, **kể cả sau khi ba kiểm chéo cấu trúc đã pass** (204 · 81 · 285). Ba kiểm đó ràng buộc *số phần tử*, không ràng buộc *số phần tử phân biệt* — chúng không có khả năng bắt lỗi gộp trùng. Cùng hạng lỗi với checksum triệt tiêu ở §3.5b.
>
> **Cái không đổi theo**: khoảng trống là **95 part** (lớn hơn ước lượng, nên luận điểm mạnh hơn chứ không yếu đi); nguyên nhân **70 bộ keyword / 147 template** là số đo **độc lập** ở §3.5c-bis và **không** phụ thuộc phép đếm này; `ears` là slot tệ nhất — máy xác nhận (22/46, tệ hơn cả ước lượng 25). Cách đóng là R7+R8+`SIG_LIFT`, không đổi.
>
> **Luật rút ra, ghi để không lặp**: không suy lại con số này bằng tay. `AC-9c-base` chạy `--no-r7` là nguồn sự thật duy nhất.

**84 part mất mặt riêng.** Phân rã: **68** do variant↔variant xuyên family (một class khác dùng đúng bộ keyword đó ở đúng số đó), **16** do va vào signature (trong đó 5 là signature↔signature — bảng §3.5d-bis).

**Đây là con số trả lời câu hỏi của product owner.** Không phải "285 − 239 = 46 part bị bỏ" (không part nào bị bỏ), mà là "84 part *có* face riêng nhưng engine không phân biệt được nó với face của một class khác cùng slot".

##### 3.13c. Sau R7 + R8 = 285/285 — và vì sao con số đó KHÔNG phụ thuộc `B[C]`

Chứng minh ba nhánh đã nêu ở §3.5c. Điều đáng nhấn: revision 2 chuyển ô này cho generator vì nó *"phụ thuộc `B[C]` — hạ ngân sách nén dải `v` → tăng collision"*. Nhận định đó **đúng với thiết kế revision 2** và là lý do 201 sẽ **tụt thấp hơn nữa** ở profile production. Với R7, sự phụ thuộc đó **biến mất**: phân biệt nằm ở keyword-set (không bị nén) và ở monotone `v(C)<v(O)<v(P)` (đúng do cấu trúc F6, không do làm tròn). Nên `distinctEngineFaces === 285` ở **cả hai** profile — và AC-9c assert đúng như vậy ở cả hai, thay vì assert một snapshot.

**Có đạt trọn 285 không, hay phải chấp nhận thiếu?** Đạt trọn. Không có rào cản cấu trúc nào: ba nhánh của chứng minh vét cạn mọi cặp part, và cả ba nhánh đều được một bất biến máy kiểm bảo vệ (`I4` R1, `I7` F6, `I5` R7, `I6` R8). Cái phải trả **không** phải một sự thoả hiệp về con số — nó là **77 bộ keyword mới phải author** (§3.5c-bis) và **6 face signature hand-designed phải đổi số** (§3.5d-bis). Cả hai đều nằm gọn trong đúng hai bảng của doc này (§3.11, §3.3b/§3.10), không đụng `FACE_POOL` legacy, không đụng `HEROES`, không cần keyword engine mới.

**Ba rủi ro của việc ép 285, nêu trước để không ai ngạc nhiên** (mỗi cái có một bất biến canh):
1. **Keyword stack phi lý.** Nếu ai giải 77 ô thiếu bằng cách chồng keyword đắt thay vì đổi magnitude/lệch type, face sẽ phi lý về flavour *và* bị clamp `v = 1` ở production. Canh bằng `I19` (số ô `clampFloor` không tăng quá 20%) và `I20` (không face variant nào có >3 keyword).
2. **Bản sắc class nhoè.** Ép mỗi family một bộ keyword riêng có thể đẩy Beast sang `shield`, Bird sang `heal` — phá bản sắc §3.11. Canh bằng `I21`: **class identity whitelist** — mỗi class khai báo tập type được phép ở §3.11 header (Beast: không `shield`/`heal`; Bird: không `shield`/`heal`; Plant: không `poison`), và generator fail nếu một variant vi phạm. Lệch type chỉ được dùng **trong** whitelist đó.
3. **Vi phạm dải ngân sách.** Canh bằng AC-7 (474/474 khớp ô ở profile tham chiếu) — nó vốn đã chặt hơn mọi dải %.

##### 3.13d. "63" và "81" không mâu thuẫn — và phân bổ 81 signature theo slot

| Con số | Đếm cái gì | Xuất hiện ở |
|---|---|---|
| **63** | Signature **chỉ trong 6 class chính** = 50 `FACE_NAMES` + 13 Addendum | §3.3, §3.3a/b, checksum §3.12 (`267 − 63 = 204`) |
| **18** | Signature **secret-class** (dawn/dusk/mech), §3.10 | §3.10 |
| **81** | **Tổng** = 63 + 18 | §3.2, §3.13b |

Phân bổ theo slot (dùng để viết test §3.5d-bis bước 1): mouth 14 (10 legacy + 3 addendum + 1 secret) · horn 17 (10+3+4) · back 13 (6+2+5) · tail 16 (11+1+4) · eyes 13 (8+2+3) · ears 8 (5+2+1) = **81** ✓. *(Cột legacy cộng lại = 50 ✓ — lưu ý #41 `Goda` là beast·**mouth**, dễ bỏ sót khi đếm tay; revision 2 đã bỏ sót nó.)*

`SIGNATURE_FACE` có đúng **81 khoá**, rời hoàn toàn với `PART_VARIANT` (204 khoá). `81 + 204 = 285` ✓ (AC-3).

Và điều product owner thực sự hỏi: số mặt *khác nhau mà hai con Axie cùng class có thể ra* đi từ **0** (hiện tại: **luôn** giống hệt 6/6) lên **6/6** — bảo đảm bởi R1 + R7, độc lập với mọi con số tuning.

---

## 4. Formulas

Mọi con số trong §3.11 và §3.3b phải suy được từ mục này. `tools/gen_faces.mjs` (§6) implement đúng F1–F8 và **phải reproduce bảng §3.11 byte-identical** — đó là AC-7.

### F0. Ký hiệu

| Ký hiệu | Nghĩa | Miền |
|---|---|---|
| `bucket` | scarcity bucket của `partKey` | `C \| O \| P \| X` |
| `B` | ngân sách gốc theo bucket | 6.0 … 9.6 |
| `SlotMod` | hệ số slot | 0.95 … 1.10 |
| `B_eff` | ngân sách hiệu dụng | 5.70 … 11.62 |
| `R` | role rate theo `type` | 0.86 … 2.60 |
| `KW` | tổng chi phí keyword (điểm ngân sách) | −1.0 … 5.5 |
| `v` | giá trị mặt cuối (`face.v`) | 1 … 12 |
| `N` | magnitude keyword trên face `debuff`/`buff` | 1 … 6 |
| `r` | rarity mặt (`face.r`) | 0 … 4 |

### F1. Scarcity → power curve

Hàm của **trường `stage`** trong `parts_full_source.json`, không của gì khác. Cho một `partKey` `k`, gọi `stages(k)` = tập stage mà `k` xuất hiện.

```
bucket(k) =
  X   nếu class(k) ∈ {dawn, dusk, mech}
  P   nếu 0 ∈ stages(k)  AND  2 ∈ stages(k)          // Prime — cả 2 dòng dõi
  O   nếu 0 ∈ stages(k)  AND  2 ∉ stages(k)          // Origin — chỉ α
  C   nếu 0 ∉ stages(k)  AND  2 ∈ stages(k)          // Classic — chỉ "+"
  (trường hợp còn lại: stages(k) = {1} — KHÔNG tồn tại trong catalog hiện tại, xem E7)

S(bucket) = { C: 1.000, O: 1.267, P: 1.600, X: 1.467 }   // HẰNG SỐ GỐC. Dùng cho §3.9d handicap
B[C]      = 2.80                                          // HẰNG SỐ GỐC. Neo vào HEROES tier-1 (F2)
B(bucket) = B[C] × S(bucket)
          = { C: 2.80, O: 3.55, P: 4.48, X: 4.11 }        // X: RESERVED, không code nào đọc (§3.4)

B_REF     = 6.00                                          // thang tham chiếu = B[C] của revision 1
KW_SCALE  = B[C] / B_REF = 0.4667                          // mọi cost F4/F5 nhân hệ số này (F4)
SIG_IMPORT_SCALE = B[C] / B_REF = 0.4667                   // giá trị signature trên die import (§3.3, F7b)
```

> **`B[C]` hạ 6.00 → 2.80 là thay đổi lớn nhất của revision 2. Lý do, tường minh:**
>
> Revision 1 neo `B[C] = 6.00` vào tầng COMMON của `FACE_POOL` (F2). Nhưng `FACE_POOL` là **drop pool giữa run** — nó được cân bằng cho `band=[0,1]` ở đầu run và `[2,4]` ở cuối, tức nó là thang *reward*, không phải thang *starting power*. Neo vào nó có nghĩa: một Axie import ở **wave 1** bắt đầu với sáu mặt ở thang COMMON-drop.
>
> Đo thực tế thang mà nó **nên** bám — `HEROES` (avg positive face value, mean trên 6 class):
>
> | | tier 1 | tier 2 | tier 3 |
> |---|---|---|---|
> | avg face value | **2.53** | **4.11** | **6.39** |
> | maxHp | **13.8** | **20.2** | **29.0** |
>
> Với `B[C] = 6.00`, bucket C cho avg face ~5.33 — tức **+111% so với hero tier-1** và gần bằng hero **tier-3**. Một Axie import mới quét vào sẽ khởi đầu mạnh gần bằng một hero đã lên hết cấp. Đó không phải "hơi yếu hơn khi part không khớp" như product owner yêu cầu; đó là ngược dấu.
>
> `B[C] = 2.80` cho: **trộn hoàn toàn 2.33 (0.92× tier-1)** · thuần Classic 2.85 (1.13×) · thuần Origin 3.61 · thuần Prime 4.55 · trần tuyệt đối 4.84 (**0.76× tier-3**). *(Nhân `SlotMod` trung bình 1.0167.)*
>
> **Hệ quả bắt buộc phải nêu: `B[C]` hạ thì cost keyword cũng phải hạ theo.** Cost F4 là **trừ tuyệt đối** khỏi ngân sách. Với `B_eff ≈ 2.80`, `aoe` (3.60) và `cleave` (3.10) *lớn hơn cả ngân sách* → mọi variant mang chúng sẽ kẹp về `v = 1` ở cả ba bucket, phá monotone và xoá sạch trục scarcity của những variant đó. Nên mọi cost F4/F5 được nhân `KW_SCALE` (F4). Điều này giữ **nguyên xi tỉ lệ** giữa mọi ô của §3.11 — đó là lý do cột thang-tham-chiếu vẫn là bằng chứng hợp lệ về hình dạng thiết kế.

**Đường cong là bậc thang, không liên tục** — vì tín hiệu đầu vào (`stage`) là hạng mục, không phải liên tục. Không có nội suy, không có "supply count" đọc từ marketplace (điều đó sẽ phá determinism và replay: nguồn cung on-chain đổi theo giờ).

Bước nhảy: C→O = **+26.7%** · O→P = **+26.3%** · C→P = **+60.0%**.

### F1c. Thang `specialGenes` (§3.4a) — NHÂN, không cộng

```
G(tier)  = 1 + SG_STEP × tier          SG_STEP = 0.071,  tier ∈ [0, 7]
G        = [1.000, 1.071, 1.142, 1.213, 1.284, 1.355, 1.426, 1.497]
G_MAX    = G(7) = 1.497
S_MAX    = max S(bucket) over buckets đi qua F1–F6 = S(P) = 1.600
                                        // X không đi qua F1–F6 (§3.4), nên S(X) KHÔNG vào S_MAX

B_acq  (k, part)          = min( B[C] × S(bucket(k)) × G(sgTier_eff(part, bucket)),  B_CAP0 )
B_run  (k, part, g)       = min( B_acq + GENE_STEP × g,  B_CAP_RUN )   // g = geneTier ∈ [0,6], §3.4c
B_final(k, part, g, coh)  = B_run × coh                                 // coh = CoherenceMod, §3.4b

SPREAD_OWN_MAX = 2.40      // ← ràng buộc TTK-legibility, KHÔNG còn là ràng buộc chống pay-to-win (F1b)
TTK_CEIL_T3    = 1.15      // ← trần power tuyệt đối, theo bội số avg face của hero tier-3

B_CAP0    = B[C] × S_MAX × G_MAX  = 2.80 × 1.600 × 1.497 = 6.7066 → 6.71   // trần của đường SỞ HỮU
GENE_STEP = 0.53                          // GIỮ NGUYÊN revision 2 — neo vào thang hero
GENE_MAX  = 6
B_CAP_RUN = TTK_CEIL_T3 × 6.39 / 1.018 = 7.219  →  7.20      // GIỮ NGUYÊN revision 2
HP_STEP   = [0, 3, 5, 8, 10, 13, 15]      // KHÔNG ĐỔI — vẫn neo vào HP hero 13.8 → 29.0
```

**`SG_BONUS = 0.28` của revision 2 bị xoá.** Nó là hằng số cộng phẳng; F1c thay bằng hệ số nhân. Bốn hệ quả:
- `B_CAP0` **không còn là knob tự do** — nó *bằng* `B[C] × S_MAX × G_MAX` theo định nghĩa (`I16`).
- **`GENE_STEP` giữ 0.53 và giữ nguyên lý do gốc của revision 2**: nó neo đường tăng trưởng trong run vào thang `HEROES` (Classic thuần ở gene 6 = 5.98 ≈ **0.95× hero tier-3**). Bản nháp trước của revision 3 đẩy nó lên 0.88 để giữ bất đẳng thức *play > money*; **bất đẳng thức đó đã bị thu hồi** (F1b), nên ràng buộc ép nó lên biến mất và nó quay về giá trị đã hiệu chuẩn.
- **`B_CAP_RUN` giữ 7.20 và đổi HOÀN TOÀN lý do tồn tại.** Ở revision 2 nó là "trần của cả run" trong một lập luận công bằng. Giờ nó là **trần TTK thuần tuý**, suy từ một câu hỏi duy nhất: *"mặt dice mạnh nhất tồn tại trong game có làm `CURVE.budget` vô nghĩa không?"* `CURVE.budget` / `mkMonster` / `mkBoss` **không đổi** và được hiệu chuẩn cho thang hero, mà hero mạnh nhất là tier-3 (avg face 6.39). Trần 7.20 ⇒ `7.33` avg face ⇒ **1.15× hero tier-3** — đúng mức mà revision 2 đã gọi là "tối đa chấp nhận được", và **không có gì trong quyết định pay-to-win làm mức đó lỏng ra**: chấp nhận người giàu mạnh hơn *không* có nghĩa là chấp nhận quái vật trở thành bao cát. `I23` kiểm `B_CAP_RUN × 1.018 ≤ TTK_CEIL_T3 × 6.39`.
- `min(…)` trong `B_acq` hầu như không bao giờ cắn. `min(…)` trong `B_run` **cắn sớm với die đắt tiền**: Prime + `agamogenesis` bắt đầu ở 6.71 và chạm 7.20 ngay ở **gene 1**.

> **Hệ quả cần biết: die đắt nhất gần như không có đường tăng power trong run** (1 bậc gene rồi kẹp). Đây **không** phải một phần thưởng chết, vì reward `GENE EXPRESSION` trả bằng **hai** thứ và chỉ một thứ bị kẹp:
> - `B_run` — **bị kẹp** ở `B_CAP_RUN`.
> - `HP_STEP[g]` — **KHÔNG bị kẹp** (`maxHp = round(HEROES.hp × coh) + HP_STEP[g]`, §3.4b). Một die đã kẹp trần vẫn nhận đủ `+3/+5/+8/+10/+13/+15` HP qua 6 bậc.
> - `rBonus` (F8) cũng không bị kẹp.
>
> Nên người mua nhiều **mua trước phần damage** và **vẫn phải chơi** để lấy phần HP. Đó là một phân công trục hợp lý sau quyết định pay-to-win, và nó giữ cho `GENE EXPRESSION` có nghĩa với mọi người chơi. Nếu playtest cho thấy nó vẫn hụt, knob đầu tiên là `TTK_CEIL_T3` (`K31`), **không** phải `GENE_STEP` — vì `GENE_STEP` đang neo vào thang hero và `TTK_CEIL_T3` mới là thứ đang ràng buộc.

### F1b. Bốn đại lượng dải, và đại lượng nào thực sự bị ghim

Thay hoàn toàn "F1a — ba trần, ba lập luận" của revision 2. Lý do thay: revision 2 đặt cạnh nhau `1.70×` (trần tiền) và `2.57×` (trần run) rồi kết luận "play > money", nhưng **hai số đó không cùng đơn vị** — một cái là tỉ số giữa hai *người chơi*, cái kia là tỉ số giữa hai *thời điểm của cùng một người chơi*. Việc đặt tên tách bạch vẫn cần, kể cả sau khi bất đẳng thức bị thu hồi (F1b-α), vì nếu không thì `SPREAD_OWN` và `SPREAD_RUN` sẽ lại bị đem so với nhau.

| Đại lượng | Công thức | Giá trị | Trả lời câu hỏi | Bị ghim? |
|---|---|---|---|---|
| **`SPREAD_OWN`** | `S_MAX × G_MAX` | **2.395×** | *Cùng trình độ, cùng gu chọn Axie — giàu hơn thì mạnh hơn bao nhiêu?* | ✅ `< SPREAD_OWN_MAX = 2.40` (`I16`, `I17`) — lý do là **TTK-legibility**, **không** phải chống pay-to-win |
| `SPREAD_STATIC` | `SPREAD_OWN / COH_MIN` = `2.395 / 0.82` | 2.921× | *Die tồn tại mạnh nhất so với die tồn tại yếu nhất, gene 0* | ❌ chỉ chẩn đoán |
| `SPREAD_RUN` | `B_CAP_RUN / B[C]` | **2.571×** | *Một con Axie lớn bao nhiêu trong một run?* | ❌ miễn — mốc tự nhiên là hero t1→t3 = **2.53×** |
| **`TTK_CEIL_T3`** | `B_CAP_RUN × 1.018 / 6.39` | **1.15×** | *Die mạnh nhất tồn tại có làm `CURVE.budget` vô nghĩa không?* | ✅ **`≤ 1.15` — đây là ràng buộc cứng DUY NHẤT còn lại** (`I23`) |

#### F1b-α. ⛔ THU HỒI — "play > money" KHÔNG còn là mục tiêu thiết kế

**Quyết định product owner, 2026-09-03**, nguyên văn: *"tôi chấp nhận việc pay to win - chúng ta không cần chống lại những người chi tiền mạnh."*

Bị thu hồi cùng lúc, **cố ý, không phải sơ suất**:

| Thứ bị thu hồi | Nó từng làm gì |
|---|---|
| Bất đẳng thức *cái chơi kiếm được > cái tiền mua được* | Lập luận công bằng trung tâm của F1a (revision 2) và của bản nháp đầu revision 3 |
| `PLAY_MARGIN_MIN = 1.20` và đại lượng `PLAY_MARGIN` | Ép `GENE_STEP` và `B_CAP_RUN` phải đủ cao để đường chơi vượt đường tiền |
| Bất biến `I14` (`P_free ≥ PLAY_MARGIN_MIN × B_CAP0`) và `I22` (`B_CAP_RUN ≥ P_free`) | Hard-fail build khi bất đẳng thức đảo dấu |
| Bảng đối chiếu "Axie A miễn phí đã chơi vs Axie B đắt nhất chưa chơi" | Bằng chứng bằng số cho bất đẳng thức |
| `GENE_STEP = 0.88`, `B_CAP_RUN = 8.40` | Hai hằng số **chỉ tồn tại** để phục vụ biên 1.20×. Quay về **0.53** và **7.20** |

> ⚠️ **GHI CHO NGƯỜI ĐỌC SAU — đừng "khôi phục" những mục trên như thể chúng là hồi quy.** Chúng bị bỏ theo một quyết định sản phẩm rõ ràng, có ngày tháng (2026-09-03), không phải bị quên. Một Axie mua đắt **được phép** mạnh hơn một Axie miễn phí đã chơi hết run; đó giờ là hành vi **đúng**. Muốn đảo lại thì phải hỏi product owner, không phải thêm lại `I14`.

**Cái giá thật của quyết định 2.4×, phát biểu thẳng** — không còn "nó ép trần run lên", vì ràng buộc đó đã biến mất:

> Ở **cùng trình độ, cùng độ thuần, cùng tiến độ run**, người chơi giàu mạnh hơn **≈2.4× trên mỗi mặt dice**. Cụ thể ở gene 0: ngân sách `6.71` so với `2.80` ⇒ avg face `6.83` so với `2.85` ⇒ **một con Axie mua đắt khởi đầu run ở mức 1.07× hero tier-3**, tức xấp xỉ sức mạnh cuối game của một hero, ngay từ wave 1. Product owner đã chấp nhận điều này một cách có ý thức để đổi lấy thang gene 8 bậc đọc được bằng số (§3.4a-1). Đó không phải một khuyết điểm chưa phát hiện.

**Cái KHÔNG bị thu hồi — ranh giới phải rõ, vì đây là chỗ dễ áp dụng quá tay nhất:**
- **Chống gian lận nguyên vẹn, vẫn BLOCKING.** Replay phía server tồn tại để chặn điểm số **bịa ra**, không phải để chặn việc chi tiền. `AC-1` (purity + determinism của `axieToDie`) **vẫn BLOCKING**, vì dựng lại die phía server phụ thuộc đúng vào tính pure đó. Chấp nhận pay-to-win nghĩa là *một người giàu có thể mạnh hơn một cách hợp lệ*; nó **không** nghĩa là ai cũng được nộp một điểm số họ chưa từng chơi.
- **Mô hình ngân sách và ngang giá nguyên vẹn.** R1, R6, R7, R8, monotone-distinct (F6), dải ±12%/±20%, REPAIR/SPREAD — **không cái nào là bộ máy chống-whale**. Chúng phục vụ tính đọc được của cân bằng và khả năng bảo trì. Product owner đồng thời yêu cầu **siết chặt hơn** kỷ luật cân bằng ở phía relic, nên quyết định này **không** là giấy phép nới công thức.
- **`TTK_CEIL_T3 = 1.15` nguyên vẹn.** Người giàu được mạnh hơn người nghèo; quái vật **không** được biến thành bao cát. Đây là ràng buộc cứng duy nhất còn lại trên trục power.

**`SPREAD_OWN` theo từng bậc gene** — vẫn *thu hẹp* theo tiến độ run (balancing loop giữ nguyên, và nó gấp hơn trước):

| geneTier `g` | đắt nhất `min(6.71 + 0.53g, 7.20)` | rẻ nhất `min(2.80 + 0.53g, 7.20)` | `SPREAD_OWN(g)` |
|---|---|---|---|
| 0 | 6.71 | 2.80 | **2.396×** ← đỉnh |
| 1 | 7.20 *(kẹp)* | 3.33 | 2.162× |
| 2 | 7.20 | 3.86 | 1.865× |
| 3 | 7.20 | 4.39 | 1.640× |
| 4 | 7.20 | 4.92 | 1.463× |
| 5 | 7.20 | 5.45 | 1.321× |
| 6 | 7.20 | 5.98 | **1.204×** |

`I17` assert `max(SPREAD_OWN(g)) < SPREAD_OWN_MAX` trên cả 7 bậc; đỉnh ở `g = 0` bằng đúng `S_MAX × G_MAX`, nên `I16` và `I17` phải nhất quán với nhau.

**Đây giờ chỉ là một quan sát, không còn là lập luận công bằng.** Khoảng cách thu hẹp từ 2.40× xuống 1.20× qua một run — nhưng nó thu hẹp vì `B_CAP_RUN` là một **trần TTK phẳng** mà người giàu chạm sớm, chứ không vì thiết kế đang cố cân bằng ai với ai. Ghi lại vì nó vẫn hữu ích cho việc đọc TTK theo wave (AC-28), không vì nó chứng minh điều gì về công bằng.

**Hệ quả phụ**: từ gene 1 trở đi, part Prime + gene cao chạm `B_CAP_RUN` nên **thang gene trở nên vô hình về số trên nhóm đó** (cả `normal` lẫn `agamogenesis` đều 7.20 sau khi kẹp). Bù lại bằng hai trục **không bị kẹp**: `rBonus` (F8 — nhãn rarity) và `HP_STEP` (§3.4c — máu). Xem ghi chú ở F1c.

#### F1b-bis. Rủi ro combat — ĐÃ TỰ GIẢI khi bất đẳng thức bị thu hồi

Bản nháp trước của revision 3 phải đẩy `B_CAP_RUN` lên **8.40** để giữ biên 1.20×, và điều đó đưa die mạnh nhất lên **1.34× hero tier-3**, phá dải `[0.70, 1.10]` của `AC-27`. Tôi đã nêu nó như một rủi ro cần product owner quyết, kèm ba phương án.

**Việc thu hồi biên (F1b-α) làm rủi ro đó biến mất.** `B_CAP_RUN` quay về **7.20** ⇒ **1.15× hero tier-3** — đúng mức revision 2 đã chấp nhận. Không cần trim `S_MAX`, không cần nới AC-27 lên 1.35, không cần re-sim toàn bộ. Ba phương án A/B/C **rút khỏi bàn**.

**Đối chiếu với thang hero, số cuối cùng:**

| Nhóm | ngân sách cuối run | avg face | so hero t3 (6.39) | Dải AC-27 |
|---|---|---|---|---|
| Classic trộn (coh 0.82), gene 6 | 4.90 | 4.99 | 0.78× | ✅ |
| Classic thuần, gene 6 | 5.98 | 6.09 | **0.95×** | ✅ trong `[0.70, 1.10]` |
| Origin thuần, gene 6 | 7.20 *(kẹp)* | 7.33 | 1.15× | ⚠️ chạm trần |
| Prime + `agamogenesis`, gene ≥1 | 7.20 *(kẹp)* | 7.33 | **1.15×** | ⚠️ chạm trần |

Còn đúng **một** chỗ lệch, và nó cần sửa AC chứ không cần đổi hằng số: nhóm max-scarcity ngồi ở 1.15×, trên trần 1.10 của dải cũ. ⇒ **`AC-27` TÁCH LÀM HAI NHÓM** thay vì nới một dải chung (§8):

- nhóm **điển hình** (mọi part bucket C — 174/285 part rơi vào đây): giữ `[0.70, 1.10]`;
- nhóm **max-scarcity** (mọi part bucket P + gene tier 7): `[0.70, 1.18]`.

Tách đúng hơn nới, vì nó giữ được khả năng phát hiện hồi quy ở nhóm phổ biến nhất, đồng thời thừa nhận rằng nhóm max-scarcity **được phép** chạm trần TTK — đó chính là điều `TTK_CEIL_T3` cho phép và `SPREAD_OWN_MAX` giới hạn.

**Giảm thiểu cấu trúc vẫn nguyên và vẫn thật**: `B_CAP_RUN` kẹp `B_run` nhưng **không** kẹp `HP_STEP`. Một die max-scarcity đánh mạnh hơn hero t3 15% nhưng chỉ đạt HP ngang hero t3 sau khi đã chơi hết 6 bậc gene. Lệch bị giới hạn ở *"giết nhanh hơn"*, không phải *"không giết được"* — loại lệch mà `CURVE.budget` chịu tốt hơn nhiều, và là lý do AC-28 khoản (b) đo TTK **hai phía** chứ không đo winrate.

#### ~~F1a. Ba trần, ba lập luận công bằng khác nhau~~ — **SUPERSEDED bởi F1b (revision 3)**

Revision 2 đặt cạnh nhau `B_CAP0 = 1.70×` và `B_CAP_RUN = 2.57×` rồi kết luận *"play > money"*. Kết luận **đúng**, nhưng đường đi tới nó **sai đơn vị**: `1.70×` là tỉ số giữa **hai người chơi khác nhau**, còn `2.57×` là tỉ số giữa **hai thời điểm của cùng một người chơi**. So hai tỉ số khác mẫu số rồi kết luận về công bằng là đúng loại lỗi mà E15c đã bắt được một lần (so hai hệ số nhân mà quên rằng nền cũng dịch).

F1b sửa theo hai bước: (a) so bằng **ngân sách tuyệt đối** (`5.98 > 5.11`) thay vì so hai tỉ số; (b) đặt **tên riêng** cho ba tỉ số (`SPREAD_OWN` / `SPREAD_STATIC` / `SPREAD_RUN`) để không ai trộn lại chúng, và để R2 ghim được đúng một cái.

Số trong bảng cũ đã lỗi thời ở đúng một ô: `B_CAP0` **4.76 → 5.11** (F1c). `COH_MIN = 0.82` và `B_CAP_RUN = 7.20` **không đổi**. Đọc F1b.

### F2. Ngân sách hiệu dụng + slot modifier

```
B_eff(k, part, slot) = B_final(k, part) × SlotMod[slot]

SlotMod = { mouth: 1.00,  horn: 1.10,  back: 1.05,
            tail:  0.95,  eyes: 1.00,  ears: 1.00 }
```

**Hiệu chuẩn — hai profile, và lời tuyên bố đã được hạ cấp cho đúng sự thật (defect 11 của review).**

Revision 1 tuyên bố *"6/6 khớp — bằng chứng công thức neo vào dữ liệu thật"*. Hai vấn đề đã verify:

1. **Hàng `Gill` không hợp lệ làm neo.** Nó tính `(6.0×1.00 − 1.5)/2.25 = 2.00 → 2` bằng cách **bỏ qua** `TYPE_COST[aqua][mana] = 1.20` mà chính F5 bắt buộc. Tính đủ: `(6.00 − 1.20 − 1.50)/2.25 = 1.467 → 1`, không phải 2. Và sâu hơn: **`Gill` là Signature** (#5), nên theo §3.3 nó **được miễn F1–F6** — một face miễn công thức không thể dùng để hiệu chuẩn hằng số của công thức. Hàng này là lập luận vòng.
2. **Hàng `horn` và `back` ràng buộc rất yếu.** `horn dmg 7` chỉ đòi `round(6.0 × SlotMod) = 7`, tức `SlotMod[horn] ∈ [1.0833, 1.25)` — **bất kỳ** giá trị nào trong dải đó cũng "khớp"; 1.10 không được suy ra, nó chỉ không bị loại. Tương tự `back shield 7` cho `SlotMod[back] ∈ [0.9317, 1.075)`.

**Profile THAM CHIẾU (`B_REF = 6.00`)** — dùng để reproduce cột số §3.11. Ba neo chặt, hai neo lỏng, một neo bị loại:

| `FACE_POOL` r0 | Công thức, `B = 6.00` | Trạng thái neo |
|---|---|---|
| `mouth dmg 6` (Zigzag) | `6.00 × 1.00 / 1.00 = 6.00` → 6 | ✓ **chặt** — `SlotMod[mouth] = 1.00` là định nghĩa (đơn vị neo) |
| `eyes heal 6` (Blossom) | `6.00 × 1.00 / 1.00 = 6.00` → 6 | ✓ **chặt** — xác nhận `R[heal] = R[dmg]` |
| `tail poison 4` (Grass Snake) | `6.00 × 0.95 / 1.55 = 3.68` → 4 | ✓ **chặt** — `SlotMod[tail] × R[poison]` bị ghim trong dải hẹp |
| `horn dmg 7` (Incisor) | `6.00 × 1.10 / 1.00 = 6.60` → 7 | 🟡 **lỏng** — mọi `SlotMod[horn] ∈ [1.083, 1.25)` đều khớp |
| `back shield 7` (Snail Shell) | `6.00 × 1.05 / 0.86 = 7.33` → 7 | 🟡 **lỏng** — mọi `SlotMod[back] ∈ [0.932, 1.075)` đều khớp |
| ~~`ears mana 2 cantrip` (Gill)~~ | ~~`(6.00 − 1.50)/2.25 = 2.00`~~ | ❌ **LOẠI** — bỏ `TYPE_COST[aqua][mana]`; và là Signature nên miễn công thức |

Neo thay thế cho `ears`, **hợp lệ vì nó không phải signature và tính đủ type cost** — `HEROES.aqua1` có `F('ears','mana',1,'cantrip')` (`src/data.js:72`):

```
profile production:  (2.80 × 1.00 − 0.56 − 0.70) / 2.25 = 0.684 → max(1, ·) = 1   ✓ khớp aqua1
                      (TYPE_COST[aqua][mana] = 1.20 × 0.4667 = 0.56 · cantrip = 1.50 × 0.4667 = 0.70)
```

**Profile PRODUCTION (`B[C] = 2.80`)** — neo vào `HEROES` tier-1, và tuyên bố được phát biểu **đúng mức**:

Ngân sách hàm ý của 6 mặt `HEROES.beast1` (Cub), tính bằng `B_hàm_ý = (v·R + KW·KW_SCALE + TYPE_COST·KW_SCALE)/SlotMod`:

| face của Cub | `B_hàm_ý` |
|---|---|
| `horn dmg 5 heavy` | `(5 − 0.187)/1.10` = **4.38** |
| `horn dmg 3` | `3/1.10` = **2.73** |
| `mouth dmg 3` | **3.00** |
| `mouth dmg 2 growth` | `(2 + 0.70)/1.00` = **2.70** |
| `back shield 2` | `2×0.86/1.05` = **1.64** |
| `mouth dmg 2` | **2.00** |
| | **mean 2.74 · median 2.72** |

`B[C] = 2.80` nằm trong khoảng đó, và nó cũng khớp cơ sở độc lập thứ hai (avg positive face value của 6 hero tier-1 = **2.53**). **Lời tuyên bố đúng là**: *`B[C] = 2.80` **nhất quán với** thang `HEROES` tier-1 theo hai phép đo độc lập (2.53 và 2.74), và nằm trong dải phân tán của chính một viên dice hero.* **Không** phải: "công thức reproduce hero tier-1".

Nó **không thể** reproduce, và điều đó không phải khuyết điểm của công thức: một viên dice hero tier-1 có ngân sách hàm ý trải từ **1.64 đến 4.38** — dải 2.7×, *bên trong một viên dice*. `HEROES` được hand-author, cố ý không đồng giá (mặt `heavy` mạnh là mặt "signature" của Cub). Công thức F1–F6 tồn tại để bảo đảm **158 variant ngang giá với nhau**, không để mô phỏng lại sự bất đối xứng có chủ ý của hero.

`SlotMod` **không đổi** giữa hai profile:
```
SlotMod = { mouth: 1.00,  horn: 1.10,  back: 1.05,  tail: 0.95,  eyes: 1.00,  ears: 1.00 }
```
Nó không được hiệu chuẩn lại, vì hai neo lỏng ở trên không cung cấp thêm thông tin để hiệu chuẩn. `K7` vì vậy **hạ từ "đừng chạm" xuống "chạm được trong ±0.10, nhưng phải chạy lại AC-7"** (§7) — trung thực hơn là gọi nó là hiệu chuẩn cứng.

### F3. Role rate

```
R = { dmg: 1.00,  heal: 1.00,  shield: 0.86,  poison: 1.55,
      mana: 2.25,  buff: 2.60,  debuff: 2.60,  summon: 4.20 }
```

Lý do mỗi con số:

| type | R | Lý do |
|---|---|---|
| `dmg` | 1.00 | Đơn vị neo. Mọi thứ khác quy về đây |
| `heal` | 1.00 | Ngang `dmg` vì heal bị chặn trần bởi HP thiếu — trung bình mất hiệu quả bù cho việc không bị shield chặn |
| `shield` | 0.86 | Shield **rẻ hơn** dmg: nó chặn 1:1 nhưng có trần `maxHp×2` (`engine.js:352`) và không tồn tại nếu không bị đánh |
| `poison` | 1.55 | Poison `v` gây tổng `v(v+1)/2` damage (stack giảm 1/lượt, `:620`) → **bậc hai**. Engine tự xác nhận: `faceScale()` dùng `pow(s, 0.50)` cho poison (`:107`) |
| `mana` | 2.25 | 1 mana ≈ 2.25 điểm ngân sách. Thô nhưng đúng — xem ghi chú aqua·ears §3.11 |
| `buff`/`debuff` | 2.60 | Face này có `v=0`; toàn bộ ngân sách chuyển thành magnitude keyword. Engine xác nhận rate nén: `faceScale()` dùng `pow(s, 0.45)` cho buff/debuff (`:107`) |
| `summon` | 4.20 | Chỉ dùng ở signature legacy (Mavis/Robin/Neo). **Không** dùng ở variant nào — summon có trần 4 token (`:507`) làm nó phi tuyến khó định giá |

### F4. Keyword cost — mọi keyword doc này dùng

```
KW(face) = Σ over k ∈ face.k  of  cost(k) + Σ CLS_SURCHARGE[class][k]
```

| keyword | cost | Dạng | Ghi chú |
|---|---|---|---|
| `heavy` | **−0.40** | phẳng | **Drawback** (chặn reroll) → hoàn ngân sách |
| `decay` | **−0.80** | phẳng | Drawback. Không dùng ở variant nào |
| `selfharm:N` | **−0.25 × N** | tuyến tính | Drawback |
| `crit:N` | **0.045 × N** | tuyến tính | `crit:30` = 1.35 |
| `regen:N` | **0.50 × N** | tuyến tính | Giảm 1/lượt → tổng `N(N+1)/2` nhưng chỉ heal |
| `weaken:N` | **0.60 × N** | tuyến tính | Giảm 1/lượt |
| `poison:N` | **0.70 × N** | tuyến tính | Rider trên face non-poison |
| `thorns:N` | **0.70 × N** | tuyến tính | **KHÔNG bao giờ giảm** (E10) → đắt hơn regen dù cùng dạng |
| `vulnerable:N` | **0.75 × N** | tuyến tính | Nhân dmg toàn party ×1.5 |
| `blind:N` | **0.90 × N** | tuyến tính | Vô hiệu hoá hoàn toàn 1 face dmg |
| `vital` | **1.00** | phẳng | ×2 nhưng có điều kiện HP đầy |
| `burn:N` | **0.55 × N** | tuyến tính | Halve mỗi lượt (`:629`) → tổng ≈ 2N |
| `mana:N` | **1.10 × N** | tuyến tính | Rider |
| `rerollup` | **1.40** | phẳng | +1 reroll, một lần |
| `chain:N` | **1.40 × (N−1)** | tuyến tính | Chiết khấu vì target **ngẫu nhiên** (E6) |
| `cantrip` | **1.50** | phẳng | Không mất lượt |
| `lifesteal` | **1.50** | phẳng | |
| **`growth`** | **1.50** | phẳng | 🆕 **THIẾU trong revision 1** (defect 3 của review). `u.growth[fi] += 1` mỗi lần dùng, **cộng vĩnh viễn trong trận** — mặt càng roll càng to. Suy ngược từ 4 variant + 3 signature: xem ghi chú dưới |
| `multi:N` | **1.60 × (N−1)** | tuyến tính | Đắt hơn `chain` vì chọn được target |
| `exec` | **2.00** | phẳng | |
| `pierce` | **2.30** | phẳng | |
| `freeze` | **2.60** | phẳng | Chỉ secret-class (Fulu) |
| `undying` | **2.80** | phẳng | Không dùng ở variant nào |
| `cleave` | **3.10** | phẳng | |
| `stun` | **3.40** | phẳng | Không dùng ở variant nào |
| `aoe` | **3.60** | phẳng, **có biến thể** | Trên face `v>0`: cost phẳng 3.60. Trên face `v=0` (`buff`/`debuff`): **không** trừ phẳng, mà **nhân kwBudget × `AOE_KWB` = 0.55** (F5b) |
| `echo` `plague` `bastion` `overflow` | **không định giá** | — | Rule-break. Chỉ ở signature r4. Miễn kiểm ngân sách (F7) |

> **`cost(growth) = 1.50` được suy ngược, không đoán** (defect 3 của review). F4 của revision 1 mang tiêu đề *"mọi keyword doc này dùng"* nhưng **không định giá `growth`**, dù `growth` xuất hiện trên 4 variant (`beast.mouth.C`, `plant.mouth.D`, `plant.ears.D`, `bug.ears.E`) và 3 signature (`Confident`, `Axie Kiss`, `Buddy Chorus`). Nghĩa là generator không thể tính được 12 ô — nó sẽ đọc `cost('growth')` là `undefined`, và `undefined` trong biểu thức số học của JS cho **`NaN`**, làm cả 12 ô thành `NaN` (chính xác là loại lỗi mà `tools/t_import.mjs` :48-50 tồn tại để bắt).
>
> Giải nghịch từ dữ liệu đã có trong doc, ở thang tham chiếu:
>
> | Face | Ràng buộc | Suy ra `cost(growth)` |
> |---|---|---|
> | `beast.mouth.C` = `dmg · growth` = 5/6/8 | `round(6.00 − c) = 5` ∧ `round(7.60 − c) = 6` ∧ `round(9.60 − c) = 8` | `c ∈ (1.10, 1.50]` |
> | `plant.mouth.D` = `dmg · growth` = 5/6/8 | (giống trên) | `c ∈ (1.10, 1.50]` |
> | `plant.ears.D` = `mana · cantrip · growth` = 1/2/3 | `round((6.00 − 1.50 − c)/2.25) = 1` ∧ `… = 2` ∧ `… = 3` | `c ∈ [1.35, 1.62)` |
> | `bug.ears.E` = `mana · cantrip · growth` = 1/2/3 | (giống trên) | `c ∈ [1.35, 1.62)` |
>
> Giao của bốn ràng buộc: **`c ∈ [1.35, 1.50]`**. Chọn **1.50** — cận trên, và nó **reproduce cả 12 ô trên cả 3 bucket**. Kiểm hai ô biên: `plant.ears.D`@C = `(6.00 − 1.50 − 1.50)/2.25 = 1.333 → 1` ✓ · @P = `(9.60 − 1.50 − 1.50)/2.25 = 2.933 → 3` ✓.
>
> **Vì sao 1.50 là giá đúng về mặt thiết kế, không chỉ về mặt khớp số**: `growth` ngang giá `cantrip` và `lifesteal`. Nó yếu hơn cả hai ở lượt đầu (cộng 0) nhưng vượt cả hai từ lượt 3-4 trở đi và **không có trần** — nên giá của nó là giá của một keyword mạnh-nhưng-chậm. Nó cũng là lý do `decay` (`−0.80`) không phải `−1.50`: mất 1 điểm/lượt trên một mặt bạn *không* muốn roll thì rẻ hơn là được 1 điểm/lượt trên mặt bạn *muốn* roll.

**Mọi cost trong bảng F4 và F5 là giá ở THANG THAM CHIẾU (`B_REF = 6.00`).** Giá production = `cost × KW_SCALE` (= `× 0.4667`, F1). Generator nhân hệ số này một lần, ở một chỗ — bảng này **không** được viết lại theo thang production, vì (a) nó sẽ mất tính đọc-được (mọi số thành lẻ), và (b) tỉ lệ giữa các keyword là *thiết kế*, còn thang là *tuning*. Đổi `B[C]` không được phép làm ai phải sửa bảng F4.

### F5. Class surcharge — giá của việc cộng dồn với passive

Passive class nhân giá trị của một số keyword. Không tính surcharge = mọi build mono-class dồn vào đúng keyword đó.

```
CLS_SURCHARGE[class][keyword] hoặc [class][type]
```

| class | passive | Surcharge | Vì sao |
|---|---|---|---|
| beast | FERAL (+60% vs <50% HP) | `exec` **+0.80** | `exec` (×1.6) và FERAL (×1.6) dùng **cùng một ngưỡng HP** → nhân nhau thành ×2.56 |
| bird | TALON (pierce +3; `aoe` cũng có pierce) | `pierce` **+0.90** · `aoe` **+1.40** | `engine.js:466` tự cấp Pierce cho **mọi** face `aoe` của Bird → `aoe` ở Bird = `aoe` + `pierce` miễn phí |
| aqua | CONDUIT (mana +1; 4 mana → 1 reroll) | `mana:N` **+0.45 × N** · `TYPE_COST[aqua][mana]` = **1.20** | CONDUIT cộng +1 phẳng cho mọi mana nhận được (`applyMana`) |
| plant | BULWARK (mọi Shield +2) | `TYPE_COST[plant][shield]` = **1.70** | `applyShield` cộng +2 vô điều kiện cho Plant (`:374-379`), và ≥10 shield tự cấp Thorns 2 (`:379`) |
| bug | VIRULENT (poison stack +2) | `poison:N` **+0.50** (phẳng, không theo N) · `TYPE_COST[bug][poison]` = **0.90** | Stack thứ 2 trở đi mạnh gấp đôi (`addStatus` :386) |
| reptile | SCALES (Thorns 2 nền; Thorns cũng áp Poison 1) | `thorns:N` **+0.60** (phẳng) | Mỗi lần thorns kích hoạt = thorns **+ poison 1** (`dealDamage` :337-345) |

#### F5a. Quy ước dấu — SỬA LỖI DOUBLE-NEGATION của revision 1 (defect 4 của review)

Revision 1 ghi surcharge type là số **âm** (`type mana −1.20`, `shield −1.70`, `poison −0.90`) và ghi chú *"trừ thẳng khỏi `B_eff`"*, nhưng F5b lại viết công thức là `B_eff − TYPE_SURCHARGE`. Đọc đúng nghĩa từng chữ thì `B_eff − (−1.20) = B_eff + 1.20` — **tăng** ngân sách cho đúng những class mà passive đang làm keyword đó *rẻ hơn*, tức ngược dấu.

Đã xác nhận ý định đúng là **trừ một chi phí dương**, bằng cách kiểm ô đã tabled: `aqua.ears.A` = `mana · cantrip` = 1/2/3.
- Trừ chi phí dương (**đúng**): `(6.00 − 1.20 − 1.50)/2.25 = 1.467 → 1` ✓ khớp bảng
- Đọc theo nghĩa từng chữ (sai): `(6.00 + 1.20 − 1.50)/2.25 = 2.533 → 3` ✗ lệch 2 bậc

**Quy ước từ revision 2 trở đi — một dấu, một tên, không có ngoại lệ:**

```
TYPE_COST[class][type]   ≥ 0   ALWAYS.  Lưu dạng DƯƠNG.  Công thức TRỪ nó.
CLS_SURCHARGE[class][kw] ≥ 0   ALWAYS.  Lưu dạng DƯƠNG.  Cộng vào KW (KW cũng bị TRỪ).

TYPE_COST = { aqua:{mana:1.20},  plant:{shield:1.70},  bug:{poison:0.90} }
            // beast, bird, reptile: không có type cost — passive của chúng
            // nhân giá trị KEYWORD, không nhân giá trị TYPE
```

Tên cũng đổi: `TYPE_SURCHARGE` → **`TYPE_COST`**. Từ *"surcharge"* mang nghĩa "phụ phí cộng thêm" nên nó *mời gọi* việc lưu số âm rồi cộng; *"cost"* thì chỉ có một cách đọc. Đây là đúng loại lỗi mà tên biến gây ra và tên biến sửa được.

Cả hai loại đều làm `v` **thấp hơn**, và cả hai đều có cùng lý do: passive class đang cho không một phần giá trị, nên face phải trả lại phần đó bằng ngân sách. Khác biệt duy nhất là **chỗ áp**: `TYPE_COST` trừ khỏi `B_eff` (nên nó bị chia bởi `R` cùng với ngân sách), `CLS_SURCHARGE` cộng vào `KW` (nên nó cũng bị chia bởi `R`). Về đại số hai chỗ tương đương; tách ra vì `TYPE_COST` phụ thuộc `(class, type)` còn `CLS_SURCHARGE` phụ thuộc `(class, keyword)` — hai bảng tra khác nhau.

### F5b. Công thức chính

**Face có giá trị** (`dmg` `shield` `heal` `poison` `mana` `summon`):

```
v_raw = ( B_eff − TYPE_COST[class][type] − KW ) / R[type]        // TYPE_COST ≥ 0, xem F5a
v     = max( 1, Math.round(v_raw) )

KW    = Σ over k ∈ face.k of ( cost(k) + flatSurcharge(class, k) ) × KW_SCALE
```

**Face không giá trị** (`buff` `debuff`, `v = 0`):

```
kwBudget = ( B_eff − TYPE_COST[class][type] ) / R[type]          // R = 2.60
if face has `aoe`:  kwBudget = kwBudget × AOE_KWB                // AOE_KWB = 0.55
N = max( 1, Math.floor( (kwBudget − flatRiderCosts) / perStackCost ) )

flatRiderCosts = Σ over k ∈ face.k, k ≠ 'aoe', of
                   ( flatCost(k) + CLS_SURCHARGE[class][k] ) × KW_SCALE / R[type]
perStackCost   = ( perStackCost(kScaling) + CLS_SURCHARGE[class][kScaling] ) × KW_SCALE / R[type]
```

**LUẬT `aoe` TRÊN FACE `v = 0` — nêu tường minh, vì revision 1 áp nó ngầm (defect 5 của review):**

> Trên face `v = 0` (`buff`/`debuff`), `aoe` đi **đường nhân** (`AOE_KWB`) và **KHÔNG** đi đường cộng-chi-phí. Nên `CLS_SURCHARGE[class]['aoe']` **KHÔNG được áp** — nó đã nằm trong hệ số nhân. Mọi surcharge phẳng theo keyword **khác** thì **CÓ** áp, qua `flatRiderCosts`.

Đây không phải quy ước tôi phát minh: nó là quy ước mà **bảng §3.11 đã tuân theo**, chỉ chưa ai viết ra. Hai ô chứng minh, và chúng ràng buộc theo **hai chiều ngược nhau** — nên luật này là điều duy nhất làm cả hai ô cùng đúng:

| Ô | Nếu ÁP `CLS_SURCHARGE['aoe']` | Nếu KHÔNG áp | Bảng §3.11 ghi |
|---|---|---|---|
| `bird.eyes.D` = `debuff · vulnerable:N · aoe` (bird `aoe` +1.40) | @C `floor((1.269 − 1.40)/0.75)` → clamp **1** · @O → clamp **1** · @P **1** | @C **1** · @O **2** · @P 2→**3** (F6) | **1 / 2 / 3** ← khớp cột phải |
| `bug.eyes.C` = `debuff · poison:N` (bug `poison:N` +0.50 phẳng) | @C `floor((2.308 − 0.50)/0.70)` = **2** · @O **3** · @P **4** | @C `floor(2.308/0.70)` = **3** · @O 4 · @P 5 | **2 / 3 / 4** ← khớp cột trái |

`bird.eyes.D` chỉ đúng khi `aoe` surcharge **bị bỏ**; `bug.eyes.C` chỉ đúng khi `poison:N` surcharge **được áp**. Hai ô đó ở hai family khác nhau nên revision 1 không bao giờ phải đối mặt với mâu thuẫn — nhưng một người viết generator sẽ phải chọn một, và **cả hai lựa chọn đều làm sai 4 ô** nếu không có luật này.

**Vì sao luật này đúng về mặt thiết kế, không chỉ về mặt khớp số**: `AOE_KWB = 0.55` nghĩa là "aoe lấy 45% ngân sách keyword". Với Bird, TALON cấp Pierce miễn phí cho mọi face `aoe` (`dealDamage` :318 + `doFace` :491) nên `aoe` ở Bird đáng giá gấp đôi — nhưng **chỉ trên face gây damage**. Trên một face `debuff` `v = 0` thì **không có damage nào để pierce**: `f.t === 'debuff'` đi nhánh `:515-517`, gọi thẳng `addStatus`, không bao giờ gọi `dealDamage`. Nên TALON **không có hiệu lực nào** trên `bird.eyes.D`, và thu phí nó là thu phí cho một lợi ích không tồn tại. Luật này *đúng vì engine*, không phải vì bảng.

Hệ quả: `CLS_SURCHARGE[bird]['aoe']` (`K13`) chỉ ảnh hưởng face `v > 0`. Face `debuff · aoe` của Bird (`bird.eyes.D`, `bird.back.C` khi có `aoe`) miễn nhiễm với knob đó — ghi vào §7 K13.

**Kiểm biên bắt buộc** (generator, BLOCKING): nếu `kwBudget − flatRiderCosts ≤ 0` thì `N` bị kẹp về 1 bởi `max(1, ·)`. Đó **không** phải lỗi, nhưng nó âm thầm phá quan hệ ngân sách, nên generator phải **log** mọi ô bị kẹp (`CLAMP_FLOOR`) và AC-7d kiểm số ô bị kẹp khớp snapshot. Ở thang production (`B[C] = 2.80`) số ô bị kẹp **nhiều hơn hẳn** thang tham chiếu — đó là hệ quả đã biết và đã chấp nhận của F1, không phải hồi quy.

### F6. Monotone-distinct enforcement (BẮT BUỘC)

Sau khi tính `v` (hoặc `N`) cho cả 4 bucket của cùng một variant, **bắt buộc** áp:

```
out[C] = max( 1,          round(raw[C]) )
out[O] = max( out[C] + 1, round(raw[O]) )
out[P] = max( out[O] + 1, round(raw[P]) )
// KHÔNG có nhánh out[X] — bucket X không bao giờ đi qua F1–F6 (§3.4, defect 12)
```

**Viết lại thành CẤU TRÚC, không phải pass sửa chữa** (defect 6 của review). Về đại số nó tương đương vòng lặp của revision 1, nhưng ba khác biệt quan trọng:

1. **Không còn "pass" nào để chạy sai thứ tự.** `out[O]` không thể tồn tại ở giá trị vi phạm monotone, kể cả trong một trạng thái trung gian. Monotone là **bất biến của biểu thức**, không phải hậu điều kiện của một thủ tục.
2. **Không còn nhánh `out[X]`.** Revision 1 kẹp `out[X]` vào `[out[O], out[P]]` — assert trên **tập rỗng**, vì cả 18 part bucket X đều là signature (§3.10 quy tắc 2) nên không variant nào từng được tính ở bucket X. `AC-14` bỏ khoản `v(O) <= v(X) <= v(P)` theo cùng lý do.
3. **Danh sách ô bị can thiệp do generator in ra, không do doc duy trì** — xem dưới.

**Bảng danh sách monotone-lift đã bị XOÁ khỏi doc.** Revision 1 liệt kê 10 variant bằng tay. Review kiểm được 3 sai:

| Variant | Revision 1 nói | Sự thật (thang tham chiếu) |
|---|---|---|
| `aqua.ears.B` = `mana` | *cần* enforcement | **KHÔNG cần.** `(6.00−1.20)/2.25 = 2.13 → 2` · `(7.60−1.20)/2.25 = 2.84 → 3` · `(9.60−1.20)/2.25 = 3.73 → 4` — tự nhiên đã 2/3/4, tăng nghiêm ngặt |
| `aqua.ears.C` = `mana · cantrip · rerollup` | không nhắc | **CẦN.** `1.90/2.25 = 0.84 → 1` · `3.50/2.25 = 1.56 → 2` · `5.50/2.25 = 2.44 → 2` — @P **bằng** @O, phải lift lên 3 |
| `bird.eyes.A` = `debuff · vulnerable:N` | không nhắc | **CẦN, hai lần.** `floor(2.308/0.75) = 3` · `floor(2.923/0.75) = 3` (bằng @C → lift 4) · `floor(3.692/0.75) = 4` (bằng @O đã lift → lift 5) |

Nghĩa là danh sách sai **3/10 mục theo cả hai chiều** — một mục dương tính giả, hai mục âm tính giả. Âm tính giả nguy hiểm hơn: một người viết test theo danh sách đó sẽ assert `bird.eyes.A` *không* bị lift, và test đó sẽ đổ vào một generator **đúng**.

Nên danh sách này không còn nằm trong doc. `tools/gen_faces.mjs` in ra `monotoneLifts[]` vào snapshot (§6f), và AC-7d kiểm snapshot. Ở thang production tập này **sẽ khác và sẽ lớn hơn nhiều** — `ΔB(C→O) = 0.75` và `ΔB(O→P) = 0.93` điểm ngân sách, nên với `R[dmg] = 1.00` các bucket cách nhau ~1 điểm mặt và làm tròn thường xuyên gây hoà. Đó là hệ quả đã biết của F1, và nó có một mặt tốt cần nêu:

> **Ở thang production, `Origin = Classic + 1` và `Prime = Classic + 2` gần như luôn đúng.** Đó là một luật người chơi **đọc được** — "part α mạnh hơn một điểm, part Prime mạnh hơn hai điểm, trên đúng cùng kỹ năng đó". Revision 1 ở thang 6.0 cho bước nhảy 1–2 điểm không đều nên không phát biểu được luật nào. Việc monotone construction chi phối kết quả không phải khuyết điểm — nó là chỗ công thức và tính legible trùng nhau. `ux-designer` nên dùng đúng câu đó trong tooltip.

**Slack ngân sách**: lift được vượt ngân sách tối đa **+1 đơn vị** `v`/`N` mỗi bậc. Ở thang tham chiếu (`v` tới 12) đó là ≤12%, nằm trong dải AC-7. Ở thang production (`v` tới 6) một lift +1 có thể là +30% ngân sách của ô đó — nên **AC-7 không áp dải % ở thang production**; nó áp "khớp snapshot" (AC-7d). Dải ±12% chỉ còn hiệu lực ở thang tham chiếu, nơi độ phân giải đủ để nó có nghĩa. Đây là điều chỉnh bắt buộc, không phải nới lỏng: một dải % ở độ phân giải `v ∈ [1,6]` không phát hiện được gì mà nó không cho phép.

**Vì sao bắt buộc**: `Math.round` có thể làm hai bucket khác nhau ra cùng số (ví dụ `beast.ears.C`: `6.00/2.25 = 2.67 → 3` và `7.60/2.25 = 3.38 → 3`). Nếu variant đó có một part bucket C **và** một part bucket O, hai part đó ra **face y hệt** → phá AC-4. Monotone enforcement là thứ đóng lỗ hổng này, và nó là lý do một số con số trong §3.11 lệch nhẹ khỏi F5b thuần.

*(Bảng liệt kê 10 variant bị enforcement của revision 1 đã bị xoá tại đây — xem lý do ở trên. Nguồn sự thật mới: `monotoneLifts[]` trong `assets/data/part_faces.json`.)*

### F7. Signature power allowance

Signature face **không** dùng F1–F6. Chúng dùng ngân sách theo **rarity tier**:

```
SIG_BUDGET = { 0: 6.0,  1: 8.5,  2: 12.0,  3: 17.0,  4: MIỄN KIỂM }
```

> **Đây chính là `TIER_BUDGET` của `part-tier-system.md` §2b, không sửa một số nào** (`common 6.0 · rare 8.5 · epic 12.0 · legendary 17.0`). Nó được suy lại độc lập trong phiên này bằng cách lấy **trung vị ngân sách hàm ý** của 50 face `FACE_NAMES` theo từng tier, và ra đúng bốn con số cũ. Hai đường phân tích khác nhau ra cùng kết quả → đây là kiểm chứng độc lập, không phải copy.

Quan hệ hai trục, phát biểu tường minh:

| | Trục **scarcity** (variant) | Trục **iconicity** (signature) |
|---|---|---|
| Dải ngân sách | 6.0 → 10.2 (**1.70×**) | 6.0 → 17.0 (**2.83×**), r4 vượt xa hơn |
| Điều khiển bởi | Bạn **sở hữu** part gì | Part đó **là** part gì |
| Mua được bằng tiền? | Có (mua NFT hiếm) | **Không** — Ronin là Ronin, ai có cũng ra face đó |
| Áp guardrail ranked? | **Có** (§3.9) | Không cần |

Dải kiểm ngân sách:
- **Variant** (158 face): `|B_hàm_ý − B_eff| / B_eff ≤ 12%` — **BLOCKING** (AC-7)
- **Signature Addendum + Secret** (13 + 18 = 31 face): `≤ 20%` — **BLOCKING** (AC-7b). Lệch lớn nhất hiện tại: `Pincer` +18% (Bug poison đắt vì VIRULENT; giữ `poison 4` để không yếu hơn `Grass Snake` r0 về cảm nhận — ngoại lệ có ý thức, 1/31)
- **Signature legacy** (50 face `FACE_NAMES`): **MIỄN KIỂM hoàn toàn** (grandfathered). Chúng hand-tuned và đang chạy live; áp dải sẽ fail vào chính những face iconic ta muốn giữ nguyên (`Pocky` r4 có ngân sách hàm ý 29.4 — vô nghĩa để so)

`B_hàm_ý` tính ngược: `B_hàm_ý = ( v × R[type] + KW + TYPE_SURCHARGE ) / SlotMod`

### F8. Rarity của mặt

```
r(k, part) = min( 4,  rBase  +  rBonus( sgTier_eff(part, bucket(k)) ) )

rBase   = SIGNATURE_FACE[k].r                        nếu là signature
        = SCARCITY_RFLOOR[bucket(k)]                 nếu là variant
rBonus  = [0, 1, 1, 1, 1, 2, 2, 2][tier]             // §3.4a-1

SCARCITY_RFLOOR = { C: 0,  O: 1,  P: 2,  X: 2 }
```

**Đổi ở revision 3**: bonus rarity không còn là `+1` nhị phân mà theo thang gene — `+1` cho tier 1–4, `+2` cho tier 5–7. Đây là **nửa đọc-được** của thang gene (§3.4a-1 khuyến nghị 3): `G(tier)` chỉ nhích ngân sách vài phần trăm nên nó hay bị làm tròn mất, còn `rBonus` đổi **màu viền mặt dice và nhãn `dieRarity`** nên nó luôn thấy được, và nó **không** bị `B_CAP_RUN` kẹp ở cuối run.

**Hệ quả phải kiểm (E12 mục 1 vẫn giữ)**: variant tối đa `rBase = 2` (Prime) `+ 2` = **`r = 4`** — nghĩa là một part Prime mang gene tier ≥5 giờ **CÓ THỂ** tự tạo COSMIC, điều mà revision 2 cấm tuyệt đối. Quyết định: **kẹp variant ở `r ≤ 3`**, giữ nguyên luật "chỉ signature Mythic mới đưa die lên COSMIC":
```
nếu src === 'var':  r = min(3, ·)          // AC-18 kiểm: 0 variant nào có r >= 4
nếu src === 'sig':  r = min(4, ·)
```
Lý do giữ luật: `dieRarity` là nhãn cao nhất trong game và §3.3 đã quyết rằng nó phải đòi **một part iconic thật**, không mua được bằng cách gom part hiếm + gene hiếm. Nếu bỏ kẹp này, `COSMIC` trở thành thứ mua được — đúng đường mua power thứ hai mà §3.9 không bao (E12 mục 2).

Hệ quả cho `dieRarity()` (`engine.js:97`) — xem E12.

### F9. ~~Ranked guardrail — công thức~~ — **ĐÃ BỎ HẲN (2026-09-03)**

> Mục này đặc tả `scarcityPoint`, `teamScarcity`, `w(part)`, `S̄`, handicap divisor `H`, `H'`,
> `scoreFinal = floor(rawScore / H')`, và luật `REJECT nếu teamScarcity > SBC_CAP`.
>
> **Toàn bộ đã bỏ** theo quyết định pay-to-win của product owner (2026-09-03, `F1b-α`). Thân công thức
> bị xoá thay vì gạch tiêu đề, vì cùng lý do đã nêu ở §3.9: lập trình viên implement theo thân mục.
>
> `scoreFinal = rawScore`. Không chia, không hệ số, không trần scarcity đội hình.
>
> Hai thứ **không** bị bỏ theo và phải giữ nguyên hiệu lực:
> - `nftHpBonusPct` (§3.9f) — đây là một trục scarcity riêng, không phải handicap. Nó vẫn tồn tại.
> - Anti-cheat: replay xác thực phía server vẫn **chặn cứng**. Chấp nhận pay-to-win nghĩa là người
>   giàu được mạnh hơn, **không** nghĩa là ai đó được nộp điểm mình không chơi. `AC-1` (tính pure và
>   tất định của `axieToDie`) vẫn BLOCKING vì server phải dựng lại die để replay.

### F10. Ví dụ chạy đủ #1 — SIGNATURE (`Piranha`)

Input từ `/api/axie?id=…`:
```json
{ "id":"piranha-mouth", "name":"Piranha", "class":"Aquatic", "type":"Mouth", "specialGenes":"" }
```

| Bước | Thao tác | Kết quả |
|---|---|---|
| 1 | `normClass('Aquatic')` | `aqua` |
| 2 | `normSlot('Mouth')` | `mouth` |
| 3 | `baseName('Piranha')` — không có hậu tố | `Piranha` |
| 4 | `partKey` | `aqua\|mouth\|Piranha` |
| 5 | Tra `SIGNATURE_FACE` — có (§3.3a #35) | **Signature path** |
| 6 | Copy face nguyên xi | `{p:'mouth', t:'dmg', v:13, k:['lifesteal','crit:40'], r:3}` |
| 7 | `isSpecialGene`? `''` → falsy | không bump |
| 8 | Gắn metadata | `name:'Piranha', src:'sig'` |
| — | **KHÔNG** áp F1–F6 | `v` giữ nguyên **13** dù bucket là gì |

Kiểm ngân sách (F7, chỉ để đối chiếu — face này **miễn kiểm** vì thuộc legacy 50):
`B_hàm_ý = (13 × 1.00 + 1.50 + 0.045×40 + 0) / 1.00 = 13 + 1.5 + 1.8 = 16.30`
`SIG_BUDGET[3] = 17.0` → lệch **−4.1%**. (Trong dải 20% dù được miễn — dấu hiệu tốt rằng `SIG_BUDGET` hiệu chuẩn đúng.)

**Điểm mấu chốt**: `Piranha` là bucket **C** (`stages = {1,2}`, không có α). Nếu signature bị scale theo scarcity thì một `Piranha` Prime giả định sẽ ra `dmg 21` — nhưng **không có đường nào** dẫn tới đó. Đó là §3.3 đang làm việc.

### F11. Ví dụ chạy đủ #2 — FAMILY VARIANT (`Bumpy`, Prime)

Input:
```json
{ "id":"bumpy-horn", "name":"Bumpy α", "class":"Reptile", "type":"Horn", "specialGenes":"" }
```

| Bước | Thao tác | Kết quả |
|---|---|---|
| 1 | `normClass('Reptile')` | `reptile` |
| 2 | `normSlot('Horn')` | `horn` |
| 3 | `baseName('Bumpy α')` — bỏ ` α`, trim | `Bumpy` |
| 4 | `partKey` | `reptile\|horn\|Bumpy` |
| 5 | Tra `SIGNATURE_FACE` — **không có** | Family path |
| 6 | Tra `PART_VARIANT` (§3.12 REPTILE·horn) | `Bumpy (P) → D` |
| 7 | Tra `FAMILY_VARIANT.reptile.horn.D` (§3.11) | `Heavy Horn` = `dmg` · `heavy` |
| 8 | `bucket` — `Bumpy` có stage 0 **và** stage 2 (§3.4) | **P** (Prime) |

Tính `v`:

```
B_final   = B(P) + 0                 = 9.60          (specialGenes = '' → falsy)
            min(9.60, 10.2)          = 9.60
B_eff     = 9.60 × SlotMod[horn]     = 9.60 × 1.10   = 10.56
TYPE_SUR  = CLS_SURCHARGE[reptile][dmg]              = 0        (reptile chỉ có thorns surcharge)
KW        = cost('heavy')            = −0.40
            + CLS_SURCHARGE[reptile]['heavy']        = 0
                                                     = −0.40
R[dmg]    = 1.00
v_raw     = (10.56 − 0 − (−0.40)) / 1.00             = 10.96
v         = max(1, Math.round(10.96))                = 11
```

Monotone check (F6) — cả 3 bucket của `reptile.horn.D`:
```
C: (6.60 + 0.40) / 1.00 = 7.00  → 7
O: (8.36 + 0.40) / 1.00 = 8.76  → 9      9 > 7  ✓ không cần enforcement
P: (10.56 + 0.40)/ 1.00 = 10.96 → 11    11 > 9  ✓
```
Khớp bảng §3.11 `reptile · horn · D = 7 / 9 / 11` ✓

Rarity (F8): `rBase = SCARCITY_RFLOOR[P] = 2`, không specialGenes → `r = 2` (EPIC).

Face cuối:
```js
{ p:'horn', t:'dmg', v:11, k:['heavy'], r:2,
  name:'Bumpy', src:'var', variant:'D', bucket:'P' }
```

Kiểm ngân sách (F7, BLOCKING cho variant):
`B_hàm_ý = (11 × 1.00 + (−0.40) + 0) / 1.10 = 10.60 / 1.10 = 9.636`
`B_eff/SlotMod = 9.60` → lệch `|9.636 − 9.60| / 9.60 = 0.38%` ✓ **trong dải 12%**

**Đối chiếu người chơi cảm nhận được** — cả ba dòng dưới đây tra đúng §3.12 REPTILE·horn, thang tham chiếu:

| Part thật | §3.12 gán | variant | Face | Người chơi thấy gì |
|---|---|---|---|---|
| `Unko` | (C) → **D** | `Heavy Horn` = `dmg · heavy` | **dmg 7 · heavy** | cùng kỹ năng với Bumpy, yếu hơn |
| `Bumpy` | (P) → **D** | `Heavy Horn` = `dmg · heavy` | **dmg 11 · heavy** | ⬥ PRIME — *cùng kỹ năng*, mạnh hơn |
| `Scaly Spoon` | (C) → **B** | `Scale Piercer` = `dmg · pierce` | **dmg 4 · pierce** | cùng bucket với Unko, *khác kỹ năng hẳn* |

Ba part Reptile·Horn, ba face khác nhau, và chúng minh hoạ **hai trục tách bạch** cùng lúc: `Unko` vs `Bumpy` cô lập trục **scarcity** (variant giống nhau, bucket khác) · `Unko` vs `Scaly Spoon` cô lập trục **identity** (bucket giống nhau, variant khác). Đó chính là điều decision 2 yêu cầu.

> **Sửa lỗi revision 1 (defect 8 của review).** Bản trước kết bằng: *"`Scaly Spoon` (bucket C, variant `A`) ra `dmg 7` không `heavy`"*. Ba lỗi trong một câu, và cả ba mâu thuẫn với chính doc:
> - §3.12 và §3.5d **đều** gán `Scaly Spoon → B`, **không** phải `A` — và gán đó là *có chủ ý*, để tránh đúng collision với signature `Incisor` (`reptile horn dmg 7`, #2 legacy). Ví dụ cũ vô tình tái tạo lại chính collision mà §3.5d bỏ công giải.
> - `reptile.horn.B` = `dmg · pierce` = **4** ở bucket C, không phải 7.
> - `reptile.horn.A` là **spare** (§3.12) — không part nào trong family này gán vào `A`, nên **không có** part Reptile·Horn nào ra `dmg 7` thuần.
>
> Ví dụ mới chứng minh **cùng một luận điểm** và đúng sự thật. Nó cũng mạnh hơn: dùng hai cặp đối chiếu thay vì một, nên nó cô lập được từng trục.

---

## 5. Edge Cases

### E1. Part có trong API thật nhưng KHÔNG có trong catalog (catalog drift)

**Đây là edge case có xác suất cao nhất, không phải giả thuyết.** Catalog đã tăng 192 → 285 một lần rồi (`axie-body-parts.md` dòng 5: *"bản cũ thiếu ~93 part thật"*), và `tools/t_import.mjs:36` đã dùng một part tên `'Owl'` (Bird·Ears) **không tồn tại** trong catalog hiện tại — Bird·Ears thật là {Curly, Early Bird, Little Owl, Peace Maker, Pink Cheek, Risky Bird}. Sky Mavis phát hành part mới bất cứ lúc nào.

Xảy ra khi: `SIGNATURE_FACE[k]` miss **và** `PART_VARIANT[k]` miss.

```
fallbackFace(part):
  cls  = normClass(part.class);  slot = normSlot(part.type)
  if FAMILY_VARIANT[cls]?.[slot] exists:
      tpl    = FAMILY_VARIANT[cls][slot]['A']      # variant 'A' = baseline mọi family
      bucket = 'C'                                 # bảo thủ: bucket yếu nhất
      f      = build từ tpl với bucket C
      f.src  = 'fallback'
      f.name = baseName(part.name)                 # VẪN hiện tên thật
  else:
      f = clone(BLANK)                             # slot/class không nhận diện được → E3
      f.src = 'fallback-blank'
  telemetry('part_unmapped', {cls, slot, name: baseName(part.name)})
  return f
```

Bốn quyết định trong đó, mỗi cái có lý do:

1. **Variant `A`, không random.** `A` được định nghĩa là baseline "thuần số, ít/không keyword" ở **cả 36 family** — đó là lý do §3.11 luôn đặt biến thể nhàm nhất ở `A`. Fallback tất định, giữ purity (AC-1).
2. **Bucket `C`, luôn luôn.** Không đoán scarcity của part chưa biết. Part mới sẽ **yếu hơn** thực tế, không mạnh hơn. Fail-safe theo đúng chiều: một part chưa được cân bằng không được phép là part mạnh nhất trong game.
3. **Vẫn hiển thị tên thật.** Người chơi thấy đúng tên part mình sở hữu, chỉ là chưa có skill riêng. Giữ Player Fantasy §2 khoản 1 thay vì hiện "Unknown Part".
4. **Telemetry bắt buộc.** Đây là tín hiệu vận hành duy nhất cho biết catalog đã lệch. Không có nó, part mới âm thầm rơi vào `A` mãi mãi. `analytics-engineer` cần một dashboard đếm `part_unmapped` theo tên.

**Cách sửa drift** (runbook, không phải design): chạy `tools/gen_faces.mjs --refresh-catalog` để nhập lại `parts_full_source.json`, thêm dòng vào §3.12, chạy `tools/t_partskill.mjs`. Không cần đổi công thức.

### E2. Số part ≠ 6

| Input | Hành vi | Đã có trong code? |
|---|---|---|
| `parts.length < 6` | Pad `BLANK` tới đúng 6 (`{p:'blank', t:'blank', v:0, k:[], r:0}`) | ✓ `engine.js:90` — giữ nguyên |
| `parts.length = 0` | 6 mặt `BLANK`. Die vô dụng nhưng **không crash**, và người chơi thấy ngay là die rỗng | ✓ `engine.js:90` |
| `parts.length > 6` | `slice(0,6)` — giữ 6 part **đầu tiên theo thứ tự API trả về** | ✓ `engine.js:91` |
| `parts` = `null`/`undefined` | Coi như `[]` | ✓ `engine.js:71` |

> ⚠️ **Rủi ro tất định của `slice(0,6)`**: nó phụ thuộc **thứ tự** `parts` từ Axie GraphQL. Nếu API đổi thứ tự trả về giữa hai lần fetch cùng một Axie, die sẽ khác → **phá determinism** ở tầng ngoài `axieToDie` (bản thân hàm vẫn pure). Với Collector board (§3.9e bước 3-4) điều này làm replay fail.
> **Yêu cầu**: trước `slice`, **sort `parts` theo `SLOT_ORDER = ['eyes','ears','mouth','horn','back','tail']`** rồi mới cắt. Sort tất định → thứ tự API không còn ảnh hưởng. Đây là thay đổi hành vi nhỏ nhưng cần thiết; nó cũng làm thứ tự mặt dice nhất quán giữa mọi Axie (lợi cho UX: mặt 1 luôn là eyes).

#### E2a. Blank padding là đường DUY NHẤT relic `r_voidgene` kích hoạt được

Phát hiện từ pass thiết kế relic song song, đã verify trực tiếp trên source:

- `r_voidgene` có `modFace` chỉ viết lại face thoả `f.t === 'blank'`.
- **Không một face nào trong cả 18 `HEROES` có `t === 'blank'`** — đã kiểm cả 108 face.
- `axieToDie` pad `clone(B)` (`src/engine.js:107`) khi Axie có < 6 part, và `BLANK` có `t: 'blank'`.

⇒ **Với đội toàn hero, `r_voidgene` là một no-op tuyệt đối.** Đường duy nhất trong toàn game để nó có tác dụng là **một Axie import thiếu part** — tức chính là edge case E2 này.

Ba hệ quả, và chúng đi theo hai chiều nên phải quyết tường minh:

1. **Quyết định của E2 về padding quyết định luôn một relic đã ship có chạy hay không.** Đó là một cặp phụ thuộc ẩn giữa hai hệ mà không doc nào nêu. Nay nêu ở cả E2 và §6a.
2. **Giữ `BLANK` padding — KHÔNG thay bằng fallback face.** Đây là quyết định, và nó ngược với bản năng "đừng để mặt trống": mặt `BLANK` trung thực (Axie đó thật sự thiếu part) *và* nó là bề mặt duy nhất `r_voidgene` cần. Thay `BLANK` bằng một face `A`-fallback sẽ **âm thầm biến `r_voidgene` thành no-op vĩnh viễn trên toàn game**, và không test nào hiện có bắt được.
3. **Nhưng đừng biến nó thành lý do để thưởng cho die khuyết.** Một Axie 3 part + `r_voidgene` không được mạnh hơn một Axie 6 part. §3.4b đã xử lý đúng chiều này: purity dùng **tỉ lệ** trên số part thật (`purity6 = round(6 × matching / realParts.length)`), nên die khuyết không bị phạt coherence *và* cũng không được thưởng. Trần vẫn là `B_CAP_RUN`.

**AC mới (AC-32)**: import một Axie 3 part → die có đúng **3 face thật + 3 face `t === 'blank'`**; với `r_voidgene` trong `s.relics`, cả 3 face blank **đều** được `modFace` viết lại. Không có AC này, quan hệ trên là một sự trùng hợp không ai bảo vệ.

### E3. Slot hoặc class không nhận diện được

| Input | Xử lý |
|---|---|
| `type` = `'Wing'` (slot lạ) | `FAMILY_VARIANT[cls]['wing']` miss → `fallbackFace` nhánh 2 → `BLANK`. **Đổi so với code hiện tại**, vốn fallback sang `SLOT_CLASS_TEMPLATE.mouth.beast` (`engine.js:78`) — tức một part slot lạ nhận được một face `dmg` Beast. `BLANK` trung thực hơn: ta không biết part này là gì, đừng phát minh sức mạnh cho nó |
| `class` = `'nonsense'` | `normClass` giữ nguyên chuỗi → tra miss → `BLANK`. **Lưu ý**: `mapAxieClass()` (dùng cho `axieData.class`, tức body class) vẫn fallback `'beast'` như cũ (`engine.js:68`) — body class **phải** hợp lệ để `PASSIVE`/`HEROES` hoạt động. Hai đường khác nhau: body class fallback `beast`, part class fallback `BLANK` |
| `type` hoặc `class` = `null` | `(x \|\| '').toLowerCase()` → `''` → miss → `BLANK` |
| `name` = `null`/`''` | `baseName('')` = `''` → miss → `BLANK`, `f.name` bỏ trống (UI hiện nhãn slot) |

`resolveFace` **không bao giờ throw** với bất kỳ input nào. AC-8.

### E4. Trùng tên xuyên slot — `Nut Cracker`

`Nut Cracker` (Beast) tồn tại ở **4 slot**: mouth, tail, eyes, ears. Đây là 4 identity riêng biệt và phải ra 4 face khác nhau.

| `partKey` | bucket | Đường | Face |
|---|---|---|---|
| `beast\|mouth\|Nut Cracker` | P | **Signature** (§3.3a #26) | `dmg 6 · multi:3`, r2 |
| `beast\|tail\|Nut Cracker` | P | Variant `beast.tail.B` | `dmg 8 · multi:2`, r2 |
| `beast\|eyes\|Nut Cracker` | O | Variant `beast.eyes.A` | `debuff 0 · vulnerable:4`, r1 |
| `beast\|ears\|Nut Cracker` | P | Variant `beast.ears.D` | `mana 4 · cantrip · selfharm:2`, r2 |

4 face khác nhau về `p`, `t`, `v`, `k` **và** `r`. Cơ chế: `slot` nằm trong `partKey` (§3.1).

**Bẫy phải tránh khi implement**: `SIGNATURE_FACE` **không được** khoá theo tên. Nếu khoá theo `'Nut Cracker'` thì cả 4 slot nhận face mouth. Cùng bẫy áp dụng cho `Little Owl` (bird: mouth/eyes/ears — mouth là signature, hai slot kia là variant), `Leaf Bug` (bug: horn/tail/ears — 3 variant khác nhau), `Puppy` (beast: mouth/eyes/ears), `Maggot` (bug: mouth/ears), `Tiny Dino` (reptile: mouth/back/tail), `Anemone` (aqua: horn signature / back variant), `Oranda` (aqua: horn/tail), `Ranchu` (aqua: mouth/tail), `Puff` (aqua tail / beast mouth — **khác class nữa**), `Lotus` (plant: horn/ears), `Turnip` (plant: back/ears), `Nimo` (aqua: tail/ears), `Peace Maker` (bird: mouth/ears), `Foxy` (beast: mouth/ears), `Shiba`/`Pangolin` (beast tail).

`tools/t_partskill.mjs` phải có một test riêng cho 4 face `Nut Cracker` (AC-4b).

### E5. Cùng một part xuất hiện 2 lần trên một Axie

Có thể xảy ra: một con Axie có thể mang `Nut Cracker` ở cả mouth và tail. Cũng có thể (dữ liệu lỗi) API trả cùng `{name, type, class}` hai lần.

- **Cùng tên, KHÁC slot** → 2 `partKey` khác nhau → 2 face khác nhau. **Đúng, không phải bug.** Đây là trường hợp thường gặp.
- **Cùng tên, CÙNG slot, 2 lần** → 2 face **giống nhau** trên die. Cho phép, không dedupe. Lý do: hai mặt giống nhau chỉ có nghĩa "xác suất roll ra kỹ năng đó gấp đôi" — đó là một die hợp lệ (`HEROES.beast1` cũng có `mouth dmg 2` hai lần, `data.js:63`). Dedupe sẽ tạo ra mặt `BLANK` — tệ hơn.
- **Deep-clone bắt buộc**: hai mặt đó phải là 2 object riêng. Nếu share reference, một mutation/rune/ascend reward áp lên mặt 1 (`buildUnit`, `engine.js:50-52`) sẽ âm thầm sửa mặt 2. AC-2.

### E6. `chain:N` — target ngẫu nhiên, không tất định theo lựa chọn người chơi

`chain:N` (`engine.js:475-476`) đánh `N` lần vào target **`pick()` ngẫu nhiên** từ `aliveE(s)`, bỏ qua target người chơi kéo vào. Nó *vẫn tất định* (dùng `RNG` seeded, nên replay khớp) nhưng **không tất định theo ý người chơi**.

Hệ quả thiết kế: `chain` được **chiết khấu** so với `multi` (F4: `1.40×(N−1)` vs `1.60×(N−1)`) vì mất quyền chọn target là một cost thật. Và `chain` **không được** dùng trên face có `exec`/`vulnerable` setup — nếu đòn chain đi lạc khỏi target yếu máu thì combo tan. Đã kiểm: 4 variant dùng `chain` (`beast.tail.D`, `aqua.tail.C`, `bird.back.E`, `bird.tail.C`) đều **không** kèm `exec` hay `vulnerable`.

**Pillar risk**: game-concept đặt "Deterministic" làm pillar, và `chain` có vẻ vi phạm. Nó không — RNG seeded và crit hiện ngay lúc roll (`:236`) — nhưng UI **phải** nói rõ "3 đòn vào mục tiêu ngẫu nhiên", không được để người chơi tưởng mình chọn được. Đây là việc cho `ux-designer`.

### E7. `cantrip` chain — trần 6 và tương tác với variant

`resolveCantrips()` (`engine.js:261-266`) lặp `while(... hasKw(cantrip) && g++ < 6)`. Trần cứng 6 vòng/unit/lượt.

- **Không có vòng lặp vô hạn** — trần 6 tồn tại độc lập với thiết kế này.
- **Nhưng**: `cantrip` được resolve **tự động lúc roll**, trước khi người chơi tương tác. Một face `cantrip` có `dmg` sẽ tự chọn target — và `execFace(s, u, u.uid)` truyền `u.uid` (chính unit đó) làm target. Với `f.t === 'dmg'`, `doFace` kiểm `tgt.side === u.side` → **return false** → face không kích hoạt, rồi `rollUnit` lại. Nghĩa là **`cantrip` trên face `dmg` đơn mục tiêu = reroll miễn phí, không gây damage.**
- **Suy ra luật**: `cantrip` chỉ được đặt lên `mana` / `heal` / `shield` / `buff` (self-targetable), hoặc lên face có `aoe` (không cần target). **Không bao giờ** lên `dmg`/`poison`/`debuff` đơn mục tiêu.
- Đã kiểm 158 variant: `cantrip` xuất hiện ở `plant.tail.E` (shield ✓), `plant.eyes.D` (heal ✓), `aqua.eyes.D` (heal ✓), và toàn bộ variant `mana` ✓. **Không variant nào** đặt `cantrip` lên `dmg`/`poison`/`debuff`. Signature: `Sleepless` (heal ✓), `Risky Bird` (mana ✓), `Mavis`/`Robin`/`Neo` (summon ✓), `Gill`/`Bubblemaker`/`Nyan`/`Friezard`/`Sidebarb` (mana ✓), `Harmonious Silence` (mana ✓). Tất cả hợp lệ.
- AC-5b kiểm luật này bằng test.

### E8. Chuẩn hoá hậu tố stage — `α` và `+`

Một identity xuất hiện tối đa 3 lần trong `parts_full_source.json` với 3 stage. `part.name` từ API **có thể** mang hậu tố.

| API trả về | `baseName` | `partKey` | Face |
|---|---|---|---|
| `Nut Cracker` | `Nut Cracker` | `beast\|mouth\|Nut Cracker` | giống nhau |
| `Nut Cracker α` | `Nut Cracker` | `beast\|mouth\|Nut Cracker` | giống nhau |
| `Nut Cracker +` | `Nut Cracker` | `beast\|mouth\|Nut Cracker` | giống nhau |

**Cả 3 stage của cùng một identity ra CÙNG MỘT face.** Đây là quyết định, không phải sơ suất: `axie-body-parts.md` dòng 12 nói rõ stage 2 *"là tập con của stage 1 (cùng part, tên hiển thị khi Axie ở stage cao — KHÔNG phải part khác)"*. Stage là trạng thái tiến hoá của **con Axie**, không phải part khác. Bucket được suy từ **tập stage mà identity tồn tại trong catalog**, không từ stage của instance NFT đang cầm — nên nó là thuộc tính tĩnh, tra bảng, tất định (§3.4).

**Rủi ro**: nếu API dùng hậu tố khác (`" Alpha"`, `"(α)"`, ký tự Unicode khác cho α — `U+03B1` GREEK SMALL LETTER ALPHA vs `U+1D6C2` MATHEMATICAL ITALIC SMALL ALPHA), `baseName` miss → rơi vào E1. **Việc cần làm trước khi implement**: log `part.name` thật từ một Axie Origin stage-0 và một stage-2, xác nhận chuỗi hậu tố chính xác, ghi vào `assets/data/name_suffixes.json` thay vì hardcode.

**Identity với `stages = {1}` duy nhất**: hiện tại **không tồn tại** — cả 285 identity đều có stage 0 hoặc stage 2 (verify: 174 + 75 + 18 = 267 sáu-class, cộng 18 secret = 285). Nếu Axie phát hành một part chỉ có stage 1, `bucket()` (F1) không có nhánh khớp → **phải** default về `C` và ghi telemetry `bucket_undetermined`. Không được throw.

### E9. Chất lượng dữ liệu catalog — 3 vấn đề đã biết

| Vấn đề | Chi tiết | Xử lý |
|---|---|---|
| **`Kotaro?`** (bug·eyes) | Tên có **dấu hỏi thật** trong `parts_full_source.json`. Có thể là ghi chú "chưa xác nhận" của người nhập, không phải tên part | `partKey` dùng nguyên `'Kotaro?'`. Nếu API trả `'Kotaro'` (không `?`) → miss → E1. **Mitigation**: thêm alias `bug\|eyes\|Kotaro → bug\|eyes\|Kotaro?` vào `PART_ALIAS`. Cần product owner xác nhận tên đúng |
| **`Kotaro` vs `Kotaro?`** | `Kotaro` là reptile·mouth (không `?`), `Kotaro?` là bug·eyes (có `?`). Hai part khác nhau, tên gần giống | `class` + `slot` trong khoá đã tách chúng ra ✓. Không cần xử lý thêm — nhưng đừng "sửa" bằng cách strip `?` mà không thêm slot vào khoá |
| **`Bamboo Spear` vs `Bamboo Shoot`** | Catalog thật ghi `Bamboo Spear` (plant·horn); `part-tier-system.md` §8 ghi `Bamboo Shoot`. Một trong hai sai | Doc này dùng **`Bamboo Spear`** (theo catalog, là nguồn sự thật). §3.12 PLANT·horn dùng tên này |
| **`Confusion` vs `Confused`** | Catalog: `Confusion` (plant·eyes). `part-tier-system.md` §8: `Confused` | Doc này dùng **`Confusion`** |

`PART_ALIAS : string → partKey` là một bảng nhỏ, tách riêng, cho các trường hợp API-vs-catalog lệch chính tả. Nó **không** được dùng để hợp nhất hai part thật khác nhau.

### E10. `thorns` KHÔNG BAO GIỜ giảm — degenerate strategy đã xác định

`tickStatus()` (`engine.js:632`) chỉ giảm `['blind','weaken','vulnerable']`. `poison` giảm ở `:620`, `burn` halve ở `:629`, `regen` giảm ở `:631`. **`thorns` không có ở đâu cả** → `st.thorns` tích luỹ **vĩnh viễn trong trận, không trần**.

Degenerate strategy: một đội Reptile (SCALES: `thorns` nền 2 **và** `thorns` áp thêm Poison 1) dồn variant `reptile.back.B` (`thorns:3`) + `reptile.eyes.B` (`thorns:2`) có thể lên `thorns` hai chữ số trong ~5 lượt, sau đó **thắng bằng cách không làm gì** — địch tự chết khi tấn công, mỗi đòn phản còn kèm Poison 1. Với `plant` thì `applyShield` tự cấp `thorns 2` khi shield ≥10 (`:354`).

#### E10a. Vì sao ĐỊNH GIÁ KHÔNG PHẢI là cách xử lý — sửa lỗi phân loại của revision 1 (defect 17 của review)

Revision 1 xử lý bằng 3 lớp, cả 3 đều là **định giá**: `thorns:N` = 0.70/stack, Reptile surcharge +0.60, và "trần phơi bày" 7/158 variant. Đó là một **category error**, và nó cần được nói thẳng vì nó là khuyết điểm thiết kế nghiêm trọng nhất còn lại trong doc:

> Định giá keyword là một phép trao đổi **ngân sách một lần** đổi lấy **giá trị một lần**. Nó chỉ đúng khi giá trị của keyword **bị chặn**. Giá trị tổng của `thorns` **không bị chặn theo số lượt**: đã verify `tickStatus()` (`src/engine.js:640-662`) giảm `poison` (:649), `burn` (:658), `regen` (:660), `blind`/`weaken`/`vulnerable` (:661) — **`thorns` không xuất hiện ở đâu cả**. Nên với một trận dài `T` lượt và `A` đòn địch/lượt, tổng damage từ một lần áp `thorns:N` là `Θ(N × A × T)`, tăng **vô hạn** theo `T`.
>
> Một số hữu hạn không thể là giá đúng cho một đại lượng vô hạn. Không có giá trị nào của `K11` đúng — 0.70 sai, và 1.10 (đỉnh dải revision 1 đề xuất) cũng sai, chỉ sai chậm hơn.

Và revision 1 **tăng** mức phơi bày trong khi cho rằng mình đang chặn nó: `SCALES` đã cấp Thorns 2 nền cho mọi unit Reptile (`:232`), `applyShield` tự cấp Thorns 2 cho Plant ở shield ≥10 (`:379`), rồi thiết kế **thêm** `reptile.back.B` (`thorns:3`), `reptile.eyes.B` (`thorns:2`) và secret `Greedy Urn` (`thorns:4`).

**Revision 2 còn làm nó tệ hơn một bước nữa, và điều này phải nêu**: `B[C]` hạ 6.00 → 2.80 nhưng **magnitude `thorns:N` là hằng số được authored ở §3.11, không phải số suy từ ngân sách**. Nên `reptile.back.B` vẫn cấp `thorns:3` trong khi `shield` của nó rơi từ 4 xuống ~2. Tỉ lệ *thorns trên power của phần còn lại của die* **tăng ~2.1×** so với revision 1. Trục power hạ xuống, trục thorns thì không.

#### E10b. Cam kết trước: remedy engine ship CÙNG hệ này, không hoãn

Revision 1 viết *"Điều doc này KHÔNG làm: không đề xuất sửa `tickStatus`… Nhưng nó là ứng viên #1 cho `/balance-check combat` **sau** khi hệ này ship"*. Hoãn không còn là lựa chọn hợp lệ, vì chính doc này làm exposure tăng. Nên **cam kết trước một trong hai remedy, chọn bằng đo, không bằng tranh luận** (`N12`, §9a — BLOCKING):

| Remedy | Cơ chế | Ảnh hưởng ngoài scope | Ưu tiên |
|---|---|---|---|
| **R-A — thorns decay** | thêm `'thorns'` vào mảng `['blind','weaken','vulnerable']` ở `tickStatus` :661 | Đổi `HEROES.reptile1/2/3` (thorns:2/3/4 thành tạm thời), relic `thornsMult`, boss `permThorns` (`:141`), passive SCALES (`:232`) | 🥈 đúng về nguyên lý nhưng bán kính lớn |
| **R-B — trần thorns/unit** | `t.st.thorns = min(THORNS_CAP, t.st.thorns + v)` trong `addStatus` :394-395 | **Không đổi gì** khi thorns < cap. `HEROES.reptile3` cao nhất là `thorns:4`; `THORNS_CAP = 8` không đụng tới bất kỳ dice hero nào | 🥇 **KHUYẾN NGHỊ** |

**R-B được khuyến nghị** vì nó chặn đúng cái vô hạn (tích luỹ) mà **không** đổi bất kỳ giá trị đang chạy nào: nó là một no-op cho mọi build hiện tại và chỉ có hiệu lực đúng ở vùng degenerate. Nó cũng biến `thorns` trở lại thành một đại lượng **bị chặn** — tại đó, và chỉ tại đó, việc định giá `0.70/stack` mới trở thành đúng thay vì vô nghĩa. `THORNS_CAP` vào §7 làm `K24` (dải 6–12, gate).

`ENGINE_VERSION` phải bump cho R-B (nó là gameplay math) — nhưng nó đã bump vì `axieToDie` rồi, nên chi phí biên bằng 0. Đây là lý do thứ hai để ship cùng nhau chứ không hoãn.
2. **Reptile surcharge +0.60** (F5) trên `thorns:N`, vì SCALES nhân đôi giá trị nó.
3. **Trần phơi bày**: đúng **7 variant** trên 158 mang `thorns` — `plant.back.C`, `plant.tail.C`, `bug.back.C`, `reptile.back.B`, `reptile.eyes.B`, cộng signature `Indian Star`/`Tri Spikes`/`Green Thorns` (legacy, không đổi) và secret `Nutdha Statue`/`Greedy Urn`. Một Axie import chỉ có 6 mặt; muốn 3 mặt `thorns` phải cố ý chọn đúng 3 part cụ thể. **Đó là một build hợp pháp, không phải exploit** — nó có counter (`pierce` bỏ qua thorns nếu có relic `piercePlus`, `:313`; địch `aoe`/`poison` không `attack:true` nên không kích hoạt thorns).

*(Đoạn "Điều doc này KHÔNG làm — không đề xuất sửa `tickStatus`… ứng viên #1 cho `/balance-check` **sau** khi ship" của revision 1 đã bị xoá tại đây và thay bằng E10a/E10b: remedy được cam kết trước và ship cùng hệ này.)*

**Lưu ý về counter**: E10 của revision 1 lập luận thorns "có counter" qua relic `piercePlus` (bỏ qua thorns, `dealDamage` :338). Điều đó **vẫn đúng về code** nhưng **không dùng được làm lập luận cân bằng nữa**: hệ relic đang được thiết kế lại song song (`design/gdd/relic-system.md`, `relic-roster-expansion.md`), nên sự tồn tại và tần suất của `piercePlus` là **một phụ thuộc, không phải một hằng số**. Doc này nêu phụ thuộc: *nếu* roster relic mới bỏ hoặc làm loãng `piercePlus`, `THORNS_CAP` phải xét lại. Ghi vào §6d chứ không giả định.

### E11. `Greedy Urn` (secret) + SCALES — cộng dồn cần sim

`Greedy Urn` là dusk·back, map sang `reptile`, face `shield 9 · thorns:4`. Với SCALES:
- `thorns` hiệu dụng = 2 (nền) + 4 = **6**
- Mỗi lần địch tấn công: 6 damage phản + **Poison 1** (`:319`)
- Nếu roll lại `Greedy Urn` lượt sau: `thorns` = 10, rồi 14, … (E10: không giảm)

Đây là mặt `thorns` **mạnh nhất** trong toàn bộ 239 face. Nó cố ý — `Greedy Urn` là 1 trong 18 part khan hiếm nhất của Axie, và nó **không thể lên leaderboard** (§3.9 L1). **Yêu cầu**: `tools/sim.js` phải chạy ≥200 run với một đội gồm `Greedy Urn` + `reptile.back.B` + `Tri Spikes` trước khi ship, và win-rate ở Ascension 10 không được vượt **1.4×** win-rate của đội đối chứng cùng bucket (AC-10).

### E12. `dieRarity()` khi die trộn signature và family face

`dieRarity()` (`src/engine.js:115-122`) tính độ hiếm của **cả viên dice** từ `r` của 6 mặt:
```
myth ≥1 → 4 (COSMIC) · leg ≥2 → 3 (GOLDEN) · (leg ≥1 hoặc epic ≥2) → 2 · any r≥1 → 1 · else 0
```

Die import mới sẽ trộn `r` từ hai nguồn: signature (`r` cố định 0–4 theo `FACE_POOL`) và variant (`r` = `SCARCITY_RFLOOR[bucket]`, tối đa 2 + 1 nếu specialGenes = **3**).

Ba hệ quả cần biết:

1. **Variant không bao giờ tự tạo COSMIC.** `r` variant tối đa = `SCARCITY_RFLOOR[P] = 2`, `+1` specialGenes = 3. Cần `r ≥ 4` cho COSMIC → **chỉ signature Mythic** (8 face: `Thorny Caterpillar`, `Wing Horn`, `Green Thorns`, `Mosquito`, `Sidebarb`, `Granma's Fan`, `Neo`, `Pocky`) mới đưa được một die lên COSMIC. Đó là đúng và đáng mong đợi: nhãn cao nhất phải cần một part iconic thật, không mua được bằng cách gom part hiếm.
2. **GOLDEN (r3) đạt được bằng scarcity.** 2 part Prime **có** specialGenes → 2 mặt `r3` → GOLDEN. Đường này chỉ mua được bằng tiền. **Chấp nhận** — `dieRarity` là nhãn cosmetic/hiển thị, không có tác dụng gameplay nào (grep: `dieRarity` chỉ được `ui.js` dùng để tô màu viền). Nếu sau này ai đó gắn gameplay effect vào `dieRarity`, guardrail §3.9 phải mở rộng theo — ghi vào §6 như một cảnh báo hợp đồng.
3. **Regression so với hiện tại**: code hiện hành ép `r >= 3` cho **mọi** part Origin (`engine.js:82`), nên một con Axie Dawn hiện cho 6 mặt `r3` → GOLDEN ngay. Thiết kế mới cho Origin `r1` và Secret `r3` (signature). Nhiều die đang GOLDEN trong Vault sẽ tụt xuống RARE/EPIC. Xem E15.

### E13. Re-import khi part đổi trên chain / vault snapshot đã đóng băng

**Verify**: `importAxieToVault()` (`ui.js:150-155`) gọi `axieToDie()` **một lần** rồi **lưu die đã resolve** vào `META.vault` → `localStorage`. `ensureVaultHero()` (`:170-173`) đăng ký nó vào `HEROES` nguyên xi. Nghĩa là **mọi entry Vault là một snapshot đóng băng**, không phải một tham chiếu.

Hai hệ quả:

| Tình huống | Hành vi hiện tại | Yêu cầu |
|---|---|---|
| Người chơi đổi part con Axie ngoài đời rồi quét lại cùng `axieId` | `META.vault[idx] = die` — **ghi đè** bản cũ (`ui.js:152`), giữ 1 entry. ✓ Đúng | Giữ nguyên |
| **Ship hệ mới này** trong khi Vault đang có die cũ (36-cell) | Die cũ **giữ nguyên vĩnh viễn**. Người chơi thấy die 36-cell và die mới cạnh nhau, không hiểu vì sao | **BẮT BUỘC migration** — xem dưới |

**Migration bắt buộc** (nếu bỏ qua, hệ mới sẽ vô hình với mọi người chơi đã import):
```
Thêm META.vault[i].schema = 2  cho die sinh bởi hệ mới.
Lúc load: mọi entry KHÔNG có schema === 2 → đánh dấu 'stale',
  hiện badge "RE-SCAN" trên card ở Vault screen,
  và HIỂN THỊ die cũ (không xoá — người chơi vẫn chơi được),
  nhưng CHẶN pre-select vào đội hình cho tới khi re-scan.
Re-scan = fetch lại /api/axie?id=<axieId> rồi axieToDie() v2.
```
Lý do không tự động re-scan: cần 1 network call/Axie, tối đa 20 Axie, và `api/axie.js` có rate limit 20 req/phút/IP (`api/axie.js:63`) → tự động re-scan 20 Axie sẽ **đụng đúng trần rate limit**. Phải là hành động do người chơi bấm, có nút "RE-SCAN ALL" chạy tuần tự với backoff.

**Trường hợp Axie bị bán/chuyển đi**: Vault vẫn giữ die (offline-first, đúng thiết kế hiện tại). Không xoá. Nhưng Collector board (§3.9e bước 2) sẽ **reject** vì on-chain ownership check fail — đó là chỗ đúng để chặn, không phải ở Vault.

### E14. Axie dawn/dusk/mech thật — thành phần 6 part

Một con Axie Dawn thật **không** có 6 part Dawn. Dawn chỉ có 7 identity phủ 5 slot (mouth 1, back 3, tail 1, eyes 1, ears 1) và **không có horn nào**. Nên một con Dawn thật mang một hỗn hợp: vài part Dawn + vài part từ 2 class gốc mà Dawn lai (`economy-progression.md` D15: *"rút 3/6 slot từ mỗi bloodline gốc"*).

Xử lý — **không cần luật mới**, mọi part resolve độc lập qua `partKey` của chính nó:

| Part trên con Axie Dawn | `partKey` | Đường |
|---|---|---|
| `Radiant Darkness` (Dawn eyes) | `dawn\|eyes\|Radiant Darkness` | Secret signature (§3.10) |
| `Ronin` (Beast back) | `beast\|back\|Ronin` | Signature (#54) |
| `Imp` (Beast horn) | `beast\|horn\|Imp` | Signature (#13) |
| `Cottontail` (Beast tail) | `beast\|tail\|Cottontail` | Variant `beast.tail.A` |

**Body class** của con Axie đó → `mapAxieClass('Dawn')` → `'beast'` → passive `FERAL`, HP `HEROES.beast1.hp`, màu Beast. **Bản sắc class vẫn đọc được** ✓ (ràng buộc cứng của product owner).

Trường hợp cực đoan: một con Axie có **cả 6 part đều là secret-class**. Không thể xảy ra với dữ liệu hiện tại (Dawn thiếu horn, Dusk thiếu mouth/ears, Mech thiếu mouth/eyes/ears), nhưng nếu Axie mở rộng: 6 secret signature face, tất cả `r3` → `dieRarity` = 3 (GOLDEN, vì `leg >= 2`). Vẫn không COSMIC. Không cần trần thêm.

### E15. Thang power của import so với thang địch — rủi ro TTK, cần sim gate

> **Mục này đã được viết lại hoàn toàn ở revision 2 (Task 2A). Tiền đề của bản cũ bị ngược.**
>
> Bản cũ mang tiêu đề *"Power regression cho Vault đang có"* và dành một bảng quyết định A/B/C cộng một công thức đền bù 150 Shard/bậc rarity để giải một vấn đề **không tồn tại**. Nó so **hệ số nhân** (`2.2 × 1.3 = 2.86×` hôm nay so với trần `1.70×` mới) và kết luận "die sẽ yếu đi". Nhưng nó bỏ qua việc **nền cũng dịch**: `SLOT_CLASS_TEMPLATE` (`src/data.js:123-172`) copy giá trị từ face **hero tier-1** — comment ở `:116` nói thẳng *"dmg/shield 2-4, ears luôn mana 1 cantrip"* — còn nền của thiết kế này là `FACE_POOL` COMMON (`dmg 6`, `shield 7`).
>
> Đo bằng chính hằng số F1/F2 của doc: bucket C ở **revision 1** cho avg face value **~5.33** so với **~2.50** hôm nay — **+113%**, tức *lạm phát*, không phải hồi quy. Bảng A/B/C đã giải sai bài toán, và **product owner đã bác bỏ đền bù**. Đã xoá: bảng A/B/C, công thức 150 Shard, knob `K20`, và dòng propagate sang `economy-progression.md` ở §6e.

#### E15a. Rủi ro thật, sau khi F1 hạ `B[C]` xuống 2.80

Revision 2 hạ `B[C]` 6.00 → 2.80 chính vì đo được +113% ở trên. Sau khi hạ, tình hình từng phần:

| Nhóm part | Hôm nay (thực đo trên code) | Sau revision 2 | Delta |
|---|---|---|---|
| Part 6-class thường | base 2–4, `×1.3` nếu `specialGenes` truthy (bug E16 ⇒ **hầu như luôn**) ⇒ **2.6–5.2** | bucket C thang production ⇒ **~2–5** | **≈ trung tính** |
| Part 6-class là Signature | như trên, 2.6–5.2 | `v_pool × 0.4667` ⇒ r0 ~3, r4 `Pocky` ~12 | **tăng ở đuôi trên** |
| Part dawn/dusk/mech | `round(base × 2.2 × 1.3)` ⇒ **6–11**, `r ≥ 3` | secret signature r3 `× 0.4667` ⇒ **3–6**, `r3` | **giảm ~45%** |
| `dieRarity` của die Origin | ép `r ≥ 3` mọi part ⇒ GOLDEN ngay | Origin(α) → `r1`; Secret → `r3` | **giảm nhãn** (E12 mục 3) |

Nên: **có** một nhóm yếu đi thật — part dawn/dusk/mech — nhưng lý do là hai hệ số nhân *không suy từ đâu cả* đang nhân dồn (`ORIGIN_TIER3_MULT = 2.2`, không có nguồn gốc ghi ở `src/data.js:199` ngoài *"xấp xỉ tỉ lệ quan sát được"*; nhân với bug `specialGenes != null`). Sửa một bug không phải là lấy đi thứ người chơi kiếm được. **Không đền bù.** Điều bắt buộc là **thông báo trước** (patch note nêu rõ die dawn/dusk/mech đổi số) và migration `RE-SCAN` (E13) để người chơi thấy sự thay đổi một cách chủ động, không phải phát hiện ra giữa một run.

#### E15b. Rủi ro cần sim gate — TTK, không phải winrate

Rủi ro thật **không** phải "die yếu đi", mà là: **giá trị mặt tuyệt đối của Axie import giờ được neo vào `HEROES`, trong khi độ khó của run được hiệu chuẩn cho hero BIẾT LÊN TIER.**

- Hero: tier1 → tier2 → tier3 = **2.53 → 4.11 → 6.39** (×2.53 trong một run), qua reward `'level'`.
- Axie import: gene 0 → gene 6 = **2.80 → 5.98** (×2.14), qua reward `'gene'` (§3.4c).
- Địch: `CURVE.budget = TUNE.base × growth^min(pw,knee) × growth2^max(0,pw−knee)` (`src/data.js:499`), **không đổi**.

Hai đường tăng khác hình dạng, nên chúng có thể cắt nhau ở giữa run. Đây là chỗ cần đo, và nó phải đo bằng **TTK theo wave**, không bằng winrate tổng — winrate tổng là một con số cho cả run và nó **trung bình mất** đúng thứ ta cần thấy (một spike ở wave 8 và một hố ở wave 14 cho cùng winrate như một đường phẳng).

**Baseline đã đo** (`tools/sim.js`, 300 run, `mode=short asc=0`, đội 5 hero): winrate **20.0%**, wave-10 elite 73%, wave-12 boss 37%.

**Sim gate (AC-28, BLOCKING trước khi ship):**

| Đại lượng | Ngưỡng | Vì sao hai phía |
|---|---|---|
| winrate đội có ≥1 Axie import | trong **[0.85×, 1.30×]** của 20.0% ⇒ **17.0%–26.0%** | Chặn cả hai chiều. Revision 1 chỉ có ngưỡng trên (AC-10 `≤1.40×`) nên một thiết kế làm import *quá yếu* sẽ pass — mà "import quá yếu" đúng là bài toán product owner giao |
| TTK trung vị mỗi wave, so đội hero | trong **±20%** ở **mọi** wave 1–12 | Đây là kiểm phát hiện được crossover. Cột `ttk` của `sim.js` |
| winrate wave-12 boss | trong **[0.80×, 1.25×]** của 37% | Boss cuối là chỗ chênh power biểu hiện mạnh nhất (siêu tuyến tính gần tường) |

Nếu TTK lệch >20% ở bất kỳ wave nào: **`GENE_STEP` là knob đầu tiên** (`K23`, §7), không phải `B[C]`. `B[C]` neo vào wave 1 và đã được hiệu chuẩn hai lần độc lập (F2); `GENE_STEP` neo vào hình dạng đường tăng trong run và **chưa** được đo lần nào.

#### E15c. Sửa tuyên bố sai ở §3.4a (Task 2A)

§3.4a của revision 1 viết: *"thiết kế này **giảm** trần power của import, không tăng"*. Sai — nó so `1.70×` với `2.20×` mà không nói hai hệ số đó nhân vào **hai nền khác nhau** (`2.2 × [2..4]` so với `1.70 × 6.00`). Phát biểu trung thực gồm **hai** mệnh đề, và chỉ mệnh đề thứ hai là điều doc này thực sự đạt được:

1. ❌ *"Trần power tuyệt đối giảm"* — **không đúng ở revision 1** (nền tăng 113%). **Đúng ở revision 2**, nhưng nhờ `B[C] = 2.80`, không nhờ `B_CAP`.
2. ✅ *"Dải giàu-nghèo thu hẹp"* — **đúng ở cả hai revision.** Hôm nay: một part dawn cho 6–11 còn một part Classic cho 2–4 ⇒ dải **~2.75×**. Revision 2: `B_CAP0 / (B[C] × 0.82) = 4.76 / 2.296` ⇒ dải **2.07×**, và ở gene 6 thu tiếp về **1.47×** (F1a). Tỉ lệ thu: `2.07 / 2.75 = 0.75×`.

Hai mệnh đề đó khác nhau và chỉ mệnh đề 2 là lập luận công bằng dùng được. §3.4a đã được sửa theo đúng cách phát biểu này.

### E16. `specialGenes` — ba cách hiểu trong cùng codebase

Đã verify ba chỗ hiểu field này **khác nhau**:

| Nơi | Cách hiểu | Code |
|---|---|---|
| `src/engine.js:101` (trong `axieToDie`) | nullable flag: `!= null` → có gene đặc biệt | `if(part.specialGenes!=null)` |
| `engine.js:36` `nftRarityMult` | **số nguyên 0–3** đếm số gene đặc biệt | `[1.0,1.15,1.3,1.5][clamp(specialGenes\|0, 0, 3)]` |
| `tools/t_import.mjs:70, 82` | **chuỗi bitmask** `'000000'` được coi là *có* gene đặc biệt | `specialGenes: '000000'` |

Ba cách này không thể cùng đúng. `'000000'` là bitmask **toàn 0** — gần như chắc chắn nghĩa là "KHÔNG có gene đặc biệt", nhưng test hiện tại dùng nó làm case *có*. Nếu API trả `'000000'` cho part thường thì:
- `axieToDie` đang cho **mọi part** `×1.3` và `r ≥ 1` (vì `'000000' != null`)
- `nftRarityMult` đang cho **mọi Axie** `1.0` (vì `'000000' | 0 === 0`)

→ Một trong hai đang sai, và có khả năng cao là cả hai.

### E16-bis. `sgTier()` — chuẩn hoá chuỗi API, và ĐIỀU TA CHƯA BIẾT (viết ở revision 3)

**Trạng thái verify — nói thẳng phần không biết trước, vì đây là điều kiện chặn thật:**

| Câu hỏi | Trả lời | Bằng chứng |
|---|---|---|
| Field tên gì, đến từ đâu? | `parts[].specialGenes`, truyền **nguyên xi** từ Axie GraphQL gateway | `api/axie.js` — `QUERY` liệt kê `specialGenes` trong `parts { … }`; handler trả `parts: axie.parts` không biến đổi gì |
| Kiểu dữ liệu là gì? | **KHÔNG BIẾT.** Có thể string, list, hay null | Không có schema, không có validation, không có cast ở bất kỳ đâu trong repo |
| Chuỗi enum thật là gì? | **KHÔNG BIẾT — 0/8 bậc verify được** | Giá trị `specialGenes` duy nhất tồn tại trong toàn repo là `null` và `'000000'`, cả hai là **fixture do người viết test tự đặt** (`tools/t_import.mjs`), không phải response thật |
| `'000000'` nghĩa là gì? | Gần như chắc chắn "KHÔNG có gene đặc biệt" (bitmask toàn 0) — nhưng test hiện dùng nó làm case *CÓ* | `tools/t_import.mjs` — hai fixture `specialGenes: '000000'` nằm dưới comment `/* ---- specialGenes bump ---- */` |

⇒ **Cả 8 chuỗi trong bảng §3.4a-1 (`summer` `nightmare` `japanese` `shiny` `xmas` `meo1` `meo2` `origin` `mystic` `agamogenesis`) là TÊN THIẾT KẾ, không phải enum API đã xác nhận.** Riêng `japanese` là chỗ rủi ro cao nhất: nó có ít nhất bốn cách viết hợp lý (`japan`, `japanese`, `jpn`, `Japan`) và không có cách nào chọn đúng bằng suy luận. Tìm kiếm tài liệu cộng đồng cũng **không** liệt kê giá trị enum — chỉ liệt kê rằng field tồn tại. **Không được đoán.**

**Nên thiết kế phải tách làm hai lớp**, và lớp thứ hai là dữ liệu, không phải code:

```js
// LỚP 1 — chuẩn hoá, HARDCODE ĐƯỢC vì nó không chứa enum nào
function sgNormalize(raw){
  if (raw == null) return [];
  const list = Array.isArray(raw) ? raw : [raw];           // field CÓ THỂ là list — chịu được cả hai
  const out = [];
  for (const x of list){
    if (typeof x === 'number') { if (x > 0) out.push(String(x)); continue; }
    const s = String(x).trim().toLowerCase().replace(/[\s_-]+/g, '');
    if (s === '' || s === 'none' || s === 'null' || s === 'false') continue;
    if (/^0+$/.test(s)) continue;                          // '000000' và mọi bitmask toàn 0
    out.push(s);
  }
  return out;
}

// LỚP 2 — tra bảng DỮ LIỆU. Bảng nằm ở assets/data/special_genes.json, KHÔNG hardcode.
function sgTier(part){
  const keys = sgNormalize(part && part.specialGenes);
  let best = 0;
  for (const k of keys){
    const t = SG_TABLE.alias[k];                           // undefined nếu chưa biết
    if (t === undefined){ telemetry('sg_unknown_value', { raw: k }); continue; }  // → tier 0
    if (t > best) best = t;                                 // part nhiều gene → lấy bậc CAO NHẤT
  }
  return best;
}
```

Shape của `assets/data/special_genes.json` (giá trị `alias` phải được **điền bằng response thật**, không bằng doc này):

```jsonc
{ "schema": 1,
  "tierNames": ["normal","summer","nightmare","japanese","shinyXmasMeo","origin","mystic","agamogenesis"],
  "alias": {
    // TRỐNG cho tới khi verify. Mỗi khoá là một chuỗi ĐÃ THẤY THẬT từ /api/axie.
    // Ví dụ hình thức (KHÔNG phải giá trị đã xác nhận): "mystic": 6
  },
  "verifiedAt": null, "verifiedAxieIds": [] }
```

**Bốn tính chất bắt buộc, mỗi cái vá một cách hỏng khác nhau:**

1. **Giá trị lạ → tier 0, không bao giờ crash, không bao giờ cấp power.** Nhánh `t === undefined` rơi thẳng về `best = 0`. Đây là điều làm bug lạm phát 30% của E16 **không thể tái diễn**: mặc định là *không có bonus*, và chỉ một khoá có trong bảng dữ liệu mới nâng bậc được. Kiểm bằng `AC-34`.
2. **Chịu được cả string, list, number, null.** Vì ta chưa biết kiểu thật, `sgNormalize` bọc mọi thứ về mảng chuỗi. Nếu API đổi từ string sang list (hoặc ngược lại), **không dòng code nào phải sửa** — chỉ `alias` cần khoá mới.
3. **Nhiều gene → lấy bậc CAO NHẤT, không cộng.** Cộng sẽ phá trần R2 (`G_MAX` giả định đúng một bậc). `max` giữ `SPREAD_OWN = S_MAX × G_MAX` đúng theo định nghĩa. Kiểm bằng `AC-34`.
4. **`telemetry('sg_unknown_value')` là tín hiệu vận hành duy nhất** cho biết bảng `alias` đã lạc hậu — cùng vai trò với `part_unmapped` ở E1. Không có nó, một gene mới của Sky Mavis sẽ âm thầm bị tính là `normal` mãi mãi.

**Việc chặn (N2, §9a) — 3 bước, và bước 1 KHÔNG phải việc của designer:**
1. Gọi `/api/axie?id=…` trên **≥8 Axie thật** phủ đủ 8 bậc (ít nhất: 1 thường, 1 summer, 1 nightmare, 1 Japanese, 1 Shiny **hoặc** Xmas **hoặc** MEO, 1 Origin, 1 Mystic, 1 Agamogenesis). Log **nguyên văn** `specialGenes` của cả 6 part mỗi con, kèm kiểu (`typeof`). Đây là việc cho `lead-programmer` + product owner (cần ví dụ Axie thật để tra).
2. Điền `alias` + `verifiedAt` + `verifiedAxieIds` vào `assets/data/special_genes.json`.
3. Bỏ `if(part.specialGenes!=null)` ở `axieToDie`; `nftRarityMult` chuyển sang `specialGeneCount(axie) = clamp(số part có sgTier > 0, 0, 3)`. **Một định nghĩa, hai chỗ dùng** — đó là điều E16 đòi và §3.4a-4 cấp.

> **Điều KHÔNG chặn**: mọi thứ còn lại của doc này. Với `alias` rỗng, `sgTier` trả 0 cho mọi part ⇒ hệ chạy đúng như thể không có trục gene ⇒ `SPREAD_OWN` co về `S_MAX = 1.600×` (vẫn thoả R2, vẫn thoả `I16`). Thang gene là một **lớp cộng thêm bật được bằng dữ liệu**, không phải một phụ thuộc chặn của F1–F8. Đó là lý do nó được thiết kế thành bảng tra chứ không thành `switch`.

---

## 6. Dependencies

### 6a. Code — symbol chính xác phải đổi

| File : symbol | Quan hệ | Thay đổi bắt buộc |
|---|---|---|
| `src/engine.js:86` **`axieToDie`** | **Bề mặt chính** | Thay nguyên thân theo §3.6. Thêm sort `SLOT_ORDER` trước `slice(0,6)` (E2). Thêm `scarcity` manifest vào return (§3.9e) |
| `src/engine.js:63` **`mapAxieClass`** | Đọc | **KHÔNG đổi.** Vẫn dùng cho `axieData.class` (body class). Nhưng §3.1 `normClass` là hàm **mới, khác**: nó **không** collapse dawn/dusk/mech. Hai hàm cùng tồn tại — đừng hợp nhất |
| `src/engine.js:101` `specialGenes != null` | Sửa | Thay bằng `isSpecialGene()` (E16). **Blocking** cho tới khi enum thật được xác nhận. *(revision 1 trích symbol này ở `:100` tại đây và `:84` tại E16 — số đúng là **101**.)* |
| `src/engine.js:36` **`nftRarityMult`** | Sửa | Dùng `specialGeneCount()` (E16). Hiện đang hiểu field khác với `axieToDie` |
| `src/engine.js:115` **`dieRarity`** | Đọc, không đổi | Hợp đồng: nó đọc `face.r`. §F8 cấp `r` mới. **Cảnh báo hợp đồng (E12 mục 2)**: `dieRarity` hiện *chỉ* dùng để tô màu ở `ui.js`. Nếu ai gắn gameplay effect vào nó, guardrail §3.9 phải mở rộng — nó trở thành một đường mua power thứ hai |
| `src/engine.js:9` **`ENGINE_VERSION`** | **Bump bắt buộc** | Gameplay math đổi → mọi replay leaderboard cũ sẽ bị `api/submit-run.js:88` từ chối. Đây là hành vi đúng, nhưng producer phải biết trước |
| `src/data.js:123` **`SLOT_CLASS_TEMPLATE`** | **Xoá** | Thay bằng `FAMILY_VARIANT` (§3.11), `PART_VARIANT` (§3.12), `SIGNATURE_FACE` (§3.3a/b + §3.10), `SCARCITY` (§3.4) |
| `src/data.js:198` `ORIGIN_CLASS_MAP` | Giữ | Vẫn dùng cho body class (§3.10 mục 1) |
| `src/data.js:199` `ORIGIN_TIER3_MULT` | **Xoá** | Thay bằng `SCARCITY[bucket].B`. Xem E15 (power regression) |
| `src/data.js:203` **`FACE_POOL`** | Mở rộng | 50 → 63 entry. **50 entry cũ giữ NGUYÊN số** (§3.8). Thêm field `cls` cho cả 63 |
| `src/data.js:238` **`FACE_NAMES`** | Mở rộng | 50 → 63 tên. Nó trở thành **nguồn thực thi của Icon List** (§3.3), không còn chỉ là nhãn hiển thị |
| `src/data.js:6` header comment | Sửa | Xoá `shieldself:N` — chưa bao giờ implement (§3.7) |
| `src/data.js:255` `RUNES` | Đọc, không đổi | Đã kiểm an toàn với §3.7a. **Đừng thêm `thorns`/`regen` vào đây sau này** |
| `src/data.js:490` **`RESONANCE`** | Đọc | `types: ['dmg','shield','heal','poison','mana']` — **`debuff` KHÔNG resonate**. Xem 6d. *(revision 1 trích symbol này ở hai số khác nhau — `:510` ở đây và `:490` ở 6d. Số đúng là **490**.)* |
| `src/engine.js:42` **`buildUnit`** | **Sửa** | Axie import phải dựng lại die từ `parts` + `geneTier` thay vì `clone(h.die)` (§3.4c). `oc` ở `:52` chỉ nhân face `f.v > 0` → face `debuff` miễn nhiễm; xem 6d |
| `src/engine.js:687-694` **`genRewards`** | **Sửa** | `:694` `if(canLevel.length) … else pool.push('ascend','ascend')` — thêm nhánh `'gene'` cho Axie import (§3.4c). **Đội toàn hero: 0 thay đổi hành vi** |
| `src/engine.js:709` **`mkReward`** | **Thêm** | Nhánh `t === 'gene'`. Nhánh `'ascend'` (`:717-721`) và `'level'` (`:711-716`) **không đổi** |
| `src/engine.js:394-395` `addStatus` — nhánh `thorns` | **Sửa (E10b R-B)** | Thêm `THORNS_CAP`. No-op với mọi dice hero hiện tại (`reptile3` cao nhất `thorns:4` < cap 8) |
| `src/engine.js:382-401` `addStatus` — **KHÔNG có nhánh `mana`** | Đọc — **cảnh báo hợp đồng** | `mana:N` nằm TRONG kwPure (§3.7a). Nó vô hại **chỉ vì** không có nhánh `mana` ở đây. **Thêm một nhánh `mana` vào `addStatus` sẽ khiến mọi face `dmg · mana:2` cấp mana CHO ĐỊCH.** |
| `RELICS` — `r_voidgene` | Đọc — **phụ thuộc mới phát hiện** | `modFace` của nó chỉ viết lại face `f.t === 'blank'`. **Không** `HEROES` nào có face `blank`, nên đường **duy nhất** relic này kích hoạt được là die import bị pad `BLANK` (E2, `axieToDie` :107). Quyết định của E2 về blank padding **quyết định luôn relic đó có chạy hay không** — xem E2 |
| `src/engine.js:880` `archScore` + `ARCH` (`src/data.js:31-49`) | Đọc — **phụ thuộc đang đổi** | `archScore` khởi tạo `sc` từ khoá `ARCH` rồi guard `if(sc[a]!=null)`. `PASSIVE.beast.a === 'exec'` và `exec` **không** có trong `ARCH` ⇒ **mọi hero Beast góp 0 vào mọi archetype score**. Hệ relic đang thêm `exec` làm archetype thứ 11 — xem 6d |
| `src/engine.js:728` `mkReward` type `'face'` | Sửa (tuỳ chọn) | Ưu tiên face khớp `cls` (§3.8 mục 2). Đổi hành vi drop → cân nhắc ship riêng sau flag |
| `src/ui.js:318` **`importAxieToVault`** | Sửa | Thêm `schema: 2` + migration re-scan (E13). **Blocking** — không có nó hệ mới vô hình với người chơi đã import |
| `src/ui.js:340` `ensureVaultHero` | Đọc, không đổi | Hợp đồng: entry Vault phải giữ shape `{n, cls, tier, hp, art, die}`. §3.6 giữ đúng shape |
| `src/ui.js` — die face tooltip / `faceText` (`engine.js:745`) | Sửa | `faceText()` hiện **không hiện `f.name`**. Player Fantasy §2 khoản 1 *phụ thuộc* việc người chơi đọc được "Ronin" trên mặt dice. → việc cho `ux-designer` + `ui-programmer` |
| `api/submit-run.js:63` `VALID_HERO_KEY` | Giữ | **Đây là guardrail L1 và nó đã đúng.** Không nới. §3.9b |
| `api/submit-run.js` — endpoint mới | Thêm | Collector board (§3.9c–e): `SBC_CAP` check, handicap `H'`, 4 bước provenance, board key `lbc:{mode}:{asc}` |
| `api/leaderboard.js` | Thêm | Đọc board `lbc:*`; nhãn `EXHIBITION` khi chưa có on-chain check (§3.9e GATE) |
| `api/axie.js` | Đọc, không đổi | Nhưng server-side manifest verify (§3.9e bước 3) sẽ gọi nó **20 lần/submission** → rate limit hiện tại 20 req/phút/IP (`:50`) sẽ **chặn chính server mình**. Cần đường nội bộ bỏ qua rate limit hoặc cache |

### 6b. Tools — cái nào fail, cái nào phải viết mới

| Tool | Trạng thái sau spec này |
|---|---|
| **`tools/t_import.mjs`** | 🔴 **FAIL BY DESIGN — 6/21 check sẽ đổ, và đó là đúng.** Nó assert chính hành vi 36-cell mà doc này xoá. Cụ thể: `:9` import `SLOT_CLASS_TEMPLATE` + `ORIGIN_TIER3_MULT` (cả hai bị xoá → `vm.runInContext` sẽ ném `ReferenceError` ở dòng `:12`, tức **toàn bộ file chết, không chỉ 6 check**). Phải viết lại. Chi tiết ở 6c |
| **`tools/t_partskill.mjs`** | 🆕 **Phải viết mới** — chủ nhà của AC-1…AC-9, AC-14…AC-18 (§8) |
| **`tools/gen_faces.mjs`** | 🆕 **Phải viết mới** — implement F1–F8 + REPAIR (§3.5d), sinh `assets/data/part_faces.json`. Thay `gen_parts.py` |
| **`tools/gen_parts.py`** | 🔴 **Invalidated** — sinh dữ liệu 36-cell vào một file không ai import. Xoá cùng với `parts_build_data.json` |
| **`tools/verify.mjs`** | 🟡 Không fail trực tiếp (nó kiểm UI/contrast/tap-target, không kiểm face math). **Nhưng**: badge scarcity mới (`α ORIGIN` / `⬥ PRIME` / `◈ SECRET`) là text mới trên màn Vault → phải qua check contrast AA 4.5 và min-font 11px. Trần hiện tại **29/30 không được tụt** |
| **`tools/soak.mjs` / `soakm.mjs`** | 🟡 Phải chạy lại. Doc này đổi `die` của mọi Axie import → vòng đời element `.die`/`.unit` bị tác động, và đó là **nguồn regression drag/drop đã biết** (`.claude/docs/technical-preferences.md`) |
| **`tools/sim.js`** | 🟡 Phải chạy lại. Là chủ nhà của AC-10. *(AC-11 đã bỏ cùng handicap — 2026-09-03)* |

### 6c. `tools/t_import.mjs` — check nào sống, check nào chết

| Dòng | Check | Sau spec |
|---|---|---|
| 23-25 | `mapAxieClass` beast / `Beast` / `Aquatic` | ✅ Sống, không đổi |
| 26-27 | Dawn/Dusk/Mech map sang class thật | ✅ Sống (§3.10 mục 1 giữ mapping) |
| 28-29 | Input rác không throw | ✅ Sống |
| 44-47 | 6 face · body class · hp · `imported` flag | ✅ Sống |
| 48-50 | Không `NaN`/`undefined` trong face nào | ✅ Sống — và **quan trọng hơn trước** (F5b có phép chia; `R` không được là 0) |
| **51-52** | *"face map theo class của PART, không phải body class"* — assert `=== SLOT_CLASS_TEMPLATE.eyes.bug.t` | 🔴 **Chết.** *Ý định vẫn đúng và phải giữ*; viết lại thành: `partKey` của part đó dùng `part.class`, không `axieData.class` |
| **62-64** | Origin value × `ORIGIN_TIER3_MULT` | 🔴 **Chết.** Thay bằng: part secret-class → signature face của nó (§3.10), hoặc `bucket X` |
| **65** | Origin rarity ≥ 3 | 🔴 **Chết.** Mới: secret signature `r=3`; Origin(α) thường `r=1`. Xem E12 mục 3 |
| **74-76** | `specialGenes` value × 1.3 | 🔴 **Chết.** Thay bằng `B += 0.6` (F1) — và test dùng `'000000'` làm case *có* gene, vốn là **sai** (E16) |
| **77** | `specialGenes` rarity ≥ 1 | 🟡 **Chết như đang viết** (vì `'000000'` giờ là falsy), nhưng luật `r+1` vẫn tồn tại. Viết lại với giá trị `specialGenes` thật |
| **87-89** | Origin + specialGenes nhân dồn theo thứ tự | 🔴 **Chết.** Không còn nhân dồn — F1 là **cộng ngân sách rồi trần 10.2** |
| 90 | Giá trị nhân dồn không overflow/NaN | ✅ Ý định sống |
| 93-97 | < 6 part → pad blank | ✅ Sống |
| 99-101 | > 6 part → truncate | 🟡 Sống, nhưng phải **thêm** assert sort `SLOT_ORDER` (E2) |
| 103-105 | 0 part → 6 blank | ✅ Sống |
| 107-108 | `class`/`parts` = null | ✅ Sống |
| 111-113 | Slot lạ (`'Wing'`) không crash | 🟡 Sống nhưng **kết quả đổi**: giờ ra `BLANK` thay vì face Beast·Mouth (E3) |

Tổng: **6 check chết hẳn, 4 check cần viết lại, 11 check sống nguyên.** Lưu ý lại: vì `NAMES` ở `:9` import symbol đã bị xoá, file **không chạy được chút nào** cho tới khi sửa dòng đó — nên đây là công việc bắt buộc cùng lúc với thay `axieToDie`, không phải việc dọn sau.

Thêm 2 fixture trong test cũ cần biết: `:36` dùng part `'Owl'` (Bird·Ears) — **không tồn tại** trong catalog thật → nó trở thành case E1 (fallback). `:70, :82` dùng `specialGenes: '000000'` → E16. Cả hai là fixture **tốt** để giữ, chỉ cần đổi assertion.

### 6d. Tương tác hệ thống — cái đã kiểm, và một thiếu sót đã lượng hoá

| Hệ | Quan hệ | Đã kiểm |
|---|---|---|
| `PASSIVE` (6 class engine) | Doc này định giá keyword theo passive (F5) | ✓ 6/6 class có surcharge, hoặc lý do rõ vì sao không |
| `buildUnit` mutation/rune/oc (`engine.js:49-53`) | Áp lên `u.die[m.idx]` | ✓ Cần deep-clone (AC-2). `oc` nhân `f.v` với `f.v>0` → face `debuff` (`v=0`) **miễn nhiễm** với Overclock. Đó là một bất đối xứng đã tồn tại, không do doc này tạo ra, nhưng nó **cộng thêm** vào thiếu sót dưới |
| **`RESONANCE`** (`data.js:490`) | `types: ['dmg','shield','heal','poison','mana']` | 🔴 **THIẾU SÓT ĐÃ LƯỢNG HOÁ**: `debuff`/`buff`/`summon` **không bao giờ** resonate được (`findResonanceIdx`, `engine.js:403`). Nghĩa là mọi face `debuff` mất vĩnh viễn cơ hội ×1.15 mà F5b **không định giá**. Ảnh hưởng **17 variant** (`beast.eyes` A-D, `bug.eyes` A-D, `bird.eyes` A-D, `bird.back.C`, `bird.ears.E`) + 4 signature (`Little Peas`, `Scar`, `Zeal`, `Balloon`). Cộng với việc `oc` cũng bỏ qua chúng, face `debuff` bị **hai** đường buff bỏ rơi. **Remediation** (§7 knob `R_DEBUFF`): giảm `R[debuff]` 2.60 → **2.35** ⇒ kwBudget +10.6% ⇒ một số `N` tăng 1. **Không áp trước** — phải đo bằng `tools/sim.js` (AC-11b) rồi mới chọn, vì áp bừa sẽ làm debuff quá mạnh ở bucket P |
| `ARCH` / `archScore()` (`src/engine.js:880`) | Tracker archetype tính động theo keyword đội hình | 🔴 **PHỤ THUỘC ĐANG ĐỔI — đừng assert trên `ARCH` 10 archetype hiện tại.** Xem 6d-bis dưới. Về phủ: 158 variant phủ 8/10 archetype; **thiếu `burn` và `crit` gần như hoàn toàn** (chỉ `aqua.horn.C`, `bird.horn.C` có `crit`; **không variant nào** có `burn`). INFERNO chỉ dựng được từ `FACE_POOL` drop + relic, không từ import. Chấp nhận có ý thức — `burn` halve mỗi lượt (`tickStatus` :658) nên nó là archetype phụ thuộc relic |

**6d-bis. `archScore()` đang bỏ rơi HOÀN TOÀN class Beast — phụ thuộc, không phải việc của doc này**

Đã verify (phát hiện từ pass thiết kế relic song song): `archScore()` khởi tạo `sc` từ **chỉ các khoá của `ARCH`**, rồi guard mọi lần cộng bằng `if(sc[a] != null)`. Nhưng `PASSIVE.beast.a === 'exec'`, và **`exec` không có trong `ARCH`** (`src/data.js:31-49` có 10 khoá: `poison burn shield mana pierce crit growth summon aoe thorns`).

⇒ **Mọi hero Beast trong roster góp 0 vào mọi archetype score**, và hai relic gắn `a: 'exec'` cũng vậy. Đó là một class trên sáu bị vô hình với tracker.

Ba điều cần nói rõ:

1. **Đây KHÔNG phải lỗi do doc này gây ra**, và cũng không phải doc này sửa. Hệ relic đang thêm `exec` làm archetype **thứ 11**. Doc này chỉ ghi nhận phụ thuộc.
2. **Nhưng nó ảnh hưởng thiết kế Beast của doc này.** §3.11 BEAST cố ý xây quanh FERAL/`exec` (`beast.mouth.E` = `dmg · exec`, `CLS_SURCHARGE[beast]['exec'] = +0.80`, `beast.eyes` toàn bộ là `debuff` để setup FERAL). Toàn bộ trục bản sắc đó **hiện không được tracker nhìn thấy**, nên một người chơi dựng đội Beast-import không nhận được tín hiệu archetype nào — mất đúng phần feedback mà §2 khoản 5 (Competence) dựa vào.
3. **Ràng buộc lên AC của doc này**: **không AC nào ở §8 được assert số lượng archetype, tên khoá `ARCH`, hay giá trị `archScore` cụ thể.** Đã kiểm: `AC-11b` (hiệu chuẩn `R[debuff]`) và `AC-10` (AEGIS) đều đo **winrate và damage share**, không đo `archScore` — nên cả hai an toàn với việc `ARCH` lên 11 khoá. Nếu sau này ai thêm AC dựa trên `archScore`, nó phải đọc `Object.keys(ARCH).length` động, không hardcode 10.
| `nftHpBonusPct` (`engine.js:37`) | Ngoại lệ NFT thứ hai, cộng dồn với scarcity | ✓ Đã gộp vào `H'` (§3.9f, F9). **Nếu bỏ bước này, L3 under-corrects** |
| `CURVE.budget` / `mkMonster` / `mkBoss` | Sức mạnh địch theo wave | ✓ Không đổi. Nhưng import mạnh hơn ⇒ TTK giảm ⇒ AC-10 phải đo winrate |
| `faceScale()` (`engine.js:107`) | Engine tự dùng `pow(s,0.50)` poison, `pow(s,0.45)` buff/debuff | ✓ **Xác nhận độc lập** `R[poison]=1.55` và `R[debuff]=2.60` đúng hướng nén |

### 6e. GDD phải sửa downstream

| Doc | Việc |
|---|---|
| `design/gdd/part-tier-system.md` | Superseded phần lớn (§0). Nên thêm banner trỏ sang doc này ở đầu file, giữ §1/§3 (nguồn dữ liệu, hiệu chuẩn pDPS) làm tham chiếu |
| `design/gdd/leaderboard-system.md` | Thêm Collector board `lbc:*` với `SBC_CAP` + handicap `H'`. Bảng "Standard/Collector" hiện có **mô tả một thứ chưa ship** — cập nhật theo §3.9b, và ghi rõ GATE provenance (§3.9e) |
| `design/gdd/economy-progression.md` | §10.2b không cần đổi (quyền truy cập không đổi). **Cần thêm**: đền bù E15 nếu chọn phương án C — đó là một faucet Shard mới, phải qua `economy-designer` |
| `design/gdd/bloodline-system.md` | Bản sắc class theo keyword giờ suy được từ 158 variant. Nên đối chiếu lại §5.4 với phân bố thật (kiểm chứng độc lập, giống cách `part-tier-system.md` §4 đã làm) |
| `design/gdd/game-concept.md` | Pillar "Deterministic" — thêm ghi chú `chain:N` là ngẫu nhiên-trong-seed (E6), và yêu cầu UI nói rõ |
| `design/gdd/axie-body-parts.md` | **Không sửa** — là nguồn input. Nhưng cần product owner xác nhận 4 lệch chính tả ở E9 |
| `docs/architecture/adr-0001-…` | Cần ADR mới hoặc mở rộng: Collector board đòi **wallet signature + on-chain read**, tức phụ thuộc hạ tầng mới hẳn so với ADR-0001 |

**GDD được tham chiếu — đã kiểm tồn tại trên đĩa (`Glob`, 2026-09-03, commit `438e944`)**:

✓ `part-tier-system.md` · ✓ `leaderboard-system.md` · ✓ `economy-progression.md` · ✓ `bloodline-system.md` · ✓ `game-concept.md` · ✓ `axie-body-parts.md` · ✓ `combo-decision-memo.md` · ✓ **`design/quick-specs/formation-resonance-2026-09-01.md`** · ✗ `design/gdd/systems-index.md` (thật sự không tồn tại — doc này chưa vào index nào)

> **Sửa lỗi revision 1 (defect 18 của review).** Bản trước đánh dấu `formation-resonance-2026-09-01.md` là `✗ chưa kiểm` và ghi *"nếu thiếu thì 6d dòng RESONANCE không có doc gốc để đối chiếu"*. **File tồn tại** (`design/quick-specs/` có đúng 3 file: `formation-resonance-2026-09-01.md`, `milestone-ledger.md`, `import-axie-variants-2026-09-03.md`), và `src/data.js:487-489` trỏ thẳng tới nó bằng comment.
>
> Việc đánh dấu sai **làm nhẹ đi phát hiện của chính doc này**: §6d kết luận `debuff`/`buff`/`summon` không bao giờ resonate được, ảnh hưởng 17 variant + 4 signature, và đề xuất remediation `R[debuff]` (`K10`). Với `✗ chưa kiểm`, kết luận đó đọc như một suy đoán chưa xác minh. Với file có thật và `RESONANCE.types` đọc được trực tiếp ở `src/data.js:490`, nó là **một phát hiện đã lượng hoá, có spec gốc để đối chiếu** — tức nó là mục cần `systems-designer` xử lý, không phải mục cần ai đi xác minh trước.
>
> **Việc còn lại (thật)**: `systems-index.md` không tồn tại, nên doc này chưa nằm trong bất kỳ index nào. Đó là việc cho `producer`, không phải blocker thiết kế.

---

### 6f. `tools/gen_faces.mjs` — spec đủ để build

**Vì sao tool này là BLOCKING, không phải tiện ích.** Ba defect độc lập mà review tìm được — hàng TOTAL §3.5b sai cả 3 cột (defect 1), danh sách monotone sai 3/10 mục (defect 6), một ô lệch công thức (defect 7) — có **cùng một nguyên nhân gốc**: ~474 ô số suy diễn duy trì bằng tay trong Markdown, tự kiểm bằng cách designer đọc lại. Mọi defect trong số đó **lọt qua các kiểm tra mà doc tự đặt ra**, vì các kiểm tra đó cũng làm bằng tay. Sau revision 2, doc **không còn chứa** giá trị runtime — nên không có tool này thì không có số để implement.

**Phân chia sở hữu — bất biến của cả kiến trúc này:**

| Loại | Ai sở hữu | Ví dụ |
|---|---|---|
| **Design input** — quyết định thiết kế thật | **DOC**, sửa tay, có lý do ghi kèm | §3.11 cột `t · k` · §3.12 gán 204 part · §3.3a/b/§3.10 signature · hằng số §4 (F1, F3, F4, F5) · `COH`, `SP`, `SlotMod` |
| **Derived data** — output công thức | **GENERATOR**, không ai sửa tay | cột `v` theo bucket · `monotoneLifts[]` · `repairLog[]` · `clampFloor[]` · `distinctEngineFaces` · totals §3.5b |

**Inputs** (đọc, không ghi):
```
docs/axiedice-source/economy/parts_full_source.json   → 285 identity + trường `stage` (F1 bucket)
design/gdd/part-skill-identity.md                     → parse §3.11 (t·k), §3.12 (gán), §3.3a/b, §3.10
assets/data/part_faces_tuning.json                    → mọi knob §7 (KHÔNG hardcode — coding-standards.md)
src/data.js                                           → FACE_POOL, FACE_NAMES, BP_FACES, HEROES (đối chiếu)
```

**Outputs**:
```
assets/data/part_faces.json          ← runtime data. Nguồn sự thật của mọi số suy diễn
assets/data/part_faces.ref.json      ← output profile tham chiếu (B[C]=6.00), cho AC-7
```

Shape của `part_faces.json`:
```jsonc
{ "schema": 1, "engineVersion": "<khớp src/engine.js:9>", "profile": "production",
  "constants": { "B_C": 2.80, "S": {...}, "SG_BONUS": 0.28, "B_CAP0": 4.76,
                 "GENE_STEP": 0.53, "GENE_MAX": 6, "B_CAP_RUN": 7.20,
                 "KW_SCALE": 0.4667, "SIG_IMPORT_SCALE": 0.4667, "COH": {...} },
  "familyVariant":  { "beast": { "mouth": { "A": { "t":"dmg", "k":[], "v":{"C":3,"O":4,"P":5} }, … } } },
  "signatureFace":  { "beast|mouth|Cub": { "p":"mouth","t":"dmg","v":3,"k":[],"r":0,"src":"sig" }, … },
  "partVariant":    { "beast|mouth|Foxy": "E", … },                       // 204 khoá
  "scarcityBucket": { "beast|mouth|Foxy": "O", … },                       // 285 khoá
  "manifest": { "monotoneLifts": [ {"variant":"aqua.ears.C","bucket":"P","from":2,"to":3} ],
                "repairLog":    [ {"variant":"bug.back.A","bucket":"C","bumps":1,"collidedWith":"Snail Shell"} ],
                "clampFloor":   [ {"variant":"bird.tail.B","bucket":"C","raw":-0.94} ],
                "totals": { "nSig":63, "nC":115, "nO":74, "nP":15, "nX":18, "variants":158,
                            "spares":11, "spareList":[…], "designedFaces":239, "reachableFaces":228,
                            "distinctEngineFaces":<đo> } }
}
```

**Pipeline** (tất định tuyệt đối — thứ tự duyệt cố định: class asc → `SLOT_ORDER` → chữ cái variant → `C,O,P`):
```
1. loadCatalog()      → 285 identity, bucket theo F1
2. loadDesign()       → parse §3.11/§3.12/§3.3a/§3.3b/§3.10 từ Markdown
3. checkDesign()      → R1, R5, R6, §3.7a direction law, E7 cantrip law, whitelist keyword §3.7
4. computeVariants()  → F2 (B_eff) → F5a (TYPE_COST) → F4 (KW × KW_SCALE) → F5b → F6 (monotone
                        by construction, ghi monotoneLifts[]) ; ghi clampFloor[] mỗi lần max(1,·) cắn
5. REPAIR()           → §3.5d, ghi repairLog[] ; HARD FAIL nếu >2 bump hoặc >8 collision
6. computeSignature() → v_pool × SIG_IMPORT_SCALE ; type/k/r copy nguyên xi
7. computeTotals()    → nC/nO/nP/spares/distinctEngineFaces
8. emit()             → part_faces.json (+ .ref.json nếu --profile=reference)
```

**Cờ**:
| Cờ | Tác dụng |
|---|---|
| `--profile=production` *(mặc định)* | `B[C] = 2.80`. Sinh `part_faces.json` |
| `--profile=reference` | `B[C] = 6.00`. Sinh `.ref.json` để AC-7 so với cột §3.11 |
| `--check` | Không ghi. So output với snapshot đã commit, exit≠0 nếu lệch. **Đây là cờ CI chạy** |
| `--check-citations` | Quét mọi `file.js:NNN` có kèm tên symbol trong doc; đọc file, tìm symbol, fail nếu lệch >±3 dòng (AC-33) |
| `--refresh-catalog` | Nhập lại `parts_full_source.json`, in danh sách `partKey` mới/mất (runbook E1) |

**Invariant checks — HARD FAIL build, không cảnh báo:**

| # | Kiểm | Neo vào |
|---|---|---|
| I1 | `nC + nO + nP === 204` | AC-6b |
| I2 | `nP === 18 − |Prime ∩ Signature| === 15` | AC-6b, §3.4 |
| I3 | `keys(SIGNATURE_FACE) === 81` · `keys(PART_VARIANT) === 204` · giao rỗng · hợp = 285 | AC-3 |
| I4 | R1: trong mỗi family, không hai part cùng bucket cùng variant | AC-4a |
| I5 | R6: trong mỗi family, không hai variant cùng `(t, sortedKeys)` | AC-4a *(bất biến độc lập ngân sách)* |
| I6 | R5 sau REPAIR: 0 collision signature↔variant | AC-4c |
| I7 | Monotone `v(C) < v(O) < v(P)` cho cả 158 variant | AC-14 |
| I8 | §3.7a direction law trên cả 239 face (nhớ `poison` ở nhóm 3) | AC-5 |
| I9 | E7 cantrip placement law | AC-5b |
| I10 | Mọi keyword ⊆ whitelist §3.7; `shieldself` xuất hiện 0 lần | AC-15 |
| I11 | Không `NaN`/`undefined`/`Infinity` ở bất kỳ ô nào — **kiểm này bắt được defect 3** (`cost('growth')` thiếu ⇒ `NaN` ở 12 ô) | AC-8 |
| I12 | Profile tham chiếu: 474/474 ô khớp cột §3.11; 472 ô ≤12%; đúng 2 ô ≤20% | AC-7 |
| I13 | `spares === 11` **và** tập 11 chuỗi khớp §3.12 | AC-6 |
| ~~I14~~ | ❌ **THU HỒI (2026-09-03)** — `B_CAP0 < B[C] + GENE_STEP × GENE_MAX`, tức *tiền mua được < chơi kiếm được*. Bất đẳng thức F1a đã bị product owner thu hồi cùng quyết định pay-to-win (F1b-α). `B_CAP0` nay định nghĩa lại là `B[C] × S_MAX × G_MAX = 6.71`, **tất yếu vi phạm** bất biến cũ. **KHÔNG được để I14 trong danh sách hard-fail của §6f** — generator sẽ báo build RED vĩnh viễn vì một mâu thuẫn nội bộ của doc, không phải vì dữ liệu sai. *(Phát hiện bởi chính `gen_faces.mjs` lần chạy đầu — đúng công dụng của nó.)* | ~~K5~~ |
| I15 | `SBC_CAP ≤ 0.125 × 30 / (0.267 × k / 2.0)` — nguyên tắc handicap ≤ −20% (§3.9c-bis) | K16, K17 |

`I15` là loại kiểm mà revision 1 không có bất kỳ tương đương nào: nó bảo vệ **lập luận thiết kế**, không chỉ tính nhất quán số học. *(`I14` từng cùng nhóm này nhưng đã thu hồi — xem trên. Bài học đáng giữ: một bất biến bảo vệ lập luận thiết kế phải bị thu hồi **cùng lúc** với lập luận đó, nếu không nó biến thành build gate đỏ vĩnh viễn. `gen_faces.mjs` bắt được đúng ca này ngay lần chạy đầu tiên.)*

**Chạy ở đâu**: `--check` và `--check-citations` chạy trong CI mọi PR. `gen` chạy tay khi đổi design input hoặc knob, và output **được commit**. Snapshot commit là cái AC-7d so — nên mọi thay đổi số đều xuất hiện trong diff của PR, đọc được, review được. Đó là thứ revision 1 không có: 474 ô đổi trong đầu designer mà không để lại dấu vết nào.

---

## 7. Tuning Knobs

Tất cả phải nằm trong `assets/data/part_faces_tuning.json`, **không hardcode** (yêu cầu `.claude/docs/coding-standards.md`).

| # | Knob | Hiện tại | Dải an toàn | Loại | Trade-off |
|---|---|---|---|---|---|
| K1 | `B[C]` — ngân sách Classic | **6.0** | 5.5 – 6.5 | curve | Neo của cả hệ. Đổi nó là đổi **mọi** face. Đang khớp `SIG_BUDGET[0]` và tầng r0 `FACE_POOL` — đổi sẽ phá hiệu chuẩn F2. **Đừng chạm trừ khi rebase toàn bộ** |
| K2 | `B[O]` — ngân sách Origin(α) | **7.6** | 6.6 – 8.5 | curve | Chase value của 75 part α. Cao hơn → α đáng săn hơn nhưng khoảng cách F2P/whale rộng ra. Trần 8.5 = `SIG_BUDGET[1]`; vượt nó thì một part α thường mạnh bằng một signature Rare |
| K3 | `B[P]` — ngân sách Prime | **9.6** | 8.0 – 11.0 | curve | Chase value đỉnh của 18 part. Trần 11.0 giữ `C→P < 1.85×`. Đây là knob **duy nhất** mà product owner nên chạm khi muốn "làm part hiếm đáng giá hơn" |
| ~~K4~~ | ~~`B[X]`~~ — **THU HỒI** | — | — | — | 🚫 **Không còn là knob** (defect 12). `B[X]` không được code nào đọc: cả 18 part secret-class là signature (§3.10) nên bucket X không bao giờ đi qua F1–F6. Tuning một hằng số chết là đo lường ảo. **Nửa còn sống của cùng hàng đó là `S(X) = 1.467`** — nó là input của §3.9d và của `SP[X] = 2`, và nó thuộc `K18`, không phải K4 |
| K5 | **`B_CAP0`** — trần thu thập | **4.76** | 4.20 – 5.60 | gate | Định nghĩa trần power của **tiền**. ⚠️ **Lý do tồn tại đã đổi (2026-09-03)**: sau quyết định pay-to-win, đây **không còn** là rào công bằng ranked — nó chỉ còn là rào **TTK-legibility**, giữ sức mạnh import ở mức hợp lý so với `CURVE.budget`/`mkMonster` để time-to-kill không vỡ. Ràng buộc cũ `B_CAP0 < B[C] + GENE_STEP × GENE_MAX` đã bỏ cùng `PLAY_MARGIN_MIN`/`I14`/`I22` |
| K5b | **`B_CAP_RUN`** — trần cả run | **7.20** | 6.00 – 8.40 | gate | 🆕 Trần power của **chơi**. 7.20 cho Prime+SG ở gene 6 đạt 1.15× hero tier-3 — mức tối đa chấp nhận được, và chỉ đạt bởi cấu hình hiếm nhất trong game (6 part Prime cùng class + special gene). Hạ xuống 6.00 sẽ làm Origin và Prime **hội tụ về cùng một giá trị** ở gene 6 (cả hai kẹp trần) và xoá chase value cuối run — đó là cận dưới thật, không phải cận dưới thẩm mỹ |
| K23 | **`GENE_STEP`** | **0.53** | 0.35 – 0.75 | curve | 🔴 🆕 **Knob đầu tiên cần chạm nếu E15b sim gate đổ.** Nó định nghĩa *hình dạng* đường tăng power trong run của Axie import (`B[C] + 0.53×g`), so với hero (`level`: 2.53→4.11→6.39). 0.53 cho thuần Classic ở gene 6 = 0.95× hero tier-3. Chưa được đo lần nào — `B[C]` đã hiệu chuẩn 2 lần độc lập (F2) nên **đừng chạm `B[C]` trước** |
| K24 | **`THORNS_CAP`** | **8** | 6 – 12 | gate | 🔴 🆕 Remedy engine E10b R-B. **8 là no-op với mọi dice hero hiện tại** (`HEROES.reptile3` cao nhất `thorns:4`), nên nó chỉ có hiệu lực ở vùng degenerate. Đây là knob làm cho việc *định giá* `thorns` (K11) trở thành đúng thay vì vô nghĩa — không có trần, `thorns` vô hạn theo số lượt và không giá hữu hạn nào đúng (E10a) |
| K25 | **`CoherenceMod[purity]`** | **0.780/0.757/0.733/0.710/0.686/0.663/0.640** *(retuned 2026-09-03; trước: 1.00/0.97/0.94/0.91/0.88/0.85/0.82)* | scale toàn thang ×0.70 – ×1.00 | curve | 🔴 🆕 §3.4b. **Đây là knob thật sự điều khiển sức mạnh Axie import**, không phải K23 hay K1 — nó là knob DUY NHẤT chạm cả `maxHp`, mà lợi thế của import là **sinh tồn** chứ không phải giá trị mặt (2.50 vs hero 2.53 = 0.989×). Đo được: ×0.78 đưa winrate đội 5-vault 49.3% → **34.0%** trong khi hero giữ nguyên **20.0%**. Luôn scale **cả 7 bậc và `COH_FLOOR_SECRET` cùng một hệ số** — sửa riêng bậc 6 sẽ đảo thang (purity 5 hoá ra hơn purity 6) |
| K26 | **`COH_FLOOR_SECRET`** | **0.91** | 0.88 – 1.00 | gate | 🆕 §3.10. Sàn coherence cho die có ≥1 part bucket X. Tồn tại vì Axie Dawn/Dusk/Mech **bắt buộc** lai (Dawn không có part horn nào — E14), nên phạt chúng là phạt một ràng buộc dữ liệu, không phải một lựa chọn. Đặt = 1.00 sẽ miễn hẳn; 0.91 giữ một mức phạt nhẹ để die toàn-secret không vừa được coherence đầy vừa được 18 face r3 |
| K27 | **`SIG_IMPORT_SCALE`** | **0.4667** | — (**suy diễn**) | — | 🆕 §3.3. **Không phải knob tự do**: nó *bằng* `B[C]/B_REF` theo định nghĩa. Liệt kê ở đây để không ai tune nó riêng — tune nó lệch khỏi `B[C]/B_REF` sẽ tách thang signature khỏi thang variant và tái tạo đúng vấn đề mà §3.3 sửa |
| ~~K6~~ | ~~`SG_BONUS` cộng phẳng +0.6~~ | — | — | — | ❌ **BỎ (revision 3)**. Cờ nhị phân cộng phẳng đã bị thay bằng thang 8 bậc có thứ tự `G(tier) = 1 + SG_STEP × tier` (§3.4a). Knob thay thế: **K28 `SG_STEP` = 0.071**. Lý do đổi: cộng phẳng đáng 10% trên part Classic nhưng chỉ 6.25% trên Prime — tức yếu đi đúng nơi gene đặc biệt hay xuất hiện nhất |
| K7 | `SlotMod[*]` | 1.00/1.10/1.05/0.95/1.00/1.00 | ±0.10 mỗi slot | curve | Hiệu chuẩn ngược từ `FACE_POOL` r0 (F2, 6/6 khớp). Đổi sẽ phá bằng chứng hiệu chuẩn — **đổi thì phải chạy lại F2** |
| K8 | `R[poison]` | **1.55** | 1.3 – 1.9 | curve | Poison là bậc hai (`v(v+1)/2`). Thấp hơn → poison value cao hơn → PLAGUE lệch mạnh. Đối chứng: `faceScale` engine dùng `pow(s,0.50)` |
| K9 | `R[mana]` | **2.25** | 1.8 – 2.8 | curve | Độ phân giải thô của mana. Thấp hơn → mana value cao hơn nhưng family `ears` mất tính đa dạng số (§3.11 ghi chú aqua·ears) |
| K10 | **`R[debuff]`** | **2.60** | **2.20 – 2.60** | curve | 🔴 **Knob cần đo trước tiên.** 2.35 là remediation cho thiếu sót RESONANCE (6d). Thấp hơn → debuff mạnh hơn, bù cho việc không resonate được và miễn nhiễm `oc`. **Rủi ro**: `vulnerable:N` nhân dmg toàn party ×1.5 nên nó siêu tuyến tính — 2.20 có thể tạo degenerate |
| K11 | `KW['thorns:N']` | **0.70/stack** | 0.70 – 1.10 | curve | 🔴 `thorns` **không bao giờ giảm** (E10). Đây là knob chống degenerate chính. Tăng nếu sim cho thấy build AEGIS thắng bằng cách không làm gì |
| K12 | `CLS_SURCHARGE[reptile]['thorns:N']` | **+0.60** | 0.4 – 1.2 | curve | Cùng vấn đề E10 nhưng riêng cho SCALES (thorns + poison 1) |
| K13 | `CLS_SURCHARGE[bird]['aoe']` | **+1.40** | 1.0 – 2.2 | curve | TALON cấp Pierce miễn phí cho mọi `aoe` Bird (`:466`). Nếu TEMPEST bird quá mạnh, đây là knob |
| K14 | `AOE_KWB` — hệ số aoe trên face `v=0` | **0.55** | 0.45 – 0.70 | curve | Định giá `aoe` cho `buff`/`debuff`. Ảnh hưởng 4 variant + `Balloon`, `Little Peas` |
| K15 | `V(class, slot)` — số variant/family | 4 – 6 (§3.5b) | 4 – 8 | gate | Tăng = đa dạng hơn, nhưng **công authoring tuyến tính** và mỗi variant mới phải qua R1+R5. Trần 6 là quyết định product owner |
| ~~K16~~ | ~~`SBC_CAP`~~ | — | — | — | ❌ **BỎ (2026-09-03)**. Trần scarcity đội hình đã bỏ cùng toàn bộ cân bằng hoá — xem `F1b-α`, §3.9, F9. Không còn knob nào ở đây |
| ~~K17~~ | ~~`k` — hệ số handicap~~ | — | — | — | ❌ **BỎ (2026-09-03)**. Handicap divisor đã bỏ; `scoreFinal = rawScore`. Xem F9 |
| K18 | `SP[bucket]` — điểm scarcity | C0 / O1 / P3 / X2 | mỗi bậc 0 – 5 | gate | `P=3` cố ý siêu tuyến tính so với power (bậc thang giá vs tuyến tính power) → spam Prime là kém hiệu quả. Đây là balancing loop; hạ P xuống 2 là bỏ nó |
| K19 | `SIG_BUDGET[r]` | 6.0/8.5/12.0/17.0 | ±15% mỗi bậc | curve | = `TIER_BUDGET` cũ. Đổi sẽ **không** ảnh hưởng 50 face legacy (miễn kiểm) nhưng đổi dải hợp lệ của 31 face Addendum+Secret |
| ~~K20~~ | ~~`E15_COMPENSATION`~~ — **XOÁ** | — | — | — | 🚫 **Không còn tồn tại.** Nó tune một công thức đền bù giải một vấn đề không có (E15 đã viết lại: nền tăng 113%, không phải giảm), và **product owner đã bác bỏ đền bù**. Không còn faucet Shard mới → §6e không còn dòng propagate sang `economy-progression.md` |
| K21 | Dải kiểm ngân sách variant | **±12%** | 8% – 20% | gate | Chặt hơn = bảo đảm ngang giá mạnh hơn nhưng REPAIR (§3.5d) dễ HARD FAIL. 12% được chọn vì bump +1 trên `v≥9` vừa khít |
| K22 | Ngưỡng `mkReward` ưu tiên `cls` | **pool ≥ 3** | 2 – 6 | feel | §3.8 mục 2. Cao hơn = ít khớp class hơn nhưng pool drop không co lại |

**Knob KHÔNG được đổi mà không chạy lại toàn bộ**: K1, K7 (chúng là hiệu chuẩn F2, không phải tuning).
**Knob cần đo trước khi ship**: **K10** (`R[debuff]`, AC-11b) · **K11 + K24** (thorns, AC-10) · **K23** (`GENE_STEP`, AC-28 + AC-27) — **4 knob**, tất cả đánh 🔴. *(K16 và K17 đã bỏ cùng handicap, 2026-09-03 — từ 6 xuống 4.)*

**Knob là SUY DIỄN, không được tune riêng** (tune lệch sẽ phá một bất biến, không chỉ đổi cân bằng): `K27` (`SIG_IMPORT_SCALE` = `B[C]/B_REF`) · `KW_SCALE` (= `B[C]/B_REF`) · `SG_BONUS` (= `0.6 × KW_SCALE`) · `B(bucket)` (= `B[C] × S(bucket)`).

**Đổi `B[C]` (K1) là thao tác một-dòng-nhiều-hệ-quả**: nó tự động dịch `KW_SCALE`, `SG_BONUS`, `SIG_IMPORT_SCALE`, `B_CAP0`, và cả 474 ô ở profile production. Đó là **thiết kế có chủ ý** (F1) — nhưng nó nghĩa là mọi lần đổi `B[C]` phải chạy lại `gen_faces.mjs` + AC-7d + AC-27 + AC-28. Không có đường đổi `B[C]` "nhẹ".

---

## 8. Acceptance Criteria

Mọi AC dưới đây **kiểm được bằng máy**. Chủ nhà: `tools/t_partskill.mjs` (mới) trừ khi ghi khác. Không có AC nào chứa "feels", "balanced", "works correctly".

> **Vì sao grep bị loại khỏi AC-1** (defect 15 của review). Grep `Math.random|Date|RNG|rnd|ri\(|pick\(` trên **thân hàm** `axieToDie`/`resolveFace` không phải bằng chứng purity, theo hai chiều:
> - **Âm tính giả**: nó không thấy được lời gọi **bắc cầu**. `resolveFace` gọi `applyPartVariant` → gọi `hashPartIdentity`; nếu bất kỳ helper nào trong chuỗi đó chạm RNG, grep trên thân hàm gốc vẫn sạch. Với pipeline mới có `dieContext` + `resolveDie` + `geneKeywords`, độ sâu chuỗi gọi tăng lên, nên lỗ này **rộng ra**, không hẹp lại.
> - **Dương tính giả**: pattern `pick\(` khớp mọi identifier kết thúc bằng `pick` — `teamPick(`, `partPick(`, `lastPick(`. Một AC dương-tính-giả bị vô hiệu hoá bởi chính người bảo trì (ai cũng học cách bỏ qua nó), nên nó tệ hơn không có.
>
> Harness stub kiểm **đúng thứ ta quan tâm** (hàm không chạm nguồn không tất định) chứ không kiểm proxy văn bản của nó, và nó bắt được lời gọi bắc cầu ở mọi độ sâu. Nó cũng chạy nhanh hơn: 1995 lần gọi trên dữ liệu tĩnh, không I/O.

### Nhóm A — Tính đúng đắn cấu trúc (BLOCKING)

| AC | Assertion | Số cụ thể |
|---|---|---|
| **AC-1** | **Hành vi** (giữ nguyên): gọi `axieToDie(x)` **1000 lần** cùng `x` → `JSON.stringify` cả 1000 kết quả giống hệt; lặp với `mkRng(1)`, `mkRng(999)`, `mkRng(12345)` → vẫn giống hệt.<br>**Purity** (THAY grep bằng harness — xem AC-1b): stub `Math.random`, đóng băng `Date`, và fail nếu bị chạm | 1000 lần · 3 seed · 0 lần chạm |
| **AC-1b** | 🆕 **Purity harness thay cho grep.** Trước khi gọi `axieToDie`, thay `Math.random` bằng hàm `throw new Error('AC-1b: Math.random touched')`; thay `Date.now` và constructor `Date` bằng hàm throw; đóng băng `globalThis.performance.now`. Gọi `axieToDie` trên **cả 285 identity** (mọi part, mọi tổ hợp bucket/coherence/geneTier 0–6). Assert: **0 exception**, và mọi die hợp lệ. Khôi phục stub trong `finally` | 285 × 7 geneTier = 1995 lần gọi · 0 throw |
| **AC-2** | Với `x` có 2 part **cùng `partKey`**: `die[i] !== die[j]` (reference khác nhau) và `die[i].k !== die[j].k`. Mutate `die[0].v = 99` → `die[1].v` **không đổi** | 2 assert |
| **AC-3** | `keys(SIGNATURE_FACE).length === 81` · `keys(PART_VARIANT).length === 204` · giao hai tập khoá `=== 0` · hợp hai tập **phủ đúng** 285 identity của `parts_full_source.json` (không thừa, không thiếu) | 81 · 204 · 0 · 285 |
| **AC-4a** | Với **mỗi** family `(class, slot)`: gom tuple `(t, v, sortedKeys)` của mọi part **non-signature** trong family → số tuple distinct **=** số part. Tổng trên 36 family: **0 collision** | 0 / 204 |
| **AC-4b** | 4 `partKey` của `Nut Cracker` (beast: mouth/tail/eyes/ears) → 4 face **khác nhau** ở `(p,t,v,k,r)`. Lặp cho `Little Owl` (bird ×3), `Leaf Bug` (bug ×3), `Puppy` (beast ×3), `Tiny Dino` (reptile ×3), `Maggot`, `Nimo`, `Peace Maker`, `Foxy`, `Anemone`, `Oranda`, `Ranchu`, `Lotus`, `Turnip` | 15 nhóm · 0 collision nội nhóm |
| **AC-4c** | Sau REPAIR (§3.5d): **0 collision** signature↔variant trên toàn 36 family. Generator log **đúng 2** dòng `REPAIR`: `bug.back.A@C +1` và `beast.horn.B@O +1`. Nhiều hơn 2 → bảng §3.11/§3.12 đã lệch khỏi doc → **fail** | 0 collision · đúng 2 repair |
| **AC-5** | **kwPure Direction Law** (§3.7a). Với mọi 239 face: nếu `t ∈ {dmg, poison, debuff}` thì `k ∩ {thorns, regen, undying, enrage} === ∅`; nếu `t ∈ {shield, heal, buff}` thì `k ∩ {burn, poison, weaken, vulnerable, blind, stun, freeze} === ∅`; nếu `t ∈ {mana, summon}` thì `k ⊆ {cantrip, mana, rerollup, growth, decay, selfharm, vital, overflow}` | 0 vi phạm / 239 |
| **AC-5b** | **cantrip placement law** (E7). Mọi face có `cantrip` phải có `t ∈ {mana, heal, shield, buff, summon}` **hoặc** có `aoe` | 0 vi phạm |
| **AC-6** | Số variant không được part nào dùng **=== 11**, và tập đó khớp **chính xác** danh sách §3.12 (11 chuỗi) | 11 |
| **AC-8** | `resolveFace` **không throw** với 40 input rác: `null`, `{}`, `{name:null}`, `{type:'Wing'}`, `{class:'nonsense'}`, `{name:''}`, `{name:'X'.repeat(500)}`, `{type:123}`, `{class:[]}`, `{specialGenes:{}}`, … Mọi kết quả có `Number.isFinite(f.v)`, `f.v >= 0`, `Array.isArray(f.k)`, `f.r ∈ [0,4]` nguyên | 40 input · 0 throw |
| **AC-14** | Với **mọi** 158 variant: `v(C) < v(O) < v(P)` **nghiêm ngặt** (đúng do cấu trúc, F6). Khoản `v(O) <= v(X) <= v(P)` của revision 1 **đã bỏ** — nó assert trên tập rỗng vì không variant nào tồn tại ở bucket X (§3.4, defect 12). Thay bằng: `FAMILY_VARIANT` resolve ở bucket X phải **throw hoặc trả `null`**, không được âm thầm trả một face — để một part secret-class bị gán nhầm sang đường variant bị **bắt**, không bị làm tròn thành hợp lệ | 158 variant · 0 vi phạm · bucket X: 158/158 reject |
| **AC-15** | Union mọi keyword xuất hiện trong 239 face ⊆ whitelist 33 keyword đã verify implement (§3.7). Đặc biệt: `'shieldself'` **không xuất hiện** ở bất kỳ face nào | ⊆ 33 · 0 lần `shieldself` |

### Nhóm B — Ngân sách và số đếm (BLOCKING)

| AC | Assertion | Số cụ thể |
|---|---|---|
| **AC-7** | **Profile THAM CHIẾU (`B[C] = 6.00`).** Generator phải reproduce cột `C/O/P` của §3.11 **khớp từng ô**: `158 variant × 3 bucket = 474 ô`, `474/474` khớp chính xác (không dải %). Đồng thời assert `|B_hàm_ý − B_eff| / B_eff <= 0.12` với `B_hàm_ý = (v·R + KW + TYPE_COST)/SlotMod` cho **đúng 472 ô**, và `<= 0.20` cho **đúng 2 ô** (`bug.back.A`@C, `beast.horn.B`@O — hai ô REPAIR, §3.5d) | **474/474 khớp ô** · **472** ô ≤12% · **đúng 2** ô ≤20% |
| **AC-7d** | 🆕 **Profile PRODUCTION (`B[C] = 2.80`).** Output generator khớp `assets/data/part_faces.json` đã commit **byte-identical** (so JSON đã canonicalise khoá). Snapshot phải chứa và pin: `monotoneLifts[]`, `repairLog[]`, `clampFloor[]`, `distinctEngineFaces`. **Không** có dải % ở profile này (F6 giải thích vì sao) | 0 byte diff · 4 mảng manifest có mặt |
| **AC-7b** | Với 13 Addendum + 18 Secret = 31 signature: `|B_hàm_ý − SIG_BUDGET[r]| / SIG_BUDGET[r] <= 0.20`. Lệch lớn nhất phải là `Pincer` ở **+18%** (nếu có face nào lệch hơn → bảng đã lệch khỏi doc) | 31 face · max = Pincer +18% |
| **AC-7c** | 50 face legacy `FACE_NAMES` **được miễn** kiểm ngân sách, **nhưng** `(p,t,v,k,r)` của chúng phải **byte-identical** với `FACE_POOL` trước thay đổi. Diff `FACE_POOL[0..49]` cũ vs mới ⇒ chỉ được thêm field `cls`, không đổi/xoá field nào khác | 50 face · 0 thay đổi số |
| **AC-9a** | `count(FAMILY_VARIANT rows) === 158` · `count(SIGNATURE_FACE) === 81` · tổng face thiết kế `=== 239`. Phân rã theo class: variant beast 28 · aqua 26 · plant 27 · bird 26 · bug 27 · reptile 24 | 158 · 81 · 239 · 6 số |
| **AC-9b** | Resolve toàn bộ 285 identity → tập tuple `(cls, p, t, v, k, r)` distinct **=== 285**. Nếu < 285 → có collision chưa bắt được.<br>🔧 **Đã đổ ở 283 trước khi có `SIG_LIFT`** (generator, 2026-09-03): `Gill`/`Bubblemaker` và `Mavis`/`Robin` sập về cùng `v = 1` do `SIG_IMPORT_SCALE`. Sửa ở §3.3c — **phép chiếu**, không phải dữ liệu, nên `AC-7c` không bị nới | 285 |
| **AC-37** | 🆕 **`SIG_LIFT` — thang legacy không được sập bậc** (§3.3c). Gom 81 signature theo `(p, t, sortedKeys)`; trong **mỗi** nhóm, dãy `v` trên die import phải **tăng nghiêm ngặt** theo `v_pool`. Assert cụ thể: nhóm `ears·mana·cantrip` → `Gill = 1`, `Bubblemaker = 2`; nhóm `eyes·summon·cantrip` → `Mavis = 1`, `Robin = 2`, `Neo = 3`. Assert `max(lift) === 2` và `≤ SIG_LIFT_MAX = 3`. Assert **đúng 45/50** face legacy có `lift === 0` (luật chỉ chạm face thực sự đụng nhau).<br>**Bất biến độc lập `B[C]`**: chạy lại ở `B[C] ∈ {2.20, 2.80, 4.00, 6.00}` → thứ tự trong mọi nhóm vẫn nghiêm ngặt ở **cả bốn**; ở 6.00 thì `max(lift) === 0` (luật thành no-op). Đây là kiểm chống tái phát, không phải kiểm hai va chạm hôm nay | 2 nhóm · 5 face · lift ≤3 · 45 face lift 0 · 4 giá trị `B[C]` |
| **AC-9c** | 🔴 **VIẾT LẠI ở revision 3 — sàn `>= 76` bị XOÁ, thay bằng ĐẲNG THỨC CHÍNH XÁC.** Resolve cả 285 identity, gene 0, coherence 1.00, thu tập tuple **`(p, t, v, k)`** (bỏ `cls` — đây là face identity mà `doFace()` thật sự thấy). Assert `distinctEngineFaces === 285` ở **CẢ HAI** profile (tham chiếu `B[C]=6.00` **và** production `B[C]=2.80`) — không phải khớp snapshot, mà khớp **hằng số 285**, vì sau R7+R8 con số này **không còn phụ thuộc `B[C]`** (§3.13c). Kèm phân rã theo slot, mỗi slot một assert riêng để thông báo lỗi chỉ đúng chỗ: mouth **41** · horn **54** · back **52** · tail **52** · eyes **40** · ears **46** | `=== 285` ở 2 profile · 6 assert slot |
| ~~**AC-9c-base**~~ | ⛔ **THU HỒI.** Nó đếm distinct-face của các bộ keyword *trước* pass re-author, và pass đó đã thay thế chính chúng — **không cấu hình generator nào tái tạo được con số này nữa**. Phép đo hợp lệ cuối: **198** tham chiếu / **190** production trên bảng tiền hợp nhất (đếm tay của tôi: 201, sai, và không mô tả cấu hình nào có thật — nó trộn tiền-REPAIR và hậu-REPAIR giữa các slot).<br>**Thay bằng `AC-9c`**, đo được và đang xanh: `=== 285` ở **cả hai** profile. Ràng buộc kế thừa từ mục này: mọi AC đếm face phải nêu **profile** *và* **REPAIR đã chạy chưa** — thiếu một trong hai thì con số không falsifiable | *(thu hồi)* |
| **AC-9d** | 🆕 **Hiện trạng ĐANG CHẠY, để so sánh không bị trôi.** Đếm tuple `(p,t,v,k)` distinct của `SLOT_CLASS_TEMPLATE` (36 entry) → assert **`=== 19`**. Phân rã: eyes 5 · ears **1** · mouth 3 · horn 3 · back 3 · tail 4. Đây là con số "trước" của headline `19 → 285`; nếu ai sửa `SLOT_CLASS_TEMPLATE` trước khi nó bị xoá, assert này đổ và headline phải được tính lại thay vì im lặng sai | `=== 19` · 6 số |
| **AC-34** | 🆕 **R7 — slot-wide keyword-set uniqueness** (§3.5c). Với mỗi slot, gom `(t, sortedKeys)` của **mọi reachable variant template** → số phân biệt **=== số template**: mouth **24** · horn **27** · back **27** · tail **22** · eyes **21** · ears **26**, tổng **147/147**. Nguồn: §3.11-R7 (đã author đủ, 2026-09-03 — trước đó là 70/147). Thông báo lỗi phải in **cặp template đụng nhau**, không chỉ con số | 6 slot · 147/147 |
| **AC-34b** | 🆕 **`I24` — variant không trùng legacy cùng slot.** Với mỗi slot, giao của {`(t, sortedKeys)` của reachable variant template} và {`(t, sortedKeys)` của **50 signature legacy**} phải **rỗng**.<br>**Chuẩn hoá bắt buộc**: so sánh trên danh sách keyword **đã sort theo thứ tự chuỗi tăng dần**, sau đó join bằng `,`. Không sort thì `dmg·lifesteal·growth` và `dmg·growth·lifesteal` là hai khoá khác nhau với máy nhưng cùng một face với người đọc — checker và designer sẽ bất đồng. Áp cùng quy ước cho AC-34, AC-9b, AC-9c, `I5`, `I6`.<br>**Số bộ legacy bị cấm theo slot — đếm TỪ `FACE_POOL`, không từ danh sách viết tay**: mouth **9** · horn **10** · back **5** · tail **11** · eyes **6** · ears **3**.<br>Đây là kiểm **độc lập** với AC-34: AC-34 chỉ nhìn variant↔variant, và một tập variant hoàn toàn phân biệt vẫn có thể đụng legacy — lúc đó tính phân biệt tụt về phụ thuộc `v`, tức phụ thuộc `B[C]`, đúng thứ R7 tồn tại để diệt. SPREAD **không cứu được** vì nó không được nhích legacy (AC-7c) | 6 slot · giao rỗng · 9/10/5/11/6/3 |
| **AC-35** | 🆕 **R8 — signature slot-disjointness sau SPREAD** (§3.5d-bis). Với mỗi slot: `(t, v, sortedKeys)` của mọi signature khác mọi signature khác **và** khác mọi variant instance reachable. 50 face legacy **không được nhích một đơn vị nào** (giao với AC-7c). Chỉ 31 face authored được bump, tối đa `SPREAD_MAX_BUMP = 2`. **Hôm nay có đúng 8 collision đã biết** (§3.5d-bis) — 5 signature↔signature (`Cub`↔`Zigzag`, `Cactus`↔`Cerastes`, `Black Gourd`↔`Tiny Dino`, `Mainspring`↔`Gila`, `Harmonious Silence`↔`Nyan`) và 3 signature↔variant (`Nutdha Statue`, `Imp`, `Snail Shell`); sau khi áp bảng sửa của §3.5d-bis phải còn **0** | 0 collision · 0 bump trên legacy · ≤2 bump/face |
| **AC-36** | 🆕 **Bất biến chống-lạm-dụng của pass re-author** (§3.13c). Sau khi `N17` xong: **(a)** không variant nào có **>3 keyword** (`I20`); **(b)** số ô `clampFloor` ở profile production **không tăng quá 20%** so với snapshot trước re-author (`I19`) — chặn việc giải R7 bằng cách chồng keyword đắt tới mức face kẹp `v=1`; **(c)** class identity whitelist giữ nguyên (`I21`): Beast và Bird không có variant `shield`/`heal`, Plant không có variant `poison` | ≤3 kw · clamp ≤+20% · 0 vi phạm whitelist |
| **AC-16** | 🔧 **Đã sửa (defect 9).** `FACE_POOL.filter(f => !f.bp).length === 63` · `FACE_POOL.length === 68` · `FACE_NAMES.length === 63` · `FACE_NAMES` khớp 1:1 theo index với **63 entry non-BP đầu tiên**. Phân bố rarity của 63 entry non-BP: r0=**11**, r1=**19**, r2=**15**, r3=**10**, r4=**8**. Mọi entry non-BP có `cls ∈ CLASSES`; **5 entry BP không cần `cls`** và không có entry `FACE_NAMES` | 63 · 68 · 63 · 11/19/15/10/8 |
| **AC-16b** | 🆕 **Kiểm bất biến BP**, để lỗi của revision 1 không tái diễn: `FACE_POOL.filter(f => f.bp).length === 5` và mọi `f.bp` khớp một khoá của `BP_FACES`. Đây là kiểm chặn cho việc **đếm `FACE_POOL.length` mà quên 5 entry được push lúc load module** (`src/data.js:596`) | 5 · 5/5 khớp khoá |
| **AC-17** | Đếm bucket từ `parts_full_source.json` qua F1: `C === 174` · `O === 75` · `P === 18` · `X === 18`. Tổng `=== 285`. Danh sách 18 part Prime khớp **chính xác** bảng §3.4 | 174/75/18/18 · 285 · 18 tên |
| **AC-18** | **Trần power**: `max over all 285 parts × specialGenes∈{true,false} of B_final / B[C] <= 1.70`. Và: không face variant nào có `r >= 4` (chỉ signature Mythic mới đạt COSMIC, E12) | ≤1.70 · 0 variant r4 |

### Nhóm C — Ranked guardrail (BLOCKING)

| AC | Assertion | Số cụ thể |
|---|---|---|
| **AC-12** | POST `/api/submit-run` với `teamKeys` chứa **bất kỳ** chuỗi khớp `/^vault_/` hoặc `/^axie:/` → HTTP **400**, và board `lb:{mode}:{asc}` **không** có entry mới. Chạy cho cả 5 vị trí trong `teamKeys`, và cho `mode ∈ {short, full}` × `ascension ∈ {0, 10}` | 5×2×2 = 20 case · 20× HTTP 400 · 0 entry |
| ~~**AC-13**~~ | ❌ **BỎ (2026-09-03)**. Kiểm biên `SBC_CAP` — trần đã bỏ, không còn gì để assert | — |
| ~~**AC-11**~~ | ❌ **BỎ (2026-09-03)**. Hiệu chuẩn `k` — handicap đã bỏ. *(nội dung cũ giữ lại bên dưới chỉ để truy vết, KHÔNG implement)* ~~Hiệu chuẩn `k`~~ (`tools/sim.js`). Chạy **≥500 run** ở `mode=full, ascension=10` cho 2 nhóm: nhóm-thấp (mọi part bucket C, `S̄=1.00`) và nhóm-cao (`teamScarcity=14`, `S̄` tối đa trong cap). Assert: `\|median(scoreFinal_cao) − median(scoreFinal_thấp)\| / median(scoreFinal_thấp) <= 0.10`. Nếu > 0.10 → chưa được ship Collector board; điều chỉnh `k` trong dải K17 (1.0–4.0) và chạy lại | ≥500 run/nhóm · lệch median ≤10% |
| **AC-11b** | **Hiệu chuẩn `R[debuff]`** (6d). ≥300 run mỗi giá trị `R[debuff] ∈ {2.60, 2.45, 2.35, 2.20}`. Chọn giá trị nhỏ nhất mà winrate của đội debuff-nặng (≥3 mặt `debuff`) **không vượt** 1.15× winrate đội đối chứng cùng bucket. Ghi kết quả vào `docs/balance-log.md` | 4 giá trị × ≥300 run · ngưỡng 1.15× |
| **AC-10** | 🔧 **Viết lại (defect 17).** **Degenerate check AEGIS** (`tools/sim.js --roster=...`). ≥200 run `ascension=10`, đội `thorns`-max (`Greedy Urn` + `reptile.back.B`@P + `Tri Spikes`) vs đối chứng cùng bucket.<br>**(a)** winrate `<= 1.40×` đối chứng.<br>**(b) 🆕 SHARE METRIC thay cho `s.stat.dmg === 0`**: trong **≥95%** các run **thắng**, damage quy cho thorns `<= 60%` tổng damage đội gây ra. Cần counter mới `s.stat.dmgThorns` (`N13`, §9a) tăng tại `dealDamage` :339-345.<br>**(c)** nếu (a) hoặc (b) đổ → **áp `THORNS_CAP` (E10b R-B) rồi chạy lại**, không hoãn sang sau ship | ≥200 run · ≤1.40× · thorns-share ≤60% ở ≥95% run thắng |
| | **Vì sao `s.stat.dmg === 0` bị loại**: nó chỉ bắt được trường hợp thuần khiết tuyệt đối. Một đội thorns vẫn **thỉnh thoảng** roll một mặt dmg — nó có 6 mặt, không phải 6 mặt shield — nên `s.stat.dmg` gần như **luôn** > 0 và điều kiện `=== 0` gần như **luôn** pass. Nó là một AC **không thể đổ**, đúng loại mà `qa-lead` phải chặn. Share metric đo đúng thứ degenerate: *tỉ trọng*, không phải *sự vắng mặt*. |
| | **Điều kiện tiên quyết về tooling**: `tools/sim.js` chạy 300 run cho ra AEGIS chỉ **4 run** — build thorns gần như không bao giờ xuất hiện tự nhiên, nên AC-10 **không đo được** bằng sampling. Cần cờ **`--roster`** ghim đội hình + **`--faces`** ghim mặt cụ thể. Nếu `sim.js` chưa hỗ trợ, đó là việc chặn (`N14`, §9a) cùng hạng với `gen_faces.mjs`. Không có nó, AC-10 là AC không chạy được, không phải AC đổ. |

### Nhóm D — Không gây regression (BLOCKING)

| AC | Assertion | Số cụ thể |
|---|---|---|
| **AC-19** | ✅ **ĐÃ ĐO THẬT — 2026-09-03, không còn là điều kiện treo.**<br>**Baseline chính thức: `tools/verify.mjs` = 32/32 PASS** (Phase A 21 · B 10 · C 2 · D 1). Cả hai con số cũ đều SAI: doc revision 1 ghi 29/30, session notes ghi 28/30.<br>**Tiên quyết** (đã làm): `npm install` — `verify.mjs`/`t_aoe.mjs`/`t_fit.mjs` đều `import playwright`, vốn là `devDependency` và worktree không có `node_modules`.<br>**Câu lệnh đúng** (chạy trần sẽ `ERR_CONNECTION_REFUSED`): `python3 build.py`, serve gốc repo ở cổng 5173, rồi `node tools/verify.mjs --url http://localhost:5173/AxieDiceTactics.html`.<br>**Assert**: sau thay đổi giữ **32/32**, không tụt. Badge mới (`α ORIGIN` / `⬥ PRIME` / `◈ SECRET`): contrast **≥ 4.5**, font **≥ 11px**, tap target **≥ 44px** nếu bấm được.<br>**Ghi chú**: `t_aoe.mjs` và `t_fit.mjs` từng **chết** (hardcode `/opt/pw-browsers/chromium` và `file:///home/claude/axie-dice/`) — đã sửa 2026-09-03. `t_aoe` pass sạch; `t_fit` **3/4 viewport**, fail 1280×720 (END TURN rơi khỏi màn hình) là **bug có sẵn, không liên quan**, đang sửa riêng — **đừng gate AC nào lên việc `t_fit` xanh hoàn toàn** | 32/32 · 4.5 / 11px / 44px |
| **AC-20** | `axieToDie` sort theo `SLOT_ORDER` trước `slice(0,6)` (E2): đưa cùng 6 part vào theo **6 thứ tự khác nhau** (kể cả đảo ngược) → `die` **giống hệt** cả 6 lần | 6 permutation · 1 kết quả |
| **AC-21** | `node tools/soak.mjs` và `node tools/soakm.mjs` pass — không regression vòng đời `.die`/`.unit` (nguồn regression drag/drop đã biết). Chạy với ≥1 Axie import trong đội hình | 2 tool · 0 fail |
| **AC-22** | 🔧 `tools/t_import.mjs` đã được viết lại và pass **≥ 23** check. *(Đã đo: file hiện pass **23/23**, không phải 21 như revision 1 ghi — nên ngưỡng 21 sẽ cho phép **hồi quy 2 check** mà vẫn báo xanh.)* 11 check "sống" (§6c) phải còn nguyên ý định | **≥23** pass · 11 check giữ nguyên |
| **AC-23** | Migration E13: entry Vault không có `schema === 2` → hiện badge `RE-SCAN`, **và** `pickTeam` từ chối nó. Load một `META.vault` chứa 3 entry schema-1 + 2 entry schema-2 → đúng 3 badge, đúng 3 entry bị chặn pre-select | 5 entry · 3 badge · 3 chặn |

### Nhóm F — Trục mới của revision 2 (BLOCKING)

| AC | Assertion | Số cụ thể |
|---|---|---|
| **AC-6b** | 🆕 **Hai identity của §3.5b** (thay checksum triệt tiêu được): `nC + nO + nP === 204` **và** `nP === 18 − |Prime ∩ Signature| === 15`. Cộng: `nSig + nC + nO + nP === 267`. Cả ba tính **từ `parts_full_source.json` qua F1**, không đọc từ bảng Markdown — nếu đọc từ bảng thì test chỉ kiểm bảng tự nhất quán | 204 · 15 · 267 |
| **AC-27** | 🆕 **Power bám thang hero suốt cả run** (Task 2C). `tools/sim.js --roster` ≥300 run `mode=full asc=0`, đội = 1 Axie import (thuần Classic, coherence 1.00) + 4 hero. Đo `avgPositiveFaceValue` và `maxHp` của Axie import ở **wave 1**, **wave 10**, **wave cuối**, so với hero **cùng thời điểm** trong cùng run (không so với hằng số — hero có thể chưa lên tier).<br>Assert tỉ lệ face value: wave 1 ∈ **[0.85, 1.20]** · wave 10 ∈ **[0.75, 1.15]** · cuối ∈ **[0.70, 1.10]**. Cùng dải cho `maxHp`.<br>**Đây là AC mà revision 1 không có**: nó chỉ đo winrate, và winrate không phân biệt được "import đúng thang" với "import quá yếu ở giữa run rồi được `FACE_POOL` drop bù lại" | ≥300 run · 3 mốc × 2 đại lượng · 6 dải |
| **AC-28** | 🆕 **TTK gate** (E15b). Cùng sim run của AC-27. Assert: **(a)** winrate ∈ [17.0%, 26.0%] *(= [0.85×, 1.30×] của baseline hero 20.0% đã đo, 300 run `mode=short asc=0`)* · **(b)** TTK trung vị **mỗi wave 1–12** trong **±20%** so với đội toàn hero · **(c)** winrate wave-12 boss ∈ [0.80×, 1.25×] của 37% đã đo.<br>**Hai phía có chủ ý**: revision 1 chỉ có ngưỡng trên, nên thiết kế làm import *quá yếu* sẽ pass — mà đó đúng là bài toán product owner giao | 3 assert · 12 wave · hai phía |
| **AC-29** | 🆕 **Coherence** (§3.4b). Cho một bộ part tổng hợp, quét `purity` 0→6: `CoherenceMod` khớp `K25` từng bậc; `B_final` và `maxHp` **đều** nhân nó; `purity` tính trên **`mapAxieClass(part.class)`** so với body class (nên part Dawn trên Axie Dawn **đếm là khớp**); Axie < 6 part dùng `purity6 = round(6 × matching / realParts.length)` nên **không bị phạt hai lần** | 7 bậc · 2 đại lượng · 1 công thức tỉ lệ |
| **AC-30** | 🆕 **Sàn secret** (§3.10, K26). Die có ≥1 part bucket X → `CoherenceMod >= 0.91` **và** keyword suppression **không** áp. Một Axie Dawn thật (dữ liệu thật: 1–3 part Dawn + phần còn lại từ class khác) → `CoherenceMod === 0.91`, không phải 0.85/0.82 | ≥0.91 · 0 suppression |
| **AC-31** | 🆕 **Gene tier** (§3.4c). `geneTier` 0→6: `B_run` tăng đúng `GENE_STEP` mỗi bậc rồi kẹp `B_CAP_RUN`; `maxHp` khớp `HP_STEP = [0,3,5,8,10,13,15]`; die được **dựng lại từ `parts`**, không nhân face đã có (assert: một face `debuff` `v=0` vẫn `v=0` ở gene 6 — nó **không** bị `oc`-style multiply).<br>**Và bất biến reward**: với roster **toàn hero**, phân phối `pool` của `genRewards` **byte-identical** với trước thay đổi ở cả 4 tier reward. Đây là AC bảo vệ "0 thay đổi cho đội toàn hero" | 7 bậc · 3 đại lượng · 4 tier · 0 diff |
| **AC-32** | 🆕 **Blank padding × `r_voidgene`** (E2a). Axie 3 part → die có đúng **3 face thật + 3 face `t === 'blank'`**. Với `r_voidgene` trong `s.relics`, **cả 3** face blank được `modFace` viết lại. Bảo vệ quan hệ ẩn: `BLANK` padding là đường **duy nhất** relic đó kích hoạt được trong toàn game | 3+3 · 3/3 rewrite |
| **AC-33** | 🆕 **Citation check** (`gen_faces.mjs --check-citations`). Với mọi tham chiếu `file.js:NNN` trong doc này có kèm tên symbol: đọc file, tìm symbol, assert dòng khớp trong **±3**. Fail build kèm số đúng. Đây là remedy cho defect 18 — cùng nguyên nhân gốc với defect 1/6/7: dữ liệu suy diễn duy trì bằng tay | 0 lệch >±3 |

### Nhóm E — Trải nghiệm (ADVISORY, không chặn merge)

> **Cả ba AC dưới đây đã được viết lại (defect 16 của review).** Bản revision 1 **không thể đổ**: không có cỡ mẫu (AC-24 nói "người chơi" số ít), không có thủ tục chọn mẫu (chọn 2 con Axie *nào*? ai chọn?), không có nhóm đối chứng, và điều kiện thành công là *"chỉ ra được"* — một cụm từ không có ngưỡng. AC-26 còn cho phép đoán bừa đúng: hỏi *"nhãn nào mạnh nhất?"* khi chỉ có 3 nhãn tồn tại thì tỉ lệ đoán đúng ngẫu nhiên là **33%**, và ngưỡng ≥4/5 = 80% chỉ cách ngẫu nhiên `p ≈ 0.045` với n=5 — tức gần như không phân biệt được kỹ năng đọc UI với may mắn.
>
> Ba AC mới nêu rõ: **n**, **cách chọn mẫu**, **câu hỏi nguyên văn**, **điều kiện đổ**, và với AC-26 là **distractor** để đoán bừa không pass được. Chúng vẫn là ADVISORY (không chặn merge) nhưng giờ chúng *có thể* đổ, nên chúng có giá trị.

| AC | Assertion |
|---|---|
| **AC-24** | 🔧 **Discovery — hai Axie cùng class trông khác nhau.**<br>**n = 8** người chơi, mỗi người 1 lượt.<br>**Chọn mẫu (adversarial, không random)**: chọn cặp Axie **khó nhất** — cùng class, cùng bucket (đều Classic), và cả 6 slot đều đi **đường variant** (không signature, vì signature có tên riêng nên dễ). Cặp này là *cận dưới* của trải nghiệm; nếu nó pass thì mọi cặp khác pass. Generator xuất danh sách cặp thoả điều kiện; chọn cặp đầu theo thứ tự `partKey` để lặp lại được.<br>**Thủ tục**: hiện hai die cạnh nhau, tooltip **bị tắt**, 20 giây. Câu hỏi nguyên văn: *"Đánh dấu những mặt mà hai con này KHÁC nhau."*<br>**Đổ nếu**: trung vị số mặt đánh dấu đúng < **4/6**, **hoặc** ≥2/8 người đánh dấu ≥2 mặt *sai* (nhận nhầm khác biệt không có thật — dấu hiệu die trông ồn ào chứ không phân biệt được) |
| **AC-25** | 🔧 **Relatedness — đọc được tên part thật.**<br>**n = 8**, mỗi người dùng **con Axie của chính họ** (nếu không có, dùng một Axie test đã cho họ xem trước ảnh trên marketplace 60 giây).<br>**Thủ tục**: hiện die đã import. Câu hỏi nguyên văn: *"Kể tên các part trên con Axie này, đọc từ chính mặt dice."*<br>**Đổ nếu**: trung vị số tên đọc đúng < **5/6**, hoặc ≥3/8 người nói không tìm thấy tên ở đâu.<br>**Nguyên nhân nếu đổ (đã biết trước)**: `faceText()` (`src/engine.js:774`) hiện **không** render `f.name`. Đây là AC duy nhất trong nhóm E có nguyên nhân-gốc xác định trước — nên nếu nó đổ thì đó là việc cho `ui-programmer`, không phải tín hiệu thiết kế sai |
| **AC-26** | 🔧 **Legibility của thang scarcity — có distractor.**<br>**n = 8**, sau **1 session đầy đủ** (≥1 run hoàn tất) với ≥1 Axie import trong đội.<br>**Thủ tục**: hiện **5 nhãn** — 3 nhãn thật (`α ORIGIN`, `⬥ PRIME`, `◈ SECRET`) cộng **2 distractor** trông hợp lý nhưng không tồn tại (`✦ MYSTIC`, `▲ ELITE`). Câu hỏi nguyên văn, đúng thứ tự này: **(1)** *"Nhãn nào trong số này bạn ĐÃ THẤY trong game?"* → **(2)** *"Trong những nhãn bạn đã thấy, xếp từ mạnh nhất xuống yếu nhất."*<br>**Đổ nếu**: <6/8 người chọn đúng tập 3 nhãn thật ở câu (1) *(distractor làm tỉ lệ đoán bừa tụt từ 33% xuống 10% — `1/C(5,3)`)*, **hoặc** <6/8 xếp `⬥ PRIME` trên `α ORIGIN` ở câu (2).<br>**Vì sao hai câu, đúng thứ tự đó**: câu (1) đo *nhận diện*, câu (2) đo *thứ bậc*. Hỏi thứ bậc trước sẽ mồi cho người chơi coi mọi nhãn được hiện là thật. Không xếp `◈ SECRET` vào điều kiện đổ — §3.4 cố ý đặt nó **giữa** O và P (`S = 1.467`), nên việc người chơi không xếp được nó là kết quả *đúng*, không phải thất bại của UI |

---

## 9. NEW ENGINE WORK REQUIRED

Doc này được thiết kế để **không cần keyword engine mới**. Cả 239 face chỉ dùng keyword đã verify implement (§3.7, AC-15). Mục này liệt kê việc engine **thật sự** cần, tách theo tính chặn.

### 9a. BLOCKING — không có thì hệ này không chạy đúng

| # | Việc | File | Vì sao chặn |
|---|---|---|---|
| N1 | Thay thân `axieToDie` theo §3.6 + `partKey`/`normClass`/`baseName`/`bucket`/`resolveFace` | `src/engine.js` | Là chính bề mặt cần sửa |
| N2 | `isSpecialGene()` + `specialGeneCount()` (E16), sau khi xác nhận enum thật | `src/engine.js` | Predicate hiện tại (`!= null`) có thể đang lạm phát 30% **mọi** part. Không sửa = không biết mình đang cân bằng cái gì |
| N3 | Sort `SLOT_ORDER` trước `slice(0,6)` | `src/engine.js` | E2 — không có thì die phụ thuộc thứ tự API ⇒ phá determinism ở tầng ngoài ⇒ replay Collector fail |
| N4 | Vault migration `schema: 2` + nút RE-SCAN + chặn pre-select entry stale | `src/ui.js` | E13 — không có thì hệ mới **vô hình** với mọi người chơi đã import |
| N5 | Bump `ENGINE_VERSION` | `src/engine.js:9` | Gameplay math đổi. Không bump = server replay điểm sai cho log cũ |
| N6 | Viết lại `tools/t_import.mjs` | `tools/` | §6c — nó import symbol đã xoá nên **cả file không chạy được**, không chỉ vài check đỏ. Baseline đã đo: **23/23 pass** hôm nay, nên AC-22 đòi ≥23 |
| **N7′** | 🆕 **`tools/gen_faces.mjs`** — implement F1–F8 + REPAIR ở **hai profile**, sinh `assets/data/part_faces.json` + `--check-citations` | `tools/` | §6f. **Chặn** vì sau revision 2 doc **không còn chứa** giá trị runtime. Không có generator = không có số để implement. Thay `gen_parts.py` |
| **N12** | 🆕 **`THORNS_CAP`** trong `addStatus` (`src/engine.js:394-395`) | `src/engine.js` | E10b remedy R-B. **Chặn**, không hoãn: doc này *tăng* mức phơi bày thorns (thêm `reptile.back.B` `thorns:3`, `reptile.eyes.B` `thorns:2`, `Greedy Urn` `thorns:4`) trong khi `B[C]` hạ xuống — nên tỉ trọng thorns/power tăng ~2.1×. `thorns` không decay (`tickStatus` :640-662) nên **không giá hữu hạn nào đúng** mà không có trần. ~1 dòng, no-op với mọi dice hero hiện tại |
| **N13** | 🆕 Counter `s.stat.dmgThorns` tại `dealDamage` :339-345 | `src/engine.js` | AC-10 share metric cần nó. Không có nó, AC-10 phải quay về `s.stat.dmg === 0` — điều kiện gần như không bao giờ đổ. ~2 dòng |
| **N14** | 🆕 `tools/sim.js --roster` + `--faces` (ghim đội hình / ghim mặt) | `tools/` | **Chặn AC-10, AC-27, AC-28.** Đã đo: 300 run cho AEGIS chỉ **4 run** — build thorns gần như không xuất hiện tự nhiên, nên không sampling được. Không có cờ này, 3 AC là AC *không chạy được*, không phải AC đổ |
| **N15** | 🆕 Reward `'gene'`: nhánh `mkReward` + nhánh pool `genRewards` + dựng lại die trong `buildUnit` | `src/engine.js` | §3.4c. **Chặn** vì Task 2C yêu cầu import có đường tăng trưởng thật. Điều kiện thiết kế: nhánh pool phải giữ **nguyên xi** hành vi cho roster toàn hero (AC-31) — dùng `if(canGene.length) pool.push('gene','gene')` **thêm vào**, không thay `else` hiện có |
| **N16** | 🆕 Vault schema 3: lưu `parts` manifest đã verify cạnh die đã resolve | `src/ui.js` | Cần cho N15 (dựng lại die theo `geneTier`) **và** §3.9e bước 4 (server rebuild). Một migration, hai yêu cầu |

### 9b. Keyword CHƯA implement — chỉ làm nếu muốn dùng

Đúng **một** keyword ở trạng thái này. Doc này **không dùng nó**; spec ở đây để `lead-programmer` scope được nếu Phase 2 muốn.

**`shieldself:N` — Self-Shield**

- **Bằng chứng chưa implement**: xuất hiện đúng 1 lần trong `src/` — comment `src/data.js:6`. Không có trong `KWT` (`engine.js:738`). Không có nhánh nào trong `addStatus()` hay `doFace()`.
- **Vì sao đáng làm**: `part-tier-system.md` §2c dùng nó ở **6 ô** và §8/§9a gán **~14 part** vào nó. Toàn bộ là no-op. Nó cũng lấp một lỗ thiết kế thật: hiện **không có** cách nào để một face `dmg` tự tạo shield cho người dùng nó (chỉ có `lifesteal` cho HP).
- **Spec hành vi chính xác**:

```
Đặt cạnh các rider khác trong doFace(), khối `if(!isEcho)` — CÙNG CHỖ với
selfharm (engine.js:511) và mana (engine.js:512), KHÔNG phải trong kwPure.

  const ss = kwVal(f,'shieldself');
  if (ss) applyShield(s, u, ss);

Ràng buộc:
  - Target LUÔN là `u` (người dùng face), không bao giờ là tgt. Đây là điều
    phân biệt nó với một face `shield` thường.
  - PHẢI đi qua applyShield(), không gán tay `u.shield += ss` — vì applyShield
    áp BULWARK +2 cho Plant (:351), trần maxHp×2 (:352), auto-Thorns 2 khi
    shield>=10 cho Plant (:354), hook relic onShield (:355), và phát EVhp.
    Bỏ qua nó = mechanic vô hình với fx.js và sai với Plant.
  - PHẢI nằm trong `if(!isEcho)` để `echo` không nhân đôi nó — cùng lý do
    selfharm/mana/rerollup đã ở đó.
  - PHẢI thêm vào danh sách loại trừ kwPure (engine.js:462-464), nếu không
    addStatus() sẽ nhận `'shieldself:3'`, không khớp nhánh nào, và no-op im lặng
    — nhưng tệ hơn: trên face `shield`/`heal` nó sẽ được truyền như status lên ally.
  - PHẢI thêm `shieldself:'Self-Shield'` vào KWT (:742) để tooltip hiện đúng.
```
- **Định giá đề xuất** (chưa hiệu chuẩn, cần sim): `KW['shieldself:N'] = 0.80 × N`. Lý do: rẻ hơn `regen:N`×2 nhưng đắt hơn `regen:N` đơn — nó tức thời (không chờ tick) nhưng bị `pierce` xuyên qua, còn `regen` thì không.
- **Kiểm sau khi làm**: 1 test đơn vị (`shieldself:3` trên một Plant → `u.shield === 5` vì BULWARK +2) + 1 test `echo` không nhân đôi + 1 test kwPure không rò rỉ.
- **Ước lượng**: ~6 dòng engine + 3 dòng test. **S**.

### 9c. Việc engine cho Collector board (§3.9) — tách riêng, không chặn phần import

| # | Việc | Ghi chú |
|---|---|---|
| N7 | Endpoint Collector: `SBC_CAP` check + `H'` divisor + board `lbc:{mode}:{asc}` | Tính được thuần từ manifest. **M** |
| N8 | Verify wallet signature (`walletSig`) | §3.9e bước 1. **M** |
| N9 | **On-chain ownership read** | §3.9e bước 2. **Đây là GATE**: chưa có nó thì Collector board bắt buộc mang nhãn `EXHIBITION`, không reward, không mùa giải. Cần ADR mới (§6e). **L** |
| N10 | Server-side manifest re-verify qua `api/axie.js` | §3.9e bước 3. **Chú ý**: 20 call/submission vs rate limit 20/phút/IP (`api/axie.js:63`) → cần đường nội bộ bỏ qua rate limit hoặc cache theo `axieId`. **M** |
| N11 | Server-side `axieToDie()` rebuild từ manifest đã verify | §3.9e bước 4. Chạy được vì `axieToDie` pure (AC-1) — đó là lý do AC-1 là BLOCKING, không phải nice-to-have. **S** |

### 9d. Việc engine KHÔNG làm (nêu rõ để không ai làm nhầm)

| Việc | Vì sao không |
|---|---|
| Sửa `tickStatus()` để `thorns` giảm mỗi lượt (E10) | Đây là thay đổi balance **toàn game**: ảnh hưởng `HEROES.reptile1/2/3`, relic `thornsMult`, boss `permThorns`, passive SCALES. Ngoài scope. Là ứng viên #1 cho `/balance-check combat` **sau** khi hệ này ship — knob K11 là mitigation tạm |
| Thêm `debuff` vào `RESONANCE.types` (6d) | Sẽ đổi Formation Resonance cho **cả** `HEROES` (ngoài scope). Remediation trong-scope là knob K10 (`R[debuff]`) |
| Sửa `chain:N` để tôn trọng target người chơi chọn (E6) | Là hành vi cố ý của engine, và `chain` đã được **chiết khấu giá** vì nó. Việc cần làm là **UI nói rõ**, không phải đổi engine |
| Gắn gameplay effect vào `dieRarity()` | E12 mục 2 — sẽ tạo đường mua power thứ hai mà §3.9 không bao |
