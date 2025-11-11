@tool
extends Node
class_name MaterialHolder

"""
- Holds valid EnchantmentMaterial.
- Provides actions to insert, remove the EnchantmentMaterial.
"""

signal material_embedded
signal material_removed

var sealed = false ## An attribute to dictate whether the embedded_material can be removed and returned, or just removed.
@export var embedded_material: EnchantmentMaterial = null

## The tier the EnchantMaterial has to be or greater to be embedded into EnchantmentNode
@export var tier_requirement: int = 1
## The requirements an EnchantmentMaterial has to fulfill to be allowed to be embedded into EnchantmentNode, 
## checks the material_attributes attribute of EnchantmentMaterial
@export var material_requirements: Array[MaterialCondition]


func can_embbed_material(m: EnchantmentMaterial) -> bool:
	"""
	You can only embed a material if it meets
	- The tier requirement
	- All the required material_requirements
	- At least 1 material_requirement
	"""
	if embedded_material.tier < tier_requirement:
		return false
	
	var is_valid = false
	for requirement in material_requirements:
		if requirement.is_material_valid(m):
			is_valid = true
		else:
			if requirement.required:
				return false
	return is_valid

func embbed_material(m: EnchantmentMaterial) -> void:
	embedded_material = m
	emit_signal("material_embedded")

func remove_material() -> EnchantmentMaterial:
	var m = embedded_material
	embedded_material = null
	emit_signal("material_removed")
	return m

func can_material_be_activated(ctx: MaterialActivationContext) -> bool: # NOTE: What should be inserted as a parameter to check
	"""
	A material component can be activated if:
		- All embedded material conditions are true
	"""
	if !embedded_material:
		return false
	for condition in embedded_material.activation_conditions:
		if not condition.is_fulfilled(ctx):
			return false
	return true
