class_name EnchantmentMaterial
extends Resource

@export var material_id: StringName
@export var material_sprite: Texture2D

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
