extends SceneTree
## Owner: Irish. No add-ons needed.
## Run from the project folder (open the project in the editor once first):
##   godot --headless -s tests/run_tests.gd
## Exit code 0 = all passed, 1 = something failed.

const Rule := preload("res://core/DRRule.gd")
const Bank := preload("res://autoload/QuestionBank.gd")

var failures := 0
var passed := 0


func _init() -> void:
	test_rule()
	test_data_files()
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


## Every item in data/ must pass validation, including "answer matches the rule".
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
