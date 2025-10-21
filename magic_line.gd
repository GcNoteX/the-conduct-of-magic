class_name MagicLine
extends Area2D

"""
- A straight line that goes between two MagicLineConnectableComponents
"""

@onready var visual_shape: Line2D = $Line2D
@onready var collision_shape: CollisionShape2D = $LineCollisionShape


# The MagicLineConnectableComponent the MagicLine goes between
# INFO: Storing starting and ending points in MagicLine helps with traversal and makes identifying the state of the MagicLine for further features easier.
@export var start: MagicLineConnectableComponent = null
@export var end: MagicLineConnectableComponent = null

@export var width = 15 # The width of the MagicLine 

func _ready() -> void:
	collision_shape.shape.size.x = width
	visual_shape.width = width


## Stretch the MagicLine to a new destination 
func stretch_line(v: Vector2) -> void:
	_change_visual_end_point(v)
	_update_collision_shape()


## Abstracts away the line2d updating second point (the end)
func _change_visual_end_point(v: Vector2) -> void:
	visual_shape.set_point_position(1, v)

## Updates collision shape of line to follow line
func _update_collision_shape() -> void:
	# Make collision length (which its y-size) match visual length.
	var u = visual_shape.get_point_position(0)
	var v = visual_shape.get_point_position(1)
	var length = u.distance_to(v)
	var angle = -1 * v.angle_to_point(u)
	var pos = (u+v)/2
	
	collision_shape.position = pos
	collision_shape.shape.size.y = length
	collision_shape.rotation = angle
