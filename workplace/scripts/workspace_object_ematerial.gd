extends WorkspaceObject
class_name WorkspaceObjectEMaterial

"""
For easier testing, pass in EnchantmentMaterialDefinition rather than having to create an ItemInstance
"""

@export var e_material: EnchantmentMaterialDefinition

func _ready() -> void:
	if item == null:
		item = ItemInstance.new()

	item.definition = e_material
	super._ready()
