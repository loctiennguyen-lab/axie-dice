class_name DamagePipeline
extends RefCounted
## Direct port of engine.js dealDamage() — see design/gdd/godot-port-rule-spec.md §3 for the
## authoritative 13-step order (source side 1-5, target side 6-13). This order is
## load-bearing: reordering it changes balance in ways that were already verified twice
## against engine.js, so any change here needs a rule-spec update first, not just a code review.
##
## `resolve(ctx)` takes a plain Dictionary rather than a typed Resource/class: the pipeline
## has ~10 optional flags (pierce/crit/exec/attack/resonant/pity_crit/...) that mirror JS's
## loose `o` options object, and a Dictionary keeps call sites (CombatEngine.do_face,
## StatusEngine.tick_status) simple. `ctx.combat` (the owning CombatEngine) is required for
## relic aggregate lookups (RelicHooks.sum/has/max_val) and s.stat bookkeeping.
##
## Sentinel: src_uid 0 in emitted signals means "no source" (JS src=null, e.g. poison/burn
## ticks, thorns' own reflect-back damage's `src=null` case never happens but tick damage
## does). uid 0 is never assigned to a real unit — persistent roster ids start at 1
## (RunState._next_persistent_id) and in-combat token ids start at TOKEN_UID_BASE (see
## combat_engine.gd) — so this sentinel can never collide with a real target/source.
const NO_SOURCE_UID := 0

