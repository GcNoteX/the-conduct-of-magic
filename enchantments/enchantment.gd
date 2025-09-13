class_name Enchantment
extends Node

enum Tier {
	Tier1 = 1,
	Tier2 = 2,
	Tier3 = 3,
	Tier4 = 4,
	Tier5 = 5,
	Tier6 = 6,
	Tier7 = 7
}

@export var enchantment_name: String = "None"
@export var tier: Tier = Tier.Tier1

func _to_string() -> String:
	return "Enchantment: %s (%s)" % [enchantment_name, Enchantment.tier_as_string(tier)]

static func tier_as_string(t: Tier) -> String:
	match t:
		Tier.Tier1:
			return "Tier 1"
		Tier.Tier2:
			return "Tier 2"
		Tier.Tier3:
			return "Tier 3"
		Tier.Tier4:
			return "Tier 4"
		Tier.Tier5:
			return "Tier 5"
		Tier.Tier6:
			return "Tier 6"
		Tier.Tier7:
			return "Tier 7"
		_:
			return "Unknown Tier"
