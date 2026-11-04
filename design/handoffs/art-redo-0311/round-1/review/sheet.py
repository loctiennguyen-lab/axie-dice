"""Review sheets for art batch 1: current UI-06 vs new v2 vs library, plus mocks at game size.
usage: python sheet.py <new_dir> <cur_dir> <lib_dir> <metrics.jsonl> <out_dir>
"""
import json, sys
from PIL import Image, ImageDraw, ImageFont

NEW, CUR, LIB, MET, OUT = sys.argv[1:6]
BG = (42, 31, 26, 255)
CREAM = (243, 238, 219, 255)
MUTED = (180, 168, 150, 255)
RED = (230, 120, 110, 255)
try:
    F = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", 18)
    FS = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", 14)
    FB = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", 22)
except OSError:
    F = FS = FB = ImageFont.load_default()
NP = {"frame_core_moss": [100, 64, 100, 60], "frame_core_amber": [56, 56, 56, 60],
      "frame_core_crystal": [100, 64, 100, 64], "frame_run_rule": [48, 48, 48, 52],
      "artwin_moss": [28, 28, 28, 44], "artwin_amber": [28, 28, 28, 28], "artwin_crystal": [28, 28, 28, 40]}
MET_ROWS = {}
for l in open(MET):
    x = json.loads(l)
    MET_ROWS[x["file"].replace("_256.png", "").replace(".png", "")] = x


def ld(p):
    return Image.open(p).convert("RGBA")


def ninepatch(img, w, h, m):
    L, T, R, B = m
    W, H = img.size
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    xs = [(0, L, 0, L), (L, W - R, L, w - R), (W - R, W, w - R, w)]
    ys = [(0, T, 0, T), (T, H - B, T, h - B), (H - B, H, h - B, h)]
    for sx0, sx1, dx0, dx1 in xs:
        for sy0, sy1, dy0, dy1 in ys:
            if sx1 > sx0 and sy1 > sy0 and dx1 > dx0 and dy1 > dy0:
                part = img.crop((sx0, sy0, sx1, sy1)).resize((dx1 - dx0, dy1 - dy0), Image.LANCZOS)
                out.alpha_composite(part, (dx0, dy0))
    return out


def fit(img, box):
    w, h = img.size
    s = min(box / w, box / h)
    return img.resize((max(1, round(w * s)), max(1, round(h * s))), Image.LANCZOS)


