class_name EnchantmentMaterial
extends Node2D

#INFO: This class extends Node2D cause in the future it may implement sprites.
# And more importantly, may have map_effect, which having collision shapes and positions may be important for.

## The tier of the material, used to evaluate its usage aswell (e.g. Whether it can be inserted in an EnchantmentNode)
@export var tier: int = 1
## Used to evaluate the material (e.g. Whether it can be inserted in an EnchantmentNode)
@export var material_attributes: Array[MATERIAL_ATTRIBUTES]
## Conditions for the EnchantmentMaterial to be activated in an EnchantmentNode
@export var activation_conditions: Array[EnchantmentCondition] 

enum MATERIAL_ATTRIBUTES {
	Soft,
	Hard,
	Shiny,
	Flame,
	Water
}
