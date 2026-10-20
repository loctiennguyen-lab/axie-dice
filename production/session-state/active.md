# Axie Dice — trạng thái hiện tại

## ⇢ BẮT ĐẦU TỪ ĐÂY (chốt trưa 20/10/2026) — SESSION MỚI = GAME DESIGN

**Git:** godot-port = axiedice/main = **a6b7ba3**, suite **125/125**. Bản test Liam: `build/AxieDice-0.1.0-L1-b1049-a6b7ba3-macos.dmg`
+ `-windows.zip` (b945 → `build/old/`). Không có agent/Godot nào đang chạy.

**Đã xong 20/10 (không làm lại):** merge U/E/M/C/V/K/L/S/A — màn giới thiệu boss; hộp mùa + 3 danh hiệu; test/with_lock luôn
dùng user dir cô lập (cây chính an toàn khi Liam chơi) + chặn override.cfg lọt vào build; bỏ Dango; preload map; **6 boss Chimera**
(agony Venom, mecha Tempest, mirror Feral, plague_mother Parasite = mesh team Art, gooey_king Brine, frost_lord Brine xanh-tím);
boss nhìn về party hé ~12° (t_boss_facing); quái gọi ra 0.7 (t_boss_resume_summons); chữ đe doạ boss mới; số phase thật.
Blender đang mở scene `Chimera_Review` (6 Chimera + script `chimera_clip.py` đổi clip).

