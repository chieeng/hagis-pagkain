class_name SpeedLines
extends Control
## Comic-style speed lines that burst in from the screen edges while the fruit flies.

var strength := 0.0   ## 0 = hidden, 1 = full
var _seed := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2.ZERO
	size = get_viewport_rect().size   # parent is a CanvasLayer, so anchors alone give size 0


func burst(seconds: float) -> void:
	strength = 1.0
	var t := create_tween()
	t.tween_method(func(v: float) -> void:
		strength = v
		queue_redraw(), 1.0, 0.0, seconds).set_ease(Tween.EASE_IN)


func _process(_delta: float) -> void:
	if strength > 0.01:
		_seed += 1
		queue_redraw()


func _draw() -> void:
	if strength <= 0.01:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed / 3
	var c := size / 2.0
	var radius := size.length() * 0.6
	for i in 60:
		var a := rng.randf() * TAU
		var dir := Vector2.from_angle(a)
		var inner := radius * rng.randf_range(0.4, 0.65)
		var w := rng.randf_range(6.0, 16.0)
		var p1 := c + dir * radius
		var p2 := c + dir * inner
		var side := dir.orthogonal() * w
		draw_colored_polygon(PackedVector2Array([p1 + side, p1 - side, p2]), Color(1, 1, 1, 0.85 * strength))
