class_name BiomeSession
extends RefCounted
## The game logic of one biome visit, with no visuals, so it can be unit-tested.
## world/BiomeWorld.gd (the 3D scene) asks this for sentences and reports each throw and delivery.
##
## Flow [proposal, Part 3]:
##   - Stages in order: vowel -> consonant -> w/y (-> exception in Sky). Then mixed practice that
##     favours the weakest stage ("extra animals keep appearing in the weaker stage").
##   - One throw per sentence. Correct: the animal joins the pen and the learner earns coins.
##     Wrong: the animal leaves, a hint shows, and the sentence comes back later (spaced review).
##   - A second miss on the same sentence shows a worked example.
##   - About 30% of sentences come from earlier biomes (spiral review) [proposal].
##   - From the River biome on, three foods are offered; Island is back to the pair's two [proposal].
##   - Sky's exception stage opens only after 80% on the three regular stages [proposal, GO4].
##   - Island plays mixed from the start: every pair, every context, no new rule [proposal].

var biome: String
var items: Array[Dictionary] = []
## Items from earlier biomes, mixed in at GameConfig.REVIEW_SHARE [proposal].
var review_items: Array[Dictionary] = []
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

## Correct first throws in a row (resets on a miss). Drives the combo and rare/golden animals.
var streak := 0

var _last_item_id := ""
var _left_animal_id := ""
var rng := RandomNumberGenerator.new()


func _init(p_biome: String, p_items: Array[Dictionary], p_animals: Array, p_progress: Progress, seed: int = -1, p_review: Array[Dictionary] = []) -> void:
	biome = p_biome
	items = p_items
	review_items = p_review
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
	# Island teaches no new rule: mixed review of everything from the first sentence [proposal].
	mixed = biome == "island"


## Sky only: the exception stage hides until the three regular stages are at 80% [proposal, GO4].
func stage_open(s: String) -> bool:
	if s != GameConfig.GATED_STAGE or biome != GameConfig.GATE_BIOME:
		return true
	for reg in stages:
		if reg != GameConfig.GATED_STAGE and not progress.stage_met(biome, reg):
			return false
	return true


func open_stages() -> Array[String]:
	var out: Array[String] = []
	for s in stages:
		if stage_open(s):
			out.append(s)
	return out


## The stages the next-biome unlock checks: the proposal's accuracy check names the
## vowel, consonant and w/y stages (the Sky exception stage is a research target, not a gate).
func unlock_stages() -> Array[String]:
	var out: Array[String] = []
	for s in stages:
		if s != GameConfig.GATED_STAGE:
			out.append(s)
	return out


func current_stage() -> String:
	if stages.is_empty():
		return ""
	if mixed:
		return progress.weakest_stage(biome, open_stages())
	return stages[stage_index]


## Picks the next sentence and the animal that will wear its word tag. Returns {} if there are no items.
## `busy_animal_ids` / `busy_item_ids`: animals and sentences already out in the world.
func next_sentence(busy_animal_ids: Array = [], busy_item_ids: Array = []) -> Dictionary:
	if items.is_empty():
		return {}
	current = {}
	for i in requeue.size():
		if requeue[i].due <= 0 and not requeue[i].item.id in busy_item_ids:
			current = requeue[i].item
			requeue.remove_at(i)
			break
	# Spiral review [proposal]: about 30% of sentences come from earlier biomes.
	if current.is_empty() and not review_items.is_empty() and rng.randf() < GameConfig.REVIEW_SHARE:
		current = _pick_review(current_stage(), busy_item_ids)
	if current.is_empty():
		current = _pick_from_stage(current_stage(), busy_item_ids)
	_last_item_id = current.id
	current_animal = _pick_animal(busy_animal_ids)
	current_choices = _choices_for(current)
	return current


