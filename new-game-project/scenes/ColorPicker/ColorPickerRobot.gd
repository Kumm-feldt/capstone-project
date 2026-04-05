extends AnimatedSprite2D

var color: Color

func _ready() -> void:
	setColorPickerRobot(Color("#c7dcd0"))
	play("default")

func setColorPickerRobot(givenColor: Color) -> void:
	color = givenColor
	set_instance_shader_parameter("tint_color", color)
	set_instance_shader_parameter("tint_effect", 1)
	set_instance_shader_parameter("brightness", 1)

func confirmColor() -> void:
	play("happy")
