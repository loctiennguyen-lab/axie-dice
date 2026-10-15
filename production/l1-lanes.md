# L1 — các làn, worktree, quy tắc merge

Nguồn gốc: `production/l1-sprint-plan.md` §1 (bảng sở hữu) và mục "Chạy suite test". File này chỉ là sổ tra nhanh. Lệch nhau thì lấy plan.

## Bảng làn

Worktree nằm cạnh repo chính, tại `/Users/loc.tien.nguyen/my-game-wt/<làn>`, nhánh `l1/<làn>` tách từ `godot-port`.
Làn I làm việc ngay trong `/Users/loc.tien.nguyen/my-game` (nhánh `godot-port`). Làn D (thiết kế) cũng làm trong cây chính, chỉ sửa `design/`, không có worktree.

| Làn | Tên | Worktree | Nhánh | File / thư mục sở hữu |
|---|---|---|---|---|
| A | Luật combat | `/Users/loc.tien.nguyen/my-game-wt/A` | `l1/A` | `godot/scripts/core/` **trừ** `relic_hooks.gd`, `damage_pipeline.gd`, `save_store.gd` (`reward_generator.gd` của B, nhưng A sửa các điểm epoch seed trước 17/10); `godot/autoload/RunState.gd`; `godot/autoload/ContentDB.gd` (toàn bộ file), `scripts/data_models/run_map_*.gd`; A chèn điểm gọi hook rỗng + state relic trong `combat_engine.gd`/`RunState.gd` cho B |
| B | Relic | `/Users/loc.tien.nguyen/my-game-wt/B` | `l1/B` | `godot/scripts/core/relic_hooks.gd`, `damage_pipeline.gd`, `reward_generator.gd`, `godot/autoload/RelicRegistry.gd`, `godot/resources/relics/` |
| S | Server tối thiểu | `/Users/loc.tien.nguyen/my-game-wt/S` | `l1/S` | `worker/` (src, test, wrangler), `godot/scripts/net/`, `godot/autoload/AccountService.gd` |
| E | Economy + meta logic | `/Users/loc.tien.nguyen/my-game-wt/E` | `l1/E` | `godot/autoload/MetaState.gd`, `godot/scripts/core/save_store.gd`, `godot/scripts/meta/` (mới), `godot/assets/data/economy/` (mới); **không** sửa `ContentDB.gd` (xem mục 4 bên dưới) |
| C | Combat 3D + Atia | `/Users/loc.tien.nguyen/my-game-wt/C` | `l1/C` | `godot/scenes/shared/CombatStage3D.*`, `BattleBackdrop.gd`, `godot/scripts/data_models/monster_art.gd`, `monster_anim.gd`, `godot/assets/monsters/`, `godot/assets/bosses/`, `godot/assets/atia/` (mới) |
| U | UI combat + run flow | `/Users/loc.tien.nguyen/my-game-wt/U` | `l1/U` | `godot/scenes/shared/DangoTheme.gd`, `godot/resources/theme/`, `godot/scenes/combat/` (`CombatView.gd`, `Combat.tscn`; `CombatStage3D` là của C), `scenes/shared/` còn lại (`DangoScreen`, `AccountUI`, `MockupAssets`, `UnitPortrait`, `AxiePreview3D`), `scripts/ui/`, `scenes/tutorial/`, `UnitHeadHUD.gd`, `HPBar.gd`, `godot/scenes/run_map/`, `godot/scenes/result/`, `godot/assets/icons/` |
| L | Land 3D hub | `/Users/loc.tien.nguyen/my-game-wt/L` | `l1/L` | `godot/scenes/land/` (mới), `godot/assets/land/` (mới), `godot/scenes/main_menu/` (`MainMenu.gd`, `TeamSelect.gd`) |
| M | Màn meta | `/Users/loc.tien.nguyen/my-game-wt/M` | `l1/M` | `godot/scenes/pass/`, `vault/`, `codex/`, `settings/`, `guides/`, `unlocks/`, `godot/scenes/echobox/`, `missions/`, `store/`, `run_setup/` (mới) |
| R | Build + QA | `/Users/loc.tien.nguyen/my-game-wt/R` | `l1/R` | `godot/export_presets.cfg`, script export, `production/qa/`, file hướng dẫn cài |
| I | Tích hợp | `/Users/loc.tien.nguyen/my-game` | `godot-port` | `godot/tests/t_rules_version.gd`, `godot/project.godot` (autoload, cài đặt), `godot/tools/run_tests.sh`, `.claude/docs/technical-preferences.md` (mức sàn), nhánh `godot-port` |

