class_name BiomeWorld
extends Node3D
## A 3D biome (Pet Simulator style). Owner: Lead. Loraine builds each biome from this.
##
## Loop:
##   - Walk around (joystick or WASD). Wild animals wear a word tag: the word before din/rin.
##   - Pick a fruit word in the hotbar (rin or din). HOLD Ihagis [Throw]: the power meter goes up
##     and down; let go inside the green band to reach the animal being aimed at.
##   - Animals back away if you come too close. Rare and golden ones are shyer, so they need
##     a stronger throw (better fruit from the shop flies farther).
##   - Preferred form: "NAHULI MO!" popup, coins (x combo), the animal follows you.
##     Walk into the pen: it joins the Animal Index.
##   - Not the preferred form: it sniffs and walks off; a hint lights up the deciding letter
##     (worked example on the 2nd miss of the same sentence). The streak resets.
##   - A streak of correct first throws brings rare (3) and golden (6) animals and a coin multiplier.
## Logic: core/BiomeSession.gd + core/Progress.gd (unit-tested). This script only shows it.

@export var biome: String = "forest"

const WILD_COUNT := 4
const PEN_CENTER := Vector3(-10, 0, 12)
const PEN_HALF := 4.0
const PLAYER_START := Vector3(0, 0, 9)
const MAP_HALF := 28.0
const CAMERA_OFFSET := Vector3(0, 11, 11)
const WORD_COLORS := [Color("#e64980"), Color("#f08c00"), Color("#7950f2")]
const AUTOPLAY_THROWS := 18

var session: BiomeSession
var player: Player3D
var camera: Camera3D
var animals: Array[Animal3D] = []
var followers: Array[Animal3D] = []
var fruits: Array[String] = []
var selected_fruit := ""
var _throwing := false
var _charging := false
var _charge_t := 0.0
var _aim: Animal3D = null
var _aim_ring: MeshInstance3D
var _spawn_cooldown := 0.0
var _hint_token := 0
var _popup_token := 0
var _cam_focus: Node3D = null   ## the camera chases the fruit, then looks at the reveal
var _shake := 0.0
var _shown_coins := -1

# HUD
var ui: CanvasLayer
var joystick: Joystick
var coins_label: Label
var follow_label: Label
var combo_label: Label
var mult_label: Label
var fruit_label: Label
var index_button: Button
var fruit_buttons: Dictionary = {}
var throw_button: Button
var meter: PowerMeter
var toast: Label
var hint_panel: PanelContainer
var hint_box: VBoxContainer
var catch_panel: PanelContainer
var catch_box: VBoxContainer
var index_page: AnimalIndex
var shop: FruitShop
var debug_label: Label
var speed_lines: SpeedLines
var flash: ColorRect
var distance_label: Label

# Autoplay
var autoplay := DebugTools.has_arg("--autoplay")
var _bot_dir := Vector3.ZERO
var _bot_wait := 1.5
var _bot_throws := 0
var _bot_done := false
var _bot_bought := false
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
	_aim_ring = Blocky.cylinder(self, 1.1, 0.06, Color("#ff922b"), Vector3.ZERO)
	_aim_ring.visible = false
	_build_ui()
	for animal_id in GameState.progress.collected.get(biome, []):
		_spawn_in_pen(animal_id)
	if session.items.is_empty():
		_show_toast(Strings.NO_ITEMS, 999.0)
		return
	for i in WILD_COUNT:
		_spawn_wild("common")
	_select_fruit(fruits[0])


func _range() -> float:
	return float(GameState.progress.equipped_tier().range)


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
	while placed.size() < 30 and tries < 2000:
		tries += 1
		var p := Vector3(rng.randf_range(-MAP_HALF, MAP_HALF), 0, rng.randf_range(-MAP_HALF, MAP_HALF))
		if pen_zone.has_point(Vector2(p.x, p.z)) or p.distance_to(PLAYER_START) < 7.0:
			continue
		var ok := true
		for q in placed:
			if p.distance_to(q) < 5.0:
				ok = false
				break
		if ok:
			placed.append(p)
			_tree(p, rng)
	for i in 60:
		var p := Vector3(rng.randf_range(-MAP_HALF, MAP_HALF), 0, rng.randf_range(-MAP_HALF, MAP_HALF))
		var c: Color = [Color("#ffd43b"), Color("#f783ac"), Color("#ffffff"), Color("#868e96")][rng.randi() % 4]
		Blocky.box(self, Vector3(0.25, 0.25, 0.25), c, p + Vector3(0, 0.12, 0))
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

