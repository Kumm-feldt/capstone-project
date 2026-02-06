# tests/CalibrationHelper.gd
# Attach to a Node2D in a test scene
extends Node2D

@onready var board = $Board  # Reference to Board node

func _ready():
	queue_redraw()

func _draw():
	"""Draw debug circles at all calculated positions"""
	
	# Draw red circles at PIN positions
	for row in range(7):
		for col in range(7):
			var pos = board.get_pin_screen_position(row, col)
			draw_circle(pos, 5, Color.RED)
			# Draw grid labels
			var label = "%s%d" % [char('a'.unicode_at(0) + col), row + 1]
			draw_string(ThemeDB.fallback_font, pos + Vector2(10, 0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.RED)
	
	# Draw blue circles at COIN positions
	for row in range(6):
		for col in range(6):
			var pos = board.get_coin_screen_position(row, col)
			draw_circle(pos, 8, Color.BLUE)
