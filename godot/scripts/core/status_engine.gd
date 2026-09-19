class_name StatusEngine
extends RefCounted
## Status-effect application + end-of-turn decay. Two separate responsibilities, both
## ported from engine.js, kept in one file because they operate on the same `status`
## Dictionary and rule spec §3 describes them together:
##
##  - add_status()  == engine.js addStatus(s,t,kws,src) — called while a face resolves
##    (doFace), applies a NEW stack of poison/burn/regen/blind/weaken/vulnerable/thorns/
##    stun/freeze/undying/enrage. THORNS_CAP is enforced HERE (on apply), matching JS:
##    thorns never decays over turns, so the cap has to live at the only place thorns
##    stacks grow, not in the decay pass below.
##  - tick_status()  == engine.js tickStatus(s) — called once at END_TURN, decays
##    poison/burn/regen/blind/weaken/vulnerable. Thorns/stun/freeze/undying are
##    deliberately NOT touched here: thorns never decays (see above), stun is consumed
##    in CombatEngine's enemy-action loop (skip-this-turn-then-clear, not a turn-end
##    tick), freeze transitions in CombatEngine.roll_all() (frozen_next -> frozen), and
##    undying is consumed inside DamagePipeline at the moment it prevents a death.
##    This split exactly matches where engine.js itself performs each of these —
##    see design/gdd/godot-port-rule-spec.md §3.

const THORNS_CAP := 8


static func _die_has_keyword(die: Array, kw: String) -> bool:
	for f in die:
		if (f.get("keywords", []) as Array).has(kw):
			return true
	return false

static func _any_unit_die_has_keyword(units: Array, kw: String) -> bool:
	for u in units:
		if _die_has_keyword(u.die, kw):
			return true
	return false


## kws: Array[String] like ["poison:2"], ["thorns", "regen:1"] — matches JS addStatus
## keyword-string parsing (`name` or `name:N`, defaulting N=1).
static func add_status(combat, tgt: Unit, kws: Array, src: Unit = null) -> void:
	for raw in kws:
		var parts: PackedStringArray = String(raw).split(":", true, 1)
		var n: String = parts[0]
		var v: int = int(parts[1]) if parts.size() > 1 else 1

		if n == "poison":
			if src != null and src.side == "p" and src.cls == "bug" and int(tgt.status.get("poison", 0)) > 0:
				v += 2                                                          # VIRULENT passive
			tgt.status["poison"] = int(tgt.status.get("poison", 0)) + v
			EventBus.float_text.emit(tgt.uid, "PSN %d" % v, "poi", 0)
			if src != null and src.side == "p" and RelicHooks.has(combat, "poisonSpread"):
				var arr: Array = combat.alive_enemies() if tgt.side == "e" else combat.alive_party()
				var i := arr.find(tgt)
				var half := int(ceil(v / 2.0))
				for x in [arr[i - 1] if i > 0 else null, arr[i + 1] if i >= 0 and i < arr.size() - 1 else null]:
					if x != null:
						x.status["poison"] = int(x.status.get("poison", 0)) + half
						EventBus.float_text.emit(x.uid, "PSN %d" % half, "poi", 0)
			continue

		if n in ["thorns", "regen", "burn", "blind", "weaken", "vulnerable"]:
			if n == "thorns":
				tgt.status["thorns"] = min(THORNS_CAP, int(tgt.status.get("thorns", 0)) + v)
			else:
				tgt.status[n] = int(tgt.status.get(n, 0)) + v
			var cls_css := "buf" if (n == "thorns" or n == "regen") else "deb"
			EventBus.float_text.emit(tgt.uid, n.substr(0, 3).to_upper() + str(v), cls_css, 0)
		elif n == "stun":
			tgt.status["stun"] = 1
			EventBus.float_text.emit(tgt.uid, "STUN", "deb", 0)
		elif n == "freeze":
			if tgt.side == "p":
				tgt.frozen_next = true
				EventBus.float_text.emit(tgt.uid, "FREEZE", "deb", 0)
			else:
				tgt.status["stun"] = 1
				EventBus.float_text.emit(tgt.uid, "STUN", "deb", 0)
		elif n == "enrage":
			for f in tgt.die:
				if f.get("type", "") == "dmg":
					f["value"] = int(ceil(int(f.get("value", 0)) * 1.25))
			EventBus.float_text.emit(tgt.uid, "ENRAGE", "buf", 0)
		elif n == "undying":
			tgt.status["undying"] = 1
			EventBus.float_text.emit(tgt.uid, "UNDYING", "buf", 0)


