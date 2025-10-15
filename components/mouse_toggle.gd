extends Node

var is_hidden = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle"):
		if !is_hidden:
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
			is_hidden = true
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			is_hidden = false
