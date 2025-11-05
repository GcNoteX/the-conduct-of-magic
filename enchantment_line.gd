@tool
class_name EnchantmentLine
extends MapLine

"""
- A special line that goes between EnchantmentNodes
"""

signal locked

@onready var visual_shape: Line2D = $Line2D
@onready var collision_shape: CollisionShape2D = $LineCollisionShape
@onready var line_connecting_shape: CollisionShape2D = $LineConnectingShape


var initialized = false

## If the collision box is the entire line, spawn points for lines overlap and kill each other. This is a naive solution to that.
@export var collision_length_offset: int = 100
@export var collision_width_offset: int = 13

func _ready() -> void:
	# Setup the Line's Shape
	if !Engine.is_editor_hint():
		assert(start, "A MagicLine cannot exist without a start!")

	collision_shape.shape = collision_shape.shape.duplicate() # Collision shapes in instances share shape resource when they shouldnt
	line_connecting_shape.shape = line_connecting_shape.shape.duplicate()

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

	collision_shape.shape.size.x = max(width - collision_width_offset, 0.5)
	line_connecting_shape.shape.size.x = width
	visual_shape.width = width
	initialized = true

## Stretch the MagicLine to a new destination 
func stretch_line(v: Vector2) -> void:
	_change_visual_end_point(v)
	_update_collision_shape()

## Locks the MagicLine to an ending EnchantmentLineConnectableComponent
func lock_line(m: LineConnector) -> void:
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
	collision_shape.shape.size.y = max(length - collision_length_offset, 0)
	collision_shape.rotation = angle
	line_connecting_shape.position = pos
	line_connecting_shape.shape.size.y = length
	line_connecting_shape.rotation = angle


func _on_area_shape_entered(_area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	"""
	EnchantmentLine's are created by the Coder, only moved around as an Enchantment
	When an EnchantmentLine Overlaps with:
		EnchantmentLine of Enchantment -> Nothing
		EnchantmentNode of Enchantment -> Invalid except owner (This is on Coder to not happen)
		
		EnchantmentLine of Other Enchantment -> Invalid
		EnchantmentNode of Other Enchantment -> Invalid
	"""
	if area is MagicLine:
		var other_shape_owner = area.shape_find_owner(area_shape_index)
		var other_shape_node = area.shape_owner_get_owner(other_shape_owner)
		var local_shape_owner = shape_find_owner(local_shape_index)
		var local_shape_node = shape_owner_get_owner(local_shape_owner)
		if _identify_if_same_source(area): ## Use smaller collision shapes only for same source MapNode
			if local_shape_node == collision_shape and other_shape_node == area.collision_shape: # Their colliding boxes hit
				var node: MapNode = area.start.owner
				if node.get_bounded_identity() == self.start.owner.get_bounded_identity():
					area.kill_magic_line()
		else:
			var node: MapNode = area.start.owner
			if node.get_bounded_identity() == self.start.owner.get_bounded_identity():
				area.kill_magic_line()

func _identify_if_same_source(m: MagicLine) -> bool:
	var same = start.owner == m.start.owner or end.owner == m.start.owner
	#print(self, "Is same," , is_same)
	if m.end:
		same = same or start.owner == m.end.owner or end.owner == m.end.owner
	return same
