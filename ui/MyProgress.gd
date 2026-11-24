extends Control
## My Progress screen [proposal, MVP]: the learner's own first-throw accuracy per pair and
## per context (vowel, consonant, w/y, exception), and the sentences to review next.
## Data: Progress.pair_stats and Progress.missed_items (all biomes together).
## Owner: Alex (look), Irish (data).

const STAGES: Array[String] = ["vowel", "consonant", "wy", "exception"]


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#e7f5ff")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var back := UiKit.button(Strings.BACK, 26, Color("#495057"))
	back.position = Vector2(16, 14)
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://main/Main.tscn"))
	add_child(back)
	var title := UiKit.label(Strings.MY_PROGRESS, 44, Color("#1971c2"))
	title.position = Vector2(200, 18)
	add_child(title)

	var panel := UiKit.panel()
	panel.position = Vector2(90, 90)
	panel.custom_minimum_size = Vector2(1100, 0)
	add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)

	var grid := GridContainer.new()
	grid.columns = STAGES.size() + 1
	grid.add_theme_constant_override("h_separation", 26)
	grid.add_theme_constant_override("v_separation", 8)
	vb.add_child(grid)
	grid.add_child(UiKit.label(Strings.PAIR, 26, Color("#495057")))
	for s in STAGES:
		grid.add_child(_cell(Strings.STAGE_NAMES[s], Color("#495057")))
	var p := GameState.progress
	# Pairs come straight from DRRule, so this table cannot drift from the rule engine.
	for d in DRRule.PAIRS:
		var pair := "%s/%s" % [d, DRRule.PAIRS[d]]
		grid.add_child(UiKit.label(pair, 26, UiKit.INK))
		for s in STAGES:
			var acc := p.pair_accuracy(pair, s)
			if acc < 0.0:
				grid.add_child(_cell(Strings.NO_DATA, Color("#adb5bd")))
			else:
				var col := Color("#2b8a3e") if acc >= GameConfig.ACCURACY_TARGET else Color("#e67700")
				grid.add_child(_cell("%d%%" % int(round(acc * 100)), col))

	vb.add_child(HSeparator.new())
	vb.add_child(UiKit.label(Strings.REVIEW_NEXT, 26, Color("#1971c2")))
	var any := false
	for item_id in p.missed_items:
		var item := QuestionBank.find_item(str(item_id))
		if item.is_empty():
			continue
		any = true
		var line := UiKit.rich(24, 1000)
		line.text = "•  %s   [color=#868e96](%s)[/color]" % [
			Hints.highlighted_sentence(item), GameState.BIOME_NAMES.get(item.biome, item.biome)]
		vb.add_child(line)
	if not any:
		vb.add_child(UiKit.label(Strings.NOTHING_TO_REVIEW, 24, Color("#2b8a3e")))

	if DebugTools.has_arg("--autoplay"):
		await get_tree().create_timer(0.5).timeout
		await DebugTools.snap(self, "30_my_progress")
		print("AUTOPLAY my-progress: pairs=%d missed=%d" % [p.pair_stats.size(), p.missed_items.size()])
		get_tree().quit()


func _cell(text: String, color: Color) -> Label:
	var l := UiKit.label(text, 26, color)
	l.custom_minimum_size = Vector2(150, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l
