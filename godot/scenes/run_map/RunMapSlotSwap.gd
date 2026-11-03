class_name RunMapSlotSwap
extends RefCounted
## Slot swap sheet for a full relic bar. Split out of RunMapController (UI-05 b23 lane 0b): code moved as-is, state stays on the controller (`ctrl`).
## The controller keeps a same-name forwarder for every method here.


const MakeRoomSheet := preload("res://scenes/run_map/ui5/MakeRoomSheet.gd")

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
		var same_pool := RelicSlots.is_core(od) if RelicSlots.is_core(nd) else RelicSlots._is_active(od) == active
		if not sell_from.has(id) and not (eternal and same_pool):
			continue
		cells.append({"id": id, "name": UI3.title_case(UI3.player_text(String(od.name))),
			"kind": tr("Active") if RelicSlots._is_active(od) else tr("Passive"),
			"sell": RelicSlots.sell_price(id, RunState.ascension), "eternal": eternal})
	var title_text := ""
	var nm := UI3.title_case(UI3.player_text(String(nd.name)))
	var rule := ""
	if RelicSlots.is_core(nd):
		# Real Core: the 6 Core slots are what is full (owned_cores excludes the Run Rule slot).
		rule = MakeRoomSheet.room_line(true, RelicSlots.owned_cores(RunState.owned_relic_ids).size(),
			RelicSlots.tuning().core_slots, nm)
	else:
		rule = MakeRoomSheet.room_line(false, -1, int(cap["active"] if active else cap["passive"]), nm)
	var sheet := MakeRoomSheet.build(UI3.title_case(UI3.player_text(String(nd.name))), int(nd.rarity), rule, cells,
		func(sell_id: String) -> void:
			var ok := RunState.acquire_relic(key, "reward", sell_id)
			sheet_closed(ok, reward),
		func() -> void: sheet_closed(false, {}, true), title_text)
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
