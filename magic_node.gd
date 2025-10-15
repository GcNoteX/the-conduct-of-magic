class_name MagicNode
extends Node2D

"""
- Allows the creation of magic edges from it
- Allows the acceptance of magic edges from it
"""

@onready var edge_connector: MagicEdgeConnectableComponent = $MagicEdgeConnectableComponent
@onready var cursor_detector: EnchantmentCursorDetectionComponent = $EnchantmentCursorDetectionComponent

var hovered_over = false

func _on_enchantment_cursor_detection_component_hovered_over(s: EnchantmentCursorDetectionComponent) -> void:
	print("Magic node hovered over")
	hovered_over = true


func _on_enchantment_cursor_detection_component_exited_selecting(s: EnchantmentCursorDetectionComponent) -> void:
	print("Magic node unhovered over")
	if hovered_over:
		MagicEdge.start_magic_edge(edge_connector)
	hovered_over = false
