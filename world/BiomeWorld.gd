class_name BiomeWorld
extends Node3D
## A 3D biome (Pet Simulator style). Owner: Lead. Loraine builds each biome from this.
##
## Loop:
##   - Walk around (joystick or WASD). Wild animals wear a word tag: the word before din/rin.
##   - Pick a fruit in the hotbar (rin or din) and press Ihagis [Throw] near an animal.
##   - Preferred form: it eats, says the whole sentence, and follows you.
##     Walk into the pen: it joins the Animal Index and you get coins.
##   - Otherwise: it sniffs and walks off; a hint lights up the deciding letter (worked example on
##     the 2nd miss of the same sentence). The sentence comes back later on another animal.
## Logic: core/BiomeSession.gd + core/Progress.gd (unit-tested). This script only shows it.

@export var biome: String = "forest"

const WILD_COUNT := 4
const THROW_RANGE := 10.0
const PEN_CENTER := Vector3(-10, 0, 12)
const PEN_HALF := 4.0
const PLAYER_START := Vector3(0, 0, 9)
const MAP_HALF := 28.0
const CAMERA_OFFSET := Vector3(0, 10, 10)
const FRUIT_COLORS := [Color("#e64980"), Color("#f08c00"), Color("#7950f2")]
const AUTOPLAY_THROWS := 12

var session: BiomeSession
var player: Player3D
var camera: Camera3D
var animals: Array[Animal3D] = []
var followers: Array[Animal3D] = []
var fruits: Array[String] = []
var selected_fruit := ""
var _throwing := false
var _spawn_cooldown := 0.0
var _hint_token := 0

# HUD
var ui: CanvasLayer
var joystick: Joystick
var coins_label: Label
var follow_label: Label
var index_button: Button
var fruit_buttons: Dictionary = {}
var throw_button: Button
var toast: Label
var hint_panel: PanelContainer
var hint_box: VBoxContainer
var index_page: AnimalIndex
var debug_label: Label

# Autoplay
var autoplay := DebugTools.has_arg("--autoplay")
var _bot_dir := Vector3.ZERO
var _bot_wait := 1.5
var _bot_throws := 0
var _bot_done := false
var _first_miss_id := ""
var _snapped := {}
var _started_ms := 0


func _ready() -> void:
	_started_ms = Time.get_ticks_msec()
	session = BiomeSession.new(biome, QuestionBank.get_items(biome), QuestionBank.get_animals(biome), GameState.progress)
	if not session.items.is_empty():
		var d := DRRule.d_form(session.items[0].answer)
		fruits = [DRRule.r_form(d), d]
	_build_environment()
	_build_map()
	player = Player3D.new()
	add_child(player)
	player.global_position = PLAYER_START
	camera = Camera3D.new()
	camera.fov = 55
	add_child(camera)
	camera.current = true
	_place_camera(1.0)
	_build_ui()
	for biome_id in GameState.progress.collected.get(biome, []):
		_spawn_in_pen(biome_id)
	if session.items.is_empty():
		_show_toast(Strings.NO_ITEMS, 999.0)
		return
	for i in WILD_COUNT:
		_spawn_wild()
	_select_fruit(fruits[0])


# ---------------------------------------------------------------- world building

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("#4dabf7")
	sky_mat.sky_horizon_color = Color("#d0ebff")
	sky_mat.ground_horizon_color = Color("#d0ebff")
	sky_mat.ground_bottom_color = Color("#69db7c")
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.66, 0.72)
	env.ambient_light_energy = 0.45
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.light_energy = 0.8
	sun.shadow_enabled = true
	add_child(sun)


