extends MapNode
class_name MagicNode

"""
- Kills MagicLines that cannot connect to it
- Adds MagicLines to the MagicLineConnectableComponent if one is detected
"""

@onready var magic_lines_connector: MagicLineConnectableComponent = $MagicLineConnectableComponent
@onready var cursor_detector: EnchantmentCursorDetectionComponent = $EnchantmentCursorDetectionComponent

var is_activated: bool = false ## Whether a MagicNode is responsive to cursor
var enchantment_bound: Enchantment = null ## The enchantment this MagicNode has been bounded to

func _ready() -> void:
	update_connections()

func update_connections() -> void:
	connections.clear()
	for line in magic_lines_connector.connected_lines:
		if line.start == self:
			#print("Adding ", line.end)
			connections.append(line.end.owner)
		else:
			#print("Adding ", line.start)
			connections.append(line.start.owner)

func get_bounded_identity() -> Variant:
	return enchantment_bound

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
	if partner in connections or partner == self: # The latter case only matters when there is more than one connectable component for lines
		l.kill_magic_line()
		return
	
	if partner is MapNode:
		if partner.get_bounded_identity() == get_bounded_identity() or get_bounded_identity() == null:
			if !is_activated:
				activate_node(partner.get_bounded_identity())
			magic_lines_connector.add_edge(l)
			update_connections()
		else:
			l.kill_magic_line()
	else:
		magic_lines_connector.add_edge(l)
		update_connections()


func _on_magic_line_connectable_component_unconnectable_line_detected(l: MagicLine) -> void:
	l.kill_magic_line()

# TODO: When all lines are disconnected from node, deactive it


func _on_magic_line_connectable_component_line_destroyed(l: MagicLine) -> void:
	magic_lines_connector.remove_edge(l)
	update_connections()
