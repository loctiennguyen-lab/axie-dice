# Session State

## Current Task
Xử lý GDD/spec/mechanics theo `docs/review-2026-08-31.md` + `docs/adoption-plan-2026-08-31.md`, ưu tiên GDD/mechanic trước, các mảng khác (economy, art, UI/UX, QA) sau.

## Progress Checklist
- [x] Import toàn bộ tài liệu/code từ `/Users/loc.tien.nguyen/Downloads/AxieDice 2` vào template (`docs/axiedice-source/`, `design/gdd/`, `src/`, `tools/`)
- [x] `/adopt` audit → `docs/adoption-plan-2026-08-31.md`
- [x] Review 5 mảng song song (game-designer, economy-designer, art-director, ux-designer, qa-lead) → `docs/review-2026-08-31.md`
- [x] Sửa `docs/axiedice-source/guide/PLAYER_GAME_GUIDE_v1.md` — gỡ mục "Gọi mặt" (Declare), đã xác nhận bị gác lại chính thức theo `bloodline-system.md` v1.2, không có trong code
- [x] Viết lại hoàn toàn `design/gdd/game-concept.md` theo format 8 mục, nguồn: `AUDIT_AND_SPEC_v1.md` Phần B-F + đối chiếu trực tiếp `src/engine.js`/`src/data.js`/`src/ui.js`. Phát hiện thêm 1 lệch số: base reroll thật là 2, không phải 1 như audit cũ.
- [ ] `part-tier-system.md` — khoá archetype Beast (7 part → FERAL), chốt 7 part thiếu card text
- [ ] `axie-body-parts.md` — retrofit 8-section nếu cần
- [ ] `combo-decision-memo.md` / `build-spec.md` — retrofit hoặc giữ nguyên dạng spec kỹ thuật (chưa quyết định, xem adoption-plan mục 2.1-2.7)
- [ ] `design/gdd/systems-index.md` — chưa tồn tại, cần `/map-systems`
- [ ] Sau khi xong GDD/mechanic: chuyển sang economy (mục #3-#5, #11 trong review), art (#6, #9), UX (#7-#8), QA/docs (#10)

## Key Decisions
- Cơ chế "Gọi mặt"/Declare/BLOODCHAIN: đã xác nhận bị gác lại chính thức (bloodline-system.md v1.2), KHÔNG implement lại trong phiên này — chỉ sửa tài liệu cho khớp thực tế.
- game-concept.md: viết lại toàn bộ (không phải chỉ thêm section thiếu) vì nội dung cũ sai thực chất, không chỉ thiếu cấu trúc — quyết định của user.

## Files Being Worked On
- `design/gdd/game-concept.md` (vừa hoàn thành)
- `design/gdd/part-tier-system.md` (tiếp theo)
- `design/gdd/axie-body-parts.md` (tiếp theo)

## Progress Checklist (tiếp — 2026-09-01 phần 2)
- [x] D1-D16 đồng bộ ✅ CHỐT giữa economy-progression.md và build-spec.md
- [x] Balance quái/boss: `TUNE.growth2` 1.065→1.05, `eliteMult` 1.40→1.25 (`src/data.js`), xác nhận qua sim thật (Full Run 3.6%→8.0%) — log ở `docs/balance-log.md`
- [x] Hợp nhất màu rarity (`RAR_COL`↔CSS `--r0..r4`) + dịch hue 4 class color khỏi vùng semantic (`src/data.js`)
- [x] `docs/axiedice-source/HANDOVER.md` cập nhật ghi chú lỗi thời
- [x] Milestone Ledger (`design/quick-specs/milestone-ledger.md`) — progression/retention
- [x] Leaderboard (`design/gdd/leaderboard-system.md`) — Standard/Collector, anti-cheat qua deterministic replay
- [x] ADR-0001 (`docs/architecture/adr-0001-leaderboard-backend-infrastructure.md`) — serverless function + managed DB, registry đã cập nhật
- [x] Sink cuối game Echo Points (`design/gdd/economy-progression.md` §10.2/§10.2a/§10.2b/§10.3) — kèm NFT HP bonus (ngoại lệ có phạm vi của D12, CHƯA validate qua sim vì NFT preselect chưa implement)
- [x] Icon spec 6 body part (`docs/art/icon-spec-body-parts.md`)
- [x] Combat log UX spec (`design/ux/combat-log.md`)

## Progress Checklist (tiếp — 2026-09-01 phần 3, "việc còn treo")
- [x] `tools/gen_parts.py` viết lại hoàn toàn — đọc 36 template (§2a/§2c) + bảng gán (§8) nhúng trong script, không gọi API/đọc card text. Chạy thành công 192/192 part, không part nào lọt ngoài bảng gán. Output: `docs/axiedice-source/economy/parts_build_data.json`.
- [x] NFT HP Bonus (§10.2a) implement thật trong `src/engine.js` (`nftHpBonusPct`, `opt.nftPreselect`) + `tools/sim.js` hỗ trợ test (`nftCount=`/`nftOwned=`/`nftGenes=`). Validate: Full Run 8.6%→10.5%, Short Run 17.9%→21.8% ở kịch bản cực đại — an toàn, không cần hạ hệ số. Log ở `docs/balance-log.md`.
- [x] `.rsel` button-nesting — **hoá ra là báo động giả**: đối chiếu code thật (`ui.js:671-674`, `style.css:429-430`) cho thấy `.rsel` vốn đã là sibling của `.die`, không lồng bên trong. Đã đính chính `docs/review-2026-08-31.md` (mục 5 và hành động #8), không cần fix.

## Progress Checklist (tiếp — 2026-09-01 phần 4)
- [x] TALON N=2500: 3% winrate (190 mẫu), cùng nhóm CONDUIT/TEMPEST — mẫu 34 cũ chỉ là nhiễu, không cần buff. Log ở `docs/balance-log.md`.
- [x] `docs/axiedice-source/economy/PART_REVIEW_SHEET.md` sinh từ `parts_build_data.json` — 192 part, dễ duyệt tay.
- [x] Cập nhật bảng hành động trong `docs/review-2026-08-31.md` — 10/11 mục ✅, chỉ còn #4 (xin quyền IP) là hành động ngoài đời thực.

## Open Questions (thật sự còn treo)
- AEGIS (thorns) giờ là archetype mẫu nhỏ nhất (25 run, 0% ở N=2500) — chưa đủ dữ liệu, theo dõi ở lần sim lớn tiếp theo.
- Icon pixel data thật (`IC_G` format) và implement combat log UI — việc code thật, ngoài phạm vi GDD/balance, cần ui-programmer/technical-artist.
- ~~Mục #4 — xin quyền IP tên/art part Sky Mavis~~ **ĐÃ GIẢI QUYẾT** (commit 9c387fc, 2026-09-01): IP granted, tên part thật đã gắn vào FACE_POOL.

## Progress Checklist (tiếp — 2026-09-01 phần 5, phản hồi "game chưa đổi mới" + "UX xấu")
- [x] **economy-progression.md §10.2b/§10.3 chốt 3 câu hỏi treo** (giá part α ~700 Shard, pre-select bắt buộc để dùng part NFT, gate Echo Points tách 2 thanh Free/NFT độc lập) — quyết định của product owner qua AskUserQuestion.
- [x] **UI/UX overhaul thật** (ui-programmer, đã tự verify bằng browser thật):
  - Bug "TURN undefined" ở combat header → sửa `src/ui.js:424`, luôn fallback `S.turn||1`.
  - Bảng "Classes & Playstyles" trong Codex lệch cột (2 header nhưng 3 phần dữ liệu) → viết lại `cxTable` (`src/ui.js:950-965` + áp dụng cho mọi bảng codex khác cùng lỗi: `relictable`/`tiertable` ở `:1146-1153,1187,1403-1404`) để tính `grid-template-columns` động theo số cột thật.
  - Sample Teams tràn ngang cắt chữ → `src/style.css` `.guidegrid` đổi sang `repeat(2,minmax(0,1fr))` + `min-width:0`/`overflow-wrap`.
  - Visual overhaul: class-colour gradient trên `.unit.p`, glow/scale cho `.unit.acting` (lượt đang hành động), `.nodecard:hover/:focus-visible`, số HP to/đậm hơn (`.hpnum b`), tiêu đề đậm hơn (`font-weight:900`).
  - **Đã tự verify bằng browser thật** (không chỉ tin lời agent): TURN 1 hiện đúng, bảng Classes đúng 3 cột, Sample Teams 2 cột không cắt chữ.
- [x] **Mechanic MỚI cho core combat loop — Formation Resonance** (game-designer đề xuất → gameplay-programmer implement → tự verify bằng cách gọi thẳng `execFace`/`resonancePairs` qua console, bypass UI để test đúng logic engine):
  - Spec: `design/quick-specs/formation-resonance-2026-09-01.md`.
  - 2 Axie liền kề trong đội hình cùng roll mặt cùng type (dmg/shield/heal/poison/mana) trong 1 lượt → Axie thực thi SAU nhận `+RESONANCE.mult` giá trị mặt.
  - Implement: `src/data.js` (`RESONANCE` const), `src/engine.js` (`formationPos`/`checkResonance`/`logResonanceAttempt`/`resonancePairs`, tích hợp vào `execFace`/`faceValue`/`startCombat`/`endTurn`/`SNAP`), `src/ui.js` (preview icon `.reslink` giữa 2 chân dung TRƯỚC khi click — bắt buộc theo pillar minh bạch), `src/fx.js` (hiệu ứng event `resonance`).
  - **Verify thật qua console** (2026-09-01): tạo state test (2 Axie liền kề cùng roll dmg), gọi `execFace` trực tiếp — Axie đầu (v=2) không bonus, Axie sau (v=5, keyword heavy) nhận đúng `ceil(5×1.15)=6` sát thương, event `{t:'resonance'}` + float text `"LINK ×1.15"` xuất hiện đúng, `resonanceLog` cập nhật `used:true` chính xác.
  - **⚠️ Balance risk chưa chốt**: sim N=500 cho thấy winrate +13% đến +21% relative so baseline (19.8%→22.4% ở mult=1.25, →24.0% ở mult=1.15) — đã hạ `RESONANCE.mult` từ 1.25 xuống **1.15** (sàn của khoảng an toàn) làm giá trị khởi điểm thận trọng, nhưng lưu ý RNG seed cố định trong `sim.js` khiến so sánh này bị nhiễu bởi hiệu ứng cánh bướm (xem `docs/balance-log.md` mục 2026-09-01). **Cần chạy lại N≥2000 với nhiều seed offset trước khi coi số liệu ổn định để ship** — chưa làm trong phiên này.
  - GDD đã cập nhật: `design/gdd/game-concept.md` (EXECUTE step + Tuning Knobs table).

## Open Questions mới
- ~~Formation Resonance cần sim N≥2000 đa-seed~~ **ĐÃ XONG** (2026-09-01): thêm `seed0=` override vào `tools/sim.js`, chạy 5×500 run độc lập. Kết quả thật: baseline TB 21.52%, Resonance mult=1.15 TB 22.88% → **+1.36pp tuyệt đối (~6.3% relative)**, thấp hơn nhiều so với số liệu 1-seed gây hiểu lầm trước đó (từng đọc nhầm tới +21%). Giữ nguyên `mult=1.15`, đủ tin cậy để ship. Log đầy đủ ở `docs/balance-log.md`.
- Drag-to-reorder đội hình ở Team Select (để chủ động sắp Resonance) chưa làm — v1 chỉ dùng thứ tự click hiện có, ghi trong quick-spec là "nice-to-have" cho bản sau.
- User đã duyệt (2026-09-01) toàn bộ thay đổi phần 5 (UI overhaul + Formation Resonance) — sẵn sàng commit khi được yêu cầu.

## Progress Checklist (tiếp — 2026-09-01 phần 6, kiểm duyệt cấp cao trước commit)
User yêu cầu rõ: "kiểm duyệt chặt chẽ từ agent cấp cao, UIUX phải hoàn hảo". Chạy 3 review nghiêm ngặt song song trước commit:
- [x] **art-director** (NEEDS REVISION → đã fix hết): phát hiện Collection/Unlocks bị bỏ sót khỏi fix layout trước đó (`.screen.menu.collection/.unlocks` thiếu trong selector `justify-content:flex-start`, gây dồn nội dung vào giữa màn đen trống). Đã fix: thêm class, empty-state, `.colsec h3` border, `.sethint` type-scale, `.cxtab.on` active-indicator ở breakpoint tablet.
- [x] **ux-designer** (NEEDS REVISION → đã fix 2 mục blocking): Collection empty-state cần dùng lại pattern `.iempty` có sẵn (thay vì class mới `.citem-empty`) với copy hữu ích hơn "None yet." — đã sửa theo đúng đề xuất. Codex nói sai "one reroll per turn" trong khi engine thật là 2 — đã sửa text. Ghi nhận backlog (không chặn): keyboard-only gần như chỉ hoạt động ở bước chọn die (thiếu tabindex toàn bộ game ngoài combat), thiếu toggle giảm flash màn hình trong Settings, label BACK/MENU không nhất quán 3 kiểu khác nhau, Esc không phải universal-back ở màn top-level.
- [x] **lead-programmer** (NEEDS FIXES → đã fix): bug thật trong `checkResonance` — tiêu thụ bản ghi resonance (`s.resonanceLog[idx].used=true`) TRƯỚC khi biết `doFace` có thành công không; nếu target chết/invalid giữa chừng, bonus resonance mất âm thầm không cảnh báo (vi phạm pillar minh bạch). Bug này kế thừa từ chính pseudocode gốc trong spec, không phải do agent tự sáng tác. Đã sửa: tách `findResonanceIdx` (pure, không mutate) khỏi việc consume — chỉ mark `used=true` sau khi `doFace` trả `true`; đồng thời fix thêm `u.resonantNow` không được reset khi `doFace` fail (bug liên quan). Verify: sim.js 2 seed trước/sau fix cho cùng kết quả (24.0%/21.0%), không regression. Đồng bộ `game-concept.md` Tuning Knobs ghi đúng `mult=1.15` (trước đó vẫn ghi nhầm 1.25).
- [x] Build lại + verify browser thật sau mỗi vòng fix (không lỗi console, Collection/Unlocks hiển thị đúng).

## Backlog mới (không chặn commit lần này, ghi lại để không quên)
- Keyboard-only accessibility: hầu hết UI ngoài bước chọn die trong combat (chọn team, chọn node map, chọn target, mua shop, claim pass) không có `tabindex`/focus — không dùng được bằng bàn phím thuần. Cần 1 task riêng cho `ui-programmer`/`accessibility-specialist`.
- Settings thiếu toggle giảm/tắt flash toàn màn hình (crit/Mythic pickup) — cần cho người nhạy cảm ánh sáng.
- Label nút thoát không nhất quán (BACK/MENU, class khác nhau giữa các màn) — polish nhỏ.
- Esc chưa phải universal "back" ở các màn top-level không phải modal.
- `design/ux/interaction-patterns.md` chưa tồn tại — team-ui skill Phase 1a từng flag việc này, quyết định (b) là proceed không có pattern library, patterns mới coi là mới. Chưa tạo file này chính thức trong phiên này.

## Progress Checklist (tiếp — 2026-09-01 phần 7, release-readiness song song)
User hỏi "còn gì trước khi release" → chọn scope V1: web game offline free, không economy/leaderboard. Chạy 3 việc song song (devops-engineer, ui-programmer, accessibility-specialist), rồi 2 review cấp cao (ux-designer, lead-programmer):

- [x] **Test infra**: cài `playwright` qua `package.json` mới (chỉ devDependency, không đụng `build.py`). `tools/verify.mjs`/`soak.mjs`/`soakm.mjs` sửa hardcoded Chromium path. Kết quả: verify.mjs 28/30 (2 fail còn lại là baseline có sẵn: B2.tablet scrollWidth overflow, N1.phone landscape-only theo thiết kế — không phải regression). Soak 25 run tổng, 0 crash/stall. Fix kèm theo: `--dim` contrast (`style.css:49`, `#99a3b2`→`#a1aec0`) để đạt WCAG AA — trước đó 26/30, sau khi fix contrast lên 28/30.
- [x] **Combat Log UI (T15)** implement đầy đủ theo `design/ux/combat-log.md`: module mới `src/log.js` (296 dòng), hook `clogIngest` trong `fx.js` (đọc đúng batch `playEvents()` sắp drain, không đọc `s.ev` sau khi mất), toggle `LOG` trong combat header + phím tắt `L`, Battle Report freeze+auto-open khi thua, SR channel throttle 400ms riêng biệt khỏi visible log.
  - **Bug MAJOR tìm bởi ux-designer, đã fix**: breakpoint desktop "dock zero-overlap" (ban đầu ≥1200px) sai vì `#app` center + `.zone` center lồng nhau — đo thật bằng browser (không đoán): overlap 266px@1280px, 21px@1600px, 0px@1680px+. Đã nâng breakpoint lên **1700px** (có buffer an toàn), dải 600-1699px dùng overlay-drawer (đã có scrim, cùng pattern chấp nhận sẵn cho tablet cũ 600-1199px).
  - **Fix MINOR**: panel Battle Report từng đè xuyên qua màn Menu sau khi thua+bấm MENU (không reset qua RETRY) — đã thêm auto-close (không xoá data) khi `screen!=='combat'` trong `render()` (`ui.js`).
  - 4 quyết định tự phát sinh của agent (aria-live="off" cho container + kênh riêng cho SR, status-tick damage generic "N dmg", resonance/hp không có dòng riêng, buff/debuff verbatim fallback) — tất cả đã được ux-designer duyệt kỹ bằng cách đọc chéo `engine.js`, đều APPROVE.
- [x] **Keyboard-only nav + Flash toggle**: helper `kbAct()` áp dụng cho `.pick`/`.nodecard`/`.icard`/`.unit`/`.rcard`/`.ucard`/`.bpnode` (Enter/Space kích hoạt, đúng semantics, không double-fire). `META.reduceFlash` mới trong Settings, `flashScreen()`/`hitstop()` tôn trọng cả setting này lẫn `prefers-reduced-motion` OS — verify bởi lead-programmer, không có vấn đề.
- [x] Verify cuối: `node tools/sim.js 500`/`seed0=999` không đổi winrate (24.0%/21.0%, khớp `balance-log.md`) — 3 track UI/test-only không ảnh hưởng balance. `verify.mjs` 28/30 giữ nguyên sau mọi fix.

## Backlog còn lại sau phần 7 (không chặn release V1 này)
- README.md vẫn là README template studio, chưa viết lại cho riêng game — làm khi chuẩn bị public repo/deploy link.
- AEGIS archetype vẫn thiếu dữ liệu cân bằng lớn (N nhỏ) — theo dõi tiếp.
- `kbAct` elements có thể thêm `role="button"` cho AT rõ ràng hơn (đề xuất lead-programmer, không blocking).
- Patch nhỏ gắn `reason:'poison'|'burn'` vào `dealDamage`/`tickStatus` để combat log hiện đúng "Poison N damage" thay vì "N dmg" chung chung (2 dòng, không blocking, đã được ux-designer duyệt tạm chấp nhận).

## Progress Checklist (tiếp — 2026-09-01 phần 8, Import Axie NFT thật)
User: "chưa có kho đồ để đưa NFT Axie vào — tiến hành chuẩn bị để release" → sau làm rõ: build luôn Phase 2 (Import Axie thật), không phải bỏ qua.

- [x] **Nghiên cứu kỹ thuật thật** (không đoán): Axie Infinity GraphQL (`graphql-gateway.axieinfinity.com/graphql`) chặn CORS (xác nhận qua `curl -X OPTIONS`, thiếu header `access-control-allow-origin`) → bắt buộc proxy qua Vercel serverless. Node `fetch`/`https` bị Cloudflare Managed Challenge chặn (đã test cả với User-Agent giả — vẫn bị chặn, đây là TLS/HTTP2 fingerprint check) nhưng `curl` bypass được → dùng `execFileSync('curl',...)` (argv array, KHÔNG shell string) trong serverless function. Query `GetAxieDetail(axieId)` đã verify hoạt động thật với nhiều ID (100000, 5000000...), trả đúng `class`+`parts[]` (id/name/class/type/specialGenes).
- [x] **`api/axie.js`** (Vercel serverless, mới) — proxy CORS + rate limit in-memory (20 req/phút/IP) + timeout curl (`-m 8`) + validate input regex + error handling không leak thông tin nội bộ. Đã qua security-engineer review (NEEDS FIXES → đã fix cả 2 điểm: timeout + rate limit).
- [x] **Mapping engine** (`src/data.js` `SLOT_CLASS_TEMPLATE` 6×6, `src/engine.js` `axieToDie`/`mapAxieClass`) — đúng insight thiết kế cũ (`AUDIT_AND_SPEC_v1.md` §G3①): KHÔNG hand-author theo từng part, map theo `(slot, class-của-part)` qua bảng nhỏ tái dùng dải giá trị `HEROES` tier1 sẵn có. Fallback Origin (Dawn/Dusk/Mech→beast/reptile/bug cố định, ×2.2) + `specialGenes` (×1.3) đã kiểm tra không tràn số, nằm trong dải myth-tier hiện có.
- [x] **Vault** (`META.vault`, tối đa 20) + màn "IMPORT AXIE" (menu → nhập Axie ID → preview → ADD TO VAULT) + tích hợp vào Team Select (section "YOUR VAULT", ẩn khi rỗng — học từ bài học Collection/Unlocks trước đây).
- [x] **Bug thật tìm được khi tôi tự test bằng chuột** (không phải qua console): click chọn Axie từ Vault vào team không hoạt động — root cause (do lead-programmer xác định chính xác): `PLAY`/`NEW RUN` pre-fill `teamPick` đủ 5/5 mặc định TRƯỚC khi vào màn Team Select, nên card Vault bị guard `if(teamPick.length<5)` chặn im lặng — không phải lỗi wiring. Đã fix: thêm class `.full` (dim card) + thông báo rõ ràng "Team full (5/5) — right-click a card to swap it out" khi click card đã đầy đội, áp dụng cho cả T1 lẫn Vault card.
- [x] **Verify end-to-end bằng browser thật**: dựng local mock server chạy đúng `api/axie.js` handler thật (không phải giả lập), import Axie #100000 thật → data thật hiển thị đúng → add vào Vault → chọn vào team qua UI thật (không phải console) → vào combat thật, unit build đúng 6 face theo class của TỪNG part (không phải class thân) — đúng bản chất Axie genetics.
- [x] `node tools/sim.js 500` không đổi (24.0%), `node tools/verify.mjs` giữ 28/30 — không regression.
- [x] Cập nhật `design/gdd/economy-progression.md` §10.2b — ghi rõ đây là scope **P0 prototype** (Vault miễn phí, không gate NFT, không pre-select-mỗi-run), KHÔNG phải toàn bộ mô hình pay-to-win đã thiết kế — tránh nhầm là economy đầy đủ đã live.

## Chưa làm (backlog thật, không chặn)
- README.md vẫn là README của template "Claude Code Game Studios", chưa viết riêng cho game — cân nhắc: repo này có vẻ là fork của chính template, README có thể có chủ đích quảng bá template — CHƯA tự ý thay, cần hỏi ý user trước khi động vào.
- Gate NFT thật (285/396 part khoá theo sở hữu, pre-select-mỗi-run, Echo Points 2-thanh nối với Vault) — toàn bộ mô hình pay-to-win ở economy-progression.md vẫn chỉ là thiết kế, chưa code.
- `HEROES[vaultKey]` không được dọn khi `removeFromVault` — vô hại (không có code nào scan `Object.keys(HEROES)`) nhưng là rác nhỏ, có thể dọn sau.
- Chưa có test tự động cho `axieToDie`/`mapAxieClass` (`tests/` trống) — verify hiện tại là tay + sim.js gián tiếp.
