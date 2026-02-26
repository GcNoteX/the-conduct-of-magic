extends Node

@onready var workstation_cursor: WorkstationCursor = $World/WorkstationCursor

var _cursor_enabled = false

# BUG: Zooming can push objects outside of the workstation area due to the area being
# outside the subviewport, causing some weird shifting behaviour.

func _ready() -> void:
	workstation_cursor.enable_cursor()
	_cursor_enabled = true
	

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("editor_toggle_enchant_mouse"):
		if _cursor_enabled:
			workstation_cursor.disable_cursor()
			_cursor_enabled = false
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			workstation_cursor.enable_cursor()
			workstation_cursor.global_position = get_viewport().get_mouse_position()
			_cursor_enabled = true
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
