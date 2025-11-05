@abstract class_name MapNode extends Node2D

"""
An abstract class to compile define all Node-Type objects within a PlayMap
"""

var connections: Array[MapNode] = [] ## The number of connected nodes

func _ready() -> void:
	call_deferred("_update_connections")

@abstract func _update_connections() -> void

@abstract func get_bounded_identity() -> Variant
