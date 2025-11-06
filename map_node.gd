@abstract class_name MapNode extends Area2D

"""
An abstract class to compile define all Node-Type objects within a PlayMap
"""

signal mapnode_added(m: MapNode) ## If an inheriting class wants to perform extra operations after
signal mapnode_removed(m: MapNode) ## If an inheriting class wants to perform extra operations after
signal mapline_added(l: MapLine) ## If an inheriting class wants to perform extra operations after
signal mapline_removed(l: MapLine) ## If an inheriting class wants to perform extra operations after

@export var mapnode_connections: Dictionary[MapNode, int] = {} ## The number of connected nodes
@export var mapline_connections: Array[MapLine] = [] ## The number of connected lines

@export var is_unlimited_capacity: bool = true
@export var max_capacity: int = 0:
	set(c):
		if c < 0:
			return
		max_capacity = c

@abstract func get_bounded_identity() -> Variant

func _ready() -> void:
	mapnode_connections.clear()
	mapline_connections.clear()

"""
Connection Functions
"""
func add_connection(l: MapLine) -> void:
	if mapline_connections.has(l):
		push_error("Attempting to add the same line more than once!")
		return

	mapline_connections.append(l)
	l.destroyed.connect(remove_connection)
	emit_signal("mapline_added", l)

	# --- handle start ---
	if l.start != null:
		var start_owner := l.start.owner as MapNode
		if start_owner != self: # Finding the node that is not itself
			var is_new := not mapnode_connections.has(start_owner)
			mapnode_connections[start_owner] = mapnode_connections.get(start_owner, 0) + 1
			if is_new:
				emit_signal("mapnode_added", start_owner)
	else:
		push_warning("Attempted to add MapLine with no start")

	# --- handle end ---
	if l.end != null:
		var end_owner := l.end.owner as MapNode
		if end_owner != self: # Finding the node that is not itself
			var is_new := not mapnode_connections.has(end_owner)
			mapnode_connections[end_owner] = mapnode_connections.get(end_owner, 0) + 1
			if is_new:
				emit_signal("mapnode_added", end_owner)
	else:
		pass # optional warning here if needed


func remove_connection(l: MapLine) -> void:
	if not mapline_connections.has(l):
		push_warning("Attempted to remove line that is not connected")
		return

	mapline_connections.erase(l)
	emit_signal("mapline_removed", l)

	# --- handle start ---
	if l.start != null:
		var start_owner := l.start.owner as MapNode
		if start_owner != self and mapnode_connections.has(start_owner):
			mapnode_connections[start_owner] -= 1
			if mapnode_connections[start_owner] <= 0:
				mapnode_connections.erase(start_owner)
				emit_signal("mapnode_removed", start_owner)

	# --- handle end ---
	if l.end != null:
		var end_owner := l.end.owner as MapNode
		if end_owner != self and mapnode_connections.has(end_owner):
			mapnode_connections[end_owner] -= 1
			if mapnode_connections[end_owner] <= 0:
				mapnode_connections.erase(end_owner)
				emit_signal("mapnode_removed", end_owner)


func _clear_connections() -> void:
	mapnode_connections.clear()
	mapline_connections.clear()


"""
Conditions Functions
"""
func passes_base_conditions(l: MapLine) -> bool:
	var is_duplicate = is_duplicate_line(l)
	var has_cap = has_capacity()
	#print("Is Duplicate: ", is_duplicate, ". Has Capacity: ", has_cap)
	return !is_duplicate and has_cap

func is_duplicate_line(l: MapLine) -> bool:
	# If the end is already selected, allow regardless (for prebuilds)
	if l.end:
		return false

	# Prevent Exact duplicate mapnode_connections (ignore direction)
	for line in mapline_connections:
		if (l.start == line.start and l.end == line.end) or (l.start == line.end and l.end == line.start):
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
