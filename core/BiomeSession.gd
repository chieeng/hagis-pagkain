class_name BiomeSession
extends RefCounted
## The game logic of one biome visit, with no visuals, so it can be unit-tested.
## BiomeTemplate (the scene) asks this for the next sentence and reports each throw.
##
## Flow [proposal, Part 3]:
##   - Stages in order: vowel -> consonant -> w/y (-> exception in Sky). Then mixed practice that
##     favours the weakest stage ("extra animals keep appearing in the weaker stage").
##   - One throw per sentence. Correct: the animal joins the pen and the learner earns coins.
##     Wrong: the animal leaves, a hint shows, and the sentence comes back later (spaced review).
##   - A second miss on the same sentence shows a worked example.
## TODO: 30% spiral review from earlier biomes, rare/golden animals, 3 foods from River on,
##       Sky's exception stage only after 80% on the regular stages, hints that fade.

var biome: String
var items: Array[Dictionary] = []
var animals: Array = []
var progress: Progress
var stages: Array[String] = []

var stage_index := 0
var answered_in_stage := 0
## True after the last stage: practice picks the weakest stage.
var mixed := false

var current: Dictionary = {}
var current_animal: Dictionary = {}
var current_choices: Array[String] = []

## item id -> number of misses
var misses: Dictionary = {}
## [{ "item": Dictionary, "due": int }]
var requeue: Array = []

var _last_item_id := ""
var _left_animal_id := ""
var rng := RandomNumberGenerator.new()


func _init(p_biome: String, p_items: Array[Dictionary], p_animals: Array, p_progress: Progress, seed: int = -1) -> void:
	biome = p_biome
	items = p_items
	animals = p_animals
	progress = p_progress
	if seed >= 0:
		rng.seed = seed
	else:
		rng.randomize()
	for s in GameConfig.STAGE_ORDER:
		for item in items:
			if item.stage == s:
				stages.append(s)
				break


func current_stage() -> String:
	if stages.is_empty():
		return ""
	if mixed:
		return progress.weakest_stage(biome, stages)
	return stages[stage_index]


## Picks the next sentence and the animal that says it. Returns {} if there are no items.
func next_sentence() -> Dictionary:
	if items.is_empty():
		return {}
	current = {}
	for i in requeue.size():
		if requeue[i].due <= 0:
			current = requeue[i].item
			requeue.remove_at(i)
			break
	if current.is_empty():
		current = _pick_from_stage(current_stage())
	_last_item_id = current.id
	current_animal = _pick_animal()
	current_choices = [DRRule.d_form(current.answer), DRRule.r_form(current.answer)]
	if rng.randi() % 2 == 1:
		current_choices.reverse()
	return current


func _pick_from_stage(stage: String) -> Dictionary:
	var pool: Array[Dictionary] = []
	for item in items:
		if item.stage == stage and item.id != _last_item_id:
			pool.append(item)
	if pool.is_empty():
		for item in items:
			if item.id != _last_item_id:
				pool.append(item)
	if pool.is_empty():
		pool = items
	return pool[rng.randi() % pool.size()]


## The first animal not yet in the pen, but not the one that just walked away
## (it "comes back later"). When all are collected, any animal can appear again.
func _pick_animal() -> Dictionary:
	if animals.is_empty():
		return {"id": "animal", "name": "Hayop", "color": "#c08552"}
	var waiting: Array = []
	for a in animals:
		if not progress.has_animal(biome, a.id):
			waiting.append(a)
	if waiting.is_empty():
		return animals[rng.randi() % animals.size()]
	for a in waiting:
		if a.id != _left_animal_id:
			return a
	return waiting[0]


## Reports one throw. Returns what the scene needs to show:
## { correct, stage, hint_level (0, 1 or 2), coins, animal_id, new_animal, cleared }
func answer(chosen: String) -> Dictionary:
	var item := current
	var correct: bool = DRRule.clean_word(chosen) == item.answer
	var stage: String = item.stage
	progress.record(biome, stage, correct)
	for entry in requeue:
		entry.due -= 1

	var result := {
		"correct": correct, "stage": stage, "hint_level": 0, "coins": 0,
		"animal_id": current_animal.get("id", ""), "new_animal": false, "cleared": false,
	}
	if correct:
		progress.coins += GameConfig.COINS_PER_CORRECT
		result.coins = GameConfig.COINS_PER_CORRECT
		result.new_animal = progress.collect(biome, current_animal.get("id", ""))
		_left_animal_id = ""
	else:
		misses[item.id] = int(misses.get(item.id, 0)) + 1
		result.hint_level = 1 if misses[item.id] == 1 else 2
		requeue.append({"item": item, "due": GameConfig.REQUEUE_GAP})
		_left_animal_id = current_animal.get("id", "")

	if not mixed:
		answered_in_stage += 1
		if answered_in_stage >= GameConfig.STAGE_LENGTH:
			answered_in_stage = 0
			stage_index += 1
			if stage_index >= stages.size():
				stage_index = stages.size() - 1
				mixed = true

	result.cleared = progress.biome_cleared(biome, stages, animals.size())
	return result
