extends CharacterBody2D

const ACCEL = 200.0 * 60
const AIR_ACCEL = 30.0 * 60
const AIR_IDLE_ACCEL = ACCEL/20.0
const SPEED = 250.0
const JUMP_VELOCITY = -600.0
const WALL_JUMP_VELOCITY = 400.0
const JUMP_BUFFER_SIZE = 6
const GROUND_BUFFER_SIZE = 6
const JUMP_DIVIDE = 3.0
const BOOST_MULT = 1.0
const WALL_SLIDE_THRESH_LEFT = 7.0
const WALL_SLIDE_THRESH_RIGHT = 7.0
const RAY_CAST_LENGTH = 30.0
const WALL_JUMP_TIME = 0
const CAM_ZOOM_SPEED = 0.005
enum State {IDLE, WALKING, # Grounded states
			JUMPING, FALLING, # Airborne states
			HOOK_EXTEND, HOOK_PULL, # Hook states
			WALL_SLIDING, WALL_CLINGED} # Wall states

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity") * 1.0
var screen_size
var jump_buffer : Array
var ground_buffer : Array
var is_ground_jumping : bool
var is_wall_jumping : bool
var wall_jump_counter
var wall_direction 
var state = State.IDLE
var viewport_width

signal death

func _ready():
	$AnimatedSprite2D.animation = "idle"
	$AnimatedSprite2D.play()
	screen_size = get_viewport_rect().size
	jump_buffer = []
	ground_buffer = []
	is_ground_jumping = false
	is_wall_jumping = false
#	wall_jump_timer.one_shot = false
	wall_jump_counter = 0
	for i in range(JUMP_BUFFER_SIZE):
		jump_buffer.append(false)
	for i in range(GROUND_BUFFER_SIZE):
		ground_buffer.append(false)
	viewport_width = get_viewport().get_visible_rect().size.x
	
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
		
# Perform a ray cast horizontally and return the collided object if near enough
func ray_cast(ray_length, threshold):
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, global_position+Vector2(ray_length, 0), collision_mask)
	var result = space_state.intersect_ray(query)
	if result and abs(global_position.x - result.position.x) <= threshold:
		return result
		
func get_collided_tilemap_data(collider):
	if collider is TileMapLayer:
		var collision_pos = get_last_slide_collision().get_position()
		var tilemap_collision_pos = collider.local_to_map(collider.to_local(collision_pos))
		var cell_tile_data = collider.get_cell_tile_data(tilemap_collision_pos)
		return cell_tile_data
	
	
func _process(delta):
#	if velocity.x:
#		var cam_pos = viewport_width/4.0 if velocity.x > 0 else 0
#		$PlayerCamera.position.x = viewport_width/4.0
	pass

func _physics_process(delta):
	var direction = Input.get_axis("left", "right")
	var does_jump = process_bool_buffer(jump_buffer, Input.is_action_just_pressed("jump"))
	var does_be_floor = process_bool_buffer(ground_buffer, is_on_floor())

	# Determine the state on simple conditions
	if $Hook.is_extending:
		state = State.HOOK_EXTEND
	elif $Hook.is_pulling:
		state = State.HOOK_PULL
		# Raycast to handle wall slide/jump.
		if $Hook.scale.x <= 2.0 and ray_cast(-RAY_CAST_LENGTH, WALL_SLIDE_THRESH_LEFT):
			$Hook.reset_hook()
			state = State.WALL_CLINGED
			wall_direction = 1
		elif $Hook.scale.x <= 2.0 and ray_cast(RAY_CAST_LENGTH, WALL_SLIDE_THRESH_RIGHT):
			$Hook.reset_hook()			
			state = State.WALL_CLINGED
			wall_direction = -1
	elif is_on_floor():
		if direction:
			state = State.WALKING
		else:
			state = State.IDLE
	else: # Not on floor
		var ray_left = ray_cast(-RAY_CAST_LENGTH, WALL_SLIDE_THRESH_LEFT)
		var ray_right = ray_cast(RAY_CAST_LENGTH, WALL_SLIDE_THRESH_RIGHT)
		if state == State.WALL_CLINGED:
			pass
		# Raycast to handle wall slide/jump. Might be refactored ?? 
		elif ray_left:
			state = State.WALL_SLIDING
			wall_direction = 1
		elif ray_right:
			state = State.WALL_SLIDING
			wall_direction = -1
		elif velocity.y < 0:
			state = State.JUMPING
		else:
			state = State.FALLING
	# Handle the "ground jump" for jump variation ONLY from the ground
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
		velocity.x = move_toward(velocity.x, direction*SPEED, ACCEL*delta)
	if state in [State.WALKING, State.IDLE]: # Handle Jump
		if does_jump:
			velocity.y = JUMP_VELOCITY
			reset_bool_buffer(jump_buffer)
			reset_bool_buffer(ground_buffer)
			is_ground_jumping = true
		if not direction: # Deceleration
			velocity.x = move_toward(velocity.x, 0, ACCEL*delta)
	if state in [State.WALL_CLINGED]:
		velocity = Vector2(0.0, 0.0)
		if does_jump:
			wall_jump_counter = WALL_JUMP_TIME
			state = State.JUMPING
			velocity.y = JUMP_VELOCITY
			velocity.x = WALL_JUMP_VELOCITY*wall_direction
			reset_bool_buffer(jump_buffer)
			reset_bool_buffer(ground_buffer)
	if state in [State.JUMPING, State.FALLING, State.WALL_SLIDING]: # Handle Gravity airborne
		velocity.y += gravity * delta
		# Jump variation
		if is_ground_jumping and Input.is_action_just_released("jump"):
			velocity.y /= JUMP_DIVIDE
		if wall_jump_counter: # 
			wall_jump_counter -= 1
		else:
			# Handle direction airborne: move only if does not "slow down" the character
			if direction and (direction*velocity.x < SPEED): 
				velocity.x = move_toward(velocity.x, direction*SPEED, AIR_ACCEL*delta)
			if not direction: # Deceleration
				velocity.x = move_toward(velocity.x, 0, AIR_IDLE_ACCEL*delta)
	if state in [State.WALL_SLIDING]: # Handle wall jump
		if does_jump:
			wall_jump_counter = WALL_JUMP_TIME			
			velocity.y = JUMP_VELOCITY
			velocity.x = WALL_JUMP_VELOCITY*wall_direction
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
		if collider is TileMapLayer:
			var collision_pos = get_last_slide_collision().get_position()
			var tilemap_collision_pos = collider.local_to_map(collider.to_local(collision_pos))
			var cell_tile_data = collider.get_cell_tile_data(tilemap_collision_pos)
			if cell_tile_data and cell_tile_data.get_custom_data("fatal"):
				death.emit()
				
#	var zoom_factor = clamp((WALL_JUMP_VELOCITY - velocity.length())/400.0, 0.5, 1.0)
#	var current_zoom = $PlayerCamera.get_zoom()
#	$PlayerCamera.zoom.x = move_toward(current_zoom.x, zoom_factor, CAM_ZOOM_SPEED)
#	$PlayerCamera.zoom.y = move_toward(current_zoom.y, zoom_factor, CAM_ZOOM_SPEED)
	move_and_slide()
