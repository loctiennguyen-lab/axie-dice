class_name RunCard
extends RefCounted
## Lane GM (D4): the shareable text of a finished run: team, Cores, combos, seed, run rule. Pure: takes the Result
## snapshot dictionary, reads names from ContentDB / RelicRegistry / ComboAdapter, touches no state.

static func core_name(id: String) -> String:
	var d = RelicRegistry.get_def(id)
	return UI3.title_case(UI3.player_text(String(d.name))) if d != null else id


## "Pair" / "Full" word for a combo tier.
static func tier_word(tier: String) -> String:
	return "Full" if tier == "full" else "Pair"


## Names of up to 3 Crystal Cores the player was offered and did not take (A8 near-miss).
static func skipped_names(skipped: Array) -> Array[String]:
	var out: Array[String] = []
	for id in skipped:
		if out.size() >= 3:
			break
		out.append(core_name(String(id)))
	return out


static func text(s: Dictionary) -> String:
	var team: Array[String] = []
	for e in (s.get("roster", []) as Array):
		var k := String((e as Dictionary).get("hero_key", ""))
		var d: Dictionary = ContentDB.heroes.get(k, {})
		team.append("%s T%d" % [String(d.get("n", k)), int((e as Dictionary).get("tier", 1))])
	var cores: Array[String] = []
	for id in (s.get("relic_ids", []) as Array):
		cores.append(core_name(String(id)))
	var combos: Array[String] = []
	var done: Dictionary = s.get("combo_done", {})
	for cid in done:
		combos.append("%s (%s)" % [ComboAdapter.display_name(String(cid)), tier_word(String(done[cid]))])
	var rule := String(s.get("run_rule", ""))
	var lines: Array[String] = [
		"Axie Dice run: %s" % ("WON" if bool(s.get("won", false)) else "lost"),
		"Team: %s" % ", ".join(team),
		"Cores: %s" % (", ".join(cores) if not cores.is_empty() else "none"),
		"Combos: %s" % (", ".join(combos) if not combos.is_empty() else "none"),
		"Run rule: %s" % (core_name(rule) if rule != "" else "none"),
		"Mode: %s A%d · Seed: %d" % [String(s.get("mode", "short")), int(s.get("ascension", 0)), int(s.get("seed", 0))],
	]
	return "\n".join(lines)
