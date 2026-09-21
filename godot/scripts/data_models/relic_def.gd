class_name RelicDef
extends Resource
## Static relic definition (architecture plan §6 "Luật cứng cho MỌI data model dạng
## Resource" — Resources are cached per-path by ResourceLoader, so they must stay
## data-only/read-only; runtime state never lives here). Ported from src/data.js RELICS[]
## entries — see design/gdd/godot-port-rule-spec.md §5 for the hook API this mirrors.
##
## Logic that is more than a pure aggregate number/flag lives in
## scripts/core/relic_hooks.gd's TABLE, looked up by `hook_key` — never a Callable stored
## directly on this Resource (plan §6: a Callable field here would be shared mutable state
## across every run in the same process, and breaks under script hot-reload).
##
## Aggregate fields below (piercePlus..growthPlus) are read by RelicHooks.sum/has/max_val/mul
## (scripts/core/relic_hooks.gd) via `field in def and def.get(field)` — field NAMES must
## match the exact string literals used at each call site in damage_pipeline.gd/
## combat_engine.gd/status_engine.gd. Defaults are each field's "not present" identity value
## (0.0 for sum/max_val fields, false for has() fields) so a .tres only needs to set the 1-3
## fields its own relic actually uses — same sparse shape as the JS RELICS[] object it was
## ported from.

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""    ## src/data.js RELICS[].d, verbatim — the sentence the
                                        ## player reads on a reward card, in the shop, and on
                                        ## the run's relic list. It lives HERE rather than in a
                                        ## lookup table beside the reward code because the two
                                        ## drift: a relic added without its line renders as a
                                        ## name with no rule, which reads as a relic that does
                                        ## nothing rather than as missing text. Keeping them in
                                        ## one file makes "added the relic, forgot the words"
                                        ## impossible instead of merely unlikely.
@export var rarity: int = 0            ## 0 Common .. 3 Legendary. No rarity-4 (Mythic)
                                        ## PASSIVE relic exists in src/data.js RELICS today —
                                        ## Mythic only appears on hero/mutation FACES (rule
                                        ## spec §11), not on this list. Not a porting omission.
@export var archetype: String = ""     ## rule spec §11 ARCH key (poison/burn/shield/mana/
                                        ## pierce/crit/growth/summon/aoe/thorns/exec) — tracker
                                        ## UI only, no gameplay call site reads this yet.
@export var mload: int = 0             ## RELIC_MLOAD_CAP bookkeeping (reward/shop offer
                                        ## system — not built this slice) — carried for
                                        ## forward-compat, matches src/data.js `mload` 1:1.
@export var sort_index: int = 0        ## Architecture plan §6 / INV-5 — explicit, NEVER
                                        ## derived from directory scan order. Composed as
                                        ## phase*100000 + rarity*1000 + RELIC_INDEX (original
                                        ## src/data.js RELICS[] array position) — see the
                                        ## comment above RelicHooks.TABLE for why phase is
                                        ## always 1 ("add") for every relic shipped so far
                                        ## (none of them define modFace/mfPhase yet).
@export var hook_key: String = ""      ## Key into RelicHooks.TABLE. "" = pure-data relic
                                        ## with no custom event logic — still fully
                                        ## functional via the aggregate fields below.
@export var act_cost: int = 0          ## 0 = passive. >0 = Lunacia active card, playable in
                                        ## combat for Mana via CombatEngine.play_active().

## The active card's effect, mirroring src/engine.js's `act:{...}` object (engine.js:810-874).
## Kept as a Dictionary rather than a dozen @export fields because the shape genuinely varies
## per `kind`, and because engine.js reads every option out of DATA — a hardcoded assumption
## here is exactly how ENG-14 happened in the JS original (the dmg branch ignored the card's
## own `crit`/`exec` flags, so a card that declared crit could never crit).
##
## Recognised keys, by `kind`:
##   heal        {v}                       — heal one ally
##   dmg         {v, pierce?, crit?, exec?} — damage one enemy
##   ult         {v, crit?}                — pierce damage to one enemy + 10 shield to all allies
##   shieldall   {v}                       — shield every living ally
##   dmgall      {v}                       — damage every living enemy
##   poisonall   {v}                       — poison every living enemy
##   stun        {}                        — stun one enemy
##   reroll      {v}                       — +v reroll charges this turn
##   kw          {kw, scope, mode}         — apply a keyword/status; scope "allEnemies"|allies,
##                                           mode "min" (raise to a floor, idempotent) or "add"
##   grow        {v}                       — +v permanent growth on each ally's ROLLED face
##   summon      {v}                       — summon v Axie Eggs, respecting tokenCap
##   shatter     {min}                     — strip the target's shield, deal that much (min `min`)
@export var act: Dictionary = {}

