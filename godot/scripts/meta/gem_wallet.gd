class_name GemWallet
extends RefCounted
## Ví Gem (Lunar Gem) phía client — INTERFACE. [LIAM-2] chưa chốt Gem ở server hay ở save, nên
## mọi nơi trong game chỉ nói chuyện với lớp này. Hôm nay: LocalGemWallet (đọc/ghi MetaState).
## Sau này lane S thay bằng bản server (cùng chữ ký), không ai khác phải sửa.
## Số liệu: assets/data/economy/gem.json (monetization-v1 T2a, phase-plan-v1 "Gem tặng ở L1").

## Số dư hiện có (bản server: bộ đệm hiển thị).
func balance() -> int:
	push_error("GemWallet.balance: chưa cài đặt")
	return 0


func can_afford(n: int) -> bool:
	return n >= 0 and balance() >= n


## Trừ n Gem. false nếu không đủ (không trừ gì). save=false: người gọi sẽ save sau (một lần cho cả giao dịch). `reason` vào sổ cái, vd "aid:R1".
func spend(_n: int, _reason: String, _save: bool = true) -> bool:
	push_error("GemWallet.spend: chưa cài đặt")
	return false


## Cộng Gem. `tag` là thẻ nguồn ("playtest_grant", "season_gift", "vip_trial"...).
func grant(_n: int, _tag: String) -> void:
	push_error("GemWallet.grant: chưa cài đặt")


## Ví này cấp Gem được ngay phía client (grant() có hiệu lực)? Local: true. Remote: false cho tới khi
## server có endpoint quà mùa; chỗ nào cần cấp Gem (quà Pass) phải kiểm cái này trước.
func grants_locally() -> bool:
	return false


## Nhận Gem tặng theo ngày. `now_unix` truyền vào để test được (UTC).
## Trả {ok:bool, granted:int, reason:String, next_utc:int}. reason: "" | "already_claimed" | "at_cap".
func claim_daily_gift(_now_unix: int) -> Dictionary:
	push_error("GemWallet.claim_daily_gift: chưa cài đặt")
	return {"ok": false, "granted": 0, "reason": "unimplemented", "next_utc": 0}


## Bản bất đồng bộ: done(result:Dictionary) cùng dạng với claim_daily_gift. Local trả ngay; Remote
## (RemoteGemWallet) gọi server rồi mới done. UI nên dùng hàm này.
func claim_daily_gift_async(done: Callable) -> void:
	var r := claim_daily_gift(int(Time.get_unix_time_from_system()))
	if done.is_valid():
		done.call(r)


## Unix của 00:00 UTC kế tiếp sau `now_unix` (cho badge / đếm giờ).
static func next_utc_midnight(now_unix: int) -> int:
	return (now_unix / 86400 + 1) * 86400


## Ngày UTC "YYYY-MM-DD" của một mốc unix.
static func utc_day(now_unix: int) -> String:
	var d := Time.get_datetime_dict_from_unix_time(now_unix)
	return "%04d-%02d-%02d" % [int(d["year"]), int(d["month"]), int(d["day"])]
