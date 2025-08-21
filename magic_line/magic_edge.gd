class_name MagicEdge
extends Line2D

"""
An Edge is a line between two points
A MagicEdge has to start from a Socket and end at a Socket when finalized.
While connecting the sockets, the data of what happens in between to the line should be tracked.
"""

signal magic_edge_destroyed(v1: Vector2, v2: Vector2)


@onready var decay_component: DecayComponent = $DecayComponent
@onready var health_component: HealthComponent = $HealthComponent


# The socket the edge goes between
var starting_socket: Socket
var ending_socket: Socket

# States of the line
var is_in_focus: bool = false ## The edge is 'selected'. (i.e. The player is controlling the line, has it selected).
var is_locked: bool = false ## The edge has both sockets selected, it cannot be modified, only destroyed.


# Other attributes of the line
@onready var max_width: float = self.width

func _ready() -> void:
	assert(starting_socket, "ERROR: MagicEdge placed in scene without a starting socket, suggest using start_magic_edge()")
	add_point(starting_socket.position)
	if ending_socket: # A line is not created with an ending socket unless it is instantiated as such
		lock_line(ending_socket)


## Creates a magic edge only with the starting socket. Use lock_line() to lock it to another socket, stretch_magic_edge() to move it.
static func start_magic_edge(start: Socket, is_debug = false) -> MagicEdge:
	assert(start != null, "ERROR: MagicEdge created without a starting socket")
	var ins: MagicEdge = preload(SceneReferences.magic_edge).instantiate()
	ins.starting_socket = start
	if is_debug: 
		print("Creating magic edge from:", ins.starting_socket.position, ins.ending_socket.position)
	return ins


## Creates a magic edge between two sockets
static func create_magic_edge(start: Socket, end: Socket, is_debug = false) -> MagicEdge:
	assert(start != null, "ERROR: MagicEdge created without a starting socket")
	var ins: MagicEdge = preload(SceneReferences.magic_edge).instantiate()
	ins.starting_socket = start
	ins.ending_socket = end
	if is_debug: print("Creating magic edge from:", ins.starting_socket.position, ins.ending_socket.position)
	return ins


## Can only be used when the line is not locked
func stretch_magic_edge(v: Vector2) -> void:
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
	stretch_magic_edge(ending_socket.position)
	is_locked = true
	decay_component.stop_decay()


## Focusing a line stops decay
func focus_line() -> void:
	is_in_focus = true
	decay_component.stop_decay()


## Unfocusing a line starts decay
func unfocus_line() -> void:
	is_in_focus = false
	decay_component.start_decay()


func _on_health_component_health_depleted() -> void:
	# As the line deletes itself, we give the points of the line to do any manual effects needed based on where the line would be drawn.
	emit_signal("magic_edge_destroyed", get_point_position(0), get_point_position(1))
	queue_free()


func _on_health_component_health_updated() -> void:
	print("Update health")
	self.width = health_component.health/health_component.max_health * max_width
