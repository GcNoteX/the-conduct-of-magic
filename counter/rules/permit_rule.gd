class_name PermitRule
extends CounterRule

## Controlled enchantments need a permit that covers them and is valid in the customer's kingdom.

@export var controlled: Array[Enchantment] = []


func check(visit: CustomerVisit, _day_number: int) -> String:
	for wanted in visit.slip.enchantments:
		if wanted not in controlled:
			continue
		if visit.permit == null:
			return "No permit shown for %s" % wanted.enchantment_name
		if wanted not in visit.permit.covers:
			return "The permit doesn't cover %s" % wanted.enchantment_name
		if visit.slip.kingdom not in visit.permit.kingdoms:
			return "The permit isn't valid in %s" % visit.slip.kingdom
	return ""
