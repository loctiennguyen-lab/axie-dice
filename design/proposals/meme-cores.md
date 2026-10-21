# Lõi meme (C5): 3 Lõi bậc Rêu "yếu nhưng vui, để kể lại"

Nguồn: `production/gacha-contract.md` (mục "Lõi meme"), `core-pick-excitement-brainstorm.md` C5 + nguyên tắc 8, `dice-depth-v4.md` 3.0-3.3. Chưa sửa code, chưa commit. Đây là đề xuất để Liam duyệt, chưa phải luật.

## Quy tắc chung cho cả 3

- `rarity = 0` (Rêu). Field data: **không có `requires_runs`** trong `RelicDef`; cái có sẵn là `first_run_hidden = true` ("không hiện ở run đầu của tài khoản"), dùng cái đó cho cả 3 (đúng ý "bật từ run thứ 2").
- Tất định: mọi lựa chọn ngẫu nhiên dùng `combat._rng` (rng của engine, từ seed), chỉ rút khi Lõi đang được sở hữu và đang phát. Không rng ngoài engine, không thời gian thật.
- Mỗi Lõi phát `CoreHooks.fire(id, uid, amount>0, kind)` đúng lúc nó làm gì đó thật. `fire` im lặng khi preview (`mute`), nên dùng `_fire_live` / `fire` trong handler chạy thật như các Lõi hiện có.
- Không động vào BỘ/gai/Overcast theo hướng cộng thêm hệ số. Mỗi Lõi dưới đây nêu rõ vì sao không chồng được.
- Mọi số là knob (`rule_knobs` hoặc `assets/data/rules/`), không hard-code. Đụng `resources/relics/` + `assets/data/rules/` là phải bump `RULES_VERSION` chung lúc merge (làn GD không tự bump).
- Pool Rêu chỉ hiện ở lần chọn 1 và lần 2 chuỗi RR (reviewer đã cảnh báo): 3 Lõi meme chiếm chỗ Rêu thật ở lần chọn ít thẻ nhất. Gợi ý: `weight` thấp (nếu pool có trọng số) hoặc chỉ cho tối đa 1 meme mỗi lần chọn. Cần Liam quyết (câu hỏi 1 bên dưới).

---

## 1. Copycat (`c_meme_copycat`) — chơi với BỘ

- **Mô tả thẻ:** "Each turn you have a Set, your weakest die outside it copies the Set's part, but only for 1."
- Trục `dice`, hook `on_roll_settled` (chỉ lần tung đầu của lượt, `rerolled_uids` rỗng; và cả sau Liều nếu chưa phát lượt này).
- **Hiệu ứng chính xác:**
  1. Sau khi `recompute_bo()` chốt, nếu có ít nhất 1 nhóm Bộ (size ≥ 3), lấy nhóm có part ưu tiên: size lớn nhất, hoà thì part có `fi` nhỏ nhất.
  2. Chọn 1 viên **đủ điều kiện (3.2) nhưng ngoài mọi nhóm Bộ**, không Held/Nứt/Mặt Tạm/viên ảo; chọn viên có giá trị chính thấp nhất (hoà: slot thấp nhất). Không rút rng. Không có viên nào thì thôi.
  3. Viên đó `set_roll(fi_của_Bộ)`: hiện đúng mặt part của Bộ (kèm loại/keyword của mặt đó), nhưng **giá trị chính = 1** và gắn `custom_state.copycat = true` (reset khi viên đó tung lại hoặc hết lượt).
  4. Viên copycat **không tính vào Bộ**: thêm điều kiện vào 3.2 ("không có `custom_state.copycat`") giống Nứt/viên ảo. Nhóm Bộ giữ nguyên size, không được hệ số và cũng không đẩy bậc lên. Gọi `_snap_bo()` sau khi đổi mặt (3.3 mục 5).
  5. Mỗi lượt tối đa 1 lần (`turn_state(combat, "cs_copycat")`).
