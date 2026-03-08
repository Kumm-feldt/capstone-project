extends AnimatedSprite2D

var player: String
var playerColor: Color


func set_pin(ownerPlayer: String, givenPlayerColor: Color) -> void:
	"""Set up the pin according to its player."""
	player = ownerPlayer;
	
	playerColor = givenPlayerColor;
	modulate = givenPlayerColor;
	
	self.play("idle");
	
func _input(event: InputEvent) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		pin_move_diagonal_down(false);
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		pin_move_up();
	
func play_appropriate_animation(currentPosition: Vector2, newPosition: Vector2) -> void:
	# Is newPosition orthogonal to currentPosition?
	if (currentPosition.dot(newPosition) == 0):
		# Figure out if jumping or not
		print();
	else:
	 	# Call diagonal_move in the right direction, with the right flip animation
		print();
			
	return
	
func pin_diagonal_move(direction: Vector2, targetDisc: Sprite2D) -> void:
	#if (direction == Vector2(1, 1)):
	#	print();
	#else: if (direction == Vector2(1, -1)):
	#	print();
	#else: if (direction == Vector2(-1, -1)):
	#	print();
	#else: if (direction == Vector2(-1, 1)):
	#	print();
	
	#Step one: start moving in the right direction
	
	#Step two: play corresponding pin animation
	
		
	
	#Step three: make the disc change its color
	
	return
	
func pin_move_up() -> void:
	play("upPrepJump");
	await self.animation_finished;
	play("upJump");
	
	self.z_index = 50
	
	var newPos = Vector2(global_position)
	
	var tween1 = create_tween()
	newPos += Vector2(0, -10)
	tween1.tween_property(self, "global_position", newPos, 0.2)
	await tween1.finished
	var tween2 = create_tween()
	newPos += Vector2(0, -30)
	tween2.tween_property(self, "global_position", newPos, 0.1)
	await tween2.finished
	var tween3 = create_tween()
	newPos += Vector2(0, -10)
	tween3.tween_property(self, "global_position", newPos, 0.2)
	await tween3.finished
	
	play("upEndJump")
	
	await self.animation_finished;
	
	self.z_index = 0
	
	play("idle")
	
	return
	
func pin_move_down() -> void:
	play("downPrepJump");
	await self.animation_finished;
	play("downJump");
	
	self.z_index = 50
	
	var newPos = Vector2(global_position)
	
	var tween1 = create_tween()
	newPos += Vector2(0, 10)
	tween1.tween_property(self, "global_position", newPos, 0.2)
	await tween1.finished
	var tween2 = create_tween()
	newPos += Vector2(0, 30)
	tween2.tween_property(self, "global_position", newPos, 0.1)
	await tween2.finished
	var tween3 = create_tween()
	newPos += Vector2(0, 10)
	tween3.tween_property(self, "global_position", newPos, 0.2)
	await tween3.finished
	
	play("downEndJump")
	
	await self.animation_finished;
	
	self.z_index = 0
	
	play("idle")
	
	return
	
func pin_move_horizontal(left: bool) -> void:
	if not left:
		self.flip_h = true;
		
		play("diagonalDownPrepJump");
		await self.animation_finished;
		play("diagonalDownJump");
	
		var newPos = Vector2(global_position)
	
		var tween1 = create_tween()
		newPos += Vector2(20, -25)
		tween1.tween_property(self, "global_position", newPos, 0.2)
		await tween1.finished
		var tween2 = create_tween()
		newPos += Vector2(10, 0)
		tween2.tween_property(self, "global_position", newPos, 0.1)
		await tween2.finished
		var tween3 = create_tween()
		newPos += Vector2(20, 25)
		tween3.tween_property(self, "global_position", newPos, 0.2)
		await tween3.finished
		play("diagonalDownEndJump")
		await self.animation_finished;
		
		self.flip_h = false;
	else:
		play("diagonalDownPrepJump");
		await self.animation_finished;
		play("diagonalDownJump");
		
		var newPos = Vector2(global_position)
	
		var tween1 = create_tween()
		newPos += Vector2(-20, -25)
		tween1.tween_property(self, "global_position", newPos, 0.2)
		await tween1.finished
		var tween2 = create_tween()
		newPos += Vector2(-10, 0)
		tween2.tween_property(self, "global_position", newPos, 0.1)
		await tween2.finished
		var tween3 = create_tween()
		newPos += Vector2(-20, 25)
		tween3.tween_property(self, "global_position", newPos, 0.2)
		await tween3.finished
		play("diagonalDownEndJump")
		await self.animation_finished;
	
	play ("idle")
	return
	
