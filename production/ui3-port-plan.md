# Port UI-03 (A4 Blend, Terrariums) vào game — kế hoạch làn

Viết 18/10/2026. Quyết định Liam 18/10: làm cả 25 màn, làm luôn xúc xắc 3D vật lý, giữ bắt đăng nhập, font Rowdies Bold + Work Sans Regular.
Nguồn: `design/handoffs/ui-03-redesign/round-1/handoff/` (spec thắng ảnh nếu lệch). Màn chưa có mockup: `round-1/GAP-LIST.md`, prompt vòng 2: `PROMPT-ROUND-2.md`.

## Thứ tự

**Bước 0 (đang làm):**
- Làn U: nền theme: `UI3Theme.gd` (Theme dựng từ `tokens_ui3.json`), `UI3.gd` (bộ component), font, icon, test `t_ui3_theme`, ảnh gallery.
- Làn C: `DiceRoller3D.gd` (xúc xắc 3D chỉ để nhìn, kết quả vẫn do engine).

Merge nền theme trước, mọi làn màn sau đều dựa vào nó.

**Bước 1 (sau khi nền merge, tối đa 4 làn cùng lúc):**

| Làn | Màn (số trong handoff) | Agent |
|---|---|---|
| U | 18 system (modal, toast, network notice, skeleton), 16 boot/sign-in, 26 settings + account, 17 tutorial | ui-programmer |
| C | 02 combat HUD + nối DiceRoller3D vào khay mới | ui-programmer + godot-specialist |
| M | 03 run map, 06 run setup, 07 reward, 08 shop, 09 event, 13 treasure, 12 pact, 14 in-run menu, 10 result | ui-programmer |
| L | 01 land hub HUD, 27 team presets, 28 land upgrade, 24 profile, 23 leaderboard | ui-programmer |
| E (khi có làn rảnh) | 19 store, 20 echo box, 21 pass, 22 missions, 25 vault, 29 codex/guides/unlocks | ui-programmer |

**Bước 2:** màn vòng 2 từ Claude Design (gap list) khi Liam gửi về.

## Luật cho mọi làn
- Màn mới chỉ dùng `UI3Theme` / `UI3`, không gọi `DangoTheme`. Màn chưa port vẫn dùng Dango cho tới khi tới lượt; xong hết thì xoá Dango.
- Logic và luật không đổi. Không sửa file luật (`scripts/core/*`, `data/rules/*`), `t_rules_version` phải xanh.
- Test cũ khẳng định UI cũ (t_mainmenu_ui, t_button_states, t_runloop_ui, …): sửa theo UI mới, không bỏ kiểm tra. Mỗi màn có ít nhất một test tương tác hoặc trạng thái.
- Mỗi màn: ảnh ở 1920×1080 và 1280×720 (`godot/tools/shot.sh`) vào `production/qa/evidence/ui3-<màn>-*.png`, art-director xem ảnh so với spec.
- Định nghĩa "xong" như `l1-plan-16-10.md`: review bởi agent khác → merge đúng commit → kiểm xung đột + `--import` → suite cây chính xanh không SKIP → push. Màn chạm online (boot, account, run setup, result, missions, store): live smoke PASS trước khi đưa build cho Liam.
- Placeholder trong spec (giá, tỉ lệ Echo Box, phần thưởng Pass…) lấy số thật từ data của game, không dùng số trong mockup.
