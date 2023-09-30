extends Node2D

signal player_death

@export var player_scene : PackedScene
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_death_menu_restart():
	var player = player_scene.instantiate()
	add_child(player)
	$Player.death.connect(_on_player_death)



func _on_player_death():
	$Player.queue_free()
	player_death.emit()


func _on_death_zone_body_entered(body):
	$Player.queue_free()
	player_death.emit()
