# Gói "gacha vui" (gói Lớn) — hợp đồng giữa các làn

Nguồn thiết kế: `design/proposals/core-pick-excitement-brainstorm.md` (mục 1-3 + Ghi chú reviewer). Liam chốt 22/10:
1. Thưởng combo = **B nhưng KHÔNG lộ bậc** lần chọn kế (bỏ A4 và B4 ý (3) hoàn toàn). Thưởng: trình diễn mạnh + **+1 reroll Lõi** khi lần đầu ráp Cặp của một combo.
2. Combo 2 tầng: **Cặp** (2 Lõi) / **Đủ** (Lõi thứ ba, bản vàng). Combo 1 là jackpot, không có tầng Cặp.
3. Chỉ hiện phần thưởng; không có chấm báo bậc dưới mọi hình thức.
4. Được làm chậm để hồi hộp; thời gian do mình chốt (bảng dưới), luôn có bấm để bỏ qua, mọi số là knob.
5. Có 2-3 Lõi meme (bật từ run thứ 2 của tài khoản).
6. **Gói Lớn** (A1-A3, A5-A8, B1-B3, B5, C5, D1-D4; KHÔNG A4, C3, C4, D5), tối đa 2 ngày.

## Nhịp (knob `godot/assets/data/ui/gacha_timing.json`, không phải file luật)
| Nhịp | Giá trị |
|---|---|
| Thẻ úp hiện + quầng bậc | 0.6 s (Rêu), 0.9 s (Hổ Phách), 1.5 s (Tinh Thể) — dài chỉ ở lần đầu thấy bậc đó trong run, lần sau 0.4 s |
| Lật lần lượt trái→phải | lệch 180 ms, mỗi lật 0.35 s |
| Cú cược (Hoá Thạch / Hòn Đá Mờ) | quay 2.0 s qua Lõi THẬT trong pool, chậm dần, dừng ở kết quả đã có trong seed |
| Reroll 1 thẻ | thẻ cũ bay ra 0.3 s + dòng "won't come back this run", thẻ mới úp → quầng → lật 0.5 s |
| Jackpot (A6: bộ ba T có thẻ tạo Cặp/Đủ) | thêm 0.6 s rung nhẹ + lấp lánh |
| Ráp Cặp lúc nhận | banner 1.2 s ("PAIR: <tên combo>") + âm; Đủ: 1.8 s, khung vàng |
| Combo nổ trong trận (B5) | tên combo 1.0 s, không chặn input |
Bấm chuột / Space bất kỳ lúc nào = tua hết nhịp còn lại. Reduce flashing: bỏ rung + lấp lánh.

## Data + API (làn GD sở hữu)
- `godot/assets/data/rules/core_combos.json` (file luật, có fingerprint): `[{id, name_en, name_vi, pair:[core_a, core_b] | null, full:core_c | null, jackpot:bool, hide_if_rules:[...]}]` — 14 combo theo bảng 2.B (đã qua reviewer); combo có Lõi `disabled`/bị Luật run `excludes` tự ẩn; Lõi nhiệm vụ đã xong vẫn tính.
- `godot/scripts/core/core_combos.gd` `class_name CoreCombos` (static, thuần, không rng):
  - `all() -> Array` các combo đang bật cho run.
  - `state(owned: Array) -> Dictionary` id → "pair" | "full".
  - `card_completes(owned: Array, core_id: String) -> Dictionary` {id, tier} nếu nhận thẻ này làm đủ Cặp/Đủ, không thì {}.
  - `matches(owned: Array, core_id: String) -> Array` tối đa 2 Lõi người chơi ĐANG có hợp với thẻ (chip "Works with").
- RunState: `combo_done: Dictionary` (id → tier, save + replay), `core_skipped_t: Array` (Lõi Tinh Thể từng hiện mà không lấy, cho near-miss A8/D3), thưởng: lần đầu ráp Cặp của một combo → `core_rerolls += 1` (tối đa +2 mỗi run, knob `core.combo_reroll_cap`).
- EventBus: `combo_formed(combo_id: String, tier: String)` (lúc nhận Lõi), `combo_fired(combo_id: String)` (trong trận, lần đầu mỗi trận cả hai Lõi của Cặp cùng phát `core_fired` trong một lượt).
- Lõi meme (C5): 2-3 Lõi Rêu mới (design ở `design/proposals/meme-cores.md`), `requires_runs: 1` (ẩn ở run đầu tài khoản), phát `core_fired`.
- Đổi luật → làn GD KHÔNG bump RULES_VERSION (bump chung lúc merge), chạy với `AXIE_SKIP_RULES_FINGERPRINT=1`.

