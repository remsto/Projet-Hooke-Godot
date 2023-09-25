extends CharacterBody2D

const ACCEL = 20.0
const SPEED = 150.0
const JUMP_VELOCITY = -400.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var screen_size

signal death

func _ready():
	position.x = 0.0
	position.y = 0.0
	$AnimatedSprite2D.animation = "idle"
	$AnimatedSprite2D.play()
	screen_size = get_viewport_rect().size



func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("ui_left", "ui_right")
	var accel
	var max_speed
	if Input.is_action_pressed("run"): 
		accel = ACCEL*2
		max_speed = SPEED*2
	else:
		accel = ACCEL
		max_speed = SPEED
	if direction:
#		velocity.x = direction * speed
		velocity.x = move_toward(velocity.x, direction*max_speed, accel)
		$AnimatedSprite2D.animation = "walk"
		$AnimatedSprite2D.flip_h = velocity.x < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		$AnimatedSprite2D.animation = "idle"
	move_and_slide()
#	position = position.clamp(Vector2.ZERO, screen_size)

#func die():
#	'''
#	Death of the player
#	'''
#	death.emit()
#	queue_free()
#
#func _on_death_zone_body_entered(body):
#	'''
#	Death of the player
#	'''
#	print("oiuuiuisdcoiveqiu")
#	die()
