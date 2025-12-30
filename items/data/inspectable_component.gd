extends Area2D
class_name InspectableComponent

@export var inspect_key: StringName

signal inspected(key: StringName)

func inspect():
	emit_signal("inspected", inspect_key)
