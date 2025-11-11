@abstract class_name MapLine extends EnchantmentMapElement

"""
An abstract class to compile define all Line-Type objects within a PlayMap
Line-Type objects have only one start and end, and can only connect(a very specific term) to MapNode objects
"""

signal spawned(l: MapLine)
signal locked(l: MapLine)
signal destroyed(l: MapLine)
signal connected(l: MapLine)

@onready var visual_shape: Line2D = $Line2D
@onready var collision_shape: CollisionShape2D = $LineCollisionShape
@onready var line_connecting_shape: CollisionShape2D = $LineConnectingShape


# INFO: Storing starting and ending points in MapLine helps with traversal and makes identifying the state of the MagicLine for further features easier.
@export var start: MapNode = null
@export var end: MapNode = null
@export var width = 15 # The width of the MapLine 
## If the collision box is the entire line, spawn points for lines overlap and kill each other. This is a naive solution to that.
@export var collision_length_offset: int = 100
@export var collision_width_offset: int = 13

var initialized = false
var is_locked = false

func _ready() -> void:
	_initialize_line()
	push_warning("Abstract class MapLine _ready() called by ", self)
	
func _initialize_line() -> void:
	# EnchantmentUpdateManager Triggerrs to updates
	#self.spawned.connect(EnchantmentUpdateManager._on_MapLine_spawned)
	#self.locked.connect(EnchantmentUpdateManager._on_MapLine_locked)
	#self.destroyed.connect(EnchantmentUpdateManager._on_MapLine_destroyed)
	
	# For building maps in the editor 
	if !Engine.is_editor_hint():
		assert(start, "A MagicLine cannot exist without a start!")
	else:
		if !start:
			push_warning("[REMINDER] Set start position for ", self)

	# Collision shapes in instances share shape resource when they shouldnt
	collision_shape.shape = collision_shape.shape.duplicate() 
	line_connecting_shape.shape = line_connecting_shape.shape.duplicate()
	
	# Start the line at the start position
	global_position = start.global_position
	# Initialize the line's visual shape
	visual_shape.clear_points()
	_change_visual_start_point(Vector2.ZERO) # Always start at origin
	start.add_line_connection(self) # Update 
	if end:
		lock_line(end)
	
	# Set the sizes of the line
	collision_shape.shape.size.x = max(width - collision_width_offset, 0.5)
	line_connecting_shape.shape.size.x = width
	visual_shape.width = width
	
	initialized = true
	emit_signal("spawned", self)

func _on_spawned(_l: MapLine) -> void:
	pass

func _on_destroyed(_l: MapLine) -> void:
	update_bounded_identity()

func _on_locked(_l: MapLine) -> void:
	update_bounded_identity()

func kill_line() -> void:
	#print("Killing line")
	emit_signal("destroyed", self)
	queue_free()

## Stretch the MagicLine to a new destination 
func stretch_line(v: Vector2) -> void:
	_change_visual_end_point(v)
	_update_collision_shape()

## Locks the MagicLine to an ending MapNode
func lock_line(m: MapNode) -> void:
	end = m
	stretch_line(m.global_position - start.global_position)
	is_locked = true
	emit_signal("locked", self)
	emit_signal("connected", end)

## Abstracts away the Line2d updating first point (the start)
func _change_visual_start_point(v: Vector2) -> void:
	#print("Setting visual start ", v)
	if visual_shape.get_point_count() <= 0:
		visual_shape.add_point(v, 0)
	else:
		visual_shape.set_point_position(0, v)

## Abstracts away the Line2d updating second point (the end)
func _change_visual_end_point(v: Vector2) -> void:
	#print("Setting visual end ", v)
	if visual_shape.get_point_count() <= 0:
		visual_shape.add_point(v, 0)
		visual_shape.add_point(v, 1)
	elif visual_shape.get_point_count() <= 1:
		visual_shape.add_point(v, 1)
	else:
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

static func maplines_share_identity(l1: MapLine, l2: MapLine) -> bool:
	# --- Case 1: Both are unbound (null) ---
	if l1.bounded_identity == null and l2.bounded_identity == null:
		var connected_nodes := MapNode.gather_connections(l1.start)
		var connected_lines := MapNode.gather_lines(connected_nodes)
		return l2 in connected_lines

	# --- Case 2: Both have a bounded identity and it's the same ---
	elif l1.bounded_identity != null and l1.bounded_identity == l2.bounded_identity:
		return true

	# --- Otherwise, not shared ---
	return false

"""
Overlap Handling
"""

## Re-check all current overlaps manually
func validate_current_overlaps() -> void:
	var overlaps := get_overlapping_areas()
	for area in overlaps:
		# Skip invalid or freed references
		if not is_instance_valid(area):
			continue

		# Only check relevant types (e.g., MagicLine)
		if area is MapLine:
			_handle_overlap_validation(area)

func _handle_overlap_validation(_area: MapLine) -> void:
	# Same logic you used in _on_area_shape_entered
	#print(self, " overlap with ", area)
	pass
