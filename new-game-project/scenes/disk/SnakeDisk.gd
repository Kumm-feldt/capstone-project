extends Sprite2D

var player: String
var playerColor: Color
var hasBeenPlaced: bool

func set_disc(ownerPlayer: String, givenPlayerColor: Color) -> void:
	"""Set up the pin according to its player."""
	player = ownerPlayer;
	
	playerColor = givenPlayerColor
	
	set_instance_shader_parameter("givenColor", playerColor);
	
 	#if (hasBeenPlaced):
		#Change the owner of the disk, 
		# and play the appropriate animation
	#	print("ph");
	#else:
		# Play disk entrance animation 
		# (perhaps it falls onto the board?)
	#	print("ph");
	#return
	
func change_owner(newOwner: String, newPlayerColor) -> void:
	player = newOwner;
	playerColor = newPlayerColor;
	
	set_instance_shader_parameter("givenColor", playerColor);
	
	return
