extends Node

var GAME_MODE = null
var AI_MODE_LEVEL = null
var username 
var player_id
var color
var background_color

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
