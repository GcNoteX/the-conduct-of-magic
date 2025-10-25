@tool
extends Node2D
class_name EnchantmentNode

"""
- Kills MagicLines that cannot connect to it
- Adds MagicLines to the MagicLineConnectableComponent if one is detected
- Can insert EnchantmentMaterial into to activate
- Can connect to EnchantmentLine's unlimitedly
"""

@onready var m_line_connector: MagicLineConnectableComponent = $MagicLineConnectableComponent
@onready var e_line_connector: EnchantmentLineConnectableComponent = $EnchantmentLineConnectableComponent
@onready var cursor_detector: EnchantmentCursorDetectionComponent = $EnchantmentCursorDetectionComponent
@onready var material_component: MaterialComponent = $MaterialComponent


func _on_magic_line_connectable_component_connectable_line_detected(l: MagicLine) -> void:
	m_line_connector.add_edge(l)

func _on_magic_line_connectable_component_unconnectable_line_detected(l: MagicLine) -> void:
	l.kill_magic_line()

func _on_enchantment_line_connectable_component_connectable_line_detected(l: EnchantmentLine) -> void:
	e_line_connector.add_edge(l)
