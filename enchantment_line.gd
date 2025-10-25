@tool
class_name EnchantmentLine
extends Area2D

"""
- A special line that goes between EnchantmentNodes
"""

signal locked

@onready var visual_shape: Line2D = $Line2D
@onready var collision_shape: CollisionShape2D = $LineCollisionShape


# The EnchantmentLineConnectableComponent the MagicLine goes between
# INFO: Storing starting and ending points in MagicLine helps with traversal and makes identifying the state of the MagicLine for further features easier.
@export var start: EnchantmentLineConnectableComponent = null
@export var end: EnchantmentLineConnectableComponent = null
@export var width = 15 # The width of the MagicLine 

var initialized = false

func _ready() -> void:
	if !Engine.is_editor_hint():
		assert(start, "A MagicLine cannot exist without a start!")

	collision_shape.shape = collision_shape.shape.duplicate() # Collision shapes in instances share shape resource when they shouldnt

	# Start the line at the start position
	start.add_edge(self)
	global_position = start.global_position

	if end: # An end point visually needs to be set ahead of time
		if !(visual_shape.get_point_count() == 2): # we need to check the point count because in @tool mode it would just keep adding points
			visual_shape.add_point(end.position)
		end.add_edge(self)
		lock_line(end)
	else: # Set end point of visual shape to start if it dose not exist yet for cleaner rendering/updates of the line
		if visual_shape.get_point_count() == 1:
			visual_shape.add_point(visual_shape.get_point_position(0))
		elif visual_shape.get_point_count() == 2:
			visual_shape.set_point_position(1, visual_shape.get_point_position(0))

	collision_shape.shape.size.x = width
	visual_shape.width = width
	initialized = true

## Stretch the MagicLine to a new destination 
func stretch_line(v: Vector2) -> void:
	_change_visual_end_point(v)
	_update_collision_shape()

## Locks the MagicLine to an ending EnchantmentLineConnectableComponent
func lock_line(m: EnchantmentLineConnectableComponent) -> void:
	end = m
	stretch_line(m.global_position - global_position)
	emit_signal("locked")

## Destroy the MagicLine and update related components
func kill_magic_line() -> void:
	print("Line Killed")
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
