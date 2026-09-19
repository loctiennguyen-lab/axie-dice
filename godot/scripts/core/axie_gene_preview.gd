class_name AxieGenePreview
extends Object
## Reads a real Axie's 512-bit gene string and reports what the 3D kit can actually build from
## it — BEFORE anything is rendered.
##
## WHY THIS IS A SEPARATE FILE FROM THE RENDERER
## --------------------------------------------
## The measured fidelity of the gene -> rig path is 54/60 parts across the vendor's ten pinned
## sample Axies; one of the ten builds with no parts at all. That is not a bug to fix here —
## `AxiePartResolver` falls back only by skin and level, NEVER by variant, so a variant the kit
## does not ship resolves to nothing rather than to the wrong thing, and the vendor's own golden
## sets `"spawn_min": 9` because upstream knows and accepts it.
##
## What matters is that the bare body is DETECTABLE. A silently part-less Axie looks like "a
## strange-looking Axie", not like a failure, and this project has already lost hours to exactly
## that class of bug (five growth sources writing keys nobody read; every monster going mute).
## So the count is produced by a pure catalogue query that needs no renderer, no viewport and no
## display server — which means a headless test can pin it, and the UI can put a badge on it.
##
## PURE-ish: no RNG, no Time, no network. It does read the addon's catalogue (`AxieFactory`), so
## it is not pure in the sense `axie_to_die.gd` is — and it must never become a die-building
## input for that reason. The die comes from the Axie's PART NAMES via `AxieToDie`, which the
## server can replay; the rig is cosmetic only. An Axie that renders bare still gets a correct,
## complete die.

## Every Axie has exactly six parts; the gene layout has no way to express fewer.
const PART_COUNT := 6

## Reasons a gene string cannot be trusted. Kept as constants because the UI branches on them
## and a typo'd string literal would silently become "no reason given".
const REASON_OK := ""
const REASON_EMPTY := "empty_genes"
const REASON_BAD_HEX := "bad_hex"
const REASON_NO_CATALOG := "no_catalog"

## NOT VALIDATED: length. A first version of this file rejected anything under 128 hex digits as
## truncated, on the reasoning that an Axie gene is 512 bits. Measured against the vendor's ten
## pinned samples that rule flagged THREE real Axies (#1000, #42, #777, `len: 117`) as broken
## while they decoded perfectly — body type, colour and all six parts matching the golden exactly.
## The gene is a big NUMBER written in hex, so leading zeroes are simply absent, and `_parse_genes`
## reads it from the last digit backwards for that reason. A genuinely truncated gene is therefore
## indistinguishable from a valid small one, and cannot be detected here; the only gene value that
## really carries no information is zero.


