#!/usr/bin/env bash
# Replays submitted run records through the real game rules and reports the score the referee
# computes — the Godot equivalent of what api/submit-run.js does for the live JS build.
#
# Runs the same way locally and in CI, on purpose: a verification path that only exists inside
# a workflow file is one nobody can reproduce when it disagrees with a player.
#
# Usage:
#   tools/verify_runs.sh                      # golden + every record in production/leaderboard/records
#   tools/verify_runs.sh path/to/record.json  # one record
#   GODOT=/path/to/godot tools/verify_runs.sh
#
# Exit codes: 0 every record verified · 1 a record was REFUSED · 2 the tool could not run.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJ="$ROOT/godot"
GOLDEN_DIR="$ROOT/production/leaderboard/golden"
RECORDS_DIR="$ROOT/production/leaderboard/records"
OUT_DIR="${VERIFY_OUT_DIR:-$ROOT/production/leaderboard/verdicts}"

GODOT="${GODOT:-}"
if [[ -z "$GODOT" ]]; then
  for candidate in \
    "/Users/loc.tien.nguyen/Desktop/Godot.app/Contents/MacOS/Godot" \
    "$(command -v godot || true)" \
    "$ROOT/.godot-bin/godot"; do
    [[ -n "$candidate" && -x "$candidate" ]] && GODOT="$candidate" && break
  done
fi
if [[ -z "$GODOT" || ! -x "$GODOT" ]]; then
  echo "verify_runs: no Godot binary. Set GODOT=/path/to/godot." >&2
  exit 2
fi

# Wiped, not merged. Verdicts are OUTPUT: leaving yesterday's behind puts a run on the board
# that nobody submitted any more, and the board is supposed to be a function of the records
# that exist right now.
rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

# Import once. A fresh checkout has no .godot/ cache, and running a scene before the project
# has been imported fails in ways that read as missing files — and a new class_name stays
# invisible until an import registers it.
echo "==> importing project (first run on a fresh checkout takes a while)"
"$GODOT" --headless --path "$PROJ" --import >/dev/null 2>&1 || true

fail=0
verified=0
refused=0

verify_one() {
  local record="$1"
  local prefix="${2:-}"
  # Golden records are prefixed so the leaderboard builder can tell them apart. They are a bot
  # run kept as a determinism check, and a board that ranked them would be ranking the test
  # fixture alongside the players.
  local name; name="$prefix$(basename "$record" .json)"
  local out="$OUT_DIR/$name.verdict.json"
  # The tool prints its verdict on a line prefixed VERDICT_JSON and also writes it to --out;
  # the file is what everything downstream reads, so a change to Godot's startup chatter can
  # never break the parse.
  "$GODOT" --headless --path "$PROJ" res://tools/verify_run.tscn -- \
    --log="$record" --out="$out" >/dev/null 2>&1
  local code=$?
  if [[ ! -s "$out" ]]; then
    echo "  ERROR  $name — the verifier produced no verdict (exit $code)" >&2
    fail=1
    return
  fi
  local ok score err msg
  ok=$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['ok'])" "$out")
  score=$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['score'])" "$out")
  err=$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['error'])" "$out")
  msg=$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['message'])" "$out")
  if [[ "$ok" == "True" ]]; then
    echo "  ok     $name — score $score"
    verified=$((verified+1))
  else
    echo "  REFUSED $name — $err: $msg"
    refused=$((refused+1))
  fi
}

# ---- golden records first -------------------------------------------------
# These are real runs with their score written down on the machine that played them. They are
# not a sample of the submission flow; they are the cross-platform determinism check. If the
# referee scores one of them differently here than it did there, every verdict this run
# produces is worthless, so nothing else is even attempted.
echo "==> golden records (cross-platform determinism)"
golden_failed=0
shopt -s nullglob
for record in "$GOLDEN_DIR"/*.json; do
  [[ "$record" == *.expected.json ]] && continue
  name="$(basename "$record" .json)"
  expected="$GOLDEN_DIR/$name.expected.json"
  verify_one "$record" "golden__"
  out="$OUT_DIR/golden__$name.verdict.json"
  if [[ -s "$expected" && -s "$out" ]]; then
    if ! python3 - "$expected" "$out" "$name" <<'PY'
import json, sys
exp = json.load(open(sys.argv[1])); got = json.load(open(sys.argv[2])); name = sys.argv[3]
problems = []
if int(exp["score"]) != int(got.get("score", -1)):
    problems.append("score %s here vs %s where it was recorded" % (got.get("score"), exp["score"]))
if bool(exp["won"]) != bool(got.get("won", False)):
    problems.append("won=%s here vs %s there" % (got.get("won"), exp["won"]))
if problems:
    print("  DETERMINISM FAILURE  %s — %s" % (name, "; ".join(problems)))
    print("  This means the same run scores differently on different machines. An honest")
    print("  player would be called a cheat by a referee running elsewhere. Do not ship a")
    print("  leaderboard until this is understood.")
    sys.exit(1)
print("  golden ok  %s — score %s matches the machine that recorded it" % (name, got.get("score")))
PY
    then
      golden_failed=1
    fi
  fi
done

if [[ $golden_failed -ne 0 ]]; then
  echo "==> refusing to verify submissions while a golden record disagrees" >&2
  exit 1
fi

# ---- submissions ----------------------------------------------------------
records=()
if [[ $# -gt 0 ]]; then
  records=("$@")
else
  for record in "$RECORDS_DIR"/*.json; do records+=("$record"); done
fi

if [[ ${#records[@]} -eq 0 ]]; then
  echo "==> no submitted records"
else
  echo "==> submitted records"
  for record in "${records[@]}"; do verify_one "$record"; done
fi

echo
echo "================ $verified verified, $refused refused ================"
[[ $fail -ne 0 ]] && exit 2
[[ $refused -gt 0 ]] && exit 1
exit 0
