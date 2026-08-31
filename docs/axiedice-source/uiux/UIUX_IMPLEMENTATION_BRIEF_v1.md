# IMPLEMENTATION BRIEF — Axie Dice Tactics UI/UX v0.9 → v1.0

> **File này viết cho một AI coding agent, không phải cho người đọc.**
> Đọc hết §0 → §4 trước khi sửa dòng code đầu tiên. Sau đó thực thi §5 theo đúng thứ tự task.
> Mọi task đều có tiêu chí nghiệm thu **chạy được bằng máy** — không có chỗ nào để "tự đánh giá là xong".

**Kèm theo brief này:**

| File | Vai trò |
|---|---|
| `IMPLEMENTATION_BRIEF.md` | File này. Nguồn sự thật duy nhất. |
| `verify.mjs` | Trình chấm điểm Playwright. 32 check. Chạy sau **mỗi** phase. |
| `REFERENCE.html` | Bản triển khai mẫu đã PASS 32/32. Dùng để đối chiếu khi bí, **không** copy nguyên vào game. |

---

## 0. Nhiệm vụ và cách làm việc

### 0.1 Bạn là ai trong việc này

Bạn là engineer thực thi một spec UI/UX đã được audit và verify. Bạn **không** phải designer trong task này. Mọi con số trong file này đã được đo trên bản build thật và tính toán lại bằng công thức WCAG — **đừng thay đổi chúng vì cảm thấy số khác đẹp hơn**. Nếu bạn tin một con số sai, hãy dừng lại, ghi lý do vào `DEVIATIONS.md`, và tiếp tục với số trong spec.

### 0.2 Vòng lặp bắt buộc

```
Với mỗi PHASE (A → B → C → D → E):
  1. Đọc toàn bộ task của phase đó.
  2. Sửa code.
  3. Chạy:  node verify.mjs --url http://localhost:<port> --only <PHASE>
  4. Nếu còn FAIL → sửa tiếp. KHÔNG sang phase kế tiếp khi phase hiện tại chưa xanh hết.
  5. Chạy full:  node verify.mjs --url http://localhost:<port> --json reports/<PHASE>.json
     → đảm bảo không làm hỏng phase trước (regression).
  6. Commit theo §9.
```

**Tuyệt đối không** gộp cả 5 phase vào một lần sửa rồi mới chạy verify. Phase A thay đổi token toàn cục; nếu bạn đồng thời viết lại layout thì khi verify đỏ bạn sẽ không biết nguyên nhân nằm ở đâu.

### 0.3 Ghi lại mọi chỗ bạn lệch khỏi spec

Tạo `DEVIATIONS.md` ở gốc repo. Mỗi lần bạn **không** làm đúng như spec (vì code thực tế khác dự đoán, vì spec sai, vì có ràng buộc kỹ thuật), ghi một dòng:

```
- [T07] Spec nói .btn dùng min-height:40px, nhưng .btn còn được dùng làm
  inline chip trong .relicstrip nên 40px làm strip cao gấp đôi.
  → Đã tách .btn--chip{min-height:32px} và giữ hit-area 44px qua ::before.
```

File này quan trọng ngang code. Không có nó, người review không biết bản build lệch spec ở đâu.

---

## 1. Tám luật bất biến

Mọi task đều phải tuân thủ. Nếu một task và một luật xung đột, **luật thắng** — và ghi vào `DEVIATIONS.md`.

**L1 — Không có chữ nào dưới 11px.**
Thang chữ chỉ có 6 bậc: `11 / 13 / 15 / 20 / 28 / 44`. Cộng 3 ngoại lệ đã đặt tên: `--die-num: 34px`, `--die-kw: 13px` (đã nằm trong thang), `--intent-v: 20px` (đã nằm trong thang). Bất kỳ `font-size` nào không thuộc tập `{11,13,15,20,24,28,34,44}` là lỗi. (24px dành cho icon, không cho chữ.)

**L2 — 11px chỉ dành cho nhãn ALL-CAPS ngắn (≤ 12 ký tự).**
Câu văn, mô tả, tooltip, nội dung Codex: tối thiểu **15px** (`--t3`). Đây là luật hay bị vi phạm nhất — mỗi khi bạn định đặt `font-size: var(--t1)` cho một thứ có dấu chấm câu, bạn đang sai.

**L3 — Mọi chữ đạt contrast ≥ 4.5:1 so với nền hiệu dụng.**
"Nền hiệu dụng" = màu thật sau khi gộp mọi lớp bán trong suốt phía dưới. Ngoại lệ duy nhất: chữ ≥ 24px hoặc bold ≥ 18.66px được phép 3:1; và element `[disabled]` được phép 3:1 (WCAG 1.4.3 miễn trừ "inactive user interface components"). Không có ngoại lệ nào khác. **Không dùng `opacity` để làm mờ chữ** — nó phá contrast một cách không kiểm soát được; hãy đặt màu trực tiếp.

**L4 — Mọi viền phân định component đạt ≥ 3:1 (WCAG 1.4.11).**
Bậc bề mặt (`--pan` vs `--bg`) chỉ chênh 1.25:1 — nó **không** gánh được việc tách lớp. `--line2` mới là thứ gánh. Đừng bỏ viền vì "trông sạch hơn".

**L5 — Mọi vùng chạm ≥ 44×44px.**
Được phép giữ kích thước hình học nhỏ hơn **nếu** mở rộng vùng chạm bằng `::before` absolute với inset âm. Khi làm vậy, element **bắt buộc** có `position: relative` — nếu không, pseudo sẽ neo vào tổ tiên positioned gần nhất và vùng chạm không tồn tại. `verify.mjs` kiểm tra đúng điều này.

**L6 — Màu mã hoá *trạng thái*, không mã hoá *danh tính*.**
Thanh máu đổi màu theo % HP còn lại, giống nhau cho cả địch và ta. Phe được phân biệt bằng vị trí (hàng trên/dưới) và một dải viền trên. Đây không phải sở thích thẩm mỹ — đó là lý do người chơi biết con nào sắp chết.

**L7 — Không có layout shift do tương tác.**
Hover, chọn, bỏ chọn, xuất hiện badge preview, xuất hiện chip trạng thái: không element nào được dịch chuyển. Đặt trước chỗ trống có kích thước cố định và chỉ đổi `opacity`.

**L8 — Không có glow ngoài 3 chỗ.**
Chỉ: xúc xắc đang chọn, mục tiêu hợp lệ, và độ hiếm Mythic. Đây là luật kế thừa từ design system v0.8 và vẫn đúng.

---

## 2. Pre-flight — dò repo trước khi sửa (bắt buộc)

Đừng đoán cấu trúc file. Chạy đúng các bước sau và ghi kết quả vào `PREFLIGHT.md`:

```bash
# 1. Cây file nguồn
find . -type f \( -name '*.css' -o -name '*.js' -o -name '*.jsx' -o -name '*.ts' -o -name '*.tsx' -o -name '*.html' \) \
  -not -path './node_modules/*' -not -path './dist/*' | sort

# 2. File nào định nghĩa token?
grep -rln -- '--t1\|--die-num\|--faint' --include='*.css' --include='*.js' .

# 3. Đếm chỗ dùng từng token sắp đổi (biết trước khối lượng)
for v in faint t1 t2 t3 t4 t5 t6 die-num die-kw intent-v pan pan2 pan3 line line2 dim; do
  printf '%-12s %s\n' "--$v" "$(grep -ro -- "var(--$v)" --include='*.css' --include='*.js' . | wc -l)"
done

# 4. Chuỗi 'TURN' được render ở đâu?
grep -rn "TURN" --include='*.js' --include='*.jsx' --include='*.ts' --include='*.tsx' . | grep -v node_modules

# 5. Ai set --ui-scale?
grep -rn "ui-scale\|setProperty" --include='*.js' --include='*.ts' . | grep -v node_modules

# 6. Có test / lint sẵn không?
cat package.json

# 7. Dev server chạy ở port nào?
npm run dev   # ghi lại URL, dùng cho verify.mjs
```

**Kỳ vọng dựa trên tài liệu design system v0.8:** `src/style.css` chứa toàn bộ CSS, được sắp xếp theo từng màn hình, với 4 luật ghi ở đầu file. Nếu thực tế khác, ghi vào `PREFLIGHT.md` và điều chỉnh đường dẫn trong các task bên dưới.

**Sau pre-flight, tạo nhánh:**
```bash
git checkout -b feat/uiux-v1
node verify.mjs --url http://localhost:<port> --json reports/baseline.json
```
`reports/baseline.json` là điểm gốc. Nó **phải** có nhiều FAIL — đó là bằng chứng verify.mjs đang thật sự đo bản build của bạn chứ không phải chạy rỗng.

---

## 3. Bảng token đích — nguồn sự thật duy nhất

Dán nguyên khối này vào `:root`, thay thế khối token hiện tại. Mọi comment tỷ lệ đã được tính bằng công thức WCAG 2.1 relative luminance, không phải ước lượng.

