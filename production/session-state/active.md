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

## Open Questions
- Có nên xin quyền IP tên/art part Axie Origins song song ngay bây giờ không (blocker Bloodline, D1 đã CHỐT nhưng IP request thực tế chưa xác nhận đã gửi)?
- TALON (pierce) 0% Full Run — mẫu nhỏ (34), cần N≥2000 riêng biệt trước khi kết luận có cần buff không.
- `PART_REVIEW_SHEET.md` (bảng duyệt tay cho designer) chưa tạo — có thể sinh từ `parts_build_data.json` nếu cần review UI ngoài code.
