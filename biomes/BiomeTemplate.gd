class_name BiomeTemplate
extends Node2D
## Owner: Lead (template). Loraine makes each biome scene from BiomeTemplate.tscn and sets `biome`.
##
## One round [proposal, Part 3 "Core loop"]:
##   1. An animal walks in and "says" a sentence with a blank.
##   2. The learner drags one of the foods (din / rin) and lets go to throw it.
##   3. Correct: the animal joins the pen and coins are added.
##      Not the preferred form: the animal walks away and a hint shows the deciding letter.
##      A second miss on the same sentence shows a worked example.
## Game logic lives in core/BiomeSession.gd; this script only shows it.
## Feedback wording: "mas wasto" / "Mahusay!", never "mali".

@export var biome: String = "forest"

const ANIMAL_SPOT := Vector2(930, 430)
const OFFSCREEN_X := 1450.0
const AUTOPLAY_TURNS := 14

var session: BiomeSession
var _shown_at_ms := 0

# World
var background: BiomeBackground
var animal: AnimalSprite
var thrower: ThrowController
# UI (on a CanvasLayer)
var ui: CanvasLayer
var coins_label: Label
var stage_label: Label
var index_button: Button
var pen_button: Button
var bubble: PanelContainer
var bubble_text: RichTextLabel
var toast: Label
var drag_hint: Label
var hint_panel: PanelContainer
var hint_box: VBoxContainer
var index_page: AnimalIndex
var debug_label: Label

# Autoplay (checks without a person playing)
var autoplay := DebugTools.has_arg("--autoplay")
var _turn := 0
var _first_miss_id := ""
var _snapped := {}


func _ready() -> void:
	session = BiomeSession.new(biome, QuestionBank.get_items(biome), QuestionBank.get_animals(biome), GameState.progress)
	_build_world()
	_build_ui()
	if session.items.is_empty():
		_show_toast(Strings.NO_ITEMS, 999.0)
		return
	_next_round()


# ---------------------------------------------------------------- building

func _build_world() -> void:
	background = BiomeBackground.new()
	background.biome = biome
	add_child(background)
	animal = AnimalSprite.new()
	animal.visible = false
	add_child(animal)
	thrower = ThrowController.new()
	thrower.target = ANIMAL_SPOT
	thrower.answer_thrown.connect(_on_answer_thrown)
	add_child(thrower)


func _build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)

	var back := UiKit.button(Strings.BACK, 26, Color("#495057"))
	back.position = Vector2(16, 14)
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://main/Main.tscn"))
	ui.add_child(back)

	coins_label = UiKit.label("", 32, Color("#e67700"), 8)
	coins_label.add_theme_color_override("font_outline_color", Color.WHITE)
	coins_label.position = Vector2(200, 24)
	ui.add_child(coins_label)

	stage_label = UiKit.label("", 24, UiKit.INK)
	stage_label.position = Vector2(430, 30)
	ui.add_child(stage_label)

	index_button = UiKit.button("", 26, Color("#1971c2"))
	index_button.position = Vector2(780, 14)
	index_button.pressed.connect(func() -> void: index_page.open(biome))
	ui.add_child(index_button)

	pen_button = UiKit.button(Strings.PEN, 26, Color("#9c36b5"))
	pen_button.position = Vector2(1100, 14)
	pen_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://ui/Pen.tscn"))
	ui.add_child(pen_button)

	bubble = UiKit.panel(Color.WHITE, 30)
	bubble.position = Vector2(500, 140)
	bubble_text = UiKit.rich(42, 640)
	bubble.add_child(bubble_text)
	bubble.visible = false
	ui.add_child(bubble)

	drag_hint = UiKit.label(Strings.DRAG_HINT, 22, UiKit.INK)
	drag_hint.position = Vector2(90, 685)
	ui.add_child(drag_hint)

	toast = UiKit.label("", 54, Color.WHITE, 14)
	toast.add_theme_color_override("font_outline_color", Color("#2b8a3e"))
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.size = Vector2(1280, 80)
	toast.position = Vector2(0, 300)
	toast.visible = false
	ui.add_child(toast)

	hint_panel = UiKit.panel()
	hint_panel.position = Vector2(200, 110)
	hint_panel.custom_minimum_size = Vector2(880, 0)
	hint_box = VBoxContainer.new()
	hint_box.add_theme_constant_override("separation", 14)
	hint_panel.add_child(hint_box)
	hint_panel.visible = false
	ui.add_child(hint_panel)

	debug_label = UiKit.label("", 18, Color.WHITE, 6)
	debug_label.position = Vector2(860, 560)
	debug_label.visible = false
	ui.add_child(debug_label)

	index_page = AnimalIndex.new()
	ui.add_child(index_page)

	_refresh_hud()


