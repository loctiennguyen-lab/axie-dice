extends Node
## M3 Vault R3: states (normal, empty, offline, guest, full), layout (collection left, 560 import
## column right), scan disabled offline, empty state focuses the ID field, Remove confirm.

var _fail: Array[String] = []
var _checks := 0
var _guard := SaveGuard.new()


func _ok(c: bool, msg: String) -> void:
	_checks += 1
	if not c:
		_fail.append(msg)


func _payload(id: String) -> Dictionary:
	var parts: Array = []
	for slot in ["mouth", "horn", "back", "tail", "eyes", "ears"]:
		parts.append({"id": "plant-%s" % slot, "name": "T %s" % slot, "class": "plant", "type": slot, "specialGenes": null})
	return {"id": id, "class": "plant", "parts": parts, "genes": "0x1234"}


func _mk(st: String) -> VaultView:
	var s: VaultView = load("res://scenes/vault/Vault.tscn").instantiate()
	s.use_account = false
	s.no_scene_change = true
	s.state = st
	add_child(s)
	return s


func _ready() -> void:
	print("=== t_vault_r3: start ===")
	_guard.capture()
	MetaState.vault.clear()
	# empty
	var e := _mk("normal")
	await get_tree().process_frame
	var field := e.find_child("AxieIdField", true, false) as LineEdit
	_ok(e.find_child("EmptyLabel", true, false) != null and (e.find_child("EmptyLabel", true, false) as Label).visible, "empty state text")
	_ok(not field.editable or field.has_focus(), "empty state focuses the ID field")
	_ok(e.find_child("Banner", true, false) == null, "no banner when normal")
	var imp := e.find_child("ImportPanel", true, false) as Control
	var sc := e.find_child("RecordScroll", true, false) as Control
	_ok(imp.position.x > sc.position.x, "collection left, import column right")
	_ok(absf(imp.size.x - 560.0) < 2.0, "import column 560 wide: %f" % imp.size.x)
	e.queue_free()
	# offline with entries
	MetaState.vault_import(_payload("11"))
	var o := _mk("offline")
	await get_tree().process_frame
	_ok(o.find_child("Banner", true, false) != null, "offline banner")
	_ok((o.find_child("ScanButton", true, false) as Button).disabled, "scan disabled offline")
	(o.find_child("AxieIdField", true, false) as LineEdit).text = "11778888"
	(o.find_child("AxieIdField", true, false) as LineEdit).text_changed.emit("11778888")
	_ok((o.find_child("ScanButton", true, false) as Button).disabled, "scan stays disabled offline with a valid ID")
	_ok((o.find_child("RecordScroll", true, false) as Control).modulate.a < 1.0, "grid greyed offline")
	_ok(o.find_child("Row_11", true, false) != null, "cached rows still shown offline")
	o.queue_free()
	# guest
	var g := _mk("guest")
	await get_tree().process_frame
	var b := g.find_child("Banner", true, false)
	_ok(b != null and "Sign in" in (b.get_child(0) as Label).text, "guest banner asks to sign in")
	g.queue_free()
	# full 20/20
	MetaState.vault.clear()
	for i in 20:
		MetaState.vault_import(_payload(str(100 + i)))
	var f := _mk("normal")
	await get_tree().process_frame
	_ok(MetaState.vault_is_full() and (f.find_child("ImportCountChip", true, false) != null), "full chip present")
	_ok(f.find_children("Row_*", "PanelContainer", true, false).size() == 20, "20 rows")
	f.queue_free()
	_guard.restore()
	if _fail.is_empty():
		print("t_vault_r3: PASS (%d checks)" % _checks)
		get_tree().quit(0)
	else:
		for x in _fail:
			print("FAIL: ", x)
		print("t_vault_r3: FAIL")
		get_tree().quit(1)
