#!/usr/bin/env python3
"""
gen_parts.py — sinh parts_build_data.json cho hệ 192-part Bloodline.

VIẾT LẠI 2026-09-01 (xem design/gdd/part-tier-system.md §1-§2, §6, §8).

Bản cũ (không còn tồn tại trong repo, chỉ mô tả trong docs/axiedice-source/)
gọi Axie Origin Data API rồi dùng regex đọc `description` để suy role/archetype/
keyword. Bản này KHÔNG đọc bất kỳ card text/API nào — role/archetype/keyword
đến từ 36 template (class × slot) do game-designer tự thiết kế
(part-tier-system.md §2a/§2c), gán cho từng part thật thuần theo tên/slot/class
(part-tier-system.md §8). Đây là single source of truth cho toàn bộ pipeline —
sửa dữ liệu ở CELLS/ASSIGN bên dưới (khớp với §2c/§8 trong GDD) rồi chạy lại
script, KHÔNG sửa parts_build_data.json bằng tay.

Input:
  design/gdd/axie-body-parts.md   — 192 part thật: tên + class + slot
  (dữ liệu 36 ô + gán part → primary/alt nằm ngay trong script này,
   khớp 1:1 với design/gdd/part-tier-system.md §2c/§8)

Output:
  docs/axiedice-source/economy/parts_build_data.json

Chạy: python3 tools/gen_parts.py
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BODY_PARTS_MD = ROOT / "design/gdd/axie-body-parts.md"
OUT_JSON = ROOT / "docs/axiedice-source/economy/parts_build_data.json"

# ── §2b: ngân sách và hệ số (part-tier-system.md) ──────────────────────────
TIER_BUDGET = {"common": 6.0, "rare": 8.5, "epic": 12.0, "legendary": 17.0}
ROLE_RATE = {"dmg": 1.00, "shield": 0.90, "heal": 0.80, "debuff": 0.85, "utility": 0.85}
TYPE_TO_ROLE = {"dmg": "dmg", "shield": "shield", "heal": "heal", "poison": "debuff", "mana": "utility"}

# Chi phí keyword — dải 0.7-2.7 theo §2b (KW_COST), trừ `heavy` là keyword
# ĐÁNH ĐỔI (không reroll được), nên được GIẢM ngân sách thay vì tốn thêm —
# khớp với dữ liệu HEROES thật: mặt `heavy` luôn có value cao hơn mặt thường.
KW_COST = {
    "cantrip": 0.8, "rerollup": 0.9, "vital": 1.0, "mana": 1.0,
    "regen": 1.1, "shieldself": 1.2, "lifesteal": 1.3, "thorns": 1.3,
    "weaken": 1.3, "vulnerable": 1.3, "blind": 1.3, "poison": 1.4,
    "crit": 1.7, "pierce": 1.8, "chain": 1.9, "multi": 2.0, "aoe": 2.2,
    "heavy": -0.5,
}

CLASS_PASSIVE = {
    "plant": "BULWARK", "beast": "FERAL", "aquatic": "CONDUIT",
    "reptile": "SCALES", "bug": "VIRULENT", "bird": "TALON",
}
# axie-body-parts.md dùng "aquatic"; engine (src/data.js CLASSES) dùng "aqua"
CLASS_ENGINE_KEY = {
    "plant": "plant", "beast": "beast", "aquatic": "aqua",
    "reptile": "reptile", "bug": "bug", "bird": "bird",
}

# ── §2c: 36 ô (class × slot) — Common / Rare primary+alt / Mythic ──────────
# type/value = Common (0 keyword). rare_primary/rare_alt = keyword Rare.
# epic = [rare_primary, rare_alt] cả hai (đúng theo "Epic = primary + alt cùng ô").
# mythic = mô tả phá luật (text, không phải cơ chế thực thi — Phase 2 designer duyệt tay).
CELLS = {
    ("plant", "mouth"): dict(type="dmg", value=5, rare_primary="lifesteal", rare_alt="vital",
        mythic="Overheal từ Lifesteal chuyển thành max-HP vĩnh viễn thay vì mất"),
    ("plant", "horn"): dict(type="dmg", value=6, rare_primary="pierce", rare_alt="heavy",
        mythic="Damage Pierce của mặt này cũng tạo Shield bằng đúng số damage"),
    ("plant", "back"): dict(type="shield", value=9, rare_primary="shieldself", rare_alt="thorns",
        mythic="Shield mặt này không decay đầu lượt, tồn tại tới khi bị tiêu"),
    ("plant", "tail"): dict(type="shield", value=6, rare_primary="shieldself", rare_alt="regen",
        mythic="Mỗi 10 Shield tích luỹ cũng hồi 1 HP, không chỉ cho Thorns"),
    ("plant", "eyes"): dict(type="heal", value=7, rare_primary="regen", rare_alt="cantrip",
        mythic="Heal vào mục tiêu đã đầy máu chuyển thành Shield thay vì mất"),
    ("plant", "ears"): dict(type="mana", value=2, rare_primary="mana", rare_alt="rerollup",
        mythic="Mana từ mặt này cũng tạo Shield bằng đúng giá trị mana"),

    ("beast", "mouth"): dict(type="dmg", value=7, rare_primary="lifesteal", rare_alt="crit",
        mythic="Lifesteal hồi máu cả trên phần damage bonus +60% của FERAL"),
    ("beast", "horn"): dict(type="dmg", value=9, rare_primary="heavy", rare_alt="pierce",
        mythic="Mặt này luôn được bonus FERAL +60%, bất kể HP% mục tiêu"),
    ("beast", "back"): dict(type="dmg", value=6, rare_primary="thorns", rare_alt="vulnerable",
        mythic="Thorns phản đòn của mặt này scale theo % HP mất của địch"),
    ("beast", "tail"): dict(type="dmg", value=6, rare_primary="multi", rare_alt="chain",
        mythic="Mỗi đòn trong multi-strike kiểm tra lại ngưỡng FERAL theo HP hiện tại giữa chuỗi đòn"),
    ("beast", "eyes"): dict(type="dmg", value=5, rare_primary="regen", rare_alt="vulnerable",
        mythic="Hồi máu cho bản thân bằng damage gây cho mục tiêu <50% HP, không giới hạn theo HP thiếu của chính mình"),
    ("beast", "ears"): dict(type="mana", value=2, rare_primary="rerollup", rare_alt="mana",
        mythic="Reroll charge từ mặt này không tính vào cap nâng cấp Max Reroll (3)"),

    ("aquatic", "mouth"): dict(type="dmg", value=6, rare_primary="mana", rare_alt="lifesteal",
        mythic="Mana mặt này kích hoạt quy đổi reroll của CONDUIT ngay, không cần gom đủ bội số 4"),
    ("aquatic", "horn"): dict(type="dmg", value=7, rare_primary="pierce", rare_alt="crit",
        mythic="Damage Pierce của mặt này cũng tạo Mana bằng đúng số damage"),
    ("aquatic", "back"): dict(type="shield", value=6, rare_primary="shieldself", rare_alt="mana",
        mythic="Shield mặt này cũng tạo Mana bằng đúng giá trị shield"),
    ("aquatic", "tail"): dict(type="dmg", value=5, rare_primary="chain", rare_alt="multi",
        mythic="Chain của mặt này không bao giờ trúng lại mục tiêu đã trúng khi còn địch chưa bị chọn"),
    ("aquatic", "eyes"): dict(type="heal", value=7, rare_primary="regen", rare_alt="cantrip",
        mythic="Chuỗi cantrip của mặt này không giới hạn 6 lần lặp như bình thường"),
    ("aquatic", "ears"): dict(type="mana", value=3, rare_primary="mana", rare_alt="rerollup",
        mythic="Overheal từ mặt Eyes đồng minh trong lượt được quy đổi thành Mana bonus trên mặt này"),

    ("reptile", "mouth"): dict(type="dmg", value=6, rare_primary="lifesteal", rare_alt="poison",
        mythic="Lifesteal mặt này cũng hồi máu theo damage Poison-tick đã gây trong lượt"),
    ("reptile", "horn"): dict(type="dmg", value=7, rare_primary="pierce", rare_alt="heavy",
        mythic="Damage Pierce mặt này áp Poison-qua-Thorns ngay, không cần địch tấn công trước"),
    ("reptile", "back"): dict(type="shield", value=8, rare_primary="thorns", rare_alt="shieldself",
        mythic="Thorns mặt này không có trần stack và không reset đầu lượt"),
    ("reptile", "tail"): dict(type="poison", value=4, rare_primary="poison", rare_alt="aoe",
        mythic="Poison mặt này không giảm 1 stack mỗi lượt như bình thường (khớp rule-break plague)"),
    ("reptile", "eyes"): dict(type="heal", value=5, rare_primary="regen", rare_alt="weaken",
        mythic="Regen tick mặt này cũng cộng Thorns bằng đúng lượng hồi"),
    ("reptile", "ears"): dict(type="mana", value=2, rare_primary="mana", rare_alt="rerollup",
        mythic="Mana mặt này cũng cho 1 stack Thorns tồn tại sang trận sau (không reset cuối wave)"),

    ("bug", "mouth"): dict(type="dmg", value=5, rare_primary="poison", rare_alt="lifesteal",
        mythic="Lifesteal mặt này đọc cả damage Poison-tick vừa áp trong lượt"),
    ("bug", "horn"): dict(type="dmg", value=6, rare_primary="weaken", rare_alt="pierce",
        mythic="Weaken mặt này stack nhân thay vì cộng như bình thường"),
    ("bug", "back"): dict(type="shield", value=6, rare_primary="poison", rare_alt="shieldself",
        mythic="Shield mặt này gây Poison cho địch phá giáp dù không có keyword Thorns"),
    ("bug", "tail"): dict(type="poison", value=5, rare_primary="poison", rare_alt="aoe",
        mythic="Bonus +2-stack của VIRULENT áp dụng 2 lần trên chính mặt này"),
    ("bug", "eyes"): dict(type="poison", value=3, rare_primary="poison", rare_alt="blind",
        mythic="Poison mặt này không giảm stack mỗi lượt, chỉ khi VIRULENT đang active trong trận (khớp rule-break plague)"),
    ("bug", "ears"): dict(type="mana", value=2, rare_primary="mana", rare_alt="rerollup",
        mythic="Mana mặt này áp Poison 1 lên một địch ngẫu nhiên theo mỗi điểm mana"),

    ("bird", "mouth"): dict(type="dmg", value=6, rare_primary="pierce", rare_alt="lifesteal",
        mythic="Luật \"mặt aoe cũng có Pierce\" của TALON áp cho cả mặt này dù không gắn aoe"),
    ("bird", "horn"): dict(type="dmg", value=7, rare_primary="pierce", rare_alt="crit",
        mythic="Pierce mặt này bỏ qua hoàn toàn phản đòn Thorns của địch"),
    ("bird", "back"): dict(type="dmg", value=5, rare_primary="vulnerable", rare_alt="blind",
        mythic="Mặt này tạo Shield — phá luật \"Bird không bao giờ có mặt shield\" ở mọi bậc khác"),
    ("bird", "tail"): dict(type="dmg", value=5, rare_primary="chain", rare_alt="multi",
        mythic="Đòn Chain của mặt này tính là Pierce cho bonus TALON, dù Chain thường không mang Pierce"),
    ("bird", "eyes"): dict(type="dmg", value=5, rare_primary="blind", rare_alt="vulnerable",
        mythic="Mặt này tạo Heal — phá luật \"Bird không bao giờ có mặt heal\" ở mọi bậc khác"),
    ("bird", "ears"): dict(type="mana", value=2, rare_primary="rerollup", rare_alt="mana",
        mythic="Bonus TALON áp cho mỗi lần kích hoạt cantrip-chain của mặt này, không chỉ lần đầu"),
}

# ── §8: gán 192 part thật → primary/alt (thuần theo tên/flavor, không đọc card text) ──
# key: (class, slot, name lowercase) -> "primary" | "alt"
ASSIGN_RAW = {
    ("beast", "mouth"): {"Axie Kiss": "primary", "Confident": "alt", "Goda": "alt", "Nut Cracker": "primary"},
    ("beast", "horn"): {"Arco": "alt", "Dual Blade": "alt", "Imp": "primary", "Little Branch": "primary", "Merry": "primary", "Pocky": "alt"},
    ("beast", "back"): {"Furball": "primary", "Hero": "alt", "Jaguar": "alt", "Risky Beast": "alt", "Ronin": "primary", "Timber": "primary"},
    ("beast", "tail"): {"Cottontail": "primary", "Gerbil": "alt", "Hare": "primary", "Nut Cracker": "primary", "Rice": "alt", "Shiba": "alt"},
    ("beast", "eyes"): {"Chubby": "alt", "Little Peas": "alt", "Puppy": "primary", "Zeal": "primary"},
    ("beast", "ears"): {"Belieber": "alt", "Innocent Lamb": "alt", "Nut Cracker": "alt", "Nyan": "primary", "Puppy": "primary", "Zen": "primary"},

    ("aquatic", "mouth"): {"Catfish": "alt", "Lam": "primary", "Piranha": "alt", "Risky Fish": "primary"},
    ("aquatic", "horn"): {"Anemone": "alt", "Babylonia": "primary", "Clamshell": "primary", "Oranda": "primary", "Shoal Star": "alt", "Teal Shell": "alt"},
    ("aquatic", "back"): {"Anemone": "primary", "Blue Moon": "alt", "Goldfish": "alt", "Hermit": "primary", "Perch": "alt", "Sponge": "primary"},
    ("aquatic", "tail"): {"Koi": "primary", "Navaga": "alt", "Nimo": "primary", "Ranchu": "primary", "Shrimp": "alt", "Tadpole": "alt"},
    ("aquatic", "eyes"): {"Clear": "primary", "Gero": "alt", "Sleepless": "primary", "Telescope": "alt"},
    ("aquatic", "ears"): {"Bubblemaker": "primary", "Gill": "primary", "Inkling": "alt", "Nimo": "primary", "Seaslug": "alt", "Tiny Fan": "alt"},

    ("plant", "mouth"): {"Herbivore": "alt", "Serious": "primary", "Silence Whisper": "alt", "Zigzag": "primary"},
    ("plant", "horn"): {"Bamboo Shoot": "primary", "Beech": "alt", "Cactus": "primary", "Rose Bud": "primary", "Strawberry Shortcake": "alt", "Watermelon": "alt"},
    ("plant", "back"): {"Bidens": "alt", "Mint": "primary", "Pumpkin": "primary", "Shiitake": "primary", "Turnip": "alt", "Watering Can": "alt"},
    ("plant", "tail"): {"Carrot": "alt", "Cattail": "primary", "Hatsune": "alt", "Hot Butt": "primary", "Potato Leaf": "primary", "Yam": "alt"},
    ("plant", "eyes"): {"Blossom": "primary", "Confused": "alt", "Cucumber Slice": "primary", "Papi": "alt"},
    ("plant", "ears"): {"Clover": "alt", "Hollow": "primary", "Leafy": "primary", "Lotus": "alt", "Rosa": "primary", "Sakura": "alt"},

    ("reptile", "mouth"): {"Kotaro": "alt", "Razor Bite": "primary", "Tiny Turtle": "alt", "Toothless Bite": "primary"},
    ("reptile", "horn"): {"Bumpy": "alt", "Cerastes": "primary", "Incisor": "primary", "Scaly Spear": "primary", "Scaly Spoon": "alt", "Unko": "alt"},
    ("reptile", "back"): {"Bone Sail": "alt", "Croc": "alt", "Green Thorns": "primary", "Indian Star": "primary", "Red Ear": "alt", "Tri Spikes": "primary"},
    ("reptile", "tail"): {"Gila": "primary", "Grass Snake": "primary", "Iguana": "alt", "Snake Jar": "alt", "Tiny Dino": "primary", "Wall Gecko": "alt"},
    ("reptile", "eyes"): {"Gecko": "primary", "Scar": "alt", "Topaz": "alt", "Tricky": "primary"},
    ("reptile", "ears"): {"Curved Spine": "alt", "Friezard": "primary", "Pogona": "alt", "Sidebarb": "primary", "Small Frill": "primary", "Swirl": "alt"},

    ("bug", "mouth"): {"Cute Bunny": "alt", "Mosquito": "alt", "Pincer": "primary", "Square Teeth": "primary"},
    ("bug", "horn"): {"Antenna": "alt", "Caterpillars": "primary", "Lagging": "primary", "Leaf Bug": "alt", "Parasite": "primary", "Pliers": "alt"},
    ("bug", "back"): {"Buzz Buzz": "primary", "Garish Worm": "primary", "Sandal": "alt", "Scarab": "alt", "Snail Shell": "alt", "Spiky Wing": "primary"},
    ("bug", "tail"): {"Ant": "alt", "Fish Snack": "primary", "Gravel Ant": "alt", "Pupae": "primary", "Thorny Caterpillar": "primary", "Twin Tail": "alt"},
    ("bug", "eyes"): {"Bookworm": "alt", "Kotaro?": "primary", "Neo": "primary", "Nerdy": "alt"},
    ("bug", "ears"): {"Beetle Spike": "primary", "Ear Breathing": "alt", "Earwing": "alt", "Larva": "primary", "Leaf Bug": "primary", "Tassels": "alt"},

    ("bird", "mouth"): {"Doubletalk": "alt", "Hungry Bird": "alt", "Little Owl": "primary", "Peace Maker": "primary"},
    ("bird", "horn"): {"Cuckoo": "alt", "Eggshell": "primary", "Feather Spear": "primary", "Kestrel": "alt", "Trump": "alt", "Wing Horn": "primary"},
    ("bird", "back"): {"Balloon": "primary", "Cupid": "primary", "Kingfisher": "primary", "Pigeon Post": "alt", "Raven": "alt", "Tri Feather": "alt"},
    ("bird", "tail"): {"Cloud": "primary", "Feather Fan": "alt", "Granma's Fan": "primary", "Post Fight": "alt", "Swallow": "alt", "The Last One": "primary"},
    ("bird", "eyes"): {"Little Owl": "primary", "Lucas": "alt", "Mavis": "primary", "Robin": "alt"},
    ("bird", "ears"): {"Curly": "primary", "Early Bird": "primary", "Owl": "alt", "Peace Maker": "alt", "Pink Cheek": "primary", "Risky Bird": "alt"},
}


def parse_body_parts(md_text):
    """Đọc design/gdd/axie-body-parts.md -> list[(name, class, slot)]."""
    parts = []
    cur_class = None
    cur_slot = None
    class_map = {"BEAST": "beast", "AQUATIC": "aquatic", "PLANT": "plant",
                 "BIRD": "bird", "BUG": "bug", "REPTILE": "reptile"}
    for line in md_text.splitlines():
        m = re.match(r"^## ([A-Z]+)\s*$", line.strip())
        if m and m.group(1) in class_map:
            cur_class = class_map[m.group(1)]
            cur_slot = None
            continue
        if line.strip().startswith("## Special-gene"):
            cur_class = None  # bỏ qua special-gene parts (không phải 192 core)
            continue
        m = re.match(r"^### .+? — (Mouth|Horn|Back|Tail|Eyes|Ears)\s*$", line.strip())
        if m and cur_class:
            cur_slot = m.group(1).lower()
            continue
        if cur_class and cur_slot and line.strip().startswith("|") and "Card effect" not in line and "---" not in line:
            cells = [c.strip() for c in line.strip().strip("|").split("|")]
            if len(cells) >= 1 and cells[0] and cells[0] != "Part":
                parts.append((cells[0], cur_class, cur_slot))
    return parts


def compute_value(face_type, tier, keywords):
    role = TYPE_TO_ROLE[face_type]
    rate = ROLE_RATE[role]
    kw_cost = sum(KW_COST.get(k, 1.3) for k in keywords)  # 1.3 = trung vị dải, fallback an toàn
    budget = TIER_BUDGET[tier]
    v = (budget - kw_cost) / rate
    return max(1, round(v))


def main():
    if not BODY_PARTS_MD.exists():
        sys.exit(f"Không tìm thấy {BODY_PARTS_MD}")
    parts_raw = parse_body_parts(BODY_PARTS_MD.read_text(encoding="utf-8"))
    if len(parts_raw) != 192:
        print(f"⚠️  Cảnh báo: đọc được {len(parts_raw)} part core, kỳ vọng 192 — kiểm tra lại axie-body-parts.md", file=sys.stderr)

    out_parts = []
    unassigned = []
    slug_seen = {}

    for name, cls, slot in parts_raw:
        cell = CELLS.get((cls, slot))
        if not cell:
            unassigned.append((name, cls, slot))
            continue
        choice_map = ASSIGN_RAW.get((cls, slot), {})
        choice = choice_map.get(name)
        if choice is None:
            # part không có trong bảng gán §8 (không nên xảy ra với 192 part core;
            # có thể là dữ liệu mới thêm sau) — mặc định primary, đánh dấu để designer duyệt.
            choice = "primary"
            unassigned.append((name, cls, slot))

        rare_kw = cell["rare_primary"] if choice == "primary" else cell["rare_alt"]
        epic_kws = [cell["rare_primary"], cell["rare_alt"]]
        ftype = cell["type"]

        base = re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")
        slug = f"{slot}-{base}"
        n = slug_seen.get(slug, 0)
        slug_seen[slug] = n + 1
        if n:  # part trùng tên ở cùng slot (hiếm, nhưng dữ liệu gốc có thể trùng) -> hậu tố
            slug = f"{slug}-{n+1}"

        out_parts.append({
            "partId": slug,
            "name": name,
            "class": CLASS_ENGINE_KEY[cls],
            "slot": slot,
            "classPassive": CLASS_PASSIVE[cls],
            "rareChoice": choice,
            "keywords": {"rare": [rare_kw], "epic": epic_kws, "legendary": epic_kws},
            "tiers": {
                "common": {"type": ftype, "value": cell["value"], "keywords": []},
                "rare": {"type": ftype, "value": compute_value(ftype, "rare", [rare_kw]), "keywords": [rare_kw]},
                "epic": {"type": ftype, "value": compute_value(ftype, "epic", epic_kws), "keywords": epic_kws},
                "legendary": {"type": ftype, "value": compute_value(ftype, "legendary", epic_kws), "keywords": epic_kws},
            },
        })

    mythic_by_slot = {}
    for (cls, slot), cell in CELLS.items():
        mythic_by_slot.setdefault(cls, {})[slot] = {
            "classPassive": CLASS_PASSIVE[cls],
            "ruleBreak": cell["mythic"],
        }

    output = {
        "_meta": {
            "source": "design/gdd/part-tier-system.md §2a/§2c/§8 — 36 template tự thiết kế, KHÔNG dùng Axie Origins card text",
            "generatedBy": "tools/gen_parts.py",
            "note": "value = (ngân_sách_bậc - chi_phí_keyword) / hệ_số_role (§2b). Sửa CELLS/ASSIGN_RAW trong "
                    "gen_parts.py rồi chạy lại — không sửa file JSON này bằng tay.",
        },
        "parts": out_parts,
        "mythicBySlot": mythic_by_slot,
    }

    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(json.dumps(output, ensure_ascii=False, indent=2), encoding="utf-8")

    print(f"✅ Sinh {len(out_parts)} part -> {OUT_JSON}")
    if unassigned:
        print(f"⚠️  {len(unassigned)} part không có trong bảng gán §8 (đã mặc định 'primary', cần designer duyệt lại):")
        for name, cls, slot in unassigned:
            print(f"   - {name} ({cls}/{slot})")


if __name__ == "__main__":
    main()
