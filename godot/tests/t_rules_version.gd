extends Node
## Guards the one constant a human has to remember, by refusing to let them forget it.
##
## `ActionLog.RULES_VERSION` tells a verifier which rules a run was played under. A log written
## under different rules is unreadable, not suspicious, and the verifier answers accordingly —
## but only if the constant actually changed when the rules did. A hand-typed version that
## nobody bumps is worse than none: every old log then claims to be current, and the referee
## replays them against rules they were never played under, calling honest players cheats.
##
## So this gate fingerprints the files that decide outcomes and fails when the fingerprint
## moves. A machine cannot tell a rewritten comment from a rewritten formula, and pretending
## otherwise would be the same false confidence — so the failure message asks the human the one
## question only they can answer, and the answer is cheap either way.

## Everything whose content can change what a replay produces: the rules themselves, and the
## balance table they read. NOT the UI, not the scenes — a screen cannot change an outcome, and
## including them would make this gate cry wolf every time a button moved.
## L1 (2026-10-12): the relic set is data now (`resources/relics/*.tres`, incl. `relic_tuning.tres`)
## and the rules JSON lane A/E add lives under `assets/data/rules/`. Every dir is walked
## recursively for .gd / .tres / .json (never .uid / .import: Godot bookkeeping).
const WATCHED_DIRS: Array[String] = ["res://scripts/core", "res://autoload",
	"res://resources/relics", "res://assets/data/rules", "res://scripts/meta"]
const WATCHED_EXTS: Array[String] = [".gd", ".tres", ".json"]
const WATCHED_FILES: Array[String] = ["res://assets/data/part_faces.json"]

