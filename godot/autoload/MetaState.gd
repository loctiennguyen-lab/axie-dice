extends Node
## Persistent meta-progression (~= JS `META` in localStorage). Saved as JSON to
## user://meta_save.json — deliberately NOT a .tres/Resource save file: a Resource save
## can embed arbitrary script/resource references, so a hand-edited save could execute
## code on load. JSON is data-only, matching how the JS version already does it
## (architecture plan §4, §9 self-critique #A "over-engineered" note on ResourceSaver).

const SAVE_PATH := "user://meta_save.json"

## src/client.html:3216. Twenty slots, and a full vault REFUSES a new import with a message
## rather than quietly dropping the oldest one — a silent LRU on a list the player curated by
## hand is a bug they only find later, by missing an Axie.
const VAULT_MAX := 20
## src/client.html:3224. A vault record is a RESOLVED die, frozen at import. When the part->face
## rules change (v1 looked up a 36-cell slot/class template and could only produce 19 distinct
## faces; v2 looks up the 285-entry part-identity table), every old record keeps its old faces.
## Without a version the new system is invisible to anyone who already imported — their dice are
## simply out of date, with nothing to tell them. Migration is a RE-SCAN, not an in-place
## conversion: a v1 record never stored `parts`, so the die cannot be rebuilt from it.
const VAULT_SCHEMA := 2
## Prefix for the synthetic hero key a vault Axie is registered under. `vault_<axie id>`.
const VAULT_KEY_PREFIX := "vault_"

var shard_pool: int = 0
var battle_pass_xp: int = 0
var battle_pass_level: int = 1
var vault: Array[Dictionary] = []      # imported Axie dice, max 20 (rule spec §6)
var unlocks: Array[String] = []

# --- Battle pass / lifetime stats (~= JS META.xp/bpClaimed/perks/ascMax/runs/wins/best) ---
var xp: int = 0
var bp_claimed: Array[int] = []        # levels already collected
var perks: Dictionary = {}             # perk key -> stack count (reroll/relic0/relic1/hp4/rrw)
var asc_max: int = 0                   # highest Ascension the player may select
var runs: int = 0
var wins: int = 0
var best: int = 0                      # furthest power_level reached in any run

## Audio settings. Linear 0..1 sliders, not dB — CombatAudioDirector converts. They live in
## MetaState rather than in a separate settings file because this project already has exactly
## one persisted blob and a second one would be a second thing to keep migrated.
var audio_music_volume: float = 1.0
var audio_sfx_volume: float = 1.0
var audio_muted: bool = false

## Daily Mission (economy-progression.md §10.3, src/client.html:5425). The UTC date string
## 'YYYY-MM-DD' of the last grant; "" means never claimed.
var daily_date: String = ""

## Onboarding tutorial (design/gdd/onboarding-tutorial.md), ported trigger. The JS gate is
## "after first login" (`!META.tut && META.runs===0`) — this port has no login screen (a
## deliberate, permanent waiver, not a gap to fill later), so the equivalent trigger is FIRST
## LAUNCH ON THIS MACHINE: false on a save that has never been through Tutorial.tscn's
## completion, checked once at MainMenu.gd's _ready(), the single scene every "return to menu"
## path in this project already funnels through (boot IS MainMenu.tscn per project.godot's
## run/main_scene — unlike the JS build, this port does not need a second gate point).
var tutorial_seen: bool = false


## `needs_tutorial()` mirrors the JS `needsTutorial` formula's belt-and-suspenders shape
## (design doc §3.2/§4): `runs == 0` is a second, independent guard so a save whose
## `tutorial_seen` flag is wrong for any reason (bug, hand-edited save) can never force a
## player who has already completed real runs back into the tutorial.
func needs_tutorial() -> bool:
	return not tutorial_seen and runs == 0

