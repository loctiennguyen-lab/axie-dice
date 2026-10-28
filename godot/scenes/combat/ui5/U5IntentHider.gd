class_name U5IntentHider
extends Node
## UI-05 b1 lane E: keeps every live enemy's IntentBlock at alpha 0 while the "Your turn" band plays, so the intent
## reveal pops them in instead of them showing, vanishing and popping (a plate rebuilt during the band comes back
## at alpha 1; this re-hides it every frame). stop() is called when the reveal starts; a second later any block
## the reveal did not reach is put back to alpha 1. Holds the combat view by WeakRef; frees itself.

var _vw: WeakRef
var _until_ms := 0
var _stopped := false


static func start(layer: Node, v: CombatView, max_sec: float) -> U5IntentHider:
	var old := layer.get_node_or_null("IntentHider")
	if old != null:
		old.name = "IntentHiderOld"
		old.queue_free()
	var h := U5IntentHider.new()
	h.name = "IntentHider"
	h._vw = weakref(v)
	h._until_ms = Time.get_ticks_msec() + int(max_sec * 1000.0)
	layer.add_child(h)
	h._apply(0.0)
	return h


## The reveal has started (or will not): stop hiding, restore stragglers a second later.
func stop() -> void:
	if _stopped:
		return
	_stopped = true
	if is_inside_tree():
		get_tree().create_timer(1.0).timeout.connect(_restore)   # bound to self: gone with the scene, no stale capture


func _process(_dt: float) -> void:
	if _vw.get_ref() == null:
		queue_free()
		return
	if _stopped:
		return
	if Time.get_ticks_msec() > _until_ms:
		stop()
		return
	_apply(0.0)


func _apply(alpha: float, only_hidden := false) -> void:
	var v: CombatView = _vw.get_ref()
	if v == null or v._combat == null:
		return
	for e in v._combat.enemies:
		if e.hp <= 0:
			continue
		var p: Variant = v._portraits.get(e.uid)
		if not (p is UnitPortrait) or not is_instance_valid(p):
			continue
		var blk: Control = (p as UnitPortrait).intent_block()
		if blk != null and (not only_hidden or blk.modulate.a < 0.01):
			blk.modulate.a = alpha


func _restore() -> void:
	_apply(1.0, true)
	queue_free()
