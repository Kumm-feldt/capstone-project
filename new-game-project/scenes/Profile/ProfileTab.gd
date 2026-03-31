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
	var color = GameManager.background_color
	style.bg_color = Color(color)  
	panelContainer.add_theme_stylebox_override("panel", style)
	
	
func _on_points_received(points):
	pointsLabel.text = str(points) + "pts"
	
