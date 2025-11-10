class_name MagicLine
extends MapLine

"""
- A straight line that goes between two MagicLineConnectableComponents
"""

func _ready() -> void:
	_initialize_line()

func update_bounded_identity() -> void:
	# Collect possible identities using a dictionary as a pseudo-set
	var identities := {}

	if start:
		if start.can_share_identity:
			identities[start.bounded_identity] = true
	if end: 
		if end.can_share_identity:
			identities[end.bounded_identity] = true

	# Evaluate results
	var keys := identities.keys()
	
	if keys.has(null):
		keys.erase(null)
	
	if keys.size() > 1:
		push_error(
			"%s connected between %s and %s with mismatched identities %s"
			% [self, start, end, str(keys)]
		)

	if keys.size() > 0:
		bounded_identity = keys[0]  # Use the first identity deterministically
	else:
		bounded_identity = null
	#print(self, " identity set to ", bounded_identity)

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
		if area.end: # Lines that have both a start (implicit) and end are not touched
			return
		var other_shape_owner = area.shape_find_owner(area_shape_index)
		var other_shape_node = area.shape_owner_get_owner(other_shape_owner)
		var local_shape_owner = shape_find_owner(local_shape_index)
		var local_shape_node = shape_owner_get_owner(local_shape_owner)
		#print(self, " Called function on ", area)
		if UtilityFunctions._are_adjacent_lines(self, area):
			# Use the collision_shape (smaller one) not to be confused with the larger whole line
			# This specific collision just has better feeling to it.
			if local_shape_node == collision_shape and other_shape_node == area.collision_shape:
				if MagicLine.maplines_share_identity(self, area):
					area.kill_line()
		else:
			if MagicLine.maplines_share_identity(self, area):
				area.kill_line()
