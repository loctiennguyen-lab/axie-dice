class_name StoreCatalog
extends RefCounted
## Store L1: mọi thứ giá Gem mua được bằng Gem (tặng), nút USD tắt (gem.json -> store).
## Aid mua trong run đi qua AidCatalog; ở đây chỉ vé bundle và cosmetic. Giá cosmetic là GIÁ TẠM.
## `store` cần: tickets, cosmetics_owned, spend(cur,n,reason,save), ledger_add, save_to_disk.

const _Econ := preload("res://scripts/meta/economy_db.gd")


static func _cfg() -> Dictionary:
	return _Econ.get_table("gem").get("store", {})


static func usd_enabled() -> bool:
	return bool(_cfg().get("usd_buttons_enabled", false))


static func bundles() -> Array:
	return _cfg().get("ticket_bundles", [])


static func cosmetic_price(rarity: String) -> int:
	return int((_cfg().get("cosmetic_prices_temp", {}) as Dictionary).get(rarity, 0))


## Mua gói vé theo số vé (6/15/40/100). Vé bundle không tăng bậc giá. Trả "" hoặc lý do.
static func buy_ticket_bundle(store: Object, count: int) -> String:
	var gems := -1
	for b in bundles():
		if int((b as Dictionary).get("tickets", 0)) == count:
			gems = int((b as Dictionary).get("gems", 0))
	if gems < 0:
		return "unknown_bundle"
	if not store.spend("gem", gems, "store:bundle%d" % count):
		return "no_gems"
	EchoBox.grant_tickets(store, count, "bundle")
	store.save_to_disk()
	return ""


## Mua cosmetic giá Gem (rare/epic/legendary/mythic). Trả "" hoặc lý do.
static func buy_cosmetic(store: Object, item_id: String, rarity: String) -> String:
	var price := cosmetic_price(rarity)
	if price <= 0:
		return "not_for_sale"
	if store.cosmetics_owned.has(item_id):
		return "owned"
	if not store.spend("gem", price, "store:cosmetic:" + item_id):
		return "no_gems"
	store.cosmetics_owned.append(item_id)
	store.save_to_disk()
	return ""
