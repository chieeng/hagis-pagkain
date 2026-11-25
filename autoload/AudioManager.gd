extends Node
## Owner: Alex (UI/Art/Audio). Lead reviews.
## Sound effects. Until real sounds exist, simple placeholder sounds are made in code
## (no files, works offline). Replace with .ogg files later: play("name") stays the same.

const RATE := 22050
const POOL := 6

var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _cache := {}
var enabled := true


func _ready() -> void:
	for i in POOL:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)


## Plays a sound by name: whoosh, hit, correct, rare, golden, miss, coin, perfect, tick, combo, buy.
func play(sfx_name: String, pitch: float = 1.0) -> void:
	if not enabled or DisplayServer.get_name() == "headless":
		return
	if not _cache.has(sfx_name):
		_cache[sfx_name] = _make(sfx_name)
	var p := _players[_next]
	_next = (_next + 1) % POOL
	p.stream = _cache[sfx_name]
	p.pitch_scale = pitch
	p.play()


func play_sfx(stream: AudioStream) -> void:
	if stream == null:
		return
	var p := _players[_next]
	_next = (_next + 1) % POOL
	p.stream = stream
	p.play()


func _make(sfx_name: String) -> AudioStreamWAV:
	match sfx_name:
		"whoosh":
			return _noise(0.45, 0.5, true)
		"hit":
			return _notes([[160.0, 0.08]], "square", 0.35)
		"correct":
			return _notes([[523.0, 0.09], [659.0, 0.09], [784.0, 0.18]], "square", 0.3)
		"rare":
			return _notes([[523.0, 0.08], [659.0, 0.08], [784.0, 0.08], [1047.0, 0.25]], "square", 0.32)
		"golden":
			return _notes([[392.0, 0.08], [523.0, 0.08], [659.0, 0.08], [784.0, 0.08], [1047.0, 0.08], [1319.0, 0.35]], "square", 0.34)
		"miss":
			return _notes([[330.0, 0.12], [262.0, 0.2]], "sine", 0.35)
		"coin":
			return _notes([[988.0, 0.05], [1319.0, 0.12]], "square", 0.22)
		"perfect":
			return _notes([[880.0, 0.06], [1175.0, 0.06], [1760.0, 0.16]], "sine", 0.35)
		"tick":
			return _notes([[700.0, 0.03]], "sine", 0.15)
		"combo":
			return _notes([[659.0, 0.06], [880.0, 0.06], [1319.0, 0.14]], "square", 0.28)
		"buy":
			return _notes([[440.0, 0.06], [660.0, 0.06], [880.0, 0.06], [1320.0, 0.15]], "sine", 0.32)
		"drum":
			return _noise(0.6, 0.25, false, 18.0)
	return _notes([[440.0, 0.1]], "sine", 0.2)


## A short melody: [[frequency, seconds], ...]
func _notes(notes: Array, wave: String, volume: float) -> AudioStreamWAV:
	var data := PackedByteArray()
	for n in notes:
		var freq: float = n[0]
		var count := int(RATE * float(n[1]))
		for i in count:
			var t := float(i) / RATE
			var env: float = min(1.0, i / 200.0) * (1.0 - float(i) / count)
			var s := sin(TAU * freq * t)
			if wave == "square":
				s = 0.6 * signf(s) + 0.4 * s
			_push(data, s * env * volume)
	return _wav(data)


## Noise: a whoosh (fading in and out) or a drum roll (pulsing).
func _noise(seconds: float, volume: float, sweep: bool, pulses: float = 0.0) -> AudioStreamWAV:
	var data := PackedByteArray()
	var count := int(RATE * seconds)
	var rng := RandomNumberGenerator.new()
	var last := 0.0
	for i in count:
		var k := float(i) / count
		var env := sin(PI * k) if sweep else (0.5 + 0.5 * sin(TAU * pulses * k * seconds)) * (0.4 + 0.6 * k)
		var smooth := 0.15 + 0.6 * k if sweep else 0.5   # rising pitch for the whoosh
		last = lerp(last, rng.randf_range(-1.0, 1.0), smooth)
		_push(data, last * env * volume)
	return _wav(data)


func _push(data: PackedByteArray, s: float) -> void:
	var v := int(clamp(s, -1.0, 1.0) * 32767.0)
	data.append(v & 0xFF)
	data.append((v >> 8) & 0xFF)


func _wav(data: PackedByteArray) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	return w
