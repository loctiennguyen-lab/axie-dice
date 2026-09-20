#!/usr/bin/env bash
# Dọn repo sau pass UI 2026-09-20.
#
#   bash tools/cleanup-2026-09-20.sh            # chỉ xem, không xoá gì
#   bash tools/cleanup-2026-09-20.sh --apply    # xoá thật
#
# Script TỰ KIỂM TRA tại thời điểm chạy thay vì tin một danh sách viết cứng: ảnh QA nào còn được
# một tài liệu trỏ tới thì được giữ, worktree nào còn thay đổi chưa commit thì bị bỏ qua. Nghĩa là
# chạy lại sau này vẫn an toàn kể cả khi repo đã đổi.
#
# KHÔNG đụng tới: src/ api/ production/leaderboard production/session-* third_party/
# node_modules/ build/ AxieDiceTactics.html — bản JS vẫn đang live.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.." || { echo "Không cd được vào gốc repo."; exit 1; }
if [[ ! -d .git || ! -d godot ]]; then
  echo "Đang đứng ở $(pwd) — không thấy .git và godot/."
  echo "Chạy: bash ~/my-game/tools/cleanup-2026-09-20.sh --apply"
  exit 1
fi
APPLY=0; [[ "${1:-}" == "--apply" ]] && APPLY=1
run() { if [[ $APPLY -eq 1 ]]; then eval "$@"; else echo "    [dry-run] $*"; fi; }
hr() { printf '\n%s\n' "── $* ──────────────────────────────────────────"; }

hr "1. Rác đã gom sẵn"
# Gồm: godot-linux-arm64.zip (77MB — binary đã giải nén nằm ở tools/bin/, đã xác minh chạy được
# v4.7.2), 11 script python một-lần-dùng của .tmp-uiedit (mỗi file patch một scene .gd, các patch
# đó đã nằm trong commit rồi), tools/__pycache__, và 4 file probe của phiên 20/09.
# Đã kiểm: không file nào trong repo tham chiếu tới chúng.
if [[ -d _to_delete ]]; then
  echo "  _to_delete/ = $(du -sh _to_delete | cut -f1)"
  run "rm -rf _to_delete"
fi
[[ -d .tmp-uiedit ]] && run "rmdir .tmp-uiedit 2>/dev/null || rm -rf .tmp-uiedit"

hr "2. Ảnh QA mồ côi (18-19/09)"
# 138 ảnh của hai ngày đó, NHƯNG 17 cái vẫn được docs/godot-port-inventory.md,
# docs/godot-port-gap-inventory.md, production/session-state/godot-port-active.md và
# mockups-v2/combat-v2.html trỏ tới đích danh. Danh sách giữ lại được tính lại ngay đây, không
# viết cứng — xoá cả cụm sẽ làm hỏng phần bằng chứng của chính tài liệu port.
REFS=$(mktemp); ORPH=$(mktemp)
# Tuyệt đối, vì đoạn dưới có cd vào thư mục ảnh.
case "$ORPH" in /*) ;; *) ORPH="$PWD/$ORPH";; esac
grep -rhoE '2026-09-[0-9]{2}[A-Za-z0-9_.-]*\.png' \
  docs production .github tools ./*.md 2>/dev/null \
  | sed 's|.*/||' | sort -u > "$REFS"
# `find -printf` và `xargs -a` là GNU-only — macOS không có. Dùng glob + basename thay thế.
: > "$ORPH.all"
for f in production/qa/evidence/2026-09-1[89]*; do
  [ -e "$f" ] || continue
  basename "$f" >> "$ORPH.all"
