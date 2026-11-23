extends Node
## Owner: Lead.
## Holds the player's progress for the current session. SaveManager persists it.
## Other scripts read/write progress ONLY through this autoload.

signal score_changed(new_score: int)
signal biome_completed(biome: String, stars: int)

## Biome order = unlock order. Pairs per biome are fixed by the proposal.
const BIOMES := {
	"forest": ["din/rin"],
	"river": ["daw/raw"],
	"mountain": ["dito/rito", "diyan/riyan"],
	"sky": ["doon/roon", "exceptions"],
}
const BIOME_ORDER := ["forest", "river", "mountain", "sky"]

var current_biome: String = "forest"
var score: int = 0
## biome -> best stars (0-3)
var stars: Dictionary = {}
## biome -> true
var unlocked: Dictionary = {"forest": true}


func add_score(points: int) -> void:
	score += points
	score_changed.emit(score)


func complete_biome(biome: String, earned_stars: int) -> void:
	stars[biome] = max(int(stars.get(biome, 0)), earned_stars)
	var i := BIOME_ORDER.find(biome)
	if i >= 0 and i + 1 < BIOME_ORDER.size():
		unlocked[BIOME_ORDER[i + 1]] = true
	biome_completed.emit(biome, earned_stars)
	SaveManager.save_game()


func is_unlocked(biome: String) -> bool:
	return unlocked.get(biome, false)


func to_dict() -> Dictionary:
	return {"score": score, "stars": stars, "unlocked": unlocked}


func from_dict(data: Dictionary) -> void:
	score = int(data.get("score", 0))
	stars = data.get("stars", {})
	unlocked = data.get("unlocked", {"forest": true})