## Recorded when RULES_VERSION was last considered. Update it in the same commit that changes
## anything above — and bump RULES_VERSION too if the change can alter an outcome.
##
## Moved 2026-09-20 by the RunStats accumulator (design-handoff-v2 §09, Result screen v2):
## a new autoload (`RunStatsAccumulator.gd`) joined `res://autoload`, and `damage_pipeline.gd`
## gained a second, purely-additive stat key ("dmg_dealt_clamped") written alongside the
## existing "dmg"/"taken"/"turns"/"kills"/"max_hit" — plus matching default-dict/fold-loop
## entries in `combat_engine.gd` and `RunState.gd`. RULES_VERSION was NOT bumped — every new
## line only READS already-computed values (`dealt`, `iv`, `ith`, `hp_before_*`) into a
## Dictionary key that nothing branches on; `dealt`/`iv`/`ith` themselves, and every value
## passed to a relic hook, are byte-for-byte unchanged. `t_run_stats_accumulator.gd` (new)
## exercises the two rules this key exists for directly against DamagePipeline.resolve();
## `t_replay` still verifies a full run to the same score.
##
## Last moved 2026-09-20 by SaveStore: MetaState and RunState now persist through it instead
## of FileAccess, because `user://` does not survive a page reload in a web build. RULES_VERSION
## was NOT bumped — where a save is written cannot change what a run does, and `t_replay` still
## verifies a full run to the same score.
##
## Moved before that, same day, by the end-screen work: `CombatEngine.get_result()` now carries the
## fight's `stat` counters, `RunState.run_stats` totals them, `MetaState.reduce_flash` arrived,
## and two pieces of ContentDB display copy stopped saying "waves". RULES_VERSION was NOT
## bumped — none of it can change what a run does. The counters are written and never read by
## a rule; `reduce_flash` is a visual setting; and the unlock text is display only, keyed by
## `id`. `t_replay` re-verifies a full run after every one of these, and still agrees.
##
## Moved before that, 2026-09-19, by `MetaState.tutorial_seen` + `needs_tutorial()`. RULES_VERSION was
## NOT bumped, and the reason is the whole point of asking: that flag decides whether a player
## is shown the tutorial. It cannot change what a run does, because a ranked run reads
## `MetaState.run_bonuses(true)`, which returns zeroes for everything the meta holds.
##
## Moved again, 2026-09-21, by `ContentDB.ARCH` gaining its eleventh entry (`exec`) plus the
## new `ARCH_PRIORITY` / `face_arch()` / `team_arch_score()` / `team_arch_top()` port. NOT
## bumped: ARCH is a tracker/display table. Nothing in `scripts/core` branches on membership in
## it — the only reader outside the UI is `reward_generator._relic_text()`, which falls back to
## "Archetype: <key>" when a relic has no description, and relic SELECTION never filters on it.
## The four new functions have no caller in the engine at all; Team Select reads them to draw
## the "THIS COMP LEANS" bar. Same actions, same run.
##
## BUMPED, 2026-09-21, by `MetaState._hero_def_from_vault()`. This one IS a rules change and
## `ActionLog.RULES_VERSION` moved to `godot-2026-09-21-a` with it. An imported Axie's die was
## stored under src/data.js's short field names (`p/t/v/k/r`) and handed to `ContentDB.heroes`
## untouched, while this port's engine reads the long names it gave the hand-written hero table
## (`part/type/value/keywords/rarity`). Every lookup missed, `Dictionary.get()` returned the
## default, and a vault Axie rolled six 0-value blank faces in real combat. It now rolls the die
## its own six body parts describe — the same actions produce a different run, which is the
## question this file exists to ask.
## Moved, 2026-09-21, by the end_turn() split: `combat_engine.gd` gained `can_end_turn()`,
## `begin_end_turn()`, `step_end_turn_action()` and `finish_end_turn()`, and `end_turn()` is now
## a wrapper that calls the three in order. RULES_VERSION was NOT bumped, and the answer to this
## file's one question was not taken on faith.
##
## The change exists so CombatView can put a gap between enemies and let each one's attack
## animation play; the engine gained no timing, no `await`, and no new state. The same actions
## produce the same run because the split preserves the two things that could have moved:
##   · the ENEMY LOOP body is the old one line for line, including where the party-wipe check
##     sits — only a real `_exec_face()` can end the phase early, and a skipped or stunned
##     enemy returns "keep going" exactly as the old `continue` did;
##   · the stepper takes an INDEX and the caller re-reads `enemies.size()` every pass, so an
##     enemy SUMMONED mid-phase still acts this turn. A list of uids captured up front would
##     have dropped it, and that WOULD have been a rules change — it is the trap this split was
##     most likely to fall into.
##
## `t_enemy_phase_pacing.gd` (new) is the evidence, not the assertion: it replays the pre-split
## begin-block and enemy loop, written out verbatim, against the split path on the same seed and
## compares `to_data()` turn by turn. Its own break-tests are recorded in that file. `t_replay`,
## `t_vertical_slice`, `t_full_run_loop` and `t_combat_roundtrip` all still agree as well.
##
## Moved, 2026-09-21, by the English/punctuation pass before the GitHub push. Six boss `desc`
## strings in `ContentDB.gd` and one sentence each in `reward_generator.gd`,
## `axie_gene_preview.gd` and `run_verifier.gd` lost an em dash; the boss descriptions also
## gained a full stop where the dash used to be. RULES_VERSION was NOT bumped. Every one of
## these is a string the player reads and nothing branches on: `desc` is drawn by the boss
## intro and the codex, `reward_generator`'s is the LEVEL UP card's subtitle (selection reads
## `key`/`tier`, never `desc`), `axie_gene_preview`'s is a Vault warning line, and
## `run_verifier`'s is the text of an already-decided ERR_NOT_RANKED failure. `t_replay` still
## verifies a full run to the same score.
## Moved, 2026-10-10, by accounts + cloud save (`b4f528f`): new autoload `AccountService.gd`,
## `SaveStore` gained per-account profiles, `MetaState` gained `reload_from_store()` and a comment
## edit. RULES_VERSION was NOT bumped (Liam, 10 Oct). None of it is read during a run: it decides
## WHICH save file meta progression lives in, never how a die, an enemy or a reward resolves.
## `t_replay` still verifies a full run to the same score.
## Moved again the same day: `AccountService.error_message()` gained a "rate_limited" line for the
## Worker's new sign-in rate limit. Player-facing text only; RULES_VERSION was NOT bumped.
## BUMPED, 2026-10-12 (L1 combat batch 1): `ActionLog.RULES_VERSION` -> `godot-2026-10-12-a`.
## Changes the run result: YES. Lane A's PR1 routes every rules draw through EpochSource (the seed
## of each draw now comes from the epoch, not the old stream) and lane B's relic set v2 (8/7 passive
## and 3/4 active slots, G/A multiplier slots, 45 new relics, 9 new + 5 reworked bodies, 6 merged away).
## The watch list now also covers resources/relics (*.tres incl. relic_tuning.tres) and
## assets/data/rules (*.json), recursively, so the relic set is fingerprinted from here on.
## Earlier today (88abaa4 B skeleton, d6e8f25 C MonsterArt.resolve) moved it with no behaviour change.
## BUMPED again, 2026-10-12: `ActionLog.RULES_VERSION` -> `godot-2026-10-12-b`. Lane E's merge
## (MetaState save v2 + migration, EconomyDB, GemWallet, Echo Box, MissionBoard) is wallet/UI-only
## EXCEPT `MetaState.run_bonuses(is_ranked)`: ranked runs used to get all zeroes, and now get the
## grind unlocks (B3, Liam 12/10). Same actions + seed in a ranked run now play out differently
## (starting bonuses are non-zero), so old ranked logs must not be replayed under the new rules.
## Changes the run result: YES. `scripts/meta` (Aid catalog, Echo Box...) joined the watch list.
## DEBT: the verifier must take the loadout from the log header; until then a ranked replay only
## matches on a machine with the same unlocks (see production/l1-tasks-I.md).
## Moved 2026-10-12 by lane E Store fixes (store_catalog/gem_wallet spend(save)): wallet + shop only,
## no run outcome change, so RULES_VERSION was NOT bumped.
## BUMPED again, 2026-10-12: `ActionLog.RULES_VERSION` -> `godot-2026-10-12-c`. Lane A PR2: Ascension v2
## rule tables (assets/data/rules/*.json, now fingerprinted), boss clock, attrition, spike, Continue (form B),
## Aid effects, Boons as numbers, relic hook points H1-H8 (inert until lane B fills them), set_epoch.
## Changes the run result: YES. `t_mon13` guards that no scripts/core rule reads Aid/Continue/Boon state.
## Moved 2026-10-12 by lane S (338d371): AccountService.gd (desktop login + Bearer, rate-limit messages)
## and scripts/net/ (RemoteGemWallet, run session plumbing). Accounts and network only; nothing here
## is read while a die, enemy or reward resolves, and the remote sources are not wired in yet
## (flag off). Changes the run result: NO, so RULES_VERSION was NOT bumped (still -c).
## Moved 2026-10-12 night by lane E merge (7f68d62 + 7ce7560): MetaState.gd (remote Gem wallet wiring,
## Pass v2 XP/claims). Meta progression only, read after a run ends. Changes the run result: NO.
## BUMPED, 2026-10-12 night: `ActionLog.RULES_VERSION` -> `godot-2026-10-12-d`. Lane B merge: EN names/descriptions,
## boss immune to instant kills, relic offer v2 (rarity by source, gating, exclusions, boss pact offer), bodies for
## 22 H1-H8 relics + 7 reworks, live pacts (twinfates/devilsreroll/tithepips), pipfile tweak cleared per roll.
## Changes the run result: YES.
## BUMPED, 2026-10-12 night: `ActionLog.RULES_VERSION` -> `godot-2026-10-12-e`. Lane A merge: mission rules
## (mission_rules.json, ContentDB.mission_mods), reroll hook veto checked before RNG/reroll_k/Mana, is_refresh fix,
## end_run -> record_run_outcome {mode, ascension, ranked, reached_boss}. Changes the run result: YES.
## Moved 2026-10-12 night by lane E (467a478): MetaState.gd Pass v2 weekly tasks. Meta only, after a run
## ends. Changes the run result: NO, RULES_VERSION stays -e.
## BUMPED, 2026-10-12 night: `ActionLog.RULES_VERSION` -> `godot-2026-10-12-f`. Lane B: G/A multiplier axes
## (G cap 2.5 per Axie damage face, ascend/forge no longer baked into faces, A axes for ticks/thorns/crit/opener),
## reroll caps (a_chaos 6, relic sources 4 per turn), Eternal sticker, RelicSlots.pact_forced, apexpredator no
## crit chance. Touches combat_engine.gd / RunState.gd / unit.gd minimally. Changes the run result: YES.
## Moved 2026-10-12 night by lane S merge: AccountService.gd (RemoteGemWallet on sign-in, behind the
## axie/gem_wallet flag, default local), scripts/net RunSession + RemoteEpochSource (flag axie/epoch_source,
## default local). Network/accounts only, flags off. Changes the run result: NO, RULES_VERSION stays -f.
## BUMPED, 2026-10-13: `ActionLog.RULES_VERSION` -> `godot-2026-10-13-g`. Lane B: 9 hidden relics live
## (ironvow, lonewolf, hollowchalice, alphafang, falconhood, heartrootgrove, shedskin, tidecaller, venomlineage),
## value hooks shield_value / reroll_allowed / active_cost / face_final / field, CombatEngine.active_cost.
## Changes the run result: YES.
## Moved 2026-10-13 by lane E (3a3764a..95f3304): MetaState mission stake escrow (nonce id via Crypto, not game
## RNG) + RunState.end_run settles the escrow before clearing the saved run. Meta only. Run result: NO, stays -g.
## BUMPED, 2026-10-13: `ActionLog.RULES_VERSION` -> `godot-2026-10-13-h`. Lane B 4d97af8: last 5 hidden relics
## live (assassinsneedle, breakersward, firestormveil, fumeblossom, sporegale); hooks face_crit, on_face_hit,
## on_status_tick, on_shield_break. No relic is hidden now. Changes the run result: YES.
## Moved 2026-10-13 by 1813525: RunState picks RemoteEpochSource only when axie/epoch_source == "remote"
## (default local, unchanged path), RunSession as a lazy child node. Run result: NO, stays -h.
## Moved 2026-10-13 by lane E (5eadce4..b2e12a9): MetaState daily Stone + week counter, Pass wrappers, Gem pack
## data, seasonal Echo Box state (disabled in data). Meta only. Run result: NO, stays -h.
## BUMPED, 2026-10-13: `ActionLog.RULES_VERSION` -> `godot-2026-10-13-i`. LocalEpochSource writes header.newcomer
## from run params (was always false), so local newcomer runs now get the designed softening (no attrition, no
## light boss clock, Aid hidden; monetization-v1 §1.6). Changes the run result: YES (newcomer runs only).
## BUMPED, 2026-10-13: `ActionLog.RULES_VERSION` -> `godot-2026-10-13-j`. Lane A (Liam H3/H4): mission rules M6
## normal_hp x1.20 (non-elite, non-boss) and M7 elite_dmg x1.25 (all elite die faces, like enemy_dmg), no 2-rule
## limit. Mission runs only. Changes the run result: YES.
## Moved 2026-10-13 by lane E e1bf15b (Liam H11): MetaState newcomer = runs_with_battle < newcomer_runs;
## RunState.apply_combat_result notes the run's first battle. Meta counter only. Run result: NO, stays -j.
## Moved 2026-10-13 by B3 f6a5203: AccountService desktop sign-in phase/error/reopen. Accounts only.
## Run result: NO, stays -j.
## Moved 2026-10-13 by B5 f88192a: RunState.begin_run refuses a disabled mission tier (early return, no RNG).
## Valid runs unchanged. Run result: NO, stays -j.
## Moved 2026-10-13 by B4 d4b3efb/0e48e63: RunState.close_summary() sent at run close (telemetry; never read
## by a rule; lane I merge fix: str() instead of String() on Variant fields). Run result: NO, stays -j.
## BUMPED, 2026-10-13: `ActionLog.RULES_VERSION` -> `godot-2026-10-13-k`. missions.json now matches the approved
## very-hard doc (rule sets A/B and multipliers N1–N6; L1 plays N1–N3). Changes the run result: YES (mission runs).
## Worker SUPPORTED_RULE_VERSIONS gained -k in the same commit.
## Moved 2026-10-13 by B10 1cf344d: MetaState.free_continue_used + RunState ctx flag (price of the newcomer's
## first Continue only; no combat rule reads it). Run result: NO, stays -k.
## 2026-10-13 (R-save): RunState.gd writes/checks rules_version in run_save (resume refused on mismatch). Changes the run result: NO, RULES_VERSION stays -k.
## Moved 2026-10-13 by B12 951fc80: MetaState equipped_die_skin / equipped_frame (cosmetic only; t_mon13 +
## scan confirm no rule reads them). Run result: NO, stays -k.
## BUMPED, 2026-10-13: `ActionLog.RULES_VERSION` -> `godot-2026-10-13-l`. C1: boss pact phase after non-final boss
## wins (pick_pact_offer, pact_pick logged; verifier enforces forced A6/A10 and blocks other actions while pending).
## Worker accepts -l and pact_pick. Changes the run result: YES.
## Moved 2026-10-14 by C7 titles bd8a2bf: MetaState grants Ascension titles in record_run_outcome +
## equipped_title / equip_title (cosmetic meta, no combat/replay/verifier input). Run result: NO, stays -l.
## Moved 2026-10-14 by C8 67aa32d: MetaState daily weekly bonus (daily_week.paid, add_shards ledger for daily
## Shard). Meta economy only. Run result: NO, stays -l.
## Moved 2026-10-14 by C2 f05dd91: RunState run_kind saved + close_summary score/elites + ranked submit;
## MetaState daily-run reward. Run result: NO (seed path unchanged), stays -l.
## BUMPED, 2026-10-14: `ActionLog.RULES_VERSION` -> `godot-2026-10-13-m`. L1 B11: Aid R5, swap ONE boss Pact card
## (`RunState.reroll_pact_slot`, `RewardGenerator.pick_pact_replacement`, action `pact_reroll` [slot, n], replayed by
## RunVerifier). Changes what a run can contain. Worker SUPPORTED_RULE_VERSIONS gained -m.
## Moved 2026-10-14 by C6 a2ceadd: MetaState team_presets field (meta only). Run result: NO, stays -m.
## Moved 2026-10-14 by C6 Land upgrade 664b1a0: MetaState land_tier + upgrade_land (meta only). Run result: NO, stays -m.
## BUMPED, 2026-10-15: `ActionLog.RULES_VERSION` -> `godot-2026-10-13-n`. L1 B1 fix: the `shop_roll` epoch arg `item` is the
## string "<kind>_<index>" (RunState._shop_item_arg) instead of an int, because the Worker requires an identifier. Args feed
## EpochCanon.seed_from, so heal-buy seeds change and RunVerifier recomputes from them. Worker SUPPORTED_RULE_VERSIONS gained -n.
## FINGERPRINT left for the main merge (lane I recomputes it).
## Moved 2026-10-16 by sign-in feedback c1400a1: AccountService desktop_phase/reconciling (account UI only). Run result: NO, stays -n.
## Moved 2026-10-16 by C6 Profile 53a6981: MetaState run_log/profile_stats, RunState passes kind/aid_used to record_run_outcome (meta only). Run result: NO, stays -n.
## Moved 2026-10-16 by online Continue fix d8a60c0: EpochSource.reconnect()/needs_reconnect() + RunState.resume_online/discard_gone_run (session plumbing, no rule/replay change). Run result: NO, stays -n.
## Moved 2026-10-16 by Missions online A 8a00dc0: MetaState mission mirror bound to the server escrow, RunState sends tier/stake + server settlement (meta/economy only). Run result: NO, stays -n.
## Moved 2026-10-18 by lane M 0ea6b45: TeamPresets.may_repeat/seat_taken/has_vault_duplicate (starter Axies may repeat in a
## party, Vault once). Party building only; the engine already took team_keys as given and the Worker never checked
## uniqueness. Run result: NO, stays -n.
## Moved 2026-10-19 by lane M 2190ab6: MetaState.key_bindings (rebindable shortcuts, saved via SaveStore; settings only,
## no rule reads it). Run result: NO, stays -n.
## Moved 2026-10-20 by lane E 2302828/28a050c: EchoBox season box (season pool split, milestones, titles, per-tier pity;
## meta/cosmetics only, no rule reads it). Run result: NO, stays -n.
## BUMPED, 2026-10-20: `ActionLog.RULES_VERSION` -> `godot-2026-10-20-o`. Depth v3 integration (lanes A/B/C/D/E): Cores replace
## relic offers (CoreOffer, Core quests/rerolls/tier chain), Run Rules + affixes, Armor, combat_tune.json knobs, Core/rule
## picks recorded in the action log and replayed by RunVerifier, plus Raid R1 ghost combat. Same actions give a different run.
## Worker SUPPORTED_RULE_VERSIONS gained -o. Unfinished runs saved under -n are discarded by saved_run_status() ("rules").
## Moved 2026-10-20 by integration round 2 (depth/FX cfca4ba + depth/VZ 8d480d1): thorn cap removed, 3 thorn Cores, tier-bet Cores,
## Heavy Strike, core_fired for every Core, RunState.core_impact. These are part of the depth v3 rules whose version `-o` has NOT
## been deployed yet, so RULES_VERSION stays `godot-2026-10-20-o` (same unreleased version); only the FINGERPRINT moves.
## Moved 2026-10-20 by FX review fixes (RunState): empty-pool Dim Stone refunds a Core reroll, an empty offer keeps the Fossil, old-save
## offer_pick default. Same unreleased `-o`; RULES_VERSION unchanged.
## BUMPED, 2026-10-22: `ActionLog.RULES_VERSION` -> `godot-2026-10-22-p`. Depth v4 integration (depth/V4 c22162f): Set (BO) per part,
## Dose/Safe rmode + pin, Crack from epoch, wild_face, Overcast in the M bag, thorn/poison caps, depth_stage header, best_bo,
## enemy_dmg 1.50. Same actions give a different run. Worker SUPPORTED_RULE_VERSIONS gained -p.
const FINGERPRINT := "5e3ffc5f76e5b285b4556603156b6727c60db4a017fe9afb6d53e93941a2439e"


