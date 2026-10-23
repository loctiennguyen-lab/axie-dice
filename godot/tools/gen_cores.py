#!/usr/bin/env python3
"""Generates godot/resources/relics/c_*.tres + rule_*.tres (depth v3 lane C). Usage: gen_cores.py <relics_dir> [ids...]
Without ids: all entries. Re-running overwrites. The catalog below is the single source; edit here, regenerate."""
import sys, os

# slug, vn, name, tier(0 moss,1 amber,2 crystal), axis, requires, excludes, tags(<=2), desc, extra
C = []
def core(slug, vn, name, tier, axis, req, exc, tags, desc, **extra):
    C.append(dict(slug=slug, vn=vn, name=name, tier=tier, axis=axis, req=req, exc=exc, tags=tags, desc=desc, extra=extra))

FRONT_EXC = ["rule:rule_upside_down"]

# ---- stat
core("early_scales", "Vảy Sớm", "Early Scales", 0, "stat", [], [], ["nonattack"], "Start of combat: front-row Axies gain 5 Shield.")
core("dewdrop", "Giọt Sương", "Dewdrop", 0, "stat", [], [], ["nonattack"], "+1 Mana at the start of every turn.")
core("elder_trunk", "Thân Cổ Thụ", "Elder Trunk", 0, "stat", [], [], ["nonattack", "tradeoff"], "Every Axie gets +8 Max HP, but every damage face deals 1 less (min 1).")
# ---- dice
core("prime_chain", "Chuỗi Mồi", "Prime Chain", 0, "dice", [], [], ["nonattack", "convert_to_dmg"], "Using a shield or mana face primes the neighbouring Axies: their next damage face this turn deals +3.")
core("finisher", "Kết Cục", "Final Blow", 0, "dice", [], [], ["nonattack"], "The last die you use each turn gets +1 for every die used before it (max +4).")
core("prism", "Đa Sắc", "Prism", 1, "dice", ["faces_distinct:4"], [], ["nonattack"], "End of turn: if you used 4 or more different face types, the whole team gains 3 Shield and +2 Mana.")
core("steady_hold", "Giữ Vững", "Steady Hold", 1, "dice", [], ["rule:rule_tundra"], ["nonattack"], "You can Hold 2 dice per turn, and the same die can be held two turns in a row. A Held die gets +1 for every turn it has been held (max +3), lost once it is used.")
core("kindle", "Cất Lửa", "Kindle", 1, "dice", [], [], ["nonattack"], "A Held die has Focus: used next turn it deals +4 (+8 if held two turns in a row).")
core("sonic_shield", "Sóng Khiên", "Shield Wave", 1, "dice", ["face:shield"], [], ["nonattack", "convert_to_dmg"], "Shield and heal faces also deal damage equal to half their value (rounded up) to the enemy targeting that Axie.")
core("fissure", "Vết Nứt", "Fissure", 1, "dice", ["face:poison|weaken|vulnerable|blind|freeze|stun"], [], ["nonattack", "convert_to_dmg"], "Poison and debuff faces that hit make the enemy take +25% from all damage until the end of next turn and strip its Armor.")
core("field_medic", "Y Sĩ Chiến Trường", "Field Medic", 1, "dice", ["faces_distinct:3", "faces_nondmg:2"], ["owned:c_toxic_still"], ["nonattack", "tradeoff"], "Damage faces deal 2 less (min 1). Heal, shield, poison, mana and debuff faces get +3.")
core("plague_spread", "Độc Lan", "Contagion", 1, "dice", ["face:poison"], [], ["nonattack", "convert_to_dmg"], "When a poisoned enemy dies, its remaining poison spreads to every living enemy. Poison faces give +2 stacks.")
core("mirror_face", "Mặt Gương", "Mirror Face", 2, "dice", [], [], ["nonattack"], "The first die you use each turn is not spent: use it a second time, with a new target. The second use gets no Prime, Finisher or Focus.")
core("sixth_die", "Con Xúc Xắc Thứ Sáu", "Sixth Die", 2, "dice", [], [], ["nonattack"], "Each turn, roll one extra die from a random living Axie. Use it this turn; it vanishes at end of turn.")
core("whittle", "Gọt Xúc Xắc", "Whittled Die", 2, "dice", [], [], ["nonattack", "tradeoff"], "The team's weakest face slot is locked: a die that rolls it rerolls once. Every other face gets +1.")
core("three_dice", "Ba Viên", "Three Dice", 2, "dice", [], [], ["nonattack", "tradeoff"], "You can use at most 3 dice per turn. Dice you did not use are Held automatically and have Focus +3 next turn.")
core("concord", "Đồng Tâm", "Concord", 2, "dice", ["class_pair"], [], ["nonattack"], "Start of turn: Axies of the same class roll the same face. Each face used right after a face from the same part gets +2.")
core("toxic_still", "Lò Độc", "Toxic Still", 2, "dice", ["face:poison"], ["owned:c_field_medic", "owned:c_cascade"], ["nonattack", "tradeoff"], "Damage faces deal 2 less (min 1). End of turn: every poisoned enemy gains poison equal to half its stacks (rounded up, max +4).")
# ---- pos
core("bastion", "Thành Trì", "Bastion", 0, "pos", [], FRONT_EXC, ["nonattack", "front"], "Front-row Axies take 2 less from single-target hits.")
core("gatekeeper", "Kẻ Gác Cổng", "Gatekeeper", 1, "pos", [], FRONT_EXC, ["nonattack", "front"], "Enemies that hit a front-row Axie with a single-target attack take 3 pierce thorns. Each such hit gives your team's next damage face +2 (max +6, ends with the turn).")
core("thorn_growth", "Gai Mọc", "Thorn Growth", 1, "pos", ["front_hero", "face:thorns|shield"], FRONT_EXC, ["nonattack", "front"], "Each time a front-row Axie is hit by a single-target attack, it gains +1 Thorns for the rest of the fight.")
core("thorn_shield", "Khiên Gai", "Thorn Shield", 1, "stat", ["face:shield|thorns"], [], ["nonattack"], "End of your turn, every 2 leftover Shield on an Axie turns into 1 Thorns (that Shield is lost).")
core("thorn_rebound", "Phản Chấn", "Rebound", 2, "rule", ["face:thorns|shield"], [], ["nonattack", "tradeoff"], "The Axie with the most Thorns reflects its Thorns a second time on every hit, but it cannot use damage faces.")
core("backline_glow", "Hàng Sau Phát Sáng", "Backline Glow", 1, "pos", ["back_face:heal|mana|buff"], ["owned:c_open_ranks"], ["nonattack"], "Back-row Axies: buff, heal and mana faces get +50% (rounded up, at most +8).")
core("living_wall", "Bức Tường Sống", "Living Wall", 2, "pos", [], ["owned:c_open_ranks"] + FRONT_EXC, ["nonattack", "front"], "Only slot 1 is the front row. That Axie gets +12 Max HP and 2 Thorns. The other four are the back row.")
core("open_ranks", "Đội Hình Mở", "Open Ranks", 2, "pos", [], ["owned:c_living_wall", "owned:c_backline_glow", "owned:c_descend", "rule:rule_rising_tide"] + FRONT_EXC, ["nonattack", "front"], "No back row: all 5 Axies are front row, and every front-row Core applies to the whole team.")
core("growing_shell", "Mai Lớn Dần", "Growing Shell", 1, "pos", ["front_hero"], FRONT_EXC, ["nonattack", "front"], "Each enemy a front-row Axie kills gives it +1 Max HP for the run. If it falls, it loses two thirds of the stacks.")
core("descend", "Xuống Trận", "Take The Field", 2, "pos", ["back_face:heal"], ["owned:c_open_ranks"] + FRONT_EXC, ["nonattack", "convert_to_dmg"], "Pick a back-row Axie with heal faces: it moves to the front for good, its heal and buff faces become damage faces +2, +8 Max HP, 30% lifesteal.")
# ---- mana
core("tidecaller", "Ngọn Triều", "Rising Wave", 0, "mana", [], [], ["nonattack", "convert_to_dmg"], "Every 2 Mana you spend deals 2 damage to all enemies.")
core("mana_pool", "Hồ Mana", "Mana Pool", 0, "mana", [], ["rule:rule_dry_steppe"], ["nonattack"], "Mana faces give +1. End of turn: every 3 unspent Mana earns 1 more (max +3 per turn).")
core("mana_ward", "Đổi Mana Lấy Khiên", "Mana Ward", 1, "mana", [], [], ["nonattack"], "End of turn, spend up to 6 unused Mana: every 2 Mana gives each front-row Axie 3 Shield.")
core("overflow", "Bể Tràn", "Overflow", 1, "mana", [], ["rule:rule_dry_steppe"], ["nonattack", "convert_to_dmg"], "Mana above 8 turns into pierce damage to all enemies and drops back to 8.")
core("hollow_core", "Lõi Rỗng", "Hollow Core", 2, "mana", [], ["owned:c_thorn_pact", "rule:rule_cheap_mana", "rule:rule_tundra"], ["nonattack"], "No free reroll. Every reroll costs 1 Mana, up to 8 per turn. Mana faces give +1. Each die you reroll gets +1 until end of turn (max +10).", rerollUp=-1)
core("deep_current", "Mạch Ngầm", "Deep Current", 2, "mana", [], ["rule:rule_dry_steppe"], ["nonattack"], "Leftover Mana carries into the next combat (up to 12) instead of resetting.")
core("thorn_pact", "Khế Ước Gai", "Thorn Pact", 1, "mana", [], ["owned:c_hollow_core", "rule:rule_cheap_mana", "rule:rule_tundra"], ["nonattack", "tradeoff"], "Rerolls cost no Mana but 2 HP of the Axie being rerolled (not allowed at 2 HP or less). Axies at half HP or lower get +2 on every face.")
# ---- quest
core("collector", "Nhà Sưu Tầm", "Collector", 1, "quest", ["faces_distinct:4"], [], ["nonattack"], "Quest: use 4 different face types in one turn, in 3 different fights. Until done: +1 Mana every turn.", quest={"kind": "distinct_faces_turn", "faces": 4, "steps": [{"target": 3, "reward_tier": 1}]})
core("dry_well", "Hồ Cạn", "Dry Well", 1, "quest", [], [], ["nonattack"], "Quest: spend 40 Mana in total. Until done: +2 Mana at the start of each fight.", quest={"kind": "mana_spent", "steps": [{"target": 40, "reward_tier": 1}]})
core("night_watch", "Kẻ Gác Đêm", "Night Watch", 1, "quest", [], [], ["nonattack"], "Quest: beat the next boss without losing an Axie. Until done: front-row Axies +3 Max HP.", quest={"kind": "boss_no_loss", "steps": [{"target": 1, "reward_tier": 2}]})
core("key_strike", "Trọng Điểm", "Key Strike", 1, "quest", [], [], ["nonattack"], "Quest: use a Held die for 9 or more damage, 3 times. Until done: the same die can be held two turns in a row.", quest={"kind": "held_big_hit", "min": 9, "steps": [{"target": 3, "reward_tier": 1}]})
core("chimera_hunt", "Săn Chimera", "Chimera Hunt", 1, "quest", [], [], ["attack"], "Quest in 3 steps: kill 8 enemies with a finishing die for +1 Core reroll; kill 20 for an Amber Core pick; kill a boss with a finishing die for a Crystal Core pick.", quest={"kind": "finisher_kills", "steps": [{"target": 8, "reward_tier": -1, "reward": "core_reroll"}, {"target": 20, "reward_tier": 1}, {"target": 1, "reward_tier": 2, "boss": True}]})
# ---- rule (axis "rule")
core("nest", "Tổ Ấm", "Nest", 0, "rule", [], [], ["nonattack", "egg"], "Start of combat: 1 Egg. Eggs count as front row, so single-target enemy attacks can pick them.")
core("golden_egg", "Trứng Vàng", "Golden Egg", 1, "rule", ["egg_source"], [], ["nonattack"], "When an Egg dies or hatches: +3 Mana, 4 Shield to your weakest Axie, and your team's next damage face gets +3.")
core("blood_sign", "Chữ Ký Máu", "Blood Sign", 2, "rule", ["face:poison"], [], ["nonattack", "convert_to_dmg"], "Damage faces add 1 poison per 3 damage dealt (rounded down). Poison faces also deal damage equal to half their value.")
core("loop", "Vòng Lặp", "Loop", 2, "rule", ["face:cantrip"], [], ["nonattack"], "Cantrip faces reroll and are used one extra time each turn.")
core("cascade", "Thác Đổ", "Cascade", 2, "rule", [], ["rule:rule_balance", "owned:c_toxic_still"], ["attack"], "Damage faces used back to back form a chain: the 2nd gets +2, the 3rd +4, the 4th +6, the 5th+ +8. Using a non-damage face breaks the chain.")
core("sacrifice", "Hiến Tế", "Sacrifice", 2, "rule", [], [], ["nonattack", "tradeoff"], "Start of combat: the Axie in slot 5 sleeps (no die, cannot be targeted). The other four get +2 on every face and 1 extra free reroll each turn.", rerollUp=1)
core("spore_burst", "Nổ Bào Tử", "Spore Burst", 0, "rule", [], [], ["nonattack", "convert_to_dmg"], "When an Axie falls it bursts: every enemy loses 20% of its Max HP (boss 8%), ignoring Shield. Eggs burst for half.")
# ---- gacha C5 meme Cores (design/proposals/meme-cores.md): Moss, weak but funny, hidden in the account's first run, at most one per offer
core("meme_copycat", "Bản Sao", "Copycat", 0, "dice", [], [], ["meme"], "Each turn you have a Set, your weakest die outside it copies the Set's part, but only for 1.", first_run_hidden=True)
core("meme_nametag", "Thẻ Tên", "Name Tag", 0, "rule", [], [], ["meme"], "Start of combat: a random enemy gets a silly name. Kill it for +1 Mana.", first_run_hidden=True)
core("meme_jumpy", "Xúc Xắc Nhảy", "Jumpy Dice", 0, "dice", [], [], ["meme"], "After the roll, two random dice jump and swap places. Sometimes it helps.", first_run_hidden=True)
core("fossil", "Hoá Thạch", "Fossil", 0, "rule", [], [], ["nonattack"], "Does nothing now and takes a slot. Your next Core pick is one tier higher (Crystal: 4 cards; already 4 cards: +1 Core reroll), then it disappears. Only shows at picks 1-2.", first_run_hidden=True, bet=True, pick_max=2, kn={"next_pick_tier_up": 1, "crystal_extra_card": 4})
core("dim_stone", "Hòn Đá Mờ", "Dim Stone", 1, "rule", [], [], ["nonattack"], "Pick this: nothing now, but you get a random Crystal Core of another axis. Not at pick 2, not at the last pick.", first_run_hidden=True, bet=True, kn={"grant_crystal_other_axis": True, "not_pick": [2, "last"], "max_chain_t": 2})
# ---- disabled by design (2.10)
core("spearhead", "Mũi Giáo", "Spearhead", 0, "pos", [], FRONT_EXC, ["attack", "front"], "Front-row Axies: damage faces +2.", disabled=True, needs="cut 2.10")
core("squad_up", "Hợp Đội", "Squad Up", 1, "pos", ["class_pair"], [], ["attack"], "Axies next to an Axie of the same class: damage faces +2.", disabled=True, needs="cut 2.10")
core("wicked_tally", "Tích Ác", "Wicked Tally", 1, "dice", [], [], ["attack"], "Each time a finishing die kills an enemy it gets +1 for the run (max +6).", disabled=True, needs="cut 2.10")
core("verdict", "Phán Quyết", "Verdict", 2, "rule", [], [], ["attack"], "Enemies under 20% HP die at once (not bosses). Finishing faces always Execute.", disabled=True, needs="cut 2.10")

