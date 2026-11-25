extends Node3D
## The lobby [redesign 2026-11-25]: a walkable 3D hub with one portal per biome.
## Open portals glow and show progress (animals rescued, sentences answered); locked ones
## are grey and say what is still needed. Walking into an open portal enters its zone.
## There is no lesson screen: the rule is taught inside the zones. Owner: Lead.

const PORTAL_COLORS := {
	"forest": Color("#2f9e44"), "river": Color("#1098ad"), "mountain": Color("#846358"),
	"sky": Color("#7048e8"), "island": Color("#f59f00"),
}
const PORTAL_X := {"forest": 0.0, "river": -11.0, "mountain": 11.0, "sky": -20.0, "island": 20.0}

var player: Player3D
var camera: Camera3D
var _entering := ""
var autoplay := DebugTools.has_arg("--autoplay")


func _ready() -> void:
	_environment()
	_build()
	player = Player3D.new()
	add_child(player)
	player.global_position = Vector3(0, 0, 10)
	camera = Camera3D.new()
	camera.fov = 55
	add_child(camera)
	camera.current = true
	_ui()


func _environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var m := ProceduralSkyMaterial.new()
	m.sky_top_color = Color("#4dabf7")
	m.sky_horizon_color = Color("#d0ebff")
	m.ground_horizon_color = Color("#d0ebff")
	m.ground_bottom_color = Color("#69db7c")
	sky.sky_material = m
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.74, 0.69, 0.6)
	env.ambient_light_energy = 0.5
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.light_color = Color("#fff1cf")
	sun.shadow_enabled = true
	add_child(sun)


func _build() -> void:
	var g := MeshInstance3D.new()
	var p := PlaneMesh.new()
	p.size = Vector2(70, 60)
	g.mesh = p
	g.material_override = Blocky.material(Color("#51cf66"))
	add_child(g)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	# paths from the center toward each portal
	for biome in GameState.BIOME_ORDER:
		var px: float = PORTAL_X[biome]
		var portal_pos := Vector3(px, 0, -14 - absf(px) * 0.22)
		var steps := 12
		for i in steps:
			var t := float(i) / steps
			var pos := Vector3(0, 0, 10).lerp(portal_pos + Vector3(0, 0, 2.5), t)
			Blocky.box(self, Vector3(1.6, 0.06, 1.0), Color("#dee2e6").lerp(Color("#adb5bd"), rng.randf()), pos + Vector3(0, 0.03, 0))
		_portal(portal_pos, biome)
	for i in 16:
		var pos := Vector3(rng.randf_range(-30, 30), 0, rng.randf_range(-26, 24))
		if absf(pos.x) > 4.0 and pos.z > -22.0:
			Blocky.box(self, Vector3(0.6, 2.0, 0.6), Color("#8d5a3b"), pos + Vector3(0, 1.0, 0))
			var gr := Color("#2f9e44").lerp(Color("#40c057"), rng.randf())
			Blocky.box(self, Vector3(2.4, 1.5, 2.4), gr, pos + Vector3(0, 2.6, 0))
			Blocky.box(self, Vector3(1.5, 1.1, 1.5), gr.lightened(0.12), pos + Vector3(0, 3.7, 0))
	for i in 30:
		var pos := Vector3(rng.randf_range(-30, 30), 0, rng.randf_range(-24, 24))
		var c: Color = [Color("#ffd43b"), Color("#f783ac"), Color("#ffffff")][rng.randi() % 3]
		Blocky.box(self, Vector3(0.25, 0.25, 0.25), c, pos + Vector3(0, 0.12, 0))


func _portal(pos: Vector3, biome: String) -> void:
	var open := GameState.is_unlocked(biome)
	var color: Color = PORTAL_COLORS[biome]
	var c := color if open else Color("#868e96")
	Blocky.box(self, Vector3(0.7, 4.2, 0.7), c.darkened(0.35), pos + Vector3(-2.0, 2.1, 0))
	Blocky.box(self, Vector3(0.7, 4.2, 0.7), c.darkened(0.35), pos + Vector3(2.0, 2.1, 0))
	Blocky.box(self, Vector3(4.7, 0.7, 0.7), c.darkened(0.25), pos + Vector3(0, 4.3, 0))
	var glow := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(3.4, 3.9)
	glow.mesh = pm
	glow.material_override = Fx.glow_material(c, 0.5 if open else 0.1)
	glow.rotation_degrees = Vector3(90, 0, 0)
	glow.position = pos + Vector3(0, 2.0, 0)
	add_child(glow)
	Blocky.label3d(self, GameState.BIOME_NAMES[biome], pos + Vector3(0, 5.4, 0), 84,
		c.lightened(0.3) if open else Color("#adb5bd"))
	Blocky.label3d(self, ", ".join(GameState.BIOMES[biome]), pos + Vector3(0, 4.9, 0), 40,
		Color("#f1f3f5") if open else Color("#adb5bd"))
	var p := GameState.progress
	var sub := ""
	if open:
		var total: int = QuestionBank.get_animals(biome).size()
		sub = Strings.PROGRESS_ANIMALS % [p.collected_count(biome), total]
		var n := int(p.answered.get(biome, 0))
		if n > 0:
			sub += " · " + Strings.PROGRESS_SENTENCES % n
		Fx.sparkles(self, color).position = pos + Vector3(0, 2.2, 0)
	else:
		var prev_i := GameState.BIOME_ORDER.find(biome) - 1
		var prev: String = GameState.BIOME_ORDER[prev_i] if prev_i >= 0 else ""
		if prev != "" and GameState.is_unlocked(prev):
			sub = Strings.NEED_INDEX if not p.index_complete(prev, QuestionBank.get_animals(prev).size()) else Strings.NEED_ACCURACY
		elif prev != "":
			sub = Strings.NEED_PREV % GameState.BIOME_NAMES[prev]
	if sub != "":
		Blocky.label3d(self, sub, pos + Vector3(0, 0.7, 0.8), 38, Color("#ffe066") if open else Color("#ced4da"))


