extends Resource
class_name Player

@export var material_inventory: Dictionary[EnchantmentMaterial, int] = {}

func add_material(mat: EnchantmentMaterial, amount: int = 1) -> void:
	if mat == null:
		push_warning("Tried to add null material to inventory.")
		return

	material_inventory[mat] = material_inventory.get(mat, 0) + amount
	if material_inventory[mat] <= 0:
		material_inventory.erase(mat)

func remove_material(mat: EnchantmentMaterial, amount: int = 1) -> void:
	if mat == null:
		push_warning("Tried to remove null material from inventory.")
		return

	if not material_inventory.has(mat):
		push_warning("Tried to remove material not in inventory: %s" % mat)
		return

	material_inventory[mat] -= amount
	if material_inventory[mat] <= 0:
		material_inventory.erase(mat)

func get_material_count(mat: EnchantmentMaterial) -> int:
	return material_inventory.get(mat, 0)
