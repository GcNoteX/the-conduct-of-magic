extends Area2D
class_name MaterialComponent

"""
- Takes in a valid EnchantmentMaterial.
- Interfaces the state of an EnchantmentMaterial.
- Provides actions to insert, remove, activate and deactivate the EnchantmentMaterial.
- Provides an area to insert an EnchantmentMaterial.
"""

var is_activated
var embedded_material: EnchantmentMaterial = null

## The tier the EnchantMaterial has to be or greater to be embedded into EnchantmentNode
@export var tier_requirement: int = 1
## The requirements an EnchantmentMaterial has to fulfill to be allowed to be embedded into EnchantmentNode, 
## checks the material_attributes attribute
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

func remove_material() -> void:
	embedded_material = null

func can_material_be_activated() -> bool: # NOTE: What should be inserted as a parameter to check
	"""
	A node can be activated if:
		- All embedded material conditions are true
	"""
	for condition in embedded_material.activation_conditions:
		if not condition.is_fulfilled():
			return false
	return true

func activate_material() -> void:
	is_activated = true

func deactivate_material() -> void:
	is_activated = false
