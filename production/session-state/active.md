# Axie Dice — trạng thái hiện tại

Cập nhật: 2026-10-12. Nhánh `godot-port`, push lên `axiedice` (`git push axiedice godot-port:main`).
Bản đầy đủ trước khi rút gọn: `archive/active-2026-10-12-before-rewrite.md`. Backlog trước 20/9: `archive/2026-09-pre-cowork/` (đã bỏ).

## ⇢ BẮT ĐẦU TỪ ĐÂY

1. **Mở `production/session-state/pending-decisions.md`** — 23 câu (A art, B monetization, C kiến trúc) + câu commit (D),
   mỗi câu có đề xuất. Liam nói sẽ trả lời ở session này. Đưa danh sách cho Liam, ghi quyết định vào đầu file nguồn,
   rồi làm "Việc sau khi Liam trả lời" ở cuối file đó.
2. Không có agent nào đang chạy. Không có server preview nào đang mở.
3. Có việc CHƯA COMMIT (xem `pending-decisions.md` mục D) — chỉ commit/push khi Liam cho phép.

## Quy tắc làm việc (Liam)
- Brainstorm → plan → làm → polish, đợi Liam duyệt giữa các bước. Có chỗ chưa rõ → hỏi.
- **Mọi việc xong phải cho một agent cao cấp KHÁC người làm audit/review** trước khi báo Liam.
- Thiết kế do agent làm chính (`game-designer`, `economy-designer`, `systems-designer`), Liam review.
- Không chạy nhiều agent song song nếu Liam chưa cho; thực tế đang giữ tối đa 2 cùng lúc.
- **Không mở/sửa `~/Downloads/MyGame` (Axie Infinity: A New Empire) và `~/Downloads/axie-asset-sources/`.**
- Gọi là "Nhiệm vụ", không gọi "hợp đồng".

## Tầm nhìn & hướng sản phẩm (đã chốt)
- Axie Dice thành game thật (không còn prototype Vibeathon). Nền tảng **Windows + macOS trước**, web giữ song song, mobile sau.
- Màn chính là **Land 3D** sống (Axie đi lại), các nhà là lối vào. Land là tài sản free, 6 tier Savannah < Forest <
  Arctic < Mystic < Genesis < LunaLanding, nâng bằng **Land Stone** (40k/100k/180k/500k/1M). Land KHÔNG cho sức mạnh combat.
- Combat giữ nguyên chiều sâu, chỉ bổ sung; không trait khắc chế; hồi đầy HP mỗi trận. Quái chuyển sang **Atia 3D**.
- **Hướng mới 11/10:** tạo ức chế TRONG RUN (quái/boss thật khó) rồi bán giải pháp (tiện lợi + sức mạnh trong run)
  bằng **tiền thật**, dùng được cả ranked. **Server tung xúc xắc ở mọi chế độ** (online-only). Nhiệm vụ KHÔNG gắn
  monetization — chỉ khó, là bài test risk-to-earn của Liam. Đã nêu rủi ro pháp lý (cược tiền có giá trị) → hỏi pháp lý Sky Mavis.

## Thiết kế — trạng thái từng file (`design/proposals/`, mỗi file mở đầu bằng khối quyết định của Liam)
| File | Trạng thái |
|---|---|
| `core-loop-v2.md` | Đã review; quyết định ở đầu file ghi đè thân file |
| `economy-v2.md` | **Chốt**: 2 tiền (Gene Shard, Land Stone), vé 200 Shard ×1,05/ngày cap 30, mỗi lượt Echo Box 1 phần thưởng, jackpot 0,02%/0,03%, heavy ~1 năm tới Luna (regular/casual chậm hơn — Liam chấp nhận). R ≈ 450 Shard/run (đo: `godot/prototypes/economy_probe/`) |
| `echobox-pass-v2.md` | **Chốt**, đồng bộ với economy: hộp thường (pool lớn, pity) + hộp mùa (kiểu Dota "Trove of Terror", 5 vé/lượt, đủ bộ ≤80 lượt, 12 tuần); Pass kiểu LoL ≥14 ngày, có 5 unlock chỉ số |
| `relic-audit-research.md`, `relic-set-v2.md`, `relic-set-v2-review.md` | **Bộ relic KHOÁ về thiết kế** (133 relic, 8+3 ô, trần nhân G ×2,5/Axie mặt dmg, 9 pact, 8 hook mới); số chốt sau sim |
| `ascension-v2.md` | Liam trả lời đủ; A1–A10 luật cố định; mốc enrage chốt sau sim |
| `nhiem-vu-risk-to-earn.md` | Bản 7 bậc đã viết; Liam yêu cầu **viết lại CỰC KHÓ** (chưa làm), nhà Nhiệm vụ nâng bằng Shard + Stone, bậc khó nhất dùng Full mode, server tung xúc xắc |
| `monetization-v1.md` (+ `-review.md`) | Đã định giá (Lunar Gem, 10 Aid, trần 8/run); creative-director: APPROVE WITH CHANGES, 3 BLOCKER → chờ Liam (pending B) |
| `design/registry/entities.yaml` | Đã đăng ký 18 mục economy |

