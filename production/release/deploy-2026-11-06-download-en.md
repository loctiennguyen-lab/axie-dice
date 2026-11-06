# Deploy 6/11 khuya: trang /download sang tiếng Anh (Liam: "tôi muốn ngôn ngữ phải là tiếng Anh", "Deploy đi")

## Bản đưa lên
- Chỉ Worker. Đổi `worker/src/downloads.js`: toàn bộ chữ trên trang /download + 2 câu 503 sang tiếng Anh, `lang="en"`. Logic, link, header không đổi.
- `worker/test/download_route.test.mjs`: kiểm chữ tiếng Anh + `lang="en"`.
- Từ bản live trước (bd77027e, deploy 5/11 ở fccbd25) tới nay, `worker/` chỉ khác 2 file này.
- Game (web pck 02fe988a, desktop b2484), RULES_VERSION -w: không đổi.

## Kiểm
- Worker 398/398. Review lead-programmer: APPROVE, đã sửa 2 câu theo góp ý.
- Worker mới: **dbe22412-230b-46f5-b2ee-63efa7487dd2** (wrangler 4.151.3).
- Sau deploy: /download hiện `lang="en"`, title, h1, nút "Download for macOS (284.3 MB)" / "Download for Windows (261.8 MB)", 0 ký tự tiếng Việt. Hai zip HEAD 200, đúng dung lượng (298113357 / 274541106). `/` và `/api/leaderboard` 200.
- Trang có `Cache-Control: max-age=60`, nên ai vừa mở có thể thấy bản cũ tối đa 1 phút.

## Rollback
- `cd worker && npx wrangler@4.151.3 rollback bd77027e-1b21-4ce9-af64-9052b219a29f`