func _ready() -> void:
	load_from_disk()
	# DEFERRED on purpose. Autoloads are constructed in the order project.godot lists them, and
	# MetaState comes before ContentDB — so at this point `ContentDB` does not exist yet, and
	# writing hero keys into it here would either fail or be overwritten by its own `_init()`.
	# A deferred call runs once the whole autoload set is up.
	ensure_vault_heroes.call_deferred()

func add_shards(amount: int) -> void:
	shard_pool += amount
	save_to_disk()

func load_from_disk() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		push_warning("MetaState: could not open %s for reading" % SAVE_PATH)
		return
	var text := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("MetaState: save file did not contain a JSON object, ignoring")
		return
	shard_pool = int(parsed.get("shard_pool", 0))
	battle_pass_xp = int(parsed.get("battle_pass_xp", 0))
	battle_pass_level = int(parsed.get("battle_pass_level", 1))
	# NOT a bare assign(). Every number that went through JSON comes back a float, and a vault
	# record is nothing but numbers with meaning — see _vault_entry_from_json().
	vault.assign(_vault_from_json(parsed.get("vault", [])))
	unlocks.assign(parsed.get("unlocks", []))
	xp = int(parsed.get("xp", 0))
	bp_claimed.assign(_ints(parsed.get("bp_claimed", [])))
	perks = _int_values(parsed.get("perks", {}))
	asc_max = int(parsed.get("asc_max", 0))
	runs = int(parsed.get("runs", 0))
	wins = int(parsed.get("wins", 0))
	best = int(parsed.get("best", 0))
	# Defaults are "on at full", so a save written before audio existed reads as sound enabled
	# rather than as a player who had muted the game.
	audio_music_volume = clampf(float(parsed.get("audio_music_volume", 1.0)), 0.0, 1.0)
	audio_sfx_volume = clampf(float(parsed.get("audio_sfx_volume", 1.0)), 0.0, 1.0)
	audio_muted = bool(parsed.get("audio_muted", false))
	daily_date = str(parsed.get("daily_date", ""))
	tutorial_seen = bool(parsed.get("tutorial_seen", false))
	# Migration backfill (design/gdd/onboarding-tutorial.md §5 "Migration save cũ", ported):
	# a save with real runs already on it predates this feature and must never be forced
	# through the tutorial retroactively.
	if not tutorial_seen and runs > 0:
		tutorial_seen = true

