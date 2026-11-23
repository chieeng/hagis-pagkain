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
## biome -> true once the learner has finished that biome's lesson (Aralin)
var lessons_done: Dictionary = {}


func record(biome: String, stage: String, correct: bool) -> void:
	if not history.has(biome):
		history[biome] = {}
	var per_stage: Dictionary = history[biome]
	if not per_stage.has(stage):
		per_stage[stage] = []
	var window: Array = per_stage[stage]
	window.append(correct)
	while window.size() > GameConfig.ACCURACY_WINDOW:
		window.pop_front()


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
	return {"coins": coins, "collected": collected, "history": history, "unlocked": unlocked, "lessons_done": lessons_done}


func from_dict(data: Dictionary) -> void:
	coins = int(data.get("coins", 0))
	collected = data.get("collected", {})
	history = data.get("history", {})
	unlocked = data.get("unlocked", {"forest": true})
	lessons_done = data.get("lessons_done", {})
