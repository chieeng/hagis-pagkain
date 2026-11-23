extends Node2D
## The pen ("Kulungan"): every animal the learner has collected lives here and wanders around.
## TODO (proposal): decorations bought with coins; idle animations with real art.

const AREA := Rect2(120, 260, 1040, 400)

var _animals: Array[AnimalSprite] = []


func _ready() -> void:
	var count := 0
	for biome in GameState.BIOME_ORDER:
		for id in GameState.progress.collected.get(biome, []):
			var data := QuestionBank.find_animal(id)
			if data.is_empty():
				continue
			var a := AnimalSprite.new()
			add_child(a)
			a.setup(data, 46)
			a.position = _random_spot()
			_animals.append(a)
			_wander(a)
			count += 1

	var ui := CanvasLayer.new()
	add_child(ui)
	var back := UiKit.button(Strings.BACK, 26, Color("#495057"))
	back.position = Vector2(16, 14)
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://main/Main.tscn"))
	ui.add_child(back)
	var title := UiKit.label("%s  (%d)" % [Strings.PEN, count], 48, Color.WHITE, 12)
	title.position = Vector2(200, 14)
	ui.add_child(title)
	var coins := UiKit.label(Strings.COINS % GameState.progress.coins, 32, Color("#e67700"), 8)
	coins.add_theme_color_override("font_outline_color", Color.WHITE)
	coins.position = Vector2(1000, 24)
	ui.add_child(coins)
	if count == 0:
		var empty := UiKit.label(Strings.PEN_EMPTY, 34, UiKit.INK)
		empty.position = Vector2(300, 420)
		ui.add_child(empty)

	if DebugTools.has_arg("--autoplay"):
		await get_tree().create_timer(1.0).timeout
		await DebugTools.snap(self, "07_pen")
		print("AUTOPLAY pen: animals=%d" % count)
		get_tree().quit()


func _random_spot() -> Vector2:
	return Vector2(randf_range(AREA.position.x, AREA.end.x), randf_range(AREA.position.y, AREA.end.y))


func _wander(a: AnimalSprite) -> void:
	while is_instance_valid(a) and a.is_inside_tree():
		var t := create_tween()
		t.tween_property(a, "position", _random_spot(), randf_range(2.0, 4.0)).set_trans(Tween.TRANS_SINE)
		t.parallel().tween_property(a, "rotation", randf_range(-0.08, 0.08), 0.5)
		await t.finished
		if not is_inside_tree():
			return
		await get_tree().create_timer(randf_range(0.3, 1.5)).timeout


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("#b2f2bb"))
	draw_rect(Rect2(0, 0, 1280, 200), Color("#a5d8ff"))
	var fence := Color("#a0522d")
	draw_rect(Rect2(80, 220, 1120, 12), fence)
	draw_rect(Rect2(80, 690, 1120, 12), fence)
	for x in range(80, 1220, 80):
		draw_rect(Rect2(x, 200, 14, 60), fence)
		draw_rect(Rect2(x, 670, 14, 40), fence)