```css
:root{
  /* ═══ TYPE — 6 bậc, sàn 11px ═══════════════════════════════════
     L1: font-size chỉ được lấy từ tập {11,13,15,20,24,28,34,44}.
     L2: 11px CHỈ cho nhãn ALL-CAPS ≤12 ký tự. Câu văn tối thiểu 15px. */
  --t1: 11px;   /* nhãn: WAVE, MANA, BACK, HORN */
  --t2: 13px;   /* chữ phụ, chip, giá trị số nhỏ, keyword xúc xắc */
  --t3: 15px;   /* BODY MẶC ĐỊNH — mô tả, tooltip, Codex, passive */
  --t4: 20px;   /* tiêu đề section, nhãn nút lớn, intent địch */
  --t5: 28px;   /* tiêu đề màn hình */
  --t6: 44px;   /* logo */
  --die-num: 34px;   /* số trên mặt xúc xắc — thông tin số 1 trên màn hình */
  --die-kw:  13px;   /* = --t2 */
  --intent-v:20px;   /* = --t4 */
  --float-sz:28px;   /* = --t5, floating combat text */
  --icon-sm: 14px; --icon-md: 24px;
  --font: "JetBrains Mono","IBM Plex Mono",ui-monospace,"Courier New",monospace;

  /* ═══ SPACING — lưới 4px, không có giá trị ngoài thang ═════════ */
  --s1:4px; --s2:8px; --s3:12px; --s4:16px; --s5:24px; --s6:32px; --s7:48px;

  /* ═══ CONTROL — 3 cỡ, không có cỡ thứ 4 ═══════════════════════ */
  --ctl-sm:32px; --ctl-md:40px; --ctl-lg:48px; --tap-min:44px;

  /* ═══ SURFACE ═════════════════════════════════════════════════
     Bậc bề mặt chỉ chênh ~1.25:1 — nó KHÔNG tách lớp được.
     --line2 mới là thứ đạt 1.4.11 và gánh việc phân định component. */
  --bg:    #0b0d10;
  --bg-top:#151a20;
  --pan:   #1e242c;   /* 1.25:1 vs --bg   (cũ #191d23 chỉ 1.13:1) */
  --pan2:  #2a323d;   /* 1.21:1 vs --pan  */
  --pan3:  #39434f;   /* 1.29:1 vs --pan2 */
  --line:  #4a5563;   /* kẻ TRANG TRÍ. KHÔNG dùng làm ranh giới component */
  --line2: #707c8c;   /* VIỀN CARD — 4.59 / 3.68 / 3.05 vs bg / pan / pan2 ✅ */
  --radius:10px; --rad-sm:6px; --bd:2px;

  /* ═══ TEXT — cả 3 bậc đều đạt AA trên cả 3 bậc surface ════════ */
  --txt:#e9edf3;   /* 13.30 / 11.02  trên --pan / --pan2 */
  --dim:#99a3b2;   /*  6.13 /  5.08  — bậc mờ NHẤT được phép cho chữ */
  --off:#7d8794;   /*  4.29 /  3.55  — CHỈ cho [disabled] (miễn trừ 1.4.3) */
  /* --faint ĐÃ BỊ XOÁ. #59616e chỉ đạt 2.71 / 2.40 / 2.04 → không đủ cho chữ. */

  /* ═══ SEMANTIC — giữ nguyên v0.8, đã verify AA trên --pan2 ════ */
  --acc: #ffc857;  /* 8.42 — "bạn có thể hành động ở đây" */
  --heal:#5fd68a;  /* 7.07 */
  --shd: #63b3ff;  /* 5.81 */
  --man: #b388ff;  /* 4.86 */
  --dmg: #ff6b6b;  /* 4.67 */
  --poi: #a8d84a; --burn:#ff9a4d; --deb:#ff8fc7;

  /* ═══ HP — mã hoá % HP, KHÔNG mã hoá phe (L6) ═════════════════ */
  --hp-full:#5fd68a;  /* 100–51% */
  --hp-low: #ffc857;  /*  50–26% */
  --hp-crit:#ff6b6b;  /*  25– 1% */
  --hp-h:8px;
  --hp-ink:#0b0e12;   /* 10.57 / 12.57 / 6.97 trên 3 màu fill trên ✅
                         chỉ cần nếu BUỘC phải đè chữ lên thanh */

  /* ═══ RARITY — không dùng cho bất kỳ mục đích nào khác ════════ */
  --r0:#9aa4b2; --r1:#63b3ff; --r2:#b388ff; --r3:#ffc857; --r4:#ff5f8f;

  /* ═══ LAYOUT ══════════════════════════════════════════════════ */
  --unit-w:158px; --die-w:160px; --die-h:120px;
  --spr-w:100px; --spr-big:164px; --spr-guide:64px;
  --zone-gap:12px;
  --ui-scale:1;   /* set bằng JS — xem T09. KHÔNG set được bằng CSS thuần. */
}
```

---

## 4. Bảng ánh xạ — chạy trước khi sửa từng component

Đây là các phép thay thế toàn cục. Làm chúng **trước** các task component, vì mọi task sau đều giả định chúng đã xong.

| Tìm | Thay bằng | Điều kiện |
|---|---|---|
| `var(--faint)` khi dùng cho `color` | `var(--dim)` | mọi chỗ có chữ |
| `var(--faint)` khi dùng cho `border`/`background` của đường kẻ | `var(--line)` | mọi chỗ trang trí |
| `--faint: #59616e;` trong `:root` | **xoá dòng** | sau khi 2 dòng trên xong |
| `font-size: var(--t1)` trên element chứa câu (có `.` `,` hoặc > 12 ký tự) | `font-size: var(--t3)` | xem L2 |
| `opacity: .28` / `.3` / `.35` trên chữ | xoá, đặt `color: var(--off)` | L3 |
| `.btn.xs` | `.btn.btn--sm` | T07 |
| `#191d23` hardcode | `var(--pan)` | |
| `#212730` hardcode | `var(--pan2)` | |
| `rgb(201, 80, 79)` (fill máu địch) | **xoá rule** | T06 |

> ⚠️ **Đừng đổi tên `--faint` thành `--line`.** `--line` đã tồn tại với giá trị khác; đổi tên sẽ âm thầm chuyển màu mọi đường kẻ đang dùng `--line`. Phải phân loại từng chỗ dùng như bảng trên.

**Kiểm tra sau khi xong §4:**
```bash
grep -rn -- '--faint' --include='*.css' --include='*.js' . | grep -v node_modules   # kỳ vọng: rỗng
grep -rn 'btn xs\|btn\.xs'  --include='*.css' --include='*.js' . | grep -v node_modules  # kỳ vọng: rỗng
```

---

## 5. Task

Ký hiệu: **[verify: A4]** = task này được check `A4` trong `verify.mjs` nghiệm thu. Task không có ký hiệu này cần kiểm thủ công theo §7.

---

## PHASE A — P0: token, contrast, accessibility

> Gate ra khỏi phase: `node verify.mjs --only A` xanh toàn bộ (21 check).

---

### T01 · `TURN undefined` lộ ra production **[verify: A7]**

**Hiện trạng đo được:** trên màn Map (`CHOOSE YOUR PATH`), element `.turn` render nguyên văn chuỗi `TURN undefined` ở 11px màu `#8b95a4`. Ngoài combat, khái niệm "turn" không tồn tại.

**Việc phải làm:**

1. Tìm chỗ render `.turn` (pre-flight bước 4).
2. Guard ở tầng render:
```js
const turnLabel = (screen === 'combat' && turn != null) ? `TURN ${turn}` : '';
```
3. Thêm lưới an toàn ở CSS để lỗi tương tự không lộ ra lần nữa:
```css
.screen:not(.combat) .track .turn{ visibility: hidden; }
```
`visibility` chứ không `display:none` — giữ chiều rộng header ổn định giữa các màn (L7).

**Nghiệm thu:** không có chuỗi `undefined` / `NaN` / `null` / `[object Object]` trong bất kỳ text node nào, trên **mọi** màn hình.

---

### T02 · Thay bảng token type **[verify: A4, A1]**

**Hiện trạng:** `--t1:9px --t2:11px --t3:13px --t4:17px --t5:26px --t6:40px --die-num:30px --die-kw:10px --intent-v:15px`.

Đếm ký tự thực tế trên bản build hiện tại:

| Màn hình | Tổng ký tự | Ở đúng 9px | Ở ≤ 11px |
|---|---|---|---|
| Combat (turn 5, wave 1) | 312 | **219 (70%)** | **260 (83%)** |
| Collection | 799 | **692 (87%)** | **785 (98%)** |

x-height của Courier New ở 9px, đo bằng `canvas.measureText('x').actualBoundingBoxAscent`: **3.81px**. Đó là dưới ngưỡng đọc thoải mái ở khoảng cách ngồi máy tính.

**Việc phải làm:**

1. Dán khối `:root` ở §3.
2. Đặt body dùng `--t3` làm mặc định, để không element nào thừa hưởng 16px của UA:
```css
html, body{ font-size: var(--t3); font-family: var(--font); }
```
3. Rà từng chỗ dùng `--t1` theo bảng §4. Danh sách các selector **chắc chắn** đang vi phạm L2 (đo được trên bản hiện tại):

| Selector | Nội dung | Sửa thành |
|---|---|---|
| `.pd` | mô tả passive, 2–3 dòng văn xuôi | `--t3` |
| `.cxp` | đoạn văn Codex | `--t3` |
| `.nd` | mô tả node trên map | `--t3` |
| `.cxtd` | ô dữ liệu bảng Codex | `--t2` |
| `.hintbar` | câu hướng dẫn | `--t2` |
| `.nothing` | "no active cards yet" | `--t2` |
| `.tlabel` `.ml` `.dp` `.cls` `.pn` | nhãn ALL-CAPS ngắn | `--t1` (giữ) |

**Nghiệm thu:** `A4` xanh (9 token đúng giá trị) và `A1.*` xanh trên cả 4 viewport.

---

### T03 · Xoá `--faint` **[verify: A3, A5]**

**Hiện trạng:** `--faint: #59616e` đang được dùng cho **chữ** ở ít nhất 9 selector. Contrast đo được:

| Nền | Tỷ lệ | Kết quả |
|---|---|---|
| `--pan` `#191d23` | **2.71 : 1** | ❌ |
| `--pan2` `#212730` | **2.40 : 1** | ❌ |
| `--pan3` `#2c333e` | **2.04 : 1** | ❌ |
| `--bg` `#0e1013` | **3.05 : 1** | ❌ |

Bốn cái đều fail ngưỡng 4.5:1.

**Việc phải làm:** thực hiện đúng bảng §4. Selector cần chuyển sang `--dim`: `.tlabel`, `.cls`, `.pn`, `.pd`, `.hintbar`, `.dp`, `.ml`, `.cxtd`, `.nothing`, `.sub`.

**Nghiệm thu:** `grep -rn -- '--faint'` rỗng; không text node nào có `color: rgb(89, 97, 110)`.

---

### T04 · Nâng bậc surface và viền **[verify: A6, A2]**

**Hiện trạng đo được — cả 3 đều fail WCAG 1.4.11 (ngưỡng 3:1):**

| Cặp | Tỷ lệ |
|---|---|
| `--pan #191d23` trên `--bg #0e1013` | **1.13 : 1** |
| `--line #2c333d` trên `--bg` | **1.50 : 1** |
| `--line2 #3f4956` trên `--bg` | **2.09 : 1** |

