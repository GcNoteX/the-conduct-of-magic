extends Area2D
class_name MaterialDropper

"""
- Provides a location to insert and remove from a MaterialHolder
- Requires a Shape to function
"""

@export var holder: MaterialHolder

## Return true if material inserted successfully else false
func insert_material(m: EnchantmentMaterial) -> bool:
	if !holder:
		push_warning("MaterialDropper needs a MaterialHolder to drop into")
		return false
	
	if holder.can_embbed_material(m):
		holder.embbed_material(m)
		print("Holder took material")
		return true
	print("Holder did not take material")
	return false 

func remove_material() -> EnchantmentMaterial:
	var m = holder.remove_material()
	if holder.sealed:
		return null
	else:
		return m
