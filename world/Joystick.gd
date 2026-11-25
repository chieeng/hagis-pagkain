class_name Joystick
extends Control
## On-screen joystick for phones (bottom-left). `value` is -1..1 on each axis; y is down.
## On a PC the arrow keys / WASD work too (handled in BiomeWorld).

const RADIUS := 90.0
const KNOB := 42.0

var value := Vector2.ZERO
var _touch_index := -1
var _knob := Vector2.ZERO


func _ready() -> void:
	custom_minimum_size = Vector2(RADIUS * 2, RADIUS * 2)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			_touch_index = event.index
			_update(event.position)
		elif not event.pressed and event.index == _touch_index:
			_touch_index = -1
			_knob = Vector2.ZERO
			value = Vector2.ZERO
			queue_redraw()
		accept_event()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_update(event.position)
		accept_event()


func _update(local: Vector2) -> void:
	_knob = (local - size / 2.0).limit_length(RADIUS)
	value = _knob / RADIUS
	queue_redraw()


func _draw() -> void:
	var c := size / 2.0
	draw_circle(c, RADIUS, Color(1, 1, 1, 0.25))
	draw_arc(c, RADIUS, 0, TAU, 40, Color(1, 1, 1, 0.7), 4.0)
	draw_circle(c + _knob, KNOB, Color(1, 1, 1, 0.8))
