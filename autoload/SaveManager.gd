extends Node
## Owner: Irish (Systems).
## Offline save to the device (user://). No internet, no accounts.

const SAVE_PATH := "user://save.json"
const LOG_PATH := "user://play_log.jsonl"


func _ready() -> void:
	load_game()


func save_game() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("Save failed: %s" % FileAccess.get_open_error())
		return
	f.store_string(JSON.stringify(GameState.to_dict()))


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if data is Dictionary:
		GameState.from_dict(data)


## One line per answer. Used later for the validation data (error counts per pair).
## TODO(Irish): agree the exact fields with Jian so they match the research instruments.
func log_answer(item_id: String, chosen: String, correct: bool) -> void:
	var f: FileAccess
	if FileAccess.file_exists(LOG_PATH):
		f = FileAccess.open(LOG_PATH, FileAccess.READ_WRITE)
		f.seek_end()
	else:
		f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_line(JSON.stringify({
		"t": Time.get_datetime_string_from_system(),
		"item": item_id,
		"chosen": chosen,
		"correct": correct,
	}))
