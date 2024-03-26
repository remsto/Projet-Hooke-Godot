extends CharacterBody2D

const ACCEL = 200.0
const SPEED = 300.0
const JUMP_VELOCITY = -600.0
const JUMP_BUFFER_SIZE = 6
const GROUND_BUFFER_SIZE = 6
enum State {IDLE, WALKING, # Grounded states
			GROUND_JUMPING, JUMPING, FALLING, # Airborne states
			HOOK_EXTEND, HOOK_PULL} # Hook states

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var screen_size
var jump_buffer : Array
var ground_buffer : Array
var is_ground_jumping : bool
var state = State.IDLE

signal death

func _ready():
	$AnimatedSprite2D.animation = "idle"
	$AnimatedSprite2D.play()
	screen_size = get_viewport_rect().size
	jump_buffer = []
	ground_buffer = []
	is_ground_jumping = false
	for i in range(JUMP_BUFFER_SIZE):
		jump_buffer.append(false)
	for i in range(GROUND_BUFFER_SIZE):
		ground_buffer.append(false)
	
# The "buffers" here work as conveyor belt:
# - The last value (biggest index) is removed
# - All values are shifted right by 1 (toward bigger index)
# - The new value is inserted at the beginning (index 0)
# Then we return the "bool value" of the buffer, which is an OR of all its elements
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
	var direction = Input.get_axis("left", "right")
	var does_jump = process_bool_buffer(jump_buffer, Input.is_action_just_pressed("jump"))
	var does_be_floor = process_bool_buffer(ground_buffer, is_on_floor())
	var does_ground_jump = false
	# Determine the state on simple conditions
	if $Hook.is_extending:
		state = State.HOOK_EXTEND
	elif $Hook.is_pulling:
		state = State.HOOK_PULL
	elif is_on_floor():
		if direction:
			state = State.WALKING
		else:
			state = State.IDLE
	else: # Not on floor 
		if velocity.y < 0 and state == State.GROUND_JUMPING and \
		(Input.is_action_pressed("jump") or Input.is_action_just_released("jump")):
			state = State.GROUND_JUMPING
		elif velocity.y < 0:
			state = State.JUMPING
		else:
			state = State.FALLING
	$Label.text = State.keys()[state]
	# Update the animation
	$AnimatedSprite2D.flip_h = velocity.x < 0
	if state == State.WALKING:
		$AnimatedSprite2D.animation = "walk"
	else:
		$AnimatedSprite2D.animation = "idle"
			
	# Handle the physic according to the state
	if state in [State.WALKING]: # Handle walk
		velocity.x = move_toward(velocity.x, direction*SPEED, ACCEL)
	if state in [State.WALKING, State.IDLE]: # Handle Jump
		if does_jump:
			velocity.y = JUMP_VELOCITY
			reset_bool_buffer(jump_buffer)
			reset_bool_buffer(ground_buffer)
			state = State.GROUND_JUMPING
			does_ground_jump = true
		if not direction: # Deceleration
			velocity.x = move_toward(velocity.x, 0, ACCEL)
	if state in [State.JUMPING, State.FALLING, State.GROUND_JUMPING]: # Handle Gravity airborne
		velocity.y += gravity * delta
		# Handle direction airborne: move only if does not "slow down" the character
		if direction and (direction*velocity.x < SPEED): 
			velocity.x = move_toward(velocity.x, direction*SPEED, ACCEL)
		if not direction: # Deceleration
			velocity.x = move_toward(velocity.x, 0, ACCEL)
	if state in [State.GROUND_JUMPING]: # Handle Jump Variations
		if Input.is_action_just_released("jump"):
			velocity.y /= 3.0
	if state in [State.FALLING]:
		if does_be_floor and does_jump: # Handle the "roll jump"
			velocity.y = JUMP_VELOCITY
			reset_bool_buffer(jump_buffer)
			reset_bool_buffer(ground_buffer)
			state = State.GROUND_JUMPING			
			does_ground_jump = true
	if state in [State.HOOK_EXTEND]:
		set_velocity(Vector2(0.0, 0.0))
	if state in [State.HOOK_PULL]:
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


