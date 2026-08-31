# Axie Dice Tactics — UI/UX Audit & Redesign Spec
**Bản được đánh giá:** `https://axiedice.vercel.app` · v0.9 (chuỗi `LUNACIA MUTANTS · v0.9` trên màn hình MENU)
**Ngày audit:** 14/08/2026
**Người thực hiện:** Lead UI/UX Game Designer
**Phạm vi:** Menu → Team Select → Map → Combat → Info panel → Settings → Codex → Collection
**Thiết bị đo:** Chrome desktop macOS, DPR 2. Viewport CSS: **1440×839** (chụp màn hình, phân tích khoảng trống dọc), **1728×944** và **864×860** (đo `getComputedStyle` / `getBoundingClientRect`)

---

## 0. Cách đọc tài liệu này

Mỗi vấn đề đều có 4 phần: **hiện trạng đo được** (số thật, lấy từ `getComputedStyle` / `getBoundingClientRect` trên chính bản build đang chạy), **tại sao sai**, **sửa thành số bao nhiêu**, và **CSS patch**. Không có khuyến nghị nào ở dạng "nên đẹp hơn" mà không kèm con số.

Ký hiệu ưu tiên:

| Mức | Nghĩa | SLA đề xuất |
|---|---|---|
| **P0** | Chặn người chơi / lỗi hiển thị / vi phạm accessibility mức A | Sửa trước bản build kế tiếp |
| **P1** | Gây hiểu sai luật chơi hoặc mất người chơi mới | Trong sprint hiện tại |
| **P2** | Đánh bóng, nhất quán hệ thống | Backlog 2 sprint |

### Giới hạn của bản audit này (nói trước cho minh bạch)

1. **Chưa audit được 4 màn:** Reward, Shop, Event, Game Over/Victory. Phiên chơi thử dừng ở wave 1 vì thời lượng; các màn này cần một pass riêng.
2. **Không render được viewport < 864px CSS trong phiên này.** Phiên audit điều khiển một cửa sổ Chrome thật (không bật được device toolbar), và cửa sổ Chrome trên macOS có chiều rộng tối thiểu. Vì vậy phần phân tích mobile ở **P0-6 (§3)** được suy ra từ **kiểm tra CSS trực tiếp** — đếm media query, đọc `zoom`, cộng token layout — chứ không phải từ ảnh render. 846px được **tính từ các token đã đo thật**; mọi con số cho màn 390px là phép tính. Bước QA ở §9 dùng DevTools device toolbar chính là để **xác nhận lại** phần này.
3. Contrast ratio được tính lại bằng công thức WCAG 2.1 relative luminance từ mã màu computed thật, không ước lượng bằng mắt.

---

## 1. Điểm tổng quan

| Hạng mục | Điểm | Nhận xét một dòng |
|---|---|---|
| Hệ thống thị giác (token, màu, nhịp) | **7.5 / 10** | Nền tảng token rất tốt, nhưng bị phá bởi việc dùng bậc chữ nhỏ nhất cho nội dung dài |
| Khả năng đọc (typography + contrast) | **4.0 / 10** | 9px cho câu văn, và 4 cặp màu fail WCAG AA |
| Bố cục & mật độ thông tin | **6.5 / 10** | Sạch, nhưng bỏ trống ~36% chiều dọc trên laptop 16:9 (đo ở 1440×839) |
| Phản hồi & rõ ràng trạng thái | **6.0 / 10** | Target preview tốt; thiếu combat log, thiếu trạng thái nguy hiểm của HP |
| Điều hướng & information architecture | **5.0 / 10** | Menu giấu toàn bộ nav phụ sau 2 tab xoay dọc ở mép màn hình |
| Responsive / mobile | **2.0 / 10** | 547 CSS rule, **0 media query theo chiều rộng**. Chiến lược duy nhất là `zoom` |
| Accessibility | **3.0 / 10** | Không focus ring, không keyboard nav ngoài phím tắt, target 18px, contrast fail |
| Độ bóng (polish / bug) | **5.5 / 10** | `TURN undefined` hiển thị công khai; layout shift khi chọn dice |
| **Tổng** | **4.9 / 10** | Bản game **có gu thẩm mỹ nhưng chưa có kỷ luật kỹ thuật UI** |

**Kết luận một câu:** Design system v0.8 đã giải đúng bài toán "quá nhiều thứ tranh nhau gây chú ý", nhưng đã đi quá xa sang phía đối diện — bây giờ game **quá nhạt và quá nhỏ**. Ba cỡ chữ nhỏ nhất đang dùng (`--t1` 9px, `--die-kw` 10px, `--t2` 11px) gánh gần như toàn bộ nội dung. Đếm ký tự thực tế trên bản build đang chạy:

| Màn hình | Tổng ký tự | Ở đúng 9px | Ở ≤ 11px |
|---|---|---|---|
| Combat (turn 5, wave 1) | 312 | **219 (70%)** | **260 (83%)** |
| Collection | 799 | **692 (87%)** | **785 (98%)** |

