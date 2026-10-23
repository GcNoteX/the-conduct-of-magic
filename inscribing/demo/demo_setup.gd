class_name DemoSetup
extends Resource

## What a player starts with: money, materials, items and the enchantments they know. The Day
## uses day/demo/shop_start.tres; the test bench uses inscribing/demo/demo_setup.tres.

@export var money: int = 0
@export var materials: Dictionary[EnchantmentMaterialDefinition, int] = {}
@export var items: Array[EnchantableItemDefinition] = []
## Items that arrive already carved. The player gets a copy of each.
@export var carved_items: Array[ItemInstance] = []
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
	for carved in carved_items:
		var inst: ItemInstance = carved.duplicate(true)
		inst.id = StringName("%s_%d" % [carved.id, p.items.size() + 1])
		p.items.append(inst)
	p.known_enchantments = enchantments.duplicate()
	return p


## The starting materials, in the order they are listed
func shown_materials() -> Array[EnchantmentMaterialDefinition]:
	var out: Array[EnchantmentMaterialDefinition] = []
	out.assign(materials.keys())
	return out
