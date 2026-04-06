extends Node

var GAME_MODE = null
var AI_MODE_LEVEL = null
var hosting = false

var username 
var player_id
var color
var background_color
var current_score

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
