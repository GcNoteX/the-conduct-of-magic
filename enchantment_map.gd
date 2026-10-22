class_name EnchantmentMap
extends Node2D
## The root of one legacy play map: every MapNode, MapLine and EnchantmentGrid placed on the map
## sits somewhere below it. EmapUpdateManager updates each map on its own.


func _ready() -> void:
	add_to_group("enchantment_map")


## The EnchantmentMap that `node` sits in, or null when it is not on a map
static func of(node: Node) -> EnchantmentMap:
	var current := node
	while current:
		if current is EnchantmentMap:
			return current
		current = current.get_parent()
	return null
