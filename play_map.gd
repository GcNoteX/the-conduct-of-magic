extends Node

@onready var material_cursor := $MaterialCursor
@onready var draw_cursor := $DrawCursor
@onready var enchantment_layout_cursor := $EnchantmentLayoutCursor

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _unhandled_input(event: InputEvent) -> void:

	# --- Material Cursor Toggle (Z) ---
	if event.is_action_pressed("cursor_toggle_material"):
		if material_cursor.enabled:
			material_cursor.disable_cursor()
		else:
			# enable this one
			material_cursor.enable_cursor()
			# disable others
			draw_cursor.disable_cursor()
			enchantment_layout_cursor.disable_cursor()
		return  # prevent double triggers


	# --- Draw Cursor Toggle (X) ---
	if event.is_action_pressed("cursor_toggle_draw"):
		if draw_cursor.enabled:
			draw_cursor.disable_cursor()
		else:
			draw_cursor.enable_cursor()
			# disable others
			material_cursor.disable_cursor()
			enchantment_layout_cursor.disable_cursor()
		return


	# --- Enchantment Layout Cursor Toggle (C) ---
	if event.is_action_pressed("cursor_toggle_emap_layout"):
		if enchantment_layout_cursor.enabled:
			enchantment_layout_cursor.disable_cursor()
		else:
			enchantment_layout_cursor.enable_cursor()
			# disable others
			material_cursor.disable_cursor()
			draw_cursor.disable_cursor()
		return
