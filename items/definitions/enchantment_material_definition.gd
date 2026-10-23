class_name EnchantmentMaterialDefinition
extends ItemDefinition
## A material that can be placed on an enchantment node: its tier, attributes, activation
## conditions and the runes it gives when disenchanted

# Pre-existing names, stored by index in material .tres files
# gdlint: ignore=enum-name,enum-element-name
enum MATERIAL_ATTRIBUTES { Soft, Hard, Shiny, Flame, Water }

@export var enchantment_sprite_normal: Texture2D  ## Used within the enchantment screen
@export var color: Color = Color.WHITE  ## Used to draw the material on the hex board

## The tier of the material, also used to evaluate its usage
## (e.g. whether it can be placed on an enchantment node)
@export var tier: int = 1
## Used to evaluate the material (e.g. whether it can be placed on an enchantment node)
@export var material_attributes: Array[MATERIAL_ATTRIBUTES]
## Conditions for the material to be activated on an enchantment node
@export var activation_conditions: Array[EnchantmentCondition]

@export_category("Disenchanting")
## The runes this material puts on every line at its node. A line costs both its ends' runes.
@export var edge_runes: RuneSet
## The runes its node gives back once, when the node's last line is cut
@export var harvest_runes: RuneSet
## The runes you get for dissolving one of this material
@export var dissolve_runes: RuneSet
