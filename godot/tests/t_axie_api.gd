extends Node
## Gate for `AxieApi` — the Vault's network layer (Import Axie, step (d)).
##
## THIS GATE NEVER MAKES A NETWORK REQUEST. `test-standards.md`: "Unit tests must not depend on
## external state (filesystem, network, database)" and "Tests must produce the same result every
## run". A gate that called the real Axie gateway would go red on a train, on a rate limit, or on
## the day Sky Mavis changes an unrelated field — and each of those would look exactly like a
## code regression. `AxieApi` is split so that everything worth testing is pure: validation,
## payload construction, and response parsing all run on strings.
##
## To check the LIVE endpoint on purpose, run the opt-in probe instead:
##     godot --headless --path godot res://tests/probe_axie_live.tscn -- 123
##
## WHAT IS ACTUALLY AT RISK
## ------------------------
##  1. **Reading `genes` instead of `newGenes`.** Both fields exist, both return a hex string,
##     and the wrong one does not error — `AxieDescriptor.from_genes()` is a 512-bit decoder, so
##     handed the 256-bit `genes` it decodes garbage and builds a confident, wrong Axie. There is
##     no symptom. Pinned below against the real byte string for Axie #123.
##  2. **A Cloudflare challenge page parsed as data.** The gateway answers a blocked client with
##     HTML, not JSON. If that path is not named, the next person sees "invalid JSON" and goes
##     looking at their parser.
##  3. **A missing Axie treated as a valid one.** The API returns a null class and empty parts
##     for an unminted id rather than an error.
##
## Run: godot --headless --path godot res://tests/t_axie_api.tscn

## Real bytes, captured from the live gateway on 2026-09-19 for Axie #123. `new_genes` here is
## byte-identical to the vendor golden's `genes` for the same Axie
## (`third_party/godot-axie-mixer-3d-main/tests/goldens/sample_axies.json`) — which is the whole
## reason this is the field to read.
const REAL_NEW_GENES := "0x180000000000030002018040810800000001000c080043040001000c08008002000100140840830200010" \
	+ "00c1860430600010008100085060001000408604506"
## The SHORT one the same query also offers. Kept here so the difference is visible in the test
## rather than described in a comment somewhere else.
const REAL_OLD_GENES := "0x30004000072c22120c2008c40c201002142210"

const GOLDEN_REL := "../third_party/godot-axie-mixer-3d-main/tests/goldens/sample_axies.json"

## Every test in this file, by name. Listed rather than derived so deleting one is a visible edit.
const EXPECTED_TESTS: Array[String] = [
	"test_only_a_plain_number_is_accepted_as_an_axie_id",
	"test_the_query_asks_for_new_genes_and_not_the_short_legacy_field",
	"test_a_real_response_parses_into_the_shape_the_vault_stores",
	"test_the_gene_it_returns_is_the_one_the_3d_kit_can_actually_decode",
	"test_a_cloudflare_challenge_is_named_as_a_block_not_as_bad_json",
	"test_a_missing_axie_is_not_mistaken_for_a_valid_one",
	"test_a_typo_is_named_a_typo_even_though_the_gateway_also_reports_an_error",
	"test_every_failure_mode_has_its_own_key_and_a_sentence_for_the_player",
	"test_availability_is_reported_rather_than_assumed",
	"test_the_proxy_transport_produces_the_same_shape_as_curl",
	"test_the_transport_is_chosen_by_what_the_build_can_actually_do",
	"test_the_403_workaround_is_sent_on_both_curl_attempts",
	"test_only_a_transport_failure_is_retried",
]

var _failures: Array[String] = []
var _checks := 0
var _completed: Array[String] = []


func _ready() -> void:
	print("=== t_axie_api: start ===")
	await get_tree().process_frame

	test_only_a_plain_number_is_accepted_as_an_axie_id()
	test_the_query_asks_for_new_genes_and_not_the_short_legacy_field()
	test_a_real_response_parses_into_the_shape_the_vault_stores()
	test_the_gene_it_returns_is_the_one_the_3d_kit_can_actually_decode()
	test_a_cloudflare_challenge_is_named_as_a_block_not_as_bad_json()
	test_a_missing_axie_is_not_mistaken_for_a_valid_one()
	test_a_typo_is_named_a_typo_even_though_the_gateway_also_reports_an_error()
	test_every_failure_mode_has_its_own_key_and_a_sentence_for_the_player()
	test_availability_is_reported_rather_than_assumed()
	test_the_proxy_transport_produces_the_same_shape_as_curl()
	test_the_transport_is_chosen_by_what_the_build_can_actually_do()
	test_the_403_workaround_is_sent_on_both_curl_attempts()
	test_only_a_transport_failure_is_retried()

	for name in EXPECTED_TESTS:
		if not _completed.has(name):
			_failures.append(("test '%s' did not run to completion — a runtime error aborted it "
				+ "part-way and every assertion after that point was skipped") % name)

	print("=== t_axie_api: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_axie_api: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_axie_api: FAIL — %s" % f)
	get_tree().quit(1)