Nghĩa là game vừa có bậc bề mặt quá nhỏ **vừa** có viền dưới chuẩn — không kênh nào gánh được việc tách lớp. Trên laptop nghiêng hoặc ngoài sáng, card biến mất khỏi nền.

**Việc phải làm:**

1. Áp giá trị surface mới ở §3.
2. Đảm bảo mọi component có viền đạt chuẩn:
```css
.unit, .die, .pick, .nodecard, .bottombar, .track, .cxpane, .modal{
  border: var(--bd) solid var(--line2);
  box-shadow: 0 1px 0 rgba(0,0,0,.55), 0 4px 12px rgba(0,0,0,.35);
}
```
3. `--dim` **phải** lên `#99a3b2`. Giá trị cũ `#8b95a4` chỉ đạt **4.27:1** trên `--pan2` mới — dưới ngưỡng AA. Đây là hệ quả bắt buộc của việc làm sáng surface, không phải tuỳ chọn.

**Nghiệm thu:** `A6` xanh, `A2.*` xanh trên cả 4 viewport.

---

### T05 · Chữ HP không đọc được **[verify: A2]**

**Hiện trạng đo được:**

| Thành phần | Giá trị |
|---|---|
| `.hptxt` | `color:#ffffff`, `font-size:11px`, viền đen 1px 4 hướng |
| `.hpfill` đồng minh | `#5fd68a` |
| `.hpfill` địch | `rgb(201,80,79)` = `#c9504f` |
| `.hpchip` | `rgba(255,255,255,.18)`, **width luôn == width của `.hpfill`** |

Contrast:

| Cặp | Tỷ lệ | Kết quả |
|---|---|---|
| `#fff` trên `#5fd68a` | **1.83 : 1** | ❌ |
| `#fff` trên `#5fd68a` + lớp phủ 18% (`#7cdd9f`) | **1.65 : 1** | ❌ |
| `#fff` trên `#c9504f` | **4.43 : 1** | ❌ |
| `#fff` trên `#d3706f` (có lớp phủ) | **3.34 : 1** | ❌ |

Viền đen 1px không cứu được: ở 11px Courier New nét chữ chỉ dày ~1px, viền chiếm gần hết nét và làm chữ bết lại thay vì rõ hơn.

**`.hpchip` đang vô nghĩa.** Đo trên cả 7 unit: `chipWidth === fillWidth` ở mọi thời điểm (Chomper 117/117, Sprout 107/107, Hatchling 67/67…). Ý đồ ban đầu là hiện đoạn máu *vừa mất* với animation trễ; thực tế nó chỉ là một lớp phủ trắng vĩnh viễn làm nhạt fill và giảm thêm contrast.

**Việc phải làm — phương án chuẩn: bỏ chữ ra khỏi thanh.**

```css
/* Số HP thành dòng riêng phía trên thanh → bài toán contrast biến mất
   hoàn toàn, và miễn nhiễm với mọi màu fill thêm về sau */
.hpnum{
  display:flex; justify-content:space-between;
  font-size:var(--t1); letter-spacing:.5px; color:var(--dim);
  margin-bottom:3px;
}
.hpnum b{ color:var(--txt); }

.hpbar { position:relative; height:var(--hp-h); background:#0a0c0f;
         border-radius:4px; overflow:hidden; }
.hpfill{ height:100%; background:var(--hp-full); transition:width .22s ease-out; }
.hpchip{ display:none; }   /* hoặc sửa đúng: left=newPct, width=oldPct-newPct */
```

Markup: `<div class="hpnum"><span>HP</span><b>15/20</b></div>` đặt **trước** `.hpbar`.

Nếu vì lý do bố cục **bắt buộc** phải đè chữ lên thanh, dùng `color: var(--hp-ink)` (`#0b0e12`) — đã kiểm chứng 10.57 / 12.57 / 6.97 trên ba màu fill. Ghi vào `DEVIATIONS.md`.

**Nghiệm thu:** `A2.combat` xanh. Thanh máu cao 8px thay vì 16px.

---

### T06 · Thanh máu mã hoá phe thay vì mã hoá nguy hiểm **[verify: A9]**

**Hiện trạng:**
```css
.hpbar.low .hpfill { background: var(--dmg); }    /* rule này TỒN TẠI */
.unit.e   .hpfill { background: rgb(201,80,79); } /* nhưng bị override cứng */
```

Hai selector `.unit.e .hpfill` và `.hpbar.low .hpfill` có **specificity bằng nhau** — cùng (0,3,0). Rule của địch thắng đơn giản vì nó nằm **sau** trong file. Và vì không có biến thể `.unit.e .hpbar.low`, quái ở 1/14 HP trông y hệt quái ở 14/14 HP.

**Xác nhận trong phiên chơi thật:** Gooey Slime tụt xuống `1/14` mà thanh máu không đổi màu. Hatchling `9/19` (47%) vẫn xanh lá đầy đủ.

**Tại sao đây là lỗi thiết kế, không chỉ lỗi CSS (L6):** vị trí trên màn hình đã nói rõ ai là địch. Dùng thêm màu để lặp lại thông tin đó là lãng phí kênh màu mà người chơi liếc nhanh nhất — trong khi thông tin *thực sự* cần liếc nhanh là "con nào sắp chết".

**Việc phải làm:**

1. Ở tầng render, gắn class theo % HP:
```js
const pct = hp / maxHp;
const state = pct <= 0.25 ? 'crit' : pct <= 0.50 ? 'low' : '';
// <div class="hpbar {state}">
```
Ngưỡng: `100–51%` → không class · `50–26%` → `.low` · `25–1%` → `.crit`.

2. CSS — 3 rule dưới phải nằm **sau** rule `.unit.e` gốc (specificity bằng nhau, thắng bằng source order):
```css
.unit.e     .hpfill{ background: var(--hp-full); }   /* bỏ override theo phe */
.hpbar.low  .hpfill{ background: var(--hp-low);  }
.hpbar.crit .hpfill{ background: var(--hp-crit); animation: hp-pulse 1.2s infinite; }
@keyframes hp-pulse{ 50%{ opacity:.55 } }
```
Cách sạch hơn: xoá hẳn rule `.unit.e .hpfill` khỏi file thay vì override nó.

3. Phân biệt phe bằng viền, không bằng fill:
```css
.unit.e{ border-top: 3px solid var(--dmg); }
```

4. Tôn trọng reduce-motion:
```css
@media (prefers-reduced-motion: reduce){ .hpbar.crit .hpfill{ animation:none } }
```

**Nghiệm thu:** `A9` xanh. Check này tự đọc `HP x/y` từ DOM, tính %, và đối chiếu với class thực tế trên `.hpbar` — cho cả địch và ta.

---

### T07 · Hệ nút — bỏ hẳn cỡ `xs` **[verify: B1, A2]**

**Hiện trạng đo được:**

| Nút | Kích thước | Font |
|---|---|---|
| `.btn.xs` (`UNDO` `1x` `2x` `3x` `INFO` `SET`) | **42 × 18** | 9px |
| `.btn.sm` | 301 × **27** / 38 × 27 | 11px |
| `.btn` (rail) | 196 × **39** | 11px |
| `.rsel` (đánh dấu reroll) | **22 × 22** | 11px |
| `.seedinp` | 230 × **29** | 11px |
| `.reroll` / `.end` | 98 × **35** | 13px |
| `.go` (`START RUN`) | 152 × **47** | 17px ← nút duy nhất đạt chuẩn |

Chuẩn: WCAG 2.5.5 (AAA) = 44×44 · WCAG 2.5.8 (AA) = 24×24 · Apple HIG 44pt · Material 48dp.
`.btn.xs` ở **18px** fail cả mức AA. `.rsel` 22×22 cũng fail AA (thiếu 2px).

**`UNDO` khi disabled còn tệ hơn:** `opacity: 0.28` trên `#8b95a4`/`#191d23` → màu hiệu dụng `#393f47`, contrast **1.59 : 1**. Người chơi không phân biệt được "nút bị tắt" với "một vệt bẩn trên nền".

**Việc phải làm — 3 cỡ, không có cỡ thứ 4:**

| Cỡ | Chiều cao | Padding ngang | Font | Dùng cho |
|---|---|---|---|---|
| `.btn--sm` | **32px** | 12px | `--t2` | toggle trong header, chip |
| `.btn--md` (mặc định) | **40px** | 16px | `--t2` | nút thường |
| `.btn--lg` | **48px** | 28px | `--t4` | CTA chính: `PLAY` `START RUN` `END TURN` |

```css
.btn{
  box-sizing:border-box;
  --btn-h:var(--ctl-md);              /* biến cục bộ, không thuộc bảng token §3 */
  position:relative;                   /* BẮT BUỘC cho ::before — L5 */
  min-height:var(--btn-h);
  display:inline-flex; align-items:center; justify-content:center;
  padding:0 var(--s4);
  font-size:var(--t2); letter-spacing:.5px;
  border:var(--bd) solid var(--line2); border-radius:var(--radius);
  background:var(--pan2); color:var(--txt);
  cursor:pointer;
}
/* mở rộng vùng chạm mà không đổi kích thước hình học */
.btn::before{
  content:""; position:absolute; inset:50% 50%;
  width:max(100%,var(--tap-min)); height:max(100%,var(--tap-min));
  transform:translate(-50%,-50%);
}
.btn--sm{ --btn-h:var(--ctl-sm); padding:0 var(--s3); }
.btn--lg{ --btn-h:var(--ctl-lg); padding:0 28px; font-size:var(--t4); }

/* disabled: giảm tương phản CÓ KIỂM SOÁT, không dùng opacity mù */
.btn[disabled], .btn.dis{
  background:transparent; border-color:var(--line);
  color:var(--off);        /* 3.55:1 trên --pan2 — đủ nhận ra, đủ hiểu là tắt */
  opacity:1;               /* thay cho opacity:.28 (1.59:1) */
  cursor:not-allowed;
}

/* nút đánh dấu reroll — position:relative BẮT BUỘC, nếu không ::before
   neo vào ancestor positioned gần nhất và vùng chạm 44px không tồn tại */
.rsel{ position:relative; width:28px; height:28px; }
.rsel::before{ content:""; position:absolute; inset:-8px; }   /* → 44×44 */

.seedinp{ box-sizing:border-box; min-height:var(--ctl-md); font-size:var(--t2); }
```

