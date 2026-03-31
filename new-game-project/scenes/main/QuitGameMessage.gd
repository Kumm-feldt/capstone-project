extends Control

signal resume_match
signal match_left

func _on_resume_button_pressed() -> void:
	emit_signal("resume_match")

func _on_leave_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/GameMode/GameMode.tscn")
	emit_signal("match_left")
