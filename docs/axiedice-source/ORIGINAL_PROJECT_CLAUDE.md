# Axie Dice Tactics: Lunacia Mutants — Repo Guide

Đọc file này trước khi sửa bất cứ thứ gì. Nó mô tả **trạng thái thật** của
repo, không phải trạng thái mong muốn.

---

## 1. Game là gì

Roguelike chiến thuật xác định (deterministic), chạy trong trình duyệt.
Mỗi Axie **là một con xúc xắc 6 mặt**; mỗi mặt là một body part. Đầu lượt
cả hai phe đổ xúc xắc; **mặt địch đổ ra chính là intent công khai của
chúng**. Người chơi kéo-thả mặt của mình lên mục tiêu, có reroll giới hạn.
Nguồn cảm hứng cơ học: Slice & Dice. Nguồn IP: Axie Infinity.

---

## 2. Kiến trúc build — KHÔNG có bundler

Không có `npm run dev`, không có `dist/`, không có node_modules cho game.
Game là **một file HTML tự chứa**.

```bash
python3 build.py            # -> build/AxieDiceTactics.html  (có devtools)
python3 build.py public     # -> build/index.html            (bản deploy, gỡ devtools)
```

`build.py` chỉ nối chuỗi: nó thay các placeholder `%CSS% %ART% %DATA%
%ENGINE% %AUDIO% %ICONS% %UI% %FX% %DEV%` trong một template HTML bằng nội
dung các file trong `src/`. **Thứ tự nối là thứ tự thực thi** — `data.js`
phải đứng trước `engine.js`, `ui.js` trước `fx.js`.

Deploy: `build/index.html` là toàn bộ artifact. Vercel/Netlify/S3 đều chỉ
cần đúng file đó.

---

## 3. Bố cục repo

```
src/
  art.js       sprite data (một dòng, ~230KB — đừng mở bằng editor thường)
  data.js      pool mặt xúc xắc, relic, enemy, wave table
  engine.js    toàn bộ luật chơi. Thuần hàm, không chạm DOM.
  audio.js     WebAudio bíp, không asset ngoài
  icons.js     icon vẽ bằng CSS/inline SVG
  ui.js        mọi màn hình (sc* = screen). Render toàn bộ mỗi lần.
  fx.js        animation combat + drag/drop pointer. Đọc s.ev.
  devtools.js  chỉ có trong build dev
  style.css    design system + toàn bộ layout

build/         output của build.py
tools/         xem §5
reports/       kết quả verify: baseline.json -> phaseA.json -> final.json
docs/          xem §7
```

### Ranh giới engine ↔ UI (quan trọng)

`engine.js` **không được** import hay chạm tới DOM. Nó phát ra một **event
stream** `s.ev` (mảng các sự kiện: damage, shield, poison, death, …).
`fx.js` replay stream đó thành animation **mà không render lại**. Nếu bạn
thêm một cơ chế mới mà quên emit event, cơ chế vẫn đúng về số nhưng người
chơi sẽ không thấy gì xảy ra.

---

## 4. Tám luật UI (từ `docs/uiux/UIUX_IMPLEMENTATION_BRIEF_v1.md`)

Đây là các luật `tools/verify.mjs` kiểm tự động. Vi phạm = check đỏ.

1. **Thang chữ đóng.** Chỉ dùng các token `--t1..--t6`, `--die-num`,
   `--die-kw`, `--intent-v`. Không có chữ < 11px. Không hardcode px cho
   font-size.
2. **Contrast.** Chữ ≥ 4.5:1 (WCAG AA). Viền/element phi-chữ ≥ 3:1
   (WCAG 1.4.11).
3. **Token `--faint` đã bị xoá vĩnh viễn.** Nó là nguyên nhân gốc của toàn
   bộ lỗi contrast ở v0.9. Đừng thêm lại, kể cả dưới tên khác.
4. **Tap target ≥ 44×44** (WCAG 2.5.5). Kỹ thuật dùng: `::before` với
   inset âm để nới vùng chạm mà không nới hình. Yêu cầu phần tử cha có
   `position: relative`.
