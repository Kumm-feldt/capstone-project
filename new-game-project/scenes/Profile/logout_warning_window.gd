extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_accept_button_pressed() -> void:
	DirAccess.remove_absolute("user://save.cfg")
	# send to main board
	get_tree().change_scene_to_file("res://scenes/MainMenu/MainMenu.tscn")
	
