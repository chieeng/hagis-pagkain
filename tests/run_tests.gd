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
	var tests := [test_rule, test_stage_and_highlight, test_data_files, test_progress, test_session,
		test_choices_and_island, test_review_mix, test_exception_gate, test_pair_stats]
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
	check("highlight Ikaw", Hints.highlight_word("Ikaw"), "Ika[color=%s][b]w[/b][/color]" % GameConfig.R_COLOR)
	check("highlight colour for d", Hints.letter_color("Gutom"), GameConfig.D_COLOR)
	check("highlight colour for exception", Hints.letter_color("mura"), GameConfig.D_COLOR)
	var item := {"sentence": "Ikaw ___ ang taya.", "prev_word": "Ikaw", "answer": "rin"}
	check("highlighted sentence", Hints.highlighted_sentence(item),
		"Ika[color=%s][b]w[/b][/color] ___ ang taya." % GameConfig.R_COLOR)
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
	var all_ids := {}
	for biome in ["forest", "river", "mountain", "sky", "island"]:
		check("%s has %d animals" % [biome, GameConfig.ANIMALS_PER_BIOME], animals[biome].size(), GameConfig.ANIMALS_PER_BIOME)
		for a in animals[biome]:
			check("animal id %s unique" % a.id, all_ids.has(a.id), false)
			all_ids[a.id] = true
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
	# Learning inside the game: the letter glow fades with correct throws and comes back after a miss.
	check("new stage not met", p.has_met_stage("forest", "wy"), false)
	check("glow starts full", p.help_level("forest", "wy"), 1.0)
	p.meet_stage("forest", "wy")
	check("stage met", p.has_met_stage("forest", "wy"), true)
	check("meeting keeps full glow", p.help_level("forest", "wy"), 1.0)
	for i in 3:
		p.update_help("forest", "wy", true)
	check("glow fades with correct throws", p.help_level("forest", "wy"), 1.0 - 3 * GameConfig.HELP_FADE_STEP)
	for i in 5:
		p.update_help("forest", "wy", true)
	check("glow stops at 0", p.help_level("forest", "wy"), 0.0)
	p.update_help("forest", "wy", false)
	check("a miss brings the glow back", p.help_level("forest", "wy"), GameConfig.HELP_ON_MISS)
	var copy := Progress.new()
	copy.from_dict(JSON.parse_string(JSON.stringify(p.to_dict())))
	check("save round trip", copy.collected_count("forest"), 1)
	check("help saved", copy.help_level("forest", "wy"), GameConfig.HELP_ON_MISS)
	finished += 1


func _items(biome := "forest", particle := "din") -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var d := DRRule.d_form(particle)
	var r := DRRule.r_form(particle)
	var pair := "%s/%s" % [d, r]
	for row in [["v1", "vowel", "Masaya", r], ["v2", "vowel", "ka", r],
			["c1", "consonant", "Gutom", d], ["c2", "consonant", "Matamis", d],
			["w1", "wy", "Ikaw", r], ["w2", "wy", "Kahoy", r]]:
		out.append({"id": "%s-%s" % [biome, row[0]], "stage": row[1], "prev_word": row[2], "answer": row[3],
			"sentence": "%s ___ x." % row[2], "biome": biome, "pair": pair, "status": "draft"})
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

	# Correct throw: the animal follows; it joins the pen (and pays coins) only when delivered.
	var r := s.answer(item.answer)
	check("correct", r.correct, true)
	check("no hint after correct", r.hint_level, 0)
	check("coins on a correct throw", p.coins, GameConfig.RARITY_COINS.common)
	check("not in the pen before delivery", p.collected_count("forest"), 0)
	var d := s.deliver(r.animal_id)
	check("animal collected on delivery", p.collected_count("forest"), 1)
	check("new animal flag", d.new_animal, true)
	check("common variant recorded", p.has_variant("forest", r.animal_id, "common"), true)

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

	# Several animals at once: busy animals and sentences are not handed out twice.
	var p3 := Progress.new()
	var s3 := BiomeSession.new("forest", _items(), _animals(8), p3, 3)
	var busy_a := []
	var busy_i := []
	for i in 4:
		var it := s3.next_sentence(busy_a, busy_i)
		busy_a.append(s3.current_animal.id)
		busy_i.append(it.id)
	var unique_a := {}
	for a in busy_a:
		unique_a[a] = true
	check("4 different animals out at once", unique_a.size(), 4)

	# Streaks: rare after 3 in a row, golden after 6, coin multiplier grows; a miss resets.
	var p4 := Progress.new()
	var s4 := BiomeSession.new("forest", _items(), _animals(8), p4, 4)
	check("starts common", s4.next_rarity(), "common")
	for i in GameConfig.RARE_STREAK:
		var it := s4.next_sentence()
		s4.answer(it.answer)
	check("rare after 3 in a row", s4.next_rarity(), "rare")
	check("multiplier x2 after 3", s4.multiplier(), 2)
	for i in GameConfig.GOLDEN_STREAK - GameConfig.RARE_STREAK:
		var it := s4.next_sentence()
		s4.answer(it.answer)
	check("golden after 6 in a row", s4.next_rarity(), "golden")
	var before := p4.coins
	var it2 := s4.next_sentence()
	var rr := s4.answer(it2.answer, {}, {}, "golden")
	check("golden coins = rarity x multiplier", p4.coins - before, GameConfig.RARITY_COINS.golden * rr.multiplier)
	var it3 := s4.next_sentence()
	var wrong3 := DRRule.r_form(it3.answer) if it3.answer == DRRule.d_form(it3.answer) else DRRule.d_form(it3.answer)
	s4.answer(wrong3)
	check("a miss resets the streak", s4.streak, 0)
	check("no coins for a miss", p4.coins - before, GameConfig.RARITY_COINS.golden * rr.multiplier)
	check("back to common after a miss", s4.next_rarity(), "common")

	# Fruit shop
	var p5 := Progress.new()
	check("cannot buy without coins", p5.buy_fruit("mangga"), false)
	p5.coins = 45
	check("buy mangga", p5.buy_fruit("mangga"), true)
	check("coins spent", p5.coins, 5)
	check("mangga equipped", p5.equipped_tier().id, "mangga")
	check("switch back for free", p5.buy_fruit("bayabas"), true)
	check("coins unchanged on switch", p5.coins, 5)
	var copy5 := Progress.new()
	copy5.from_dict(JSON.parse_string(JSON.stringify(p5.to_dict())))
	check("shop saved", copy5.owned_fruits.has("mangga"), true)

	# Unlocking needs the whole Index AND 80% in every stage.
	var p2 := Progress.new()
	var s2 := BiomeSession.new("forest", _items(), _animals(2), p2, 2)
	var cleared := false
	for i in 200:
		var x := s2.next_sentence()
		var ans := s2.answer(x.answer)
		cleared = s2.deliver(ans.animal_id).cleared
		if cleared:
			break
	check("cleared after enough correct answers", cleared, true)
	check("every stage window full when cleared", p2.stage_window("forest", "wy").size(), GameConfig.ACCURACY_WINDOW)
	finished += 1


