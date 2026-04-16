extends Node


var current_line = 0
var waiting_for_move = false
var waiting_for_capture = false
var tutorial_done = false
var toot = null
var wait_for_move_lines = [14, 17, 21]
var wait_for_capture_lines = [19]

var lines = [
	"Hello!   My   name   is   Teacher   Of   Ophidian   Technologies,   or   T.O.O.T.",
	"Ophidian   is   another   word   for   snakes.",
	"Welcome   to   Slither!   Your   goal   is   to   connect   your   snake's   head   and   tail   with   an   unbroken   chain   of   nodes.",
	"First,   let's   look   at   the   board.",
	"The   6x6   grid   is   where   nodes   are   placed.   This   is   called   the   grid.",
	"The   line   intersections   around   those   spaces   are   where   robots   move.",
	"Your   snake's   head   and   tail   are   at   opposite   corners   of   the   grid.",
	"To   win,   create   a   connected   chain   of   nodes   between   those   two   corners!",
	"Only   orthogonal   connections   count   -   up,   down,   left   or   right.",
	"On   your   turn,   move   exactly   ONE   robot   of   your   color!",
	"There   are   three   kinds   of   moves:   diagonal   jump,   orthogonal   move,   and   capture   jump.",
	"The   diagonal   jump   is   the   most   important   -   it   is   how   you   place   nodes!",
	"Move   a   robot   one   space   diagonally   to   place   a   node   on   the   space   it   passes   over.",
	"If   that   space   has   your   opponent's   node,   it   flips   to   your   color!",
	"Go   ahead   -   try   moving   a   robot   diagonally!",
	"You   can   also   move   a   robot   one   space   up,   down,   left,   or   right.   This   is   an   orthogonal   move.",
	"Orthogonal   moves   do   not   place   nodes   -   they   reposition   your   robots.",
	"Try   moving   a   robot   orthogonally!",
	"You   can   capture   an   opponent   robot   by   jumping   over   it   in   a   straight   line   into   an   empty   space.",
	"Try   capturing   an   opponent   robot!",
	"Destroying   ALL   opponent   robots   ends   in   a   draw   -   be   careful!",
	"When   your   chain   connects   head   and   tail,   you   win   immediately!",
	"That   is   Slither!   Move   robots,   place   nodes,   build   your   chain.",
	"Feel   free   to   finish   this   game   or   start   a   new   one.   Good   luck,   and   have   fun!",
	
]
func _ready():
	toot = get_parent().get_node_or_null("TutorialRobot")
	if toot == null:
		push_error("TutorialOverlay: Could not find TutorialRobot node")
		return
	GameState.connect("valid_move", _on_player_moved)
	GameState.connect("pin_jumped", _on_pin_jumped)
	await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout
	start_tutorial()

func start_tutorial():
	await toot.wakeUp()
	show_current_line()

func show_current_line():
	if current_line >= lines.size():
		toot.hide_bubble()
		tutorial_done = true
		return
	if current_line in wait_for_capture_lines:
		waiting_for_capture = true
		waiting_for_move = false
		toot.say_wait_for_move(lines[current_line])
	elif current_line in wait_for_move_lines:
		waiting_for_move = true
		waiting_for_capture = false
		toot.say_wait_for_move(lines[current_line])
	else:
		waiting_for_move = false
		waiting_for_capture = false
		toot.say(lines[current_line])

func _on_player_moved():
	if waiting_for_move and not waiting_for_capture:
		waiting_for_move = false
		current_line += 1
		show_current_line()

func _on_pin_jumped(_from_pos, _to_pos, _removed_pos, player):
	# Only count the human player's jump (player "o")
	if waiting_for_capture and player == "o":
		waiting_for_capture = false
		current_line += 1
		show_current_line()

func _unhandled_input(event):
	if tutorial_done:
		return
	if event is InputEventMouseButton and event.pressed:
		if not waiting_for_move and not waiting_for_capture:
			current_line += 1
			show_current_line()
