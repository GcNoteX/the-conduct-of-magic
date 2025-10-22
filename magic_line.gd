class_name MagicLine
extends Area2D

"""
- A straight line that goes between two MagicLineConnectableComponents
"""

signal locked

@onready var visual_shape: Line2D = $Line2D
@onready var collision_shape: CollisionShape2D = $LineCollisionShape


# The MagicLineConnectableComponent the MagicLine goes between
# INFO: Storing starting and ending points in MagicLine helps with traversal and makes identifying the state of the MagicLine for further features easier.
@export var start: MagicLineConnectableComponent = null
@export var end: MagicLineConnectableComponent = null
@export var width = 15 # The width of the MagicLine 

var initialized = false

func _ready() -> void:
	assert(start, "A MagicLine cannot exist without a start!")
	
	collision_shape.shape = collision_shape.shape.duplicate() # Collision shapes in instances share shape resource when they shouldnt
	
	# Start the line at the start position
	_change_visual_start_point(start.global_position)
	visual_shape.add_point(start.global_position)
	
	collision_shape.shape.size.x = width
	visual_shape.width = width
	initialized = true

## Stretch the MagicLine to a new destination 
func stretch_line(v: Vector2) -> void:
	_change_visual_end_point(v)
	_update_collision_shape()

## Locks the MagicLine to an ending MagicLineConnectableComponent
func lock_line(m: MagicLineConnectableComponent) -> void:
	end = m
	stretch_line(m.global_position)
	emit_signal("locked")

## Destroy the MagicLine and update related components
func kill_magic_line() -> void:
	pass
	if start:
		start.remove_edge(self)
	if end:
		end.remove_edge(self)
	queue_free()

## Abstracts away the line2d updating first point (the start)
func _change_visual_start_point(v: Vector2) -> void:
	visual_shape.set_point_position(0, v)

## Abstracts away the line2d updating second point (the end)
func _change_visual_end_point(v: Vector2) -> void:
	visual_shape.set_point_position(1, v)

## Updates collision shape of line to follow line
func _update_collision_shape() -> void:
	# Make collision length (which its y-size) match visual length.
	var u = visual_shape.get_point_position(0)
	var v = visual_shape.get_point_position(1)
	var length = u.distance_to(v)
	var angle = v.angle_to_point(u) - PI/2
	var pos = (u+v)/2
	
	collision_shape.position = pos
	collision_shape.shape.size.y = length
	collision_shape.rotation = angle
