extends Area2D
class_name MaterialDropper

"""
- Provides a location to insert and remove from a MaterialHolder
- Requires a Shape to function
"""

@export var holder: MaterialHolder

func insert(m: EnchantmentMaterial) -> void:
	if !holder:
		return
	
	if holder.can_embbed_material(m):
		holder.embbed_material(m)

func remove() -> EnchantmentMaterial:
	var m = holder.remove_material()
	if holder.sealed:
		return null
	else:
		return m
