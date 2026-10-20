#!/usr/bin/env bash
# Sim can bang Axie Dice (headless, tat dinh theo seed, khong mang, save that duoc SaveGuard giu).
# 1) Chay:  godot/tools/sim_balance.sh --runs=200 --seed=1000 --asc=0 --policies=attack_spam,greedy,random_legal
# 2) Tham so: --runs (moi chinh sach) --seed (goc) --asc=0,3,5 --teams=all|beast_bird,... --cores=mix|random|greedy_axis --tag=ten
# 3) Doi: beast_bird aqua_plant reptile_bug mixed_std mixed_dmg tank_heavy (xoay vong theo seed); --cores=mix doi Loi random/greedy_axis.
# 4) Ra: production/qa/sim/sim-<ngay>-<tag>.md (bao cao) + .csv (moi run mot dong, de gop/phan tich them).
# 5) Toc do ~0.1s/run; chia lo <= 600s neu chay vai chuc nghin run. Lock/hang-kill: AXIE_HANG_KILL (mac dinh 900s).
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
GODOT="${GODOT:-/Users/loc.tien.nguyen/Desktop/Godot.app/Contents/MacOS/Godot}"
export AXIE_HANG_KILL="${AXIE_HANG_KILL:-900}"
exec "$HERE/with_lock.sh" "$GODOT" --headless --path "$HERE/.." res://tools/sim_balance.tscn -- "$@"