func _ready() -> void:
	var files := _watched_files()
	if files.is_empty():
		print("t_rules_version: FAIL — the watch list matched no files, so this gate is blind")
		get_tree().quit(1)
		return

	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	for path in files:
		ctx.update(path.to_utf8_buffer())
		var f := FileAccess.open(path, FileAccess.READ)
		if f == null:
			print("t_rules_version: FAIL — cannot read watched file %s" % path)
			get_tree().quit(1)
			return
		ctx.update(f.get_buffer(f.get_length()))
		f.close()
	var digest := ctx.finish().hex_encode()

	if digest == FINGERPRINT:
		print("t_rules_version: PASS — %d rule files unchanged since RULES_VERSION '%s' was set"
			% [files.size(), ActionLog.RULES_VERSION])
		get_tree().quit(0)
		return

	print("t_rules_version: FAIL — the rule files changed since RULES_VERSION '%s' was last set."
		% ActionLog.RULES_VERSION)
	print("  Watched: %d files under %s plus %s"
		% [files.size(), str(WATCHED_DIRS), str(WATCHED_FILES)])
	print("  ASK ONE QUESTION: can this change make the same actions produce a different run?")
	print("    YES -> bump ActionLog.RULES_VERSION (old logs then get an honest 'refresh and")
	print("           replay' instead of being replayed against rules they never ran under).")
	print("    NO  -> leave RULES_VERSION alone (a comment, a rename, a new UI-only branch).")
	print("  EITHER WAY, paste this into t_rules_version.gd's FINGERPRINT:")
	print("    %s" % digest)
	get_tree().quit(1)


## Sorted, so the digest depends on the files' content and not on the order the filesystem
## happened to hand them over.
func _watched_files() -> Array[String]:
	var out: Array[String] = []
	for dir_path in WATCHED_DIRS:
		_collect(dir_path, out)
	for path in WATCHED_FILES:
		if FileAccess.file_exists(path):
			out.append(path)
	out.sort()
	return out


## Recursive; a missing directory is skipped (assets/data/rules does not exist until lane A/E add it).
func _collect(dir_path: String, out: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	for name in dir.get_files():
		for ext in WATCHED_EXTS:
			if String(name).ends_with(ext):
				out.append("%s/%s" % [dir_path, name])
				break
	for sub in dir.get_directories():
		_collect("%s/%s" % [dir_path, sub], out)
