extends CanvasLayer
const WinScreen = preload("res://scenes/WinScreen.tscn")
@onready var turn_label = $PanelContainer/MarginContainer/Control/TurnLabel
@onready var invalid_label = $PanelContainer/MarginContainer/Control/InvalidaLabel
@onready var pause_button = $PanelContainer/MarginContainer/Control/PauseButton
@onready var pause_menu = $"/root/Main/PauseMenu"


func _ready() -> void:
	GameState.connect("turn_changed", _on_turn_changed)
	GameState.connect("invalid_move", _on_invalid_move)
	GameState.connect("valid_move", _on_valid_move)
	GameState.connect("game_paused_changed", _on_pause_changed)
	pause_button.pressed.connect(_on_pause_button_pressed)
	GameState.connect("game_over", _on_game_over)
func _on_pause_button_pressed():
	GameState.toggle_pause()

func _on_pause_changed(is_paused: bool):
	#pause_button.text = "Resume" if is_paused else "Pause"
	if is_paused:
		pause_menu.show()
	else:
		pause_menu.hide()

func _on_turn_changed(player):
	var player_color = "Red" if player == 'o' else "Blue"
	turn_label.text = "%s's turn" % player_color

func _on_invalid_move(text):
	invalid_label.text = text

func _on_valid_move():
	invalid_label.text = ""
	
func _on_game_over(winner: String):
	var win_screen = WinScreen.instantiate()
	get_tree().root.add_child(win_screen)
	win_screen.setup(winner)