func _build_map() -> void:
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(MAP_HALF * 2 + 24, MAP_HALF * 2 + 24)
	ground.mesh = plane
	ground.material_override = Blocky.material(Color("#51cf66"))
	add_child(ground)

	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var placed: Array[Vector3] = []
	var pen_zone := Rect2(PEN_CENTER.x - PEN_HALF - 2, PEN_CENTER.z - PEN_HALF - 2, PEN_HALF * 2 + 4, PEN_HALF * 2 + 4)
	var tries := 0
	while placed.size() < 38 and tries < 2000:
		tries += 1
		var p := Vector3(rng.randf_range(-MAP_HALF, MAP_HALF), 0, rng.randf_range(-MAP_HALF, MAP_HALF))
		if pen_zone.has_point(Vector2(p.x, p.z)) or p.distance_to(PLAYER_START) < 6.0:
			continue
		var ok := true
		for q in placed:
			if p.distance_to(q) < 4.0:
				ok = false
				break
		if ok:
			placed.append(p)
			_tree(p, rng)
	# Small decorations
	for i in 60:
		var p := Vector3(rng.randf_range(-MAP_HALF, MAP_HALF), 0, rng.randf_range(-MAP_HALF, MAP_HALF))
		var c: Color = [Color("#ffd43b"), Color("#f783ac"), Color("#ffffff"), Color("#868e96")][rng.randi() % 4]
		Blocky.box(self, Vector3(0.25, 0.25, 0.25), c, p + Vector3(0, 0.12, 0))
	# Map border: a row of bushes the player cannot pass (position is also clamped).
	for x in range(-int(MAP_HALF) - 2, int(MAP_HALF) + 3, 3):
		for z in [-MAP_HALF - 2, MAP_HALF + 2]:
			Blocky.box(self, Vector3(3, 1.4, 1.5), Color("#2b8a3e"), Vector3(x, 0.7, z))
			Blocky.box(self, Vector3(1.5, 1.4, 3), Color("#2b8a3e"), Vector3(z, 0.7, x))
	_build_pen()


func _tree(p: Vector3, rng: RandomNumberGenerator) -> void:
	var t := StaticBody3D.new()
	add_child(t)
	t.position = p
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.6
	cyl.height = 3.0
	shape.shape = cyl
	shape.position = Vector3(0, 1.5, 0)
	t.add_child(shape)
	var h := rng.randf_range(1.6, 2.6)
	Blocky.box(t, Vector3(0.6, h, 0.6), Color("#8d5a3b"), Vector3(0, h / 2.0, 0))
	var g := Color("#2f9e44").lerp(Color("#40c057"), rng.randf())
	Blocky.box(t, Vector3(2.6, 1.6, 2.6), g, Vector3(0, h + 0.7, 0))
	Blocky.box(t, Vector3(1.7, 1.2, 1.7), g.lightened(0.12), Vector3(0, h + 1.9, 0))


func _build_pen() -> void:
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(PEN_HALF * 2, PEN_HALF * 2)
	floor_mesh.mesh = plane
	floor_mesh.material_override = Blocky.material(Color("#e9c46a"))
	floor_mesh.position = PEN_CENTER + Vector3(0, 0.02, 0)
	add_child(floor_mesh)
	var wood := Color("#a0522d")
	var h := PEN_HALF
	for i in range(-int(h), int(h) + 1, 2):
		for side in [Vector3(i, 0, -h), Vector3(i, 0, h), Vector3(-h, 0, i), Vector3(h, 0, i)]:
			if side.x == h and abs(side.z) <= 1:   # gate on the east side, facing the forest
				continue
			Blocky.box(self, Vector3(0.25, 1.1, 0.25), wood, PEN_CENTER + side + Vector3(0, 0.55, 0))
	Blocky.box(self, Vector3(h * 2, 0.15, 0.12), wood, PEN_CENTER + Vector3(0, 0.8, -h))
	Blocky.box(self, Vector3(h * 2, 0.15, 0.12), wood, PEN_CENTER + Vector3(0, 0.8, h))
	Blocky.box(self, Vector3(0.12, 0.15, h * 2), wood, PEN_CENTER + Vector3(-h, 0.8, 0))
	Blocky.box(self, Vector3(0.12, 0.15, h - 1.2), wood, PEN_CENTER + Vector3(h, 0.8, -h / 2.0 - 0.6))
	Blocky.box(self, Vector3(0.12, 0.15, h - 1.2), wood, PEN_CENTER + Vector3(h, 0.8, h / 2.0 + 0.6))
	Blocky.label3d(self, Strings.PEN, PEN_CENTER + Vector3(0, 2.6, -h), 90, Color("#ffe066"))


func _pen_rect() -> Rect2:
	return Rect2(PEN_CENTER.x - PEN_HALF, PEN_CENTER.z - PEN_HALF, PEN_HALF * 2, PEN_HALF * 2)


