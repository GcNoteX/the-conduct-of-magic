extends Node

@onready var workstation_cursor: WorkstationCursor = $World/WorkstationCursor

var _cursor_enabled = false

func _ready() -> void:
	workstation_cursor.enable_cursor()
	_cursor_enabled = true
	

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("editor_toggle_enchant_mouse"):
		if _cursor_enabled:
			workstation_cursor.disable_cursor()
			_cursor_enabled = false
		else:
			workstation_cursor.enable_cursor()
			workstation_cursor.global_position = get_viewport().get_mouse_position()
			_cursor_enabled = true
