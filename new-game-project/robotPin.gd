extends AnimatedSprite2D

var player: String
var color: Color
signal movement_finished

# Call this after creating the pin to set its appropriate status.
func set_pin(ownerPlayer: String, givenColor: Color) -> void:
	"""Set up the pin according to its player."""
	player = ownerPlayer;
	
	color = givenColor;
	
	setRobotPinColor(color);
	
	self.play("idle");
	
func setRobotPinColor(givenColor: Color) -> void:
	color = givenColor
	set_instance_shader_parameter("tint_color", color)
	set_instance_shader_parameter("tint_effect", 1)
	set_instance_shader_parameter("brightness", 1)


func play_invalid_animation() -> void:
	self.play("invalid");
	await self.animation_finished;
	self.play("idle");

# If the pin is just moving, pass it the current pin position and the desired position.
func play_movement_animation(currentPosition: Vector2, newPosition: Vector2) -> void:
	#dir is the direction to the new position
	var dir = newPosition - currentPosition;
	if (dir == Vector2(0, -1)):			# Move Up
		await _pin_move_up()
	else: if (dir == Vector2(1, -1)):	# Move Diagonal Up & Right
		await _pin_move_diagonal_up(false)
	else: if (dir == Vector2(1, 0)):	# Move Right
		await _pin_move_horizontal(false)
	else: if (dir == Vector2(1, 1)):	# Move Diagonal Down & Right
		await _pin_move_diagonal_down(false)
	else: if (dir == Vector2(0, 1)):	# Move Down
		await _pin_move_down()
	else: if (dir == Vector2(-1, 1)):	# Move Diagonal Down & Left
		await _pin_move_diagonal_down(true)
	else: if (dir == Vector2(-1, 0)):	# Move Left
		await _pin_move_horizontal(true)
	else: if (dir == Vector2(-1, -1)):	# Move Diagonal Up & Left
		await _pin_move_diagonal_up(true)

	movement_finished.emit()
	return

# If the pin is capturing, pass the currentPos, newPos, and the pin to be captured.
# If you don't pass the captured pin, it can't explode at the right time.
func play_capture_animation(currentPosition: Vector2, newPosition: Vector2, capTarget: AnimatedSprite2D) -> void:
	var dir = newPosition - currentPosition;
	print("went in the play_capture_animation")
	if dir == Vector2(0, -2):
		await _pin_capture_up(capTarget)
	else: if dir == Vector2(0, 2):
		await _pin_capture_down(capTarget)
	else: if dir == Vector2(-2, 0):
		await _pin_capture_left(capTarget);
	else: if dir == Vector2(2, 0):
		await _pin_capture_right(capTarget);
	movement_finished.emit()
	return


#The following methods should not be accessed by any script outside of this one.
func explode() -> void:
	play("explode")
	await self.animation_finished;
	return

func _pin_capture_up(capTarget: AnimatedSprite2D) -> void:
	
	play("upPrepJump");
	await self.animation_finished;
	play("upJump");
	
	self.z_index = 50
	
	var newPos = Vector2(position)
	
	var tween1 = create_tween()
	newPos += Vector2(0, -10)
	tween1.tween_property(self, "position", newPos, 0.2)
	await tween1.finished
	var tween2 = create_tween()
	newPos += Vector2(0, -30)
	tween2.tween_property(self, "position", newPos, 0.1)
	await tween2.finished
	var tween3 = create_tween()
	newPos += Vector2(0, -20)
	tween3.tween_property(self, "position", newPos, 0.2)
	await tween3.finished
	
	play("bounceUp")
	await animation_finished
	capTarget.explode()
	Music.play_explosion()
	
	play("upJump")
	
	var tween4 = create_tween()
	newPos += Vector2(0, -15)
	tween4.tween_property(self, "position", newPos, 0.2)
	await tween4.finished
	var tween5 = create_tween()
	newPos += Vector2(0, -10)
	tween5.tween_property(self, "position", newPos, 0.1)
	await tween5.finished
	var tween6 = create_tween()
	newPos += Vector2(0, -15)
	tween6.tween_property(self, "position", newPos, 0.2)
	await tween6.finished
	
	self.z_index = 0
	
	play("upEndJump")
	
	await self.animation_finished;
	
	play("idle")
	
	return
	
func _pin_capture_down(capTarget: AnimatedSprite2D) -> void:
	play("downPrepJump");
	await self.animation_finished;
	play("downJump");
	
	self.z_index = 50
	
	var newPos = Vector2(position)
	
	var tween1 = create_tween()
	newPos += Vector2(0, 10)
	tween1.tween_property(self, "position", newPos, 0.2)
	await tween1.finished
	var tween2 = create_tween()
	newPos += Vector2(0, 30)
	tween2.tween_property(self, "position", newPos, 0.1)
	await tween2.finished
	var tween3 = create_tween()
	newPos += Vector2(0, 20)
	tween3.tween_property(self, "position", newPos, 0.2)
	await tween3.finished
	
	play("bounceDown")
	await animation_finished
	capTarget.explode()
	Music.play_explosion()
	
	play("downJump")
	
	var tween4 = create_tween()
	newPos += Vector2(0, 15)
	tween4.tween_property(self, "position", newPos, 0.2)
	await tween4.finished
	var tween5 = create_tween()
	newPos += Vector2(0, 10)
	tween5.tween_property(self, "position", newPos, 0.1)
	await tween5.finished
	var tween6 = create_tween()
	newPos += Vector2(0, 15)
	tween6.tween_property(self, "position", newPos, 0.2)
	await tween6.finished
	
	self.z_index = 0
	
	play("downEndJump")
	
	await self.animation_finished;
	
	play("idle")
	return
	
