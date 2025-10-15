@tool
class_name MagicEdge
extends Area2D


"""
An Edge is a line between two points
A MagicEdge has to start from a MagicEdgeConnectableComponent and end at a MagicEdgeConnectableComponent when finalized.
While connecting the MagicEdgeConnectableComponents, the data of what happens in between to the line should be tracked.
"""

signal hovered_over(e: MagicEdge)
signal unhovered_over(e: MagicEdge)
signal destroyed(e: MagicEdge)
signal locked(e: MagicEdge)

@onready var decay_component: DecayComponent = $DecayComponent
@onready var health_component: HealthComponent = $HealthComponent
@onready var magic_edge_collision_shape: CollisionShape2D = $LineCollisionShape
@onready var magic_line: Line2D = $MagicLine

# The MagicEdgeConnectableComponent the edge goes between
@export var start: MagicEdgeConnectableComponent = null
@export var end: MagicEdgeConnectableComponent = null

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
var is_hovered_over = false

var is_locked: bool = false ## The edge has both MagicEdgeConnectableComponents selected, it cannot be modified, only destroyed.

const SHAPE_PADDING: int = 1

# Other attributes of the line
@onready var max_width: float = magic_line.width


func _ready() -> void:
	if Engine.is_editor_hint():
		if start:
			magic_line.add_point(start.position)
		if end:
			magic_line.add_point(end.position)
		if start and end:
			update_collision_shape()
		return
	assert(start, "ERROR: MagicEdge placed in scene without a starting MagicEdgeConnectableComponent, suggest using start_magic_edge()")
	magic_line.add_point(start.position)
	if end: # A line is not created with an ending MagicEdgeConnectableComponent unless it is instantiated as such
		lock_line()
	if magic_edge_collision_shape and start and end:
		update_collision_shape()

## Creates a magic edge only with the starting MagicEdgeConnectableComponent. Use lock_line() to lock it to another MagicEdgeConnectableComponent, stretch_magic_edge() to move it.
static func start_magic_edge(start: MagicEdgeConnectableComponent, is_debug = false) -> MagicEdge:
	assert(start != null, "ERROR: MagicEdge created without a starting MagicEdgeConnectableComponent")
	var ins: MagicEdge = preload(SceneReferences.magic_edge).instantiate()
	ins.start = start
	if is_debug: 
		print("Creating magic edge from:", ins.start.position, ins.end.position)
	return ins


## Creates a magic edge between two MagicEdgeConnectableComponents
static func create_magic_edge(start: MagicEdgeConnectableComponent, end: MagicEdgeConnectableComponent, is_debug = false) -> MagicEdge:
	assert(start != null, "ERROR: MagicEdge created without a starting MagicEdgeConnectableComponent")
	var ins: MagicEdge = preload(SceneReferences.magic_edge).instantiate()
	ins.start = start
	ins.end = end
	if is_debug: print("Creating magic edge from:", ins.start.position, ins.end.position)
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
## Boolean return to determine if the MagicEdgeConnectableComponent can continue to be used or if limit is reached
func lock_line() -> bool:
	assert(end != null, "ERROR: Attempting to lock MagicEdge without a valid ending MagicEdgeConnectableComponent")
	stretch_magic_edge(end.position)
	is_locked = true
	if !end.can_connect_edge():
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
	if start:
		start.remove_connection(self)
	if end:
		end.remove_connection(self)
	queue_free()
	emit_signal("destroyed", self)


func get_end_of_line() -> Vector2:
	return magic_line.get_point_position(1)


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


func _on_area_entered(_area: Area2D) -> void:
	is_hovered_over = true


func _on_area_exited(_area: Area2D) -> void:
	is_hovered_over = false

func get_vector_from_line() -> Vector2:
	var v1 = start.position
	var v2 = end.position
	return (v2 - v1).normalized()
