class_name MagicEdge
extends Line2D

var starting_socket: Socket
var ending_socket: Socket

func _ready() -> void:
	assert(starting_socket != null, "ERROR: MagicEdge created without a starting socket, suggest using create_magic_edge()")
	assert(ending_socket != null, "ERROR: MagicEdge created without an ending socket, suggest using create_magic_edge()")
	add_point(starting_socket.position)
	add_point(ending_socket.position)

static func create_magic_edge(start: Socket, end: Socket, is_debug = false) -> MagicEdge:
	assert(start != null, "ERROR: MagicEdge created without a starting socket")
	assert(end != null, "ERROR: MagicEdge created without an ending socket")
	var ins: MagicEdge = MagicEdge.new()
	ins.starting_socket = start
	ins.ending_socket = end
	if is_debug: print("Creating magic edge from:", ins.starting_socket.position, ins.ending_socket.position)
	return ins
