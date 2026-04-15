extends CanvasLayer
@onready var resume_button = $Panel/MarginContainer/VBoxContainer/ResumeButton
@onready var quit_button = $Panel/MarginContainer/VBoxContainer/QuitButton
@onready var quit_message = $QuitGameMessage
@onready var pause_menu = $Panel


func _ready():
	resume_button.pressed.connect(_on_resume)
	quit_button.pressed.connect(_on_quit)
	quit_message.resume_match.connect(_on_resume_match)

func _on_resume_match():
	# hide everything
	resume_button.pressed.connect(_on_resume)
	GameState.unpause_game()
	quit_message.visible = false
	pause_menu.visible = true
	hide()
	

func _on_resume():
	GameState.unpause_game()
	hide()

func _on_quit():
	# show message
	quit_message.visible = true
	pause_menu.visible = false


func _on_win_button_pressed() -> void:
	Music.play_button_sound()
	hide()
	if GameManager.Mode.Local or GameManager.Mode.AI:
		GameState.force_game_over("o")
	elif GameManager.Mode.Multiplayer:
		if multiplayer.is_server():
			GameState.force_game_over("x")
		else:
			GameState.force_game_over("o")
			
func _on_lose_button_pressed() -> void:
	Music.play_button_sound()
	hide()
	if GameManager.Mode.Local or GameManager.Mode.AI:
		GameState.force_game_over("x")
	elif GameManager.Mode.Multiplayer:
		if multiplayer.is_server():
			GameState.force_game_over("o")
		else:
			GameState.force_game_over("x")
