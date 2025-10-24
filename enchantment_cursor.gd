class_name EnchantmentCursor
extends Area2D

"""
- Controlled by the players mouse
- Can create MagicLines from MagicLineConnectableComponent
- Controls MagicLines that it creates
"""

var magic_line: PackedScene = preload(SceneReferences.magic_line)

var controlled_line: MagicLine = null

func _process(_delta: float) -> void:
	position = get_global_mouse_position()

func _physics_process(_delta: float) -> void:
	if controlled_line and controlled_line.initialized:
		controlled_line.stretch_line(position - controlled_line.position)
	
	# Letting go of a line destroys it
	if Input.is_action_just_released("left_click"):
		if controlled_line:
			controlled_line.kill_magic_line()
		controlled_line = null

func _on_area_exited(area: Area2D) -> void:
	if !controlled_line and area is MagicLineConnectableComponent and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if area.can_connect_edge():
			# Create a MagicLine
			var m: MagicLine = magic_line.instantiate()
			# Setup the edge
			m.start = area
			get_tree().current_scene.call_deferred("add_child", m) # WARNING: This is temporary until EnchantmentMap is built back in
			m.locked.connect(_on_MagicLine_locked)
			
			controlled_line = m

func _on_MagicLine_locked() -> void:
	controlled_line = null
