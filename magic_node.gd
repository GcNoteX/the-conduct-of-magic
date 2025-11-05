extends MapNode
class_name MagicNode

"""
- Kills MagicLines that cannot connect to it
- Adds MagicLines to the LineConnector if one is detected
"""

@onready var line_connector: LineConnector = $LineConnector
@onready var cursor_detector: EnchantmentCursorDetectionComponent = $EnchantmentCursorDetectionComponent

var is_activated: bool = false ## Whether a MagicNode is responsive to cursor
var enchantment_bound: Enchantment = null ## The enchantment this MagicNode has been bounded to

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
	for line in line_connector.connected_lines:
		line.kill_magic_line()


func _on_line_connector_allowed_line_type_detected(l: MapLine) -> void:
	if !passes_base_conditions(l):
		l.kill_line()
		return
		
	var partner = l.start.owner as MapNode # LineConnector owner is Guranteed to be useful
	
	## Condition1: MagicNode does not allow more than 1 connection to a partner
	if partner in mapnode_connections or partner == self: # The latter case only matters when there is more than one connectable component for lines
		l.kill_line()
		return
	
	## Condition2: MagicNode does not allow a line from a different Enchantment to connect
	if !(partner.get_bounded_identity() == get_bounded_identity() or get_bounded_identity() == null):
		l.kill_line()
		return
	
	add_connection(l)

func _on_line_connector_invalid_line_type_detected(l: MapLine) -> void:
	# Destroys invalid 
	l.kill_line()

"""
Handling Cursor's
"""

func handle_drag_out(c: EnchantmentCursor) -> void:
	if c is DrawCursor:
		# Ignore if node is not activated
		if !is_activated:
			return
		if !c.controlled_line and has_capacity():
			# Create a new MagicLine
			var l: MagicLine = preload(SceneReferences.magic_line).instantiate()
			# Draw the line from this node
			EnchantmentMapManager.call_deferred("add_to_enchantment_map", l)
			# Attach it to the DrawCursor
			l.locked.connect(c._on_MagicLine_locked)
			c.controlled_line = l
