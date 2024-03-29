extends Node

var game_scene 

func _on_play_button_pressed():
	$MainTitle.hide()
	$LevelMenu.show()
	
func _on_quit_button_pressed():
	get_tree().quit()
	
func _on_level_selected(level_name):
	$LevelMenu.hide()
#	var level_scene = load("res://Levels/" + level_name)
#	$Game.add_child(level_scene.instantiate())
	$Game.add_level(level_name)
	$Game.set_process(true)

# Called when the node enters the scene tree for the first time.
func _ready():
	# We do this to remove the (dummy) level from the game. To remove ?
	game_scene = preload("res://game.tscn")
	var GameNode = game_scene.instantiate()
	var level_node = GameNode.find_child("Level")
	GameNode.remove_child(level_node)
	level_node.queue_free()
	add_child(GameNode)
	GameNode.set_process(false)
	$LevelMenu.hide()
	# Connect the button signals
	$MainTitle/VBoxContainer/PlayButton.connect("pressed", _on_play_button_pressed)
	$MainTitle/VBoxContainer/QuitButton.connect("pressed", _on_quit_button_pressed)
	
	$LevelMenu.connect("level_selected", _on_level_selected)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