- **core_fired:** `fire("c_meme_copycat", uid_viên, 1, "rule")` lúc bước 3 xong, kèm float text "COPY!" trên viên đó.
- **Vì sao vui:** Axie yếu nhất bắt chước Bộ nhưng làm không ra hồn ("Horn, nhưng 1"). Người chơi nhìn thấy mặt Bộ nằm sai chỗ trên bàn và có chuyện để kể. Đổi loại mặt (khiên thành đòn) đôi khi vô tình có ích.
- **Vì sao không phá cân bằng:** nó chỉ chọn viên YẾU NHẤT ngoài Bộ và ép nó về 1, nên kỳ vọng là hơi âm hoặc hoà (mất 1-3 điểm giá trị/lượt, chỉ lượt có Bộ). Không vào nhóm nên Bộ BA không thành BỐN. Overcast cộng +0.5 vào hệ số của một viên 1 điểm thì gần như 0; Mặt Tạm không dùng được lên viên copycat (đã có `wild_slot` hoặc `copycat` thì bỏ qua, nên không thể cộng dồn để tạo Bộ rẻ).
- **Lỗ hổng cần test:** viên copycat bị Hold/Stash (mang sang lượt sau) thì cờ `copycat` hết hạn cùng lượt, mặt giữ nguyên nhưng giá trị trả về bình thường? Chốt: cờ xoá cuối lượt, mặt giữ part nhưng giá trị trở về giá trị thật của mặt đó. Cần reviewer xác nhận không tạo cách rửa giá trị.

## 2. Name Tag (`c_meme_nametag`) — quái bị đổi tên

- **Mô tả thẻ:** "Start of combat: a random enemy gets a silly name. Kill it for +1 Mana."
- Trục `rule`, hook `on_combat_start` (đặt tên) + `on_kill` (thưởng).
- **Hiệu ứng chính xác:**
  1. Đầu trận, chọn 1 quái sống **không phải boss** (rng engine, `next_int(n)`), gán tên từ danh sách cố định `assets/data/rules/meme_enemy_names.json` (12 tên EN, ví dụ "Gary", "Steve the Unbothered", "Sir Bonks-a-Lot", "Karen", "Mr. Crunchy"; tên chọn bằng rng engine thứ hai). Lưu `custom_state.nick`. Không có quái non-boss thì không làm gì và không phát.
  2. Quái này giữ nguyên chỉ số. Khi nó chết (bất kể do ai, kể cả độc/gai): +1 Mana (`CoreHooks.gain_mana(combat, 1, "RIP "+tên, "c_meme_nametag")`), tối đa 1 lần/trận.
- **core_fired:** lúc đặt tên `fire(id, uid_quái, 1, "rule")` (hiện thanh tên mới + float text); lúc chết `fire(id, 0, 1, "mana")` qua `gain_mana`.
- **Vì sao vui:** log trận và thanh máu hiện "Gary đã chết" thay vì "Skeleton". Đánh Gary có cảm giác cá nhân, người chơi kể "tao giết Karen trước". Không cần hiểu luật gì.
- **Vì sao không phá cân bằng:** +1 Mana khi một con chết là rất nhỏ (cùng cỡ Dewdrop +1/lượt, nhưng mỗi trận chỉ 1 lần, không lặp). Không đổi chỉ số quái, không đổi thứ tự lượt, không chọn boss (tránh đụng BOSS_ALT). Không tương tác với BỘ/gai/Overcast.
- **Cần làm UI (làn khác, ghi để không sót):** UI đang đọc tên quái từ `name` của đơn vị. Cần một chỗ đọc `custom_state.nick` (thanh máu, log, tooltip). Nếu không hiển thị tên thì Lõi này vô hình, trái nguyên tắc "content mới phải thấy được". Liam/lead cần quyết có làm hay thay bằng Lõi khác nếu UI không kịp (câu hỏi 2).

## 3. Jumpy Dice (`c_meme_jumpy`) — xúc xắc tự nhảy