## Called once per turn at END_TURN, over party.concat(enemies) in that fixed order
## (matches JS `s.party.concat(s.enemies)` — iteration order affects nothing balance-wise
## here since each unit's tick is independent, but keeping the same order helps side-by-side
## debugging against tools/sim.js logs).
static func tick_status(combat) -> void:
	var poison_ticks: int = int(RelicHooks.max_val(combat, "poisonTicks", 1.0))
	var plague: bool = RelicHooks.has(combat, "plague")
	var units: Array = combat.party + combat.enemies
	# Which effects actually did something this tick, for EventBus.status_tick's payload.
	# Collected, never acted on: nothing below branches on this, so it cannot change an
	# outcome. Deduplicated — five poisoned enemies are one poison event to a listener, not
	# five. `blind`/`weaken`/`vulnerable` are excluded on purpose: their tick only decrements
	# a counter, with no visible or audible consequence to announce.
	var resolved: Dictionary = {}
	for u in units:
		if u.hp <= 0:
			continue

		if int(u.status.get("poison", 0)) > 0:
			resolved["poison"] = true
			var t: int = poison_ticks if u.side == "e" else 1
			for i in t:
				# Re-read each tick with a default, never `u.status["poison"]`. Dealing this
				# damage can drop a boss to 0 and trip DamagePipeline.check_boss_phase(), which
				# resets `status` to {} (damage_pipeline.gd) — the very key being read is gone
				# by the time the next line runs. Direct indexing threw there; a poisoned agony
				# entering phase 2 aborted the rest of the status tick for every unit after it.
				if u.hp > 0 and int(u.status.get("poison", 0)) > 0:
					DamagePipeline.resolve({"combat": combat, "src": null, "tgt": u,
						"value": int(u.status.get("poison", 0)), "pierce": true})
			# The decay below must also tolerate the status having been wiped mid-loop: there is
			# nothing left to decay, and subtracting from a missing key would re-create it at -1.
			if int(u.status.get("poison", 0)) > 0:
				var keep_full: bool = u.side == "e" and (plague or _die_has_keyword(u.die, "plague") or _any_unit_die_has_keyword(combat.party, "plague"))
				if not keep_full:
					u.status["poison"] = int(u.status.get("poison", 0)) - 1
				else:
					EventBus.relic_pulsed.emit("plague", u.uid)

		if int(u.status.get("burn", 0)) > 0:
			resolved["burn"] = true
			var bm: float = RelicHooks.max_val(combat, "burnMult", 1.0)
			var base: int = int(int(u.status.get("burn", 0)) * (bm if u.side == "e" else 1.0))
			DamagePipeline.resolve({"combat": combat, "src": null, "tgt": u, "value": base, "pierce": true})
			var bt: int = int(RelicHooks.max_val(combat, "burnTicks", 1.0))
			if u.side == "e" and bt > 1:
				var ratio: float = RelicHooks.max_val(combat, "burnTickRatio", 0.7)
				for i in range(1, bt):
					if u.hp > 0:
						DamagePipeline.resolve({"combat": combat, "src": null, "tgt": u,
							"value": max(1, int(ceil(base * ratio))), "pierce": true})
				EventBus.relic_pulsed.emit("burnTicks", u.uid)
			if u.side == "e" and RelicHooks.has(combat, "burnSpread"):
				var arr: Array = combat.alive_enemies()
				var i: int = arr.find(u)
				var sp := int(ceil(int(u.status.get("burn", 0)) * 0.5))
				for x in [arr[i - 1] if i > 0 else null, arr[i + 1] if i >= 0 and i < arr.size() - 1 else null]:
					if x != null and x != u:
						x.status["burn"] = int(x.status.get("burn", 0)) + sp
						EventBus.float_text.emit(x.uid, "BUR%d" % sp, "deb", 0)
			# Same guard as poison above — a phase change during the burn ticks clears status.
			if u.hp > 0 and int(u.status.get("burn", 0)) > 0:
				if RelicHooks.has(combat, "burnSlow"):
					u.status["burn"] = int(u.status.get("burn", 0)) - 1
				else:
					u.status["burn"] = int(floor(int(u.status.get("burn", 0)) / 2.0))

		if int(u.status.get("regen", 0)) > 0:
			resolved["regen"] = true
			DamagePipeline.apply_heal(combat, u, int(u.status.get("regen", 0)))
			if u.hp > 0 and int(u.status.get("regen", 0)) > 0:
				u.status["regen"] = int(u.status.get("regen", 0)) - 1

		for k in ["blind", "weaken", "vulnerable"]:
			if int(u.status.get(k, 0)) > 0:
				u.status[k] = int(u.status[k]) - 1

	EventBus.status_tick.emit(PackedStringArray(resolved.keys()))
