extends CharacterBody2D

const ACCEL = 200.0
const AIR_IDLE_ACCEL = ACCEL/20.0
const SPEED = 300.0
const JUMP_VELOCITY = -800.0
const JUMP_BUFFER_SIZE = 6
const GROUND_BUFFER_SIZE = 6
const JUMP_DIVIDE = 3.0
const BOOST_MULT = 1.5
const WALL_SLIDE_THRESH_LEFT = 11.0
const WALL_SLIDE_THRESH_RIGHT = 16.0
const RAY_CAST_LENGTH = 30.0
enum State {IDLE, WALKING, # Grounded states
			JUMPING, FALLING, # Airborne states
			HOOK_EXTEND, HOOK_PULL, # Hook states
			WALL_SLIDING, WALL_CLINGED} # Wall states

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
	var wall_direction 
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
		# Raycast to handle wall slide/jump. Might be refactored ?? 
		var space_state = get_world_2d().direct_space_state
		var query_right = PhysicsRayQueryParameters2D.create(global_position, global_position+Vector2(RAY_CAST_LENGTH, 0))
		var query_left = PhysicsRayQueryParameters2D.create(global_position, global_position+Vector2(-RAY_CAST_LENGTH, 0))
		var result_right = space_state.intersect_ray(query_right)
		var result_left = space_state.intersect_ray(query_left)
		if result_left and abs(global_position.x - result_left.position.x) <= WALL_SLIDE_THRESH_LEFT:
			state = State.WALL_SLIDING
			wall_direction = 1
		elif result_right and abs(global_position.x - result_right.position.x) <= WALL_SLIDE_THRESH_RIGHT:
			state = State.WALL_SLIDING
			wall_direction = -1
		elif velocity.y < 0:
			state = State.JUMPING
		else:
			state = State.FALLING
	# Handle the "ground jump" for jump variation ONLY form the ground
	if state in [State.JUMPING, State.WALL_SLIDING] and velocity.y<0 and is_ground_jumping and\
	 (Input.is_action_pressed("jump") or Input.is_action_just_released("jump")):
		is_ground_jumping = true
	else:
		is_ground_jumping = false
		
		
	
	# DEBUG purpose (state)
#	$Label.text = State.keys()[state] + (" ground_jump" if is_ground_jumping else "")
	# Update the animation
	if direction:
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
			is_ground_jumping = true
		if not direction: # Deceleration
			velocity.x = move_toward(velocity.x, 0, ACCEL)
	if state in [State.JUMPING, State.FALLING, State.WALL_SLIDING]: # Handle Gravity airborne
		velocity.y += gravity * delta
		# Jump variation
		if is_ground_jumping and Input.is_action_just_released("jump"):
			velocity.y /= JUMP_DIVIDE
		# Handle direction airborne: move only if does not "slow down" the character
		if direction and (direction*velocity.x < SPEED): 
			velocity.x = move_toward(velocity.x, direction*SPEED, ACCEL)
		if not direction: # Deceleration
			velocity.x = move_toward(velocity.x, 0, AIR_IDLE_ACCEL)
	if state in [State.WALL_SLIDING]: # Handle wall jump
		if does_jump:
			velocity.y = JUMP_VELOCITY
			velocity.x = -JUMP_VELOCITY*wall_direction
			reset_bool_buffer(jump_buffer)
			reset_bool_buffer(ground_buffer)
	if state in [State.FALLING]:
		if does_be_floor and does_jump: # Handle the "roll jump"
			velocity.y = JUMP_VELOCITY
			reset_bool_buffer(jump_buffer)
			reset_bool_buffer(ground_buffer)
			is_ground_jumping = true
	if state in [State.HOOK_EXTEND]:
		set_velocity(Vector2(0.0, 0.0))
	if state in [State.HOOK_PULL]:
		velocity = $Hook.hook_speed * $Hook.hook_direction
		if does_jump:
				$Hook.reset_hook()
				velocity *= BOOST_MULT
				velocity.y = min(JUMP_VELOCITY, velocity.y)
				reset_bool_buffer(jump_buffer)
				reset_bool_buffer(ground_buffer)

	if get_last_slide_collision():
		# Check if tile collided is fatal. Maybe too compplicated, is there a simpler way ?
		var collider = get_last_slide_collision().get_collider()
#		$ColliderLabel.text = str(get_last_slide_collision().get_normal())
		if collider is TileMap:
			var collision_pos = get_last_slide_collision().get_position()
			var tilemap_collision_pos = collider.local_to_map(collider.to_local(collision_pos))
			var cell_tile_data = collider.get_cell_tile_data(0, tilemap_collision_pos)
			if cell_tile_data and cell_tile_data.get_custom_data("fatal"):
				death.emit()
	move_and_slide()