5. **Không layout shift khi hover/active/select.** Cấm `transform:
   translateY()` trên `.unit`, `.die`, `.nodecard`, `.rcard`, `.btn`.
   Dùng đổi màu/viền/glow.
6. **Không lộ `undefined` / `NaN` / `null`** ra UI ở bất kỳ màn nào.
7. **Responsive bằng breakpoint, không bằng zoom.** Có 3 breakpoint thật
   (1199 / 899 / 599) đổi kích thước component. `--ui-scale` (áp qua
   `zoom` trên `#app`) chỉ là **lớp tinh chỉnh cuối**, và JS chỉ đặt nó
   ≠ 1 khi `innerWidth ≥ 1200`.
8. **Phone portrait ẩn bàn chơi, hiện gợi ý xoay máy.** Game chơi ở
   landscape.

### Bẫy font đã gặp

Font pixel không có glyph cho `▸ ☠ ♾ ↯ ↺ ✕` — chúng render thành ô tofu.
Dùng chữ hoặc hình CSS thay thế. Đã sửa một lượt; đừng thêm ký tự lạ mới
mà không chụp màn hình kiểm.

### Bẫy tên class đã gặp

Đã có 3 vụ trùng tên class giữa các màn (`.cxhead`, `.bplv/.bpstate/.bpttl/
.bpn`, `.gb`). CSS là một namespace phẳng cho cả game. Đặt tiền tố theo
màn khi thêm class mới.

---

## 5. Công cụ kiểm thử (`tools/`)

Playwright chạy headless. **Bắt buộc** hai tham số này, nếu không sẽ báo
`Executable doesn't exist`:

```js
chromium.launch({ executablePath: '/opt/pw-browsers/chromium',
                  args: ['--no-sandbox'] })
```

Quy trình chuẩn — **phải khởi động server trước mỗi lần chạy**, nó hay
chết giữa các lần:

```bash
python3 build.py                       # build dev
python3 tools/serve.py &               # http://localhost:5173
node tools/verify.mjs                  # 30 check UI/UX -> reports/
node tools/soak.mjs                    # soak bằng click DOM
node tools/soakm.mjs                   # soak bằng chuột thật (pointer events)
node tools/sim.js                      # sim cân bằng, không cần trình duyệt
node tools/shots.mjs                   # chụp màn hình mọi screen
```

| File | Việc |
|---|---|
| `verify.mjs` | 30 check conformance. **Hiện 29/30 pass.** |
| `verify.original.mjs` | bản gốc từ project doc, giữ để đối chiếu |
| `sim.js` | chạy `data.js` + `engine.js` qua Node `vm`, không DOM. Dùng để cân bằng. |
| `soak.mjs` / `soakm.mjs` | **Cần cả hai.** soak.mjs (click DOM) từng pass 55 run sạch trong khi đường chuột thật vẫn còn bug. |
| `t_aoe.mjs` | repro riêng cho bug mặt AoE/Mana/Summon |
| `t_fit.mjs` | kiểm `fitUI()` ở nhiều viewport |
| `serve.py` | static server cổng 5173 |

> **Luật:** không được sửa hay nới lỏng check trong `verify.mjs` để làm
> nó xanh (brief §8.10). Nếu một check đỏ vì bạn làm đúng spec, ghi vào
> `docs/uiux/DEVIATIONS.md` — đó là điều đã làm với `N1.phone`.

---

## 6. Bảy bất biến kinh tế (`docs/economy/`)

Bắt buộc với mọi thay đổi chạm progression. Chi tiết ở
`ECONOMY_AND_PROGRESSION_v2.md`; tóm tắt:

- **INV-1** Bộ sưu tập chỉ giữ **danh tính** part, không giữ sức mạnh.
- **INV-2** Mọi part vào run ở bậc **COMMON**. Không có ngoại lệ.
- **INV-3** Bậc (rarity) là thuộc tính của **mặt xúc xắc trong một ván**,
  không phải của part. Kết thúc run là mất.
- **INV-4** Lên tier **nâng bậc mặt đang có**, **không đổi `partId`**.
  Danh tính hero được giữ suốt run.
- **INV-5** Gene Mutation là cơ chế đổi danh tính duy nhất, và nó **hạ mặt
  về COMMON**. Nếu không, "giữ part tới cuối run" thành zero-cost.
