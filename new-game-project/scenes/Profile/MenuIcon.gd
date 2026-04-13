extends Control

@onready var scoreBoardButton = $ScoreboardButton
@onready var settingsButton = $SettingsButton
@onready var vMenuSprite = $HamburguerMenuButton/VerticalSprite
@onready var hMenuSprite = $HamburguerMenuButton/HorizontalSprite

signal show_settings

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_menu_button_pressed() -> void:
	if scoreBoardButton.visible == true:
		scoreBoardButton.visible = false
		settingsButton.visible = false
		hMenuSprite.visible = true
		vMenuSprite.visible = false
		
	else:
		scoreBoardButton.visible = true
		settingsButton.visible = true
		vMenuSprite.visible = true
		hMenuSprite.visible = false
		


func _on_scoreboard_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ScoreBoard/ScoreBoard.tscn")


func _on_settings_button_pressed() -> void:
	emit_signal("show_settings")
		# Prevent stacking multiple popups
	