## The fruit words offered for this sentence: the pair's two forms, plus one form of another
## pair from the River biome on, so the learner also picks the right word [proposal, GO2].
func _choices_for(item: Dictionary) -> Array[String]:
	var d := DRRule.d_form(item.answer)
	var out: Array[String] = [d, DRRule.r_form(d)]
	if biome in GameConfig.THREE_CHOICE_BIOMES:
		var others: Array[String] = []
		for other_d in DRRule.PAIRS:
			if other_d != d:
				others.append(other_d)
				others.append(DRRule.PAIRS[other_d])
		out.append(others[rng.randi() % others.size()])
	for i in range(out.size() - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var tmp := out[i]
		out[i] = out[j]
		out[j] = tmp
	return out


## A review sentence from an earlier biome, preferring the stage being practised.
func _pick_review(stage: String, busy_item_ids: Array) -> Dictionary:
	var pool: Array[Dictionary] = []
	for item in review_items:
		if item.stage == stage and item.id != _last_item_id and not item.id in busy_item_ids and stage_open(str(item.stage)):
			pool.append(item)
	if pool.is_empty():
		for item in review_items:
			if item.id != _last_item_id and not item.id in busy_item_ids and stage_open(str(item.stage)):
				pool.append(item)
	return {} if pool.is_empty() else pool[rng.randi() % pool.size()]


func _pick_from_stage(stage: String, busy_item_ids: Array = []) -> Dictionary:
	var pool: Array[Dictionary] = []
	for item in items:
		if item.stage == stage and item.id != _last_item_id and not item.id in busy_item_ids:
			pool.append(item)
	if pool.is_empty():
		# Stay in the stage being learned: two animals may share a sentence before another stage is borrowed.
		for item in items:
			if item.stage == stage:
				pool.append(item)
	if pool.is_empty():
		for item in items:
			if item.id != _last_item_id and not item.id in busy_item_ids:
				pool.append(item)
	if pool.is_empty():
		pool = items
	return pool[rng.randi() % pool.size()]


## The first animal not yet in the pen and not already out in the world, avoiding the one
## that just walked away (it "comes back later"). When all are collected, any free animal appears again.
func _pick_animal(busy_animal_ids: Array = []) -> Dictionary:
	if animals.is_empty():
		return {"id": "animal", "name": "Hayop", "color": "#c08552"}
	var waiting: Array = []
	var free: Array = []
	for a in animals:
		if a.id in busy_animal_ids:
			continue
		free.append(a)
		if not progress.has_animal(biome, a.id):
			waiting.append(a)
	for a in waiting:
		if a.id != _left_animal_id:
			return a
	if not waiting.is_empty():
		return waiting[0]
	if not free.is_empty():
		return free[rng.randi() % free.size()]
	return animals[rng.randi() % animals.size()]


## Reports one throw that reached an animal. `item`/`animal` default to the last ones picked.
## `rarity` is the animal's: "common", "rare" or "golden".
## Returns { correct, stage, hint_level (0, 1 or 2), animal_id, coins, streak, multiplier }.
## Coins are paid now [proposal: a correct first throw earns coins]. The animal joins the
## Animal Index only when it reaches the pen (deliver()).
func answer(chosen: String, item: Dictionary = {}, animal: Dictionary = {}, rarity: String = "common") -> Dictionary:
	if item.is_empty():
		item = current
	if animal.is_empty():
		animal = current_animal
	var correct: bool = DRRule.clean_word(chosen) == item.answer
	var stage: String = item.stage
	progress.record(biome, stage, correct)
	progress.record_pair(str(item.get("pair", "")), stage, str(item.get("id", "")), correct)
	var help := progress.update_help(biome, stage, correct)
	for entry in requeue:
		entry.due -= 1

	var result := {"correct": correct, "stage": stage, "hint_level": 0, "animal_id": animal.get("id", ""),
		"coins": 0, "streak": 0, "multiplier": 1, "help": help}
	if correct:
		streak += 1
		_left_animal_id = ""
		result.multiplier = multiplier()
		result.coins = int(GameConfig.RARITY_COINS.get(rarity, GameConfig.COINS_PER_CORRECT)) * int(result.multiplier)
		progress.coins += int(result.coins)
	else:
		streak = 0
		misses[item.id] = int(misses.get(item.id, 0)) + 1
		result.hint_level = 1 if misses[item.id] == 1 else 2
		requeue.append({"item": item, "due": GameConfig.REQUEUE_GAP})
		_left_animal_id = animal.get("id", "")
	result.streak = streak

	if not mixed:
		answered_in_stage += 1
		if answered_in_stage >= GameConfig.STAGE_LENGTH:
			answered_in_stage = 0
			stage_index += 1
			# Skip stages that are not open yet (Sky's exception stage) [proposal, GO4].
			while stage_index < stages.size() and not stage_open(stages[stage_index]):
				stage_index += 1
			if stage_index >= stages.size():
				stage_index = stages.size() - 1
				mixed = true
	return result


## Coin multiplier from the current streak: x1, then +1 for every COMBO_STEP in a row.
func multiplier() -> int:
	return min(GameConfig.COMBO_MAX_MULT, 1 + streak / GameConfig.COMBO_STEP)


## Rarity for a newly appearing animal, from the current streak.
func next_rarity() -> String:
	if streak >= GameConfig.GOLDEN_STREAK:
		return "golden"
	if streak >= GameConfig.RARE_STREAK:
		return "rare"
	return "common"


## A fed animal reached the pen: add it (and its rarity) to the Animal Index.
## Returns { new_animal, new_variant, cleared }.
func deliver(animal_id: String, rarity: String = "common") -> Dictionary:
	var is_new := progress.collect(biome, animal_id)
	var new_variant := progress.add_variant(biome, animal_id, rarity)
	return {
		"new_animal": is_new,
		"new_variant": new_variant,
		"cleared": progress.biome_cleared(biome, unlock_stages(), animals.size()),
	}
