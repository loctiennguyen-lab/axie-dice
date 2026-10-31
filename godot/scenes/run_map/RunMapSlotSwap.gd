class_name RunMapSlotSwap
extends RefCounted
## Slot swap sheet for a full relic bar. Split out of RunMapController (UI-05 b23 lane 0b): code moved as-is, state stays on the controller (`ctrl`).
## The controller keeps a same-name forwarder for every method here.


var ctrl: RunMapController


func _init(owner_ctrl: RunMapController) -> void:
	ctrl = owner_ctrl

## Spec 32: the slot kind of the new relic is full. The sale goes through RunState.acquire_relic (logged as
## swap_on_full), then the normal pick applies. Leave it returns to the cards with nothing taken.
func open_slot_swap(reward: Dictionary, chk: Dictionary) -> void:
	var key := String(reward.get("key", ""))
	var nd = RelicRegistry.get_def(key)
	if nd == null or ctrl._overlay_root.find_child("SlotSwapSheet", true, false) != null:
		return   # one sheet at a time: a second Take while it is open must not stack another
	var active: bool = RelicSlots._is_active(nd)
	var cap := RelicSlots.capacity(RunState.ascension, RunState.owned_relic_ids)
	var cells: Array = []
	var sell_from: Array = chk["sell_from"]
	for oid in RunState.owned_relic_ids:
		var id := String(oid)
		var od = RelicRegistry.get_def(id)
		if od == null or id.begins_with("__"):
			continue
		var eternal := String(RunState.relic_stickers.get(id, "")) == RelicSlots.STICKER_ETERNAL
		if not sell_from.has(id) and not (eternal and RelicSlots._is_active(od) == active):
			continue
		cells.append({"id": id, "name": UI3.title_case(UI3.player_text(String(od.name))),
			"kind": tr("Active") if RelicSlots._is_active(od) else tr("Passive"),
			"sell": RelicSlots.sell_price(id, RunState.ascension), "eternal": eternal})
	var rule := (tr("Active slots are full (%d of %d). Sell one to take the new Core.") if active
		else tr("Passive slots are full (%d of %d). Sell one to take the new Core.")) % [
		cells.size(), int(cap["active"] if active else cap["passive"])]
	var dsc := UI3.describe(RewardGenerator.relic_desc(nd))
	var sheet := UI3.slot_swap_sheet(tr("Make room"), UI3.title_case(UI3.player_text(String(nd.name))),
		("MP %d · " % int(dsc["mp"]) if int(dsc["mp"]) >= 0 else "") + String(dsc["text"]), rule, cells,
		false, func(sell_id: String) -> void:
			var ok := RunState.acquire_relic(key, "reward", sell_id)
			sheet_closed(ok, reward),
		func() -> void: sheet_closed(false, {}, true), 3 if active else 4)
	sheet.name = "SlotSwapSheet"
	ctrl._overlay_root.add_child(sheet)


## Closes the swap sheet. ok: the swap was made, so finish the pick. Otherwise the cards stay as they were.
func sheet_closed(ok: bool, reward: Dictionary, _left := false) -> void:
	var sh := ctrl._overlay_root.find_child("SlotSwapSheet", true, false)
	if sh != null:
		sh.get_parent().remove_child(sh)
		sh.queue_free()
	if ok:
		ctrl._apply_and_finish(reward)
