extends Node2D
class_name MapItem

"""
Exist in a different 'layer' from the EnchantmentMap
Overlays it to be inserted into certain components
"""

@onready var item_sprite: Sprite2D = $ItemSprite

@export var e_material: EnchantmentMaterialDefinition

func _ready() -> void:
	assert(e_material, "MapItem cannot be added to the scene tree without an EnchantmentMaterialDefinition!")
	item_sprite.texture = e_material.material_sprite
