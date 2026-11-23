class_name BiomeBackground
extends Node2D
## Placeholder scenery drawn with shapes (owner: Loraine for layout, Alex for art).

const PALETTES := {
	"forest": {"sky": Color("#a5d8ff"), "ground": Color("#8ce99a"), "far": Color("#69db7c"), "tree": Color("#2b8a3e")},
	"river": {"sky": Color("#c5f6fa"), "ground": Color("#b2f2bb"), "far": Color("#74c0fc"), "tree": Color("#1971c2")},
	"mountain": {"sky": Color("#e7f5ff"), "ground": Color("#d8f5a2"), "far": Color("#adb5bd"), "tree": Color("#495057")},
	"sky": {"sky": Color("#d0bfff"), "ground": Color("#f8f9fa"), "far": Color("#e5dbff"), "tree": Color("#9775fa")},
}

var biome := "forest"


func _draw() -> void:
	var p: Dictionary = PALETTES.get(biome, PALETTES.forest)
	draw_rect(Rect2(0, 0, 1280, 720), p.sky)
	for x in [80, 300, 560, 820, 1080, 1300]:
		draw_circle(Vector2(x, 520), 150, p.far)
	draw_rect(Rect2(0, 500, 1280, 220), p.ground)
	for x in [60, 470, 700, 1220]:
		draw_rect(Rect2(x - 14, 380, 28, 130), Color("#8d5a3b"))
		draw_circle(Vector2(x, 360), 70, p.tree)
		draw_circle(Vector2(x - 40, 400), 50, p.tree.lightened(0.1))
		draw_circle(Vector2(x + 40, 400), 50, p.tree.darkened(0.1))
