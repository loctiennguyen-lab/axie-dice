class_name RelicHooks
extends RefCounted
## Relic hook API contract (architecture plan §6). This vertical slice ships ZERO real
## relics (RelicRegistry.all_defs_sorted() is empty until the data.js -> .tres converter,
## checklist step 8) — every function here is intentionally a no-op that returns the
## "no relic present" default. The call SITES in DamagePipeline/StatusEngine/CombatEngine
## must still exist at the exact spots the rule spec's 13-step damage pipeline names them,
## so wiring in the first real relic later is a data change, not an architecture change.
##
## Two distinct things live in this file on purpose:
##  1. call_hook() — the FUNCTION hook table (modDmg/onHit/onDmgTaken/onThorns/onKill/
##     onShield/onTurnStart/onRollEnd/growthAllGuard), keyed by RelicDef.hook_key. Never
##     bind a Callable onto a RelicDef Resource itself (plan §6 — ResourceLoader caches
##     Resources per-path, so a Callable stored there is shared mutable global state and
##     breaks under script hot-reload). Real relics will register into TABLE.
##  2. sum()/has()/max_val()/mul() — DATA aggregate helpers mirroring engine.js's
##     rsum/rhas/rmax/rmul_(s,k): "sum this numeric field across every owned relic".
##     These read RelicDef fields directly (once RelicDef exists), not the hook table.

