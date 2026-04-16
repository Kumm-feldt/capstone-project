extends Control

signal resume_match
signal match_left
signal ready_to_leave
const menu_panel_scene = preload("res://scenes/MainMenu/menu_panel.tscn")

@onready var quit_game_mult = $QuiteGameMessage/MultiplayerQuitLabel

func _ready() -> void:
	if GameManager.GAME_MODE == GameManager.Mode.Multiplayer:
		if GameManager.current_score < 100:
			quit_game_mult.text = "This action might result in a penalty."
		quit_game_mult.visible = true


func _on_resume_button_pressed() -> void:
	Music.play_button_sound()
	emit_signal("resume_match")

func _on_leave_button_pressed() -> void:	
	# User left the match
	# If already disconnected (other player left first), just go to menu
	Music.play_button_sound()
	GameState.reset_game()
	
	print("this allows to exit")
	if GameManager.GAME_MODE == GameManager.Mode.Local or  GameManager.GAME_MODE == GameManager.Mode.AI:
		# show loading scene...
		var canvas = CanvasLayer.new()
		canvas.layer = 100  # on top of everything
		get_tree().root.add_child(canvas)
		
		var menu_panel = menu_panel_scene.instantiate()
		canvas.add_child(menu_panel)
		
		menu_panel.toggleLoadingScreen()
		await get_tree().create_timer(1).timeout

		menu_panel.queue_free()
		
		get_tree().change_scene_to_file("res://scenes/GameMode/GameMode.tscn")
	else:
		if multiplayer.multiplayer_peer == null:
			get_tree().change_scene_to_file("res://scenes/GameMode/GameMode.tscn")
			return
			
		if (multiplayer.is_server()):
			GameManager.hosting = false
			print("about to call leave_match_as_host")
			NetworkManager.leave_match_as_host()
		else:
			print("about to call leave_match_as_client")
			NetworkManager.leave_match_as_client()
	
	
