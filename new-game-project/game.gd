extends Node2D

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
	var from_row = int(coordinates[1]) - 1
	var from_col = from_c.unicode_at(0) - "a".unicode_at(0)
	
	var to_c = coordinates[2]
	var to_row = int(coordinates[3])-1
	var to_col = to_c.unicode_at(0) - "a".unicode_at(0)
	
	var current_pin_to_move = PINS[from_row][from_col]
	var next_pos = PINS[to_row][to_col]
	
	# check if the next position is available
	if(next_pos == '.'):
		# if next movement U,R,L,D requires to take 2 steps instead of 1, we will know
		var col_diff =  to_col - from_col 
		var row_diff = to_row - from_row
		
		# check if next position involves removing the players pin
		if (abs(col_diff) > 1 or abs(row_diff) > 1):
			if (col_diff == 2): # RIGHT
				PINS[to_row][to_col-1] = '.'
			elif(col_diff == -2): # LEFT
				PINS[to_row][to_col+1] = '.'
			elif(row_diff == 2): # UP
				PINS[to_row-1][to_col] = '.'
			elif (row_diff == -2): # DOWN
				PINS[to_row+1][to_col] = '.'
			put_pin(from_row, from_col, to_row, to_col, current_pin_to_move)
		
		else:
			# calculate if ONE STEP move is r, l, d, u or diagonal
			var to_i = to_row + to_col
			var from_i = from_row + from_col
			var pos = from_i - to_i
				
			if(pos == 2):
				print("UP <- LEFT")
				put_coin(to_row,to_col, curr_player)
			elif(pos == -2):
				print("DOWN -> RIGHT")
				put_coin(from_row,from_col,curr_player)
			elif(pos == 0):
				if (to_col > from_col and to_row < from_row):
					print("UP & RIGHT")
					put_coin(to_row,from_col,curr_player)
				else:
					print("DOWN & LEFT")
					put_coin(from_row,to_col,curr_player)
			put_pin(from_row, from_col, to_row, to_col, current_pin_to_move)
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
	
	
func _ready() -> void:
	move_pin('a5b4', 'X')
	move_pin('a3a4', 'O')
	move_pin('a6b5', 'X')
	move_pin('a4c4', 'O')
	print("I did something new...")
	

	
