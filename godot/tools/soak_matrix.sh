#!/usr/bin/env bash
# Soak theo o: Anchor x Luat run x stage x A0..A9 x Short/Full x normal/mission, moi run replay qua RunVerifier (--verify=1).
# Chia o ra K process nen, moi process dung MOT worktree sim rieng (override.cfg rieng, khoa rieng) qua sim_balance.sh PROJECT=...
#   bash godot/tools/soak_matrix.sh plan            # chi in so o / so run uoc tinh, khong chay
#   bash godot/tools/soak_matrix.sh run             # chay lo lon (dem; KHONG chay cung run_tests.sh)
#   bash godot/tools/soak_matrix.sh report <ngay>   # gom lai CSV + log -> SUMMARY.md
# Bien: SOAK_DATE (mac dinh hom nay) SOAK_SIMS="../my-game-wt/soak-sim1 ..." (mac dinh 3 worktree canh repo, tu tao detached tu HEAD)
#       N_FAST=30 (run/o bot nhanh) N_EXPERT=13 (run/o expert) AXIE_HANG_KILL=900 (moi o)
# Ra: production/qa/soak/<ngay>/{cells/<o>/sim-*.csv, logs/<o>.log, SUMMARY.md}. Log moi o co exit code o dong cuoi ("EXIT n").
# Uoc: ~24.000 run nhanh (~0,1 s) + ~3.100 run expert (~1 s) = ~1,5 gio tren 3 process (do lo thu: expert ~0,8 s/run kem verify).
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
CMD="${1:-plan}"
DATE="${SOAK_DATE:-${2:-$(date +%Y-%m-%d)}}"
OUT="$ROOT/production/qa/soak/$DATE"
N_FAST="${N_FAST:-30}"; N_EXPERT="${N_EXPERT:-13}"
ANCHORS=(a_volley a_gambler a_mana_mine a_kin a_embers a_big_hand none)
ASC_ALL="0,1,2,3,4,5,6,7,8,9"
# Luat run: moi luat khong phai test (rule_test_*); luat dang tat van duoc ep (force_run_rule) de bat loi luong.
RULES=$(grep -l 'core_axis = "run_rule"' "$ROOT"/godot/resources/relics/*.tres 2>/dev/null | xargs -n1 basename | sed 's/.tres//' | grep -v '^rule_test_' | tr '\n' ' ')

cells() {   # in: ten|--tham-so... (moi dong mot o)
  local a st md pol
  for a in "${ANCHORS[@]}"; do
    for st in 1 2 3; do
      [[ "$a" != none && $st == 1 ]] && continue          # Anchor chi tu stage 2
      for md in short full; do
        echo "fastN_${a}_s${st}_${md}|--runs=$N_FAST --seed=100000 --asc=$ASC_ALL --mode=$md --stage=$st --anchor=$a --policies=random_legal,attack_spam"
      done
      echo "expN_${a}_s${st}|--runs=$N_EXPERT --seed=200000 --asc=0,5,9 --mode=short --stage=$st --anchor=$a --policies=expert"
    done
    for r in $RULES; do
      echo "fastR_${a}_${r}|--runs=$N_FAST --seed=300000 --asc=0 --stage=3 --anchor=$a --force_run_rule=$r --policies=random_legal"
      echo "expR_${a}_${r}|--runs=$N_EXPERT --seed=400000 --asc=0 --stage=3 --anchor=$a --force_run_rule=$r --policies=expert"
    done
    for t in N1 N2 N3 N4 N5 N6; do
      echo "fastM_${a}_${t}|--runs=$N_FAST --seed=500000 --mission=$t --stage=3 --anchor=$a --kind=mission --policies=random_legal,attack_spam"
      echo "expM_${a}_${t}|--runs=$N_EXPERT --seed=600000 --mission=$t --stage=3 --anchor=$a --kind=mission --policies=expert"
    done
  done
}

if [[ "$CMD" == plan ]]; then
  cells | awk -F'|' '{n=0; r=1; split($2,a," "); for(i in a){ if(a[i] ~ /^--runs=/){split(a[i],b,"="); n=b[2]} if(a[i] ~ /^--asc=/){split(a[i],c,"="); r=split(c[2],d,",")} if(a[i] ~ /^--policies=/){split(a[i],e,"="); p=split(e[2],f,",")}} if($1 ~ /^fast/) F+=n*r*p; else X+=n*r*p; C++} END{print C" o, ~"F" run nhanh, ~"X" run expert (chua tru o N6 chi Full va skip_forced)"}'
  exit 0
fi

if [[ "$CMD" == report ]]; then
  python3 - "$OUT" <<'PY'
import sys,glob,csv,re,collections
out=sys.argv[1]; end=collections.Counter(); ver=collections.Counter(); bad=[]; n=0
for f in glob.glob(out+'/cells/*/sim-*.csv'):
    for r in csv.DictReader(open(f)):
        n+=1; end[r.get('end','?')]+=1; v=r.get('verify','?'); ver[v.split(':')[0] if v.startswith('diff') else v]+=1
        # skip_stuck (end=STUCK_TURNS, not replayed) is counted in the verify line on its own and is NOT a bad verify;
        # the run still shows below when its end is STUCK, because a stuck fight is its own finding.
        if r.get('end','').startswith('STUCK') or v not in ('ok','skip_forced','skip_stuck'):
            bad.append(f"seed={r['seed']} policy={r['policy']} team={r['team']} asc={r['asc']} cfg={r['cfg']} anchor={r['anchor']} rule={r['rule']} end={r['end']} verify={v} {r.get('vdetail','')}  [{f.split('/')[-2]}]")
logs=collections.Counter(); lines=[]
for f in glob.glob(out+'/logs/*.log'):
    t=open(f,errors='replace').read()
    for k in ('SCRIPT ERROR','Parse Error','ERROR:'):
        c=t.count(k)
        if c: logs[k]+=c; lines.append(f"{k} x{c} in {f.split('/')[-1]}")
    m=re.findall(r'EXIT (\d+)',t)
    if not m or m[-1]!='0': logs['cell_exit_nonzero_or_missing']+=1; lines.append(f"EXIT {m[-1] if m else 'none'} in {f.split('/')[-1]}")
s=f"# Soak {out.split('/')[-1]}\n\n- run: {n}\n- end: {dict(end)}\n- verify: {dict(ver)}\n- log: {dict(logs)}\n- run xau: {len(bad)}\n\n## Run xau (seed de tai hien)\n"+"\n".join("- "+b for b in bad[:200])+"\n\n## Log\n"+"\n".join("- "+l for l in lines[:100])+"\n"
open(out+'/SUMMARY.md','w').write(s); print(s[:1500])
PY
  exit 0
fi

# ---- run
SIMS=(${SOAK_SIMS:-})
if [[ ${#SIMS[@]} -eq 0 ]]; then
  for i in 1 2 3; do SIMS+=("$(dirname "$ROOT")/soak-sim$i"); done
fi
for w in "${SIMS[@]}"; do
  if [[ ! -d "$w" ]]; then git -C "$ROOT" worktree add --detach "$w" HEAD >/dev/null || exit 1; fi
  git -C "$w" checkout -q --detach "$(git -C "$ROOT" rev-parse HEAD)" 2>/dev/null || { echo "worktree $w sai trang thai"; exit 1; }
  if [[ ! -f "$w/godot/override.cfg" ]]; then
    printf '[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="AxieDice-wt-%s"\n' "$(basename "$w")" > "$w/godot/override.cfg"
  fi
done
mkdir -p "$OUT/cells" "$OUT/logs" "$OUT/jobs"
rm -f "$OUT"/jobs/job*.txt
K=${#SIMS[@]}; i=0
cells | while IFS= read -r line; do echo "$line" >> "$OUT/jobs/job$((i % K)).txt"; i=$((i+1)); done
export GODOT="${GODOT:-/Users/loc.tien.nguyen/Desktop/Godot.app/Contents/MacOS/Godot}" AXIE_HANG_KILL="${AXIE_HANG_KILL:-900}"
worker() {   # $1=worktree $2=job file
  while IFS='|' read -r name args; do
    [[ -z "$name" ]] && continue
    mkdir -p "$OUT/cells/$name"
    # shellcheck disable=SC2086
    PROJECT="$1/godot" bash "$ROOT/godot/tools/sim_balance.sh" $args --verify=1 --dump_fail="$OUT/dump/$name" --out="$OUT/cells/$name" --tag="$name" > "$OUT/logs/$name.log" 2>&1
    echo "EXIT $?" >> "$OUT/logs/$name.log"
  done < "$2"
}
for ((j=0; j<K; j++)); do worker "${SIMS[$j]}" "$OUT/jobs/job$j.txt" & echo "worker $j pid $!"; done
echo "Da chay nen. Khi xong: bash godot/tools/soak_matrix.sh report $DATE"
