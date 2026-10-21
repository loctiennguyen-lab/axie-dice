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
