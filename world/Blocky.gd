class_name Blocky
extends RefCounted
## Helpers for the blocky, Roblox-like placeholder look: everything is built from coloured boxes.
## Owner: Alex. Real models can replace these later; keep the node names the scripts use.

static var _materials := {}


static func material(color: Color) -> StandardMaterial3D:
	var key := color.to_html()
	if not _materials.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = 1.0
		m.metallic_specular = 0.0   # no shiny highlights: keeps the flat, blocky colours
		_materials[key] = m
	return _materials[key]


static func box(parent: Node3D, size: Vector3, color: Color, pos: Vector3, node_name: String = "") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = material(color)
	mi.position = pos
	if node_name != "":
		mi.name = node_name
	parent.add_child(mi)
	return mi


static func cylinder(parent: Node3D, radius: float, height: float, color: Color, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 8
	mi.mesh = mesh
	mi.material_override = material(color)
	mi.position = pos
	parent.add_child(mi)
	return mi


static func sphere(parent: Node3D, radius: float, color: Color, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	mi.mesh = mesh
	mi.material_override = material(color)
	mi.position = pos
	parent.add_child(mi)
	return mi


## A floating, always-facing-the-camera text label.
static func label3d(parent: Node3D, text: String, pos: Vector3, size: int = 64, color: Color = Color.WHITE) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.font_size = size
	l.outline_size = 18
	l.modulate = color
	l.outline_modulate = Color(0.1, 0.1, 0.1, 0.9)
	l.pixel_size = 0.01
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.render_priority = 10
	l.outline_render_priority = 9
	parent.add_child(l)
	return l
