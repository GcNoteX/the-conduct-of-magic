class_name Enchantment
extends Node

@export var enchantment_name: String = "None"

func _to_string() -> String:
	return "Enchantment: %s" % enchantment_name
