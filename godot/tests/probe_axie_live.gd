extends Node
## OPT-IN live check of the real Axie gateway. NOT part of the suite (name does not start with
## `t_`) — on purpose: a gate that needs the internet goes red on a train and looks exactly like
## a code regression. `t_axie_api` covers the same logic offline against canned payloads.
##
## A SCENE, not a `--script` SceneTree. `--script` mode does not load autoloads, so `ContentDB`
## does not exist there and `AxieToDie` fails to compile — the die half of this probe silently
## never ran until it was moved here.
##
## Run (pass an ID after `--`, default 123):
##   godot --headless --path godot res://tests/probe_axie_live.tscn -- 4154

func _ready() -> void:
	var id := "123"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		id = str(args[0])

	var api := AxieApi.new()
	add_child(api)
	await get_tree().process_frame

	if not AxieApi.is_available():
		print("LIVE: unavailable — ", AxieApi.unavailable_reason())
		get_tree().quit(1)
		return
	print("LIVE: asking the gateway for Axie #", id, " via ", AxieApi.curl_path())
	api.request_axie(id)
	var res: Dictionary = await api.completed
	if not bool(res["ok"]):
		print("LIVE: FAILED err=", res["err"], " — ", res["message"])
		get_tree().quit(1)
		return

	var axie: Dictionary = res["axie"]
	var genes := str(axie.get("genes", ""))
	print("LIVE: ok  class=", axie.get("class"), "  parts=", (axie.get("parts", []) as Array).size())
	print("LIVE: genes len=", genes.length(), " head=", genes.substr(0, 46))

	var report := AxieGenePreview.inspect(genes)
	print("LIVE: rig  body=", report["body_name"], " colour=", report["color_variant"],
		"  parts resolved=", report["resolved_count"], "/", report["part_count"],
		"  complete=", report["complete"])

	var die := AxieToDie.build({"id": axie["id"], "class": axie["class"], "parts": axie["parts"]})
	print("LIVE: die  name=", die.get("n"), "  cls=", die.get("cls"),
		"  secret=", die.get("secret_cls"), "  hp=", die.get("max_hp"),
		"  purity=", die.get("purity"), "  coh=", "%.3f" % float(die.get("coh", 0.0)))
	for f in die.get("die", []):
		print("        %-6s %-7s %s" % [str(f.get("p")), str(f.get("t")), str(f.get("v"))])
	get_tree().quit(0)