## Quy tắc merge

1. Chỉ làn I merge vào `godot-port`. Làn khác không merge, không push `godot-port`.
2. Làn tự commit trên nhánh `l1/<làn>` của mình. Muốn vào `godot-port` thì báo làn I.
3. Trước khi merge: nhánh làn rebase lên `godot-port` mới nhất (làn I hoặc làn chủ nhánh rebase, không để conflict trôi sang `godot-port`).
4. Chỉ sửa file mình sở hữu. File chung (`FINGERPRINT`, `RULES_VERSION`, `project.godot`, `run_tests.sh`, mức sàn test) chỉ làn I sửa. Cần đổi thì gửi yêu cầu cho làn I.
5. `FINGERPRINT` trong `t_rules_version.gd`: không làn nào tự sửa. Làn I tính lại sau mỗi merge và ghi "đổi kết quả run: có/không" vào mô tả merge. Conflict ở dòng này giải bằng cách tính lại, không chọn bên.
6. Mức sàn test (hiện 68/68 từ 12/10, sau merge A PR2, trong `.claude/docs/technical-preferences.md`): đổi suite thì đổi con số trong cùng commit.
7. Push: chỉ `git push axiedice godot-port:main`, không bao giờ `origin`. Không deploy.

## user:// riêng cho mỗi worktree (override.cfg)

Từ 12/10 (chiều) mỗi worktree làn có file `godot/override.cfg` (KHÔNG track, đã vào `.gitignore`):

```
[application]
config/use_custom_user_dir=true
config/custom_user_dir_name="AxieDice-wt-<làn>"
```

Godot 4.7.2 đọc file này ở thư mục project (đã kiểm: headless báo user dir `~/Library/Application Support/AxieDice-wt-<làn>`; bỏ file thì về `app_userdata/Axie Dice (Godot port)`). Hệ quả:
- Save/test của worktree nằm ở user dir riêng, KHÔNG còn chạm save thật của Liam ở `app_userdata/Axie Dice (Godot port)`. Cây chính (không có override.cfg) giữ hành vi cũ.
- Khoá cũng riêng theo worktree: `~/Library/Caches/axie-dice-godot-AxieDice-wt-<làn>.lock`. Các làn không xếp hàng chung nữa. Chỉ cây chính (làn I, save thật) dùng khoá chung `axie-dice-godot.lock`. Logic suy ra user dir + khoá nằm ở `godot/tools/userdir.sh`, dùng chung cho `with_lock.sh` và `run_tests.sh`.
- User dir mới trống = như máy cài mới. Muốn có save mẫu thì chép tay vào thư mục đó.
- Worktree mới tạo sau này: tự tạo `godot/override.cfg` như trên (tên khác nhau cho mỗi worktree, đừng dùng chung tên).
- Làn R: file override.cfg không được vào bản build. Trước khi export, kiểm gói export không chứa nó (hoặc build từ cây không có file này).
- `with_lock.sh` / `run_tests.sh` luôn suy user dir từ project của CHÍNH worktree chứa script; đừng chạy script của worktree này với `--path` của worktree khác.

## Chạy Godot: BẮT BUỘC qua khoá

Hai lần chạy Godot trên CÙNG một user dir sẽ giẫm nhau (trong cùng worktree, hoặc cây chính). Vì vậy MỌI lần chạy Godot, ở worktree nào cũng vậy, đều đi qua `godot/tools/with_lock.sh`:

```
# cả suite (run_tests.sh tự xin khoá, gọi trực tiếp cũng được)
bash godot/tools/run_tests.sh

# một test lẻ
godot/tools/with_lock.sh "$GODOT" --headless --path godot res://tests/t_codex.tscn
# nhập lại project
godot/tools/with_lock.sh "$GODOT" --headless --path godot --import
# mở editor (giữ khoá tới khi đóng editor, nên đóng khi xong việc)
godot/tools/with_lock.sh "$GODOT" --path godot --editor
# tool
godot/tools/with_lock.sh "$GODOT" --headless --path godot res://tools/record_sample_run.tscn -- --seed=991237 --out=/tmp/x.json
```

