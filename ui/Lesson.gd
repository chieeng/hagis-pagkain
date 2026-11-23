extends Control
## Aralin (lesson) shown before the Forest the first time, and any time from the menu.
## Explicit rule teaching before play [proposal: Error Analysis, Scaffolding/ZPD; Holz et al. tutorials].
##   1. Tingnan [Look]: three examples with the deciding letter lit up and the rule.
##   2. Hanapin [Find]: tap the last letter of a few words (the habit we want).
##   3. Ayusin [Sort]: drag words into the R basket (rin) or the D basket (din).
##   4. Maglaro [Play]: summary card, then the game.
## Not a story: no plot, just a guide animal pointing at things.

const BIOME := "forest"
const NEXT_SCENE := "res://biomes/forest/Forest3D.tscn"

var _words: Array = []          # [{word, stage}] from the item bank, one per prev_word
var _step := 0
var _content: VBoxContainer
var _step_labels: Array[Label] = []
var _guide_text: RichTextLabel
var _find_index := 0
var _sort_left := 0
var _sort_first := true
var _r_basket: PanelContainer
var _d_basket: PanelContainer
var _chips_row: HFlowContainer
var autoplay := DebugTools.has_arg("--autoplay")


func _ready() -> void:
	_collect_words()
	var bg := ColorRect.new()
	bg.color = Color("#e6fcf5")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var top := HBoxContainer.new()
	top.position = Vector2(16, 14)
	top.add_theme_constant_override("separation", 18)
	add_child(top)
	var back := UiKit.button(Strings.BACK, 24, Color("#495057"))
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://main/Main.tscn"))
	top.add_child(back)
	top.add_child(UiKit.label(Strings.LESSON_TITLE, 36, Color("#0b7285")))
	for s in Strings.LESSON_STEPS:
		var l := UiKit.label(s, 22, Color("#adb5bd"))
		l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_step_labels.append(l)
		top.add_child(l)

	# Guide animal (bottom-left) with what it is saying.
	var guide := AnimalSprite.new()
	guide.setup({"name": "Kuwago", "color": "#a07850"}, 60)
	guide.position = Vector2(110, 610)
	add_child(guide)
	var bubble := UiKit.panel(Color.WHITE, 22)
	bubble.position = Vector2(200, 560)
	_guide_text = UiKit.rich(28, 1000)
	bubble.add_child(_guide_text)
	add_child(bubble)

	_content = VBoxContainer.new()
	_content.position = Vector2(60, 100)
	_content.size = Vector2(1160, 440)
	_content.add_theme_constant_override("separation", 18)
	add_child(_content)
	_show_step(0)


func _collect_words() -> void:
	var seen := {}
	for item in QuestionBank.get_items(BIOME):
		var w: String = item.prev_word
		if seen.has(w.to_lower()):
			continue
		seen[w.to_lower()] = true
		_words.append({"word": w, "stage": item.stage, "answer": item.answer})


func _say(text: String) -> void:
	_guide_text.text = text


func _clear() -> void:
	for c in _content.get_children():
		_content.remove_child(c)
		c.queue_free()


func _show_step(i: int) -> void:
	_step = i
	for j in _step_labels.size():
		_step_labels[j].add_theme_color_override("font_color", Color("#0b7285") if j == i else Color("#adb5bd"))
	_clear()
	match i:
		0:
			_step_look()
		1:
			_step_find()
		2:
			_step_sort()
		3:
			_step_ready()


# ---------------------------------------------------------------- 1. Look

func _step_look() -> void:
	_say(Strings.LESSON_LOOK)
	for ex in _examples():
		var row := UiKit.rich(46, 1100)
		row.text = "%s [b]%s[/b]      [color=#495057][font_size=30]%s[/font_size][/color]" % [
			Hints.highlight_word(ex.word), ex.answer, Hints.rule_line(ex.word)]
		_content.add_child(row)
	_add_next_button(func() -> void: _show_step(1))
	if autoplay:
		_autoplay_snap_then("08_lesson_look", func() -> void: _show_step(1))


## One example per stage, in the proposal's order (vowel, w/y, consonant).
func _examples() -> Array:
	var out := []
	for stage in ["vowel", "wy", "consonant", "exception"]:
		var best: Variant = null
		for w in _words:
			# prefer a full word (e.g. "Masaya") over a tiny one (e.g. "ka")
			if w.stage == stage and (best == null or (best.word.length() < 4 and w.word.length() >= 4)):
				best = w
		if best != null:
			out.append(best)
	return out


