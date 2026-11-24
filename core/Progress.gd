class_name Progress
extends RefCounted
## Everything the learner has earned, plus the per-stage accuracy windows used for unlocking.
## Plain data so it can be saved as JSON and unit-tested. GameState holds the live copy.

var coins: int = 0
## biome -> Array of animal ids in the pen
var collected: Dictionary = {}
## biome -> { stage -> Array[bool] of the last ACCURACY_WINDOW first throws }
var history: Dictionary = {}
## biome -> true
var unlocked: Dictionary = {"forest": true}
## biome -> { stage -> 0..1 } how strongly the deciding letter glows (1 = full help, 0 = none).
## A stage missing here has not been met yet (used for the "new kind of animal" moment).
var help: Dictionary = {}
## biome -> { animal id -> Array of rarities found ("common", "rare", "golden") }
var variants: Dictionary = {}
## Fruit shop: owned tier ids and the one in use.
var owned_fruits: Array = ["bayabas"]
var equipped_fruit: String = "bayabas"
## My Progress data [proposal]: accuracy per pair and per context, all biomes together.
## pair -> { stage -> { "right": int, "total": int } }
var pair_stats: Dictionary = {}
## Item ids of recently missed sentences, newest first (the "sentences to review next").
var missed_items: Array = []
## biome -> total sentences answered there (the biome-select screen shows this) [proposal].
var answered: Dictionary = {}


func record(biome: String, stage: String, correct: bool) -> void:
	answered[biome] = int(answered.get(biome, 0)) + 1
	if not history.has(biome):
		history[biome] = {}
	var per_stage: Dictionary = history[biome]
	if not per_stage.has(stage):
		per_stage[stage] = []
	var window: Array = per_stage[stage]
	window.append(correct)
	while window.size() > GameConfig.ACCURACY_WINDOW:
		window.pop_front()


## My Progress [proposal]: lifetime counts per pair and context, plus the missed-sentence list.
func record_pair(pair: String, stage: String, item_id: String, correct: bool) -> void:
	if not pair_stats.has(pair):
		pair_stats[pair] = {}
	var per_stage: Dictionary = pair_stats[pair]
	if not per_stage.has(stage):
		per_stage[stage] = {"right": 0, "total": 0}
	per_stage[stage].total += 1
	if correct:
		per_stage[stage].right += 1
		missed_items.erase(item_id)   # answered right later: no longer "to review next"
	elif item_id != "":
		missed_items.erase(item_id)
		missed_items.push_front(item_id)
		while missed_items.size() > GameConfig.REVIEW_LIST_MAX:
			missed_items.pop_back()


## Accuracy 0..1 for one pair in one stage, or -1.0 when nothing was answered yet.
func pair_accuracy(pair: String, stage: String) -> float:
	var s: Dictionary = pair_stats.get(pair, {}).get(stage, {})
	var total := int(s.get("total", 0))
	return -1.0 if total == 0 else float(s.get("right", 0)) / total


## Glow level for a stage: starts at 1, fades with correct first throws, comes back after a miss.
func help_level(biome: String, stage: String) -> float:
	return float(help.get(biome, {}).get(stage, 1.0))


func has_met_stage(biome: String, stage: String) -> bool:
	return help.get(biome, {}).has(stage)


func update_help(biome: String, stage: String, correct: bool) -> float:
	if not help.has(biome):
		help[biome] = {}
	var level := help_level(biome, stage)
	level = maxf(0.0, level - GameConfig.HELP_FADE_STEP) if correct else GameConfig.HELP_ON_MISS
	help[biome][stage] = level
	return level


## Marks a stage as met (glow stays at its current level).
func meet_stage(biome: String, stage: String) -> void:
	if not help.has(biome):
		help[biome] = {}
	if not help[biome].has(stage):
		help[biome][stage] = 1.0


func stage_window(biome: String, stage: String) -> Array:
	return history.get(biome, {}).get(stage, [])


