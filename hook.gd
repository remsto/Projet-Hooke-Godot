extends Area2D

@export var max_stretch : float = 15.0
@export var stretch_speed : float = 40.0

var pos_speed : float
var hook_speed : float
var hook_direction : Vector2
var is_active : bool
var is_extending : float
var is_pulling : float
# Called when the node enters the scene tree for the first time.
func _ready():
	pos_speed = stretch_speed * $CollisionShape2D.shape.size.x / 2.
	hook_speed = stretch_speed * $CollisionShape2D.shape.size.x 
#	hook_speed = 1000.0
	is_active = false
	is_extending = false
	is_pulling = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
		
func reset_hook():
	scale = Vector2(1.0, 1.0)
	position = Vector2(1.0, 1.0)	
	rotation = 0.0	
	is_active = false
	is_extending = false
	is_pulling = false

func _physics_process(delta):
	if Input.is_action_just_pressed("hook") and not is_active:
		hook_direction = get_local_mouse_position().normalized()
		rotation = hook_direction.angle()
		is_active = true
		is_extending = true
	if is_active:
		# Extension phase
		if is_extending:
			scale.x = move_toward(scale.x, max_stretch, stretch_speed*delta)
			position += hook_direction*pos_speed*delta
			if scale.x >= max_stretch:
				is_extending = false
			if has_overlapping_bodies():
				is_extending = false
				is_pulling = true
		# Retraction phase
		else:
			scale.x = move_toward(scale.x, 1.0, stretch_speed*delta)
			position -= hook_direction*pos_speed*delta
			if scale.x == 1.0:
				reset_hook()
