extends CharacterBody2D

const ACCEL = 200.0
const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const JUMP_BUFFER_SIZE = 6
const GROUND_BUFFER_SIZE = 6

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var screen_size
var jump_buffer : Array
var ground_buffer : Array

signal death

func _ready():
	$AnimatedSprite2D.animation = "idle"
	$AnimatedSprite2D.play()
	screen_size = get_viewport_rect().size
	jump_buffer = []
	for i in range(JUMP_BUFFER_SIZE):
		jump_buffer.append(false)
	for i in range(GROUND_BUFFER_SIZE):
		ground_buffer.append(false)
	

func process_bool_buffer(buffer : Array, new_value : bool) -> bool:
	var buffer_value : bool = new_value
	for i in range(buffer.size() - 1, 0, -1):
		buffer[i] = buffer[i-1]
		buffer_value = (buffer_value or buffer[i])
	buffer[0] = new_value
	return buffer_value
	
func reset_bool_buffer(buffer : Array) -> void:
	for i in range(buffer.size()):
		buffer[i] = false

func _physics_process(delta):
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("left", "right")
	# Handle jump and jump buffer
	var does_jump = process_bool_buffer(jump_buffer, Input.is_action_just_pressed("jump"))
	var does_be_floor = process_bool_buffer(ground_buffer, is_on_floor())
	var accel
	var max_speed
	if not ($Hook.is_extending or $Hook.is_pulling):
		# Add the gravity.
		if not is_on_floor():
			velocity.y += gravity * delta
		# Handle Jump.
		if does_jump and does_be_floor:
			velocity.y = JUMP_VELOCITY
			reset_bool_buffer(jump_buffer)
			reset_bool_buffer(ground_buffer)
		accel = ACCEL
		max_speed = SPEED
		if direction:
			if direction*velocity.x < max_speed:
				velocity.x = move_toward(velocity.x, direction*max_speed, accel)
			$AnimatedSprite2D.animation = "walk"
			$AnimatedSprite2D.flip_h = velocity.x < 0
		else:
			velocity.x = move_toward(velocity.x, 0, ACCEL)
			$AnimatedSprite2D.animation = "idle"
	else:
		set_velocity(Vector2(0.0, 0.0))
		if $Hook.is_pulling:
			velocity = $Hook.hook_speed * $Hook.hook_direction
			if does_jump:
				$Hook.reset_hook()
				velocity.y = min(JUMP_VELOCITY, velocity.y)
				reset_bool_buffer(jump_buffer)
				reset_bool_buffer(ground_buffer)
	if move_and_slide():
		# Check if tile collided is fatal. Maybe too compplicated, is there a simpler way ?
		var collider = get_last_slide_collision().get_collider()
		if collider is TileMap:
			var collision_pos = get_last_slide_collision().get_position()
			var tilemap_collision_pos = collider.local_to_map(collider.to_local(collision_pos))
			var cell_tile_data = collider.get_cell_tile_data(0, tilemap_collision_pos)
			if cell_tile_data and cell_tile_data.get_custom_data("fatal"):
				death.emit()


