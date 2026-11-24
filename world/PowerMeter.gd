class_name PowerMeter
extends Control
## Vertical throw-power bar shown next to the Ihagis button.
## While the button is held the value goes up and down; letting go throws with that power.
## The green band shows the power that reaches the animal being aimed at (kid-friendly aiming).

var value := 0.0          ## 0..1
var band_min := -1.0      ## green band, 0..1 (negative = no target)
var band_max := -1.0
var active := false       ## true while charging


func _ready() -> void:
	custom_minimum_size = Vector2(54, 330)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_band(lo: float, hi: float) -> void:
	band_min = lo
	band_max = hi
	queue_redraw()


func set_value(v: float) -> void:
	value = clamp(v, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, Color("#1c1c3a", 0.85))   # dark, so the band stands out on green grass
	if band_min >= 0.0:
		var lo: float = clamp(band_min, 0.0, 1.0)
		var hi: float = clamp(band_max, 0.0, 1.0)
		if hi > lo:
			var band := Rect2(0, size.y * (1.0 - hi), size.x, size.y * (hi - lo))
			draw_rect(band, Color("#8ce99a"))
			draw_rect(band, Color("#ffd43b"), false, 4.0)   # yellow outline
			# arrows pointing at the band from both sides
			var mid := band.get_center().y
			draw_colored_polygon(PackedVector2Array([Vector2(-16, mid - 10), Vector2(-16, mid + 10), Vector2(-3, mid)]), Color("#ffd43b"))
			draw_colored_polygon(PackedVector2Array([Vector2(size.x + 16, mid - 10), Vector2(size.x + 16, mid + 10), Vector2(size.x + 3, mid)]), Color("#ffd43b"))
	if active:
		var h := size.y * value
		var c := Color("#ffd43b").lerp(Color("#ff6b6b"), value)
		draw_rect(Rect2(6, size.y - h, size.x - 12, h), c)
		draw_rect(Rect2(0, size.y - h - 3, size.x, 6), Color.WHITE)
	draw_rect(r, Color.WHITE, false, 3.0)