**Ánh xạ nút hiện có:**
`UNDO` `1x` `2x` `3x` `INFO` `SET` → `.btn--sm` · `RANDOM` `CODEX` `SAMPLE TEAMS` `MENU` `REROLL` → `.btn--md` · `PLAY` `START RUN` `END TURN` `CONTINUE RUN` → `.btn--lg`

**`.tnode` (chấm wave 14×14):** kích thước hiển thị 14px là hợp lý, nhưng phải mở rộng hit-area lên 44px bằng cùng kỹ thuật `::before`, **và** thêm `title` — hiện 12 chấm với 3 màu mà không có chú giải nào. Bổ sung legend một lần ở wave 1, hoặc tốt hơn là đổi **hình dạng** thay vì chỉ đổi màu (tròn = thường · vuông xoay 45° = elite · lục giác = boss) để không phụ thuộc màu.

**Nghiệm thu:** `B1.*` xanh trên cả 3 viewport (check này đọc cả `::before` để tính vùng chạm thật).

---

### T08 · Accessibility: focus, semantic, keyboard **[verify: A8a, A8b, A10]**

**Hiện trạng:** không tồn tại rule `:focus-visible` nào trong 547 CSS rule. Game có phím tắt (`I`, `Esc`, `Space`, `Ctrl+Z`) nhưng **không có tab navigation**. Xúc xắc và unit là `div` có `onclick` — không nhận focus, screen reader không đọc được.

**Việc phải làm:**

1. Focus ring:
```css
:where(button,[role=button],a[href],input,select,textarea,[tabindex]:not([tabindex="-1"])):focus-visible{
  outline: 3px solid var(--acc);
  outline-offset: 2px;
  border-radius: var(--rad-sm);
}
.die:focus-visible, .unit:focus-visible{ outline:3px solid var(--acc); outline-offset:3px; }
```

2. Đổi element sang semantic đúng — **không** dùng `div` + `onclick`:

| Hiện tại | Đổi thành |
|---|---|
| `<div class="die" onclick>` | `<button type="button" class="die" role="option" aria-selected aria-label="Xúc xắc 1, BACK, Shield 5, chưa dùng">` |
| `<div class="unit" onclick>` | `<button type="button" class="unit" aria-label="Sprout, máu 15 trên 20, khiên 7">` |
| `<div class="hpbar">` | thêm `role="progressbar" aria-valuenow aria-valuemin="0" aria-valuemax` |
| `<div class="pick" onclick>` | `<button type="button" class="pick" aria-pressed>` |
| `.tray` | thêm `role="listbox" aria-label="Xúc xắc của bạn"` |

> Khi đổi sang `<button>`, nhớ `box-sizing:border-box`, reset `font-family:inherit`, `text-align:inherit`, và bỏ `background:ButtonFace` mặc định. `REFERENCE.html` có bản mẫu.

3. Thứ tự tab: header → enemies → party → dice tray → bottom bar.

4. Bind phím cho thao tác chính (badge chữ cái ở góc card đã có sẵn — chỉ cần nối dây):
   `1`–`5` chọn xúc xắc · `Q W E R T` chọn mục tiêu · `Esc` hủy · `Space` end turn.

5. Reduce motion — phủ toàn bộ, không chỉ từng animation:
```css
@media (prefers-reduced-motion: reduce){
  *, *::before, *::after{ animation-duration:.001ms !important;
    animation-iteration-count:1 !important; transition-duration:.001ms !important; }
}
```

**Nghiệm thu:** `A8a` (mọi element tương tác focus được, trừ `[disabled]`), `A8b` (outline ≥ 2px, không phải UA default), `A10` (reduce-motion tắt hết animation).

---

## PHASE B — P0: responsive

> Gate: `node verify.mjs --only B` xanh (9 check).
> `verify.mjs` chạy viewport thật **393×852** và **744×1133** trong Playwright — mobile được **kiểm tra thật**, không suy luận.

---

### T09 · `--ui-scale` chỉ biết thu nhỏ **[verify: B3]**

**Hiện trạng:** chiến lược responsive duy nhất là `#app { max-width:1240px; zoom: var(--ui-scale) }`. `--ui-scale` không bao giờ vượt 1, nên trên màn cao nội dung combat chỉ chiếm ~540px trong 839px khả dụng — **299px, ~36% chiều dọc bỏ trống** (đo ở viewport CSS 1440×839) trong khi số xúc xắc vẫn 30px.

> ⚠️ **Không dùng `clamp()` thuần CSS cho việc này.**
> `clamp(0.85, min(100vw/880, 100vh/720), 1.30)` là **CSS không hợp lệ**: `100vw / 880` cho ra một *length*, còn hai cận của `clamp()` là *number*. Trộn kiểu → cả khai báo bị bỏ qua, và `zoom:` cần số không đơn vị. Game đã set `--ui-scale` bằng JS rồi, giữ ở JS.

```js
function fitUI(){
  const BOARD_W = 880;   // 846px nội dung + 34px headroom
  const BOARD_H = 720;   // header 44 + enemies 214 + party 238 + tray 136 + bar 64 + gaps
  const raw = Math.min(innerWidth / BOARD_W, innerHeight / BOARD_H);
  // Trên ≤1199px, breakpoint (T10) đã lo việc co — khoá về 1 để 2 cơ chế
  // KHÔNG nhân chồng lên nhau (unit 158 × 1.20 = 190px, board 846 → 1015px)
  const s = innerWidth >= 1200 ? Math.min(raw, 1.20) : 1;
  document.documentElement.style.setProperty('--ui-scale', Math.max(0.85, s).toFixed(3));
}
addEventListener('resize', fitUI, { passive:true });
fitUI();
```

**Kiểm chứng trên máy đã đo thật (1440×839):** `min(1440/880, 839/720) = min(1.636, 1.165) = 1.165`.
`--die-num` 34 × 1.165 = **39.6px**; `--t1` 11 × 1.165 = **12.8px**. Khoảng trống dọc 299px → còn khoảng 90px.

**Nghiệm thu:** `B3.desktop-1440` trong `[0.85, 1.20]`; `B3.tablet` và `B3.phone` **= 1** đúng bằng 1.

---

### T10 · Thêm breakpoint thật **[verify: B0, B2]**

**Hiện trạng đo được:**

- Tổng CSS rule: **547**
- Tổng `@media`: **1** — và đó là `(prefers-reduced-motion: reduce)`
- **Không có một media query nào theo `min-width`/`max-width`**
- `<meta name="viewport" content="width=device-width,…">` có khai báo mobile nhưng không có CSS đi kèm

Chiều rộng tối thiểu của bàn chơi (tính từ token đã đo):
```
5 unit × 158px       = 790px
4 khoảng cách × 8px  =  32px
padding #app 2 × 12  =  24px
──────────────────────────────
TỔNG                 = 846px
```

Hệ quả nếu chỉ dựa vào `zoom` (phép tính, chưa xác nhận trên thiết bị):

| Thiết bị | Viewport | `--ui-scale` bắt buộc | `--die-num` 30px thành | `--t1` 9px thành |
|---|---|---|---|---|
| iPhone 15 Pro | 393px | **0.46** | 13.9px | **4.1px** |
| iPhone SE | 375px | **0.44** | 13.3px | **4.0px** |
| iPad mini | 744px | 0.88 | 26.4px | 7.9px |
| MacBook Air 13" | 1280px | 1.00 | 30px | 9px |

Ở scale 0.46, nhãn `BACK`/`HORN` sẽ render ở **4.1px** — đây không còn là "chữ nhỏ", đây là không tồn tại.

**Việc phải làm — thay đổi *kích thước component*, không zoom cả trang:**

```css
/* ≥1200px — desktop, mặc định (đã nằm trong :root §3) */

/* 900–1199px — laptop hẹp / tablet landscape */
@media (max-width:1199px){
  :root{ --unit-w:140px; --die-w:140px; --die-h:112px; --zone-gap:10px; --ui-scale:1; }
}

/* 600–899px — tablet portrait
   Kiểm tra ở CẬN DƯỚI 600px: 5×104 + 4×8 + 2×8 = 568px ≤ 600 ✅
   (dùng 112px sẽ ra 616px và tràn ngay tại 600px) */
@media (max-width:899px){
  :root{ --unit-w:104px; --die-w:104px; --die-h:100px; --zone-gap:8px;
         --die-num:26px; --spr-w:76px; --ui-scale:1; }
  #app{ padding:var(--s2) var(--s2) var(--s3); }
  .dp{ display:none; }              /* bỏ nhãn chữ, giữ icon */
  .track{ flex-wrap:wrap; row-gap:var(--s2); }
}

/* <600px — phone
   Kiểm tra ở 393px: 16 + 5×64 + 4×6 = 360px ≤ 393 ✅ (dư 33px) */
@media (max-width:599px){
  :root{ --unit-w:64px; --die-w:64px; --die-h:88px; --zone-gap:6px;
         --die-num:24px; --spr-w:56px; --hp-h:6px; --ui-scale:1; }
  #app{ padding:var(--s2) var(--s2) var(--s3); }
  .nm, .dp, .pips{ display:none; }
  .die{ padding:6px 4px; }
  .bottombar{ position:sticky; bottom:0; height:60px; }
  .btn--lg{ --btn-h:52px; }         /* ngón tay cần nhiều hơn con trỏ */
}
```

> `--die-num: 26px` và `24px` ở 2 breakpoint dưới **nằm ngoài** thang chữ L1 — đó là chủ ý, vì đây là số hiển thị chứ không phải chữ đọc. `verify.mjs` cho phép chúng qua vì kiểm tra chỉ áp cho text node. Nếu check `A1` báo đỏ vì 2 giá trị này, thêm chúng vào `ALLOWED_FONT_SIZES` và ghi `DEVIATIONS.md`.

**Nghiệm thu:** `B0` (≥ 3 width query), `B2.tablet` và `B2.phone` (không tràn ngang), `A1`/`A2`/`B1` xanh trên cả tablet và phone.

