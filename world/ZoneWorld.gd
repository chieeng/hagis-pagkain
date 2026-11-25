class_name ZoneWorld
extends Node3D
## A 3D zone behind a portal [redesign 2026-11-25, docs/superpowers/specs]. Owner: Lead.
##
## Loop:
##   - Walk a winding path. Word tiles (din, rin, ...) lie near the path; walk over to collect.
##   - The path is blocked by stations (a broken bridge over water, a locked gate). Each
##     station has slots; each slot is one sentence with a blank from BiomeSession. The
##     sign carries the previous word with its deciding letter glowing (fades with mastery).
##   - Stand near a slot and tap a pouch word to place it. Right: the plank/bar is built
##     with the word on it. Wrong: the tile pops back, the letter hint shows (worked example
##     on the second wrong of the same sentence), the tile returns to the pouch. No fail.
##   - All slots solved: the cage opens, the animal joins the Index and follows you, the
##     invisible wall drops, the journey continues. Rare/golden animals come from streaks.
##   - Only the FIRST placement in a slot is an answer (session.answer); retries are checked
##     against DRRule and logged as "retry", so first-placement accuracy stays clean.
## Logic: core/BiomeSession.gd + core/Progress.gd (unit-tested). This script only shows it.

@export var biome: String = "forest"

const MAP_HALF := 26.0
const CAMERA_OFFSET := Vector3(0, 12, 9.5)
const FIRST_STATION_Z := -14.0
const AHEAD := 2                ## stations kept built ahead of the player
const AUTOPLAY_RESCUES := 4

const THEMES := {
	"forest": {"sky_top": "#4dabf7", "sky_horizon": "#d0ebff", "ground": "#51cf66",
		"tree_a": "#2f9e44", "tree_b": "#40c057", "trunk": "#8d5a3b", "hedge": "#2b8a3e", "water": "#339af0"},
	"river": {"sky_top": "#3bc9db", "sky_horizon": "#e3fafc", "ground": "#8ce99a",
		"tree_a": "#2f9e44", "tree_b": "#63e6be", "trunk": "#a07850", "hedge": "#0ca678", "water": "#15aabf"},
	"mountain": {"sky_top": "#748ffc", "sky_horizon": "#e5dbff", "ground": "#a9b388",
		"tree_a": "#5c940d", "tree_b": "#868e96", "trunk": "#6f4e37", "hedge": "#495057", "water": "#4dabf7"},
	"sky": {"sky_top": "#5f3dc4", "sky_horizon": "#d0ebff", "ground": "#91a7ff",
		"tree_a": "#f8f9fa", "tree_b": "#e599f7", "trunk": "#b197fc", "hedge": "#845ef7", "water": "#dbe4ff"},
	"island": {"sky_top": "#22b8cf", "sky_horizon": "#fff9db", "ground": "#ffe8a1",
		"tree_a": "#37b24d", "tree_b": "#94d82d", "trunk": "#b08968", "hedge": "#1098ad", "water": "#15aabf"},
}

var session: BiomeSession
var player: Player3D
var camera: Camera3D
var stations: Array[Dictionary] = []
var tiles: Array[Node3D] = []
var pouch: Dictionary = {}          ## word -> count
var followers: Array[Node3D] = []
var _next_station := 0
var _active_slot: Dictionary = {}
var _tts_voice := ""
var _banner_item_id := ""
var _hint_token := 0
var _popup_token := 0
var _intro_token := 0
var _shake := 0.0
var _shown_coins := -1
var _started_ms := 0
var first_attempts := 0

# HUD
var ui: CanvasLayer
var joystick: Joystick
var coins_label: Label
var quest_label: Label
var combo_label: Label
var mult_label: Label
var index_button: Button
var toast: Label
var hint_panel: PanelContainer
var hint_box: VBoxContainer
var catch_panel: PanelContainer
var catch_box: VBoxContainer
var intro_panel: PanelContainer
var intro_box: VBoxContainer
var index_page: AnimalIndex
var shop: FruitShop
var debug_label: Label
var flash: ColorRect
var sentence_banner: PanelContainer
var sentence_label: RichTextLabel
var listen_button: Button
var pouch_box: HBoxContainer
var pouch_buttons: Dictionary = {}

# Autoplay
var autoplay := DebugTools.has_arg("--autoplay")
var _bot_dir := Vector3.ZERO
var _bot_wait := 1.2
var _bot_done := false
var _bot_bought := false
var _bot_missed_slots := 0
var _snapped := {}


func _theme() -> Dictionary:
	return THEMES.get(biome, THEMES["forest"])


func _ready() -> void:
	_started_ms = Time.get_ticks_msec()
	session = BiomeSession.new(biome, QuestionBank.get_items(biome), QuestionBank.get_animals(biome),
		GameState.progress, -1, QuestionBank.get_review_items(biome, GameState.BIOME_ORDER))
	_build_environment()
	_build_ground()
	player = Player3D.new()
	add_child(player)
	player.global_position = Vector3(_path_x(6.0), 0, 6.0)
	camera = Camera3D.new()
	camera.fov = 55
	add_child(camera)
	camera.current = true
	_place_camera(1.0)
	_build_ui()
	_tts_voice = _find_voice()
	listen_button.visible = _tts_voice != ""
	if session.items.is_empty():
		_show_toast(Strings.NO_ITEMS, 999.0)
		return
	for i in AHEAD:
		_spawn_station()
	_refresh_hud()


func _path_x(z: float) -> float:
	return sin(z * 0.07) * 6.0


func _slot_count() -> int:
	return GameConfig.SLOTS_FOREST if biome in ["forest", "river", "island"] else GameConfig.SLOTS_LATER


# ---------------------------------------------------------------- world building

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(_theme().sky_top)
	sky_mat.sky_horizon_color = Color(_theme().sky_horizon)
	sky_mat.ground_horizon_color = Color(_theme().sky_horizon)
	sky_mat.ground_bottom_color = Color(_theme().ground).lightened(0.15)
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.74, 0.69, 0.60)
	env.ambient_light_energy = 0.5
	var we := WorldEnvironment.new()
	we.environment = env
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.light_color = Color("#fff1cf")
	sun.light_energy = 0.85
	sun.shadow_enabled = true
	add_child(we)
	add_child(sun)


## The ground is endless along -z: big tiles are added under each new station segment.
var _ground_to_z := 40.0


