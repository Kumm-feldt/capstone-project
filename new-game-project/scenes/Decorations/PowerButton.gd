extends Node2D
signal turn_off_light  # declare the signal

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _on_power_button_pressed() -> void:
	emit_signal("turn_off_light")
