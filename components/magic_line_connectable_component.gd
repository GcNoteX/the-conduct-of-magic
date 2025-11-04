@tool
class_name MagicLineConnectableComponent
extends Area2D

"""
- Detects when a MagicLine collides with it and whether it can connect.
- It defines the number of MagicLines that can be connected to it.
- It defines the position a MagicLine would be connected to an object.
"""

signal line_destroyed(l: MagicLine)
signal connectable_line_detected(l: MagicLine)
signal unconnectable_line_detected(l: MagicLine)
signal magicline_collided_with_self(l: MagicLine)

@export var is_unlimited_capacity: bool = true
@export var max_capacity: int = 0: ## Number of magic edges that can be connected to this socket
	set(c):
		if c < 0:
			return
		max_capacity = c

@export var connected_lines: Array[MagicLine] = []

func _ready() -> void:
	connected_lines = []

func can_connect_edge(e: MagicLine = MagicLine.new()) -> bool:
	# If the end is already selected, allow regardless - This is to allow prebuilds to work.
	if e.end:
		return true
	# Check if component already has a line from the MagicLine's source to itself
	# Check if there is a Magicline from the component to the MagicLine's source
	for line in connected_lines:
		if e.start == line.start or e.start == line.end:
			return false

	# Has capacity, and not connecting to itself
	return is_unlimited_capacity or connected_lines.size() < max_capacity

func add_edge(e: MagicLine) -> void:
	if e.start and e.end == null and e.start != self:
		e.lock_line(self)
	connected_lines.append(e)
	e.destroyed.connect(_on_MagicLine_destroyed.bind(e))
	

func remove_edge(e: MagicLine) -> void:
	connected_lines.erase(e)

func _on_area_entered(area: Area2D) -> void:
	if area is MagicLine:
		# If edge started from this component, ignore it
		if area.start == self:
			emit_signal("magicline_collided_with_self", area)
			return
		# If edge is not from this component, try to connect it.
		if can_connect_edge(area):
			emit_signal("connectable_line_detected", area)
		else:
			emit_signal("unconnectable_line_detected", area)

func _on_MagicLine_destroyed(l: MagicLine) -> void:
	#remove_edge(l)
	emit_signal("line_destroyed", l)
