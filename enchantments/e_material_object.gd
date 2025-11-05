extends Node2D
class_name EMaterialObject

"""
This is the Physical Holder of an EnchantmentMaterial
The classes have been seperated because there may be cases
the material data is used, but no object needs to be displayed.
This is a Decorater that allows an EnchantmentMaterial to be
an object in the SceneTree
"""

@export var enchantment_material: EnchantmentMaterial

# Give it a sprite and etc