# ---------------------------------------------------------------- 2. Find

func _step_find() -> void:
	_find_index = 0
	_show_find_word()


func _find_words() -> Array:
	var out := _examples()
	for w in _words:
		if out.size() >= 4:
			break
		if not w in out:
			out.append(w)
	return out


func _show_find_word() -> void:
	_clear()
	var words := _find_words()
	if _find_index >= words.size():
		_show_step(2)
		return
	_say(Strings.LESSON_FIND)
	var word: String = words[_find_index].word
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	_content.add_child(UiKit.label("%d / %d" % [_find_index + 1, words.size()], 24, Color("#868e96")))
	_content.add_child(row)
	var buttons: Array[Button] = []
	for k in word.length():
		var b := UiKit.button(word[k], 64, Color("#1c7ed6"))
		b.custom_minimum_size = Vector2(100, 120)
		var is_last := k == word.length() - 1
		b.pressed.connect(_on_letter.bind(b, is_last, word))
		row.add_child(b)
		buttons.append(b)
	if autoplay:
		await get_tree().create_timer(0.3).timeout
		if _find_index == 0:
			buttons[0].pressed.emit()          # show the "try again" message once
			await get_tree().create_timer(0.2).timeout
		buttons[-1].pressed.emit()


func _on_letter(b: Button, is_last: bool, word: String) -> void:
	if not is_last:
		_say(Strings.LESSON_FIND_AGAIN)
		var t := create_tween()
		for dx in [8.0, -8.0, 0.0]:
			t.tween_property(b, "position:x", b.position.x + dx, 0.05)
		return
	b.add_theme_stylebox_override("normal", _flat(Color("#e8590c")))
	b.add_theme_stylebox_override("disabled", _flat(Color("#e8590c")))
	for sib in b.get_parent().get_children():
		(sib as Button).disabled = true
	_say("[b]%s[/b]   %s" % [Hints.highlight_word(word), Hints.rule_line(word)])
	if autoplay and _find_index == 0:
		await DebugTools.snap(self, "09_lesson_find")
	await get_tree().create_timer(1.4 if not autoplay else 0.4).timeout
	_find_index += 1
	_show_find_word()


# ---------------------------------------------------------------- 3. Sort

func _step_sort() -> void:
	_say(Strings.LESSON_SORT)
	_sort_first = true
	var baskets := HBoxContainer.new()
	baskets.alignment = BoxContainer.ALIGNMENT_CENTER
	baskets.add_theme_constant_override("separation", 120)
	_r_basket = _make_basket(Strings.BASKET_R, "rin", Color("#2f9e44"))
	_d_basket = _make_basket(Strings.BASKET_D, "din", Color("#1971c2"))
	baskets.add_child(_r_basket)
	baskets.add_child(_d_basket)

	_chips_row = HFlowContainer.new()
	_chips_row.alignment = FlowContainer.ALIGNMENT_CENTER
	_chips_row.add_theme_constant_override("h_separation", 16)
	_chips_row.add_theme_constant_override("v_separation", 12)
	var words := _words.duplicate()
	words.shuffle()
	words = words.slice(0, 6)
	_sort_left = words.size()
	for w in words:
		_chips_row.add_child(_make_chip(w))
	_content.add_child(_chips_row)
	_content.add_child(baskets)
	_pulse_help()
	if autoplay:
		_autoplay_sort()


func _make_chip(w: Dictionary) -> Button:
	var chip := UiKit.button(w.word, 40, Color("#f08c00"))
	chip.custom_minimum_size = Vector2(190, 80)
	chip.set_meta("w", w)
	var get_drag := func(_pos: Vector2) -> Variant:
		var preview := UiKit.button(w.word, 40, Color("#f08c00"))
		preview.modulate.a = 0.85
		chip.set_drag_preview(preview)
		return chip
	var can_drop := func(_p: Vector2, _d: Variant) -> bool:
		return false
	var drop := func(_p: Vector2, _d: Variant) -> void:
		pass
	chip.set_drag_forwarding(get_drag, can_drop, drop)
	return chip