---

### T11 · Cổng chặn phone portrait

Bàn chơi 5 cột về bản chất là bố cục ngang. Ép nó vào 393px chiều rộng luôn cho ra thoả hiệp tệ. Giải pháp rẻ và trung thực hơn:

```css
.rotate-hint{ display:none; }
@media (max-width:599px) and (orientation:portrait){
  .rotate-hint{
    display:flex; position:fixed; inset:0; z-index:100;
    flex-direction:column; align-items:center; justify-content:center; gap:var(--s4);
    background:var(--bg); color:var(--txt); font-size:var(--t3); text-align:center;
    padding:var(--s5);
  }
  .screen.combat{ display:none; }
}
```
Markup: `<div class="rotate-hint">Xoay ngang máy để chơi<span aria-hidden="true">⟳</span></div>`

`verify.mjs` phát hiện `.rotate-hint`; nếu có, nó tự chuyển sang landscape 852×393 rồi mới chấm các check còn lại.

---

## PHASE C — P1: UX cốt lõi

> Gate: `node verify.mjs --only C` xanh + kiểm thủ công §7.

---

### T12 · Layout shift khi chọn xúc xắc **[verify: C2]**

**Hiện trạng đo được:** khi chọn xúc xắc khiên/hồi máu, badge preview (`SH +7`, `+3`, `+0`) xuất hiện **phía trên** mỗi card đồng minh và đẩy cả hàng party dịch lên. `.zone.party` chuyển từ `y=386` sang `y=371` — **dịch 15px**. Bỏ chọn thì nhảy ngược lại.

Người chơi đang nhắm chuột vào một card thì card đó di chuyển ra khỏi con trỏ. Đây là lỗi Fitts's Law và gây misclick thật.

**Việc phải làm:** đặt trước chỗ trống cố định, badge chỉ đổi `opacity`:

```css
.unit{ position:relative; margin-top:24px; }   /* chỗ trống cố định */
.preview-badge{
  position:absolute; top:-24px; left:50%; transform:translateX(-50%);
  height:20px; padding:0 var(--s2); border-radius:var(--rad-sm);
  font-size:var(--t2); line-height:20px; white-space:nowrap;
  opacity:0; transition:opacity .12s; pointer-events:none;
}
.unit.previewing .preview-badge{ opacity:1; }
```

Áp **cùng nguyên tắc** cho chip trạng thái (`Poison 2`) dưới thanh máu — hiện nó làm card địch cao thêm ~20px khi trạng thái xuất hiện. Đặt sẵn một hàng chip cao 20px luôn tồn tại, rỗng khi không có trạng thái:
```css
.statusrow{ min-height:20px; display:flex; gap:var(--s1); justify-content:center; }
```

**Nghiệm thu:** `C2` — check này snapshot toạ độ mọi `.unit`/`.die`/`.zone`, click một xúc xắc, đợi 350ms, `Esc`, đợi 350ms, và yêu cầu **0** element dịch chuyển ở cả hai bước.

---

### T13 · Giải phẫu xúc xắc không thống nhất **[verify: C1]**

**Hiện trạng đo được:** `.die` = **158 × 104px**, cấu trúc `.dp` (nhãn 9px `--faint`) · `.di` (icon 22×22) · `.dv` (giá trị 30px) · `.pips` (6 ô 9×9).

Nhưng mặt có **từ khoá** (`Weaken 2`, `Cantrip`) render `.dv` **rỗng** và thay bằng chữ 10px. Kết quả: 4 ô có số 30px, 1 ô có chữ 10px — nhịp thị giác của cả hàng bị gãy, và mặt quan trọng nhất lại khó đọc nhất.

**Việc phải làm — một giải phẫu duy nhất, chiều cao cố định cho mọi loại mặt:**

```
┌──────── 160px ────────┐
│  BACK           11px  │  --dim, ls 1.5px
│        ◆ 24px         │  icon
│         34            │  --die-num, màu semantic
│      Weaken 2   13px  │  dòng keyword — LUÔN tồn tại (rỗng nếu không có)
│ ▪ ▪ ▪ ▫ ▪ ▪    10px   │  pips, gap 4
└───────────────────────┘   cao 120px
```

```css
.die{
  box-sizing:border-box;                 /* BẮT BUỘC: có cả height lẫn padding */
  position:relative;                     /* neo cho .rsel */
  width:var(--die-w); height:var(--die-h);
  padding:10px var(--s2) var(--s2);
  display:grid;
  grid-template-rows:14px 24px 1fr 16px 14px;   /* dp · di · dv · dkw · pips */
  align-items:center; justify-items:center;
  background:var(--pan2); border:var(--bd) solid transparent;
  border-radius:var(--radius);
}
.dp { font-size:var(--t1); letter-spacing:1.5px; color:var(--dim); }
.di { width:var(--icon-md); height:var(--icon-md); }
.dv { font-size:var(--die-num); line-height:1; }
.dkw{ font-size:var(--die-kw); color:var(--dim); min-height:16px; }  /* LUÔN render */
.pips{ display:flex; gap:var(--s1); }
.pip { width:10px; height:10px; border-radius:2px; background:var(--pan3); }
.pip.on{ background:var(--acc); }
```

Mặt có keyword vẫn giữ số lớn (giá trị của keyword, ví dụ `Weaken **2**`); keyword là dòng phụ 13px bên dưới.

**Xúc xắc đã dùng:** hiện chỉ giảm opacity xuống ~0.3 nhưng vẫn chiếm nguyên 158px. Giữ nguyên vị trí (để không nhảy layout — L7) nhưng thêm dấu ✓ 20px màu `--dim` ở giữa và `filter: grayscale(1)`. Người chơi phân biệt được "đã dùng" với "không hợp lệ".

**Pips cần chú giải:** 6 ô vuông nhỏ không tự giải thích. Thêm `title="Mặt 4 trên 6"` và, ở wave 1, một dòng hint: *"6 ô = 6 mặt của xúc xắc · ô vàng là mặt đang hiện"*.

**Nghiệm thu:** `C1` — cả 5 ô cùng width và cùng height, kể cả khi có mặt keyword trong tray.

---

### T14 · Mục tiêu "hợp lệ nhưng vô ích" vẫn sáng vàng

**Hiện trạng:** chọn xúc xắc hồi máu, cả 5 đồng minh đều viền vàng "hợp lệ". Fry đang `16/16` HP hiển thị badge **`+0`** — vẫn viền vàng đầy đủ, click vẫn tiêu xúc xắc.

Vàng trong design system có nghĩa "bạn có thể hành động ở đây". Nhưng "có thể" ≠ "nên". Người chơi mới sẽ đốt một lượt heal vào con full máu và không hiểu tại sao không có gì xảy ra.

**Việc phải làm — thêm bậc thứ 3:**

| Trạng thái | Viền | Card | Badge |
|---|---|---|---|
| Hợp lệ & hiệu quả | `2px solid var(--acc)` + glow | không đổi | màu semantic, `opacity 1` |
| Hợp lệ nhưng `value = 0` | `2px dashed var(--line)` | `opacity .55` | `+0` màu `--dim` |
| Không hợp lệ | `2px solid transparent` | `opacity .35` | không có |

```css
.unit.legal      { border-color:var(--acc); box-shadow:0 0 0 3px rgba(255,200,87,.22); }
.unit.legal.noop { border-style:dashed; border-color:var(--line);
                   box-shadow:none; opacity:.55; }
.unit.illegal    { opacity:.35; pointer-events:none; }
```

> Lưu ý L3: `opacity` trên card **kéo theo** chữ bên trong. Sau khi làm task này, chạy lại `A2` — nếu đỏ, giảm opacity trên nền/viền riêng thay vì trên cả card.

Kèm confirm nhẹ: nếu người chơi vẫn click mục tiêu `noop`, hiện toast 2s *"Fry đang đầy máu — xúc xắc này sẽ không có tác dụng. Click lần nữa để xác nhận."*

---

### T15 · Không có combat log

**Hiện trạng:** sau `END TURN`, địch hành động, máu thay đổi, floating text bay lên rồi biến mất trong ~0.6s. Không có bất kỳ lịch sử nào. Ở tốc độ `3x` gần như không đọc kịp.

Roguelike deckbuilder sống bằng việc người chơi hiểu **tại sao** mình mất 8 máu. Không có log, người chơi thua mà không học được gì — đây là nguyên nhân churn số 1 của thể loại.

**Việc phải làm — panel gấp gọn cạnh phải:**

- Chiều rộng khi mở **280px**, cao = chiều cao vùng board, `position:absolute; right:0`
- Mỗi dòng: `font-size:var(--t2)`, `line-height:20px`, `padding:6px 10px`, phân cách `1px solid var(--line)`
- Giữ **40 sự kiện** gần nhất, cuộn ngược, mới nhất trên cùng
- Format: `[T4] Chomper → Sprout · 8 dmg (5 chặn bởi Shield)`
- Icon 14px màu semantic đứng đầu mỗi dòng
- Nút toggle `LOG` `.btn--sm` trong header, mặc định **đóng**, nhớ trạng thái qua `localStorage`
- `role="log" aria-live="polite"` để screen reader đọc được

**Phương án rẻ hơn nếu không làm panel:** tăng thời gian sống của floating text lên **1.4s** ở tốc độ 1x, và **không** rút ngắn theo `speed` — tốc độ chỉ nên rút ngắn animation di chuyển, không rút ngắn thời gian đọc số.

---

### T16 · Header combat: icon không nhãn

**Hiện trạng:** `.trk-right` nhồi `TURN 1` · 🌙`2/2` · 💎`0` · `UNDO` · `1x 2x 3x` · `INFO` · `SET` vào một dải **415 × 18px**.

- Icon mặt trăng + `2/2` = số reroll còn lại — **không có nhãn nào nói vậy**
- Icon kim cương + `0` = Gene Shard — cũng không nhãn
- `1x 2x 3x` không có nhãn "tốc độ"

**Việc phải làm:**

