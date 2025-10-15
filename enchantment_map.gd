class_name EnchantmentMap
extends Node2D

"""
EnchantmentMap is mainly a container that ensures accurate signals, 
any functionality to do operations on the map is on other nodes,
the EnchantmentMap will emit signals to work with the nodes within it.
"""

signal map_initialized()
signal updated()
signal magic_edge_added(e: MagicEdge)
signal starting_socket_selected(s: Socket)
signal ending_socket_selected(s: Socket)

var sockets: Array[Socket]
var magic_edges: Array[MagicEdge]

func _ready() -> void:
	for child in get_children():
		if child is Socket:
			child.selected_as_start.connect(_on_start_socket_selected)
			child.selected_as_end.connect(_on_end_socket_selected)
			sockets.append(child)
		elif child is MagicEdge:
			child.destroyed.connect(_on_edge_destroyed)
			child.locked.connect(_on_edge_locked)
			magic_edges.append(child)
	
	emit_signal("map_initialized")

func add_magic_edge_to_map(e: MagicEdge) -> void:
	e.destroyed.connect(_on_edge_destroyed)
	e.locked.connect(_on_edge_locked)
	add_child(e)
	magic_edges.append(e)
	emit_signal("magic_edge_added", e)

func _on_start_socket_selected(s: Socket) -> void:
	emit_signal("starting_socket_selected", s)

func _on_end_socket_selected(s: Socket) -> void:
	emit_signal("ending_socket_selected", s)

func _on_edge_destroyed(e: MagicEdge) -> void:
	magic_edges.erase(e)
	emit_signal("updated")

func _on_edge_locked(_e: MagicEdge) -> void:
	#print("Map Updated")
	emit_signal("updated")

## Checks if the edge goes between the same sockets as any other edge.
func is_edge_duplicate(end_socket: Socket, new_edge: MagicEdge) -> bool:
	assert(end_socket.can_connect_edge(), "Redundancy check for valid socket tripped, socket should be able to connect edge! Please check why.")
	
	var starting_socket: Socket = new_edge.starting_socket
	for edge in magic_edges:
		if (edge.starting_socket == starting_socket or \
			edge.starting_socket == end_socket) and \
			(edge.ending_socket == starting_socket or \
			edge.ending_socket == end_socket):
			return true 
	
	return false