Cùng lúc đó, màu `--faint` (#59616e) được dùng cho **cả câu văn hoàn chỉnh**, và panel `--pan` (#191d23) chỉ hơn nền `--bg` (#0e1013) đúng **1.13:1** nên gần như không tách được lớp.

---

## 2. Token hiện tại (đo thật từ `:root`)

```
/* Typography */
--t1: 9px    --t2: 11px   --t3: 13px   --t4: 17px   --t5: 26px   --t6: 40px
--die-num: 30px   --die-kw: 10px   --float-sz: 26px   --intent-v: 15px
font-family: "Courier New" (duy nhất, toàn bộ game)

/* Surfaces */
--bg: #0e1013   --bg-top: #171b21   --pan: #191d23   --pan2: #212730   --pan3: #2c333e
--line: #2c333d   --line2: #3f4956   --bd: 2px
--radius: 10px  --rad-sm: 6px

/* Text */
--txt: #e9edf3   --dim: #8b95a4   --faint: #59616e

/* Semantic */
--acc:#ffc857  --dmg:#ff6b6b  --shd:#63b3ff  --heal:#5fd68a
--man:#b388ff  --poi:#a8d84a  --burn:#ff9a4d  --deb:#ff8fc7

/* Rarity */
--r0:#9aa4b2  --r1:#63b3ff  --r2:#b388ff  --r3:#ffc857  --r4:#ff5f8f

/* Layout */
--die-w:158px  --die-h:104px  --unit-w:158px  --spr-w:100px  --spr-big:164px
--spr-guide:64px  --hp-h:16px  --zone-gap:8px  --ui-scale:1
```

Bộ token này **về cấu trúc là đúng**. Vấn đề nằm ở *giá trị* của 3 bậc dưới cùng và ở việc thiếu hoàn toàn token cho spacing, chiều cao control, và breakpoint.

---

## 3. P0 — Phải sửa trước bản build kế tiếp

### P0-1. Lỗi hiển thị: `TURN undefined`

**Hiện trạng:** Trên màn Map (`CHOOSE YOUR PATH`), thanh header hiển thị nguyên văn `TURN undefined`. Element `.turn` render chuỗi này ở 11px màu `#8b95a4`.

**Tại sao nghiêm trọng:** Đây là lỗi lộ ra ngoài production, người chơi nhìn thấy trực tiếp. Ngoài combat, khái niệm "turn" không tồn tại.

**Sửa:** Ẩn hoàn toàn `.turn` khi `screen !== 'combat'`. Nếu muốn giữ chiều rộng header ổn định, dùng `visibility:hidden` thay vì `display:none`.

```css
.screen:not(.combat) .track .turn { visibility: hidden; }
```

Kèm guard ở tầng render:

```js
const turnLabel = (screen === 'combat' && turn != null) ? `TURN ${turn}` : '';
```

---

### P0-2. Chữ HP không đọc được — contrast 1.65:1

**Hiện trạng đo được:**

| Thành phần | Giá trị thật |
|---|---|
| `.hptxt` | `color: #ffffff`, `font-size: 11px`, `text-shadow` viền đen 1px 4 hướng |
| `.hpfill` (đồng minh) | `background: #5fd68a` |
| `.hpfill` (địch) | `background: rgb(201,80,79)` = `#c9504f` |
| `.hpchip` | `background: rgba(255,255,255,0.18)`, **width luôn bằng width của `.hpfill`** |

**Contrast tính theo WCAG 2.1:**

| Cặp màu | Tỷ lệ | Ngưỡng AA (chữ <18px) | Kết quả |
|---|---|---|---|
| `#ffffff` trên `#5fd68a` | **1.83 : 1** | 4.5 : 1 | ❌ Fail nặng |
| `#ffffff` trên `#5fd68a` + lớp phủ trắng 18% (`#7cdd9f`) | **1.65 : 1** | 4.5 : 1 | ❌ Fail nặng hơn |
| `#ffffff` trên `#c9504f` | **4.43 : 1** | 4.5 : 1 | ❌ Fail sát ngưỡng |
| `#ffffff` trên `#d3706f` (có lớp phủ) | **3.34 : 1** | 4.5 : 1 | ❌ Fail |

> Bốn con số này được tính lại bằng công thức relative luminance của WCAG 2.1 từ mã màu computed thật, không ước lượng.

Viền đen 1px có cứu vãn phần nào, nhưng ở 11px Courier New nét chữ chỉ dày ~1px — viền đen chiếm gần hết nét chữ, làm chữ bị "bết" thay vì rõ hơn.

**Ngoài ra `.hpchip` đang vô nghĩa:** đo trên cả 7 unit, `chipWidth === fillWidth` ở mọi thời điểm (Chomper 117/117, Sprout 107/107, Hatchling 67/67…). Ý đồ ban đầu chắc chắn là hiển thị đoạn máu *vừa mất* với hiệu ứng trễ, nhưng hiện tại nó chỉ là một lớp phủ trắng 18% vĩnh viễn nằm trên toàn bộ thanh máu — làm nhạt màu fill và **giảm thêm contrast**.

**Sửa — 3 thay đổi:**

1. Đổi chữ HP sang **mực tối** `#0b0e12` thay vì trắng. Kiểm chứng trên cả 3 màu fill mới ở P0-3:
   `#0b0e12` trên `#5fd68a` = **10.57 : 1**, trên `#ffc857` = **12.57 : 1**, trên `#ff6b6b` = **6.97 : 1** — cả ba đều vượt xa 4.5:1.
2. **Bỏ hẳn màu fill riêng cho địch** (`#c9504f`). Xem P0-3: sau khi màu thanh máu mã hoá theo % HP thay vì theo phe, chỉ còn 3 màu fill và cả ba đều an toàn với mực tối. Không cần đi tìm một sắc đỏ vừa đủ tối cho địch nữa.
3. Sửa `.hpchip` để chỉ phủ đoạn chênh lệch (`width = oldPct - newPct`, `left = newPct`), hoặc **xoá hẳn** nếu không làm animation trễ.

**Khuyến nghị mạnh nhất — bỏ chữ chồng lên thanh:** đưa `HP 15/20` thành một dòng riêng 11px `--dim` **phía trên** thanh máu. Thanh máu khi đó chỉ còn là thanh, cao 8px thay vì 16px, và **bài toán contrast biến mất hoàn toàn** — không còn chữ nào nằm trên nền màu nữa. Đây là cách sửa rẻ nhất và bền nhất: nó miễn nhiễm với mọi màu fill mà bạn thêm về sau.

```css
:root{
  --hp-h: 8px;               /* từ 16px */
  --hp-full: #5fd68a;        /* 100–51% */
  --hp-low:  #ffc857;        /*  50–26% */
  --hp-crit: #ff6b6b;        /*  25– 1% */
  /* KHÔNG có --hp-enemy: màu mã hoá % máu, không mã hoá phe. Xem P0-3. */
}
.hpbar { height:var(--hp-h); border-radius:4px; background:#0a0c0f; overflow:hidden; }
.hpfill{ height:100%; background:var(--hp-full); transition:width .22s ease-out; }
.hpchip{ display:none; }     /* hoặc sửa đúng theo mô tả ở mục 3 phía trên */

/* Số HP tách ra khỏi thanh — không còn chữ trên nền màu */
.hpnum{
  display:flex; justify-content:space-between;
  font-size:var(--t1); letter-spacing:.5px; color:var(--dim);
  margin-bottom:3px;
}
.hpnum b{ color:var(--txt); }
```

Nếu **bắt buộc** phải giữ chữ đè lên thanh (vì lý do bố cục), dùng `--hp-ink: #0b0e12` — đã kiểm chứng 10.57 / 12.57 / 6.97 trên ba màu fill trên.

---

### P0-3. Màu thanh máu mã hoá **phe**, không mã hoá **nguy hiểm**

**Hiện trạng:**
```css
.hpbar.low .hpfill { background: var(--dmg); }   /* tồn tại */
.unit.e   .hpfill { background: rgb(201,80,79); } /* nhưng override cứng cho địch */
```

Hai selector `.unit.e .hpfill` và `.hpbar.low .hpfill` có **specificity bằng nhau** — cùng (0,3,0). Rule của địch thắng đơn giản vì nó nằm **sau** trong file. Và vì không có biến thể `.unit.e .hpbar.low`, **quái ở 1/14 HP trông y hệt quái ở 14/14 HP**. Điều này đã được xác nhận trong phiên chơi: Gooey Slime tụt xuống `1/14` mà thanh máu không đổi màu. Ở phía đồng minh, Hatchling `9/19` (47%) vẫn xanh lá đầy đủ.

**Tại sao đây là lỗi thiết kế game, không chỉ lỗi CSS:** vị trí trên màn hình đã nói rõ ai là địch (hàng trên) ai là ta (hàng dưới). Dùng thêm màu để lặp lại thông tin đó là lãng phí kênh màu duy nhất mà người chơi liếc nhanh nhất — trong khi thông tin *thực sự* cần liếc nhanh là "con nào sắp chết".

**Sửa — ngưỡng cụ thể:**

| % HP còn lại | Màu fill | Token |
|---|---|---|
| 100% – 51% | `#5fd68a` xanh | `--hp-full` |
| 50% – 26% | `#ffc857` vàng | `--hp-low` |
| 25% – 1% | `#ff6b6b` đỏ + nhấp nháy 1.2s | `--hp-crit` |

Áp dụng **giống hệt** cho cả địch lẫn ta. Phân biệt phe bằng: hàng trên/dưới (đã có), và một dải 3px màu `--dmg` ở cạnh trên của card địch.

```css
/* Thứ tự nguồn quan trọng: 3 rule dưới phải nằm SAU rule .unit.e gốc,
   vì cả ba đều có specificity (0,3,0) — chúng thắng nhau bằng source order. */
.unit.e     .hpfill{ background: var(--hp-full); }   /* bỏ override cứng theo phe */
.hpbar.low  .hpfill{ background: var(--hp-low);  }
.hpbar.crit .hpfill{ background: var(--hp-crit); animation: pulse 1.2s infinite; }
.unit.e{ border-top: 3px solid var(--dmg); }
@keyframes pulse{ 50%{ opacity:.55 } }
@media (prefers-reduced-motion: reduce){ .hpbar.crit .hpfill{ animation:none } }
```

---

### P0-4. Bậc chữ 9px dùng cho **câu văn hoàn chỉnh**

**Hiện trạng đo được — mọi chỗ đang dùng `--t1: 9px`:**

| Selector | Nội dung | Màu | Contrast |
|---|---|---|---|
| `.pd` (Team Select) | *"Every Shield you create is increased by 2. An Axie with 10 or more Shield gains Thorns 2."* — 2–3 dòng văn xuôi | `#8b95a4` / `#191d23` | 5.58:1 (đạt, nhưng 9px) |
| `.hintbar` (Combat) | *"Click or drag a die to use it · corner button marks it for reroll · Ctrl+Z undoes"* | `#59616e` / `#0e1013` | **3.05:1 ❌** |
| `.dp` (nhãn dice: BACK/HORN/MOUTH) | 9px, `letter-spacing: 2px` | `#59616e` / `#212730` | **2.40:1 ❌** |
| `.nm` (tên unit trong combat) | `Sprout T1` | `#8b95a4` / `#191d23` | 5.58:1 |
| `.cls`, `.pn` (Team Select) | `PLANT · HP 17`, `BULWARK` | `#59616e` / `#191d23` | **2.71:1 ❌** |
| `.tlabel` | `WAVE` | `#59616e` / `#191d23` | **2.71:1 ❌** |
| `.ml` | `MANA` | `#59616e` / `#212730` | **2.40:1 ❌** |
| `.btn.xs` | `UNDO`, `1x`, `INFO`, `SET` | — | xem P0-5 |
| `.cxtd` (Codex table) | ô dữ liệu bảng | `#59616e` / `#2c333e` | **2.04:1 ❌** |

**Tại sao nghiêm trọng:** Courier New là font monospace có x-height thấp. Đo trực tiếp bằng `canvas.measureText('x').actualBoundingBoxAscent` trên chính bản build: ở 9px, x-height thực tế chỉ **3.81px** (ở 11px là 4.65px) — dưới ngưỡng đọc thoải mái của mắt người ở khoảng cách ngồi máy tính (~60cm). Một câu 100 ký tự ở kích thước này buộc người chơi phải rướn người về màn hình. Trong game roguelike deckbuilder, mô tả passive là thông tin **quyết định build** — nó không thể là chữ nhỏ nhất trên màn hình.

**Sửa — thang chữ mới:**

| Token | Cũ | **Mới** | Chỉ được dùng cho |
|---|---|---|---|
| `--t1` | 9px | **11px** | Nhãn ALL-CAPS ≤ 12 ký tự (`WAVE`, `MANA`, `BACK`). **Cấm** dùng cho câu văn |
| `--t2` | 11px | **13px** | Chữ phụ, giá trị số phụ, chip trạng thái |
| `--t3` | 13px | **15px** | **Body mặc định** — mọi mô tả, tooltip, Codex |
| `--t4` | 17px | **20px** | Tiêu đề section, nhãn nút lớn |
| `--t5` | 26px | **28px** | Tiêu đề màn hình |
| `--t6` | 40px | **44px** | Logo |
| `--die-num` | 30px | **34px** | Số trên mặt xúc xắc |
| `--die-kw` | 10px | **13px** | Từ khoá trên xúc xắc (`Weaken 2`) |
| `--intent-v` | 15px | **20px** | Số damage trong intent của địch |
| `--float-sz` | 26px | **28px** | Floating combat text |

**Quy tắc bổ sung — cấm dùng `--faint` cho chữ:**
`#59616e` chỉ đạt 2.71:1 trên `--pan`, 2.40:1 trên `--pan2` và 2.04:1 trên `--pan3`. Chuyển **toàn bộ** chữ đang dùng `--faint` sang `--dim`. **Xoá hẳn token `--faint`** (đừng đổi tên nó — `--line` đã tồn tại với giá trị khác, đổi tên sẽ âm thầm chuyển màu mọi đường kẻ đang dùng `--line`). Mọi chỗ `--faint` đang dùng cho **chữ** → chuyển sang `--dim`; mọi chỗ dùng cho **đường kẻ / icon trang trí** → chuyển sang `--line`. Xem bảng surface mới ở P1-8.

```css
:root{
  --t1:11px; --t2:13px; --t3:15px; --t4:20px; --t5:28px; --t6:44px;
  --die-num:34px; --die-kw:13px; --intent-v:20px; --float-sz:28px;
}
.pd, .cxp, .nd                   { font-size: var(--t3); color: var(--dim); }  /* 15px */
.hintbar, .cxtd                  { font-size: var(--t2); color: var(--dim); }  /* 13px */
.tlabel, .ml, .dp, .cls, .pn     { font-size: var(--t1); color: var(--dim); }  /* 11px */
```

**Đề xuất font (P1, không bắt buộc):** Courier New render rất mỏng trên Windows ClearType ở cỡ nhỏ. Thay bằng stack có hinting tốt hơn ở 11–15px, vẫn giữ chất monospace/retro:
```css
font-family: "JetBrains Mono", "IBM Plex Mono", ui-monospace, "Courier New", monospace;
```
Nếu muốn giữ chất pixel-art, dùng một pixel font bitmap có bản 16px (ví dụ *Departure Mono*) và khoá cỡ chữ theo bội số của 8/16 để không bị nhoè.

---

### P0-5. Vùng chạm 18px — dưới cả ngưỡng AA lẫn AAA

**Hiện trạng đo được:**

| Nút | Kích thước thật | Font | Ghi chú |
|---|---|---|---|
| `.btn.xs` (`UNDO`, `1x`, `2x`, `3x`, `INFO`, `SET`) | **42 × 18 px** | 9px | padding `2px 7px` |
| `.btn.sm` (mode, ascension ở Team Select) | 301 × **27 px** / 38 × 27 px | 11px | padding `5px 10px` |
| `.btn` (rail menu) | 196 × **39 px** | 11px | padding `11px 12px` |
| `.rsel` (nút đánh dấu reroll trên xúc xắc) | **22 × 22 px** | 11px | `border-radius: 50%` |
| `.seedinp` | 230 × **29 px** | 11px | |
| `.reroll` / `.end` | 98 × **35 px** | 13px | |
| `.go` (`START RUN`) | 152 × **47 px** | 17px | nút duy nhất đạt chuẩn |
| `.tnode` (chấm wave trên track) | **14 × 14 px** | — | |

Chuẩn: **WCAG 2.5.5 (AAA) = 44×44px**, **WCAG 2.5.8 (AA) = 24×24px**, Apple HIG = 44pt, Material = 48dp.
`.btn.xs` ở 18px cao **fail cả mức AA**. `.rsel` 22×22 cũng fail AA (thiếu 2px).

**Nút `UNDO` khi disabled còn tệ hơn:** `opacity: 0.28` trên `#8b95a4`/`#191d23` → màu hiệu dụng `#393f47`, contrast **1.59 : 1**. Người chơi không phân biệt được "nút bị vô hiệu" với "một vệt bẩn trên nền".

**Sửa — hệ 3 cỡ nút, bỏ hẳn `xs`:**

| Cỡ | Chiều cao | Padding | Font | Hit-area | Dùng cho |
|---|---|---|---|---|---|
| `.btn--sm` | **32px** | `8px 12px` | `--t2` 13px | 44px (qua `::before`) | Toggle trong header, chip |
| `.btn--md` | **40px** | `10px 16px` | `--t2` 13px | 44px | Nút thường |
| `.btn--lg` | **48px** | `14px 28px` | `--t4` 20px | 48px | CTA chính (`START RUN`, `END TURN`, `PLAY`) |

```css
.btn{
  --btn-h:40px;
  min-height:var(--btn-h);
  display:inline-flex; align-items:center; justify-content:center;
  padding:0 16px; font-size:var(--t2); letter-spacing:.5px;
  border:2px solid var(--line2); border-radius:var(--radius);
  background:var(--pan2); color:var(--txt);
  position:relative; cursor:pointer;
}
/* mở rộng vùng chạm mà không đổi kích thước hình học */
.btn::before{
  content:""; position:absolute; inset:50% 50%;
  width:max(100%,44px); height:max(100%,44px);
  transform:translate(-50%,-50%);
}
/* --btn-h là biến cục bộ của component, không thuộc bảng token §6 */
.btn--sm{ --btn-h:32px; padding:0 12px; }
.btn--lg{ --btn-h:48px; padding:0 28px; font-size:var(--t4); }

/* disabled: giảm tương phản có kiểm soát, KHÔNG dùng opacity mù */
.btn[disabled], .btn.dis{
  background:transparent;
  border-color:var(--line);
  color:var(--off);        /* #7d8794 → 3.55:1 trên --pan2, 4.29:1 trên --pan */
  opacity:1;               /* thay cho opacity:.28 (1.59:1) hiện tại */
  cursor:not-allowed;
}
/* nút đánh dấu reroll — position:relative BẮT BUỘC, nếu không ::before
   sẽ neo vào ancestor có position gần nhất chứ không phải vào chính nó */
.rsel{ position:relative; width:28px; height:28px; }
.rsel::before{ content:""; position:absolute; inset:-8px; }  /* → 44×44 hit area */
```

**Chấm wave `.tnode`:** 14px là kích thước hiển thị hợp lý, nhưng chúng **không có tooltip và không có chú giải màu**. 12 chấm với 3 màu khác nhau (vàng/xám/đỏ-nhạt) mà người chơi không biết màu nào là elite, màu nào là boss. Thêm `title` attribute + một hàng legend 11px dưới track ở wave 1, hoặc đổi shape thay vì đổi màu (tròn = thường, vuông xoay 45° = elite, lục giác = boss) để không phụ thuộc màu.

---

### P0-6. Không có breakpoint — game vỡ hoàn toàn trên mobile

**Hiện trạng đo được:**

- Tổng số CSS rule: **547**
- Tổng số `@media`: **1** — và đó là `(prefers-reduced-motion: reduce)`
- **Không có một media query nào theo `min-width`/`max-width`**
- Chiến lược responsive duy nhất: `#app { max-width:1240px; zoom: var(--ui-scale) }`
- `<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">` — có khai báo mobile nhưng không có CSS đi kèm

**Chiều rộng tối thiểu của bàn chơi (tính từ token đo được):**
```
5 unit × 158px  = 790px
4 khoảng cách × 8px =  32px
padding #app  2 × 12px =  24px
───────────────────────────────
TỔNG              = 846px
```

**Hệ quả suy ra bằng phép tính — chưa xác nhận trên thiết bị thật (xem §0, giới hạn 2):**

| Thiết bị | Viewport CSS | `--ui-scale` bắt buộc | `--die-num` 30px thành | `--t1` 9px thành |
|---|---|---|---|---|
| iPhone 15 Pro portrait | 393px | **0.46** | **13.9px** | **4.1px** |
| iPhone SE portrait | 375px | **0.44** | 13.3px | **4.0px** |
| iPad mini portrait | 744px | 0.88 | 26.4px | 7.9px |
| MacBook Air 13" | 1280px | 1.00 | 30px | 9px |

Ở scale 0.46, nhãn xúc xắc `BACK`/`HORN` **sẽ** render ở **4.1px** — đây không còn là "chữ nhỏ", đây là **không tồn tại**. Vùng chạm `.btn.xs` 42×18 co xuống **19×8px**.

**`zoom` chỉ thu nhỏ, không bao giờ phóng to.** Đo trên máy audit (cửa sổ 1440×900 → viewport CSS 1440×839): nội dung combat cao khoảng **540px** trong **839px** khả dụng — **299px, tức ~36% chiều dọc bị bỏ trống** trong khi số trên xúc xắc vẫn chỉ 30px. Đây là lãng phí thuần tuý.

**Sửa — 3 phần:**

**(a) Cho `--ui-scale` phóng to trên màn lớn**

> ⚠️ **Không dùng `clamp()` thuần CSS cho việc này.** `clamp(0.85, min(100vw/880, 100vh/720), 1.30)` là **CSS không hợp lệ**: `100vw / 880` cho ra một *length*, trong khi hai cận của `clamp()` là *number* — trộn kiểu làm cả khai báo bị bỏ qua, và `zoom:` cần một số không đơn vị. Game đã set `--ui-scale` bằng JS rồi, nên cứ giữ ở JS:

```js
function fitUI(){
  const BOARD_W = 880;   // 846px nội dung + 34px headroom
  const BOARD_H = 720;   // header 44 + enemies 214 + party 238 + tray 136 + bar 64 + gaps
  const s = Math.min(innerWidth / BOARD_W, innerHeight / BOARD_H);
  // Chặn trên = 1 khi đã có breakpoint (b) — nếu không hai cơ chế sẽ nhân chồng lên nhau
  const capped = innerWidth >= 1200 ? Math.min(s, 1.20) : 1;
  document.documentElement.style.setProperty('--ui-scale', Math.max(0.85, capped).toFixed(3));
}
addEventListener('resize', fitUI); fitUI();
```

**Kiểm chứng trên máy đã đo thật (viewport CSS 1440 × 839):**
`min(1440/880, 839/720) = min(1.636, 1.165) = **1.165**` → chặn ở 1.165.
`--die-num` 34px × 1.165 = **39.6px**; `--t1` 11px × 1.165 = **12.8px**.
Khoảng trống dọc 299px co xuống còn khoảng 90px — vẫn thở được, không còn lãng phí.

**Quan trọng:** khi bật (b) bên dưới, `--ui-scale` phải bị khoá về `1` ở mọi breakpoint ≤ 1199px, nếu không zoom và token component sẽ nhân chồng nhau (unit 158px × 1.20 = 190px, board 846px thành 1015px).

**(b) Thêm 4 breakpoint thật, thay đổi *kích thước component* chứ không zoom cả trang**

```css
/* ≥1200px — desktop, mặc định */
:root{ --unit-w:158px; --die-w:160px; --die-h:120px; --zone-gap:12px; }

/* 900–1199px — laptop hẹp / tablet landscape */
@media (max-width:1199px){
  :root{ --unit-w:140px; --die-w:140px; --die-h:112px; --zone-gap:10px; --die-num:30px; }
}

/* 600–899px — tablet portrait
   Kiểm tra ở cận dưới 600px: 5×104 + 4×8 + 2×8 = 568px ≤ 600 ✅
   (dùng 112px sẽ ra 616px và tràn ngay tại 600px) */
@media (max-width:899px){
  :root{ --unit-w:104px; --die-w:104px; --die-h:100px; --zone-gap:8px;
         --die-num:26px; --spr-w:76px; --ui-scale:1; }
  #app{ padding:8px 8px 12px; }
  .dp{ display:none; }            /* bỏ nhãn chữ, giữ icon */
  .track{ flex-wrap:wrap; row-gap:8px; }
}

/* <600px — phone */
@media (max-width:599px){
  :root{
    --unit-w:64px;  --die-w:64px;  --die-h:88px;
    --zone-gap:6px; --die-num:24px; --spr-w:56px; --hp-h:6px;
    --ui-scale:1;
  }
  .nm, .dp, .pips{ display:none; }
  .die{ padding:6px 4px; }
  .bottombar{ position:sticky; bottom:0; height:60px; }
  .btn--lg{ --btn-h:52px; }        /* ngón tay cần nhiều hơn con trỏ */
}
```

**Kiểm tra số học cho iPhone 393px:**
```
padding 2×8      =  16px
5 cột × 64px     = 320px
4 gap × 6px      =  24px
─────────────────────────
tổng             = 360px  ≤ 393px  ✅ (dư 33px)
```

**(c) Gợi ý xoay ngang cho phone portrait**

Bàn chơi 5 cột về bản chất là bố cục ngang. Trên `max-width:599px` và `orientation:portrait`, hiển thị một overlay 100vh:

```css
@media (max-width:599px) and (orientation:portrait){
  .rotate-hint{ display:flex; }   /* "Xoay ngang máy để chơi" + icon */
  .combat{ display:none; }
}
```
Đây là giải pháp rẻ và trung thực hơn nhiều so với việc ép 5 cột vào 393px.

---

### P0-7. Không có focus ring — bàn phím và screen reader không dùng được

**Hiện trạng:** Không tìm thấy rule `:focus-visible` nào. Game có phím tắt (`I`, `Esc`, `Space`, `Ctrl+Z`) nhưng **không có tab navigation**. Xúc xắc và unit là `div` có `onclick`, không phải `button`, nên không nhận focus.

**Sửa:**

```css
:where(button,[role="button"],a,input,[tabindex]):focus-visible{
  outline: 3px solid var(--acc);
  outline-offset: 2px;
  border-radius: var(--rad-sm);
}
.die:focus-visible, .unit:focus-visible{
  outline: 3px solid var(--acc); outline-offset: 3px;
}
```

Kèm ở tầng markup:
- `.die` → `<button type="button" role="option" aria-label="Xúc xắc 1, BACK, Shield 5, chưa dùng">`
- `.unit` → `<button type="button" aria-label="Sprout, máu 15 trên 20, khiên 7">`
- `.hpbar` → `role="progressbar" aria-valuenow aria-valuemin="0" aria-valuemax`
- Thứ tự tab: header → enemies → party → dice tray → bottom bar
- Phím `1`–`5` chọn xúc xắc, `Q`–`T` chọn mục tiêu (badge chữ cái đã có sẵn ở góc card — chỉ cần bind phím)

---

## 4. P1 — Ảnh hưởng trực tiếp đến hiểu luật và giữ chân người chơi mới

### P1-1. Menu giấu toàn bộ điều hướng phụ sau 2 tab xoay dọc ở mép màn hình

**Hiện trạng:** Màn MENU chỉ có `PLAY` (và `CONTINUE RUN` nếu có save). Ba mục `LUNACIA PASS`, `UNLOCKS`, `COLLECTION` nằm sau tab trái nhãn `PROGRESS`; một nhóm nữa nằm sau tab phải nhãn `LEARN` (nội dung chỉ lộ ra khi hover — audit này không mở nó vì cùng lý do khiến người chơi cũng sẽ không mở). Hai tab `.railtab` kích thước **33 × 141 px**, chữ xoay 90°, dán vào mép trái/phải viewport. Ở 1440px chúng cách nhau **~1400px**.

**Tại sao sai:**
1. Chữ xoay dọc ở mép màn hình đọc chậm hơn ~2× so với chữ ngang.
2. Người chơi mới không có lý do gì để rê chuột ra mép màn hình — vùng đó theo quy ước là chỗ của scrollbar và browser chrome.
3. Trên touch không có hover; `.rail:hover .railbody` không kích hoạt, phải tap trúng dải 33px.
4. Toàn bộ cụm nội dung menu (logo + subtitle + nút + dòng stats) nằm gọn trong một hộp **~429 × 166 px**. Trên viewport 1440×839 đó là **~6% diện tích màn hình**; 94% còn lại hoàn toàn trống.

**Sửa — bố cục menu mới, số cụ thể:**

```
┌──────────────────── viewport ───────────────────┐
│                                                  │
│              AXIE DICE TACTICS      44px t6      │
│           LUNACIA MUTANTS · v0.9    13px dim     │
│                    ↕ 32px                        │
│         ┌────────────────────────┐               │
│         │      CONTINUE RUN      │  320×56  acc  │
│         └────────────────────────┘               │
│                    ↕ 8px                         │
│         ┌────────────────────────┐               │
│         │        NEW RUN         │  320×48  ghost│
│         └────────────────────────┘               │
│                    ↕ 24px                        │
│   ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐   │
│   │  PASS  │ │COLLECT.│ │UNLOCKS │ │ CODEX  │   │ 4 × 152×72, gap 8
│   │  Lv 13 │ │ 17/55  │ │   —    │ │   —    │   │
│   └────────┘ └────────┘ └────────┘ └────────┘   │
│                    ↕ 24px                        │
│    16 runs · 1 win · best wave 20 · 1970 Shard   │ 13px dim
└──────────────────────────────────────────────────┘
```

- Cụm nội dung: `width: 640px`, căn giữa cả ngang lẫn dọc (`min-height:100dvh; display:grid; place-items:center`).
- Nút phụ hiển thị **số tiến độ ngay trên nút** khi có (`Lv 13` cho Pass, `17/55` mặt xúc xắc cho Collection) — biến điều hướng thành động lực. Lưu ý cả `17/55` (faces) lẫn `12/44` (relics) đều thuộc Collection, đừng gán `12/44` cho Unlocks.
- Xoá hoàn toàn `.rail`, `.railtab`, `.railbody`. Tiết kiệm ~40 dòng CSS và loại bỏ một pattern không hoạt động trên touch.

```css
.menu{ min-height:100dvh; display:grid; place-items:center; }
.menu-inner{ width:min(640px, 100% - 32px); display:flex; flex-direction:column;
             align-items:center; gap:0; }
.menu .logo{ font-size:var(--t6); letter-spacing:8px; color:var(--acc); }
.menu .sub { font-size:var(--t2); letter-spacing:3px; color:var(--dim); margin-top:8px; }
.menu .cta { width:320px; height:56px; margin-top:32px; font-size:var(--t4); }
.menu .cta2{ width:320px; height:48px; margin-top:8px; }
.menu-grid{ display:grid; grid-template-columns:repeat(4,152px); gap:8px; margin-top:24px; }
.menu-grid .btn{ height:72px; flex-direction:column; gap:4px; }
.menu-grid .btn small{ font-size:var(--t1); color:var(--acc); }
.menu .stats{ margin-top:24px; font-size:var(--t2); color:var(--dim); }
@media (max-width:599px){
  .menu-grid{ grid-template-columns:repeat(2,1fr); width:100%; }
  .menu .cta,.menu .cta2{ width:100%; }
}
```

---

### P1-2. Layout nhảy khi chọn xúc xắc (CLS trong game)

**Hiện trạng:** Khi chọn một xúc xắc hồi máu/khiên, badge preview (`SH +7`, `+3`, `+0`) xuất hiện **phía trên** mỗi card đồng minh và **đẩy toàn bộ hàng party dịch lên**. Đo được: `.zone.party` chuyển từ `y = 386` sang `y = 371` — **dịch 15px**. Khi bỏ chọn, nó nhảy ngược lại.

**Tại sao sai:** Người chơi đang nhắm chuột vào một card thì card đó di chuyển ra khỏi con trỏ. Đây là lỗi Fitts's Law cơ bản, và trong game cần thao tác nhanh thì nó gây misclick thật.

**Sửa:** Đặt trước một dải trống 24px cố định phía trên mỗi card, badge chỉ đổi `opacity` chứ không đổi luồng layout.

```css
.unit{ position:relative; margin-top:24px; }     /* chỗ trống cố định */
.preview-badge{
  position:absolute; top:-24px; left:50%; transform:translateX(-50%);
  height:20px; padding:0 8px; border-radius:var(--rad-sm);
  font-size:var(--t2); line-height:20px; white-space:nowrap;
  opacity:0; transition:opacity .12s;
  pointer-events:none;
}
.unit.previewing .preview-badge{ opacity:1; }
```

Tương tự với chip trạng thái (`Poison 2`) xuất hiện dưới thanh máu — hiện tại nó làm card địch cao thêm ~20px. Đặt sẵn một hàng chip cao 20px luôn tồn tại, rỗng khi không có trạng thái.

---

### P1-3. Mục tiêu "hợp lệ nhưng vô ích" vẫn sáng vàng như mục tiêu tốt

**Hiện trạng:** Chọn xúc xắc hồi máu, cả 5 đồng minh đều được viền vàng "hợp lệ". Fry đang `16/16` HP hiển thị badge **`+0`** — vẫn viền vàng đầy đủ, click vẫn tiêu tốn xúc xắc.

**Tại sao sai:** Vàng trong design system v0.8 có nghĩa "bạn có thể hành động ở đây". Nhưng "có thể" ≠ "nên". Một người chơi mới sẽ đốt một lượt heal vào con full máu và không hiểu tại sao không có gì xảy ra.

**Sửa — thêm bậc thứ 3 trong hệ thống mục tiêu:**

| Trạng thái | Viền | Nền card | Badge |
|---|---|---|---|
| Hợp lệ & hiệu quả | `2px solid #ffc857` + glow | không đổi | badge màu semantic, `opacity 1` |
| Hợp lệ nhưng `value = 0` | `2px dashed #59616e` | `opacity .55` | badge `+0` màu `--dim` |
| Không hợp lệ | `2px solid transparent` | `opacity .35` | không có |

```css
.unit.legal      { border-color:var(--acc); box-shadow:0 0 0 3px rgba(255,200,87,.22); }
.unit.legal.noop { border-style:dashed; border-color:var(--line);
                   box-shadow:none; opacity:.55; }
.unit.illegal    { opacity:.35; pointer-events:none; }
```

Kèm confirm nhẹ: nếu người chơi vẫn click mục tiêu `noop`, hiện toast 2s *"Fry đang đầy máu — xúc xắc này sẽ không có tác dụng. Click lần nữa để xác nhận."*

---

### P1-4. Không có combat log — người chơi không biết vừa xảy ra chuyện gì

**Hiện trạng:** Sau khi bấm `END TURN`, địch hành động, số máu thay đổi, floating text bay lên rồi biến mất trong ~0.6s. Không có bất kỳ lịch sử nào. Ở tốc độ `3x` thì gần như không đọc kịp.

**Tại sao sai với thể loại này:** Roguelike deckbuilder sống bằng việc người chơi hiểu **tại sao** mình mất 8 máu. Slay the Spire, Monster Train, Balatro đều có log hoặc tooltip lịch sử. Không có nó, người chơi thua mà không học được gì — đây là nguyên nhân churn số 1 của thể loại.

**Sửa — panel log gấp gọn ở cạnh phải bottom bar:**

- Chiều rộng khi mở: **280px**, chiều cao `= chiều cao vùng board`, `position: absolute; right: 0`
- Mỗi dòng: `font-size: 13px`, `line-height: 20px`, `padding: 6px 10px`, phân cách `1px solid var(--line)`
- Giữ **40 sự kiện** gần nhất, cuộn ngược
- Format: `[T4] Chomper → Sprout · 8 dmg (5 chặn bởi Shield)`
- Icon 12px màu semantic đứng đầu mỗi dòng
- Nút toggle `LOG` 32px trong header, mặc định **đóng**, nhớ trạng thái qua `localStorage`

Rẻ hơn (nếu không muốn làm panel): giữ floating text trên màn hình lâu hơn — hiện `--float-sz: 26px` biến mất quá nhanh. Tăng thời gian sống lên **1.4s** ở tốc độ 1x, và **không** rút ngắn theo `speed` (tốc độ chỉ nên rút ngắn animation di chuyển, không rút ngắn thời gian đọc số).

---

### P1-5. `ABANDON RUN` trông giống hệt `SAVE & QUIT`

**Hiện trạng:** Trong Settings, hai nút nằm cạnh nhau, cùng `background: var(--pan2)`, cùng `border: 2px solid var(--line2)`, cùng cỡ chữ, cùng chiều cao. Một nút lưu tiến độ, nút kia **xoá vĩnh viễn** một run 15–35 phút.

**Sửa:**

```css
.btn--danger{
  border-color:var(--dmg);
  color:var(--dmg);
  background:transparent;
}
.btn--danger:hover{ background:rgba(255,107,107,.12); }
```

- Đẩy `ABANDON RUN` xuống một hàng riêng, cách `SAVE & QUIT` **24px**, có đường kẻ `1px solid var(--line)` ngăn giữa.
- Bắt buộc modal xác nhận: *"Bỏ run này? Bạn đang ở wave 1/12. Gene Shard và Lunacia XP đã kiếm được vẫn giữ."* — nút hủy là mặc định (focus), nút xác nhận là `--danger`.

**Thiếu trong Settings (bổ sung):**
- `Reduce motion` toggle (CSS đã có `prefers-reduced-motion` — cho người chơi bật thủ công)
- `UI scale` slider 85%–120%, step 5% — ghi đè `--ui-scale`
- `Colorblind mode`: bổ sung ký hiệu hình cho damage/shield/heal (▲ ◆ ✚) thay vì chỉ dựa vào màu
- `SOUND ON` đang xuống 2 dòng vì nút quá hẹp (`96px`). Cho `min-width: 120px`.
- Slider volume dài **580px** — thừa. Giới hạn `max-width: 320px`, số % đặt bên phải cách 12px.

---

### P1-6. Card Team Select — hierarchy đảo ngược

**Hiện trạng đo được (`.pick` = 196 × 246 px):**

| Phần tử | Cỡ | Màu | Chiều cao |
|---|---|---|---|
| `.spr` (sprite Axie) | 100×100 | — | 100px (**41%** card) |
| `.nm` (tên) | 13px | `#e9edf3` | 15px |
| `.cls` (`PLANT · HP 17`) | 9px | `#59616e` | 10px |
| `.pn` (`BULWARK`) | 9px | `#ffc857` | 10px |
| `.pd` (mô tả passive, 2–3 dòng) | 9px, lh 13.5 | `#8b95a4` | 41px |
| `.minidie` (6 mặt xúc xắc) | 9px, ô `.mf` 25×16 | `#8b95a4` | 16px |

**Vấn đề:** Sprite chiếm **41% chiều cao card** (100px trên 246px) nhưng mang **0 thông tin quyết định** — 6 con Axie đều là cục tròn dễ thương, nhìn sprite không suy ra được build. Trong khi đó `.pd` — thứ duy nhất người chơi thực sự cần đọc để chọn team — chiếm 17% và ở cỡ chữ nhỏ nhất.

Sáu ô `.mf` (mặt xúc xắc) mỗi ô **25×16px** chứa 1 icon + 1 số ở 9px. Đây là mật độ của một sparkline, không phải của một thông tin cần đọc.

**Sửa — card mới 220 × 300:**

```
┌──────────── 220px ─────────────┐
│ ┌──────┐  Sprout          20px │   ← sprite thu còn 72×72, đặt bên trái
│ │ 72px │  PLANT · HP 17   11px │
│ └──────┘                       │
│ ━━━━━━━━━━━━━━ 3px PLANT color │
│                                │
│ BULWARK                  11px  │   ← acc
│ Every Shield you create is     │   ← 15px !! (từ 9px)
│ increased by 2. An Axie with   │      lh 22px, --dim
│ 10+ Shield gains Thorns 2.     │
│                                │
│ ┌────┬────┬────┬────┬────┬────┐│   ← 6 ô ~30×32 (grid 1fr), gap 2
│ │◆ 4│◆ 3│✚ 2│◆ 2│✚ 3│⚡1│    │      icon 14px + số 13px
│ └────┴────┴────┴────┴────┴────┘│
└────────────────────────────────┘
```

```css
.pick{
  width:220px; min-height:300px;
  padding:14px 14px 12px;
  display:flex; flex-direction:column; gap:0;
  border:2px solid var(--line2); border-radius:var(--radius);
  background:var(--pan);
}
.pick-head{ display:flex; align-items:center; gap:12px; }
.pick .spr{ width:72px; height:72px; flex:none; }
.pick .nm { font-size:var(--t4); color:var(--txt); }         /* 20px */
.pick .cls{ font-size:var(--t1); color:var(--dim); letter-spacing:1px; }
.pick-rule{ height:3px; background:var(--class-color); margin:12px 0; border-radius:2px; }
/* --class-color KHÔNG nằm trong :root — set inline theo từng card:
   <div class="pick" style="--class-color:#5fd68a"> cho PLANT, v.v. */
.pick .pn { font-size:var(--t1); color:var(--acc); letter-spacing:1px; margin-bottom:6px; }
.pick .pd { font-size:var(--t3); line-height:22px; color:var(--dim); flex:1; }  /* 15px */
.minidie{ display:grid; grid-template-columns:repeat(6,1fr); gap:2px; margin-top:12px; }
.mf{ height:32px; display:flex; align-items:center; justify-content:center; gap:3px;
     background:var(--pan2); border-radius:var(--rad-sm); font-size:var(--t2); }
.mf .icow{ width:14px; height:14px; }
```

**Số đếm `5/5` (`.tcount`)** hiện là chữ 11px màu `--dim` nằm cách nút `RANDOM` 10px về bên trái, không có nhãn. Đổi thành chip 32px cao, `ĐÃ CHỌN 5/5`, màu `--acc` khi đủ 5 và `--dim` khi chưa, đặt **ngay bên trái nút `START RUN`** — nơi mắt người chơi đang nhìn khi chuẩn bị bấm.

**`START RUN` phải disabled khi chưa đủ 5.** Hiện chưa kiểm chứng được hành vi này; nếu chưa có, thêm.

---

### P1-7. Xúc xắc có 2 giải phẫu khác nhau

**Hiện trạng:** Ô xúc xắc `.die` = **158 × 104 px**, cấu trúc:
```
.dp   nhãn "BACK"     9px, ls 2px, --faint    ← contrast 2.9:1 ❌
.di   icon body part  22×22, màu semantic
.dv   giá trị         30px, màu semantic
.pips 6 ô 9×9         chỉ báo mặt nào đang hiện
```

Nhưng mặt có **từ khoá** (`Weaken 2`, `Cantrip`) lại render `.dv` **rỗng** và thay bằng chữ 10px. Kết quả: 4 ô có số khổng lồ 30px, 1 ô có chữ tí hon 10px — nhịp thị giác của cả hàng bị gãy, và mặt quan trọng nhất lại là mặt khó đọc nhất.

**Sửa — một giải phẫu duy nhất:**

```
┌──────── 160px ────────┐
│  BACK           11px  │  ← --dim (từ --faint), ls 1.5px
│                       │
│        ◆ 24px         │  ← icon
│         34            │  ← --die-num, màu semantic
│      Weaken 2   13px  │  ← dòng keyword, LUÔN tồn tại (rỗng nếu không có)
│                       │
│ ▪ ▪ ▪ ▫ ▪ ▪    10px   │  ← pips, gap 4
└───────────────────────┘
        cao 120px
```

Mặt có keyword vẫn giữ số lớn (giá trị của keyword, ví dụ `Weaken **2**`), keyword là dòng phụ 13px bên dưới. Chiều cao ô cố định 120px cho mọi mặt — không còn nhảy layout khi reroll.

```css
:root{ --die-w:160px; --die-h:120px; --die-num:34px; --die-kw:13px; }
.die{
  box-sizing:border-box;                 /* bắt buộc: có cả height lẫn padding */
  width:var(--die-w); height:var(--die-h);
  padding:10px 8px 8px;
  position:relative;                     /* neo cho .rsel */
  display:grid;
  grid-template-rows:14px 24px 1fr 16px 14px;   /* dp · di · dv · dkw · pips = 5 hàng, 5 con */
  align-items:center; justify-items:center;
  background:var(--pan2); border:2px solid transparent; border-radius:var(--radius);
}
.dp{ font-size:var(--t1); letter-spacing:1.5px; color:var(--dim); }
.di{ width:24px; height:24px; }
.dv{ font-size:var(--die-num); line-height:1; }
.dkw{ font-size:var(--die-kw); color:var(--dim); min-height:16px; }  /* luôn tồn tại */
.pips{ display:flex; gap:4px; }
.pip { width:10px; height:10px; border-radius:2px; background:var(--pan3); }
.pip.on{ background:var(--acc); }
```

**Pips cần chú giải.** 6 ô vuông nhỏ dưới mỗi xúc xắc không tự giải thích. Thêm `title="Mặt 4 trên 6"` và, ở wave 1, một dòng hint 11px: *"6 ô = 6 mặt của xúc xắc · ô vàng là mặt đang hiện"*.

**Xúc xắc đã dùng** hiện chỉ giảm opacity xuống ~0.3 nhưng vẫn chiếm nguyên 158px. Đề xuất: giữ nguyên vị trí (để không nhảy layout) nhưng thêm dấu ✓ 20px màu `--dim` ở giữa và `filter: grayscale(1)` — người chơi phân biệt "đã dùng" với "vô hiệu" ngay.

---

### P1-8. Panel không tách được khỏi nền — contrast 1.13:1

**Hiện trạng:**

| Cặp | Tỷ lệ | Ngưỡng non-text (WCAG 1.4.11) |
|---|---|---|
| `--pan #191d23` trên `--bg #0e1013` | **1.13 : 1** | 3 : 1 |
| `--line #2c333d` trên `--bg` | **1.50 : 1** | 3 : 1 |
| `--line2 #3f4956` trên `--bg` | **2.09 : 1** | 3 : 1 |

Cả ba đều fail. Trên màn hình chất lượng thấp, laptop nghiêng, hoặc ngoài sáng, các card về cơ bản **biến mất** khỏi nền.

**Điểm mấu chốt:** chênh lệch giữa hai bề mặt (`--pan` vs `--bg`) *không* phải là yêu cầu của WCAG. Cái **bắt buộc** đạt 3:1 theo 1.4.11 là **đường viền** phân định component. Hiện `--line2` chỉ đạt 2.09:1 — nghĩa là game vừa có bậc bề mặt quá nhỏ (1.13:1) **vừa** có viền dưới chuẩn. Không có kênh nào gánh được việc tách lớp.

**Sửa — bảng surface mới, mọi tỷ lệ đều đã tính lại:**

| Token | Cũ | **Mới** | Tỷ lệ đo được |
|---|---|---|---|
| `--bg` | `#0e1013` | `#0b0d10` | nền gốc |
| `--pan` | `#191d23` | `#1e242c` | **1.25:1** vs `--bg` (từ 1.13) |
| `--pan2` | `#212730` | `#2a323d` | **1.21:1** vs `--pan` |
| `--pan3` | `#2c333e` | `#39434f` | **1.29:1** vs `--pan2` |
| `--line` (kẻ nội bộ, trang trí) | `#2c333d` | `#4a5563` | 2.06:1 vs `--pan` — không phải ranh giới bắt buộc |
| `--line2` (**viền card**) | `#3f4956` (2.09:1 ❌) | `#707c8c` | **4.59:1** vs `--bg` · **3.68:1** vs `--pan` · **3.05:1** vs `--pan2` — ✅ đạt 1.4.11 ở mọi ngữ cảnh |
| `--txt` | `#e9edf3` | giữ nguyên | 13.30:1 vs `--pan` · 11.02:1 vs `--pan2` |
| `--dim` | `#8b95a4` | `#99a3b2` | **6.13:1** vs `--pan` · **5.08:1** vs `--pan2` · 7.63:1 vs `--bg` — ✅ AA ở mọi nền |
| `--off` (disabled) | `opacity .28` (1.58:1 ❌) | `#7d8794` | **4.29:1** vs `--pan` · **3.55:1** vs `--pan2` |

> `--dim` cũ (`#8b95a4`) đạt 5.58:1 trên `--pan` cũ nhưng chỉ **4.27:1** trên `--pan2` mới — dưới ngưỡng AA. Vì thế phải nâng lên `#99a3b2`.

Màu semantic kiểm tra lại trên `--pan2` mới (`#2a323d`) — tất cả đều đạt AA cho chữ nhỏ:
`--acc` 8.42 · `--heal` 7.07 · `--shd` 5.81 · `--man` 4.86 · `--dmg` 4.67. Không cần chỉnh màu semantic nào.

```css
:root{
  --bg:#0b0d10; --pan:#1e242c; --pan2:#2a323d; --pan3:#39434f;
  --line:#4a5563;    /* kẻ trang trí, KHÔNG dùng làm ranh giới component */
  --line2:#707c8c;   /* viền card — đây mới là thứ gánh việc tách lớp */
  --txt:#e9edf3; --dim:#99a3b2; --off:#7d8794;
}
.unit,.die,.pick,.nodecard,.bottombar,.track{
  border:2px solid var(--line2);
  box-shadow:0 1px 0 rgba(0,0,0,.55), 0 4px 12px rgba(0,0,0,.35);
}
```

---

### P1-9. Header combat — icon không nhãn, không tooltip

**Hiện trạng:** `.trk-right` chứa `TURN 1` · 🌙`2/2` · 💎`0` · `UNDO` · `1x 2x 3x` · `INFO` · `SET` trong một dải 415×18px.

- Icon mặt trăng + `2/2` = số lần reroll còn lại — **không có nhãn nào nói vậy**
- Icon kim cương + `0` = Gene Shard — cũng không nhãn
- `1x 2x 3x` không có nhãn "tốc độ"

**Sửa:**
- Mỗi cụm số thành một chip cao 32px: `icon 14px` + nhãn 11px `--dim` + giá trị 13px màu semantic. Ví dụ: `🌙 REROLL 2/2`.
- Thêm `title` cho mọi icon.
- Nhóm `1x/2x/3x` bọc trong một segmented control có nhãn `SPEED` 11px bên trái.
- Tăng chiều cao `.track` từ **34px → 44px** để chứa control 32px + padding 6px.

**Dãy 12 chấm wave:** đẹp nhưng câm. Thêm legend một lần ở wave 1: `● thường  ◆ elite  ⬢ boss`, và `title` cho từng chấm (`Wave 7 · Elite`).

---

## 5. P2 — Đánh bóng & nhất quán

### P2-1. Codex — dòng quá dài

**Đo được:** chiều rộng thực tế của `.cxp` (đoạn văn trong Codex) là **602px** — lấy trực tiếp bằng `getBoundingClientRect()`, không suy ra từ padding. Cỡ chữ `font-size: 11px`, font Courier New.

Advance width của Courier New đo trực tiếp bằng `canvas.measureText` trên chính bản build: **6.601 px/ký tự @11px**, **9.001 px/ký tự @15px**.

```
602 / 6.601 = 91,2 ký tự/dòng   ← hiện tại (11px)
602 / 9.001 = 66,9 ký tự/dòng   ← sau khi lên 15px
```

Ngưỡng dễ đọc cho văn bản dài: **45–75 ký tự**. 91 là quá dài — mắt mất dấu khi xuống dòng. **Chỉ cần tăng cỡ chữ lên 15px là rơi đúng vào 67 ký tự, không phải đụng đến chiều rộng pane.** Một thay đổi sửa được hai vấn đề.

```css
.cxp  { font-size:var(--t3); line-height:24px; color:var(--dim); }  /* 11px → 15px */
.cxtd { font-size:var(--t2); color:var(--dim); }   /* từ 9px/--faint (2.04:1) */
.cxtab{ min-height:40px; font-size:var(--t2); }    /* từ 31px cao / 11px */
```

Bổ sung: **ô tìm kiếm** ở đầu rail trái (`height: 36px`), lọc theo tên keyword/relic. Codex có 9 section — tìm một keyword cụ thể hiện phải đọc thủ công.

---

### P2-2. Collection — 3 kiểu căn lề trên cùng một màn

**Hiện trạng:** Tiêu đề `COLLECTION` và dòng `Faces 17/55 · Relics 12/44` **căn giữa**; heading `RELIC (12/44)` và `DIE FACES (17/55)` **căn trái sát mép x=12**; heading `BOSSES DEFEATED (5/6)` lại **căn giữa**; nút `BACK` **rộng 838px** trải hết viewport.

**Sửa:**
- Bọc toàn bộ trong `.container{ width:min(1080px, 100% - 48px); margin-inline:auto }`
- Mọi heading section: căn trái, `font-size: var(--t4)`, `margin: 32px 0 12px`
- Nút `BACK`: `width: 160px`, đặt trên cùng bên trái dưới dạng `‹ BACK`, không phải một thanh full-width ở đáy
- **Hiện cả mục chưa mở khoá** dưới dạng chip mờ có ổ khoá: hiện tại 38/55 mặt xúc xắc chưa mở đơn giản là *không tồn tại* trên màn hình. Người chơi không thấy được mình đang thiếu gì → mất động lực sưu tầm. Chip khoá: `opacity .4`, `border-style: dashed`, nội dung `? ? ?`.

---

### P2-3. Info panel — bảng bỏ trống ~3/4 chiều rộng

**Hiện trạng:** Modal rộng ~850px, hàng bảng trải từ x≈355 đến x≈1145 (**790px**). Nội dung thật chỉ nằm trong x≈365 → 570: index · icon · part · value · keyword — tức **~205px được dùng, ~585px (74%) bỏ trống**.

**Sửa:** Đặt `grid-template-columns: 28px 24px 92px 56px 1fr;` và giới hạn `max-width: 560px` cho bảng, hoặc dùng phần trống để hiển thị **2 Axie cạnh nhau** (2 cột × 420px) — người chơi so sánh build nhanh hơn nhiều so với cuộn dọc qua 5 bảng.

Row height hiện ~23px với chữ 9–11px. Nâng lên **32px** với chữ 13px.

Nút `CLOSE` 11px ở góc phải: nâng lên cỡ `.btn--sm` 32px cao. Thêm click-outside-to-close và `Esc` (Esc đã có).

---

### P2-4. Unit chết vẫn chiếm chỗ và làm lệch hàng

**Hiện trạng:** Gooey Slime chết (`0/14`) — card chuyển sang xám nhưng **vẫn giữ nguyên 158px** trong hàng, và card của Chomper còn sống trở nên **cao hơn** card đã chết (vì card chết mất hàng intent). Hàng địch không căn giữa lại.

**Sửa:**
- Giữ chỗ 400ms (để animation chết chạy), sau đó `width: 0; margin: 0; opacity: 0` với `transition: all .35s` → hàng tự căn giữa lại mượt.
- Hoặc giữ chỗ vĩnh viễn nhưng **khoá chiều cao card** bằng `min-height` cố định để hàng không so le, và hiển thị bia mộ (sprite xám 40% + chữ `DOWN` 13px).

Chọn phương án 1 cho địch (dọn màn hình), phương án 2 cho đồng minh (người chơi cần biết ai đã ngã và có thể hồi sinh).

---

### P2-5. Map — "CHOOSE YOUR PATH" nhưng chỉ có một lựa chọn

**Hiện trạng:** Wave 1 hiển thị tiêu đề `CHOOSE YOUR PATH` với đúng **1 node**. Codex nói rõ mỗi wave chọn `one of two nodes`. Ở wave 1 dường như bị ép còn 1.

**Sửa:** Nếu chỉ có 1 node, đổi tiêu đề thành `NEXT · WAVE 1` và bỏ chữ "choose". Đừng bảo người chơi chọn khi họ không có gì để chọn — nó làm giảm độ tin cậy của mọi prompt về sau.

Node card hiện `.nodecard` không đo được kích thước cố định; đề xuất chuẩn hoá: **280 × 160px**, dải màu trên 4px theo loại node, icon 32px, tiêu đề 20px, mô tả 13px, meta 13px màu `--acc`.

---

### P2-6. Bottom bar — hierarchy phẳng

**Hiện trạng:** `.bottombar` cao 55px chứa `MANA 0` (pill 77×35) · `no active cards yet` (9px `--faint`, contrast 3.05:1) · `REROLL 2` (98×35) · `END TURN` (98×35). Hai nút cuối cùng cỡ, cùng nền `--pan2`, chỉ khác màu chữ.

**Sửa:**
- `END TURN` là hành động chính → `.btn--lg`, **140 × 48px**, nền đặc `--acc`, chữ `#1a1503`
- `REROLL` là hành động phụ → `.btn--md`, **120 × 40px**, ghost viền `--shd`
- Hiển thị **phím tắt trên nút**: `END TURN ␣`, `REROLL R` — 11px `--dim` ở góc phải nút
- `MANA`: pill cao **40px**, nhãn 11px + giá trị **20px** màu `--man`
- `no active cards yet` → 13px `--dim`, và khi có relic/card thì hiển thị chip 28px cao
- Chiều cao bar: 55px → **64px**

---

### P2-7. Hint bar

**Hiện trạng:** 9px, `--faint`, contrast 3.05:1, đặt cách bottom bar 8px, cách mép dưới viewport ~85px.

Design system v0.8 nói hint bar "nghỉ hưu sau wave 1" — nhưng nó vẫn hiển thị ở turn 5 wave 1, nghĩa là logic đó tính theo wave chứ không theo lần hiển thị. Ở wave 1 người chơi đã đọc nó 5 lần rồi.

**Sửa:** 13px `--dim`. Ẩn sau **3 lượt đầu tiên của run đầu tiên**, không phải sau wave 1. Sau đó chỉ hiện khi có tình huống cụ thể (`Không đủ Mana`, `Xúc xắc này không có mục tiêu hợp lệ`) với nền `--pan2` và `role="status"`.

---

## 6. Bảng token đề xuất (dán thẳng vào đầu `src/style.css`)

```css
:root{
  /* ── TYPE (6 bậc, tối thiểu 11px) ─────────────────────────── */
  --t1:11px;  /* nhãn ALL-CAPS ≤12 ký tự. CẤM dùng cho câu văn */
  --t2:13px;  /* chữ phụ, chip, giá trị số nhỏ */
  --t3:15px;  /* BODY MẶC ĐỊNH — mô tả, tooltip, Codex */
  --t4:20px;  /* tiêu đề section, nút lớn */
  --t5:28px;  /* tiêu đề màn hình */
  --t6:44px;  /* logo */
  --die-num:34px; --die-kw:13px; --intent-v:20px; --float-sz:28px;
  --font: "JetBrains Mono","IBM Plex Mono",ui-monospace,"Courier New",monospace;

  /* ── SPACING (lưới 4px) ───────────────────────────────────── */
  --s1:4px; --s2:8px; --s3:12px; --s4:16px; --s5:24px; --s6:32px; --s7:48px;

  /* ── CONTROL HEIGHT ───────────────────────────────────────── */
  --ctl-sm:32px; --ctl-md:40px; --ctl-lg:48px; --tap-min:44px;

  /* ── SURFACE (viền đạt ≥3:1 ở mọi nền — WCAG 1.4.11) ──────── */
  --bg:#0b0d10; --bg-top:#151a20;
  --pan:#1e242c;     /* 1.25:1 vs --bg  */
  --pan2:#2a323d;    /* 1.21:1 vs --pan */
  --pan3:#39434f;    /* 1.29:1 vs --pan2 */
  --line:#4a5563;    /* kẻ trang trí. KHÔNG dùng làm ranh giới component */
  --line2:#707c8c;   /* viền card — 4.59 / 3.68 / 3.05 vs bg / pan / pan2 ✅ */
  --radius:10px; --rad-sm:6px; --bd:2px;

  /* ── TEXT (đã kiểm tra AA trên cả 3 bậc surface) ───────────── */
  --txt:#e9edf3;     /* 13.30 / 11.02  trên --pan / --pan2 */
  --dim:#99a3b2;     /*  6.13 /  5.08  — bậc mờ nhất được phép cho câu văn */
  --off:#7d8794;     /*  4.29 /  3.55  — trạng thái disabled */
  /* --faint ĐÃ BỊ XOÁ. Không có token chữ nào dưới 4.5:1 nữa. */

  /* ── SEMANTIC (giữ nguyên v0.8 — đã verify AA trên --pan2) ── */
  --acc:#ffc857;  /* 8.42 */   --heal:#5fd68a; /* 7.07 */
  --shd:#63b3ff;  /* 5.81 */   --man:#b388ff;  /* 4.86 */
  --dmg:#ff6b6b;  /* 4.67 */   --poi:#a8d84a;
  --burn:#ff9a4d; --deb:#ff8fc7;

  /* ── HP STATE (mã hoá nguy hiểm, KHÔNG mã hoá phe) ─────────── */
  --hp-full:#5fd68a;  /* 100–51% */
  --hp-low:#ffc857;   /*  50–26% */
  --hp-crit:#ff6b6b;  /*  25– 1% */
  --hp-h:8px;
  --hp-ink:#0b0e12;   /* 10.57 / 12.57 / 6.97 trên 3 màu fill trên ✅ */

  /* ── RARITY (không dùng cho việc gì khác) ─────────────────── */
  --r0:#9aa4b2; --r1:#63b3ff; --r2:#b388ff; --r3:#ffc857; --r4:#ff5f8f;

  /* ── LAYOUT ───────────────────────────────────────────────── */
  --unit-w:158px; --die-w:160px; --die-h:120px;
  --spr-w:100px; --spr-big:164px; --spr-guide:64px;
  --zone-gap:12px;
  /* --ui-scale KHÔNG set được bằng CSS thuần (xem P0-6a).
     Đặt bằng JS: min(innerWidth/880, innerHeight/720), kẹp [0.85, 1.20],
     và khoá về 1 ở mọi breakpoint ≤1199px. */
  --ui-scale:1;
}
```

---

## 7. Bảng tra nhanh: số cũ → số mới

| Thành phần | Hiện tại | Đề xuất | Lý do |
|---|---|---|---|
| Chữ body nhỏ nhất | 9px | **15px** | x-height 3.8px không đọc được |
| Nhãn ALL-CAPS | 9px | **11px** | tối thiểu cho all-caps mono |
| Số xúc xắc `--die-num` | 30px | **34px** | thông tin số 1 trên màn hình |
| Keyword xúc xắc | 10px | **13px** | ngang hàng với số |
| Intent địch `--intent-v` | 15px | **20px** | quyết định phòng thủ |
| Ô xúc xắc `.die` | 158×104 | **160×120** | chứa dòng keyword cố định |
| Pip | 9×9, gap 2 | **10×10, gap 4** | tách rời rõ ở 6 ô |
| Nút reroll `.rsel` | 22×22 | **28×28** (hit 44) | dưới AA 24px |
| Nút `xs` | 42×18 | **xoá → 32px** | dưới cả AA lẫn AAA |
| Nút `sm` | h 27 | **h 32** | — |
| Nút chính | h 47 | **h 48** | chuẩn hoá |
| Thanh HP | h 16, chữ đè | **h 8, chữ tách ra** | contrast 1.65:1 |
| Card unit | 158×198 | **158×222** | +24px chỗ đặt sẵn cho preview badge |
| Card Team Select | 196×246 | **220×300** | mô tả passive từ 9→15px |
| Ô mini-die | 25×16 | **~30×32** (`repeat(6,1fr)` trong 192px nội dung) | — |
| Header `.track` | h 34 | **h 44** | chứa control 32px |
| Bottom bar | h 55 | **h 64** | chứa nút 48px |
| Bottom `END TURN` | 98×35 | **140×48** | hành động chính |
| Codex body | 11px, 91 ký tự/dòng | **15px, 67 ký tự/dòng** | 91 vượt ngưỡng 75 |
| Codex table cell | 9px `--faint` | **13px `--dim`** | contrast 2.04:1 |
| Modal row | h 23 | **h 32** | — |
| Zone gap | 8px | **12px** | tách nhóm rõ hơn |
| `--ui-scale` | JS, trần = 1 | **JS, kẹp [0.85, 1.20], chỉ ≥1200px** | 36% chiều dọc bỏ trống |
| Media query theo width | **0** | **4 breakpoint** | — |

---

## 8. Thứ tự triển khai đề xuất

| # | Việc | Mức | Ước tính | Rủi ro |
|---|---|---|---|---|
| 1 | Sửa `TURN undefined` (P0-1) | P0 | 0.25 giờ | Không |
| 2 | Contrast chữ HP + sửa/xoá `.hpchip` (P0-2) | P0 | 1 giờ | Thấp |
| 3 | HP đổi màu theo % HP, bỏ override theo phe (P0-3) | P0 | 1 giờ | Thấp |
| 4 | Bảng token type mới + xoá `--faint` (P0-4) | P0 | 2 giờ | Trung bình — rà toàn bộ file |
| 5 | Hệ nút 3 cỡ, bỏ `xs`, thêm focus ring (P0-5, P0-7) | P0 | 3 giờ | Trung bình |
| 6 | 4 breakpoint + khoá `--ui-scale` (P0-6) | P0 | 6 giờ | Cao — cần QA đủ máy |
| 7 | Bỏ rail, làm lại Menu (P1-1) | P1 | 3 giờ | Thấp |
| 8 | Chống layout shift: preview badge, status chip (P1-2) | P1 | 2 giờ | Thấp |
| 9 | Trạng thái mục tiêu `noop` (P1-3) | P1 | 2 giờ | Thấp |
| 10 | Combat log (P1-4) | P1 | 6 giờ | Trung bình — cần state mới |
| 11 | `ABANDON RUN` danger + modal xác nhận + mục Settings mới (P1-5) | P1 | 2 giờ | Không |
| 12 | Làm lại card Team Select (P1-6) | P1 | 3 giờ | Thấp |
| 13 | Giải phẫu xúc xắc thống nhất (P1-7) | P1 | 3 giờ | Trung bình |
| 14 | Nâng bậc surface & viền (P1-8) | P1 | 1 giờ | Thấp |
| 15 | Header combat: chip có nhãn, legend wave (P1-9) | P1 | 1.5 giờ | Thấp |
| 16 | Codex: cỡ chữ + ô tìm kiếm (P2-1) | P2 | 2 giờ | Thấp |
| 17 | Collection: container + chip khoá (P2-2) | P2 | 2 giờ | Thấp |
| 18 | Info panel: lưới cột + 2 Axie cạnh nhau (P2-3) | P2 | 2 giờ | Thấp |
| 19 | Xử lý unit chết (P2-4) | P2 | 1.5 giờ | Thấp |
| 20 | Map: tiêu đề đúng ngữ cảnh + chuẩn hoá node card (P2-5) | P2 | 1 giờ | Thấp |
| 21 | Bottom bar: phân cấp nút + phím tắt (P2-6) | P2 | 1.5 giờ | Thấp |
| 22 | Hint bar contextual (P2-7) | P2 | 0.5 giờ | Thấp |
| | **Tổng** | | **47.25 giờ** | |

Nếu chỉ có 1 ngày: làm **#1 → #5** (7.25 giờ). Nếu có 2 ngày: thêm **#6** — đó là hạng mục đắt nhất nhưng cũng là hạng mục duy nhất mở được game cho người chơi mobile.

---

## 9. Checklist QA sau khi sửa

**Đo lại bằng script, không bằng mắt:**

```js
// 1. Không còn chữ dưới 11px
[...document.querySelectorAll('#app *')]
  .filter(e => !e.children.length && e.textContent.trim())
  .filter(e => parseFloat(getComputedStyle(e).fontSize) < 11)
  .map(e => e.className + ' → ' + getComputedStyle(e).fontSize);
// kỳ vọng: []

// 2. Không còn vùng chạm dưới 44px
[...document.querySelectorAll('button,[role=button],.die,.unit')]
  .map(e => ({c:e.className, r:e.getBoundingClientRect()}))
  .filter(o => o.r.height < 44 || o.r.width < 44);
// kỳ vọng: [] (hoặc chỉ những phần tử có ::before mở rộng hit-area)

// 3. Không còn --faint dùng cho chữ
[...document.querySelectorAll('#app *')]
  .filter(e => !e.children.length && e.textContent.trim())
  .filter(e => getComputedStyle(e).color === 'rgb(89, 97, 110)');
// kỳ vọng: []

// 4. Board vừa 393px không cần zoom
// mở DevTools device toolbar → iPhone 15 Pro → kiểm tra scrollWidth <= 393
document.documentElement.scrollWidth;
```

**Kiểm thủ công:**

- [ ] Tab qua toàn bộ combat screen — mọi phần tử tương tác đều có focus ring nhìn thấy rõ
- [ ] `prefers-reduced-motion: reduce` — không còn animation nào chạy (kể cả nhấp nháy HP crit)
- [ ] Zoom trình duyệt 200% — không có chữ nào bị cắt hoặc chồng
- [ ] iPhone 15 Pro portrait: hiện gợi ý xoay ngang; landscape: chơi được đủ 5 xúc xắc
- [ ] iPad mini portrait 744px: bàn chơi vừa, không zoom
- [ ] Mô phỏng deuteranopia (Chrome DevTools → Rendering → Emulate vision deficiencies): phân biệt được damage / shield / heal **mà không cần màu**
- [ ] Chọn xúc xắc heal → bỏ chọn → không có element nào dịch chuyển 1px
- [ ] Địch tụt xuống 20% HP → thanh máu đổi đỏ và nhấp nháy
- [ ] `ABANDON RUN` → phải qua modal xác nhận, nút hủy được focus mặc định
- [ ] Đọc trọn 1 section Codex mà không phải rướn người về màn hình

---

## 10. Ba điều nên giữ nguyên

Audit không phải chỉ để chê. Ba quyết định sau là đúng và nên bảo vệ khi refactor:

1. **Bảng màu semantic.** Vàng = hành động được, đỏ = damage, xanh dương = shield, tím = mana. Nhất quán tuyệt đối trên mọi màn hình. Đây là phần mạnh nhất của v0.8 — đừng đụng vào.
2. **Nền xám khử bão hoà.** Quyết định "chỉ sprite Axie được bão hoà" là đúng về mặt hướng mắt. Vấn đề chỉ là các bậc xám hiện quá sát nhau, không phải chọn sai hướng.
3. **Preview số sát thương/khiên trên đầu mục tiêu.** `-2`, `SH +7` xuất hiện ngay khi chọn xúc xắc là feedback loop rất tốt, ngang tầm với các game hàng đầu trong thể loại. Chỉ cần sửa việc nó đẩy layout.

---

## Nguồn

- Bản build được audit: https://axiedice.vercel.app (v0.9, truy cập 14/08/2026)
- Số đo lấy trực tiếp từ `getComputedStyle` / `getBoundingClientRect` trên bản build đang chạy
- Contrast tính theo WCAG 2.1 relative luminance
- `claude/UI_DESIGN_SYSTEM_v0.8.md` (project doc) — dùng để đối chiếu ý đồ thiết kế gốc