func pin_move_diagonal_up(left: bool) -> void:
	if not left:
		self.flip_h = true;
		
		play("diagonalUpPrepJump");
		await self.animation_finished;
		play("diagonaUpJump");
	
		var newPos = Vector2(global_position)
	
		var tween1 = create_tween()
		newPos += Vector2(10, -30)
		tween1.tween_property(self, "global_position", newPos, 0.2)
		await tween1.finished
		var tween2 = create_tween()
		newPos += Vector2(10, -10)
		tween2.tween_property(self, "global_position", newPos, 0.1)
		await tween2.finished
		var tween3 = create_tween()
		newPos += Vector2(30, -10)
		tween3.tween_property(self, "global_position", newPos, 0.2)
		await tween3.finished
		play("diagonalUpEndJump")
		await self.animation_finished;
		
		self.flip_h = false;
	else:
		play("diagonalUpPrepJump");
		await self.animation_finished;
		play("diagonalUpJump");
		
		var newPos = Vector2(global_position)
	
		var tween1 = create_tween()
		newPos += Vector2(-10, -30)
		tween1.tween_property(self, "global_position", newPos, 0.2)
		await tween1.finished
		var tween2 = create_tween()
		newPos += Vector2(-10, -10)
		tween2.tween_property(self, "global_position", newPos, 0.1)
		await tween2.finished
		var tween3 = create_tween()
		newPos += Vector2(-30, -10)
		tween3.tween_property(self, "global_position", newPos, 0.2)
		await tween3.finished
		play("diagonalUpEndJump")
		await self.animation_finished;
	
	play ("idle")
	return
	
func pin_move_diagonal_down(left: bool) -> void:
	if not left:
		self.flip_h = true;
		
		play("diagonalDownPrepJump");
		await self.animation_finished;
		play("diagonalDownJump");
	
		var newPos = Vector2(global_position)
	
		var tween1 = create_tween()
		newPos += Vector2(30, 10)
		tween1.tween_property(self, "global_position", newPos, 0.2)
		await tween1.finished
		var tween2 = create_tween()
		newPos += Vector2(10, 10)
		tween2.tween_property(self, "global_position", newPos, 0.1)
		await tween2.finished
		var tween3 = create_tween()
		newPos += Vector2(10, 30)
		tween3.tween_property(self, "global_position", newPos, 0.2)
		await tween3.finished
		play("diagonalDownEndJump")
		await self.animation_finished;
		
		self.flip_h = false;
	else:
		play("diagonalDownPrepJump");
		await self.animation_finished;
		play("diagonalDownJump");
		
		var newPos = Vector2(global_position)
	
		var tween1 = create_tween()
		newPos += Vector2(-30, 10)
		tween1.tween_property(self, "global_position", newPos, 0.2)
		await tween1.finished
		var tween2 = create_tween()
		newPos += Vector2(-10, 10)
		tween2.tween_property(self, "global_position", newPos, 0.1)
		await tween2.finished
		var tween3 = create_tween()
		newPos += Vector2(-10, 30)
		tween3.tween_property(self, "global_position", newPos, 0.2)
		await tween3.finished
		play("diagonalDownEndJump")
		await self.animation_finished;
	
	play ("idle")
	return
