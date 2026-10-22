class_name CommissionSlip
extends Resource

## What a customer asks for: the enchantments, the item they go on, and what they offer to pay.
## The offer is for the whole job; each enchantment left undone takes an equal share off it.

@export var customer_name: String = ""
@export var kingdom: String = ""
@export var enchantments: Array[Enchantment] = []
@export var item: EnchantableItemDefinition
@export var payment: int = 0


## The enchantments' names, like "Glow and Ward"
func enchantment_names() -> String:
	var names: Array[String] = []
	for e in enchantments:
		names.append(e.enchantment_name)
	if names.size() <= 1:
		return "".join(names)
	return "%s and %s" % [", ".join(names.slice(0, -1)), names[-1]]