## hook_key -> { event_name -> Callable }. First 12 real entries ported (checklist step 8,
## content-expansion pass) — see design/gdd/godot-port-rule-spec.md §5 for the JS hook
## signatures each of these mirrors (src/data.js RELICS[], src/engine.js rcall dispatch).
##
## Scope note: every relic below was chosen because its FULL effect is reachable through a
## hook/call-site that already exists in damage_pipeline.gd/combat_engine.gd/status_engine.gd
## (mod_dmg/on_hit/on_dmg_taken/on_thorns/on_kill/on_shield/on_turn_start/on_roll_end, or the
## RelicHooks.sum/has/max_val/mul aggregate fields on RelicDef). None of them use JS `modFace`/
## `modFace2` (build-time die mutation) — that hook has NO call site in this vertical slice
## (_build_unit_from_roster in combat_engine.gd never invokes it) and wiring one is out of
## scope for this pass (would require editing combat_engine.gd, which this pass must not
## touch — see the content-expansion task notes). A number of otherwise-simple JS relics
## (r_heart, r_ear, r_deathmark, r_soulforge, r_worldpiercer, ...) were deliberately left
## unported for exactly this reason rather than shipped with a silently-missing modFace half.
static var TABLE: Dictionary = {
	"r_scentofblood": {
		# JS: modDmg:ctx=> (ctx.tgt.side==='e'&&ctx.tgt.hp<ctx.tgt.maxHp*0.5? ctx.v+4 : ctx.v)
		"mod_dmg": func(ctx: Dictionary):
			var tgt: Unit = ctx["tgt"]
			var v: float = float(ctx["value"])
			return v + 4.0 if (tgt.side == "e" and DamagePipeline.is_wounded(ctx["combat"], tgt)) else v,
	},
	"r_lastwall": {
		# JS onTurnStart: most-endangered living non-token ally (lowest hp+shield) gets
		# Undying if it doesn't already have it.
		"on_turn_start": func(ctx: Dictionary):
			var combat = ctx["combat"]
			var p: Array = []
			for u in combat.party:
				if not u.is_token and u.hp > 0:
					p.append(u)
			if p.is_empty():
				return
			var w: Unit = p[0]
			for u in p:
				if u.hp + u.shield < w.hp + w.shield:
					w = u
			if int(w.status.get("undying", 0)) == 0:
				w.status["undying"] = 1
				EventBus.float_text.emit(w.uid, "UNDYING", "buf", 0)
			return,
	},
	"r_ember": {
		# JS onHit: any hit dealing >=4 also applies Burn 2. StatusEngine.add_status already
		# emits the float text for the new burn stack, matching JS addStatus().
		"on_hit": func(ctx: Dictionary):
			if String(ctx.get("type", "")) == "dmg" and int(ctx.get("dealt", 0)) >= 4:
				StatusEngine.add_status(ctx["combat"], ctx["tgt"], ["burn:2"], ctx.get("src", null))
			return,
	},
	"r_bloodhymn": {
		# JS onHit: crits grant 2 Mana. Silent in JS (bare s.mana+=2) — add a "+2 MP" float
		# text on the source (same styling src/data.js uses elsewhere for mana gains) so the
		# effect isn't invisible (rule spec §10).
		"on_hit": func(ctx: Dictionary):
			if bool(ctx.get("crit", false)) and int(ctx.get("dealt", 0)) > 0:
				var combat = ctx["combat"]
				combat.mana += 2
				var src: Unit = ctx.get("src", null)
				if src != null:
					EventBus.float_text.emit(src.uid, "+2 MP", "man", 0)
			return,
	},
	"r_bastionplate": {
		# JS onShield: ctx.splash(0.5) — deal 50% of the shield value to a random enemy.
		# Uses the owning CombatEngine's own seeded Rng (combat._rng) so this stays
		# deterministic/replay-safe, matching every other random pick in the engine.
		"on_shield": func(ctx: Dictionary):
			var combat = ctx["combat"]
			var es: Array = combat.alive_enemies()
			if es.is_empty():
				return
			var idx: int = combat._rng.next_int(es.size())
			DamagePipeline.resolve({
				"combat": combat, "src": null, "tgt": es[idx],
				"value": int(ceil(float(ctx["v"]) * 0.5)), "pierce": true, "attack": false,
			})
			return,
	},
	# PSEUDO-RELIC, not a relic the player can be offered. The CURSE PACT reward's upside is
	# "all damage faces deal 4 more"; src/engine.js implements that by pushing a synthetic
	# relic id onto s.relics (engine.js:1185) whose whole body is a modFace
	# (engine.js:1188-1189). Ported the same way rather than as a special case in the reward
	# code, so it flows through the normal INV-5 ordering like any other die mutation.
	# Phase "add" (a flat +4) puts it after keyword-adders and before multipliers.
	"__curse_dmg": {
		"mod_face": func(ctx: Dictionary):
			var unit = ctx["unit"]
			for f in unit.die:
				if String((f as Dictionary).get("type", "")) == "dmg":
					f["value"] = int(f.get("value", 0)) + 4
			return,
	},
	"r_chainreact": {
		# JS onKill's `explode` callback (engine.js:607):
		#   explode: v => aliveE(s).forEach(x => { if (x !== e) dealDamage(s, null, x, v, {}) })
		# i.e. REMAINING ENEMIES only, excluding the unit that just died, and with an EMPTY
		# options object — so no pierce.
		#
		# This was previously implemented as "every unit on the board (both sides), pierce",
		# with a comment asserting that was the JS behaviour. It was not: the relic was
		# detonating on the player's own party and ignoring their shields. Fixed to match JS.
		"on_kill": func(ctx: Dictionary):
			var combat = ctx["combat"]
			var dead = ctx.get("tgt", null)
			for u in combat.alive_enemies():
				if u == dead:
					continue
				DamagePipeline.resolve({"combat": combat, "src": null, "tgt": u, "value": 5, "attack": false})
			return,
	},
	"r_cullingorder": {
		# JS onKill: most-wounded living non-token Axie (lowest hp/maxHp ratio) heals 4 and
		# gains 4 Shield.
		"on_kill": func(ctx: Dictionary):
			var combat = ctx["combat"]
			var p: Array = []
			for u in combat.party:
				if not u.is_token and u.hp > 0:
					p.append(u)
			if p.is_empty():
				return
			var w: Unit = p[0]
			for u in p:
				if float(u.hp) / u.max_hp < float(w.hp) / w.max_hp:
					w = u
			DamagePipeline.apply_heal(combat, w, 4)
			DamagePipeline.apply_shield(combat, w, 4)
			return,
	},
	"r_manaspring": {
		# JS onTurnStart: +2 Mana every turn, with a "+2 MP" float text on the first living
		# non-token party member.
		"on_turn_start": func(ctx: Dictionary):
			var combat = ctx["combat"]
			var p: Array = []
			for u in combat.party:
				if not u.is_token and u.hp > 0:
					p.append(u)
			if p.is_empty():
				return
			combat.mana += 2
			EventBus.float_text.emit(p[0].uid, "+2 MP", "man", 0)
			return,
	},
	"r_pierceall": {
		# JS: if(f.p==='horn'&&!f.k.includes('pierce'))f.k.push('pierce')
		"mod_face": func(ctx: Dictionary):
			for f in ctx["unit"].die:
				if String(f.get("part", "")) == "horn" and not (f["keywords"] as Array).has("pierce"):
					(f["keywords"] as Array).append("pierce")
			return,
	},
	"r_cleaveall": {
		# JS: if(f.t==='dmg'&&(f.k.includes('cleave')||f.k.includes('aoe')))f.v+=2
		"mod_face": func(ctx: Dictionary):
			for f in ctx["unit"].die:
				var kw: Array = f["keywords"]
				if String(f.get("type", "")) == "dmg" and (kw.has("cleave") or kw.has("aoe")):
					f["value"] = int(f.get("value", 0)) + 2
			return,
	},
	"r_bloodmouth": {
		# JS also bumps maxHp by 2 in the same body — the die walk and the HP are one relic.
		"mod_face": func(ctx: Dictionary):
			var unit = ctx["unit"]
			for f in unit.die:
				if String(f.get("part", "")) == "mouth" and not (f["keywords"] as Array).has("lifesteal"):
					(f["keywords"] as Array).append("lifesteal")
			unit.max_hp += 2
			return,
	},
	"r_gorehook": {
		# JS: dmg faces on horn OR tail gain exec
		"mod_face": func(ctx: Dictionary):
			for f in ctx["unit"].die:
				var part := String(f.get("part", ""))
				if String(f.get("type", "")) == "dmg" and (part == "horn" or part == "tail") \
						and not (f["keywords"] as Array).has("exec"):
					(f["keywords"] as Array).append("exec")
			return,
	},
	"r_heart": {
		# v2 rework (§1.2): +8 Max HP for the whole party (runs in the INV-5 pass with the other
		# max-HP changes); at turn start an Axie below 30% HP gains 6 Shield.
		"mod_face": func(ctx: Dictionary):
			ctx["unit"].max_hp += 8
			return,
		"on_turn_start": func(ctx: Dictionary):
			var combat = ctx["combat"]
			for u in combat.party:
				if u.hp > 0 and not u.is_token and float(u.hp) < float(u.max_hp) * 0.3:
					DamagePipeline.apply_shield(combat, u, 6)
			return,
	},
	"r_talonedge": {
		# JS returns early for non-dmg faces, then applies BOTH bonuses — a horn face that
		# also pierces gets +3, not +2 or +1.
		"mod_face": func(ctx: Dictionary):
			for f in ctx["unit"].die:
				if String(f.get("type", "")) != "dmg":
					continue
				if (f["keywords"] as Array).has("pierce"):
					f["value"] = int(f.get("value", 0)) + 2
				if String(f.get("part", "")) == "horn":
					f["value"] = int(f.get("value", 0)) + 1
			return,
	},
	"r_marrowdrill": {
		"mod_face": func(ctx: Dictionary):
			for f in ctx["unit"].die:
				if String(f.get("type", "")) == "dmg" and (f["keywords"] as Array).has("pierce") \
						and not _has_kw_prefix(f, "weaken"):
					(f["keywords"] as Array).append("weaken:2")
			return,
	},
	"r_bloomscale": {
		# The "Growth faces grow by 4" half is the `growthPlus` data field.
		"mod_face": func(ctx: Dictionary):
			for f in ctx["unit"].die:
				var part := String(f.get("part", ""))
				if (part == "back" or part == "eyes") and not (f["keywords"] as Array).has("growth"):
					(f["keywords"] as Array).append("growth")
			return,
	},
	"r_rotmouth": {
		"mod_face": func(ctx: Dictionary):
			for f in ctx["unit"].die:
				if String(f.get("part", "")) == "mouth" and String(f.get("type", "")) == "dmg" \
						and not _has_kw_prefix(f, "poison"):
					(f["keywords"] as Array).append("poison:2")
			return,
	},
	"r_squallmark": {
		# JS says heal OR debuff — "weakens" in the description means the debuff face type.
		"mod_face": func(ctx: Dictionary):
			for f in ctx["unit"].die:
				var t := String(f.get("type", ""))
				if String(f.get("part", "")) == "eyes" and (t == "heal" or t == "debuff") \
						and not (f["keywords"] as Array).has("aoe"):
					(f["keywords"] as Array).append("aoe")
			return,
	},
	"r_fang": {
		"mod_face": func(ctx: Dictionary):
			for f in ctx["unit"].die:
				if String(f.get("type", "")) == "poison":
					f["value"] = int(f.get("value", 0)) + 1
			return,
	},
	"r_pyroclasm": {
		# The burn-spreading half is the `burnSpread` data field; only the +1 horn damage is here.
		"mod_face": func(ctx: Dictionary):
			for f in ctx["unit"].die:
				if String(f.get("part", "")) == "horn" and String(f.get("type", "")) == "dmg":
					f["value"] = int(f.get("value", 0)) + 1
			return,
	},
	"r_wildfire": {
		# The "burn decays by 1 instead of half" half is the `burnSlow` data field.
		"mod_face": func(ctx: Dictionary):
			for f in ctx["unit"].die:
				if String(f.get("part", "")) == "horn" and String(f.get("type", "")) == "dmg" \
						and not _has_kw_prefix(f, "burn"):
					(f["keywords"] as Array).append("burn:6")
			return,
	},
	"r_plaguelord": {
		# The "poison never decays" half is the `plague` data field.
		"mod_face": func(ctx: Dictionary):
			for f in ctx["unit"].die:
				if String(f.get("type", "")) == "poison":
					f["value"] = int(f.get("value", 0)) + 1
			return,
	},
	"r_soulforge": {
		# v2 rework (§1.2): the no-shield-cap half is the `noShieldCap` field. No `dr`, no +2
		# Shield any more; instead every 10 Shield on the attacker is +1 on its damage faces (max +6).
		"mod_dmg": func(ctx: Dictionary):
			var src: Unit = ctx.get("src", null)
			var v: float = float(ctx["value"])
			if src == null:
				return v
			return v + float(mini(6, src.shield / 10)),
	},
	"r_stormcall": {
		# "single-target" means a face carrying neither aoe nor cleave already.
		"mod_face": func(ctx: Dictionary):
			for f in ctx["unit"].die:
				var kw: Array = f["keywords"]
				if String(f.get("type", "")) == "dmg" and not kw.has("aoe") and not kw.has("cleave"):
					kw.append("cleave")
			return,
	},
	"r_ancientgene": {
		# v2 rework (§1.2): +30% on DAMAGE faces only (was every face), plus +1 Growth on every
		# face that already has the growth keyword. mf_phase "mul" keeps it after every flat adder
		# (INV-5). ceil, positive faces only, so blanks stay blank.
		"mod_face": func(ctx: Dictionary):
			var unit = ctx["unit"]
			for i in unit.die.size():
				var f: Dictionary = unit.die[i]
				if (f["keywords"] as Array).has("growth"):
					unit.add_growth(i, 1)
			return,
	},
	"r_broodpouch": {
		# The start-of-fight Egg is the `startSummon` field. Merged swarmnest rule: on turn 3,
		# fewer than 3 Eggs -> one more. on_turn_start runs before roll_all, so it rolls normally.
		"on_turn_start": func(ctx: Dictionary):
			var combat = ctx["combat"]
			if combat.turn != 3:
				return
			var eggs := 0
			for u in combat.party:
				if u.is_token and u.hp > 0:
					eggs += 1
			if eggs < 3:
				combat.party.append(combat._mk_ally())
			return,
	},
	"r_worldpiercer": {
		# The "pierce ignores thorns" half is handled by the piercePlus/thorns path, not here.
		"mod_face": func(ctx: Dictionary):
			for f in ctx["unit"].die:
				if String(f.get("type", "")) == "dmg" and not (f["keywords"] as Array).has("pierce"):
					(f["keywords"] as Array).append("pierce")
			return,
	},

	# =======================================================================
	# EVENT HOOKS — 2026-09-18 relic authoring pass.
	#
	# Same rule as the modFace block: each body is a transcription of src/data.js, and where
	# the description and the body disagree the body wins.
	#
	# Two shapes recur and are worth naming once:
	#   * ONCE-PER-UNIT buffs ride in `custom_state` (JS hangs `u.eggDmg`/`u.eggBuff`/
	#     `u.spiraled` straight off the unit). They must be flags, not "apply every turn":
	#     on_turn_start fires every turn, so a token would gain +1 damage per turn forever.
	#   * `Math.max(existing, n)` on a status is a FLOOR, not an add. Re-running it is a no-op,
	#     which is exactly why these relics can fire on_turn_start without stacking to infinity.
	# =======================================================================
	"r_tidalbrand": {
		"mod_face": func(ctx: Dictionary):
			for f in ctx["unit"].die:
				if String(f.get("part", "")) == "ears" and not (f["keywords"] as Array).has("rerollup"):
					(f["keywords"] as Array).append("rerollup")
			return,
		# JS bumps BOTH rerolls and maxRerolls on turn 1. It does not compound across combats:
		# startCombat() recomputes max_rerolls from the formula before on_turn_start runs, so
		# each fight gets exactly +1 — verified against engine.js:420 vs :426.
		"on_turn_start": func(ctx: Dictionary):
			var combat = ctx["combat"]
			if combat.turn == 1:
				combat.rerolls += 1
				combat.max_rerolls += 1
			return,
	},
	"r_deathmark": {
		"mod_face": func(ctx: Dictionary):
			ctx["unit"].max_hp += 2
			return,
		# JS walks s.party, NOT alive party — a downed Axie still gets the bonus, which matters
		# because it may be revived or simply survive to the next combat's rebuild.
		"on_kill": func(ctx: Dictionary):
			for u in ctx["combat"].party:
				for f in u.die:
					if String(f.get("type", "")) == "dmg":
						f["value"] = int(f.get("value", 0)) + 1
			return,
	},
	"r_infinitedie": {
		# The +2 max rerolls and safe-reroll halves are the `rerollUp`/`safeReroll` fields.
		"on_turn_start": func(ctx: Dictionary):
			var combat = ctx["combat"]
			if combat.turn == 1:
				combat.mana += 1
			return,
	},
	"r_manaflood": {
		# The "unspent mana damages every enemy" half is the `manaOverflow` data field.
		"on_turn_start": func(ctx: Dictionary):
			var combat = ctx["combat"]
			if combat.turn == 1:
				combat.mana += 3
			return,
	},
	"r_heartwood": {
		# growthAll (2) is the data field; this guard is what makes it start on turn 2.
		# CombatEngine consults it per relic, so returning false here suppresses only this
		# relic's growth, never another's.
		"growth_all_guard": func(ctx: Dictionary):
			return ctx["combat"].turn > 1,
	},
	"r_broodmother": {
		# JS hatches through the same mkAlly/rollUnit path a summon face uses, and sets
		# used=true so the new egg does not also act on the turn it arrives.
		"on_kill": func(ctx: Dictionary):
			var combat = ctx["combat"]
			var cap := int(RelicHooks.max_val(combat, "tokenCap", 4.0))
			var alive_tokens := 0
			for u in combat.party:
				if u.is_token and u.hp > 0:
					alive_tokens += 1
			if alive_tokens >= cap:
				return
			var egg = combat._mk_ally()
			combat._roll_unit(egg)
			egg.mark_used()
			combat.party.append(egg)
			EventBus.unit_spawned.emit(egg.uid)
			return,
		# `egg_dmg` is the once-per-egg guard. Without it on_turn_start would add +1 every
		# turn and an egg that survived ten turns would hit for ten more.
		"on_turn_start": func(ctx: Dictionary):
			for u in ctx["combat"].party:
				if u.is_token and u.hp > 0 and not bool(u.custom_state.get("egg_dmg", false)):
					u.custom_state["egg_dmg"] = true
					for f in u.die:
						if String(f.get("type", "")) == "dmg":
							f["value"] = int(f.get("value", 0)) + 1
			return,
	},
	"r_apexbrood": {
		# Same once-per-egg guard as r_broodmother, and JS raises current hp alongside max so
		# the egg arrives at full health rather than instantly wounded.
		"on_turn_start": func(ctx: Dictionary):
			for u in ctx["combat"].party:
				if u.is_token and u.hp > 0 and not bool(u.custom_state.get("egg_buff", false)):
					u.custom_state["egg_buff"] = true
					u.max_hp += 8
					u.hp += 8
					for f in u.die:
						if String(f.get("type", "")) == "dmg":
							f["value"] = int(f.get("value", 0)) + 2
					EventBus.hp_changed.emit(u.uid, u.hp, u.max_hp, u.shield)
			return,
	},
	"r_bloodthorn": {
		"mod_face": func(ctx: Dictionary):
			for f in ctx["unit"].die:
				if String(f.get("type", "")) == "shield":
					f["value"] = int(f.get("value", 0)) + 1
			return,
		# JS guards on ctx.attack: status damage (poison/burn ticks) must not heal the victim.
		"on_dmg_taken": func(ctx: Dictionary):
			if not bool(ctx.get("attack", false)):
				return
			var tgt: Unit = ctx["tgt"]
			var th := int(tgt.status.get("thorns", 0))
			if th > 0 and tgt.hp > 0:
				DamagePipeline.apply_heal(ctx["combat"], tgt, int(ceil(float(th) / 3.0)))
			return,
	},
	"r_growthcore": {
		# Two phases: the keyword in "kw", the numbers in "add". Split this way in JS so the
		# +1 lands after every other keyword-adder and before r_ancientgene's multiplier.
		"mod_face": func(ctx: Dictionary):
			for f in ctx["unit"].die:
				if String(f.get("type", "")) == "dmg" and not (f["keywords"] as Array).has("growth"):
					(f["keywords"] as Array).append("growth")
			return,
		"mod_face2": func(ctx: Dictionary):
			var unit = ctx["unit"]
			for f in unit.die:
				if String(f.get("type", "")) == "dmg":
					f["value"] = int(f.get("value", 0)) + 1
			unit.max_hp += 2
			return,
	},
	"r_thousandcuts": {
		"mod_face": func(ctx: Dictionary):
			for f in ctx["unit"].die:
				if String(f.get("type", "")) == "dmg" and (f["keywords"] as Array).has("pierce") \
						and not _has_kw_prefix(f, "multi"):
					(f["keywords"] as Array).append("multi:2")
			return,
		# The halving runs in the LATER phase so it applies to the value every flat adder has
		# already contributed to — "half plus 2, twice" of the final number, as JS does.
		"mod_face2": func(ctx: Dictionary):
			for f in ctx["unit"].die:
				if String(f.get("type", "")) == "dmg" and (f["keywords"] as Array).has("pierce"):
					f["value"] = int(ceil(float(f.get("value", 0)) / 2.0)) + 2
			return,
	},
	"r_windlash": {
		"mod_face": func(ctx: Dictionary):
			for f in ctx["unit"].die:
				var kw: Array = f["keywords"]
				if String(f.get("part", "")) == "mouth" and String(f.get("type", "")) == "dmg" \
						and not kw.has("cleave") and not kw.has("aoe"):
					kw.append("cleave")
			return,
		"mod_face2": func(ctx: Dictionary):
			for f in ctx["unit"].die:
				if String(f.get("part", "")) == "mouth" and String(f.get("type", "")) == "dmg":
					f["value"] = int(f.get("value", 0)) + 1
			return,
	},
	"r_apexferal": {
		"mod_face": func(ctx: Dictionary):
			for f in ctx["unit"].die:
				if String(f.get("type", "")) == "dmg" and not (f["keywords"] as Array).has("exec"):
					(f["keywords"] as Array).append("exec")
			return,
		# Finishes the target for exactly its remaining hp, pierce, attack=false — so it does
		# not re-enter onHit and recurse.
		"on_hit": func(ctx: Dictionary):
			var t: Unit = ctx["tgt"]
			# Bosses are immune to instant kills (design/l1-relic-answers.md §5, Liam 12/10).
			if t != null and t.side == "e" and not t.is_boss and t.hp > 0 and float(t.hp) <= float(t.max_hp) * 0.15:
				DamagePipeline.resolve({"combat": ctx["combat"], "src": null, "tgt": t,
					"value": t.hp, "pierce": true, "attack": false})
			return,
	},
	"r_deathspiral": {
		# `spiraled` makes this once per enemy per combat, not once per hit below half.
		"on_hit": func(ctx: Dictionary):
			var t: Unit = ctx["tgt"]
			if t == null or t.side != "e" or t.hp <= 0:
				return
			if DamagePipeline.is_wounded(ctx["combat"], t) and not bool(t.custom_state.get("spiraled", false)):
				t.custom_state["spiraled"] = true
				DamagePipeline.resolve({"combat": ctx["combat"], "src": null, "tgt": t,
					"value": 7, "pierce": true, "attack": false})
			return,
	},
	"r_pandemic": {
		"on_kill": func(ctx: Dictionary):
			var combat = ctx["combat"]
			var dead: Unit = ctx["tgt"]
			var pois := int(dead.status.get("poison", 0))
			if pois <= 0:
				return
			var half := int(ceil(float(pois) / 2.0))
			for x in combat.alive_enemies():
				if x != dead:
					StatusEngine.add_status(combat, x, ["poison:%d" % half])
			return,
	},
	"r_glassspine": {
		# A floor on the shielded unit, so repeated shielding never stacks thorns past 4.
		"on_shield": func(ctx: Dictionary):
			var tgt: Unit = ctx.get("tgt", null)
			if tgt != null and tgt.hp > 0:
				tgt.status["thorns"] = maxi(int(tgt.status.get("thorns", 0)), 4)
			return,
	},
	"r_retributor": {
		# Only when the thorned Axie actually has Shield up. The splash lands on the ATTACKER's
		# neighbours among living enemies — ctx.src is who took the thorns damage.
		"on_thorns": func(ctx: Dictionary):
			var combat = ctx["combat"]
			var tgt: Unit = ctx["tgt"]
			if tgt.shield <= 0:
				return
			var d := int(ceil(float(ctx["th"]) / 3.0))
			if d <= 0:
				return
			for x in combat._neighbors_of(combat.alive_enemies(), ctx["src"]):
				DamagePipeline.resolve({"combat": combat, "src": null, "tgt": x, "value": d,
					"pierce": true, "attack": false})
			return,
	},
	"r_scalecrown": {
		"on_turn_start": func(ctx: Dictionary):
			for u in ctx["combat"].party:
				if u.hp > 0:
					u.status["thorns"] = maxi(int(u.status.get("thorns", 0)), 2)
			return,
		# JS skips reptiles: they already have SCALES natively, and applying it twice would
		# double-poison. ctx.src is the attacker that just took the thorns damage.
		"on_thorns": func(ctx: Dictionary):
			var tgt: Unit = ctx["tgt"]
			var src: Unit = ctx.get("src", null)
			if String(tgt.cls) != "reptile" and src != null and src.hp > 0:
				StatusEngine.add_status(ctx["combat"], src, ["poison:1"])
			return,
	},
	"r_ironmaiden": {
		# IRONMAIDEN_CAP is 7 (src/data.js:30).
		"on_turn_start": func(ctx: Dictionary):
			var combat = ctx["combat"]
			var es: Array = combat.alive_enemies()
			if es.is_empty():
				return
			var th := 0
			for u in combat.alive_party():
				th = maxi(th, int(u.status.get("thorns", 0)))
			th = mini(7, th)
			if th <= 0:
				return
			var big: Unit = es[0]
			for e in es:
				if e.hp > big.hp:
					big = e
			DamagePipeline.resolve({"combat": combat, "src": null, "tgt": big, "value": th,
				"pierce": true, "attack": false})
			return,
	},
	"r_conduitcrown": {
		# The "each card twice per turn" half is the `actReuse` data field.
		"on_turn_start": func(ctx: Dictionary):
			var combat = ctx["combat"]
			var p: Array = []
			for u in combat.alive_party():
				if not u.is_token:
					p.append(u)
			if p.is_empty():
				return
			combat.mana += 2
			EventBus.float_text.emit(p[0].uid, "+2 MP", "man", 0)
			return,
	},
	"r_quickenroot": {
		# Growth on the face each Axie currently HAS ROLLED, only from turn 2, only when that
		# face is still unused and is not a blank.
		"on_roll_end": func(ctx: Dictionary):
			var combat = ctx["combat"]
			if combat.turn <= 1:
				return
			for u in combat.alive_party():
				var fi: int = u.roll_face_index()
				if fi < 0 or u.roll_used():
					continue
				if int((u.die[fi] as Dictionary).get("value", 0)) <= 0:
					continue
				u.growth[fi] = int(u.growth.get(fi, 0)) + 1
				EventBus.float_text.emit(u.uid, "GROW", "buf", 0)
			return,
	},
	"r_dawnlance": {
		# JS: ctx.tgt.side==='e' && ctx.tgt.hp > ctx.tgt.maxHp*0.5 ? ceil(v*1.9) : v
		"mod_dmg": func(ctx: Dictionary):
			var tgt: Unit = ctx["tgt"]
			var v: float = float(ctx["value"])
			if tgt.side == "e" and not DamagePipeline.is_wounded(ctx["combat"], tgt):
				return ceil(v * (1.0 + RelicHooks.axis_sum(ctx["combat"], "A:opener")))
			return v,
	},


	# =======================================================================
	# RELIC SET V2 (design/proposals/relic-set-v2.md) — bodies that need only hooks that exist
	# today. Relics that wait for the 8 new hooks stay data-only (needs_hook in the .tres).
	# =======================================================================
	"r_bookend": {
		# §1.5 positional: party slot 1 and slot 5 (index 0 and 4) — dmg faces +3. `slot` is set
		# by the engine (lane A); until then the roster index is the same number.
		"mod_face": func(ctx: Dictionary):
			var unit = ctx["unit"]
			var s: int = unit.slot if unit.slot >= 0 else unit.roster_index
			if s != 0 and s != 4:
				return
			for f in unit.die:
				if String(f.get("type", "")) == "dmg":
					f["value"] = int(f.get("value", 0)) + 3
			return,
	},
	"r_brittledice": {
		# Pact (dice group): benefit = every dmg face +4 (add phase); drawback = Shield/Heal
		# faces halved, rounded down (mul phase, so it also halves other relics' bonuses).
		"mod_face": func(ctx: Dictionary):
			for f in ctx["unit"].die:
				if String(f.get("type", "")) == "dmg":
					f["value"] = int(f.get("value", 0)) + 4
			return,
		"mod_face2": func(ctx: Dictionary):
			for f in ctx["unit"].die:
				var t := String(f.get("type", ""))
				if t == "shield" or t == "heal":
					f["value"] = int(floor(float(int(f.get("value", 0))) * 0.5))
			return,
	},
	"r_towershield": {
		# §1.5: a dmg face of an Axie that holds Shield: +1 per 4 Shield, at most +6.
		"mod_dmg": func(ctx: Dictionary):
			var src: Unit = ctx.get("src", null)
			var v: float = float(ctx["value"])
			if src == null:
				return v
			return v + float(mini(6, src.shield / 4)),
	},
	"r_patientfang": {
		# Pact (dice group): turn 1 every damage face deals 0; from turn 2, +2 per turn passed,
		# capped at +14. Only face damage reaches mod_dmg with a src (relic damage has src null).
		"mod_dmg": func(ctx: Dictionary):
			var v: float = float(ctx["value"])
			# Turn 1 is zeroed by DamagePipeline (`zeroFirstTurn`) AFTER every bonus, crit included.
			var turn: int = int(ctx["combat"].turn)
			if turn <= 1:
				return v
			return v + float(mini(14, 2 * (turn - 1))),
	},
	"r_festermark": {
		# Merge of rotbite + tinderbox + openwound: poisoned OR burning target takes +2 per hit,
		# both statuses +4. Flat, no multiplier.
		"mod_dmg": func(ctx: Dictionary):
			var tgt: Unit = ctx["tgt"]
			var v: float = float(ctx["value"])
			var n := 0
			if int(tgt.status.get("poison", 0)) > 0:
				n += 1
			if int(tgt.status.get("burn", 0)) > 0:
				n += 1
			return v + 2.0 * n,
	},
	"r_coupmark": {
		# Crit on a wounded target (is_wounded BEFORE the hit): if it is left at <= 25% Max HP,
		# it dies. Same shape as apexferal: pierce, attack=false, no re-entry into on_hit.
		"on_hit": func(ctx: Dictionary):
			var t: Unit = ctx["tgt"]
			var combat = ctx["combat"]
			if not bool(ctx.get("crit", false)) or t == null or t.side != "e" or t.hp <= 0 or t.is_boss:
				return   # bosses are immune to instant kills (l1-relic-answers §5)
			var hp_before: int = t.hp + int(ctx.get("dealt", 0))
			if not DamagePipeline.is_wounded_at(combat, t, hp_before):
				return
			if float(t.hp) <= float(t.max_hp) * 0.25:
				DamagePipeline.resolve({"combat": combat, "src": null, "tgt": t,
					"value": t.hp, "pierce": true, "attack": false})
			return,
	},
	"r_spikedbulwark": {
		# Shield + Thorns duo: an Axie that gains Shield holds +1 Thorns per 5 Shield (max +4)
		# until the end of the turn. The bonus is remembered per unit so it is removed exactly.
		"on_shield": func(ctx: Dictionary):
			var u: Unit = ctx["tgt"]
			var want: int = mini(4, u.shield / 5)
			var have: int = int(u.custom_state.get("spiked_bonus", 0))
			if want > have:
				u.status["thorns"] = StatusEngine.clamp_thorns(int(u.status.get("thorns", 0)) + (want - have))
				u.custom_state["spiked_bonus"] = want
			return,
		"on_turn_start": func(ctx: Dictionary):
			for u in ctx["combat"].party:
				var have: int = int(u.custom_state.get("spiked_bonus", 0))
				if have > 0:
					u.status["thorns"] = maxi(0, int(u.status.get("thorns", 0)) - have)
					u.custom_state["spiked_bonus"] = 0
			return,
	},
	"r_thornling": {
		# Summon + Thorns duo: Eggs hold Thorns 3 (floor, re-applied each turn start); whenever an
		# Egg reflects, the Axie(s) next to it gain 2 Shield.
		"on_turn_start": func(ctx: Dictionary):
			for u in ctx["combat"].party:
				if u.is_token and u.hp > 0:
					u.status["thorns"] = maxi(int(u.status.get("thorns", 0)), 3)
			return,
		"on_thorns": func(ctx: Dictionary):
			var egg: Unit = ctx["tgt"]
			var combat = ctx["combat"]
			if egg == null or not egg.is_token:
				return
			var line: Array = []
			for u in combat.party:
				if u.hp > 0:
					line.append(u)
			for n in combat._neighbors_of(line, egg):
				if not n.is_token:
					DamagePipeline.apply_shield(combat, n, 2)
			return,
	},


	# =======================================================================
	# RELIC SET V2, second batch: relics on the 8 new hooks (H1-H8, lane A PR2).
	# Conventions (relic-set-v2 §5, interfaces §2):
	#  * per-roll bonuses ("+4 on the lowest face", linkstone...) are attached to the rolled die face
	#    by RelicHooks.rb_add() in on_roll_settled and removed/re-attached at every settle ("clear,
	#    then attach again"), never counted;
	#  * counters live in combat.relic_combat (snapshotted: undo and resume restore them);
	#  * run-level results go into combat.relic_run_out[<relic id>];
	#  * the only randomness is combat._rng (the epoch stream).
	# =======================================================================
	"r_claw": {
		# v2 rework: the lowest-value damage face on the team gets +4, recomputed after every
		# Reroll/Tweak. Ties go to the Axie in the lower slot.
		"on_roll_settled": func(ctx: Dictionary):
			var c = ctx["combat"]
			for u in c.party:
				RelicHooks.rb_clear(u, "claw")
			var best: Unit = null
			var best_v := 0
			for u in RelicHooks.party_line(c):
				var fi: int = u.roll_face_index()
				if fi < 0 or u.roll_used():
					continue
				var f: Dictionary = u.die[fi]
				var v := int(f.get("value", 0))
				if String(f.get("type", "")) != "dmg" or v <= 0:
					continue
				if best == null or v < best_v:
					best = u
					best_v = v
			if best != null:
				RelicHooks.rb_add(best, "claw", 4)
			return,
	},
	"r_carapace": {
		# v2 rework: the first Shield face used each turn gives +5 Shield (to the Axie it shielded).
		"on_face_used": func(ctx: Dictionary):
			var c = ctx["combat"]
			if String(ctx["side"]) != "p" or String((ctx["face"] as Dictionary).get("type", "")) != "shield":
				return
			if not RelicHooks.once_per_turn(c, "carapace_t"):
				return
			var t: Unit = c.by_uid(int(ctx["target_uid"]))
			if t == null or t.side != "p" or t.hp <= 0:
				t = ctx["unit"]
			DamagePipeline.apply_shield(c, t, 5)
			return,
	},
	"r_barbedhide": {
		# v2 rework: each Shield face used gives that Axie +1 Thorns through the enemy phase (max +3).
		"on_face_used": func(ctx: Dictionary):
			if String(ctx["side"]) != "p" or String((ctx["face"] as Dictionary).get("type", "")) != "shield":
				return
			var u: Unit = ctx["unit"]
			var n := int(u.custom_state.get("barbed", 0))
			if n < 3:
				u.status["thorns"] = StatusEngine.clamp_thorns(int(u.status.get("thorns", 0)) + 1)
				u.custom_state["barbed"] = n + 1
			return,
		"on_turn_start": func(ctx: Dictionary):
			for u in ctx["combat"].party:
				var n := int(u.custom_state.get("barbed", 0))
				if n > 0:
					u.status["thorns"] = maxi(0, int(u.status.get("thorns", 0)) - n)
					u.custom_state["barbed"] = 0
			return,
	},
	"r_ear": {
		# +1 on Mana faces (die build) and, v2: the first active played each turn refunds 1 Mana.
		"mod_face": func(ctx: Dictionary):
			for f in ctx["unit"].die:
				if String(f.get("type", "")) == "mana":
					f["value"] = int(f.get("value", 0)) + 1
			return,
		"on_active_played": func(ctx: Dictionary):
			var c = ctx["combat"]
			if RelicHooks.once_per_turn(c, "ear_t"):
				c.mana += 1
			return,
	},
	"r_eggshell": {
		# v2 rework: at end of turn each living Egg gives 3 Shield to the Axies next to it.
		"on_turn_end": func(ctx: Dictionary):
			var c = ctx["combat"]
			var line: Array = []
			for u in c.party:
				if u.hp > 0:
					line.append(u)
			for egg in line:
				if not egg.is_token:
					continue
				for n in c._neighbors_of(line, egg):
					if not n.is_token:
						DamagePipeline.apply_shield(c, n, 3)
			return,
	},
	"r_regrow": {
		# v2 rework: each Shield/Heal face used gives that Axie +1 Growth on the face it used, for
		# this combat (max +4 per Axie).
		"on_face_used": func(ctx: Dictionary):
			var t := String((ctx["face"] as Dictionary).get("type", ""))
			if String(ctx["side"]) != "p" or (t != "shield" and t != "heal"):
				return
			var u: Unit = ctx["unit"]
			var n := int(u.custom_state.get("regrow_n", 0))
			if n < 4:
				u.add_growth(int(ctx["fi"]), 1)
				u.custom_state["regrow_n"] = n + 1
			return,
	},
	"r_hollowbone": {
		# Pierce ignoring Thorns is the `pierceThornProof` field. The first Pierce face each turn
		# also hits the lowest-HP enemy for 50% (relic damage: src null, attack false, no on_hit).
		"on_face_used": func(ctx: Dictionary):
			var c = ctx["combat"]
			var f: Dictionary = ctx["face"]
			if String(ctx["side"]) != "p" or int(ctx.get("depth", 0)) > 0:
				return
			if String(f.get("type", "")) != "dmg" or not (f["keywords"] as Array).has("pierce"):
				return
			if not RelicHooks.once_per_turn(c, "hollowbone_t"):
				return
			var low: Unit = null
			for e in c.alive_enemies():
				if low == null or e.hp < low.hp:
					low = e
			if low == null:
				return
			var v := int(ceil(float(c._face_value(ctx["unit"], int(ctx["fi"]))) * 0.5))
			DamagePipeline.resolve({"combat": c, "src": null, "tgt": low, "value": v, "pierce": true, "attack": false})
			return,
	},
	"r_keeneye": {
		# Pity crit, recomputed at every settle (v2): clear last settle's pity crit (unless that Axie
		# just rerolled, whose crit is fresh), then give the first unused damage face a crit when
		# nobody has one. The +4 crit damage half is the `critFlatPity` data field.
		"on_roll_settled": func(ctx: Dictionary):
			var combat = ctx["combat"]
			var rerolled: Array = ctx.get("rerolled_uids", [])
			var p: Array = combat.alive_party()
			for u in p:
				if bool(u.custom_state.get("pity_crit", false)) and not rerolled.has(u.uid):
					u.set_crit_now(false)
				u.custom_state["pity_crit"] = false
			for u in p:
				if u.roll_crit_now():
					return
			for u in p:
				var fi: int = u.roll_face_index()
				if fi < 0 or u.roll_used():
					continue
				if String((u.die[fi] as Dictionary).get("type", "")) != "dmg":
					continue
				u.set_crit_now(true)
				u.custom_state["pity_crit"] = true
				EventBus.float_text.emit(u.uid, "CRIT", "buf", 0)
				return
			return,
	},
	"r_aegiscapacitor": {
		# Shield + Mana duo: every 2 Mana spent this combat, the Axie with the least Shield gains 4.
		"on_active_played": func(ctx: Dictionary):
			var c = ctx["combat"]
			var due: int = RelicHooks.mana_steps_due(c, "r_aegiscapacitor", 2)
			for i in due:
				var w: Unit = null
				for u in RelicHooks.party_line(c):
					if w == null or u.shield < w.shield:
						w = u
				if w != null:
					DamagePipeline.apply_shield(c, w, 4)
			return,
	},
	"r_wellspringroots": {
		# Growth + Mana duo: every 2 Mana spent, every face of the team +1 Growth this combat (max +4 times).
		"on_active_played": func(ctx: Dictionary):
			var c = ctx["combat"]
			var due: int = RelicHooks.mana_steps_due(c, "r_wellspringroots", 2)
			for i in due:
				var n := int(c.relic_combat.get("wsr_n", 0))
				if n >= 4:
					break
				for u in c.alive_party():
					for fi in u.die.size():
						u.add_growth(fi, 1)
				c.relic_combat["wsr_n"] = n + 1
			return,
	},
	"r_tideglass": {
		# Every 3 Mana spent: all team damage faces +1 for this combat (max +6 times).
		"on_active_played": func(ctx: Dictionary):
			var c = ctx["combat"]
			var due: int = RelicHooks.mana_steps_due(c, "r_tideglass", 3)
			for i in due:
				var n := int(c.relic_combat.get("tideglass_n", 0))
				if n >= 6:
					break
				RelicHooks.add_to_dmg_faces(c, 1)
				c.relic_combat["tideglass_n"] = n + 1
			return,
	},
	"r_heirloom": {
		# Each Elite/Boss won: all damage faces +1 for the rest of the RUN (max +5). Stored in the
		# run-level relic state; applied at the start of every later fight.
		"on_combat_start": func(ctx: Dictionary):
			var c = ctx["combat"]
			var n := int((c.relic_run_in.get("r_heirloom", {}) as Dictionary).get("n", 0))
			if n > 0:
				RelicHooks.add_to_dmg_faces(c, n)
			return,
		"on_combat_end": func(ctx: Dictionary):
			var c = ctx["combat"]
			if String(ctx["result"]) != "won" or not ["elite", "boss"].has(String(ctx.get("node_kind", ""))):
				return
			var n := int((c.relic_run_out.get("r_heirloom", {}) as Dictionary).get("n", 0))
			c.relic_run_out["r_heirloom"] = {"n": mini(5, n + 1)}
			return,
	},
	"r_crescendofang": {
		# Each damage face used this turn: the next damage face +1 (stacks). Resets every turn.
		"on_face_used": func(ctx: Dictionary):
			if String(ctx["side"]) == "p" and String((ctx["face"] as Dictionary).get("type", "")) == "dmg":
				var rc: Dictionary = ctx["combat"].relic_combat
				rc["cresc"] = int(rc.get("cresc", 0)) + 1
			return,
		"mod_dmg": func(ctx: Dictionary):
			var v: float = float(ctx["value"])
			if ctx.get("src", null) == null:
				return v
			return v + float(int(ctx["combat"].relic_combat.get("cresc", 0))),
		"on_turn_start": func(ctx: Dictionary):
			ctx["combat"].relic_combat["cresc"] = 0
			return,
		"on_turn_end": func(ctx: Dictionary):
			ctx["combat"].relic_combat["cresc"] = 0
			return,
	},
	"r_relaybaton": {
		# Slot-order dependent: the chain is built left to right, so the result depends on who is used first.
		# After an Axie uses a face, the Axie in the next slot to the right gets +2 on its damage faces
		# this turn, PLUS whatever bonus the user itself had (the chain adds up left to right, Liam 12/10).
		"on_face_used": func(ctx: Dictionary):
			var u: Unit = ctx["unit"]
			if String(ctx["side"]) != "p" or u.is_token:
				return
			var s := RelicHooks.slot_of(u)
			if s < 0:
				return
			var relay := RelicHooks.relay_of(ctx["combat"])
			var nxt := str(s + 1)
			relay[nxt] = maxi(int(relay.get(nxt, 0)), int(relay.get(str(s), 0)) + 2)
			return,
		"mod_dmg": func(ctx: Dictionary):
			var v: float = float(ctx["value"])
			var src: Unit = ctx.get("src", null)
			if src == null or src.is_token:
				return v
			return v + float(int(RelicHooks.relay_of(ctx["combat"]).get(str(RelicHooks.slot_of(src)), 0))),
		"on_turn_start": func(ctx: Dictionary):
			ctx["combat"].relic_combat["relay"] = {}
			return,
		"on_turn_end": func(ctx: Dictionary):
			ctx["combat"].relic_combat["relay"] = {}
			return,
	},
	"r_keystone": {
		# The Shield/Heal/Mana face of the Axie in slot 3 also gives floor(50%) to each living neighbour
		# (slots 2 and 4). Mana is shared: +floor(50%) once per living neighbour.
		"on_face_used": func(ctx: Dictionary):
			var u: Unit = ctx["unit"]
			var c = ctx["combat"]
			if String(ctx["side"]) != "p" or RelicHooks.slot_of(u) != 2:
				return
			var t := String((ctx["face"] as Dictionary).get("type", ""))
			if t != "shield" and t != "heal" and t != "mana":
				return
			var half: int = int(floor(float(c._face_value(u, int(ctx["fi"]))) / 2.0))
			if half <= 0:
				return
			for n in RelicHooks.slot_neighbors(c, u):
				if t == "shield":
					DamagePipeline.apply_shield(c, n, half)
				elif t == "heal":
					DamagePipeline.apply_heal(c, n, half)
				else:
					c.mana += half
			return,
	},
	"r_linkstone": {
		# Each Axie next to a living Axie showing the same face type (dmg/shield/heal/poison/mana) gets +2
		# on its face. Static, recomputed at every settle.
		"on_roll_settled": func(ctx: Dictionary):
			var c = ctx["combat"]
			for u in c.party:
				RelicHooks.rb_clear(u, "link")
			var by_slot := RelicHooks.link_faces(c)
			var bonus: Dictionary = {}
			for s in by_slot:
				var me: Dictionary = by_slot[s]
				for d in [-1, 1]:
					if by_slot.has(int(s) + d) and String((by_slot[int(s) + d] as Dictionary)["type"]) == String(me["type"]):
						bonus[s] = 2
			for s in bonus:
				RelicHooks.rb_add((by_slot[s] as Dictionary)["unit"], "link", int(bonus[s]))
			return,
	},
	"r_symmetrycharm": {
		# Slots 1-5 and 2-4 showing the same face type: both +3. Both pairs matching: slot 3 gets +1.
		"on_roll_settled": func(ctx: Dictionary):
			var c = ctx["combat"]
			for u in c.party:
				RelicHooks.rb_clear(u, "sym")
			var by_slot := RelicHooks.link_faces(c)
			var pairs_ok := 0
			for pr in [[0, 4], [1, 3]]:
				if by_slot.has(pr[0]) and by_slot.has(pr[1]) \
						and String((by_slot[pr[0]] as Dictionary)["type"]) == String((by_slot[pr[1]] as Dictionary)["type"]):
					pairs_ok += 1
					RelicHooks.rb_add((by_slot[pr[0]] as Dictionary)["unit"], "sym", 3)
					RelicHooks.rb_add((by_slot[pr[1]] as Dictionary)["unit"], "sym", 3)
			if pairs_ok == 2 and by_slot.has(2):
				RelicHooks.rb_add((by_slot[2] as Dictionary)["unit"], "sym", 1)
			return,
	},
	"r_devilsreroll": {
		# Pact (mana group). The +3 max Rerolls is the `rerollUp` field; every Reroll (Aid included) costs 1 Mana.
		# CombatEngine refuses the reroll when Mana is short, so "no Mana = no Reroll" is the engine's rule.
		"before_reroll": func(ctx: Dictionary):
			ctx["mana_cost"] = int(ctx.get("mana_cost", 0)) + 1
			return,
	},
	"r_twinfates": {
		# Pact (reroll group): every Axie rolls 2 faces and keeps the higher main value (tie keeps the
		# first); max Rerolls 0 and every Reroll source is vetoed.
		"before_reroll": func(ctx: Dictionary):
			ctx["veto"] = true
			return,
		"on_combat_start": func(ctx: Dictionary):
			var c = ctx["combat"]
			c.max_rerolls = 0
			c.rerolls = 0
			return,
		"roll_face": func(ctx: Dictionary):
			var fi := int(ctx["value"])
			var u: Unit = ctx["unit"]
			if u.side != "p":
				return fi
			var fi2: int = ctx["combat"]._rng.next_int(6)
			return fi2 if int(u.die[fi2].get("value", 0)) > int(u.die[fi].get("value", 0)) else fi,
	},
	"r_ironvow": {
		# Pact (dice group, axis A:shield). Benefit: every Shield a party Axie gains x1.5 (`shield_value`,
		# DamagePipeline.apply_shield) and the whole team starts each fight with +2 Thorns. Drawback: every
		# dmg face -2 but never below 1 (mul phase, so it lands after the +N relics). Faces already 0 stay 0.
		"mod_face": func(ctx: Dictionary):
			for f in ctx["unit"].die:
				if String(f.get("type", "")) == "dmg" and int(f.get("value", 0)) > 0:
					f["value"] = maxi(1, int(f.get("value", 0)) - 2)
			return,
		"shield_value": func(ctx: Dictionary):
			var tgt: Unit = ctx["tgt"]
			if tgt.side != "p":
				return ctx["value"]
			var m := 1.0 + RelicHooks.axis_sum(ctx["combat"], "A:shield")
			return RulesMath.round_half_up(float(ctx["value"]) * m),
		"on_combat_start": func(ctx: Dictionary):
			for u in ctx["combat"].party:
				if u.hp > 0:
					u.status["thorns"] = StatusEngine.clamp_thorns(int(u.status.get("thorns", 0)) + 2)
			return,
	},
	"r_lonewolf": {
		# Pact (reroll group, axis G). Benefit is `g_axie` (slot 1 only, +100%). Drawback: only the Axie
		# in slot 1 may be rerolled; CombatEngine._rerollable asks `reroll_allowed` per Axie.
		"reroll_allowed": func(ctx: Dictionary):
			return RelicHooks.slot_of(ctx["unit"]) == 0 and bool(ctx["value"]),
	},
	"r_hollowchalice": {
		# Pact (mana group). +1 active slot is RelicSlots (chalice_id). Every active costs 2 less Mana
		# (min 1) via `active_cost`; every Mana face gives 0 after ALL mods (`face_final`).
		"active_cost": func(ctx: Dictionary):
			return maxi(1, int(ctx["value"]) - 2),
		"face_final": func(ctx: Dictionary):
			if String(ctx["face_type"]) == "mana" and ctx["unit"].side == "p":
				return 0
			return ctx["value"],
	},
	"r_alphafang": {
		# Class-up (beast). FERAL threshold 65% (FERAL only). A Beast Axie's face kill refunds 1 Reroll,
		# once per turn, through grant_relic_reroll (4/turn cap). Ticks/thorns/relic kills pass killer null.
		"class_field": func(ctx: Dictionary):
			return 0.65 if ctx["key"] == "feral_threshold" else ctx["value"],
		"on_kill": func(ctx: Dictionary):
			var k = ctx.get("killer", null)
			if k != null and k.cls == "beast" and RelicHooks.once_per_turn(ctx["combat"], "alphafang_t"):
				ctx["combat"].grant_relic_reroll(1)
			return,
	},
	"r_falconhood": {
		# Class-up (bird). TALON +5 (was +3); a Bird's Pierce hit ignores Thorns.
		"class_field": func(ctx: Dictionary):
			if ctx["key"] == "talon_pierce":
				return 5.0
			if ctx["key"] == "talon_ignore_thorns":
				return 1.0
			return ctx["value"],
	},
	"r_heartrootgrove": {
		# Class-up (plant). BULWARK: Thorns 3 from >=6 Shield (was 2 from 10). End of turn a Plant with
		# >=10 Shield gives 3 Shield to each adjacent Axie.
		"class_field": func(ctx: Dictionary):
			if ctx["key"] == "bulwark_at":
				return 6.0
			if ctx["key"] == "bulwark_thorns":
				return 3.0
			return ctx["value"],
		"on_turn_end": func(ctx: Dictionary):
			var c = ctx["combat"]
			for u in RelicHooks.party_line(c):
				if u.cls == "plant" and u.shield >= 10:
					for n in RelicHooks.slot_neighbors(c, u):
						DamagePipeline.apply_shield(c, n, 3)
			return,
	},
	"r_shedskin": {
		# Class-up (reptile). SCALES: Thorns 4 (was 2), Thorns poison 2 (was 1). A Reptile hit while it had
		# no Shield gains 4 Shield (once per turn per Axie).
		"class_field": func(ctx: Dictionary):
			if ctx["key"] == "scales_thorns":
				return 4.0
			if ctx["key"] == "scales_poison":
				return 2.0
			return ctx["value"],
		"on_dmg_taken": func(ctx: Dictionary):
			var t: Unit = ctx["tgt"]
			if t.side == "p" and t.cls == "reptile" and t.hp > 0 and not bool(ctx.get("had_shield", true)) \
					and RelicHooks.once_per_turn(ctx["combat"], "shedskin_%d" % t.uid):
				DamagePipeline.apply_shield(ctx["combat"], t, 4)
			return,
	},
	"r_tidecaller": {
		# Class-up (aqua). CONDUIT: 1 Reroll per 3 Mana spent (was 4); Aqua Mana faces +1 more.
		# The "may exceed max by up to 2" clause needs no code: CONDUIT rerolls are not clamped to max today.
		"class_field": func(ctx: Dictionary):
			return 3.0 if ctx["key"] == "conduit_step" else ctx["value"],
		"mod_face": func(ctx: Dictionary):
			var u: Unit = ctx["unit"]
			if u.cls == "aqua":
				for f in u.die:
					if String(f.get("type", "")) == "mana":
						f["value"] = int(f.get("value", 0)) + 1
			return,
	},
	"r_venomlineage": {
		# Class-up (bug). VIRULENT +3 (was +2); a Bug's first Poison each turn also puts 1 stack on each
		# neighbouring enemy.
		"class_field": func(ctx: Dictionary):
			return 3.0 if ctx["key"] == "virulent_bonus" else ctx["value"],
		"on_poison_applied": func(ctx: Dictionary):
			var s = ctx.get("src", null)
			var t: Unit = ctx["tgt"]
			if s == null or s.side != "p" or s.cls != "bug" or t.side != "e":
				return
			if not RelicHooks.once_per_turn(ctx["combat"], "venomlin_%d" % s.uid):
				return
			var arr: Array = ctx["combat"].alive_enemies()
			var i := arr.find(t)
			for x in [arr[i - 1] if i > 0 else null, arr[i + 1] if i >= 0 and i < arr.size() - 1 else null]:
				if x != null:
					x.status["poison"] = StatusEngine.capped_poison(ctx["combat"], int(x.status.get("poison", 0)), 1)
					EventBus.float_text.emit(x.uid, "PSN 1", "poi", 0)
			return,
	},
	"r_assassinsneedle": {
		# Duo (crit/pierce). FACE_CRIT: Pierce dmg faces +25 crit chance. FACE_CTX: a Pierce crit puts Weaken 2
		# on the target and refunds 1 Mana (once per face use).
		"face_crit": func(ctx: Dictionary):
			var f: Dictionary = ctx["face"]
			if String(f.get("type", "")) == "dmg" and (f["keywords"] as Array).has("pierce") and ctx["unit"].side == "p":
				return float(ctx["value"]) + 25.0
			return ctx["value"],
		"on_face_hit": func(ctx: Dictionary):
			var u: Unit = ctx["unit"]
			var t: Unit = ctx["tgt"]
			if u.side != "p" or not bool(ctx["crit"]) or not bool(ctx["pierce"]) or t.hp <= 0:
				return
			StatusEngine.add_status(ctx["combat"], t, ["weaken:2"], u)
			if bool(ctx["first"]):
				ctx["combat"].mana += 1
				EventBus.float_text.emit(u.uid, "+1 MP", "man", 0)
			return,
	},
	"r_breakersward": {
		# Duo (shield/pierce). SHIELD_BREAK: when a party attack removes enemy Shield, the party Axie with the
		# least Shield gains that much (max 8 per hit). Ties go to the lower slot.
		"on_shield_break": func(ctx: Dictionary):
			var c = ctx["combat"]
			var got := mini(8, int(ctx["broken"]))
			var low: Unit = null
			for u in RelicHooks.party_line(c):
				if low == null or u.shield < low.shield:
					low = u
			if low != null and got > 0:
				DamagePipeline.apply_shield(c, low, got)
			return,
	},
	"r_firestormveil": {
		# Duo (burn/aoe). FACE_CTX: every enemy an AoE dmg face hits gets Burn 2, +1 more if it was already
		# burning.
		"on_face_hit": func(ctx: Dictionary):
			var t: Unit = ctx["tgt"]
			if not bool(ctx["aoe"]) or ctx["unit"].side != "p" or t.hp <= 0 or t.side != "e":
				return
			var was := int(t.status.get("burn", 0)) > 0
			t.status["burn"] = int(t.status.get("burn", 0)) + (3 if was else 2)
			EventBus.float_text.emit(t.uid, "BUR%d" % (3 if was else 2), "deb", 0)
			return,
	},
	"r_fumeblossom": {
		# Duo (poison/burn). TICK: a Burn tick on an enemy adds 1 Poison to it; a Poison tick on a burning
		# enemy adds 1 Burn. Each direction at most once per enemy per turn.
		"on_status_tick": func(ctx: Dictionary):
			var c = ctx["combat"]
			var t: Unit = ctx["tgt"]
			if t.side != "e" or t.hp <= 0:
				return
			if String(ctx["kind"]) == "burn":
				if RelicHooks.once_per_turn(c, "fume_b_%d" % t.uid):
					t.status["poison"] = StatusEngine.capped_poison(ctx["combat"], int(t.status.get("poison", 0)), 1)
					EventBus.float_text.emit(t.uid, "PSN 1", "poi", 0)
			elif int(t.status.get("burn", 0)) > 0 and RelicHooks.once_per_turn(c, "fume_p_%d" % t.uid):
				t.status["burn"] = int(t.status.get("burn", 0)) + 1
				EventBus.float_text.emit(t.uid, "BUR1", "deb", 0)
			return,
	},
	"r_sporegale": {
		# Duo (poison/aoe). FACE_CTX: Cleave/AoE dmg faces put 1 Poison on every secondary target. TICK: each
		# Poison tick on an enemy spreads 1 Poison stack to its neighbours.
		"on_face_hit": func(ctx: Dictionary):
			var t: Unit = ctx["tgt"]
			if not bool(ctx["secondary"]) or ctx["unit"].side != "p" or t.hp <= 0 or t.side != "e":
				return
			t.status["poison"] = StatusEngine.capped_poison(ctx["combat"], int(t.status.get("poison", 0)), 1)
			EventBus.float_text.emit(t.uid, "PSN 1", "poi", 0)
			return,
		"on_status_tick": func(ctx: Dictionary):
			var t: Unit = ctx["tgt"]
			if String(ctx["kind"]) != "poison" or t.side != "e" or t.hp <= 0:
				return
			var arr: Array = ctx["combat"].alive_enemies()
			var i := arr.find(t)
			for x in [arr[i - 1] if i > 0 else null, arr[i + 1] if i >= 0 and i < arr.size() - 1 else null]:
				if x != null:
					x.status["poison"] = StatusEngine.capped_poison(ctx["combat"], int(x.status.get("poison", 0)), 1)
					EventBus.float_text.emit(x.uid, "PSN 1", "poi", 0)
			return,
	},
	"r_tithepips": {
		# Pact (dice group): +3 Mana each turn; after every roll the lowest-value face is blanked (exactly
		# one, living non-Egg Axies with an unused face, tie to the lower slot). Recomputed at every settle.
		"on_turn_start": func(ctx: Dictionary):
			var c = ctx["combat"]
			var line := RelicHooks.party_line(c)
			c.mana += 3
			if not line.is_empty():
				EventBus.float_text.emit((line[0] as Unit).uid, "+3 MP", "man", 0)
			return,
		"on_roll_settled": func(ctx: Dictionary):
			var c = ctx["combat"]
			for u in c.party:
				RelicHooks.unblank(u)
			var worst: Unit = null
			var worst_v := 0
			for u in RelicHooks.party_line(c):
				var fi: int = u.roll_face_index()
				if fi < 0 or u.roll_used() or String(u.die[fi].get("type", "")) == "blank":
					continue
				var v := int(u.die[fi].get("value", 0))
				if worst == null or v < worst_v:
					worst = u
					worst_v = v
			if worst != null:
				RelicHooks.blank_face(worst)
			return,
	},
	"r_amberdie": {
		# HOLD (no Tweak cost, once per turn): pick one unused die; next turn that Axie keeps this exact face.
		"on_turn_start": func(ctx: Dictionary):
			ctx["combat"].relic_combat["tweak_left"] = RelicSlots.tuning().tweak_budget_per_turn
			return,
		"roll_edit": func(ctx: Dictionary):
			var c = ctx["combat"]
			if bool(ctx["ok"]) or String(ctx["kind"]) != "hold":
				return
			var u: Unit = RelicHooks.tweakable(c, int(ctx["uid_a"]))
			if u == null or int(c.relic_combat.get("amber_t", -1)) == c.turn:
				return
			c.relic_combat["amber_t"] = c.turn
			c.relic_combat["amber"] = {"uid": u.uid, "fi": u.roll_face_index(), "t": c.turn}
			ctx["ok"] = true
			return,
		"roll_face": func(ctx: Dictionary):
			var c = ctx["combat"]
			var fi := int(ctx["value"])
			var h: Dictionary = c.relic_combat.get("amber", {})
			var u: Unit = ctx["unit"]
			if not h.is_empty() and int(h["uid"]) == u.uid and c.turn > int(h["t"]):
				c.relic_combat.erase("amber")
				return int(h["fi"])
			return fi,
	},
	"r_pipfile": {
		# NUDGE (shared budget of 2 Tweaks/turn): +1 or -1 on the main value of a rolled face (min 1).
		"on_turn_start": func(ctx: Dictionary):
			ctx["combat"].relic_combat["tweak_left"] = RelicSlots.tuning().tweak_budget_per_turn
			return,
		# The nudge is per-roll and never counted: it comes off a rerolled die, and off every die at turn end.
		"on_roll_settled": func(ctx: Dictionary):
			var c = ctx["combat"]
			for u in c.party:
				if int(u.uid) in (ctx.get("rerolled_uids", []) as Array):
					RelicHooks.rb_clear(u, "tweak")
			return,
		"on_turn_end": func(ctx: Dictionary):
			for u in ctx["combat"].party:
				RelicHooks.rb_clear(u, "tweak")
			return,
		"roll_edit": func(ctx: Dictionary):
			var c = ctx["combat"]
			var k := String(ctx["kind"])
			if not RelicHooks.tweak_gate(ctx, ["nudge_up", "nudge_down"]):
				return
			var u: Unit = RelicHooks.tweakable(c, int(ctx["uid_a"]))
			if u == null:
				return
			var f: Dictionary = u.die[u.roll_face_index()]
			var v := int(f.get("value", 0))
			if String(f.get("type", "")) == "blank" or v <= 0 or (k == "nudge_down" and v <= 1):
				return
			RelicHooks.rb_add(u, "tweak", 1 if k == "nudge_up" else -1)
			RelicHooks.tweak_done(ctx)
			return,
	},
	"r_mirrorpip": {
		# COPY: the rolled face of Axie A replaces the rolled face of Axie B for this turn (restored at end of turn).
		"on_turn_start": func(ctx: Dictionary):
			ctx["combat"].relic_combat["tweak_left"] = RelicSlots.tuning().tweak_budget_per_turn
			return,
		"on_turn_end": func(ctx: Dictionary):
			RelicHooks.restore_faces(ctx["combat"])
			return,
		"roll_edit": func(ctx: Dictionary):
			var c = ctx["combat"]
			if not RelicHooks.tweak_gate(ctx, ["copy"]):
				return
			var a: Unit = c.by_uid(int(ctx["uid_a"]))
			var b: Unit = RelicHooks.tweakable(c, int(ctx["uid_b"]))
			if a == null or b == null or a == b or a.side != "p" or a.hp <= 0 or a.is_token or not a.has_rolled():
				return
			if String(a.die[a.roll_face_index()].get("type", "")) == "blank":
				return
			RelicHooks.normalize(a)
			RelicHooks.normalize(b)
			var src_face: Dictionary = (a.die[a.roll_face_index()] as Dictionary).duplicate(true)
			RelicHooks.backup_face(b, b.roll_face_index())
			b.die[b.roll_face_index()] = src_face
			RelicHooks.tweak_done(ctx)
			return,
	},
	"r_twinswap": {
		# SWAP: exchange the rolled faces of two Axies that have not used theirs (restored at end of turn).
		"on_turn_start": func(ctx: Dictionary):
			ctx["combat"].relic_combat["tweak_left"] = RelicSlots.tuning().tweak_budget_per_turn
			return,
		"on_turn_end": func(ctx: Dictionary):
			RelicHooks.restore_faces(ctx["combat"])
			return,
		"roll_edit": func(ctx: Dictionary):
			var c = ctx["combat"]
			if not RelicHooks.tweak_gate(ctx, ["swap"]):
				return
			var a: Unit = RelicHooks.tweakable(c, int(ctx["uid_a"]))
			var b: Unit = RelicHooks.tweakable(c, int(ctx["uid_b"]))
			if a == null or b == null or a == b:
				return
			RelicHooks.normalize(a)
			RelicHooks.normalize(b)
			var fa := a.roll_face_index()
			var fb := b.roll_face_index()
			RelicHooks.backup_face(a, fa)
			RelicHooks.backup_face(b, fb)
			var tmp: Dictionary = a.die[fa]
			a.die[fa] = b.die[fb]
			b.die[fb] = tmp
			RelicHooks.tweak_done(ctx)
			return,
	},
	"r_flipside": {
		# FLIP: the rolled face becomes the opposite face of the same die (index + flip_offset mod 6).
		"on_turn_start": func(ctx: Dictionary):
			ctx["combat"].relic_combat["tweak_left"] = RelicSlots.tuning().tweak_budget_per_turn
			return,
		"roll_edit": func(ctx: Dictionary):
			var c = ctx["combat"]
			if not RelicHooks.tweak_gate(ctx, ["flip"]):
				return
			var u: Unit = RelicHooks.tweakable(c, int(ctx["uid_a"]))
			if u == null:
				return
			RelicHooks.normalize(u)
			var nf: int = (u.roll_face_index() + RelicSlots.tuning().flip_offset) % 6
			u.set_roll(nf, false)
			u.heavy = (u.die[nf]["keywords"] as Array).has("heavy")
			RelicHooks.tweak_done(ctx)
			return,
	},
	"r_loadeddie": {
		# LOCK (run-level): the chosen face of the chosen Axie weighs x3 (3/8 = 37.5% instead of 1/6) for the run.
		# The pick happens once, in a fight, through CombatEngine.loaded_pick(uid, face_index).
		"on_turn_start": func(ctx: Dictionary):
			ctx["combat"].relic_combat["tweak_left"] = RelicSlots.tuning().tweak_budget_per_turn
			return,
		"roll_edit": func(ctx: Dictionary):
			var c = ctx["combat"]
			if bool(ctx["ok"]) or String(ctx["kind"]) != "loaded" or c.relic_run_out.has("r_loadeddie"):
				return
			var u: Unit = c.by_uid(int(ctx["uid_a"]))
			var fi := int(ctx["face_index"])
			if u == null or u.side != "p" or u.is_token or fi < 0 or fi >= u.die.size():
				return
			c.relic_run_out["r_loadeddie"] = {"uid": u.uid, "fi": fi}
			ctx["ok"] = true
			return,
		"roll_face": func(ctx: Dictionary):
			var c = ctx["combat"]
			var u: Unit = ctx["unit"]
			var pick: Dictionary = c.relic_run_out.get("r_loadeddie", {})
			if pick.is_empty() or int(pick["uid"]) != u.uid:
				return int(ctx["value"])
			var loaded := int(pick["fi"])
			var r: int = c._rng.next_int(8)
			if r < 3:
				return loaded
			var idx := r - 3
			return idx if idx < loaded else idx + 1,
	},
	"r_merchantscale": {
		# Shops offer 3 relics instead of 2. Prices and sell values do not change.
		"shop_relic_count": func(ctx: Dictionary):
			return int(ctx["value"]) + 1,
	},
	"r_fortuneledger": {
		# +1 reward reroll charge per reward screen (the 25 Gene Shard cost per use is RunState's).
		"reward_reroll_charges": func(ctx: Dictionary):
			return int(ctx["value"]) + 1,
	},
	"r_scavengereye": {
		# Battle/Elite rewards show 4 cards instead of 3 (Treasure's extra relic card is RunState's).
		"reward_card_count": func(ctx: Dictionary):
			return int(ctx["value"]) + (1 if String(ctx.get("kind", "")) == "reward" else 0),
	},
	"r_broodbloom": {
		# Growth + Summon duo: at end of turn each Egg +1 Growth on every face; a newly hatched Egg is
		# brought up to the level of the highest Egg at the next turn boundary.
		"on_turn_end": func(ctx: Dictionary):
			RelicHooks.egg_growth_step(ctx["combat"], 1)
			return,
		"on_turn_start": func(ctx: Dictionary):
			RelicHooks.egg_growth_step(ctx["combat"], 0)
			return,
	},
	# ---- Depth v3 Cores / Run Rules (lane C): logic in core_hooks.gd, one TABLE entry per id ----
	# CORE_TABLE_BEGIN
	"c_bastion": {"incoming_dmg": func(ctx: Dictionary): return CoreHooks.incoming(ctx, "c_bastion")},
	"c_fissure": {
		"on_face_used": func(ctx: Dictionary): CoreHooks.fissure_used(ctx),
		"incoming_dmg": func(ctx: Dictionary): return CoreHooks.incoming(ctx, "c_fissure"),
	},
	"c_nest": {"on_combat_start": func(ctx: Dictionary): CoreHooks.nest_start(ctx)},
	"c_deep_current": {
		"on_combat_start": func(ctx: Dictionary): CoreHooks.deep_current_start(ctx),
		"on_combat_end": func(ctx: Dictionary): CoreHooks.deep_current_end(ctx),
	},
	"c_growing_shell": {
		"mod_face": func(ctx: Dictionary): CoreHooks.shell_face(ctx),
		"on_kill": func(ctx: Dictionary): CoreHooks.shell_kill(ctx),
		"on_dmg_taken": func(ctx: Dictionary): CoreHooks.shell_fall(ctx),
	},
	"rule_rising_tide": {
		"on_combat_start": func(ctx: Dictionary): CoreHooks.tide_start(ctx),
		"incoming_dmg": func(ctx: Dictionary): return CoreHooks.incoming(ctx, "rule_rising_tide"),
		"face_final": func(ctx: Dictionary): return CoreHooks.flat(ctx, "rule_rising_tide"),
	},
	"rule_upside_down": {"enemy_row_pref": func(ctx: Dictionary): return "back"},
	"rule_quick_beat": {
		"boss_period": func(ctx: Dictionary): return 2,
		"boss_strike_mult": func(ctx: Dictionary): return 1.2,
		"on_turn_start": func(ctx: Dictionary):
			for e in ctx["combat"].alive_enemies():
				if e.is_boss:
					CoreHooks.fire("rule_quick_beat", e.uid, 1, "rule"),
	},
	"rule_hard_shell": {},
	"c_descend": {
		"descend_pick": func(ctx: Dictionary): return CoreHooks.descend_pick(ctx),
		"mod_face": func(ctx: Dictionary): CoreHooks.descend_face(ctx),
		"on_face_hit": func(ctx: Dictionary): CoreHooks.descend_hit(ctx),
	},
	"c_concord": {
		"roll_share_class": func(ctx: Dictionary): return true,
		"on_face_used": func(ctx: Dictionary): CoreHooks.concord_used(ctx),
		"face_final": func(ctx: Dictionary): return CoreHooks.flat(ctx, "c_concord"),
	},
	"c_sixth_die": {"extra_dice": func(ctx: Dictionary): return int(ctx["value"]) + 1},
	"c_sacrifice": {
		"on_combat_start": func(ctx: Dictionary): CoreHooks.sacrifice_start(ctx),
		"face_final": func(ctx: Dictionary): return CoreHooks.flat(ctx, "c_sacrifice"),
	},
	"c_loop": {"cantrip_extra": func(ctx: Dictionary): return int(ctx["value"]) + 1},
	"c_early_scales": {"on_combat_start": func(ctx: Dictionary): CoreHooks.early_scales_start(ctx)},
	"c_dewdrop": {"on_turn_start": func(ctx: Dictionary): CoreHooks.dewdrop_turn(ctx)},
	"c_elder_trunk": {"mod_face": func(ctx: Dictionary): CoreHooks.elder_trunk_face(ctx)},
	"c_steady_hold": {
		"stash_cap": func(ctx: Dictionary): return CoreHooks.steady_hold_cap(ctx),
		"stash_repeat": func(ctx: Dictionary): return true,
		"on_stash": func(ctx: Dictionary): CoreHooks.steady_hold_stash(ctx),
		"face_final": func(ctx: Dictionary): return CoreHooks.flat(ctx, "c_steady_hold"),
		"on_face_used": func(ctx: Dictionary): CoreHooks.focus_spent(ctx["combat"], "focus_c_steady_hold", ctx["unit"]),
	},
	"c_kindle": {
		"on_stash": func(ctx: Dictionary): CoreHooks.kindle_stash(ctx),
		"face_final": func(ctx: Dictionary): return CoreHooks.flat(ctx, "c_kindle"),
		"on_face_used": func(ctx: Dictionary): CoreHooks.focus_spent(ctx["combat"], "focus_c_kindle", ctx["unit"]),
	},
	"c_prime_chain": {
		"on_face_used": func(ctx: Dictionary): CoreHooks.prime_used(ctx),
		"face_final": func(ctx: Dictionary): return CoreHooks.flat(ctx, "c_prime_chain"),
	},
	"c_finisher": {
		"on_face_used": func(ctx: Dictionary): CoreHooks.count_used(ctx),
		"face_final": func(ctx: Dictionary): return CoreHooks.flat(ctx, "c_finisher"),
	},
	"c_prism": {
		"on_face_used": func(ctx: Dictionary): CoreHooks.note_category(ctx),
		"on_turn_end": func(ctx: Dictionary): CoreHooks.prism_turn_end(ctx),
	},
	"c_mana_pool": {
		"face_final": func(ctx: Dictionary): return CoreHooks.flat(ctx, "c_mana_pool"),
		"on_turn_end": func(ctx: Dictionary): CoreHooks.mana_pool_turn_end(ctx),
	},
	"c_tidecaller": {
		"on_active_played": func(ctx: Dictionary): CoreHooks.tide_spent(ctx),
		"on_reroll_paid": func(ctx: Dictionary): CoreHooks.tide_spent(ctx),
	},
	"c_sonic_shield": {"on_face_used": func(ctx: Dictionary): CoreHooks.sonic_used(ctx)},
	"c_field_medic": {
		"mod_face": func(ctx: Dictionary): CoreHooks.field_medic_face(ctx),
		"face_final": func(ctx: Dictionary): return CoreHooks.flat(ctx, "c_field_medic"),
	},
	"c_plague_spread": {
		"on_kill": func(ctx: Dictionary): CoreHooks.plague_kill(ctx),
		"face_final": func(ctx: Dictionary): return CoreHooks.flat(ctx, "c_plague_spread"),
	},
	"c_mirror_face": {"on_face_used": func(ctx: Dictionary): CoreHooks.mirror_used(ctx)},
	"c_whittle": {
		"mod_face": func(ctx: Dictionary): CoreHooks.whittle_face(ctx),
		"roll_face": func(ctx: Dictionary): return CoreHooks.whittle_roll(ctx),
	},
	"c_three_dice": {
		"on_face_used": func(ctx: Dictionary):
			CoreHooks.focus_spent(ctx["combat"], "focus_c_three_dice", ctx["unit"])
			CoreHooks.count_used(ctx)
			CoreHooks.three_used(ctx),
		"on_turn_end": func(ctx: Dictionary): CoreHooks.three_auto_hold(ctx["combat"]),
		"face_final": func(ctx: Dictionary): return CoreHooks.flat(ctx, "c_three_dice"),
	},
	"c_toxic_still": {
		"mod_face": func(ctx: Dictionary): CoreHooks.toxic_still_face(ctx),
		"on_turn_end": func(ctx: Dictionary): CoreHooks.toxic_still_turn_end(ctx),
	},
	"c_gatekeeper": {
		"on_dmg_taken": func(ctx: Dictionary): CoreHooks.gatekeeper_hit(ctx),
		"on_face_used": func(ctx: Dictionary): CoreHooks.gatekeeper_used(ctx),
		"on_turn_end": func(ctx: Dictionary): CoreHooks.gatekeeper_turn_end(ctx),
		"face_final": func(ctx: Dictionary): return CoreHooks.flat(ctx, "c_gatekeeper"),
	},
	"c_thorn_growth": {"on_dmg_taken": func(ctx: Dictionary): CoreHooks.thorn_growth_hit(ctx)},
	"c_thorn_shield": {"on_turn_end": func(ctx: Dictionary): CoreHooks.thorn_shield_turn_end(ctx)},
	"c_thorn_rebound": {
		"thorns_extra": func(ctx: Dictionary): return CoreHooks.rebound_extra(ctx),
		"face_blocked": func(ctx: Dictionary): return CoreHooks.rebound_blocked(ctx),
	},
	"c_backline_glow": {
		"mod_face": func(ctx: Dictionary): CoreHooks.backline_face(ctx),
		"face_final": func(ctx: Dictionary): return CoreHooks.backline_value(ctx),
	},
	"c_living_wall": {
		"front_row_size": func(ctx: Dictionary): return 1,
		"mod_face": func(ctx: Dictionary): CoreHooks.living_wall_face(ctx),
		"on_combat_start": func(ctx: Dictionary): CoreHooks.living_wall_start(ctx),
	},
	"c_open_ranks": {
		"front_row_size": func(ctx: Dictionary): return 99,
		"on_combat_start": func(ctx: Dictionary):
			var cb = ctx["combat"]
			CoreHooks.fire("c_open_ranks", 0, CoreHooks.living_axies(cb).size() - int(CombatEngine.tune_knob("rows", "front_size", 2.0)), "rule"),
	},
	"c_mana_ward": {"on_turn_end": func(ctx: Dictionary): CoreHooks.mana_ward_turn_end(ctx)},
	"c_overflow": {
		"on_face_used": func(ctx: Dictionary): CoreHooks.overflow_check(ctx),
		"on_turn_start": func(ctx: Dictionary): CoreHooks.overflow_check(ctx),
		"on_turn_end": func(ctx: Dictionary): CoreHooks.overflow_check(ctx),
	},
	"c_hollow_core": {
		"reroll_mana_cost": func(ctx: Dictionary): return CoreHooks.reroll_cheaper(ctx),
		"reroll_hard_cap": func(ctx: Dictionary): return CoreHooks.reroll_cap_up(ctx),
		"on_reroll_paid": func(ctx: Dictionary): CoreHooks.hollow_paid(ctx),
		"on_roll_settled": func(ctx: Dictionary): CoreHooks.rerolled_count(ctx),
		"face_final": func(ctx: Dictionary): return CoreHooks.flat(ctx, "c_hollow_core"),
	},
	"c_thorn_pact": {
		"reroll_mana_cost": func(ctx: Dictionary): return 0,
		"reroll_allowed": func(ctx: Dictionary): return CoreHooks.thorn_allowed(ctx),
		"on_roll_settled": func(ctx: Dictionary): CoreHooks.thorn_settled(ctx),
		"face_final": func(ctx: Dictionary): return CoreHooks.flat(ctx, "c_thorn_pact"),
	},
	"c_collector": {
		"on_face_used": func(ctx: Dictionary): CoreHooks.note_category(ctx),
		"on_turn_start": func(ctx: Dictionary): CoreHooks.collector_turn_start(ctx),
		"on_turn_end": func(ctx: Dictionary): CoreHooks.collector_turn_end(ctx),
	},
	"c_dry_well": {
		"on_combat_start": func(ctx: Dictionary): CoreHooks.dry_well_start(ctx),
		"on_active_played": func(ctx: Dictionary): CoreHooks.dry_well_spent(ctx),
		"on_reroll_paid": func(ctx: Dictionary): CoreHooks.dry_well_spent(ctx),
	},
	"c_night_watch": {
		"mod_face": func(ctx: Dictionary): CoreHooks.night_watch_face(ctx),
		"on_combat_end": func(ctx: Dictionary): CoreHooks.night_watch_end(ctx),
	},
	"c_key_strike": {
		"stash_repeat": func(ctx: Dictionary): return bool(ctx["value"]) or not CoreHooks.quest_done(ctx["combat"], "c_key_strike"),
		"on_face_hit": func(ctx: Dictionary): CoreHooks.key_strike_hit(ctx),
	},
	"c_meme_copycat": {
		"on_roll_settled": func(ctx: Dictionary): CoreHooks.copycat_settled(ctx),
		"face_final": func(ctx: Dictionary): return CoreHooks.copycat_face(ctx),
	},
	"c_meme_jumpy": {"on_roll_settled": func(ctx: Dictionary): CoreHooks.jumpy_settled(ctx)},
	"c_meme_nametag": {
		"on_combat_start": func(ctx: Dictionary): CoreHooks.nametag_start(ctx),
		"on_kill": func(ctx: Dictionary): CoreHooks.nametag_kill(ctx),
	},
	"c_chimera_hunt": {"on_kill": func(ctx: Dictionary): CoreHooks.chimera_kill(ctx)},
	"c_golden_egg": {
		"on_dmg_taken": func(ctx: Dictionary): CoreHooks.golden_egg_fall(ctx),
		"on_face_used": func(ctx: Dictionary): CoreHooks.golden_egg_used(ctx),
		"face_final": func(ctx: Dictionary): return CoreHooks.flat(ctx, "c_golden_egg"),
	},
	"c_blood_sign": {
		"on_face_hit": func(ctx: Dictionary): CoreHooks.blood_hit(ctx),
		"on_face_used": func(ctx: Dictionary): CoreHooks.blood_used(ctx),
	},
	"c_cascade": {
		"on_face_used": func(ctx: Dictionary): CoreHooks.cascade_used(ctx),
		"face_final": func(ctx: Dictionary): return CoreHooks.flat(ctx, "c_cascade"),
	},
	"c_spore_burst": {"on_dmg_taken": func(ctx: Dictionary): CoreHooks.spore_fall(ctx)},
	"rule_cheap_mana": {
		"reroll_mana_cost": func(ctx: Dictionary): return CoreHooks.reroll_cheaper(ctx),
		"reroll_hard_cap": func(ctx: Dictionary): return CoreHooks.reroll_cap_up(ctx),
		"on_reroll_paid": func(ctx: Dictionary): CoreHooks.cheap_paid(ctx),
	},
	"rule_tundra": {
		"stash_cap": func(ctx: Dictionary): return int(ctx["value"]) + 1,
		"on_stash": func(ctx: Dictionary): CoreHooks.tundra_stash(ctx),
		"on_face_used": func(ctx: Dictionary): CoreHooks.focus_spent(ctx["combat"], "focus_rule_tundra", ctx["unit"]),
		"face_final": func(ctx: Dictionary): return CoreHooks.flat(ctx, "rule_tundra"),
	},
	"rule_starfall": {"on_combat_start": func(ctx: Dictionary): CoreHooks.scale_enemies(ctx, 1.15, false, "rule_starfall")},
	"rule_heavy_finish": {
		"face_final": func(ctx: Dictionary): return CoreHooks.flat(ctx, "rule_heavy_finish"),
		"incoming_dmg": func(ctx: Dictionary): return CoreHooks.heavy_enemy_dmg(ctx),
	},
	"rule_wasteland": {"mod_face": func(ctx: Dictionary):
		ctx["unit"].max_hp += 4
		CoreHooks.fire("rule_wasteland", ctx["unit"].uid, 4, "rule")},
	"rule_dry_steppe": {
		"on_turn_start": func(ctx: Dictionary): CoreHooks.gain_mana(ctx["combat"], 2, "", "rule_dry_steppe"),
		"on_turn_end": func(ctx: Dictionary):
			CoreHooks.fire("rule_dry_steppe", 0, int(ctx["combat"].mana), "rule")
			ctx["combat"].mana = 0,
	},
	"rule_old_forest": {
		"mod_face": func(ctx: Dictionary): CoreHooks.old_forest_face(ctx),
		"on_combat_start": func(ctx: Dictionary): CoreHooks.scale_enemies(ctx, 1.3, true, "rule_old_forest"),
		"face_final": func(ctx: Dictionary): return CoreHooks.old_forest_value(ctx),
	},
	"rule_balance": {
		"face_final": func(ctx: Dictionary): return CoreHooks.balance_value(ctx),
		"on_face_used": func(ctx: Dictionary): CoreHooks.balance_used(ctx),
	},
	# data-only Run Rules: knobs live in RelicDef.rule_knobs, read by the lanes that own them
	"rule_none": {},
	"rule_crow": {},
	"c_fossil": {},
	"c_dim_stone": {},
	# CORE_TABLE_END
}


