class_name FruitShop
extends Control
## Tindahan ng Prutas [Fruit Shop]: spend coins on better fruit that flies farther,
## so shy rare/golden animals can be reached [proposal: coins buy new kinds of food].
## Owner: Alex (look), Irish (Progress.buy_fruit logic).

signal changed


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false


func open() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var panel := UiKit.panel()
	panel.position = Vector2(90, 70)
	panel.custom_minimum_size = Vector2(1100, 560)
	add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	panel.add_child(vb)
	var p := GameState.progress
	var title := UiKit.label("%s     %s" % [Strings.SHOP_TITLE, Strings.COINS % p.coins], 38)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	var note := UiKit.label(Strings.SHOP_NOTE, 24, Color("#495057"))
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(note)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	vb.add_child(row)
	for t in GameConfig.FRUIT_TIERS:
		row.add_child(_card(t))

	var close := UiKit.button(Strings.BACK)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(func() -> void: visible = false)
	vb.add_child(close)
	visible = true


func _card(t: Dictionary) -> PanelContainer:
	var p := GameState.progress
	var card := UiKit.panel(Color.WHITE, 22)
	card.custom_minimum_size = Vector2(240, 330)
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 10)
	card.add_child(vb)
	var fruit := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(t.color)
	sb.set_corner_radius_all(50)
	fruit.add_theme_stylebox_override("panel", sb)
	fruit.custom_minimum_size = Vector2(100, 100)
	fruit.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(fruit)
	for text in [t.name, Strings.SHOP_RANGE % int(t.range)]:
		var l := UiKit.label(text, 28 if text == t.name else 24)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(l)
	var owned: bool = t.id in p.owned_fruits
	var in_use: bool = p.equipped_fruit == t.id
	var price := UiKit.label("" if owned else Strings.SHOP_PRICE % int(t.price), 24, Color("#e67700"))
	price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(price)
	var b := UiKit.button(Strings.SHOP_IN_USE if in_use else (Strings.SHOP_USE if owned else Strings.SHOP_BUY), 26)
	b.disabled = in_use or (not owned and p.coins < int(t.price))
	b.pressed.connect(buy.bind(t.id))
	vb.add_child(b)
	return card


func buy(tier_id: String) -> bool:
	var had := tier_id in GameState.progress.owned_fruits
	if not GameState.progress.buy_fruit(tier_id):
		return false
	SaveManager.save_game()
	changed.emit()
	open()
	return not had