## ctx keys: combat, src (Unit|null), tgt (Unit), value (int), pierce (bool), crit (bool),
## exec (bool), attack (bool), resonant (bool), face_type (String), pity_crit (bool).
## Returns the HP actually removed (== JS `dealt`).
static func resolve(ctx: Dictionary) -> int:
	var combat = ctx["combat"]
	var src: Unit = ctx.get("src", null)
	var tgt: Unit = ctx["tgt"]
	var v: float = float(ctx.get("value", 0))
	var pierce: bool = bool(ctx.get("pierce", false))
	var crit: bool = bool(ctx.get("crit", false))
	var is_exec: bool = bool(ctx.get("exec", false))
	var attack: bool = bool(ctx.get("attack", false))
	var resonant: bool = bool(ctx.get("resonant", false))
	# JS reads `src.pityCrit` — a flag the r_keeneye relic sets on ONE unit in its onRollEnd
	# (src/data.js:615-618), not something the caller passes in. Reading it only from ctx (as
	# this did) meant critFlatPity could never fire, because no call site ever set that key.
	# Honour both: the unit's own flag is authoritative, ctx stays as an explicit override.
	var pity_crit: bool = bool(ctx.get("pity_crit", false)) \
		or (src != null and bool(src.custom_state.get("pity_crit", false)))

	if tgt.hp <= 0 or v <= 0:
		return 0

	# ---- source side (steps 1-5) — only when the attacker is a player-side unit ----
	if src != null and src.side == "p":
		var low_hp := tgt.hp < tgt.max_hp * 0.5
		if low_hp and (src.cls == "beast" or is_exec):
			v = ceil(v * 1.6)                                                    # 1. EXECUTE
		if pierce:
			v += (3.0 if src.cls == "bird" else 0.0) + RelicHooks.sum(combat, "piercePlus")  # 2. PIERCE
		var dm := RelicHooks.mul(combat, "dmgMult", 1.0)
		if dm != 1.0:
			v = ceil(v * dm)                                                     # 3. dmgMult
		v = float(RelicHooks.run_value_hook(combat, "mod_dmg", {"src": src, "tgt": tgt, "combat": combat}, v))  # 4. modDmg
		if crit:                                                                 # 5. CRIT
			v *= RelicHooks.max_val(combat, "critMult", 2.0)
			var cf := RelicHooks.sum(combat, "critFlat")
			if pity_crit:
				cf += RelicHooks.sum(combat, "critFlatPity")
			if cf != 0.0:
				v += cf
				EventBus.relic_pulsed.emit("critFlat", tgt.uid)
			if RelicHooks.has(combat, "critPierce"):
				pierce = true
				EventBus.relic_pulsed.emit("critPierce", tgt.uid)

	# ---- target side (steps 6-13) — always ----
	if tgt.status.get("vulnerable", 0) > 0:
		v = ceil(v * 1.5)                                                        # 6. vulnerable
	if tgt.side == "p":
		var dr := RelicHooks.sum(combat, "dr")
		if dr > 0.0:
			v = max(1.0, ceil(v * (1.0 - dr)))                                   # 7. damage reduction
	var iv := int(v)
	var dealt := 0
	EventBus.hit_landed.emit(src.uid if src != null else NO_SOURCE_UID, tgt.uid, iv, crit)

	if not pierce and tgt.shield > 0:                                            # 8. shield absorbs first
		var ab: int = min(tgt.shield, iv)
		tgt.shield -= ab
		iv -= ab
		if ab > 0:
			EventBus.float_text.emit(tgt.uid, "-%d" % ab, "shd", 0)

	var hp_before_hit := tgt.hp   # pre-clamp remaining HP, for the RunStats accumulator below
	if iv > 0:                                                                   # 9. subtract HP
		tgt.hp -= iv
		dealt = iv
		var label := ("CRIT " if crit else "") + ("LINK " if resonant else "") + "-%d" % iv
		EventBus.float_text.emit(tgt.uid, label, "dmg", 2 if crit else (1 if iv >= 25 else 0))
	if tgt.hp <= 0 and tgt.status.get("undying", 0):
		tgt.status["undying"] = 0
		tgt.hp = 1
		EventBus.float_text.emit(tgt.uid, "UNDYING", "buf", 0)
	if tgt.hp < 0:
		tgt.hp = 0
	EventBus.hp_changed.emit(tgt.uid, tgt.hp, tgt.max_hp, tgt.shield)
	if tgt.hp <= 0:
		EventBus.unit_died.emit(tgt.uid)

	if src != null and src.side == "p":
		combat.stat["dmg"] = int(combat.stat.get("dmg", 0)) + dealt
		if dealt > int(combat.stat.get("max_hit", 0)):
			combat.stat["max_hit"] = dealt
	if tgt.side == "p":
		combat.stat["taken"] = int(combat.stat.get("taken", 0)) + dealt

	# RunStats accumulator (design-handoff-v2 §09, "damage_dealt"). Deliberately a separate
	# key from "dmg" above, not a fix to it: "dmg" feeds nothing rule-facing either, but
	# changing what it counts mid-project felt riskier than adding a second counter, and
	# `dealt` itself (which DOES feed relic hooks, e.g. an on_hit "dealt >= 4" check) is never
	# touched here. Two differences from "dmg": (1) clamped to the HP that actually existed
	# before this hit, so an overkill of 40 into a 6 HP enemy contributes 6, matching what a
	# player watching the HP bar actually saw; (2) counted when src == null too — a poison/burn
	# tick (StatusEngine.tick_status calls resolve() with src == null) landing on an enemy is
	# still damage the player's own status effect caused, and the `src != null` guard above
	# silently dropped all of it.
	if (src != null and src.side == "p") or (src == null and tgt.side == "e"):
		var clamped_hit := mini(dealt, maxi(hp_before_hit, 0))
		if clamped_hit > 0:
			combat.stat["dmg_dealt_clamped"] = int(combat.stat.get("dmg_dealt_clamped", 0)) + clamped_hit

	if tgt.side == "p":                                                          # 10. onDmgTaken hook
		RelicHooks.fire(combat, "on_dmg_taken", {"src": src, "tgt": tgt, "dealt": dealt, "attack": attack, "combat": combat})

	# 11. THORNS — pierce+piercePlus relic bypasses it entirely
	var skip_thorns := pierce and RelicHooks.has(combat, "piercePlus")
	if src != null and attack and not skip_thorns and int(tgt.status.get("thorns", 0)) > 0 and src.hp > 0 and src != tgt:
		var th := float(tgt.status.get("thorns", 0))
		if tgt.side == "p":
			var tm := RelicHooks.max_val(combat, "thornsMult", 1.0)
			var tp := RelicHooks.sum(combat, "thornsPlus")
			th = th * tm + tp
			if tm != 1.0 or tp != 0.0:
				EventBus.relic_pulsed.emit("thorns", tgt.uid)
		var ith := int(th)
		EventBus.hit_landed.emit(tgt.uid, src.uid, ith, false)
		var src_hp_before_thorns := src.hp
		src.hp -= ith
		EventBus.float_text.emit(src.uid, "-%d" % ith, "dmg", 0)
		# RunStats accumulator, same "damage_dealt" counter as above: thorns is a party unit's
		# OWN status reflecting damage onto whatever attacked it, so it counts as player-dealt
		# damage exactly when the thorns belongs to a party member (tgt.side == "p") — the
		# gate is unambiguous here because thorns damage only ever lands on `src`, the attacker,
		# never on a bystander. Deliberately excluded from "max_hit"/biggest_hit (spec §09):
		# nothing below touches combat.stat["max_hit"], matching the rule that biggest_hit is
		# one die resolution against one target, not a reflected tick.
		if tgt.side == "p":
			var clamped_thorns := mini(ith, maxi(src_hp_before_thorns, 0))
			if clamped_thorns > 0:
				combat.stat["dmg_dealt_clamped"] = int(combat.stat.get("dmg_dealt_clamped", 0)) + clamped_thorns
		if tgt.side == "p" and tgt.cls == "reptile":
			StatusEngine.add_status(combat, src, ["poison:1"], tgt)
		if src.hp <= 0 and src.status.get("undying", 0):
			src.status["undying"] = 0
			src.hp = 1
		if src.hp < 0:
			src.hp = 0
		EventBus.hp_changed.emit(src.uid, src.hp, src.max_hp, src.shield)
		if src.hp <= 0:
			EventBus.unit_died.emit(src.uid)
			if src.side == "e":
				on_enemy_death(combat, src)
		if tgt.side == "p":                                                      # onThorns hook
			RelicHooks.fire(combat, "on_thorns", {"src": src, "tgt": tgt, "th": ith, "combat": combat})

	if src != null and src.side == "p" and dealt > 0:                            # 12. onHit hook
		RelicHooks.fire(combat, "on_hit", {
			"type": ctx.get("face_type", "dmg"), "dealt": dealt, "tgt": tgt, "crit": crit, "src": src, "combat": combat,
		})

	if tgt.side == "e" and tgt.hp <= 0:                                          # 13. death checks
		on_enemy_death(combat, tgt)
	if tgt.is_boss:
		check_boss_phase(combat, tgt)
	return dealt


