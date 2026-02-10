extends Node

# ============================================
# SIGNALS
# ============================================
signal board_updated(pins, coins)
signal pin_moved(from_pos: Vector2i, to_pos: Vector2i, player: String)
signal pin_jumped(from_pos: Vector2i, to_pos: Vector2i, removed_pos: Vector2i, player: String)
signal coin_placed(pos: Vector2i, player: String)
signal coin_flipped(pos: Vector2i, old_player: String, new_player: String)
signal game_over(winner: String)
signal turn_changed(player: String)
signal invalid_move(text: String)
signal valid_move()



# ============================================
# GAME STATE
# ============================================

var current_player = "o"
var game_active = true

# PINS array (7x7) 
var PINS = [
	[".", "o", "o", ".", "x", "x", "."],
	["o", ".", ".", ".", ".", ".", "x"],
	["o", ".", ".", ".", ".", ".", "x"],
	[".", ".", ".", ".", ".", ".", "."],
	["x", ".", ".", ".", ".", ".", "o"],
	["x", ".", ".", ".", ".", ".", "o"],
	[".", "x", "x", ".", "o", "o", "."]
]

# COINS array (6x6)
var COINS = [
	["o", ".", ".", ".", ".", "x"],
	[".", ".", ".", ".", ".", "."],
	[".", ".", ".", ".", ".", "."],
	[".", ".", ".", ".", ".", "."],
	[".", ".", ".", ".", ".", "."],
	["x", ".", ".", ".", ".", "o"]
]

# ============================================
# CORE GAME LOGIC
# ============================================
func move_pin(coordinates: String, player: String) -> bool:
	"""
	Coordinates format: "a1b2" (from a1 to b2)
	Returns true if move was valid and executed
	"""
	if not game_active:
		return false
		
	# parse coordinates
	var from_c = coordinates[0]
	var from_row = int(coordinates[1]) - 1
	var from_col = from_c.unicode_at(0) - "a".unicode_at(0)
	
	var to_c = coordinates[2]
	var to_row = int(coordinates[3])-1
	var to_col = to_c.unicode_at(0) - "a".unicode_at(0)
	
	var current_pin_to_move = PINS[from_row][from_col]	
	print(coordinates)
	var invalid_text = "Invalid move"
	# Validate move
	if not is_valid_move(from_row, from_col, to_row, to_col, player):
		emit_signal("invalid_move", 
		invalid_text)
		return false
		
	# Calcualate movement type
	# if next movement U,R,L,D requires to take 2 steps instead of 1, we will know
	var col_diff =  to_col - from_col 
	var row_diff = to_row - from_row
	var current_pin = PINS[from_row][from_col]
	
	# check if next position involves removing the players pin
	if (abs(col_diff) > 1 or abs(row_diff) > 1):
		# Two-step jump (remove middle pin)
		var removed_col = from_col + sign(col_diff)
		var removed_row = from_row + sign(row_diff)
		
		if (col_diff == 2): # RIGHT
			PINS[to_row][to_col-1] = '.'
		elif(col_diff == -2): # LEFT
			PINS[to_row][to_col+1] = '.'
		elif(row_diff == 2): # UP
			PINS[to_row-1][to_col] = '.'
		elif (row_diff == -2): # DOWN
			PINS[to_row+1][to_col] = '.'
		put_pin(from_row, from_col, to_row, to_col, current_pin_to_move)
		# Emit jump signal
		emit_signal("pin_jumped", 
			Vector2i(from_col, from_row), 
			Vector2i(to_col, to_row),
			Vector2i(removed_col, removed_row),
			player)
	else:
		# One-step diagonal move (place/flip coin)
		handle_coin_placement(to_row, to_col, from_row, from_col, player)
		put_pin(from_row, from_col, to_row, to_col, current_pin)
		
		# Emit move signal
		emit_signal("pin_moved", 
			Vector2i(from_col, from_row), 
			Vector2i(to_col, to_row), 
			player)
	# Notify GUI of state change
	emit_signal("board_updated")
		
	# Check win condition
	if check_win_condition():
		emit_signal("game_over", get_winner())
		game_active = false
		
	switch_player()
	emit_signal("valid_move")
	return true

func handle_coin_placement(to_row, to_col, from_row, from_col, player):
	# calculate if ONE STEP move is r, l, d, u or diagonal
	var to_i = to_row + to_col
	var from_i = from_row + from_col
	var pos = from_i - to_i
		
	if(pos == 2): # UP - LEFT
		put_coin(to_row,to_col, player)
	elif(pos == -2): # DOWN - RIGHT
		put_coin(from_row,from_col,player)
	elif(pos == 0):
		if (to_col > from_col and to_row < from_row):  # UP - RIGHT
			put_coin(to_row,from_col,player)
		else: # DOWN - LEFT
			put_coin(from_row,to_col,player)

func put_coin(row: int, col: int, player: String):
	"""Place or flip a coin"""
	var old_state = COINS[row][col]
	
	if old_state != player and old_state != '.':
		# Flip existing coin
		COINS[row][col] = player
		emit_signal("coin_flipped", Vector2i(col, row), old_state, player)
	elif old_state == '.':
		# Place new coin
		COINS[row][col] = player
		emit_signal("coin_placed", Vector2i(col, row), player)

