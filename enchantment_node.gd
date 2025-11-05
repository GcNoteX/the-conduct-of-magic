@tool
extends MapNode
class_name EnchantmentNode

"""
- Kills MagicLines that cannot connect to it
- Adds MagicLines to the MagicLineConnectableComponent if one is detected
- Can insert EnchantmentMaterial into to activate
- Can connect to EnchantmentLine's unlimitedly
"""

#signal updated

@onready var m_line_connector: MagicLineConnectableComponent = $MagicLineConnectableComponent
@onready var e_line_connector: EnchantmentLineConnectableComponent = $EnchantmentLineConnectableComponent
@onready var material_component: MaterialHolder = $MaterialHolder

var is_activated: bool = false


func get_bounded_identity() -> Variant:
	return owner


func _update_connections() -> void:
	connections.clear()
	for line in m_line_connector.connected_lines:
		if line.start.owner == self:
			#print("Adding ", line.end)
			if line.end:
				connections.append(line.end.owner)
		else:
			#print("Adding ", line.start)
			connections.append(line.start.owner)

	for line in e_line_connector.connected_lines:
		if line.start.owner == self:
			#print("Adding ", line.end)
			connections.append(line.end.owner)
		else:
			#print("Adding ", line.start)
			connections.append(line.start.owner)


func add_connection(l: MagicLine) -> void:
	print("Added Connection to node")
	m_line_connector.add_edge(l)
	_update_connections()


func _on_connectable_magic_line_detected(l: MagicLine) -> void:
	# If this function is called, it is identified that the line is unique to the connectable component and there is capacity to take itt
	print("Connectable Magic Line Detected")
	var partner = l.start.owner # MagicLineConnectable owner is Guranteed to be useful
	if partner in connections or partner == self:
		l.kill_magic_line()
		return
	
	if partner is MapNode:
		if partner.get_bounded_identity() == get_bounded_identity():
			add_connection(l)
		else:
			l.kill_magic_line()
	else:
		add_connection(l)


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


func _on_unconnectable_line_detected(l: MagicLine) -> void:
	l.kill_magic_line()


func _on_magic_line_connectable_component_line_destroyed(l: MagicLine) -> void:
	m_line_connector.remove_edge(l)
	_update_connections()


func _on_material_holder_material_embedded() -> void:
	update_activation()


func _on_material_holder_material_removed() -> void:
	update_activation()


func _on_magic_line_connectable_component_connector_updated_independently() -> void:
	_update_connections()
