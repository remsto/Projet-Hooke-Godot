extends CharacterBody2D

const ACCEL = 10000.0
const SPEED = 150.0
const JUMP_VELOCITY = -400.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var screen_size

signal death

func _ready():
	$AnimatedSprite2D.animation = "idle"
	$AnimatedSprite2D.play()
	screen_size = get_viewport_rect().size
	



func _physics_process(delta):


	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("left", "right")
	var accel
	var max_speed
	if not $Hook.is_active:
		# Add the gravity.
		if not is_on_floor():
			velocity.y += gravity * delta
		# Handle Jump.
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY
		if Input.is_action_pressed("run"): 
			accel = ACCEL*2
			max_speed = SPEED*2
		else:
			accel = ACCEL
			max_speed = SPEED
		if direction:
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
	move_and_slide()
#	position = position.clamp(Vector2.ZERO, screen_size)