- **INV-6** Mọi part **ở cùng một bậc** phải nằm trong cùng ngân sách sức
  mạnh **±10%**. Vi phạm = đưa gradient sức mạnh vào tầng sưu tầm = pay-to-
  win. **Phải kiểm tự động trong CI**, không review tay.
- **INV-7** Mythic gắn với cặp **`class × slot`**, không gắn với part cụ
  thể. Bất kỳ part nào của class đó ở slot đó, khi đạt LEGENDARY, đều lên
  Mythic được.

---

## 7. Bản đồ tài liệu

| File | Đọc khi |
|---|---|
| `docs/design/SDD_GDD_OVERVIEW_v1.md` | **Bắt đầu ở đây.** Master overview 13 mục. |
| `docs/design/GDD_Axie_Dice_Tactics_Lunacia_Mutants.md` | GDD gốc (trích từ .docx) |
| `docs/design/AUDIT_AND_SPEC_v1.md` | spec cơ học chi tiết (§B vocabulary, §B5 Class×Tier) — **một phần đã bị ECONOMY_v2 Phụ lục D thay thế** |
| `docs/design/BLOODLINE_SYSTEM_v1.md` | hệ 192 part → mặt, bản sắc 6 class, lộ trình season |
| `docs/design/PART_TIER_SYSTEM.md` | bảng leo thang 4 bậc |
| `docs/design/AXIE_BODY_PARTS_DB.md` | 192 part + card text Origins (179/192 có text) |
| `docs/design/COMBO_DECISION_MEMO.md` | vì sao CHAIN/COMBO bị **gác lại** |
| `docs/design/QA_AND_BUGFIXES_v0.7.md` | lịch sử bug |
| `docs/economy/ECONOMY_AND_PROGRESSION_v2.md` | **nguồn chân lý** về economy. 16 quyết định D1–D16. |
| `docs/economy/BUILD_SPEC_v1.md` | kế hoạch triển khai economy, mốc M0–M7 |
| `docs/economy/*.json` | dữ liệu economy — **xem cảnh báo ở HANDOVER §3** |
| `docs/uiux/UIUX_IMPLEMENTATION_BRIEF_v1.md` | task T01–T26 + Phase A–E |
| `docs/uiux/UIUX_AUDIT_v0.9.md` | audit gốc, lý do đằng sau từng luật |
| `docs/uiux/DEVIATIONS.md` | **mọi chỗ build lệch khỏi brief, kèm lý do** |
| `docs/guide/PLAYER_GAME_GUIDE_v1.md` | game giải thích cho người chơi thế nào |

---

## 8. Cạm bẫy shell đã mất thời gian

- Bash **giữ cwd giữa các lệnh**. Nhiều heredoc dạng `cd src && python3 …`
  đã âm thầm không chạy vì cwd đã ở trong `src`. Luôn dùng đường dẫn tuyệt
  đối hoặc tương đối từ gốc repo.
- Server chết giữa các lần chạy → khởi động lại `serve.py` trước mỗi
  `verify.mjs`.

---

## 9. Trạng thái hiện tại — nói thẳng

**Đang chạy được:**
- Vòng chơi combat đầy đủ, map, relic, shop, boss, Ascension ladder
- Drag/drop chuột + chạm; mặt không cần mục tiêu (All/Mana/Summon) đã sửa
- verify **29/30**. Check đỏ duy nhất `N1.phone` là **hệ quả của việc làm
  đúng T11** — đã ghi ở DEVIATIONS. Check thiết kế cho đúng tình huống đó
  (`B4`) thì xanh.
- Sim: A0 winrate 14.5%, hình dạng ladder giữ nguyên
- Không còn mặt trống ở Tier 1 (trước: 59.8% lượt T1 có một Axie chết
  cứng; giờ 0%). Reroll cơ bản 1 → 2.

**Chưa xong:** xem `HANDOVER.md`.

**Bị chặn:** stream economy (BUILD_SPEC M0–M7) chặn ở M0. Xem
`HANDOVER.md` §3 — đây là thứ quan trọng nhất phải đọc trước khi hứa
timeline.
