extends Node
## Owner: Jian (Content).
## Loads question items from res://data/items_*.json and animals from res://data/animals.json.
## See data/README.md for the format.

const DATA_DIR := "res://data/"
const ANIMALS_FILE := "res://data/animals.json"
const REQUIRED_FIELDS := ["id", "biome", "pair", "stage", "sentence", "prev_word", "answer", "translation", "status"]

## Prototype: true shows draft items too. Set false for the pilot/evaluation build
## so learners only see adviser-approved items.
@export var include_drafts: bool = true

var _items: Array[Dictionary] = []
var _animals: Dictionary = {}


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
	var animals = JSON.parse_string(FileAccess.get_file_as_string(ANIMALS_FILE))
	_animals = animals if animals is Dictionary else {}


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
## Also checks that the answer is the KWF preferred form for prev_word,
## and that the stage tag matches the last sound of prev_word.
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
	var sentence := str(item.sentence)
	var blank := sentence.find("___")
	if blank == -1:
		problems.append("sentence has no ___ blank")
	# Search only the text before the blank. (rfind with a `from` argument returns -1
	# whenever from + the word's length passes the end of the string, so it misses
	# prev_words in sentences that end right after the blank.)
	elif sentence.left(blank).rfind(str(item.prev_word)) == -1:
		problems.append("prev_word '%s' is not before the blank" % item.prev_word)
	if not DRRule.is_supported(item.answer):
		problems.append("answer '%s' is not one of the five pairs" % item.answer)
	elif DRRule.preferred_form(item.prev_word, item.answer) != item.answer:
		problems.append("answer '%s' does not match the rule after '%s' (expected '%s')"
			% [item.answer, item.prev_word, DRRule.preferred_form(item.prev_word, item.answer)])
	if item.stage != DRRule.stage(item.prev_word):
		problems.append("stage '%s' should be '%s' for '%s'" % [item.stage, DRRule.stage(item.prev_word), item.prev_word])
	if not item.status in ["draft", "approved"]:
		problems.append("status must be draft or approved")
	return problems


func get_items(biome: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for item in _items:
		# Island mixes every pair and context; it reuses the other biomes' sentences [proposal].
		if (item.biome == biome or biome == "island") and (include_drafts or item.status == "approved"):
			out.append(item)
	return out


## Items from the biomes before `biome` in `biome_order` (pass GameState.BIOME_ORDER),
## for spiral review [proposal]. Island needs none: its own pool already mixes everything.
## The order is a parameter so this script compiles without the autoloads (tests run it alone).
func get_review_items(biome: String, biome_order: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if biome == "island":
		return out
	var idx: int = biome_order.find(biome)
	for i in range(0, maxi(idx, 0)):
		out.append_array(get_items(str(biome_order[i])))
	return out


func find_item(item_id: String) -> Dictionary:
	for item in _items:
		if item.id == item_id:
			return item
	return {}


func get_animals(biome: String) -> Array:
	return _animals.get(biome, [])


func find_animal(animal_id: String) -> Dictionary:
	for biome in _animals:
		if biome.begins_with("_"):
			continue
		for a in _animals[biome]:
			if a.id == animal_id:
				return a
	return {}


func count() -> int:
	return _items.size()
