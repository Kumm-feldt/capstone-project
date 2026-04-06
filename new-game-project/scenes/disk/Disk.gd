extends Sprite2D

var player: String
var color: Color
var hasBeenPlaced = false

func set_disk(ownerPlayer: String, givenColor: Color) -> void:
	"""Set up the pin according to its player."""
	if player != null:
		hasBeenPlaced = true;
	
	if (player != null):
		#The disk is changing owner from a previous owner
		_setOwner(ownerPlayer, givenColor)
		#Play color-changing animation
		# Idea: power off and then on?
		setDiskColor(color);
	else:
		_setOwner(ownerPlayer, givenColor)
		# Play disk entrance animation 
		# (perhaps it falls onto the board?)
		setDiskColor(color);
	#return
	
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
