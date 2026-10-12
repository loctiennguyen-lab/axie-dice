class_name RelicSlots
extends RefCounted
## Relic slot model: 8 passive + 3 active slots, 1 G multiplier slot + 2 A multiplier slots.
## Implements design/proposals/relic-set-v2.md §3.1 and production/l1-interfaces.md §2.4.
##
## Static and pure: nothing here touches RunState. RunState.acquire_relic()/sell_relic() (lane A)
## call these to decide whether a relic may be taken, and what must be sold first.
## Numbers (8/7/3/4, 1 G, 2 A, sell %) come from resources/relics/relic_tuning.tres.
##
## SKELETON (14/10): the bodies return "always accept" so callers can wire up against the real
## signatures with no behaviour change. The real slot rules arrive in the next commit.

const TUNING_PATH := "res://resources/relics/relic_tuning.tres"


## {passive: 8|7, active: 3|4, g: 1, a: 2}. `owned_ids` is read for hollowchalice (+1 active).
static func capacity(_ascension: int, _owned_ids: Array) -> Dictionary:
	return {"passive": 8, "active": 3, "g": 1, "a": 2}


## Decide whether `new_id` may be taken now. See relic-set-v2 §3.1 "Bảng luật ô đầy".
## Returns {ok: bool, needs_sell: bool, sell_from: Array[String], reason: String}.
## `forced` = a forced pact (A6 first boss / A10 every boss): the player may not cancel.
static func check_add(_owned_ids: Array, _stickers: Dictionary, _new_id: String,
		_ascension: int, _forced: bool) -> Dictionary:
	return {"ok": true, "needs_sell": false, "sell_from": [] as Array[String], "reason": ""}


## Sell price in Gene Shards: 50% of the rarity buy price, 40% from A1, rounded down.
static func sell_price(_relic_id: String, _ascension: int) -> int:
	return 0


## True for pacts (boss-only relics with a drawback).
static func is_pact(_relic_id: String) -> bool:
	return false
