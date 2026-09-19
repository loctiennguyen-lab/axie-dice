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
	"r_rotbite": {
		# JS: modDmg:ctx=> (ctx.tgt.st.poison>0? ctx.v+2 : ctx.v) — no event in JS either;
		# the +2 is already visible through the final hit_landed/float_text the pipeline
		# emits for the resulting total, same as JS.
		"mod_dmg": func(ctx: Dictionary):
			var tgt: Unit = ctx["tgt"]
			var v: float = float(ctx["value"])
			return v + 2.0 if int(tgt.status.get("poison", 0)) > 0 else v,
	},
	"r_tinderbox": {
		# JS: modDmg:ctx=> (ctx.tgt.st.burn>0? ctx.v+2 : ctx.v)
		"mod_dmg": func(ctx: Dictionary):
			var tgt: Unit = ctx["tgt"]
			var v: float = float(ctx["value"])
			return v + 2.0 if int(tgt.status.get("burn", 0)) > 0 else v,
	},
	"r_openwound": {
		# JS: modDmg:ctx=> ctx.tgt.st.poison>0 ? Math.ceil(ctx.v*1.3) : ctx.v
		"mod_dmg": func(ctx: Dictionary):
			var tgt: Unit = ctx["tgt"]
			var v: float = float(ctx["value"])
			return ceil(v * 1.3) if int(tgt.status.get("poison", 0)) > 0 else v,
	},
	"r_scentofblood": {
		# JS: modDmg:ctx=> (ctx.tgt.side==='e'&&ctx.tgt.hp<ctx.tgt.maxHp*0.5? ctx.v+4 : ctx.v)
		"mod_dmg": func(ctx: Dictionary):
			var tgt: Unit = ctx["tgt"]
			var v: float = float(ctx["value"])
			return v + 4.0 if (tgt.side == "e" and tgt.hp < tgt.max_hp * 0.5) else v,
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
	"r_spines": {
		# JS onTurnStart: whole living party always has Thorns >= 2. Silent in JS (no ft) —
		# pulse the relic channel when it actually raises the value so it isn't invisible
		# every single turn once it's already at the floor (rule spec §10 "never skip this").
		"on_turn_start": func(ctx: Dictionary):
			var combat = ctx["combat"]
			for u in combat.party:
				if u.hp <= 0:
					continue
				var before := int(u.status.get("thorns", 0))
				if before < 2:
					u.status["thorns"] = 2
					EventBus.relic_pulsed.emit("r_spines", u.uid)
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
	# =======================================================================
	# BUILD-TIME DIE MUTATION (modFace) — 2026-09-18 relic authoring pass.
	#
	# Every entry below is a transcription of that relic's `modFace` in src/data.js, not an
	# interpretation of its description text. Where the two disagree the JS body wins: the
	# description is what the player is promised, the body is what the live game does, and a
	# port that "fixes" the difference stops being a port.
	#
	# Two JS-isms that matter and are easy to get wrong:
	#   * `f.k.includes(x)` guards are NOT decoration. modFace runs once per unit per combat,
	#     but a die already carrying the keyword must not gain a duplicate — engine.js reads
	#     keywords with `includes`, so a second copy is inert for behaviour yet changes the
	#     array a save round-trips, and t_combat_roundtrip compares those arrays.
	#   * `f.k.some(k => k.startsWith('burn'))` is a PREFIX test, because these keywords carry
	#     a value (`burn:6`). An equality test against "burn" would never match and the relic
	#     would stack a second burn onto a face that already had one.
	# =======================================================================
	"r_claw": {
		# JS: u.die.forEach(f=>{if(f.t==='dmg')f.v+=1;})
		"mod_face": func(ctx: Dictionary):
			for f in ctx["unit"].die:
				if String(f.get("type", "")) == "dmg":
					f["value"] = int(f.get("value", 0)) + 1
			return,
	},
	"r_carapace": {
		# JS: if(f.t==='shield'||f.t==='heal')f.v+=2
		"mod_face": func(ctx: Dictionary):
			for f in ctx["unit"].die:
				var t := String(f.get("type", ""))
				if t == "shield" or t == "heal":
					f["value"] = int(f.get("value", 0)) + 2
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
	"r_barbedhide": {
		# The +1 Thorns half is the `thornsPlus` data field; only the Shield half is a modFace.
		"mod_face": func(ctx: Dictionary):
			for f in ctx["unit"].die:
				if String(f.get("type", "")) == "shield":
					f["value"] = int(f.get("value", 0)) + 1
			return,
	},
	"r_heart": {
		# JS: u=>{u.maxHp+=12;} — a modFace that touches no face at all. Kept as a modFace
		# rather than a data field because it must run inside the INV-5 pass, alongside the
		# other relics that change max HP, so the order of HP changes is data-determined too.
		"mod_face": func(ctx: Dictionary):
			ctx["unit"].max_hp += 12
			return,
	},
	"r_ear": {
		"mod_face": func(ctx: Dictionary):
			for f in ctx["unit"].die:
				if String(f.get("type", "")) == "mana":
					f["value"] = int(f.get("value", 0)) + 1
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
	"r_bloodpact": {
		# JS: u.maxHp = Math.max(4, Math.round(u.maxHp*0.85)). Math.round, not ceil/floor —
		# and JS rounds .5 toward +infinity, which is what GDScript's round() does too.
		# The x1.6 damage half is the `dmgMult` data field.
		"mod_face": func(ctx: Dictionary):
			var unit = ctx["unit"]
			unit.max_hp = maxi(4, int(round(float(unit.max_hp) * 0.85)))
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
		# The no-shield-cap and 30%-damage-reduction halves are the `noShieldCap`/`dr` fields.
		"mod_face": func(ctx: Dictionary):
			for f in ctx["unit"].die:
				if String(f.get("type", "")) == "shield":
					f["value"] = int(f.get("value", 0)) + 2
			return,
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
		# mf_phase "mul" — this is the only multiplier in the game, and the whole INV-5 phase
		# ordering exists so that it lands AFTER every flat adder no matter the pickup order.
		# ceil, and only on faces with a positive value, so blanks stay blank.
		"mod_face": func(ctx: Dictionary):
			for f in ctx["unit"].die:
				var v := int(f.get("value", 0))
				if v > 0:
					f["value"] = int(ceil(float(v) * 1.3))
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
	"r_voidgene": {
		# The +2 max rerolls half is the `rerollUp` data field.
		"on_turn_start": func(ctx: Dictionary):
			var combat = ctx["combat"]
			if combat.turn == 1:
				combat.mana += 1
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
	"r_eggshell": {
		"on_turn_start": func(ctx: Dictionary):
			var combat = ctx["combat"]
			for u in combat.party:
				if u.is_token and u.hp > 0:
					DamagePipeline.apply_shield(combat, u, 2)
			return,
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
	"r_regrow": {
		"mod_face": func(ctx: Dictionary):
			ctx["unit"].max_hp += 2
			return,
		# A floor, not an add — see the block header.
		"on_turn_start": func(ctx: Dictionary):
			for u in ctx["combat"].party:
				if u.hp > 0:
					u.status["regen"] = maxi(int(u.status.get("regen", 0)), 2)
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
			if t != null and t.side == "e" and t.hp > 0 and float(t.hp) <= float(t.max_hp) * 0.15:
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
			if float(t.hp) < float(t.max_hp) * 0.5 and not bool(t.custom_state.get("spiraled", false)):
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
	"r_keeneye": {
		# Pity crit: if NOBODY rolled a crit this turn, the first Axie holding an unused damage
		# face crits instead. The pity flag is cleared for everyone first, so last turn's pity
		# never carries. The +4 crit damage half is the `critBonus` data field.
		"on_roll_end": func(ctx: Dictionary):
			var combat = ctx["combat"]
			var p: Array = combat.alive_party()
			for u in p:
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
	"r_dawnlance": {
		# JS: ctx.tgt.side==='e' && ctx.tgt.hp > ctx.tgt.maxHp*0.5 ? ceil(v*1.9) : v
		"mod_dmg": func(ctx: Dictionary):
			var tgt: Unit = ctx["tgt"]
			var v: float = float(ctx["value"])
			if tgt.side == "e" and float(tgt.hp) > float(tgt.max_hp) * 0.5:
				return ceil(v * 1.9)
			return v,
	},

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
	var v = value
	for def in _owned_defs(combat):
		var hk: String = def.hook_key if "hook_key" in def else ""
		if hk == "":
			continue
		ctx["value"] = v
		if TABLE.has(hk) and (TABLE[hk] as Dictionary).has(event):
			v = (TABLE[hk] as Dictionary)[event].call(ctx)
	return v

## Fires every owned relic's hook for `event`, ignoring return values (pure side-effect
## hooks: onHit/onKill/onShield/onThorns/onDmgTaken/onTurnStart/onRollEnd). No-op today.
static func fire(combat, event: String, ctx) -> void:
	for def in _owned_defs(combat):
		var hk: String = def.hook_key if "hook_key" in def else ""
		if hk == "":
			continue
		if TABLE.has(hk) and (TABLE[hk] as Dictionary).has(event):
			(TABLE[hk] as Dictionary)[event].call(ctx)

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
