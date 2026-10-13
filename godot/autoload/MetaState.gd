extends Node
## Persistent meta-progression (~= JS `META` in localStorage). Saved as JSON to
## user://meta_save.json — deliberately NOT a .tres/Resource save file: a Resource save
## can embed arbitrary script/resource references, so a hand-edited save could execute
## code on load. JSON is data-only, matching how the JS version already does it
## (architecture plan §4, §9 self-critique #A "over-engineered" note on ResourceSaver).

const SAVE_PATH := "user://meta_save.json"
## Bản sao save v1 trước lần migrate đầu tiên (ghi một lần, qua SaveStore, không đè nếu đã có).
const V1_BACKUP_PATH := "user://meta_save.v1.bak"
const EconomyDBScript := preload("res://scripts/meta/economy_db.gd")

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
## H11 (Liam 13/10): newcomer = fewer than `newcomer_runs` runs that had >= 1 battle (matches
## worker/src/runs.js newcomer()). Counted once per run by RunState.apply_combat_result, so runs
## abandoned after a battle count and runs abandoned before any battle do not.
var runs_with_battle: int = 0
var battle_counted_seed: int = -1       ## run_seed of the last run already counted (resume-safe)
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

## Suppresses the two effects that FLASH or SHAKE — the screen shake on a landed hit and the
## colour flash on a resonant portrait. Not a general "less animation" switch: dice still roll
## and Axies still play their actions, because those carry information the player needs. This
## only removes the effects that exist purely for impact, which are also the ones that make a
## game unplayable for someone sensitive to them.
var reduce_flash: bool = false

## Daily Mission (economy-progression.md §10.3, src/client.html:5425). The UTC date string
## 'YYYY-MM-DD' of the last grant; "" means never claimed.
var daily_date: String = ""

## Onboarding tutorial (design/gdd/onboarding-tutorial.md), ported trigger. The JS gate is
## "after first login" (`!META.tut && META.runs===0`). This port's sign-in is optional (accounts,
## claude/ACCOUNT_SYSTEM_v1.md — a guest never signs in), so the equivalent trigger is still FIRST
## LAUNCH ON THIS MACHINE: false on a save that has never been through Tutorial.tscn's
## completion, checked once at MainMenu.gd's _ready(), the single scene every "return to menu"
## path in this project already funnels through (boot IS MainMenu.tscn per project.godot's
## run/main_scene — unlike the JS build, this port does not need a second gate point).
var tutorial_seen: bool = false

# --- L1 economy (lane E; contract production/l1-interfaces.md 5.2) -----------------------------
## Save schema. 1 = trước L1 (không có field này). 2 = economy L1. Save cũ (<2) được MIGRATE khi nạp:
## unlock + perk + Pass cũ + số dư Shard bị bỏ, thay bằng khoản khởi đầu cố định
## (docs/architecture/server-authoritative-rng.md 9.1/9.2: unlock cũ không nhập). Vault, thống kê
## run, cài đặt, tutorial_seen được giữ. Migrate CHỈ trong bộ nhớ; file ghi lại ở lần save kế tiếp
## (nạp không được tự ghi, nếu không mỗi lần chạy test sẽ đè save thật).
const SAVE_VERSION := 2
var save_version: int = SAVE_VERSION
var starter_granted: bool = false
var stone: int = 0                       # Land Stone
var gems_cache: int = 0                  # Gem (local) / bộ đệm hiển thị nếu Gem ở server [LIAM-2]
var gem_claim_next_utc: int = 0          # unix 00:00 UTC kế tiếp được nhận Gem tặng
var gem_gift_day: String = ""            # ngày UTC đã nhận Gem tặng gần nhất
var tickets: Dictionary = {"normal": 0, "season": 0}   # MỘT loại vé: dùng "normal"; "season" dự trữ = 0
## Hộp mùa theo series: {series_id: {opens, c_epic, c_legendary, c_mythic, owned[], milestones[], day, day_pulls}}.
var season_box: Dictionary = {}
var echobox_pity: Dictionary = {}        # bộ đếm pity, mảnh, số lượt mở, đếm mua vé theo ngày
var cosmetics_owned: Array[String] = []
var pass_season: Dictionary = {"id": "", "xp": 0, "level": 0, "claimed_free": []}
var vip_until_utc: int = 0
var vip_trial_used: bool = false
var mission_house_level: int = 0
## Escrow cược Nhiệm vụ đang mở ({} = không có). Lưu qua SaveStore nên sống qua khởi động lại giữa run.
var mission_escrow: Dictionary = {}
## Phần Shard khoản khởi đầu chưa tiêu: KHÔNG dùng làm cược (nhiem-vu-risk-to-earn: "khoản khởi đầu không dùng làm cược").
var starter_shard_locked: int = 0
## Stone Nhiệm vụ đã nhận trong ngày UTC (trần stone_day_cap): {"day": "", "n": 0}.
var mission_stone_day: Dictionary = {"day": "", "n": 0}
var asc_wins: Dictionary = {}            # "asc" -> số run thắng
var full_a9_won: bool = false
var aid_hints_off: bool = false
var last_daily_reward_utc: String = ""
## Số ngày UTC đã nhận daily trong tuần (thứ Hai UTC): {"week": "YYYY-MM-DD", "n": 0}. Cho chấm tuần M8.
var daily_week: Dictionary = {"week": "", "n": 0}
## Sổ cái (200 dòng cuối): {t, c, d, r, b} = thời điểm, tiền tệ, thay đổi, lý do, số dư sau.
var ledger: Array = []
const LEDGER_MAX := 200
var _gem_wallet: GemWallet = null


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

