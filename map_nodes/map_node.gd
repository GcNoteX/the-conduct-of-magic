@abstract class_name MapNode extends EnchantmentMapElement
"""
An abstract class to compile define all Node-Type objects within a PlayMap
"""

signal mapnode_added(m: MapNode) ## If an inheriting class wants to perform extra operations after
signal mapnode_removed(m: MapNode) ## If an inheriting class wants to perform extra operations after
signal mapline_added(l: MapLine) ## If an inheriting class wants to perform extra operations after
signal mapline_removed(l: MapLine) ## If an inheriting class wants to perform extra operations after
signal connections_updated()


@export var mapnode_connections: Dictionary[MapNode, int] = {} ## The number of connected nodes
@export var mapline_connections: Array[MapLine] = [] ## The number of connected lines

@export var is_unlimited_capacity: bool = true
@export var max_capacity: int = 0:
	set(c):
		if c < 0:
			return
		max_capacity = c


func _ready() -> void:
	_initialize_node()
	push_warning("Abstract class MapNode _ready() called by ", self)

func _initialize_node() -> void:
	mapnode_connections.clear()
	mapline_connections.clear()
	self.connections_updated.connect(ConnectionsUpdateManager._on_MapNode_connections_updated)

"""
Utilities
"""

static func gather_connections(source: MapNode) -> Array[MapNode]:
	var raw_nodes := UtilityFunctions.dfs_collect_nodes(
		source.mapnode_connections.keys(),
		func(node):
			return node.mapnode_connections
	)
	# The failing type hints at run time block it without this
	var connected_nodes: Array[MapNode] = []
	for n in raw_nodes:
		if n is MapNode:
			connected_nodes.append(n)

	return connected_nodes

static func gather_lines(nodes: Array[MapNode]) -> Array[MapLine]:
	var lines: Array[MapLine] = []
	var seen := {} # acts like a Set for uniqueness
	#print("Gathering lines from ", nodes)
	for node in nodes:
		#print("For ", node)
		for line in node.mapline_connections:
			#print("Has line ", line)
			if line == null:
				continue
			if not seen.has(line):
				seen[line] = true
				lines.append(line)

	return lines

"""
Connection Functions
"""

func add_line_connection(l: MapLine) -> void:
	if mapline_connections.has(l):
		push_error("Attempting to add the same line more than once!")
		return

	mapline_connections.append(l)
	l.destroyed.connect(remove_line_connection)
	emit_signal("mapline_added", l)

	# handle start and end nodes
	if l.start:
		_add_node_from_line(l.start)
	if l.end:
		_add_node_from_line(l.end)
	else:
		l.connected.connect(_add_node_from_line_aux)
	
	emit_signal("connections_updated")

func remove_line_connection(l: MapLine) -> void:
	if not mapline_connections.has(l):
		push_warning("Attempted to remove line %s that is not connected" % str(l))
		return

	mapline_connections.erase(l)
	emit_signal("mapline_removed", l)

	# handle start and end nodes
	_remove_node_from_line(l.start)
	_remove_node_from_line(l.end)
	
	emit_signal("connections_updated")

func _add_node_from_line(node: MapNode) -> void:
	if node == null:
		push_warning("Attempted to add MapLine with null node")
		return

	if node == self:
		return  # avoid self-connection

	var is_new := not mapnode_connections.has(node)
	mapnode_connections[node] = mapnode_connections.get(node, 0) + 1

	if is_new:
		emit_signal("mapnode_added", node)

func _add_node_from_line_aux(node: MapNode) -> void:
	_add_node_from_line(node)
	emit_signal("connections_updated")

func _remove_node_from_line(node: MapNode) -> void:
	if node == null or node == self:
		return

	if not mapnode_connections.has(node):
		push_warning("Attempted to removed connection to", node, " which is not connected")
		return

	mapnode_connections[node] -= 1
	if mapnode_connections[node] <= 0:
		mapnode_connections.erase(node)
		emit_signal("mapnode_removed", node)

func _clear_connections() -> void:
	mapnode_connections.clear()
	mapline_connections.clear()


"""
Conditions Functions
"""
## Conditions for a line that is trying to connect to the node
## Con1: MapLine does not share the same start and end as another line (i.e. Duplicate)
## Con2: MapNode has capacity to connect more lines
## 
func passes_base_conditions(l: MapLine) -> bool:
	var is_duplicate = is_duplicate_line(l)
	var has_cap = has_capacity()
	var is_self = l.start == self
	#print("Is Duplicate: ", is_duplicate, ". Has Capacity: ", has_cap)
	return !is_duplicate and has_cap and !is_self

## If two lines share the same start and end
func is_duplicate_line(l: MapLine) -> bool:
	# Prevent Exact duplicate mapnode_connections (ignore direction)
	for line in mapline_connections:
		var a_start = l.start
		var a_end = l.end
		var b_start = line.start
		var b_end = line.end
		if (a_start == b_start and a_end == b_end) or (a_start == b_end and a_end == b_start):
			return true
	return false

func has_capacity() -> bool:
	#if is_unlimited_capacity or mapline_connections.size() < max_capacity: print("Has capacity")
	return is_unlimited_capacity or mapline_connections.size() < max_capacity

"""
Cursor Functions
"""
func handle_drag_out(_c: EnchantmentCursor) -> void:
	pass
