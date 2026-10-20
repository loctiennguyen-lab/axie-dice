class_name SimReport
extends RefCounted
## Aggregates run records from sim_balance.gd into production/qa/sim/sim-<date>-<tag>.{md,csv}.

static func _pct(a: int, b: int) -> String:
	return "-" if b == 0 else "%.1f%% (%d/%d)" % [100.0 * a / b, a, b]


static func write(recs: Array, out_dir: String, tag: String, secs: float, catalog: Array = []) -> void:
	DirAccess.make_dir_recursive_absolute(out_dir)
	var date := Time.get_date_string_from_system()
	var base := out_dir.path_join("sim-%s-%s" % [date, tag])
	var csv := FileAccess.open(base + ".csv", FileAccess.WRITE)
	csv.store_line("seed,policy,core_policy,team,asc,won,death_kind,death_row,rule,cores,fights,offered,picked,trig")
	for r in recs:
		var fs: Array = []
		for f in r["fights"]:
			fs.append("%s:%d:%d:%s" % [f["kind"], f["turns"], 1 if f["won"] else 0, f.get("affix", "")])
		csv.store_line("%d,%s,%s,%s,%d,%d,%s,%d,%s,%s,%s,%s,%s,%s" % [r["seed"], r["policy"], r["core_policy"], r["team"],
			r["asc"], 1 if r["won"] else 0, r["death_kind"], r["death_row"], r["rule"], ";".join(r["cores"]), ";".join(fs),
			";".join(r["offered"]), ";".join(r["picked"]), ";".join(r["trig"])])
	csv.close()
	var md := build_md(recs, tag, secs, catalog)
	var f := FileAccess.open(base + ".md", FileAccess.WRITE)
	f.store_string(md)
	f.close()
	print(md)
	print("wrote ", base, ".md/.csv")


static func build_md(recs: Array, tag: String, secs: float, catalog: Array = []) -> String:
	var L: Array = []
	L.append("# Sim balance %s\n" % tag)
	L.append("Runs: %d, wall %.1fs (%.2fs/run).\n" % [recs.size(), secs, secs / maxf(1.0, recs.size())])
	# win-rate by policy x asc, policy x team, core policy
	L.append(_goals(recs))
	L.append(_funnel(recs))
	L.append(_table(recs, ["policy", "asc"], "Win-rate theo chinh sach x Ascension"))
	L.append(_table(recs, ["policy", "team"], "Win-rate theo chinh sach x doi"))
	L.append(_table(recs, ["policy", "core_policy"], "Win-rate theo chinh sach x cach chon Loi"))
	# turns per fight kind, deaths by node, stuck
	var turns := {}
	var stuck := 0
	var fights := 0
	var deaths := {}
	var by_pol_node := {}
	for r in recs:
		for f in r["fights"]:
			var k := "%s|%s" % [r["policy"], f["kind"]]
			if not turns.has(k):
				turns[k] = []
			(turns[k] as Array).append(int(f["turns"]))
			fights += 1
			if f["stuck"]:
				stuck += 1
		if not r["won"]:
			var dk := "%s|%s r%d" % [r["policy"], r["death_kind"], r["death_row"]]
			deaths[dk] = int(deaths.get(dk, 0)) + 1
	L.append("## So luot trung binh moi tran (chinh sach|loai)\n")
	var keys := turns.keys()
	keys.sort()
	for k in keys:
		var a: Array = turns[k]
		var s := 0
		for x in a:
			s += int(x)
		L.append("- %s: %.1f luot (n=%d)" % [k, float(s) / a.size(), a.size()])
	L.append("\n## Chet theo node (chinh sach|loai row)\n")
	var dks := deaths.keys()
	dks.sort()
	for k in dks:
		L.append("- %s: %d" % [k, deaths[k]])
	L.append("\nTran ket > 20 luot hoac khong ket thuc: %d / %d\n" % [stuck, fights])
	L.append(_freq_section(recs, catalog))
	L.append(_core_section(recs))
	return "\n".join(L)


static func _table(recs: Array, dims: Array, title: String) -> String:
	var cells := {}
	for r in recs:
		var parts: Array = []
		for d in dims:
			parts.append(str(r[d]))
		var k := " | ".join(parts)
		if not cells.has(k):
			cells[k] = [0, 0]
		cells[k][1] += 1
		if r["won"]:
			cells[k][0] += 1
	var out := "## %s\n\n| %s | win |\n|%s\n" % [title, " | ".join(dims), "---|".repeat(dims.size() + 1)]
	var ks := cells.keys()
	ks.sort()
	for k in ks:
		out += "| %s | %s |\n" % [k, _pct(cells[k][0], cells[k][1])]
	return out + "\n"


