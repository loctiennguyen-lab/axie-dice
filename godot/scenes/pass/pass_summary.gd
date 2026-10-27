class_name PassSummary
extends RefCounted
## One read of the Pass for every screen that shows it (QA S2-1 / BUG-0007). The Pass screen and the run Result
## screen both take name, level, XP and next reward from here, i.e. from Pass v2 (pass_v2.json), the table the
## server (worker/src/economy.js) also uses. The old BP_TRACK ("Lunacia Pass") is not read here.

const _Econ := preload("res://scripts/meta/economy_db.gd")
const NAME := "Season Pass"


## `ps` = MetaState.pass_season. A save from another season reads as empty, like PassView.ps().
static func info(ps: Dictionary) -> Dictionary:
	var cfg: Dictionary = _Econ.get_table("pass_v2")
	var same := String(ps.get("id", "")) == String(cfg.get("season_id", ""))
	var xp := int(ps.get("xp", 0)) if same else 0
	var lv := PassV2.level_for_xp(xp)
	var cur_total := int(PassV2.level_def(lv).get("xp_total", 0))
	var nxt := PassV2.level_def(lv + 1)
	var out := {"name": NAME, "xp": xp, "level": lv, "into": 0, "needed": 0, "percent": 100.0, "next_level": 0, "next_reward": ""}
	if nxt.is_empty():
		var loop := int((cfg.get("post30_loop", {}) as Dictionary).get("xp", 2000))
		out["into"] = (xp - PassV2.max_xp()) % loop
		out["needed"] = loop
		out["percent"] = 100.0 * float(out["into"]) / float(loop)
		return out
	out["into"] = xp - cur_total
	out["needed"] = int(nxt.get("xp", 0))
	out["percent"] = minf(100.0, 100.0 * float(out["into"]) / maxf(float(out["needed"]), 1.0))
	out["next_level"] = lv + 1
	var names: Array[String] = []
	for r in nxt.get("free", []):
		names.append(PassView.reward_text(r as Dictionary))
	out["next_reward"] = ", ".join(names)
	return out


## "0 / 500 XP to level 1 · Lv 1 pays 300 Shard" (+ " · +N XP this run" only when the client really knows N).
static func line(i: Dictionary, xp_gained: int = -1) -> String:
	var head: String
	if int(i["next_level"]) > 0:
		head = "%s / %s XP to level %d" % [UI3.fmt(int(i["into"])), UI3.fmt(int(i["needed"])), int(i["next_level"])]
		if String(i["next_reward"]) != "":
			head += " · Lv %d pays %s" % [int(i["next_level"]), String(i["next_reward"])]
	else:
		head = "Loop: %s / %s XP" % [UI3.fmt(int(i["into"])), UI3.fmt(int(i["needed"]))]
	if xp_gained > 0:
		head += " · +%s XP this run" % UI3.fmt(xp_gained)
	return head
