extends Node

const SFX_PLAYER_COUNT := 8

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var next_sfx_player_index := 0
var current_track: GameManager.TrackMode = GameManager.TrackMode.Default

#Background definitions
var default_track = "res://Sound/Music/menu_loop.wav"
var match_track = "res://Sound/Music/game_loop.wav"

#SFX definitions
var victory_stinger = "res://Sound/Music/stinger_victory_v2.wav"
var defeat_stinger = "res://Sound/Music/stinger_defeat_v2.wav"
var button = "res://Sound/SFX/Button_1.wav"
var explosion = "res://Sound/SFX/Explostion_1.wav"
var node = "res://Sound/SFX/Node on Board_2.wav"
var jump = "res://Sound/SFX/Land_1.wav"
var land = "res://Sound/SFX/Land_3.wav"
# need to implement still
var error = "res://Sound/SFX/Error-2.wav"
var reboot = "res://Sound/SFX/Reboot_1.wav"

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)
	for index in range(SFX_PLAYER_COUNT):
		var sfx_player = AudioStreamPlayer.new()
		sfx_player.bus = "SFX"
		sfx_player.name = "SFXPlayer%d" % index
		sfx_players.append(sfx_player)
		add_child(sfx_player)
	play_track_path(default_track)

func play_track_path(path: String) -> void:
	var new_stream = load(path)
	if music_player.stream == new_stream:
		return  # already playing this track
	music_player.stop()
	music_player.stream = new_stream
	music_player.play()

func play_sfx_path(path: String) -> void:
	var new_stream = load(path)
	if new_stream == null:
		return
	var sfx_player = _get_sfx_player()
	if sfx_player.playing:
		sfx_player.stop()
	sfx_player.stream = new_stream
	sfx_player.play()

func _get_sfx_player() -> AudioStreamPlayer:
	for sfx_player in sfx_players:
		if not sfx_player.playing:
			return sfx_player

	var sfx_player = sfx_players[next_sfx_player_index]
	next_sfx_player_index = (next_sfx_player_index + 1) % sfx_players.size()
	return sfx_player

func stop_music() -> void:
	music_player.stop()
	
func pause_music() -> void:
	music_player.stream_paused = true;

func resume_music() -> void:
	music_player.stream_paused = false;

func play_default_track():
	play_track(GameManager.TrackMode.Default)

func play_match_track():
	play_track(GameManager.TrackMode.Match)
	
func play_button_sound():
	play_sfx_path(button)

func play_explosion():
	play_sfx_path(explosion)

func play_add_node():
	play_sfx_path(node)

func play_jump_sound():
	play_sfx_path(jump)
	
func play_land_sound():
	play_sfx_path(land)

func play_track(option: GameManager.TrackMode) -> void:
	current_track = option
	stop_music()
	match option:
		GameManager.TrackMode.Default:
			play_track_path(default_track)
		GameManager.TrackMode.Match:
			play_track_path(match_track)     
		GameManager.TrackMode.Victory:
			play_track_path(victory_stinger) 
		GameManager.TrackMode.Defeat:
			play_track_path(defeat_stinger)  
			
func is_playing_track(option: GameManager.TrackMode) -> bool:
	return music_player.playing and current_track == option