func add_shards(amount: int, reason: String = "earn", save: bool = true) -> void:
	shard_pool += amount
	ledger_add("shard", amount, reason)
	if save:
		save_to_disk()


## Land Stone. n > 0. Vào sổ cái.
func add_stone(n: int, reason: String = "earn", save: bool = true) -> void:
	if n <= 0:
		return
	stone += n
	ledger_add("stone", n, reason)
	if save:
		save_to_disk()


## Trừ `n` của `currency` ("shard" | "stone" | "gem"). false (không trừ gì) nếu không đủ.
func spend(currency: String, n: int, reason: String, save: bool = true) -> bool:
	if n < 0:
		return false
	match currency:
		"shard":
			if shard_pool < n:
				return false
			shard_pool -= n
			starter_shard_locked = maxi(0, starter_shard_locked - n)   # tiêu khoản khởi đầu trước, phần dùng làm cược không đổi
		"stone":
			if stone < n:
				return false
			stone -= n
		"gem":
			return gem_wallet().spend(n, reason, save)   # ví Gem tự lo save/server
		_:
			push_warning("MetaState.spend: tiền tệ lạ '%s'" % currency)
			return false
	ledger_add(currency, -n, reason)
	if save:
		save_to_disk()
	return true


## Ví Gem (interface). Hôm nay là bản local; lane S thay bằng bản server qua set_gem_wallet().
func gem_wallet() -> GemWallet:
	if _gem_wallet == null:
		_gem_wallet = LocalGemWallet.new(self)
	return _gem_wallet


func set_gem_wallet(w: GemWallet) -> void:
	_gem_wallet = w


## Dùng ví Gem server (làn S gọi khi đăng nhập). `balance_changed` của ví cập nhật bộ đệm gems_cache
## để UI/badge đọc MetaState như cũ.
func use_remote_gem_wallet(w: GemWallet) -> void:
	set_gem_wallet(w)
	gems_cache = w.balance()
	if w.has_signal("balance_changed"):
		w.connect("balance_changed", func(b: int) -> void: gems_cache = b)


## Nhận Gem tặng, bất đồng bộ (bản remote hỏi server). done(result:{ok, granted, reason, next_utc}).
## Sau kết quả: đồng bộ gems_cache + gem_claim_next_utc rồi save.
func claim_gem_gift_async(done: Callable = Callable()) -> void:
	var w := gem_wallet()
	w.claim_daily_gift_async(func(r: Dictionary) -> void:
		if int(r.get("next_utc", 0)) > 0:
			gem_claim_next_utc = int(r["next_utc"])
		gems_cache = w.balance()
		save_to_disk()
		if done.is_valid():
			done.call(r))


## Nhận Gem tặng hôm nay (giờ UTC thật của máy; bản server sẽ do server xác nhận).
## Giá shop hiện hành của một unlock (để hoàn Shard khi mốc Pass trùng unlock đã có, ECO-13).
## Đọc ContentDB.UNLOCKS; bảng giá x3 (A2) chưa áp ở đó, theo ContentDB khi nó đổi.
func unlock_price(id: String) -> int:
	return int(unlock_def(id).get("cost", 0))


## Gọi khi một run kết thúc (A/U nối): cộng XP Pass v2 theo công thức run XP. Trả XP thực nhận.
func pass_add_run_xp(raw_xp: int) -> int:
	var got := PassV2.add_run_xp(self, raw_xp, today_utc())
	return got


## Nhận 500 XP của một việc tuần (xem PassV2.claim_weekly).
func pass_claim_weekly(week_day: String, task_id: String) -> Dictionary:
	return PassV2.claim_weekly(self, week_day, task_id, today_utc())


