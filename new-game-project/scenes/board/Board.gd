# scenes/board/Board.gd
# Attached to the Board (Node2D) root node
extends Node2D

# ============================================
# CONFIGURATION - CALIBRATE THESE VALUES
# ============================================
# Measure these from your board.png using an image editor

# Board image dimensions (your board.png size)
const BOARD_WIDTH = 800  # UPDATE THIS
const BOARD_HEIGHT = 450  # UPDATE THIS

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
	setup_board_sprite()
	connect_signals()
	render_board()

func setup_board_sprite():
	"""Configure the background board image"""
	board_sprite.texture = preload("res://sprites/board/board.png")
	board_sprite.centered = true
	#board_sprite.position = Vector2(960, 540)  # Center of 1920x1080

func connect_signals():
	"""Connect to GameState signals"""
	GameState.connect("board_updated", _on_board_updated)
	GameState.connect("pin_moved", _on_pin_moved)
	GameState.connect("pin_jumped", _on_pin_jumped)
	GameState.connect("coin_placed", _on_coin_placed)
	GameState.connect("coin_flipped", _on_coin_flipped)

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
	var sprite = Sprite2D.new()
	sprite.texture = pin_o_texture if player == "o" else pin_x_texture
	sprite.position = get_pin_screen_position(row, col)
	sprite.z_index = 1  # Pins on top
	add_child(sprite)
	pin_sprites["%d_%d" % [row, col]] = sprite

func create_coin_sprite(row: int, col: int, player: String):
	"""Create a coin sprite at array position"""
	var sprite = Sprite2D.new()
	sprite.texture = coin_o_texture if player == "o" else coin_x_texture
	sprite.position = get_coin_screen_position(row, col)
	sprite.z_index = 0  # Coins below pins
	add_child(sprite)
	coin_sprites["%d_%d" % [row, col]] = sprite

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
	var board_top_left = board_sprite.position - Vector2(BOARD_WIDTH / 2, BOARD_HEIGHT / 2)
	var relative = screen_pos - board_top_left
	
	var col = round((relative.x - FIRST_PIN_X) / PIN_SPACING_X)
	var row = round((relative.y - FIRST_PIN_Y) / PIN_SPACING_Y)
	
	if row >= 0 and row < 7 and col >= 0 and col < 7:
		return Vector2i(col, row)
	return Vector2i(-1, -1)

# ============================================
# INPUT HANDLING
# ============================================

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		handle_click(event.position)

func handle_click(screen_pos: Vector2):
	"""Handle mouse click on board"""
	var clicked_pin = screen_to_pin_array(screen_pos)
	
	if clicked_pin.x < 0:  # Out of bounds
		deselect_pin()
		return
	
	if selected_pin.x < 0:
		# First click - select a pin
		if GameState.PINS[clicked_pin.y][clicked_pin.x] == GameState.current_player:
			select_pin(clicked_pin)
	else:
		# Second click - attempt move
		attempt_move(selected_pin, clicked_pin)
		deselect_pin()

func select_pin(pos: Vector2i):
	"""Select a pin for moving"""
	selected_pin = pos
	show_highlight(pos)

func deselect_pin():
	"""Clear pin selection"""
	selected_pin = Vector2i(-1, -1)
	hide_highlight()

func attempt_move(from: Vector2i, to: Vector2i):
	"""Try to execute a move"""
	var from_notation = array_to_notation(from.y, from.x)
	var to_notation = array_to_notation(to.y, to.x)
	var move_string = from_notation + to_notation
	
	if GameState.move_pin(move_string, GameState.current_player):
		GameState.switch_player()
		print("Move successful: ", move_string)
	else:
		print("Move failed: ", move_string)

func array_to_notation(row: int, col: int) -> String:
	"""Convert array indices to chess notation (a1, b2, etc.)"""
	var letter = char('a'.unicode_at(0) + col)
	return letter + str(row + 1)

# ============================================
# VISUAL FEEDBACK
# ============================================

func show_highlight(pos: Vector2i):
	"""Show selection highlight"""
	if highlight_rect == null:
		highlight_rect = ColorRect.new()
		highlight_rect.color = Color(1, 1, 0, 0.5)  # Yellow semi-transparent
		highlight_rect.size = Vector2(30, 30)
		highlight_rect.z_index = 2
		add_child(highlight_rect)
	
	var screen_pos = get_pin_screen_position(pos.y, pos.x)
	highlight_rect.position = screen_pos - Vector2(15, 15)
	highlight_rect.visible = true

func hide_highlight():
	"""Hide selection highlight"""
	if highlight_rect:
		highlight_rect.visible = false

# ============================================
# ANIMATION FUNCTIONS (Basic Tweens)
# ============================================

func animate_pin_move(from_pos: Vector2i, to_pos: Vector2i):
	"""Animate pin moving from one position to another"""
	var from_key = "%d_%d" % [from_pos.y, from_pos.x]
	var to_key = "%d_%d" % [to_pos.y, to_pos.x]
	
	if not pin_sprites.has(from_key):
		render_board()  # Fallback to full re-render
		return
	
	var sprite = pin_sprites[from_key]
	var target_pos = get_pin_screen_position(to_pos.y, to_pos.x)
	
	# Animate movement
	var tween = create_tween()
	tween.tween_property(sprite, "position", target_pos, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	
	# Update tracking
	pin_sprites.erase(from_key)
	pin_sprites[to_key] = sprite

func animate_coin_flip(pos: Vector2i, new_player: String):
	"""Animate coin flipping to new owner"""
	var key = "%d_%d" % [pos.y, pos.x]
	
	if not coin_sprites.has(key):
		render_board()
		return
	
	var sprite = coin_sprites[key]
	
	var tween = create_tween()
	
	# Shrink horizontally (3D flip effect)
	tween.tween_property(sprite, "scale:x", 0.0, 0.15)
	
	# Change texture at midpoint
	tween.tween_callback(func():
		sprite.texture = coin_o_texture if new_player == "o" else coin_x_texture
	)
	
	# Grow back
	tween.tween_property(sprite, "scale:x", 1.0, 0.15)

func animate_coin_placement(pos: Vector2i, player: String):
	"""Animate new coin appearing"""
	var sprite = Sprite2D.new()
	sprite.texture = coin_o_texture if player == "o" else coin_x_texture
	sprite.position = get_coin_screen_position(pos.y, pos.x) - Vector2(0, 50)
	sprite.modulate.a = 0
	sprite.z_index = 0
	add_child(sprite)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "position:y", get_coin_screen_position(pos.y, pos.x).y, 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "modulate:a", 1.0, 0.2)
	
	coin_sprites["%d_%d" % [pos.y, pos.x]] = sprite

# ============================================
# SIGNAL HANDLERS
# ============================================

func _on_board_updated(pins, coins):
	"""Full board refresh"""
	render_board()

func _on_pin_moved(from_pos: Vector2i, to_pos: Vector2i, player: String):
	"""Animate pin movement"""
	animate_pin_move(from_pos, to_pos)

func _on_pin_jumped(from_pos: Vector2i, to_pos: Vector2i, removed_pos: Vector2i, player: String):
	"""Handle jump move with pin removal"""
	# For now, just do full refresh (add animation later if time)
	render_board()

func _on_coin_placed(pos: Vector2i, player: String):
	"""Animate new coin"""
	animate_coin_placement(pos, player)

func _on_coin_flipped(pos: Vector2i, old_player: String, new_player: String):
	"""Animate coin flip"""
	animate_coin_flip(pos, new_player)