**TẠM DỪNG theo Liam (20/10 trưa).** Đã làm thêm sau mốc trên: Blight BỎ khỏi dự án (Liam; code không còn tham chiếu; còn 2 ảnh
nền + thư mục rỗng trong asset-library chờ Liam tự xoá vì lệnh rm bị chặn quyền); prompt Claude Design art Epic hộp thường =
`design/handoffs/cosmetics-3d/PROMPT-EPIC-ECHOBOX.md` (Liam duyệt Deep Reef, 12 món) → khi có art: thêm id vào `art_map` epic
trong `godot/assets/data/economy/echobox.json`, bỏ 2 hình Founder khỏi đó. Dọn: còn worktree B (suite) + R (`l1/R` tại a24133d,
CHƯA có commit nào — việc "Brine to hơn bằng cách dời cổng/party khi boss rộng" đã dừng giữa chừng, làm lại từ đầu: Liam duyệt
cho dời cổng/party). Nhánh còn: l1/B-hooks, sim/quick-1012, claude/happy-herschel; nhánh script/* đã xoá (brine cbbac48,
feral 20e6a15, parasite 069dcc0). Thư mục save test cũ AxieDice-wt-* ngoài B/R chờ Liam tự xoá.

**Việc nhỏ còn treo (không chặn game design):**
1. Liam chơi b1049, duyệt Chimera trong game → rồi **deploy web** theo `production/release/web-deploy-2026-10-19.md`
   (HỎI Liam trước khi upload R2; Worker không cần deploy).
2. Brine fit 5.3 (to hơn phải dời cổng/party); Tempest nhìn party nên thấy cánh từ cạnh; vỏ kiếm Parasite: UV FBX không khớp
   texture team Art gửi → đang chiếu lại vùng texture (nhờ team Art sửa UV nếu muốn đúng gốc). Blight Chimera chờ team Art.
3. Art Epic thật cho hộp thường (đang mượn hình Founder); phím B/S ở Run setup chưa vào tab Controls.
4. Dọn worktree cũ (A,C,E,K,L,M,S,U,V,SIM; nhánh script/* giữ tham khảo bản Chimera dựng tay).

**PHASE TIẾP: làm lại game design cho sâu hơn** (Liam: mechanics hay nhưng chưa đủ sâu). Quy trình: brainstorm → plan → Liam
duyệt → làm (CLAUDE.md). Đầu vào: `production/backlog-after-b931.md` mục B + C (Vault trống ô = mặt dice BLANK → thiết kế lại
cách part sinh mặt; chiều sâu xây đội part/bloodline/synergy; lựa chọn trong trận; cơ chế quái/boss; quyết định trên map;
tiến triển dài hạn Land/Ascension/Nhiệm vụ; Nhiệm vụ cực khó; kế hoạch phase toàn dự án; sim cân bằng). Mọi thay đổi luật gom
MỘT lần bump `RULES_VERSION` (+ comment "Mythic" bậc 4 cũ, Result Ranked/mất cọc) và deploy Worker (hỏi Liam).
Doc: `design/gdd/systems-index.md`, `build-spec.md` (INV-1..7), `economy-progression.md`, `godot-port-rule-spec.md`.
Agent gợi ý: `game-designer` + `creative-director` (/brainstorm), rồi `systems-designer`, `economy-designer`.

## ⇢ BẮT ĐẦU TỪ ĐÂY (cập nhật sáng 20/10/2026 ~10:20, session "Session state active file")

**Cập nhật 11:30:** Parasite giờ dùng MESH TEAM ART Liam gửi (FBX + texture ở `asset-library/chimera-src/Parasite (Bug)/3D/Bug_01/`),
đúng nguyên bản (HAIR_SCALE 1.0); chỉ vỏ kiếm được chiếu lại vùng texture vì UV FBX không khớp texture gửi.
axiedice/main = **a6b7ba3** (suite 125/125). Team Art có mesh con nào khác → thay theo cùng cách (build_venom/build_parasite).

**5 Chimera boss đã vào game (merge d298ac4, đã push; mốc mới 125):**
agony = Venom (art team mesh, VenomPool `cover`), mecha = Tempest, mirror = Feral, plague_mother = Parasite,
gooey_king = Brine (màu tranh), frost_lord = Brine bản màu chính thức xanh dương-tím. 4 con sau = mesh AI Liam tạo bằng
Meshy/Tripo (`asset-library/chimera-src/<tên>/3D/*_ai.glb`), dọn + rig + 6 clip bằng Blender CLI
(`tools/art/chimera/build_<tên>.py`). Dựng tay bằng Blender script = Liam chê xấu, đã bỏ (nhánh script/* giữ tham khảo).
**Luật Liam:** boss LUÔN nhìn về phía party, hé ~12° về camera (facing_deg 7; test `t_boss_facing` ≤15° + phía camera);
intro có `intro_facing_deg` riêng. Quái do boss gọi ra vẽ SUMMON_SCALE 0.7 (cả khi resume), boss rộng có cột quái gọi ra
bên phía party (`WIDE_*` trong CombatStage3D, chỉnh khít theo `t_combat_spacing`, lề ~1 px). `fit_width_m`, `hover_m`
(Tempest bay), chip trạng thái theo đỉnh model. Mỏ Parasite: thẳng về TRƯỚC (tranh nghiêng `Bug_1.png` cột 3), tay tách áo.
**Còn lại:** Liam duyệt ảnh 5 Chimera trong game → push → export web + HỎI Liam trước khi upload R2 → build desktop.
Brine fit 5.3 (to hơn cần dời cổng/party — Liam quyết). Tempest nhìn party thì thấy cánh từ cạnh (hệ quả luật).
Meshy MCP đã cài (user scope, key trong Keychain `meshy-api-key`, cần gói Pro).

## (cũ hơn) ⇢ BẮT ĐẦU TỪ ĐÂY (cập nhật đêm 20/10/2026, session "Session state active file")

**Git:** godot-port = axiedice/main **a9486d4** đã push (suite 123/123 ở worktree B). Sau đó merge chưa push: 0ed00cc (E: xác nhận hộp mùa
mỗi phiên) + 2acedd5 (U: dòng đe doạ boss + số phase thật) — suite 2acedd5 **123/123**. Mốc test: **123**.
**Đã merge hôm nay:** U (màn giới thiệu boss, nền lossy), E (hộp mùa + fingerprint 4871eef, giữ -n), M (user dir cô lập cho test,
không lọt override.cfg vào build: exclude + guard + quét pck sau export; shot.sh qua with_lock; bỏ Dango; sửa watcher import để lại
`sleep 240` mồ côi). `export-web.sh` (cây chính, gitignored) có guard override tạm.
**Cây chính giờ an toàn khi Liam chơi**: test/with_lock dùng user dir AxieDice-test-my-game (sau merge M).
**Liam trả lời 7 câu** (đầu `pending-decisions.md`). Chữ intro: giữ tiêu đề cũ, dùng dòng đe doạ mới.

**Đang chạy lúc ghi (kiểm git từng worktree nếu session chết):**
- Làn V `l1/V` 8b249aa: VenomPool che chỗ cắt hông Venom (intro + trận). Đang review → merge.
- Làn U `l1/U` 7470131: HUD boss "Phase X of Y" chỉ hiện khi > 1 phase. Đang review → merge.
- 4 Chimera dựng tay bằng Blender CLI (Liam: không có AI 3D; Brine dùng cho CẢ gooey_king + frost_lord, mỗi con 1 bộ màu):
  A = Brine (gooey_king, frost_lord), K = Tempest (mecha), L = Feral (mirror), S = Parasite (plague_mother). Brief chung:
  scratchpad `chimera-brief.md` (nội dung: build_<name>.py headless, 6 clip Idle/Attack/Hit/Dead/Cast/Roar, ≤3 MB, ≤25k tris,
  gắn qua `godot/assets/atia/atia_models.json`, ảnh intro + trận 1920/1280, suite).
**CẬP NHẬT (Liam, đêm 20/10): DỪNG làm Chimera bằng Blender script ("xấu quá").** 4 agent đã dừng, KHÔNG merge. Commit dở còn
trên l1/A 3b5857e (Brine), l1/S 8c81f1e (Parasite), l1/K, l1/L — chỉ để tham khảo rig/anim. Liam không muốn trả phí AI 3D.
Hướng tiếp (chờ Liam): xin mesh từ team Art như Venom, hoặc thử TRELLIS.2 (Microsoft, MIT, free trên HF Spaces) → GLB bỏ vào
`asset-library/chimera-src/<tên>/3D/`, rồi rig/anim theo pipeline Venom. Hunyuan 3D free nhưng giấy phép loại EU/UK/KR.
Làn V (VenomPool, field `cover` trong atia_models.json) + U (HUD phase) đã merge: d98bdd9. Deploy web với bản này.
**(cũ) Sau đó:** review từng con → merge (atia_models.json mỗi làn sửa 1 key, có thể conflict nhẹ) → suite ở B → push →
export web theo `production/release/web-deploy-2026-10-19.md` → **hỏi Liam trước khi upload R2** → build desktop mới.
Liam: "làm hết rồi deploy 1 thể".

## ⇢ BẮT ĐẦU TỪ ĐÂY (bàn giao 20/10/2026, session "Build b831 review và fixes")

**Trạng thái git:** cây chính `godot-port` = **ca8bed3**; `axiedice/main` = **ca26343** (merge Venom, suite 122/122 ở worktree B). Chưa push: chỉ merge làn C (preload map, ca8bed3) — chạy suite cho ca8bed3 ở worktree B rồi push:
`git -C ../my-game-wt/B checkout --detach godot-port && cd ../my-game-wt/B && AXIE_HANG_KILL=900 godot/tools/with_lock.sh $GODOT --headless --path godot --import && AXIE_HANG_KILL=500 bash godot/tools/run_tests.sh` → xanh thì `git push axiedice godot-port:main`.
**Bản build Liam đang chơi:** b945 (40e33c7). **Mốc test:** 122/122 ở 40e33c7 (+ t_arena_preload sau merge C).

**LUẬT MỚI (Liam 19–20/10):**
- KHÔNG chạy suite/Godot ở cây chính khi Liam chơi (chung user dir "Axie Dice"); merge ở cây chính, chạy suite ở worktree B/R detached. (Làn M đã làm cách cô lập hẳn, đang chờ review → khi merge xong thì cây chính cũng an toàn.)
- Không giới hạn số agent, tự chọn đúng chuyên gia; mỗi làn một vùng file; review + suite trước merge.
- CHỐNG TREO tuyệt đối: AXIE_HANG_KILL (120 test lẻ / 500 suite / 900 import-export), không vòng until/while; bật bộ canh treo (Monitor, `ps -axww`) khi có agent chạy, bật lại mỗi 30 phút. Luật chung cho agent: `production/agent-lane-rules.md` (trỏ agent tới file này).
- Art/UI coi như XONG (Liam). Phase sau: làm lại game design (session sau, brainstorm trước).

**Làn đang dở lúc bàn giao (agent chết theo session cũ — kiểm git rồi giao agent mới làm tiếp):**
1. **Làn M** `l1/M` fe75f6a (worktree M): 1c56816 test luôn dùng user dir riêng (temp override.cfg khi giữ lock) + fe75f6a xoá Dango (bỏ `[gui] theme/custom` khỏi project.godot). **Review = FIX FIRST, KHÔNG merge trước khi sửa:** (a) RỦI RO LỌT override.cfg VÀO BẢN EXPORT (build_desktop.sh chạy export qua with_lock → temp override.cfg có mặt lúc export; export-web.sh không khoá) → thêm `override.cfg` vào cả 3 `exclude_filter` trong `godot/export_presets.cfg` + guard trong `tools/build_desktop.sh` và `export-web.sh` dừng nếu `godot/override.cfg` có dấu `axie-temp-override`; kiểm lại bằng cách export rồi tìm override.cfg trong pck. (b) `with_lock_test.sh` dòng ~137/149: thay `sleep 1.5` bằng poll có giới hạn ~10 s. (c) Chụp 1280 Combat, Tutorial, Store, Leaderboard xem có mất theme không (InfoLabel/InfoPanel/log trong Combat.tscn, TutorialView, TutorialCoach dựa project theme). Sau đó merge + cập nhật FINGERPRINT nếu cần. (Bản b945 build TRƯỚC thay đổi này nên không bị ảnh hưởng.)
2. **Làn E** `l1/E` **6f5803c** (worktree E, XONG, suite 122/122 có skip fingerprint): 4488ffd tên M6 "Sturdy foes"/M7 "Fierce elites"; e487236 balance `production/qa/season-box-balance-2026-10-19.md` (không vỡ INV-1..7; full set trung bình 57,7 lượt ≈ 289 vé, tối đa 400; vé free cả mùa chỉ ~55–60 → hoàn thành set cần Gem/Nhiệm vụ — CÂU HỎI DESIGN cho Liam); 2302828 bật hộp mùa + tách pool (die_m_moon cũng bỏ khỏi hộp thường) + 3 danh hiệu ECHO WALKER / MOONBOUND / LUNAR ECHO MASTER (`title:<NAME>`); 6f5803c tab Seasonal + t_season_box. **Cần Liam:** bậc Epic hộp thường giờ chỉ còn Founder Seal/Laurel làm hình tạm (vốn là đồ Pass) → cần art Epic thật; tên 3 danh hiệu. Worker chưa có endpoint roll hộp (hộp thường cũng roll client). Việc tiếp: review → merge → tính lại FINGERPRINT (echo_box.gd, echobox.json; kết quả run KHÔNG đổi).
3. **Làn U** `l1/U` **5734b87** (worktree U, sạch; 9842203 hình nền + BossIntroData, 22dc39d màn BossIntro + phím boss_intro_skip + nối từ node boss, 5734b87 t_boss_intro; CHƯA chụp ảnh, CHƯA chạy suite đủ, CHƯA review — agent bị dừng khi bàn giao): **màn giới thiệu boss** — spec `design/ux/screens/52-boss-intro/spec.md` NHƯNG theo quyết định Liam: luôn bản đầy đủ; model 3D boss đứng trước hình nền TRƠN `asset-library/chimera-src/Backgrounds/Chimera_BG_<Name>.png`, animation mạnh (đẩy camera, Roar, chớp sáng tôn trọng Reduce flashing, bảng tên); 5 Chimera (Blight để sau); boss chưa có model Chimera thì dùng model hiện tại + nền cùng hệ; phím skip là action KeyBindings mới; resume bỏ intro.
4. **Boss Chimera:** Venom xong (godot/assets/bosses/chimera_venom/, pipeline `tools/art/chimera/build_venom.py`, gắn boss `agony`). **Chờ Liam duyệt Venom** (ảnh `production/qa/evidence/chimera/`) → dựng Brine (Aqua) bằng Blender theo tranh `asset-library/chimera-src/Brine (Aqua)/` → duyệt → Feral, Parasite, Tempest. Liam: Chimera THAY CẢ 3 boss trong run (chia slot sau khi đủ model). Venom hơi mảnh trong trận (cỡ do `_fit_atia_model`); Cast/Roar chưa dùng trong trận (Roar hợp đổi phase). 4 biến thể Venom 02–05 ở scratchpad cũ, chưa commit.
5. **Deploy web** (Liam duyệt, chấp nhận ~253 MB): sau khi M/E/U merge → làm theo `production/release/web-deploy-2026-10-19.md` (dọn `web/_pckparts`, `.DS_Store` trước khi `deploy-r2.sh`). Worker KHÔNG cần deploy (code không đổi từ 16/10, 184/184). Xoá `../my-game-wt/R/build/web-stage` (~250 MB, agent bị chặn quyền xoá — hỏi Liam).
6. Sau cùng: build bản Mac/Win mới (`bash tools/build_desktop.sh`), dời bản cũ vào `build/old/`.

**Còn trong backlog (đã duyệt):** `production/backlog-after-b931.md` — B gom bump RULES_VERSION với game design; C game design (session sau; Vault "trống ô" = mặt dice BLANK → thiết kế lại cách part sinh mặt); token Worker để sau L1. Phím B/S ở Run setup chưa vào tab Controls.


Cập nhật: 2026-10-12. Nhánh `godot-port`, push lên `axiedice` (`git push axiedice godot-port:main`).

## ⇢ BẮT ĐẦU TỪ ĐÂY (tối 18/10/2026, Liam review b831)

Liam chơi b831, gửi 11 mục. Đã điều tra (chưa sửa code), đang chờ Liam trả lời câu hỏi rồi mới làm:
1. Reroll vẫn là khay 2D cũ (`reroll_fx.gd`), chỉ lượt tung đầu dùng `DiceRoller3D` → chuyển reroll sang 3D (M).
2. Bố cục trận: spec round 2 đặt Axie trái, quái phải; game vẫn dọc (`CombatStage3D.gd` :325, `CombatArena3D.gd` theo trục z) → xoay sang ngang, cổng sau quái, chạy ngang qua cổng (L).
3. Bấm phím tắt văng game: SIGSEGV thật (`~/Library/Logs/DiagnosticReports/Axie Dice-2026-10-18-*.ips`), chưa tái hiện, đang hỏi Liam màn nào/phím nào. Lỗi phụ: `UnitPortrait.gd` connect `gui_input` 2 lần (:411/:443).
4. Land: bỏ biển tên + badge, kéo nhà vào giữa (`BUILDINGS` Land.gd:48), cây không lòi ra ngoài (`_build_props` :585).
5. Prompt cosmetics 3D: `design/handoffs/ui-03-redesign/PROMPT-COSMETICS-3D.md` (art-director đã review) → Liam gửi Claude Design.
6. Cho trùng Axie free trong party, Vault mỗi con 1 lần (RunSetup.gd:208/225/792/1394, `team_presets.gd` là file luật → bump).
7. Echo Box thẻ Stone dùng ảnh `UI3.icon("cur_stone")` (EchoBoxScreen.gd:623).
8. Khung avatar lệch: `AvatarFrame.wrap` (Land.gd:1118), chưa rõ gốc, cần chụp.
9. Continue run không phản hồi: nghi `RunContinue.busy` chờ reconnect, không báo gì (Land.gd:1461).
10. Hiệu ứng (SHD/POI/THN) thành icon trên đầu unit, bỏ chữ trong bảng quái; chip "THN 2" đang trôi lơ lửng.
11. Run map: ô đã qua hiện ổ khoá (RunMapController.gd:410 `passed` → locked); nhấn 2 lần vào ô = đi luôn.

**Cập nhật 19/10 23:10:** godot-port = axiedice/main **40e33c7**. Suite **122/122** (worktree R). Bản test: `build/AxieDice-0.1.0-L1-b945-40e33c7-macos.dmg` + `-windows.zip`.
Từ b931: run map nền tím (reptile class art), "Enemy turn" không tràn, tab Settings > Controls đổi phím (KeyBindings, MetaState.key_bindings — fingerprint đã cập nhật, giữ -n), bỏ chữ P/L/C, Claim Gem (Daily + Store) chờ server, Vault thẻ gọn + ô Import, decor nửa sau Land (NFT_Item, +8 MB), cosmetics round 4 (viền mặt dice bo tròn, khung hết cắt mép). Art/UI XONG (Liam).
**Việc tiếp theo:** Liam duyệt `production/backlog-after-b931.md`, xác nhận Vault "trống nhiều ô" = mặt dice BLANK, rồi phase làm lại game design (brainstorm trước).

**Cập nhật 19/10 18:15:** godot-port = axiedice/main **4593e6b**. Suite **119/119** (chạy ở worktree R vì Liam chơi trên save thật — KHÔNG chạy suite ở cây chính khi Liam đang chơi). Bản test: `build/AxieDice-0.1.0-L1-b931-4593e6b-macos.dmg` + `-windows.zip` (b896 vào `build/old/`).
Từ b896: số N trên mặt dice (WEAKEN 3), battle log sang trái, cosmetics round 3, đội hình quái giữa trục cổng (2–3 con gần nhau, add 5+ hàng sau), Arctic bớt chói, 6 map trận mới làm bằng Blender (arena v2, `godot/assets/atia/arena_v2/`, pipeline `tools/art/arena_v2/`), xúc xắc rơi lưới gọn giữa 2 bên + không đè nhau + to thêm 15%, Land bớt cây (vài cụm, không chìm).
Còn: frame_m_eclipse vẫn bị cắt mép trên (cần Claude Design sửa); arena v2 tải đồng bộ lần đầu mỗi biome (web có thể giật, nên preload); kiểm dung lượng bản web (+15 MB map); Land tier 1 khá thưa (Liam xem).

**Cập nhật 19/10 14:00:** godot-port = axiedice/main **377135e**. Suite cây chính **116/116**. Bản cho Liam test: `build/AxieDice-0.1.0-L1-b896-377135e-macos.dmg` + `-windows.zip` (b831 đã vào `build/old/`).
Đã merge 19/10: làn U (icon enrage, hiệu ứng skill đầu trận nhỏ trên caster), làn K (cosmetics 3D round 2: skin xúc xắc 3D, trims, khung ×1.5, Profile, Echo Box, Store, icon Stone/Ticket/Fragment, 41 tên Liam duyệt), làn C (giãn khoảng cách trận, quái theo chiều cao Axie, boss 2.6×, cổng trên đường tiến sau quái + ngoài cột bảng quái, xúc xắc rơi giữa màn hình).
Còn: prompt cosmetics round 3 (`design/handoffs/cosmetics-3d/PROMPT-ROUND-3.md`, 6 mục) chờ Liam gửi; ô thưởng Pass chưa theo tile 48; web size_limit 256 cho skin khi build web; theo dõi 11 xúc xắc có đè nhau lúc dừng không; cổng hơi nhỏ so với boss, Thornback hơi bé.

**Cập nhật cuối tối 18/10:** đã merge vào godot-port (CHƯA push, chưa build): làn M (e90646a: trùng Axie free, Stone Echo Box, run map),
fingerprint f7ec3ca (kết quả run KHÔNG đổi, giữ -n, không cần deploy Worker), làn U (5a7585f: reroll 3D, icon hiệu ứng trên đầu),
làn L (crash phím tắt Land + 23 màn, Continue, bỏ biển tên, nhà vào giữa, cây trong land, khung avatar), làn C (bố cục trận ngang 3/4).
Suite cây chính **113/113**. Việc sau của làn C (review gợi ý, không chặn): quái sát nhau khi 3 con (ENEMY_CENTER_X), xúc xắc rơi
chạm quái, cache pad texture quái; chưa chụp 4–5 quái / boss+summon / 4 Egg. Thiếu art icon enrage. Hiệu ứng skill đầu trận (đốm sáng to) cần xem.
Cosmetics: Claude Design trả round 1 → `design/handoffs/cosmetics-3d/round-1/_zip/`. Prompt round 2 (chờ Liam chốt 3 câu ở đầu file rồi gửi):
`design/handoffs/cosmetics-3d/PROMPT-ROUND-2.md`. Việc tiếp: Liam test bản build mới (cần build lại từ godot-port), push khi Liam bảo.

## (cũ) ⇢ BẮT ĐẦU TỪ ĐÂY (cập nhật 18/10/2026)

**Đang làm: port UI-03 (Claude Design, A4 Blend trên Terrariums) vào game.** Kế hoạch làn: `production/ui3-port-plan.md`.
Bản giao round 1: `design/handoffs/ui-03-redesign/round-1/handoff/`. Màn chưa có mockup: `round-1/GAP-LIST.md`. Prompt round 2 đã
gửi Liam: `design/handoffs/ui-03-redesign/PROMPT-ROUND-2.md`. Quyết định Liam 18/10 ở cuối `pending-decisions.md`
(cả 25 màn, xúc xắc 3D vật lý làm luôn, giữ bắt đăng nhập, font Rowdies + Work Sans).

**Đã merge 18/10:** xúc xắc 3D (`DiceRoller3D.gd`, mô hình Blender `godot/assets/dice/axie_die.glb`, nguồn `tools/art/dice/axie_die.blend`)
và nền UI-03 (`godot/scenes/shared/ui3/UI3Theme.gd`, `UI3.gd`, `tokens_ui3.json`, font). Suite cây chính **104/104**.

**UI-03 đã port HẾT các màn trong bản giao round 1 + 2 (axiedice/main 3f014fe, suite 110/110 không SKIP).** Thêm 19 Store,
25 Vault (Use in team → Run setup), 29 codex/guides/unlocks, AccountUI, 43 tooltips, 45 victory march, 30/39/42 combat, MainMenu
chỉ còn chuyển hướng, TeamSelect + R3Shell đã xoá, `godot/CLAUDE.md` viết lại cho UI3. Live smoke `--full` PASS trên production (18/10).
**Bản cho Liam test:** `build/AxieDice-0.1.0-L1-b831-3f014fe-macos.dmg` + `-windows.zip` (cũ ở `build/old/`). Sau b831 đã merge thêm (4842dfe, chưa build): Vault preview 260, Scan, chip tài khoản UI3, Codex cột 920 + nhãn token, menu in-run thẳng hàng.
**Còn sau:** xoá hẳn DangoTheme/DangoScreen/dango.tres (còn `gen_theme.gd`, test `t_button_states`/`t_ui_laws`/`t_mockup_assets`, vài
dòng lẻ); trạng thái gửi điểm Ranked trên Result + câu "mất cọc" đúng theo hoàn cọc → gom vào lần bump RULES_VERSION.
**Chờ Liam:** tên M6/M7, duyệt chữ Claude Design tự viết (nhãn tóm tắt Defeat, câu lỗi…), test bản build mới.
Mỗi màn: review code + art-director xem ảnh 2 cỡ → merge đúng commit → --import → suite cây chính → push.

## (cũ 16/10) ⇢ BẮT ĐẦU TỪ ĐÂY (bàn giao 16/10/2026 03:10)

**Đọc `production/l1-plan-16-10.md`** (định nghĩa "xong", thứ tự việc, quy tắc chống treo + tiết kiệm token).
godot-port = axiedice/main. Suite cây chính **102/102**. Worker **184/184**, deploy **4055be9c** (16/10, migration 0007 đã áp),
RULES_VERSION `-n`. Live smoke PASS trên production với code mới nhất.
Bản Mac cho Liam test sáng 17/10 (L2): `build/AxieDice-0.1.0-L1-b615-bbfc8fb-macos.dmg` (ổ "Axie Dice L1" đang gắn).

**Xong sáng 16/10 (session sau bàn giao):**
1. Build Windows: `build/AxieDice-0.1.0-L1-b616-9574922-windows.zip` (9574922 chỉ thêm doc so với bbfc8fb). Bản Win cũ b556 đã ở `build/old/`.
2. Polish plan v2 (`production/polish/polish-plan-draft.md`, 4fe15e4): ux-designer review → art-director sửa (vạch freeze sau Batch 2,
   Reward/Shop/Event vào Batch 2, mỗi mục có cách kiểm, còn 3 câu hỏi). Chờ Liam duyệt.
3. Làn U 3 việc (a95d2dc, 6a631e6, c8d8d18) → lead-programmer review MERGE → merge c88c997, suite cây chính 102/102 không SKIP,
   push. Live smoke `--full` PASS trên production (R ở c88c997). Còn nhỏ: test _atia_play chưa kiểm die/RESET/không connect 2 lần.
   b615 KHÔNG có 3 sửa này (build sau sẽ có).
4. Web gọn đã export: `web/index.pck` 205 MB (từ a100cf6 = code bbfc8fb). CHƯA deploy R2.

**Chờ Liam:** L2 test b615 (chơi run thường + Nhiệm vụ N1 + tắt wifi giữa trận + thoát rồi Continue); L3 đăng nhập trên Windows;
duyệt kế hoạch Polish. Quyết định Liam 16/10 ở cuối `pending-decisions.md` (L1 A đã làm, L4 bỏ, L5 vào Polish, L6 đã làm, L7 web-only đã làm).

## (cũ) ⇢ BẮT ĐẦU TỪ ĐÂY (cập nhật 14/10/2026)

**godot-port = axiedice/main (4ed21e7).** Suite cây chính **96/96 không SKIP**, Worker **163/163**. RULES_VERSION **`godot-2026-10-13-m`**.
Checklist: `production/l1-checklist.md`. Quyết định Liam 14/10: cuối `pending-decisions.md`.

**Xong 14/10 (đều review + suite cây chính):** C (bỏ FrontLine), C7 danh hiệu, C8 thưởng tuần Daily, C4 test, C5 polish Land v5,
C2 Daily + Ranked + leaderboard (Worker migration 0006), B11 R5 đổi thẻ pact (-m; R4 chờ ví chung LIAM-2), C6 Team presets + Leaderboard + Land upgrade (mở L1, giá gốc), C9 polish (cả 5 việc + MultiMesh lối đi).

**CHỜ LIAM DEPLOY Worker** (C2 + B11): `git pull axiedice main` → `cd worker && node --test test/*.test.mjs` →
`npx wrangler d1 migrations apply axie-dice-db --remote` (chỉ 0006) → `npx wrangler deploy`. Build game mới cũng cần (client gửi -m).

**Việc kế tiếp:** C6 còn Profile/Account, Cosmetics; đo FPS web (lối đi sân + Land) ở B8; B1 cuối + B3 (cần Liam), B7/B8 build.

**Bẫy hôm nay:** lỗi parse / thiếu `--import` sau rebase / dấu CONFLICT còn trong file → Godot TREO (luôn kill timer); test xanh ở
worktree nhưng đỏ ở cây chính vì save thật của Liam (không còn newcomer) → test phải tự đặt trạng thái; agent con hay chạm giới hạn
20 lượt → bảo commit từng bước nhỏ; vòng `until ! pgrep run_tests` không bao giờ thoát.

## (cũ) ⇢ BẮT ĐẦU TỪ ĐÂY (bàn giao chiều 13/10/2026 — session mới đọc mục này trước)

**Việc đầu tiên: mở `production/l1-checklist.md`** (checklist L1, ô `[ ]` = còn làm). Quyết định của Liam: `production/session-state/pending-decisions.md` mục F–K + các dòng cuối file (đã chốt, không hỏi lại).

**godot-port = axiedice/main.** Suite cây chính **92/92 không SKIP**, Worker **152/152**. RULES_VERSION **`godot-2026-10-13-l`**
(Worker `SUPPORTED_RULE_VERSIONS` có tới -l). **Worker đã deploy 13/10 16:13** (gồm -l, pact_pick, telemetry, Continue miễn phí).

**Đã xong chiều 13/10 (đều qua review + suite):** B1 (điều kiện bật online), B2 (Aid/Continue trừ Gem), B3 code (màn đăng nhập),
B4 (số liệu + `worker/sql/l1_report.sql`), B5 (Nhiệm vụ N1–N3 + số bản cực khó -k), B6 (boss/elite đủ model), B9 (save cũ), B10
(Continue miễn phí người mới), B12 (cosmetics trong game), C1 (màn pact, -l), C3 (menu trong run), C5 (Land hub v5), C11 (cosmetics v8).

**Đang dở khi chuyển session (agent đã dừng cùng session cũ — kiểm tra rồi review + merge):**
- l1/L có commit chưa merge: cd2475b (Land v5: "5 runs" từ data, nút + Gem 44 px, chạm-để-xem, UI scale 0.85) — review FIX FIRST:
  `_is_touch()` chỉ dựa `is_touchscreen_available()` → laptop cảm ứng click chuột cũng 2 bước; cần chốt touch khi có
  InputEventScreenTouch thật + test HUD không đè dock ở scale 1.275. Đã có commit sửa 1cd678d (touch chỉ bật khi chạm thật + test HUD ở 1.275) — CHƯA review: cho agent khác review cd2475b..1cd678d rồi merge.
- l1/C: bỏ hẳn FrontLine (Liam chọn C) — đã có commit 20d73ee (xoá node + code, `_update_front_line` để no-op vì TutorialView còn đọc; suite worktree 91/91), CHƯA review: cho agent khác review rồi merge.
- Worktree R: file nháp `godot/tests/qa_b12_capture.*` untracked — xoá.

**Việc kế tiếp theo checklist:** B1 phần cuối (bật cờ remote trong `project.godot` [axie] + chạy trọn 1 run thật trên Worker),
B3 (Liam thử đăng nhập Google trên bản Mac/Win), B7 (build lại Mac Apple Silicon + Win), B8 (web), B11 (Aid R4/R5), C2 (Daily/Ranked),
C6 (màn R3 còn lại: Team presets, Leaderboard, Profile R3, Land upgrade), C7, C8, C9, rồi D1–D7 theo lịch.

**Bẫy quan trọng (đã cắn hôm nay):** merge commit đã review chứ không merge đầu nhánh; không `| tail -1` output merge (giấu CONFLICT);
test ở worktree xanh vẫn có thể đỏ ở cây chính vì save thật của Liam (có run_save + meta cũ) → test phải SaveGuard + tự đặt trạng thái
(newcomer, saved_run_probe); vòng chờ `until … pgrep run_tests` không bao giờ thoát nếu worktree khác đang chạy suite. Xem memory
`lane-merge-pitfalls`.

## (cũ) bàn giao sáng 13/10/2026 — sau đêm chạy liên tục)

**godot-port = axiedice/main** (đã push). Suite cây chính **85/85 không SKIP**, Worker **141/141**. RULES_VERSION
`godot-2026-10-13-i`. Mức sàn trong `.claude/docs/technical-preferences.md` đã cập nhật (file đó nằm trong .gitignore, chỉ trên máy).

**Đã merge trong đêm (mỗi lần merge đều có agent khác review + suite xanh ở cây chính):**
- A: luật Nhiệm vụ, end_run → record_run_outcome (+reached_boss), RemoteEpochSource sau cờ (mặc định local).
- B: offer v2, EN, boss miễn instant kill, 22 relic H1–H8 + 7 rework, pact live, trục G/A (trần G ×2,5), trần reroll,
  Eternal, pact_forced, **mở hết 14 relic ẩn** (không còn relic ẩn).
- C: Atia 3D, 6 sân biome (chọn theo hàng bản đồ, boss có biến thể), ánh sáng khớp Land, sửa khung/cổng.
- E: ví Gem remote, Pass v2 + việc tuần, ký quỹ cược Nhiệm vụ (nonce, an toàn khi tắt app), daily +500 Stone, hộp mùa (đang tắt).
- L: Land hub 6 tier, cổng xoay 90°, ánh sáng ấm, đất, decor dày, phím 1/3/4/daily mở màn R3, sửa lỗi khởi động.
- U: UI combat v3, AidPanel/DefeatPanel, "Elite row ahead" ở A9, số build 0.1.0-l1, chọn sân 3D.
- M (Round 3): Run Setup, Echo Box, Nhiệm vụ (cược thật qua ký quỹ), Store + Daily, Pass, Vault, Settings, Codex.
- S: RunSession, ví Gem khi đăng nhập (sau cờ), Continue boss 180, quà mùa 2×90 (bảng mùa server + điều kiện số run),
  token kid/jti + thu hồi, khoá trần quà nguyên tử, alarm hello.
- `.gitignore`: `src/` neo về gốc (trước đó giấu mesh sân và Land).

**Còn lại theo làn:**
- A: (xong, -i) header.newcomer lấy từ params. Nối màn pact gọi `RelicSlots.pact_forced`. Client gọi lại `/api/run/open` sau 1008 auth.
- B: xong bộ relic L1. Còn: sim cân bằng thật (sim F), sporegale có thể dùng `poisonSpread`.
- C: mystic/genesis chưa ai xem ảnh; chân trời boss vẫn phẳng (camera thấy ít trời).
- E: thưởng tuần Daily (4 ngày → 150 Shard + 2000 Stone) có data chưa có logic; ghép số vào bảng Aid catalog (giá Aid đang viết cứng trong CombatView).
- L: mảnh địa hình biome thật (mới có đất texture), tier 6 trời tím/đất hồng chưa chỉnh.
- M: M2 Team presets, M9 Leaderboard, M12–M14 Profile/Account/Cosmetics, M15 Land upgrade chưa làm; Vault giữ thẻ cũ (chưa lưới 5×4); hộp mùa UI (bật `enabled`).
- R: bản build Mac/Win ở `build/l1-2026-10-13/` (từ b2bd505, TRƯỚC Pass/ký quỹ/màn M sau) — build lại sau khi anh duyệt.
- S: ràng token với session (chờ anh quyết); M7 nhảy hàng chưa có spec server.

**Câu cần Liam quyết:** `production/session-state/pending-decisions.md` mục F (đã trả lời) + **G** (agent chọn tạm). Quan trọng:
G1–G6 Nhiệm vụ cực khó (doc `design/proposals/nhiem-vu-risk-to-earn.md` + review), Eternal (2 relic đầu, có tính relic khởi đầu?),
breakersward, A9 "Elite row ahead", việc tuần (XP ngoài trần ngày, mất nếu qua tuần), quà mùa 3/8 run, token không ràng session,
thu nhỏ 72 MB texture nguồn, hộp mùa (dup trả vé).
Review UI R3 để gửi Claude Design: `design/handoffs/ui-02-round3/REVIEW-art-director.md`. Sim nhanh: `production/qa/sim-quick-2026-10-12.md`.
Smoke: `production/qa/smoke-2026-10-13.md`.

**Deploy Worker: XONG (Liam, sáng 13/10)** — đã kiểm: D1 không còn migration chờ (0001–0005 đã áp), secret RUN_TOKEN_KEY có (RUN_TOKEN_KID không đặt → mặc định "k1", đúng code), `/api/gem/season_gift` trả 401 khi chưa đăng nhập (code mới đang chạy). Web R2 + build desktop: chưa làm lại.

**Các bước deploy (để tham chiếu lần sau):**
1. `cd worker && node --test test/*.test.mjs` (141/141).
2. `npx wrangler d1 migrations apply axie-dice-db --remote` — áp 0002, 0003, 0004, **0005_token_revocation** (0005 phải trước code).
3. `npx wrangler secret put RUN_TOKEN_KEY` (và `RUN_TOKEN_KID`; khi xoay khoá thêm `RUN_TOKEN_KEY_PREV`/`RUN_TOKEN_KID_PREV`).
4. Google OAuth: thêm redirect URI desktop (loopback) nếu dùng login desktop.
5. `npx wrangler deploy`. Cờ client `axie/epoch_source`, `axie/gem_wallet` vẫn "local" → người chơi chưa thấy thay đổi.
6. Web: `bash export-web.sh` (tắt editor) → `bash deploy-r2.sh`. Desktop: build lại từ godot-port mới nhất.

## (cũ, tối 12/10) bàn giao trước đêm

**Đang làm: sprint L1 — playtest nội bộ tải về, ra mắt 3/11/2026.** Kế hoạch: `production/l1-sprint-plan.md` (khối quyết định
đầu file), giao diện giữa các làn: `production/l1-interfaces.md`, bảng làn/worktree/quy tắc merge: `production/l1-lanes.md`,
nợ của làn I: `production/l1-tasks-I.md`, làn S: `production/l1-tasks-S.md`.

**Quy tắc làm việc đêm nay / sprint (Liam):** commit + push tự do (`git push axiedice godot-port:main`), duyệt theo tuần,
chạy liên tục; KHÔNG deploy (Worker/R2) khi chưa hỏi; mọi việc xong phải có agent khác review rồi mới merge.
**Dùng token cẩn thận:** đọc `production/agent-token-rules.md`, tối đa 4 agent cùng lúc, prompt gọn, agent mới cho việc mới.

**Worktree** `/Users/loc.tien.nguyen/my-game-wt/<A|B|C|E|L|M|R|S|U>` (nhánh `l1/<làn>`), mỗi cái có `godot/override.cfg`
(user dir riêng, khoá Godot riêng). Mọi lần chạy Godot qua `godot/tools/with_lock.sh`; worktree làn dùng
`AXIE_SKIP_RULES_FINGERPRINT=1`; cây chính thì không (phải xanh không SKIP). Sau rebase cần `--import` (class_name mới).
Nếu rebase bị chặn bởi `.import` untracked của echobox: xoá chúng (godot-port đã track).

**godot-port (= axiedice/main) hiện có:** ngày 0 (khoá, worktree), S (RunDO, canon, ví Gem server, login desktop),
R (build mac/win), A PR1 epoch + PR2 (hook H1–H8, Ascension v2, đồng hồ, attrition, spike, Continue, Aid R4/R6, Boon),
B relic v2 (133 relic, slots), C sổ Atia, E kinh tế + Store fixes. RULES_VERSION `godot-2026-10-12-c`. Suite 68/68 trước merge S.
**Cây chính còn sửa chưa commit:** `godot/tests/t_rules_version.gd` (FINGERPRINT sau merge S d9fbe77, không bump) +
`production/l1-tasks-I.md` — chạy suite ở cây chính, xanh thì commit + push.

**Lưu ý worktree bẩn lúc bàn giao** (agent bị ngắt do hết hạn mức): C 3 file, E 4, L 3, S 7 chưa commit — session mới
xem `git status` từng worktree, giữ/commit nếu xanh, không xoá bừa. Agent cũ của session trước có thể vẫn đang chạy nền một lúc.

**Chưa merge (theo làn, việc kế tiếp):**
| Làn | Commit chưa merge | Trạng thái / việc tiếp |
|---|---|---|
| A | 24b8d76 luật Nhiệm vụ, b7f270d end_run gọi record_run_outcome/pass_add_run_xp | 24b8d76 đang chờ review (lead-programmer). Tiếp: nối offer_ctx của B vào RunState (reward/shop/event/treasure/pact boss, shop_relic_count), R5 pact_reroll/pact_pick + ALLOWED_FNS + replay |
| B | 7ffcbb7 mô tả EN+boss immune (đã duyệt), ee2b582 offer v2 (đã duyệt), 83aefe9 thân 22 relic H1–H8 + 7 rework, 24dd998 pact live | 2 commit đầu đã duyệt MERGE (bump `-d`). 2 commit sau cần review. Còn: trục G/A, trần reroll a_chaos 6/4, relaybaton, Eternal sticker, pact bắt buộc A6/A10, mở nốt relic ẩn |
| C | 3f389e4, 8353d24, 011971f (Atia 3D + sửa review), 2935916 sân 6 biome, ef4bf9f ảnh lineup/arena | Review lần 2 báo commit cũ thiếu file arena — nay đã commit arena; cần review lại cả chuỗi + kiểm checkout sạch. Ảnh ở production/qa/evidence/ |
| E | 7f68d62 ví Gem remote (đã duyệt MERGE), 7ce7560 Pass v2 | 7ce7560 cần review. Tiếp: Việc tuần (3/tuần, 500 XP), MissionBoard theo `params.mission`/`mission_outcome` khi A merge |
| L | 50b016b LandNav, 888ec56 hub Savannah, a6ebd95 đủ 6 tier + nâng Land | Review xong: FIX FIRST, danh sách ở `production/l1-review-L.md`. Tiếp: **xoay cổng Portal 90° (Liam)**, **làm đẹp hub (Liam duyệt ưu tiên)**: ánh sáng ấm + bóng mềm, nền đất/mảnh địa hình biome thật, decor dày hơn, Pass ghi 29 Dec 2026 |
| U | 3 commit WIP (theme v3, khay 5 cột, AidPanel, DefeatPanel, banner) | CHƯA xanh. Tiếp: cho xanh, gọi `_combat.set_epoch(RunState.epoch)` sau `from_data`, màn đăng nhập desktop (AccountService.begin_desktop_sign_in), newcomer ẩn nút Aid, dòng "2 elite ẩn" ở A9, số build |
| S | e0fc845 (h_0 run_start) | Tiếp: nối RemoteGemWallet khi đăng nhập / set_gem_wallet(null) khi đăng xuất, RunSession + RemoteEpochSource (seq từ 0), giá Continue boss 180, kiểm nhảy hàng M7, endpoint quà mùa 2×90 Gem, tài khoản khách tối thiểu |
| M | chưa mở | Mở làn M: các màn meta theo Round 3 (`design/handoffs/ui-02-round3/_zip/`, README normative, 135 khung): ưu tiên Run Setup, Echo Box, Nhiệm vụ, Store+Daily, Pass |

**Claude Design Round 3 + phụ lục Round 2 đã về** (`design/handoffs/ui-02-round3/`), chưa review. Việc: art-director review
→ ghi chú sửa cho Liam gửi; làn M + U làm theo.

**Liam trả lời tối 12/10:** Pass: hết mùa vẫn nhận được thưởng đã đạt, chỉ dừng cộng XP · ưu tiên làm đẹp Land hub: CÓ.
**Liam trả lời thêm tối 12/10 (đã chốt, không hỏi lại):** (3) chấp nhận các chỗ [INF] của Round 3, code theo, gom danh sách
sửa cho Liam gửi Claude Design · (4) bỏ phần gamepad trong R3 · (5) KHÔNG deploy Worker trong đêm — sáng 13/10 Liam làm cùng ·
(6) thứ tự ưu tiên trong đêm: merge các commit đang chờ → U xanh → màn meta R3 (Run Setup, Echo Box, Nhiệm vụ, Store, Pass
trước) → đẹp Land hub → relic ẩn → sân biome → RunSession. Tối đa 4 agent cùng lúc. Chạy liên tục, không chờ Liam duyệt.

**Trước deploy Worker (hỏi Liam):** áp migration 0002–0004 lên D1 `axie-dice-db`, `wrangler secret put RUN_TOKEN_KEY`, có
thể thêm redirect URI desktop cho Google OAuth; Cloudflare gói Free.

Bản đầy đủ trước khi rút gọn: `archive/active-2026-10-12-before-rewrite.md`. Backlog trước 20/9: `archive/2026-09-pre-cowork/` (đã bỏ).

## (cũ, sáng 12/10) BẮT ĐẦU TỪ ĐÂY

**Cập nhật cuối 12/10:** đã chốt + review xong: kiến trúc server RNG (local `docs/architecture/`), monetization-v1
(cách B, PA-1, quà 180 Gem, status CHỐT — chờ sim), ascension-v2 bảng răng cưa, prompt UI
`design/requests/ui-redesign-request-02.md` (Liam gửi Claude Design). Tiếp theo: (1) Liam gửi prompt UI + ghi chú cosmetics
02 cho Claude Design; (2) technical-director thêm kind epoch cho R5 đổi pact; (3) sim F/G cho monetization + Ascension;
(4) viết lại Nhiệm vụ bản cực khó; (5) kế hoạch phase toàn dự án. Mục 1–3 bên dưới là bản sáng 12/10, đã xong.

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
- Comment cũ gọi bậc 4 là "Mythic" (`reward_generator.gd:56`, `relic_def.gd:32`, `unit.gd:40`) giờ sai vì Mythic = 5 (chỉ cosmetic).
  Đây là file luật: sửa comment cũng làm đỏ `t_rules_version`, nên để gom vào lần bump `RULES_VERSION` chung.
- Lỗi parse GDScript làm Godot treo; Mac không có `timeout` → background + `( sleep N; kill $p )`.
- `godot/tools/record_sample_run.tscn` và `verify_run.tscn` CHƯA có SaveGuard — ghi đè save thật. Sao lưu
  `~/Library/Application Support/Godot/app_userdata/Axie Dice (Godot port)/` trước khi chạy bất cứ thứ gì.
- Chụp màn hình phải chạy KHÔNG `--headless`. Mọi ghi save qua `SaveStore`; field meta mới → sửa `MetaState.reload_from_store()`.
- Worker test: `cd worker && node --test test/*.test.mjs` (Node 24 không nhận `test/`).
- zsh không tách biến chứa tham số: dùng `${=var}`.
- Server tĩnh xem bản giao Claude Design: cấu hình `cosmetics-01` trong `.claude/launch.json` (cổng 8766).

---
**Session mới: đọc mục "⇢ BẮT ĐẦU TỪ ĐÂY" ở đầu file này, rồi mở `production/session-state/pending-decisions.md` (23 câu chờ Liam).**
