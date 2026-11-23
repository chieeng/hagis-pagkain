class_name FoodItem
extends Node2D
## Owner: Lead (gameplay). One throwable food carrying one answer option ("din" or "rin").
## Placeholder drawing (a fruit) until real art exists.

var answer := "din"
var home := Vector2.ZERO
var radius := 50.0
var color := Color("#f08c00")
var label: Label


func setup(text: String, pos: Vector2, food_color: Color = Color("#f08c00")) -> void:
	answer = text
	home = pos
	position = pos
	color = food_color
	if label == null:
		label = UiKit.label("", 36, Color.WHITE, 10)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		add_child(label)
	label.text = text
	label.size = Vector2(radius * 2.4, radius)
	label.position = Vector2(-radius * 1.2, -radius * 0.5)
	queue_redraw()


func contains(global_point: Vector2) -> bool:
	return to_local(global_point).length() <= radius * 1.3


func _draw() -> void:
	draw_circle(Vector2(4, 6), radius, Color(0, 0, 0, 0.18))
	draw_circle(Vector2.ZERO, radius, color)
	draw_circle(Vector2(-radius * 0.35, -radius * 0.35), radius * 0.25, color.lightened(0.35))
	draw_line(Vector2(0, -radius), Vector2(6, -radius - 16), Color("#5c3d1e"), 5.0)
	draw_circle(Vector2(18, -radius - 10), 11, Color("#2b8a3e"))
