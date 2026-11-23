class_name AnimalSprite
extends Node2D
## Placeholder animal drawn with shapes until real art exists (owner: Alex).
## Replace _draw() with a Sprite2D/AnimatedSprite2D later; keep setup() the same.

var body_color := Color("#c08552")
var radius := 60.0
## Grey shape with no face: used for animals not yet found in the Animal Index.
var silhouette := false
var name_label: Label


func setup(data: Dictionary, r: float = 60.0, show_name: bool = true) -> void:
	body_color = Color(data.get("color", "#c08552"))
	radius = r
	if name_label == null:
		name_label = UiKit.label("", int(max(18.0, r * 0.4)), Color.WHITE, 8)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(name_label)
	name_label.text = Strings.UNKNOWN if silhouette else str(data.get("name", ""))
	name_label.size = Vector2(radius * 4, radius * 0.6)
	name_label.position = Vector2(-radius * 2, radius * 1.02)
	name_label.visible = show_name
	queue_redraw()


func _draw() -> void:
	var c := Color("#868e96") if silhouette else body_color
	draw_circle(Vector2(-radius * 0.55, -radius * 0.85), radius * 0.32, c.darkened(0.15))
	draw_circle(Vector2(radius * 0.55, -radius * 0.85), radius * 0.32, c.darkened(0.15))
	draw_circle(Vector2.ZERO, radius, c)
	draw_circle(Vector2(0, radius * 0.35), radius * 0.55, c.lightened(0.35))
	if silhouette:
		return
	for x in [-0.35, 0.35]:
		draw_circle(Vector2(radius * x, -radius * 0.2), radius * 0.17, Color.WHITE)
		draw_circle(Vector2(radius * x, -radius * 0.17), radius * 0.09, Color("#1b1b1b"))
	draw_arc(Vector2(0, radius * 0.05), radius * 0.22, 0.3, PI - 0.3, 12, Color("#3b2314"), 3.0)
