extends Node

signal main_menu

var level_node

func set_level(level_name):
	if is_instance_valid(level_node):
		remove_child(level_node)
		level_node.queue_free() 
	var level_scene = load("res://Levels/" + level_name)
	level_node = level_scene.instantiate()
	add_child(level_node)
	level_node.player_death.connect(_on_level_player_death)
	$DeathMenu.restart.connect(level_node._on_death_menu_restart)


# Called when the node enters the scene tree for the first time.
func _ready():
	$DeathMenu.hide()
	$PauseMenu.hide()
	$PauseMenu/VBoxContainer/TitleButton.connect("pressed", _on_pause_main_menu_pressed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("pause"):
		# TODO : better pause menu position
#		var active_cam_pos = $Level/Player/PlayerCamera.get_viewport_rect().size / 2
		var active_cam_pos = $Level/Player/PlayerCamera.get_screen_center_position() - $Level/Player/PlayerCamera.get_viewport_rect().size / 2
#		var active_cam_pos = $Level/Player/PlayerCamera.get_viewport_rect().position
#		$PauseMenu.set_position($Level/Player/PlayerCamera.get_screen_center_position())
		$PauseMenu.set_position(active_cam_pos)
		get_tree().paused = true
		$PauseMenu.show()


func _on_level_player_death():
	$DeathMenu.show()
#	var death_menu = death_menu_scene.instantiate()
#	add_child(death_menu)


func _on_pause_main_menu_pressed():
	remove_child(level_node)
	level_node.queue_free()
	get_tree().paused = false
	$PauseMenu.hide()
	main_menu.emit()

func _on_pause_menu_unpause():
	get_tree().paused = false
