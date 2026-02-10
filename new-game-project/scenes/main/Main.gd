# scenes/main/Main.gd
# Attached to Main (Node2D) root node
extends Node2D

#@onready var turn_label = $CanvasLayer/UI/TurnLabel
#@onready var debug_label = $CanvasLayer/UI/DebugLabel
#@onready var reset_button = $CanvasLayer/UI/ResetButton

func _ready():
	# Connect to GameState
	GameState.connect("turn_changed", _on_turn_changed)
	GameState.connect("game_over", _on_game_over)
	
	# Connect UI
	#reset_button.pressed.connect(_on_reset_pressed)
	
	update_ui()

func update_ui():
	"""Update UI labels"""


func _on_turn_changed(_player: String):
	"""Handle turn change"""


func _on_game_over(_winner: String):
	"""Handle game over"""


func _on_reset_pressed():
	"""Reset game button"""


func _process(_delta):
	"""Debug display (remove for production)"""
	
