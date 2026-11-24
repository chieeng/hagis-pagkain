extends Node
## Owner: Lead.
## The live Progress for this play session. SaveManager saves and loads it.

signal biome_unlocked(biome: String)

## Biome order = unlock order. Pairs per biome are fixed by the proposal.
const BIOMES := {
	"forest": ["din/rin"],
	"river": ["daw/raw"],
	"mountain": ["dito/rito", "diyan/riyan"],
	"sky": ["doon/roon", "espesyal"],
	"island": ["lahat"],   # mixed review of every pair [proposal]; "Isla" is a placeholder name
}
const BIOME_ORDER: Array[String] = ["forest", "river", "mountain", "sky", "island"]
const BIOME_NAMES := {"forest": "Gubat", "river": "Ilog", "mountain": "Bundok", "sky": "Himpapawid", "island": "Isla"}
## Biomes that have a playable scene in this build.
const BIOME_SCENES := {
	"forest": "res://biomes/forest/Forest3D.tscn",
	"river": "res://biomes/river/River3D.tscn",
	"mountain": "res://biomes/mountain/Mountain3D.tscn",
	"sky": "res://biomes/sky/Sky3D.tscn",
	"island": "res://biomes/island/Island3D.tscn",
}

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
