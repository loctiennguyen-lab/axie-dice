#!/usr/bin/env bash
# usage: _v5_rules_sim.sh <tag> [sim args...]   (n 126, seed 5000, expert, A0)
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"; T=$1; shift
OUT="$ROOT/production/qa/sim/v5tail/RULES"; mkdir -p "$OUT"
AXIE_HANG_KILL=900 "$ROOT/godot/tools/sim_balance.sh" --runs=126 --seed=5000 --asc=0 --policies=expert --tag=$T --out="$OUT" "$@" >/dev/null 2>&1
python3 - "$OUT" "$T" <<'PY'
import sys,csv,glob,math
f=glob.glob(sys.argv[1]+'/sim-*-'+sys.argv[2]+'.csv')[0]
rows=list(csv.DictReader(open(f))); n=len(rows)
w=sum(int(r['won']) for r in rows); p=w/n; ci=1.96*math.sqrt(p*(1-p)/n)
rule=sum(1 for r in rows if sys.argv[2] in r['rule'] or sys.argv[2].replace('r_','') in r['rule'])
mag=sum(1 for r in rows if 'c_magma_seed' in r['cores']); off=sum(1 for r in rows if 'c_magma_seed' in r['offered'])
fired=sum(1 for r in rows if any(x in r['trig'] for x in ('set_is_king','pilot_light','magma_seed')))
print(f"{sys.argv[2]:12s} n={n} win={100*p:.1f} +-{100*ci:.1f} rule_match={rule} magma_held={mag} fired={fired}")
PY
