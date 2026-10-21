extends Node
## Global signal bus. Holds no state — every gameplay signal fired here must correspond
## to an actual state change in RunState/CombatEngine. See design/gdd/godot-port-rule-spec.md
## §10 for the JS s.ev event list this maps to, and the architecture plan §4/§5 for the
## "no silent state change" discipline this bus exists to enforce.

# --- Combat gameplay events (map 1:1 to the old s.ev types — do not drop any of these) ---
signal hp_changed(uid: int, hp: int, max_hp: int, shield: int)              # ~ "hp"
signal hit_landed(src_uid: int, uid: int, value: int, crit: bool)           # ~ "hit"
signal unit_died(uid: int)                                                 # ~ "death"
signal face_used(uid: int, side: String, target_uid: int, aoe: bool,
		face_part: String, face_name: String, face_type: String)              # ~ "use"
signal resonance_triggered(uid: int)                                       # ~ "resonance"
signal relic_pulsed(relic_id: String, uid: int)                            # ~ "relic" —
		# the ONLY channel some relic effects have to become visible; never skip this.
signal anchor_chosen(anchor_id: String)                                       # Anchor locked for the run (before the first Core offer)
signal anchor_awakened(anchor_id: String)                                    # first time >= 2 house Cores are owned; never repeats in a run
signal mutation_on(house_id: String, tier: int)                               # Anchor: a house mutation changed tier (0 -> 1, 1 -> 2) after a Core pick
signal combo_formed(combo_id: String, tier: String)                         # gacha: a Core pick raised a combo to "pair" | "full"
signal combo_fired(combo_id: String)                                       # gacha: first time this fight both Cores of a Pair fired in one turn
signal core_fired(core_id: String, unit_uid: int, amount: int, kind: String)  # depth v3 lane VZ: a Core DID something
		# (see production/depth-v3-contract.md "Làn VZ"). Cores never use relic_pulsed: its two-arg signature has no amount/kind.
		# kind: dmg | shield | block | mana | poison | heal | reroll | thorns | quest_step ("" = unknown, UI shows the name only).
		# Pure presentation + run stat; emit it from the engine AFTER the effect resolved, never to cause one.
signal float_text(uid: int, text: String, css_class: String, big: int)     # ~ "ft"
signal die_overcast(uid: int, before: int, after: int)                 # Overcast: mana paid, die powered up
signal die_wild(uid: int, slot: int)                                     # Mat Tam: mana paid, die counts as part `slot` for Sets
signal bo_changed(groups: Array)                                       # depth v4 BO: the Set snapshot changed ([{part,size,uids,hi,m100}], [] = no Set)
signal die_stashed(uid: int)                                              # depth v3 Hold: a die was parked
signal plating(uid: int, before: int, after: int, p: int)                  # depth v3 6.7 M1/M6: a single-target hit was reduced by Plating
signal plating_off(uid: int, turns: int)                                  # a debuff / poison switched the Plating off for `turns` player turns
signal plating_decay(uid: int, p_now: int)                                # anti-stall: Plating wears down from `plating.decay_turn`
signal ward(src_uid: int, tgt_uid: int, amount: int)                      # M2: a ward source shielded an ally
signal mend(src_uid: int, tgt_uid: int, amount: int)                      # M4: a mend source healed an ally
signal spite(src_uid: int, tgt_uid: int, dmg: int, hits: int)             # M3: the enemy hurt the Axie that landed its 3rd+ hit
signal charge_start(uid: int, target_uid: int)                            # M5: public tell, charge turn (boss: the prep turn before the strike)
signal charge_hit(uid: int, target_uid: int, value: int)                  # M5: the x2.5 strike lands
signal charge_break(uid: int)                                             # M5: stun / freeze interrupted the charge
signal unit_spawned(uid: int)                                              # (no JS analogue)
		# A unit JOINED a fight already in progress — gooey_king's SPLIT, a summoner's adds, an
		# Axie Egg from a face/card/relic. JS has no such event because its view re-renders the
		# whole board from state on every change; this port keeps a persistent node per unit, so
		# a newcomer needs someone to build its nameplate, head HUD and 3D slot.
		#
		# It is a PROMPTNESS signal, not the source of truth. CombatView reconciles the full
		# roster on every rebuild anyway, because the bug this fixes was precisely "a spawn site
		# nobody told the view about" — a fix that depends on remembering to announce would
		# reproduce it the first time a sixth spawn site is added.
signal boss_phase_changed(uid: int)                                        # ~ "phase"
signal enemy_intent_executed(uid: int)                                     # ~ "eact"
signal status_tick(statuses: PackedStringArray)                             # ~ "tick"
		# Carries the effects that ACTUALLY resolved this tick (deduplicated), not everything
		# the units are carrying — a poison stack that dealt no damage is not in the list.
		# The payload exists so presentation can tell burn from poison from regen: the tick
		# fires once, at the end, and without it a listener knows only that "something ticked".

# --- Navigation / run-level signals (NOT gameplay juice — scene routing only) ---
signal phase_changed(old_phase: int, new_phase: int)
signal node_entered(node_type: String, node_id: String)
signal combat_finished(won: bool)
signal run_ended(won: bool)
## Presentation only (L1 contract 3.2): nothing in the rules listens to these.
signal combat_clock_changed(state: Dictionary)
signal combat_attrition_changed(state: Dictionary)
signal party_revived(uids: Array, heal_pct: int)
signal boss_spike_warned(uid: int, turns: int)

# --- Combat-internal turn FSM (added for CombatEngine, checklist step 4) ---
# Deliberately separate from `phase_changed` above: that signal's ints are
# RunState.RunPhase values (MENU/MAP/EVENT/.../COMBAT/...) for scene-level routing.
# CombatEngine.CombatPhase (ROLL/REROLL/EXECUTE/END_TURN) is a different, turn-scoped
# enum that only makes sense while already inside COMBAT — reusing phase_changed would
# force every listener to disambiguate "which enum is this int" at the call site.
signal turn_phase_changed(old_phase: int, new_phase: int)
