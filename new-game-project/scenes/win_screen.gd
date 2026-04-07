extends Control

@onready var winner_label = $PanelContainer/MarginContainer/VBoxContainer/WinnerLabel
@onready var play_again_button = $PanelContainer/MarginContainer/VBoxContainer/PlayAgainButton
@onready var main_menu_button = $PanelContainer/MarginContainer/VBoxContainer/MainMenuButton
@onready var quit_button = $PanelContainer/MarginContainer/VBoxContainer/QuitButton

func _ready():
	
	play_again_button.pressed.connect(_on_play_again)
	main_menu_button.pressed.connect(_on_main_menu)
	quit_button.pressed.connect(_on_quit)
	
func setup(player: String):
	var winner 
	if GameManager.GAME_MODE == GameManager.Mode.Multiplayer:
		# fall backs 
		if not GameManager.multiplayer_username:
			GameManager.multiplayer_username = "unknown"
		if not GameManager.username:
			GameManager.username = "my name"
		# if it is hosting, special case
		if GameManager.hosting:
			winner = "You Won!" if player == "x" else GameManager.multiplayer_username +" Wins!"
		else:
			winner = GameManager.multiplayer_username+" Wins!" if player == 'x' else "You Won!"
	elif GameManager.GAME_MODE == GameManager.Mode.AI:
		winner = "You Won!" if player == 'x' else "CPU Wins!"
	winner_label.text = winner

func _on_play_again():
	GameState.reset_game()
	get_tree().change_scene_to_file("res://Board.tscn")  

func _on_main_menu():
	get_tree().change_scene_to_file("res://MainMenu.tscn")  # adjust to your main menu path

func _on_quit():
	GameState.reset_game()
	hide()
	get_tree().change_scene_to_file("res://scenes/GameMode/GameMode.tscn")  # adjust to your main menu path
