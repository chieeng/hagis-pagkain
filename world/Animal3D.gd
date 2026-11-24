class_name Animal3D
extends Node3D
## A blocky animal in the 3D world, wearing the word tag of its sentence (the word before din/rin).
## The deciding last letter of the tag glows in its fruit's colour; `help` (0..1) sets how strongly,
## so the learner first sees the pattern, then has to read the letter alone.
## States:
##   WILD     wanders the forest; stops and looks at the player when they come close
##   FOLLOW   was fed the preferred form; follows the player
##   TO_PEN   walking into the pen
##   IN_PEN   lives in the pen, wanders inside it
##   LEAVING  sniffed the other fruit and walks off the map (comes back later as a new animal)
## Owner: Lead (behaviour), Alex (look).

signal arrived_in_pen(animal: Animal3D)
signal left_map(animal: Animal3D)

enum State { WILD, FOLLOW, TO_PEN, IN_PEN, LEAVING }

const WALK_SPEED := 2.2
const FOLLOW_SPEED := 6.5

var data: Dictionary = {}      ## from data/animals.json
var rarity := "common"         ## "common", "rare" or "golden"
var coins_earned := 0          ## paid when it was fed (shown in the catch popup)
var item: Dictionary = {}      ## the sentence this animal carries (empty when IN_PEN from a save)
var state := State.WILD
var wander_area := Rect2(-24, -26, 48, 30)
var pen_area := Rect2(-14, 8, 8, 8)
var follow_target: Node3D
var follow_slot := 0
var player: Node3D
var help := 1.0                ## 0..1 glow of the deciding letter (Progress.help_level)

var _target := Vector3.ZERO
var _pause := 0.0
var _model: Node3D
var _tag: Label3D
var _tag_end: Label3D          ## the deciding last letter (or last syllable for KWF exceptions)
var _speech: Label3D
var _busy := false   ## playing an eat/sniff animation


func setup(p_data: Dictionary, p_item: Dictionary, p_state: State = State.WILD, p_rarity: String = "common") -> void:
	data = p_data
	item = p_item
	state = p_state
	rarity = p_rarity
	var color := Color(data.get("color", "#c08552"))
	if rarity == "golden":
		color = color.lerp(Color("#ffd43b"), 0.75)
	_model = Node3D.new()
	add_child(_model)
	_model.scale = Vector3.ONE * {"common": 1.0, "rare": 1.2, "golden": 1.4}.get(rarity, 1.0)
	if rarity != "common":
		var badge := Blocky.label3d(self, Strings.RARITY_NAMES.get(rarity, ""), Vector3(0, 3.1, 0), 60,
			Color("#99e9f2") if rarity == "rare" else Color("#ffd43b"))
		badge.name = "Badge"
		# a ring, sparkles and a light pillar so rare/golden animals are spotted from far away
		var glow := Color("#66d9e8") if rarity == "rare" else Color("#fcc419")
		var ring := Blocky.cylinder(self, 1.3, 0.05, glow, Vector3(0, 0.03, 0))
		ring.name = "Ring"
		Fx.sparkles(self, glow).name = "Sparkles"
		Fx.pillar(self, glow).name = "Pillar"
	# Blocky body facing +z
	Blocky.box(_model, Vector3(0.9, 0.7, 1.2), color, Vector3(0, 0.75, 0))
	Blocky.box(_model, Vector3(0.75, 0.7, 0.7), color.lightened(0.08), Vector3(0, 1.3, 0.6))
	Blocky.box(_model, Vector3(0.2, 0.3, 0.12), color.darkened(0.2), Vector3(-0.22, 1.78, 0.5))
	Blocky.box(_model, Vector3(0.2, 0.3, 0.12), color.darkened(0.2), Vector3(0.22, 1.78, 0.5))
	Blocky.box(_model, Vector3(0.14, 0.14, 0.05), Color.WHITE, Vector3(-0.17, 1.4, 0.96))
	Blocky.box(_model, Vector3(0.14, 0.14, 0.05), Color.WHITE, Vector3(0.17, 1.4, 0.96))
	Blocky.box(_model, Vector3(0.07, 0.08, 0.04), Color("#1b1b1b"), Vector3(-0.17, 1.39, 0.99))
	Blocky.box(_model, Vector3(0.07, 0.08, 0.04), Color("#1b1b1b"), Vector3(0.17, 1.39, 0.99))
	Blocky.box(_model, Vector3(0.3, 0.16, 0.1), color.lightened(0.35), Vector3(0, 1.18, 0.98))
	for x in [-0.3, 0.3]:
		for z in [-0.4, 0.4]:
			Blocky.box(_model, Vector3(0.2, 0.45, 0.2), color.darkened(0.25), Vector3(x, 0.22, z))
	Blocky.box(_model, Vector3(0.15, 0.15, 0.35), color.darkened(0.1), Vector3(0, 0.95, -0.7))

	_tag = Blocky.label3d(self, "", Vector3(0, 2.1, 0), 72)
	_tag_end = Blocky.label3d(self, "", Vector3(0, 2.1, 0), 72)
	for l: Label3D in [_tag, _tag_end]:
		l.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM   # bottoms line up when the letter is bigger
	_speech = Blocky.label3d(self, "", Vector3(0, 3.2, 0), 54, Color("#d3f9d8"))
	_speech.outline_modulate = Color("#2b8a3e")
	_refresh_tag()
	_pick_target()