func _new_animal(data: Dictionary, item: Dictionary, state: Animal3D.State, rarity: String) -> Animal3D:
	var a := Animal3D.new()
	a.pen_area = _pen_rect()
	a.wander_area = Rect2(-MAP_HALF + 2, -MAP_HALF + 2, MAP_HALF * 2 - 4, MAP_HALF + 4)
	a.setup(data, item, state, rarity)
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
	var best := "common"
	for r in ["rare", "golden"]:
		if GameState.progress.has_variant(biome, animal_id, r):
			best = r
	var a := _new_animal(data, {}, Animal3D.State.IN_PEN, best)
	a.global_position = _random_pen_spot()


## `far`: rare/golden bonus animals appear farther away.
func _spawn_wild(rarity: String, far: bool = false) -> Animal3D:
	var busy_a := []
	var busy_i := []
	for a in animals:
		if a.state != Animal3D.State.IN_PEN:
			busy_a.append(a.data.get("id", ""))
			busy_i.append(a.item.get("id", ""))
	var item := session.next_sentence(busy_a, busy_i)
	if item.is_empty():
		return null
	var a := _new_animal(session.current_animal, item, Animal3D.State.WILD, rarity)
	var min_d := 12.0 if far else 9.0
	for i in 30:
		var p := Vector3(randf_range(-MAP_HALF + 3, MAP_HALF - 3), 0, randf_range(-MAP_HALF + 3, 4))
		var d := p.distance_to(player.global_position)
		if d > min_d and (not far or d < 20.0):
			a.global_position = p
			return a
	a.global_position = Vector3(0, 0, -15)
	return a


func _wild_count() -> int:
	var n := 0
	for a in animals:
		if a.state == Animal3D.State.WILD and a.rarity == "common":
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
	if _charging:
		dir = Vector3.ZERO   # stand still while aiming
	player.move(dir.limit_length(1.0), delta)
	player.global_position.x = clamp(player.global_position.x, -MAP_HALF, MAP_HALF)
	player.global_position.z = clamp(player.global_position.z, -MAP_HALF, MAP_HALF)
	_place_camera(delta * 5.0)
	_update_aim(delta)

	if not followers.is_empty() and _pen_rect().grow(1.0).has_point(Vector2(player.global_position.x, player.global_position.z)):
		for f in followers:
			f.go_to_pen(_random_pen_spot())
		followers.clear()
		_refresh_hud()

	_spawn_cooldown -= delta
	if _spawn_cooldown <= 0.0 and _wild_count() < WILD_COUNT and not session.items.is_empty():
		_spawn_wild("common")
		_spawn_cooldown = 2.0


func _place_camera(weight: float) -> void:
	var focus := player.global_position
	var offset := CAMERA_OFFSET
	if _cam_focus != null and is_instance_valid(_cam_focus):
		# Chase the fruit / show the reveal, pulled back a bit so the whole moment fits.
		focus = player.global_position.lerp(_cam_focus.global_position, 0.75)
		offset = CAMERA_OFFSET * 1.2
	var want := focus + offset
	camera.global_position = camera.global_position.lerp(want, clamp(weight, 0.0, 1.0))
	camera.look_at(camera.global_position - offset + Vector3(0, 1, 0))
	if _shake > 0.01:
		camera.global_position += Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * _shake * 0.35
		_shake = move_toward(_shake, 0.0, get_process_delta_time() * 2.5)


