class_name MaterialCondition
extends Resource

"""
Provides attributes to define a condition based on
EnchantmentMaterial.MATERIAL_ATTRIBUTES
"""

@export var attribute: EnchantmentMaterial.MATERIAL_ATTRIBUTES
## Whether the condition is required to succeed or just one of many since
## a list of conditions may only require 1 to be required.
@export var required: bool = false

## Evaluates whether a material passes the MaterialCondition
func is_material_valid(m: EnchantmentMaterial) -> bool:
	if attribute in m.material_attributes:
		return true
	return false
