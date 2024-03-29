extends Node

func add_level(level_name):
	var level_scene = load("res://Levels/" + level_name)
	var level_node = level_scene.instantiate()
	add_child(level_node)
	level_node.player_death.connect(_on_level_player_death)
	$DeathMenu.restart.connect(level_node._on_death_menu_restart)


# Called when the node enters the scene tree for the first time.
func _ready():
	$DeathMenu.hide()
	$PauseMenu.hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("pause"):
		# TODO : better pause menu position
		$PauseMenu.set_position($Level/Player.get_position())
		get_tree().paused = true
		$PauseMenu.show()


func _on_level_player_death():
	$DeathMenu.show()
#	var death_menu = death_menu_scene.instantiate()
#	add_child(death_menu)




func _on_pause_menu_unpause():
	get_tree().paused = false