func _make_basket(title: String, answer: String, color: Color) -> PanelContainer:
	var p := UiKit.panel(color.lightened(0.75), 30)
	p.custom_minimum_size = Vector2(360, 190)
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	var t := UiKit.label(title, 52, color.darkened(0.2))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var inside := HFlowContainer.new()
	inside.name = "Inside"
	vb.add_child(inside)
	p.add_child(vb)
	p.set_meta("answer", answer)
	var get_drag := func(_pos: Vector2) -> Variant:
		return null
	var can_drop := func(_p: Vector2, data: Variant) -> bool:
		return data is Button and data.has_meta("w")
	var drop := func(_p: Vector2, data: Variant) -> void:
		_drop(data, p)
	p.set_drag_forwarding(get_drag, can_drop, drop)
	return p


func _drop(chip: Button, basket: PanelContainer) -> void:
	var w: Dictionary = chip.get_meta("w")
	if w.answer == basket.get_meta("answer"):
		chip.get_parent().remove_child(chip)
		chip.custom_minimum_size = Vector2(120, 50)
		chip.add_theme_font_size_override("font_size", 26)
		chip.disabled = true
		chip.add_theme_stylebox_override("disabled", _flat(Color("#2f9e44")))
		basket.find_child("Inside", true, false).add_child(chip)
		_say("[b]%s %s[/b]   %s" % [Hints.highlight_word(w.word), w.answer, Hints.rule_line(w.word)])
		_sort_first = false
		_sort_left -= 1
		if _sort_left <= 0:
			if autoplay:
				await DebugTools.snap(self, "10_lesson_sort")
			await get_tree().create_timer(1.2 if not autoplay else 0.3).timeout
			_show_step(3)
	else:
		_say("%s   [b]%s[/b]   %s" % [Strings.LESSON_SORT_HELP, Hints.highlight_word(w.word), Hints.rule_line(w.word)])
		var t := create_tween()
		for dx in [10.0, -10.0, 6.0, 0.0]:
			t.tween_property(chip, "position:x", chip.position.x + dx, 0.05)


## First time only: gently pulse the right basket for the first word (help the first time).
func _pulse_help() -> void:
	await get_tree().process_frame
	if not _sort_first or _chips_row.get_child_count() == 0:
		return
	var w: Dictionary = _chips_row.get_child(0).get_meta("w")
	var target := _r_basket if w.answer == "rin" else _d_basket
	_say("%s  [b]%s[/b] → [b]%s[/b]" % [Strings.LESSON_SORT_HELP, Hints.highlight_word(w.word), w.answer])
	var t := create_tween().set_loops(3)
	t.tween_property(target, "scale", Vector2(1.06, 1.06), 0.3)
	t.tween_property(target, "scale", Vector2.ONE, 0.3)


func _autoplay_sort() -> void:
	await get_tree().create_timer(0.5).timeout
	var first := true
	while _chips_row.get_child_count() > 0 and _step == 2:
		var chip: Button = _chips_row.get_child(0)
		var w: Dictionary = chip.get_meta("w")
		if first:
			_drop(chip, _d_basket if w.answer == "rin" else _r_basket)   # one wrong drop to show the help
			first = false
			await get_tree().create_timer(0.3).timeout
		_drop(chip, _r_basket if w.answer == "rin" else _d_basket)
		await get_tree().create_timer(0.25).timeout


# ---------------------------------------------------------------- 4. Ready

func _step_ready() -> void:
	_say(Strings.LESSON_READY)
	var card := UiKit.panel()
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	card.add_child(vb)
	for stage in ["vowel", "wy", "consonant"]:
		var l := UiKit.rich(38, 900)
		l.text = "[b]%s[/b]" % Hints.RULE_LINES[stage]
		vb.add_child(l)
	_content.add_child(card)
	var go := UiKit.button(Strings.LESSON_GO, 40)
	go.custom_minimum_size = Vector2(320, 90)
	go.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	go.pressed.connect(_finish)
	_content.add_child(go)
	if autoplay:
		_autoplay_snap_then("11_lesson_ready", _finish)


func _finish() -> void:
	GameState.progress.lessons_done[BIOME] = true
	SaveManager.save_game()
	get_tree().change_scene_to_file(NEXT_SCENE)


# ---------------------------------------------------------------- helpers

func _add_next_button(on_press: Callable) -> void:
	var ok := UiKit.button(Strings.OK, 34)
	ok.custom_minimum_size = Vector2(220, 80)
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ok.pressed.connect(on_press)
	_content.add_child(ok)


func _flat(c: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.set_corner_radius_all(18)
	sb.set_content_margin_all(12)
	return sb


func _autoplay_snap_then(shot: String, then: Callable) -> void:
	await get_tree().create_timer(0.4).timeout
	await DebugTools.snap(self, shot)
	then.call()
