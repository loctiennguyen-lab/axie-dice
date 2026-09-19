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
signal float_text(uid: int, text: String, css_class: String, big: int)     # ~ "ft"
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

# --- Combat-internal turn FSM (added for CombatEngine, checklist step 4) ---
# Deliberately separate from `phase_changed` above: that signal's ints are
# RunState.RunPhase values (MENU/MAP/EVENT/.../COMBAT/...) for scene-level routing.
# CombatEngine.CombatPhase (ROLL/REROLL/EXECUTE/END_TURN) is a different, turn-scoped
# enum that only makes sense while already inside COMBAT — reusing phase_changed would
# force every listener to disambiguate "which enum is this int" at the call site.
signal turn_phase_changed(old_phase: int, new_phase: int)
