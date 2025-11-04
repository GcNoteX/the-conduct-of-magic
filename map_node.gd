@abstract class_name MapNode extends Node2D

"""
An abstract class to compile define all Node-Type objects within a PlayMap
"""

var connections: Array[MapNode] = []

func _ready() -> void:
	call_deferred("update_connections")

@abstract func update_connections() -> void

@abstract func get_bounded_identity() -> Variant
