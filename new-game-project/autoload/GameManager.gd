extends Node

var GAME_MODE = null
var AI_MODE_LEVEL = null


enum Mode {
	Local,
	AI,
	Join,
	Host
}

enum AILevel {
	Easy,
	Difficult
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