## Picks the animal being aimed at, shows a ring under it and the green band on the meter.
func _update_aim(delta: float) -> void:
	if not _charging:
		_aim = _pick_target()
	if _aim != null and is_instance_valid(_aim) and _aim.is_wild():
		_aim_ring.visible = true
		_aim_ring.global_position = _aim.global_position + Vector3(0, 0.05, 0)
		var dist := _flat_distance(_aim.global_position)
		var r := _range()
		meter.set_band((dist - GameConfig.HIT_RADIUS) / r, (dist + GameConfig.HIT_RADIUS) / r)
	else:
		_aim = null
		_aim_ring.visible = false
		meter.set_band(-1.0, -1.0)
	if _charging:
		_charge_t += delta
		meter.set_value(0.5 - 0.5 * cos(TAU * _charge_t / GameConfig.METER_PERIOD))


func _flat_distance(p: Vector3) -> float:
	var d := p - player.global_position
	d.y = 0
	return d.length()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and not event.echo:
		match event.keycode:
			KEY_1:
				if event.pressed:
					_select_fruit(fruits[0])
			KEY_2:
				if event.pressed and fruits.size() > 1:
					_select_fruit(fruits[1])
			KEY_SPACE:
				if event.pressed:
					start_charge()
				else:
					release_throw()
			KEY_F3:
				if event.pressed:
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


## The wild animal the player is aiming at: mostly in front, within 1.3x the fruit's range.
func _pick_target() -> Animal3D:
	var best: Animal3D = null
	var best_score := INF
	var max_d := _range() * 1.3
	for a in animals:
		if not a.is_wild():
			continue
		var d := a.global_position - player.global_position
		d.y = 0
		var dist := d.length()
		if dist > max_d:
			continue
		var front := player.facing.dot(d.normalized()) if dist > 0.01 else 1.0
		if front < 0.2:
			continue
		var score := dist * (2.0 - front)
		if score < best_score:
			best_score = score
			best = a
	return best


func start_charge() -> void:
	if _throwing or _charging or selected_fruit == "":
		return
	if _aim == null:
		_show_toast(Strings.NO_ANIMAL_NEAR)
		return
	_charging = true
	_charge_t = 0.0
	meter.active = true


func release_throw(forced_power: float = -1.0) -> void:
	if not _charging:
		return
	_charging = false
	var power := meter.value if forced_power < 0.0 else forced_power
	meter.set_value(power)
	await _throw(power)
	meter.active = false
	meter.queue_redraw()