## Decodes `genes` and asks the catalogue which of the six parts it can actually build.
##
## Always returns a full report, even for rubbish input — the caller needs something to show and
## something to explain, and a null return would only move the branch outwards. Read `ok` for
## "this is a real gene string", `complete` for "the rig will look right".
static func inspect(genes: String) -> Dictionary:
	var report := {
		"genes": genes,
		"ok": false,
		"reason": REASON_EMPTY,
		"descriptor": null,
		"body": AxieTypes.Body.NORMAL,
		"body_name": AxieTypes.body_name(AxieTypes.Body.NORMAL),
		"color_variant": 0,
		"parts": [],
		"part_count": 0,
		"resolved_count": 0,
		"complete": false,
		"missing": [],
	}

	var hex := _strip_prefix(genes)
	if hex.is_empty() or _is_all_zero(hex):
		# `0x0` is what the pinned sample #1 carries, and the vendor marks it `skip`. It is not a
		# strange Axie — it is the absence of one, which is why it is caught before decoding
		# rather than being allowed to render as a Beast-coloured bare body.
		return report
	if not _is_hex(hex):
		report["reason"] = REASON_BAD_HEX
		return report
	report["reason"] = REASON_OK
	report["ok"] = true

	var desc := AxieDescriptor.from_genes(genes)
	report["descriptor"] = desc
	report["body"] = desc.body
	report["body_name"] = AxieTypes.body_name(desc.body)
	report["color_variant"] = desc.color_variant
	report["part_count"] = desc.parts.size()

	var factory := _factory()
	if factory == null:
		# No catalogue means "unknown", not "zero". Saying 0/6 here would put a wrong badge on a
		# perfectly good Axie whenever the addon has not booted yet.
		report["reason"] = REASON_NO_CATALOG
		report["ok"] = false
		return report

	var parts: Array[Dictionary] = []
	var resolved := 0
	var missing: Array[String] = []
	for p in desc.parts:
		var res: Dictionary = factory.resolve_part(p)
		var got := bool(res.get("ok", false))
		if got:
			resolved += 1
		else:
			missing.append(part_label(p))
		parts.append({
			"slot": AxieTypes.part_name(p.type),
			"part_class": p.part_class,
			"variant": p.variant,
			"skin": p.skin,
			"level": p.level,
			"resolved": got,
			"asset": str(res.get("name", "")),
		})
	report["parts"] = parts
	report["resolved_count"] = resolved
	report["missing"] = missing
	report["complete"] = bool(report["ok"]) and resolved == PART_COUNT and desc.parts.size() == PART_COUNT
	return report


## One line a player can read, e.g. "Horn Plant-00". The variant is the field that decides whether
## the kit has the part, so it is the field the label leads with. An unrecognised class number
## decodes to an empty class name; say so rather than rendering "Horn -07", which reads as a
## negative number.
static func part_label(p: AxiePartDescriptor) -> String:
	var cls := p.part_class if not p.part_class.is_empty() else "?"
	return "%s %s-%02d" % [AxieTypes.part_name(p.type), cls, p.variant]


## The short sentence the preview puts under a rig that did not come out whole. Empty when there
## is nothing to warn about, so the caller can use it directly as "show the badge?".
static func warning_text(report: Dictionary) -> String:
	var reason := str(report.get("reason", REASON_OK))
	match reason:
		REASON_EMPTY:
			return "No gene data for this Axie."
		REASON_BAD_HEX:
			return "Gene string is not valid hex."
		REASON_NO_CATALOG:
			return "3D kit is not loaded; cannot preview."
	var resolved := int(report.get("resolved_count", 0))
	var total := int(report.get("part_count", PART_COUNT))
	if resolved >= total and total == PART_COUNT:
		return ""
	var missing: Array = report.get("missing", [])
	return "Showing %d/%d parts — the 3D kit has no art for: %s" % [
		resolved, total, ", ".join(PackedStringArray(missing))
	]


static func _strip_prefix(genes: String) -> String:
	var s := genes.strip_edges()
	if s.begins_with("0x") or s.begins_with("0X"):
		s = s.substr(2)
	return s


## "0", "00", "0x000…" — every spelling of the number zero. Checked on the raw text rather than on
## the decoded descriptor because a zero gene decodes to a perfectly plausible-looking Beast with
## variant-00 parts, which is precisely the bare body this file exists to catch.
static func _is_all_zero(s: String) -> bool:
	for i in s.length():
		if s[i] != "0":
			return false
	return true


static func _is_hex(s: String) -> bool:
	for i in s.length():
		var c := s[i]
		if not ((c >= "0" and c <= "9") or (c >= "a" and c <= "f") or (c >= "A" and c <= "F")):
			return false
	return true


## `AxieMixerBoot` (project autoload) assigns `AxieFactory.default_factory`; `AxieDefaults.factory`
## is the addon's own fallback slot. Checking both mirrors what `AxieCharacter3D.from_descriptor`
## does, so this report can never disagree with what the renderer will actually build.
static func _factory() -> AxieFactory:
	if AxieFactory.default_factory != null:
		return AxieFactory.default_factory
	return AxieDefaults.factory as AxieFactory
