class_name ThrowController
extends Node2D
## Owner: Lead (gameplay).
## Reads the learner's touch/drag and throws the chosen FoodItem.
## TODO(Lead): drag-to-aim, release-to-throw. Keep it forgiving: Grade 4 hands, small phones.

## Emitted after a throw lands. BiomeTemplate listens to this.
signal answer_thrown(answer: String)