- Mỗi cụm số thành một chip cao 32px: icon 14px + nhãn `--t1` `--dim` + giá trị `--t2` màu semantic. Ví dụ `🌙 REROLL 2/2`.
- `title` cho mọi icon.
- Nhóm `1x/2x/3x` bọc trong segmented control có nhãn `SPEED` `--t1` bên trái.
- Chiều cao `.track`: **34px → 44px** (chứa control 32px + padding 6px).

---

### T17 · `ABANDON RUN` trông giống hệt `SAVE & QUIT`

**Hiện trạng:** trong Settings, hai nút cạnh nhau, cùng `background: var(--pan2)`, cùng `border: 2px solid var(--line2)`, cùng cỡ chữ, cùng chiều cao. Một nút lưu tiến độ, nút kia **xoá vĩnh viễn** một run 15–35 phút.

**Việc phải làm:**

```css
.btn--danger{ border-color:var(--dmg); color:var(--dmg); background:transparent; }
.btn--danger:hover{ background:rgba(255,107,107,.12); }
```

- Đẩy `ABANDON RUN` xuống hàng riêng, cách `SAVE & QUIT` **24px**, có `1px solid var(--line)` ngăn giữa.
- Modal xác nhận bắt buộc: *"Bỏ run này? Bạn đang ở wave 3/12. Gene Shard và Lunacia XP đã kiếm được vẫn giữ."* Nút **hủy** là mặc định và được focus; nút xác nhận là `.btn--danger`.

**Thiếu trong Settings — bổ sung:**

- `Reduce motion` toggle (CSS đã hỗ trợ `prefers-reduced-motion` — cho bật thủ công)
- `UI scale` slider **85%–120%**, step 5% — ghi đè `--ui-scale`
- `Colorblind mode`: thêm ký hiệu hình cho damage/shield/heal (▲ ◆ ✚) thay vì chỉ dựa vào màu
- `SOUND ON` đang xuống 2 dòng vì nút hẹp (96px) → `min-width:120px`
- Slider volume dài **580px**, thừa → `max-width:320px`, số % bên phải cách 12px

---

### T18 · Menu giấu toàn bộ điều hướng phụ sau 2 tab xoay dọc

**Hiện trạng:** màn MENU chỉ có `PLAY` (và `CONTINUE RUN` nếu có save). Ba mục `LUNACIA PASS`, `UNLOCKS`, `COLLECTION` nằm sau tab trái nhãn `PROGRESS`; một nhóm nữa sau tab phải nhãn `LEARN`. Hai tab `.railtab` kích thước **33 × 141px**, chữ xoay 90°, dán vào mép trái/phải viewport. Ở 1440px chúng cách nhau **~1400px**.

Tại sao sai:
1. Chữ xoay dọc ở mép màn hình đọc chậm hơn ~2× chữ ngang.
2. Người chơi mới không có lý do rê chuột ra mép màn hình — vùng đó theo quy ước là của scrollbar và browser chrome.
3. Trên touch không có hover; `.rail:hover .railbody` không kích hoạt, phải tap trúng dải 33px.
4. Toàn bộ cụm nội dung menu nằm gọn trong hộp **~429 × 166px**. Trên viewport 1440×839 đó là **~6% diện tích**; 94% còn lại hoàn toàn trống.

**Việc phải làm:**

```
┌──────────────────── viewport ───────────────────┐
│              AXIE DICE TACTICS      44px --t6   │
│           LUNACIA MUTANTS · v1.0    13px --dim  │
│                    ↕ 32px                       │
│         ┌────────────────────────┐              │
│         │      CONTINUE RUN      │  320×56 acc  │
│         └────────────────────────┘              │
│                    ↕ 8px                        │
│         ┌────────────────────────┐              │
│         │        NEW RUN         │  320×48 ghost│
│         └────────────────────────┘              │
│                    ↕ 24px                       │
│   ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐  │
│   │  PASS  │ │COLLECT.│ │UNLOCKS │ │ CODEX  │  │ 4 × 152×72, gap 8
│   │  Lv 13 │ │ 17/55  │ │   —    │ │   —    │  │
│   └────────┘ └────────┘ └────────┘ └────────┘  │
│                    ↕ 24px                       │
│    16 runs · 1 win · best wave 20 · 1970 Shard  │ 13px --dim
└─────────────────────────────────────────────────┘
```

```css
.menu{ min-height:100dvh; display:grid; place-items:center; }
.menu-inner{ width:min(640px, 100% - 32px); display:flex; flex-direction:column; align-items:center; }
.menu .logo{ font-size:var(--t6); letter-spacing:8px; color:var(--acc); }
.menu .sub { font-size:var(--t2); letter-spacing:3px; color:var(--dim); margin-top:var(--s2); }
.menu .cta { width:320px; min-height:56px; margin-top:var(--s6); font-size:var(--t4); }
.menu .cta2{ width:320px; min-height:var(--ctl-lg); margin-top:var(--s2); }
.menu-grid { display:grid; grid-template-columns:repeat(4,152px); gap:var(--s2); margin-top:var(--s5); }
.menu-grid .btn{ min-height:72px; flex-direction:column; gap:var(--s1); }
.menu-grid .btn small{ font-size:var(--t1); color:var(--acc); }
.menu .stats{ margin-top:var(--s5); font-size:var(--t2); color:var(--dim); }
@media (max-width:599px){
  .menu-grid{ grid-template-columns:repeat(2,1fr); width:100%; }
  .menu .cta, .menu .cta2{ width:100%; }
}
```

- **Xoá hoàn toàn** `.rail`, `.railtab`, `.railbody`, `.railbadge`. Tiết kiệm ~40 dòng CSS và loại bỏ một pattern không hoạt động trên touch.
- Nút phụ hiển thị số tiến độ ngay trên nút khi có (`Lv 13` cho Pass, `17/55` mặt xúc xắc cho Collection).
- **Cả `17/55` (faces) lẫn `12/44` (relics) đều thuộc Collection** — đừng gán `12/44` cho Unlocks.

---

### T19 · Card Team Select — hierarchy đảo ngược

**Hiện trạng đo được (`.pick` = 196 × 246px):**

| Phần tử | Cỡ | Màu | Cao |
|---|---|---|---|
| `.spr` sprite | 100×100 | — | 100px (**41% chiều cao card**) |
| `.nm` tên | 13px | `#e9edf3` | 15px |
| `.cls` (`PLANT · HP 17`) | 9px | `#59616e` | 10px |
| `.pn` (`BULWARK`) | 9px | `#ffc857` | 10px |
| `.pd` mô tả passive 2–3 dòng | 9px, lh 13.5 | `#8b95a4` | 41px (17%) |
| `.minidie` 6 mặt, ô `.mf` 25×16 | 9px | `#8b95a4` | 16px |

Sprite chiếm 41% chiều cao nhưng mang **0 thông tin quyết định** — 6 con Axie đều là cục tròn dễ thương, nhìn sprite không suy ra được build. `.pd` — thứ duy nhất người chơi thực sự cần đọc để chọn team — chiếm 17% và ở cỡ chữ nhỏ nhất.

**Việc phải làm — card 220 × 300:**

```
┌──────────── 220px ─────────────┐
│ ┌──────┐  Sprout          20px │  sprite thu còn 72×72, đặt bên trái
│ │ 72px │  PLANT · HP 17   11px │
│ └──────┘                       │
│ ━━━━━━━━━━━━━━ 3px class color │
│ BULWARK                  11px  │  --acc
│ Every Shield you create is     │  15px (từ 9px)
│ increased by 2. An Axie with   │  lh 22px, --dim
│ 10+ Shield gains Thorns 2.     │
│ ┌────┬────┬────┬────┬────┬────┐│  6 ô ~30×32 (grid 1fr), gap 2
│ │◆ 4│◆ 3│✚ 2│◆ 2│✚ 3│⚡1│    │  icon 14px + số 13px
│ └────┴────┴────┴────┴────┴────┘│
└────────────────────────────────┘
```

```css
.pick{
  box-sizing:border-box; width:220px; min-height:300px;
  padding:14px 14px var(--s3);
  display:flex; flex-direction:column;
  border:var(--bd) solid var(--line2); border-radius:var(--radius);
  background:var(--pan);
}
.pick-head{ display:flex; align-items:center; gap:var(--s3); }
.pick .spr{ width:72px; height:72px; flex:none; }
.pick .nm { font-size:var(--t4); color:var(--txt); }
.pick .cls{ font-size:var(--t1); color:var(--dim); letter-spacing:1px; }
.pick-rule{ height:3px; background:var(--class-color); margin:var(--s3) 0; border-radius:2px; }
/* --class-color KHÔNG nằm trong :root — set inline theo card:
   <button class="pick" style="--class-color:#5fd68a"> cho PLANT, v.v. */
.pick .pn { font-size:var(--t1); color:var(--acc); letter-spacing:1px; margin-bottom:6px; }
.pick .pd { font-size:var(--t3); line-height:22px; color:var(--dim); flex:1; }
.minidie{ display:grid; grid-template-columns:repeat(6,1fr); gap:2px; margin-top:var(--s3); }
.mf{ height:32px; display:flex; align-items:center; justify-content:center; gap:3px;
     background:var(--pan2); border-radius:var(--rad-sm); font-size:var(--t2); }
.mf .icow{ width:var(--icon-sm); height:var(--icon-sm); }
```

**Số đếm `5/5` (`.tcount`):** hiện là chữ 11px `--dim` cách nút `RANDOM` 10px về bên trái, không nhãn. Đổi thành chip cao 32px `ĐÃ CHỌN 5/5`, màu `--acc` khi đủ 5 và `--dim` khi chưa, đặt **ngay bên trái `START RUN`** — nơi mắt đang nhìn khi chuẩn bị bấm.

**`START RUN` phải `disabled` khi chưa đủ 5 Axie.** Audit chưa kiểm chứng được hành vi hiện tại — kiểm tra, nếu chưa có thì thêm.

---

## PHASE D — P2: đánh bóng & nhất quán

> Gate: `node verify.mjs --only D` xanh + đọc lại §7.

---

### T20 · Codex — dòng quá dài **[verify: D1]**

**Hiện trạng đo được:** `.cxp` (đoạn văn Codex) rộng **602px** (lấy trực tiếp bằng `getBoundingClientRect`), `font-size: 11px` Courier New.

