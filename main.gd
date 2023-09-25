extends Node

@export var death_menu_scene : PackedScene
# Called when the node enters the scene tree for the first time.
func _ready():
	$DeathMenu.hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_level_player_death():
	$DeathMenu.show()
#	var death_menu = death_menu_scene.instantiate()
#	add_child(death_menu)
