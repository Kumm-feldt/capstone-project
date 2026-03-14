# scenes/main/Main.gd
# Attached to Main (Node2D) root node
extends Node2D
var win_screen_scene = preload("res://scenes/WinScreen.tscn")
#@onready var turn_label = $CanvasLayer/UI/TurnLabel
#@onready var debug_label = $CanvasLayer/UI/DebugLabel
#@onready var reset_button = $CanvasLayer/UI/ResetButton
@onready var dim_overlay = $DimOverlay

var WIN_POINTS = 100
var LOSS_POINTS = 30


func _ready():
	# Connect to GameState
	dim_overlay.visible = false
	GameState.connect("game_over", _on_game_over)
	

func _on_turn_changed(_player: String):
	"""Handle turn change"""

func _on_game_over(winner: String):
	var canvas = CanvasLayer.new()
	canvas.layer = 10  # renders above everything
	get_tree().root.add_child(canvas)
	var win_screen = win_screen_scene.instantiate()
	canvas.add_child(win_screen)
	win_screen.set_anchors_preset(Control.PRESET_CENTER)
	win_screen.setup(winner)

	if (GameManager.GAME_MODE == GameManager.Mode.AI ):
		print("username: ", GameManager.username)
		DBService.update_user_info(GameManager.username, "add", WIN_POINTS)
	elif(GameManager.GAME_MODE == GameManager.Mode.Multiplayer):
		print("multi")

	
func _on_reset_pressed():
	"""Reset game button"""


func _process(_delta):
	"""Debug display (remove for production)"""
	
