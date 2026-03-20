extends Control

@onready var usernameLabel = $Panel/UsernameLabel
@onready var pointsLabel = $Panel/PointsLabel
@onready var panelContainer= $Panel/PanelContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# connect to signal
	DBService.connect("points_received", _on_points_received)
	# update labels
	usernameLabel.text = GameManager.username
	DBService.check_points(GameManager.username)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(GameManager.background_color)  
	panelContainer.add_theme_stylebox_override("panel", style)
	
	
func _on_points_received(points):
	print("points: ", points)
	pointsLabel.text = str(points) + "pts"
	
