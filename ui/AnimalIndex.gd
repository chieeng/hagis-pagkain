class_name AnimalIndex
extends Control
## The Animal Index ("Aklat ng Hayop") page for one biome: found animals in colour,
## missing ones as grey shapes. Owner: Alex (look), Lead (data).

signal closed


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false


func open(biome: String) -> void:
	for c in get_children():
		c.queue_free()
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var animals := QuestionBank.get_animals(biome)
	var found := GameState.progress.collected_count(biome)
	var panel := UiKit.panel()
	panel.position = Vector2(140, 50)
	panel.custom_minimum_size = Vector2(1000, 620)
	add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)

	var title := UiKit.label("%s: %s   %d / %d" % [Strings.INDEX, GameState.BIOME_NAMES.get(biome, biome), found, animals.size()], 38)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)

	var grid := GridContainer.new()
	grid.columns = 4
	vb.add_child(grid)
	for a in animals:
		var slot := Control.new()
		slot.custom_minimum_size = Vector2(236, 210)
		var sprite := AnimalSprite.new()
		sprite.silhouette = not GameState.progress.has_animal(biome, a.id)
		slot.add_child(sprite)
		sprite.position = Vector2(118, 80)
		sprite.setup(a, 52)
		sprite.name_label.add_theme_color_override("font_color", UiKit.INK)
		sprite.name_label.add_theme_constant_override("outline_size", 0)
		grid.add_child(slot)

	var close := UiKit.button(Strings.BACK)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(func() -> void:
		visible = false
		closed.emit())
	vb.add_child(close)
	visible = true
