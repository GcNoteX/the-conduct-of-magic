class_name EnchantmentMap
extends Node2D

"""
EnchantmentMap is mainly a container that ensures accurate signals, any functionality
to do operations on the map is on other nodes,
the EnchantmentMap will emit signals to work with the nodes within it.
"""

signal map_initialized()
signal magic_edge_destroyed(e: MagicEdge)
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
			child.magic_edge_destroyed.connect(_on_edge_destroyed)
			#child.magic_edge_hovered_over.connect(_on_magic_edge_hovered_over)
			#child.magic_edge_unhovered_over.connect(_on_magic_edge_unhovered_over)
			magic_edges.append(child)
	
	emit_signal("map_initialized")

func add_magic_edge_to_map(e: MagicEdge) -> void:
	e.magic_edge_destroyed.connect(_on_edge_destroyed)
	#e.magic_edge_hovered_over.connect(_on_magic_edge_hovered_over)
	#e.magic_edge_unhovered_over.connect(_on_magic_edge_unhovered_over)
	add_child(e)
	emit_signal("magic_edge_added", e)

func _on_start_socket_selected(s: Socket) -> void:
	emit_signal("starting_socket_selected", s)

func _on_end_socket_selected(s: Socket) -> void:
	emit_signal("ending_socket_selected", s)

func _on_edge_destroyed(e: MagicEdge) -> void:
	emit_signal("magic_edge_destroyed", e)

#func _on_magic_edge_hovered_over(e: MagicEdge) -> void:
	#emit_signal("magic_edge_hovered_over", e)
	#
#func _on_magic_edge_unhovered_over(e: MagicEdge) -> void:
	#emit_signal("magic_edge_unhovered_over", e)
