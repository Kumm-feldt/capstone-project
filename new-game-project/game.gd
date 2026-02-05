extends Node2D


signal pin_selected(pin_pos: Vector2i, player: int)
signal pin_deselected()
signal move_requested(from_pos: Vector2i, to_pos: Vector2i)
signal move_validated(from_pos: Vector2i, to_pos: Vector2i, move_type: int)
signal move_executed(from_pos: Vector2i, to_pos: Vector2i, move_type: int)

# Disk signals
signal disk_placed(octagon_pos: Vector2i, player: int)
signal disk_flipped(octagon_pos: Vector2i, old_player: int, new_player: int)

# Pin capture signals
signal pin_captured(pin_pos: Vector2i, player: int)
signal pin_removed(pin_pos: Vector2i, player: int)

# Turn management signals
signal turn_started(player: int)
signal turn_ended(player: int)
signal player_switched(old_player: int, new_player: int)

# Win condition signals
signal path_checking(start: Vector2i, end: Vector2i, player: int)
signal path_found(start: Vector2i, end: Vector2i, player: int, path: Array)
signal victory(player: int)
signal game_over(winner: int)

# UI update signals
signal board_updated()
signal valid_moves_calculated(moves: Array)
signal display_refresh_requested()


enum Player { NONE = 0, BLACK = 1, WHITE = 2 }
enum MoveType { INVALID = 0, SIMPLE = 1, CAPTURE = 2, DIAGONAL = 3 }

const BOARD_LAYER := 0
const DISK_LAYER := 1
const PIN_LAYER := 2
const HIGHLIGHT_LAYER := 3

const BLACK_DISK := 0
const WHITE_DISK := 1
const BLACK_PIN := 2
const WHITE_PIN := 3

@onready var tilemap: TileMap = $TileMap


var current_player: int = Player.BLACK
var selected_pin: Vector2i = Vector2i(-1, -1)

func _ready():
	emit_signal("turn_started", current_player)
	emit_signal("display_refresh_requested")

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var cell := tilemap.local_to_map(tilemap.to_local(get_global_mouse_position()))
		_handle_click(cell)


func _handle_click(cell: Vector2i):
	if selected_pin == Vector2i(-1, -1):
		_try_select_pin(cell)
	else:
		emit_signal("move_requested", selected_pin, cell)
		_try_move(selected_pin, cell)

func _try_select_pin(cell: Vector2i):
	var atlas := tilemap.get_cell_atlas_coords(PIN_LAYER, cell)
	var expected := BLACK_PIN if current_player == Player.BLACK else WHITE_PIN
	
	if atlas.x == expected:
		selected_pin = cell
		emit_signal("pin_selected", cell, current_player)
	else:
		emit_signal("pin_deselected")

func _try_move(from: Vector2i, to: Vector2i):
	var move_type := _validate_move(from, to)
	
	if move_type == MoveType.INVALID:
		emit_signal("pin_deselected")
		selected_pin = Vector2i(-1, -1)
		return
	
	emit_signal("move_validated", from, to, move_type)
	_execute_move(from, to, move_type)

func _validate_move(from: Vector2i, to: Vector2i) -> int:
	if tilemap.get_cell_source_id(PIN_LAYER, to) != -1:
		return MoveType.INVALID
	
	var delta := to - from
	var abs := Vector2i(abs(delta.x), abs(delta.y))
	
	if abs == Vector2i(1, 0) or abs == Vector2i(0, 1):
		return MoveType.SIMPLE
	
	if abs == Vector2i(2, 0) or abs == Vector2i(0, 2):
		return MoveType.CAPTURE
	
	if abs == Vector2i(2, 2):
		return MoveType.DIAGONAL
	
	return MoveType.INVALID


func _execute_move(from: Vector2i, to: Vector2i, move_type: int):
	tilemap.erase_cell(PIN_LAYER, from)
	
	var pin_tile := BLACK_PIN if current_player == Player.BLACK else WHITE_PIN
	tilemap.set_cell(PIN_LAYER, to, 0, Vector2i(pin_tile, 0))
	
	if move_type == MoveType.CAPTURE:
		var mid := (from + to) / 2
		_handle_capture(mid)
	
	if move_type == MoveType.DIAGONAL:
		_handle_disk((from + to) / 2)
	
	emit_signal("move_executed", from, to, move_type)
	emit_signal("board_updated")
	_end_turn()


func _handle_capture(pos: Vector2i):
	var atlas := tilemap.get_cell_atlas_coords(PIN_LAYER, pos)
	if atlas != Vector2i(-1, -1):
		var owner := Player.WHITE if current_player == Player.BLACK else Player.BLACK
		tilemap.erase_cell(PIN_LAYER, pos)
		emit_signal("pin_captured", pos, owner)
		emit_signal("pin_removed", pos, owner)

func _handle_disk(pos: Vector2i):
	var atlas := tilemap.get_cell_atlas_coords(DISK_LAYER, pos)
	
	if atlas == Vector2i(-1, -1):
		var tile := BLACK_DISK if current_player == Player.BLACK else WHITE_DISK
		tilemap.set_cell(DISK_LAYER, pos, 0, Vector2i(tile, 0))
		emit_signal("disk_placed", pos, current_player)
	else:
		var old := Player.BLACK if atlas.x == BLACK_DISK else Player.WHITE
		var tile := BLACK_DISK if current_player == Player.BLACK else WHITE_DISK
		tilemap.set_cell(DISK_LAYER, pos, 0, Vector2i(tile, 0))
		emit_signal("disk_flipped", pos, old, current_player)


