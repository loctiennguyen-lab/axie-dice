#!/usr/bin/env bash
# Dọn dẹp repo sau pass UI 2026-09-20.
#
# VÌ SAO LÀ MỘT SCRIPT CHỨ KHÔNG PHẢI ĐÃ XOÁ SẴN: phiên làm việc chạy trong sandbox không có
# quyền xoá file trong thư mục này, chỉ có quyền đổi tên. Những gì đổi tên được thì đã nằm sẵn
# trong `_to_delete/`. Phần còn lại cần `rm` và `git rm` thật, nên ở đây.
#
#   bash tools/cleanup-2026-09-20.sh --dry-run    # xem sẽ xoá gì (mặc định)
#   bash tools/cleanup-2026-09-20.sh --apply      # xoá thật
#
# Tổng thu hồi: ~380 MB. Không đụng tới `src/`, `api/`, `production/leaderboard`,
# `production/session-*`, `third_party/`, `node_modules/`, `build/` hay bản deploy JS đang live.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

APPLY=0
[[ "${1:-}" == "--apply" ]] && APPLY=1
run() { if [[ $APPLY -eq 1 ]]; then eval "$@"; else echo "  would run: $*"; fi; }
size() { du -sh "$1" 2>/dev/null | cut -f1; }

echo "== 1. Tám worktree Claude Code đã chết ($(size .claude/worktrees)) =="
# `git worktree list` tự đánh dấu cả tám là `prunable`: chúng là checkout của các phiên agent đã
# kết thúc. `prune` gỡ đăng ký, thư mục thì phải xoá tay.
run "git worktree prune"
for w in .claude/worktrees/*/; do
  [[ -d "$w" ]] || continue
  run "rm -rf '$w'"
done

echo "== 2. Rác đã gom sẵn ($(size _to_delete)) =="
# godot-linux-arm64.zip (77M, đã giải nén sang tools/bin/), 11 script python một lần dùng của
# .tmp-uiedit, __pycache__, và 4 file probe của phiên này.
run "rm -rf _to_delete .tmp-uiedit"

echo "== 3. Ảnh QA đã bị thay thế (124M, 138 file ngày 18-19/09) =="
# 27 ảnh ngày 20/09 là bằng chứng hiện hành và được giữ lại.
run "git rm -r --quiet 'production/qa/evidence/2026-09-18_*' 'production/qa/evidence/2026-09-19_*'"

echo "== 4. Bản sao lưu bỏ quên =="
run "git rm --quiet tools/verify.original.mjs"

echo "== 5. Object tạm và lock cũ trong .git =="
# Sinh ra khi sandbox commit mà không unlink được, cộng với .git/index.lock treo từ 08:34 sáng.
run "find .git -name 'tmp_obj_*' -delete"
run "find .git -name '*.stale*' -delete"
run "git gc --prune=now --quiet"

echo
if [[ $APPLY -eq 1 ]]; then
  echo "Xong. Nhớ commit phần git rm:  git commit -m 'chore: dọn ảnh QA và file thừa sau pass UI'"
else
  echo "Đây là dry-run. Chạy lại với --apply để xoá thật."
fi
