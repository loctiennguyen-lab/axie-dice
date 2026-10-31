#!/usr/bin/env python3
"""ui5_names.py - in cay data-name (= ten node Godot) cua cac frame trong HTML UI-05.

Cach dung (chay voi `python3 -I`, chi dung thu vien chuan):
  ui5_names.py <html> <tien to> [<tien to> ...] [-o file]   in cay cho frame co id bat dau bang tien to
  ui5_names.py <html> --list                                 liet ke id frame (+ co 1920/1280)
  ui5_names.py --all [--root DIR] [--design DIR]             sinh production/ui05-b23/names/<lan>.txt + README.md

Tien to "=id" khop dung id. Moi dong: data-name [left,top WxH] "chu" ; comment <!-- godot: ... --> in dang "# godot: ...".
"""
import sys, os, re, argparse
from html.parser import HTMLParser

VOID = {"area","base","br","col","embed","hr","img","input","link","meta","source","track","wbr"}


class Node:
    def __init__(self, name, style, parent):
        self.name, self.style, self.parent = name, style, parent
        self.children, self.comments, self.text = [], [], []


class Frame:
    def __init__(self, fid, cls):
        self.id, self.cls = fid, cls
        self.root = Node(fid, "", None)


class P(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.frames = []
        self.stack = []      # (tag, node|None)
        self.cur = None      # frame
        self.fdepth = None
        self.node = None

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if tag in VOID:
            if self.cur is not None and a.get("data-name"):
                n = Node(a["data-name"], a.get("style", ""), self.node)
                self.node.children.append(n)
            return
        if tag == "section" and "frame" in (a.get("class") or "").split():
            self.cur = Frame(a.get("id", a.get("data-name", "?")), a.get("class"))
            self.frames.append(self.cur)
            self.node = self.cur.root
            self.stack.append((tag, "FRAME"))
            return
        nn = None
        if self.cur is not None and a.get("data-name"):
            nn = Node(a["data-name"], a.get("style", ""), self.node)
            self.node.children.append(nn)
            self.node = nn
        self.stack.append((tag, nn))

    def handle_endtag(self, tag):
        if tag in VOID:
            return
        for i in range(len(self.stack) - 1, -1, -1):
            if self.stack[i][0] == tag:
                popped = self.stack[i:]
                del self.stack[i:]
                for _, n in popped:
                    if n == "FRAME":
                        self.cur = None; self.node = None
                    elif n is not None:
                        self.node = n.parent
                return

    def handle_data(self, d):
        if self.cur is not None and self.node is not None:
            t = " ".join(d.split())
            if t:
                self.node.text.append(t)

    def handle_comment(self, c):
        if self.cur is not None and self.node is not None:
            m = re.match(r"\s*godot:\s*(.*?)\s*$", c, re.S)
            if m:
                self.node.comments.append(" ".join(m.group(1).split()))


def parse(path):
    p = P()
    with open(path, encoding="utf-8") as f:
        p.feed(f.read())
    return p.frames


def geom(style):
    d = dict(re.findall(r"(left|top|width|height)\s*:\s*([^;]+)", style or ""))
    if not d:
        return ""
    xy = ",".join(d[k].strip() for k in ("left", "top") if k in d)
    wh = "x".join(d[k].strip() for k in ("width", "height") if k in d)
    return "[" + " ".join(s for s in (xy, wh) if s) + "]"


def size_of(fr):
    c = fr.cls or ""
    return "1280" if "r1280" in c else "1920" if "r1920" in c else ""


def render(node, depth, out):
    pad = "  " * depth
    line = pad + node.name
    g = geom(node.style)
    if g:
        line += " " + g
    if not node.children and node.text:
        t = " ".join(node.text)
        if len(t) > 60:
            t = t[:59] + "…"
        line += ' "' + t + '"'
    out.append(line)
    for c in node.comments:
        out.append(pad + "  # godot: " + c)
    for ch in node.children:
        render(ch, depth + 1, out)


def match(fid, prefixes):
    for p in prefixes:
        if p.startswith("="):
            if fid == p[1:] or fid == p[1:] + "--1280":
                return True
        elif fid.startswith(p):
            return True
    return False


def select(frames, prefixes):
    return [f for f in frames if match(f.id, prefixes)]


def dump(frames):
    out = []
    for f in frames:
        out.append("")
        out.append("=== %s%s" % (f.id, " (%s)" % size_of(f) if size_of(f) else ""))
        for c in f.root.comments:
            out.append("  # godot: " + c)
        for ch in f.root.children:
            render(ch, 1, out)
    return out


# ---------------------------------------------------------------- bang lan
R2 = "round-2/ui05-run-screens.html"
LAND = "round-3/ui05-land-screens.html"
M1 = "round-3/ui05-meta1-screens.html"
M2 = "round-3/ui05-meta2-screens.html"
M3 = "round-3/ui05-meta3-screens.html"

L = "01-land--"
S = "06-run-setup--"
E = "20-echo--"
# lan -> (mo ta, [(html, [tien to])]) ; "=id" la khop dung (id kem "--1280" van khop vi so khop theo tien to + hau to)
LANES = {
 "R1": ("Ban do + HUD", [(R2, ["03-run-map", "components-run--sheet"])]),
 "R2": ("Offers: core, rule (TRU make-room + combo-banner cua R4; them components-run--cards)",
        [(R2, ["47-core-offer--amber", "47-core-offer--combo-tags", "47-core-offer--crystal", "47-core-offer--facedown",
               "47-core-offer--moss", "47-core-offer--pick1-4cards", "47-core-offer--reroll-used",
               "47-core-offer--rerolls-none", "47-core-offer--selected", "05-run-rule-offer", "components-run--cards"])]),
 "R3": ("Anchor", [(R2, ["48-anchor-pick", "49-anchor-awaken"])]),
 "R4": ("Make room + Combo banner", [(R2, ["47-core-offer--make-room", "47-core-offer--combo-banner"])]),
 "R5a": ("Shop", [(R2, ["shop--"])]),
 "R5b": ("Event + Treasure", [(R2, ["event--", "13-treasure"])]),
 "R6": ("Menu trong run", [(R2, ["menu--"])]),
 "S1a": ("Land HUD: idle + state RunPlate + tooltip + tier plate", [(LAND, [L + p for p in
        ("signed-in", "guest", "loading", "continue-run", "continue-mission", "tier-up", "tier6-max", "tooltip-building", "tooltip-lock")] + ["components-land--sheet"])]),
 "S1b": ("Land HUD: toast, coach, confirm, banner offline", [(LAND, [L + p for p in
        ("first-visit", "toast-error", "new-run-confirm", "abandon-mission-confirm", "offline", "offline-retry", "reconnecting", "beta-reset")])]),
 "S2": ("Edit Land + Land upgrade", [(LAND, ["e0", "u0"])]),
 "S3a": ("Run setup: layout chinh", [(LAND, [S + p for p in
        ("a5", "blocked", "closing", "daily", "full-locked", "guest", "loading", "newcomer", "offline-live", "offline-local",
         "open-run", "party-short", "ranked", "stage1", "stage3", "start-error", "starting")] + ["components-land--setup"])]),
 "S3b": ("Run setup: picker, bang xep hang popup, Load/Save team", [(LAND, [S + p for p in
        ("picker", "picker-empty", "lb-", "presets-load", "presets-save")])]),
 "S4a": ("Team presets", [(LAND, ["t0"])]),
 "S4b": ("Tutorial", [(LAND, ["37-tutorial"])]),
 "S5": ("Missions", [(M1, ["40-missions"])]),
 "S6": ("Result", [(M1, ["10-result"])]),
 "S7a": ("Leaderboard", [(M1, ["lb--"])]),
 "S7b": ("Raid", [(M1, ["r0", "r10"])]),
 "S8a1": ("Account + sign-in (a01-a12, a17-a18)", [(M1, ["a01-", "a02-", "a03-", "a04-", "a05-", "a06-", "a07-", "a08-", "a09-", "a10-", "a11-", "a12-", "a17-", "a18-"])]),
 "S8a2": ("Boot offline, Welcome, ChooseSave, Move progress (a13-a16)", [(M1, ["a13-", "a14-", "a15-", "a16-"])]),
 "S8b": ("NetNotice + Update", [(M3, ["18-netnotice", "18-update"])]),
 "S9a": ("Echo Box (tru ceremony)", [(M2, [E + p for p in
        ("idle", "buy-confirm", "error", "guest", "last-pull", "loading", "no-tickets", "offline", "open10-confirm",
         "rates", "seasonal")])]),
 "S9b": ("Echo Box ceremony: opening, reveal-*, open10 grid, summary", [(M2, [E + "opening", E + "reveal-", "=" + E + "open10", E + "summary"])]),
 "S10": ("Season Pass", [(M2, ["21-pass"])]),
 "S11a": ("Daily", [(M2, ["41-daily"])]),
 "S11b": ("Store", [(M2, ["19-store"])]),
 "S12": ("Profile", [(M3, ["24-profile"])]),
 "S13": ("Codex + Guides + Unlocks", [(M3, ["29-codex"])]),
 "S14": ("Settings", [(M3, ["26-settings"])]),
 "0d": ("Meta kit: sheet/setup cua land, meta1, meta2", [(LAND, ["components-land--sheet", "components-land--setup"]),
        (M1, ["components-meta1--sheet"]), (M2, ["components-meta2--sheet"])]),
}
MOMENTS = {
 "M2": ("Moment B2", "round-2/moments"),
 "M3": ("Moment B3", "round-3/moments"),
}
ALL_ORDER = ["R1","R2","R3","R4","R5a","R5b","R6","M2","S1a","S1b","S2","S3a","S3b","S4a","S4b","S5","S6","S7a","S7b",
             "S8a1","S8a2","S8b","S9a","S9b","S10","S11a","S11b","S12","S13","S14","M3","0d"]
# Ghi chu cach chia / doan
NOTES = {
 "S1a": "Chia 01-land (nua dau): idle (signed-in, guest), state RunPlate (loading, continue-run, continue-mission), land tier (tier-up, tier6-max), tooltip; + components-land--sheet.",
 "S1b": "Chia 01-land (nua sau): first-visit (coach), toast-error, new-run-confirm, abandon-mission-confirm, banner offline/offline-retry/reconnecting, beta-reset. DOAN: beta-reset xep vao day (banner/thong bao), first-visit la coach.",
 "S3a": "Chia 06-run-setup (nua dau): layout chinh va moi state cua no (kieu run, party, start-error, starting, closing...) + components-land--setup.",
 "S3b": "Chia 06-run-setup (nua sau): picker, picker-empty, popup bang xep hang (lb-*), Load/Save team (presets-load, presets-save). DOAN: presets-save xep vao S3b cung Load.",
 "R2": "DOAN: 47-core-offer--combo-tags (the co nhan combo) o R2; chi combo-banner o R4. Plan ghi R2 '47-core-offer x12 (tru make-room)' nhung R4 cung nhan combo, nen tach combo-banner sang R4.",
 "S9a": "DOAN: ceremony = opening + reveal-* + open10 + summary; open10-confirm va seasonal-milestone o S9a.",
 "0d": "Chu y: components-land--sheet con nam o S1a, components-land--setup o S3a (trung co chu y).",
}


def moment_lines(rel, design):
    d = os.path.join(design, rel)
    out = []
    for fn in sorted(os.listdir(d)):
        if not fn.endswith(".html") or fn == "index.html":
            continue
        txt = open(os.path.join(d, fn), encoding="utf-8").read()
        out.append("")
        tm = re.search(r"<title>([^<]*)", txt)
        out.append("=== moments/" + fn + ("  [" + tm.group(1).strip() + "]" if tm else ""))
        names, seen = [], set()
        for m in re.finditer(r'data-name="([^"]+)"', txt):
            if m.group(1) not in seen:
                seen.add(m.group(1)); names.append(m.group(1))
        if names:
            out.append("  data-name: " + ", ".join(names[:40]) + (" ..." if len(names) > 40 else ""))
        else:
            out.append("  (HTML dong, khong co data-name; xem motion-batch*.md va file nay)")
        cs, seenc = [], set()
        for m in re.finditer(r"<!--\s*godot:\s*(.*?)-->", txt, re.S):
            c = " ".join(m.group(1).split())
            if c not in seenc:
                seenc.add(c); cs.append(c)
        for c in cs:
            out.append("  # godot: " + c)
    return out


def run_all(root, design):
    nd = os.path.join(root, "production", "ui05-b23", "names")
    os.makedirs(nd, exist_ok=True)
    cache = {}
    def frames_of(h):
        if h not in cache:
            cache[h] = parse(os.path.join(design, h))
        return cache[h]
    used = {}   # (html, id) -> [lanes]
    rows, problems = [], []
    for lane in ALL_ORDER:
        if lane in MOMENTS:
            title, rel = MOMENTS[lane]
            body = moment_lines(rel, design)
            nfiles = sum(1 for l in body if l.startswith("=== "))
            head = ["# %s: %s" % (lane, title), "# Nguon: design/handoffs/ui-05-figma/%s (khong co frame, liet ke file)" % rel,
                    "# So file moment: %d" % nfiles]
            open(os.path.join(nd, lane + ".txt"), "w", encoding="utf-8").write("\n".join(head + body) + "\n")
            rows.append((lane, title, "%d moment" % nfiles, 0))
            if nfiles == 0: problems.append(lane + ": khong co file moment")
            continue
        title, parts = LANES[lane]
        sel, srcs = [], []
        for h, pre in parts:
            fs = select(frames_of(h), pre)
            srcs.append(h)
            for f in fs:
                sel.append((h, f))
                used.setdefault((h, f.id), []).append(lane)
        if not sel:
            problems.append(lane + ": khong khop frame nao")
        head = ["# %s: %s" % (lane, title)]
        head += ["# Nguon HTML: design/handoffs/ui-05-figma/" + h for h in srcs]
        head.append("# So frame: %d (%d id, tinh ca ban 1920 va 1280)" % (len(sel), len({f.id.replace('--1280','') for _, f in sel})))
        head.append("# Tien to: " + "; ".join(" ".join(pre) for _, pre in parts))
        if lane in NOTES:
            head.append("# Ghi chu: " + NOTES[lane])
        head.append("# Id frame:")
        for _, f in sel:
            head.append("#   " + f.id)
        body = []
        for h, f in sel:
            body += dump([f])
        open(os.path.join(nd, lane + ".txt"), "w", encoding="utf-8").write("\n".join(head + body) + "\n")
        rows.append((lane, title, "%d" % len(sel), len({f.id.replace('--1280','') for _, f in sel})))
    # frame khong thuoc lan nao
    orphan, multi = [], []
    for h in {x for l in LANES.values() for x, _ in l[1]}:
        for f in frames_of(h):
            ls = used.get((h, f.id), [])
            if not ls: orphan.append((h, f.id))
            elif len(ls) > 1 and ls != ["0d"] and not (set(ls) <= {"0d", "S1a", "S3a"}):
                multi.append((f.id, ls))
    tot = sum(len(frames_of(h)) for h in {x for l in LANES.values() for x, _ in l[1]})
    readme = ["# UI-05 dot 2+3: names theo lan", "",
              "Sinh bang `python3 -I godot/tools/ui5_names.py --all` (tu cay chinh design/handoffs/ui-05-figma). Moi file la cay data-name cua cac frame cua lan; `# godot:` la comment luat trong HTML.", "",
              "| Lan | Mo ta | Frame (ca 2 co) | Id (khong tinh co) |", "|---|---|---|---|"]
    for lane, title, n, ids in rows:
        readme.append("| %s | %s | %s | %s |" % (lane, title, n, ids or "-"))
    readme += ["", "Tong frame trong 5 file HTML: %d." % tot, ""]
    readme.append("## Frame khong thuoc lan nao (%d)" % len(orphan))
    readme += ["- %s (%s)" % (i, os.path.basename(h)) for h, i in sorted(orphan)] or ["(khong co)"]
    readme += ["", "## Frame thuoc nhieu lan (tru 0d, S1a/S3a cung sheet)"]
    readme += ["- %s: %s" % (i, ", ".join(l)) for i, l in multi] or ["(khong co)"]
    readme += ["", "## Cach chia / doan"]
    readme += ["- **%s**: %s" % (k, v) for k, v in NOTES.items()]
    if problems:
        readme += ["", "## Loi", *["- " + p for p in problems]]
    open(os.path.join(nd, "README.md"), "w", encoding="utf-8").write("\n".join(readme) + "\n")
    print("\n".join(readme))
    return 1 if problems else 0


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("html", nargs="?")
    ap.add_argument("prefix", nargs="*")
    ap.add_argument("-o", "--output")
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--root", default=os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..")))
    ap.add_argument("--design", default=None, help="thu muc ui-05-figma (mac dinh: <root>/design/handoffs/ui-05-figma, neu khong co thi cay chinh)")
    a = ap.parse_args()
    design = a.design
    if not design:
        design = os.path.join(a.root, "design", "handoffs", "ui-05-figma")
        if not os.path.isfile(os.path.join(design, R2)):
            design = "/Users/loc.tien.nguyen/my-game/design/handoffs/ui-05-figma"
    if a.all:
        return run_all(a.root, design)
    if not a.html:
        ap.error("can <html> hoac --all")
    frames = parse(a.html)
    if a.list:
        for f in frames:
            print("%s\t%s" % (f.id, size_of(f)))
        print("# %d frame" % len(frames), file=sys.stderr)
        return 0
    if not a.prefix:
        ap.error("can it nhat 1 tien to frame (hoac --list)")
    sel = select(frames, a.prefix)
    if not sel:
        print("khong frame nao khop %s; thu --list" % a.prefix, file=sys.stderr)
        return 1
    out = ["# %s | %d frame" % (a.html, len(sel))] + dump(sel)
    txt = "\n".join(out) + "\n"
    if a.output:
        open(a.output, "w", encoding="utf-8").write(txt)
    else:
        sys.stdout.write(txt)
    return 0


if __name__ == "__main__":
    sys.exit(main())
