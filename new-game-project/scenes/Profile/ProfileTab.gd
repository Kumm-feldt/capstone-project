extends Control

@onready var usernameLabel = $Panel/UsernameLabel
@onready var pointsLabel = $Panel/PointsLabel
@onready var panelContainer= $Panel/PanelContainer
func _get_safe_color(raw) -> Color:
	if raw is Color:
		# Already a Color object e.g. (0.9098, 0.2314, 0.2314, 1.0)
		return raw
	elif raw is String and raw.length() > 0:
		# Hex string e.g. "ffffff" or "#ff0000"
		return Color.from_string(raw, Color.GRAY)
	else:
		# Null, bool, int, or anything unexpected
		push_warning("Invalid color value in GameManager: " + str(raw))
		return Color.GRAY

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# connect to signal
	DBService.connect("points_received", _on_points_received)
	# update labels
	usernameLabel.text = GameManager.username
	DBService.check_points(GameManager.username)
	var style = StyleBoxFlat.new()
	var color = _get_safe_color(GameManager.background_color)
	print("ERROR: ", color)
	style.bg_color = Color(color)  
	panelContainer.add_theme_stylebox_override("panel", style)
	
	
func _on_points_received(points):
	pointsLabel.text = str(points) + "pts"
	
