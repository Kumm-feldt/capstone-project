extends Control

signal resume_match
signal match_left
@onready var quit_game_mult = $QuiteGameMessage/MultiplayerQuitLabel

func _ready() -> void:
	if GameManager.GAME_MODE == GameManager.Mode.Multiplayer:
		if GameManager.current_score < 100:
			quit_game_mult.text = "This action might result in a penalty."
		quit_game_mult.visible = true

func _on_resume_button_pressed() -> void:
	emit_signal("resume_match")

func _on_leave_button_pressed() -> void:
	#get_tree().change_scene_to_file("res://scenes/GameMode/GameMode.tscn")
	
	# User left the match
	if (multiplayer.is_server()):
		NetworkManager.leave_match_as_host()
	else:
		NetworkManager.leave_match_as_client()
	
	