func _random_pen_spot() -> Vector3:
	var r := _pen_rect().grow(-0.8)
	return Vector3(randf_range(r.position.x, r.end.x), 0, randf_range(r.position.y, r.end.y))


# ---------------------------------------------------------------- animals

func _new_animal(data: Dictionary, item: Dictionary, state: Animal3D.State) -> Animal3D:
	var a := Animal3D.new()
	a.pen_area = _pen_rect()
	a.wander_area = Rect2(-MAP_HALF + 2, -MAP_HALF + 2, MAP_HALF * 2 - 4, MAP_HALF + 4)
	a.setup(data, item, state)
	a.player = player
	a.arrived_in_pen.connect(_on_arrived_in_pen)
	a.left_map.connect(func(x: Animal3D) -> void: animals.erase(x))
	add_child(a)
	animals.append(a)
	return a


func _spawn_in_pen(animal_id: String) -> void:
	var data := QuestionBank.find_animal(animal_id)
	if data.is_empty():
		return
	var a := _new_animal(data, {}, Animal3D.State.IN_PEN)
	a.global_position = _random_pen_spot()


func _spawn_wild() -> void:
	var busy_a := []
	var busy_i := []
	for a in animals:
		if a.state != Animal3D.State.IN_PEN:
			busy_a.append(a.data.get("id", ""))
			busy_i.append(a.item.get("id", ""))
	var item := session.next_sentence(busy_a, busy_i)
	if item.is_empty():
		return
	var a := _new_animal(session.current_animal, item, Animal3D.State.WILD)
	for i in 20:
		var p := Vector3(randf_range(-MAP_HALF + 3, MAP_HALF - 3), 0, randf_range(-MAP_HALF + 3, 4))
		if p.distance_to(player.global_position) > 9.0:
			a.global_position = p
			return
	a.global_position = Vector3(0, 0, -15)


func _wild_count() -> int:
	var n := 0
	for a in animals:
		if a.state == Animal3D.State.WILD:
			n += 1
	return n


# ---------------------------------------------------------------- frame

func _process(delta: float) -> void:
	var dir := Vector3(joystick.value.x, 0, joystick.value.y)
	var keys := Vector3(
		float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)),
		0,
		float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)))
	if keys.length() > 0:
		dir = keys.normalized()
	if autoplay:
		_bot(delta)
		dir = _bot_dir
	player.move(dir.limit_length(1.0), delta)
	player.global_position.x = clamp(player.global_position.x, -MAP_HALF, MAP_HALF)
	player.global_position.z = clamp(player.global_position.z, -MAP_HALF, MAP_HALF)
	_place_camera(delta * 5.0)

	# Bring followers home.
	if not followers.is_empty() and _pen_rect().grow(1.0).has_point(Vector2(player.global_position.x, player.global_position.z)):
		for f in followers:
			f.go_to_pen(_random_pen_spot())
		followers.clear()
		_refresh_hud()

	# Keep the forest full of wild animals.
	_spawn_cooldown -= delta
	if _spawn_cooldown <= 0.0 and _wild_count() < WILD_COUNT and not session.items.is_empty():
		_spawn_wild()
		_spawn_cooldown = 2.0


func _place_camera(weight: float) -> void:
	var want := player.global_position + CAMERA_OFFSET
	camera.global_position = camera.global_position.lerp(want, clamp(weight, 0.0, 1.0))
	camera.look_at(camera.global_position - CAMERA_OFFSET + Vector3(0, 1, 0))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				_select_fruit(fruits[0])
			KEY_2:
				if fruits.size() > 1:
					_select_fruit(fruits[1])
			KEY_SPACE:
				throw_selected()
			KEY_F3:
				debug_label.visible = not debug_label.visible


# ---------------------------------------------------------------- throwing

func _select_fruit(f: String) -> void:
	selected_fruit = f
	for name in fruit_buttons:
		var b: Button = fruit_buttons[name]
		var sel: bool = name == f
		var sb: StyleBoxFlat = b.get_theme_stylebox("normal").duplicate()
		sb.border_color = Color.WHITE
		sb.set_border_width_all(7 if sel else 0)
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", sb)
		b.scale = Vector2(1.12, 1.12) if sel else Vector2.ONE


