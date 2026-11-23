extends Node
## Owner: Lead.
## The live Progress for this play session. SaveManager saves and loads it.

signal biome_unlocked(biome: String)

## Biome order = unlock order. Pairs per biome are fixed by the proposal.
const BIOMES := {
	"forest": ["din/rin"],
	"river": ["daw/raw"],
	"mountain": ["dito/rito", "diyan/riyan"],
	"sky": ["doon/roon", "exceptions"],
}
const BIOME_ORDER: Array[String] = ["forest", "river", "mountain", "sky"]
const BIOME_NAMES := {"forest": "Gubat", "river": "Ilog", "mountain": "Bundok", "sky": "Himpapawid"}
## Biomes that have a playable scene in this build.
const BIOME_SCENES := {"forest": "res://biomes/forest/Forest3D.tscn"}
## Lesson shown before a biome the first time.
const LESSON_SCENE := "res://ui/Lesson.tscn"

var progress := Progress.new()


func is_unlocked(biome: String) -> bool:
	return progress.unlocked.get(biome, false)


func next_biome(biome: String) -> String:
	var i := BIOME_ORDER.find(biome)
	return BIOME_ORDER[i + 1] if i >= 0 and i + 1 < BIOME_ORDER.size() else ""


## Unlocks the biome after `biome`. Returns its id, or "" if nothing new was unlocked.
func unlock_next(biome: String) -> String:
	var nb := next_biome(biome)
	if nb == "" or is_unlocked(nb):
		return ""
	progress.unlocked[nb] = true
	biome_unlocked.emit(nb)
	SaveManager.save_game()
	return nb


func to_dict() -> Dictionary:
	return progress.to_dict()


func from_dict(data: Dictionary) -> void:
	progress.from_dict(data)