func _done(test_name: String) -> void:
	_completed.append(test_name)


## The reported bug: "HTTP 403 error when using an ID to select". The addon author's fix is
## one header — Apollo Server rejects anything it judges could be a cross-site form post
## unless the caller opts into a CORS preflight — and this pins that it is actually sent, on
## BOTH attempts, spelled exactly as the reference demo spells it.
##
## Also pins the thing that stopped the reference from being copied wholesale: its query asks
## for `id, genes, newGenes`, and parse_response() throws out any axie with a null class or no
## parts. A GET carrying the reference's own field list would turn the 403 into "No Axie with
## that ID" — the same failure wearing a message that blames the player's typing.
func test_the_403_workaround_is_sent_on_both_curl_attempts() -> void:
	_assert(AxieApi.APOLLO_HEADER == "Apollo-Require-Preflight:true",
		"the preflight header is '%s'; the reference demo sends "
		% AxieApi.APOLLO_HEADER + "'Apollo-Require-Preflight:true' and this is the whole fix")

	var url := AxieApi.build_get_url("123")
	_assert(url.begins_with(AxieApi.ENDPOINT + "?query="),
		"the GET retry should hit the gateway's query string, got '%s'" % url)
	_assert(url.contains("123"), "the GET retry lost the axie id: %s" % url)
	# Percent-encoded, so the field names appear as %20-separated text rather than raw.
	var decoded := url.uri_decode()
	for field in ["class", "parts", "newGenes", "specialGenes"]:
		_assert(decoded.contains(field),
			"the GET retry does not ask for '%s'; parse_response() rejects an axie without "
			% field + "class or parts, so this retry would report 'No Axie with that ID'")
	_assert(not decoded.contains("genes,"),
		"the GET retry asks for the legacy 66-char `genes`; AxieDescriptor.from_genes() is a "
		+ "512-bit decoder and would build a confident wrong Axie from it")
	_assert(not url.contains(" "),
		"the GET url carries a raw space and curl would treat it as a second argument: %s" % url)
	_done("test_the_403_workaround_is_sent_on_both_curl_attempts")


## The retry costs a whole round trip, so it may only fire when the first attempt never
## reached a resolver. A mistyped id must NOT be asked twice: the gateway already answered,
## the answer will not change this second, and the player would wait twice as long to be told
## about a typo.
func test_only_a_transport_failure_is_retried() -> void:
	for err in ["blocked", "network", "empty", "bad_json"]:
		_assert(AxieApi._worth_retrying(err),
			"'%s' means the request never got through and should be retried as a GET" % err)
	for err in ["not_found", "graphql", "bad_id", "io", "unavailable", ""]:
		_assert(not AxieApi._worth_retrying(err),
			"'%s' is the gateway having answered; retrying doubles the wait and changes "
			% err + "nothing")
	_done("test_only_a_transport_failure_is_retried")


func _assert(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)


## A canned gateway response, built from the real field names.
func _response(axie) -> String:
	return JSON.stringify({"data": {"axie": axie}})


func test_only_a_plain_number_is_accepted_as_an_axie_id() -> void:
	for good in ["1", "123", "4154", "11778888"]:
		_assert(AxieApi.is_valid_axie_id(good), "'%s' is a valid Axie ID and was rejected" % good)
	_assert(AxieApi.is_valid_axie_id("  123  "),
		"a pasted ID with surrounding spaces was rejected — copying an ID off a web page is the "
		+ "normal way to get one")
	for bad in ["", "   ", "abc", "12a", "-1", "1.5", "12 34", "999999999999999"]:
		_assert(not AxieApi.is_valid_axie_id(bad), "'%s' was accepted as an Axie ID" % bad)
	# Leading zeros: the API would treat "007" and "7" as the same Axie, but the vault files
	# records under `vault_<id>`, so they would become two entries for one animal.
	_assert(not AxieApi.is_valid_axie_id("007"),
		"'007' was accepted — it is the same Axie as '7' to the API but a different vault key here")
	_done("test_only_a_plain_number_is_accepted_as_an_axie_id")


