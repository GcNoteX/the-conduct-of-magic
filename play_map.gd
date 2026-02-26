extends Node2D

@onready var material_cursor := $MaterialCursor
@onready var draw_cursor := $DrawCursor
@onready var enchantment_layout_cursor := $EnchantmentLayoutCursor

var _captured: bool = true
var _cursor: EnchantmentCursor

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
		_cursor.disable_cursor()
		material_cursor.enable_cursor()
		_cursor = material_cursor
		_cursor.global_position = get_global_mouse_position()
		#if material_cursor.enabled:
			#material_cursor.disable_cursor()
		#else:
			## enable this one
			#material_cursor.enable_cursor()
			## disable others
			#draw_cursor.disable_cursor()
			#enchantment_layout_cursor.disable_cursor()
		return  # prevent double triggers


	# --- Draw Cursor Toggle (X) ---
	if event.is_action_pressed("cursor_toggle_draw"):
		_cursor.disable_cursor()
		draw_cursor.enable_cursor()
		_cursor = draw_cursor
		_cursor.global_position = get_global_mouse_position()
		#if draw_cursor.enabled:
			#draw_cursor.disable_cursor()
		#else:
			#draw_cursor.enable_cursor()
			## disable others
			#material_cursor.disable_cursor()
			#enchantment_layout_cursor.disable_cursor()
		return


	# --- Enchantment Layout Cursor Toggle (C) ---
	if event.is_action_pressed("cursor_toggle_emap_layout"):
		_cursor.disable_cursor()
		enchantment_layout_cursor.enable_cursor()
		_cursor = enchantment_layout_cursor
		_cursor.global_position = get_global_mouse_position()
		#if enchantment_layout_cursor.enabled:
			#enchantment_layout_cursor.disable_cursor()
		#else:
			#enchantment_layout_cursor.enable_cursor()
			## disable others
			#material_cursor.disable_cursor()
			#draw_cursor.disable_cursor()
		return