## True when the face already carries a keyword of this family. Keywords that carry a value
## are stored as "name:N" ("burn:6", "poison:2"), so an equality test against "burn" never
## matches and a relic would stack a second one onto a face that already had it. Every JS
## `f.k.some(k => k.startsWith(x))` guard maps here.
static func _has_kw_prefix(face: Dictionary, prefix: String) -> bool:
	for k in (face["keywords"] as Array):
		if String(k).begins_with(prefix):
			return true
	return false

# ---------------------------------------------------------------------------
# Helpers for the relic set v2 bodies (second batch). All static, all pure functions of the combat
# state; per-fight scratch goes through combat.relic_combat so undo/resume keep it.
# ---------------------------------------------------------------------------

const LINK_TYPES := ["dmg", "shield", "heal", "poison", "mana"]


## Slot of a party unit (positional relics). Falls back to roster_index until the engine assigns slots.
static func slot_of(u) -> int:
	return u.slot if u.slot >= 0 else u.roster_index


## Living, non-Egg party Axies in slot order (ties and "lower slot wins" rely on this order).
static func party_line(combat) -> Array:
	var out: Array = []
	for u in combat.party:
		if u.hp > 0 and not u.is_token:
			out.append(u)
	out.sort_custom(func(a, b): return slot_of(a) < slot_of(b))
	return out


