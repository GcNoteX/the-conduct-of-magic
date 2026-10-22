class_name MaterialDropper
extends Area2D
## A drop zone over a MaterialHolder: the material cursor inserts materials here and takes them
## back out. Needs a collision shape to be hovered.

@export var holder: MaterialHolder


## Returns true if the material was inserted, false otherwise
func insert_material(m: EnchantmentMaterialDefinition) -> bool:
	if not holder:
		push_warning("MaterialDropper needs a MaterialHolder to drop into")
		return false

	if holder.can_embbed_material(m):
		holder.embbed_material(m)
		return true
	return false


## Takes the embedded material out and returns it. Returns null, and changes nothing, when the
## slot is empty or sealed: a sealed slot keeps its material.
func remove_material() -> EnchantmentMaterialDefinition:
	if not holder or holder.sealed or holder.get_embedded_material() == null:
		return null
	return holder.remove_material()