func _end_turn():
	emit_signal("turn_ended", current_player)
	
	var old := current_player
	current_player = Player.WHITE if current_player == Player.BLACK else Player.BLACK
	
	selected_pin = Vector2i(-1, -1)
	
	emit_signal("player_switched", old, current_player)
	emit_signal("turn_started", current_player)
	emit_signal("display_refresh_requested")

var PINS = [
	[".", "o", "o", ".", "x", "x", "."],
	["o", ".", ".", ".", ".", ".", "x"],
	["o", ".", ".", ".", ".", ".", "x"],
	[".", ".", ".", ".", ".", ".", "."],
	["x", ".", ".", ".", ".", ".", "o"],
	["x", ".", ".", ".", ".", ".", "o"],
	[".", "x", "x", ".", "o", "o", "."]
]

var COINS = [
	["o", ".", ".", ".", ".", "x"],
	[".", ".", ".", ".", ".", "."],
	[".", ".", ".", ".", ".", "."],
	[".", ".", ".", ".", ".", "."],
	[".", ".", ".", ".", ".", "."],
	["x", ".", ".", ".", ".", "o"]
]

func print_nice_board(board):
	for row in board:
		print(row)

func put_coin(a, b, curr_player):
	if COINS[a][b] != curr_player and COINS[a][b] != '.':
		# flip the coin
		COINS[a][b] = curr_player
	elif COINS[a][b] == '.':
		# put current_player coin
		COINS[a][b] = curr_player
		
func put_pin(from_c_indx_0,from_c_indx_1,to_c_indx_0,to_c_indx_1,current_pin):
	PINS[to_c_indx_0][to_c_indx_1] = current_pin
	PINS[from_c_indx_0][from_c_indx_1] = '.'

func move_pin(coordinates, curr_player):
	# turns abcdef coordinates into index for matrix
	var from_c = coordinates[0]
	var from_c_index_0 = int(coordinates[1]) - 1
	var from_c_index_1 = from_c.unicode_at(0) - "a".unicode_at(0)
	
	var to_c = coordinates[2]
	var to_c_index_0 = int(coordinates[3])-1
	var to_c_index_1 = to_c.unicode_at(0) - "a".unicode_at(0)
	
	var current_pin_to_move = PINS[from_c_index_0][from_c_index_1]
	var next_pos = PINS[to_c_index_0][to_c_index_1]
	
	# check if the next position is available
	if(next_pos == '.'):
		# if next movement U,R,L,D requires to take 2 steps instead of 1, we will know
		var check_indx_letters =  to_c_index_1 - from_c_index_1 
		var check_indx_nums = to_c_index_0 - from_c_index_0
		
		# check if next position involves removing the players pin
		if (abs(check_indx_letters) > 1 or abs(check_indx_nums) > 1):
			if (check_indx_letters == 2): # RIGHT
				PINS[to_c_index_0][to_c_index_1-1] = '.'
			elif(check_indx_letters == -2): # LEFT
				PINS[to_c_index_0][to_c_index_1+1] = '.'
			elif(check_indx_nums == 2): # UP
				PINS[to_c_index_0-1][to_c_index_1] = '.'
			elif (check_indx_nums == -2): # DOWN
				PINS[to_c_index_0+1][to_c_index_1] = '.'
			put_pin(from_c_index_0, from_c_index_1, to_c_index_0, to_c_index_1, current_pin_to_move)
		
		else:
			# calculate if ONE STEP move is r, l, d, u or diagonal
			var to_i = to_c_index_0 + to_c_index_1
			var from_i = from_c_index_0 + from_c_index_1
			var pos = from_i - to_i
				
			if(pos == 2):
				print("UP <- LEFT")
				put_coin(to_c_index_0,to_c_index_1, curr_player)
			elif(pos == -2):
				print("DOWN -> RIGHT")
				put_coin(from_c_index_0,from_c_index_1,curr_player)
			elif(pos == 0):
				if (to_c_index_1 > from_c_index_1 and to_c_index_0 < from_c_index_0):
					print("UP & RIGHT")
					put_coin(to_c_index_0,from_c_index_1,curr_player)
				else:
					print("DOWN & LEFT")
					put_coin(from_c_index_0,to_c_index_1,curr_player)
			put_pin(from_c_index_0, from_c_index_1, to_c_index_0, to_c_index_1, current_pin_to_move)
	else:
		print("Incorrect Move")
		
	print_nice_board(PINS)
	print("\n")
	print_nice_board(COINS)
	print("\n------------------------\n")
	
		

func move_coin():
	pass

func isGameOver():
	return true	
	
	
#func _ready() -> void:
	#move_pin('a5b4', 'X')
	#move_pin('a3a4', 'O')
	#move_pin('a6b5', 'X')
	#move_pin('a4c4', 'O')
	#print("I did something new...")
	

	
