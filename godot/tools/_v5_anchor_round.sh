#!/usr/bin/env bash
# usage: _v5_anchor_round.sh <round> [anchors comma list, default all 6] [n, default 126]
# Forces each Anchor, expert, Short A0, stage 3 (Mana Mine needs stage 3), common seed 5000.
R=${1:?round}; A=${2:-a_kin,a_volley,a_gambler,a_mana_mine,a_big_hand,a_embers}; N=${3:-126}
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
OUT="$ROOT/production/qa/sim/v5tail/$R"; mkdir -p "$OUT"
for a in ${A//,/ }; do
  AXIE_HANG_KILL=900 "$ROOT/godot/tools/sim_balance.sh" --runs=$N --seed=5000 --asc=0 --policies=expert --anchor=$a --out="$OUT" --tag=$a >/dev/null 2>&1
done
python3 - "$OUT" <<'PY'
import sys,csv,glob,math
for f in sorted(glob.glob(sys.argv[1]+'/*.csv')):
    rows=list(csv.DictReader(open(f))); n=len(rows)
    w=sum(int(r['won']) for r in rows); p=w/n; ci=1.96*math.sqrt(p*(1-p)/n)
    held=[r for r in rows if r['anchor']]
    aw=sum(1 for r in held if int(r['aw_node'])>=0)
    print(f"{f.split('sim-')[1][11:-4]:14s} n={n} held={len(held)} win={100*p:.1f} +-{100*ci:.1f} awakened={100*aw/max(1,len(held)):.0f}%")
PY