## Living non-Egg Axies standing in the slot right before/after `u`.
static func slot_neighbors(combat, u) -> Array:
	var out: Array = []
	var s := slot_of(u)
	for n in party_line(combat):
		if absi(slot_of(n) - s) == 1:
			out.append(n)
	return out


## True the first time it is asked in this turn for `key`; remembered in relic_combat (undo-safe).
static func once_per_turn(combat, key: String) -> bool:
	if int(combat.relic_combat.get(key, -1)) == int(combat.turn):
		return false
	combat.relic_combat[key] = int(combat.turn)
	return true


## How many whole `step`-Mana chunks were spent that this relic has not been paid for yet; marks them paid.
static func mana_steps_due(combat, relic_id: String, step: int) -> int:
	var key := "mana_paid_" + relic_id
	var total: int = int(combat.mana_spent) / step
	var due: int = total - int(combat.relic_combat.get(key, 0))
	combat.relic_combat[key] = total
	return maxi(0, due)


static func relay_of(combat) -> Dictionary:
	if not (combat.relic_combat.get("relay") is Dictionary):
		combat.relic_combat["relay"] = {}
	return combat.relic_combat["relay"]


## +n on every damage face (value > 0) of every party unit, Eggs included.
static func add_to_dmg_faces(combat, n: int) -> void:
	for u in combat.party:
		for f in u.die:
			if String(f.get("type", "")) == "dmg" and int(f.get("value", 0)) > 0:
				f["value"] = int(f.get("value", 0)) + n