# ---- Cores v5 (design/proposals/cores-rules-v5.md section 10, 23/10)
core("bloodline_ward", "Phòng Thủ Huyết Thống", "Bloodline Ward", 0, "pos", ["class_pair"], [], ["nonattack"], "When an Axie gains Shield from a shield face, each adjacent Axie of the same class gains half of it (rounded up).")
core("smoldering", "Than Âm Ỉ", "Smoldering Coals", 0, "mana", [], ["rule:rule_dry_steppe"], ["nonattack"], "End of turn: each Held die gives +1 Mana (max +2 per turn).")
core("cache_plate", "Giáp Cất", "Cache Plate", 1, "dice", ["face:shield"], [], ["nonattack"], "When you Hold a die showing a shield face, its Axie gains half that Shield now (rounded up, min 2, max 6, no M). Once per die per turn. The die keeps its full face for next turn.")
core("golden_thread", "Sợi Chỉ Vàng", "Golden Thread", 1, "mana", ["stage_min:2"], [], ["nonattack"], "Wild Face costs 1 less Mana (min 1) and can be used 2 times per fight. A Set of four made with a Wild Face gets +0.20 M.")

# Run rules: slug, vn, name, weight, desc, extra
R = []
def rule(slug, vn, name, weight, desc, **extra):
    R.append(dict(slug=slug, vn=vn, name=name, weight=weight, desc=desc, extra=extra))