static func apply_heal(combat, tgt: Unit, value: int) -> void:
	if tgt.hp <= 0 or value <= 0:
		return
	var before := tgt.hp
	tgt.hp = min(tgt.max_hp, tgt.hp + value)
	if tgt.hp > before:
		EventBus.float_text.emit(tgt.uid, "+%d" % (tgt.hp - before), "heal", 0)
	EventBus.hp_changed.emit(tgt.uid, tgt.hp, tgt.max_hp, tgt.shield)
	if tgt.side == "p" and RelicHooks.has(combat, "healShield"):
		apply_shield(combat, tgt, value)


static func apply_shield(combat, tgt: Unit, value: int) -> void:
	if tgt.hp <= 0 or value <= 0:
		return
	var v := value
	if tgt.side == "p" and tgt.cls == "plant":
		v += 2                                                                   # BULWARK passive
	var no_cap: bool = tgt.side == "p" and RelicHooks.has(combat, "noShieldCap")
	var cap: int = 999999 if no_cap else tgt.max_hp * 2
	if no_cap and tgt.shield + v > tgt.max_hp * 2:
		EventBus.relic_pulsed.emit("noShieldCap", tgt.uid)
	tgt.shield = min(cap, tgt.shield + v)
	EventBus.float_text.emit(tgt.uid, "+%d" % v, "shd", 0)
	EventBus.hp_changed.emit(tgt.uid, tgt.hp, tgt.max_hp, tgt.shield)
	if tgt.side == "p" and tgt.cls == "plant" and tgt.shield >= 10:
		tgt.status["thorns"] = min(StatusEngine.THORNS_CAP, max(int(tgt.status.get("thorns", 0)), 2))
	if tgt.side == "p":
		RelicHooks.fire(combat, "on_shield", {"v": v, "tgt": tgt, "combat": combat})


