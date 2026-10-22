extends Node2D
## PlayMap: the legacy enchanting map test scene. Captures the mouse and switches between the
## material (Z), draw (X) and enchantment layout (C) cursors.

var _captured: bool = true
var _cursor: EnchantmentCursor

@onready var material_cursor: MaterialCursor = $MaterialCursor
@onready var draw_cursor: DrawCursor = $DrawCursor
@onready var enchantment_layout_cursor: EnchantmentLayoutCursor = $EnchantmentLayoutCursor


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	material_cursor.enable_cursor()
	_cursor = material_cursor


func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("editor_toggle_enchant_mouse"):
		if _captured:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			_captured = false
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			_captured = true


func _unhandled_input(event: InputEvent) -> void:
	# --- Material Cursor Toggle (Z) ---
	if event.is_action_pressed("cursor_toggle_material"):
		_switch_to(material_cursor)
		return  # prevent double triggers

	# --- Draw Cursor Toggle (X) ---
	if event.is_action_pressed("cursor_toggle_draw"):
		_switch_to(draw_cursor)
		return

	# --- Enchantment Layout Cursor Toggle (C) ---
	if event.is_action_pressed("cursor_toggle_emap_layout"):
		_switch_to(enchantment_layout_cursor)
		return


func _switch_to(cursor: EnchantmentCursor) -> void:
	_cursor.disable_cursor()
	cursor.enable_cursor()
	_cursor = cursor
	_cursor.global_position = get_global_mouse_position()
