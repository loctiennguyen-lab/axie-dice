# Soak 2026-10-27 (bản R3) — phân tích

- 27.069 run (381 ô). Kết thúc: WON 1.250, LOST 25.816, STUCK_TURNS 3. Không crash, không SCRIPT ERROR, không treo.
- Replay qua RunVerifier: ok 12.902, lệch 1, skip_forced 14.166 (ô ép Anchor/Luật, chưa replay được). Lệch Nhiệm vụ 85% của 26/10 đã hết, nhờ sửa verifier ở R3.
- 1.905 dòng `ERROR:` đều là `Couldn't open directory at path "user://acct"` (SaveGuard trong môi trường soak), vô hại.

## 3 run STUCK_TURNS (cùng 3 seed với 26/10, nay tái hiện được, chỉ khi có `--verify=1`)
- #1 seed 500024 N2 attack_spam, #2 seed 300026 Mana Mine + Pilot Light random_legal, #3 seed 400008 Mana Mine + Upside Down expert.
- Cả 3 là trận kéo dài khi ta chỉ còn 1 Axie: quái tự hồi (heal / ward / mend) ngang sát thương ta gây. Attrition dừng ở +25%, trận thường không có đồng hồ. Engine vẫn chạy đều mỗi lượt, không kẹt cứng.
- Người chơi thật có reroll, mana và tự chọn mặt nên dễ phá hơn bot. Tệ nhất là một trận chán và rất dài.
- Chặn hẳn thì phải đổi luật: bỏ trần attrition, hoặc thêm đồng hồ mềm cho trận thường. Việc này đổi kết quả run nên phải bump RULES_VERSION. **Liam quyết.**

## 1 run lệch replay (#1: live 100, replay 110)
- Chỉ xảy ra ở run STUCK. Trận chưa ngã ngũ ở lượt 60 (giới hạn của bot), còn game thật không có giới hạn này.
- Thử cho bot dừng run ngay tại trận chưa xong: điểm vẫn lệch. Nghĩa là `compute_run_xp` của bot và replay tính khác nhau khi run kết thúc giữa trận. Run thật chỉ có thể kết thúc giữa trận bằng cách bỏ run, và bỏ run thì không có điểm. Nên đây là lệch của công cụ, không phải lỗi người chơi gặp.
- Việc nhỏ cho sau: dạy harness coi run STUCK là skip khi verify. Điều kiện SR-V không đổi.

## Tái hiện
- #1 `--runs=25 --seed=500000 --mission=N2 --stage=3 --anchor=none --kind=mission --policies=attack_spam --verify=1` (run thứ 24)
- #2 `--runs=27 --seed=300000 --asc=0 --stage=3 --anchor=a_mana_mine --force_run_rule=rule_pilot_light --policies=random_legal --verify=1` (run 26)
- #3 `--runs=9 --seed=400000 --asc=0 --stage=3 --anchor=a_mana_mine --force_run_rule=rule_upside_down --policies=expert --verify=1` (run 8)