Advance width của Courier New, đo bằng `canvas.measureText` trên chính bản build: **6.601 px/ký tự @11px**, **9.001 px/ký tự @15px**.

```
602 / 6.601 = 91,2 ký tự/dòng   ← hiện tại
602 / 9.001 = 66,9 ký tự/dòng   ← sau khi lên 15px
```

Ngưỡng dễ đọc cho văn bản dài là **45–75 ký tự**. 91 là quá dài — mắt mất dấu khi xuống dòng. **Chỉ cần tăng cỡ chữ lên 15px là rơi đúng 67 ký tự, không phải đụng đến chiều rộng pane.** Một thay đổi sửa hai vấn đề.

```css
.cxp  { font-size:var(--t3); line-height:24px; color:var(--dim); }   /* 11 → 15px */
.cxtd { font-size:var(--t2); color:var(--dim); }   /* từ 9px/--faint (2.04:1) */
.cxtab{ min-height:var(--ctl-md); font-size:var(--t2); }  /* từ 31px cao / 11px */
```

Bổ sung **ô tìm kiếm** ở đầu rail trái (`min-height:36px`), lọc theo tên keyword/relic. Codex có 9 section — tìm một keyword cụ thể hiện phải đọc thủ công.

---

### T21 · Collection — 3 kiểu căn lề trên cùng một màn

**Hiện trạng:** tiêu đề `COLLECTION` và dòng `Faces 17/55 · Relics 12/44` **căn giữa**; heading `RELIC (12/44)` và `DIE FACES (17/55)` **căn trái sát mép x=12**; heading `BOSSES DEFEATED (5/6)` lại **căn giữa**; nút `BACK` **rộng 838px** trải hết viewport.

Đếm ký tự: **785/799 (98%)** ở ≤11px, trong đó **692 (87%)** ở đúng 9px. Đây là màn tệ nhất về mặt readability trong toàn game.

**Việc phải làm:**

- Bọc toàn bộ trong `.container{ width:min(1080px, 100% - 48px); margin-inline:auto; }`
- Mọi heading section: căn trái, `font-size:var(--t4)`, `margin:var(--s6) 0 var(--s3)`
- Nút `BACK`: `width:160px`, đặt trên cùng bên trái dạng `‹ BACK` — không phải thanh full-width ở đáy
- **Hiện cả mục chưa mở khoá** dạng chip mờ có ổ khoá. Hiện tại 38/55 mặt xúc xắc chưa mở đơn giản là *không tồn tại* trên màn hình — người chơi không thấy mình đang thiếu gì nên mất động lực sưu tầm. Chip khoá: `opacity:.4`, `border-style:dashed`, nội dung `? ? ?`, `aria-label="Chưa mở khoá"`.

---

### T22 · Info panel — bảng bỏ trống ~3/4 chiều rộng

**Hiện trạng:** modal rộng ~850px, hàng bảng trải từ x≈355 đến x≈1145 (**790px**). Nội dung thật chỉ nằm trong x≈365 → 570: index · icon · part · value · keyword — tức **~205px được dùng, ~585px (74%) bỏ trống**. Row height ~23px với chữ 9–11px.

**Việc phải làm:**

```css
.dietable{ display:grid; grid-template-columns:28px 24px 92px 56px 1fr; max-width:560px; }
.dietable > *{ min-height:32px; display:flex; align-items:center; font-size:var(--t2); }
```

Hoặc tốt hơn: dùng phần trống để hiển thị **2 Axie cạnh nhau** (2 cột × 420px) — người chơi so sánh build nhanh hơn nhiều so với cuộn dọc qua 5 bảng.

Nút `CLOSE` 11px ở góc phải → `.btn--sm` cao 32px. Thêm click-outside-to-close (`Esc` đã có).

---

### T23 · Unit chết vẫn chiếm chỗ và làm lệch hàng

**Hiện trạng:** Gooey Slime chết (`0/14`) — card chuyển xám nhưng vẫn giữ nguyên 158px trong hàng, và card của Chomper còn sống trở nên **cao hơn** card đã chết (vì card chết mất hàng intent). Hàng địch không căn giữa lại.

**Việc phải làm:**

- **Địch:** giữ chỗ 400ms cho animation chết chạy, sau đó `width:0; margin:0; opacity:0` với `transition:all .35s` → hàng tự căn giữa lại mượt. Dọn màn hình.
- **Đồng minh:** giữ chỗ vĩnh viễn, khoá `min-height` cố định để hàng không so le, hiển thị bia mộ (sprite `filter:grayscale(1) opacity(.4)` + chữ `DOWN` `--t2`). Người chơi cần biết ai đã ngã và có thể hồi sinh.

---

### T24 · Map — "CHOOSE YOUR PATH" nhưng chỉ có một lựa chọn

**Hiện trạng:** wave 1 hiển thị tiêu đề `CHOOSE YOUR PATH` với đúng **1 node**. Codex nói rõ mỗi wave chọn `one of two nodes`. Ở wave 1 dường như bị ép còn 1.

**Việc phải làm:** nếu chỉ có 1 node, đổi tiêu đề thành `NEXT · WAVE 1` và bỏ chữ "choose". Đừng bảo người chơi chọn khi họ không có gì để chọn — nó làm giảm độ tin cậy của mọi prompt về sau.

Chuẩn hoá `.nodecard`: **280 × 160px**, dải màu trên 4px theo loại node, icon 32px, tiêu đề `--t4`, mô tả `--t2`, meta `--t2` màu `--acc`.

---

### T25 · Bottom bar — hierarchy phẳng

**Hiện trạng:** `.bottombar` cao 55px chứa `MANA 0` (pill 77×35) · `no active cards yet` (9px `--faint`, 3.05:1) · `REROLL 2` (98×35) · `END TURN` (98×35). Hai nút cuối cùng cỡ, cùng nền `--pan2`, chỉ khác màu chữ.

**Việc phải làm:**

- `END TURN` là hành động chính → `.btn--lg`, **140 × 48px**, nền đặc `var(--acc)`, chữ `#1a1503`
- `REROLL` là phụ → `.btn--md`, **120 × 40px**, ghost viền `var(--shd)`
- Hiển thị **phím tắt trên nút**: `END TURN ␣`, `REROLL R` — `--t1` `--dim` ở góc phải nút
- `MANA`: pill cao **40px**, nhãn `--t1` + giá trị `--t4` màu `--man`
- `no active cards yet` → `--t2` `--dim`; khi có relic/card thì hiện chip cao 28px
- Chiều cao bar: 55px → **64px**

---

### T26 · Hint bar

**Hiện trạng:** 9px, `--faint`, 3.05:1, đặt cách bottom bar 8px. Design system v0.8 nói hint bar "nghỉ hưu sau wave 1" — nhưng nó **vẫn hiển thị ở turn 5 wave 1**, nghĩa là logic tính theo wave chứ không theo lần hiển thị. Ở wave 1 người chơi đã đọc nó 5 lần.

**Việc phải làm:** `--t2` `--dim`. Ẩn sau **3 lượt đầu tiên của run đầu tiên**, không phải sau wave 1. Sau đó chỉ hiện khi có tình huống cụ thể (`Không đủ Mana`, `Xúc xắc này không có mục tiêu hợp lệ`) với nền `var(--pan2)` và `role="status"`.

---

## PHASE E — Audit 4 màn chưa được kiểm

> `Reward` · `Shop` · `Event` · `Game Over / Victory`
> Bản audit gốc dừng ở wave 1 nên **chưa** kiểm 4 màn này. Bạn phải tự audit rồi tự sửa theo cùng bộ luật.

### E1 — Thu thập dữ liệu

Chơi tới từng màn (hoặc dùng seed / dev shortcut nếu repo có). Ở **mỗi** màn, chạy đúng script này trong console và lưu output vào `audit-<screen>.json`:

```js
(() => {
  const P = x => Math.round(x);
  const leaves = [...document.querySelectorAll('#app *')]
    .filter(e => [...e.childNodes].some(n => n.nodeType === 3 && n.textContent.trim()));
  const lin = c => { c/=255; return c<=0.04045 ? c/12.92 : Math.pow((c+0.055)/1.055,2.4); };
  const lum = ([r,g,b]) => 0.2126*lin(r)+0.7152*lin(g)+0.0722*lin(b);
  const cr = (a,b) => { const la=lum(a),lb=lum(b),hi=Math.max(la,lb),lo=Math.min(la,lb); return (hi+0.05)/(lo+0.05); };
  const rgb = s => (String(s).match(/[\d.]+/g)||[0,0,0]).slice(0,3).map(Number);
  const bgOf = el => { let e=el; while(e){ const b=getComputedStyle(e).backgroundColor;
    if(b && b!=='rgba(0, 0, 0, 0)') return rgb(b); e=e.parentElement; } return [11,13,16]; };
  return JSON.stringify({
    screen: document.querySelector('.screen')?.className,
    viewport: [innerWidth, innerHeight],
    text: leaves.map(el => { const c = getComputedStyle(el), r = el.getBoundingClientRect();
      return { cls: el.className || el.tagName, fs: parseFloat(c.fontSize),
               contrast: +cr(rgb(c.color), bgOf(el)).toFixed(2),
               chars: el.textContent.trim().length, w: P(r.width), h: P(r.height) }; }),
    controls: [...document.querySelectorAll('button,[role=button],.btn,[onclick]')]
      .map(el => { const r = el.getBoundingClientRect();
        return { cls: el.className, w: P(r.width), h: P(r.height),
                 txt: el.textContent.trim().slice(0,24) }; }),
    contentBox: (() => { const els=[...document.querySelectorAll('#app *')]
      .filter(e => e.getBoundingClientRect().width > 0);
      const b = els.reduce((a,e) => { const r=e.getBoundingClientRect();
        return { x0:Math.min(a.x0,r.left), y0:Math.min(a.y0,r.top),
                 x1:Math.max(a.x1,r.right), y1:Math.max(a.y1,r.bottom) }; },
        {x0:1e9,y0:1e9,x1:-1e9,y1:-1e9});
      return { w:P(b.x1-b.x0), h:P(b.y1-b.y0),
               fillPct: P((b.x1-b.x0)*(b.y1-b.y0)/(innerWidth*innerHeight)*100) }; })()
  }, null, 1);
})()
```

