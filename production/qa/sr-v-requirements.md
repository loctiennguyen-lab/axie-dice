# SR-V — điều kiện bắt buộc trước khi verifier được TỪ CHỐI/THƯỞNG theo kết quả (review bảo mật 26/10)

Hiện verifier chỉ chạy bóng (ghi nhận). Trước khi dùng nó để chặn hay trả tiền:
1. Tape header (mission, depth_stage) do SERVER dựng từ D1 (`runs` + `mission_escrow`), không lấy `epochs.extra`/tape do client gửi. Kiểm `meta.mode=='mission'` ⇔ tape có mission.
2. Loadout/bonuses do server dựng (unlock trong D1 bảng `unlocks` từ 0011 sau R3) và truyền vào tham số `loadout` của `RunVerifier.verify` (thắng header log). Perks trong cloud save không tin được: hoặc đưa perks lên server, hoặc (cần Liam duyệt, đổi luật) ép bonus run Nhiệm vụ về 0 như ranked.
3. Client cũ (desktop ≤ b1705) không chép mission vào tape: nếu làm (1) thì không ảnh hưởng; nếu chưa, đừng bật verify bắt buộc cho Nhiệm vụ tới khi bản cũ hết dùng.
Nguồn: review `a92ee20`, `2997f35` (security-engineer, APPROVE WITH CONDITIONS).