## Nhận phần thưởng free của level `lv` ở Pass v2 (xem PassV2.claim_free).
func pass_claim_free(lv: int) -> Dictionary:
	return PassV2.claim_free(self, lv)


## Nhận hết vòng sau lv30 đang chờ (50 Shard/vòng, data). Trả số Shard nhận được.
func pass_claim_post30() -> int:
	return PassV2.claim_post30(self)


## Ảnh chụp chỉ đọc của Pass v2 cho màn hình (đổi dict trả về không ảnh hưởng save).
func pass_state() -> Dictionary:
	var today := today_utc()
	var wk := PassV2.week_key(today)
	var xp := int(pass_season.get("xp", 0))
	return {
		"season_id": String(pass_season.get("id", "")),
		"active": PassV2.season_active(today),
		"xp": xp,
		"level": PassV2.level_for_xp(xp),
		"max_xp": PassV2.max_xp(),
		"claimed_free": (pass_season.get("claimed_free", []) as Array).duplicate(),
		"claimable_levels": PassV2.claimable_levels(self),
		"post30_pending": PassV2.post30_pending(self),
		"premium": PassV2.premium_state(),
		"week_key": wk,
		"weekly": PassV2.weekly_status(self, wk),
	}


func claim_gem_gift_now() -> Dictionary:
	return gem_wallet().claim_daily_gift(int(Time.get_unix_time_from_system()))


## Ghi một dòng sổ cái (chưa save; người gọi tự save). `c` = "shard"|"stone"|"gem"|"ticket".
func ledger_add(c: String, delta: int, reason: String) -> void:
	var bal := 0
	match c:
		"shard": bal = shard_pool
		"stone": bal = stone
		"gem": bal = gems_cache
		"ticket": bal = int(tickets.get("normal", 0))
	ledger.append({"t": int(Time.get_unix_time_from_system()), "c": c, "d": delta, "r": reason, "b": bal})
	if ledger.size() > LEDGER_MAX:
		ledger = ledger.slice(ledger.size() - LEDGER_MAX)


## S gọi sau khi gọi server: ghi đè bộ đệm ví từ snapshot {gems?, gem_claim_next_utc?, ...}.
func apply_server_wallet(snapshot: Dictionary) -> void:
	if snapshot.has("gems"):
		gems_cache = int(snapshot["gems"])
	if snapshot.has("gem_claim_next_utc"):
		gem_claim_next_utc = int(snapshot["gem_claim_next_utc"])
	save_to_disk()

## L1 contract 5.2 — A gọi từ RunState.end_run (A không ghi field trực tiếp). Ghi thắng theo Ascension
## và "đã thắng Full A9" để mở bậc Nhiệm vụ. `params`: {mode:"short"|"full", ascension:int, ...}.
## runs/wins/best vẫn do end_run ghi như hôm nay.
func record_run_outcome(params: Dictionary, won: bool) -> void:
	# Quyết toán cược Nhiệm vụ (một lần; settle lần hai không làm gì). `won` đã gồm điều kiện phụ.
	# Run thường kết thúc khi đang có escrow của run khác: params.mission_id rỗng -> không đụng escrow.
	if not mission_escrow.is_empty() and String(params.get("mission_id", "")) == String(mission_escrow.get("mission_id", "")) \
			and not String(params.get("mission_id", "")).is_empty():
		settle_mission_stake(won, false)
	# Việc tuần Pass v2: mọi run đã kết thúc đều tính; params.reached_boss (tuỳ chọn) cho việc "chạm boss".
	PassV2.record_run(self, today_utc(), won, bool(params.get("reached_boss", false)))
	if not won:
		return
	var asc := int(params.get("ascension", 0))
	asc_wins[str(asc)] = int(asc_wins.get(str(asc), 0)) + 1
	if String(params.get("mode", "short")) == "full" and asc >= 9:
		full_a9_won = true
	save_to_disk()


## Shard dùng được làm cược = số dư trừ phần khoản khởi đầu chưa tiêu.
func stake_usable_shards() -> int:
	return maxi(0, shard_pool - starter_shard_locked)


static func _escrow_from_json(raw) -> Dictionary:
	if not (raw is Dictionary) or (raw as Dictionary).is_empty():
		return {}
	var d: Dictionary = raw
	return {"tier": String(d.get("tier", "")), "mission_id": String(d.get("mission_id", "")),
		"stake": int(d.get("stake", 0)), "payout": int(d.get("payout", 0)), "stone": int(d.get("stone", 0)),
		"t": int(d.get("t", 0))}


