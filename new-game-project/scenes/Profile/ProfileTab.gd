extends Control

@onready var usernameLabel = $Panel/UsernameLabel
@onready var pointsLabel = $Panel/PointsLabel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# connect to signal
	DBService.connect("points_received", _on_points_received)
	# update labels
	usernameLabel.text = GameManager.username
	DBService.check_points(GameManager.username)
	

	
func _on_points_received(points):
	print("points: ", points)
	pointsLabel.text = str(points) + "pts"
	
