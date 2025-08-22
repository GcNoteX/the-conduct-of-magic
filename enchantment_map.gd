class_name EnchantmentMap
extends Node2D

"""
EnchantmentMap is mainly a container, any functionality
to do operations on the map is on other nodes,
the EnchantmentMap will emit signals to work with the nodes within it.
"""


signal starting_socket_selected(s: Socket)
signal ending_socket_selected(s: Socket)

@export var sockets: Array[Socket]
@export var magic_edges: Array[MagicEdge]

func _ready() -> void:
	sockets.clear()
	magic_edges.clear()
	
	for child in get_children():
		if child is Socket:
			child.selected_as_start.connect(_on_start_socket_selected)
			child.selected_as_end.connect(_on_end_socket_selected)
			sockets.append(child)
		elif child is MagicEdge:
			magic_edges.append(child)


func add_magic_edge_to_map(e: MagicEdge) -> void:
	add_child(e)

func _on_start_socket_selected(s: Socket) -> void:
	emit_signal("starting_socket_selected", s)

func _on_end_socket_selected(s: Socket) -> void:
	emit_signal("ending_socket_selected", s)
