# scenes/board/Board.gd
# Attached to the Board (Node2D) root node
extends Node2D

# ============================================
# CONFIGURATION
# ============================================
var MODE = "AI"

# Board image dimensions
const BOARD_WIDTH = 800 
const BOARD_HEIGHT = 450 

# Octagon (coin space) measurements
const FIRST_OCTAGON_X = 275  # X pixel position of COINS[0][0] center
const FIRST_OCTAGON_Y = 100  # Y pixel position of COINS[0][0] center
const OCTAGON_SPACING_X = 50  # Horizontal distance between octagon centers
const OCTAGON_SPACING_Y = 50  # Vertical distance between octagon centers

# Pin (intersection) measurements - calculated from octagons
const FIRST_PIN_X = FIRST_OCTAGON_X - OCTAGON_SPACING_X / 2
const FIRST_PIN_Y = FIRST_OCTAGON_Y - OCTAGON_SPACING_Y / 2
const PIN_SPACING_X = OCTAGON_SPACING_X
const PIN_SPACING_Y = OCTAGON_SPACING_Y

# ============================================
# RESOURCES
# ============================================
var pin_o_texture = preload("res://sprites/pins/pin_o.png")
var pin_x_texture = preload("res://sprites/pins/pin_x.png")
var coin_o_texture = preload("res://sprites/coins/coin_o.png")
var coin_x_texture = preload("res://sprites/coins/coin_x.png")


var pin_o_scene = preload("res://scenes/pin/PinO.tscn")
var pin_x_scene = preload("res://scenes/pin/PinX.tscn")

var disk_o_scene = preload("res://scenes/disk/DiskO.tscn")
var disk_x_scene = preload("res://scenes/disk/DiskX.tscn")


# ============================================
# STATE TRACKING
# ============================================
var pin_sprites = {}   # "row_col" -> Sprite2D
var coin_sprites = {}  # "row_col" -> Sprite2D

var selected_pin: Vector2i = Vector2i(-1, -1)
var highlight_rect: ColorRect = null

# ============================================
# NODE REFERENCES
# ============================================
@onready var board_sprite = $BoardSprite

# ============================================
# INITIALIZATION
# ============================================
func _ready():
	setup_board_sprite() # load board
	connect_signals() 
	render_board()

func setup_board_sprite():
	"""Configure the background board image"""
	board_sprite.texture = preload("res://sprites/board/board.png")
	board_sprite.centered = true

func connect_signals():
	"""Connect to GameState signals"""
	GameState.connect("board_updated", _on_board_updated)
	#GameState.connect("pin_moved", _on_pin_moved)
	GameState.connect("pin_jumped", _on_pin_jumped)
	#GameState.connect("coin_placed", _on_coin_placed)
	#GameState.connect("coin_flipped", _on_coin_flipped)

# ============================================
# RENDERING
# ============================================
func render_board():
	"""Main render function - creates all sprites from GameState arrays"""
	clear_all_sprites()
	
	# Render pins (at intersections)
	for row in range(7):
		for col in range(7):
			var state = GameState.PINS[row][col]
			if state != ".":
				create_pin_sprite(row, col, state)
	
	# Render coins (in octagons)
	for row in range(6):
		for col in range(6):
			var state = GameState.COINS[row][col]
			if state != ".":
				create_coin_sprite(row, col, state)

func create_pin_sprite(row: int, col: int, player: String):
	"""Create a pin sprite at array position"""
	var pin_scene = pin_o_scene if player == "o" else pin_x_scene
	var sprite_instance = pin_scene.instantiate()
	
	sprite_instance.position = get_pin_screen_position(row, col)
	sprite_instance.z_index = 1  # Pins on top
	# add scene to tree
	add_child(sprite_instance)
	# store reference
	pin_sprites["%d_%d" % [row, col]] = sprite_instance

func create_coin_sprite(row: int, col: int, player: String):
	"""Create a coin scene at array position"""
	var disk_scene = disk_o_scene if player == "o" else disk_x_scene
	var sprite_instance = disk_scene.instantiate()
	sprite_instance.position = get_coin_screen_position(row, col)
	sprite_instance.z_index = 0  # Coins below pins
	add_child(sprite_instance)
	coin_sprites["%d_%d" % [row, col]] = sprite_instance