rule("none", "Không luật", "No Rule", 0, "No Run Rule: play the base game.")
rule("cheap_mana", "Mana Rẻ", "Cheap Mana", 1, "Every reroll costs 1 Mana, there is no free reroll, and you get at most 5 rerolls a turn. Teams without Mana get stuck.", rerollUp=-1, knobs={"reroll_mana_cost": 1, "free_reroll": 0, "reroll_max_total": 5, "asc_lt": 3})
rule("tundra", "Băng Nguyên", "Tundra", 1, "No free reroll (rerolls cost 2 Mana). You can Hold 2 dice, and a Held die gets +2 when used next turn.", rerollUp=-1, knobs={"free_reroll": 0, "stash_cap": 2, "focus": 2})
rule("quick_beat", "Nhịp Gấp", "Quick Beat", 1, "Boss rhythm is only 2 turns (Strike, Hollow, Strike...), and Strike turns hit 20% harder.", knobs={"boss_rhythm_period": 2, "strike_mult": 1.2})
rule("starfall", "Mưa Sao Khởi Nguyên", "Genesis Starfall", 1, "Your first Core pick is a Crystal Core. Normal and elite enemies have +15% HP all run.", knobs={"first_tier": 2, "enemy_hp_mult": 1.15})
rule("heavy_finish", "Kết Nặng", "Heavy Finish", 1, "The last die you use each turn gets +3, but enemies deal 10% more damage.", knobs={"finisher_bonus": 3, "enemy_dmg_mult": 1.1})
rule("wasteland", "Đất Hoang Huyền Bí", "Mystic Wasteland", 1, "Only 3 Core picks (no pick after the elite), but each shows 4 cards. Every Axie +4 Max HP.", knobs={"core_picks": 3, "core_cards": 4, "party_hp": 4})
rule("dry_steppe", "Thảo Nguyên Khô", "Dry Steppe", 1, "Mana does not carry over: leftover Mana is lost at end of turn. +2 Mana at the start of every turn.", knobs={"mana_carry": 0, "turn_mana": 2})
rule("rising_tide", "Thuỷ Triều Lên", "Rising Tide", 1, "Each fight one row is in the water: the front row takes 25% less damage, or the back row's damage faces get +2. They alternate fight by fight.", knobs={"front_dmg_taken": 0.75, "back_dmg": 2})
rule("upside_down", "Thế Giới Lộn Ngược", "Upside Down", 1, "Single-target enemy attacks pick the back row first. The front row only takes AoE.", knobs={"enemy_target_row": "back"})
rule("old_forest", "Rừng Già", "Old Forest", 2, "Every Axie and enemy has +30% HP. Heal and poison faces are 50% stronger. Fights run long, so spamming damage runs out of steam.", knobs={"hp_mult": 1.3, "heal_poison_mult": 1.5})
rule("crow", "Quạ Đưa Tin", "Crow Herald", 1, "The fight before each Core pick (from pick 2): win within 5 turns (boss 7) with nobody down and the pick is one tier higher; if an Axie falls, one tier lower.", knobs={"fast_turns": 5, "fast_turns_boss": 7})
rule("hard_shell", "Vỏ Cứng", "Hard Shell", 2, "Every enemy has Armor 2: single-target damage faces deal 2 less (min 1). Poison, pierce, thorns and AoE are not reduced. Shield, poison and debuff faces get +2.", knobs={"plating_global": 2, "side_face_bonus": 2}, requires_extra=["team_can_break"])
rule("balance", "Thế Cân Bằng", "Balance", 2, "From the 3rd damage face each turn, damage faces deal 2 less (min 1). Every non-damage face you use gives +1 Mana. You cannot stack five attacks.", knobs={"dmg_use_soft_cap": 2, "dmg_overuse_penalty": 2, "nondmg_mana": 1})

