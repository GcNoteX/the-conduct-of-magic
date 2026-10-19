class_name IdRequiredRule
extends CounterRule

## Some enchantments are only sold to customers who show an adventurer ID.

@export var enchantments: Array[Enchantment] = []


func check(visit: CustomerVisit, _day_number: int) -> String:
	var wanted := visit.slip.enchantment
	if wanted in enchantments and visit.adventurer_id == null:
		return "No adventurer ID shown for %s" % wanted.enchantment_name
	return ""
