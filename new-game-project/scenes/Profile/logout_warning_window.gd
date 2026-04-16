extends Control


func _on_accept_button_pressed() -> void:
	DirAccess.remove_absolute("user://save.cfg")
	# send to main board
	get_tree().change_scene_to_file("res://scenes/MainMenu/MainMenu.tscn")
	
