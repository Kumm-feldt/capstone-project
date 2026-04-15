extends Node

var music_player: AudioStreamPlayer
var default_track = "res://Sound/Music/menu_loop.wav"
var match_track = "res://Sound/Music/game_loop.wav"
var current_track: GameManager.TrackMode = GameManager.TrackMode.Default
var victory_stinger = "res://Sound/Music/stinger_victory_v2.wav"
var defeat_stinger = "res://Sound/Music/stinger_defeat_v2.wav"

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	play_track_path(default_track)

func play_track_path(path: String) -> void:
	var new_stream = load(path)
	if music_player.stream == new_stream:
		return  # already playing this track
	music_player.stop()
	music_player.stream = new_stream
	music_player.play()

func stop_music() -> void:
	music_player.stop()

func play_default_track():
	play_track(default_track)

func play_match_track():
	stop_music()
	play_track(match_track)

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
