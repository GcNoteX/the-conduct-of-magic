class_name DemoSetup
extends Resource

## What a test player starts the inscribing table with

@export var materials: Dictionary[EnchantmentMaterialDefinition, int] = {}
@export var items: Array[EnchantableItemDefinition] = []
@export var enchantments: Array[Enchantment] = []
## Length of the enchanting day for playtesting
@export var day_length_seconds: float = 3600.0


func create_player() -> Player:
	var p := Player.new()
	for m in materials:
		p.add_material(m, materials[m])
	for i in items.size():
		var inst := ItemInstance.new()
		inst.id = StringName("%s_%d" % [items[i].id, i + 1])
		inst.definition = items[i]
		p.items.append(inst)
	p.known_enchantments = enchantments.duplicate()
	return p