done
sort -o "$ORPH.all" "$ORPH.all"
comm -23 "$ORPH.all" "$REFS" > "$ORPH"
n=$(wc -l < "$ORPH" | tr -d ' ')
keep=$(( $(wc -l < "$ORPH.all" | tr -d ' ') - n ))
echo "  xoá $n ảnh · giữ $keep ảnh còn được tài liệu trỏ tới"
if [[ $n -gt 0 ]]; then
  if [[ $APPLY -eq 1 ]]; then
    ( cd production/qa/evidence || exit
      while IFS= read -r f; do
        [ -n "$f" ] || continue
        git rm --quiet -- "$f" 2>/dev/null || rm -f -- "$f"
      done < "$ORPH" )
  else
    echo "    [dry-run] git rm $n file trong production/qa/evidence/"
  fi
fi
rm -f "$REFS" "$ORPH" "$ORPH.all"

hr "3. Worktree Claude Code đã xong việc"
# CẢNH BÁO ĐÃ KIỂM: 10/11 nhánh của chúng đã merge hết vào main/godot-port (ahead=0), nên xoá thư
# mục không mất commit nào. Riêng `claude/happy-herschel-e511c5` còn 3 commit chưa merge — commit
# nằm trong .git, KHÔNG nằm trong thư mục worktree, nên vẫn còn nguyên sau khi xoá; chỉ bản
# checkout mất. Nhánh không bị xoá ở đây.
# Worktree nào còn thay đổi chưa commit thì bỏ qua, không hỏi.
for w in .claude/worktrees/*/; do
  [[ -d "$w" ]] || continue
  n=$(basename "$w")
  # `git status` phải CHẠY ĐƯỢC thì mới tin kết quả. Nếu nó lỗi (worktree hỏng, gitdir không
  # resolve được) thì mặc định là GIỮ — không bao giờ xoá dựa trên một câu trả lời không có.
  if ! dirty=$(git -C "$w" status --porcelain 2>/dev/null); then
    echo "  GIỮ  $n — git status không chạy được ở đây, không dám xoá"
    continue
  fi
  d=$(printf '%s' "$dirty" | grep -c . || true)
  if [[ "$d" != "0" ]]; then
    echo "  GIỮ  $n — còn $d file chưa commit"
    continue
  fi
  echo "  xoá  $n ($(du -sh "$w" | cut -f1))"
  run "rm -rf '$w'"
done
run "git worktree prune"

hr "4. File tạm git để lại"
# Sinh ra khi commit từ sandbox không có quyền unlink, cộng với .git/index.lock treo từ 08:34
# sáng 20/09 đã chặn mọi thao tác git trong repo này. `git fsck` đã xác nhận kho object lành.
echo "  $(find .git -name 'tmp_obj_*' | wc -l | tr -d ' ') tmp_obj · $(find .git -name '*.stale*' | wc -l | tr -d ' ') lock cũ"
run "find .git -name 'tmp_obj_*' -delete"
run "find .git -name '*.stale*' -delete"
run "git gc --prune=now --quiet"

hr "KHÔNG xoá, có lý do"
cat <<'NOTE'
  tools/verify.original.mjs   docs/axiedice-source/ORIGINAL_PROJECT_CLAUDE.md dòng 133 ghi rõ
                              "giữ để đối chiếu", và nó khác verify.mjs (543 vs 1231 dòng) —
                              không phải bản sao bỏ quên.
  docs/design-handoff-v2/FIX-PASS-01|02, consistency-sweep, UI-LAWS-BASELINE
                              godot/CLAUDE.md bảo giữ để đọc lại lý do của các quyết định cũ.
  godot/.godot/ (53MB)        cache import, tự sinh lại — nhưng xoá thì lần mở Godot sau mất
                              vài phút re-import. Xoá tay khi nào cần chỗ.
  build/ node_modules/ AxieDiceTactics.html
                              artifact của bản JS đang chạy production. Không đụng.
NOTE

echo
if [[ $APPLY -eq 1 ]]; then
  echo "Xong. Commit phần đã git rm:"
  echo "  git add -A production/qa/evidence && git commit -m 'chore: dọn ảnh QA mồ côi sau pass UI 20/09'"
else
  echo "Đây là dry-run. Chạy lại với --apply để xoá thật."
fi
