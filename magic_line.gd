class_name MagicLine
extends MapLine

"""
- A straight line that goes between two MagicLineConnectableComponents
"""

func _ready() -> void:
	_initialize_line()

func _on_area_shape_entered(_area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	"""
	When an MagicLine Overlaps with:
		EnchantmentLine of Enchantment -> Nothing
		EnchantmentNode of Enchantment -> Invalid except owner (This is on Coder to not happen)
		MagicLine of Enchantment -> Destroy MagicLine
		
		EnchantmentLine of Other Enchantment -> Invalid
		EnchantmentNode of Other Enchantment -> Invalid
		MagicLine of Other Enchantment -> Okay
		MagicNode of Item Map -> Invalid
	"""
	if area is MagicLine:
		var other_shape_owner = area.shape_find_owner(area_shape_index)
		var other_shape_node = area.shape_owner_get_owner(other_shape_owner)
		var local_shape_owner = shape_find_owner(local_shape_index)
		var local_shape_node = shape_owner_get_owner(local_shape_owner)
		if UtilityFunctions._is_same_source(self, area):
			if local_shape_node == collision_shape and other_shape_node == area.collision_shape:
				if !area.is_locked:
					var node: MapNode = area.start
					if node.get_bounded_identity() == self.start.get_bounded_identity():
						area.kill_line()
		else:
			if !area.is_locked:
				var node: MapNode = area.start
				if node.get_bounded_identity() == self.start.get_bounded_identity():
					area.kill_line()
