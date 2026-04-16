extends Node
var board: Node

const SERVER_PORT = 7777
const LAN_BROADCAST_PORT = 42355
const BROADCAST_ADDRESS = "255.255.255.255"
var HOST =  getHostName()[0]

var players = {}
var discovered_servers = {}

var host_udp
var client_udp
var broadcast_timer = 1.0
var peer
var is_hosting = false

var host_id := 1
var client_id := 0

# ============================================
# SIGNALS
# ============================================
signal game_ready
signal discovered_servers_ui
signal end_match(username)
signal ready_to_leave

func getHostName():
	var config = ConfigFile.new()
	if config.load("user://save.cfg") == OK:
		var username = config.get_value("player", "username")
		var icon_profile_pic = config.get_value("player", "picture")
		
		return [username, icon_profile_pic]
	else:
		return "undefined"

func search_hosts():
	client_udp = PacketPeerUDP.new()
	client_udp.bind(LAN_BROADCAST_PORT, "*")

func _ready():
	discovered_servers.clear()
	emit_signal("discovered_servers_ui", discovered_servers)
	# safely initialize 
	
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
				if packet.get("closing", false):
					# Host announced it stopped — remove it
					discovered_servers.erase(sender_ip)
				else:
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
	if not host_udp:
		host_udp = PacketPeerUDP.new()	 
	if multiplayer.peer_connected.is_connected(_add_player_to_game):
		multiplayer.peer_connected.disconnect(_add_player_to_game)
	if multiplayer.peer_disconnected.is_connected(_del_player):
		multiplayer.peer_disconnected.disconnect(_del_player)
		
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
		client_udp.close()  # closes UDP socket 
		client_udp = null

	discovered_servers.clear()
	emit_signal("discovered_servers_ui", discovered_servers)	

func stop_hosting():
	is_hosting = false
	broadcast_timer = 0.0

	# Stop broadcasting UDP
	if host_udp:
		host_udp.set_broadcast_enabled(true)
		host_udp.set_dest_address(BROADCAST_ADDRESS, LAN_BROADCAST_PORT)
		var goodbye = {"port": SERVER_PORT, "name": "Creeper Match", "host": HOST, "closing": true}
		host_udp.put_var(goodbye)
		host_udp.close()
		host_udp = null
	# Stop ENet server
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()  # closes ENetMultiplayerPeer 
		multiplayer.multiplayer_peer = null

	players.clear()	
	

func join_game(server_ip):
	print("Player 2 joining")
	# Disconnect stale signals first
	if multiplayer.connected_to_server.is_connected(_on_connected_to_server):
		multiplayer.connected_to_server.disconnect(_on_connected_to_server)
	if multiplayer.connection_failed.is_connected(_on_connection_failed):
		multiplayer.connection_failed.disconnect(_on_connection_failed)
	
	var client_peer = ENetMultiplayerPeer.new()
	client_peer.create_client(server_ip, SERVER_PORT)
	multiplayer.multiplayer_peer = client_peer
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)

# pass network id 
func _add_player_to_game(id: int):
	if id == 1:
		# Host registers itself directly
		players[1] = { "username": HOST }
		print("Host added: ", HOST)

	
func _del_player(id: int):
	players.erase(id)
	print("Player left: ", id)

func _on_connected_to_server():
	print("Successfully connected!")
	var username = getHostName()[0]
	var icon_profile_pic = getHostName()[1]
	register_user.rpc_id(1, username, icon_profile_pic)
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
	client_leaves.rpc()  # goes to server because it’s authority


func leave_match_as_host():
	print("1) leave_match_as_host")
	# 1. Notify the client the match ended
	match_ended.rpc(HOST)          # server CAN call this (authority)

	# 2. Tell client to disconnect
	confirm_client_disconnect.rpc_id(client_id, 1, "HOST")  # leaver_id = 1 = host
	# Wait one frame so packets actually go out
	await get_tree().process_frame
	
	# 3. Clean up host locally — no RPC needed
	#emit_signal("end_match", HOST)
	confirm_host_disconnect()      # call directly, not via rpc()

func _on_server_disconnected():
	print("Server closed, returning to menu")
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")  # or “Host left” dialog [web:23]		

# ============================================
# RCP
# ============================================
@rpc("authority", "call_local", "reliable")
func notify_all_players_ready():
	emit_signal.call_deferred("game_ready")  # fires on ALL machines
		
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

@rpc("authority", "call_local", "reliable")
func sync_game_over(winner: String):
	GameState.emit_signal("game_over", winner)

# rpc emit signal to let the other peer the user left the match
@rpc("authority", "reliable")
func match_ended(username):
	emit_signal("end_match", username)
	
# Someone tells the server they are leaving
@rpc("any_peer", "reliable")
func client_leaves():
	print("client_leaves called on server")
	var leaver_id := multiplayer.get_remote_sender_id()
	var username = players[leaver_id].username if players.has(leaver_id) else "Unknown"

	# Notify the remaining peer
	for peer_id in multiplayer.get_peers():
		if peer_id != leaver_id:
			match_ended.rpc_id(peer_id, username)

	# Also fire locally on host
	emit_signal("end_match", username)

	# NOW tell the client it's safe to disconnect
	confirm_client_disconnect.rpc_id(leaver_id, leaver_id, "Client")

# Server → client: "okay, you can go now"
@rpc("authority", "call_remote", "reliable")
func confirm_client_disconnect(leaver_id, user):
	print("4) confirm_client_disconnect ")
	print("Server confirmed disconnect, closing connection...")
	var my_id = multiplayer.get_unique_id()  # save BEFORE closing peer

	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	# Only auto-leave if I'm the one who initiated the disconnect
	if leaver_id == my_id:
		emit_signal("ready_to_leave")
	
@rpc("any_peer", "reliable")
func request_force_end(winner: String):
	if not multiplayer.is_server():
		return
	sync_game_over.rpc(winner)  # server broadcasts to both peers
	
# client -> server: this is my name
@rpc("any_peer", "reliable")
func register_user(username, icon_profile_pic):
	var sender_id := multiplayer.get_remote_sender_id()
	GameManager.multiplayer_username = username
	GameManager.multiplayer_icon = icon_profile_pic
	players[sender_id] = { "username": username, "icon_profile_pic": icon_profile_pic}
	client_id = sender_id
	if players.size() == 2:  # both players connected
		notify_all_players_ready.rpc()  # tell EVERYONE including client

# 2) HOST NETWORK CLEANUP: run ONLY on host
@rpc("authority", "call_local", "reliable")
func confirm_host_disconnect():
	players.clear()
	is_hosting = false
	if host_udp:
		host_udp.close()
		host_udp = null
	emit_signal("ready_to_leave") 