## Three foods from the River biome on; Island plays mixed with the pair's own two [proposal].
func test_choices_and_island() -> void:
	var p := Progress.new()
	var s := BiomeSession.new("river", _items("river", "daw"), _animals(8), p, 6)
	var item := s.next_sentence()
	check("river has 3 choices", s.current_choices.size(), 3)
	check("choices include d-form", s.current_choices.has(DRRule.d_form(item.answer)), true)
	check("choices include r-form", s.current_choices.has(DRRule.r_form(item.answer)), true)
	var third := ""
	for c in s.current_choices:
		if DRRule.d_form(c) != DRRule.d_form(item.answer):
			third = c
	check("third choice is another pair's form", DRRule.is_supported(third) and third != "", true)
	check("picking the third choice is wrong", s.answer(third).correct, false)

	var island := BiomeSession.new("island", _items("island", "doon"), _animals(8), p, 7)
	check("island plays mixed from the start", island.mixed, true)
	island.next_sentence()
	check("island is back to 2 choices", island.current_choices.size(), 2)
	finished += 1


## Spiral review [proposal]: about 30% of sentences come from earlier biomes.
func test_review_mix() -> void:
	var p := Progress.new()
	var s := BiomeSession.new("river", _items("river", "daw"), _animals(8), p, 8, _items("forest", "din"))
	var review := 0
	var own := 0
	for i in 60:
		var item := s.next_sentence()
		if item.biome == "forest":
			review += 1
		else:
			own += 1
		s.answer(item.answer)
	check("some sentences are review", review > 5, true)
	check("most sentences are the biome's own", own > review, true)
	check("review answers are recorded under this biome", p.stage_window("forest", "vowel").is_empty(), true)
	finished += 1


## Sky's exception stage opens only after 80% on the three regular stages [proposal, GO4].
func test_exception_gate() -> void:
	var p := Progress.new()
	var items := _items("sky", "doon")
	items.append({"id": "sky-x1", "stage": "exception", "prev_word": "Mura", "answer": "din",
		"sentence": "Mura ___ x.", "biome": "sky", "pair": "din/rin", "status": "draft"})
	var s := BiomeSession.new("sky", items, _animals(8), p, 9)
	check("exception stage exists", s.stages.has("exception"), true)
	check("exception closed at the start", s.stage_open("exception"), false)
	check("unlock check ignores the exception stage", s.unlock_stages().has("exception"), false)
	# No exception sentence appears while the gate is closed (run through all the stages).
	for i in GameConfig.STAGE_LENGTH * 4:
		var item := s.next_sentence()
		check("no exception sentence while closed", item.stage == "exception", false)
		s.answer(item.answer)
	for stage in ["vowel", "consonant", "wy"]:
		for i in GameConfig.ACCURACY_WINDOW:
			p.record("sky", stage, true)
	check("exception opens after 80% on regular stages", s.stage_open("exception"), true)
	# Mixed practice now favours the unmet exception stage.
	s.mixed = true
	check("weakest open stage is exception", s.current_stage(), "exception")
	finished += 1


## My Progress data: accuracy per pair and context, and the missed-sentence list [proposal].
func test_pair_stats() -> void:
	var p := Progress.new()
	var s := BiomeSession.new("forest", _items(), _animals(8), p, 10)
	var item := s.next_sentence()
	var wrong := DRRule.d_form(item.answer) if item.answer != DRRule.d_form(item.answer) else DRRule.r_form(item.answer)
	s.answer(wrong)
	check("miss recorded per pair", p.pair_accuracy("din/rin", item.stage), 0.0)
	check("missed sentence listed", p.missed_items.has(item.id), true)
	for i in GameConfig.REQUEUE_GAP:
		s.answer(s.next_sentence().answer)
	var back := s.next_sentence()
	check("missed sentence comes back for review", back.id, item.id)
	s.answer(back.answer)
	check("right answer clears it from the review list", p.missed_items.has(item.id), false)
	check("no data gives -1", p.pair_accuracy("daw/raw", "vowel"), -1.0)
	var copy := Progress.new()
	copy.from_dict(JSON.parse_string(JSON.stringify(p.to_dict())))
	check("pair stats saved", copy.pair_accuracy("din/rin", item.stage) >= 0.0, true)
	finished += 1