## Nhiệm vụ (nhiem-vu-risk-to-earn §3, economy missions.json): trừ cược lúc tạo run, ghi escrow vào save.
## `tier_id` = "N1".. ; `mission_id` = id offer/run (RunState.mission.mission_id) để khớp lúc quyết toán;
## `stake` (tuỳ chọn) phải khớp bảng, số trong bảng là số thật. false + không trừ gì nếu: tier tắt/lạ,
## không đủ Shard dùng được (khởi đầu không tính), hoặc đã có escrow đang mở của run còn sống.
## Escrow mồ côi (không còn run đã lưu) bị đóng là thua trước khi nhận cược mới.
## Test seam: nếu gán, thay cho RunState.has_saved_run() trong code escrow (test không phụ thuộc save thật).
var saved_run_probe: Callable = Callable()

func _saved_run_exists() -> bool:
	if saved_run_probe.is_valid():
		return bool(saved_run_probe.call())
	return RunState.has_saved_run()


func take_mission_stake(tier_id: String, stake: int = -1) -> String:
	var t: Dictionary = (MissionBoard.tiers() as Dictionary).get(tier_id, {})
	if t.is_empty() or not bool(t.get("enabled", false)):
		return ""
	var cost := int(t.get("stake", 0))
	if cost <= 0 or (stake >= 0 and stake != cost):
		return ""
	if not mission_escrow.is_empty():
		if _saved_run_exists():
			return ""
		settle_mission_stake(false, false)   # run đã mất mà escrow còn: coi như bỏ = thua
	if stake_usable_shards() < cost:
		return ""
	# Nonce mỗi lần nhận cược (không theo ngày/bậc): run không cược không thể khớp escrow cũ.
	var mission_id := "ms_" + Crypto.new().generate_random_bytes(8).hex_encode()
	shard_pool -= cost   # trực tiếp, không qua spend(): cược lấy từ phần dùng được, không đụng starter_shard_locked
	ledger_add("shard", -cost, "mission_stake")
	var cap := int(MissionBoard.config().get("payout_cap", 0))
	var pay := MissionBoard.payout(tier_id)
	if cap > 0:
		pay = mini(pay, cap)
	mission_escrow = {"tier": tier_id, "mission_id": mission_id, "stake": cost, "payout": pay,
		"stone": int(t.get("stone", 0)), "t": int(Time.get_unix_time_from_system())}
	save_to_disk()
	return mission_id


## id của escrow đang mở ("" nếu không có). Lane M truyền id này vào header mission của RunState.
func current_mission_id() -> String:
	return String(mission_escrow.get("mission_id", ""))


## RunState.end_run gọi TRƯỚC clear_saved_run: chốt escrow (và lưu) khi save run còn đó, nên app bị kill
## giữa chừng không biến thắng thành thua (kill trước: run còn, escrow còn; kill sau: escrow đã trả).
## Chỉ đóng khi mission_id khớp escrow đang mở. Idempotent.
func settle_mission_for_run(mission_id: String, won: bool) -> bool:
	if mission_id.is_empty() or mission_id != current_mission_id():
		return false
	return settle_mission_stake(won, true)


## Đóng escrow. Thắng: trả `payout` (đã gồm cược, trần payout_cap) + Stone (trần stone_day_cap/ngày).
## Thua/bỏ: cược mất. Idempotent: không escrow -> trả false và không làm gì.
## Gọi `settle_mission_stake(false)` khi người chơi bấm Bỏ run (SettingsView) vì đường đó không qua end_run.
## H6 (13/10): bỏ run thì KHÔNG nhận Shard R của run (đường bỏ chỉ xoá save, không qua end_run). Thua/thắng bình thường vẫn cộng R.
func settle_mission_stake(won: bool, save: bool = true) -> bool:
	if mission_escrow.is_empty():
		return false
	var e := mission_escrow
	mission_escrow = {}   # xoá trước khi trả: lỗi giữa chừng cũng không trả hai lần
	if won:
		add_shards(int(e.get("payout", 0)), "mission_win", false)
		var day := today_utc()
		if String(mission_stone_day.get("day", "")) != day:
			mission_stone_day = {"day": day, "n": 0}
		var room := maxi(0, int(MissionBoard.config().get("stone_day_cap", 0)) - int(mission_stone_day["n"]))
		var st := mini(int(e.get("stone", 0)), room)
		if st > 0:
			mission_stone_day["n"] = int(mission_stone_day["n"]) + st
			add_stone(st, "mission_win", false)
	else:
		ledger_add("shard", 0, "mission_loss_%s" % String(e.get("tier", "")))
	if save:
		save_to_disk()
	return true


