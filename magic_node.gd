extends MapNode
class_name MagicNode

"""
- Kills MagicLines that cannot connect to it
- Adds MagicLines to the LineConnector if one is detected
- Can only be drawn from when activated
"""

@onready var line_connector: LineConnector = $LineConnector
@onready var cursor_detector: EnchantmentCursorDetectionComponent = $EnchantmentCursorDetectionComponent

var enchantment_bound: Enchantment = null ## The enchantment this MagicNode has been bounded to

func get_bounded_identity() -> Variant:
	return enchantment_bound

"""
Handling Activation
"""


func deactivate_node() -> void:
	"""
		- Destroy all lines connected to it
		- Perform visual deactivation
	"""
	for line in line_connector.connected_lines:
		line.kill_line()


func _on_line_connector_allowed_line_type_detected(l: MapLine) -> void:
	if !passes_base_conditions(l):
		#print("Failed base conditions")
		l.kill_line()
		return
	#print("Passed base conditions")
	var partner = l.start.owner as MapNode # LineConnector owner is Guranteed to be useful
	
	## Condition1: MagicNode does not allow more than 1 connection to a partner
	if partner in mapnode_connections or partner == self: # The latter case only matters when there is more than one connectable component for lines
		l.kill_line()
		return
	#print("Pass Condition 1")
	## Condition2: MagicNode does not allow a line from a different Enchantment to connect
	if !(partner.get_bounded_identity() == get_bounded_identity() or get_bounded_identity() == null):
		l.kill_line()
		return
	#print("Pass Condition 2")
	add_connection(l)
	l.lock_line(line_connector)
	# Activate the Node if possible
	if partner.get_bounded_identity() is Enchantment:
		enchantment_bound = partner.get_bounded_identity()
	

func _on_line_connector_invalid_line_type_detected(l: MapLine) -> void:
	# Destroys invalid 
	l.kill_line()

func _on_line_connector_line_forcing_connection(l: MapLine) -> void:
	add_connection(l)

"""
Handling Cursor's
"""

func handle_drag_out(c: EnchantmentCursor) -> void:
	if c is DrawCursor:
		if !c.controlled_line and has_capacity():
			# Create a new MagicLine
			var l: MagicLine = preload(SceneReferences.magic_line).instantiate()
			l.start = line_connector
			# Draw the line from this node
			EnchantmentMapManager.call_deferred("add_to_enchantment_map", l)
			# Attach it to the DrawCursor
			l.locked.connect(c._on_MagicLine_locked)
			c.controlled_line = l
