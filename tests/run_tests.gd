extends SceneTree
## Owner: Irish. No add-ons needed.
## Run from the project folder (open the project in the editor once first):
##   godot --headless -s tests/run_tests.gd
## Exit code 0 = all passed, 1 = something failed.

const Rule := preload("res://core/DRRule.gd")
const Bank := preload("res://autoload/QuestionBank.gd")

var failures := 0
var passed := 0
## A script error stops a test function but not the runner, so count the ones that finished.
var finished := 0


func _init() -> void:
	var tests := [test_rule, test_stage_and_highlight, test_data_files, test_progress, test_session]
	for t in tests:
		t.call()
	# Each test function adds 1 to `finished` as its last line; a script error skips that.
	if finished != tests.size():
		failures += 1
		printerr("FAIL only %d of %d test functions finished (script error above)" % [finished, tests.size()])
	print("\n%d passed, %d failed" % [passed, failures])
	quit(1 if failures > 0 else 0)


func check(label: String, got, expected) -> void:
	if got == expected:
		passed += 1
	else:
		failures += 1
		printerr("FAIL %s: got '%s', expected '%s'" % [label, got, expected])


func test_rule() -> void:
	# [prev_word, particle asked, expected preferred form]
	var cases := [
		# Examples from the proposal
		["ikaw", "daw", "raw"],        # ends in w (semivowel)
		["bahay", "dito", "rito"],     # ends in y (semivowel)
		["masaya", "din", "rin"],      # ends in vowel
		["pinsan", "rin", "din"],      # ends in consonant; works when given the r-form too
		["mura", "rin", "din"],        # KWF exception -ra
		# KWF exceptions -ri, -raw, -ray
		["hari", "rin", "din"],
		["araw", "raw", "daw"],
		["aray", "rin", "din"],
		# -ro and -re are NOT KWF exceptions
		["libro", "din", "rin"],
		["padre", "din", "rin"],
		# All five pairs
		["bata", "diyan", "riyan"],
		["lapis", "riyan", "diyan"],
		["bata", "doon", "roon"],
		["aklat", "roon", "doon"],
		# Capitals and punctuation
		["Masaya,", "din", "rin"],
		["  Pinsan ", "rin", "din"],
	]
	for c in cases:
		check("preferred_form(%s, %s)" % [c[0], c[1]], Rule.preferred_form(c[0], c[1]), c[2])

	check("is_preferred masaya rin", Rule.is_preferred("masaya", "rin"), true)
	check("is_preferred masaya din", Rule.is_preferred("masaya", "din"), false)
	check("is_supported dati", Rule.is_supported("dati"), false)  # dati/rati is excluded
	check("reason mura", Rule.reason("mura"), Rule.REASON_EXCEPTION)
	check("reason ikaw", Rule.reason("ikaw"), Rule.REASON_SEMIVOWEL)
	finished += 1


func test_stage_and_highlight() -> void:
	check("stage ka", Rule.stage("ka"), "vowel")
	check("stage Gutom", Rule.stage("Gutom"), "consonant")
	check("stage Kahoy", Rule.stage("Kahoy"), "wy")
	check("stage Maaari", Rule.stage("Maaari"), "exception")
	check("stage libro", Rule.stage("libro"), "vowel")   # -ro is not an exception
	check("deciding_length ikaw", Rule.deciding_length("ikaw"), 1)
	check("deciding_length mura", Rule.deciding_length("mura"), 2)
	check("deciding_length araw", Rule.deciding_length("araw"), 3)
	check("highlight Ikaw", Hints.highlight_word("Ikaw"), "Ika[color=%s][b]w[/b][/color]" % Hints.HIGHLIGHT)
	var item := {"sentence": "Ikaw ___ ang taya.", "prev_word": "Ikaw", "answer": "rin"}
	check("highlighted sentence", Hints.highlighted_sentence(item),
		"Ika[color=%s][b]w[/b][/color] ___ ang taya." % Hints.HIGHLIGHT)
	check("worked example lines", Hints.worked_example(item).size(), 3)
	check("worked example ends with answer", Hints.worked_example(item)[2].contains("[b]rin[/b]"), true)
	for s in ["vowel", "consonant", "wy", "exception"]:
		check("rule line has no 'mali' (%s)" % s, Hints.RULE_LINES[s].to_lower().contains("mali"), false)


## Every item in data/ must pass validation, including "answer matches the rule".
	finished += 1