# --- per-roll bonuses: attached to the rolled face, removed and re-attached at every settle ---

static func rb_add(unit, key: String, amount: int) -> void:
	var fi: int = unit.roll_face_index()
	if fi < 0 or amount == 0:
		return
	var f: Dictionary = unit.die[fi]
	if String(f.get("type", "")) == "blank":
		return
	var rb: Dictionary = unit.custom_state.get("rb", {})
	var e: Dictionary = rb.get(key, {})
	if not e.is_empty() and int(e["fi"]) != fi:
		rb_clear(unit, key)
		rb = unit.custom_state.get("rb", {})
		e = {}
	f["value"] = int(f.get("value", 0)) + amount
	rb[key] = {"fi": fi, "amt": int(e.get("amt", 0)) + amount}
	unit.custom_state["rb"] = rb


static func rb_clear(unit, key: String) -> void:
	var rb: Dictionary = unit.custom_state.get("rb", {})
	if not rb.has(key):
		return
	var e: Dictionary = rb[key]
	var fi := int(e["fi"])
	if fi >= 0 and fi < unit.die.size():
		(unit.die[fi] as Dictionary)["value"] = int((unit.die[fi] as Dictionary).get("value", 0)) - int(e["amt"])
	rb.erase(key)
	unit.custom_state["rb"] = rb


