extends MarginContainer

signal unpause
var is_paused

# Called when the node enters the scene tree for the first time.
func _ready():
	is_paused = false
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if visible:
		if not is_paused and Input.is_action_just_pressed("pause"):
			is_paused = true
		elif Input.is_action_just_pressed("pause"):
			is_paused = false
			unpause.emit()
			hide()	



func _on_continue_button_pressed():
	is_paused = false
	unpause.emit()
	hide()