- **Mô tả thẻ:** "After the roll, two random dice jump and swap places. Sometimes it helps."
- Trục `dice`, hook `on_roll_settled` (chỉ lần tung đầu của lượt, `rerolled_uids` rỗng).
- **Hiệu ứng chính xác:**
  1. Sau `roll_all()` xong và Bộ đã chốt, chọn 2 viên khác nhau trong số viên đủ điều kiện (3.2), chưa dùng, không Held/stash/Nứt/Mặt Tạm/copycat/viên ảo, bằng rng engine. Cần ≥ 2 viên, không thì thôi.
  2. Hai viên **hoán đổi chỉ số mặt `fi`**: mỗi viên hiện mặt `die[fi_của_viên_kia]` trên chính xúc xắc của mình (cờ crit giữ theo viên, tính lại theo loại mặt như `_share_class_rolls` làm). Cantrip không phát lại.
  3. Mỗi lượt 1 lần (`turn_state(combat, "cs_jumpy")`). Gọi `_snap_bo()` sau đó.
- **core_fired:** `fire("c_meme_jumpy", uid_viên_1, 1, "rule")`, UI nên phát hiệu ứng nhảy cho cả hai viên (cần sự kiện/`die_wild`-like; làn UI quyết).
- **Vì sao vui:** xúc xắc tự đổi chỗ trước mắt người chơi, có lúc may (Miệng thay mặt khiên), có lúc xui. Không ai điều khiển, nên là "chuyện kể".
- **Vì sao không phá cân bằng:** hoán đổi `fi` giữ nguyên **bội số part** trên bàn nên kích thước các nhóm Bộ không đổi, không thể tự tạo hay phá Bộ BA/BỐN/NĂM (đây là tính chất đã kiểm bằng lập luận, cần test xác nhận). Kỳ vọng giá trị ~0 (hai viên ngang xác suất). Chỉ phương sai tăng. Không động mana, không động gai, không động Overcast (Overcast dùng sau khi nhảy, người chơi thấy kết quả rồi mới quyết). Với Concord (cùng class cùng `fi`): hoán đổi có thể làm hai viên cùng class lệch part; vẫn nằm trong luật "mỗi class một viên đếm Bộ", nên chấp nhận.

---

## Câu hỏi cho Liam / lead

1. Pool Rêu chỉ có 2 lần chọn ít thẻ: cho 3 Lõi meme chiếm bao nhiêu? Gợi ý: tối đa 1 meme mỗi lần chọn, hoặc `weight` thấp.
2. Name Tag cần UI đọc `custom_state.nick`. Làn GP/GM có nhận không? Nếu không thì đổi thành Lõi khác (ví dụ "Battle Scream": Axie ngã thì hét, +2 Khiên cho đồng đội, chỉ là float text).
3. Copycat sửa luật 3.2 (thêm điều kiện loại viên copycat). Đây là đổi luật BỘ, cần reviewer/GD duyệt riêng.

## Test cần có (để làn code viết trước)

- Mỗi Lõi: có thẻ trong pool từ run thứ 2, ẩn ở run 1; phát `core_fired` đúng lúc, im lặng ở preview.
- Tất định: cùng seed + cùng hành động cho cùng kết quả, replay khớp (`t_replay`).
- Copycat: size nhóm Bộ không đổi trước/sau; viên copycat không nhận hệ số; giá trị = 1; mỗi lượt tối đa 1.
- Jumpy: bội số part bất biến trước/sau hoán đổi; không chạm viên Held/Nứt/ảo.
- Name Tag: không bao giờ chọn boss; +1 Mana đúng 1 lần/trận; không lỗi khi hết quái non-boss.

## Chốt (agent điều phối, 22/10 — Liam giao đẩy nhanh)
- Tối đa 1 Lõi meme mỗi lần chọn thẻ Rêu (không chiếm chỗ Lõi thật), dùng `first_run_hidden = true`.
- Giữ Name Tag: tên ngố hiện trên bảng tên quái trong trận (làn GM làm UI đọc `custom_state.nick`).
- Copycat: viên đổi part KHÔNG tính vào nhóm BỘ (không đẩy bộ ba thành bộ bốn) — làn GD thêm đúng điều kiện này + test.
