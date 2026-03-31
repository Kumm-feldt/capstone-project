extends Control

@onready var sprite = $Panel/Panel/Sprite2D
@onready var background = $Panel/Panel/BackgroundPanel

var pending_color 
var pending_background_color

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sprite.modulate = Color(GameManager.color);
	
func _on_accept_button_pressed() -> void:
	var config = ConfigFile.new()
	if pending_color != null:
		GameManager.color = pending_color
		config.set_value("player", "color", pending_color)
		
	if pending_background_color != null:
		GameManager.background_color = pending_background_color
		config.set_value("player", "background_color", pending_background_color)
	get_tree().change_scene_to_file("res://scenes/GameMode/GameMode.tscn")

# TODO: create signals for when a color is pressed.

func change_sprite_color(path):
	var style = path.get_theme_stylebox("normal") as StyleBoxFlat
	if style:
		pending_color= style.bg_color
		sprite.modulate = style.bg_color

func change_background_color(path):
	var style = path.get_theme_stylebox("normal") as StyleBoxFlat
	if style:
		pending_background_color = style.bg_color
		background.modulate = style.bg_color
		
		
# ============================================
# Change Sprite Color Buttons
# ============================================

func _on_color_button_1_pressed() -> void:
	change_sprite_color($Panel/Panel/VBoxContainer/ColorButton1)

func _on_color_button_2_pressed() -> void:
	change_sprite_color($Panel/Panel/VBoxContainer/ColorButton2)

func _on_color_button_3_pressed() -> void:
	change_sprite_color($Panel/Panel/VBoxContainer/ColorButton3)

func _on_color_button_4_pressed() -> void:
	change_sprite_color($Panel/Panel/VBoxContainer/ColorButton4)

func _on_color_button_5_pressed() -> void:
	change_sprite_color($Panel/Panel/VBoxContainer2/ColorButton5)

func _on_color_button_6_pressed() -> void:
	change_sprite_color($Panel/Panel/VBoxContainer2/ColorButton6)

func _on_color_button_7_pressed() -> void:
	change_sprite_color($Panel/Panel/VBoxContainer2/ColorButton7)

func _on_color_button_8_pressed() -> void:
	change_sprite_color($Panel/Panel/VBoxContainer2/ColorButton8)
	
# ============================================
# Change Background Buttons
# ============================================
func _on_background_color_button_1_pressed() -> void:
	change_background_color($Panel/Panel/HBoxContainer/BackgroundColorButton1)

func _on_background_color_button_2_pressed() -> void:
	change_background_color($Panel/Panel/HBoxContainer/BackgroundColorButton2)

func _on_background_color_button_3_pressed() -> void:
	change_background_color($Panel/Panel/HBoxContainer/BackgroundColorButton3)

func _on_background_color_button_4_pressed() -> void:
	change_background_color($Panel/Panel/HBoxContainer/BackgroundColorButton4)


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/GameMode/GameMode.tscn")