## The single most dangerous line in the whole feature.
func test_the_query_asks_for_new_genes_and_not_the_short_legacy_field() -> void:
	_assert(AxieApi.QUERY.contains("newGenes"),
		"the query no longer asks for `newGenes` — the 3D preview has nothing to build from")
	# `genes` appears inside the word `newGenes`, so look for it as a standalone field.
	_assert(not AxieApi.QUERY.contains(" genes"),
		"the query asks for the legacy `genes` field. It is 256-bit; `from_genes()` is a 512-bit "
		+ "decoder and will NOT error on it — it will decode nonsense and build a confident, "
		+ "wrong Axie with no symptom at all.")

	var payload := AxieApi.build_payload(" 4154 ")
	var parsed = JSON.parse_string(payload)
	_assert(parsed is Dictionary, "build_payload() did not produce valid JSON")
	if parsed is Dictionary:
		var vars: Dictionary = (parsed as Dictionary).get("variables", {})
		_assert(str(vars.get("axieId", "")) == "4154",
			"the payload sent axieId '%s' — the ID was not trimmed before being sent"
			% str(vars.get("axieId", "")))
	_done("test_the_query_asks_for_new_genes_and_not_the_short_legacy_field")


func test_a_real_response_parses_into_the_shape_the_vault_stores() -> void:
	var body := _response({
		"id": "123", "class": "Plant", "newGenes": REAL_NEW_GENES,
		"parts": [
			{"id": "eyes-papi", "name": "Papi", "class": "Plant", "type": "Eyes",
				"specialGenes": null},
			{"id": "ears-pogona", "name": "Pogona", "class": "Reptile", "type": "Ears",
				"specialGenes": null},
			{"id": "mouth-serious", "name": "Serious", "class": "Plant", "type": "Mouth",
				"specialGenes": null},
			{"id": "horn-rose-bud", "name": "Rose Bud", "class": "Plant", "type": "Horn",
				"specialGenes": null},
			{"id": "back-cupid", "name": "Cupid", "class": "Bird", "type": "Back",
				"specialGenes": null},
			{"id": "tail-ant", "name": "Ant", "class": "Bug", "type": "Tail",
				"specialGenes": null},
		],
	})
	var res := AxieApi.parse_response(0, body)
	_assert(bool(res["ok"]), "a real response was rejected: %s" % str(res.get("err", "")))
	var axie: Dictionary = res["axie"]
	_assert(typeof(axie.get("id")) == TYPE_STRING and str(axie["id"]) == "123",
		"the id came back as %s — the vault files records under `vault_<id>` and needs a String"
		% type_string(typeof(axie.get("id"))))
	_assert(str(axie.get("class", "")) == "Plant", "the class was lost")
	_assert(str(axie.get("genes", "")) == REAL_NEW_GENES, "the gene string was altered in parsing")
	_assert((axie.get("parts", []) as Array).size() == 6,
		"%d parts survived parsing, expected 6" % (axie.get("parts", []) as Array).size())

	# The end-to-end point of the whole layer: this payload must produce a real die.
	var die := AxieToDie.build({"id": axie["id"], "class": axie["class"], "parts": axie["parts"]})
	_assert((die.get("die", []) as Array).size() == 6,
		"the parsed response did not build a six-face die")
	_assert(int(die.get("max_hp", 0)) > 0, "the parsed response built an Axie with no HP")
	_done("test_a_real_response_parses_into_the_shape_the_vault_stores")


