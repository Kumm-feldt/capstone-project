# scenes/main/Main.gd
# Attached to Main (Node2D) root node
extends Node2D

@onready var turn_label = $CanvasLayer/UI/TurnLabel
@onready var debug_label = $CanvasLayer/UI/DebugLabel
@onready var reset_button = $CanvasLayer/UI/ResetButton

func _ready():
	# Connect to GameState
	GameState.connect("turn_changed", _on_turn_changed)
	GameState.connect("game_over", _on_game_over)
	
	# Connect UI
	reset_button.pressed.connect(_on_reset_pressed)
	
	update_ui()

func update_ui():
	"""Update UI labels"""
	var player_name = "Gold" if GameState.current_player == "o" else "Silver"
	turn_label.text = "Turn: " + player_name

func _on_turn_changed(player: String):
	"""Handle turn change"""
	update_ui()

func _on_game_over(winner: String):
	"""Handle game over"""
	var winner_name = "Gold" if winner == "o" else "Silver"
	turn_label.text = "Game Over! Winner: " + winner_name

func _on_reset_pressed():
	"""Reset game button"""
	GameState.reset_game()
	update_ui()

func _process(_delta):
	"""Debug display (remove for production)"""
	if debug_label:
		debug_label.text = "Player: %s\nFPS: %d" % [GameState.current_player, Engine.get_frames_per_second()]