func _refresh_tag() -> void:
	match state:
		State.WILD:
			_word_tag(Color.WHITE)
		State.LEAVING:
			_word_tag(Color("#ffa8a8"))
		State.FOLLOW, State.TO_PEN, State.IN_PEN:
			_tag.text = str(data.get("name", ""))
			_tag.modulate = Color("#ffe066")
			_tag.font_size = 40
			_tag.position = Vector3(0, 1.85, 0)
			_tag_end.text = ""


## "Masaya" -> "Masay" + a glowing "a". The glow colour matches the fruit that completes the sentence.
func _word_tag(base: Color) -> void:
	var word := str(item.get("prev_word", ""))
	var n: int = min(DRRule.deciding_length(word), word.length())
	var stem := word.left(word.length() - n)
	var end := word.right(n)
	var glow := Color(GameConfig.R_COLOR if DRRule.takes_r(word) else GameConfig.D_COLOR)
	_tag.text = stem
	_tag.modulate = base
	_tag_end.text = end
	_tag_end.font_size = 72 + int(round(28.0 * help))
	_tag_end.modulate = base.lerp(glow, help)
	# Place the two labels side by side (the root never rotates, so local x = screen right).
	var font: Font = _tag.font if _tag.font != null else ThemeDB.fallback_font
	var w1 := font.get_string_size(stem, HORIZONTAL_ALIGNMENT_LEFT, -1, _tag.font_size).x * _tag.pixel_size
	var w2 := font.get_string_size(end, HORIZONTAL_ALIGNMENT_LEFT, -1, _tag_end.font_size).x * _tag_end.pixel_size
	var total := w1 + w2
	_tag.position = Vector3(-total / 2.0 + w1 / 2.0, 2.1, 0)
	_tag_end.position = Vector3(total / 2.0 - w2 / 2.0, 2.1, 0)


func set_help(h: float) -> void:
	help = clampf(h, 0.0, 1.0)
	if state == State.WILD or state == State.LEAVING:
		_refresh_tag()


## After a miss: the deciding letter jumps a few times ("look here!").
func blink_letter() -> void:
	var t := create_tween()
	for i in 3:
		t.tween_property(_tag_end, "scale", Vector3.ONE * 1.6, 0.15)
		t.tween_property(_tag_end, "scale", Vector3.ONE, 0.2)


## 0..1, so the world can fade a tag that would hide under the HUD.
func set_tag_alpha(a: float) -> void:
	for l: Label3D in [_tag, _tag_end, _speech]:
		l.modulate.a = a
		l.outline_modulate.a = 0.9 * a
	var badge := get_node_or_null("Badge") as Label3D
	if badge != null:
		badge.modulate.a = a
		badge.outline_modulate.a = 0.9 * a


func is_wild() -> bool:
	return state == State.WILD and not _busy


