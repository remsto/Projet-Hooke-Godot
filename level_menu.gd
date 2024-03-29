extends MarginContainer

signal level_selected(level_name)

func add_level(level_name):
	var new_button = Button.new()
	new_button.text = level_name.split(".tscn")[0]
	new_button.pressed.connect(_dummy_press.bind(level_name))
	$LevelGrid.add_child(new_button)

func _dummy_press0():
	print('zazou')

func _dummy_press(level_name):
	emit_signal("level_selected", level_name)

func dir_contents(path):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				print("Found directory: " + file_name)
			else:
				add_level(file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")

# Called when the node enters the scene tree for the first time.
func _ready():
	dir_contents("res://Levels")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