func test_data_files() -> void:
	var dir := DirAccess.open("res://data/")
	for file_name in dir.get_files():
		if not (file_name.begins_with("items_") and file_name.ends_with(".json")):
			continue
		var data = JSON.parse_string(FileAccess.get_file_as_string("res://data/" + file_name))
		check("%s is an array" % file_name, data is Array, true)
		if not data is Array:
			continue
		var ids := {}
		for item in data:
			var problems: Array[String] = Bank.validate_item(item)
			check("%s %s" % [file_name, item.get("id", "?")], ", ".join(problems), "")
			if item is Dictionary and item.has("id"):
				check("unique id %s" % item.id, ids.has(item.id), false)
				ids[item.id] = true
	var bad := {"id": "x", "biome": "forest", "pair": "din/rin", "stage": "consonant", "sentence": "Ikaw ___ ang taya.",
		"prev_word": "Ikaw", "answer": "rin", "translation": "", "status": "draft"}
	check("wrong stage tag is rejected", Bank.validate_item(bad).size(), 1)
	var animals = JSON.parse_string(FileAccess.get_file_as_string("res://data/animals.json"))
	check("forest has %d animals" % GameConfig.ANIMALS_PER_BIOME, animals.forest.size(), GameConfig.ANIMALS_PER_BIOME)
	finished += 1


func test_progress() -> void:
	var p := Progress.new()
	for i in GameConfig.ACCURACY_WINDOW - 1:
		p.record("forest", "vowel", true)
	check("not met before the window is full", p.stage_met("forest", "vowel"), false)
	p.record("forest", "vowel", true)
	check("met with 15/15", p.stage_met("forest", "vowel"), true)
	for i in 4:
		p.record("forest", "vowel", false)
	check("window keeps only the last 15", p.stage_window("forest", "vowel").size(), GameConfig.ACCURACY_WINDOW)
	check("11/15 is below 80%", p.stage_met("forest", "vowel"), false)
	check("collect new", p.collect("forest", "ibon"), true)
	check("collect again", p.collect("forest", "ibon"), false)
	check("index not complete", p.index_complete("forest", 8), false)
	check("weakest is an unpractised stage", p.weakest_stage("forest", ["vowel", "consonant"]), "consonant")
	var copy := Progress.new()
	copy.from_dict(JSON.parse_string(JSON.stringify(p.to_dict())))
	check("save round trip", copy.collected_count("forest"), 1)
	finished += 1


func _items() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for row in [["v1", "vowel", "Masaya", "rin"], ["v2", "vowel", "ka", "rin"],
			["c1", "consonant", "Gutom", "din"], ["c2", "consonant", "Matamis", "din"],
			["w1", "wy", "Ikaw", "rin"], ["w2", "wy", "Kahoy", "rin"]]:
		out.append({"id": row[0], "stage": row[1], "prev_word": row[2], "answer": row[3],
			"sentence": "%s ___ x." % row[2], "biome": "forest", "status": "draft"})
	return out


func _animals(n: int) -> Array:
	var out := []
	for i in n:
		out.append({"id": "a%d" % i, "name": "A%d" % i, "color": "#888888"})
	return out


func test_session() -> void:
	var p := Progress.new()
	var s := BiomeSession.new("forest", _items(), _animals(8), p, 1)
	check("stages found in order", s.stages, ["vowel", "consonant", "wy"] as Array[String])

	# Stage order: the first STAGE_LENGTH sentences are vowel ones.
	var item := s.next_sentence()
	check("first stage is vowel", item.stage, "vowel")
	check("two choices", s.current_choices.size(), 2)
	check("choices are the pair", s.current_choices.has("din") and s.current_choices.has("rin"), true)

	# Correct throw: animal joins the pen, coins added.
	var r := s.answer(item.answer)
	check("correct", r.correct, true)
	check("coins", p.coins, GameConfig.COINS_PER_CORRECT)
	check("animal collected", p.collected_count("forest"), 1)
	check("no hint after correct", r.hint_level, 0)

	# Wrong throw: hint level 1, no animal, the sentence is re-queued.
	item = s.next_sentence()
	var missed_id: String = item.id
	var wrong := DRRule.d_form(item.answer) if item.answer != DRRule.d_form(item.answer) else DRRule.r_form(item.answer)
	r = s.answer(wrong)
	check("wrong", r.correct, false)
	check("hint level 1", r.hint_level, 1)
	check("no animal on a miss", p.collected_count("forest"), 1)
	check("re-queued", s.requeue.size(), 1)

	# It comes back after REQUEUE_GAP other sentences; a second miss gives the worked example.
	for i in GameConfig.REQUEUE_GAP:
		var other := s.next_sentence()
		s.answer(other.answer)
	item = s.next_sentence()
	check("missed sentence comes back", item.id, missed_id)
	r = s.answer(wrong)
	check("second miss -> worked example", r.hint_level, 2)

	# After the stages run out, practice is mixed.
	for i in GameConfig.STAGE_LENGTH * 3:
		var x := s.next_sentence()
		s.answer(x.answer)
	check("mixed practice after the last stage", s.mixed, true)

	# Unlocking needs the whole Index AND 80% in every stage.
	var p2 := Progress.new()
	var s2 := BiomeSession.new("forest", _items(), _animals(2), p2, 2)
	var cleared := false
	for i in 200:
		var x := s2.next_sentence()
		cleared = s2.answer(x.answer).cleared
		if cleared:
			break
	check("cleared after enough correct answers", cleared, true)
	check("every stage window full when cleared", p2.stage_window("forest", "wy").size(), GameConfig.ACCURACY_WINDOW)
	finished += 1
