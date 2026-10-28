#!/usr/bin/env bash
# Validate a candidate tokens.json (Claude Design drop) before it replaces
# godot/assets/data/ui/tokens_ui3.json. No Godot needed.
# Usage: godot/tools/check_tokens.sh <path/to/tokens.json>
# Exit 0 = OK (warnings allowed), 1 = missing key / wrong type / bad value, 2 = usage.
# Lists: keys the code reads that are missing, current keys that vanished, type changes,
# extra keys (ignored by the game), and every value that changed.
set -euo pipefail
if [[ $# -lt 1 || ! -f "$1" ]]; then
  echo "usage: godot/tools/check_tokens.sh <tokens.json>" >&2
  exit 2
fi
exec python3 -I "$(cd "$(dirname "$0")" && pwd)/check_tokens.py" "$@"
