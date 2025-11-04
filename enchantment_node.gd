extends MapNode
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


func update_connections() -> void:
	connections.clear()
	for line in m_line_connector.connected_lines:
		if line.start.owner == self:
			#print("Adding ", line.end)
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


func get_bounded_identity() -> Variant:
	return owner

func _on_connectable_magic_line_detected(l: MagicLine) -> void:
	# If this function is called, it is identified that the line is unique to the connectable component and there is capacity to take itt
	var partner = l.start.owner # MagicLineConnectable owner is Guranteed to be useful
	if partner in connections or partner == self:
		l.kill_magic_line()
		return
	
	if partner is MapNode:
		if partner.get_bounded_identity() == get_bounded_identity():
			m_line_connector.add_edge(l)
			update_connections()
		else:
			l.kill_magic_line()
	else:
		m_line_connector.add_edge(l)
		update_connections()

func _on_unconnectable_line_detected(l: MagicLine) -> void:
	l.kill_magic_line()
