class_name FoodItem
extends Node2D
## Owner: Lead (gameplay).
## One throwable food carrying one answer option (e.g. "din" or "rin").
## TODO(Lead): build FoodItem.tscn (sprite + label + Area2D) and the flight motion.

## Emitted when the food lands on the target.
signal landed(answer: String)

@export var answer: String = "din"
