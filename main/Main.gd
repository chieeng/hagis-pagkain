extends Control
## Owner: Lead. The biome-select screen the game opens on [proposal, Unlocking]:
## every biome shows the learner's progress (animals caught, sentences answered), any open
## biome can be replayed, and a locked biome says what is still needed to open it.
## There is no lesson screen: the rule is taught inside the game.


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#d3f9d8")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var vb := VBoxContainer.new()
	vb.position = Vector2(0, 30)
	vb.size = Vector2(1280, 660)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 22)
	add_child(vb)

	var title := UiKit.label(Strings.TITLE, 80, Color("#2b8a3e"), 16)
	title.add_theme_color_override("font_outline_color", Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	var sub := UiKit.label(Strings.SUBTITLE, 30, UiKit.INK)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(sub)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	vb.add_child(row)
	for biome in GameState.BIOME_ORDER:
		row.add_child(_biome_card(biome))

	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 24)
	vb.add_child(bottom)
	var pen := UiKit.button(Strings.PEN, 30, Color("#9c36b5"))
	pen.custom_minimum_size = Vector2(230, 72)
	pen.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://ui/Pen.tscn"))
	bottom.add_child(pen)
	var prog := UiKit.button(Strings.MY_PROGRESS, 30, Color("#1971c2"))
	prog.custom_minimum_size = Vector2(290, 72)
	prog.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://ui/MyProgress.tscn"))
	bottom.add_child(prog)
	var coins := UiKit.label(Strings.COINS % GameState.progress.coins, 32, Color("#e67700"), 8)
	coins.add_theme_color_override("font_outline_color", Color.WHITE)
	bottom.add_child(coins)

	if DebugTools.has_arg("--autoplay"):
		await DebugTools.snap(self, "01_main")
		get_tree().change_scene_to_file(GameState.BIOME_SCENES[DebugTools.arg_value("--biome") if DebugTools.arg_value("--biome") != "" else "forest"])


func _biome_card(biome: String) -> Button:
	var pairs := ", ".join(GameState.BIOMES[biome])
	var open := GameState.is_unlocked(biome)
	var built: bool = GameState.BIOME_SCENES.has(biome)
	var p := GameState.progress
	var lines: Array[String] = [GameState.BIOME_NAMES[biome], pairs, ""]
	if open and built:
		# Progress on the card [proposal]: animals caught and sentences answered.
		var total: int = QuestionBank.get_animals(biome).size()
		lines.append(Strings.PROGRESS_ANIMALS % [p.collected_count(biome), total])
		var n := int(p.answered.get(biome, 0))
		lines.append(Strings.PROGRESS_SENTENCES % n if n > 0 else Strings.PLAY)
	elif not open:
		# What is still needed [proposal]: finish the previous biome's Index + accuracy check.
		var prev_i := GameState.BIOME_ORDER.find(biome) - 1
		var prev: String = GameState.BIOME_ORDER[prev_i] if prev_i >= 0 else ""
		lines.append(Strings.LOCKED)
		if prev != "" and GameState.is_unlocked(prev):
			if not p.index_complete(prev, QuestionBank.get_animals(prev).size()):
				lines.append(Strings.NEED_INDEX)
			else:
				lines.append(Strings.NEED_ACCURACY)
		elif prev != "":
			lines.append(Strings.NEED_PREV % GameState.BIOME_NAMES[prev])
	else:
		lines.append(Strings.SOON)
	var b := UiKit.button("\n".join(lines), 22)
	b.custom_minimum_size = Vector2(238, 210)
	b.disabled = not (open and built)
	if open and built:
		b.pressed.connect(func() -> void: get_tree().change_scene_to_file(GameState.BIOME_SCENES[biome]))
	return b
