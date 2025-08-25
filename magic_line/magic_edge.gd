@tool
class_name MagicEdge
extends Area2D


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
@onready var magic_edge_collision_shape: CollisionShape2D = $LineCollisionShape
@onready var magic_line: Line2D = $MagicLine

# The socket the edge goes between
@export var starting_socket: Socket:
		set(s):
			if s == null:
				if starting_socket and Engine.is_editor_hint():
					starting_socket.remove_connection(self)
					starting_socket = null
				if ending_socket:
					ending_socket = null
				magic_line.clear_points()
				_reset_collision_shape()
				return
			if !s.can_connect_edge():

				push_error("Socket is at max capacity, unable to connect start")
				return
			starting_socket = s
			starting_socket.add_connection(self)
			if is_instance_valid(magic_line) and is_instance_valid(starting_socket) and Engine.is_editor_hint():
				magic_line.clear_points()
				magic_line.add_point(starting_socket.position)
		
@export var ending_socket: Socket:
		set(s):
			if s == null and ending_socket and Engine.is_editor_hint(): # For editor use, clearing connection
				ending_socket.remove_connection(self)
				ending_socket = null
				is_locked = false
				magic_line.remove_point(1)
				_reset_collision_shape()
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
			if is_instance_valid(magic_line) and is_instance_valid(ending_socket) and Engine.is_editor_hint():
				lock_line()

@export var line_highlighted: bool:
	set(l):
		line_highlighted = l
		if line_highlighted:
			modulate = Color(1, 1, 0, 1)
		else:
			modulate = Color(1, 1, 1, 1)
@export var kill: bool:
	set(i):
		kill_edge()
		
# States of the line
var is_locked: bool = false ## The edge has both sockets selected, it cannot be modified, only destroyed.
const SHAPE_PADDING: int = 1

# Other attributes of the line
@onready var max_width: float = magic_line.width


func _ready() -> void:
	if Engine.is_editor_hint():
		if starting_socket:
			magic_line.add_point(starting_socket.position)
		if ending_socket:
			magic_line.add_point(ending_socket.position)
		if starting_socket and ending_socket:
			update_collision_shape()
		return
	assert(starting_socket, "ERROR: MagicEdge placed in scene without a starting socket, suggest using start_magic_edge()")
	magic_line.add_point(starting_socket.position)
	if ending_socket: # A line is not created with an ending socket unless it is instantiated as such
		lock_line()
	if magic_edge_collision_shape and starting_socket and ending_socket:
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
	#print("Stretching")
	if magic_line.get_point_count() == 1: # A final point has not been made
		magic_line.add_point(v)
	else:
		magic_line.set_point_position(1, v)
	
	if magic_edge_collision_shape:
		call_deferred("update_collision_shape")

## Finalize the edge, should not be edited anymore
## Boolean return to determine if the socket can continue to be used or if limit is reached
func lock_line() -> bool:
	assert(ending_socket != null, "ERROR: Attempting to lock MagicEdge without a valid ending Socket")
	stretch_magic_edge(ending_socket.position)
	is_locked = true
	if !ending_socket.can_connect_edge():
		return false
	if Engine.is_editor_hint():
		return true
		
	stop_decay()
	return true

func stop_decay() -> void:
	# NOTE: Incase of animation, seperate to a function
	decay_component.stop_decay()

func start_decay() -> void:
	if is_locked:
		return
	# NOTE: Incase of animation, seperate to a function
	decay_component.start_decay()

## Kills the edge safely, guranteed kill
func kill_edge() -> void:
	if starting_socket:
		starting_socket.remove_connection(self)
	if ending_socket:
		ending_socket.remove_connection(self)
	queue_free()
	emit_signal("magic_edge_destroyed", self)


func update_collision_shape():
	var a = magic_line.get_point_position(0)
	var b = magic_line.get_point_position(1)
	var length = a.distance_to(b)
	var angle = (b - a).angle() - PI/2
	var new_shape: CapsuleShape2D = CapsuleShape2D.new()
	new_shape.radius = magic_line.width/2 + SHAPE_PADDING
	new_shape.height = max(0, length + 2 * new_shape.radius)
	magic_edge_collision_shape.shape = new_shape
	magic_edge_collision_shape.position = (a + b) / 2
	magic_edge_collision_shape.rotation = angle


func _reset_collision_shape() -> void:
	magic_edge_collision_shape.position = Vector2.ZERO
	magic_edge_collision_shape.rotation = 0.0
	magic_edge_collision_shape.shape = CapsuleShape2D.new()


func highlight() -> void:
	line_highlighted = true

func unhighlight() -> void:
	line_highlighted = false

func _on_health_component_health_depleted() -> void:
	# As the line deletes itself, we give the points of the line to do any manual effects needed based on where the line would be drawn.
	kill_edge()


func _on_health_component_health_updated() -> void:
	#print("MagicEdge health updated")
	magic_line.width = health_component.health/health_component.max_health * max_width
	call_deferred("update_collision_shape")


func _on_mouse_entered() -> void:
	pass # Replace with function body.


func _on_mouse_exited() -> void:
	pass # Replace with function body.


func _on_area_entered(area: Area2D) -> void:
	print("Cursor detected entering")
	emit_signal("magic_edge_unhovered_over", self)


func _on_area_exited(area: Area2D) -> void:
	print("Cursor detected exiting")
	emit_signal("magic_edge_hovered_over", self)
