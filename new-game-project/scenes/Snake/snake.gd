extends Node2D

const CELL_SIZE := 78
const STEP_TIME := 0.3
const START_LENGTH := 3
const SEGMENT_SCALE := Vector2(4.5, 4.5)
const TOP_BUFFER_ROWS := 0
const BOARD_TILES_X := 13
const BOARD_TILES_Y := 8
const START_SCREEN_SCENE := preload("res://scenes/Snake/snake_start_screen.tscn")
const WIN_SCREEN_SCENE := preload("res://scenes/Snake/snake_win_screen.tscn")
const LOSE_SCREEN_SCENE := preload("res://scenes/Snake/snake_lose_screen.tscn")

@onready var snake_player: Node2D = $SnakePlayer
@onready var snake_head: Sprite2D = $SnakePlayer/SnakeHead
@onready var body_template: Sprite2D = $SnakePlayer/SnakeBody
@onready var snake_food: AnimatedSprite2D = $SnakeFood
@onready var playfield: ColorRect = $SnakeBox/ColorRect3
@onready var snake_tile: Node2D = $SnakeTile
@onready var score_label: Label = $Score
@onready var title_label: Label = $Title

var board_origin := Vector2.ZERO
var grid_size := Vector2i.ZERO
var move_timer := 0.0
var direction := Vector2i(1, 0)
var queued_direction := Vector2i(1, 0)
var snake_cells: Array[Vector2i] = []
var body_segments: Array[Sprite2D] = []
var food_cell := Vector2i.ZERO
var score := 0
var game_over := false
var game_started := false
var rng := RandomNumberGenerator.new()
var start_screen: Node2D
var win_screen: Node2D
var lose_screen: Node2D


func _ready() -> void:
	rng.randomize()
	snake_player.position = Vector2.ZERO
	snake_player.scale = Vector2.ONE
	snake_head.z_index = 1
	snake_head.scale = SEGMENT_SCALE
	body_template.z_index = 0
	body_template.scale = SEGMENT_SCALE
	body_template.visible = false
	snake_food.scale = SEGMENT_SCALE
	snake_food.play()
	_configure_board()
	_setup_menu_screens()
	_show_start_screen()


func _process(delta: float) -> void:
	if not game_started:
		return

	move_timer += delta

	if game_over:
		return

	while move_timer >= STEP_TIME:
		move_timer -= STEP_TIME
		_step()
		if game_over:
			break


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if not game_started:
			return

		var next_direction := _direction_from_key(event.keycode)
		if next_direction != Vector2i.ZERO:
			_queue_turn(next_direction)
			get_viewport().set_input_as_handled()
			return

		if game_over and event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
			_restart_round()
			get_viewport().set_input_as_handled()


func _configure_board() -> void:
	grid_size = Vector2i(BOARD_TILES_X, BOARD_TILES_Y - TOP_BUFFER_ROWS)
	var board_rect := _get_board_rect()
	var board_size := Vector2(grid_size.x * CELL_SIZE, grid_size.y * CELL_SIZE)
	board_origin = board_rect.position + ((board_rect.size - board_size) / 2.0) + Vector2(CELL_SIZE / 2.0, CELL_SIZE / 2.0)
	board_origin.y += CELL_SIZE * TOP_BUFFER_ROWS


func _get_board_rect() -> Rect2:
	var tile_rect := _get_sprite_bounds(snake_tile)
	if tile_rect.size != Vector2.ZERO:
		return tile_rect
	return Rect2(playfield.global_position, playfield.size)


func _get_sprite_bounds(root: Node) -> Rect2:
	var has_bounds := false
	var min_point := Vector2.ZERO
	var max_point := Vector2.ZERO

	for child in root.get_children():
		if child is not Sprite2D:
			continue

		var sprite := child as Sprite2D
		if sprite.texture == null:
			continue

		var sprite_rect := sprite.get_rect()
		var corners := [
			sprite_rect.position,
			sprite_rect.position + Vector2(sprite_rect.size.x, 0.0),
			sprite_rect.position + sprite_rect.size,
			sprite_rect.position + Vector2(0.0, sprite_rect.size.y),
		]

		for corner in corners:
			var global_corner := sprite.to_global(corner)
			if not has_bounds:
				min_point = global_corner
				max_point = global_corner
				has_bounds = true
				continue

			min_point.x = minf(min_point.x, global_corner.x)
			min_point.y = minf(min_point.y, global_corner.y)
			max_point.x = maxf(max_point.x, global_corner.x)
			max_point.y = maxf(max_point.y, global_corner.y)

	if not has_bounds:
		return Rect2()

	return Rect2(min_point, max_point - min_point)


func _start_new_round() -> void:
	for segment in body_segments:
		segment.queue_free()
	body_segments.clear()

	game_over = false
	move_timer = 0.0
	score = 0
	direction = Vector2i(1, 0)
	queued_direction = Vector2i(1, 0)
	title_label.text = "SNAKE"
	_update_score()

	var start_x: int = maxi(START_LENGTH + 1, grid_size.x / 2)
	var start_y: int = maxi(1, grid_size.y / 2)
	snake_cells.clear()
	for offset in range(START_LENGTH):
		snake_cells.append(Vector2i(start_x - offset, start_y))

	snake_food.visible = true
	_spawn_food()
	_sync_visuals()
	game_started = true
	_hide_all_screens()


