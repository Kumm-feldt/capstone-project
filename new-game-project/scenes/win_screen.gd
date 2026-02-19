extends Control

@onready var winner_label = $PanelContainer/VBoxContainer/WinnerLabel
@onready var play_again_button = $PanelContainer/VBoxContainer/PlayAgainButton
@onready var main_menu_button = $PanelContainer/VBoxContainer/MainMenuButton
@onready var quit_button = $PanelContainer/VBoxContainer/QuitButton

func _ready():
	play_again_button.pressed.connect(_on_play_again)
	main_menu_button.pressed.connect(_on_main_menu)
	quit_button.pressed.connect(_on_quit)

func setup(winner: String):
	var color = "Red" if winner == "o" else "Blue"
	winner_label.text = "%s Wins!" % color

func _on_play_again():
	GameState.reset_game()
	get_tree().change_scene_to_file("res://Board.tscn")  

func _on_main_menu():
	get_tree().change_scene_to_file("res://MainMenu.tscn")  # adjust to your main menu path

func _on_quit():
	get_tree().quit()