## Chỉ khi run KHÔNG bắt đầu được (begin_run lỗi): hoàn đúng số đã trừ, không payout. false nếu không có escrow.
## Từ chối khi run đã bắt đầu (có save run hoặc RunState không còn ở MENU).
func refund_mission_stake() -> bool:
	if mission_escrow.is_empty():
		return false
	if _saved_run_exists() or RunState.phase != RunState.RunPhase.MENU:
		return false
	var cost := int(mission_escrow.get("stake", 0))
	mission_escrow = {}
	shard_pool += cost
	ledger_add("shard", cost, "mission_refund")
	save_to_disk()
	return true


## L1 contract 5.2 — chấm đỏ cho màn `screen_id`. Chỉ đếm cái nhận được ngay, không tính toán nặng.
func badge_count(screen_id: String) -> int:
	match screen_id:
		"store":
			var cap := int((EconomyDBScript.get_table("gem").get("gift", {}) as Dictionary).get("balance_cap", 900))
			return 1 if int(Time.get_unix_time_from_system()) >= gem_claim_next_utc and gems_cache < cap else 0
		"echobox":
			return 1 if int(tickets.get("normal", 0)) > 0 else 0
	return 0


## Throws away everything in memory and loads whichever save `SaveStore.profile` now points at.
##
## `load_from_disk()` alone is not enough when the account changes: it only assigns the fields a
## save contains, so loading a fresh account's empty save would leave the previous player's
## shards, vault and pass sitting in memory. Called by AccountService on sign-in, sign-out and
## after applying a cloud save — never in the middle of a run.
func reload_from_store() -> void:
	shard_pool = 0
	battle_pass_xp = 0
	battle_pass_level = 1
	vault.clear()
	unlocks.clear()
	xp = 0
	bp_claimed.clear()
	perks = {}
	asc_max = 0
	runs = 0
	runs_with_battle = 0
	battle_counted_seed = -1
	wins = 0
	best = 0
	audio_music_volume = 1.0
	audio_sfx_volume = 1.0
	audio_muted = false
	reduce_flash = false
	daily_date = ""
	tutorial_seen = false
	_reset_economy_fields()
	load_from_disk()
	ensure_vault_heroes()


func _reset_economy_fields() -> void:
	save_version = SAVE_VERSION
	starter_granted = false
	stone = 0
	gems_cache = 0
	gem_claim_next_utc = 0
	gem_gift_day = ""
	tickets = {"normal": 0, "season": 0}
	echobox_pity = {}
	season_box = {}
	cosmetics_owned.clear()
	pass_season = {"id": "", "xp": 0, "level": 0, "claimed_free": []}
	vip_until_utc = 0
	vip_trial_used = false
	mission_house_level = 0
	mission_escrow = {}
	starter_shard_locked = 0
	mission_stone_day = {"day": "", "n": 0}
	asc_wins = {}
	full_a9_won = false
	aid_hints_off = false
	last_daily_reward_utc = ""
	daily_week = {"week": "", "n": 0}
	ledger = []


func load_from_disk() -> void:
	# Through SaveStore, not FileAccess: on a web build `user://` does not reliably survive a
	# page reload, and the failure is silent on both sides. See save_store.gd's header for the
	# measurement.
	var text := SaveStore.read_text(SAVE_PATH)
	if text.is_empty():
		_apply_starter_if_needed()
		return
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
	# Old saves have no counter: runs is the best available stand-in.
	runs_with_battle = int(parsed.get("runs_with_battle", runs))
	battle_counted_seed = int(parsed.get("battle_counted_seed", -1))
	wins = int(parsed.get("wins", 0))
	best = int(parsed.get("best", 0))
	# Defaults are "on at full", so a save written before audio existed reads as sound enabled
	# rather than as a player who had muted the game.
	audio_music_volume = clampf(float(parsed.get("audio_music_volume", 1.0)), 0.0, 1.0)
	audio_sfx_volume = clampf(float(parsed.get("audio_sfx_volume", 1.0)), 0.0, 1.0)
	audio_muted = bool(parsed.get("audio_muted", false))
	reduce_flash = bool(parsed.get("reduce_flash", false))
	daily_date = str(parsed.get("daily_date", ""))
	tutorial_seen = bool(parsed.get("tutorial_seen", false))
	# Migration backfill (design/gdd/onboarding-tutorial.md §5 "Migration save cũ", ported):
	# a save with real runs already on it predates this feature and must never be forced
	# through the tutorial retroactively.
	if not tutorial_seen and runs > 0:
		tutorial_seen = true
	_economy_from_json(parsed, text)


