extends Node
## Gacha lane GD: Core draw sim (no fights). Plays only the Core/Rule offers of whole Short runs through the real RunState +
## CoreOffer + tier chain, with two pick policies, and counts how often combos form.
## Args (after `--`): --runs=5000 --seed=1 --out=<md path>
## Policies: random (random card, no reroll) | hunt (card that completes a Full/Pair, else a card with a partner already owned,
## else random; rerolls a no-partner card when no card completes anything). Quest bonus picks, shop and event Cores are NOT
## simulated (milestone picks only). Never touches the network; the bot uses its own Rng.
const TEAMS := [
	["beast1", "bird1", "beast1", "bird1", "beast1"], ["aqua1", "plant1", "aqua1", "plant1", "aqua1"],
	["reptile1", "bug1", "reptile1", "bug1", "reptile1"], ["plant1", "beast1", "aqua1", "reptile1", "bug1"],
	["beast1", "bird1", "aqua1", "bug1", "reptile1"], ["plant1", "plant1", "reptile1", "aqua1", "bird1"],
	["reptile1", "plant1", "reptile1", "plant1", "reptile1"]]


func _arg(name: String, d: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--%s=" % name):
			return a.substr(name.length() + 3)
	return d


func _ready() -> void:
	var runs := int(_arg("runs", "5000"))
	var seed0 := int(_arg("seed", "1"))
	var out_path := _arg("out", "")
	var combos := CoreCombos.all([])
	var rep := "# Combo draw sim (gacha lane GD)\n\n%d Short runs per policy, seed base %d, real RunState + CoreOffer + tier chain, 4 milestone Core picks + Run Rule card, no fights. Quest bonus / shop / event Cores are not simulated (they only add draws, so these are lower bounds). Rerolls: 2 base + combo bonus.\n\n" % [runs, seed0]
	for policy in ["random", "hunt"]:
		var st := _run_policy(policy, runs, seed0)
		rep += _fmt(policy, runs, st, combos)
	print(rep)
	if out_path != "":
		var f := FileAccess.open(out_path, FileAccess.WRITE)
		f.store_string(rep)
		f.close()
	RunState.reset()
	get_tree().quit(0)


func _run_policy(policy: String, runs: int, seed0: int) -> Dictionary:
	var any_pair := 0
	var any_full := 0
	var jackpot := 0
	var jack2 := 0
	var formed := {}      # combo id -> runs formed (pair or better)
	var fulls := {}
	var shown := {}       # core id -> times shown in a milestone offer card (first sight)
	var picked := {}
	var sum_combos := 0
	for i in runs:
		var seed := seed0 + i * 7919
		var rng := Rng.new(seed ^ 0x51AB)
		RunState.reset()
		RunState.start_new_run_seeded(seed, {"team_keys": TEAMS[i % TEAMS.size()], "mode": "short", "ascension": 0, "ranked": false,
			"bonuses": {}, "loadout": {"rules_on": true}})
		var guard := 0
		while guard < 12:
			guard += 1
			if RunState.pending_rewards.is_empty():
				if not RunState._open_core_offer():
					if RunState.core_pick_index >= CoreOffer.picks_total("short"):
						break
					continue
			var first: Dictionary = RunState.pending_rewards[0]
			if bool(first.get("rule", false)):
				RunState.apply_chosen_reward(RunState.pending_rewards[rng.next_int(RunState.pending_rewards.size())])
				continue
			for c in RunState.pending_rewards:
				shown[String(c["key"])] = int(shown.get(String(c["key"]), 0)) + 1
			var idx := _choose(policy, rng)
			var card: Dictionary = RunState.pending_rewards[idx]
			var sell := ""
			var chk := RelicSlots.check_add(RunState.owned_relic_ids, RunState.relic_stickers, String(card["key"]), 0, false)
			if bool(chk["needs_sell"]):
				sell = String((chk["sell_from"] as Array)[0])
			picked[String(card["key"])] = int(picked.get(String(card["key"]), 0)) + 1
			RunState.apply_chosen_reward(card, sell)
			RunState.pending_rewards = []
		var done := RunState.combo_done
		if not done.is_empty():
			any_pair += 1
		sum_combos += done.size()
		var fl := false
		for cid in done:
			formed[cid] = int(formed.get(cid, 0)) + 1
			if done[cid] == "full":
				fl = true
				fulls[cid] = int(fulls.get(cid, 0)) + 1
		if fl:
			any_full += 1
		if done.has("combo_rain"):
			jackpot += 1
		var jm := 0
		for jid in CoreCombos.members(CoreCombos.get_combo("combo_rain")):
			if RunState.owned_relic_ids.has(jid):
				jm += 1
		if jm >= 2:
			jack2 += 1
	return {"any_pair": any_pair, "any_full": any_full, "jackpot": jackpot, "jack2": jack2, "formed": formed, "fulls": fulls, "shown": shown,
		"picked": picked, "sum": sum_combos}


func _choose(policy: String, rng: Rng) -> int:
	var offer: Array = RunState.pending_rewards
	if policy == "random":
		return rng.next_int(offer.size())
	var owned: Array = RunState.combo_owned_ids()
	var best := -1
	var best_score := -1
	var cands: Array = []
	for _try in 3:
		cands = []
		best_score = -1
		for i in offer.size():
			var key := String((offer[i] as Dictionary)["key"])
			var s := 0
			var cc := CoreCombos.card_completes(owned, key)
			if not cc.is_empty():
				s = 3 if cc["tier"] == "full" else 2
			elif not CoreCombos.matches(owned, key).is_empty():
				s = 1
			if s > best_score:
				best_score = s
				cands = [i]
			elif s == best_score:
				cands.append(i)
		if best_score >= 1:
			break
		# nothing connects: spend a reroll on the first card (one per slot), then look again
		var rr := false
		for i in offer.size():
			if RunState.core_can_reroll(i) and RunState.reroll_pending_rewards(rng.next_int(1 << 30), i):
				rr = true
				break
		if not rr:
			break
		offer = RunState.pending_rewards
	best = cands[rng.next_int(cands.size())]
	return best


func _fmt(policy: String, runs: int, st: Dictionary, combos: Array) -> String:
	var s := "## Policy: %s\n\n" % policy
	s += "- Runs with >=1 combo (Pair or better): **%.1f%%**\n- Runs with >=1 Full: **%.1f%%**\n- Jackpot (Lunacia Rain): **%.2f%%**\n- Runs holding 2 of the 3 jackpot Cores: %.2f%%\n- Avg combos formed per run: %.2f\n\n" % [
		100.0 * st["any_pair"] / runs, 100.0 * st["any_full"] / runs, 100.0 * st["jackpot"] / runs, 100.0 * st["jack2"] / runs, float(st["sum"]) / runs]
	s += "| Combo | Formed % | Full % |\n|---|---|---|\n"
	for r in combos:
		s += "| %s | %.1f | %.1f |\n" % [r["name_en"], 100.0 * int(st["formed"].get(r["id"], 0)) / runs, 100.0 * int(st["fulls"].get(r["id"], 0)) / runs]
	var rows: Array = []
	for k in st["shown"]:
		var sh := int(st["shown"][k])
		rows.append([k, sh, int(st["picked"].get(k, 0))])
	rows.sort_custom(func(a, b): return float(a[2]) / maxf(a[1], 1) > float(b[2]) / maxf(b[1], 1))
	s += "\nCores picked in more than 60% of the offers where they appeared (shown >= 30):\n\n"
	var any := false
	for r in rows:
		if r[1] >= 30 and float(r[2]) / r[1] > 0.6:
			s += "- %s: %d/%d = %.0f%%\n" % [r[0], r[2], r[1], 100.0 * r[2] / r[1]]
			any = true
	if not any:
		s += "- none\n"
	s += "\nEvery Core: tier / axis / cards shown per run (a Core can show twice in one run through rerolls):\n\n| Core | Tier | Axis | Shown per 100 runs |\n|---|---|---|---|\n"
	rows.sort_custom(func(a, b): return a[1] > b[1])
	for r in rows:
		var d = RelicRegistry.get_def(String(r[0]))
		s += "| %s | %s | %s | %.1f |\n" % [r[0], ["R", "H", "T"][int(d.rarity)], d.core_axis, 100.0 * r[1] / runs]
	return s + "\n"
