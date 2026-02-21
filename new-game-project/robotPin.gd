extends AnimatedSprite2D

var player: String
var playerColor: Color


func set_pin(ownerPlayer: String, givenPlayerColor: Color) -> void:
	"""Set up the pin according to its player."""
	player = ownerPlayer;
	
	playerColor = givenPlayerColor
	modulate = givenPlayerColor;
	
	self.play("idle");
	