static func rb_clear_all(unit) -> void:
	for k in (unit.custom_state.get("rb", {}) as Dictionary).keys():
		rb_clear(unit, String(k))


# --- tithepips blank ---

static func blank_face(unit) -> void:
	var fi: int = unit.roll_face_index()
	if fi < 0:
		return
	unit.custom_state["blanked"] = {"fi": fi, "type": String(unit.die[fi].get("type", ""))}
	unit.die[fi]["type"] = "blank"


static func unblank(unit) -> void:
	var b: Dictionary = unit.custom_state.get("blanked", {})
	if b.is_empty():
		return
	var fi := int(b["fi"])
	if fi >= 0 and fi < unit.die.size():
		(unit.die[fi] as Dictionary)["type"] = String(b["type"])
	unit.custom_state.erase("blanked")


# --- dice Tweaks (shared budget in relic_combat["tweak_left"]) ---

## The Axie a Tweak may touch: ours, alive, not an Egg, rolled and not yet used.
static func tweakable(combat, uid: int):
	var u = combat.by_uid(uid)
	if u == null or u.side != "p" or u.hp <= 0 or u.is_token or not u.has_rolled() or u.roll_used():
		return null
	return u


## True when this roll_edit is one of `kinds`, nobody handled it yet, and budget is left.
static func tweak_gate(ctx: Dictionary, kinds: Array) -> bool:
	return not bool(ctx["ok"]) and kinds.has(String(ctx["kind"])) \
		and int(ctx["combat"].relic_combat.get("tweak_left", 0)) > 0