## Đọc field economy L1 và migrate save cũ. Xem SAVE_VERSION. Không ghi file.
func _economy_from_json(parsed: Dictionary, raw_text: String = "") -> void:
	var ver := int(parsed.get("save_version", 1))
	if ver < SAVE_VERSION and not raw_text.is_empty() and not SaveStore.exists_as(SaveStore.profile, V1_BACKUP_PATH):
		# notify=false: bản sao không được kích hoạt upload cloud.
		SaveStore.write_text_as(SaveStore.profile, V1_BACKUP_PATH, raw_text, false)
	stone = int(parsed.get("stone", 0))
	gems_cache = int(parsed.get("gems_cache", 0))
	gem_claim_next_utc = int(parsed.get("gem_claim_next_utc", 0))
	gem_gift_day = str(parsed.get("gem_gift_day", ""))
	var t = parsed.get("tickets", {})
	tickets = {"normal": int((t as Dictionary).get("normal", 0)) if t is Dictionary else 0,
		"season": int((t as Dictionary).get("season", 0)) if t is Dictionary else 0}
	echobox_pity = _pity_from_json(parsed.get("echobox_pity", {}))
	season_box = _season_box_from_json(parsed.get("season_box", {}))
	cosmetics_owned.clear()
	for c in (parsed.get("cosmetics_owned", []) as Array):
		cosmetics_owned.append(str(c))
	var ps = parsed.get("pass_season", {})
	pass_season = {"id": "", "xp": 0, "level": 0, "claimed_free": []}
	if ps is Dictionary:
		pass_season = {"id": str((ps as Dictionary).get("id", "")), "xp": int((ps as Dictionary).get("xp", 0)),
			"level": int((ps as Dictionary).get("level", 0)),
			"claimed_free": _ints((ps as Dictionary).get("claimed_free", [])),
			"day": str((ps as Dictionary).get("day", "")), "day_xp": int((ps as Dictionary).get("day_xp", 0)),
			"post30_claimed": int((ps as Dictionary).get("post30_claimed", 0)),
			"weekly": _weekly_from_json((ps as Dictionary).get("weekly", {}))}
	vip_until_utc = int(parsed.get("vip_until_utc", 0))
	vip_trial_used = bool(parsed.get("vip_trial_used", false))
	mission_house_level = int(parsed.get("mission_house_level", 0))
	mission_escrow = _escrow_from_json(parsed.get("mission_escrow", {}))
	starter_shard_locked = maxi(0, int(parsed.get("starter_shard_locked", 0)))
	var msd = parsed.get("mission_stone_day", {})
	mission_stone_day = {"day": String(msd.get("day", "")), "n": int(msd.get("n", 0))} if msd is Dictionary else {"day": "", "n": 0}
	asc_wins = _int_values(parsed.get("asc_wins", {}))
	full_a9_won = bool(parsed.get("full_a9_won", false))
	aid_hints_off = bool(parsed.get("aid_hints_off", false))
	last_daily_reward_utc = str(parsed.get("last_daily_reward_utc", ""))
	var dw = parsed.get("daily_week", {})
	daily_week = {"week": String(dw.get("week", "")), "n": maxi(0, int(dw.get("n", 0)))} if dw is Dictionary else {"week": "", "n": 0}
	ledger = (parsed.get("ledger", []) as Array).duplicate(true) if parsed.get("ledger", []) is Array else []
	starter_granted = bool(parsed.get("starter_granted", false))
	if ver < SAVE_VERSION:
		_migrate_pre_economy()
	save_version = SAVE_VERSION
	_apply_starter_if_needed()


## v1 -> v2 (docs/architecture/server-authoritative-rng.md 9.2): unlock/perk/Pass cũ và số dư Shard
## cũ không nhập; chỉ còn khoản khởi đầu cố định. Giữ vault, thống kê run, asc_max, cài đặt.
func _migrate_pre_economy() -> void:
	unlocks.clear()
	perks = {}
	shard_pool = 0
	battle_pass_xp = 0
	battle_pass_level = 1
	xp = 0
	bp_claimed.clear()
	starter_granted = false


## Khoản khởi đầu cố định, một lần (daily.json -> starter, SỐ TẠM). Tài khoản mới và save vừa migrate.
func _apply_starter_if_needed() -> void:
	if starter_granted:
		return
	var st: Dictionary = EconomyDBScript.get_table("daily").get("starter", {})
	shard_pool += int(st.get("shards", 0))
	starter_shard_locked = int(st.get("shards", 0))
	gems_cache += int(st.get("gems", 0))
	tickets["normal"] = int(tickets.get("normal", 0)) + int(st.get("tickets", 0))
	starter_granted = true
	if int(st.get("shards", 0)) > 0:
		ledger_add("shard", int(st.get("shards", 0)), "starter")
	if int(st.get("tickets", 0)) > 0:
		ledger_add("ticket", int(st.get("tickets", 0)), "starter")
	if int(st.get("gems", 0)) > 0:
		ledger_add("gem", int(st.get("gems", 0)), "starter")


