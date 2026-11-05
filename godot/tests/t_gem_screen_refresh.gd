extends Node
## Hotfix 5/11 (after the Land Gem 0 bug): Store and Daily read the Gem wallet while they build, and the server
## wallet can answer later. Both screens now ask the wallet to refresh on open and redraw when it answers.
## A fake wallet with refresh() holds the answer back; the test checks the request was made, then answers with
## 900 and checks Daily's "You hold" and Store's gift note follow. The real wallet and save are put back.

class FakeRemoteWallet extends GemWallet:
	var b := 0
	var calls := 0
	var pending: Array[Callable] = []

	func balance() -> int:
		return b

	func refresh(done: Callable = Callable()) -> void:
		calls += 1
		pending.append(done)

	func answer(v: int) -> void:
		b = v
		for d in pending:
			if d.is_valid():
				d.call(true)
		pending.clear()


const _Econ := preload("res://scripts/meta/economy_db.gd")

var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0


func _ok(c: bool, m: String) -> void:
	_checks += 1
	if not c:
		_fails.append(m)


func _texts(root: Node) -> String:
	var s := ""
	for n in root.find_children("*", "", true, false):
		if n is Label:
			s += (n as Label).text + "\n"
		elif n is Button:
			s += (n as Button).text + "\n"
	return s


func _wait(n := 3) -> void:
	for _i in n:
		await get_tree().process_frame


func _ready() -> void:
	_guard.capture()
	var real: GemWallet = MetaState.gem_wallet()
	var cap := int(_Econ.get_table("gem").get("gift", {}).get("balance_cap", 900))

	# Daily
	var w := FakeRemoteWallet.new()
	MetaState.set_gem_wallet(w)
	var d: DailyScreen = load("res://scenes/daily/DailyScreen.tscn").instantiate()
	d.use_account = false
	d.state = "normal"
	d.no_scene_change = true
	d.test_mode = true
	add_child(d)
	await _wait()
	_ok(w.calls >= 1, "Daily asks the Gem wallet to refresh on open (calls %d)" % w.calls)
	_ok(_texts(d).contains("You hold\n" + UI3.fmt(0)), "Daily shows the cached 0 before the wallet answers")
	w.answer(cap)
	await _wait()
	_ok(_texts(d).contains("You hold\n" + UI3.fmt(cap)), "Daily 'You hold' follows the wallet once it answers")
	d.queue_free()
	await _wait(1)

	# Store
	var w2 := FakeRemoteWallet.new()
	MetaState.set_gem_wallet(w2)
	var s: StoreScreen = load("res://scenes/store/StoreScreen.tscn").instantiate()
	s.use_account = false
	s.state = "normal"
	add_child(s)
	await _wait()
	_ok(w2.calls >= 1, "Store asks the Gem wallet to refresh on open (calls %d)" % w2.calls)
	var before := _texts(s)
	w2.answer(cap)
	await _wait()
	var after := _texts(s)
	_ok(s.gems() == cap, "Store reads the answered balance")
	_ok(after.contains("You hold %d, nothing to claim" % cap) and not before.contains("You hold %d, nothing to claim" % cap),
		"Store redraws its Gem gift note when the wallet answers")
	s.queue_free()
	await _wait(1)

	MetaState.set_gem_wallet(real)
	_guard.restore()
	if _fails.is_empty():
		print("t_gem_screen_refresh: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
	else:
		for f in _fails:
			print("FAIL: " + f)
		get_tree().quit(1)
