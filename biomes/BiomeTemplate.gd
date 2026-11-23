class_name BiomeTemplate
extends Node2D
## Owner: Lead (template). Loraine builds each biome scene on top of it.
##
## Contract (keep these names so everyone can work in parallel):
##   1. Ask QuestionBank.get_items(biome) for items.
##   2. Show item.sentence with the blank ___ and two foods: d-form and r-form.
##   3. On ThrowController.answer_thrown -> check_answer(chosen).
##   4. Show feedback (Alex's FeedbackPopup), log with SaveManager, add score in GameState.
##
## Feedback wording rule: say "the preferred form here is ...", never "wrong Filipino".

signal round_finished(correct_count: int, total: int)

@export var biome: String = "forest"

var items: Array[Dictionary] = []
var index: int = 0
var correct_count: int = 0


func _ready() -> void:
	items = QuestionBank.get_items(biome)
	items.shuffle()


func current_item() -> Dictionary:
	return items[index] if index < items.size() else {}


## The two choices to put on the foods, e.g. ["din", "rin"].
func current_choices() -> Array[String]:
	var choices: Array[String] = []
	var item := current_item()
	if not item.is_empty():
		var d := DRRule.d_form(item.answer)
		choices.append(d)
		choices.append(DRRule.r_form(d))
	return choices


func check_answer(chosen: String) -> bool:
	var item := current_item()
	if item.is_empty():
		return false
	var ok := DRRule.is_preferred(item.prev_word, chosen)
	SaveManager.log_answer(item.id, chosen, ok)
	if ok:
		correct_count += 1
		GameState.add_score(10)
	index += 1
	if index >= items.size():
		round_finished.emit(correct_count, items.size())
	return ok