func _pin_capture_left(capTarget: AnimatedSprite2D) -> void:
	
	play("diagonalDownPrepJump");
	await self.animation_finished;
	play("diagonalDownJump");
	
	self.z_index = 50
	
	var newPos = Vector2(position)
	
	var tween1 = create_tween()
	newPos += Vector2(-20, -25)
	tween1.tween_property(self, "position", newPos, 0.2)
	await tween1.finished
	var tween2 = create_tween()
	newPos += Vector2(-10, 5)
	tween2.tween_property(self, "position", newPos, 0.1)
	await tween2.finished
	var tween3 = create_tween()
	newPos += Vector2(-20, 10)
	tween3.tween_property(self, "position", newPos, 0.2)
	await tween3.finished
	
	play("bounceLeft")
	await animation_finished
	capTarget.explode()
	Music.play_explosion()
	
	play("diagonalDownJump")
	
	var tween4 = create_tween()
	newPos += Vector2(-20, -20)
	tween4.tween_property(self, "position", newPos, 0.2)
	await tween4.finished
	var tween5 = create_tween()
	newPos += Vector2(-10, 10)
	tween5.tween_property(self, "position", newPos, 0.1)
	await tween5.finished
	var tween6 = create_tween()
	newPos += Vector2(-20, 20)
	tween6.tween_property(self, "position", newPos, 0.2)
	await tween6.finished
	
	self.z_index = 0
	
	play("diagonalDownEndJump")
	
	await self.animation_finished;
	
	play("idle")
	return
	
func _pin_capture_right(capTarget: AnimatedSprite2D) -> void:
	self.flip_h = true;
	
	play("diagonalDownPrepJump");
	await self.animation_finished;
	play("diagonalDownJump");
	
	self.z_index = 50
	
	var newPos = Vector2(position)
	
	var tween1 = create_tween()
	newPos += Vector2(20, -25)
	tween1.tween_property(self, "position", newPos, 0.2)
	await tween1.finished
	var tween2 = create_tween()
	newPos += Vector2(10, 5)
	tween2.tween_property(self, "position", newPos, 0.1)
	await tween2.finished
	var tween3 = create_tween()
	newPos += Vector2(20, 10)
	tween3.tween_property(self, "position", newPos, 0.2)
	await tween3.finished
	
	play("bounceLeft")
	await animation_finished
	capTarget.explode()
	Music.play_explosion()
	
	play("diagonalDownJump")
	
	var tween4 = create_tween()
	newPos += Vector2(20, -20)
	tween4.tween_property(self, "position", newPos, 0.2)
	await tween4.finished
	var tween5 = create_tween()
	newPos += Vector2(10, 10)
	tween5.tween_property(self, "position", newPos, 0.1)
	await tween5.finished
	var tween6 = create_tween()
	newPos += Vector2(20, 20)
	tween6.tween_property(self, "position", newPos, 0.2)
	await tween6.finished
	
	self.z_index = 0
	
	play("diagonalDownEndJump")
	
	await self.animation_finished;
	
	play("idle")
	
	self.flip_h = false;
	
	return


func _pin_move_up() -> void:
	play("upPrepJump");
	await self.animation_finished;
	play("upJump");
	
	self.z_index = 50
	
	var newPos = Vector2(position)
	
	var tween1 = create_tween()
	newPos += Vector2(0, -10)
	tween1.tween_property(self, "position", newPos, 0.2)
	await tween1.finished
	var tween2 = create_tween()
	newPos += Vector2(0, -30)
	tween2.tween_property(self, "position", newPos, 0.1)
	await tween2.finished
	var tween3 = create_tween()
	newPos += Vector2(0, -10)
	tween3.tween_property(self, "position", newPos, 0.2)
	await tween3.finished
	
	play("upEndJump")
	
	await self.animation_finished;
	
	self.z_index = 0
	
	play("idle")
	
	return
	
func _pin_move_down() -> void:
	play("downPrepJump");
	await self.animation_finished;
	play("downJump");
	
	self.z_index = 50
	
	var newPos = Vector2(position)
	
	var tween1 = create_tween()
	newPos += Vector2(0, 10)
	tween1.tween_property(self, "position", newPos, 0.2)
	await tween1.finished
	var tween2 = create_tween()
	newPos += Vector2(0, 30)
	tween2.tween_property(self, "position", newPos, 0.1)
	await tween2.finished
	var tween3 = create_tween()
	newPos += Vector2(0, 10)
	tween3.tween_property(self, "position", newPos, 0.2)
	await tween3.finished
	
	play("downEndJump")
	
	await self.animation_finished;
	
	self.z_index = 0
	
	play("idle")
	
	return
	