func save_to_disk() -> void:
	var data := {
		"shard_pool": shard_pool,
		"battle_pass_xp": battle_pass_xp,
		"battle_pass_level": battle_pass_level,
		"vault": vault,
		"unlocks": unlocks,
		"xp": xp,
		"bp_claimed": bp_claimed,
		"perks": perks,
		"asc_max": asc_max,
		"runs": runs,
		"wins": wins,
		"best": best,
		"audio_music_volume": audio_music_volume,
		"audio_sfx_volume": audio_sfx_volume,
		"audio_muted": audio_muted,
		"daily_date": daily_date,
		"tutorial_seen": tutorial_seen,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("MetaState: could not open %s for writing" % SAVE_PATH)
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()


# ===========================================================================
# JSON coercion helpers
# ===========================================================================
# JSON.parse_string returns every number as a float and every key as a string. Levels are
# compared with `in`, and perk counts are added to — a 3.0 where a 3 is expected compares
# unequal in an Array[int] and silently drops the claim.

static func _ints(raw) -> Array:
	var out: Array = []
	for v in (raw as Array):
		out.append(int(v))
	return out


static func _int_values(raw) -> Dictionary:
	var out: Dictionary = {}
	for k in (raw as Dictionary):
		out[String(k)] = int((raw as Dictionary)[k])
	return out


# ===========================================================================
# Battle pass (~= JS bpLevel()/bpProg()/bpUnclaimed(), client.html:3424-3436)
# ===========================================================================

## src/data.js bpLevel(): the highest level whose cumulative XP requirement is met.
func bp_level() -> int:
	var lv := 0
	var need := 0
	for i in range(1, ContentDB.BP_MAX_LEVEL + 1):
		need += ContentDB.bp_xp_for_level(i)
		if xp >= need:
			lv = i
		else:
			break
	return lv


## {level, into_level, needed, percent} — the progress bar's own numbers. `needed` is 0 at max
## level, which callers must treat as "done" rather than dividing by it.
func bp_progress() -> Dictionary:
	var lv := bp_level()
	var base := 0
	for i in range(1, lv + 1):
		base += ContentDB.bp_xp_for_level(i)
	var next_need: int = ContentDB.bp_xp_for_level(lv + 1) if lv < ContentDB.BP_MAX_LEVEL else 0
	return {
		"level": lv,
		"into_level": xp - base,
		"needed": next_need,
		"percent": (100.0 if next_need == 0 else minf(100.0, 100.0 * float(xp - base) / float(next_need))),
	}


## Levels the player has earned but not collected — and, deliberately, only the ones that can
## actually be granted. A `face` reward has nothing behind it while FACE_POOL is unported, so
## offering it would be a button that consumes a claim and gives nothing.
func bp_unclaimed() -> Array:
	var out: Array = []
	var lv := bp_level()
	for entry in ContentDB.BP_TRACK:
		var e: Dictionary = entry
		if int(e.get("lv", 0)) > lv:
			continue
		if bp_claimed.has(int(e.get("lv", 0))):
			continue
		if String(e.get("type", "")) == "face":
			continue
		out.append(e)
	return out


## Levels that are earned and would be claimable if their reward type were ported. Shown to the
## player as locked-with-a-reason rather than hidden, so a missing subsystem reads as missing
## rather than as a track with holes in it.
func bp_blocked() -> Array:
	var out: Array = []
	var lv := bp_level()
	for entry in ContentDB.BP_TRACK:
		var e: Dictionary = entry
		if int(e.get("lv", 0)) <= lv and String(e.get("type", "")) == "face" \
				and not bp_claimed.has(int(e.get("lv", 0))):
			out.append(e)
	return out


## Grants one milestone. Returns "" on success, or a human-readable reason it was refused —
## never silently no-ops, because a claim button that appears to work and does nothing is the
## exact failure this project already shipped once in the event system.
func claim_bp_reward(level: int) -> String:
	if level > bp_level():
		return "Level %d is not earned yet." % level
	if bp_claimed.has(level):
		return "Level %d was already claimed." % level
	var entry: Dictionary = {}
	for e in ContentDB.BP_TRACK:
		if int((e as Dictionary).get("lv", 0)) == level:
			entry = e
			break
	if entry.is_empty():
		return "Level %d is not on the track." % level

	var reward_type := String(entry.get("type", ""))
	match reward_type:
		"shard":
			shard_pool += int(entry.get("value", 0))
		"unlock":
			var id := String(entry.get("value", ""))
			if not unlocks.has(id):
				unlocks.append(id)
		"perk":
			var key := String(entry.get("value", ""))
			perks[key] = int(perks.get(key, 0)) + 1
		"face":
			# Refused, not claimed. FACE_POOL is unported (a recorded decision, not an
			# oversight), so there is no face to grant and marking this claimed would burn the
			# milestone forever.
			return "Gene rewards need the mutation pool, which is not in this build yet."
		_:
			return "Unknown reward type '%s'." % reward_type

	bp_claimed.append(level)
	save_to_disk()
	return ""


# ===========================================================================
# Unlock ladder (~= JS unlocked()/buying from the meta screen)
# ===========================================================================

func has_unlock(id: String) -> bool:
	return unlocks.has(id)


func unlock_def(id: String) -> Dictionary:
	for u in ContentDB.UNLOCKS:
		if String((u as Dictionary).get("id", "")) == id:
			return u
	return {}


## Spends shards on a permanent unlock. Returns "" on success or the reason it was refused.
func buy_unlock(id: String) -> String:
	if has_unlock(id):
		return "Already owned."
	var def := unlock_def(id)
	if def.is_empty():
		return "No such unlock."
	var cost := int(def.get("cost", 0))
	if shard_pool < cost:
		return "Needs %d Gene Shard, you have %d." % [cost, shard_pool]
	shard_pool -= cost
	unlocks.append(id)
	save_to_disk()
	return ""


# ===========================================================================
# What the meta grants a run (~= JS newRun(), client.html:4669-4673)
# ===========================================================================

## RANKED RUNS GET NOTHING. Every value below is zeroed for a ranked run, because meta
## progression is local and never synced, so a replay on the server cannot reproduce it — a
## ranked board where a player's local purchases change the outcome is not a board at all.
## This is the single most important line in this file to keep true.
func run_bonuses(is_ranked: bool) -> Dictionary:
	if is_ranked:
		return {"bonus_reroll": 0, "hp_bonus": 0, "start_relic_max_rarity": -1,
			"reward_reroll_max": 1}
	var reroll := 0
	if has_unlock("u_reroll"):
		reroll += 1
	if has_unlock("u_reroll2"):
		reroll += 1
	reroll += int(perks.get("reroll", 0))

	var hp := 0
	if has_unlock("u_hp"):
		hp += 3
	if has_unlock("u_hp2"):
		hp += 2
	hp += 4 * int(perks.get("hp4", 0))

	# JS: sr = u_start + perks.relic0 + perks.relic1 (a count), srRar = perks.relic1 ? 1 : 0.
	# One starting relic is granted when any of those is present; the rarity ceiling rises to
	# Rare only with the relic1 perk.
	var grants_relic: bool = has_unlock("u_start") or int(perks.get("relic0", 0)) > 0 \
		or int(perks.get("relic1", 0)) > 0
	var rarity_cap: int = -1
	if grants_relic:
		rarity_cap = 1 if int(perks.get("relic1", 0)) > 0 else 0

	# src/client.html:4681 — the 'rrw' perk lets a reward set be rerolled more than once per node.
	var reward_rerolls := 1 + int(perks.get("rrw", 0))

	return {"bonus_reroll": reroll, "hp_bonus": hp, "start_relic_max_rarity": rarity_cap,
		"reward_reroll_max": reward_rerolls}


# ===========================================================================
# Vault / Import Axie (~= JS importAxieToVault / removeFromVault / vaultStale /
# vaultKey / ensureVaultHero, src/client.html:3212-3256)
# ===========================================================================
# A vault entry is the record `AxieToDie.build()` produced, stamped with a schema version and
# carrying the verified part manifest beside it. It is shaped like a ContentDB.heroes entry on
# purpose (n / cls / tier / max_hp / die), which is what lets a vault Axie be picked into a team
# and played as a tier-1 hero with no change to the combat engine at all.


## `vault_<axie id>` — stable across sessions, which is what makes a saved run resumable: the
## roster stores keys, not records.
static func vault_key(entry: Dictionary) -> String:
	return VAULT_KEY_PREFIX + str(entry.get("axie_id", ""))


static func is_vault_key(hero_key: String) -> bool:
	return hero_key.begins_with(VAULT_KEY_PREFIX)


## A record written under older face rules. Shown with a RE-SCAN badge and refused by team
## select, rather than hidden — a missing Axie reads as data loss; a flagged one reads as work
## to do.
static func vault_stale(entry: Dictionary) -> bool:
	return entry.is_empty() or int(entry.get("schema", 0)) < VAULT_SCHEMA


func vault_index_of(axie_id) -> int:
	var want := str(axie_id)
	for i in vault.size():
		if str((vault[i] as Dictionary).get("axie_id", "")) == want:
			return i
	return -1


func vault_entry(axie_id) -> Dictionary:
	var i := vault_index_of(axie_id)
	return vault[i] if i >= 0 else {}


func vault_is_full() -> bool:
	return vault.size() >= VAULT_MAX


## Imports one Axie. Takes the RAW API payload — the same shape `AxieToDie.build()` reads — and
## does the conversion itself. Returns `{ok, updated, err, die}`; `err` is "vault_full" or
## "invalid_axie_data", the same strings the JS returns, so the screen's messages match the live
## build's word for word.
##
## WHY IT TAKES THE PAYLOAD AND NOT A FINISHED DIE. A vault record is the resolved die PLUS the
## verified part manifest it was resolved from (client.html:3230) — the die alone cannot be
## re-derived, which is exactly why a schema-1 record has to be re-scanned rather than converted.
## An earlier draft of this function took `(die, parts)` separately and defaulted `parts` to
## empty. That signature let a caller store Axie A's die beside Axie B's parts, and let a caller
## who simply forgot the second argument write a record that was born un-re-derivable, with no
## error. One payload in, one record out, no way to pair the wrong two halves.
##
## Re-importing an id that is already stored UPDATES it rather than adding a second copy: the
## player's Axie really can change parts between scans, and two records for one Axie would both
## claim the same `vault_<id>` key.
func vault_import(axie_data: Dictionary, gene_tier: int = 0) -> Dictionary:
	if axie_data.is_empty() or str(axie_data.get("id", "")).is_empty():
		return {"ok": false, "updated": false, "err": "invalid_axie_data", "die": {}}

	var entry: Dictionary = AxieToDie.build(axie_data, gene_tier)
	entry["schema"] = VAULT_SCHEMA
	# The id is stored as a STRING, always. It arrives from the API as a number and would come
	# back from JSON as a float, so `123` saved becomes `123.0` loaded and stops matching the key
	# it was filed under — the same int/string key split that once left five growth sources
	# writing values nobody read. An id is a name, not a quantity.
	entry["axie_id"] = str(axie_data.get("id", ""))
	entry["parts"] = _vault_parts_manifest(axie_data.get("parts", []))
	if (entry["parts"] as Array).is_empty():
		# A record with no manifest is born in the state schema-1 records are stuck in. Refusing
		# is louder than storing one and discovering it at the next rules change.
		return {"ok": false, "updated": false, "err": "invalid_axie_data", "die": {}}

	var existing := vault_index_of(entry["axie_id"])
	if existing >= 0:
		vault[existing] = entry
		_register_vault_hero(entry)
		save_to_disk()
		return {"ok": true, "updated": true, "err": ""}
	if vault_is_full():
		return {"ok": false, "updated": false, "err": "vault_full"}
	vault.append(entry)
	_register_vault_hero(entry)
	save_to_disk()
	return {"ok": true, "updated": false, "err": ""}


func vault_remove(axie_id) -> bool:
	var i := vault_index_of(axie_id)
	if i < 0:
		return false
	var key := vault_key(vault[i])
	vault.remove_at(i)
	ContentDB.heroes.erase(key)
	save_to_disk()
	return true


## Registers every stored Axie into `ContentDB.heroes`, so the combat engine can resolve a roster
## entry whose key is `vault_<id>` exactly as it resolves `plant1`.
##
## WHY THIS IS CALLED FROM _ready() AND NOT FROM THE VAULT SCREEN. The JS registers lazily, from
## whichever menu screen happens to render a vault Axie — and shipped a bug because of it
## (client.html:3256, "wave clear doesn't advance"): CONTINUE RUN resumes straight into combat
## and never visits a menu, so a saved run with a vault Axie came back with an unresolvable hero
## key. Registering once at boot has no such hole, and costs one loop over at most twenty records.
func ensure_vault_heroes() -> void:
	for entry in vault:
		_register_vault_hero(entry)


func _register_vault_hero(entry: Dictionary) -> void:
	if vault_stale(entry):
		# A stale record must not become playable by the back door. It is missing the `parts`
		# manifest, so its die cannot be rebuilt, and registering it would let a team picker that
		# only checks `ContentDB.heroes` hand the player a die built under last version's rules.
		return
	ContentDB.heroes[vault_key(entry)] = entry


## Vault Axies are not eligible for a Ranked Run (rule spec §6; the live server refuses them with
## HTTP 400, api/submit-run.js:87). The reason is not fairness in the abstract: a vault die exists
## only in this player's local save, so a replay cannot rebuild it and the score cannot be
## verified. Mirrored here rather than left to the UI, because the UI is not the authority.
static func team_has_vault_pick(team_keys: Array) -> bool:
	for k in team_keys:
		if is_vault_key(str(k)):
			return true
	return false


# ---------------------------------------------------------------------------
# JSON coercion for vault records
# ---------------------------------------------------------------------------
# Same hazard the helpers above this file already carry, but worse: a vault record is a nested
# structure of numbers that all mean something. A face value read back as 7.0 formats as "7.0" on
# a die card; a tier of 1.0 fails `== 1`. Only the fields that are known to be numeric are cast —
# blind-casting every value would turn the class name and the keyword list into garbage, which is
# the mistake the part_faces loader explicitly avoided.

func _vault_from_json(raw) -> Array:
	var out: Array = []
	if not (raw is Array):
		return out
	for v in (raw as Array):
		if v is Dictionary:
			out.append(_vault_entry_from_json(v))
	return out


static func _vault_entry_from_json(raw: Dictionary) -> Dictionary:
	var e := raw.duplicate(true)
	e["axie_id"] = str(raw.get("axie_id", ""))
	e["schema"] = int(raw.get("schema", 0))
	e["tier"] = int(raw.get("tier", 1))
	e["max_hp"] = int(raw.get("max_hp", 0))
	e["gene_tier"] = int(raw.get("gene_tier", 0))
	e["purity"] = int(raw.get("purity", 0))
	e["coh"] = float(raw.get("coh", 1.0))
	var faces: Array = []
	for f in (raw.get("die", []) as Array):
		if not (f is Dictionary):
			continue
		var face: Dictionary = (f as Dictionary).duplicate(true)
		face["v"] = int((f as Dictionary).get("v", 0))
		face["r"] = int((f as Dictionary).get("r", 0))
		faces.append(face)
	e["die"] = faces
	return e


## The manifest JS freezes next to the die (client.html:3230). Kept to the same five fields: it is
## what a re-derive and a server-side replay would need, and copying the whole API payload would
## put fields nobody reads into a save file forever.
static func _vault_parts_manifest(raw) -> Array:
	var out: Array = []
	if not (raw is Array):
		return out
	for p in (raw as Array):
		if not (p is Dictionary):
			continue
		var d: Dictionary = p
		out.append({
			"id": str(d.get("id", "")),
			"name": str(d.get("name", "")),
			"class": str(d.get("class", "")),
			"type": str(d.get("type", "")),
			# null is meaningful and distinct from "": JS writes `specialGenes==null?null:...`,
			# and AxieToDie.sg_tier() treats an absent value as tier 0 on purpose.
			"specialGenes": d.get("specialGenes"),
		})
	return out


# ===========================================================================
# Daily Mission (~= JS claimDailyMission(), src/client.html:5430)
# ===========================================================================

## The UTC calendar day, 'YYYY-MM-DD'.
##
## UTC, not local time, and not `Time.get_datetime_string_from_system(false)` — the JS uses
## `new Date().toISOString().slice(0,10)` for BOTH this and the DAILY SEED button, so a player's
## day boundary has to be the same instant in both features. A local-time boundary here would
## give a player in UTC+7 a fresh mission at a different moment than a fresh daily seed.
static func today_utc() -> String:
	var d := Time.get_datetime_dict_from_system(true)
	return "%04d-%02d-%02d" % [int(d["year"]), int(d["month"]), int(d["day"])]


## Grants the daily shard if it has not been granted today. Returns true only when it actually
## granted, so the result screen can show the line only on the day it happened.
##
## IDEMPOTENT: safe to call at every run end. A player finishing four runs in one day gets the
## 60 shards once, on the first — the same contract the JS relies on by calling it unconditionally
## from `onRunEnd()`.
func claim_daily_mission() -> bool:
	var today := today_utc()
	if daily_date == today:
		return false
	daily_date = today
	shard_pool += ContentDB.DAILY_MISSION_SHARD
	return true
