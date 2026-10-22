@abstract
class_name MapNode extends EnchantmentMapElement
## Base class for every node on the legacy play map. Tracks the lines drawn onto it and the
## nodes those lines connect it to.

signal mapnode_added(m: MapNode)  ## For subclasses that need to do more afterwards
signal mapnode_removed(m: MapNode)  ## For subclasses that need to do more afterwards
signal mapline_added(l: MapLine)  ## For subclasses that need to do more afterwards
signal mapline_removed(l: MapLine)  ## For subclasses that need to do more afterwards
signal connections_updated

@export var is_unlimited_capacity: bool = true
@export var max_capacity: int = 0:
	set(c):
		if c < 0:
			return
		max_capacity = c

## Connected nodes, each with the number of lines joining them to this node. Runtime state.
var mapnode_connections: Dictionary[MapNode, int] = {}
## Lines drawn onto this node. Runtime state.
var mapline_connections: Array[MapLine] = []


func _ready() -> void:
	_initialize_node()
	push_warning("Abstract class MapNode _ready() called by ", self)


# Utilities


static func gather_connections(source: MapNode) -> Array[MapNode]:
	var raw_nodes := UtilityFunctions.dfs_collect_nodes(
		source.mapnode_connections.keys(), func(node): return node.mapnode_connections
	)
	# The failing type hints at run time block it without this
	var connected_nodes: Array[MapNode] = []
	for n in raw_nodes:
		if n is MapNode:
			connected_nodes.append(n)

	return connected_nodes


static func gather_lines(nodes: Array[MapNode]) -> Array[MapLine]:
	var lines: Array[MapLine] = []
	var seen := {}  # acts like a Set for uniqueness
	for node in nodes:
		for line in node.mapline_connections:
			if line == null:
				continue
			if not seen.has(line):
				seen[line] = true
				lines.append(line)

	return lines


func kill_node() -> void:
	for line in mapline_connections:
		line.kill_line()
	queue_free()


# Connection Functions


func add_line_connection(l: MapLine) -> void:
	if mapline_connections.has(l):
		push_error("Attempting to add the same line more than once!")
		return

	mapline_connections.append(l)
	l.destroyed.connect(remove_line_connection)
	mapline_added.emit(l)

	# handle start and end nodes
	if l.start:
		_add_node_from_line(l.start)
	if l.end:
		_add_node_from_line(l.end)
	else:
		l.connected.connect(_add_node_from_line_aux)

	connections_updated.emit()


func remove_line_connection(l: MapLine) -> void:
	if not mapline_connections.has(l):
		## WARNING: Sometimes this is called because delete line is called multiple times
		## since collision is detected by specific area and not just area entered
		push_warning(
			"Attempted to remove line %s from %s that is not connected" % [str(l), str(self)]
		)
		return

	mapline_connections.erase(l)
	mapline_removed.emit(l)

	# handle start and end nodes
	_remove_node_from_line(l.start)
	_remove_node_from_line(l.end)

	connections_updated.emit()


# Conditions Functions


## Conditions for a line that is trying to connect to the node
## Con1: MapLine does not share the same start and end as another line (i.e. Duplicate)
## Con2: MapNode has capacity to connect more lines
func passes_base_conditions(l: MapLine) -> bool:
	var is_duplicate := is_duplicate_line(l)
	var has_cap := has_capacity()
	var is_self := l.start == self
	return not is_duplicate and has_cap and not is_self


## If two lines share the same start and end
func is_duplicate_line(l: MapLine) -> bool:
	var l_start := l.start

	if l_start == null:
		return false  # prevent errors when the line has no start yet

	for line in mapline_connections:
		# If any existing line touches the same start node
		if line.start == l_start or line.end == l_start:
			return true

	return false


func has_capacity() -> bool:
	return is_unlimited_capacity or mapline_connections.size() < max_capacity


# Cursor Functions


func handle_drag_out(_c: EnchantmentCursor) -> void:
	pass


# Detection Handling

@abstract func disable_detection() -> void

@abstract func enable_detection() -> void


func _initialize_node() -> void:
	mapnode_connections.clear()
	mapline_connections.clear()
	connections_updated.connect(EmapUpdateManager._on_MapNode_connections_updated)


func _add_node_from_line(node: MapNode) -> void:
	if node == null:
		push_warning("Attempted to add MapLine with null node")
		return

	if node == self:
		return  # avoid self-connection

	var is_new := not mapnode_connections.has(node)
	mapnode_connections[node] = mapnode_connections.get(node, 0) + 1

	if is_new:
		mapnode_added.emit(node)


func _add_node_from_line_aux(node: MapNode) -> void:
	_add_node_from_line(node)
	connections_updated.emit()


func _remove_node_from_line(node: MapNode) -> void:
	if node == null or node == self:
		return

	if not mapnode_connections.has(node):
		push_warning("Attempted to removed connection to", node, " which is not connected")
		return

	mapnode_connections[node] -= 1
	if mapnode_connections[node] <= 0:
		mapnode_connections.erase(node)
		mapnode_removed.emit(node)


func _clear_connections() -> void:
	mapnode_connections.clear()
	mapline_connections.clear()
