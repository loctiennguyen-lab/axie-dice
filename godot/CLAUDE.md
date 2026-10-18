# UI rules — đọc trước khi sửa file nào trong `godot/scenes/`

Game UI đã dựng lại theo **UI-03** (Claude Design "A4 Blend" trên Terrariums design system).
Mọi quy tắc cũ về Dango/Homeland v3 (`DangoTheme`, `surface_style()`, `mockups-v2`, chữ 9-11 px,
Baloo) **không còn đúng** cho màn đã port.

## Thiết kế nằm ở đâu

- Round 2 thắng round 1: `design/handoffs/ui-03-redesign/round-2/handoff/` (README, components.md,
  motion.md, tokens.json, `screens/<id>/spec.md`, file HTML tổng).
- Round 1 vẫn dùng cho phần round 2 không nhắc: `round-1/handoff/` (README có luật toàn cục,
  tokens.json, components.md, motion.md, `screens/<id>/spec.md`).
- Con số đọc từ spec/tokens, không đoán, không làm tròn. Vị trí thì dựng theo quan hệ, không chép toạ độ y.

## Code

| Gì | Ở đâu |
| --- | --- |
| Token (màu, cỡ chữ, viền, bóng) | `scenes/shared/ui3/UI3Theme.gd`, đọc từ `assets/data/ui/tokens_ui3.json` |
| Component (nút, chip, panel, badge...) | `scenes/shared/ui3/UI3.gd` |
| Khung màn meta (header, footer, nội dung) | `scenes/shared/ui3/UI3Meta.gd` |
| Tooltip | `scenes/shared/ui3/UI3Tooltip.gd` |
| Xúc xắc 3D | `DiceRoller3D` + `axie_die.glb` |
| Test | `t_ui3_theme`, `t_ui_laws` (L0 PlateHost, L2 bề rộng scroll, L7 viền token trên box gắn cờ "ui3") |

## Luật toàn cục

- Canvas 1920x1080, stretch `canvas_items` + `expand`. 1280x720 = scale 0.667, vẫn phải đọc được.
- Cỡ chữ: 16 (chỉ key hint) / 18 / 24 / 32, thêm 36 cho banner lượt, số trên xúc xắc 28/20. Không cỡ nào khác.
- Font: Rowdies 700 + Work Sans 400 (body vẫn Work Sans), không trộn hai font trong một label.
- Vùng bấm >= 44 px. Lưới 8 px, lề màn 24.
- Chữ màu cream, không bao giờ trắng tinh.
- Mỗi màn 1 nút primary, tối đa 2 secondary.
- Đang chọn: viền cream 4 px. Focus: vòng amber 2 px, cách 4 px.
- Nút disabled phải nói lý do (text hoặc tooltip), không chỉ xám đi.
- Đỏ chỉ dùng cho nguy hiểm (danger).
- StyleBox phẳng + bóng cứng. Không blur, không gradient, không mask, không shader trên UI; mỗi panel một nền trong suốt duy nhất.
- Scrim modal: neutral-1 @ 80%.
- Esc: trong combat và trên run map mở menu in-run; màn khác thì theo Esc ghi trong spec của màn đó.
- Gem violet chỉ dùng cho bề mặt trả tiền.
- Màn vừa khít hoặc scroll. Một hàng bị cắt mà không có scrollbar là lỗi nặng nhất.
- Màu/swatch mã hoá cơ chế thì kèm glyph của cơ chế đó, không để màu đứng một mình.

## Dựng một màn

1. Đọc `screens/<id>/spec.md` của round 2, rồi round 1 nếu thiếu.
2. Chỉ dùng `UI3` / `UI3Meta`. Cần component mới thì thêm vào `UI3.gd`, không dựng tại chỗ.
3. Token, không hex. Thiếu màu thì thêm vào `tokens_ui3.json`.
4. Không `Label`/`Button` font override lẻ; cỡ chữ lấy từ token.
5. Chụp ở **2 cỡ** (vd 1920x1080 và 1280x720) bằng `godot/tools/shot.sh <scene> WxH`, so với spec.
6. Chạy `godot/tools/run_tests.sh` (số sàn ở `.claude/docs/technical-preferences.md`).
7. Báo rõ cái gì chưa làm được. Không tự bịa UI không có trong spec. Luật sửa cho một chỗ thì áp cho mọi chỗ cùng loại.

## Bẫy đã gặp ở đợt này

- `t_rules_version` lấy fingerprint của cả `autoload/`, `scripts/core/`, `scripts/meta/`,
  `resources/relics/`, `assets/data/`, `rules/`. Đụng file nào trong đó (kể cả json) là phải
  bump `RULES_VERSION` hoặc test đỏ.
- Test có thể đọc save thật ở cây chính. Cô lập save (userdir/override.cfg) trước khi chạy.
- Mỗi helper chỉ có MỘT định nghĩa trong `UI3.gd`. Trùng tên là lỗi parse, và parse error làm
  headless bị treo thay vì báo lỗi (chạy `--import` trước).
- Text relic/pact luôn qua `UI3.describe()` / `player_text()`. Không tự ghép chuỗi từ data thô.
- Không dùng `git stash` (làn khác dùng chung repo). Không `pkill` chung chung, chỉ kill đúng PID của mình.
- Mọi lần chạy Godot qua `godot/tools/with_lock.sh`.

## Legacy

`DangoTheme` / `DangoScreen` / `MockupAssets` / `dango.tres` (`tools/gen_theme.gd`) chỉ còn ở các
màn chưa port (vd MainMenu, TeamSelect, Result, Codex, Unlocks, Leaderboard, TeamPresets). Không
dùng cho code mới. Khi màn cuối cùng được port thì xoá hết, kể cả `t_mockup_assets`.
