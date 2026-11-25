class_name Fx
extends RefCounted
## Visual "juice": the effects that make a throw feel exciting (confetti, light beams, shockwaves,
## floating text, sparkles). All built from simple shapes so they run on low-end phones.
## Owner: Alex. Tune colours/sizes here; gameplay code only calls these functions.

## Glowing, see-through material for beams and rings.
static func glow_material(color: Color, alpha: float = 0.6) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = Color(color.r, color.g, color.b, alpha)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


## One burst of colourful cube confetti.
static func confetti(parent: Node, pos: Vector3, amount: int = 60, colors: Array = []) -> void:
	if colors.is_empty():
		colors = [Color("#ff6b6b"), Color("#ffd43b"), Color("#51cf66"), Color("#339af0"), Color("#cc5de8"), Color("#ffffff")]
	var p := CPUParticles3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.18, 0.18, 0.05)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mesh.material = mat
	p.mesh = mesh
	p.amount = amount
	p.one_shot = true
	p.explosiveness = 1.0
	p.lifetime = 1.6
	p.direction = Vector3.UP
	p.spread = 70.0
	p.initial_velocity_min = 6.0
	p.initial_velocity_max = 11.0
	p.gravity = Vector3(0, -12, 0)
	p.angular_velocity_min = -720.0
	p.angular_velocity_max = 720.0
	p.damping_min = 1.0
	p.damping_max = 2.0
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array()
	grad.colors = PackedColorArray()
	for i in colors.size():
		grad.add_point(float(i) / max(1, colors.size() - 1), colors[i])
	p.color_initial_ramp = grad
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	_free_later(p, 2.0)


## Expanding ring on the ground.
static func shockwave(parent: Node, pos: Vector3, color: Color, size: float = 6.0) -> void:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.85
	torus.outer_radius = 1.0
	torus.rings = 24
	torus.ring_segments = 6
	ring.mesh = torus
	var mat := glow_material(color, 0.9)
	ring.material_override = mat
	parent.add_child(ring)
	ring.global_position = pos + Vector3(0, 0.15, 0)
	ring.scale = Vector3.ONE * 0.3
	var t := ring.create_tween().set_parallel()
	t.tween_property(ring, "scale", Vector3(size, 1.0, size), 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(mat, "albedo_color:a", 0.0, 0.6)
	_free_later(ring, 0.7)


## A pillar of light shooting up from the animal (the big "reveal" moment).
static func beam(parent: Node, pos: Vector3, color: Color, height: float = 14.0, seconds: float = 1.4) -> void:
	var b := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.8
	cyl.bottom_radius = 0.9
	cyl.height = height
	cyl.radial_segments = 16
	b.mesh = cyl
	var mat := glow_material(color, 0.55)
	b.material_override = mat
	parent.add_child(b)
	b.global_position = pos + Vector3(0, height / 2.0, 0)
	b.scale = Vector3(0.1, 1.0, 0.1)
	var t := b.create_tween()
	t.tween_property(b, "scale", Vector3(1.0, 1.0, 1.0), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(seconds * 0.5)
	t.tween_property(mat, "albedo_color:a", 0.0, seconds * 0.5)
	_free_later(b, seconds + 0.3)


## Text that pops up in the world, rises and fades ("+10", "PERPEKTO!", "?").
static func float_text(parent: Node, pos: Vector3, text: String, color: Color = Color.WHITE, size: int = 90, rise: float = 2.5, seconds: float = 1.2) -> Label3D:
	var l := Blocky.label3d(parent, text, Vector3.ZERO, size, color)
	l.global_position = pos
	l.scale = Vector3.ONE * 0.3
	var t := l.create_tween()
	t.tween_property(l, "scale", Vector3.ONE * 1.15, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(l, "scale", Vector3.ONE, 0.1)
	t.parallel().tween_property(l, "global_position:y", pos.y + rise, seconds)
	t.tween_property(l, "modulate:a", 0.0, 0.25)
	t.parallel().tween_property(l, "outline_modulate:a", 0.0, 0.25)
	_free_later(l, seconds + 0.6)
	return l


## Endless sparkles around a rare/golden animal, so kids spot it from far away.
static func sparkles(parent: Node3D, color: Color) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.12, 0.12, 0.12)
	mesh.material = glow_material(color, 1.0)
	p.mesh = mesh
	p.amount = 18
	p.lifetime = 1.2
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 1.2
	p.direction = Vector3.UP
	p.spread = 25.0
	p.initial_velocity_min = 0.8
	p.initial_velocity_max = 1.8
	p.gravity = Vector3.ZERO
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.4
	parent.add_child(p)
	p.position = Vector3(0, 1.2, 0)
	return p


## A tall faint light column above a rare/golden animal: visible across the whole map.
static func pillar(parent: Node3D, color: Color) -> MeshInstance3D:
	var b := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.5
	cyl.bottom_radius = 0.5
	cyl.height = 30.0
	cyl.radial_segments = 10
	b.mesh = cyl
	b.material_override = glow_material(color, 0.22)
	parent.add_child(b)
	b.position = Vector3(0, 15.0, 0)
	var t := b.create_tween().set_loops()
	t.tween_property(b, "scale", Vector3(1.4, 1.0, 1.4), 0.6).set_trans(Tween.TRANS_SINE)
	t.tween_property(b, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_SINE)
	return b


static func _free_later(node: Node, seconds: float) -> void:
	if not node.is_inside_tree():
		return
	node.get_tree().create_timer(seconds, true, false, true).timeout.connect(func() -> void:
		if is_instance_valid(node):
			node.queue_free())