### E2 — Chấm theo checklist

Với mỗi màn, trả lời **bằng số**, không bằng cảm nhận:

| # | Câu hỏi | Cách trả lời |
|---|---|---|
| 1 | Có `fs < 11` không? | đếm từ `text[]` |
| 2 | Có `contrast < 4.5` không? | đếm từ `text[]` |
| 3 | Có control nào `w<44` hoặc `h<44`? | đếm từ `controls[]` |
| 4 | Có `--faint` (`rgb(89,97,110)`) dùng cho chữ? | grep output |
| 5 | Card nào cùng loại mà **khác chiều cao**? | so `h` trong `controls[]` |
| 6 | Hành động phá hoại nào (bỏ item, bán, thoát) trông giống hành động an toàn? | mắt + so `cls` |
| 7 | Có hành động **không thể hoàn tác** mà không có confirm? | thử |
| 8 | Nội dung lấp bao nhiêu % viewport? | `contentBox.fillPct` |
| 9 | Có nhánh nào **không có lối ra** (dead end)? | thử `Esc`, thử back |
| 10 | Có element nào **dịch chuyển** khi hover/chọn? | snapshot toạ độ trước/sau |
| 11 | Tab qua được hết không? | tab thủ công, đếm stop |
| 12 | Ở 393px có tràn ngang? | resize + đo `scrollWidth` |

### E3 — Sửa và ghi lại

- Sửa theo đúng 8 luật §1 và bảng token §3. **Không** phát minh token mới.
- Ghi phát hiện vào `AUDIT_PHASE_E.md`, format giống các task §5: hiện trạng đo được → tại sao sai → số đích → CSS patch.
- Thêm check tương ứng vào `verify.mjs` nếu phát hiện thuộc loại máy đo được (thêm vào phase `E`).

**Quy tắc đặc biệt cho Reward / Shop:** đây là màn người chơi ra quyết định tiêu tài nguyên. Ba thứ **bắt buộc** phải có:
1. Số tài nguyên hiện có, hiển thị thường trực, `--t4` — không phải 9px ở góc.
2. Giá và số dư sau khi mua, xem trước được **trước** khi xác nhận.
3. Nút bỏ qua (`SKIP`) rõ ràng, không giấu — và không được trông giống nút xác nhận.

---

## 6. Chạy verify.mjs

```bash
npm i -D playwright && npx playwright install chromium

node verify.mjs                                       # http://localhost:5173
node verify.mjs --url http://localhost:3000
node verify.mjs --only A                              # chỉ Phase A
node verify.mjs --json reports/phaseA.json            # xuất JSON
node verify.mjs --headed                              # xem browser chạy
```

**Cách đọc output:** mỗi dòng là một check với ID (`A2.combat`, `B1.phone`). `FAIL` in kèm tối đa 12 vi phạm cụ thể — selector, giá trị đo được, giá trị cần. Ví dụ:

```
FAIL  A2.combat  [combat] Mọi chữ đạt contrast AA
      2.4:1 (cần 4.5) 9px #59616e trên #212730 · .dp · "BACK"
```
Đọc là: element `.dp` chứa chữ `BACK`, cỡ 9px, màu `#59616e` trên nền hiệu dụng `#212730`, được 2.4:1, cần 4.5:1.

**32 check, phân bổ:** Phase A 21 · Phase B 9 · Phase C 2 · Phase D 1 (khuyến nghị, không chặn).
Exit code `0` = mọi check bắt buộc PASS. `1` = còn FAIL. `2` = script lỗi.

**Điều verify.mjs KHÔNG kiểm được — bắt buộc kiểm thủ công (§7):** chất lượng bản dịch/copy, có combat log hay không, thẩm mỹ bố cục, và mô phỏng mù màu.

---

## 7. Kiểm thủ công — 12 mục

Chạy sau khi verify.mjs xanh hết. Đánh dấu vào `MANUAL_QA.md`.

- [ ] Tab qua toàn bộ màn combat — mọi element tương tác có focus ring nhìn thấy rõ, thứ tự hợp lý
- [ ] Bấm `1`–`5` chọn xúc xắc, `Q`–`T` chọn mục tiêu, `Esc` hủy, `Space` end turn — đều hoạt động
- [ ] Zoom trình duyệt 200% — không chữ nào bị cắt hoặc chồng
- [ ] iPhone 15 Pro portrait: hiện gợi ý xoay ngang · landscape: chơi được đủ 5 xúc xắc
- [ ] iPad mini portrait 744px: bàn chơi vừa, `--ui-scale` = 1
- [ ] **Mô phỏng mù màu** (DevTools → Rendering → Emulate vision deficiencies → deuteranopia): phân biệt được damage / shield / heal **mà không cần màu**
- [ ] Địch tụt xuống 20% HP → thanh máu đổi đỏ và nhấp nháy; ta cũng vậy
- [ ] `ABANDON RUN` → qua modal xác nhận, nút hủy được focus mặc định
- [ ] Combat log ghi đúng nguồn → đích → số → phần bị chặn bởi Shield
- [ ] Chọn xúc xắc heal khi có đồng minh full máu → card đó `dashed` + mờ + badge `+0`
- [ ] Đọc trọn một section Codex mà không phải rướn người về màn hình
- [ ] Chơi hết 1 run 12 wave, không gặp màn nào bị dead end hoặc `undefined`

---

## 8. Cấm

1. **Không** thay đổi các con số trong §3 vì lý do thẩm mỹ. Chúng đã được verify bằng công thức.
2. **Không** dùng `opacity` để làm mờ chữ. Đặt `color` trực tiếp. (`opacity` trên container kéo theo mọi chữ con và phá contrast không kiểm soát được.)
3. **Không** thêm bậc chữ thứ 7, cỡ nút thứ 4, hay bậc surface thứ 5.
4. **Không** thêm `glow` / `box-shadow` phát sáng ngoài 3 chỗ ở L8.
5. **Không** dùng `zoom` làm chiến lược responsive. Nó là lớp tinh chỉnh cuối, sau breakpoint.
6. **Không** đổi tên `--faint` thành `--line` — `--line` đã tồn tại với giá trị khác.
7. **Không** dùng `div` + `onclick` cho thứ có thể là `<button>`.
8. **Không** đổi logic gameplay, cân bằng số, hay nội dung Codex. Task này thuần UI/UX. Nếu một fix UI đòi đổi luật chơi, dừng và ghi vào `DEVIATIONS.md`.
9. **Không** commit khi verify của phase hiện tại còn đỏ.
10. **Không** xoá hay nới lỏng check trong `verify.mjs` để làm nó xanh. Nếu tin một check sai, ghi vào `DEVIATIONS.md` kèm lý do và giữ nguyên check.

---

## 9. Commit và bàn giao

Một commit cho mỗi phase, chỉ commit khi phase đó xanh:

```bash
git add -A && git commit -m "feat(ui): Phase A — token, contrast, a11y (verify 21/21)"
git add -A && git commit -m "feat(ui): Phase B — responsive breakpoints (verify 9/9)"
git add -A && git commit -m "feat(ui): Phase C — combat UX (verify 2/2)"
git add -A && git commit -m "feat(ui): Phase D — polish"
git add -A && git commit -m "feat(ui): Phase E — audit + fix reward/shop/event/gameover"
```

**Definition of Done — cả 8 mục:**

1. `node verify.mjs` → exit 0, **32/32** check bắt buộc PASS
2. `reports/baseline.json` và `reports/final.json` đều tồn tại, cho thấy tiến triển
3. `DEVIATIONS.md` liệt kê mọi chỗ lệch spec kèm lý do
4. `PREFLIGHT.md` ghi cấu trúc repo thật
5. `AUDIT_PHASE_E.md` ghi phát hiện + fix cho 4 màn chưa audit
6. `MANUAL_QA.md` đủ 12 mục §7 đã tick
7. `grep -rn -- '--faint'` rỗng; `grep -rn 'btn xs'` rỗng
8. Không có console error trong suốt một run 12 wave hoàn chỉnh

---

## 10. Ba điều nên giữ nguyên

Audit không chỉ để chê. Ba quyết định sau là đúng — bảo vệ chúng khi refactor:

1. **Bảng màu semantic.** Vàng = hành động được, đỏ = damage, xanh dương = shield, tím = mana. Nhất quán tuyệt đối trên mọi màn hình. Đây là phần mạnh nhất của design system v0.8 — đừng đụng vào.
2. **Nền xám khử bão hoà.** Quyết định "chỉ sprite Axie được bão hoà" là đúng về mặt hướng mắt. Vấn đề chỉ là các bậc xám hiện quá sát nhau, không phải chọn sai hướng.
3. **Preview số sát thương/khiên trên đầu mục tiêu.** `-2`, `SH +7` xuất hiện ngay khi chọn xúc xắc là feedback loop rất tốt, ngang tầm các game hàng đầu trong thể loại. Chỉ cần sửa việc nó đẩy layout (T12).

---

## Phụ lục — nguồn gốc mọi con số

| Loại | Cách lấy |
|---|---|
| px, màu, padding, kích thước | `getComputedStyle` + `getBoundingClientRect` trên bản build tại `https://axiedice.vercel.app` v0.9, 14/08/2026 |
| Contrast ratio | Công thức WCAG 2.1 relative luminance, tính từ mã màu computed thật, có gộp lớp bán trong suốt |
| Advance width & x-height của font | `canvas.measureText()` trên chính bản build |
| Đếm ký tự theo cỡ chữ | Duyệt DOM, chỉ tính element có text node trực tiếp |
| Số media query (547 rule, 1 `@media`) | Duyệt `document.styleSheets[].cssRules` |
| 846px min-width | Tính từ token đã đo: `5×158 + 4×8 + 2×12` |
| Hệ quả trên 393px | **Phép tính**, chưa xác nhận trên thiết bị — nhưng `verify.mjs` nay chạy viewport 393 thật nên sẽ xác nhận được |
| Bảng token đích §3 | Mọi tỷ lệ tính lại và kiểm chứng bằng `REFERENCE.html` (PASS 32/32) |
