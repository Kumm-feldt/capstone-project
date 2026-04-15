extends Node

var GAME_OPENED = false;

var GAME_MODE = null
var AI_MODE_LEVEL = null
var hosting = false
var IS_TUTORIAL: bool = false

var username 
var player_id
var color

var icon_color
var background_color
var profile_picture


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

enum TrackMode {
	Default,
	Match,
	Victory,
	Defeat,
}

enum AILevel {
	Easy,
	Difficult
}

func get_safe_color(raw) -> Color:
	if raw is Color:
		return raw
	elif raw is String and raw.length() > 0:
		# Hex format: "#rrggbb" or "rrggbbaa"
		if raw.begins_with("#") or raw.length() == 6 or raw.length() == 8:
			return Color.from_string(raw, Color.GRAY)
		# Godot str(Color) format: "(0.98, 1.0, 0.52, 1.0)"
		var cleaned = raw.strip_edges().trim_prefix("(").trim_suffix(")")
		var parts = cleaned.split(",")
		if parts.size() == 4:
			return Color(
				float(parts[0].strip_edges()),
				float(parts[1].strip_edges()),
				float(parts[2].strip_edges()),
				float(parts[3].strip_edges())
			)
		return Color.from_string(raw, Color.GRAY)
	else:
		push_warning("Invalid color value: " + str(raw))
		return Color.GRAY
