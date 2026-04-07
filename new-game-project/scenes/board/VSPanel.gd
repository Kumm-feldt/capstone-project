extends Control

@onready var player_1 = $Panel/HBoxContainer/Player1Label
@onready var player_2 = $Panel/HBoxContainer/Player2Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if GameManager.GAME_MODE == GameManager.Mode.AI:
		player_1.text = GameManager.username
		player_2.text = "CPU"
	elif GameManager.GAME_MODE == GameManager.Mode.Multiplayer:
		player_1.text = GameManager.username
		player_2.text = GameManager.multiplayer_username
