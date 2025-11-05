@abstract class_name MapLine extends Area2D

"""
An abstract class to compile define all Line-Type objects within a PlayMap
"""

signal line_destroyed(l: MapLine)

# INFO: Storing starting and ending points in MapLine helps with traversal and makes identifying the state of the MagicLine for further features easier.
@export var start: LineConnector = null
@export var end: LineConnector = null
@export var width = 15 # The width of the MapLine 

func kill_line() -> void:
	emit_signal("line_destroyed", self)
	queue_free()