static func _weekly_from_json(raw) -> Dictionary:
	var out: Dictionary = {}
	if not (raw is Dictionary):
		return out
	for k in (raw as Dictionary):
		var w = (raw as Dictionary)[k]
		if not (w is Dictionary):
			continue
		var claimed: Array = []
		for c in (w as Dictionary).get("claimed", []):
			claimed.append(str(c))
		out[String(k)] = {"runs": int((w as Dictionary).get("runs", 0)), "wins": int((w as Dictionary).get("wins", 0)),
			"boss": int((w as Dictionary).get("boss", 0)), "claimed": claimed}
	return out


static func _season_box_from_json(raw) -> Dictionary:
	var out: Dictionary = {}
	if not (raw is Dictionary):
		return out
	for sid in (raw as Dictionary):
		var v = (raw as Dictionary)[sid]
		if not (v is Dictionary):
			continue
		var e := {"opens": int(v.get("opens", 0)), "c_epic": int(v.get("c_epic", 0)), "c_legendary": int(v.get("c_legendary", 0)),
			"c_mythic": int(v.get("c_mythic", 0)), "day": str(v.get("day", "")), "day_pulls": int(v.get("day_pulls", 0)),
			"owned": [], "milestones": []}
		for k in ["owned", "milestones"]:
			if v.get(k, []) is Array:
				for x in v[k]:
					e[k].append(str(x))
		out[String(sid)] = e
	return out


static func _pity_from_json(raw) -> Dictionary:
	var out: Dictionary = {}
	if not (raw is Dictionary):
		return out
	for k in (raw as Dictionary):
		var v = (raw as Dictionary)[k]
		out[String(k)] = str(v) if v is String else int(v)
	return out

func is_newcomer() -> bool:
	return runs_with_battle < int(EconomyDBScript.get_table("missions").get("newcomer_runs", 5))


## Called by RunState when a battle of the run with `run_seed` finishes. Once per run.
func note_run_battle(run_seed_key: int) -> void:
	if battle_counted_seed == run_seed_key:
		return
	battle_counted_seed = run_seed_key
	runs_with_battle += 1
	save_to_disk()


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
		"runs_with_battle": runs_with_battle,
		"battle_counted_seed": battle_counted_seed,
		"wins": wins,
		"best": best,
		"audio_music_volume": audio_music_volume,
		"audio_sfx_volume": audio_sfx_volume,
		"audio_muted": audio_muted,
		"reduce_flash": reduce_flash,
		"daily_date": daily_date,
		"tutorial_seen": tutorial_seen,
		"save_version": SAVE_VERSION,
		"starter_granted": starter_granted,
		"stone": stone,
		"gems_cache": gems_cache,
		"gem_claim_next_utc": gem_claim_next_utc,
		"gem_gift_day": gem_gift_day,
		"tickets": tickets,
		"echobox_pity": echobox_pity,
		"season_box": season_box,
		"cosmetics_owned": cosmetics_owned,
		"pass_season": pass_season,
		"vip_until_utc": vip_until_utc,
		"vip_trial_used": vip_trial_used,
		"mission_house_level": mission_house_level,
		"mission_escrow": mission_escrow,
		"starter_shard_locked": starter_shard_locked,
		"mission_stone_day": mission_stone_day,
		"asc_wins": asc_wins,
		"full_a9_won": full_a9_won,
		"aid_hints_off": aid_hints_off,
		"last_daily_reward_utc": last_daily_reward_utc,
		"daily_week": daily_week,
		"ledger": ledger,
	}
	if not SaveStore.write_text(SAVE_PATH, JSON.stringify(data, "\t")):
		push_error("MetaState: could not write %s — this player's progress is not being saved"
			% SAVE_PATH)


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
	starter_shard_locked = maxi(0, starter_shard_locked - cost)
	unlocks.append(id)
	save_to_disk()
	return ""


# ===========================================================================
# What the meta grants a run (~= JS newRun(), client.html:4669-4673)
# ===========================================================================

