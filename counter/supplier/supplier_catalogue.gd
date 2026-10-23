class_name SupplierCatalogue
extends Resource

## The materials a supplier sells and what each costs, in gold.

@export var prices: Dictionary[EnchantmentMaterialDefinition, int] = {}


func materials() -> Array[EnchantmentMaterialDefinition]:
	var out: Array[EnchantmentMaterialDefinition] = []
	out.assign(prices.keys())
	return out


func price_of(m: EnchantmentMaterialDefinition) -> int:
	return prices.get(m, 0)
