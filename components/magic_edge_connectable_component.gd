class_name MagicEdgeConnectableComponent
extends Area2D

"""
- Allows an object to have MagicEdges connected to it.
- It defines the number of MagicEdges that can be connected to it.
- It defines the position a MagicEdge would be connected to an object.
"""

@export var is_unlimited_capacity: bool = true
@export var max_capacity: int = 0: ## Number of magic edges that can be connected to this socket
	set(c):
		if c < 0:
			return
		max_capacity = c

var connected_edges: Array[MagicEdge] = []

func can_connect_edge(e: MagicEdge = MagicEdge.new()) -> bool:
	# Has capacity, and not connecting to itself
	return (is_unlimited_capacity or connected_edges.size() < max_capacity) and !(e.start == self)

func add_edge(e: MagicEdge) -> void:
	connected_edges.append(e)

func remove_edge(e: MagicEdge) -> void:
	connected_edges.erase(e)

func _on_area_entered(area: Area2D) -> void:
	if area is MagicEdge:
		# If edge started from this component, ignore it
		if area.start == self:
			return
		# If edge is not from this component, try to connect it.
		if can_connect_edge(area):
			add_edge(area)
		else:
			area.kill_edge()