func _throw(power: float) -> void:
	_throwing = true
	var fruit := selected_fruit
	var target := _aim
	var dir := player.facing
	if target != null and is_instance_valid(target):
		var to_t := target.global_position - player.global_position
		to_t.y = 0
		if to_t.length() > 0.01:
			dir = to_t.normalized()
			player.facing = dir
			player.move(Vector3.ZERO, 0.016)
	var landing := player.global_position + dir * power * _range()
	var hit: Animal3D = null
	for a in animals:
		if a.is_wild() and _flat_distance(a.global_position) > 0.0 \
				and Vector2(a.global_position.x - landing.x, a.global_position.z - landing.z).length() <= GameConfig.HIT_RADIUS:
			if hit == null or a == target:
				hit = a

	# PERPEKTO [perfect]: released right in the middle of the green band (skill, not luck).
	var perfect := false
	if hit != null and hit == target:
		perfect = abs(power * _range() - _flat_distance(target.global_position)) <= GameConfig.HIT_RADIUS * GameConfig.PERFECT_WINDOW

	var proj := Node3D.new()
	add_child(proj)
	var tier := GameState.progress.equipped_tier()
	Blocky.sphere(proj, 0.32, Color(tier.color), Vector3.ZERO)
	Blocky.label3d(proj, fruit, Vector3(0, 0.65, 0), 46)
	var trail := Fx.sparkles(proj, Color(tier.color))
	trail.position = Vector3.ZERO
	trail.local_coords = false
	var start := player.hand_position()
	proj.global_position = start
	var flight: float = clamp(0.45 + power * 0.6, 0.5, 1.1)
	var throw_dist := power * _range()

	# Thrill: whoosh, speed lines, camera chases the fruit, distance counter, slow-motion at the end.
	AudioManager.play("whoosh")
	speed_lines.burst(flight + 0.3)
	_cam_focus = proj
	distance_label.visible = true
	if autoplay:
		_bot_snap_later("25_flight", flight * 0.45)
	var t := create_tween()
	t.tween_method(func(k: float) -> void:
		var end := (hit.global_position + Vector3(0, 1.3, 0)) if hit != null and is_instance_valid(hit) else landing + Vector3(0, 0.3, 0)
		var ctrl := (start + end) / 2.0 + Vector3(0, 2.5 + power * 4.0, 0)
		proj.global_position = start.lerp(ctrl, k).lerp(ctrl.lerp(end, k), k)
		proj.rotation.z = k * TAU * 2.0
		distance_label.text = "%.1f m" % (k * throw_dist)
		if hit != null and k > 0.72:
			Engine.time_scale = 0.4
	, 0.0, 1.0, flight)
	await t.finished
	Engine.time_scale = 1.0
	var dl := create_tween()
	dl.tween_interval(0.8)
	dl.tween_callback(func() -> void: distance_label.visible = false)
	if hit != null and is_instance_valid(hit) and hit.is_wild():
		proj.queue_free()
		AudioManager.play("hit")
		_cam_focus = hit
		if perfect:
			Fx.float_text(self, hit.global_position + Vector3(0, 4.2, 0), Strings.PERFECT, Color("#74c0fc"), 120, 1.8, 1.3)
			AudioManager.play("perfect")
			if autoplay:
				_bot_snap_later("28_perfect", 0.2)
		await _resolve(hit, fruit, perfect)
		_cam_focus = null
	else:
		_cam_focus = null
		# Missed the animal: about aiming, not about d/r, so nothing is logged or counted.
		var short := target != null and is_instance_valid(target) and power * _range() < _flat_distance(target.global_position)
		_show_toast(Strings.TOO_SHORT if short else Strings.TOO_FAR, 1.2)
		AudioManager.play("miss", 1.3)
		await get_tree().create_timer(0.6).timeout
		proj.queue_free()
	_throwing = false   # only now can the next throw start (after the reveal)


func _resolve(target: Animal3D, fruit: String, perfect: bool = false) -> void:
	var was_new := not GameState.progress.has_animal(biome, target.data.get("id", ""))
	var r := session.answer(fruit, target.item, target.data, target.rarity)
	if r.correct and perfect:
		GameState.progress.coins += GameConfig.PERFECT_BONUS
		r.coins = int(r.coins) + GameConfig.PERFECT_BONUS
	SaveManager.log_answer({
		"biome": biome, "item": target.item.get("id", ""), "pair": target.item.get("pair", ""),
		"stage": target.item.get("stage", ""), "chosen": fruit, "correct": r.correct,
		"hint_level": r.hint_level, "animal": target.data.get("id", ""), "rarity": target.rarity,
		"streak": r.streak, "coins": GameState.progress.coins,
		"ms_since_start": Time.get_ticks_msec() - _started_ms, "perfect": perfect,
	})
	# Suspense first ("What did we get?"), then the reveal.
	AudioManager.play("drum")
	if autoplay:
		_bot_snap_later("26_suspense", 0.35)
	await target.suspense(0.75)
	if not is_instance_valid(target):
		return
	if r.correct:
		target.coins_earned = r.coins
		followers.append(target)
		_celebrate(target, r, was_new)
		target.eat(player, followers.size() - 1)
		# Streak bonus: a rare (3 in a row) or golden (6+) animal appears farther away.
		if r.streak >= GameConfig.RARE_STREAK and r.streak % GameConfig.RARE_STREAK == 0:
			var bonus := _spawn_wild(session.next_rarity(), true)
			if bonus != null:
				_show_toast("%s: %s!" % [Strings.RARITY_NAMES[bonus.rarity], bonus.data.get("name", "")], 1.6)
	else:
		AudioManager.play("miss")
		Fx.float_text(self, target.global_position + Vector3(0, 3.2, 0), "?", Color("#ced4da"), 120, 1.2, 1.0)
		var exit := Vector3(target.global_position.x, 0, -MAP_HALF - 4)
		target.sniff(exit)
		_show_hint(target.item, r.hint_level)
	SaveManager.save_game()
	_refresh_hud()
	await get_tree().create_timer(0.9).timeout


