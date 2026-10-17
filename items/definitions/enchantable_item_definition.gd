class_name EnchantableItemDefinition
extends ItemDefinition

"""
The immutable aspects of an EnchantableItem, used in a factory
when creating new EnchantableItem's for the game
"""

@export_category("Enchanting")
## The magic node arrangement this item is bound to (choosing and sealing arrangements comes later)
@export var map_template: HexMapDefinition
#@export var possible_enchantment_graph_templates: Array[GraphTemplate]
