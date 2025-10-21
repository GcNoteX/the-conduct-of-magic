class_name MagicLineConnectableComponent
extends Area2D

"""
- Allows an object to have MagicLines connected to it.
- It defines the number of MagicLines that can be connected to it.
- It defines the position a MagicLine would be connected to an object.
"""

@export var is_unlimited_capacity: bool = true
@export var max_capacity: int = 0: ## Number of magic edges that can be connected to this socket
	set(c):
		if c < 0:
			return
		max_capacity = c

var connected_edges: Array[MagicLine] = []

func can_connect_edge(e: MagicLine = MagicLine.new()) -> bool:
	# Has capacity, and not connecting to itself
	return (is_unlimited_capacity or connected_edges.size() < max_capacity) and !(e.start == self)

func add_edge(e: MagicLine) -> void:
	connected_edges.append(e)

func remove_edge(e: MagicLine) -> void:
	connected_edges.erase(e)

func _on_area_entered(area: Area2D) -> void:
	if area is MagicLine:
		# If edge started from this component, ignore it
		if area.start == self:
			return
		# If edge is not from this component, try to connect it.
		if can_connect_edge(area):
			add_edge(area)
		else:
			area.kill_edge()
