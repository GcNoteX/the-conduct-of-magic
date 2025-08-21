class_name MagicEdge
extends Line2D

"""
An Edge is a line between two points
A MagicEdge has to start from a Socket and end at a Socket when finalized.
While connecting the sockets, the data of what happens in between to the line should be tracked.
"""

var starting_socket: Socket
var ending_socket: Socket
var is_locked: bool = false

func _ready() -> void:
	assert(starting_socket != null, "ERROR: MagicEdge placed in scene without a starting socket, suggest using create_magic_edge()")
	add_point(starting_socket.position)


## Can only be used when the line is not locked
func update_floating_line(v: Vector2) -> void:
	# NOTE: Given it is an Edge, there will only be two points, but I am leaving the option to making curved lines in which this has to be overrided.
	# Updates the second/ending/final point (since its an edge)
	
	assert(is_locked == false, "MagicEdge can only be updated when not locked!")
	
	if get_point_count() == 1: # A final point has not been made
		add_point(v)
	else:
		set_point_position(1, v)
	
## Finalize the edge, should not be edited anymore
func lock_line(end_socket: Socket) -> void:
	assert(end_socket != null, "ERROR: Attempting to lock MagicEdge without a valid ending Socket")
	ending_socket = end_socket
	set_point_position(get_point_count() - 1, ending_socket.position)
	is_locked = true


static func create_magic_edge(start: Socket, is_debug = false) -> MagicEdge:
	assert(start != null, "ERROR: MagicEdge created without a starting socket")
	var ins: MagicEdge = MagicEdge.new()
	ins.starting_socket = start
	if is_debug: print("Creating magic edge from:", ins.starting_socket.position, ins.ending_socket.position)
	return ins
