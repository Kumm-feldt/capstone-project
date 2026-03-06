extends Node

const SERVER_PORT = 7777
const SERVER_IP = "127.0.0.1"
var players = {}

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


@rpc("authority", "call_local", "reliable")
func notify_all_players_ready():
	emit_signal.call_deferred("game_ready")  # fires on ALL machines
	
func _del_player(id: int):
	players.erase(id)
	print("Player left: ", id)

func _on_connected_to_server():
	print("Successfully connected!")
	# tell JoinGameScreen to stop showing "Searching..." and enter the lobby

func _on_connection_failed():
	print("Connection failed!")
	# tell JoinGameScreen to show "No games found" + Search Again button
