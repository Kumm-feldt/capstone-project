extends Sprite2D

var player: String
@export var color: Color
var hasBeenPlaced = false

func set_disk(ownerPlayer: String, givenColor: Color) -> void:
	"""Set up the pin according to its player."""
	_setOwner(ownerPlayer, givenColor)
	setDiskColor(color);
	
func setDiskColor(givenColor: Color) -> void:
	color = givenColor
	set_instance_shader_parameter("tint_color", color)
	set_instance_shader_parameter("tint_effect", 1)
	set_instance_shader_parameter("brightness", 1)
	
	
func _setOwner(newOwner: String, newPlayerColor) -> void:
	player = newOwner;
	color = newPlayerColor;
	
	#Make sure to change the color visually!
	return
	
func play_create_animation() -> void:
	visible = true;
	var tween = get_tree().create_tween()
	var currentPos = position
	var higherPos = Vector2(position.x, -1000)
	tween.tween_property($".", "position", higherPos, 0)
	tween.tween_property($".", "position", currentPos, 1.0)
	#Fall onto it from the sky really fast
	#Shake a bit on impact
	var shakeVal = 0.5
	while (shakeVal > 0):
		tween.tween_property($".", "position", Vector2(currentPos.x + (shakeVal * 10), currentPos.y), shakeVal / 2)
		tween.tween_property($".", "position", Vector2(currentPos.x + (shakeVal * -10), currentPos.y), shakeVal / 2)
		shakeVal -= 0.1
	pass
	
func play_swap_animation(oldColor:Color) -> void:
	var tintColorString = "instance_shader_parameters/tint_color"
	#First, set the disk color to look like the old color
	var tween = get_tree().create_tween()
	tween.tween_property($".", tintColorString, oldColor, 0)
	#Then, fade the disk to "power" off
	var powerOffColor = Color(0.225, 0.499, 0.562, 1.0);
	tween.tween_property($".", tintColorString, powerOffColor, 0.2)
	#Lastly, fade the disk to power back on w/ the new color
	tween.tween_property($".", tintColorString, color, 0.2)
	pass
