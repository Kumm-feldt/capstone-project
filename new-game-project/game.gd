extends Node2D

var pins = [
	[".", "o", "o", ".", "x", "x", "."],
	["o", ".", ".", ".", ".", ".", "x"],
	["o", ".", ".", ".", ".", ".", "x"],
	[".", ".", ".", ".", ".", ".", "."],
	["x", ".", ".", ".", ".", ".", "o"],
	["x", ".", ".", ".", ".", ".", "o"],
	[".", "x", "x", ".", "o", "o", "."]
]

var coins = [
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

func move_pin(coordinates, curr_player):
	# turns abcdef coordinates into index for matrix
	var from_c = coordinates[0]
	var from_c_index_0 = int(coordinates[1])-1
	var from_c_index_1 = from_c.unicode_at(0) - "a".unicode_at(0)
	
	var to_c = coordinates[2]
	var to_c_index_0 = int(coordinates[3])-1
	var to_c_index_1 = to_c.unicode_at(0) - "a".unicode_at(0)
	
	var current_pin_to_move = pins[from_c_index_0][from_c_index_1]
	var next_pos = pins[to_c_index_0][to_c_index_1]
	
	# check if the next position is available
	if(next_pos == '.'):
		# calculate if next pos is r, l, d, u
		var to_i = to_c_index_0 + to_c_index_1
		var from_i = from_c_index_0 + from_c_index_1
		var pos = from_i - to_i
		var diag_move = false
		
		if(pos == 1):
			print("UP")
		elif (pos == -1):
			print("DOWN")
		elif(pos == 2):
			print("UP <- LEFT")
			# put a COIN
			coins[to_c_index_0][to_c_index_1] = curr_player

		elif(pos == -2):
			print("DOWN -> RIGHT")
			# put a COIN
			coins[from_c_index_0][from_c_index_1] = curr_player
			
		elif(pos == 0):
			diag_move = true
			if (to_c_index_1 > from_c_index_1 and to_c_index_0 < from_c_index_0):
				print("UP & RIGHT")
				# put a COIN
				coins[to_c_index_0][from_c_index_1] = curr_player

			else:
				print("DOWN & LEFT")
				# put a COIN
				coins[from_c_index_0][to_c_index_1] = curr_player

		# if it was a diagonal move
		if (diag_move):
			print("Diag move")
			# move it to next position
			# if cell == currentplayer -> move pin
			pins[to_c_index_0][to_c_index_1] = current_pin_to_move
			
			# if cell == blank -> put coin
			# if cell == player2 -> flip coin
			
		else:
			# move it to next position
			pins[to_c_index_0][to_c_index_1] = current_pin_to_move
		
		pins[from_c_index_0][from_c_index_1] = '.'
		
		
	else:
		print("ERROR")
	print_nice_board(pins)
	print("\n")
	print_nice_board(coins)
		

func move_coin():
	pass

func isGameOver():
	return true	
	
	
func _ready() -> void:
	move_pin('a5b4', 'X')
	move_pin('b4c5', 'X')
	move_pin('c5b6', 'X')
	
	

	
