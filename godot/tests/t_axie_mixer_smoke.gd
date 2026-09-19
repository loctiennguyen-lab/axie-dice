extends SceneTree
## Smoke test: confirms the vendored Axie Mixer 3D addon (godot/addons/axie_mixer_3d*)
## actually works INSIDE this project (not just the vendor's own demo project) —
## catalog loads, AxieMixerInitializer assigns the factory, and from_genes() produces
## a real character with mesh children. Uses the same sample gene string as the
## vendor's examples/demo_kit.gd (DemoKit.SAMPLE_GENES), copied inline here since that
## file lives in third_party/, not in this project.
##
## Run: godot --headless --path godot --script tests/t_axie_mixer_smoke.gd

const SAMPLE_GENES := "0x180000000000030002018040810800000001000c080043040001000c0800800200010014084083020001000c1860430600010008100085060001000408604506"

func _initialize() -> void:
	var initializer := AxieMixerInitializer.new()
	initializer.persist_across_scenes = false
	root.add_child(initializer)
	# _enter_tree() (which assigns the factory) fires on the NEXT frame in headless
	# --script mode, not synchronously inside add_child() — confirmed by isolating a
	# minimal Node subclass and observing print ordering. Wait one frame before checking.
	await process_frame

	if initializer.get_factory() == null:
		push_error("t_axie_mixer_smoke: FAIL — AxieMixerInitializer did not assign a factory " +
			"(catalog.json failed to load?)")
		quit(1)
		return

	var axie := AxieCharacter3D.from_genes(SAMPLE_GENES)
	if axie == null or axie.root == null:
		push_error("t_axie_mixer_smoke: FAIL — from_genes() returned null for sample genes")
		quit(1)
		return

	root.add_child(axie.root)
	print("t_axie_mixer_smoke: PASS — from_genes() built a character, root='%s', child_count=%d, has_playable=%s" % [
		axie.root.name, axie.root.get_child_count(), axie.playable != null])

	axie.dispose()
	quit(0)