## Pins the two gene strings against each other and against the vendor's own golden, so reading
## the wrong field becomes a red test instead of a subtly wrong-looking Axie.
func test_the_gene_it_returns_is_the_one_the_3d_kit_can_actually_decode() -> void:
	_assert(REAL_NEW_GENES.length() == 130,
		"the pinned newGenes is %d characters; a 512-bit gene is 130 with the 0x"
		% REAL_NEW_GENES.length())
	_assert(REAL_OLD_GENES.length() < 80,
		"the pinned legacy gene is no longer obviously shorter — the contrast this test relies on "
		+ "is gone")

	var path := ProjectSettings.globalize_path("res://").path_join(GOLDEN_REL)
	if FileAccess.file_exists(path):
		var golden = JSON.parse_string(FileAccess.get_file_as_string(path))
		if golden is Dictionary:
			for e in (golden as Dictionary).get("ids", []):
				if str((e as Dictionary).get("id", "")) != "123":
					continue
				_assert(str((e as Dictionary).get("genes", "")) == REAL_NEW_GENES,
					"the live `newGenes` for Axie #123 no longer matches the vendor golden — "
					+ "either the API changed format or the wrong field is pinned here")

	# And the decisive difference: the right string builds the Axie the golden describes; the
	# wrong one does not, WITHOUT erroring.
	var good := AxieGenePreview.inspect(REAL_NEW_GENES)
	_assert(bool(good["ok"]) and bool(good["complete"]),
		"the 512-bit gene did not build a complete Axie (reason '%s')" % str(good["reason"]))
	_assert(str(good["body_name"]) == "Normal" and int(good["color_variant"]) == 8,
		"Axie #123 decoded as %s/colour %d; the golden says Normal/8"
		% [str(good["body_name"]), int(good["color_variant"])])

	var bad := AxieGenePreview.inspect(REAL_OLD_GENES)
	_assert(not (bool(bad["ok"]) and bool(bad["complete"])
			and str(bad["body_name"]) == "Normal" and int(bad["color_variant"]) == 8),
		"the LEGACY 256-bit gene decoded to the same Axie as the 512-bit one. That would mean "
		+ "this test cannot tell the two fields apart, which is the only thing it is for.")
	_done("test_the_gene_it_returns_is_the_one_the_3d_kit_can_actually_decode")


func test_a_cloudflare_challenge_is_named_as_a_block_not_as_bad_json() -> void:
	var html := "<!DOCTYPE html><html lang=\"en-US\"><head><title>Just a moment...</title></head>"
	var res := AxieApi.parse_response(0, html)
	_assert(not bool(res["ok"]), "a Cloudflare challenge page was accepted as Axie data")
	_assert(str(res["err"]) == "blocked",
		"a challenge page reported '%s'; it must be 'blocked', or the next person to hit this "
		% str(res["err"]) + "goes looking for a bug in the JSON parser")
	_assert(str(res["message"]).to_lower().contains("block"),
		"the player-facing message does not say the request was blocked: '%s'"
		% str(res["message"]))
	_done("test_a_cloudflare_challenge_is_named_as_a_block_not_as_bad_json")


func test_a_missing_axie_is_not_mistaken_for_a_valid_one() -> void:
	# The two shapes the API really uses for an id that does not exist.
	for body in [
		_response(null),
		_response({"id": "999999999", "class": null, "newGenes": "", "parts": []}),
	]:
		var res := AxieApi.parse_response(0, body)
		_assert(not bool(res["ok"]), "an unminted Axie was accepted as real")
		_assert(str(res["err"]) == "not_found",
			"an unminted Axie reported '%s', expected 'not_found'" % str(res["err"]))
	_done("test_a_missing_axie_is_not_mistaken_for_a_valid_one")


## MEASURED against the live gateway 2026-09-19: an id that does not exist answers with a NULL
## axie AND an `errors` entry (`INTERNAL_SERVER_ERROR`, path ["axie"]) in the SAME body. Reading
## `errors` first renames "no Axie with that ID" into "the service rejected the request" — which
## sends a player who mistyped one digit off to check their connection, and the next person
## debugging off to look for an outage that never happened. `data` decides; `errors` only speaks
## when `data` carries no axie field to speak for itself.
func test_a_typo_is_named_a_typo_even_though_the_gateway_also_reports_an_error() -> void:
	var gateway_body := JSON.stringify({
		"data": {"axie": null},
		"errors": [{
			"message": "Internal Server Error",
			"locations": [{"line": 1, "column": 20}],
			"path": ["axie"],
			"extensions": {"type": "INTERNAL_SERVER_ERROR"},
		}],
	})
	var res := AxieApi.parse_response(0, gateway_body)
	_assert(not bool(res["ok"]), "a null axie was accepted as a real one")
	_assert(str(res["err"]) == "not_found",
		"the gateway's real 'no such Axie' body reported '%s'; expected 'not_found'"
		% str(res["err"]))
	_assert(str(res["message"]).to_lower().contains("no axie"),
		"a mistyped ID tells the player '%s'" % str(res["message"]))

	# The other half of the rule. Without this, the line above could be satisfied by ignoring
	# `errors` altogether, and a real outage would be reported to the player as a typo.
	for broken in [
		JSON.stringify({"errors": [{"message": "nope"}]}),
		JSON.stringify({"data": null, "errors": [{"message": "nope"}]}),
		JSON.stringify({"data": {}, "errors": [{"message": "nope"}]}),
	]:
		var bad := AxieApi.parse_response(0, broken)
		_assert(str(bad["err"]) == "graphql",
			"a gateway error with no axie field reported '%s'; expected 'graphql'"
			% str(bad["err"]))
	_done("test_a_typo_is_named_a_typo_even_though_the_gateway_also_reports_an_error")


