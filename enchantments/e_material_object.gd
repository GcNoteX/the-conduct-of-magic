extends Node2D
class_name EMaterialObject

"""
This is the Physical Holder of an EnchantmentMaterialDefinition
The classes have been seperated because there may be cases
the material data is used, but no object needs to be displayed.
This is a Decorater that allows an EnchantmentMaterialDefinition to be
an object in the SceneTree
"""

@export var enchantment_material: EnchantmentMaterialDefinition

# Give it a sprite and etc