## Spends one Tweak, answers ok and re-runs the settled hooks so every per-roll bonus is recomputed
## for the edited faces.
static func tweak_done(ctx: Dictionary) -> void:
	var c = ctx["combat"]
	c.relic_combat["tweak_left"] = int(c.relic_combat.get("tweak_left", 0)) - 1
	ctx["ok"] = true
	fire(c, "on_roll_settled", {"combat": c, "rerolled_uids": []})


## Faces back to pristine (no per-roll bonus, no blank) before a Tweak swaps whole faces around.
static func normalize(unit) -> void:
	rb_clear_all(unit)
	unblank(unit)


static func backup_face(unit, fi: int) -> void:
	var fb: Dictionary = unit.custom_state.get("fb", {})
	if not fb.has(str(fi)):
		fb[str(fi)] = (unit.die[fi] as Dictionary).duplicate(true)
	unit.custom_state["fb"] = fb


## End of turn: every Tweaked-in face goes back to the die's own face.
static func restore_faces(combat) -> void:
	for u in combat.party:
		var fb: Dictionary = u.custom_state.get("fb", {})
		if fb.is_empty():
			continue
		normalize(u)
		for k in fb:
			u.die[int(k)] = (fb[k] as Dictionary).duplicate(true)
		u.custom_state.erase("fb")


