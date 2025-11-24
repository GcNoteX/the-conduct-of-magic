@tool
class_name EnchantmentLine
extends MapLine

"""
- A special line that goes between EnchantmentNodes
"""

func _ready() -> void:
	_initialize_line()
	bounded_identity = get_parent()
	assert(bounded_identity is EnchantmentGrid, " EchantmentLine must have EnchantmentGrid as a parent")

func update_bounded_identity() -> void:
	bounded_identity = get_parent()

func _on_area_shape_entered(_area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	"""
	EnchantmentLine's are created by the Coder, only moved around as an EnchantmentGrid
	When an EnchantmentLine Overlaps with:
		EnchantmentLine of EnchantmentGrid -> Nothing
		EnchantmentNode of EnchantmentGrid -> Invalid except owner (This is on Coder to not happen)
		
		EnchantmentLine of Other EnchantmentGrid -> Invalid
		EnchantmentNode of Other EnchantmentGrid -> Invalid
	"""
	if area is MagicLine:
		if area.end: # Lines that have both a start (implicit) and end are not touched
			return
		var other_shape_owner = area.shape_find_owner(area_shape_index)
		var other_shape_node = area.shape_owner_get_owner(other_shape_owner)
		var local_shape_owner = shape_find_owner(local_shape_index)
		var local_shape_node = shape_owner_get_owner(local_shape_owner)
		if UtilityFunctions._are_adjacent_lines(self, area): ## Use smaller collision shapes only for same source MapNode
			if local_shape_node == collision_shape and other_shape_node == area.collision_shape: # Their colliding boxes hit
				if MagicLine.maplines_share_identity(self, area):
					#print(self, " kill ", area)
					area.kill_line()
		else:
			if MagicLine.maplines_share_identity(self, area):
				#print(self, " kill ", area)
				area.kill_line()
