class_name EnchantmentMaterialDefinition
extends ItemDefinition

# Pre-existing names, stored by index in material .tres files
# gdlint: ignore=enum-name,enum-element-name
enum MATERIAL_ATTRIBUTES { Soft, Hard, Shiny, Flame, Water }

@export var enchantment_sprite_normal: Texture2D  ## Used within the enchantment screen
@export var color: Color = Color.WHITE  ## Used to draw the material on the hex board

## The tier of the material, also used to evaluate its usage
## (e.g. whether it can be inserted in an EnchantmentNode)
@export var tier: int = 1
## Used to evaluate the material (e.g. Whether it can be inserted in an EnchantmentNode)
@export var material_attributes: Array[MATERIAL_ATTRIBUTES]
## Conditions for the EnchantmentMaterialDefinition to be activated in an EnchantmentNode
@export var activation_conditions: Array[EnchantmentCondition]
