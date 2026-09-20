#!/usr/bin/env bash
# Godot test suite runner — single entry point for the godot-port branch.
# Usage: godot/tools/run_tests.sh [godot-binary]
# Runs every res://tests/t_*.tscn headless; a test signals failure by printing
# a line containing "FAIL" (tests also set exit codes via quit(1) where they can).
set -uo pipefail

# Godot binary: the Mac editor build when present, otherwise the Linux build vendored in
# tools/bin/ (container, CI, headless box). Override with GODOT=/path/to/godot.
_default_godot() {
  local root
  root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  local c
  for c in "/Users/loc.tien.nguyen/Desktop/Godot.app/Contents/MacOS/Godot" \
           "$root/tools/bin/Godot_v4.7.2-stable_linux.arm64" \
           "$root/tools/bin/Godot_v4.7.2-stable_linux.x86_64"; do
    [[ -x "$c" ]] && { printf '%s' "$c"; return; }
  done
  command -v godot 2>/dev/null || true
}
GODOT="${1:-${GODOT:-$(_default_godot)}}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJ="$ROOT/godot"

# Godot chỉ đăng ký `class_name` cho script nó đã quét. Một file .gd mới chưa quét làm
# MỌI test tham chiếu tới nó đỏ bằng "Identifier ... not declared in the current scope",
# tức là một lỗi hạ tầng đội lốt 20 lỗi code. Dấu hiệu: .gd không có .uid đi kèm.
unscanned=0
while IFS= read -r f; do
  [[ -f "$f.uid" ]] || unscanned=$((unscanned+1))
done < <(find "$PROJ" -name '*.gd' -not -path '*/addons/*' -not -path '*/.godot/*')
if [[ $unscanned -gt 0 ]]; then
  echo "$unscanned script chưa được Godot quét — nhập lại project trước khi chạy test..."
  "$GODOT" --headless --path "$PROJ" --import >/dev/null 2>&1 \
    || "$GODOT" --headless --path "$PROJ" --editor --quit >/dev/null 2>&1 || true
fi

pass=0; fail=0; failed_names=()

# Two kinds of test live side by side: scene tests (t_*.tscn, a Node _ready())
# and SceneTree tests (t_*.gd with no .tscn, run via --script). Run both.
targets=()
for scene in "$PROJ"/tests/t_*.tscn; do targets+=("scene:$(basename "$scene" .tscn)"); done
for gd in "$PROJ"/tests/t_*.gd; do
  b="$(basename "$gd" .gd)"
  [[ -f "$PROJ/tests/$b.tscn" ]] || targets+=("script:$b")
done

for target in "${targets[@]}"; do
  kind="${target%%:*}"; name="${target#*:}"
  if [[ "$kind" == scene ]]; then
    out="$("$GODOT" --headless --path "$PROJ" "res://tests/$name.tscn" 2>&1)"
  else
    out="$("$GODOT" --headless --path "$PROJ" --script "tests/$name.gd" 2>&1)"
  fi
  code=$?
  # A test fails on a non-zero exit, an engine-level script error, or an explicit
  # "FAIL" verdict. "0 failure(s)" in a passing summary must NOT trip this, hence the
  # word-boundary + explicit-verdict matching rather than a bare `grep -i fail`.
  if [[ $code -ne 0 ]] \
     || grep -qE "SCRIPT ERROR|Parse Error|^ *FAIL|: FAIL|FAILED" <<<"$out" \
     || grep -qE "[^0-9]([1-9][0-9]*) failure" <<<"$out" \
     || ! grep -qi "PASS" <<<"$out"; then
    fail=$((fail+1)); failed_names+=("$name")
    printf '  \033[31mFAIL\033[0m  %s\n' "$name"
    sed -n '1,25p' <<<"$out" | sed 's/^/        /'
  else
    pass=$((pass+1))
    printf '  \033[32mpass\033[0m  %s — %s\n' "$name" "$(grep -m1 -i 'PASS' <<<"$out" | cut -c1-110)"
  fi
done

echo
echo "================ $((pass+fail)) tests: $pass passed, $fail failed ================"
if [[ $fail -gt 0 ]]; then printf 'failed: %s\n' "${failed_names[*]}"; exit 1; fi
