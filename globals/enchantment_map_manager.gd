extends Node

"""
Small script to insert a scrint to the EnchantmentMap correctly.
"""

func add_to_enchantment_map(node: Node) -> void:
	var map := get_tree().get_first_node_in_group("enchantment_map")
	if map:
		map.add_child(node)
	else:
		push_error("No EnchantmentMap found in the current scene!")
