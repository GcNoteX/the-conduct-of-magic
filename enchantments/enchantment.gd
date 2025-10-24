class_name Enchantment
extends Node2D

"""
- Holds the map of an Enchantment
"""

var enodes: Array[EnchantmentNode]

func _ready() -> void:
	for child in get_children():
		if child is EnchantmentNode:
			enodes.append(child)
