extends Control
## Owner: Lead. Title screen and biome map.
## Forest is playable; the other biomes show as closed until unlocked, then "coming soon"
## until their scenes exist (GameState.BIOME_SCENES).


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#d3f9d8")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var vb := VBoxContainer.new()
	vb.position = Vector2(0, 50)
	vb.size = Vector2(1280, 620)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 26)
	add_child(vb)

	var title := UiKit.label(Strings.TITLE, 88, Color("#2b8a3e"), 16)
	title.add_theme_color_override("font_outline_color", Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	var sub := UiKit.label(Strings.SUBTITLE, 32, UiKit.INK)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(sub)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 20)
	vb.add_child(row)
	for biome in GameState.BIOME_ORDER:
		row.add_child(_biome_card(biome))

	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 30)
	vb.add_child(bottom)
	var lesson := UiKit.button(Strings.LESSON, 32, Color("#0b7285"))
	lesson.custom_minimum_size = Vector2(220, 76)
	lesson.pressed.connect(func() -> void: get_tree().change_scene_to_file(GameState.LESSON_SCENE))
	bottom.add_child(lesson)
	var pen := UiKit.button(Strings.PEN, 32, Color("#9c36b5"))
	pen.custom_minimum_size = Vector2(260, 76)
	pen.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://ui/Pen.tscn"))
	bottom.add_child(pen)
	var coins := UiKit.label(Strings.COINS % GameState.progress.coins, 34, Color("#e67700"), 8)
	coins.add_theme_color_override("font_outline_color", Color.WHITE)
	bottom.add_child(coins)

	if DebugTools.has_arg("--autoplay"):
		await DebugTools.snap(self, "01_main")
		get_tree().change_scene_to_file(GameState.LESSON_SCENE)


func _biome_card(biome: String) -> Button:
	var pairs := ", ".join(GameState.BIOMES[biome])
	var open := GameState.is_unlocked(biome)
	var built := GameState.BIOME_SCENES.has(biome)
	var status := ""
	if not open:
		status = Strings.LOCKED
	elif not built:
		status = Strings.SOON
	var b := UiKit.button("%s\n%s\n%s" % [GameState.BIOME_NAMES[biome], pairs, status], 26)
	b.custom_minimum_size = Vector2(250, 190)
	b.disabled = not (open and built)
	if open and built:
		b.pressed.connect(func() -> void:
			# The lesson comes first the first time.
			var first_time: bool = not GameState.progress.lessons_done.get(biome, false)
			get_tree().change_scene_to_file(GameState.LESSON_SCENE if first_time else GameState.BIOME_SCENES[biome]))
	return b
