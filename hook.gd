extends Node2D

@export var max_stretch : float = 20.0
@export var stretch_speed : float = 20.0

var pos_speed : float
var is_active : bool
var is_extending : float
# Called when the node enters the scene tree for the first time.
func _ready():
	pos_speed = stretch_speed * $HookTip/CollisionShape2D.shape.size.x / 2.
	is_active = false
	is_extending = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
		
func _physics_process(delta):
	if Input.is_action_just_pressed("run"):
		is_active = true
		is_extending = true
	if is_active:
		var init_x_pos = position.x
		if is_extending:
			scale.x += stretch_speed*delta
			position.x += pos_speed*delta
			if scale.x >= max_stretch:
				is_extending = false
				position.x = init_x_pos
		else:
			scale.x -= stretch_speed*delta
			position.x -= pos_speed*delta
			if scale.x <= 1.0:
				scale.x = 1.0
				position.x = init_x_pos
				is_active = false