func _refresh_hud() -> void:
	coins_label.text = Strings.COINS % GameState.progress.coins
	var total := session.animals.size()
	index_button.text = "%s  %d/%d" % [Strings.INDEX, GameState.progress.collected_count(biome), total]
	if not session.current.is_empty():
		stage_label.text = "%s · %s" % [GameState.BIOME_NAMES.get(biome, biome), Strings.STAGE_NAMES.get(session.current.stage, "")]
	var lines := ["F3 debug (team only)"]
	for s in session.stages:
		var w := GameState.progress.stage_window(biome, s)
		lines.append("%s: %d%% of last %d %s" % [s, int(GameState.progress.stage_accuracy(biome, s) * 100), w.size(),
			"OK" if GameState.progress.stage_met(biome, s) else ""])
	lines.append("mode: %s" % ("mixed" if session.mixed else "stage %d" % (session.stage_index + 1)))
	debug_label.text = "\n".join(lines)


# ---------------------------------------------------------------- one round

func _next_round() -> void:
	session.next_sentence()
	animal.setup(session.current_animal, 70)
	animal.position = Vector2(OFFSCREEN_X, ANIMAL_SPOT.y)
	animal.rotation = 0.0
	animal.scale = Vector2.ONE
	animal.visible = true
	thrower.set_choices(session.current_choices)
	_refresh_hud()

	var t := create_tween()
	t.tween_property(animal, "position", ANIMAL_SPOT, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await t.finished
	bubble_text.text = _sentence_text("[color=#adb5bd]_____[/color]")
	bubble.visible = true
	thrower.enabled = true
	_shown_at_ms = Time.get_ticks_msec()

	if autoplay:
		await _maybe_snap("02_sentence")
		await get_tree().create_timer(0.4).timeout
		_simulate_drag(_autoplay_choice())


func _sentence_text(fill: String) -> String:
	return session.current.sentence.replace("___", fill)


func _on_answer_thrown(chosen: String) -> void:
	var item := session.current
	var ms := Time.get_ticks_msec() - _shown_at_ms
	var r := session.answer(chosen)
	SaveManager.log_answer({
		"biome": biome, "item": item.id, "pair": item.pair, "stage": item.stage,
		"chosen": chosen, "correct": r.correct, "hint_level": r.hint_level, "ms": ms,
		"animal": r.animal_id, "coins": GameState.progress.coins,
	})
	SaveManager.save_game()
	_turn += 1
	if r.correct:
		await _celebrate(r)
	else:
		await _walk_away(r)


func _celebrate(r: Dictionary) -> void:
	bubble_text.text = _sentence_text("[color=#2b8a3e][b]%s[/b][/color]" % session.current.answer)
	_show_toast("%s  %s" % [Strings.CORRECT, Strings.COINS_EARNED % r.coins])
	_refresh_hud()
	var t := create_tween()
	t.tween_property(animal, "position:y", ANIMAL_SPOT.y - 70, 0.16)
	t.tween_property(animal, "position:y", ANIMAL_SPOT.y, 0.16)
	t.tween_property(animal, "position:y", ANIMAL_SPOT.y - 40, 0.12)
	t.tween_property(animal, "position:y", ANIMAL_SPOT.y, 0.12)
	await t.finished
	if autoplay:
		await _maybe_snap("03_correct")
	await get_tree().create_timer(0.5).timeout
	bubble.visible = false

	var pen_center := pen_button.position + pen_button.size / 2.0
	t = create_tween()
	t.tween_property(animal, "position", pen_center, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(animal, "scale", Vector2(0.15, 0.15), 0.7)
	await t.finished
	animal.visible = false

	if r.new_animal:
		_show_toast(Strings.NEW_FRIEND % session.current_animal.get("name", ""), 1.2)
		await get_tree().create_timer(1.0).timeout
	if r.cleared:
		var opened := GameState.unlock_next(biome)
		if opened != "":
			_show_toast(Strings.UNLOCKED % GameState.BIOME_NAMES.get(opened, opened), 2.0)
			await get_tree().create_timer(2.0).timeout
	await _after_round()


func _walk_away(r: Dictionary) -> void:
	var t := create_tween()
	for angle in [0.18, -0.18, 0.12, 0.0]:
		t.tween_property(animal, "rotation", angle, 0.12)
	t.tween_interval(0.3)
	await t.finished
	bubble.visible = false
	t = create_tween()
	t.tween_property(animal, "position:x", OFFSCREEN_X, 0.8)
	await t.finished
	animal.visible = false
	_show_hint(r.hint_level)
	if autoplay:
		await _maybe_snap("04_hint" if r.hint_level == 1 else "05_worked_example")
		await get_tree().create_timer(0.3).timeout
		_close_hint()


func _show_hint(level: int) -> void:
	for c in hint_box.get_children():
		hint_box.remove_child(c)
		c.queue_free()
	var item := session.current
	var title := UiKit.label(Hints.title(item.prev_word), 38, Color("#d9480f"))
	hint_box.add_child(title)
	if level >= 2:
		# Worked example: the steps already include the highlighted letter and the rule.
		hint_box.add_child(UiKit.label(Strings.WORKED_EXAMPLE, 30, UiKit.INK))
		for line in Hints.worked_example(item):
			var l := UiKit.rich(34, 820)
			l.text = line
			hint_box.add_child(l)
	else:
		var sentence := UiKit.rich(44, 820)
		sentence.text = Hints.highlighted_sentence(item, "_____")
		hint_box.add_child(sentence)
		var rule := UiKit.rich(34, 820)
		rule.text = "[b]%s[/b]" % Hints.rule_line(item.prev_word)
		hint_box.add_child(rule)
	hint_box.add_child(UiKit.label(Strings.COMES_BACK, 24, Color("#495057")))
	var ok := UiKit.button(Strings.OK, 32)
	ok.custom_minimum_size = Vector2(200, 70)
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ok.pressed.connect(_close_hint)
	hint_box.add_child(ok)
	hint_panel.visible = true
	hint_panel.reset_size()
	hint_panel.call_deferred("reset_size")  # again after the text has been laid out


func _close_hint() -> void:
	if not hint_panel.visible:
		return
	hint_panel.visible = false
	await _after_round()


func _after_round() -> void:
	_refresh_hud()
	if autoplay and _turn >= AUTOPLAY_TURNS:
		await _finish_autoplay()
		return
	await get_tree().create_timer(0.3).timeout
	_next_round()


func _show_toast(text: String, seconds: float = 1.0) -> void:
	toast.text = text
	toast.modulate.a = 1.0
	toast.visible = true
	var t := create_tween()
	t.tween_interval(seconds)
	t.tween_property(toast, "modulate:a", 0.0, 0.3)
	t.tween_callback(func() -> void: toast.visible = false)


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F3:
		debug_label.visible = not debug_label.visible


# ---------------------------------------------------------------- autoplay

## Mostly the preferred form; misses turn 2, and misses that same sentence again when it
## comes back, so both hint levels appear.
func _autoplay_choice() -> String:
	var item := session.current
	var right: String = item.answer
	var d := DRRule.d_form(right)
	var wrong: String = DRRule.r_form(right) if right == d else d
	if _turn == 1:
		_first_miss_id = item.id
		return wrong
	if item.id == _first_miss_id and int(session.misses.get(item.id, 0)) == 1:
		return wrong
	return right


## Sends real touch events (press, drag, release) so the same input code a learner uses is tested.
func _simulate_drag(answer: String) -> void:
	for f in thrower.foods:
		if f.answer != answer:
			continue
		var start := f.global_position
		var press := InputEventScreenTouch.new()
		press.position = start
		press.pressed = true
		Input.parse_input_event(press)
		var drag := InputEventScreenDrag.new()
		drag.position = start + Vector2(90, -90)
		Input.parse_input_event(drag)
		var release := InputEventScreenTouch.new()
		release.position = drag.position
		release.pressed = false
		Input.parse_input_event(release)
		return


func _maybe_snap(shot: String) -> void:
	if _snapped.has(shot):
		return
	_snapped[shot] = true
	await DebugTools.snap(self, shot)


func _finish_autoplay() -> void:
	debug_label.visible = true
	_refresh_hud()
	index_page.open(biome)
	await _maybe_snap("06_index")
	print("AUTOPLAY forest: turns=%d coins=%d animals=%d/%d" % [_turn, GameState.progress.coins,
		GameState.progress.collected_count(biome), session.animals.size()])
	get_tree().change_scene_to_file("res://ui/Pen.tscn")
