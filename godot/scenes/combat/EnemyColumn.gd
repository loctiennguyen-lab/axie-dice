extends RefCounted
class_name EnemyColumn
## UI-05 b1 lane 0: enemy plates (spawn, per-rebuild plate update) and the damage-preview hovers, moved out of
## CombatView.gd as-is. CombatView keeps one-line forwarders with the same names.
## State stays on the view (`v._portraits`, `v._enemy_disp`, ...); this class holds no state of its own.
## Lane C edits THIS file for the enemy column.
##
## UI-05 b1 lane C: `layout_column()` places the EnemyColumn (design/handoffs/ui-05-figma/round-1, `.enemy-column`):
## anchored top-right (margin space.screen 24), clusters 12 apart, the AttritionCard last. The column never reaches the
## docks: its bottom stays 12 above the higher of the DiceDock and ActionDock tops. Too tall (a boss with summons, 5+
## enemies, big hits): the clusters go compact (BigHitStrip folded, the label floats), then wrap into a second column
## to the left. (The "world-anchored" comment in the HTML is stale: README says top-right.)

var v: CombatView


func _init(view: CombatView) -> void:
	v = view

func _spawn_portrait(u: Unit, is_enemy: bool, slot_index: int, slot_count: int) -> void:
	var p: UnitPortrait = CombatView._PORTRAIT_SCENE.instantiate()
	if is_enemy:   # HTML data-name; a summon that reuses a number gets Godot's unique suffix
		p.name = "EnemyCluster%d" % (v._combat.enemies.find(u) + 1)
	v._unit_visuals_root.add_child(p, true)
	var tag := ""
	if is_enemy:
		tag = CombatLabels.tag_for(u.is_boss, String(v._setup.get("kind", "")), \
			v._combat.enemies.find(u) == 0, bool(u.custom_state.get("alpha", false)))
	v._enemy_disp = CombatLabels.enemy_names(v._combat.enemies)
	p.setup(u.uid, v._enemy_disp.get(u.uid, u.n) if is_enemy else u.n, u.cls, is_enemy, u.is_boss, tag)
	p.clicked.connect(v._on_target_clicked)
	p.hover_changed.connect(_on_plate_hover)
	p.inspect_requested.connect(v._open_unit_inspect)   # right-click the nameplate, same door as
		# right-clicking the model (CombatStage3D.unit_inspect_requested)
	v._portraits[u.uid] = p

	# An imported Axie's genes ride along so the stage can build its real body. They live on
	# the hero def MetaState._register_vault_hero() published into ContentDB, which is the only
	# place that knows this key came from the Vault — Unit deliberately carries no gene field,
	# so nothing here reaches into the engine or changes what a run replays as.
	var genes := String((ContentDB.heroes.get(u.key, {}) as Dictionary).get("genes", ""))
	var boss_on_field := false
	for en in v._combat.enemies:
		if (en as Unit).is_boss and (en as Unit).hp > 0:
			boss_on_field = true
	# A boss fight starts with the boss alone, so any other enemy beside a live boss is a summon. Not tied to
	# "spawned after the board was built": a fight resumed from a save rebuilds its summons in _ready() too.
	var is_summon := is_enemy and not u.is_boss and boss_on_field
	v._stage3d.spawn_unit(u.uid, u.cls, is_enemy, slot_index, slot_count, u.is_boss, u.key, genes, is_summon)
	# The audio director only ever sees uids in `hit_landed`, so it needs each unit's voice
	# up front. Heroes carry their own class; monsters have none and get one derived from the
	# Chimera sprite they wear — without this every enemy in the game would be silent.
	v._audio.register_unit(u.uid, u.cls, u.key, u.is_boss)

