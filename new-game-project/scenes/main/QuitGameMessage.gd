extends Control

signal resume_match
signal match_left
signal ready_to_leave

@onready var quit_game_mult = $QuiteGameMessage/MultiplayerQuitLabel

func _ready() -> void:
	if GameManager.GAME_MODE == GameManager.Mode.Multiplayer:
		if GameManager.current_score < 100:
			quit_game_mult.text = "This action might result in a penalty."
		quit_game_mult.visible = true




func _on_resume_button_pressed() -> void:
	emit_signal("resume_match")

func _on_leave_button_pressed() -> void:	
	# User left the match
	# If already disconnected (other player left first), just go to menu
	if multiplayer.multiplayer_peer == null:
		get_tree().change_scene_to_file("res://scenes/GameMode/GameMode.tscn")
		return
	if (multiplayer.is_server()):
		print("about to call leave_match_as_host")
		NetworkManager.leave_match_as_host()
	else:
		print("about to call leave_match_as_client")
		NetworkManager.leave_match_as_client()
	
	
