class_name Player
extends Resource

## What the player owns: money, materials, items, the enchantments they know, and the
## commissions they have taken on.

@export var money: int = 0
@export var material_inventory: Dictionary[EnchantmentMaterialDefinition, int] = {}
@export var items: Array[ItemInstance] = []
@export var known_enchantments: Array[Enchantment] = []
@export var commissions: Array[Commission] = []


func add_material(mat: EnchantmentMaterialDefinition, amount: int = 1) -> void:
	if mat == null:
		push_warning("Tried to add null material to inventory.")
		return

	material_inventory[mat] = material_inventory.get(mat, 0) + amount
	if material_inventory[mat] <= 0:
		material_inventory.erase(mat)


func remove_material(mat: EnchantmentMaterialDefinition, amount: int = 1) -> void:
	if mat == null:
		push_warning("Tried to remove null material from inventory.")
		return

	if not material_inventory.has(mat):
		push_warning("Tried to remove material not in inventory: %s" % mat)
		return

	material_inventory[mat] -= amount
	if material_inventory[mat] <= 0:
		material_inventory.erase(mat)


func get_material_count(mat: EnchantmentMaterialDefinition) -> int:
	return material_inventory.get(mat, 0)


## Every material to list, in order: those in `first`, then any others the player holds
func materials_in_order(
	first: Array[EnchantmentMaterialDefinition]
) -> Array[EnchantmentMaterialDefinition]:
	var out: Array[EnchantmentMaterialDefinition] = first.duplicate()
	for m in material_inventory:
		if m not in out:
			out.append(m)
	return out


## Takes the amount from their money if they have enough; returns whether they did
func spend(amount: int) -> bool:
	if amount > money:
		return false
	money -= amount
	return true