func put_pin(from_row: int, from_col: int, to_row: int, to_col: int, pin: String):
	"""Move pin in array"""
	PINS[to_row][to_col] = pin
	PINS[from_row][from_col] = '.'
	

func is_valid_selection(row,col, player):
	"""Validate if the current selection is legal"""
	var invalid_text = "Invalid Move"
	# Bounds check
	if row < 0 or row >= 7 or col < 0 or col >= 7:
		emit_signal("invalid_move", 
		invalid_text)
		return false
	# Check if selection is players pin
	if PINS[row][col] != player:
		emit_signal("invalid_move", 
		invalid_text)
		return false
	return true


func is_valid_move(from_row: int, from_col: int, to_row: int, to_col: int, player: String) -> bool:
	"""Validate if a move is legal"""
	# Bounds check
	if from_row < 0 or from_row >= 7 or from_col < 0 or from_col >= 7:
		return false
	if to_row < 0 or to_row >= 7 or to_col < 0 or to_col >= 7:
		return false
	# Check if moving your own pin
	if PINS[from_row][from_col] != player:
		return false
	
	# Check if destination is empty
	if PINS[to_row][to_col] != ".":
		return false
	
	# Check if move is within rules
	var row_diff = abs(to_row - from_row)
	var col_diff = abs(to_col - from_col)
	
	# One step move (adjacent) or two step jump (over opponent pin)
	if (row_diff <= 1 and col_diff <= 1):
		return true  # Adjacent move
	elif (row_diff == 2 and col_diff == 0) or (row_diff == 0 and col_diff == 2):
		# Check if jumping over opponent's pin
		var mid_row = from_row + sign(to_row - from_row)
		var mid_col = from_col + sign(to_col - from_col)
		var opponent = "x" if player == "o" else "o"
		return PINS[mid_row][mid_col] == opponent
	return false

func switch_player():
	"""Switch to the other player"""
	current_player = "x" if current_player == "o" else "o"
	emit_signal("turn_changed", current_player)


# ============================================
# WIN CONDITION CHECKING
# ============================================

func check_win_condition() -> bool:
	"""
	Check if either player has won.
	O must connect top-left (0,0) to bottom-right (5,5)
	X must connect top-right (0,5) to bottom-left (5,0)
	Only orthogonal connections count (no diagonal)
	"""
	# Check both players to see if either has won
	if check_path_exists(0, 0, 5, 5, "o"):
		return true
	if check_path_exists(0, 5, 5, 0, "x"):
		return true
	return false

func get_winner() -> String:
	"""Determine winner based on coin chains"""
	if check_path_exists(0, 0, 5, 5, "o"):
		return "o"
	elif check_path_exists(0, 5, 5, 0, "x"):
		return "x"
	return "you won"

func check_path_exists(start_row: int, start_col: int, end_row: int, end_col: int, player: String) -> bool:
	"""
	Use BFS"""
	# Check if start and end coins exist
	if COINS[start_row][start_col] != player:
		return false
	if COINS[end_row][end_col] != player:
		return false
	
	# BFS setup
	var visited = {}
	var queue = []
	queue.append(Vector2i(start_col, start_row))
	visited["%d_%d" % [start_row, start_col]] = true
	
	
	var directions = [
		Vector2i(0, -1),  # up
		Vector2i(0, 1),   # down
		Vector2i(-1, 0),  # left
		Vector2i(1, 0)    # right
	]
	
	while queue.size() > 0:
		var current = queue.pop_front()
		var cur_col = current.x
		var cur_row = current.y
		
		# Check if we reached the goal
		if cur_row == end_row and cur_col == end_col:
			return true
		
		# Check all orthogonal neighbors
		for dir in directions:
			var next_col = cur_col + dir.x
			var next_row = cur_row + dir.y
			
			# Bounds check
			if next_row < 0 or next_row >= 6 or next_col < 0 or next_col >= 6:
				continue
			
			# Check if already visited
			var key = "%d_%d" % [next_row, next_col]
			if visited.has(key):
				continue
			
			# Check if this coin belongs to the player
			if COINS[next_row][next_col] == player:
				visited[key] = true
				queue.append(Vector2i(next_col, next_row))
	
	return false

func check_draw():
	# check if there is not pins
	

func reset_game():
	"""Reset to initial state"""
	PINS = [
		[".", "o", "o", ".", "x", "x", "."],
		["o", ".", ".", ".", ".", ".", "x"],
		["o", ".", ".", ".", ".", ".", "x"],
		[".", ".", ".", ".", ".", ".", "."],
		["x", ".", ".", ".", ".", ".", "o"],
		["x", ".", ".", ".", ".", ".", "o"],
		[".", "x", "x", ".", "o", "o", "."]
	]
	
	COINS = [
		["o", ".", ".", ".", ".", "x"],
		[".", ".", ".", ".", ".", "."],
		[".", ".", ".", ".", ".", "."],
		[".", ".", ".", ".", ".", "."],
		[".", ".", ".", ".", ".", "."],
		["x", ".", ".", ".", ".", "o"]
	]
	
	current_player = "o"
	game_active = true
	emit_signal("board_updated", PINS, COINS)

func print_debug_state():
	"""Debug helper"""
	print("=== PINS ===")
	for row in PINS:
		print(row)
	print("\n=== COINS ===")
	for row in COINS:
		print(row)
	print("\nCurrent player: ", current_player)
	print("================\n")
