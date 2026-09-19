#!/usr/bin/env bash
# Fast GDScript syntax preflight. Run this BEFORE run_tests.sh after editing any .gd file.
#
# WHY THIS EXISTS: a GDScript parse error does not make Godot exit with an error — the
# scene's script simply fails to load, `_ready()` never runs, nobody calls quit(), and the
# process runs forever. That looks exactly like a hung test, and has repeatedly cost hours
# of debugging the wrong thing. This catches it in seconds instead.
#
# NOTE ON FALSE POSITIVES: `--check-only --script` does not register autoloads, so any file
# referencing EventBus/RunState/ContentDB/MetaState/RelicRegistry reports
# "Identifier not found: <Autoload>". Worse, every file that merely *depends* on such a file
# then reports "Failed to compile depended scripts", which cascades across most of the
# project. Both are filtered out: they are artifacts of the check mode, not defects. What
# survives the filter is a genuine root-cause parse/compile error in THIS file.
set -uo pipefail

GODOT="${GODOT:-/Users/loc.tien.nguyen/Desktop/Godot.app/Contents/MacOS/Godot}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJ="$ROOT/godot"
AUTOLOADS='EventBus|RunState|ContentDB|MetaState|RelicRegistry|AxieMixer'

# macOS ships bash 3.2, which has no `mapfile` — read into the array the portable way.
bad=0; total=0
files=()
while IFS= read -r line; do files+=("$line"); done < <(
  find "$PROJ" -name '*.gd' -not -path '*/addons/*' -not -path '*/.godot/*' | sort)
for f in "${files[@]}"; do
  total=$((total+1))
  rel="${f#"$PROJ"/}"
  out="$("$GODOT" --headless --path "$PROJ" --check-only --script "$rel" 2>&1 \
        | grep -E 'Parse Error|Compile Error' \
        | grep -vE "Identifier not found: ($AUTOLOADS)" \
        | grep -vF 'Failed to compile depended scripts' \
        | grep -vF 'referenced non-existent resource')"
  if [[ -n "$out" ]]; then
    bad=$((bad+1))
    printf '\033[31mSYNTAX\033[0m %s\n%s\n' "$rel" "$(sed 's/^/    /' <<<"$out")"
  fi
done

if [[ $bad -eq 0 ]]; then
  echo "syntax OK — $total GDScript files"
else
  echo "$bad file(s) with syntax errors"; exit 1
fi