## Every branch has to be distinguishable by machine AND explainable to a person. A shared error
## key means the screen cannot react differently; a missing message means it shows nothing.
func test_every_failure_mode_has_its_own_key_and_a_sentence_for_the_player() -> void:
	var cases := {
		"network": AxieApi.parse_response(7, ""),
		"empty": AxieApi.parse_response(0, ""),
		"bad_json": AxieApi.parse_response(0, "{not json"),
		"graphql": AxieApi.parse_response(0, JSON.stringify({"errors": [{"message": "nope"}]})),
		"not_found": AxieApi.parse_response(0, _response(null)),
	}
	var seen := {}
	for want in cases:
		var res: Dictionary = cases[want]
		_assert(not bool(res["ok"]), "failure case '%s' reported success" % want)
		_assert(str(res["err"]) == want,
			"case '%s' reported err '%s'" % [want, str(res["err"])])
		_assert(not str(res["message"]).is_empty(),
			"case '%s' has no message — the screen would show an empty error" % want)
		_assert(not seen.has(str(res["message"])),
			"case '%s' reuses another case's wording ('%s'); the player cannot tell them apart"
			% [want, str(res["message"])])
		seen[str(res["message"])] = true
		_assert(res["axie"] is Dictionary and (res["axie"] as Dictionary).is_empty(),
			"case '%s' returned an axie payload alongside a failure" % want)
	_done("test_every_failure_mode_has_its_own_key_and_a_sentence_for_the_player")


## The honest limit of this approach: it needs a desktop and a `curl`. That has to be reported,
## not discovered.
func test_availability_is_reported_rather_than_assumed() -> void:
	var available := AxieApi.is_available()
	if available:
		_assert(not AxieApi.curl_path().is_empty(),
			"is_available() says yes but there is no curl path")
		_assert(AxieApi.unavailable_reason().is_empty(),
			"is_available() says yes but a reason is still being reported")
	else:
		_assert(not AxieApi.unavailable_reason().is_empty(),
			"import is unavailable and NO reason is given — the Vault screen would disable its "
			+ "field with nothing to tell the player")
	# Whatever the machine, asking for a fetch when it cannot work must fail loudly rather than
	# hanging or doing nothing.
	var api := AxieApi.new()
	add_child(api)
	var got: Array[Dictionary] = []
	api.completed.connect(func(r: Dictionary) -> void: got.append(r))
	api.request_axie("not-a-number")
	_assert(got.size() == 1, "a malformed ID produced %d results, expected 1 immediate failure"
		% got.size())
	if got.size() == 1:
		_assert(str(got[0]["err"]) == "bad_id",
			"a malformed ID reported '%s', expected 'bad_id'" % str(got[0]["err"]))
	api.queue_free()
	_done("test_availability_is_reported_rather_than_assumed")