func clear_all_sprites():
	"""Remove all existing sprites"""
	for sprite in pin_sprites.values():
		sprite.queue_free()
	for sprite in coin_sprites.values():
		sprite.queue_free()
	pin_sprites.clear()
	coin_sprites.clear()

# ============================================
# COORDINATE MAPPING
# ============================================

func get_pin_screen_position(row: int, col: int) -> Vector2:
	"""Convert PINS[row][col] to screen pixel position"""
	var x = FIRST_PIN_X + col * PIN_SPACING_X
	var y = FIRST_PIN_Y + row * PIN_SPACING_Y
	
	# Account for board sprite being centered
	var board_top_left = board_sprite.position - Vector2(BOARD_WIDTH / 2, BOARD_HEIGHT / 2)
	
	return board_top_left + Vector2(x, y)

func get_coin_screen_position(row: int, col: int) -> Vector2:
	"""Convert COINS[row][col] to screen pixel position"""
	var x = FIRST_OCTAGON_X + col * OCTAGON_SPACING_X
	var y = FIRST_OCTAGON_Y + row * OCTAGON_SPACING_Y
	
	var board_top_left = board_sprite.position - Vector2(BOARD_WIDTH / 2, BOARD_HEIGHT / 2)
	
	return board_top_left + Vector2(x, y)

func screen_to_pin_array(screen_pos: Vector2) -> Vector2i:
	"""Convert mouse click to PINS array indices"""
	var board_top_left = board_sprite.position - Vector2(BOARD_WIDTH/2, BOARD_HEIGHT/2)
	var relative = screen_pos - board_top_left
	var col = round((relative.x - FIRST_PIN_X) / PIN_SPACING_X)
	var row = round((relative.y - FIRST_PIN_Y) / PIN_SPACING_Y)
	
	if row >= 0 and row < 7 and col >= 0 and col < 7:
		return Vector2i(col, row)
	return Vector2i(-1, -1)

# ============================================
# INPUT HANDLING
# ============================================
func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:		# Get the global mouse position (relative to the top-left corner of the screen)
		var click_position: Vector2 = get_global_mouse_position()
		var local_mouse_pos = to_local(click_position)
		var clicked_pin = screen_to_pin_array(local_mouse_pos)

		if selected_pin.x < 0:
			handle_first_click(clicked_pin)
		else:
			handle_second_click(clicked_pin)
		


func handle_first_click(clicked_pin: Vector2i):
	if GameState.is_valid_selection(clicked_pin.y,clicked_pin.x,  GameState.current_player):
		selected_pin = clicked_pin
		emit_signal("valid_move")

	else:
		print("first click incorrectly: ", clicked_pin)
	

func handle_second_click(clicked_pin: Vector2i):
	print("Second click: trying to move to ", clicked_pin)
	var coord_f = array_to_notation(selected_pin.y, selected_pin.x)
	var coord = coord_f + array_to_notation(clicked_pin.y, clicked_pin.x)
	if GameState.move_pin(coord, GameState.current_player):
		print("Attempt move Succesfully")
	else:
		print("Failed")
	# Always deselect after second click (whether move succeeded or not)
	deselect_pin()
	if MODE == "AI":
		test_ai()

func deselect_pin():
	"""Clear pin selection"""
	selected_pin = Vector2i(-1, -1)


func array_to_notation(row: int, col: int) -> String:
	print("row: ", row, "col: ", col)
	"""Convert array indices to chess notation (a1, b2, etc.)"""
	var letter = char('a'.unicode_at(0) + col)
	return letter + str(row + 1)
# ============================================
# VISUAL FEEDBACK
# ============================================


# ============================================
# ANIMATION FUNCTIONS (Basic Tweens)
# ============================================

# ============================================
# SIGNAL HANDLERS
# ============================================
func _on_board_updated():
	""" update board """
	render_board()
	
	
func _on_pin_jumped(from_pos: Vector2i, to_pos: Vector2i, removed_pos: Vector2i, player: String):
	"""Add animations"""	
	print("Animation")
	
# ============================================
# AI CALLS
# ============================================
func test_ai():
	pass