static func _core_section(recs: Array) -> String:
	const MIN_N := 8
	var with := {}
	var pairs := {}
	var pair_runs := 0
	for r in recs:
		var ids: Array = []
		var axes := {}
		for c in r["cores"]:
			var sp := String(c).split("@")
			ids.append(sp[0])
			if sp[1] in ["dice", "mana", "pos", "rule"]:
				axes[sp[1]] = int(axes.get(sp[1], 0)) + 1
		var has_pair := false
		for a in axes:
			if int(axes[a]) >= 2:
				has_pair = true
		if has_pair:
			pair_runs += 1
		for id in ids:
			if not with.has(id):
				with[id] = [0, 0]
			with[id][1] += 1
			if r["won"]:
				with[id][0] += 1
		ids.sort()
		for i in ids.size():
			for j in range(i + 1, ids.size()):
				var pk := "%s + %s" % [ids[i], ids[j]]
				if not pairs.has(pk):
					pairs[pk] = [0, 0]
				pairs[pk][1] += 1
				if r["won"]:
					pairs[pk][0] += 1
	var out := "## Loi\n\nRun rap duoc cap (2 Loi cung truc dice/mana/pos/rule): %s\n\n" % _pct(pair_runs, recs.size())
	var rows: Array = []
	for id in with:
		if int(with[id][1]) >= MIN_N:
			rows.append([id, float(with[id][0]) / with[id][1], with[id][0], with[id][1]])
	rows.sort_custom(func(a, b): return a[1] > b[1])
	out += "Win-rate khi co Loi (n >= %d). Top 10:\n" % MIN_N
	for i in mini(10, rows.size()):
		out += "- %s: %.1f%% (%d/%d)\n" % [rows[i][0], 100.0 * rows[i][1], rows[i][2], rows[i][3]]
	out += "\nBottom 10:\n"
	for i in mini(10, rows.size()):
		var rr: Array = rows[rows.size() - 1 - i]
		out += "- %s: %.1f%% (%d/%d)\n" % [rr[0], 100.0 * rr[1], rr[2], rr[3]]
	var prow: Array = []
	for pk in pairs:
		if int(pairs[pk][1]) >= MIN_N:
			prow.append([pk, float(pairs[pk][0]) / pairs[pk][1], pairs[pk][0], pairs[pk][1]])
	prow.sort_custom(func(a, b): return a[1] > b[1])
	out += "\nCap Loi bat thuong (n >= %d): top 5 / bottom 5\n" % MIN_N
	for i in mini(5, prow.size()):
		out += "- %s: %.1f%% (%d/%d)\n" % [prow[i][0], 100.0 * prow[i][1], prow[i][2], prow[i][3]]
	for i in mini(5, prow.size()):
		var pr: Array = prow[prow.size() - 1 - i]
		out += "- %s: %.1f%% (%d/%d)\n" % [pr[0], 100.0 * pr[1], pr[2], pr[3]]
	return out


## Per Core / Run Rule: % of runs where it was offered, picked, fired (heuristic, see sim_balance.gd _note_triggers).
static func _freq_section(recs: Array, catalog: Array) -> String:
	var n := maxi(1, recs.size())
	var off := {}
	var pick := {}
	var trig := {}
	var trig_picked := {}
	for r in recs:
		var pk := {}
		for id in r["picked"]:
			pk[id] = true
		for id in r["offered"]:
			off[id] = int(off.get(id, 0)) + 1
		for id in pk:
			pick[id] = int(pick.get(id, 0)) + 1
		for id in r["trig"]:
			trig[id] = int(trig.get(id, 0)) + 1
			if pk.has(id):
				trig_picked[id] = int(trig_picked.get(id, 0)) + 1
	var out := "## Tan suat Loi / Luat run (% run)\n\nCot fire = Loi dang so huu co kich hoat it nhat 1 lan (heuristic: state bucket hoac event chac chan xay ra; engine chua co trace rieng). `LOW` = xuat hien < 10% run; `DEAD` = duoc chon nhung khong bao gio fire.\n\n"
	out += "| id | truc | bac | offered | picked | fired | fired/picked | co |\n|---|---|---|---|---|---|---|---|\n"
	for c in catalog:
		var id: String = c["id"]
		var o := int(off.get(id, 0))
		var p := int(pick.get(id, 0))
		var t := int(trig.get(id, 0))
		var flags: Array = []
		if 100.0 * o / n < 10.0:
			flags.append("LOW")
		if p > 0 and int(trig_picked.get(id, 0)) == 0:
			flags.append("DEAD")
		out += "| %s | %s | %d | %.1f%% | %.1f%% | %.1f%% | %s | %s |\n" % [id, c["axis"], c["rarity"], 100.0 * o / n,
			100.0 * p / n, 100.0 * t / n, "-" if p == 0 else "%.0f%%" % (100.0 * int(trig_picked.get(id, 0)) / p), " ".join(flags)]
	return out + "\n"


