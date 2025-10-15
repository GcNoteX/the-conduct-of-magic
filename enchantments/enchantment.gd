class_name Enchantment
extends Node2D

var enodes: Array[EnchantmentNode]

func _ready() -> void:
	for child in get_children():
		if child is EnchantmentNode:
			enodes.append(child)