## UI màn chọn Lõi (làn GP sở hữu `godot/scenes/run_map/**` phần overlay Lõi + `godot/scenes/shared/ui3/**` component mới)
A1 hé bậc rồi lật, A2 âm/hiệu ứng theo bậc (âm tạm từ `godot/assets/audio/sfx/status` theo `design/audio/v4-dice-moments.md`), A3 thẻ Tinh Thể khác hình dáng (khung lăng kính, tên to, nổi khi rê), A5 cú cược quay, A6 jackpot, A7 nhịp reroll, A8 near-miss thật (trần T hạ thẻ: thẻ úp viền T vỡ thành H + lý do), B2 nhãn "PAIR!/FULL!" + tên combo trên thẻ sẽ làm đủ, B3 chip "Works with: X, Y", banner ráp Cặp/Đủ. Không có nhãn 1/2, không thanh tiến độ combo trên HUD. Đọc API ở trên; nếu GD chưa xong thì gọi theo tên, stub tạm.

## Trận + meta (làn GM sở hữu combat HUD panel Lõi, Result, Codex, Guides/daily, share)
B5 combo nổ trong trận (nghe `combo_fired`), D3 Result: khối "Combos" (Cặp/Đủ đã ráp) + dòng "Skipped" (≤3 Lõi T đã bỏ qua), D1 Sổ Lõi: `MetaState.core_codex` {core_id: {seen, picked}} + `MetaState.combo_codex` {combo_id: {pair, full}} — qua SaveStore, PHẢI vào `MetaState.reload_from_store()`; màn Codex thêm tab Cores/Combos (ô chưa thấy = bóng mờ), D2 thử thách ngày "Form combo X" trong hệ daily/Guides có sẵn, thưởng mỹ phẩm/danh hiệu (không Gene Shard), D4 "Copy run card" (text: đội + Lõi + combo + seed + luật run).

## Luật chung
UI3 (`godot/CLAUDE.md`): token/component, cỡ chữ 18/24/32 (+36 banner), disabled có lý do, tiếng Anh qua tr(). Test trước. Không vòng chờ không hạn chót; mọi Godot qua `with_lock.sh`. Không push/merge/deploy, không `git stash`.

## Làn GP - bàn giao (21/10, dừng giữa chừng theo lệnh điều phối)
Xong (2 commit trên nhánh `gacha/GP`):
- Việc 1 (6a30816): `godot/assets/data/ui/gacha_timing.json` (đủ bảng nhịp + sfx + knob `near_miss_sec`, `spin_hold_sec`), `scenes/shared/ui3/UI3Gacha.gd` (plan thuần, first_seen theo run, build_cover, play_sfx, `instant_override`), `scenes/shared/ui3/GachaReveal.gd` (úp -> quầng -> lật lần lượt, bấm/Space tua, Reduce flashing bỏ pulse + rung). Hook: `RunMapController._start_core_reveal()`, `_take_selected_reward()` tua trước khi nhận. Đã xoá chip "Next: tier" (không lộ bậc kế). Aura lấy bậc cao nhất trong 3 thẻ, bìa mỗi thẻ theo bậc của nó.
- Việc 2 (commit kế): A3 thẻ Tinh Thể (`UI3Gacha.prism_style/prism_frame`, góc vát corner_detail 1, hover nổi 1.04, tên 24, Rêu/Hổ Phách tên 18), A6 jackpot (rung + `jackpot` sfx, chỉ khi `combo_completes` khác rỗng), adapter combo `UI3Gacha.combo_completes/combo_matches/combo_name` (nạp `res://scripts/core/core_combos.gd` nếu có, có `combo_provider` để giả trong test), A2 âm theo bậc qua `play_sfx`.
- Test: `t_gacha_reveal` (16 check, MỚI -> sàn suite +1), `t_core_overlay_flow`, `t_ui_laws`, `t_ui3_theme`, `t_core_visibility_ui` xanh. Capture: `tests/qa_gacha_pick_capture.tscn` (facedown, flip_crystal, jackpot) -> `production/qa/evidence/gacha_pick_*` (thư mục bị gitignore).
Chưa làm: việc 3 (A7 reroll từng thẻ: ghost bay ra 0.3 s + "Won't come back this run", thẻ mới úp/lật 0.5 s qua `GachaReveal.start(..., flip_sec)`; A5 quay cược Hòn Đá Mờ: đọc `owned_relic_ids` trước/sau `apply_chosen_reward` để biết Lõi T được cấp, quay qua pool `CoreOffer.valid_pool(RunState._core_ctx(...))` rarity 2, chỉ làm với `c_dim_stone`; Hoá Thạch không có kết quả lúc nhận nên bỏ, payoff là lần lật kế), việc 4 (near-miss: `chain[_core_offer_pick]==2` mà thẻ tier<2 và `owned_crystal_count>=t_cap`, bỏ qua offer bonus; B2 nhãn PAIR!/FULL!; B3 chip "Works with"; banner 1.2/1.8 s sau nhận), việc 5 (test từng mục, cả suite một lần, ảnh còn lại). Banner/spin nên là một `GachaFx` mới trong ui3. Lưu ý: CoreCombos của làn GD chưa có trong worktree này.