def q(s): return '"' + s.replace('\\', '\\\\').replace('"', '\\"') + '"'
def psa(l): return "PackedStringArray(" + ", ".join(q(x) for x in l) + ")" if l else "PackedStringArray()"
def dv(v):
    if isinstance(v, bool): return "true" if v else "false"
    if isinstance(v, str): return q(v)
    if isinstance(v, (int, float)): return repr(v)
    if isinstance(v, list): return "[" + ", ".join(dv(x) for x in v) + "]"
    if isinstance(v, dict): return "{" + ", ".join(q(k) + ": " + dv(x) for k, x in v.items()) + "}"
    raise ValueError(v)

NOHOOK = set()   # data-only rules (knobs read by lane B)
HEAD = '[gd_resource type="Resource" script_class="RelicDef" load_steps=2 format=3]\n\n[ext_resource type="Script" path="res://scripts/data_models/relic_def.gd" id="1"]\n\n[resource]\nscript = ExtResource("1")\n'

def emit(dirp, id_, name, desc, tier, axis, req, exc, tags, layer, idx, extra, is_rule=False, weight=1, knobs=None):
    L = [HEAD.rstrip("\n")]
    L.append("id = " + q(id_)); L.append("name = " + q(name)); L.append("description = " + q(desc))
    L.append("rarity = %d" % tier); L.append('archetype = ""'); L.append("mload = 0")
    L.append("sort_index = %d" % (200000 + tier * 1000 + idx))
    L.append("hook_key = " + q("" if (extra.get("disabled") or id_ in NOHOOK) else id_)); L.append("tags = " + psa(tags)); L.append("layer = " + q(layer))
    L.append("core_axis = " + q("run_rule" if is_rule else axis))
    if req: L.append("requires = " + psa(req))
    if exc: L.append("excludes = " + psa(exc))
    ex = dict(extra)
    if ex.pop("disabled", False): L.append("disabled = true"); L.append("hidden_from_pool = true")
    if ex.pop("first_run_hidden", False): L.append("first_run_hidden = true")
    if is_rule: L.append("run_rule = true"); L.append("weight = %d" % weight)
    nd = ex.pop("needs", "")
    if nd: L.append("needs_hook = " + q(nd))
    qu = ex.pop("quest", None)
    if qu: L.append("quest = " + dv(qu))
    ru = ex.pop("requires_extra", None)
    ru_notes = ex.pop("bet", None); ex.pop("pick_max", None)
    kn = dict(knobs or {})
    if ex.pop("bet", None): pass
    ri = ex.pop("rerollUp", None)
    if ri is not None: L.append("rerollUp = %s" % float(ri))
    if kn: L.append("rule_knobs = " + dv(kn))
    return "\n".join(L) + "\n"