static func _rate(recs: Array, policies: Array) -> float:
	var n := 0
	var w := 0
	for r in recs:
		if policies.has(r["policy"]):
			n += 1
			if r["won"]:
				w += 1
	return -1.0 if n == 0 else 100.0 * w / n


## Liam's targets (Short, A0): dumb bots <= 5%, expert 15-25%, expert - random >= 15 points.
static func _goals(recs: Array) -> String:
	var a0: Array = []
	for r in recs:
		if int(r["asc"]) == 0:
			a0.append(r)
	var out := "## Muc tieu (Short A0)\n\n"
	for pol in ["random_legal", "attack_spam", "attack_only"]:
		var x := _rate(a0, [pol])
		if x >= 0.0:
			out += "- %s <= 5%%: %.1f%% -> %s\n" % [pol, x, "DAT" if x <= 5.0 else "CHUA DAT"]
	var ex := _rate(a0, ["expert"])
	if ex >= 0.0:
		out += "- expert 15-25%%: %.1f%% -> %s\n" % [ex, "DAT" if ex >= 15.0 and ex <= 25.0 else "CHUA DAT"]
		var rnd := _rate(a0, ["random_legal"])
		if rnd >= 0.0:
			out += "- expert - random >= 15 diem: %.1f diem -> %s\n" % [ex - rnd, "DAT" if ex - rnd >= 15.0 else "CHUA DAT"]
	var gr := _rate(a0, ["greedy"])
	if gr >= 0.0:
		out += "- (tham khao) greedy: %.1f%%\n" % gr
	return out + "\n"


static func read_csvs(paths: Array) -> Array:
	var out: Array = []
	for p in paths:
		var f := FileAccess.open(String(p), FileAccess.READ)
		if f == null:
			push_error("cannot read " + String(p))
			continue
		f.get_line()
		while not f.eof_reached():
			var ln := f.get_line()
			if ln == "":
				continue
			var c := ln.split(",")
			var fights: Array = []
			for fs in String(c[10]).split(";", false):
				var q := fs.split(":")
				fights.append({"kind": q[0], "turns": int(q[1]), "won": q[2] == "1", "stuck": int(q[1]) > 20, "affix": q[3] if q.size() > 3 else ""})
			out.append({"seed": int(c[0]), "policy": c[1], "core_policy": c[2], "team": c[3], "asc": int(c[4]), "won": c[5] == "1",
				"death_kind": c[6], "death_row": int(c[7]), "rule": c[8], "cores": Array(String(c[9]).split(";", false)),
				"fights": fights, "offered": Array(String(c[11]).split(";", false)), "picked": Array(String(c[12]).split(";", false)),
				"trig": Array(String(c[13]).split(";", false))})
	return out


## Survival funnel per policy: of all runs, how many were still alive when they reached each map row (cumulative deaths).
static func _funnel(recs: Array) -> String:
	var by := {}
	var cnt := {}
	for r in recs:
		var pol: String = r["policy"]
		cnt[pol] = int(cnt.get(pol, 0)) + 1
		if not by.has(pol):
			by[pol] = {}
		if not r["won"] and int(r["death_row"]) > 0:
			var k := "%d %s" % [r["death_row"], r["death_kind"]]
			by[pol][k] = int(by[pol].get(k, 0)) + 1
	var out := "## Phieu chet theo node (song sot tich luy)\n\n"
	for pol in by.keys():
		var rows: Array = []
		for k in (by[pol] as Dictionary).keys():
			rows.append([int(String(k).split(" ")[0]), String(k), int(by[pol][k])])
		rows.sort_custom(func(a, b): return a[0] < b[0])
		var alive := int(cnt[pol])
		var line := "- **%s** (n=%d): " % [pol, alive]
		var parts: Array = []
		for rw in rows:
			alive -= int(rw[2])
			parts.append("r%s -%d (con %.0f%%)" % [String(rw[1]).replace(" ", " "), rw[2], 100.0 * alive / int(cnt[pol])])
		out += line + "; ".join(parts) + "\n"
	return out + "\n"
