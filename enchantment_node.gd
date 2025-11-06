@tool
extends MapNode
class_name EnchantmentNode

"""
- Kills MagicLines that cannot connect to it
- Adds MagicLines to the MagicLineConnectableComponent if one is detected
- Can insert EnchantmentMaterial into to activate
- Can connect to EnchantmentLine's unlimitedly
"""

@onready var line_connector: LineConnector = $LineConnector
@onready var material_component: MaterialHolder = $MaterialHolder

var is_activated: bool = false


func get_bounded_identity() -> Variant:
	return owner


func _on_line_connector_allowed_line_type_detected(l: MapLine) -> void:
	if !passes_base_conditions(l):
		l.kill_line()
		return
	
	var partner = l.start.owner as MapNode # MagicLineConnectable owner is Guranteed to be useful
	
	## Condition1: EnchantmentNode does not allow more than 1 connection to a partner
	if partner in mapnode_connections or partner == self:
		l.kill_line()
		return
	
	## Condition2: EnchantmentNode does not allow a line from a different Enchantment to connect
	if partner.get_bounded_identity() != get_bounded_identity():
		l.kill_line()
	
	add_connection(l)
	l.lock_line(line_connector)

func _on_line_connector_invalid_line_type_detected(l: MapLine) -> void:
	# Destroys invalid 
	l.kill_line()

func _on_line_connector_line_forcing_connection(l: MapLine) -> void:
	add_connection(l)

"""
Handling Activation
"""
## Updates the state of the EnchantmentNode based on whether it can be activated.
## Returns whether the node can be activated.
func update_activation() -> bool:
	var ctx = MaterialActivationContext.new(self)
	if material_component.can_material_be_activated(ctx):
		#print("Material activated! Activating node:")
		_activate_node()
		return true
	else:
		#print("Material not activated.")
		if is_activated:
			_deactivate_node()
		return false


func _activate_node() -> void:
	is_activated = true
	self.modulate =Color(1.0, 0.306, 0.36, 1.0)


func _deactivate_node() -> void:
	is_activated = false
	self.modulate =Color(1, 1, 1, 1.0)


"""
Handling Material
"""

func _on_material_holder_material_embedded() -> void:
	update_activation()


func _on_material_holder_material_removed() -> void:
	update_activation()


"""
Handling Cursors
"""

func handle_drag_out(c: EnchantmentCursor) -> void:
	if c is DrawCursor:
		# Ignore if node is not activated
		if !is_activated:
			return
		if !c.controlled_line and has_capacity():
			# Create a new MagicLine
			var l: MagicLine = preload(SceneReferences.magic_line).instantiate()
			l.start = line_connector
			# Draw the line from this node
			EnchantmentMapManager.call_deferred("add_to_enchantment_map", l)
			# Attach it to the DrawCursor
			l.locked.connect(c._on_MagicLine_locked)
			c.controlled_line = l