def main():
    out = sys.argv[1]; only = set(sys.argv[2:])
    n = 0
    for i, c in enumerate(C):
        id_ = "c_" + c["slug"]
        if only and id_ not in only: continue
        layer = {"stat": "economy", "dice": "dice", "pos": "positional", "mana": "economy", "quest": "enabler", "rule": "engine"}[c["axis"]]
        ex = dict(c["extra"]); knobs = {}
        if ex.get("bet"): knobs = {"bet": True, "pick_max": ex.get("pick_max", 0)}
        knobs.update(ex.pop("kn", {}))
        open(os.path.join(out, id_ + ".tres"), "w").write(emit(out, id_, c["name"], c["desc"], c["tier"], c["axis"], c["req"], c["exc"], c["tags"], layer, i, ex, knobs=knobs))
        n += 1
    for i, r in enumerate(R):
        id_ = "rule_" + r["slug"]
        if only and id_ not in only: continue
        ex = dict(r["extra"]); kn = ex.pop("knobs", {})
        rq = ex.pop("requires_extra", [])
        open(os.path.join(out, id_ + ".tres"), "w").write(emit(out, id_, r["name"], r["desc"], 0, "run_rule", rq, [], ["rule"], "engine", 500 + i, ex, is_rule=True, weight=r["weight"], knobs=kn))
        n += 1
    print("wrote", n)

if __name__ == "__main__":
    main()
