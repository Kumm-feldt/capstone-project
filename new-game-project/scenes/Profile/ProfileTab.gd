extends Control

@onready var usernameLabel = $Panel/UsernameLabel
@onready var pointsLabel = $Panel/PointsLabel
@onready var panelContainer= $Panel/PanelContainer
@onready var sprite = $Panel/PanelContainer/PlayerIcon


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# connect to signal
	DBService.connect("points_received", _on_points_received)
	DBService.connect("player_updated", _on_player_updated)
	# update labels
	usernameLabel.text = GameManager.username
	DBService.check_points(GameManager.username)
	set_icon()
	
func set_icon():
	var style = StyleBoxFlat.new()
	var background_color = GameManager.get_safe_color(GameManager.background_color)
	var safe_color = GameManager.get_safe_color(GameManager.icon_color)
	style.bg_color = background_color  # ← Replace Color.RED with this
	sprite.setIcon(GameManager.profile_picture, safe_color)
	panelContainer.add_theme_stylebox_override("panel", style)
	panelContainer.queue_redraw()
	
func _on_player_updated():
	set_icon()

func _on_points_received(points):
	pointsLabel.text = str(points) + "pts"
	