## The wild animal the throw goes to: in range, mostly in front of the player (aim assist).
func _pick_target() -> Animal3D:
	var best: Animal3D = null
	var best_score := INF
	for a in animals:
		if not a.is_wild():
			continue
		var d := a.global_position - player.global_position
		d.y = 0
		var dist := d.length()
		if dist > THROW_RANGE:
			continue
		var front := player.facing.dot(d.normalized()) if dist > 0.01 else 1.0
		if front < -0.2 and dist > 3.0:
			continue
		var score := dist * (2.0 - front)
		if score < best_score:
			best_score = score
			best = a
	return best


func throw_selected() -> void:
	if _throwing or selected_fruit == "":
		return
	var target := _pick_target()
	if target == null:
		_show_toast(Strings.NO_ANIMAL_NEAR)
		return
	_throwing = true
	var fruit := selected_fruit
	var to_target := target.global_position - player.global_position
	to_target.y = 0
	if to_target.length() > 0.01:
		player.facing = to_target.normalized()
		player.move(Vector3.ZERO, 0.016)
	var proj := Node3D.new()
	add_child(proj)
	Blocky.sphere(proj, 0.3, FRUIT_COLORS[fruits.find(fruit) % FRUIT_COLORS.size()], Vector3.ZERO)
	Blocky.label3d(proj, fruit, Vector3(0, 0.6, 0), 44)
	var start := player.hand_position()
	proj.global_position = start
	var t := create_tween()
	t.tween_method(func(k: float) -> void:
		if not is_instance_valid(target):
			return
		var end := target.global_position + Vector3(0, 1.3, 0)
		var ctrl := (start + end) / 2.0 + Vector3(0, 3.0, 0)
		proj.global_position = start.lerp(ctrl, k).lerp(ctrl.lerp(end, k), k)
	, 0.0, 1.0, 0.55)
	await t.finished
	proj.queue_free()
	_throwing = false
	if is_instance_valid(target) and target.is_wild():
		_resolve(target, fruit)


func _resolve(target: Animal3D, fruit: String) -> void:
	var r := session.answer(fruit, target.item, target.data)
	SaveManager.log_answer({
		"biome": biome, "item": target.item.get("id", ""), "pair": target.item.get("pair", ""),
		"stage": target.item.get("stage", ""), "chosen": fruit, "correct": r.correct,
		"hint_level": r.hint_level, "animal": target.data.get("id", ""), "coins": GameState.progress.coins,
		"ms_since_start": Time.get_ticks_msec() - _started_ms,
	})
	if r.correct:
		followers.append(target)
		target.eat(player, followers.size() - 1)
		_show_toast(Strings.CORRECT)
		if autoplay:
			_bot_snap_later("13_fed", 0.5)
	else:
		var exit := Vector3(target.global_position.x, 0, -MAP_HALF - 4)
		target.sniff(exit)
		_show_hint(target.item, r.hint_level)
	SaveManager.save_game()
	_refresh_hud()


func _on_arrived_in_pen(a: Animal3D) -> void:
	if a.item.is_empty():
		return
	var d := session.deliver(a.data.get("id", ""))
	a.item = {}
	var msg := Strings.COINS_EARNED % d.coins
	if d.new_animal:
		msg = "%s  %s" % [Strings.NEW_FRIEND % a.data.get("name", ""), msg]
	_show_toast(msg, 1.6)
	if d.cleared:
		var opened := GameState.unlock_next(biome)
		if opened != "":
			_show_toast(Strings.UNLOCKED % GameState.BIOME_NAMES.get(opened, opened), 2.5)
	SaveManager.save_game()
	_refresh_hud()
	if autoplay:
		_bot_snap_later("17_delivered", 0.4)


# ---------------------------------------------------------------- HUD