func _update_enemy_plate(p: UnitPortrait, u: Unit) -> void:
	var hs: Dictionary = v._hud if not v._hud.is_empty() else v._hud_state()
	var next: Dictionary = (hs.get("enemy_next", {}) as Dictionary).get(u.uid, {})
	var newcomer := bool(hs.get("newcomer", false))
	var intent := {"show": false}
	var fi := int(u.intent.get("face_index", -1)) if not u.intent.is_empty() else -1
	if u.hp > 0 and fi >= 0 and fi < u.die.size():
		var f: Dictionary = u.die[fi]
		var ftype := String(f.get("type", ""))
		var tgt_uid := int(u.intent.get("target_uid", -1))
		var num := int(next.get("dmg", v._live_face_value(u, fi))) if ftype == "dmg" \
			else v._live_face_value(u, fi)
		var clock: Dictionary = hs.get("clock", {})
		intent = {"show": true, "type": ftype, "num": num,
			"label": UI3.type_label(ftype),
			"target": v._unit_name(tgt_uid) if tgt_uid >= 0 else "",
			"boosted": u.is_boss and int(clock.get("stacks", 0)) > 0 and not newcomer,
			"big_hit": ftype == "dmg" and CombatLabels.is_big_hit(num, v._party_effective_hp())}
	p.set_acting(v._end_turn_acting_uid == u.uid)
	p.set_intent(intent)

	var tab := {}
	if u.hp > 0 and not newcomer:
		if u.is_boss and bool((hs.get("clock", {}) as Dictionary).get("active", false)):
			tab = HudKit.clock_tab(hs["clock"], int(hs.get("turn", v._combat.turn)),
				int(intent.get("num", 0)))
		elif bool(next.get("spike", false)) and int(next.get("turns_to_spike", 0)) > 0:
			var n := int(next.get("turns_to_spike", 0))
			var hits := int(next.get("spike_dmg", int(round(float(next.get("dmg", 0)) * 2.5))))
			tab = {"bg": UI3Theme.color("accent"), "ink": UI3Theme.color("accent_text"),
				"icon": HudKit.icon("spike"), "text": "BIG HIT IN %d" % n,
				"right": "HITS %d" % hits, "pips": []}
	p.set_tab(tab)
	if u.is_boss:
		p.set_phase(int((hs.get("boss_phase", {}) as Dictionary).get(u.uid, {}).get("phase",
			int(u.custom_state.get("phase", 1)))),
			2 if (u.custom_state.has("max_hp2") or u.custom_state.has("hp2")) else 1)

## Damage-preview hover, path 1/2 (review P0 #2): hovering a currently-playable ATTACK die
## previews its value on every alive enemy (click-click has no "hovering a target" moment
## before a die is even selected, so this previews against the whole legal-target set instead
## of one specific unit — see file-header DEVIATIONS #3).
func _on_die_slot_hover(slot_index: int, entering: bool) -> void:
	if entering:
		var units := v._party_dice_units()
		if slot_index < units.size():
			var u: Unit = units[slot_index]
			if u.hp > 0 and u.has_rolled() and not u.roll_used():
				var fi := u.roll_face_index()
				var f: Dictionary = u.die[fi]
				if String(f.get("type", "")) == "dmg":
					var value := v._live_face_value(u, fi)
					for e in v._combat.alive_enemies():
						var p: UnitPortrait = v._portraits.get(e.uid)
						if p != null:
							p.set_preview_damage(value)
					return
	_clear_all_previews()

## Damage-preview hover, path 2/2 (review P0 #2 + #3 combined): hovering an enemy's intent
## badge previews that intent's actual value on its actual target — the more important of the
## two per the review's own framing ("quyết định người chơi giơ khiên hay lao vào đánh"). Also
## brightens this enemy's target-line (see _layout_unit_visuals()).
func _on_enemy_intent_hover(uid: int, hovering: bool) -> void:
	v._hovered_enemy_uid = uid if hovering else -1
	if not hovering:
		_clear_all_previews()
		return
	var e := v._combat.by_uid(uid)
	if e == null or e.intent.is_empty():
		return
	var fi := int(e.intent.get("face_index", -1))
	var tgt_uid := int(e.intent.get("target_uid", -1))
	if fi < 0 or fi >= e.die.size() or tgt_uid < 0:
		return
	var f: Dictionary = e.die[fi]
	if String(f.get("type", "")) != "dmg":
		return
	var p: UnitPortrait = v._portraits.get(tgt_uid)
	if p != null:
		p.set_preview_damage(v._live_face_value(e, fi))
	# Party HP lives in the tray: the gold hatched segment goes on that column's bar.
	var units := v._party_dice_units()
	for i in units.size():
		if (units[i] as Unit).uid == tgt_uid and i < v._die_slot_content.size():
			((v._die_slot_content[i] as Dictionary)["hp"] as HPBar).set_preview(v._live_face_value(e, fi))

