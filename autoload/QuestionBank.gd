extends Node
## Owner: Jian (Content).
## Loads question items from res://data/items_*.json. See data/README.md for the format.

const DATA_DIR := "res://data/"
const REQUIRED_FIELDS := ["id", "biome", "pair", "sentence", "prev_word", "answer", "translation", "status"]

## Prototype: true shows draft items too. Set false for the pilot/evaluation build
## so learners only see adviser-approved items.
@export var include_drafts: bool = true

var _items: Array[Dictionary] = []


func _ready() -> void:
	reload()


func reload() -> void:
	_items.clear()
	var dir := DirAccess.open(DATA_DIR)
	if dir == null:
		push_error("QuestionBank: cannot open %s" % DATA_DIR)
		return
	for file_name in dir.get_files():
		if file_name.begins_with("items_") and file_name.ends_with(".json"):
			_load_file(DATA_DIR + file_name)


func _load_file(path: String) -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Array:
		push_error("QuestionBank: %s must be a JSON array" % path)
		return
	for item in data:
		var problems := validate_item(item)
		if problems.is_empty():
			_items.append(item)
		else:
			push_error("QuestionBank: %s item %s skipped: %s" % [path, item.get("id", "?"), ", ".join(problems)])


## Returns a list of problems; empty = item is OK.
## Also checks that the answer is the KWF preferred form for prev_word.
static func validate_item(item) -> Array[String]:
	var problems: Array[String] = []
	if not item is Dictionary:
		problems.append("not an object")
		return problems
	for field in REQUIRED_FIELDS:
		if not item.has(field):
			problems.append("missing '%s'" % field)
	if not problems.is_empty():
		return problems
	if not "___" in str(item.sentence):
		problems.append("sentence has no ___ blank")
	if not DRRule.is_supported(item.answer):
		problems.append("answer '%s' is not one of the five pairs" % item.answer)
	elif DRRule.preferred_form(item.prev_word, item.answer) != item.answer:
		problems.append("answer '%s' does not match the rule after '%s' (expected '%s')"
			% [item.answer, item.prev_word, DRRule.preferred_form(item.prev_word, item.answer)])
	if not item.status in ["draft", "approved"]:
		problems.append("status must be draft or approved")
	return problems


func get_items(biome: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for item in _items:
		if item.biome == biome and (include_drafts or item.status == "approved"):
			out.append(item)
	return out


func count() -> int:
	return _items.size()
