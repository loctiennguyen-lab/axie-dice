class_name LocalGemWallet
extends GemWallet
## Bản local của GemWallet: Gem nằm trong save (field của `store`, thường là MetaState).
## `store` cần có: gems_cache:int, gem_claim_next_utc:int, gem_gift_day:String,
## vip_until_utc:int, vip_trial_used:bool, và hàm `ledger_add(cur, delta, reason)` + `save_to_disk()`.
## Test truyền stub thay MetaState để không chạm save thật.
##
## LƯU Ý (ghi rõ để khỏi hiểu nhầm): ở bản local người chơi sửa save là có Gem vô hạn và
## server không kiểm được trần 900. Chấp nhận cho playtest nội bộ nếu LIAM-2 chọn (a).

const _Econ := preload("res://scripts/meta/economy_db.gd")

var store: Object


func _init(p_store: Object) -> void:
	store = p_store


func balance() -> int:
	return int(store.gems_cache)


func spend(n: int, reason: String) -> bool:
	if n < 0 or int(store.gems_cache) < n:
		return false
	if n == 0:
		return true
	store.gems_cache = int(store.gems_cache) - n
	store.ledger_add("gem", -n, reason)
	store.save_to_disk()
	return true


func grant(n: int, tag: String) -> void:
	if n <= 0:
		return
	store.gems_cache = int(store.gems_cache) + n
	store.ledger_add("gem", n, "grant:" + tag)
	store.save_to_disk()


## 300/ngày, trần số dư 900 (gift.balance_cap), idempotent theo ngày UTC. Chỉ ghi nhận ngày khi
## thực sự cộng được: đang ở trần thì ngày chưa bị "dùng", và lúc đã tiêu bớt vẫn nhận được.
## Quà mùa Pass (season_gift) đi đường `grant`, không bị trần này.
func claim_daily_gift(now_unix: int) -> Dictionary:
	var cfg: Dictionary = _Econ.get_table("gem").get("gift", {})
	var per_day := int(cfg.get("per_day", 300))
	var cap := int(cfg.get("balance_cap", 900))
	var today := GemWallet.utc_day(now_unix)
	var next := GemWallet.next_utc_midnight(now_unix)
	if String(store.gem_gift_day) == today:
		return {"ok": false, "granted": 0, "reason": "already_claimed", "next_utc": next}
	var room := cap - int(store.gems_cache)
	if room <= 0:
		return {"ok": false, "granted": 0, "reason": "at_cap", "next_utc": now_unix}
	var amount := mini(per_day, room)
	store.gem_gift_day = today
	store.gem_claim_next_utc = next
	store.gems_cache = int(store.gems_cache) + amount
	store.ledger_add("gem", amount, "grant:" + String(cfg.get("source_tag", "playtest_grant")))
	store.save_to_disk()
	return {"ok": true, "granted": amount, "reason": "", "next_utc": next}