## The big reveal after a correct throw. Bigger for rarer animals.
func _celebrate(target: Animal3D, r: Dictionary, was_new: bool) -> void:
	var level := {"common": 0, "rare": 1, "golden": 2}.get(target.rarity, 0) as int
	var col: Color = [Color("#69db7c"), Color("#66d9e8"), Color("#ffd43b")][level]
	var pos := target.global_position
	Fx.beam(self, pos, col, [10.0, 15.0, 22.0][level], [1.2, 1.6, 2.2][level])
	Fx.shockwave(self, pos, col, [5.0, 8.0, 12.0][level])
	Fx.confetti(self, pos + Vector3(0, 1.5, 0), [50, 90, 160][level])
	if level == 2:
		Fx.confetti(self, pos + Vector3(0, 3.0, 0), 120, [Color("#ffd43b"), Color("#fff3bf"), Color("#fab005")])
	target.pop()
	_flash([0.3, 0.5, 0.75][level])
	_shake = [0.35, 0.7, 1.2][level]
	AudioManager.play(["correct", "rare", "golden"][level])
	Fx.float_text(self, pos + Vector3(0, 3.4, 0), "+%d" % r.coins, Color("#ffd43b"), 120, 2.6, 1.4)
	get_tree().create_timer(0.35).timeout.connect(func() -> void: AudioManager.play("coin"))
	_show_catch(target, r, was_new)
	if int(r.streak) >= 2:
		_bump_combo()
		AudioManager.play("combo", 1.0 + 0.06 * min(int(r.streak), 10))
	if autoplay:
		_bot_snap_later("27_reveal" if level == 0 else "27_reveal_%s" % target.rarity, 0.35)


func _flash(strength: float) -> void:
	flash.color.a = strength
	var t := create_tween()
	t.tween_property(flash, "color:a", 0.0, 0.35)


