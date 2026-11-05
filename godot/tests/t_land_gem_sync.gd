extends Node
## Hotfix 5/11: on the web the server Gem wallet answered after Land had built its HUD, and the CurrencyPlate kept
## showing Gem 0 while /api/wallet said 900. Land now follows the wallet's cached balance. This builds Land with a
## wallet at 0, moves the balance to 900 afterwards (what RemoteGemWallet.refresh() does), and checks GemValue
## follows; then swaps in a new wallet after the HUD (sign-in) and checks again. The real wallet is put back.

class FakeWallet extends GemWallet:
	var b := 0

	func balance() -> int:
		return b


var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0


func _ok(c: bool, m: String) -> void:
	_checks += 1
	if not c:
		_fails.append(m)


func _gem_text(h: Node) -> String:
	var cell := h.find_child("GemValue", true, false)
	var v := cell.get_node_or_null("Value") as Label if cell != null else null
	return v.text if v != null else "<none>"


func _wait(n := 3) -> void:
	for _i in n:
		await get_tree().process_frame


func _ready() -> void:
	_guard.capture()
	LandNav.dry_run = true
	MetaState.tutorial_seen = true
	var real: GemWallet = MetaState.gem_wallet()
	var w := FakeWallet.new()
	MetaState.set_gem_wallet(w)
	var prev_qa: Dictionary = LandHub.qa
	var prev_tier: int = LandHub.tier_override
	LandHub.qa = {"guest": false, "newcomer": false, "first_launch": false}
	LandHub.tier_override = 1
	var h := (load("res://scenes/land/Land.tscn") as PackedScene).instantiate() as LandHub
	add_child(h)
	await _wait(4)
	_ok(_gem_text(h) == UI3.fmt(0), "Gem shows 0 before the wallet answers (got %s)" % _gem_text(h))
	w.b = 900
	h.set("_gem_poll", 0.0)
	await _wait()
	_ok(_gem_text(h) == UI3.fmt(900), "Gem follows the wallet once it answers: %s" % _gem_text(h))
	var w2 := FakeWallet.new()
	w2.b = 1200
	MetaState.set_gem_wallet(w2)   # sign-in swaps the wallet after the HUD was built
	h.set("_gem_poll", 0.0)
	await _wait()
	_ok(_gem_text(h) == UI3.fmt(1200), "Gem follows a wallet swapped in after the HUD: %s" % _gem_text(h))
	# The plate is right-anchored from its width; a longer number must not push it past the 24 px margin.
	w2.b = 1234567
	h.set("_gem_poll", 0.0)
	await _wait()
	var plate := h.get("_wallet") as Control
	var ui := h.get("_ui") as Control
	var right := plate.position.x + plate.get_combined_minimum_size().x * plate.scale.x
	_ok(absf(right - (ui.size.x - 24.0)) <= 1.0, "CurrencyPlate stays on the right margin after the number grows (right %.1f, want %.1f)" % [right, ui.size.x - 24.0])
	h.queue_free()
	await _wait(1)
	MetaState.set_gem_wallet(real)
	LandHub.qa = prev_qa
	LandHub.tier_override = prev_tier
	_guard.restore()
	if _fails.is_empty():
		print("t_land_gem_sync: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
	else:
		for f in _fails:
			print("FAIL: " + f)
		get_tree().quit(1)
