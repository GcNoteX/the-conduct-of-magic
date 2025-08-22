@tool
class_name MagicEdge
extends Line2D

"""
An Edge is a line between two points
A MagicEdge has to start from a Socket and end at a Socket when finalized.
While connecting the sockets, the data of what happens in between to the line should be tracked.
"""

signal magic_edge_hovered_over(e: MagicEdge)
signal magic_edge_unhovered_over(e: MagicEdge)
signal magic_edge_destroyed(e: MagicEdge)


@onready var decay_component: DecayComponent = $DecayComponent
@onready var health_component: HealthComponent = $HealthComponent
@onready var magic_edge_area: Area2D = $Area2D
@onready var magic_edge_collision_shape: CollisionShape2D = $Area2D/CollisionShape2D

# The socket the edge goes between
@export var starting_socket: Socket:
		set(s):
			if s == null:
				if starting_socket and Engine.is_editor_hint():
					starting_socket.remove_connection(self)
					starting_socket = null
				if ending_socket:
					ending_socket = null
				clear_points()
				return
			if !s.can_connect_edge():

				push_error("Socket is at max capacity, unable to connect start")
				return
			starting_socket = s
			starting_socket.add_connection(self)
			if is_instance_valid(starting_socket) and Engine.is_editor_hint(): 
				clear_points()
				add_point(starting_socket.position)
		
@export var ending_socket: Socket:
		set(s):
			if s == null and ending_socket and Engine.is_editor_hint(): # For editor use, clearing connection
				ending_socket.remove_connection(self)
				ending_socket = null
				is_locked = false
				remove_point(1)
				return
			if !starting_socket:
				if Engine.is_editor_hint(): push_error("Cannot add an Ending Socket before Starting Socket")
				return
			if !s.can_connect_edge():
				if Engine.is_editor_hint(): push_error("Socket is at max capacity, unable to connect end")
				print("Socket is at max capacity, unable to connect")
				return
			ending_socket = s
			ending_socket.add_connection(self)
			if is_instance_valid(ending_socket) and Engine.is_editor_hint():
				lock_line()

@export var highlight_color: Color = Color(1.0, 0.894, 0.795, 1)

# States of the line
var is_locked: bool = false ## The edge has both sockets selected, it cannot be modified, only destroyed.
const SHAPE_PADDING: int = 2

# Other attributes of the line
@onready var max_width: float = self.width


func _ready() -> void:
	if Engine.is_editor_hint():
		update_collision_shape()
		return
	assert(starting_socket, "ERROR: MagicEdge placed in scene without a starting socket, suggest using start_magic_edge()")
	add_point(starting_socket.position)
	if ending_socket: # A line is not created with an ending socket unless it is instantiated as such
		lock_line()
	if magic_edge_area and magic_edge_collision_shape and starting_socket and ending_socket:
		update_collision_shape()

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
	
	if magic_edge_area and magic_edge_collision_shape:
		call_deferred("update_collision_shape")

## Finalize the edge, should not be edited anymore
func lock_line() -> void:
	assert(ending_socket != null, "ERROR: Attempting to lock MagicEdge without a valid ending Socket")
	stretch_magic_edge(ending_socket.position)
	is_locked = true
	if Engine.is_editor_hint():
		return
		
	stop_decay()

func stop_decay() -> void:
	# NOTE: Incase of animation, seperate to a function
	decay_component.stop_decay()


func start_decay() -> void:
	if is_locked:
		return
	# NOTE: Incase of animation, seperate to a function
	decay_component.start_decay()


func update_collision_shape():
	var a = get_point_position(0)
	var b = get_point_position(1)
	var length = a.distance_to(b)
	var angle = (b - a).angle() - PI/2
	var new_shape: CapsuleShape2D = CapsuleShape2D.new()
	new_shape.radius = width/2 + SHAPE_PADDING
	new_shape.height = max(0, length + 2 * new_shape.radius)
	magic_edge_collision_shape.shape = new_shape
	magic_edge_area.position = (a + b) / 2
	magic_edge_area.rotation = angle



func _on_health_component_health_depleted() -> void:
	# As the line deletes itself, we give the points of the line to do any manual effects needed based on where the line would be drawn.
	emit_signal("magic_edge_destroyed", self)
	queue_free()


func _on_health_component_health_updated() -> void:
	#print("MagicEdge health updated")
	self.width = health_component.health/health_component.max_health * max_width


func _on_area_2d_mouse_entered() -> void:
	emit_signal("magic_edge_hovered_over", self)


func _on_area_2d_mouse_exited() -> void:
	emit_signal("magic_edge_unhovered_over", self)
