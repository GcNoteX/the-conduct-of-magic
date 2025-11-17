extends Node

@onready var material_cursor := $MaterialCursor
@onready var draw_cursor := $DrawCursor


func _unhandled_input(event: InputEvent) -> void:

	# --- Material Cursor Toggle (Z) ---
	if event.is_action_pressed("cursor_toggle_material"):
		if material_cursor.enabled:
			material_cursor.disable_cursor()
		else:
			material_cursor.enable_cursor()
			# turn the other one off
			draw_cursor.disable_cursor()

	# --- Draw Cursor Toggle (X) ---
	if event.is_action_pressed("cursor_toggle_draw"):
		if draw_cursor.enabled:
			draw_cursor.disable_cursor()
		else:
			draw_cursor.enable_cursor()
			# turn the other one off
			material_cursor.disable_cursor()