func _step() -> void:
	direction = queued_direction
	var new_head := snake_cells[0] + direction
	var food_eaten := new_head == food_cell

	if not _is_inside_board(new_head):
		_end_run("GAME OVER")
		return

	var occupied_cells: Array[Vector2i] = []
	occupied_cells.append_array(snake_cells)
	if not food_eaten and not occupied_cells.is_empty():
		occupied_cells.pop_back()

	if occupied_cells.has(new_head):
		_end_run("GAME OVER")
		return

	snake_cells.insert(0, new_head)
	if food_eaten:
		score += 1
		_update_score()
		if not _spawn_food():
			_sync_visuals()
			_end_run("YOU WIN")
			return
	else:
		snake_cells.pop_back()

	_sync_visuals()


func _spawn_food() -> bool:
	var free_cells: Array[Vector2i] = []
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var cell := Vector2i(x, y)
			if not snake_cells.has(cell):
				free_cells.append(cell)

	if free_cells.is_empty():
		snake_food.visible = false
		return false

	food_cell = free_cells[rng.randi_range(0, free_cells.size() - 1)]
	snake_food.visible = true
	snake_food.position = _cell_to_position(food_cell)
	return true


func _sync_visuals() -> void:
	var required_segments: int = snake_cells.size() - 1
	while body_segments.size() < required_segments:
		var segment: Sprite2D = body_template.duplicate() as Sprite2D
		segment.visible = true
		segment.z_index = 0
		snake_player.add_child(segment)
		body_segments.append(segment)

	while body_segments.size() > required_segments:
		var last_index: int = body_segments.size() - 1
		var segment: Sprite2D = body_segments[last_index]
		body_segments.remove_at(last_index)
		segment.queue_free()

	snake_head.position = _cell_to_position(snake_cells[0])
	_update_head_orientation()

	for index in range(required_segments):
		body_segments[index].position = _cell_to_position(snake_cells[index + 1])


func _queue_turn(next_direction: Vector2i) -> void:
	if snake_cells.size() > 1 and next_direction == Vector2i(-direction.x, -direction.y):
		return
	queued_direction = next_direction


func _direction_from_key(keycode: int) -> Vector2i:
	match keycode:
		KEY_UP, KEY_W:
			return Vector2i(0, -1)
		KEY_DOWN, KEY_S:
			return Vector2i(0, 1)
		KEY_LEFT, KEY_A:
			return Vector2i(-1, 0)
		KEY_RIGHT, KEY_D:
			return Vector2i(1, 0)
		_:
			return Vector2i.ZERO


func _update_head_orientation() -> void:
	snake_head.rotation_degrees = 0.0
	match direction:
		Vector2i(1, 0):
			snake_head.flip_h = true
		Vector2i(-1, 0):
			snake_head.flip_h = false
		Vector2i(0, -1):
			snake_head.flip_h = true
			snake_head.rotation_degrees = -90.0
		Vector2i(0, 1):
			snake_head.flip_h = true
			snake_head.rotation_degrees = 90.0


func _update_score() -> void:
	score_label.text = "%03d" % score


func _end_run(message: String) -> void:
	game_over = true
	if message == "YOU WIN":
		title_label.text = message
		_show_overlay(win_screen)
	else:
		_show_overlay(lose_screen)


func _is_inside_board(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < grid_size.x and cell.y < grid_size.y


func _cell_to_position(cell: Vector2i) -> Vector2:
	return board_origin + Vector2(cell.x * CELL_SIZE, cell.y * CELL_SIZE)


func _setup_menu_screens() -> void:
	start_screen = START_SCREEN_SCENE.instantiate() as Node2D
	win_screen = WIN_SCREEN_SCENE.instantiate() as Node2D
	lose_screen = LOSE_SCREEN_SCENE.instantiate() as Node2D

	add_child(start_screen)
	add_child(win_screen)
	add_child(lose_screen)

	start_screen.z_index = 100
	win_screen.z_index = 100
	lose_screen.z_index = 100

	var start_button := start_screen.get_node_or_null("Button2") as Button
	if start_button:
		start_button.pressed.connect(_on_start_button_pressed)

	var win_restart_button := win_screen.get_node_or_null("Button2") as Button
	if win_restart_button:
		win_restart_button.pressed.connect(_on_restart_button_pressed)

	var lose_restart_button := lose_screen.get_node_or_null("Button2") as Button
	if lose_restart_button:
		lose_restart_button.pressed.connect(_on_restart_button_pressed)

	_hide_all_screens()


func _show_start_screen() -> void:
	_hide_all_screens()
	start_screen.visible = true
	game_started = false
	game_over = true
	title_label.text = "SNAKE"
	score = 0
	_update_score()


func _show_overlay(screen: Node2D) -> void:
	_hide_all_screens()
	screen.visible = true


func _hide_all_screens() -> void:
	if start_screen:
		start_screen.visible = false
	if win_screen:
		win_screen.visible = false
	if lose_screen:
		lose_screen.visible = false


func _restart_round() -> void:
	_start_new_round()


func _on_start_button_pressed() -> void:
	Music.play_button_sound()
	_start_new_round()


func _on_restart_button_pressed() -> void:
	Music.play_button_sound()
	_restart_round()