static func on_enemy_death(combat, e: Unit) -> void:
	if e._dead:
		return
	e._dead = true
	combat.stat["kills"] = int(combat.stat.get("kills", 0)) + 1
	RelicHooks.fire(combat, "on_kill", {"tgt": e, "combat": combat})


## Boss on-damage traits (engine.js checkBossPhase, engine.js:877-888). Called for every
## `is_boss` target after damage resolves. Two traits live here because both react to the
## boss's CURRENT HP rather than to the turn clock: `phase` (agony) and `split` (gooey_king).
## The turn-clock traits (thorns/OVERDRIVE, summon, freeze, mirror) are in
## CombatEngine._boss_turn_traits() instead.
static func check_boss_phase(combat, b: Unit) -> void:
	var boss_trait := String(b.custom_state.get("trait", ""))

	# --- NIGHTMARE AGONY: heals to full and swaps to a deadlier die, once. ---
	# KEY MISMATCH FIXED: ContentDB.boss_stats() writes `max_hp2`/`die2`, while this read
	# `hp2` — so agony's second phase could never have fired in a real run even once bosses
	# started spawning. Both spellings are accepted now; `max_hp2` is the canonical one.
	var hp2_key := "max_hp2" if b.custom_state.has("max_hp2") else "hp2"
	if boss_trait == "phase" and int(b.custom_state.get("phase", 1)) == 1 \
			and b.hp <= 0 and b.custom_state.has(hp2_key):
		b.custom_state["phase"] = 2
		b.max_hp = int(b.custom_state[hp2_key])
		b.hp = b.max_hp
		b.die = (b.custom_state.get("die2", []) as Array).duplicate(true)
		b.shield = 0
		b.status = {}
		b._dead = false
		EventBus.float_text.emit(b.uid, "PHASE 2", "deb", 2)
		EventBus.boss_phase_changed.emit(b.uid)
		EventBus.hp_changed.emit(b.uid, b.hp, b.max_hp, b.shield)

	# --- GOOEY KING: SPLIT. Spawns an add as it crosses 2/3 and again at 1/3 HP.
	# JS (engine.js:882-887) recomputes how many adds SHOULD exist from the current HP
	# fraction and tops up, rather than firing on the crossing itself — so one huge hit that
	# jumps straight past both thresholds still spawns both adds. Ported as-is.
	if boss_trait == "split" and b.hp > 0:
		var fraction: float = float(b.hp) / max(1.0, float(b.max_hp))
		var want: int = 2 if fraction <= 0.34 else (1 if fraction <= 0.67 else 0)
		var add_cap := int(b.custom_state.get("add_cap", 0))
		while int(b.custom_state.get("split_done", 0)) < want \
				and int(b.custom_state.get("split_done", 0)) < add_cap:
			b.custom_state["split_done"] = int(b.custom_state.get("split_done", 0)) + 1
			combat.spawn_boss_add(b, float(b.custom_state.get("sc", 1.0)) * 1.6)