func stage_accuracy(biome: String, stage: String) -> float:
	var window := stage_window(biome, stage)
	if window.is_empty():
		return 0.0
	var right := 0
	for c in window:
		if c:
			right += 1
	return float(right) / window.size()


## The proposal's accuracy check: at least 80% over the last 15 sentences of this stage.
func stage_met(biome: String, stage: String) -> bool:
	return stage_window(biome, stage).size() >= GameConfig.ACCURACY_WINDOW \
		and stage_accuracy(biome, stage) >= GameConfig.ACCURACY_TARGET


## Returns true if the animal is new to the pen.
func collect(biome: String, animal_id: String) -> bool:
	if not collected.has(biome):
		collected[biome] = []
	var pen: Array = collected[biome]
	if animal_id in pen:
		return false
	pen.append(animal_id)
	return true


## Returns true if this rarity of this animal is new.
func add_variant(biome: String, animal_id: String, rarity: String) -> bool:
	if not variants.has(biome):
		variants[biome] = {}
	var per_animal: Dictionary = variants[biome]
	if not per_animal.has(animal_id):
		per_animal[animal_id] = []
	var found: Array = per_animal[animal_id]
	if rarity in found:
		return false
	found.append(rarity)
	return true


func has_variant(biome: String, animal_id: String, rarity: String) -> bool:
	return rarity in variants.get(biome, {}).get(animal_id, [])


static func fruit_tier(tier_id: String) -> Dictionary:
	for t in GameConfig.FRUIT_TIERS:
		if t.id == tier_id:
			return t
	return GameConfig.FRUIT_TIERS[0]


func equipped_tier() -> Dictionary:
	return fruit_tier(equipped_fruit)


## Buys (if needed) and equips a fruit tier. Returns false if there are not enough coins.
func buy_fruit(tier_id: String) -> bool:
	if tier_id in owned_fruits:
		equipped_fruit = tier_id
		return true
	var t := fruit_tier(tier_id)
	if t.id != tier_id or coins < int(t.price):
		return false
	coins -= int(t.price)
	owned_fruits.append(tier_id)
	equipped_fruit = tier_id
	return true


func has_animal(biome: String, animal_id: String) -> bool:
	return animal_id in collected.get(biome, [])


func collected_count(biome: String) -> int:
	return collected.get(biome, []).size()


func index_complete(biome: String, total_animals: int) -> bool:
	return total_animals > 0 and collected_count(biome) >= total_animals


## Unlock rule [proposal]: Animal Index complete AND the accuracy check met in every stage.
func biome_cleared(biome: String, stages: Array, total_animals: int) -> bool:
	if not index_complete(biome, total_animals):
		return false
	for s in stages:
		if not stage_met(biome, s):
			return false
	return true


## The stage that most needs practice: not yet met, lowest accuracy, fewest answers.
func weakest_stage(biome: String, stages: Array) -> String:
	var best := ""
	var best_score := INF
	for s in stages:
		if stage_met(biome, s):
			continue
		var score := stage_accuracy(biome, s) + float(stage_window(biome, s).size()) / GameConfig.ACCURACY_WINDOW
		if score < best_score:
			best_score = score
			best = s
	if best == "" and not stages.is_empty():
		best = stages[randi() % stages.size()]
	return best


func to_dict() -> Dictionary:
	return {"coins": coins, "collected": collected, "history": history, "unlocked": unlocked, "help": help,
		"variants": variants, "owned_fruits": owned_fruits, "equipped_fruit": equipped_fruit,
		"pair_stats": pair_stats, "missed_items": missed_items, "answered": answered}


func from_dict(data: Dictionary) -> void:
	coins = int(data.get("coins", 0))
	collected = data.get("collected", {})
	history = data.get("history", {})
	unlocked = data.get("unlocked", {"forest": true})
	help = data.get("help", {})
	variants = data.get("variants", {})
	owned_fruits = data.get("owned_fruits", ["bayabas"])
	equipped_fruit = str(data.get("equipped_fruit", "bayabas"))
	pair_stats = data.get("pair_stats", {})
	missed_items = data.get("missed_items", [])
	answered = data.get("answered", {})
