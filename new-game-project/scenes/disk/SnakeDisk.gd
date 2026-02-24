extends Sprite2D

var player: String
var playerColor: Color

func set_disc(ownerPlayer: String, givenPlayerColor: Color) -> void:
	"""Set up the pin according to its player."""
	player = ownerPlayer;
	
	playerColor = givenPlayerColor
	
	set_instance_shader_parameter("givenColor", playerColor);
	
	#Play disk entrance animation (perhaps it falls onto the board?)
 	
	
func change_owner(newOwner: String, newPlayerColor) -> void:
	player = newOwner;
	playerColor = newPlayerColor;
	
	set_instance_shader_parameter("givenColor", playerColor);
	
	return