## Pointer over an enemy plate. On its intent block: preview that intent on its target. Elsewhere
## while a die is selected: preview the die's hit on this enemy (README 3 "Targeting").
func _on_plate_hover(uid: int, hovering: bool, on_intent: bool) -> void:
	if v._combat == null:
		return
	if on_intent:
		_on_enemy_intent_hover(uid, hovering)
		return
	if not hovering:
		_clear_all_previews()
		return
	var src := v._combat.by_uid(v._selected_die_uid) if v._selected_die_uid != -1 else null
	if src == null or not src.has_rolled():
		return
	var fi := src.roll_face_index()
	if fi < 0 or fi >= src.die.size() or String((src.die[fi] as Dictionary).get("type", "")) != "dmg":
		return
	var p: UnitPortrait = v._portraits.get(uid)
	if p != null and v._combat_is_enemy_uid(uid):
		p.set_preview_damage(v._live_face_value(src, fi))

func _clear_all_previews() -> void:
	for p in v._portraits.values():
		(p as UnitPortrait).clear_preview_damage()
	for c in v._die_slot_content:
		if (c as Dictionary).has("hp"):
			((c as Dictionary)["hp"] as HPBar).clear_preview()


## Places every living enemy cluster and the AttritionCard. Called every frame from CombatView._layout_unit_visuals().
func layout_column() -> void:
	if v._combat == null:
		return
	var vs: Vector2 = v.get_viewport_rect().size
	var cards: Array[UnitPortrait] = []
	for e in v._combat.enemies:
		var ep: UnitPortrait = v._portraits.get(e.uid)
		if ep != null and ep.visible:
			ep.sync_scale()
			cards.append(ep)
	var attr: Control = v._hud_frame.get("_attr_card") as Control if v._hud_frame != null else null
	var attr_on := attr != null and is_instance_valid(attr) and attr.visible
	var res := place(cards, attr_on, vs, bottom_limit(vs))
	if v._hud_frame != null:
		v._hud_frame.place_attrition(res["attr"])


## The column itself, without the view (tests call it): positions `cards` top-right and returns
## {compact: bool, attr: Vector2 (AttritionCard top-left, right-aligned, after the last cluster), columns: int}.
static func place(cards: Array[UnitPortrait], attr_on: bool, vs: Vector2, limit: float) -> Dictionary:
	var margin := float(UI3Theme.space("screen"))
	var gap := float(UI3Theme.space("12"))
	var compact := false
	var pos := stack(_items(cards, attr_on, false), margin, limit, vs.x - margin, gap)
	if column_count(pos, margin) > 1:
		compact = true
		pos = stack(_items(cards, attr_on, true), margin, limit, vs.x - margin, gap)
	var y_end := margin
	for i in cards.size():
		cards[i].set_compact(compact)
		cards[i].position = pos[i]
		y_end = pos[i].y + cards[i].cluster_height(compact) + gap
	var ap: Vector2 = pos.back() if attr_on else Vector2(vs.x - margin - attrition_w(), y_end)
	return {"compact": compact, "attr": ap, "columns": column_count(pos, margin)}


static func _items(cards: Array[UnitPortrait], attr_on: bool, compact: bool) -> Array:
	var out: Array = []
	for c in cards:
		out.append(Vector2(c.size.x, c.cluster_height(compact)))
	if attr_on:
		out.append(Vector2(attrition_w(), UI3Theme.size_of("attrition_h")))
	return out


static func attrition_w() -> float:
	return float(UI3Theme.size_of("attrition_w"))


## Lowest y a cluster may reach: 12 above the higher of the DiceDock top and the ActionDock top (HUD).
func bottom_limit(vs: Vector2) -> float:
	var lim := TrayColumn.dock_top(vs.y)
	if v._hud_frame != null and v._hud_frame.tray_top() > 0.0:
		lim = minf(lim, v._hud_frame.tray_top())
	return lim - float(UI3Theme.space("12"))


## Pure column stacking. `items` = sizes (Vector2 w, h) top to bottom. Fills a column from `top`, right-aligned to
## `right`; an item whose bottom would pass `limit` starts a new column to the left of the widest item so far
## (`gap` between columns and between items). The first item of a column always goes in. Returns top-left corners.
static func stack(items: Array, top: float, limit: float, right: float, gap: float) -> Array:
	var out: Array = []
	var y := top
	var col_right := right
	var col_w := 0.0
	for it in items:
		var s: Vector2 = it
		if y > top and y + s.y > limit:
			col_right -= col_w + gap
			y = top
			col_w = 0.0
		out.append(Vector2(col_right - s.x, y))
		y += s.y + gap
		col_w = maxf(col_w, s.x)
	return out


## Columns used by a `stack()` result (one per item that starts at `top`).
static func column_count(pos: Array, top: float) -> int:
	var n := 0
	for p in pos:
		if is_equal_approx((p as Vector2).y, top):
			n += 1
	return n