Kiến trúc: `docs/architecture/server-authoritative-rng.md` (B2) + `-review.md` (lead-programmer) + `-security-review.md`
— **3 file chỉ có trên máy (docs/ bị gitignore)**. Chờ Liam (pending C).

Request cho Claude Design: `design/requests/cosmetics-art-request-01.md` (55 món), `design/requests/ascension-ui-request-01.md`.

## Art Cosmetics 01 (Claude Design, nhận 11/10)
- Nguồn + REVIEW: `design/handoffs/cosmetics-01/`. Đã xuất 20 die plate PNG 512 (mipmap bật) → `godot/assets/cosmetics/dice/`,
  5/21 khung → `godot/assets/cosmetics/frames/`, manifest `godot/assets/cosmetics/cosmetics_manifest.json` (spec 14 FX).
- SVG plate dùng filter → phải rasterize bằng Chrome headless (cách làm trong README của handoff).
- art-director: skin ACCEPT WITH FIXES, khung REJECT (cần vẽ 19), FX ACCEPT WITH FIXES. Chờ Liam (pending A).

## Đã làm (code) — đều đã commit + push trừ khi ghi khác
- Test không còn làm bẩn save thật; `run_tests.sh` FAIL test nào đổi save. Suite **56/56**. Worker **27/27**.
- Worker: rate limit sign-in/save, sửa typo /terms /privacy — đã deploy (version b73672cd).
- Prototypes: `godot/prototypes/land_spike/` (Land 3D khả thi; M3 Pro: 20 Axie ~200 FPS, 50 ~76; Compatibility chậm ~10×),
  `godot/prototypes/economy_probe/`. Công cụ `godot/tools/import_homeland.py`.
- Asset 3D: `asset-library/godot-ready/` (bản chép Godot-ready, 951 scene) + `asset-library/design-library/` — local, gitignore.

## Việc lớn còn lại (thứ tự)
1. Liam trả lời `pending-decisions.md` → sửa kiến trúc + monetization theo review, gửi Claude Design sửa cosmetics.
2. Viết lại Nhiệm vụ bản cực khó (+ review).
3. Viết lại kế hoạch phase toàn dự án (Land, combat batch gom một lần bump `RULES_VERSION`: relic hooks + Ascension +
   Aid + epoch seed, quái Atia 3D, server RNG P0–P5, store).
4. Bắt đầu triển khai theo phase.

## Bẫy
- Lỗi parse GDScript làm Godot treo; Mac không có `timeout` → background + `( sleep N; kill $p )`.
- `godot/tools/record_sample_run.tscn` và `verify_run.tscn` CHƯA có SaveGuard — ghi đè save thật. Sao lưu
  `~/Library/Application Support/Godot/app_userdata/Axie Dice (Godot port)/` trước khi chạy bất cứ thứ gì.
- Chụp màn hình phải chạy KHÔNG `--headless`. Mọi ghi save qua `SaveStore`; field meta mới → sửa `MetaState.reload_from_store()`.
- Worker test: `cd worker && node --test test/*.test.mjs` (Node 24 không nhận `test/`).
- zsh không tách biến chứa tham số: dùng `${=var}`.
- Server tĩnh xem bản giao Claude Design: cấu hình `cosmetics-01` trong `.claude/launch.json` (cổng 8766).

---
**Session mới: đọc mục "⇢ BẮT ĐẦU TỪ ĐÂY" ở đầu file này, rồi mở `production/session-state/pending-decisions.md` (23 câu chờ Liam).**