func _bump_combo() -> void:
	combo_label.pivot_offset = combo_label.size / 2.0
	combo_label.scale = Vector2.ONE * 1.8
	var hot: float = clamp(session.streak / 10.0, 0.0, 1.0)
	combo_label.add_theme_color_override("font_color", Color("#ffd43b").lerp(Color("#ff6b6b"), hot))
	var t := create_tween()
	t.tween_property(combo_label, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_arrived_in_pen(a: Animal3D) -> void:
	if a.item.is_empty():
		return
	var d := session.deliver(a.data.get("id", ""), a.rarity)
	a.item = {}
	if d.new_animal or d.new_variant:
		var name: String = a.data.get("name", "")
		if a.rarity != "common":
			name = "%s (%s)" % [name, Strings.RARITY_NAMES[a.rarity]]
		_show_toast(Strings.NEW_FRIEND % name, 1.6)
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

	speed_lines = SpeedLines.new()
	ui.add_child(speed_lines)
	flash = ColorRect.new()
	flash.color = Color(1, 1, 1, 0)
	flash.position = Vector2.ZERO
	flash.size = get_viewport().get_visible_rect().size
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(flash)
	distance_label = UiKit.label("", 64, Color.WHITE, 16)
	distance_label.add_theme_color_override("font_outline_color", Color("#1971c2"))
	distance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	distance_label.size = Vector2(1280, 90)
	distance_label.position = Vector2(0, 380)
	distance_label.visible = false
	ui.add_child(distance_label)

	var back := UiKit.button(Strings.BACK, 24, Color("#495057"))
	back.position = Vector2(16, 14)
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://main/Main.tscn"))
	ui.add_child(back)

	coins_label = UiKit.label("", 32, Color("#ffd43b"), 10)
	coins_label.position = Vector2(170, 22)
	ui.add_child(coins_label)

	follow_label = UiKit.label("", 24, Color.WHITE, 10)
	follow_label.position = Vector2(170, 70)
	ui.add_child(follow_label)

	index_button = UiKit.button("", 24, Color("#1971c2"))
	index_button.position = Vector2(690, 14)
	index_button.pressed.connect(func() -> void: index_page.open(biome))
	ui.add_child(index_button)

	var shop_button := UiKit.button(Strings.SHOP, 24, Color("#e67700"))
	shop_button.position = Vector2(950, 14)
	shop_button.pressed.connect(func() -> void: shop.open())
	ui.add_child(shop_button)

	var lesson := UiKit.button(Strings.LESSON, 24, Color("#0b7285"))
	lesson.position = Vector2(1140, 14)
	lesson.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://ui/Lesson.tscn"))
	ui.add_child(lesson)

	combo_label = UiKit.label("", 44, Color("#ffd43b"), 14)
	combo_label.add_theme_color_override("font_outline_color", Color("#c92a2a"))
	combo_label.position = Vector2(1000, 100)
	ui.add_child(combo_label)
	mult_label = UiKit.label("", 26, Color.WHITE, 10)
	mult_label.position = Vector2(1010, 156)
	ui.add_child(mult_label)

	joystick = Joystick.new()
	joystick.position = Vector2(50, 500)
	ui.add_child(joystick)

	fruit_label = UiKit.label("", 22, Color.WHITE, 8)
	fruit_label.position = Vector2(470, 560)
	ui.add_child(fruit_label)
	var hotbar := HBoxContainer.new()
	hotbar.add_theme_constant_override("separation", 26)
	hotbar.position = Vector2(470, 600)
	ui.add_child(hotbar)
	for i in fruits.size():
		var f := fruits[i]
		var b := UiKit.button(f, 40, WORD_COLORS[i % WORD_COLORS.size()])
		b.custom_minimum_size = Vector2(140, 96)
		b.pivot_offset = b.custom_minimum_size / 2.0
		b.pressed.connect(_select_fruit.bind(f))
		hotbar.add_child(b)
		fruit_buttons[f] = b

	meter = PowerMeter.new()
	meter.position = Vector2(1006, 330)
	ui.add_child(meter)

	throw_button = UiKit.button(Strings.THROW, 36, Color("#e8590c"))
	throw_button.custom_minimum_size = Vector2(170, 170)
	for state in ["normal", "hover", "pressed"]:
		var sb: StyleBoxFlat = throw_button.get_theme_stylebox(state).duplicate()
		sb.set_corner_radius_all(85)
		throw_button.add_theme_stylebox_override(state, sb)
	throw_button.position = Vector2(1080, 520)
	throw_button.button_down.connect(start_charge)
	throw_button.button_up.connect(func() -> void: release_throw())
	ui.add_child(throw_button)
	var hold := UiKit.label(Strings.HOLD_TO_THROW, 18, Color.WHITE, 6)
	hold.position = Vector2(900, 694)
	hold.size = Vector2(360, 24)
	hold.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ui.add_child(hold)

	toast = UiKit.label("", 46, Color.WHITE, 14)
	toast.add_theme_color_override("font_outline_color", Color("#2b8a3e"))
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.size = Vector2(1280, 70)
	toast.position = Vector2(0, 440)
	toast.visible = false
	ui.add_child(toast)

	catch_panel = UiKit.panel(Color("#fff3bf"), 26)
	catch_panel.position = Vector2(290, 96)
	catch_panel.custom_minimum_size = Vector2(700, 0)
	catch_box = VBoxContainer.new()
	catch_box.add_theme_constant_override("separation", 6)
	catch_panel.add_child(catch_box)
	catch_panel.visible = false
	catch_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(catch_panel)

	hint_panel = UiKit.panel()
	hint_panel.position = Vector2(250, 96)
	hint_panel.custom_minimum_size = Vector2(780, 0)
	hint_box = VBoxContainer.new()
	hint_box.add_theme_constant_override("separation", 10)
	hint_panel.add_child(hint_box)
	hint_panel.visible = false
	ui.add_child(hint_panel)

	debug_label = UiKit.label("", 18, Color.WHITE, 6)
	debug_label.position = Vector2(20, 120)
	debug_label.visible = false
	ui.add_child(debug_label)

	index_page = AnimalIndex.new()
	ui.add_child(index_page)
	shop = FruitShop.new()
	shop.changed.connect(_refresh_hud)
	ui.add_child(shop)
	_refresh_hud()


func _refresh_hud() -> void:
	var coins := GameState.progress.coins
	if _shown_coins < 0 or coins < _shown_coins:
		_shown_coins = coins
		coins_label.text = Strings.COINS % coins
	elif coins > _shown_coins:
		# Count up with a bounce, like a coin counter.
		var from := _shown_coins
		_shown_coins = coins
		var t := create_tween()
		t.tween_method(func(v: float) -> void: coins_label.text = Strings.COINS % int(v), float(from), float(coins), 0.6)
		coins_label.pivot_offset = coins_label.size / 2.0
		var b := create_tween()
		b.tween_property(coins_label, "scale", Vector2.ONE * 1.35, 0.12)
		b.tween_property(coins_label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BOUNCE)
	index_button.text = "%s  %d/%d" % [Strings.INDEX, GameState.progress.collected_count(biome), session.animals.size()]
	follow_label.text = "" if followers.is_empty() else "%s   %s" % [Strings.FOLLOWING % followers.size(), Strings.TAKE_HOME]
	var tier := GameState.progress.equipped_tier()
	fruit_label.text = "%s · %s" % [tier.name, Strings.SHOP_RANGE % int(tier.range)]
	combo_label.text = Strings.COMBO % session.streak if session.streak >= 2 else ""
	mult_label.text = Strings.MULTIPLIER % session.multiplier() if session.multiplier() > 1 else ""
	var lines := ["F3 debug (team only)"]
	for s in session.stages:
		lines.append("%s: %d%% of last %d %s" % [s, int(GameState.progress.stage_accuracy(biome, s) * 100),
			GameState.progress.stage_window(biome, s).size(), "OK" if GameState.progress.stage_met(biome, s) else ""])
	lines.append("mode: %s · streak %d" % ["mixed" if session.mixed else "stage %d" % (session.stage_index + 1), session.streak])
	debug_label.text = "\n".join(lines)


## "NAHULI MO!" popup after a correct throw: animal, rarity, the whole sentence, coins.
func _show_catch(a: Animal3D, r: Dictionary, was_new: bool = false) -> void:
	_popup_token += 1
	var token := _popup_token
	hint_panel.visible = false
	for c in catch_box.get_children():
		catch_box.remove_child(c)
		c.queue_free()
	var colors := {"common": Color("#2b8a3e"), "rare": Color("#1098ad"), "golden": Color("#e67700")}
	var title_text := Strings.CAUGHT
	if a.rarity != "common":
		title_text = Strings.RARE_CATCH[a.rarity]
	var title := UiKit.label(title_text, 48, colors.get(a.rarity, Color("#2b8a3e")), 6)
	title.add_theme_color_override("font_outline_color", Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	catch_box.add_child(title)
	if was_new:
		var badge := UiKit.label(Strings.NEW_BADGE, 30, Color.WHITE, 10)
		badge.add_theme_color_override("font_outline_color", Color("#e03131"))
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		catch_box.add_child(badge)
	var who := UiKit.label("%s  ·  %s" % [a.data.get("name", ""), Strings.RARITY_NAMES.get(a.rarity, "")], 32, UiKit.INK)
	who.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	catch_box.add_child(who)
	var s := UiKit.rich(34, 650)
	s.text = "[center]%s[/center]" % Hints.highlighted_sentence(a.item, "[color=#2b8a3e][b]%s[/b][/color]" % a.item.answer)
	catch_box.add_child(s)
	var coins := "+%d barya" % r.coins
	if int(r.multiplier) > 1:
		coins += "   (%s)" % (Strings.MULTIPLIER % r.multiplier)
	var cl := UiKit.label(coins, 30, Color("#e67700"))
	cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	catch_box.add_child(cl)
	catch_panel.visible = true
	catch_panel.reset_size()
	# Pop in with a bounce.
	catch_panel.pivot_offset = Vector2(350, 120)
	catch_panel.scale = Vector2.ONE * 0.3
	var pop := create_tween()
	pop.tween_property(catch_panel, "scale", Vector2.ONE * 1.08, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_property(catch_panel, "scale", Vector2.ONE, 0.12)
	catch_panel.call_deferred("reset_size")
	if autoplay:
		_bot_snap_later("20_catch" if a.rarity == "common" else "22_catch_rare", 0.25)
		if session.streak >= GameConfig.RARE_STREAK:
			_bot_snap_later("21_combo", 0.3)
	await get_tree().create_timer(2.4).timeout
	if token == _popup_token:
		catch_panel.visible = false


## Non-blocking hint: the game keeps running. Level 2 = worked example.
func _show_hint(item: Dictionary, level: int) -> void:
	_hint_token += 1
	var token := _hint_token
	catch_panel.visible = false
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
	if _bot_done or _charging or _throwing:
		return
	if Time.get_ticks_msec() - _started_ms > 200000:
		_finish_autoplay()
		return
	if not _snapped.has("12_world") and _bot_wait <= 1.0:
		_bot_snap_later("12_world", 0.0)
	if _bot_wait > 0.0:
		_bot_wait -= delta
		return
	# Visit the shop once there are enough coins.
	if not _bot_bought and GameState.progress.coins >= int(GameConfig.FRUIT_TIERS[1].price):
		_bot_bought = true
		_bot_shop()
		_bot_wait = 2.5
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
	var target := _bot_target()
	if target == null:
		return
	var d := target.global_position - player.global_position
	d.y = 0
	var shy: float = GameConfig.RARITY_SHY_DISTANCE.get(target.rarity, 3.0)
	var want: float = min(shy + 2.0, _range() * 0.85)
	if DebugTools.has_arg("--trace") and Engine.get_process_frames() % 120 == 0:
		print("BOT throws=%d target=%s rarity=%s dist=%.1f want=%.1f player=%s" % [_bot_throws, target.data.id, target.rarity, d.length(), want, player.global_position])
	if d.length() > want + 1.5:
		_bot_dir = d.normalized()
		return
	player.facing = d.normalized()
	player.move(Vector3.ZERO, 0.016)
	_aim = target
	_select_fruit(_bot_choice(target))
	_bot_throw(target)
	_bot_wait = 2.8


## Prefers rare/golden animals so they show up in the check.
func _bot_target() -> Animal3D:
	var best: Animal3D = null
	var best_d := INF
	for a in animals:
		if a.is_wild():
			var dist := _flat_distance(a.global_position) - (50.0 if a.rarity != "common" else 0.0)
			if dist < best_d:
				best_d = dist
				best = a
	return best


func _bot_throw(target: Animal3D) -> void:
	_bot_throws += 1
	start_charge()
	if target.rarity != "common":
		_bot_snap_later("22_rare_aim", 0.2)
	await get_tree().create_timer(0.7).timeout
	_bot_snap_later("19_meter", 0.0)
	await get_tree().create_timer(0.1).timeout
	var needed: float = _flat_distance(target.global_position) / _range() if is_instance_valid(target) else 0.5
	if _bot_throws == 4 and not _snapped.has("24_too_short"):
		_snapped["24_too_short"] = true
		release_throw(needed * 0.4)   # one weak throw, to show "Kulang ang lakas!"
		_bot_throws -= 1               # an aim miss is not a d/r answer
		await get_tree().create_timer(0.9).timeout
		await DebugTools.snap(self, "24_too_short")
	else:
		release_throw(clamp(needed + randf_range(-0.06, 0.06), 0.05, 1.0))   # like a child: near, not exact


func _bot_shop() -> void:
	shop.open()
	await get_tree().create_timer(0.3).timeout
	await _bot_snap_later("23_shop", 0.0)
	shop.buy(GameConfig.FRUIT_TIERS[1].id)
	await get_tree().create_timer(0.3).timeout
	shop.visible = false


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
	print("AUTOPLAY 3D: throws=%d coins=%d animals=%d/%d streak=%d fruit=%s variants=%s misses=%s shots=%s" % [
		_bot_throws, GameState.progress.coins, GameState.progress.collected_count(biome), session.animals.size(),
		session.streak, GameState.progress.equipped_fruit, GameState.progress.variants.get(biome, {}),
		session.misses, _snapped.keys()])
	get_tree().quit()
