extends Node2D
## Owner: Lead.
## Entry scene. For now it only proves the autoloads work.
## TODO(Lead): replace with MainMenu (Alex) -> BiomeMap -> biome scene once those exist.


func _ready() -> void:
	$Status.text = "Hagis Pagkain\nItems loaded: %d (forest: %d)\nScore: %d" % [
		QuestionBank.count(),
		QuestionBank.get_items("forest").size(),
		GameState.score,
	]
