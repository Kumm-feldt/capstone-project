extends Node
var board: Node

const SERVER_PORT = 7777
const LAN_BROADCAST_PORT = 42355
const BROADCAST_ADDRESS = "255.255.255.255"
const HOST = "Team5" # Name of the player hosting TODO: make it dynamic

var players = {}
var discovered_servers = {}

var host_udp
var client_udp
var broadcast_timer = 1.0
var peer
var is_hosting = false

# ============================================
# SIGNALS
# ============================================
signal game_ready
signal discovered_servers_ui


func _ready():
	# safely initialize 
	client_udp = PacketPeerUDP.new()
	client_udp.bind(LAN_BROADCAST_PORT, "*")
	host_udp = PacketPeerUDP.new()	

func _process(delta):
	# LISTEN for hosts
	if client_udp:
		var count = client_udp.get_available_packet_count()
		if count > 0:
			while client_udp.get_available_packet_count() > 0:
				var raw = client_udp.get_packet() # peek to set IP metadata
				var sender_ip = client_udp.get_packet_ip() # host ip
				var packet = bytes_to_var(raw)
				discovered_servers[sender_ip] = packet
				# Emit signal to update UI list
				emit_signal("discovered_servers_ui", discovered_servers)
				
	# BROADCAST	if we are hosting
	if is_hosting:
		broadcast_timer -= delta
		if broadcast_timer <= 0.0:
			broadcast_timer = 0.3
			host_udp.set_dest_address(BROADCAST_ADDRESS, LAN_BROADCAST_PORT)
			var data = {"port": SERVER_PORT, "name": "Creeper Match", "host": HOST}
			host_udp.put_var(data)


func host_game():
	broadcast_timer = 0.3  # broadcast immediately instead of waiting 1 second
	is_hosting = true
	# enable broadcast
	host_udp.set_broadcast_enabled(true)
	var server_peer = ENetMultiplayerPeer.new()
	server_peer.create_server(SERVER_PORT)
	
	multiplayer.multiplayer_peer = server_peer
	# when a player connects to our server then it will call add_player_to_game
	multiplayer.peer_connected.connect(_add_player_to_game) 
	
	# clean up player and remove from game
	multiplayer.peer_disconnected.connect(_del_player)
	_add_player_to_game(1)  # host is always peer ID 1 in Godot
	
func join_game(server_ip):
	print("Player 2 joining")
	var client_peer = ENetMultiplayerPeer.new()
	client_peer.create_client(server_ip, SERVER_PORT)
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

		
# ============================================
# RCP
# ============================================
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