func _build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)

	var back := UiKit.button(Strings.BACK, 24, Color("#495057"))
	back.position = Vector2(16, 14)
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://main/Main.tscn"))
	ui.add_child(back)

	coins_label = UiKit.label("", 32, Color("#ffd43b"), 10)
	coins_label.position = Vector2(170, 22)
	ui.add_child(coins_label)

	follow_label = UiKit.label("", 26, Color.WHITE, 10)
	follow_label.position = Vector2(360, 26)
	ui.add_child(follow_label)

	index_button = UiKit.button("", 24, Color("#1971c2"))
	index_button.position = Vector2(860, 14)
	index_button.pressed.connect(func() -> void: index_page.open(biome))
	ui.add_child(index_button)

	var lesson := UiKit.button(Strings.LESSON, 24, Color("#0b7285"))
	lesson.position = Vector2(1130, 14)
	lesson.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://ui/Lesson.tscn"))
	ui.add_child(lesson)

	joystick = Joystick.new()
	joystick.position = Vector2(50, 500)
	ui.add_child(joystick)

	var hotbar := HBoxContainer.new()
	hotbar.add_theme_constant_override("separation", 26)
	hotbar.position = Vector2(470, 600)
	ui.add_child(hotbar)
	for i in fruits.size():
		var f := fruits[i]
		var b := UiKit.button(f, 40, FRUIT_COLORS[i % FRUIT_COLORS.size()])
		b.custom_minimum_size = Vector2(140, 96)
		b.pivot_offset = b.custom_minimum_size / 2.0
		b.pressed.connect(_select_fruit.bind(f))
		hotbar.add_child(b)
		fruit_buttons[f] = b

	throw_button = UiKit.button(Strings.THROW, 36, Color("#e8590c"))
	throw_button.custom_minimum_size = Vector2(170, 170)
	for state in ["normal", "hover", "pressed"]:
		var sb: StyleBoxFlat = throw_button.get_theme_stylebox(state).duplicate()
		sb.set_corner_radius_all(85)
		throw_button.add_theme_stylebox_override(state, sb)
	throw_button.position = Vector2(1080, 520)
	throw_button.pressed.connect(throw_selected)
	ui.add_child(throw_button)

	toast = UiKit.label("", 48, Color.WHITE, 14)
	toast.add_theme_color_override("font_outline_color", Color("#2b8a3e"))
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.size = Vector2(1280, 70)
	toast.position = Vector2(0, 420)
	toast.visible = false
	ui.add_child(toast)

	hint_panel = UiKit.panel()
	hint_panel.position = Vector2(250, 90)
	hint_panel.custom_minimum_size = Vector2(780, 0)
	hint_box = VBoxContainer.new()
	hint_box.add_theme_constant_override("separation", 10)
	hint_panel.add_child(hint_box)
	hint_panel.visible = false
	ui.add_child(hint_panel)

	debug_label = UiKit.label("", 18, Color.WHITE, 6)
	debug_label.position = Vector2(20, 100)
	debug_label.visible = false
	ui.add_child(debug_label)

	index_page = AnimalIndex.new()
	ui.add_child(index_page)
	_refresh_hud()


func _refresh_hud() -> void:
	coins_label.text = Strings.COINS % GameState.progress.coins
	index_button.text = "%s  %d/%d" % [Strings.INDEX, GameState.progress.collected_count(biome), session.animals.size()]
	follow_label.text = "" if followers.is_empty() else "%s   %s" % [Strings.FOLLOWING % followers.size(), Strings.TAKE_HOME]
	var lines := ["F3 debug (team only)"]
	for s in session.stages:
		lines.append("%s: %d%% of last %d %s" % [s, int(GameState.progress.stage_accuracy(biome, s) * 100),
			GameState.progress.stage_window(biome, s).size(), "OK" if GameState.progress.stage_met(biome, s) else ""])
	lines.append("mode: %s" % ("mixed" if session.mixed else "stage %d" % (session.stage_index + 1)))
	debug_label.text = "\n".join(lines)