func _ui() -> void:
	var ui := CanvasLayer.new()
	add_child(ui)
	var title := UiKit.label(Strings.TITLE, 54, Color("#2b8a3e"), 12)
	title.add_theme_color_override("font_outline_color", Color.WHITE)
	title.position = Vector2(24, 14)
	ui.add_child(title)
	var sub := UiKit.label(Strings.HUB_TITLE, 24, Color.WHITE, 8)
	sub.position = Vector2(28, 76)
	ui.add_child(sub)
	var coins := UiKit.label(Strings.COINS % GameState.progress.coins, 32, Color("#ffd43b"), 10)
	coins.position = Vector2(1050, 22)
	ui.add_child(coins)
	var row := HBoxContainer.new()
	row.position = Vector2(24, 630)
	row.add_theme_constant_override("separation", 16)
	ui.add_child(row)
	var pen := UiKit.button(Strings.PEN, 26, Color("#9c36b5"))
	pen.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://ui/Pen.tscn"))
	row.add_child(pen)
	var prog := UiKit.button(Strings.MY_PROGRESS, 26, Color("#1971c2"))
	prog.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://ui/MyProgress.tscn"))
	row.add_child(prog)
	var shop := FruitShop.new()
	ui.add_child(shop)
	var shop_b := UiKit.button(Strings.SHOP, 26, Color("#e67700"))
	shop_b.pressed.connect(func() -> void: shop.open())
	row.add_child(shop_b)
	var joystick := Joystick.new()
	joystick.position = Vector2(1060, 500)
	ui.add_child(joystick)
	set_meta("joystick", joystick)
	var hint := UiKit.label(Strings.WALK_IN, 22, Color.WHITE, 8)
	hint.position = Vector2(500, 688)
	ui.add_child(hint)


func _process(delta: float) -> void:
	var joystick: Joystick = get_meta("joystick")
	var dir := Vector3(joystick.value.x, 0, joystick.value.y)
	var keys := Vector3(
		float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)),
		0,
		float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)))
	if keys.length() > 0:
		dir = keys.normalized()
	if autoplay and _entering == "":
		var target := Vector3(0, 0, -13.2)
		var d := target - player.global_position
		d.y = 0
		dir = d.normalized() if d.length() > 0.4 else Vector3.ZERO
		if not has_meta("snapped"):
			set_meta("snapped", true)
			DebugTools.snap(self, "01_hub")
	player.move(dir.limit_length(1.0), delta)
	player.global_position.x = clampf(player.global_position.x, -32.0, 32.0)
	player.global_position.z = clampf(player.global_position.z, -24.0, 24.0)
	var want := player.global_position + Vector3(0, 11, 9)
	camera.global_position = camera.global_position.lerp(want, 0.12)
	camera.look_at(player.global_position + Vector3(0, 1.2, 0))
	# walking into an open portal enters its zone
	if _entering == "":
		for biome in GameState.BIOME_ORDER:
			if not GameState.is_unlocked(biome) or not GameState.BIOME_SCENES.has(biome):
				continue
			var px: float = PORTAL_X[biome]
			var portal_pos := Vector3(px, 0, -14 - absf(px) * 0.22)
			var d := portal_pos - player.global_position
			d.y = 0
			if d.length() < 1.6:
				_entering = biome
				AudioManager.play("rare")
				var fade := ColorRect.new()
				fade.color = Color(1, 1, 1, 0)
				fade.size = Vector2(1280, 720)
				var layer := CanvasLayer.new()
				add_child(layer)
				layer.add_child(fade)
				var t := create_tween()
				t.tween_property(fade, "color:a", 1.0, 0.45)
				t.tween_callback(func() -> void: get_tree().change_scene_to_file(GameState.BIOME_SCENES[biome]))
				return