### Cập nhật GP (21/10, lượt 2)
Xong, đã commit trên `gacha/GP`: bước 0 (a3e8d97, adapter dùng CoreCombos thật), 3a A7 reroll từng thẻ (4110c2d), và (commit WIP kế) 3b cú quay Hòn Đá Mờ (`GachaFx.start_spin`, quay 2.0 s qua Lõi Tinh Thể thật, dừng ở Lõi đã cấp; state quyết định trước bằng `_apply_and_finish`), 4b nhãn "PAIR!/FULL! <tên>" + chip "Works with: X, Y" trên thẻ + banner Cặp 1.2 s / Đủ 1.8 s khung vàng (click-through). Test `t_gacha_moments` (28 check, MỚI: sàn suite +1 nữa, tổng +2 so với trước GP) xanh. Ảnh `production/qa/evidence/gacha_pick_{reroll,spin,pair_label,banner_pair,full_label,banner_full}_*` (gitignore); ảnh spin 1920x1080 chụp chưa thấy plate dù log cho thấy fx đang chạy -> cần chụp lại/kiểm. 
Dở: 4a near-miss (chưa làm: cover T vỡ thành H + lý do; điều kiện chain[_core_offer_pick]==2, offer tier<2, owned_crystal_count>=t_cap, bỏ qua bonus offer; cần thêm tham số vào GachaReveal.start/plan), 5 (chạy t_core_overlay_flow, t_ui_laws, t_ui3_theme và cả suite một lần, ảnh near-miss). Hoá Thạch không quay (không có kết quả lúc nhận). Chưa kiểm t_ui_laws với chữ 36 ở banner.

### Cập nhật GP (21/10, lượt 3) - XONG
4a near-miss: `UI3Gacha.capped_from(offer_tier)` (UI đọc RunState, KHÔNG đụng file luật: milestone offer, chain[pick]==2, offer thấp hơn, Crystal sở hữu >= cap; bỏ sót case bump/Mua Sao) -> `GachaReveal.start(..., from_tier)` / `UI3Gacha.plan(..., from_tier)`: bìa mở bằng viền bậc T, nứt thành bậc thật + dòng "Crystal cap reached" + sfx near_miss, flip lùi `near_miss_sec` 0.6. Banner combo chữ 32 (36 chỉ cho banner lượt). Lỗi thật đã sửa: plate quay + banner bị vẽ DƯỚI card vì UI3 card panel z_index 6 -> fx z_index 50. Suite 194/194 (+1 SKIP t_rules_version do cờ). Ảnh: `production/qa/evidence/gacha_pick_{spin,nearmiss_before,nearmiss_crack}_{1920x1080,1280x720}.png`. Hoá Thạch vẫn không quay.
