@tool
class_name EnchantmentLine
extends MapLine

"""
- A special line that goes between EnchantmentNodes
"""

func _ready() -> void:
	_initialize_line()
	bounded_identity = owner

func update_bounded_identity() -> void:
	return

#func update_connected_identities() -> void:
	#push_warning("Attempted to change bounded identity of ", self , ". Ignoring.")
#
#func can_change_bounded_identities(_source: EnchantmentMapElement) -> bool:
	#return false

func _on_area_shape_entered(_area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	"""
	EnchantmentLine's are created by the Coder, only moved around as an Enchantment
	When an EnchantmentLine Overlaps with:
		EnchantmentLine of Enchantment -> Nothing
		EnchantmentNode of Enchantment -> Invalid except owner (This is on Coder to not happen)
		
		EnchantmentLine of Other Enchantment -> Invalid
		EnchantmentNode of Other Enchantment -> Invalid
	"""
	if area is MagicLine:
		var other_shape_owner = area.shape_find_owner(area_shape_index)
		var other_shape_node = area.shape_owner_get_owner(other_shape_owner)
		var local_shape_owner = shape_find_owner(local_shape_index)
		var local_shape_node = shape_owner_get_owner(local_shape_owner)
		if UtilityFunctions._is_same_source(self, area): ## Use smaller collision shapes only for same source MapNode
			if local_shape_node == collision_shape and other_shape_node == area.collision_shape: # Their colliding boxes hit
				
				## Condition1: If both MagicLine are bound to Enchantment's, they cannot be the same
				if bounded_identity is Enchantment and \
						area.bounded_identity is Enchantment and \
						bounded_identity == area.bounded_identity:
					area.kill_line()
		else:
			## Condition1: If both MagicLine are bound to Enchantment's, they cannot be the same
			if bounded_identity is Enchantment and \
					area.bounded_identity is Enchantment and \
					bounded_identity == area.bounded_identity:
				area.kill_line()