## RANKED (B3, Liam 12/10): unlock cày ĐƯỢC dùng trong ranked (người cày không thua người nạp).
## Ranked nhận bonus của các UNLOCK (u_reroll, u_reroll2, u_hp, u_hp2, u_start), nhưng KHÔNG nhận
## perk của Pass cũ và không nhận reward-reroll bonus: những thứ đó không phải unlock cày.
## HỆ QUẢ CHO VERIFIER (làn A, F9 trong docs/architecture/server-authoritative-rng.md): một replay
## phía server không thể đọc MetaState của máy người chơi. Verifier phải nhận loadout unlock được
## TIÊM VÀO (từ header run do server giữ) rồi tính bonus từ đó, không gọi hàm này. Tới khi A xong,
## replay ranked chỉ khớp trên chính máy có cùng unlock.
func run_bonuses(is_ranked: bool) -> Dictionary:
	var reroll := 0
	if has_unlock("u_reroll"):
		reroll += 1
	if has_unlock("u_reroll2"):
		reroll += 1
	if not is_ranked:
		reroll += int(perks.get("reroll", 0))

	var hp := 0
	if has_unlock("u_hp"):
		hp += 3
	if has_unlock("u_hp2"):
		hp += 2
	if not is_ranked:
		hp += 4 * int(perks.get("hp4", 0))

	# JS: sr = u_start + perks.relic0 + perks.relic1 (a count), srRar = perks.relic1 ? 1 : 0.
	# One starting relic is granted when any of those is present; the rarity ceiling rises to
	# Rare only with the relic1 perk.
	var perk_relic: bool = not is_ranked and (int(perks.get("relic0", 0)) > 0 or int(perks.get("relic1", 0)) > 0)
	var grants_relic: bool = has_unlock("u_start") or perk_relic
	var rarity_cap: int = -1
	if grants_relic:
		rarity_cap = 1 if (not is_ranked and int(perks.get("relic1", 0)) > 0) else 0

	# src/client.html:4681 — the 'rrw' perk lets a reward set be rerolled more than once per node.
	var reward_rerolls := 1 + (0 if is_ranked else int(perks.get("rrw", 0)))

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
	ContentDB.heroes[vault_key(entry)] = _hero_def_from_vault(entry)


## THE TWO DIE SCHEMAS, and the bug this exists to close (found 2026-09-21 by VLT-05's own
## screenshot: a vault Axie picked into Team Select drew six blank faces valued 0, while the
## Vault card two screens earlier drew the same die correctly).
##
## src/data.js has ONE face shape, `F(p,t,v,...k) -> {p,t,v,k,r}`, and everything in the JS build
## reads it. This port renamed those fields for the hand-written hero table — `ContentDB._f()`
## emits `{part, type, value, keywords, rarity}` — and the whole engine was written against the
## long names (`combat_engine` line 779 reads `f.value`, line 387 reads `f.type`). But
## `axie_to_die.gd` was ported from the JS verbatim and still emits the SHORT names, and
## `_register_vault_hero()` used to hand that record to `ContentDB.heroes` untouched. Every key
## the engine asked for was missing, and `Dictionary.get()` answers a missing key with the
## default — so an imported Axie rolled six 0-damage blank faces, silently, in real combat.
## `t_vault` checked the die had six entries and never looked inside one, which is exactly the
## drift its own docstring warned about.
##
## The STORED record keeps the short names: it is the save format and the shape a server-side
## replay would re-derive, and rewriting it would break every save already on disk. The
## conversion happens here, at the one point where a vault record becomes a playable hero.
static func _hero_def_from_vault(entry: Dictionary) -> Dictionary:
	var hero := entry.duplicate(true)
	var faces: Array = []
	for f in (entry.get("die", []) as Array):
		if not (f is Dictionary):
			continue
		var src: Dictionary = f
		faces.append({
			"part": String(src.get("p", "blank")),
			"type": String(src.get("t", "blank")),
			"value": int(src.get("v", 0)),
			"keywords": (src.get("k", []) as Array).duplicate(),
			"rarity": int(src.get("r", 0)),
		})
	hero["die"] = faces
	return hero


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
	var stone_n := int((EconomyDBScript.get_table("daily").get("daily_reward", {}) as Dictionary).get("stone", 0))
	if stone_n > 0:
		add_stone(stone_n, "daily", false)
	var wk := PassV2.week_key(today)
	if String(daily_week.get("week", "")) != wk:
		daily_week = {"week": wk, "n": 0}
	daily_week["n"] = int(daily_week["n"]) + 1
	PassV2.add_daily_bonus_xp(self, today)   # +100 XP Pass v2 (ngoài mùa: không làm gì)
	return true


## Đã nhận daily hôm nay (= đã xong một run hôm nay: claim_daily_mission chạy ở cuối run). Cho chấm ngày M8.
func daily_done_today() -> bool:
	return daily_date == today_utc()


## Số ngày đã nhận daily trong tuần UTC hiện tại (0..7).
func weekly_daily_days() -> int:
	if String(daily_week.get("week", "")) != PassV2.week_key(today_utc()):
		return 0
	return int(daily_week.get("n", 0))


## Ngưỡng ngày để ăn thưởng tuần (daily.json -> weekly_bonus.min_days). Chưa có logic trao thưởng tuần.
func weekly_daily_min_days() -> int:
	return int((EconomyDBScript.get_table("daily").get("weekly_bonus", {}) as Dictionary).get("min_days", 0))
