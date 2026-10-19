class_name GiftClaim
extends RefCounted
## The Gem gift claim shared by Daily and Store. With the server wallet the answer is asynchronous
## (RemoteGemWallet.claim_daily_gift returns "pending" at once), so a screen must wait for
## claim_daily_gift_async. Before this, both screens read the "pending" result, showed nothing and
## never refreshed: the button looked dead (Liam, build b931).

## True when the claim has to be awaited (server wallet).
static func is_remote() -> bool:
	return MetaState.gem_wallet() is RemoteGemWallet


## Starts the async claim. done(result: Dictionary, text: String, ok: bool) runs when the server answers.
static func claim_async(done: Callable) -> void:
	MetaState.gem_wallet().claim_daily_gift_async(func(r: Dictionary) -> void:
		if bool(r.get("ok", false)) or String(r.get("reason", "")) == "already_claimed":
			# The screens read the claimed day from MetaState, so keep it in step with the server.
			MetaState.gem_gift_day = GemWallet.utc_day(int(Time.get_unix_time_from_system()))
			if int(r.get("next_utc", 0)) > 0:
				MetaState.gem_claim_next_utc = int(r["next_utc"])
			MetaState.save_to_disk()
		done.call(r, message(r), bool(r.get("ok", false))))


## One sentence for a claim result (local or server). Never empty.
static func message(r: Dictionary) -> String:
	if bool(r.get("ok", false)):
		return "+%d Gem" % int(r.get("granted", 0))
	match String(r.get("reason", "")):
		"already_claimed": return "Gem gift already claimed today"
		"at_cap": return "You hold the maximum, nothing to claim"
		"offline": return "Couldn't reach the server. Check your connection and try again."
		"pending": return "Claiming..."
	return "Could not claim the Gem gift. Try again."


## A short error/ok toast at the top centre of `host` that removes itself.
static func toast(host: Control, text: String, tone: StringName = &"ok") -> void:
	if host == null or not host.is_inside_tree():
		return
	var t := UI3.toast(text, tone)
	t.name = "GiftToast"
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(t)
	t.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 24)
	var tw := host.create_tween()
	tw.tween_interval(2.4)
	tw.tween_property(t, "modulate:a", 0.0, 0.4)
	tw.tween_callback(t.queue_free)
