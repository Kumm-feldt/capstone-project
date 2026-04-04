extends Node
var board: Node

const SERVER_PORT = 7777
const LAN_BROADCAST_PORT = 42355
const BROADCAST_ADDRESS = "255.255.255.255"
var HOST =  getHostName()

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
signal match_ended_(username)

func getHostName():
	var config = ConfigFile.new()
	if config.load("user://save.cfg") == OK:
		return config.get_value("player", "username")
	else:
		return "undefined"

func _ready():
	# safely initialize 
	client_udp = PacketPeerUDP.new()
	client_udp.bind(LAN_BROADCAST_PORT, "*")
	host_udp = PacketPeerUDP.new()	
	multiplayer.server_disconnected.connect(_on_server_disconnected)


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

func stop_searching():
	# Stop listening for broadcasts
	if client_udp:
		client_udp.close()  # closes UDP socket [web:6]
		client_udp = null

	discovered_servers.clear()
	emit_signal("discovered_servers_ui", discovered_servers)	

func stop_hosting():
	is_hosting = false
	broadcast_timer = 0.0

	# Stop ENet server
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()  # closes ENetMultiplayerPeer [web:8]
		multiplayer.multiplayer_peer = null

	# Stop broadcasting UDP
	if host_udp:
		host_udp.close()  # closes UDP socket [web:6]
		host_udp = null

	players.clear()	
	

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
	if sender_id == 1 and GameState.current_player == 'x':
		return true
	elif sender_id != 1 and GameState.current_player == 'o':
		return true
	print("Returning False...")
	return false

func leave_match_as_client():
	print("Client is leaving the match...")
	
	client_leaves.rpc()  # goes to server because it’s authority [web:25]

	if multiplayer.multiplayer_peer:
		# Tell ENet to disconnect from the server [web:8]
		multiplayer.multiplayer_peer.disconnect_peer(1)
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null


func leave_match_as_host():
	print("Host is leaving the match...")
	# Tell client via RPC that match is ending
	host_leaves.rpc()

	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()  # kills server and all clients [web:8]
		multiplayer.multiplayer_peer = null

	players.clear()
	is_hosting = false

	# Also stop LAN broadcast if you’re in a “live lobby”
	if host_udp:
		host_udp.close()
		host_udp = null

	
func _on_server_disconnected():
	print("Server closed, returning to menu")
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")  # or “Host left” dialog [web:23]		

# ============================================
# RCP
# ============================================
@rpc("authority", "call_local", "reliable")
func notify_all_players_ready():
	emit_signal.call_deferred("game_ready")  # fires on ALL machines

# rpc emit signal to let the other peer the user left the match
@rpc("any_peer", "reliable")
func match_ended(username):
	print("match ended, user left: ", username)
	emit_signal("match_ended_",username)
		
@rpc("any_peer", "reliable")
func send_move(coord):
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

# Someone tells the server they are leaving
@rpc("any_peer", "reliable")
func client_leaves():
	var leaver_id := multiplayer.get_remote_sender_id()  # who called this [web:24][web:47]
	print("Client leaving, id: ", leaver_id)

	# Figure out the remaining peer id (host is always 1)
	var remaining_id := 1 if leaver_id != 1 else 0  # 0 means “no other peer”

	var username := ""
	if leaver_id == 1:
		username = HOST
	else:
		username = players[leaver_id].username  

	# Tell remaining peer (if any) that match ended
	if remaining_id != 0:
		match_ended.rpc_id(remaining_id, username)
	# tiny delay before closing, optional but can help
	await get_tree().process_frame
	
	# Also emit locally on server, so host’s UI can react
	emit_signal("match_ended_", username)

# Someone tells the server they are leaving
@rpc("any_peer", "reliable")
func host_leaves():
	# Also emit locally on server, so host’s UI can react
	emit_signal("match_ended_", HOST)
