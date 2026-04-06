extends Node

var GAME_MODE = null
var AI_MODE_LEVEL = null
var hosting = false

var username 
var player_id
var color
var background_color
var current_score
var player1_color = Color(1.0, 0.206, 0.154, 1.0)
var player2_color = Color(0.211, 0.439, 1.0, 1.0)

var multiplayer_username

enum Mode {
	Local,
	AI,
	Multiplayer,
	Join,
	Host
}

enum AILevel {
	Easy,
	Difficult
}
