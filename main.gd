extends Node

var game_scene 

func _on_play_button_pressed():
	$MainTitle.hide()
	$LevelMenu.show()
	$LevelMenu.set_process(true)
	
func _on_quit_button_pressed():
	get_tree().quit()
	
func _on_level_selected(level_name):
	$LevelMenu.set_process(false)
	$LevelMenu.hide()
#	var level_scene = load("res://Levels/" + level_name)
#	$Game.add_child(level_scene.instantiate())
	$Game.set_level(level_name)
	$Game.set_process(true)

func _on_level_back_pressed():
	$LevelMenu.set_process(false)
	$LevelMenu.hide()
	print("debug0")
	$MainTitle.show()
	
func _on_pause_main_menu_pressed():
	$Game.set_process(false)
	$MainTitle.show()

# Called when the node enters the scene tree for the first time.
func _ready():
	get_window().size = Vector2i(1280, 720)
	get_window().position = Vector2i(100, 100)
	# We do this to remove the (dummy) level from the game. To remove ?
	game_scene = preload("res://game.tscn")
	var GameNode = game_scene.instantiate()
	var level_node = GameNode.find_child("Level")
	GameNode.remove_child(level_node)
	level_node.queue_free()
	add_child(GameNode)
	GameNode.set_process(false)
	GameNode.connect("main_menu", _on_pause_main_menu_pressed)
	
	$LevelMenu.hide()
	$LevelMenu.set_process(false)
	# Connect the button signals
	$MainTitle/VBoxContainer/PlayButton.connect("pressed", _on_play_button_pressed)
	$MainTitle/VBoxContainer/QuitButton.connect("pressed", _on_quit_button_pressed)
	
	$LevelMenu.connect("level_selected", _on_level_selected)
	$LevelMenu.connect("back", _on_level_back_pressed)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
