#!/usr/bin/env bash
# Sim can bang Axie Dice (headless, tat dinh theo seed, khong mang, save that duoc SaveGuard giu).
# 1) Chay:  godot/tools/sim_balance.sh --runs=200 --seed=1000 --asc=0 --policies=attack_spam,expert,random_legal
# 2) Tham so: --runs (moi chinh sach) --seed --asc=0,3,5 --teams=all|beast_bird,... --cores=mix|random|greedy_axis|combo --tag=ten
#    Chinh sach: random_legal attack_spam attack_only greedy expert. Gop/dung lai bao cao tu CSV: --from=a.csv,b.csv --tag=ten
# 3) Nhanh khac: PROJECT=/duong/dan/worktree/godot godot/tools/sim_balance.sh ...  (copy 3 file sim vao project do, import, chay;
#    bao cao ra <worktree>/production/qa/sim). Chi can nhanh do co engine/Loi/RunState cung API (xem run_bot.gd).
# 4) Ra: production/qa/sim/sim-<ngay>-<tag>.md (co dong DAT/CHUA DAT cho muc tieu) + .csv (moi run mot dong).
# 5) Toc do: ~0.08s/run bot thuong, ~0.9s/run expert; chia lo <= 600s (expert ~500 run/lo). AXIE_HANG_KILL mac dinh 900s.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
GODOT="${GODOT:-/Users/loc.tien.nguyen/Desktop/Godot.app/Contents/MacOS/Godot}"
export AXIE_HANG_KILL="${AXIE_HANG_KILL:-900}"
PROJ="${PROJECT:-$HERE/..}"
if [[ "$(cd "$PROJ" && pwd -P)" != "$(cd "$HERE/.." && pwd -P)" ]]; then
  mkdir -p "$PROJ/tools"
  for f in sim_balance.gd sim_balance.tscn sim_report.gd; do cp "$HERE/$f" "$PROJ/tools/$f"; done
  "$PROJ/tools/with_lock.sh" "$GODOT" --headless --path "$PROJ" --import >/dev/null 2>&1 || true
  exec "$PROJ/tools/with_lock.sh" "$GODOT" --headless --path "$PROJ" res://tools/sim_balance.tscn -- "$@"
fi
exec "$HERE/with_lock.sh" "$GODOT" --headless --path "$HERE/.." res://tools/sim_balance.tscn -- "$@"