# ---------------------------------------------------------------------------
# Aggregate fields — mirror src/engine.js rsum/rhas/rmax/rmul_(s,k). Field names are the
# contract; do not rename without updating every call site that passes the matching string.
# ---------------------------------------------------------------------------
@export_group("Aggregate fields (sum/has/max_val/mul)")
@export var piercePlus: float = 0.0
@export var dmgMult: float = 0.0
@export var critMult: float = 0.0
@export var critFlat: float = 0.0
@export var critFlatPity: float = 0.0
@export var critPierce: bool = false
@export var critBonus: float = 0.0
@export var dr: float = 0.0
@export var thornsMult: float = 0.0
@export var thornsPlus: float = 0.0
@export var noShieldCap: bool = false
@export var healShield: bool = false
@export var rerollUp: float = 0.0
@export var hiveMind: float = 0.0
@export var tokenCap: float = 0.0
@export var cleaveRatio: float = 0.0
@export var manaOverflow: bool = false
@export var poisonTicks: float = 0.0
@export var plague: bool = false
@export var burnMult: float = 0.0
@export var burnTicks: float = 0.0
@export var burnTickRatio: float = 0.0
@export var burnSlow: bool = false
@export var burnSpread: bool = false
@export var poisonSpread: bool = false
@export var growthPlus: float = 0.0

## --- Fields the engine reads but that had no home here until the Phase-1 parity pass.
## Each one corresponds to a real src/engine.js behaviour that was silently unreachable
## because the field did not exist to be summed/tested: a relic could declare it in JS and
## the Godot port would read a constant default and never know the difference.
@export var growthAll: float = 0.0     ## engine.js:929-938 — grow EVERY face each turn
                                        ## (EVOLVE archetype's only real payoff).
@export var startSummon: float = 0.0   ## engine.js:416-418 — allies spawned at combat start.
@export var safeReroll: bool = false   ## engine.js:502 — reroll no longer wipes the undo stack.
@export var critKeep: bool = false     ## engine.js:496-500 — a rolled crit survives a reroll.
@export var growthKeep: bool = false   ## engine.js:986-994 — carry half the run's face growth
                                        ## between combats, capped by GROWTH_KEEP_CAP.
@export var firstEcho: bool = false    ## engine.js:716 — the first face used each turn fires twice.
@export var eggInherit: bool = false   ## engine.js:435-440 — tokens run the modFace pass too.
@export var actReuse: float = 0.0      ## engine.js:810-874 — how many times one active card
                                        ## may be replayed in a single turn.

## --- Build-time die mutation (modFace), INV-5 ordering ---
## A relic may declare up to TWO die-mutation entries, in different phases. The phase, NOT
## the pickup order, decides when it runs: every keyword-adding relic runs before every
## flat-adder, which runs before every multiplier. Without this, r_claw(+1) plus
## r_ancientgene(x1.3) yields (v+1)*1.3 or v*1.3+1 depending purely on which the player
## happened to pick up first — so a relic's power would be a RANGE rather than a number,
## which breaks INV-1 (see the long comment at src/engine.js:36-47).
@export_enum("kw", "add", "mul") var mf_phase: String = "add"
@export_enum("kw", "add", "mul") var mf_phase2: String = "add"


## --- What an active card needs the player to click, before it can be played ---
##
## "none" plays on the spot. "ally" and "enemy" need a unit picked first, and the engine
## REFUSES a wrong one (CombatEngine.play_active() checks `tgt.side` per kind and returns
## false without spending mana), so this table only has to agree with the engine to keep the
## UI from offering a click that cannot work — it is not the authority on legality.
##
## Read off combat_engine.gd's own `match String(a.get("kind", ""))`, kind by kind:
##   heal                                  -> tgt.side must be "p"
##   dmg / ult / stun / shatter            -> tgt.side must be "e"
##   shieldall / dmgall / poisonall /
##   reroll / kw / grow / summon           -> never reads `tgt`
##
## It lives HERE and not in combat_engine.gd on purpose: `res://scripts/core` is inside
## t_rules_version's fingerprint, and adding a UI-facing helper there would trip the rules
## gate over a change that alters no rule. `scripts/data_models` is outside it.
const _ACT_TARGET := {
	"heal": "ally",
	"dmg": "enemy", "ult": "enemy", "stun": "enemy", "shatter": "enemy",
}


## "none" | "ally" | "enemy". A passive, or an active with no `act` block, answers "none".
func act_target() -> String:
	if act_cost <= 0 or act.is_empty():
		return "none"
	return String(_ACT_TARGET.get(String(act.get("kind", "")), "none"))
