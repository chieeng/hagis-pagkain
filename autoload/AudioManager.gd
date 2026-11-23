extends Node
## Owner: Alex (UI/Art/Audio). Lead reviews.
## Central place to play sound effects so scenes don't each manage players.

var _player := AudioStreamPlayer.new()


func _ready() -> void:
	add_child(_player)


## TODO(Alex): load real sounds, e.g. preload("res://assets/sfx/correct.ogg").
func play_sfx(stream: AudioStream) -> void:
	if stream == null:
		return
	_player.stream = stream
	_player.play()