def card(d, tier, fam):
    """Rough card mock at 1920 size: frame 400x600, crest 76 % on the top edge, art window, emblem."""
    c = Image.new("RGBA", (400, 660), (0, 0, 0, 0))
    inner = Image.new("RGBA", (360, 560), (58, 44, 36, 255))
    c.alpha_composite(inner, (20, 70))
    c.alpha_composite(ld(f"{d}/frame_core_{tier}.png"), (0, 50))
    aw = ninepatch(ld(f"{d}/artwin_{tier}.png"), 352, 160, NP["artwin_" + tier])
    c.alpha_composite(aw, (24, 140))
    em = fit(ld(f"{d}/family_{fam}_128.png"), 128)
    c.alpha_composite(em, (200 - em.width // 2, 220 - em.height // 2))
    cr = ld(f"{d}/crest_{tier}.png").resize((122, 64), Image.LANCZOS)
    c.alpha_composite(cr, (200 - 61, 50 - 34))
    return c


def text(dr, xy, s, f=F, fill=CREAM):
    dr.text(xy, s, font=f, fill=fill)


def metrics_line(key):
    x = MET_ROWS.get(key)
    if not x:
        return ""
    return f"cov {x['cov']}  black {x['black']}%  minV {x['minV']}  grain {x['grain']}  col {x['colors']}" + \
        (f"  FAIL {','.join(x['fail'])}" if x["fail"] else "  pass")


# ---- Sheet 1: card mocks, current vs new, per tier + run rule + backs
s1 = Image.new("RGBA", (1880, 1700), BG)
dr = ImageDraw.Draw(s1)
text(dr, (24, 16), "1  Core card mock at 1920 size (rough layout, not the game's exact positions). Top: current UI-06. Bottom: new v2.", FB)
for i, (tier, fam) in enumerate((("moss", "stat"), ("amber", "dice"), ("crystal", "quest"))):
    x = 24 + i * 430
    text(dr, (x, 56), f"{tier} · current", F, MUTED)
    s1.alpha_composite(card(CUR, tier, fam), (x, 70))
    text(dr, (x, 776), f"{tier} · NEW v2", F)
    s1.alpha_composite(card(NEW, tier, fam), (x, 790))
x = 1320
text(dr, (x, 56), "run rule · current", F, MUTED)
s1.alpha_composite(fit(ld(f"{CUR}/frame_run_rule.png"), 500), (x, 120))
text(dr, (x, 776), "run rule · NEW v2", F)
s1.alpha_composite(fit(ld(f"{NEW}/frame_run_rule.png"), 500), (x, 840))
s1.save(f"{OUT}/review-1-cards.png")

# ---- Sheet 2: card backs + crests + windows, current / new / library
rows = [
    ("crest", ["moss", "amber", "crystal"], {"moss": ["makerdao1", "a20a"], "amber": ["makerdao3"], "crystal": ["makerdao2", "a20b", "a20c"]}),
    ("back_art", ["moss", "amber", "crystal"], {"moss": ["s18a", "s3b"], "amber": ["s18b", "s3b"], "crystal": ["s18c", "s3c"]}),
    ("artwin", ["moss", "amber", "crystal"], {"moss": ["a14a", "a16a"], "amber": ["a16b", "a16c"], "crystal": ["a14c", "s17a"]}),
]
s2 = Image.new("RGBA", (1880, 9 * 230 + 80), BG)
dr = ImageDraw.Draw(s2)
text(dr, (24, 16), "2  Crests, card backs, art windows at native size: current | NEW v2 | library traced from", FB)
y = 60
for base, tiers, refs in rows:
    for t in tiers:
        key = f"{base}_{t}"
        text(dr, (24, y), key, F)
        text(dr, (24, y + 22), metrics_line(key), FS, MUTED)
        cur = ld(f"{CUR}/{key}.png")
        new = ld(f"{NEW}/{key}.png")
        s2.alpha_composite(cur, (24, y + 46))
        text(dr, (24 + cur.width + 8, y + 46), "current", FS, MUTED)
        nx = 440
        s2.alpha_composite(new, (nx, y + 46))
        text(dr, (nx + new.width + 8, y + 46), "NEW", FS)
        rx = 900
        for r in refs[t]:
            im = fit(ld(f"{LIB}/{r}.png"), 160)
            s2.alpha_composite(im, (rx, y + 46))
            text(dr, (rx, y + 46 + 164), r, FS, MUTED)
            rx += 190
        y += 230
s2.save(f"{OUT}/review-2-crest-back-window.png")

# ---- Sheet 3: slots at game size with emblem, + icons vs library
s3 = Image.new("RGBA", (1880, 1500), BG)
dr = ImageDraw.Draw(s3)
text(dr, (24, 16), "3  Slots at the game's real size (44 px core_slot, 38 px HUD) with the family emblem at 0.6 x slot as the code does today", FB)
y = 60
for label, d in (("current", CUR), ("NEW v2", NEW)):
    text(dr, (24, y), label, F, CREAM if d == NEW else MUTED)
    x = 160
    for t, fam in (("moss", "stat"), ("amber", "dice"), ("crystal", "quest"), ("empty", None)):
        for px in (44, 38):
            sl = ld(f"{d}/slot_{t}_64.png").resize((px, px), Image.LANCZOS)
            tile = Image.new("RGBA", (px, px), (0, 0, 0, 0))
            tile.alpha_composite(sl)
            if fam:
                e = fit(ld(f"{d}/family_{fam}_64.png"), round(px * 0.6))
                tile.alpha_composite(e, ((px - e.width) // 2, (px - e.height) // 2))
            big = tile.resize((px * 3, px * 3), Image.NEAREST)
            s3.alpha_composite(tile, (x, y + 30))
            s3.alpha_composite(big, (x + px + 8, y + 30))
            x += px * 4 + 30
    y += 180
text(dr, (24, y), "slots 128 / 64 / 32: current (dim) then NEW", F)
y += 30
x = 24
for t in ("moss", "amber", "crystal", "empty"):
    for d in (CUR, NEW):
        for px in (128, 64, 32):
            s3.alpha_composite(ld(f"{d}/slot_{t}_{px}.png"), (x, y + (128 - px) // 2))
            x += px + 6
        x += 14
    x += 20
y += 160
text(dr, (24, y), "family set at 64 and 32 (new 4 + library pos / mana / rule already in game) and badges", F)
y += 30
x = 24
fams = [(NEW, "family_stat"), (NEW, "family_dice"), (NEW, "family_quest"), (NEW, "family_run_rule"),
        (f"{CUR}/lib", "family_pos"), (f"{CUR}/lib", "family_mana"), (f"{CUR}/lib", "family_rule"),
        (NEW, "badge_tradeoff"), (NEW, "badge_convert_to_dmg")]
for d, k in fams:
    for px in (64, 32):
        p = f"{d}/{k}_{px}.png"
        try:
            im = ld(p)
        except FileNotFoundError:
            im = fit(ld(f"{CUR}/{k}_{px}.png"), px)
        s3.alpha_composite(im, (x, y + (64 - px) // 2))
        x += px + 6
    x += 30
y += 100
text(dr, (24, y), "icons at 128: current | NEW | library traced from", F)
y += 30
icon_refs = {"family_stat": ["peach", "strawberry"], "family_dice": ["dice_ref", "wood_plank"],
             "family_quest": ["s21a", "s21b"], "family_run_rule": ["f4b", "gem_orange"],
             "badge_tradeoff": ["gem_red"], "badge_convert_to_dmg": ["gem_orange"]}
for i, (k, refs) in enumerate(icon_refs.items()):
    cx = 24 + (i % 2) * 930
    cy = y + (i // 2) * 210
    text(dr, (cx, cy), k + "   " + metrics_line(k), FS, CREAM)
    s3.alpha_composite(ld(f"{CUR}/{k}_128.png"), (cx, cy + 22))
    s3.alpha_composite(ld(f"{NEW}/{k}_128.png"), (cx + 150, cy + 22))
    rx = cx + 330
    for r in refs:
        s3.alpha_composite(fit(ld(f"{LIB}/{r}.png"), 128), (rx, cy + 22))
        rx += 150
s3.save(f"{OUT}/review-3-slots-icons.png")
print("ok")
