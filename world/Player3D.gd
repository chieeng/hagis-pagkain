class_name Player3D
extends CharacterBody3D
## The learner's blocky character. Moves on flat ground; trees block it.
## Owner: Lead (gameplay). Look: Alex.

const SPEED := 6.0

var facing := Vector3(0, 0, -1)
var _model: Node3D
var _walk_time := 0.0
var _legs: Array[MeshInstance3D] = []


func _ready() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	shape.shape = capsule
	shape.position = Vector3(0, 0.9, 0)
	add_child(shape)

	_model = Node3D.new()
	add_child(_model)
	_legs.append(Blocky.box(_model, Vector3(0.28, 0.7, 0.3), Color("#364fc7"), Vector3(-0.17, 0.35, 0)))
	_legs.append(Blocky.box(_model, Vector3(0.28, 0.7, 0.3), Color("#364fc7"), Vector3(0.17, 0.35, 0)))
	Blocky.box(_model, Vector3(0.75, 0.75, 0.4), Color("#e03131"), Vector3(0, 1.08, 0))
	Blocky.box(_model, Vector3(0.22, 0.7, 0.25), Color("#f1c27d"), Vector3(-0.5, 1.08, 0))
	Blocky.box(_model, Vector3(0.22, 0.7, 0.25), Color("#f1c27d"), Vector3(0.5, 1.08, 0))
	Blocky.box(_model, Vector3(0.55, 0.55, 0.55), Color("#f1c27d"), Vector3(0, 1.75, 0))
	Blocky.box(_model, Vector3(0.6, 0.18, 0.6), Color("#3b2314"), Vector3(0, 2.06, 0))
	Blocky.box(_model, Vector3(0.08, 0.1, 0.05), Color("#1b1b1b"), Vector3(-0.12, 1.8, 0.28))
	Blocky.box(_model, Vector3(0.08, 0.1, 0.05), Color("#1b1b1b"), Vector3(0.12, 1.8, 0.28))


## `dir` is on the ground plane (x, z), length 0..1.
func move(dir: Vector3, delta: float) -> void:
	velocity = dir * SPEED
	velocity.y = 0.0
	move_and_slide()
	position.y = 0.0
	if dir.length() > 0.1:
		facing = dir.normalized()
		_model.rotation.y = lerp_angle(_model.rotation.y, atan2(facing.x, facing.z), min(1.0, delta * 12.0))
		_walk_time += delta * 10.0
		_legs[0].rotation.x = sin(_walk_time) * 0.6
		_legs[1].rotation.x = -sin(_walk_time) * 0.6
	else:
		_legs[0].rotation.x = 0.0
		_legs[1].rotation.x = 0.0


func hand_position() -> Vector3:
	return global_position + Vector3(0, 1.4, 0) + facing * 0.5