- `GODOT=/Users/loc.tien.nguyen/Desktop/Godot.app/Contents/MacOS/Godot`.
- Khoá là thư mục trong `~/Library/Caches/` (mkdir nguyên tử, ngoài repo; riêng theo user dir như trên). Có file `pid`; pid chết thì khoá bị coi là chết và người sau tiếp quản. Khi phải chờ, script in ra ai đang giữ. Chờ tối đa 30 phút (`AXIE_LOCK_TIMEOUT`).
- Lỗi parse GDScript làm Godot treo, mac không có `timeout`. Chạy lẻ nên đặt `AXIE_HANG_KILL=120` (giây) để kill và nhả khoá.
- Mỗi lần chạy suite đầy đủ mất khoảng 1,5 phút (đo 12/10: 91s). Làn thường chỉ chạy test lẻ của file mình; suite đủ do làn I chạy sau merge.
- `record_sample_run.tscn` và `verify_run.tscn` đã có SaveGuard (không còn đè save thật).
- Worker test (`node --test`) không chạm `user://`, không cần khoá.

## Cờ bỏ qua `t_rules_version` (chỉ cho worktree của làn)

`FINGERPRINT` bao cả `scripts/core/` và `autoload/`, nên `t_rules_version` đỏ trong mọi worktree đã sửa hai chỗ đó. Đây là lỗi dự kiến. Để chạy được "xanh trừ gate này":

```
AXIE_SKIP_RULES_FINGERPRINT=1 bash godot/tools/run_tests.sh
```

Runner báo `SKIP t_rules_version`, in cảnh báo màu vàng, và dòng tổng ghi rõ "SKIPPED". Làn I và mọi lần kiểm trước merge/RC KHÔNG đặt cờ. Không đặt cờ thì chạy y như cũ.

## Nhận bản with_lock.sh mới (bắt buộc)

Bản `with_lock.sh` / `run_tests.sh` ngày 0 có lỗi (Godot mồ côi sau Ctrl-C hoặc hang-kill, save không được trả khi bị TERM). Bản đã sửa nằm trên `godot-port`. Mỗi làn chạy ngay trong worktree của mình:

```
git rebase godot-port
```

Chưa rebase thì đừng chạy Godot. Cờ `AXIE_SKIP_RULES_FINGERPRINT=1` giờ bị từ chối (exit 2) ở worktree chính và khi có biến `CI`. `run_tests.sh` mặc định có watchdog 900s. Test của khoá: `bash godot/tools/tests/with_lock_test.sh`.

## Mới tạo worktree

Thư mục `godot/.godot/` (cache import) không nằm trong git. Lần đầu trong worktree mới, `run_tests.sh` tự import nếu thiếu `.uid`; nếu vẫn lỗi "Identifier not declared", chạy `--import` qua `with_lock.sh` rồi thử lại.

## Sau merge A PR1 + B (12/10): việc của mỗi làn

- `git rebase godot-port` rồi chạy `godot/tools/with_lock.sh "$GODOT" --headless --path godot --import` (class_name mới `EpochSource`, `EpochReply`, `LocalEpochSource`... chưa có trong cache nên test cũ báo "Could not find type"; `.uid` có sẵn nên runner không tự import).
- `RULES_VERSION` giờ là `godot-2026-10-12-a`; `t_rules_version` phủ cả `resources/relics` và `assets/data/rules`.
- Nợ còn mở của làn I: `production/l1-tasks-I.md`.


## Live smoke trước khi đưa build cho Liam (16/10)

`godot/tools/live_smoke.sh` (chạy ở worktree có `godot/override.cfg`, ví dụ R): chép phiên đăng nhập của app desktop
vào user dir riêng, chạy một run online thật trên production (Begin → vào ô → thắng trận → nhận thưởng → ô 2 →
bỏ run), in `LIVE SMOKE PASS` mới được đưa bản build cho Liam. Cần: Liam đã đăng nhập trên app desktop, app đang tắt,
tài khoản không có run dở (preflight sẽ từ chối, không đụng vào). Tốn 1/20 run trong ngày. Không chạy trong sandbox
không có mạng.
