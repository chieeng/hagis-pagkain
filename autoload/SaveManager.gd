extends Node
## Owner: Irish (Systems).
## Offline save to the device (user://). No internet, no accounts.
## Run with `-- --nosave` to play without touching the save or the log (used by autoplay checks).

const SAVE_PATH := "user://save.json"
const LOG_PATH := "user://play_log.jsonl"

var enabled := not "--nosave" in OS.get_cmdline_user_args()


func _ready() -> void:
	load_game()


func save_game() -> void:
	if not enabled:
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("Save failed: %s" % FileAccess.get_open_error())
		return
	f.store_string(JSON.stringify(GameState.to_dict()))


func load_game() -> void:
	if not enabled or not FileAccess.file_exists(SAVE_PATH):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if data is Dictionary:
		GameState.from_dict(data)


## One JSON line per throw, for the evaluation data [proposal, "Data tracked"]:
## first-throw accuracy per pair/context/biome, hints shown, time per answer.
## TODO(Irish + Jian): add session id and streaks; agree the final fields with the research instruments.
func log_answer(entry: Dictionary) -> void:
	if not enabled:
		return
	var f: FileAccess
	if FileAccess.file_exists(LOG_PATH):
		f = FileAccess.open(LOG_PATH, FileAccess.READ_WRITE)
		f.seek_end()
	else:
		f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f == null:
		return
	entry["t"] = Time.get_datetime_string_from_system()
	f.store_line(JSON.stringify(entry))
