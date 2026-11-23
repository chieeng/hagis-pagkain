class_name ThrowController
extends Node2D
## Owner: Lead (gameplay).
## Shows the food choices. The learner drags a food and lets go to throw it to the animal.
## Aim assist: any drag longer than MIN_DRAG counts as a throw at the animal, so the
## challenge is choosing the right word, not aiming. Throw power can change this later.

signal answer_thrown(answer: String)

const MIN_DRAG := 30.0
const FOOD_COLORS := [Color("#f08c00"), Color("#e64980"), Color("#7950f2")]

var target := Vector2(930, 430)
var foods: Array[FoodItem] = []
var enabled := false
var _dragging: FoodItem = null


func set_choices(choices: Array[String]) -> void:
	for f in foods:
		f.queue_free()
	foods.clear()
	for i in choices.size():
		var f := FoodItem.new()
		add_child(f)
		f.setup(choices[i], Vector2(170 + i * 170, 625), FOOD_COLORS[i % FOOD_COLORS.size()])
		foods.append(f)


func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			for f in foods:
				if f.contains(event.position):
					_dragging = f
					break
		elif _dragging != null:
			var f := _dragging
			_dragging = null
			if f.position.distance_to(f.home) >= MIN_DRAG:
				throw_food(f)
			else:
				_snap_back(f)
	elif event is InputEventScreenDrag and _dragging != null:
		_dragging.position = to_local(event.position)


## Throws the food whose label is `answer` (used by autoplay and tests).
func throw_answer(answer: String) -> void:
	for f in foods:
		if f.answer == answer:
			throw_food(f)
			return


func throw_food(food: FoodItem) -> void:
	enabled = false
	for f in foods:
		if f != food:
			f.visible = false
	var start := food.position
	var end := to_local(target)
	var control := (start + end) / 2.0 + Vector2(0, -260)
	var t := create_tween()
	t.tween_method(func(k: float) -> void:
		food.position = start.lerp(control, k).lerp(control.lerp(end, k), k)
		food.rotation = k * TAU
	, 0.0, 1.0, 0.55)
	await t.finished
	food.visible = false
	answer_thrown.emit(food.answer)


func _snap_back(f: FoodItem) -> void:
	create_tween().tween_property(f, "position", f.home, 0.15)
