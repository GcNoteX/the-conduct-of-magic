class_name EnchantmentCursor
extends Area2D

"""
- Controlled by the players mouse
- Can create MagicLines from MagicLineConnectableComponent
- Controls MagicLines that it creates
"""

var magic_line: PackedScene = preload("res://magic_line.tscn")

var controlled_line: MagicLine = null

func _process(_delta: float) -> void:
	position = get_global_mouse_position()

func _physics_process(_delta: float) -> void:
	if controlled_line and controlled_line.initialized:
		controlled_line.stretch_line(position)

func _on_area_exited(area: Area2D) -> void:
	if !controlled_line and area is MagicLineConnectableComponent and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if area.can_connect_edge():
			# Create a MagicLine
			#print("Creating MagicLine")
			var m: MagicLine = magic_line.instantiate()
			get_tree().current_scene.call_deferred("add_child", m) # WARNING: This is temporary until EnchantmentMap is built back in
			area.add_edge(m)
			m.locked.connect(_on_MagicLine_locked)
			controlled_line = m

func _on_MagicLine_locked() -> void:
	controlled_line = null