## slot -> {unit, type} for the faces positional relics compare: living non-Egg Axies with an unused,
## linkable face showing.
static func link_faces(combat) -> Dictionary:
	var out: Dictionary = {}
	for u in party_line(combat):
		var fi: int = u.roll_face_index()
		if fi < 0 or u.roll_used():
			continue
		var t := String(u.die[fi].get("type", ""))
		if LINK_TYPES.has(t):
			out[slot_of(u)] = {"unit": u, "type": t}
	return out


## brood bloom: bring unsynced Eggs up to the highest Egg's level, then (inc > 0) raise everyone.
static func egg_growth_step(combat, inc: int) -> void:
	var eggs: Array = []
	var top := 0
	for u in combat.party:
		if u.is_token and u.hp > 0:
			eggs.append(u)
			top = maxi(top, int(u.custom_state.get("bb", 0)))
	for e in eggs:
		var lvl := int(e.custom_state.get("bb", -1))
		if lvl < 0:            # a newly hatched Egg joins at the top Egg's level
			for fi in e.die.size():
				e.add_growth(fi, top)
			lvl = top
		if inc > 0:
			for fi in e.die.size():
				e.add_growth(fi, inc)
			lvl += inc
		e.custom_state["bb"] = lvl


## Looks up and calls a relic hook. ctx is whatever shape that hook expects (see rule
## spec §5 for the JS hook signatures this mirrors: modFace/modFace2/modDmg/onRollEnd/
## onTurnStart/onHit/onKill/onShield/onThorns/onDmgTaken/growthAllGuard).
## Returns the hook's result, or a sensible identity default when no relic defines it:
##   - "mod_dmg" with ctx={"value":v,...} -> returns v unchanged (JS: modDmg returns v)
##   - "growth_all_guard" -> true (JS: no guard means the growthAll effect fires)
##   - anything else -> null (pure side-effect hooks: onHit/onKill/onShield/onThorns/
##     onTurnStart/onRollEnd have no return value in JS either)
static func call_hook(hook_key: String, event: String, ctx = null) -> Variant:
	if TABLE.has(hook_key) and (TABLE[hook_key] as Dictionary).has(event):
		return (TABLE[hook_key] as Dictionary)[event].call(ctx)
	match event:
		"mod_dmg":
			return (ctx as Dictionary).get("value", 0) if ctx is Dictionary else ctx
		"growth_all_guard":
			return true
		_:
			return null


# ---------------------------------------------------------------------------
# Data aggregate helpers — mirror engine.js rlist/rsum/rhas/rmax/rmul_(s,k).
# `combat` is the owning CombatEngine (for combat.relic_ids); all of these degrade to
# their JS default value when RelicRegistry has no matching defs loaded, which is always
# true right now (no .tres relics exist yet) — see architecture plan §6.
# ---------------------------------------------------------------------------

## INV-5 phase ranks for build-time die mutation. Keyword-adders run first, then flat
## adders, then multipliers — see the RelicDef.mf_phase comment and src/engine.js:36-47.
const MF_PHASE_RANK := {"kw": 0, "add": 1, "mul": 2}


## Port of src/engine.js modFaceOrder() (engine.js:42-50).
##
## Returns the owned relics' die-mutation entries sorted by
## [phase_rank, rarity, sort_index, sub] — every key a constant of the DATA, never of the
## player's pickup order. That independence is the whole point: it is what makes a relic's
## contribution a fixed number instead of a range, and what keeps a replayed seed identical
## no matter what order the run happened to offer the relics in.
##
## Each entry is {"def": RelicDef, "event": "mod_face"|"mod_face2"}.
static func mod_face_order(combat) -> Array:
	var out: Array = []
	for def in _owned_defs(combat):
		var hk: String = def.hook_key if "hook_key" in def else ""
		if hk == "" or not TABLE.has(hk):
			continue
		var entry: Dictionary = TABLE[hk]
		if entry.has("mod_face"):
			out.append({"def": def, "event": "mod_face",
				"ph": int(MF_PHASE_RANK.get(def.mf_phase if "mf_phase" in def else "add", 1)), "sub": 0})
		if entry.has("mod_face2"):
			out.append({"def": def, "event": "mod_face2",
				"ph": int(MF_PHASE_RANK.get(def.mf_phase2 if "mf_phase2" in def else "add", 1)), "sub": 1})
	out.sort_custom(func(a, b):
		if int(a["ph"]) != int(b["ph"]):
			return int(a["ph"]) < int(b["ph"])
		var ra: int = int(a["def"].rarity)
		var rb: int = int(b["def"].rarity)
		if ra != rb:
			return ra < rb
		var ia: int = int(a["def"].sort_index)
		var ib: int = int(b["def"].sort_index)
		if ia != ib:
			return ia < ib
		return int(a["sub"]) < int(b["sub"]))
	return out


## Runs every owned relic's build-time die mutation over `unit`, in INV-5 order.
## Called from CombatEngine._build_unit_from_roster() (and, for `eggInherit` relics, from
## _mk_ally()). A no-op when no owned relic declares a mod_face entry.
static func apply_mod_faces(combat, unit) -> void:
	for e in mod_face_order(combat):
		var hk: String = e["def"].hook_key
		(TABLE[hk] as Dictionary)[String(e["event"])].call({"combat": combat, "unit": unit, "def": e["def"]})


## Public alias for _owned_defs — callers that need to inspect each relic's own fields
## (rather than an aggregate sum/max) go through this, e.g. CombatEngine's growthAll pass,
## which must read each relic's amount AND consult that relic's own guard hook.
static func owned_defs(combat) -> Array:
	return _owned_defs(combat)


static func _owned_defs(combat) -> Array:
	var out: Array = []
	for id in combat.relic_ids:
		var def = RelicRegistry.get_def(id)
		if def != null:
			out.append(def)
	return out

## Threads `value` through every owned relic's hook for `event`, in pickup order
## (combat.relic_ids order) — mirrors JS `for(const r of rlist(s)) if(r.modDmg) v=r.modDmg(...)`.
## No-op today (no relics loaded): returns `value` unchanged.
static func run_value_hook(combat, event: String, ctx: Dictionary, value) -> Variant:
	if not _declares(combat, event):
		return value
	var v = value
	for def in _owned_defs(combat):
		var hk: String = def.hook_key if "hook_key" in def else ""
		if hk == "":
			continue
		ctx["value"] = v
		if TABLE.has(hk) and (TABLE[hk] as Dictionary).has(event):
			v = (TABLE[hk] as Dictionary)[event].call(ctx)
	return v

## True when at least one owned relic declares a handler for `event`. Cached on the combat object,
## keyed by the relic_ids signature, so a pickup mid-combat invalidates it. Hot-path guard only:
## skipping is result-identical because run_value_hook returns `value` untouched with no handler.
static func _declares(combat, event: String) -> bool:
	if combat == null or not (combat is Object) or not ("relic_ids" in combat):
		return true
	var sig: int = (combat.relic_ids as Array).hash()
	var cache: Dictionary = combat.get_meta("_hook_decl", {})
	if cache.get("sig", -1) != sig or not cache.has("ev"):
		cache = {"sig": sig, "ev": {}}
		combat.set_meta("_hook_decl", cache)
	var ev: Dictionary = cache["ev"]
	if not ev.has(event):
		var found := false
		for def in _owned_defs(combat):
			var hk: String = def.hook_key if "hook_key" in def else ""
			if hk != "" and TABLE.has(hk) and (TABLE[hk] as Dictionary).has(event):
				found = true
				break
		ev[event] = found
	return bool(ev[event])

## Fires every owned relic's hook for `event`, ignoring return values (pure side-effect
## hooks: onHit/onKill/onShield/onThorns/onDmgTaken/onTurnStart/onRollEnd). No-op today.
static func fire(combat, event: String, ctx) -> void:
	for def in _owned_defs(combat):
		var hk: String = def.hook_key if "hook_key" in def else ""
		if hk == "":
			continue
		if TABLE.has(hk) and (TABLE[hk] as Dictionary).has(event):
			(TABLE[hk] as Dictionary)[event].call(ctx)

## Out-of-combat twins of fire()/run_value_hook() (hook H8, relic-set-v2 §5): RunState has no
## CombatEngine while it opens a shop or builds a reward, only the owned id list. Same pickup
## order, same TABLE lookup. Handlers return data by writing into `ctx` (fire() drops returns).
## No-op when no owned relic declares `event`.
static func run_fire(relic_ids: Array, event: String, ctx: Dictionary) -> void:
	for id in relic_ids:
		var hk := _hook_key_of(String(id))
		if hk != "" and TABLE.has(hk) and (TABLE[hk] as Dictionary).has(event):
			(TABLE[hk] as Dictionary)[event].call(ctx)


## Threads `value` through every owned relic's `event` handler (ctx["value"] carries the running
## value in, the handler returns the new one). Returns `value` unchanged when nobody handles it.
static func run_value(relic_ids: Array, event: String, ctx: Dictionary, value: Variant) -> Variant:
	var v = value
	for id in relic_ids:
		var hk := _hook_key_of(String(id))
		if hk != "" and TABLE.has(hk) and (TABLE[hk] as Dictionary).has(event):
			ctx["value"] = v
			v = (TABLE[hk] as Dictionary)[event].call(ctx)
	return v


static func _hook_key_of(relic_id: String) -> String:
	var def = RelicRegistry.get_def(relic_id)
	if def == null or not ("hook_key" in def):
		return ""
	return String(def.hook_key)


## Sum of `mult_bonus` over owned relics on one multiplier axis ("A:poison", "A:burn", ...). Within an
## axis bonuses ADD (total = 1 + this); different axes multiply (relic-set-v2 §3.3).
static func axis_sum(combat, axis: String) -> float:
	var total := 0.0
	for def in _owned_defs(combat):
		if String(def.mult_axis) == axis:
			total += float(def.mult_bonus)
	return total

## G_axie = min(g_cap, 1 + G relic bonuses + that Axie's ascend/forge bonus). Damage faces only.
## r_lonewolf counts only for the Axie in slot 1 (roster index 0).
static func g_axie(combat, src) -> float:
	var b := 0.0
	for def in _owned_defs(combat):
		if String(def.mult_axis) != "G":
			continue
		if String(def.id) == "r_lonewolf" and (src == null or int(src.slot) != 0):
			continue
		b += float(def.mult_bonus)
	if src != null:
		b += float(src.g_oc_bonus)
	return minf(RelicSlots.tuning().g_cap, 1.0 + b)

## FIELD hook: class-passive numbers (FERAL threshold, TALON pierce, BULWARK, SCALES, CONDUIT step,
## VIRULENT). Call sites pass the base value; owned class-upgrade relics answer `class_field` by key.
static func field(combat, key: String, base: float) -> float:
	return float(run_value_hook(combat, "class_field", {"combat": combat, "key": key}, base))

static func sum(combat, field: String, default_value: float = 0.0) -> float:
	var total := default_value
	for def in _owned_defs(combat):
		if field in def and def.get(field):
			total += float(def.get(field))
	return total

static func has(combat, field: String) -> bool:
	for def in _owned_defs(combat):
		if field in def and def.get(field):
			return true
	return false

static func max_val(combat, field: String, default_value: float) -> float:
	var v := default_value
	for def in _owned_defs(combat):
		if field in def and def.get(field) and float(def.get(field)) > v:
			v = float(def.get(field))
	return v

static func mul(combat, field: String, default_value: float = 1.0) -> float:
	var v := default_value
	for def in _owned_defs(combat):
		if field in def and def.get(field):
			v *= float(def.get(field))
	return v
