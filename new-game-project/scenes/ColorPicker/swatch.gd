#Code inspired from GDQuest at https://www.youtube.com/watch?v=4Fubatvtpkw on 4/4/2026.

@tool
extends Button
class_name ColorSwatch

@onready var color_rect: ColorRect = $AspectRatioContainer/ColorRect

@export var color: = Color('ffffff'):
	set(value):
		color = value
		if not color_rect:
			return
		color_rect.color = value
	get:
		return color

func _ready() -> void:
	self.color = color;
