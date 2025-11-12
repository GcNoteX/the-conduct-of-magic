extends Node

"""
Manages scenes on the EnchantmentMap
"""

func add_to_enchantment_map(node: Node2D, global_pos: Vector2=Vector2.ZERO) -> void:
	var map := get_tree().get_first_node_in_group("enchantment_map") as Node2D
	if map:
		map.add_child(node)
		node.position = map.to_local(global_pos)
	else:
		push_error("No EnchantmentMap found in the current scene!")

func _on_unhandled_MapItem(i: MapItem) -> void:
	# Current implementation: Add the item back to the inventory of the player
	print("Adding material back to player")
	PlayerManager.add_material(i.e_material)
	# Delete the MapItem
	i.queue_free()