func _pin_move_horizontal(left: bool) -> void:
	if not left:
		self.flip_h = true;
		
		play("diagonalDownPrepJump");
		await self.animation_finished;
		play("diagonalDownJump");
	
		var newPos = Vector2(position)
	
		var tween1 = create_tween()
		newPos += Vector2(20, -25)
		tween1.tween_property(self, "position", newPos, 0.2)
		await tween1.finished
		var tween2 = create_tween()
		newPos += Vector2(10, 0)
		tween2.tween_property(self, "position", newPos, 0.1)
		await tween2.finished
		var tween3 = create_tween()
		newPos += Vector2(20, 25)
		tween3.tween_property(self, "position", newPos, 0.2)
		await tween3.finished
		play("diagonalDownEndJump")
		await self.animation_finished;
		
		self.flip_h = false;
	else:
		play("diagonalDownPrepJump");
		await self.animation_finished;
		play("diagonalDownJump");
		
		var newPos = Vector2(position)
	
		var tween1 = create_tween()
		newPos += Vector2(-20, -25)
		tween1.tween_property(self, "position", newPos, 0.2)
		await tween1.finished
		var tween2 = create_tween()
		newPos += Vector2(-10, 0)
		tween2.tween_property(self, "position", newPos, 0.1)
		await tween2.finished
		var tween3 = create_tween()
		newPos += Vector2(-20, 25)
		tween3.tween_property(self, "position", newPos, 0.2)
		await tween3.finished
		play("diagonalDownEndJump")
		await self.animation_finished;
	
	play ("idle")
	return
	
func _pin_move_diagonal_up(left: bool) -> void:
	if not left:
		self.flip_h = true;
		
		play("diagonalUpPrepJump");
		await self.animation_finished;
		play("diagonalUpJump");
	
		var newPos = Vector2(position)
	
		var tween1 = create_tween()
		newPos += Vector2(10, -30)
		tween1.tween_property(self, "position", newPos, 0.2)
		await tween1.finished
		var tween2 = create_tween()
		newPos += Vector2(10, -10)
		tween2.tween_property(self, "position", newPos, 0.1)
		await tween2.finished
		var tween3 = create_tween()
		newPos += Vector2(30, -10)
		tween3.tween_property(self, "position", newPos, 0.2)
		await tween3.finished
		play("diagonalUpEndJump")
		await self.animation_finished;
		
		self.flip_h = false;
	else:
		play("diagonalUpPrepJump");
		await self.animation_finished;
		play("diagonalUpJump");
		
		var newPos = Vector2(position)
	
		var tween1 = create_tween()
		newPos += Vector2(-10, -30)
		tween1.tween_property(self, "position", newPos, 0.2)
		await tween1.finished
		var tween2 = create_tween()
		newPos += Vector2(-10, -10)
		tween2.tween_property(self, "position", newPos, 0.1)
		await tween2.finished
		var tween3 = create_tween()
		newPos += Vector2(-30, -10)
		tween3.tween_property(self, "position", newPos, 0.2)
		await tween3.finished
		play("diagonalUpEndJump")
		await self.animation_finished;
	
	play ("idle")
	return
	
func _pin_move_diagonal_down(left: bool) -> void:
	if not left:
		self.flip_h = true;
		
		play("diagonalDownPrepJump");
		await self.animation_finished;
		play("diagonalDownJump");
	
		var newPos = Vector2(position)
	
		var tween1 = create_tween()
		newPos += Vector2(30, 10)
		tween1.tween_property(self, "position", newPos, 0.2)
		await tween1.finished
		var tween2 = create_tween()
		newPos += Vector2(10, 10)
		tween2.tween_property(self, "position", newPos, 0.1)
		await tween2.finished
		var tween3 = create_tween()
		newPos += Vector2(10, 30)
		tween3.tween_property(self, "position", newPos, 0.2)
		await tween3.finished
		play("diagonalDownEndJump")
		await self.animation_finished;
		
		self.flip_h = false;
	else:
		play("diagonalDownPrepJump");
		await self.animation_finished;
		play("diagonalDownJump");
		
		var newPos = Vector2(position)
	
		var tween1 = create_tween()
		newPos += Vector2(-30, 10)
		tween1.tween_property(self, "position", newPos, 0.2)
		await tween1.finished
		var tween2 = create_tween()
		newPos += Vector2(-10, 10)
		tween2.tween_property(self, "position", newPos, 0.1)
		await tween2.finished
		var tween3 = create_tween()
		newPos += Vector2(-10, 30)
		tween3.tween_property(self, "position", newPos, 0.2)
		await tween3.finished
		play("diagonalDownEndJump")
		await self.animation_finished;
	
	play ("idle")
	return
