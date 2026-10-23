class_name SupplierCatalogue
extends Resource

## The materials a supplier sells and what each costs, in gold.

@export var prices: Dictionary[EnchantmentMaterialDefinition, int] = {}


func materials() -> Array[EnchantmentMaterialDefinition]:
	var out: Array[EnchantmentMaterialDefinition] = []
	out.assign(prices.keys())
	return out


## The price with a markup, like 1.5 for half as much again, rounded up to whole gold
func price_of(m: EnchantmentMaterialDefinition, multiplier: float = 1.0) -> int:
	return ceili(prices.get(m, 0) * multiplier)
