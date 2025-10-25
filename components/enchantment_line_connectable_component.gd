@tool
class_name EnchantmentLineConnectableComponent
extends Area2D

"""
- Detects when a EnchantmentLine collides with it and whether it can connect.
- It defines the number of EnchantmentLines that can be connected to it.
- It defines the position a EnchantmentLine would be connected to an object.
"""

signal connectable_line_detected(l: EnchantmentLine)
signal unconnectable_line_detected(l: EnchantmentLine)
signal enchantmentline_collided_with_self(l: EnchantmentLine)

@export var is_unlimited_capacity: bool = true
@export var max_capacity: int = 0: ## Number of magic edges that can be connected to this socket
	set(c):
		if c < 0:
			return
		max_capacity = c

@export var connected_lines: Array[EnchantmentLine] = []

func _ready() -> void:
	connected_lines = []

func can_connect_edge(e: EnchantmentLine = EnchantmentLine.new()) -> bool:
	# If the end is already selected, allow regardless - This is to allow prebuilds to work.
	if e.end:
		return true
	# Check if component already has a line from the EnchantmentLine's source to itself
	# Check if there is a Magicline from the component to the EnchantmentLine's source
	for line in connected_lines:
		if e.start == line.start or e.start == line.end:
			return false

	# Has capacity, and not connecting to itself
	return is_unlimited_capacity or connected_lines.size() < max_capacity

func add_edge(e: EnchantmentLine) -> void:
	if e.start and e.end == null and e.start != self:
		e.lock_line(self)
	connected_lines.append(e)

func remove_edge(e: EnchantmentLine) -> void:
	connected_lines.erase(e)

func _on_area_entered(area: Area2D) -> void:
	if area is EnchantmentLine:
		# If edge started from this component, ignore it
		if area.start == self:
			emit_signal("enchantmentline_collided_with_self", area)
			return
		# If edge is not from this component, try to connect it.
		if can_connect_edge(area):
			emit_signal("connectable_line_detected", area)
		else:
			emit_signal("unconnectable_line_detected", area)