## The web path. A desktop machine never exercises it, so without this gate the whole browser
## transport would ship untested — and the bug would surface only after a deploy.
func test_the_proxy_transport_produces_the_same_shape_as_curl() -> void:
	# The proxy answers with the axie already unwrapped, so it has its own parser. Both must hand
	# the rest of the game an identical record, or a screen would have to know which transport it
	# got its Axie from.
	var proxy_body := JSON.stringify({
		"id": "123", "class": "Plant", "genes": REAL_NEW_GENES,
		"parts": [
			{"id": "eyes-papi", "name": "Papi", "class": "Plant", "type": "Eyes",
				"specialGenes": null},
			{"id": "ears-pogona", "name": "Pogona", "class": "Reptile", "type": "Ears",
				"specialGenes": null},
			{"id": "mouth-serious", "name": "Serious", "class": "Plant", "type": "Mouth",
				"specialGenes": null},
			{"id": "horn-rose-bud", "name": "Rose Bud", "class": "Plant", "type": "Horn",
				"specialGenes": null},
			{"id": "back-cupid", "name": "Cupid", "class": "Bird", "type": "Back",
				"specialGenes": null},
			{"id": "tail-ant", "name": "Ant", "class": "Bug", "type": "Tail",
				"specialGenes": null},
		],
	})
	var via_proxy := AxieApi.parse_proxy_response(HTTPRequest.RESULT_SUCCESS, 200, proxy_body)
	_assert(bool(via_proxy["ok"]), "a good proxy response was rejected: %s" % str(via_proxy["err"]))

	var gateway_body := _response({
		"id": "123", "class": "Plant", "newGenes": REAL_NEW_GENES,
		"parts": JSON.parse_string(proxy_body)["parts"],
	})
	var via_curl := AxieApi.parse_response(0, gateway_body)
	_assert(bool(via_curl["ok"]), "the matching gateway response was rejected")
	_assert(str(via_proxy["axie"]) == str(via_curl["axie"]),
		"the two transports produce DIFFERENT records for the same Axie.\n  proxy: %s\n  curl:  %s"
		% [str(via_proxy["axie"]), str(via_curl["axie"])])

	# A proxy that forwards the gateway's own field name instead of renaming it must still work —
	# that is the single likeliest mistake in a hand-written proxy.
	var forwarded := AxieApi.parse_proxy_response(HTTPRequest.RESULT_SUCCESS, 200,
		JSON.stringify({"id": "123", "class": "Plant", "newGenes": REAL_NEW_GENES,
			"parts": JSON.parse_string(proxy_body)["parts"]}))
	_assert(bool(forwarded["ok"]) and str(forwarded["axie"]["genes"]) == REAL_NEW_GENES,
		"a proxy that passes the gateway's `newGenes` through unrenamed produced no gene string")

	# Every HTTP failure the proxy can answer with needs its own key and its own sentence.
	var http_cases := {
		404: "not_found", 429: "rate_limited", 502: "upstream", 500: "proxy",
	}
	var wordings := {}
	for code in http_cases:
		var res := AxieApi.parse_proxy_response(HTTPRequest.RESULT_SUCCESS, int(code), "")
		_assert(not bool(res["ok"]), "HTTP %d was treated as success" % int(code))
		_assert(str(res["err"]) == str(http_cases[code]),
			"HTTP %d reported '%s', expected '%s'" % [int(code), str(res["err"]),
				str(http_cases[code])])
		_assert(not str(res["message"]).is_empty(), "HTTP %d has no message" % int(code))
		_assert(not wordings.has(str(res["message"])),
			"HTTP %d reuses another case's wording" % int(code))
		wordings[str(res["message"])] = true

	var dead := AxieApi.parse_proxy_response(HTTPRequest.RESULT_CANT_CONNECT, 0, "")
	_assert(str(dead["err"]) == "network", "an unreachable proxy did not report as a network error")
	_done("test_the_proxy_transport_produces_the_same_shape_as_curl")


## Which transport a build uses is a decision with real consequences — a web build silently
## falling back to nothing is the failure the user asked about before it could happen.
func test_the_transport_is_chosen_by_what_the_build_can_actually_do() -> void:
	var saved := AxieApi.proxy_url()
	AxieApi.set_proxy_url("")

	if OS.get_name() != "Web" and not AxieApi.curl_path().is_empty():
		_assert(AxieApi.active_transport() == AxieApi.Transport.CURL,
			"a desktop machine with curl did not choose the curl transport")
		_assert(AxieApi.is_available(), "curl is present but import reports unavailable")
		# curl must keep winning once a proxy exists: it needs no server to be up.
		AxieApi.set_proxy_url("https://example.test/api/axie")
		_assert(AxieApi.active_transport() == AxieApi.Transport.CURL,
			"configuring a proxy made a desktop build stop using local curl — that adds a server "
			+ "dependency to a path that never needed one")

	# With no curl AND no proxy there must be a reason, not silence. Simulated by clearing the
	# proxy: on a machine without curl this is exactly the web build's situation.
	AxieApi.set_proxy_url("")
	if AxieApi.curl_path().is_empty():
		_assert(AxieApi.active_transport() == AxieApi.Transport.NONE,
			"no curl and no proxy, yet a transport was reported")
		_assert(not AxieApi.unavailable_reason().is_empty(),
			"import is impossible on this build and no reason is given")

	# And a configured proxy must be usable by something that has no curl.
	AxieApi.set_proxy_url("https://example.test/api/axie")
	_assert(AxieApi.is_available(), "a configured proxy did not make import available")
	AxieApi.set_proxy_url(saved)
	_done("test_the_transport_is_chosen_by_what_the_build_can_actually_do")
