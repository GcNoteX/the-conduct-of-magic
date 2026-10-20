class_name DemoSetup
extends Resource

## What a test player starts the game with

@export var money: int = 0
@export var materials: Dictionary[EnchantmentMaterialDefinition, int] = {}
@export var items: Array[EnchantableItemDefinition] = []
@export var enchantments: Array[Enchantment] = []


func create_player() -> Player:
	var p := Player.new()
	p.money = money
	for m in materials:
		p.add_material(m, materials[m])
	for i in items.size():
		var inst := ItemInstance.new()
		inst.id = StringName("%s_%d" % [items[i].id, i + 1])
		inst.definition = items[i]
		p.items.append(inst)
	p.known_enchantments = enchantments.duplicate()
	return p
