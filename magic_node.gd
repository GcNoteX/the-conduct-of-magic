class_name MagicNode
extends Node2D

"""
- Kills MagicLines that cannot connect to it
- Adds MagicLines to the MagicLineConnectableComponent if one is detected
"""

@onready var edge_connector: MagicLineConnectableComponent = $MagicLineConnectableComponent
@onready var cursor_detector: EnchantmentCursorDetectionComponent = $EnchantmentCursorDetectionComponent


func _on_magic_line_connectable_component_connectable_line_detected(l: MagicLine) -> void:
	edge_connector.add_edge(l)


func _on_magic_line_connectable_component_unconnectable_line_detected(l: MagicLine) -> void:
	l.kill_magic_line()