## Non-blocking hint: the game keeps running. Level 2 = worked example.
func _show_hint(item: Dictionary, level: int) -> void:
	_hint_token += 1
	var token := _hint_token
	for c in hint_box.get_children():
		hint_box.remove_child(c)
		c.queue_free()
	hint_box.add_child(UiKit.label(Hints.title(item.prev_word), 34, Color("#d9480f")))
	if level >= 2:
		hint_box.add_child(UiKit.label(Strings.WORKED_EXAMPLE, 26, UiKit.INK))
		for line in Hints.worked_example(item):
			var l := UiKit.rich(30, 740)
			l.text = line
			hint_box.add_child(l)
	else:
		var s := UiKit.rich(40, 740)
		s.text = Hints.highlighted_sentence(item, "_____")
		hint_box.add_child(s)
		var rule := UiKit.rich(30, 740)
		rule.text = "[b]%s[/b]" % Hints.rule_line(item.prev_word)
		hint_box.add_child(rule)
	hint_box.add_child(UiKit.label(Strings.COMES_BACK, 22, Color("#495057")))
	var ok := UiKit.button(Strings.OK, 28)
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ok.pressed.connect(func() -> void: hint_panel.visible = false)
	hint_box.add_child(ok)
	hint_panel.visible = true
	hint_panel.reset_size()
	hint_panel.call_deferred("reset_size")
	if autoplay:
		_bot_snap_later("14_hint" if level == 1 else "15_worked_example", 0.3)
	# The first hint fades by itself; the worked example stays until "Sige".
	if level == 1:
		await get_tree().create_timer(7.0 if not autoplay else 1.5).timeout
		if token == _hint_token:
			hint_panel.visible = false
	elif autoplay:
		await get_tree().create_timer(1.5).timeout
		hint_panel.visible = false


func _show_toast(text: String, seconds: float = 1.0) -> void:
	toast.text = text
	toast.modulate.a = 1.0
	toast.visible = true
	var t := create_tween()
	t.tween_interval(seconds)
	t.tween_property(toast, "modulate:a", 0.0, 0.3)
	t.tween_callback(func() -> void: toast.visible = false)


# ---------------------------------------------------------------- autoplay (checks without a person)

func _bot(delta: float) -> void:
	_bot_dir = Vector3.ZERO
	if _bot_done:
		return
	if Time.get_ticks_msec() - _started_ms > 150000:
		_finish_autoplay()
		return
	if _snapped.size() == 0 and _bot_wait <= 1.0:
		_bot_snap_later("12_world", 0.0)
	if _bot_wait > 0.0:
		_bot_wait -= delta
		return
	var to_pen := PEN_CENTER - player.global_position
	to_pen.y = 0
	var going_home := followers.size() >= 3 or (_bot_throws >= AUTOPLAY_THROWS and not followers.is_empty())
	if going_home:
		if followers.size() >= 2:
			_bot_snap_later("16_following", 0.0)
		_bot_dir = to_pen.normalized() if to_pen.length() > 0.5 else Vector3.ZERO
		return
	if _bot_throws >= AUTOPLAY_THROWS:
		for a in animals:
			if a.state == Animal3D.State.TO_PEN:
				return
		_finish_autoplay()
		return
	var target := _nearest_wild()
	if target == null:
		return
	var d := target.global_position - player.global_position
	d.y = 0
	if d.length() > 5.0:
		_bot_dir = d.normalized()
		return
	player.facing = d.normalized()
	_select_fruit(_bot_choice(target))
	throw_selected()
	_bot_throws += 1
	_bot_wait = 2.6


func _nearest_wild() -> Animal3D:
	var best: Animal3D = null
	var best_d := INF
	for a in animals:
		if a.is_wild():
			var dist := a.global_position.distance_to(player.global_position)
			if dist < best_d:
				best_d = dist
				best = a
	return best


## Mostly the preferred form; misses throw 2, and misses that sentence again when it comes back.
func _bot_choice(target: Animal3D) -> String:
	var right: String = target.item.answer
	var wrong: String = DRRule.d_form(right) if right != DRRule.d_form(right) else DRRule.r_form(right)
	if _bot_throws == 1:
		_first_miss_id = target.item.id
		return wrong
	if target.item.id == _first_miss_id and int(session.misses.get(_first_miss_id, 0)) == 1:
		return wrong
	return right


func _bot_snap_later(shot: String, delay: float) -> void:
	if not autoplay or _snapped.has(shot):
		return
	_snapped[shot] = true
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	await DebugTools.snap(self, shot)


func _finish_autoplay() -> void:
	if _bot_done:
		return
	_bot_done = true
	index_page.open(biome)
	await get_tree().create_timer(0.3).timeout
	await DebugTools.snap(self, "18_index")
	print("AUTOPLAY 3D: throws=%d coins=%d animals=%d/%d misses=%s shots=%s" % [_bot_throws, GameState.progress.coins,
		GameState.progress.collected_count(biome), session.animals.size(), session.misses, _snapped.keys()])
	get_tree().quit()
