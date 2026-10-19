class_name TierRule
extends CounterRule

## Some enchantments need an adventurer of at least a given tier.

@export var min_tiers: Dictionary[Enchantment, int] = {}


func check(visit: CustomerVisit, _day_number: int) -> String:
	var wanted := visit.slip.enchantment
	if wanted not in min_tiers or visit.adventurer_id == null:
		return ""
	if visit.adventurer_id.tier < min_tiers[wanted]:
		return (
			"%s needs tier %d, but the ID is tier %d"
			% [wanted.enchantment_name, min_tiers[wanted], visit.adventurer_id.tier]
		)
	return ""
