extends Sprite2D

var iconName
var iconColor

func setIcon(name:String, color:Color) -> void:
	iconName = name
	iconColor = color
	setIconImage()
	setIconColor()
	
func setIconImage() -> void:
	var ipx = Vector2(0, 0)
	
	match iconName:
		"Derpy":
			ipx = Vector2(0, 0)
		"Pretty":
			ipx = Vector2(1, 0)
		"Thinking":
			ipx = Vector2(2, 0)
		"Sad":
			ipx = Vector2(3, 0)
		"Handsome":
			ipx = Vector2(0, 1)
		"Groucho":
			ipx = Vector2(1, 1)
		"Angry":
			ipx = Vector2(2, 1)
		"Happy":
			ipx = Vector2(3, 1)
		"Random":
			ipx = Vector2(randi_range(0, 3), randi_range(0, 1)) 
	
	self.region_rect.position = Vector2(ipx.x * 58, ipx.y * 33)

func setIconColor() -> void:
	set_instance_shader_parameter("tint_color", iconColor)
	set_instance_shader_parameter("tint_effect", 1)
	set_instance_shader_parameter("brightness", 1)