func _build_ground() -> void:
	_extend_ground(-80.0)


func _extend_ground(to_z: float) -> void:
	while _ground_to_z > to_z:
		var g := MeshInstance3D.new()
		var p := PlaneMesh.new()
		p.size = Vector2(MAP_HALF * 2 + 70, 42.0)
		g.mesh = p
		g.material_override = Blocky.material(Color(_theme().ground))
		g.position = Vector3(0, 0, _ground_to_z - 21.0)
		add_child(g)
		_decorate_segment(_ground_to_z - 42.0, _ground_to_z)
		_ground_to_z -= 40.0


func _decorate_segment(z_from: float, z_to: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(absf(z_from)) * 7 + biome.length()
	# stone path
	var z := z_to
	while z > z_from:
		Blocky.box(self, Vector3(2.2, 0.06, 1.1),
			Color("#dee2e6").lerp(Color("#adb5bd"), rng.randf()), Vector3(_path_x(z) + rng.randf_range(-0.3, 0.3), 0.03, z))
		z -= 1.5
	# trees and scatter
	for i in 10:
		var p := Vector3(rng.randf_range(-MAP_HALF, MAP_HALF), 0, rng.randf_range(z_from, z_to))
		if absf(p.x - _path_x(p.z)) > 4.5:
			_tree(p, rng)
	for i in 16:
		var p := Vector3(rng.randf_range(-MAP_HALF, MAP_HALF), 0, rng.randf_range(z_from, z_to))
		var c: Color = [Color("#ffd43b"), Color("#f783ac"), Color("#ffffff"), Color("#868e96")][rng.randi() % 4]
		Blocky.box(self, Vector3(0.25, 0.25, 0.25), c, p + Vector3(0, 0.12, 0))
	# hedges on both sides, far silhouettes with aerial perspective (STYLE.md)
	var horizon := Color(_theme().sky_horizon)
	var base := Color(_theme().hedge)
	z = z_to
	while z > z_from:
		for side in [-1.0, 1.0]:
			Blocky.box(self, Vector3(1.5, 1.4, 3), base, Vector3(side * (MAP_HALF + 2.0), 0.7, z))
			var h := rng.randf_range(4.0, 9.0)
			Blocky.box(self, Vector3(4.0, h, rng.randf_range(6.0, 11.0)),
				base.lerp(horizon, 0.6), Vector3(side * (MAP_HALF + 12.0), h / 2.0, z))
		z -= 4.0


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
	Blocky.box(t, Vector3(0.6, h, 0.6), Color(_theme().trunk), Vector3(0, h / 2.0, 0))
	var g := Color(_theme().tree_a).lerp(Color(_theme().tree_b), rng.randf())
	Blocky.box(t, Vector3(2.6, 1.6, 2.6), g, Vector3(0, h + 0.7, 0))
	Blocky.box(t, Vector3(1.7, 1.2, 1.7), g.lightened(0.12), Vector3(0, h + 1.9, 0))


# ---------------------------------------------------------------- stations

## Builds the next station down the path: obstacle + slots + tiles + caged animal + wall.
func _spawn_station() -> void:
	var idx := _next_station
	_next_station += 1
	var z := FIRST_STATION_Z - idx * GameConfig.STATION_GAP
	_extend_ground(z - GameConfig.STATION_GAP - 20.0)
	var cx := _path_x(z)
	var kind := "bridge" if idx % 2 == 0 else "gate"
	var rarity := session.next_rarity()
	var busy_items: Array = []
	var busy_animals: Array = []
	for st in stations:
		if not st.complete:
			busy_animals.append(st.animal_id)
			for sl in st.slots:
				busy_items.append(sl.item.get("id", ""))
	var slots: Array = []
	var animal_data: Dictionary = {}
	for s in _slot_count():
		var item := session.next_sentence(busy_animals, busy_items)
		if item.is_empty():
			break
		if animal_data.is_empty():
			animal_data = session.current_animal
		busy_items.append(item.get("id", ""))
		slots.append({"item": item, "choices": session.current_choices.duplicate(), "solved": false,
			"attempted": false, "wrongs": 0, "pos": Vector3.ZERO, "sign": null, "end_label": null, "spot": null})
	if slots.is_empty():
		return
	var station := {"index": idx, "z": z, "cx": cx, "kind": kind, "slots": slots, "complete": false, "stand_z": z,
		"animal_id": animal_data.get("id", ""), "animal_data": animal_data, "rarity": rarity,
		"animal": null, "cage": null, "wall": null, "nodes": []}
	_build_obstacle(station)   # sets station.stand_z
	_spawn_tiles(station)
	stations.append(station)


func _build_obstacle(st: Dictionary) -> void:
	var z: float = st.z
	var cx: float = st.cx
	var n: int = st.slots.size()
	if st.kind == "bridge":
		var water := MeshInstance3D.new()
		var wp := PlaneMesh.new()
		wp.size = Vector2(MAP_HALF * 2 + 70, 3.2 * n + 3.0)
		water.mesh = wp
		water.material_override = Blocky.material(Color(_theme().water))
		water.position = Vector3(0, 0.05, z)
		add_child(water)
		for x_off in [-1.7, 1.7]:
			Blocky.box(self, Vector3(0.25, 0.25, 3.2 * n + 4.0), Color("#a0522d"), Vector3(cx + x_off, 0.9, z))
			for z_end in [z - (1.6 * n + 1.6), z + (1.6 * n + 1.6)]:
				Blocky.box(self, Vector3(0.3, 1.0, 0.3), Color("#8d5a3b"), Vector3(cx + x_off, 0.45, z_end))
	else:
		# a locked gate: a fence across the path with missing bars
		for side in [-1.0, 1.0]:
			var seg_len := MAP_HALF
			Blocky.box(self, Vector3(seg_len, 1.6, 0.4), Color(_theme().trunk),
				Vector3(cx + side * (seg_len / 2.0 + 1.3 * n + 0.6), 0.8, z))
		var half := 1.3 * n + 0.6
		Blocky.box(self, Vector3(0.4, 2.6, 0.4), Color("#6f4e37"), Vector3(cx - half, 1.3, z))
		Blocky.box(self, Vector3(0.4, 2.6, 0.4), Color("#6f4e37"), Vector3(cx + half, 1.3, z))
	# slots along the crossing, one behind the other
	for i in n:
		var slot: Dictionary = st.slots[i]
		var sz := z + (1.6 * (n - 1)) - i * 3.2 if st.kind == "bridge" else z
		var spot_pos := Vector3(cx, 0, sz) if st.kind == "bridge" else Vector3(cx - 1.3 * (n - 1) + i * 2.6, 0, z)
		slot.pos = spot_pos
		var gap := Blocky.box(self, Vector3(2.9, 0.08, 2.6) if st.kind == "bridge" else Vector3(1.0, 2.2, 0.25),
			Color("#1864ab") if st.kind == "bridge" else Color("#343a40"),
			spot_pos + (Vector3(0, 0.04, 0) if st.kind == "bridge" else Vector3(0, 1.1, 0)))
		slot.spot = gap
		# the sign: previous word with the deciding letter glowing in its fruit's colour
		var sign := Node3D.new()
		add_child(sign)
		# bridge signs stand on the bank beside each plank; gate signs stand right in front of each bar
		sign.global_position = spot_pos + (Vector3(-3.6, 0, 1.0) if st.kind == "bridge" else Vector3(0, 0, 1.6))
		Blocky.box(sign, Vector3(0.22, 1.5, 0.22), Color("#8d5a3b"), Vector3(0, 0.75, 0))
		Blocky.box(sign, Vector3(2.5, 1.15, 0.15), Color("#fff9db"), Vector3(0, 1.95, 0))
		var word := str(slot.item.get("prev_word", ""))
		var nn: int = mini(DRRule.deciding_length(word), word.length())
		var stem := Blocky.label3d(sign, word.left(word.length() - nn), Vector3(-0.2, 2.1, 0.12), 56, Color("#212529"))
		stem.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		var endl := Blocky.label3d(sign, word.right(nn), Vector3(0.28, 2.14, 0.12), 76, Color("#212529"))
		endl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		Blocky.label3d(sign, "___", Vector3(0, 1.55, 0.12), 40, Color("#868e96"))
		slot.sign = sign
		slot.end_label = endl
		st.nodes.append(sign)
		_refresh_slot_glow(slot)
	# invisible wall until solved
	var wall := StaticBody3D.new()
	add_child(wall)
	var ws := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(MAP_HALF * 2 + 20, 4, 1.0)
	ws.shape = box
	ws.position = Vector3(0, 2, 0)
	wall.add_child(ws)
	# the wall stands at the near edge of the crossing, so every slot is reachable from it
	var wall_z: float = z + (1.6 * n + 2.2) if st.kind == "bridge" else z + 0.4
	wall.global_position = Vector3(0, 0, wall_z)
	st.wall = wall
	st.stand_z = wall_z + 1.2
	# the caged animal past the obstacle
	var beyond := Vector3(_path_x(z - 7.0), 0, z - 7.0)
	var animal := _mini_animal(beyond, st.animal_data, st.rarity)
	st.animal = animal
	var cage := Node3D.new()
	add_child(cage)
	cage.global_position = beyond
	for ang in 8:
		var a := TAU * ang / 8.0
		Blocky.box(cage, Vector3(0.14, 2.4, 0.14), Color("#495057"), Vector3(cos(a) * 1.5, 1.2, sin(a) * 1.5))
	Blocky.box(cage, Vector3(3.4, 0.14, 3.4), Color("#495057"), Vector3(0, 2.4, 0))
	st.cage = cage
	Blocky.label3d(cage, Strings.TRAPPED, Vector3(0, 3.6, 0), 52, Color("#ffe066"))


func _mini_animal(pos: Vector3, data: Dictionary, rarity: String) -> Node3D:
	var a := Node3D.new()
	add_child(a)
	a.global_position = pos
	var color := Color(data.get("color", "#c08552"))
	if rarity == "golden":
		color = color.lerp(Color("#ffd43b"), 0.75)
	var model := Node3D.new()
	a.add_child(model)
	model.name = "Model"
	model.scale = Vector3.ONE * {"common": 1.0, "rare": 1.2, "golden": 1.4}.get(rarity, 1.0)
	Blocky.box(model, Vector3(0.9, 0.7, 1.2), color, Vector3(0, 0.75, 0))
	Blocky.box(model, Vector3(0.75, 0.7, 0.7), color.lightened(0.08), Vector3(0, 1.3, 0.6))
	Blocky.box(model, Vector3(0.14, 0.14, 0.05), Color.WHITE, Vector3(-0.17, 1.4, 0.96))
	Blocky.box(model, Vector3(0.14, 0.14, 0.05), Color.WHITE, Vector3(0.17, 1.4, 0.96))
	Blocky.box(model, Vector3(0.07, 0.08, 0.04), Color("#1b1b1b"), Vector3(-0.17, 1.39, 0.99))
	Blocky.box(model, Vector3(0.07, 0.08, 0.04), Color("#1b1b1b"), Vector3(0.17, 1.39, 0.99))
	for x in [-0.3, 0.3]:
		for zz in [-0.4, 0.4]:
			Blocky.box(model, Vector3(0.2, 0.45, 0.2), color.darkened(0.25), Vector3(x, 0.22, zz))
	var tag := Blocky.label3d(a, str(data.get("name", "")), Vector3(0, 2.5, 0), 48, Color("#ffe066"))
	tag.name = "Tag"
	if rarity != "common":
		Blocky.label3d(a, Strings.RARITY_NAMES.get(rarity, ""), Vector3(0, 3.1, 0), 56,
			Color("#99e9f2") if rarity == "rare" else Color("#ffd43b"))
		var glow := Color("#66d9e8") if rarity == "rare" else Color("#fcc419")
		Fx.sparkles(a, glow).name = "Sparkles"
		Fx.pillar(a, glow).name = "Pillar"
	return a


func _spawn_tiles(st: Dictionary) -> void:
	var words := {}
	for slot in st.slots:
		for w in slot.choices:
			words[w] = int(words.get(w, 0)) + 1
	var rng := RandomNumberGenerator.new()
	rng.seed = st.index * 31 + 7
	# tiles lie on the near side of the wall, in the walk up to this station
	var near: float = float(st.stand_z) + 1.0
	for w in words:
		for i in words[w]:
			var z: float = near + rng.randf_range(0.0, GameConfig.STATION_GAP * 0.6)
			var p := Vector3(_path_x(z) + rng.randf_range(-9.0, 9.0), 0, z)
			tiles.append(_tile(p, str(w)))


func _tile(pos: Vector3, word: String) -> Node3D:
	var t := Node3D.new()
	add_child(t)
	t.global_position = pos
	t.set_meta("word", word)
	var col := _word_color(word)
	var box := Blocky.box(t, Vector3(0.9, 0.9, 0.9), col, Vector3(0, 0.55, 0))
	box.material_override = Fx.glow_material(col, 0.9)
	Blocky.label3d(t, word, Vector3(0, 1.7, 0), 72, Color.WHITE)
	var tw := t.create_tween().set_loops()
	tw.tween_property(t, "position:y", 0.3, 0.7).set_trans(Tween.TRANS_SINE)
	tw.tween_property(t, "position:y", 0.0, 0.7).set_trans(Tween.TRANS_SINE)
	return t


static func _word_color(word: String) -> Color:
	return Color(GameConfig.R_COLOR if word.begins_with("r") else GameConfig.D_COLOR)


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
	var speed: float = float(GameState.progress.equipped_tier().get("speed", 1.0))
	player.move(dir.limit_length(1.0) * speed, delta)
	player.global_position.x = clamp(player.global_position.x, -MAP_HALF, MAP_HALF)
	player.global_position.z = minf(player.global_position.z, 12.0)
	_place_camera(delta * 5.0)
	_collect_tiles()
	_update_active_slot()
	_followers(delta)
	if stations.is_empty() or (_stations_incomplete() < AHEAD and not session.items.is_empty()):
		_spawn_station()


func _stations_incomplete() -> int:
	var n := 0
	for st in stations:
		if not st.complete:
			n += 1
	return n


func _place_camera(weight: float) -> void:
	var want := player.global_position + CAMERA_OFFSET
	camera.global_position = camera.global_position.lerp(want, clamp(weight, 0.0, 1.0))
	camera.look_at(camera.global_position - CAMERA_OFFSET + Vector3(0, 1, 0))
	if _shake > 0.01:
		camera.global_position += Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * _shake * 0.35
		_shake = move_toward(_shake, 0.0, get_process_delta_time() * 2.5)


func _collect_tiles() -> void:
	for i in range(tiles.size() - 1, -1, -1):
		var t := tiles[i]
		if not is_instance_valid(t):
			tiles.remove_at(i)
			continue
		var d := t.global_position - player.global_position
		d.y = 0
		if d.length() <= GameConfig.TILE_PICKUP:
			var word := str(t.get_meta("word"))
			pouch[word] = int(pouch.get(word, 0)) + 1
			AudioManager.play("coin")
			Fx.float_text(self, t.global_position + Vector3(0, 2.0, 0), word, _word_color(word).lightened(0.3), 100, 1.8, 0.9)
			t.queue_free()
			tiles.remove_at(i)
			_refresh_pouch()


func _followers(_delta: float) -> void:
	for i in followers.size():
		var f := followers[i]
		if not is_instance_valid(f):
			continue
		var behind := player.global_position - player.facing * (1.8 + i * 1.5)
		f.global_position = f.global_position.lerp(Vector3(behind.x, 0, behind.z), 0.08)
		var model := f.get_node_or_null("Model")
		if model != null:
			model.position.y = absf(sin(Time.get_ticks_msec() * 0.012)) * 0.12


## The nearest unsolved slot in range drives the banner, the TTS and the pouch's target.
func _update_active_slot() -> void:
	var best: Dictionary = {}
	var best_d := GameConfig.SLOT_RANGE
	for st in stations:
		if st.complete:
			continue
		for slot in st.slots:
			if slot.solved:
				continue
			var d: Vector3 = slot.pos - player.global_position
			d.y = 0
			if d.length() < best_d:
				best_d = d.length()
				best = slot
	if best.is_empty():
		_active_slot = {}
		if not catch_panel.visible:
			sentence_banner.visible = false
		_banner_item_id = ""
		return
	if _active_slot != best or not sentence_banner.visible:
		_active_slot = best
		if not catch_panel.visible and not hint_panel.visible:
			_show_banner(best)
	var item: Dictionary = best.item
	if item.get("id", "") != _banner_item_id:
		_banner_item_id = item.get("id", "")
		_speak(item)
		_introduce_stage(item)


func _show_banner(slot: Dictionary) -> void:
	sentence_label.text = "[center]%s[/center]" % str(slot.item.get("sentence", "")).replace("___", "[color=#868e96]_____[/color]")
	sentence_banner.visible = true
	sentence_banner.reset_size()


# ---------------------------------------------------------------- placing words

## Tap a pouch word: the tile flies to the active slot and the answer is judged.
func place_word(word: String) -> void:
	if _active_slot.is_empty():
		_show_toast(Strings.GO_NEAR_SLOT)
		return
	if int(pouch.get(word, 0)) <= 0:
		return
	var slot: Dictionary = _active_slot
	pouch[word] = int(pouch[word]) - 1
	_refresh_pouch()
	await _resolve(slot, word)


func _resolve(slot: Dictionary, word: String) -> void:
	var st := _station_of(slot)
	var item: Dictionary = slot.item
	var correct: bool
	var r: Dictionary = {}
	if not slot.attempted:
		# the FIRST placement is the answer: windows, pair stats, coins, streak, glow
		slot.attempted = true
		first_attempts += 1
		r = session.answer(word, item, st.animal_data, st.rarity)
		correct = r.correct
		SaveManager.log_answer({"event": "answer", "biome": biome, "item": item.get("id", ""),
			"pair": item.get("pair", ""), "stage": item.get("stage", ""), "chosen": word,
			"correct": correct, "hint_level": r.get("hint_level", 0), "animal": st.animal_id,
			"rarity": st.rarity, "streak": r.get("streak", 0), "coins": GameState.progress.coins,
			"ms_since_start": Time.get_ticks_msec() - _started_ms})
	else:
		correct = DRRule.is_preferred(str(item.get("prev_word", "")), word)
		SaveManager.log_answer({"event": "retry", "biome": biome, "item": item.get("id", ""),
			"pair": item.get("pair", ""), "stage": item.get("stage", ""), "chosen": word,
			"correct": correct, "ms_since_start": Time.get_ticks_msec() - _started_ms})
	# the tile flies from the player to the slot
	var fly := Node3D.new()
	add_child(fly)
	var col := _word_color(word)
	Blocky.box(fly, Vector3(0.9, 0.9, 0.9), col, Vector3.ZERO).material_override = Fx.glow_material(col, 0.95)
	Blocky.label3d(fly, word, Vector3(0, 1.0, 0), 66, Color.WHITE)
	fly.global_position = player.global_position + Vector3(0, 1.4, 0)
	var to: Vector3 = slot.pos + Vector3(0, 0.6, 0)
	var tw := create_tween()
	tw.tween_property(fly, "global_position", to, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	if correct:
		fly.queue_free()
		_build_plank(st, slot, word)
		slot.solved = true
		if not r.is_empty():
			_celebrate_slot(slot, r)
		else:
			AudioManager.play("correct")
			Fx.shockwave(self, slot.pos, col, 4.0)
		sentence_label.text = "[center]%s[/center]" % str(item.get("sentence", "")).replace("___", "[b][color=#2b8a3e]%s[/color][/b]" % word)
		sentence_banner.reset_size()
		_refresh_all_glows()
		SaveManager.save_game()
		_refresh_hud()
		var done := true
		for s2 in st.slots:
			if not s2.solved:
				done = false
		if done:
			await get_tree().create_timer(0.6).timeout
			await _complete_station(st)
	else:
		slot.wrongs = int(slot.wrongs) + 1
		AudioManager.play("miss")
		var back := player.global_position + Vector3(0, 1.4, 0)
		var tb := create_tween()
		tb.tween_property(fly, "global_position", to + Vector3(0, 1.6, 0), 0.18)
		tb.tween_property(fly, "global_position", back, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await tb.finished
		fly.queue_free()
		pouch[word] = int(pouch.get(word, 0)) + 1   # the tile comes back: no loss, try again
		_refresh_pouch()
		_blink_sign(slot)
		_show_hint(item, mini(int(slot.wrongs), 2))
		_refresh_all_glows()
		_refresh_hud()


func _station_of(slot: Dictionary) -> Dictionary:
	for st in stations:
		if slot in st.slots:
			return st
	return {}


func _build_plank(st: Dictionary, slot: Dictionary, word: String) -> void:
	if is_instance_valid(slot.spot):
		(slot.spot as Node3D).queue_free()
	var pos: Vector3 = slot.pos
	var plank: MeshInstance3D
	if st.kind == "bridge":
		plank = Blocky.box(self, Vector3(2.9, 0.3, 2.4), Color("#d9a05b"), pos + Vector3(0, 0.3, 0))
		Blocky.label3d(self, word, pos + Vector3(0, 0.75, 0), 64, Color.WHITE)
	else:
		plank = Blocky.box(self, Vector3(1.0, 2.2, 0.25), _word_color(word), pos + Vector3(0, 1.1, 0))
		Blocky.label3d(self, word, pos + Vector3(0, 2.6, 0), 64, Color.WHITE)
	plank.scale = Vector3.ONE * 0.2
	create_tween().tween_property(plank, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _celebrate_slot(slot: Dictionary, r: Dictionary) -> void:
	AudioManager.play("correct")
	Fx.shockwave(self, slot.pos, Color("#69db7c"), 4.5)
	Fx.confetti(self, slot.pos + Vector3(0, 1.2, 0), 50)
	if int(r.get("coins", 0)) > 0:
		Fx.float_text(self, slot.pos + Vector3(0, 2.6, 0), "+%d" % r.coins, Color("#ffd43b"), 100, 2.2, 1.2)
	if int(r.get("streak", 0)) >= 2:
		_bump_combo()
		AudioManager.play("combo", 1.0 + 0.06 * mini(int(r.streak), 10))
	if autoplay:
		_bot_snap_later("20_plank", 0.25)


func _complete_station(st: Dictionary) -> void:
	st.complete = true
	if is_instance_valid(st.wall):
		(st.wall as Node3D).queue_free()
	# the cage opens: bars rise and fade
	var cage: Node3D = st.cage
	if is_instance_valid(cage):
		var tw := create_tween()
		tw.tween_property(cage, "position:y", 4.0, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(func() -> void: cage.queue_free())
	var d := session.deliver(st.animal_id, st.rarity)
	var animal: Node3D = st.animal
	var level := {"common": 0, "rare": 1, "golden": 2}.get(st.rarity, 0) as int
	var col: Color = [Color("#69db7c"), Color("#66d9e8"), Color("#ffd43b")][level]
	var pos: Vector3 = animal.global_position if is_instance_valid(animal) else player.global_position
	Fx.beam(self, pos, col, [10.0, 15.0, 22.0][level], [1.2, 1.6, 2.2][level])
	Fx.shockwave(self, pos, col, [5.0, 8.0, 12.0][level])
	Fx.confetti(self, pos + Vector3(0, 1.5, 0), [60, 100, 160][level])
	_flash([0.3, 0.5, 0.75][level])
	_shake = [0.35, 0.7, 1.2][level]
	AudioManager.play(["correct", "rare", "golden"][level])
	if is_instance_valid(animal):
		var pillar := animal.get_node_or_null("Pillar")
		if pillar != null:
			pillar.queue_free()
		followers.append(animal)
	_show_rescue(st, d)
	SaveManager.save_game()
	_refresh_hud()
	if d.cleared:
		var opened := GameState.unlock_next(biome)
		if opened != "":
			_show_toast(Strings.UNLOCKED % GameState.BIOME_NAMES.get(opened, opened), 2.5)
	if autoplay:
		_bot_snap_later("22_rescue" if st.rarity == "common" else "23_rescue_%s" % st.rarity, 0.35)


func _show_rescue(st: Dictionary, d: Dictionary) -> void:
	_popup_token += 1
	var token := _popup_token
	hint_panel.visible = false
	sentence_banner.visible = false
	for c in catch_box.get_children():
		catch_box.remove_child(c)
		c.queue_free()
	var colors := {"common": Color("#2b8a3e"), "rare": Color("#1098ad"), "golden": Color("#e67700")}
	var title_text: String = Strings.RESCUED if st.rarity == "common" else Strings.RARE_RESCUE[st.rarity]
	var title := UiKit.label(title_text, 48, colors.get(st.rarity, Color("#2b8a3e")), 6)
	title.add_theme_color_override("font_outline_color", Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	catch_box.add_child(title)
	if d.new_animal:
		var badge := UiKit.label(Strings.NEW_BADGE, 30, Color.WHITE, 10)
		badge.add_theme_color_override("font_outline_color", Color("#e03131"))
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		catch_box.add_child(badge)
	var who := UiKit.label("%s  ·  %s" % [st.animal_data.get("name", ""), Strings.RARITY_NAMES.get(st.rarity, "")], 32, UiKit.INK)
	who.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	catch_box.add_child(who)
	for slot in st.slots:
		var s := UiKit.rich(28, 650)
		s.text = "[center]%s[/center]" % Hints.highlighted_sentence(slot.item, "[color=#2b8a3e][b]%s[/b][/color]" % slot.item.answer)
		catch_box.add_child(s)
	catch_panel.visible = true
	catch_panel.reset_size()
	catch_panel.pivot_offset = Vector2(350, 120)
	catch_panel.scale = Vector2.ONE * 0.3
	var pop := create_tween()
	pop.tween_property(catch_panel, "scale", Vector2.ONE * 1.08, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_property(catch_panel, "scale", Vector2.ONE, 0.12)
	catch_panel.call_deferred("reset_size")
	await get_tree().create_timer(2.6).timeout
	if token == _popup_token:
		catch_panel.visible = false


# ---------------------------------------------------------------- teaching

## Every sign's deciding letter glows by its stage's help level (fades with mastery).
func _refresh_all_glows() -> void:
	for st in stations:
		if st.complete:
			continue
		for slot in st.slots:
			if not slot.solved:
				_refresh_slot_glow(slot)


func _refresh_slot_glow(slot: Dictionary) -> void:
	var word := str(slot.item.get("prev_word", ""))
	var help := GameState.progress.help_level(biome, str(slot.item.get("stage", "")))
	var glow := Color(GameConfig.R_COLOR if DRRule.takes_r(word) else GameConfig.D_COLOR)
	var l: Label3D = slot.end_label
	if is_instance_valid(l):
		l.modulate = Color("#212529").lerp(glow, help)
		l.font_size = 64 + int(round(24.0 * help))


func _blink_sign(slot: Dictionary) -> void:
	var l: Label3D = slot.end_label
	if not is_instance_valid(l):
		return
	var t := create_tween()
	for i in 3:
		t.tween_property(l, "scale", Vector3.ONE * 1.6, 0.15)
		t.tween_property(l, "scale", Vector3.ONE, 0.2)


func _introduce_stage(item: Dictionary) -> void:
	var stage := str(item.get("stage", ""))
	if stage == "" or GameState.progress.has_met_stage(biome, stage):
		return
	var first: bool = GameState.progress.help.get(biome, {}).is_empty()
	GameState.progress.meet_stage(biome, stage)
	var word := str(item.get("prev_word", ""))
	var n: int = mini(DRRule.deciding_length(word), word.length())
	var takes_r := DRRule.takes_r(word)
	var c: String = (GameConfig.R_COLOR if takes_r else GameConfig.D_COLOR).trim_prefix("#")
	var answer := str(item.get("answer", ""))
	var target := DRRule.r_form(answer) if takes_r else DRRule.d_form(answer)
	for ch in intro_box.get_children():
		intro_box.remove_child(ch)
		ch.queue_free()
	var title := UiKit.label(Strings.FIRST_KIND if first else Strings.NEW_KIND, 30, Color("#0b7285"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro_box.add_child(title)
	var ex := UiKit.rich(44, 620)
	ex.text = "[center]%s[color=#%s][b]%s[/b][/color]   →   [color=#%s][b]%s[/b][/color][/center]" % [
		word.left(word.length() - n), c, word.right(n), c, target]
	intro_box.add_child(ex)
	var rule := UiKit.rich(26, 620)
	rule.text = "[center]%s[/center]" % Hints.rule_line(word)
	intro_box.add_child(rule)
	intro_panel.visible = true
	intro_panel.reset_size()
	intro_panel.call_deferred("reset_size")
	intro_panel.pivot_offset = Vector2(330, 60)
	intro_panel.scale = Vector2.ONE * 0.4
	create_tween().tween_property(intro_panel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	AudioManager.play("rare")
	SaveManager.save_game()
	if autoplay:
		_bot_snap_later("13_new_kind_%s" % stage, 0.4)
	_intro_token += 1
	var token := _intro_token
	await get_tree().create_timer(5.0 if not autoplay else 1.5).timeout
	if token == _intro_token:
		intro_panel.visible = false


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
	var ok := UiKit.button(Strings.OK, 28)
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ok.pressed.connect(func() -> void: hint_panel.visible = false)
	hint_box.add_child(ok)
	hint_panel.visible = true
	hint_panel.reset_size()
	hint_panel.call_deferred("reset_size")
	if autoplay:
		_bot_snap_later("14_hint" if level == 1 else "15_worked_example", 0.3)
	await get_tree().create_timer(6.0 if not autoplay else 1.6).timeout
	if token == _hint_token:
		hint_panel.visible = false


# ---------------------------------------------------------------- HUD

func _build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	_light_grade()
	flash = ColorRect.new()
	flash.color = Color(1, 1, 1, 0)
	flash.size = get_viewport().get_visible_rect().size
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(flash)

	var back := UiKit.button(Strings.BACK, 24, Color("#495057"))
	back.position = Vector2(16, 14)
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://main/Hub3D.tscn"))
	ui.add_child(back)
	coins_label = UiKit.label("", 32, Color("#ffd43b"), 10)
	coins_label.position = Vector2(170, 22)
	ui.add_child(coins_label)
	index_button = UiKit.button("", 24, Color("#1971c2"))
	index_button.position = Vector2(690, 14)
	index_button.pressed.connect(func() -> void: index_page.open(biome))
	ui.add_child(index_button)
	var shop_button := UiKit.button(Strings.SHOP, 24, Color("#e67700"))
	shop_button.position = Vector2(950, 14)
	shop_button.pressed.connect(func() -> void: shop.open())
	ui.add_child(shop_button)

	var quest := UiKit.panel(Color("#fff9db"), 14)
	quest.position = Vector2(16, 90)
	ui.add_child(quest)
	var qv := VBoxContainer.new()
	quest.add_child(qv)
	qv.add_child(UiKit.label("MISYON", 18, Color("#e8590c")))
	quest_label = UiKit.label("", 20, UiKit.INK)
	qv.add_child(quest_label)

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

	# the sentence banner (read aloud when a voice exists)
	sentence_banner = UiKit.panel(Color("#fff9db"), 20)
	sentence_banner.position = Vector2(300, 430)
	sentence_banner.custom_minimum_size = Vector2(680, 0)
	sentence_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	sentence_banner.add_child(row)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	sentence_label = UiKit.rich(38, 520)
	col.add_child(sentence_label)
	var prompt := UiKit.label(Strings.SENTENCE_PROMPT, 18, Color("#495057"))
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(prompt)
	listen_button = UiKit.button(Strings.LISTEN, 20, Color("#1971c2"))
	listen_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	listen_button.pressed.connect(func() -> void:
		if not _active_slot.is_empty():
			_speak(_active_slot.item))
	row.add_child(listen_button)
	sentence_banner.visible = false
	ui.add_child(sentence_banner)

	# the word pouch: tap a word to place it into the active slot
	var pouch_panel := UiKit.panel(Color("#f1f3f5"), 18)
	pouch_panel.position = Vector2(430, 580)
	ui.add_child(pouch_panel)
	var pv := VBoxContainer.new()
	pouch_panel.add_child(pv)
	pv.add_child(UiKit.label(Strings.POUCH, 18, Color("#495057")))
	pouch_box = HBoxContainer.new()
	pouch_box.add_theme_constant_override("separation", 14)
	pv.add_child(pouch_box)
	_refresh_pouch()

	toast = UiKit.label("", 46, Color.WHITE, 14)
	toast.add_theme_color_override("font_outline_color", Color("#2b8a3e"))
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.size = Vector2(1280, 70)
	toast.position = Vector2(0, 200)
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

	intro_panel = UiKit.panel(Color("#e3fafc"), 22)
	intro_panel.position = Vector2(310, 84)
	intro_panel.custom_minimum_size = Vector2(660, 0)
	intro_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intro_box = VBoxContainer.new()
	intro_box.add_theme_constant_override("separation", 4)
	intro_panel.add_child(intro_box)
	intro_panel.visible = false
	ui.add_child(intro_panel)

	hint_panel = UiKit.panel()
	hint_panel.position = Vector2(250, 96)
	hint_panel.custom_minimum_size = Vector2(780, 0)
	hint_box = VBoxContainer.new()
	hint_box.add_theme_constant_override("separation", 10)
	hint_panel.add_child(hint_box)
	hint_panel.visible = false
	ui.add_child(hint_panel)

	debug_label = UiKit.label("", 18, Color.WHITE, 6)
	debug_label.position = Vector2(20, 200)
	debug_label.visible = false
	ui.add_child(debug_label)

	index_page = AnimalIndex.new()
	ui.add_child(index_page)
	shop = FruitShop.new()
	shop.changed.connect(_refresh_hud)
	ui.add_child(shop)


## STYLE.md lighting rule 4: warm radial wash + gentle vignette under the HUD.
func _light_grade() -> void:
	var size := get_viewport().get_visible_rect().size
	for grade in [
		{"colors": [Color(1.0, 0.86, 0.5, 0.09), Color(1.0, 0.86, 0.5, 0.0)],
			"offsets": [0.0, 1.0], "from": Vector2(0.35, 0.25), "to": Vector2(0.35, 1.1)},
		{"colors": [Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.24)],
			"offsets": [0.0, 0.68, 1.0], "from": Vector2(0.5, 0.5), "to": Vector2(0.5, 1.2)},
	]:
		var g := Gradient.new()
		g.colors = PackedColorArray(grade.colors)
		g.offsets = PackedFloat32Array(grade.offsets)
		var tex := GradientTexture2D.new()
		tex.gradient = g
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = grade.from
		tex.fill_to = grade.to
		tex.width = 512
		tex.height = 288
		var rect := TextureRect.new()
		rect.texture = tex
		rect.stretch_mode = TextureRect.STRETCH_SCALE
		rect.size = size
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ui.add_child(rect)


func _refresh_pouch() -> void:
	for b in pouch_buttons.values():
		(b as Node).queue_free()
	pouch_buttons.clear()
	var any := false
	for word in pouch:
		if int(pouch[word]) <= 0:
			continue
		any = true
		var b := UiKit.button("%s ×%d" % [word, pouch[word]] if int(pouch[word]) > 1 else str(word), 32, _word_color(str(word)))
		b.custom_minimum_size = Vector2(130, 84)
		b.pressed.connect(func() -> void: place_word(str(word)))
		pouch_box.add_child(b)
		pouch_buttons[word] = b
	if not any:
		var l := UiKit.label(Strings.NEED_TILE, 20, Color("#868e96"))
		pouch_box.add_child(l)
		pouch_buttons["_empty"] = l


func _refresh_hud() -> void:
	var coins := GameState.progress.coins
	if _shown_coins < 0 or coins < _shown_coins:
		_shown_coins = coins
		coins_label.text = Strings.COINS % coins
	elif coins > _shown_coins:
		var from := _shown_coins
		_shown_coins = coins
		var t := create_tween()
		t.tween_method(func(v: float) -> void: coins_label.text = Strings.COINS % int(v), float(from), float(coins), 0.6)
		coins_label.pivot_offset = coins_label.size / 2.0
		var b := create_tween()
		b.tween_property(coins_label, "scale", Vector2.ONE * 1.35, 0.12)
		b.tween_property(coins_label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BOUNCE)
	index_button.text = "%s  %d/%d" % [Strings.INDEX, GameState.progress.collected_count(biome), session.animals.size()]
	quest_label.text = "%s: %d/%d" % [Strings.INDEX, GameState.progress.collected_count(biome), session.animals.size()]
	combo_label.text = Strings.COMBO % session.streak if session.streak >= 2 else ""
	mult_label.text = Strings.MULTIPLIER % session.multiplier() if session.multiplier() > 1 else ""
	var lines := ["F3 debug (team only)"]
	for s in session.stages:
		lines.append("%s: %d%% of last %d %s" % [s, int(GameState.progress.stage_accuracy(biome, s) * 100),
			GameState.progress.stage_window(biome, s).size(), "OK" if GameState.progress.stage_met(biome, s) else ""])
	lines.append("mode: %s · streak %d · attempts %d" % ["mixed" if session.mixed else "stage %d" % (session.stage_index + 1), session.streak, first_attempts])
	debug_label.text = "\n".join(lines)


func _bump_combo() -> void:
	combo_label.pivot_offset = combo_label.size / 2.0
	combo_label.scale = Vector2.ONE * 1.8
	var hot: float = clamp(session.streak / 10.0, 0.0, 1.0)
	combo_label.add_theme_color_override("font_color", Color("#ffd43b").lerp(Color("#ff6b6b"), hot))
	var t := create_tween()
	t.tween_property(combo_label, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _flash(strength: float) -> void:
	flash.color.a = strength
	create_tween().tween_property(flash, "color:a", 0.0, 0.35)


func _show_toast(text: String, seconds: float = 1.0) -> void:
	toast.text = text
	toast.modulate.a = 1.0
	toast.visible = true
	var t := create_tween()
	t.tween_interval(seconds)
	t.tween_property(toast, "modulate:a", 0.0, 0.3)
	t.tween_callback(func() -> void: toast.visible = false)


func _find_voice() -> String:
	if DisplayServer.get_name() == "headless" or not ProjectSettings.get_setting("audio/general/text_to_speech", false):
		return ""
	for lang in ["fil", "tl"]:
		var voices := DisplayServer.tts_get_voices_for_language(lang)
		if not voices.is_empty():
			return voices[0]
	return ""


func _speak(item: Dictionary) -> void:
	if _tts_voice == "":
		return
	DisplayServer.tts_stop()
	DisplayServer.tts_speak(str(item.get("sentence", "")).replace("___", "..."), _tts_voice)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_F3:
				debug_label.visible = not debug_label.visible
			KEY_1, KEY_2, KEY_3, KEY_4:
				var i: int = int(event.keycode) - int(KEY_1)
				var words: Array = pouch_buttons.keys().filter(func(k): return k != "_empty")
				if i < words.size():
					place_word(str(words[i]))


# ---------------------------------------------------------------- autoplay (checks without a person)

func _bot(delta: float) -> void:
	_bot_dir = Vector3.ZERO
	if _bot_done:
		return
	if Time.get_ticks_msec() - _started_ms > 240000:
		_finish_autoplay()
		return
	if _bot_wait > 0.0:
		_bot_wait -= delta
		return
	if not _snapped.has("12_world"):
		_bot_snap_later("12_world", 0.0)
	if not _bot_bought and GameState.progress.coins >= int(GameConfig.FRUIT_TIERS[1].price):
		_bot_bought = true
		_bot_shop()
		_bot_wait = 2.0
		return
	var done := 0
	for st in stations:
		if st.complete:
			done += 1
	if done >= AUTOPLAY_RESCUES:
		_finish_autoplay()
		return
	# the nearest incomplete station
	var target: Dictionary = {}
	for st in stations:
		if not st.complete:
			target = st
			break
	if target.is_empty():
		return
	if DebugTools.has_arg("--trace") and Engine.get_process_frames() % 90 == 0:
		var slot_dbg := []
		for sl in target.slots:
			slot_dbg.append("%s:%s solved=%s wrongs=%s" % [sl.item.get("id", ""), sl.item.answer, sl.solved, sl.wrongs])
		print("BOT st=%d pouch=%s tiles=%d active=%s player=%s stand=%s slots=%s" % [target.index, pouch, tiles.size(),
			"" if _active_slot.is_empty() else _active_slot.item.get("id", ""), player.global_position, target.stand_z, slot_dbg])
	# 1. collect a tile the station still needs
	var needed := _bot_needed_word(target)
	if needed != "":
		var tile := _bot_tile_with(needed)
		if tile != null:
			var d := tile.global_position - player.global_position
			d.y = 0
			if d.length() > 1.0:
				_bot_dir = d.normalized()
			return
		# no tile anywhere (shouldn't happen): fall through and walk to the slot
	# 2. walk to the front of the crossing, then place into the active (nearest unsolved) slot
	var stand := Vector3(target.cx, 0, float(target.stand_z))
	var ds := stand - player.global_position
	ds.y = 0
	if ds.length() > 1.2:
		_bot_dir = ds.normalized()
		return
	if _active_slot.is_empty():
		return
	for slot in [_active_slot]:
		var right := str(slot.item.answer)
		var wrong := DRRule.d_form(right) if right != DRRule.d_form(right) else DRRule.r_form(right)
		var choice := right
		# the 2nd slot overall is missed twice, to show the hint and the worked example
		if first_attempts == 1 and not slot.attempted and _bot_missed_slots == 0:
			_bot_missed_slots = 1
			choice = wrong
		elif int(slot.wrongs) == 1 and int(pouch.get(wrong, 0)) > 0:
			choice = wrong if int(slot.wrongs) < 2 else right
		if int(pouch.get(choice, 0)) <= 0:
			choice = right if int(pouch.get(right, 0)) > 0 else ""
		if choice == "":
			return
		place_word(choice)
		_bot_wait = 2.2
		return
	_bot_wait = 0.5


func _bot_needed_word(st: Dictionary) -> String:
	var need := {}
	for slot in st.slots:
		if slot.solved:
			continue
		for w in slot.choices:
			need[w] = int(need.get(w, 0)) + 1
	# collect until the pouch holds the right word for every unsolved slot
	var right_need := {}
	for slot in st.slots:
		if not slot.solved:
			right_need[slot.item.answer] = int(right_need.get(slot.item.answer, 0)) + 1
	for w in right_need:
		if int(pouch.get(w, 0)) < int(right_need[w]) and _bot_tile_with(str(w)) != null:
			return str(w)
	# decoys too only at the first station, so the scripted misses (both hint levels) can happen
	if st.index == 0:
		for w in need:
			if int(pouch.get(w, 0)) < 1 and _bot_tile_with(str(w)) != null:
				return str(w)
	return ""


func _bot_tile_with(word: String) -> Node3D:
	var best: Node3D = null
	var best_d := INF
	for t in tiles:
		if is_instance_valid(t) and str(t.get_meta("word")) == word:
			var d := t.global_position.distance_to(player.global_position)
			if d < best_d:
				best_d = d
				best = t
	return best


func _bot_shop() -> void:
	shop.open()
	await get_tree().create_timer(0.3).timeout
	await _bot_snap_later("25_shop", 0.0)
	shop.buy(GameConfig.FRUIT_TIERS[1].id)
	await get_tree().create_timer(0.3).timeout
	shop.visible = false


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
		first_attempts, GameState.progress.coins, GameState.progress.collected_count(biome), session.animals.size(),
		session.streak, GameState.progress.equipped_fruit, GameState.progress.variants.get(biome, {}),
		session.misses, _snapped.keys()])
	get_tree().quit()
