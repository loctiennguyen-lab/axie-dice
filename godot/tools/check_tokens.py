#!/usr/bin/env python3
"""Check a candidate tokens.json (e.g. from a Claude Design zip) against what the game reads.

Usage: python3 check_tokens.py <candidate.json> [--baseline <current tokens_ui3.json>]

Exit 0 = safe to drop in (warnings allowed), 1 = something the game reads is missing or has the wrong
type. Three checks:
  1. USED keys: every UI3Theme.color/size_of/size_dict/radius/space/stroke/motion_sec("key") literal found
     in godot/scenes + godot/scripts must exist in the candidate with the right type (this is the one
     that crashes or paints magenta if it fails).
  2. Baseline diff: every leaf path in the current tokens_ui3.json must exist in the candidate with the
     same type (missing / type mismatch = error). Paths only in the candidate = "extra" (warning: the
     game will ignore them until code reads them).
  3. Values: colours must be #rrggbb or #rrggbbaa, sizes/radii/spaces/strokes/motion numbers must be
     non-negative numbers. Changed values are listed (informational, so you can eyeball the round).
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
GODOT = os.path.dirname(HERE)
BASELINE = os.path.join(GODOT, "assets", "data", "ui", "tokens_ui3.json")
HEX = re.compile(r"^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$")

# accessor -> (group, kind). kind: color | num | pair
ACCESSORS = {
    "color": ("color", "color"),
    "size_of": ("size", "num"),
    "size_dict": ("size", "pair"),
    "radius": ("radius", "num"),
    "space": ("space", "num"),
    "stroke": ("stroke", "num"),
    "motion_sec": ("motion", "num"),
}


def leaves(d, prefix=""):
    """Flatten to {path: value}; colour entries {"value": "#..", "meaning": ..} collapse to their value."""
    out = {}
    for k, v in d.items():
        if k.startswith("$") or k.startswith("_"):
            continue
        p = prefix + k
        if isinstance(v, dict) and "value" in v and isinstance(v["value"], str) and prefix.startswith("color."):
            out[p] = v["value"]
        elif isinstance(v, dict):
            if prefix == "color." or (prefix == "" and k == "color"):
                pass
            out.update(leaves(v, p + "."))
        elif isinstance(v, list) and k == "contrast":
            out[p] = "[contrast]"
        else:
            out[p] = v
    return out


def color_leaves(tokens):
    return {k: (v.get("value") if isinstance(v, dict) else v) for k, v in tokens.get("color", {}).items()
            if not k.startswith("$")}


def kind_of(v):
    if isinstance(v, bool):
        return "bool"
    if isinstance(v, (int, float)):
        return "number"
    if isinstance(v, str):
        return "string"
    if isinstance(v, list):
        return "list"
    if isinstance(v, dict):
        return "object"
    return "null"


def used_keys():
    pat = re.compile(r'UI3Theme\.(color|size_of|size_dict|radius|space|stroke|motion_sec)\(\s*"([A-Za-z0-9_]+)"')
    found = {}
    for top in ("scenes", "scripts", "tests"):
        for dp, _, fs in os.walk(os.path.join(GODOT, top)):
            for f in fs:
                if not f.endswith(".gd"):
                    continue
                path = os.path.join(dp, f)
                rel = os.path.relpath(path, GODOT)
                with open(path, encoding="utf-8") as fh:
                    for i, line in enumerate(fh, 1):
                        for m in pat.finditer(line):
                            found.setdefault((m.group(1), m.group(2)), []).append("%s:%d" % (rel, i))
    return found


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    cand_path = argv[1]
    base_path = BASELINE
    if "--baseline" in argv:
        base_path = argv[argv.index("--baseline") + 1]
    try:
        cand = json.load(open(cand_path, encoding="utf-8"))
    except Exception as e:  # noqa: BLE001
        print("ERROR: cannot parse %s: %s" % (cand_path, e))
        return 1
    base = json.load(open(base_path, encoding="utf-8"))
    errors, warns, changed = [], [], []

    # 1. keys the code reads
    for (acc, key), where in sorted(used_keys().items()):
        group, kind = ACCESSORS[acc]
        grp = cand.get(group, {})
        if key not in grp:
            errors.append("MISSING %s.%s (read by UI3Theme.%s at %s)" % (group, key, acc, where[0]))
            continue
        v = grp[key]
        if kind == "color":
            val = v.get("value") if isinstance(v, dict) else None
            if not isinstance(val, str) or not HEX.match(val):
                errors.append("BAD colour %s.%s = %r (need {\"value\": \"#rrggbb[aa]\"})" % (group, key, v))
        elif kind == "num":
            if isinstance(v, bool) or not isinstance(v, (int, float)) or v < 0:
                errors.append("BAD number %s.%s = %r (read by UI3Theme.%s at %s)" % (group, key, v, acc, where[0]))
        elif kind == "pair":
            if not (isinstance(v, dict) and "w" in v and "h" in v):
                errors.append("BAD pair %s.%s = %r (need {w,h})" % (group, key, v))

    # 2. baseline diff (colours handled separately because they are {value, meaning} objects)
    bcol, ccol = color_leaves(base), color_leaves(cand)
    for k in bcol:
        if k not in ccol:
            errors.append("MISSING color.%s (in current tokens)" % k)
        elif not isinstance(ccol[k], str) or not HEX.match(ccol[k]):
            errors.append("BAD colour color.%s = %r" % (k, ccol[k]))
        elif ccol[k].lower() != str(bcol[k]).lower():
            changed.append("color.%s: %s -> %s" % (k, bcol[k], ccol[k]))
    for k in ccol:
        if k not in bcol:
            warns.append("EXTRA color.%s (game ignores it until code reads it)" % k)
    b2 = {k: v for k, v in leaves({g: base[g] for g in base if g not in ("color", "contrast")}).items()}
    c2 = {k: v for k, v in leaves({g: cand[g] for g in cand if g not in ("color", "contrast")}).items()}
    for k, v in b2.items():
        if k not in c2:
            errors.append("MISSING %s (in current tokens)" % k)
        elif kind_of(c2[k]) != kind_of(v):
            errors.append("TYPE %s: was %s, now %s (%r)" % (k, kind_of(v), kind_of(c2[k]), c2[k]))
        elif c2[k] != v:
            changed.append("%s: %r -> %r" % (k, v, c2[k]))
    for k in c2:
        if k not in b2:
            warns.append("EXTRA %s" % k)

    # contrast table is data the t_ui3_theme test recomputes; just make sure it is still a list
    if "contrast" in base and not isinstance(cand.get("contrast"), list):
        errors.append("MISSING contrast list (t_ui3_theme recomputes every row)")

    for e in errors:
        print("ERROR  " + e)
    for w in warns:
        print("warn   " + w)
    print("--- %d value(s) changed vs current tokens" % len(changed))
    for c in changed:
        print("  ~ " + c)
    print("RESULT: %s (%d error(s), %d warning(s), %d changed)" % (
        "FAIL" if errors else "OK", len(errors), len(warns), len(changed)))
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
