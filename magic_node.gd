class_name MagicNode
extends Node2D

"""
- Kills MagicLines that cannot connect to it
- Adds MagicLines to the MagicLineConnectableComponent if one is detected
"""

@onready var magic_lines_connector: MagicLineConnectableComponent = $MagicLineConnectableComponent
@onready var cursor_detector: EnchantmentCursorDetectionComponent = $EnchantmentCursorDetectionComponent

var is_activated: bool = false ## Whether a MagicNode is responsive to cursor
var enchantment_bound: Enchantment = null ## The enchantment this MagicNode has been bounded to

func activate_node(e: Enchantment) -> void:
	"""
		- Set is_activated to true and get enchantment_bounded
		- Perform visual activation
	"""
	enchantment_bound = e
	is_activated = true

func deactivate_node() -> void:
	"""
		- Destroy all lines connected to it
		- Perform visual deactivation
	"""
	for line in magic_lines_connector.connected_lines:
		line.kill_magic_line()

func _on_magic_line_connectable_component_connectable_line_detected(l: MagicLine) -> void:
	# If this function is called, it is identified that the line is unique to this node and there is capacity to take it
	var partner = l.start.owner # MagicLineConnectable owner is Guranteed to be useful
	## NOTE: With an abstract class, this can be halved - a map node abstract class with a bounded enchantment
	if is_activated:
		if partner is EnchantmentNode:
			if partner.owner == enchantment_bound: # Only same enchantment can continue connecting
				magic_lines_connector.add_edge(l)
			else: # Different enchantment's cannot be connected, so destroy line
				l.kill_magic_line()
		elif partner is MagicNode:
			if partner.enchantment_bound == enchantment_bound: # Only same enchantment can continue connecting
				magic_lines_connector.add_edge(l)
			else: # Different enchantment's cannot be connected, so destroy line
				l.kill_magic_line()

	else:
		if partner is MagicNode:
			activate_node(partner.enchantment_bound)
		elif partner is EnchantmentNode:
			activate_node(partner.owner)
		magic_lines_connector.add_edge(l)


func _on_magic_line_connectable_component_unconnectable_line_detected(l: MagicLine) -> void:
	l.kill_magic_line()

# TODO: When all lines are disconnected from node, deactive it
