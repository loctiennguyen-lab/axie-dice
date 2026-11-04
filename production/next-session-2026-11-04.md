# Bàn giao cho session mới (4/11/2026)

## Prompt dán vào session mới
> Đọc `production/next-session-2026-11-04.md`. Tôi gửi bản art lượt 1 của Claude Design kèm theo. Làm theo mục "Nhận bản Claude Design". Luật làm việc ở `CLAUDE.md`. Hỏi tôi trước khi deploy.

## Trạng thái (live trên axiedice.fun)
- `godot-port` @ 398e1b9, push lên `axiedice/main`.
- Live:
  - Worker `ae8f917a`;
  - web pck `a7ef2613`;
  - desktop b2435;
  - RULES_VERSION `godot-2026-11-03-w`.

  Ghi chép đợt deploy: `production/release/deploy-2026-11-03-polish1.md`.
- Polish đợt 1 xong 23 mục (`production/polish-0311-list.md`, `production/polish-0311-plan.md`), kèm 2 sửa luật:
  - ô relic cũ / pact không đếm Lõi;
  - sửa kẹt run khi bán Lõi trong bảng Make room.
- Hiệu ứng Lõi / Anchor kích hoạt: ô sáng + nổ VFX kỹ năng trên đích + chữ trên đầu đích, không còn hạt bay. Liam đã chọn kiểu này.
- Suite sàn 344 (AXIE_RELEASE=1 cần `AXIE_HANG_KILL=4500`). Worker 397.
- Đã xong và live từ trước: UI-06, UI-07 (màn đăng nhập, đã sửa 2 lần), thay icon theo lựa chọn của Liam 2/11.

## Nhận bản Claude Design (việc đầu tiên)
Brief: `design/handoffs/art-redo-0311/PROMPT-batch1.md`. Zip đã gửi: `design/handoffs/art-redo-0311/send/AxieDice-art-batch1.zip`. Bảng tồn kho: `production/art-redo-0311-inventory.md`.

Lượt 1 là 23 món thẻ Lõi. Claude Design vẽ thử 3 món trước rồi dừng: `frame_core_amber`, `family_stat`, `slot_moss`.

1. Giải nén bản giao vào `design/handoffs/art-redo-0311/round-1/_zip/` (không `git add` thư mục `_zip/`). Đọc README / báo cáo tự kiểm của nó.
2. Load skill `game-art-reskin-design`. Đo từng món theo bảng ngưỡng của skill: near-black, min V, coverage, grain, số màu. Dùng python + numpy/PIL nếu có; máy này thiếu PIL thì dùng `sips` hoặc chạy trong Godot.
3. Dựng sheet so sánh: món mới cạnh món kho đã bám (ảnh kho nằm trong `library/` của zip).
4. Kiểm luật cứng:
   - không Axie, không sinh vật, không mặt hay mắt;
   - không chữ, không viền đen;
   - ngôi sao lấp lánh chỉ trên đá quý, kính, nhẫn;
   - crest để trống ô giữa (Ø42 tại (80,46));
   - nine-patch giữ đúng margin, tâm khung và cửa sổ trong suốt.
5. Cho **art-director** soát độc lập, rồi đưa Liam: sheet + số đo + kết luận. **Liam duyệt thì Claude Design mới vẽ tiếp 20 món** của lượt 1.
6. Khi có đủ 23 món:
   - đưa vào game qua `godot/scenes/shared/ui6/UI6Assets.gd`, thay file `godot/assets/ui6/...` cùng tên, `--import`;
   - test: `t_ui6_kit`, `t_ui6_core_offer`, `t_ui6_owned_cores`, `t_ui6_anchor_dropb`, `t_ui5_shop`, `t_assets`;
   - chụp 1920 + 1280, review, QA, rồi hỏi Liam deploy.
7. Sau lượt 1, theo bảng tồn kho:
   - **lượt 2**: 6 pact còn lại, Gambler, 6 glyph UI, buff;
   - **lượt 3–4**: cosmetics (26 skin + khung);
   - **gói D**: `icons/hl` + `cur_*`.

   Huy hiệu nhà dùng **vật thật từ kho** (Liam đã chọn), không vẽ. Brief mỗi lượt theo skill `game-art-reskin-design`: vẽ thử 3 món, dừng, Liam duyệt.

## Việc polish còn sót (nhỏ, chưa làm)
- QA chưa chạy thật tới shop, bảng Make room, boss của run có Anchor (seed đổi sau -w nên bot thua sớm). Cần seed hoặc driver đi tới được; ranked seed 59 thì đã qua boss.
- Từ review hình (art-director):
  - vài chữ ~13 px (dưới luật 14 px): mô tả thẻ Lõi, chip House Core, chữ phụ ở màn đăng nhập, nhãn nút công cụ — cần đo;
  - event còn hiện "Event · Row 0" và dùng từ "relic" (nên là "Core");
  - Egg die chưa có icon trứng;
  - #5 chưa có ảnh lý do của Wild / Hold / Undo;
  - nửa dưới thẻ thưởng và thẻ Anchor vẫn trống;
  - màn kết quả Defeated ghi "+0" cạnh "87 run payout" dễ hiểu nhầm.
- Nhỏ (review code):
  - `t_ui5_core_swap_take` chưa có ca Esc, Eternal và RunVerifier;
  - `t_core_offer_no_owned` chưa assert offer khác rỗng;
  - Forced pact mà mọi relic đều Eternal thì không có lối ra: kiểm luật.
  - `RunMapController` bỏ qua kết quả trả về của `apply_chosen_reward`.

## Câu hỏi / việc chờ Liam
- Verifier đang tính run thường là "lệch" (`not_ranked`). Đề xuất bỏ qua run không ranked.
- Danh sách Liam tự làm trước khi mở cho tester ngoài: mục "Danh sách Liam tự làm" ở `production/next-session-2026-11-02.md`, gồm mua Nhiệm vụ N1, rớt mạng, hai thiết bị, tài khoản mới, Windows, notarize mac, RTT, logo Google.
- Viết lại kế hoạch phase sau L1. Kế hoạch dùng máy Mac làm server 24/24.

## Máy
- Worktree còn giữ:
  - `u5b-0`: chạy cổng phát hành;
  - `verifier`: đang chạy;
  - `agent-ab462…`: một phiên khác đang khoá.
- Các worktree polish (`pl-*`, `u6-fin`, `u6-qa`, `u6-art`) đã gộp hết. Xoá khi Liam đồng ý.
- Bản lùi web: `build/web-prev/` (pck 7ec48c9a), cùng `build/web-prev-f8f4f45e/`, `build/web-prev-ce820681/`.
- Ảnh QA đợt này ở `production/qa/polish-0311/`. Ảnh trong các worktree `pl-*` chưa commit hết.
