extends Node

const SERVER_PORT = 7777
const SERVER_IP = "127.0.0.1"
var players = {}
var board: Node

# ============================================
# SIGNALS
# ============================================
signal game_ready

func host_game():
	print("Starting host!")
	var server_peer = ENetMultiplayerPeer.new()
	server_peer.create_server(SERVER_PORT)
	
	multiplayer.multiplayer_peer = server_peer
	# when a player connects to our server then it will call add_player_to_game
	multiplayer.peer_connected.connect(_add_player_to_game) 
	
	# clean up player and remove from game
	multiplayer.peer_disconnected.connect(_del_player)
	_add_player_to_game(1)  # host is always peer ID 1 in Godot
	

func join_game():
	print("Player 2 joining")
	var client_peer = ENetMultiplayerPeer.new()
	client_peer.create_client(SERVER_IP, SERVER_PORT)
	multiplayer.multiplayer_peer = client_peer
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)

# pass network id 
func _add_player_to_game(id: int):
	players[id] = {"id" : id, "username": "Player"}
	print("Player joined: ", id)
	if players.size() == 2:  # both players connected
		notify_all_players_ready.rpc()  # tell EVERYONE including client
	
func _del_player(id: int):
	players.erase(id)
	print("Player left: ", id)

func _on_connected_to_server():
	print("Successfully connected!")
	# tell JoinGameScreen to stop showing "Searching..." and enter the lobby

func _on_connection_failed():
	print("Connection failed!")
	# tell JoinGameScreen to show "No games found" + Search Again button

func is_valid_player_turn(sender_id):
	print("=============================")
	print("sender_id: ", sender_id)
	print("current playe: ", GameState.current_player)
	print("=============================")
	
	if sender_id == 1 and GameState.current_player == 'x':
		return true
	elif sender_id != 1 and GameState.current_player == 'o':
		return true
	print("Returning False...")
	return false
		

@rpc("authority", "call_local", "reliable")
func notify_all_players_ready():
	emit_signal.call_deferred("game_ready")  # fires on ALL machines
	
@rpc("any_peer", "reliable")
func send_move(coord):
	print("send_move hitted")
	# Only the server processes incoming moves
	if not multiplayer.is_server():
		return
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = 1 #host called it directly
	# validate it is this players turn
	if not is_valid_player_turn(sender_id):
		return
		
	# tell the board to apply the move on all peers
	rpc("confirm_move", coord)
	confirm_move(coord) # run locally on server

		
@rpc("authority", "reliable")
func confirm_move(coord):
	# This runs on every peer — board applies the move
	GameState.move_pin(coord, GameState.current_player)