func _process(delta: float) -> void:
	if _busy:
		return
	match state:
		State.WILD:
			var shy: float = GameConfig.RARITY_SHY_DISTANCE.get(rarity, 3.0)
			var dist := global_position.distance_to(player.global_position) if player != null else INF
			if dist < shy:
				# Too close: back away, so the learner has to throw from a distance.
				var away := global_position - player.global_position
				away.y = 0
				var spot := global_position + away.normalized() * 3.0
				spot.x = clamp(spot.x, wander_area.position.x, wander_area.end.x)
				spot.z = clamp(spot.z, wander_area.position.y, wander_area.end.y)
				_walk_to(spot, delta, WALK_SPEED * 1.6, 0.1)
			elif dist < shy + 6.0:
				_face(player.global_position - global_position, delta)   # stop and wait for a throw
			else:
				_wander(delta, wander_area, WALK_SPEED)
		State.IN_PEN:
			_wander(delta, pen_area, WALK_SPEED * 0.6)
		State.FOLLOW:
			if follow_target != null:
				var back: Vector3 = -follow_target.get("facing") if follow_target.get("facing") != null else Vector3(0, 0, 1)
				var behind := follow_target.global_position + back * (1.8 + follow_slot * 1.6)
				_walk_to(behind, delta, FOLLOW_SPEED, 0.6)
		State.TO_PEN:
			if _walk_to(_target, delta, FOLLOW_SPEED * 0.6, 0.3):
				state = State.IN_PEN
				_refresh_tag()
				arrived_in_pen.emit(self)
		State.LEAVING:
			if _walk_to(_target, delta, WALK_SPEED * 2.0, 0.5):
				left_map.emit(self)
				queue_free()


func _wander(delta: float, area: Rect2, speed: float) -> void:
	if _pause > 0.0:
		_pause -= delta
		return
	if _walk_to(_target, delta, speed, 0.3):
		_pause = randf_range(0.5, 2.0)
		_pick_target(area)


func _pick_target(area: Rect2 = Rect2()) -> void:
	if area.size == Vector2.ZERO:
		area = pen_area if state == State.IN_PEN else wander_area
	for i in 10:
		var p := Vector3(randf_range(area.position.x, area.end.x), 0, randf_range(area.position.y, area.end.y))
		if state == State.IN_PEN or not pen_area.grow(2.0).has_point(Vector2(p.x, p.z)):
			_target = p
			return
	_target = position


## Returns true when close enough to `to`.
func _walk_to(to: Vector3, delta: float, speed: float, stop: float) -> bool:
	var d := to - global_position
	d.y = 0
	if d.length() <= stop:
		return true
	var step: float = min(d.length(), speed * delta)
	global_position += d.normalized() * step
	_face(d, delta)
	_model.position.y = abs(sin(Time.get_ticks_msec() * 0.012)) * 0.12
	return false


func _face(dir: Vector3, delta: float) -> void:
	if dir.length() < 0.01:
		return
	_model.rotation.y = lerp_angle(_model.rotation.y, atan2(dir.x, dir.z), min(1.0, delta * 8.0))


## The moment of suspense after the fruit lands: the animal sniffs while "?" marks float up.
func suspense(seconds: float = 0.7) -> void:
	_busy = true
	for i in 3:
		Fx.float_text(get_parent(), global_position + Vector3(randf_range(-1.0, 1.0), 2.6 + i * 0.3, 0), "?",
			Color("#ffe066"), 110, 1.6, seconds + 0.2)
	var t := create_tween()
	for a in [0.12, -0.12, 0.12, -0.12, 0.0]:
		t.tween_property(_model, "rotation:y", _model.rotation.y + a, seconds / 5.0)
	await t.finished


## Big "pop" when caught: grow, then settle (rarer = bigger).
func pop() -> void:
	var base: Vector3 = _model.scale
	var t := create_tween()
	t.tween_property(_model, "scale", base * 1.6, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_model, "scale", base, 0.25).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	for n in ["Pillar", "Sparkles"]:
		if has_node(n):
			get_node(n).queue_free()


## The preferred form: eat, say the whole sentence, then follow the player.
func eat(target: Node3D, slot: int) -> void:
	_busy = true
	_speech.text = str(item.get("sentence", "")).replace("___", str(item.get("answer", "")))
	var t := create_tween()
	for i in 2:
		t.tween_property(_model, "position:y", 0.7, 0.15)
		t.tween_property(_model, "position:y", 0.0, 0.15)
	t.tween_interval(1.6)
	await t.finished
	_speech.text = ""
	if has_node("Ring"):
		get_node("Ring").visible = false
	state = State.FOLLOW
	follow_target = target
	follow_slot = slot
	_refresh_tag()
	_busy = false


## Not the preferred form: sniff, shake head, walk off the map.
func sniff(exit_point: Vector3) -> void:
	_busy = true
	state = State.LEAVING
	help = 1.0   # show the deciding letter in full colour as it leaves
	_refresh_tag()
	blink_letter()
	var t := create_tween()
	for a in [0.4, -0.4, 0.3, -0.3, 0.0]:
		t.tween_property(_model, "rotation:z", a * 0.5, 0.1)
	t.tween_interval(0.4)
	await t.finished
	_target = exit_point
	_busy = false


func go_to_pen(spot: Vector3) -> void:
	state = State.TO_PEN
	_target = spot
