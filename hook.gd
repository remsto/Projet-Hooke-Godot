extends Area2D

@export var max_stretch : float = 10.0
@export var stretch_speed : float = 30.0

signal signal_pulling(new_speed : float)

var pos_speed : float
var hook_speed : float
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
		
func _physics_process(delta):
	if Input.is_action_just_pressed("hook"):
		is_active = true
		is_extending = true
	if is_active:
		var init_x_pos = 0.0
		# Extension phase
		if is_extending:
#			scale.x += stretch_speed*delta
			scale.x = move_toward(scale.x, max_stretch, stretch_speed*delta)
			position.x += pos_speed*delta
			if scale.x >= max_stretch:
				is_extending = false
			if has_overlapping_bodies():
				is_extending = false
				is_pulling = true
		# Retraction phase
		else:
			scale.x = move_toward(scale.x, 1.0, stretch_speed*delta)
			position.x -= pos_speed*delta
			if is_pulling: 
				signal_pulling.emit(pos_speed)
			if scale.x == 1.0:
				position.x = init_x_pos
				is_active = false
				is_pulling = false
