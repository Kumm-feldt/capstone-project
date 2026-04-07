extends Sprite2D

var color: Color

func setSnakeBaseColors(givenColor:Color):
	
	color = givenColor
	set_instance_shader_parameter("tint_color", color)
	set_instance_shader_parameter("tint_effect", 1)
	set_instance_shader_parameter("brightness", 1)
